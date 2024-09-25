require "UnLua"

local UnreachableZoneArrowUI = Class("Common.Framework.UserWidget")

function UnreachableZoneArrowUI:Construct()
    self.LocalCH = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
    if self.LocalCH == nil then return end
    self.LocalCHCapsuleComponent = self.LocalCH.CapsuleComponent
end

function UnreachableZoneArrowUI:Tick(MyGeometry, InDeltaTime)
    if not self.LocalCH then return end
    if not self.LocalCHCapsuleComponent then return end
    if not CommonUtil.IsValid(self.LocalCH) then
        return
    end
    local CurCHLocation = self.LocalCH:K2_GetActorLocation()
    local OffsetVector = CurCHLocation - self.ZoneCenter
    local CurDes = self:CaculateArrowDestination(OffsetVector)

    local LocalCHForwardVec = self.LocalCHCapsuleComponent:GetForwardVector()
    local AngleCos = UE.UKismetMathLibrary.Vector_CosineAngle2D(OffsetVector, LocalCHForwardVec)
    local Angle = UE.UKismetMathLibrary.DegAcos(AngleCos)
    if not CurDes then
        Angle = -Angle
    end 

    --箭头更改方向
    self.VX:SetRenderTransformAngle(Angle)

    --箭头更改位置
    local ArrowLocation = UE.FVector2D()
    ArrowLocation.x = self.Rad * UE.UKismetMathLibrary.DegSin(Angle)
    ArrowLocation.y = self.Rad * AngleCos * -1
    local ArrowSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.VX)
    ArrowSlot:SetPosition(ArrowLocation)
end

function UnreachableZoneArrowUI:CaculateArrowDestination(OffsetVector)
    local LocalCHRightVec = self.LocalCHCapsuleComponent:GetRightVector()
    local CurCos = UE.UKismetMathLibrary.Vector_CosineAngle2D(OffsetVector, LocalCHRightVec)
    if CurCos >= 0 then
        return true
    else
        return false
    end
end

return UnreachableZoneArrowUI