---
--- Model 模块，用于数据存储与逻辑运算，不需要存储复杂数据，直接继承 GameEventDispatcher
--- Description: 大厅结算数据存储
--- Created At: 2023/04/07 17:00
--- Created By: 朝文
---

local super = GameEventDispatcher
local class_name = "HallSettlementModel"
---@class HallSettlementModel : GameEventDispatcher
HallSettlementModel = BaseClass(super, class_name)

local MatchConst = require("Client.Modules.Match.MatchConst")

HallSettlementModel.ON_MESSAGE_ITEM_ANIMATION_COMPLETE_EVENT = "ON_MESSAGE_ITEM_ANIMATION_COMPLETE_EVENT" -- 消息item动画播放完成事件
HallSettlementModel.ON_SETTLEMENT_PLAYER_ITEM_CLICK_EVENT = "ON_SETTLEMENT_PLAYER_ITEM_CLICK_EVENT" -- 结算玩家列表item点击事件
HallSettlementModel.ON_SETTLEMENT_DATA_STATE_UPDATE_EVENT = "ON_SETTLEMENT_DATA_STATE_UPDATE_EVENT" -- 结算数据状态发生变化  需要刷新界面

--局外结算-消息提示item
HallSettlementModel.MessageTipItem = {
    UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Settlement/WBP_AwardWidget.WBP_AwardWidget",
    LuaClass = "Client.Modules.HallSettlement.HallSettlement_Widgets.HallSettlement_MessageTipItem",
}

-- 三连按钮鼠标转圈材质参数
HallSettlementModel.TripleButtonMouseMaterialParam = {
    MaterialPath = "/Game/Arts/UI/UIMaterial/MaterialInstance/M_UmgCircleBarTemp_Skill_01.M_UmgCircleBarTemp_Skill_01",
    MaterialName = "Progress"
}

-- 结算Item类型
HallSettlementModel.Enum_SettlementItemType = {
    -- 结算类型
    Settlement = 1,
    -- 历史战绩类型
    History = 2,
}

-- 结算状态类型
HallSettlementModel.Enum_SettlementDataStateType = {
    -- 等待结算数据返回中
    Loading = 1,
    -- 获取结算数据失败
    GetDataFail = 2,
    -- 正常获得了结算数据
    Normal = 3,
}

-- 消息提示类型
HallSettlementModel.Enum_MessageTipType = {
    -- 任务完成
    TaskComplete = 1,
    -- 成就获得
    AchievementGet = 2,
    -- 任务奖励
    TaskReward = 3,
    -- 道具掉落
    PropDrop = 4,
}

-- 排位结算结果类型
HallSettlementModel.Enum_DivisionResultType = {
    -- 段位升级
    UpgradeDivision = 1,
    -- 段位降低
    DowngradeDivision = 2,
    -- 段位未变更
    UnchangedDivision = 3,
}

function HallSettlementModel:__init()    
    self:DataInit()
end

function HallSettlementModel:DataInit()
    --[[
        --大逃杀br模式
        self.SettlementData = {
            GameId = 123,
            GameplayCfg = {
                TeamType = 4,
                GameplayId = 10005,
                View = 3,
                LevelId = 1031002,
            },
            Level = 1,              -- 当前等级
            Experience = 50,        -- 当前经验
            DeltaExperience = 120,  -- 增量经验
            TeamRank = 1,
            TeamCount = 100,
            PlayerArray = {
                [1] = {
                    PlayerId = 00,
                    HeroTypeId = 200030000,
                    SkinId = 200030001,
                    RescueTimes = 1,
                    PlayerName = "玩家1",
                    PlayerSurvivalTime = 1234,
                    PlayerKill = 1,
                    PlayerAssist = 2,
                    RespawnTimes = 12,
                    PlayerDamage = 1234,
                    PosInTeam = 1
                },
                [2] = {
                    PlayerId = 2,
                    HeroTypeId = 200030000,
                    SkinId = 200030001,
                    RescueTimes = 1,
                    PlayerName = "玩家2",
                    PlayerSurvivalTime = 1111,
                    PlayerKill = 3,
                    PlayerAssist = 4,
                    RespawnTimes = 22,
                    PlayerDamage = 333334,
                    PosInTeam = 2
                },
            }
        }
        
        --死斗模式、征服模式、团竞模式
        self.SettlementData = {
            GameplayCfg = {
                TeamType = 4,
                GameplayId = 10005,
                View = 3,
                LevelId = 1031002,
            },
            Level = 1,              -- 当前等级
            Experience = 50,        -- 当前经验
            DeltaExperience = 120,  -- 增量经验
            GameId = "12700116925991561",
            TeamRank = 1,       -- 队伍排名
            TeamCount = 1,      -- 队伍数量
            PlayerArray = {
                [13874757660] = {
                    PlayerDamage = 300,
                    PosInTeam = 2,
                    PlayerAssist = 2,
                    HeroTypeId = 200020000,
                    PlayerDeath = 3,
                    PlayerScore = 3,
                    PlayerKill = 3,
                    TeamId = 0,
                    CampId = 3,
                    PlayerName = "",
                    PlayerId = 13874757660,
                },
                [13874757661] = {
                    PlayerDamage = 300,
                    PosInTeam = 2,
                    PlayerAssist = 2,
                    HeroTypeId = 200020000,
                    PlayerDeath = 3,
                    PlayerScore = 3,
                    PlayerKill = 3,
                    TeamId = 0,
                    CampId = 4,
                    PlayerName = "",
                    PlayerId = 13874757661,
                },
            },
        }
    --]]    
    self.SettlementData = nil    
    self.SettlementHideViewCallback = nil
    self.LikedCache = {}
    self.PlayHeroVoiceInfo = nil
    
    self.IsTest = false
    self.LongPressButtonTriggerTime = (CommonUtil.GetParameterConfig(ParameterConfig.YijiansanlianTrigger, 500)) / 1000
    self.TripleButtonTriggerTime = (CommonUtil.GetParameterConfig(ParameterConfig.YijiansanlianKeep, 2000)) / 1000
    self:ClearSettlementData()
end

--[[
    玩家登出或者断线重连
]]
function HallSettlementModel:OnLogout(Data)
    if Data then
        return
    end
    self:DataInit()
end

---清空大厅结算数据
function HallSettlementModel:ClearSettlementData()
    CLog("[cw] HallSettlementModel:ClearSettlementData()")
    self.SettlementData = nil
    self.SettlementType = nil
    self.LikedCache = {}
    -- 结算数据状态类型
    self.SettlementDataStateType = HallSettlementModel.Enum_SettlementDataStateType.Loading
end

-- 设置当前结算数据的状态类型  赋值后会立即刷新界面  所以需要在数据更新后赋值
function HallSettlementModel:SetSettlementDataStateType(SettlementDataStateType)
    if self.SettlementDataStateType ~= SettlementDataStateType then
        self.SettlementDataStateType = SettlementDataStateType
        self:DispatchType(HallSettlementModel.ON_SETTLEMENT_DATA_STATE_UPDATE_EVENT)
    end
end

-- 获取当前结算数据的状态类型
function HallSettlementModel:GetSettlementDataStateType()
    return self.SettlementDataStateType
end

---设置数据，并对队友信息按照位置进行排序
---@param MatchMode number 游戏模式类型，参考 MatchConst.Enum_MatchType
---@param Data table 具体数据结构参考上方注释
function HallSettlementModel:SetSettlementData(MatchMode, Data)
    CLog("[cw] MatchMode: " .. tostring(MatchMode))
    print_r(Data, "[cw] ====Data")

    self.SettlementType = MatchMode
    self.SettlementData = Data

    if self.SettlementData and self.SettlementData.PlayerArray then 
        --大逃杀模式
        if self.SettlementType == MatchConst.Enum_MatchType.Survive then
            -- 获取服务器数据后做个转换 目前服务器的是无序map
            self.SettlementData.SortPlayerArray = {}
            for PlayerId, PlayerInfo in pairs(self.SettlementData.PlayerArray) do
                local CurIndex = #self.SettlementData.SortPlayerArray + 1
                self.SettlementData.SortPlayerArray[CurIndex] = DeepCopy(PlayerInfo)
                self.SettlementData.SortPlayerArray[CurIndex].PlayerId = PlayerId
            end
            table.sort(self.SettlementData.PlayerArray, function(a, b) return a.PosInTeam < b.PosInTeam end)
            self:SetSettlementRankInfo()
            self:SetCompleteAchieveList()
            self:SetPlayHeroVoiceInfo()
        --死斗模式
        elseif self.SettlementType == MatchConst.Enum_MatchType.DeathMatch then
            --这里只应该存在一份玩家数据，目前的测试数据后台会下发多条数据，客户端先做个过滤，后续督促服务器删除
            ---@type UserModel
            local UserModel = MvcEntry:GetModel(UserModel)
            local PlayerId = UserModel:GetPlayerId()
            local PlayerData = {}
            for playerId, PlayerInfo in pairs(self.SettlementData.PlayerArray) do
                if playerId == PlayerId then
                    PlayerData = PlayerInfo
                end
            end
            self.SettlementData.PlayerArray = {}
            self.SettlementData.PlayerArray[1] = PlayerData
            
        --征服模式
        elseif self.SettlementType == MatchConst.Enum_MatchType.Conqure then
            local PlayerArray = {}
            for k, v in pairs(self.SettlementData.PlayerArray) do PlayerArray[v.PosInTeam] = v end
            self.SettlementData.PlayerArray = PlayerArray
            table.sort(self.SettlementData.PlayerArray, function(a, b) return a.PosInTeam < b.PosInTeam end)
        --团竞模式
        elseif self.SettlementType == MatchConst.Enum_MatchType.TeamMatch then
            local PlayerArray = {}
            for k, v in pairs(self.SettlementData.PlayerArray) do PlayerArray[v.PosInTeam] = v end
            self.SettlementData.PlayerArray = PlayerArray
            table.sort(self.SettlementData.PlayerArray, function(a, b) return a.PosInTeam < b.PosInTeam end)
        end

        self:SetSettlementDataStateType(HallSettlementModel.Enum_SettlementDataStateType.Normal)
    else
        self:SetSettlementDataStateType(HallSettlementModel.Enum_SettlementDataStateType.Loading)
    end
end

-- 设置结算排位相关信息
function HallSettlementModel:SetSettlementRankInfo()
    -- 排位模式结算数据处理
    if self.SettlementData then
        self.SettlementData.IsRankMode = self.SettlementData.PlayModeId and MvcEntry:GetModel(SeasonRankModel):CheckIsRankModeByPlayModeId(self.SettlementData.PlayModeId) or false
        if self.SettlementData.IsRankMode then
            local DivisionResultType = HallSettlementModel.Enum_DivisionResultType.UnchangedDivision
            if self.SettlementData.OldDivisionId ~= self.SettlementData.NewDivisionId then
                DivisionResultType = self.SettlementData.NewDivisionId > self.SettlementData.OldDivisionId and HallSettlementModel.Enum_DivisionResultType.UpgradeDivision or HallSettlementModel.Enum_DivisionResultType.DowngradeDivision
            end
            ---@class DivisionSettlementData
            ---@field DivisionResultType number 排位结算结果类型
            ---@field OldDivisionId number 上一个段位Id
            ---@field NewDivisionId number 当前段位Id
            ---@field WinPoint number 当前胜点
            ---@field DeltaWinPoint number 变化的胜点
            ---@field DeltaRankRating number 变化的排名分
            ---@field PerformanceRating number 当前的表现分
            ---@field GradeName string 评价等级
            ---@field TeamRank number 队伍排名(和队伍所在阵营一致)
            ---@field TeamCount number 所有队伍个数
            local DivisionSettlementData = {
                DivisionResultType = DivisionResultType,
                OldDivisionId = self.SettlementData.OldDivisionId,
                NewDivisionId = self.SettlementData.NewDivisionId,
                WinPoint = self.SettlementData.WinPoint,
                DeltaWinPoint = self.SettlementData.DeltaWinPoint,
                DeltaRankRating = self.SettlementData.DeltaRankRating,
                PerformanceRating = self.SettlementData.PerformanceRating,
                GradeName = self.SettlementData.GradeName,
                TeamRank = self.SettlementData.TeamRank,
                TeamCount = self.SettlementData.TeamCount,
            }
            self.SettlementData.DivisionSettlementData = DivisionSettlementData 
        end
    end
end

-- 设置完成的成就信息
function HallSettlementModel:SetCompleteAchieveList()
    if self.SettlementData and self.SettlementData.Task2AchieveIds and self.SettlementData.CompletedTasks then
        local CompleteAchieveList = {}
        for TaskId, AchieveId in pairs(self.SettlementData.Task2AchieveIds) do
            CompleteAchieveList[#CompleteAchieveList + 1] = AchieveId
        end
        self.SettlementData.CompleteAchieveList = CompleteAchieveList
    end
end

---@return number 游戏模式类型，参考 MatchConst.Enum_MatchType
function HallSettlementModel:GetSettlementCacheType()
    return self.SettlementType or MatchConst.Enum_MatchType.Survive
end

---获取是否有大厅结算数据缓存
---@return boolean
function HallSettlementModel:HasSettlementCache()
    return self.SettlementData and next(self.SettlementData)
end

---是否排位赛模式结算  排位赛模式 需要先弹排位结算再显示结算面板
---@return boolean
function HallSettlementModel:CheckIsRankModeSettlement()
    return self.SettlementData and self.SettlementData.IsRankMode
end

---是否自建房模式
---@return boolean
function HallSettlementModel:CheckIsCustomRoomMode()
    -- 不为0时，标识为自建房，为0则为非自建房
    return self.SettlementData and self.SettlementData.OwnerId and self.SettlementData.OwnerId > 0
end

---是否显示继续按钮  死斗模式&自建房不显示继续按钮
---@return boolean
function HallSettlementModel:CheckIsShowContinueBtn()
    local IsShow = true 
    local SettlementCacheType = self:GetSettlementCacheType()
    local IsCustomRoomMode = self:CheckIsCustomRoomMode()
    if SettlementCacheType == MatchConst.Enum_MatchType.DeathMatch or IsCustomRoomMode then
        IsShow = false
    end
    return IsShow
end

---是否段位升级
---@return boolean
function HallSettlementModel:CheckIsUpgradeDivision()
    return self.SettlementData and self.SettlementData.DivisionSettlementData and self.SettlementData.DivisionSettlementData.DivisionResultType == HallSettlementModel.Enum_DivisionResultType.UpgradeDivision
end

---设置关闭界面回调，在关闭界面时会触发，触发后清空
---@param hideViewCallback function 关闭大厅结算界面时需要触发的回调
function HallSettlementModel:SetHideViewCallbackFunc(hideViewCallback)
    self.SettlementHideViewCallback = hideViewCallback
end

---触发关闭界面时候的回调，并清空
function HallSettlementModel:ExecuteHideViewCallback()
    local HallSceneMgr = _G.HallSceneMgrInst
    if not HallSceneMgr then
        ReportError("ExecuteHideViewCallback HallSceneMgr Is nil !!!!",true)
        return
    elseif not HallSceneMgr.CameraMgr then
        ReportError("ExecuteHideViewCallback CameraMgr Is nil !!!!",true)
        return
    end
    if self.SettlementHideViewCallback then
        self.SettlementHideViewCallback()        
    end
    self.SettlementHideViewCallback = nil
end

---检查这一局中，有没有赞过这名玩家
---@param PlayerId number 需要检查的玩家id
---@return boolean 是否已赞过
function HallSettlementModel:IsLiked(GameId, PlayerId)
    if not self.LikedCache then self.LikedCache = {} end
    if not self.LikedCache[GameId] then self.LikedCache[GameId] = {} end
    
    return self.LikedCache[GameId][PlayerId]
end

---缓存赞
---@param PlayerId number 需要点赞的玩家id
---@return boolean 是缓存成功
function HallSettlementModel:AddLike(GameId, TeamId, PlayerId)
    if self:IsLiked(GameId, PlayerId) then
        CWaring("[cw] Player Already liked")
        return false
    end

    if not self.LikedCache then self.LikedCache = {} end
    if not self.LikedCache[GameId] then self.LikedCache[GameId] = {} end
    self.LikedCache[GameId][PlayerId] = true

    local Msg = {
        TargetPlayerId = tonumber(PlayerId),
        GameId = tostring(GameId),
    }
    
    ---@type PersonalInfoCtrl
    local PersonalInfoCtrl = MvcEntry:GetCtrl(PersonalInfoCtrl)
    PersonalInfoCtrl:SendProto_PlayerLikeReq(Msg)
    
    return true
end

---@return number 获取到当局游戏的GameID
function HallSettlementModel:GetGameId()
    --大逃杀模式
    if self.SettlementType == MatchConst.Enum_MatchType.Survive then
        return self.SettlementData.GameId

    --死斗模式、征服模式、团竞模式
    elseif self.SettlementType == MatchConst.Enum_MatchType.DeathMatch or
            self.SettlementType == MatchConst.Enum_MatchType.Conqure or
            self.SettlementType == MatchConst.Enum_MatchType.TeamMatch then

        return self.SettlementData.GameId
    end
    
    return -1
end

---获取地图名
---@return string
function HallSettlementModel:GetMapName()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)      
    -- local SceneId = MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(self.SettlementData.GameplayCfg.LevelId)
    local SceneId = self.SettlementData.GameplayCfg.SceneId or MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(self.SettlementData.GameplayCfg.LevelId)
    local SceneName = MatchModeSelectModel:GetSceneEntryCfg_SceneName(SceneId)
    return StringUtil.Format(SceneName)
end

---获取上一局游戏的游戏模式
---@return string 模式类型
function HallSettlementModel:GetGameType()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    -- local ModeId = MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(self.SettlementData.GameplayCfg.LevelId)
    local ModeId = self.SettlementData.GameplayCfg.ModeId or MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(self.SettlementData.GameplayCfg.LevelId)
    local ModeType = MatchModeSelectModel:GetModeEntryCfg_ModeType(ModeId)
    return ModeType
end

---@return boolean 上一局游戏是否是 **大逃杀(BR)** 模式
function HallSettlementModel:IsGameType_Survive()    return self:GetGameType() == require("Client.Modules.Match.MatchConst").Enum_MatchType.Survive    end
---@return boolean 上一局游戏是否是 **征服** 模式
function HallSettlementModel:IsGameType_Conqure()    return self:GetGameType() == require("Client.Modules.Match.MatchConst").Enum_MatchType.Conqure    end
---@return boolean 上一局游戏是否是 **团队竞技** 模式
function HallSettlementModel:IsGameType_TeamMatch()  return self:GetGameType() == require("Client.Modules.Match.MatchConst").Enum_MatchType.TeamMatch  end
---@return boolean 上一局游戏是否是 **死斗** 模式
function HallSettlementModel:IsGameType_DeathMatch() return self:GetGameType() == require("Client.Modules.Match.MatchConst").Enum_MatchType.DeathMatch end

---获取游戏模式
---@return string
function HallSettlementModel:GetGameMode()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    -- local ModeId = MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(self.SettlementData.GameplayCfg.LevelId)
    local ModeId = self.SettlementData.GameplayCfg.ModeId or MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(self.SettlementData.GameplayCfg.LevelId)
    local ModeType = MatchModeSelectModel:GetModeEntryCfg_ModeName(ModeId)
    return StringUtil.Format(ModeType)
end

---@return number 上一局游戏获得的经验
function HallSettlementModel:GetGainedExp()
    return self.SettlementData.DeltaExperience or 0
end

---获取升级之前的等级和经验
---@return number, number 之前的等级，之前的经验
function HallSettlementModel:GetBeforeLvlExp()
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local _l, _e = UserModel:GetPlayerLvAndExp() 
    local exp = self.SettlementData.Experience or _e
    local lvl = self.SettlementData.Level or _l
    local totalExpGot = self.SettlementData.DeltaExperience or 0

    while totalExpGot > 0 and lvl > 0 do        
        --这里说明升级了
        if totalExpGot == exp then
            return lvl, 0
        elseif totalExpGot > exp then
            lvl = lvl - 1
            totalExpGot = totalExpGot - exp
            exp = UserModel:GetPlayerMaxExpForLv(lvl)
        else
            exp = exp - totalExpGot
            return lvl, exp
        end
    end
    
    return lvl, exp    
end

---获取排名
---@return number 如果是 -1 就代表有问题
function HallSettlementModel:GetRankNum()
    --大逃杀模式
    if self.SettlementType == MatchConst.Enum_MatchType.Survive then
        return self.SettlementData.TeamRank

    --死斗模式、征服模式、团竞模式
    elseif self.SettlementType == MatchConst.Enum_MatchType.DeathMatch or
            self.SettlementType == MatchConst.Enum_MatchType.Conqure or
            self.SettlementType == MatchConst.Enum_MatchType.TeamMatch then

        return self.SettlementData.TeamRank
    end
    
    return -1
end

---获取队伍总数
---@return number 如果是 -1 就代表有问题
function HallSettlementModel:GetTotalTeams()
    --大逃杀模式
    if self.SettlementType == MatchConst.Enum_MatchType.Survive then
        return self.SettlementData.TeamCount

    --死斗模式、征服模式、团竞模式
    elseif self.SettlementType == MatchConst.Enum_MatchType.DeathMatch or
            self.SettlementType == MatchConst.Enum_MatchType.Conqure or
            self.SettlementType == MatchConst.Enum_MatchType.TeamMatch then

        return self.SettlementData.TeamCount
    end
    
    return -1
end

---获取队友及自己的信息
---@return table
function HallSettlementModel:GetTeammates()
    local Teammates = {}
    local SettlementDataStateType = self:GetSettlementDataStateType()
    if SettlementDataStateType == HallSettlementModel.Enum_SettlementDataStateType.Normal then
           --大逃杀模式
        if self.SettlementType == MatchConst.Enum_MatchType.Survive then
            return self.SettlementData.SortPlayerArray or Teammates
            
        --死斗模式、征服模式、团竞模式
        elseif self.SettlementType == MatchConst.Enum_MatchType.DeathMatch or
                self.SettlementType == MatchConst.Enum_MatchType.Conqure or
                self.SettlementType == MatchConst.Enum_MatchType.TeamMatch then
        
            return self.SettlementData.PlayerArray
        end 
    elseif SettlementDataStateType == HallSettlementModel.Enum_SettlementDataStateType.Loading then
        Teammates = {
            {
                IsEmptyBroad = true,
            },
            {
                IsEmptyBroad = true,
            },
            {
                IsEmptyBroad = true,
            },
            {
                IsEmptyBroad = true,
            },
        }
    end
         
    return Teammates
end

---获取自己的通行证信息
---@return table
function HallSettlementModel:GetSeasonPassInfo()
    local SeasonPassInfo = {}
    --大逃杀模式
    if self.SettlementType == MatchConst.Enum_MatchType.Survive then
        SeasonPassInfo = {
            -- 通行证等级
            PassLevel = self.SettlementData.PassLevel,
            -- 通行证变化等级数，如 +1，+2
            DeltaPassLevel = self.SettlementData.DeltaPassLevel,
            -- 通行证经验
            PassExp = self.SettlementData.PassExp,
            -- 通行证变化的经验，如 +20
            DeltaPassExp = self.SettlementData.DeltaPassExp
        }
    end
    return SeasonPassInfo
end

---获取任务完成对应成就Id列表
---@return table
function HallSettlementModel:GetTask2AchieveIdList()
    local Task2AchieveIds = (self.SettlementData and self.SettlementData.CompleteAchieveList ~= nil) and self.SettlementData.CompleteAchieveList or {}
    return Task2AchieveIds
end

---获取消息提示列表
---@return table
function HallSettlementModel:GetMessageTipList()
    local MessageTipList = {}
    --大逃杀模式
    if self.SettlementType == MatchConst.Enum_MatchType.Survive then
        ---@type TaskModel
        local TaskModel = MvcEntry:GetModel(TaskModel)
        ---@type AchievementModel
        local AchievementModel = MvcEntry:GetModel(AchievementModel)
        ---@type DepotModel
        local DepotModel = MvcEntry:GetModel(DepotModel)

        -- 任务完成相关
        -- 任务成就映射map, key为任务id，value为成就id
        local Task2AchieveIds = self.SettlementData.Task2AchieveIds
        -- 当前对局完成的任务,key为任务id，value为任务来源
        local CompletedTasks = self.SettlementData.CompletedTasks
        if Task2AchieveIds and CompletedTasks then
            local CompleteAchieveList = {}
            for TaskId, TaskSource in pairs(CompletedTasks) do
                local MessageType = HallSettlementModel.Enum_MessageTipType.TaskComplete
                local TextContent = ""
                local TextDesc = ""
                local ItemId = 0
                local ItemNum = 0
                local Quality = 0
                -- 普通任务
                local RewardItemId, RewardItemNum = TaskModel:GetTaskRewardItemInfo(TaskId)
                if RewardItemId and RewardItemId > 0 and RewardItemNum then
                    -- 有奖励的任务走奖励样式
                    MessageType = HallSettlementModel.Enum_MessageTipType.TaskReward
                    -- 显示奖励名称
                    TextContent = DepotModel:GetItemName(RewardItemId)
                    -- 显示任务描述
                    TextDesc = TaskModel:GetTaskDescription(TaskId)
                    ItemId = RewardItemId
                    ItemNum = RewardItemNum
                    Quality = DepotModel:GetQualityByItemId(RewardItemId) or 0
                else
                    -- 没奖励的普通任务样式
                    MessageType = HallSettlementModel.Enum_MessageTipType.TaskComplete
                    TextContent = TaskModel:GetTaskDescription(TaskId)
                    TextDesc = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Settlement", "TaskComplete")
                end
                ---@class HallSettlementMessageTip
                ---@field MessageType number 消息提示类型 HallSettlementModel.Enum_MessageTipType
                ---@field TextContent string 文本内容
                ---@field TextDesc string 文本描述
                ---@field ItemId number 物品ID
                ---@field ItemNum number 物品数量
                ---@field Quality number 品质
                ---@field AdditiveCardNum number? 加成卡数值 不传值或0 即为没有加成
                local MessageTip = {
                    MessageType = MessageType,
                    TextContent = TextContent,
                    TextDesc = TextDesc,
                    ItemId = ItemId,
                    ItemNum = ItemNum, 
                    Quality = Quality,
                    AdditiveCardNum = 0,
                }
                MessageTipList[#MessageTipList + 1] = MessageTip
            end

            for _, AchieveId in pairs(Task2AchieveIds) do
                -- 成就任务
                local MessageType = HallSettlementModel.Enum_MessageTipType.AchievementGet
                local TextContent = AchievementModel:GetAchievementNameByUniId(AchieveId)
                local TextDesc = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Settlement", "GetAchievements")
                local ItemId = AchievementModel:ConvertUniId2GroupId(AchieveId)
                local ItemNum = 1
                local Quality = AchievementModel:GetAchievementQualityByUniId(AchieveId)
                ---@type HallSettlementMessageTip
                local MessageTip = {
                    MessageType = MessageType,
                    TextContent = TextContent,
                    TextDesc = TextDesc,
                    ItemId = ItemId,
                    ItemNum = ItemNum, 
                    Quality = Quality,
                    AdditiveCardNum = 0,
                }
                MessageTipList[#MessageTipList + 1] = MessageTip
            end
        end

        -- 道具掉落相关
        -- 结算获取的奖励物品数组
        local RewardItems = self:GetDropRewardItems()
        for _, RewardItem in ipairs(RewardItems) do
            local ItemId = RewardItem.ItemId
            local ItemNum = RewardItem.ItemCount
            if ItemId > 0 and ItemNum > 0 then
                local RewardType = RewardItem.RewardType
                local ItemName = DepotModel:GetItemName(ItemId)
                local TextContent = self:GetDropRewardTextContent(RewardType, ItemName, ItemNum)
                local AdditiveCardNum = self:GetDropRewardAdditiveCardNum(ItemId)
                local TextDesc = self:GetDropRewardTextDesc(RewardType, ItemNum, AdditiveCardNum)
                ---@type HallSettlementMessageTip
                local MessageTip = {
                    MessageType = HallSettlementModel.Enum_MessageTipType.PropDrop,
                    TextContent = TextContent,
                    TextDesc = TextDesc,
                    ItemId = ItemId,
                    ItemNum = ItemNum, 
                    Quality = DepotModel:GetQualityByItemId(ItemId) or 0,
                    AdditiveCardNum = AdditiveCardNum
                }
                MessageTipList[#MessageTipList + 1] = MessageTip 
            end
        end
    end
    return MessageTipList
end

-- 根据掉落奖励类型获取对应的文本内容
function HallSettlementModel:GetDropRewardTextContent(RewardType, ItemName, ItemNum)
    local TextContent = ""
    if RewardType == Pb_Enum_SettlementRewardSrcType.SettlementRewardSrcTypeCoin then
        TextContent = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Settlement", "MatchAcquisition"), ItemName)
    elseif RewardType == Pb_Enum_SettlementRewardSrcType.SettlementRewardSrcTypeLevelUp then
        TextContent = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Settlement", "LevelReward"), ItemName, ItemNum)
    elseif RewardType == Pb_Enum_SettlementRewardSrcType.SettlementRewardSrcTypeGrowthMoney then
        TextContent = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Settlement", "GrowthMoney"))
    else
        TextContent = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Settlement", "MatchAcquisition"), ItemName)
    end
    return TextContent
end

-- 根据掉落奖励类型获取对应的文本描述
function HallSettlementModel:GetDropRewardTextDesc(RewardType, ItemNum, AdditiveCardNum)
    local TextDesc = ""
    -- 判断是否有加成卡
    if AdditiveCardNum and AdditiveCardNum > 0 then
        TextDesc = StringUtil.Format("+{0}%", AdditiveCardNum / 10)
    elseif RewardType == Pb_Enum_SettlementRewardSrcType.SettlementRewardSrcTypeGrowthMoney then
        TextDesc = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Settlement", "ItemNumDesc"), StringUtil.FormatNumberWithComma(ItemNum))
    end
    return TextDesc
end

-- 根据掉落奖励物品ID获取对应的加成卡数据
function HallSettlementModel:GetDropRewardAdditiveCardNum(ItemId)
    local UserModel = MvcEntry:GetModel(UserModel)
    local AdditiveCardNum = 0
    -- 目前只有金币跟经验需要判断加成卡
    if ItemId == DepotConst.ITEM_ID_GOLDEN  then
        local AddInfo = UserModel:GetPlayerGoldAddInfo()
        AdditiveCardNum = AddInfo and AddInfo.AddValue or 0
    elseif ItemId == DepotConst.ITEM_ID_EXP then
        local AddInfo = UserModel:GetPlayerExpAddInfo()
        AdditiveCardNum = AddInfo and AddInfo.AddValue or 0
    end
    return AdditiveCardNum
end

-- 获取对局掉落的奖励信息
function HallSettlementModel:GetDropRewardItems()
    -- 道具掉落相关
    -- 结算获取的奖励物品数组
    local RewardItems = (self.SettlementData and self.SettlementData.RewardItems) and DeepCopy(self.SettlementData.RewardItems) or {}
    local DeltaExperience = self:GetGainedExp()
    local UserModel = MvcEntry:GetModel(UserModel)
    local AddInfo = UserModel:GetPlayerExpAddInfo()
    local AdditiveCardNum = AddInfo and AddInfo.AddValue or 0
    if DeltaExperience > 0 and AdditiveCardNum > 0 then
        -- 经验的道具要客户端自己加上去
        local ExpRewardItem =  {
            ItemId = DepotConst.ITEM_ID_EXP;
            ItemCount = DeltaExperience;
            RewardType = Pb_Enum_SettlementRewardSrcType.Coin;
        } 
        RewardItems[#RewardItems + 1] = ExpRewardItem
    end
    return RewardItems
end

---获取上一局对战中，玩家使用的英雄id
---@return number
function HallSettlementModel:GetLastMatchPlayerUsedHeroId()
    local teammatesInfo = self:GetTeammates()
    local res = 200030000
    if teammatesInfo and next(teammatesInfo) then
        for _, info in ipairs(teammatesInfo) do
            if info.PlayerId == MvcEntry:GetModel(UserModel):GetPlayerId() then
                res = info.HeroTypeId
                break
            end
        end
    end    
    return res
end

---获取上一局对战中，玩家使用的英雄皮肤id
---@return number
function HallSettlementModel:GetLastMatchPlayerUsedHeroSkinId()
    local teammatesInfo = self:GetTeammates()
    local res
    if teammatesInfo and next(teammatesInfo) then
        for _, info in ipairs(teammatesInfo) do
            if info.PlayerId == MvcEntry:GetModel(UserModel):GetPlayerId() then
                res = info.SkinId
                break
            end
        end
    end    
    return res
end

---获取长按效果的触发时间  即按下按钮X秒后变成长按 
function HallSettlementModel:GetLongPressButtonTriggerTime()
    return self.LongPressButtonTriggerTime
end

---获取三连按钮的触发时间
function HallSettlementModel:GetTripleButtonTriggerTime()
    return self.TripleButtonTriggerTime
end

--- 获取三连鼠标倒计时进度条材质参数
---@param MatchType string 参考 MatchConst.Enum_MatchType
---@return string string 光标长按倒计时进度条材质路径 、光标长按倒计时进度条材质参数名
function HallSettlementModel:GetTripleButtonMouseMaterialParam(MatchType)
    local MaterialPath = nil
    local MaterialParam = nil
    local HallSettlementCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HallSettlementConfig, Cfg_HallSettlementConfig_P.ModeType, MatchType)
    if HallSettlementCfg then
        MaterialPath = HallSettlementCfg[Cfg_HallSettlementConfig_P.MaterialPath]
        MaterialParam = HallSettlementCfg[Cfg_HallSettlementConfig_P.MaterialParam]
    end
    return MaterialPath, MaterialParam
end

-- 获取排位结算数据
---@return DivisionSettlementData | nil
function HallSettlementModel:GetDivisionSettlementData()
    local DivisionSettlementData = self.SettlementData and self.SettlementData.DivisionSettlementData or nil
    return DivisionSettlementData
end

-- 获取增加的金币相关信息
---@return number 总共获得的金币 
---@return number 加成卡增加的金币数量 
---@return number 成长货币转换的金币数量
function HallSettlementModel:GetAddGoldInfo()
    -- 总共获得的金币、加成卡增加的金币数量、成长货币转换的金币数量
    local TotalGoldNum, AdditiveCardAddGoldNum, ConversionGoldNum = 0, 0, 0
    if self.SettlementData then 
        -- 成长转换金币值
        local GrowthGoldMoney = self.SettlementData.GrowthGoldMoney or 0
        -- 对局结算基础金币值
        local GoldMoneyBase = self.SettlementData.GoldMoneyBase or 0      
        -- 对局结算加成之后的金币值
        local GoldMoneyCofTotal = self.SettlementData.GoldMoneyCofTotal or 0      
        TotalGoldNum = GrowthGoldMoney + GoldMoneyCofTotal
        AdditiveCardAddGoldNum = GoldMoneyCofTotal - GoldMoneyBase
        ConversionGoldNum = GrowthGoldMoney
    end
    return TotalGoldNum, AdditiveCardAddGoldNum, ConversionGoldNum
end

-- 获取检测数据失败的时间
function HallSettlementModel:GetCheckDataFailTime()
    local DataFailTime = CommonUtil.GetParameterConfig(ParameterConfig.SettlementDataFailTime, 10)
    return DataFailTime
end

--- 设置结算返回大厅后需要播放的角色语音
--- 播放英雄语音，包含四种情况
--- 1) 使用了主界面展示的英雄，且进了前50%
--- 2) 使用了主界面展示的英雄，且没进前50%
--- 3) 没有使用主界面展示的英雄，且进了前50%
--- 4) 没有使用主界面展示的英雄，且没进前50%
function HallSettlementModel:SetPlayHeroVoiceInfo()
    local LastMatchPlayerUsedHeroId = self:GetLastMatchPlayerUsedHeroId()
    ---@type HeroModel
    local HeroModel = MvcEntry:GetModel(HeroModel)
    local PlayerFavoriteHeroId = HeroModel:GetFavoriteId()
    local PlayerFavoriteHeroFavoriteSkinId = HeroModel:GetFavoriteHeroFavoriteSkinId()
    local IsLastMatchPlayerRankInTop50Percent = (self:GetRankNum() / self:GetTotalTeams()) <= 0.5
    self.PlayHeroVoiceInfo = {}
    self.PlayHeroVoiceInfo.SkinId = PlayerFavoriteHeroFavoriteSkinId
    --1.使用的是主界面展示的英雄
    CLog("[cw] LastMatchPlayerUsedHeroId: " .. tostring(LastMatchPlayerUsedHeroId))
    CLog("[cw] PlayerFavoriteHeroId: " .. tostring(PlayerFavoriteHeroId))
    CLog("[cw] PlayerFavoriteHeroFavoriteSkinId: " .. tostring(PlayerFavoriteHeroFavoriteSkinId))
    if LastMatchPlayerUsedHeroId == PlayerFavoriteHeroId then
        --1.1.进了前50%
        if IsLastMatchPlayerRankInTop50Percent then
            CLog("[cw] used favorite hero and rank in 50%")
            self.PlayHeroVoiceInfo.EventID = SoundCfg.Voice.HALL_SETTLEMENT_FAVORITE_WIN_TOP50P

            --1.2.没进前50%
        else
            CLog("[cw] used favorite hero and rank not in 50%")
            self.PlayHeroVoiceInfo.EventID = SoundCfg.Voice.HALL_SETTLEMENT_FAVORITE_WIN_NOT_TOP50P
        end

        --2.使用的不是主界面展示的英雄
    else
        --2.1.进了前50%
        if IsLastMatchPlayerRankInTop50Percent then
            CLog("[cw] not used favorite hero and rank in 50%")
            self.PlayHeroVoiceInfo.EventID = SoundCfg.Voice.HALL_SETTLEMENT_NOT_FAVORITE_WIN_TOP50P
            --2.2.没进前50%
        else
            CLog("[cw] not used favorite hero and rank not in 50%")
            self.PlayHeroVoiceInfo.EventID = SoundCfg.Voice.HALL_SETTLEMENT_NOT_FAVORITE_WIN_NOT_TOP50P
        end
    end
end

-- 获取结算需要播放的角色语音信息
function HallSettlementModel:GetPlayHeroVoiceInfo()
    return self.PlayHeroVoiceInfo
end

--- 播放角色语音后清空
function HallSettlementModel:ClearPlayHeroVoiceInfo()
    self.PlayHeroVoiceInfo = nil
end

return HallSettlementModel