local ChatMessageUIMobile = Class("Common.Framework.UserWidget")

local EChatChannel = {
    Team = 1, -- 组队聊天
    Private = 2, -- 私聊
    NearBy = 4 -- 附近人聊天
}

local ETextChatPage = {
    QuickMsg = 0,
    History = 1,
    FriendChat = 2
}

function ChatMessageUIMobile:OnInit()
    print("ChatMessageUIMobile >> OnInit self=", GetObjectName(self))

    self.PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local Role = self.PC:GetLocalRole()
    if Role ~= UE.ENetRole.ROLE_AutonomousProxy then
        return
    end

    self.BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)

    if self.BattleChatComp then
        self.RefreshChatMsgHandle = ListenObjectMessage(self.BattleChatComp,
            GameDefine.MsgCpp.BattleChat_OnRefreshIngameChatBox, self, self.AddChatToBox)
    end

    self.ChatInputBox.OnTextCommitted:Add(self, self.OnChatInputBoxCommitted)
    self.ChatModeIndex = 0
    self.ChatChannel = -1
    self:UpdateCurrentChatMode()


    self:RegistEvent()
    self.ChatTabTable = {
        [ETextChatPage.QuickMsg] = self.BP_ChatTab_Quick,
        [ETextChatPage.History] = self.BP_ChatTab_History,
        [ETextChatPage.FriendChat] = self.BP_ChatTab_Friend
    }

    self:UpdateTabAndPage(ETextChatPage.History)
    self:InitQuickReplayMsgList()
    self:InitFriendMessageList()

    UserWidget.OnInit(self)
end

function ChatMessageUIMobile:OnDestroy()
    print("ChatMessageUIMobile >> OnDestroy self=", GetObjectName(self))
    self:UnRegistEvent()
    UserWidget.OnDestroy(self)
end


function ChatMessageUIMobile:RegistEvent()
    -- #region 文字消息更新
    self.MessageList.OnScrollItem:Add(self, self.OnScrollItem)
    self.MessageList.OnPreUpdateItem:Add(self, self.OnPreUpdateItem)
    if UE.UGFUnluaHelper.IsEditor() then
        self.MessageList.OnUpdateItem:Add(self, self.OnUpdateItemLocal)
    else
        self.MessageList.OnUpdateItem:Add(self, self.OnUpdateItem)
    end
    -- #endregion

    self.Button_VoiceToText.OnClicked:Add(self, self.OnVoiceToTextButtonClicked)
    self.Button_ChatMode.OnClicked:Add(self, self.OnChatModeButtonClicked)

    self.BP_ChatTab_Quick.Button.OnClicked:Add(self, self.OnQuickTabButtonClicked)
    self.BP_ChatTab_History.Button.OnClicked:Add(self, self.OnHistoryButtonClicked)
    self.BP_ChatTab_Friend.Button.OnClicked:Add(self, self.OnFriendButtonClicked)
end

function ChatMessageUIMobile:UnRegistEvent()

    if self.BattleChatComp then
        if self.RefreshChatMsgHandle then
            UnListenObjectMessage(GameDefine.MsgCpp.BattleChat_OnRefreshIngameChatBox, self, self.RefreshChatMsgHandle)
        end
    end

    self.ChatInputBox.OnTextCommitted:Clear()
    self.MessageList.OnScrollItem:Clear()
    self.MessageList.OnPreUpdateItem:Clear()
    self.MessageList.OnUpdateItem:Clear()

    self.Button_VoiceToText.OnClicked:Clear()
    self.Button_ChatMode.OnClicked:Clear()

    self.BP_ChatTab_Quick.Button.OnClicked:Clear()
    self.BP_ChatTab_History.Button.OnClicked:Clear()
    self.BP_ChatTab_Friend.Button.OnClicked:Clear()

    self.FriendChatList.OnUpdateItem:Clear()
    self.QuickReplayList.OnUpdateItem:Clear()
end


function ChatMessageUIMobile:OnChatInputBoxCommitted(Text, CommitMethod)
    if CommitMethod == 1 --[[UE.ETextCommit.Type.OnEnter]] then
        self:SendTextMessage(Text)
    end
end

function ChatMessageUIMobile:InitFriendMessageList()
    if UE.UGFUnluaHelper.IsEditor() then
        self.FriendChatList.OnUpdateItem:Add(self, self.OnUpdateFriendItemLocal)
    else
        self.FriendChatList.OnUpdateItem:Add(self, self.OnUpdateFriendItem)
    end
end

function ChatMessageUIMobile:OnUpdateFriendItemLocal(Widget, Index)
    self:UpdateMessageItem(Widget, Index, self.BattleChatComp.PriavteMessageDatas)
end

function ChatMessageUIMobile:OnUpdateFriendItem(Widget, Index)
    self:UpdateMessageItem(Widget, Index, self.BattleChatComp.PriavteMessageDatas)
end

function ChatMessageUIMobile:InitQuickReplayMsgList()
    local ArrNum = self.QuickReplayArr:Num()
    self.QuickReplayList.OnUpdateItem:Add(self, self.OnUpdateQuickReplayList)
    self.QuickReplayList:Reload(ArrNum)
end

function ChatMessageUIMobile:OnUpdateQuickReplayList(Widget, Index)
    local QuickReplayText = self.QuickReplayArr:Get(Index + 1)
    Widget.Text:SetText(QuickReplayText)
    Widget.Button_QuickReplay.OnClicked:Add(self, function()
        self.BattleChatComp:SendMsg(self.ChatChannel, QuickReplayText)
    end)
end

function ChatMessageUIMobile:OnQuickTabButtonClicked()
    self:UpdateTabAndPage(ETextChatPage.QuickMsg)
end

function ChatMessageUIMobile:OnHistoryButtonClicked()
    self:UpdateTabAndPage(ETextChatPage.History)
end

function ChatMessageUIMobile:OnFriendButtonClicked()
    self:UpdateTabAndPage(ETextChatPage.FriendChat)
end

-- ETextChatPage:TextChatPage
function ChatMessageUIMobile:UpdateTabAndPage(TextChatPage)
    self.ChatPageIndex = TextChatPage
    for index, TabWidget in pairs(self.ChatTabTable) do
        TabWidget:SetTabState(index == self.ChatPageIndex)
    end
    self.ChatPage:SetActiveWidgetIndex(self.ChatPageIndex)
end

function ChatMessageUIMobile:OnVoiceToTextButtonClicked()
    print("[wzp]ChatMessageUIMobile >> OnVoiceToTextButtonClicked self=", GetObjectName(self))
    -- 打开语音转文字面板

    -- Test
    local ReadySendText = self.ChatInputBox:GetText()
    self:SendTextMessage(ReadySendText)
end

function ChatMessageUIMobile:OnChatModeButtonClicked()
    print("[wzp]ChatMessageUIMobile >> OnChatModeButtonClicked self=", GetObjectName(self))
    -- 切换文字聊天模式 队伍、私聊、附近人
    self:SwitchChatMode()
    self:UpdateCurrentChatMode()
end

function ChatMessageUIMobile:SwitchChatMode()
    print("[Wzp]ChatMessageUIMobile >> SwitchChatMode")
    self.ChatModeIndex = (self.ChatModeIndex + 1) % 2
end

function ChatMessageUIMobile:UpdateCurrentChatMode(ChatChannel)
    if ChatChannel then
        self.ChatChannel = ChatChannel
    else
        if self.ChatModeIndex == 0 then
            self.ChatChannel = EChatChannel.Team
        elseif self.ChatModeIndex == 1 then
            self.ChatChannel = EChatChannel.NearBy
        end
    end

    local ModeText = self.ChatModeTextMap:Find(self.ChatChannel)
    self.Text_ChatMode:SetText(ModeText)
end

function ChatMessageUIMobile:OnScrollItem(StartIdx, EndIdx)
    self.CurrentLastId = EndIdx
    print("[wzp]ChatMessageUIMobile >> OnScrollItem > self.CurrentLastId", self.CurrentLastId, "Length=",
        self.BattleChatComp.MessageDatas:Length())
end

function ChatMessageUIMobile:OnPreUpdateItem(Index)
end

-- 需要在包体中才能执行，依赖服务器
function ChatMessageUIMobile:OnUpdateItem(Widget, Index)
    local ChatMessage = self.BattleChatComp.MessageDatas[Index + 1].Message
    local OwnerPlayerId = self.BattleChatComp.MessageDatas[Index + 1].MessageOwnerPlayerID
    local MessageChannel = self.BattleChatComp.MessageDatas[Index + 1].MessageChannel
    local PlayerExSubSystem = UE.UPlayerExSubsystem.Get(self)
    local PlayerName = PlayerExSubSystem:GetPlayerNameById(OwnerPlayerId)
    if PlayerName == nil then
        Widget:InitChatContentWidgetByData(self, MessageChannel, "", ChatMessage, Index, nil)
        return
    end

    print("[wzp]ChatMessageUIMobile >> OnUpdateItem ChatMessage", ChatMessage)
    Widget:InitChatContentWidgetByData(self, MessageChannel, PlayerName, ChatMessage, Index, nil)
end

function ChatMessageUIMobile:UpdateMessageItem(Widget, Index, MessageSourceArr)
    local ChatMessage = MessageSourceArr[Index + 1].Message
    local OwnerPlayerId = MessageSourceArr[Index + 1].MessageOwnerPlayerID
    local MessageChannel = MessageSourceArr[Index + 1].MessageChannel
    local PlayerExSubSystem = UE.UPlayerExSubsystem.Get(self)
    local PlayerName = PlayerExSubSystem:GetPlayerNameById(OwnerPlayerId)
    if PlayerName == nil then
        Widget:InitChatContentWidgetByData(self, MessageChannel, "", ChatMessage, Index, nil)
        return
    end

    print("[wzp]ChatMessageUIMobile >> OnUpdateItem ChatMessage", ChatMessage)
    Widget:InitChatContentWidgetByData(self, MessageChannel, PlayerName, ChatMessage, Index, nil)
end

function ChatMessageUIMobile:OnUpdateItemLocal(Widget, Index)
    -- 编辑器模式下，不依赖服务器
    print("[wzp]ChatMessageUIMobile:OnUpdateItemLocal")
    local ChatMessage = self.BattleChatComp.MessageDatas[Index + 1].Message
    local OwnerPlayerId = self.BattleChatComp.MessageDatas[Index + 1].MessageOwnerPlayerID
    local MessageChannel = self.BattleChatComp.MessageDatas[Index + 1].MessageChannel
    local PlayerExSubSystem = UE.UPlayerExSubsystem.Get(self)
    local PlayerName = PlayerExSubSystem:GetPlayerNameById(OwnerPlayerId)
    if PlayerName == nil then
        Widget:InitChatContentWidgetByData(self, MessageChannel, "话痨玩家", ChatMessage, Index, nil)
        return
    end
    Widget:InitChatContentWidgetByData(self, MessageChannel, PlayerName, ChatMessage, Index, nil)
end

function ChatMessageUIMobile:SendTextMessage(Text)
    local bOnlyWhitespace = self:IsStringOnlyWhitespace(Text)
    if #Text > 0 and not bOnlyWhitespace then
        self.ChatInputBox:SetText("")
        self.BattleChatComp:SendMsg(self.ChatChannel, Text)
    end
end

function ChatMessageUIMobile:IsBarScrolled()
    print("[wzp]ChatMessageUI >> IsBarScrolled > self.CurrentLastId", self.CurrentLastId, "Length=",
        self.BattleChatComp.MessageDatas:Length())
    if self.CurrentLastId then
        return self.CurrentLastId >= self.BattleChatComp.MessageDatas:Length() - 1
    end
    return false
end

function ChatMessageUIMobile:AddChatToBox(InNeedReload)
    print("[wzp]ChatMessageUIMobile >> OnAddChatToBox self=", self)
    print("[wzp]ChatMessageUIMobile >> AddChatToBox > self.CurrenInputMode=", self.CurrenInputMode)
    print("[wzp]ChatMessageUIMobile >> IsBarScrolled > self.CurrentLastId", self.CurrentLastId, "Length=",
        self.BattleChatComp.MessageDatas:Length())

    if self.BattleChatComp == nil then
        return
    end

    local bIsSroll = self:IsBarScrolled()

    if InNeedReload then
        self.MessageList:Reload(self.BattleChatComp.MessageDatas:Length())
    else
        self.MessageList:AddOne(self.BattleChatComp.MessageDatas:Length())
        self.FriendChatList:AddOne(self.BattleChatComp.PriavteMessageDatas:Length())
    end

    if bIsSroll then
        self.MessageList:ScrollToEnd()
    end
end

function ChatMessageUIMobile:OnTryReplayMessage(Index, ReplayMesgOwner, MessageOwner)
    -- 点击私聊回复
    if not self.BattleChatComp then return end
    self:UpdateCurrentChatMode(EChatChannel.Private)
    self.CurrentReplayMsgOwner = ReplayMesgOwner
    self.CurrentReplayIndex = Index
    local MessagePlayerId = self.BattleChatComp.MessageDatas[Index + 1].MessageOwnerPlayerID
    self.BattleChatComp:SetPrivatePlayerId(MessagePlayerId)
end

function ChatMessageUIMobile:IsStringOnlyWhitespace(str)
    -- 判断字符串中是否全是空格这种无效消息 true无效，false有效
    return str:match("^%s*$") ~= nil
end

return ChatMessageUIMobile
