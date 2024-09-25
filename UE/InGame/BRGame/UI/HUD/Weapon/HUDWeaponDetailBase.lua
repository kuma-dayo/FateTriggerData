--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--
require "UnLua"
--if GameLog then GameLog.AddToBlackList("HUDWeaponDetailBase") end

require "Common.Framework.UIHelper"

local HUDWeaponDetailBase = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

HUDWeaponDetailBase.FireModeIcons = {
    Auto = { Level = 1, Tag = "Weapon.Attribute.FireMode.Auto" },
    Burst = { Level = 2, Tag = "Weapon.Attribute.FireMode.Burst" }
}

function HUDWeaponDetailBase:OnInit()
    print("HUDWeaponDetailBase", ">> OnInit, ", GetObjectName(self))

    self.bIsActive = false

    self.MsgList = {}

    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempLocalPC then
        table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerPawn, Func = self.OnUpdatePawn, bCppMsg = true, WatchedObject = TempLocalPC })
        table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnDestroy, Func = self.OnInventoryDestroy, bCppMsg = true})
        --table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.CHARACTER_Gun_BloodBullet_OnTagEvent, Func = self.OnBloodBulletEvent, bCppMsg = true }) --浸血触发，暂时不用
        --table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.WEAPON_Functionality_TolBullet_OnEnableDisable, Func = self.OnTolBulletEvent, bCppMsg = true })--容错触发，暂时不用
        -- table.insert(self.MsgList, { MsgName = GameDefine.MsgCpp.WEAPON_InventoryItem_CreateEnhance, Func = self.OnnventoryItemCreateEnhance, bCppMsg = true })

    end
    --MsgHelper:RegisterList(self, self.MsgList)

    self:UnBindWeaponAvatarAttachSucceed()
    self:BindWeaponAvatarAttachSucceed()

    --需要引用外面的HUDWeaponSwitcher，因为管理当前显示的芯片动画id在外面的HUDWeaponSwitcher里面，这个Id只有一个
    self.HUDWeaponSwitcherBase = nil

    UserWidget.OnInit(self)

    --具有动画效果的芯片
    self.HasAnimChipTable = {"311200000","311140000","311210000"}

    self.bIsCurrentChipAnimActive = false--效果是否触发
    self.HasBloodBulletEventTag = nil--过载
    self.TolBulletEventState = nil--容错

    self.CurrentActiveChipId = nil

    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)



end

function HUDWeaponDetailBase:OnDestroy()
    print("HUDWeaponDetailBase", ">> OnDestroy, ", GetObjectName(self))
    self:UnBindWeaponAvatarAttachSucceed()
    UserWidget.OnDestroy(self)
end

-------------------------------------------- Function ------------------------------------

function HUDWeaponDetailBase:InitData(InMainWidget, InSlotIndex, WeaponInfo)
    assert(InMainWidget and InSlotIndex, ">> InMainWidget is invalid!!!")


    -- 武器插槽Index
    self.SlotIndex  = InSlotIndex
    -- 父Widget的引用
    self.MainWidget = InMainWidget

    self.BulletWarningNum = 0

end


-- function HUDWeaponDetailBase:InitAttachments() --Virtual Funciton
-- end

function HUDWeaponDetailBase:IsValidWeaponSlotData()
    if self.WeaponSlotData then
        return self.WeaponSlotData.InventoryIdentity.ItemID ~= 0
    end
    return false
end

function HUDWeaponDetailBase:GetCurrentInventoryIdentity()
    if self:IsValidWeaponSlotData() then
        return self.WeaponSlotData.InventoryIdentity
    end
    return nil
end



function HUDWeaponDetailBase:OnAttachmentStateChange(InGAWAttachmentStateChangeGMPData)

    local TmpProfile = require("Common.Utils.InsightProfile")
    TmpProfile.Begin("HUDWeaponDetailBase:OnAttachmentStateChange")

    if not InGAWAttachmentStateChangeGMPData then return end
    if not self.GAWeaponInstance then return end
    if self.GAWeaponInstance == InGAWAttachmentStateChangeGMPData.WeaponInstance then
        self:UpdateAttachmentInfoByGMPData(InGAWAttachmentStateChangeGMPData)
    end
    TmpProfile.End("HUDWeaponDetailBase:OnAttachmentStateChange")
end



function HUDWeaponDetailBase:BindWAttachmentGMP(GAWInstance)
    if not self.Key_GAW_OnAttachmentStateChange then
        self.Key_GAW_OnAttachmentStateChange = ListenObjectMessage(nil,
            GameDefine.MsgCpp.WEAPON_GAW_AttachmentStateChange, self, self.OnAttachmentStateChange)
    end

    if not self.Key_GAW_AttachmentEffectOnPostAttached then
        self.Key_GAW_AttachmentEffectOnPostAttached = ListenObjectMessage(nil,
        GameDefine.MsgCpp.WEAPON_GWSAttachmentEffectOnPostAttached, self, self.OnInventoryItemCreateEnhance)
    end

    if not self.Key_GAW_AttachmentEffectOnPostDetached then
        self.Key_GAW_AttachmentEffectOnPostDetached = ListenObjectMessage(nil,
        GameDefine.MsgCpp.WEAPON_GWSAttachmentEffectOnPostDetached, self, self.OnInventoryItemCreateEnhance)
    end
end

function HUDWeaponDetailBase:UnBindWAttachmentGMP()
    if self.Key_GAW_OnAttachmentStateChange then
        UnListenObjectMessage(GameDefine.MsgCpp.WEAPON_GAW_AttachmentStateChange, self,
            self.Key_GAW_OnAttachmentStateChange)
        self.Key_GAW_OnAttachmentStateChange = nil
    end

    if  self.Key_GAW_AttachmentEffectOnPostAttached then
        UnListenObjectMessage(GameDefine.MsgCpp.WEAPON_GWSAttachmentEffectOnPostAttached, self,
            self.Key_GAW_AttachmentEffectOnPostAttached)
        self.Key_GAW_AttachmentEffectOnPostAttached = nil
    end

    if  self.Key_GAW_AttachmentEffectOnPostDetached then
        UnListenObjectMessage(GameDefine.MsgCpp.WEAPON_GWSAttachmentEffectOnPostDetached, self,
            self.Key_GAW_AttachmentEffectOnPostDetached)
        self.Key_GAW_AttachmentEffectOnPostDetached = nil
    end
end

function HUDWeaponDetailBase:BindGMP()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not PlayerController then return end
    if not self.GMPHandle_InventoryItemNumChangeTotal then
        -- 因为只有主端有，所以可以监听全局
        self.GMPHandle_InventoryItemNumChangeTotal = ListenObjectMessage(nil, GameDefine.Msg.InventoryItemNumChangeTotal,
            self, self.OnInventoryItemNumChangeTotal)
    end

    if not self.GMPHandle_FireBurst then
        local TempPawn = PlayerController:K2_GetPawn()
        if TempPawn then
            self.GMPHandle_FireBurst = ListenObjectMessage(TempPawn, GameDefine.MsgCpp.Character_Gun_Fire_Burst_OnTagEvent, self, self.OnFireBurst)
        end
    end

    if not self.GMPHandle_WeaponMagUpdate then
        self.GMPHandle_WeaponMagUpdate = ListenObjectMessage(nil, GameDefine.MsgCpp.WEAPON_WeaponMagUpdate, self,
            self.OnWeaponMagUpdate)
    end
end

function HUDWeaponDetailBase:UnBindGMP()
    if self.GMPHandle_InventoryItemNumChangeTotal then
        UnListenObjectMessage(GameDefine.Msg.InventoryItemNumChangeTotal, self,
            self.GMPHandle_InventoryItemNumChangeTotal)
        self.GMPHandle_InventoryItemNumChangeTotal = nil
    end

    if self.GMPHandle_FireBurst then
        UnListenObjectMessage(GameDefine.MsgCpp.Character_Gun_Fire_Burst_OnTagEvent, self, self.GMPHandle_FireBurst)
        self.GMPHandle_FireBurst = nil
    end

    if not self.GMPHandle_WeaponMagUpdate then
        UnListenObjectMessage(GameDefine.MsgCpp.WEAPON_WeaponMagUpdate, self, self.GMPHandle_WeaponMagUpdate)
        self.GMPHandle_WeaponMagUpdate = nil
    end
end



function HUDWeaponDetailBase:UpdateWeaponBulletItemIcon(WeaponBulletItemID)
    local TmpProfile = require("Common.Utils.InsightProfile")
    TmpProfile.Begin("HUDWeaponDetailBase:UpdateWeaponBulletItemIcon")

    if WeaponBulletItemID then
        local ItemIcon, bValidItemIcon = UE.UItemSystemManager.GetItemDataFString(
            self, WeaponBulletItemID, "ItemIcon", GameDefine.NItemSubTable.Ingame,
            "HUDWeaponDetailBase:UpdateWeaponBulletItemIcon")
        if bValidItemIcon then
            local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(ItemIcon)
            self.ImgBulletType:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)

            -- 这个是临时代码，在蓝图中配置，后续需要策划配表  WangZeping
            -- local BulletTypeImgPath  = self.BulletTypeImgMap:Find(WeaponBulletItemID)

            -- self.ImgIconBg:SetBrushFromSoftTexture(BulletTypeImgPath, false)
            --self.BulletColorStr = self.BulletMaxColorMap:Find(WeaponBulletItemID) --设置子弹数量的富文本颜色
        end
    end
    TmpProfile.End("HUDWeaponDetailBase:UpdateWeaponBulletItemIcon")
end


function HUDWeaponDetailBase:SetupWeaponInfo(InWeaponSlotData)

    local testProfile = require("Common.Utils.InsightProfile")
    testProfile.Begin("HUDWeaponDetailBase:SetupWeaponInfo")

    if (not InWeaponSlotData) then return end

    self.WeaponSlotData = InWeaponSlotData
    self.TrsWeapon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:BindGMP()
    testProfile.End("HUDWeaponDetailBase:SetupWeaponInfo")
end



function HUDWeaponDetailBase:GetInfiniteAmmoFlag()
    if self.GAWeaponInstance then
        local TempIsInfiniteAmmo = self.GAWeaponInstance:IsInfiniteAmmo();
        return TempIsInfiniteAmmo
    end
    return false
end


-- 更新武器信息
-- return void
function HUDWeaponDetailBase:UpdateInnerWeaponInfo(InWeaponSlotData)
    if not InWeaponSlotData then return end

    self:SetupWeaponInfo(InWeaponSlotData)

    -- 设置子弹类型的 Icon
    self:UpdateWeaponBulletItemID(InWeaponSlotData.InventoryIdentity.ItemID)
    self:UpdateWeaponBulletWarningNum(InWeaponSlotData.InventoryIdentity.ItemID)

    -- 更新开火模式
    --self:UpdateFireMode(tPawn)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    local TempPawn = PlayerController:K2_GetPawn()
    if not TempPawn then return end
    local TempEquipmentComponent = UE.UEquipmentStatics.GetEquipmentComponent(TempPawn)
    if not TempEquipmentComponent then return end
    local TempWeaponInstance = TempEquipmentComponent:GetEquipmentInstanceByInventoryIdentity(InWeaponSlotData.InventoryIdentity)

    if TempWeaponInstance then
        self.GAWeaponInstance = TempWeaponInstance

        -- 设置武器在插槽中的图片
        self:UpdateWeaponSlotImage(self.GAWeaponInstance, InWeaponSlotData.InventoryIdentity.ItemID)

        -- 绑定
        self:BindWAttachmentGMP(TempWeaponInstance)

        -- 设置武器伤害数值
        local TempDamageValue = self:GetWeaponDamageNumber()
        self:UpdateWeaponDamageNumber(TempDamageValue)

        -- 设置武器开火模式
        local TempFireModeTag, TempFireModeTags,bResult = self:GetFireModeInfo(TempWeaponInstance)
        if bResult then
            self:UpdateFireMode(TempFireModeTag, TempFireModeTags)
        end

        local TempInfiniteFlag = self:GetInfiniteAmmoFlag()
        if TempInfiniteFlag then
            self:SetInfiniteAmmoWidget(true)
            self:SetInfiniteAmmoColor(true)
        else
            self:SetInfiniteAmmoWidget(false)
            self:SetInfiniteAmmoColor(false)

            -- 设置武器最大子弹数
            local TempMaxBulletCount = self:GetWeaponMaxMagBullet(self.CurrentWeaponBulletItemID,TempWeaponInstance)
            --self:SetMaxBulletNumTxt(TempMaxBulletCount)
            -- 设置最大子弹数的颜色（警戒值）
            self:UpdateCurrentBulletTextAndColor(TempMaxBulletCount)
        end


        -- 设置武器当前子弹数
        local TempCurrentBulletCount = self:GetWeaponCurrentBullet(TempWeaponInstance)
        self:SetCurBulletNumTxt(TempCurrentBulletCount)

        -- 更新武器配件的数据信息
        self:UpdateAttachmentInfo(false, self.bIsActive ~= InWeaponSlotData.bActive)
    else
        self:UnBindWAttachmentGMP()
        self:UpdateWeaponDamageNumber(nil)
        -- self:UpdateFireMode(nil)
        self:SetCurBulletNumTxt(nil)
        self:SetInfiniteAmmoWidget(false)
        self:SetInfiniteAmmoColor(false)
        self:UpdateCurrentBulletTextAndColor(nil)
        self:ResetAttachmentInfo()
    end

    self.bIsActive = InWeaponSlotData.bActive
    -- 通知InteractiveWeapon组件更新枪械背景图片信息
    -- print("HUDWeaponDetailBase:UpdateWeaponBulletInfo Send GameDefine.Msg.WEAPON_UpdateWeaponPanelBGPic")
    -- MsgHelper:Send(nil, GameDefine.Msg.WEAPON_UpdateWeaponPanelBGPic, {CurBulletNum = CurBulletNum, MaxBulletNum = MaxBulletNum, MinAmmoWarningNum = self.MinAmmoWarningNum})
    -- MsgHelper:Send(nil, GameDefine.Msg.WEAPON_UpdateWeaponBulletNum, {WeaponEntity = WeaponEntity, SlotID = self.SlotIndex})
end


function HUDWeaponDetailBase:UppdateMicrochipData(InWeaponSlotData)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    local TempPawn = PlayerController:K2_GetPawn()
    if not TempPawn then return end
    local TempEquipmentComponent = UE.UEquipmentStatics.GetEquipmentComponent(TempPawn)
    if not TempEquipmentComponent then return end
    local TempWeaponInstance = TempEquipmentComponent:GetEquipmentInstanceByInventoryIdentity(InWeaponSlotData.InventoryIdentity)
    if TempWeaponInstance then
        self:SendMicrochipNotify( false,self.bIsActive ~= InWeaponSlotData.bActive)
    end
    self.bIsActive = InWeaponSlotData.bActive
end

function HUDWeaponDetailBase:SendMicrochipNotify(bIsAttachChange, bIsSwitchWeapon)
    local ThebIsAttachChange = bIsAttachChange or false --配件是否改变
    local ThebIsSwitchWeapon = bIsSwitchWeapon or false --武器是否切换

    
end


function HUDWeaponDetailBase:OnWeaponMagUpdate(InGAWeaponInstance)

    local TmpProfile = require("Common.Utils.InsightProfile")
    TmpProfile.Begin("HUDWeaponDetailBase:OnWeaponMagUpdate")

    if not InGAWeaponInstance then return end
    if not self:IsValidWeaponSlotData() then return end
    local CurrentWidgetInventoryIdentity = self:GetCurrentInventoryIdentity()
    if not CurrentWidgetInventoryIdentity then return end
    local WeaponInventoryIdentity = InGAWeaponInstance:GetInventoryIdentity()
    if not WeaponInventoryIdentity then return end
    if (CurrentWidgetInventoryIdentity.ItemID == WeaponInventoryIdentity.ItemID) and (CurrentWidgetInventoryIdentity.ItemInstanceID == WeaponInventoryIdentity.ItemInstanceID) then
        -- 设置武器当前子弹数
        local TempCurrentBulletCount = self:GetWeaponCurrentBullet(InGAWeaponInstance)
        self:SetCurBulletNumTxt(TempCurrentBulletCount)
        self:UpdateWeaponBulletItemID(WeaponInventoryIdentity.ItemID)
        local MaxBulletNum = self:GetWeaponMaxMagBullet(self.CurrentWeaponBulletItemID,InGAWeaponInstance)
        self:UpdateCurrentBulletTextAndColor(MaxBulletNum)
    end
    TmpProfile.End("HUDWeaponDetailBase:OnWeaponMagUpdate")
end

function HUDWeaponDetailBase:OnInventoryDestroy(InInventoryInstance)
    print("ItemSlotWeapon >> OnInventoryDestroy...")
    local CurrentInventoryIdentity = InInventoryInstance:GetInventoryIdentity()
    if self.GAWeaponInstance then
        if CurrentInventoryIdentity.ItemID == self.CurrentWeaponBulletItemID then
            self:UpdateCurrentBulletTextAndColor(0)
        end
    end
end

function HUDWeaponDetailBase:OnFireBurst(InASC, InTag, InTagCount)
    local TmpProfile = require("Common.Utils.InsightProfile")
    TmpProfile.Begin("HUDWeaponDetailBase:OnFireBurst")

    if not self:IsValidWeaponSlotData() then return end
    if InTag.TagName ~= "Character.Gun.Fire.Burst" then
        return
    end
    if InTagCount <= 0 then return end

    if self.WeaponSlotData then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(InASC, 0)
        if PlayerController == nil then
            Error("HUDWeaponDetailBase >> OnFireBurst > PlayerController:nil")
            return
        end

        local TempPawn = PlayerController:K2_GetPawn()
        local TempEquipmentComp = UE.UEquipmentStatics.GetEquipmentComponent(TempPawn)
        if not TempEquipmentComp then return end
        local TempWeaponInstance = TempEquipmentComp:GetEquippedInstance()
        if not TempWeaponInstance then return end

        local TempEquippedInstanceInventoryIdentity = TempWeaponInstance:GetInventoryIdentity()

        if (TempEquippedInstanceInventoryIdentity.ItemID == self.WeaponSlotData.InventoryIdentity.ItemID) and
            (TempEquippedInstanceInventoryIdentity.ItemInstanceID == self.WeaponSlotData.InventoryIdentity.ItemInstanceID) then

            local TempCurrentBulletCount = TempWeaponInstance:GetPredictCurrentAmmo()
            self:SetCurBulletNumTxt(TempCurrentBulletCount)
        end
    end
    TmpProfile.End("HUDWeaponDetailBase:OnFireBurst")
end

function HUDWeaponDetailBase:OnSkillTagUpdated(InASC, InGameplay, InTagExists)
    if InGameplay.TagName == "Character.Gun.SwitchMode" and (not InTagExists) then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        local TempPawn = PlayerController:K2_GetPawn()
        local TempEquipmentComponent = UE.UEquipmentStatics.GetEquipmentComponent(TempPawn)
        if not TempEquipmentComponent then return end
        local TempWeaponInstance = TempEquipmentComponent:GetEquipmentInstanceByInventoryIdentity(self.WeaponSlotData.InventoryIdentity)
        if not TempWeaponInstance then return end

        -- 设置武器开火模式
        local TempFireModeTag, TempFireModeTags,bResult = self:GetFireModeInfo(TempWeaponInstance)
        if bResult then
            self:UpdateFireMode(TempFireModeTag, TempFireModeTags)
        end

    end
end


function HUDWeaponDetailBase:IsExistValidWeaponInSlot()
    if (self.WeaponSlotData.InventoryIdentity.ItemID ~= 0) and (self.WeaponSlotData.InventoryIdentity.ItemInstanceID ~= 0) then
        return true
    else
        return false
    end
end


function HUDWeaponDetailBase:UpdateWeaponBulletItemID(WeaponItemID)
    if WeaponItemID then
        local BulletItemID, bValidBulletItemID = UE.UItemSystemManager.GetItemDataInt32(
            self, WeaponItemID, "BulletItemID", GameDefine.NItemSubTable.Ingame,
            "HUDWeaponDetailBase:UpdateWeaponBulletItemID")
        if bValidBulletItemID then
            self.CurrentWeaponBulletItemID = BulletItemID
            self:UpdateWeaponBulletItemIcon(BulletItemID)
        end
    else
        self.CurrentWeaponBulletItemID = nil
    end
end

function HUDWeaponDetailBase:UpdateWeaponBulletWarningNum(WeaponItemID)
    if WeaponItemID then
        local BulletWarningNum, bValidBulletItemID = UE.UItemSystemManager.GetItemDataInt32(
            self, WeaponItemID, "AmmoRed", GameDefine.NItemSubTable.Ingame,
            "HUDWeaponDetailBase:UpdateWeaponBulletWarningNum")
            --print("HUDWeaponDetailBase >> UpdateWeaponBulletWarningNum BulletWarningNum:",BulletWarningNum,"bValidBulletItemID:",bValidBulletItemID )
            if bValidBulletItemID then
                self.BulletWarningNum = BulletWarningNum
            end
    end
end



-- 回调函数，背包物品总个数更新
function HUDWeaponDetailBase:OnInventoryItemNumChangeTotal(In_GMPMessage_InventoryItemChange_Total)
    local TmpProfile = require("Common.Utils.InsightProfile")
    TmpProfile.Begin("HUDWeaponDetailBase:OnInventoryItemNumChangeTotal")

    if not In_GMPMessage_InventoryItemChange_Total then return end
    if self.CurrentWeaponBulletItemID then
        if self.CurrentWeaponBulletItemID == In_GMPMessage_InventoryItemChange_Total.ItemID then
            --self:SetMaxBulletNumTxt(In_GMPMessage_InventoryItemChange_Total.ItemTotalNum)
            -- 设置最大子弹数的颜色（警戒值）
            self:UpdateCurrentBulletTextAndColor(In_GMPMessage_InventoryItemChange_Total.ItemTotalNum)

            --self:SetMaxBulletNumTxtAndColor()
        end
    end
    TmpProfile.End("HUDWeaponDetailBase:OnInventoryItemNumChangeTotal")
end


-- 设置插槽的颜色
function HUDWeaponDetailBase:UpdateWeaponSlotImage(InWeaponInstance, InItemId)
    local TmpProfile = require("Common.Utils.InsightProfile")
    TmpProfile.Begin("HUDWeaponDetailBase:UpdateWeaponSlotImage")

    if not InWeaponInstance then
        return
    end

    local TempAvatarManagerSubsystem = UE.UAvatarManagerSubsystem.Get(self)
    if not TempAvatarManagerSubsystem then
        return
    end

    local TempTargetSlot = UE.FGameplayTag()
    TempTargetSlot.TagName = GameDefine.NTag.WEAPON_SKIN_ATTACHSLOT_GUNBODY
    local TempWeaponSkinId = TempAvatarManagerSubsystem:GetWeaponCurrentAvatarID(InWeaponInstance, TempTargetSlot)

    local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, TempWeaponSkinId)
    if not WeaponSkinCfg then
        return
    end

    local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(WeaponSkinCfg.WeaponSlotImage)
    if ImageSoftObjectPtr then
        self.ImgIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)

        if self.WeaponsScaleRote then
            local ScaleRote = self.WeaponsScaleRote:Find(InItemId)
            if ScaleRote then
                self.ImgIcon:SetRenderScale(self.InitIconRenderScale * ScaleRote)
            else
                self.ImgIcon:SetRenderScale(self.InitIconRenderScale)
            end
        end
    end

    -- 特殊背景
    local TheQualityCfg = MvcEntry:GetModel(DepotModel):GetQualityCfgByItemId(InItemId)
    local Quality = TheQualityCfg[Cfg_ItemQualityColorCfg_P.Quality]
    self.Image_SpecialBg:SetVisibility(Quality == 5 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    
    TmpProfile.End("HUDWeaponDetailBase:UpdateWeaponSlotImage")
end



-- 获得武器伤害
-- return float
function HUDWeaponDetailBase:GetWeaponDamageNumber()
    if (self.GAWeaponInstance) and (self.GAWeaponInstance:IsWeaponCreated()) then
        local TempGAWeaponFireMode = nil
        local TempDamageValue = self.GAWeaponInstance:GetDamageValue()
        if(UE.UWeaponBlueprintLibrary.GetCurrentFireModeUF(self.GAWeaponInstance,TempGAWeaponFireMode))then
            return TempDamageValue
        end
    end
    
    return 55.8
end

-- 获得武器设置的开火模式
-- return FGameplayTag
function HUDWeaponDetailBase:GetFireModeInfo(GAWeaponInstance)
    if (GAWeaponInstance) and (GAWeaponInstance:IsWeaponCreated()) then
        local FireModeTags = GAWeaponInstance:GetFireModeTags()
        local TempGAWeaponFireMode,bResult= UE.UWeaponBlueprintLibrary.GetCurrentFireModeUF(GAWeaponInstance)
        if bResult then
            if (TempGAWeaponFireMode ~= nil) and (FireModeTags ~= nil) then
                    return TempGAWeaponFireMode.FireModeName, FireModeTags,true
            end
        end
    end
    return UE.FGameplayTag(), 0,false
end

-- 获得武器当前弹夹中的子弹数
-- return int32
function HUDWeaponDetailBase:GetWeaponCurrentBullet(GAWeaponInstance)
    if GAWeaponInstance then
        local TempMagBoltSetup = GAWeaponInstance:GetMagBoltData()
        if TempMagBoltSetup then
            return TempMagBoltSetup.CurrentCartridges
        end
    end
    return 0
end

-- 获得武器当前弹夹最大子弹上限
-- return int32
function HUDWeaponDetailBase:GetWeaponMaxMagBullet(WeaponBulletItemID,InGAWeaponInstance)

    if InGAWeaponInstance then
        local MagBoltSetup = InGAWeaponInstance:GetMagBoltSetup()
        if MagBoltSetup then
            if MagBoltSetup.bUseBuiltInCartridges then
                local TempMagBoltSetup = InGAWeaponInstance:GetMagBoltData()
                local CurrentBuiltInCartridges = TempMagBoltSetup.CurrentBuiltInCartridges
                return CurrentBuiltInCartridges
            else
                if WeaponBulletItemID then
                    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
                    local TempBagComponent = UE.UBagComponent.Get(PlayerController)
                    if TempBagComponent then
                        local TempItemNum = TempBagComponent:GetItemNumByItemID(WeaponBulletItemID);
                        return TempItemNum
                    end
                end
            end
        end
    end

    return 0
end





-- 转换开火模式Tag到Icon的ID
-- InFireModeGameplayTag : FGameplayTag
function HUDWeaponDetailBase:ConvertFireModeTagToIconID(InFireModeGameplayTag)
    if InFireModeGameplayTag then
        local IsMatchFireMode = false
        for k, v in pairs(HUDWeaponDetailBase.FireModeIcons) do
            local TempGameplayTag = UE.FGameplayTag()
            TempGameplayTag.TagName = v.Tag
            IsMatchFireMode = UE.UGFUnluaHelper.FGameplayTagMatchesTag(InFireModeGameplayTag, TempGameplayTag)
            if IsMatchFireMode then
                return v.Tag
            end
        end
    end
    return nil
end

function HUDWeaponDetailBase:ResetAttachmentInfo()  --Virtuall Function
end

--发送芯片装备GMP
function HUDWeaponDetailBase:MicrochipNotify(TheItemID) --Virtuall Function
end

--更新配件信息
function HUDWeaponDetailBase:UpdateAttachmentInfo(bIsAttachChange, bIsSwitchWeapon) --Virtual Function
end

--更新配件信息 性能优化版本
function HUDWeaponDetailBase:UpdateAttachmentInfoByGMPData(InGAWAttachmentStateChangeGMPData)
end


-- 更新开火模式UI
-- 可能的值
-- InFireModeTag - FGameplayTag
-- InFireModeNum - int32
-- InFireModeTag 为现在选择的模式，类型为 FGameplayTag
-- InFireModeTags 为现在总共有多少种模式，类型为 TArray<FGameplayTag>
function HUDWeaponDetailBase:UpdateFireMode(InFireModeTag, InFireModeTags) --Virtual Function
end

-- 更新当前武器的伤害值文字
-- return void
function HUDWeaponDetailBase:UpdateWeaponDamageNumber(CurrentDamageNumber) --Virtual Function
end

-- 设置当前武器的当前弹夹子弹个数文字
-- return void
function HUDWeaponDetailBase:SetCurBulletNumTxt(InBulletNum) --Virtual Function
end

function HUDWeaponDetailBase:SetActiveState(bIsActive) --Virtual Function
end

-- 更新当前子弹个数的字体颜色
-- return void
function HUDWeaponDetailBase:UpdateCurrentBulletTextAndColor(CurrentBulletCount) --Virtual Function
end


--每次切枪都会执行一次 
function HUDWeaponDetailBase:ResetWidget() --Virtual Function
end


function HUDWeaponDetailBase:SetInfiniteAmmoWidget(NewState) --Virtual Function
end


function HUDWeaponDetailBase:SetInfiniteAmmoColor(NewState) --Virtual Function
end

function HUDWeaponDetailBase:OnUpdatePawn(InLocalPC, InPCPwn)
    self:UnBindWeaponAvatarAttachSucceed()
    self:BindWeaponAvatarAttachSucceed()
end

function HUDWeaponDetailBase:BindWeaponAvatarAttachSucceed()
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempLocalPC then
        -- local CurPawn = UE.UGameplayStatics:GetPlayerPawn(self,0)
        local CurPawn = TempLocalPC:K2_GetPawn()
        if CurPawn then
            if self.WeaponAttachSucceedHandle then
                self:UnBindWeaponAvatarAttachSucceed()
            end
            self.WeaponAttachSucceedHandle = ListenObjectMessage(CurPawn, GameDefine.MsgCpp.WEAPON_SKIN_ATTACH_SUCCEED, self, self.OnWeaponAvatarAttachSucceed)
        end
    end
end

function HUDWeaponDetailBase:UnBindWeaponAvatarAttachSucceed()
    if self.WeaponAttachSucceedHandle then
        UnListenObjectMessage(GameDefine.MsgCpp.WEAPON_SKIN_ATTACH_SUCCEED, self, self.WeaponAttachSucceedHandle)
        self.WeaponAttachSucceedHandle = nil
    end
end

function HUDWeaponDetailBase:OnWeaponAvatarAttachSucceed(InUAvatarItemDefinitionPtr)
    if not InUAvatarItemDefinitionPtr then
       return 
    end

    if self.GAWeaponInstance and self.WeaponSlotData.InventoryIdentity.ItemID then
        self:UpdateWeaponSlotImage(self.GAWeaponInstance, self.WeaponSlotData.InventoryIdentity.ItemID)
    end
end

function HUDWeaponDetailBase:GetWeaponMaxMagBullet(WeaponBulletItemID,InGAWeaponInstance)
    

    if InGAWeaponInstance then
        local MagBoltSetup = InGAWeaponInstance:GetMagBoltSetup()
        if MagBoltSetup then
            if MagBoltSetup.bUseBuiltInCartridges then
                local TempMagBoltSetup = InGAWeaponInstance:GetMagBoltData()
                local CurrentBuiltInCartridges = TempMagBoltSetup.CurrentBuiltInCartridges
                return CurrentBuiltInCartridges
            else
                if WeaponBulletItemID then
                    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
                    local TempBagComponent = UE.UBagComponent.Get(PlayerController)
                    if TempBagComponent then
                        local TempItemNum = TempBagComponent:GetItemNumByItemID(WeaponBulletItemID);
                        return TempItemNum
                    end
                end
            end
        end
    end

    return 0
end

function HUDWeaponDetailBase:OnBloodBulletEvent()
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

    if not self.LocalPC then 
        return 
    end

    local CurrentPawn = self.LocalPC:K2_GetPawn()

    if not CurrentPawn then 
        return 
    end

    local TempASC = CurrentPawn:GetGameAbilityComponent()

    if not TempASC then 
        return 
    end

    local TempAbilityTag = UE.FGameplayTag()
    TempAbilityTag.TagName = "Character.Gun.BloodBullet"
    self.HasBloodBulletEventTag = TempASC:HasMatchingGameplayTag(TempAbilityTag)

    if self.HasBloodBulletEventTag == true then
        if self.bIsCurrentChipAnimActive == true then self:VXE_StopOtherChip(0) end
        self:VXE_Chip_BloodInvasion_In()
    elseif self.HasBloodBulletEventTag == false then
        self:VXE_Chip_BloodInvasion_Out()
    end
end


function HUDWeaponDetailBase:OnTolBulletEvent(BulletOwner,Weapon,State)

    --是不是自己
    local CurrentPawn = self.LocalPC:K2_GetPawn()
    if BulletOwner == nil or CurrentPawn == nil or BulletOwner ~= CurrentPawn then
        return 
    end
    
    --是不是同一把枪
    local TempIdentity = Weapon:GetInventoryIdentity()
    if TempIdentity == nil then
        return 
    end
    if (TempIdentity.ItemID ~= self.WeaponSlotData.InventoryIdentity.ItemID or TempIdentity.ItemInstanceID ~= self.WeaponSlotData.InventoryIdentity.ItemInstanceID) then
        return 
    end

    self.TolBulletEventState = State
    if State == 1 then
        if self.bIsCurrentChipAnimActive == true then self:VXE_StopOtherChip(2) end
        self:VXE_Chip_Mistake_In()
    elseif State == 0  then
        self:VXE_Chip_Mistake_Out()
    end
end

function HUDWeaponDetailBase:OnInventoryItemCreateEnhance(InInventoryInstance)
    -- 设置武器伤害数值
    local TempDamageValue = self:GetWeaponDamageNumber()
    self:UpdateWeaponDamageNumber(TempDamageValue)
end

function HUDWeaponDetailBase:PlayChipAnim(TheItemID)
    --如果之前显示的芯片不是空的
    if self.HUDWeaponSwitcherBase.CurrentShowingChipId ~= nil then
        --切换到空的效果，或者是新的芯片没有进入动画
        if TheItemID == nil or (not self:IsThisChipHasAnimation(TheItemID)) then
            --播放之前芯片的退出动画
            self:PlayChipOutAnimation(self.HUDWeaponSwitcherBase.CurrentShowingChipId)

        --切换到新的效果
        else 
            --播放新的芯片进入动画
            self:PlayChipInAnimation(TheItemID)
        end

        local AnotherDetailWidget = self:GetAnOtherDetailWidget()
        if AnotherDetailWidget ~= nil then
            AnotherDetailWidget:PlayChipOutAnimation(AnotherDetailWidget.CurrentActiveChipId)
        end
    --如果之前显示的芯片是空的
    else
        --直接播放新的芯片进入动画
        self:PlayChipInAnimation(TheItemID)
    end

    --然后再设置当前显示的动画id
    self.HUDWeaponSwitcherBase.CurrentShowingChipId = TheItemID
end

function HUDWeaponDetailBase:IsThisChipHasAnimation(ChipItemID)

    for _,v in pairs(self.HasAnimChipTable) do
        if v == ChipItemID then
            return true
        end
    end
    return false
end

function HUDWeaponDetailBase:PlayChipInAnimation(ChipItemID)
    if (ChipItemID == "311200000") then
        self:VXE_Chip_Cure_In()
    elseif (ChipItemID == "311140000") then
        self:VXE_Chip_BloodInvasion_In()
    elseif (ChipItemID == "311210000") then
        self:VXE_Chip_Mistake_In()

    else
        self.T_BG:SetRenderOpacity(0)
    end
end

function HUDWeaponDetailBase:PlayChipOutAnimation(ChipItemID)
    if (ChipItemID == "311200000") then
        self:VXE_Chip_Cure_Out()
    elseif (ChipItemID == "311140000") then
        self:VXE_Chip_BloodInvasion_Out()
    elseif (ChipItemID == "311210000") then
        self:VXE_Chip_Mistake_Out()
    end
end

function HUDWeaponDetailBase:GetAnOtherDetailWidget()
    if self.HUDWeaponSwitcherBase ~= nil then
        for i = 0, #self.HUDWeaponSwitcherBase.BPWeaponDetail do
            if self.HUDWeaponSwitcherBase.BPWeaponDetail[i] ~= self then
                return self.HUDWeaponSwitcherBase.BPWeaponDetail[i]
            end
        end
    end
    return nil
end


return HUDWeaponDetailBase
