--[[
    待定列表Item ：邀请组队/申请入队/队伍合并
]]
local class_name = "TeamInviteItem"
local TeamInviteItem = BaseClass(nil, class_name)

function TeamInviteItem:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.WBP_Common_InviteBtn.GUIButton_Main.OnClicked,	Func = Bind(self,self.OnClicked_GUIButton_Cancel) },
        -- { UDelegate = self.View.GUIButton_Bg.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
        -- { UDelegate = self.View.GUIButton_Cancel.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
        -- { UDelegate = self.View.GUIButton_Bg.OnUnhovered,			Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
        -- { UDelegate = self.View.GUIButton_Cancel.OnUnhovered,			Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
	}

    self.MsgList = {
        {Model = FriendModel, MsgName = FriendModel.ON_PLAYERSTATE_CHANGED, Func = Bind(self,self.OnFriendListUpdated)},
        {Model = UserModel, MsgName = UserModel.ON_QUERY_PLAYER_STATE_RSP, Func = Bind(self,self.OnGetPlayerState)},
        {Model = TeamModel, MsgName = TeamModel.ON_TEAM_LEADER_CHANGED, Func = Bind(self,self.UpdateSwitcherAddShowStatus)},
        {Model = TeamModel, MsgName = TeamModel.ON_GET_OTHER_TEAM_INFO, Func = Bind(self,self.OnGetOtherTeamInfo)},
    }

    self.State2WidgetSwitcherName = {
        [Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE] = "Offline",
        [Pb_Enum_PLAYER_STATE.PLAYER_LOBBY] = "Online",
        [Pb_Enum_PLAYER_STATE.PLAYER_TEAM] = "Online",
        [Pb_Enum_PLAYER_STATE.PLAYER_MATCH] = "Matching",
        [Pb_Enum_PLAYER_STATE.PLAYER_SETTLE] = "Online",
        [Pb_Enum_PLAYER_STATE.PLAYER_BATTLE] = "OnGame",
        [Pb_Enum_PLAYER_STATE.PLAYER_CUSTOMROOM] = "CustomRoom",
    }

    self.SingleHeadCls = nil
    self.TeamHeadCls = {}
    self.CheckPlayerStatusDuration = 1
end

function TeamInviteItem:OnHide()
    -- self:CleanUpdateStateTimer()
    self.QueryStateId = nil
    self.SingleHeadCls = nil
    self.TeamHeadCls = {}
end

--[[
    Param = {
        Data = {
            PlayerId ,
            PlayerName ,
            TypeId : FriendConst.LIST_TYPE_ENUM
            TeamId : -[optional] 处理入队申请需要的参数
            InviterId: -[optional] 处理邀请入队 
            Members: -[optional] 处理队伍合并需要展示队员头像
            LeaderId: -[optional] 处理队伍合并需要展示队长标签
        }
    }
]]
function TeamInviteItem:OnShow(Param)
    self.Param = Param
    self.Vo = self.Param.Data
    -- 处理是单头像还是队伍头像
    self:UpdateSwitcherTeam()
    -- 处理按钮是否展示
    self:UpdateSwitcherAddShowStatus()
    -- 更新玩家状态
    self:UpdateState()
end

function TeamInviteItem:UpdateSwitcherTeam()
    self.IsInTeam = self.Vo.Members and table_leng(self.Vo.Members) > 1
    if self.IsInTeam then
        -- 展示队伍
        self.View.WidgetSwitcher_Team:SetActiveWidget(self.View.Widget_Team)    
        local TeamModel = MvcEntry:GetModel(TeamModel)
        local Index = 1
        for PlayerId,Member in pairs(self.Vo.Members) do
            local ItemWidget = self.View["WBP_CommonHeadIcon_"..Index]
            ItemWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            local Param = {
                PlayerId = Member.PlayerId,
                IsCaptain = Member.PlayerId == self.Vo.LeaderId,
                ClickType = CommonHeadIcon.ClickTypeEnum.None
            }
            if not self.TeamHeadCls[Index] then
                self.TeamHeadCls[Index] = UIHandler.New(self,ItemWidget, CommonHeadIcon,Param).ViewInstance
            else
                self.TeamHeadCls[Index]:UpdateUI(Param) 
            end
            Index = Index + 1
        end
        for I = Index, FriendConst.MAX_TEAM_MEMBER_COUNT do
            local Widget = self.View["WBP_CommonHeadIcon_"..I]
            if Widget then
                Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
            if self.TeamHeadCls[I] then
                self.TeamHeadCls[I]:OnCustomHide()
            end
        end
    else
        self.View.WidgetSwitcher_Team:SetActiveWidget(self.View.Widget_Player)    
        local PlayerNameParam = {
            WidgetBaseOrHandler = self,
            TextBlockName = self.View.LabelPlayerName,
            TextBlockId = self.View.Text_Id,
            PlayerId = self.Vo.PlayerId,
            DefaultStr = self.Vo.PlayerName,
        }
        MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):RegistPlayerNameUpdate(PlayerNameParam)
        -- self.View.LabelPlayerName:SetText(self.Vo.PlayerName)
        -- 更新玩家头像
        local Param = {
            PlayerId = self.Vo.PlayerId,
            ClickType = CommonHeadIcon.ClickTypeEnum.None
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

function TeamInviteItem:UpdateSwitcherAddShowStatus()
    local IsSelfCaptain = MvcEntry:GetModel(TeamModel):IsSelfTeamCaptain(true)
    local LTEnum = FriendConst.LIST_TYPE_ENUM
    local TypeId = self.Vo.TypeId
    if (TypeId == LTEnum.TEAM_INVITE_REQUEST and self.Vo.InviterId ~= MvcEntry:GetModel(UserModel):GetPlayerId() and not IsSelfCaptain) or 
    ((TypeId == LTEnum.TEAM_REQUEST or TypeId == LTEnum.TEAM_MERGE_REQUEST) and not IsSelfCaptain) then
        -- 邀请入队：只有队长和自己可以取消（这里的队长判断无视单人队伍无感化，只有自己的时候也认为自己就是队长）
        -- 申请入队/队伍合并：只有队长可以取消
        -- self.View.Cancel:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.WBP_Common_InviteBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        -- self.View.Cancel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.WBP_Common_InviteBtn:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        -- 这里都是邀请中的状态，只能进行取消操作
        self.View.WBP_Common_InviteBtn.IsBtnInviteState = true
        self.View.WBP_Common_InviteBtn.BtnCanCancel = true
        if self.View.WBP_Common_InviteBtn.VXE_Btn_Inviting_Success then
                self.View.WBP_Common_InviteBtn:VXE_Btn_Inviting_Success()
            end
        end
end

-- PlayerState : Lobby.proto - PlayerState
function TeamInviteItem:UpdateState()
    -- self:CleanUpdateStateTimer()
    self.QueryStateId = nil
    local PlayerState = nil
    if self.IsInTeam then
        -- 展示为队伍的
        local IsAllMemberOffline = MvcEntry:GetModel(TeamModel):CheckIsAllMemberOffline(self.Vo.Members)
        if IsAllMemberOffline then
            -- 全员掉线视为离线
            PlayerState = {Status = Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE}
        else
            -- 选取其中一个在线成员 去查询状态
            local SelectMember = nil
            for _,Member in pairs(self.Vo.Members) do
                if Member.Status ~= Pb_Enum_TEAM_MEMBER_STATUS.CONNECTING and Member.Status ~= Pb_Enum_TEAM_MEMBER_STATUS.OFFLINE then
                    SelectMember = Member
                    break
                end
            end
            if SelectMember then
                self.QueryStateId = SelectMember.PlayerId
            end
        end
    else
        -- 展示为单人的，二级状态不推送，只能轮询
        self.QueryStateId = self.Vo.PlayerId
    end
    
    if self.QueryStateId ~= nil then
        MvcEntry:GetModel(UserModel):GetPlayerState(self.QueryStateId)
        -- self:AddUpdateStateTimer()
        MvcEntry:GetCtrl(PlayerStateQueryCtrl):PushQueryPlayerIdByView(self,self.QueryStateId)
    elseif PlayerState then
        self:UpdateStateWidget(PlayerState,self.Vo.PlayerId)
    end
end

function TeamInviteItem:UpdateStateWidget(PlayerState,PlayerId)
    if not PlayerState then
        return
    end
    local WidgetName = self.State2WidgetSwitcherName[PlayerState.Status]
    if not WidgetName then
        CWaring("TeamInviteItem:UpdateStateWidget Can't Get WidgetName For State: "..PlayerState.Status)
        return
    end
    local StateText  = MvcEntry:GetModel(UserModel):GetPlayerDisplayStateFromPlayerState(PlayerState, PlayerId)
    local ActiveWidget = self.View[WidgetName]
    if ActiveWidget then
        self.View.WidgetSwitcher_State:SetActiveWidget(ActiveWidget)
        if WidgetName ~= "Offline" then
            self.View["Lb"..WidgetName]:SetText(StateText)
        end
    else
        CError("TeamInviteItem:UpdateStateWidget not found ActiveWidget With State:" .. WidgetName)
    end
end

-- function TeamInviteItem:AddUpdateStateTimer()
--     self.CheckStateTimer = self:InsertTimer(self.CheckPlayerStatusDuration, function ()
--         MvcEntry:GetModel(UserModel):GetPlayerState(self.QueryStateId)
--     end,true)
-- end

function TeamInviteItem:CleanUpdateStateTimer()
    if self.CheckStateTimer then
        self:RemoveTimer(self.CheckStateTimer)
    end
    self.CheckStateTimer = nil
end

-- 得到状态查询结果
function TeamInviteItem:OnGetPlayerState(_, Msg)
    local PlayerId = Msg.PlayerId
    if self.QueryStateId and self.QueryStateId == PlayerId then
        self:UpdateStateWidget(Msg.PlayerStateInfo,PlayerId)
    end
end

-- 好友状态变化
function TeamInviteItem:OnFriendListUpdated(_,FriendInfoList)
    for i,Vo in ipairs(FriendInfoList) do
        if self.Vo.PlayerId == Vo.PlayerId then
            self:UpdateStateWidget(Vo.PlayerState,Vo.PlayerId)
            break
        end
    end
end

-- 得到队伍查询结果  - 在 TeamInviteListMdt 中查询
function TeamInviteItem:OnGetOtherTeamInfo(_,TeamInfo)
    if self.Vo.TeamId and self.Vo.TeamId == TeamInfo.TeamId then
        self.Vo.Members = TeamInfo.Members
        self:UpdateSwitcherTeam()
    end
    self.IsInTeam = self.Vo.Members and table_leng(self.Vo.Members) > 1
end

function TeamInviteItem:OnClicked_GUIButton_Cancel()
    local TypeId = self.Vo.TypeId
    local LTEnum = FriendConst.LIST_TYPE_ENUM
    if TypeId == LTEnum.TEAM_REQUEST then
        -- 申请入队，拒绝申请
        local Msg = {
            ApplicantId = self.Vo.PlayerId,
            Reply = Pb_Enum_REPLY_TYPE.REJECT,
            TeamId = self.Vo.TeamId
        }
        MvcEntry:GetCtrl(TeamCtrl):SendTeamApplyReplyReq(Msg)
    elseif TypeId == LTEnum.TEAM_INVITE_REQUEST then
        -- 邀请入队，取消邀请
        local Msg = {
            InviteeId = self.Vo.PlayerId
        }
        MvcEntry:GetCtrl(TeamCtrl):SendTeamInviteCancelReq(Msg)
    elseif TypeId == LTEnum.TEAM_MERGE_REQUEST then
        local TeamModel = MvcEntry:GetModel(TeamModel)
        -- 队伍合并，拒绝申请
        local Msg = {
            MergeSendId = self.Vo.PlayerId,
            Reply = Pb_Enum_REPLY_TYPE.REJECT,
            TargetTeamId = TeamModel:GetTeamId(),
            SourceTeamId = TeamModel:GetTeamId(self.Vo.PlayerId)
        }
        MvcEntry:GetCtrl(TeamCtrl):SendTeamMergeReplyReq(Msg)
    end
end

-- function TeamInviteItem:GUIButton_Bg_OnHovered()
--     self.View.GUIImage_ListBgHover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--     self.View.GUIImage_ListHover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
-- end

-- function TeamInviteItem:GUIButton_Bg_OnUnhovered()
--     self.View.GUIImage_ListBgHover:SetVisibility(UE.ESlateVisibility.Collapsed)
--     self.View.GUIImage_ListHover:SetVisibility(UE.ESlateVisibility.Collapsed)
-- end

return TeamInviteItem
