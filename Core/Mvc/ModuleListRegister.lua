require("Core.Mvc.GameController");

local class_name = "ModuleListRegister";
local super = GameController;
---@class ModuleListRegister : GameController
ModuleListRegister = ModuleListRegister or BaseClass(super, class_name);
--[[大模块控制器批量注册器]]
function ModuleListRegister:__init()
	-- self.__class_name = class_name;
	self.auto_init_type = 2;
end

function ModuleListRegister:Initialize() 
	if(self.module_list ~= nil) then
		local init_list = {};
		for k, classRef in pairs(self.module_list) do
			local ctrl = self:GetSingleton(classRef);
			ctrl.view_id =  k;
			if(ctrl.auto_init_type == 2) then
				table.insert(init_list, ctrl);
			end
		end
		
		--先实例化后初始化
		for k,ctrl in pairs(init_list) do
			ctrl:Initialize();
		end
		--初始化后注册事件
		for k,ctrl in pairs(init_list) do
			ctrl:AddMsgListeners();
		end
	end
end

function ModuleListRegister:__dispose()
	if(self.module_list ~= nil) then
		for k, classRef in pairs(self.module_list) do
			local ctrl = self:RemoveSingleton(classRef);
			if ctrl ~= nil then
				ctrl:RemoveMsgListeners();
				ctrl:Dispose();
			end
		end
		self.module_list = nil;
	end
end

function ModuleListRegister:RegisterModule(classRef) 
	if not classRef then
		CError("ModuleListRegister RegisterModule classRef nil! Please Check!",true)
		return
	end
	self.module_list = self.module_list or {};
	table.insert(self.module_list, classRef);
end

return ModuleListRegister;