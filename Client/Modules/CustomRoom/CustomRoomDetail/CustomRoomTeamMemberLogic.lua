--[[
    房间列表Item逻辑
]]
local class_name = "CustomRoomTeamMemberLogic"
local CustomRoomTeamMemberLogic = BaseClass(nil, class_name)


function CustomRoomTeamMemberLogic:OnInit()
    self.TheCustomRommModel = MvcEntry:GetModel(CustomRoomModel)
    self.TheUserModel = MvcEntry:GetModel(UserModel)

    self.BindNodes = 
    {
		{ UDelegate = self.View.Button_Player.OnClicked,Func = Bind(self,self.BtnClick) },
	}
end
function CustomRoomTeamMemberLogic:OnShow(Param)
end

--[[
    local Param = {
        TeamId = TeamId,
        Pos = Pos,
        MemberInfo = MemberInfo,
        TeamType = self.TeamType,
    }
]]
function CustomRoomTeamMemberLogic:SetData(Param)
    if not Param then
        return
    end
    self.Pos = Param.Pos
    self.MemberInfo = Param.MemberInfo
    self.TeamId = Param.TeamId
    self.TeamType = Param.TeamType
    self.Param = Param

    -- local FlatSwitchTargetName = nil
    local NeedSetTextNumberValue = nil
    local NeedShowSwitch = true
    if self.MemberInfo then
        NeedShowSwitch = false

    --暂时不启用这个逻辑
    -- else
    --     local SelfUserId = self.TheUserModel:GetPlayerId()
    --     local SelfTeamId = self.TheCustomRommModel:GetTeamIdByPlayerId(SelfUserId)
    --     if SelfTeamId and SelfTeamId == self.TeamId then
    --         NeedShowSwitch = false
    --     end
    end
    self.IsMaster = false
    self.IsSelf = false
    
    if self.MemberInfo then
        self.View.Panel_Head:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.Panel_Name:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        self.IsMaster = self.TheCustomRommModel:IsMaster(self.MemberInfo.PlayerId)
        self.IsSelf = self.TheUserModel:IsSelf(self.MemberInfo.PlayerId)
        -- if self.TeamType == 1 then
        --     -- FlatSwitchTargetName = "FlagStateNumber"
        --     NeedSetTextNumberValue = self.TeamId .. ""
        -- else
        --     if self.IsMaster then
        --         -- FlatSwitchTargetName = "FlagStateFlag"
        --     else
        --         -- FlatSwitchTargetName = "FlagStateNumber"

        --         NeedSetTextNumberValue = self.Pos .. ""
        --     end
        -- end

        --更新头像
        local Param = {
            PlayerId = self.MemberInfo.PlayerId,
            PlayerName = self.MemberInfo.PlayerName,
            FilterOperateList = {CommonPlayerInfoHoverTipMdt.OperateTypeEnum.Chat},
            CloseAutoCheckFriendShow = true,
        }
        if not self.HeadIconCls then
            self.HeadIconCls = UIHandler.New(self,self.View.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
        else
            self.HeadIconCls:UpdateUI(Param,true)
        end

        --更新玩家名称
        if self.IsSelf then
            self.View.WidgetSwitcher_PlayerName:SetActiveWidget(self.View.LabelPlayerName_My)
            self.View.LabelPlayerName_My:SetText(StringUtil.Format(StringUtil.StringTruncationByChar(self.MemberInfo.PlayerName, "#")[1]))
        else
            self.View.WidgetSwitcher_PlayerName:SetActiveWidget(self.View.LabelPlayerName_Other)
            self.View.LabelPlayerName_Other:SetText(StringUtil.Format(StringUtil.StringTruncationByChar(self.MemberInfo.PlayerName, "#")[1]))
        end
    else
        self.View.Panel_Head:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.Panel_Name:SetVisibility(UE.ESlateVisibility.Collapsed)
        -- FlatSwitchTargetName = "FlagStateNumber"
    end
    NeedSetTextNumberValue = self.Pos .. ""
    if self.TeamType == 1 then
        NeedSetTextNumberValue = self.TeamId .. ""
    end
    --玩家位置序号
    self.View.Text_TeamNumber1:SetText(NeedSetTextNumberValue)
    self.View.Text_TeamNumberMy:SetText(NeedSetTextNumberValue)
    self.View.WidgetSwitcher_Number:SetActiveWidget(not self.IsSelf and self.View.Text_TeamNumber1 or self.View.Text_TeamNumberMy)
    --位置可交换图标
    self.View.Image_Change2:SetVisibility(NeedShowSwitch and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    --房主图标
    self.View.Image_Flag:SetVisibility(self.IsMaster and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)

    self.View:IsPlayerEmpty(self.MemberInfo == nil)
    -- if NeedSetTextNumberValue then
    --     for i=1,3 do
    --         self.View["Text_TeamNumber" .. i]:SetText(NeedSetTextNumberValue)
    --     end
    -- end
    -- if FlatSwitchTargetName then
    --     for i=1,3 do
    --         self.View["WidgetSwitcherFlat" .. i]:SetActiveWidget(self.View[FlatSwitchTargetName .. i])
    --     end
    -- end
    -- for i=1,3 do
    --     self.View["Image_Change" .. i]:SetVisibility(NeedShowSwitch and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    -- end
end

function CustomRoomTeamMemberLogic:OnHide()
end

function CustomRoomTeamMemberLogic:UpdateShow()

end

function CustomRoomTeamMemberLogic:BtnClick()
    CWaring("CustomRoomTeamMemberLogic:BtnClick()")
    if self.MemberInfo then
        return
    end
    --空位置可以跳入
    local SelfUserId = self.TheUserModel:GetPlayerId()
    local SelfTeamId = self.TheCustomRommModel:GetTeamIdByPlayerId(SelfUserId)
    if not SelfTeamId then
        CError("CustomRoomTeamMemberLogic:BtnClick SelfTeamId nil")
        return
    end
    if SelfTeamId == self.TeamId then
        --申请同一队换位置
        -- MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_ChangePosReq(self.TheCustomRommModel:GetCurEnteredRoomId(),self.Pos)
        --不进行任意操作，不允许这么做
    else
        --申请换队伍
        MvcEntry:GetCtrl(CustomRoomCtrl):SendProto_ChangeTeamReq(self.TheCustomRommModel:GetCurEnteredRoomId(),self.TeamId)
    end
end

return CustomRoomTeamMemberLogic
