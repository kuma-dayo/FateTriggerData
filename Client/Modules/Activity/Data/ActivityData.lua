local AcBaseData = require("Client.Modules.Activity.Data.AcBaseData")
local ActivityDefine = require("Client.Modules.Activity.ActivityDefine")
local BannerData = require("Client.Modules.Activity.Data.BannerData")

local super = AcBaseData;
local class_name = "ActivityData";
---@class ActivityData : AcBaseData
---@field private super AcBaseData
local ActivityData = BaseClass(super, class_name)

---沉底类型
ActivityData.SinkType = ActivityDefine.ActivitySinkType.None

ActivityData.Entries = nil
ActivityData.ShowCurrency = nil

ActivityData.LvUpperLimit = 0
ActivityData.LvLowerLimit = 0
ActivityData.VersionLimit = 0
ActivityData.BannerMap = nil
ActivityData.HelpID = 0

--包含的任务列表,用于刷新状态
-- ActivityData.TaskList = nil

ActivityData.Cfg = nil

--来源类型
ActivityData.SourceType = ActivityDefine.ActivitySourceType.Normal

function ActivityData:InitFromCfgId(ConfigId)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ActivityCfg, ConfigId)
    if not Cfg then
        CError("ActivityData:InitFromCfgId Cfg is nil. ConfigId:"..ConfigId)
        return false
    end
    self.Cfg = Cfg
    self.ID = Cfg[Cfg_ActivityCfg_P.ID]
    self.Type = Cfg[Cfg_ActivityCfg_P.TypeID]
    self.TabId = Cfg[Cfg_ActivityCfg_P.TabID]
    self.SortValue = Cfg[Cfg_ActivityCfg_P.SortID]
    self.HelpID = Cfg[Cfg_ActivityCfg_P.HelpID]
    self.Entries = Cfg[Cfg_ActivityCfg_P.Entries]
    self.SinkType = Cfg[Cfg_ActivityCfg_P.SinkType]
    self.StartTime = Cfg[Cfg_ActivityCfg_P.StartTimeTimestamp]
    self.EndTime = Cfg[Cfg_ActivityCfg_P.EndTimeTimestamp]
    self.LvUpperLimit = Cfg[Cfg_ActivityCfg_P.LvUpperLimit]
    self.LvLowerLimit = Cfg[Cfg_ActivityCfg_P.LvLowerLimit]
    self.VersionLimit = Cfg[Cfg_ActivityCfg_P.VersionLimit]

    self.BannerMap = {}
    for _, BannerId in pairs(Cfg[Cfg_ActivityCfg_P.BannerId]) do
        local BannerCfg = G_ConfigHelper:GetSingleItemById(Cfg_BannerConfig, BannerId)
        ---@type BannerData
        local BnData = PoolManager.GetInstance(BannerData)
        BnData:InitFromCfg(BannerCfg)
        BnData:AttachActivity(self.ID)
        self.BannerMap[BannerId] = BnData
    end

    if Cfg[Cfg_ActivityCfg_P.ShowCurrency] then
        self.ShowCurrency = {}
        for _, v in pairs(Cfg[Cfg_ActivityCfg_P.ShowCurrency]) do
            table.insert(self.ShowCurrency, v)
        end
    end

    if self.Entries then
        for _, v in pairs(self.Entries) do
            local EntryData = MvcEntry:GetModel(ActivityModel):GetEntryData(v)
            if EntryData then
                EntryData:AppendActivity(self.ID)
            end
        end
    end

    MvcEntry:GetModel(ActivitySubModel):AppendAcSubDatas(self.ID)

    self.IsChanged = false
    return true
end

--- 回收
function ActivityData:Recycle()
    CWaring("ActivityData:Recycle ID"..self.ID)

    self:Reset()

    MvcEntry:GetModel(ActivitySubModel):ReclaimItemsByAcId(self.ID)

    if self.BannerMap then
        for _, v in pairs(self.BannerMap) do
            PoolManager.Reclaim(v)
        end
    end
    self.BannerMap = nil

    self.ID = 0
    self.Type = Pb_Enum_ACTIVITY_TYPE.ACTIVITY_TYPE_INVAILD
    self.TabId = 0
    self.SortValue = 0
    self.StartTime = 0
    self.EndTime = 0
    self.SinkType = ActivityDefine.ActivitySinkType.None
    self.Entries = nil
    self.ShowCurrency = nil
    self.LvUpperLimit = 0
    self.LvLowerLimit = 0
    self.VersionLimit = 0
    self.HelpID = 0
    self.Cfg = nil
    self.SourceType = ActivityDefine.ActivitySourceType.Normal
end

function ActivityData:Reset()
    CWaring("ActivityData:Reset ID"..self.ID)
    self.IsChanged = true
    self.State = ActivityDefine.ActivityState.None
    MvcEntry:GetModel(ActivitySubModel):ResetItemsByAcId(self.ID)
    self:ResetBannerState()
end

function ActivityData:GetTabTitle(LanguageCallBack)
    if not self.Cfg then
        return
    end

    if LanguageCallBack then
        LanguageCallBack(self.Cfg[Cfg_ActivityCfg_P.TabTitle])
    end
    return self.Cfg[Cfg_ActivityCfg_P.TabTitle]
end

function ActivityData:GetTabIcon()
    if not self.Cfg then
        return
    end
    return self.Cfg[Cfg_ActivityCfg_P.TabIcon]
end

function ActivityData:GetMainTitle()
    if not self.Cfg then
        return ""
    end
    return self.Cfg[Cfg_ActivityCfg_P.MainTitle]
end

function ActivityData:GetSubTitle()
    if not self.Cfg then
        return ""
    end
    return self.Cfg[Cfg_ActivityCfg_P.SubTitle]
end

function ActivityData:GetBigImg()
    if not self.Cfg then
        return
    end
    return self.Cfg[Cfg_ActivityCfg_P.BigImg]
end

--- 打开帮助系统
function ActivityData:OpenHelpSys()
    if self.HelpID < 1 then
        return
    end
    MvcEntry:OpenView(ViewConst.CommonHelpSys, {Id = self.HelpID})
end

---@param Type number
---@return ActivitySubData
function ActivityData:GetSubItemById(SubItemId)
    return MvcEntry:GetModel(ActivitySubModel):GetData(SubItemId)
end

--- func desc
---@param Type number
---@return number[]
function ActivityData:GetSubItemsByType(Type)
    return MvcEntry:GetModel(ActivitySubModel):GetSubItemsByAcIdAndType(self.ID, Type)
end

--- func desc
---@param State ActivityState
function ActivityData:UpdateAcState(State)
    self:SetState(State)
    self:CheckBannerState()
    self.IsChanged = false
end

function ActivityData:ResetBannerState()
    if not self.BannerMap then
        return
    end
    ---@param v BannerData
    for _, v in pairs(self.BannerMap) do
        v:Reset()
    end
end

function ActivityData:CheckBannerState()
    if not self.BannerMap then
        return
    end
    ---@param v BannerData
    for _, v in pairs(self.BannerMap) do
        v:CheckFreshState()
    end
end

function ActivityData:HandleFreshState()
    if not self.BannerMap then
        return
    end
    ---@param v BannerData
    for _, v in pairs(self.BannerMap) do
        ---@type BannerData
        v:HandleFreshState()
    end
end

function ActivityData:GetBannerList()
    if not self.BannerMap then
        return
    end
    return self.BannerMap
end

--- func desc
---@param BannerId any
---@return BannerData
function ActivityData:GetBanner(BannerId)
    if not self.BannerMap then
        return
    end
    return self.BannerMap[BannerId]
end

function ActivityData:OnRefreshState()
    MvcEntry:GetModel(ActivityModel):DispatchType(ActivityModel.ACTIVITY_STATE_CHANGE, self.ID)
end

--- 是否可用
function ActivityData:IsAvailble()
    local CurLv = MvcEntry:GetModel(UserModel):GetPlayerLvAndExp()
    if (self.LvUpperLimit > 0 and CurLv > self.LvUpperLimit) or (self.LvLowerLimit > 0 and CurLv < self.LvLowerLimit) then
        return false
    end
    if self.VersionLimit and string.len(self.VersionLimit) > 0 then
        local AppVersion = MvcEntry:GetModel(UserModel):GetAppVersion()
        local VerArr = string.split(AppVersion, ".")
        local LimitVerArr = string.split(self.VersionLimit, ".")
        if LimitVerArr and VerArr then
            local Flag = true
            for Index, VerNum in ipairs(VerArr) do
                if LimitVerArr[Index] and VerNum < LimitVerArr[Index] then
                    Flag = false
                    break
                end
            end
            return Flag
        end
    end

    local Timestamp = GetTimestamp()
    if (self.StartTime > 0 and Timestamp < self.StartTime) or (self.EndTime > 0 and Timestamp > self.EndTime) then
        return false
    end

    return self.State == ActivityDefine.ActivityState.Open
end

function ActivityData:Sort()
    local TSort = 0

    if not self:IsAvailble() then
        return TSort
    end

    TSort = self.SortValue

    local AllItemFinished = MvcEntry:GetModel(ActivitySubModel):IsAllSubItemsFinished(self.ID)
    if self.SinkType == ActivityDefine.ActivitySinkType.AllRewardGot and AllItemFinished then
        TSort = -100
    end

    local IsFinalDay = self.EndTime - GetTimestamp() < 24*60*60
    if self.SinkType == ActivityDefine.ActivitySinkType.FinalDay and IsFinalDay then
        TSort = -100
    end

    if self.SinkType == ActivityDefine.ActivitySinkType.AllRewardGotAndFinalDay and AllItemFinished and IsFinalDay then
        TSort = -100
    end

    return TSort
end

---@param SubItemIDs number[]
function ActivityData:AcSubItemSort(SubItemIDs)
    SubItemIDs = SubItemIDs or {}

    local GetSubItemSortValFunc = function(SubItemID)
        ---@type ActivitySubData
        local SubItem = self:GetSubItemById(SubItemID)
        if SubItem.State == ActivityDefine.ActivitySubState.Can then
            return 0
        elseif SubItem.State == ActivityDefine.ActivitySubState.Not then
            local jumpId = SubItem:GetJumpID()
            return jumpId > 0 and 1 or 2
        elseif SubItem.State == ActivityDefine.ActivitySubState.Got then
            return 10
        end
        return 999
    end

    local NewData = {}
    for k, SubID in pairs(SubItemIDs) do
        table.insert(NewData,{SubID = SubID, Sort = GetSubItemSortValFunc(SubID)})
    end
    table.sort(NewData, function(TempA,TempB)
        if TempA.Sort == TempB.Sort then
            return TempA.SubID < TempB.SubID
        end
        return TempA.Sort < TempB.Sort
    end)

    local NewSubItemIDs = {}
    for k, Val in pairs(NewData) do
        table.insert(NewSubItemIDs, Val.SubID)
    end
    return NewSubItemIDs
end

function ActivityData:GetLeftTime()
    return self.EndTime - GetTimestamp()
end

function ActivityData:GetLeftTimeStr()
    local Timestamp = self:GetLeftTime()
    return StringUtil.FormatLeftTimeShowStrRuleOne(Timestamp)
end

function ActivityData:GetStartTime()
    return self.StartTime
end

return ActivityData
