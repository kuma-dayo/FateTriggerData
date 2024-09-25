--[[
    好友申请Item 具体列表中每个Item的逻辑
]]
local class_name = "FriendRequestItemInner"
local FriendRequestItemInner = BaseClass(nil, class_name)


function FriendRequestItemInner:OnInit()
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
            PlayerName
            PlayerId
            AddTime
        }
        MoreIconShow = MoreStateShow,
        ShowCount: 列表第一个Item要展示标题数量
    }
]]
function FriendRequestItemInner:OnShow(Param)
    self:UpdateUI(Param)
end

function FriendRequestItemInner:OnHide()
    self.SingleHeadIconCls = nil
end

function FriendRequestItemInner:UpdateUI(Param)
    self.Vo = Param.Data
    -- self.View.LbPlayerName:SetText(self.Vo.PlayerName)
    local PlayerNameParam = {
        WidgetBaseOrHandler = self,
        TextBlockName = self.View.LbPlayerName,
        TextBlockId = self.View.Text_Id,
        PlayerId = self.Vo.PlayerId,
        DefaultStr = self.Vo.PlayerName,
    }
    MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):RegistPlayerNameUpdate(PlayerNameParam)


    -- 列表第一个Item要展示标题数量
    self.IsShowTitle = Param.ShowCount and Param.ShowCount > 0
    if self.IsShowTitle then
        self.View.TitleItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.LbTitle:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendRequestItemInner_Friendapplication")))
        self.View.NoticeNumber:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_5"),Param.ShowCount))
    else
        self.View.TitleItem:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    --更新MoreIcon是否需要展示
    self.View.MoreIcon:SetVisibility(Param.MoreIconShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

    --更新玩家头像
    local Param = {
        PlayerId = self.Vo.PlayerId,
        PlayerName = self.Vo.PlayerName,
        CloseAutoCheckFriendShow = true,
        HeadIconId = self.Vo.HeadId
    }
    if not  self.SingleHeadIconCls then
        self.SingleHeadIconCls = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else 
        self.SingleHeadIconCls:UpdateUI(Param)
    end

    -- 更新段位信息
    self:UpdateRankInfo()
    -- self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBg)
end

function FriendRequestItemInner:UpdateRankInfo()
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

function FriendRequestItemInner:OnListStateChange(IsOpen, Index)
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

function FriendRequestItemInner:OnPlayerInfoChange(PlayerId)
    if self.Vo and self.Vo.PlayerId == PlayerId then
        self:UpdateRankInfo()
    end
end

function FriendRequestItemInner:OnClick_GUIButton_YES()
    MvcEntry:GetCtrl(FriendCtrl):SendProto_AddFriendOperateReq(self.Vo.PlayerId,true)
end

function FriendRequestItemInner:OnClick_GUIButton_NO()
    MvcEntry:GetCtrl(FriendCtrl):SendProto_AddFriendOperateReq(self.Vo.PlayerId,false)
end

-- function FriendRequestItemInner:GUIButton_Bg_OnHovered()
--     self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBgHover)
--     if self.IsShowTitle then
--         local Color = "1B2024"
--         CommonUtil.SetBrushTintColorFromHex( self.View.NoticeIcon,Color)
--         CommonUtil.SetTextColorFromeHex(self.View.LbTitle,Color)
--         CommonUtil.SetTextColorFromeHex(self.View.NoticeNumber,Color)
--     end
-- end

-- function FriendRequestItemInner:GUIButton_Bg_OnUnhovered()
--     self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBg)
--     if self.IsShowTitle then
--         local Color = "F3ECDC"
--         CommonUtil.SetBrushTintColorFromHex( self.View.NoticeIcon,Color)
--         CommonUtil.SetTextColorFromeHex(self.View.LbTitle,Color)
--         CommonUtil.SetTextColorFromeHex(self.View.NoticeNumber,Color)
--     end
-- end

return FriendRequestItemInner
