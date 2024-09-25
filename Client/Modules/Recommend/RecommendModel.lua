--[[
    好友&组队 推荐 数据模型
]]

local super = GameEventDispatcher;
local class_name = "RecommendModel";

---@class RecommendModel : GameEventDispatcher
---@field private super GameEventDispatcher
---@type RecommendModel
RecommendModel = BaseClass(super, class_name)
RecommendModel.ON_RECOMMEND_SHOW_LIST_UPDATED = "ON_RECOMMEND_SHOW_LIST_UPDATED" -- 推荐列表更新
RecommendModel.ON_RECOMMEND_SPECIAL_SHOW_LIST_UPDATED = "ON_RECOMMEND_SPECIAL_SHOW_LIST_UPDATED" -- 特殊推荐列表更新
RecommendModel.ON_PLAYER_STATE_UPDATE = "ON_PLAYER_STATE_UPDATE" -- 玩家状态更新

function RecommendModel:__init()
    self:_dataInit()
end

function RecommendModel:_dataInit()
    self.ConfigPageCount = nil
    self.ConfigRecommendNum = nil
    self.RecommendTeammateList = {} -- 总的推荐列表
    self.CheckStateIdList = {} -- 需要检查状态的id列表
    self.CheckStateIdMap = {} -- 需要检查状态的id的KeyMap
    self.CheckTeamStatePlayerIdList = {} -- 需要检查队伍状态的玩家id列表
    self.PlayerId2TeamInfo = {} -- 玩家id对应的队伍信息
    self.TeamMemberRecord = {} -- 玩家id对应的队伍id
    self.TeamItemRefreshRecord = {} -- 记录是否刷新过该队伍item
    self.RecommendTeammateStateList = {}    -- 推荐列表的玩家状态
    self.RecommendTeammateMemberCountList = {}  -- 推荐列表的队伍人数
    self.ShowList = {}  -- 可展示的列表
    self.ShowPlayerId2Index = {}  -- 展示列表的id->index
    self.LastReqIndex = 0 -- 最后一次请求的Index
    self.SpecialShowList = {} -- 当前正在展示的特殊推荐人员列表
    self.SpecialRecommendLastIndex = 0 -- 特殊推荐展示的最后一个人的index
    self.MyTeamMember = {} -- 记录推荐人进入玩家自己队伍
    self.MinShowNum = 10 -- 最小展示人数
    self.ReqOneRoundInner = false	-- 内部是否已经请求完一轮数据标记
    self.RequestingInner = false	-- 是否进行内部请求中标记
end

function RecommendModel:OnLogin(data)
    self:_dataInit()
end

--[[
    玩家登出时调用
]]
function RecommendModel:OnLogout(data)
    RecommendModel.super.OnLogout(self)
    self:_dataInit()
end

-- 关闭界面时，把所有记录过的变动清除，重新打开界面根据状态重新计算
function RecommendModel:ClearCacheData()
    self.PlayerId2TeamInfo = {}
    self.TeamMemberRecord = {}
    self.TeamItemRefreshRecord = {}
    self.MyTeamMember = {}
end
-------- 对外接口 -----------

-- 获取一页请求多少人
function RecommendModel:GetConfigPageCount()
    if not self.ConfigPageCount then
        local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ParameterConfig,ParameterConfig.TeamRecommendListNum.ParameterId)
        self.ConfigPageCount = Cfg and Cfg[Cfg_ParameterConfig_P.ParameterValue] or 50
    end
    return self.ConfigPageCount
end

-- 获取特殊展示页展示的人数
function RecommendModel:GetConfigRecommendNum()
    if not self.ConfigRecommendNum then
        local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ParameterConfig,ParameterConfig.TeamRecommendNum.ParameterId)
        self.ConfigRecommendNum = Cfg and Cfg[Cfg_ParameterConfig_P.ParameterValue] or 5
    end
    return self.ConfigRecommendNum
end

-- 获取上次请求的末尾索引，用于请求服务器分页数据
function RecommendModel:GetLastIndex()
    return self.LastReqIndex
end

-- 重新重头请求
function RecommendModel:ResetLastIndex()
    if self.RequestingInner then
    	-- 内部请求中，重置说明已经完成一轮，修改一轮的标记
        self.ReqOneRoundInner = true
    end
    self.LastReqIndex = 0
end

-- 获取需要检查状态Id列表
function RecommendModel:GetCheckStateIdList()
    return self.CheckStateIdList
end

-- 获取需要检查队伍状态的玩家id列表
function RecommendModel:GetCheckTeamStatePlayerIdList()
    return self.CheckTeamStatePlayerIdList
end

-- 获取所有可展示的推荐人员
function RecommendModel:GetCanShowRecommendList()
    return self.ShowList
end

-- 获取当前正在展示的特别推荐列表
function RecommendModel:GetSpecialShowList()
    return self.SpecialShowList
end

-- 是否展示特别推荐列表
function RecommendModel:IsShowSpecialShowList()
    return (self.SpecialShowList and #self.SpecialShowList > 0)
end

-- 获取id在展示列表中的index
function RecommendModel:GetIndexInShowList(PlayerId)
    if self.ShowPlayerId2Index and self.ShowPlayerId2Index[PlayerId] then
        return self.ShowPlayerId2Index[PlayerId]
    end
    return nil
end

-- 获取id对应的玩家状态
function RecommendModel:GetRecommendPlayerState(PlayerId)
    if self.RecommendTeammateStateList and self.RecommendTeammateStateList[PlayerId] then
        return self.RecommendTeammateStateList[PlayerId]
    end
    return nil
end

-- 获取下一批特别推荐人员
function RecommendModel:GetNextSpecialShowRecommendList(IsFromOuter)
    local ConfigRecommendNum = self:GetConfigRecommendNum()
    local LastIndex = #self.ShowList
    if self.SpecialRecommendLastIndex > 0 and self.SpecialRecommendLastIndex == LastIndex then
        -- 取完缓存数据了，取下一页
        if IsFromOuter then	-- 这个标记位是个兜底判断，理论上内部进来时候SpecialRecommendLastIndex都会重置为0
		-- 先重置特殊推荐列表，如果请求回来没有新数据，则从头开始循环
            self.SpecialShowList = {}
            self.SpecialRecommendLastIndex = 0
            MvcEntry:GetCtrl(RecommendCtrl):ReqRecommendTeammateList()
        end
        return false
    end
    self.SpecialShowList = {}
    local ShowLastIndex = self.SpecialRecommendLastIndex + ConfigRecommendNum
    if ShowLastIndex > LastIndex then ShowLastIndex = LastIndex end
    for Index = self.SpecialRecommendLastIndex + 1, ShowLastIndex do
        self.SpecialShowList[#self.SpecialShowList + 1] = self.ShowList[Index]
    end
    self.SpecialRecommendLastIndex = ShowLastIndex
    return true
end

function RecommendModel:UpdateSpecialShowList()
    local ConfigRecommendNum = self:GetConfigRecommendNum()
    if #self.SpecialShowList > 0 then
        -- 已经有列表在展示了
        local NewList = {}
        for _,ShowInfo in ipairs(self.SpecialShowList) do
            local NewIndex = self:GetIndexInShowList(ShowInfo.PlayerId)
            if NewIndex then
                -- 还能继续展示
                NewList[#NewList+1] = ShowInfo
                self.SpecialRecommendLastIndex = NewIndex
            end
        end
        local NeedAppendCount = ConfigRecommendNum - #NewList
        local LastIndex = #self.ShowList
        if NeedAppendCount > 0 and self.SpecialRecommendLastIndex < LastIndex then
            -- 继续补全到人数够
            local ShowLastIndex = self.SpecialRecommendLastIndex + NeedAppendCount
            if ShowLastIndex > LastIndex then ShowLastIndex = LastIndex end
            for Index = self.SpecialRecommendLastIndex + 1, ShowLastIndex do
                NewList[#NewList + 1] = self.ShowList[Index]
            end
            self.SpecialRecommendLastIndex = ShowLastIndex
        end
        self.SpecialShowList = NewList
    else
        self:GetNextSpecialShowRecommendList()
    end
    self:DispatchType(RecommendModel.ON_RECOMMEND_SPECIAL_SHOW_LIST_UPDATED)
end

--[[
    是否可以展示
    非离线，非匹配中，非游戏中，非满队，非好友 & 
    组队中： 前面已有队伍显示了自己，会合并在一起 or 和自己的队伍无法合并 or 在自己队伍
    
]]
function RecommendModel:CheckCanShow(RecommendTeammateInfo)
    local PlayerId = RecommendTeammateInfo.PlayerId
    if MvcEntry:GetModel(FriendModel):IsFriend(PlayerId) then
        return false
    end
    if MvcEntry:GetModel(TeamModel):IsSelfTeamMember(PlayerId) then
        return false
    end
        
    local PlayerState = self.RecommendTeammateStateList[PlayerId]
    if not PlayerState then
        CWaring("Get State Of No Record Member, Id = "..tostring(PlayerId))
        return false
    end
    local Status = PlayerState.Status
    if Status == Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE or Status >= Pb_Enum_PLAYER_STATE.PLAYER_MATCH then
        return false
    end
    if Status > Pb_Enum_PLAYER_STATE.PLAYER_LOBBY  then
        local MyTeamInfo = MvcEntry:GetModel(TeamModel):GetTeamInfo()
        local MyTeamId = MyTeamInfo and MyTeamInfo.TeamId or 0
        local MyTeamMemberCount = MyTeamInfo and MyTeamInfo.PlayerCnt or 0
        if not self.PlayerId2TeamInfo[PlayerId] or (self.PlayerId2TeamInfo[PlayerId].TeamId == 0 and self.TeamMemberRecord[PlayerId]) then
            -- 组队中，但没有队伍信息，被别的队伍展示了
            return false
        elseif self.PlayerId2TeamInfo[PlayerId].TeamId == 0 then
            return true
        elseif self.PlayerId2TeamInfo[PlayerId].PlayerCnt == FriendConst.MAX_TEAM_MEMBER_COUNT 
            or MyTeamMemberCount + self.PlayerId2TeamInfo[PlayerId].PlayerCnt > FriendConst.MAX_TEAM_MEMBER_COUNT then
            -- 满队 or 无法合并
            return false
        elseif self.PlayerId2TeamInfo[PlayerId].TeamId == MyTeamId then
            -- 已经进了自己队伍
            return false
        end
    end
    return true
end
----------------------------------------
--[[
    Msg = {
        repeated RecommendTeammateInfo RecommendTeammateList = 1; // 推荐列表
        int32 PageCount = 2;                                      // 推荐个数
        int32 LastIndex = 3;                                      // 该页最后一个元素的索引位置，用于分页
    }
    message RecommendTeammateInfo
    {
        int64 PlayerId = 1;         // 推荐组队队友PlayerId
        string PlayerName = 2;      // 推荐组队队友名字
        PLAYER_STATE PlayerState = 3; // 玩家状态
        RECOMMEND_TEAM_SOURCE RecommendSource = 4;      // 推荐来源
    }
]]
function RecommendModel:SaveRecommendTeammateList(Msg)
    local List = Msg.RecommendTeammateList
    local IsSameList = self.RecommendTeammateList and #self.RecommendTeammateList == #List
    for I = 1,#List do
        local RecommendTeammateInfo = List[I]
        local PlayerState = {
            Status = RecommendTeammateInfo.PlayerState,
            DetailStatus = {},
            DisplayStatus = "",
        }
        RecommendTeammateInfo.PlayerState = PlayerState
        if IsSameList and self.RecommendTeammateList and self.RecommendTeammateList[I].PlayerId ~= RecommendTeammateInfo.PlayerId then
            IsSameList = false
        end
    end
    if IsSameList then
        -- 如果列表与缓存一致，无需触发后续逻辑
        CWaring("RecommendModel:SaveRecommendTeammateList Get SameList")
            self:DoUpdateShowList()
        return false
    end 
    self.RecommendTeammateList = List
    -- 重置特殊展示列表
    self.SpecialShowList = {}
    self.SpecialRecommendLastIndex = 0
    local ConfigPageCount = self:GetConfigPageCount()
    if #List < ConfigPageCount then
        -- 当前数据不满一页了，重置索引下次重头开始请求
        self:ResetLastIndex()
    else
        self.LastReqIndex = Msg.LastIndex 
    end
    self:InitStateList()
    self:UpdateShowList(true)
    return true
end

-- IsAll：用于控制外部列表刷新后是否需要滚动回顶部
function RecommendModel:UpdateShowList(IsAll)
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local List = self.RecommendTeammateList
    self.ShowList = {}
    self.ShowPlayerId2Index = {}
    for Index = 1, #List do
        local RecommendTeammateInfo = List[Index]
        if self:CheckCanShow(RecommendTeammateInfo) then
            self.ShowList[#self.ShowList + 1] = RecommendTeammateInfo
            self.ShowPlayerId2Index[RecommendTeammateInfo.PlayerId] = #self.ShowList
        end
    end
    CWaring(StringUtil.FormatSimple("RecommendModel:UpdateShowList DataListLength = {0} ShowListLength = {1}",#List,#self.ShowList))
    if #List > 0 and #self.ShowList == 0 then
        -- 当前页内，数据没有可展示的
        MvcEntry:GetCtrl(RecommendCtrl):ReqRecommendTeammateListInner()
    else
        self:DoUpdateShowList(IsAll)
    end
end

-- IsAll：用于控制外部列表刷新后是否需要滚动回顶部
function RecommendModel:DoUpdateShowList(IsAll)
    self.RequestingInner = false
    self:UpdateSpecialShowList()
    self:DispatchType(RecommendModel.ON_RECOMMEND_SHOW_LIST_UPDATED,IsAll)
end

-- 获得新列表的时候，初始化一遍玩家状态
function RecommendModel:InitStateList()
    local OldStateList = self.RecommendTeammateStateList
    self.RecommendTeammateStateList = {}
    self.CheckStateIdList = {}
    self.CheckStateIdMap = {}
    self.PlayerId2TeamInfo = {}
    self.CheckTeamStatePlayerIdList = {}
    self:ClearCacheData()
    local List = self.RecommendTeammateList
    for Index = 1, #List do
        local RecommendTeammateInfo = List[Index]
        local PlayerId = RecommendTeammateInfo.PlayerId
        local PlayerState = RecommendTeammateInfo.PlayerState
        self.RecommendTeammateStateList[PlayerId] = OldStateList[PlayerId] or PlayerState
        self.CheckStateIdList[#self.CheckStateIdList + 1] = PlayerId
        self.CheckStateIdMap[PlayerId] = 1
        if PlayerState.Status > Pb_Enum_PLAYER_STATE.PLAYER_LOBBY then
            -- 需要查询队伍的
            self.PlayerId2TeamInfo[PlayerId] = {TeamId = 0}
            self.CheckTeamStatePlayerIdList[#self.CheckTeamStatePlayerIdList + 1] = PlayerId
        end
    end
end

--[[
    更新玩家状态
    map<int64, PlayerState> StatusInfoList = 1;    // 玩家PlayerId列表的状态
    StatusInfoList 这个列表中的ID，都是独立显示成Item的ID。如果有状态导致不能作为独立Item显示，或者本来合并在其他item中，现在需要变成独立item显示，需要刷新列表
]]
function RecommendModel:UpdatePlayerState(StatusInfoList)
    -- local IsRecommendPlayerStatus = true
    -- for PlayerId, PlayerState in pairs(StatusInfoList) do
    --     -- 检测收到的状态列表是否是推荐列表的玩家的状态
    --     if not self.CheckStateIdMap[PlayerId] then
    --         IsRecommendPlayerStatus = false
    --         break
    --     end
    -- end
    -- if not IsRecommendPlayerStatus then
    --     return
    -- end
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local NeedUpdateShowList = false
    local UpdateReason = ""
    local MaxTeamPlayerCnt = FriendConst.MAX_TEAM_MEMBER_COUNT
    self.CheckTeamStatePlayerIdList = {}    -- 需要查询队伍信息的Id列表
    for PlayerId, PlayerState in pairs(StatusInfoList) do
        PlayerId = tonumber(PlayerId)
        if self.CheckStateIdMap[PlayerId] then
            local OldState = self.RecommendTeammateStateList[PlayerId]
            if OldState then
                if not NeedUpdateShowList and
                    ((OldState.Status == Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE and PlayerState.Status ~= Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE) 
                    or(OldState.Status ~= Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE and PlayerState.Status == Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE) -- 离线状态变化
                    or(OldState.Status >= Pb_Enum_PLAYER_STATE.PLAYER_MATCH and PlayerState.Status < Pb_Enum_PLAYER_STATE.PLAYER_MATCH)
                    or(OldState.Status < Pb_Enum_PLAYER_STATE.PLAYER_MATCH and PlayerState.Status >= Pb_Enum_PLAYER_STATE.PLAYER_MATCH)) -- 匹配、战斗状态变化
                then
                    -- 离线了或者进战斗了 需要从列表去掉
                    UpdateReason = "Offline Or InMatch, Need Remove"
                    NeedUpdateShowList = true
                end
                
                self.RecommendTeammateStateList[PlayerId] = PlayerState
                if PlayerState.Status > Pb_Enum_PLAYER_STATE.PLAYER_LOBBY then
                    
                    -- 需要查询队伍的
                    local NeedQueryTeam = false
                    if not TeamModel:IsSelfTeamMember(PlayerId) then
                        if not self.PlayerId2TeamInfo[PlayerId] then
                            self.PlayerId2TeamInfo[PlayerId] = {TeamId = 0}
                            NeedQueryTeam = true
                        elseif self.PlayerId2TeamInfo[PlayerId].TeamId > 0 and self.PlayerId2TeamInfo[PlayerId].PlayerCnt < MaxTeamPlayerCnt then
                            NeedQueryTeam = true
                        end
                    end
                    if NeedQueryTeam then
                        self.CheckTeamStatePlayerIdList[#self.CheckTeamStatePlayerIdList + 1] = PlayerId
                    end
                else
                    if self.TeamMemberRecord[PlayerId] or self.MyTeamMember[PlayerId] then
                        -- 之前是自己的队友，或者是其他玩家队友在其他Item中现在，现在变成单人状态，需要独立显示 需要添加回列表
                        UpdateReason = "Out Of Self Team Or Other's Team , Need Add"
                        NeedUpdateShowList = true
                    end
                    if self.PlayerId2TeamInfo[PlayerId] and self.PlayerId2TeamInfo[PlayerId].TeamId > 0 then
                        -- 如果曾经是队伍item记录者，退队了，需要把自己作为独立Item以及把原队伍刷成另一个Item
                        -- 退队了要把原来标记的队友标记都清除掉
                        local Members = self.PlayerId2TeamInfo[PlayerId].Members
                        for MemberId,Member in pairs(Members) do
                            MemberId = tonumber(MemberId)
                            if PlayerId ~= MemberId then
                                self.TeamMemberRecord[MemberId] = nil
                                self.TeamItemRefreshRecord[MemberId] = nil
                            end
                        end
                        UpdateReason = "Out Of Team Show Item, Need Add"
                        NeedUpdateShowList = true
                    end
                    -- 不查询队伍了，记录过的队伍信息要去掉
                    self.MyTeamMember[PlayerId] = nil
                    self.PlayerId2TeamInfo[PlayerId] = nil
                    self.TeamMemberRecord[PlayerId] = nil
                    self.TeamItemRefreshRecord[PlayerId] = nil
                    TeamModel:DeletePlayerIdInOtherTeam(PlayerId)

                end
                local Msg = {
                    PlayerId        = PlayerId,
                    PlayerStateInfo = PlayerState
                }
                self:DispatchType(RecommendModel.ON_PLAYER_STATE_UPDATE,Msg)
            end
        end
    end
    if NeedUpdateShowList then
        CWaring("RecommendModel:UpdatePlayerState NeedUpdateList For Reason : "..UpdateReason)
        self:UpdateShowList()
    end
end

--[[
    更新队伍信息
]]
function RecommendModel:UpdateTeamInfo(TeamInfo)
    local TargetId = TeamInfo.TargetId
    if not self.RecommendTeammateStateList[TargetId] then
        -- 不是推荐列表的队伍信息
        return
    end
    
    local NeedUpdateList = false
    local UpdateReason = ""
    local MyTeamId = MvcEntry:GetModel(TeamModel):GetTeamId()
    local TeamId = TeamInfo.TeamId
    if TeamId == MyTeamId then
        -- 进了自己队伍了
        if not self.MyTeamMember[TargetId] then
            self.MyTeamMember[TargetId] = true
            -- 不查询队伍了，记录过的队伍信息要去掉
            self.PlayerId2TeamInfo[TargetId] = nil
            self.TeamMemberRecord[TargetId] = nil
            self.TeamItemRefreshRecord[TargetId] = nil
            MvcEntry:GetModel(TeamModel):DeletePlayerIdInOtherTeam(TargetId)
            UpdateReason = "Enter Self Team"
            NeedUpdateList = true
        end
    else
        local TeamMemberCnt = TeamInfo.PlayerCnt
        local MaxTeamPlayerCnt = FriendConst.MAX_TEAM_MEMBER_COUNT
        local OldTeamMemberCnt = self.PlayerId2TeamInfo[TargetId] and self.PlayerId2TeamInfo[TargetId].PlayerCnt or 0
        if (OldTeamMemberCnt < MaxTeamPlayerCnt and TeamMemberCnt == MaxTeamPlayerCnt) 
            or (OldTeamMemberCnt == MaxTeamPlayerCnt and TeamMemberCnt < MaxTeamPlayerCnt)  -- 满队&非满队的转换
        then
            NeedUpdateList = true
            UpdateReason = "Full Team"
        end
        if self.PlayerId2TeamInfo[TargetId] then
            -- 组队状态下
            if self.TeamMemberRecord[TargetId] and self.TeamMemberRecord[TargetId] == TeamId then
                -- 已经有队伍信息把Target标记为自己的队友
                if not self.TeamItemRefreshRecord[TargetId] then
                    --[[
                        如果没有刷新标记，表示Target可能也是一个单独的Item展示;
                        避免两个Item展示了一样的队伍，清除自己的队伍记录信息（让自己不通过CheckCanShow，不展示），刷新列表，更改刷新标记位
                    ]] 
                    self.PlayerId2TeamInfo[TargetId] = nil
                    self.TeamItemRefreshRecord[TargetId] = true
                    NeedUpdateList = true
                    UpdateReason = "In Other Team"
                end
            else
                self.TeamMemberRecord[TargetId] = nil -- 可能之前和别人同队被记录，现在不同队了，清除记录
                -- 更新记录
                self.PlayerId2TeamInfo[TargetId] = TeamInfo
                local Members = TeamInfo.Members
                for PlayerId,Member in pairs(Members) do
                    PlayerId = tonumber(PlayerId)
                    if PlayerId ~= TargetId then
                        -- 标记下自己的队友，后面出现队友的队伍信息不做处理
                        self.TeamMemberRecord[PlayerId] = TeamId
                    end
                end
            end
        end
    end
    if NeedUpdateList then
        CWaring("RecommendModel:UpdateTeamInfo NeedUpdateList For Reason : "..UpdateReason)
        self:UpdateShowList()
    end
end

