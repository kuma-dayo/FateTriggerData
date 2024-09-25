require "UnLua"

local UpdateCharacterGait = Class()

function UpdateCharacterGait:EventUpdateState(InDeltaTime)
    local Character = self:GetCharacter()
    if not Character then
        return
    end

    local MoveComp = Character.CharacterMovement

    -- Enforce Code Gait Restriction
    local AllowedGait = Character:GetAllowedGait()
    -- State Machine Restriction, Test with try enter state
    
    Character:GetTargetGait(AllowedGait)
    local ActualGait = Character:GetActualGait()
    
    --if ActualGait ~= Character.Gait then
        -- TODO: Need Enter New Gait Here
    --    Character:SetGait(ActualGait)
    --end
    
    MoveComp:SetAllowedGait(AllowedGait)
    
    --print(Character:GetName())
end

function UpdateCharacterGait:GetAllowedGait()
    local Character = self:GetCharacter()
    
    if Character.Stance ~= UE.ES1BRStance.Prone then
        if Character.RotationMode ~= UE.ES1BRRotationMode.Aiming then
            if Character.DesiredGait == UE.ES1BRGait.Sprinting then
                if Character:CanSprint() then return UE.ES1BRGait.Sprinting else return UE.ES1BRGait.Running end
            end
        end
    end

    if (Character.DesiredGait == UE.ES1BRGait.Sprinting) then
        return UE.ES1BRGait.Running
    end
    
    return Character.DesiredGait
end

function UpdateCharacterGait:GetActualGait(AllowedGait)
    local Character = self:GetCharacter()
    local MoveComp = Character.CharacterMovement

    local LocWalkSpeed = MoveComp.CurrentMovementSettings.WalkSpeed
    local LocRunSpeed = MoveComp.CurrentMovementSettings.RunSpeed

    if Character.Speed > (LocRunSpeed + 10) then
        if AllowedGait == UE.ES1BRGait.Sprinting then
            return UE.ES1BRGait.Sprinting
        else
            return UE.ES1BRGait.Running
        end
    end
    
    if Character.Speed > (LocWalkSpeed + 10) then
        return UE.ES1BRGait.Running
    end
    
    return UE.ES1BRGait.Walking
end

return UpdateCharacterGait