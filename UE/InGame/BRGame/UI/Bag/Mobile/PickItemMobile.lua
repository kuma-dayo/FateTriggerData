require "UnLua"
require ("InGame.BRGame.ItemSystem.ItemSystemHelper")
require ("Common.Utils.StringUtil")

local PickItemMobile = Class()

function PickItemMobile:Initialize(Initializer)
    self.PickupObjArray = nil
end

function PickItemMobile:Construct()
    self:HandleBetterItem()
    self.GUIButton_Pick.OnClicked:Add(self, self.OnPickButtonClick)
end

function PickItemMobile:HandleBetterItem()
    if not self.PickupObjArray or self.PickupObjArray:Length() <= 0 then
        return
    end
    local TempPickupObj = self.PickupObjArray:Get(1)
    if not UE.UKismetSystemLibrary.IsValid(TempPickupObj) then
        return
    end
    -- 查类型
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not PlayerController then
        return
    end
    local tPawn = PlayerController:GetPawn()
    if not tPawn then
        return
    end
    local TempItemType, IsFindTempItemType = UE.UItemSystemManager.GetItemDataFName(
        PlayerController,self.ItemID, "ItemType",GameDefine.NItemSubTable.Ingame,"PickItemDetailUI:HandleBetterItem")
    if not IsFindTempItemType then
        return
    end

    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if not PickupSetting then
        return
    end
    if not PickupSetting.ItemTypeNeedCompare:Contains(TempItemType) then
        return
    end

    if TempPickupObj:IsBetter(tPawn) > 0 then
        self.Image_Better:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    else
        self.Image_Better:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function PickItemMobile:Destruct()
    --self:Release()
end

function PickItemMobile:OnPickButtonClick()
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPawn(LocalPC)
    if not LocalPC or not LocalPCPawn then
        return
    end
    -- 查询最小堆叠数，现在叫快捷丢弃，点一下捡多少=点一下丢多少  没毛病
    local CurQuickDiscardNum, IsExistNum = UE.UItemSystemManager.GetItemDataInt32(self, self.ItemID, "InventoryQuickDiscardNum", GameDefine.NItemSubTable.Ingame,"PickItemDetailUI:OnMouseButtonUp")
    if IsExistNum and self.PickupObjArray then
        for index = 1, self.PickupObjArray:Length() do
            local PrePickObj = self.PickupObjArray:Get(index)
            if UE.UKismetSystemLibrary.IsValid(PrePickObj) and PrePickObj.ItemInfo.ItemNum <= CurQuickDiscardNum and CurQuickDiscardNum > 0 then
                UE.UPickupStatics.TryPickupItem(LocalPCPawn, PrePickObj, 0, UE.EPickReason.PR_Player, UE.FGameplayTagContainer())
                CurQuickDiscardNum = CurQuickDiscardNum - PrePickObj.ItemInfo.ItemNum
            else
                UE.UPickupStatics.TryPickupItem(LocalPCPawn, PrePickObj, CurQuickDiscardNum, UE.EPickReason.PR_Player, UE.FGameplayTagContainer())
                break
            end
        end
    end
end

function PickItemMobile:AddPickupObj(InPickupObj)
    if UE.UKismetSystemLibrary.IsValid(InPickupObj) then
        self.PickupObjArray:AddUnique(InPickupObj)

        self.ItemNum = 0
        for i = 1, self.PickupObjArray:Length() do
            self.ItemNum = self.ItemNum + self.PickupObjArray:Get(i).ItemInfo.ItemNum
        end

            -- 设置个数
        self.TextBlock_Num:SetText(self.ItemNum)
    end
end

function PickItemMobile:SetDetail(InPickupObj, ParentWidget)
    -- if not self.InitSizeBoxWidth then
    --     self.InitSizeBoxWidth = self.SizeBox_BarArmor.WidthOverride
    -- end
    
    if not UE.UKismetSystemLibrary.IsValid(InPickupObj) then
        return
    end

    self.PickupObjArray:Clear()
    self.PickupObjArray:AddUnique(InPickupObj)
    
    self.ItemID = InPickupObj.ItemInfo.ItemID
    self.ItemNum = 0
    for i = 1, self.PickupObjArray:Length() do
        self.ItemNum = self.ItemNum + self.PickupObjArray:Get(i).ItemInfo.ItemNum
    end
    self.ParentWidget = ParentWidget
    -- 查表
    local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(self)
    local SubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(self.ItemID, "Ingame")
    local StrItemID = tostring(self.ItemID)

    -- 设置物品类型
    local CurItemType, IsExistType = SubTable:BP_FindDataFName(StrItemID, "ItemType")
    if IsExistType then
        self.TextBlock_ItemType:SetText(CurItemType)
    end
    
    -- 设置名称
    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, self.ItemID)
    if not IngameDT then
        return
    end

    local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, StrItemID)
    if not StructInfo_Item then
        return
    end

    local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)
    self.TextBlock_Name:SetText(TranslatedItemName)
    
    -- 设置 ItemIcon 根据皮肤
    local HasAttribute_SkinId = InPickupObj:HasSkinId()
    if HasAttribute_SkinId then
        local ImageSoftObjectPtr = self:GetImageAssetFromSkinID(InPickupObj.ItemInfo.ItemID, InPickupObj:GetSkinId())
        if ImageSoftObjectPtr then
            self.Image_Content:SetBrushFromSoftTexture(ImageSoftObjectPtr,true)
        end
    else
        -- 设置图片
        local CurItemIcon, IsExistIcon = SubTable:BP_FindDataFString(StrItemID,"ItemIcon")
        if IsExistIcon then
            local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurItemIcon)
            self.Image_Content:SetBrushFromSoftTexture(ImageSoftObjectPtr,true)
        end
    end
    
    -- 设置个数
    self.TextBlock_Num:SetText(self.ItemNum)

    local ItemLevel, IsFindItemLevel = SubTable:BP_FindDataUInt8(StrItemID,"ItemLevel")
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
    
    self:HandleBetterItem()
end

function PickItemMobile:GetImageAssetFromSkinID(InItemId, InSkinId)
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

return PickItemMobile
