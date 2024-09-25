local RouteLine = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------




--
function RouteLine:OnInit()
	print("RouteLine", ">> OnInit, ", GetObjectName(self))
	--self.CurTeamPos = 1
	UserWidget.OnInit(self)
end
--
function RouteLine:OnDestroy()
	print("RouteLine", ">> OnDestroy, ", GetObjectName(self))
	
	UserWidget.OnDestroy(self)
end

-- 已挪到CPP
-- function RouteLine:BPNativeFunc_OnItemCustomUpdate(WhichMap, InTaskData)
-- 	local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
-- 	BlackBoardKeySelector.SelectedKeyName = "TeamPos"
-- 	local TeamPos, TeamPosType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(InTaskData.OtherData, BlackBoardKeySelector)

-- 	if TeamPosType then
-- 		self.CurTeamPos = TeamPos
-- 	end

-- 	self:SetRenderTransformAngle(self.LineAngle)

-- 	local TeamPosColor
-- 	local MiscSystem = UE.UMiscSystem.GetMiscSystem(self)
-- 	if MiscSystem then
-- 		TeamPosColor = MiscSystem.TeamColors:FindRef(self.CurTeamPos)
-- 	end
-- 	local ImgColor = MinimapHelper.GetTeamMemberColor(self.CurTeamPos)
-- 	self:SetColorAndOpacity(TeamPosColor)
-- end

-- function RouteLine:BPNativeFunc_OnItemStartShow(WhichMap, InTaskData)
-- 	self:BPNativeFunc_OnItemCustomUpdate(WhichMap, InTaskData)
	
-- end

return RouteLine

