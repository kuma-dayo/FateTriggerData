require("Client.Modules.RankSystem.RankDefine");

local super = ListModel
local class_name = "RankSystemModel"

---@class RankSystemModel : ListModel
---@field private super ListModel
RankSystemModel = BaseClass(super, class_name)



function RankSystemModel:__init()
    self:_dataInit()
end

function RankSystemModel:_dataInit()
    self:Clean()
    self.RankList = nil
    self.SelfRankInfo = nil
    self.RankInfoCacheTimeOut = nil
end

function RankSystemModel:OnGameInit()
    RankSystemModel.UnitText = {
        [RankDefine.Type.Skin]      =   {Unit = "", ShowUnit = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_RankSystemModel_Skinquantity"))},
        [RankDefine.Type.Hero]      =   {Unit = "", ShowUnit = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_RankSystemModel_Numberofvisionaries"))},
        [RankDefine.Type.Liked]     =   {Unit = "", ShowUnit = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_RankSystemModel_Heatvalue"))},
        [RankDefine.Type.Victory]   =   {Unit = "", ShowUnit = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_RankSystemModel_Numberofvictorygames"))},
        [RankDefine.Type.Kill]      =   {Unit = "", ShowUnit = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_RankSystemModel_Killingquantity"))},
        [RankDefine.Type.Score]     =   {Unit = "", ShowUnit = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_RankSystemModel_integration"))},
    }
end

--- 玩家登出时调用
---@param data any
function RankSystemModel:OnLogout(data)
    RankSystemModel.super.OnLogout(self)
    self:_dataInit()
end

--- 玩家登出时调用
---@param data any
function RankSystemModel:OnLogin(data)
    RankSystemModel.super.OnLogin(self)
end

function RankSystemModel:AddRankList(RankTypeId, Location, List)
    self.RankList = self.RankList or {}
    self.RankList[RankTypeId] = List
    self:SetRankInfoCacheTime(RankTypeId)
end

function RankSystemModel:ConvertTypeId2Type(RankTypeId)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_RankConfig, RankTypeId)
    if not Cfg then
        CWaring("[RankSystemModel] ConvertTypeId2Type Cfg is nil, RankTypeId = " .. RankTypeId)
        return
    end
    return Cfg[Cfg_RankConfig_P.RankType], Cfg[Cfg_RankConfig_P.ModeType]
end

function RankSystemModel:ConvertType2TypeId(RankType, ModeId)
    local Cfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_RankConfig, {Cfg_RankConfig_P.RankType, Cfg_RankConfig_P.ModeType}, {RankType , ModeId})
    if not Cfg then
        CWaring("[RankSystemModel] ConvertType2TypeId Cfg is nil, RankType = " .. RankType .. ", ModeId = " .. ModeId)
        return
    end
    return Cfg[Cfg_RankConfig_P.RankId]
end

function RankSystemModel:GetRankList(RankTypeId, Location)
    self.RankList = self.RankList or {}
    return self.RankList[RankTypeId]
end

function RankSystemModel:SetSelfRankInfo(RankTypeId, Rank, Score)
    if not RankTypeId then
        return
    end
    self.SelfRankInfo = self.SelfRankInfo or {}
    self.SelfRankInfo[RankTypeId] = self.SelfRankInfo[RankTypeId] or {}
    local TempRank = Rank or self.SelfRankInfo[RankTypeId].Rank
    local TempScore = Score or self.SelfRankInfo[RankTypeId].Score
    self.SelfRankInfo[RankTypeId] = {
        Rank = TempRank,
        Score = TempScore,
    }
end

function RankSystemModel:GetSelfRankInfo(RankTypeId)
    self.SelfRankInfo = self.SelfRankInfo or {}
    local Count = 0
    local RankType = self:ConvertTypeId2Type(RankTypeId)
    if RankType == RankDefine.Type.Liked then
        local PlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
        local Info = MvcEntry:GetModel(PersonalInfoModel):GetPlayerDetailInfo(PlayerId)
        if Info then
            Count = Info.LikeHeartTotal
        end
        self:SetSelfRankInfo(RankTypeId, nil, Count)
    end
    if RankType == RankDefine.Type.Hero then
        Count = MvcEntry:GetModel(HeroModel):GetHaveHeroCount()
        self:SetSelfRankInfo(RankTypeId, nil, Count)
    end
    return self.SelfRankInfo[RankTypeId]
end

function RankSystemModel:SetRankInfoCacheTime(RankTypeId)
    self.RankInfoCacheTimeOut = self.RankInfoCacheTimeOut or {}
    self.RankInfoCacheTimeOut[RankTypeId] = GetTimestamp()
end

function RankSystemModel:CheckRankInfoCacheTimeOut(RankTypeId)
    self.RankInfoCacheTimeOut = self.RankInfoCacheTimeOut or {}
    local CacheTime = self.RankInfoCacheTimeOut[RankTypeId]
    if not CacheTime then
        self:SetRankInfoCacheTime(RankTypeId)
        return false
    end
    local CacheTimeLimit = CommonUtil.GetParameterConfig(ParameterConfig.RankCacheTimeOut, 30)
    if GetTimestamp() - CacheTime > CacheTimeLimit then
        return true
    end
    return false
end

return RankSystemModel
