require("Client.Mvc.ViewCtrlBase");
require("Client.Views.ViewConst");


local class_name = "ViewRegister";
--View Mediator 注册器
---@class ViewRegister : ViewCtrlBase
ViewRegister = ViewRegister or BaseClass(ViewCtrlBase, class_name);


function ViewRegister:__init()
	--依赖虚拟场景的UI注册
	for k,v in pairs(VirtualViewConfig) do
		self:RegisterVirtualLevelView(k,v.VirtualSceneId)
	end

	--界面控制器注册
	for k,v in pairs(ViewConstConfig) do
		self:RegisterView(k,v.Class);
	end
end
