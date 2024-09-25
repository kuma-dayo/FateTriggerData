local SpeakerPanelMobile = Class("Common.Framework.UserWidget")

--音频模式
local EAudioMode = {
    Near = 0, --附近人音频
    Team = 1,   --队伍音频
    Close = 2,  --关闭
}

function SpeakerPanelMobile:OnInit()
    print("SpeakerPanelMobile >> OnInit self=",GetObjectName(self))

    self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.BattleChat_OnOpenOrCloseVoiceChat,            Func = self.OnRefreshPanel,      bCppMsg = true },
    }
    self.BattleChatComp =  UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    self.ButtonTable = {
        ["NearSpeaker"] = self.BP_NearSpeaker,
        ["TeamSpeaker"] = self.BP_TeamSpeaker,
        ["CloseSpeaker"] = self.BP_CloseSpeaker,
    }
    

    self:RegistEvent()
    self:InitTeammatePlayerSpeaker()
    UserWidget.OnInit(self)
end

function SpeakerPanelMobile:OnDestroy()
    print("SpeakerPanelMobile >> OnDestroy self=",GetObjectName(self))
    self:UnRegistEvent()
    UserWidget.OnDestroy(self)
end

function SpeakerPanelMobile:RegistEvent()
    self.BP_NearSpeaker.Button.OnClicked:Add(self,self.OnSwitchNearSpeakerMode)
    self.BP_TeamSpeaker.Button.OnClicked:Add(self,self.OnSwitchTeamSpeakerMode)
    self.BP_CloseSpeaker.Button.OnClicked:Add(self,self.OnSwitchCloseSpeakerMode)
end

function SpeakerPanelMobile:UnRegistEvent()
    self.BP_NearSpeaker.Button.OnClicked:Clear()
    self.BP_TeamSpeaker.Button.OnClicked:Clear()
    self.BP_CloseSpeaker.Button.OnClicked:Clear()
end

function SpeakerPanelMobile:OnShow()
    self:OnRefreshPanel()
    self:InitTeammatePlayerSpeaker()
end

function SpeakerPanelMobile:OnSwitchNearSpeakerMode()
    self.BattleChatComp:SetSpeakerMode(EAudioMode.Near)
end

function SpeakerPanelMobile:OnSwitchTeamSpeakerMode()
    self.BattleChatComp:SetSpeakerMode(EAudioMode.Team)
end

function SpeakerPanelMobile:OnSwitchCloseSpeakerMode()
    self.BattleChatComp:SetSpeakerMode(EAudioMode.Close)
end


function SpeakerPanelMobile:OnRefreshPanel()
    if self.BattleChatComp then
        local SpeakerMode = self.BattleChatComp.SpeakerMode

        if SpeakerMode == EAudioMode.Close then
            self:SetButtonEnable("CloseSpeaker")
        elseif SpeakerMode == EAudioMode.Team then
            self:SetButtonEnable("TeamSpeaker")
        elseif SpeakerMode == EAudioMode.Near then
            self:SetButtonEnable("NearSpeaker")
        end
    end
end

function SpeakerPanelMobile:SetButtonEnable(BtnKeyName)
    for KeyName, BtnWidget in pairs(self.ButtonTable) do
        if KeyName == BtnKeyName then
            BtnWidget:SetEnable(true)
            self:ClickComplete()
        else
            BtnWidget:SetEnable(false)
        end
    end
end

function SpeakerPanelMobile:ClickComplete()
    -- local UIManager = UE.UGUIManager.GetUIManager(self)
    -- local ChatSuspendHandle = UIManager:TryLoadDynamicWidget("UMG_ChatSuspend");
end


function SpeakerPanelMobile:GetAllSpeakerSliderWidget()
    return {[1] = self.BP_TeamMember0,[2] = self.BP_TeamMember1,[3] = self.BP_TeamMember2}
end


function SpeakerPanelMobile:InitTeammatePlayerSpeaker()
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LocalPS = LocalPC and LocalPC.PlayerState or nil
    local TeamExSubsystem = UE.UTeamExSubsystem.Get(LocalPS)

    if TeamExSubsystem == nil then
        Warning("PlayerVoiceSettingsItem:InitializedPlayerInfoByID TeamExSubsystem = nil")
        return
    end

    local TeammatesPSList = TeamExSubsystem:GetTeammatePSListByPS(LocalPS)
    local TeammatesPSListLen = TeammatesPSList:Length()
    local SpeakerSliderWidgets = self:GetAllSpeakerSliderWidget()

    local TeammatesPSTable = {}

    for i = 1, TeammatesPSListLen do
        local SpeakerSliderWidget = SpeakerSliderWidgets[i]
        local IndexPS = TeammatesPSList:Get(i)
        if IndexPS and IndexPS ~= LocalPS then
            table.insert(TeammatesPSTable,IndexPS)

        end
    end

    for Index, Widget in pairs(SpeakerSliderWidgets) do
        local PS = TeammatesPSTable[Index]
        if PS then
            Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            Widget:InitInitTeammate(PS)
        else

            Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end


end

return SpeakerPanelMobile