local class_name = "EntryData"
---@class EntryData
local EntryData = BaseClass(nil, class_name)

EntryData.EntryId = 0
EntryData.Enable = false
EntryData.Sort = 0
EntryData.Cfg = nil
EntryData.IsChanged = true

EntryData.ActivityList = nil
EntryData.BannerList = nil

EntryData.TabList = nil

function EntryData:InitFromCfg(Cfg)
    if not Cfg then
        return false
    end
    self.Cfg = Cfg
    self.EntryId = Cfg[Cfg_EntryConfig_P.EntryId]
    self.Enable = Cfg[Cfg_EntryConfig_P.Enable]
    self.Sort = Cfg[Cfg_EntryConfig_P.Sort]

    self.TabList = {}

    local TabConfigs = G_ConfigHelper:GetDict(Cfg_ActivityTabConfig)
    for _, TCfg in ipairs(TabConfigs) do
        if TCfg[Cfg_ActivityTabConfig_P.Enable] then
            table.insert(self.TabList, TCfg[Cfg_ActivityTabConfig_P.TabId])
        end
    end

    if self.TabList then
        table.sort(self.TabList, function(a ,b)
            local CfgA = G_ConfigHelper:GetSingleItemById(Cfg_ActivityTabConfig, a)
            local CfgB = G_ConfigHelper:GetSingleItemById(Cfg_ActivityTabConfig, b)
            return CfgA[Cfg_ActivityTabConfig_P.Sort] > CfgB[Cfg_ActivityTabConfig_P.Sort]
        end)
    end

    self.IsChanged = false
    return true
end

function EntryData:Recycle()
    CWaring("EntryData:Recycle ID"..self.EntryId)
    self.EntryId = 0
    self.Enable = false
    self.Sort = 0
    self.Cfg = nil
    self.IsChanged = true
    self.ActivityList = nil
    self.BannerList = nil
    self.TabList = nil
end

function EntryData:GetEntryText()
    if not self.Cfg then
        return
    end
    return self.Cfg[Cfg_EntryConfig_P.EntryText]
end

function EntryData:GetEntryIcon()
    if not self.Cfg then
        return
    end
    return self.Cfg[Cfg_EntryConfig_P.EntryIcon]
end

function EntryData:IsAvailble()
    if self.ActivityList and #self:GetActivityList() > 0 then
        local Flag = false
        for k, v in pairs(self.ActivityList) do
            ---@type ActivityData
            local AcData = MvcEntry:GetModel(ActivityModel):GetData(k)
            if AcData and AcData:IsAvailble() then
                Flag = true
                break
            end
        end
        if Flag then
            return true
        end
    end
    return false
end

function EntryData:EntrySort()
    return self.Sort
end

function EntryData:AppendBanner(BannerId)
    if not self.BannerList then
        self.BannerList = {}
    end
    self.BannerList[BannerId] = true
end

function EntryData:GetBannerList()
    if not self.BannerList then
        return
    end
    return table.keys(self.BannerList)
end

function EntryData:AppendActivity(NewAcId)
    if not self.ActivityList then
        self.ActivityList = {}
    end
    self.ActivityList[NewAcId] = true
end

function EntryData:GetActivityList()
    return self.ActivityList and table.keys(self.ActivityList) or {}
end

--- 获取标签列表
function EntryData:GetTabList()
    return self.TabList
end

return EntryData
