--[[
    好友&组队 推荐 协议处理模块
]]

require("Client.Modules.Recommend.RecommendModel")
local class_name = "RecommendCtrl"
---@class RecommendCtrl : UserGameController
RecommendCtrl = RecommendCtrl or BaseClass(UserGameController,class_name)


function RecommendCtrl:__init()
    CWaring("==RecommendCtrl init")
    self.LastReqTime = 0
    self.ReqTimeCD = 5
    self.LastReqSendTime = 0  -- 上次请求的发送时间
    self.ReqTimeout = 3 -- 请求超时时间
    self.LastOutterReqTime = 0  -- 上次外部请求的发送时间
    self.MinOutterReqGap = 1    -- 最小外部请求时间间隔
end

function RecommendCtrl:Initialize()
    ---@type RecommendModel
    self.RecommendModel = MvcEntry:GetModel(RecommendModel)
end

--[[
    玩家登入
]]
function RecommendCtrl:OnLogin(data)
    CWaring("RecommendCtrl OnLogin")
end

function RecommendCtrl:OnLogout()
    self.LastReqTime = 0
    self.LastOutterReqTime = 0
    self:StopReqTimeoutTimer()
end

function RecommendCtrl:AddMsgListenersUser()
    self.ProtoList = {
    	{MsgName = Pb_Message.RecommendTeammateListRsp,	Func = self.RecommendTeammateListRsp_Func },	
    }

    self.MsgList = {
		{Model = UserModel,  	MsgName = UserModel.ON_QUERY_MULTI_PLAYER_STATE_RSP,      Func = self.OnQueryMultiPlayerStateRsp},
        {Model = TeamModel,  	MsgName = TeamModel.ON_GET_OTHER_TEAM_INFO,      Func = self.OnGetOtherTeamInfo},
        {Model = TeamModel,  	MsgName = TeamModel.ON_ADD_TEAM_MEMBER,      Func = self.CheckIsMemberInRecommend},
        {Model = FriendModel,  	MsgName = FriendModel.ON_ADD_FRIEND,      Func = self.CheckIsMemberInRecommend},
    }
end

--[[
    收到展示列表信息
    message RecommendTeammateListRsp
    {
        repeated RecommendTeammateInfo RecommendTeammateList = 1; // 推荐列表
        int32 PageCount = 2;                                      // 推荐个数
        int32 LastIndex = 3;                                      // 该页最后一个元素的索引位置，用于分页
    }
]] 
function RecommendCtrl:RecommendTeammateListRsp_Func(Msg)
    CWaring(StringUtil.FormatSimple("RecommendTeammateListRsp_Func LastIndex = {0} PageCount = {1} ListLength = {2}",Msg.LastIndex,Msg.PageCount,#Msg.RecommendTeammateList))
    self:StopReqTimeoutTimer()
    if #Msg.RecommendTeammateList == 0 then
        -- 请求不到数据了，非第一页就请求不到数据的。就重新重头请求
        local NeedReq = self.RecommendModel:GetLastIndex() ~= 0
        if NeedReq then
            self.RecommendModel:ResetLastIndex()
            self:ReqRecommendTeammateListInner()
            return
        else
            -- 确实没数据了
        end
    end
    local IsListChanged = self.RecommendModel:SaveRecommendTeammateList(Msg)
    if IsListChanged then
        -- 如果列表发生了变化，需要重新整理列表中处于队伍状态的玩家Id，查询这些玩家的队伍状态
        self:CheckShowListTeamState()
    end
end

------------------------------------请求相关----------------------------

-- 设定一个时间间隔进行请求
function RecommendCtrl:CheckReqShowList()
    local CurTime = GetTimestamp()
    if self.LastReqTime == 0 or (CurTime - self.LastReqTime) >= self.ReqTimeCD then
        self:ReqRecommendTeammateList()
        self.LastReqTime = CurTime
        return true
    else
        CWaring("RecommendCtrl ReqRecommendTeammateList In CDTime!")
        return false
    end
end

-- 外部请求推荐列表，允许内部请求一轮
function RecommendCtrl:ReqRecommendTeammateList()
    print("== ReqRecommendTeammateList")
    local CurTime = GetTimestamp()
    if self.LastOutterReqTime == 0 or (CurTime - self.LastOutterReqTime) >= self.MinOutterReqGap then
        -- 重置内部请求标记
        self.RecommendModel.ReqOneRoundInner = false
        self.RecommendModel.RequestingInner = false
        self:SendProto_RecommendTeammateListReq()
        self.LastOutterReqTime = CurTime
    else
        CWaring("== ReqRecommendTeammateList In 1s")
    end
end

-- 内部请求推荐列表
function RecommendCtrl:ReqRecommendTeammateListInner()
    if self.RecommendModel.ReqOneRoundInner then
        print("== ReqRecommendTeammateListInner Have Req OneRound")
        -- 内部请求完一轮了，直接以当前数据更新了
        self.RecommendModel:DoUpdateShowList()
        return
    end
    print("== ReqRecommendTeammateListInner")
    self.RecommendModel.RequestingInner = true
    self:SendProto_RecommendTeammateListReq()
end

-- 起一个计时器检测这次的内部是否超时，如果超时或已经收到回包重置请求阻拦标记
function RecommendCtrl:StartReqTimeoutTimer()
    self:StopReqTimeoutTimer()
    self.LastReqSendTime = GetTimestamp()  -- 记录下当前请求的时间
    self.InnerReqTimeoutTimer = Timer.InsertTimer(self.ReqTimeout, function ()
        CWaring("== ReqRecommendTeammateListInner Timeout!!!")
        self:StopReqTimeoutTimer()
        -- self.RecommendModel:DoUpdateShowList()
    end)
end

function RecommendCtrl:StopReqTimeoutTimer()
    if self.InnerReqTimeoutTimer then
        Timer.RemoveTimer(self.InnerReqTimeoutTimer)
        self.InnerReqTimeoutTimer = nil
    end
    self.LastReqSendTime = 0   -- 重置内部请求标记
end

-- 请求推荐展示列表
function RecommendCtrl:SendProto_RecommendTeammateListReq()
    if self.LastReqSendTime > 0 then
        -- 上一次请求还未返回，不给进行下一次直到返回或者超时
        CWaring("== SendProto_RecommendTeammateListReq Is Waiting Last Req")
        return
    end
    local Msg = {
        LastIndex = self.RecommendModel:GetLastIndex(),
        PageCount = self.RecommendModel:GetConfigPageCount()
    }
    print_r(Msg)
    -- 起一个计时器看是否超时，如果超时重置请求阻拦标记
    self:StartReqTimeoutTimer()
    self:SendProto(Pb_Message.RecommendTeammateListReq,Msg,Pb_Message.RecommendTeammateListRsp)
end

-- 请求列表内的玩家状态和组队状态
function RecommendCtrl:CheckShowListState()
    self:CheckShowListPlayerState()
    self:CheckShowListTeamState()
end

-- 查询玩家状态
function RecommendCtrl:CheckShowListPlayerState()
    local List = self.RecommendModel:GetCheckStateIdList()
    if List and #List > 0 then
        -- MvcEntry:GetCtrl(UserCtrl):SendQueryMultiPlayerStatusReq(List)
        MvcEntry:GetModel(UserModel):GetPlayerState(List)
    end
end

-- 查询队伍状态
function RecommendCtrl:CheckShowListTeamState()
     -- -- 通过teamid查询队伍状态
    -- local TeamIdList = self.RecommendModel:GetCheckTeamStateTeamIdList()
    -- if TeamIdList and #TeamIdList > 0 then
    --     MvcEntry:GetCtrl(TeamCtrl):QueryMultiTeamInfoReq(TeamIdList)
    -- end
    -- 通过playerid查询队伍状态
    local PlayerIdList = self.RecommendModel:GetCheckTeamStatePlayerIdList()
    if PlayerIdList and #PlayerIdList > 0 then
        MvcEntry:GetCtrl(TeamCtrl):SendPlayerListTeamInfoReq(PlayerIdList)
    end
end

--[[
    收到查询玩家返回
    map<int64, PlayerState> StatusInfoList = 1;    // 玩家PlayerId列表的状态
]]
function RecommendCtrl:OnQueryMultiPlayerStateRsp(StatusInfoList)
    self.RecommendModel:UpdatePlayerState(StatusInfoList)
end

--[[
    收到查询队伍信息返回
]]
function RecommendCtrl:OnGetOtherTeamInfo(TeamInfo)
    if not TeamInfo or TeamInfo.TargetId == 0 then
        return
    end
    self.RecommendModel:UpdateTeamInfo(TeamInfo)
end

--[[
    新队员加入/新好友，查询是否存在于推荐列表，存在要刷新列表，把好友从列表移除
]]
function RecommendCtrl:CheckIsMemberInRecommend(AddMap)
    local NeedUpdate = false
	for _, Info in ipairs(AddMap) do
        local PlayerId = Info.k or Info.PlayerId
        if self.RecommendModel:GetIndexInShowList(PlayerId) then
            NeedUpdate = true
            break
        end
    end
    if NeedUpdate then
        CWaring("RecommendModel:CheckIsMemberInRecommend NeedUpdateList For Reason : Become TeamMember Of Friend")
        self.RecommendModel:UpdateShowList()
    end
end