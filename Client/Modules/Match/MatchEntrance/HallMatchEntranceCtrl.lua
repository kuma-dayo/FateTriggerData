---
--- Ctrl 模块，主要用于处理协议
--- Description: 大厅匹配入口动效控制
--- Created At: 2023/06/29 19:04
--- Created By: 朝文
---

require("Client.Modules.Match.MatchEntrance.HallMatchEntranceModel")

local class_name = "HallMatchEntranceCtrl"
---@class HallMatchEntranceCtrl : UserGameController
---@field private model HallMatchEntranceModel
HallMatchEntranceCtrl = HallMatchEntranceCtrl or BaseClass(UserGameController, class_name)

function HallMatchEntranceCtrl:__init()
end

function HallMatchEntranceCtrl:Initialize()
end

---战斗后需要吧匹配成功的参数改回来，避免污染缓存
function HallMatchEntranceCtrl:OnPreEnterBattle()
    ---@type HallMatchEntranceModel
    local HallMatchEntranceModel = MvcEntry:GetModel(HallMatchEntranceModel)
    HallMatchEntranceModel:DataInit()
end

--从战斗返回大厅成功  重置一下组队状态
function HallMatchEntranceCtrl:OnAfterBackToHall()
    CLog("[cw][HallMatchEntranceCtrl]:OnAfterBackToHall")
    ---@type HallMatchEntranceModel
    local HallMatchEntranceModel = MvcEntry:GetModel(HallMatchEntranceModel)
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    --1.初始化数据
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    if HallMatchEntranceModel and MatchModel and TeamModel then
        local InitState = {
            TeamInfo = {
                isCaptain = not TeamModel:IsSelfInTeam() or TeamModel:IsSelfTeamCaptain(),
                isReady = MatchModel:GetIsPrepare()
            },
            MatchInfo = {
                isMatching = false,           --后续赋值
                isMatchingSuccess = false     --后续赋值
            }
        }
        HallMatchEntranceModel:StoreData(InitState) 
    end
end

function HallMatchEntranceCtrl:AddMsgListenersUser()
    self.MsgList = {
        --队伍数据
        { Model = TeamModel, MsgName = TeamModel.ON_TEAM_MEMBER_PREPARE,	Func = self.ON_TEAM_MEMBER_PREPARE_func },  --队员组队状态变动
        { Model = TeamModel, MsgName = TeamModel.ON_TEAM_LEADER_CHANGED,	Func = self.ON_TEAM_LEADER_CHANGED_func },  --队长变化
        { Model = TeamModel, MsgName = TeamModel.ON_SELF_SINGLE_IN_TEAM_PRE,Func = self.ON_SELF_SINGLE_IN_TEAM_PRE_func },  --自己退出队伍 （数据更新之前）（变回单人，可能存在单人队）
        { Model = TeamModel, MsgName = TeamModel.ON_SELF_SINGLE_IN_TEAM,	Func = self.ON_SELF_SINGLE_IN_TEAM_func },  --自己退出队伍 （变回单人，可能存在单人队）
        { Model = TeamModel, MsgName = TeamModel.ON_SELF_JOIN_TEAM,	        Func = self.ON_SELF_JOIN_TEAM_func },       --自己加入队伍

        --匹配状态数据
        { Model = MatchModel, MsgName = MatchModel.ON_MATCHING_STATE_CHANGE,Func = self.ON_MATCHING_STATE_CHANGE_func },--匹配状态变动        
    }
end

-- 队员组队状态变动回调
function HallMatchEntranceCtrl:ON_TEAM_MEMBER_PREPARE_func(InMemberInfo)
    CLog("[cw][HallMatchEntranceCtrl]:ON_TEAM_MEMBER_PREPARE_func(" .. string.format("%s", InMemberInfo) .. ")")
    --0.判空保护
    if not InMemberInfo then return end

    --1.非玩家自己的信息不处理
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local MyPlayerId = UserModel:GetPlayerId()
    if InMemberInfo.PlayerId ~= MyPlayerId then return end

    ---TODO: 目前还有点问题，先保留log打印，后续可以去掉
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    CLog("[cw][HallMatchEntranceCtrl]: " .. tostring(InMemberInfo.PlayerName) .. ": " .. 
            tostring(InMemberInfo.OldState) .. "(" .. tostring(TeamModel:Debug_StatusToString(InMemberInfo.OldState)) .. 
            ") -> " .. tostring(InMemberInfo.Status) .."(" .. tostring(TeamModel:Debug_StatusToString(InMemberInfo.Status)) .. ")") 
    print_r(InMemberInfo, "[cw][HallMatchEntranceCtrl] InMemberInfo")
    
    --2.单人队伍不信任数据
    if not TeamModel:IsSelfInTeam() then CLog("[cw][HallMatchEntranceCtrl] not in team(TeamCount==1), do not trust status(" .. tostring(InMemberInfo.Status) .. ")") return end
    
    --3.更新数据
    ---@type HallMatchEntranceModel
    local HallMatchEntranceModel = MvcEntry:GetModel(HallMatchEntranceModel)
    if InMemberInfo.Status == Pb_Enum_TEAM_MEMBER_STATUS.READY then
        HallMatchEntranceModel:UpdateNextAnimData(true, nil, false)
    elseif InMemberInfo.Status == Pb_Enum_TEAM_MEMBER_STATUS.UNREADY then
        HallMatchEntranceModel:UpdateNextAnimData(false, nil, false)
    elseif InMemberInfo.Status == Pb_Enum_TEAM_MEMBER_STATUS.MATCH then
        HallMatchEntranceModel:UpdateNextAnimData(nil, nil, true)
    end
end

-- 队长变化
function HallMatchEntranceCtrl:ON_TEAM_LEADER_CHANGED_func(Param)
    CLog("[cw][HallMatchEntranceCtrl]: HallMatchEntranceCtrl:ON_TEAM_LEADER_CHANGED_func()")

    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    if not TeamModel:IsSelfInTeam() then CLog("[cw][HallMatchEntranceCtrl] play self not in team") return end
    print_r(Param, "[cw][HallMatchEntranceCtrl] Param")

    ---@type TeamCtrl
    local TeamCtrl = MvcEntry:GetCtrl(TeamCtrl)
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local PlayerId = UserModel:GetPlayerId()
    local isBeforeTeamCaptain = Param.OldLeader == PlayerId
    local isAfterTeamCaptain = Param.NewLeader == PlayerId
    ---@type HallMatchEntranceModel
    local HallMatchEntranceModel = MvcEntry:GetModel(HallMatchEntranceModel)

    --单人 -> 队长
    if Param.OldLeader == 0 and isAfterTeamCaptain then
        --变成队长后需要改变准备状态为准备
        TeamCtrl:ChangeMyTeamMemberStatusToReady()
        CLog("[cw][HallMatchEntranceCtrl]: HallMatchEntranceCtrl Solo -> Captain")
        HallMatchEntranceModel:UpdateNextAnimData(true, true)

    --队长 -> 队员
    elseif isBeforeTeamCaptain and not isAfterTeamCaptain then
        CLog("[cw][HallMatchEntranceCtrl]: HallMatchEntranceCtrl Captain -> Teammate")
        HallMatchEntranceModel:UpdateNextAnimData(nil, false)

    --队员 -> 队长
    elseif not isBeforeTeamCaptain and isAfterTeamCaptain then
        --变成队长后需要改变准备状态为准备
        TeamCtrl:ChangeMyTeamMemberStatusToReady()
        CLog("[cw][HallMatchEntranceCtrl]: HallMatchEntranceCtrl Teammate -> Captain")
        HallMatchEntranceModel:UpdateNextAnimData(true, true)

    --队长入队
    elseif isBeforeTeamCaptain and isAfterTeamCaptain then
        CLog("[cw][HallMatchEntranceCtrl]: HallMatchEntranceCtrl ? -> Captain")
        HallMatchEntranceModel:UpdateNextAnimData(true, true)

    --队员入队 如果旧队长ID为0才是入队
    elseif not isBeforeTeamCaptain and not isAfterTeamCaptain and Param.OldLeader == 0 then
        CLog("[cw][HallMatchEntranceCtrl]: HallMatchEntranceCtrl ? -> Teammate")
        HallMatchEntranceModel:UpdateNextAnimData(true, false, false)
        
    end
end

---退队数据更新之前
function HallMatchEntranceCtrl:ON_SELF_SINGLE_IN_TEAM_PRE_func()
    CLog("[cw][HallMatchEntranceCtrl]: ON_SELF_SINGLE_IN_TEAM_PRE_func()")
    ---@type HallMatchEntranceModel
    local HallMatchEntranceModel = MvcEntry:GetModel(HallMatchEntranceModel)
    HallMatchEntranceModel:UpdateNextAnimData(true, true, false)
end

---退队
function HallMatchEntranceCtrl:ON_SELF_SINGLE_IN_TEAM_func()
    CLog("[cw][HallMatchEntranceCtrl]:ON_SELF_SINGLE_IN_TEAM_func()")
    ---@type HallMatchEntranceModel
    local HallMatchEntranceModel = MvcEntry:GetModel(HallMatchEntranceModel)
    HallMatchEntranceModel:UpdateNextAnimData(true, true, false)
end

---加入队伍
function HallMatchEntranceCtrl:ON_SELF_JOIN_TEAM_func()
    CLog("[cw][HallMatchEntranceCtrl]:ON_SELF_JOIN_TEAM_func()")
    ---@type HallMatchEntranceModel
    local HallMatchEntranceModel = MvcEntry:GetModel(HallMatchEntranceModel)
    HallMatchEntranceModel:UpdateNextAnimData(true, nil, false)
end

---匹配状态变动处理
function HallMatchEntranceCtrl:ON_MATCHING_STATE_CHANGE_func(Msg)
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    MatchModel:Debug_GetMatchStateString()
    
    local OldMatchState = Msg.OldMatchState
    local NewMatchState = Msg.NewMatchState
    CLog("[cw][HallMatchEntranceCtrl]:ON_MATCHING_STATE_CHANGE_func(" .. tostring(OldMatchState) .. "(" .. tostring(MatchModel:Debug_MatchState2String(OldMatchState)) .. ")" ..
            " -> " .. tostring(NewMatchState) .. "(" .. tostring(MatchModel:Debug_MatchState2String(NewMatchState)) .. "))")

    ---@type HallMatchEntranceModel
    local HallMatchEntranceModel = MvcEntry:GetModel(HallMatchEntranceModel)
    --1.无匹配状态
    local MatchState = MatchModel.Enum_MatchState
    if NewMatchState == MatchState.MatchIdle then
        HallMatchEntranceModel:UpdateNextAnimData(nil, nil, false, false)

    --2.请求匹配中
    elseif NewMatchState == MatchState.MatchRequesting then
        --do nothing special

    --3.匹配中
    elseif NewMatchState == MatchState.Matching then
        HallMatchEntranceModel:UpdateNextAnimData(nil, nil, true, false)       

    --4.匹配成功
    elseif NewMatchState == MatchState.MatchSuccess then
        HallMatchEntranceModel:UpdateNextAnimData(nil, nil, nil, true)

    --5.匹配失败
    elseif NewMatchState == MatchState.MatchFail then
        HallMatchEntranceModel:UpdateNextAnimData(nil, nil, false,false)

    --6.匹配取消了
    elseif NewMatchState == MatchState.MatchCanceled then
        HallMatchEntranceModel:UpdateNextAnimData(nil, nil, false)
        
    end
end
