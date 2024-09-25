require "UnLua"

local ChooseHero_Layer = Class("Common.Framework.UserWidget")


function ChooseHero_Layer:OnInit()
    self.GameState = UE.UGameplayStatics.GetGameState(self)
end

function ChooseHero_Layer:Tick(MyGeometry, InDeltaTime)
    if self.GameState == nil then
        return
    end

    if self.NeedTick then
        self.RemainTime = self.AllStateTime - self.GameState:GetReplicatedWorldTimeSeconds()
        self.RemainTimeInt = UE.UKismetMathLibrary.FCeil(self.RemainTime)
        if self.RemainTimeInt >= 0 then
            --增加分秒的显示
            if self.RemainTimeInt >= 60 then
                self.TimeTxt_M_Value:SetVisibility(UE.ESlateVisibility.Visible)
                self.TimeTxt_M:SetVisibility(UE.ESlateVisibility.Visible)
                self.RemainTimeInt_M =math.floor(self.RemainTimeInt / 60)
                self.RemainTimeInt_S = self.RemainTimeInt % 60
                local RemainTimeText_M = UE.UKismetTextLibrary.Conv_IntToText(self.RemainTimeInt_M)
                local RemainTimeText_S = UE.UKismetTextLibrary.Conv_IntToText(self.RemainTimeInt_S)
                self.TimeTxt_M_Value:SetText(RemainTimeText_M)
                self.TimeTxt_S_Value:SetText(RemainTimeText_S)
            else
                self.TimeTxt_M_Value:SetVisibility(UE.ESlateVisibility.Collapsed)
                self.TimeTxt_M:SetVisibility(UE.ESlateVisibility.Collapsed)
                local RemainTimeText_S = UE.UKismetTextLibrary.Conv_IntToText(self.RemainTimeInt)
                self.TimeTxt_S_Value:SetText(RemainTimeText_S)
            end

            local Percent = self.RemainTime / self.WarmStateTime
            local RealPercent =  UE.UKismetMathLibrary.FClamp(Percent, 0.0, 1.0)
            --print("dyptest",self.RemainTime, self.WarmStateTime, Percent,RealPercent)
            self.TimeBar:SetPercent(RealPercent)
            if self.RemainTimeInt <= 5 then
                self.TimeTxt_M_Value:SetColorAndOpacity(self.RedColor_Slate)
                self.TimeTxt_M:SetColorAndOpacity(self.RedColor_Slate)
                self.TimeTxt_S_Value:SetColorAndOpacity(self.RedColor_Slate)
                self.TimeTxt_S:SetColorAndOpacity(self.RedColor_Slate)
                self.TimeBar:SetFillColorAndOpacity(self.RedColor)
            end
        
        else
            self.NeedTick = false
        end
    else
        return
    end
end


function ChooseHero_Layer:GetRealName(InName)
    return StringUtil.Format(InName)
end

function ChooseHero_Layer:Checkinitcompleted()
    local IsHeroItemInit = self.HeroItemInitCurNums >= self.HeroItemInitNeedNums
    local IsPreChooseheroInit = self.PreChooseHeroInit
    print("[WBP]Choosehero_StopLoading check", IsHeroItemInit, IsPreChooseheroInit, self.HeroItemInitCurNums,
    self.HeroItemInitNeedNums)

    print("[KeyStep-->Client][12] Check Asset Load Completed", IsHeroItemInit, IsPreChooseheroInit,
    self.HeroItemInitCurNums, self.HeroItemInitNeedNums)
    UE.UGFUnluaHelper.OnClientHitKeyStep("12")
    return IsHeroItemInit and IsPreChooseheroInit
end

return ChooseHero_Layer
