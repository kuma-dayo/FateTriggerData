--[[
   赛季任务界面的任务Item
]] 
local class_name = "SeasonBpTaskItemLogic"
local SeasonBpTaskItemLogic = BaseClass(nil, class_name)

function SeasonBpTaskItemLogic:OnInit()
    self.TheModel = MvcEntry:GetModel(SeasonBpModel)
    
    self.BindNodes = {
		{ UDelegate = self.View.WBP_Season_Task_List_Btn.BtnGo.OnClicked,				Func = Bind(self,self.OnBtnGoClick) },
    }
end

--[[
    message BpTaskBase
    {
        int64 BpTaskId = 1;
        int64 TaskId = 2;
    }
    Param = {
        BpTaskBase = {},
        TaskType = 1,--1表示日任务，2表示周任务
    }
]]
function SeasonBpTaskItemLogic:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function SeasonBpTaskItemLogic:OnHide()
end

function SeasonBpTaskItemLogic:UpdateUI(Param)
    if not Param then
        CWaring("SeasonBpTaskItemLogic:UpdateUI Param nil")
        return
    end
    -- print_r(Param,"SeasonBpTaskItemLogic:UpdateUI",true)
    self.TaskId = Param.BpTaskBase.TaskId
    local TaskCfg = G_ConfigHelper:GetSingleItemById(Cfg_TaskCfg,self.TaskId)
    local TaskProgress = MvcEntry:GetModel(TaskModel):GetTaskProcess(self.TaskId)
    if not TaskProgress or not TaskProgress.ProcessValue or not TaskProgress.MaxProcess then
        TaskProgress = {
            ProcessValue = 0,
            MaxProcess = 1,
        }
        CError("SeasonBpTaskItemLogic:UpdateUI TaskProgress nil:" .. self.TaskId,true)
    end
    self.View.ProgressBar:SetPercent(TaskProgress.ProcessValue/TaskProgress.MaxProcess)
    self.View.LbProgressCur:SetText(tostring(TaskProgress.ProcessValue))
    self.View.LbProgressAll:SetText("/" .. tostring(TaskProgress.MaxProcess))
    
    local IsFinish = MvcEntry:GetModel(TaskModel):HasTaskFinished(self.TaskId)
    self.View.WBP_Season_Task_List_Btn:RemoveAllActiveWidgetStyleFlags()
    local Flags = {}
    if IsFinish then
        self.View.WBP_Season_Task_List_Btn:AddActiveWidgetStyleFlags(5)--按钮状态
        self.View.WBP_Season_Task_List_Btn.BtnGo:SetIsEnabled(false)
        Flags = {1}
        self.View.LbName:SetText(StringUtil.Format("<span color=\"#333333\">{0}</>",TaskCfg[Cfg_TaskCfg_P.TaskDescription]))
    else
        if Param.TaskType == 2 then
            Flags = {2}
        end
        self.View.WBP_Season_Task_List_Btn.BtnGo:SetIsEnabled(true)
        self.View.LbName:SetText(StringUtil.Format("<span color=\"#F5EFDF\">{0}</>",TaskCfg[Cfg_TaskCfg_P.TaskDescription]))
    end
    self.View:SetActiveWidgetStyleFlags(Flags)--底板状态

    --TODO 更新奖励展示

    self.View.GoodsHBox:ClearChildren()
    if TaskCfg[Cfg_TaskCfg_P.RewardId] and TaskCfg[Cfg_TaskCfg_P.RewardId] > 0 then
        local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/Components/WBP_CommonItemIcon.WBP_CommonItemIcon")
        local Widget = NewObject(WidgetClass, self.View)
        self.View.GoodsHBox:AddChild(Widget)

        -- Widget.Padding.Right = 0
        -- if k ~= #self.Param.ItemList then
        --     Widget.Padding.Right = 14
        -- end
        -- Widget:SetPadding(Widget.Padding)

        -- Widget.Slot.Padding.Bottom = 10
        -- Widget.Slot:SetPadding(Widget.Slot.Padding)
        local ItemId = TaskCfg[Cfg_TaskCfg_P.RewardId]
        local ItemNum = TaskCfg[Cfg_TaskCfg_P.RewardNum]
        local IconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
            ItemId = ItemId,
            ItemNum = ItemNum,
            -- ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.TIP,
            HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
            ShowCount = true,
            IsGot = IsFinish,

        }
        UIHandler.New(self,Widget,CommonItemIcon,IconParam)
    end

    if (TaskCfg[Cfg_TaskCfg_P.JumpId] and TaskCfg[Cfg_TaskCfg_P.JumpId] > 0) or IsFinish then
        self.View.WBP_Season_Task_List_Btn:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.View.WBP_Season_Task_List_Btn:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

--[[
    前往点击
]]
function SeasonBpTaskItemLogic:OnBtnGoClick()
    local TaskCfg = G_ConfigHelper:GetSingleItemById(Cfg_TaskCfg,self.TaskId)
    MvcEntry:GetCtrl(ViewJumpCtrl):JumpTo(TaskCfg[Cfg_TaskCfg_P.JumpId])
end

return SeasonBpTaskItemLogic
