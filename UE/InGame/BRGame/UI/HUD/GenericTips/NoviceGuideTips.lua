local NoviceGuideTips = Class("Common.Framework.UserWidget")

--Guide.PickupItemList
--Guide.PoisonCircle
--Guide.AmmoInBag

function NoviceGuideTips:OnInit()
    self.ArrowFacingArray = 
    {
        [1] = {self.Up, UE.EHorizontalAlignment.HAlign_Center, UE.EVerticalAlignment.VAlign_Top, -180},
        [2] = {self.Down, UE.EHorizontalAlignment.HAlign_Center, UE.EVerticalAlignment.VAlign_Bottom, 0},
        [3] = {self.Left, UE.EHorizontalAlignment.HAlign_Left, UE.EVerticalAlignment.VAlign_Center, 90},
        [4] = {self.Right, UE.EHorizontalAlignment.HAlign_Right, UE.EVerticalAlignment.VAlign_Center, -90}
    }

    UserWidget.OnInit(self)
end

function NoviceGuideTips:OnDestroy()
    UserWidget.OnDestroy(self)
end

function NoviceGuideTips:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)

    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackBoardKeySelector.SelectedKeyName = "Anchors"
    local AnchorsVector, bFindAnchors = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsVector(TipGenricBlackboard, BlackBoardKeySelector)
    if bFindAnchors then
        local NewAnchors = UE.FAnchors()
        NewAnchors.Minimum = UE.FVector2D(AnchorsVector.X, AnchorsVector.Y)
        NewAnchors.Maximum = NewAnchors.Minimum
        self.Overlay.Slot:SetAnchors(NewAnchors)
    end

    BlackBoardKeySelector.SelectedKeyName = "Alignment"
    local AlignmentVector, bFindAlignment = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsVector(TipGenricBlackboard, BlackBoardKeySelector)
    if bFindAlignment then
        local NewAlignment = UE.FVector2D(AlignmentVector.X, AlignmentVector.Y)
        self.Overlay.Slot:SetAlignment(NewAlignment)
    end
    
    local XOffset = tonumber(self.PositionXOffset:GetText())
    local YOffset = tonumber(self.PositionYOffset:GetText())
    if XOffset and YOffset then self.Overlay.Slot:SetPosition(UE.FVector2D(XOffset, YOffset)) end
    self:SetArrowFacing()
end

function NoviceGuideTips:SetArrowFacing()
    local ArrowFacingNum = tonumber(self.ArrowFacing:GetText())
    self.Img_Arrow:SetVisibility(UE.ESlateVisibility.Collapsed) 
    if not ArrowFacingNum then return end
    if ArrowFacingNum == 0 then return end
    for i, v in pairs(self.ArrowFacingArray) do
        if i == ArrowFacingNum then
            self.Img_Arrow:SetVisibility(UE.ESlateVisibility.Visible) 
            local ArrowSlot = UE.UWidgetLayoutLibrary.SlotAsOverlaySlot(self.Img_Arrow)
            ArrowSlot:SetPadding(v[1])
            ArrowSlot:SetHorizontalAlignment(v[2])
            ArrowSlot:SetVerticalAlignment(v[3])
            self.Img_Arrow:SetRenderTransformAngle(v[4])
        end
    end
end


return NoviceGuideTips

