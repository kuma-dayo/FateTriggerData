require ("Common.Utils.StringUtil")

local GenericCommonWarningTips = Class("Common.Framework.UserWidget")

function GenericCommonWarningTips:OnInit()
    self.CountDownTime = 0
    self.WarningTipsText = ""
    UserWidget.OnInit(self)
end

function GenericCommonWarningTips:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self.CountDownTime = NewCountDownTime
    self.WarningTipsText = self.TxtTips:GetText()
    if self.vx_genericcommonwarningtips_in then self:VXE_HUD_GenericCommonWarningTips_In() end
    self.TxtTips:SetText(StringUtil.Format(self.WarningTipsText, math.floor(self.CountDownTime)))
end

function GenericCommonWarningTips:Tick(MyGeometry, InDeltaTime)
    if self.CountDownTime > 0 then
        local FormatDeltaTime = string.format("%.1f", InDeltaTime)
        self.CountDownTime = self.CountDownTime - FormatDeltaTime
        self.TxtTips:SetText(StringUtil.Format(self.WarningTipsText, math.floor(self.CountDownTime)))
        if self.CountDownTime == 1 then
            if self.vx_genericcommonwarningtips_out then self:VXE_HUD_GenericCommonWarningTips_Out() end
        end
    end
end

function GenericCommonWarningTips:OnDestroy()
    UserWidget.OnDestroy(self)
end


return GenericCommonWarningTips