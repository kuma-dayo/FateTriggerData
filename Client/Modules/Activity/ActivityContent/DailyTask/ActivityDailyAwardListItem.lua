local ActivityDefine = require("Client.Modules.Activity.ActivityDefine")
--- 视图控制器:每日活动任务ListItem
local class_name = "ActivityDailyAwardListItem"
local ActivityDailyAwardListItem = BaseClass(ActivitySubViewBase, class_name)

function ActivityDailyAwardListItem:OnInit()
    ActivityDailyAwardListItem.super.OnInit(self)
    ---@type ActivitySubData
    self.SubData = nil
    self.Model = MvcEntry:GetModel(ActivityModel)
    self.MsgList = {
        {Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_SUBITEM_STATE_LIST_NOTIFY, Func = self.OnActivitySubItemStateListNotify },
    }
    self.BindNodes = {}
end


function ActivityDailyAwardListItem:OnShow(Param)
    self:SetData(Param)
end

function ActivityDailyAwardListItem:OnHide(Param)
  
end

-- function ActivityDailyAwardListItem:OnManualShow(Param)
--     self:SetData(Param)
-- end

-- function ActivityDailyAwardListItem:OnManualHide(Param)
--     self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
-- end

-- function ActivityDailyAwardListItem:OnShowAvator(Data, IsNotVirtualTrigger) 
-- end

-- function ActivityDailyAwardListItem:OnHideAvator(Data, IsNotVirtualTrigger) 
-- end

-- function ActivityDailyAwardListItem:OnDestroy(Data, IsNotVirtualTrigger)
-- end

function ActivityDailyAwardListItem:OnSubStateChangedNotify()
    self:InteractRedDot()
    self:UpdateSubitemState()
end

function ActivityDailyAwardListItem:SetData(Param)
    Param = Param or {}
    if Param.SubItemId then
        self.ActiveityID = Param.ActiveityID
        ---@type ActivityData
        local Data = self.Model:GetData(Param.ActiveityID)
        self.SubData = Data:GetSubItemById(Param.SubItemId)
    end

    self:UpdateItemUI()
end

function ActivityDailyAwardListItem:UpdateItemUI()
    if self.SubData == nil then
        return
    end

    --TODO:通用 CommonItemIcon 控件
    ---@type UIHandler
    if self.AwardItemHandler == nil then
        self.AwardItemHandler = UIHandler.New(self, self.View, CommonItemIcon)
    end
    ---@type ActivityReward[]
    local Rewards = self.SubData.Rewards
    ---@type ActivityReward
    local FristReward = (Rewards and #(Rewards) > 0) and Rewards[1] or nil
    if FristReward then
        local IconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
            ItemId = FristReward.RewardId,
            ItemNum = FristReward.RewardNum,
            ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.NONE,
            ShowCount = true,
            ClickCallBackFunc = Bind(self, self.ClickCallBackFunc),
            PressCallBackFunc = Bind(self, self.PressCallBackFunc),
            -- HoverScale = 1.15,
            HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
            RedDotKey = "ActivitySubItem_",
            RedDotSuffix = self.SubData.SubItemId,
            RedDotInteractType = CommonConst.RED_DOT_INTERACT_TYPE.NONE
        }
        self.AwardItemHandler.ViewInstance:UpdateUI(IconParam, true)
    end

    --修改可领取状态
    self:UpdateSubitemState()
end

--- 取消红点逻辑
function ActivityDailyAwardListItem:InteractRedDot()
    if self.AwardItemHandler and self.AwardItemHandler:IsValid() and self.SubData:IsGot() then
        ---@type RedDotCtrl
        local RedDotCtrl = MvcEntry:GetCtrl(RedDotCtrl)
        -- RedDotCtrl:Interact("ActivitySubItem_", self.SubData.SubItemId, RedDotModel.Enum_RedDotTriggerType.Click) 
        RedDotCtrl:Interact("ActivitySubItem_", self.SubData.SubItemId) 
    end
end

---领取奖励
function ActivityDailyAwardListItem:ClickCallBackFunc()
     --TODO:领取奖励
    if self.SubData then
        --CError("ActivityDailyAwardListItem:ClickCallBackFunc 点击领取奖励 !!")
        MvcEntry:GetCtrl(ActivityCtrl):TrySendProtoActivityGetPrizeReq(self.ActiveityID, {self.SubData.SubItemId})

        -- if self.SubData:GetState() == ActivityDefine.ActivitySubState.Can then
        --     self:InteractRedDot()
        -- end
    end
end

function ActivityDailyAwardListItem:PressCallBackFunc()
    -- CError("ActivityDailyAwardListItem:PressCallBackFunc 按压回调！！！！")
end

function ActivityDailyAwardListItem:OnActivitySubItemStateListNotify()
    -- CError("ActivityDailyAwardListItem:OnActivitySubItemStateListNotify")
    if not(CommonUtil.IsValid(self.View)) then
        return
    end

    self:UpdateSubitemState()
end

---修改可领取状态
function ActivityDailyAwardListItem:UpdateSubitemState()
    if self.SubData == nil or self.AwardItemHandler == nil then
        return
    end

    local state = self.SubData:GetState()
    if state == ActivityDefine.ActivitySubState.Not then
        if self.AwardItemHandler:IsValid() then
            self.AwardItemHandler.ViewInstance:SetIsGot(false)
            self.AwardItemHandler.ViewInstance:SetIsCanGet(false)
        end
    elseif state == ActivityDefine.ActivitySubState.Can then
        if self.AwardItemHandler:IsValid() then
            -- self.AwardItemHandler.ViewInstance:SetIsGot(false)
            self.AwardItemHandler.ViewInstance:SetIsCanGet(true)
        end
    elseif state == ActivityDefine.ActivitySubState.Got then
        if self.AwardItemHandler:IsValid() then
            self.AwardItemHandler.ViewInstance:SetIsGot(true)
        end
    end
end

return ActivityDailyAwardListItem