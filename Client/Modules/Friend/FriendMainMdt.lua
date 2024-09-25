--[[
    好友主界面
]]

local class_name = "FriendMainMdt";
FriendMainMdt = FriendMainMdt or BaseClass(GameMediator, class_name);

FriendMainMdt.MenTabKeyEnum = {
    --好友
    Friend = 1,
    --推荐
    Recommend = 2,
}

function FriendMainMdt:__init()
end

function FriendMainMdt:OnShow(data)
end

function FriendMainMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.GUIButton_AddFriend.GUIButton_Main.OnClicked,				    Func = self.GUIButton_AddFriend_ClickFunc },
		{ UDelegate = self.GUIButton_AddFriend.GUIButton_Main.OnHovered,				    Func = self.GUIButton_AddFriend_OnHoveredFunc },
		{ UDelegate = self.GUIButton_AddFriend.GUIButton_Main.OnUnhovered,				    Func = self.GUIButton_AddFriend_OnUnhoveredFunc },
        { UDelegate = self.BtnOutSide.OnClicked,	Func = self.GUIButton_Close_ClickFunc },
        { UDelegate = self.WBP_ReuseListEx.ScrollBoxList.OnUserOverScrolled,	Func = self.OnUserOverScrolled_Func },
        { UDelegate = self.OnAnimationFinished_vx_hall_invite_close,	Func = self.On_vx_hall_invite_close_Finished },
	}
    self.MsgList = {
        {Model = FriendModel, MsgName = FriendModel.ON_CLOSE_FRIENDVIEW_BY_ACTION, Func = self.OnCloseViewByAction}, --只在Friend页签加了关闭动画事件，当初没注意到是分页签放msgList的
        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_ACTIVE_CHANGED,    Func = self.OnOtherViewShowed },
    }
    self.CustomMsgList ={
        [FriendMainMdt.MenTabKeyEnum.Friend] = 
            {
                {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.GUIButton_Close_ClickFunc },
                {Model = FriendModel, MsgName = ListModel.ON_UPDATED, Func = self.OnFriendListUpdated},
                {Model = FriendModel, MsgName = ListModel.ON_DELETED, Func = self.RefreshFriendItems},
                {Model = FriendModel, MsgName = FriendModel.ON_PLAYERSTATE_CHANGED, Func = self.OnFriendPlayerStateChanged},
                -- {Model = FriendModel, MsgName = FriendModel.ON_SHOW_FRIENDVIEW_LIST_BY_ACTION, Func = self.OnShowListByAction},
                -- {Model = FriendModel, MsgName = FriendModel.ON_HIDE_FRIENDVIEW_LIST_BY_ACTION, Func = self.OnHideListByAction},
                {Model = FriendApplyModel, MsgName = ListModel.ON_UPDATED, Func = self.OnApplyListUpdate},
                {Model = FriendApplyModel, MsgName = ListModel.ON_DELETED, Func = self.OnApplyListUpdate},
                {Model = TeamModel, MsgName = TeamModel.ON_ADD_TEAM_MEMBER, Func = self.OnAddTeamMember},
                {Model = TeamModel, MsgName = TeamModel.ON_DEL_TEAM_MEMBER, Func = self.OnDelTeamMember},
                {Model = TeamModel, MsgName = TeamModel.ON_GET_OTHER_TEAM_INFO, Func = self.OnGetOtherTeamInfo},
                {Model = TeamModel, MsgName = TeamModel.ON_DEL_OTHER_TEAM_INFO, Func = self.OnDelOtherTeamInfo},
                {Model = TeamModel, MsgName = TeamModel.ON_SELF_QUIT_TEAM, Func = self.OnSelfQuitTeam},
                {Model = TeamModel, MsgName = TeamModel.ON_TEAM_LEADER_CHANGED, Func = self.OnTeamLeaderChanged},
                -- 邀请入队
                {Model = TeamInviteApplyModel, MsgName = TeamInviteApplyModel.ON_APPEND_TEAM_INVITE_APPLY, Func = self.OnOperateTeamInviteApply},
                {Model = TeamInviteApplyModel, MsgName = TeamInviteApplyModel.ON_OPERATE_TEAM_INVITE, Func = self.OnOperateTeamInviteApply},
                {Model = TeamInviteApplyModel, MsgName = ListModel.ON_CHANGED, Func = self.OnOperateTeamInviteApply},
                -- 申请入队
                {Model = TeamRequestApplyModel, MsgName = TeamRequestApplyModel.ON_APPEND_TEAM_REQUEST_FOR_CAPTAIN, Func = self.OnOperateTeamRequestApply},
                {Model = TeamRequestApplyModel, MsgName = TeamRequestApplyModel.ON_OPERATE_TEAM_REQUEST, Func = self.OnOperateTeamRequestApply},
                {Model = TeamRequestApplyModel, MsgName = ListModel.ON_CHANGED, Func = self.OnOperateTeamRequestApply},
                -- 合并队伍
                {Model = TeamMergeApplyModel, MsgName = TeamMergeApplyModel.ON_APPEND_TEAM_MERGE_FOR_CAPTAIN, Func = self.OnOperateTeamMerge},
                {Model = TeamMergeApplyModel, MsgName = TeamMergeApplyModel.ON_OPERATE_TEAM_MERGE, Func = self.OnOperateTeamMerge},
                {Model = TeamMergeApplyModel, MsgName = ListModel.ON_CHANGED, Func = self.OnOperateTeamMerge},
                -- 组队推荐
                {Model = RecommendModel, MsgName = RecommendModel.ON_RECOMMEND_SPECIAL_SHOW_LIST_UPDATED, Func = Bind(self,self.OnSpecialRecommendListUpdate)},
            },
        -- 组队推荐
        [FriendMainMdt.MenTabKeyEnum.Recommend] = 
            {
                {Model = RecommendModel, MsgName = RecommendModel.ON_RECOMMEND_SHOW_LIST_UPDATED, Func = self.OnRecommendListUpdate},
            }
        }


    self.ShowTypeId2ItemCls = {
        [FriendConst.LIST_TYPE_ENUM.EMPTY] = require("Client.Modules.Friend.FriendItems.FriendListEmptyItem"),
        [FriendConst.LIST_TYPE_ENUM.FRIEND] = require("Client.Modules.Friend.FriendItems.FriendListItem"),
        [FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST] = require("Client.Modules.Friend.FriendItems.FriendTeamInviteRequestItem"),
        [FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST] = require("Client.Modules.Friend.FriendItems.FriendTeamMergeRequestItem"),
        [FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST] = require("Client.Modules.Friend.FriendItems.FriendTeamRequestItem"),
        [FriendConst.LIST_TYPE_ENUM.FRIEND_REQUEST] = require("Client.Modules.Friend.FriendItems.FriendRequestItem"),
        [FriendConst.LIST_TYPE_ENUM.TEAM_RECOMMEND] = require("Client.Modules.Friend.FriendItems.FriendTeamRecommendItem"),
    }
    
    local MenuTabParam = {
		ItemInfoList = {
            {Id=FriendMainMdt.MenTabKeyEnum.Friend,LabelStr=G_ConfigHelper:GetStrFromOutgameStaticST("SD_Friend","1427_Btn")},
            {Id=FriendMainMdt.MenTabKeyEnum.Recommend,LabelStr=G_ConfigHelper:GetStrFromOutgameStaticST("SD_Friend","1428_Btn")},
        },
        CurSelectId = FriendMainMdt.MenTabKeyEnum.Friend,
        ClickCallBack = Bind(self,self.OnMenuBtnClick),
        ValidCheck = Bind(self,self.MenuValidCheck),
        HideInitTrigger = true,
        IsOpenKeyboardSwitch = true,
	}
    self.MenuTabListCls = UIHandler.New(self,self.WBP_Common_TabUp_03, CommonMenuTabUp,MenuTabParam).ViewInstance


    -- 初始化 EmptyState 中按钮和文字的展示信息
    -- UIHandler.New(self, self.WBP_CommonBtnTips, WCommonBtnTips, 
    -- {
    --     OnItemClick = Bind(self, self.OnPressSpaceBar),
    --     CommonTipsID = CommonConst.CT_SPACE,
    --     TipStr = G_ConfigHelper:GetStrFromMiscST("Lua_FriendMainMdt_b96fe5bcce4dabb0"),
    --     HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Custom_Friend,
    --     ActionMappingKey = ActionMappings.SpaceBar
    -- })
    -- self.WBP_CommonBtnTips.ControlTipsIcon:SetRenderScale(UE.FVector2D(0.8, 0.8))

    self.CurTabId = 0
    self.AutoTeamCheckTime = 1  -- 定时请求好友队伍状态的间隔时间
    self.RecommendCtrl = MvcEntry:GetCtrl(RecommendCtrl)
end

function M:AddListeners()
	self.WBP_ReuseListEx.OnUpdateItem:Add(self, self.OnUpdateItem)
    self.WBP_ReuseListEx.OnPreUpdateItem:Add(self, self.OnPreUpdateItem)
    self.WBP_ReuseListEx.OnReloadFinish:Add(self, self.OnReloadFinish)
end

function M:RemoveListeners()
	self.WBP_ReuseListEx.OnUpdateItem:Clear()
	self.WBP_ReuseListEx.OnPreUpdateItem:Clear()
	self.WBP_ReuseListEx.OnReloadFinish:Clear()
end


--由mdt触发调用
--[[
    Data = {
        TabKey FriendMainMdt.MenTabKeyEnum [可选]
    }
]]
function M:OnShow(Data)
    local ShowTab = FriendMainMdt.MenTabKeyEnum.Friend
    if Data and Data.TabKey then
        ShowTab = Data.TabKey
    end
    self.Widget2Item = {}
    self.Widget2RecommendItem = {}
	self:AddListeners()
    self.RecommendCtrl:CheckReqShowList()
    self:OnMenuBtnClick(ShowTab)
    self:PlayDynamicEffectOnShow(true)
    MvcEntry:GetModel(TeamModel):DispatchType(TeamModel.ON_NOTIFY_TEAM_AND_CHAT_IN_OR_OUT_BY_ACTION, true)
end

function M:OnHide()
    for _,MsgList in pairs(self.CustomMsgList) do
		CommonUtil.MvcMsgRegisterOrUnRegister(self,MsgList,false)
    end
    self.MenuTabListCls = nil
    -- self.IsFriendListInited = false
    self:CleanAutoCheckTimer()
	self:RemoveListeners()
    MvcEntry:GetModel(RecommendModel):ClearCacheData()
end

--[[
    播放显示退出动效
]]
function M:PlayDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.VXE_Hall_Invite_Open then
            self:VXE_Hall_Invite_Open()
        end
    else
        if self.VXE_Hall_Invite_Close then
            self:VXE_Hall_Invite_Close()
        end
    end
end

function M:OnUpdateItem(Widget, Index)
	-- CLog("=============OnUpdateItem"..Index)
	local FixIndex = Index + 1
    if self.CurTabId == FriendMainMdt.MenTabKeyEnum.Friend then
        self:UpdateTabFriendItem(Widget,FixIndex)
    elseif self.CurTabId == FriendMainMdt.MenTabKeyEnum.Recommend then
        self:UpdateTabRecommendItem(Widget,FixIndex)
    end
end

function M:OnPreUpdateItem(Index)
	-- CLog("=============OnPreUpdateItem"..Index)
	local FixIndex = Index + 1
    if self.CurTabId == FriendMainMdt.MenTabKeyEnum.Friend then
        local Data = nil
        if FixIndex <= #self.MergeItemDataList then
            Data = self.MergeItemDataList[FixIndex]
        else
        Data = self.FriendItemDataList[FixIndex - #self.MergeItemDataList] 
        end
        if Data then
            if Data.TypeId == FriendConst.LIST_TYPE_ENUM.FRIEND then
                self.WBP_ReuseListEx:ChangeItemClassForIndex(Index,"")
            else
                self.WBP_ReuseListEx:ChangeItemClassForIndex(Index,Data.TypeId)
            end
        end
    elseif self.CurTabId == FriendMainMdt.MenTabKeyEnum.Recommend then
        if FixIndex > #self.RecommendList then
            -- ‘换一批’按钮
            self.WBP_ReuseListEx:ChangeItemClassForIndex(Index, FriendConst.LIST_TYPE_ENUM.TEAM_RECOMMEND_CHANGE_LIST)
        else
            self.WBP_ReuseListEx:ChangeItemClassForIndex(Index, FriendConst.LIST_TYPE_ENUM.TEAM_RECOMMEND_INNER)
        end
    end
end

function M:OnReloadFinish()
    if self.NeedSrollToStart then
        self.WBP_ReuseListEx:ScrollToStart()
        self.NeedSrollToStart = false
    end
end

function M:UpdateTabFriendItem(Widget,FixIndex)
    local Data = nil
    if FixIndex <= #self.MergeItemDataList then
        Data = self.MergeItemDataList[FixIndex]
    else
       Data = self.FriendItemDataList[FixIndex - #self.MergeItemDataList] 
    end
	if Data == nil then
		return
	end
	local Param = {
        Data = Data.Vo,
    }
    
    local Item = self.Widget2Item[Widget]
	if not Item then
        local Cls = self.ShowTypeId2ItemCls[Data.TypeId]
        if not Cls then
            CError("FriendMainMdt OnUpdateItem Get Cls Error for Type = "..tostring(Data.TypeId))
            print_trackback()
            return
        end
        Item = UIHandler.New(self,Widget,Cls,Param).ViewInstance
        self.Widget2Item[Widget] = Item
    end
    Item:UpdateListShow(Param)
	self.ItemList[FixIndex] = Item
    
    if Data.TypeId ~= FriendConst.LIST_TYPE_ENUM.FRIEND and Data.TypeId ~= FriendConst.LIST_TYPE_ENUM.TEAM_RECOMMEND  then
        -- 折叠的Item一个TypeId只会存在一项
        self.MergeItemType2Index[Data.TypeId] = FixIndex
        self.MergeItemType2Item[Data.TypeId] = Item
    end
end

-- 好友列表界面是否需要展示为空提示
function M:UpdateEmptyTipsShow()
    -- local IsFriendTab = self.CurTabId == FriendMainMdt.MenTabKeyEnum.Friend
    -- local IsEmpty = IsFriendTab and (#self.MergeItemDataList + #self.FriendItemDataList) <= 0
    -- self.EmptyState:SetVisibility(IsEmpty and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    -- self.WBP_ReuseListEx:SetVisibility(IsEmpty and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible)
    -- if IsFriendTab and self.IsListEmpty then
        -- todo 
    -- end
end

function M:OnMenuBtnClick(Id,ItemInfo,IsInit)
    for TabKey, MsgList in pairs(self.CustomMsgList) do
        TabKey = tonumber(TabKey)
		CommonUtil.MvcMsgRegisterOrUnRegister(self,MsgList,Id == TabKey)
    end
    self.CurTabId = Id
    if Id == FriendMainMdt.MenTabKeyEnum.Friend then
        -- 好友页签
        self.WBP_ReuseListEx:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.EmptyState:SetVisibility(UE.ESlateVisibility.Collapsed)
        -- if self.IsFriendListInited then 
        --     self:DoReloadList()
        -- else
            -- 切到其他页签，会暂停好友相关的事件监听，数据无法更新，切页签只能全刷一遍
            self:UpdateAllList() 
            self:CheckTeamState()
        -- end
        self:ScheduleCheckTeamState()
    elseif Id == FriendMainMdt.MenTabKeyEnum.Recommend then
        -- 组队页签
        self.WBP_ReuseListEx:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:DoReloadRecommendList()
        self:ScheduleCheckTeamState()
    else
        self.WBP_ReuseListEx:SetVisibility(UE.ESlateVisibility.Collapsed)
        self:CleanAutoCheckTimer()
    end
    MvcEntry:GetModel(FriendModel):SaveNowTabIndex(Id)
end
function M:MenuValidCheck(Id)
    return true
end

--关闭界面
function M:GUIButton_Close_ClickFunc()
    MvcEntry:GetModel(TeamModel):DispatchType(TeamModel.ON_NOTIFY_TEAM_AND_CHAT_IN_OR_OUT_BY_ACTION, false)
    MvcEntry:CloseView(self.viewId)
    return true
end

--弹出手动添加好友界面
function M:GUIButton_AddFriend_ClickFunc()
    MvcEntry:OpenView(ViewConst.FriendAdd)
end

function M:GUIButton_AddFriend_OnHoveredFunc()
    local Param = {
        ParentWidgetCls = self,
        TipsStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Friend","Lua_FriendMainMdt_AddFriendTips"),
        FocusWidget = self.GUIButton_AddFriend,
        PositionType = CommonHoverTipsMdt.PositionType.BottomCenter
    }
    MvcEntry:OpenView(ViewConst.CommonHoverTips,Param)
end

function M:GUIButton_AddFriend_OnUnhoveredFunc()
    MvcEntry:CloseView(ViewConst.CommonHoverTips)
end

-- 空格键 无好友的时候才响应
function M:OnPressSpaceBar()
    local IsFriendTab = self.CurTabId == FriendMainMdt.MenTabKeyEnum.Friend
    local IsEmpty = IsFriendTab and (#self.MergeItemDataList + #self.FriendItemDataList) <= 0
    if IsEmpty then
        self:GUIButton_AddFriend_ClickFunc()
    end
end

function M:DoReloadList()
    if not self.MergeItemDataList or not self.FriendItemDataList then
        return
    end
    self.ItemList = {}
    self.WBP_ReuseListEx:Reload(#self.MergeItemDataList + #self.FriendItemDataList)
    self.NeedSrollToStart = true
end

--[[
    刷新整个列表
]]
function M:UpdateAllList()
    self:UpdateMergeItemShowDatas()
    self:UpdateFriendItemShowDatas()
    self:DoReloadList()
    self:UpdateEmptyTipsShow()
    -- self.IsFriendListInited = true
end

--[[ 
    仅刷新好友项部分展示数据
]]
function M:RefreshFriendItems()
    self:UpdateFriendItemShowDatas()
    self:DoReloadList()
    self:UpdateEmptyTipsShow()
end

--[[ 
    好友列表数据发生变化
]]
function M:OnFriendListUpdated(Map)
    if not Map then
        return  
    end
    local AddMap = Map["AddMap"]
    local DeleteMap = Map["DeleteMap"]
    if (AddMap and #AddMap > 0) or (DeleteMap and #DeleteMap > 0) then
        self:RefreshFriendItems()
        return
    end

    local UpdateMap = Map["UpdateMap"]
    local FriendModel = MvcEntry:GetModel(FriendModel)
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local RefreshIndexList = {}

    if UpdateMap and #UpdateMap > 0 then
        for i,Vo in ipairs(UpdateMap) do
            local PlayerId = Vo.PlayerId
            local FixIndex = self.PlayerId2Index[PlayerId]
            if FixIndex and self.FriendItemDataList[FixIndex-#self.MergeItemDataList] then
                -- 状态改变 挪入单独的事件 ON_PLAYERSTATE_CHANGED 处理
                local ShowData = FriendModel:TransformToFriendShowData(Vo)
                self.FriendItemDataList[FixIndex-#self.MergeItemDataList] = ShowData
                local Item = self.ItemList[FixIndex] 
                if Item then
                    local Param = {
                        Data = ShowData.Vo
                    }
                    Item:UpdateListShow(Param)
                end
            end
        end
    end
end

-- 好友玩家状态改变
function M:OnFriendPlayerStateChanged(FriendInfoList)
    local FriendModel = MvcEntry:GetModel(FriendModel)
    for i,FriendBaseNode in ipairs(FriendInfoList) do
        local PlayerId = FriendBaseNode.PlayerId
        local FixIndex = self.PlayerId2Index[PlayerId]
        if FixIndex and self.FriendItemDataList[FixIndex-#self.MergeItemDataList] then
            local OldState = self.FriendItemDataList[FixIndex-#self.MergeItemDataList].Vo.State
            local ShowData = FriendModel:TransformToFriendShowData(FriendBaseNode)
            local NewState = ShowData.Vo.State
            -- 列表中的状态变化会影响排序
            local StateEffectSortList = {
                [FriendConst.PLAYER_STATE_ENUM.PLAYER_OFFLINE] = 1,
            }
            if (StateEffectSortList[OldState] and not StateEffectSortList[NewState]) or (not StateEffectSortList[OldState] and StateEffectSortList[NewState]) then
                self:RefreshFriendItems()
                break
            end
            local TeamKey = self.PlayerId2TeamKey[PlayerId]
            if NewState == FriendConst.PLAYER_STATE_ENUM.PLAYER_SINGLE and TeamKey then
                -- 退队了，原来是在TeamItem里, 要重新加回PlayerItem。只能重刷
                self:RefreshFriendItems()
                break
            end

            self.FriendItemDataList[FixIndex-#self.MergeItemDataList].Vo.State = ShowData.Vo.State
            self.FriendItemDataList[FixIndex-#self.MergeItemDataList].Vo.PlayerState = ShowData.Vo.PlayerState
            local Item = self.ItemList[FixIndex] 
            if Item then
                local Param = {
                    Data = self.FriendItemDataList[FixIndex-#self.MergeItemDataList].Vo
                }
                Item:UpdateListShow(Param)
            end
        end
    end
end

-- 申请列表数据变化，处理该节点
function M:OnApplyListUpdate()
    local RequestList = MvcEntry:GetModel(FriendApplyModel):GetApplyList()
    self:UpdateMergeItem(FriendConst.LIST_TYPE_ENUM.FRIEND_REQUEST,RequestList)
end

-- 邀请入队申请数据变化，处理该节点
function M:OnOperateTeamInviteApply()
    local RequestList = MvcEntry:GetModel(TeamInviteApplyModel):GetTeamInviteApplyList()
    self:UpdateMergeItem(FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST,RequestList)
end

-- 申请入队数据变化，处理该节点
function M:OnOperateTeamRequestApply()
    local RequestList = MvcEntry:GetModel(TeamRequestApplyModel):GetTeamRequestDataList()
    self:UpdateMergeItem(FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST,RequestList)
end

-- 合并队伍数据变化，处理该节点
function M:OnOperateTeamMerge()
    local RequestList = MvcEntry:GetModel(TeamMergeApplyModel):GetTeamMergeDataList()
    self:UpdateMergeItem(FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST,RequestList)
end

--[[
    更新指定类型合并节点的展示
    ItemType: FriendConst.LIST_TYPE_ENUM
    RequestList: 节点中展示的数据列表
]]
function M:UpdateMergeItem(ItemType, RequestList)
    local MergeItemFlag = self.MergeItemFlag[ItemType]
    local FixIndex = self.MergeItemType2Index[ItemType]
    local NeedReload = true
    if #RequestList > 0 and not MergeItemFlag then
        table.insert(self.MergeItemDataList,RequestList[1])
        self.MergeItemFlag[ItemType] = 1
    elseif #RequestList == 0 and MergeItemFlag then
        table.remove(self.MergeItemDataList,FixIndex)
        self.MergeItemType2Index[ItemType] = nil
        self.MergeItemType2Item[ItemType] = nil
        self.MergeItemFlag[ItemType] = nil
    elseif MergeItemFlag or #RequestList == 0 then
        NeedReload = false
    end
    if NeedReload then
        -- 需要根据类型排序
        table.sort(self.MergeItemDataList,function (a,b)
            return a.TypeId < b.TypeId
        end)
        self:RefreshFriendItems()
    else
        local Item = self.ItemList[FixIndex]
        if Item then
            Item:UpdateListShow()
        end
    end
end


-- 新增队员
function M:OnAddTeamMember(AddMap)
    local TeamModel =MvcEntry:GetModel(TeamModel) 
    local MyTeamId = TeamModel:GetTeamId()
    local MyTeamKey = self:ConvertTeamId2Key(MyTeamId)
    local MyTeamIndex = self.TeamKey2Index[MyTeamKey]

    local Members = TeamModel:GetDataMap()
    local FriendModel = MvcEntry:GetModel(FriendModel)
    local MemberHavePlayerItem = false
    for MemberId,Member in pairs(Members) do
        if FriendModel:IsFriend(MemberId) then
            -- 检测是否由其他好友单人项 转成 在此队伍项一起展示 
            local PlayerIndex = self.PlayerId2Index[MemberId]
            if PlayerIndex ~= nil and PlayerIndex ~= MyTeamIndex then
                if MyTeamIndex == nil then
                    MyTeamIndex = PlayerIndex
                else
                    MemberHavePlayerItem = true
                end

            end
        end
    end
    self.TeamKey2Index[MyTeamKey] = MyTeamIndex
    if MemberHavePlayerItem then
        -- 2. 有队员展示为其他好友单人项，需要将其放在此队伍项一起展示 ,要删除单人项，重新更新列表
        self:RefreshFriendItems()     
        return
    elseif MyTeamIndex == nil then
        -- 2.1 无队员存在于好友项。无需处理列表
        return
    end
    -- 3. 有队伍项展示了，只是刷新内部队伍信息
    local Item = self.ItemList[MyTeamIndex]
    if Item then
        Item:OnAddTeamMember()
    end
    -- self:UpdateTeamMemberCount()
end

-- 减少队员
function M:OnDelTeamMember(DeleteMap)
    local TeamModel = MvcEntry:GetModel(TeamModel) 
    local IsSelfInTeam = TeamModel:IsSelfInTeam()
    local NeedRefresh = true
    if IsSelfInTeam then
        local MyTeamId = TeamModel:GetTeamId()
        local MyTeamKey = self:ConvertTeamId2Key(MyTeamId)
        local MyTeamIndex = self.TeamKey2Index[MyTeamKey]
        local Item = self.ItemList[MyTeamIndex]
        if Item then
            -- 我的队伍还在，人数变化，刷新显示
            Item:OnDelTeamMember()
            NeedRefresh = false
        end
    end
    if NeedRefresh then
        self:RefreshFriendItems()     
    end
end

--[[
    收到好友的队伍信息
]]
function M:OnGetOtherTeamInfo(TeamInfo)
    if not self.CurTabId or self.CurTabId == FriendMainMdt.MenTabKeyEnum.Recommend or  not TeamInfo then
        return
    end

    local FriendModel = MvcEntry:GetModel(FriendModel)
    local TeamModel = MvcEntry:GetModel(TeamModel)
    -- local TargetId = TeamInfo.TargetId
    local TeamId = TeamInfo.TeamId
    local TeamKey = self:ConvertTeamId2Key(TeamId)
    local Members = TeamInfo.Members
    local TeamIndex = self.TeamKey2Index[TeamKey]

    local IsAllMemberOffline = TeamModel:CheckIsAllMemberOffline(Members)
    if IsAllMemberOffline then
        -- 查询回来的队伍，全员离线，则直接重刷列表，展示回单人项
        self:RefreshFriendItems()   
        return  
    end
    
    -- 1. 查询到的是个单人队
    if TeamInfo.PlayerCnt == 1 then
        -- 1-1. 原来有队伍项展示，现在只是单人队了。直接刷新该项展示为单人项
        if TeamIndex ~= nil then
            -- 清除队伍记录
            for MemberId,Member in pairs(Members) do
                self.PlayerId2TeamKey[MemberId] = nil
            end
            self.TeamKey2Index[TeamKey] = nil
            local WidgetIndex = TeamIndex - 1
            self.WBP_ReuseListEx:RefreshOne(WidgetIndex)
        end
        -- 1-2. 原来是单人项，现在变成单人队，表现上没有变化，无需处理
        return
    end

    -- TargetId有可能不在此队伍里
    local MemberHavePlayerItem = false
    for MemberId,Member in pairs(Members) do
        -- 记录队伍信息
        self.PlayerId2TeamKey[MemberId] = TeamKey
        if FriendModel:IsFriend(MemberId) then
            -- 检测是否由其他好友单人项 转成 在此队伍项一起展示 
            local PlayerIndex = self.PlayerId2Index[MemberId]
            if PlayerIndex ~= nil and PlayerIndex ~= TeamIndex then
                if TeamIndex == nil then
                    -- 仅有好友项，没有队伍项，那此项就作为队伍项. 走3的逻辑
                    TeamIndex = PlayerIndex
                    self.TeamKey2Index[TeamKey] = TeamIndex
                else
                    MemberHavePlayerItem = true
                end
            end
        end
    end
    
    if MemberHavePlayerItem then
        -- 2. 有队员展示为其他好友单人项，需要将其放在此队伍项一起展示 ,要删除单人项，重新更新列表
        self:RefreshFriendItems()     
        return
    end

    if TeamIndex then
        -- 3. 有队伍项展示了，只是刷新内部队伍信息
        local Item = self.ItemList[TeamIndex]
        if Item then
            Item:UpdateListShow()
        end
    else
        -- 理论上出口1.2.3满足所有情况。不会到这里。走到这了。强刷一遍数据了。
        -- 走到这里。。说明是推荐列表请求的队伍数据。此界面可以不处理了
        -- CLog("OnGetOtherTeamInfo exit invalid....")
        -- self:RefreshFriendItems()     
    end
end

-- 清除其他队伍信息
function M:OnDelOtherTeamInfo(DelTeamId)
    local TeamKey = self:ConvertTeamId2Key(DelTeamId)
    local RefreshIndex  = self.TeamKey2Index[TeamKey]
    if RefreshIndex and RefreshIndex > 0 then
        self.TeamKey2Index[TeamKey] = nil
        for PlayerId, SaveTeamKey in pairs(self.PlayerId2TeamKey) do
            if SaveTeamKey == TeamKey then
                self.PlayerId2TeamKey[PlayerId] = nil
            end
        end
        self.WBP_ReuseListEx:RefreshOne(RefreshIndex-1)
    end
end

function M:OnSelfQuitTeam(IsFromSingleTeam)
    if not IsFromSingleTeam then
        self:UpdateAllList()
    end
end

function M:OnTeamLeaderChanged(OriLeaderId)
    local NewLeaderId = MvcEntry:GetModel(TeamModel):GetLeaderId()
    local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()
    if OriLeaderId ~= NewLeaderId and (OriLeaderId == MyPlayerId or NewLeaderId == MyPlayerId) then
        -- 我成为队长 或 我把队长转交 申请等折叠项是队长才会有，需要刷新列表
        self:UpdateMergeItemShowDatas()
        self:DoReloadList()
        self:UpdateEmptyTipsShow()
    end
end

function M:CheckTeamState()
    self:CheckFriendTeamState()
    self:CheckMergeItemsTeamState()
end

-- 检测是否请求好友队伍状态
function M:CheckFriendTeamState()
    if not self.FriendItemDataList then
        return
    end
    local ReqPlayerIdList = {}
    local ReqTeamIdList = {}

    local TeamModel = MvcEntry:GetModel(TeamModel)
    local MyTeamId = TeamModel:GetTeamId()
    local IsTeam = false
    for Index,Data in ipairs(self.FriendItemDataList) do
        local Vo = Data.Vo
        if Vo then
            local PlayerId = Vo.PlayerId
            IsTeam = false
            if not TeamModel:IsSelfTeamMember(PlayerId) then
                if self.PlayerId2TeamKey[PlayerId] then
                    local TeamId = self:ConvertTeamKey2Id(self.PlayerId2TeamKey[PlayerId])
                    if TeamId then
                        if TeamId ~= MyTeamId then
                            -- 自己队伍不轮询
                            ReqTeamIdList[#ReqTeamIdList + 1] = {
                                PlayerId = PlayerId,
                                TeamId = TeamId
                            }
                        end
                        IsTeam = true
                    end
                end
                if not IsTeam then
                    local State = Vo.State
                    if State == FriendConst.PLAYER_STATE_ENUM.PLAYER_INTEAM or  -- 单人组队中
                        ((State == FriendConst.PLAYER_STATE_ENUM.PLAYER_MATCHING or State == FriendConst.PLAYER_STATE_ENUM.PLAYER_GAMING) and TeamModel:GetTeamId(PlayerId) == 0) then
                        -- 单人游戏中，且本地没缓存过队伍数据的，只需要请求一次队伍数据 (TODO - 后续可能需要判断是否是单人模式)
                        ReqPlayerIdList[#ReqPlayerIdList+1] = PlayerId
                    end
                end    
            end
        end
    end
   
    if #ReqPlayerIdList > 0 then
        MvcEntry:GetCtrl(TeamCtrl):SendPlayerListTeamInfoReq(ReqPlayerIdList)
    end
    if #ReqTeamIdList > 0 then
        MvcEntry:GetCtrl(TeamCtrl):QueryMultiTeamInfoReq(ReqTeamIdList)
    end
end

-- 检测各种申请中的队伍状态
function M:CheckMergeItemsTeamState()
    for TypeId,MergeItem in pairs(self.MergeItemType2Item) do
        if MergeItem and MergeItem.CheckTeamState then
            MergeItem:CheckTeamState()
        end
    end
end

-- 定时回调
function M:OnSchedule()
    if not CommonUtil.IsValid(self) then
        self:CleanAutoCheckTimer()
        print("FriendMainMdt Already Released")
        return
    end
    
    if self.CurTabId == FriendMainMdt.MenTabKeyEnum.Friend then
        self:CheckTeamState()
    end
    -- 界面打开期间，轮询推荐人员的状态和组队情况
    self.RecommendCtrl:CheckShowListState()
end

-- 定时检测队伍状态
function M:ScheduleCheckTeamState()
    self:CleanAutoCheckTimer()
    self.CheckTimer = Timer.InsertTimer(self.AutoTeamCheckTime,function()
        self:OnSchedule()
	end,true)   
end

function M:CleanAutoCheckTimer()
    if self.CheckTimer then
        Timer.RemoveTimer(self.CheckTimer)
    end
    self.CheckTimer = nil
end

--[[
    更新合并项展示列表数据
]]
function M:UpdateMergeItemShowDatas()
    self.MergeItemFlag = {}
    self.MergeItemType2Index = {}
    self.MergeItemType2Item = {}
    local List = {}
    -- 申请入队列表合并项
    local RequestList = MvcEntry:GetModel(TeamRequestApplyModel):GetTeamRequestDataList()
    if RequestList and #RequestList > 0  then
        self.MergeItemFlag[FriendConst.LIST_TYPE_ENUM.TEAM_REQUEST] = 1
        table.insert(List,RequestList[1])
    end
    -- 邀请加入队伍列表合并项
    local InviterList =  MvcEntry:GetModel(TeamInviteApplyModel):GetTeamInviteApplyList()
    if InviterList and #InviterList > 0  then
        self.MergeItemFlag[FriendConst.LIST_TYPE_ENUM.TEAM_INVITE_REQUEST] = 1
        table.insert(List,InviterList[1])
    end
    -- 合并队伍列表合并项
    local MergeRecvList = MvcEntry:GetModel(TeamMergeApplyModel):GetTeamMergeDataList()
    if MergeRecvList and #MergeRecvList > 0  then
        self.MergeItemFlag[FriendConst.LIST_TYPE_ENUM.TEAM_MERGE_REQUEST] = 1
        table.insert(List,MergeRecvList[1])
    end
    -- 好友申请列表合并项
    local ApplyList = MvcEntry:GetModel(FriendApplyModel):GetApplyList()
    if ApplyList and #ApplyList > 0  then
        self.MergeItemFlag[FriendConst.LIST_TYPE_ENUM.FRIEND_REQUEST] = 1
        table.insert(List,ApplyList[1])
    end
    self.MergeItemDataList = List
end

--[[
    更新好友项展示列表数据
]]
function M:UpdateFriendItemShowDatas()
    self.TeamKey2Index = {}
    self.PlayerId2TeamKey = {}
    self.PlayerId2Index = {}
    local List = {}
    local FriendList = MvcEntry:GetModel(FriendModel):GetFriendDataList()
    local OnlineNum = MvcEntry:GetModel(FriendModel):GetOnlineFriendNum()
    local TeamModel = MvcEntry:GetModel(TeamModel)
    self.IsShowRecommend = MvcEntry:GetModel(RecommendModel):IsShowSpecialShowList()
    -- self.IsListEmpty = false
    if #FriendList == 0 and #self.MergeItemDataList == 0 then
        List[#List + 1] = self:GetEmptyShowData()
        if self.IsShowRecommend then
            List[#List + 1] = self:GetTeamRecommendShowData(false)
        end
        -- self.IsListEmpty = true
    elseif OnlineNum == 0 then
        -- 没有一个在线的，直接先插入组队推荐数据
        if self.IsShowRecommend then
            List[#List + 1] = self:GetTeamRecommendShowData(true)
        end
    end
    for I,Data in ipairs(FriendList) do
        local PlayerId = Data.Vo.PlayerId
        local IsInTeam = TeamModel:IsInTeam(PlayerId)
        if IsInTeam then
            -- 判断是否全员离线
            local Members = TeamModel:GetTeamMembers(PlayerId)
            local IsAllMemberOffline = TeamModel:CheckIsAllMemberOffline(Members)
            if not IsAllMemberOffline then
                local TeamId = TeamModel:GetTeamId(PlayerId)
                local TeamKey = self:ConvertTeamId2Key(TeamId)
                -- 没有同队伍的队伍项展示，才加入列表
                if not self.TeamKey2Index[TeamKey] then
                    -- 界面可能会更新List中的数据，拷贝一份副本，防止直接改到源数据
                    List[#List + 1] = DeepCopy(Data)
                    local Index = #self.MergeItemDataList + #List
                    self.TeamKey2Index[TeamKey] = Index
                    self.PlayerId2Index[PlayerId] = Index
                else
                    self.PlayerId2Index[PlayerId] = self.TeamKey2Index[TeamKey]
                end
                self.PlayerId2TeamKey[PlayerId] = TeamKey
            else
                -- 队伍全员离线，不显示为队伍了
                List[#List + 1] = DeepCopy(Data)
                self.PlayerId2Index[PlayerId] = #self.MergeItemDataList + #List
            end
        else
            List[#List + 1] = DeepCopy(Data)
            self.PlayerId2Index[PlayerId] = #self.MergeItemDataList + #List
        end

        -- 检测是否最后一个在线人员，需要插入组队推荐数据
        if I == OnlineNum and self.IsShowRecommend then
            List[#List + 1] = self:GetTeamRecommendShowData(OnlineNum ~= #FriendList)
        end
    end
    self.FriendItemDataList = List
end

function M:ConvertTeamId2Key(TeamId)
    return "Team_"..TeamId
end

function M:ConvertTeamKey2Id(TeamKey)
    local s,e = string.find(TeamKey,"Team_") 
    if e then
        return tonumber(string.sub(TeamKey,e+1))
    else
        return nil 
    end
end

-- 好友页签内 - 特殊推荐列表数据更新
function M:OnSpecialRecommendListUpdate()
    local IsShowRecommend = MvcEntry:GetModel(RecommendModel):IsShowSpecialShowList()
    if IsShowRecommend ~= self.IsShowRecommend then
        self:RefreshFriendItems()
    end
end


------------------- 组队推荐
function M:GetTeamRecommendShowData(IsShowLine)
    local Data = {
        TypeId = FriendConst.LIST_TYPE_ENUM.TEAM_RECOMMEND,
        Vo = {
            IsShowLine = IsShowLine
        }
    }
    return Data
end

function M:GetEmptyShowData()
    local Data = {
        TypeId = FriendConst.LIST_TYPE_ENUM.EMPTY
    }
    return Data
end

function M:DoReloadRecommendList(NotScrollToStart)
    self.RecommendList = MvcEntry:GetModel(RecommendModel):GetCanShowRecommendList()
    local IsEmpty = #self.RecommendList == 0
    self.EmptyState:SetVisibility(IsEmpty and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.WBP_ReuseListEx:SetVisibility(IsEmpty and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    if not IsEmpty then
        self.ItemList = {}
        self.WBP_ReuseListEx:Reload(#self.RecommendList + 1) -- 最后有个换一批item
        self.NeedSrollToStart = not NotScrollToStart
    end
end

function M:UpdateTabRecommendItem(Widget,FixIndex)
    if FixIndex > #self.RecommendList then
        if not self.RecommendChangeListItem then
            local Cls = require("Client.Modules.Friend.FriendItems.FriendTeamRecommendChangeListItem")
            self.RecommendChangeListItem = UIHandler.New(self,Widget,Cls).ViewInstance
        end
    else
        local Data = self.RecommendList[FixIndex]
        if Data == nil then
            return
        end
        
        local Item = self.Widget2RecommendItem[Widget]
        if not Item then
            local Cls = require("Client.Modules.Friend.FriendItems.Inner.FriendTeamRecommendItemInner")
            Item = UIHandler.New(self,Widget,Cls,Data).ViewInstance
            self.Widget2RecommendItem[Widget] = Item
        end
        Item:UpdateListShow(Data)
        self.ItemList[FixIndex] = Item
    end
end

function M:OnRecommendListUpdate(IsAll)
    if self.CurTabId == FriendMainMdt.MenTabKeyEnum.Recommend then
        self:DoReloadRecommendList(not IsAll)
    end
end

function M:OnCloseViewByAction()
    self:PlayDynamicEffectOnShow(false)
end

function M:On_vx_hall_invite_close_Finished()
    MvcEntry:GetModel(TeamModel):DispatchType(TeamModel.ON_NOTIFY_TEAM_AND_CHAT_IN_OR_OUT_BY_ACTION, false)
    MvcEntry:CloseView(ViewConst.FriendMain)
end

-- 监听其他界面打开
function M:OnOtherViewShowed(ViewId)
    if ViewId == self.viewId then
        return
    end
    
    if ViewId == ViewConst.PlayerInfo then
        MvcEntry:CloseView(ViewConst.FriendMain)
    end
end

-- todo tbt暂时屏蔽，放cbt1接入
-- function M:OnShowListByAction()
--     if self.VXE_Hall_Team_InvitedItem_Open then
--         self:VXE_Hall_Team_InvitedItem_Open()
--     end
-- end

-- function M:OnHideListByAction()
--     if self.VXE_Hall_Team_InvitedItem_Close then
--         self:VXE_Hall_Team_InvitedItem_Close()
--     end
-- end


return M