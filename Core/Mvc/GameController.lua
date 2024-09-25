require("Core.Mvc.Controller")
require("Core.Events.GameEventDispatcher")
require("Common.Events.CommonEvent")

local class_name = "GameController"
---程序逻辑控制器, self.auto_init_type = 2
---@class GameController : Controller
GameController = GameController or BaseClass(Controller, class_name)
local global_proto_dispatcher = EventDispatcher.New()

function GameController:__init()
	self.auto_init_type = 2
	---@type EventDispatcher
	self.proto_dispatcher = global_proto_dispatcher
	self.proto_map = {}
	self.auto_record = true  	--自动记录所注册的协议回调，继承类可以通过协议号就可以自动移除回调
end

function GameController:__dispose()
	if self.proto_dispatcher ~= nil then
		self.proto_dispatcher = nil
	end
	self.proto_map = nil
end

---协议处理，添加协议监听
---@param msgId string 协议号
---@param handler fun(proto:table):void 回调函数
---@param caller table obj 调用对象
---@return void
function GameController:AddProtoRPC(msgId, handler, caller)
	if not msgId then
		CError("AddProtoRPC cmd nil:" .. self:ClassName(),true)
		return
	end
	if not handler then
		CError("AddProtoRPC handler(callback) nil:" .. self:ClassName() .. "|CMD:" .. msgId,true)
		return
	end
	
	if self.auto_record then
		if self.proto_map[msgId] then
			CError("重复添加协议监听，请检查",true)
			return
		end
		self.proto_map[msgId] = handler
	end
	
	if s2c[msgId] then
		CError("重复添加RPC协议监听,请检查:" .. self:ClassName() .. "|MsgId:" .. msgId,true)
		return
	end
	
	s2c[msgId] = Bind(caller, handler)
end


---删除协议监听
---@param msgId string 协议号
---@param handler|nil fun(proto:table):void 回调函数
function GameController:RemoveProtoRPC(msgId, handler)
	if not msgId then
		CError("RemoveProtoRPC cmd nil")
		return
	end
	
	if self.auto_record then
		handler = handler or self.proto_map[msgId]
		self.proto_map[msgId] = nil
	end
	
	s2c[msgId] = nil
end

---发送协议给服务器
---@param cmd string 发送的协议ID
---@param msgBody any 发送的内容
---@param recvCmd string 期望收到的协议ID  这个有值则会默认开启协议转圈
---@param reliable bool  是否可靠，为真的情况下，如果发送失败，会Cache到下次重连后再次尝试发送 (只针对客户端生效，对DS无效)
function GameController:SendProto(cmd, msgBody, recvCmd,reliable)
	if not cmd then
		CError("Error: SendProto cmd nil",true)
		return
	end
	if not msgBody then
		CError("Error: SendProto msgBody nil with cmd:" .. cmd)
		return
	end
	
	local proto = {
		cmd = cmd,
		msgBody = msgBody,
		reliable = reliable,
	}
	if cmd and recvCmd and _G.GameInstance then
		NetLoading.Add(cmd, recvCmd)
	end	
	self:SendMessage(CommonEvent.SEND_PROTO, proto)
end

---打开面板
---@param viewId number 界面Id
---@param data any 界面OnShow时候的数据
function GameController:OpenView(viewId, data)
	if not viewId then
		CError("Error: OpenView viewId nil", true)
		return
	end
	print("GameController:OpenView", viewId)
	self:SendMessage(CommonEvent.SHOW_VIEW_CHECK, {viewId = viewId, param = data})
end

---关闭面板
---@param viewId number 界面Id
---@param data any 界面OnShow时候的数据
---@param force boolean 关卡/流关卡/关卡类虚拟视图不能主动关闭，需要设置这个值为true才能主动关闭，慎用
---@param notSwitchScene boolean 关闭界面默认会进行虚拟场景切换 notSwitchScene可阻拦这一操作
function GameController:CloseView(viewId, data, force, notSwitchScene)
	if not viewId then
		CError("Error: CloseView viewId nil", true)
		return
	end
	print("GameController:CloseView", viewId)
	self:SendMessage(CommonEvent.HIDE_VIEW_CHECK, {viewId = viewId, param = data, force = force, notSwitchScene = notSwitchScene})
end

---根据面板打开状态关闭或打开
---@param viewId number 界面Id
---@param data any 界面切换显示时候的数据
function GameController:ToggleView(viewId, data)
	if not viewId then
		CError("Error: ToggleView viewId nil", true)
		return
	end
	
	self:SendMessage(CommonEvent.TOGGLE_VIEW, {viewId = viewId, param = data})
end

return GameController