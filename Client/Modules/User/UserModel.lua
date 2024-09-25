--[[用户数据模型]]
local super = GameEventDispatcher;
local class_name = "UserModel";

---玩家状态相关
---    *标代表核心功能与函数，需要注意 2) & 5)
---
---    1) 当有玩家状态信息同步时，会触发 UserModel:UpdatePlayerStatusCache(newPlayerStatusInfo)
---    @see UserModel#UpdatePlayerStatusCache                       当有玩家信息更新时，存储到本地并触发对应的回调
---
---    * 2) 需要获取玩家状态的时候，请调用 UserModel:GetPlayerState(PlayerId, callback)
---    @see UserModel#GetPlayerState                                传入玩家Id或玩家Id列表，获取到对应数据后触发回调。如果需要取得的玩家数据过期了，则会等待数据回来时再触发回调。
---        这里会对需要请求的玩家id进行一个整理，对于还在时效性内的数据，会直接触发回调；
---        对于已经过了时效性的数据，会先进行请求，等待新的数据到来后再触发回调。
---        * 请注意传入的回调函数，如果是匿名函数的话则会触发很多次，因为每个匿名函数的地址都是不一样的。触发回调时无法对匿名函数进行去重。
---
---    3) 如果只想获取玩家的显示状态，则可以直接使用 UserModel:GetPlayerDisplayState(CheckedPlayerId, callbackFunc)
---    @see UserModel#GetPlayerDisplayState                         获取玩家的显示状态，如果数据过期了，就请求之后再返回
---        这里的大致用法和上一个函数 GetPlayerState 一样，只不过这里传入的回调函数中的参数进行了调整，只会传入一个string，适合用于更新text控件来展示玩家状态
---
---    4) 除此之外，还有三个函数，外部也可以使用，但是一般来说上面的俩个函数应该可以完成大部分的业务需求了，在使用前可以先思考一下是否有必要使用
---    @see UserModel#IsPlayerStatusOutOfDate                       检查玩家上次的状态是否已经过期，返回false意味着 1）没有数据 2）超过了默认状态过期时间
---    @see UserModel#RawGetPlayerLogicStateAndClientHallState      获取当前玩家的逻辑状态和显示状态，不触发更新（使用前请先确保有数据，最好在GetPlayerState的回调中使用）
---    @see UserModel#RawGetPlayerDisplayStateByPlayerID            仅获取玩家状态，不触发更新逻辑（使用前请先确保有数据，最好在GetPlayerState的回调中使用）
---    @see UserModel#GetPlayerDisplayStateFromPlayerState          允许外部通过传入一个玩家状态，转换为玩家显示状态
---
---    * 5) 如果需要告知后台前端的状态，则使用 UserModel:UpdatePlayerClientHallState(NewClientState)
---    @see UserModel#UpdatePlayerClientHallState                   发送给服务器，告知服务器客户端当前的显示状态
---        这里也对发送频率进行了限制，直接调用即可
---        但是这里需要结合实际情况来使用，建议先使用 ConstPlayerState.VIEW_ID_2_PLAYER_CLIENT_HALL_STATE_MAP 查看是否达成预期
---
---    6) 玩家状态的展示文字是基于 LogicState与ClientHallState 而定的，具体可以参考 UserModel:GetDisplayStateByLogicStateAndClientHallState(LogicState, ClientHallState, PlayerId)
---    @see UserModel#GetDisplayStateByLogicStateAndClientHallState
---        在已知LogicState与ClientHallState时，可以调用，如果想获取某一玩家的展示状态，请使用 GetPlayerDisplayState
---
---@alias Pb_Enum_PLAYER_STATE number | 'Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE' | 'Pb_Enum_PLAYER_STATE.PLAYER_LOGIN' | 'Pb_Enum_PLAYER_STATE.PLAYER_LOBBY' | 'Pb_Enum_PLAYER_STATE.PLAYER_TEAM' | 'Pb_Enum_PLAYER_STATE.PLAYER_MATCH' | 'Pb_Enum_PLAYER_STATE.PLAYER_BATTLE' | 'Pb_Enum_PLAYER_STATE.PLAYER_SETTLE'
---@class UserModel : GameEventDispatcher
UserModel = BaseClass(super, class_name);

--玩家状态相关
UserModel.PLAYER_STATE_DATA_OUT_OF_DATE = require("Client.Modules.User.ConstPlayerState").PlayerStateDataOutOfDate                      --玩家数据过期标识
UserModel.Enum_PLAYER_CLIENT_HALL_STATE = require("Client.Modules.User.ConstPlayerState").Enum_PLAYER_CLIENT_HALL_STATE                 --客户端大厅状态


--玩家帐号ID/OpenId被设置时的事件通知
UserModel.ON_OPEN_ID_SET = "ON_OPEN_ID_SET"

UserModel.ON_PLAYER_CREATE_FAIL = "ON_PLAYER_CREATE_FAIL"
UserModel.ON_QUERY_PLAYER_STATE_RSP = "ON_QUERY_PLAYER_STATE_RSP"
UserModel.ON_QUERY_MULTI_PLAYER_STATE_RSP = "ON_QUERY_MULTI_PLAYER_STATE_RSP"
UserModel.ON_COMMON_HEAD_HIDE = "ON_COMMON_HEAD_HIDE"

UserModel.ON_GET_PALYER_HEAD_LISR_RESULT = "UserModel.ON_GET_PALYER_HEAD_LISR_RESULT"

UserModel.ON_PLAYER_LV_CHANGE = "ON_PLAYER_LV_CHANGE"
UserModel.ON_PLAYER_EXP_CHANGE = "ON_PLAYER_EXP_CHANGE"
UserModel.ON_PLAYER_LEVEL_UP_SYC_DATA = "ON_PLAYER_LEVEL_UP_SYC_DATA"
UserModel.ON_GET_RANDOM_NAME = "ON_GET_RANDOM_NAME"
UserModel.ON_CHECK_NAME_VALID_RESULT = "ON_CHECK_NAME_VALID_RESULT"
UserModel.ON_MODIFY_NAME_SUCCESS = "ON_MODIFY_NAME_SUCCESS"
UserModel.ON_PLAYER_VALUE_ADD_CHANGED = "ON_PLAYER_VALUE_ADD_CHANGED"

function UserModel:__init()
    --服务器ID
    self.ServerId = 0
    --服务器IP
    self.Ip = ""
    --服务器端端口
    self.Port = 0
    
    --玩家输入的（或者SDK登录返回的角色ID）
    self.SdkOpenId = ""
    --SDKID
    self.SdkId = 0
    --SDKID下层分发ID
    self.Pid = ""
    --SDK登录需要发送给服务器进行校验的Token缓存
    self.Token = ""

    self.PlayerIdReConnect = 0;
    self.PlayerGameTokenReConnect = 0;

    --记录本地P4的分支名称和changeList 方便对比调试的
    self.PVersion = nil
    --记录大厅服的P4的分支名称和changeList
    self.GateVersion = nil
    --记录当前连服或者最后连接DS的P4的分支名称和changeList
    self.DSVersion = nil
    --记录当前战斗或者最后连接DS战斗的战斗ID
    self.DSGameId = nil
    
    ---这里记录玩家状态
    --当有请求加入时，会更新时间，当时间超过设定时间时就会发送，尽可能以列表形式发送请求，不拆分
    --后台限定最大单次请求量为50，所以不能让 RequireQueue 的大小超过50
    self.LastRequirePlayerStateTime = -1                                    --上一次请求的时间，两次请求之间的时间差不能太短
    ---@type number[]
    self.RequirePlayerStateList = {}                                        --请求列表(最多50个)
    ---@type number[]
    self.LeftRequirePlayerStateList = {}                                    --超过50个，或者没有赶上上一次请求的玩家id
    self._PlayerStateRequireTickTimer = nil                                 --更新玩家状态计时器句柄
    ---@type table<number, fun[]>
    self.GetPlayerStateCallback = { --[[ [playerId] = {fun, fun} --]] }     --获取玩家状态回调
    self.PlayerStateCache = {}                                              --记录获取到的玩家状态

    ---这里记录玩家状态
    self.LastUpdatePlayerClientHallState = nil                              --上一次发送协议时的状态
    self.PlayerLastClientHallState = nil                                    --客户端在一定时间内发送的最后一条大厅状态
    self.LastPlayerClientHallStateUpdateTime = -1                           --上一次客户端发送
    self._PlayerClientHallStateTickTimer = nil                              --更新客户端状态计时器句柄    

    ----走命令行参数的字段缓存
    self.IsLoginByCMD = false --是否通过CMD命令行获取的参数自动登录
    self.CMDLoginRoomID = 1006 --房间ID
    self.CMDLoginServerIP = ""
    self.CMDLoginServerPort = ""
    self.CMDLoginName = "" --玩家登录用户名
    self.CMDLoginConnectServerId = 1 --连接服务器ID
    self.CMDSelectHeroId = 0 --选择英雄Id

    ---自建房自动进入测试---
    --self.IsLoginByCMD = true    --是否通过CMD命令行获取的参数自动登录
    --self.CMDLoginServerIP = "10.70.174.74"
    --self.CMDLoginServerPort = "13751"
    --self.CMDLoginConnectServerId = 0
    --self.CMDLoginName = "CmdTest1003"
    --self.CMDLoginRoomID = 1     --房间ID
    --self.CMDSelectHeroId = 20020000

    -- 是否自动进入自建房
	self.IsAutoEnterCustomRoom = false
    -- 是否自动开启自建房对局
    self.IsAutoStartCustomRoom = false
	-- 自建房自动相关指令
	self.CMDAutoEnterCustomRoomCfg = {}
    ----------

    self.LocationInfo = nil

    self:DataInit()
end

--region ----------------- 玩家状态处理 -------------------
-----------------------------------------
----- 这一部分是用来获取服务器中玩家状态的 -----
-----------------------------------------

local _TryToBatchRequire

---打开请求Timer，按照固定时间间隔，向服务器发送想要请求的玩家id列表，获取玩家状态
---外部不应该直接使用，为了避免外部使用，调整为local函数，但是需要传入self来指明对象
---@param self UserModel
local function _StartRequirePlayerStateTimer(self)
    --CLog("[cw] _StartRequirePlayerStateTimer()")
    if self._PlayerStateRequireTickTimer then
        --CLog("[cw] self._PlayerStateRequireTickTimer is activated, do not need to reactive it.")
        return 
    end
    
    --CLog("[cw] active self._PlayerStateRequireTickTimer")
    local ConstPlayerState = require("Client.Modules.User.ConstPlayerState")
    self._PlayerStateRequireTickTimer = Timer.InsertTimer(
            ConstPlayerState.REQUEST_DELAY,
            function()
                _TryToBatchRequire(self)
            end,
            true)
end

---当没有需要请求的数据时，可以清空timer节省性能
---外部不应该直接使用，为了避免外部使用，调整为local函数，但是需要传入self来指明对象
---@param self UserModel
local function _StopRequirePlayerStateTimer(self)
    --CLog("[cw] _StopRequirePlayerStateTimer()")
    if not self._PlayerStateRequireTickTimer then
        --CLog("[cw] no time to stop")
        return 
    end
    
    --CLog("[cw] deactive self._PlayerStateRequireTickTimer")
    Timer.RemoveTimer(self._PlayerStateRequireTickTimer)
    self._PlayerStateRequireTickTimer = nil
end

---外部不应该直接使用，为了避免外部使用，调整为local函数，但是需要传入self来指明对象
---@param self UserModel
---@param toIndex
local function _ClearLeftRequirePlayerStateList(self, toIndex)
    --CLog("[cw] _ClearLeftRequirePlayerStateList(" .. string.format("%s, %s", self, toIndex) .. ")")
    --没有请求了，就清空timer吧
    if toIndex == #self.LeftRequirePlayerStateList then
        --CLog("[cw] Clear to the last item, so clear table and stop tick")
        self.LeftRequirePlayerStateList = {}
        _StopRequirePlayerStateTimer(self)
    else
        for i = toIndex, 1, -1 do
            table.remove(self.LeftRequirePlayerStateList, i)
        end
        --CLog("[cw] Some date left in self.LeftRequirePlayerStateList")
    end
end

---外部不应该直接使用，为了避免外部使用，调整为local函数，但是需要传入self来指明对象
---@param self UserModel
local function _BatchRequirePlayerState(self)
    --CLog("[cw] _BatchRequirePlayerState()")
    
    --1.把一部分不重复的且最多不超过50条请求从 LeftRequirePlayerStateList 移动到 RequirePlayerStateList
    local _LastIndex = 0
    local RequiredPlayerId = {}
    self.RequirePlayerStateList = {}
    local ConstPlayerState = require("Client.Modules.User.ConstPlayerState")
    for i, PlayerId in ipairs(self.LeftRequirePlayerStateList) do
        if not RequiredPlayerId[PlayerId] then
            table.insert(self.RequirePlayerStateList, PlayerId)
            RequiredPlayerId[PlayerId] = true
        end

        _LastIndex = i
        if #self.RequirePlayerStateList >= ConstPlayerState.MAX_REQUIRE_LIST_SIZE then break end
    end
    --CLog("[cw] finish regroup self.RequirePlayerStateList")
    --print_r(self.RequirePlayerStateList, "[cw] self.RequirePlayerStateList")
    
    --清除 LeftRequirePlayerStateList 已请求的玩家ID
    _ClearLeftRequirePlayerStateList(self, _LastIndex)
    --CLog("[cw] finish regroup self.LeftRequirePlayerStateList")
    --print_r(self.LeftRequirePlayerStateList, "[cw] self.LeftRequirePlayerStateList")

    ---@type UserCtrl
    local UserCtrl = MvcEntry:GetCtrl(UserCtrl)
    self.LastRequirePlayerStateTime = GetLocalTimestamp()
    --CLog("[cw] ====== SendQueryMultiPlayerStatusReq at time: " .. tostring(self.LastRequirePlayerStateTime) .. "======")
    --print_r(self.RequirePlayerStateList, "[cw] self.RequirePlayerStateList")
    UserCtrl:SendQueryMultiPlayerStatusReq(self.RequirePlayerStateList)
    --CLog("[cw] ====== SendQueryMultiPlayerStatusReq at time: " .. tostring(self.LastRequirePlayerStateTime) .. " end ======")
end

---外部不应该直接使用，为了避免外部使用，调整为local函数，但是需要传入self来指明对象
---@param self UserModel
_TryToBatchRequire = function(self)
    --CLog("[cw] ==== _TryToBatchRequire ===")
    
    local CurTime = GetLocalTimestamp()
    local ConstPlayerState = require("Client.Modules.User.ConstPlayerState")
    if math.abs(self.LastRequirePlayerStateTime - CurTime) < ConstPlayerState.MAX_REQUIRE_TIME_GAP then
        --CLog("[cw] The difference between CurTime(" .. tostring(CurTime) .. ") and LastRequireTime(" .. tostring(self.LastRequirePlayerStateTime) .. ") is less than " .. tostring(ConstPlayerState.MAX_REQUIRE_TIME_GAP) .. ", waite for the next tick")
        --CLog("[cw] ==== _TryToBatchRequire end ===")
        --_StartRequirePlayerStateTimer(self)
        return
    end

    _BatchRequirePlayerState(self)
    --CLog("[cw] ==== _TryToBatchRequire end ===")
end

---@return boolean 两个玩家状态是否有相同
local function _IsDifferentState(leftState, rightState)
    if not leftState and not rightState then return false end
    if not leftState or not rightState then return true end
    
    if leftState.DisplayStatus ~= rightState.DisplayStatus then return true end
    if leftState.Status ~= rightState.Status then return true end
    --暂时没有 DetailStatus 数据，不需要处理
    --if leftState.DetailStatus ~= rightState.DetailStatus then return true end
    
    --走到这里说明全部检查完了没有变动
    return false
end

---处理缓存数据写入，外部调用时请确保数据的及时性和正确性
---@param PlayerId number 玩家id
---@param PlayerState table 玩家状态数据，参考 message PlayerState
function UserModel:SyncPlayerStatusCache(PlayerId, PlayerState)
    self.PlayerStateCache[PlayerId] = PlayerState
    self.PlayerStateCache[PlayerId].UpdateTime = GetLocalTimestamp()
end

---当有玩家信息更新时，存储到本地并触发对应的回调
---@param newPlayerStatusInfo table 玩家状态信息
function UserModel:UpdatePlayerStatusCache(newPlayerStatusInfo)
    --CLog("[cw] ============ UserModel:UpdatePlayerStatusCache(" .. tostring(newPlayerStatusInfo) .. ") ============")
    --print_r(newPlayerStatusInfo, "[cw] newPlayerStatusInfo")
    
    ---@type FriendModel
    local FriendModel = MvcEntry:GetModel(FriendModel)
    --1.循环遍历更新的数据
    for PlayerId, PlayerStateInfo in pairs(newPlayerStatusInfo) do
        --CLog("[cw] ======================" .. tostring(PlayerId) .. "=========================")
        --CLog("[cw] handle player(" .. tostring(PlayerId) .. ")'s info update")

        --1.1.更新缓存，并判断是否需要更抛出事件或触发回调
        local bNeedUpdate = _IsDifferentState(self.PlayerStateCache[PlayerId], PlayerStateInfo)
        self:SyncPlayerStatusCache(PlayerId, PlayerStateInfo)
        
        --CLog("[cw]     1.update player state self.PlayerStateCache")
        --print_r(self.PlayerStateCache, "[cw] self.PlayerStateCache")

        --1.2.触发回调
        --1.2.1.遍历回调，然后进行触发
        local calledCallback = {}
        if not self.GetPlayerStateCallback[PlayerId] then
            -- CWaring("[cw] callbacks is nil rather than an empty table, something might wrong, please check it")
            -- CWaring(debug.traceback())
            -- CLog("[cw] ================= debug info =================")
            -- CLog("[cw] self.LastRequirePlayerStateTime: " .. tostring(self.LastRequirePlayerStateTime))
            -- print_r(self.RequirePlayerStateList, "[cw] self.RequirePlayerStateList")
            -- print_r(self.LeftRequirePlayerStateList, "[cw] self.LeftRequirePlayerStateList")
            -- print_r(self.GetPlayerStateCallback, "[cw] self.GetPlayerStateCallback")
            -- print_r(self.PlayerStateCache, "[cw] self.PlayerStateCache")
            -- CLog("[cw] ===================================================")
        else
            --仅需要在数据变动的时候更新一下
            if bNeedUpdate then
                for _, callback in ipairs(self.GetPlayerStateCallback[PlayerId]) do
                    --可能存在重复的callback，这里需要进行去重
                    if not calledCallback[callback] then
                        --CLog("[cw]         trigger callback(" .. tostring(callback) .. ") with param(" .. tostring(PlayerId) .. ", " .. tostring(PlayerStateInfo) .. ")")
                        callback(PlayerId, PlayerStateInfo)
                        calledCallback[callback] = true
                    end
                end
            end
        end
        --1.2.2.兼容事件
        if bNeedUpdate then
            local Msg = {
                PlayerId        = PlayerId,
                PlayerStateInfo = PlayerStateInfo
            }
            self:DispatchType(self.ON_QUERY_PLAYER_STATE_RSP, Msg)
        end
        --1.2.3.遍历完后进行清空
        self.GetPlayerStateCallback[PlayerId] = nil
        --CLog("[cw]     2.Clear self.GetPlayerStateCallback of player." .. tostring(PlayerId) .. "")
        --1.2.4 同步给好友Model更新状态 避免两边不同步
        FriendModel:SyncPlayerStatus(PlayerId,PlayerStateInfo)

        --1.3.整理列表，不用再次请求相同的数据
        for i = #self.LeftRequirePlayerStateList, 1, -1 do
            if self.LeftRequirePlayerStateList[i] == PlayerId then
                table.remove(self.LeftRequirePlayerStateList, i)
            end
        end
        --CLog("[cw]     3.Clear data which id is " .. tostring(PlayerId) .. " in self.LeftRequirePlayerStateList")
        --CLog("[cw] ======================" .. tostring(PlayerId) .. " end =========================")
    end
    --CLog("[cw] ========= UserModel:UpdatePlayerStatusCache(" .. tostring(newPlayerStatusInfo) .. ") end =========")
    
    --2.如果没有请求了就停掉Timer
    if #self.LeftRequirePlayerStateList == 0 and self._PlayerStateRequireTickTimer then
        --CLog("[cw] #self.LeftRequirePlayerStateList == 0, stop tick timer")
        _StopRequirePlayerStateTimer(self)
    end
    --CLog("[cw] ============ UserModel:UpdatePlayerStatusCache(" .. tostring(newPlayerStatusInfo) .. ") end ============")
end

---检查玩家上次的状态是否已经过期，返回false意味着 1）没有数据 2）超过了默认状态过期时间
---@param CheckedPlayerId number 需要检查的玩家id
---@return boolean 玩显示状态是否过期
function UserModel:IsPlayerStatusOutOfDate(CheckedPlayerId)
    --1.没有数据，返回true
    local PlayerStatusInfo = self.PlayerStateCache[CheckedPlayerId]
    if not PlayerStatusInfo then
        --CLog("[cw] UserModel:IsPlayerStatusOutOfDate(" .. tostring(CheckedPlayerId) .. ") return true, cause no cache data")
        return true 
    end

    --2.数据时效性超过默认值，返回true
    local CurTime = GetLocalTimestamp()
    local ConstPlayerState = require("Client.Modules.User.ConstPlayerState")
    if math.abs(PlayerStatusInfo.UpdateTime - CurTime) > ConstPlayerState.OUT_OF_DATE_TIME_OFFSET then
        --CLog("[cw] UserModel:IsPlayerStatusOutOfDate(" .. tostring(CheckedPlayerId) .. ") return true, cause cache data out of date")
        return true
    end

    --3.有数据且在时效性内，返回false
    --CLog("[cw] UserModel:IsPlayerStatusOutOfDate(" .. tostring(CheckedPlayerId) .. ") return false")
    return false
end

---获取单个玩家的数据
---     数据没有过期 - 直接触发回调
---     数据过期    - 加入队列，等待数据回包后再触发回调
---外部不应该直接使用，为了避免外部使用，调整为local函数，但是需要传入self来指明对象
---@param self UserModel
---@param PlayerId number 需要请求的玩家ID
---@param callback fun(PlayerId:number, PlayerInfo:table):void 得到数据后的回调
local function _GetPlayerStateSingle(self, PlayerId, callback)
    --1.如果有缓存，先触发回调和事件，让调用者先凑合着用着旧数据，同时请求新数据
    local PlayerStateInfo = self.PlayerStateCache[PlayerId]
    if PlayerStateInfo then        
        --触发回调
        if callback then
            callback(PlayerId, PlayerStateInfo)
        end

        --兼容事件
        local Msg = {
            PlayerId        = PlayerId,
            PlayerStateInfo = PlayerStateInfo
        }
        self:DispatchType(self.ON_QUERY_PLAYER_STATE_RSP, Msg)
    end
    
    --2.如果数据没有过期，就不请求了
    if not self:IsPlayerStatusOutOfDate(PlayerId) then return end
    
    --3.开始正常请求
    if not self.GetPlayerStateCallback[PlayerId] then self.GetPlayerStateCallback[PlayerId] = {} end
    table.insert(self.LeftRequirePlayerStateList, PlayerId)
    if callback then
        table.insert(self.GetPlayerStateCallback[PlayerId], callback)        
    end
end

---外部不应该直接使用，为了避免外部使用，调整为local函数，但是需要传入self来指明对象
---@param self UserModel
---@param PlayerIdArray number[] 需要请求的玩家ID列表
---@param callback fun(PlayerId:number, PlayerInfo:table):void 得到数据后的回调
local function _GetPlayerStateMultiple(self, PlayerIdArray, callback)
    for _, PlayerId in ipairs(PlayerIdArray) do
        _GetPlayerStateSingle(self, PlayerId, callback)
    end
end

---传入玩家Id或玩家Id列表，获取到对应数据后触发回调。如果需要取得的玩家数据过期了，则会等待数据回来时再触发回调。
---@see ConstPlayerState#OUT_OF_DATE_TIME_OFFSET 玩家时间过期时间宏
---@param PlayerId number|table 玩家ID或玩家ID列表
---@param callback fun(PlayerId:number, PlayerInfo:table):void 得到数据后的回调
function UserModel:GetPlayerState(PlayerId, callback)
    --1.请求
    --1.1.单个id请求
    if type(PlayerId) == "number" then
        --CLog("[cw] Trying to get state of player " .. tostring(PlayerId) .. "")
        _GetPlayerStateSingle(self, PlayerId, callback)
        
    --1.2.多个id请求
    elseif type(PlayerId) == "table" then
        local PlayerIdDisplayString = ""
        for _, id in ipairs(PlayerId) do
            if PlayerIdDisplayString == "" then
                PlayerIdDisplayString = tostring(id)
            else
                PlayerIdDisplayString = PlayerIdDisplayString .. ", " .. tostring(id)
            end
        end
        --CLog("[cw] Trying to get state of players(" .. tostring(PlayerIdDisplayString) .. ")")
        
        _GetPlayerStateMultiple(self, PlayerId, callback)
        
    --1.3.错误请求
    else
        CError("[cw] trying to get playerState with illegal PlayerId(" .. tostring(tostring(PlayerId)) .. ") which type is " .. tostring(type(PlayerId)))
        return
    end
    
    --CLog("[cw] regroup self.LeftRequirePlayerStateList and self.GetPlayerStateCallback done")
    --print_r(self.LeftRequirePlayerStateList, "[cw] self.LeftRequirePlayerStateList")
    --print_r(self.GetPlayerStateCallback, "[cw] self.GetPlayerStateCallback")

    --2.判断是否需要打开Timer，如果有请求的话就不需要做了
    if self.LeftRequirePlayerStateList and #self.LeftRequirePlayerStateList > 0 then
        --CLog("[cw] self.LeftRequirePlayerStateList size is larger than 0, so start to request data")
        _StartRequirePlayerStateTimer(self)
    else
        --CLog("[cw] self.LeftRequirePlayerStateList size is 0, no need to request data")
    end
end

---允许外部通过传入一个玩家状态，转换为玩家显示状态
---@param PlayerState table 玩家状态，参考 message PlayerState
---@param PlayerId number|nil 可选。玩家ID，玩家单人情况下，也可能被后台判断为单人队伍，从而下发队伍中的状态，但是实际情况下客户端需要判断为单人大厅中
---@return string 玩家显示状态字符串
function UserModel:GetPlayerDisplayStateFromPlayerState(PlayerState, PlayerId)
    local LogicState, ClientHallState, DetailStatus = PlayerState.Status, PlayerState.DisplayStatus, PlayerState.DetailStatus
    local PlayerDisplayState = self:GetDisplayStateByLogicStateAndClientHallState(LogicState, ClientHallState, PlayerId, DetailStatus)    
    return PlayerDisplayState
end

---获取是否有缓存的玩家状态，不触发更新
function UserModel:GetPlayerCacheState(CheckedPlayerId)
    self.PlayerStateCache = self.PlayerStateCache or {}
    return self.PlayerStateCache[CheckedPlayerId]
end

---获取当前玩家的逻辑状态和显示状态，不触发更新（使用前请先确保有数据，最好在GetPlayerState的回调中使用）
---@param CheckedPlayerId number 需要检查的玩家id
---@return any&any Pb_Enum_PLAYER_STATE 与 Enum_PLAYER_CLIENT_HALL_STATE
function UserModel:RawGetPlayerLogicStateAndClientHallState(CheckedPlayerId)
    local PlayerStatusInfo = self.PlayerStateCache[CheckedPlayerId]
    if not PlayerStatusInfo then 
        return UserModel.PLAYER_STATE_DATA_OUT_OF_DATE, UserModel.PLAYER_STATE_DATA_OUT_OF_DATE, UserModel.PLAYER_STATE_DATA_OUT_OF_DATE
    end
    
    --CLog("[cw] UserModel:RawGetPlayerLogicStateAndClientHallState(" .. string.format("%s", CheckedPlayerId) .. ") return " .. tostring(PlayerStatusInfo.Status) .. ", " .. tostring(PlayerStatusInfo.DisplayStatus) .. "")
    return PlayerStatusInfo.Status, PlayerStatusInfo.DisplayStatus, PlayerStatusInfo.DetailStatus
end

---仅获取玩家状态，不触发更新逻辑（使用前请先确保有数据，最好在GetPlayerState的回调中使用）
---@param CheckedPlayerId number 需要查询的玩家ID。同时玩家单人情况下，也可能被后台判断为单人队伍，从而下发队伍中的状态，但是实际情况下客户端需要判断为单人大厅中
---@return string 玩家状态字符串
function UserModel:RawGetPlayerDisplayStateByPlayerID(CheckedPlayerId)
    local LogicState, ClientHallState, DetailStatus = self:RawGetPlayerLogicStateAndClientHallState(CheckedPlayerId)
    local DisplayState = self:GetDisplayStateByLogicStateAndClientHallState(LogicState, ClientHallState, CheckedPlayerId, DetailStatus)
    --CLog("[cw] UserModel:RawGetPlayerDisplayStateByPlayerID(" .. string.format("%s", CheckedPlayerId) .. ") return " .. tostring(DisplayState))
    return DisplayState
end

---获取玩家的显示状态，如果数据过期了，就请求之后再返回
---@param callbackFunc fun(DisplayStateStr:string):void 回调，DisplayStateStr为玩家当前的状态
---@return string 玩家展示的状态，请参考 PlayerStateDisplayCfg 来看
function UserModel:GetPlayerDisplayState(CheckedPlayerId, callbackFunc)
    --CLog("[cw] UserModel:GetPlayerDisplayState(" .. string.format("%s, %s", CheckedPlayerId, callbackFunc) .. ")")
    
    --1.优先判断数据是否在时效性之内，如果在时效性之内，就不需要再次请求
    if not self:IsPlayerStatusOutOfDate(CheckedPlayerId) then        
        local DisplayStateStr = self:RawGetPlayerDisplayStateByPlayerID(CheckedPlayerId)
        --CLog("[cw] GetPlayerDisplayState data of player(" .. tostring(CheckedPlayerId) .. ") is available, call callback directly with param(" .. tostring(DisplayStateStr) .. ")")
        callbackFunc(DisplayStateStr)
        return
    end
    
    --2.走到这里就是数据过期了，需要重新设获取一下
    --这里使用闭包，再调用触发GetPlayerState的接口来获取数据，获取到了之后会在闭包中再次触发回调，此时回调需要自己判断自己内部的对象是否在生命周期内
    --CLog("[cw] GetPlayerDisplayState data of player(" .. tostring(CheckedPlayerId) .. ")is not available, trying to call GetPlayerState to request player info")
    local _DelayCallFunc = function(PlayerID, PlayerInfo)
        local DisplayStateStr = self:RawGetPlayerDisplayStateByPlayerID(PlayerID)
        callbackFunc(DisplayStateStr)
    end
    self:GetPlayerState(CheckedPlayerId, _DelayCallFunc)
end

--------------------------------------------
----- 这一部分是用来告诉服务器客户端当前状态的 -----
--------------------------------------------

---更新完毕后，需要去除Timer
---外部不应该直接使用，为了避免外部使用，调整为local函数，但是需要传入self来指明对象
---@param self UserModel
local function _StopPlayerClientStateTickTimer(self)
    --CLog("[cw] deactive self._PlayerClientHallStateTickTimer")
    Timer.RemoveTimer(self._PlayerClientHallStateTickTimer)
    self._PlayerClientHallStateTickTimer = nil
end

---更新客户端状态的内部处理函数
---外部不应该直接使用，为了避免外部使用，调整为local函数，但是需要传入self来指明对象
---@param self UserModel
local function _UpdatePlayerClientHallSateInner(self)
    --1.如果和上次更新时的状态一样，那么就不需要再次发送了
    if self.LastUpdatePlayerClientHallState == self.PlayerLastClientHallState then
        --CLog("[cw] player's client hall state(" .. tostring(self.PlayerLastClientHallState) .. ") is same with last update state(" .. tostring(self.LastUpdatePlayerClientHallState) .. "), so do not need to update")
        
    --2.否则则需要发送协议更新一下客户端状态
    else
        ---@type UserCtrl
        local UserCtrl = MvcEntry:GetCtrl(UserCtrl)
        UserCtrl:SendSetPlayerDisplayStatusReq(self.PlayerLastClientHallState)
        self.LastUpdatePlayerClientHallState = self.PlayerLastClientHallState
    end

    --3.重置一下玩家更新请求的状态
    self.PlayerLastClientHallState = nil
    _StopPlayerClientStateTickTimer(self)
end

---使用Timer来限制发送频率
---外部不应该直接使用，为了避免外部使用，调整为local函数，但是需要传入self来指明对象
---@param self UserModel
local function _StartPlayerClientStateTickTimer(self)
    --1.如果已经有timer在跑，则不需要新建一个Timer了
    --CLog("[cw] _StartPlayerClientStateTickTimer")
    if self._PlayerClientHallStateTickTimer then
        --CLog("[cw] self._PlayerClientHallStateTickTimer is activated, return")
        return 
    end

    --2.如果没有timer，则新建一个
    --CLog("[cw] self._PlayerClientHallStateTickTimer is nil, create new one and active it")
    local ConstPlayerState = require("Client.Modules.User.ConstPlayerState")
    self._PlayerClientHallStateTickTimer = Timer.InsertTimer(ConstPlayerState.UPDATE_CLIENT_HALL_STATE_GAP, function() _UpdatePlayerClientHallSateInner(self) end)
end

---发送给服务器，告知服务器客户端当前的显示状态
---@param NewClientState string
---@see ConstPlayerState#Enum_PLAYER_CLIENT_HALL_STATE
function UserModel:UpdatePlayerClientHallState(NewClientState)
    --1.判空保护
    --CLog("[cw] UpdatePlayerClientHallState(" .. string.format("%s", NewClientState) .. ")")
    if not NewClientState then
        CError(debug.traceback())
        return
    end
    
    --2.与最后要发送给服务器同步的状态相同的话，不需要处理，因为没有意义
    if NewClientState == self.PlayerLastClientHallState then
        --CLog("[cw] NewClientState(" .. tostring(NewClientState) .. ") is same as self.PlayerLastClientHallState, then return")
        return
    end
    
    --3.更新最后需要发送给服务器的客户端状态，并打开计时器
    --使用计时器来限制发送频率，避免玩家反复切换界面导致发送过多的数据
    self.PlayerLastClientHallState = NewClientState
    _StartPlayerClientStateTickTimer(self)
end

--endregion ----------------- 玩家状态处理 -------------------

--region ----------------- 玩家状态表格内容处理 -------------------

---@param LogicState Pb_Enum_PLAYER_STATE 玩家逻辑状态
---@return string 逻辑状态枚举值对应的逻辑状态字符串
local function _GetLogicStateStr(LogicState)
    local ConstPlayerState = require("Client.Modules.User.ConstPlayerState")
    local EPLSS = ConstPlayerState.Enum_PLAYER_LOGIC_STATE_STR
    return EPLSS[LogicState]
end

---玩家单人情况下，也可能被后台判断为单人队伍，从而下发队伍中的状态，但是实际情况下客户端需要判断为单人大厅中，这里处理一下这个情况
---@param LogicState Pb_Enum_PLAYER_STATE 玩家逻辑状态
---@param PlayerId number|nil 可选。玩家ID，玩家单人情况下，也可能被后台判断为单人队伍，从而下发队伍中的状态，但是实际情况下客户端需要判断为单人大厅中
---@return number LogicState 逻辑状态枚举值
local function _FixedLogicState(PlayerId, LogicState)
    --没有 PlayerId 则说明不需要处理
    if not PlayerId then return LogicState end

    --仅处理队伍中的状态
    if LogicState ~= Pb_Enum_PLAYER_STATE.PLAYER_TEAM then return LogicState end

    --单人的情况下，如果后台下发的逻辑状态是 PLAYER_TEAM 则转换为 PLAYER_LOBBY
    ---@type TeamModel
    local TeamModel = MvcEntry:GetModel(TeamModel)
    local bIsInTeam = TeamModel:IsInTeam(PlayerId)
    if not bIsInTeam then
        CLog("[cw] Player " .. tostring(PlayerId) .. " is not in team, but his logic state is PLAYER_TEAM, so fix it to PLAYER_LOBBY")
        return Pb_Enum_PLAYER_STATE.PLAYER_LOBBY
    end

    return LogicState
end

---获取当前玩家传入 LogicState 与 ClientHallState，获取对应 PlayerID 玩家的显示状态字符串
---@param LogicState Pb_Enum_PLAYER_STATE 玩家逻辑状态
---@param ClientHallState string 玩家显示状态
---@see ConstPlayerState#Enum_PLAYER_CLIENT_HALL_STATE
---@param PlayerId number|nil 可选。玩家ID，玩家单人情况下，也可能被后台判断为单人队伍，从而下发队伍中的状态，但是实际情况下客户端需要判断为单人大厅中
---@param DetailStatus table 服务器下发的展示状态数据
---@return string 玩家此时逻辑状态与显示状态下，应该展示的状态
function UserModel:GetDisplayStateByLogicStateAndClientHallState(LogicState, ClientHallState, PlayerId, DisplayStatus)
    --CLog("[cw] GetDisplayStateByLogicStateAndClientHallState(" .. string.format("%s, %s", LogicState, ClientHallState) .. ")")
    
    --0.兜底处理，返回空字符串
    local DesireDisplayName = ""
    if not LogicState or LogicState == UserModel.PLAYER_STATE_DATA_OUT_OF_DATE then return DesireDisplayName end
    --ClientHallState 允许为空，从而获取默认状态显示文字
    
    LogicState = _FixedLogicState(PlayerId, LogicState)
    local LogicStateStr = _GetLogicStateStr(LogicState)
    
    --1.有客户端显示状态，优先使用客户端显示状态进行查询
    if ClientHallState then
        DesireDisplayName = G_ConfigHelper:GetSingleItemById(Cfg_PlayerStateDisplayCfg, ClientHallState, LogicStateStr)        
    end
    
    --2.没有查询到再使用默认值进行查询
    -- if not DesireDisplayName or DesireDisplayName == "" then -- 现在如果从配置取出来的是个FText
    if not DesireDisplayName or DesireDisplayName == "" or string.len(DesireDisplayName) == 0 then
        --CLog("[cw] DesireDisplayName is empty, get Default value")
        local ConstPlayerState = require("Client.Modules.User.ConstPlayerState")
        DesireDisplayName = G_ConfigHelper:GetSingleItemById(Cfg_PlayerStateDisplayCfg, ConstPlayerState.DEFAULT_KEY, LogicStateStr)
    end

    --CLog("[cw] GetDisplayStateByLogicStateAndClientHallState(" .. tostring(LogicState) .. ", " .. tostring(ClientHallState) .. ") return " .. tostring(DesireDisplayName))
    if type(DesireDisplayName) == "table" then
        ReportError(StringUtil.Format("DesireDisplayName Error For LogicState = {0}, ClientHallState = {1}, LogicStateStr = {2}",LogicState,ClientHallState,LogicStateStr),true)
        DesireDisplayName = ""
    end
    -- 战斗中的情况需要做参数设置
    if LogicState == Pb_Enum_PLAYER_STATE.PLAYER_BATTLE then
        if DisplayStatus and DisplayStatus.StartTime and DisplayStatus.ModeId then
            local CurTime = GetTimestamp()
            local PastTime = CurTime - tonumber(DisplayStatus.StartTime)
            PastTime = PastTime > 0 and PastTime or 0
            local Minute = math.floor(PastTime/60)
            local ModeName = MvcEntry:GetModel(MatchModeSelectModel):GetModeEntryCfg_ModeName(tonumber(DisplayStatus.ModeId)) or ""
            if DisplayStatus.OwnerId and tonumber(DisplayStatus.OwnerId) ~= 0 then
                local Param = {
                    Minute = Minute,
                    ModeName = ModeName,
                }
                -- 自建房
                DesireDisplayName = StringUtil.FormatByKey(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "CustomRoomBattleTip"), Param)
            else
                -- 普通战斗
                DesireDisplayName = StringUtil.Format(DesireDisplayName, Minute, ModeName)
            end
        else
            DesireDisplayName = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Friend', "1406"))
        end
    end
    return DesireDisplayName
end

--endregion ----------------- 玩家状态表格内容处理 -------------------

function UserModel:DataInit()
    self.PlayerName = ""
    self.Level = 1
    self.Experience = 0
    self.PlayerId = 0
    self.PlayerGameToken = 0
    self.HeadId = 0
    self.HeadFrameId = 0
    self.PortraitUrl = ""
    self.AuditPortraitUrl = ""
    self.SelectPortraitUrl = false
    self.LikeTotal = 0 --点赞数
    self.PlayerCreateTime = 0   --角色创建时间

    --玩家必要数据是否同步完成
    self.PlayerLoginFinished = false

    --- 玩家可选头像列表
    self.PlayerHeadList = {}

    --- 这一部分处理逻辑状态
    self.LastRequirePlayerStateTime = -1                                    --上一次请求的时间，两次请求之间的时间差不能太短
    self.RequirePlayerStateList = {}                                        --请求列表(最多50个)
    self.LeftRequirePlayerStateList = {}                                    --超过50个，或者没有赶上上一次请求的玩家id
    _StopRequirePlayerStateTimer(self)                                      --更新玩家状态计时器句柄
    self.GetPlayerStateCallback = {}                                        --在各个逻辑状态下的默认显示配置
    self.PlayerStateCache = {}                                              --记录获取到的玩家状态

    --- 这一部分处理客户端显示状态
    _StopPlayerClientStateTickTimer(self)                                   --更新完毕后，需要去除Timer
    self.LastUpdatePlayerClientHallState = nil                              --上一次发送协议时的状态
    self.PlayerLastClientHallState = nil                                    --客户端在一定时间内发送的最后一条大厅状态
    self.LastPlayerClientHallStateUpdateTime = -1                           --上一次客户端发送
    self._PlayerClientHallStateTickTimer = nil                              --更新客户端状态计时器句柄    

    -- 最大配置等级
    self.MaxLevel = 0

    --毫秒，当前跟Lobby服的网络连接延迟
    self.NetDelayTime = 0

    ---服务器跨天刷新的时间偏移值，单位秒
    self.RefreshDayOffset = 0
    -- 服务器下一次刷新的，utc+0 单位秒
    self.RefreshDayTimeStamp = 0

    -- 经验加成信息列表
    self.PlayerExpAddMap = {}
    -- 金币加成信息列表
    self.PlayerGoldAddMap = {}
    ---服务器的ZoneId
    self.ZoneID = 0
end

--[[
    玩家登出时调用
]]
function UserModel:OnLogin(data)
end

--[[
    玩家登出时调用
]]
function UserModel:OnLogout(data)
    --判断如果断线重连不需要清数据，就将逻辑打开
    -- if data then
    --     --断线重连
    --     return
    -- end
    CWaring("UserModel:OnLogout===============")
    self:DataInit()
end

--[[
    是否玩家自身
]]
function UserModel:IsSelf(PlayerId)
    return self.PlayerId == tonumber(PlayerId)
end

function UserModel:IsSelfByName(PlayerName)
    return self.PlayerName == PlayerName
end

function UserModel:SetLikeTotal(InTotal)
    self.LikeTotal = InTotal
end
function UserModel:GetLikeTotal()
    return self.LikeTotal
end

-- 玩家id
function UserModel:SetPlayerId(InID)
    self.PlayerId = InID
    self.PlayerIdReConnect = InID
end
function UserModel:GetPlayerId()
    return self.PlayerId
end
function UserModel:GetPlayerIdReConnect()
    return self.PlayerIdReConnect
end

--[[创角时间]]
function UserModel:GetPlayerCreateTime()
    return self.PlayerCreateTime
end

--服务器ID
function UserModel:GetServerId()
    return self.ServerId
end

--[[
    SDK Token
]]
function UserModel:GetToken()
    return self.Token
end
function UserModel:SetToken(Token)
    self.Token = Token
end
--[[
    SDK OpenId
]]
function UserModel:GetSdkOpenId()
    return self.SdkOpenId
end
function UserModel:SetSdkOpenId(SdkOpenId)
    self.SdkOpenId = SdkOpenId
    SaveGame.SetAccountId(SdkOpenId)
    self:DispatchType(UserModel.ON_OPEN_ID_SET)
end

--游戏Token
function UserModel:SetGameToken(GameToken)
    self.PlayerGameToken = GameToken
    self.PlayerGameTokenReConnect = GameToken
end
function UserModel:GetGameToken()
    return self.PlayerGameToken
end
function UserModel:GetPlayerGameTokenReConnect()
    return self.PlayerGameTokenReConnect
end

function UserModel:GetPlayerIdStr()
    return tostring(self.PlayerId)
end

function UserModel:SetDayOffset(Offset)
    self.RefreshDayOffset = Offset
    print("SetDayOffset", self.RefreshDayOffset)
end

--- 获取每日刷新的时间偏移
function UserModel:GetDayOffset()
    return self.RefreshDayOffset
end

--- 获取下次每日刷新的时间戳
function UserModel:GetRefreshDayTimeStamp()
    local NextZeroTime = TimeUtils.GetOffsetDayZeroTime(GetTimestamp(), 1)
    self.RefreshDayTimeStamp = NextZeroTime + self.RefreshDayOffset
    return self.RefreshDayTimeStamp
end

--设置玩家昵称
function UserModel:SetPlayerName(InName)
    -- CWaring("InName:" .. InName)
    self.PlayerName = InName
end

---获取玩家昵称
---@return string 玩家名字
function UserModel:GetPlayerName()
    return self.PlayerName
end

function UserModel:SetPlayerLvAndExp(InLevel, InExperience)
    print("UserModel:SetPlayerLvAndExp", InLevel, InExperience)
    local OldLevel = self.Level
    local OldExp = self.Experience
    self.Level = InLevel
    self.Experience = InExperience
    MvcEntry:GetModel(PersonalInfoModel):SetPlayerLvAndExp(self.PlayerId,InLevel,InExperience)
    if OldLevel ~= self.Level then
        self:DispatchType(UserModel.ON_PLAYER_LV_CHANGE, {Level = self.Level, OldLevel = OldLevel})
    end
    if OldExp ~= self.Experience then
        self:DispatchType(UserModel.ON_PLAYER_EXP_CHANGE, {Exp = self.Experience, OldExp = OldExp})
    end
end

---获取玩家等级以及经验
function UserModel:GetPlayerLvAndExp()
    return self.Level,self.Experience
end

---获取玩家等级
function UserModel:GetPlayerLv()
    return self.Level
end

---检测玩家是否满级
function UserModel:CheckIsMaxLevel()
    local CurLevel = self:GetPlayerLvAndExp()
    local MaxLevel = self:GetPlayerMaxCfgLevel()
    local IsMaxLevel = CurLevel >= MaxLevel
    return IsMaxLevel
end

--- 获取某个等级下的最大经验值
function UserModel:GetPlayerMaxExpForLv(InLevel)
    local LevelCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_PlayerLevelConfig,Cfg_PlayerLevelConfig_P.Lv, InLevel)
    if not LevelCfg then
        return 0
    end
    return LevelCfg[Cfg_PlayerLevelConfig_P.Exp]
end

-- 获取配置最大等级
function UserModel:GetPlayerMaxCfgLevel()
    if self.MaxLevel == 0 then
        local Cfgs = G_ConfigHelper:GetDict(Cfg_PlayerLevelConfig)
        local MaxLevel = 0
        for _,Cfg in ipairs(Cfgs) do
            if Cfg[Cfg_PlayerLevelConfig_P.Lv] > MaxLevel then
                MaxLevel = Cfg[Cfg_PlayerLevelConfig_P.Lv]
            end
        end
        self.MaxLevel = MaxLevel
    end
    return self.MaxLevel
end

function UserModel:CheckClientP4Version()
    if not self.PVersion then
        -- self.PVersion = UE.UGFUnluaHelper.GetP4Version()

        self.PVersion = {}
        self.PVersion.Stream = UE.UGFUnluaHelper.GetP4Steam()
        self.PVersion.Changelist = UE.UGFUnluaHelper.GetP4ChangeList()
        print_r(self.PVersion,"self.PVersion:")
    end
end

--- 获取P4 ChangeList
function UserModel:GetP4ChangeList()
    self:CheckClientP4Version()
    -- local SplitList = StringUtil.Split(self.PVersion,"_")
    -- local Stream = SplitList[1]
    -- local ChangeList = SplitList[2]
    return self.PVersion.Changelist,self.PVersion.Stream
end


--[[
    获取客户端当前的P4分支名及CL
]]
function UserModel:GetClientP4Show()
    self:CheckClientP4Version()
    -- return self.PVersion;
    return StringUtil.FormatSimple("{0}_{1}",self.PVersion.Stream,self.PVersion.Changelist)
end

--[[
    获取大厅服当前的P4分支名及CL
]]
function UserModel:GetGatewayP4Show()
    if not self.GateVersion then
        return "--"
    end
    return StringUtil.FormatSimple("{0}_{1}",self.GateVersion.Stream,self.GateVersion.Changelist)
end
--[[
    获取DS服当前的P4分支名及CL
]]
function UserModel:GetDSP4Show()
    if not self.DSVersion then
        return "--"
    end
    return self.DSVersion
end
function UserModel:SetDSVersion(Stream,Changelist)
    self.DSVersion = StringUtil.Format("{0}_{1}",Stream,Changelist)
end

function UserModel:GetDSGameIdShow()
    local GameId = self.DSGameId or "--"
    return (GameId .. "")
end
function UserModel:SetDSGameId(GameId)
    self.DSGameId = GameId
end


--获取当前客户端版本号, 一般读取Ini
function UserModel:GetAppVersion()
    return UE.UGFUnluaHelper.GetAppVersion()
end


--[[
    检查服务器的P4本地库版本是否和本地一致
]]
function UserModel:ComparePVersion()
    self:CheckClientP4Version()
    if not self.PVersion or not self.GateVersion then
        return
    end
    if UE.UGFUnluaHelper.IsEditor() then
		return
	end
    -- if not self.PVersionParam then
    --     self.PVersionParam = {}
    --     local SplitList = StringUtil.Split(self.PVersion,"_")
    --     print_r(SplitList)
    --     local Stream = SplitList[1]
    --     local ChangeList = SplitList[2]

    --     self.PVersionParam.Stream = Stream
    --     self.PVersionParam.ChangeList = ChangeList
    -- end
    local Stream = self.PVersion.Stream
    local ChangeList = self.PVersion.ChangeList
    local RemoteStream = self.GateVersion.Stream
    local RemoteChangelist = self.GateVersion.Changelist
    if self:IsPParamValid(Stream) and self:IsPParamValid(RemoteStream) and Stream ~= RemoteStream then
        local TipLog = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_UserModel_Streammismatch"),Stream,RemoteStream)
        if not CommonUtil.IsShipping() then
            --发布版本不显示此Tip
            UIAlert.Show(TipLog)
        end
        CWaring(TipLog)
    end

    if self:IsPParamValid(ChangeList) and self:IsPParamValid(RemoteChangelist) and ChangeList ~= RemoteChangelist then
        local TipLog = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_UserModel_ChangeListdoesnotmat"),ChangeList,RemoteChangelist)
        if not CommonUtil.IsShipping() then
            --发布版本不显示此Tip
            UIAlert.Show(TipLog)
        end
        CWaring(TipLog)
    end
end

--[[
    判断跟P4版本相关的参数是否有用
    nil
    空字符串
    0
    以上三种情况都属于不可用

    Param为字符串类型
]]
function UserModel:IsPParamValid(Param)
    if not Param then
        return false
    end
    if string.len(Param) <= 0 then
        return false
    end
    if Param == "0" then
        return false
    end
    if Param == "local" then
        return false
    end
    return true
end

function UserModel:GetPVersionShow()
    self:CheckClientP4Version()
    local DSVersion = UE.UGFUnluaHelper.GetDSVersion()
    local GateVersonStr = ""
    if self.GateVersion then
        GateVersonStr = StringUtil.Format("{0}_{1}",self.GateVersion.Stream,self.GateVersion.Changelist)
    end
    local ShowStr = StringUtil.Format("Local:{0},Gate:{1},DS:{2}",self:GetClientP4Show(),GateVersonStr,DSVersion)
    CWaring("GetPVersionShow:" .. ShowStr)
    return ShowStr
end

function UserModel:SetLocationInfo(SdkLocInfo)
    self.LocationInfo = 
    {
        CountryCode = SdkLocInfo and SdkLocInfo.CountryCode or "",
        CityAscii = SdkLocInfo and SdkLocInfo.CityAscii or "",
        Latitude = SdkLocInfo and SdkLocInfo.Latitude or 0,
        Longitude = SdkLocInfo and SdkLocInfo.Longitude or 0
    }
end

function UserModel:SetAntiAddictionForbidInfo(Info)
    self.AntiAddictionForbidInfo = Info or {
        IsInForbidTime = false, 
        ForbidMessage = "",
    }
end

function UserModel:GetAntiAddictionForbidInfo()
    return self.AntiAddictionForbidInfo
end

function UserModel:CheckAntiAddictionMessageBox(IsLogin)
    if not self:IsAntiAddictionForbid() then
        return
    end
    local ForbidInfo = self:GetAntiAddictionForbidInfo()
	local msgParam = {
		describe = StringUtil.Format(ForbidInfo.ForbidMessage),
		closeAfterCallback = function()
			-- --二次弹框确认
			-- local msgParam = {
			-- 	describe = StringUtil.Format("未成年用户非可玩时间段宵禁, 必须强制下线"),
			-- 	rightBtnInfo = {
			-- 		callback = function()
            --             if not IsLogin then
			-- 			    MvcEntry:GetCtrl(CommonCtrl):GAME_LOGOUT()                           
            --             end
            --             self:SetAntiAddictionForbidInfo()
			-- 		end
			-- 	}
			-- }
			-- UIMessageBox.Show(msgParam)
            if not IsLogin then
                MvcEntry:GetCtrl(CommonCtrl):GAME_LOGOUT()                           
            end
            self:SetAntiAddictionForbidInfo()
		end
	}
	UIMessageBox.Show(msgParam)
end

--[[
    判断玩家是否被宵禁了
]]
function UserModel:IsAntiAddictionForbid()
    if self.AntiAddictionForbidInfo and self.AntiAddictionForbidInfo and self.AntiAddictionForbidInfo.IsInForbidTime then
        return true
    end
    return false
end

--[[
    存储加成数据
    message PlayerSysCofSync
    {
        map<int64, int64> ExpMap = 1;      // 经验加成数据，Key是加成的系数,1000是基数，Value是该加成的次数
        map<int64, int64> GoldMap = 2;     // 金币加成数据，Key是加成的系数,1000是基数，Value是该加成的次数
    }
]]
function UserModel:SavePlayerCofData(Msg)
    self.PlayerExpAddMap = Msg.ExpMap or {}
    self.PlayerGoldAddMap = Msg.GoldMap or {}
    self:DispatchType(UserModel.ON_PLAYER_VALUE_ADD_CHANGED)
end

-- 获取经验加成map
function UserModel:GetPlayerExpAddMap()
    return self.PlayerExpAddMap
end

-- 获取经验加成信息 - （当前展示只有一个展示位置，取一个展示)
function UserModel:GetPlayerExpAddInfo()
    return self:GetPlayerOneAddInfoInMap(self.PlayerExpAddMap)
end

-- 获取金币加成map
function UserModel:GetPlayerGoldAddMap()
    return self.PlayerGoldAddMap
end

-- 获取金币加成信息 - （当前展示只有一个展示位置，取一个展示)
function UserModel:GetPlayerGoldAddInfo()
    return self:GetPlayerOneAddInfoInMap(self.PlayerGoldAddMap)
end

-- 取其中一条数据
function UserModel:GetPlayerOneAddInfoInMap(Map)
    local AddInfo = nil
    for AddValue,LeftCount in pairs(Map) do
        AddInfo = {
            AddValue = tonumber(AddValue),
            LeftCount = LeftCount
        }
        break
    end
    return AddInfo
end

-- 是否展示加成信息 - 有一个生效即展示
function UserModel:IsShowPlayerExpAddInfo()
    return next(self.PlayerExpAddMap) or next(self.PlayerGoldAddMap)
end

return UserModel;