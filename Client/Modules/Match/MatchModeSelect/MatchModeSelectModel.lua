---
--- Model 模块，用于数据存储与逻辑运算
--- Description: 匹配模式选择
--- Created At: 2023/05/11 16:53
--- Created By: 朝文
---

local super = GameEventDispatcher
local class_name = "MatchModeSelectModel"
---@class MatchModeSelectModel : GameEventDispatcher
MatchModeSelectModel = BaseClass(super, class_name)

--事件相关
MatchModeSelectModel.ON_MATCH_MODE_SEL_BATTLE_SEVER_ID_CHANGED     = "ON_MATCH_MODE_SEL_BATTLE_SEVER_ID_CHANGED"    --已选的战斗服务器变动
MatchModeSelectModel.ON_MATCH_MODE_SEL_PLAY_MODE_ID_CHANGED        = "ON_MATCH_MODE_SEL_PLAY_MODE_ID_CHANGED"       --已选的玩法模式id变动
MatchModeSelectModel.ON_MATCH_MODE_SEL_LEVEL_ID_CHANGED            = "ON_MATCH_MODE_SEL_LEVEL_ID_CHANGED"           --已选的玩法关卡变动（可能会导致场景id和模式key变动）
MatchModeSelectModel.ON_MATCH_MODE_SEL_SCENE_ID_CHANGED            = "ON_MATCH_MODE_SEL_SCENE_ID_CHANGED"           --已选的场景id变动
MatchModeSelectModel.ON_MATCH_MODE_SEL_MODE_ID_CHANGED             = "ON_MATCH_MODE_SEL_MODE_ID_CHANGED"            --已选的模式key变动

MatchModeSelectModel.ON_MATCH_MODE_FILL_TEAM_CHANGED               = "ON_MATCH_MODE_FILL_TEAM_CHANGED"              --已选的补满队伍变动
MatchModeSelectModel.ON_MATCH_MODE_CROSS_PLATFORM_MATCH_CHANGED    = "ON_MATCH_MODE_CROSS_PLATFORM_MATCH_CHANGED"   --已选的跨平台组队变动
MatchModeSelectModel.ON_MATCH_MODE_TEAM_TYPE_CHANGED               = "ON_MATCH_MODE_TEAM_TYPE_CHANGED"              --已选的队伍人数类型变动
MatchModeSelectModel.ON_MATCH_MODE_PERSPECTIVE_CHANGED             = "ON_MATCH_MODE_PERSPECTIVE_CHANGED"            --已选的视角变动

MatchModeSelectModel.ON_MATCH_MODE_MANUAL_SELECT             = "ON_MATCH_MODE_MANUAL_SELECT"            --选择模式

local MatchConst = require("Client.Modules.Match.MatchConst")
MatchModeSelectModel.Const = {
    DefaultSelectPlayModeId         = 10001,
    DefaultSelectTeamType           = MatchConst.Enum_TeamType.squad,
    DefaultSelectPerspective        = MatchConst.Enum_View.tpp,
    DefaultSelectLevelId            = 1011001,
    DefaultSelectSceneId            = 101,
    DefaultSelectModeId             = 100,
    DefaultSelectFillTeam           = true,
    DefaultSelectCrossPlatformMatch = true,
}

function MatchModeSelectModel:__init()
    --读取表格缓存一下默认数据
    local DefaultCfg = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_DefaultCfg, 1)
    if not DefaultCfg then
        CError("[cw] cannot find default setting, use lua default")
        self.Const.DefaultSelectPlayModeId         = 10001
        self.Const.DefaultSelectTeamType           = MatchConst.Enum_TeamType.squad
        self.Const.DefaultSelectPerspective        = MatchConst.Enum_View.tpp
        self.Const.DefaultSelectLevelId            = 1011001
        self.Const.DefaultSelectSceneId            = 101
        self.Const.DefaultSelectModeId             = 100
        self.Const.DefaultSelectFillTeam           = true
        self.Const.DefaultSelectCrossPlatformMatch = true
    else
        self.Const.DefaultSelectPlayModeId         = DefaultCfg[Cfg_ModeSelect_DefaultCfg_P.DefaultPlayModeId]
        self.Const.DefaultSelectTeamType           = MatchConst.Enum_TeamTypeStringToInt[DefaultCfg[Cfg_ModeSelect_DefaultCfg_P.DefaultTeamMode]]
        self.Const.DefaultSelectPerspective        = MatchConst.Enum_ViewStringToInt[DefaultCfg[Cfg_ModeSelect_DefaultCfg_P.DefaultPerspective]]
        self.Const.DefaultSelectLevelId            = DefaultCfg[Cfg_ModeSelect_DefaultCfg_P.DefaultLevelId]
        self.Const.DefaultSelectSceneId            = DefaultCfg[Cfg_ModeSelect_DefaultCfg_P.DefaultSceneId]
        self.Const.DefaultSelectModeId             = DefaultCfg[Cfg_ModeSelect_DefaultCfg_P.DefaultModeId]
        self.Const.DefaultSelectFillTeam           = DefaultCfg[Cfg_ModeSelect_DefaultCfg_P.DefaultFillTeam] == 1
        self.Const.DefaultSelectCrossPlatformMatch = DefaultCfg[Cfg_ModeSelect_DefaultCfg_P.DefaultCrossPlatFormMatch] == 1
    end
    
    self:DataInit()
end

---初始化数据，用于第一次调用及登出的时候调用
function MatchModeSelectModel:DataInit()
    --外部不要调用，模式选择界面使用的数据
    self._cache = {}
    self._CurSelServeId = nil
    self._CurSelPlayModeId = nil
    self._CurSelLevelId = nil
    self._CurSelSceneId = nil
    self._CurSelModeId = nil
    self._CurSelFillTeam = nil
    self._CurSelCrossPlatformMatch = nil
    self._CurSelTeamType = nil
    self._CurSelPerspective = nil

    self._IsShowModeSelectServerList = false
end

--region _CurSelServe

---封装一个设置 _CurSelServe 的方法, 用于设置 当前选中的服务器
---@param newCurSelServe number
function MatchModeSelectModel:_SetCurSelServeId(newCurSelServe)
    if not newCurSelServe then
         CError("[cw] MatchModeSelectModel trying to set a nil value to _CurSelServe, if you wanna do it, please use _CleanCurSelServeId() instead")
    end

    self._CurSelServeId = newCurSelServe
    self:DispatchType(MatchModeSelectModel.ON_MATCH_MODE_SEL_BATTLE_SEVER_ID_CHANGED, newCurSelServe)
end

---封装一个获取 _CurSelServe 的方法，用于获取 当前选中的服务器
---@return number
function MatchModeSelectModel:_GetCurSelServeId()
    return self._CurSelServeId
end

---封装一个清空 _CurSelServe 的方法，用于去除 当前选中的服务器
function MatchModeSelectModel:_CleanCurSelServeId()
    self._CurSelServeId = nil
end

-- 设置是否显示服务器列表
function MatchModeSelectModel:SetIsShowModeSelectServerList(Value)
    self._IsShowModeSelectServerList = Value
end

-- 获取是否显示服务器列表
function MatchModeSelectModel:GetIsShowModeSelectServerList(Value)
    return self._IsShowModeSelectServerList
end

--endregion _CurSelServe

--region _CurSelPlayModeId

---封装一个设置 CurSelPlayModeId 的方法, 用于设置 当前选中的玩法模式ID
---@param newCurSelPlayModeId number
function MatchModeSelectModel:_SetCurSelPlayModeId(newCurSelPlayModeId)
    CLog("[cw] MatchModeSelectModel:_SetCurSelPlayModeId(" .. string.format("%s", newCurSelPlayModeId) .. ")")
    if not newCurSelPlayModeId then
         CError("[cw] MatchModeSelectModel trying to set a nil value to CurSelPlayModeId, if you wanna do it, please use _CleanCurSelPlayModeId() instead")
    end
    self._CurSelPlayModeId = newCurSelPlayModeId
    self:DispatchType(MatchModeSelectModel.ON_MATCH_MODE_SEL_PLAY_MODE_ID_CHANGED, newCurSelPlayModeId)
end

---封装一个获取 CurSelPlayModeId 的方法，用于获取 当前选中的玩法模式ID
---@return number
function MatchModeSelectModel:_GetCurSelPlayModeId()
    return self._CurSelPlayModeId
end

---封装一个清空 CurSelPlayModeId 的方法，用于去除 当前选中的玩法模式ID
function MatchModeSelectModel:_CleanCurSelPlayModeId()
    self._CurSelPlayModeId = nil
end

--endregion _CurSelPlayModeId

--region _CurSelLevelId

---封装一个设置 _CurSelLevelId 的方法, 用于设置 当前选中的关卡ID
---@param newCurSelLevelId number
function MatchModeSelectModel:_SetCurSelLevelId(newCurSelLevelId)
    CLog("[cw] MatchModeSelectModel:_SetCurSelLevelId(" .. string.format("%s", newCurSelLevelId) .. ")")
    if not newCurSelLevelId then
         CError("[cw] MatchModeSelectModel trying to set a nil value to _CurSelLevelId, if you wanna do it, please use _CleanCurSelLevelId() instead")
    end
    self._CurSelLevelId = newCurSelLevelId
    self:DispatchType(MatchModeSelectModel.ON_MATCH_MODE_SEL_LEVEL_ID_CHANGED, newCurSelLevelId)
end

---封装一个获取 _CurSelLevelId 的方法，用于获取 当前选中的关卡ID
---@return number
function MatchModeSelectModel:_GetCurSelLevelId()
    return self._CurSelLevelId
end

---封装一个清空 _CurSelLevelId 的方法，用于去除 当前选中的关卡ID
function MatchModeSelectModel:_CleanCurSelLevelId()
    self._CurSelLevelId = nil
end

--endregion _CurSelLevelId

--region _CurSelSceneId

---封装一个设置 _CurSelSceneId 的方法, 用于设置 当前选中的场景id
---@param newCurSelSceneId number
function MatchModeSelectModel:_SetCurSelSceneId(newCurSelSceneId)
    CLog("[cw] MatchModeSelectModel:_SetCurSelSceneId(" .. string.format("%s", tostring(newCurSelSceneId)) .. ")")
    if not newCurSelSceneId then
         CError("[cw] MatchModeSelectModel trying to set a nil value to _CurSelSceneId, if you wanna do it, please use _CleanCurSelSceneId() instead")
    end
    
    self._CurSelSceneId = newCurSelSceneId
    self:DispatchType(MatchModeSelectModel.ON_MATCH_MODE_SEL_SCENE_ID_CHANGED, newCurSelSceneId)
end

---封装一个获取 _CurSelSceneId 的方法，用于获取 当前选中的场景id
---@return number
function MatchModeSelectModel:_GetCurSelSceneId()
    return self._CurSelSceneId
end

---封装一个清空 _CurSelSceneId 的方法，用于去除 当前选中的场景id
function MatchModeSelectModel:_CleanCurSelSceneId()
    self._CurSelSceneId = nil
end

--endregion _CurSelSceneId

--region _CurSelModeId

---封装一个设置 _CurSelModeId 的方法, 用于设置 当前选择的模式id
---@param newCurSelModeId number 新的选中模式id
function MatchModeSelectModel:_SetCurSelModeId(newCurSelModeId)
    CLog("[cw] MatchModeSelectModel:_SetCurSelModeId(" .. string.format("%s", newCurSelModeId) .. ")")
    if not newCurSelModeId then
         CError("[cw] MatchModeSelectModel trying to set a nil value to _CurSelModeId, if you wanna do it, please use CleanCurSelModeId() instead")
    end
    
    self._CurSelModeId = newCurSelModeId
    self:DispatchType(MatchModeSelectModel.ON_MATCH_MODE_SEL_MODE_ID_CHANGED, newCurSelModeId)
end

---封装一个获取 _CurSelModeId 的方法，用于获取 当前选择的模式id
---@return number 当前选择的模式id
function MatchModeSelectModel:_GetCurSelModeId()
    return self._CurSelModeId
end

---@return boolean 是否所有需要选择的参数都选中了
function MatchModeSelectModel:IsAllMatchDataSelected()
    local CurSelPlayModeId  = self:_GetCurSelPlayModeId()   --玩法模式id
    local CurSelLevelId     = self:_GetCurSelLevelId()      --关卡id
    local CurSelSceneId     = self:_GetCurSelSceneId()      --场景id
    local CurSelModeId      = self:_GetCurSelModeId()       --模式id
    local CurSelPerspective = self:_GetCurSelPerspective()  --视角
    local CurSelTeamType    = self:_GetCurSelTeamType()     --队伍类型
    
    return CurSelPlayModeId and CurSelLevelId and CurSelSceneId and CurSelModeId and CurSelPerspective and CurSelTeamType
end

---封装一个清空 _CurSelModeId 的方法，用于去除 当前选择的模式id
function MatchModeSelectModel:_CleanCurSelModeId()
    self._CurSelModeId = nil
end

--endregion _CurSelModeId

--region _CurSelFillTeam

---封装一个设置 _CurSelFillTeam 的方法, 用于设置 当前是否选择了补满队伍
---@param newCurSelFillTeam boolean
function MatchModeSelectModel:_SetCurSelFillTeam(newCurSelFillTeam)
    if newCurSelFillTeam == nil then
         CError("[cw] MatchModeSelectModel trying to set a nil value to _CurSelFillTeam, if you wanna do it, please use _CleanCurSelFillTeam() instead")
    end
    
    self._CurSelFillTeam = newCurSelFillTeam
    self:DispatchType(MatchModeSelectModel.ON_MATCH_MODE_FILL_TEAM_CHANGED, newCurSelFillTeam)
end

---封装一个获取 _CurSelFillTeam 的方法，用于获取 当前是否选择了补满队伍
---@return 
function MatchModeSelectModel:_GetCurSelFillTeam()
    if self._CurSelFillTeam == nil then
        ---@type MatchModel
        local MatchModel = MvcEntry:GetModel(MatchModel)
        self._CurSelFillTeam = MatchModel:GetIsFillTeam() 
    end
    return self._CurSelFillTeam
end

function MatchModeSelectModel:_CleanCurSelFillTeam()
    self._CurSelFillTeam = nil
end

--endregion _CurSelFillTeam

--region _CurSelCrossPlatformMatch

---封装一个设置 _CurSelCrossPlatformMatch 的方法, 用于设置 是否勾选了跨平台匹配
---@param newCurSelCrossPlatformMatch boolean 是否跨平台匹配
function MatchModeSelectModel:_SetCurSelCrossPlatformMatch(newCurSelCrossPlatformMatch)
    if newCurSelCrossPlatformMatch == nil then
         CError("[cw] MatchModeSelectModel trying to set a nil value to _CurSelCrossPlatformMatch, if you wanna do it, please use _CleanCurSelCrossPlatformMatch() instead")
    end
    
    self._CurSelCrossPlatformMatch = newCurSelCrossPlatformMatch
    self:DispatchType(MatchModeSelectModel.ON_MATCH_MODE_CROSS_PLATFORM_MATCH_CHANGED, newCurSelCrossPlatformMatch)
end

---封装一个获取 _CurSelCrossPlatformMatch 的方法，用于获取 是否勾选了跨平台匹配
---@return boolean 是否跨平台匹配
function MatchModeSelectModel:_GetCurSelCrossPlatformMatch()
    if self._CurSelCrossPlatformMatch == nil then 
        ---@type MatchModel
        local MatchModel = MvcEntry:GetModel(MatchModel)
        self._CurSelCrossPlatformMatch = MatchModel:GetIsCrossPlatformMatch() 
    end
    return self._CurSelCrossPlatformMatch
end

function MatchModeSelectModel:_CleanCurSelCrossPlatformMatch()
    self._CurSelCrossPlatformMatch = nil
end

--endregion _CurSelCrossPlatformMatch

--region _CurSelTeamType

---封装一个设置 _CurSelTeamType 的方法, 用于设置 队伍类型（单排、双排、四排）
---@param newCurSelTeamType number MatchModeSelectModel.Enum_TeamType
function MatchModeSelectModel:_SetCurSelTeamType(newCurSelTeamType)
    CLog("[cw] MatchModeSelectModel:_SetCurSelTeamType(" .. string.format("%s", tostring(newCurSelTeamType)) .. ")")
    if not newCurSelTeamType then
        CError("[cw] MatchModeSelectModel trying to set a nil value to _CurSelTeamType, if you wanna do it, please use _CleanCurSelTeamType() instead", true)
    end
    
    self._CurSelTeamType = newCurSelTeamType
    self:DispatchType(MatchModeSelectModel.ON_MATCH_MODE_TEAM_TYPE_CHANGED, newCurSelTeamType)
end

---封装一个获取 CurSelTeamType 的方法，用于获取 队伍类型
---@return number
function MatchModeSelectModel:_GetCurSelTeamType()
    return self._CurSelTeamType
end

function MatchModeSelectModel:_CleanCurSelTeamType()
    self._CurSelTeamType = nil
end

--endregion _CurSelTeamType

--region _CurSelPerspective

---封装一个设置 _CurSelPerspective 的方法, 用于设置 玩家选择的玩家视角
---@param newCurSelPerspective number 
function MatchModeSelectModel:_SetCurSelPerspective(newCurSelPerspective)
    CLog("[cw] MatchModeSelectModel:_SetCurSelPerspective(" .. string.format("%s", tostring(newCurSelPerspective)) .. ")")
    if not newCurSelPerspective then
         CError("[cw] MatchModeSelectModel trying to set a nil value to _CurSelPerspective, if you wanna do it, please use _CleanCurSelPerspective() instead")
    end
    
    self._CurSelPerspective = newCurSelPerspective
    self:DispatchType(MatchModeSelectModel.ON_MATCH_MODE_PERSPECTIVE_CHANGED, newCurSelPerspective)
end

---封装一个获取 _CurSelPerspective 的方法，用于获取 玩家选择的玩家视角
---@return number
function MatchModeSelectModel:_GetCurSelPerspective()
    return self._CurSelPerspective
end

function MatchModeSelectModel:_CleanCurSelPerspective()
    self._CurSelPerspective = nil
end

--endregion _CurSelPerspective

---@return boolean 模式选择中的数据是否和已经设置的数据一样
function MatchModeSelectModel:IsSameConfigWithMatchModel()
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    return self:_GetCurSelServeId() == MatchModel:GetSeverId() and
            self:_GetCurSelPlayModeId() == MatchModel:GetPlayModeId() and
            self:_GetCurSelPerspective() == MatchModel:GetPerspective() and
            self:_GetCurSelTeamType() == MatchModel:GetTeamType() and
            self:_GetCurSelLevelId() == MatchModel:GetLevelId() and
            self:_GetCurSelSceneId() == MatchModel:GetSceneId() and
            self:_GetCurSelModeId() == MatchModel:GetModeId() and
            self:_GetCurSelCrossPlatformMatch() == MatchModel:GetIsCrossPlatformMatch() and
            self:_GetCurSelFillTeam() == MatchModel:GetIsFillTeam()
end

---玩家登出时调用
function MatchModeSelectModel:OnLogout(data)
    self:DataInit()
end

--region 读表 ModeEntryCfg.csv 相关

---    玩法模式配置    ---  
--- PlayModeEntryCfg ---

---@return table 基于PlayModeId获取的数据
function MatchModeSelectModel:GetPlayModeCfg(PlayModeId)
    if not PlayModeId then CError(debug.traceback()) return end
       
    local PlayModeCfg = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_PlayModeEntryCfg, PlayModeId)
    return PlayModeCfg
end

---@return string 玩法名字
function MatchModeSelectModel:GetPlayModeCfg_PlayModeName(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return end
             
    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.PlayModeName]
end

---@return string 玩法介绍
function MatchModeSelectModel:GetPlayModeCfg_PlayModeDesc(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return end
    
    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.PlayModeDesc]
end

---@return string[] 可以使用的视角列表
function MatchModeSelectModel:GetPlayModeCfg_Perspectives(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return {} end
    
    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.Perspective] or {}
end

---@param Perspective number 参考 MatchConst.Enum_View
---@return boolean 传入的视角在玩法模式底下是否可用
function MatchModeSelectModel:GetPlayModeCfg_CheckIfPerspectiveAvailiable(PlayModeId, Perspective)
    local Perspectives = self:GetPlayModeCfg_Perspectives(PlayModeId)
    if not Perspectives then return false end

    for k, v in pairs(Perspectives) do
        local PerspectiveInt = MatchConst.Enum_ViewStringToInt[v] or 0
        if PerspectiveInt == Perspective then return true end
    end
    return false
end

---@return boolean 玩法模式id是否支持第一人称视角
function MatchModeSelectModel:GetPlayModeCfg_Perspective_FPP(PlayModeId)
    return self:GetPlayModeCfg_CheckIfPerspectiveAvailiable(PlayModeId, MatchConst.Enum_View.fpp)
end

---@return boolean 玩法模式id是否支持第三人称视角
function MatchModeSelectModel:GetPlayModeCfg_Perspective_TPP(PlayModeId)
    return self:GetPlayModeCfg_CheckIfPerspectiveAvailiable(PlayModeId, MatchConst.Enum_View.tpp)
end

---@return string[] 可以使用的队伍类型
---@see Enum_TeamType
function MatchModeSelectModel:GetPlayModeCfg_TeamTypes(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return {} end

    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.TeamMode] or {}
end

---@param TeamType number 参考 MatchConst.Enum_TeamType
---@return boolean 传入的队伍类型在玩法模式底下是否可用
function MatchModeSelectModel:GetPlayModeCfg_CheckIfTeamTypeAvailiable(PlayModeId, TeamType)
    local TeamTypes = self:GetPlayModeCfg_TeamTypes(PlayModeId)    
    for k, v in pairs(TeamTypes) do
        local teamTypeInt = MatchConst.Enum_TeamTypeStringToInt[v] or -1
        if teamTypeInt == TeamType then return true end
    end
    return false
end

---@return boolean 玩法模式id是否支持单人
function MatchModeSelectModel:GetPlayModeCfg_TeamType_Solo(PlayModeId)
    return self:GetPlayModeCfg_CheckIfTeamTypeAvailiable(PlayModeId, MatchConst.Enum_TeamType.solo)
end

---@return boolean 玩法模式id是否支持双排
function MatchModeSelectModel:GetPlayModeCfg_TeamType_Duo(PlayModeId)
    return self:GetPlayModeCfg_CheckIfTeamTypeAvailiable(PlayModeId, MatchConst.Enum_TeamType.duo)
end

---@return boolean 玩法模式id是否支持四排
function MatchModeSelectModel:GetPlayModeCfg_TeamType_Squad(PlayModeId)
    return self:GetPlayModeCfg_CheckIfTeamTypeAvailiable(PlayModeId, MatchConst.Enum_TeamType.squad)
end

---@return boolean 是否允许跨平台匹配
function MatchModeSelectModel:GetPlayModeCfg_IsCrossPlayFormMatch(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return end
       
    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.CrossPlatFormMatch] == 1
end

---@return string[] 可游玩平台，Android, PC, iOS, Console
function MatchModeSelectModel:GetPlayModeCfg_Platforms(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return end
    
    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.Platforms]
end

---@return boolean 入口是否开放
function MatchModeSelectModel:GetPlayModeCfg_IsOpen(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return end

    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.IsOpen] == 1
end

---@return boolean 是否允许自动补满
function MatchModeSelectModel:GetPlayModeCfg_IsAllowAutoFill(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return end

    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.AllowAutoFill] == 1
end

---@return number 开始时间戳
function MatchModeSelectModel:GetPlayModeCfg_StartTime(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return -1 end
    
    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.StartTimeTimestamp] or -1
end

---@return number 结束时间戳
function MatchModeSelectModel:GetPlayModeCfg_EndTime(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return -1 end
    
    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.EndTimeTimestamp] or -1
end

---@return boolean 当前时间是否在模式配置的时间范围内
function MatchModeSelectModel:GetPlayModeCfg_IsInTime(PlayModeId)
    --如果没有设置，则说明永久开放
    local startTime = self:GetPlayModeCfg_StartTime(PlayModeId)
    local endTime = self:GetPlayModeCfg_EndTime(PlayModeId)
    if startTime == 0 and endTime == 0 then return true end
    
    --否则判断当前时间是否在时间戳内
    local curTime = GetTimestamp()
    return startTime <= curTime and curTime <= endTime
end

---@return number[] 包含的关卡列表
function MatchModeSelectModel:GetPlayModeCfg_LevelIds(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return end
    
    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.LevelIds]
end

---@return string 大背景图路径
function MatchModeSelectModel:GetPlayModeCfg_BigBackgroundImgPath(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return end

    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.BigBackgroundImgPath]
end

---@return string 小预览图路径
function MatchModeSelectModel:GetPlayModeCfg_SmallPreviewImgPath(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return end
    
    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.SmallPreviewImgPath]
end

---@return string 弹窗图片路径
function MatchModeSelectModel:GetPlayModeCfg_PopMessageImgPath(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return end

    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.PopMessageImgPath]
end

---@return string 弹窗文字描述
function MatchModeSelectModel:GetPlayModeCfg_PopDetailDesc(PlayModeId)
    local PlayModeCfg = self:GetPlayModeCfg(PlayModeId)
    if not PlayModeCfg then return end
    
    return PlayModeCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.PopDetailDesc]
end

--- extra

---一个玩法模式中，只有一个关卡配置是可以用的，这个函数可以获取当前可以使用的关卡配置id
---@return number 当前玩法模式下可以使用的关卡配置id
function MatchModeSelectModel:GetPlayModeCfg_Extra_CurAvailableGameLevelId(PlayModeId)
    local GameLevelIds = self:GetPlayModeCfg_LevelIds(PlayModeId)
    if not GameLevelIds then return nil end
    
    local CurTimeStamp = GetTimestamp()
    for _, levelId in pairs(GameLevelIds) do
        local startTime = self:GetGameLevelEntryCfg_StartTime(levelId)
        local endTime = self:GetGameLevelEntryCfg_EndTime(levelId)
        if startTime <= CurTimeStamp and CurTimeStamp < endTime then
           return levelId 
        end
    end
    return nil
end

---     关卡配置       ---
--- GameLevelEntryCfg ---

---@param GameLevelId number 
---@return table 基于 GameLevelId 获取的数据
function MatchModeSelectModel:GetGameLevelEntryCfg(GameLevelId)
    if not GameLevelId then CError(debug.traceback()) return end
    
    local GameLevelEntryCfg = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_GameLevelEntryCfg, GameLevelId)
    return GameLevelEntryCfg
end

---@return number 关卡配置
function MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(GameLevelId)
    local GameLevelEntryCfg = self:GetGameLevelEntryCfg(GameLevelId)
    if not GameLevelEntryCfg then return end
    
    return GameLevelEntryCfg[Cfg_ModeSelect_GameLevelEntryCfg_P.SceneCfg]
end

---@return number 模式配置key
function MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(GameLevelId)
    local GameLevelEntryCfg = self:GetGameLevelEntryCfg(GameLevelId)
    if not GameLevelEntryCfg then return end
    
    return GameLevelEntryCfg[Cfg_ModeSelect_GameLevelEntryCfg_P.ModeCfg]
end

---@return number 开始时间戳
function MatchModeSelectModel:GetGameLevelEntryCfg_StartTime(GameLevelId)
    local GameLevelEntryCfg = self:GetGameLevelEntryCfg(GameLevelId)
    if not GameLevelEntryCfg then return -1 end
    
    return GameLevelEntryCfg[Cfg_ModeSelect_GameLevelEntryCfg_P.StartTimeTimestamp] or -1
end

---@return number 结束时间戳
function MatchModeSelectModel:GetGameLevelEntryCfg_EndTime(GameLevelId)
    local GameLevelEntryCfg = self:GetGameLevelEntryCfg(GameLevelId)
    if not GameLevelEntryCfg then return -1 end
    
    return GameLevelEntryCfg[Cfg_ModeSelect_GameLevelEntryCfg_P.EndTimeTimestamp] or -1
end

---@return boolean 当前时间关卡是否在关卡配置的时间范围内
function MatchModeSelectModel:GetGameLevelEntryCfg_IsInTime(PlayModeId)
    --如果没有设置，则说明永久开放
    local startTime = self:GetGameLevelEntryCfg_StartTime(PlayModeId)
    local endTime = self:GetGameLevelEntryCfg_EndTime(PlayModeId)
    if startTime == 0 and endTime == 0 then return true end

    --否则判断当前时间是否在时间戳内
    local curTime = GetTimestamp()
    return startTime <= curTime and curTime <= endTime
end

---    场景配置    ---
--- SceneEntryCfg ---

---@param SceneId number
---@return table 基于 SceneId 获取的数据
function MatchModeSelectModel:GetSceneEntryCfg(SceneId)
    if not SceneId then CError(debug.traceback()) return end
    
    local SceneCfg = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_SceneEntryCfg, SceneId)
    return SceneCfg
end

---@return string 场景名称
function MatchModeSelectModel:GetSceneEntryCfg_SceneName(SceneId)
    local SceneCfg = self:GetSceneEntryCfg(SceneId)
    if not SceneCfg then return end

    return SceneCfg[Cfg_ModeSelect_SceneEntryCfg_P.SceneName]
end

---@return string 场景蓝图路径
function MatchModeSelectModel:GetSceneEntryCfg_SceneBpPath(SceneId)
    local SceneCfg = self:GetSceneEntryCfg(SceneId)
    if not SceneCfg then return end
    
    return SceneCfg[Cfg_ModeSelect_SceneEntryCfg_P.SceneBpPath]
end

---@return string 场景缩略图路径
function MatchModeSelectModel:GetSceneEntryCfg_ScenePreviewImgPath(SceneId)
    local SceneCfg = self:GetSceneEntryCfg(SceneId)
    if not SceneCfg then return end
    
    return SceneCfg[Cfg_ModeSelect_SceneEntryCfg_P.ScenePreviewImgPath]
end

---@return string 场景缩略图路径
function MatchModeSelectModel:GetSceneEntryCfg_HallMatchEntranceBgImgPath(SceneId)
    local SceneCfg = self:GetSceneEntryCfg(SceneId)
    if not SceneCfg then return end

    return SceneCfg[Cfg_ModeSelect_SceneEntryCfg_P.HallMatchEntranceBgImgPath]
end

---    模式配置   ---
--- ModeEntryCfg ---

---@param ModeId number 模式ID
---@return table 基于 ModeKey 获取的数据
function MatchModeSelectModel:GetModeEntryCfg(ModeId)
    if not ModeId then CError(debug.traceback()) return end

    local ModeCfg = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_ModeEntryCfg, ModeId)
    return ModeCfg
end

---@return string 模式名称
function MatchModeSelectModel:GetModeEntryCfg_ModeName(ModeId)
    local ModeCfg = self:GetModeEntryCfg(ModeId)
    if not ModeCfg then return end
    
    return ModeCfg[Cfg_ModeSelect_ModeEntryCfg_P.ModeName]
end

---@return string 模式类型
function MatchModeSelectModel:GetModeEntryCfg_ModeType(ModeId)
    local ModeCfg = self:GetModeEntryCfg(ModeId)
    if not ModeCfg then return end

    return ModeCfg[Cfg_ModeSelect_ModeEntryCfg_P.ModeType]
end

---@return number 队伍上限
---@deprecated
function MatchModeSelectModel:GetModeEntryCfg_MaxTeam(ModeKey)
    local ModeCfg = self:GetModeEntryCfg(ModeKey)
    if not ModeCfg then return end

    return ModeCfg[Cfg_ModeSelect_ModeEntryCfg_P.MaxTeam]
end

---@return number 单队伍人数
---@deprecated
function MatchModeSelectModel:GetModeEntryCfg_MaxTeamPlayer(ModeKey)
    local ModeCfg = self:GetModeEntryCfg(ModeKey)
    if not ModeCfg then return end

    return ModeCfg[Cfg_ModeSelect_ModeEntryCfg_P.MaxTeamPlayer]
end

---@return number 获取此模式可以容纳的最大人数
---@deprecated
function MatchModeSelectModel:GetModeEntryCfg_MaxPlayer(ModeKey)
    local MaxTeam = self:GetModeEntryCfg_MaxTeam(ModeKey) or 0
    local MaxTeamPlayer = self:GetModeEntryCfg_MaxTeamPlayer(ModeKey) or 0
    return MaxTeam * MaxTeamPlayer
end

--endregion 读表 ModeEntryCfg.csv 相关

return MatchModeSelectModel