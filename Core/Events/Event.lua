require("Core.BaseClass");

local class_name = "Event";
Event = Event or BaseClass(nil, class_name);
Event.COMPLETE = "complete";
Event.CHANGED = "changed";

--[[事件基础类
@param type_name string 事件类型名称
@param data Object 事件需要传送的参数
@param auto_dispose Boolean 是否自动消毁本实例, 默认是消毁, 常用的实例可以保存,不用再实例化新对象;
]]
function Event:__init(type_name, data, auto_dispose)	
	if (auto_dispose == nil) then
		auto_dispose = true;
	end
	self.type_name = type_name;
	self.__enabled = true;
	self.data = data;
	self.auto_dispose = auto_dispose; -- 自动销毁
	self.target = nil;--EventDispatcher对象

end
--[[中止后续抛事件]]
function Event:Stop()
	self.__enabled = false;
end

function Event:__dispose()
	self.type_name = nil ;
	self.data = nil;
	self.target = nil;
	self.__base_name = nil;
end
return Event;