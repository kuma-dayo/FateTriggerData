--[[
    载具皮肤贴纸贴纸界面
]]

local class_name = "VehicleSkinStickerMdt";
VehicleSkinStickerMdt = VehicleSkinStickerMdt or BaseClass(GameMediator, class_name);


--贴纸更新原因
VehicleSkinStickerMdt.StickerUpdateType = 
{
	EQUIP = 1, --增加贴纸：装备
	REPLACE = 2, --增加贴纸：替换
	UNEQUIP = 3, --删除贴纸：卸载
	REPLACED = 4, --删除贴纸：被替换
	AUTOSAVED = 5, --更新贴纸：保存上次编辑贴纸
	EXIT = 6, --退出编辑贴纸
}

function VehicleSkinStickerMdt:__init()
end

function VehicleSkinStickerMdt:OnShow(data)
end

function VehicleSkinStickerMdt:OnHide()

end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
	self.BindNodes = 
    {
		{ UDelegate = self.ReuseList_Sticker.OnUpdateItem,	Func = self.OnUpdateStickerItem },
		{ UDelegate = self.ReuseList_StickerEquip.OnUpdateItem,	Func = self.OnUpdateEquipStickerItem },
		{ UDelegate = self.Common_Button_GetBuy.Btn_List.OnClicked,	Func = self.OnButtonGetBuyClicked },
		{ UDelegate = self.Common_Button_GetActivity.Btn_List.OnClicked,	Func = self.OnButtonGetActivityClicked },
	}
	

	self.MsgList = 
	{
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnEscClicked},
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Left), Func = Bind(self,self.OnSwitchSticker,-1) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Right), Func = Bind(self,self.OnSwitchSticker,1)},
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.A), Func = Bind(self,self.OnSwitchSticker,-1) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.D), Func = Bind(self,self.OnSwitchSticker,1)},
		{Model = VehicleModel, MsgName = VehicleModel.ON_UPDATE_VEHICLE_SKIN_STICKER_LIST, Func = self.ON_UPDATE_VEHICLE_SKIN_STICKER_LIST},
		{Model = VehicleModel, MsgName = VehicleModel.ON_BUY_VEHICLE_SKIN_STICKER_LIST, Func = self.ON_BUY_VEHICLE_SKIN_STICKER_LIST},
	}
	self.StickerItemWidgetList = {}
    self.EquipStickerItemWidgetList = {}
	self.TheVehicleModel = MvcEntry:GetModel(VehicleModel)
	self.TheArsenalModel = MvcEntry:GetModel(ArsenalModel)
end


--由mdt触发调用
function M:OnShow(data)
	self.CurSelectVehicleId = data.VehicleId or 0
	self.CurSelectVehicleSkinId = data.VehicleSkinId or 0
	self:InitCommonUI()
end

function M:OnShowAvator()
	self.TheVehicleModel:DispatchType(VehicleModel.ON_OPEN_VEHICLE_SKIN_STICKER_SHOW, 
	{

	})

	--从槽位满回来之后，重置选中
	if self.OpenVehicleSkinStickerFull then
		self.CurSelectStickerId = 0
		self.CurSelectStickerSlot = 0
		self:ReloadStickerList()
		self:ReloadEquipStickerList()
		self:UpdateSelectStickerInfo()
		self:UpdateEditStickerShow()
		self.OpenVehicleSkinStickerFull = false
	end
end

function M:InitCommonUI()
	--贴纸类型标签页
	local TypeTabParam = {
        ClickCallBack = Bind(self,self.OnStickerTypeClick),
        ValidCheck = Bind(self,self.StickerTypeValidCheck),
        HideInitTrigger = false,
        IsOpenKeyboardSwitch = true,
	}

    TypeTabParam.ItemInfoList = {}
    local TabList = self.TheVehicleModel.VehicleSkinStickerTypeList
    for Index,StickerType in ipairs(TabList) do
        local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinStickerType, StickerType)
		if Cfg ~= nil then
			local TabItemInfo = {
				Id = Index,
				LabelStr = Cfg[Cfg_VehicleSkinStickerType_P.TypeName]
			}
			TypeTabParam.ItemInfoList[#TypeTabParam.ItemInfoList + 1] = TabItemInfo
		end
    end
    local CommonTabUpBarParam = {
        TitleTxt = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Weapon","11350"),
        CurrencyIDs = {ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND},
        TabParam = TypeTabParam
    }
    self.TabListCls = UIHandler.New(self,self.WBP_Common_TabUpBar_02, CommonTabUpBar,CommonTabUpBarParam).ViewInstance

    --底部
	UIHandler.New(self,self.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
		HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    })

	UIHandler.New(self,self.CommonBtnTips_Rotate, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_ROTATE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
		TipStr = self.TheArsenalModel:GetArsenalText("10045_Btn"),
		ActionMappingKey = ActionMappings.LeftMouseButton,
    })

	 --底部
	self.ButtonStickerInfoInst =  UIHandler.New(self,self.BTN_Sticker, WCommonBtnTips, 
	 {
		 OnItemClick = Bind(self,self.OnStickerInfoButtonClicked, 1),
		 CommonTipsID = CommonConst.CT_SPACE,
		 HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
		 ActionMappingKey = ActionMappings.SpaceBar,
	 }).ViewInstance

	--通用Touch输入
	UIHandler.New(self, self.WBP_Common_TouchInput, CommonTouchInput, 
	{

	})

	local StickerEditParam = 
	{
		VehicleId = self.CurSelectVehicleId,
		VehicleSkinId = self.CurSelectVehicleSkinId,
		CallCloseFunc = Bind(self, self.OnStickerCloseClicked),
		CallAlignmentFunc = Bind(self, self.OnStickerAlignClicked),
		CallMirrorFunc = Bind(self, self.OnStickerMirrorClicked),
	}
	self.StickerEditInst = UIHandler.New(self, self.WBP_VehicleSkinSticker_Edit, 
			require("Client.Modules.Arsenal.Vehicle.VehicleSkinStickerEdit"), StickerEditParam).ViewInstance

	local StickerShortageParam = 
	{
		CallReplaceFunc = Bind(self, self.OnStickerReplaceClicked),
		CallCloseFunc = Bind(self, self.OnStickerShortageCloseClicked)
	}
	self.StickerShortageInst = UIHandler.New(self, self.WBP_VehicleSkinSticker_Shortage, 
			require("Client.Modules.Arsenal.Vehicle.VehicleSkinStickerShortageLogic"), StickerShortageParam).ViewInstance
			

	--[[
		1、初始化，不选中贴纸
		2、贴纸列表
		3、装备列表
		4、贴纸信息
		5、编辑信息
	]]--
	self.CurSelectStickerId = 0
	self.CurSelectStickerSlot = 0
	self:ReloadStickerList()
	self:ReloadEquipStickerList()
	self:UpdateSelectStickerInfo()
	self:UpdateEditStickerShow()
end

function M:OnStickerTypeClick(Index,ItemInfo,IsInit)
	local TabList = self.TheVehicleModel.VehicleSkinStickerTypeList
	if TabList == nil or #TabList == 0 then 
		return 
	end
	local StickerType = TabList[Index] or 0
	if StickerType == self.CurStickerType  then
		return
	end

	--设置类型名字
	local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinStickerType, StickerType)
	self.GUITBWeaponName:SetText(StringUtil.Format(Cfg and Cfg[Cfg_VehicleSkinStickerType_P.TypeName] or ""))

	--更新改类型列表
	self.CurStickerType = StickerType
	self.StickerIdList = self.TheVehicleModel.VehicleSkinStickerType2IdList[StickerType] or {}
	table.sort(self.StickerIdList, function(StickerId1, StickerId2)
		-- 已解锁＞稀有度高＞贴纸ID大
		local HasA = self.TheVehicleModel:HasVehicleSkinSticker(StickerId1) 
		local HasB = self.TheVehicleModel:HasVehicleSkinSticker(StickerId2) 
		if HasA and not HasB then 
			return true
		elseif not HasA and HasB then
			return false
		else 
			local QualityA = self.TheVehicleModel:GetVehicleSkinStickerQuality(StickerId1)
			local QualityB = self.TheVehicleModel:GetVehicleSkinStickerQuality(StickerId2)
			if QualityA ~= QualityB then 
				return QualityA > QualityB
			end
		end
		return StickerId1 > StickerId2
	end)

	--总数
	self.GUITBTotalNum:SetText(#self.StickerIdList)
	--解锁数
	self:UpdateUnlockStickerNum()

	--[[
		切换类型标签
		1、贴纸列表
		2、刷新装备列表
		3、贴纸信息
		4、编辑信息
	]]
	self.CurSelectStickerId = 0
	self.CurSelectStickerSlot = 0
	self:ReloadStickerList()
	self:RefreshEquipStickerList()
	self:UpdateSelectStickerInfo()
	self:UpdateEditStickerShow()
end

function M:StickerTypeValidCheck(Type)
    return true
end

--解锁数
function M:UpdateUnlockStickerNum()
	local UnlockedNum = 0
	for _, StickerId in ipairs(self.StickerIdList) do
		local IsGot = self.TheVehicleModel:HasVehicleSkinSticker(StickerId)
		if IsGot then 
			UnlockedNum = UnlockedNum + 1
		end
	end
	self.GUITBUnLockedNum:SetText(UnlockedNum)
end

--------------------------底部贴纸列表---------------------------

function M:ReloadStickerList()
    self.ReuseList_Sticker:Reload(#self.StickerIdList)
end

function M:RefreshStickerList()
	self.ReuseList_Sticker:Refresh()
end

function M:CreateStickerItem(Widget)
	local Item = self.StickerItemWidgetList[Widget]
	if not Item then
		local Param = {
			UseByStickerList = true,
			OnItemClick = Bind(self,self.OnStickerItemClick)
		}
		Item = UIHandler.New(self, Widget, require("Client.Modules.Arsenal.Vehicle.VehicleSkinStickerListItem"), Param)
		self.StickerItemWidgetList[Widget] = Item
	end
	return Item.ViewInstance
end

--[[
	点击贴纸列表项
	1、当前Item选中高亮
	2、检查保存上次编辑
	3、开始编辑新贴纸
	4、更新右边贴纸信息
	5、更新装备贴纸列表：装备贴纸无须高亮
]]
function M:OnStickerItemClick(Item, StickerId, Slot)
	if Item == nil or StickerId == nil then 
		return
	end
	if StickerId == self.CurSelectStickerId and self.CurSelectStickerSlot == 0 then
		return
	end
	self.CurSelectStickerId = StickerId
	self.CurSelectStickerSlot = 0
	self:OnSelectStickerItem(Item)
	self:AutoSaveEditSticker()
	self:UpdateEditStickerShow()
	self:UpdateSelectStickerInfo()
	self:RefreshEquipStickerList()
end

function M:OnSelectStickerItem(Item)
	if self.CurSelectStickerItem then
		self.CurSelectStickerItem:UnSelect()
	end
	self.CurSelectStickerItem = Item
	if self.CurSelectStickerItem then
		self.CurSelectStickerItem:Select()
	end
end

function M:OnUpdateStickerItem(Widget, Index)
	local i = Index + 1
	local StickerId = self.StickerIdList[i]
	if StickerId == nil then
		return
	end

	local ListItem = self:CreateStickerItem(Widget)
	if ListItem == nil then
		return
	end

    if StickerId == self.CurSelectStickerId then
		self:OnSelectStickerItem(ListItem)
	else 
		ListItem:UnSelect()
	end
	ListItem:SetItemData(StickerId)
end



function M:UpdatSkinAvatarWithSticker(VehicleSkinId)
	self.TheVehicleModel:DispatchType(VehicleModel.ON_UPDATE_VEHICLE_SKIN_STICKER_SHOW, 
	{
		VehicleSkinId = VehicleSkinId or self.CurSelectVehicleSkinId
	})
end

--[[
	自动保存上次编辑贴纸
]]
function M:AutoSaveEditSticker()
	if self.StickerEditInst == nil then
		return
	end
	--保存上次编辑
	self.StickerEditInst:CommitEdit(true)
end

--[[
	更新编辑
]]
function M:UpdateEditStickerShow()
	if self.StickerEditInst == nil then
		return
	end
	--开始新的编辑
	self.StickerEditInst:UpdateStickerShow(self.CurSelectVehicleSkinId, 
		self.CurSelectStickerId, self.CurSelectStickerSlot)
end

--[[
更新贴纸信息：
	1、已拥有贴纸
	2、未拥有贴纸
	  1）可直接购买
	  2）活动获得
]]
function M:UpdateSelectStickerInfo()
	self.WidgetSwitcherStickerInfo:SetVisibility(self.CurSelectStickerId == 0 
		and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)

	if self.CurSelectStickerId == 0 then
		return
	end

	local StickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker, self.CurSelectStickerId)
    if StickerCfg == nil then 
		return
	end	
	self.WidgetSwitcherStickerInfo:SetActiveWidgetIndex(0)
	self.TB_StickerName:SetText(StringUtil.Format(StickerCfg[Cfg_VehicleSkinSticker_P.StickerName]))
	self.TB_StickerDesc:SetText(StringUtil.Format(StickerCfg[Cfg_VehicleSkinSticker_P.StickerDesc]))
	
	local TextId = 0
	local IsGot = self.TheVehicleModel:HasVehicleSkinSticker(self.CurSelectStickerId)
	local CanBuy = self.TheVehicleModel:CanBuyVehicleSkinSticker(self.CurSelectStickerId)
	if IsGot then
		self.WidgetSwitcherStickState:SetActiveWidgetIndex(CanBuy and 0 or 1)
		TextId = 10005
	else
		self.WidgetSwitcherStickState:SetActiveWidgetIndex(CanBuy and 2 or 3)
		TextId = CanBuy and 10038 or 10039
	end
	local BtnParam = 
	{
		TipStr = self.TheArsenalModel:GetArsenalText(TextId),
		OnItemClick = Bind(self,self.OnStickerInfoButtonClicked, 1),
		CommonTipsID = CommonConst.CT_SPACE,
		HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
		ActionMappingKey = ActionMappings.SpaceBar,
	}
	self.ButtonStickerInfoInst:UpdateItemInfo(BtnParam)

	if IsGot and CanBuy then
		self.Common_Button_GetBuy.Icon_Normal:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.Common_Button_GetBuy.Img_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.Common_Button_GetBuy.Text_Count:SetText(self.TheArsenalModel:GetArsenalText(10038))

		local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemId])
		if not CfgItem then
			self.MoneyIcon_GetBuy:SetVisibility(UE.ESlateVisibility.Collapsed)
		else
			self.MoneyIcon_GetBuy:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
			CommonUtil.SetBrushFromSoftObjectPath(self.MoneyIcon_GetBuy, CfgItem[Cfg_ItemConfig_P.IconPath])
		end
		self.TextNum_GetBuy:SetText(StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemNum])

	elseif IsGot and not CanBuy then
		self.Common_Button_GetActivity.Icon_Normal:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.Common_Button_GetActivity.Img_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.Common_Button_GetActivity.Text_Count:SetText(self.TheArsenalModel:GetArsenalText(10035))
		self.TextNum_GetActivity:SetText(self.TheArsenalModel:GetArsenalText(10040))
	elseif not IsGot and CanBuy then
		local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemId])
		if not CfgItem then
			self.MoneyIcon_NotOwnedBuy:SetVisibility(UE.ESlateVisibility.Collapsed)
		else
			self.MoneyIcon_NotOwnedBuy:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
			CommonUtil.SetBrushFromSoftObjectPath(self.MoneyIcon_NotOwnedBuy, CfgItem[Cfg_ItemConfig_P.IconPath])
		end
		self.TextNum_NotOwnedBuy:SetText(StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemNum])
	elseif not IsGot and not CanBuy then
		self.TextNum_NotOwnedActivity:SetText(StickerCfg[Cfg_VehicleSkinSticker_P.ObtainWay])
	end
end


function M:OnStickerInfoButtonClicked(BuyFrom)
	local IsGot = self.TheVehicleModel:HasVehicleSkinSticker(self.CurSelectStickerId)
	local CanBuy = self.TheVehicleModel:CanBuyVehicleSkinSticker(self.CurSelectStickerId)
	if IsGot then
		self:OnStickerEquipClicked()
	else
		if CanBuy then
			self:OnStickerBuyClicked(BuyFrom)
		else 
			self:OnStickerFectchClicked()
		end
	end
end



--[[
	装备贴纸-贴纸数量不足，且贴纸都已经装备在当前皮肤上时：返回到购买
]]
function M:BreakEquipSticker2Buy()
	self.WidgetSwitcherStickerInfo:SetVisibility(self.CurSelectStickerId == 0 
		and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)

	if self.CurSelectStickerId == 0 then
		return
	end

	local StickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker, self.CurSelectStickerId)
    if StickerCfg == nil then 
		return
	end	
	self.WidgetSwitcherStickerInfo:SetActiveWidgetIndex(0)
	self.TB_StickerName:SetText(StringUtil.Format(StickerCfg[Cfg_VehicleSkinSticker_P.StickerName]))
	self.TB_StickerDesc:SetText(StringUtil.Format(StickerCfg[Cfg_VehicleSkinSticker_P.StickerDesc]))
	
	local CanBuy = self.TheVehicleModel:CanBuyVehicleSkinSticker(self.CurSelectStickerId)
	self.WidgetSwitcherStickState:SetActiveWidgetIndex(CanBuy and 0 or 1)
	
	local BtnParam = 
	{
		TipStr = self.TheArsenalModel:GetArsenalText(CanBuy and 10038 or 10039),
		OnItemClick = CanBuy and Bind(self,self.OnStickerBuyClicked, 1) or Bind(self, self.OnStickerFectchClicked),
		CommonTipsID = CommonConst.CT_SPACE,
		HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
		ActionMappingKey = ActionMappings.SpaceBar,
	}
	self.ButtonStickerInfoInst:UpdateItemInfo(BtnParam)

	if CanBuy then
		self.Common_Button_GetBuy.Icon_Normal:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.Common_Button_GetBuy.Img_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.Common_Button_GetBuy.Text_Count:SetText(self.TheArsenalModel:GetArsenalText(10038))

		local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemId])
		if not CfgItem then
			self.MoneyIcon_GetBuy:SetVisibility(UE.ESlateVisibility.Collapsed)
		else
			self.MoneyIcon_GetBuy:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
			CommonUtil.SetBrushFromSoftObjectPath(self.MoneyIcon_GetBuy, CfgItem[Cfg_ItemConfig_P.IconPath])
		end
		self.TextNum_GetBuy:SetText(StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemNum])
	else
		self.Common_Button_GetActivity.Icon_Normal:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.Common_Button_GetActivity.Img_Icon:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.Common_Button_GetActivity.Text_Count:SetText(self.TheArsenalModel:GetArsenalText(10035))
		self.TextNum_GetActivity:SetText(self.TheArsenalModel:GetArsenalText(10040))
	end
end


--[[
装备贴纸：
	1、槽位是否满
		跳转新的界面
	2、查看贴纸是否够
		不够：弹替换贴纸侧边栏
		够：发送协议
]]
function M:OnStickerEquipClicked()
	if self.StickerEditInst == nil then
		return
	end
	
	local StickerEditInfo = self.StickerEditInst:GetStickerEditInfo()
	if StickerEditInfo == nil then
		return
	end
	if StickerEditInfo.Slot ~= 0 then
		self.StickerEditInst:CommitEdit()
	else
		local IsSlotFull = self.TheVehicleModel:IsVehicleSkinStickerSlotFull(self.CurSelectVehicleSkinId)
		if IsSlotFull then
			MvcEntry:OpenView(ViewConst.VehicleSkinStickerFull, {
				VehicleId = self.CurSelectVehicleId,
				VehicleSkinId = self.CurSelectVehicleSkinId,
				StickerInfo = StickerEditInfo
			})
			self.OpenVehicleSkinStickerFull = true
		else
			local IsEnough = self.TheVehicleModel:IsStickerEnough(self.CurSelectStickerId)
			if IsEnough then
				MvcEntry:GetCtrl(ArsenalCtrl):SendProto_AddVehicleSkinSticker(self.CurSelectVehicleSkinId, StickerEditInfo, 
					VehicleSkinStickerMdt.StickerUpdateType.EQUIP)
			else
				if self.TheVehicleModel:GetStickerNumUsedByOtherVehicleSkin(self.CurSelectVehicleSkinId, self.CurSelectStickerId) <= 0  then
					--装备贴纸-贴纸数量不足，且贴纸都已经装备在当前皮肤上时
					--self:BreakEquipSticker2Buy()
					local CanBuy = self.TheVehicleModel:CanBuyVehicleSkinSticker(self.CurSelectStickerId)
					if CanBuy then
						self:OnStickerBuyClicked(1)
					else
						self:OnStickerFectchClicked()
					end
				else
					--在别的皮肤中可以找到替换的贴纸
					self.WidgetSwitcherStickerInfo:SetActiveWidgetIndex(1)
					if self.StickerShortageInst ~= nil then
						self.StickerShortageInst:UpdateVisibility(true)
						self.StickerShortageInst:UpdateInfo(self.CurSelectVehicleSkinId, self.CurSelectStickerId)
					end
				end
			end
		end
	end
end

function M:OnStickerBuyClicked(BuyFrom)
	local Param = {
		StickerBuyFrom = BuyFrom,
		StickerId = self.CurSelectStickerId
	}
	MvcEntry:OpenView(ViewConst.VehicleSkinStickerBuy, Param)
end

function M:OnStickerFectchClicked()

end


function M:OnButtonGetBuyClicked()
	self:OnStickerBuyClicked()
end

function M:OnButtonGetActivityClicked()
	self:OnStickerFectchClicked()
end

--------------------------已装备贴纸列表---------------------------
function M:ReloadEquipStickerList()
	self.EquipStickerList = {}
	local MaxStickerSlotNum = self.TheVehicleModel:GetVehilceSkinStickerMaxSlot(self.CurSelectVehicleSkinId)
	local EquipNum = 0
	for Slot=1, MaxStickerSlotNum do
		local StickerInfo = self.TheVehicleModel:GetVehicleSkinStickerBySlot(self.CurSelectVehicleSkinId, Slot)
		table.insert(self.EquipStickerList, StickerInfo or 
		{
			StickerId = 0,
			Slot = Slot,
		})
		EquipNum = StickerInfo and EquipNum + 1 or EquipNum
	end
	self.ReuseList_StickerEquip:Reload(#self.EquipStickerList)

	self.TB_SelectNum:SetText(EquipNum)
	self.TB_TotalNum:SetText(MaxStickerSlotNum)
end

function M:RefreshEquipStickerList()
	self.ReuseList_StickerEquip:Refresh()
end
 
function M:CreateEquipStickerItem(Widget)
	local Item = self.EquipStickerItemWidgetList[Widget]
	if not Item then
		local Param = {
			UseByEquipList = true,
			OnItemRemoveClick = Bind(self,self.OnRemoveStickerItemClick),
			OnItemClick = Bind(self,self.OnEquipStickerItemClick),
			OnItemHover  = Bind(self,self.OnEquipStickerItemHover),
			OnItemUnhover = Bind(self,self.OnEquipStickerItemUnhover),
		}
		Item = UIHandler.New(self, Widget, require("Client.Modules.Arsenal.Vehicle.VehicleSkinStickerListItem"), Param)
		self.EquipStickerItemWidgetList[Widget] = Item
	end
	return Item.ViewInstance
end

--[[
	点击装备贴纸
	1、当前选中高亮
	2、检查保存上次编辑
	3、开始编辑新贴纸
	4、更新右边贴纸信息
	5、更新贴纸列表：相同的贴纸Id需要高亮
]]
function M:OnEquipStickerItemClick(Item, StickerId, Slot)
	if Item == nil or StickerId == nil or Slot == nil then 
		return
	end
	if StickerId == self.CurSelectStickerId 
		and Slot == self.CurSelectStickerSlot then
		return
	end
	self.CurSelectStickerId = StickerId
	self.CurSelectStickerSlot = Slot or 0
	self:OnSelectEquipStickerItem(Item)
	self:AutoSaveEditSticker()
	self:UpdateEditStickerShow()
	self:UpdateSelectStickerInfo()
	self:RefreshStickerList()
end

function M:OnEquipStickerItemHover(Slot)
	if self.StickerEditInst == nil then
		return
	end
	self.CurHoverEquipStickerSlot = self.CurHoverEquipStickerSlot or 0
	if self.CurHoverEquipStickerSlot ~= 0 and self.CurHoverEquipStickerSlot ~= Slot then
		self.StickerEditInst:UpdateStickerHoverState(self.CurHoverEquipStickerSlot, false)
	end
	self.CurHoverEquipStickerSlot = Slot
	self.StickerEditInst:UpdateStickerHoverState(Slot, true)
end

function M:OnEquipStickerItemUnhover(Slot)
	if self.StickerEditInst == nil then
		return
	end
	self.StickerEditInst:UpdateStickerHoverState(Slot, false)
end

function M:OnRemoveStickerItemClick(StickerId, Slot)
	if StickerId == nil or Slot == nil then 
		return
	end
	MvcEntry:GetCtrl(ArsenalCtrl):SendProto_RemoveVehicleSkinSticker(self.CurSelectVehicleSkinId, 
				StickerId, Slot, VehicleSkinStickerMdt.StickerUpdateType.UNEQUIP)
end

function M:OnSelectEquipStickerItem(Item)
	if self.CurSelectEquipStickerItem then
		self.CurSelectEquipStickerItem:UnSelect()
	end
	self.CurSelectEquipStickerItem = Item
	if self.CurSelectEquipStickerItem then
		self.CurSelectEquipStickerItem:Select()
	end
	--选中已装备贴纸
end

function M:OnUpdateEquipStickerItem(Widget, Index)
	local i = Index + 1
	local EquipSticker = self.EquipStickerList[i]
	if EquipSticker == nil then
		return
	end

	local ListItem = self:CreateEquipStickerItem(Widget)
	if ListItem == nil then
		return
	end

    if EquipSticker.StickerId == self.CurSelectStickerId and EquipSticker.Slot == self.CurSelectStickerSlot then
		self:OnSelectEquipStickerItem(ListItem)
	else 
		ListItem:UnSelect()
	end
	ListItem:SetItemData(EquipSticker.StickerId, EquipSticker.Slot)
end


--------------------------中间贴纸编辑---------------------------
--水平翻转
function M:OnStickerAlignClicked(StickerId)

end

--[[
	编辑贴纸关闭：处理未装备贴纸的编辑刷新
	1、重置贴纸选中
	2、更新右边贴纸信息
	3、刷新贴纸列表：不选中
]]
function M:OnStickerCloseClicked()
	self.CurSelectStickerId = 0
	self.CurSelectStickerSlot = 0
	self:UpdateEditStickerShow()
	self.ReuseList_Sticker:Refresh()
end

--镜像
function M:OnStickerMirrorClicked(StickerId)

end

--替换皮肤贴纸
function M:OnStickerReplaceClicked(TargetVehicleSkinId, TargetSlot, TargetStickerId)
	if self.StickerEditInst == nil then
		return
	end

	local StickerInfo = self.TheVehicleModel:GetVehicleSkinStickerBySlot(TargetVehicleSkinId, TargetSlot)
	if StickerInfo == nil then
		--没有现存的贴纸，无法替换
		local msgParam = {
			describe = self.TheArsenalModel:GetArsenalText(10041),
		}
		UIMessageBox.Show(msgParam)
		return
	end
	MvcEntry:GetCtrl(ArsenalCtrl):SendProto_RemoveVehicleSkinSticker(TargetVehicleSkinId, StickerInfo.StickerId, StickerInfo.Slot,
		VehicleSkinStickerMdt.StickerUpdateType.REPLACED)

	MvcEntry:GetCtrl(ArsenalCtrl):SendProto_AddVehicleSkinSticker(self.CurSelectVehicleSkinId, self.StickerEditInst:GetStickerEditInfo(), 
		VehicleSkinStickerMdt.StickerUpdateType.REPLACE)
end


function M:OnStickerShortageCloseClicked()
	if self.StickerShortageInst == nil then
		return
	end
	self.StickerShortageInst:UpdateVisibility(false)
	
	self.CurSelectStickerId = 0
	self.CurSelectStickerSlot = 0

	if self.StickerEditInst ~= nil then
		self.StickerEditInst:OnEditEnd()
	end

	self:RefreshStickerList()
	self:UpdateEditStickerShow()
	self:UpdateSelectStickerInfo()
end

--------------------------按钮以及网络事件---------------------------
function M:OnEscClicked()
	if self.StickerEditInst == nil then
		return
	end

	local function EcsCallFunc(Saved)
		MvcEntry:GetCtrl(ArsenalCtrl):SendProto_ExitVehicleSkinSticker(self.CurSelectVehicleSkinId,
		 	Saved and self.StickerEditInst.StickerEditInfo or self.StickerEditInst.BeforeEditInfo,
			VehicleSkinStickerMdt.StickerUpdateType.EXIT)

		MvcEntry:CloseView(ViewConst.VehicleSkinSticker)

		self.TheVehicleModel:DispatchType(VehicleModel.ON_UPDATE_VEHICLE_SKIN_SHOW, 
		{
			VehicleId = self.CurSelectVehicleId, 
			VehicleSkinId = self.CurSelectVehicleSkinId
		})
	end

	if not self.StickerEditInst:CanCommit() then
		EcsCallFunc()
		return
	end

	local msgParam = {
		describe = StringUtil.Format(self.TheArsenalModel:GetArsenalText(10020)),
		leftBtnInfo = {
            callback = function()
				EcsCallFunc(false)
			end
		},
		rightBtnInfo = {
			callback = function()
				EcsCallFunc(true)
			end
		}
	}
	UIMessageBox.Show(msgParam)
	return true
end

--[[
	切换贴纸
	1、贴纸列表选中高亮
	2、右边贴纸信息
	3、中间自动保存上次编辑
	4、中间更新新编辑信息
	5、右边装备列表取消高亮显示
]]
function M:OnSwitchSticker(Direction)
	local Idx, SelectId = 0,0
	if Direction > 0 then 
		Idx,SelectId = CommonUtil.GetListNextIndex4Id(self.StickerIdList, self.CurSelectStickerId)
	else 
		Idx,SelectId = CommonUtil.GetListPreIndex4Id(self.StickerIdList, self.CurSelectStickerId)
	end
	if not SelectId then
		return
	end
	self.CurSelectStickerId = SelectId
	self.CurSelectStickerSlot = 0

	self.ReuseList_Sticker:Refresh()
	self.ReuseList_Sticker:JumpByIdxStyle(Idx-1,UE.EReuseListJumpStyle.Content)
	
	self:UpdateSelectStickerInfo()
	self:AutoSaveEditSticker()
	self:UpdateEditStickerShow()
	self:RefreshEquipStickerList()
end

function M:ON_UPDATE_VEHICLE_SKIN_STICKER_LIST(Param)
	if Param == nil then
		return
	end
	local UpdateReason = Param.UpdateReason
	local VehicleSkinId = Param.VehicleSkinId

	if UpdateReason == VehicleSkinStickerMdt.StickerUpdateType.EQUIP then
		--增加贴纸：装备(包括装备贴纸的更新而非增加)
		UIAlert.Show(self.TheArsenalModel:GetArsenalText(10042))
	elseif UpdateReason == VehicleSkinStickerMdt.StickerUpdateType.REPLACE then
		--增加贴纸：替换
		UIAlert.Show(self.TheArsenalModel:GetArsenalText(10049))
	elseif UpdateReason == VehicleSkinStickerMdt.StickerUpdateType.UNEQUIP then
		--删除贴纸：卸载
		UIAlert.Show(self.TheArsenalModel:GetArsenalText(10043))
	elseif UpdateReason == VehicleSkinStickerMdt.StickerUpdateType.REPLACED then
		--删除贴纸：被替换
		if VehicleSkinId == self.CurSelectVehicleSkinId then
			UIAlert.Show(self.TheArsenalModel:GetArsenalText(10049))
		else
			--重置槽位
			MvcEntry:GetCtrl(ArsenalCtrl):SendProto_ExitVehicleSkinSticker(VehicleSkinId, nil,
				VehicleSkinStickerMdt.StickerUpdateType.EXIT)
		end
	elseif UpdateReason == VehicleSkinStickerMdt.StickerUpdateType.AUTOSAVED then
		--更新贴纸：保存上次编辑贴纸
	elseif UpdateReason == VehicleSkinStickerMdt.StickerUpdateType.EXIT then
		--UI已经关闭，不理
	end

	if UpdateReason == VehicleSkinStickerMdt.StickerUpdateType.EQUIP 
	or UpdateReason == VehicleSkinStickerMdt.StickerUpdateType.REPLACE 
	or UpdateReason == VehicleSkinStickerMdt.StickerUpdateType.UNEQUIP then
		self.CurSelectStickerId = 0
		self.CurSelectStickerSlot = 0
		self:RefreshStickerList()
		self:ReloadEquipStickerList()
		self:UpdateEditStickerShow()
		self:UpdateSelectStickerInfo()
		self:UpdatSkinAvatarWithSticker()
	elseif UpdateReason == VehicleSkinStickerMdt.StickerUpdateType.REPLACED then
		self:UpdatSkinAvatarWithSticker(VehicleSkinId)
	end
end

--[[
	需要自动装备
		槽位够
			--1) 如果是已经装备上去了的，需要做替换操作
			--2) 新的直接就直接装上去
		槽位不够：
			--1）
]]
function M:CheckEquipStickerAfterBuy(BuyStickerList, BuyFrom)
	if not BuyStickerList or not BuyFrom then
		return
	end
	if BuyFrom ~= 1 then
		return
	end

	if self.StickerEditInst == nil or self.StickerEditInst:GetStickerEditInfo() == nil  then
		return
	end

	local ConfirmBuyThisSticker = false
	for _, V in ipairs(BuyStickerList) do
		if V.StickerId == self.CurSelectStickerId then
			ConfirmBuyThisSticker = true
			break
		end
	end
	if not ConfirmBuyThisSticker then
		return
	end

	local IsSlotFull = self.TheVehicleModel:IsVehicleSkinStickerSlotFull(self.CurSelectVehicleSkinId)
	if IsSlotFull then
		return
	end
	MvcEntry:GetCtrl(ArsenalCtrl):SendProto_AddVehicleSkinSticker(self.CurSelectVehicleSkinId, self.StickerEditInst:GetStickerEditInfo(), 
		VehicleSkinStickerMdt.StickerUpdateType.EQUIP)
end

function M:ON_BUY_VEHICLE_SKIN_STICKER_LIST(Param)
	if Param == nil then
		return
	end
	if Param.StickerInfoList == nil or #Param.StickerInfoList == 0 then
		return
	end
	self:RefreshStickerList()
	self:UpdateSelectStickerInfo()
	self:UpdateUnlockStickerNum()
	self:CheckEquipStickerAfterBuy(Param.StickerInfoList, Param.BuyFrom)
end

function M:OnMouseMove(InMyGeometry, InMouseEvent)
	if self.StickerEditInst and self.StickerEditInst.OnMouseMove then
		return self.StickerEditInst:OnMouseMove(self.LimitBox,InMyGeometry, InMouseEvent)
	end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function M:OnMouseButtonDown(InMyGeometry, InMouseEvent)
	if self.StickerEditInst and self.StickerEditInst.OnMouseButtonDown then
		return self.StickerEditInst:OnMouseButtonDown(InMyGeometry, InMouseEvent)
	end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function M:OnMouseButtonUp(InMyGeometry, InMouseEvent)
    if self.StickerEditInst and self.StickerEditInst.OnMouseButtonUp then
		return self.StickerEditInst:OnMouseButtonUp(InMyGeometry, InMouseEvent)
	end
    return UE.UWidgetBlueprintLibrary.Handled()
end
return M