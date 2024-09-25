local GenericSkillActionTips = Class("Common.Framework.UserWidget")


function GenericSkillActionTips:OnInit()
    UserWidget.OnInit(self)
end

function GenericSkillActionTips:OnDestroy()
    UserWidget.OnDestroy(self)
end

function GenericSkillActionTips:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:SetTipsImageAndText()
end

function GenericSkillActionTips:SetTipsImageAndText()
    local bShowOtherText = #self.OtherText:GetText() == 0
    local bShowReleaseText = #self.ReleaseText:GetText() == 0
    local bShowCancelText = #self.CancelText:GetText() == 0

    if bShowOtherText then 
        self.OtherAction:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.OtherAction:SetVisibility(UE.ESlateVisibility.Visible)
    end
    
    if bShowReleaseText then 
        self.ReleaseAction:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.ReleaseAction:SetVisibility(UE.ESlateVisibility.Visible)
    end

    if bShowCancelText then 
        self.CancelAction:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.ImgLine:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.CancelAction:SetVisibility(UE.ESlateVisibility.Visible)
        self.ImgLine:SetVisibility(UE.ESlateVisibility.Visible)
    end 
end

return GenericSkillActionTips
