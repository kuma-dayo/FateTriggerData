--[[
    世界观 - 数据
]]

local super = GameEventDispatcher;
local class_name = "NarrativeModel";

---@class NarrativeModel : GameEventDispatcher
---@field private super GameEventDispatcher
NarrativeModel = BaseClass(super, class_name)
-- NarrativeModel.ON_SEND_SUCCESS = "ON_SEND_SUCCESS" -- 发送成功


function NarrativeModel:__init()
    self:_dataInit()
end

function NarrativeModel:_dataInit()
    self.TabList = nil
    self.ContentList = nil
end

function NarrativeModel:OnLogin(data)
    -- self:InitNarrativeCfgs()
end

--[[
    玩家登出时调用
]]
function NarrativeModel:OnLogout(data)
    NarrativeModel.super.OnLogout(self)
    self:_dataInit()
end

--[[
    顶部页签配置列表
]]
function NarrativeModel:GetTabDataList()
    if self.TabList == nil then
        self:InitNarrativeTabCfgs()
    end
    return self.TabList
end

--[[
    页签下左侧内容标题列表
]]
function NarrativeModel:GetContentDataList(TabId)
    if self.ContentList == nil then
        self:InitNarrativeContentCfgs()
    end
    return self.ContentList[TabId] or {}
end

-- 初始化世界观顶部页签配置数据
function NarrativeModel:InitNarrativeTabCfgs()
    self.TabList = {}
    local TabCfgs = G_ConfigHelper:GetDict(Cfg_NarrativeTabCfg)
    for _,TabCfg in pairs(TabCfgs) do
        local TabData = {
            TabId = TabCfg[Cfg_NarrativeTabCfg_P.TabId],
            TabName = TabCfg[Cfg_NarrativeTabCfg_P.TabName],
        }
        table.insert(self.TabList,TabData)
    end
    table.sort(self.TabList,function (a,b)
        return a.TabId < b.TabId
    end)
end

-- 初始化世界观配置数据
function NarrativeModel:InitNarrativeContentCfgs()
    self.ContentList = {}
    local NarrativeCfgs =  G_ConfigHelper:GetDict(Cfg_NarrativeCfg) 
    for _,Cfg in pairs(NarrativeCfgs) do
        local TabId = Cfg[Cfg_NarrativeCfg_P.TabId]
        self.ContentList[TabId] =  self.ContentList[TabId] or {}
        local ContentData = {
            Id = Cfg[Cfg_NarrativeCfg_P.Id],
            Name = Cfg[Cfg_NarrativeCfg_P.ContentName]
        }
        table.insert(self.ContentList[TabId],ContentData)
    end
    for TabId,SubContentList in pairs(self.ContentList) do
        table.sort(SubContentList,function (a,b)
            return a.Id < b.Id
        end)
    end
end