--[[
    载具界面
]]


local class_name = "VehicleDetailMdt";
VehicleDetailMdt = VehicleDetailMdt or BaseClass(GameMediator, class_name);

require("Client.Modules.Arsenal.Vehicle.VehicleDetailItem")

function VehicleDetailMdt:__init()
end

function VehicleDetailMdt:OnShow(data)
end

function VehicleDetailMdt:OnHide()

end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
	self.BindNodes = 
    {
		{ UDelegate = self.WBP_ReuseList_Vehicle.OnUpdateItem,		Func = self.OnUpdateVehicleItem },
		{ UDelegate = self.GUIButtonSkill.OnClicked,				Func = self.OnButtonSkillClicked },
		{ UDelegate = self.GUIButtonSkillIcon.OnClicked,			Func = self.OnButtonSkillClicked },
		{ UDelegate = self.WBP_CommonListBtn.GUIButton_Main.OnClicked,			Func = self.OnPlateLotteryClicked },
	}
	self.MsgList = 
    {
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = Bind(self,self.OnEscClicked) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Left), Func = Bind(self,self.OnSwitchVehicle,-1) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Right), Func = Bind(self,self.OnSwitchVehicle,1)},
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.A), Func = Bind(self,self.OnSwitchVehicle,-1) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.D), Func = Bind(self,self.OnSwitchVehicle,1)},
		{Model = VehicleModel, MsgName = VehicleModel.ON_SELECT_VEHICLE,	Func = self.OnUpdateSelectVehicle },
		{Model = VehicleModel, MsgName = VehicleModel.ON_SELECT_VEHICLE_SKIN,	Func = self.OnUpdateSelectVehicle },
		
		{Model = InputModel, MsgName = InputModel.ON_BEGIN_TOUCH,	Func = self.OnInputBeginTouch },
		{Model = InputModel, MsgName = InputModel.ON_END_TOUCH,		Func = self.OnInputEndTouch },
		{Model = VehicleModel, MsgName = VehicleModel.ON_UPDATE_VEHICLE_SKIN_SHOW,	Func = self.ON_UPDATE_VEHICLE_SKIN_SHOW },
		{Model = VehicleModel, MsgName = VehicleModel.ON_OPEN_VEHICLE_SKIN_STICKER_SHOW,	Func = self.ON_OPEN_VEHICLE_SKIN_STICKER_SHOW },
		{Model = VehicleModel, MsgName = VehicleModel.ON_LICENSEPLATE_SELECT,	Func =  self.ON_LICENSEPLATE_SELECT },
		
		
		{Model = VehicleModel, MsgName = VehicleModel.ON_UPDATE_VEHICLE_SKIN_STICKER_SHOW,	Func =  self.ON_UPDATE_VEHICLE_SKIN_STICKER_SHOW },
		{Model = VehicleModel, MsgName = VehicleModel.ON_ADD_VEHICLE_SKIN_STICKER,	Func =  self.ON_ADD_VEHICLE_SKIN_STICKER },
		{Model = VehicleModel, MsgName = VehicleModel.ON_REMOVE_VEHICLE_SKIN_STICKER,	Func =  self.ON_REMOVE_VEHICLE_SKIN_STICKER },
		{Model = VehicleModel, MsgName = VehicleModel.ON_UPDATE_VEHICLE_SKIN_STICKER,	Func =  self.ON_UPDATE_VEHICLE_SKIN_STICKER },	
	}
	self.TheVehicleModel = MvcEntry:GetModel(VehicleModel)
	self.TheArsenalModel = MvcEntry:GetModel(ArsenalModel)

	self.CurSelectVehicleId = self.TheVehicleModel:GetSelectVehicleId()
	self.IsFullScreenMode = false

	local CommonTabUpBarParam = {
        TitleTxt = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Weapon","11350"),
        -- TabParam = MenuTabParam -- todo 
    }
    self.CommonTabUpBarInstance = UIHandler.New(self,self.WBP_Common_TabUpBar_02,CommonTabUpBar,CommonTabUpBarParam).ViewInstance
end

--由mdt触发调用
function M:OnShow(data)
	self:InitCommonUI()
	self:ReloadVehicleList()
	self:UpdateLicensePlate()
end


function M:OnHide()
end

function M:OnShowAvator(data)
	self:ShowVehicleAvatar()
end

function M:OnHideAvator(data)
	self:HideVehicleAvatar()
end

function M:InitCommonUI()
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
        TipStr = self.TheArsenalModel:GetArsenalText("10018_Btn"),
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

	UIHandler.New(self,self.CommonBtnTips_FullScreen, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnFullScreenClicked),
        CommonTipsID = CommonConst.CT_LShift,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
		ActionMappingKey = ActionMappings.LShift
    })


	-- --通用Touch输入
	UIHandler.New(self, self.WBP_Common_TouchInput, CommonTouchInput, 
    {

    })
end

function M:ReloadVehicleList()
	self.VehicleIdList = {}
	local VehicleCfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_VehicleConfig, Cfg_VehicleConfig_P.IsShow, true)
	for _, Cfg in ipairs(VehicleCfgs) do
		table.insert(self.VehicleIdList, Cfg[Cfg_VehicleConfig_P.VehicleId])
    end

	local SelectVehicleId = self.TheVehicleModel:GetSelectVehicleId()
	table.sort(self.VehicleIdList,function (VehicleId1, VehicleId2)
        if SelectVehicleId == VehicleId1 then
			return true
		elseif SelectVehicleId == VehicleId2 then
			return false
		end
		return VehicleId1 < VehicleId2
    end)

	if #self.VehicleIdList > 0 then
		self.WBP_ReuseList_Vehicle:Reload(#self.VehicleIdList)
	end
end

function M:UpdateLicensePlate()
	self.WBP_WeaponVehicle_Plate_EntranceBtn:SetVisibility(UE.ESlateVisibility.Hidden)
	self.WBP_CommonListBtn:SetVisibility(UE.ESlateVisibility.Hidden)

	local LicensePlate = self.TheVehicleModel:GetVehicleLicensePlate(self.CurSelectVehicleId)
	self.WBP_WeaponVehicle_Plate_EntranceBtn.TextBlock_LicensePlate:SetText(LicensePlate)

	if self.VehicleAvatar then
		self.VehicleAvatar:UpdateVehiclePlate(self.CurSelectVehicleId, self.VehicleAvatar:GetCurShowSkinId())
	end
end

--[[
	载具Item被点击
]]
function M:OnVehicleItemClick(Item, VehicleId, DataIndex)
	if Item == nil then 
		return
	end
	self:UpdateVehicleSkinAvatar(VehicleId)
	self:OnSelectVehicleItem(Item)
end

function M:OnSelectVehicleItem(Item)
	if self.CurSelectVehicleItem then
		self.CurSelectVehicleItem:UnSelect()
	end
	self.CurSelectVehicleItem = Item
	if self.CurSelectVehicleItem then
		self.CurSelectVehicleItem:Select()
	end
	self:UpdateSelectVehicleShine()
	self:UpdateSelectVehicleInfo()

	self:RegisterSkinRedDot()
end

function M:CreateVehicleItem(Widget)
	self.VehicleItemWidgetList = self.VehicleItemWidgetList or {}
	local Item = self.VehicleItemWidgetList[Widget]
	if not Item then
		local Param = {
			OnItemClick = Bind(self,self.OnVehicleItemClick)
		}
		Item = UIHandler.New(self, Widget, VehicleDetailItem, Param)
		self.VehicleItemWidgetList[Widget] = Item
	end
	return Item.ViewInstance
end


function M:OnUpdateVehicleItem(Widget, Index)
	local i = Index + 1
	local VehicleId = self.VehicleIdList[i]
	if VehicleId == nil then
		return
	end

	local ListItem = self:CreateVehicleItem(Widget)
	if ListItem == nil then
		return
	end
    
    if VehicleId == self.CurSelectVehicleId then
		self:OnSelectVehicleItem(ListItem)
	else 
		ListItem:UnSelect()
	end
	ListItem:SetItemData(VehicleId,i)
end

function M:ShowVehicleAvatar(VehicleSkinId)
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr == nil then
		return 
	end
	if not self.CurSelectVehicleId then
		return
	end

	local CurEquipVehicleSkinId = self.TheVehicleModel:GetVehicleSkinId(self.CurSelectVehicleId)
	self.CurSelectVehicleSkinId = VehicleSkinId or CurEquipVehicleSkinId
	local TheTrans = CommonUtil.GetShowTranByItemID(ETransformModuleID.Arsenal_VehicleDetail.ModuleID, self.CurSelectVehicleSkinId)
	local SpawnParam = {
		ViewID = ViewConst.VehicleDetail,
		InstID = 0,
		VehicleID = self.CurSelectVehicleId,
		SkinID = self.CurSelectVehicleSkinId,
		Location = UE.FVector(0, 0, 0),
        Rotation = UE.FRotator(0, 0, 0),
		OpenCheckCameraSpringArm = true,
	}
    local VehicleAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_VEHICLE, SpawnParam)
    if VehicleAvatar ~= nil then				
		VehicleAvatar:CheckCameraSpringArm()
		VehicleAvatar:OpenOrCloseCameraMoveAction(false)
		VehicleAvatar:OpenOrCloseAvatorRotate(false)
		VehicleAvatar:OpenOrCloseGestureAction(true)
		VehicleAvatar:OpenOrCloseAutoRotateAction(true)
		VehicleAvatar:OpenOrCloseCameraTranslation(true)
		--重置位置
		VehicleAvatar:ResetCameraSpringArmRotation()
		VehicleAvatar:K2_SetActorRotation(TheTrans.Rot, false)
		VehicleAvatar:K2_SetActorLocation(TheTrans.Pos, false, nil, false)	
		VehicleAvatar:SetCameraFocusTracking()	
    end
	self.VehicleAvatar = VehicleAvatar
end

function M:HideVehicleAvatar()
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr ~= nil then
		HallAvatarMgr:HideAvatarByViewID(ViewConst.VehicleDetail)
	end
end

function M:HideVehicleAvatar()
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr ~= nil then
		HallAvatarMgr:HideAvatar(0, ViewConst.VehicleDetail, self.CurSelectVehicleId)
	end
end

function M:UpdateVehicleSkinAvatar(VehicleId, VehicleSkinId)
	if VehicleSkinId == nil and self.CurSelectVehicleId == VehicleId then
		return
	end
	self:HideVehicleAvatar()
	self.CurSelectVehicleId = VehicleId
	self:ShowVehicleAvatar(VehicleSkinId)

	self:UpdateLicensePlate()
end


function M:SetPropertyDesc(PropertyId, PropertyWidget)
	if PropertyWidget == nil then
		return false
	end
	local PropertyDesc = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleProperty, Cfg_VehicleProperty_P.Id, PropertyId)
	if PropertyDesc == nil then
		return false	
	end
	local Material = PropertyWidget.GUIImageProgress:GetDynamicMaterial()
	if Material ~= nil then
		Material:SetScalarParameterValue("SegmentNumber", 5)
		Material:SetScalarParameterValue("Value", PropertyDesc[Cfg_VehicleProperty_P.Value] / 100)
	end
	PropertyWidget.GUITextBlock:SetText(StringUtil.Format(PropertyDesc[Cfg_VehicleProperty_P.Name]))
	local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(PropertyDesc[Cfg_VehicleProperty_P.Icon])
	if ImageSoftObjectPtr ~= nil then
		PropertyWidget.GUIImageIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
	end

	return true
end

function M:UpdateSelectVehicleInfo()
	local VehicleCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleConfig, 
		Cfg_VehicleConfig_P.ItemId, self.CurSelectVehicleId)
    if VehicleCfg == nil then 
		return
	end
	self.Name:SetText(StringUtil.Format(VehicleCfg[Cfg_VehicleConfig_P.Name]))

	--属性
	local PropertyWidgets = {}
	table.insert(PropertyWidgets, self.WBP_Property_Item_1)
	table.insert(PropertyWidgets, self.WBP_Property_Item_2)
	table.insert(PropertyWidgets, self.WBP_Property_Item_3)
	table.insert(PropertyWidgets, self.WBP_Property_Item_4)
	for i=1,#PropertyWidgets do
		PropertyWidgets[i]:SetVisibility(UE.ESlateVisibility.Collapsed)
	end

	local PropertyIdList = VehicleCfg[Cfg_VehicleConfig_P.PropertyList]
	for Index, PropertyId in pairs(PropertyIdList) do
		local IsSet = self:SetPropertyDesc(PropertyId, PropertyWidgets[Index])
		if IsSet then
			PropertyWidgets[Index]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		end
	end
	--技能
	local VehicleSkillCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkillConfig, Cfg_VehicleSkillConfig_P.SkillId, VehicleCfg[Cfg_VehicleConfig_P.SkillId])
    if VehicleSkillCfg ~= nil then 
		local IconTexture = LoadObject(VehicleSkillCfg[Cfg_VehicleSkillConfig_P.SkillIcon])
		if IconTexture then
			self.GUIButtonImage:SetBrushFromTexture(IconTexture)
		end
		self.GUIButtonText:SetText(StringUtil.Format(VehicleSkillCfg[Cfg_VehicleSkillConfig_P.SkillName]))
	end

	--装备状态
	local SelectVehicleId = self.TheVehicleModel:GetSelectVehicleId()
	if SelectVehicleId == self.CurSelectVehicleId then 
		self.WidgetSwitcherSelect:SetActiveWidgetIndex(1)
	else 
		self.WidgetSwitcherSelect:SetActiveWidgetIndex(0)
	end
end

function M:OnEscClicked()
	if self.IsFullScreenMode then
		self.IsFullScreenMode = false
		self:UpdateFullScreenMode()
	end
	MvcEntry:CloseView(ViewConst.VehicleDetail)
end


function M:UpdateFullScreenMode()
	if self.IsFullScreenMode then
		self.Top:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.Center:SetVisibility(UE.ESlateVisibility.Collapsed)
		--self.Common_Bottom_Bar:SetVisibility(UE.ESlateVisibility.Collapsed)
		MvcEntry:GetModel(HallModel):DispatchType(HallModel.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE,false)
	else 
		self.Top:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		self.Center:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		--self.Common_Bottom_Bar:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		MvcEntry:GetModel(HallModel):DispatchType(HallModel.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE,true)
	end
end

function M:OnFullScreenClicked()
	self.IsFullScreenMode = not self.IsFullScreenMode
	self:UpdateFullScreenMode()
end


function M:OnButtonSkillClicked()
	MvcEntry:OpenView(ViewConst.VehicleDetailVideo, {SelectVehicleId = self.CurSelectVehicleId})
end

function M:OnPlateLotteryClicked()
	MvcEntry:OpenView(ViewConst.VehiclePlateLottery, 
	{
		VehicleId = self.CurSelectVehicleId,
	})
end


--[[ 
	获取选中载具的品质颜色
]]
function M:GetSelectVehicleQualityColor(SkinId)
	local VehicleSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinConfig, SkinId)
	if VehicleSkinCfg then
		local ItemId = VehicleSkinCfg[Cfg_WeaponSkinConfig_P.ItemId]
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
	播放载具选中特效
]]
function M:OpenOrCloseSelectVehicleShine(SkinId, Value, TagIndex)
	local function DoChgGlobalOpacityValueFunc(Opacity)
		if not self.VehicleAvatar then
			return
		end
		local SkinActor = self.VehicleAvatar:GetSkinActor(SkinId)
		if not SkinActor then
			return
		end
		local RootComponent =  SkinActor:K2_GetRootComponent()
		local AllMeshComponents = RootComponent:GetChildrenComponents(true)
		local Num =  AllMeshComponents:Num()
		for i=1, Num do
			local MeshComponent = AllMeshComponents:Get(i)
			if MeshComponent and MeshComponent:Cast(UE.UMeshComponent) then
				if not MeshComponent.bHiddenInGame and Value and MeshComponent ~= SkinActor.AO_Plane then
					local Param = {
						OutlineColor =  self:GetSelectVehicleQualityColor(SkinId) or UE.FLinearColor(1,1,1),
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

function M:UpdateSelectVehicleShine(SkinId)
	self:InsertTimer(Timer.NEXT_FRAME, function ()
		self:OpenOrCloseSelectVehicleShine(SkinId or self.CurSelectVehicleSkinId, true, 4)
	end)
end


--[[
    左右箭头按键切换载具
]]
function M:OnSwitchVehicle(Direction)
	if self.IsFullScreenMode then
		CWaring("FullScreen: Forbid Switch")
		return
	end

	if self.VehicleAvatar and self.VehicleAvatar:IsLerping() then
		CWaring("VehicleAvatar Lerping: Forbid Switch")
		return 
	end

	local Idx, SelectId = 0,0
	if Direction > 0 then 
		Idx,SelectId = CommonUtil.GetListNextIndex4Id(self.VehicleIdList, self.CurSelectVehicleId)
	else 
		Idx,SelectId = CommonUtil.GetListPreIndex4Id(self.VehicleIdList, self.CurSelectVehicleId)
	end
	if not SelectId then
		return
	end
	self:UpdateVehicleSkinAvatar(SelectId)
	self.WBP_ReuseList_Vehicle:Refresh()
	self.WBP_ReuseList_Vehicle:JumpByIdxStyle(Idx-1,UE.EReuseListJumpStyle.Content)
end


function M:OnInputBeginTouch()
	self.IsTouched = true
	if self.VehicleAvatar then
		self.VehicleAvatar:OpenOrCloseAutoRotateAction(false)
	end
end

function M:OnInputEndTouch()
	self.IsTouched = false
end

function M:OnUpdateSelectVehicle()
	self.WBP_ReuseList_Vehicle:Refresh()
end


function M:ON_UPDATE_VEHICLE_SKIN_SHOW(Param)
	if Param == nil then
		CWaring("Update Vehicle Skin Show Param Failed")
		return
	end

	if not Param.DisableAutoRotate then
		self:UpdateVehicleSkinAvatar(Param.VehicleId, Param.VehicleSkinId)
		self:UpdateSelectVehicleShine(Param.VehicleSkinId)
	else
		if self.VehicleAvatar then
			self.VehicleAvatar:OpenOrCloseAutoRotateAction(false)
		end	
	end
end


function M:ON_OPEN_VEHICLE_SKIN_STICKER_SHOW(Param)
	if Param == nil then
		CWaring("Update Vehicle Skin Sticker Show Param Failed")
		return
	end
	if self.VehicleAvatar == nil then
		return
	end

	self.VehicleAvatar:CheckCameraSpringArm()
	self.VehicleAvatar:OpenOrCloseAutoRotateAction(false)
	self.VehicleAvatar:OpenOrCloseCameraTranslation(false)
	--重置位置
	self.VehicleAvatar:ResetCameraSpringArmRotation()
	self.VehicleAvatar:K2_SetActorRotation(UE.FRotator(0, -40, 0), false)
	self.VehicleAvatar:K2_SetActorLocation(UE.FVector(99900.53, 1408, -91.0), false, nil, false)	
end


function M:ON_LICENSEPLATE_SELECT()
	self:UpdateLicensePlate()
end


function M:ON_UPDATE_VEHICLE_SKIN_STICKER_SHOW(Param)
	if Param == nil then
		return
	end
	if self.VehicleAvatar == nil then
		return
	end
	self.VehicleAvatar:UpdateVehicleSkinAllSticker(Param.VehicleSkinId)
end


function M:ON_ADD_VEHICLE_SKIN_STICKER(Param)
	if Param == nil then
		return
	end
	if self.VehicleAvatar == nil then
		return
	end
	local Component = self.VehicleAvatar:GetSkinDecalComponent(Param.VehicleSkinId, Param.StickerInfo.Slot)
	if not Component then
		self.VehicleAvatar:AddVehicleSkinSticker(Param.VehicleSkinId, Param.StickerInfo)	
	else
		self.VehicleAvatar:UpdateVehicleSkinSticker(Param.VehicleSkinId, Param.StickerInfo)	
	end
end

function M:ON_REMOVE_VEHICLE_SKIN_STICKER(Param)
	if Param == nil then
		return
	end
	if self.VehicleAvatar == nil then
		return
	end
	self.VehicleAvatar:RemoveVehicleSkinSticker(Param.VehicleSkinId, Param.StickerInfo.Slot)
end

function M:ON_UPDATE_VEHICLE_SKIN_STICKER(Param)
	if Param == nil then
		return
	end
	if self.VehicleAvatar == nil then
		return
	end
	--根据编辑信息，同步贴纸component显示
	self.VehicleAvatar:UpdateVehicleSkinSticker(Param.VehicleSkinId, Param.StickerInfo)
end


--[[
	操作相关
]]--

--设为展示
function M:OnGUIButtonSelect()
	local SelectVehicleId = self.TheVehicleModel:GetSelectVehicleId()
	if SelectVehicleId ~= self.CurSelectVehicleId then
		MvcEntry:GetCtrl(ArsenalCtrl):SendProto_SelectVehicleReq(self.CurSelectVehicleId)
	end
end

--展示中
function M:OnGUIButtonSelected()
	
end

--查看皮肤
function M:OnGUIButtonSkin()
	local Param = {
		VehicleId = self.CurSelectVehicleId
	}
	MvcEntry:OpenView(ViewConst.VehicleSkin, Param)

	self:InteractSkinRedDot()
end

----------------------------------------------reddot >>
-- 绑定红点
function M:RegisterSkinRedDot()
	local RedDotKey = "ArsenalVehicleSkin_"
	local RedDotSuffix = self.CurSelectVehicleId
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