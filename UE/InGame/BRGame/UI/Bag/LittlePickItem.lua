require "UnLua"
require ("InGame.BRGame.ItemSystem.ItemSystemHelper")

local LittlePickItem = Class()

function LittlePickItem:Initialize(Initializer)
end

function LittlePickItem:Construct()
end

function LittlePickItem:Destruct()
end

function LittlePickItem:SetDetail(InPickupObj)
    if not InPickupObj then
        return
    end
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not LocalPC then
        return
    end

    -- 设置ItemIcon，如果有皮肤则用皮肤的ItemIcon
    local HasAttribute_SkinId = InPickupObj:HasSkinId()
    if HasAttribute_SkinId then
        local ImageSoftObjectPtr = self:GetImageAssetFromSkinID(InPickupObj.ItemInfo.ItemID, InPickupObj:GetSkinId())
        self:SetItemIcon(ImageSoftObjectPtr)
    else
        local CurItemIcon, IsExistIcon = UE.UItemSystemManager.GetItemDataFString(
            LocalPC,InPickupObj.ItemInfo.ItemID, "ItemIcon", GameDefine.NItemSubTable.Ingame, "LittlePickItem:SetDetail")
        if IsExistIcon then
            local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurItemIcon)
            self:SetItemIcon(ImageSoftObjectPtr)
        end
    end

    -- 根据物品等级设置颜色
    local ItemLevel, IsFindItemLevel = UE.UItemSystemManager.GetItemDataUInt8(
        LocalPC,InPickupObj.ItemInfo.ItemID, "ItemLevel", GameDefine.NItemSubTable.Ingame, "LittlePickItem:SetDetail")

    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if IsFindItemLevel and PickupSetting then
        local BackgroundImagePath = PickupSetting.PickupBGImageMap:Find(ItemLevel)
        local BackgroundImage = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(BackgroundImagePath)
        if BackgroundImage then
            self.Image_BG:SetBrushFromSoftTexture(BackgroundImage, true)
            self.Image_BG:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        else
            self.Image_BG:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

function LittlePickItem:SetDetailByItemId(InItemID)
    if InItemID <= 0 then
        return
    end
    
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not LocalPC then
        return
    end

    local CurItemIcon, IsExistIcon = UE.UItemSystemManager.GetItemDataFString(
        LocalPC,InItemID, "ItemIcon", GameDefine.NItemSubTable.Ingame, "LittlePickItem:SetDetail")

    if IsExistIcon then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurItemIcon)
        self:SetItemIcon(ImageSoftObjectPtr)
    end

    local ItemLevel, IsFindItemLevel = UE.UItemSystemManager.GetItemDataUInt8(
        LocalPC,InItemID, "ItemLevel", GameDefine.NItemSubTable.Ingame, "LittlePickItem:SetDetail")

    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if IsFindItemLevel and PickupSetting then
        local BackgroundImagePath = PickupSetting.PickupBGImageMap:Find(ItemLevel)
        local BackgroundImage = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(BackgroundImagePath)
        if BackgroundImage then
            self.Image_BG:SetBrushFromSoftTexture(BackgroundImage, true)
            self.Image_BG:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        else
            self.Image_BG:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end


function LittlePickItem:SetItemIcon(InItemIconFSoftObjectPath)
    if self.Image_Content and InItemIconFSoftObjectPath then
        self.Image_Content:SetBrushFromSoftTexture(InItemIconFSoftObjectPath,true)
    end
end

function LittlePickItem:GetImageAssetFromSkinID(InItemId, InSkinId)
    local ItemType, IsExistItemType = UE.UItemSystemManager.GetItemDataFName(self, InItemId, "ItemType", GameDefine.NItemSubTable.Ingame, "")
    if IsExistItemType then
        if ItemType == ItemSystemHelper.NItemType.Weapon then
            local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, InSkinId)
            if not WeaponSkinCfg then
                return nil
            end
            local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(WeaponSkinCfg.WeaponIconImage)
            return ImageSoftObjectPtr
        end
    end

    return nil
end


return LittlePickItem
