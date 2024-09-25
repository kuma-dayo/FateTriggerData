---
--- Model 模块，用于数据存储与逻辑运算
--- Description: 玩家个人信息历史战绩数据存放
--- Created At: 2023/08/04 17:47
--- Created By: 朝文
---

local super = ListModel
local class_name = "PlayerInfo_MatchHistoryModel"
---@class PlayerInfo_MatchHistoryModel : ListModel
PlayerInfo_MatchHistoryModel = BaseClass(super, class_name)
PlayerInfo_MatchHistoryModel.Const = {
    DefaultSendReqHistoryListDelay = 1,
    MinimumRequireMatchHistoryBrifeListTime = 30,   --数据拉取完后，下一次拉取数据的最短间隔时间s
}
local MatchConst = require("Client.Modules.Match.MatchConst")
PlayerInfo_MatchHistoryModel.Enum_HistoryItemLuaPath = {
    [MatchConst.Enum_MatchType.Survive]     = "Client.Modules.PlayerInfo.MatchHistory.PlayerInfo_MatchHistory_Item.PlayerInfo_MatchHistory_Item_Survive",
    [MatchConst.Enum_MatchType.Conqure]     = "Client.Modules.PlayerInfo.MatchHistory.PlayerInfo_MatchHistory_Item.PlayerInfo_MatchHistory_Item_Conqure",
    [MatchConst.Enum_MatchType.TeamMatch]   = "Client.Modules.PlayerInfo.MatchHistory.PlayerInfo_MatchHistory_Item.PlayerInfo_MatchHistory_Item_TeamMatch",
    [MatchConst.Enum_MatchType.DeathMatch]  = "Client.Modules.PlayerInfo.MatchHistory.PlayerInfo_MatchHistory_Item.PlayerInfo_MatchHistory_Item_DeathMatch",
}

PlayerInfo_MatchHistoryModel.ON_GAME_DETAIL_RECORD_GOT = "ON_GAME_DETAIL_RECORD_GOT"    --当获取到历史记录详细信息 

function PlayerInfo_MatchHistoryModel:KeyOf(vo)
    if vo["GameId"] then
        return vo["GameId"]
    end
    return PlayerInfo_MatchHistoryModel.super.KeyOf(self, vo)
end

function PlayerInfo_MatchHistoryModel:__init()
    self:DataInit()
end

function PlayerInfo_MatchHistoryModel:SetIsChange(_)
    --do nothing
end

function PlayerInfo_MatchHistoryModel:AppendList(List)
    for i = #List, 1, -1 do
        self:AppendData(List[i])
    end
    self:DispatchType(PlayerInfo_MatchHistoryModel.ON_CHANGED)
end

---不同于 AppendList，AppendListBegin会把数据插入到 mDataList 的头部
function PlayerInfo_MatchHistoryModel:AppendListBegin(List)
    for i = #List, 1, -1 do
        self:AppendDataBegin(List[i])
    end
    self:DispatchType(PlayerInfo_MatchHistoryModel.ON_CHANGED)
end

---不同于 AppendData，AppendDataBegin会把数据插入到 mDataList 的头部
function PlayerInfo_MatchHistoryModel:AppendDataBegin(item)
    local key = self:KeyOf(item)
    if not self.mDataMap[key]  then
        table.insert(self.mDataList, 1, item)
    end
    self.mDataMap[key] = item
end

--[[
    --大逃杀类型
    GameDetailRecord = {
        BrSettlement = {
            RemainingPlayers = 1 
            RemainingTeams = 1 
            GameId = "127001169174013985" 
            TeamId = 1 
            PlayerMap = { 
                2835349508 = { 
                    RemainingPlayers = 1 
                    RemainingTeams = 1 
                    bRespawnable = false 
                    SkinId = 0 
                    bIsTeamOver = true 
                    PosInTeam = 1 
                    PlayerSurvivalTime = 143.57386779785 
                    HeroTypeId = 200020000 
                    RescueTimes = 0 
                } 
                2835349505 = {
                    ...
                }
            }
        }
    }
    
    --团竞、死斗、征服模式类型
    GameDetailRecord = {
        CampSettlement = {
            TeamRank = 1,
            GameId = "127001169174013985"
            PlayerMap = { 
                2835349508 = { 
                    RemainingPlayers = 1 
                    RemainingTeams = 1 
                    bRespawnable = false 
                    SkinId = 0 
                    bIsTeamOver = true 
                    PosInTeam = 1 
                    PlayerSurvivalTime = 143.57386779785 
                    HeroTypeId = 200020000 
                    RescueTimes = 0 
                } 
                2835349505 = {
                    ...
                }
            }
        }
    }    
--]]
---为历史数据添加详细信息
---@param GameDetailRecord table 详细数据
function PlayerInfo_MatchHistoryModel:AddDetailRecord(GameDetailRecord)
    if not GameDetailRecord or not next(GameDetailRecord) then return nil end
    
    --大逃杀类型数据
    local GameId
    if GameDetailRecord.BrSettlement and GameDetailRecord.BrSettlement.GameId then
        GameId = GameDetailRecord.BrSettlement.GameId
    
    --团竞、死斗、征服类型数据
    elseif GameDetailRecord.CampSettlement and GameDetailRecord.CampSettlement.GameId then
        GameId = GameDetailRecord.CampSettlement.GameId
    end
    
    if not GameId then return false end

    local HistoryData = self:GetData(GameId)
    if not HistoryData then
        HistoryData = {
            GameId = GameId
        }
        self:AppendData(HistoryData)
    end
    HistoryData.DetailData = GameDetailRecord
    self:DispatchType(PlayerInfo_MatchHistoryModel.ON_GAME_DETAIL_RECORD_GOT, GameId)
end

---判断玩家是否以已经拉取过传入GameId的对局详细数据了
---@param GameId number 需要检查的GameId
---@return boolean 传入的GameId是否已经拉取过详细的历史战绩数据了
function PlayerInfo_MatchHistoryModel:IsGotDetailRecordById(GameId)
    local HistoryData = self:GetData(GameId)
    if not HistoryData then
        return
    end
    return HistoryData.DetailData and type(HistoryData.DetailData) == "table" and next(HistoryData.DetailData)
end

---初始化数据，用于第一次调用及登出的时候调用
function PlayerInfo_MatchHistoryModel:DataInit()
    self.IsGotAllMatchHistory = false
end

---玩家登出时调用
function PlayerInfo_MatchHistoryModel:OnLogout(data)
    self:DataInit()
    PlayerInfo_MatchHistoryModel.super.OnLogout(self, data)
end

--region IsGotAllMatchHistory

---封装一个设置 IsGotAllMatchHistory 的方法, 用于设置 是否已经取得了所有的历史数据缓存
---@param newIsGotAllMatchHistory boolean
function PlayerInfo_MatchHistoryModel:SetIsGotAllMatchHistory(newIsGotAllMatchHistory)
    if newIsGotAllMatchHistory == nil then
         CError("[cw] PlayerInfo_MatchHistoryModel trying to set a nil value to IsGotAllMatchHistory, if you wanna do it, please use CleanIsGotAllMatchHistory() instead")
    end
    self.IsGotAllMatchHistory = newIsGotAllMatchHistory
    if newIsGotAllMatchHistory then
        self._GotAllMatchHistoryTime = GetTimestamp()
    end
end

---封装一个获取 IsGotAllMatchHistory 的方法，用于获取 是否已经取得了所有的历史数据缓存
---@return boolean
function PlayerInfo_MatchHistoryModel:GetIsGotAllMatchHistory()
    return self.IsGotAllMatchHistory
end

---结合GetIsGotAllMatchHistory使用，当GetIsGotAllMatchHistory为true时，调用判断上一次获取到全部数据的时间与现在的时间差是否大于可再次请求一次数据的条件
---@return boolean
function PlayerInfo_MatchHistoryModel:GetIsAvaliableForNextReq()
    self._GotAllMatchHistoryTime = self._GotAllMatchHistoryTime or 0
    return PlayerInfo_MatchHistoryModel.Const.MinimumRequireMatchHistoryBrifeListTime <= math.abs(self._GotAllMatchHistoryTime - GetTimestamp())
end

---封装一个清空 IsGotAllMatchHistory 的方法，用于去除 是否已经取得了所有的历史数据缓存
function PlayerInfo_MatchHistoryModel:CleanIsGotAllMatchHistory()
    self.IsGotAllMatchHistory = nil
end

--endregion IsGotAllMatchHistory

---通过GameId获取到玩家使用的英雄
---@param GameId number 需要检查的GameId
---@return number 玩家在那局游戏中使用的角色id
function PlayerInfo_MatchHistoryModel:GetPlayerUsedHeroById(GameId)
    local Data = self:GetData(GameId)
    if not Data then 
        CError("[cw] Cannot find player used hero by gameid(" .. tostring(GameId) .. ")")
        return -1 
    end
    return Data.GeneralData.HeroId
end

---通过GameId获取到模式类型
---@param GameId number 需要检查的GameId
---@return string MatchConst.Enum_MatchType.Survive|TeamMatch|DeathMatch|Conqure
function PlayerInfo_MatchHistoryModel:GetGameModeById(GameId)
    local Data = self:GetData(GameId)
    if not Data.GeneralData then
        return MatchConst.Enum_MatchType.Survive
    end
    local LevelId = Data.GeneralData.GameplayCfg.LevelId
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    -- local ModeId = MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(LevelId)
    local ModeId = Data.GeneralData.GameplayCfg.ModeId or MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(LevelId)
    local ModeType = MatchModeSelectModel:GetModeEntryCfg_ModeType(ModeId)
    return ModeType
end

---通过GameId获取到模式名
---@param GameId number 需要检查的GameId
---@return string 已本地化的玩法名称
function PlayerInfo_MatchHistoryModel:GetGameModeNameById(GameId)
    local Data = self:GetData(GameId)
    if not Data.GeneralData then
        return ""
    end
    local LevelId = Data.GeneralData.GameplayCfg.LevelId
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    -- local ModeId = MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(LevelId)
    local ModeId = Data.GeneralData.GameplayCfg.ModeId or MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(LevelId)
    local ModeTypeName = MatchModeSelectModel:GetModeEntryCfg_ModeName(ModeId)
    return StringUtil.Format(ModeTypeName)
end

---通过GameId获取到地图场景名
---@param GameId number 需要检查的GameId
---@return string 已本地化的地图场景名
function PlayerInfo_MatchHistoryModel:GetSceneNameById(GameId)
    local Data = self:GetData(GameId)
    if not Data.GeneralData then
        return ""
    end
    local LevelId = Data.GeneralData.GameplayCfg.LevelId
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    -- local SceneId = MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(LevelId)
    local GameSceneId = Data.GeneralData.GameplayCfg.SceneId
    local SceneId = GameSceneId ~= 0 and GameSceneId or MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(LevelId)
    local SceneName = MatchModeSelectModel:GetSceneEntryCfg_SceneName(SceneId)
    return StringUtil.Format(SceneName)
end

---通过GameId获取到玩家详细信息里面的排名
---@param GameId number 需要检查的GameId
---@return number 玩家在当前对局中的排名通过GameId获取到玩家详细信息里面的排名
function PlayerInfo_MatchHistoryModel:GetDetailRankById(GameId)
    local GameMode = self:GetGameModeById(GameId)
    if GameMode == MatchConst.Enum_MatchType.Survive then
        return self:GetData(GameId).DetailData.BrSettlement.TeamRank
        
    elseif GameMode == MatchConst.Enum_MatchType.DeathMatch or
            GameMode == MatchConst.Enum_MatchType.TeamMatch or
            GameMode == MatchConst.Enum_MatchType.Conqure then
        return self:GetData(GameId).DetailData.CampSettlement.TeamRank
    end
end

---通过GameId获取到详细信息里面的队伍总数
---@param GameId number 需要检查的GameId
---@return number 玩家在当前对局中的队伍总数
function PlayerInfo_MatchHistoryModel:GetDetailTotalTeamById(GameId)
    local GameMode = self:GetGameModeById(GameId)
    if GameMode == MatchConst.Enum_MatchType.Survive then
        return self:GetData(GameId).DetailData.BrSettlement.TeamCount

    elseif GameMode == MatchConst.Enum_MatchType.DeathMatch or
            GameMode == MatchConst.Enum_MatchType.TeamMatch or
            GameMode == MatchConst.Enum_MatchType.Conqure then
        return self:GetData(GameId).DetailData.CampSettlement.TeamCount
    end
end

---通过GameId获取详细信息里面的队伍信息
---@return table
function PlayerInfo_MatchHistoryModel:GetDetailTeammatesById(GameId)
    local DetailTeammates = {}
    local PlayerMap  = {}
    local GameMode = self:GetGameModeById(GameId)
    if GameMode == MatchConst.Enum_MatchType.Survive then
        PlayerMap = self:GetData(GameId).DetailData.BrSettlement.PlayerMap 
    elseif GameMode == MatchConst.Enum_MatchType.DeathMatch or
            GameMode == MatchConst.Enum_MatchType.TeamMatch or
            GameMode == MatchConst.Enum_MatchType.Conqure then
        PlayerMap = self:GetData(GameId).DetailData.CampSettlement.PlayerMap
    end

    if PlayerMap then
        -- 获取服务器数据后做个转换 目前服务器的是无序map
        for PlayerId, PlayerInfo in pairs(PlayerMap) do
            local CurIndex = #DetailTeammates + 1
            DetailTeammates[CurIndex] = DeepCopy(PlayerInfo)
            DetailTeammates[CurIndex].PlayerId = PlayerId
        end
        table.sort(DetailTeammates, function(a, b) return a.PosInTeam < b.PosInTeam end)
    end
    return DetailTeammates
end

return PlayerInfo_MatchHistoryModel