--[[
   等级历程item逻辑
]] 
local class_name = "PlayerLevelGrowthItemLogic"
local PlayerLevelGrowthItemLogic = BaseClass(UIHandlerViewBase, class_name)

function PlayerLevelGrowthItemLogic:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.GUIButton_Award.OnClicked,    Func = Bind(self,self.OnButtonClicked) },
        { UDelegate = self.View.GUIButton_Award.OnHovered,    Func = Bind(self,self.OnButtonHovered) },
        { UDelegate = self.View.GUIButton_Award.OnUnhovered,  Func = Bind(self,self.OnButtonUnhovered) },
        { UDelegate = self.View.GUIButton_Award.OnPressed,    Func = Bind(self,self.OnButtonPressed) },
        { UDelegate = self.View.GUIButton_Award.OnReleased,   Func = Bind(self,self.OnButtonReleased) },
    }
    -- 等级历程item显示类型
    self.Enum_LevelGrowthItemShowType = {
        -- 未解锁状态
        Lock = 1,
        -- 未完成状态
        Undone = 2,
        -- 可领取奖励状态
        Receive = 3,
        -- 已领取状态
        Received = 4,
    }
    -- 等级历程item状态对应名称
    self.Const_LevelGrowthItemWidgetName = {
        [self.Enum_LevelGrowthItemShowType.Lock] = "Panel_Lock",
        [self.Enum_LevelGrowthItemShowType.Undone] = "Panel_Undone",
        [self.Enum_LevelGrowthItemShowType.Receive] = "Panel_Receive",
        [self.Enum_LevelGrowthItemShowType.Received] = "Panel_Received",
    }

    ---@type PlayerLevelGrowthCtrl
    self.PlayerLevelGrowthCtrl = MvcEntry:GetCtrl(PlayerLevelGrowthCtrl)

    ---@type LevelGrowthInfo
    self.LevelGrowthInfo = nil
    self.ShowType = 1
    -- 奖励item复用列表
    self.RewardItemList = {}
end

--[[
    LevelGrowthInfo
]]
function PlayerLevelGrowthItemLogic:OnShow(LevelGrowthInfo)
    if not LevelGrowthInfo then
        return
    end
    self:UpdateUI(LevelGrowthInfo)
end

function PlayerLevelGrowthItemLogic:OnHide()

end

function PlayerLevelGrowthItemLogic:UpdateUI(LevelGrowthInfo)
    if not LevelGrowthInfo then
        return
    end
    ---@type SeasonRankRuleConfig
    self.LevelGrowthInfo = LevelGrowthInfo
    self:UpdateShow()
end

-- 更新展示
function PlayerLevelGrowthItemLogic:UpdateShow()
    self:UpdateProgressShow()
    self:UpdateRewardShow()
    
    -- 获取展示类型 切换UI展示
    self.ShowType = self:GetLevelGrowthItemShowType()
    local WidgetName = self.Const_LevelGrowthItemWidgetName[self.ShowType] or ""
    if self.View[WidgetName] then
        self.View.WidgetSwitcher_State:SetActiveWidget(self.View[WidgetName])
    end
    if self.ShowType == self.Enum_LevelGrowthItemShowType.Lock then
        self:UpdateLockShow()
    elseif self.ShowType == self.Enum_LevelGrowthItemShowType.Undone then
        self:UpdateUndoneShow()
    elseif self.ShowType == self.Enum_LevelGrowthItemShowType.Receive then
        self:UpdateReceiveShow()
    elseif self.ShowType == self.Enum_LevelGrowthItemShowType.Received then
        self:UpdateReceivedShow()
    end
end

-- 获取应该显示的UI状态
function PlayerLevelGrowthItemLogic:GetLevelGrowthItemShowType()
    local ShowType = self.Enum_LevelGrowthItemShowType.Lock
    if self.LevelGrowthInfo.LevelRewardState == PlayerLevelGrowthModel.Enum_LevelRewardState.AlreadyGotReward then
        -- 奖励已领取状态
        ShowType = self.Enum_LevelGrowthItemShowType.Received
    elseif self.LevelGrowthInfo.LevelRewardState == PlayerLevelGrowthModel.Enum_LevelRewardState.NotGetReward then
        -- 等级不满足的话用lock,任务不满足的话用undone
        ShowType = self.LevelGrowthInfo.IsMeetLevel and self.Enum_LevelGrowthItemShowType.Undone or self.Enum_LevelGrowthItemShowType.Lock
    elseif self.LevelGrowthInfo.LevelRewardState == PlayerLevelGrowthModel.Enum_LevelRewardState.CanGetReward then
        ShowType = self.Enum_LevelGrowthItemShowType.Receive
    end
    return ShowType
end

-- 更新进度条显示
function PlayerLevelGrowthItemLogic:UpdateProgressShow()
    if self.LevelGrowthInfo then
        self.View.Progress:SetPercent(self.LevelGrowthInfo.ExpProgress)
        self.View.Image_ProgressBg:SetVisibility(self.LevelGrowthInfo.IsLastLevel and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

-- 更新锁定状态展示
function PlayerLevelGrowthItemLogic:UpdateLockShow()
    if self.LevelGrowthInfo then
        self.View.Switcher_LockState:SetActiveWidget(self.LevelGrowthInfo.IsHasLevelTask and self.View.Special_LockState or self.View.Normal_LockState)
        self.View.RichText_Lock:SetText(StringUtil.Format(self.LevelGrowthInfo.LevelTaskDesc))
        self.View.Text_LockNumber:SetText(self.LevelGrowthInfo.Level)
    end
end


-- 更新待完成状态展示
function PlayerLevelGrowthItemLogic:UpdateUndoneShow()
    if self.LevelGrowthInfo then
        self.View.Switcher_UndoneState:SetActiveWidget(self.LevelGrowthInfo.IsHasLevelTask and self.View.Special_UndoneState or self.View.Normal_UndoneState)
        self.View.RichText_Undone:SetText(StringUtil.Format(self.LevelGrowthInfo.LevelTaskDesc))
        self.View.Text_UndoneNumber:SetText(self.LevelGrowthInfo.Level)
    end
end


-- 更新可领取状态状态展示
function PlayerLevelGrowthItemLogic:UpdateReceiveShow()
    if self.LevelGrowthInfo then
        self.View.RichText_Receive:SetText(StringUtil.Format(self.LevelGrowthInfo.LevelTaskDesc))
        self.View.Text_ReceiveNumber:SetText(self.LevelGrowthInfo.Level)
        if self.View.VXE_GradeProcess_Gift_Loop then
            self.View:VXE_GradeProcess_Gift_Loop()
        end
    end
end

-- 更新已领取状态展示
function PlayerLevelGrowthItemLogic:UpdateReceivedShow()
    if self.LevelGrowthInfo then
        self.View.Switcher_ReceivedState:SetActiveWidget(self.LevelGrowthInfo.IsHasLevelTask and self.View.Special_ReceivedState or self.View.Normal_ReceivedState)
        self.View.RichText_Received:SetText(StringUtil.Format(self.LevelGrowthInfo.LevelTaskDesc))
        self.View.Text_ReceivedNumber:SetText(self.LevelGrowthInfo.Level)
    end
end

--更新奖励展示
function PlayerLevelGrowthItemLogic:UpdateRewardShow()
    local LevelRewardItemIconList = self.LevelGrowthInfo.LevelRewardItemIconList
    for _, SocialTagItem in pairs(self.RewardItemList) do
        if SocialTagItem and SocialTagItem.View then
            SocialTagItem.View:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    local MaxLength = #LevelRewardItemIconList
    for Index, LevelRewardItemIcon in ipairs(LevelRewardItemIconList) do
        local Item = self.RewardItemList[Index]
        if not (Item and CommonUtil.IsValid(Item.View)) then
            local WidgetClass = UE.UClass.Load(CommonItemIconUMGPath)
            local Widget = NewObject(WidgetClass, self.WidgetBase)
            self.View.ItemList_Reward:AddChild(Widget)
            Item = UIHandler.New(self,Widget,CommonItemIcon).ViewInstance
            self.RewardItemList[Index] = Item
        end
        Item.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        Item:UpdateUI(LevelRewardItemIcon)
        Item.View.Padding.Left = Index == 1 and 0 or 30
        Item.View:SetPadding(Item.View.Padding) 
    end
end

-- 领取奖励按钮点击
function PlayerLevelGrowthItemLogic:OnButtonClicked()
    if self.LevelGrowthInfo and self.LevelGrowthInfo.LevelRewardState == PlayerLevelGrowthModel.Enum_LevelRewardState.CanGetReward then
        self.PlayerLevelGrowthCtrl:SendProtoPlayerReceiveLevelRewardReq(self.LevelGrowthInfo.Level)

        ---@type RedDotCtrl
        local RedDotCtrl = MvcEntry:GetCtrl(RedDotCtrl)
        RedDotCtrl:Interact("LevelGrowthRewardItem_", self.LevelGrowthInfo.Level) 
    end
end

-- 领取奖励按钮hover
function PlayerLevelGrowthItemLogic:OnButtonHovered()
    self.View.Switcher_BtnState:SetActiveWidget(self.View.Panel_Hover)
end

-- 领取奖励按钮unhover
function PlayerLevelGrowthItemLogic:OnButtonUnhovered()
    self.View.Switcher_BtnState:SetActiveWidget(self.View.Panel_Normal)
end

-- 领取奖励按钮按下
function PlayerLevelGrowthItemLogic:OnButtonPressed()
    self.View.Switcher_BtnState:SetActiveWidget(self.View.Panel_Click)
end

-- 领取奖励按钮抬起
function PlayerLevelGrowthItemLogic:OnButtonReleased()
    self.View.Switcher_BtnState:SetActiveWidget(self.View.Panel_Normal)
end

return PlayerLevelGrowthItemLogic
