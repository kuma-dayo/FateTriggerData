--[[
    赛季通行证任务界面
]]

local class_name = "SeasonBpTaskPanelMdt";
SeasonBpTaskPanelMdt = SeasonBpTaskPanelMdt or BaseClass(GameMediator, class_name);

function SeasonBpTaskPanelMdt:__init()
end

function SeasonBpTaskPanelMdt:OnShow(data)
end

function SeasonBpTaskPanelMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.TheModel = MvcEntry:GetModel(SeasonBpModel)
    self.TheDepotModel = MvcEntry:GetModel(DepotModel)
    self.BindNodes = 
    {
		{ UDelegate = self.WBP_ReuseList_Daily.OnUpdateItem,	Func = self.WBP_ReuseList_Daily_OnUpdateItem },
		{ UDelegate = self.WBP_ReuseList_Daily.OnScrollItem,	Func = self.WBP_ReuseList_Daily_OnScrollItem },
		{ UDelegate = self.WBP_ReuseList_Week.OnUpdateItem,	Func = self.WBP_ReuseList_Week_OnUpdateItem },
		{ UDelegate = self.WBP_ReuseList_Week.OnScrollItem,	Func = self.WBP_ReuseList_Week_OnScrollItem },
	}
    self.MsgList = 
    {
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_DAILY_TASK_UPDATE, Func = self.UpdateDailyShow },
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_WEEK_TASK_UPDATE, Func = self.UpdateWeekShow },
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_INFO_INIT, Func = self.UpdateUI },
	}

    UIHandler.New(self,self.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Esc_Btn")),
        ActionMappingKey = ActionMappings.Escape
    })
    UIHandler.New(self, self.WBP_CommonCurrency, CommonCurrencyList, {ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND})
    UIHandler.New(self,self.WBP_Season_Lv_Progress_Panel,require("Client.Modules.Season.Pass.SeasonBpLevelPanelLogic"))

    self.MenuTabUpInstance = UIHandler.New(self,self.WBP_Common_Tabup,CommonMenuTabUp).ViewInstance

    self.DailyWidget2Handler = {}
    self.WeekWidget2Handler = {}
end

--[[
    Param = {
    }
]]
function M:OnShow(Param)
    self:UpdateUI()
    self:PlayDynamicEffectOnShow(true)
end

function M:OnRepeatShow(Param)
    
end

function M:OnHide()
   
end

function M:UpdateUI()
    local PassStatus = self.TheModel:GetPassStatus()

    local MenuItemList = {}
    for i=1,PassStatus.TotWeek do
        local MenuItemInfo = {
            --MenuId，可选，值为空则按下标顺序赋值
            Id = i,
            --需要展示的文本 可选，值为空不做动作
            LabelStr = StringUtil.FormatSimple(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Season","WhichWeek_Btn"),i),
        }
        MenuItemList[#MenuItemList + 1] = MenuItemInfo
    end
    self.PageMaxNum = 4
    self.ValidPageNum = math.floor(PassStatus.Week/self.PageMaxNum) + 1
    if PassStatus.Week%self.PageMaxNum == 0 then
        self.ValidPageNum = self.ValidPageNum - 1
    end
    local MenuParamInfo = {
		ItemInfoList = MenuItemList,
        -- CurSelectId = self.CurShowWeek,
        ClickCallBack = Bind(self,self.OnMenuItemClick),
        HideInitTrigger = true,
        ValidCheck = Bind(self,self.OnMenuItemValidCheck),
        ValidPageCheck = Bind(self,self.OnPageValidCheck),
        PageMaxNum = self.PageMaxNum,
        ShowPageArrow = true,
        PageInvalidStillShow = true,
	}
    self.MenuTabUpInstance:UpdateUI(MenuParamInfo)


    local CfgSeason = G_ConfigHelper:GetSingleItemById(Cfg_SeasonBpCfg,PassStatus.SeasonBpId)

    self.LbName:SetText(CfgSeason[Cfg_SeasonBpCfg_P.Name])
    -- self.LbTime:SetText(self.TheModel:GetEndTimeShow())
    if self.CounDownTimer then
        self:RemoveTimer(self.CounDownTimer)
        self.CounDownTimer = nil
    end
    self.CounDownTimer = self:InsertTimerByEndTime(self.TheModel:GetEndTime(),function (TimeStr,ResultParam)
        self.LbTime:SetText(self.TheModel:FormatEndTimeShow(TimeStr))
    end)
    self.LbDailyUpdateTime:SetText("--")



    self:UpdateCanGetRewardListNextLevel();
    self:UpdateDailyShow()
    self:UpdateWeekShow()
end

function M:WBP_ReuseList_Daily_OnUpdateItem(Widget,Index)
	local FixIndex = Index + 1
    if not self.DailyWidget2Handler[Widget] then
        self.DailyWidget2Handler[Widget]  = UIHandler.New(self,Widget,require("Client.Modules.Season.Pass.SeasonBpTaskItemLogic")).ViewInstance
    end

    local TaskBase = self.DailyTaskList[FixIndex]
    local Param = {
        BpTaskBase = TaskBase,
        TaskType = 1,
    }
    self.DailyWidget2Handler[Widget]:UpdateUI(Param)
end

function M:WBP_ReuseList_Daily_OnScrollItem(StartIdx,EndIdx)

end

function M:WBP_ReuseList_Week_OnUpdateItem(Widget,Index)
	local FixIndex = Index + 1
    if not self.WeekWidget2Handler[Widget] then
        self.WeekWidget2Handler[Widget]  = UIHandler.New(self,Widget,require("Client.Modules.Season.Pass.SeasonBpTaskItemLogic")).ViewInstance
    end

    local TaskBase = self.WeekTaskInfo.TaskList[FixIndex]
    local Param = {
        BpTaskBase = TaskBase,
        TaskType = 2,
    }
    self.WeekWidget2Handler[Widget]:UpdateUI(Param)
end

function M:WBP_ReuseList_Week_OnScrollItem(StartIdx,EndIdx)

end

function M:UpdateCanGetRewardListNextLevel()
    local PassStatus = self.TheModel:GetPassStatus()
    self.NornalGetRewardList = {}
    if not (PassStatus.Level > self.TheModel:GetBpLevelMax()) then
        local RewardCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpRewardCfg,{Cfg_SeasonBpRewardCfg_P.SeasonBpId,Cfg_SeasonBpRewardCfg_P.Level},{PassStatus.SeasonBpId,PassStatus.Level + 1})
        if RewardCfg then
            self.NornalGetRewardList = self.TheModel:GetDropItemListByBpReward(RewardCfg)--self.TheDepotModel:GetItemListForDropId(RewardCfg[Cfg_SeasonBpRewardCfg_P.DropId])
            for i=(PassStatus.Level+1),self.TheModel:GetBpLevelMax() do
                local RewardCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpRewardCfg,{Cfg_SeasonBpRewardCfg_P.SeasonBpId,Cfg_SeasonBpRewardCfg_P.Level},{PassStatus.SeasonBpId,i})
                if PassStatus.PassType ~= Pb_Enum_PASS_TYPE.BASIC or RewardCfg[Cfg_SeasonBpRewardCfg_P.TypeId] <= 0 then
                    self.NornalGetRewardList = self.TheModel:GetDropItemListByBpReward(RewardCfg)

                    if #self.NornalGetRewardList > 0 then
                        break
                    end
                end
            end
        end
    end
    self.NextLvRewardShow:SetVisibility(#self.NornalGetRewardList > 0 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if #self.NornalGetRewardList > 0 then
        self.NextLevelRewards:ClearChildren()
        for k,ItemInfo in ipairs(self.NornalGetRewardList) do
            local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/Components/WBP_CommonItemIcon.WBP_CommonItemIcon")
            local Widget = NewObject(WidgetClass, self)
            self.NextLevelRewards:AddChild(Widget)
    
            local IconParam = {
                IconType = CommonItemIcon.ICON_TYPE.PROP,
                ItemId = ItemInfo.ItemId,
                ItemNum = ItemInfo.ItemNum,
                -- ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.TIP,
                HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
                ShowCount = true,
            }
            UIHandler.New(self,Widget,CommonItemIcon,IconParam)
        end
    end
end

function M:UpdateDailyShow()
    self.DailyTaskList = self.TheModel:GetDailyTaskList()
    if not self.DailyTaskList then
        MvcEntry:GetCtrl(SeasonBpCtrl):SendProto_PassDailyTaskReq()
    else
        local TheTaskModel = MvcEntry:GetModel(TaskModel)
        table.sort(self.DailyTaskList, function(a, b)
            local FinishStateA = TheTaskModel:HasTaskFinished(a.TaskId) and 1 or 0
            local FinishStateB = TheTaskModel:HasTaskFinished(b.TaskId) and 1 or 0
            if FinishStateA ~= FinishStateB then
                return (FinishStateA < FinishStateB)
            end
            return (a.BpTaskId < b.BpTaskId)
        end)
        --TODO 更新日常任务列表
        self.WBP_ReuseList_Daily:Reload(#self.DailyTaskList)

        if self.DailyCounDownTimer then
            self:RemoveTimer(self.DailyCounDownTimer)
            self.DailyCounDownTimer = nil
        end
        self.DailyCounDownTimer = self:InsertTimerByEndTime(self.TheModel.DailyEndTime,function (TimeStr,ResultParam)
            self.LbDailyUpdateTime:SetText(TimeStr)
        end)
    end
end

function M:UpdateWeekShow()
    if not self.TheModel:IsWeekTaskInfoInit() then
        MvcEntry:GetCtrl(SeasonBpCtrl):SendProto_PassUnlockWeekTaskReq()
    else
        self:CalculateCurSelectWeek()
        self:UpdateCurSelectWeekShow()
    end
end

function M:CalculateCurSelectWeek()
    --TODO 需要计算当前显示周
    --[[
        当前已开放的周，哪个周任务存在未完成的则显示该周
    ]]
    local TheTaskModel = MvcEntry:GetModel(TaskModel)
    local PassStatus = self.TheModel:GetPassStatus()
    self.CurShowWeek = nil
    for Week = 1,PassStatus.Week do
        local TaskInfo = self.TheModel:GetWeekTaskInfo(Week)
        local ExistNotFinishState = false
        table.sort(TaskInfo.TaskList, function(a, b)
            local FinishStateA = TheTaskModel:HasTaskFinished(a.TaskId) and 1 or 0
            local FinishStateB = TheTaskModel:HasTaskFinished(b.TaskId) and 1 or 0
            if FinishStateA == 0 or FinishStateB == 0 then
                ExistNotFinishState = true
            end
            if FinishStateA ~= FinishStateB then
                return (FinishStateA < FinishStateB)
            end
            return (a.BpTaskId < b.BpTaskId)
        end)
        if ExistNotFinishState and not self.CurShowWeek then
            self.CurShowWeek = Week
            CWaring("ExistNotFinishState:" .. self.CurShowWeek)
        end
    end
    if not self.CurShowWeek then
        CWaring("self.CurShowWeek nil try to fix")
        self.CurShowWeek = PassStatus.Week
    end
    self.MenuTabUpInstance:UpdateCurSelect(self.CurShowWeek)
end

function M:UpdateCurSelectWeekShow()
    self.WeekTaskInfo = self.TheModel:GetWeekTaskInfo(self.CurShowWeek)
    --TODO 更新周任务列表
    self.WBP_ReuseList_Week:Reload(#self.WeekTaskInfo.TaskList)
end

function M:OnMenuItemClick(Id,ItemInfo,IsInit)
    if self.CurShowWeek == Id then
        return
    end
    self.CurShowWeek = Id
    self:UpdateCurSelectWeekShow()
end
function M:OnMenuItemValidCheck(Id,IsClickTrgger)
    local PassStatus = self.TheModel:GetPassStatus()
    if Id > PassStatus.Week then
        if IsClickTrgger then
            local ShowTip = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Season","TaskWeekNotOpen")
            ShowTip = StringUtil.Format(ShowTip,Id)
            UIAlert.Show(ShowTip)
        end
        return false
    end
    return true
end
function M:OnPageValidCheck(Page)
    if Page > self.ValidPageNum then
        -- local ItemListIndex = (Page-1)*self.PageMaxNum + 1
        -- local ShowTip = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Season","TaskWeekNotOpen")
        -- ShowTip = StringUtil.Format(ShowTip,ItemListIndex)
        -- UIAlert.Show(ShowTip)
        return false
    end
    return true
end

function M:OnEscClicked()
    MvcEntry:CloseView(self.viewId)
end

--[[
    播放显示退出动效
]]
function M:PlayDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.VXE_Outside_Season_Task_In then
            self:VXE_Outside_Season_Task_In()
        end
    else
        -- if self.VXE_HalllMain_Tab_Out then
        --     self:VXE_HalllMain_Tab_Out()
        -- end
    end
end

return M
