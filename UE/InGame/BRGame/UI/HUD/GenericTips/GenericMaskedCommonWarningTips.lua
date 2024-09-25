require ("Common.Utils.StringUtil")

local GenericMaskedCommonWarningTips = Class("Common.Framework.UserWidget")

function GenericMaskedCommonWarningTips:OnInit()
    self.CountDownTime = 0
    self.WarningTipsText = ""
    UserWidget.OnInit(self)
end

function GenericMaskedCommonWarningTips:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self.CountDownTime = NewCountDownTime
    self.WarningTipsText = self.TxtTips:GetText()
    if self.vx_GenericMaskedCommonWarningTips_in then self:VXE_HUD_GenericCommonWarningTips_In() end
    self.TxtTips:SetText(StringUtil.Format(self.WarningTipsText, math.floor(self.CountDownTime)))
end

function GenericMaskedCommonWarningTips:Tick(MyGeometry, InDeltaTime)
    if self.CountDownTime > 0 then
        local FormatDeltaTime = string.format("%.1f", InDeltaTime)
        self.CountDownTime = self.CountDownTime - FormatDeltaTime
        self.TxtTips:SetText(StringUtil.Format(self.WarningTipsText, math.floor(self.CountDownTime)))
        if self.CountDownTime == 1 then
            if self.vx_GenericMaskedCommonWarningTips_out then self:VXE_HUD_GenericCommonWarningTips_Out() end
        end
    end
end

function GenericMaskedCommonWarningTips:OnDestroy()
    UserWidget.OnDestroy(self)
end


return GenericMaskedCommonWarningTips