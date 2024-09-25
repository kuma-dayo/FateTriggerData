--[[
事件处理机制基础类 用于Unlua类
类似Flash事件, 有优先级功能,通过抛出Event来推动逻辑;
]]
---@class EventDispatcherUn
EventDispatcherUn = Class()

function EventDispatcherUn:Construct()
	self.Overridden.Construct(self)
	-- self.__class_name = class_name;
	self.listener_list = {};
	self.changed_map = {};
	self.count = 0;
	self.dispatching_map = {};
end

function EventDispatcherUn:Destruct()	
	self.Overridden.Destruct(self)
	-- CWaring("EventDispatcherUn:Destruct()")
	self.listener_list = nil;
	self.changed_map = nil;
	self.count = 0;
	self.dispatching_map = nil;
end


--[[
添加一个事件
@param type_name string|int 事件关键字
@param call_back Function 事件回调函数
@param caller table 监听者
@param priority int 执行优先级,数字越大越提前执行
]]
function EventDispatcherUn:AddListener(type_name, call_back, caller,priority) 
	local  list = self.listener_list[type_name];
	priority = priority or 0;
	if (list == nil) then
		list = {};
		self.listener_list[type_name] = list;		
	else
		for i,obj in pairs(list) do
			if(obj.call_back == call_back) and (not caller or caller == obj.caller) then
				obj.priority = priority;
				obj.is_removed = false;
				return ;
			end
		end
	end
	self.count = self.count+1;
	table.insert(list, {call_back = call_back,caller = caller, priority = priority, id = self.count});
	self.changed_map[type_name] = true;
end

--[[
删除一个事件
@param type_name string|int 事件关键字
@param call_back Function 事件回调函数
@param caller table 监听者
]]
function EventDispatcherUn:RemoveListener(type_name, call_back,caller) 
	local  list = self.listener_list[type_name];
	if (list ~= nil) then
		local is_dispatching = self.dispatching_map[type_name];
		for i,obj in pairs(list) do
			if(obj.call_back == call_back) and (not caller or caller == obj.caller) then
				if(is_dispatching) then
					obj.is_removed = true;
				else
					table.remove(list, i);
				end
				return ;
			end
		end
	end
end

--[[
	是否存在为某个事件 注册的监听
]]
function EventDispatcherUn:HasListeners(type_name)
	if not type_name then
		CError("EventDispatcher:HasListeners type_name nil",true)
		return
	end
	local ListenersNum = 0
	local list = self.listener_list[type_name];
	if list and #list > 0 then
		for i,obj in pairs(list) do
			if not obj.is_removed then
				ListenersNum = ListenersNum + 1
			end
		end
	end
	return (ListenersNum > 0 and ListenersNum or nil)
end


--[[
抛出一个事件(简易模式)
@param type_name 事件名称
@param data 抛出的数据
]]
function EventDispatcherUn:DispatchType(type_name, data)
	if not self.listener_list then
		return
	end
	local  list = self.listener_list[type_name];
	-- print('DispatchType', type_name, data, list, list == nil and 0 or #list)
	if (list ~= nil) then
		local  count = 0;
		local need_clear = false;
		if not self.dispatching_map then
			return
		end
		self.dispatching_map[type_name] = true;
		for i,obj in pairs(list) do
			if (obj ~= nil) then
				if obj.is_removed then
					need_clear = true;
				else
					if obj.caller then
						obj.call_back(obj.caller,data);
					else
						obj.call_back(data);
					end
					count = count + 1;
				end
			end
		end
		if not self.dispatching_map then
			--可能在上述逻辑执行时，已经触发自身的Destruct,将相关值置空了
			return
		end
		self.dispatching_map[type_name] = false;
		if need_clear then
			local newList = {};
			for i,obj in pairs(list) do
				if (obj ~= nil) then
					if not obj.is_removed then
						table.insert(newList, obj);
					end
				end
			end
			self.listener_list[type_name] = newList;
		end
		return count;
	end
	return 0;
end

return EventDispatcherUn;