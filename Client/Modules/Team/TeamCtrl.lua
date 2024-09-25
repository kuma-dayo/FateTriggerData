--[[
    组队数据模块
]]

require("Client.Modules.Friend.FriendConst")
require("Client.Modules.Team.TeamModel");
require("Client.Modules.Team.TeamInviteModel");
require("Client.Modules.Team.TeamInviteApplyModel");
require("Client.Modules.Team.TeamRequestModel");
require("Client.Modules.Team.TeamRequestApplyModel");
require("Client.Modules.Team.TeamMergeModel");
require("Client.Modules.Team.TeamMergeApplyModel");

local class_name = "TeamCtrl";
---@class TeamCtrl : GameController
TeamCtrl = TeamCtrl or BaseClass(UserGameController,class_name);


function TeamCtrl:__init()
    CWaring("==TeamCtrl init")
    --重连尝试次数
    self.GVoiceRetryMaxCount = CommonUtil.GetParameterConfig(ParameterConfig.TryCount,5)
    self.GVoiceRetryCount = 0 -- 语音进房已重连次数
    self.RetryDelayTime = 2 -- 进房失败几秒后开始尝试下一次进房
    self.GVoiceRetryTimer = nil
end

function TeamCtrl:Initialize()
    ---@type TeamModel
    self.TeamModel = self:GetModel(TeamModel)
    self.TeamInviteModel = self:GetModel(TeamInviteModel)
    self.TeamInviteApplyModel = self:GetModel(TeamInviteApplyModel)
    self.TeamRequestModel = self:GetModel(TeamRequestModel)
    self.TeamRequestApplyModel = self:GetModel(TeamRequestApplyModel)
    self.TeamMergeModel = self:GetModel(TeamMergeModel)
    self.TeamMergeApplyModel = self:GetModel(TeamMergeApplyModel)
end

function TeamCtrl:OnLogin()
    -- 请求队伍信息
    -- self:SendTeamInfoReq()
end

---【重写】用户从大厅进入战斗处理的逻辑
function TeamCtrl:OnPreEnterBattle()
    if self.TeamModel then
        self.TeamModel:OnPreEnterBattle()
    end
    self:StopGVoiceRetryTimer()
end

---【重写】用户从战斗返回大厅处理的逻辑
function TeamCtrl:OnAfterBackToHall()
    if self.TeamModel then
        self.TeamModel:OnAfterBackToHall()
    end
end

function TeamCtrl:OnLogout()
    self:StopGVoiceRetryTimer()
end

function TeamCtrl:AddMsgListenersUser()
    self.ProtoList = {
        { MsgName = Pb_Message.TeamInviteRsp,	Func = self.On_TeamInviteRsp },
        { MsgName = Pb_Message.TeamInviteSync,	Func = self.On_TeamInviteSync },
        { MsgName = Pb_Message.TeamInviteReplyRsp,	Func = self.On_TeamInviteReplyRsp },
        { MsgName = Pb_Message.TeamInviteReplySync,	Func = self.On_TeamInviteReplySync },
        { MsgName = Pb_Message.TeamInviteCancelRsp,	Func = self.On_TeamInviteCancelRsp },
        { MsgName = Pb_Message.TeamInviteCancelSync,	Func = self.On_TeamInviteCancelSync },
        { MsgName = Pb_Message.TeamInviteNotifyDelSync,	Func = self.On_TeamInviteNotifyDelSync },

        { MsgName = Pb_Message.TeamApplyRsp,	Func = self.On_TeamApplyRsp },
        { MsgName = Pb_Message.TeamApplySync,	Func = self.On_TeamApplySync},
        { MsgName = Pb_Message.TeamApplyReplyRsp,	Func = self.On_TeamApplyReplyRsp},
        { MsgName = Pb_Message.TeamApplyReplySync,	Func = self.On_TeamApplyReplySync },

        { MsgName = Pb_Message.TeamMergeRsp,	Func = self.On_TeamMergeRsp },
        { MsgName = Pb_Message.TeamMergeReplySync,	Func = self.On_TeamMergeReplySync },
        { MsgName = Pb_Message.TeamMergeSync,	Func = self.On_TeamMergeSync },
        { MsgName = Pb_Message.TeamMergeReplyRsp,	Func = self.On_TeamMergeReplyRsp },

        { MsgName = Pb_Message.TeamInfoSync,	Func = self.On_TeamInfoSync },
        { MsgName = Pb_Message.TeamIncreInfoSync,	Func = self.On_TeamIncreInfoSync },
        { MsgName = Pb_Message.TeamQuitRsp,	Func = self.On_TeamQuitRsp },
        { MsgName = Pb_Message.TeamKickRsp,	Func = self.On_TeamKickRsp },
        { MsgName = Pb_Message.TeamChangeLeaderRsp,	Func = self.On_TeamChangeLeaderRsp },
        { MsgName = Pb_Message.TeamChangeModeRsp,	Func = self.On_TeamChangeModeRsp },
        { MsgName = Pb_Message.PlayerListTeamInfoRsp,	Func = self.On_PlayerListTeamInfoRsp },
        { MsgName = Pb_Message.QueryMultiTeamInfoRsp,	Func = self.On_QueryMultiTeamInfoRsp },
        { MsgName = Pb_Message.TeamSingleChangeNotifyRsp,	Func = self.On_TeamSingleChangeNotifyRsp },
        { MsgName = Pb_Message.UpdateTeamInfoRsp,	Func = self.On_UpdateTeamInfoRsp },
    }
    self.MsgList = {
        {Model = GVoiceModel, MsgName = GVoiceModel.ON_ROOM_ROOMNAME_UPDATE, Func = self.ON_ROOM_ROOMNAME_UPDATE},
        {Model = GVoiceModel, MsgName = GVoiceModel.ON_INIT_STATE_CHANGED, Func = self.ON_INIT_STATE_CHANGED},
        {Model = GVoiceModel, MsgName = GVoiceModel.ON_JOIN_ROOM_SUCCESS, Func = self.ON_JOIN_ROOM_SUCCESS},
        {Model = GVoiceModel, MsgName = GVoiceModel.ON_JOIN_ROOM_FAILED, Func = self.ON_JOIN_ROOM_FAILED},
    }
end


---- 【【邀请组队】】---- 

--邀请者: 发起邀请请求    
function TeamCtrl:SendTeamInviteReq(InviteeId,InviteeName,SourceType)
    CLog("[cw] TeamCtrl:SendTeamInviteReq(" .. string.format("%s, %s, %s", tostring(InviteeId), tostring(InviteeName), tostring(SourceType)) .. ")")
    if self.TeamInviteModel:GetData(InviteeId) ~= nil then
        CLog("SendTeamInviteReq is in inviteList ".. InviteeId)
        return
    end
    -- 黑名单中不给邀请
    if MvcEntry:GetModel(FriendBlackListModel):GetData(InviteeId) then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamCtrl_Invitationfailed"))
        return
    end
    local InviteeTeamId = self.TeamModel:GetTeamId(InviteeId)
    -- 如果受邀者所在的队伍，邀请过自己，转为接受邀请
    if InviteeTeamId > 0 and self:CheckIsInviteeForTeam(InviteeTeamId) then
        return
    end
    -- 如果受邀者，申请过加入自己的队伍，转为接受申请
    if self:CheckIsTeamRequestApplicant(InviteeId) then
        return
    end


    local InSource = SourceType
    local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
    local PlayerInfoData = MvcEntry:GetModel(PersonalInfoModel):GetCachePlayerDetailInfo(InviteeId)
    if PlayerInfoData then
        -- 检查是否通过轮询请求更新过名称
        InviteeName = PlayerInfoData.PlayerName
        InSource = EventTrackingModel:GetFriendAddSource(PlayerInfoData.PlayerId)
    end
    
    -- 发起操作则停止检测单人队退队倒计时
    self.TeamModel:CleanAutoCheckTimer()

    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    local Msg = {
        InviteeId = InviteeId,
        PlayerName = InviteeName,
        InviteInfo = {
            GameplayId      = MatchModel:GetPlayModeId(),
            LevelId         = MatchModel:GetLevelId(),
            TeamType        = MatchModel:GetTeamType(),
            View            = MatchModel:GetPerspective(),
            IsCrossPlatform = MatchModel:GetIsCrossPlatformMatch(),
            Source          = InSource,
            ReferSourcePageId = GetLocalTimestamp() .. EventTrackingModel:GetNowViewId()
        }
    }
    
    self:SendProto(Pb_Message.TeamInviteReq,Msg)

    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:AddSendNetProtoLog(Pb_Message.TeamInviteReq, nil, Pb_Message.TeamInviteRsp)
end

--邀请者: 收到邀请操作结果
function TeamCtrl:On_TeamInviteRsp(Msg)
    UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamCtrl_Theinvitationwassent"))
end

--被邀请者：通知被邀请者
function TeamCtrl:On_TeamInviteSync(Msg)
    Msg.RequestTime = GetTimestamp()
    local CanAppend = self.TeamInviteApplyModel:AppendData(Msg)
    if CanAppend then
        self.TeamInviteApplyModel:OnReceiveTeamInviteTips(Msg)
        self.TeamInviteApplyModel:DispatchType(TeamInviteApplyModel.ON_APPEND_TEAM_INVITE_APPLY,Msg)
    end
end

--被邀请者：回复邀请
function TeamCtrl:SendTeamInviteReplyReq(Msg)
    self:SendProto(Pb_Message.TeamInviteReplyReq,Msg,Pb_Message.TeamInviteReplyRsp)

    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:AddSendNetProtoLog(Pb_Message.TeamInviteReplyReq, nil, Pb_Message.TeamInviteReplyRsp)
end

--被邀请者：回复邀请后，我加入队伍是否成功通知  需要同步清除对应的邀请缓存
function TeamCtrl:On_TeamInviteReplyRsp(Msg)
    self:DeleteInviteNotice(Msg.TeamId)

    -- 触发组队邀请红点 红点后缀是队伍Id
    MvcEntry:GetCtrl(RedDotCtrl):Interact(RedDotModel.Const_SysRedDotKey[Pb_Enum_RED_DOT_SYS.RED_DOT_TEAM_INVIT], Msg.TeamId)
end

--邀请者 通知邀请者对方应答
function TeamCtrl:On_TeamInviteReplySync(Msg)
    if Msg.Reply == Pb_Enum_REPLY_TYPE.REJECT then
        -- 弹出拒绝邀请提示
        local ShowTipsList = {}
        ShowTipsList[#ShowTipsList+1] = {k = Msg.InviteeId}
        self.TeamModel:ShowTeamTips(FriendConst.TEAM_SHOW_TIPS_TYPE.REJECT_INVITE,ShowTipsList)
    end
end

--邀请者 取消邀请操作
function TeamCtrl:SendTeamInviteCancelReq(Msg)
    self:SendProto(Pb_Message.TeamInviteCancelReq,Msg)
end

--邀请者 取消邀请回包
function TeamCtrl:On_TeamInviteCancelRsp(Msg)
end

--被邀请者：通知邀请取消
function TeamCtrl:On_TeamInviteCancelSync(Msg)
    self:DeleteInviteNotice(Msg.TeamId)
end

--被邀请者：通知邀请消除
function TeamCtrl:On_TeamInviteNotifyDelSync(Msg)
    if not MvcEntry:GetModel(UserModel):IsSelf(Msg.InviteeId) then
        CWaring("TeamInviteNotifyDelSync target is not self!!")
        return
    end
    self:DeleteInviteNotice(Msg.TeamId)

    -- 触发组队邀请红点 红点后缀是队伍Id
    MvcEntry:GetCtrl(RedDotCtrl):Interact(RedDotModel.Const_SysRedDotKey[Pb_Enum_RED_DOT_SYS.RED_DOT_TEAM_INVIT], Msg.TeamId)
end

-- 删除收到的邀请通知
function TeamCtrl:DeleteInviteNotice(TeamId)
    self.TeamInviteApplyModel:DeleteData(TeamId)
    self.TeamInviteApplyModel:DispatchType(TeamInviteApplyModel.ON_OPERATE_TEAM_INVITE,TeamId)
end

-- 检测是否接受过该队伍的邀请,如果是，转为同意邀请
function TeamCtrl:CheckIsInviteeForTeam(TeamId)
    local InviteApplyData = self.TeamInviteApplyModel:GetData(TeamId)
    if InviteApplyData then
        -- 如果申请的队伍，邀请过自己，转为同意邀请
        local Msg = {
            InviterId = InviteApplyData.InviterId,
            Reply = Pb_Enum_REPLY_TYPE.ACCEPT,
            TeamId = TeamId
        }
        self:SendTeamInviteReplyReq(Msg)
        return true
    end
    return false
end

---- 【【申请组队】】---- 

--申请者: 发起申请
function TeamCtrl:SendTeamApplyReq(Msg)
    local TeamId = Msg.ApplyInfo.TeamId
    if self.TeamRequestModel:GetData(TeamId) ~= nil then
        CDebug("SendTeamApplyReq is in requestList ".. TeamId)
        return
    end
    if self:CheckIsInviteeForTeam(TeamId) then
        return
    end
   -- 发起操作则停止检测单人队退队倒计时
    self.TeamModel:CleanAutoCheckTimer()
    self:SendProto(Pb_Message.TeamApplyReq,Msg,Pb_Message.TeamApplyRsp)

    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:AddSendNetProtoLog(Pb_Message.TeamApplyReq, nil, Pb_Message.TeamApplyRsp)
end
--申请者：申请成功回包
function TeamCtrl:On_TeamApplyRsp(Msg)
    -- 存入发出的申请列表
    local CanAppend = self.TeamRequestModel:AppendData(Msg)
    if CanAppend then
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamCtrl_Sendingapplicationsu"))
        self.TeamRequestModel:DispatchType(TeamRequestModel.ON_APPEND_TEAM_REQUEST)
    end
end

--申请者: 收到申请回复通知
function TeamCtrl:On_TeamApplyReplySync(Msg)
    self.TeamRequestModel:DeleteData(Msg.TeamId)
    -- 弹拒绝提示
    if Msg.Reply == Pb_Enum_REPLY_TYPE.REJECT then
        self.TeamModel:ShowRejectApplyTips(Msg.TeamId)
    end
end

--被申请者: 收到申请
function TeamCtrl:On_TeamApplySync(Msg)
    self.TeamRequestApplyModel:OnReceiveTeamRequestTips(Msg)
end

--被申请者: 回复申请
function TeamCtrl:SendTeamApplyReplyReq(Msg, NotCheckLeader)
    Msg.IsCheckLeader = not NotCheckLeader
    self:SendProto(Pb_Message.TeamApplyReplyReq,Msg,Pb_Message.TeamApplyReplyRsp)

    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:AddSendNetProtoLog(Pb_Message.TeamApplyReplyReq, nil, Pb_Message.TeamApplyReplyRsp)
end

--被申请者: 回复申请操作结果
function TeamCtrl:On_TeamApplyReplyRsp(Msg)
    -- 触发组队申请红点 红点后缀是申请队伍的玩家PlayerId
    MvcEntry:GetCtrl(RedDotCtrl):Interact(RedDotModel.Const_SysRedDotKey[Pb_Enum_RED_DOT_SYS.RED_DOT_TEAM_APPLY], Msg.ApplicantId)
end

-- 检测该玩家是否申请过加入自己队伍,如果是，转为同意申请
function TeamCtrl:CheckIsTeamRequestApplicant(PlayerId)
    if self.TeamRequestApplyModel:GetData(PlayerId) then
        local Msg = {
            ApplicantId = PlayerId,
            Reply = Pb_Enum_REPLY_TYPE.ACCEPT,
            TeamId = self.TeamModel:GetTeamId()
        }
        self:SendTeamApplyReplyReq(Msg,true)
        return true
    end
    return false
end

---- 【【合并队伍】】---- 
-- 申请者：发起合并申请
function TeamCtrl:SendTeamMergeReq(Msg)
    -- 如果合并目标队伍，申请过合并到自己的队伍，转为接受合并
    if self:CheckIsMergeSourceTeam(Msg.MergeInfo.TargetTeamId,Msg.MergeRecvId) then
        return
    end
    -- 发起操作则停止检测单人队退队倒计时
    self.TeamModel:CleanAutoCheckTimer()
    self:SendProto(Pb_Message.TeamMergeReq,Msg,Pb_Message.TeamMergeRsp)

    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:AddSendNetProtoLog(Pb_Message.TeamMergeReq, nil, Pb_Message.TeamMergeRsp)
end

-- 申请者：发起合并申请回包
function TeamCtrl:On_TeamMergeRsp(Msg)
    UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamCtrl_Sendingmergerapplica"))
end

--申请者: 收到申请回复通知
function TeamCtrl:On_TeamMergeReplySync(Msg)
    -- 弹拒绝提示
    if Msg.Reply == Pb_Enum_REPLY_TYPE.REJECT then
        self.TeamModel:ShowRejectApplyTips(Msg.TeamId)
    end
end

--被申请者：收到申请
function TeamCtrl:On_TeamMergeSync(Msg)
    self.TeamMergeApplyModel:OnReceiveTeamMergeTips(Msg)
end

--被申请者：回复申请
function TeamCtrl:SendTeamMergeReplyReq(Msg, NotCheckLeader)
    Msg.IsCheckLeader = not NotCheckLeader
    self:SendProto(Pb_Message.TeamMergeReplyReq,Msg,Pb_Message.TeamMergeReplyRsp)

    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:AddSendNetProtoLog(Pb_Message.TeamMergeReplyReq, nil, Pb_Message.TeamMergeReplyRsp)
end

--被申请者：回复申请操作结果
function TeamCtrl:On_TeamMergeReplyRsp(Msg)
end

-- 检测该玩家是否申请过合并队伍,如果是，转为同意合并
function TeamCtrl:CheckIsMergeSourceTeam(TargetTeamId,TargetPlayerId)
    if self.TeamMergeApplyModel:GetData(TargetTeamId) then
        local Msg = {
            MergeSendId = TargetPlayerId,
            Reply = Pb_Enum_REPLY_TYPE.ACCEPT,
            TargetTeamId = self.TeamModel:GetTeamId(),
            SourceTeamId = TargetTeamId
        }
        self:SendTeamMergeReplyReq(Msg, true)
        return true
    end
    return false
end

---- 【【队伍】】---- 

--队伍信息: 请求队伍信息
function TeamCtrl:SendTeamInfoReq()
    self:SendProto(Pb_Message.TeamInfoReq,{},Pb_Message.TeamInfoSync)
end

--队伍信息: 收到队伍信息
function TeamCtrl:On_TeamInfoSync(TeamInfo)
    -- print_r(TeamInfo)
    if TeamInfo == nil then
        return
    end
    if self.TeamModel == nil then
        return 
    end
    self.TeamModel:SetTeamInfo(TeamInfo)
end

--队伍信息: 增量同步队伍信息
function TeamCtrl:On_TeamIncreInfoSync(TeamIncreInfo)
    self.TeamModel:UpdateTeamInfo(TeamIncreInfo)
end

--退出队伍: 主动退出队伍
function TeamCtrl:SendTeamQuitReq()
    self:SendProto(Pb_Message.TeamQuitReq,{},Pb_Message.TeamQuitRsp)
    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:AddSendNetProtoLog(Pb_Message.TeamQuitReq, nil, Pb_Message.TeamQuitRsp)
end

--退出队伍: 退出队伍回复
function TeamCtrl:On_TeamQuitRsp()
end

--踢出队伍: 踢人
function TeamCtrl:SendTeamKickReq(PlayerId)
    local Msg = {
        PlayerId = PlayerId
    }
    self:SendProto(Pb_Message.TeamKickReq,Msg,Pb_Message.TeamKickRsp)
end

--踢出队伍: 踢人回复
function TeamCtrl:On_TeamKickRsp()

end

--更换队长: 更换队长请求
function TeamCtrl:SendTeamChangeLeaderReq(NewLeaderId)
    local Msg = {
        NewLeaderId = NewLeaderId
    }
    self:SendProto(Pb_Message.TeamChangeLeaderReq,Msg,Pb_Message.TeamChangeLeaderRsp)

    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:AddSendNetProtoLog(Pb_Message.TeamChangeLeaderReq, nil, Pb_Message.TeamChangeLeaderRsp)
end

--更换队长: 更换队长回复
function TeamCtrl:On_TeamChangeLeaderRsp()

end

--修改队伍模式：请求
function TeamCtrl:SendTeamChangeModeReq(Msg)
    CLog("[cw] TeamCtrl:SendTeamChangeModeReq(" .. string.format("%s", Msg) .. ")")
    CLog("[cw] Msg.GameplayId: " .. tostring(Msg.GameplayId))
    CLog("[cw] Msg.LevelId: " .. tostring(Msg.LevelId))
    CLog("[cw] Msg.TeamType: " .. tostring(Msg.TeamType))
    CLog("[cw] Msg.View: " .. tostring(Msg.View))
    CLog("[cw] Msg.IsCrossPlatform: " .. tostring(Msg.IsCrossPlatform))
    self:SendProto(Pb_Message.TeamChangeModeReq, Msg, Pb_Message.TeamChangeModeRsp)
end

--修改队伍模式：回复
function TeamCtrl:On_TeamChangeModeRsp(Msg)
    if not Msg or not Msg.GameplayId or Msg.GameplayId == 0 or
            not Msg.LevelId or Msg.LevelId == 0 or
            not Msg.View or Msg.View == 0 or
            not Msg.TeamType or Msg.TeamType == 0 then
        CError("[cw] On_TeamChangeModeRsp with illegal param")
        print_r(Msg, "[cw] ====Msg")
        CError(debug.traceback())
        return 
    end
    
    CLog("[cw] TeamCtrl:On_TeamChangeModeRsp(" .. string.format("%s", Msg) .. ")")
    CLog("[cw] Msg.GameplayId: " .. tostring(Msg.GameplayId))
    CLog("[cw] Msg.LevelId: " .. tostring(Msg.LevelId))
    CLog("[cw] Msg.View: " .. tostring(Msg.View))
    CLog("[cw] Msg.TeamType: " .. tostring(Msg.TeamType))
    CLog("[cw] Msg.IsCrossPlatform : " .. tostring(Msg.IsCrossPlatform))
    
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    MatchModel:SetPlayModeId(Msg.GameplayId)
    MatchModel:SetLevelId(Msg.LevelId)
    MatchModel:SetPerspective(Msg.View)
    MatchModel:SetTeamType(Msg.TeamType)
    MatchModel:SetIsCrossPlatformMatch(Msg.IsCrossPlatform)    
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    MatchModel:SetSceneId(MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(Msg.LevelId))
    MatchModel:SetModeId(MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(Msg.LevelId))
end

-- 根据PlayerList批量查询队伍信息
-- 查询成功通过TeamInfoSync返回
-- 查询失败通过On_PlayerListTeamInfoRsp返回
function TeamCtrl:SendPlayerListTeamInfoReq(ReqIdList)
    local Msg = {
        PlayerList = ReqIdList
    }
    self:SendProto(Pb_Message.PlayerListTeamInfoReq,Msg)
end

-- 根据PlayerList批量查询队伍信息
-- Msg.PlayerList 查询不到队伍的玩家Id列表
function TeamCtrl:On_PlayerListTeamInfoRsp(Msg)
    self.TeamModel:DeleteOtherTeamInfos(Msg.PlayerList)
end

-- 根据TeamIdList查询多个队伍信息
-- 查询成功通过TeamInfoSync返回
-- 查询失败通过ErrorCode.TeamNotExist返回
function TeamCtrl:QueryMultiTeamInfoReq(TeamIdList)
    local Msg = {
        QueryTeamList = TeamIdList
    }
    self:SendProto(Pb_Message.QueryMultiTeamInfoReq,Msg)
end

function TeamCtrl:On_QueryMultiTeamInfoRsp()
    
end

-- 通知服务器单人队发生变化
function TeamCtrl:SendTeamSingleChangeNotifyReq()
    self:SendProto(Pb_Message.TeamSingleChangeNotifyReq,{})
end

function TeamCtrl:On_TeamSingleChangeNotifyRsp()
    
end

-- 查询自己的队伍信息
function TeamCtrl:SendUpdateTeamInfoReq()
    self:SendProto(Pb_Message.UpdateTeamInfoReq,{})
end

function TeamCtrl:On_UpdateTeamInfoRsp(TeamInfo)
    self.TeamModel:OnQuerySelfTeamInfo(TeamInfo)
end

--region -------------------------------------- 队伍玩家状态 --------------------------------------
---队伍玩家状态与玩家状态不一致，玩家状态记录在UserModel中，队伍玩家状态记录在队伍中
---队伍玩家状态主要包含了 准备 与 未准备 的信息，专为队伍打造使用
---玩家状态则主要是为了体现玩家客户端的一个显示状态，例如在浏览英雄界面、在浏览战备之类的信息
---使用前请先区分该使用哪一种状态

---更改自己的状态为准备
function TeamCtrl:ChangeMyTeamMemberStatusToGAME_RESULT()
    self:ChangeMyTeamMemberStatus(Pb_Enum_TEAM_MEMBER_STATUS.SETTLE)
end

---更改自己的状态为准备
function TeamCtrl:ChangeMyTeamMemberStatusToReady()
    self:ChangeMyTeamMemberStatus(Pb_Enum_TEAM_MEMBER_STATUS.READY)
end

---更改自己的状态为未准备
function TeamCtrl:ChangeMyTeamMemberStatusToUnReady()
    self:ChangeMyTeamMemberStatus(Pb_Enum_TEAM_MEMBER_STATUS.UNREADY)
end

---更改玩家在队伍中的准备状
---@param NewStatus string 参考 Pb_Enum_TEAM_MEMBER_STATUS
function TeamCtrl:ChangeMyTeamMemberStatus(NewStatus)
    --1.判空保护
    if not NewStatus then
        CError("[cw] trying to set a illegal status(" .. tostring(NewStatus) .. ") ")
        return
    end

    --2.非队伍不处理
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    if not TeamModel:IsSelfInTeam() then return CLog("[cw] not in team, no need to change teamStatus") end

    --3.状态相同不处理
    local MyTeamInfoStatus = TeamModel:GetMyTeamInfoStatus()
    if MyTeamInfoStatus and MyTeamInfoStatus ~= nil and MyTeamInfoStatus == NewStatus then CLog("[cw] MyTeamInfoStatus(" .. tostring(MyTeamInfoStatus) .. ") == NewStatus(" .. tostring(NewStatus) .. ") no need to update") return end

    --4.发送状态变更
    local Msg = {
        Status = NewStatus
    }    
    CLog("[cw] Send TeamChangeMemberStatusReq to change myMemberStatus to : " .. tostring(NewStatus))
    self:SendProto(Pb_Message.TeamChangeMemberStatusReq, Msg)

    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:AddSendNetProtoLog(Pb_Message.TeamChangeMemberStatusReq, nil, Pb_Message.TeamChangeMemberStatusRsp)
end

--endregion -------------------------------------- 队伍玩家状态 --------------------------------------

-- 语音token更新
function TeamCtrl:ON_ROOM_ROOMNAME_UPDATE()
    self.TeamModel:EnterTeamVoiceRoom()
end

function TeamCtrl:ON_INIT_STATE_CHANGED(IsInited)
    if IsInited then
        self.TeamModel:EnterTeamVoiceRoom()
    end
end

function TeamCtrl:ON_JOIN_ROOM_SUCCESS(RoomName)
    if RoomName ~= self.TeamModel:GetTeamVoiceRoomName() then
        CLog("ON_JOIN_ROOM_SUCCESS RoomName Unpatch Req RoomName, : "..RoomName )
        return
    end
    UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamVoice_JoinSuccess"))
    self:StopGVoiceRetryTimer()
    MvcEntry:GetCtrl(GVoiceCtrl):OnJoinTeamRoomOutside(RoomName)

end

function TeamCtrl:ON_JOIN_ROOM_FAILED(RoomName)
    if RoomName ~= self.TeamModel:GetTeamVoiceRoomName() then
        CLog("ON_JOIN_ROOM_FAILED RoomName Unpatch Req RoomName, : "..RoomName )
        return
    end
    if self.GVoiceRetryCount > self.GVoiceRetryMaxCount then
        -- 重连失败
        local msgParam = {
            describe = G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamVoice_RetryFailed"),
            rightBtnInfo = {                                              
                callback = function()
                    self.GVoiceRetryCount = 0
                    self.TeamModel:EnterTeamVoiceRoom()
                end
            },
            leftBtnInfo = {}
        }
        UIMessageBox.Show(msgParam)
        return
    end
    self.GVoiceRetryCount = self.GVoiceRetryCount + 1
    self:StartGVoiceRetryTimer()
end

function TeamCtrl:StartGVoiceRetryTimer()
    self:StopGVoiceRetryTimer()
    -- RetryDelayTime 秒后再次尝试重进语音房间
    self.GVoiceRetryTimer = Timer.InsertTimer(self.RetryDelayTime,function ()
        UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamVoice_FailAndRetry"))
        self.TeamModel:EnterTeamVoiceRoom()
        self.GVoiceRetryTimer = nil
    end)    
end

function TeamCtrl:StopGVoiceRetryTimer()
    if self.GVoiceRetryTimer then
        Timer.RemoveTimer(self.GVoiceRetryTimer)
    end
    self.GVoiceRetryTimer = nil
end

function TeamCtrl:AddTest()
    if CommonUtil.IsShipping() then
        return
    end
    local Uid = MvcEntry:GetModel(UserModel):GetPlayerId()
    local TeamInfo = {
        LeaderId = Uid,
        PlayerCnt = 2,
        LevelId = 1011001,
        CreateTime = 1720249737,
        TeamId = 29041360897,
        View = 3,
        TeamType = 4,
        TargetId = Uid,
        GameplayId = 10001,
        Reason = 1,
        IsCrossPlatform = true,
        Members = {
            [Uid] = {
                WeaponId = 300010000,
                WeaponSkinId = 300010001,
                PlayerId = Uid,
                PlayerName = "AlanJohnson,#0004",
                PlatformId = 0,
                JoinTime = 1720249737,
                Addr = 0,
                HeadId = 600010001,
                Status = 1,
                HeroSkinId = 200030001,
                HeroId = 200030000
            },
            [29041360898] = {
                WeaponId = 300010000,
                WeaponSkinId = 300010001,
                PlayerId = 29041360898,
                PlayerName = "善良的朱利安,#0001",
                PlatformId = 0,
                JoinTime = 1720249742,
                Addr = 0,
                HeadId = 600010001,
                Status = 1,
                HeroSkinId = 200030001,
                HeroId = 200030000
            }
        },
        InviteList = {},
        ApplyList = {},
        MergeRecvList = {},
        MergeSendList = {}
    }
    self.TeamModel:SetTeamInfo(TeamInfo)
end
function TeamCtrl:DelTest()
    if CommonUtil.IsShipping() then
        return
    end
    local Uid = MvcEntry:GetModel(UserModel):GetPlayerId()
    local TeamInfo = {
        LeaderId = Uid,
        IsCrossPlatform = true,
        PlayerCnt = 1,
        LevelId = 1011001,
        CreateTime = 1720249737,
        TeamId = 29041360897,
        View = 3,
        TeamType = 4,
        TargetId = Uid,
        GameplayId = 10001,
        Reason = 1,
        Members = {},
        InviteList = {},
        ApplyList = {},
        MergeRecvList = {},
        MergeSendList = {}
    }
    self.TeamModel:SetTeamInfo(TeamInfo)
end
