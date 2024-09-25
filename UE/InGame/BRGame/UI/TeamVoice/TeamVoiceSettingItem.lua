require "UnLua"


local TeamVoiceSettingItem = Class("Common.Framework.UserWidget")


function TeamVoiceSettingItem:OnInit()

    self.BindNodes ={
        { UDelegate = self.BtnVoice_1.GUIButton_Click.OnClicked, Func = self.OnButtonIndex1Clicked },
        { UDelegate = self.BtnVoice_2.GUIButton_Click.OnClicked, Func = self.OnButtonIndex2Clicked },
        { UDelegate = self.BtnVoice_3.GUIButton_Click.OnClicked, Func = self.OnButtonIndex3Clicked },
    }

    self:UpdateToggle(1)
    self.HoveredEvent = {Bind = nil,Call = nil}
    self.IsOnDelegateFunc= {}
    UserWidget.OnInit(self)
end

function TeamVoiceSettingItem:AddSwicthEvent(src,IsOnDelegateFunc)
    --设置回调函数
    table.insert(self.IsOnDelegateFunc, {Bind = src,Call = IsOnDelegateFunc})
end

function TeamVoiceSettingItem:SwicthEventBoradCast(bIsOn)
    if not self.IsOnDelegateFunc then
        return
    end

    if self.IsOnDelegateFunc then
        for _, event in ipairs(self.IsOnDelegateFunc) do
            event.Call(event.Bind,bIsOn)
        end
    end
end

function TeamVoiceSettingItem:BindHoveredEvent(src,Func)
    self.HoveredEvent = {Bind = src,Call = Func}
end

function TeamVoiceSettingItem:SetState(bState)
    self.Active = bState
    self:SetIsEnabled(bState)

    if self.Active==false then
        self.BtnVoice_1.GUIImageBG:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.BtnVoice_2.GUIImageBG:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.BtnVoice_3.GUIImageBG:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end



function TeamVoiceSettingItem:OnButtonIndex1Clicked()
    if self.Index == 0  then
        return
    end
    self.Index = 0
    self:SwicthEventBoradCast(self.Index)
end

function TeamVoiceSettingItem:OnButtonIndex2Clicked()
    if self.Index == 1  then
        return
    end
    self.Index = 1
    self:SwicthEventBoradCast(self.Index)
end

function TeamVoiceSettingItem:OnButtonIndex3Clicked()
    if self.Index == 2  then
        return
    end
    self.Index = 2 
    self:SwicthEventBoradCast(self.Index)
end

function TeamVoiceSettingItem:UpdateToggle(Index)
    
    if self.Active == false then

        self.BtnVoice_1:SetSelectionState(false)
        self.BtnVoice_2:SetSelectionState(false)
        self.BtnVoice_3:SetSelectionState(false)
        return
    end

    self.Index = Index

    self.BtnVoice_1:SetSelectionState(self.Index == 0)
    self.BtnVoice_2:SetSelectionState(self.Index == 1)
    self.BtnVoice_3:SetSelectionState(self.Index == 2)

end


function TeamVoiceSettingItem:OnMouseEnter(MyGeometry,MouseEvent)
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    self.NameBlock:SetColorAndOpacity(self.TextEnableColor)

    if self.HoveredEvent.Bind then
        self.HoveredEvent.Call(self.HoveredEvent.Bind,self.TextEnableColor)
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function TeamVoiceSettingItem:OnMouseLeave(MyGeometry,MouseEvent)
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.NameBlock:SetColorAndOpacity(self.TextDisableColor)

    if self.HoveredEvent.Bind then
        self.HoveredEvent.Call(self.HoveredEvent.Bind,self.TextDisableColor)
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end







return TeamVoiceSettingItem
