--[[
    组队数据模型
]]
local super = MapModel;
local class_name = "TeamModel";

---@class TeamModel : MapModel
TeamModel = BaseClass(super, class_name);

TeamModel.ON_TEAM_INITED = "ON_TEAM_INITED" -- 队伍信息初始化
TeamModel.ON_CLEAN_PENDDING_LIST = "ON_CLEAN_PENDDING_LIST" -- 清除所有待定列表
TeamModel.ON_ADD_TEAM_MEMBER = "ON_ADD_TEAM_MEMBER" -- 队员成员增加
TeamModel.ON_DEL_TEAM_MEMBER = "ON_DEL_TEAM_MEMBER" -- 队员成员减少
TeamModel.ON_UPDATE_TEAM_MEMBER = "ON_UPDATE_TEAM_MEMBER"   -- 队员信息更新
TeamModel.ON_TEAM_INFO_CHANGED = "ON_TEAM_INFO_CHANGED" -- 队伍信息更新
TeamModel.ON_TEAM_LEADER_CHANGED = "ON_TEAM_LEADER_CHANGED" -- 队长变化
TeamModel.ON_TEAM_MEMBER_HERO_INFO_CHANGED = "ON_TEAM_MEMBER_HERO_INFO_CHANGED"   -- 队员选取英雄或皮肤变化
TeamModel.ON_TEAM_MEMBER_WEAPON_INFO_CHANGED = "ON_TEAM_MEMBER_WEAPON_INFO_CHANGED"   -- 队员选取武器或武器皮肤变化
TeamModel.ON_GET_OTHER_TEAM_INFO = "ON_GET_OTHER_TEAM_INFO" -- 获取到其他队伍信息
TeamModel.ON_DEL_OTHER_TEAM_INFO = "ON_DEL_OTHER_TEAM_INFO" -- 删除其他队伍信息
TeamModel.ON_SELF_JOIN_TEAM = "ON_SELF_JOIN_TEAM"   -- 自己加入队伍
TeamModel.ON_SELF_QUIT_TEAM = "ON_SELF_QUIT_TEAM"   -- 自己退出队伍（不包括单人队，真正意义上的退队）
TeamModel.ON_SELF_JOIN_TEAM_PRE = "ON_SELF_JOIN_TEAM_PRE"   -- 自己加入队伍（数据更新之前）
TeamModel.ON_SELF_QUIT_TEAM_PRE = "ON_SELF_QUIT_TEAM_PRE"   -- 自己退出队伍（数据更新之前）（不包括单人队，真正意义上的退队）
TeamModel.ON_SELF_SINGLE_IN_TEAM = "ON_SELF_SINGLE_IN_TEAM" -- 自己退出队伍 （变回单人，可能存在单人队）
TeamModel.ON_SELF_SINGLE_IN_TEAM_PRE = "ON_SELF_SINGLE_IN_TEAM_PRE" -- 自己退出队伍 （数据更新之前）（变回单人，可能存在单人队）
TeamModel.ON_TEAM_CHANGEMODE = "ON_TEAM_CHANGEMODE" --队员地图模式状态同步
TeamModel.ON_TEAM_MEMBER_PREPARE = "ON_TEAM_MEMBER_PREPARE" --队员准备状态同步
TeamModel.ON_CLOSE_TEAM_AND_CHAT_VIEW_BY_ACTION = "ON_CLOSE_TEAM_AND_CHAT_VIEW_BY_ACTION" --通过行为关闭界面

TeamModel.ON_NOTIFY_TEAM_AND_CHAT_IN_OR_OUT_BY_ACTION = "ON_NOTIFY_TEAM_AND_CHAT_IN_OR_OUT_BY_ACTION" --通知team_and_chat组件播放进入/退出动效

function TeamModel:__init()
    self:_dataInit()
end


function TeamModel:_dataInit()
    self:Clean()
    --参考 TeamInfoSync
    self.IsInited = false
    self.TeamInfoSync = {}  -- 自己队伍

    -- 他人队伍
    self.OtherPlayerId2TeamId = {}
    self.OtherTeamId2MembersId = {}
    self.OtherTeamInfoSync = {} -- 他人队伍信息 TeamId - TeamInfo
    -- self.TeamMemStandPositionMapping = {}

    -- 大厅队伍站位信息
    self.TeamStandTransform = 
    {
        -- 2 1 3 4 
        [1] = 
        {
        	Location = UE.FVector(-141, -50.0, 0.0),
		    Rotation = UE.FRotator(0, -20, 0),
        },
        [2] = 
        {
        	Location = UE.FVector(-90, -192, 0),
		    Rotation = UE.FRotator(0, -9, 0),
        },
        -- 自己的位置
        [3] = 
        {
        	Location = UE.FVector(0, 0, 0),
			Rotation = UE.FRotator(0, 0, 0),
        },
        [4] = 
        {
        	Location = UE.FVector(83, -42, 0),
		    Rotation = UE.FRotator(0, 14, 0),
        },
    }
    -- 大厅组队要求站位和位置索引的对应
    self.TeamStandIndex2PlayerId = {
        [1] = {Pos = 3},
        [2] = {Pos = 2},
        [3] = {Pos = 4},
        [4] = {Pos = 1}   
    }
    self.PlayerId2TeamStandIndex = {}

    self.SaveTips = nil

    self.TeamVoiceRoomName = nil

    self.UpdateSelfTeamInfoGap = 3 -- 轮询自己队伍信息间隔 /秒
end

--[[
    玩家登出时调用
]]
function TeamModel:OnLogout(data)
    TeamModel.super.OnLogout(self)
    self:CleanAutoCheckTimer()
    self:StopSelfTeamInfoQuery()
    self:_dataInit()
end

function TeamModel:OnPreEnterBattle()
    self:HandleAfterLeaveTeam()
end

function TeamModel:OnAfterBackToHall()
    self:HandleAfterJoinTeam()
end

--override
function TeamModel:GetData(PlayerId)
    if self.TeamInfoSync and self.TeamInfoSync.Members and self.TeamInfoSync.Members[PlayerId] then
        return self.TeamInfoSync.Members[PlayerId]
    end
    return nil
end

--override
function TeamModel:GetDataMap()
    if self.TeamInfoSync then
        return self.TeamInfoSync.Members
    end
    return nil
end

------------ 获取队伍信息相关接口 start ------------------
--[[
    获取队伍Id
]]
function TeamModel:GetTeamId(PlayerId)
    if not PlayerId or MvcEntry:GetModel(UserModel):IsSelf(PlayerId) or self:IsSelfTeamMember(PlayerId) then
        return self.TeamInfoSync.TeamId or 0
    else
        local TeamInfo = self:GetOtherTeamInfoByPlayerId(PlayerId)
        if TeamInfo then
            return TeamInfo.TeamId or 0
        end
    end
    return 0
end

---获取自己队伍的id
---@return number 自己当前队伍的id，如果没有队伍则返回 0
function TeamModel:GetMyTeamId()
    return self.TeamInfoSync.TeamId or 0
end

--[[
    获取队长Id
]]
function TeamModel:GetLeaderId(PlayerId)
    if not PlayerId or MvcEntry:GetModel(UserModel):IsSelf(PlayerId) or self:IsSelfTeamMember(PlayerId) then
        return self.TeamInfoSync.LeaderId or 0
    else
        local TeamInfo = self:GetOtherTeamInfoByPlayerId(PlayerId)
        if TeamInfo then
            return TeamInfo.LeaderId or 0
        end
    end
    return 0
end

--region --------- 队伍中的玩家状态 -----------
--  Pb_Enum_TEAM_MEMBER_STATUS.BATTLE       = 0, --// 游戏中
--	Pb_Enum_TEAM_MEMBER_STATUS.READY        = 1, --// 准备
--	Pb_Enum_TEAM_MEMBER_STATUS.UNREADY      = 2, --// 未准备
--	Pb_Enum_TEAM_MEMBER_STATUS.OFFLINE      = 3, --// 离线
--	Pb_Enum_TEAM_MEMBER_STATUS.SETTLE       = 4, --// 结算中
--	Pb_Enum_TEAM_MEMBER_STATUS.MATCH        = 5, --// 匹配中
--	Pb_Enum_TEAM_MEMBER_STATUS.CONNECTING   = 6, --// 意外掉线

--------------
--- 玩家自身 ---
--------------

---获取玩家在自己队伍中的状态信息
---参考 Pb_Enum_TEAM_MEMBER_STATUS
---@return number|nil
function TeamModel:GetMyTeamInfoStatus()    
    local MyPlayerInfo = self:GetMyTeamPlayerInfo()
    if not MyPlayerInfo or not next(MyPlayerInfo) then return nil end

    return MyPlayerInfo.Status
end

---Debug使用，外部请不要调用
---@param Status number 需要查询的枚举状态，参考 Pb_Enum_TEAM_MEMBER_STATUS
---@return string Status对应的状态
function TeamModel:Debug_StatusToString(Status)
    local state2String = {
        [Pb_Enum_TEAM_MEMBER_STATUS.BATTLE]      = G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamModel_Inbattle"),
        [Pb_Enum_TEAM_MEMBER_STATUS.READY]       = G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamModel_prepare"),
        [Pb_Enum_TEAM_MEMBER_STATUS.UNREADY]     = G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamModel_Notprepared"),
        [Pb_Enum_TEAM_MEMBER_STATUS.OFFLINE]     = G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamModel_beoffline"),
        [Pb_Enum_TEAM_MEMBER_STATUS.SETTLE]      = G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamModel_Beinthesettlement"),
        [Pb_Enum_TEAM_MEMBER_STATUS.MATCH]       = G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamModel_Matching"),
        [Pb_Enum_TEAM_MEMBER_STATUS.CONNECTING]  = G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamModel_Accidentaldisconnect")
    }
    return state2String[Status]
end

---Debug使用，外部请不要调用
---@return string 玩家当前在队伍中的状态
function TeamModel:Debug_GetMyTeamInfoStatusString()
    local Status = self:GetMyTeamInfoStatus()
    if not Status then return G_ConfigHelper:GetStrFromCommonStaticST("Lua_TeamModel_Unknownstate") end

    return self:Debug_StatusToString(Status)
end

---获取玩家在自己队伍中的状态信息是否为准备
------@return boolean 玩家在在自己队伍中的状态信息是否为准备
function TeamModel:IsMyTeamPlayerInfoStatusREADY()
    local MyTeamStatus = self:GetMyTeamInfoStatus()
    return MyTeamStatus == Pb_Enum_TEAM_MEMBER_STATUS.READY
end

---获取玩家在自己队伍中的状态信息是否为未准备
---@return boolean 玩家在在自己队伍中的状态信息是否为未准备
function TeamModel:IsMyTeamPlayerInfoStatusUNREADY()
    local MyTeamStatus = self:GetMyTeamInfoStatus()
    return MyTeamStatus == Pb_Enum_TEAM_MEMBER_STATUS.UNREADY
end

---获取传入的玩家id在他自己的队伍中的状态信息
---参考 Pb_Enum_TEAM_MEMBER_STATUS
---@param PlayerId number 需要获取的玩家id
---@return number|nil 玩家队伍状态
function TeamModel:GetTeamPlayerInfoStatus(PlayerId)
    local PlayerInfo = self:GetTeamPlayerInfo(PlayerId)
    if not PlayerInfo then return nil end
    return PlayerInfo.Status
end

---判断玩家自己的队伍中，是否所有队员都已经准备好了
---@return boolean 所有队员已准备完毕
function TeamModel:IsMyTeamAllMembersTeamPlayerInfoStatusREADY()
    local MembersDataList = self:GetMyTeamMembers()

    --遍历队伍中非队长的玩家，查看他们的状态是否是Ready态
    for _, Player in pairs(MembersDataList) do
        local IsCaptain = self:IsTeamCaptain(Player.PlayerId)
        CLog("[cw] " .. tostring(Player.PlayerName) .. "(" .. tostring(Player.PlayerId) .. "): IsCaptain: " .. tostring(IsCaptain) .. ", Status: " .. tostring(Player.Status) .. ", IsReady: " .. tostring(Player.Status == Pb_Enum_TEAM_MEMBER_STATUS.READY))
        if not IsCaptain and Player.Status ~= Pb_Enum_TEAM_MEMBER_STATUS.READY then
            return false
        end
    end

    return true
end

--endregion --------- 队伍中的玩家状态 -----------


---获取玩家在自己队伍中的玩家信息
---@return table|nil 玩家在他自己队伍中的信息，可能为空
function TeamModel:GetMyTeamPlayerInfo()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local PlayerId = UserModel:GetPlayerId()

    return self:GetTeamPlayerInfo(PlayerId)
end

---获取传入的玩家id在他自己的队伍中的队伍信息
---@param PlayerId number 需要获取的玩家id
---@return table|nil 玩家在他自己队伍中的信息，可能为空
function TeamModel:GetTeamPlayerInfo(PlayerId)
    local MembersDataList = self:GetTeamMembers(PlayerId)
    if not MembersDataList or not next(MembersDataList) then return nil end

    for _, PlayerInfo in pairs(MembersDataList) do
        if PlayerInfo.PlayerId == PlayerId then
            return PlayerInfo
        end
    end
    
    return nil
end

---获取玩家自己队伍的队员列表
---@return table 队员列表，可能为空表
function TeamModel:GetMyTeamMembers()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local PlayerId = UserModel:GetPlayerId()

    local MembersDataList = self:GetTeamMembers(PlayerId)
    return MembersDataList
end

--[[
    获取队伍成员列表
]]
function TeamModel:GetTeamMembers(PlayerId)
    if not PlayerId or MvcEntry:GetModel(UserModel):IsSelf(PlayerId) or self:IsSelfTeamMember(PlayerId) then
        if self.TeamInfoSync then
            return self.TeamInfoSync.Members or {}
        else
            return {}
        end
    else
        local TeamInfo = self:GetOtherTeamInfoByPlayerId(PlayerId)
        if TeamInfo then
            return TeamInfo.Members or {}
        end
    end
    return {}
end

function TeamModel:GetTeamMemberCount(PlayerId)
    if not PlayerId or MvcEntry:GetModel(UserModel):IsSelf(PlayerId) or self:IsSelfTeamMember(PlayerId) then
        if self.TeamInfoSync and self.TeamInfoSync.PlayerCnt then
            return self.TeamInfoSync.PlayerCnt
        end
    else
        local TeamInfo = self:GetOtherTeamInfoByPlayerId(PlayerId)
        if TeamInfo then
            return TeamInfo.PlayerCnt or 0
        end
    end
    return 0
end

---获取玩家自己队伍中的玩家数量(包括自己)
---单人队伍/未组队   返回 1
---组队，有一个队员  返回 2
---@return number 玩家自己队伍中的玩家数量(包括自己)
function TeamModel:GetMyTeamMemberCount()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local MyPlayerId = UserModel:GetPlayerId()

    if self:IsSelfInTeam() then
        return self:GetTeamMemberCount(MyPlayerId)
    else
        return 1
    end
end

--[[
    是否是队长
]]
function TeamModel:IsTeamCaptain(PlayerId)
    PlayerId = tonumber(PlayerId)
    if not PlayerId or MvcEntry:GetModel(UserModel):IsSelf(PlayerId) or self:IsSelfTeamMember(PlayerId) then
        if PlayerId then
            return self:IsSelfInTeam() and self.TeamInfoSync.LeaderId == PlayerId 
        else
            self:IsSelfTeamCaptain() 
        end
    else
        local TeamInfo = self:GetOtherTeamInfoByPlayerId(PlayerId)
        if TeamInfo then
            return TeamInfo.PlayerCnt and TeamInfo.PlayerCnt > 1 and TeamInfo.LeaderId == PlayerId
        end
    end
    return false
end

--[[ 
    玩家自身是不是队长
    IgnoreSingle: 无视单人队伍无感化（即不考虑队伍人数是否>1):
        目前使用此判断：取消邀请时，获取入队申请/合并申请列表时
]]
function TeamModel:IsSelfTeamCaptain(IgnoreSingle)
    if not IgnoreSingle and not self:IsSelfInTeam() then
        return false
    end
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    return self.TeamInfoSync and self.TeamInfoSync.LeaderId == MyPlayerId 
end

---判断玩家自己在队伍中是否是队员，即在队伍中且非队长
---如果想判断一个玩家是否在自己的队伍中，请使用 IsSelfTeamMember(PlayerId)
---@return boolean 在队伍中且为队员，不为队长
function TeamModel:IsSelfTeamNotCaptain()
    if not self:IsSelfInTeam() then
        return false
    end

    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    return self.TeamInfoSync and self.TeamInfoSync.LeaderId ~= MyPlayerId
end

--[[
    玩家是否在队伍中
]]
function TeamModel:IsInTeam(PlayerId)
    if not PlayerId or MvcEntry:GetModel(UserModel):IsSelf(PlayerId) or self:IsSelfTeamMember(PlayerId) then
        return self:IsSelfInTeam()
    else
        local TeamInfo = self:GetOtherTeamInfoByPlayerId(PlayerId)
        if TeamInfo then
            return TeamInfo.TeamId and TeamInfo.TeamId > 0 and TeamInfo.PlayerCnt and TeamInfo.PlayerCnt > 1 and TeamInfo.Members[PlayerId] ~= nil 
        end
    end
    return false
end

---判断玩家是否与自己在同一个队伍中(如果传入的PlayerId是玩家自己的，则返回true)
---@param PlayerId number 需要判断的玩家id
---@return boolean 玩家是否与自己在同一个队伍中
function TeamModel:IsInMyTeam(PlayerId)
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local MyPlayerId = UserModel:GetPlayerId()
    if MyPlayerId == PlayerId then return true end 
    
    local MyTeamMembers = self:GetMyTeamMembers()
    for _, teamPlayerInfo in pairs(MyTeamMembers) do
        if teamPlayerInfo.PlayerId == PlayerId then return true end
    end
    
    return false
end

--[[
    是否处于队伍状态（无感化单人队人数>1才算是队伍）
]]
function TeamModel:IsSelfInTeam()
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    if self.TeamInfoSync and self.TeamInfoSync.TeamId then
        return self.TeamInfoSync.TeamId > 0 and self.TeamInfoSync.PlayerCnt > 1  and self.TeamInfoSync.Members[MyPlayerId] ~= nil 
    end
    return false
end

-- 是否是自己的队员
function TeamModel:IsSelfTeamMember(PlayerId)
    if not self:IsSelfInTeam() then
        return false
    end
    return self:GetData(PlayerId)
end

-- 通过TeamId获取其他队伍信息
function TeamModel:GetTeamInfo(TeamId)
    if not TeamId or TeamId == 0 then
        return self.TeamInfoSync
    else
        return self.OtherTeamInfoSync[TeamId]
    end
end

-- 通过PlayerId获取其他队伍的信息
function TeamModel:GetOtherTeamInfoByPlayerId(PlayerId)
    local TargetTeamId = 0
    if self.OtherPlayerId2TeamId and self.OtherPlayerId2TeamId[PlayerId] then
        TargetTeamId = self.OtherPlayerId2TeamId[PlayerId]
    elseif self.OtherTeamId2MembersId then
        for TeamId,MemberIdMap in pairs(self.OtherTeamId2MembersId) do
            if MemberIdMap[PlayerId] then
                TargetTeamId = TeamId
                break
            end
        end
    end
    if self.OtherTeamInfoSync and self.OtherTeamInfoSync[TargetTeamId] then
        return self.OtherTeamInfoSync[TargetTeamId]
    end
    return nil
end

-- 获取队长的DsGroupId
function TeamModel:GetTeamCaptainDsGroupId()
    if not self.TeamInfoSync then
        return nil
    end
    local LeaderId = self.TeamInfoSync.LeaderId
    local LeaderInfo = self.TeamInfoSync.Members[LeaderId]
    if not LeaderInfo then
        CError("GetTeamCaptainDsGroupId Can't Get LeaderInfo For Id = "..LeaderId)
        return nil
    end
    return LeaderInfo.DsGroupId
end

-- 获取自己的DsGroupId
function TeamModel:GetSelfDsGroupId()
    if not self.TeamInfoSync then
        return nil
    end
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    local MyTeamInfo = self.TeamInfoSync.Members[MyPlayerId]
    if not MyTeamInfo then
        CError("GetSelfDsGroupId Can't Get MyTeamInfo For Id = "..MyPlayerId)
        return nil
    end
    return MyTeamInfo.DsGroupId
end
------------ 获取队伍信息相关接口 end   ------------------

-- 获取队员在大厅站位的位置
function TeamModel:GetTeamTransform(TeamMemPlayerId)
    local Pos= self:GetMemberHallPos(TeamMemPlayerId)
    if Pos > 0 and self.TeamStandTransform[Pos] then
        return self.TeamStandTransform[Pos]
    end
    return nil

    
end

-- 获取队员在大厅站位的位置序号
function TeamModel:GetMemberHallPos(TeamMemPlayerId)
    print("TeamModel:GetMemberHallPos",TeamMemPlayerId)
    local TargetIndex = self.PlayerId2TeamStandIndex[TeamMemPlayerId]
    if TargetIndex and self.TeamStandIndex2PlayerId[TargetIndex] then
        -- 查到记录直接返回
        return self.TeamStandIndex2PlayerId[TargetIndex].Pos
    end
    -- 没有记录，新取一个位置放入
    if MvcEntry:GetModel(UserModel):IsSelf(TeamMemPlayerId) then
        -- 自己默认取第一个位置（对应大厅3号位）
        self.TeamStandIndex2PlayerId[1].PlayerId = TeamMemPlayerId
        self.PlayerId2TeamStandIndex[TeamMemPlayerId] = 1
        return self.TeamStandIndex2PlayerId[1].Pos
    end
    if not self:GetData(TeamMemPlayerId) then
        CWaring("GetTeamTransform PlayerId Is not Member..")
        print_trackback()
        return 0
    end

    print_r(self.TeamStandIndex2PlayerId)
    -- 其他人从第二个位置开始选（顺序对应大厅 2-1-4）
    local FirstEmptyPosIndex = nil
    for Index = 2,#self.TeamStandIndex2PlayerId do
        local PosInfo = self.TeamStandIndex2PlayerId[Index]
        if (not PosInfo.PlayerId or PosInfo.PlayerId == 0) and not FirstEmptyPosIndex then
            -- 先记录可补位的空位，避免自己的位置在空位后面，提前放入了空位
            FirstEmptyPosIndex = Index
        elseif PosInfo.PlayerId and PosInfo.PlayerId == TeamMemPlayerId then
            self.TeamStandIndex2PlayerId[Index].PlayerId = TeamMemPlayerId
            self.PlayerId2TeamStandIndex[TeamMemPlayerId] = Index
            return PosInfo.Pos
        end 
    end
    -- 没有找到自己原先的位置，则放到空位
    if FirstEmptyPosIndex then
        self.TeamStandIndex2PlayerId[FirstEmptyPosIndex].PlayerId = TeamMemPlayerId
        self.PlayerId2TeamStandIndex[TeamMemPlayerId] = FirstEmptyPosIndex
        return self.TeamStandIndex2PlayerId[FirstEmptyPosIndex].Pos
    else
        CWaring("GetTeamTransform have no empty pos..")
        print_trackback()
        return 0
    end
end

-- 删除队员在大厅站位的位置（退队时）
function TeamModel:DelMemberTeamTransform(TeamMemPlayerId)
    print("TeamModel:DelMemberTeamTransform", TeamMemPlayerId)
    print_r(self.TeamStandIndex2PlayerId,"DelMemberTeamTransform Before")
    local Index = self.PlayerId2TeamStandIndex[TeamMemPlayerId] 
    if Index and Index > 1 then
        -- 自己的，第一个位置，不删
        if self.TeamStandIndex2PlayerId[Index] then
            self.TeamStandIndex2PlayerId[Index].PlayerId  = 0
        end
        self.PlayerId2TeamStandIndex[TeamMemPlayerId] = nil
    end
    print_r(self.TeamStandIndex2PlayerId,"DelMemberTeamTransform After")
end

-- 清空队员在大厅站位的位置（自己退队时）
function TeamModel:ClearTeamTransform()
    print("TeamModel:ClearTeamTransform")
    for Index = 2,#self.TeamStandIndex2PlayerId do
        if self.TeamStandIndex2PlayerId[Index] then
            self.TeamStandIndex2PlayerId[Index].PlayerId = 0
        end
    end
    self.PlayerId2TeamStandIndex = {}
end

--[[
    同步队伍信息
]]
function TeamModel:SetTeamInfo(TeamInfo)
    if not TeamInfo then
        return
    end
    local TargetId = TeamInfo.TargetId
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    if TargetId == 0 or TargetId == MyPlayerId then
        print_r(TeamInfo)
        ---@type NetProtoLogCtrl
        local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
        NetProtoLogCtrl:PrintNetProtoLog(Pb_Message.TeamInfoSync, "TeamInfo.Reason = " .. tostring(TeamInfo.Reason))
        
        if TeamInfo.Reason == Pb_Enum_TEAM_SYNC_REASON.SYNC_INVITE_LEAVE_TEAM then
            -- 本身在队伍中，被其他队伍邀请，加入新的队伍前，先静默退出自己队伍，需要特殊处理，清空大厅站位信息
            self:ClearTeamTransform()
            return
        end
        --PRE 事件处理
        --  检测自己是否变成单人队了。需要触发一些离队的逻辑
        local IsSingleTeam = false
        if self.TeamInfoSync.PlayerCnt and self.TeamInfoSync.PlayerCnt > 1 and
               not (TeamInfo and TeamInfo.TeamId and TeamInfo.TeamId > 0 and TeamInfo.PlayerCnt > 1) then   --这一行判断玩家是否不在队伍中
            IsSingleTeam = true
            self:DispatchType(TeamModel.ON_SELF_SINGLE_IN_TEAM_PRE)
            -- 处理离队后操作
            self:HandleAfterLeaveTeam()
        end
        
        -- 自己的队伍
        local OriTeamInfo = self.TeamInfoSync
        local OriPlayerCnt = OriTeamInfo and OriTeamInfo.PlayerCnt or 0
        self.TeamInfoSync = TeamInfo

        --同步队友准备状态
        self:UpdateTeamMembersStatus(OriTeamInfo) 

        local IsChangeTeamFromTeam = OriTeamInfo.TeamId and OriTeamInfo.TeamId > 0 
            and self.TeamInfoSync.TeamId and self.TeamInfoSync.TeamId > 0 
            and OriTeamInfo.TeamId ~= self.TeamInfoSync.TeamId
        if IsChangeTeamFromTeam then
            -- 换了队伍，经过了静默离队过程
            self:QuitTeamVoiceRoom()
        end
        
        --1 表示退队  2表示入队
        local SyncTypeId = FriendConst.TEAM_STATUS_SYNC_TYPE.NONE
        if self.TeamInfoSync.TeamId == 0 and OriTeamInfo.TeamId and OriTeamInfo.TeamId > 0 then
            SyncTypeId = FriendConst.TEAM_STATUS_SYNC_TYPE.QUIT
            self:DispatchType(TeamModel.ON_SELF_QUIT_TEAM_PRE)
        elseif OriTeamInfo.PlayerCnt and OriTeamInfo.PlayerCnt <= 1 and self:IsSelfInTeam() then
            SyncTypeId = FriendConst.TEAM_STATUS_SYNC_TYPE.JOIN
            self:DispatchType(TeamModel.ON_SELF_JOIN_TEAM_PRE)
        end
        
        -- 单人队的退队静默处理，不提示
        local IsSlient = OriPlayerCnt == 1 and TeamInfo.PlayerCnt == 0
        self:OnTeamModeSelSync(TeamInfo) --同步队友模式选择状态
        self:UpdateDatas(TeamInfo.Members,true,IsSlient)

        -- 当单人队伍变成多人队伍；或者从多人队伍，静默退队，进入另一个多人队伍，需要进入语音房间
        if (IsChangeTeamFromTeam or OriPlayerCnt <= 1) and TeamInfo.PlayerCnt > 1 then
            if OriPlayerCnt <= 1 then
                -- 当单人（未组队或单人队）向多人队伍状态变化的时候，服务器需要发一个触发请求
                MvcEntry:GetCtrl(TeamCtrl):SendTeamSingleChangeNotifyReq()
            end
            -- 处理进队后操作
            self:HandleAfterJoinTeam()
        end

        -- 队伍的邀请待定列表
        MvcEntry:GetModel(TeamInviteModel):SetDataListFromMap(TeamInfo.InviteList)
        -- 队伍的申请入队待定列表
        MvcEntry:GetModel(TeamRequestApplyModel):SetDataListFromMap(TeamInfo.ApplyList)
        -- 队伍收到的合并队伍待定列表
        MvcEntry:GetModel(TeamMergeApplyModel):SetDataListFromMap(TeamInfo.MergeRecvList)
        -- 队伍发出的合并队伍申请列表
        MvcEntry:GetModel(TeamMergeModel):SetDataListFromMap(TeamInfo.MergeSendList)

        if SyncTypeId == FriendConst.TEAM_STATUS_SYNC_TYPE.QUIT then
            -- 自己退出了队伍(不包含单人队的情况，这里单人队仍然视为有队伍)
            self:ClearTeamTransform()
            self:CleanPendingList()
            self:DispatchType(TeamModel.ON_SELF_QUIT_TEAM)
        elseif SyncTypeId == FriendConst.TEAM_STATUS_SYNC_TYPE.JOIN then
            -- 刚加入队伍，清除我发出的所有入队申请
            MvcEntry:GetModel(TeamRequestModel):Clean()
            self:DispatchType(TeamModel.ON_SELF_JOIN_TEAM)
        end
        -- 检测自己是否变成单人队了。需要触发一些离队的逻辑
        if IsSingleTeam then
            self:DispatchType(TeamModel.ON_SELF_SINGLE_IN_TEAM)
        end
        -- 队长变化
        local OriLeaderId = OriTeamInfo.LeaderId or 0
        if OriLeaderId ~= self.TeamInfoSync.LeaderId 
            or ((not OriTeamInfo.PlayerCnt or OriTeamInfo.PlayerCnt <= 1) and self.TeamInfoSync.PlayerCnt > 1) then
            local Param = {
                OldLeader = OriLeaderId,
                NewLeader = self.TeamInfoSync.LeaderId
            }
            self:DispatchType(TeamModel.ON_TEAM_LEADER_CHANGED, Param)
        end 

        if self.TeamInfoSync.TeamId > 0 then
            -- 自己加入了，查询过的队伍，需要将曾经查询的队伍信息删掉
            self:DeleteOtherTeamInfo(self.TeamInfoSync.TeamId)
        end
        
        if not self.IsInited then
            self.IsInited = true
            self:DispatchType(TeamModel.ON_TEAM_INITED)
        end

        self:DispatchType(TeamModel.ON_TEAM_INFO_CHANGED)
        self:ScheduleCheckNeedQuit()
    else
        -- 他人的队伍
        self.OtherTeamInfoSync = self.OtherTeamInfoSync or {}
        local TeamId = TeamInfo.TeamId
        self.OtherTeamInfoSync[TeamId] = TeamInfo
        if TeamInfo.PlayerCnt and TeamInfo.PlayerCnt == FriendConst.MAX_TEAM_MEMBER_COUNT then
            -- 队伍已满，清除本地向该队发过的入队申请
            if MvcEntry:GetModel(TeamRequestModel):GetData(TeamId) then
                MvcEntry:GetModel(TeamRequestModel):DeleteData(TeamId)
            end
        end
        local OriTeamId = self.OtherPlayerId2TeamId[TargetId]
        if OriTeamId and OriTeamId ~= TeamId and self.OtherTeamId2MembersId[OriTeamId] and self.OtherTeamId2MembersId[OriTeamId][TargetId] then
            -- 原来在别的队伍
            self.OtherTeamId2MembersId[OriTeamId][TargetId] = nil
            if table_isEmpty(self.OtherTeamId2MembersId[OriTeamId]) then
                -- 原来的队伍没人了 , 清除缓存
                self.OtherTeamId2MembersId[OriTeamId] = nil
                self.OtherTeamInfoSync[OriTeamId] = nil
            end
        end

        -- 需要先检测是否有已经不在队伍中的队员的缓存记录
        self.OtherTeamId2MembersId[TeamId] = self.OtherTeamId2MembersId[TeamId] or {}
        for PlayerId,_ in pairs(self.OtherTeamId2MembersId[TeamId]) do
            PlayerId = tonumber(PlayerId)
            if not TeamInfo.Members[PlayerId] then
                -- 已经不在队伍中了
                self.OtherTeamId2MembersId[TeamId][PlayerId] = nil
                self.OtherPlayerId2TeamId[PlayerId] = nil
            end
        end
        -- TargetId 不一定在TeamMember中，可能是通过TeamId返回的队伍信息。
        local TargetIsInTeam = false
        for PlayerId,TeamMember in pairs(TeamInfo.Members) do
            if PlayerId == TargetId then
                TargetIsInTeam = true
            end
            -- 建立队伍中每个成员 PlayerId和TeamId的映射
            self.OtherPlayerId2TeamId[PlayerId] = TeamId
            self.OtherTeamId2MembersId[TeamId][PlayerId] = 1
        end
        -- 如果TargetId不在队伍中，将TargetId置为0后再派发
        if not TargetIsInTeam then
            TeamInfo.TargetId = 0
        end
        -- 更新各个待定列表中的队伍信息
        -- 队伍收到的合并队伍待定列表
        MvcEntry:GetModel(TeamMergeApplyModel):OnGetOtherTeamInfo(TeamInfo)
        -- 队伍发出的合并队伍申请列表
        MvcEntry:GetModel(TeamMergeModel):OnGetOtherTeamInfo(TeamInfo)
        
        -- self.OtherTeamInfoSync[TargetId] = TeamInfo
        self:DispatchType(TeamModel.ON_GET_OTHER_TEAM_INFO,TeamInfo)
    end
end

--[[
    增量同步队伍信息
]]
function TeamModel:UpdateTeamInfo(TeamIncreInfo)
    print_r(TeamIncreInfo)
    if not self.TeamInfoSync then return end
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    local Reason = TeamIncreInfo.Reason
    local NeedCheckQuitTeam = false

    ---@type NetProtoLogCtrl
    local NetProtoLogCtrl = MvcEntry:GetCtrl(NetProtoLogCtrl)
    NetProtoLogCtrl:PrintNetProtoLog(Pb_Message.TeamIncreInfoSync, "TeamIncreInfo.Reason = " .. tostring(Reason))


    if Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_LEAVE_TEAM
    or Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_KICKED 
    or Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_NORMAL_LOGOUT 
    or Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_INVITE_LEAVE_TEAM then
    -- or Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_SILENT_LEAVE 
        -- 成员离队
        -- local IsSlient = Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_SILENT_LEAVE
        self:DelMember(TeamIncreInfo)
        NeedCheckQuitTeam = true
    elseif Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_MEMBER_NAME_CHANGE
        or Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_STATUS_CHANGE 
        or Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_NORMAL_LOGOUT 
        or Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_ON_LOGOUT then
        self:UpdateMember(TeamIncreInfo)
    elseif Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_LEADER_CHANGE then
        -- 队长变更
        local Param = {
            OldLeader = self.TeamInfoSync.LeaderId,
            NewLeader = TeamIncreInfo.TargetId
        }
        self.TeamInfoSync.LeaderId = TeamIncreInfo.TargetId
        self:DispatchType(TeamModel.ON_TEAM_LEADER_CHANGED, Param)
    elseif Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_HERO_CHANGE then
        -- 选取的 HeroId 或 HeroSkinId 发生变化
        if self.TeamInfoSync and self.TeamInfoSync.Members[TeamIncreInfo.TargetId] then
            self.TeamInfoSync.Members[TeamIncreInfo.TargetId].HeroId = TeamIncreInfo.Member.HeroId
            self.TeamInfoSync.Members[TeamIncreInfo.TargetId].HeroSkinId = TeamIncreInfo.Member.HeroSkinId
            self.TeamInfoSync.Members[TeamIncreInfo.TargetId].HeroSkinPartList = TeamIncreInfo.Member.HeroSkinPartList
        end
        if TeamIncreInfo.TargetId ~= MyPlayerId then
            self:DispatchType(TeamModel.ON_TEAM_MEMBER_HERO_INFO_CHANGED,TeamIncreInfo.Member)
        end
    elseif Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_WEAPON_CHANGE then
        -- 选取的 WeaponId 或 WeaponSkinId 发生变化
        if self.TeamInfoSync and self.TeamInfoSync.Members[TeamIncreInfo.TargetId] then
            self.TeamInfoSync.Members[TeamIncreInfo.TargetId].WeaponId = TeamIncreInfo.Member.WeaponId
            self.TeamInfoSync.Members[TeamIncreInfo.TargetId].WeaponSkinId = TeamIncreInfo.Member.WeaponSkinId
        end
        if TeamIncreInfo.TargetId ~= MyPlayerId then
            self:DispatchType(TeamModel.ON_TEAM_MEMBER_WEAPON_INFO_CHANGED,TeamIncreInfo.Member)
        end
    elseif Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_INVITE_LIST_CHANGE then
        -- 邀请列表发生变化
        MvcEntry:GetModel(TeamInviteModel):OnInviteListChange(TeamIncreInfo)
        NeedCheckQuitTeam = true
    elseif Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_APPLY_LIST_CHANGE then
        -- 申请列表发生变化
        MvcEntry:GetModel(TeamRequestApplyModel):OnRequestListChange(TeamIncreInfo)
        NeedCheckQuitTeam = true
    elseif Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_MERGE_REVC_LIST_CHANGE then
        -- 收到的合并列表发生变化
        MvcEntry:GetModel(TeamMergeApplyModel):OnMergeApplyListChange(TeamIncreInfo)
        NeedCheckQuitTeam = true
    elseif Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_MERGE_SEND_LIST_CHANGE then
        -- 发出的合并列表发生变化
        MvcEntry:GetModel(TeamMergeModel):OnMergeListChange(TeamIncreInfo)
        NeedCheckQuitTeam = true
    elseif Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_REQUEST_LIST_DEL_ALL then
        -- 清空 邀请列表 申请列表 合并列表
        self:CleanPendingList()
        NeedCheckQuitTeam = true
    elseif Reason == Pb_Enum_TEAM_INCRE_SYNC_REASON.INCRE_SYNC_MODE_CHANGE then
        -- body 模式选择同步
        self:OnTeamModeSelSync(TeamIncreInfo)
    end
    -- 以下暂未有相关处理
    -- INCRE_SYNC_SILENT_LEAVE 静默离队对于客户端是个中间态，暂无需做任何处理
    self:DispatchType(TeamModel.ON_TEAM_INFO_CHANGED)
    if NeedCheckQuitTeam then
        self:ScheduleCheckNeedQuit()
    end
end

-- 清空待定列表： 邀请列表 申请列表 合并列表
function TeamModel:CleanPendingList()
    MvcEntry:GetModel(TeamInviteModel):Clean()
    MvcEntry:GetModel(TeamRequestApplyModel):Clean()
    MvcEntry:GetModel(TeamMergeApplyModel):Clean()
    MvcEntry:GetModel(TeamMergeModel):Clean()
    self:DispatchType(TeamModel.ON_CLEAN_PENDDING_LIST)
end

-- 成员离队
function TeamModel:DelMember(TeamIncreInfo,IsSlient)
    if self.TeamInfoSync.Members and self.TeamInfoSync.Members[TeamIncreInfo.TargetId] then
        --PRE 事件处理
        local newCcount = self.TeamInfoSync.PlayerCnt - 1
        if newCcount == 1 then
            self:DispatchType(TeamModel.ON_SELF_SINGLE_IN_TEAM_PRE)
            self:HandleAfterLeaveTeam()
        end
        
        --真实处理
        self.TeamInfoSync.PlayerCnt = newCcount
        self:DelMemberTeamTransform(TeamIncreInfo.TargetId)
        -- 检测自己是否变成单人队了。需要触发一些离队的逻辑
        if self.TeamInfoSync.PlayerCnt == 1 then
            self:DispatchType(TeamModel.ON_SELF_SINGLE_IN_TEAM)
        end
        self.TeamInfoSync.Members[TeamIncreInfo.TargetId] = nil
        if self.TeamInfoSync.PlayerCnt == 0 then
            -- 最后一人离队，即单人队退出队伍。作为静默处理。不提示
            IsSlient = true
        end
        self:UpdateDatas(self.TeamInfoSync.Members,true,IsSlient)
    end
end

-- 成员信息变更
function TeamModel:UpdateMember(TeamIncreInfo)
    -- self:UpdateMemberStatus(TeamIncreInfo.Member)
    if self.TeamInfoSync.Members and self.TeamInfoSync.Members[TeamIncreInfo.TargetId] then
        local OriMember = self.TeamInfoSync.Members[TeamIncreInfo.TargetId]
        self.TeamInfoSync.Members[TeamIncreInfo.TargetId] = TeamIncreInfo.Member
        self:UpdateMemberStatus(OriMember, TeamIncreInfo.Member)
    end
end

--同步成员当前状态到各自RoomModel
function TeamModel:UpdateTeamMembersStatus(OriTeamInfo)
    if not self:IsSelfInTeam() then
        return
    end
    local CurMembers = self.TeamInfoSync.Members
    local OriMembers = OriTeamInfo.Members
    if not CurMembers or not OriMembers then
        return
    end
    for _, Member in pairs(CurMembers) do
        self:UpdateMemberStatus(OriMembers[Member.PlayerId], Member)
    end
end

function TeamModel:UpdateMemberStatus(OriMember,CurMember)
    if not OriMember then
        return
    end
    if OriMember.Status ~= CurMember.Status then
        CurMember.OldState = OriMember.Status   -- todo debug使用
        CLog(StringUtil.Format("UpdateTeamMembersStatus PlayerId = {0}, OldStatus = {1}, NewStatus = {2}",CurMember.PlayerId, OriMember.Status, CurMember.Status))
        self:DispatchType(TeamModel.ON_TEAM_MEMBER_PREPARE, CurMember) --我自己的Member信息
    end
end

---成员模式选择信息更新
---@param TeamIncreInfo table
function TeamModel:OnTeamModeSelSync(TeamIncreInfo)
    print_r(TeamIncreInfo, "[cw] OnTeamModeSelSync ====TeamIncreInfo")
    CLog("[cw] OnTeamModeSelSync TeamIncreInfo.GameplayId: " .. tostring(TeamIncreInfo.GameplayId))
    CLog("[cw] OnTeamModeSelSync TeamIncreInfo.LevelId: " .. tostring(TeamIncreInfo.LevelId))
    CLog("[cw] OnTeamModeSelSync TeamIncreInfo.View: " .. tostring(TeamIncreInfo.View))
    CLog("[cw] OnTeamModeSelSync TeamIncreInfo.TeamType: " .. tostring(TeamIncreInfo.TeamType))
    CLog("[cw] OnTeamModeSelSync TeamIncreInfo.IsCrossPlatform: " .. tostring(TeamIncreInfo.IsCrossPlatform))
    if self.TeamInfoSync.Members and self.TeamInfoSync.Members[TeamIncreInfo.TargetId] then        
        self.TeamInfoSync.Members[TeamIncreInfo.TargetId].GameplayId = TeamIncreInfo.GameplayId
        self.TeamInfoSync.Members[TeamIncreInfo.TargetId].LevelId = TeamIncreInfo.LevelId
        self.TeamInfoSync.Members[TeamIncreInfo.TargetId].View = TeamIncreInfo.View
        self.TeamInfoSync.Members[TeamIncreInfo.TargetId].TeamType = TeamIncreInfo.TeamType
    end

    --如果是退出队伍的话，则后台下发的数据就不可信了。退队的时候客户端会自己发送请求给服务器，这个时候如果服务器再同步数据，会尝试一系列的问题
    --玩家退队后会维持几秒的单人队，之后才会完全退队。此时服务器才会下发改变，如果用户在单人队的情况下，修改了模式，等服务器下发时，又会修改模式，就导致问题。
    --简而言之，当退队的时候，不使用服务器的数据。
    if TeamIncreInfo.TeamId == 0 and
            (TeamIncreInfo.Reason == Pb_Enum_TEAM_SYNC_REASON.SYNC_TEAM_DISMISS or TeamIncreInfo.Reason == Pb_Enum_TEAM_SYNC_REASON.SYNC_LEAVE_TEAM) then
        CLog("[cw] Player not in any team, do not need to update local match mode info")
        return
    end

    --服务器会下发 玩法模式id、关卡id、视角、队伍类型、跨平台匹配 这些数据，客户端判断是否可信，不可信则使用本地的默认值，可信则赋值
    --对新玩家来说 ModeId 默认是 0 如果回来的结果是空字符串都应该主动请求默认选择单排模式, 避免被回来的结果所覆盖造成污染
    if not TeamIncreInfo or not TeamIncreInfo.GameplayId or TeamIncreInfo.GameplayId == 0 or 
            not TeamIncreInfo.LevelId or TeamIncreInfo.LevelId == 0 or
            not TeamIncreInfo.View or TeamIncreInfo.View == "" or
            not TeamIncreInfo.TeamType or TeamIncreInfo.TeamType == "" then
        CLog("[cw] TeamIncreInfo.Reason: " .. tostring(TeamIncreInfo.Reason))
        CLog("[cw] OnTeamModeSelSync not TeamIncreInfo.GameplayId|LevelId|View|TeamType, try to set to default")
        ---@type MatchCtrl
        local MatchCtrl = MvcEntry:GetCtrl(MatchCtrl)
        MatchCtrl:ChangeMatchModeInfo()
        return
    end
    
    --走到这里说明排除了异常，可以给客户端赋值了
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    MatchModel:SetPlayModeId(TeamIncreInfo.GameplayId)
    MatchModel:SetTeamType(TeamIncreInfo.TeamType)
    MatchModel:SetPerspective(TeamIncreInfo.View)
    MatchModel:SetIsCrossPlatformMatch(TeamIncreInfo.IsCrossPlatform)
    MatchModel:SetLevelId(TeamIncreInfo.LevelId)    
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    MatchModel:SetModeId(MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(TeamIncreInfo.LevelId))
    MatchModel:SetSceneId(MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(TeamIncreInfo.LevelId))
end

--[[
    更新队伍信息
    -- IsSlient 是否静默（不触发弹出提示） 默认为false
]]
function TeamModel:UpdateDatas(map,fullCheck,IsSlient)
    local stateList, updateList = TeamModel.super.UpdateDatas(self, map,fullCheck)
    if stateList == nil or updateList == nil or not self.IsInited then 
        return 
    end
    
    --先处理删除
    for k, v in ipairs(stateList) do
        if v == EDataUpdateType.DELETE then  
            if not IsSlient then
                self:ShowExitTeamTips(updateList["DeleteMap"])
                self:DispatchType(TeamModel.ON_DEL_TEAM_MEMBER, updateList["DeleteMap"])
            end
            break
        end
    end

    for k, v in ipairs(stateList) do
        if v == EDataUpdateType.ADD then
            if self:IsSelfInTeam() then
                self:ShowJoinTeamTips(updateList["AddMap"])
            end
            -- 站位需要按照入队先后顺序
            table.sort(updateList["AddMap"],function (a,b)
                return a.v.JoinTime < b.v.JoinTime
            end)
            self:DispatchType(TeamModel.ON_ADD_TEAM_MEMBER, updateList["AddMap"])
        elseif v == EDataUpdateType.UPDATE then
            self:DispatchType(TeamModel.ON_UPDATE_TEAM_MEMBER, updateList["UpdateMap"])
        end
    end
end

-- 加入队伍提示
function TeamModel:ShowJoinTeamTips(AddList)
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    local ShowTipsList = {}
    for _,InfoMap in ipairs(AddList) do
        if InfoMap.k ~= MyPlayerId then
            -- 自己入队的时候，提示队伍其他成员，不包括自己
            ShowTipsList[#ShowTipsList + 1] = InfoMap
        end
    end
    self:ShowTeamTips(FriendConst.TEAM_SHOW_TIPS_TYPE.ADD,ShowTipsList)
end

-- 脱离队伍提示
function TeamModel:ShowExitTeamTips(DeleteList)
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    local ShowTipsList = {}
    for _,InfoMap in ipairs(DeleteList) do
        if InfoMap.k == MyPlayerId then
            -- 自己离队的时候，只提示自己
            ShowTipsList = {}
            ShowTipsList[#ShowTipsList + 1] = InfoMap
            break
        else
            ShowTipsList[#ShowTipsList + 1] = InfoMap
        end
    end
    self:ShowTeamTips(FriendConst.TEAM_SHOW_TIPS_TYPE.EXIT,ShowTipsList)
end

-- 弹队伍变动提示
function TeamModel:ShowTeamTips(Type,ShowTipsList,LeaderId)
    -- 不在局内才提示
    if not self:CanPopTeamTips() then
        return
    end
    local Param = {
        Type = Type
    }
--    local TipsViewId = ViewConst.TeamTipsSingle
   local TipsViewType = FriendConst.TEAM_NOTICE_ITEM_TYPE.SINGLE
    if #ShowTipsList > 1 then
        -- 多人
        -- TipsViewId = ViewConst.TeamTipsMulti
        TipsViewType = FriendConst.TEAM_NOTICE_ITEM_TYPE.MULTI
        Param.MemberList = ShowTipsList
        Param.LeaderId = LeaderId or self:GetLeaderId()
    else
        Param.Member = ShowTipsList[1]
    end
    Param.TipsViewType = TipsViewType
    MvcEntry:OpenView(ViewConst.TeamNoticeItemList,Param)
end

-- 拒绝 入队申请/合并队伍 提示
function TeamModel:ShowRejectApplyTips(TeamId)
    local TeamMembers = nil
    local LeaderId = 0
    if self.OtherTeamInfoSync and self.OtherTeamInfoSync[TeamId] then
        TeamMembers = self.OtherTeamInfoSync[TeamId].Members
        LeaderId = self.OtherTeamInfoSync[TeamId].LeaderId
    end
    if not TeamMembers then
        CWaring("ShowRejectApplyTips Can't get teamInfo for teamId = "..TeamId)
        return
    end
    local ShowTipsList = {}
    for PlayerId,Member in pairs(TeamMembers) do
        ShowTipsList[#ShowTipsList + 1] = {k = PlayerId,v = Member}
    end
    self:ShowTeamTips(FriendConst.TEAM_SHOW_TIPS_TYPE.REJECT_APPLY,ShowTipsList,LeaderId)
end

-- 好友状态发生了变化，检测是否需要去掉缓存队伍信息
function TeamModel:OnFriendStateUpdated(UpdateList)
    local List = {}
    for _,Vo in ipairs(UpdateList) do
        if Vo.PlayerState.Status == Pb_Enum_PLAYER_STATE.PLAYER_LOBBY then
            List[#List + 1] = Vo.PlayerId
        end
    end
    self:DeleteOtherTeamInfos(List)
end

--删除缓存的他人队伍信息
function TeamModel:DeleteOtherTeamInfo(DelTeamId)
    if not DelTeamId then
        return
    end
    self.OtherTeamInfoSync[DelTeamId] = nil
    self.OtherTeamId2MembersId[DelTeamId] = nil
    for PlayerId,TeamId in pairs(self.OtherPlayerId2TeamId) do
        if TeamId == DelTeamId then
            self.OtherPlayerId2TeamId[PlayerId] = nil
        end
    end
    self:DispatchType(TeamModel.ON_DEL_OTHER_TEAM_INFO,DelTeamId)
end

-- 不在队伍状态的PlayerId，如果有缓存的队伍信息，需要删除
function TeamModel:DeleteOtherTeamInfos(KeyList)
    if KeyList and #KeyList> 0 then
        for _,PlayerId in ipairs(KeyList) do
            self:DeletePlayerIdInOtherTeam(PlayerId)
        end
    end
end

-- 删除不在组队状态的玩家Id缓存
function TeamModel:DeletePlayerIdInOtherTeam(PlayerId)
    self.OtherPlayerId2TeamId[PlayerId] = nil
    for TeamId,MembersIdMap in pairs(self.OtherTeamId2MembersId) do
        if MembersIdMap[PlayerId] then
            MembersIdMap[PlayerId] = nil
            if table_isEmpty(MembersIdMap) then
                self.OtherTeamId2MembersId[TeamId] = nil
                self.OtherTeamInfoSync[TeamId] = nil
                self:DispatchType(TeamModel.ON_DEL_OTHER_TEAM_INFO,TeamId)
            end
            break
        end
    end
end

-- 10秒后检测是否需要自动离队
function TeamModel:ScheduleCheckNeedQuit()
    self:CleanAutoCheckTimer()
    self.CheckTimer = Timer.InsertTimer(10,function()
        self:CheckNeedQuitTeam()
	end)   
end

function TeamModel:CleanAutoCheckTimer()
    if self.CheckTimer then
        Timer.RemoveTimer(self.CheckTimer)
    end
    self.CheckTimer = nil
end

-- 检测是否需要自动离队
-- 人数为1 且 InviteList, ApplyList, MergeRecvList, MergeSendList 均为空的时候，需要离队
function TeamModel:CheckNeedQuitTeam()
    if not self.TeamInfoSync then
        return
    end
    if not self.TeamInfoSync.TeamId or self.TeamInfoSync.TeamId == 0 then
        return
    end
    if not self.TeamInfoSync.PlayerCnt or self.TeamInfoSync.PlayerCnt > 1 then
        return
    end
    if #MvcEntry:GetModel(TeamInviteModel):GetDataList() == 0 
        and #MvcEntry:GetModel(TeamInviteApplyModel):GetDataList() == 0 
        and #MvcEntry:GetModel(TeamRequestModel):GetDataList() == 0 
        and #MvcEntry:GetModel(TeamRequestApplyModel):GetDataList() == 0 
        and #MvcEntry:GetModel(TeamMergeApplyModel):GetDataList() == 0 
        and #MvcEntry:GetModel(TeamMergeModel):GetDataList() == 0  then
        MvcEntry:GetCtrl(TeamCtrl):SendTeamQuitReq()
    end
end

-- 判断是否全员离线
function TeamModel:CheckIsAllMemberOffline(Members)
    if not Members then
        return false
    end

    for _,Member in pairs(Members) do
        if Member.Status ~= Pb_Enum_TEAM_MEMBER_STATUS.CONNECTING and Member.Status ~= Pb_Enum_TEAM_MEMBER_STATUS.OFFLINE then
            return false
        end
    end
    return true
end

-- 生成一个按JoinTime排序的列表
function TeamModel:GetSortedMembersList(Members)
    if not Members then
        return
    end
    local List = {}
    for k, v in pairs(Members) do
		List[#List + 1] = {PlayerId = k, JoinTime = v.JoinTime}
	end
	-- 站位需要按照入队先后顺序
	table.sort(List, function(a,b)
		return a.JoinTime < b.JoinTime
	end)
    return List
end

-- 获取是否初始化队伍信息
function TeamModel:IsTeamInfoInited()
    return self.IsInited    
end

-- 能否弹各种交互提示
-- 不在局内 & 非匹配成功进入局内状态 & 好友数据初始化完成 才可以展示
function TeamModel:CanPopTeamTips()
    return 
    (not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle)
        and not MvcEntry:GetModel(MatchModel):IsMatchSuccessed()
        and MvcEntry:GetModel(FriendModel):IsInited()
        and MvcEntry:GetModel(NewSystemUnlockModel):IsSystemUnlock(ViewConst.FriendRequestItemList,false))
end
------------------ 进入/退出队伍状态后需要处理的事情 ------------------
function TeamModel:HandleAfterJoinTeam()
    CWaring("= TeamModel:HandleAfterJoinTeam")
    if not (self.TeamInfoSync and self.TeamInfoSync.PlayerCnt) or self.TeamInfoSync.PlayerCnt < 2 then
        return
    end
    -- 进入语音房间
    self:EnterTeamVoiceRoom()
    -- 开始轮询自己队伍信息
    self:StartUpdateSelfTeamInfoQuery()
end

function TeamModel:HandleAfterLeaveTeam()
    CWaring("= TeamModel:HandleAfterLeaveTeam")
    -- 退出语音房间
    self:QuitTeamVoiceRoom()
    -- 停止轮询自己队伍信息
    self:StopSelfTeamInfoQuery()
end

------------------ 小队语音 --------------------------

function TeamModel:GetTeamVoiceRoomName()
    return self.TeamVoiceRoomName   
end

-- 进入语音房间
function TeamModel:EnterTeamVoiceRoom()
    if not (self.TeamInfoSync and self.TeamInfoSync.PlayerCnt) or self.TeamInfoSync.PlayerCnt < 2 then
        return
    end
    
    if MvcEntry:GetModel(BanModel):IsBanningForType(Pb_Enum_BAN_TYPE.BAN_VOICE) then
        return
    end
   
    ---@type GVoiceModel
    local GVoiceModel = MvcEntry:GetModel(GVoiceModel)
    self.TeamVoiceRoomName = GVoiceModel:GetRoomNameByRoomId(tostring(self.TeamInfoSync.TeamId))
    ---@type GVoiceCtrl
    local GVoiceCtrl = MvcEntry:GetCtrl(GVoiceCtrl)
    if not self.TeamVoiceRoomName then
        GVoiceCtrl:SendProto_GetRtcTokenReq(self.TeamInfoSync.TeamId)
        return
    end
    local SelfUserId = GVoiceModel:GetSelfPlayerIdStr()
    local TheIsInRoom = GVoiceModel:IsUserIdInRoom(self.TeamVoiceRoomName,SelfUserId)
    if TheIsInRoom then
        -- UIAlert.Show("您已经在房间内了，无需重复加入")
        return
    end
    -- 先根据队长的DsGroupId，更新语音Url
    local CaptainDsGroupId = self:GetTeamCaptainDsGroupId()
    if CaptainDsGroupId then
        GVoiceCtrl:UpdateServerUrlForDSGroupId(CaptainDsGroupId)
    else
        CWaring("EnterTeamVoiceRoom Can't Get Leader DsGroupId, Cur Use Url = "..(GVoiceModel:GetServerUrl() or ""))
    end
    ---@type SystemMenuModel
    local SystemMenuModel = MvcEntry:GetModel(SystemMenuModel)
    local IsVoiceOpen = SystemMenuModel:GetVoiceSetting(SystemMenuConst.VoiceSettingType.VoiceIsOpen)
    GVoiceCtrl:SetIsAutoOpenSpeaker(IsVoiceOpen)
    GVoiceCtrl:SetIsAutoOpenMic(IsVoiceOpen and not SystemMenuModel:GetVoiceSetting(SystemMenuConst.VoiceSettingType.VoiceMode))
    GVoiceCtrl:JoinTeamRoom(self.TeamVoiceRoomName)
    GVoiceCtrl:SetKeyboardIsOpen(true)
end

-- 退出语音聊天房间
function TeamModel:QuitTeamVoiceRoom()
    if not self.TeamVoiceRoomName then
        return
    end
    ---@type GVoiceCtrl
    local GVoiceCtrl = MvcEntry:GetCtrl(GVoiceCtrl)
    GVoiceCtrl:EnableRoomMicrophone(self.TeamVoiceRoomName,false)
    GVoiceCtrl:EnableRoomSpeaker(self.TeamVoiceRoomName,false)
    GVoiceCtrl:QuitRoom(self.TeamVoiceRoomName)
    GVoiceCtrl:SetKeyboardIsOpen(false)
    MvcEntry:GetModel(SystemMenuModel):ClearSavedVolume()
    self.TeamVoiceRoomName = nil
end

------------------- 自己队伍信息轮询 --------------
-- 在组队状态时，起一个定时器轮询自己的队伍信息，用于弱网或丢包情况下，主动请求队伍信息概率能从其他链路拉取到信息，覆盖不能及时收到的推送
function TeamModel:StartUpdateSelfTeamInfoQuery()
    self:StopSelfTeamInfoQuery()
    if not (self.TeamInfoSync and self.TeamInfoSync.PlayerCnt) or self.TeamInfoSync.PlayerCnt < 2 then
        return
    end
    self.UpdateSelfTeamInfoTimer = Timer.InsertTimer(self.UpdateSelfTeamInfoGap,function ()
        MvcEntry:GetCtrl(TeamCtrl):SendUpdateTeamInfoReq()
    end,true)    
end

function TeamModel:StopSelfTeamInfoQuery()
    if self.UpdateSelfTeamInfoTimer then
        Timer.RemoveTimer(self.UpdateSelfTeamInfoTimer)
    end
    self.UpdateSelfTeamInfoTimer = nil
end

-- 轮询到自己的队伍信息
function TeamModel:OnQuerySelfTeamInfo(TeamInfo)
    if not TeamInfo then
        return
    end
    if not self.TeamInfoSync then
        return
    end
    --[[
        与本地缓存信息做对比，只有以下关键信息与本地不一致，会向本地信息覆盖以及同步客户端表现
        1. 队伍Id
        2. 队长Id
        3. 玩法和关卡Id
        4. 队员人数&Id
    ]]
    local IsNeedSync = false
    local SyncReason = ""
    if TeamInfo.TeamId ~= self.TeamInfoSync.TeamId then
        SyncReason = "TeamId"
        IsNeedSync = true
    elseif TeamInfo.LeaderId ~= self.TeamInfoSync.LeaderId then
        SyncReason = "LeaderId"
        IsNeedSync = true
    elseif TeamInfo.GameplayId ~= self.TeamInfoSync.GameplayId then
        SyncReason = "GameplayId"
        IsNeedSync = true
    elseif TeamInfo.LevelId ~= self.TeamInfoSync.LevelId then
        SyncReason = "LevelId"
        IsNeedSync = true
    else
        if TeamInfo.PlayerCnt ~= self.TeamInfoSync.PlayerCnt then
            SyncReason = "PlayerCnt"
            IsNeedSync = true
        else
            local NewMembers= TeamInfo.Members
            for PlayerId,NewMember in pairs(NewMembers) do
                if not self.TeamInfoSync.Members[PlayerId] then
                    SyncReason = "Member PlayerId: "..PlayerId
                    IsNeedSync = true
                    break
                end
            end
        end
    end

    if IsNeedSync then
        CWaring("== TeamModel:OnQuerySelfTeamInfo Need Do Sync For Reason = "..SyncReason)
        TeamInfo.TargetId = 0 -- 自己的队伍信息
        self:SetTeamInfo(TeamInfo)
    end
end

return TeamModel;