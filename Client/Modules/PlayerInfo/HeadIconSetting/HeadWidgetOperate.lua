--[[
   个人信息 - 个性化设置 - 头像挂件操作类 - WBP_HeadWidgetOperate
]] 
local HeadWidgetUtil = require("Client.Modules.PlayerInfo.HeadIconSetting.HeadWidgetUtil")
local class_name = "HeadWidgetOperate"
local HeadWidgetOperate = BaseClass(nil, class_name)

function HeadWidgetOperate:OnInit()
    ---@type HeadIconSettingModel
    self.HeadIconSettingModel = MvcEntry:GetModel(HeadIconSettingModel)
    self.MsgList = {
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_HEAD_WIDGET_EDITING,Func = Bind(self,self.OnEditing) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_ADJUST_HEAD_WIDGET_ANGLE,Func = Bind(self,self.OnAngleChanged) },
        {Model = HeadIconSettingModel, MsgName = HeadIconSettingModel.ON_SET_HEAD_WIDGET_CAN_SELECT,Func = Bind(self,self.OnSetCanSelect) },
    }
    self.BindNodes = {
		{ UDelegate = self.View.WBP_CommonBtn_Cir_Small_02.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnClick_Putoff) },
		{ UDelegate = self.View.SelectBtn.OnClicked,				Func = Bind(self,self.OnClick_SelectBtn) },
    }
end


function HeadWidgetOperate:OnShow()
end

function HeadWidgetOperate:OnHide()
end

--[[
    Param = {
        HeadWidgetId,
        Angle,
        Cfg,
        WidgetContainer
    }
]]
function HeadWidgetOperate:UpdateUI(Param)
    if not (Param and Param.HeadWidgetId) then
        return
    end
    self.Param = Param
    self.Cfg = self.HeadIconSettingModel:GetHeadIconSettintCfg(HeadIconSettingModel.SettingType.HeadWidget,self.Param.HeadWidgetId)
    if not self.Cfg then
        return
    end
    self.View.Panel_Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- self.View.Panel_Putoff:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.SelectBox:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.SelectBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function HeadWidgetOperate:OnEditing(_,HeadWidgetId)
    if self.Param.HeadWidgetId == HeadWidgetId then
        -- self.View.Panel_Putoff:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.SelectBox:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

function HeadWidgetOperate:OnAngleChanged(_,Msg)
    if not (Msg and Msg.HeadWidgetId) or self.Param.HeadWidgetId ~= Msg.HeadWidgetId then
        return
    end
    if not self.Cfg then
        return
    end
    local Angle = Msg.Angle
    local InitRotation =  self.Param.Cfg[Cfg_HeadWidgetCfg_P.InitRotation]
    local RotationAngle = InitRotation + Angle
    self.View.Bg:SetRenderTransformAngle(RotationAngle)
    local Type = self.Cfg[Cfg_HeadWidgetCfg_P.WidgetType]
    local IsStatic = Type == HeadIconSettingModel.HeadWidgetType.Static
    if IsStatic  then
        self.View.Panel_Widget:SetRenderTransformAngle(-RotationAngle)
    end
    HeadWidgetUtil.AdjustHeadWidget(IsStatic, self.Param.WidgetContainer, self.View, 1, RotationAngle)
end

function HeadWidgetOperate:OnSetCanSelect(_,CanSelect)
    self.View.SelectBtn:SetVisibility(CanSelect and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
end

function HeadWidgetOperate:OnClick_Putoff()
    self.HeadIconSettingModel:DelHeadWidgetTemp(self.Param.HeadWidgetId)
end

function HeadWidgetOperate:OnClick_SelectBtn()
    local SelectParam = {
        SettingType = HeadIconSettingModel.SettingType.HeadWidget,
        Id = self.Param.HeadWidgetId
    }
    self.HeadIconSettingModel:SetItemSelectParam(SelectParam)
    self.HeadIconSettingModel:DispatchType(HeadIconSettingModel.ON_SELECT_ITEM_AND_EDIT,SelectParam)
end

return HeadWidgetOperate
