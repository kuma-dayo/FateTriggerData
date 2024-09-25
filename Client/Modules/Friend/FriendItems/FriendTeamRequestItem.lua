--[[
    申请入队Item 逻辑 包括列表，展示，关闭
]]
local class_name = "FriendTeamRequestItem"
local FriendTeamRequestItem = BaseClass(nil, class_name)

function FriendTeamRequestItem:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.GUIButton_Open.OnClicked,				Func = Bind(self,self.OnClick_GUIButton_Open) },
        { UDelegate = self.View.GUIButton_Hide.OnClicked,				Func = Bind(self,self.OnClick_GUIButton_Hide) },
	}
    self.ListOpenState = false
end

function FriendTeamRequestItem:OnShow(Param)
    self.InnerItemList = {}
    self.Param = Param
    self:UpdateListShow()
end

function FriendTeamRequestItem:OnHide()
    self.View.RequestListBox:ClearChildren()
    self.InnerItemList = {}
end

function FriendTeamRequestItem:UpdateListShow()
    -- self.View.LbTitleName:SetText(StringUtil.Format("申请入队"))
    local RequestList = MvcEntry:GetModel(TeamRequestApplyModel):GetTeamRequestDataList()
    self.RequestList = RequestList
    -- self.View.LbRequestNum:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_5"),#self.RequestList))
    if self.View.OpenHidePanel then
        self.View.OpenHidePanel:SetVisibility(#self.RequestList > 1 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Hidden)
    else
        self.View.OpenHideBtn:SetVisibility(#self.RequestList > 1 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Hidden)
    end
    self.View.OpenHideBtn:SetActiveWidget(self.ListOpenState and self.View.GUIButton_Hide or self.View.GUIButton_Open)

    local ShowList = self.RequestList
    if not self.ListOpenState then
        ShowList = {}
        table.insert(ShowList,self.RequestList[1])
    end

    if self.ListOpenState then
        MvcEntry:GetModel(FriendModel):DispatchType(FriendModel.ON_SHOW_FRIENDVIEW_LIST_BY_ACTION)
    end

    local MoreStateShow = not self.ListOpenState and #self.RequestList > 1
    local ItemIndex = 0
    local zOrder = 99
    for Index,Show in ipairs(ShowList) do
        local Item = self.InnerItemList[Index]
        local Param = {
            Data = Show.Vo,
            MoreIconShow = MoreStateShow,
            ShowCount = Index == 1 and #self.RequestList or 0,
        }
        if not (Item and CommonUtil.IsValid(Item.View)) then
            local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/OutsideGame/Friend/Notice/WBP_MainPanel_TeamOperateItem.WBP_MainPanel_TeamOperateItem")
            local Widget = NewObject(WidgetClass, self.WidgetBase)
            self.View.RequestListBox:AddChild(Widget)
            Widget.Slot:SetAutoSize(true)
            Item = UIHandler.New(self,Widget,require("Client.Modules.Friend.FriendItems.Inner.FriendTeamRequestItemInner"),Param).ViewInstance
            self.InnerItemList[Index] = Item
            Widget.VXV_ListItem_Num = 0
            zOrder = zOrder - Index
            Widget.Slot:SetZOrder(zOrder)
        else
            Item:UpdateUI(Param)
        end

        if self.ListOpenState and Item.OnListStateChange then
            Item:OnListStateChange(true, Index)
        end

        ItemIndex = ItemIndex + 1
    end
    if ItemIndex < #self.InnerItemList then
        for I = ItemIndex+1, #self.InnerItemList do
            if self.InnerItemList[I] and self.ListOpenState then
                self:DoOneItemAnimation(self.InnerItemList[I], false, I)
            end
        end
    end
end

function FriendTeamRequestItem:DoAnimation(IsOpen)
    for i, Item in ipairs(self.InnerItemList) do
        self:DoOneItemAnimation(Item, IsOpen, i)
    end
end

function FriendTeamRequestItem:DoOneItemAnimation(Item, IsOpen, Index)
    if Item.OnListStateChange then
        Item:OnListStateChange(IsOpen, Index)
    end
end

function FriendTeamRequestItem:OnClick_GUIButton_Open()
    --展开
    self.ListOpenState = true
    self:UpdateListShow()
    self:DoAnimation(true)
end

function FriendTeamRequestItem:OnClick_GUIButton_Hide()
    --隐藏
    self.ListOpenState = false
    self:UpdateListShow()
    self:DoAnimation(false)
end


return FriendTeamRequestItem
