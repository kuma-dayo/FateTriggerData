require("Client.Modules.Friend.FriendConst")
require("Client.Modules.Friend.FriendModel")
require("Client.Modules.Friend.FriendApplyModel")
require("Client.Modules.Friend.FriendBlackListModel")
require("Client.Modules.Friend.FriendOpLogModel")

--[[
    好友协议处理模块
]]
local class_name = "FriendCtrl"
---@class FriendCtrl : UserGameController
FriendCtrl = FriendCtrl or BaseClass(UserGameController,class_name)


function FriendCtrl:__init()
    CWaring("==FriendCtrl init")
    self.PersonalInfoModel = nil
    ---@type FriendModel
    self.ModelFriend = nil
    ---@type FriendApplyModel
    self.ModelFriendApply = nil
    ---@type FriendBlackListModel
    self.ModelFriendBlack = nil
    ---@type FriendOpLogModel
    self.ModelOpLog = nil
end

function FriendCtrl:Initialize()
    self.PersonalInfoModel = self:GetModel(PersonalInfoModel)
    self.ModelFriend = self:GetModel(FriendModel)
    self.ModelFriendApply = self:GetModel(FriendApplyModel)
    self.ModelFriendBlack = self:GetModel(FriendBlackListModel)
    self.ModelOpLog = self:GetModel(FriendOpLogModel)
end

--[[
    玩家登入
]]
function FriendCtrl:OnLogin(data)
    CWaring("FriendCtrl OnLogin")
    -- 请求好友列表及好友申请列表
    self:SendProto_FriendListReq()
end


function FriendCtrl:AddMsgListenersUser()
    self.ProtoList = {
        {MsgName = Pb_Message.FriendListRsp,	Func = self.FriendListRsp_Func },
        {MsgName = Pb_Message.FriendBaseInfoChangeSyn,	Func = self.FriendBaseInfoChangeSyn_Func },
        {MsgName = Pb_Message.AddFriendApplyListSyn,	Func = self.AddFriendApplyListSyn_Func },
        {MsgName = Pb_Message.AddFriendOperateRsp,	Func = self.AddFriendOperateRsp_Func },
        {MsgName = Pb_Message.FriendDeleteRsp,	Func = self.FriendDeleteRsp_Func },
        {MsgName = Pb_Message.FriendPlayerDataRsp,	Func = self.FriendPlayerDataRsp_Func },
        {MsgName = Pb_Message.FriendSetStarRsp,	Func = self.FriendSetStarRsp_Func },
        {MsgName = Pb_Message.FriendSetPlayerBlackRsp,	Func = self.FriendSetPlayerBlackRsp_Func },
        {MsgName = Pb_Message.FriendGetOpLogRsp,	Func = self.FriendGetOpLogRsp_Func },
        {MsgName = Pb_Message.PlayerTimeTogetherRsp,	Func = self.PlayerTimeTogetherRsp_Func },
        {MsgName = Pb_Message.FriendsInRecentGamesRsp,	Func = self.FriendsInRecentGamesRsp_Func },
        {MsgName = Pb_Message.PlayerLookUpLastOnlineTimeRsp,	Func = self.PlayerLookUpLastOnlineTimeRsp_Func },
        {MsgName = Pb_Message.PlayerGiveFriendItemGiftRsp,	Func = self.PlayerGiveFriendItemGiftRsp_Func },
        {MsgName = Pb_Message.PlayerIsFriendRsp,	Func = self.PlayerIsFriendRsp_Func },
    }
end

--[[
    好友列表返回信息,包含好友列表，申请列表信息数据
]]
function FriendCtrl:FriendListRsp_Func(Msg)
    self.ModelFriend:SetDataList(Msg.FriendInfoList)
    self.ModelFriendApply:SetDataList(Msg.AddFriendApplyList,true)
    self.ModelFriendBlack:SetDataList(Msg.BlackList,true)
    self.PersonalInfoModel:SetPlayerHeadIdForList(Msg.AddFriendApplyList)
    self:UpdatePlayerDetailInfoData()
    self.ModelFriend:DispatchType(FriendModel.ON_FRIEND_LIST_UPDATED)
    self.ModelFriend:SetInited(true)
end

--[[
    好友基础数据变化列表（通过角色ID找到好友列表中对应的好友，覆盖节点信息）
]]
function FriendCtrl:FriendBaseInfoChangeSyn_Func(Msg)
    -- print_r(Msg)
    local ChangeType = Msg.ChangeType
    if ChangeType == Pb_Enum_BASE_INFO_CHANGE_TYPE.CHANGE_STATUS then
        -- 仅更新玩家状态
        MvcEntry:GetModel(TeamModel):OnFriendStateUpdated(Msg.FriendInfoList)
        self.ModelFriend:UpdatePlayerState(Msg.FriendInfoList)
    elseif ChangeType == Pb_Enum_BASE_INFO_CHANGE_TYPE.CHANGE_INTIMACY then
        -- 仅更新亲密度
        self.ModelFriend:UpdateIntimacy(Msg.FriendInfoList)
    elseif ChangeType == Pb_Enum_BASE_INFO_CHANGE_TYPE.CHANGE_TEAM_DATA then
        -- 仅更新共同游戏时长和次数
        self.ModelFriend:UpdateCooperationData(Msg.FriendInfoList)
    else
        local _,UpdateMap = self.ModelFriend:UpdateDatas(Msg.FriendInfoList)
        if UpdateMap and UpdateMap["AddMap"] and #UpdateMap["AddMap"] > 0 then
            self.ModelFriend:ShowAddFriendTips(UpdateMap["AddMap"])
            self.ModelFriend:DispatchType(FriendModel.ON_ADD_FRIEND,UpdateMap["AddMap"])
            self.ModelFriend:RecordNewFriendIds(UpdateMap["AddMap"])
        end
        self:UpdatePlayerDetailInfoData()
    end
end

--[[
    当有玩家申请加入好友，同步申请信息到客户端，增量
]]
function FriendCtrl:AddFriendApplyListSyn_Func(Msg)
    self.PersonalInfoModel:SetPlayerHeadIdForList(Msg.AddFriendApplyList)
    self.ModelFriendApply:UpdateDatas(Msg.AddFriendApplyList)
end

--[[
    删除好友，需要同步清除本地好友数据缓存
]]
function FriendCtrl:FriendDeleteRsp_Func(Msg)
    self.ModelFriend:DeleteData(Msg.PlayerId)
    self.ModelOpLog:DeleteLog(Msg.PlayerId)
    self.ModelFriend:ShowDeleteFriendTips(Msg.PlayerId)
    MvcEntry:GetModel(ChatModel):DeletePrivateChatMsgForPlayerID(Msg.PlayerId,true)
    -- 删除好友要清除对应的聊天红点
    MvcEntry:GetCtrl(RedDotCtrl):Interact(RedDotModel.Const_SysRedDotKey[Pb_Enum_RED_DOT_SYS.RED_DOT_CHAT_FRIEND], Msg.PlayerId)
end

--[[
    同意或者拒绝玩家，需要清除好友请求缓存
]]
function FriendCtrl:AddFriendOperateRsp_Func(Msg)
    local Data = self.ModelFriendApply:GetData(Msg.ReqPlayerId)
    if Data then
        self.ModelFriendApply:ShowOperateApplyTips({PlayerId = Data.PlayerId, PlayerName = Data.PlayerName})
    end
    self.ModelFriendApply:DispatchType(FriendApplyModel.ON_OPERATE_APPLY,Msg.ReqPlayerId)
    self.ModelFriendApply:DeleteData(Msg.ReqPlayerId)
end

--- 更新好友项展示列表数据
function FriendCtrl:UpdatePlayerDetailInfoData()
    local PlayerList = self.ModelFriend:GetDataMapKeys()
    -- CError("===============UpdatePlayerDetailInfoData".. table.tostring(PlayerList))
    MvcEntry:GetCtrl(PersonalInfoCtrl):SendGetPlayerListBaseInfoReq(PlayerList)
end

-- 设置星标返回
function FriendCtrl:FriendSetStarRsp_Func(Msg)
    self.ModelFriend:UpdateFriendStarFlag(Msg.TargetPlayerId, Msg.StarFlag)
    UIAlert.Show(Msg.StarFlag and G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendCtrl_Starhasbeenadded") or G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendCtrl_Thestarsignhasbeenca"))
end

-- 操作黑名单返回
function FriendCtrl:FriendSetPlayerBlackRsp_Func(Msg)
    if Msg.BlackFlag then
        -- 添加黑名单，需把数据加到黑名单列表
        local FriendBlackNode = {
            PlayerId = Msg.TargetPlayerId,
            OpTime = GetTimestamp()
        }
        self.ModelFriendBlack:AppendData(FriendBlackNode)
    else
        -- 从黑名单列表移除对应数据
        self.ModelFriendBlack:DeleteData(Msg.TargetPlayerId)
        UIAlert.Show(self.IsAddFriendFromBlackList and G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendCtrl_Removedfromtheblackl") or G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendCtrl_Movedoutoftheblackli"))
    end
    self.ModelFriendBlack:DispatchType(FriendBlackListModel.ON_BLACKLIST_CHANGED)
end

-- 请求好友操作日志返回
function FriendCtrl:FriendGetOpLogRsp_Func(Msg)
    self.ModelOpLog:SaveOpLogList(Msg)
end

-- 获取好友共同游玩时长
function FriendCtrl:PlayerTimeTogetherRsp_Func(Msg)
    self.ModelFriend:DispatchType(FriendModel.ON_GET_PLAY_TOGETHER_TIME,Msg)
end

-- 获取最近30场共同游玩的好友列表
function FriendCtrl:FriendsInRecentGamesRsp_Func(Msg)
    self.ModelFriend:SaveInRecentGameIdList(Msg.PlayerIdList)
    self.ModelFriend:DispatchType(FriendModel.ON_GET_IN_RECENT_GAMES_PLAYERIDS)
end

-- 查询某些玩家的最晚在线时间
function FriendCtrl:PlayerLookUpLastOnlineTimeRsp_Func(Msg)
    self.ModelFriend:SavePlayersLastOnlineTime(Msg.PlayerIdList)
    self.ModelFriend:DispatchType(FriendModel.ON_GET_LAST_ONLINE_TIME)
end

-- 给好友赠送物品增加亲密度
function FriendCtrl:PlayerGiveFriendItemGiftRsp_Func(Msg)
    self.ModelFriend:DispatchType(FriendModel.ON_USE_INTIMACY_ITEM_SUCCESS,Msg)
end
------------------------------------请求相关----------------------------
--[[
    请求好友列表及好友申请列表
]]
function FriendCtrl:SendProto_FriendListReq(Msg)
    Msg = Msg or {}
    self:SendProto(Pb_Message.FriendListReq,Msg)
end
--[[
    请求添加好友 
    PlayerData -- 玩家名称或角色ID
]]
function FriendCtrl:SendProto_AddFriendReq(PlayerId)
    if MvcEntry:GetModel(FriendBlackListModel):GetData(PlayerId) then
        -- 在黑名单中，不给添加
        local MsgObject = {
            ErrCode = ErrorCode.FriendAccountNotFound.ID,
            ErrCmd = "",
            ErrMsg = "",
        }
        MvcEntry:GetCtrl(ErrorCtrl):PopTipsAction(MsgObject, ErrorCtrl.TIP_TYPE.ERROR_CONFIG)
        return
    end
    if MvcEntry:GetModel(FriendApplyModel):IsInApplyList(PlayerId) then
        -- 在申请列表中，转为同意申请
        self:SendProto_AddFriendOperateReq(PlayerId,true)
        return
    end
    local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)

    local Msg = {
        PlayerData = PlayerId,
        -- AddType = self.ModelFriend:GetAddFriendModule(PlayerId)
        AddType = EventTrackingModel:GetFriendAddSource(PlayerId)   -- 修改为调用埋点使用的途径
    }
    self:SendProto(Pb_Message.AddFriendReq,Msg,Pb_Message.AddFriendRsp)
    
    EventTrackingModel:SetFriendAddSourceByTeam(PlayerId)
    local EventData = {
        action = EventTrackingModel.FRIEND_FLOW_ACTION.APPLY_FOR_FRIEND,
        playerId = PlayerId,
        bIsClear = true
    }
    EventTrackingModel:DispatchType(EventTrackingModel.ON_FRIEND_FLOW_EVENTTRACKING, EventData)
end
--[[
    同意或者拒绝好友申请
]]
function FriendCtrl:SendProto_AddFriendOperateReq(ReqPlayerId,Choice)
    if Choice then
        if self.ModelFriend:CheckIsFriendListFull() then
            -- 好友已满
            return
        end
        if self.ModelFriend:IsFriend(ReqPlayerId) then
            UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendCtrl_Theotherpartyisalrea"))
            self.ModelFriendApply:DeleteData(ReqPlayerId)   -- 清除本地申请列表缓存
            return
        end
    end
    self.ModelFriendApply:SaveApplyOperateInfo({PlayerId = ReqPlayerId, Choice = Choice})
    local Msg = {
        ReqPlayerId = ReqPlayerId,
        Choice = Choice,
    }
    self:SendProto(Pb_Message.AddFriendOperateReq,Msg,Pb_Message.AddFriendOperateRsp)

    local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
    local EventAction = Choice and EventTrackingModel.FRIEND_FLOW_ACTION.THROUGH_FRIENDS or EventTrackingModel.FRIEND_FLOW_ACTION.REFUSAL_OF_APPLICATION
    local EventData = {
        action = EventAction,
        playerId = ReqPlayerId
    }
    EventTrackingModel:DispatchType(EventTrackingModel.ON_FRIEND_FLOW_EVENTTRACKING, EventData)
end
--[[
    请求删除好友
]]
function FriendCtrl:SendProto_FriendDeleteReq(PlayerId)
    self.ModelFriend:SaveDeletePlayerInfo(PlayerId)
    local Msg = {
        PlayerId = PlayerId
    }
    self:SendProto(Pb_Message.FriendDeleteReq,Msg,Pb_Message.FriendDeleteRsp)

    local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
    local EventData = {
        action = EventTrackingModel.FRIEND_FLOW_ACTION.DELETE_FRIEND,
        playerId = PlayerId
    }
    EventTrackingModel:DispatchType(EventTrackingModel.ON_FRIEND_FLOW_EVENTTRACKING, EventData)
end

--[[
    通过角色名字或者角色Id，查询角色Id
]]
function FriendCtrl:SendFriendPlayerDataReq(PlayerData)
    local Msg = {
        PlayerData = PlayerData
    }
    self:SendProto(Pb_Message.FriendPlayerDataReq,Msg,Pb_Message.FriendPlayerDataRsp)

    local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
    local EventData = {
        action = EventTrackingModel.FRIEND_FLOW_ACTION.APPLY_FOR_FRIEND,
        playerId = PlayerData
    }
    EventTrackingModel:DispatchType(EventTrackingModel.ON_FRIEND_FLOW_EVENTTRACKING, EventData)
end

function FriendCtrl:FriendPlayerDataRsp_Func(Msg)
    self.ModelFriend:DispatchType(FriendModel.ON_QUERY_PLAYERID, Msg.PlayerId)
end

--[[
    请求设置/取消星标
]]
function FriendCtrl:SendFriendSetStarReq(TargetPlayerId,StarFlag)
    local Msg = {
        TargetPlayerId = TargetPlayerId,
        StarFlag = StarFlag,
    }
    self:SendProto(Pb_Message.FriendSetStarReq,Msg, Pb_Message.FriendSetStarRsp)
end

--[[
    请求操作黑名单
]]
function FriendCtrl:SendFriendSetPlayerBlackReq(TargetPlayerId,BlackFlag,AddFriend)
    if BlackFlag and self.ModelFriendBlack:GetLength() >= CommonUtil.GetParameterConfig(ParameterConfig.FriendBlackMaxCount) then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendCtrl_Theblacklistlistisfu"))
        return
    end
    local Msg = {
        TargetPlayerId = TargetPlayerId,
        BlackFlag = BlackFlag,
        AddFriend = AddFriend or false,
    }
    self.IsAddFriendFromBlackList = AddFriend or false
    self:SendProto(Pb_Message.FriendSetPlayerBlackReq,Msg, Pb_Message.FriendSetPlayerBlackRsp)

    local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
    local EventBlackListAction = Msg.BlackFlag and EventTrackingModel.FRIEND_FLOW_ACTION.ADD_TO_BLACK_LIST or EventTrackingModel.FRIEND_FLOW_ACTION.REMOVE_FROM_BLACK_LIST
    local EventData = {
        action = EventBlackListAction,
        playerId = Msg.TargetPlayerId
    }
    EventTrackingModel:DispatchType(EventTrackingModel.ON_FRIEND_FLOW_EVENTTRACKING, EventData)
end

--[[
    请求好友操作日志
]]
function FriendCtrl:SendFriendGetOpLogReq(TargetPlayerId)
    local Msg = {
        TargetPlayerId = TargetPlayerId,
    }
    self:SendProto(Pb_Message.FriendGetOpLogReq,Msg)
end

--[[
    获取好友共同游玩时长
]]
function FriendCtrl:SendPlayerTimeTogetherReq(TargetPlayerId)
    local Msg = {
        TargetPlayerId = TargetPlayerId
    }
    self:SendProto(Pb_Message.PlayerTimeTogetherReq,Msg, Pb_Message.PlayerTimeTogetherRsp)
end

--[[
    获取最近共30场共同游玩的玩家列表
]]
function FriendCtrl:SendFriendsInRecentGamesReq()
    local Msg = {}
    self:SendProto(Pb_Message.FriendsInRecentGamesReq,Msg, Pb_Message.FriendsInRecentGamesRsp)
end

--[[
    查询某些玩家的最晚在线时间
]]
function FriendCtrl:SendPlayerLookUpLastOnlineTimeReq(PlayerIdList)
    local Msg = {
        PlayerIdList = PlayerIdList
    }
    self:SendProto(Pb_Message.PlayerLookUpLastOnlineTimeReq,Msg, Pb_Message.PlayerLookUpLastOnlineTimeRsp)
end

--[[
    给好友赠送物品增加亲密度
]]
function FriendCtrl:SendPlayerGiveFriendItemGiftReq(Msg)
    self:SendProto(Pb_Message.PlayerGiveFriendItemGiftReq,Msg, Pb_Message.PlayerGiveFriendItemGiftRsp)
end

--[[
    请求获取对应PlayerId下的好友关系
]]
function FriendCtrl:SendPlayerIsFriendReq(Msg)
    self:SendProto(Pb_Message.PlayerIsFriendReq, Msg, Pb_Message.PlayerIsFriendRsp)
end

function FriendCtrl:PlayerIsFriendRsp_Func(InResData)
    self.ModelFriend:UpdateFriendPlayerIdToTargetPlayerId(InResData.TargetPlayerId, InResData.IsFriendMap)

    local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
    local EventData = {
        action = EventTrackingModel.FRIEND_FLOW_ACTION.APPLY_FOR_FRIEND,
        playerId = EventTrackingModel:GetLastApplyFriendId(),
        bIsClear = false
    }
    EventTrackingModel:DispatchType(EventTrackingModel.ON_FRIEND_FLOW_EVENTTRACKING, EventData)
end
