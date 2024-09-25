--[[
    载具视频
]]

local class_name = "VehicleDetailVideoMdt";
VehicleDetailVideoMdt = VehicleDetailVideoMdt or BaseClass(GameMediator, class_name);


function VehicleDetailVideoMdt:__init()
end

function VehicleDetailVideoMdt:OnShow(data)
end

function VehicleDetailVideoMdt:OnHide()

end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
	self.BindNodes = 
    {
		{ UDelegate = self.GUIButtonBgClose.OnClicked,				Func = self.OnEscClicked },
	}
	self.MsgList = 
    {
		-- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = Bind(self,self.OnEscClicked) },
	}
end

--由mdt触发调用
function M:OnShow(data)
	self.CurSelectVehicleId = data and data.SelectVehicleId or 0
	self:InitCommonUI()
	self:UpdateSelectVehicleInfo()
end

function M:OnHide()
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
	local VehicleSkillCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkillConfig, VehicleCfg[Cfg_VehicleConfig_P.SkillId])
    if VehicleSkillCfg ~= nil then 
		local IconTexture = LoadObject(VehicleSkillCfg[Cfg_VehicleSkillConfig_P.SkillIcon])
		if IconTexture then
			self.SkillIcon:SetBrushFromTexture(IconTexture)
		end
		self.SkillName:SetText(StringUtil.Format(VehicleSkillCfg[Cfg_VehicleSkillConfig_P.SkillName]))
		self.RichDesc:SetText(StringUtil.Format(VehicleSkillCfg[Cfg_VehicleSkillConfig_P.SkillDes]))
		--视频
		local Param = {
			--MediaPlayer组件
			MediaPlayer = self.MediaPlayer,
			--MediaSource路径
			MediaSourcePath = VehicleSkillCfg[Cfg_VehicleSkillConfig_P.SkillMovie],
			--WBP_Common_Video
			WBP_Common_Video = self.WBP_Common_Video,
			--是否自动播放
			AutoPlay = true,
			HideCloseTip = true
		}
		UIHandler.New(self,self.WBP_Common_Video.PanelVideo, CommonMediaPlayer, Param)
	end
end

function M:OnEscClicked()
	MvcEntry:CloseView(ViewConst.VehicleDetailVideo)
	return true
end


return M