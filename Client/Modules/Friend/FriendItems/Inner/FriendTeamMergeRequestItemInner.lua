--[[
    申请合并队伍item 具体列表中每个Item的逻辑
]]
local class_name = "FriendTeamMergeRequestItemInner"
local FriendTeamMergeRequestItemInner = BaseClass(nil, class_name)

function FriendTeamMergeRequestItemInner:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.View.WBP_Common_SocialBtn_YES.GUIButton_Main.OnClicked,				    Func = Bind(self,self.OnClick_GUIButton_YES) },
        { UDelegate = self.View.WBP_Common_SocialBtn_NO.GUIButton_Main.OnClicked,				    Func = Bind(self,self.OnClick_GUIButton_NO) },
        -- { UDelegate = self.View.GUIButton_Bg.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
        -- { UDelegate = self.View.GUIButton_YES.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
        -- { UDelegate = self.View.GUIButton_NO.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
        -- { UDelegate = self.View.GUIButton_Bg.OnUnhovered,			Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
        -- { UDelegate = self.View.GUIButton_YES.OnUnhovered,			Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
        -- { UDelegate = self.View.GUIButton_NO.OnUnhovered,			Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
	}

    self.MsgList = {
        {Model = TeamModel,MsgName = TeamModel.ON_GET_OTHER_TEAM_INFO,Func = Bind(self,self.OnGetOtherTeamInfo)},
    }
    self.MemberHeadIconWidget = {}
    self.MemberHeadIconCls = {}
    self.SingleHeadIconCls = nil
end

--[[
    Param = {
        Data =  {
            PlayerId = MergeListInfo.MergeSend.PlayerId,
            Info = MergeListInfo
        },
        MoreIconShow = MoreStateShow,
        ShowCount: 列表第一个Item要展示标题数量
    }
]]
function FriendTeamMergeRequestItemInner:OnShow(Param)
    self:UpdateUI(Param)
end

function FriendTeamMergeRequestItemInner:UpdateUI(Param)
    self.Vo = Param.Data
    -- 列表第一个Item要展示标题数量
    self.IsShowTitle = Param.ShowCount and Param.ShowCount > 0
    if self.IsShowTitle then
        self.View.TitleItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.LbTitle:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendTeamMergeRequestItemInner_Mergeteams")))
        self.View.NoticeNumber:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_5"),Param.ShowCount))
    else
        self.View.TitleItem:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    --更新MoreIcon是否需要展示
    self.View.MoreIcon:SetVisibility(Param.MoreIconShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    -- 他人队伍信息
    local MergeInfo = self.Vo.Info
    if MergeInfo and MergeInfo.Members then
        local Members = MergeInfo.Members
        local LeaderId = MergeInfo.LeaderId or 0
        local CacheTeamInfo = MvcEntry:GetModel(TeamModel):GetTeamInfo(MergeInfo.TeamId)
        if CacheTeamInfo and CacheTeamInfo.Members then
            -- 有请求过队伍信息，更新成缓存的队伍信息
            Members = CacheTeamInfo.Members
            LeaderId = CacheTeamInfo.LeaderId or 0
        end
        self:UpdateShow(Members,LeaderId)
    end
    -- self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBg)
end

function FriendTeamMergeRequestItemInner:UpdateShow(Members, LeaderId)
    if not Members then
        return
    end
    local ShowList = {}
    for PlayerId,MemberInfo in pairs(Members) do
        local Data = {
            PlayerId = MemberInfo.PlayerId,
            PlayerName = MemberInfo.PlayerName,
            IsCaptain = MemberInfo.PlayerId == LeaderId
        }
        ShowList[#ShowList + 1] = Data
    end

    if not ShowList or #ShowList == 0 then
        return
    end
    if #ShowList > 1 then
        -- 队伍
        self.View.WidgetSwitcher_Team:SetActiveWidget(self.View.TeamListBox)
        self:UpdateMultiInfo(ShowList)
    else
        -- 单人
        self.View.WidgetSwitcher_Team:SetActiveWidget(self.View.Widget_Player)
        self:UpdateSingleInfo(ShowList[1])
    end
end

-- 单人状态的信息展示
function FriendTeamMergeRequestItemInner:UpdateSingleInfo(Data)
    --更新玩家名称
    -- self.View.LbPlayerName:SetText(StringUtil.Format( Data.PlayerName or ""))
    local PlayerNameParam = {
        WidgetBaseOrHandler = self,
        TextBlockName = self.View.LbPlayerName,
        TextBlockId = self.View.Text_Id,
        PlayerId = Data.PlayerId,
        DefaultStr = Data.PlayerName,
    }
    MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):RegistPlayerNameUpdate(PlayerNameParam)
    -- 更新头像展示
    local Param = {
        PlayerId = Data.PlayerId,
        PlayerName = Data.PlayerName,
        IsCaptain =  Data.IsCaptain,
    }
    if not  self.SingleHeadIconCls then
        self.SingleHeadIconCls = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else 
        self.SingleHeadIconCls:UpdateUI(Param)
    end
    if self.MemberHeadIconCls then
        for _,MemberHeadIcon in pairs(self.MemberHeadIconCls) do
            MemberHeadIcon:OnCustomHide()
        end
    end
end

-- 多人状态的信息展示
function FriendTeamMergeRequestItemInner:UpdateMultiInfo(ShowList)
    local Index = 1
    for _,Data in ipairs(ShowList) do
        self:UpdateTeamMemberHead(Index,Data)
        Index = Index + 1
    end
    for I = Index,#self.MemberHeadIconWidget do
        if self.MemberHeadIconWidget[I] then
            self.MemberHeadIconWidget[I]:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        if self.MemberHeadIconCls[I] then
            self.MemberHeadIconCls[I]:OnCustomHide()
        end
    end
end

-- 更新队员头像
function FriendTeamMergeRequestItemInner:UpdateTeamMemberHead(Index,Data)
    local ItemWidget = self.MemberHeadIconWidget[Index]
    if not ItemWidget then
        local WidgetClass = UE.UClass.Load("/Game/BluePrints/UMG/OutsideGame/Friend/Common/WBP_Hall_FriedHeadIcon.WBP_Hall_FriedHeadIcon")
        ItemWidget = NewObject(WidgetClass, self.WidgetBase)
        self.View.TeamListBox:AddChild(ItemWidget)
        -- 设置Item的间隔
        ItemWidget:SetRenderScale(UE.FVector2D(0.92,0.92))
        ItemWidget.Slot.Padding.Right = -8
        ItemWidget.Slot:SetPadding(ItemWidget.Slot.Padding)
        self.MemberHeadIconWidget[Index] = ItemWidget
    else
        ItemWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    --更新玩家名称
    -- ItemWidget.LabelPlayerName:SetText(StringUtil.FormatName( Data.PlayerName or ""))
    -- CommonUtil.SetTextColorFromeHex(ItemWidget.LabelPlayerName,"1B2024")
    local PlayerNameParam = {
        WidgetBaseOrHandler = self,
        TextBlockName = ItemWidget.LabelPlayerName,
        PlayerId = Data.PlayerId,
        DefaultStr = Data.PlayerName,
        IsFormatName = true,
        IsHideNum = true,
    }
    MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):RegistPlayerNameUpdate(PlayerNameParam)
    -- 更新头像展示
    local Param = {
        PlayerId = Data.PlayerId,
        PlayerName = Data.PlayerName,
        IsCaptain =  Data.IsCaptain,
        -- ClickType = CommonHeadIcon.ClickTypeEnum.None
    }
    if not  self.MemberHeadIconCls[Index] then
        self.MemberHeadIconCls[Index] = UIHandler.New(self,ItemWidget.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else 
        self.MemberHeadIconCls[Index]:UpdateUI(Param)
    end
end

function FriendTeamMergeRequestItemInner:OnListStateChange(IsOpen, Index)
    if Index == 1 then
        return
    end
    if IsOpen and self.View.VXV_ListItem_Num > 0 then
        return
    end
    self.View.VXV_ListItem_Num = Index - 1
    if IsOpen then
        if self.View.VXE_Hall_Team_InvitedItem_Open then
            self.View:VXE_Hall_Team_InvitedItem_Open()
        end
    else
        if self.View.VXE_Hall_Team_InvitedItem_Close then
            self.View:VXE_Hall_Team_InvitedItem_Close()
        end
    end
end

function FriendTeamMergeRequestItemInner:OnHide()
    for _,Widget in ipairs(self.MemberHeadIconWidget) do
        Widget:RemoveFromParent()
    end
    self.MemberHeadIconWidget = {}
    self.MemberHeadIconCls = {}
    self.SingleHeadIconCls = nil
end

function FriendTeamMergeRequestItemInner:OnClick_GUIButton_YES()
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local Msg = {
        MergeSendId = self.Vo.PlayerId,
        Reply = Pb_Enum_REPLY_TYPE.ACCEPT,
        TargetTeamId = TeamModel:GetTeamId(),
        SourceTeamId = self.Vo.Info.TeamId
    }
    MvcEntry:GetCtrl(TeamCtrl):SendTeamMergeReplyReq(Msg)
end

function FriendTeamMergeRequestItemInner:OnClick_GUIButton_NO()
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local Msg = {
        MergeSendId = self.Vo.PlayerId,
        Reply = Pb_Enum_REPLY_TYPE.REJECT,
        TargetTeamId = TeamModel:GetTeamId(),
        SourceTeamId = self.Vo.Info.TeamId
    }
    MvcEntry:GetCtrl(TeamCtrl):SendTeamMergeReplyReq(Msg)
end

function FriendTeamMergeRequestItemInner:OnGetOtherTeamInfo(_,TeamInfo)
    if TeamInfo and TeamInfo.TeamId  == self.Vo.Info.TeamId then
         -- 更新队伍信息
         self:UpdateShow(TeamInfo.Members, TeamInfo.LeaderId)
    end
 end

-- function FriendTeamMergeRequestItemInner:GUIButton_Bg_OnHovered()
--     self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBgHover)
--     if self.IsShowTitle then
--         local Color = "1B2024"
--         CommonUtil.SetBrushTintColorFromHex( self.View.NoticeIcon,Color)
--         CommonUtil.SetTextColorFromeHex(self.View.LbTitle,Color)
--         CommonUtil.SetTextColorFromeHex(self.View.NoticeNumber,Color)
--     end
-- end

-- function FriendTeamMergeRequestItemInner:GUIButton_Bg_OnUnhovered()
--     self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBg)
--     if self.IsShowTitle then
--         local Color = "F3ECDC"
--         CommonUtil.SetBrushTintColorFromHex( self.View.NoticeIcon,Color)
--         CommonUtil.SetTextColorFromeHex(self.View.LbTitle,Color)
--         CommonUtil.SetTextColorFromeHex(self.View.NoticeNumber,Color)
--     end
-- end


return FriendTeamMergeRequestItemInner
