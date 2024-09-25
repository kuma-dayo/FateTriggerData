--
-- 被观战玩家 - 对局信息(击杀数/击倒数/救援数)
--
-- @COMPANY	ByteDance
-- @AUTHOR	王泽平
-- @DATE	2023.05.17

--当前被观战玩家的击杀数 击倒数 救援数 
--切换被观战角色重新刷新信息
local OBWatchGameBase = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function OBWatchGameBase:OnInit()
    print("[WZP]OBWatchGameBase >> OnInit WidgetName=",GetObjectName(self))
	UserWidget.OnInit(self)
end

function OBWatchGameBase:OnDestroy()
    print("[WZP]OBWatchGameBase >> OnDestroy WidgetName=",GetObjectName(self))
	UserWidget.OnDestroy(self)
end

function OBWatchGameBase:RegistViewModel()
    
end

function OBWatchGameBase:UnRegistViewModel()
    
end

return OBWatchGameBase

