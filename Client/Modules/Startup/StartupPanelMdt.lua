--[[
	废弃
]]
-- local class_name = "StartupPanelMdt";
-- StartupPanelMdt = StartupPanelMdt or BaseClass(GameMediator, class_name);

-- function StartupPanelMdt:__init()
-- end

-- function StartupPanelMdt:OnShow(data)
-- 	CLog("-----OnShow")
	
-- end

-- function StartupPanelMdt:OnHide()
-- 	CLog("-----OnHide")
-- end

-- -------------------------------------------------------------------------------

-- local M = Class("Client.Mvc.UserWidgetBase")

-- --由mdt触发调用
-- function M:OnShow(data)
-- 	CLog(">>HotPatch 测试<<")

-- 	--TODO 延迟X秒以后再进去到登录关卡
-- 	self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.TimerHandle}, 2,false)
-- end

-- function M:OnHide()
-- 	if self.TimerHandle then
-- 		UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
-- 		self.TimerHandle = nil
-- 	end
-- end

-- function M:TimerHandle()
-- 	MvcEntry:CloseView(self.viewId)
-- end

-- return M