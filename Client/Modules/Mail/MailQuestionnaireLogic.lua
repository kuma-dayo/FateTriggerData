--[[
	调查问卷邮件详情界面
]]
local class_name = "MailQuestionnaireLogic";
local MailQuestionnaireLogic = BaseClass(nil, class_name);

function MailQuestionnaireLogic:OnInit()
    self.BindNodes = 
    {
		-- { UDelegate = self.View.BtnCloseDetail.OnClicked,				                            Func = Bind(self,self.OnCloseDetailClicked) },
	}
end

function MailQuestionnaireLogic:OnShow(Param)
    self.MailData = Param
    self.Model = MvcEntry:GetModel(QuestionnaireModel)
	self:UpdateMailDetail(self.MailData)
end

function MailQuestionnaireLogic:OnHide()
end

function MailQuestionnaireLogic:UpdateMailDetail(MailData)
	if MailData == nil then
		return
	end
	self.MailData = MvcEntry:GetCtrl(MailCtrl):ConvertMailInfo(MailData)
	
    if self.QuestionnaireCommonViewInst == nil then
        self.QuestionnaireCommonViewInst = UIHandler.New(self, self.View.WBP_Mail_Questionnaire, require("Client.Modules.Questionnaire.QuestionnaireCommonLogic"), tonumber(MailData.CustomData)).ViewInstance
    else 
        self.QuestionnaireCommonViewInst:UpdateUI()
    end
	CommonUtil.SetBrushFromSoftObjectPath(self.View.WBP_Mail_Questionnaire.HeadIcon,self.MailData.HeadIcon)
	if self.MailData.TitleTextId > 0 then
		local LanguageCallBack = function (TextStr) 
			if not CommonUtil.IsValid(self.View) or not CommonUtil.IsValid(self.View.WBP_Mail_Questionnaire) then
				return
			end
			self.View.WBP_Mail_Questionnaire.MailTitle:SetText(TextStr)
		end
		MvcEntry:GetCtrl(LocalizationCtrl):GetMultiLanguageContentByTextId(self.MailData.TitleTextId, LanguageCallBack)
	else
		self.View.WBP_Mail_Questionnaire.MailTitle:SetText(self.MailData.Title)
	end
	self.View.WBP_Mail_Questionnaire.FromWho:SetText(self.MailData.SendPlayerName)

	self.View.WBP_Mail_Questionnaire.Time:SetText(TimeUtils.GetDateFromTimeStamp(MailData.RealSendTime))
	self:SetMailRead()
end

function MailQuestionnaireLogic:UpdateMailDetailVisibility(IsVisible)
	if not IsVisible then 
		self.View.LeftUI:SetVisibility(UE.ESlateVisibility.Collapsed)
	else 
		self.View.LeftUI:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	end
end

function MailQuestionnaireLogic:SetMailRead()
	if self.MailData == nil then
		return
	end
	if self.MailData.ReadFlag then
		return
	end
	local MailMainMdt = self.WidgetBase
	if MailMainMdt == nil then
		return
	end
	CLog("SetMailRead MailUniqId = "..self.MailData.MailUniqId)
	
	local PageType = MailMainMdt:GetPageTypeByCurTab()
	MvcEntry:GetCtrl(MailCtrl):SendProto_PlayerReadMailReq(PageType, 
		{self.MailData.MailUniqId})
end

function MailQuestionnaireLogic:OnCloseDetailClicked()
	self:UpdateMailDetailVisibility(false)
end

return MailQuestionnaireLogic