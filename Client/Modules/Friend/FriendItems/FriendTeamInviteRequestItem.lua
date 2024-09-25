--[[
    邀请入队Item 逻辑 包括列表，展示，关闭
]]
local class_name = "FriendTeamInviteRequestItem"
local FriendTeamInviteRequestItem = BaseClass(nil, class_name)

function FriendTeamInviteRequestItem:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.GUIButton_Open.OnClicked,				Func = Bind(self,self.OnClick_GUIButton_Open) },
        { UDelegate = self.View.GUIButton_Hide.OnClicked,				Func = Bind(self,self.OnClick_GUIButton_Hide) },
	}
    self.ListOpenState = false
end

function FriendTeamInviteRequestItem:OnShow(Param)
    self.InnerItemList = {}
    self.Param = Param
    self:UpdateListShow()
end

function FriendTeamInviteRequestItem:OnHide()
    self.InnerItemList = {}
    self.View.RequestListBox:ClearChildren()
end

function FriendTeamInviteRequestItem:UpdateListShow()
    -- self.View.LbTitleName:SetText(StringUtil.Format("邀请入队"))
    local RequestList = MvcEntry:GetModel(TeamInviteApplyModel):GetTeamInviteApplyList()
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
            Item = UIHandler.New(self,Widget,require("Client.Modules.Friend.FriendItems.Inner.FriendTeamInviteRequestItemInner"),Param).ViewInstance
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

function FriendTeamInviteRequestItem:DoAnimation(IsOpen)
    for i, Item in ipairs(self.InnerItemList) do
        self:DoOneItemAnimation(Item, IsOpen, i)
    end
end

function FriendTeamInviteRequestItem:DoOneItemAnimation(Item, IsOpen, Index)
    if Item.OnListStateChange then
        Item:OnListStateChange(IsOpen, Index)
    end
end

function FriendTeamInviteRequestItem:OnClick_GUIButton_Open()
    --展开
    self.ListOpenState = true
    self:UpdateListShow()
    self:DoAnimation(true)
end

function FriendTeamInviteRequestItem:OnClick_GUIButton_Hide()
    --隐藏
    self.ListOpenState = false
    self:UpdateListShow()
    self:DoAnimation(false)
end

-- 检测队伍状态
--[[
    Data =  {
        PlayerId = TeamInviteSync.InviterId,
        Info : InviteInfoMsg
    }
]]
function FriendTeamInviteRequestItem:CheckTeamState()
    if not CommonUtil.IsValid(self.View) or not self.RequestList then
        return
    end
    local ReqTeamArgs = {}
    local FriendModel = MvcEntry:GetModel(FriendModel)
    for _,Show in ipairs(self.RequestList) do
        local Data = Show.Vo
        if Data.Info and Data.Info.TeamId and Data.Info.TeamId > 0 then
            local Members = Data.Info.Members
            local HaveFriend = false
            for _,Member in pairs(Members) do
                local State = FriendModel:GetFriendState(Member.PlayerId)
                if State and State == Pb_Enum_PLAYER_STATE.PLAYER_TEAM then
                    HaveFriend = true
                    break
                end
            end
            -- 队伍中如果有好友，队伍信息走好友里的队伍信息更新请求。
            -- 只有全部不是好友的请求，才走队伍Id请求更新队伍信息
            if not HaveFriend then
                ReqTeamArgs[#ReqTeamArgs + 1] = {
                    PlayerId = Data.PlayerId,
                    TeamId = Data.Info.TeamId
                }
            end
        end
        if not self.ListOpenState then
            break
        end
    end
    if #ReqTeamArgs > 0 then
        MvcEntry:GetCtrl(TeamCtrl):QueryMultiTeamInfoReq(ReqTeamArgs)
    end
end


return FriendTeamInviteRequestItem
