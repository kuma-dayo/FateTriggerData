require "UnLua"


local Drop_AirDrop = Class()

function Drop_AirDrop:OnInit()

end

function Drop_AirDrop:CanDrop(InDropItemInfoArray,inExtraDropActorArray,InDropReasonTag)
    self.Overridden.CanDrop(self,InDropItemInfoArray,inExtraDropActorArray,InDropReasonTag)
    return true
end

function Drop_AirDrop:PreDrop(InDropItemInfoArray,inExtraDropActorArray,InDropReasonTag)
    self.Overridden.PreDrop(self,InDropItemInfoArray,inExtraDropActorArray,InDropReasonTag)
    local DropItemInfoArray = UE.TArray(UE.FItemTransportInfo)
    local DropDataToAdd = UE.FItemTransportInfo()
    DropItemInfoArray:Add(DropDataToAdd)
    return DropItemInfoArray
end

function Drop_AirDrop:AfterDrop(inDropActors,InDropReasonTag)
    self.Overridden.AfterDrop(self,inDropActors,InDropReasonTag)

end

function Drop_AirDrop:CalculatePosition(inDropNum)
    if inDropNum > 1 then
        local retLocationArray = UE.TArray(UE.FVector)
        if not self.Owner then
            print("nzyp " .. "Owner is Null")
            return retLocationArray
        end
        local TargetLocation = self.Owner.FlightDropLocation
        TargetLocation.Z = self.Owner:K2_GetActorLocation().Z
        retLocationArray:Add(TargetLocation)
        print("nzyp " .. "TargetLocation",TargetLocation.X,TargetLocation.Y,TargetLocation.Z)
        
        if retLocationArray:Length() ~= inDropNum then
            print("nzyp " .. "retLocationArray.Num",retLocationArray:Length())
        end
        return retLocationArray
    end

    return self.Overridden.CalculatePosition(self,inDropNum)
end

function Drop_AirDrop:CalculateExtraActorPosition(inDropNum)
    return self.Overridden.CalculateExtraActorPosition(self,inDropNum)
end

function Drop_AirDrop:IsMultiItem()
    self.Overridden.IsMultiItem(self)
    return true
end

function Drop_AirDrop:ReceiveDestroyed()
    --self:UnBindDynamicLua()
end

function Drop_AirDrop:CalculateCircle(c, Radius, Num, index)
    local Center = UE.FVector()
    Center = c
    local Center2D = UE.FVector2D(Center.X,Center.Y)
    local AverageDegree = math.pi*2*index/Num
    local tx = Center2D.X + Radius * math.cos(AverageDegree)
    local ty = Center2D.Y + Radius * math.sin(AverageDegree)
    local tLocation3D = UE.FVector(tx,ty,Center.Z)
    return tLocation3D
end

return Drop_AirDrop