local ActivityDefine = require("Client.Modules.Activity.ActivityDefine")
--- 视图控制器:每日活动任务ListItem
local class_name = "ActivityDailyTaskListItem"
local ActivityDailyTaskListItem = BaseClass(ActivitySubViewBase, class_name)

function ActivityDailyTaskListItem:OnInit(Param)
    ActivityDailyTaskListItem.super.OnInit(self, Param)
    ---@type ActivitySubData
    self.SubData = nil
    self.Model = MvcEntry:GetModel(ActivityModel)
    self.MsgList = {
        {Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_SUBITEM_STATE_LIST_NOTIFY, Func = self.OnActivitySubItemStateListNotify },
        {Model = TaskModel, MsgName = ListModel.ON_UPDATED_MAP, Func = self.OnTaskUpdate},
    }
    self.BindNodes = {
        {UDelegate = self.View.WBP_Btn_Strong.GUIButton_Tips.OnClicked, Func = Bind(self, self.OnClickBtnStrong)},
		-- {UDelegate = self.View.WBP_Btn_Strong.GUIButton_Tips.OnHovered,Func = Bind(self, self.OnHoveredStrong)},
        -- {UDelegate = self.View.WBP_Btn_Strong.GUIButton_Tips.OnUnhovered,Func = Bind(self, self.OnUnhoveredStrong)},
        {UDelegate = self.View.WBP_Btn_Weak.GUIButton_Tips.OnClicked, Func = Bind(self, self.OnClickBtnWeak)},
		-- {UDelegate = self.View.WBP_Btn_Weak.GUIButton_Tips.OnHovered,Func = Bind(self, self.OnHoveredWeak)},
        -- {UDelegate = self.View.WBP_Btn_Weak.GUIButton_Tips.OnUnhovered,Func = Bind(self, self.OnUnhoveredWeak)},
    }
end

function ActivityDailyTaskListItem:OnShow(Param)
    -- CError("ActivityDailyTaskListItem:OnShow,Param =" .. table.tostring(Param))
    self:OnManualShow(Param)
end

-- function ActivityDailyTaskListItem:OnHide(Param)
--     self.SubData = nil
-- end

-- function ActivityDailyTaskListItem:OnManualShow(Param)
--     -- CError("ActivityDailyTaskListItem:OnManualShow,Param =" .. table.tostring(Param))
--    self:SetData(Param) 
-- end


function ActivityDailyTaskListItem:OnSubStateChangedNotify()
    self:RefreshSubitemState()
    self:InteractRedDot()
end

function ActivityDailyTaskListItem:SetData(Param)
    -- CError("ActivityDailyTaskListItem:SetData Param = " .. table.tostring(Param))
    Param = Param or {}
    if Param.SubItemId then
        self.ActiveityID = Param.ActiveityID
        ---@type ActivityData
        local Data = self.Model:GetData(Param.ActiveityID)
        self.SubData = Data:GetSubItemById(Param.SubItemId)
    end

    -- if self.BtnStrongInstance == nil then
    --     --领取
    --     self.BtnStrongInstance = UIHandler.New(self, self.View.WBP_Btn_Strong, WCommonBtnTips,
    --     {
    --         OnItemClick = Bind(self, self.OnClickBtnStrong),
    --         -- CommonTipsID = CommonConst.CT_SPACE,
    --         TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "11510"),
    --         HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    --         -- ActionMappingKey = ActionMappings.SpaceBar
    --     }).ViewInstance
    -- end
    
    -- if self.BtnWeakInstance == nil then
    --     --前往
    --     self.BtnWeakInstance = UIHandler.New(self, self.View.WBP_Btn_Weak, WCommonBtnTips,
    --     {
    --         OnItemClick = Bind(self, self.OnClickBtnWeak),
    --         -- CommonTipsID = CommonConst.CT_SPACE,
    --         TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "Lua_Activity_GoJump"),
    --         HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    --         -- ActionMappingKey = ActionMappings.SpaceBar
    --     }).ViewInstance
    -- end

    
    self:InitBtn()
    self:UpdateItemUI()
end

function ActivityDailyTaskListItem:InitBtn()
    --领取
    self.View.WBP_Btn_Strong.ControlTipsTxt:SetText(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "11510"))
    if self.View.WBP_Btn_Strong.ScaleBox_Currency then
        self.View.WBP_Btn_Strong.ScaleBox_Currency:Setvisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.View.WBP_Btn_Strong.SizeBox_Icon then
        self.View.WBP_Btn_Strong.SizeBox_Icon:Setvisibility(UE.ESlateVisibility.Collapsed)
    end
    self.View.WBP_Btn_Strong:RemoveAllActiveWidgetStyleFlags()
    self.View.WBP_Btn_Strong:AddActiveWidgetStyleFlags(1)
    --前往
    self.View.WBP_Btn_Weak.ControlTipsTxt:SetText(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "Lua_Activity_GoJump"))
    if self.View.WBP_Btn_Weak.ScaleBox_Currency then
        self.View.WBP_Btn_Weak.ScaleBox_Currency:Setvisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.View.WBP_Btn_Weak.SizeBox_Icon then
        self.View.WBP_Btn_Weak.SizeBox_Icon:Setvisibility(UE.ESlateVisibility.Collapsed)
    end
    self.View.WBP_Btn_Weak:RemoveAllActiveWidgetStyleFlags()
    self.View.WBP_Btn_Weak:AddActiveWidgetStyleFlags(1)
end

function ActivityDailyTaskListItem:OnManualHide(Param)
    self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
end

-- function ActivityDailyTaskListItem:OnShowAvator(Data, IsNotVirtualTrigger) 
-- end

-- function ActivityDailyTaskListItem:OnHideAvator(Data, IsNotVirtualTrigger) 
-- end

-- function ActivityDailyTaskListItem:OnDestroy(Data, IsNotVirtualTrigger)
-- end

---领取按钮
function ActivityDailyTaskListItem:OnClickBtnStrong()
    --TODO:领取奖励
    if self.SubData then
        --CError("ActivityDailyTaskListItem:OnClickBtnStrong 点击领取奖励 !!")
        MvcEntry:GetCtrl(ActivityCtrl):TrySendProtoActivityGetPrizeReq(self.ActiveityID, {self.SubData.SubItemId})

        -- if self.SubData:GetState() == ActivityDefine.ActivitySubState.Can then
        --     self:InteractRedDot()
        -- end
    end
end

---前往按钮
function ActivityDailyTaskListItem:OnClickBtnWeak()
    --TODO:前往按钮
    if self.SubData then
        -- CError("--每日任务点击前往按钮")
        CLog("--每日任务点击前往按钮")
        self.SubData:JumpView()
    end
end

function ActivityDailyTaskListItem:UpdateItemUI()
    if self.SubData == nil then
        return
    end

    self:RefreshSubitemState()
end

---更新奖励Icon
function ActivityDailyTaskListItem:UpdateAwardItem()
    if self.SubData == nil then
        return
    end

    if self.AwardItemHandler == nil then
        self.AwardItemHandler = UIHandler.New(self, self.View.WBP_AwardItem, CommonItemIcon)
    end

    ---@type ActivityReward[]
    local Rewards = self.SubData.Rewards
    ---@type ActivityReward 奖励中的第1个
    local FristReward = (Rewards and #(Rewards) > 0) and Rewards[1] or nil
    
    if FristReward then
        local IconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
            ItemId = FristReward.RewardId,
            ItemNum = FristReward.RewardNum,
            ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE,
            ShowCount = true,
            -- HoverScale = 1.15,
            HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
            RedDotKey = "ActivitySubItem_",
            RedDotSuffix = self.SubData.SubItemId,
            RedDotInteractType = CommonConst.RED_DOT_INTERACT_TYPE.NONE
        }
        if self.AwardItemHandler and self.AwardItemHandler:IsValid() then
            self.AwardItemHandler.ViewInstance:UpdateUI(IconParam, true)

            local state = self.SubData:GetState()
            if state == ActivityDefine.ActivitySubState.Not then
                self.AwardItemHandler.ViewInstance:SetIsCanGet(false)
                self.AwardItemHandler.ViewInstance:SetIsGot(false)
            elseif state == ActivityDefine.ActivitySubState.Can then
                self.AwardItemHandler.ViewInstance:SetIsCanGet(true)
            elseif state == ActivityDefine.ActivitySubState.Got then
                self.AwardItemHandler.ViewInstance:SetIsGot(true)
            end
        end
        -- CError("ActivityDailyTaskListItem:UpdateAwardItem 刷新红点")
    end
end

--- 取消红点逻辑
function ActivityDailyTaskListItem:InteractRedDot()
    if self.AwardItemHandler and self.AwardItemHandler:IsValid() and self.SubData:IsGot() then
        ---@type RedDotCtrl
        local RedDotCtrl = MvcEntry:GetCtrl(RedDotCtrl)
        -- RedDotCtrl:Interact("ActivitySubItem_", self.SubData.SubItemId, RedDotModel.Enum_RedDotTriggerType.Click) 
        RedDotCtrl:Interact("ActivitySubItem_", self.SubData.SubItemId)   
    end
end

function ActivityDailyTaskListItem:OnActivitySubItemStateListNotify()
    -- CError("ActivityDailyTaskListItem:OnActivitySubItemStateListNotify")
    if not(CommonUtil.IsValid(self.View)) then
        return
    end
    self:RefreshSubitemState()
end

function ActivityDailyTaskListItem:RefreshSubitemState()
    self:UpdateAwardItem()
    self:UndateTaskProgress()
    self:UpdateSubitemState()
end

---任务进度
function ActivityDailyTaskListItem:UndateTaskProgress()
    if self.SubData == nil then
       return
    end

    -- message TargetProcessNode
    -- {
    --     int64 EventId       = 1;        // Key是任务的事件类型Id,参考Task.xslx,TargetEventCfg页签
    --     int64 ProcessValue  = 2;        // 当前进度
    --     int64 MaxProcess    = 3;        // 目标最大进度
    -- } 

    local TaskProcess = MvcEntry:GetModel(TaskModel):GetTaskProcess(self.SubData.TaskID)
    local TaskDes = self.SubData:GetTittle()
    if TaskProcess then
        local TipStr = StringUtil.Format("{0}({1}/{2})", TaskDes, TaskProcess.ProcessValue or 0, TaskProcess.MaxProcess or 0)
        -- if UE.UGFUnluaHelper.IsEditor() then
        --     TipStr = TipStr .. "-" .. self.SubData.SubItemId.."-" .. self.SubData.TaskID
        -- end
        self.View.BP_TextTask:SetText(TipStr)
    else
        self.View.BP_TextTask:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam"), TaskDes))
    end
end

---任务状态
function ActivityDailyTaskListItem:UpdateSubitemState()
    if self.SubData == nil then
        return
    end
   
    local state = self.SubData:GetState()

    --更新领取按钮的状态
    local UpdateWBP_Btn_StrongUI = function()
        self.View.WBP_Btn_Strong:RemoveAllActiveWidgetStyleFlags()
        if state == ActivityDefine.ActivitySubState.Not then
            --未完成
            self.View.WBP_Btn_Strong.ControlTipsTxt:SetText(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "11508"))
            self.View.WBP_Btn_Strong:AddActiveWidgetStyleFlags(5)
        elseif state == ActivityDefine.ActivitySubState.Can then
            --领取
            self.View.WBP_Btn_Strong.ControlTipsTxt:SetText(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "11510"))
            -- self.View.WBP_Btn_Strong:AddActiveWidgetStyleFlags(1)
        elseif state == ActivityDefine.ActivitySubState.Got then
            --已领取
            self.View.WBP_Btn_Strong.ControlTipsTxt:SetText(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "Lua_Activity_HasGot"))
            self.View.WBP_Btn_Strong:AddActiveWidgetStyleFlags(5)
        end
    end

    local JumpID = self.SubData:GetJumpID()
    if JumpID > 0 and state == ActivityDefine.ActivitySubState.Not then
        --打开 WBP_Btn_Weak 按钮
        self.View.WBP_Btn_Strong:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.WBP_Btn_Weak:SetVisibility(UE.ESlateVisibility.Visible)
        self.View.WBP_Btn_Weak:RemoveAllActiveWidgetStyleFlags()
        self.View.WBP_Btn_Weak:AddActiveWidgetStyleFlags(1)
        --前往
        self.View.WBP_Btn_Weak.ControlTipsTxt:SetText(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "Lua_Activity_GoJump"))
    elseif JumpID <= 0 and state == ActivityDefine.ActivitySubState.Not then
        --打开 WBP_Btn_Weak 按钮
        self.View.WBP_Btn_Strong:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.WBP_Btn_Weak:SetVisibility(UE.ESlateVisibility.Visible)
        self.View.WBP_Btn_Weak:RemoveAllActiveWidgetStyleFlags()
        self.View.WBP_Btn_Weak:AddActiveWidgetStyleFlags(5)
        --未完成
        self.View.WBP_Btn_Weak.ControlTipsTxt:SetText(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "11508"))
    else
        --打开 WBP_Btn_Strong 按钮
        self.View.WBP_Btn_Strong:SetVisibility(UE.ESlateVisibility.Visible)
        self.View.WBP_Btn_Weak:SetVisibility(UE.ESlateVisibility.Collapsed)
        UpdateWBP_Btn_StrongUI()
    end
end

function ActivityDailyTaskListItem:OnTaskUpdate(Change)
    if not(CommonUtil.IsValid(self.View)) then
        return
    end
    
    if self.SubData == nil then
        return
    end
	for TaskId, _ in pairs(Change) do
        if self.SubData.TaskID == TaskId then
            self:UndateTaskProgress()
            break
        end
	end
end

return ActivityDailyTaskListItem