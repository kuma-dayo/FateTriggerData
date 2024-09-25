--[[
    主界面 - 邀请组队/申请入队/队伍合并申请 通知 
]]

local class_name = "FriendNoticeInviteItem"
local FriendNoticeInviteItem = BaseClass(nil, class_name)

function FriendNoticeInviteItem:OnInit()
    self.MemberHeadIconWidget = {
        self.View.CommonHeadIcon_1,
        self.View.CommonHeadIcon_2,
        self.View.CommonHeadIcon_3,
        self.View.CommonHeadIcon_4,
    }

    self.BindNodes = {
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
        {Model = TeamInviteApplyModel,MsgName = TeamInviteApplyModel.ON_OPERATE_TEAM_INVITE,Func = Bind(self,self.OnTeamInviteListChanged)},
        {Model = TeamMergeApplyModel,MsgName = TeamMergeApplyModel.ON_OPERATE_TEAM_MERGE,Func = Bind(self,self.OnTeamInviteListChanged)},
        {Model = TeamRequestApplyModel,MsgName = TeamRequestApplyModel.ON_OPERATE_TEAM_REQUEST,Func = Bind(self,self.OnTeamInviteListChanged)},
        {Model = TeamModel,MsgName = TeamModel.ON_SELF_QUIT_TEAM,Func = Bind(self,self.DoClose)},
        -- {Model = TeamModel,MsgName = TeamModel.ON_SELF_JOIN_TEAM,Func = Bind(self,self.DoClose)},
        {Model = TeamModel,MsgName = TeamModel.ON_CLEAN_PENDDING_LIST,Func = Bind(self,self.DoClose)},
        {Model = TeamModel,MsgName = TeamModel.ON_GET_OTHER_TEAM_INFO,Func = Bind(self,self.OnGetOtherTeamInfo)},
    }

    self.TitleStr = {
        [FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendNoticeInviteItem_Teaminvitation"),
        [FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendNoticeInviteItem_Applytojointheteam"),
        [FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendNoticeInviteItem_Teammerging"),
    }
    self.SingleHeadIconCls = nil
    self.MemberHeadIconCls = {}
    -- self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBg)
    self.InputFocus = false
end

--由mdt触发调用
--[[
    Param = {
        TypeId = FriendConst.LIST_TYPE_ENUM, 邀请/申请/合并
        Time 
        ItemInfoList = {
            {
                PlayerId: InviterId / ApplicantId / MergeSendId
                TeamId: InviteInfo.TeamId / 0 / MergeInfo.TargetTeamId
                Info: InviteInfoMsg / ApplyInfoMsg / MergeInfoMsg
                AddTime
            }...
        }
    }
]]
function FriendNoticeInviteItem:OnShow(Param)
    if not Param or not Param.ItemInfoList or #Param.ItemInfoList <= 0 then
        CError("FriendNoticeInviteItem:OnShow Param Error",true)
        return
    end
    self.TypeId = Param.TypeId
    local ItemInfoList = Param.ItemInfoList
    self.ShowItemList = self.ShowItemList or {}
    -- 去重处理
    self.ShowKeyList = self.ShowKeyList or {}
    for _,ItemInfo in ipairs(ItemInfoList) do
        local Key = ItemInfo.TeamId > 0 and ItemInfo.TeamId or ItemInfo.PlayerId
        if not self.ShowKeyList[Key] then
            self.ShowItemList[#self.ShowItemList + 1] = ItemInfo
            self.ShowKeyList[Key] = true
        end
    end

    if not self.IsShow then
        self:UpdateNoticeShow()
        self.IsShow = true
    end
    self:UpdateMoreIconShow()
end

function FriendNoticeInviteItem:OnRepeatShow(Param)
    self:OnShow(Param)
end

function FriendNoticeInviteItem:OnHide()
    self.MemberHeadIconCls = {}
    self.SingleHeadIconCls = nil
    self:CleanAutoHideTimer()
end

function FriendNoticeInviteItem:UpdateNoticeShow()
    if not CommonUtil.IsValid(self.View) or not (self.ShowItemList and #self.ShowItemList > 0)  then
        self:DoClose()
        return
    end
    local ItemInfo = self.ShowItemList[1]
    self.View.LbTitle:SetText(StringUtil.Format(self.TitleStr[self.TypeId] or ""))
    local ShowList = {}
    if ItemInfo.Info.Members then
        -- 邀请/合并 有队伍
        ShowList = self:GetShowListByMembers(ItemInfo.Info.Members,ItemInfo.Info.LeaderId)
    else
        -- 申请 只能单人
        local Data = {
            PlayerId = ItemInfo.PlayerId,
            PlayerName = ItemInfo.Info.PlayerName,
            IsCaptain = false
        }
        ShowList[#ShowList + 1] = Data
    end

    self:UpdateShowList(ShowList)
    self:UpdateMoreIconShow()
    self:ScheduleAutoHide()
end

function FriendNoticeInviteItem:GetShowListByMembers(Members,LeaderId)
    local ShowList = {}
    local _PlayerName = ""
    for PlayerId,MemberInfo in pairs(Members) do
        _PlayerName = #Members > 1 and StringUtil.StringTruncationByChar(MemberInfo.PlayerName, "#")[1] or MemberInfo.PlayerName --多人邀请时只保留昵称--story=1004214 --user=郭洪 【社交】账号系统迭代 https://www.tapd.cn/68880148/s/1211315
        local Data = {
            PlayerId = MemberInfo.PlayerId,
            PlayerName = _PlayerName,
            IsCaptain = MemberInfo.PlayerId == LeaderId 
        }
        ShowList[#ShowList + 1] = Data
    end
    return ShowList
end

function FriendNoticeInviteItem:UpdateShowList(ShowList)
    if #ShowList > 1 then
        -- 队伍展示
        self.View.WidgetSwitcher:SetActiveWidget(self.View.Widget_Team)
        self:UpdateMultiInfo(ShowList)
    else
        -- 单人展示
        self.View.WidgetSwitcher:SetActiveWidget(self.View.Widget_Player)
        self:UpdateSingleInfo(ShowList[1])
    end
end

-- 单人状态的信息展示
function FriendNoticeInviteItem:UpdateSingleInfo(Data)
    -- 玩家名称
    local PlayerNameStr,PlayerNameIdStr = StringUtil.SplitPlayerName(Data.PlayerName,true)
    self.View.LbPlayerName:SetText(PlayerNameStr)
    self.View.Text_Id:SetText(PlayerNameIdStr)
    -- 更新头像展示
    local Param = {
        PlayerId = Data.PlayerId,
        IsCaptain = false, -- 单人状态不展示队长了
        ClickType = CommonHeadIcon.ClickTypeEnum.None
        -- IsCaptain = Data.IsCaptain
    }
    if not self.SingleHeadIconCls then
        self.SingleHeadIconCls = UIHandler.New(self,self.View.CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else 
        self.SingleHeadIconCls:UpdateUI(Param)
    end
    -- 更新段位信息
    self:UpdateRankInfo(Data)
end

function FriendNoticeInviteItem:UpdateRankInfo(Data)
    if not Data then
        return
    end
    local RankData = MvcEntry:GetModel(PersonalInfoModel):GetMaxRankDivisionInfo(Data.PlayerId)
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

-- 多人状态的信息展示
function FriendNoticeInviteItem:UpdateMultiInfo(ShowList)
    local Index = 1
    for _,Data in ipairs(ShowList) do
        self:UpdateTeamMemberHead(Index,Data)
        Index = Index + 1
    end
    for I = Index,#self.MemberHeadIconWidget do
        if self.MemberHeadIconWidget[I] then
            self.MemberHeadIconWidget[I]:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

-- 更新队员头像
function FriendNoticeInviteItem:UpdateTeamMemberHead(Index,Data)
    local ItemWidget = self.MemberHeadIconWidget[Index]
    if not ItemWidget then
        print_trackback()
        return
    end
    ItemWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- 更新头像展示
    local Param = {
        PlayerId = Data.PlayerId,
        IsCaptain = Data.IsCaptain,
        ClickType = CommonHeadIcon.ClickTypeEnum.None
    }
    if not  self.MemberHeadIconCls[Index] then
        self.MemberHeadIconCls[Index] = UIHandler.New(self,ItemWidget, CommonHeadIcon,Param).ViewInstance
    else 
        self.MemberHeadIconCls[Index]:UpdateUI(Param)
    end
end

function FriendNoticeInviteItem:UpdateMoreIconShow()
    self.View.NoticeNumber:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_5"),#self.ShowItemList))
    self.View.MoreIcon:SetVisibility(#self.ShowItemList > 1 and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
end

--[[
    提示信息 超时 关闭
]]
function FriendNoticeInviteItem:ScheduleAutoHide()
    self:CleanAutoHideTimer()
    self.AutoHideTimer = Timer.InsertTimer(1,function()
        if self.SecondTick == FriendConst.NOTICE_DURATION then
            self:CleanAutoHideTimer()
		    self:ToNext()
        else
            self.SecondTick = self.SecondTick + 1
            self:CheckNeedQueryTeamInfo()
        end
	end,true)   
end

function FriendNoticeInviteItem:CleanAutoHideTimer()
    self.SecondTick = 0
    if self.AutoHideTimer then
        Timer.RemoveTimer(self.AutoHideTimer)
    end
    self.AutoHideTimer = nil
end

function FriendNoticeInviteItem:OnClick_GUIButton_NO()
    if self.ShowItemList and self.ShowItemList[1] then
        self:OnSendReply(Pb_Enum_REPLY_TYPE.REJECT)
    end
    self:ToNext()
end

function FriendNoticeInviteItem:OnClick_GUIButton_YES()
    if self.ShowItemList and self.ShowItemList[1] then
        self:OnSendReply(Pb_Enum_REPLY_TYPE.ACCEPT)
    end
    self:ToNext()
end

function FriendNoticeInviteItem:OnSendReply(Reply)
    local TYPE_ENUM = FriendConst.LIST_TYPE_ENUM
    if self.TypeId == TYPE_ENUM.TEAM_INVITE_REQUEST then
        self:SendTeamInviteReply(Reply)
    elseif self.TypeId == TYPE_ENUM.TEAM_REQUEST then
        self:SendTeamApplyReply(Reply)
    elseif self.TypeId == TYPE_ENUM.TEAM_MERGE_REQUEST then
        self:SendTeamMergeReply(Reply)
    end
end

-- 回复是否接受邀请组队
function FriendNoticeInviteItem:SendTeamInviteReply(Reply)
    local Msg = {
        InviterId =  self.ShowItemList[1].PlayerId,
        Reply = Reply,
        TeamId = self.ShowItemList[1].TeamId
    }
    MvcEntry:GetCtrl(TeamCtrl):SendTeamInviteReplyReq(Msg)
end

-- 回复是否接受申请入队
function FriendNoticeInviteItem:SendTeamApplyReply(Reply)
    local Msg = {
        ApplicantId =  self.ShowItemList[1].PlayerId,
        Reply = Reply,
        TeamId = self.ShowItemList[1].Info.TeamId
    }
    MvcEntry:GetCtrl(TeamCtrl):SendTeamApplyReplyReq(Msg)
end

-- 回复是否接受队伍合并
function FriendNoticeInviteItem:SendTeamMergeReply(Reply)
    local Msg = {
        MergeSendId =  self.ShowItemList[1].PlayerId,
        Reply = Reply,
        TargetTeamId = self.ShowItemList[1].Info.TargetTeamId,
        SourceTeamId = self.ShowItemList[1].Info.SourceTeamId
    }
    MvcEntry:GetCtrl(TeamCtrl):SendTeamMergeReplyReq(Msg)
end

function FriendNoticeInviteItem:ToNext()
    local ItemInfo = self.ShowItemList[1]
    if not ItemInfo then
        self:DoClose()
        return
    end
    local Key = ItemInfo.TeamId > 0 and ItemInfo.TeamId or ItemInfo.PlayerId
    self.ShowKeyList[Key] = nil
    table.remove(self.ShowItemList,1)
    self:UpdateNoticeShow()
end

function FriendNoticeInviteItem:OnTeamInviteListChanged(_,TargetId)
    if TargetId then
        local Key = self.ShowItemList[1].TeamId > 0 and self.ShowItemList[1].TeamId or self.ShowItemList[1].PlayerId
        if TargetId == Key then
            -- 已操作了同意或拒绝，跳下一个
            self:ToNext()
        else
            local DeleteIndex = 0
            for Index,ItemInfo in ipairs(self.ShowItemList) do
                local Key = ItemInfo.TeamId > 0 and ItemInfo.TeamId or ItemInfo.PlayerId
                if Key == TargetId then
                    DeleteIndex = Index
                    break
                end
            end
            if DeleteIndex > 0 then
                table.remove(self.ShowItemList,DeleteIndex)
                self:UpdateMoreIconShow()
            end
        end
    end
end

--[[
    检测是否需要轮询通知的队伍信息
]]
function FriendNoticeInviteItem:CheckNeedQueryTeamInfo()
    if not CommonUtil.IsValid(self.View) or not (self.ShowItemList and #self.ShowItemList > 0)  then
        self:DoClose()
        return
    end
    if self.TypeId == FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST then
        -- 申请入队只能单人的，不查询了
        return
    end
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.FriendMain) then
        -- 好友面板打开期间，就走面板中的轮询请求，不额外请求了
        return
    end
    
    local ItemInfo = self.ShowItemList[1]
    if ItemInfo.TeamId and ItemInfo.TeamId > 0 then
        local List = {
            [1] = {
                PlayerId = ItemInfo.PlayerId,
                TeamId = ItemInfo.TeamId
            }
        }
        MvcEntry:GetCtrl(TeamCtrl):QueryMultiTeamInfoReq(List)
    end
end

-- 收到队伍查询信息
function FriendNoticeInviteItem:OnGetOtherTeamInfo(_,TeamInfo)
    if not CommonUtil.IsValid(self.View) or not (self.ShowItemList and #self.ShowItemList > 0)  then
        self:DoClose()
        return
    end
    local ItemInfo = self.ShowItemList[1]
    if ItemInfo.TeamId and ItemInfo.TeamId == TeamInfo.TeamId then
        local ShowList = self:GetShowListByMembers(TeamInfo.Members,TeamInfo.LeaderId)
        self:UpdateShowList(ShowList)
    end
end

--关闭界面
function FriendNoticeInviteItem:DoClose()
    self.IsShow = false
    MvcEntry:GetModel(FriendModel):DispatchType(FriendModel.ON_HIDE_HALL_TIPS,self.TypeId)
end

-- function FriendNoticeInviteItem:GUIButton_Bg_OnHovered()
--     self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBgHover)
--     local Color = "1B2024"
--     CommonUtil.SetBrushTintColorFromHex( self.View.NoticeIcon,Color)
--     CommonUtil.SetTextColorFromeHex(self.View.LbTitle,Color)
--     CommonUtil.SetTextColorFromeHex(self.View.NoticeNumber,Color)
-- end

-- function FriendNoticeInviteItem:GUIButton_Bg_OnUnhovered()
--     self.View.ListBg:SetActiveWidget(self.View.GUIImage_ListBg)
--     local Color = "F3ECDC"
--     CommonUtil.SetBrushTintColorFromHex( self.View.NoticeIcon,Color)
--     CommonUtil.SetTextColorFromeHex(self.View.LbTitle,Color)
--     CommonUtil.SetTextColorFromeHex(self.View.NoticeNumber,Color)
-- end

return FriendNoticeInviteItem