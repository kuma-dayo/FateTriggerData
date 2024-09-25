--[[
    申请入队Item 具体列表中每个Item的逻辑
]]
local class_name = "FriendTeamRequestItemInner"
local FriendTeamRequestItemInner = BaseClass(nil, class_name)

function FriendTeamRequestItemInner:OnInit()
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
        { Model = PersonalInfoModel, MsgName = PersonalInfoModel.ON_PLAYER_BASE_INFO_CHANGED_FOR_ID, Func = self.OnPlayerInfoChange},
    }
    self.SingleHeadIconCls = nil
end

--[[
    Param = {
        Data = {
            PlayerId = ApplyListInfo.Applicant.PlayerId,
            Info : ApplyListInfo
        },
        MoreIconShow = MoreStateShow,
        ShowCount: 列表第一个Item要展示标题数量
    }
]]
function FriendTeamRequestItemInner:OnShow(Param)
    self:UpdateUI(Param)
end

function FriendTeamRequestItemInner:OnHide()
    self.SingleHeadIconCls = nil
end

function FriendTeamRequestItemInner:UpdateUI(Param)
    self.Vo = Param.Data
    local PlayerNameParam = {
        WidgetBaseOrHandler = self,
        TextBlockName = self.View.LbPlayerName,
        TextBlockId = self.View.Text_Id,
        PlayerId = self.Vo.PlayerId,
        DefaultStr = self.Vo.Info.Applicant.PlayerName,
    }
    MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):RegistPlayerNameUpdate(PlayerNameParam)
    -- self.View.LbPlayerName:SetText(self.Vo.Info.Applicant.PlayerName)
    
     -- 列表第一个Item要展示标题数量
     self.IsShowTitle = Param.ShowCount and Param.ShowCount > 0
     if self.IsShowTitle then
        self.View.TitleItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.LbTitle:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendTeamRequestItemInner_Applytojointheteam")))
        self.View.NoticeNumber:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_5"),Param.ShowCount))
    else
        self.View.TitleItem:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    --更新MoreIcon是否需要展示
    self.View.MoreIcon:SetVisibility(Param.MoreIconShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

    -- 申请只能是单人的
    self.View.WidgetSwitcher_Team:SetActiveWidget(self.View.Widget_Player)
    --更新玩家头像
    local Param = {
        PlayerId = self.Vo.PlayerId,
        PlayerName = self.Vo.Info.Applicant.PlayerName,
    }
    if not  self.SingleHeadIconCls then
        self.SingleHeadIconCls = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else 
        self.SingleHeadIconCls:UpdateUI(Param)
    end
    -- self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBg)

    -- 更新段位信息
    self:UpdateRankInfo()
end

function FriendTeamRequestItemInner:UpdateRankInfo()
    if not self.Vo then
        return
    end
    local RankData = MvcEntry:GetModel(PersonalInfoModel):GetMaxRankDivisionInfo(self.Vo.PlayerId)
    if not RankData then
        self.View.Image_Rank:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Text_Rank:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    local SeasonRankModel = MvcEntry:GetModel(SeasonRankModel)
    local DivisionIconPath = SeasonRankModel:GetDivisionIconPathByDivisionId(RankData.MaxDivisionId)
    if DivisionIconPath then
        CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_Rank,DivisionIconPath)
        self.View.Image_Rank:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.View.Image_Rank:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    local DivisionText = SeasonRankModel:GetDivisionNameByDivisionId(RankData.MaxDivisionId)
    self.View.Text_Rank:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.Text_Rank:SetText(DivisionText)
end

function FriendTeamRequestItemInner:OnPlayerInfoChange(PlayerId)
    if self.Vo and self.Vo.PlayerId == PlayerId then
        self:UpdateRankInfo()
    end
end

function FriendTeamRequestItemInner:OnListStateChange(IsOpen, Index)
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

function FriendTeamRequestItemInner:OnClick_GUIButton_YES()
    local Msg = {
        ApplicantId = self.Vo.PlayerId,
        Reply = Pb_Enum_REPLY_TYPE.ACCEPT,
        TeamId = self.Vo.Info.TeamId, 
    }
    MvcEntry:GetCtrl(TeamCtrl):SendTeamApplyReplyReq(Msg)
end

function FriendTeamRequestItemInner:OnClick_GUIButton_NO()
    local Msg = {
        ApplicantId = self.Vo.PlayerId,
        Reply = Pb_Enum_REPLY_TYPE.REJECT,
        TeamId = self.Vo.Info.TeamId,
    }
    MvcEntry:GetCtrl(TeamCtrl):SendTeamApplyReplyReq(Msg)
end

-- function FriendTeamRequestItemInner:GUIButton_Bg_OnHovered()
--     self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBgHover)
--     if self.IsShowTitle then
--         local Color = "1B2024"
--         CommonUtil.SetBrushTintColorFromHex( self.View.NoticeIcon,Color)
--         CommonUtil.SetTextColorFromeHex(self.View.LbTitle,Color)
--         CommonUtil.SetTextColorFromeHex(self.View.NoticeNumber,Color)
--     end
-- end

-- function FriendTeamRequestItemInner:GUIButton_Bg_OnUnhovered()
--     self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBg)
--     if self.IsShowTitle then
--         local Color = "F3ECDC"
--         CommonUtil.SetBrushTintColorFromHex( self.View.NoticeIcon,Color)
--         CommonUtil.SetTextColorFromeHex(self.View.LbTitle,Color)
--         CommonUtil.SetTextColorFromeHex(self.View.NoticeNumber,Color)
--     end
-- end


return FriendTeamRequestItemInner
