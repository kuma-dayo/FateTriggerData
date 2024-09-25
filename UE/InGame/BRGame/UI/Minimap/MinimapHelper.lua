--
-- 小地图工具
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.02.17
--

require("Common.Framework.CommFuncs")
require("Common.Framework.UIHelper")


local MinimapHelper = _G.MinimapHelper or {}

local LayoutDTPath = UIHelper.LayoutDTPath.MinimapPanelSubData

-------------------------------------------- Config/Enum ------------------------------------

-- 裁剪缩放倍数
MinimapHelper.ClipScaleRate = 2.25

-- 动态图标类型
MinimapHelper.EDynamicIconTypes = {
	ActorStatic = 1, ActorDynamic = 2, 
	PosWorld 	= 5, PosScreen 	  = 6, PosMapMark	= 7, PosMapCenter	= 8,
}
SetErrorIndex(MinimapHelper.EDynamicIconTypes)

-- 地图名字等级
MinimapHelper.EMapNameLevel = {
	L1 = 1, L2 = 2,
}
SetErrorIndex(MinimapHelper.EMapNameLevel)

-------------------------------------------- Common ------------------------------------

function MinimapHelper.GetTeamMemberColor(InIndex)
	local TeamPos = InIndex or 1
	local MiscSystem = UE.UMiscSystem.GetMiscSystem(GameInstance)
	if MiscSystem then
		local RetCol = MiscSystem.TeamColors:FindRef(TeamPos)
		if RetCol then
			return RetCol
		end
	end

	local ColorKeys = { UE.FLinearColor(0, 0.3, 1, 1),
		UE.FLinearColor(0, 1, 0.2, 1), UE.FLinearColor(0.65, 0, 0.75, 1), UE.FLinearColor(0.75, 0.75, 0, 1) }
	return ColorKeys[TeamPos]
end

function MinimapHelper.GetFallDownColor()
	return UIHelper.LinearColor.Red
end

function MinimapHelper.GetDeathColor()
	return UIHelper.LinearColor.Grey
end

-------------------------------------------- MinimapActor ------------------------------------

-- 获取并初始化MinimapActor
function MinimapHelper.GetMinimapActor(InContext)
	local MapManagerSystem = UE.UMinimapManagerSystem.GetMinimapManagerSystem(InContext)

	if MapManagerSystem then
		return	MapManagerSystem:GetMiniMapInfo()
	end
end

-- 获取MinimapConfig
function MinimapHelper.GetMinimapConfigData(InKey)
    local LayoutDT = UE.UObject.Load(LayoutDTPath)
    local WidgetData = UE.UDataTableFunctionLibrary.GetRowDataStructure(LayoutDT, InKey)
	return WidgetData
end

-- 创建子对象控件
function MinimapHelper.CreateSubWidget(InMainWidget, InKey, InParent, bWidgetKeyAsName, InNewWidgetName)
    local LayoutDT = UE.UObject.Load(LayoutDTPath)
	return UIHelper.CreateSubWidget(InMainWidget, LayoutDT, InKey, InParent, bWidgetKeyAsName, InNewWidgetName)
end

-------------------------------------------- RingActor ------------------------------------

-- 获取毒圈Actor
function MinimapHelper.GetRingActor(InContext)
	return UE.ARingActor.GetRingActorFromWorld(InContext)
end

-------------------------------------------- Debug ------------------------------------


-------------------------------------------- Require ------------------------------------

_G.MinimapHelper = MinimapHelper

return MinimapHelper
