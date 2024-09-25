--[[
    聊天协议处理模块
]]

require("Client.Modules.Chat.ChatModel")
require("Client.Modules.Chat.ChatEmojiModel")
local class_name = "ChatCtrl"
---@class ChatCtrl : UserGameController
ChatCtrl = ChatCtrl or BaseClass(UserGameController,class_name)


function ChatCtrl:__init()
    CWaring("==ChatCtrl init")
end

function ChatCtrl:Initialize()
    ---@type ChatModel
    self.ChatModel = MvcEntry:GetModel(ChatModel)
    self.ChatEmojiModel = MvcEntry:GetModel(ChatEmojiModel)
    self.ChatSync_Delegate = {}
    self.ClearChatMsg_Delegate = {}
end

--[[
    玩家登入
]]
function ChatCtrl:OnLogin(data)
    CWaring("ChatCtrl OnLogin")
end


function ChatCtrl:AddMsgListenersUser()
    self.ProtoList = {
    	{MsgName = Pb_Message.ChatRsp,	Func = self.ChatRsp_Func },
		{MsgName = Pb_Message.ChatSync,	Func = self.ChatSync_Func },
		{MsgName = Pb_Message.ChatMergeSync,	Func = self.ChatMergeSync_Func },
		{MsgName = Pb_Message.ChatPrivateOffMsgSync,	Func = self.ChatPrivateOffMsgSync_Func },
		{MsgName = Pb_Message.ChatTipsSync,	Func = self.ChatTipsSync_Func },
		{MsgName = Pb_Message.ClearPlayerChatSync,	Func = self.ClearPlayerChatSync_Func },
        {MsgName = Pb_Message.ClientChgLangTypRsp,	Func = self.ClientChgLangTypRsp_Func },
    }

    self.MsgList = {
		{Model = DepotModel,  	MsgName = DepotModel.ON_DEPOT_DATA_INITED,      Func = self.OnDepotInited},
		{Model = DepotModel,  	MsgName = ListModel.ON_UPDATED,      Func = self.OnDepotUpdated},
		{Model = BanModel,  	MsgName = BanModel.ON_BAN_STATE_CHANGED,      Func = self.OnBanStateChange},

        {Model = LocalizationModel,  	MsgName = LocalizationModel.ON_CURRENT_LANGUAGE_CHANGE,      Func = self.ON_CURRENT_LANGUAGE_CHANGE_Func},
    }
end

-- 聊天回包
function ChatCtrl:ChatRsp_Func(Msg)
    print("ChatCtrl >> ChatRsp_Func")
    self.ChatModel:SetSendCDTime(Msg.ChatMsg.ChatType,Msg.CDTime)
    if Msg.MsgStatus == Pb_Enum_MSG_STATUS.CHAT_PASS or Msg.MsgStatus == Pb_Enum_MSG_STATUS.CHAT_SELF then
        -- 仅自己可见的消息也要显示消息内容
        Msg.ChatMsg.MsgStatus = Msg.MsgStatus
        -- CD处理
        if Msg.ChatMsg.ChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
            Msg.ChatMsg.ReceiverId = Msg.ReceiverId
        end

        if Msg.ChatMsg.ChatType == Pb_Enum_CHAT_TYPE.DS_CHAT then
            print("ChatCtrl >> ChatRsp_Func >  Msg.ChatMsg.ChatType == Pb_Enum_CHAT_TYPE.DS_CHAT")
            --局内
            self:UseChatSyncDelegate(Msg)
        else
            --大厅
            self.ChatModel:OnReceiveChatMsg(Msg.ChatMsg,true,true)
        end

        if Msg.MsgStatus == Pb_Enum_MSG_STATUS.CHAT_PASS then
            self.ChatModel:DispatchType(ChatModel.ON_SEND_SUCCESS)
        else
            self.ChatModel:DispatchType(ChatModel.ON_SEND_FAILED,Msg.MsgStatus)
        end
    else
        -- 发送失败
        self.ChatModel:DispatchType(ChatModel.ON_SEND_FAILED,Msg.MsgStatus)
    end
end

-- 聊天消息单条推送
function ChatCtrl:ChatSync_Func(Msg)
    print("ChatCtrl:ChatSync_Func")

    print("ChatCtrl:ChatSync_Func  Msg.ChatMsg.ChatType=",Msg.ChatMsg.ChatType,"Msg.ChatMsg.ChatType(Type)=",type(Msg.ChatMsg.ChatType))
    if Msg.ChatMsg.ChatType == Pb_Enum_CHAT_TYPE.DS_CHAT then
        print("ChatCtrl:Msg.ChatMsg.ChatType == Pb_Enum_CHAT_TYPE.DS_CHAT")
        --走局内
        self:UseChatSyncDelegate(Msg)
        return
    end
    self.ChatModel:OnReceiveChatMsg(Msg.ChatMsg, false, true)
end

-- 聊天消息合并推送
function ChatCtrl:ChatMergeSync_Func(Msg)
    if Msg.ChatMsgList[1].PlayerId == MvcEntry:GetModel(UserModel):GetPlayerId() then
        -- 推送自己发送的消息不处理
        return
    end
    self:HandleMsgList(Msg.ChatMsgList)
    self.ChatModel:DispatchType(ChatModel.ON_RECEIVE_NEW_MSG_LIST,Msg.ChatMsgList[1].ChatType)
end

-- 聊天私聊离线消息合并推送
function ChatCtrl:ChatPrivateOffMsgSync_Func(Msg)
    self:HandleMsgList(Msg.ChatMsgList)
    -- 这个只在登录的时候会同步，无需派发事件通知
end

-- 处理消息列表
function ChatCtrl:HandleMsgList(MsgList)
    table.sort(MsgList,function(MsgA,MsgB)
        return MsgA.SendTime < MsgB.SendTime
    end)
    for i = 1, #MsgList do
        self.ChatModel:OnReceiveChatMsg(MsgList[i], false, false)
    end
end


--region 给局内聊天调用的lua委托
function ChatCtrl:UseChatSyncDelegate(Msg)
    print("[Wzp]ChatCtrl >> UseChatSyncDelegate ")
    for _, delegate in ipairs(self.ChatSync_Delegate) do
        delegate.Func(delegate.Obj,Msg)
    end
end

function ChatCtrl:UseClearChatMsgDelegate(PlayerID)
    print("[Wzp]ChatCtrl >> UseChatSyncDelegate ")
    for _, delegate in ipairs(self.ClearChatMsg_Delegate) do
        delegate.Func(delegate.Obj,PlayerID)
    end
end

function ChatCtrl:BindChatSyncDelegate(Context,Delegate)
    print("[Wzp]ChatCtrl >> BindChatSyncDelegate ")
    table.insert(self.ChatSync_Delegate,{Obj = Context,Func =Delegate })
end


function ChatCtrl:BindClearChatMsgDelegate(Context,Delegate)
    print("[Wzp]ChatCtrl >> BindClearChatMsgDelegate ")
    table.insert(self.ClearChatMsg_Delegate,{Obj = Context,Func =Delegate })
end

function ChatCtrl:UnBindClearChatMsgDelegate()
    print("[Wzp]ChatCtrl >> UnBindClearChatMsgDelegate ")
    --如果你的事件多次调用，那代表你没解绑
    self.ClearChatMsg_Delegate = {}
end

function ChatCtrl:UnBindChatSyncDelegate()
    print("[Wzp]ChatCtrl >> UnBindChatSyncDelegate ")
    --如果你的事件多次调用，那代表你没解绑
    self.ChatSync_Delegate = {}
end
--endregion 给局内聊天调用的lua委托

-- 系统消息推送
function ChatCtrl:ChatTipsSync_Func(Msg)
    self.ChatModel:OnReceiveSystemMsg(Msg)
end

-- 删除某个玩家的所有聊天信息
function ChatCtrl:ClearPlayerChatSync_Func(Msg)
    self.ChatModel:DeleteAllMsgForPlayerId(Msg.PlayerId)
    self:UseClearChatMsgDelegate(Msg.PlayerId)
end
--[[
    修改语言类型成功回调
]]
function ChatCtrl:ClientChgLangTypRsp_Func(Msg)
    --暂不需要特定逻辑处理
end
------------------------------------请求相关----------------------------

-- 聊天请求
function ChatCtrl:SendProto_ChatReq(ReceiverId,ChatInfo)
    local NextSendTime = self.ChatModel:GetNextTimeForSend(ChatInfo.ChatType)
    local LeftSeconds = math.ceil(NextSendTime - GetTimestamp())
    if LeftSeconds > 0 then
        UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Chat', "Lua_ChatCtrl_Itwillbesecondsbefor"),LeftSeconds))
        return
    end
    -- 未组队，在小队频道发消息，接收者为自己
    if ChatInfo.ChatType == Pb_Enum_CHAT_TYPE.TEAM_CHAT and not MvcEntry:GetModel(TeamModel):IsSelfInTeam() then
        ReceiverId = MvcEntry:GetModel(UserModel):GetPlayerId()
    end
    local Msg = {
        ReceiverId = ReceiverId,
        ChatInfo = ChatInfo
    }
    self:SendProto(Pb_Message.ChatReq,Msg)

    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:AddSendNetProtoLog(Pb_Message.ChatReq, nil, Pb_Message.ChatRsp)
end
--[[ 
    客户端上报修改语言类型请求
]]
function ChatCtrl:SendProto_ClientChgLangTypReq(LangType)
    local Msg = {
        LangType = LangType
    }
    self:SendProto(Pb_Message.ClientChgLangTypReq,Msg)
end

----------- 聊天表情相关 ---------------------

function ChatCtrl:OnDepotInited()
    self.ChatEmojiModel:UpdateShowList()
end

function ChatCtrl:OnDepotUpdated(ChangeMap)
    self.ChatEmojiModel:CheckEmojiUnlock(ChangeMap)
end

-- 设置表情图片
function ChatCtrl:SetEmojiImg(EmojiId,Img)
    local EmojiCfg = G_ConfigHelper:GetSingleItemById(Cfg_ChatEmojiCfg,EmojiId)
    if not EmojiCfg then
        CWaring("SetEmojiImg Error For Id = "..tostring(EmojiId))
        return
    end
    if EmojiCfg[Cfg_ChatEmojiCfg_P.IconPath] ~= "" then
        CommonUtil.SetBrushFromSoftObjectPath(Img, EmojiCfg[Cfg_ChatEmojiCfg_P.IconPath])
    elseif EmojiCfg[Cfg_ChatEmojiCfg_P.DynamicIconPath] ~= "" then
        CommonUtil.SetBrushFromSoftMaterialPath(Img, EmojiCfg[Cfg_ChatEmojiCfg_P.DynamicIconPath])
    end
end

----------- 收到封禁状态变化 ----------------
--[[
    local Param = {
        BanType = BanType,
        IsBan = LeftTime > 0
    }
]]
function ChatCtrl:OnBanStateChange(Param)
    if not Param or Param.BanType ~= Pb_Enum_BAN_TYPE.BAN_CHAT then
        return
    end
    local BanTime = MvcEntry:GetModel(BanModel):GetBanTimeForType(Pb_Enum_BAN_TYPE.BAN_CHAT)
    -- 现在给的禁言时间不分频道。兼容分频道接口，避免后续需求又需要
    local Map = {}    
    for ChatType = Pb_Enum_CHAT_TYPE.PRIVATE_CHAT, Pb_Enum_CHAT_TYPE.TEAM_CHAT do
        Map[ChatType] = BanTime
    end
    self.ChatModel:SyscExpireTimeMap(Map)
end

--[[
    语言文化发生改变时，需要同步到服务器
]]
function ChatCtrl:ON_CURRENT_LANGUAGE_CHANGE_Func()
    local LangType = self:GetModel(LocalizationModel):GetCurSelectLanguageServer()
    self:SendProto_ClientChgLangTypReq(LangType)
end
