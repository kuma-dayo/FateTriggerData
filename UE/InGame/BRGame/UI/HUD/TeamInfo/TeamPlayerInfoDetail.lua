--
-- 战斗界面 - 角色信息基础
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.28
--
require("InGame.BRGame.ItemSystem.PickSystemHelper")
require ("InGame.BRGame.ItemSystem.RespawnSystemHelper")

local TeamPlayerInfoDetail = Class("Common.Framework.UserWidget")

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

-------------------------------------------- Init/Destroy ------------------------------------

function TeamPlayerInfoDetail:OnInit()
    print("XTDebug TeamPlayerInfoDetail", ">> OnInit, ...", GetObjectName(self))

    -- 健康值预览
    self.PreviewRate = self.PreviewRate or 0.25
    self.bPreviewTreat = false
    self.PreviewPercent = 0
    self.PreviewTreatValue = 0
    self.RespawnTotalTime = 0 -- 复活这个过程中需要的总时间
    self.CurRespawnRemainTime = 0 -- 当前复活这个过程中还剩余的时间

    --血条动效
    self.VXPreviewPercent = 0
    --判断完成救援状态
    self.bIsRescueMeCompleted = false
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.ProgressValue, 0)
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealthbarHurtValue, 0)
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealthbarAfterValue, 0)
    local NewColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", "White")
    self.VX_BarHealth:GetDynamicMaterial():SetVectorParameterValue(VXHealthBarParam.MainColor, NewColor)
    
    self.TxtName:SetText('')
    -- self.BarArmor:SetPercent(0)
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("Value", 0)
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("ExpValue", 0)
    self.BarHealthPreview:GetDynamicMaterial():SetScalarParameterValue("Progress", 0)
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.SlowProgress, 0)
    -- self.BarHealthPreview:SetPercent(0)
    self.IsDead = false
   
    self.ImgTalking:SetRenderOpacity(0.5)
    self.ArmorValue = self.SizeBox_BarArmor.WidthOverride
    self.bIsDying = false
    self.IsRescueMe = false
    self.DyingColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", "Red")
    self.RespawnColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", "Red")
    self.TxtNameColor_Original = self.TxtNameStateColor:FindRef("Normal") or self.TxtName.ColorAndOpacity
    UserWidget.OnInit(self)
    
end

function TeamPlayerInfoDetail:OnDestroy()
    -- print("TeamPlayerInfoDetail", ">> OnDestroy, ...", GetObjectName(self))

    self:ResetData()
    self:UnBindPlayerVMData()

    UserWidget.OnDestroy(self)
end

function TeamPlayerInfoDetail:UnBindPlayerVMData()
    if self.MyDataVM then
        self.MyDataVM.OnHealthValueChangedHandle:Remove(self, self.SetHealthInfo)
        self.MyDataVM:K2_RemoveFieldValueChangedDelegateSimple("ArmorInfo", {self, self.SetArmorData}) 
        self.MyDataVM:K2_RemoveFieldValueChangedDelegateSimple("PreviewHealth", {self, self.SetPreviewHealth}) 
        self.MyDataVM:K2_RemoveFieldValueChangedDelegateSimple("SlowlyRecoveryHealth", {self, self.SetSlowlyRecoveryHealth})
        self.MyDataVM:K2_RemoveFieldValueChangedDelegateSimple("PreviewArmorValue", {self, self.SetPreviewArmorValue}) 
        self.MyDataVM:K2_RemoveFieldValueChangedDelegateSimple("SlowlyRecoveryMaxArmor", {self, self.SetSlowlyRecoveryMaxArmor})
        self.MyDataVM:K2_RemoveFieldValueChangedDelegateSimple("SkillStatus", {self, self.UpdateSkillStatus})
        self.MyDataVM = nil
    end
end

-------------------------------------------- Get/Set ------------------------------------

function TeamPlayerInfoDetail:GetTeamMemberColor()
    local CurTeamPos = BattleUIHelper.GetTeamPos(self.RefPS)
    local ImgColor = MinimapHelper.GetTeamMemberColor(CurTeamPos)
    return ImgColor
end

-------------------------------------------- Function ------------------------------------

function TeamPlayerInfoDetail:ResetData()
    MsgHelper:UnregisterList(self, self.MsgList or {})
    self.SizeBox_BarArmor.WidthOverride = self.ArmorValue
    self.RefPS = nil
    self.IsDead = false
    self.MsgList=nil
end

function TeamPlayerInfoDetail:OnClose()
    print("TeamPlayerInfoDetail:OnClose123",GetObjectName(self))
    MsgHelper:UnregisterList(self, self.MsgList or {})
    self:VXE_HUD_Team_Down_Out()
    self.MsgList= nil
    self:RemoveActiveWidgetStyleFlags(2)
end

function TeamPlayerInfoDetail:InitData(InPlayerState)
    print("XTDebug TeamPlayerInfoDetail:InitData",GetObjectName(InPlayerState),InPlayerState.PlayerId)
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
   
    -- local HudNetDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(InPlayerState)
    -- self.fieid_IsOpenFire = UE.FFieldNotificationId()
    -- self.fieid_IsOpenFire.FieldName = "IsOpenFire"
    -- HudNetDataCenter.HudNetDataCenterViewModel:K2_AddFieldValueChangedDelegate(self.fieid_IsOpenFire, { self, self.OnIsOpenFireChange })
    -- self.fieid_DyingInfo = UE.FFieldNotificationId()
    -- self.fieid_DyingInfo.FieldName = "DyingInfo"
    -- HudNetDataCenter.HudNetDataCenterViewModel:K2_AddFieldValueChangedDelegate(self.fieid_DyingInfo, { self, self.OnDyingInfoChange })
   
    --local LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
    self.RefPS = InPlayerState
    -- 初始化濒死颜色
    
   
    -- 名字
    self.TxtName:SetText(InPlayerState:GetPlayerName())
    -- 护甲值
    --self:UpdateArmorInfo()
   --队伍颜色和编号
    self:OnChange_PSTeamPos(self.RefPS)
    
    self.MsgList = {{
        MsgName = GameDefine.MsgCpp.PLAYER_PSPawn,
        Func = self.OnUpdatePSPawn,
        bCppMsg = true,
        WatchedObject = self.RefPS
    }, 
    --{
    --    MsgName = GameDefine.MsgCpp.PLAYER_PSHealth,
    --    Func = self.SetHealthInfo,
    --    bCppMsg = true,
    --    WatchedObject = self.RefPS
    --}, 
    {
        MsgName = GameDefine.MsgCpp.PLAYER_PSAlive,
        Func = self.OnChangePSAlive,
        bCppMsg = true,
        WatchedObject = self.RefPS
    }, {
        MsgName = GameDefine.MsgCpp.UISync_UpdateMarkData,
        Func = self.OnUpdateMarkData,
        bCppMsg = true,
        WatchedObject = nil
    }, {
        MsgName = GameDefine.MsgCpp.BAG_FeatureSetUpdate,
        Func = self.OnUpdateItemFeatureSet,
        bCppMsg = true,
        WatchedObject = nil
    },
    -- { MsgName = GameDefine.MsgCpp.RespawnX_Respawning_Post, Func = self.OnChangePlayerInfo,     bCppMsg = true, WatchedObject = self.LocalPC }
                    {
        MsgName = GameDefine.MsgCpp.PLAYER_PSDeadTimeSec,
        Func = self.OnChangeDeadTimeSec,
        bCppMsg = true,
        WatchedObject = self.RefPS
    }, -- 修复下面报错。PLAYER_PSRespawnGeneState的定义已经被删除了，所以注释掉
    {
        MsgName = GameDefine.MsgCpp.PLAYER_PSUpdateRespawnGeneState,
        Func = self.OnChangeRespawnGeneState,
        bCppMsg = true,
        WatchedObject = self.RefPS
    }, 
    -- {
    --     MsgName = GameDefine.MsgCpp.PLAYER_OnBeginRespawn,
    --     Func = self.OnBeginRespawn,
    --     bCppMsg = true,
    --     WatchedObject = self.RefPS
    -- }, 
 {
        MsgName = GameDefine.MsgCpp.PLAYER_OnGeneProgressChange,
        Func = self.OnGeneProgressChange,
        bCppMsg = true,
        WatchedObject = self.RefPS
    },{
        MsgName = GameDefine.MsgCpp.UISync_UpdateOpenFireStatus,
        Func = self.IsOpenFire,
        bCppMsg = true,
        WatchedObject = self.RefPS
    },{
        MsgName = GameDefine.MsgCpp.UISync_UpdateOnBeginDying,
        Func = self.UpdateDyingInfo,
        bCppMsg = true,
        WatchedObject = self.RefPS
    },{ 
        MsgName = GameDefine.MsgCpp.UISync_UpdateOnDead,
        Func = self.UpdateDeadInfo,   
        bCppMsg = true, 
        WatchedObject = self.RefPS 
    },{ 
        MsgName = GameDefine.MsgCpp.UISync_UpdateOnRescueMe,
        Func = self.UpdateRescueMeInfo,   
        bCppMsg = true, 
        WatchedObject = self.RefPS 
    },
    -- { 
    --     MsgName = GameDefine.MsgCpp.UISync_UpdateSkillStatus,
    --     Func = self.UpdateSkillStatus,   
    --     bCppMsg = true, 
    --     WatchedObject = self.RefPS 
    -- },
    --{ MsgName = GameDefine.MsgCpp.UISync_UpdateRecoveryMaxArmor, Func = self.UpdateRecoveryMaxArmor, bCppMsg = true,  WatchedObject = self.RefPS  },
    --{ MsgName = GameDefine.MsgCpp.PLAYER_PSTeamPos,          Func = self.OnChange_PSTeamPos, bCppMsg = true, WatchedObject =nil },
    -- { MsgName = UE.USDKTags.Get().RTCSDKOnRemoteAudioPropertiesReport,            Func = self.OnRemoteAudioPropertiesReport,      bCppMsg = true },
    {MsgName = GameDefine.MsgCpp.UISync_Update_RuntimeHeroId,     Func = self.OnUpdateAvatar,  bCppMsg = true,  WatchedObject = self.RefPS }, 
    { MsgName = GameDefine.MsgCpp.RespawnX_RuleCollect,          Func = self.OnChange_RespawnXRule, bCppMsg = true, WatchedObject =nil },
    {MsgName = GameDefine.MsgCpp.UISync_Update_ParachuteRespawnStart,     Func = self.OnParachuteRespawnStart,  bCppMsg = true,  WatchedObject = self.RefPS}, 
    {MsgName = GameDefine.MsgCpp.UISync_Update_ParachuteRespawnFinished,     Func = self.OnParachuteRespawnFinished,  bCppMsg = true,  WatchedObject = self.RefPS}, 
    
    {MsgName = GameDefine.MsgCpp.UIEvent_Update_DisConnect,     Func = self.OnUpdateDisConnectStatus,  bCppMsg = true,  WatchedObject = self.RefPS}, 
    { MsgName = GameDefine.MsgCpp.UIEvent_Update_ReConnect,          Func = self.OnUpdataReConnect, bCppMsg = true, WatchedObject =nil },
    {MsgName = GameDefine.MsgCpp.UISync_Update_ParachuteRespawnRuleEnd,     Func = self.OnRuleFinishedParachuteRespawn,  bCppMsg = true,  WatchedObject = nil}, 
   

    
}
    MsgHelper:RegisterList(self, self.MsgList)

    self.PlayerChatComponent = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
    self.PlayerChatComponent.VoiceRoomMemberSpeakNotify:Add(self,self.OnMemberPlayerSpeaking)

    self:CheckRules()
    self:InitPlayerPawnInfo()

    self.UIManager = UE.UGUIManager.GetUIManager(self)
    local VMGameplayTag = UE.FGameplayTag()
    VMGameplayTag.TagName = "MVVM.PlayerInfo"
    self:UnBindPlayerVMData()
    self.MyDataVM = self.UIManager:GetDynamicViewModel(VMGameplayTag, self.RefPS)
    if not self.MyDataVM then print("TeamPlayerInfoDetail>>Not found ViewModel") end
    if self.MyDataVM then
        self.MyDataVM.OnHealthValueChangedHandle:Add(self, self.SetHealthInfo) 
        self.MyDataVM:K2_AddFieldValueChangedDelegateSimple("ArmorInfo", {self, self.SetArmorData}) 
        self.MyDataVM:K2_AddFieldValueChangedDelegateSimple("PreviewHealth", {self, self.SetPreviewHealth}) 
        self.MyDataVM:K2_AddFieldValueChangedDelegateSimple("SlowlyRecoveryHealth", {self, self.SetSlowlyRecoveryHealth})
        self.MyDataVM:K2_AddFieldValueChangedDelegateSimple("PreviewArmorValue", {self, self.SetPreviewArmorValue}) 
        self.MyDataVM:K2_AddFieldValueChangedDelegateSimple("SlowlyRecoveryMaxArmor", {self, self.SetSlowlyRecoveryMaxArmor}) 
        self.MyDataVM:K2_AddFieldValueChangedDelegateSimple("SkillStatus", {self, self.UpdateSkillStatus})
        self:SetHealthInfo(self.MyDataVM.HealthInfo, self.MyDataVM.HealthInfo)
        self:SetArmorData(self.MyDataVM, nil)
        self:UpdateSkillStatus(self.MyDataVM, nil)
    end
   
    local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.RefPS)
    if HudDataCenter then self.IsDead = HudDataCenter.DeadInfo.bIsDead end
    if self.LocalPC then self.bInOB = self.LocalPC.PlayerState ~= self.LocalPC.OriginalPlayerState end
end


function TeamPlayerInfoDetail:OnMemberPlayerSpeaking(MemberID, bSpeaking)
    print("(Wzp)PlayerInfo:OnMemberPlayerSpeaking  [ObjectName]=",GetObjectName(self),",[MemberID]=",MemberID,",[bSpeaking]=",bSpeaking)

    if self.RefPS then
        print("(Wzp)PlayerInfo:OnMemberPlayerSpeaking  [self.RefPS]=",self.RefPS,",[PlayerId]=",self.RefPS.PlayerId)
        local PlayerId = self.RefPS.PlayerId
        local RoomMemberInfo = self.PlayerChatComponent:GetVoiceRoomInfoByPlayerID(PlayerId)
        if RoomMemberInfo then
            local SelfMemberID = RoomMemberInfo.MemberID
            print("(Wzp)PlayerInfo:OnMemberPlayerSpeaking  [SelfMemberID]=",SelfMemberID)
            if MemberID == SelfMemberID then
                self.ImgTalking:SetRenderOpacity(bSpeaking and self.ChatOpacity or self.NotChatOpacity)
            end
        end
    end
end

function TeamPlayerInfoDetail:OnChatFinish()
    --TODO WangZeping 蓝图被checkout ，先写死到代码里
    self.ImgTalking:SetRenderOpacity(self.NotChatOpacity)
end


-- 初始化角色消息
function TeamPlayerInfoDetail:InitPlayerPawnInfo()
    -- do return end
    print("TeamPlayerInfoDetail:InitPlayerPawnInfo self.RefPS",self.RefPS)
    local RefPawn = UE.UPlayerStatics.GetPSPlayerPawn(self.RefPS)
    print("TeamPlayerInfoDetail:InitPlayerPawnInfo self.RefPS PlayerId",self.RefPS.PlayerId,RefPawn)
    if (not RefPawn) then
        --找不到pawn，可能是进了观战，这个时候，要走特殊手段
        local HeroId = UE.UPlayerExSubsystem.Get(self):GetPlayerRuntimeHeroId(self.RefPS.PlayerId)
        local PawnConfig = UE.FGePawnConfig()
        local  bIsValidData = UE.UGeGameFeatureStatics.GetPawnDataByPawnTypeID(HeroId,PawnConfig,self)
        if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.Icon) then
            self.ImgAvatar:SetBrushFromSoftTexture(PawnConfig.Icon, false)
        end
        self:SetSkillState(PawnConfig)
        self:OnBeginDead(nil)
        print("TeamPlayerInfoDetail", ">> UpdataAvatar123456, ", GetObjectName(self), GetObjectName(RefPawn), self.RefPS.PlayerId,PawnConfig.Name,PawnConfig.Icon)
        -- Warning("TeamPlayerInfoDetail", ">> InitPlayerPawnInfo, RefPawn is nil!!!")
        return
    end

    -- 设置玩家基础数据
    RefPawn = RefPawn.Object or RefPawn
    local PawnConfig, bIsValidData = UE.UGeGameFeatureStatics.GetPawnData(RefPawn)
    if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.Icon) then
        -- local SlateBrushAsset = UE.UKismetSystemLibrary.LoadAsset_Blocking(PawnConfig.Icon)
        -- self.ImgAvatar:SetBrushFromAsset(SlateBrushAsset)
        self.ImgAvatar:SetBrushFromSoftTexture(PawnConfig.Icon, false)
        print("TeamPlayerInfoDetail", ">> UpdataAvatar12345678, ", GetObjectName(self), GetObjectName(RefPawn), self.RefPS.PlayerId,PawnConfig.Name,PawnConfig.Icon)
    end
    --设置技能大招图标信息
    self:SetSkillState(PawnConfig)
    
    -- 重置玩家状态
    self:OnEndDying(nil)
    self:OnEndDead(nil)

    -- 地图标记
    self:UpdateTeamMarkItem(self.RefPS)
end

function TeamPlayerInfoDetail:SetSkillState(PawnConfig)
    if not PawnConfig then return end
    for index, SkillData in pairs(PawnConfig.SkillConfigs) do
        --print("TeamPlayerInfoDetail:InitPlayerPawnInfo",index,SkillData,SkillData.TriggerInputTag.TagName )
        if SkillData.TriggerInputTag.TagName == "EnhancedInput.Skill.Ultimate" then
            if UE.UKismetSystemLibrary.IsValidSoftObjectReference(SkillData.SkillIcon) then
                self.ImgSkillState:SetBrushFromSoftTexture(SkillData.SkillIcon, false)
            end
        end
    end
end

-- 健康值
function TeamPlayerInfoDetail:SetHealthInfo(NewHealthInfo, OldHealthInfo)
    print("TeamPlayerInfoDetail>>SetHealthInfo>>Old:CurrentHealth:", OldHealthInfo.CurrentHealth, "MaxHealth:", OldHealthInfo.MaxHealth, "New CurrentHealth:", NewHealthInfo.CurrentHealth, "MaxHealth:", NewHealthInfo.MaxHealth,
    " bIsDying: ", self.bIsDying, " bIsDead: ", self.IsDead)

    -- 低血量动效
    if NewHealthInfo.CurrentHealth <= 25 then
        if self.bIsDying == false or self.bIsRescueMeCompleted == true then
            self:VXE_HUD_PlayerInfo_Blood_LowBlood()
            if self.bIsRescueMeCompleted == true then self.bIsRescueMeCompleted = false end
        end
    else
        self:VXE_HUD_PlayerInfo_Blood_LowBlood_Stop()
    end

    local OldPercent = (OldHealthInfo.MaxHealth > 0) and (OldHealthInfo.CurrentHealth / OldHealthInfo.MaxHealth) or 0
    local NewPercent = (NewHealthInfo.MaxHealth > 0) and (NewHealthInfo.CurrentHealth / NewHealthInfo.MaxHealth) or 0
 
    --预览伤害值(新血条设置)
    if self.VXPreviewPercent <= 0 and not self.bIsDying and not self.IsDead then
        local DamagePercent = (OldHealthInfo.CurrentHealth > 0) and ((OldHealthInfo.CurrentHealth - NewHealthInfo.CurrentHealth) / NewHealthInfo.MaxHealth) or 0
        --如果连续扣血则叠加预览值
        self.VXPreviewPercent = self.VXPreviewPercent + DamagePercent > 0 and DamagePercent or 0
        if self.VXPreviewPercent == 0 then self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.ProgressValue, 1) end
        --倒地后扣血不播放扣血色散动效
        if self.VXPreviewPercent > 0 then 
            print("TeamPlayerInfoDetail>>SetHealthInfo>>Play Blood Hurt")
            self:VXE_HUD_PlayerInfo_Blood_Hurt() 
            self:VXE_HUD_Hurt_Anim() 
        end
    end

    --由于倒地与救援时序问题，在救援成功后重播一次低血量闪烁
    if NewHealthInfo.CurrentHealth <= 25 and self:IsPlayingAnimation(self.vx_hud_player_lowblood) then
        self:VXE_HUD_PlayerInfo_Blood_LowBlood() 
    end

    -- 设置当前值
    if self.VXDyingDownHealth then self.VXDyingDownHealth = NewPercent end
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealthbarAfterValue, NewPercent)
end

--[[
    预览血量治疗值
    bPreviewTreat:  启用或关闭预览
    InExtraValue:   预览额外值
]]
function TeamPlayerInfoDetail:PreviewTreat(bPreviewTreat, InExtraValue)
    print("TeamPlayerInfoDetail", ">> PreviewTreat, ", bPreviewTreat, InExtraValue)

    self.bPreviewTreat = bPreviewTreat
    self.PreviewTreatValue = InExtraValue
    if bPreviewTreat then
        local CurPercent = self.BarHealth:GetDynamicMaterial():K2_GetScalarParameterValue("Progress")
        self.PreviewPercent = CurPercent + (InExtraValue * 0.01)
        print("TeamPlayerInfoDetail:PreviewTreat self.PreviewPercent",self.PreviewPercent)
        -- self.PreviewPercent = self.BarHealth.Percent + (InExtraValue * 0.01)
    else
        self.PreviewPercent = 0
    end

    -- local NewColor = bPreviewTreat and UIHelper.LinearColor.Green or UIHelper.LinearColor.Red

    local NewColorKey = bPreviewTreat and "Green" or "Red"
    local NewColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", NewColorKey)
    self.BarHealthPreview:GetDynamicMaterial():SetVectorParameterValue("FillColor", NewColor)
    -- self.BarHealthPreview:SetFillColorAndOpacity(NewColor)
    self.BarHealthPreview:GetDynamicMaterial():SetScalarParameterValue("Progress", self.PreviewPercent)
    -- self.BarHealthPreview:SetPercent(self.PreviewPercent)
end

-- 护甲数值信息
function TeamPlayerInfoDetail:SetArmorProcessBarInfo(InCurArmor, InMaxArmor, InArmorItemId)
    print("TeamPlayerInfoDetail", ">> SetArmorProcessBarInfo, ", InCurArmor, InMaxArmor)

    InCurArmor = InCurArmor or 0
    InMaxArmor = InMaxArmor or 0
    local NewPercent = (InCurArmor > 0) and (InCurArmor / InMaxArmor) or 0

    --用材质之后修改参数实现
    self.MaxArmor = InMaxArmor
    if InCurArmor == InMaxArmor or InCurArmor == 0 then
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("ExpValue", 0)
    end
    
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("Value", NewPercent)
   
    --local NewTxt = math.floor(InCurArmor) .. "/" .. math.floor(InMaxArmor)
    --self.BarArmor:SetToolTipText(NewTxt)

    --这里开始使用MiscSystem的颜色
    local MiscSystem = UE.UMiscSystem.GetMiscSystem(self)
    local ArmorLvAttributes = MiscSystem.BarArmorAttributes
    self.SizeBox_BarArmor.WidthOverride = self.ArmorValue
    BattleUIHelper.SetArmorShieldLvInfo(InArmorItemId, self.BarArmor, ArmorLvAttributes, self.SizeBox_BarArmor)
    
end

-- 更新护甲信息
function TeamPlayerInfoDetail:UpdateArmorInfo()
    local IsShowArmor = false

    -- 得到当前护甲的护甲物品Id
    local TempViewPS = self.RefPS
    local TempArmorItemId, IsExistArmorItemId = UE.UItemStatics.GetArmorBodyArmorShieldItemIdFromPS(TempViewPS)
    local TempArmorShieldValue, IsExistArmorShieldValue = UE.UItemStatics.GetArmorBodyArmorShieldFromPS(TempViewPS)
    local TempArmorShieldMaxValue, IsExistArmorShieldMaxValue = UE.UItemStatics.GetArmorBodyMaxArmorShieldFromPS(TempViewPS)
    
    if IsExistArmorItemId and IsExistArmorShieldValue and IsExistArmorShieldMaxValue then
        IsShowArmor = true
    end

    if IsShowArmor then
        self.SizeBox_BarArmor:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        

        -- 设置进度条百分比，颜色
        self:SetArmorProcessBarInfo(TempArmorShieldValue, TempArmorShieldMaxValue, TempArmorItemId)

        -- 根据护甲等级
        local TempItemLevel, IsExistItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, TempArmorItemId, "ItemLevel", GameDefine.NItemSubTable.Ingame, "PlayerInfo:UpdateArmorInfo")
        if IsExistItemLevel then
            -- -- 设置护甲等级文字
            -- local TempTxt = BattleUIHelper.GetRomanNumText(TempItemLevel)
            -- self.TxtArmorLv:SetText(TempTxt)

           
        end
    else
        self.SizeBox_BarArmor:SetVisibility(UE.ESlateVisibility.Collapsed)
        
    end
end


-- 更新为正常界面(else 部分针对基因未拾取要隐藏)

function TeamPlayerInfoDetail:UpdateToNormalWidget(bIsToNormal)
    print("XTDebug TeamPlayerInfoDetail:UpdateToNormalWidget bIsToNormal", bIsToNormal,self.RefPS.PlayerId)
    if bIsToNormal then
        -- 普通状态界面设置
        self.BarArmor:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.HPCanvasPanel:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        -- self.BarHealthPreview:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        -- self.BarHealth:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.ImgBgDying:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TrsOthers:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.ImgAvatar:SetOpacity(1)
        self.ImgAvatar:SetColorAndOpacity(self.ImgAvatarStateColor:FindRef("Normal"))
        self.DeadMark:SetVisibility(UE.ESlateVisibility.Collapsed)
        -- self.ImgDead:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TxtName:SetColorAndOpacity(self.TxtNameColor_Original)
    else
        self.HPCanvasPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    if self.ImgBgNum then
        local NewColor = self:GetTeamMemberColor()
        self.ImgBgNum:SetColorAndOpacity(NewColor)
        local SlateColor = UE.FSlateColor()
        SlateColor.SpecifiedColor = NewColor
        if self.TeamNumber then self.TeamNumber:SetColorAndOpacity(SlateColor) end
    end
end
function TeamPlayerInfoDetail:UpdateToDeadlWidget(bIsToDead)
    print("XTDebug TeamPlayerInfoDetail:UpdateToDeadlWidget(bIsToDead)", bIsToDead)
    -- 死亡状态界面设置

    self.BarArmor:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.HPCanvasPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self.BarHealthPreview:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self.BarHealth:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.ImgBgDying:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.ImgPlatform:SetRenderOpacity(self.DeadOpacity)
    self.TxtName:SetColorAndOpacity(self.TxtNameStateColor:FindRef("Dead"))
    self.DeadMark:SetRenderOpacity(self.DeadOpacity)
    self.ImgAvatar:SetColorAndOpacity(self.ImgAvatarStateColor:FindRef("Dead"))
    self.TxtName:SetRenderOpacity(self.DeadOpacity)
    self.DeadMark:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    self.TrsMark:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TrsOthers:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self.ImgDead:SetVisibility(UE.ESlateVisibility.HitTestInvisible)

    if self.ImgBgNum then
        local NewColor = self.ImgAvatarStateColor:FindRef("Dead")
        self.ImgBgNum:SetColorAndOpacity(NewColor)
        local SlateColor = UE.FSlateColor()
        SlateColor.SpecifiedColor = NewColor
        if self.TeamNumber then self.TeamNumber:SetColorAndOpacity(SlateColor) end
    end
end
--[[
    濒死/救援
    InParamters: { 
        DyingInfo(FS1LifetimeDyingInfo):  { bIsDying, DyingCounter, DeadCountdownTime }
    }
]]
function TeamPlayerInfoDetail:UpdateDyingState(InParamters)
    print(" TeamPlayerInfoDetail", ">> UpdateDyingState, ", InParamters.DyingInfo.bIsDying,InParamters.DyingInfo.DeadCountdownRemainTime)

    local NewColorKey = InParamters.DyingInfo.bIsDying and "Red" or "White"
    local NewColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", NewColorKey)
    self.BarHealth:GetDynamicMaterial():SetVectorParameterValue("FillColor", NewColor)
    self.VX_BarHealth:GetDynamicMaterial():SetVectorParameterValue(VXHealthBarParam.MainColor, NewColor)
    -- self.BarHealth:SetFillColorAndOpacity(NewColor)

    --

   
    local NewVisible = InParamters.DyingInfo.bIsDying and UE.ESlateVisibility.HitTestInvisible or
                           UE.ESlateVisibility.Collapsed
    self.TrsDying:SetVisibility(NewVisible)
    self.ImgBgDying:SetVisibility(NewVisible)

    self.TotalDyingTime = InParamters.DyingInfo.bIsDying and InParamters.DyingInfo.DeadCountdownTime or 0
    self.RemianDyingTime = self.TotalDyingTime
    self.TxtDyingTime:SetText(math.floor(self.TotalDyingTime))
    local NewPercent = (self.TotalDyingTime > 0) and 1 or 0
    self.ImgDyingProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", NewPercent)
    self.ImgDyingProgress:SetColorAndOpacity(self.DyingColor)
   
    

    if InParamters.DyingInfo.bIsDying then
        self.ImgBgDying:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.TxtName:SetColorAndOpacity(self.TxtNameStateColor:FindRef("Dying"))
        self.ImgAvatar:SetColorAndOpacity(self.ImgAvatarStateColor:FindRef("Dying"))
        self.TotalDyingTime = InParamters.DyingInfo.DeadCountdownTime
        self.RemianDyingTime = InParamters.DyingInfo.DeadCountdownRemainTime
        self:UpdateDyingTime(0)

    else
        --self:UpdateToNormalWidget(true)
        self:UpdateDeadState()
    end
end

-- 更新濒死时间
function TeamPlayerInfoDetail:UpdateDyingTime(InDeltaTime)
    
    if self.RemianDyingTime and (self.RemianDyingTime >= 0) and (self.TotalDyingTime > 0) then
        self.RemianDyingTime = self.RemianDyingTime - InDeltaTime
        local ShowDyingTime = math.max(0, self.RemianDyingTime)
        self.TxtDyingTime:SetText(math.floor(ShowDyingTime))
        local NewPercent = ShowDyingTime / self.TotalDyingTime
        self.ImgDyingProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", NewPercent)
        self.ImgDyingProgress:SetColorAndOpacity(self.DyingColor)
    end
end

--[[ 死亡 ]]
function TeamPlayerInfoDetail:UpdateDeadState(bIsDead)
    local PlayerName = "None"
    if UE.UKismetSystemLibrary.IsValid(self.RefPS) then
        PlayerName = self.RefPS:GetPlayerName()
    end
    print("  TeamPlayerInfoDetail", ">> UpdateDeadState[1], ", PlayerName, bIsDead)

    self:UpdateToNormalWidget(not bIsDead)
    print("TeamPlayerInfoDetail>>UpdateDeadState>>UpdateGeneData")
    self:UpdateGeneData()
end

-- 更新队伍标记
function TeamPlayerInfoDetail:UpdateTeamMarkItem(InPS, InMarkSystemDataSet)
    if self.RefPS ~= InPS then
        return
    end

    -- InMarkSystemDataSet = InMarkSystemDataSet or UE.UMarkSystemDataSet.GetMarkSystemDataSet(InPS)
    -- if (not InMarkSystemDataSet) then
    --     return
    -- end

    -- local NewVisible = (InMarkSystemDataSet.MarkData.bMarked) and UE.ESlateVisibility.HitTestInvisible or
    --                        UE.ESlateVisibility.Collapsed
    -- self.TrsMark:SetVisibility(NewVisible)
end

function TeamPlayerInfoDetail:ClearGeneTimerHandle()
    if self.GeneTimerHandle then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.GeneTimerHandle)
        self.GeneTimerHandle = nil
   end
end

-- 更新基因状态
function TeamPlayerInfoDetail:UpdateGeneData()
    --print("XTDebug TeamPlayerInfoDetail:UpdateGeneData")
    -- TODO: 对接新版基因
    -- do return end
    if (not UE.UKismetSystemLibrary.IsValid(self.RefPS)) then
        print("TeamPlayerInfoDetail>>UpdateGeneData self.RefPS", self.RefPS, GetObjectName(self.RefPS))
        return
    end
    
    local bAlive = false
    if self.RefPS:IsAlive() ==true then
        bAlive = not self.IsDead
    else
        bAlive =self.RefPS:IsAlive()
    end

    local gene = UE.URespawnSubsystem.Get(self):HasGeneRespawnRule()
    if gene == false then
        if bAlive == true then
            self:UpdateToNormalWidget(bAlive)
        else
            self:UpdateToDeadlWidget(true)
        end
        return
        
    end
    
    -- 颜色/倒计时/剩余时间
    local RespawnGeneState = RespawnSystemHelper.GetRespawnGeneState(self.RefPS)
	local DeadTime = RespawnSystemHelper.GetPlayerDeadTimeSec(self.RefPS)
	local TotalTime = RespawnSystemHelper.GetGeneDurationTimeFromDead(self.RefPS)

    local TimeSeconds = UE.UAdvancedWorldBussinessMarkSystem.GetTimeSeconds(self)
    local RemainTime = math.max(0, (DeadTime + TotalTime) - TimeSeconds)
   
    -- 显示剩余时间数据
    
    
    local LocalAlive = nil
    if self.LocalPC then
        local LocalPawn = self.LocalPC:K2_GetPawn()
        if LocalPawn then
            LocalAlive = UE.US1PickupStatics.IsPlayerAlive(LocalPawn)
        end
    end
   
   
    print("TeamPlayerInfoDetail>>UpdateGeneData bAlive",bAlive)
    self:UpdateToNormalWidget(bAlive)
    local bShowGeneTime = (DeadTime > 0) and (TotalTime > 0) and (RemainTime > 0) and (not bAlive)
    local NewVisible = (bShowGeneTime) and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed
    self.ImgBgGene:SetVisibility(not bAlive and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.TrsGeneTime:SetVisibility(NewVisible)
    if bShowGeneTime then
        self.GeneTimeData = {
            RemainTime = RemainTime,
            TotalTime = TotalTime
        }
        if not self.GeneTimerHandle then
            self.GeneTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.UpdateGeneTime}, 1, true, 0, 0)
        end
    else
        self.GeneTimeData = nil
        self.lastServerTime = nil
        self:ClearGeneTimerHandle()
    end


    -- 显示基因状态
    local TxtGeneTipsKey, bGenePickedup = nil, false
    if (not bAlive) then
        
        if (UE.ERespawnGeneState.Default == RespawnGeneState) then
            -- 活着,无基因
        elseif (UE.ERespawnGeneState.Drop == RespawnGeneState) then
            -- 基因未拾取
            -- if self.ProgressNotZero then
            --     TxtGeneTipsKey = "Gene_WaitPick"
            -- else
            TxtGeneTipsKey = "Gene_NotPickedup"            
            --end
            self.TxtName:SetColorAndOpacity(self.TxtNameStateColor:FindRef("Resue"))
            self.ImgAvatar:SetColorAndOpacity(self.ImgAvatarStateColor:FindRef("Resue"))
            self.TrsDying:SetVisibility(UE.ESlateVisibility.Collapsed)
        elseif (UE.ERespawnGeneState.PickingUp == RespawnGeneState) or (6 == RespawnGeneState) then
            -- 基因提取中
            TxtGeneTipsKey = "Gene_Pickingup"
            self.TrsDying:SetVisibility(UE.ESlateVisibility.Collapsed)
        elseif (UE.ERespawnGeneState.FinishPickedUp == RespawnGeneState) then
            -- 基因已被拾取
            bGenePickedup = true
            TxtGeneTipsKey = "Gene_Pickedup"
            self:ResetGeneTimeAndUi() -- 基因已经被队友拾取，那么就停止倒计时
            self.TrsDying:SetVisibility(UE.ESlateVisibility.Collapsed)
        elseif (UE.ERespawnGeneState.TimeOut == RespawnGeneState) then
            -- 基因已被删除
            -- bGenePickedup = true
            -- TxtGeneTipsKey = "Gene_Deleted"
            self:UpdateToDeadlWidget(true)
        elseif (UE.ERespawnGeneState.NoMoreRespawn == RespawnGeneState) then
            -- 无法继续复活
            -- print("TeamPlayerInfoDetail:UpdateGeneData-->基因掉落未拾取，但无法继续复活")
            self:UpdateToDeadlWidget(true)
        elseif (UE.ERespawnGeneState.UnDeployed == RespawnGeneState) then
            -- 基因未部署
            -- TxtGeneTipsKey = "Gene_NotDeployed"
            self:ResetGeneTimeAndUi() -- 基因部署被中断，隐藏倒计时
            -- 基因部署动作虽然取消，但是此时玩家的状态依然还是拾取改队友的基因，因此状态10会流转到状态3，并执行状态3的动作
            bGenePickedup = true
            TxtGeneTipsKey = "Gene_Pickedup"
        elseif (UE.ERespawnGeneState.Deploying == RespawnGeneState) then
            -- 基因部署中
            TxtGeneTipsKey = "Gene_Deploying"
            self:ResetGeneTimeAndUi() -- 基因正在部署，停止倒计时
        elseif (UE.ERespawnGeneState.FinishDeployed == RespawnGeneState) then
            -- 基因完成部署
            TxtGeneTipsKey = "Gene_DeployOk"
            self:ResetGeneTimeAndUi() -- 基因已经部署，停止倒计时
        end

        self.TxtGeneTips:SetText(G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, TxtGeneTipsKey or "") or"")
        print("TeamPlayerInfoDetail>>UpdateGeneData LocalAlive: ", LocalAlive, " bGenePickedup:", bGenePickedup)
        if LocalAlive and bGenePickedup then
            self.TrsGenePickedup:SetVisibility( not UE.UGUIManager.IsMobilePlatform() and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
            self.Panel_RebornBtn_Mobile:SetVisibility(UE.UGUIManager.IsMobilePlatform() and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        else
            self.TrsGenePickedup:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.Panel_RebornBtn_Mobile:SetVisibility(UE.ESlateVisibility.Collapsed)
        end

        if self.ProgressNotZero and RespawnGeneState ~= UE.ERespawnGeneState.FinishPickedUp then
            self.TxtGeneProgress:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        else
            self.TxtGeneProgress:SetVisibility(UE.ESlateVisibility.Collapsed)
        end

        if TxtGeneTipsKey ~= nil then
            self.TxtGeneTips:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        end
        if RespawnGeneState == UE.ERespawnGeneState.FinishPickedUp and UE.UKismetSystemLibrary.IsValid(self.BootyBox) then
            self:SetGeneIconSize(false)
        end
    else
        self.TxtGeneProgress:Setvisibility(UE.ESlateVisibility.Collapsed)
        self.TxtGeneTips:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TrsGenePickedup:SetVisibility(UE.ESlateVisibility.Collapsed)
        
    end
    print("TeamPlayerInfoDetail>>UpdateGeneData>>All Data", self.RefPS.PlayerId, self.RefPS:GetPlayerName(),
        RespawnGeneState, DeadTime, TotalTime, TimeSeconds, RemainTime, bAlive, bShowGeneTime, TxtGeneTipsKey, bGenePickedup, self.ProgressNotZero)
    print("XTDebug TeamPlayerInfoDetail", ">> UpdateGeneData, ", self.RefPS.PlayerId, self.RefPS:GetPlayerName(),
        RespawnGeneState, DeadTime, TotalTime, TimeSeconds, RemainTime, bAlive, bShowGeneTime, TxtGeneTipsKey,
        bGenePickedup)
end

function TeamPlayerInfoDetail:ResetGeneTimeAndUi()
    self.GeneTimeData = nil
    self.lastServerTime = nil
    self.TxtGeneTime:SetText("")
    self.ImgGeneTime:GetDynamicMaterial():SetScalarParameterValue("Progress", 0)
    --self.ImgBgGene:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TrsGeneTime:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.ProgressNotZero = false
end

-- 更新基因剩余时间
function TeamPlayerInfoDetail:UpdateGeneTime(InDeltaTime)
    if not self.GeneTimeData then
        return
    end

    -- 拿DS时间差算，第一次不记录
    self.curServerTime = UE.UAdvancedWorldBussinessMarkSystem.GetTimeSeconds(self)
	if self.lastServerTime == nil then
		self.lastServerTime = self.curServerTime
	end
    self.GeneTimeData.RemainTime = self.GeneTimeData.RemainTime - (self.curServerTime - self.lastServerTime)
    self.lastServerTime = self.curServerTime

    if self.GeneTimeData.RemainTime >= 0 then
        -- local TxtSeconds = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Common_Seconds")
        local NewTime = math.max(0, self.GeneTimeData.RemainTime)
        -- print("TeamPlayerInfoDetail:UpdateGeneTime-->NewTime:", NewTime)
        if NewTime ~= 0 then
            local NewTxtTime = string.format("%.f", NewTime)
            local NewProgress = self.GeneTimeData.RemainTime / self.GeneTimeData.TotalTime
            self.TxtGeneTime:SetText(NewTxtTime)
            self.ImgGeneTime:GetDynamicMaterial():SetScalarParameterValue("Progress", NewProgress)
        else
            self.TxtGeneTime:SetText("")
            self.ImgGeneTime:GetDynamicMaterial():SetScalarParameterValue("Progress", 0)
            self.ImgBgGene:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.TrsGeneTime:SetVisibility(UE.ESlateVisibility.Collapsed)
        end

    else
        self:ResetGeneTimeAndUi()
        self:ClearGeneTimerHandle()
    end

    --[[print("TeamPlayerInfoDetail", ">> UpdateGeneData, ",
        self.RefPS.PlayerId, self.RefPS:GetPlayerName(), self.GeneTimeData.RemainTime)]]
end

-------------------------------------------- Callable ------------------------------------

-- 
function TeamPlayerInfoDetail:OnUpdatePSPawn(InPS)
    if self.RefPS and (self.RefPS == InPS) then
        self:InitPlayerPawnInfo()
    end
end

-- 角色存活改变
function TeamPlayerInfoDetail:OnChangePSAlive(InPS, bIsAlive)
   
    if bIsAlive and (self.RefPS == InPS) then
        self:OnEndDying(nil)
        self:OnEndDead(nil)
    end
end

-- 玩家基因数据改变
function TeamPlayerInfoDetail:OnChangeDeadTimeSec(InPS, InDeadTimeSec)
    print("XTDebug TeamPlayerInfoDetail", ">> OnChangeDeadTimeSec[Gene], ", GetObjectName(self.RefPS), GetObjectName(InPS))
    if (InPS == self.RefPS) then
        print("TeamPlayerInfoDetail>>OnChangeDeadTimeSec>>UpdateGeneData")
        self:UpdateGeneData()
    end
end

-- 重生基因收集&部署状态改变
function TeamPlayerInfoDetail:OnChangeRespawnGeneState(InPS, InState)
    print("XTDebug TeamPlayerInfoDetail:OnChangeRespawnGeneState-->InPS:", InPS, "InState:", InState)
    if (InPS == self.RefPS) then
        print("TeamPlayerInfoDetail>>OnChangeRespawnGeneState>>UpdateGeneData")
        self:UpdateGeneData()

        -- --接动效
        -- if InState == UE.ERespawnGeneState.PickingUp then
        --     self:VXE_HUD_Team_Gene_In()
        -- elseif InState == UE.ERespawnGeneState.FinishPickedUp then
        --     self:VXE_HUD_Team_GenePick_Out()
        -- elseif InState == UE.ERespawnGeneState.Deploying then
        --     self:VXE_HUD_Team_GenePick_In()
        -- elseif InState == UE.ERespawnGeneState.FinishDeployed then
        --     self:VXE_HUD_Team_GenePick_Out()
        --     self:VXE_HUD_Team_GenePick_Success()
        -- end
    end
end

function TeamPlayerInfoDetail:IsOpenFire(IsOpenFire)
    
    if IsOpenFire ==true then
         self.ImgOnFire:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        --self:SimplePlayAnimationByName("vx_fire")
        self:PlayAnimationByName("vx_fire",0,0)
    else
       self:StopAnimationByName("vx_fire") 
       self.ImgOnFire:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

-- 更新标记数据
function TeamPlayerInfoDetail:OnUpdateMarkData(InMarkSystemDataSet)
    -- print("TeamPlayerInfoDetail", ">> OnUpdateMarkData, ", GetObjectName(InMarkSystemDataSet))

    if self:GetWorld() == InMarkSystemDataSet:GetWorld() then
        self:UpdateTeamMarkItem(InMarkSystemDataSet:GetPlayerState(), InMarkSystemDataSet)
    end
end

-- 角色背包数据更新
function TeamPlayerInfoDetail:OnUpdateItemFeatureSet(InItemSlotFeatureSet, InItemSlotFeatureSetOuter)
    print("TeamPlayerInfoDetail", ">> OnUpdateItemFeatureSet, ...", GetObjectName(InItemSlotFeatureSet), GetObjectName(InItemSlotFeatureSetOuter))

    if (InItemSlotFeatureSet:GetOuterActor() == self.RefPS) then
        --self:UpdateArmorInfo()
    end
end



function TeamPlayerInfoDetail:OnBeginDead(InDeadMessageInfo)
    print("TeamPlayerInfoDetail", ">> OnBeginDead, ")

    self:UpdateDeadState(true)
end

--[[
function TeamPlayerInfoDetail:OnBeginDying(InDyingMessageInfo)
    print("TeamPlayerInfoDetail", ">> OnBeginDying, ", InDyingMessageInfo.DyingInfo)

    self.bIsDying = InDyingMessageInfo.DyingInfo.bIsDying
    self:UpdateDyingState({
        DyingInfo = InDyingMessageInfo.DyingInfo
    })
end
]]--
function TeamPlayerInfoDetail:UpdateDyingInfo(InDyingInfo)
    --print("TeamPlayerInfoDetail", ">> UpdateDyingInfo, ", InDyingInfo.bIsDying,InDyingInfo.DeadCountdownRemainTime,self.RefPS.PlayerId)
    if self.bIsDying~=InDyingInfo.bIsDying  then
        if InDyingInfo.bIsDying == true then
            print("TeamPlayerInfoDetail>>UpdateDyingInfo>>Enter bIsDying", InDyingInfo.bIsDying)
            if self.MyDataVM and self.VXDyingDownHealth then
                self.VXDyingDownHealth = self.MyDataVM.HealthInfo.CurrentHealth / self.MyDataVM.HealthInfo.MaxHealth
                self:VXE_HUD_DyingHealth()
            end
            self:VXE_HUD_Team_Down_In()
            self:ResetRecoveryValue()
        else
            print("TeamPlayerInfoDetail>>UpdateDyingInfo>>Exit Dying", InDyingInfo.bIsDying)
            self:VXE_HUD_Team_Down_Out()
            --self.PreviewPercent=0
            -- self:PreviewTreat(true,0)
            -- self:SetHealthInfo(0,100)
            -- self:PreviewTreat(false,0)
            -- local CurHealth, MaxHealth, bIsValid = UE.UPlayerStatics.GetHealthData(self.RefPS)
            -- self:SetHealthInfo(CurHealth, MaxHealth)
        end
        
    end
    self.bIsDying = InDyingInfo.bIsDying
   
    self:UpdateDyingState({
        DyingInfo = InDyingInfo
    })
    
end

function TeamPlayerInfoDetail:UpdateDeadInfo(InDeadInfo)
    print("TeamPlayerInfoDetail>>UpdateDeadInfo>>bIsDead", InDeadInfo.bIsDead)
    self.IsDead = InDeadInfo.bIsDead
    self:UpdateDeadState(InDeadInfo.bIsDead)
    if InDeadInfo.bIsDead == true then
        self:ResetRecoveryValue()
        local PlayerExSubsystem =  UE.UPlayerExSubsystem.Get(self)
        
        if PlayerExSubsystem and PlayerExSubsystem:IsPlayerHasGameplayTag(self.RefPS,UE.UGUVGameplayTags.Get().PlayerExTag_OutOfGame) and self:HasActiveWidgetStyleFlags(2) == true then
            self:RemoveActiveWidgetStyleFlags(2)
        end
    end
end

function TeamPlayerInfoDetail:UpdateRescueMeInfo(InRescueMeInfo)
    if InRescueMeInfo.EndReason == UE.ES1RescueEndReason.RescueBreakOff or InRescueMeInfo.EndReason == UE.ES1RescueEndReason.Cancelled  then
        --print("TeamPlayerInfoDetail>>UpdateRescueMeInfo>>RescueCompleted>>self.bIsRescueMeCompleted: ", self.bIsRescueMeCompleted)
        self:VXE_HUD_Team_Revive_Out()
        self.IsRescueMe = false
    end

    
    if self.IsRescueMe == true and self.IsRescueMe ~= InRescueMeInfo.bIsBeRescued then
        --print("TeamPlayerInfoDetail>>UpdateRescueMeInfo>>RescueCompleted>>self.bIsRescueMeCompleted: ", self.bIsRescueMeCompleted)
        self.bIsRescueMeCompleted = true
        self:VXE_HUD_Team_ReviveSuccess()
    end

    self.IsRescueMe = InRescueMeInfo.bIsBeRescued
end

function TeamPlayerInfoDetail:UpdateSkillStatus(VM, fieldID)
    local InSkillStatus = VM:GetSkillStatus()
    print("LogHudNetData TeamPlayerInfoDetail", ">> UpdateSkillStatus, ", InSkillStatus)
    if  InSkillStatus == UE.EGeSkillStatus.Normal  then
        --print("TeamPlayerInfoDetail", ">> UpdateSkillStatus1, ", InSkillStatus)
        self.TrsPlayerSkill:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
       -- print("TeamPlayerInfoDetail", ">> UpdateSkillStatus2, ", InSkillStatus)
        self.TrsPlayerSkill:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    
end

function TeamPlayerInfoDetail:OnEndDead(InDeadMessageInfo)
    print("TeamPlayerInfoDetail", ">> OnEndDead, ")

    self:UpdateDeadState(false)
end

function TeamPlayerInfoDetail:OnEndDying(InDyingMessageInfo)
    print("TeamPlayerInfoDetail", ">> OnEndDying, ")

    local DyingInfo = UE.FS1LifetimeDyingInfo()
    DyingInfo.bIsDying = false
    DyingInfo.DyingCounter = 0
    DyingInfo.DeadCountdownTime = 0
    self.bIsDying = DyingInfo.bIsDying
    self:UpdateDyingState({
        DyingInfo = DyingInfo
    })
end






function TeamPlayerInfoDetail:OnUpdateDeadCountdown(InTotalTime, InRemianTime)
   -- print("TeamPlayerInfoDetail", ">> OnUpdateDeadCountdown, ", InTotalTime, InRemianTime)

    if self.bIsDying then
        self.TotalDyingTime = InTotalTime
        self.RemianDyingTime = InRemianTime
        self:UpdateDyingTime(0)
    end
end

-- -- InRespawnTime这个参数已经被还成基因持续时间了
-- function TeamPlayerInfoDetail:OnBeginRespawn(InPlayerState, InRespawnTime)
--     self.BeginRespawn = true
--     self.TargetPlayerState = InPlayerState
--     local NewRespawnTime = math.max(12, InRespawnTime)
--     self.RespawnTotalTime = NewRespawnTime
--     self.CurRespawnRemainTime = NewRespawnTime
--     print("TeamPlayerInfoDetail", ">> OnBeginRespawn, ...InRespawnTime:", InRespawnTime, "NewRespawnTime:", NewRespawnTime)
--     self.TxtDyingTime:SetText(math.floor(NewRespawnTime))
--     local NewPercent = (NewRespawnTime > 0) and 1 or 0
--     self.ImgDyingProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", NewPercent)
--     self.ImgDyingProgress:SetColorAndOpacity(self.RespawnColor)
--     --self.TrsDying:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
-- end




function TeamPlayerInfoDetail:OnGeneProgressChange(InBootyBox, InCurrentProgress)
    print("TeamPlayerInfoDetail", ">> OnChangePlayerInfo, [DebugRespawnX] ", self.LocalPC)
    if not InBootyBox then
         return
    end
    self.BootyBox = InBootyBox
    local Per = InCurrentProgress/InBootyBox.CacheAllStageTimeSum
    local ProText = StringUtil.Format("{0}%", math.floor(Per*100))
    self.TxtGeneProgress:SetText(ProText)
    self.ProgressNotZero   = Per > 0 and Per < 1.0
    print("TeamPlayerInfoDetail>>OnGeneProgressChange>>UpdateGeneData", Per)
    self:UpdateGeneData()
end

function TeamPlayerInfoDetail:UpdateRecoveryMaxArmor(RecoveryMaxArmor)
    print("TeamPlayerInfoDetail:UpdateRecoveryMaxArmor",RecoveryMaxArmor)
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("ExpValue", 0)
    if self.MaxArmor and self.MaxArmor-RecoveryMaxArmor<=25 then
        local NewPercent = RecoveryMaxArmor/self.MaxArmor
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("ExpValue", NewPercent)
    end
    

end

function TeamPlayerInfoDetail:OnChange_PSTeamPos(InPS, InPlayerSpec)
    if self.RefPS== nil or self.RefPS~= InPS then
        print("TeamPlayerInfoDetail:OnChange_PSTeamPos self.RefPS is nil ")
        return
    end
     -- 队伍颜色信息
     local CurTeamPos = BattleUIHelper.GetTeamPos(self.RefPS)
      if CurTeamPos == 0   then
        if InPlayerSpec == nil then
            return 
        end
        CurTeamPos = InPlayerSpec.PlayerSerialNumber
      end
     print("TeamPlayerInfoDetail", ":OnChange_PSTeamPos,CurTeamPos: ", GetObjectName(self.RefPS), GetObjectName(self.LocalPC),self.LocalPC, CurTeamPos,self.RefPS.PlayerId,self.RefPS:GetPlayerName())
     local ImgColor = MinimapHelper.GetTeamMemberColor(CurTeamPos)
     self.Team_Color = ImgColor
     if self.TxtNumber then
         self.TxtNumber:SetText(CurTeamPos or 1)
     end
     if self.TeamNumber then self.TeamNumber:SetText(CurTeamPos or 1) end
     if self.ImgBgNum then
         self.ImgBgNum:SetColorAndOpacity(ImgColor)
     end
     local SlateColor = UE.FSlateColor()
     SlateColor.SpecifiedColor = ImgColor
     if self.TeamNumber then self.TeamNumber:SetColorAndOpacity(SlateColor) end
     if self.ImgMark then
         self.ImgMark:SetColorAndOpacity(ImgColor)
     end
    
end

function TeamPlayerInfoDetail:OnUpdateAvatar(InHeroId)
    local PawnConfig = UE.FGePawnConfig()
    local  bIsValidData = UE.UGeGameFeatureStatics.GetPawnDataByPawnTypeID(InHeroId,PawnConfig,self)
    print("TeamPlayerInfoDetail:OnUpdateAvatar",self.RefPS.PlayerId,InHeroId,"bIsValidData",bIsValidData)
    if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.Icon) then
        self.ImgAvatar:SetBrushFromSoftTexture(PawnConfig.Icon, false)
        --设置技能图标
        self:SetSkillState(PawnConfig)
    else
        print("TeamPlayerInfoDetail:OnUpdateAvatar PawnConfig.Icon is not Valid ")
    end
end


function TeamPlayerInfoDetail:OnChange_RespawnXRule(InTagContainer)
    print("TeamPlayerInfoDetail>>OnChange_RespawnXRule>>UpdateGeneData")
    self:UpdateGeneData()
end


function TeamPlayerInfoDetail:OnUpdateDisConnectStatus(InIsLostConnection)
    print("TeamPlayerInfoDetail:OnUpdateDisConnectStatus InIsLostConnection",InIsLostConnection,self.RefPS.PlayerId)
    if InIsLostConnection == true then
        --self:AddActiveWidgetStyleFlags(1)
        self:VXE_HUD_Team_Offline()
    else
        --self:RemoveActiveWidgetStyleFlags(1)
        self:VXE_HUD_Team_Online()
    end
end

function TeamPlayerInfoDetail:OnUpDateReSpawnRules()
    
end

function TeamPlayerInfoDetail:OnParachuteRespawnStart(bParachuteRespawnStart,ParachuteRespawnCDTime,AvailableChance, ActiveTime,InContext)
    print("TeamPlayerInfoDetail:OnParachuteRespawnStart",bParachuteRespawnStart,self.RefPS:GetPlayerName())
    --true 表示打开选点地图， false 表示关闭选点地图
    if bParachuteRespawnStart == true then
        self:AddActiveWidgetStyleFlags(2)
    else
        self:RemoveActiveWidgetStyleFlags(2)
        --选点阶段返回大厅，移除WidgetStyle会把原本死亡隐藏的UI显示出来，暂时先再次判断隐藏
        self:UpdateGeneData()
    end
end

function TeamPlayerInfoDetail:OnParachuteRespawnFinished(bParachuteRespawnFinished)
    print("TeamPlayerInfoDetail:OnParachuteRespawnFinished",bParachuteRespawnFinished)
    --true 表示切换到复活塔视角， false 表示复活成功开始跳伞
    --所以无论true还是false都要移除该面板
    self:RemoveActiveWidgetStyleFlags(2)
    
end

function TeamPlayerInfoDetail:CheckRules()
    self:OnParachuteRespawnStart(RespawnSystemHelper.CheckIsBeginRespawner(self.RefPS))

end

--本地重连之后都会走这
--重连之后需要刷新血量和护甲，倒地之类的状态应该是根据rep刷新
function  TeamPlayerInfoDetail:OnUpdataReConnect()
    print("TeamPlayerInfoDetail:OnUpdataReConnect",self.RefPS.PlayerId)
    if self.MyDataVM then
        self:SetHealthInfo(self.MyDataVM.HealthInfo, self.MyDataVM.HealthInfo)
        self:SetArmorData(self.MyDataVM, nil)
    end
end

function TeamPlayerInfoDetail:OnRuleFinishedParachuteRespawn()
    --self:RemoveActiveWidgetStyleFlags(2)
end

function TeamPlayerInfoDetail:SetArmorData(vm, fieldID)
    if vm.ArmorInfo.IsShowArmor then
        self.SizeBox_BarArmor:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self:SetArmorProcessBarInfo(vm.ArmorInfo.CurrentArmorValue, vm.ArmorInfo.MaxArmorValue, vm.ArmorInfo.ArmorId)
    else
        self.SizeBox_BarArmor:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.ExpValue, 0)
    end
end

function TeamPlayerInfoDetail:SetPreviewHealth(vm, fieldID)
    print("TeamPlayerInfoDetail>>SetPreviewHealth:", vm.PreviewHealth)
    if vm.PreviewHealth > 0 then
        local RecoveryPercent = (vm.HealthInfo.MaxHealth > 0) and vm.PreviewHealth / vm.HealthInfo.MaxHealth or 0
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastOpacity, 1)
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastProgress, RecoveryPercent)
    else
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastOpacity, 0)
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastProgress, 0)
    end
end

function TeamPlayerInfoDetail:SetSlowlyRecoveryHealth(vm, fieldID)
    print("TeamPlayerInfoDetail>>SetSlowlyRecoveryHealth:", vm.SlowlyRecoveryHealth)
    if vm.SlowlyRecoveryHealth > 0 then
        local RecoveryPercent = (vm.HealthInfo.MaxHealth > 0) and vm.SlowlyRecoveryHealth / vm.HealthInfo.MaxHealth or 0
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.Healback, 1)
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.BackProgress, RecoveryPercent)
    else
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.Healback, 0)
        self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.BackProgress, 0)
    end
end

function TeamPlayerInfoDetail:SetPreviewArmorValue(vm, fieldID)
    print("TeamPlayerInfoDetail>>SetPreviewArmorValue:", vm.PreviewArmorValue)
    if vm.PreviewArmorValue > 0 then
        local Percent = (vm.ArmorInfo.MaxArmorValue > 0) and vm.PreviewArmorValue / vm.ArmorInfo.MaxArmorValue or 0
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.ExpValue, Percent)
    else
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.ExpValue, 0)
    end
end

function TeamPlayerInfoDetail:SetSlowlyRecoveryMaxArmor(vm, fieldID)
    print("TeamPlayerInfoDetail>>SetSlowlyRecoveryMaxArmor:", vm.SlowlyRecoveryMaxArmor)
    if vm.SlowlyRecoveryMaxArmor > 0 then
        local Percent = (vm.ArmorInfo.MaxArmorValue > 0) and vm.SlowlyRecoveryMaxArmor / vm.ArmorInfo.MaxArmorValue or 0
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.SlowProgress, Percent)
    else
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.SlowProgress, 0)
    end
end

function TeamPlayerInfoDetail:ResetRecoveryValue()
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastOpacity, 0)
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.HealFastProgress, 0)
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.Healback, 0)
    self.VX_BarHealth:GetDynamicMaterial():SetScalarParameterValue(VXHealthBarParam.BackProgress, 0)
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.ExpValue, 0)
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue(ArmorMaterialProperty.SlowProgress, 0)
end

return TeamPlayerInfoDetail
