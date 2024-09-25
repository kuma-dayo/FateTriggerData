--- 视图控制器：社群关注子项
local class_name = "ActivityCommunitySubItem"
local ActivityCommunitySubItem = BaseClass(ActivitySubViewBase, class_name)

function ActivityCommunitySubItem:OnInit(Param)
    ActivityCommunitySubItem.super.OnInit(self, Param)
    self.BindNodes = {
        {UDelegate = self.View.GUIButton_List.OnHovered, Func = Bind(self, self.OnHovered)},
        {UDelegate = self.View.GUIButton_List.OnUnhovered, Func = Bind(self, self.OnUnhovered)},
    }
    self.Model = MvcEntry:GetModel(ActivityModel)
    ---@type ActivitySubData
    self.Data = nil
    self.SubData = nil
    self.SubIdList = {}
end

function ActivityCommunitySubItem:OnShow(Param)
    if not Param or not Param.AcId or not Param.SubIdList then
        CError("ActivityCommunitySubItem:OnShow Param is nil")
        return
    end

    local RewardIndex = Param.RewardIndex or 1

    ---@type ActivityData
    self.Data = self.Model:GetData(Param.AcId)
    if not self.Data then
        CError("ActivityCommunitySubItem:OnShow ActivityData is nil ActivityId:"..Param.AcId)
        return
    end

    self.SubIdList = Param.SubIdList
    ---@type ActivitySubData
    local SubId = #Param.SubIdList > 0 and Param.SubIdList[1] or 0
    self.SubData = self.Data:GetSubItemById(SubId)
    if not self.SubData then
        CError("ActivityCommunitySubItem:OnShow SubData is nil SubId:"..SubId)
        return
    end

    self.RewardId = 0
    self.RewardNum = 0
    if self.SubData.Rewards and #self.SubData.Rewards >= RewardIndex then
        self.RewardId = self.SubData.Rewards[RewardIndex].RewardId
        self.RewardNum = self.SubData.Rewards[RewardIndex].RewardNum
    end

    CommonUtil.SetItemImageShow(self.RewardId, self.View.Img_Icon)
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,self.RewardId)
    if CfgItem then
        CommonUtil.SetImageColorFromQuality(self.View.Img_Chapter_Quality,CfgItem[Cfg_ItemConfig_P.Quality])
    end
    self.View.Item_Num:SetText(self.RewardNum)
    self:UpdateSubitemState()
end

function ActivityCommunitySubItem:OnManualShow()
end

function ActivityCommunitySubItem:OnHide()
    self.SubData = nil
    self.RewardId = 0
    self.RewardNum = 0
end

---修改可领取状态
function ActivityCommunitySubItem:UpdateSubitemState()
    if self.SubData == nil then
        return
    end
    
    --0.未完成 1.可领取 2.已领取
    self.View:SetIconState(self.SubData:GetState())
end

function ActivityCommunitySubItem:OnHovered()
    if not self.SubData then
        return
    end

    local Params = {
        ItemId = self.RewardId,
        ItemNum = self.RewardNum,
        FocusWidget = self.View.GUIButton_List,
        IsHideBtnOutside = true
    }
    MvcEntry:OpenView(ViewConst.CommonItemTips, Params)
end

function ActivityCommunitySubItem:OnUnhovered()
    MvcEntry:CloseView(ViewConst.CommonItemTips)
end

function ActivityCommunitySubItem:OnSubStateChangedNotify()
    self:UpdateSubitemState()
    self:InteractRedDot()
end

function ActivityCommunitySubItem:InteractRedDot()
    ---@type RedDotCtrl
    local RedDotCtrl = MvcEntry:GetCtrl(RedDotCtrl)
    --一个按钮奖励领取，则将两个按钮的可领取红点取消
    if self.SubData:IsGot() then
        for i, Id in ipairs(self.SubIdList) do
            local vo = self.Data:GetSubItemById(Id)
            RedDotCtrl:Interact("ActivitySubItem_", vo.SubItemId) 
        end
    end
end

return ActivityCommunitySubItem
