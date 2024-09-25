local class_name = "QuestionnaireTabItem"
local QuestionnaireTabItem = BaseClass(nil, class_name)

local oneDaySecond = 60 * 60 * 24
function QuestionnaireTabItem:OnInit()
    self.MsgList = 
    {
		{Model = QuestionnaireModel, MsgName = QuestionnaireModel.QUESTIONNAIRE_MAIN_PANEL_TAB_SELECT, Func = Bind(self, self.OnTabItemSelect)},

	}
    self.BindNodes = 
    {
        { UDelegate = self.View.Btn_Tab.OnClicked,				Func = Bind(self, self.OnBtnClicked) },
        { UDelegate = self.View.Btn_Tab.OnHovered,				Func = Bind(self, self.OnBtnHovered) },
        { UDelegate = self.View.Btn_Tab.OnUnhovered,		    Func = Bind(self, self.OnBtnUnhovered) },
        { UDelegate = self.View.WBP_ReuseList.OnUpdateItem,     Func = Bind(self, self.OnUpdateItem) },
	}
    self.Widget2Handler = {}
    self.CurSelAcId = 0
	---@type QuestionnaireModel
    self.Model = MvcEntry:GetModel(QuestionnaireModel)
end

function QuestionnaireTabItem:OnShow(Param)
    
end

function QuestionnaireTabItem:OnHide()
    self:ClearTimeShowTick()
end

--[[
    {
        ChooseTabId,
        TabId,
        ClickFunc
        Index
    }
]]
function QuestionnaireTabItem:SetData(Param)
    if not Param then
        return
    end
    self.CfgRewardList = {}
    self.Param = Param
    local cfg = self.Model:GetDataByID(Param.TabId)
    for k,v in ipairs(cfg.ItemId) do
        local iconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
            ItemId = v,
            ItemNum = cfg.ItemNum[k],
            HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
            ClickCallBackFunc = Bind(self, self.OnBtnClicked),
        }
        table.insert(self.CfgRewardList, iconParam)
    end
    self.View.Panel_ReuseList:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.Panel_HBox:SetVisibility(UE.ESlateVisibility.Collapsed)
    if #self.CfgRewardList > 3 then
        self.View.Panel_ReuseList:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.WBP_ReuseList:Reload(#self.CfgRewardList);
    else
        self.View.HBox_Reward:ClearChildren()
        self.View.Panel_HBox:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        for k,Param in ipairs(self.CfgRewardList) do
            local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/Components/WBP_CommonItemIcon.WBP_CommonItemIcon")
            local Widget = NewObject(WidgetClass, self.View)
            self.View.HBox_Reward:AddChild(Widget)
            local Offset = k == #self.CfgRewardList and 80 or 10
            Widget.Padding.Right = Offset
            Widget:SetPadding(Widget.Padding)
            UIHandler.New(self, Widget, CommonItemIcon, Param)
        end
    end
    if cfg.QuestionnaireNameID > 0 then
        self.View.GUITextBlock_59:SetText("")
		local LanguageCallBack = function (TextStr) 
            if not CommonUtil.IsValid(self.View) then
                return
            end
			self.View.GUITextBlock_59:SetText(TextStr)
		end
		MvcEntry:GetCtrl(LocalizationCtrl):GetMultiLanguageContentByTextId(cfg.QuestionnaireNameID, LanguageCallBack)
    else
        self.View.GUITextBlock_59:SetText(StringUtil.FormatText(cfg.QuestionnaireName))
    end
    self.DateTimeStamp = cfg.EndTimeTimestamp
    self.LeftTime = cfg.EndTimeTimestamp - GetTimestamp()
    self:ScheduleTimeShowTick()
    self:OnTabItemSelect(nil, Param.ChooseTabId)
end


-- 更新剩余时间显示
function QuestionnaireTabItem:UpdateTimeShow()
    --大于等于24小时显示"年月日"
    if self.LeftTime >= oneDaySecond then
        self.View.Text_Time:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), G_ConfigHelper:GetStrFromCommonStaticST("147"), TimeUtils.GetDateTimeStrFromTimeStamp(self.DateTimeStamp, "%04d-%02d-%02d")))
        return
    end
    --小于等于0显示"已过期"
    if self.LeftTime <= 0 then
        self.View.Text_Time:SetText(G_ConfigHelper:GetStrFromCommonStaticST("Lua_Questionnaire_OutOfDate_Btn"))
        return
    end
    --正常显示倒计时
    self.View.Text_Time:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"), G_ConfigHelper:GetStrFromCommonStaticST("147"), StringUtil.FormatLeftTimeShowStrRuleTwo(self.LeftTime)))
    CommonUtil.SetTextColorFromeHex(self.View.Text_Time, DepotConst.TimeTextColor.Warning)

end

-- 时间刷新显示
function QuestionnaireTabItem:ScheduleTimeShowTick()
    self:ClearTimeShowTick()
    self.CheckTimer = Timer.InsertTimer(1,function()
		self:UpdateTimeShow()
        if self.LeftTime <= 0 then
            self:ClearTimeShowTick()
        end
        self.LeftTime = self.LeftTime - 1
	end, true, "", true)   
end

-- 关闭定时器
function QuestionnaireTabItem:ClearTimeShowTick()
    if self.CheckTimer then
        Timer.RemoveTimer(self.CheckTimer)
    end

    self.CheckTimer = nil
end


function QuestionnaireTabItem:OnUpdateItem(_, Widget, Index)
	local FixIndex = Index + 1

	local TargetItem = self:CreateItem(Widget)
	if TargetItem == nil then
		return
	end
    local param = self.CfgRewardList[FixIndex]
    if param then
        TargetItem:UpdateUI(param)
    end
end

function QuestionnaireTabItem:CreateItem(Widget)
    local Item = self.Widget2Handler[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, CommonItemIcon)
        self.Widget2Handler[Widget] = Item
    end
    return Item.ViewInstance
end

function QuestionnaireTabItem:OnBtnClicked()
    if not self.Param then
        return
    end
    if self.CurSelAcId == self.Param.TabId then
        return
    end
    if self.Param and self.Param.ClickFunc then
        self.Param.ClickFunc(self, self.Param.Index)
    end
end

function QuestionnaireTabItem:OnTabItemSelect(_, AcId)
    if not self.Param then
        return
    end
    if self.CurSelAcId == AcId then
        return
    end
    if self.Param.TabId == AcId then
        self.View:VXE_Btn_Active()
    else
        self.View:VXE_Btn_Normal()
    end
    self.CurSelAcId = AcId
end

function QuestionnaireTabItem:OnBtnHovered()
    if not self.Param then
        return
    end
    if self.CurSelAcId == self.Param.TabId then
        return
    end
    self.View:VXE_Btn_Hover()
end

function QuestionnaireTabItem:OnBtnUnhovered()
    if not self.Param then
        return
    end
    if self.CurSelAcId == self.Param.TabId then
        return
    end
    self.View:VXE_Btn_Normal()
end


return QuestionnaireTabItem
