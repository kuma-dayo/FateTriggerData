require "UnLua"
require ("Common.Utils.StringUtil")

local ItemDetailInfoUI = Class("Common.Framework.UserWidget")


function ItemDetailInfoUI:OnInit()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.BP_DetailKeyMap:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.BP_DetailKeyButton:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.MsgList = {
		{ MsgName = GameDefine.Msg.PLAYER_ShowItemDetailInfo,     Func = self.ShowItemDetailInfo,   bCppMsg = false },
		{ MsgName = GameDefine.Msg.PLAYER_HideItemDetailInfo,     Func = self.HideItemDetailInfo,   bCppMsg = false }
    }
    self.bIsShow = false
    self.bIsUseGamepad = UE.UGamepadUMGFunctionLibrary.IsGamepadConnection()

    local GamepadInputSubsystem = UE.UGamepadInputSubsystem.Get(self)
    GamepadInputSubsystem.GamepadConnectionNotify:Add(self,self.GamepadConnectionNotify)

	UserWidget.OnInit(self)
end

function ItemDetailInfoUI:OnDestroy()
    local GamepadInputSubsystem = UE.UGamepadInputSubsystem.Get(self)
    GamepadInputSubsystem.GamepadConnectionNotify:Remove(self,self.GamepadConnectionNotify)

    UserWidget.OnDestroy(self)
end


function ItemDetailInfoUI:GamepadConnectionNotify(bGamepadAttached)
    print("ItemDetailInfoUI:GamepadConnectionNotify", bGamepadAttached)
    self.bIsUseGamepad = bGamepadAttached
end

-- 重要函数：隐藏 - 背包层 - 详细信息面板
function ItemDetailInfoUI:HideItemDetailInfo()
    self.bIsShow = false
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.BP_DetailKeyMap:HideAllNumber()
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo_Deffer)
end


-- 重要函数：显示 - 背包层 - 详细信息面板
-- 此函数为了接收所有的详细信息面板展示功能的消息。
function ItemDetailInfoUI:ShowItemDetailInfo(InMsgBody)
    

    local ItemID = InMsgBody.ItemID
    local EnhanceId = InMsgBody.EnhanceId

    -- 在此处可以区分显示哪些类型的详细信息，因为不同的详细信息，显示的细节区别较大
    -- 此处将多种信息都放在一个控件中，没有拆分多个子类是有考虑的。一，因为显示的差别并不大，仅需显示隐藏某些结点，即可完成区分。二，拆分重构没时间。

    if ItemID == nil and EnhanceId then
        -- 显示强化词条的详细信息
        self:ShowDetailInfoByEnhanceId(InMsgBody)
    elseif ItemID then
        -- 显示物品的详细信息
        self:ShowDetailInfoByItemID(InMsgBody)
    else
        return
    end

    -- 位置
    local HoverWidget = InMsgBody.HoverWidget
    local ParentWidget = InMsgBody.ParentWidget
    local IsShowAtLeftSide = InMsgBody.IsShowAtLeftSide


    -- local UpdateSizeAndPositonLambda= function()

    -- end

    -- self.UpdateSizeAndPositonHandle = UE.UKismetSystemLibrary.K2_SetTimerForNextTickDelegate({self,UpdateSizeAndPositonLambda})
   -- UE.UKismetSystemLibrary.K2_SetTimerDelegate({ self, UpdateSizeAndPositonLambda }, 1, false, 0, 0)

    self:ChangeDetailLoc(HoverWidget, ParentWidget, IsShowAtLeftSide, nil)
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end


function ItemDetailInfoUI:ShowDetailInfoByItemID(InMsgBody)


    local ForceShow = InMsgBody.ForceShow and InMsgBody.ForceShow or true

    if ForceShow then
        self.ItemID = InMsgBody.ItemID
        self.ItemInstanceID = InMsgBody.ItemInstanceID
    else
        if self.ItemID ~= InMsgBody.ItemID  and self.ItemInstanceID ~= InMsgBody.ItemInstanceID then
            return
        end
    end


    local ItemID = InMsgBody.ItemID
    local ItemInstanceID = InMsgBody.ItemInstanceID
    local EnhanceId = InMsgBody.EnhanceId
    local ItemNum = InMsgBody.ItemNum
    local TempIsShowDiscardNum = InMsgBody.IsShowDiscardNum
    local TempInteractionKey = InMsgBody.InteractionKeyName
    local TempWeaponInstance = InMsgBody.WeaponInstance
    local ItemSkinId = InMsgBody.ItemSkinId
    local TempIsBetter = InMsgBody.IsBetter
    local TempEnhanceId = InMsgBody.EnhanceId
    


    --是否是更好的物品

    self.WidgetSwitcher_Better:SetVisibility(UE.ESlateVisibility.Collapsed)
    if TempIsBetter then
        if TempIsBetter > 0 then
            self.WidgetSwitcher_Better:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
            self.WidgetSwitcher_Better:SetActiveWidgetIndex(0)
        elseif TempIsBetter < 0 then
            self.WidgetSwitcher_Better:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
            self.WidgetSwitcher_Better:SetActiveWidgetIndex(1)
        end
    end

    -- 更新控件显示
    -- self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:SetItemTypeTextVisibility(true)

    -- 声音
    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Hover_01")

    -- 快捷丢弃的信息
    if BridgeHelper.IsMobilePlatform() then
        self.BP_DetailKeyButton:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.BP_DetailKeyButton:SetItemInfo(ItemID,ItemInstanceID,ItemNum)
        MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo_Deffer, { HoverWidget = self, ParentWidget = self.ParentWidget, IsShowAtLeftSide = true , ItemID=self.ItemID,ItemInstanceID = self.ItemInstanceID, ItemNum = self.ItemNum})
    else
        --设置按键映射图
        self.BP_DetailKeyMap:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.BP_DetailKeyMap:SetInteractionInfo(TempInteractionKey)

        -- 显示快捷丢弃个数控制
        local IsShowQuickDiscardFlag = false;
        local InventoryItemDevSettingCDO = UE.UGFUnluaHelper.GetDefaultObject(self.InventoryItemDevSettingClass)
        if InventoryItemDevSettingCDO then
            IsShowQuickDiscardFlag = InventoryItemDevSettingCDO.IsQuickDiscardFlag
        end
        if IsShowQuickDiscardFlag and TempIsShowDiscardNum then
            self.BP_DetailKeyMap:UpdateDiscardNumWidget(ItemID, ItemNum, "MouseRightKey.Discard")
        end

        -- 若物品被标记为无法主动丢弃，则右键丢弃的快捷提示需要关闭
        local tBagComp = UE.UBagComponent.Get(UE.UGameplayStatics.GetPlayerController(self,0))
        if tBagComp then
            local TempInventoryIdentity = UE.FInventoryIdentity()
            TempInventoryIdentity.ItemID = ItemID
            TempInventoryIdentity.ItemInstanceID = ItemInstanceID
            local CurItemObj = tBagComp:GetInventoryInstance(TempInventoryIdentity)
            if CurItemObj then
                local HasIsActivelyDiscard = CurItemObj:HasItemAttribute("IsActivelyDiscard")
                if HasIsActivelyDiscard then
                    local CurIsActivelyDiscardValue = CurItemObj:GetItemAttributeFloat("IsActivelyDiscard")
                    if CurIsActivelyDiscardValue == 0 then
                        self.BP_DetailKeyMap:SetInteractionKeyWidgetVisibility("MouseRightKey.Discard", false)
                        self.BP_DetailKeyMap:SetInteractionKeyWidgetVisibility("Ctrl.MouseRightKey.DiscardCount", false)
                    end
                end
            end
        end
    end

    -- 获得表数据
    local StrItemID = tostring(ItemID)
    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, ItemID)
    if not IngameDT then
        return
    end
    local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, StrItemID)
    if not StructInfo_Item then
        return
    end

    -- 显示物品名称
    self:UpdateDetailNameText(StructInfo_Item.ItemName)

    -- 显示物品类型
    local TempItemTypeNameText = UE.UTableManagerSubsystem.GetIngameItemTypeName(self, StructInfo_Item.ItemType)
    self:UpdateItemTypeText(TempItemTypeNameText)

    -- 更新：拾取系统，对比信息
    -- 显示这个详细信息，发消息的来源类型（'PickupSystem'，'BagSystem'）
    local TempShowSourceType = InMsgBody.ShowSourceType
    if TempShowSourceType == ItemSystemHelper.ItemDetialInfoShowMsgSourceType.PickupSystem then
        self:UpdateCompareEnhanceAttributeInfo(StructInfo_Item.ItemType)
    else
        self.Canvas_Replace:SetVisibility(UE.ESlateVisibility.Collapsed)
    end


    -- 获得 Icon 图片
    local ImageIconSoftPathPtr = nil
    if StructInfo_Item.ItemType == ItemSystemHelper.NItemType.Weapon then
        local TempCurWeaponSkinId, TempDefaultWeaponSkinId, TempReplacedWeaponSkinId = self:GetImportantSkinIds(TempWeaponInstance)
        print("ItemDetailInfoUI:ShowDetailInfoByItemID [TempCurWeaponSkinId]=",TempCurWeaponSkinId,",[TempDefaultWeaponSkinId]=",TempDefaultWeaponSkinId,",[TempReplacedWeaponSkinId]=",TempReplacedWeaponSkinId)
        if TempCurWeaponSkinId then
            -- 获得武器的Icon，通过武器实例
            ImageIconSoftPathPtr = self:GetWeaponSkinItemIconByWeaponInstance(TempWeaponInstance)
            if not ImageIconSoftPathPtr then
                -- 获得武器的Icon，通过SkinId
                ImageIconSoftPathPtr = self:GetWeaponSkinItemIconBySkinId(TempCurWeaponSkinId)
            end
        end
        -- 别改了别删了求求了别改了不是第一次了
        if not ImageIconSoftPathPtr then
            -- 求求别改了，拾取列表也要用，那里拿不到WeaponInstance，只有传进来的skinid，求求别改了！！！！
            ImageIconSoftPathPtr = self:GetWeaponSkinItemIconBySkinId(ItemSkinId)
        end
        -- 别改了别删了求求了别改了不是第一次了
    end
    print("ItemDetailInfoUI:ShowDetailInfoByItemID [ImageIconSoftPathPtr]=",ImageIconSoftPathPtr)
    if not ImageIconSoftPathPtr then
        -- 获得物品的Icon
        ImageIconSoftPathPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(StructInfo_Item.ItemIconSoft)
    end
    if ImageIconSoftPathPtr then
        print("ItemDetailInfoUI:ShowDetailInfoByItemID [StructInfoEnhanceAttr.EnhanceIconSoft]=",StructInfo_Item.EnhanceIconSoft)
        self:UpdateIconFromSoftTexture(ImageIconSoftPathPtr)
    end

    -- 显示物品描述
    self:UpdateDetailDescribeText(StructInfo_Item.SimpleDescribe)

    -- 等级颜色
    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if PickupSetting then
        local BackgroundImagePath = PickupSetting.PickupBGImageMap:Find(StructInfo_Item.ItemLevel)
        local BackgroundImage = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(BackgroundImagePath)
        if BackgroundImage then
            self.Image_BG:SetBrushFromSoftTexture(BackgroundImage, true)
            self.Image_BG:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        else
            self.Image_BG:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end

    -- 词条
    local TempGameplayTag = UE.FGameplayTag()
    TempGameplayTag.TagName = GameDefine.NTag.TABLE_EnhanceAttribute
    local TempEnhanceAttributeDT = UE.UTableManagerSubsystem.GetDataTableByTag(self, TempGameplayTag)
    if TempEnhanceAttributeDT and EnhanceId then
        self.VerticalBox_Enhance:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        local StructInfoEnhanceAttr = UE.UDataTableFunctionLibrary.GetRowDataStructure(TempEnhanceAttributeDT, tostring(EnhanceId))
        if StructInfoEnhanceAttr then
            -- 更新图片
            local EnhanceIconSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(StructInfoEnhanceAttr.EnhanceIconSoft)
            if EnhanceIconSoftPtr and self.Image_Enhance then
                self.Image_Enhance:SetBrushFromSoftTexture(EnhanceIconSoftPtr, false)
            end

            -- 更新背景
            local EnhanceBgSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(StructInfoEnhanceAttr.EnhanceBgSoft)
            if EnhanceBgSoftPtr and self.Image_Enhance_Bg then
                self.Image_Enhance_Bg:SetBrushFromSoftTexture(EnhanceBgSoftPtr, false)
            end

            -- 更新名字
            if self.TextBlock_EnhanceTitle and self.TextBlock_EnhanceDescribe then
                self.TextBlock_EnhanceTitle:SetText(StructInfoEnhanceAttr.EnhanceName)
                self.TextBlock_EnhanceDescribe:SetText(StructInfoEnhanceAttr.EnhanceDecription)
            end
        end
    else
        self.VerticalBox_Enhance:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end


function ItemDetailInfoUI:ShowDetailInfoByEnhanceId(InMsgBody)
    if BridgeHelper.IsMobilePlatform() then
        return
    end

    -- 强化词条Id
    local TempEnhanceId = InMsgBody.EnhanceId

    -- 设置显示控件

    self:SetItemTypeTextVisibility(false)

    -- 声音
    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Hover_01")

    -- 刷新词条
    self:UpdateEnhanceInfoToMainInfo(TempEnhanceId)

    -- 操作指引
    local TempInteractionKey = InMsgBody.InteractionKeyName
    self.BP_DetailKeyMap:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.BP_DetailKeyMap:SetInteractionInfo(TempInteractionKey)

end


function ItemDetailInfoUI:UpdateEnhanceInfoToMainInfo(InEnhanceId)
    -- 刷新词条
    local TempGameplayTag = UE.FGameplayTag()
    TempGameplayTag.TagName = GameDefine.NTag.TABLE_EnhanceAttribute
    local TempEnhanceAttributeDT = UE.UTableManagerSubsystem.GetDataTableByTag(self, TempGameplayTag)
    if TempEnhanceAttributeDT and InEnhanceId then
        self.VerticalBox_Enhance:SetVisibility(UE.ESlateVisibility.Collapsed)
        local StructInfoEnhanceAttr = UE.UDataTableFunctionLibrary.GetRowDataStructure(TempEnhanceAttributeDT, tostring(InEnhanceId))
        if StructInfoEnhanceAttr then
            -- 更新词条Icon图片
            print("ItemDetailInfoUI:UpdateEnhanceInfoToMainInfo [StructInfoEnhanceAttr.EnhanceIconSoft]=",StructInfoEnhanceAttr.EnhanceIconSoft,",[InEnhanceId]=",InEnhanceId)
            local EnhanceIconSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(StructInfoEnhanceAttr.EnhanceIconSoft)
            if EnhanceIconSoftPtr then
                self:UpdateIconFromSoftTexture(EnhanceIconSoftPtr)
            end

            self:UpdateEnhanceBackground(StructInfoEnhanceAttr.EnhanceID)

            -- 更新词条名字
            self:UpdateDetailNameText(StructInfoEnhanceAttr.EnhanceName)

            -- 更新词条描述
            self:UpdateDetailDescribeText(StructInfoEnhanceAttr.EnhanceDecription)
        end
    end
end

function ItemDetailInfoUI:UpdateEnhanceBackground(EnhanceID)
    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self,EnhanceID)
    if IngameDT then
        local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(EnhanceID))
        local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
        if PickupSetting then
            local BackgroundImagePath = PickupSetting.PickupBGImageMap:Find(StructInfo_Item.ItemLevel)
            local BackgroundImage = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(BackgroundImagePath)
            if BackgroundImage then
                self.Image_BG:SetBrushFromSoftTexture(BackgroundImage, true)
                self.Image_BG:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
            else
                self.Image_BG:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        end
    end
end


function ItemDetailInfoUI:SetReplaceEnhanceInfoByItemObj(InInventoryInstance)
    local IsShowReplace = false
    local PC = UE.UGameplayStatics.GetPlayerController(self,0)
    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if InInventoryInstance then
        --设置词条
        if InInventoryInstance:HasItemAttribute("EnhanceAttributeId") then
            IsShowReplace = true
            local TempEnhanceId = InInventoryInstance:GetItemAttributeFString("EnhanceAttributeId")
            self:SetReplaceEnhance(TempEnhanceId)

            --设置图片
            local ItemIcon, RetItemIcon = UE.UItemSystemManager.GetItemDataFString(PC, InInventoryInstance.InventoryIdentity.ItemID,
                "ItemIcon", GameDefine.NItemSubTable.Ingame, "ItemDetailInfoUI:SetReplaceEnhanceInfoByItemObj")
            if RetItemIcon then
                print("ItemDetailInfoUI:SetReplaceEnhanceInfoByItemObj [InInventoryInstance.InventoryIdentity.ItemID]=", InInventoryInstance.InventoryIdentity.ItemID)
                local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(ItemIcon)
                self.Image_ReplaceItem:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
            end
            -- 等级颜色
            local ReplaceItemLevel, IsFindReplaceItemLevel = UE.UItemSystemManager.GetItemDataUInt8(PC, InInventoryInstance.InventoryIdentity.ItemID,
                "ItemLevel", GameDefine.NItemSubTable.Ingame, "ItemDetailInfoUI:SetReplaceEnhanceInfoByItemObj")
            if IsFindReplaceItemLevel and PickupSetting then
                local BackgroundImagePath = PickupSetting.PickupBGImageMap:Find(ReplaceItemLevel)
                local BackgroundImage = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(BackgroundImagePath)
                if BackgroundImage then
                    self.Image_ReplaceBG:SetBrushFromSoftTexture(BackgroundImage, false)
                end
            end

            -- 对比的名字
            if self.TextBlock_ReplaceEnhance_Name then
                local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(PC, InInventoryInstance.InventoryIdentity.ItemID)
                if IngameDT then
                    local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(InInventoryInstance.InventoryIdentity.ItemID))
                    if StructInfo_Item then
                        local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)
                        self.TextBlock_ReplaceEnhance_Name:SetText(TranslatedItemName)
                    end
                end
            end
        end
    end

    if IsShowReplace then
        self.Canvas_Replace:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    else
        self.Canvas_Replace:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end


function ItemDetailInfoUI:SetReplaceEnhance(InEnhanceId)
    local TempGameplayTag = UE.FGameplayTag()
    TempGameplayTag.TagName = GameDefine.NTag.TABLE_EnhanceAttribute
    local TempEnhanceAttributeDT = UE.UTableManagerSubsystem.GetDataTableByTag(self, TempGameplayTag)
    if TempEnhanceAttributeDT and InEnhanceId then
        local StructInfoEnhanceAttr = UE.UDataTableFunctionLibrary.GetRowDataStructure(TempEnhanceAttributeDT, tostring(InEnhanceId))
        if StructInfoEnhanceAttr then
            -- 更新图片
            local EnhanceIconSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(StructInfoEnhanceAttr.EnhanceIconSoft)
            if EnhanceIconSoftPtr and self.Image_ReplaceEnhance then
                self.Image_ReplaceEnhance:SetBrushFromSoftTexture(EnhanceIconSoftPtr, false)
            end

            -- 更新图片
            local EnhanceBgSoftPtr = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(StructInfoEnhanceAttr.EnhanceBgSoft)
            if EnhanceBgSoftPtr and self.Image_ReplaceEnhance_Bg then
                self.Image_ReplaceEnhance_Bg:SetBrushFromSoftTexture(EnhanceBgSoftPtr, false)
            end

            -- 更新名字
            if self.TextBlock_ReplaceEnhanceTitle and self.TextBlock_ReplaceEnhanceDescribe then
                self.TextBlock_ReplaceEnhanceTitle:SetText(StructInfoEnhanceAttr.EnhanceName)
                self.TextBlock_ReplaceEnhanceDescribe:SetText(StructInfoEnhanceAttr.EnhanceDecription)
            end
        end
    end
end

function ItemDetailInfoUI:GetImportantSkinIds(InGAWeaponInstance)
    local TempCurWeaponSkinId = -1
    local TempDefaultWeaponSkinId = -1
    local TempReplacedWeaponSkinId = -1

    if not InGAWeaponInstance then
        return TempCurWeaponSkinId, TempDefaultWeaponSkinId, TempReplacedWeaponSkinId
    end

    local TempAvatarManagerSubsystem = UE.UAvatarManagerSubsystem.Get(self)
    if not TempAvatarManagerSubsystem then
        return TempCurWeaponSkinId, TempDefaultWeaponSkinId, TempReplacedWeaponSkinId
    end

    local TempTargetSlot = UE.FGameplayTag()
    TempTargetSlot.TagName = GameDefine.NTag.WEAPON_SKIN_ATTACHSLOT_GUNBODY
    TempCurWeaponSkinId = TempAvatarManagerSubsystem:GetWeaponCurrentAvatarID(InGAWeaponInstance, TempTargetSlot)
    TempDefaultWeaponSkinId = TempAvatarManagerSubsystem:GetWeaponDefaultAvatarID(InGAWeaponInstance, TempTargetSlot)
    TempReplacedWeaponSkinId = TempAvatarManagerSubsystem:GetWeaponReplacedAvatarIDByWeaponInst(InGAWeaponInstance)

    return TempCurWeaponSkinId, TempDefaultWeaponSkinId, TempReplacedWeaponSkinId
end

function ItemDetailInfoUI:GetWeaponSkinItemIconByWeaponInstance(InWeaponInstance)
    if not InWeaponInstance then
        return nil
    end

    local TempAvatarManagerSubsystem = UE.UAvatarManagerSubsystem.Get(self)
    if not TempAvatarManagerSubsystem then
        return nil
    end

    local TempTargetSlot = UE.FGameplayTag()
    TempTargetSlot.TagName = GameDefine.NTag.WEAPON_SKIN_ATTACHSLOT_GUNBODY
    local TempWeaponSkinId = TempAvatarManagerSubsystem:GetWeaponCurrentAvatarID(InWeaponInstance, TempTargetSlot)
    
    local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, TempWeaponSkinId)
    if not WeaponSkinCfg then
        return nil
    end
    
    local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(WeaponSkinCfg.WeaponIconImage)
    return ImageSoftObjectPtr
end

function ItemDetailInfoUI:GetWeaponSkinItemIconBySkinId(InSkinId)
    local ReturnImageIconSoftPathPtr = nil
    local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, InSkinId)
    if WeaponSkinCfg then
        print("ItemDetailInfoUI:GetWeaponSkinItemIconBySkinId [InSkinId]=",InSkinId,",[WeaponSkinCfg.WeaponIconImage]=",WeaponSkinCfg.WeaponIconImage)
        ReturnImageIconSoftPathPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(WeaponSkinCfg.WeaponIconImage)
    end

    return ReturnImageIconSoftPathPtr
end

--替换词条
function ItemDetailInfoUI:UpdateCompareEnhanceAttributeInfo(InItemType)
    local PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not PC then return end
    local CH = PC:K2_GetPawn()
    if not CH then return end
    local TargetItemObj = nil
    local EquipComp = UE.UEquipmentStatics.GetEquipmentComponent(CH)
    local tBagComp = UE.UBagComponent.Get(PC)

    if InItemType == ItemSystemHelper.NItemType.Weapon then

        if EquipComp and tBagComp then
            local WeaponNum = tBagComp:GetNumInItemSlotsByItemType(ItemSystemHelper.NItemType.Weapon)
            if WeaponNum >= 2 then
                local CurrentEquipWeapon = EquipComp:GetEquippedInstance()
                if CurrentEquipWeapon and CurrentEquipWeapon.GetInventoryIdentity then
                    local CurrentInventoryIdentity = CurrentEquipWeapon:GetInventoryIdentity()
                    local CurItemType, CurRetItemType = UE.UItemSystemManager.GetItemDataFName(self, CurrentInventoryIdentity.ItemID,
                        "ItemType", GameDefine.NItemSubTable.Ingame, "ItemDetailInfoUI:UpdateCompareEnhanceAttributeInfo")
                    if CurRetItemType then
                        if CurItemType == ItemSystemHelper.NItemType.Weapon then
                            -- 当前持有武器
                            TargetItemObj = tBagComp:GetInventoryInstance(CurrentInventoryIdentity)
                        else
                            -- 不是武器，换1
                            local ItemSlot1, HasSlot1 = tBagComp:GetItemSlotByTypeAndSlotID(ItemSystemHelper.NItemType.Weapon, 1)
                            if HasSlot1 then
                                TargetItemObj = tBagComp:GetInventoryInstance(ItemSlot1.InventoryIdentity)
                            end
                        end
                    end
                else
                    -- 空手，强制换1
                    local ItemSlot1, HasSlot1 = tBagComp:GetItemSlotByTypeAndSlotID(ItemSystemHelper.NItemType.Weapon, 1)
                    if HasSlot1 then
                        TargetItemObj = tBagComp:GetInventoryInstance(ItemSlot1.InventoryIdentity)
                    end
                end
            end
        end
    elseif InItemType == ItemSystemHelper.NItemType.ArmorHead or InItemType == ItemSystemHelper.NItemType.ArmorBody or InItemType == ItemSystemHelper.NItemType.Bag then
        local ItemObjs = tBagComp:GetSlotItemObjects(InItemType)
        if ItemObjs:Length() > 0 then
            local TargetIndex = 1 -- 头盔、护甲、背包，直接使用数组的第一个
            TargetItemObj = ItemObjs:Get(TargetIndex)
        end
    end

    self:SetReplaceEnhanceInfoByItemObj(TargetItemObj)
end


-- 处理详细信息面板的显示位置
function ItemDetailInfoUI:ChangeDetailLoc(HoverWidget,ParentWidget,IsShowAtLeftSide,ItemID)
    -- 显示的情况
    local SituationIndex = nil
    local AnchorWidget = nil
    if ParentWidget ~= nil then
        if IsShowAtLeftSide then
            SituationIndex = 2
        else
            SituationIndex = 1
        end
        AnchorWidget = ParentWidget
    else
        SituationIndex = 3
        AnchorWidget = HoverWidget
    end

    if AnchorWidget == nil then
        return
    end

    local PlayerWidgetGeometry = UE.UWidgetLayoutLibrary.GetPlayerScreenWidgetGeometry(UE.UGameplayStatics.GetPlayerController(self,0))
    if SituationIndex == 1 then
        local DetailUIPos = UE.FVector2D()
        local NewAlignment = UE.FVector2D()
        -- X
        local AnchorWidgetGeometry = AnchorWidget:GetCachedGeometry()
        local PixelPosition,ViewportPosition = UE.USlateBlueprintLibrary.LocalToViewport(self,AnchorWidgetGeometry,UE.FVector2D())
        local LocalAnchorWidgetSize = UE.USlateBlueprintLibrary.GetLocalSize(AnchorWidgetGeometry)
        DetailUIPos.X = ViewportPosition.X + LocalAnchorWidgetSize.X + self.ShowAtSideDistanceX -- 68
       -- DetailUIPos.X = ViewportPosition.X  + self.ShowAtSideDistanceX
        -- Y
        local HoverWidgetGeometry = HoverWidget:GetCachedGeometry()
        local H_PixelPosition,H_ViewportPosition = UE.USlateBlueprintLibrary.LocalToViewport(self,HoverWidgetGeometry,UE.FVector2D())
        local SelfWidgetGeometry = self:GetCachedGeometry()
        local LocalSelfWidgetSize = UE.USlateBlueprintLibrary.GetLocalSize(SelfWidgetGeometry)
        local ViewportSize = UE.USlateBlueprintLibrary.GetLocalSize(PlayerWidgetGeometry)
        local ChangeDirY = H_ViewportPosition.Y + LocalSelfWidgetSize.Y
        if ViewportSize.Y < ChangeDirY then
            NewAlignment.Y = 1
            DetailUIPos.Y = ViewportPosition.Y + LocalAnchorWidgetSize.Y
        else
            DetailUIPos.Y = H_ViewportPosition.Y
        end
        -- Final set
        local CanvasPanelSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self)
        CanvasPanelSlot:SetAlignment(NewAlignment)
        CanvasPanelSlot:SetPosition(DetailUIPos)
    elseif SituationIndex == 2 then
        local DetailUIPos = UE.FVector2D()
        local NewAlignment = UE.FVector2D(1,0)
        -- X
        local AnchorWidgetGeometry = AnchorWidget:GetCachedGeometry()
        local PixelPosition,ViewportPosition = UE.USlateBlueprintLibrary.LocalToViewport(self,AnchorWidgetGeometry,UE.FVector2D())
        local LocalAnchorWidgetSize = UE.USlateBlueprintLibrary.GetLocalSize(AnchorWidgetGeometry)
        DetailUIPos.X = ViewportPosition.X - self.ShowAtSideDistanceX
        -- Y
        local HoverWidgetGeometry = HoverWidget:GetCachedGeometry()
        local H_PixelPosition,H_ViewportPosition = UE.USlateBlueprintLibrary.LocalToViewport(self,HoverWidgetGeometry,UE.FVector2D())
        local SelfWidgetGeometry = self:GetCachedGeometry()
        local LocalSelfWidgetSize = UE.USlateBlueprintLibrary.GetLocalSize(SelfWidgetGeometry)
        local ViewportSize = UE.USlateBlueprintLibrary.GetLocalSize(PlayerWidgetGeometry)
        local ChangeDirY = H_ViewportPosition.Y + LocalSelfWidgetSize.Y
        if ViewportSize.Y < ChangeDirY then
            NewAlignment.Y = 1
            DetailUIPos.Y = ViewportPosition.Y + LocalAnchorWidgetSize.Y
        else
            DetailUIPos.Y = H_ViewportPosition.Y
        end
        -- Final set
        local CanvasPanelSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self)
        CanvasPanelSlot:SetAlignment(NewAlignment)
        CanvasPanelSlot:SetPosition(DetailUIPos)
    elseif SituationIndex == 3 then
        local DetailUIPos = UE.FVector2D()
        local NewAlignment = UE.FVector2D(1,0)
        -- X
        local AnchorWidgetGeometry = AnchorWidget:GetCachedGeometry()
        local PixelPosition,ViewportPosition = UE.USlateBlueprintLibrary.LocalToViewport(self,AnchorWidgetGeometry,UE.FVector2D())
        local LocSizeAnchorWidget = UE.USlateBlueprintLibrary.GetLocalSize(AnchorWidgetGeometry)
        --DetailUIPos.X = ViewportPosition.X - 5
        DetailUIPos.X = ViewportPosition.X - self.ShowAtSideDistanceX 
        -- Y
        local SelfWidgetGeometry = self:GetCachedGeometry()
        --local SelfWidgetGeometry = self:GetPaintSpaceGeometry()
        local LocalSelfWidgetSize = UE.USlateBlueprintLibrary.GetLocalSize(SelfWidgetGeometry)
        local RealSize = self.Slot:GetSize()
        local ViewportSize = UE.USlateBlueprintLibrary.GetLocalSize(PlayerWidgetGeometry)
        local bIsAttachment = AnchorWidget.AttachmentEffectInstanceID ~= nil
        if bIsAttachment then
            local ChangeDirY = ViewportPosition.Y - LocalSelfWidgetSize.Y 
            if ChangeDirY > 0  then
                NewAlignment.Y = 1
                DetailUIPos.Y = ViewportPosition.Y
            else
                DetailUIPos.Y = ViewportPosition.Y
            end
        else
            local ChangeDirY = ViewportPosition.Y + LocalSelfWidgetSize.Y
            print("(Wzp)ItemDetailInfoUI >> ChangeDetailLoc > [ViewportPosition.Y = ",ViewportPosition.Y,"] [ LocalSelfWidgetSize.Y=", LocalSelfWidgetSize.Y,"] [ChangeDirY=",ChangeDirY,"] [RealSize=",RealSize,"]")
            print("(Wzp)ItemDetailInfoUI >> ChangeDetailLoc > [ViewportSize.Y = ",ViewportSize.Y,"]")
            if ChangeDirY > ViewportSize.Y then
                -- DetailUIPos.Y = ViewportPosition.Y - LocSizeAnchorWidget.Y
                NewAlignment.Y = 1
                 DetailUIPos.Y = ViewportPosition.Y + LocSizeAnchorWidget.Y-- * 0.5

             else
                 DetailUIPos.Y = ViewportPosition.Y
                 NewAlignment.Y = 0
             end
             local bsize = ViewportSize.Y < ChangeDirY
             print("(Wzp)ItemDetailInfoUI >> ChangeDetailLoc > [DetailUIPos.Y = ",DetailUIPos.Y,"] [ViewportSize.Y < bsize =",bsize,"]")
        end

        -- Final set
        local CanvasPanelSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self)
        CanvasPanelSlot:SetAlignment(NewAlignment)
        CanvasPanelSlot:SetPosition(DetailUIPos)
    end
end


function ItemDetailInfoUI:SetLevelColor(LevelNumber)
    local LinearColor = self.LevelColorMap:Find(LevelNumber)
    if LinearColor then
        self.Border_LevelColor:SetBrushColor(LinearColor)
    end
end


-- 更新：物品描述信息
function ItemDetailInfoUI:UpdateDetailDescribeText(InText)
    if self.TextBlock_DetailDescribe then
        local TranslatedItemName = StringUtil.Format(InText)
        self.TextBlock_DetailDescribe:SetText(TranslatedItemName)
    end
end


-- 更新：物品类型
function ItemDetailInfoUI:UpdateItemTypeText(InText)
    if self.TextBlock_ItemType then
        local TranslatedItemTypeName = StringUtil.Format(InText)
        self.TextBlock_ItemType:SetText(TranslatedItemTypeName)
    end
end


-- 更新控件显示：物品类型
function ItemDetailInfoUI:SetItemTypeTextVisibility(InBool)
    if self.TextBlock_ItemType then
        if InBool then
            self.TextBlock_ItemType:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.TextBlock_ItemType:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end


-- 更新：描述信息Icon
function ItemDetailInfoUI:UpdateIconFromSoftTexture(InIconSoftPathPtr)
    if self.Image_Item then
        self.Image_Item:SetBrushFromSoftTexture(InIconSoftPathPtr, true)
    end
end


-- 更新：描述信息名字
function ItemDetailInfoUI:UpdateDetailNameText(InText)
    if self.TextBlock_ItemName then
        local TranslatedItemName = StringUtil.Format(InText)
        self.TextBlock_ItemName:SetText(TranslatedItemName)
    end
end


return ItemDetailInfoUI