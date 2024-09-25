require "UnLua"

local UpdateGroundedRotation = Class()

function UpdateGroundedRotation:EventUpdateState(InDeltaTime)
    local Character = self:GetCharacter()
    local MoveComp = Character.CharacterMovement

    local bCanUpdateMovingRot = ((Character.bIsMoving and Character.bHasMovementInput) or Character.Speed > 150) and (not Character:HasAnyRootMotion())
    
    if bCanUpdateMovingRot then
        local GroundedRotationRate = self:CalculateGroundedRotationRate()
        if Character.RotationMode == UE.ES1BRRotationMode.VelocityDirection then
            self:SmoothCharacterRotation(UE.FRotator(0, Character.LastVelocityRotation.Yaw, 0), 800, GroundedRotationRate, InDeltaTime)
        elseif Character.RotationMode == UE.ES1BRRotationMode.LookingDirection then
            local YawValue
            if Character.Gait == UE.ES1BRGait.Sprinting then
                YawValue = Character.ReplicatedCurrentAcceleration.ToOrientationRotator().Yaw
            else
            
            end
        elseif Character.RotationMode == UE.ES1BRRotationMode.Aiming then
            
        end
        
    else
        local ControlYaw = Character.AimingRotation and Character.AimingRotation.ControlYaw or 0
        
        Character.TargetRotation = UE.UKismetMathLibrary.RInterpTo_Constant(Character.TargetRotation, UE.FRotator(0, ControlYaw, 0), InDeltaTime, 1000)
        Character:K2_SetActorRotation(Character.TargetRotation, true)
    end
    --print(ActualGait)
    --print(Character:GetName())
end

function UpdateGroundedRotation:CalculateGroundedRotationRate(InDeltaTime)
    return 10
end

function UpdateGroundedRotation:SmoothCharacterRotation(Target, TargetInterpSpeed, ActorInterpSpeed, InDeltaTime)
    local Character = self:GetCharacter()

    Character.TargetRotation = UE.UKismetMathLibrary.RInterpTo_Constant(Character.TargetRotation, Target, InDeltaTime, TargetInterpSpeed)
    Character:K2_SetActorRotation(UE.UKismetMathLibrary.RInterpTo(Character:GetActorRotation(), Character.TargetRotation, InDeltaTime, ActorInterpSpeed), true)
end

return UpdateGroundedRotation