require "UnLua"

local PickActor_BootyBox = Class()

-- function PickActor_BootyBox:ReceiveBeginPlay()
--     self.PrepickScale = self.NormalScale
-- end

-- function PickActor_BootyBox:ReceiveTick(DeltaSeconds)
--     if self:GetLocalRole() == UE.ENetRole.ROLE_Authority then
--         return
--     end
--     local PC = UE.UGameplayStatics.GetPlayerController(self, 0)
--     if not PC then
--         return
--     end
--     local Pawn = PC:K2_GetPawn()
--     if not Pawn then
--         return
--     end
--     local Distance = UE.UKismetMathLibrary.Vector_Distance(Pawn:K2_GetActorLocation(),self:K2_GetActorLocation())
--     if self.ScaleCurve then
--         self.ScaleCurveValue = self.ScaleCurve:GetVectorValue(Distance)
--         self:UpdateScale()
--     end
-- end

-- function PickActor_BootyBox:PrePickBegin(InPicker, InPickupObj)
--     self.PrepickScale = self.AimScale
--     self:UpdateScale()
-- end

-- function PickActor_BootyBox:PrePickEnd(InPicker, InPickupObj)
--     self.PrepickScale = self.NormalScale
--     self:UpdateScale()
-- end

-- function PickActor_BootyBox:UpdateScale()
--     if self.PickupObj and self.PickupObj.ParticleComp then
--         self.PickupObj.ParticleComp:SetRelativeScale3D(UE.UKismetMathLibrary.Multiply_VectorVector(self.PrepickScale, self.ScaleCurveValue))
--     end
-- end

return PickActor_BootyBox