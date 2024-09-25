--[[好友数据模型]]
require("Client.Modules.Friend.FriendApplyModel")
local super = ListModel;
local class_name = "FriendModel";
---@class FriendModel : GameEventDispatcher
---@type FriendModel
FriendModel = BaseClass(super, class_name);
FriendModel.ON_FRIEND_LIST_UPDATED = "ON_FRIEND_LIST_UPDATED"
FriendModel.ON_HIDE_HALL_TIPS = "ON_HIDE_HALL_TIPS"
FriendModel.ON_QUERY_PLAYERID = "ON_QUERY_PLAYERID"
FriendModel.ON_STAR_FLAG_CHANGED = "ON_STAR_FLAG_CHANGED"
FriendModel.ON_INTIMACY_CHANGED = "ON_INTIMACY_CHANGED"
FriendModel.ON_PLAYERSTATE_CHANGED = "ON_PLAYERSTATE_CHANGED"
FriendModel.ON_GET_PLAY_TOGETHER_TIME = "ON_GET_PLAY_TOGETHER_TIME"
FriendModel.ON_GET_IN_RECENT_GAMES_PLAYERIDS = "ON_GET_IN_RECENT_GAMES_PLAYERIDS"
FriendModel.ON_GET_LAST_ONLINE_TIME = "ON_GET_LAST_ONLINE_TIME"
FriendModel.ON_COOPERATION_INFO_CHANGED = "ON_COOPERATION_INFO_CHANGED"
FriendModel.ON_ADD_FRIEND = "ON_ADD_FRIEND"
FriendModel.ON_USE_INTIMACY_ITEM_SUCCESS = "ON_USE_INTIMACY_ITEM_SUCCESS"
FriendModel.ON_CLOSE_FRIENDVIEW_BY_ACTION = "ON_CLOSE_FRIENDVIEW_BY_ACTION" --通过行为关闭界面
FriendModel.ON_SHOW_FRIENDVIEW_LIST_BY_ACTION = "ON_SHOW_FRIENDVIEW_LIST_BY_ACTION" --通过行为控制列表展开
FriendModel.ON_HIDE_FRIENDVIEW_LIST_BY_ACTION = "ON_HIDE_FRIENDVIEW_LIST_BY_ACTION" --通过行为控制列表隐藏

--[[
    重写父方法，返回唯一Key
]]
function FriendModel:KeyOf(Vo)
    return Vo["PlayerId"]
end

--[[
    重写父方法，数据变动更新子类数据
]]
function FriendModel:SetIsChange(value)
    FriendModel.super.SetIsChange(self,value)
    self.IsFriendListChanged = value
end

function FriendModel:__init()
    self:_dataInit()
end

function FriendModel:_dataInit()
    -- 大厅玩家状态 -> 好友在线状态
    self.LobbyState2FriendState = {
        [Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE] = FriendConst.PLAYER_STATE_ENUM.PLAYER_OFFLINE,
        [Pb_Enum_PLAYER_STATE.PLAYER_LOGIN] = FriendConst.PLAYER_STATE_ENUM.PLAYER_SINGLE,
        [Pb_Enum_PLAYER_STATE.PLAYER_LOBBY] = FriendConst.PLAYER_STATE_ENUM.PLAYER_SINGLE,
        [Pb_Enum_PLAYER_STATE.PLAYER_TEAM] = FriendConst.PLAYER_STATE_ENUM.PLAYER_INTEAM,
        [Pb_Enum_PLAYER_STATE.PLAYER_MATCH] = FriendConst.PLAYER_STATE_ENUM.PLAYER_MATCHING,
        [Pb_Enum_PLAYER_STATE.PLAYER_BATTLE] = FriendConst.PLAYER_STATE_ENUM.PLAYER_GAMING,
        [Pb_Enum_PLAYER_STATE.PLAYER_SETTLE] = FriendConst.PLAYER_STATE_ENUM.PLAYER_SINGLE,
        [Pb_Enum_PLAYER_STATE.PLAYER_CUSTOMROOM] = FriendConst.PLAYER_STATE_ENUM.PLAYER_CUSTOMROOM,
    }

    self.IsListInited = false
    self.IsFriendListChanged = true
    self.FriendList = {}
    self.PlayerId2Friend = {}
    self.PlayerName2Friend = {}
    self.InRecentGameIdList = {}
    self.PlayerLastOnlineTimeList = {}
    self.PlayerIdsFriendsList = {}
    self.NewFriendIds = {}
    self.FriendMianTabIndex = FriendMainMdt.MenTabKeyEnum.Friend
end

--[[
    玩家登出时调用
]]
function FriendModel:OnLogout(data)
    FriendModel.super.OnLogout(self)
    self:_dataInit()
end

-- --[[
--     获取好友主界面的显示列表
--     - 申请入队列表合并项
--     - 邀请加入队伍列表合并项
--     - 好友申请列表合并项
--     - 好友列表
-- ]]
-- function FriendModel:GetFriendMainListShow()
--     local List = {}
--     -- 申请入队列表合并项
--     local RequestList = MvcEntry:GetModel(TeamRequestApplyModel):GetTeamRequestDataList()
--     if RequestList and #RequestList > 0  then
--         table.insert(List,RequestList[1])
--     end
--     -- 邀请加入队伍列表合并项
--     local InviterList =  MvcEntry:GetModel(TeamInviteApplyModel):GetTeamInviteApplyList()
--     if InviterList and #InviterList > 0  then
--         table.insert(List,InviterList[1])
--     end
--     -- 合并队伍列表合并项
--     local MergeRecvList = MvcEntry:GetModel(TeamMergeApplyModel):GetTeamMergeDataList()
--     if MergeRecvList and #MergeRecvList > 0  then
--         table.insert(List,MergeRecvList[1])
--     end
--     -- 好友申请列表合并项
--     local ApplyList = MvcEntry:GetModel(FriendApplyModel):GetApplyList()
--     if ApplyList and #ApplyList > 0  then
--         table.insert(List,ApplyList[1])
--     end
--     -- 好友列表
--     local FriendList = self:GetFriendDataList()
--     local TeamModel = MvcEntry:GetModel(TeamModel)
--     for _,Data in ipairs(FriendList) do
--         -- 策划又要求不隐藏了，先注释
--         -- 在队伍中的不展示在好友列表
--         -- if not TeamModel:GetData(Data.Vo.PlayerId) then
--             table.insert(List,Data)
--         -- end
--     end
--     return List
-- end

----------------------------------------------------------------------------------------
-- 好友列表数据初始化完成标记
function FriendModel:SetInited()
    self.IsListInited = true
    self:CheckApplyTips()
end

function FriendModel:IsInited()
    return self.IsListInited
end

--[[
    是否玩家的好友
]]
function FriendModel:IsFriend(PlayerId)
    PlayerId = tonumber(PlayerId)
    self:CheckDataInit()
    if MvcEntry:GetModel(UserModel):IsSelf(PlayerId) then
        --玩家自身非好友
        return false
    end
    return self.PlayerId2Friend[PlayerId] or false
end

--[[
    是否玩家的好友
]]
function FriendModel:IsFriendByName(PlayerName)
    self:CheckDataInit()
    return self.PlayerName2Friend[PlayerName] or false
end

--[[
    获取好友状态
    ---@param State - FriendConst.PLAYER_STATE
]]
function FriendModel:GetFriendState(PlayerId)
    self:CheckDataInit()
    local Data = self:GetData(PlayerId)
    if Data then
        return Data.State
    end
    return nil
end

--[[
    获取好友的状态（服务器状态）
    ---@param PlayerState - Lobby.proto PlayerState
]]
function FriendModel:GetFriendPlayerState(PlayerId)
    self:CheckDataInit()
    local Data = self:GetData(PlayerId)
    if Data then
        return Data.PlayerState
    end
    return nil
end

--[[
    查看好友是否在线
]]
function FriendModel:IsFriendOnline(PlayerId)
    PlayerId = tonumber(PlayerId)
    if MvcEntry:GetModel(UserModel):IsSelf(PlayerId) then
        return true
    end
    local State = self:GetFriendState(PlayerId)
    if not State then
        return false
    end
    return State ~= FriendConst.PLAYER_STATE_ENUM.PLAYER_OFFLINE
end

--[[
    好友人数上限
]]
function FriendModel:GetFriendMaxLimit()
    if not self.FriendMaxLimit then
        self.FriendMaxLimit = CommonUtil.GetParameterConfig(ParameterConfig.MaxFriendsNum,100)
    end
    return self.FriendMaxLimit
end

--[[
    检测好友人数是否达上限，是的话弹错误
]]
function FriendModel:CheckIsFriendListFull()
    local Result = self:IsFriendListFull();
    if Result then
        MvcEntry:GetCtrl(ErrorCtrl):PopErrorSync(ErrorCode.FriendNumMax.ID)
    end
    return Result
end

--[[
    是否好友人数已达上限
]]
function FriendModel:IsFriendListFull()
    local FriendList = self:GetFriendDataList();
    return #FriendList >= self:GetFriendMaxLimit()
end

--[[
    是否好友列表为空
]]
function FriendModel:IsFriendListEmpty()
    local FriendList = self:GetFriendDataList();
    return #FriendList == 0
end

-- 通过好友Id获取好友名称
function FriendModel:GetPlayerNameByPlayerId(PlayerId)
    self:CheckDataInit()
    local Data = self:GetData(PlayerId)
    if Data then
        return Data.PlayerName
    end
    return ""
end

-- 获取在线好友人数
function FriendModel:GetOnlineFriendNum()
    self:CheckDataInit()
    return self.OnlineNum
end

-- 获取好友全部人数
function FriendModel:GetAllFriendNum()
    local FriendDataList = self:GetFriendDataList()
    return #FriendDataList
end

-- 根据亲密值获取对应等级和icon
function FriendModel:GetIntimacyImgIcon(IntimacyValue)
    local IntimacyLv,IntimacyIconPath,IntimacyImgPath = 0,nil,nil
    local Cfgs = G_ConfigHelper:GetDict(Cfg_IntimacyLevelCfg)
    for _, Cfg in ipairs(Cfgs) do
        if IntimacyValue >= Cfg[Cfg_IntimacyLevelCfg_P.IntimacyValue] then
            IntimacyLv = Cfg[Cfg_IntimacyLevelCfg_P.IntimacyLevel]
            IntimacyIconPath = Cfg[Cfg_IntimacyLevelCfg_P.IntimacyIcon]
            IntimacyImgPath = Cfg[Cfg_IntimacyLevelCfg_P.IntimacyImg]
        else
            break
        end
    end
    return IntimacyLv,IntimacyIconPath,IntimacyImgPath
end
------------------------------------------------------------------

function FriendModel:CheckDataInit()
    -- 数据变化 重新刷新列表
    if #self.FriendList == 0 or self.IsFriendListChanged then
        self.FriendList = {}
        self.PlayerId2Friend = {}
        self.PlayerName2Friend = {}
        local OnlineNum = 0
        local DataList = self:GetDataList()
        local UserModel = MvcEntry:GetModel(UserModel)
        local PersonalInfoModel = MvcEntry:GetModel(PersonalInfoModel)
        local StateOffline = FriendConst.PLAYER_STATE_ENUM.PLAYER_OFFLINE
        for k,v in ipairs(DataList) do
            local FriendBaseNode = DataList[k]
            local PlayerId = FriendBaseNode.PlayerId
            -- local CacheQueryState = UserModel:GetPlayerCacheState(PlayerId)
            -- if CacheQueryState then
            --     -- 如果有缓存的轮询玩家状态，更新为该状态
            --     FriendBaseNode.PlayerState = CacheQueryState
            -- end
            local BaseInfo = PersonalInfoModel:GetCachePlayerDetailInfo(PlayerId)
            if BaseInfo then
                -- 如果有缓存的轮询玩家信息，玩家更新为该名称
                FriendBaseNode.PlayerName = BaseInfo.PlayerName
            end
            self.PlayerId2Friend[PlayerId] = true
            if FriendBaseNode.PlayerName then
                self.PlayerName2Friend[FriendBaseNode.PlayerName] = true
            end
            local FriendData = self:TransformToFriendShowData(FriendBaseNode)
            table.insert(self.FriendList,FriendData)
            if FriendData.Vo.State ~= StateOffline then
                OnlineNum = OnlineNum + 1
            end
        end
        self.OnlineNum = OnlineNum
        self:SortList(self.FriendList)
        self.IsFriendListChanged = false
    end
end

-- 好友列表排序
--[[
    SortType:   FriendConst.LIST_SORT_TYPE = {
                    DEFAULT = 1,  -- 默认排序
                    INTIMACY = 2,  -- 亲密度降序
                    FIRSTWORD = 3,  -- 首字母降序
                }
    默认排序：   1. 在线玩家>离线玩家
                2. 星标 > 普通
                3. 亲密度 高 -> 低
                4. 首字母 A - Z; 中文 -> 拼音 ； 日文 -> 五十音图
]]
function FriendModel:SortList(List,SortType)
    local LIST_SORT_TYPE = FriendConst.LIST_SORT_TYPE
    SortType = SortType or LIST_SORT_TYPE.DEFAULT
    local StateOffline = FriendConst.PLAYER_STATE_ENUM.PLAYER_OFFLINE
    if SortType == LIST_SORT_TYPE.DEFAULT then
        -- 默认排序
        table.sort(List,function (a,b)
                -- 在线玩家>离线玩家
            if a.Vo.State == StateOffline and b.Vo.State ~= StateOffline then
                return false
            elseif a.Vo.State ~= StateOffline and b.Vo.State == StateOffline then
                return true
            else
                if a.Vo.StarFlag ~= b.Vo.StarFlag then
                    -- 星标 > 普通
                    return a.Vo.StarFlag
                elseif a.Vo.IntimacyValue ~= b.Vo.IntimacyValue then
                    -- 亲密度 高 -> 低
                    return a.Vo.IntimacyValue > b.Vo.IntimacyValue
                else
                    -- 首字母
                    return StringUtil.CompareFirstWord(a.Vo.PlayerName,b.Vo.PlayerName)
                end
            end
        end)
    elseif SortType == LIST_SORT_TYPE.INTIMACY then
        -- 亲密度降序
        table.sort(List,function (a,b)
            if a.Vo.IntimacyValue ~= b.Vo.IntimacyValue then
                -- 亲密度 高 -> 低
                return a.Vo.IntimacyValue > b.Vo.IntimacyValue
            end
        end)
    elseif SortType == LIST_SORT_TYPE.FIRSTWORD then
        -- 首字母
        table.sort(List,function (a,b)
            return StringUtil.CompareFirstWord(a.Vo.PlayerName,b.Vo.PlayerName)
        end)
    end
end

--[[
    筛选列表
]]
function FriendModel:FliterList(FliterType)
    local FriendList = self:GetFriendDataList()
    if FliterType == FriendConst.LIST_FILTER_TYPE.ALL then
        return FriendList
    elseif FliterType == FriendConst.LIST_FILTER_TYPE.ONLINE then
        -- 最近在线：最近3天内有在线行为
        local FilterList = {}
        local CurTime = GetTimestamp()
        for _,FriendData in pairs(FriendList) do
            local PlayerId = FriendData.Vo.PlayerId
            local PlayerState = FriendData.Vo.PlayerState.Status
            local LastOnlineTime = self.PlayerLastOnlineTimeList[PlayerId] or 0
            if PlayerState ~= Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE or 
                (LastOnlineTime > 0 and CurTime - LastOnlineTime <= 3*24*3600) then
                FilterList[#FilterList + 1] = FriendData
            end
        end
        return FilterList
    elseif FliterType == FriendConst.LIST_FILTER_TYPE.PLAY_TOGETHER then
        -- 最近组队：玩家近30场内和对方有组队进行游戏行为
        local FilterList = {}
        for _,FriendData in pairs(FriendList) do
            local PlayerId = FriendData.Vo.PlayerId
            if self.InRecentGameIdList and self.InRecentGameIdList[PlayerId] then
                FilterList[#FilterList + 1] = FriendData
            end
        end
        return FilterList
    end
end

--[[
    获取好友列表数据
]]
function FriendModel:GetFriendDataList()
    self:CheckDataInit()
    return self.FriendList
end

--[[ 
    将协议数据 FriendBaseNode 转化为界面所需的格式
]]
function FriendModel:TransformToFriendShowData(FriendBaseNode)
    -- 兼容新的玩家状态结构
    local NeedConvert = false
    if not FriendBaseNode.State then
        FriendBaseNode.State = self.LobbyState2FriendState[FriendBaseNode.PlayerState.Status]
    end
    local FriendData = {
        TypeId = FriendConst.LIST_TYPE_ENUM.FRIEND,
        Vo = {
            State = FriendBaseNode.State,
            PlayerState = FriendBaseNode.PlayerState,
            PlayerName = FriendBaseNode.PlayerName,
            PlayerId = FriendBaseNode.PlayerId,
            IntimacyValue = FriendBaseNode.IntimacyValue,
            StarFlag = FriendBaseNode.StarFlag,
        }
    }
    return FriendData
end

--[[ 
    大厅玩家状态 -> 好友显示状态 
]]
function FriendModel:ConvertLobbyState2FriendState(LobbyState)
    return self.LobbyState2FriendState[LobbyState] or FriendConst.PLAYER_STATE_ENUM.PLAYER_OFFLINE
end

--[[
    存储删除操作的玩家id和名字 - 用于飘字提示
]]
function FriendModel:SaveDeletePlayerInfo(PlayerId)
    local FriendData = self:GetData(PlayerId)
    if FriendData then
        self.DeletedPlayerInfo = {}
        self.DeletedPlayerInfo.PlayerId = FriendData.PlayerId
        self.DeletedPlayerInfo.PlayerName = FriendData.PlayerName
    end
end

--[[
    删除好友飘字
]]
function FriendModel:ShowDeleteFriendTips(PlayerId)
    if self.DeletedPlayerInfo and self.DeletedPlayerInfo.PlayerId == PlayerId then
        local TipsArgs = {self.DeletedPlayerInfo.PlayerName}
        MvcEntry:GetCtrl(ErrorCtrl):PopTipsSync(TipsCode.FriendDeleted.ID,"",TipsArgs)
        self.DeletedPlayerInfo = nil
    end
end

--[[
    检测是否有主界面提示需要弹出，包含
    - 好友申请
    - 邀请组队申请
    - 申请入队申请
    - 队伍合并申请
]]
function FriendModel:CheckApplyTips()
    if not self.IsListInited then
        -- 需要好友数据初始化完成再进行弹窗提示
        return
    end
    local List = {}
    -- 好友申请
    local FriendApply = MvcEntry:GetModel(FriendApplyModel):GetFriendApplyTipsData();
    if FriendApply then
        List[#List+1] = FriendApply
    end
     -- 邀请组队
     local TeamInvite = MvcEntry:GetModel(TeamInviteApplyModel):GetTeamInviteTipsData()
     if TeamInvite then
         List[#List+1] = TeamInvite
     end
    -- 申请入队
    local TeamRequest = MvcEntry:GetModel(TeamRequestApplyModel):GetTeamRequestTipsData()
    if TeamRequest then
        List[#List+1] = TeamRequest
    end
    -- 队伍合并
    local TeamMerge = MvcEntry:GetModel(TeamMergeApplyModel):GetTeamMergeTipsData()
    if TeamMerge then
        List[#List+1] = TeamMerge
    end
    if #List > 0 then
        table.sort(List,function (A,B)
            return A.Time < B.Time
        end)
        MvcEntry:OpenView(ViewConst.FriendRequestItemList,List)
    end
end

-- 更好好友状态
function FriendModel:UpdatePlayerState(FriendInfoList)
    if not FriendInfoList or #FriendInfoList == 0 then
        return
    end
    -- 先更新UserModel对玩家状态的缓存，避免这里更新了那边还需要通过再次请求才能更新状态
    self:SyncPlayerStatusToUserModel(FriendInfoList)
    -- 再更新自身数据
    self:UpdateDataForProperty(FriendInfoList,{"PlayerState"})
    self:DispatchType(FriendModel.ON_PLAYERSTATE_CHANGED,FriendInfoList)
end

-- 更新亲密度
function FriendModel:UpdateIntimacy(FriendInfoList)
    if not FriendInfoList or #FriendInfoList == 0 then
        return
    end
    self:UpdateDataForProperty(FriendInfoList,{"IntimacyValue"})
    self:DispatchType(FriendModel.ON_INTIMACY_CHANGED,FriendInfoList)
end

-- 更新合作信息 （共同游戏时长，次数）
function FriendModel:UpdateCooperationData(FriendInfoList)
    if not FriendInfoList or #FriendInfoList == 0 then
        return
    end
    self:UpdateDataForProperty(FriendInfoList,{"PlayCount","PlayTime"})
    self:DispatchType(FriendModel.ON_COOPERATION_INFO_CHANGED,FriendInfoList)
end

-- 更新好友数据的某个字段
function FriendModel:UpdateDataForProperty(FriendInfoList,PropertyNames)
    local StateOffline = FriendConst.PLAYER_STATE_ENUM.PLAYER_OFFLINE
    for _, FriendBaseNode in ipairs(FriendInfoList) do
        local PlayerId = FriendBaseNode.PlayerId
        if PlayerId then
            local FriendData = self:GetData(PlayerId)
            if FriendData then
                for _,PropertyName in pairs(PropertyNames) do
                    if FriendData[PropertyName] ~= nil and FriendBaseNode[PropertyName] ~= nil then
                        if PropertyName == "PlayerState" then
                            local IsNewFriend = self.NewFriendIds[PlayerId]
                            -- 状态更新比较特殊，只更新里面的一级状态字段，二级展示状态由usermodel进行轮询更新
                            FriendData[PropertyName].Status = FriendBaseNode[PropertyName].Status
                            FriendData.State = self.LobbyState2FriendState[FriendBaseNode[PropertyName].Status]
                            if FriendData.State == StateOffline then
                                if IsNewFriend then
                                    -- 新好友需要去服务器查询上次离线时间
                                    MvcEntry:GetCtrl(FriendCtrl):SendPlayerLookUpLastOnlineTimeReq({PlayerId})
                                else
                                    -- 更新最近离线时间
                                    self.PlayerLastOnlineTimeList[PlayerId] = GetTimestamp()
                                end
                            end
                            self.NewFriendIds[PlayerId] = nil
                        else
                            FriendData[PropertyName] = FriendBaseNode[PropertyName]
                        end
                    end
                end
            end
        end
    end
    self:SetIsChange(true)
end

-- 覆盖基类方法
function FriendModel:SetDataList(FriendInfoList)
    -- 先更新UserModel对玩家状态的缓存，避免这里更新了那边还需要通过再次请求才能更新状态
    self:SyncPlayerStatusToUserModel(FriendInfoList)
    -- 再更新自身数据
    FriendModel.super.SetDataList(self,FriendInfoList,true)
end

-- 更新UserModel对玩家状态的缓存
function FriendModel:SyncPlayerStatusToUserModel(FriendInfoList)
    ---@type UserModel
    local UserModel = MvcEntry:GetModel(UserModel)
    if not UserModel then
        return
    end
    for _,FriendBaseNode in ipairs(FriendInfoList) do
        -- UpdateMap[FriendBaseNode.PlayerId] = FriendBaseNode.PlayerState
        UserModel:SyncPlayerStatusCache(FriendBaseNode.PlayerId,FriendBaseNode.PlayerState)
    end
end

-- 从UserModel更新状态 暂时仅判断DisplayStatus
function FriendModel:SyncPlayerStatus(PlayerId,PlayerStateInfo)
    local Data = self:GetData(PlayerId)
    if (Data and Data.PlayerState and 
         Data.PlayerState.DisplayStatus ~= PlayerStateInfo.DisplayStatus) then
        -- 只更新二级状态 一级状态会通过推送，优先级更高
        Data.PlayerState.DetailStatus = PlayerStateInfo.DetailStatus
        Data.PlayerState.DisplayStatus = PlayerStateInfo.DisplayStatus
        self:SetIsChange(true)
    end
end

-- 更新好友星标状态
function FriendModel:UpdateFriendStarFlag(PlayerId,StarFlag)
    local Data = self:GetData(PlayerId)
    if not Data then
        CError("FriendModel UpdateFriendStarFlag Error! PlayerId = "..PlayerId,true)
        return
    end
    Data.StarFlag = StarFlag
    self:SetIsChange(true)    
    self:DispatchType(FriendModel.ON_STAR_FLAG_CHANGED,PlayerId)
end

function FriendModel:ShowAddFriendTips(AddMap)
    -- 不在局内才提示
    if not MvcEntry:GetModel(TeamModel):CanPopTeamTips() then
        return
    end
    
    for _,FriendBaseNode in ipairs(AddMap) do
        local Param = {
            TipsViewType = FriendConst.TEAM_NOTICE_ITEM_TYPE.SINGLE,
            Type = FriendConst.TEAM_SHOW_TIPS_TYPE.ADD_FRIEND,
            Member = FriendBaseNode
        }
        MvcEntry:OpenView(ViewConst.TeamNoticeItemList,Param)
    end
end

-- 记录添加好友的模块id（已废弃）
function FriendModel:SetAddFriendModule(GameModuleId)
    self.AddFriendModuleId = GameModuleId
end

function FriendModel:ClearAddFriendModule(GameModuleId)
    if self.AddFriendModuleId == GameModuleId then
        self.AddFriendModuleId = nil
    end
end

-- 获取记录的添加好友的模块id（已废弃）
function FriendModel:GetAddFriendModule(TargetPlayerId)
    if not self.AddFriendModuleId then
        if MvcEntry:GetModel(TeamModel):IsSelfTeamMember(TargetPlayerId) then
            -- 如果是自己的队友,模块为好友组队
            return GameModuleCfg.FriendTeam.ID
        end
        CWaring("GetAddFriendModule Error !")
        return GameModuleCfg.Invalid
    end
    return self.AddFriendModuleId
end

-- 获取好友亲密度
function FriendModel:GetFriendIntimacy(PlayerId)
    local FriendData = self:GetData(PlayerId)
    if FriendData then
        return FriendData.IntimacyValue
    end
end

-- 存储最近组队的好友id列表
function FriendModel:SaveInRecentGameIdList(PlayerIdList)
    self.InRecentGameIdList = {}
    for _,PlayerId in ipairs(PlayerIdList) do
        self.InRecentGameIdList[PlayerId] = 1
    end
end

-- 存储玩家的最近在线时间
function FriendModel:SavePlayersLastOnlineTime(PlayerIdList)
    self.PlayerLastOnlineTimeList = {}
    for _,LastOnlineTimeNode in ipairs(PlayerIdList) do
        self.PlayerLastOnlineTimeList[LastOnlineTimeNode.PlayerId] = LastOnlineTimeNode.LastOnlineTime
    end
end


--[[
    判断InPlayerId是否是TargetPlayerId的好友
]]
function FriendModel:IsFriendFromTargetPlayerId()
    for k, Value in pairs(self.PlayerIdsFriendsList) do
        if Value > 0 then
            return true
        end
    end
    return false
end

--[[
    判断InPlayerId是否是TargetPlayerId的好友，缓存
]]
function FriendModel:UpdateFriendPlayerIdToTargetPlayerId(InTargetPlayerId, InFriendsMap)
    -- self.CheckFriendByFriendCout = self.CheckFriendByFriendCout + 1
    -- if not self.PlayerIdsFriendsList[InTargetPlayerId] then
    --     self.PlayerIdsFriendsList[InTargetPlayerId] = {}
    -- end

    for Key, Value in pairs(InFriendsMap) do
        table.insert(self.PlayerIdsFriendsList, Value)
    end
end

--[[
    缓存当前选中Tab
]]
function FriendModel:SaveNowTabIndex(InIndex)
    self.FriendMianTabIndex = InIndex
end

function FriendModel:GetNowTabIndex()
    return self.FriendMianTabIndex
end

--[[
    记录新增的好友id，用于判断是否查询上次离线时间
    因为服务器处理新增好友是先推送好友数据，再通过另一条协议同步该好友的玩家状态
]]
function FriendModel:RecordNewFriendIds(AddMap)
    for _,FriendBaseNode in ipairs(AddMap) do
        self.NewFriendIds[FriendBaseNode.PlayerId] = 1
    end
end


return FriendModel;