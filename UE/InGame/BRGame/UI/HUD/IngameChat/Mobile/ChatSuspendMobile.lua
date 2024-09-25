local ChatSuspendMobile = Class("Common.Framework.UserWidget")



function ChatSuspendMobile:OnInit()
    print("ChatSuspendMobile >> OnInit self=",GetObjectName(self))

    self.PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local Role = self.PC:GetLocalRole()
    if Role ~= UE.ENetRole.ROLE_AutonomousProxy then
        return
    end
    self.BattleChatComp =  UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)

    if self.BattleChatComp then
        self.RefreshChatMsgHandle = ListenObjectMessage(self.BattleChatComp, GameDefine.MsgCpp.BattleChat_OnRefreshIngameChatBox, self, self.OnMessageNotify)
    end




    self.MaxMessageCount = 3
    self.MessageWidgetList = {}
    
    self:InitChatList()


    UserWidget.OnInit(self)
end


function ChatSuspendMobile:InitChatList()

    for i = 1, self.MaxMessageCount  do
        local Widget = self.DEB_TextChatList:BP_CreateEntry()
        Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        Widget.Image_Deco:SetVisibility(UE.ESlateVisibility.Collapsed)
        table.insert(self.MessageWidgetList,i,Widget)
    end
end


function ChatSuspendMobile:OnDestroy()
    print("ChatSuspendMobile >> OnDestroy self=",GetObjectName(self))
    --TODO 注销消息
    UserWidget.OnDestroy(self)
end


function ChatSuspendMobile:SwitchChatMode()
    print("[Wzp]ChatSuspendMobile >> SwitchChatMode")
    self.ChatModeIndex = (self.ChatModeIndex + 1) % 2
end

function ChatSuspendMobile:OnScrollItem(StartIdx,EndIdx)
    self.CurrentLastId = EndIdx
    print("[wzp]ChatSuspendMobile >> OnScrollItem > self.CurrentLastId",self.CurrentLastId,"Length=",self.BattleChatComp.MessageDatas:Length())
end


function ChatSuspendMobile:IsBarScrolled()
    print("[wzp]ChatMessageUI >> IsBarScrolled > self.CurrentLastId",self.CurrentLastId,"Length=",self.BattleChatComp.MessageDatas:Length())
    if self.CurrentLastId then
        return  self.CurrentLastId >= self.BattleChatComp.MessageDatas:Length() - 1 
    end
    return false
end


function ChatSuspendMobile:OnMessageNotify(InNeedReload)

    print("ChatSuspendMobile >> OnOnMessageNotify self=",self)
    print("[wzp]ChatSuspendMobile >> OnMessageNotify > self.CurrenInputMode=",self.CurrenInputMode)
    print("[wzp]ChatSuspendMobile >> IsBarScrolled > self.CurrentLastId",self.CurrentLastId,"Length=",self.BattleChatComp.MessageDatas:Length())

    if self.BattleChatComp == nil then
        return
    end

    self:RefreshMessageBox()
end



function ChatSuspendMobile:RefreshMessageBox()
    local MsgCount = self.BattleChatComp.MessageDatas:Length()

    for Index = 1, self.MaxMessageCount  do

        local MessageWidget = self.MessageWidgetList[Index]

        local DataIndex = MsgCount - (Index-1)
        local bIsValidIndex = self.BattleChatComp.MessageDatas:IsValidIndex(DataIndex)
        MessageWidget:SetVisibility(bIsValidIndex and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        if not bIsValidIndex then
            return
        end
        
        local MessageData = self.BattleChatComp.MessageDatas[DataIndex]
        local ChatMessage = MessageData.Message
        local OwnerPlayerId = MessageData.MessageOwnerPlayerID
        local MessageChannel = MessageData.MessageChannel
        local PlayerExSubSystem = UE.UPlayerExSubsystem.Get(self)
        local PlayerName = PlayerExSubSystem:GetPlayerNameById(OwnerPlayerId)
        if  PlayerName == nil then
            MessageWidget:InitChatContentWidgetByData(self,MessageChannel,"话痨玩家",ChatMessage,Index,nil)
        else
            MessageWidget:InitChatContentWidgetByData(self,MessageChannel,PlayerName,ChatMessage,Index,nil)
        end

    end
end




return ChatSuspendMobile
