--- 使用方式
--[[

local M = {}
function M:OnInit()
    --1.设置初始状态
    local initialState = "A"
    --2.设置转化矩阵
    local events = {
        {eventName = "A_B",          from = "A",         to = "B"},     --调用 A_B() 会触发从 A状态转移到B状态
        {eventName = "B_C",          from = "B",         to = "C"},     --调用 B_C() 会触发从 B状态转移到C状态
        {eventName = "BC_A",         from = {"B", "C"},  to = "A"},     --调用 BC_A() 会触发从 B状态或C状态转移到A状态
        {eventName = "Any_A",        from = "*",         to = "A"}      --调用 Any_A() 会触发从 任意状态转移到A状态
    }
    --3.构造一个状态机
    local fsm_C = require("Client.Common.SimpleFSM")
    self.fsm = fsm_C(self, initialState, events)
end

--4.设置需要的状态机函数
--4.1.状态机转移函数
function M:OnStateChanged(Event, From, To, ...) print("OnStateChanged " .. Event) end

--4.2.状态机各状态函数，
--A状态
function M:OnEnter_A(Event, From, To, ...)  print("OnEnter_A")  end
function M:On_A(Event, From, To, ...)       print("On_A")       end
function M:OnLeave_A(Event, From, To, ...)  print("OnLeave_A")  end
--B状态
function M:OnEnter_B(Event, From, To, ...)  print("OnEnter_B")  end
function M:On_B(Event, From, To, ...)       print("On_B")       end
function M:OnLeave_B(Event, From, To, ...)  print("OnLeave_B")  end

--5.调用
M:OnInit()
M.fsm:A_B()     --> OnLeave_A           (注释上方 function M:OnLeave_A  这一行则不会打印出此日志)
                --> OnEnter_B           (注释上方 function M:OnEnter_B  这一行则不会打印出此日志)
                --> On_B                (注释上方 function M:On_B       这一行则不会打印出此日志)
                --> OnStateChanged A_B  (注释上方 function M:OnStateChanged  这一行则不会打印出此日志)
--]]

local fsm = {}
fsm.ANY_STATE = "*"

local function _GetEnterEventName(event) return "OnEnter_" .. event end
local function _GetOnEventName(event) return "On_" .. event end
local function _GetLeaveEventName(event) return "OnLeave_" .. event end
local function _SafeCallFun(func, param)
    if not func then
        CError("SimpleFSM failed, Func name not exist!", true)
        return
    end

    local ErrorTypeStr = StringUtil.FormatSimple("SimpleFSM failed with funcname {0}:", func)
    EnsureCall(ErrorTypeStr, func, table.unpack(param))
end

local fsmObjMetatable = { }

---判断是否可以触发Event，如果可以的话返回true与目标状态
---@return boolean 是否可以运行
---@return string eventName 如果可以运行的话，返回下一状态名称
function fsmObjMetatable:Can(Event)
    local eventInfo = self._event[Event]
    local eventFrom = eventInfo.from
    local eventTo = eventInfo.to

    if eventFrom == fsm.ANY_STATE then return true, eventTo end

    if type(eventFrom) == "table" then
        for k, v in pairs(eventFrom) do
            if v == self.curState then
                return true, eventTo
            end
        end
        return false, nil
    end

    return eventFrom == self.curState, eventTo
end

---@return string 返回当前状态名称
function fsmObjMetatable:GetCurState()
    return self.curState
end

--[[
    event = {
        {eventName = "GetJob",          from = "A",         to = "B"},  --GetJob          A -> B
        {eventName = "CodeComplete",    from = "B",         to = "C"},  --CodeComplete    B -> C
        {eventName = "FindError",       from = "C",         to = "B"},  --FindError       C -> B
        {eventName = "TestPass",        from = "C",         to = "A"},  --TestPass        C -> A
        {eventName = "LoseJob",         from = {"B", "C"},  to = "A"}   --LoseJob         B/C -> A
    }
--]]
---@generic eventName:string
---@generic from:string
---@generic to:string
---@alias transition table<eventName, from, to>
---@param self table 持有fsm的对象句柄
---@param initial eventName 初始事件名
---@param transitions transition[] 允许转换的事件列表
local function ctor(_, self, initial, transitions)
    local handler = self
    local fsmObj = {
        curState = initial,
        _event = {}
    }
    setmetatable(fsmObj, { __index = fsmObjMetatable })

    ---@param eventInfo transition
    ---@return boolean|string
    local function _transitionFunc(eventInfo)
        local eventName = eventInfo.eventName
        --以A->B为例子
        --    阶段1：触发 OnLeave_A
        --    阶段2：触发 OnEnter_B
        --    阶段3：触发 On_B       触发 OnStateChanged
        local function _transition(self, ...)
            local can, to = self:Can(eventName)
            if not can then return false end

            local oldState = self.curState
            local newState = to

            --    阶段1：触发 OnLeave_A
            local param = table.pack(handler, eventName, oldState, newState, ...)
            _SafeCallFun(handler[_GetLeaveEventName(self.curState)], param)
            
            --    阶段2：触发 OnEnter_B，此时状态已经成功转变为 B，所以要同步修改 curState
            self.curState = to
            _SafeCallFun(handler[_GetEnterEventName(self.curState)], param)
            
            --    阶段3：触发 On_B       触发 OnStateChanged
            _SafeCallFun(handler[_GetOnEventName(self.curState)], param)
            _SafeCallFun(handler["OnStateChanged"], param)

            return true
        end
        return _transition
    end

    ---@param eventInfo transition
    for _, eventInfo in pairs(transitions or {}) do
        fsmObj._event[eventInfo.eventName] = { from = eventInfo.from, to = eventInfo.to }
        fsmObj[eventInfo.eventName] = _transitionFunc(eventInfo)
    end

    return fsmObj
end

setmetatable(fsm, {__call = ctor})
return fsm