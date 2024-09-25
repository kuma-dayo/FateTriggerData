local ActivityDefine = require("Client.Modules.Activity.ActivityDefine")
local AcBaseData = require("Client.Modules.Activity.Data.AcBaseData")

---@class QuestionnaireData
local QuestionnaireData = BaseClass(AcBaseData, "QuestionnaireData")

function QuestionnaireData:InitFromCfgId(QuestionnaireInfo)
    if not QuestionnaireInfo then
        CError("QuestionnaireData:InitFromCfgId NoticeInfo Is nil")
        return false
    end
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_QuestionnaireCfg, QuestionnaireInfo.QuestId)
    if Cfg then
        self.Cfg = Cfg
        self.ID = Cfg[Cfg_QuestionnaireCfg_P.ID]
        self.TabId = Cfg[Cfg_QuestionnaireCfg_P.TabId]
        self.StartTime = Cfg[Cfg_QuestionnaireCfg_P.StartTimeTimestamp]
        self.EndTime = Cfg[Cfg_QuestionnaireCfg_P.EndTimeTimestamp]
        self.SortValue = Cfg[Cfg_QuestionnaireCfg_P.Sort]
    else
        self.ID = QuestionnaireInfo.QuestId
        self.TabId = QuestionnaireInfo.ActivityTabId
        self.TitleTextId = QuestionnaireInfo.QuesTitleTextId
        self.SortValue = QuestionnaireInfo.Priority
    end

    self.Type = ActivityDefine.ActicityQuestionnaireType
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

function QuestionnaireData:Recycle()
    CWaring("QuestionnaireData:Recycle ID"..self.ID)
    QuestionnaireData.super:Recycle()
    self.TitleTextId = 0
    self.ContentTextId = 0
    self.Cfg = nil
end

function QuestionnaireData:GetTabTitle(LanguageCallBack)
    if self.TitleTextId and self.TitleTextId > 0 then
        MvcEntry:GetCtrl(LocalizationCtrl):GetMultiLanguageContentByTextId(self.TitleTextId, LanguageCallBack)
        return
    end

    if not self.Cfg then
        return
    end

    if LanguageCallBack then
        LanguageCallBack(self.Cfg[Cfg_QuestionnaireCfg_P.QuestionnaireName])
    end
end

function QuestionnaireData:GetLeftTime()
    return self.EndTime - GetTimestamp()
end

function QuestionnaireData:GetLeftTimeStr()
    local Timestamp = self:GetLeftTime()
    return StringUtil.FormatLeftTimeShowStrRuleOne(Timestamp)
end

function QuestionnaireData:GetStartTime()
    return self.StartTime
end

function QuestionnaireData:IsAvailble()
    local Timestamp = GetTimestamp()
    if (self.StartTime > 0 and Timestamp < self.StartTime) or (self.EndTime > 0 and Timestamp > self.EndTime) then
        return false
    end
    return self.State == ActivityDefine.ActivityState.Open
end

return QuestionnaireData
