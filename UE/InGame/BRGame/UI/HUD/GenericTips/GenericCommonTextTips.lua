local GenericCommonTextTips = Class("Common.Framework.UserWidget")

function GenericCommonTextTips:OnInit()
    self.CountDownTime = 0
    UserWidget.OnInit(self)
end

function GenericCommonTextTips:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self.CountDownTime = NewCountDownTime
    if self.vx_commontips_in then self:VXE_HUD_CommonTips_In() end
    if self.vx_warningtips_in then self:VXE_HUD_WarningTips_In() end
end

function GenericCommonTextTips:Tick(MyGeometry, InDeltaTime)
    if self.CountDownTime > 0 then
        local FormatDeltaTime = string.format("%.1f", InDeltaTime)
        self.CountDownTime = self.CountDownTime - FormatDeltaTime
        --根据Min Tick Interval Time设置阈值
        if self.CountDownTime == 1  then
            if self.vx_commontips_out then self:VXE_HUD_CommonTips_out() end
            if self.vx_warningtips_out then self:VXE_HUD_WarningTips_Out() end
        end
    end
end

function GenericCommonTextTips:OnDestroy()
    UserWidget.OnDestroy(self)
end


return GenericCommonTextTips