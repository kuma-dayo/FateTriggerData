--
-- 物品系统助手
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.25
--

require("Common.Framework.CommFuncs")

local ItemSystemHelper = _G.ItemSystemHelper or {}

-------------------------------------------- Config/Enum ------------------------------------

-- 道具栏类型定义
-- FItemSlot -> ItemType
ItemSystemHelper.NItemType = {
    Weapon              = "Weapon",
    ArmorHead           = "ArmorHead",
    ArmorBody           = "ArmorBody",
    Bag              	= "Bag",
    Potion              = "Potion",
    Throwable           = "Throwable",
    Attachment          = "Attachment",
    Bullet              = "Bullet",
    Currency            = "Currency",
    Other               = "Other"
}
SetErrorIndex(ItemSystemHelper.NItemType)

ItemSystemHelper.ItemDetialInfoShowMsgSourceType = {
    PickupSystem = 'PickupSystem',
    BagSystem = 'BagSystem'
}
SetErrorIndex(ItemSystemHelper.ItemDetialInfoShowMsgSourceType)

-- 物品定义FeatureSet
ItemSystemHelper.NFeatureSetName = {
    ItemSlot            = "FeatureSet.ItemSlot",
}

-- 物品属性名定义
ItemSystemHelper.NItemAttrName = {
	ArmorShield         = "ArmorShield",
	MaxArmorShield      = "MaxArmorShield",
	ArmorDurability     = "ArmorDurability",
	WeaponHandle        = "WeaponHandleID",
}
SetErrorIndex(ItemSystemHelper.NItemAttrName)

-- 物品属性名定义
ItemSystemHelper.NUsefulReason = {
	PlayerActivePick    = "PlayerActivePick",
    PlayerActiveDiscard = "PlayerActiveDiscard",
    PlayerActiveUse     = "PlayerActiveUse",
    SwitchHoldItem      = "SwitchHoldItem",
    -- 切换装备物品
    SwitchEquipItem     = "SwitchEquipItem",
    DiscardEquippedItem = "DiscardEquippedItem",
    PickSwapHold        = "PickSwapHold",
    UseUpDelete         = "UseUpDelete",
    UseConsume          = "UseConsume",
    SwitchCharacterSkill= "SwitchCharacterSkill",
    -- For Weapon
    PickToWeapon1= "PickToWeapon1",
    PickToWeapon2= "PickToWeapon2",
    SwapToWeapon1= "SwapToWeapon1",
    SwapToWeapon2= "SwapToWeapon2",
    -- Empty Hand
    EmptyHand="EmptyHand",
    EquipAndUse="EquipAndUse"
}
SetErrorIndex(ItemSystemHelper.NUsefulReason)

-- 物品槽位类型定义
-- BagTypes -> EItemSlotType
ItemSystemHelper.NItemSlotType = {
	Item                = "Item",
    Weapon              = "Weapon",
}
SetErrorIndex(ItemSystemHelper.NItemSlotType)

-- 物品选中的使用状态
ItemSystemHelper.NKeyButtonState =
{
    None = 0,
    AttachmentCanUse = 1,
    AttachmentCanNotUse = 2,
    Potion = 3,
    Throwable = 4,
    BulletCanUse = 5,
    BulletCanNotUse = 6,
}
SetErrorIndex(ItemSystemHelper.NKeyButtonState)

-------------------------------------------- Common ------------------------------------

function ItemSystemHelper.ToString_FItemSlot(InItemSlot)
    return string.format("SlotID[%d] ItemType[%s] bActive[%d] ItemID[%d] ItemInstanceID[%d]",
        InItemSlot.SlotID, InItemSlot.ItemType, InItemSlot.bActive and 1 or 0, InItemSlot.InventoryIdentity.ItemID, InItemSlot.InventoryIdentity.ItemInstanceID)
end

function ItemSystemHelper.AttributeConvertWeaponHandle(ItemAttribute)
    if ItemAttribute.AttributeName == GameDefine.NItemAttribute.WeaponHandleID then
        local TempInstanceID = math.floor(ItemAttribute.FloatValue)
        local WeaponHandle = UE.FGWSWeaponHandle()
        WeaponHandle.InstanceID = TempInstanceID
        return WeaponHandle
    end
    return nil
end

function ItemSystemHelper.GenerateItemAttributeByFloat(Name, Float)
    local RetAttr = UE.FItemAttribute()
    RetAttr.AttributeName = Name
    RetAttr.FloatValue = Float
    return RetAttr
end

function ItemSystemHelper.GetItemLevelColorBgByLevel(ItemLevel)
    local MiscSystem = UE.UMiscSystem.GetMiscSystem(GameInstance)
    local Ret = MiscSystem.BagLvColorTexture:FindRef(ItemLevel)
    return Ret
end

-- copy from pc ui item show
-- TODO move to c++
function ItemSystemHelper.IsShowNotRecommendSuperscript(ItemID)
    local ReturnValue = false

    if not ItemID then
        return ReturnValue
    end

    local TempPC = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    if not TempPC then
        return ReturnValue
    end

    local TempBagComp = UE.UBagComponent.Get(TempPC)
    if not TempBagComp then
        return ReturnValue
    end

    local WeaponItmeObjectArray = TempBagComp:GetItemByItemType(ItemSystemHelper.NItemType.Weapon)
    local WeaponNum = WeaponItmeObjectArray:Length()
    if WeaponNum <= 0 then
        return ReturnValue
    end

    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(TempPC, ItemID)
    if not IngameDT then
        return ReturnValue
    end

    local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(ItemID))
    if not StructInfo_Item then
        return ReturnValue
    end

    local IsSupportWAttachmentFinal = false
    local IsLowestLevelWAttachment = true
    local IsMatchBulletType = false

    -- 获取当前武器
    for i = 1, WeaponNum, 1 do
        -- 获取背包物品
        local TempInventoryInstance_Weapon = WeaponItmeObjectArray:Get(i)
        if not TempInventoryInstance_Weapon then
            goto continue
        end

        -- 获取武器实例
        local TempWeaponInstance = TempInventoryInstance_Weapon.CurrentEquippableInstance
        if not TempWeaponInstance then
            goto continue
        end
        
        local TempWeaponInventoryIdentity = TempInventoryInstance_Weapon:GetInventoryIdentity()
        if not TempWeaponInventoryIdentity then
            goto continue
        end

        local IngameDTForWeapon = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(TempPC, TempWeaponInventoryIdentity.ItemID)
        if not IngameDT then
            goto continue
        end
    
        local StructInfo_LoopWeapon = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDTForWeapon, tostring(TempWeaponInventoryIdentity.ItemID))
        if not StructInfo_LoopWeapon then
            goto continue
        end
        
        -- 根据类型判断
        if StructInfo_Item.ItemType == ItemSystemHelper.NItemType.Attachment then
            -- 芯片
            -- 瞄准镜和芯片都视为平级的，都不显示不推荐
            if (StructInfo_Item.SlotName.TagName == GameDefine.NTag.WEAPON_AttachSlot_Optics) and 
               (StructInfo_Item.SlotName.TagName == GameDefine.NTag.WEAPON_AttachSlot_HopUp) then
                goto continue
            end

            local IsSupportWAttachment = UE.UGAWAttachmentFunctionLibrary.CanAttachToWeapon(TempWeaponInstance, ItemID)
            if not IsSupportWAttachment then
                goto continue
            end

            -- 得到特定槽位中配件的等级，进行对比，如果更低，则显示
            local WAttachmentHandleArray = UE.UGAWAttachmentFunctionLibrary.GetAllAttachmentEffectHandleInSlot(TempWeaponInstance, StructInfo_Item.SlotName)
            if WAttachmentHandleArray:Length() > 0 then
                local TempWAttachmentHandle = WAttachmentHandleArray:Get(1);
                if not TempWAttachmentHandle then
                    goto continue
                end

                local StructInfo_AttachmentInWewpon = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(TempWAttachmentHandle.ItemID))
                if not StructInfo_AttachmentInWewpon then
                    goto continue
                end
                
                if StructInfo_Item.ItemLevel >= StructInfo_AttachmentInWewpon.ItemLevel then
                    IsLowestLevelWAttachment = false
                end
            else
                IsLowestLevelWAttachment = false
            end
            
            if not IsSupportWAttachmentFinal then
                if IsSupportWAttachment then
                    IsSupportWAttachmentFinal = true
                end
            end

        elseif StructInfo_Item.ItemType == ItemSystemHelper.NItemType.Bullet then
            print("BagM@IsShowNotRecommendSuperscript 1", ItemID, StructInfo_LoopWeapon.BulletItemID)
            -- 子弹
            if ItemID == StructInfo_LoopWeapon.BulletItemID then
                IsMatchBulletType = true
                break
            end
        end

        ::continue::
    end


    -- 根据类型判断
    if StructInfo_Item.ItemType == ItemSystemHelper.NItemType.Attachment then
        if (StructInfo_Item.SlotName.TagName ~= GameDefine.NTag.WEAPON_AttachSlot_Optics) and 
           (StructInfo_Item.SlotName.TagName ~= GameDefine.NTag.WEAPON_AttachSlot_HopUp) then
            -- 芯片
            if IsSupportWAttachmentFinal then
                if IsLowestLevelWAttachment then
                    ReturnValue = true
                end
            else
                ReturnValue = true
            end
        end
    elseif StructInfo_Item.ItemType == ItemSystemHelper.NItemType.Bullet then
        -- 没有匹配到任何一种当前持有武器的子弹类型，则显示
        if not IsMatchBulletType then
            ReturnValue = true
        end
    end
    
    return ReturnValue

end

function ItemSystemHelper.TryToDiscardItem(ItemID, ItemInstanceID, ItemNum)
    print("TryToDiscardItem", ItemID, ItemInstanceID, ItemNum)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    if not PlayerController then
        return
    end

    local DiscardInventoryIdentity = UE.FInventoryIdentity()
    DiscardInventoryIdentity.ItemID = ItemID
    DiscardInventoryIdentity.ItemInstanceID = ItemInstanceID
    local TempDiscardTag = UE.FGameplayTag()
    UE.UItemStatics.DiscardItem(PlayerController, DiscardInventoryIdentity, ItemNum, TempDiscardTag)
end

function ItemSystemHelper.TryToEquipAttachmentToAnyWeapon(ItemID, InstanceID, ItemNum, InstanceIDType)
    if InstanceIDType == GameDefine.InstanceIDType.ItemInstance then
        local AttachmentInventoryIdentity = UE.FInventoryIdentity()
        AttachmentInventoryIdentity.ItemID = ItemID
        AttachmentInventoryIdentity.ItemInstanceID = InstanceID

        local PlayerController = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
        UE.UItemStatics.UseItem(PlayerController, AttachmentInventoryIdentity,
            ItemAttachmentHelper.NUsefulReason.AttachAnyWeapon)
    end
end

function ItemSystemHelper.TryUseItem(ItemID, ItemInstanceID)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    local TempBagComp = UE.UBagComponent.Get(PlayerController)
    if not TempBagComp then
        return
    end

    local TempItemType, IsFindTempItemType = UE.UItemSystemManager.GetItemDataFName(PlayerController, ItemID, "ItemType",GameDefine.NItemSubTable.Ingame,"ItemSlotNormal:OnMouseButtonUp")
    if not IsFindTempItemType then
        return
    end

    if (TempItemType == "Throwable") or (TempItemType == "Potion") then
        -- 使用物品
        if not TempBagComp then return end
        local TempInventoryInstanceArray = TempBagComp:GetAllItemObjectByItemID(ItemID)
        if not TempInventoryInstanceArray then return end
        local FirstInventoryInstance = TempInventoryInstanceArray:Get(1)
        if FirstInventoryInstance and FirstInventoryInstance.ClientUseSkill then
            FirstInventoryInstance:ClientUseSkill()
        end
    else
        -- 其他物品
        local TempInventoryIdentity = UE.FInventoryIdentity()
        TempInventoryIdentity.ItemID = ItemID
        TempInventoryIdentity.ItemInstanceID = ItemInstanceID

        UE.UItemStatics.UseItem(PlayerController, TempInventoryIdentity, ItemSystemHelper.NUsefulReason.PlayerActiveUse)
    end
end
-------------------------------------------- Debug ------------------------------------

function ItemSystemHelper.GetItemDefaultAttribute(WorldContext, InItemID)
    -- 查类型

    local TempItemType, IsFindTempItemType = UE.UItemSystemManager.GetItemDataFName(
        WorldContext,InItemID, "ItemType","Ingame","ItemSystemHelper.GetItemDefaultAttribute")

    local tAttributeArray = UE.TArray(UE.FItemAttribute)
    if IsFindTempItemType then
        if TempItemType == ItemSystemHelper.NItemType.ArmorBody or TempItemType == ItemSystemHelper.NItemType.ArmorHead then
            local ArmorInfoAsset, bArmorInfoAsset = UE.UItemSystemManager.GetItemDataFString(WorldContext, InItemID, "ArmorInfoPath", "Ingame","ItemSystemHelper.GetItemDefaultAttribute")
            if not bArmorInfoAsset then return tAttributeArray end
            local ArmorPrimaryDataAsset = UE.UPickupStatics.SyncLoadObject(ArmorInfoAsset)
            if ArmorPrimaryDataAsset then
                local tAttribute = UE.FItemAttribute()
                tAttribute.AttributeName = ItemSystemHelper.NItemAttrName.ArmorShield
                tAttribute.FloatValue = ArmorPrimaryDataAsset.DefaultArmorShield
                tAttributeArray:Add(tAttribute)
                tAttribute.AttributeName = ItemSystemHelper.NItemAttrName.MaxArmorShield
                tAttribute.FloatValue = ArmorPrimaryDataAsset.MaxArmorShield
                tAttributeArray:Add(tAttribute)
            end
        end
    end
    return tAttributeArray
end

-- 
_G.ItemSystemHelper = ItemSystemHelper
return ItemSystemHelper
