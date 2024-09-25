--[[
    好友管理 - 好友列表 - 列表Item
]]
local class_name = "FriendManagerTabFriendListItem"
local FriendManagerTabFriendListItem = BaseClass(nil, class_name)

function FriendManagerTabFriendListItem:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.FriendManageBtn.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnClick_FriendManageBtn) },
		{ UDelegate = self.View.FriendManageBtn.GUIButton_Main.OnHovered,				Func = Bind(self,self.OnHovered_FriendManageBtn) },
		{ UDelegate = self.View.FriendManageBtn.GUIButton_Main.OnUnhovered,				Func = Bind(self,self.OnUnhovered_FriendManageBtn) },
		{ UDelegate = self.View.FriendInviteBtn.GUIButton_Main.OnClicked,				Func = Bind(self,self.OnClick_FriendInviteBtn) },
		{ UDelegate = self.View.FriendInviteBtn.GUIButton_Main.OnHovered,				Func = Bind(self,self.OnHovered_FriendInviteBtn) },
		{ UDelegate = self.View.FriendInviteBtn.GUIButton_Main.OnUnhovered,				Func = Bind(self,self.OnUnhovered_FriendInviteBtn) },
        -- { UDelegate = self.View.GUIButton_Bg.OnHovered,				Func = Bind(self,self.GUIButton_Bg_OnHovered) },
        -- { UDelegate = self.View.GUIButton_Bg.OnUnhovered,			Func = Bind(self,self.GUIButton_Bg_OnUnhovered) },
		-- { UDelegate = self.View.GUIButton_EnableStar.OnClicked,				Func = Bind(self,self.OnClick_GUIButton_ChangeStarFlag,true) },
        -- { UDelegate = self.View.GUIButton_DisableStar.OnClicked,				Func = Bind(self,self.OnClick_GUIButton_ChangeStarFlag,false) },
		{ UDelegate = self.View.Btn_Tag.OnClicked,				Func = Bind(self,self.OnClick_GUIButton_ChangeStarFlag) },
		{ UDelegate = self.View.OnCustomAniTriggered_Log,Func = Bind(self,self.OnCustomAniTriggered_Log)},
		{ UDelegate = self.View.OnCustomAniTriggered_Log1,Func = Bind(self,self.OnCustomAniTriggered_Log1)},
	}

    self.MsgList = {
        {Model = FriendModel, MsgName = FriendModel.ON_INTIMACY_CHANGED, Func = Bind(self,self.OnIntimacyChanged)},
        {Model = FriendOpLogModel, MsgName = FriendOpLogModel.ON_GET_FRIEND_OPLOG, Func = Bind(self,self.OnGetOpLog)},
        {Model = TeamModel, MsgName = TeamModel.ON_GET_OTHER_TEAM_INFO, Func = Bind(self,self.OnGetOtherTeamInfo)},
        {Model = TeamInviteModel, MsgName = ListModel.ON_DELETED, Func = Bind(self,self.OnCancelTeamInvite)},
        {Model = TeamInviteModel, MsgName = TeamInviteModel.ON_APPEND_TEAM_INVITE, Func = Bind(self,self.OnTeamInvite)},
        {Model = UserModel, MsgName = UserModel.ON_QUERY_PLAYER_STATE_RSP, Func = Bind(self,self.OnQueryTeamState)},
    }
    -- 最大展示日志条数
    self.MaxShowLogCount = 10
  
    -- self.View.FriendManageBtn.TextTips:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabFriendListItem_Friendmanagement")))

    self.TextColor = {
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_OFFLINE] = {Hex = "1B2024"},
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_SINGLE] = {Hex = "E48E35"},
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_INTEAM] = {Hex = "FFC74F"},
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_MATCHING] = {Hex = "4C91EF"},
        [FriendConst.PLAYER_STATE_ENUM.PLAYER_GAMING] = {Hex = "86837D"},
    }
    self.MaxContentWidth = self.View.LogContent.Slot:GetSize().X
    self.InitActionLog = {
        [1] = {TextBlock = self.View.GUITextBlock_Log, Pos = self.View.GUITextBlock_Log.Slot:GetPosition()},
        [2] = {TextBlock = self.View.GUITextBlock_Log_1, Pos = self.View.GUITextBlock_Log_1.Slot:GetPosition()},
    }
    self.TickDuration = 2.5
    self.TickDelay = 0.5
    self.AutoTeamCheckTime = 1  -- 定时请求好友队伍状态的间隔时间
end

function FriendManagerTabFriendListItem:OnShow()
    ---@type FriendModel
    self.FriendModel = MvcEntry:GetModel(FriendModel)
    self:StartTickTimer()
end

function FriendManagerTabFriendListItem:OnHide()
    self.FriendModel = nil
    self.ShowLogIndex = 1
    self:StopTicksAndAnimations()
end

function FriendManagerTabFriendListItem:OnCustomShow()
    self:StartTickTimer()
    self:StartTeamQueryTimer()
    self:StartQueryPlayerState()
    self:UpdateOpLog()
end

function FriendManagerTabFriendListItem:OnCustomHide()
    self:StopTicksAndAnimations()
end

function FriendManagerTabFriendListItem:StopTicksAndAnimations()
    self:RemoveTickTimer()
    self:ClearTeamQueryTimer()
    self:StopQueryPlayerState()
    self.View:StopAllAnimations()
    self.DoActionTextBlock = nil
end
--[[
    FriendData.Vo = {
            State = FriendConst.PLAYER_STATE_ENUM
            PlayerState = Pb_Enum_PLAYER_STATE,
            PlayerName ,
            PlayerId ,
            IntimacyValue ,
            StarFlag ,
        }
]]
function FriendManagerTabFriendListItem:UpdateUI(FriendData)
    if not (FriendData and FriendData.Vo) then
        CError("FriendManagerTabFriendListItem FriendData Error!!",true)
        return
    end
    self.FriendData = FriendData.Vo
    -- 玩家名称
    -- self.View.LabelPlayerName:SetText(StringUtil.Format(self.FriendData.PlayerName))
    local PlayerNameParam = {
        WidgetBaseOrHandler = self,
        TextBlockName = self.View.LabelPlayerName,
        TextBlockId = self.View.Text_PlayerNameId,
        PlayerId = self.FriendData.PlayerId,
        DefaultStr = self.FriendData.PlayerName,
        -- IsHideNum = true,
    }
    MvcEntry:GetCtrl(PlayerBaseInfoSyncCtrl):RegistPlayerNameUpdate(PlayerNameParam)
    
    self:UpdateHeadIcon()
    self:UpdateIntimacy()
    self:UpdateStarFlag()
    self:UpdateState()
    self:UpdateOpLog()
    self:UpdateInviteBtn(true)
    self:StartQueryPlayerState()
end

-- 更新玩家头像
function FriendManagerTabFriendListItem:UpdateHeadIcon()
    local Param = {
        PlayerId = self.FriendData.PlayerId,
        PlayerName = self.FriendData.PlayerName,
    }
    if not self.SingleHeadCls then
        self.SingleHeadCls = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
    else
        self.SingleHeadCls:UpdateUI(Param)
    end
end

-- 更新亲密度
function FriendManagerTabFriendListItem:UpdateIntimacy()
    local IntimacyLv,IntimacyIconPath = self.FriendModel:GetIntimacyImgIcon(self.FriendData.IntimacyValue)
    if IntimacyIconPath then
        self.View.GUIImage_Intimacy:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImage_Intimacy,IntimacyIconPath)
    else
        self.View.GUIImage_Intimacy:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

-- 更新星标
function FriendManagerTabFriendListItem:UpdateStarFlag()
    self.IsStarFlag = self.FriendData.StarFlag
    self.View.WidgetSwitcher_Star:SetActiveWidget(self.IsStarFlag and self.View.Select or self.View.Normal)
end

-- 更新玩家状态
function FriendManagerTabFriendListItem:UpdateState()
    local StateText  = MvcEntry:GetModel(UserModel):GetPlayerDisplayStateFromPlayerState(self.FriendData.PlayerState,self.FriendData.PlayerId)
    local IsRealInTeam = false
     if self.FriendData.State == FriendConst.PLAYER_STATE_ENUM.PLAYER_INTEAM then
        local TeamModel = MvcEntry:GetModel(TeamModel)
        if TeamModel:IsInTeam(self.FriendData.PlayerId)  then
            -- 组队中 需要显示队伍人物
            StateText = StringUtil.Format("{0} {1}/{2}",StateText,TeamModel:GetTeamMemberCount(self.FriendData.PlayerId),FriendConst.MAX_TEAM_MEMBER_COUNT)
            IsRealInTeam = true
        end
        self:StartTeamQueryTimer()
    end
    self.View.LabelState:SetText(StringUtil.Format(StateText))
    local ShowState = self.FriendData.State
    if ShowState == FriendConst.PLAYER_STATE_ENUM.PLAYER_INTEAM and not IsRealInTeam then
        ShowState = FriendConst.PLAYER_STATE_ENUM.PLAYER_SINGLE
    end
    local TextColorInfo = self.TextColor[ShowState]
    if TextColorInfo then
        CommonUtil.SetTextColorFromeHex(self.View.LabelState,TextColorInfo.Hex,TextColorInfo.Opacity or 1)
    end
    local IsOffline = ShowState == FriendConst.PLAYER_STATE_ENUM.PLAYER_OFFLINE
    if self.IsOffline ~= IsOffline then
        local TextColor = IsOffline and "#1B2024" or "#C0BCB0"
        CommonUtil.SetRichTextDefaultTextStyleColorFromHex(self.View.GUITextBlock_Log,TextColor)
        CommonUtil.SetRichTextDefaultTextStyleColorFromHex(self.View.GUITextBlock_Log_1,TextColor)
        if IsOffline  then
            -- 底板
            if self.View.VXE_OfflineBtn_Normal then
                self.View:VXE_OfflineBtn_Normal()
            end
            -- 邀请按钮反色
            if self.View.FriendInviteBtn.VXE_Btn_List_Hover then
                self.View.FriendInviteBtn:VXE_Btn_List_Hover()
            end
            -- 管理按钮反色
            if self.View.FriendManageBtn.VXE_Btn_List_Hover then
                self.View.FriendManageBtn:VXE_Btn_List_Hover()
            end
        else
            -- 底板
            if self.View.VXE_OnlineBtn_Normal then
                self.View:VXE_OnlineBtn_Normal()
            end
            -- 邀请按钮正常颜色
            if self.View.FriendInviteBtn.VXE_Btn_List_Unhover then
                self.View.FriendInviteBtn:VXE_Btn_List_Unhover()
            end
            -- 管理按钮正常颜色
            if self.View.FriendManageBtn.VXE_Btn_List_Unhover then
                self.View.FriendManageBtn:VXE_Btn_List_Unhover()
            end
        end
        self.IsOffline = IsOffline
    end
end

-- 更新邀请好友按钮
function FriendManagerTabFriendListItem:UpdateInviteBtn(IsInit)
    local InviteData = MvcEntry:GetModel(TeamInviteModel):GetData(self.FriendData.PlayerId)
    self.IsInviting = InviteData ~= nil
    -- self.View.FriendInviteBtn.TextTips:SetText(StringUtil.Format(self.IsInviting and G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabFriendListItem_Canceltheinvitation") or G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabFriendListItem_Inviteateam")))
    self.InviteTextTips = StringUtil.Format(self.IsInviting and G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabFriendListItem_Canceltheinvitation") or G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabFriendListItem_Inviteateam"))
    local IsInInvitingState = self.View.FriendInviteBtn.IsBtnInviteState
    self.View.FriendInviteBtn.IsBtnInviteState = self.IsInviting
    if self.IsInviting then
        -- 进入邀请状态
        if self.View.FriendInviteBtn.VXE_Btn_Inviting_Success then
            self.View.FriendInviteBtn:VXE_Btn_Inviting_Success()
        end
    elseif IsInInvitingState then
        if  IsInit then
            if self.View.FriendInviteBtn.VXE_Btn_Stop_Inviting then
                self.View.FriendInviteBtn:VXE_Btn_Stop_Inviting()
            end
        else
            -- 原来在邀请状态，现在非操作中，播放取消邀请
            if self.View.FriendInviteBtn.VXE_Btn_Invite_Cancel_Success then
                self.View.FriendInviteBtn:VXE_Btn_Invite_Cancel_Success()
            end
        end
    end
end

-- 收到邀请
function FriendManagerTabFriendListItem:OnTeamInvite(_,InviteListInfo)
    if InviteListInfo and InviteListInfo.Invitee and InviteListInfo.Invitee.PlayerId == self.FriendData.PlayerId then
        self:UpdateInviteBtn()
    end
end

-- 取消邀请
function FriendManagerTabFriendListItem:OnCancelTeamInvite(_,KeyList)
    for _,PlayerId in ipairs(KeyList) do
        if PlayerId == self.FriendData.PlayerId then
            self:UpdateInviteBtn()
            break
        end
    end
end

-- 更新好友操作日志
--[[
    LogList = {
        [1] = {OpTime = 101010101, ShortLogStr = "xxxx", LogStr = "xxxxx"}
    }
]]
function FriendManagerTabFriendListItem:UpdateOpLog()
    self:ResetOpLog()
    self.View.GUITextBlock_Log:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.GUITextBlock_Log_1:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.LogList = MvcEntry:GetModel(FriendOpLogModel):GetOpLogList(self.FriendData.PlayerId)
    if not self.LogList then
        -- 需要请求
        ---@type FriendCtrl
        MvcEntry:GetCtrl(FriendCtrl):SendFriendGetOpLogReq(self.FriendData.PlayerId)
        return
    end
    if #self.LogList == 0 then
        return
    end
    self.ShowLogIndex = 1
    self.View.GUITextBlock_Log:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    self.View.GUITextBlock_Log:SetText(StringUtil.Format(self.LogList[self.ShowLogIndex].ShortLogStr))
    self:CheckCurrentShowLogNeedScroll(self.View.GUITextBlock_Log,1)
    print("FriendManagerTabFriendListItem:UpdateOpLog Count = "..tostring(#self.LogList))
    if #self.LogList > 1 then
        -- 大于一条才开启滚动
        self:PlayLogScroll()
    else
    end
end

function FriendManagerTabFriendListItem:ResetOpLog()
    self.ShowLogIndex = 1
    self.View:StopAnimation(self.View.ScrollLog)
    -- Reset两条TextBlock的Transform，用代码怎么设置都不生效，只能多做一条Animation重置，用魔法打败魔法。（如有其他解决办法请告诉我T_T @chenyishui
    self.View:PlayAnimation(self.View.ResetlLog)
end

function FriendManagerTabFriendListItem:PlayLogScroll()
    self:SetNextLog(self.View.GUITextBlock_Log_1)
    self.View:PlayAnimation(self.View.ScrollLog,0,0)
end

function FriendManagerTabFriendListItem:SetNextLog(TextBlock)
    if not self.LogList then
        return
    end
    TextBlock:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    local NextIndex = self.ShowLogIndex + 1
    if NextIndex > #self.LogList or NextIndex > self.MaxShowLogCount then
        -- 仅滚动最近十条
        NextIndex = 1
    end
    TextBlock:SetText(StringUtil.Format(self.LogList[NextIndex].ShortLogStr))
    self.ShowLogIndex = NextIndex
end

-- GUITextBlock_Log Animation移动结束后下一帧，由蓝图事件触发
function FriendManagerTabFriendListItem:OnCustomAniTriggered_Log()
    self:CheckCurrentShowLogNeedScroll(self.View.GUITextBlock_Log_1,2)
    self:SetNextLog(self.View.GUITextBlock_Log)
end

-- GUITextBlock_Log_1 Animation移动结束后下一帧，由蓝图事件触发
function FriendManagerTabFriendListItem:OnCustomAniTriggered_Log1()
    self:CheckCurrentShowLogNeedScroll(self.View.GUITextBlock_Log,1)
    self:SetNextLog(self.View.GUITextBlock_Log_1)
end

-- 检测TextBlock是否超长，是否需要进行横向移动
function FriendManagerTabFriendListItem:CheckCurrentShowLogNeedScroll(TextBlock,Index)
    local CurPosition = TextBlock.Slot:GetPosition()
    CurPosition.X = self.InitActionLog[Index].Pos.X
    TextBlock.Slot:SetPosition(CurPosition)
    TextBlock:ForceLayoutPrepass()
    local TextBlockWidth = TextBlock:GetDesiredSize().X
    self.DoActionIndex = nil
    if TextBlockWidth > self.MaxContentWidth then
        local DiffWidth = TextBlockWidth - self.MaxContentWidth
        self.DoActionIndex = Index
        self.MoveOffset =  DiffWidth / (self.TickDuration - self.TickDelay)
        self.CurDt = 0
    end
end

function FriendManagerTabFriendListItem:DoTickAction(dt)
    if not (self.DoActionIndex and self.InitActionLog[self.DoActionIndex]) then
        return
    end
    local DoActionTextBlock = self.InitActionLog[self.DoActionIndex].TextBlock
    local InitPosition = self.InitActionLog[self.DoActionIndex].Pos
    if self.CurDt > self.TickDuration then
        local CurPosition = DoActionTextBlock.Slot:GetPosition()
        CurPosition.X = InitPosition.X
        DoActionTextBlock.Slot:SetPosition(CurPosition)
        self.DoActionIndex = nil
        return
    end
    
    if self.CurDt > self.TickDelay then
        local CurPosition = DoActionTextBlock.Slot:GetPosition()
        CurPosition.X = CurPosition.X  - self.MoveOffset * dt
        DoActionTextBlock.Slot:SetPosition(CurPosition)
    end
    self.CurDt = self.CurDt + dt
end

-- 收到日志信息
function FriendManagerTabFriendListItem:OnGetOpLog(_,PlayerId)
    if PlayerId ~= self.FriendData.PlayerId then
        return
    end
    self:UpdateOpLog()
end

-- 收到亲密度更新
function FriendManagerTabFriendListItem:OnIntimacyChanged(_,FriendInfoList)
    local ContainSelf = false
    for _, FriendBaseNode in ipairs(FriendInfoList) do
        local PlayerId = FriendBaseNode.PlayerId
        if PlayerId == self.FriendData.PlayerId then
            self.FriendData.IntimacyValue = FriendBaseNode.IntimacyValue
            ContainSelf = true
            break
        end
    end
    if ContainSelf then
        self:UpdateIntimacy()
    end
end

-- 点击好友管理
function FriendManagerTabFriendListItem:OnClick_FriendManageBtn()
    MvcEntry:OpenView(ViewConst.FriendManagerLog,self.FriendData.PlayerId)
end

-- 点击组队邀请
function FriendManagerTabFriendListItem:OnClick_FriendInviteBtn()
    if self.IsInviting then
        local Msg  = {
            InviteeId = self.FriendData.PlayerId
        }
        MvcEntry:GetCtrl(TeamCtrl):SendTeamInviteCancelReq(Msg)
    else
        MvcEntry:GetCtrl(TeamCtrl):SendTeamInviteReq(self.FriendData.PlayerId,self.FriendData.PlayerName,Pb_Enum_TEAM_SOURCE_TYPE.FRIEND_BAR)
    end
end

-- 点击激活/取消星标
function FriendManagerTabFriendListItem:OnClick_GUIButton_ChangeStarFlag()
    local NewStarFlag = not self.IsStarFlag
    ---@type FriendCtrl
    MvcEntry:GetCtrl(FriendCtrl):SendFriendSetStarReq(self.FriendData.PlayerId,NewStarFlag)
end

function FriendManagerTabFriendListItem:StartTickTimer()
    self.TickTimer = self:InsertTimer(-1, function (dt)
        self:DoTickAction(dt)
    end,true)
end

function FriendManagerTabFriendListItem:RemoveTickTimer()
    if self.TickTimer then
        self:RemoveTimer(self.TickTimer )
        self.TickTimer  = nil
    end
end
----- Hover效果

function FriendManagerTabFriendListItem:OnHovered_FriendManageBtn()
    local Param = {
        ParentWidgetCls = self,
        TipsStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabFriendListItem_Friendmanagement")),
        FocusWidget = self.View.FriendManageBtn,
    }
    MvcEntry:OpenView(ViewConst.CommonHoverTips,Param)
    -- self.View.FriendManageBtn.HoverTips:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    -- self:GUIButton_Bg_OnHovered()
end

function FriendManagerTabFriendListItem:OnUnhovered_FriendManageBtn()
    MvcEntry:CloseView(ViewConst.CommonHoverTips)
    -- self.View.FriendManageBtn.HoverTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self:GUIButton_Bg_OnUnhovered()
end

function FriendManagerTabFriendListItem:OnHovered_FriendInviteBtn()
    local Param = {
        ParentWidgetCls = self,
        TipsStr = self.InviteTextTips or "",
        FocusWidget = self.View.FriendInviteBtn,
    }
    MvcEntry:OpenView(ViewConst.CommonHoverTips,Param)
    -- self.View.FriendInviteBtn.HoverTips:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    -- self:GUIButton_Bg_OnHovered()
end

function FriendManagerTabFriendListItem:OnUnhovered_FriendInviteBtn()
    MvcEntry:CloseView(ViewConst.CommonHoverTips)
    -- self.View.FriendInviteBtn.HoverTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self:GUIButton_Bg_OnUnhovered()
end


-- function FriendManagerTabFriendListItem:GUIButton_Bg_OnHovered()
--     self.View.ListBg_Btn_Switch:SetActiveWidget(self.View.ListBg_Hover)
-- end

-- function FriendManagerTabFriendListItem:GUIButton_Bg_OnUnhovered()
--     self.View.ListBg_Btn_Switch:SetActiveWidget(self.View.ListBg_Normal)
-- end

---------- 轮询队伍
function FriendManagerTabFriendListItem:OnGetOtherTeamInfo(_,TeamInfo)
    if not TeamInfo then
        return
    end
    local Members = TeamInfo.Members
    if TeamInfo.TargetId ~= self.FriendData.PlayerId or not Members[self.FriendData.PlayerId] then
        return
    end
    self:UpdateState()
end
function FriendManagerTabFriendListItem:StartTeamQueryTimer()
    if self.TeamQueryTimer then
        return
    end
    self.TeamQueryTimer = self:InsertTimer(self.AutoTeamCheckTime,function()
        MvcEntry:GetCtrl(TeamCtrl):SendPlayerListTeamInfoReq({[1] = self.FriendData.PlayerId})
    end,true)
end
function FriendManagerTabFriendListItem:ClearTeamQueryTimer()
    if self.TeamQueryTimer then
        self:RemoveTimer(self.TeamQueryTimer)
        self.TeamQueryTimer = nil
    end
end

--------- 轮询状态，仅取二级状态，一级状态走服务器推送
function FriendManagerTabFriendListItem:StartQueryPlayerState()
    if not self.StartQuery then
        MvcEntry:GetCtrl(PlayerStateQueryCtrl):PushQueryPlayerId(self.FriendData.PlayerId)
        self.StartQuery = true
    end
end

function FriendManagerTabFriendListItem:StopQueryPlayerState()
    MvcEntry:GetCtrl(PlayerStateQueryCtrl):DeleteQueryPlayerId(self.FriendData.PlayerId)
    self.StartQuery = false
end

-- 收到玩家状态
function FriendManagerTabFriendListItem:OnQueryTeamState(_,Msg)
    local FriendModel = MvcEntry:GetModel(FriendModel)
    if self.FriendData and self.FriendData.PlayerId == Msg.PlayerId then
        local PlayerStateInfo = Msg.PlayerStateInfo
        self.FriendData.PlayerState = Msg.PlayerStateInfo
        self.FriendData.State = FriendModel:ConvertLobbyState2FriendState(PlayerStateInfo.Status)
        self:UpdateState()
    end
end
return FriendManagerTabFriendListItem
