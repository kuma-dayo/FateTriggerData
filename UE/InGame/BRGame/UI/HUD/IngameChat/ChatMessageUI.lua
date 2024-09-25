-- local PlayerChatComponent = require("UE.InGame.BRGame.UI.HUD.IngameChat.PlayerChatComponent")
local ChatMessageUI = Class("Common.Framework.UserWidget")


function ChatMessageUI:OnShow()
    print("ChatMessageUI >> OnShow self=",self)
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.LocalPS = self.LocalPC.OriginalPlayerState
    if self.LocalPS then
        self.PlayerId = self.LocalPS.PlayerId
    end
    local Role = self.LocalPC:GetLocalRole()
    if Role ~= UE.ENetRole.ROLE_AutonomousProxy then
        return
    end

    self.BattleChatComp =  UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    self.PlayerExSubsystemIns = UE.UPlayerExSubsystem.Get(self)
    if not self.BattleChatComp then return end
    if self.BattleChatComp then
        self.RefreshChatMsgHandle = ListenObjectMessage(self.BattleChatComp, GameDefine.MsgCpp.BattleChat_OnRefreshIngameChatBox, self, self.AddChatToBox)
    end
    self.MsgList = {
		{ MsgName =  GameDefine.MsgCpp.BattleChat_OnStartMsgChat,            Func = self.StartOrStopChat,      bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState,            Func = self.OnUpdateLocalPCPS,      bCppMsg = true },
    }
    self.BindNodes ={
        { UDelegate = self.ChatInputBox.OnTextCommitted, Func = self.OnMessageCommitted },
    }
    self.RootPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.MessageList.OnScrollItem:Add(self, self.OnScrollItem)
    self.MessageList.OnPreUpdateItem:Add(self, self.OnPreUpdateItem)
    self.MessageList.OnListSizeChanged:Add(self, self.OnListSizeChanged)
    self.BattleChatComp.ClearMessageDelegate:Add(self,self.OnClearChatMessage)

    
    local bIsEditor = UE.UGFUnluaHelper.IsEditor()
    print("ChatMessageUI:OnInit bIsEditor=",bIsEditor)
    if UE.UGFUnluaHelper.IsEditor() then
        self.MessageList.OnUpdateItem:Add(self, self.OnUpdateItemLocal)
    else
        self.MessageList.OnUpdateItem:Add(self,self.OnUpdateItem)
    end


    -- self.MessageList.OnUpdateItem:Add(self,self.OnUpdateItem)


    self.BP_ChatTag:ToTeamStyle()

    self.GameState = UE.UGameplayStatics.GetGameState(self.LocalPC)
    -- CurrentStyle 0：collapsed(完全隐藏) 1：Blank（只显示信息，不显示背景板） 2：MsgDisplayOnly（显示信息，显示背景板，不显示输入栏） 3：InputMode（显示信息 显示背景板 显示输入栏）
    -- 回车触发InputMode，并且不会进入其他Style

    -- 停止输入之后，进入2 MsgDisplayOnly，如果一段时间不继续输入的话进入1：Blank
    -- 进入1：Blank之后，如果没有新消息来，一段时间之后会进入0：collapsed(完全隐藏)，如果有新消息来，则会进入1：Blankz
    -- self:ToCollapsedStyle()
    self:CollapseMode()
    self.bIsShow = false

    -- 注册节点监听
    if self.BindNodes then
        MsgHelper:OpDelegateList(self, self.BindNodes, true)
    end
    -- 注册消息监听
    if self.MsgList then
        MsgHelper:RegisterList(self, self.MsgList)
    end
    self:UpdateAllFromMessageList()
    self:SetMessageBoxBarVisible(UE.ESlateVisibility.Hidden)
end


function ChatMessageUI:OnListSizeChanged()
end


function ChatMessageUI:UpdateAllFromMessageList()
    if self.BattleChatComp then
        self.MessageList:ScrollToEnd()
    end
end


--[GMP消息]每次切换被观战者（存活的）后触发
function ChatMessageUI:OnUpdateLocalPCPS(InLocalPC, InOldPS, InNewPS)
    --更新存活被观战者
    print("ChatMessageUI >> OnUpdateLocalPCPS",GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS))
    if self.LocalPC == InLocalPC then
        if InNewPS then
            self.LocalPS = self.LocalPC.OriginalPlayerState
            self.PlayerId = self.LocalPS.PlayerId
        end
	end
end


function ChatMessageUI:OnInit()
    print("ChatMessageUI >> OnInit self=",self)
    UserWidget.OnInit(self)
end

function ChatMessageUI:OnDestroy()
    print("ChatMessageUI >> OnDestroy self=",self)
    if self.BattleChatComp then
        UnListenObjectMessage(GameDefine.MsgCpp.BattleChat_OnRefreshIngameChatBox, self.BattleChatComp, self.RefreshChatMsgHandle)
    end

    if self.MsgList then
        MsgHelper:UnregisterList(self, self.MsgList)
        self.MsgList = {}
    end
    
    if self.CollapsedTimerHandle then
        Timer.RemoveTimer(self.CollapsedTimerHandle)
        self.CollapsedTimerHandle = nil
    end

    self.MessageList.OnScrollItem:Remove(self, self.OnScrollItem)
    self.MessageList.OnPreUpdateItem:Remove(self, self.OnPreUpdateItem)
    if UE.UGFUnluaHelper.IsEditor() then
        self.MessageList.OnUpdateItem:Remove(self, self.OnUpdateItemLocal)
    else
        self.MessageList.OnUpdateItem:Remove(self,self.OnUpdateItem)
    end

    UserWidget.OnDestroy(self)
end

function ChatMessageUI:OnClose()
    print("ChatMessageUI >> OnClose self=",self)
    
    if self.BattleChatComp then
        UnListenObjectMessage(GameDefine.MsgCpp.BattleChat_OnRefreshIngameChatBox, self.BattleChatComp, self.RefreshChatMsgHandle)
    end
    
    self.MessageList.OnScrollItem:Remove(self, self.OnScrollItem)
    self.MessageList.OnPreUpdateItem:Remove(self, self.OnPreUpdateItem)

    if self.MsgList then
        MsgHelper:UnregisterList(self, self.MsgList)
        self.MsgList = {}
    end

    if self.CollapsedTimerHandle then
        Timer.RemoveTimer(self.CollapsedTimerHandle)
        self.CollapsedTimerHandle = nil
    end

    if UE.UGFUnluaHelper.IsEditor() then
        self.MessageList.OnUpdateItem:Remove(self, self.OnUpdateItemLocal)
    else
        self.MessageList.OnUpdateItem:Remove(self,self.OnUpdateItem)
    end

end



local EChatMode={
    InputMode = 0,
    Suspend = 1,
    Collapse = 2,
}



function ChatMessageUI:OnMessageCommitted(Text, CommitMethod)
    if CommitMethod == 1 then
        if #Text > 0 then
            self.ChatInputBox:SetText("")
            self.BattleChatComp:SendMsg(self.BP_ChatTag:GetIngameMessageChannel(),StringUtil.ConvertFText2String(Text))
        end
    end
end

function ChatMessageUI:AddChatToBox(InNeedReload)

    print("ChatMessageUI >> OnAddChatToBox self=",self)
    print("[wzp]ChatMessageUI >> AddChatToBox > self.CurrenInputMode=",self.CurrenInputMode)
    print("[wzp]ChatMessageUI >> IsBarScrolled > self.CurrentLastId",self.CurrentLastId,"Length=",self.BattleChatComp.MessageDatas:Length())

    if self.BattleChatComp == nil then
        return
    end

    local bIsSroll = self:IsBarScrolled()

    if InNeedReload then
        self.MessageList:Reload(self.BattleChatComp.MessageDatas:Length())
    else
        self.MessageList:AddOne(self.BattleChatComp.MessageDatas:Length())
    end

    if bIsSroll then
        self.MessageList:ScrollToEnd()
    end


    if self.CurrenInputMode == EChatMode.Collapse or self.CurrenInputMode == EChatMode.Suspend then
        self:SuspendModeNormal()
    end
end


--- 清除聊天通知
---@param ClearMode UE.ETextChatClearMode 清除聊天的方式，是全部清除、指定PlayerID清除、清除所有队伍类型...
function ChatMessageUI:OnClearChatMessage(ClearMode)
    print("[wzp]ChatMessageUI:OnClearChatMessage [ObjectName]=",GetObjectName(self),",[ClearMode]=",ClearMode)

    if self.BattleChatComp == nil then
        return
    end

    self.MessageList:Reload(self.BattleChatComp.MessageDatas:Length())
end



function ChatMessageUI:OnScrollItem(StartIdx,EndIdx)
    self.CurrentLastId = EndIdx
    print("[wzp]ChatMessageUI >> OnScrollItem > self.CurrentLastId",self.CurrentLastId,"Length=",self.BattleChatComp.MessageDatas:Length())
end

function ChatMessageUI:OnPreUpdateItem(Index)
end

--需要在包体中才能执行，依赖服务器
function ChatMessageUI:OnUpdateItem(Widget, Index)

    local MessageData,bFind = self.BattleChatComp:GetMessageByIndex(Index)
    Widget:SetVisibility(bFind and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if not bFind then
        return
    end

    local ChatMessage = MessageData.Message
    
    if not ChatMessage then
        return
    end

    if not string.notNilOrEmpty(ChatMessage) then
        return
    end

    local OwnerPlayerId = MessageData.MessageOwnerPlayerID
    local MessageChannel = MessageData.MessageChannel
    local PlayerExSubSystem = UE.UPlayerExSubsystem.Get(self)
    local bIsMyMessage = true
    if self.PlayerId then
        bIsMyMessage = (self.PlayerId == OwnerPlayerId)
    end
    local PlayerName = PlayerExSubSystem:GetPlayerNameById(OwnerPlayerId)

    local TeammatePS = self.PlayerExSubsystemIns:GetPlayerStateById(OwnerPlayerId)
    local CurTeamPos = 255
    if TeammatePS then
        CurTeamPos = BattleUIHelper.GetTeamPos(TeammatePS)
    end

    --local OwnerPS =  self.GameState:GetPlayerState(OwnerPlayerId)
    if  PlayerName == nil then
        Widget:InitChatContentWidgetByData(self,MessageChannel,bIsMyMessage,CurTeamPos,"",ChatMessage,Index)
        return
    end
    --local MessageOwnerName = OwnerPS:GetPlayerName()
    print("ChatMessageUI >> OnUpdateItem ChatMessage", ChatMessage)
    Widget:InitChatContentWidgetByData(self,MessageChannel,bIsMyMessage,CurTeamPos,PlayerName,ChatMessage,Index)
end

--编辑器模式下，不依赖服务器
function ChatMessageUI:OnUpdateItemLocal(Widget, Index)
    print("ChatMessageUI:OnUpdateItemLocal")
    

    local MessageData,bFind = self.BattleChatComp:GetMessageByIndex(Index)
    Widget:SetVisibility(bFind and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if not bFind then
        return
    end

    local ChatMessage = MessageData.Message

    if not ChatMessage then
        return
    end
    if not string.notNilOrEmpty(ChatMessage) then
        return
    end

    local OwnerPlayerId = MessageData.MessageOwnerPlayerID
    local MessageChannel = MessageData.MessageChannel
    --local OwnerPS =  self.GameState:GetPlayerState(OwnerPlayerId)
    local bIsMyMessage = true
    if self.PlayerId then
        bIsMyMessage = (self.PlayerId == OwnerPlayerId)
    end

    local TeammatePS = self.PlayerExSubsystemIns:GetPlayerStateById(OwnerPlayerId)
    local CurTeamPos = 255
    if TeammatePS then
        CurTeamPos = BattleUIHelper.GetTeamPos(TeammatePS)
    end

    local PlayerExSubSystem = UE.UPlayerExSubsystem.Get(self)
    local PlayerName = PlayerExSubSystem:GetPlayerNameById(OwnerPlayerId)
    if  PlayerName == nil then
        Widget:InitChatContentWidgetByData(self,MessageChannel,bIsMyMessage,CurTeamPos,"话痨玩家",ChatMessage,Index)
        return
    end

    Widget:InitChatContentWidgetByData(self,MessageChannel,bIsMyMessage,CurTeamPos,PlayerName,ChatMessage,Index)
    -- self.MessageList.ScrollBoxList:ScrollToEnd()
end



function ChatMessageUI:IsBarScrolled()
    print("[wzp]ChatMessageUI >> IsBarScrolled > self.CurrentLastId",self.CurrentLastId,"Length=",self.BattleChatComp.MessageDatas:Length())
    if self.CurrentLastId then
        return  self.CurrentLastId >= self.BattleChatComp.MessageDatas:Length() - 1 
    end
    return false
end


function ChatMessageUI:OnTryReplayMessage(Index, ReplayMesgOwner,MessageOwner)

    self.CurrentReplayMsgOwner = ReplayMesgOwner
    self.CurrentReplayIndex = Index
    local MessageData,bFind = self.BattleChatComp:GetMessageByIndex(Index)
    if bFind then
        local MessageChannel = MessageData.MessageChannel
        local MessagePlayerId = MessageData.MessageOwnerPlayerID
        self.BattleChatComp:SetPrivatePlayerId(MessagePlayerId)
        -- local OwnerPS =  self.GameState:GetPlayerState(MessagePlayerId)
        -- local MessageOwner = OwnerPS:GetPlayerName()
        self:InputMode()
        local FreindName = MessageOwner and MessageOwner or MessagePlayerId
        self.BP_ChatTag:SetReplayFreindName(FreindName)
        self.BP_ChatTag:ToFriendStyle() 
    end

    print("ChatMessageUI >> OnMessageCommitted > Channel=",self.BP_ChatTag:GetIngameMessageChannel())
end




function ChatMessageUI:StartOrStopChat()
    print("[wzp]ChatMessageUI >> StartOrStopChat self.CurrenInputMode=",self.CurrenInputMode)
    if self.CurrenInputMode == EChatMode.Suspend or self.CurrenInputMode == EChatMode.Collapse then
        print("[wzp]ChatMessageUI >> StartOrStopChat >> if self.CurrenInputMode=",self.CurrenInputMode)
        self:InputMode()

    elseif self.CurrenInputMode == EChatMode.InputMode then
        print("[wzp]ChatMessageUI >> StartOrStopChat >> else self.CurrenInputMode=",self.CurrenInputMode)
        local MessageStr = self.ChatInputBox:GetText()
        self:OnMessageCommitted(MessageStr,1)
        self:SuspendMode()
    end
end


function ChatMessageUI:SetMessageBoxBarVisible(Visibility)
    if self.MessageList then
        self.MessageList.ScrollBoxList:SetScrollBarVisibility(Visibility)
    end
end


function ChatMessageUI:InputMode()
    self.CurrenInputMode = EChatMode.InputMode
    self:SetMessageBoxBarVisible(UE.ESlateVisibility.Visible)
    self.RootPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.WidgetSwitcher_State:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    --取消进入折叠状态的计时器
    if self.CollapsedTimerHandle then
        Timer.RemoveTimer(self.CollapsedTimerHandle)
        self.CollapsedTimerHandle = nil
    end

    self:TryChangeInputMode(false)
    print("[wzp]ChatMessageUI >>  UIOnly ")
    self.ChatInputBox:SetFocus(true)
    local PC = UE.UGameplayStatics.GetPlayerController(self,0)
    print("[wzp]ChatMessageUI >> InputMode  self.CurrenInputMode=",self.CurrenInputMode)

end


function ChatMessageUI:SuspendMode()
    if not self.BattleChatComp then return end
    self:SetMessageBoxBarVisible(UE.ESlateVisibility.Hidden)
    self:SuspendModeNormal()
    local PC = UE.UGameplayStatics.GetPlayerController(self,0)
    print("[wzp]ChatMessageUI >>  GameOnly ")
    self:TryChangeInputMode(true)
    print("[wzp]ChatMessageUI >> SuspendMode  self.CurrenInputMode=",self.CurrenInputMode)
end

function ChatMessageUI:SuspendModeNormal()
    self.CurrenInputMode = EChatMode.Suspend
    self.RootPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.WidgetSwitcher_State:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.ChatInputBox:SetText("")
    -- self.ChatInputBox:SetFocus(false)
        -- 状态回调 写一起了
        if self.CollapsedTimerHandle then
            Timer.RemoveTimer(self.CollapsedTimerHandle)
            self.CollapsedTimerHandle = nil
        end
        self.CollapsedTimerHandle = Timer.InsertTimer(self.BPParam_CollapseAllTime, 
            function (dt)
                self:CollapseMode()
            end
        )

end

function ChatMessageUI:CollapseMode()
    self.CurrenInputMode = EChatMode.Collapse
    self.RootPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    print("[wzp]ChatMessageUI >> CollapseMode  self.CurrenInputMode=",self.CurrenInputMode)
end


function ChatMessageUI:OnRemovedFromFocusPath(InFousEvent)

    print("[wzp]ChatMessageUI >> OnRemovedFromFocusPath  self.CurrenInputMode=",self.CurrenInputMode)
    self:SuspendMode();
end



function ChatMessageUI:OnKeyDown(MyGeometry,InKeyEvent)
    -- wzp
    -- 将聊天回车IA Trigger改成Down按下触发，UI输入放到OnKeyDown中处理
    -- 这样能够让发送消息更快，没有按键延迟
    print("[wzp]ChatMessageUI >> OnKeyUp  self.CurrenInputMode=",self.CurrenInputMode)
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey == UE.FName("Enter") then

        self:StartOrStopChat()
        return UE.UWidgetBlueprintLibrary.Handled()
    elseif PressKey == UE.FName("Tab") then
        self.BP_ChatTag:ToNextStatus()
    elseif PressKey == UE.FName("Escape") then
        self:SuspendMode()
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    return UE.UWidgetBlueprintLibrary.Unhandled()
end



return ChatMessageUI