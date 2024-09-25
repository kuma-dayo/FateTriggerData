local class_name = "FriendListItem"
local FriendListItem = BaseClass(nil, class_name)


function FriendListItem:OnInit()
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
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_OFFLINE] = "Offline",
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_SINGLE] = "Online",
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_INTEAM] = "Online",
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_MATCHING] = "Matching",
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_GAMING] = "OnGame",
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_CUSTOMROOM] = "CustomRoom",
    }

    self.MsgList = {
        {Model = TeamInviteModel, MsgName = ListModel.ON_CHANGED, Func = Bind(self,self.OnAddBtnStateChanged)},
        {Model = TeamInviteModel, MsgName = ListModel.ON_DELETED, Func = Bind(self,self.OnAddBtnStateChanged)},
        {Model = TeamInviteModel, MsgName = TeamInviteModel.ON_APPEND_TEAM_INVITE, Func = Bind(self,self.OnAddBtnStateChanged)},
        {Model = TeamRequestModel, MsgName = ListModel.ON_DELETED, Func = Bind(self,self.OnAddBtnStateChanged)},
        {Model = TeamRequestModel, MsgName = TeamRequestModel.ON_APPEND_TEAM_REQUEST, Func = Bind(self,self.OnAddBtnStateChanged)},
        {Model = TeamMergeModel, MsgName = ListModel.ON_DELETED, Func = Bind(self,self.OnAddBtnStateChanged)},
        {Model = TeamMergeModel, MsgName = TeamMergeModel.ON_APPEND_TEAM_MERGE, Func = Bind(self,self.OnAddBtnStateChanged)},
        -- {Model = TeamModel, MsgName = TeamModel.ON_ADD_TEAM_MEMBER, Func = Bind(self,self.OnAddTeamMember)},
        -- {Model = TeamModel, MsgName = TeamModel.ON_DEL_TEAM_MEMBER, Func = Bind(self,self.OnDelTeamMember)},
        {Model = TeamModel, MsgName = TeamModel.ON_TEAM_LEADER_CHANGED, Func = Bind(self,self.OnTeamLeaderChanged)},
        {Model = UserModel, MsgName = UserModel.ON_QUERY_PLAYER_STATE_RSP, Func = Bind(self,self.OnQueryTeamState)},
    }
end

--[[
    local Param = {
        Data = FriendBaseNode
    }
]]
function FriendListItem:OnShow(Param)
    -- TODO '更多'按钮暂时隐藏
    -- self.View.GUIButton_More:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.WBP_Common_SocialBtn_More:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- 界面可能会更新Data的State，拷贝一份副本，防止直接改到源数据
    self.Vo = DeepCopy(Param.Data)

    self.IsContentDirty = true
    self.CurWidgetName = ""
    self.CurStateText = ""
    self.IsOperating = false
    self.CanCancel = false
end

function FriendListItem:OnHide()
    self.SingleHeadCls = nil
    self.TeamHeadCls = {}
    self.QueryStateMemberId = nil
end

function FriendListItem:UpdateListShow(Param)
    if Param then
        -- 界面可能会更新Data的State，拷贝一份副本，防止直接改到源数据
        self.Vo = DeepCopy(Param.Data)
        self.IsContentDirty = true
    end
    if not self.Vo then return end
    self:UpdateShowContent()
end

--[[ 
    更新展示内容
]]
function FriendListItem:UpdateShowContent()
    local IsInTeam = MvcEntry:GetModel(TeamModel):IsInTeam(self.Vo.PlayerId)   -- 是否展示为队伍状态
    local TeamMemberCount = MvcEntry:GetModel(TeamModel):GetTeamMemberCount(self.Vo.PlayerId)
    if self.IsInTeam == nil or self.IsInTeam ~= IsInTeam or self.TeamMembers == nil or TeamMemberCount ~= self.TeamMemberCount then
        -- 状态变化 或 队伍人数变化
        self.IsContentDirty = true
    end

    if not self.IsContentDirty then
        -- print("--- FriendListItem Update Nothing Changed")
        return
    end
    -- print("--- FriendListItem DoUpdate ---------------")

    self.IsInTeam = IsInTeam
    self.TeamMemberCount = TeamMemberCount
    self.TeamMembers = MvcEntry:GetModel(TeamModel):GetTeamMembers(self.Vo.PlayerId)
   
    self:UpdateShowState()
    self:UpdateAddBtnStatus()
    self:UpdateShowStatus()
    self.IsContentDirty = false
end

-- 更新顶部状态栏展示内容
function FriendListItem:UpdateShowState()
    local WidgetName = self.State2WidgetSwitcherName[self.Vo.State]
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    local StateText  = UserModel:GetPlayerDisplayStateFromPlayerState(self.Vo.PlayerState,self.Vo.PlayerId)
    local IsAllMemberOffline = MvcEntry:GetModel(TeamModel):CheckIsAllMemberOffline(self.TeamMembers)
    -- self:CleanUpdateStateTimer()
    -- MvcEntry:GetCtrl(PlayerStateQueryCtrl):DeleteQueryPlayerId(self.QueryStateMemberId)
    self.QueryStateMemberId = self.Vo.PlayerId    -- 是否需要定时轮询状态
    if self.IsInTeam then
        if self.Vo.State == FriendConst.PLAYER_STATE_ENUM.PLAYER_OFFLINE and not IsAllMemberOffline then
            -- 队伍状态下，当前的ItemVo是属于队伍中某个成员的
            -- 如果此时这个队员离线了，但不是队伍全员离线，则需要取其他在线队员状态作为显示
            local SelectMember = nil
            for _,Member in pairs(self.TeamMembers) do
                if Member.Status ~= Pb_Enum_TEAM_MEMBER_STATUS.CONNECTING and Member.Status ~= Pb_Enum_TEAM_MEMBER_STATUS.OFFLINE then
                    SelectMember = Member
                    break
                end
            end
            if not SelectMember then
                CError("Get Other Team Member State Error; No Online Member")
                print_trackback()
                return
            end
            -- 走状态请求，通过事件触发 OnQueryTeamState 进行状态设置
            self.QueryStateMemberId = SelectMember.PlayerId
            UserModel:GetPlayerState(SelectMember.PlayerId)
        else
            if self.Vo.State == FriendConst.PLAYER_STATE_ENUM.PLAYER_INTEAM and MvcEntry:GetModel(TeamModel):IsInTeam(self.Vo.PlayerId) then
                -- 组队中 需要显示队伍人物
                StateText = StringUtil.Format("{0} {1}/{2}",StateText, MvcEntry:GetModel(TeamModel):GetTeamMemberCount(self.Vo.PlayerId),FriendConst.MAX_TEAM_MEMBER_COUNT)
            end
            self:UpdateStateWidget(WidgetName,StateText)
        end
    else
        -- 单人直接取状态显示
        self:UpdateStateWidget(WidgetName,StateText)    
    end
    if self.QueryStateMemberId ~= nil then
        MvcEntry:GetCtrl(PlayerStateQueryCtrl):PushQueryPlayerIdByView(self,self.QueryStateMemberId)
    end
end

function FriendListItem:UpdateStateWidget(WidgetName,StateText)
    if not WidgetName then
        CError("FriendListItem:UpdateStateWidget Error For State"..tostring(self.Vo.State),true)
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
        CError("FriendListItem:UpdateStateWidget not found ActiveWidget With WidgetName:" .. WidgetName)
    end
end

-- 异步返回的玩家状态
function FriendListItem:OnQueryTeamState(_,Msg)
    local FriendModel = MvcEntry:GetModel(FriendModel)
    if self.QueryStateMemberId and self.QueryStateMemberId == Msg.PlayerId then
        local PlayerStateInfo = Msg.PlayerStateInfo
        self.Vo.PlayerState = Msg.PlayerStateInfo
        self.Vo.State = FriendModel:ConvertLobbyState2FriendState(PlayerStateInfo.Status)
        local WidgetName = self.State2WidgetSwitcherName[self.Vo.State]
        local StateText  = MvcEntry:GetModel(UserModel):GetPlayerDisplayStateFromPlayerState(PlayerStateInfo, self.Vo.PlayerId)
        if self.Vo.State == FriendConst.PLAYER_STATE_ENUM.PLAYER_INTEAM and MvcEntry:GetModel(TeamModel):IsInTeam(self.Vo.PlayerId) then
            -- 组队中 需要显示队伍人物
            StateText = StringUtil.Format("{0} {1}/{2}",StateText,MvcEntry:GetModel(TeamModel):GetTeamMemberCount(self.Vo.PlayerId),FriendConst.MAX_TEAM_MEMBER_COUNT)
        end
        self:UpdateStateWidget(WidgetName,StateText)
    end
end

--[[
    是否展示添加按钮
    - 自己队伍的成员栏 不展示
    - 无法合并队伍的情况 / 满员的情况 不展示
]]
function FriendListItem:UpdateAddBtnStatus()
    local TeamMemberCount = self.TeamMembers and table_leng(self.TeamMembers) or 0
    local IsHideAddBtn = false
    local MyTeamMemberCount = MvcEntry:GetModel(TeamModel):GetTeamMemberCount()
    if MvcEntry:GetModel(TeamModel):IsSelfTeamMember(self.Vo.PlayerId) then
        -- 自己队伍的成员栏 不展示
        IsHideAddBtn = true
    end
    -- 只有双方队伍人数都为2人才能发起合并队伍请求
    local MaxMemberCount = FriendConst.MAX_TEAM_MEMBER_COUNT
    self.IsCanMerge = TeamMemberCount > 1 and MyTeamMemberCount > 1 and  TeamMemberCount + MyTeamMemberCount <= MaxMemberCount
    if (MyTeamMemberCount > 1 and TeamMemberCount > 1 and not self.IsCanMerge)
        or TeamMemberCount ==  MaxMemberCount 
        or MyTeamMemberCount == MaxMemberCount then
        -- 无法合并队伍的情况 / 满员的情况 不展示
        IsHideAddBtn = true
    end
    -- self.View.WidgetSwitcher_Add:SetVisibility(IsHideAddBtn and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible)
    self.View.WBP_Common_InviteBtn_Add:SetVisibility(IsHideAddBtn and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)

    if not IsHideAddBtn then
        self:UpdateAddBtnShow(true)
    end
end

function FriendListItem:OnAddBtnStateChanged()
    self:UpdateAddBtnShow()
end

-- 更新添加按钮的展示状态
function FriendListItem:UpdateAddBtnShow(IsInit)
    -- if self.View.WidgetSwitcher_Add:GetVisibility() == UE.ESlateVisibility.Collapsed then
    if self.View.WBP_Common_InviteBtn_Add:GetVisibility() == UE.ESlateVisibility.Collapsed then
        return
    end
    local IsOperating = false
    local CanCancel = false
    -- 是否邀请中
    local InviteData = MvcEntry:GetModel(TeamInviteModel):GetData(self.Vo.PlayerId)
    local IsInInvitingState = self.View.WBP_Common_InviteBtn_Add.IsBtnInviteState
    local TeamMemberCount = self.TeamMembers and table_leng(self.TeamMembers) or 0

    if TeamMemberCount <= 1 and InviteData ~= nil then
        -- 邀请中
        IsOperating = true 
        local IsSelfCaptain = MvcEntry:GetModel(TeamModel):IsSelfTeamCaptain(true)
        local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
        if IsSelfCaptain or InviteData.Inviter.PlayerId == MyPlayerId then
            CanCancel = true
        end
    else
        local TeamId = MvcEntry:GetModel(TeamModel):GetTeamId(self.Vo.PlayerId)
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
    -- 初始化不需要播放动效
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

--[[
    更新当前内容显示 队伍/个人
]]
function FriendListItem:UpdateShowStatus()
    -- 无感化单人队，人数大于1才展示为队伍
    local IsShowTeam = false
    if self.IsInTeam then
        local IsAllMemberOffline = MvcEntry:GetModel(TeamModel):CheckIsAllMemberOffline(self.TeamMembers)
        if not IsAllMemberOffline then
            IsShowTeam = true
        end
    end
    local PlayerBaseInfoSyncCtrl = MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl)
    if IsShowTeam then
        --创建队伍展示
        self.View.WidgetSwitcher_Team:SetActiveWidget(self.View.Widget_TeamList)
        local LeaderId = MvcEntry:GetModel(TeamModel):GetLeaderId(self.Vo.PlayerId)
        local Index = 1
        for _,Member in pairs(self.TeamMembers) do
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
            PlayerId = self.Vo.PlayerId,
            DefaultStr = self.Vo.PlayerName,
        }
        PlayerBaseInfoSyncCtrl:RegistPlayerNameUpdate(PlayerNameParam)

        -- self.View.LabelPlayerName:SetText(self.Vo.PlayerName)
        --更新玩家头像
        local Param = {
            PlayerId = self.Vo.PlayerId,
            PlayerName = self.Vo.PlayerName,
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


function FriendListItem:OnClicked_GUIButton_More()
    UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendListItem_Functionisnotopen"))
end

--[[
    邀请组队
]]
function FriendListItem:OnClicked_GUIButton_Add()
    if not self.IsOperating then
        local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
        if self.IsInTeam then
            if self.IsCanMerge then
                -- 发起队伍合并
                local Msg = {
                    MergeRecvId = self.Vo.PlayerId,
                    MergeInfo = {
                        TargetTeamId = MvcEntry:GetModel(TeamModel):GetTeamId(self.Vo.PlayerId),
                        Source = EventTrackingModel:GetFriendAddSource(self.Vo.PlayerId),
                        ReferSourcePageId = GetLocalTimestamp() .. EventTrackingModel:GetNowViewId()
                    }
                }
                MvcEntry:GetCtrl(TeamCtrl):SendTeamMergeReq(Msg)
            else
                -- 发起申请入队
                local Msg = {
                    RespondentId = self.Vo.PlayerId,
                    ApplyInfo = {
                        TeamId = MvcEntry:GetModel(TeamModel):GetTeamId(self.Vo.PlayerId),
                        Source = EventTrackingModel:GetFriendAddSource(self.Vo.PlayerId),
                        ReferSourcePageId = GetLocalTimestamp() .. EventTrackingModel:GetNowViewId()
                    }
                }
                MvcEntry:GetCtrl(TeamCtrl):SendTeamApplyReq(Msg)
            end
        else
            -- 单人 发邀请入队
            MvcEntry:GetCtrl(TeamCtrl):SendTeamInviteReq(self.Vo.PlayerId,self.Vo.PlayerName,Pb_Enum_TEAM_SOURCE_TYPE.FRIEND_BAR)
        end
    elseif self.CanCancel then
        self:OnClicked_GUIButton_Cancel()
    end
end

function FriendListItem:OnClicked_GUIButton_Cancel()
    -- if self.IsInTeam then
    --     -- 只有单人邀请可以取消
    --     return
    -- end
    local Msg  = {
        InviteeId = self.Vo.PlayerId
    }
    MvcEntry:GetCtrl(TeamCtrl):SendTeamInviteCancelReq(Msg)
end

-- 新增队员
function FriendListItem:OnAddTeamMember()
    self:UpdateListShow()
    self:UpdateAddBtnStatus()
end

-- 减少队员
function FriendListItem:OnDelTeamMember()
    self:UpdateListShow()
    self:UpdateAddBtnStatus()
end

-- 队长变化
function FriendListItem:OnTeamLeaderChanged()
    if MvcEntry:GetModel(TeamModel):IsSelfTeamMember(self.Vo.PlayerId) then
        self:UpdateShowStatus()
        self:UpdateAddBtnStatus()
    end
end

-- function FriendListItem:GUIButton_Bg_OnHovered()
--     self.View.GUIImage_ListBgHover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--     self.View.GUIImage_ListHover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
-- end

-- function FriendListItem:GUIButton_Bg_OnUnhovered()
--     self.View.GUIImage_ListBgHover:SetVisibility(UE.ESlateVisibility.Collapsed)
--     self.View.GUIImage_ListHover:SetVisibility(UE.ESlateVisibility.Collapsed)
-- end


return FriendListItem
