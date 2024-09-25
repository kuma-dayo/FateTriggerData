--[[
	钩子 
	当目标widget被销毁时，清理c++侧的引用，并且派发消息进行lua侧的清理
]]
UIBrige = {}
UIBrige.ON_DESTRUCT = "UIBrige_Destruct"
---@class UIBrige : EventDispatcherUn
---@field super EventDispatcherUn
local M = Class("Core.Events.EventDispatcherUn")

function M:Construct()
	self.Super.Construct(self)

	self.ViewId = 0
	--标志初始化成功
	self.InitSuccess = true
	-- print("UIBrige-----Construct")
end

function M:Destruct()
	-- print("UIBrige-----Destruct" .. self.ViewId)
	-- 派发事件，可以进行lua侧的清理
	self:DispatchType(UIBrige.ON_DESTRUCT)
	self.InitSuccess = false
	-- 解除LuaTable在C++侧的引用
	self:Release()
end
--[[
	设置要清理的目标widget
]]
---@public
---@param UMGHandler Widget 即widget实例在lua中的表示
function M:SetHandlerViewId(ViewId)
	self.ViewId = ViewId
end

return M