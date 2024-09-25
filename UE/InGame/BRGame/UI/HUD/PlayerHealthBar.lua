local PlayerHealthBar = Class("Common.Framework.UserWidget")

--血条动效材质参数
--ProgressValue状态：0：白色、0.5：色散、1：红色
local VXHealthBarParam  = 
{
    MainColor = "MainColor",
    TransColor = "TransColor",
    ProgressValue = "ProgressValue",
    HealthbarHurtValue = "healthbarHurtValue",
    HealthbarAfterValue = "healthbarAfterValue",
    HealFastProgress = "HealFastProgress",
    HealFastOpacity = "HealFastOpacity",
    BackProgress = "BackProgress",
    Healback = "HealbackOpacity",
}

function PlayerHealthBar:OnInit()
    self:InitData()
    UserWidget.OnInit(self)
end

function PlayerHealthBar:OnDestroy()
    self:UnBindPlayerVMData()
    UserWidget.OnDestroy(self)
end

function PlayerHealthBar:InitData()
    self.RefPS = nil
    self.IsDead = false
    self.bIsDying = false
    self.IsRescueMe = false
    
    --扣血动效预览值
    self.VXPreviewPercent = 0
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.ProgressValue, 0)
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealthbarHurtValue, 0)
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealthbarAfterValue, 0)
    local NewColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", "White")
    print("PlayerHealthBar:InitData:NewColor:", NewColor)
    self.VX_BarHealth:GetDynamicMaterial():SetVectorParameterValue(VXHealthBarParam.MainColor, NewColor)
end

function PlayerHealthBar:InitRefPS(InRefPS)
    if not InRefPS then return end
    self.RefPS = InRefPS
    self:UnBindPlayerVMData()
    self.UIManager = UE.UGUIManager.GetUIManager(self)
    local VMGameplayTag = UE.FGameplayTag()
    VMGameplayTag.TagName = "MVVM.PlayerInfo"
    self.VMData = self.UIManager:GetDynamicViewModel(VMGameplayTag, self.RefPS)

    if self.VMData then 
        self.VMData.OnHealthValueChangedHandle:Add(self, self.SetHealthInfo) 
        self.VMData:K2_AddFieldValueChangedDelegateSimple("PreviewHealth", {self, self.SetPreviewHealth}) 
        self.VMData:K2_AddFieldValueChangedDelegateSimple("SlowlyRecoveryHealth", {self, self.SetSlowlyRecoveryHealth})
        self:SetHealthInfo(self.VMData.HealthInfo, self.VMData.HealthInfo)
    end

    local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(InRefPS)
    if HudDataCenter then self.IsDead = HudDataCenter.DeadInfo.bIsDead end

    MsgHelper:UnregisterList(self, self.MsgList_PS or {})
    self.MsgList_PS = 
    {
        { MsgName = GameDefine.MsgCpp.UISync_UpdateOnBeginDying, Func = self.UpdateDyingInfo, bCppMsg = true, WatchedObject = self.RefPS },
        { MsgName = GameDefine.MsgCpp.UISync_UpdateOnRescueMe,   Func = self.UpdateRescueMeInfo, bCppMsg = true, WatchedObject = self.RefPS },
        { MsgName = GameDefine.MsgCpp.UISync_UpdateOnDead,       Func = self.UpdateDeadInfo,     bCppMsg = true, WatchedObject = self.RefPS },
    }
    MsgHelper:RegisterList(self, self.MsgList_PS)
end

function PlayerHealthBar:UnBindPlayerVMData()
    if self.VMData then 
        self.VMData.OnHealthValueChangedHandle:Remove(self, self.SetHealthInfo)
        self.VMData:K2_RemoveFieldValueChangedDelegateSimple("PreviewHealth", {self, self.SetPreviewHealth}) 
        self.VMData:K2_RemoveFieldValueChangedDelegateSimple("SlowlyRecoveryHealth", {self, self.SetSlowlyRecoveryHealth})
        self.VMData = nil
    end
end

function PlayerHealthBar:SetHealthInfo(NewHealthInfo, OldHealthInfo)
    print("PlayerHealthBar>>SetHealthInfo>>Old:CurrentHealth:", OldHealthInfo.CurrentHealth, "MaxHealth:", OldHealthInfo.MaxHealth, "New CurrentHealth:", NewHealthInfo.CurrentHealth, "MaxHealth:", NewHealthInfo.MaxHealth,
    " bIsDying: ", self.bIsDying, " bIsDead: ", self.IsDead)
    -- 低血量动效
    if NewHealthInfo.CurrentHealth < 25 and not self.bIsDying then
        self:VXE_HUD_PlayerInfo_Blood_LowBlood()
    else
        self:VXE_HUD_PlayerInfo_Blood_LowBlood_Stop()
    end

    local OldPercent = (OldHealthInfo.MaxHealth > 0) and (OldHealthInfo.CurrentHealth / OldHealthInfo.MaxHealth) or 0
    local NewPercent = (NewHealthInfo.MaxHealth > 0) and (NewHealthInfo.CurrentHealth / NewHealthInfo.MaxHealth) or 0
    self.VXHealBeforePercent = OldPercent
    self.VXHealAfterPercent = NewPercent

    --设置扣血后的值，以及扣血预览动效值
    if self.VXPreviewPercent <= 0 and not self.bIsDying and not self.IsDead then
        local DamagePercent = (OldHealthInfo.CurrentHealth > 0) and ((OldHealthInfo.CurrentHealth - NewHealthInfo.CurrentHealth) / NewHealthInfo.MaxHealth) or 0
        --如果连续扣血则叠加预览值
        self.VXPreviewPercent = self.VXPreviewPercent + DamagePercent > 0 and DamagePercent or 0
        if self.VXPreviewPercent == 0 then self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.ProgressValue, 1) end
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealthbarAfterValue, NewPercent)
        --倒地后扣血不播放扣血色散动效
        if self.VXPreviewPercent > 0 and self:IsVisible() then
            print("PlayerHealthBar>>SetHealthInfo>>Play Blood Hurt")
            self:VXE_HUD_PlayerInfo_Blood_Hurt()
            self:VXE_HUD_Hurt_Anim()
        end
    end

    -- 设置当前生命，缓慢恢复不播放立即回复动效
    local bPlayHealAnimation = NewHealthInfo.CurrentHealth - OldHealthInfo.CurrentHealth > 1
    if not self.bIsDying and bPlayHealAnimation then
        self:VXE_HUD_Heal_Anim()
    else
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealthbarAfterValue, NewPercent)
    end
end

function PlayerHealthBar:SetPreviewHealth(vm, fieldID)
    print("PlayerHealthBar>>SetPreviewHealth:", vm.PreviewHealth)
    if vm.PreviewHealth > 0 then
        local RecoveryPercent = (vm.HealthInfo.MaxHealth > 0) and vm.PreviewHealth / vm.HealthInfo.MaxHealth or 0
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastOpacity, 1)
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastProgress, RecoveryPercent)
        self:VXE_HUD_PlayerInfo_Heal_FastIn()
    else
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastOpacity, 0)
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastProgress, 0)
        self:VXE_HUD_PlayerInfo_Heal_FastOut()
    end
end

function PlayerHealthBar:SetSlowlyRecoveryHealth(vm, fieldID)
    print("PlayerHealthBar>>SetSlowlyRecoveryHealth:", vm.SlowlyRecoveryHealth)
    if vm.SlowlyRecoveryHealth > 0 then
        local RecoveryPercent = (vm.HealthInfo.MaxHealth > 0) and vm.SlowlyRecoveryHealth / vm.HealthInfo.MaxHealth or 0
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.Healback, 1)
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.BackProgress, RecoveryPercent)
        self:VXE_HUD_PlayerInfo_Heal_SlowIn()
    else
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.Healback, 0)
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.BackProgress, 0)
        self:VXE_HUD_PlayerInfo_Heal_SlowOut()
    end
end

function PlayerHealthBar:ResetPreviewValue()
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastOpacity, 0)
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastProgress, 0)
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.Healback, 0)
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.BackProgress, 0)
end

function PlayerHealthBar:UpdateDyingInfo(InDyingInfo)
    if self.bIsDying ~= InDyingInfo.bIsDying  then
        if InDyingInfo.bIsDying == true then
            self:ResetPreviewValue()
            self:VXE_HUD_Playinfo_Me_Die()
        else
           -- self:VXE_HUD_Playinfo_Me_Die_Stop()
        end
    end

    self.bIsDying = InDyingInfo.bIsDying
    local NewColorKey = self.bIsDying and "Red" or "White"
    local NewColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", NewColorKey)
    self.VX_BarHealth:GetDynamicMaterial():SetVectorParameterValue(VXHealthBarParam.MainColor, NewColor)
end

function PlayerHealthBar:UpdateRescueMeInfo(InRescueMeInfo)
    if InRescueMeInfo.EndReason == UE.ES1RescueEndReason.RescueBreakOff or InRescueMeInfo.EndReason == UE.ES1RescueEndReason.Cancelled  then
        self.IsRescueMe = false
    end

    if self.IsRescueMe == true and self.IsRescueMe ~= InRescueMeInfo.bIsBeRescued then
        --self.bIsRescueMeCompleted = true
        --self:VXE_HUD_Playinfo_Me_Die_Stop()
    end
    
    self.IsRescueMe = InRescueMeInfo.bIsBeRescued
end

function PlayerHealthBar:UpdateDeadInfo(InDeadInfo)
    self.IsDead = InDeadInfo.bIsDead
    if self.IsDead == true then 
        self:ResetPreviewValue()
        --self:VXE_HUD_Playinfo_Me_Die_Stop() 
        --self:VXE_HUD_PlayerInfo_Blood_LowBlood_Stop()
    end
end

return PlayerHealthBar