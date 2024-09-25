---@class QuestionnaireInfoData
local QuestionnaireInfoData = BaseClass(nil, "QuestionnaireInfoData")

--问卷ID
QuestionnaireInfoData.ID = 0
--IDIP问卷名称ID
QuestionnaireInfoData.QuestionnaireNameID = 0
---问卷名称
QuestionnaireInfoData.QuestionnaireName = ""
---问卷网址
QuestionnaireInfoData.WebUrl = ""
---外显奖励物品ID Array<number>
QuestionnaireInfoData.ItemId = nil
--奖励物品数量 Array<number>
QuestionnaireInfoData.ItemNum = nil
---问卷描述1
QuestionnaireInfoData.Decs1 = ""
---IDIP问卷描述ID1
QuestionnaireInfoData.DecsID1 = 0
---问卷描述2
QuestionnaireInfoData.Decs2 = ""
---IDIP问卷描述ID2
QuestionnaireInfoData.DecsID2 = 0
--问卷开始时间
QuestionnaireInfoData.StartTimeTimestamp = 0
--问卷结束时间
QuestionnaireInfoData.EndTimeTimestamp = 0
--问卷排序
QuestionnaireInfoData.Sort = 0
--关联邮件模版ID
QuestionnaireInfoData.MainlId = 0
--ZoneIDs Array<number>
QuestionnaireInfoData.ZoneIDs = nil
--问卷密钥
QuestionnaireInfoData.SecretKey = ""

function QuestionnaireInfoData:Init()
    self.ID = 0
    self.QuestionnaireName = ""
    self.QuestionnaireNameID = 0
    self.WebUrl = ""
    self.ItemId = nil
    self.ItemNum = nil
    self.Decs1 = ""
    self.DecsID1 = 0
    self.Decs2 = ""
    self.DecsID2 = 0
    self.StartTimeTimestamp = 0
    self.EndTimeTimestamp = 0
    self.Sort = 0
    self.MainlId = 0
    self.ZoneIDs = nil
    self.SecretKey = ""
end

function QuestionnaireInfoData:InitFromCfgId(QuestionnaireInfo)
    self:Init()
    if not QuestionnaireInfo then
        CError("QuestionnaireInfoData:InitFromCfgId QuestionnaireInfo Is nil")
        return false
    end
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_QuestionnaireCfg, QuestionnaireInfo.QuestId)
    if Cfg then
        self.ID = Cfg[Cfg_QuestionnaireCfg_P.ID]
        self.QuestionnaireName = Cfg[Cfg_QuestionnaireCfg_P.QuestionnaireName]
        self.WebUrl = Cfg[Cfg_QuestionnaireCfg_P.WebUrl]
        self.ItemId = {}
        for k,v in pairs(Cfg[Cfg_QuestionnaireCfg_P.ItemId]) do
            table.insert(self.ItemId, v)
        end
        self.ItemNum = {}
        for k,v in pairs(Cfg[Cfg_QuestionnaireCfg_P.ItemNum]) do
            table.insert(self.ItemNum, v)
        end
        self.Decs1 = Cfg[Cfg_QuestionnaireCfg_P.Decs1]
        self.Decs2 = Cfg[Cfg_QuestionnaireCfg_P.Decs2]
        self.StartTimeTimestamp = Cfg[Cfg_QuestionnaireCfg_P.StartTimeTimestamp]
        self.EndTimeTimestamp = Cfg[Cfg_QuestionnaireCfg_P.EndTimeTimestamp]
        self.Sort = Cfg[Cfg_QuestionnaireCfg_P.Sort]
        self.MainlId = Cfg[Cfg_QuestionnaireCfg_P.MainlId]
        self.ZoneIDs = {}
        for k,v in pairs(Cfg[Cfg_QuestionnaireCfg_P.ZoneIDs]) do
            table.insert(self.ZoneIDs, v)
        end
        self.SecretKey = Cfg[Cfg_QuestionnaireCfg_P.SecretKey]
    else
        self.ID = QuestionnaireInfo.QuestId
        self.QuestionnaireNameID = QuestionnaireInfo.QuesTitleTextId
        self.WebUrl = QuestionnaireInfo.QuestLink
        self.ItemId = {}
        for k,v in pairs(QuestionnaireInfo.OuterRewardItemIdList) do
            table.insert(self.ItemId, v)
        end
        self.ItemNum = {}
        for k,v in pairs(QuestionnaireInfo.RewardItemCountList) do
            table.insert(self.ItemNum, v)
        end
        self.DecsID1 = QuestionnaireInfo.QuestDescriptionTextId
        self.DecsID2 = QuestionnaireInfo.QuestDescriptionsTextId
        self.StartTimeTimestamp = QuestionnaireInfo.StartTS
        self.EndTimeTimestamp = QuestionnaireInfo.EndTS
        self.Sort = QuestionnaireInfo.Priority
        self.MainlId = QuestionnaireInfo.MailId
        self.ZoneIDs = {}
        for k,v in pairs(QuestionnaireInfo.ZoneIds) do
            table.insert(self.ZoneIDs, v)
        end
        self.SecretKey = QuestionnaireInfo.CliQuestKey
    end

    return true
end

--- 回收
function QuestionnaireInfoData:Recycle()
    self:Init()
end

return QuestionnaireInfoData
