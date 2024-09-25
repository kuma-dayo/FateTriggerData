--Base
require("Common.Utils.PoolManager")
require("Common.Utils.CommonUtil")
require("Common.Lib.Util")
require("Core.Mvc.ModuleListRegister")
require("Core.Misc.ListModel")
require("Core.Misc.MapModel")
require("Common.Events.CommonEvent")
require("Common.Mvc.UserGameController")

--Net
require("Server.Net.DSProtoCtrl")

--Module
require("Server.DSServerCtrl")


local class_name = "DSMainCtrl";
local super = ModuleListRegister;
--[[主控制注册器]]
---@class DSMainCtrl : ModuleListRegister
DSMainCtrl = DSMainCtrl or BaseClass(super, class_name);

function DSMainCtrl:__init()
	-- --主控制器或小模块控制器注册
	self:RegisterModule(DSProtoCtrl) ;		--协议管理器
	self:RegisterModule(DSServerCtrl) ;		--服务器Ctrl处理	
end
function DSMainCtrl:__dispose()
	PoolManager.Clear();
end

function DSMainCtrl:Initialize()
	super.Initialize(self);
	self:SendMessage(CommonEvent.ON_GAME_INIT);
end

function DSMainCtrl:OnQuit(is_press)

end



