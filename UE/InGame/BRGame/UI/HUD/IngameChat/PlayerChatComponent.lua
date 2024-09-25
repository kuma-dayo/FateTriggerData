--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local PlayerChatComponent = Class()

function PlayerChatComponent:Construct()
    --不是继承UserWidget 直接在Contruct中执行

end



function PlayerChatComponent:ReceiveBeginPlay()
    self.LocalPC = self:GetOwner()
    if self.LocalPC:GetLocalRole() ~= UE.ENetRole.ROLE_Authority then
        print("PlayerChatComponent:ReceiveBeginPlay [self]=",self)
        self.MsgList = {{
            MsgName = "EnhancedInput.TeamChat.StartTeamVoice",
            Func = self.OnVoiceMicKeyDown,
            bCppMsg = true
        }, {
            MsgName = "EnhancedInput.TeamChat.StopTeamVoice",
            Func = self.OnVoiceMicKeyUp,
            bCppMsg = true
        },
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState,	        Func = self.OnUpdateLocalPCPS,      bCppMsg = true,	WatchedObject = nil },
        --[VoiceSDK] 本地玩家加入房间通知
        { MsgName = UE.USDKTags.Get().GVoiceSDKOnJoinRoom,	        Func = self.OnGVoiceSDKOnJoinRoom,      bCppMsg = true,	WatchedObject = nil }, 
        --[VoiceSDK] 其他玩家退出房间通知
        { MsgName = UE.USDKTags.Get().GVoiceSDKOnQuitRoom,	        Func = self.OnGVoiceSDKOnQuitRoom,      bCppMsg = true,	WatchedObject = nil },
        --[VoiceSDK] 其他玩家加入、退出房间通知
        { MsgName = UE.USDKTags.Get().GVoiceSDKOnRoomMemberChanged,	        Func = self.OnGVoiceSDKOnRoomMemberChanged,      bCppMsg = true,	WatchedObject = nil },
        --[VoiceSDK] 本地玩家是否说话通知
        { MsgName = UE.USDKTags.Get().GVoiceSDKOnMicState,	        Func = self.OnGVoiceSDKOnMicState,      bCppMsg = true,	WatchedObject = nil },
        --[VoiceSDK] 其他玩家是否说话通知
        { MsgName = UE.USDKTags.Get().GVoiceSDKOnRoomMemberVoice,	Func = self.OnGVoiceSDKOnRoomMemberVoice,      bCppMsg = true,	WatchedObject = nil },
        --[VoiceSDK] 本地玩家开关麦克风通知
        { MsgName = UE.USDKTags.Get().GVoiceSDKOnMicIsOpen,	        Func = self.OnGVoiceSDKOnMicIsOpen,      bCppMsg = true,	WatchedObject = nil },
         --[VoiceSDK] 其他玩家开关麦克风通知
        { MsgName = UE.USDKTags.Get().GVoiceSDKOnRoomMemberMicChanged,	    Func = self.OnGVoiceSDKOnRoomMemberMicChanged,      bCppMsg = true,	WatchedObject = nil },
        { MsgName = "EnhancedInput.TeamChat.SwitchTeamVoiceChat",	        Func = self.OnLoopSwitchVoice,      bCppMsg = true,	WatchedObject = nil },
        { MsgName = "EnhancedInput.TeamChat.SwitchTeamVoiceMode",	        Func = self.OnLoopSwitchPressAndFree,      bCppMsg = true,	WatchedObject = nil },}

        -- 注册消息监听
        if self.MsgList then
            MsgHelper:RegisterList(self, self.MsgList)
        end

        self.PrivatePlayerId = -1
        self.PC = UE.UGameplayStatics.GetPlayerController(self, 0)
        self.PCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.PC)
        print("(Wzp)PlayerChatComponent:ReceiveBeginPlay >  self.PC=", GetObjectName(self.PC))
        self.GameState = UE.UGameplayStatics.GetGameState(self.PC)
        self:InitBanChat()
        -- self:InitBanVoice()
        -- self:InitServerUrl()
        -- self:InitVoiceRoomInfo()
        -- self:InitVocieAndChat()
        self:InitTextChat_Editor()
        self:InitTextChat_Client()
        self.PlayerExSubsystemIns = UE.UPlayerExSubsystem.Get(self)

    end

end


function PlayerChatComponent:InitBanVoice()
    print("(Wzp)PlayerChatComponent:InitBanVoice...  [ObjectName]=",GetObjectName(self))
    --语音是否封禁
    self.IsBanVoice = false
    --监听封禁语音消息
    self.VoiceCtrl = MvcEntry:GetCtrl(GVoiceCtrl)
    if not self.VoiceCtrl then
        print("(Wzp_Error)PlayerChatComponent:InitBanVoice Faild! [self.VoiceCtrl]=",self.VoiceCtrl)
        return
    end
    self.VoiceCtrl:BindBanDataSyncDelegate(self,self.OnBanVoice)

    --主动获取一次封禁状态
    local LocalBanModel = MvcEntry:GetModel(BanModel)
    if not LocalBanModel then 
        print("(Wzp_Error)PlayerChatComponent:InitBanVoice Faild! [LocalBanModel]=",LocalBanModel)
        return
    end
    
    local bLocalBanVoice = self:RegetBanVoiceState()
    self:UpdateBanVoiceState(bLocalBanVoice)
end

function PlayerChatComponent:InitBanChat()
    print("(Wzp)PlayerChatComponent:InitBanChat...  [ObjectName]=",GetObjectName(self))
    -- 主动获取一次封禁状态
    local LocalBanModel = MvcEntry:GetModel(BanModel)
    if not LocalBanModel then 
        print("(Wzp_Error)PlayerChatComponent:InitBanChat Faild! [LocalBanModel]=",LocalBanModel)
        return
    end
    local BanChat = LocalBanModel:IsBanningForType(Pb_Enum_BAN_TYPE.BAN_CHAT) -- 可能返回nil
    local bBanChat = BanChat and BanChat or false
    self:UpdateBanTextChatState(bBanChat)
end

function PlayerChatComponent:InitVoiceRoomInfo()
    print("(Wzp)PlayerChatComponent:InitVoiceRoomInfo...  [ObjectName]=",GetObjectName(self))
    --监听队伍PS更新消息
    self.TeamSubsystem = UE.UTeamExSubsystem.Get(self)
    self.TeamSubsystem.OnTeammatePSListChangedDelegate:Add(self,self.OnTeamatePSList)
    if not self.VoiceRoomInfos  then
        self.VoiceRoomInfos = {}
    end
    self:UpdateVoiceMemberInfo()
end

function PlayerChatComponent:InitTextChat_Editor()
    --初始化编辑器PIE消息分发
    print("(Wzp)PlayerChatComponent:InitTextChat_Editor...  [ObjectName]=",GetObjectName(self))
    if UE.UGFUnluaHelper.IsEditor() then
        self.S1TestManager = UE.US1TestManager.Get(self)
        local Cantainer = self.S1TestManager.ProtoTypeDelegateMap:FindRef("Chat");
        Cantainer.OnEditorProtoDistributorDelegate:Add(self, self.OnChatSync_EditorMode)
    end
end

function PlayerChatComponent:InitTextChat_Client()
    print("(Wzp)PlayerChatComponent:InitTextChat_Client...  [ObjectName]=",GetObjectName(self))
    --初始化客户端消息监听
    self.ChatCtrl = MvcEntry:GetCtrl(ChatCtrl)
    if not self.ChatCtrl then
        print("(Wzp_Error)PlayerChatComponent:InitTextChat_Client Faild! [self.ChatCtrl]=",self.ChatCtrl)
        return
    end
    self.ChatCtrl:BindChatSyncDelegate(self,self.OnChatSync)
    self.ChatCtrl:BindClearChatMsgDelegate(self,self.OnClearChatMsg)
end

function PlayerChatComponent:InitServerUrl()
    self.MatchModel = MvcEntry:GetModel(MatchModel)
    if self.MatchModel then
        local DsGroupId = self.MatchModel:GetSavedDsGroupId()
        print("PlayerChatComponent:InitServerUrl [DsGroupId]=",DsGroupId)
        self.VoiceCtrl:UpdateServerUrlForDSGroupId(DsGroupId)
    end
end


function PlayerChatComponent:OnUpdateLocalPCPS(InLocalPC, InOldPS, InNewPS)
    print("PlayerChatComponent:OnUpdateLocalPCPS",GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS))
	if self.PC == InLocalPC then
        if InNewPS then
            self.PlayerState = self.PC.OriginalPlayerState
            if self.PlayerState then
                self.PlayerId = self.PlayerState:GetPlayerId()
                self.CurrentTeamId = self.PlayerState:GetTeamInfo_Id()
                self:UpdateVoiceMemberInfo()
            end
            print("PlayerChatComponent:OnUpdateLocalPCPS self.PlayerId=",self.PlayerId, "self.CurrentTeamId=", self.CurrentTeamId)
        end
	end

end

function PlayerChatComponent:OnTeamatePSList(InTeammateList)
    print("(Wzp)PlayerChatComponent:OnTeamatePSList  [ObjectName]=",GetObjectName(self),",[InTeammateList]=",InTeammateList)
    if not InTeammateList then
        return
    end
    local TeammateNum = InTeammateList:Num()
    print("(Wzp)PlayerChatComponent:OnTeamatePSList  [TeammateNum]=",TeammateNum)
    self:UpdateVoiceMemberInfo()
end



--发送消息
function PlayerChatComponent:SendMsg(ChatChannel,MessageText)

    if UE.UGFUnluaHelper.IsEditor() then
        self:SendMessage_EditorMode(ChatChannel,MessageText)
    else
        self:SendMessage_Server(ChatChannel,MessageText)
    end
end

function PlayerChatComponent:SendMessage_Server(ChatChannel,MessageText)
    print("(Wzp)PlayerChatComponent:SendMessage_Server  [ObjectName]=",GetObjectName(self),",[ChatChannel]=",ChatChannel,",[MessageText]=",MessageText)
    if not self.ChatCtrl then
        return
    end

    local BanChatState = self:GetBanChatState()
    if BanChatState then
        return
    end

    if not self.PC then
        self.PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    end

    local PlayerState = self.LocalPC.OriginalPlayerState
    self.PlayerId = PlayerState.PlayerId


--     message ChatMsgType
-- {
--      int64 SendTime                = 1;    // 聊天发送时间，后台赋值
--      string Text                   = 2;    // 聊天文本内容
--      CHAT_TYPE ChatType            = 3;    // 聊天类型
--      string PlayerName             = 4;    // 发送者名字，后台赋值
--      int64 PlayerId                = 5;    // 发送者的PlayerId，后台赋值
--      string AvatarUrl              = 6;    // 发送者的头像Url，后台赋值
--      int32 Level                   = 7;    // 发送者的等级，后台赋值
--      int64 CurrentTeamId                  = 8;    // 队伍Id，如需要，后台赋值
--      string GameId                 = 9;    // 对局Id，局内聊天校验需要，前台赋值
--      DS_CHAT_SUBTYPE DsChatSubType = 10;   // 局内聊天子类型，用于局内区分，前台赋值
-- }

-- // 聊天请求
-- message ChatReq
-- {
--     int64 ReceiverId            = 1;    // 接收者Id
--     repeated int64 PlayerIdList = 2;    // 接收者PlayerId列表
--     ChatMsgType ChatInfo        = 3;    // 聊天信息
-- }

    --填充协议
    local TmpChatMsg = {
        SendTime = 0,
        Text = MessageText,
        ChatType = 3, --局内固定是3
        GameId = self.GameId,
        DsChatSubType = ChatChannel,
        PlayerId = self.PlayerId,
    }

    
    local MsgBody = {
        ReceiverId = 0,
        PlayerIdList = {},
        ChatInfo = TmpChatMsg,
    }
    --end

    print("(Wzp)PlayerChatComponent:SendMessage_Server  [self.GameId]=",self.GameId,",[self.PlayerId]=",self.PlayerId)

    if ChatChannel == UE.EIngameMessageChatChannel.Private then
        --如果是私聊则填充私聊对象ID
        MsgBody.ReceiverId = self.PrivatePlayerId
        
    elseif ChatChannel == UE.EIngameMessageChatChannel.Team then
        -- 如果是队伍聊天，则客户端填充所有队友的PlayerID 到 PlayerIdList,服务器根据PlayerIdList分发
        local PSList = self.TeamSubsystem:GetTeammatePSListByPS(self.PlayerState)
        print("(Wzp)PlayerChatComponent:SendMessage_Server self.PlayerState=",self.PlayerState)
        local TeamMemberLength = PSList:Length()
        print("(Wzp)PlayerChatComponent:SendMessage_Server TeamMemberLength=",TeamMemberLength)
        for i = 1, TeamMemberLength do
            local TmpPS = PSList:GetRef(i)
            if TmpPS then
                print("(Wzp)PlayerChatComponent:SendMessage_Server TmpPS=",TmpPS,",index=",i)
                local TmpPlayerId = TmpPS:GetPlayerId()
                if TmpPlayerId ~= self.PlayerId then
                    table.insert(MsgBody.PlayerIdList,TmpPlayerId)
                end
            end

        end
    end
    --end

    GameLog.Dump(MsgBody, MsgBody)

    self.ChatCtrl:SendProto(Pb_Message.ChatReq, MsgBody)
end



function PlayerChatComponent:OnClearChatMsg(PlayerID)
    print("(Wzp)PlayerChatComponent:OnClearChatMsg [ObjectName]=",GetObjectName(self),",[PlayerID]=",PlayerID)
    self:ClearMessageByPlayerID(PlayerID)
end

--接收消息
function PlayerChatComponent:OnChatSync(Msg)
    print("(Wzp)PlayerChatComponent:OnChatSync [ObjectName]=",GetObjectName(self))

    GameLog.Dump(Msg, Msg)

    if not Msg then
        return
    end

    print("(Wzp)PlayerChatComponent:OnChatSync > self=",GetObjectName(self))


    -- message ChatMsgType
    -- {
    --     int64 SendTime                = 1;    // 聊天发送时间，后台赋值
    --     string Text                   = 2;    // 聊天文本内容
    --     CHAT_TYPE ChatType            = 3;    // 聊天类型
    --     string PlayerName             = 4;    // 发送者名字，后台赋值
    --     int64 PlayerId                = 5;    // 发送者的PlayerId，后台赋值
    --     string AvatarUrl              = 6;    // 发送者的头像Url，后台赋值
    --     int32 Level                   = 7;    // 发送者的等级，后台赋值
    --     int64 CurrentTeamId                  = 8;    // 队伍Id，如需要，后台赋值
    --     string GameId                 = 9;    // 对局Id，局内聊天校验需要，前台赋值
    --     DS_CHAT_SUBTYPE DsChatSubType = 10;   // 局内聊天子类型，用于局内区分，前台赋值
    -- }

    -- // 聊天回包
    -- message ChatRsp
    -- {
    --     int64 ReceiverId                      = 1;    // 接收者Id
    --     repeated int64 PlayerIdList           = 2;    // 接收者PlayerId列表
    --     ChatMsgType ChatMsg                   = 3;    // 聊天信息
    --     int32 CDTime                          = 4;    // 聊天CD时间
    --     MSG_STATUS MsgStatus                  = 5;    // 消息状态
    --     int64 ChatExpireAt                    = 6;    // 聊天处罚结束时间戳
    -- }

    -- // 聊天消息单条推送
    -- message ChatSync
    -- {
    --     int64 ReceiverId    = 1;    // 接收者Id
    --     ChatMsgType ChatMsg = 2;    // 聊天信息
    -- }


    self.PlayerId = self.PlayerState:GetPlayerId()
    self.CurrentTeamId = self.PlayerState:GetTeamInfo_Id()

    local ChatMsg = Msg.ChatMsg
    local ReceiverId = Msg.ReceiverId

    local ChatType = ChatMsg.ChatType -- 聊天类型
    local PlayerName = ChatMsg.PlayerName
    local PlayerId = ChatMsg.PlayerId -- 发送者名字
    local LobbyTeamId = ChatMsg.TeamId
    local Text = ChatMsg.Text
    local SendTime = ChatMsg.SendTime
    local CurrentGameId = ChatMsg.GameId

    local ChatChannel = ChatMsg.DsChatSubType



    if CurrentGameId == self.GameId then
        --判断是这局游戏

        if ChatChannel == UE.EIngameMessageChatChannel.Private then
            --私聊
            self:OnReceivePrivateChatMsg(Text, ReceiverId,PlayerId)
        elseif ChatChannel == UE.EIngameMessageChatChannel.NearBy then
            --附近
            self:OnReceiveNearbyMsg(Text, PlayerId)
        elseif ChatChannel == UE.EIngameMessageChatChannel.Team then
            --队伍
            self:OnReceiveTeamMsg(Text,PlayerId)
        end
    end


end

--发送消息 编辑器模式下
function PlayerChatComponent:SendMessage_EditorMode(ChatChannel,MessageText)
    print("(Wzp)PlayerChatComponent:SendMessage_Editor > MessageText=", MessageText)

    
    local BanChatState = self:GetBanChatState()
    if BanChatState then
        return
    end


    if not self.PC then
        self.PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    end



    local PlayerState = self.LocalPC.OriginalPlayerState
    self.PlayerId = PlayerState.PlayerId

    --填充协议
    local TmpChatMsg = {
        SendTime = 0,
        Text = MessageText,
        ChatType = 3, --局内固定是3
        GameId = self.GameId,
        DsChatSubType = ChatChannel,
        PlayerId = self.PlayerId,
    }

    
    local MsgBody = {
        ReceiverId = 0,
        ChatMsg = TmpChatMsg,
        PlayerIdList = {}
    }



    if ChatChannel == UE.EIngameMessageChatChannel.Private then
        --如果是私聊则填充私聊对象ID
        MsgBody.ReceiverId = self.PrivatePlayerId

    elseif ChatChannel == UE.EIngameMessageChatChannel.Team then
        -- 如果是队伍聊天，则客户端填充所有队友的PlayerID 到 PlayerIdList,服务器根据PlayerIdList分发
        local TeamSubsystem = UE.UTeamExSubsystem.Get(self)
        local PSList = TeamSubsystem:GetTeammatePSListByPS(self.PlayerState)
        local TeamMemberLength = PSList:Length()
        for i = 1, TeamMemberLength do
            local TmpPS = PSList:GetRef(i)
            if TmpPS then
                local TmpPlayerId = TmpPS:GetPlayerId()
                if TmpPlayerId ~= self.PlayerId then
                    table.insert(MsgBody.PlayerIdList,TmpPlayerId)
                end
            end
        end
    end


    --end

    --序列化成json 
    local MsgBodyStr = JSON:encode(MsgBody)
    self.S1TestManager:SendSimulateProto("Chat",MsgBodyStr)

end


--接收消息 编辑器模式下
function PlayerChatComponent:OnChatSync_EditorMode(Msg)
    print("(Wzp)PlayerChatComponent:OnChatSync_EditorMode > Msg=", Msg)

    GameLog.Dump(Msg, Msg)

    if not Msg then
        return
    end

    local MsgBodyTable = JSON:decode(Msg)
    self.PlayerId = self.PlayerState:GetPlayerId()
    self.CurrentTeamId = self.PlayerState:GetTeamInfo_Id()

    local ChatMsg = MsgBodyTable.ChatMsg
    local ReceiverId = MsgBodyTable.ReceiverId

    local ChatType = ChatMsg.ChatType -- 聊天类型
    local PlayerName = ChatMsg.PlayerName
    local PlayerId = ChatMsg.PlayerId -- 发送者名字
    local LobbyTeamId = ChatMsg.TeamId
    local Text = ChatMsg.Text
    local SendTime = ChatMsg.SendTime
    local CurrentGameId = ChatMsg.GameId

    local ChatChannel = ChatMsg.DsChatSubType


    if CurrentGameId == self.GameId then
        --判断是这局游戏

        if ChatChannel == UE.EIngameMessageChatChannel.Private then
            --私聊
            self:OnReceivePrivateChatMsg(Text, ReceiverId,PlayerId)
        elseif ChatChannel == UE.EIngameMessageChatChannel.NearBy then
            --附近
            self:OnReceiveNearbyMsg(Text, PlayerId)
        elseif ChatChannel == UE.EIngameMessageChatChannel.Team then
            --队伍
            self:OnReceiveTeamMsg(Text,PlayerId)
        end
    end


end




--接收私聊消息
function PlayerChatComponent:OnReceivePrivateChatMsg(MsgContent, ReceivePlayerId,PlayerId)
    print("(Wzp)PlayerChatComponent:OnReceivePrivateChatMsg > MsgContent=",MsgContent,",ReceivePlayerId=",ReceivePlayerId,",PlayerId=",PlayerId)
    --判断接收者playerid
    if ReceivePlayerId == self.PlayerId or PlayerId == self.PlayerId then
        self:ShowMessage(UE.EIngameMessageChatChannel.Private,PlayerId, MsgContent)
    end
end

--接收附近消息
function PlayerChatComponent:OnReceiveNearbyMsg(MsgContent, PlayerId)
    print("(Wzp)PlayerChatComponent:OnReceiveNearbyMsg > MsgContent=",MsgContent,",PlayerId=",PlayerId)
    --判断距离
    --拿到发送者id 、 拿到自己id
    --根据id获取pc pawn，判断两个pawn的距离，如果小于则收到消息
    local SelfPawn = self.PlayerExSubsystemIns:GetPawnById(self.PlayerId)
    local SendPawn = self.PlayerExSubsystemIns:GetPawnById(PlayerId)
    print("PlayerChatComponent: OnReceiveNearbyMsg self.PlayerExSubsystemIns=",self.PlayerExSubsystemIns)
    print("PlayerChatComponent: OnReceiveNearbyMsg self.PlayerId=",self.PlayerId)
    print("PlayerChatComponent: OnReceiveNearbyMsg PlayerId=",PlayerId)
    if not SendPawn then
        print("PlayerChatComponent: OnReceiveNearbyMsg SendPawn= nil")
        --获取不到pawn，定义为失去相关性，直接不做任何处理
        return
    end
    
    local SenderPS =  self.GameState:GetPlayerState(PlayerId)
    print("(Wzp)PlayerChatComponent:OnReceiveNearbyMsg > SenderPS = ",SenderPS)
    local InGameTeamId = 0
    if SenderPS then
        InGameTeamId = SenderPS:GetTeamInfo_Id()
    end

    --判断队伍id
    if InGameTeamId > 0 then
        --组队聊天
        --判断是不是一个队伍的
        if InGameTeamId ==  self.CurrentTeamId then
            self:ShowMessage(UE.EIngameMessageChatChannel.NearBy, PlayerId, MsgContent)
            return
        end
    end

    local Distance = SendPawn:GetDistanceTo(SelfPawn)
    print("(Wzp)PlayerChatComponent:OnReceiveNearbyMsg > Distance=",Distance)
    if Distance < self.TextMsgReceiveRange then
        self:ShowMessage(UE.EIngameMessageChatChannel.NearBy, PlayerId, MsgContent)
    end

    print("(Wzp)PlayerChatComponent:OnReceiveNearbyMsg > self.TextMsgReceiveRange=",self.TextMsgReceiveRange)

end

--接收队伍消息
function PlayerChatComponent:OnReceiveTeamMsg(MsgContent, PlayerId)

    print("(Wzp)PlayerChatComponent:OnReceiveTeamMsg > MsgContent=",MsgContent,",PlayerId=",PlayerId)
    local SenderPS =  self.GameState:GetPlayerState(PlayerId)
    if not SenderPS then
        print("(Wzp)PlayerChatComponent:OnReceiveTeamMsg > SenderPS = nil")
        return
    end
    local InGameTeamId = SenderPS:GetTeamInfo_Id()
    print("(Wzp)PlayerChatComponent:OnReceiveTeamMsg  [InGameTeamId]=",InGameTeamId,",[self.CurrentTeamId]=",self.CurrentTeamId)
    print("(Wzp)PlayerChatComponent:OnReceiveTeamMsg  [InGameTeamId.type]=",type(InGameTeamId),",[self.CurrentTeamId.type]=",type(self.CurrentTeamId))
    -- local SenderTeamIdStr = tostring(InGameTeamId)
    --判断队伍id
    if InGameTeamId == self.CurrentTeamId then
        --组队聊天
        --判断是不是一个队伍的
        self:ShowMessage(UE.EIngameMessageChatChannel.Team, PlayerId, MsgContent)
    end
end


function PlayerChatComponent:ReceiveEndPlay()
    print("(Wzp)PlayerChatComponent:ReceiveEndPlay",GetObjectName(self))
    self:FinalProcessing()
end



function PlayerChatComponent:OnDestroy()
    print("PlayerChatComponent:OnDestroy self=",GetObjectName(self))
    self:FinalProcessing()
end

function PlayerChatComponent:FinalProcessing()
    print("PlayerChatComponent:FinalProcessing self=",GetObjectName(self))
    local Owner = self:GetOwner()
    if  Owner:HasAuthority() then
        print("(Wzp)PlayerChatComponent:ReceiveEndPlay > end play server")
        return
    end

    self:LeaveGameRangeRoom()
    self:LeaveTeamRoom()

    if self.ChatCtrl then
        self.ChatCtrl:UnBindChatSyncDelegate()
        self.ChatCtrl:UnBindClearChatMsgDelegate()
    end

    if self.VoiceCtrl then
        self.VoiceCtrl:UnBindBanDataSyncDelegate()
    end
end



function PlayerChatComponent:SetPrivatePlayerId(PlayerId)

    self.PrivatePlayerId = PlayerId
    UE.UKismetSystemLibrary.PrintString(nil, tostring(self.PrivatePlayerId), true, false, UE.FLinearColor(1, 0, 0, 1), 5)
    print("(Wzp)PlayerChatComponent:SetPrivatePlayerId > self.PrivatePlayerId=",self.PrivatePlayerId ,",self.PlayerId=",self.PlayerId)
end

--/////////////////////////////////////////////////////////////////////////////////////////////////语音总开关相关/////////////////////////////////////////////////////////////////////////////////////////////////

function PlayerChatComponent:InitVocieAndChat()
    self.EVoiceAndChatState = self.DefaultChatorVoiceMode
    self.VoiceNeedPressSetting = self.DefaultPressChatMode --0=按下说话 1=自由说话麦
    self.SpeakerMode = self.DefaultSpeakerMode
    self.VoiceMicMode = self.DefaultMicMode
    self.bSpeaking = false

    if UE.UGFUnluaHelper.IsEditor()  then
        self.bJoinRoomCompelete = true
        if BridgeHelper.IsMobilePlatform() then
            self:OpenOrCloseVoice(0)
        end
    else
        self.bJoinRoomCompelete = false
    end

    -- self:OnSyncGameIDAndTeamIDCompelete()
end


--#region 语音相关逻辑

--设置语音总开关
function PlayerChatComponent:OpenOrCloseVoice(EVoiceAndChatState)
    print("(Wzp)PlayerChatComponent:OpenOrCloseVoice=",EVoiceAndChatState)

    local bBanVoice = self:GetBanVoiceState()
    if bBanVoice then
        self:ShowBanChatTips()
        return
    end

    if self.bJoinRoomCompelete then
        self.EVoiceAndChatState = EVoiceAndChatState
        MsgHelper:SendCpp(self, GameDefine.MsgCpp.BattleChat_OnOpenOrCloseVoiceChat)
        self:UpdateVoiceTotalMode()
    end
end

function PlayerChatComponent:UpdateVoiceTotalMode()
    print("(Wzp)PlayerChatComponent:UpdateVoiceTotalMode")
    if self.EVoiceAndChatState  == 0  then
         --打开状态
        self:UpdateSpeakerMode()
        --打开之前要判断是不是[按下说话]，如果是[按下说话]则不修改语音状态
        self:UpdateVoiceNeedsPress()
     elseif self.EVoiceAndChatState  == 1 then
        --关闭状态
        self:SetTeamMic(false)
        self:SetNearMic(false)
        self:SetTeamSpeaker(false)
        self:SetNearSpeaker(false)
     end
end

function PlayerChatComponent:IsOpenVoice()
    return self.EVoiceAndChatState  == 0
end

--加入队伍语音房间
function PlayerChatComponent:JoinTeamRoom()
    print("(Wzp)PlayerChatComponent:JoinTeamRoom  [ObjectName]=",GetObjectName(self),",[self.IsBanVoice]=",self.IsBanVoice)
    
    if self.IsBanVoice then
        print("(Wzp)PlayerChatComponent:JoinTeamRoom  BanVoice")
        return
    end
    local TeamRoomId = self:GetRtcTeamRoomId()

    if self.JoinTeamRoomID ~= nil then
        --禁止重复加入
        print(" Return: You are already in the room, do not add to the room again! [self.JoinTeamRoomID]=",self.JoinTeamRoomID)
        return 
    end

    if TeamRoomId == "" then
        print(" return: Perhaps the value has not been replicated yet, and the timing is too early. [TeamRoomId]= nil ")
        return
    end

    self.JoinTeamRoomID = TeamRoomId
    UE.UGVoiceHelper.JoinTeamRoom(TeamRoomId,10000)
    self.bJoinTeamRoom = true
    print("(Wzp)PlayerChatComponent:JoinTeamRoom > TeamRoomId=",TeamRoomId)
end

--加入游戏范围语音房间
function PlayerChatComponent:JoinGameRangeRoom()
    print("(Wzp)PlayerChatComponent:JoinGameRangeRoom  [ObjectName]=",GetObjectName(self),",[self.IsBanVoice]=",self.IsBanVoice)
    if self.IsBanVoice then
        print("(Wzp)PlayerChatComponent:JoinGameRangeRoom  BanVoice")
        return
    end
    local RangeRoomId = self:GetRtcGameRoomId()

    if self.JoinRangeRoomID ~= nil then
        --禁止重复加入
        print(" Return: You are already in the room, do not add to the room again. [self.JoinRangeRoomID]=",self.JoinRangeRoomID)
        return 
    end

    if RangeRoomId == "" then
        print(" return: Perhaps the value has not been replicated yet, and the timing is too early. [RangeRoomId]= nil ")
        return
    end

    -- 设置模式（SetMode）为实时语音（RealTime）模式后，加入房间（JoinTeamRoom 或 JoinRangeRoom）之前
    -- UE.UGVoiceHelper.EnableMultiRoom(true)
        
    self.JoinRangeRoomID = RangeRoomId
    UE.UGVoiceHelper.JoinRangeRoom(RangeRoomId,10000)
    print("(Wzp)PlayerChatComponent:JoinGameRangeRoom > RangeRoomId=",RangeRoomId)
end

--离开队伍语音房间
function PlayerChatComponent:LeaveTeamRoom()
    local TeamRoomId = self:GetRtcTeamRoomId()
    if  self.JoinTeamRoomID == nil then
        return
    end
    self.JoinTeamRoomID = nil
    self:SetTeamMic(false)
    self:SetTeamSpeaker(false)
    UE.UGVoiceHelper.QuitRoom(TeamRoomId,10000)
end


--离开游戏范围语音房间
function PlayerChatComponent:LeaveGameRangeRoom()
    local RangeRoomId = self:GetRtcGameRoomId()
    if  self.JoinRangeRoomID == nil then
        return
    end
    self.JoinRangeRoomID = nil
    self:SetNearMic(false)
    self:SetNearSpeaker(false)
    UE.UGVoiceHelper.QuitRoom(RangeRoomId,10000)
end




--/////////////////////////////////////////////////////////////////////////////////////////////////按下说话相关/////////////////////////////////////////////////////////////////////////////////////////////////
--设置是否需要按下说话
function PlayerChatComponent:SetVoiceNeedsPress(MicropKeyMode)

    self.VoiceNeedPressSetting = MicropKeyMode
    local bIsOpenVoice = self:IsOpenVoice()
    print("(Wzp)PlayerChatComponent:SetVoiceNeedsPress > MicropKeyMode=",MicropKeyMode," bIsOpenVoice=",bIsOpenVoice)
    if bIsOpenVoice then
        MsgHelper:SendCpp(self, GameDefine.MsgCpp.BattleChat_OnOpenOrCloseVoiceChat)
        self:UpdateVoiceNeedsPress()
    end
end

function PlayerChatComponent:UpdateVoiceNeedsPress()
    if self.VoiceNeedPressSetting == UE.EMicropKeyMode.PressChat then
        self:SetTeamMic(false)
        self:SetNearMic(false)
    else
        self:SetVoiceMicMode(self.VoiceMicMode)
    end
end


--InhanceInput
--当说话按键按下
function PlayerChatComponent:OnVoiceMicKeyDown()
    local bIsOpenVoice = self:IsOpenVoice()
    print("(Wzp)PlayerChatComponent:OnVoiceMicKeyDown bIsOpenVoice=",bIsOpenVoice)
    if bIsOpenVoice then
        local bIsPressChatMode = self:IsPressChatMode()
        if bIsPressChatMode then
            print("(Wzp)PlayerChatComponent:OnVoiceMicKeyDown Speaking...")
            self.bSpeaking = true
            self:PressVoiceModeChat(true)
            self:UpdateMicMode()
        end
    MsgHelper:SendCpp(self, GameDefine.MsgCpp.BattleChat_OnOpenOrCloseVoiceChat,{IsPressChat = true })
    end
end

--InhanceInput
--当说话按键抬起
function PlayerChatComponent:OnVoiceMicKeyUp()
    local bIsOpenVoice = self:IsOpenVoice()
    print("(Wzp)PlayerChatComponent:OnVoiceMicKeyUp bIsOpenVoice=",bIsOpenVoice)
    if bIsOpenVoice then
        self.bSpeaking = false
        MsgHelper:SendCpp(self, GameDefine.MsgCpp.BattleChat_OnOpenOrCloseVoiceChat)
        --必须打开 按下说话 才执行否则不生效
        local bIsPressChatMode = self:IsPressChatMode()
        if bIsPressChatMode then
            self:PressVoiceModeChat(false)
            self:SetTeamMic(false)
            self:SetNearMic(false)
        end
    end
end


function PlayerChatComponent:IsPressChatMode()
    return self.VoiceNeedPressSetting == UE.EMicropKeyMode.PressChat
end

--/////////////////////////////////////////////////////////////////////////////////////////////////麦克风模式相关/////////////////////////////////////////////////////////////////////////////////////////////////
--设置麦克风模式 ： 附近=0、队伍=1、关闭=2
function PlayerChatComponent:SetVoiceMicMode(VoiceMicMode)
    print("(Wzp)PlayerChatComponent:SetVoiceMicMode > VoiceMicMode=",VoiceMicMode)

    local bBanVoice = self:GetBanVoiceState()
    if bBanVoice then
        return
    end
    
    self.VoiceMicMode = VoiceMicMode
    MsgHelper:SendCpp(self, GameDefine.MsgCpp.BattleChat_OnOpenOrCloseVoiceChat)

    local bIsOpenVoice = self:IsOpenVoice()
    if not bIsOpenVoice then
        return
    end

    local bIsPressChatMode = self:IsPressChatMode()
    if bIsPressChatMode then
        --如果打开了按下说话先不生效 只设置状态枚举缓存
        return
    end


    self:UpdateMicMode()
end

function PlayerChatComponent:UpdateMicMode()
    if self.VoiceMicMode == UE.EMicMode.Near then
        self:SetTeamMic(true)
        self:SetNearMic(true)
    elseif self.VoiceMicMode == UE.EMicMode.Team then
        self:SetTeamMic(true)
        self:SetNearMic(false)
    elseif self.VoiceMicMode == UE.EMicMode.Close then
        self:SetTeamMic(false)
        self:SetNearMic(false)
    end

    print("(Wzp)PlayerChatComponent:UpdateMicMode > self.VoiceMicMode=",self.VoiceMicMode)
end



--队伍麦克风设置
function PlayerChatComponent:SetTeamMic(bIsOn)
    print("(Wzp)PlayerChatComponent:SetTeamMic > bIsOn=",bIsOn)
     local TeamRoomId = self:GetRtcTeamRoomId()
     UE.UGVoiceHelper.EnableRoomMicrophone(TeamRoomId,bIsOn)
end

--游戏麦克风设置
function PlayerChatComponent:SetNearMic(bIsOn)
    print("(Wzp)PlayerChatComponent:SetNearMic > bIsOn=",bIsOn)
    local NearRoomId = self:GetRtcGameRoomId()
    UE.UGVoiceHelper.EnableRoomMicrophone(NearRoomId,bIsOn)
end

--/////////////////////////////////////////////////////////////////////////////////////////////////扬声器模式相关/////////////////////////////////////////////////////////////////////////////////////////////////
--设置音频模式 ： 附近=0、队伍=1、关闭=2
function PlayerChatComponent:SetSpeakerMode(SpeakerMode)

    print("(Wzp)PlayerChatComponent:SetSpeakerMode > SpeakerMode=",SpeakerMode)
    local bBanVoice = self:GetBanVoiceState()
    if bBanVoice then
        return
    end
    self.SpeakerMode = SpeakerMode
    MsgHelper:SendCpp(self, GameDefine.MsgCpp.BattleChat_OnOpenOrCloseVoiceChat)
    local bIsOpenVoice = self:IsOpenVoice()
    if not bIsOpenVoice then
        return
    end

    self:UpdateSpeakerMode()
end

function PlayerChatComponent:UpdateSpeakerMode()
    if self.SpeakerMode == UE.ESpeakerMode.Near then
        self:SetTeamSpeaker(true)
        self:SetNearSpeaker(true)
    elseif self.SpeakerMode == UE.ESpeakerMode.Team then
        self:SetTeamSpeaker(true)
        self:SetNearSpeaker(false)
    elseif self.SpeakerMode == UE.ESpeakerMode.Close then
        self:SetTeamSpeaker(false)
        self:SetNearSpeaker(false)
    end
    print("(Wzp)PlayerChatComponent:UpdateSpeakerMode > self.SpeakerMode=",self.SpeakerMode)
end


--设置队伍声音
function PlayerChatComponent:SetTeamSpeaker(bIsOn)
    print("(Wzp)PlayerChatComponent:SetTeamSpeaker > bIsOn=",bIsOn)
    local TeamRoomId = self:GetRtcTeamRoomId()
    UE.UGVoiceHelper.EnableRoomSpeaker(TeamRoomId,bIsOn)
end

--设置游戏声音
function PlayerChatComponent:SetNearSpeaker(bIsOn)
    print("(Wzp)PlayerChatComponent:SetNearSpeaker > bIsOn=",bIsOn)
    local RangeRoomId = self:GetRtcGameRoomId()
    UE.UGVoiceHelper.EnableRoomSpeaker(RangeRoomId,bIsOn)
end


--/////////////////////////////////////////////////////////////////////////////////////////////////EnhanceInput相关/////////////////////////////////////////////////////////////////////////////////////////////////
function PlayerChatComponent:OnLoopSwitchVoice()
    local TempVoiceAndChatState = (self.EVoiceAndChatState + 1) % 2
    self:OpenOrCloseVoice(TempVoiceAndChatState)
end

function PlayerChatComponent:OnLoopSwitchPressAndFree()
    local TempVoiceNeedPressSettin = (self.VoiceNeedPressSetting + 1) % 2
    self:SetVoiceNeedsPress(TempVoiceNeedPressSettin)
end




--[[
	* 当房间中的其他成员开始说话或停止说话时，通过该回调接口进行通知。
    * VolArrayJsonStr格式为
    * {
    *	"VolArray" = [
    *		{
    *			"memberid": int,
    *			"status": int (当前状态，零值表示没有说话，非零值表示正在说话)
    *		},...
    *	]
    */
]]
function PlayerChatComponent:OnGVoiceSDKOnRoomMemberVoice(roomName,member,status)

    local TeamRoomId = self:GetRtcTeamRoomId()
    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnRoomMemberVoice  [ObjectName]=",GetObjectName(self),",[roomName]=",roomName,",[status]=",status,",[TeamRoomId]=",TeamRoomId)
    if roomName ~= TeamRoomId then
        return
    end

    local bSpeaking = status ~= 0
    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnRoomMemberVoice  [bSpeaking]=",bSpeaking)
    --只要队伍的说话状态
    self.VoiceRoomMemberSpeakNotify:Broadcast(member,bSpeaking)
end


---OnGVoiceSDKOnMicState 本地客户端说话
---@param status int 不等于0表示说话
function PlayerChatComponent:OnGVoiceSDKOnMicState(status)
    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnMicState  [ObjectName]=",GetObjectName(self),",[status]=",status)

    local bVoiceSpeaking = false

    if self.VoiceMicMode ~= UE.ESpeakerMode.Close then
        if  self.VoiceNeedPressSetting == UE.EMicropKeyMode.PressChat then
            if self.bSpeaking == true then
                bVoiceSpeaking = (status ~= 0)
            end
        else
            bVoiceSpeaking = (status ~= 0)
        end
    end
    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnMicState  [bSpeaking]=",bVoiceSpeaking)
    self.VoiceLocalSpeakNotify:Broadcast(bVoiceSpeaking)
end

--- 本地开关麦
---@param InCloudVoiceEvent int 状态枚举
function PlayerChatComponent:OnGVoiceSDKOnMicIsOpen(IsOpen)
    -- //EVENT_MIC_STATE_OPEN_SUCC = 30,   // 开麦成功
    -- //EVENT_MIC_STATE_OPEN_ERR = 31,   // 开麦出错
    -- //EVENT_MIC_STATE_NO_OPEN = 32,   // 关麦
    -- //EVENT_MIC_STATE_OCCUPANCY = 33,   // 麦克风被其他应用占用了
    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnMicIsOpen  [ObjectName]=",GetObjectName(self),",[IsOpen]=",IsOpen)
    self.VoiceLocalIsOpenMicNotify:Broadcast(IsOpen)
end


---远端开关麦
---@param RoomName FString 房间
---@param MemberId int32 成员ID
---@param OpenId FString PlayerID
---@param IsOpen bool 是否开麦
function PlayerChatComponent:OnGVoiceSDKOnRoomMemberMicChanged(RoomName,MemberID,OpenID,IsOpen)
    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnRoomMemberMicChanged  [ObjectName]=",GetObjectName(self),",[RoomName]=",RoomName,",[MemberID]=",MemberID,",[OpenID]=",OpenID,",[IsOpen]=",IsOpen)
    local TeamRoomId = self:GetRtcTeamRoomId()
    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnRoomMemberMicChanged  [TeamRoomId]=",TeamRoomId)
    if RoomName ~= TeamRoomId then
        return
    end

    local PlayerID = math.floor(tonumber(OpenID))
    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnRoomMemberMicChanged  [PlayerID]=",PlayerID)
    self.VoiceRemoteIsOpenMicNotify:Broadcast(PlayerID,IsOpen)
end



---当房间中有成员加入或退出时，通过该回调接口通知。 注：国战语音房间暂不支持该功能
---@param RoomName FString 房间
---@param MemberId int32 成员ID
---@param OpenId FString PlayerID
---@param IsIn bool 进房/false 退房
function PlayerChatComponent:OnGVoiceSDKOnRoomMemberChanged(RoomName,MemberId,OpenId,IsIn)
    local TeamRoomId = self:GetRtcTeamRoomId()
    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnRoomMemberChanged  [ObjectName]=",GetObjectName(self),",[RoomName]=",RoomName,",[MemberId]=",MemberId,",[OpenId]=",OpenId,",[IsIn]=",IsIn,",[TeamRoomId]=",TeamRoomId)
    if RoomName ~= TeamRoomId then
        return
    end

    local ExistRoom = self:ExistRoomInfo(OpenId)
    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnRoomMemberChanged  [ExistRoom]=",ExistRoom)
    if ExistRoom then
        local RoomInfo = self:GetVoiceRoomInfoByPlayerID(OpenId)
        RoomInfo.bInRoom = IsIn
        RoomInfo.MemberID = MemberId
        GameLog.Dump(RoomInfo, RoomInfo)
    else
        local RoomInfo = self:AddRoomInfoByPlayerID(OpenId)
        RoomInfo.bInRoom = IsIn
        RoomInfo.MemberID = MemberId
        GameLog.Dump(RoomInfo, RoomInfo)
    end

end


---本地加入房间后
---@param RoomName FString 房间
---@param IsJoinSuccess bool 加入房间成功
function PlayerChatComponent:OnGVoiceSDKOnJoinRoom(RoomName,IsJoinSuccess)
    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnJoinRoom  [ObjectName]=",GetObjectName(self),",[RoomName]=",RoomName,",[IsJoinSuccess]=",IsJoinSuccess)
    if not IsJoinSuccess then
        print("(Wzp_Error)PlayerChatComponent:OnGVoiceSDKOnJoinRoom  [IsJoinSuccess]=false")
        return
    end

    self.bJoinRoomCompelete = true

    if BridgeHelper.IsMobilePlatform() then
        self:OpenOrCloseVoice(0)
    end

    --本地客户端执行
    --本地加入队伍房间，则设置队伍语音信息，加入附近语音只设置本地自己的状态，不做任何处理
    local TeamRoomID = self:GetRtcTeamRoomId()
    local GameRoomID = self:GetRtcGameRoomId()
    local RoomMembersJsonStr = UE.UGVoiceHelper.GetRoomMembers(RoomName)

    if RoomName == TeamRoomID  then
        --本地加入队伍语音房间
        if RoomMembersJsonStr ~= "" then
            local JsonObject = json.decode(RoomMembersJsonStr)
            if JsonObject and JsonObject.MemberList then
                local MemberList = JsonObject.MemberList
                local PlayerIdStr = self.PlayerId
                print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnJoinRoom  [#MemberList]=",#MemberList,",[PlayerIdStr]=",PlayerIdStr)
                for index = 1, #MemberList do
                    local Member = MemberList[index]
                    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnJoinRoom  [index]=",index,",[Member]=",Member)
                    if Member then
                        local ExistRoom = self:ExistRoomInfo(PlayerIdStr)
                        print("(Wzp)PlayerChatComponent:UpdateVoiceMemberInfo  [PlayerIdStr]=",PlayerIdStr,",[ExistRoom]=",ExistRoom)
                        if not ExistRoom then
                            local RoomInfo = self:AddRoomInfoByPlayerID(PlayerIdStr)
                            RoomInfo.MicStatus = Member.micstatus
                            RoomInfo.MemberID = Member.memberid
                            RoomInfo.bInTeamRoom = true
                        end
                    end
                end
            end
        end

    --设置语音总开关状态
    self:UpdateVoiceTotalMode()
    MsgHelper:SendCpp(self, GameDefine.MsgCpp.BattleChat_OnOpenOrCloseVoiceChat)
    elseif RoomName == GameRoomID then
        --本地加入附近语音房间
        local RoomInfo = self:GetVoiceRoomInfoByPlayerID(self.PlayerId)
        if not RoomInfo then
            RoomInfo = self:AddRoomInfoByPlayerID(self.PlayerId)
        end
        RoomInfo.bInNearRoom = true
    end
end


---本地退出房间后通知
---@param RoomName string 房间
---@param IsQuitSuccess bool 退出房间成功
function PlayerChatComponent:OnGVoiceSDKOnQuitRoom(RoomName,IsQuitSuccess)
    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnQuitRoom  [ObjectName]=",GetObjectName(self),",[RoomName]=",RoomName,",[IsQuitSuccess]=",IsQuitSuccess)

    if not IsQuitSuccess then
        return
    end

    --本地客户端退出成房间功的处理
    local RangeRoomId = self:GetRtcGameRoomId()
    local TeamRoomId = self:GetRtcTeamRoomId()
    print("(Wzp)PlayerChatComponent:OnGVoiceSDKOnQuitRoom  [RangeRoomId]=",RangeRoomId,",[TeamRoomId]=",TeamRoomId)
    --拿到本地RoomInfo
    local LocalRoomInfo = self:GetVoiceRoomInfoByPlayerID(self.PlayerId)
    --判断是RoomInfo的哪个房间，找到相应的房间设置bool成退出状态
    if LocalRoomInfo then
        if RoomName == RangeRoomId then
            LocalRoomInfo.bInNearRoom = false
        elseif RoomName == TeamRoomId then
            LocalRoomInfo.bInTeamRoom = false
        end
    end
end



--  C++ Call lua
--  当GameID 和 TeamID 完全Rep下来之后会调用此方法
--  在此处加入队伍语音和附近语音，避免加入房间用空的 GameID 和 TeamID 
function PlayerChatComponent:OnSyncGameIDAndTeamIDCompelete()
    print("(Wzp)PlayerChatComponent:OnSyncGameIDAndTeamIDCompelete  [ObjectName]=",GetObjectName(self),"[self]=",self)
    --加入两个房间队伍、附近

    --这里有时序问题：self.IsBanVoice 还没有获取，先调用OnSyncGameIDAndTeamIDCompelete，JoinTeamRoom中做了 self.IsBanVoice，导致没有执行加入房间
    --修复：主动获取一次状态

    self:InitBanVoice()
    self:InitServerUrl()
    self:InitVoiceRoomInfo()
    self:InitVocieAndChat()

    local bLocalBanVoice = self:RegetBanVoiceState()
    self:UpdateBanVoiceState(bLocalBanVoice)

    self:JoinGameRangeRoom()
    self:JoinTeamRoom()

    

    --之后会触发加入成功失败结果回调
    --在成功的时候设置麦克风和扬声器初始状态

end


--- 当有成员加入房间的时候添加成员的房间信息
function PlayerChatComponent:UpdateVoiceMemberInfo()
    print("(Wzp)PlayerChatComponent:UpdateVoiceMemberInfo  [ObjectName]=",GetObjectName(self))

    local TeamSubsystem = UE.UTeamExSubsystem.Get(self)
    local PSList = TeamSubsystem:GetTeammatePSListByPS(self.PlayerState)
    local TeamMemberLength = PSList:Length()
    print("(Wzp)PlayerChatComponent:UpdateVoiceMemberInfo  [TeamMemberLength]=",TeamMemberLength)
    for i = 1, TeamMemberLength do
        local TmpPS = PSList:GetRef(i)
        if TmpPS then
            local TmpPlayerId = TmpPS:GetPlayerId()
            local ListItem = self:GetVoiceRoomInfoByPlayerID(TmpPlayerId)
            if not ListItem then
                local ExistRoom = self:ExistRoomInfo(TmpPlayerId)
                print("(Wzp)PlayerChatComponent:UpdateVoiceMemberInfo  [TmpPlayerId]=",TmpPlayerId,",[ExistRoom]=",ExistRoom)
                if not ExistRoom  then
                    self:AddRoomInfoByPlayerID(TmpPlayerId)
                end
            end
        end
    end
    GameLog.Dump(self.VoiceRoomInfos, self.VoiceRoomInfos)
end


--- 根据PlayerID添加RoomInfo
---@param InPlayerID int32
---@return RoomInfo RoomInfo
function PlayerChatComponent:AddRoomInfoByPlayerID(InPlayerID)
    print("(Wzp)PlayerChatComponent:AddRoomInfoByPlayerID  [ObjectName]=",GetObjectName(self),",[InPlayerID.Type]=",type(InPlayerID),",[InPlayerID]=",InPlayerID)
    local PlayerID_String = tostring(InPlayerID)
    if not self.VoiceRoomInfos  then
        self.VoiceRoomInfos = {}
    end

    if self.VoiceRoomInfos[PlayerID_String] then
        return
    end

    
    --这里还要判断该位玩家ID是否是队伍里面的队友
    local RoomInfo = {
        OpenID = PlayerID_String,
        MemberID = -1,
        bEnableSpeaker = true, --扬声器开关
        SpeakerVolume = 100, --扬声器音量
        bInRoom = false, --是否在房间中
        bSpeaking = false, --是否说话中
        bMicStatus = false, --麦克风状态
        bInNearRoom = false,
        bInTeamRoom = false,
    }

    self.VoiceRoomInfos[PlayerID_String] = RoomInfo
    MsgHelper:SendCpp(self, GameDefine.MsgCpp.BattleChat_OnAddRoomMemberInfo)
    return RoomInfo
end

--- 根据PlayerID获取RoomInfo
---@param InPlayerID int32
---@return RoomInfo 房间信息
function PlayerChatComponent:GetVoiceRoomInfoByPlayerID(InPlayerID)
    if not InPlayerID then
        print("(Wzp_Error)PlayerChatComponent:GetVoiceRoomInfoByPlayerID  [InPlayerID=nil]")
        return
    end
    print("(Wzp_Error)PlayerChatComponent:GetVoiceRoomInfoByPlayerID  [ObjectName]=",GetObjectName(self),",[InPlayerID]=",InPlayerID,",[InPlayerID.type]=",type(InPlayerID))
    local PlayerID_String = tostring(InPlayerID)
    if not self.VoiceRoomInfos  then
        self.VoiceRoomInfos = {}
    end
    local RetRoomInfo = self.VoiceRoomInfos[PlayerID_String]
    if not RetRoomInfo then
        print("(Wzp_Error)PlayerChatComponent:GetVoiceRoomInfoByPlayerID  [RetRoomInfo=nil]")
    end
    return RetRoomInfo
end

--- 判断是否存在RoomInfo
---@param InPlayerID int32
---@return IsInRoom bool
function PlayerChatComponent:ExistRoomInfo(InPlayerID)
    local PlayerID_String = tostring(InPlayerID)
    if self.VoiceRoomInfos then
        if self.VoiceRoomInfos[PlayerID_String] then
            return true
        end
    end
    return false
end


--- 返回所有的RoomInfo
---@return RoomInfo 房间信息
function PlayerChatComponent:GetRoomInfos()
    return self.VoiceRoomInfos
end

--- 设置某个玩家在本地的音量大小
---@param InPlayerId int32
---@param InVolume int32
function PlayerChatComponent:SetSpeakerVolume(InPlayerId,InVolume)
    print("(Wzp)PlayerChatComponent:SetSpeakerVolume  [ObjectName]=",GetObjectName(self),",[InPlayerId]=",InPlayerId,",[InVolume]=",InVolume)

    local RoomInfo = self:GetVoiceRoomInfoByPlayerID(InPlayerId)

    if not RoomInfo then
        return
    end

    RoomInfo.SpeakerVolume = InVolume
    UE.UGVoiceHelper.SetPlayerVolume(InPlayerId,InVolume)
end

---获得某个玩家在本地的音量大小
---@param InPlayerId int32
---@return int32  音量大小
function PlayerChatComponent:GetSpeakerVolume(InPlayerID)
    print("(Wzp)PlayerChatComponent:GetSpeakerVolume  [ObjectName]=",GetObjectName(self),",[InPlayerID]=",InPlayerID)
    local RoomInfo = self:GetVoiceRoomInfoByPlayerID(InPlayerID)
    return RoomInfo.SpeakerVolume
end

--- 设置某个玩家在本地的扬声器开关
---@param InPlayerID int32
---@param bIsEnable any
function PlayerChatComponent:SetSpakerState(InPlayerID,bIsEnable)
    print("(Wzp)PlayerChatComponent:SetSpakerState  [ObjectName]=",GetObjectName(self),",[InPlayerID]=",InPlayerID,",[bIsEnable]=",bIsEnable)
    local RoomInfo = self:GetVoiceRoomInfoByPlayerID(InPlayerID)
    if not RoomInfo then
        print("(Wzp_Error)PlayerChatComponent:SetSpakerState  [RoomInfo=nil]")
        return
    end
    local MemberID = RoomInfo.MemberID
    RoomInfo.bEnableSpeaker = bIsEnable
    local RangeRoomId = self:GetRtcGameRoomId()
    local TeamRoomId = self:GetRtcTeamRoomId()
    local Disable = not bIsEnable
    UE.UGVoiceHelper.ForbidMemberVoice(MemberID,Disable,RangeRoomId)
    UE.UGVoiceHelper.ForbidMemberVoice(MemberID,Disable,TeamRoomId)
end

--- 获取某个玩家在本地的扬声器开关
---@param InPlayerID int32
---@return bIsEnable any
function PlayerChatComponent:GetSpakerState(InPlayerID)
    print("(Wzp)PlayerChatComponent:GetSpakerState  [ObjectName]=",GetObjectName(self),",[InPlayerID]=",InPlayerID)
    local RoomInfo = self:GetVoiceRoomInfoByPlayerID(InPlayerID)
    if not RoomInfo then
        print("(Wzp_Error)PlayerChatComponent:GetSpakerState  [RoomInfo=nil]")
        return false
    end
    return RoomInfo.bEnableSpeaker
end


--【【安全合规】禁止语音功能接口（AQ）验收不通过】https://www.tapd.cn/68880148/bugtrace/bugs/view/1168880148001022733 接入
--- 禁止语音功能接口回调
---@param Msg Struct 封禁信息
function PlayerChatComponent:OnBanVoice(Msg)
    print("(Wzp)PlayerChatComponent:OnBanVoice  [ObjectName]=",GetObjectName(self))
    GameLog.Dump(Msg,Msg)
    
    if not (Msg and Msg.BanType) then
        return
    end

    local LocalBanModel = MvcEntry:GetModel(BanModel)
    local BanTips = ""
    if Msg.BanType ~= Pb_Enum_BAN_TYPE.BAN_VOICE then
        --封禁语音
        local bLocalBanVoice = Msg.IsBan
        local bIsBanVoice = bLocalBanVoice and bLocalBanVoice or false
        self:UpdateBanVoiceState(bIsBanVoice)
        BanTips = LocalBanModel:GetBanTipsForType(Pb_Enum_BAN_TYPE.BAN_VOICE)
    elseif  Msg.BanType ~= Pb_Enum_BAN_TYPE.BAN_CHAT then
        --封禁文字聊天
        local bIsBanChat = Msg.IsBan
        self:UpdateBanTextChatState(bIsBanChat)
        BanTips = LocalBanModel:GetBanTipsForType(Pb_Enum_BAN_TYPE.BAN_CHAT)
    end


    if BanTips then
        print("(Wzp)PlayerChatComponent:OnBanVoice  [BanTips]=",BanTips)
        UIAlert.Show(BanTips,3,self)
    end

end

function PlayerChatComponent:ShowBanChatTips()
     local BanTip = self:GetBanChatTips()
     UIAlert.Show(BanTip,3,self)
end

function PlayerChatComponent:GetBanChatTips()
    local LocalBanModel = MvcEntry:GetModel(BanModel)
    return LocalBanModel:GetBanTipsForType(Pb_Enum_BAN_TYPE.BAN_CHAT)
end

function PlayerChatComponent:GetBanVoiceTips()
    local LocalBanModel = MvcEntry:GetModel(BanModel)
    return LocalBanModel:GetBanTipsForType(Pb_Enum_BAN_TYPE.BAN_VOICE)
end


--- 获取封禁语音聊天状态
function PlayerChatComponent:GetBanVoiceState()
    return self.IsBanVoice
end

function PlayerChatComponent:RegetBanVoiceState()
    local LocalBanModel = MvcEntry:GetModel(BanModel)
    if not LocalBanModel then 
        print("(Wzp_Error)PlayerChatComponent:InitBanVoice Faild! [LocalBanModel]=",LocalBanModel)
        return
    end
    local BanVoice = LocalBanModel:IsBanningForType(Pb_Enum_BAN_TYPE.BAN_VOICE) --可能返回nil
    print("PlayerChatComponent:RegetBanVoiceState [BanVoice]=",BanVoice)
    local bBanVoice = BanVoice and BanVoice or false
    print("PlayerChatComponent:RegetBanVoiceState [BanVoice]=",bBanVoice)
    return bBanVoice
end

function PlayerChatComponent:UpdateBanVoiceState(bBanVoice)
    print("(Wzp)PlayerChatComponent:UpdateBanVoiceState [bBanVoice]=",bBanVoice)
    if bBanVoice then
        self:SetVoiceMicMode(UE.EMicMode.Close)
        self:SetSpeakerMode(UE.ESpeakerMode.Close)
        self:LeaveTeamRoom()
        self:LeaveGameRangeRoom()
    end
    self.IsBanVoice = bBanVoice
end

function PlayerChatComponent:UpdateBanTextChatState(bBanChat)
    print("(Wzp)PlayerChatComponent:UpdateBanTextChatState [bBanChat]=",bBanChat)
    self.BanTextChat = bBanChat
end

--- 获取封禁文字聊天状态
function PlayerChatComponent:GetBanChatState()
    return self.BanTextChat
end

function PlayerChatComponent:PressVoiceModeChat(IsPress)
    print("(Wzp)PlayerChatComponent:PressVoiceModeChat  [ObjectName]=",GetObjectName(self),",[IsPress]=",IsPress)
    self.IsPressVoiceChatNotify:Broadcast(IsPress)
    self:OnGVoiceSDKOnMicState(IsPress and 1 or 0)
end

return PlayerChatComponent
