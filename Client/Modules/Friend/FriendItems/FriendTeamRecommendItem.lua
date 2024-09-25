--[[
    组队推荐 Item
]]
local class_name = "FriendTeamRecommendItem"
local FriendTeamRecommendItem = BaseClass(nil, class_name)

function FriendTeamRecommendItem:OnInit()
    self.Model = MvcEntry:GetModel(RecommendModel)
    self.BindNodes = {
		{ UDelegate = self.View.GUIButton_Change.OnClicked,				Func = Bind(self,self.OnClick_GUIButton_Change) },
	}

    self.MsgList = {
        {Model = RecommendModel, MsgName = RecommendModel.ON_RECOMMEND_SPECIAL_SHOW_LIST_UPDATED, Func = Bind(self,self.UpdateListShow)},
    }
end

function FriendTeamRecommendItem:OnShow(Param)
    self.Param = Param
    self.InnerItemList = {}
    self:UpdateListShow()
end

function FriendTeamRecommendItem:OnHide()
    self.InnerItemList = {}
end

function FriendTeamRecommendItem:UpdateListShow()
    local RecommendList = self.Model:GetSpecialShowList()
    if not RecommendList or #RecommendList == 0 then
        -- 可能已经没有可展示数据，要等待请求返回
        -- self.View.Content_Panel:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    -- self.View.Content_Panel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local Index = 1
    for _,RecommendData in ipairs(RecommendList) do
        local Item = self.InnerItemList[Index]
        if not (Item and CommonUtil.IsValid(Item.View)) then
            local WidgetClass = UE.UClass.Load('/Game/BluePrints/UMG/OutsideGame/Friend/FriendMain/WBP_Hall_InviteList_PlayerItem.WBP_Hall_InviteList_PlayerItem')
            local Widget = NewObject(WidgetClass, self.WidgetBase)
            self.View.Panel_TeamRecommend:AddChild(Widget)
            -- Widget.Slot.Padding.Bottom = 16
            -- Widget.Slot:SetPadding(Widget.Slot.Padding)
            
            Item = UIHandler.New(self,Widget,require("Client.Modules.Friend.FriendItems.Inner.FriendTeamRecommendItemInner")).ViewInstance
            self.InnerItemList[Index] = Item
        end
        Item.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        Item:UpdateListShow(RecommendData)
        Index = Index + 1
    end
    for I = Index,#self.InnerItemList do
        local Item = self.InnerItemList[I]
        if Item and CommonUtil.IsValid(Item.View) then
            Item.View:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end

    local IsShowLine = self.Param and self.Param.Data and self.Param.Data.IsShowLine
    if self.View.LinePanel then
        self.View.LinePanel:SetVisibility(IsShowLine and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    end
end

function FriendTeamRecommendItem:OnClick_GUIButton_Change()
    if MvcEntry:GetModel(RecommendModel):GetNextSpecialShowRecommendList(true) then
        self:UpdateListShow()
    end
end

return FriendTeamRecommendItem
