require("Core.BaseClass")
local class_name = "EventDispatcher"

---事件处理机制基础类。类似Flash事件, 有优先级功能,通过抛出Event来推动逻辑
---@class EventDispatcher
EventDispatcher = EventDispatcher or BaseClass(nil, class_name)
EventDispatcher.ECallerType = {
	NONE = 0,			--空值
	TABLE = 1,			--表
	USER_TABLE = 2,		--Unlua表（是表同时也可以代表C++对象）
	USER_DATA = 3,		--C++对象
	UNKNOWN = 4,		--未知
}

--回调排序类型
EventDispatcher.ECallOrderType = {
	ORDER = 1,			--回调先添加先执行
	REVERSE_ORDER = 2,	--回调先添加后执行
}

function EventDispatcher:__init()
	self.listener_list = {}
	self.changed_map = {}
	self.count = 0
	self.dispatching_map = {}
	self.Swallow = false			--是否开启吞噬事件，在执行事件对应的回调，如果回调返回True，表示吞噬此事件，此事件将不会继续往下传递
	self.CallOrderType = EventDispatcher.ECallOrderType.ORDER
end

function EventDispatcher:__dispose()	
	self.listener_list = nil
	self.changed_map = nil
	self.count = 0
	self.dispatching_map = nil
end

---供孩子重写，方便扩展逻辑
function EventDispatcher:IsListenerCanCall(obj, UIStack) return true end

---供孩子重写，获取事件派发判断，For循环前的UI堆栈列表，供IsListenerCanCall判断使用，避免循环中状态动态改变了影响判断
function EventDispatcher:GetUIStack() return nil end

---添加一个事件
---@param type_name string|number 事件关键字
---@param call_back fun 事件回调函数
---@param caller table 监听者
---@param priority nil|number 执行优先级,数字越大越提前执行
function EventDispatcher:AddListener(type_name, call_back, caller, priority) 
	if not type_name then
		local callerName = caller and caller.ClassName and caller:ClassName() or nil
		if not callerName then
			callerName = caller and caller.GetName and caller:GetName() or nil
		end
		CError("EventDispatcher:AddListener type_name nil:" .. (callerName or ""),true)
		return nil
	end
	if not call_back then
		CError("EventDispatcher:AddListener call_back nil:" .. tostring(type_name), true)
		return nil
	end
	
	priority = priority or 0
	
	--以事件名为key，加入到self.listener_list中
	local list = self.listener_list[type_name]
	if list == nil then
		list = {}
		self.listener_list[type_name] = list	
	else
		for _, obj in pairs(list) do
			if (obj.call_back == call_back) and (not obj.caller or not caller or obj.caller == caller) then
				obj.priority = priority
				obj.is_removed = false
				return obj
			end
		end
	end
	
	--递增id
	self.count = self.count + 1
	
	--调用者类型
	local callerType = EventDispatcher.ECallerType.NONE
	if caller then
		local typeStr = type(caller)
		if typeStr == "table" then
			callerType = EventDispatcher.ECallerType.TABLE
			if caller.__inner_type == "unlua" then
				callerType = EventDispatcher.ECallerType.USER_TABLE
			end
		elseif typeStr == "userdata" then
			callerType = EventDispatcher.ECallerType.USER_DATA
		else
			CError("AddListener unknown typeStr:" .. typeStr)
			callerType = EventDispatcher.ECallerType.UNKNOWN
		end
	end
	
	--真正加入到 self.listener_list 中
	local listener = {call_back = call_back, caller = caller, callerType = callerType, priority = priority, id = self.count}
	table.insert(list, listener)
	
	--delay evaluation
	self.changed_map[type_name] = true
	
	return listener
end

---删除一个事件
---@param type_name string|number 事件关键字
---@param call_back fun 事件回调函数
---@param caller table 监听者
function EventDispatcher:RemoveListener(type_name, call_back, caller) 
	if not type_name then
		local callerName = caller and caller.ClassName and caller:ClassName() or nil
		if not callerName then
			callerName = caller and caller.GetName and caller:GetName() or nil
		end
		CError("EventDispatcher:RemoveListener type_name nil:" .. (callerName or ""), true)
		return
	end
	if not call_back then
		CError("EventDispatcher:RemoveListener call_back nil:" .. type_name, true)
		return
	end
	
	local list = self.listener_list[type_name]
	if list ~= nil then
		local is_dispatching = self.dispatching_map[type_name]
		for i,obj in pairs(list) do
			if(obj.call_back == call_back) and (not caller or caller == obj.caller) then
				if(is_dispatching) then
					obj.is_removed = true
				else
					table.remove(list, i)
				end
				return nil
			end
		end
	end
end

---是否存在为某个事件 注册的监听
---@param type_name string|number 事件关键字
function EventDispatcher:HasListeners(type_name)
	if not type_name then
		CError("EventDispatcher:HasListeners type_name nil",true)
		return
	end
	
	local list = self.listener_list[type_name]
	if list and #list > 0 then
		for i,obj in pairs(list) do
			if not obj.is_removed then
				return true
			end
		end
	end
	
	return false
end

---抛出一个事件(简易模式)
---@param type_name string|number 事件名称
---@param data any 抛出的数据
---@return number 事件触发回调的次数
function EventDispatcher:DispatchType(type_name, data)
	if not type_name then
		CError("EventDispatcher:DispatchType type_name nil",true)
		return 0
	end
	
	local list = self.listener_list[type_name]
	if self.changed_map[type_name] then
		if list and #list > 0 then
			if self.CallOrderType == EventDispatcher.ECallOrderType.ORDER then
				--排在前面先执行
				table.sort(list, function(a, b)
					return  a.priority > b.priority
				end)
			else
				--排在后面先执行
				table.sort(list, function(a, b)
					return  a.priority < b.priority
				end)
			end
		end
		self.changed_map[type_name] = false
	end
	
	--没有事件的话不进行处理
	if list == nil then return 0 end
	
	self.dispatching_map[type_name] = true
	local count = 0
	local need_clear = false
	local UIStack = self:GetUIStack()
	for i=1, #list do
		local finxIndex = i
		if self.CallOrderType == EventDispatcher.ECallOrderType.REVERSE_ORDER then
			--排在后面先执行
			finxIndex = #list - (i - 1)
		end
		local obj = list[finxIndex]
		
		if obj ~= nil then
			if obj.is_removed then
				need_clear = true
			else
				--监听者是否可用
				local valid_call = true
				if obj.callerType ~= EventDispatcher.ECallerType.NONE then
					if not obj.caller then
						valid_call = false
					elseif obj.callerType == EventDispatcher.ECallerType.USER_TABLE or obj.callerType == EventDispatcher.ECallerType.USER_DATA then
						if not UE.UKismetSystemLibrary.IsValid(obj.caller) then
							valid_call = false
						end
					end
				end
				
				--是否可以运行
				local can_call = self:IsListenerCanCall(obj, UIStack)
				
				if valid_call and can_call then
					local callResult = nil
					local ErrorTypeStr = StringUtil.FormatSimple("EventDispatcher:DispatchType failed with eventname {0}:", type_name)
					if obj.caller then
						-- callResult = obj.call_back(obj.caller, data)
						local res,info = EnsureCall(ErrorTypeStr, obj.call_back,obj.caller, data)
						if res then
							callResult = info
						end
					else
						-- callResult = obj.call_back(data)
						local res,info = EnsureCall(ErrorTypeStr, obj.call_back, data)
						if res then
							callResult = info
						end
					end
					count = count + 1
					if self.Swallow and callResult then
						--发生事件吞噬，停止传递
						CWaring("DispatchType be swallowed!: " .. type_name)
						break
					end
				else
					if not valid_call then
						CError("forgot to remove listener,please check! : " .. type_name)
						obj.is_removed = true
					end
				end
			end
		end
	end	
	self.dispatching_map[type_name] = false
	
	if need_clear then
		local newList = {}
		for i,obj in pairs(list) do
			if (obj ~= nil) then
				if not obj.is_removed then
					table.insert(newList, obj)
				end
			end
		end
		self.listener_list[type_name] = newList
	end
	
	return count
end

return EventDispatcher