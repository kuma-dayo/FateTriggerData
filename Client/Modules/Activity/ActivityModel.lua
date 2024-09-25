local ActivityData = require("Client.Modules.Activity.Data.ActivityData")
local NoticeData = require("Client.Modules.Activity.Data.NoticeData")
local QuestionnaireData = require("Client.Modules.Activity.Data.QuestionnaireData")
local ActivityDefine = require("Client.Modules.Activity.ActivityDefine")
local BannerData = require("Client.Modules.Activity.Data.BannerData")
local EntryData = require("Client.Modules.Activity.Data.EntryData")
local DitryFlag = require("Common.Utils.DitryFlag")

local super = ListModel;
local class_name = "ActivityModel";

---@class ActivityModel : ListModel
---@field private super ListModel
ActivityModel = BaseClass(super, class_name);

ActivityModel.ACTIVITY_TABLISTITEM_SELECT = "ACTIVITY_TABLISTITEM_SELECT"
ActivityModel.ACTIVITY_BANNERLIST_CHANGE = "ACTIVITY_BANNERLIST_CHANGE"
ActivityModel.ACTIVITY_BANNER_STATE_CHANGE = "ACTIVITY_BANNER_STATE_CHANGE"
ActivityModel.ACTIVITY_ACTIVITYLIST_CHANGE = "ACTIVITY_ACTIVITYLIST_CHANGE"
ActivityModel.ACTIVITY_STATE_CHANGE = "ACTIVITY_STATE_CHANGE"
ActivityModel.ACTIVITY_SUBITEM_STATE_LIST_NOTIFY = "ACTIVITY_SUBITEM_STATE_LIST_NOTIFY"

---脏数据定义
ActivityModel.DirtyFlagDefine = {
    DirtyFlagDefineBannerChanged = 1,
    DirtyFlagDefineActivityChanged = 2,
    DirtyFlagDefineEntryChanged = 3,
    DirtyFlagDefineTabListChanged = 4,
    DirtyFlagDefineEntryTabListChanged = 5,
}

function ActivityModel:__init()
    ---@type DitryFlag
    self.DitryFlag = DitryFlag.New(ActivityModel.DirtyFlagDefine)
    self:_dataInit()
end

function ActivityModel:_dataInit()
    self:Clean()
    self.BannerEnableDataList = nil
    self.EntryDataMap = nil
    self.EntryEnableDataList = nil
    self.AvailbleActivityList = nil
    self.TabEnableDataList = nil
    self.EntryTabList = nil
    self.AcTabList = nil
    self.TaskId2AcId = nil
    self.QuestionnaireDataIDMap = nil
    self.DitryFlag:Reset()
end

---@param data any
function ActivityModel:OnLogin(data)
    CWaring("ActivityModel OnLogin")
    -- self:_dataInit()
    self:InitData()
end

--- 玩家登出时调用
---@param data any
function ActivityModel:OnLogout(data)
    local List = self:GetDataList()
    for _, v1 in pairs(List) do
        PoolManager.Reclaim(v1)
    end
    if self.EntryDataMap then
        for _, v1 in pairs(self.EntryDataMap) do
            PoolManager.Reclaim(v1)
        end
    end
    ActivityModel.super.OnLogout(self)
    self:_dataInit()
end

--- 重写父方法,返回唯一Key
---@param vo any
function ActivityModel:KeyOf(vo)
    return vo["ID"]
end

--- 重写父类方法,如果数据发生改变
--- 进行通知到这边的逻辑
---@param vo any
function ActivityModel:SetIsChange(value)
    ActivityModel.super.SetIsChange(self, value)
end

function ActivityModel:InitData()
    CLog("ActivityModel:InitData")
    if not self.EntryDataMap then
        self.EntryDataMap = {}
        local EntryDict = G_ConfigHelper:GetDict(Cfg_EntryConfig)
        for _, v in pairs(EntryDict) do
            ---@type EntryData
            local EnData = PoolManager.GetInstance(EntryData)
            EnData:InitFromCfg(v)
            self.EntryDataMap[v[Cfg_EntryConfig_P.EntryId]] = EnData
        end
    end
end

function ActivityModel:AppendAcData(AcId)
    ---@type ActivityData
    local AcData = self:GetData(AcId)
    if not AcData then
        AcData = PoolManager.GetInstance(ActivityData)
        AcData:InitFromCfgId(AcId)
        self:AppendData(AcData)
    end
    AcData:Reset()
    AcData:UpdateAcState(ActivityDefine.ActivityState.Open)
end

function ActivityModel:AppendNoticeData(NoticeInfo)
    if not NoticeInfo then
        return
    end
    ---@type NoticeData
    local TNoticeData = self:GetData(NoticeInfo.NoticeId)
    if not TNoticeData then
        TNoticeData = PoolManager.GetInstance(NoticeData)
        TNoticeData:InitFromCfgId(NoticeInfo)
        self:AppendData(TNoticeData)
    end
    TNoticeData:Reset()
    TNoticeData:SetState(ActivityDefine.ActivityState.Open)
end

function ActivityModel:AppendQuestionnaireData(InQuestionnaireInfo)
    if not InQuestionnaireInfo then
        return
    end
    ---@type QuestionnaireData
    local TQuestionnaireData = self:GetData(InQuestionnaireInfo.QuestId)
    if not TQuestionnaireData then
        TQuestionnaireData = PoolManager.GetInstance(QuestionnaireData)
        TQuestionnaireData:InitFromCfgId(InQuestionnaireInfo)
        self:AppendData(TQuestionnaireData)
    end
    TQuestionnaireData:Reset()
    TQuestionnaireData:SetState(ActivityDefine.ActivityState.Open)
end
-------- 对外接口 -----------

-------- 协议数据处理接口 -----------

function ActivityModel:On_QuestionnairesSync(Msg)
    self.QuestionnaireDataIDMap = self.QuestionnaireDataIDMap or {}
    local TempMap = {}
    for _,v in pairs(Msg.QuestionnaireInfos) do
        self:AppendQuestionnaireData(v)
        TempMap[v.QuestId] = true
    end
    for k, _ in pairs(self.QuestionnaireDataIDMap) do
        if not TempMap[k] then
            self.QuestionnaireDataIDMap[k] = false
            ---@type QuestionnaireData
            local TQuestionnaireData = self:GetData(k)
            if TQuestionnaireData then
                TQuestionnaireData:SetState(ActivityDefine.ActivityState.Close)
            end
        end
    end
    self.QuestionnaireDataIDMap = TempMap
    self.DitryFlag:SetAllFlagDirty()
    self:DispatchType(ActivityModel.ACTIVITY_ACTIVITYLIST_CHANGE)
end

--[[
	Msg = {
	    repeated int64 NoticeList = 1;    // 公告Id列表
	}
]]
function ActivityModel:On_NoticeListSyn(Msg)
    for _, NoticeInfo in pairs(Msg.NoticeList) do
        self:AppendNoticeData(NoticeInfo)
    end
    self.DitryFlag:SetAllFlagDirty()
    self:DispatchType(ActivityModel.ACTIVITY_ACTIVITYLIST_CHANGE, Msg.NoticeList)
end

--[[
	Msg = {
	    repeated int64 ActivityIdList = 1;  // 开启的活动列表Id
	}
]]
function ActivityModel:On_OpenActivityListSyn(Msg)
    for _, AcId in pairs(Msg.ActivityIdList) do
        self:AppendAcData(AcId)
    end
    self.DitryFlag:SetAllFlagDirty()
    self:DispatchType(ActivityModel.ACTIVITY_ACTIVITYLIST_CHANGE, Msg.ActivityIdList)
end

--[[
	Msg = {
	    repeated int64 ActivityIdList = 1;  // 关闭的活动Id列表
	}
]]
function ActivityModel:On_CloseActivityListSyn(Msg)
    for _, AcId in pairs(Msg.ActivityIdList) do
        ---@type ActivityData
        local AcData = self:GetData(AcId)
        if not AcData then
            CError("ActivityModel:On_CloseActivityListSyn AcId:"..AcId)
        else
            AcData:Reset()
            AcData:UpdateAcState(ActivityDefine.ActivityState.Close)
        end
    end
    self.DitryFlag:SetAllFlagDirty()
    self:DispatchType(ActivityModel.ACTIVITY_ACTIVITYLIST_CHANGE, Msg.ActivityIdList)
end


--[[
	Msg = {
	    int64 ActivityId = 1;                   // 活动Id
	    int64 SubItemIdList = 2;            // 子项Id
	}
]]
function ActivityModel:On_ActivityGetPrizeRsp(Msg)
    ---@type ActivityData
    local AcData = self:GetData(Msg.ActivityId)
    if not AcData then
        return
    end
    for _, SubId in pairs(Msg.SubItemIdList) do
        MvcEntry:GetModel(ActivitySubModel):SetSubAcState(SubId, Pb_Enum_ACTIVITY_SUB_ITEM_PRIZE_STATE.ACTIVITY_SUB_ITEM_PRIZE_STATE_PRIZE)
    end
    self:SetDirtyByType(ActivityModel.DirtyFlagDefine.DirtyFlagDefineTabListChanged, true)
    MvcEntry:GetModel(ActivityModel):DispatchType(ActivityModel.ACTIVITY_STATE_CHANGE, Msg.ActivityId)
end

--[[
	Msg = {
	    int64 ActivityId = 1;                   // 活动Id
	    map<int64, int64> SubItemMap = 2;       // 已经领取的奖励子项数据，Key子项Id,Value子项奖励领取时间
	}
]]
function ActivityModel:On_PlayerGetActivityDataRsp(Msg)
    ---@type ActivityData
    local AcData = self:GetData(Msg.ActivityId)
    if not AcData then
        return
    end
    for SubId, State in pairs(Msg.SubItemMap) do
        MvcEntry:GetModel(ActivitySubModel):SetSubAcState(SubId, State.State)
    end
    self:SetDirtyByType(ActivityModel.DirtyFlagDefine.DirtyFlagDefineTabListChanged, true)
    self:DispatchType(ActivityModel.ACTIVITY_SUBITEM_STATE_LIST_NOTIFY)
    MvcEntry:GetModel(ActivityModel):DispatchType(ActivityModel.ACTIVITY_STATE_CHANGE, Msg.ActivityId)
end

function ActivityModel:On_PlayerSetActivitySubItemPrizeStateRsp_Func(Msg)
    MvcEntry:GetModel(ActivitySubModel):SetSubAcState(Msg.SubItemId, Pb_Enum_ACTIVITY_SUB_ITEM_PRIZE_STATE.ACTIVITY_SUB_ITEM_PRIZE_STATE_FINISH)
    self:SetDirtyByType(ActivityModel.DirtyFlagDefine.DirtyFlagDefineTabListChanged, true)
    MvcEntry:GetModel(ActivityModel):DispatchType(ActivityModel.ACTIVITY_STATE_CHANGE, Msg.ActivityId)
end


--- 获取需要展示的Banner
function ActivityModel:GetShowBannerList(EntryId)
    if not self.BannerEnableDataList or self.DitryFlag:IsDirtyByType(ActivityModel.DirtyFlagDefine.DirtyFlagDefineBannerChanged) then
        self.BannerEnableDataList = {}
        local ActivityIdList = self:GetAvailbleActivityList()
        for _, v in ipairs(ActivityIdList) do
            ---@type ActivityData
            local AcData = self:GetData(v)
            if AcData.GetBannerList then
                local BannerList = AcData:GetBannerList()
                ---@param v BannerData
                for _, TBanner in pairs(BannerList) do
                    if TBanner.EntryId == EntryId and  TBanner:IsAvailble() then
                        self.BannerEnableDataList[TBanner.EntryId] = self.BannerEnableDataList[TBanner.EntryId] or {}
                        table.insert(self.BannerEnableDataList[TBanner.EntryId], StringUtil.FormatSimple("{0}_{1}", TBanner.AttachAcId ,TBanner.BannerId))
                    end
                end
            end
        end
    end
    return self.BannerEnableDataList[EntryId]
end

--- 获取需要展示的入口
function ActivityModel:GetShowEntryList()
    if not self.EntryEnableDataList or self.DitryFlag:IsDirtyByType(ActivityModel.DirtyFlagDefine.DirtyFlagDefineEntryChanged) then
        self.EntryEnableDataList = {}
        self.EntryDataMap = self.EntryDataMap or {}
        for _, v in pairs(self.EntryDataMap) do
            if v:IsAvailble() then
                table.insert(self.EntryEnableDataList, v.EntryId)
            end
        end
        table.sort(self.EntryEnableDataList, function(a, b)
            ---@type EntryData
            local AcDataA = self:GetEntryData(a)
            local ASrot =  AcDataA and AcDataA:EntrySort() or 0
            ---@type EntryData
            local AcDataB = self:GetEntryData(b)
            local BSrot =  AcDataB and AcDataB:EntrySort() or 0
            return ASrot > BSrot
        end)
    end
    return self.EntryEnableDataList
end

--- 获取可用的活动列表
function ActivityModel:GetAvailbleActivityList()
    if not self.AvailbleActivityList or self.DitryFlag:IsDirtyByType(ActivityModel.DirtyFlagDefine.DirtyFlagDefineActivityChanged) then
        self.AvailbleActivityList = {}
        for _, v in pairs(self:GetDataList()) do
            if v:IsAvailble() then
                table.insert(self.AvailbleActivityList, v.ID)
            end
        end
    end
    return self.AvailbleActivityList
end

function ActivityModel:CheckAvailbleActivityBannerState()
    local ActivityIdList = self:GetAvailbleActivityList()
    local ChangeFlag = false
    for _, v in ipairs(ActivityIdList) do
        ---@type ActivityData
        local AcData = self:GetData(v)
        if AcData.GetBannerList then
            local BannerList = AcData:GetBannerList()
            ---@param TBanner BannerData
            for _, TBanner in pairs(BannerList) do
                TBanner:CheckFreshState()
                if TBanner.IsChanged then
                    ChangeFlag = true
                    break
                end
            end
        end
        if ChangeFlag then
            break
        end
    end

    if ChangeFlag then
        self:SetDirtyByType(ActivityModel.DirtyFlagDefine.DirtyFlagDefineBannerChanged, true)
	    self:DispatchType(ActivityModel.ACTIVITY_BANNERLIST_CHANGE)
    end
end

--- 获取标签下的活动列表
---@param TabId any
function ActivityModel:GetTabAvailbleAcList(TabId)
    if not self.TabEnableDataList or self.DitryFlag:IsDirtyByType(ActivityModel.DirtyFlagDefine.DirtyFlagDefineTabListChanged) then
        self.TabEnableDataList = {}
        ---@type ActivityData[]
        for _, v in pairs(self:GetDataList()) do
            if v:IsAvailble() then
                self.TabEnableDataList[v.TabId] = self.TabEnableDataList[v.TabId] or {}
                table.insert(self.TabEnableDataList[v.TabId], v.ID)
            end
        end
        for _, v in pairs(self.TabEnableDataList) do
            table.sort(v, function(a, b)
                ---@type ActivityData
                local AcDataA = self:GetData(a)
                local ASrot =  AcDataA and AcDataA:Sort() or 0
                ---@type ActivityData
                local AcDataB = self:GetData(b)
                local BSrot =  AcDataB and AcDataB:Sort() or 0
                if ASrot == BSrot then
                    return a > b
                end
                return ASrot > BSrot
            end)
        end
    end
    return self.TabEnableDataList[TabId]
end

--- 获取入口下的标签列表
---@param TabId any
function ActivityModel:GetEntryAvailbleTabList(EntryId)
    if not self.EntryTabList or self.DitryFlag:IsDirtyByType(ActivityModel.DirtyFlagDefine.DirtyFlagDefineEntryTabListChanged) then
        self.EntryTabList = {}
        ---@type EntryData
        local TEntryData = self:GetEntryData(EntryId)
        for _, TabId in pairs(TEntryData:GetTabList()) do
            local List = self:GetTabAvailbleAcList(TabId)
            if List and #List > 0 then
                self.EntryTabList[EntryId] = self.EntryTabList[EntryId] or {}
                table.insert(self.EntryTabList[EntryId], TabId)
            end
        end
        if not self.EntryTabList[EntryId] then
            return
        end
        table.sort(self.EntryTabList[EntryId], function(a, b)
            local ACfg = G_ConfigHelper:GetSingleItemById(Cfg_ActivityTabConfig, a)
            local ASort = ACfg and ACfg[Cfg_ActivityTabConfig_P.Sort] or 0
            local BCfg = G_ConfigHelper:GetSingleItemById(Cfg_ActivityTabConfig, b)
            local BSort = BCfg and BCfg[Cfg_ActivityTabConfig_P.Sort] or 0
            return ASort > BSort
        end)
    end
    return self.EntryTabList[EntryId]
end

--- 获取入口数据
---@param EntryId any
function ActivityModel:GetEntryData(EntryId)
    self:InitData()
    return self.EntryDataMap[EntryId]
end

--- 获取banner数据 BannerIdStr是字符串拼接而成 ActivityId_bannerid
---@param BannerIdStr string
---@return BannerData
function ActivityModel:GetBannerData(BannerIdStr)
    local ActivityId, BannerId = self:ConvertStr2AcidAndBannerId(BannerIdStr)
    if not ActivityId or not BannerId then
        CError("ActivityModel:GetBannerData BannerIdStr is not avaible")
        return
    end
     ---@type ActivityData
     local AcData = self:GetData(ActivityId)
     if not AcData then
         return
     end
    return AcData:GetBanner(BannerId)
end

--- 获取banner数据 BannerIdStr是字符串拼接而成 ActivityId_bannerid
---@param BannerIdStr string
---@return BannerData
function ActivityModel:ConvertStr2AcidAndBannerId(BannerIdStr)
    local StrArr = string.split(BannerIdStr, "_")
    local ActivityId, BannerId
    if StrArr and #StrArr > 1 then
        ActivityId = tonumber(StrArr[1])
        BannerId = tonumber(StrArr[2])
    else
        CError("ActivityModel:ConvertStr2AcidAndBannerId BannerIdStr is not avaible")
    end
    return ActivityId, BannerId
end

function ActivityModel:SetDirtyByType(DirtyFlag, IsDirty)
    self.DitryFlag:SetDirtyByType(DirtyFlag, IsDirty)
end

function ActivityModel:RecordTask2AcIdList(TaskId, AcId)
    if TaskId == 0 or AcId == 0 then
        return
    end
    self.TaskId2AcId = self.TaskId2AcId or {}
    self.TaskId2AcId[TaskId] = self.TaskId2AcId[TaskId] or {}
    self.TaskId2AcId[TaskId][AcId] = true
end

--- 活动是否可用
---@param ActivityId any
function ActivityModel:IsActiivtyAvailable(ActivityId)
    ---@type ActivityData
    local AcData = self:GetData(ActivityId)
    if not AcData then
        return false
    end
    return AcData:IsAvailble()
end

--- 获取活动名称
---@param ActivityId any
function ActivityModel:GetActivityName(ActivityId)
    ---@type ActivityData
    local AcData = self:GetData(ActivityId)
    if not AcData then
        return ""
    end
    return AcData:GetTabTitle()
end

--- 处理Banner的状态
---@param ActivityId any
function ActivityModel:RefreshBannerState(ActivityId)
	---@type ActivityData
	local Data = self:GetData(ActivityId)
    if not Data then
        CError("ActivityModel:RefreshBannerState ActivityId:"..ActivityId)
        return
    end
    if not Data.HandleFreshState then
        return
    end
    Data:HandleFreshState()
	self:SetDirtyByType(ActivityModel.DirtyFlagDefine.DirtyFlagDefineBannerChanged, true)
	self:DispatchType(ActivityModel.ACTIVITY_BANNERLIST_CHANGE)
end

return ActivityModel;