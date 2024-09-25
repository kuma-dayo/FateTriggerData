

require "UnLua"
local class_name = "SettingKeyMapConflict"
SettingKeyMapConflict = SettingKeyMapConflict or BaseClass(GameMediator, class_name);


function SettingKeyMapConflict:__init()
    
    print("SettingKeyMapConflict:__init")
    self:ConfigViewId(ViewConst.SettingKeyMapConflict)
    
end


function SettingKeyMapConflict:OnHide()
end


local SettingKeyMapConflict = Class("Client.Mvc.UserWidgetBase")



function SettingKeyMapConflict:OnInit()
    print("SettingKeyMapConflict:OnInit")
    -- self.MsgList = 
    -- {
	-- 	{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnClicked_GUIButton_Close },
    --     {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Enter), Func = self.OnClicked_GUIButton_ResetDefault },
    -- }
    self.BindNodes ={
    { UDelegate = self.CommonBtn_Cancel.GUIButton_Tips.OnClicked, Func = self.OnClicked_GUIButton_Close },
    { UDelegate = self.CommonBtn_Confirm.GUIButton_Tips.OnClicked, Func = self.OnClicked_GUIButton_ResetDefault},
    }

    -- self.CommonBtn_Cancel.ControlTipsTxt:SetText(self.RetrunText)
    -- self.CommonBtn_Cancel.ControlTipsIcon:SetBrushFromSoftTexture(self.ReturnNormalIcon)
    -- self.CommonBtn_Cancel.ControlTipsTxt:SetColorAndOpacity(self.TxtNormalColor)
    -- self.CommonBtn_Confirm.ControlTipsTxt:SetText(self.ConfirmText)
    -- self.CommonBtn_Confirm.ControlTipsIcon:SetBrushFromSoftTexture(self.ConfirmNormalIcon)
    -- self.CommonBtn_Confirm.ControlTipsTxt:SetColorAndOpacity(self.TxtNormalColor)
    -- self:SetHoveredStyle(self.CommonBtn_Cancel,self.ReturnNormalIcon,self.ReturnHoverIcon)
    -- self:SetHoveredStyle(self.CommonBtn_Confirm,self.ConfirmNormalIcon,self.ConfirmHoverIcon)
    UserWidgetBase.OnInit(self)
end

function SettingKeyMapConflict:OnDestroy()
    UserWidgetBase.OnDestroy(self)
end


function SettingKeyMapConflict:OnShow(InContext)
    print("SettingKeyMapConflict:OnShow")
    
    if self.MvcCtrl and self.viewId then
        self.AskTagName = InContext.AskTagName
        self:SetContent(InContext)
        self.CommonBtn_Confirm:OnShow(InContext,nil)
        self.CommonBtn_Cancel:OnShow(InContext,nil)
    end
    local GenericGamepadUMGSubsystem = UE.UGenericGamepadUMGSubsystem.Get(GameInstance)
    if GenericGamepadUMGSubsystem  then 
        local status = GenericGamepadUMGSubsystem:IsInGamepadInput()
        self.CommonBtn_Confirm:SetKeyIcon(status)
        self.CommonBtn_Cancel:SetKeyIcon(status)
    end
    
end


function SettingKeyMapConflict:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    print("SettingKeyMapConflict:OnTipsInitialize")
    local TxtKey = UE.FGenericBlackboardKeySelector()
    
    TxtKey.SelectedKeyName ="TabText"
    local Title,IsFindTitle =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(TipGenricBlackboard,TxtKey)
    
    TxtKey.SelectedKeyName ="DetailText"
    local Detail,IsFindDetail =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(TipGenricBlackboard,TxtKey)
    TxtKey.SelectedKeyName ="AskTagName"
    local tmpAskTagName,IsFindAskTagName =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(TipGenricBlackboard,TxtKey)
    self.AskTagName = tmpAskTagName
    local Data ={
        TabText = Title,
        DetailText = Detail,
    }
    
    self:SetContent(Data)
end

function SettingKeyMapConflict:SetContent(data)
   
    print("SettingKeyMapConflict:SetContent",data)
    self.GUITextBlock_TabText:SetText(data.TabText)
    self.GUITextBlock_Detail:SetText(data.DetailText)
    
end

-- function SettingKeyMapConflict:SetHoveredStyle(Button,UnhoverIcon,HoverIcon)
    
--     Button.GUIButton_Tips.OnHovered:Add(self, function()
--         Button.ControlTipsIcon:SetBrushFromSoftTexture(HoverIcon)
--         Button.ControlTipsTxt:SetColorAndOpacity(self.TxtHoverColor)
--     end)

--     Button.GUIButton_Tips.OnUnhovered:Add(self, function()
--         Button.ControlTipsIcon:SetBrushFromSoftTexture(UnhoverIcon)
--         Button.ControlTipsTxt:SetColorAndOpacity(self.TxtNormalColor)
--     end)
-- end


function SettingKeyMapConflict:OnClicked_GUIButton_Close()
    print("SettingSetPopUp:OnClicked_GUIButton_Close ESC")
    self:SetFocus(false)
    if self.MvcCtrl and self.viewId then
        --通过Mvc框架管理的
        MvcEntry:CloseView(self.viewId)  
    else
        local TipsManager = UE.UTipsManager.GetTipsManager(self)
        TipsManager:RemoveTipsUI("Setting.SettingKeyMapConflict")
        MsgHelper:Send(self, "UIEvent.ESCSetting")
    end
    
    
end

function SettingKeyMapConflict:OnClicked_GUIButton_ResetDefault()
    print("SettingKeyMapConflict:OnClicked_GUIButton_ResetDefault AskTagName",self.AskTagName)
    --如果确认离开的话，将设置系统的冲突数据清空，并发消息更新
    UE.UGenericSettingSubsystem.Get(self):ResetKeyMapConflict()
    if self.AskTagName == nil or self.AskTagName =="nil" or self.AskTagName == "" then
        MsgHelper:Send(self, "UIEvent.SettingHide")
    else
        
        print("SettingKeyMapConflict:OnClicked_GUIButton_ResetDefault AskTagName GetWorld",self:GetWorld())
        MsgHelper:Send(self, "UIEvent.RefreshSubContent",self.AskTagName)
    end
    
    
    self:OnClicked_GUIButton_Close()
end


function SettingKeyMapConflict:OnKeyDown(MyGeometry,InKeyEvent)  
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    print("SettingKeyMapConflict:OnKeyDown",PressKey)
    if PressKey == self.CommonBtn_Cancel.Key or PressKey ==  self.CommonBtn_Cancel.GamepadKey then
        self:OnClicked_GUIButton_Close()
        
    elseif  PressKey == self.CommonBtn_Confirm.Key  or  PressKey == self.CommonBtn_Confirm.GamepadKey   then
        self:OnClicked_GUIButton_ResetDefault()
    end
    return UE.UWidgetBlueprintLibrary.Handled()
    
end
function SettingKeyMapConflict:OnChangeInputType(InStatus)
    self.CommonBtn_Confirm:SetKeyIcon(InStatus)
    self.CommonBtn_Cancel:SetKeyIcon(InStatus)
end

return SettingKeyMapConflict