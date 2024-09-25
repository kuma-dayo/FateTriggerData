--[[
    通用的TeamSideBarLogic控件
    队伍侧边栏逻辑展示

    通过控制WBP_TeamSideBar组件 实例好友侧边栏功能
    WBP_TeamSideBar 队员排序自下而上
    自己头像固定在第一位，无论队伍状态如何
]]

local class_name = "TeamSideBarLogic"
TeamSideBarLogic = TeamSideBarLogic or BaseClass(nil, class_name)

TeamSideBarLogic.DIRECTION = {
    HORIZONTAL = 1,
    VERTICAL = 2
}

function TeamSideBarLogic:OnInit()
    self.MemberItemWidget = {
        self.View.WBP_Hall_Invite_HeadBtn_1,
        self.View.WBP_Hall_Invite_HeadBtn_2,
        self.View.WBP_Hall_Invite_HeadBtn_3,
        self.View.WBP_Hall_Invite_HeadBtn_4,
    }
    self.BindNodes = {}
    for Index = 1,#self.MemberItemWidget do
        local ItemWidget = self.MemberItemWidget[Index]
        table.insert(self.BindNodes,{ UDelegate = ItemWidget.GUIButton_Add.OnClicked,Func = Bind(self,self.OnClick_SwitchFriendList,Index) })
        table.insert(self.BindNodes,{ UDelegate = ItemWidget.BtnInviteOne.OnClicked,Func = Bind(self,self.OnClick_OpenRequest,Index) })
        table.insert(self.BindNodes,{ UDelegate = ItemWidget.BtnInviteMore.OnClicked,Func = Bind(self,self.OnClick_OpenRequest,Index) })
    end

    self.MsgList = {
        -- 登录时候可能好友获取的比队伍慢
        {Model = FriendModel, MsgName = FriendModel.ON_FRIEND_LIST_UPDATED,	Func =  Bind(self,self.UpdateShow) },
        -- {Model = FriendModel, MsgName = ListModel.ON_UPDATED, Func = self.UpdateMemberListShow},
        -- {Model = FriendModel, MsgName = ListModel.ON_DELETED, Func = self.UpdateMemberListShow},
        {Model = TeamModel, MsgName = TeamModel.ON_CLEAN_PENDDING_LIST,	Func =  Bind(self,self.UpdateShow) },
        {Model = TeamModel, MsgName = TeamModel.ON_ADD_TEAM_MEMBER,	Func =  Bind(self,self.OnAddTeamMember) },
		{Model = TeamModel, MsgName = TeamModel.ON_DEL_TEAM_MEMBER,	Func =  Bind(self,self.OnDelTeamMember) },
		{Model = TeamModel, MsgName = TeamModel.ON_UPDATE_TEAM_MEMBER,	Func =  Bind(self,self.OnUpdateTeamMember) },
		{Model = TeamModel, MsgName = TeamModel.ON_TEAM_INFO_CHANGED,	Func =  Bind(self,self.OnTeamInfoChanged) },
		{Model = TeamModel, MsgName = TeamModel.ON_TEAM_LEADER_CHANGED,	Func =  Bind(self,self.OnTeamLeaderChanged) },
        -- 邀请入队
        {Model = TeamInviteModel, MsgName = TeamInviteModel.ON_APPEND_TEAM_INVITE, Func = Bind(self,self.OnAppendTeamInvite)},
        {Model = TeamInviteModel, MsgName = ListModel.ON_DELETED, Func = Bind(self,self.OnDeleteTeamInvite)},
        {Model = TeamInviteModel, MsgName = ListModel.ON_CHANGED, Func = Bind(self,self.OnInviteListChanged)},
        -- 申请入队
        {Model = TeamRequestApplyModel, MsgName = TeamRequestApplyModel.ON_APPEND_TEAM_REQUEST, Func = Bind(self,self.OnAppendTeamRequest)},
        {Model = TeamRequestApplyModel, MsgName = ListModel.ON_DELETED, Func = Bind(self,self.OnDeleteTeamRequest)},
        {Model = TeamRequestApplyModel, MsgName = ListModel.ON_CHANGED, Func = Bind(self,self.OnInviteListChanged)},
        -- 队伍合并
        {Model = TeamMergeApplyModel, MsgName = TeamMergeApplyModel.ON_APPEND_TEAM_MERGE, Func = Bind(self,self.OnAppendTeamMerge)},
        {Model = TeamMergeApplyModel, MsgName = ListModel.ON_DELETED, Func = Bind(self,self.OnDeleteTeamMerge)},
        {Model = TeamMergeApplyModel, MsgName = ListModel.ON_CHANGED, Func = Bind(self,self.OnInviteListChanged)},

        -- 小队聊天提示
        {Model = ChatModel, MsgName = ChatModel.ON_RECEIVE_TEAM_MEMBER_MSG, Func = Bind(self,self.OnReceiveNewMsg)},
        {Model = ChatModel, MsgName = ChatModel.ON_OPEN_CHAT_MDT, Func = Bind(self,self.OnOpenChatMdt)},
    }
    self.CommonHeadIconCls = {}
end

--[[
    Param结构参考：
    {
        -- 侧边栏的方向，默认为横向
        Direction
        --侧边栏每个队员Widget的缩放值  默认值为1
        Scale 
        --侧边栏每个队员之间的间隔   默认值为-10
        Padding
        -- --隐藏按钮点击
        -- HideBtnClick

        --是否隐藏自己的头像，默认为false
        IsHideSelf
    }
]]
function TeamSideBarLogic:OnShow(Param)
    self:UpdateUI(Param)
end

function TeamSideBarLogic:UpdateUI(Param)
	self.Param = Param
    if not self.Param then
        return
    end
    local Direction = self.Param.Direction or TeamSideBarLogic.DIRECTION.HORIZONTAL
    local IsVertical = Direction == TeamSideBarLogic.DIRECTION.VERTICAL
    -- 调整排列方向
    if IsVertical and IsVertical ~= self.IsVertical  then
        local ChildrenCount = self.View.HorizontalBox:GetChildrenCount()
        if ChildrenCount > 0 then
            for i = ChildrenCount - 1,0,-1 do
                local Child = self.View.HorizontalBox:GetChildAt(i)
                if Child then
                    self.View.HorizontalBox:RemoveChildAt(i)
                    self.View.VerticalBox:AddChild(Child)
                end
            end
        end
        self.IsVertical  = IsVertical
    end

    -- 直接由重构设计间隔、缩放 代码不做处理
    -- local Scale = self.Param.Scale or 1
    -- local Padding = self.Param.Padding or -10
    -- -- local HiddenBtnClick = self.Param and self.Param.HideBtnClick or false
    -- -- self.View.BtnClick:SetVisibility(HiddenBtnClick and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible)
    -- for Index = 1,#self.MemberItemWidget do
    --     local ItemWidget = self.MemberItemWidget[Index]
    --     if self.IsVertical then
    --         ItemWidget.Slot.Padding.Top = Padding/2
    --         ItemWidget.Slot.Padding.Bottom = Padding/2
    --     else
    --         ItemWidget.Slot.Padding.Left = Padding/2
    --         ItemWidget.Slot.Padding.Right = Padding/2
    --     end
    --     ItemWidget.Slot:SetPadding(ItemWidget.Slot.Padding)
    --     ItemWidget:SetRenderScale(UE.FVector2D(Scale,Scale))
    -- end
    self:UpdateShow()
end

-- 刷新所有数据和展示列表
function TeamSideBarLogic:UpdateShow()
    self:InitShowData()
    self:UpdateMemberListShow()
end

function TeamSideBarLogic:OnHide()
    self.CommonHeadIconCls = {}
    self:ClearAllNewMsgTick()
end

--[[
    初始化展示数据
]]
function TeamSideBarLogic:InitShowData()
    -- 自己当前是不是队长
    self.IsSelfCaptain = MvcEntry:GetModel(TeamModel):IsSelfTeamCaptain()
    -- 我的队员列表
    self.MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    self.TeamList = {}
    -- 自己固定展示在第一位
    if not self.Param.IsHideSelf then
        local Data = {
            PlayerId = self.MyPlayerId,
            -- Status   -- TODO 
        }
        self.TeamList[#self.TeamList + 1] = Data
    end
    local TeamMembers = MvcEntry:GetModel(TeamModel):GetTeamMembers()
    for PlayerId,TeamMember in pairs(TeamMembers) do
        if  PlayerId ~= self.MyPlayerId then 
            local Data = {
                PlayerId = TeamMember.PlayerId,
                -- Status   -- TODO 
            }
            self.TeamList[#self.TeamList + 1] = Data
        end
    end
    -- 避免pairs遍历后顺序不一致
    -- table.sort(List,function (a,b)
    --     return a.PlayerId < b.PlayerId
    -- end)
    self.IsTeamListChanged = false

    -- 待定列表数据
    self:UpdateInviteListData()
end

-- 更新 邀请，申请，合并待定列表的数据
function TeamSideBarLogic:UpdateInviteListData()
     -- 我的邀请待定列表
     self.InviteList = {}
     local InviteList = MvcEntry:GetModel(TeamInviteModel):GetDataList()
     local FriendModel = MvcEntry:GetModel(FriendModel)
     for _,InviteListInfo in ipairs(InviteList) do
        local Data = {
            PlayerId = InviteListInfo.Invitee.PlayerId,
            TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST,
            TargetId = InviteListInfo.Invitee.PlayerId,
        }
        self.InviteList[#self.InviteList + 1] = Data
     end
     -- 申请入队待定列表
     local RequestList = MvcEntry:GetModel(TeamRequestApplyModel):GetDataList()
     for _,TeamApplySync in ipairs(RequestList) do
        local Data = {
            PlayerId = TeamApplySync.Applicant.PlayerId,
            TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST,
            TargetId = TeamApplySync.Applicant.PlayerId,
        }
         self.InviteList[#self.InviteList + 1] = Data
     end
     -- 合并队伍待定列表
     local MergeRecvList = MvcEntry:GetModel(TeamMergeApplyModel):GetDataList()
     for _,MergeListInfo in ipairs(MergeRecvList) do
        local Data = {
            PlayerId = MergeListInfo.MergeSend.PlayerId,
            TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST,
            TargetId = MergeListInfo.TeamId
        }
         self.InviteList[#self.InviteList + 1] = Data
     end
end

function TeamSideBarLogic:AppendToInviteList(Data)
    table.insert(self.InviteList,Data)
    self:UpdateMemberListShow()
end

--[[
    标记邀请列表数据发生变化
]]
function TeamSideBarLogic:OnInviteListChanged()
    self.IsInviteListChanged = true
end

--[[
    新增邀请待定
]]
function TeamSideBarLogic:OnAppendTeamInvite(_,InviteListInfo)
    local Data = {
        PlayerId = InviteListInfo.Invitee.PlayerId,
        TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST,
        TargetId = InviteListInfo.Invitee.PlayerId,
    }
    self:AppendToInviteList(Data)
end

--[[
    取消邀请待定
]]
function TeamSideBarLogic:OnDeleteTeamInvite(_,KeyList)
    for _,TargetId in ipairs(KeyList) do
        self:DeleteDataInTeamInvite(TargetId,FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST)
    end
    self:UpdateMemberListShow()
end


--[[
    新增入队申请待定
]]
function TeamSideBarLogic:OnAppendTeamRequest(_,ApplyListInfo)
    local Data = {
        PlayerId = ApplyListInfo.Applicant.PlayerId,
        TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST,
        TargetId = ApplyListInfo.Applicant.PlayerId,
    }
    self:AppendToInviteList(Data)
end

--[[
    取消入队申请待定
]]
function TeamSideBarLogic:OnDeleteTeamRequest(_,KeyList)
    for _,TargetId in ipairs(KeyList) do
        self:DeleteDataInTeamInvite(TargetId,FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST)
    end
    self:UpdateMemberListShow()
end

--[[
    新增合并队伍待定
]]
function TeamSideBarLogic:OnAppendTeamMerge(_,MergeListInfo)
    local Data = {
        PlayerId = MergeListInfo.MergeSend.PlayerId,
        TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST,
        TargetId = MergeListInfo.TeamId,
    }
    self:AppendToInviteList(Data)
end

--[[
    取消合并队伍待定
]]
function TeamSideBarLogic:OnDeleteTeamMerge(_,KeyList)
    for _,TargetId in ipairs(KeyList) do
        -- TargetId 合并发起方的TeamId
        self:DeleteDataInTeamInvite(TargetId,FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST)
    end
    self:UpdateMemberListShow()
end

function TeamSideBarLogic:DeleteDataInTeamInvite(TargetId,TypeId)
    local DeleteIndex = 0;
    for Index,Data in ipairs(self.InviteList) do
        if Data.TypeId == TypeId and Data.TargetId == TargetId then
            DeleteIndex = Index
            break
        end
    end
    if DeleteIndex > 0  then
        table.remove(self.InviteList,DeleteIndex)
    end
end

--[[
    新增队员 AddMap - { map< k = PlayerId, v = TeamMember> }
]]
function TeamSideBarLogic:OnAddTeamMember(_,AddMap)
    if not self.IsTeamListChanged and #AddMap > 0 then
        self.IsTeamListChanged = true
    end
    for _,AddInfo in ipairs(AddMap) do
        if AddInfo.k ~= self.MyPlayerId then 
            local Data = {
                PlayerId = AddInfo.k,
                -- Status   -- TODO 
            }
            self.TeamList[#self.TeamList + 1] = Data
            self:DeleteDataInTeamInvite(AddInfo.k) -- 检查是否从我的邀请待定中转换来
        end
    end
end

--[[
    减少队员 DeleteMap - { map< k = PlayerId, v = TeamMember> }
]]
function TeamSideBarLogic:OnDelTeamMember(_,DeleteMap)
    if not self.IsTeamListChanged and #DeleteMap > 0 then
        self.IsTeamListChanged = true
    end
    for _,DelInfo in ipairs(DeleteMap) do
        local PlayerId = DelInfo.k
        for i = #self.TeamList, 1, -1 do
            -- 自己固定展示在第一位，不被删除
            if self.TeamList[i].PlayerId ~= self.MyPlayerId and self.TeamList[i].PlayerId == PlayerId then
                table.remove(self.TeamList,i)
                -- 退队了要清除消息展示计时器
                self:ClearNewMsgTick(PlayerId)
                break
            end
        end
    end
    
end

--[[
    队员信息更新 UpdateMap - { map< k = PlayerId, v = TeamMember> }
]]
function TeamSideBarLogic:OnUpdateTeamMember(_,UpdateMap)
    if not self.IsTeamListChanged and #UpdateMap > 0 then
        self.IsTeamListChanged = true
    end
end

--[[
    队员信息更新完,根据状态是否执行列表刷新
]]
function TeamSideBarLogic:OnTeamInfoChanged()
    local IsRefresh = false
    if self.IsTeamListChanged then
        self.IsSelfCaptain = MvcEntry:GetModel(TeamModel):IsSelfTeamCaptain()
        IsRefresh = true
        
        self.IsTeamListChanged = false
    end
    if self.IsInviteListChanged then
        self:UpdateInviteListData()
        self.IsInviteListChanged = false
    end
    if IsRefresh then
        self:UpdateMemberListShow()
    end
end

function TeamSideBarLogic:UpdateMemberListShow()
    self.Index2PlayerId = {}
    if self.TeamList and #self.TeamList > 0 then
        -- 对self.TeamList进行排序
        local SelfData = nil
        -- 自己固定第一位不参与排序了
        if not self.Param.IsHideSelf then
            SelfData = table.remove(self.TeamList,1)
        end
        table.sort(self.TeamList,function (a,b)
                return a.PlayerId < b.PlayerId
            end)
        if SelfData then
            table.insert(self.TeamList,1,SelfData)
        end
    end
    for Index = 1,#self.MemberItemWidget do
        self:UpdateTeamMemberShow(Index)
    end
end

-- 队长变更，刷新队长标识
function TeamSideBarLogic:OnTeamLeaderChanged()
    self.IsSelfCaptain = MvcEntry:GetModel(TeamModel):IsSelfTeamCaptain()
    local LeaderId = MvcEntry:GetModel(TeamModel):GetLeaderId()
    local IsInTeam = MvcEntry:GetModel(TeamModel):IsSelfInTeam()
    local Index = 1
    for _,MemberInfo in ipairs(self.TeamList) do
        local IsCaptain = IsInTeam and MemberInfo.PlayerId == LeaderId
        local CommonHeadIcon = self.CommonHeadIconCls[Index]
        if CommonHeadIcon then
            CommonHeadIcon:UpdateCaptainFlag(IsCaptain)
        end
        Index = Index + 1
    end
    for I = Index,#self.MemberItemWidget do
        if not self.InviteList[I-Index+1] then
            local ItemWidget = self.MemberItemWidget[I]
            -- ItemWidget.WidgetSwitcher_HeadBtn:SetActiveWidget(self.IsSelfCaptain and ItemWidget.AddBtn or ItemWidget.TeamNone)
            ItemWidget.WidgetSwitcher_HeadBtn:SetActiveWidget(ItemWidget.AddBtn)
        end
    end
end

function TeamSideBarLogic:UpdateTeamMemberShow(Index)
    local ItemWidget = self.MemberItemWidget[Index]
    if not ItemWidget then
        print_trackback()
        return
    end
    if self.Param.IsHideSelf and Index == #self.MemberItemWidget then
        ItemWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        ItemWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    local IsTeamMember =  Index <= #self.TeamList
    local ShowData = IsTeamMember and self.TeamList[Index] or self.InviteList[Index - #self.TeamList]
    if not ShowData then
        --没有队员状态
        -- ItemWidget.WidgetSwitcher_HeadBtn:SetActiveWidget(self.IsSelfCaptain and ItemWidget.AddBtn or ItemWidget.TeamNone)
        ItemWidget.WidgetSwitcher_HeadBtn:SetActiveWidget(ItemWidget.AddBtn)
        ItemWidget.GUIImage_NewMsg:SetVisibility(UE.ESlateVisibility.Collapsed)
        if self.CommonHeadIconCls and self.CommonHeadIconCls[Index] then
            self.CommonHeadIconCls[Index]:OnCustomHide()
        end
    else
        self.Index2PlayerId[Index] = ShowData.PlayerId
        --[[
            存在队员状态三种情况：
            1.在队伍中  ShowCount = -1
            1.不在队伍中，但处于邀请中  ShowCount = 0
            2.不在队伍中，但处于邀请队末    ShowCount > 0
        ]]
        ItemWidget.WidgetSwitcher_HeadBtn:SetActiveWidget(ItemWidget.HeadIcon)

        ItemWidget.WidgetSwitcher_Head:SetVisibility(UE.ESlateVisibility.Collapsed)
        --TODO 要据队员四种状态去区切换WidgetSwitcher_Head 并更新展示
        local IsShowMask = false
        if not IsTeamMember then
            ItemWidget.WidgetSwitcher_Head:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            local MaxIndex = self.Param.IsHideSelf and #self.MemberItemWidget - 1 or #self.MemberItemWidget
            local ExtraCount = #self.InviteList - (MaxIndex - #self.TeamList)
            if Index == MaxIndex and ExtraCount > 0 then
                ItemWidget.WidgetSwitcher_Head:SetActiveWidget(ItemWidget.InvitedMore)
                ItemWidget.LbRequestNum:SetText(ExtraCount)
            else
                ItemWidget.WidgetSwitcher_Head:SetActiveWidget(ItemWidget.InvitedOnlyOne)
            end
            IsShowMask = true
        end

        local IsInTeam = MvcEntry:GetModel(TeamModel):IsSelfInTeam()
        -- 更新头像展示
        local Param = {
            PlayerId = ShowData.PlayerId,
            -- FocusType = self.IsVertical and CommonHeadIconOperateMdt.FocusTypeEnum.RIGHT or CommonHeadIconOperateMdt.FocusTypeEnum.TOP,
            FocusType = CommonHeadIconOperateMdt.FocusTypeEnum.RIGHT,
            CloseAutoCheckFriendShow = not IsTeamMember,    -- 处于待定列表时，不展示陌生人
            IsCaptain =  (IsTeamMember and IsInTeam) and MvcEntry:GetModel(TeamModel):IsTeamCaptain(ShowData.PlayerId) or false,
            -- OnItemClick = Bind(self,self.OnSelected,Index)
            -- FatherScale = self.Param.Scale or 1
        }
        if not self.CommonHeadIconCls[Index] then
            self.CommonHeadIconCls[Index] = UIHandler.New(self,ItemWidget.WBP_CommonHeadIcon, CommonHeadIcon,Param).ViewInstance
        else 
            self.CommonHeadIconCls[Index]:UpdateUI(Param)
        end
        self.CommonHeadIconCls[Index]:SetIsForceShowMask(IsShowMask)

        -- 是否有聊天角标展示中
        ItemWidget.GUIImage_NewMsg:SetVisibility((self.NewMsgTick and self.NewMsgTick[ShowData.PlayerId] ~= nil) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    end
    -- ItemWidget.GUIImage_Light:SetVisibility(UE.ESlateVisibility.Hidden)
end

--[[
    打开待定申请列表
]]
function TeamSideBarLogic:OnClick_OpenRequest(Index)
    -- self:OnSelected(Index)
    MvcEntry:OpenView(ViewConst.TeamInviteList,self.Index2PlayerId[Index])
end

--[[
    切换好友列表开关状态
]]
function TeamSideBarLogic:OnClick_SwitchFriendList(Index)
    -- self:OnSelected(Index)
    local ViewId = ViewConst.FriendMain
    local IsViewOpen = MvcEntry:GetModel(ViewModel):GetState(ViewId)
    if IsViewOpen then
        --MvcEntry:CloseView(ViewId) 
        MvcEntry:GetModel(FriendModel):DispatchType(FriendModel.ON_CLOSE_FRIENDVIEW_BY_ACTION)
    else
        -- if MvcEntry:GetModel(ViewModel):GetState(ViewConst.Chat) then
            -- 打开聊天界面的时候不响应
            -- return
        -- end
        MvcEntry:OpenView(ViewId)
    end
end

--[[
    切换选中态光圈
]]
-- function TeamSideBarLogic:OnSelected(SelectIndex)
--     for Index = 1,#self.MemberItemWidget do
--         local ItemWidget = self.MemberItemWidget[Index]
--         if ItemWidget then
--             ItemWidget.GUIImage_Light:SetVisibility(Index == SelectIndex and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Hidden)
--         end
--     end
-- end

-- 收到队友聊天消息
function TeamSideBarLogic:OnReceiveNewMsg(_,PlayerId)
    if PlayerId == self.MyPlayerId then
        return
    end
    for Index,Data in ipairs(self.TeamList) do
        if Data.PlayerId == PlayerId then
            local ItemWidget = self.MemberItemWidget[Index]
            if ItemWidget then
                self:AddNewMsgTick(ItemWidget,PlayerId)
                break
            end
        end
    end
end

-- 打开聊天界面 (清除所有小队聊天角标)
function TeamSideBarLogic:OnOpenChatMdt()
    for _,ItemWidget in pairs(self.MemberItemWidget) do
        -- 隐藏角标
        ItemWidget.GUIImage_NewMsg:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self:ClearAllNewMsgTick()
end

-- 添加消息角标
function TeamSideBarLogic:AddNewMsgTick(ItemWidget,PlayerId)
    self:ClearNewMsgTick(PlayerId)
    self.NewMsgTick = self.NewMsgTick or {}
    -- 展示角标
    ItemWidget.GUIImage_NewMsg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- TODO 时间读配置
    self.NewMsgTick[PlayerId] = Timer.InsertTimer(3,function ()
        -- 隐藏角标
        ItemWidget.GUIImage_NewMsg:SetVisibility(UE.ESlateVisibility.Collapsed)
        self:ClearNewMsgTick(PlayerId)
    end)
end

-- 清除所有角标计时器
function TeamSideBarLogic:ClearAllNewMsgTick()
    if self.NewMsgTick then
        for PlayerId,Timer in pairs(self.NewMsgTick) do
            self:ClearNewMsgTick(PlayerId)
        end
        self.NewMsgTick = nil
    end
end
-- 清除角标计时器
function TeamSideBarLogic:ClearNewMsgTick(PlayerId)
    if self.NewMsgTick and self.NewMsgTick[PlayerId] then
        Timer.RemoveTimer(self.NewMsgTick[PlayerId])
        self.NewMsgTick[PlayerId] = nil
    end
end

return TeamSideBarLogic
