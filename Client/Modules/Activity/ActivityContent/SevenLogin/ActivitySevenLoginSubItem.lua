local ActivityDefine = require("Client.Modules.Activity.ActivityDefine")
--- 视图控制器
local class_name = "ActivitySevenLoginSubItem"
local ActivitySevenLoginSubItem = BaseClass(ActivitySubViewBase, class_name)

function ActivitySevenLoginSubItem:OnInit(Param)
    ActivitySevenLoginSubItem.super.OnInit(self, Param)
    self.BindNodes = {
        {UDelegate = self.View.GUIButton_Weekly.OnClicked, Func = Bind(self, self.OnClicked)},
        {UDelegate = self.View.GUIButton_Weekly.OnHovered, Func = Bind(self, self.OnHovered)},
        {UDelegate = self.View.GUIButton_Weekly.OnUnhovered, Func = Bind(self, self.OnUnhovered)},
    }
    self.Model = MvcEntry:GetModel(ActivityModel)
    ---@type ActivitySubData
    self.SubData = nil
end

function ActivitySevenLoginSubItem:OnShow(Param)
    if not Param or not Param.AcId or not Param.SubId then
        CError("ActivitySevenLogin:OnShow Param is nil")
        return
    end

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
        CError("ActivitySevenLoginSubItem:OnShow SubData is nil SubId:"..Param.SubId)
        return
    end

    self.RewardId = 0
    self.RewardNum = 0
    if self.SubData.Rewards and #self.SubData.Rewards > 0 then
        self.RewardId = self.SubData.Rewards[1].RewardId
        self.RewardNum = self.SubData.Rewards[1].RewardNum
    end

    CommonUtil.SetItemImageShow(self.RewardId, self.View.Image_Icon)
    CommonUtil.SetQualityShow(self.RewardId,{QualityBar = self.View.Image_Quality01})
    CommonUtil.SetQualityShow(self.RewardId,{QualityBar = self.View.Image_Quality02})

    self.View:InitViewShow(StringUtil.FormatSimple("0{0}", Index), self.RewardNum)
    self:RegCommonRedDot()
    self:UpdateLineUI()
    self:UpdateUI()
end

function ActivitySevenLoginSubItem:OnManualShow()
    self.RedDotViewInstance:RefreshNode()
end

function ActivitySevenLoginSubItem:OnHide()
    self.SubData = nil
    self.RewardId = 0
    self.RewardNum = 0
end

function ActivitySevenLoginSubItem:RegCommonRedDot()
    --TODO:通用 红点 控件
    local RedDotKey = "ActivitySubItem_"
    local RedDotSuffix = self.SubData.SubItemId
    if self.RedDotViewInstance == nil then
        if self.View.WBP_RedDotFactory then
            self.RedDotViewInstance = UIHandler.New(self, self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
        end
    else 
        self.RedDotViewInstance:ChangeKey(RedDotKey, RedDotSuffix)
    end  
end

function ActivitySevenLoginSubItem:UpdateLineUI()
    if self.SubData:IsGot() then
        self.View:PlayAnimation(self.View.vx_line_end)
    else
        self.View:PlayAnimation(self.View.vx_line_start)
    end
end

function ActivitySevenLoginSubItem:InteractRedDot()
    if self.RedDotViewInstance and self.SubData:IsGot() then
        self.RedDotViewInstance:Interact()    
    end
end

function ActivitySevenLoginSubItem:OnClicked()
    if not self.SubData then
        return
    end
    self.SubData:DoAccept()
end

function ActivitySevenLoginSubItem:OnHovered()
    if not self.SubData then
        return
    end
    local Params = {
        ItemId = self.RewardId,
        ItemNum = self.RewardNum,
        FocusWidget = self.View.GUIButton_Weekly,
        IsHideBtnOutside = true
    }
    MvcEntry:OpenView(ViewConst.CommonItemTips, Params)
    self.View:VXE_SetHover(self.SubData:GetState(), true)
    self:UpdateLineUI()
end

function ActivitySevenLoginSubItem:OnUnhovered()
    MvcEntry:CloseView(ViewConst.CommonItemTips)
    self.View:VXE_SetHover(self.SubData:GetState(), false)
    self:UpdateLineUI()
end

function ActivitySevenLoginSubItem:OnSubStateChangedNotify()
    CWaring("ActivitySubViewBase:OnStateChangedNotify")
    self:InteractRedDot()
    self:UpdateLineUI()
    self:UpdateUI()
end

function ActivitySevenLoginSubItem:UpdateUI()
    self.View.WidgetSwitcher_State:SetActiveWidgetIndex(self.SubData:GetState())
    self.View.WidgetSwitcher_State_Ex:SetActiveWidgetIndex(self.SubData:GetState())
end

return ActivitySevenLoginSubItem
