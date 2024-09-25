--[[
    聊天数据模型
]]

local super = GameEventDispatcher;
local class_name = "ChatModel";

---@class ChatModel : GameEventDispatcher
---@field private super GameEventDispatcher
ChatModel = BaseClass(super, class_name)
ChatModel.ON_SEND_SUCCESS = "ON_SEND_SUCCESS" -- 发送成功
ChatModel.ON_SEND_FAILED = "ON_SEND_FAILED" -- 发送失败
ChatModel.ON_RECEIVE_NEW_MSG = "ON_RECEIVE_NEW_MSG" -- 收到新消息
ChatModel.ON_RECEIVE_NEW_MSG_LIST = "ON_RECEIVE_NEW_MSG_LIST" -- 收到多条新消息
ChatModel.ON_RECEIVE_HIGH_PRIORITY_MSG = "ON_RECEIVE_HIGH_PRIORITY_MSG" -- 收到更高优先级消息
ChatModel.ON_SELECT_CHANNEL_CHANGED = "ON_SELECT_CHANNEL_CHANGED" -- 改变选中的聊天频道
ChatModel.ON_SELECT_FRIEND_CHANGED = "ON_SELECT_FRIEND_CHANGED" -- 改变选中的聊天好友
ChatModel.ON_RECEIVE_TEAM_MEMBER_MSG = "ON_RECEIVE_TEAM_MEMBER_MSG" -- 收到队友的聊天消息
ChatModel.ON_OPEN_CHAT_MDT = "ON_OPEN_CHAT_MDT" -- 打开聊天界面
ChatModel.SAVE_CHAT_SEND_CONTENT = "SAVE_CHAT_SEND_CONTENT" -- 通知保存草稿
ChatModel.ON_DELETE_MSG = "ON_DELETE_MSG" -- 删除某个玩家的所有聊天信息

ChatModel.ON_UPDATE_CHAT_POSITION = "ON_UPDATE_CHAT_POSITION" -- 通知需要更新聊天框的位置

function ChatModel:__init()
    self:_dataInit()
end

function ChatModel:_dataInit()
    -- 玩家自己的Id
    self.PlayerId = nil 
    --  当前选中的聊天频道 默认世界
    self.CurChatType = Pb_Enum_CHAT_TYPE.WORLD_CHANNEL_CHAT 
    -- 参数配置列表
    self.ParamConfig = {}
    -- 配置的频道列表
    self.CfgChannelList= {}
    -- 优先级排序列表
    self.PriorityOrderList = {}
    -- 私聊消息列表
    self.PrivateChatMsgs = {}
    -- 私聊未读消息列表
    self.PrivateChatUnreadMsgs = {}
    -- 小队消息列表
    self.TeamChatMsgs = {}
    -- 世界消息列表
    self.WorldChatMsgs = {}
    -- 新增消息列表
    self.NewMsgList = {}
    -- 当前展示消息的优先级
    self.CurPriority = 0
    -- 聊天CD列表
    self.ChatCDTimeList = {}
    -- 聊天CD提示文字
    self.CDTipsStr = ""
    -- 聊天禁言提示文字
    self.ForbiddenTipsStr = ""
    -- 私聊接受者Id
    self.TargetReceiverId = 0
    -- 记录未发送的草稿
    self.SavedToSendContent = {}
    -- 最后一条展示的消息
    self.LastShowMsg = nil
    -- 是否已初始化配置
    self.IsInitChatParamConfig = false
    -- 当前输入框的位置
    self.CurChatInputPos = UE.FVector2D(0,0)
    -- 底部待滚动消息最大条数(每个优先级最多xx条)
    self.BottomNewMsgMaxCount = 20
end

function ChatModel:OnLogin()
    self:InitChatParamConfig()
end

--[[
    玩家登出时调用
]]
function ChatModel:OnLogout(data)
    ChatModel.super.OnLogout(self)
    self:_dataInit()
end

-------- 对外接口 -----------
-- 获取频道的消息列表
---@param PlayerId number 私聊需要传入PlayerId
function ChatModel:GetMsgList(ChatType,PlayerId)
    if ChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        if self.PrivateChatMsgs[PlayerId] then
            return self.PrivateChatMsgs[PlayerId]
        end
    elseif ChatType == Pb_Enum_CHAT_TYPE.WORLD_CHANNEL_CHAT then
        return self.WorldChatMsgs
    elseif ChatType == Pb_Enum_CHAT_TYPE.TEAM_CHAT then

        return self.TeamChatMsgs
    end
    return {}
end

-- 获取最新可展示的消息
function ChatModel:GetNewMsg()
    self:InitChatParamConfig()
    -- 按优先级排序取消息
    for _, PriorityInfo in ipairs(self.PriorityOrderList) do
        local Priority = PriorityInfo.Priority
        if self.NewMsgList[Priority] and #self.NewMsgList[Priority] > 0 then
            self.CurPriority = Priority
            local Msg = self.NewMsgList[Priority][1]
            table.remove(self.NewMsgList[Priority],1)        
            self.LastShowMsg = Msg
            return Msg
        end
    end
    return nil
end

-- 获取最后一条展示的信息
function ChatModel:GetLastShowMsg()
    return self.LastShowMsg
end

-- 检查是否有当前优先级下的新消息
function ChatModel:HaveCurPriorityNewMsg()
    return self.NewMsgList[self.CurPriority] and #self.NewMsgList[self.CurPriority] > 0 
end

-- 获取对应频道的配置
function ChatModel:GetChannelConfig(ChatType)
    self:InitChatParamConfig()
    if self.ParamConfig and self.ParamConfig[ChatType] then
        return self.ParamConfig[ChatType]
    end
    return nil
end

-- 获取对应频道的配置参数
function ChatModel:GetChatParam(ChatType,ParamKey)
    self:InitChatParamConfig()
    if self.ParamConfig and self.ParamConfig[ChatType] and self.ParamConfig[ChatType][ParamKey] then
        return self.ParamConfig[ChatType][ParamKey]
    end
    return nil
end

-- 设置当前选择的频道
function ChatModel:SetCurChatType(ChatType)
    self.CurChatType = ChatType
    self:DispatchType(ChatModel.ON_SELECT_CHANNEL_CHANGED)
end

-- 获取当前选择的频道
function ChatModel:GetCurChatType()
    -- if not table.isEmpty(self.PrivateChatUnreadMsgs) then
    --     -- 私聊有未读消息，优先切到私聊频道
    --     self.CurChatType = Pb_Enum_CHAT_TYPE.PRIVATE_CHAT
    -- end
    return self.CurChatType
end

-- 获取展示的频道列表
function ChatModel:GetShowChannelList()
    self:InitChatParamConfig()
    return self.CfgChannelList
end

-- 获取聊天下次可发言的时间（CDTime）
function ChatModel:GetNextTimeForSend(ChatType)
    if self.ChatCDTimeList[ChatType] then
        return self.ChatCDTimeList[ChatType]
    end
    return 0
end

-- 是否有未读私聊消息
function ChatModel:HaveUnreadMsgForPlayerId(PlayerId)
    if not (self.PrivateChatUnreadMsgs and self.PrivateChatUnreadMsgs[PlayerId]) then
        return false
    end
    return not table.isEmpty(self.PrivateChatUnreadMsgs[PlayerId])
end

-- 标记消息为已读
function ChatModel:SetMsgRead(Msg)
    if self.PrivateChatUnreadMsgs[Msg.PlayerId] and self.PrivateChatUnreadMsgs[Msg.PlayerId][Msg.SendTime] then
        self.PrivateChatUnreadMsgs[Msg.PlayerId][Msg.SendTime] = nil
    end
    if table.isEmpty(self.PrivateChatUnreadMsgs[Msg.PlayerId]) then
        self.PrivateChatUnreadMsgs[Msg.PlayerId] = nil
    end
end

-- 私聊设置接收者Id
function ChatModel:SetTargetFriendId(TargetReceiverId)
    local IsTargetChanged = TargetReceiverId ~= 0 and self.TargetReceiverId ~= TargetReceiverId
    self.TargetReceiverId = TargetReceiverId
    if IsTargetChanged then
        self:DispatchType(ChatModel.ON_SELECT_FRIEND_CHANGED)
    end
end

function ChatModel:GetTagetFriendId()
    return self.TargetReceiverId
end

----------------------------------------

--[[
    初始化聊天参数信息
]]
function ChatModel:InitChatParamConfig()
    if self.IsInitChatParamConfig then
        return
    end
    local ChatConfigs =  G_ConfigHelper:GetDict(Cfg_ChatParamCfg)
    for _,Cfg in pairs(ChatConfigs) do
        if Cfg[Cfg_ChatParamCfg_P.IconPath] ~= "" then
            local ChatType = Cfg[Cfg_ChatParamCfg_P.ChatType]
            self.ParamConfig[ChatType] = Cfg
            local ChannelInfo = {
                ChatType = ChatType,
                Name = Cfg[Cfg_ChatParamCfg_P.Name],
                Color = Cfg[Cfg_ChatParamCfg_P.FontHexColor],
                IconPath = Cfg[Cfg_ChatParamCfg_P.IconPath],
                ShowOrder = Cfg[Cfg_ChatParamCfg_P.ShowOrder],
            }
            self.CfgChannelList[#self.CfgChannelList + 1] = ChannelInfo
            local PriorityInfo = {
                ChatType = ChatType,
                Priority = Cfg[Cfg_ChatParamCfg_P.Priority],
            }
            self.PriorityOrderList[#self.PriorityOrderList + 1] = PriorityInfo
        end
    end
    -- 根据展示顺序，对频道排序
    table.sort(self.CfgChannelList,function (A,B)
        return A.ShowOrder < B.ShowOrder
    end)
    -- 对优先级排序
    table.sort(self.PriorityOrderList,function (A,B)
        return A.Priority > B.Priority
    end)
    self.IsInitChatParamConfig = true
end

-- 收到聊天消息
--- @param ChatMsg ChatMsgType 
--- @param IsSaveSelf boolean 回包和推送都会返回自己发送的信息，取回包的速度比较快
--- @param NeedDispatch boolean 是否需要派发事件通知
function ChatModel:OnReceiveChatMsg(ChatMsg,IsSaveSelf,NeedDispatch)
    if not ChatMsg then
        return
    end
    if not IsSaveSelf and ChatMsg.PlayerId == MvcEntry:GetModel(UserModel):GetPlayerId() then
        return
    end

    if ChatMsg.ChatType == Pb_Enum_CHAT_TYPE.DS_CHAT then
        print("ChatCtrl:Msg.ChatMsg.ChatType == Pb_Enum_CHAT_TYPE.DS_CHAT")
        --走局内
        return
    end

    self:HandMsgByType(ChatMsg,NeedDispatch)
end

-- 分类型处理聊天信息
--- @param ChatMsg ChatMsgType 
--- @param NeedDispatch boolean 是否需要派发事件通知
function ChatModel:HandMsgByType(ChatMsg,NeedDispatch)
    if not ChatMsg or not ChatMsg.Text then
        return
    end
    if not self.PlayerId then
        self.PlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    end
    ChatMsg.IsSelf = ChatMsg.PlayerId == self.PlayerId
    
    local ChatType = ChatMsg.ChatType
    if ChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        -- 私聊
        self:PushPrivateChatMsg(ChatMsg)
    elseif ChatType == Pb_Enum_CHAT_TYPE.WORLD_CHANNEL_CHAT then
        -- 世界频道聊天
        self:PushWorldChatMsg(ChatMsg)
    elseif ChatType == Pb_Enum_CHAT_TYPE.TEAM_CHAT then
        -- 组队聊天
        self:PushTeamChatMsg(ChatMsg)
    end
    local IsChatViewOpen = MvcEntry:GetModel(ViewModel):GetState(ViewConst.Chat)
    local IsInBattle = CommonUtil.IsInBattle()
    if IsChatViewOpen then
        -- 聊天界面打开期间，如果新收到的消息是正在展示的频道，不加入列表中
        -- 仅更新最后一条
        self.LastShowMsg = ChatMsg
    elseif(not IsInBattle or ChatType ~= Pb_Enum_CHAT_TYPE.WORLD_CHANNEL_CHAT) then
        -- 战斗中，底部滚动栏处理忽略世界频道消息
        self:PushNewMsg(ChatMsg)
    end
    if NeedDispatch then
        -- 从列表部分处理的，不需要每条都派发，等列表处理完再派发更新通知
        self:DispatchType(ChatModel.ON_RECEIVE_NEW_MSG,ChatMsg)
    end
end

-- 私聊
function ChatModel:PushPrivateChatMsg(ChatMsg)
    local PlayerId = ChatMsg.IsSelf and ChatMsg.ReceiverId or ChatMsg.PlayerId
    -- TODO 信息内容处理 暂只有文字无需处理
    self.PrivateChatMsgs[PlayerId] = self.PrivateChatMsgs[PlayerId] or {}
    self.PrivateChatMsgs[PlayerId][#self.PrivateChatMsgs[PlayerId] + 1] = ChatMsg
    if #self.PrivateChatMsgs[PlayerId] > self:GetChatParam(ChatMsg.ChatType,Cfg_ChatParamCfg_P.MaxMsgCount) then
        local SendTime = self.PrivateChatMsgs[PlayerId][1].SendTime
        if self.PrivateChatUnreadMsgs[PlayerId] then
            self.PrivateChatUnreadMsgs[PlayerId][SendTime] = nil
        end
        table.remove(self.PrivateChatMsgs[PlayerId], 1)
    end

    -- 收到的都加入未读列表
    if not ChatMsg.IsSelf then
        self.PrivateChatUnreadMsgs[PlayerId] = self.PrivateChatUnreadMsgs[PlayerId] or {}
        self.PrivateChatUnreadMsgs[PlayerId][ChatMsg.SendTime] = ChatMsg
    end
end

-- 组队聊天
function ChatModel:PushTeamChatMsg(ChatMsg)
-- TODO 策划需求这部分暂不需处理
--    local TeamId = ChatMsg.TeamId
--    local MyTeamId = MvcEntry:GetModel(TeamModel):GetTeamId()
--    if TeamId ~= MyTeamId then
--         if MyTeamId == 0 then
--             -- 退队了，清空消息
--             self.TeamChatMsgs = {}
--         end
--         return
--    end
--    -- 检测是否有前队伍的消息
--    if #self.TeamChatMsgs > 0 then
--         local MsgTeamId = self.TeamChatMsgs[1].TeamId
--         if MsgTeamId ~= MyTeamId then
--             self.TeamChatMsgs = {}
--         end
--    end
   self.TeamChatMsgs[#self.TeamChatMsgs + 1] = ChatMsg
    if not ChatMsg.IsSystem then
        self:DispatchType(ChatModel.ON_RECEIVE_TEAM_MEMBER_MSG, ChatMsg.PlayerId)
    end
    if #self.TeamChatMsgs > self:GetChatParam(ChatMsg.ChatType,Cfg_ChatParamCfg_P.MaxMsgCount) then
        table.remove(self.TeamChatMsgs, 1)
    end
end

-- 世界频道聊天
function ChatModel:PushWorldChatMsg(ChatMsg)
    self.WorldChatMsgs[#self.WorldChatMsgs + 1] = ChatMsg
    if #self.WorldChatMsgs > self:GetChatParam(ChatMsg.ChatType,Cfg_ChatParamCfg_P.MaxMsgCount) then
        table.remove(self.WorldChatMsgs, 1)
    end
end

-- 处理新消息 （底栏聊天信息展示）
function ChatModel:PushNewMsg(ChatMsg)
    self:InitChatParamConfig()
    local ChatType = ChatMsg.ChatType
    local ChatConfig = self.ParamConfig[ChatType]
    if not ChatConfig then
        CError("PushNewMsg Can't Found Config For Type = " ..tostring(ChatType))
        print_trackback()
        return
    end
    local Priority = ChatConfig[Cfg_ChatParamCfg_P.Priority]
    self.NewMsgList[Priority] = self.NewMsgList[Priority] or {}
    table.insert(self.NewMsgList[Priority],ChatMsg)
    if #self.NewMsgList[Priority] > self.BottomNewMsgMaxCount then
        table.remove(self.NewMsgList[Priority],1)
    end
    if Priority > self.CurPriority then
        -- 新消息优先级更高，通知打断当前信息展示
        self:DispatchType(ChatModel.ON_RECEIVE_HIGH_PRIORITY_MSG)
    end
end

-- 记录聊天CD
function ChatModel:SetSendCDTime(ChatType,CDTime)
    self.ChatCDTimeList = self.ChatCDTimeList or {}
    self.ChatCDTimeList[ChatType] = GetTimestamp() + CDTime
end

function ChatModel:GetSendCDErrorCodeTips()
    if not self.CDTipsStr or self.CDTipsStr == "" then
        local MsgObject = {
            ErrCode = ErrorCode.ChatNeedCD.ID,
            ErrCmd = "",
            ErrMsg = "",
        }
        self.CDTipsStr = MvcEntry:GetCtrl(ErrorCtrl):GetErrorTipByMsg(MsgObject)
    end
    return self.CDTipsStr
end

function ChatModel:GetForbiddenErrorCodeTips()
    if not self.ForbiddenTipsStr or self.ForbiddenTipsStr == "" then
        local MsgObject = {
            ErrCode = ErrorCode.ChatForbidden.ID,
            ErrCmd = "",
            ErrMsg = "",
        }
        self.ForbiddenTipsStr = MvcEntry:GetCtrl(ErrorCtrl):GetErrorTipByMsg(MsgObject)
    end
    return self.ForbiddenTipsStr
end

-- 获取未发送的草稿
function ChatModel:GetSavedSendContent(ChatType)
    if not ChatType then
        return ""
    end
    if ChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        local TargetId = self.TargetReceiverId
        if not TargetId or TargetId == 0 then
            return ""
        end
        self.SavedToSendContent[ChatType] = self.SavedToSendContent[ChatType] or {}
        return self.SavedToSendContent[ChatType][TargetId] or ""
    else
        return self.SavedToSendContent[ChatType] or ""
    end
end

-- 记录未发送的草稿
function ChatModel:SaveSendContent(ChatType,Content)
    if not ChatType then
        return
    end
    if ChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        local TargetId = self.TargetReceiverId
        if not TargetId or TargetId == 0 then
            return
        end
        self.SavedToSendContent[ChatType] = self.SavedToSendContent[ChatType] or {}
        self.SavedToSendContent[ChatType][TargetId] = Content
    else
        self.SavedToSendContent[ChatType] = Content
    end
end

-- 清空缓存的未发送的草稿
function ChatModel:ClearSavedSendContent(ChatType)
    if not ChatType then
        return
    end
    if ChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
        local TargetId = self.TargetReceiverId
        if not TargetId or TargetId == 0 then
            return
        end
        self.SavedToSendContent[ChatType] = self.SavedToSendContent[ChatType] or {}
        self.SavedToSendContent[ChatType][TargetId] = ""
    else
        self.SavedToSendContent[ChatType] = ""
    end
end

-- 同步禁言时间Map
function ChatModel:SyscExpireTimeMap(Map)
    for ChatType, Time in pairs(Map) do
        self:SyscExpireTime(ChatType,Time)
    end
end

-- 同步禁言时间
function ChatModel:SyscExpireTime(ChatType,Time)
    self.ExpireTime = self.ExpireTime or {}
    if Time > 0 and Time > GetTimestamp() then
        self.ExpireTime[ChatType] = Time
    else
        self.ExpireTime[ChatType] = 0
    end
end

-- 获取禁言解禁时间
function ChatModel:GetExpireTime(ChatType)
    self.ExpireTime = self.ExpireTime or {}
    return self.ExpireTime[ChatType] or 0
end


-- 收到系统消息
function ChatModel:OnReceiveSystemMsg(Msg)
    local TipsCfg = G_ConfigHelper:GetSingleItemById(Cfg_ChatTipCfg,Msg.TipsId)
    if not TipsCfg then
        CWaring("OnReceiveSystemMsg Error For Id = "..Msg.TipsId)
        return
    end
    local ChatMsg = {}
    ChatMsg.ChatType = TipsCfg[Cfg_ChatTipCfg_P.ChatType]
    ChatMsg.IsSystem = true
    ChatMsg.SendTime = GetTimestamp()
    local TipsArgsList = ChatMsg.ChatType == Pb_Enum_CHAT_TYPE.TEAM_CHAT and self:GetChatTargetName(Msg.TipsArgsList) or Msg.TipsArgsList
    ChatMsg.Text = StringUtil.Format(TipsCfg[Cfg_ChatTipCfg_P.Des],table.unpack(TipsArgsList))
    self:HandMsgByType(ChatMsg,true)
end


function ChatModel:GetChatTargetName(TipsArgsList)
    local result_arr = {}
    for _, str in ipairs(TipsArgsList) do
        local substring = string.match(str, "(.-)#")
        if substring then
            table.insert(result_arr, substring)
        else
            table.insert(result_arr, str)
        end
    end
    return result_arr
end

-- 删除该玩家id的所有消息
function ChatModel:DeleteAllMsgForPlayerId(PlayerId)
    -- 删除世界聊天
    self:DeleteMsgForPlayerId(self.WorldChatMsgs,PlayerId)
    -- 删除组队聊天
    self:DeleteMsgForPlayerId(self.TeamChatMsgs,PlayerId)
    -- 删除私聊相关信息
    self:DeletePrivateChatMsgForPlayerID(PlayerId,false)
    -- 删除新消息
    for Priority,_ in pairs(self.NewMsgList) do
        self:DeleteMsgForPlayerId(self.NewMsgList[Priority],PlayerId)
    end
    -- 删除最后一条展示消息
    if self.LastShowMsg and self.LastShowMsg.PlayerId == PlayerId then
        self.LastShowMsg = nil
        self.CurShowMsgType = Pb_Enum_CHAT_TYPE.WORLD_CHANNEL_CHAT
    end
    self:DispatchType(ChatModel.ON_DELETE_MSG)
end

function ChatModel:DeleteMsgForPlayerId(List,PlayerId,ChatType)
    List = List or {}
    local Length = #List
    for Index = Length,1,-1 do
        local Msg = List[Index]
        if Msg.PlayerId == PlayerId and (not ChatType or ChatType == Msg.ChatType) then
            table.remove(List,Index)
        end
    end
end

-- 删除跟PlayerId相关的私聊信息
-- IsDeleteNewMsg 是否处理NewMsgList和LastShowMsg
function ChatModel:DeletePrivateChatMsgForPlayerID(PlayerId, IsDeleteNewMsg)
    -- 删除私聊
    self.PrivateChatMsgs[PlayerId] = self.PrivateChatMsgs[PlayerId] or {}
    for FriendPlayerId,List in pairs(self.PrivateChatMsgs) do
        self:DeleteMsgForPlayerId(self.PrivateChatMsgs[FriendPlayerId],PlayerId)
    end
    -- 删除私聊未读信息
    self.PrivateChatUnreadMsgs[PlayerId] = self.PrivateChatUnreadMsgs[PlayerId] or {}
    for SendTime,Msg in pairs(self.PrivateChatUnreadMsgs[PlayerId]) do
        if Msg.PlayerId == PlayerId then
            SendTime = tonumber(SendTime)
            self.PrivateChatUnreadMsgs[PlayerId][SendTime] = nil
        end
    end
    if IsDeleteNewMsg then
        -- 删除新消息
        for Priority,_ in pairs(self.NewMsgList) do
            self:DeleteMsgForPlayerId(self.NewMsgList[Priority],PlayerId,Pb_Enum_CHAT_TYPE.PRIVATE_CHAT)
        end
        -- 删除最后一条展示消息
        if self.LastShowMsg and (self.LastShowMsg.PlayerId == PlayerId or self.LastShowMsg.ReceiverId == PlayerId) and self.LastShowMsg.ChatType == Pb_Enum_CHAT_TYPE.PRIVATE_CHAT then
            self.LastShowMsg = nil
            self.CurShowMsgType = Pb_Enum_CHAT_TYPE.WORLD_CHANNEL_CHAT
        end
        self:DispatchType(ChatModel.ON_DELETE_MSG)
    end
end

-- 设置当前输入框的位置
function ChatModel:SetCurChatInputPos(CurChatInputPos)
    self.CurChatInputPos = CurChatInputPos
end

-- 获取当前输入框的位置
function ChatModel:GetCurChatInputPos()
    return self.CurChatInputPos
end