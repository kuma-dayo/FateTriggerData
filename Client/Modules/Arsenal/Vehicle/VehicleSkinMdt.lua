--[[
    载具皮肤界面
]]

local class_name = "VehicleSkinMdt";
VehicleSkinMdt = VehicleSkinMdt or BaseClass(GameMediator, class_name);


function VehicleSkinMdt:__init()
end

function VehicleSkinMdt:OnShow(data)
end

function VehicleSkinMdt:OnHide()

end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
	self.BindNodes = 
    {
		{ UDelegate = self.ReuseList_WeaponStickerSkin.OnUpdateItem,	Func = self.OnUpdateVehicleSkinItem },

		{ UDelegate = self.Btn_Sticker_Edit.Btn_List.OnClicked,       Func = self.OnStickerEditClicked},
	}

	self.MsgList = 
	{
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnEscClicked},
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Left), Func = Bind(self,self.OnSwitchVehicleSkin, -1) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Right), Func = Bind(self,self.OnSwitchVehicleSkin, 1)},
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.A), Func = Bind(self,self.OnSwitchVehicleSkin, -1) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.D), Func = Bind(self,self.OnSwitchVehicleSkin, 1)},
		{Model = VehicleModel, MsgName = VehicleModel.ON_SELECT_VEHICLE_SKIN,	Func = Bind(self, self.OnUpdateSelectVehicleSkin) },
		{Model = VehicleModel, MsgName = VehicleModel.ON_UNLOCK_VEHICLE_SKIN,	Func = Bind(self, self.OnUnLockVehicleSkin) },
		{Model = InputModel, MsgName = InputModel.ON_BEGIN_TOUCH,	Func = self.OnInputBeginTouch },
		{Model = InputModel, MsgName = InputModel.ON_END_TOUCH,	Func = self.OnInputEndTouch }
	}

    self.VehicleSkinItemWidgetList = {}
	self.TheVehicleModel = MvcEntry:GetModel(VehicleModel)
	self.TheArsenalModel = MvcEntry:GetModel(ArsenalModel)
end


--由mdt触发调用
function M:OnShow(data)
	self.CurSelectVehicleId = data.VehicleId or 0
	self.CurSelectVehicleSkinId = self.TheVehicleModel:GetVehicleSkinId(self.CurSelectVehicleId)
    
    self.VehicleSkinList = G_ConfigHelper:GetMultiItemsByKey(Cfg_VehicleSkinConfig, Cfg_VehicleSkinConfig_P.VehicleId, self.CurSelectVehicleId)
	table.sort(self.VehicleSkinList, function(A ,B)
		-- 1、被装备的皮肤，下次进入皮肤页面时，图标会无视排序规则被提前至首位
		-- 2、已获取排在未获取前
		-- 3、由高到低排列品级
		-- 4、同品级下则按照载具皮肤配置表中ID从小到大排列
		local SelectedA = self.CurSelectVehicleSkinId == A[Cfg_VehicleSkinConfig_P.SkinId]
		local SelectedB = self.CurSelectVehicleSkinId == B[Cfg_VehicleSkinConfig_P.SkinId]
		if SelectedA and not SelectedB then 
			return true
		elseif not SelectedA and SelectedB then
			return false
		else
			local HasA = self.TheVehicleModel:HasVehicleSkin(A[Cfg_VehicleSkinConfig_P.SkinId]) 
			local HasB = self.TheVehicleModel:HasVehicleSkin(B[Cfg_VehicleSkinConfig_P.SkinId]) 
			if HasA and not HasB then 
				return true
			elseif not HasA and HasB then
				return false
			else 
				local QualityA = self.TheVehicleModel:GetVehicleSkinQuality(A[Cfg_VehicleSkinConfig_P.SkinId])
				local QualityB = self.TheVehicleModel:GetVehicleSkinQuality(B[Cfg_VehicleSkinConfig_P.SkinId])
				if QualityA ~= QualityB then 
					return QualityA > QualityB
				end
			end
		end
		return A[Cfg_VehicleSkinConfig_P.SkinId] < B[Cfg_VehicleSkinConfig_P.SkinId]
	end)

	if CommonUtil.IsValid(self.WBP_Common_TabUpBar_02) then
		local CommonTabUpBarParam = {
			-- TitleTxt = self.TheArsenalModel:GetArsenalText(10018),
			TitleTxt = self.TheArsenalModel:GetArsenalText("10007_Btn"),
			CurrencyIDs = {ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND},
			-- TabParam = MenuTabParam
		}
		self.CommonTabUpBarInstance = UIHandler.New(self,self.WBP_Common_TabUpBar_02,CommonTabUpBar,CommonTabUpBarParam).ViewInstance
		-- todo 当前不显示tab,待打开
		self.CommonTabUpBarInstance:SetTabVisibility(UE.ESlateVisibility.Collapsed) 
		-- self.WBP_Common_TabUpBar_02:SetVisibility(UE.ESlateVisibility.Collapsed)
	end

	self:InitCommonUI()
    self:ReloadVehicleSkinList()
end

function M:OnShowAvator(data)
	self:UpdateSelectSkinAvatar(self.CurSelectVehicleSkinId)
end

function M:InitCommonUI()
	
    --底部
	UIHandler.New(self,self.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.Escape,
    })

	UIHandler.New(self,self.CommonBtnTips_Rotate, WCommonBtnTips, 
    {
        CommonTipsID = CommonConst.CT_ROTATE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
		TipStr = self.TheArsenalModel:GetArsenalText("10045_Btn"),
		ActionMappingKey = ActionMappings.LeftMouseButton,
    })

    --通用操作按钮：解锁
    self.UnlockBtnInst = UIHandler.New(self, self.Skin_UnlockBtn, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnUnlockBtn),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = self.TheArsenalModel:GetArsenalText(10004),
        ActionMappingKey = ActionMappings.SpaceBar,
        CheckButtonIsVisible = true,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
		JumpIDList = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(self.CurSelectVehicleSkinId)
    }).ViewInstance

    --通用操作按钮：装备
    UIHandler.New(self, self.Skin_SelectBtn, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnSelectBtn),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = self.TheArsenalModel:GetArsenalText(10005),
        ActionMappingKey = ActionMappings.SpaceBar,
        CheckButtonIsVisible = true,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })

    --通用操作按钮：已装备
    UIHandler.New(self, self.Skin_SelectedBtn, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnSelectedBtn),
        TipStr = self.TheArsenalModel:GetArsenalText("10006_Btn"),
        CheckButtonIsVisible = true,
    }).ViewInstance:SetBtnEnabled(false)

    --通用Touch输入
	UIHandler.New(self, self.WBP_Common_TouchInput, CommonTouchInput, 
    {

    })

	--两个按钮
	local VehicleSkillCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkillConfig, 100)
    if VehicleSkillCfg ~= nil then 
		CommonUtil.SetBrushFromSoftObjectPath(self.Btn_Sticker_Edit.Icon_Normal,VehicleSkillCfg[Cfg_VehicleSkillConfig_P.SkillIcon])
		self.Btn_Sticker_Edit.Text_Count:SetText(StringUtil.Format(VehicleSkillCfg[Cfg_VehicleSkillConfig_P.SkillName]))
	end

	VehicleSkillCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkillConfig, 200)
    if VehicleSkillCfg ~= nil then 
		CommonUtil.SetBrushFromSoftObjectPath(self.Btn_Wheel.Icon_Normal,VehicleSkillCfg[Cfg_VehicleSkillConfig_P.SkillIcon])
		self.Btn_Wheel.Text_Count:SetText(StringUtil.Format(VehicleSkillCfg[Cfg_VehicleSkillConfig_P.SkillName]))
	end
end




function M:ReloadVehicleSkinList()
    self.ReuseList_WeaponStickerSkin:Reload(#self.VehicleSkinList)
end

function M:RefreshVehicleSkinList()
	self.ReuseList_WeaponStickerSkin:Refresh()
end


function M:CreateVehicleSkinItem(Widget)
	local Item = self.VehicleSkinItemWidgetList[Widget]
	if not Item then
		local Param = {
			OnItemClick = Bind(self,self.OnVehicleSkinItemClick)
		}
		Item = UIHandler.New(self, Widget, require("Client.Modules.Arsenal.Vehicle.VehicleSkinListItem"), Param)
		self.VehicleSkinItemWidgetList[Widget] = Item
	end
	return Item.ViewInstance
end

--[[
	载具皮肤Item被点击
]]
function M:OnVehicleSkinItemClick(Item, VehicleSkinInfo, DataIndex)
	if Item == nil or VehicleSkinInfo == nil then 
		return
	end
	local SkinId = VehicleSkinInfo[Cfg_VehicleSkinConfig_P.SkinId] 
	self.CurSelectVehicleSkinId = SkinId
	self:UpdateSelectSkinAvatar(SkinId)
	self:OnSelectVehicleSkinItem(Item)
end

function M:OnSelectVehicleSkinItem(Item)
	if self.CurSelectVehicleItem then
		self.CurSelectVehicleItem:UnSelect()
	end
	self.CurSelectVehicleItem = Item
	if self.CurSelectVehicleItem then
		self.CurSelectVehicleItem:Select()
	end
	self:UpdateSelectSkinInfo()
end

function M:OnUpdateVehicleSkinItem(Widget, Index)
	local i = Index + 1
	local VehicleSkin = self.VehicleSkinList[i]
	if VehicleSkin == nil then
		return
	end

	local ListItem = self:CreateVehicleSkinItem(Widget)
	if ListItem == nil then
		return
	end

    if VehicleSkin[Cfg_VehicleSkinConfig_P.SkinId] == self.CurSelectVehicleSkinId then
		self:OnSelectVehicleSkinItem(ListItem)
	else 
		ListItem:UnSelect()
	end
	ListItem:SetItemData(VehicleSkin, self.CurSelectVehicleId, i)
end

function M:UpdateSelectSkinInfo()
	--[[
		载具皮肤信息: 皮肤名称、描述、解锁花费
	]]--
	local Wsc = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig, 
		Cfg_VehicleSkinConfig_P.SkinId, self.CurSelectVehicleSkinId)
    if Wsc ~= nil then 
		self.GUITBWeaponSkinName:SetText(StringUtil.Format(Wsc[Cfg_VehicleSkinConfig_P.SkinName]))
		self.GUITBWeaponSkinDesc:SetText(StringUtil.Format(Wsc[Cfg_VehicleSkinConfig_P.SkinDesc]))

		if self.UnlockBtnInst then
			local UnlockItemId = Wsc[Cfg_VehicleSkinConfig_P.UnlockItemId]
			local UnlockItemNum = Wsc[Cfg_VehicleSkinConfig_P.UnlockItemNum]
			local JumpID = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(Wsc[Cfg_VehicleSkinConfig_P.ItemId])
			self.UnlockBtnInst:ShowCurrency(UnlockItemId, UnlockItemNum, JumpID)
		end
	end

	--[[
		当前载具的按钮状态：未解锁、已解锁、已装备
	]]--
    if not self.TheVehicleModel:HasVehicleSkin(self.CurSelectVehicleSkinId) then 
		self.WidgetSwitcherSkinStatus:SetActiveWidgetIndex(0)
	else
		if self.TheVehicleModel:GetVehicleSkinId(self.CurSelectVehicleId) ~= self.CurSelectVehicleSkinId then
			self.WidgetSwitcherSkinStatus:SetActiveWidgetIndex(1)
		else 
			self.WidgetSwitcherSkinStatus:SetActiveWidgetIndex(2)
		end
	end

	--[[
		解锁信息：
	]]--
	self.GUITBWeaponName:SetText(self.TheArsenalModel:GetArsenalText("10007_Btn"))

	--[[
		载具信息：载具总皮肤数量、载具已解锁皮肤数量
	]]--	
	local SkinCfgList = G_ConfigHelper:GetMultiItemsByKey(Cfg_VehicleSkinConfig, 
		Cfg_VehicleSkinConfig_P.VehicleId, self.CurSelectVehicleId)
	if SkinCfgList == nil then
		return
	end
	--载具总皮肤数
	local TotalSkinNum = #SkinCfgList
	self.GUITBTotalNum:SetText(TotalSkinNum)
	--解锁皮肤数
	local UnlockedNum = 0
	for i=1, TotalSkinNum do
		local SkinCfg = SkinCfgList[i]
		if SkinCfg ~= nil then
			if self.TheVehicleModel:HasVehicleSkin(SkinCfg[Cfg_VehicleSkinConfig_P.SkinId]) then
				UnlockedNum = UnlockedNum + 1
			end
		end
	end
	self.GUITBUnLockedNum:SetText(UnlockedNum)
end

function M:UpdateSelectSkinAvatar(VehicleSkinId, DisableAutoRotate)
    self.TheVehicleModel:DispatchType(VehicleModel.ON_UPDATE_VEHICLE_SKIN_SHOW, 
        {
            VehicleId = self.CurSelectVehicleId, 
            VehicleSkinId = VehicleSkinId,
			DisableAutoRotate = DisableAutoRotate
        })
end

--[[
    左右箭头按键切换皮肤
]]
function M:OnSwitchVehicleSkin(Direction)
	local SkidIdList = {}
	for _, V in ipairs(self.VehicleSkinList) do
		table.insert(SkidIdList, V.SkinId)
	end
	local VehicleSkinIndex, SelectVehicleSkinId = 0, 0
	if Direction > 0 then 
		VehicleSkinIndex, SelectVehicleSkinId = CommonUtil.GetListNextIndex4Id(SkidIdList, self.CurSelectVehicleSkinId)
	else 
		VehicleSkinIndex, SelectVehicleSkinId = CommonUtil.GetListPreIndex4Id(SkidIdList, self.CurSelectVehicleSkinId)
	end
	self.CurSelectVehicleSkinId = SelectVehicleSkinId
	self:UpdateSelectSkinAvatar(SelectVehicleSkinId)
	self:RefreshVehicleSkinList()
	return true
end


function M:OnEscClicked()
	MvcEntry:CloseView(ViewConst.VehicleSkin)
	return true
end

function M:OnStickerEditClicked()
	if not self.TheVehicleModel:HasVehicleSkin(self.CurSelectVehicleSkinId) then
		UIAlert.Show(self.TheArsenalModel:GetArsenalText(10048))
		return
	end

	local Param = 
	{
		VehicleId = self.CurSelectVehicleId,
		VehicleSkinId = self.CurSelectVehicleSkinId
	}
	MvcEntry:OpenView(ViewConst.VehicleSkinSticker, Param)	
end


--解锁
function M:OnUnlockBtn()
	local Wsc = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig, 
		Cfg_VehicleSkinConfig_P.SkinId, self.CurSelectVehicleSkinId)
    if Wsc == nil then 
		return
	end
	local CurrencyId = Wsc[Cfg_VehicleSkinConfig_P.UnlockItemId]
	local Cost = Wsc[Cfg_VehicleSkinConfig_P.UnlockItemNum] or 0
	local Balance = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(CurrencyId)
	local ItemName = MvcEntry:GetModel(DepotModel):GetItemName(CurrencyId)
	if Balance < Cost then
		local msgParam = {
			describe = StringUtil.Format(self.TheArsenalModel:GetArsenalText(10008),ItemName) --{0}不够，无法解锁！
		}
		UIMessageBox.Show(msgParam)
		return
	end
	
	local msgParam = {
		-- describe = StringUtil.Format(self.TheArsenalModel:GetArsenalText(10009),StringUtil.GetRichTextImgForId(CurrencyId), Cost), --确定要花{0}{1}，进行解锁吗？
		describe = CommonUtil.GetBuyCostDescribeText(CurrencyId, Cost, CommonConst.BuyType.UNLOCK),--确定要花 {0}{1} 解锁吗？
		leftBtnInfo = {},
		rightBtnInfo = {
			callback = function()
				MvcEntry:GetCtrl(ArsenalCtrl):SendProto_BuyVehicleSkinReq(self.CurSelectVehicleId, 
						self.CurSelectVehicleSkinId)
				InputShieldLayer.Add(3, 1, function ()
				end)
			end,
			DelayCloseTime = 3,
		}
	}
	UIMessageBox.Show(msgParam)
end

--装备
function M:OnSelectBtn()
	MvcEntry:GetCtrl(ArsenalCtrl):SendProto_SelectVehicleSkinReq(self.CurSelectVehicleId, 
		self.CurSelectVehicleSkinId)
end

--已装备
function M:OnSelectedBtn()
	CLog("Selected: SkinId = "..self.CurSelectVehicleSkinId)
end

--装备皮肤回调
function M:OnUpdateSelectVehicleSkin()
	self:UpdateSelectSkinInfo()
	self:RefreshVehicleSkinList()
end

--购买解锁皮肤回调
function M:OnUnLockVehicleSkin()
	self:UpdateSelectSkinInfo()
	self:RefreshVehicleSkinList()
	self:CloseMessageBox()
end

function M:CloseMessageBox()
	InputShieldLayer.Close()
	if MvcEntry:GetModel(ViewModel):GetState(ViewConst.MessageBox) then
		UIMessageBox.Close()
	end
end


function M:OnInputBeginTouch()
	self.IsTouched = true
	self:UpdateSelectSkinAvatar(self.CurSelectVehicleSkinId, true)
end

function M:OnInputEndTouch()
	self.IsTouched = false
end



return M