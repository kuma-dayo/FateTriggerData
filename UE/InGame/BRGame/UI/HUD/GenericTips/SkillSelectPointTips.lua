local SkillSelectPointTips = Class("Common.Framework.UserWidget")

function SkillSelectPointTips:OnInit()
    UserWidget.OnInit(self)
end

function SkillSelectPointTips:OnDestroy()
    UserWidget.OnDestroy(self)
end

function SkillSelectPointTips:OnShow()
    if self.vx_selectpoin_in then self:VXE_HUD_SelectPoinTips_In() end
end

function SkillSelectPointTips:OnClose()
    if self.vx_selectpoin_out then self:VXE_HUD_SelectPoinTips_Out() end
end

function SkillSelectPointTips:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    if self.GenericSkillActionTips then
        self.GenericSkillActionTips.OtherText:SetText(self.OtherText:GetText())
        self.GenericSkillActionTips.ReleaseText:SetText(self.ReleaseText:GetText())
        self.GenericSkillActionTips.CancelText:SetText(self.CancelText:GetText())
        self.GenericSkillActionTips:SetTipsImageAndText()
    end
end

return SkillSelectPointTips