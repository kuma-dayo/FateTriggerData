--[[
    武器详情界面
]]
require("Client.Modules.Arsenal.Weapon.WeaponDetailItem")
require("Client.Modules.Arsenal.Weapon.WeaponDetailAttachItem")
require("Client.Modules.Arsenal.Weapon.WeaponDetailAttachSelectorLogic")

local class_name = "WeaponDetailMdt";
WeaponDetailMdt = WeaponDetailMdt or BaseClass(GameMediator, class_name);

function WeaponDetailMdt:__init()
end

function WeaponDetailMdt:OnShow(data)
end

function WeaponDetailMdt:OnHide()

end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
	self.BindNodes = 
    {
		{ UDelegate = self.WBP_ReuseList_Weapon.OnUpdateItem,		Func = self.OnUpdateWeaponItem },
	}

	self.MsgList = 
    {
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Left), Func = Bind(self,self.OnSwitchWeapon,-1) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Right), Func = Bind(self,self.OnSwitchWeapon,1)},
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.A), Func = Bind(self,self.OnSwitchWeapon,-1) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.D), Func = Bind(self,self.OnSwitchWeapon,1)},
		{Model = WeaponModel, MsgName = WeaponModel.ON_SELECT_WEAPON,	Func = Bind(self, self.OnUpdateSelectWeapon) },
		{Model = WeaponModel, MsgName = WeaponModel.ON_SELECT_WEAPON_SKIN,	Func = Bind(self, self.OnUpdateSelectWeaponSkin) },
		{Model = SeasonModel, MsgName = SeasonModel.ON_ADD_SEASON_WEAPON_DATA,	Func = Bind(self, self.OnUpdateSeasonWeaponData) },
		-- {Model = InputModel, MsgName = InputModel.ON_BEGIN_TOUCH,	Func = Bind(self, self.OnInputBeginTouch) },
		-- {Model = InputModel, MsgName = InputModel.ON_END_TOUCH,	Func = Bind(self, self.OnInputEndTouch) },
		{Model = WeaponModel, MsgName = WeaponModel.ON_WEAPON_AVATAR_PREVIEW_UPDATE,	Func =  self.ON_WEAPON_AVATAR_PREVIEW_UPDATE },
		{Model = WeaponModel, MsgName = WeaponModel.ON_UPDATE_WEAPON_SKIN_SHOW,	Func =  self.ON_UPDATE_WEAPON_SKIN_SHOW },
		{Model = WeaponModel, MsgName = WeaponModel.ON_UPDATE_WEAPON_SKIN_HIDE,	Func =  self.ON_UPDATE_WEAPON_SKIN_HIDE },
		{Model = WeaponModel,  MsgName = WeaponModel.ON_CLICK_SELECT_ATTACHMENT_SLOT,      Func = self.ON_CLICK_SELECT_ATTACHMENT_SLOT },
		{Model = WeaponModel,  MsgName = WeaponModel.ON_CLICK_CLOSE_ATTACHMENT_SLOT,      Func = self.ON_CLICK_CLOSE_ATTACHMENT_SLOT },
		{Model = WeaponModel,  MsgName = WeaponModel.ON_HOVER_SELECT_ATTACHMENT_SLOT,      Func = self.ON_HOVER_SELECT_ATTACHMENT_SLOT },
	}
	self.TheWeaponModel = MvcEntry:GetModel(WeaponModel)
	self.TheSeasonModel = MvcEntry:GetModel(SeasonModel)
	self.TheArsenalModel = MvcEntry:GetModel(ArsenalModel)
	
	self.TheSeasonModel:ClearSeasonWeaponData()
	self.CacheWeaponTransformList = {}
end

--由mdt触发调用
function M:OnShow(data)
	self:InitCommonUI()

	self:InitSeasonDropDown()
end

function M:OnShowAvator()
	self:ShowWeaponAvatar()
	self:PlayShowLS()
end

function M:OnHide()
end

function M:InitCommonUI()
	--武器类型标签页
	local TypeTabParam = {
        ClickCallBack = Bind(self,self.OnWeaponTypeClick),
        ValidCheck = Bind(self,self.WeaponTypeValidCheck),
        HideInitTrigger = false,
        IsOpenKeyboardSwitch = true,
	}
    TypeTabParam.ItemInfoList = {}

    local TabList = self.TheWeaponModel.WeaponTypeList
    for Index,WeaponType in ipairs(TabList) do
        local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponDetailType, WeaponType)
		if Cfg ~= nil then
			local TabItemInfo = {
				Id = Index,
				LabelStr = Cfg[Cfg_WeaponDetailType_P.WeaponTypeName]
			}
			TypeTabParam.ItemInfoList[#TypeTabParam.ItemInfoList + 1] = TabItemInfo
		end
    end
    local CommonTabUpBarParam = {
        TitleTxt = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Weapon","11353"),
        TabParam = TypeTabParam
    }
    self.TabListCls = UIHandler.New(self,self.WBP_Common_TabUpBar_02, CommonTabUpBar,CommonTabUpBarParam).ViewInstance


	--通用操作按钮：展示
    UIHandler.New(self, self.GUIButtonSelect, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnGUIButtonSelect),
        CommonTipsID = CommonConst.CT_F,
        TipStr = self.TheArsenalModel:GetArsenalText("10012_Btn"),
        ActionMappingKey = ActionMappings.F,
        CheckButtonIsVisible = true,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })

	--通用操作按钮：展示中
	UIHandler.New(self, self.GUIButtonSelected, WCommonBtnTips,
	{
		OnItemClick = Bind(self, self.OnGUIButtonSelected),
		TipStr = self.TheArsenalModel:GetArsenalText("10013_Btn"),
		CheckButtonIsVisible = true,
	}).ViewInstance:SetBtnEnabled(false)

	
	--通用操作按钮：皮肤
	UIHandler.New(self, self.GUIButtonSkin, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnGUIButtonSkin),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = self.TheArsenalModel:GetArsenalText("10007_Btn"),
        ActionMappingKey = ActionMappings.SpaceBar,
        CheckButtonIsVisible = true,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })

	--底部
	UIHandler.New(self,self.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.Escape,
    })

	--配件选择
	self.AttachmentSelectorInst = UIHandler.New(self,self.WBP_AttachmentSelector, WeaponDetailAttachSelectorLogic, 
    {
		ContainerHandler = self
    }).ViewInstance
	
end

function M:ReloadWeaponList()
	if #self.WeaponIdList > 0 then
		self.WBP_ReuseList_Weapon:Reload(#self.WeaponIdList)
	end
end

function M:RefreshWeaponList()
	self.WBP_ReuseList_Weapon:Refresh()
end

function M:OnWeaponTypeClick(Index,ItemInfo,IsInit)
	local TabList = self.TheWeaponModel.WeaponTypeList
	if TabList == nil or #TabList == 0 then 
		return 
	end
	local WeaponType = TabList[Index] or 0
	if WeaponType == self.CurWeaponType  then
		return
	end
	--设置类型名字
	local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponDetailType, WeaponType)
	self.GUITBWeaponTypeName:SetText(StringUtil.Format(Cfg and Cfg[Cfg_WeaponDetailType_P.WeaponTypeName] or ""))

	--更新改类型列表
	self.CurWeaponType = WeaponType
	self.WeaponIdList = self.TheWeaponModel.WeaponType2IdList[WeaponType]
	table.sort(self.WeaponIdList, function(IdA, IdB)
		local SelectWeaponId = self.TheWeaponModel:GetSelectWeaponId()
		if IdA == SelectWeaponId then 
			return true
		elseif IdB == SelectWeaponId then
			return false
		else 
			return IdA < IdB
		end
	end)
	self:UpdateWeaponSkinAvatar(#self.WeaponIdList > 0 and self.WeaponIdList[1] or 0)
	self:ReloadWeaponList()
	if not IsInit then
		self:PlayShowLS()
	end
end

function M:WeaponTypeValidCheck(Type)
    return true
end


--[[
	武器Item被点击
]]
function M:OnWeaponItemClick(Item, WeaponId, DataIndex)
	self:UpdateWeaponSkinAvatar(WeaponId)
	self:OnSelectWeaponItem(Item)
	self:PlayShowLS()
end

function M:PlayShowLS()
	if not self.CurWeaponAvatar then
		return
	end
	self.CurWeaponAvatar:PlayShowLS()
end

function M:OnSelectWeaponItem(Item)
	if self.CurSelectWeaponItem then
		self.CurSelectWeaponItem:UnSelect()
	end
	self.CurSelectWeaponItem = Item
	if self.CurSelectWeaponItem then
		self.CurSelectWeaponItem:Select()
	end

	-- self:UpdateSelectWeaponShine()

	self:UpdateSelectWeaponInfo()
	--拉取每把枪的赛季数据
	self:TryFetchSeasonWeaponData()
	-- 选中武器时 注册红点
	self:RegisterSkinRedDot()
end

function M:CreateWeaponItem(Widget)
	self.WeaponItemWidgetList = self.WeaponItemWidgetList or {}
	local Item = self.WeaponItemWidgetList[Widget]
	if not Item then
		local Param = {
			OnItemClick = Bind(self,self.OnWeaponItemClick)
		}
		Item = UIHandler.New(self, Widget, WeaponDetailItem, Param)
		self.WeaponItemWidgetList[Widget] = Item
	end
	return Item.ViewInstance
end


function M:OnUpdateWeaponItem(Widget, Index)
	local i = Index + 1
	local WeaponId = self.WeaponIdList[i]
	if WeaponId == nil then
		return
	end

	local ListItem = self:CreateWeaponItem(Widget)
	if ListItem == nil then
		return
	end
    
    if WeaponId == self.CurSelectWeaponId then
		self:OnSelectWeaponItem(ListItem)
	else 
		ListItem:UnSelect()
	end
	ListItem:SetItemData(WeaponId, i)
end

function M:ShowWeaponAvatar(WeaponSkinId)
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr == nil then
		return 
	end
	if not self.CurSelectWeaponId then
		return
	end

	---@type HallCameraMgr
	local HallCameraMgr = CommonUtil.GetHallCameraMgr()
	if HallCameraMgr ~= nil then
		---重置相机
		HallCameraMgr:ResetCurCamera()
	end

	local CurEquipWeaponSkinId = self.TheWeaponModel:GetWeaponSkinId(self.CurSelectWeaponId)
	self.CurSelectWeaponSkinId = WeaponSkinId or CurEquipWeaponSkinId
    ---@type RtShowTran
    local FinalTran = CommonUtil.GetShowTranByItemID(ETransformModuleID.Arsenal_WeaponDetail.ModuleID, self.CurSelectWeaponSkinId)
    local SpawnParam = {
		ViewID = ViewConst.WeaponDetail,
		InstID = 0,
		WeaponID = self.CurSelectWeaponId,
		SkinID = self.CurSelectWeaponSkinId,
		Location = FinalTran.Pos,
        Rotation = FinalTran.Rot,
		Scale = FinalTran.Scale,
		--TrackingFocus = true,
		bAdaptCameraDistance = true,--适配相机推进距离
		UserSelectPartCache = (CurEquipWeaponSkinId == WeaponSkinId) or (not WeaponSkinId) 
	}

	if self.CurSelectSlotMeshComponent then
		self:OpenOrCloseWeaponPartEffect(self.CurSelectSlotMeshComponent, false)
		self.CurSelectSlotMeshComponent = nil
	end

	self.CurWeaponAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_WEAPON, SpawnParam)
    if self.CurWeaponAvatar ~= nil then
		self.CurWeaponAvatar:AttachVirutalPartSkinList(self.CurSelectWeaponSkinId)
		--TODO:模型创建成功
		if WeaponSkinId then
			if self.CacheWeaponTransformList[self.CurSelectWeaponId] then
				self.CurWeaponAvatar:K2_SetActorTransform(self.CacheWeaponTransformList[self.CurSelectWeaponId], 
					false, UE.FHitResult(), false)
			end
		end
		self.CurWeaponAvatar:OpenOrCloseCameraMoveAction(false)
		self.CurWeaponAvatar:OpenOrCloseAvatorRotate(true)
		self.CurWeaponAvatar:OpenOrCloseGestureAction(true)
    end
end

function M:HideWeaponAvatar()
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr ~= nil then
		local Avatar = HallAvatarMgr:HideAvatar(0, ViewConst.WeaponDetail, self.CurSelectWeaponId)
		if Avatar then
			self.CacheWeaponTransformList[self.CurSelectWeaponId] = Avatar:GetTransform()
		end
	end
	self.CurWeaponAvatar = nil
end

function M:UpdateWeaponSkinAvatar(WeaponId, WeaponSkinId)
	if WeaponSkinId == nil and self.CurSelectWeaponId == WeaponId then
		return
	end
	self:HideWeaponAvatar()
	self.CurSelectWeaponId = WeaponId
	self:ShowWeaponAvatar(WeaponSkinId)
end

function M:SetTagDesc(Tag, TagWidget)
	if Tag == nil then
		return false
	end
	if TagWidget == nil then
		return false
	end
	local TagDesc = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponDetailTag,
		Cfg_WeaponDetailTag_P.TagID, Tag.TagID)
	if TagDesc == nil then
		return false	
	end

	TagWidget:SetText(StringUtil.Format(TagDesc[Cfg_WeaponDetailTag_P.WeaponTagName]))
	return true
end

function M:SetTagColor(Tag, TagImgWidget)
	if Tag == nil then
		return
	end
	if TagImgWidget == nil then
		return
	end
	local TagDesc = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponDetailTag,
		Cfg_WeaponDetailTag_P.TagID, Tag.TagID)
	if TagDesc == nil then
		return	
	end
	CommonUtil.SetBrushTintColorFromHex(TagImgWidget, TagDesc[Cfg_WeaponDetailTag_P.WeaponTagColor], 1)
end

function M:SetPropertyDesc(Property, PropertyWidget)
	if Property == nil then
		return false
	end
	if PropertyWidget == nil then
		return false
	end
	local PropertyDesc = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponDetailProperty,
		Cfg_WeaponDetailProperty_P.PropertyID, Property.PropertyID)
	if PropertyDesc == nil then
		return false	
	end
	local Material = PropertyWidget.GUIImageProgress:GetDynamicMaterial()
	if Material ~= nil then
		Material:SetScalarParameterValue("SegmentNumber", 5)
		Material:SetScalarParameterValue("Value", Property.PropertyValue / 100)
	end
	PropertyWidget.GUITextBlock:SetText(StringUtil.Format(PropertyDesc[Cfg_WeaponDetailProperty_P.PropertyName]))
	local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(PropertyDesc[Cfg_WeaponDetailProperty_P.PropertyIcon])
	if ImageSoftObjectPtr ~= nil then
		PropertyWidget.GUIImageIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
	end

	return true
end

function M:UpdateSelectWeaponShine(WeaponSkinId)
	self:InsertTimer(Timer.NEXT_FRAME, function ()
		self:OpenOrCloseSelectWeaponShine(WeaponSkinId or self.CurSelectWeaponSkinId, true, 4)
	end)
end

function M:UpdateSelectWeaponInfo()
	local WCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponConfig, 
	Cfg_WeaponConfig_P.ItemId, self.CurSelectWeaponId)
    if WCfg == nil then 
		return
	end
	local WeaponName = MvcEntry:GetModel(DepotModel):GetItemName(WCfg[Cfg_WeaponConfig_P.ItemId])
	self.GUITBWeaponName:SetText(WeaponName)

	--标签
	local TagWidgets = {}
	table.insert(TagWidgets, self.GUITextBlockTag1)
	table.insert(TagWidgets, self.GUITextBlockTag2)
	table.insert(TagWidgets, self.GUITextBlockTag3)

	local TagImgWidgets = {}
	table.insert(TagImgWidgets, self.GUIImageTag1)
	table.insert(TagImgWidgets, self.GUIImageTag2)
	table.insert(TagImgWidgets, self.GUIImageTag3)

	for i=1,#TagWidgets do
		TagWidgets[i]:SetVisibility(UE.ESlateVisibility.Collapsed)
		TagImgWidgets[i]:SetVisibility(UE.ESlateVisibility.Collapsed)
	end
	local TagDescList = G_ConfigHelper:GetMultiItemsByKey(Cfg_WeaponDetailGroupTag, 
		Cfg_WeaponDetailGroupTag_P.TagGroupID, 
		WCfg[Cfg_WeaponConfig_P.TagGroupId])
	for i=1, #TagDescList do
		self:SetTagColor(TagDescList[i], TagImgWidgets[i])
		local IsSet = self:SetTagDesc(TagDescList[i], TagWidgets[i])
		if IsSet then
			TagWidgets[i]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
			TagImgWidgets[i]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		end
	end

	--属性
	local PropertyWidgets = {}
	table.insert(PropertyWidgets, self.WBP_Property_Item_1)
	table.insert(PropertyWidgets, self.WBP_Property_Item_2)
	table.insert(PropertyWidgets, self.WBP_Property_Item_3)
	table.insert(PropertyWidgets, self.WBP_Property_Item_4)
	for i=1,#PropertyWidgets do
		PropertyWidgets[i]:SetVisibility(UE.ESlateVisibility.Collapsed)
	end
	local PropertyDescList = G_ConfigHelper:GetMultiItemsByKey(Cfg_WeaponDetailPropertyGroup, 
		Cfg_WeaponDetailPropertyGroup_P.PropertyGroupID, 
		WCfg[Cfg_WeaponConfig_P.PropertyGroupId])
	for i=1, #PropertyDescList do
		local IsSet = self:SetPropertyDesc(PropertyDescList[i], PropertyWidgets[i])
		if IsSet then
			PropertyWidgets[i]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		end
	end

	--装备状态
	local SelectWeaponId = self.TheWeaponModel:GetSelectWeaponId()
	if SelectWeaponId == self.CurSelectWeaponId then 
		self.WidgetSwitcherSelect:SetActiveWidgetIndex(1)
	else 
		self.WidgetSwitcherSelect:SetActiveWidgetIndex(0)
	end
	
	--配件槽位
	if self.AttachmentSelectorInst then
		self.AttachmentSelectorInst:UpdateShowData(self.CurSelectWeaponId)
		self.AttachmentSelectorInst:ShowAttachmentSlotList(true)
	end
end


function M:OnEscClicked()
	MvcEntry:CloseView(ViewConst.WeaponDetail)

	--清理特效
	if self.CurSelectSlotMeshComponent then
		self:OpenOrCloseWeaponPartEffect(self.CurSelectSlotMeshComponent, false)
		self.CurSelectSlotMeshComponent = nil
	end

	if self.SelectShineTimer then
		Timer.RemoveTimer(self.SelectShineTimer)
		self.SelectShineTimer = nil
	end

	self:HideWeaponAvatar()

	--武器界面退出时，需要清除配件的装配信息
	self.TheWeaponModel:ClearSlotEquipAttachmentId()

	return true
end


--[[
    左右箭头按键切换枪
]]
function M:OnSwitchWeapon(Direction)
	local WeaponIdList = {}
	for _, WeaponId in ipairs(self.WeaponIdList) do
		table.insert(WeaponIdList, WeaponId)
	end
	local WeaponIndex, SelectWeaponId = 0, 0
	if Direction > 0 then 
		WeaponIndex, SelectWeaponId = CommonUtil.GetListNextIndex4Id(WeaponIdList, self.CurSelectWeaponId)
	else 
		WeaponIndex, SelectWeaponId = CommonUtil.GetListPreIndex4Id(WeaponIdList, self.CurSelectWeaponId)
	end
	--CLog(StringUtil.Format("SwitchWeapon: CurSelection={0}-{1}",WeaponIndex, SelectWeaponId))
	self:UpdateWeaponSkinAvatar(SelectWeaponId)
	self:RefreshWeaponList()
	self.WBP_ReuseList_Weapon:JumpByIdxStyle(WeaponIndex-1,UE.EReuseListJumpStyle.Content)
	self:PlayShowLS()
end

function M:OnUpdateSelectWeapon()
	self:RefreshWeaponList()
end

function M:OnUpdateSelectWeaponSkin()
	self:RefreshWeaponList()
end


--[[ 
	获取选中武器的品质颜色
]]
function M:GetSelectWeaponQualityColor(WeaponSkinId)
	local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, WeaponSkinId)
	if WeaponSkinCfg then
		local ItemId = WeaponSkinCfg[Cfg_WeaponSkinConfig_P.ItemId]
		local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
		if ItemCfg then
			-- 品质
			local Quality = ItemCfg[Cfg_ItemConfig_P.Quality]
			local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,Quality)
			return QualityCfg and UE.UGFUnluaHelper.FLinearColorFromHex(QualityCfg[Cfg_ItemQualityColorCfg_P.HexColor])
		end
	end
end

--[[
	播放武器选中特效
]]
function M:OpenOrCloseSelectWeaponShine(WeaponSkinId, Value, TagIndex)
	local function DoChgGlobalOpacityValueFunc(Opacity)
		if not self.CurWeaponAvatar or not self.CurWeaponAvatar:GetSkinActor(WeaponSkinId) then
			return
		end
		local RootComponent = self.CurWeaponAvatar:GetSkinActor(WeaponSkinId):K2_GetRootComponent()
		local AllMeshComponents = RootComponent:GetChildrenComponents(true)
		local Num =  AllMeshComponents:Num()
		for i=1, Num do
			local MeshComponent = AllMeshComponents:Get(i)
			if MeshComponent and MeshComponent:Cast(UE.UMeshComponent) then
				if not MeshComponent.bHiddenInGame and Value then
					local Param = {
						OutlineColor =  self:GetSelectWeaponQualityColor(WeaponSkinId) or UE.FLinearColor(1,1,1),
						GlobalOpacity = Opacity
					}
					self.TheArsenalModel:ChangePostProcessVolumeMaterialParam(TagIndex, Param)
					MeshComponent:SetGameplayStencilState(3)
				else
					MeshComponent:SetGameplayStencilState(0)
				end
			end	
		end
	end
	
	if self.SelectShineTimer ~= nil then
		Timer.RemoveTimer(self.SelectShineTimer)
		self.SelectShineTimer = nil
	end

	local GlobalOpacityValue = 1
	self.TheArsenalModel:SwitchPostProcessVolume(TagIndex)
	self.SelectShineTimer = Timer.InsertTimer(0, function()
			GlobalOpacityValue = GlobalOpacityValue - 0.05
			if GlobalOpacityValue <= 0.0 then
				GlobalOpacityValue = 0.0
				if self.SelectShineTimer ~= nil then
					Timer.RemoveTimer(self.SelectShineTimer)
					self.SelectShineTimer = nil
				end
			end
			DoChgGlobalOpacityValueFunc(GlobalOpacityValue)
	end, true)
end


--[[
	武器赛季数据展示
]]
function M:InitSeasonDropDown()
	self.SeasonList = self.TheSeasonModel:GetSeasonList()
	if #self.SeasonList > 0 then
		local SeasonNameList = {}
		for k, v in ipairs(self.SeasonList) do
			table.insert(SeasonNameList, {ItemDataString = StringUtil.Format(v.SeasonName)})
		end
		local DefaultSelectionIndex = 1
		UIHandler.New(self, self.WBP_ComboBox, CommonComboBox, {
			OptionList = SeasonNameList, 
			DefaultSelect = DefaultSelectionIndex,
			SelectCallBack = Bind(self, self.OnSelectionChangedSeason)
		})
	end
end

function M:GetSelectedSeason()
	return self.SeasonList and self.SeasonList[self.SelectedSeasonIndex]
end

function M:TryFetchSeasonWeaponData()
	local SelectSeason = self:GetSelectedSeason()
	if SelectSeason == nil then
		self.GUITBKillNum:SetText(0)
		self.GUITBHeadShotNum:SetText(0)
		self.GUITBTotalDamage:SetText(0)
		self.GUITBProcessedTime:SetText(StringUtil.Format(self.TheArsenalModel:GetArsenalText(10054), 0)) --10054:{0}分
		return
	end
	local SelectSeasonName = SelectSeason.SeasonName
	local SeasonId = SelectSeason.SeasonId
	local WeaponId = self.CurSelectWeaponId
	local SeasonWeaponData = self.TheSeasonModel:GetSeasonWeaponData(SeasonId, WeaponId)
	if SeasonWeaponData ~= nil then
		CLog("Cache Season Weapon Data: SeasonId = "..SeasonId.." WeaponId = "..WeaponId)
		self.TheSeasonModel:DispatchType(SeasonModel.ON_ADD_SEASON_WEAPON_DATA)
		return
	end
	MvcEntry:GetCtrl(SeasonCtrl):SendProto_SeasonWeaponDataReq(SeasonId, WeaponId)
end

function M:RefreshSeasonWeaponData()
	local SelectSeason = self:GetSelectedSeason()
	if SelectSeason == nil then
		return
	end
	local SelectSeasonName = SelectSeason.SeasonName
	local SeasonId = SelectSeason.SeasonId
	local WeaponId = self.CurSelectWeaponId
	local SeasonWeaponData = MvcEntry:GetModel(SeasonModel):GetSeasonWeaponData(SeasonId, WeaponId)
	if SeasonWeaponData ~= nil then
		local MaxShowNum = CommonConst.MAX_SHOW_NUM
		self.GUITBKillNum:SetText(SeasonWeaponData.KillNum > MaxShowNum and MaxShowNum.."+" or SeasonWeaponData.KillNum.."")
		self.GUITBHeadShotNum:SetText(SeasonWeaponData.HeadShotNum > MaxShowNum and MaxShowNum.."+" or SeasonWeaponData.HeadShotNum.."")
		self.GUITBTotalDamage:SetText(SeasonWeaponData.TotalDamage > MaxShowNum and MaxShowNum.."+" or math.floor(SeasonWeaponData.TotalDamage).."")
		
		local _, Hours, Minutes, _ = TimeUtils.sec2Time(SeasonWeaponData.PossessedTime)
		
		--10052:{0}小时{1}分 --10053:{0}小时 --10054:{0}分
		local FormatTextId = Hours > 0 and (Minutes > 0 and 10052 or 10053) or 10054
		local FormatText = self.TheArsenalModel:GetArsenalText(FormatTextId)
		local FormatProcessedTime = Hours > 0 and (Minutes > 0 and StringUtil.Format(FormatText, Hours, Minutes) or StringUtil.Format(FormatText, Hours)) or StringUtil.Format(FormatText, Minutes)
		self.GUITBProcessedTime:SetText(StringUtil.Format(FormatProcessedTime))
	else
		self.GUITBKillNum:SetText(0)
		self.GUITBHeadShotNum:SetText(0)
		self.GUITBTotalDamage:SetText(0)
		self.GUITBProcessedTime:SetText(StringUtil.Format(self.TheArsenalModel:GetArsenalText(10054), 0)) ---10054:{0}分
	end
end

function M:OnSelectionChangedSeason(Index)
	CLog("Index = "..Index)
	self.SelectedSeasonIndex = Index

	self:TryFetchSeasonWeaponData()
end

function M:OnUpdateSeasonWeaponData()
	self:RefreshSeasonWeaponData()
end

function M:OnInputBeginTouch()
	if self.bInputBeginTouch then
        return
    end
    self.bInputBeginTouch = true

	if self.VXE_Hall_Weapon_RotShow_In then
		self:VXE_Hall_Weapon_RotShow_In()
	end
end

function M:OnInputEndTouch()
	if not self.bInputBeginTouch then
		return
    end
    self.bInputBeginTouch = false

	if self.VXE_Hall_Weapon_RotShow_Out then
		self:VXE_Hall_Weapon_RotShow_Out()
	end
end

function M:ON_WEAPON_AVATAR_PREVIEW_UPDATE(Param)
	if Param.IsAdd then
		self.CurWeaponAvatar:AttachAvatarByID(Param.AvatarId, nil, true)
	else
		local SlotTag = self.TheWeaponModel:GetSlotTagBySlotType(Param.SlotType)
		if SlotTag then
			self.CurWeaponAvatar:RemoveAvatarBySlotTag(SlotTag)
		end
	end
	self.CurWeaponAvatar:AttachVirutalPartSkinList(self.CurSelectWeaponSkinId)
	self:OpenOrCloseClickWeaponPartShine(true, Param.SlotType)
end


function M:ON_UPDATE_WEAPON_SKIN_SHOW(Param)
	if Param == nil then
		CWaring("Update Weapon Skin Show Param Failed")
		return
	end
	self:UpdateWeaponSkinAvatar(Param.WeaponId,Param.WeaponSkinId)
	-- self:UpdateSelectWeaponShine(Param.WeaponSkinId)
	self:PlayShowLS()
end

function M:ON_UPDATE_WEAPON_SKIN_HIDE()
	self:HideWeaponAvatar()
end

--打开插槽
function M:ON_CLICK_SELECT_ATTACHMENT_SLOT(Param)
	if Param == nil then
		return
	end
	if self.CurWeaponAvatar == nil then
		return
	end
	local PreviewAttachTrans = self.TheWeaponModel:GetWeaponTransForSlot(self.CurSelectWeaponId, Param.SlotType)
	if PreviewAttachTrans == nil then
		CWaring("Not Found Target Trans")
		return
	end
	self.CurWeaponAvatar:PreviewWeaponPartWithCamerFocus(PreviewAttachTrans, Param.SlotType)
	self.CurWeaponAvatar:OpenOrCloseAvatorRotate(false)
	self.CurWeaponAvatar:OpenOrCloseGestureAction(false)
	self:OpenOrCloseClickWeaponPartShine(true, Param.SlotType)
	MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag("ShowWeapon")
	self:PlayWeaponPartBlurLS(Param.SlotType, false)
end

--关闭插槽
function M:ON_CLICK_CLOSE_ATTACHMENT_SLOT(Param)
	if Param == nil then
		return
	end
	if self.CurWeaponAvatar == nil then
		return
	end

	--还原初始位置
	local DefParam = {DefPos = UE.FVector(40020, -10, 0), DefRot = UE.FRotator(0, 90, 2), DefScale = UE.FVector(1, 1, 1)}
    local FinalTran = CommonUtil.GetShowTranByItemID(ETransformModuleID.Arsenal_WeaponDetail.ModuleID, self.CurSelectWeaponSkinId, DefParam)
	local OriginTransform = UE.UKismetMathLibrary.MakeTransform(FinalTran.Pos, FinalTran.Rot, FinalTran.Scale)
	self.CurWeaponAvatar:PreviewWeaponPartWithCamerFocus(OriginTransform, 0)
	self.CurWeaponAvatar:OpenOrCloseAvatorRotate(true)
	self.CurWeaponAvatar:OpenOrCloseGestureAction(true)
	self:OpenOrCloseClickWeaponPartShine(false, Param.SlotType)
	self:PlayWeaponPartBlurLS(Param.SlotType, true)
end

function M:OpenOrCloseClickWeaponPartShine(IsSelect, Slot)
	if self.CurWeaponAvatar == nil then
		return
	end
	local AvatarComponent = self.CurWeaponAvatar:GetAvatarComponent()
	local RootComponent = self.CurWeaponAvatar:K2_GetRootComponent()
	if not RootComponent and not AvatarComponent then
		return
	end
	--先关闭其他的
	local AllMeshComponents = RootComponent:GetChildrenComponents(true)
	local Num =  AllMeshComponents:Num()
	for i=1, Num do
		local MeshComponent = AllMeshComponents:Get(i)
		if MeshComponent and MeshComponent:Cast(UE.UMeshComponent) then
			if self.CurSelectSlotMeshComponent ~= MeshComponent then
				MeshComponent:SetGameplayStencilState(0)
				self:OpenOrCloseWeaponPartEffect(MeshComponent, false)
			end
		end	
	end
	local MeshCompoent = self.CurWeaponAvatar:GetAvatarAttachedMeshComponent(Slot)
	if not IsSelect or not MeshCompoent then
		if CommonUtil.IsValid(self.CurSelectSlotMeshComponent) then
			self.CurSelectSlotMeshComponent:SetGameplayStencilState(0)
			self:OpenOrCloseWeaponPartEffect(self.CurSelectSlotMeshComponent, false)
			self.CurSelectSlotMeshComponent = nil
		end
	else
		if self.CurSelectSlotMeshComponent ~= MeshCompoent then
			if  CommonUtil.IsValid(self.CurSelectSlotMeshComponent) then
				self.CurSelectSlotMeshComponent:SetGameplayStencilState(0)
				self:OpenOrCloseWeaponPartEffect(self.CurSelectSlotMeshComponent, false)
			end
			self.CurSelectSlotMeshComponent = MeshCompoent
			self.TheArsenalModel:SwitchPostProcessVolume(2)
			self.CurSelectSlotMeshComponent:SetGameplayStencilState(1)
			self:OpenOrCloseWeaponPartEffect(MeshCompoent, true, Slot)
		end
	end
end

function M:OpenOrCloseWeaponPartEffect(MeshComponent, IsShow, Slot)
	if not MeshComponent then
		return
	end
	if not IsShow then
		--Cleanup All The Attach Effects
		local ChildComponents = MeshComponent:GetChildrenComponents(false)
		local Num = ChildComponents:Num()
		if Num > 0 then
			local Component = ChildComponents:Get(1)
			if Component ~= nil and Component:Cast(UE.UNiagaraComponent) then
				Component:K2_DestroyComponent(MeshComponent)
			end
		end
	else
		--Spawn Effect And Attach To MeshComponent
		if not Slot then
			return
		end
		local NiagraCfg = self.CurWeaponAvatar:GetAvatarNiagraConfig(Slot)
		if not NiagraCfg then
			return
		end
		local NiagaraSystem = NiagraCfg.NiagaraAsset:LoadSynchronous()
		if not NiagaraSystem then
			return
		end

		local FXSpawnParameter = UE.FFXSystemSpawnParameters()
		FXSpawnParameter.SystemTemplate = NiagaraSystem
		FXSpawnParameter.AttachToComponent = MeshComponent
		FXSpawnParameter.AttachPointName = MeshComponent:GetAttachSocketName()
		FXSpawnParameter.Location = NiagraCfg.Translation
		FXSpawnParameter.Rotation = NiagraCfg.Rotation
		FXSpawnParameter.Scale = NiagraCfg.Scale
		FXSpawnParameter.LocationType = UE.EAttachLocation.SnapToTargetIncludingScale
		UE.UNiagaraFunctionLibrary.SpawnSystemAttachedWithParams(FXSpawnParameter)
	end
end


--HOVER插槽
function M:ON_HOVER_SELECT_ATTACHMENT_SLOT(Param)
	if Param == nil then
		return
	end
	self:OpenOrCloseHoverWeaponPartShine(Param.IsHover, Param.SlotType)
end

function M:OpenOrCloseHoverWeaponPartShine(Value, Slot)
	if not self.CurWeaponAvatar then
		return
	end

	local AvatarComponent = self.CurWeaponAvatar:GetAvatarComponent()
	local RootComponent = self.CurWeaponAvatar:K2_GetRootComponent()
	if not RootComponent or not AvatarComponent then
		return
	end
	--先关闭其他的
	local AllMeshComponents = RootComponent:GetChildrenComponents(true)
	local Num =  AllMeshComponents:Num()
	for i=1, Num do
		local MeshComponent = AllMeshComponents:Get(i)
		if MeshComponent and MeshComponent:Cast(UE.UMeshComponent) then
			if self.CurSelectSlotMeshComponent ~= MeshComponent then
				MeshComponent:SetGameplayStencilState(0)
			end
		end	
	end

	local ComponentTag = self.TheWeaponModel:GetSlotTagBySlotType(Slot)
	local MeshComponent = AvatarComponent:GetAttachedMeshComponent(ComponentTag, false)
	if not MeshComponent or self.CurSelectSlotMeshComponent == MeshComponent then
		return
	end
	
	if Value then
		self.TheArsenalModel:SwitchPostProcessVolume(2)
		MeshComponent:SetGameplayStencilState(3)
		MeshComponent:SetHiddenInGame(false)
	else
		MeshComponent:SetGameplayStencilState(0)
	end
end


--设置相机Tracking焦点
function M:PlayWeaponPartBlurLS(Slot, IsReverse)
	local LSParam = {
		LSId = HallModel.LSTypeIdEnum.LS_ARSENAL_HALL_FOCUS_WEAPONPART,
		Tag = "CameraLS_FocusWeaponPart"
	}
    local LSPath = MvcEntry:GetModel(HallModel):GetLSPathById(LSParam.LSId)
    if LSPath then
        --播放镜头动画
        local SetBindings = {}
        local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
        if CameraActor ~= nil then
            local CameraBinding = {
                ActorTag = "",
                Actor = CameraActor, 
                TargetTag = SequenceModel.BindTagEnum.CAMERA,
            }
            table.insert(SetBindings,CameraBinding)
        end
        local PlayParam = {
            LevelSequenceAsset = LSPath,
            SetBindings = SetBindings,
			IsPlayReverse = IsReverse,
            NeedStopAllSequence = true,
        }
        MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(LSParam.Tag, function ()
			if IsReverse then
				local Param = {
					FocusMethod = UE.ECameraFocusMethod.Disable,
				}
				MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_CAMERA_FOCUSSETTING_CHANGE,Param)
			end
        end, PlayParam)
    end
end


--[[
	操作相关
]]--

--设为展示
function M:OnGUIButtonSelect()
	local SelectWeaponId = self.TheWeaponModel:GetSelectWeaponId()
	if SelectWeaponId ~= self.CurSelectWeaponId then
		MvcEntry:GetCtrl(ArsenalCtrl):SendProto_SelectWeaponReq(self.CurSelectWeaponId)
	end
end

--展示中
function M:OnGUIButtonSelected()
	
end

--查看皮肤
function M:OnGUIButtonSkin()
	local Param = {
		WeaponId = self.CurSelectWeaponId,
		--WeaponTransform = self.CurWeaponAvatar:GetTransform()
	}
	MvcEntry:OpenView(ViewConst.WeaponSkin, Param)
	self:InteractSkinRedDot()
end

----------------------------------------------reddot >>
-- 绑定红点
function M:RegisterSkinRedDot()
	local RedDotKey = "ArsenalWeaponSkin_"
	local RedDotSuffix = self.CurSelectWeaponId
	if not self.SkinRedDot then
		self.SkinRedDot = UIHandler.New(self,  self.GUIButtonSkin.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
	else
		self.SkinRedDot:ChangeKey(RedDotKey, RedDotSuffix)
	end
end

-- 红点触发逻辑
function M:InteractSkinRedDot()
    if self.SkinRedDot then
        self.SkinRedDot:Interact()
    end
end
----------------------------------------------reddot >>

return M