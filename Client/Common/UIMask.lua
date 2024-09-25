local M = Class()

function M:Construct()
    local slot = self.Slot

    local LocationMin = UE.FVector2D()
    LocationMin.x = 0
    LocationMin.y = 0
    local LocationMax = UE.FVector2D()
    LocationMax.x = 1
    LocationMax.y = 1

    slot:SetMinimum(LocationMin)
    slot:SetMaximum(LocationMax)
    
    local LocalFMargin = UE.FMargin()
    LocalFMargin.Left = -50
    LocalFMargin.Right = -50
    slot:SetOffsets(LocalFMargin)
end

function M:Destruct()
end

return M