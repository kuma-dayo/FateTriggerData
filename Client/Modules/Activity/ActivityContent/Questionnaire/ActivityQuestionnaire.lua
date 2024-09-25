--- 视图控制器
local class_name = "ActivityQuestionnaire"
local ActivityQuestionnaire = BaseClass(ActivityViewBase, class_name)

function ActivityQuestionnaire:OnInit(Param)
    self.MsgList = {}
    self.BindNodes = {}
    ActivityQuestionnaire.super.OnInit(self, Param)
    self.Model = MvcEntry:GetModel(ActivityModel)
    self.Data = nil
end

function ActivityQuestionnaire:OnShow(Param)
    if not Param or not Param.Id then
        CError("ActivityQuestionnaire:OnShow Param is nil")
        return
    end
    ---@type NoticeData
    self.Data = self.Model:GetData(Param.Id)
    if not self.Data then
        CError("ActivityQuestionnaire:OnShow NoticeData is nil NoticeDataId:"..Param.Id)
        return
    end
    UIHandler.New(self, self.View, require("Client.Modules.Questionnaire.QuestionnaireCommonLogic"), Param.Id)
end

function ActivityQuestionnaire:OnHide(Param)
    self.Data = nil
end

return ActivityQuestionnaire
