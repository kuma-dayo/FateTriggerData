local PlayerArmorBar = Class("Common.Framework.UserWidget")

--护甲条对应阈值的显示
local LimitedArmorNum = 
{
    [1]=25,
    [2]=50,
    [3]=75,
    [4]=100,
}

local ArmorMaterialProperty = 
{
    Value = "Value",
    ExpValue = "ExpValue",
    SlowProgress = "SlowProgress",
    LineOpacity = "Line-Opacity",
}

local bTeamPlayerArmorBar = false

function PlayerArmorBar:OnInit()
    self:InitData()
    UserWidget.OnInit(self)
end

function PlayerArmorBar:OnDestroy()
    if self.VMData then 
        self.VMData:K2_RemoveFieldValueChangedDelegateSimple("ArmorInfo", {self, self.SetArmorData}) 
        self.VMData:K2_RemoveFieldValueChangedDelegateSimple("PreviewArmorValue", {self, self.SetPreviewArmorValue}) 
        self.VMData:K2_RemoveFieldValueChangedDelegateSimple("SlowlyRecoveryMaxArmor", {self, self.SetSlowlyRecoveryMaxArmor})
        self.VMData = nil
    end
    self:ResetData()
    UserWidget.OnDestroy(self)
end

function PlayerArmorBar:InitData()
    --动效图片
    self.VXAttackLight = 
    {
        self.VX_AttackLight_01, 
        self.VX_AttackLight_02, 
        self.VX_AttackLight_03, 
        self.VX_AttackLight_04, 
    }

    --当前物品提供的最大护甲值
    self.LimitedArmor = 0
    --当前提供护甲的物品ID
    self.CurArmorItemId = 0
    --最后一次记录的护甲值
    self.LastArmorPercent = 0
    self.RefPS = nil

    self.ArmorValue = self.SizeBox_BarArmor.WidthOverride
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.Value, 0)
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.ExpValue, 0)
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.SlowProgress, 0)
end

function PlayerArmorBar:InitRefPS(InRefPS)    
    if not InRefPS then return end
    self.RefPS = InRefPS

    self.UIManager = UE.UGUIManager.GetUIManager(self)
    local VMGameplayTag = UE.FGameplayTag()
    VMGameplayTag.TagName = "MVVM.PlayerInfo"
    self.VMData = self.UIManager:GetDynamicViewModel(VMGameplayTag, self.RefPS)

    if self.VMData then 
        self.VMData:K2_AddFieldValueChangedDelegateSimple("ArmorInfo", {self, self.SetArmorData}) 
        self.VMData:K2_AddFieldValueChangedDelegateSimple("PreviewArmorValue", {self, self.SetPreviewArmorValue}) 
        self.VMData:K2_AddFieldValueChangedDelegateSimple("SlowlyRecoveryMaxArmor", {self, self.SetSlowlyRecoveryMaxArmor})
        self:SetArmorData(self.VMData, nil) 
    end
end

function PlayerArmorBar:SetArmorData(vm, fieldID)
    if vm.ArmorInfo.IsShowArmor then
        self.SizeBox_BarArmor:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self:SetArmorProcessBarInfo(vm.ArmorInfo.CurrentArmorValue, vm.ArmorInfo.MaxArmorValue, vm.ArmorInfo.ArmorId)
    else
        self.SizeBox_BarArmor:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.ExpValue, 0)
    end
end

function PlayerArmorBar:SetPreviewArmorValue(vm, fieldID)
    print("PlayerArmorBar>>SetPreviewArmorValue:", vm.PreviewArmorValue)
    if vm.PreviewArmorValue > 0 then
        local Percent = (vm.ArmorInfo.MaxArmorValue > 0) and vm.PreviewArmorValue / vm.ArmorInfo.MaxArmorValue or 0
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.ExpValue, Percent)
    else
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.ExpValue, 0)
    end
end

function PlayerArmorBar:SetSlowlyRecoveryMaxArmor(vm, fieldID)
    print("PlayerArmorBar>>SetSlowlyRecoveryMaxArmor:", vm.SlowlyRecoveryMaxArmor)
    if vm.SlowlyRecoveryMaxArmor > 0 then
        local Percent = (vm.ArmorInfo.MaxArmorValue > 0) and vm.SlowlyRecoveryMaxArmor / vm.ArmorInfo.MaxArmorValue or 0
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.SlowProgress, Percent)
    else
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.SlowProgress, 0)
    end
end

function PlayerArmorBar:ResetData()
    self.SizeBox_BarArmor.WidthOverride = self.ArmorValue
end

function PlayerArmorBar:SetArmorProcessBarInfo(InCurArmor, InMaxArmor, InArmorItemId)
    --print("PlayerArmorBar:SetArmorProcessBarInfo: ", InCurArmor, InMaxArmor, InArmorItemId)
    InCurArmor = InCurArmor or 0
    InMaxArmor = InMaxArmor or 0
    local NewPercent = (InCurArmor > 0) and (InCurArmor / InMaxArmor) or 0

    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.Value, NewPercent)
    local NewTxt = math.floor(InCurArmor) .. "/" .. math.floor(InMaxArmor)
    self.BarArmor:SetToolTipText(NewTxt)

    --这里开始使用MiscSystem的颜色
    local MiscSystem = UE.UMiscSystem.GetMiscSystem(self)
    local ArmorLvAttributes = MiscSystem.BarArmorAttributes
    self.SizeBox_BarArmor.WidthOverride = self.ArmorValue
  
    local ItemLevel = BattleUIHelper.SetArmorShieldLvInfo(InArmorItemId, self.BarArmor, ArmorLvAttributes, self.SizeBox_BarArmor)
    self.LimitedArmor = ArmorLvAttributes:FindRef(ItemLevel).LimitedArmor
    if not bTeamPlayerArmorBar then self:PlayArmorAttactedEffect(InArmorItemId, InCurArmor, NewPercent) end
    self.LastArmorPercent = NewPercent
    self.CurArmorItemId = InArmorItemId
end

--护甲受击/破甲动效
function PlayerArmorBar:PlayArmorAttactedEffect(InArmorItemId, InCurArmor, InNewPercent)
    print("PlayerArmorBar:PlayArmorAttactedEffect")
    --破甲动效
    if InCurArmor == 0 then self:VXE_HUD_PlayerInfo_Armor_Crack() end
    -- 根据护甲值最大值设置受击动效格子：25/50/75/100
    local IterateTimes = 0
    local Times = 0
    for key, value in pairs(LimitedArmorNum) do
        if value == self.LimitedArmor then
            IterateTimes = key
            break
        end
    end
    if IterateTimes ~= 0 then
        for _, value in pairs(self.VXAttackLight) do
            Times = Times + 1
            if Times <= IterateTimes then
                value:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
            else
                value:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        end
        --切换不同护甲时，最后护甲值比当前值高时不播放受击动效
        if self.LastArmorPercent > InNewPercent and self.CurArmorItemId == InArmorItemId then
            self:VXE_HUD_Playerinfo_Armor_Attacted()
        end
    end
end


return PlayerArmorBar