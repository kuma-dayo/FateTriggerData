--
-- 战斗界面 - 选择物品Line
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.31
--

local SelectItemLine = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------

-------------------------------------------- Init/Destroy ------------------------------------

function SelectItemLine:OnInit()
	UserWidget.OnInit(self)
end

function SelectItemLine:OnDestroy()
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function SelectItemLine:InitData(InParameters)
	self.Parameters = InParameters
	
end

-------------------------------------------- Callable ------------------------------------

return SelectItemLine
