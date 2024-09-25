local ActivityDefine = require("Client.Modules.Activity.ActivityDefine")
--- 视图控制器
local class_name = "ActivityThreeDayLoginSubItem"
local ActivityThreeDayLoginSubItem = BaseClass(ActivitySubViewBase, class_name)

ActivityThreeDayLoginSubItem.HoveredType = {
    Hovered = 0,
    Unhovered = 1
}

function ActivityThreeDayLoginSubItem:OnInit(Param)
    ActivityThreeDayLoginSubItem.super.OnInit(self, Param)
    self.MsgList = {
        {Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_SUBITEM_STATE_LIST_NOTIFY, Func = self.UpdateSubitemState },
    }
    self.BindNodes = {
        {UDelegate = self.View.GUIButton_ClickArea.OnClicked, Func = Bind(self, self.OnClicked)},
        {UDelegate = self.View.GUIButton_ClickArea.OnHovered, Func = Bind(self, self.OnHovered)},
        {UDelegate = self.View.GUIButton_ClickArea.OnUnhovered, Func = Bind(self, self.OnUnhovered)},
    }
    self.Model = MvcEntry:GetModel(ActivityModel)
    ---@type ActivitySubData
    self.SubData = nil
end

function ActivityThreeDayLoginSubItem:OnShow(Param)
    if not Param or not Param.AcId or not Param.SubId then
        CError("ActivitySevenLogin:OnShow Param is nil")
        return
    end

    self.View.WBP_CommonSubscript:SetVisibility(UE.ESlateVisibility.Collapsed)

    local Index = Param.Index or 0

    ---@type ActivityData
    local AcData = self.Model:GetData(Param.AcId)
    if not AcData then
        CError("ActivitySevenLogin:OnShow ActivityData is nil ActivityId:"..Param.AcId)
        return
    end

    ---@type ActivitySubData
    self.SubData = AcData:GetSubItemById(Param.SubId)
    if not self.SubData then
        CError("ActivityThreeDayLoginSubItem:OnShow SubData is nil SubId:"..Param.SubId)
        return
    end

    self.RewardId = 0
    self.RewardNum = 0
    if self.SubData.Rewards and #self.SubData.Rewards > 0 then
        self.RewardId = self.SubData.Rewards[1].RewardId
        self.RewardNum = self.SubData.Rewards[1].RewardNum
    end

    CommonUtil.SetItemImageShow(self.RewardId, self.View.WBP_CommonItemVertical.ImageIcon)
    self.View.Text_Day:SetText(StringUtil.FormatText(self.SubData:GetTittle()))

    self:PlayUnHovered()
    self:UpdateUI()
    --item暂时无红点需求,Anim还未对接
    --self:RegCommonRedDot()
    --self:UpdateLineUI()
end

function ActivityThreeDayLoginSubItem:OnSubStateChangedNotify()
    self:UpdateUI()
    self:UpdateSubitemState()
    self:OnActivitySubitemStateChange()
end

function ActivityThreeDayLoginSubItem:UpdateUI()
    local state = self.SubData:GetState()
    self.View.WBP_CommonSubscript:SetVisibility(state == ActivityDefine.ActivitySubState.Not and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.WBP_CommonItemVertical.Img_Bg_Lock:SetVisibility(state == ActivityDefine.ActivitySubState.Not and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.WidgetSwitcher_State:SetActiveWidgetIndex(self.SubData:GetState())
end

-- function ActivityThreeDayLoginSubItem:OnManualShow()
--     self.RedDotViewInstance:RefreshNode()
-- end

function ActivityThreeDayLoginSubItem:OnHide()
    self.SubData = nil
    self.RewardId = 0
    self.RewardNum = 0
end

function ActivityThreeDayLoginSubItem:RegCommonRedDot()
    --TODO:通用 红点 控件
    local RedDotKey = "ActivitySubItem_"
    local RedDotSuffix = self.SubData.SubItemId
    if self.RedDotViewInstance == nil then
        -- if self.View.WBP_RedDotFactory then
        --     self.RedDotViewInstance = UIHandler.New(self, self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
        -- end
    else 
        self.RedDotViewInstance:ChangeKey(RedDotKey, RedDotSuffix)
    end  
end

function ActivityThreeDayLoginSubItem:OnActivitySubitemStateChange()
    if self.SubData == nil then
        return
    end

    --local IsGot = self.SubData:IsGot()
    local state = self.SubData:GetState()
    self:InteractRedDot()
    self:PlayUnHovered()
    self.View.WBP_CommonSubscript:SetVisibility(state == ActivityDefine.ActivitySubState.Not and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.WBP_CommonItemVertical.Img_Bg_Lock:SetVisibility(state == ActivityDefine.ActivitySubState.Not and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function ActivityThreeDayLoginSubItem:UpdateLineUI()
    if IsGot then
        self.View:PlayAnimation(self.View.vx_line_end)
    else
        self.View:PlayAnimation(self.View.vx_line_start)
    end
end

function ActivityThreeDayLoginSubItem:InteractRedDot()
    if self.SubData:IsGot() then
        local RedDotCtrl = MvcEntry:GetCtrl(RedDotCtrl)
        -- RedDotCtrl:Interact("ActivitySubItem_", self.SubData.SubItemId, RedDotModel.Enum_RedDotTriggerType.Click) 
        RedDotCtrl:Interact("ActivitySubItem_", self.SubData.SubItemId) 
    end
end

function ActivityThreeDayLoginSubItem:OnClicked()
    if not self.SubData then
        return
    end
    self.SubData:DoAccept()
end

function ActivityThreeDayLoginSubItem:OnHovered()
    if not self.SubData then
        return
    end

    self:PlayHovered()

    local Params = {
        ItemId = self.RewardId,
        ItemNum = self.RewardNum,
        FocusWidget = self.View.GUIButton_ClickArea,
        IsHideBtnOutside = true
    }
    MvcEntry:OpenView(ViewConst.CommonItemTips, Params)
    -- self.View:VXE_SetHover(self.SubData:GetState(), true)
    -- self:UpdateLineUI()
end

function ActivityThreeDayLoginSubItem:OnUnhovered()
    self:PlayUnHovered()
    MvcEntry:CloseView(ViewConst.CommonItemTips)
    -- self.View:VXE_SetHover(self.SubData:GetState(), false)
    -- self:UpdateLineUI()
end

function ActivityThreeDayLoginSubItem:StopAnimByType(InType)
    if InType == ActivityThreeDayLoginSubItem.HoveredType.Hovered then
        self.View:StopAnimation(self.View.vx_btn_locknormal)
        self.View:StopAnimation(self.View.vx_btn_receivenormal)
        self.View:StopAnimation(self.View.vx_btn_finishnormal)
    else
        self.View:StopAnimation(self.View.vx_btn_lockhover)
        self.View:StopAnimation(self.View.vx_btn_receivehover)
        self.View:StopAnimation(self.View.vx_btn_finishhover)
    end
end


function ActivityThreeDayLoginSubItem:PlayHovered()
    local state = self.SubData:GetState()
    self:StopAnimByType(ActivityThreeDayLoginSubItem.HoveredType.Hovered)
    if state == ActivityDefine.ActivitySubState.Not then
        self.View:PlayAnimation(self.View.vx_btn_lockhover)
    elseif state == ActivityDefine.ActivitySubState.Can then
        self.View:PlayAnimation(self.View.vx_btn_receivehover)
    else
        self.View:PlayAnimation(self.View.vx_btn_finishhover)
    end
end

function ActivityThreeDayLoginSubItem:PlayUnHovered()
    local state = self.SubData:GetState()
    self:StopAnimByType(ActivityThreeDayLoginSubItem.HoveredType.Unhovered)
    if state == ActivityDefine.ActivitySubState.Not then
        self.View:PlayAnimation(self.View.vx_btn_locknormal)
    elseif state == ActivityDefine.ActivitySubState.Can then
        self.View:PlayAnimation(self.View.vx_btn_receivenormal)
    else
        self.View:PlayAnimation(self.View.vx_btn_finishnormal)
    end
end

---修改可领取状态
function ActivityThreeDayLoginSubItem:UpdateSubitemState()
    if self.SubData == nil then
        return
    end
    
    local state = self.SubData:GetState()
    -- if state == ActivityDefine.ActivitySubState.Not then
        
    -- elseif state == ActivityDefine.ActivitySubState.Can then
        
    -- elseif state == ActivityDefine.ActivitySubState.Got then
        
    -- end
    self.View.WidgetSwitcher_State:SetActiveWidgetIndex(state)
    self.View.WBP_CommonSubscript:SetVisibility(state == ActivityDefine.ActivitySubState.Not and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.WBP_CommonItemVertical.Img_Bg_Lock:SetVisibility(state == ActivityDefine.ActivitySubState.Not and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

return ActivityThreeDayLoginSubItem
