local GenericCommonImageTips = Class("Common.Framework.UserWidget")

function GenericCommonImageTips:OnInit()
    self.CountDownTime = 0
    UserWidget.OnInit(self)
end

function GenericCommonImageTips:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self.CountDownTime = NewCountDownTime
    if self.vx_genericcommonimagetips_in then self:VXE_HUD_GenericCommonImageTips_In() end
end

function GenericCommonImageTips:Tick(MyGeometry, InDeltaTime)
    if self.CountDownTime > 0 then
        local FormatDeltaTime = string.format("%.1f", InDeltaTime)
        self.CountDownTime = self.CountDownTime - FormatDeltaTime
        if self.CountDownTime == 1 then
            if self.vx_genericcommonimagetips_out then self:VXE_HUD_GenericCommonImageTips_Out() end
        end
    end
end

function GenericCommonImageTips:OnDestroy()
    UserWidget.OnDestroy(self)
end


return GenericCommonImageTips