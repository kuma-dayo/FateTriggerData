---
--- Model 模块，用于数据存储与逻辑运算
--- Description: 大厅匹配入口
--- Created At: 2023/05/09 15:32
--- Created By: 朝文
---

require("Client.Modules.Match.MatchModeSelect.MatchModeSelectModel")

local MatchConst = require("Client.Modules.Match.MatchConst")
local super = GameEventDispatcher
local class_name = "MatchModel"
---@class MatchModel : GameEventDispatcher
MatchModel = BaseClass(super, class_name)


--region -------------------- 事件 --------------------
--状态变化
MatchModel.ON_MATCH_IDLE        = "ON_MATCH_IDLE"           --无匹配
MatchModel.ON_MATCH_REQUESTING  = "ON_MATCH_REQUESTING"     --请求匹配
MatchModel.ON_MATCHING          = "ON_MATCHING"             --匹配回包，且开始匹配
MatchModel.ON_MATCH_CANCELED    = "ON_MATCH_CANCELED"       --匹配取消了
MatchModel.ON_MATCH_SUCCESS     = "ON_MATCH_SUCCESS"        --匹配成功
MatchModel.ON_MATCH_FAIL        = "ON_MATCH_FAIL"           --匹配失败

MatchModel.ON_DS_ERROR          = "ON_DS_ERROR"             --DS相关有报错导致进入不了
MatchModel.ON_CONNECT_DS_SERVER = "ON_CONNECT_DS_SERVER"    --请求链接DS服务器

--数据变化
MatchModel.ON_BATTLE_SEVER_CHANGED  = "ON_BATTLE_SEVER_CHANGED"     --大厅选择的战斗服务器发生了变化
MatchModel.ON_PLAY_MODE_ID_CHANGED  = "ON_PLAY_MODE_ID_CHANGED"     --玩法模式ID(PlayModeId)发生了变化
MatchModel.ON_PERSPECTIVE_CHANGED   = "ON_PERSPECTIVE_CHANGED"      --视角(Perspective)发生了变化
MatchModel.ON_TEAM_TYPE_CHANGED     = "ON_TEAM_TYPE_CHANGED"        --队伍类型(TeamType)发生了变化
MatchModel.ON_LEVEL_ID_CHANGED      = "ON_LEVEL_ID_CHANGED"         --关卡ID(LevelId)发生了变化
MatchModel.ON_SCENE_ID_CHANGED      = "ON_SCENE_ID_CHANGED"         --场景ID(SceneId)发生了变化
MatchModel.ON_MODE_ID_CHANGED       = "ON_MODE_ID_CHANGED"          --模式ID(ModeId)发生了变化
MatchModel.ON_FILL_TEAM_CHANGED     = "ON_FILL_TEAM_CHANGED"        --补满队伍(FillTeam)发生变化
MatchModel.ON_CROSS_PLATFORM_MATCH_CHANGED  = "ON_CROSS_PLATFORM_MATCH_CHANGED"     --跨平台匹配(CrossPlatformMatch)发生变化
--DS相关
MatchModel.ON_MATCHING_STATE_CHANGE = "ON_MATCHING_STATE_CHANGE"    --匹配状态发生改变
MatchModel.ON_BATTLE_MAP_LOAED = "ON_BATTLE_MAP_LOAED"              --战斗地图加载完成
MatchModel.ON_GAMEMATCH_DSMETA_SYNC = "ON_GAMEMATCH_DSMETA_SYNC"    --匹配成功之后DS信息同步成功（表示客户端可以Travel进游戏了）
--endregion -------------------- 事件 --------------------

MatchModel.Const = {
    MAX_MATCHING_TIMEOUT = 45,  --匹配最长时间，超过这个时间客户端会发送取消匹配请求
}

--客户端自己维护的一套匹配状态，用于 UI 显示
MatchModel.Enum_MatchState = {
    MatchIdle       = 1,    --等待匹配
    MatchRequesting = 2,    --发送匹配请求中
    Matching        = 3,    --匹配请求收到后，匹配中
    MatchCanceled   = 4,    --匹配取消
    MatchSuccess    = 5,    --匹配成功
    MatchFail       = 6,    --匹配失败
}


function MatchModel:__init()    
    ---@type UserModel
    self.UserModel = MvcEntry:GetModel(UserModel)
    ---@type TeamModel
    self.TeamModel = MvcEntry:GetModel(TeamModel)    
    ---@type MatchModeSelectModel
    self.MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)    
end

function MatchModel:OnGameInit()
    --Debug使用字符串，无本地化
    MatchModel.MatchState2String = {
        [1] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModel_Waitingforamatch"),
        [2] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModel_Sendingmatchingreque"),
        [3] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModel_Afterthematchingrequ"),
        [4] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModel_Matchingisbeingcance"),
        [5] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModel_Matchingsucceeded"),
        [6] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "Lua_MatchModel_Matchingfailed"),
    }

    self:DataInit()
end

---初始化数据，用于第一次调用及登出的时候调用
function MatchModel:DataInit()
    local Const = MatchModeSelectModel.Const
    self.SeverId                = nil                                      --选择的战斗服务器id
    self.PlayModeId             = Const.DefaultSelectPlayModeId            --玩法模式id
    self.LevelId                = Const.DefaultSelectLevelId               --关卡id
    self.SceneId                = Const.DefaultSelectSceneId               --场景id
    self.ModeId                 = Const.DefaultSelectModeId                --模式Id
    self.Perspective            = Const.DefaultSelectPerspective           --视角（第三人称、第一人称）
    self.TeamType               = Const.DefaultSelectTeamType              --队伍类型（单排、双排、四排）
    self.IsCrossPlatformMatch   = Const.DefaultSelectCrossPlatformMatch    --跨平台匹配
    self.IsFillTeam             = Const.DefaultSelectFillTeam              --是补满队伍
    
    self.MatchState             = MatchModel.Enum_MatchState.MatchIdle     --匹配状态
    self.ReqDSInfoData          = nil                                      --缓存的DS信息
    self.SavedDsGroupId = 0 -- 当前记录的对局的DsGroupId
    self:CleanSynicMatchState()
end

---玩家登出时调用
function MatchModel:OnLogout(data)
    self:DataInit()
end

--lua.do local MatchModel = MvcEntry:GetModel(MatchModel); MatchModel:Debug_ShowMatchDetail()
---Debug使用，获得当前的状态
function MatchModel:Debug_ShowMatchDetail()
    local Msg = "ServerId: " .. self:GetSeverId() .. ", " ..
                    "PlayModeId: " .. self:GetPlayModeId() .. ", " ..
                    "Perspective: " .. self:GetPerspective() .. ", " ..
                    "TeamType: " .. self:GetTeamType() .. ", " ..
                    "LevelId: " .. self:GetLevelId() .. ", " ..
                    "ModeId: " .. self:GetModeId() .. ", " ..
                    "SceneId: " .. self:GetSceneId() .. ", " ..
                    "IsCrossPlatformMatch: " .. tostring(self:GetIsCrossPlatformMatch()) .. ", " ..
                    "IsFillTeam: " .. tostring(self:GetIsFillTeam()) .. ", " ..
                    "MatchState: " .. self:GetMatchState() .. "," ..
                    "IsPrepare: " .. tostring(self:GetIsPrepare()) .. "."
    UIMessageBox.Show({describe = Msg})
end

--region SynicMatchState

---封装一个设置 SynicMatchState 的方法, 用于设置 登录之后匹配状态
---@param newSynicMatchState number
function MatchModel:SetSyncMatchState(newSynicMatchState)
    if newSynicMatchState == nil then
        CError("[cw] MatchModel trying to set a nil value to SynicMatchState, if you wanna do it, please use CleanSynicMatchState() instead")
    end
    
    if self.SynicMatchState == newSynicMatchState then CLog("[cw] same SynicMatchState(" .. tostring(newSynicMatchState) .. ") with before, do nothing") return end
    self.SynicMatchState = newSynicMatchState
end

---封装一个获取 SynicMatchState 的方法，用于获取 登录之后匹配状态
---@return number
function MatchModel:TriggerSyncMatchStateChange()
    if not self.SynicMatchState then return end

    CLog("[cw] current self.SynicMatchState is " .. tostring(self.SynicMatchState))
    local SynicMatchState = self.SynicMatchState
    self:CleanSynicMatchState()
    
    if SynicMatchState == self.Enum_MatchState.MatchSuccess then
        self:SetMatchState(self.Enum_MatchState.Matching)    
    end
    self:SetMatchState(SynicMatchState)
end

---封装一个清空 SynicMatchState 的方法，用于去除 登录之后匹配状态
function MatchModel:CleanSynicMatchState()
    self.SynicMatchState = nil
end

--endregion SynicMatchState

--region SeverId

---封装一个设置 SeverId 的方法, 用于设置 大厅选择的战斗服务器id
---@param newSeverId number
function MatchModel:SetSeverId(newSeverId)
    if newSeverId == nil then
         CError("[cw] MatchModel trying to set a nil value to SeverId, if you wanna do it, please use CleanSeverId() instead")
    end

    if self.SeverId == newSeverId then CWaring("[cw] same SeverId(" .. tostring(newSeverId) .. "), do not need to update") return end

    CLog("[cw] SeverId changed form " .. tostring(self.SeverId) .. " to " .. tostring(newSeverId))
    self.SeverId = newSeverId

    self:DispatchType(MatchModel.ON_BATTLE_SEVER_CHANGED)
end

---封装一个获取 SeverId 的方法，用于获取 大厅选择的战斗服务器id
---@return number
function MatchModel:GetSeverId()
    return self.SeverId
end

---封装一个清空 SeverId 的方法，用于去除 大厅选择的战斗服务器id
function MatchModel:CleanSeverId()
    self.SeverId = nil
end

--endregion SeverId

--region PlayModeId

---封装一个设置 PlayModeId 的方法, 用于设置 玩法模式id
---@param newPlayModeId number
function MatchModel:SetPlayModeId(newPlayModeId)
    if not newPlayModeId then
         CError("[cw] MatchModel trying to set a nil value to PlayModeId, if you wanna do it, please use CleanPlayModeId() instead")
    end

    if self.PlayModeId == newPlayModeId then CWaring("[cw] same PlayModeId(" .. tostring(newPlayModeId) .. "), do not need to update") return end
    
    CLog("[cw] PlayModeId changed form " .. tostring(self.PlayModeId) .. " to " .. tostring(newPlayModeId))
    self.PlayModeId = newPlayModeId
    self:DispatchType(MatchModel.ON_PLAY_MODE_ID_CHANGED, newPlayModeId)
end

---封装一个获取 PlayModeId 的方法，用于获取 玩法模式id
---@return number
function MatchModel:GetPlayModeId()
    return self.PlayModeId
end

---封装一个清空 PlayModeId 的方法，用于去除 玩法模式id
function MatchModel:CleanPlayModeId()
    self.PlayModeId = nil
end

--endregion PlayModeId

--region Perspective

---封装一个设置 Perspective 的方法, 用于设置 视角
---@param newPerspective number
function MatchModel:SetPerspective(newPerspective)
    if newPerspective == nil then
        CError("[cw] MatchModel trying to set a nil value to Perspective, if you wanna do it, please use CleanTeamType() instead")
    end

    if self.Perspective == newPerspective then CWaring("[cw] same Perspective(" .. tostring(newPerspective) .. "), do not need to update") return end

    CLog("[cw] Perspective changed form " .. tostring(self.Perspective) .. " to " .. tostring(newPerspective))
    self.Perspective = newPerspective
    self:DispatchType(MatchModel.ON_PERSPECTIVE_CHANGED, newPerspective)
end

---封装一个获取 Perspective 的方法，用于获取 视角
---@return number
function MatchModel:GetPerspective()
    return self.Perspective
end

---封装一个清空 Perspective 的方法，用于去除 视角
function MatchModel:CleanPerspective()
    self.Perspective = nil
end

--endregion Perspective

--region TeamType

---封装一个设置 TeamType 的方法, 用于设置 队伍类型
---@param newTeamType number
function MatchModel:SetTeamType(newTeamType)
    if newTeamType == nil then
        CError("[cw] MatchModel trying to set a nil value to TeamType, if you wanna do it, please use CleanTeamType() instead")
    end

    if self.TeamType == newTeamType then CWaring("[cw] same TeamType(" .. tostring(newTeamType) .. "), do not need to update") return end

    CLog("[cw] TeamType changed form " .. tostring(self.TeamType) .. " to " .. tostring(newTeamType))
    self.TeamType = newTeamType
    self:DispatchType(MatchModel.ON_TEAM_TYPE_CHANGED, newTeamType)
end

---封装一个获取 TeamType 的方法，用于获取 队伍类型
---@return number
function MatchModel:GetTeamType()
    return self.TeamType
end

---封装一个清空 TeamType 的方法，用于去除 队伍类型
function MatchModel:CleanTeamType()
    self.TeamType = nil
end

--endregion TeamType

--region LevelId

---封装一个设置 LevelId 的方法, 用于设置 关卡id
---@param newLevelId number
function MatchModel:SetLevelId(newLevelId)
    if not newLevelId then
         CError("[cw] MatchModel trying to set a nil value to LevelId, if you wanna do it, please use CleanLevelId() instead")
    end

    if self.LevelId == newLevelId then CWaring("[cw] same LevelId(" .. tostring(newLevelId) .. "), do not need to update") return end

    CLog("[cw] LevelId changed form " .. tostring(self.LevelId) .. " to " .. tostring(newLevelId))
    self.LevelId = newLevelId
    self:DispatchType(MatchModel.ON_LEVEL_ID_CHANGED, newLevelId)
end

---封装一个获取 LevelId 的方法，用于获取 关卡id
---@return number
function MatchModel:GetLevelId()
    return self.LevelId
end

---封装一个清空 LevelId 的方法，用于去除 关卡id
function MatchModel:CleanLevelId()
    self.LevelId = nil
end

--endregion LevelId

--region ModeId

---封装一个设置 ModeId 的方法, 用于设置 模式Id
---@param newModeId number 模式ID
function MatchModel:SetModeId(newModeId)
    --表示第一次注册账号还未选择过模式需要自动默认请求选择单排
    --对新玩家来说 ModeId 默认是 "" 如果回来的结果是空字符串都应该主动请求默认选择单排模式, 避免被回来的结果所覆盖造成污染
    if not newModeId or newModeId == 0 then
        ---@type MatchCtrl
        local MatchCtrl = MvcEntry:GetCtrl(MatchCtrl)
        MatchCtrl:ChangeMatchModeInfo()
        
        CLog("[cw] ModeId is nil or 0, sendChangeModeReq to rest to default mode")
        return
    end    
    
    if self.ModeId == newModeId then CWaring("[cw] same ModeId(" .. tostring(newModeId) .. "), do not need to update") return end
    
    CLog("[cw] ModeId changed form " .. tostring(self.ModeId) .. " to " .. tostring(newModeId))
    self.ModeId = newModeId    
    self:DispatchType(MatchModel.ON_MODE_ID_CHANGED, newModeId)
end

---封装一个获取 ModeId 的方法，用于获取 模式Id
---@return number 模式ID
function MatchModel:GetModeId()
    return self.ModeId
end

--endregion ModeId

--region SceneId

---封装一个设置 SceneId 的方法, 用于设置 场景Id
---@param newSceneId number 场景Id
function MatchModel:SetSceneId(newSceneId)
    if not newSceneId then
        CError("[cw] trying to set a illegal value to SceneId in MatchModel:SetSceneId")
        return
    end

    if self.SceneId == newSceneId then CWaring("[cw] same SceneId(" .. tostring(newSceneId) .. "), do not need to update") return end

    CLog("[cw] SceneId changed form " .. tostring(self.SceneId) .. " to " .. tostring(newSceneId))
    self.SceneId = newSceneId
    self:DispatchType(MatchModel.ON_SCENE_ID_CHANGED, newSceneId)
end

---封装一个获取 SceneId 的方法，用于获取 场景Id
---@return number 场景Id
function MatchModel:GetSceneId()
    return self.SceneId
end

--endregion SceneId

--region IsCrossPlatformMatch

---封装一个设置 IsCrossPlatformMatch 的方法, 用于设置 是否开启了跨平台匹配
---@param newIsCrossPlatformMatch boolean
function MatchModel:SetIsCrossPlatformMatch(newIsCrossPlatformMatch)
    if newIsCrossPlatformMatch == nil then
        newIsCrossPlatformMatch = false
        CError("[cw] MatchModel trying to set a nil value to IsCrossPlatformMatch, if you wanna do it, please use CleanIsCrossPlatformMatch() instead")
    end

    if self.IsCrossPlatformMatch == newIsCrossPlatformMatch then CWaring("[cw] same IsCrossPlatformMatch(" .. tostring(newIsCrossPlatformMatch) .. "), do not need to update") return end

    CLog("[cw] IsCrossPlatformMatch changed form " .. tostring(self.IsCrossPlatformMatch) .. " to " .. tostring(newIsCrossPlatformMatch))
    self.IsCrossPlatformMatch = newIsCrossPlatformMatch
    self:DispatchType(MatchModel.ON_CROSS_PLATFORM_MATCH_CHANGED, newIsCrossPlatformMatch)
end

---封装一个获取 IsCrossPlatformMatch 的方法，用于获取 是否开启了跨平台匹配
---@return boolean
function MatchModel:GetIsCrossPlatformMatch()
    return self.IsCrossPlatformMatch
end

---封装一个清空 IsCrossPlatformMatch 的方法，用于去除 是否开启了跨平台匹配
function MatchModel:CleanIsCrossPlatformMatch()
    self.IsCrossPlatformMatch = nil
end

--endregion IsCrossPlatformMatch

--region IsFillTeam

---封装一个设置 IsFillTeam 的方法, 用于设置 是否开启了补满队伍
---@param newIsFillTeam boolean
function MatchModel:SetIsFillTeam(newIsFillTeam)
    if newIsFillTeam == nil then
        newIsFillTeam = false
        CError("[cw] MatchModel trying to set a nil value to IsFillTeam, if you wanna do it, please use CleanIsFillTeam() instead")
    end
    
    if self.IsFillTeam == newIsFillTeam then CWaring("[cw] same IsFillTeam(" .. tostring(newIsFillTeam) .. "), do not need to update") return end

    CLog("[cw] IsFillTeam changed form " .. tostring(self.IsFillTeam) .. " to " .. tostring(newIsFillTeam))
    self.IsFillTeam = newIsFillTeam
    self:DispatchType(MatchModel.ON_FILL_TEAM_CHANGED, newIsFillTeam)
end

---封装一个获取 IsFillTeam 的方法，用于获取 是否开启了补满队伍
---@return boolean
function MatchModel:GetIsFillTeam()
    return self.IsFillTeam
end

---封装一个清空 IsFillTeam 的方法，用于去除 是否开启了补满队伍
function MatchModel:CleanIsFillTeam()
    self.IsFillTeam = nil
end

--endregion IsFillTeam

--region MatchState

---封装一个设置 MatchState 的方法, 用于设置 匹配状态,
---设置时会抛出事件 MatchModel.ON_MATCHING_STATE_CHANGE
---@see MatchModel#Enum_MatchState
---@param newMatchState number 需要变更的新的状态
---@param EventParam any 更新状态的时候附带的消息
function MatchModel:SetMatchState(newMatchState, EventParam)
    if not newMatchState then
        CError("[cw] trying to set a nil value to MatchState in MatchModel:SetMatchState")
        CError(debug.traceback())
        return
    end

    --如果有缓存的状态，且还没有触发时，更新一下缓存的状态，并return
    --例如当登录时获取到缓存状态，但是这个时候会有1~2秒的LS，这过程中可能存在状态变化。
    if self.SynicMatchState ~= nil then
        self.SynicMatchState = newMatchState
        CLog("[cw] self.SynicMatchState change to " .. tostring(newMatchState))
        return
    end

    local _oldMatchState = self.MatchState
    local _newMatchState = newMatchState
    self.MatchState = newMatchState

    --1.抛出对应的事件
    if newMatchState == MatchModel.Enum_MatchState.MatchIdle then
        self:DispatchType(MatchModel.ON_MATCH_IDLE, EventParam)         --等待匹配
        
    elseif newMatchState == MatchModel.Enum_MatchState.MatchRequesting then
        self:DispatchType(MatchModel.ON_MATCH_REQUESTING, EventParam)   --发送匹配请求中
        
    elseif newMatchState == MatchModel.Enum_MatchState.Matching then
        self:DispatchType(MatchModel.ON_MATCHING, EventParam)           --匹配请求收到后，匹配中
        SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_SEARCHING_START)
        
    elseif newMatchState == MatchModel.Enum_MatchState.MatchCanceled then
        self:DispatchType(MatchModel.ON_MATCH_CANCELED, EventParam)     --匹配取消
        SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_SEARCHING_STOP)
        
    elseif newMatchState == MatchModel.Enum_MatchState.MatchSuccess then
        self:DispatchType(MatchModel.ON_MATCH_SUCCESS, EventParam)      --匹配成功
        SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_SEARCHING_STOP)
        
    elseif newMatchState == MatchModel.Enum_MatchState.MatchFail then
        self:DispatchType(MatchModel.ON_MATCH_FAIL, EventParam)         --匹配失败
        SoundMgr:PlaySound(SoundCfg.SoundEffects.MATCH_SEARCHING_STOP)
    end
    
    local Msg = {
        OldMatchState = _oldMatchState, 
        NewMatchState = _newMatchState
    }
    
    CLog("[cw] NewMatchState is " .. tostring(_newMatchState) .. "(" ..  tostring(self:Debug_GetMatchStateString()) .. ")")
    
    --2.抛出整体的事件    
    self:DispatchType(MatchModel.ON_MATCHING_STATE_CHANGE, Msg)       
end

---封装一个获取 MatchState 的方法，用于获取 匹配状态
---@see MatchModel#Enum_MatchState
---@return number
function MatchModel:GetMatchState()
    return self.MatchState
end

---Debug使用，无本地化，业务层请勿调用
---@param MatchState number 匹配状态枚举
---@return string 传入状态的中文描述，方便debug
function MatchModel:Debug_MatchState2String(MatchState)
    return MatchModel.MatchState2String[MatchState]
end

---Debug使用，无本地化，请勿直接使用
---@return string 当前状态的Debug文字
function MatchModel:Debug_GetMatchStateString()
    return self:Debug_MatchState2String(self.MatchState)
end

---是否处于闲置未匹配状态
---@return boolean 是否处于闲置未匹配状态
function MatchModel:IsMatchIdle()
    return self:GetMatchState() == MatchModel.Enum_MatchState.MatchIdle
end

---是否处于匹配状态
---@return boolean 是否处于匹配状态
function MatchModel:IsMatching()
    return self:GetMatchState() == MatchModel.Enum_MatchState.Matching
end

---是否处于匹配成功状态
---@return boolean 是否处于匹配成功状态
function MatchModel:IsMatchSuccessed()
    return self:GetMatchState() == MatchModel.Enum_MatchState.MatchSuccess
end

--endregion MatchState

--region ReqDSInfoData

---封装一个设置 ReqDSInfoData 的方法, 用于设置 服务器下发的SceneLdCpltdQuerySync 的数据
---@param newReqDSInfoData table
function MatchModel:SetReqDSInfoData(newReqDSInfoData)
    if not newReqDSInfoData then
        CWaring("[cw] trying to set a nil value to ReqDSInfoData in MatchModel:SetReqDSInfoData")
    end
    
    self.ReqDSInfoData = newReqDSInfoData
end

---封装一个获取 ReqDSInfoData 的方法，用于获取 服务器下发的SceneLdCpltdQuerySync 的数据
---@return table
function MatchModel:GetReqDSInfoData()
    return self.ReqDSInfoData
end

--endregion ReqDSInfoData

--region IsPrepare

---封装一个获取 IsPrepare 的方法，组队情况下依赖队伍状态，单人情况下默认准备
---@return boolean 玩家是否准备了
function MatchModel:GetIsPrepare()
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local IsSelfInTeam = TeamModel:IsSelfInTeam()

    if IsSelfInTeam then
        return TeamModel:IsMyTeamPlayerInfoStatusREADY()
    else
        return true
    end
end

--endregion IsPrepare

--region MatchDsReconnectInfo

-- ---封装一个设置 MatchDsReconnectInfo 的方法, 用于设置 大厅登录后服务器下发的DS重连信息
-- ---@param newMatchDsReconnectInfo table
-- function MatchModel:SetMatchDsReconnectInfo(newMatchDsReconnectInfo)
--     if newMatchDsReconnectInfo == nil then
--         CError("[cw] MatchModel trying to set a nil value to MatchDsReconnectInfo, if you wanna do it, please use CleanMatchDsReconnectInfo() instead")
--     end

--     if self.MatchDsReconnectInfo == newMatchDsReconnectInfo then CLog("[cw] same MatchDsReconnectInfo(" .. tostring(newMatchDsReconnectInfo) .. ") with before, do nothing") end
--     self.MatchDsReconnectInfo = newMatchDsReconnectInfo
-- end

-- ---封装一个获取 MatchDsReconnectInfo 的方法，用于获取 大厅登录后服务器下发的DS重连信息
-- ---@return table
-- function MatchModel:GetMatchDsReconnectInfo()
--     return self.MatchDsReconnectInfo
-- end

-- ---封装一个清空 MatchDsReconnectInfo 的方法，用于去除 大厅登录后服务器下发的DS重连信息
-- function MatchModel:CleanMatchDsReconnectInfo()
--     self.MatchDsReconnectInfo = nil
-- end

--endregion MatchDsReconnectInfo

function MatchModel:GetStrategyId(SeverId, PlayModeId, LevelId, TeamType, Perspective)
    ---@type MatchSeverModel
    local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
    local SeverCfg = MatchSeverModel:GetData(SeverId)
    if not SeverCfg then
        CError("[cw] Cannot find SeverCfg, SearchInfo: ")
        CError("[cw]     SeverId: " .. tostring(SeverId))
        CError("[cw]     PlayModeId: " .. tostring(PlayModeId))
        CError("[cw]     LevelId: " .. tostring(LevelId))
        CError("[cw]     TeamType: " .. tostring(TeamType))
        CError("[cw]     Perspective: " .. tostring(Perspective))
        return
    end
    
    local CsvName = SeverCfg.ClientMatchConfigTableKey    
    
    --先寻找指定的配置
    local MatchConst = require("Client.Modules.Match.MatchConst")
    local MatchConfig = G_ConfigHelper:GetSingleItemByKeys(CsvName, 
            {"PlayModeId", "TeamType",                                    "Perspective"},
            {PlayModeId,  MatchConst.Enum_TeamTypeIntToString[TeamType], MatchConst.Enum_ViewIntToString[Perspective]})

    --如果策划没有配置LevelId,则找默认的配置
    if not MatchConfig then
        MatchConfig = G_ConfigHelper:GetSingleItemByKeys(CsvName,
        {"PlayModeId", "LevelId", "TeamType",                                    "Perspective"},
        {PlayModeId,    0,  MatchConst.Enum_TeamTypeIntToString[TeamType], MatchConst.Enum_ViewIntToString[Perspective]})
    end
    
    return MatchConfig and MatchConfig.MatchModeId or 0
end

-- 获取玩法模式ID 对应RankConfig.xlsx的RankPlayMapListConfig里的枚举模式ID  用于区分排位匹配等模式
function MatchModel:GetGamePlayModeId(PlayModeId, TeamType, Perspective)
    --先寻找指定的配置
    local MatchConst = require("Client.Modules.Match.MatchConst")
    local GamePlayModeId = 0
    local TeamStr = MatchConst.Enum_TeamTypeIntToString[TeamType]
    local PerspectiveStr = MatchConst.Enum_ViewIntToString[Perspective]
    local Config = G_ConfigHelper:GetSingleItemByKeys(Cfg_RankPlayMapListConfig, {Cfg_RankPlayMapListConfig_P.PlayModeId,Cfg_RankPlayMapListConfig_P.ModeType,Cfg_RankPlayMapListConfig_P.Perspective},{PlayModeId,TeamStr,PerspectiveStr})
	if Config then
		GamePlayModeId = Config[Cfg_RankPlayMapListConfig_P.DefaultId]
	end
	return GamePlayModeId
end

-- 转换视角字符串到视角枚举
---@param ViewString string 视口字符串 如 fpp、 tpp
---@return number 
function MatchModel:ChangeViewStringToInt(ViewString)
    local ViewInt = MatchConst.Enum_ViewStringToInt[ViewString]
    return ViewInt
end

-- 转换队伍类型字符串到队伍枚举
---@param TeamTypeString string 视口字符串 如 fpp、 tpp
---@return number 
function MatchModel:ChangeTeamTypeStringToInt(TeamTypeString)
    local TeamTypeInt = MatchConst.Enum_TeamTypeStringToInt[TeamTypeString]
    return TeamTypeInt
end

--[[
    存储当前进入对局的DsGroupId
    第一个是匹配成功创建对局成功后下发的DS连接元信息
    第二个是客户端触发的重连请求获取局内状态信息
    DsMetaSync/MatchAndDsStateSync
]]
function MatchModel:SaveCurDsGroupId(DsGroupId)
    CWaring("MatchModel:SaveCurDsGroupId: = "..DsGroupId)
    self.SavedDsGroupId = DsGroupId
end

-- 获取当前对局的DsGroupId
function MatchModel:GetSavedDsGroupId()
    return self.SavedDsGroupId
end

return MatchModel