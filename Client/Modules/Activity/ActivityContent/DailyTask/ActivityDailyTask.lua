-- UIHandlerViewBase
-- ViewInstance可实现：
-- OnInit  用于委托列表，事件列表的声明及初始化
-- OnShow  包装动作时会调用，可传参数
-- OnManualShow  当父Handler调用ManualOpen时，会触发此实现
-- OnShowAvator  界面展示会触发/此界面打开情况下上层虚拟关卡被关卡  （用于3D物品的展示和隐藏）
-- OnHideAvator  界面关闭状态或者销毁时会调用/此界面打开情况下再打开虚拟关卡会触发 （用于3D物品的展示和隐藏）
-- OnHide  界面关闭状态或者销毁时会调用
-- OnManualHide  当父Handler调用ManualClose时，会触发此实现
-- OnDestroy 界面销毁时被调用

--- 视图控制器:每日活动任务
local class_name = "ActivityDailyTask"
local ActivityDailyTask = BaseClass(ActivityViewBase, class_name)

function ActivityDailyTask:OnInit(Param)
    ActivityDailyTask.super.OnInit(self, Param)
    ---@type ActivityData
    self.Data = nil
    
    self.Model = MvcEntry:GetModel(ActivityModel)

    -- 活动倒计时{0}天{1}小时
    self.FormatTimeStr1 = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "Lua_Activity_CountDown_Day")
    -- 活动剩余时间{0}小时
    self.FormatTimeStr2 = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "Lua_Activity_CountDown_Hour")
    -- 活动剩余时间1小时
    self.FormatTimeStr3 = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "Lua_Activity_CountDown_Hour_Only")
    -- 活动下次刷新时间{0}小时{1}分
    self.FormatTimeStr4 = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "Lua_Activity_NextRefTime")
    -- 活动剩余时间
    self.FormatTimeStr5 = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "Lua_Activity_CountDown")

    self.MsgList = {
        {Model = DepotModel, MsgName = ListModel.ON_UPDATED_MAP_CUSTOM, Func = self.OnUpdatedMapCustom_Func },
        {Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_SUBITEM_STATE_LIST_NOTIFY, Func = self.OnActivitySubItemStateListNotify_Func },
    }
    self.BindNodes = {
        {UDelegate = self.View.WBP_ListTask.OnUpdateItem, Func = Bind(self, self.OnUpdateTaskItem)},
        {UDelegate = self.View.WBP_ListTask.OnReloadFinish, Func = Bind(self, self.OnReloadTaskFinish)},
        {UDelegate = self.View.WBP_AwardList.OnUpdateItem, Func = Bind(self, self.OnUpdateAwardItem)},
        {UDelegate = self.View.WBP_AwardList.OnReloadFinish, Func = Bind(self, self.OnReloadAwardFinish)},

        {UDelegate = self.View.Btn_instructions.OnClicked, Func = Bind(self, self.OnClickedInstructions)},
        -- {UDelegate = self.View.WBP_ListTask.OnScrollItem,Func = Bind(self, self.OnScrollItem)},
        -- {UDelegate = self.View.WBP_ListTask.OnPreUpdateItem,Func = Bind(self, self.OnPreUpdateItem)},
    }
end

function ActivityDailyTask:OnClickedInstructions()
    if self.Data then
        self.Data:OpenHelpSys()
    end
 
    -- CError("--------self.AwardSubIDList="..table.tostring(self.AwardSubIDList))
    -- CError("--------self.TaskSubIDList="..table.tostring(self.TaskSubIDList))
    -- MvcEntry:GetModel(RedDotModel):_Debug_PrintRedDotTree()
end

function ActivityDailyTask:OnShow(Param)
    self:OnManualShow(Param)
end

function ActivityDailyTask:OnHide(Param)

    self.Data = nil
    self.BtnGetInstance = nil
    self.Widget2Item = nil
    ---@type ActivitySubData[]
    self.TaskSubIDList = nil
    ---@type ActivitySubData[]
    self.AwardSubIDList = nil

    if self.AutoHideTimer then
        self:RemoveTimer(self.AutoHideTimer)
    end
    self.AutoHideTimer = nil
end

function ActivityDailyTask:OnManualShow(Param)
    Param = Param or {}

    self.NoteShow = true
    
    -- self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if Param.Id and (self.Data == nil or self.Data.ID ~= Param.Id) then
        self:SetData(Param.Id)
    end

    if self.BtnGetInstance == nil then
        local InParam = {
            OnItemClick = Bind(self, self.OnClickButtonTips),
            CommonTipsID = CommonConst.CT_SPACE,
            TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Activity", "Lua_Activity_ReqGetAll"),
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.None,
            ActionMappingKey = ActionMappings.SpaceBar
        }
        -- 一键领取
        self.BtnGetInstance = UIHandler.New(self, self.View.WBP_Btn_Get, WCommonBtnTips, InParam).ViewInstance
    end
    self.View.WBP_Btn_Get:RemoveAllActiveWidgetStyleFlags()
    self.View.WBP_Btn_Get:AddActiveWidgetStyleFlags(1)

    self:RefreshWBPListTask()

    if self.AwardSubIDList then
        self.View.WBP_AwardList:Reload(#(self.AwardSubIDList))
    end

    self:UpdateAcProgress()
    self:UpdateTimeCountDown()
end

function ActivityDailyTask:RefreshWBPListTask()
    if self.TaskSubIDList then
        self.TaskSubIDList  = self.Data:AcSubItemSort(self.TaskSubIDList)
        self.View.WBP_ListTask:Reload(#(self.TaskSubIDList))
    end
end

function ActivityDailyTask:SetData(AcId)
    if AcId and (self.Data == nil or self.Data.ID ~= AcId) then
        ---@type ActivityData
        self.Data = self.Model:GetData(AcId)
        if self.Data == nil then
            CError(string.format("ActivityDailyTask:SetData :: self.Data == nil !!! AcId=[%s]", AcId), true)
            return
        end
        
        self.TaskSubIDList = self.Data:GetSubItemsByType(Pb_Enum_ACTIVITY_SUB_ITEM_TYPE.ACTIVITY_SUB_ITEM_TYPE_TASK) or {}
        self.AwardSubIDList = self.Data:GetSubItemsByType(Pb_Enum_ACTIVITY_SUB_ITEM_TYPE.ACTIVITY_SUB_ITEM_TYPE_ACTIVITY) or {}

        CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_bg,self.Data:GetBigImg())
    end

    self.TaskSubIDList  = self.Data:AcSubItemSort(self.TaskSubIDList)
end

function ActivityDailyTask:OnStateChangedNotify()
    self:UpdateAcProgress()
end

function ActivityDailyTask:OnManualHide(Param)
    -- self.View:SetVisibility(UE.ESlateVisibility.Collapsed)

    if self.AutoHideTimer then
        self:RemoveTimer(self.AutoHideTimer)
    end
    self.AutoHideTimer = nil
end

-- function ActivityDailyTask:OnShowAvator(Data, IsNotVirtualTrigger) 
-- end

-- function ActivityDailyTask:OnHideAvator(Data, IsNotVirtualTrigger) 
-- end

-- function ActivityDailyTask:OnDestroy(Data, IsNotVirtualTrigger)
-- end

function ActivityDailyTask:OnUpdateTaskItem(_, Widget, Index)
    -- CError(string.format("aaaaaaaaaaaaaaaaaa OnUpdateTaskItem Widget=[%s],Index=[%s]",type(Widget), Index))
    local FixIndex = Index + 1

    local TargetInstance = self:CreateTaskItem(Widget)
    if TargetInstance == nil then
        return
    end

    ---@type number
    local SubItemId = self.TaskSubIDList[FixIndex]
    local Param = {ActiveityID = self.Data.ID, ActiveityType = self.Data.Type, SubItemId = SubItemId}
    TargetInstance:SetData(Param)
end

function ActivityDailyTask:CreateTaskItem(Widget)
    self.Widget2Item = self.Widget2Item or {}
    local Item = self.Widget2Item[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require("Client.Modules.Activity.ActivityContent.DailyTask.ActivityDailyTaskListItem"))
        self.Widget2Item[Widget] = Item
    end
    return Item.ViewInstance
end

function ActivityDailyTask:OnReloadTaskFinish()
    -- CError(string.format("aaaaaaaaaaaaaaaaaa OnReloadTaskFinish"))
end

function ActivityDailyTask:OnUpdateAwardItem(_, Widget, Index)
    -- CError(string.format("aaaaaaaaaaaaaaaaaa OnUpdateAwardItem Widget=[%s],Index=[%s]",Widget, Index))
    local FixIndex = Index + 1

    local TargetInstance = self:CreateAwardItem(Widget)
    if TargetInstance == nil then
        return
    end
    
    ---@type number
    local SubItemId = self.AwardSubIDList[FixIndex]
    local Param = {ActiveityID = self.Data.ID, ActiveityType = self.Data.Type, SubItemId = SubItemId}
    TargetInstance:SetData(Param)
end

function ActivityDailyTask:CreateAwardItem(Widget)
    self.Widget2Item = self.Widget2Item or {}
    local Item = self.Widget2Item[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require("Client.Modules.Activity.ActivityContent.DailyTask.ActivityDailyAwardListItem"))
        self.Widget2Item[Widget] = Item
    end
    return Item.ViewInstance
end

function ActivityDailyTask:OnReloadAwardFinish()
    -- CError(string.format("aaaaaaaaaaaaaaaaaa OnReloadAwardFinish"))
end

---点击一键领取
function ActivityDailyTask:OnClickButtonTips()
    --TODO:领取奖励
    if self.TaskSubIDList and next(self.TaskSubIDList) then
        local SubAcIDs = {}
        for k, SubID in pairs(self.TaskSubIDList) do
            ---@type ActivitySubData
            local SubData = self.Data:GetSubItemById(SubID)
            if SubData:IsCanGet() then
                table.insert(SubAcIDs, SubData.SubItemId)
            end
        end

        -- if next(SubAcIDs) then
        --     -- CError("点击回调！！！！一键领取!!")
        --     MvcEntry:GetCtrl(ActivityCtrl):TrySendProtoActivityGetPrizeReq(self.Data.ID, SubAcIDs)
        -- end
        MvcEntry:GetCtrl(ActivityCtrl):TrySendProtoActivityGetPrizeReq(self.Data.ID, SubAcIDs)
    end
end

---获取下次重置时间戳
function ActivityDailyTask:GetNextResetTime()
    local OffsetTime = MvcEntry:GetModel(UserModel):GetDayOffset()
    self.NextResetTime = TimeUtils.GetActivityNextResetTimestamp(self.Data:GetStartTime(), 1, OffsetTime)
    -- self.NextResetTime = TimeUtils.GetActivityNextResetTimestampPro("2024-04-1 00:00:00", 1, OffsetTime)
end

---更新活动时间
function ActivityDailyTask:UpdateTimeCountDown()

    local RefreshCountDown = function()
        if self.View.Text_Countdown then
            -- CError("更新活动时间xxxxxxxxxxxxxxxxxxxxx")
            local Second = self.Data.EndTime - GetTimestamp()
            local day = math.floor(Second / 86400)
            local hour = Second % 86400 / 3600
            if day >= 1 then
                -- 活动倒计时{0}天{1}小时
                self.View.Text_Countdown:SetText(StringUtil.Format(self.FormatTimeStr1, day, math.floor(hour)))
            elseif hour >= 1 then
                -- 活动剩余时间{0}小时
                self.View.Text_Countdown:SetText(StringUtil.Format(self.FormatTimeStr2, math.floor(hour)))
            else
                -- 活动剩余时间1小时
                self.View.Text_Countdown:SetText(self.FormatTimeStr3)
            end
        end
    
        local Second2 = self.NextResetTime - GetTimestamp()
        -- 活动下次刷新时间{0}小时{1}分
        -- local str2 = StringUtil.Format(self.FormatTimeStr4, math.floor(Second2 / 3600), math.ceil(Second2 % 3600 / 60))
        local str2 = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"),self.FormatTimeStr5, StringUtil.FormatLeftTimeShowStrRuleOne(Second2))
        self.View.Text_RefreshTime:SetText(str2)
        self.View.Text_RefreshTime_1:SetVisibility(UE.ESlateVisibility.Collapsed)

        --判断是否到达了重置时间点
        if GetTimestamp() > self.NextResetTime then
            -- 重新刷新任务列表
            self:RefreshWBPListTask()
            -- 重新更新今日活跃度
            self:UpdateVitalityProgress()

            self.RefCountNote = self.RefCountNote or 0
            self.RefCountNote = self.RefCountNote + 1
            if self.RefCountNote > 1 then
                -- 为了防止意外没有及时刷新到,至少重复刷新2次
                self.RefCountNote = 0
                self:GetNextResetTime()
            end
        end
    end

    if self.AutoHideTimer == nil then
        self:GetNextResetTime()
        self.AutoHideTimer = self:InsertTimer(60, RefreshCountDown ,true)
    end

    RefreshCountDown()
end

---更新今日活跃度进度相关
function ActivityDailyTask:UpdateVitalityProgress()
    if self.AwardSubIDList and self.AwardSubIDList[1] then
        local SubItemId = self.AwardSubIDList[1]
        ---@type ActivitySubData
        local SubData = self.Data:GetSubItemById(SubItemId)
        local CurCount = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(tonumber(SubData.TargetItemId))
        self.View.Text_Progress:SetText(CurCount) 

        local Num = #(self.AwardSubIDList)
        ---@type ActivitySubData
        local LastSubData = self.Data:GetSubItemById(self.AwardSubIDList[Num])
        local TargetValue = (tonumber(LastSubData.TargetValue))
        local Progress = CurCount / (TargetValue * 1.0)

        --将进度条分成9份
        local VI,VF = math.modf(TargetValue * 0.2)
        --进度条的1/5份的活跃值的数量
        local tempV_1 = VI
        --进度条的2/5份的活跃值的数量
        local tempV_3 = VI * 2
        --进度条的3/5份的活跃值的数量
        local tempV_5 = VI * 3
        --进度条的4/5份的活跃值的数量
        local tempV_7 = VI * 4
        --进度条的5/5份的活跃值的数量
        local tempV_9 = VI * 5

        if not self.bSetProgressTxt then
            self.bSetProgressTxt = true
            self.View.Text_Number01:SetText(tempV_1)
            self.View.Text_Number02:SetText(tempV_3)
            self.View.Text_Number03:SetText(tempV_5)
            self.View.Text_Number04:SetText(tempV_7)
            self.View.Text_Number05:SetText(tempV_9)
        end

        -- if CurCount <= tempV_1 then
        --     Progress = CurCount / tempV_1 * (1/9)
        -- elseif CurCount <= tempV_3 then
        --     Progress = (1/9) + ((CurCount - tempV_1) / tempV_1 * (2/9))
        -- elseif CurCount <= tempV_5 then
        --     Progress = (3/9) + ((CurCount - tempV_3) / tempV_1 * (2/9))
        -- elseif CurCount <= tempV_7 then
        --     Progress = (5/9) + ((CurCount - tempV_5) / tempV_1 * (2/9))
        -- elseif CurCount <= tempV_9 then
        --     Progress = (7/9) + ((CurCount - tempV_7) / tempV_1 * (2/9))
        -- end

        local baseStep = 1/9
        if CurCount <= tempV_1 then
            --进度条前面 1/9 的计算规则
            Progress = CurCount / tempV_1 * baseStep
        else
            --进度条后面 8/9 的计算规则
            Progress = baseStep + ((CurCount - tempV_1) / (tempV_9 - tempV_1) * (1 - baseStep))
        end
       
        self.View.Progress_Award:SetPercent(Progress)
    end
end

---道具发生变化回调
function ActivityDailyTask:OnUpdatedMapCustom_Func(ChangeMap)
    if not(CommonUtil.IsValid(self.View)) then
        return
    end

    self:UpdateVitalityProgress()
end

function ActivityDailyTask:OnActivitySubItemStateListNotify_Func()
    -- CError("ActivityDailyTask:OnActivitySubItemStateListNotify_Func")
    if not(CommonUtil.IsValid(self.View)) then
        return
    end

    if self.NoteShow then
        self.NoteShow = false
        self:RefreshWBPListTask()
    end
   
    self:UpdateAcProgress()
end

function ActivityDailyTask:UpdateAcProgress()
    if self.Data == nil then
        return
    end

    if not(CommonUtil.IsValid(self.View)) then
        return
    end

    self:UpdateWBPBtnGet()
    self:UpdateVitalityProgress()
end

---更新一键领取按钮
function ActivityDailyTask:UpdateWBPBtnGet()
    
    if not(CommonUtil.IsValid(self.View)) then
        return
    end

    if self.TaskSubIDList and next(self.TaskSubIDList) then
        local SubAcIDs = {}
        for k, SubID in pairs(self.TaskSubIDList) do
            ---@type ActivitySubData
            local SubData = self.Data:GetSubItemById(SubID)
            if SubData:IsCanGet() then
                table.insert(SubAcIDs, SubData.SubItemId)
            end
        end
        
        if self.View.WBP_Btn_Get then
            self.View.WBP_Btn_Get:RemoveAllActiveWidgetStyleFlags()
            if next(SubAcIDs) == nil then
                -- self.View.WBP_Btn_Get:RemoveAllActiveWidgetStyleFlags()
                -- self.View.WBP_Btn_Get:RemoveActiveWidgetStyleFlags(5)
                self.View.WBP_Btn_Get:AddActiveWidgetStyleFlags(5)
            end
        end
    else
        if self.View.WBP_Btn_Get then
            self.View.WBP_Btn_Get:RemoveAllActiveWidgetStyleFlags()
            self.View.WBP_Btn_Get:AddActiveWidgetStyleFlags(5)
        end
    end

    
    --MvcEntry:GetModel(RedDotModel):_Debug_PrintRedDotTree()
end

return ActivityDailyTask
