--
-- 战斗界面 - 倒地死亡界面
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.04.15
--

local DyingDeadPanel = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------


-------------------------------------------- Init/Destroy ------------------------------------

function DyingDeadPanel:OnInit()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

	UserWidget.OnInit(self)
end

function DyingDeadPanel:OnDestroy()

	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function DyingDeadPanel:InitData(InParameters)

end

-------------------------------------------- Callable ------------------------------------

-- 
function DyingDeadPanel:Tick(MyGeometry, InDeltaTime)

end

return DyingDeadPanel
