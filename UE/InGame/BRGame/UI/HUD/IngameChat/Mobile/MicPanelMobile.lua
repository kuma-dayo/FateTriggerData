local MicPanelMobile = Class("Common.Framework.UserWidget")

local EMicMode = {
    Near = 0, --附近人麦
    Team = 1,   --队伍麦
    Close = 2,  --关闭
}

local EMicropKeyMode = {
    PressChat = 0, --按下说话
    Free = 1,   --自由麦
}

function MicPanelMobile:OnInit()
    print("MicPanelMobile >> OnInit self=",GetObjectName(self))
    local LocalPC = self:GetOwner()
    if LocalPC:GetLocalRole() == UE.ENetRole.ROLE_Authority then return end
    self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.BattleChat_OnOpenOrCloseVoiceChat,            Func = self.OnRefreshPanel,      bCppMsg = true },
    }
    self.BattleChatComp =  UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    self.ButtonTable = {
        ["NearMic"] = self.BP_NearMicMode,
        ["TeamMic"] = self.BP_TeamMicMode,
        ["CloseMic"] = self.BP_CloseMicMode,
        ["NearMicPress"] = self.BP_NearMicPressMode,
        ["TeamMicPress"] = self.BP_TeamMicPressMode,
    }
    self:RegistEvent()
    UserWidget.OnInit(self)
end

function MicPanelMobile:OnDestroy()
    print("MicPanelMobile >> OnDestroy self=",GetObjectName(self))
    self:UnRegistEvent()
    UserWidget.OnDestroy(self)
end

function MicPanelMobile:OnShow()
    self:OnRefreshPanel()
end

function MicPanelMobile:RegistEvent()
    self.BP_NearMicMode.Button.OnClicked:Add(self,self.OnSwitchNearMicMode)
    self.BP_TeamMicMode.Button.OnClicked:Add(self,self.OnSwitchTeamMicMode)
    self.BP_CloseMicMode.Button.OnClicked:Add(self,self.OnSwitchCloseMicMode)
    self.BP_NearMicPressMode.Button.OnClicked:Add(self,self.OnSwitchNearMicPressMode)
    self.BP_TeamMicPressMode.Button.OnClicked:Add(self,self.OnSwitchTeamMicPressMode)
end

function MicPanelMobile:UnRegistEvent()
    self.BP_NearMicMode.Button.OnClicked:Clear()
    self.BP_TeamMicMode.Button.OnClicked:Clear()
    self.BP_CloseMicMode.Button.OnClicked:Clear()
    self.BP_NearMicPressMode.Button.OnClicked:Clear()
    self.BP_TeamMicPressMode.Button.OnClicked:Clear()
end

function MicPanelMobile:OnSwitchNearMicMode()
    self.BattleChatComp:SetVoiceNeedsPress(EMicropKeyMode.Free)
    self.BattleChatComp:SetVoiceMicMode(EMicMode.Near)
end

function MicPanelMobile:OnSwitchTeamMicMode()
    self.BattleChatComp:SetVoiceNeedsPress(EMicropKeyMode.Free)
    self.BattleChatComp:SetVoiceMicMode(EMicMode.Team)
end

function MicPanelMobile:OnSwitchCloseMicMode()
    self.BattleChatComp:SetVoiceNeedsPress(EMicropKeyMode.Free)
    self.BattleChatComp:SetVoiceMicMode(EMicMode.Close)
end

function MicPanelMobile:OnSwitchNearMicPressMode()
    self.BattleChatComp:SetVoiceNeedsPress(EMicropKeyMode.PressChat)
    self.BattleChatComp:SetVoiceMicMode(EMicMode.Near)
end

function MicPanelMobile:OnSwitchTeamMicPressMode()
    self.BattleChatComp:SetVoiceNeedsPress(EMicropKeyMode.PressChat)
    self.BattleChatComp:SetVoiceMicMode(EMicMode.Team)
end


function MicPanelMobile:OnRefreshPanel()
    if self.BattleChatComp then
        local MicropKeyMode = self.BattleChatComp.VoiceNeedPressSetting
        local VoiceMicMode = self.BattleChatComp.VoiceMicMode

        if VoiceMicMode == EMicMode.Close then
            self:SetButtonEnable("CloseMic")
            return
        end

        if MicropKeyMode == EMicropKeyMode.Free then
            if VoiceMicMode == EMicMode.Near then
                self:SetButtonEnable("NearMic")
            elseif VoiceMicMode == EMicMode.Team then
                self:SetButtonEnable("TeamMic")
            end
        else
            if VoiceMicMode == EMicMode.Near then
                self:SetButtonEnable("NearMicPress")
            elseif VoiceMicMode == EMicMode.Team then
                self:SetButtonEnable("TeamMicPress")
            end
        end
    end
end

function MicPanelMobile:SetButtonEnable(BtnKeyName)
    for KeyName, BtnWidget in pairs(self.ButtonTable) do
        if KeyName == BtnKeyName then
            BtnWidget:SetEnable(true)
        else
            BtnWidget:SetEnable(false)
        end
    end
end

return MicPanelMobile
