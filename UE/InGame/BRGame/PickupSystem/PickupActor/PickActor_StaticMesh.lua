require "UnLua"

local PickActor_StaticMesh = Class()

function PickActor_StaticMesh:ReceiveBeginPlay()
    self.PrepickScale = self.NormalScale
end

function PickActor_StaticMesh:ReceiveTick(DeltaSeconds)
    if self:GetLocalRole() == UE.ENetRole.ROLE_Authority then
        return
    end
    local PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not PC then
        return
    end
    local Pawn = PC:K2_GetPawn()
    if not Pawn then
        return
    end
    local Distance = UE.UKismetMathLibrary.Vector_Distance(Pawn:K2_GetActorLocation(),self:K2_GetActorLocation())
    if self.ScaleCurve then
        self.ScaleCurveValue = self.ScaleCurve:GetVectorValue(Distance)
        self:UpdateScale()
    end
end

function PickActor_StaticMesh:PrePickBegin(InPicker, InPickupObj)
    self.PrepickScale = self.AimScale
    self:UpdateScale()
end

function PickActor_StaticMesh:PrePickEnd(InPicker, InPickupObj)
    self.PrepickScale = self.NormalScale
    self:UpdateScale()
end

function PickActor_StaticMesh:UpdateScale()
    if self.PickupObj and self.PickupObj.ParticleComp then
        self.PickupObj.ParticleComp:SetRelativeScale3D(UE.UKismetMathLibrary.Multiply_VectorVector(self.PrepickScale, self.ScaleCurveValue))
    end
end

return PickActor_StaticMesh