local super = GameEventDispatcher;
local class_name = "EventTrackingModel";

---@class EventTrackingModel : GameEventDispatcher
---@field private super GameEventDispatcher
EventTrackingModel = BaseClass(super, class_name);

EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID = "ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID" --界面页签切换
EventTrackingModel.ON_SHOP_EVENTTRACKING_CLICK = "ON_SHOP_EVENTTRACKING_CLICK" --商店埋点点击事件
EventTrackingModel.ON_ICON_EVENTTRACKING_CLICK = "ON_ICON_EVENTTRACKING_CLICK" --icon_click_flow埋点点击事件
EventTrackingModel.ON_HERO_INFO_EVENTTRACKING = "ON_HERO_INFO_EVENTTRACKING" --英雄交互埋点
EventTrackingModel.ON_FRIEND_FLOW_EVENTTRACKING = "ON_FRIEND_FLOW_EVENTTRACKING" --好友流水埋点
EventTrackingModel.ON_LOADING_FLOW_EVENTTRACKING = "ON_LOADING_FLOW_EVENTTRACKING" --loading界面日志埋点
EventTrackingModel.Enum_PLAYER_CLIENT_HALL_STATE = require("Client.Modules.User.ConstPlayerState").Enum_PLAYER_CLIENT_HALL_STATE                 --客户端大厅状态
--EventTrackingModel.ON_VOICE_EVENTTRACKING = "ON_VOICE_EVENTTRACKING" --语音埋点

EventTrackingModel.IsOpen = true --总开关

EventTrackingModel.SHOP_ACTION = {
    DEFAULT_VIEW = 1, --默认浏览
    CLICK_AND_VIEW = 2, --点击并浏览 (捆绑包专属)
    CLICK_ENTER_TO_CONTENT = 3, --点击进入详情页
    CLICK_BUY = 4, --点击购买
}

EventTrackingModel.ONCLICKED_HALLTAB_NAME = {
    "开始游戏",
    "先觉者",
    "战备",
    "商店",
    "赛季"
}

EventTrackingModel.SHOP_BELONG_TYPE = {
    BUNDLE = 1, --是捆绑包
    NOBUNDLE = 0
}

EventTrackingModel.VOICESCENE = {
    INGAME = 1, --局内
    OUTSIDEGAME = 2 --局外
}

EventTrackingModel.SHOP_BUY_TYPE = {
    NOT_BUY = 0, --非购买,仅浏览
    BUY_SINGLE = 1, --购买单品
    BUY_BUNDLE = 2, --购买捆绑包
}

EventTrackingModel.CLICKHEROACTSCENE = { --203308101-戳英雄,203308111-阅读英雄故事
    HALL = 203308101,
    READ = 203308111
}

EventTrackingModel.OpenType = {
    OnShow = 1,
    OnClose = 2
}

EventTrackingModel.FRIEND_FLOW_SOURCE = { --好友操作来源
    CHAT_IN_WORLD = 202, --公共聊天频道(点击头像添加好友)
    CHAT_IN_TEAM = 205, --组队聊天(点击头像添加好友)
    LAYER_SETTLEMENT = 206, --结算界面(点击头像添加好友)
    FRIEND_BLACK_LIST = 104, --黑名单
    SCORE_HISTORY = 207, --历史战绩
    COMMON_HEAD = 300, --个人信息
    PERSON_INFO = 301,
    RECENT_VISITOR = 302, --最近访客
    FRIEND_SEARCH_ID = 101, --好友搜索
    IN_TEAM_AS_OTAL_STRANGER = 208, --组队中(同队陌生人且非同队好友的好友)
    IN_TEAM_AS_FRIENDS_OF_FRIENDS = 209, --组队中(同队陌生人且同队好友的好友)
    LAYER_IN_TEAM_RECOMMONDATION1 = 210, --组队推荐界面1(好友页签)
    LAYER_IN_TEAM_RECOMMONDATION2 = 211, --组队推荐界面2(推荐页签)
    FRIEND_TEAM = 102 --兼容原来好友组队添加来源
}

EventTrackingModel.FRIEND_FLOW_ACTION = {
    APPLY_FOR_FRIEND = 101506101, --申请好友
    THROUGH_FRIENDS = 101506102, --通过申请
    REFUSAL_OF_APPLICATION = 101506103, --拒绝申请
    DELETE_FRIEND = 101506111, --删除好友
    ADD_TO_BLACK_LIST = 101506112, --拉黑
    REMOVE_FROM_BLACK_LIST = 101506113, --移除拉黑
}

--将状态数字转换为描述
EventTrackingModel.Enum_PLAYER_STATE_TO_DESC = {
    [Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE] = "离线中",
    [Pb_Enum_PLAYER_STATE.PLAYER_LOGIN] = "登陆中",
    [Pb_Enum_PLAYER_STATE.PLAYER_LOBBY] = "大厅中",
    [Pb_Enum_PLAYER_STATE.PLAYER_TEAM] = "组队中",
    [Pb_Enum_PLAYER_STATE.PLAYER_CUSTOMROOM] = "自建房中",
    [Pb_Enum_PLAYER_STATE.PLAYER_MATCH] = "匹配中",
    [Pb_Enum_PLAYER_STATE.PLAYER_BATTLE] = "战斗中",
    [Pb_Enum_PLAYER_STATE.PLAYER_SETTLE] = "结算中"
}

function EventTrackingModel:__init()
    self.View2AlreadOpened = {}
    self.View2OpenTime = {}
    --TODO 这边需要根据打开和关闭记录UI栈，然后用于你取值打开某个界面的上层来源
    --跟随先进后出原则
    self.UIStack = {
        Last = {},
        Now = {}
    }
    self.UIClickedList = {}
    self.HeroReadData = {} --当前英雄阅读上报数据缓存
    self.OpenViewId = 0
    self.fct_tab = nil
    self.upper_layer = nil
    self.duration = 0
    self.is_daily_frist = 0
    self.voice_begin_time = 0
    self.last_apply_friendId = 0
    self.OnHeroViewDuration = 0
    self.ShopEnterSource = 0
    self.FriendAddSourceByTeam = 0
    self.LoadingFlowDurationNowTime = 0
    self.LoadingType = LoadingCtrl.TypeEnum.BATTLE_TO_HALL
    self.ShopItemLoadIndex = 0 --商品加载索引
    self.ShopItemsIdTemp = {} --用于记录加载商品Id时的去重
    self.AfkFlowDurationNowTime = GetLocalTimestamp() --记录afk_flow标记时间
    self.UIViewIdBlackList = { --上报ViewID黑名单
        [ViewConst.MessageBoxSystem] = ViewConst.MessageBoxSystem,
        [ViewConst.TeamAndChat] = ViewConst.TeamAndChat,
        [ViewConst.VirtualLogin] = ViewConst.VirtualLogin,
        [ViewConst.VirtualHall] = ViewConst.VirtualHall,
        [ViewConst.MessageBox] = ViewConst.MessageBox,
        [ViewConst.CommonPlayerInfoHoverTip] = ViewConst.CommonPlayerInfoHoverTip,
        [ViewConst.CommonKeyWordTips] = ViewConst.CommonKeyWordTips,
        [ViewConst.GMPanel] = ViewConst.GMPanel,
        [ViewConst.CommonBtnOperate] = ViewConst.CommonBtnOperate,
        [ViewConst.CommonItemTips] = ViewConst.CommonItemTips,
        [ViewConst.CommonBaseTip] = ViewConst.CommonBaseTip,
        [ViewConst.CommonHoverTips] = ViewConst.CommonHoverTips,
        [ViewConst.ItemGet] = ViewConst.ItemGet,
        [ViewConst.SpecialItemGet] = ViewConst.SpecialItemGet,
        [ViewConst.ItemUsePop] = ViewConst.ItemUsePop,
        [ViewConst.ShopDetailPop] = ViewConst.ShopDetailPop
    }

    self.UIViewIdByIconClicked = { --Icon点击ViewId白名单
        [ViewConst.Hall] = ViewConst.Hall,
        [ViewConst.Questionnaire] = ViewConst.Questionnaire,
        [ViewConst.ActivityMain] = ViewConst.ActivityMain,
        [ViewConst.MailMain] = ViewConst.MailMain,
        [ViewConst.DepotMain] = ViewConst.DepotMain,
        [ViewConst.SystemMenu] = ViewConst.SystemMenu,
        [ViewConst.FriendManagerMain] = ViewConst.FriendManagerMain
    }
end

function EventTrackingModel:_dataInit()
    
end

function EventTrackingModel:OnLogout()
    
end

--[[
    上报界面信息，含页签
    local ViewParam = {
        ViewId = Int,
        TabId = Str
    }
]]
-- function EventTrackingModel:ReqOnViewFlow(ViewParam)
--     self:DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
-- end

function EventTrackingModel:UpdateViewFlowData(InIsOpen, ViewId, InViewParam)
    local ReqOnViewFlowData = SaveGame.GetItem("ReqOnViewFlowData") or {}
    self.View2AlreadOpened = ReqOnViewFlowData.View2AlreadOpened or {}
    self.View2OpenTime = ReqOnViewFlowData.View2OpenTime or {}

    self.View2AlreadOpened = self:TableFormat(self.View2AlreadOpened)
    self.View2OpenTime = self:TableFormat(self.View2OpenTime)

    self.OpenViewId = ViewId

    local viewTable = {}

    if InIsOpen then --记录第一次访问标记
        if #viewTable < 1 then
            table.insert(viewTable, ViewId)
            --table.insert(self.UIStack, viewTable)
        end

        local ViewTabId = InViewParam and InViewParam.TabId or nil
        
        if ViewTabId then
            if #viewTable > 1 then
                self.fct_tab = self:GetFctTab()
                self.upper_layer = self:GetUpperLayer()
                local tabKey = self:GetViewTabKey()
                if self.View2OpenTime[tabKey] then
                    self.duration  = os.difftime(GetTimestamp(), self.View2OpenTime[tabKey])
                end
                self.is_daily_frist = self:isCrossDay(self.View2OpenTime[tabKey], GetTimestamp()) and 1 or 0
                MvcEntry:GetCtrl(EventTrackingCtrl):ReqFunctionViewFlow(ViewId, false, self.duration, self.is_daily_frist)
                table.remove(viewTable)
            end
            table.insert(viewTable, ViewTabId)
        end

        if #self.UIStack.Now < 1 then
            self.UIStack.Now = viewTable
        else
            if self.UIStack.Now[1] ~= ViewId then
                self.UIStack.Last = self.UIStack.Now
                self.UIStack.Now = viewTable
            else
                if ViewTabId then
                    self.UIStack.Now = viewTable
                end
            end
        end

        local tabKey = self:GetViewTabKey()

        if self.View2AlreadOpened[tabKey] then
            if self.View2OpenTime[tabKey] then
                self.is_daily_frist = self:isCrossDay(self.View2OpenTime[tabKey], GetTimestamp()) and 1 or 0
            end
        end
        self.View2OpenTime[tabKey] = GetTimestamp()
        self.View2AlreadOpened[tabKey] = 1

        if InViewParam and InViewParam.Name then
            if self.UIViewIdByIconClicked[ViewId] and ViewId ~= ViewConst.ActivityMain then
                --[[
                    【埋点】ICON点击上报
                ]]
                local TabData = {
                    icon_name = InViewParam.Name,
                    fct_type = ViewId,
                }
                self:AddIconDataToList(TabData)
            end
        end
    else
        local tabKey = self:GetViewTabKey()
        if self.View2OpenTime[tabKey] then
            self.duration  = os.difftime(GetTimestamp(), self.View2OpenTime[tabKey])
        end
        if self.View2AlreadOpened[tabKey] then
            self.View2AlreadOpened[tabKey] = 0
        end
        self.View2OpenTime[tabKey] = nil

        --self.UIStack.Last = self.UIStack.Now
        
    end

    ReqOnViewFlowData = {
        View2AlreadOpened = self.View2AlreadOpened,
        View2OpenTime = self.View2OpenTime
    }

    SaveGame.SetItem("ReqOnViewFlowData", ReqOnViewFlowData)

    self.fct_tab = self:GetFctTab()
    self.upper_layer = self:GetUpperLayer()
end

--[[
    缓存每次点击按钮的icon_click_flow数据，在用户离线或长度达到500个后自动推送
]]
function EventTrackingModel:AddIconDataToList(InIconData)
    if not self.IsOpen then return end
    --self.UIClickedList = {}
    local result = nil
    for _, subTable in ipairs(self.UIClickedList) do
        if subTable.icon_name == InIconData.icon_name and subTable.fct_type == InIconData.fct_type then --表示已存在
            result = subTable
            subTable.click_count = subTable.click_count + 1
            break
        end
    end

    if not result then
        result = {
            icon_name = InIconData.icon_name,
            fct_type = InIconData.fct_type,
            fct_tab = self:GetFctTab(),
            click_count = 1
        }
        table.insert(self.UIClickedList, result)
    end

    self:ReqIconClicked(result)

    -- if #self.UIClickedList >= 500 then
    --     self:ReqIconClicked()
    -- end

    return result
end

function EventTrackingModel:ReqIconClicked(InResultTable)
    self:DispatchType(EventTrackingModel.ON_ICON_EVENTTRACKING_CLICK, InResultTable)
end

function EventTrackingModel:ClearUIClickedList()
    self.UIClickedList = {}
end


function EventTrackingModel:GetUIClickedList()
    return self.UIClickedList
end


function EventTrackingModel:GetViewTabKey()
    local viewTable = self.UIStack.Now
    if not viewTable then
        return ""
    end
    local tabKey = ""
    for index, tabStr in pairs(viewTable) do
        tabKey = #tabKey < 1 and ("" .. tabStr) or (tabKey .. "-" .. tabStr)
    end
    return tabKey
end

function EventTrackingModel:TableFormat(table)
    local newTable = {}
    for k, v in pairs(table) do
        newTable[tostring(k)] = v
    end
    return newTable
end

function EventTrackingModel:isCrossDay(timestamp1, timestamp2)
    local day1 = os.date("%Y-%m-%d", timestamp1)
    local day2 = os.date("%Y-%m-%d", timestamp2)
    if day1 ~= day2 then
        return true -- 跨天
    else
        return false -- 未跨天
    end
end

function EventTrackingModel:GetFctTab()
    if #self.UIStack.Now < 1 then
        return ""
    end

    local fct_tab = ""
    local viewTable = self.UIStack.Now

    for index, tabStr in pairs(viewTable) do
        if index > 1 then
            fct_tab = #fct_tab < 1 and ("" .. tabStr) or (fct_tab .. "-" .. tabStr)
        end
    end
    if #fct_tab < 1 then 
        fct_tab = "0" 
    end
    return fct_tab
end

function EventTrackingModel:GetUpperLayer(InIsOpen)
    return InIsOpen == nil and (self.UIStack.Last[1] or "") or (self.UIStack.Now[1] or "")
end

function EventTrackingModel:GetUpperLayerTab()
    if #self.UIStack.Last < 2 then
        return "0"
    end
    local upper_layer_tab = ""
    for index, data in pairs(self.UIStack.Last) do
        if index > 1 then
            upper_layer_tab = #upper_layer_tab < 1 and "0" or (upper_layer_tab .. "-" .. data)
        end
    end
    return upper_layer_tab
end


function EventTrackingModel:GetViewTable(ViewId)
    local result  = {}
    for index, uiData in pairs(self.UIStack) do
        if uiData[1] == ViewId then
            if #result < 1 then
                result = uiData
            end
            self.UIStack[index] = nil --清理冗余
        end
    end
    return result
end

function EventTrackingModel:SetVoiceIsStart()
    self.voice_begin_time = GetLocalTimestamp()
end

function EventTrackingModel:GetVoiceDuration()
    local updateTime = GetLocalTimestamp() - self.voice_begin_time
    local duration = os.time(os.date("*t", updateTime))
    
    if #(tostring(duration)) > 4 then
        duration = 0
    end
    return duration
end


function EventTrackingModel:GetView2OpenTimeByTabKey(tabKey)
    return self.View2OpenTime[tabKey]
end

function EventTrackingModel:GetView2AlreadOpenedByTabKey(tabKey)
    return self.View2AlreadOpened[tabKey]
end

function EventTrackingModel:IsDailyFrist()
    return self.is_daily_frist
end

function EventTrackingModel:GetDuration()
    return self.duration
end

--[[
    获取到页内具体某个Tab的Index
]]
function EventTrackingModel:GetNowTab()
    local result = {}
    local fctTab = self:GetFctTab()
    if not fctTab then
        return "0"
    end
    for substr in fctTab:gmatch("[^".. "-" .."]+") do
        table.insert(result, substr)
    end
    if #result < 1 then
        return fctTab
    end
    return result[#result]
end

function EventTrackingModel:GetNowViewId()
    return self.UIStack.Now[1] or ""
end


function EventTrackingModel:IsViewIdInBlackList(ViewId)
    -- for _, DataId in pairs(self.UIViewIdBlackList) do
    --     if DataId == ViewId then
    --         return true
    --     end
    -- end
    -- return false

    return self.UIViewIdBlackList[ViewId] and true or false
end

function EventTrackingModel:SetHeroReadData(InInfoIndex, InHeroId)
    self.HeroReadData = {
        info_index = InInfoIndex or 0,
        hero_id = InHeroId,
        into_type = "text"
    }
end

function EventTrackingModel:GetHeroReadData()
    return self.HeroReadData
end

function EventTrackingModel:GetLastApplyFriendId()
    return self.last_apply_friendId
end

--[[
    记录打开传记时开始时间
]]
function EventTrackingModel:SetHeroViewBegin(InTimestamp)
    self.OnHeroViewDuration = InTimestamp
end

function EventTrackingModel:GetHeroViewDuration()
    return GetLocalTimestamp() - self.OnHeroViewDuration
end

--[[
    记录打开商店时所处的界面
]]
function EventTrackingModel:SetShopEnterSource(InEnterSource)
    self.ShopEnterSource = InEnterSource
end

function EventTrackingModel:GetShopEnterSource()
    return self.ShopEnterSource
end

function EventTrackingModel:GetFriendAddSourceByTeam()
    return self.FriendAddSourceByTeam
end

function EventTrackingModel:CheckViewIsOpened(InViewId)
    return MvcEntry:GetModel(ViewModel):GetState(InViewId)
end

function EventTrackingModel:SetShopItemLoadIndex(InIndex)
    self.ShopItemLoadIndex = InIndex
end

function EventTrackingModel:GetShopItemLoadIndex()
    return self.ShopItemLoadIndex
end

function EventTrackingModel:ClearShopItemsIdTemp()
    self.ShopItemsIdTemp = {}
end

function EventTrackingModel:IsIdExistInShopItemsIdTemp(InId, InIndex)
    if self.ShopItemsIdTemp[InId] then
        return true
    else
        self.ShopItemsIdTemp[InId] = InIndex
        return false
    end
end

function EventTrackingModel:GetItemIndexFromShopItemsIdTemp(InId)
    return self.ShopItemsIdTemp[InId]
end

function EventTrackingModel:GetAfkDuration()
    local duration = GetLocalTimestamp() - self.AfkFlowDurationNowTime
    self.AfkFlowDurationNowTime = GetLocalTimestamp()
    return duration
end

--[[
    loading_flow埋点进入loading界面类型枚举
]]
function EventTrackingModel:SetLoadingType(InType)
    self.LoadingType = InType
    MvcEntry:GetModel(AchievementModel):SetLoadingType(InType)
end

function EventTrackingModel:GetLoadingType()
    return self.LoadingType
end

function EventTrackingModel:UpdateLoadingDurationNowTime()
    self.LoadingFlowDurationNowTime = GetLocalTimestamp()
end

function EventTrackingModel:GetLoadingDurationNowTime()
    return GetLocalTimestamp() - self.LoadingFlowDurationNowTime
end

function EventTrackingModel:GetFriendAddSource(InTargetPlayerId, InIsJumpCheckTeamFriend, InIsClear)
    local IsJumpCheckTeamFriend, IsClear = true, false
    
    if InIsJumpCheckTeamFriend ~= nil then
        IsJumpCheckTeamFriend = InIsJumpCheckTeamFriend
    end

    if InIsClear ~= nil then
        IsClear = InIsClear
    end

    local Source = 0
    self.last_apply_friendId = InTargetPlayerId
    local ViewId = self:GetNowViewId()
    local TeamModel = MvcEntry:GetModel(TeamModel)
    if MvcEntry:GetModel(FriendBlackListModel):GetData(InTargetPlayerId) then
        return self.FRIEND_FLOW_SOURCE.FRIEND_BLACK_LIST
    elseif self:CheckViewIsOpened(ViewConst.FriendMain) and ViewId ~= ViewConst.FriendAdd then
        local Tab = MvcEntry:GetModel(FriendModel):GetNowTabIndex()
        if Tab == FriendMainMdt.MenTabKeyEnum.Friend then
            Source = self.FRIEND_FLOW_SOURCE.LAYER_IN_TEAM_RECOMMONDATION1
        elseif Tab == FriendMainMdt.MenTabKeyEnum.Recommend then
            Source = self.FRIEND_FLOW_SOURCE.LAYER_IN_TEAM_RECOMMONDATION2
        end
    end

    if self:CheckViewIsOpened(ViewConst.Chat) then
        local ChatModel = MvcEntry:GetModel(ChatModel)
        local ChannelType = ChatModel:GetCurChatType()
        if ChannelType == Pb_Enum_CHAT_TYPE.TEAM_CHAT then
            return self.FRIEND_FLOW_SOURCE.CHAT_IN_TEAM
        elseif ChannelType == Pb_Enum_CHAT_TYPE.WORLD_CHANNEL_CHAT then
            return self.FRIEND_FLOW_SOURCE.CHAT_IN_WORLD
        end
    elseif self:CheckViewIsOpened(ViewConst.HallSettlement) then
        Source = self.FRIEND_FLOW_SOURCE.LAYER_SETTLEMENT
    elseif self:CheckViewIsOpened(ViewConst.PlayerInfo) then
        local PlayerInfoModel = MvcEntry:GetModel(PlayerInfoModel)
        local Tab = PlayerInfoModel:GetCurSelectTab()--self:GetNowTab() == "0" and 1 or tonumber(self:GetNowTab())
        if Tab == PlayerInfoModel.Enum_Tab.MatchHistoryPage then
            --战绩
            Source = self.FRIEND_FLOW_SOURCE.SCORE_HISTORY
        elseif Tab == PlayerInfoModel.Enum_Tab.PersonalInfoPage then
            --个人信息
            Source = self.FRIEND_FLOW_SOURCE.PERSON_INFO
        end
    elseif self:CheckViewIsOpened(ViewConst.MatchHistoryDetail) then
        Source = self.FRIEND_FLOW_SOURCE.SCORE_HISTORY
    elseif self:CheckViewIsOpened(ViewConst.FriendAdd) then
        Source = self.FRIEND_FLOW_SOURCE.FRIEND_SEARCH_ID
    elseif self:CheckViewIsOpened(ViewConst.FriendManagerLog) then
        Source = self.FRIEND_FLOW_SOURCE.COMMON_HEAD
    end

    if not IsJumpCheckTeamFriend then
        if IsClear then
            MvcEntry:GetModel(FriendModel).CheckFriendByFriendCout = 0
            MvcEntry:GetModel(FriendModel).PlayerIdsFriendsList = {}
        end
        local SourceCheckFriend = self:SetFriendAddSourceByTeam(InTargetPlayerId)
        if SourceCheckFriend < 0 then
            return 0
        end
    end

    if Source < 1 then
        if TeamModel:IsInTeam() then
            if Source == self.FRIEND_FLOW_SOURCE.LAYER_IN_TEAM_RECOMMONDATION1 or Source == self.FRIEND_FLOW_SOURCE.LAYER_IN_TEAM_RECOMMONDATION2 or Source == 0 then
                Source = self.FRIEND_FLOW_SOURCE.FRIEND_TEAM
            end
        end
    end

    if not Source or Source == 0 then
        Source = self.FRIEND_FLOW_SOURCE.COMMON_HEAD
    end

    return Source
end

function EventTrackingModel:SetFriendAddSourceByTeam(InTargetPlayerId)
    self.FriendAddSourceByTeam = 0
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local FriendModel = MvcEntry:GetModel(FriendModel)
    if TeamModel:IsInTeam() then
        local PlayerId = MvcEntry:GetModel(UserModel):GetPlayerId() 
        local TeamMenbers = TeamModel:GetTeamMembers(PlayerId)
        local HasFriend = false --有无存在好友关系
        if #FriendModel.PlayerIdsFriendsList < 1 then
            local PlayerIdList = {}
            for _, Menber in pairs(TeamMenbers) do
                if Menber.PlayerId ~= InTargetPlayerId then
                    table.insert(PlayerIdList, Menber.PlayerId)
                end
            end

            local ReqData = {
                TargetPlayerId = InTargetPlayerId,
                PlayerIdList = PlayerIdList
            }

            MvcEntry:GetCtrl(FriendCtrl):SendPlayerIsFriendReq(ReqData)
            return -1
        end

        HasFriend = FriendModel:IsFriendFromTargetPlayerId()

        if HasFriend then
            self.FriendAddSourceByTeam = self.FRIEND_FLOW_SOURCE.IN_TEAM_AS_FRIENDS_OF_FRIENDS
        else
            self.FriendAddSourceByTeam = self.FRIEND_FLOW_SOURCE.IN_TEAM_AS_OTAL_STRANGER
        end
    else
        if not FriendModel:IsFriend(InTargetPlayerId) then
            self.FriendAddSourceByTeam = 212
        end
    end
    return self.FriendAddSourceByTeam
end


return EventTrackingModel

