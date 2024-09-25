local AirFlightWiget = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------




--
function AirFlightWiget:OnInit()
	print("AirFlightWiget >> OnInit, ", GetObjectName(self))
	self.CurTeamPos = 1
	UserWidget.OnInit(self)
end
--
function AirFlightWiget:OnDestroy()
	print("AirFlightWiget >> OnDestroy, ", GetObjectName(self))
	
	UserWidget.OnDestroy(self)
end

-- 已挪到cpp
-- function AirFlightWiget:BPNativeFunc_OnItemCustomUpdate(WhichMap, InTaskData)
-- 	self:SetRenderTransformAngle(self.LineAngle)
-- end

-- function AirFlightWiget:BPNativeFunc_GetStartPosition()
-- 	if self.BRGameState then
-- 		return self.BRGameState.CurrentFlight.StartPoint
-- 	end
-- 	return UE.FVector(0,0,0)
-- end


return AirFlightWiget

