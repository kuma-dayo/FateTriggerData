--[[
    好友管理 - 页签 - 好友列表
]]

local class_name = "FriendManagerTabFriendList"
local FriendManagerTabFriendList = BaseClass(UIHandlerViewBase, class_name)


function FriendManagerTabFriendList:OnInit()
    self.InputFocus = true
    ---@type FriendModel
    self.FriendModel = MvcEntry:GetModel(FriendModel)
    self.MsgList = 
    {
        {Model = FriendModel, MsgName = FriendModel.ON_ADD_FRIEND, Func = Bind(self,self.UpdateFriendList)},
        {Model = FriendModel, MsgName = ListModel.ON_DELETED, Func = Bind(self,self.UpdateFriendList)},
        {Model = FriendModel, MsgName = FriendModel.ON_PLAYERSTATE_CHANGED, Func = Bind(self,self.UpdateFriendList)},
        {Model = FriendModel, MsgName = FriendModel.ON_STAR_FLAG_CHANGED, Func = Bind(self,self.UpdateFriendList)},
        {Model = FriendModel, MsgName = FriendModel.ON_GET_IN_RECENT_GAMES_PLAYERIDS, Func = Bind(self,self.SortAndFilterList,true)},
        {Model = FriendModel, MsgName = FriendModel.ON_GET_LAST_ONLINE_TIME, Func = Bind(self,self.SortAndFilterList,true)},
    }

    self.BindNodes = {
		{ UDelegate = self.View.AddFriendBtn.GUIButton_Main.OnClicked,				Func = Bind(self,self.GUIButton_AddFriend_ClickFunc) },
		{ UDelegate = self.View.WBP_ReuseList_Friend.OnUpdateItem,				Func = Bind(self,self.OnUpdateItem) },
		{ UDelegate = self.View.WBP_ReuseList_Friend.OnReleaseItem,				Func = Bind(self,self.OnReleaseItem) },
        
    }
    -- self.SubClassList = {}

    local Btn = UIHandler.New(self, self.View.CommonBtnTips_AddFriend, WCommonBtnTips, 
    {
        OnItemClick = Bind(self, self.GUIButton_AddFriend_ClickFunc),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabFriendList_Addfriends_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.SpaceBar
    }).ViewInstance
    -- self.SubClassList[#self.SubClassList + 1] = Btn
    self:InitComboBox()
end

-- 初始化下拉框
function FriendManagerTabFriendList:InitComboBox()
    -- 筛选
    local FilterList = {
        [1] = {ItemDataString = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabFriendList_all"))},
        [2] = {ItemDataString = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabFriendList_Recentlyonline"))},
        [3] = {ItemDataString = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabFriendList_Recentlyformedateam"))},
    }

    self.FliterComboBox = UIHandler.New(self, self.View.FilterComboBox, CommonComboBox, {
        OptionList = FilterList, 
        DefaultSelect = 1,
        SelectCallBack = Bind(self, self.OnSelectFilterChanged)
    }).ViewInstance

    -- 排序
    local Sortist = {
        [1] = {ItemDataString = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabFriendList_default"))},
        [2] = {ItemDataString = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabFriendList_Intimacy"))},
        [3] = {ItemDataString = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "Lua_FriendManagerTabFriendList_initialletter"))},
    }

    self.SortComboBox = UIHandler.New(self, self.View.SortComboBox, CommonComboBox, {
        OptionList = Sortist, 
        DefaultSelect = 1,
        SelectCallBack = Bind(self, self.OnSelectSortChanged)
    }).ViewInstance
end

function FriendManagerTabFriendList:OnShow()
    self:UpdateFriendList()
end
function FriendManagerTabFriendList:OnManualShow()
    self:UpdateFriendList()
end

function FriendManagerTabFriendList:OnHide()
    self.Widget2ItemCls = {}
    -- self.Index2Widget = {}
    MvcEntry:GetModel(FriendOpLogModel):ClearAllOpLogList()

    -- 切到其他页，重置下筛选项
    self.FilterType = nil
    self.FliterComboBox:ForceChangeSelect(1)
    self.SortType = nil
    self.SortComboBox:ForceChangeSelect(1)
    -- self.IsHide = true
end

-- function FriendManagerTabFriendList:OnCustomShow()
--     if self.Widget2ItemCls then
--         for Widget,ItemCls in pairs(self.Widget2ItemCls) do
--             if CommonUtil.IsValid(Widget) and ItemCls.OnCustomShow then
--                 ItemCls:OnCustomShow()
--             end
--         end
--     end
--     if self.IsHide then 
--         if self.MsgList then
--             CommonUtil.MvcMsgRegisterOrUnRegister(self,self.MsgList,true)
--         end
--         if self.SubClassList then
--             for _,Btn in ipairs(self.SubClassList) do
--                 CommonUtil.MvcMsgRegisterOrUnRegister(Btn,Btn.MsgList,true)
--             end
--         end
--         self.IsHide = false
--     end
--     self:UpdateFriendList()
-- end

-- function FriendManagerTabFriendList:OnCustomHide()
--     if self.Widget2ItemCls then
--         for Widget,ItemCls in pairs(self.Widget2ItemCls) do
--             if CommonUtil.IsValid(Widget) and ItemCls.OnCustomHide then
--                 ItemCls:OnCustomHide()
--             end
--         end
--     end
--     if self.MsgList then
--         CommonUtil.MvcMsgRegisterOrUnRegister(self,self.MsgList,false)
--     end
--     if self.SubClassList then
--         for _,Btn in ipairs(self.SubClassList) do
-- 		    CommonUtil.MvcMsgRegisterOrUnRegister(Btn,Btn.MsgList,false)
--         end
--     end
--     -- 切到其他页，重置下筛选项
--     self.FilterType = nil
--     self.FliterComboBox:ForceChangeSelect(1)
--     self.SortType = nil
--     self.SortComboBox:ForceChangeSelect(1)
--     self.IsHide = true
-- end

function FriendManagerTabFriendList:UpdateUI()
    self.Widget2ItemCls = {}
    self:UpdateFriendList()
end

-- 更新好友列表显示
function FriendManagerTabFriendList:UpdateFriendList()
    self.FriendList = self.FriendModel:GetFriendDataList()
    local TotalNum = #self.FriendList
    self:SortAndFilterList()
    local NumberAfterFilter = #self.FriendList
    if TotalNum > 0 then
        self.View.Switcher_Content:SetActiveWidget(self.View.FriendListContent)
        self.View.GUIText_TotalNum:SetText("/"..TotalNum)
        local OnlineNum = self.FriendModel:GetOnlineFriendNum()
        self.View.GUIText_OnlineNum:SetText(OnlineNum)
        self:DoReload(NumberAfterFilter)
    else
        self.View.Switcher_Content:SetActiveWidget(self.View.EmptyContent)
    end
end

-- 根据当前的排序和筛选过一遍数据
function FriendManagerTabFriendList:SortAndFilterList(IsReload)
    -- 先筛选
    self.FilterType = self.FilterType or FriendConst.LIST_FILTER_TYPE.ALL
    self.FriendList = self.FriendModel:FliterList(self.FilterType)
    -- 再排序
    self.SortType = self.SortType or FriendConst.LIST_SORT_TYPE.DEFAULT
    self.FriendModel:SortList(self.FriendList,self.SortType)
    
    if IsReload then
        self:DoReload(#self.FriendList)
    end
end

function FriendManagerTabFriendList:DoReload(TotalNum)
    self.View.WBP_ReuseList_Friend:Reload(TotalNum)
end

function FriendManagerTabFriendList:OnUpdateItem(_, Widget, I)
    local Index = I + 1
    -- self.Index2Widget[Index] = Widget
    local FriendData = self.FriendList[Index]
    local ItemCls = self.Widget2ItemCls[Widget]
    if not ItemCls then
        ItemCls = UIHandler.New(self,Widget,require("Client.Modules.Friend.FriendManage.FriendManagerTabFriendListItem")).ViewInstance
        self.Widget2ItemCls[Widget] = ItemCls
    end
    ItemCls:UpdateUI(FriendData)
end

function FriendManagerTabFriendList:OnReleaseItem(_,Widget)
    local ItemCls = self.Widget2ItemCls[Widget]
    if ItemCls and ItemCls.OnCustomHide then
        ItemCls:OnCustomHide()
    end
end

--弹出手动添加好友界面
function FriendManagerTabFriendList:GUIButton_AddFriend_ClickFunc()
    MvcEntry:OpenView(ViewConst.FriendAdd)
end

-- 筛选 - 下拉框
function FriendManagerTabFriendList:OnSelectFilterChanged(Index,InInit)
    if InInit or not self.FriendList then
        return
    end
    self.FilterType = Index
   
    if self.FilterType == FriendConst.LIST_FILTER_TYPE.ONLINE then
        -- 最近在线，需要拉取离线玩家的最后在线时间
        local PlayerIdList = {}
        local AllFriendList = self.FriendModel:GetFriendDataList()
        for _,FriendData in pairs(AllFriendList) do
            if FriendData.Vo.PlayerState.Status == Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE then
                PlayerIdList[#PlayerIdList + 1] = FriendData.Vo.PlayerId
            end
        end
        if #PlayerIdList > 0 then
            MvcEntry:GetCtrl(FriendCtrl):SendPlayerLookUpLastOnlineTimeReq(PlayerIdList)
        else
            self:SortAndFilterList(true)
        end
    elseif self.FilterType == FriendConst.LIST_FILTER_TYPE.PLAY_TOGETHER then
        -- 共同组队，需要请求一遍数据
        MvcEntry:GetCtrl(FriendCtrl):SendFriendsInRecentGamesReq()
    else
        self:SortAndFilterList(true)
    end
end

-- 排序 - 下拉框
function FriendManagerTabFriendList:OnSelectSortChanged(Index,InInit)
    if InInit or not self.FriendList or #self.FriendList <= 1 then
        return
    end
    self.SortType = Index
    self:SortAndFilterList(true)
end

return FriendManagerTabFriendList