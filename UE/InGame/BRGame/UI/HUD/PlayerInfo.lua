--
-- 战斗界面 - 角色信息
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.28
--
require ("InGame.BRGame.ItemSystem.RespawnSystemHelper")
local testProfile = require("Common.Utils.InsightProfile")
local PlayerInfo = Class("Common.Framework.UserWidget")

local DefaultSlotId = 1

local HealthBarType =
{
    Default =
    {
        Color       =   "FillColor",
        Progress    =   "Progress",
    },
    Damage =
    {
        Color       =   "FillColor2",
        Progress    =   "Progress2",
    },
    Recovery =
    {
        Color       =   "FillColor3",
        Progress    =   "Progress3",
    },
}

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

local ArmorMaterialProperty = 
{
    Value = "Value",
    ExpValue = "ExpValue",
    SlowProgress = "SlowProgress",
    LineOpacity = "Line-Opacity",
}

local LimitedArmorNum = 
{
    [1]=25,
    [2]=50,
    [3]=75,
    [4]=100,
}

local DamageRecoveryTag = UE.FGameplayTag()
DamageRecoveryTag.TagName = "Damage.Recovery"
local CharacterRescueTag = UE.FGameplayTag()
CharacterRescueTag.TagName = "Character.BRState.Rescue"

local GDSHealthTag = UE.FGameplayTag()
GDSHealthTag.TagName = "GDS.Health"
-- local GDSArmorBodySheildTag = UE.FGameplayTag()
-- GDSArmorBodySheildTag.TagName = "GDS.Armor.Body.Sheild"

-- 对应表DT_IngameEnhanceAttribute
local EnhanceAttribure =
{
    NoWarAutoRecovery =
    {
        EnhanceID = 1009,
    },
    NoWarAutoRecoveryArmor =
    {
        EnhanceID = 1004,
    }
}

-------------------------------------------- Init/Destroy ------------------------------------

function PlayerInfo:OnInit()
    print("PlayerInfo:OnInit")
    print("PlayerInfo >> PlayerInfo self:", GetObjectName(self))
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    print("PlayerInfo", ">> OnInit, ", GetObjectName(self), GetObjectName(self.LocalPC), self.LocalPC)

    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerPawn,  Func = self.OnLocalPCUpdatePawn,    bCppMsg = true, WatchedObject = self.LocalPC },
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState, Func = self.OnUpdateLocalPCPS,      bCppMsg = true, WatchedObject = self.LocalPC },
        --{ MsgName = GameDefine.Msg.PLAYER_InPoisonCircle,   Func = self.OnChanged_InPoisonCircle,   bCppMsg = false, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.UISync_UpdateMarkData,    Func = self.OnUpdateMarkData,   bCppMsg = true, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.PLAYER_HealthShowPreview, Func = self.PreviewTreat,       bCppMsg = true, WatchedObject = nil },
        --{ MsgName = GameDefine.MsgCpp.BAG_FeatureSetUpdate,     Func = self.OnUpdateItemFeatureSet, bCppMsg = true, WatchedObject = nil },
        -- { MsgName = UE.USDKTags.Get().RTCSDKOnRemoteAudioPropertiesReport,            Func = self.OnRemoteAudioPropertiesReport,      bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.GDS_OnAnyAttrubuteChange, Func = self.OnAnyAttrubuteChange, bCppMsg = true, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.UIEvent_Update_ReConnect,          Func = self.OnUpdataReConnect, bCppMsg = true, WatchedObject =nil },
    }

    self.ArmorValue = self.SizeBox_BarArmor.WidthOverride
    UserWidget.OnInit(self)
    
    self:InitBaseData()
    print("PlayerInfo >> PlayerInfo self:", GetObjectName(self))
end

function PlayerInfo:OnDestroy()
    print("PlayerInfo", ">> OnDestroy, ", GetObjectName(self), GetObjectName(self.LocalPC), self.LocalPC)
    self:ResetData()
    self:UnBindPlayerVMData()
    UserWidget.OnDestroy(self)
end

function PlayerInfo:UnBindPlayerVMData()
    if self.MyDataVM then
        self.MyDataVM.OnHealthValueChangedHandle:Remove(self, self.SetHealthInfo)
        self.MyDataVM:K2_RemoveFieldValueChangedDelegateSimple("ArmorInfo", {self, self.SetArmorData}) 
        self.MyDataVM:K2_RemoveFieldValueChangedDelegateSimple("PreviewHealth", {self, self.SetPreviewHealth}) 
        self.MyDataVM:K2_RemoveFieldValueChangedDelegateSimple("SlowlyRecoveryHealth", {self, self.SetSlowlyRecoveryHealth})
        self.MyDataVM:K2_RemoveFieldValueChangedDelegateSimple("PreviewArmorValue", {self, self.SetPreviewArmorValue}) 
        self.MyDataVM:K2_RemoveFieldValueChangedDelegateSimple("SlowlyRecoveryMaxArmor", {self, self.SetSlowlyRecoveryMaxArmor})
        self.MyDataVM = nil
    end
end


function PlayerInfo:ResetData()
    MsgHelper:UnregisterList(self, self.MsgList_PS or {})
    MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})
    self.SizeBox_BarArmor.WidthOverride = self.ArmorValue
end

function PlayerInfo:OnClose()
    print("PlayerInfo >> OnClose")
    self:VXE_HUD_PlayerInfo_Die_Out()
end
-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function PlayerInfo:InitBaseData()
    print("PlayerInfo >> InitBaseData")
    -- 初始化濒死颜色
    self.DyingColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", "Red")
    --self.RespawnColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", "Red")

    -- 健康值
    self.CurHealth = 0
    self.MaxHealth = 0
    self.CurHealthPercent = 0
    self.PreviewRate = self.PreviewRate or 0.25
    self.RecoveryRate = self.RecoveryRate or 0.25
    self.bPreviewTreat = false
    print("PlayerInfo >> InitBaseData > self.bPreviewTreat:", self.bPreviewTreat)
    self.PreviewPercent = 0
    self.PreviewTreatValue = 0
    self.RecoveryPercent = 0
    self.ImgTalking:SetRenderOpacity(0.5)
    -- 背包负重警告
    self.WeightPercentWarnValue = 90

    self.bIsDying = false
    self.IsDead = false
    self.IsRescueMe = false
    self.LimitedArmor= 0
    self.CurArmorItemId = 0
    --最后一次记录的护甲值
    self.LastArmorPercent = 0
    self.TxtName:SetText('')
    --self.TxtHelmetsLv:SetText('')

    --血条动效
    self.VXPreviewPercent = 0
    --判断完成救援状态
    self.bIsRescueMeCompleted = false
    self.VXAttackLight = 
    {
        self.VX_AttackLight_01, 
        self.VX_AttackLight_02, 
        self.VX_AttackLight_03, 
        self.VX_AttackLight_04, 
    }

    if BridgeHelper.IsPCPlatform() then
        self.BarHealth:GetDynamicMaterial():SetScalarParameterValue("Progress", 0)
        self.BarHealth:GetDynamicMaterial():SetScalarParameterValue("Progress2", 0)
        self.BarHealth:GetDynamicMaterial():SetScalarParameterValue("Progress3", 0)
        self.BarHealth:GetDynamicMaterial():SetScalarParameterValue("Progress4", 0)

        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.ProgressValue, 0)
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealthbarHurtValue, 0)
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealthbarAfterValue, 0)
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.SlowProgress, 0)
    end
    self.HealthAutoRecoveryBG:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.ArmorAutoRecoveryBG:SetVisibility(UE.ESlateVisibility.Collapsed)

    --self.DefaultTextureNone = self.ImgArmorIcon.Brush.ResourceObject

    self:InitPlayerStateInfo()
    self:InitPlayerPawnInfo()
    --self:UpdateArmorInfo()
end

function PlayerInfo:InitPlayerStateInfo()
    local LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
    --local LocalPS = self.LocalPC.PlayerState
    --self.LocalPC and self.LocalPC.PlayerState or nil
    print("PlayerInfo", ">> InitPlayerStateInfo[0], ", GetObjectName(LocalPS), GetObjectName(self.LocalPC), self.LocalPC)
    if LocalPS then
        local PlayerName = LocalPS:GetPlayerName()
        print("PlayerInfo", ">> InitPlayerStateInfo[5], ", GetObjectName(LocalPS), GetObjectName(self.LocalPC),
        self.LocalPC, PlayerName, LocalPS:GetPlayerId())
        
        self.TxtName:SetText(PlayerName)
        --新增玩家编号功能
        print("PlayerInfo", ">> InitPlayerStateInfo[1], ", PlayerName, CurHealth, MaxHealth)
        self:OnChange_PSTeamPos(LocalPS, nil)
        --强制初始化个人的血条颜色
        local NewColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", "White")
        if BridgeHelper.IsPCPlatform() then
            self.BarHealth:GetDynamicMaterial():SetVectorParameterValue(HealthBarType.Default.Color, NewColor)
            self.VX_BarHealth:GetDynamicMaterial():SetVectorParameterValue(VXHealthBarParam.MainColor, NewColor)
        end
        self:UpdateTeamMarkItem(LocalPS)
        -- 护甲信息
        --self:UpdateArmorInfo()
        --self.TrsArmorValue:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        -- 监听对象消息

        self.UIManager = UE.UGUIManager.GetUIManager(self)
        local VMGameplayTag = UE.FGameplayTag()
        VMGameplayTag.TagName = "MVVM.PlayerInfo"
        self:UnBindPlayerVMData()
        self.MyDataVM = self.UIManager:GetDynamicViewModel(VMGameplayTag, LocalPS)
        if not self.MyDataVM then print("PlayerInfo>>Not found ViewModel") end
        if self.MyDataVM then
            self.MyDataVM.OnHealthValueChangedHandle:Add(self, self.SetHealthInfo) 
            self.MyDataVM:K2_AddFieldValueChangedDelegateSimple("ArmorInfo", {self, self.SetArmorData}) 
            self.MyDataVM:K2_AddFieldValueChangedDelegateSimple("PreviewHealth", {self, self.SetPreviewHealth}) 
            self.MyDataVM:K2_AddFieldValueChangedDelegateSimple("SlowlyRecoveryHealth", {self, self.SetSlowlyRecoveryHealth})
            self.MyDataVM:K2_AddFieldValueChangedDelegateSimple("PreviewArmorValue", {self, self.SetPreviewArmorValue}) 
            self.MyDataVM:K2_AddFieldValueChangedDelegateSimple("SlowlyRecoveryMaxArmor", {self, self.SetSlowlyRecoveryMaxArmor}) 
            self:SetArmorData(self.MyDataVM, nil)
            self:SetHealthInfo(self.MyDataVM.HealthInfo, self.MyDataVM.HealthInfo)
        end

        self:ResetRecoveryValue()
        
        MsgHelper:UnregisterList(self, self.MsgList_PS or {})
        self.MsgList_PS = {
            --{ MsgName = GameDefine.MsgCpp.PLAYER_PSHealth,           Func = self.SetSignalValue,      bCppMsg = true, WatchedObject =LocalPS },信号值
            --{ MsgName = GameDefine.MsgCpp.PLAYER_PSHealth,           Func = self.SetHealthInfo,      bCppMsg = true, WatchedObject =LocalPS },
            { MsgName = GameDefine.MsgCpp.PLAYER_PSAlive,            Func = self.OnChangePSAlive,    bCppMsg = true,  WatchedObject =LocalPS },
            { MsgName = GameDefine.MsgCpp.PLAYER_OnBeginRespawn,     Func = self.OnBeginRespawn,     bCppMsg = true, WatchedObject =LocalPS },
            { MsgName = GameDefine.MsgCpp.PLAYER_OnEndRespawn,       Func = self.OnEndRespawn,       bCppMsg = true, WatchedObject =LocalPS },
            { MsgName = GameDefine.MsgCpp.UISync_UpdateOnBeginDying, Func = self.UpdateDyingInfo,    bCppMsg = true, WatchedObject = LocalPS },
            { MsgName = GameDefine.MsgCpp.UISync_UpdateOnDead,       Func = self.UpdateDeadInfo,     bCppMsg = true, WatchedObject =LocalPS },
            { MsgName = GameDefine.MsgCpp.UISync_UpdateOnRescueMe,   Func = self.UpdateRescueMeInfo, bCppMsg = true, WatchedObject =LocalPS },
            { MsgName = GameDefine.MsgCpp.PLAYER_PSTeamPos,          Func = self.OnChange_PSTeamPos, bCppMsg = true, WatchedObject =nil },
            { MsgName = GameDefine.MsgCpp.UISync_UpdateRecoveryMaxArmor, Func = self.UpdateRecoveryMaxArmor, bCppMsg = true,  WatchedObject = LocalPS },
            {MsgName = GameDefine.MsgCpp.PLAYER_PSPawn,     Func = self.OnUpdatePSPawn,  bCppMsg = true,  WatchedObject = LocalPS},
            --{MsgName = GameDefine.MsgCpp.UISync_Update_RuntimeHeroId,     Func = self.OnUpdateAvatar,  bCppMsg = true,  WatchedObject = LocalPS}, 
            -- { MsgName = UE.USDKTags.Get().RTCSDKOnLocalAudioPropertiesReport,            Func = self.OnLocalAudioPropertiesReport,      bCppMsg = true },
            { MsgName = GameDefine.MsgCpp.UISync_Update_FreshEnhanceId, Func = self.OnFreshEnhanceId,  bCppMsg = true,  WatchedObject = LocalPS}, 
            {MsgName = GameDefine.MsgCpp.UISync_Update_ParachuteRespawnStart,     Func = self.OnParachuteRespawnStart,  bCppMsg = true,  WatchedObject = LocalPS}, 
            {MsgName = GameDefine.MsgCpp.UISync_Update_ParachuteRespawnFinished,     Func = self.OnParachuteRespawnFinished,  bCppMsg = true,  WatchedObject = LocalPS}, 
        }



        MsgHelper:RegisterList(self, self.MsgList_PS)
        self.PlayerChatComponent = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
        if self.PlayerChatComponent then
            self.PlayerChatComponent.VoiceLocalSpeakNotify:Add(self,self.OnLocalPlayerSpeaking)
        end
    end
    self:CheckRules()
end

function PlayerInfo:OnLocalPlayerSpeaking(bSpeaking)
    print("(Wzp)PlayerInfo:OnLocalPlayerSpeaking  [ObjectName]=",GetObjectName(self),",[bSpeaking]=",bSpeaking)
    if  bSpeaking then
        self.ImgTalking:SetRenderOpacity(1)
        -- print("PlayerInfo >> OnLocalAudioPropertiesReport > self.TimerHandle=",not UE.UKismetSystemLibrary.K2_IsTimerActiveHandle(self, self.TimerHandle))
        -- if not UE.UKismetSystemLibrary.K2_IsTimerActiveHandle(self, self.TimerHandle) then
        --     self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, self.OnChatFinish }, 0.5, false, 0, 0)
        -- end
    else
        self.ImgTalking:SetRenderOpacity(0.5)
    end
end

function PlayerInfo:OnChatFinish()
    self.ImgTalking:SetRenderOpacity(0.5)
    UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
end

function PlayerInfo:InitPlayerPawnInfo()
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
    print("PlayerInfo", ">> InitPlayerPawnInfo, ", GetObjectName(self), GetObjectName(LocalPCPawn))
    self:UpdataAvatar()
    if LocalPCPawn then
        
        -- 重置玩家状态
        self:CheckDying()
        -- 监听对象消息
        MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})
        self.MsgList_Pawn = {
           
            --{ MsgName = GameDefine.NTag.CHARACTER_GunFire,             Func = self.OnGameplayTagEvent_Fire, bCppMsg = true,WatchedObject =LocalPCPawn },

            -- 濒死/救援
            { MsgName = GameDefine.MsgCpp.PLAYER_OnBeginBeingRescue,   Func = self.OnBeginBeingRescue,      bCppMsg = true,
                                                                                                                                WatchedObject =
                LocalPCPawn },
            --{ MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDead,           Func = self.OnBeginDead,            bCppMsg = true, WatchedObject = LocalPCPawn },
            --{ MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDying,          Func = self.OnBeginDying,           bCppMsg = true, WatchedObject = LocalPCPawn },
            { MsgName = GameDefine.MsgCpp.PLAYER_OnEndBeingRescue,     Func = self.OnEndBeingRescue,        bCppMsg = true,
                                                                                                                                WatchedObject =
                LocalPCPawn },
            --{ MsgName = GameDefine.MsgCpp.PLAYER_OnEndDead,             Func = self.OnEndDead,              bCppMsg = true, WatchedObject = LocalPCPawn },
            --{ MsgName = GameDefine.MsgCpp.PLAYER_OnEndDying,            Func = self.OnEndDying,             bCppMsg = true, WatchedObject = LocalPCPawn },
            { MsgName = GameDefine.MsgCpp.PLAYER_OnBeginRescue,        Func = self.OnBeginRescue,           bCppMsg = true,
                                                                                                                                WatchedObject =
                LocalPCPawn },
            { MsgName = GameDefine.MsgCpp.PLAYER_OnEndRescue,          Func = self.OnEndRescue,             bCppMsg = true,
                                                                                                                                WatchedObject =
                LocalPCPawn },
            { MsgName = GameDefine.MsgCpp.PLAYER_OnRescueActorChanged, Func = self.OnRescueActorChanged,    bCppMsg = true,
                                                                                                                                WatchedObject =
                LocalPCPawn },
            { MsgName = GameDefine.MsgCpp.PLAYER_UpdateDeadCountdown,  Func = self.OnUpdateDeadCountdown,   bCppMsg = true,
                                                                                                                                WatchedObject =
                LocalPCPawn },

        }
        MsgHelper:RegisterList(self, self.MsgList_Pawn)
    end
end

function PlayerInfo:SetHealthInfo(NewHealthInfo, OldHealthInfo)
    print("PlayerInfo>>SetHealthInfo>>Old:CurrentHealth:", OldHealthInfo.CurrentHealth, "MaxHealth:", OldHealthInfo.MaxHealth, "New CurrentHealth:", NewHealthInfo.CurrentHealth, "MaxHealth:", NewHealthInfo.MaxHealth,
    " bIsDying: ", self.bIsDying, " bIsDead: ", self.IsDead)

    self.CurHealth = NewHealthInfo.CurrentHealth
    self.MaxHealth = NewHealthInfo.MaxHealth

    -- 低血量动效
    if self.CurHealth <= 25 then
        if self.bIsDying == false or self.bIsRescueMeCompleted == true then
            self:VXE_HUD_PlayerInfo_Blood_LowBlood()
            if self.bIsRescueMeCompleted == true then self.bIsRescueMeCompleted = false end
        end
    else
        self:VXE_HUD_PlayerInfo_Blood_LowBlood_Stop()
    end

    local OldPercent = (OldHealthInfo.MaxHealth > 0) and (OldHealthInfo.CurrentHealth / OldHealthInfo.MaxHealth) or 0
    local NewPercent = (NewHealthInfo.MaxHealth > 0) and (NewHealthInfo.CurrentHealth / NewHealthInfo.MaxHealth) or 0
    self.VXHealBeforePercent = OldPercent
    self.VXHealAfterPercent = NewPercent

    -- 预览伤害(新血条设置)
    if self.VXPreviewPercent <= 0 and not self.bIsDying and not self.IsDead then
        local DamagePercent = (OldHealthInfo.CurrentHealth > 0) and ((OldHealthInfo.CurrentHealth - self.CurHealth) / self.MaxHealth) or 0
        --如果连续扣血则叠加预览值
        self.VXPreviewPercent = self.VXPreviewPercent + DamagePercent > 0 and DamagePercent or 0
        if self.VXPreviewPercent == 0 then self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.ProgressValue, 1) end 
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealthbarAfterValue, NewPercent)
        --倒地后扣血不播放扣血色散动效
        if self.VXPreviewPercent > 0 then 
            print("PlayerInfo>>SetHealthInfo>>Play Blood Hurt")
            self:VXE_HUD_PlayerInfo_Blood_Hurt()
            self:VXE_HUD_Hurt_Anim() 
        end
    end

    -- 设置当前生命，缓慢恢复不播放立即回复动效
    local bPlayHealAnimation = NewHealthInfo.CurrentHealth - OldHealthInfo.CurrentHealth > 1
    if not self.bIsDying and bPlayHealAnimation then
        print("PlayerInfo>>SetHealthInfo>>Play Heal Animation")
        self:VXE_HUD_Heal_Anim()
    else
        if self.VXDyingDownHealth then self.VXDyingDownHealth = NewPercent end
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealthbarAfterValue, NewPercent)
    end

    local NewTxt = math.floor(self.CurHealth) .. "/" .. math.floor(self.MaxHealth)
    self.VX_BarHealth:SetToolTipText(NewTxt)
end

--[[
    预览血量治疗
    bPreviewTreat:  启用或关闭预显示
    InExtraValue:   预览额外值
]]
function PlayerInfo:PreviewTreat(bPreviewTreat, InExtraValue)
    self.bPreviewTreat = bPreviewTreat
    self.PreviewTreatValue = InExtraValue
    if bPreviewTreat then
        local CurPercent = self.BarHealth:GetDynamicMaterial():K2_GetScalarParameterValue(HealthBarType.Default.Progress)
        self.PreviewPercent = CurPercent + (InExtraValue * 0.01)
    else
        self.PreviewPercent = 0
    end
    --local NewColor = bPreviewTreat and UIHelper.LinearColor.Green or UIHelper.LinearColor.Red
    local NewColorKey = bPreviewTreat and "Green" or "Red"
    local NewColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", NewColorKey)
    if BridgeHelper.IsPCPlatform() then
        self.BarHealth:GetDynamicMaterial():SetVectorParameterValue(HealthBarType.Damage.Color, NewColor)
        self.BarHealth:GetDynamicMaterial():SetScalarParameterValue(HealthBarType.Damage.Progress, self.PreviewPercent)
    end
end

-- 护甲数值信息
function PlayerInfo:SetArmorProcessBarInfo(InCurArmor, InMaxArmor, InArmorItemId)
    print("PlayerInfo", ">> SetArmorProcessBarInfo, ", InCurArmor, InMaxArmor)
    InCurArmor = InCurArmor or 0
    InMaxArmor = InMaxArmor or 0
    local NewPercent = (InCurArmor > 0) and (InCurArmor / InMaxArmor) or 0

    --用材质之后修改参数实现
    self.MaxArmor = InMaxArmor
    if InCurArmor == InMaxArmor or InCurArmor == 0 then
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("ExpValue", 0)
    end
    
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("Value", NewPercent)

    --破甲动效
    if InCurArmor == 0 then self:VXE_HUD_PlayerInfo_Armor_Crack() end
   
    local NewTxt = math.floor(InCurArmor) .. "/" .. math.floor(InMaxArmor)
    self.BarArmor:SetToolTipText(NewTxt)

    --这里开始使用MiscSystem的颜色
    local MiscSystem = UE.UMiscSystem.GetMiscSystem(self)
    local ArmorLvAttributes = MiscSystem.BarArmorAttributes
    self.SizeBox_BarArmor.WidthOverride = self.ArmorValue
    
    local ItemLevel = BattleUIHelper.SetArmorShieldLvInfo(InArmorItemId, self.BarArmor, ArmorLvAttributes, self.SizeBox_BarArmor)
    -- 根据护甲值最大值设置动效格子：25/50/75/100
    self.LimitedArmor = ArmorLvAttributes:FindRef(ItemLevel).LimitedArmor
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
        if self.LastArmorPercent > NewPercent and self.CurArmorItemId == InArmorItemId then
            self:VXE_HUD_Playerinfo_Armor_Attacted()
        end
    end
    self.LastArmorPercent = NewPercent
    self.CurArmorItemId = InArmorItemId
end


-- 更新护甲信息
function PlayerInfo:UpdateArmorInfo()
    local IsShowArmor = false

    if not self.LocalPC then
        self.TrsArmorValue:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end

    -- 得到当前护甲的护甲物品Id
    local TempViewPS = self.LocalPC.PlayerState
    local TempArmorItemId, IsExistArmorItemId = UE.UItemStatics.GetArmorBodyArmorShieldItemIdFromPS(TempViewPS)
    local TempArmorShieldValue, IsExistArmorShieldValue = UE.UItemStatics.GetArmorBodyArmorShieldFromPS(TempViewPS)
    local TempArmorShieldMaxValue, IsExistArmorShieldMaxValue = UE.UItemStatics.GetArmorBodyMaxArmorShieldFromPS(TempViewPS)
    
    if IsExistArmorItemId and IsExistArmorShieldValue and IsExistArmorShieldMaxValue then
        IsShowArmor = true
    end

    if IsShowArmor then
        self.TrsArmorValue:SetVisibility(UE.ESlateVisibility.HitTestInvisible)

        -- 设置进度条百分比，颜色
        self:SetArmorProcessBarInfo(TempArmorShieldValue, TempArmorShieldMaxValue, TempArmorItemId)
        --[[
        -- 设置护甲Icon
        local TempItemIconPath, IsExistItemIconPath = UE.UItemSystemManager.GetItemDataFString(self, TempArmorItemId, "ItemIcon", GameDefine.NItemSubTable.Ingame, "PlayerInfo:UpdateArmorInfo")
        if IsExistItemIconPath then
            local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(TempItemIconPath)
			self.ImgArmorIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
        end
        
        -- 根据护甲等级
        local TempItemLevel, IsExistItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, TempArmorItemId, "ItemLevel", GameDefine.NItemSubTable.Ingame, "PlayerInfo:UpdateArmorInfo")
        if IsExistItemLevel then
            -- 设置护甲等级文字
            local TempTxt = BattleUIHelper.GetRomanNumText(TempItemLevel)
            self.TxtArmorLv:SetText(TempTxt)

            -- 设置护甲背景颜色
            local ArmorLvAttributes = BattleUIHelper.GetMiscSystemMap(self, "BarArmorAttributes")
            local LvColor = ArmorLvAttributes:FindRef(tostring(TempItemLevel)).ArmorColor
            self.ImgArmorBg:SetColorAndOpacity(LvColor)
        end]]--
    else
        self.TrsArmorValue:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("ExpValue", 0)
    end
    
end

--[[
    濒死/救援
    InParamters: {
        DyingInfo(FS1LifetimeDyingInfo):  { bIsDying, DyingCounter, DeadCountdownTime }
    }
]]
function PlayerInfo:UpdateDyingState(InParamters)
    --print("PlayerInfo", ">> UpdateDyingState, ", InParamters.DyingInfo.bIsDying,InParamters.DyingInfo.DeadCountdownRemainTime)
    --print("PlayerInfo>>UpdateDyingState>>bIsDying:", InParamters.DyingInfo.bIsDying)
    local NewColorKey = InParamters.DyingInfo.bIsDying and "Red" or "White"
    local NewColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", NewColorKey)
    self.BarHealth:GetDynamicMaterial():SetVectorParameterValue(HealthBarType.Default.Color, NewColor)
    self.VX_BarHealth:GetDynamicMaterial():SetVectorParameterValue(VXHealthBarParam.MainColor, NewColor)
    --self.TxtName:SetColorAndOpacity(UIHelper.ToSlateColor_LC(NewColor))

    --
    local NewVisible0 = InParamters.DyingInfo.bIsDying and
        UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
    self.TrsDying:SetVisibility(NewVisible0)
    self.ImgBgDying:SetVisibility(NewVisible0)

    self.TotalDyingTime = InParamters.DyingInfo.bIsDying and InParamters.DyingInfo.DeadCountdownTime or 0
    self.RemianDyingTime = self.TotalDyingTime
    self.TxtDyingTime:SetText(math.floor(self.TotalDyingTime))
    local NewPercent = (self.TotalDyingTime > 0) and 1 or 0
    if BridgeHelper.IsPCPlatform() then
        self.ImgDyingProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", NewPercent)
        --只改变进度条不改变背景颜色
        self.ImgDyingProgress:GetDynamicMaterial():SetVectorParameterValue("ProgressColor1", self.DyingColor)
    end
    --self.ImgDyingProgress:SetColorAndOpacity(self.DyingColor)

    if InParamters.DyingInfo.bIsDying then
        self:PlayAnimationByName("Anim_Dying", 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
        self.TotalDyingTime = InParamters.DyingInfo.DeadCountdownTime
        self.RemianDyingTime = InParamters.DyingInfo.DeadCountdownRemainTime
        self:UpdateDyingTime(0)
    else
        self:StopAnimationByName("Anim_Dying")
        if self.TrsHealthValue then
            local CanvasSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.TrsHealthValue)
            if CanvasSlot:GetSize().Y > 17 then
                print("PlayerInfo>>UpdateDyingState>>Play Dying Out")
                self:VXE_HUD_PlayerInfo_Die_Out()
            end
        end
        self.ImgAvatar:SetOpacity(1)
    end
end

-- 更新濒死时间
function PlayerInfo:UpdateDyingTime(InDeltaTime)
    if self.RemianDyingTime and (self.RemianDyingTime >= 0) and (self.TotalDyingTime > 0) then
        self.RemianDyingTime = self.RemianDyingTime - InDeltaTime
        local ShowDyingTime = math.max(0, self.RemianDyingTime)
        self.TxtDyingTime:SetText(math.floor(ShowDyingTime))
        local NewPercent = ShowDyingTime / self.TotalDyingTime
        if BridgeHelper.IsPCPlatform() then
            self.ImgDyingProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", NewPercent)
            self.ImgDyingProgress:GetDynamicMaterial():SetVectorParameterValue("ProgressColor1", self.DyingColor)
        end
        --self.ImgDyingProgress:SetColorAndOpacity(self.DyingColor)
    end
end

--[[ 死亡 ]]
function PlayerInfo:UpdateDeadState(bIsDead)
    --[[local NewVisible = bIsDead and
        UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible
    self.TrsNodeGait:SetVisibility(NewVisible)]]
    print("PlayerInfo:UpdateDeadState bIsDead", bIsDead)
    if bIsDead then
        self:VXE_HUD_PlayerInfo_Blood_LowBlood_Stop()
        self:ResetRecoveryValue()
        return 
    end
    self:InitBaseData()
end

-- 毒圈信息提示
function PlayerInfo:TriggerPlayzoneTips(bShowTips)
    --local NewVisible = bShowTips and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed
    --self.TrsPlayzoneTips:SetVisibility(NewVisible)

    -- 毒圈提示屏幕效果
    local LocalPS = self.LocalPC and self.LocalPC.PlayerState or nil
    local bIsAlive = LocalPS and LocalPS:IsAlive()
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if bShowTips and bIsAlive then
        if (not self.PoisonScreenUIHandle) then
            self.PoisonScreenUIHandle = UIManager:TryLoadDynamicWidget("UMG_PoisonCircleScreen")
        end
    elseif self.PoisonScreenUIHandle then
        UIManager:TryCloseDynamicWidgetByHandle(self.PoisonScreenUIHandle)
        self.PoisonScreenUIHandle = nil
    end
end

-- 检测玩家是否倒地/死亡
function PlayerInfo:CheckDying()
    local LocalPS = self.LocalPC and self.LocalPC.PlayerState or nil
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
    local DyingInfo = nil
    if not UE.UKismetSystemLibrary.IsValid(LocalPCPawn) then
        local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.LocalPC.OriginalPlayerState)
        print("PlayerInfo:CheckDying HudDataCenter",HudDataCenter,GetObjectName(HudDataCenter))
        DyingInfo = HudDataCenter.DyingInfo
    else
        DyingInfo = LocalPCPawn:GetDyingInfo()
    end
    --local DyingInfo = LocalPCPawn:GetDyingInfo()  --这么写会有时序问题，如果消息先来但是pawn还没来，就会拿到空值，所以改成从数据中心获取
   
   
    
    
    print("PlayerInfo:CheckDying", DyingInfo.bIsDying)
    --local LifetimeMgr = UE.US1CharacterLifetimeManager.GetLifetimeManager(LocalPCPawn)
    --if not LocalPCPawn:Cast(UE.AS1GameCharacter) then return end
    --DyingMessageInfo.DyingInfo = LocalPCPawn:Cast(UE.AS1GameCharacter).GetDyingInfo()
    -- if not LifetimeMgr then return end
    --DyingMessageInfo.DyingInfo = LifetimeMgr:GetDyingInfo()
    --DyingMessageInfo.CacheHealthData = CacheHealthData
    --[[
    if (LocalPS and LocalPS:IsDying()) then
        self:OnBeginDying(DyingMessageInfo)
    else
        self:OnEndDying(DyingMessageInfo)
    end]]
          --
    if (LocalPS) then
        self:UpdateDyingInfo(DyingInfo)
    end
end

function PlayerInfo:CheckDead()
    print("PlayerInfo:CheckDead")
    local LocalPS = self.LocalPC and self.LocalPC.PlayerState or nil
    if (LocalPS and LocalPS:IsAlive()) then
        self:OnEndDead(nil)
    else
        self:OnBeginDead(nil)
        self:TriggerPlayzoneTips(false)
    end
end

-------------------------------------------- Callable ------------------------------------

--
function PlayerInfo:Tick(MyGeometry, InDeltaTime)
    --InDeltaTime = UE.UGameplayStatics.GetWorldDeltaSeconds(self)
    self:TickRespawnTime(InDeltaTime)
end

-- 是否打开背包
function PlayerInfo:OnOpenBagPanel(bIsVisible)
    local NewVisible = (bIsVisible) and
        UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
    self.ImgBagActive:SetVisibility(NewVisible)
end


-- 角色背包数据更新
function PlayerInfo:OnUpdateItemFeatureSet(InItemSlotFeatureSet, InItemSlotFeatureSetOuter)
    print("PlayerInfo", ">> OnUpdateItemFeatureSet, ",
        GetObjectName(self.LocalPC), GetObjectName(InItemSlotFeatureSet), GetObjectName(InItemSlotFeatureSetOuter))
    if self.LocalPC == nil then
        Error("self.LocalPC nil")
        return
    end
    if (InItemSlotFeatureSet:GetOuterActor() == self.LocalPC.PlayerState) then
        --self:UpdateArmorInfo()
    end
end

-- 本地更新PS/Pawn
function PlayerInfo:OnUpdateLocalPCPS(InLocalPC, InOldPS, InNewPS)
    testProfile.Begin("PlayerInfo:OnUpdatePlayerState")
    print("PlayerInfo", ">> OnUpdateLocalPCPS, ",
        GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS))
    if InNewPS then
        print("PlayerInfo", ">> OnUpdateLocalPCPS, ",
            GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS), InNewPS:GetPlayerName())
    end
    if self.LocalPC == InLocalPC then
        
        self:InitPlayerStateInfo()
        self:UpdataAvatar()
        self:OnEndDying(nil)
        
    end
    testProfile.End("PlayerInfo:OnUpdatePlayerState") 
end
  
function PlayerInfo:OnLocalPCUpdatePawn(InLocalPC, InPCPwn)
    print("PlayerInfo", ">> OnLocalPCUpdatePawn, ",
        GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InPCPwn))
    if self.LocalPC == InLocalPC then
        self:InitPlayerPawnInfo()
       
    end
end

-- 角色存活改变
function PlayerInfo:OnChangePSAlive(InPS, bIsAlive)
    print("PlayerInfo", ">> OnChangePSAlive, ", InPS, bIsAlive)
    local LocalPS = self.LocalPC and self.LocalPC.PlayerState or nil
    if bIsAlive and (LocalPS == InPS) then
        self:CheckDying()
        self:CheckDead()
    end
end




-- 濒死/救援
function PlayerInfo:OnBeginBeingRescue(InBeRescuedMessageInfo)
    --print("PlayerInfo", ">> OnBeginBeingRescue, ")
end

function PlayerInfo:OnBeginDead(InDeadMessageInfo)
    print("PlayerInfo", ">> OnBeginDead, ")
    self:UpdateDeadState(true)
end

function PlayerInfo:OnBeginDying(InDyingMessageInfo)
    print("PlayerInfo", ">> OnBeginDying, ", InDyingMessageInfo.DyingInfo)

    self.bIsDying = InDyingMessageInfo.DyingInfo.bIsDying
    self:UpdateDyingState({ DyingInfo = InDyingMessageInfo.DyingInfo })
end

function PlayerInfo:UpdateDyingInfo(InDyingInfo)
    if self.bIsDying~=InDyingInfo.bIsDying  then
        if InDyingInfo.bIsDying == true then
            print("PlayerInfo>>UpdateDyingInfo>>Enter bIsDying", InDyingInfo.bIsDying)
            if self.MyDataVM and self.VXDyingDownHealth then
                self.VXDyingDownHealth = self.MyDataVM.HealthInfo.CurrentHealth / self.MyDataVM.HealthInfo.MaxHealth
                self:VXE_HUD_DyingHealth()
            end
            self:VXE_HUD_Playinfo_Me_Die()
            self:ResetRecoveryValue()
        else
            print("PlayerInfo>>UpdateDyingInfo>>Exit Dying", InDyingInfo.bIsDying)
            self:VXE_HUD_PlayerInfo_Die_Out()
        end
    end

    self.bIsDying = InDyingInfo.bIsDying
    self:UpdateDyingState({
        DyingInfo = InDyingInfo
    })
end

function PlayerInfo:UpdateDeadInfo(InDeadInfo)
    print("PlayerInfo>>UpdateDeadInfo>>bIsDead", InDeadInfo.bIsDead)
    self.IsDead = InDeadInfo.bIsDead
    self:UpdateDeadState(InDeadInfo.bIsDead)
end

function PlayerInfo:UpdateRescueMeInfo(InRescueMeInfo)
    if InRescueMeInfo.EndReason == UE.ES1RescueEndReason.RescueBreakOff or InRescueMeInfo.EndReason == UE.ES1RescueEndReason.Cancelled  then
        -- print("UpdateRescueMeInfo: ".."RescueBreakOff Or Cancelled")
        self.IsRescueMe = false
    end

    if self.IsRescueMe == true and self.IsRescueMe ~= InRescueMeInfo.bIsBeRescued then
        -- print("UpdateRescueMeInfo: ".."RescueCompleted")
        self.bIsRescueMeCompleted = true
        self:VXE_HUD_Playinfo_Me_Revive()
    end
    
    self.IsRescueMe = InRescueMeInfo.bIsBeRescued
end

function PlayerInfo:OnEndBeingRescue(InBeRescuedMessageInfo)
end

function PlayerInfo:OnEndDead(InDeadMessageInfo)
    print("PlayerInfo:OnEndDead")
    self:UpdateDeadState(false)
end

function PlayerInfo:OnEndDying(InDyingMessageInfo)
    print("PlayerInfo", ">> OnEndDying, ")

    local DyingInfo = UE.FS1LifetimeDyingInfo()
    DyingInfo.bIsDying = false
    DyingInfo.DyingCounter = 0
    DyingInfo.DeadCountdownTime = 0
    self.bIsDying = DyingInfo.bIsDying
    self:UpdateDyingState({ DyingInfo = DyingInfo })
end

function PlayerInfo:OnBeginRescue(InBeRescuedMessageInfo)
    --print("PlayerInfo", ">> OnBeginRescue, ", InRescueTime)
end

function PlayerInfo:OnEndRescue(InRescueMessageInfo)
    --print("PlayerInfo", ">> OnEndRescue, ", InEndReason)
end

function PlayerInfo:OnRescueActorChanged(InRescueActor)
    --print("PlayerInfo", ">> OnRescueActorChanged, ", GetObjectName(self.InRescueActor))
end

function PlayerInfo:OnUpdateDeadCountdown(InTotalTime, InRemianTime)
    --print("PlayerInfo", ">> OnUpdateDeadCountdown, ", InTotalTime, InRemianTime)

    if self.bIsDying then
        self.TotalDyingTime = InTotalTime
        self.RemianDyingTime = InRemianTime
        self:UpdateDyingTime(0)
    end
end

function PlayerInfo:OnBeginRespawn(InPlayerState, InRespawnTime)
    print("PlayerInfo:OnBeginRespawn")
    self.BeginRespawn = true
    self.TargetPlayerState = InPlayerState
    self.TxtDyingTime:SetText(math.floor(InRespawnTime))
    local NewPercent = (InRespawnTime > 0) and 1 or 0
    if BridgeHelper.IsPCPlatform() then
        self.ImgDyingProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", NewPercent)
        self.ImgDyingProgress:GetDynamicMaterial():SetVectorParameterValue("ProgressColor1", self.DyingColor)
    end
    --self.ImgDyingProgress:SetColorAndOpacity(self.RespawnColor)
    self.TrsDying:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function PlayerInfo:TickRespawnTime(InDeltaTime)
    if self.BeginRespawn and self.TargetPlayerState then
        self.TxtDyingTime:SetText(math.floor(self.TargetPlayerState.RemainRespawnTime))
        local NewPercent = self.TargetPlayerState.RemainRespawnTime / self.TargetPlayerState.TotalRespawnTime
        if BridgeHelper.IsPCPlatform() then
            self.ImgDyingProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", NewPercent)
            self.ImgDyingProgress:GetDynamicMaterial():SetVectorParameterValue("ProgressColor1", self.DyingColor)
        end
        --self.ImgDyingProgress:SetColorAndOpacity(self.RespawnColor)
        if NewPercent <= 0.0 then
            self:OnEndRespawn(nil)
        end
    end
end

function PlayerInfo:OnEndRespawn(InPlayerState)
    --print("PlayerInfo:OnEndRespawn")
    self.TrsDying:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.BeginRespawn = false
end

-- 毒圈信息改变
function PlayerInfo:OnChanged_InPoisonCircle(InMsgBody)
    if self:GetWorld() == InMsgBody.World then
        if self.bInPlayzone ~= InMsgBody.bInPlayzone then
            self.bInPlayzone = InMsgBody.bInPlayzone
            self:TriggerPlayzoneTips(not self.bInPlayzone)
        end
    end
end

-- 更新标记数据
function PlayerInfo:OnUpdateMarkData(InMarkSystemDataSet)
    --print("PlayerInfo", ">> OnUpdateMarkData, ", GetObjectName(InMarkSystemDataSet))

    if self:GetWorld() == InMarkSystemDataSet:GetWorld() then
        self:UpdateTeamMarkItem(InMarkSystemDataSet:GetPlayerState(), InMarkSystemDataSet)
    end
end

function PlayerInfo:UpdateTeamMarkItem(InPS, InMarkSystemDataSet)
    local LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
    if LocalPS ~= InPS then return end

    -- InMarkSystemDataSet = InMarkSystemDataSet or UE.UMarkSystemDataSet.GetMarkSystemDataSet(InPS)
    -- if (not InMarkSystemDataSet) then
    --     return
    -- end

    -- local NewVisible = (InMarkSystemDataSet.MarkData.bMarked) and
    --     UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
    -- self.TrsMark:SetVisibility(NewVisible)
end

--更新队号和颜色
function PlayerInfo:OnChange_PSTeamPos(InPS, InPlayerSpec)
    print("PlayerInfo:OnChange_PSTeamPos", InPS, InPlayerSpec)
    local LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
    if LocalPS ~= InPS then
        return
    end
    local CurTeamPos = BattleUIHelper.GetTeamPos(LocalPS)
    print("PlayerInfo", ">>InitPlayerStateInfo[3],CurTeamPos: ", GetObjectName(LocalPS), GetObjectName(self.LocalPC),
    self.LocalPC, CurTeamPos)
    if self.TeamNumber then self.TeamNumber:SetText(CurTeamPos or 1) end
    local ImgColor = MinimapHelper.GetTeamMemberColor(CurTeamPos)
    --print("PlayerInfo", ">> InitPlayerStateInfo[4], ",self.ImgBg)
    if self.ImgBg then self.ImgBg:SetColorAndOpacity(ImgColor) end
    local SlateColor = UE.FSlateColor()
    SlateColor.SpecifiedColor = ImgColor
    if self.TeamNumber then self.TeamNumber:SetColorAndOpacity(SlateColor) end
    if self.Team_Color then self.Team_Color = ImgColor end
    if self.ImgMark then self.ImgMark:SetColorAndOpacity(ImgColor) end
end

function PlayerInfo:UpdataAvatar()
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
    print("PlayerInfo", ">> UpdataAvatar, ", GetObjectName(self), GetObjectName(LocalPCPawn))
    if LocalPCPawn then
        print("PlayerInfo", ">> UpdataAvatar1234, ", GetObjectName(self), GetObjectName(LocalPCPawn))
        -- 设置玩家基础数据
        local PawnConfig, bIsValidData = UE.UGeGameFeatureStatics.GetPawnData(LocalPCPawn)
        if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.Icon) then
            --local SlateBrushAsset = UE.UKismetSystemLibrary.LoadAsset_Blocking(PawnConfig.Icon)
            --self.ImgAvatar:SetBrushFromAsset(SlateBrushAsset)
            self.ImgAvatar:SetBrushFromSoftTexture(PawnConfig.Icon, false)
            print("PlayerInfo", ">> UpdataAvatar123456, ", GetObjectName(self), GetObjectName(LocalPCPawn), PawnConfig.Name,PawnConfig.Icon)
        end
    else
        local LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
        if LocalPS then
            local HeroId = UE.UPlayerExSubsystem.Get(self):GetPlayerRuntimeHeroId(LocalPS.PlayerId)

            local PawnConfig = UE.FGePawnConfig()
            local  bIsValidData = UE.UGeGameFeatureStatics.GetPawnDataByPawnTypeID(HeroId,PawnConfig,self)
            if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.Icon) then
                self.ImgAvatar:SetBrushFromSoftTexture(PawnConfig.Icon, false)
            end
            print("PlayerInfo", ">> UpdataAvatar12345678, ", GetObjectName(self), GetObjectName(LocalPCPawn), LocalPS.PlayerId,PawnConfig.Name,PawnConfig.Icon)
        end
        
    end
end


function PlayerInfo:UpdateRecoveryMaxArmor(RecoveryMaxArmor)
    print("PlayerInfo:UpdateRecoveryMaxArmor",RecoveryMaxArmor)
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("ExpValue", 0)
    --如果超过self.LimitedArmor需要出缓慢恢复背景，在miscsystem配置，至于怎么对上GE_InstantRecovery的值请找策划
    if self.MaxArmor-RecoveryMaxArmor<=self.LimitedArmor then
        local NewPercent = RecoveryMaxArmor/self.MaxArmor
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("ExpValue", NewPercent)
    end
    

end

function PlayerInfo:OnUpdatePSPawn(InPS)
    --print("PlayerInfo:OnUpdatePSPawn")
    local LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
    if LocalPS and (LocalPS == InPS) then
        self:InitPlayerPawnInfo()
    end
end

function PlayerInfo:OnUpdateAvatar(InHeroId)
    self:UpdataAvatar()
end

function PlayerInfo:OnAnyAttrubuteChange(InData)
    if not CommonUtil.IsValid(self.LocalPC) or not CommonUtil.IsValid(InData.TargetActor) or self.LocalPC:GetPawn() ~= InData.TargetActor then
        return
    end

    -- print("PlayerInfo:OnAnyAttrubuteChange. DamageTags = ", tostring(InData.DamageTags))
    local CanHealthRecovery = false

    if InData.DamageTags then
        if UE.UBlueprintGameplayTagLibrary.HasTag(InData.DamageTags, DamageRecoveryTag, true) then
            for _, GDSChangeData in pairs(InData.DamageInfo) do
                if UE.UBlueprintGameplayTagLibrary.EqualEqual_GameplayTag(GDSChangeData.DamageTag, GDSHealthTag) then
                    CanHealthRecovery = true
                end
            end
        elseif UE.UBlueprintGameplayTagLibrary.HasTag(InData.DamageTags, CharacterRescueTag, true) then
            CanHealthRecovery = true
        end
    end
    
    if CanHealthRecovery then
        local Percent = self.MaxHealth > 0 and (self.CurHealth + (-InData.FinalDamage)) / self.MaxHealth or 0
        self.RecoveryPercent = Percent > 0 and Percent or 0
        self.BarHealth:GetDynamicMaterial():SetScalarParameterValue(HealthBarType.Recovery.Progress, self.RecoveryPercent)
        if not self.bIsDying then
            self.CurHealthPercent = (self.MaxHealth > 0) and (self.CurHealth / self.MaxHealth) or 0
        end
    end
end

function PlayerInfo:OnFreshEnhanceId()
    print("PlayerInfo:OnFreshEnhanceId")

    local LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
    if not LocalPS then
        return
    end

    local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(LocalPS)
    if HudDataCenter == nil then
        return
    end

    if HudDataCenter.SpecEnhanceIdArray:Contains(EnhanceAttribure.NoWarAutoRecovery.EnhanceID) then
        self.HealthAutoRecoveryBG:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.HealthAutoRecoveryBG:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    if HudDataCenter.SpecEnhanceIdArray:Contains(EnhanceAttribure.NoWarAutoRecoveryArmor.EnhanceID) then
        self.ArmorAutoRecoveryBG:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.ArmorAutoRecoveryBG:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end



function PlayerInfo:OnParachuteRespawnStart(bParachuteRespawnStart,ParachuteRespawnCDTime,AvailableChance, ActiveTime,InContext)
    print("PlayerInfo:OnParachuteRespawnStart",bParachuteRespawnStart)
    --和明空对齐后，只有是true的是才走下面的逻辑
    if bParachuteRespawnStart == true then
        self:AddActiveWidgetStyleFlags(1)
    else
       -- print("PlayerInfo:OnParachuteRespawnStart123",bParachuteRespawnStart)
        self:RemoveActiveWidgetStyleFlags(1)
    end
end

function PlayerInfo:OnParachuteRespawnFinished(bParachuteRespawnFinished)
    print("PlayerInfo:OnParachuteRespawnFinished",bParachuteRespawnFinished)
    self:RemoveActiveWidgetStyleFlags(1)
end

function PlayerInfo:CheckRules()
   
    if RespawnSystemHelper.IsPlayerParachuteRespawnStart(self.LocalPC.PlayerState) then 
        if RespawnSystemHelper.CheckIsBeginRespawner(self.LocalPC.PlayerState) == true then
            print("PlayerInfo:CheckRules CheckIsBeginRespawner",true)
            self:AddActiveWidgetStyleFlags(1)
        end
    else
        self:RemoveActiveWidgetStyleFlags(1)
    end
end

function PlayerInfo:OnUpdataReConnect()
    if self.MyDataVM then
        self:ResetRecoveryValue()
        self:SetHealthInfo(self.MyDataVM.HealthInfo, self.MyDataVM.HealthInfo)
        self:SetArmorData(self.MyDataVM, nil)
    end
end

function PlayerInfo:SetArmorData(vm, fieldID)
    if vm.ArmorInfo.IsShowArmor then
        self.SizeBox_BarArmor:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self:SetArmorProcessBarInfo(vm.ArmorInfo.CurrentArmorValue, vm.ArmorInfo.MaxArmorValue, vm.ArmorInfo.ArmorId)
    else
        self.SizeBox_BarArmor:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.ExpValue, 0)
    end
end

function PlayerInfo:SetPreviewHealth(vm, fieldID)
    print("PlayerInfo>>SetPreviewHealth:", vm.PreviewHealth)
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

function PlayerInfo:SetSlowlyRecoveryHealth(vm, fieldID)
    print("PlayerInfo>>SetSlowlyRecoveryHealth:", vm.SlowlyRecoveryHealth)
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

function PlayerInfo:SetPreviewArmorValue(vm, fieldID)
    print("PlayerInfo>>SetPreviewArmorValue:", vm.PreviewArmorValue)
    if vm.PreviewArmorValue > 0 then
        local Percent = (vm.ArmorInfo.MaxArmorValue > 0) and vm.PreviewArmorValue / vm.ArmorInfo.MaxArmorValue or 0
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.ExpValue, Percent)
    else
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.ExpValue, 0)
    end
end

function PlayerInfo:SetSlowlyRecoveryMaxArmor(vm, fieldID)
    print("PlayerInfo>>SetSlowlyRecoveryMaxArmor:", vm.SlowlyRecoveryMaxArmor)
    if vm.SlowlyRecoveryMaxArmor > 0 then
        local Percent = (vm.ArmorInfo.MaxArmorValue > 0) and vm.SlowlyRecoveryMaxArmor / vm.ArmorInfo.MaxArmorValue or 0
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.SlowProgress, Percent)
    else
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.SlowProgress, 0)
    end
end

function PlayerInfo:ResetRecoveryValue()
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastOpacity, 0)
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastProgress, 0)
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.Healback, 0)
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.BackProgress, 0)
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.ExpValue, 0)
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.SlowProgress, 0)
end

return PlayerInfo
