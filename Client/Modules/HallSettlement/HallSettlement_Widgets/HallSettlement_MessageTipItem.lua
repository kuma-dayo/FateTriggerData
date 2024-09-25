
-- 局外结算消息提示item
local class_name = "HallSettlement_MessageTipItem"
---@class HallSettlement_MessageTipItem
local HallSettlement_MessageTipItem = BaseClass(nil, class_name)

local AnimationEventTypeEnum = {
    -- 入场动画
    Animation_In = 1,
    -- 上移动画
    Animation_MoveUp = 2,
    -- 离场动画
    Animation_Out = 3,
}

-- 动效事件列表
local AnimationEventInfoList = {
    -- 入场动画
    [AnimationEventTypeEnum.Animation_In] = {
        -- 事件名
        EventName = "VXE_OutsideGame_Tips_In",
        -- 动画名
        AnimationName = "vx_settlement_list_in",
    },
    -- 上移动画
    [AnimationEventTypeEnum.Animation_MoveUp] = {
        -- 事件名
        EventName = "VXE_OutsideGame_Tips_Position",
        -- 动画名
        AnimationName = "vx_settlement_list_position",
        -- 是否上移
        IsMoveUp = true,
    },
    -- 离场动画
    [AnimationEventTypeEnum.Animation_Out] = {
        -- 事件名
        EventName = "VXE_OutsideGame_Tips_Out",
        -- 动画名
        AnimationName = "vx_settlement_list_out",
    },
}

-- 消息item根据位置需要播放的动效事件
local MessageTipAnimationEventList = {
    -- 位置1
    [1] = {
        -- 对应位置需要播放的动效事件
        AnimationEventInfo = {
            1,3
        },
        -- 对应位置的坐标
        Position = UE.FVector2D(0, 100),
    },
    [2] = {
        -- 对应位置需要播放的动效事件
        AnimationEventInfo = {
            1,2,3
        },
        -- 对应位置的坐标
        Position = UE.FVector2D(0, 200),
    },
    [3] = {
        -- 对应位置需要播放的动效事件
        AnimationEventInfo = {
            1,2,2,3
        },
        -- 对应位置的坐标
        Position = UE.FVector2D(0, 300),
    },
}
function HallSettlement_MessageTipItem:OnInit()
    self.BindNodes = 
    {
        { UDelegate = self.View.OnAnimationPlayComplete,	            Func = Bind(self, self.OnAnimationPlayCompleteFunc) },
    }
    
    ---@type HallSettlementModel
    self.HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)
    ---@type HallSettlementMessageTip
    self.MessageTipData = nil
    -- 成就通用item组件
    self.AchievementCommonItemWidget = nil
    -- 任务奖励通用item组件
    self.TaskRewardCommonItemWidget = nil
    -- 获得奖励通用item组件
    self.PropCommonItemWidget = nil

    -- 播放动画的序号
    self.PlayerAnimationIndex = 1
    -- 播放动画的列表
    self.PlayerAnimationList = {}
    -- 是否正在播放动画 外部判断当前item状态
    self.IsPlayerAnimation = false
    -- 动画是否全部播完
    self.IsAnimationComplete = false
    self.CurPlayerAnimationType = ""
end

-- @class MessageTipData
function HallSettlement_MessageTipItem:OnShow(Param)
    if Param and Param.MessageTip and Param.PositionIndex then
        CLog("HallSettlement_MessageTipItem:OnShow ")
        self.MessageTipData = Param.MessageTip
        self.PositionIndex = Param.PositionIndex
        self.DelayPlayerAnimationTime = Param.DelayPlayerAnimationTime
        self.IsPlayerAnimation = false
        self.IsAnimationComplete = false
        self:UpdateShow()
        if self.DelayPlayerAnimationTime then
            self.IsPlayerAnimation = true
            self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
            self:ClearDelayPlayerAnimationTimer()
            self.DelayPlayerAnimationTimer = Timer.InsertTimer(self.DelayPlayerAnimationTime,function()
                self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                self:InitPlayerAnimation()
            end)   
        else
            self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self:InitPlayerAnimation()
        end
    end
end

--移除长按检测定时器
function HallSettlement_MessageTipItem:ClearDelayPlayerAnimationTimer()
    if self.DelayPlayerAnimationTimer then
        Timer.RemoveTimer(self.DelayPlayerAnimationTimer)
    end
    self.DelayPlayerAnimationTimer = nil
end

function HallSettlement_MessageTipItem:OnHide()
    self:ClearDelayPlayerAnimationTimer()
end

-- 初始化动效播放
function HallSettlement_MessageTipItem:InitPlayerAnimation()
    local MessageTipAnimationEvent = MessageTipAnimationEventList[self.PositionIndex]
    if MessageTipAnimationEvent then
        self.PlayerAnimationList = MessageTipAnimationEvent.AnimationEventInfo
        self:UpdateItemPosition()
        self.PlayerAnimationIndex = 1
        self:OnPlayerAnimation()
    else
        self:OnClearItem() 
    end
end

-- 播放下一个动效
function HallSettlement_MessageTipItem:OnPlayerAnimation()
    self.CurPlayerAnimationType = self.PlayerAnimationList[self.PlayerAnimationIndex]
    if self.CurPlayerAnimationType then
        local AnimationEventInfo = AnimationEventInfoList[self.CurPlayerAnimationType]
        if AnimationEventInfo then
            self.PlayerAnimationIndex = self.PlayerAnimationIndex + 1
            if self.View[AnimationEventInfo.EventName] and self.View[AnimationEventInfo.AnimationName] then
                self.IsPlayerAnimation = true
                self.IsAnimationComplete = false
                -- 如果是上移动画 就把当前位置的index更新一下
                if AnimationEventInfo.IsMoveUp then
                    self:UpdateItemPosition()
                    self.PositionIndex = self.PositionIndex - 1
                end
                self.View[AnimationEventInfo.EventName](self.View)  
            end
        end
    end
end

function HallSettlement_MessageTipItem:OnAnimationPlayCompleteFunc()
    self.IsPlayerAnimation = false
    -- 播放渐隐完成后移除
    if self.CurPlayerAnimationType == AnimationEventTypeEnum.Animation_Out then
        self.IsAnimationComplete = true
    end
    self.HallSettlementModel:DispatchType(HallSettlementModel.ON_MESSAGE_ITEM_ANIMATION_COMPLETE_EVENT)
end

-- 是否在播放动画
function HallSettlement_MessageTipItem:GetIsPlayerAnimation()
    return self.IsPlayerAnimation
end

-- 动画是否全部播放完成
function HallSettlement_MessageTipItem:GetIsAnimationComplete()
    return self.IsAnimationComplete
end

-- 下一个动画是否播放离场动画
function HallSettlement_MessageTipItem:GetIsAlReadyPlayAnimationOut()
    local PlayerAnimationType = self.PlayerAnimationList[self.PlayerAnimationIndex]
    local IsAlReadyPlayAnimationOut = PlayerAnimationType and PlayerAnimationType == AnimationEventTypeEnum.Animation_Out
    return IsAlReadyPlayAnimationOut
end

-- 更新item坐标
function HallSettlement_MessageTipItem:UpdateItemPosition()
    local MessageTipAnimationEvent = MessageTipAnimationEventList[self.PositionIndex]
    if MessageTipAnimationEvent then
        local Position = MessageTipAnimationEvent.Position
        self.View.VerticalBox.Slot:SetPosition(Position)
    end
end

-- 删除Item
function HallSettlement_MessageTipItem:OnClearItem()
    if CommonUtil.IsValid(self.View) then
        self.View:RemoveFromParent()
    end
end

-- 更新UI展示
function HallSettlement_MessageTipItem:UpdateShow()          
    if self.MessageTipData.MessageType == HallSettlementModel.Enum_MessageTipType.TaskComplete then
        self.View.WidgetSwitcher:SetActiveWidget(self.View.Panel_Task)   
        self:UpdateTaskShow()
    elseif self.MessageTipData.MessageType == HallSettlementModel.Enum_MessageTipType.AchievementGet then
        self.View.WidgetSwitcher:SetActiveWidget(self.View.Panel_Achievement)   
        self:UpdateAchievementShow()
    elseif self.MessageTipData.MessageType == HallSettlementModel.Enum_MessageTipType.TaskReward then
        self.View.WidgetSwitcher:SetActiveWidget(self.View.Panel_TaskReward) 
        self:UpdateTaskRewardShow()        
    elseif self.MessageTipData.MessageType == HallSettlementModel.Enum_MessageTipType.PropDrop then
        self.View.WidgetSwitcher:SetActiveWidget(self.View.Panel_PropDrop) 
        self:UpdatePropDropShow()        
    end
end

-- 更新任务类型的UI
function HallSettlement_MessageTipItem:UpdateTaskShow()
    self.View.Text_Task:SetText(StringUtil.Format(self.MessageTipData.TextContent))
    self.View.Text_TaskDesc:SetText(StringUtil.Format(self.MessageTipData.TextDesc))
    CommonUtil.SetImageColorFromHex(self.View.Image_Quality, "B4B2AE")
end

-- 更新成就获得类型的UI
function HallSettlement_MessageTipItem:UpdateAchievementShow()
    self.View.Text_Achievement:SetText(StringUtil.Format(self.MessageTipData.TextContent))
    self.View.Text_AchievementDesc:SetText(StringUtil.Format(self.MessageTipData.TextDesc))
    CommonUtil.SetTextColorFromQuality(self.View.Text_Achievement, self.MessageTipData.Quality)
    CommonUtil.SetImageColorFromQuality(self.View.Image_Quality, self.MessageTipData.Quality)

    local ItemId = self.MessageTipData.ItemId
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.ACHIEVEMENT,
        ItemId = ItemId,
        HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.NONE,
    }
    if not self.AchievementCommonItemWidget then
        self.AchievementCommonItemWidget = UIHandler.New(self, self.View.WBP_CommonItemIcon_Achievement, CommonItemIcon, IconParam).ViewInstance
    else
        self.AchievementCommonItemWidget:UpdateUI(IconParam)
    end
end

-- 更新任务奖励类型的UI
function HallSettlement_MessageTipItem:UpdateTaskRewardShow()
    self.View.Text_TaskReward:SetText(StringUtil.Format(self.MessageTipData.TextContent))
    self.View.Text_TaskRewardDesc:SetText(StringUtil.Format(self.MessageTipData.TextDesc))
    CommonUtil.SetTextColorFromQuality(self.View.Text_TaskReward, self.MessageTipData.Quality)
    CommonUtil.SetImageColorFromQuality(self.View.Image_Quality, self.MessageTipData.Quality)

    local ItemId = self.MessageTipData.ItemId
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemId,
        ItemNum = self.MessageTipData.ItemNum,
        ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE,
        HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.NONE,
    }
    if not self.TaskRewardCommonItemWidget then
        self.TaskRewardCommonItemWidget = UIHandler.New(self, self.View.WBP_CommonItemIcon_TaskReward, CommonItemIcon, IconParam).ViewInstance
    else
        self.TaskRewardCommonItemWidget:UpdateUI(IconParam)
    end
end

-- 更新掉落奖励类型的UI
function HallSettlement_MessageTipItem:UpdatePropDropShow()
    local IsHasAdditiveCard = self.MessageTipData.AdditiveCardNum and self.MessageTipData.AdditiveCardNum > 0 or false
    self.View.Image_AdditiveCard:SetVisibility(IsHasAdditiveCard and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

    self.View.Text_Prop:SetText(StringUtil.Format(self.MessageTipData.TextContent))
    self.View.Text_PropDesc:SetText(StringUtil.Format(self.MessageTipData.TextDesc))
    CommonUtil.SetTextColorFromQuality(self.View.Text_Prop, self.MessageTipData.Quality)
    CommonUtil.SetImageColorFromQuality(self.View.Image_Quality, self.MessageTipData.Quality)

    local ItemId = self.MessageTipData.ItemId
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemId,
        ItemNum = self.MessageTipData.ItemNum,
        ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE,
        HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.NONE,
    }
    if not self.PropCommonItemWidget then
        self.PropCommonItemWidget = UIHandler.New(self, self.View.WBP_CommonItemIcon_PropDrop, CommonItemIcon, IconParam).ViewInstance
    else
        self.PropCommonItemWidget:UpdateUI(IconParam)
    end
end

function HallSettlement_MessageTipItem:OnHide()          

end


return HallSettlement_MessageTipItem
