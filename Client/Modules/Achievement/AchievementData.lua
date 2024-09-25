local  AchievementConst = require("Client.Modules.Achievement.AchievementConst")
--- AchievementData
local class_name = "AchievementData";
---@class AchievementData
---@field UniID number Id --Id
---@field ID number 成就组Id
---@field Quality number 成就品质
---@field CanLevelUp number 是否可升级
local AchievementData = BaseClass(nil, class_name);

AchievementData.UniID = 0 --Id
AchievementData.ID = 0 --组Id
AchievementData.Cfg = nil
AchievementData.NextCfg = nil
AchievementData.CurProgress = 0
AchievementData.MaxProgress = 0
AchievementData.LV = 0
AchievementData.MaxLV = 0
AchievementData.GetTimeStamp = 0
AchievementData.State = AchievementConst.OWN_STATE.Not
AchievementData.Quality = 0 -- 成就品质
AchievementData.Type = 0 --一级成就类型
AchievementData.Count = 0
AchievementData.SlotId = 0
AchievementData.Dragging = false
AchievementData.Deleted = false
AchievementData.NoOperation = false
AchievementData.TaskId = 0 --关联任务Id
AchievementData.CanLevelUp = false --是否可升级
AchievementData.IsLoop = false --是否循环
AchievementData.SecTypeID = 0 --二级成就类型

AchievementData.IsUpLV = false
AchievementData.IsUpProgress = false

function AchievementData:UpdateLV(LV)
    if self.LV == LV then
        return false
    end
    self.LV = LV
    --self.State = LV > 0 and AchievementConst.OWN_STATE.Have or AchievementConst.OWN_STATE.Not --没有升级判断解锁这块了
    self.IsUpLV = true
    return true
end

function AchievementData:UpdateProgress(Progress)
    if self.CurProgress == Progress then
        return
    end
    self.IsUpProgress = false
    self.CurProgress = Progress
end

function AchievementData:Init()
    self:Recycle()
end

function AchievementData:Recycle()
    self.ID = 0 --组Id
    self.UniID = 0 --Id
    self.Cfg = nil
    self.NextCfg = nil
    self.CurProgress = 0
    self.MaxProgress = 0
    self.LV = 0 --子Id
    self.MaxLV = 0
    self.GetTimeStamp = 0
    self.State = AchievementConst.OWN_STATE.Not
    self.Quality = 0
    self.Type = 0
    self.Count = 0
    self.SlotId = 0
    self.Dragging = false
    self.Deleted = false
    self.NoOperation = false
    self.TaskId = 0
    self.CanLevelUp = false
    self.IsLoop = false 
    self.SecTypeID = 0
end

function AchievementData:InitDataFromCfgId(InCfgId)
    if not InCfgId then
        CError("AchievementData:InitDataFromCfg InCfgId Is Nil")
        return
    end
    self.UniID = InCfgId
    local TempCfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCfg, InCfgId)
    if not TempCfg then
        CError("AchievementData:InitDataFromCfg TempCfg Is Nil")
        return
    end
    self.Cfg = TempCfg
    self.ID = TempCfg[Cfg_AchievementCfg_P.MissionID]
    self.Type = TempCfg[Cfg_AchievementCfg_P.TypeID]
    self.Quality = TempCfg[Cfg_AchievementCfg_P.Quality]
    self.CanLevelUp = TempCfg[Cfg_AchievementCfg_P.CanLevelUp]
    self.MaxProgress = TempCfg[Cfg_AchievementCfg_P.TargetCount]
    self.TaskId = TempCfg[Cfg_AchievementCfg_P.TaskId]
    self.IsLoop = TempCfg[Cfg_AchievementCfg_P.IsLoop]
    self.State = AchievementConst.OWN_STATE.Not
    if self.CanLevelUp then
        local TempCfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_AchievementCfg, Cfg_AchievementCfg_P.MissionID, TempCfg[Cfg_AchievementCfg_P.MissionID])
        self.MaxLV = #TempCfgs
    end
end

function AchievementData:UpdateDataFromCfgId(InCfgId, InSubID)
    if not InCfgId then
        CError("AchievementData:UpdateDataFromCfgId InCfgId Is Nil")
        return
    end
    self.UniID = InCfgId
    if InSubID > 0 then
        local TempCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_AchievementCfg, {Cfg_AchievementCfg_P.MissionID,Cfg_AchievementCfg_P.SubID},{self.ID,InSubID})
        if TempCfg then
            self.Cfg = TempCfg
            self.Quality = TempCfg[Cfg_AchievementCfg_P.Quality]
            self.TaskId = TempCfg[Cfg_AchievementCfg_P.TaskId]
            self.IsLoop = TempCfg[Cfg_AchievementCfg_P.IsLoop]
        end
    end
    
    local NextCfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCfg, InCfgId)
    self.NextCfg = NextCfg
    self.MaxProgress = NextCfg[Cfg_AchievementCfg_P.TargetCount]
end

function AchievementData:GetCurrentUnlockUniID()
    if not self.Cfg then
        CError("AchievementData:GetCurrentUnlockUniID self.Cfg Is Nil")
        return 
    end
    return self.Cfg[Cfg_AchievementCfg_P.ID]
end


function AchievementData:GetName()
    if not self.Cfg then
        CError("AchievementData:GetName self.Cfg Is Nil")
        return
    end
    return self.Cfg[Cfg_AchievementCfg_P.Name]
end

function AchievementData:GetIcon()
    if not self.Cfg then
        CError("AchievementData:GetName self.Cfg Is Nil")
        return
    end
    return self.Cfg[Cfg_AchievementCfg_P.Image]
end

function AchievementData:GetSmallIcon()
    if not self.Cfg then
        CError("AchievementData:GetName self.Cfg Is Nil")
        return
    end
    return self.Cfg[Cfg_AchievementCfg_P.SmallIcon]
end

function AchievementData:GetDesc()
    if not self.Cfg then
        CError("AchievementData:GetName self.Cfg Is Nil")
        return
    end
    return self.Cfg[Cfg_AchievementCfg_P.Desc]
end

function AchievementData:GetTaskTargetNum()
    if not self.Cfg then
        CError("AchievementData:GetName self.Cfg Is Nil")
        return
    end
    return self.Cfg[Cfg_AchievementCfg_P.TaskTargetNum]
end

--[[
    获取成就获得途径是否属于结算(界面界面有特殊需求不展示大弹窗)
]]
function AchievementData:IsShowBigPop()
    if not self.Cfg then
        CError("AchievementData:IsShowBigPop self.Cfg Is Nil")
        return
    end
    return self.Cfg[Cfg_AchievementCfg_P.IsShowBigPop]
end

function AchievementData:GetSecTypeID()
    if not self.Cfg then
        CError("AchievementData:GetName self.Cfg Is Nil")
        return
    end
    return self.Cfg[Cfg_AchievementCfg_P.SecTypeID]
end


function AchievementData:GetCondiNum()
    if not self.Cfg then
        CError("AchievementData:GetName self.Cfg Is Nil")
        return
    end
    return self.Cfg[Cfg_AchievementCfg_P.DisplayConditionNum]
end

function AchievementData:GetCondition()
    if not self.Cfg then
        CError("AchievementData:GetName self.Cfg Is Nil")
        return
    end
    return self.Cfg[Cfg_AchievementCfg_P.DisplayCondition]
end

function AchievementData:GetCanAvailable()
    if not self.Cfg then
        return false
    end
    return self.Cfg[Cfg_AchievementCfg_P.AvailableFlag]
end

function AchievementData:GetCurQualityCap()
    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,self.Quality)
    if not QualityCfg then
       return ""
    end
    return QualityCfg[Cfg_ItemQualityColorCfg_P.Level]
end

function AchievementData:GetQuality()
    return self.Quality
end

function AchievementData:GetCurQualityColor()
    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,self.Quality)
    if not QualityCfg then
       return ""
    end
    return QualityCfg[Cfg_ItemQualityColorCfg_P.HexColor]
end

function AchievementData:GetLevel()
    return self.LV, self.MaxLV
end

function AchievementData:GetProgress()
    return self.CurProgress,self.MaxProgress
end

function AchievementData:GetProgressPercent()
    if self.MaxProgress <= 0 then
        return 0
    end
    return self.CurProgress / self.MaxProgress
end

--- 类型组ID
function AchievementData:GetGroupByType()
    if self.Type <= 0 then
        return 0
    end
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementCategoryConfig, self.Type)
    if not Cfg then
        CWaring("AchievementData:GetGroupByType Cfg is nil self.Type=".. self.Type)
        return 0
    end
    return Cfg[Cfg_AchievementCategoryConfig_P.TypeGroup]
end

function AchievementData:IsUnlock()
    return self.State == AchievementConst.OWN_STATE.Have
end

function AchievementData:GetStateStr()
    return self.State == AchievementConst.OWN_STATE.Have and G_ConfigHelper:GetStrFromOutgameStaticST('SD_Achievement', "Lua_AchievementData_Alreadyowned") or G_ConfigHelper:GetStrFromOutgameStaticST('SD_Achievement', "Lua_AchievementData_Notowned")
end

function AchievementData:IsEquiped()
    return self.SlotId > 0
end

function AchievementData:IsDeleted()
    return self.Deleted == true
end

function AchievementData:IsNoOperation()
    return self.NoOperation == true
end


function AchievementData:IsDrag()
    return self.Dragging == true
end

function AchievementData:IsHighQuality()
    return self.Quality > 3
end

function AchievementData:GetTimeStr()
    local TimeStr = StringUtil.Conv_TimeShowStrNew(self.GetTimeStamp, "{0}.{1}.{2}", "")
    TimeStr = string.gsub(TimeStr, ",", "")
    return TimeStr
end

function AchievementData:IsProgressed()
    -- if not self:IsUnlock() then
    --     return
    -- end
    return self.CurProgress > 0 and self.MaxProgress > 1
end

--- 根据品质等级获取右下角品质资源(Tips弹窗)
function AchievementData:GetRightDownImgByQualityLv(InLevel)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementQualityConfig, InLevel)
    if not Cfg then
        CWaring("AchievementData:GetRightDownImgByQualityLv Cfg is nil self.Type=".. InLevel)
        return 0
    end
    return Cfg[Cfg_AchievementQualityConfig_P.RightDownImg]
end

--- 根据品质等级获取成就获取Item品质资源(GetPop弹窗)
function AchievementData:GetShowGetPopItemImgByQualityLv(InLevel)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementQualityConfig, InLevel)
    if not Cfg then
        CWaring("AchievementData:GetRightDownImgByQualityLv Cfg is nil self.Type=".. InLevel)
        return 0
    end
    return Cfg[Cfg_AchievementQualityConfig_P.PopGetItemQualityImg]
end

--- 根据品质等级获取Item显示品质资源
function AchievementData:GetItemShowImgByQualityLv(InLevel)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementQualityConfig, InLevel)
    if not Cfg then
        CWaring("AchievementData:GetRightDownImgByQualityLv Cfg is nil self.Type=".. InLevel)
        return 0
    end
    return Cfg[Cfg_AchievementQualityConfig_P.ItemShowImg]
end

--- 根据品质等级获取Item详情页弹窗品质资源
function AchievementData:GetItemTipQualityImgByQualityLv(InLevel)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementQualityConfig, InLevel)
    if not Cfg then
        CWaring("AchievementData:GetRightDownImgByQualityLv Cfg is nil self.Type=".. InLevel)
        return 0
    end
    return Cfg[Cfg_AchievementQualityConfig_P.ItemTipQualityImg]
end

--- 根据品质等级获取Item小图标品质资源
function AchievementData:GetItemSmallQuelityImgByQualityLv(InLevel)
    local CfgList = G_ConfigHelper:GetDict(Cfg_AchievementQualityConfig)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_AchievementQualityConfig, InLevel)
    if not Cfg then
        CWaring("AchievementData:GetRightDownImgByQualityLv Cfg is nil self.Type=".. InLevel)
        return 0
    end
    return Cfg[Cfg_AchievementQualityConfig_P.ItemSmallQuelityImg]
end


return AchievementData
