--[[
	基于UObject Tick进行计时器封装
	在Lua层性能较好

	目前仅布署在Client
	DS不生效
]]
local TablePool = require("Common.Utils.TablePool")
Timer = Timer or {}
Timer.NEXT_TICK = 0		--遇到最近的Tick就执行
Timer.NEXT_FRAME = -1	--下一帧执行

Timer._list = TablePool.Fetch("Timer")
Timer.CurrentTime = 0
Timer.LastDeltaTime = 0

Timer.TimerId2TimerHandler = {}
Timer.TimerId2TimerHandler[2] = "asf"
Timer.TimerIdIncrement = 1
local function GetAutoIncrementTimerId()
	Timer.TimerIdIncrement = Timer.TimerIdIncrement + 1
	if Timer.TimerIdIncrement >= math.maxinteger then
		Timer.TimerIdIncrement = 1
	end
	if Timer.TimerId2TimerHandler[Timer.TimerIdIncrement] then
		--ID被占用，需要重新找值
		return GetAutoIncrementTimerId()
	end
	return Timer.TimerIdIncrement
end

---添加一个常规Timer
---@param timeOffset number 延迟时间，可以使用 Timer.NEXT_TICK|Timer.NEXT_FRAME
---@param callfunc fun(deltaTime:number):void 计时器到点触发回调
---@param loop boolean 是否为循环timer，如果为true则会在timer触发后，timeoffset秒之后执行(Timer.NEXT_TICK|Timer.NEXT_FRAME会在之后每一帧执行)
---@param name string 计时器名字，后续可以通过名字来移除计时器，名字也可以在timer报错时提供信息方便排查
---@param execImmediately boolean 是否立即执行
function Timer.InsertTimer(timeOffset, callfunc, loop, name, execImmediately)
	local _timePoint 
	if timeOffset == Timer.NEXT_FRAME then--如果为-1 表示下一帧才执行
		_timePoint = Timer.NEXT_FRAME
	else
		_timePoint = Timer.CurrentTime + timeOffset
	end
	
	-- local timer = { timePoint = _timePoint, offset = timeOffset, func = callfunc, loop = loop, name = name or ""}
	local timer = TablePool.Fetch("Timer")
	timer.timePoint = _timePoint
	timer.offset = timeOffset
	timer.func = callfunc
	timer.loop = loop
	timer.name = name or ""
	timer.need_remove = false
	Timer._InsertTimer(timer)
	if execImmediately and callfunc ~= nil and type(callfunc) == "function" then
		callfunc()
	end
	return timer.timerid
end

---添加一个协程Timer，可以使用coroutine.yield来自定义计时器触发间隔
---@param timeOffset number 延迟时间，可以使用 Timer.NEXT_TICK|Timer.NEXT_FRAME
function Timer.InsertCoroutineTimer(timeOffset, func, name)
	local _co = coroutine.create(func)
	local _timePoint
	if timeOffset == Timer.NEXT_FRAME then--如果为-1 表示下一帧才执行
		_timePoint = Timer.NEXT_FRAME
	else
		_timePoint = Timer.CurrentTime + timeOffset
	end
	-- local timer = { timePoint = _timePoint, offset = timeOffset, co = _co, name = name or ""}
	local timer = TablePool.Fetch("Timer")
	timer.timePoint = _timePoint
	timer.offset = timeOffset
	timer.co = _co
	timer.name = name or ""
	timer.need_remove = false
	Timer._InsertTimer(timer)
	return timer.timerid
end

---移除一个Timer(常规Timer或协程Timer)
---@param timer table 句柄
function Timer.RemoveTimer(timerid)
	if not timerid then return end

	local timer = Timer.TimerId2TimerHandler[timerid]
	if not timer then
		return
	end
	timer.timePoint = 0
	timer.func = nil
	timer.co = nil
	timer.loop = false
	timer.need_remove = true
end

---移除一个Timer(常规Timer或协程Timer)
---@param name string timer名
function Timer.RemoveTimerByName(name)
	for _, timer in ipairs(Timer._list) do
		if timer.name == name then
			Timer.RemoveTimer(timer.timerid)
			break
		end
	end
end

---内部封装一个增加Timer的函数
function Timer._InsertTimer(timer)
	timer.deltaTime = 0
	timer.timerid = GetAutoIncrementTimerId()
	Timer.TimerId2TimerHandler[timer.timerid] = timer
	-- CWaring("Timer Add:" .. timer.timerid)
	table.insert(Timer._list, timer)
end

function Timer.Tick(deltaTime)
	Timer.LastDeltaTime = deltaTime;
	Timer.CurrentTime = Timer.CurrentTime + deltaTime
	-- local removeList = TablePool.Fetch("Timer")
	local ExistRemove = false
	for index, timer in ipairs(Timer._list) do
		if not timer.need_remove then
			timer.deltaTime = timer.deltaTime + deltaTime
			
			--预约下一帧执行
			if timer.timePoint == Timer.NEXT_FRAME then
				timer.timePoint = -2 		--设为-2，下一帧就会执行
			
			--到点了，执行
			elseif timer.timePoint <= Timer.CurrentTime then
				--a) function Timer	
				if timer.func ~= nil and type(timer.func) == "function" then
					local res = EnsureCall("Timer.Tick failed:",timer.func, timer.deltaTime)
					--Timer运行异常,移除此Timer
					if res == false then
						-- table.insert(removeList, index)
						timer.need_remove = true
						ExistRemove = true
					--Timer运行正常，且不是loop，则移除此Timer
					elseif not timer.loop then
						-- table.insert(removeList, index)
						timer.need_remove = true
						ExistRemove = true
						--Timer运行正常，为loop，则重置deltaTime及timePoint，等待下一次调用
					else
						timer.deltaTime = 0
						timer.timePoint = timer.offset + Timer.CurrentTime
					end

				--b) coroutine Timer
				elseif timer.co ~= nil and type(timer.co) == "thread" and coroutine.status(timer.co) ~= "dead" then
					local res, errInfo, alive, delay
					res, errInfo = EnsureCall("Timer.Tick.coroutine failed:",function() alive, delay = coroutine.resume(timer.co, timer.deltaTime) end)
					--Timer运行正常，重置deltaTime以及计算下一次的触发时间
					if res and alive and delay then
						timer.deltaTime = 0
						timer.timePoint = Timer.CurrentTime + delay
						--Timer运行异常，移除此Timer
					else
						--如果时协程异常，则单独上报一下
						if not alive then
							local errMsg = "LUA ERROR: [Timer] CoroutineError: " .. tostring(timer.name) .. ": " .. tostring(delay) .. "\n" .. debug.traceback()
							CError(errMsg)
							UE.UGFUnluaHelper.ReportError(errMsg)
						end
						-- table.insert(removeList, index)
						timer.need_remove = true
						ExistRemove = true
					end
					
				--c) 奇奇怪怪Timer
				else
					-- table.insert(removeList, index)
					timer.need_remove = true
					ExistRemove = true
				end
			end
		else
			ExistRemove = true
		end
	end
	
	-- 删除过期的timer
	-- if removeList ~= nil then
	-- 	for idx = #removeList, 1, -1 do
	-- 		TablePool.Recycle("Timer", Timer._list[removeList[idx]])
	-- 		table.remove(Timer._list, removeList[idx])
	-- 	end
	-- end
	-- TablePool.Recycle("Timer", removeList)
	if ExistRemove then
		local NewList = TablePool.Fetch("Timer")
		local NewIndex = 1
		for index, timer in ipairs(Timer._list) do
			if not timer.need_remove then
				NewList[NewIndex] = timer
				NewIndex = NewIndex + 1
			else
				Timer.TimerId2TimerHandler[timer.timerid] = nil
				-- CWaring("Timer Remove:" .. timer.timerid)
				TablePool.Recycle("Timer", timer)
			end
		end
		TablePool.Recycle("Timer", Timer._list)
		Timer._list = NewList
	end
end

return Timer
