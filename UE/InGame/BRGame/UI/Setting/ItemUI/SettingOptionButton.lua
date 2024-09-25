require "UnLua"

local SettingOptionButton = Class("Common.Framework.UserWidget")

function SettingOptionButton:OnInit()
    print("SettingOptionButton:OnInitxxxxxxxxxxx",GetObjectName(self))
    self.BindNodes = nil
    if BridgeHelper.IsPCPlatform() then 
        self.BindNodes = {{ UDelegate = self.OptionButton.OnClicked, Func = self.OnClick_ChangeOptionButtonBusy },}
    elseif BridgeHelper.IsMobilePlatform() then
        self.BindNodes = {{ UDelegate = self.Button_Select.OnClicked, Func = self.OnClick_ChangeOptionButtonBusy },}
    end
    --[[
    MsgHelper:UnregisterList(self, self.MsgList or {})
    self.MsgList = {
		{ MsgName = GameDefine.Msg.SETTING_NotifyRadioButton,            Func = self.OnChangeButton,      bCppMsg = false, WatchedObject = self },
		
    }
    MsgHelper:RegisterList(self, self.MsgList)
]]--
    UserWidget.OnInit(self)
end

function SettingOptionButton:OnDestroy()
    print("SettingOptionButton:OnDestroy")
    if self.BindNodes then
        MsgHelper:OpDelegateList(self, self.BindNodes, false)
		self.BindNodes = nil
	end
    
    
    UserWidget.OnDestroy(self)
end

function SettingOptionButton:OnShow(InContext)
    --print("SetSettingOptionButton:OnShow")
    if self.GUITextBlock then self.GUITextBlock:SetText(self.OptionButtonData.ShowText) end
    if self.Text_Noraml and self.Text_Select then
        self.Text_Noraml:SetText(self.OptionButtonData.ShowText)
        self.Text_Select:SetText(self.OptionButtonData.ShowText)
    end
    self:ChangeBusy(self.OptionButtonData.Value)
    
end

function SettingOptionButton:OnClick_ChangeOptionButtonBusy()
    --print("SettingOptionButton:OnClick_ChangeOptionButtonBusy",self.Index)
    self:ChangeBusy(true)
    self.NotifyRdioButtonBusy:Broadcast(self.Index)
end


function SettingOptionButton:OnInitialize(InOptionButtonData,InType)
    print("SetSettingOptionButton:OnInitialize InOptionButtonData:",InOptionButtonData.ShowText,InOptionButtonData.Value,InType,GetObjectName(self),self)
    print("SetSettingOptionButton:OnInitialize self.OptionButtonData:",self.OptionButtonData.ShowText,self.OptionButtonData.Value,InType,GetObjectName(self),self)
    if self.GUITextBlock then self.GUITextBlock:SetText(InOptionButtonData.ShowText) end
    if self.Text_Noraml and self.Text_Select then
        self.Text_Noraml:SetText(InOptionButtonData.ShowText)
        self.Text_Select:SetText(InOptionButtonData.ShowText)
    end
    self.ButtonType = InType
    self:ChangeBusy(InOptionButtonData.Value)


    
end


--点击后的表现
function SettingOptionButton:ChangeBusy(IsBusy)
    --print("SetSettingOptionButton:ChangeBusy",self,IsBusy,self.OptionButtonData.ShowText)
    self.OptionButtonData.Value = IsBusy
    if IsBusy == true then
        if self.GUIImageBG and self.GUITextBlock then
            self.GUIImageBG:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.GUITextBlock:SetColorAndOpacity(self.ClickedTextColor)
        end
        if self.Switcher then self.Switcher:SetActiveWidgetIndex(1) end
    else
        if self.GUIImageBG and self.GUITextBlock then
            self.GUIImageBG:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.GUITextBlock:SetColorAndOpacity(self.UnClickedTextColor)
        end
        if self.Switcher then self.Switcher:SetActiveWidgetIndex(0) end
    end
end


return SettingOptionButton