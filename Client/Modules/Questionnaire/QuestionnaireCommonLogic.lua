--[[
	调查问卷公用逻辑
]]
local class_name = "QuestionnaireCommonLogic";
---@class QuestionnaireCommonLogic
local QuestionnaireCommonLogic = BaseClass(nil, class_name);

function QuestionnaireCommonLogic:OnInit()
    self.BindNodes = 
    {
        { UDelegate = self.View.WBP_AwardList.OnUpdateItem,			                Func = Bind(self, self.OnUpdateItem) },
		{ UDelegate = self.View.WBP_Notice_Btn.GUIButton_Tips.OnHovered,			Func = Bind(self, self.OnBtnHovered) },
		{ UDelegate = self.View.WBP_Notice_Btn.GUIButton_Tips.OnUnhovered,			Func = Bind(self, self.OnBtnUnhovered) },
	}

    self.BtnInstance = UIHandler.New(self, self.View.WBP_Notice_Btn, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnBtnGoToClicked),
        CommonTipsID = CommonConst.CT_FillIn,
		HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.None,
		SureNoMappingKey = true,
    }).ViewInstance
end

function QuestionnaireCommonLogic:OnShow(Param)
	if not Param then
		return
	end
	if type(Param) == "number" then
		self.QuestionnaireMailID = Param
	else
		if not Param.ID then
			return
		end
		self.QuestionnaireMailID = Param.ID
		self.NeedAdjustScale = Param.NeedAdjustScale
	end
	self.Widget2Handler = {}
	---@type QuestionnaireModel
    self.Model = MvcEntry:GetModel(QuestionnaireModel)
	self:UpdateUI()
    self.View.WBP_Notice_Btn:RemoveAllActiveWidgetStyleFlags()
    self.View.WBP_Notice_Btn:AddActiveWidgetStyleFlags(1)
end

function QuestionnaireCommonLogic:OnHide()
end

function QuestionnaireCommonLogic:UpdateUI()
    self.CfgData = self.Model:GetDataByID(self.QuestionnaireMailID)
    if self.CfgData == nil then
        return
    end
	self.CfgRewardList = {}
    for k,v in ipairs(self.CfgData.ItemId) do
        local iconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
            ItemId = v,
            ItemNum = self.CfgData.ItemNum[k],
            HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
            IsGot = self.Model:ChceckQuestionnaireIsFinish(self.QuestionnaireMailID)
        }
        table.insert(self.CfgRewardList, iconParam)
    end
	
	if self.CfgData.DecsID1 > 0 then
		self.View.BP_RichText_Content:SetText("")
		local LanguageCallBack = function (TextStr) 
			if not CommonUtil.IsValid(self.View) then
				return
			end
			self.View.BP_RichText_Content:SetText(TextStr)
		end
		MvcEntry:GetCtrl(LocalizationCtrl):GetMultiLanguageContentByTextId(self.CfgData.DecsID1, LanguageCallBack)
	else
		self.View.BP_RichText_Content:SetText(self.CfgData.Decs1)
	end

	if self.CfgData.DecsID2 > 0 then
		self.View.BP_RichText_Rules:SetText("")
		local LanguageCallBack = function (TextStr) 
			if not CommonUtil.IsValid(self.View) then
				return
			end
			self.View.BP_RichText_Rules:SetText(TextStr)
		end
		MvcEntry:GetCtrl(LocalizationCtrl):GetMultiLanguageContentByTextId(self.CfgData.DecsID2, LanguageCallBack)
	else
		self.View.BP_RichText_Rules:SetText(self.CfgData.Decs2)
	end

	if CommonUtil.IsValid(self.View.Panel_Rules) then
		self.View.Panel_Rules:SetVisibility(self.CfgData.DecsID2 == 0 and string.len(self.CfgData.Decs2) == 0 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
	end
    
	self:RereshRewardList()
	self:RefreshStatusButton()
end

function QuestionnaireCommonLogic:RereshRewardList()
	self.View.WBP_AwardList:Reload(#self.CfgRewardList)
end

function QuestionnaireCommonLogic:RefreshStatusButton()
	local isFinish = self.Model:ChceckQuestionnaireIsFinish(self.QuestionnaireMailID)
	local isOutOfDate = self.Model:ChceckQuestionnaireIsOutOfDate(self.CfgData.StartTimeTimestamp, self.CfgData.EndTimeTimestamp)
	local btnStr = isFinish and G_ConfigHelper:GetStrFromCommonStaticST("Lua_Questionnaire_Finish_Btn") or G_ConfigHelper:GetStrFromCommonStaticST("Lua_Questionnaire_OutOfDate_Btn")
	if isFinish or isOutOfDate then 
		self.BtnInstance:SetBtnEnabled(false, btnStr)
	else
		self.BtnInstance:SetBtnEnabled(true)
	end
end

function QuestionnaireCommonLogic:OnUpdateItem(Handler, Widget, Index)
	local i = Index + 1
	local IconParam = self.CfgRewardList[i]
	if IconParam == nil then
		return
	end

	local Item = self.Widget2Handler[Widget]	
	local Gap = Widget:GetDesiredSize().Y - self.View.WBP_AwardList.Slot:GetSize().Y
	if self.NeedAdjustScale and Gap > 0 then
		--Widget下的ScaleBox排版是居中所以差值需要除以2
		IconParam.HoverTipFocusOffset = UE.FVector2D(-Gap/2 ,0)
	end
	-- IconParam.ItemParentScale =	self.NeedAdjustScale and 0.88 or nil
	if not Item then
		Item = UIHandler.New(self, Widget, CommonItemIcon, IconParam).ViewInstance
		self.Widget2Handler[Widget] = Item
	else
		Item:UpdateUI(IconParam)
	end
end

-- 跳转按钮点击事件
function QuestionnaireCommonLogic:OnBtnGoToClicked()
    if self.CfgData == nil then
        return
    end
    self.View.WBP_Notice_Btn:RemoveAllActiveWidgetStyleFlags()
    self.View.WBP_Notice_Btn:AddActiveWidgetStyleFlags(4)
	MvcEntry:OpenView(ViewConst.Questionnaire, self.QuestionnaireMailID)
	MvcEntry:CloseView(self.WidgetBase.viewId)
end

function QuestionnaireCommonLogic:OnBtnHovered()
	self.View.WBP_Notice_Btn:RemoveAllActiveWidgetStyleFlags()
	self.View.WBP_Notice_Btn:AddActiveWidgetStyleFlags(2)
end

function QuestionnaireCommonLogic:OnBtnUnhovered()
	self.View.WBP_Notice_Btn:RemoveAllActiveWidgetStyleFlags()
	self.View.WBP_Notice_Btn:AddActiveWidgetStyleFlags(1)
end

return QuestionnaireCommonLogic