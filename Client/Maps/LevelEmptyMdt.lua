--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
require("Core.BaseClass");
require("Client.Mvc.GameMediator");
require("Common.Utils.CommonUtil");

local class_name = "LevelEmptyMdt";
LevelEmptyMdt = LevelEmptyMdt or BaseClass(GameMediator, class_name);


function LevelEmptyMdt:__init()
end

function LevelEmptyMdt:OnShow(data)
end

function LevelEmptyMdt:OnHide()
	
end

-------------------------------------------------------------------------------------
---@class LevelEmptyMdt_C
local M = Class()

function M:Initialize(Initializer)
	CLog("LevelEmptyMdt==========Initialize")
end

---@private
function M:OnShow(data)
	CLog("LevelEmptyMdt=======OnShow")

	--[[
		使用控制台命令查看对象和类的引用情况：
    
		查看指定类的引用列表：Obj List Class=ReleaseUMG_Root_C
		查看指定对象的引用链：Obj Refs Name=ReleaseUMG_Root_C_0
	]]
	MvcEntry:GetCtrl(PreLoadCtrl):UnLoadOutSideAction()
	LuaGC()
	UE.UKismetSystemLibrary.CollectGarbage()
	local PlayerController = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
	UE.UKismetSystemLibrary.ExecuteConsoleCommand(GameInstance, "ForceGC", PlayerController)

	local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	UE.UKismetSystemLibrary.ExecuteConsoleCommand(self, "MemReport -Full", LocalPC)

	-- LuaGC()
	-- UE.UKismetSystemLibrary.CollectGarbage()
end

function M:ReceiveEndPlay(EndPlayReason)
	_G.InitLevel = nil
	CLog("LevelEmptyMdt==========ReceiveEndPlay")
	self.Overridden.ReceiveEndPlay(self,EndPlayReason)	
end

return M
