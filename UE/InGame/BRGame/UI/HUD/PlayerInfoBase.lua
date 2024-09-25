--此为个人面板的基类，为PC和mobile的个人面板服务
--根据策划的要求，PC和mobile的数值逻辑要保持一致
--PC和mobile的表现逻辑要有差异
--因此思路总体为：数值逻辑写在基类，不太可能出现变化的表现逻辑写在父类，特殊的表现写在各自的子类
--如果以后有很多差异的变化，就分别在两个平台写各自表现

local PlayerInfoBase = Class("Common.Framework.UserWidget")
local DefaultSlotId = 1


function PlayerInfoBase:OnInit()
    print("PlayerInfoBase:OnInit", GetObjectName(self))
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    print("PlayerInfoBase", ">> OnInit, ", GetObjectName(self), GetObjectName(self.LocalPC), self.LocalPC)
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerPawn,      Func = self.OnLocalPCUpdatePawn,      bCppMsg = true, WatchedObject =self.LocalPC },
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState,     Func = self.OnUpdateLocalPCPS,        bCppMsg = true, WatchedObject =self.LocalPC },   
        { MsgName = GameDefine.Msg.PLAYER_ItemSlots,            Func = self.OnItemSlotsChange,        bCppMsg = true, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.UISync_UpdateMarkData,    Func = self.OnUpdateMarkData,       bCppMsg = true, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.BAG_FeatureSetUpdate,     Func = self.OnUpdateItemFeatureSet,   bCppMsg = true, WatchedObject = nil },
    }
    MsgHelper:RegisterList(self, self.MsgList)
    self.ArmorValue = self.SizeBox_BarArmor.WidthOverride
    UserWidget.OnInit(self)
    
    self:InitBaseData()

end

function PlayerInfoBase:OnDestroy()
    print("PlayerInfoBase:OnDestroy")
    
    UserWidget.OnDestroy(self)

end


function PlayerInfoBase:InitBaseData()
    print("PlayerInfoBase:InitBaseData")
    -- 初始化濒死颜色
    self.DyingColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", "Red")
     -- 健康值
     self.PreviewRate = self.PreviewRate or 0.25
     
     print("PlayerInfoBase >> InitBaseData > self.bPreviewTreat:", self.bPreviewTreat)
     self.PreviewPercent = 0
    self.bPreviewTreat = false
     self.PreviewTreatValue = 0
     -- 背包负重警告
     self.WeightPercentWarnValue = 90

     self.TxtName:SetText('')
     --初始化子类各自的差异化表现，该函数在子类实现
     self:InitSelfBaseData()

     self:InitBasePlayerStateInfo()
     self:InitBasePlayerPawnInfo()
     self:UpdateArmorInfo()
end

function PlayerInfoBase:InitBasePlayerStateInfo()
    print("PlayerInfoBase:InitPlayerStateInfo")
    local LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
    print("PlayerInfoBase", ">> InitPlayerStateInfo0, ", GetObjectName(LocalPS), GetObjectName(self.LocalPC), self.LocalPC)
    if LocalPS then
        local PlayerName =  LocalPS:GetPlayerName()
        print("PlayerInfoBase", ">> InitPlayerStateInfo1, ", GetObjectName(LocalPS), GetObjectName(self.LocalPC), self.LocalPC,PlayerName,LocalPS:GetPlayerId())
        local CurHealth, MaxHealth, bIsValid = UE.UPlayerStatics.GetHealthData(LocalPS)
        self:SetHealthInfoBase(CurHealth, MaxHealth)
        self.TxtName:SetText(PlayerName)
        self:UpdateArmorInfo()
        MsgHelper:UnregisterList(self, self.MsgList_PS or {})
        self.MsgList_PS = {
            { MsgName = GameDefine.MsgCpp.PLAYER_PSHealth,           Func = self.SetHealthInfoBase,      bCppMsg = true, WatchedObject =LocalPS },
            { MsgName = GameDefine.MsgCpp.PLAYER_PSAlive,            Func = self.OnChangePSAlive,        bCppMsg = true, WatchedObject =LocalPS },
            { MsgName = GameDefine.MsgCpp.PLAYER_OnBeginRespawn,     Func = self.OnBeginRespawn,         bCppMsg = true,WatchedObject =LocalPS },
            { MsgName = GameDefine.MsgCpp.PLAYER_OnEndRespawn,       Func = self.OnEndRespawn,           bCppMsg = true, WatchedObject =LocalPS },
            { MsgName = GameDefine.MsgCpp.UISync_UpdateOnBeginDying, Func = self.UpdateDyingInfo,        bCppMsg = true, WatchedObject =LocalPS },
            { MsgName = GameDefine.MsgCpp.UISync_UpdateOnDead,       Func = self.UpdateDeadInfo,         bCppMsg = true,WatchedObject =LocalPS },
            { MsgName = GameDefine.MsgCpp.UISync_UpdateOnRescueMe,   Func = self.UpdateRescueMeInfo,     bCppMsg = true,WatchedObject =LocalPS },
            { MsgName = GameDefine.MsgCpp.PLAYER_PSTeamPos,          Func = self.OnChange_PSTeamPos,     bCppMsg = true,WatchedObject =nil }
        }
        MsgHelper:RegisterList(self, self.MsgList_PS)
        --子类各自表现
        self:InitPlayerStateInfo()
    end
end

function PlayerInfoBase:InitBasePlayerPawnInfo()
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
    print("PlayerInfoBase", ">> InitPlayerPawnInfo, ", GetObjectName(self), GetObjectName(LocalPCPawn))
    if LocalPCPawn then
        -- 设置玩家基础数据
        local PawnConfig, bIsValidData = UE.UGeGameFeatureStatics.GetPawnData(LocalPCPawn)
        if UE.UKismetSystemLibrary.IsValidSoftObjectReference(PawnConfig.Icon) then
            --local SlateBrushAsset = UE.UKismetSystemLibrary.LoadAsset_Blocking(PawnConfig.Icon)
            --self.ImgAvatar:SetBrushFromAsset(SlateBrushAsset)
            self.ImgAvatar:SetBrushFromSoftTexture(PawnConfig.Icon, false)
        end

        -- 重置玩家状态
        self:CheckDying()

        -- 监听对象消息
        MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})
        self.MsgList_Pawn = {
           -- { MsgName = UE.UGFGameTags.Get().ASCUpdateTag,             Func = self.OnGameplayTagEvent,      bCppMsg = true,WatchedObject =LocalPCPawn },
            --{ MsgName = GameDefine.NTag.CHARACTER_GunFire,             Func = self.OnGameplayTagEvent_Fire, bCppMsg = true,WatchedObject =LocalPCPawn },
            -- 濒死/救援
            --{ MsgName = GameDefine.MsgCpp.PLAYER_OnBeginBeingRescue,   Func = self.OnBeginBeingRescue,      bCppMsg = true,WatchedObject =LocalPCPawn },
            --{ MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDead,           Func = self.OnBeginDead,            bCppMsg = true, WatchedObject = LocalPCPawn },
            --{ MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDying,          Func = self.OnBeginDying,           bCppMsg = true, WatchedObject = LocalPCPawn },
            --{ MsgName = GameDefine.MsgCpp.PLAYER_OnEndBeingRescue,     Func = self.OnEndBeingRescue,        bCppMsg = true,WatchedObject =LocalPCPawn },
            --{ MsgName = GameDefine.MsgCpp.PLAYER_OnEndDead,             Func = self.OnEndDead,              bCppMsg = true, WatchedObject = LocalPCPawn },
            --{ MsgName = GameDefine.MsgCpp.PLAYER_OnEndDying,            Func = self.OnEndDying,             bCppMsg = true, WatchedObject = LocalPCPawn },
            --{ MsgName = GameDefine.MsgCpp.PLAYER_OnBeginRescue,        Func = self.OnBeginRescue,           bCppMsg = true, WatchedObject =LocalPCPawn },
            --{ MsgName = GameDefine.MsgCpp.PLAYER_OnEndRescue,          Func = self.OnEndRescue,             bCppMsg = true,WatchedObject =LocalPCPawn },
            { MsgName = GameDefine.MsgCpp.PLAYER_OnRescueActorChanged, Func = self.OnRescueActorChanged,    bCppMsg = true,WatchedObject =LocalPCPawn },
            { MsgName = GameDefine.MsgCpp.PLAYER_UpdateDeadCountdown,  Func = self.OnUpdateDeadCountdown,   bCppMsg = true,WatchedObject =LocalPCPawn },
        }
        MsgHelper:RegisterList(self, self.MsgList_Pawn)
    end
end



function PlayerInfoBase:OnLocalPCUpdatePawn(InLocalPC, InPCPwn)
    print("PlayerInfoBase", ">> OnLocalPCUpdatePawn, ",GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InPCPwn))
    if self.LocalPC == InLocalPC then
        self:InitBasePlayerPawnInfo()
    end
end

-- 本地更新PS/Pawn
function PlayerInfoBase:OnUpdateLocalPCPS(InLocalPC, InOldPS, InNewPS)
    print("PlayerInfoBase", ">> OnUpdateLocalPCPS, ",
        GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS))
    if InNewPS then
        print("PlayerInfoBase", ">> OnUpdateLocalPCPS, ",
            GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS), InNewPS:GetPlayerName())
    end
    if self.LocalPC == InLocalPC then
        self:InitBasePlayerStateInfo()
    end
end

function PlayerInfoBase:SetHealthInfoBase(InCurHp,InMaxHp)
    print("PlayerInfoBase", ">> SetHealthInfo, ", InCurHp,InMaxHp)
    --表现函数，子类实现
    self:SetHealthInfo(InCurHp,InMaxHp)
    
end


-- 护甲数值信息
function PlayerInfoBase:SetArmorProcessBarInfo(InCurArmor, InMaxArmor, InArmorItemId)
    print("PlayerInfo", ">> SetArmorProcessBarInfo, ", InCurArmor, InMaxArmor)

    InCurArmor = InCurArmor or 0
    InMaxArmor = InMaxArmor or 0
    local NewPercent = (InCurArmor > 0) and (InCurArmor / InMaxArmor) or 0

    --用材质之后修改参数实现
    self.MaxArmor = InMaxArmor
    if InCurArmor == InMaxArmor then
        self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("ExpValue", 0)
    end
    
    self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("Value", NewPercent)
   
    local NewTxt = math.floor(InCurArmor) .. "/" .. math.floor(InMaxArmor)
    self.BarArmor:SetToolTipText(NewTxt)

    --这里开始使用MiscSystem的颜色
    local MiscSystem = UE.UMiscSystem.GetMiscSystem(self)
    local ArmorLvAttributes = MiscSystem.BarArmorAttributes
    self.SizeBox_BarArmor.WidthOverride = self.ArmorValue

    BattleUIHelper.SetArmorShieldLvInfo(InArmorItemId, self.BarArmor, ArmorLvAttributes, self.SizeBox_BarArmor)
end

function PlayerInfoBase:OnUpdateItemFeatureSet(InItemSlotFeatureSet, InItemSlotFeatureSetOuter)
    print("PlayerInfoBase", ">> OnUpdateItemFeatureSet, ",
        GetObjectName(self.LocalPC), GetObjectName(InItemSlotFeatureSet), GetObjectName(InItemSlotFeatureSetOuter))
    if self.LocalPC == nil then
        Error("self.LocalPC nil")
        return
    end
    if (InItemSlotFeatureSet:GetOuterActor() == self.LocalPC.PlayerState) then
        self:UpdateArmorInfo()
    end
end

function PlayerInfoBase:UpdateArmorInfo()
    local IsShowArmor = false

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
			self.:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
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
        end
        ]]--
    else
        self.TrsArmorValue:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    
end

function PlayerInfoBase:UpdateDyingInfo(InDyingInfo)
    --print("PlayerInfo", ">> UpdateDyingInfo, ", InDyingInfo.bIsDying,InDyingInfo.DeadCountdownRemainTime)
    self.bIsDying = InDyingInfo.bIsDying
    self:UpdateDyingState({
        DyingInfo = InDyingInfo
    })
end

function PlayerInfoBase:UpdateDyingState(InParamters)
    --print("PlayerInfo", ">> UpdateDyingState, ", InParamters.DyingInfo.bIsDying,InParamters.DyingInfo.DeadCountdownRemainTime)

    local NewColorKey = InParamters.DyingInfo.bIsDying and "Red" or "White"
    local NewColor = BattleUIHelper.GetMiscSystemValue(self, "HealthColors", NewColorKey)
    self:SetBarHealthColor(NewColor)
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
        self.ImgDyingProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", NewPercent)
        --只改变进度条不改变背景颜色
        self.ImgDyingProgress:GetDynamicMaterial():SetVectorParameterValue("ProgressColor1", self.DyingColor)
    --self.ImgDyingProgress:SetColorAndOpacity(self.DyingColor)

    if InParamters.DyingInfo.bIsDying then
        self:PlayAnimationByName("Anim_Dying", 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
        self.TotalDyingTime = InParamters.DyingInfo.DeadCountdownTime
        self.RemianDyingTime = InParamters.DyingInfo.DeadCountdownRemainTime
        self:UpdateDyingTime(0)
    else
        self:StopAnimationByName("Anim_Dying")
        self.ImgAvatar:SetOpacity(1)
    end

end

-- 更新濒死时间
function PlayerInfoBase:UpdateDyingTime(InDeltaTime)
    if self.RemianDyingTime and (self.RemianDyingTime >= 0) and (self.TotalDyingTime > 0) then
        self.RemianDyingTime = self.RemianDyingTime - InDeltaTime
        local ShowDyingTime = math.max(0, self.RemianDyingTime)
        self.TxtDyingTime:SetText(math.floor(ShowDyingTime))
        local NewPercent = ShowDyingTime / self.TotalDyingTime
        self.ImgDyingProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", NewPercent)
        self.ImgDyingProgress:GetDynamicMaterial():SetVectorParameterValue("ProgressColor1", self.DyingColor)
    end
end

-- 检测玩家是否倒地/死亡
function PlayerInfoBase:CheckDying()
    local LocalPS = self.LocalPC and self.LocalPC.PlayerState or nil
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
    local DyingInfo = LocalPCPawn:GetDyingInfo()
    print("PlayerInfoBase:CheckDying", DyingInfo.bIsDying)
    if (LocalPS) then
        self:UpdateDyingInfo(DyingInfo)
    end
end

return PlayerInfoBase