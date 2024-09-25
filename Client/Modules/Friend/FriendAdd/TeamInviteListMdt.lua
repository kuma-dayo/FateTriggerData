--[[
    待定邀请列表界面（我向别人发出的组队邀请/ 别人发来的入队申请）
]]

local class_name = "TeamInviteListMdt";
TeamInviteListMdt = TeamInviteListMdt or BaseClass(GameMediator, class_name);

function TeamInviteListMdt:__init()
end

function TeamInviteListMdt:OnShow(data)
    
end

function TeamInviteListMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.BindNodes = {
        { UDelegate = self.GUIButton_OtherSide.OnClicked,				Func = self.OnClick_GUIButton_OtherSide},
        { UDelegate = self.OnAnimationFinished_vx_hall_invitedlist_out,	Func = Bind(self, self.On_vx_hall_invitedlist_out_Finished) },
    }
    self.MsgList = {
        -- 邀请入队
        {Model = TeamInviteModel, MsgName = ListModel.ON_DELETED, Func = self.OnDeleteInviteData},
        {Model = TeamInviteModel, MsgName = TeamInviteModel.ON_APPEND_TEAM_INVITE, Func = self.OnAppendInviteData},
        -- 申请入队
        {Model = TeamRequestApplyModel, MsgName = ListModel.ON_DELETED, Func = self.OnDeleteRequestData},
        {Model = TeamRequestApplyModel, MsgName = TeamRequestApplyModel.ON_APPEND_TEAM_REQUEST, Func = self.OnAppendRequestData},
        -- 合并队伍
        {Model = TeamMergeApplyModel, MsgName = ListModel.ON_DELETED, Func = self.OnDeleteMergeData},
        {Model = TeamMergeApplyModel, MsgName = TeamMergeApplyModel.ON_APPEND_TEAM_MERGE, Func = self.OnAppendMergeData},

        {Model = TeamModel, MsgName = TeamModel.ON_CLEAN_PENDDING_LIST, Func = self.DoClose},
    }
    -- self.CheckPlayerStatusDuration = 5  -- 定时请求状态的间隔时间
end

--由mdt触发调用
function M:OnShow(TargetId)
    self:UpdateShow(TargetId)
end

-- 刷新整个列表的数据和展示
function M:UpdateShow(TargetId)
    self.StrangerIds = {} -- 存储陌生人id。轮询玩家状态
    self.TeamIds = {}   -- 存储合并队伍id。轮询队伍信息
    local ShowList = {}
    self.PlayerId2Item = {
        [FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST] = {},
        [FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST] = {},
        [FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST] = {},
    }
    -- 主动邀请列表
    local FriendModel = MvcEntry:GetModel(FriendModel)
    local InviteList = MvcEntry:GetModel(TeamInviteModel):GetDataList()
    for _,InviteListInfo in ipairs(InviteList) do
        local Invitee = InviteListInfo.Invitee
        local Data = {
            PlayerId = Invitee.PlayerId,
            PlayerName = Invitee.PlayerName,
            InviterId = InviteListInfo.Inviter.PlayerId,
            TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST
        }
        ShowList[#ShowList+1] = Data
    end
    -- 申请入队列表
    local RequestList = MvcEntry:GetModel(TeamRequestApplyModel):GetDataList()
    for _,ApplyListInfo in ipairs(RequestList) do
        local Applicant = ApplyListInfo.Applicant
        local Data = {
            PlayerId = Applicant.PlayerId,
            PlayerName = Applicant.PlayerName,
            TeamId = ApplyListInfo.TeamId,
            TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST,
        }
        ShowList[#ShowList+1] = Data
    end
    
    -- 合并队伍列表
    local MergeRecvList = MvcEntry:GetModel(TeamMergeApplyModel):GetDataList()
    for _,MergeListInfo in ipairs(MergeRecvList) do
        local MergeSend = MergeListInfo.MergeSend
        local Data = {
            PlayerId = MergeSend.PlayerId,
            PlayerName = MergeSend.PlayerName,
            TeamId = MergeListInfo.TeamId,
            TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST,
            Members = MergeListInfo.Members,
            LeaderId = MergeListInfo.LeaderId,
        }
        self.TeamIds[#self.TeamIds + 1] = {
            PlayerId = MergeSend.PlayerId,
            TeamId = MergeListInfo.TeamId
        }
        ShowList[#ShowList+1] = Data
    end

    self.WidgetCount = 0
    self.WidgetSize = nil
    local TargetWidget = nil
    for _,ShowData in ipairs(ShowList) do
        local Widget = self:AddWidget(ShowData)
        if not self.WidgetSize then
            Widget.Root:ForceLayoutPrepass()
            self.WidgetSize = Widget.Root:GetDesiredSize()
        end
        if TargetId and ShowData.PlayerId == TargetId then
            TargetWidget = Widget
        end
    end
    self:AdjustScrollListSize()
    if TargetWidget ~= nil and self.WidgetCount > 5 then
        self.ScrollItemList:ScrollWidgetIntoView(TargetWidget)
    end

	-- self:CheckStrangerState()
    self:ScheduleCheckTeamState()
    self:PlayDynamicEffectOnShow(true)
end

function M:AddWidget(ShowData)
    local WidgetClassPath = "/Game/BluePrints/UMG/OutsideGame/Friend/FriendMain/WBP_Hall_Invited_Item.WBP_Hall_Invited_Item"
    local LuaClass = require("Client.Modules.Friend.FriendItems.TeamInviteItem")
    local WidgetClass = UE.UClass.Load(WidgetClassPath)
    local Widget = NewObject(WidgetClass, self)
    self.ScrollItemList:AddChild(Widget)
    Widget.Slot.Padding.Top = self.ScrollItemList.Slot.Padding.Bottom
    Widget.Slot.Padding.Bottom = self.ScrollItemList.Slot.Padding.Bottom
    Widget.Slot:SetPadding(Widget.Slot.Padding)
        
    self.WidgetCount = self.WidgetCount + 1

    local Param = {
        Data = ShowData
    }
    local Item = UIHandler.New(self,Widget,LuaClass,Param).ViewInstance
    if Item then
        self.PlayerId2Item[ShowData.TypeId] = self.PlayerId2Item[ShowData.TypeId] or {}
        local TargetId = ShowData.TypeId == FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST and ShowData.TeamId or ShowData.PlayerId
        self.PlayerId2Item[ShowData.TypeId][TargetId] = Item
    else
        CError("TeamInviteListMdt:OnShow Item nil")
    end
    self:CheckIsStranger(ShowData.PlayerId)
    return Widget
end

function M:CheckIsStranger(PlayerId)
    if not MvcEntry:GetModel(FriendModel):IsFriend(PlayerId) then
        self.StrangerIds[PlayerId] = 1
    end
end

function M:AdjustScrollListSize()
    if self.WidgetCount == 0 or not self.WidgetSize then return end
    local MaxCount = 5
    local Width = self.WidgetSize.X+ self.ScrollItemList.Slot.Padding.Left*2 + (self.WidgetCount > MaxCount and 20 or 0)
    local Count = self.WidgetCount < MaxCount and self.WidgetCount or MaxCount
    local Height = (self.WidgetSize.Y + self.ScrollItemList.Slot.Padding.Bottom*2) * Count + self.ScrollItemList.Slot.Padding.Bottom*2
    self.Overlay_Box.Slot:SetSize(UE.FVector2D(Width,Height))
    self.ScrollItemList:SetScrollBarVisibility(self.WidgetCount > MaxCount and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function M:OnDeleteInviteData(DelKeyList)
    self:DeleteWidgets(DelKeyList,FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST)
end

function M:OnDeleteRequestData(DelKeyList)
    self:DeleteWidgets(DelKeyList,FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST)
end

function M:OnDeleteMergeData(DelKeyList)
    self:DeleteWidgets(DelKeyList,FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST)
end

function M:DeleteWidgets(DelKeyList,TypeId)
    local ItemList = self.PlayerId2Item[TypeId]
    if not ItemList then return end
    for _,DelTargetId in ipairs(DelKeyList) do
        if ItemList[DelTargetId] then
            ItemList[DelTargetId].View:RemoveFromParent()
            ItemList[DelTargetId] = nil
            self.WidgetCount = self.WidgetCount - 1
        end
        self.StrangerIds[DelTargetId] = nil
    end
    self:CheckNeedCloseSelf()
end

function M:CheckNeedCloseSelf()
    local NeedClose = true
    for TypeId, ItemList in pairs(self.PlayerId2Item) do
        if table_leng(ItemList) ~= 0 then
            NeedClose = false
            break
        end    
    end
    if NeedClose then
        self:DoClose()
    else
        self:AdjustScrollListSize()
    end
end

-- 新增邀请入队
function M:OnAppendInviteData(InviteListInfo)
    if not InviteListInfo then return end
    local Invitee = InviteListInfo.Invitee
    local Data = {
        PlayerId = Invitee.PlayerId,
        PlayerName = Invitee.PlayerName,
        InviterId = InviteListInfo.Inviter.PlayerId,
        TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST
    }
    self:AddWidget(Data)
    self:AdjustScrollListSize()
end

-- 新增申请入队
function M:OnAppendRequestData(ApplyListInfo)
    if not ApplyListInfo then return end
    local Applicant = ApplyListInfo.Applicant
    local Data = {
        PlayerId = Applicant.PlayerId,
        PlayerName = Applicant.PlayerName,
        TeamId = ApplyListInfo.TeamId,
        TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST,
    }
    self:AddWidget(Data)
    self:AdjustScrollListSize()
end

-- 新增合并队伍
function M:OnAppendMergeData(MergeListInfo)
    if not MergeListInfo then return end
    local MergeSend = MergeListInfo.MergeSend
    local Data = {
        PlayerId = MergeSend.PlayerId,
        PlayerName = MergeSend.PlayerName,
        TeamId = MergeListInfo.TeamId,
        Members = MergeListInfo.Members,
        TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST,
    }
    self:AddWidget(Data)
    self:AdjustScrollListSize()
end

function M:OnClick_GUIButton_OtherSide()
    self:DoClose()
end

function M:OnHide()
    self:CleanAutoCheckTimer()
end

function M:DoClose()
    --MvcEntry:CloseView(self.viewId)
    self:OnCloseViewByAction()
end

-- 请求查询列表中非好友的状态
-- function M:CheckStrangerState()
--     if not CommonUtil.IsValid(self) then
--         self:CleanAutoCheckTimer()
--         print("TeamInviteListMdt Already Releaed")
--         return
--     end
--     local List = {}
--     for PlayerId,_ in pairs(self.StrangerIds) do
--         List[#List+1] = PlayerId
--     end
--     if #List > 0 then
--         ---@type UserModel
--         local UserModel = MvcEntry:GetModel(UserModel)
--         UserModel:GetPlayerState(List)
--     end
-- end

-- 请求查询列表中的队伍信息
function M:CheckNeedQueryTeamInfo()
    if self.TeamIds and #self.TeamIds > 0 then
        MvcEntry:GetCtrl(TeamCtrl):QueryMultiTeamInfoReq(self.TeamIds)
    end
end

-- 定时检测列表的状态显示
function M:ScheduleCheckTeamState()
    self:CleanAutoCheckTimer()
    self.CheckTimer = Timer.InsertTimer(1,function()
        -- if self.SecondTick == self.CheckPlayerStatusDuration then
		--     self:CheckStrangerState()
        --     self.SecondTick = 0
        -- else 
        --     self.SecondTick = self.SecondTick + 1
        -- end
        self:CheckNeedQueryTeamInfo()
    end,true)   
end

function M:CleanAutoCheckTimer()
    self.SecondTick = 0
    if self.CheckTimer then
        Timer.RemoveTimer(self.CheckTimer)
    end
    self.CheckTimer = nil
end

--[[
    播放显示退出动效
]]
function M:PlayDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.VXE_Hall_InvitedList_In then
            self:VXE_Hall_InvitedList_In()
        end
    else
        if self.VXE_Hall_InvitedList_Out then
            self:VXE_Hall_InvitedList_Out()
        end
    end
end

function M:On_vx_hall_invitedlist_out_Finished()
    MvcEntry:CloseView(self.viewId)
end


function M:OnCloseViewByAction()
    self:PlayDynamicEffectOnShow(false)
end


return M