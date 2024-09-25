require "UnLua"

local TeamVoiceControl = Class("Common.Framework.UserWidget")

function TeamVoiceControl:OnInit()
    print("(Wzp)TeamVoiceControl:OnInit")

    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.BattleChat_OnOpenOrCloseVoiceChat,            Func = self.OnMainMenuVisibilityToggle,      bCppMsg = true },
        --{ MsgName = GameDefine.MsgCpp.BattleChat_OnAddRoomMemberInfo,            Func = self.OnAddRoomMemberInfo,      bCppMsg = false },
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState,	  Func = self.OnUpdateLocalPCPS,   bCppMsg = true, WatchedObject = self.LocalPC },
    }

    self.BattleChatComp =  UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    self.TeamChatSwitch:AddSwicthEvent(self,self.OnTeamChatSwitchCallback)
    self.ChatModeSwitch:AddSwicthEvent(self,self.OnChatModeSwitchCallback)
    self.SubscribeChannelSwitch:AddSwicthEvent(self, self.OnSubscribeChannelSwitch)
    self.PublishChannelSwitch:AddSwicthEvent(self, self.OnPublishChannelSwitch)
    self:InitVoiceRoomInfo()
    UserWidget.OnInit(self)
end
function TeamVoiceControl:OnShow(InContext, InGenericBlackboard)
    print("(Wzp)TeamVoiceControl:OnShow")
    self:OnMainMenuVisibilityToggle()
    self:InitPlayerVoiceListUI()
end

function TeamVoiceControl:InitVoiceRoomInfo()
    print("(Wzp)TeamVoiceControl:InitVoiceRoomInfo...  [ObjectName]=",GetObjectName(self))
    --监听队伍PS更新消息
    self.TeamSubsystem = UE.UTeamExSubsystem.Get(self)
    self.TeamSubsystem.OnTeammatePSListChangedDelegate:Add(self,self.OnTeamatePSList)
    -- self:InitPlayerVoiceListUI()
end

function TeamVoiceControl:OnTeamatePSList(InTeammateList)
    print("(Wzp)TeamVoiceControl:OnTeamatePSList  [ObjectName]=",GetObjectName(self),",[InTeammateList]=",InTeammateList)
    if not InTeammateList then
        return
    end
    local TeammateNum = InTeammateList:Num()
    print("(Wzp)TeamVoiceControl:OnTeamatePSList  [TeammateNum]=",TeammateNum)
    -- self:InitPlayerVoiceListUI()
end

function TeamVoiceControl:OnStateChangeEvent(bState)
    print("(Wzp)TeamVoiceControl:OnStateChangeEvent > [bState] = ",bState)
    
end

function TeamVoiceControl:OnSetTextPressToChatColor(Color)
     self.TxtPressedChat:SetColorAndOpacity(Color)
end

function TeamVoiceControl:OnTeamChatSwitchCallback(Index)
    print("(Wzp)TeamVoiceControl:OnTeamChatSwitchCallback > Index=",Index)
    self.BattleChatComp =  UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    self.BattleChatComp:OpenOrCloseVoice(Index)
end

function TeamVoiceControl:OnChatModeSwitchCallback(Index)
    print("(Wzp)TeamVoiceControl:OnChatModeSwitchCallback > Index=",Index)
    self.BattleChatComp =  UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    self.BattleChatComp:SetVoiceNeedsPress(Index)
end



function TeamVoiceControl:OnSubscribeChannelSwitch(Index)
    print("(Wzp)TeamVoiceControl:OnChatChannelCallback > Index=",Index)
    self.BattleChatComp =  UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    self.BattleChatComp:SetSpeakerMode(Index)
end


function TeamVoiceControl:OnPublishChannelSwitch(Index)
    print("(Wzp)TeamVoiceControl:OnChatChannelCallback > Index=",Index)
    self.BattleChatComp =  UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    self.BattleChatComp:SetVoiceMicMode(Index)
end


--语音聊天开关回调
function TeamVoiceControl:OnRefreshTeamChat(index)
    print("(Wzp)TeamVoiceControl:OnRefreshTeamChat > Index=",index)
    self.TeamChatSwitch:UpdateToggle(index)

    local bOnSwitch = (index == 0)
    self.ChatModeSwitch:SetState(bOnSwitch)
    self.SubscribeChannelSwitch:SetState(bOnSwitch)
    self.PublishChannelSwitch:SetState(bOnSwitch)
end

--语音聊天模式开关回调
function TeamVoiceControl:OnRefreshChatMode(index)
    print("(Wzp)TeamVoiceControl:OnRefreshChatMode > Index=",index)
    local bIsShowTip = (index == 0)
    self.ChatModeSwitch:UpdateToggle(index)
    self.HB_ChatModeTips:SetVisibility(bIsShowTip and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
end

--语音聊天频道开关回调
function TeamVoiceControl:OnRefreshChatChannel(bIsOn)
    print("(Wzp)TeamVoiceControl:OnRefreshChatChannel > bIsOn=",bIsOn)
    self.ChatChannelSwitch:UpdateToggle(bIsOn)
end

function TeamVoiceControl:OnRefreshSubscribeChannel(Index)
    print("(Wzp)TeamVoiceControl:OnRefreshSubscribeChannel > Index=",Index)
    self.SubscribeChannelSwitch:UpdateToggle(Index)
end

function TeamVoiceControl:OnRefreshPublishChannel(Index)
    print("(Wzp)TeamVoiceControl:OnRefreshPublishChannel > Index=",Index)
    self.PublishChannelSwitch:UpdateToggle(Index)
end


function TeamVoiceControl:OnMainMenuVisibilityToggle()

    --PlayerChatComponent那边可能会先发送BattleChat_OnOpenOrCloseVoiceChat，此时TeamVoiceControl可能还没有Init拿不到self.BattleChatComp 
    
    if not self.BattleChatComp then
        self.BattleChatComp =  UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
        if not self.BattleChatComp then
            print("(Wzp_Error)TeamVoiceControl:OnMainMenuVisibilityToggle [self.BattleChatComp]=nil")
            return
        end
    end
    self.PlayerVoiceSettingsItem:InitializePlayerVoiceItem()
    self.PlayerVoiceSettingsItem_1:InitializePlayerVoiceItem()
    self.PlayerVoiceSettingsItem_2:InitializePlayerVoiceItem()
    self.PlayerVoiceSettingsItem_3:InitializePlayerVoiceItem()
    

    self:OnRefreshTeamChat(self.BattleChatComp.EVoiceAndChatState)
    self:OnRefreshChatMode(self.BattleChatComp.VoiceNeedPressSetting)
    self:OnRefreshSubscribeChannel(self.BattleChatComp.SpeakerMode)
    self:OnRefreshPublishChannel(self.BattleChatComp.VoiceMicMode)
    -- print("(Wzp)TeamVoiceControl:OnMainMenuVisibilityToggle > Team=",self.BattleChatComp.bEnableVoiceChat,"Chat=",self.BattleChatComp.bVoiceChatNeedsKeyPress,"Channel=",self.BattleChatComp.bIsTeamChannel)
end

function TeamVoiceControl:OnUpdateLocalPCPS(InLocalPC, InOldPS, InNewPS)
    --更新存活被观战者
    print("(Wzp)TeamVoiceControl:OnUpdateLocalPCPS >>", GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS))
    if self.LocalPC == InLocalPC then
        if InNewPS then
            print("[Wzp]TeamVoiceControl >> [if InNewPS]")
            -- self.LocalPS = InNewPS
            self.LocalPS = self.LocalPC.OriginalPlayerState
            self.PlayerId =  self.LocalPS:GetPlayerId()
            self:InitPlayerVoiceListUI()
        end
	end
end

function TeamVoiceControl:OnAddRoomMemberInfo()
    print("(Wzp)PlayerChatComponent:OnAddRoomMemberInfo  [ObjectName]=",GetObjectName(self),",[Number]=",Number)
    local GetRoomInfos = self.BattleChatComp:GetRoomInfos()
    local PlayerVoiceSettingNum = self.VB_PlayerVoiceSettings:GetChildrenCount()
    for index = 0, PlayerVoiceSettingNum-1 do
        local ItemWidget = self.VB_PlayerVoiceSettings:GetChildAt(index)
        ItemWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    local WidgetIndex = 0
    for key, RoomInfo in pairs(GetRoomInfos) do
        WidgetIndex = WidgetIndex + 1
        local ItemWidget = self.VB_PlayerVoiceSettings:GetChildAt(WidgetIndex)
        ItemWidget:SetVisibility(UE.ESlateVisibility.Visible)
        ItemWidget:RefreshUI(key,self.LocalPS)
    end

end

function TeamVoiceControl:InitPlayerVoiceListUI()
    print("(Wzp)TeamVoiceControl:InitPlayerVoiceListUI <ObjectName=",GetObjectName(self),">")

    local TeamSubsystem = UE.UTeamExSubsystem.Get(self)
    if not self.LocalPS then
        return
    end
    local PSList = TeamSubsystem:GetTeammatePSListByPS(self.LocalPS)
    local TeamMemberLength = PSList:Length()


    print("(Wzp)TeamVoiceControl:InitPlayerVoiceListUI <PlayerStateList> BeginLoop <TeamMemberLength=",TeamMemberLength,">")
    local PlayerStateList = {}
    local Index = 0
    for i = 1, TeamMemberLength do
        local TmpPS = PSList:GetRef(i)
        if TmpPS then
            local TmpPlayerId = TmpPS:GetPlayerId()
            print("(Wzp)TeamVoiceControl:InitPlayerVoiceListUI <PlayerStateList> InLoop <Index=",Index,"><TmpPS=",TmpPS,"><TmpPlayerId=",TmpPlayerId,"><self.PlayerId=",self.PlayerId,">")
            if TmpPlayerId ~= self.PlayerId then
                Index = Index + 1
                PlayerStateList[Index] = TmpPS
            end
        end
    end
    print("(Wzp)TeamVoiceControl:InitPlayerVoiceListUI <PlayerStateList> EndLoop ")


    print("(Wzp)TeamVoiceControl:InitPlayerVoiceListUI <VB_PlayerVoiceSettings> BeginLoop")
    local PlayerVoiceSettingNum = self.VB_PlayerVoiceSettings:GetChildrenCount()
    for index = 0, PlayerVoiceSettingNum-1 do
         local PlayerVoiceSettingWidget = self.VB_PlayerVoiceSettings:GetChildAt(index)
         local PlayerState = PlayerStateList[index]
         print("(Wzp)TeamVoiceControl:InitPlayerVoiceListUI <VB_PlayerVoiceSettings> InLoop <index=",index,"><PlayerState=",PlayerState,">")
         if PlayerState then
            PlayerVoiceSettingWidget:SetVisibility(UE.ESlateVisibility.Visible)
            PlayerVoiceSettingWidget:RefreshUI(PlayerState,self.LocalPS)
         else
            PlayerVoiceSettingWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
         end
    end
    print("(Wzp)TeamVoiceControl:InitPlayerVoiceListUI <VB_PlayerVoiceSettings> EndLoop ")


end


function TeamVoiceControl:OnDestroy()
    print("(Wzp)TeamVoiceControl:OnDestroy")
    UserWidget.OnDestroy(self)
end




return TeamVoiceControl