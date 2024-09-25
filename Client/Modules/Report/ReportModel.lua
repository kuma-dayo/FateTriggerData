---
--- Model 模块，用于数据存储与逻辑运算
--- Description: 举报
--- Created At: 2023/08/30 15:35
--- Created By: 朝文
---

local super = ListModel
local class_name = "ReportModel"
---@class ReportModel : ListModel
ReportModel = BaseClass(super, class_name)

ReportModel.ON_PLAYER_REPORTED = "ON_PLAYER_REPORTED"
ReportModel.IsOpen = false

function ReportModel:KeyOf(vo)
    if vo["CfgId"] then
        return vo["CfgId"]
    end
    return ReportModel.super.KeyOf(self, vo)
end

function ReportModel:__init()
    self:DataInit()
end

---初始化数据，用于第一次调用及登出的时候调用
function ReportModel:DataInit()
    self:InitReportData()
end

---玩家登出时调用
function ReportModel:OnLogout(data)
    self:DataInit()
end

---初始化数据，读取 ReportConfig 中的数据，整理成客户端容易读取的数据格式
function ReportModel:InitReportData()
    if self.ReportDataInited then return end

    self.ReportCfgCache = {--[[
        [1] = {
            ReportType = 1
            ReportIds = {
                [1] => 1001
                [2] => 1002
                [3] => 1003
                [4] => 1004
            }
        }
        [2] = {
            ReportType = 2
            ReportIds = {
                [1] = 1005
                [2] = 1006
            }
        }
        [3] = {
            ReportType = 3
            ReportIds = {
                [1] = 1007
                [2] = 1008
            }
        }
    --]]}
    local ReportTable = G_ConfigHelper:GetDict(Cfg_ReportCfg)
    for _, Cfg in pairs(ReportTable) do
        local ReportId = Cfg[Cfg_ReportCfg_P.ReportId]
        local ReportType = Cfg[Cfg_ReportCfg_P.ReportType]
        local ReportScenes = Cfg[Cfg_ReportCfg_P.Scenes]

        --处理ReportCfgCache
        for _, ReportScene in pairs(ReportScenes) do
            if not self.ReportCfgCache[ReportScene] then
                self.ReportCfgCache[ReportScene] = {}
            end
            if not self.ReportCfgCache[ReportScene][ReportType] then
                self.ReportCfgCache[ReportScene][ReportType] = {}
            end
            table.insert(self.ReportCfgCache[ReportScene][ReportType], ReportId)
        end
    end
        
    --排序 ReportCfgCache
    for sceneId, reportTypeInfo in pairs(self.ReportCfgCache) do
        local tmpList = {}        
        for reportType, reportIds in pairs(reportTypeInfo) do
            local tmp1 = {
                ReportType = reportType,
                ReportIds =  reportIds,
            }
            table.sort(tmp1.ReportIds, function(a, b) return a < b end)
            table.insert(tmpList, tmp1)
        end
        table.sort(tmpList, function(a, b) return a.ReportType < b.ReportType end)
        self.ReportCfgCache[sceneId] = tmpList
    end
    
    -- print_r(self.ReportCfgCache, "[cw] ====self.ReportCfgCache")
    self.ReportDataInited = true    
end

--[[
    --只有 SceneId，返回当前场景下可以展示的举报类型，及其举报类型之下可以展示的条目
    return { 
        [1] = { 
            ReportType = 1 
            ReportIds =  { 
                [1] = 1001,
                [2] = 1002,
                [3] = 1003,
                [4] = 1004
             } 
        }, 
        [2] = { 
            ReportType = 2 
            ReportIds = { 
                [1] = 1005,
                [2] = 1006
            } 
        }, 
        [3] = { 
            ReportType = 3 
            ReportIds = { 
                [1] = 1007,
                [2] = 1008
            } 
        } 
    } 
    
    --有 SceneId 及 ReportType，返回当前场景及举报类型下可以展示的条目
    return { [1] = 1001, [2] = 1002 }    
--]]
---获取到举报信息
---如果只有场景Id，则返回了
---@param SceneId number 场景Id
---@param ReportType number 举报类型
---@return table
function ReportModel:GetReportCfg(SceneId, ReportType)
    if not SceneId then
        CError("[cw] SceneId is nil, Please check it.", true)    
        return
    end

    if not ReportType then
        -- print_r(self.ReportCfgCache[SceneId], "[cw] ====self.ReportCfgCache[SceneId]")
        return self.ReportCfgCache[SceneId]    
    end

    for _, reportInfo in ipairs(self.ReportCfgCache[SceneId]) do
        if reportInfo.ReportType == ReportType then
            -- print_r(reportInfo.ReportIds, "[cw] ====reportInfo.ReportIds")
            return reportInfo.ReportIds
        end
    end
    
    return nil 
end

---获取举报类型的本地化文本
---@param ReportType number 举报类型
---@return string
function ReportModel:GetReportTypeName(ReportType)
    local ReportTypeDesc = G_ConfigHelper:GetSingleItemById(Cfg_ReportTypeCfg, ReportType, Cfg_ReportTypeCfg_P.type_context)
    return StringUtil.Format(ReportTypeDesc)
end

---根据举报Id获取本地化之后的描述文本
---@return string 
function ReportModel:GetReportDetailTextByReportID(ReportId)
    local ReportItemDesc = G_ConfigHelper:GetSingleItemById(Cfg_ReportCfg, ReportId, Cfg_ReportCfg_P.ReportLableName)
    return StringUtil.Format(ReportItemDesc)
end

---根据举报Id获取举报lable
---@return number
function ReportModel:GetReportLableByReportID(ReportId)
    return G_ConfigHelper:GetSingleItemById(Cfg_ReportCfg, ReportId, Cfg_ReportCfg_P.ReportLable)
end

function ReportModel:OpenReportModel()
    ReportModel.IsOpen = true
end

function ReportModel:IsOpenReportModel()
    return ReportModel.IsOpen
end

---根据举报ScenesId获取举报ScenesDesc
---@return string
function ReportModel:GetReportSceneDescByScenesId(ScenesId)
    local ReportSceneDesc = G_ConfigHelper:GetSingleItemById(Cfg_ReportSceneCfg, ScenesId)
    return StringUtil.Format(ReportSceneDesc[Cfg_ReportSceneCfg_P.Des] or "Error Get ScenesDes")
end


return ReportModel