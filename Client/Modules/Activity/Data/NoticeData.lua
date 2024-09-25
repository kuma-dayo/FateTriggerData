local ActivityDefine = require("Client.Modules.Activity.ActivityDefine")
local AcBaseData = require("Client.Modules.Activity.Data.AcBaseData")

---@class NoticeData
local NoticeData = BaseClass(AcBaseData, "NoticeData")

function NoticeData:InitFromCfgId(NoticeInfo)
    if not NoticeInfo then
        CError("NoticeData:InitFromCfgId NoticeInfo Is nil")
        return false
    end
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_NoticeConfig, NoticeInfo.NoticeId)
    if Cfg then
        self.Cfg = Cfg
        self.ID = Cfg[Cfg_NoticeConfig_P.NoticeId]
        self.TabId = Cfg[Cfg_NoticeConfig_P.CategoryId]
        self.StartTime = Cfg[Cfg_NoticeConfig_P.BeginTimeTimestamp]
        self.EndTime = Cfg[Cfg_NoticeConfig_P.EndTimeTimestamp]
        self.SortValue = Cfg[Cfg_NoticeConfig_P.Prority]
    else
        self.ID = NoticeInfo.NoticeId
        self.TabId = NoticeInfo.TopTab
        self.TitleTextId = NoticeInfo.NoticeTitleTextId
        self.ContentTextId = NoticeInfo.NoticeContentTextId
        self.SortValue = NoticeInfo.Priority
    end

    self.Type = ActivityDefine.ActicityNoticeType
    self.IsChanged = false

    local TabCfg = G_ConfigHelper:GetSingleItemById(Cfg_ActivityTabConfig, self.TabId)
    if TabCfg then
        local EntryData = MvcEntry:GetModel(ActivityModel):GetEntryData(TabCfg[Cfg_ActivityTabConfig_P.EntryId])
        if EntryData then
            EntryData:AppendActivity(self.ID)
        end
    end
    return true
end

function NoticeData:Recycle()
    CWaring("NoticeData:Recycle ID"..self.ID)
    NoticeData.super:Recycle()
    self.TitleTextId = 0
    self.ContentTextId = 0
    self.Cfg = nil
end

function NoticeData:GetTabTitle(LanguageCallBack)
    if self.TitleTextId and self.TitleTextId > 0 then
        MvcEntry:GetCtrl(LocalizationCtrl):GetMultiLanguageContentByTextId(self.TitleTextId, LanguageCallBack)
        return
    end

    if not self.Cfg then
        return
    end

    if LanguageCallBack then
        LanguageCallBack(self.Cfg[Cfg_NoticeConfig_P.Tittle])
    end
end

function NoticeData:GetContent(LanguageCallBack)
    if self.ContentTextId and self.ContentTextId > 0 then
        MvcEntry:GetCtrl(LocalizationCtrl):GetMultiLanguageContentByTextId(self.ContentTextId, LanguageCallBack)
        return
    end

    if not self.Cfg then
        return
    end

    if LanguageCallBack then
        LanguageCallBack(self.Cfg[Cfg_NoticeConfig_P.Content])
    end
end

function NoticeData:GetLeftTime()
    return self.EndTime - GetTimestamp()
end

function NoticeData:GetLeftTimeStr()
    local Timestamp = self:GetLeftTime()
    return StringUtil.FormatLeftTimeShowStrRuleOne(Timestamp)
end

function NoticeData:GetStartTime()
    return self.StartTime
end

function NoticeData:IsAvailble()
    local Timestamp = GetTimestamp()
    if (self.StartTime > 0 and Timestamp < self.StartTime) or (self.EndTime > 0 and Timestamp > self.EndTime) then
        return false
    end
    return true
end
return NoticeData
