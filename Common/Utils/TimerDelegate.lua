--[[
	基于UE TimerManager实现的计时器封装
	可以避免因为进程挂点，从而导致计时不正确

	目前布署在Client、DS
]]
TimerDelegate = TimerDelegate or {}

TimerDelegate.TimerId2TimerHandler = TimerDelegate.TimerId2TimerHandler or {}
TimerDelegate.IndexIncrement = TimerDelegate.IndexIncrement or 1
local function GetTimerId()
	TimerDelegate.IndexIncrement = TimerDelegate.IndexIncrement + 1
	if TimerDelegate.IndexIncrement >= math.maxinteger then
		TimerDelegate.IndexIncrement = 1
	end
	if TimerDelegate.TimerId2TimerHandler[TimerDelegate.IndexIncrement] then
		--ID被占用，需要重新找值
		return GetTimerId()
	end
	return TimerDelegate.IndexIncrement
end

---添加一个计时器
---@param timeOffset number 单位是秒 0的话，遇到tick就会执行；-1的话，会在下一帧执行。
---@param callfunc function 到时间之后执行的回调
---@param loop boolean 是否循环
---@return userdata 一个计时器的handler，后续需要使用 TimerDelegate.RemoveTimer 来清理
function TimerDelegate.InsertTimer(timeOffset, callfunc, loop, name)
	--[[
		/**
		* Set a timer to execute delegate. Setting an existing timer will reset that timer with updated parameters.
		* @param Event						Event. Can be a K2 function or a Custom Event.
		* @param Time						How long to wait before executing the delegate, in seconds. Setting a timer to <= 0 seconds will clear it if it is set.
		* @param bLooping					True to keep executing the delegate every Time seconds, false to execute delegate only once.
		* @param InitialStartDelay			Initial delay passed to the timer manager, in seconds.
		* @param InitialStartDelayVariance	Use this to add some variance to when the timer starts in lieu of doing a random range on the InitialStartDelay input, in seconds. 
		* @return							The timer handle to pass to other timer functions to manipulate this timer.
		*/
	]]
	if not GameInstance then
		UnLua.LogError("TimerDelegate.InsertTimer:GameInstance not found,Please Check!")
		return
	end
	local IsNextTick = false
	local TimerHandle = nil
	if not loop and timeOffset <= 0 then
		IsNextTick = true
	end
	if timeOffset <= 0 then
		timeOffset = 0.001
	end
	if IsNextTick then
		local TimerId = GetTimerId()
		TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerForNextTickDelegate({GameInstance, Bind(nil,TimerDelegate._OnTimerout,callfunc,TimerId)})
		TimerDelegate.TimerId2TimerHandler[TimerId] = TimerHandle
	else
		if not loop then
			local TimerId = GetTimerId()
			TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({GameInstance, Bind(nil,TimerDelegate._OnTimerout,callfunc,TimerId)}, timeOffset, loop)
		else
			TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({GameInstance, callfunc}, timeOffset, loop)
		end
	end
	
	return TimerHandle
end

function TimerDelegate._OnTimerout(callfunc,TimerId)
	CWaring("TimerDelegate._OnTimerout:" .. TimerId)
	callfunc()
	local TimerHandle = TimerDelegate.TimerId2TimerHandler[TimerId]
	TimerDelegate.RemoveTimer(TimerHandle)
	TimerDelegate.TimerId2TimerHandler[TimerId] = nil
end


---移除一个计时器
---@param timer userdata 计时器handler
function TimerDelegate.RemoveTimer(timer)
	if not GameInstance then
		UnLua.LogError("TimerDelegate.InsertTimer:GameInstance not found,Please Check!")
		return
	end
	if timer and UE.UKismetSystemLibrary.K2_IsValidTimerHandle(timer) then
		UE.UKismetSystemLibrary.K2_ClearTimerHandle(GameInstance,timer)
		timer = nil
	end
end


return TimerDelegate