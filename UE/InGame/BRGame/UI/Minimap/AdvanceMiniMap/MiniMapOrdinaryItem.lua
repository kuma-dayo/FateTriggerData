local MiniMapOrdinaryItem = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------




--
function MiniMapOrdinaryItem:OnInit()
	print("MiniMapOrdinaryItem >> OnInit, ", GetObjectName(self))
	
	UserWidget.OnInit(self)
end
--
function MiniMapOrdinaryItem:OnDestroy()
	print("MiniMapOrdinaryItem >> OnDestroy, ", GetObjectName(self))
	
	UserWidget.OnDestroy(self)
end

--挪到cpp UpdateWidgetItemDirInfo中实现
--[[
function MiniMapOrdinaryItem:BPImpFunc_UpdateDirInfo(bLocalPS, bGetCameraRotation, CurActorRot, CurViewRot)
	if bLocalPS and bGetCameraRotation then
		local NewViewAngle = CurViewRot.Yaw + self.OffsetRot
		if NewViewAngle ~= self.NewViewAngle then
			self.NewViewAngle = NewViewAngle
			if self.TrsViewDir then
				self.TrsViewDir:SetRenderTransformAngle(NewViewAngle + 180)
			end
			
		end
		local NewActorAngle = CurActorRot.Yaw + self.OffsetRot
		if self.NewActorAngle ~= NewActorAngle then
			self.NewActorAngle = NewActorAngle
			if self.TrsActorDir then
				self.TrsActorDir:SetRenderTransformAngle(NewActorAngle)
			end
			
		end
	else
		local NewActorAngle = CurActorRot.Yaw + self.OffsetRot
		if self.NewActorAngle ~= NewActorAngle then
			self.NewActorAngle = NewActorAngle
			if self.TrsActorDir then
				self.TrsActorDir:SetRenderTransformAngle(NewActorAngle)
			end
			if self.TrsViewDir then
				self.TrsViewDir:SetRenderTransformAngle(NewActorAngle + 180)
			end
		end
	end
end
]]--

return MiniMapOrdinaryItem


