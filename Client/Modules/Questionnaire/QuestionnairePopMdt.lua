--[[
    问卷调查弹窗界面
]]
local class_name = "QuestionnairePopMdt"
QuestionnairePopMdt = QuestionnairePopMdt or BaseClass(GameMediator, class_name)

function QuestionnairePopMdt:__init()
end

function QuestionnairePopMdt:OnShow(data)
end

function QuestionnairePopMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    local PopParam = {
        TitleStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_QuestionnairePopMdt_Title"),
        ContentType = CommonPopUpPanel.ContentType.Content,
        CloseCb = Bind(self,self.GUIButton_Close_ClickFunc),
    }
    self.CommonPopUpPanel = UIHandler.New(self,self.WBP_CommonPopPanel,CommonPopUpPanel,PopParam).ViewInstance
    ---@type QuestionnaireModel
    self.Model = MvcEntry:GetModel(QuestionnaireModel)
end

function M:OnHide()
end

function M:OnShow(ID)
    if not ID or string.len(ID) <= 0 then
        CWaring("===========QuestionnairePopMdt ID is nil,please check")
        return
    end
    local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/OutsideGame/Notice/Questionnaire/WBP_Notice_Questionnaire.WBP_Notice_Questionnaire")
    local Widget = NewObject(WidgetClass, self)
    UIRoot.AddChildToPanel(Widget,self.CommonPopUpPanel:GetContentPanel())

    MvcEntry:GetCtrl(QuestionnaireCtrl):SendProtoQuestionnaireShowAckReq(ID)
    local Param = {
        ID = ID,
        NeedAdjustScale = true,
    }
    if self.QuestionnaireCommonViewInst == nil then
        self.QuestionnaireCommonViewInst = UIHandler.New(self, Widget, require("Client.Modules.Questionnaire.QuestionnaireCommonLogic"), Param).ViewInstance
    else 
        self.QuestionnaireCommonViewInst:UpdateUI()
    end
end

--点击关闭按钮事件
function M:GUIButton_Close_ClickFunc()
    MvcEntry:CloseView(self.viewId)
end

return M
