local ChatSetMobile = Class("Common.Framework.UserWidget")


local EChatPanelMode = {
    Close = 0,
    TextChat = 1,
    SpeakSetting = 2,
    VoiceSetting = 3,
    Settings = 4,
}


local EMicMode = {
    Near = 0, --附近人麦
    Team = 1,   --队伍麦
    Close = 2,  --关闭
}

local EMicropKeyMode = {
    PressChat = 0, --按下说话
    Free = 1,   --自由麦
}

local EMicSetting = {
    Near = 0,
    Team = 1,
    NearPress = 2,
    TeamPress = 3,
    Close = 4,
}


function ChatSetMobile:OnInit()
    print("ChatSetMobile >> OnInit self=",GetObjectName(self))

    self.BattleChatComp =  UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    self.UIManager = UE.UGUIManager.GetUIManager(self)

    self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.BattleChat_OnOpenOrCloseVoiceChat,            Func = self.OnRefreshPanel,      bCppMsg = true },
        {
            MsgName = "EnhancedInput.Chat.HoldMicSay",
            Func = self.OnVoiceMicKey,
            bCppMsg = true
        },
    }

    self:RegistEvent()
    self.TextChatState = false
    self.ChatSpeakState = false
    self.ChatVoiceState = false
    self.MicSetting = EMicSetting.Close
    self.LastMicIAState = UE.ETriggerEvent.None

    self.ChatPanelMode = EChatPanelMode.Close
    self:UpdateChatPanel(EChatPanelMode.Close)
    UserWidget.OnInit(self)
end


function ChatSetMobile:OnVoiceMicKey(InInputData)
    

   -- print("[Wzp]ChatSetMobile1 >> OnVoiceMicKeyDown >> TriggerEvent=",TriggerEvent)
   local TriggerEvent = InInputData.TriggerEvent
    if self.LastMicIAState == TriggerEvent then
        return
    end
    print("[Wzp]ChatSetMobile1 >> OnVoiceMicKeyDown >> TriggerEvent=",TriggerEvent)
    self.LastMicIAState = TriggerEvent


    if TriggerEvent == UE.ETriggerEvent.Started then
    elseif TriggerEvent == UE.ETriggerEvent.Canceled then
        --打开UI
        self:OnClickSpeak()
    elseif TriggerEvent == UE.ETriggerEvent.Triggered then 
        --开始讲话
        if self.MicSetting == EMicSetting.TeamPress or self.MicSetting == EMicSetting.NearPress then
            self.BattleChatComp:OnVoiceMicKeyDown()
            -- self.WS_MicState:SetActiveWidgetIndex(5)
        end
    elseif TriggerEvent == UE.ETriggerEvent.Completed then 
        --结束讲话
        self.BattleChatComp:OnVoiceMicKeyUp()
        -- self.WS_MicState:SetActiveWidgetIndex(self.MicSetting)
    end
end


function ChatSetMobile:OnShow()
    print("ChatSetMobile >> OnShow self=",GetObjectName(self))
    self:OnRefreshPanel()
end


function ChatSetMobile:OnDestroy()
    print("ChatSetMobile >> OnDestroy self=",GetObjectName(self))
    self:UnRegistEvent()
    UserWidget.OnDestroy(self)
end

function ChatSetMobile:RegistEvent()
    self.Button_Message.OnClicked:Add(self,self.OnClickTextMsg)
    self.Button_Voice.OnClicked:Add(self,self.OnClickVoice)
    self.Button_Speak.OnClicked:Add(self,self.OnClickSpeak)
end

function ChatSetMobile:UnRegistEvent()
    self.Button_Message.OnClicked:Clear()
    self.Button_Voice.OnClicked:Clear()
    self.Button_Speak.OnClicked:Clear()
end

function ChatSetMobile:UpdateChatPanel(ChatPanelMode)
    self.ChatPanelMode = ChatPanelMode

    --设置成收起状态
    self.WidgetSwitcher_Message:SetActiveWidgetIndex(1)
    self.WS_MicPanelState:SetActiveWidgetIndex(1)
    self.WS_SpeakerPanelState:SetActiveWidgetIndex(1)
    --self.WidgetSwitcher_Set:SetActiveWidgetIndex(1)

    self.TextChatState = false
    self.ChatSpeakState = false
    self.ChatVoiceState = false

    if self.ChatPanelMode == EChatPanelMode.TextChat then
        self.WidgetSwitcher_Message:SetActiveWidgetIndex(0)
        self.TextChatState = true
        self.ChatMessageHandle = self.UIManager:TryLoadDynamicWidget("UMG_ChatMessage");
    elseif self.ChatPanelMode == EChatPanelMode.SpeakSetting then
        self.WS_MicPanelState:SetActiveWidgetIndex(0)
        self.ChatSpeakState = true
        self.SpeakSettingHandle = self.UIManager:TryLoadDynamicWidget("UMG_SpeakSetting");
    elseif self.ChatPanelMode == EChatPanelMode.VoiceSetting then
        self.WS_SpeakerPanelState:SetActiveWidgetIndex(0)
        self.ChatVoiceState = true
        self.CVoiceSettingHandle = self.UIManager:TryLoadDynamicWidget("UMG_VoiceSetting");
    elseif self.ChatPanelMode == EChatPanelMode.Close then
        self.ChatSuspendHandle = self.UIManager:TryLoadDynamicWidget("UMG_ChatSuspend");
    end
end

function ChatSetMobile:OnClickTextMsg()
       --点击文字聊天按钮
    print("ChatSetMobile >> OnClickTextMsg self=",GetObjectName(self))
    self.TextChatState = not self.TextChatState
    local State = self.TextChatState and EChatPanelMode.TextChat or EChatPanelMode.Close
    self:UpdateChatPanel(State)
end


function ChatSetMobile:OnClickSpeak()
    print("ChatSetMobile >> OnClickSpeak self=",GetObjectName(self))
    self.ChatSpeakState = not self.ChatSpeakState
    local State = self.ChatSpeakState and EChatPanelMode.SpeakSetting or EChatPanelMode.Close
    self:UpdateChatPanel(State)
end

function ChatSetMobile:OnClickVoice()
    print("ChatSetMobile >> OnClickVoice self=",GetObjectName(self))
    self.ChatVoiceState = not self.ChatVoiceState
    local State = self.ChatVoiceState and EChatPanelMode.VoiceSetting or EChatPanelMode.Close
    self:UpdateChatPanel(State)
end


function ChatSetMobile:OnSetting()
    print("ChatSetMobile >> OnSetting self=",GetObjectName(self))
end

function ChatSetMobile:OnRefreshPanel()
    print("ChatSetMobile >> OnRefreshPanel self=",GetObjectName(self))

    local SpeakerMode = self.BattleChatComp.SpeakerMode
    local VoiceMicMode = self.BattleChatComp.VoiceMicMode
    local VoiceNeedPressSetting = self.BattleChatComp.VoiceNeedPressSetting
    local bSpeaking = self.BattleChatComp.bSpeaking

    --切换扬声器按钮图标状态
    self.WS_SpeakerState:SetActiveWidgetIndex(SpeakerMode)


    --切换麦克风按钮图标状态

    if bSpeaking then
        self.WS_MicState:SetActiveWidgetIndex(5)
        return
    end

    if VoiceMicMode == EMicMode.Close then
        --关闭麦克风
        self.MicSetting = EMicSetting.Close
        self.WS_MicState:SetActiveWidgetIndex(self.MicSetting)
    else
        
        if VoiceNeedPressSetting == EMicropKeyMode.Free then
            if VoiceMicMode == EMicMode.Near then
                --附近人麦克风
                self.MicSetting = EMicSetting.Near
            elseif VoiceMicMode == EMicMode.Team then
                --队伍麦克风
                self.MicSetting = EMicSetting.Team
            end
        else
            if VoiceMicMode == EMicMode.Near then
                --对讲机附近人麦克风
                self.MicSetting = EMicSetting.NearPress
            elseif VoiceMicMode == EMicMode.Team then
                --对讲机队伍麦克风
                self.MicSetting = EMicSetting.TeamPress
    
            end
        end
    end



    self.WS_MicState:SetActiveWidgetIndex(self.MicSetting)

    self:UpdateChatPanel(EChatPanelMode.Close)
end


return ChatSetMobile
