local class_name = "FriendTeamRecommendItemInner"
local FriendTeamRecommendItemInner = BaseClass(nil, class_name)

function FriendTeamRecommendItemInner:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.WBP_Common_SocialBtn_More.GUIButton_Main.OnClicked,	Func = Bind(self,self.OnClicked_GUIButton_More) },
        { UDelegate = self.View.WBP_Common_InviteBtn_Add.GUIButton_Main.OnClicked,	Func = Bind(self,self.OnClicked_GUIButton_Add) },
		-- { UDelegate = self.View.GUIButton_More.OnClicked,	Func = Bind(self,self.OnClicked_GUIButton_More) },
        -- { UDelegate = self.View.GUIButton_Add.OnClicked,	Func = Bind(self,self.OnClicked_GUIButton_Add) },
        -- { UDelegate = self.View.GUIButton_Cancel.OnClicked,	Func = Bind(self,self.OnClicked_GUIButton_Cancel) },
        -- { UDelegate = self.View.GUIButton_Bg.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
        -- { UDelegate = self.View.GUIButton_Add.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
        -- { UDelegate = self.View.GUIButton_Cancel.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
        -- { UDelegate = self.View.GUIButton_Bg.OnUnhovered,			Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
        -- { UDelegate = self.View.GUIButton_Add.OnUnhovered,			Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
        -- { UDelegate = self.View.GUIButton_Cancel.OnUnhovered,			Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
	}

    self.State2WidgetSwitcherName = {
        [Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE] = "Offline",
        [Pb_Enum_PLAYER_STATE.PLAYER_LOBBY] = "Online",
        [Pb_Enum_PLAYER_STATE.PLAYER_TEAM] = "Online",
        [Pb_Enum_PLAYER_STATE.PLAYER_CUSTOMROOM] = "CustomRoom",
        [Pb_Enum_PLAYER_STATE.PLAYER_MATCH] = "Matching",
        [Pb_Enum_PLAYER_STATE.PLAYER_BATTLE] = "OnGame",
        [Pb_Enum_PLAYER_STATE.PLAYER_SETTLE] = "OnGame",
    }

    self.RecommendSource2SwitcherName = {
        [Pb_Enum_RECOMMEND_TEAM_SOURCE.RECOMMEND_RECENT_PLAYED] = "Recent", -- 最近共同游玩
    }

    self.MsgList = {
        {Model = TeamInviteModel, MsgName = ListModel.ON_CHANGED, Func = Bind(self,self.OnAddBtnStateChanged)},
        {Model = TeamInviteModel, MsgName = ListModel.ON_DELETED, Func = Bind(self,self.OnAddBtnStateChanged)},
        {Model = TeamInviteModel, MsgName = TeamInviteModel.ON_APPEND_TEAM_INVITE, Func = Bind(self,self.OnAddBtnStateChanged)},
        {Model = TeamRequestModel, MsgName = ListModel.ON_DELETED, Func = Bind(self,self.OnAddBtnStateChanged)},
        {Model = TeamRequestModel, MsgName = TeamRequestModel.ON_APPEND_TEAM_REQUEST, Func = Bind(self,self.OnAddBtnStateChanged)},
        {Model = TeamMergeModel, MsgName = ListModel.ON_DELETED, Func = Bind(self,self.OnAddBtnStateChanged)},
        {Model = TeamMergeModel, MsgName = TeamMergeModel.ON_APPEND_TEAM_MERGE, Func = Bind(self,self.OnAddBtnStateChanged)},
        {Model = TeamModel,MsgName = TeamModel.ON_GET_OTHER_TEAM_INFO, Func = Bind(self,self.OnGetOtherTeamInfo)},
        {Model = UserModel, MsgName = UserModel.ON_QUERY_PLAYER_STATE_RSP, Func = Bind(self,self.OnQueryTeamState)},
        {Model = RecommendModel, MsgName = RecommendModel.ON_PLAYER_STATE_UPDATE, Func = Bind(self,self.OnQueryTeamState)},
    }
    self.RecommendModel = MvcEntry:GetModel(RecommendModel)
end

function FriendTeamRecommendItemInner:OnShow()
    -- TODO '更多'按钮暂时隐藏
    -- self.View.GUIButton_More:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.WBP_Common_SocialBtn_More:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.CurWidgetName = ""
    self.CurStateText = ""
    self.IsOperating = false
    self.CanCancel = false
end

--[[
    message RecommendTeammateInfo
    {
        int64 PlayerId = 1;         // 推荐组队队友PlayerId
        string PlayerName = 2;      // 推荐组队队友名字
        PLAYER_STATE PlayerState = 3; // 玩家状态 -- 不使用
    }
]]
function FriendTeamRecommendItemInner:UpdateListShow(RecommendTeammateInfo)
    if not RecommendTeammateInfo then
        return
    end
    self.RecommendTeammateInfo = DeepCopy(RecommendTeammateInfo)
    self.PlayerId = self.RecommendTeammateInfo.PlayerId
    -- PlayerState以Model记录的为主，会进行状态更新
    self.PlayerState = self.RecommendModel:GetRecommendPlayerState(self.PlayerId)
    if not self.PlayerState then
        CWaring("FriendTeamRecommendItemInner:UpdateListShow State Error ! Id = "..tostring(self.PlayerId))
        return
    end
    self:UpdateShowContent()
end
function FriendTeamRecommendItemInner:OnHide()
    self.RecommendTeammateInfo = nil
    self.SingleHeadCls = nil
    self.TeamHeadCls = {}
end

--[[ 
    更新展示内容
]]
function FriendTeamRecommendItemInner:UpdateShowContent()
    local SourceType = self.RecommendTeammateInfo.RecommendSource
    if self.RecommendSource2SwitcherName[SourceType] then
        self.View.WidgetSwitcher_State_Recommend:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.WidgetSwitcher_State_Recommend:SetActiveWidget(self.View[self.RecommendSource2SwitcherName[SourceType]])
    else
        self.View.WidgetSwitcher_State_Recommend:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self:UpdateShowState()
    -- self.View.WidgetSwitcher_Add:SetVisibility(UE.ESlateVisibility.Visible)
    self.View.WBP_Common_InviteBtn_Add:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:UpdateTeamStatus()
    self:UpdateAddBtnShow(true)
end

-- 更新顶部状态栏展示内容
function FriendTeamRecommendItemInner:UpdateShowState()
    local PlayerState = self.PlayerState
    local WidgetName = self.State2WidgetSwitcherName[PlayerState.Status]
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local StateText  = UserModel:GetPlayerDisplayStateFromPlayerState(PlayerState,self.PlayerId)
    if PlayerState.Status == Pb_Enum_PLAYER_STATE.PLAYER_TEAM then
        local PlayerCnt = MvcEntry:GetModel(TeamModel):GetTeamMemberCount(self.PlayerId)
        if PlayerCnt > 1 then
            StateText = StringUtil.Format("{0} {1}/{2}",StateText, PlayerCnt ,FriendConst.MAX_TEAM_MEMBER_COUNT)
        end
    end
    self:UpdateStateWidget(WidgetName,StateText)    
end

function FriendTeamRecommendItemInner:UpdateStateWidget(WidgetName,StateText)
    if not WidgetName then
        CError("FriendTeamRecommendItemInner:UpdateStateWidget Error")
        return
    end
    if self.CurWidgetName == WidgetName and self.CurStateText == StateText then
        return
    end
    local ActiveWidget = self.View[WidgetName]
    if ActiveWidget then
        self.View.WidgetSwitcher_State:SetActiveWidget(ActiveWidget)
        if WidgetName ~= "Offline" then
            self.View["Lb"..WidgetName]:SetText(StateText)
        end
        self.CurWidgetName = WidgetName
        self.CurStateText = StateText
    else
        CError("FriendTeamRecommendItemInner:UpdateStateWidget not found ActiveWidget With WidgetName:" .. WidgetName)
    end
end

function FriendTeamRecommendItemInner:OnAddBtnStateChanged()
    self:UpdateAddBtnShow()
end

-- 更新添加按钮的展示状态
function FriendTeamRecommendItemInner:UpdateAddBtnShow(IsInit)
    local MyTeamMemberCount = MvcEntry:GetModel(TeamModel):GetTeamMemberCount()
    if MyTeamMemberCount == FriendConst.MAX_TEAM_MEMBER_COUNT then
        -- 玩家自己满队不显示加号
        -- self.View.WidgetSwitcher_Add:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.WBP_Common_InviteBtn_Add:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        -- self.View.WidgetSwitcher_Add:SetVisibility(UE.ESlateVisibility.Visible)
        self.View.WBP_Common_InviteBtn_Add:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        local IsOperating = false
        local CanCancel = false
        local TeamMemberCount = self.TeamInfo and self.TeamInfo.PlayerCnt or 0
        -- 是否邀请中
        local InviteData = MvcEntry:GetModel(TeamInviteModel):GetData(self.PlayerId)
        local IsInInvitingState = self.View.WBP_Common_InviteBtn_Add.IsBtnInviteState

        if TeamMemberCount <= 1 and InviteData ~= nil then
            -- 邀请中
            IsOperating = true 
            local IsSelfCaptain = MvcEntry:GetModel(TeamModel):IsSelfTeamCaptain(true)
            local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
            if IsSelfCaptain or InviteData.Inviter.PlayerId == MyPlayerId then
                CanCancel = true
            end
        else
            local TeamId = MvcEntry:GetModel(TeamModel):GetTeamId(self.PlayerId)
            if TeamId > 0 then
                -- 是否申请入队中
                local IsTeamRequesting = MvcEntry:GetModel(TeamRequestModel):GetData(TeamId) ~= nil
                if not IsTeamRequesting then
                    -- 是否申请合并中
                    local IsTeamMerging = MvcEntry:GetModel(TeamMergeModel):GetData(TeamId) ~= nil
                    if IsTeamMerging then
                        IsOperating = true
                    end
                else
                    IsOperating = true
                end
            end
        end
        -- 给按钮蓝图变量赋值，要在播放动效之前，动效依赖此变量
        self.View.WBP_Common_InviteBtn_Add.IsBtnInviteState = IsOperating
        self.View.WBP_Common_InviteBtn_Add.BtnCanCancel = CanCancel
        if IsOperating then
            -- 进入邀请状态
            if self.View.WBP_Common_InviteBtn_Add.VXE_Btn_Inviting_Success then
                self.View.WBP_Common_InviteBtn_Add:VXE_Btn_Inviting_Success()
            end
        elseif IsInInvitingState then
            if  IsInit then
                if self.View.WBP_Common_InviteBtn_Add.VXE_Btn_Stop_Inviting then
                    self.View.WBP_Common_InviteBtn_Add:VXE_Btn_Stop_Inviting()
                end
            else
                -- 原来在邀请状态，现在非操作中，播放取消邀请
                if self.View.WBP_Common_InviteBtn_Add.VXE_Btn_Invite_Cancel_Success then
                    self.View.WBP_Common_InviteBtn_Add:VXE_Btn_Invite_Cancel_Success()
                end
            end
        end
    
        self.IsOperating = IsOperating
        self.CanCancel = CanCancel
        -- self.View.WidgetSwitcher_Add:SetActiveWidget(IsOperating and (CanCancel and self.View.Cancel or self.View.Adding) or self.View.GUIButton_Add)
    end
end


--[[
    更新当前内容显示 队伍/个人
]]
function FriendTeamRecommendItemInner:UpdateTeamStatus()
    self.TeamInfo = MvcEntry:GetModel(TeamModel):GetOtherTeamInfoByPlayerId(self.PlayerId)
    local IsShowTeam = self.PlayerState.Status > Pb_Enum_PLAYER_STATE.PLAYER_LOBBY and self.TeamInfo ~= nil and self.TeamInfo.PlayerCnt > 1

    local PlayerBaseInfoSyncCtrl = MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl)
    if IsShowTeam then
        --创建队伍展示
        self.View.WidgetSwitcher_Team:SetActiveWidget(self.View.Widget_TeamList)
        local LeaderId = self.TeamInfo.LeaderId
        local Index = 1
        for _,Member in pairs(self.TeamInfo.Members) do
            local Widget = self.View["WBP_Hall_FriedHeadIcon_"..Index]
            if Widget then
                Widget:SetVisibility(UE.ESlateVisibility.Visible)
                --更新玩家名称
                local PlayerNameParam = {
                    WidgetBaseOrHandler = self,
                    TextBlockName = Widget.LabelPlayerName,
                    PlayerId = Member.PlayerId,
                    DefaultStr = Member.PlayerName,
                    IsFormatName = true,
                    IsHideNum = true,
                }
                PlayerBaseInfoSyncCtrl:RegistPlayerNameUpdate(PlayerNameParam)
                -- Widget.LabelPlayerName:SetText(StringUtil.FormatName( Member.PlayerName or ""))
                --更新玩家头像
                local Param = {
                    PlayerId = Member.PlayerId,
                    PlayerName = Member.PlayerName,
                    IsCaptain = Member.PlayerId == LeaderId,
                    CloseAutoCheckFriendShow = true
                }
                self.TeamHeadCls = self.TeamHeadCls or {}
                if not self.TeamHeadCls[Index] then
                    self.TeamHeadCls[Index] = UIHandler.New(self,Widget.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
                else
                    self.TeamHeadCls[Index]:UpdateUI(Param)
                end
                Index = Index + 1
            end
        end
        for I = Index, FriendConst.MAX_TEAM_MEMBER_COUNT do
            local Widget = self.View["WBP_Hall_FriedHeadIcon_"..I]
            if Widget then
                Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
            if self.TeamHeadCls[I] then
                self.TeamHeadCls[I]:OnCustomHide()
            end
        end
    else
        --创建单人展示
        self.View.WidgetSwitcher_Team:SetActiveWidget(self.View.Widget_Player)
        local PlayerNameParam = {
            WidgetBaseOrHandler = self,
            TextBlockName = self.View.LabelPlayerName,
            TextBlockId = self.View.Text_Id,
            PlayerId = self.PlayerId,
            DefaultStr = self.RecommendTeammateInfo.PlayerName,
        }
        PlayerBaseInfoSyncCtrl:RegistPlayerNameUpdate(PlayerNameParam)
        -- self.View.LabelPlayerName:SetText(self.RecommendTeammateInfo.PlayerName)
        --更新玩家头像
        local Param = {
            PlayerId = self.PlayerId,
            PlayerName = self.RecommendTeammateInfo.PlayerName,
            PlayerState = self.PlayerState,
            CloseAutoCheckFriendShow = true
        }
        if not self.SingleHeadCls then
            self.SingleHeadCls = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
        else
            self.SingleHeadCls:UpdateUI(Param)
        end

        if self.TeamHeadCls then
            for _,TeamHeadCls in pairs(self.TeamHeadCls) do
                TeamHeadCls:OnCustomHide()
            end
        end
    end
end

function FriendTeamRecommendItemInner:OnGetOtherTeamInfo(_,TeamInfo)
    if TeamInfo.TargetId ~= self.PlayerId then
        return
    end
    if not self.TeamInfo or self.TeamInfo.TeamId ~= TeamInfo.TeamId or self.TeamInfo.PlayerCnt ~= TeamInfo.PlayerCnt then
        self.TeamInfo = TeamInfo
        self:UpdateTeamStatus()
    end
end

function FriendTeamRecommendItemInner:OnQueryTeamState(_,Msg)
    if Msg.PlayerId ~= self.PlayerId then
        return
    end
    if self.PlayerState.Status ~= Msg.PlayerStateInfo.Status or self.PlayerState.DisplayStatus ~= Msg.PlayerStateInfo.DisplayStatus then
        self.PlayerState = Msg.PlayerStateInfo
        self:UpdateShowState()
        self:UpdateTeamStatus()
    end
end
function FriendTeamRecommendItemInner:OnClicked_GUIButton_More()
end
function FriendTeamRecommendItemInner:OnClicked_GUIButton_Add()
    if not self.IsOperating then
        local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
        if self.TeamInfo and self.TeamInfo.PlayerCnt > 1 then
            local MyTeamPlayerCnt = MvcEntry:GetModel(TeamModel):GetTeamMemberCount()
            if MyTeamPlayerCnt > 1 and MyTeamPlayerCnt + self.TeamInfo.PlayerCnt <= FriendConst.MAX_TEAM_MEMBER_COUNT then
                -- 发起队伍合并
                local Msg = {
                    MergeRecvId = self.PlayerId,
                    MergeInfo = {
                        TargetTeamId = self.TeamInfo.TeamId,
                        Source = EventTrackingModel:GetFriendAddSource(self.PlayerId),
                        ReferSourcePageId = GetLocalTimestamp() .. EventTrackingModel:GetNowViewId()
                    }
                }
                MvcEntry:GetCtrl(TeamCtrl):SendTeamMergeReq(Msg)
            else
                -- 发起申请入队
                local Msg = {
                    RespondentId = self.PlayerId,
                    ApplyInfo = {
                        TeamId = self.TeamInfo.TeamId,
                        Source = EventTrackingModel:GetFriendAddSource(self.PlayerId),
                        ReferSourcePageId = GetLocalTimestamp() .. EventTrackingModel:GetNowViewId()
                    }
                }
                MvcEntry:GetCtrl(TeamCtrl):SendTeamApplyReq(Msg)
            end
        else
            -- 单人 发邀请入队
            MvcEntry:GetCtrl(TeamCtrl):SendTeamInviteReq(self.PlayerId,self.PlayerName,Pb_Enum_TEAM_SOURCE_TYPE.FRIEND_BAR)
        end
    elseif self.CanCancel then
        self:OnClicked_GUIButton_Cancel()
    end
end
function FriendTeamRecommendItemInner:OnClicked_GUIButton_Cancel()
    -- if self.TeamInfo then
    --     -- 只有单人邀请可以取消
    --     return
    -- end
    local Msg  = {
        InviteeId = self.PlayerId
    }
    MvcEntry:GetCtrl(TeamCtrl):SendTeamInviteCancelReq(Msg)
end

-- function FriendTeamRecommendItemInner:GUIButton_Bg_OnHovered()
--     self.View.GUIImage_ListBgHover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--     self.View.GUIImage_ListHover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
-- end

-- function FriendTeamRecommendItemInner:GUIButton_Bg_OnUnhovered()
--     self.View.GUIImage_ListBgHover:SetVisibility(UE.ESlateVisibility.Collapsed)
--     self.View.GUIImage_ListHover:SetVisibility(UE.ESlateVisibility.Collapsed)
-- end

return FriendTeamRecommendItemInner
