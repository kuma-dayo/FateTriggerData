--[[
    赛季数据模型
]]
local super = MailModelBase;
local class_name = "SeasonModel";

---@class SeasonModel : MailModelBase
---@field private super MailModelBase
SeasonModel = BaseClass(super, class_name);

--当前赛季更新事件
SeasonModel.ON_UPDATE_CURRENT_SEASON_EVENT = "ON_UPDATE_CURRENT_SEASON_EVENT"
--武器战备数据
SeasonModel.ON_ADD_SEASON_WEAPON_DATA = "ON_ADD_SEASON_WEAPON_DATA"

function SeasonModel:__init()
    self:DataInit()
end

function SeasonModel:DataInit()
    self.SeasonWeaponDataList = {}
    -- 当前赛季id
    self.CurrentSeasonId = 0
end

--[[
    玩家登出时调用
]]
function SeasonModel:OnLogout(data)
    self:DataInit()
end


--[[
    武器战备数据
]]
function SeasonModel:GetSeasonList()
    local NowTimeStamp = GetTimestamp() 
    local SeasonCfgTable = G_ConfigHelper:GetDict(Cfg_SeasonConfig)
	if SeasonCfgTable == nil then
		return {}
    end

    local SeasonList = {}
    for k, v in pairs(SeasonCfgTable) do
        local StartTimeStamp = TimeUtils.getTimestamp(v[Cfg_SeasonConfig_P.StartTime], true)
        local EndTimeStamp = TimeUtils.getTimestamp(v[Cfg_SeasonConfig_P.EndTime], true)
        if NowTimeStamp > StartTimeStamp and NowTimeStamp < EndTimeStamp then
            table.insert(SeasonList,
            {
                SeasonId = v[Cfg_SeasonConfig_P.SeasonId],
                SeasonName = v[Cfg_SeasonConfig_P.SeasonName],
            })
        end
    end
    table.sort(SeasonList, function(A, B)
        return A.SeasonId < B.SeasonId
    end)
    return SeasonList
end

-- 更新当前赛季ID 
function SeasonModel:UpdateCurrentSeasonId(SeasonId)
    if self.CurrentSeasonId ~= SeasonId then
        self.CurrentSeasonId = SeasonId
        self:DispatchType(SeasonModel.ON_UPDATE_CURRENT_SEASON_EVENT) 
    end
end

---获取当前赛季id
---@return number 当前赛季ID
function SeasonModel:GetCurrentSeasonId()
    return self.CurrentSeasonId
end

---获取当前赛季名称
---@return string 当前赛季名称
function SeasonModel:GetCurrentSeasonName()
    local SeasonName = ""
    local CurrentSeasonId = self:GetCurrentSeasonId()
    local SeasonConfig = G_ConfigHelper:GetSingleItemById(Cfg_SeasonConfig,CurrentSeasonId)
    if SeasonConfig then
        SeasonName = SeasonConfig[Cfg_SeasonConfig_P.SeasonName]
    end
    return SeasonName
end

function SeasonModel:ClearSeasonWeaponData()
    self.SeasonWeaponDataList = {}
end

function SeasonModel:AddSeasonWeaponData(SeasonWeaponData)
    if SeasonWeaponData == nil then
        return
    end
    local SeasonId = SeasonWeaponData.SeasonId
    local WeaponId = SeasonWeaponData.WeaponId
    if self.SeasonWeaponDataList[SeasonId] == nil then 
        self.SeasonWeaponDataList[SeasonId] = {}
    end
    self.SeasonWeaponDataList[SeasonId][WeaponId] = SeasonWeaponData
end

function SeasonModel:GetSeasonWeaponData(SeasonId, WeaponId)
    if SeasonId == nil or WeaponId == nil then 
        return 
    end
    if self.SeasonWeaponDataList[SeasonId] == nil then
        return
    end
    return self.SeasonWeaponDataList[SeasonId][WeaponId]
end





return SeasonModel;