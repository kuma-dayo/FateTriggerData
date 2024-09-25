require "UnLua"

local SettingSliderItem = Class("Common.Framework.UserWidget")

function SettingSliderItem:OnInit()
    if BridgeHelper.IsMobilePlatform() then
        
        self.BP_Text_Title.ParentTag = self.ParentTag
    end
    self.BindNodes = 
    {
        { UDelegate = self.Slider.OnValueChanged, Func = self.OnSlideValueChanged },
       
        --{ UDelegate = self.EditableText_Value.OnTextChanged, Func = self.OnEditableTextChanged },
        { UDelegate = self.EditableText_Value.OnTextCommitted, Func = self.OnEditableTextCommitted },
        --{ UDelegate = self.SubButton.Button_Sub.OnClicked, Func = self.OnClickedSubButton },
        --{ UDelegate = self.AddButton.Button_Add.OnClicked, Func = self.OnClickedAddButton },
        { UDelegate = self.AddButton.Button_Add.OnPressed, Func = self.OnAddPressedButtonDown },
        { UDelegate = self.SubButton.Button_Sub.OnPressed, Func = self.OnSubPressedButtonDown },
        { UDelegate = self.AddButton.Button_Add.OnReleased, Func = self.OnAddReleasedButtonUp },
        { UDelegate = self.SubButton.Button_Sub.OnReleased, Func = self.OnSubReleasedButtonUp },
    }

    self.MsgListGMP = {
        { MsgName = "EnhancedInput.SubSetting",	Func = self.OnClickedSubButton,   bCppMsg = true},
        { MsgName = "EnhancedInput.AddSetting",	Func = self.OnClickedAddButton,   bCppMsg = true},
    }
    if self.MsgListGMP then
        MsgHelper:RegisterList(self, self.MsgListGMP)
    end
    UserWidget.OnInit(self)
    self.IsBusy = false
    self.IsSliderShouldApply = false
end

function SettingSliderItem:OnDestroy()
   
    if self.MsgListGMP then
        MsgHelper:UnregisterList(self, self.MsgListGMP)
    end
    UserWidget.OnDestroy(self)
end

--给滑条设置初始化数据的
function SettingSliderItem:InitDataInLua(InTag,MinValue,MaxValue,StepSize,Keepdecimal)
    --print("SettingSliderItem:InitDataInLua",InTag.TagName,MinValue,MaxValue,StepSize,Keepdecimal)
    self.Slider:SetMinValue(MinValue)
    self.Slider:SetMaxValue(MaxValue)
    self.Slider:SetStepSize(StepSize)
    if StepSize>1 then
        self.Slider:SetMouseUsesStep(true)
    else
        self.Slider:SetMouseUsesStep(false)
    end
    self.ProgressBar:SetPercent(0)
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    local SettingValue = SettingSubsystem:GetSubContentConfigData(InTag)
    local value = SettingValue.Value_Float
    if self.IsIntSlider == true then
        value = math.floor(SettingValue.Value_Float)
    else
        self.Keepdecimal = Keepdecimal
        value = self:GetKeepdecimalValue(value)
    end
    print("SettingSliderItem:InitDataInLua234",InTag.TagName,self.Slider.MinValue,self.Slider.MaxValue,self:GetKeepdecimalValue(StepSize),Keepdecimal)
    
    
    
    
     self.TextBlock_Value:SetText(value)
     self.EditableText_Value:SetText(value)
     local Percent=  UE.UKismetMathLibrary.MapRangeClamped(value,MinValue,MaxValue,0,1)
     self.ProgressBar:SetPercent(Percent)
    self.IsSliderShouldApply = false
    self.Slider:SetValue(value)
    self.IsSliderShouldApply = true
    if BridgeHelper.IsMobilePlatform() then
        self:OnSlideValueChanged(value)
    end
    --self:SetAllValue(value)
    
    SettingSubsystem:CheckNeedToFreshData(InTag.TagName)
   
   
end



function SettingSliderItem:SetHoverStyle()
   
    UE.UGTSoundStatics.PostAkEvent(self, self.HoverSound)
    
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.TextBlock_Title:SetColorAndOpacity(self.TextHoverColor)
    self.GUIImage_Bg_List:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TextBlock_Value:SetVisibility(UE.ESlateVisibility.Collapsed)
    --self.TextBlock_Value:SetColorAndOpacity(self.TextHoverColor)
    
    self.EditableText_Value:SetVisibility(UE.ESlateVisibility.Visible)
    self.WidgetSwitcher_ValueBg:SetActiveWidgetIndex(1)
    --self.EditableText_Value:SetText(self.TextBlock_Value:GetText())
     local data =
    {
        InTag = self.ParentTag,
        IsShowTableDetailWidget = false,
        InBlackboard = UE.FGenericBlackboardContainer()
    }
    MsgHelper:Send(self, "UIEvent.ChangeDetailContent",data)
end


function SettingSliderItem:SetNormalStyle()
    
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TextBlock_Title:SetColorAndOpacity(self.TextOriginalColor)
    self.GUIImage_Bg_List:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --self.TextBlock_Value:SetColorAndOpacity(self.TextOriginalColor)
    self.TextBlock_Value:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.EditableText_Value:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WidgetSwitcher_ValueBg:SetActiveWidgetIndex(0)
    --self.EditableButton:SetVisibility(UE.ESlateVisibility.Visible)
end


-- 鼠标按键移入
function SettingSliderItem:OnMouseEnter(InMyGeometry, InMouseEvent)
   
    if BridgeHelper.IsPCPlatform() then self:SetHoverStyle() end
    --通知detail更新
   
end


-- 鼠标按键移出
function SettingSliderItem:OnMouseLeave(InMouseEvent)
	if BridgeHelper.IsPCPlatform() then self:SetNormalStyle() end
    self.IsSliderShouldApply = true
    self:OnEditableTextCommitted(self.EditableText_Value:GetText(),nil)
    --self.IsSliderShouldApply = false
end



function SettingSliderItem:RefreshItemContent(ItemContent)
    --print("SettingSliderItem:RefreshItemContent DefaultValue",ItemContent.DefaultValue,self.ParentTag.TagName,ItemContent.Value)
    self.Slider:SetValue(ItemContent.Value)
    --self:SetAllValue(ItemContent.Value)
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    SettingSubsystem:ApplySetting(self.ParentTag.TagName,self.SettingValue)
end




function SettingSliderItem:OnSlideValueChanged(InValue)
    -- print("SettingSliderItem:OnSlideValueChanged",self.ParentTag.TagName,InValue,self.Slider:GetValue())
    
    self:SetAllValue(InValue)
end



-- function SettingSliderItem:OnEditableTextCommitted(Text, CommitMethod)
--     if BridgeHelper.IsMobilePlatform() then
--         self.EditableSettingButton:SetVisibility(UE.ESlateVisibility.Visible)
--         self.TxtNum:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--         self.EditableTextValue:SetVisibility(UE.ESlateVisibility.Collapsed)
--     end
-- end

function SettingSliderItem:OnEditableTextCommitted(Text, CommitMethod)
    --print("SettingSliderItem:OnEditableTextCommitted",Text)
    local InTextNum = tonumber(Text)
    if InTextNum == nil  then InTextNum = self.Slider.MinValue end
    InTextNum = self:CheckRange(InTextNum)
    local EffectiveValue =  self:GetKeepdecimalValue(InTextNum)
    self.EditableText_Value:SetText(EffectiveValue)
    self.Slider:SetValue(EffectiveValue)
   
   
end




-- function SettingSliderItem:OnEditableTextChanged(Text)
    
--     if self.TextBlock_Value:GetText() == Text then return end
--     local InTextNum = tonumber(Text)
--     if InTextNum == nil  then 
--         InTextNum = tonumber(self.TextBlock_Value:GetText())
--      end
--     InTextNum = self:GetKeepdecimalValue(InTextNum)
    
--     self.EditableText_Value:SetText(InTextNum)
--     local EffectiveValue = self:CheckRange(InTextNum)
--     self.IsSliderShouldApply = true
--     self.Slider:SetValue(EffectiveValue)
--     --self.IsSliderShouldApply = true
    
    
--     print("SettingSliderItem:OnEditableTextChanged",Text,self.ParentTag.TagName,InTextNum,EffectiveValue,self.Slider:GetValue())
-- end

function SettingSliderItem:CheckRange(InValue)
    
    if InValue < self.Slider.MinValue then
        return self:GetKeepdecimalValue(self.Slider.MinValue)
       
    else
        if InValue > self.Slider.MaxValue then
            
            return self.Slider.MaxValue
        else
           return InValue
        end
    end
end

function SettingSliderItem:GetKeepdecimalValue(InValue)
    if self.IsIntSlider == true then 
        return math.round(InValue)
    end
    local power = 10^self.Keepdecimal
    local offset = 5/power/10
    return math.floor((InValue+offset)*power)/power
end

function SettingSliderItem:SetAllValue(InValue)
    local Value = InValue
    if self.IsIntSlider == true then
        Value = math.round(InValue)
    else
        Value = self:GetKeepdecimalValue(InValue)
    end
    self.TextBlock_Value:SetText(Value)
    self.EditableText_Value:SetText(Value)
    local Percent=  UE.UKismetMathLibrary.MapRangeClamped(InValue,self.Slider.MinValue,self.Slider.MaxValue,0,1)
    self.ProgressBar:SetPercent(Percent)
    self.SettingValue.Value_Float =InValue
    if self.IsSliderShouldApply == true then
        print("SettingSliderItem:ApplySetting",InValue)
        local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
        SettingSubsystem:ApplySetting(self.ParentTag.TagName, self.SettingValue)
    end
    
    print("SettingSliderItem:SetAllValue",self.ParentTag.TagName,InValue,Percent,Value,"IsSliderShouldApply",self.IsSliderShouldApply)
end

function SettingSliderItem:OnClickedSubButton()
    --print("SettingSliderItem:OnClickedSubButton")
    if self.IsBusy == false then
        return
    end
    self:SubSlider()
    
end

function SettingSliderItem:OnClickedAddButton()
    if self.IsBusy == false then
        return
    end
    self:AddSlider()
end


function SettingSliderItem:SubSlider()
    local NewValue = self.Slider:GetValue()-self.Slider.StepSize
    NewValue =self:CheckRange(tonumber(NewValue))
    print("SettingSliderItem:OnClickedSubButton",NewValue)
    self.Slider:SetValue(NewValue)
end

function SettingSliderItem:AddSlider()
    local NewValue = self.Slider:GetValue()+self.Slider.StepSize
    NewValue =self:CheckRange(tonumber(NewValue))
    self.Slider:SetValue(NewValue)
end

function SettingSliderItem:OnAddPressedButtonDown()
    --print("SettingSliderItem:OnAddPressedButtonDown")
    self.IsBusy = true
    self:OnClickedAddButton()
    if BridgeHelper.IsMobilePlatform() then
        self.AddButton.Switcher_Add:SetActiveWidgetIndex(1)
        
    end
end


function SettingSliderItem:OnAddReleasedButtonUp()
    self.IsBusy = false
    if BridgeHelper.IsMobilePlatform() then
        self.AddButton.Switcher_Add:SetActiveWidgetIndex(0)
        
    end
end

function SettingSliderItem:OnSubPressedButtonDown()
    --print("SettingSliderItem:OnSubPressedButtonDown")
    self.IsBusy = true
    self:OnClickedSubButton()
    if BridgeHelper.IsMobilePlatform() then
        self.SubButton.Switcher_Sub:SetActiveWidgetIndex(1)
        
    end
end


function SettingSliderItem:OnSubReleasedButtonUp()
    self.IsBusy = false
    if BridgeHelper.IsMobilePlatform() then
        self.SubButton.Switcher_Sub:SetActiveWidgetIndex(0)
        
    end
end

function SettingSliderItem:OnFocusReceived(MyGeometry,InFocusEvent)
    if BridgeHelper.IsPCPlatform() then self:SetHoverStyle() end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function SettingSliderItem:OnFocusLost(InFocusEvent)
    if BridgeHelper.IsPCPlatform() then self:SetNormalStyle() end
   
end

return SettingSliderItem
