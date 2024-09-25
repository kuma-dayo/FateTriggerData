require "UnLua"

local UnreachableZoneUI = Class("Common.Framework.UserWidget")

function UnreachableZoneUI:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    print("UnreachableZoneUI:OnTipsInitialize")

    self.RemainTime = 0
    self.CurRemainTime = 0
    --黑色Mask
    self.CurSlateColor = UE.FSlateColor()
    self.CurLinearColor = UE.FLinearColor(0, 0, 0, 0)
    self.CurSlateColor.SpecifiedColor = self.CurLinearColor
    self.GUIImageMask:SetBrushTintColor(self.CurSlateColor)
    --红色Mask
    self.MaskSlateColor = UE.FSlateColor()
    self.MaskLinearColor = UE.FLinearColor(1, 1, 1, 0)
    self.MaskSlateColor.SpecifiedColor = self.MaskLinearColor
    self.T_Mask_Red:SetBrushTintColor(self.CurSlateColor)
    self.T_Mask_Red:SetRenderOpacity(0)
    self.FinalCountDownTime = 5
    self.bStartFinalCountDown = false
    
    local RemainTimeSelector = UE.FGenericBlackboardKeySelector()
    RemainTimeSelector.SelectedKeyName = "RemainTime"
    local OutRemainTime, IsFindRemainTime = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsFloat(TipGenricBlackboard,RemainTimeSelector)
    if not IsFindRemainTime then
        print("UnreachableZoneUI:IsNotFindRemainTime")
        return
    end

    local CenterSelector = UE.FGenericBlackboardKeySelector()
    CenterSelector.SelectedKeyName = "UnreachableZoneCenter"
    local OutZoneCenter, IsFindZoneCenter = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsVector(TipGenricBlackboard,CenterSelector)
    if not IsFindZoneCenter then
        print("UnreachableZoneUI:IsNotFindZoneCenter")
        return
    end
    
    --local OutRemainTime = 10
    --local OutZoneCenter = nil
    --初始化
    if OutRemainTime > 0 then
        self.CurRemainTime = OutRemainTime
        self.RemainTime = OutRemainTime
        self.GUIText_Time:SetText(self.CurRemainTime)
        self.GUIProgressBar_Area:SetFillColorandOpacity(UE.FLinearColor(1, 1, 1, 1))
        self.GUIProgressBar_Area:SetPercent(1)
        self:SetTextVisibility(true)
    else
        self:SetTextVisibility(false)
    end

    if self.WBP_UnreachableArrow then self.WBP_UnreachableArrow.ZoneCenter = OutZoneCenter end
    --print("UnreachableZoneUI:RemainTime ", OutRemainTime, " UnreachableZoneCenter ", OutZoneCenter)
    UE.UGTSoundStatics.PostAkEvent_Asset(self, self.AkEvent_Countdown_Play)
end

function UnreachableZoneUI:Tick(MyGeometry, InDeltaTime)
    if self.CurRemainTime <= 0 then return end
    
    --更改RemainTime显示
    local FormatDeltaTime = string.format("%.1f", InDeltaTime)
    self.CurRemainTime = self.CurRemainTime - FormatDeltaTime
    self.GUIText_Time:SetText(math.floor(self.CurRemainTime))
    --更改进度条显示
    local CurPercent = self.CurRemainTime / self.RemainTime
    --print("UnreachableZoneUI:CurAlpha",self.CurRemainTime,self.RemainTime,CurPercent)
    if CurPercent <= 0.5 then self.GUIProgressBar_Area:SetFillColorandOpacity(UE.FLinearColor(1, 0, 0, 1)) end
    self.GUIProgressBar_Area:SetPercent(CurPercent)
    --更改遮罩亮度
    local CurAlpha = self.MinAlpha + (self.MaxAlpha - self.MinAlpha) * (1 - CurPercent)
    self.CurLinearColor = UE.FLinearColor(0, 0, 0, CurAlpha)
    self.CurSlateColor.SpecifiedColor = self.CurLinearColor
    self.GUIImageMask:SetBrushTintColor(self.CurSlateColor)
    --红色遮罩
    self.MaskLinearColor = UE.FLinearColor(1, 1, 1, CurAlpha)
    self.MaskSlateColor.SpecifiedColor = self.MaskLinearColor
    self.T_Mask_Red:SetBrushTintColor(self.MaskSlateColor)
    self.T_Mask_Red:SetRenderOpacity(CurAlpha)
    --最后倒计时动效
    if self.CurRemainTime <= 5 and self.FinalCountDownTime > 0 then
        --最后5秒只播放一次背景loop动效
        if not self.bStartFinalCountDown and self.vx_signawarning_countdown_fontbg_in then 
            self:VXE_HUD_SignaWarning_Countdown_FontBg_in() 
            self.bStartFinalCountDown = true
        end
        --最后5秒每秒播放一次
        if self.FinalCountDownTime == math.floor(self.FinalCountDownTime) and self.vx_signawarning_countdown_font_in then 
            self:VXE_HUD_SignaWarning_Countdown_Font_in() 
        end
        self.FinalCountDownTime = self.FinalCountDownTime - FormatDeltaTime
    end
    if self.CurRemainTime > 0  and self.CurRemainTime < 1 then
        UE.UGTSoundStatics.PostAkEvent_Asset(self, self.AkEvent_Alarm)
        self:SetTextVisibility(false)
    end
end

function UnreachableZoneUI:SetTextVisibility(IsVisible)
    if IsVisible then
        if self.vx_signawarning_in then 
            self:VXE_HUD_SignaWarning_In()
            if self.WBP_UnreachableArrow then self.WBP_UnreachableArrow:VXE_HUD_Arrow_In() end
        else
            self.GUIProgressBar_Area:SetVisibility(UE.ESlateVisibility.Visible)
            self.GUIText_Time:SetVisibility(UE.ESlateVisibility.Visible)
            self.GUIImage_Red:SetVisibility(UE.ESlateVisibility.Visible)
            self.GUIImage_Point:SetVisibility(UE.ESlateVisibility.Visible)
        end
    else
        if self.vx_signawarning_out then 
            self:VXE_HUD_SignaWarning_Out()
            if self.WBP_UnreachableArrow then self.WBP_UnreachableArrow:VXE_HUD_Arrow_Out() end
        else
            self.GUIProgressBar_Area:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.GUIText_Time:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.GUIImage_Red:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.GUIImage_Point:SetVisibility(UE.ESlateVisibility.Collapsed)  
        end
    end
end

function UnreachableZoneUI:UpdateData(Owner,NewCountDownTime,TipGenricBlackboard)
    self.UIManager = UE.UGUIManager.GetUIManager(self)
    assert(self.UIManager, ">> S1BRPlayerController, UIManager is nil!!!")
    self.UIManager:TryCloseDynamicWidgetByLayoutConfig(self.GUILayoutTagsConfig)
end


function UnreachableZoneUI:OnClose()
    UE.UGTSoundStatics.PostAkEvent_Asset(self, self.AkEvent_Countdown_Stop)
end

return UnreachableZoneUI
