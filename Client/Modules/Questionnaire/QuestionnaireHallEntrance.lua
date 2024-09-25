--[[
	大厅调查问卷入口逻辑
]]
local class_name = "QuestionnaireHallEntrance";
---@class QuestionnaireHallEntrance
local QuestionnaireHallEntrance = BaseClass(nil, class_name);
local OneDaySeconds = 60 * 60 * 24

function QuestionnaireHallEntrance:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.View.Btn_Questionnaire.OnClicked,			   Func = self.OnCliked_BtnQuestionnaire },
		{ UDelegate = self.View.WBP_Btn_Entrance.GUIButton_Main.OnClicked, Func = self.OnCliked_BtnQuestionnaire },
	}
    self.MsgList = {
		{Model = QuestionnaireModel,  	MsgName = QuestionnaireModel.QUESTIONNAIRE_LIST_INFO_CHANGED,         				Func = self.UpdateUI},
		{Model = CommonModel, MsgName = CommonModel.ON_HALL_TAB_SWITCH_COMPLETED,	Func = self.UpdateUI },  --大厅场景切换完成
    }
	---@type QuestionnaireModel
	self.Model = MvcEntry:GetModel(QuestionnaireModel)
end

function QuestionnaireHallEntrance:OnShow()
end

function QuestionnaireHallEntrance:OnHide()
    self:ClearTimeShowTick()
end

-- 更新调查问卷入口显示
function QuestionnaireHallEntrance:UpdateUI()
    local CurTime = GetTimestamp()
	local List = self.Model:GetQuestionnaireCanShowCfgList()
	---@type QuestionnaireInfoData
	local cfg = #List > 0 and List[1] or nil
	if cfg == nil then
		self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
		return
	else
		self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	end
	self.QELeftTime = cfg.EndTimeTimestamp - CurTime
    self:UpdateQuestionnaireEntryCountDownShow(UE.ESlateVisibility.Collapsed)
	if self.QELeftTime <= 0 then
		self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
        self:ClearTimeShowTick()
	else
		self:ScheduleTimeShowTick()
	end
	if #cfg.ItemId > 0 then
        self.View.WBP_Award:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		local IconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
			ItemId = cfg.ItemId[1],
			ItemNum = cfg.ItemNum[1],
			HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
			ClickCallBackFunc = Bind(self, self.OnCliked_BtnQuestionnaire),
		}
		if not self.QuestionnaireEntryItem then
			self.QuestionnaireEntryItem = UIHandler.New(self,self.View.WBP_Award,CommonItemIcon, IconParam).ViewInstance
		else
			self.QuestionnaireEntryItem:UpdateUI(IconParam,true)
		end
    else
        self.View.WBP_Award:SetVisibility(UE.ESlateVisibility.Collapsed)
	end 
end

-- 更新剩余时间显示
function QuestionnaireHallEntrance:UpdateTimeShow()
    if self.QELeftTime <= 0 or self.QELeftTime >= OneDaySeconds then
        return
    end
    self:UpdateQuestionnaireEntryCountDownShow(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.Text_Time:SetText(StringUtil.FormatLeftTimeShowStrRuleTwo(self.QELeftTime))
end

-- 时间刷新显示
function QuestionnaireHallEntrance:ScheduleTimeShowTick()
    self:ClearTimeShowTick()
    self.CheckTimer = Timer.InsertTimer(1,function()
		self:UpdateTimeShow()
        if self.QELeftTime <= 0 then
            self:ClearTimeShowTick()
            self:UpdateUI()
        end
		self.QELeftTime = self.QELeftTime - 1
	end,true, "", true)   
end

-- 关闭定时器
function QuestionnaireHallEntrance:ClearTimeShowTick()
    if self.CheckTimer then
        Timer.RemoveTimer(self.CheckTimer)
    end

    self.CheckTimer = nil
end

function QuestionnaireHallEntrance:UpdateQuestionnaireEntryCountDownShow(InVisibility)
	if CommonUtil.IsValid(self.View.Panel_Countdown) then
		self.View.Panel_Countdown:SetVisibility(InVisibility)
	end
end

-- 点击问卷入口
function QuestionnaireHallEntrance:OnCliked_BtnQuestionnaire()
	local ViewParam = {
        ViewId = ViewConst.Questionnaire,
        TabId = 0,
		Name = "问卷"
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
	MvcEntry:OpenView(ViewConst.Questionnaire)
end

return QuestionnaireHallEntrance