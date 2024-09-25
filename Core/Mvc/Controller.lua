local class_name = "Controller"
local BaseClass = require("Core.BaseClass")
local EventDispatcher = require("Core.Events.EventDispatcher")	--事件发布者基本类, 类似Flash事件, 有优先级功能

---MVC框架之控制器
---@class Controller
Controller = Controller or BaseClass(nil, class_name)
Controller.global_dispatcher = EventDispatcher.New() 	--MVC全局事件对象
Controller.global_singleton_map = {} 					--单例表
Controller.global_model_map = {}						--数据模型单例表

function Controller:__init()
	self.auto_init_type = self.auto_init_type 	or 0								 --自动初始化类型(调用self:Initialize()): 0 不自动初始化; 1 自己初始化; 2 在注册器中初始化;
	---@type EventDispatcher
	self.dispatcher 	= self.dispatcher 		or Controller.global_dispatcher 
	self.singleton_map 	= self.singleton_map 	or Controller.global_singleton_map	--ctrl 使用
	self.model_map 		= self.model_map 		or Controller.global_model_map		--model 使用

	if self.auto_init_type == 1 then
		--注意: 此逻辑不会被执行,请在续承类中自己调用一次
		self:Initialize()
	end
end

function Controller:Initialize() end

function Controller:__dispose() 
	self.dispatcher 	= nil
	self.singleton_map 	= nil
	self.model_map 		= nil
end

function Controller:AddMsgListeners() 	 end
function Controller:RemoveMsgListeners() end

---删除一个单例
---@param key string 关键字
---@return nil|table luaObject
function Controller:RemoveSingleton(key) 
	local obj = self.singleton_map[key]
	self.singleton_map[key] = nil
	return obj
end

---添加一个单例
---@param key table luaClass
---@return nil|table luaObject
function Controller:GetSingleton(key)
	if key == nil or key.IsClass == nil or not key.IsClass(Controller) then
		local name = key.ClassName and key.ClassName() or ""
		print("Error:", key, "is not class type of 'Controller'!", name)
		return nil
	end
	
	local obj = self.singleton_map[key]
	if obj == nil then		
		if key.New ~= nil then
			obj = key.New()
			self.singleton_map[key] = obj
		end
	end
	
	return obj
end

---判断控制器单例是否已经存在（创建过）
---@param key table luaClass
---@return boolean
function Controller:HasSingleton(key) 
	local  obj = self.singleton_map[key]
	return obj ~= nil
end

---取出一个实例化后的Controller对象
---@param key table luaClass Ctrl类
---@return nil|table luaObject
function Controller:GetCtrl(key)
	return self:GetSingleton(key)
end

---取出一个数据模型单例
---@param key table luaClass Model类
---@return nil|table luaObject 实例化了的Model对象
function Controller:GetModel(key)
	if key == nil or key.IsClass == nil or not key.IsClass(EventDispatcher) then
		print("Error:", key, "is not class type of 'EventDispatcher'!")
		print_trackback()
		return nil
	end
	
	local obj = self.model_map[key]
	if obj == nil then
		if key.New ~= nil then
			obj = key.New()
			self.model_map[key] = obj
		end
	end
	
	return obj
end

---注册消息监听
---@param key string 事件关键字
---@param call_back fun 事件回调函数
---@param caller table 监听者
---@param priority number 执行优先级,数字越大越提前执行
function Controller:AddMsgListener(key, call_back, caller, priority) 
	self.dispatcher:AddListener(key, call_back, caller, priority)
end

---删除消息监听
---@param key string 事件关键字
---@param call_back fun 事件回调函数
---@param caller table 监听者
function Controller:RemoveMsgListener(key, call_back, caller) 
	self.dispatcher:RemoveListener(key, call_back, caller)
end

---发送一个全局消息
---@param event_type string 事件名
---@param data any 信息参数
function Controller:SendMessage(event_type, data) 
	self.dispatcher:DispatchType(event_type, data)
end