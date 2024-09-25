require "UnLua"
require ("InGame.BRGame.ItemSystem.ItemSystemHelper")
require ("Common.Utils.StringUtil")

local PickItemDetailUI = Class("Common.Framework.UserWidget")

function PickItemDetailUI:Initialize(Initializer)
    self.HandleSelect = false
    self.IsHoldLeftMouseButton = false
    self.PickInfoMode = 2
    self.HoldingTime = 0.0
    self.HoldToPickTipId = "HoldToPick"
end

function PickItemDetailUI:OnInit()
    self.GMPSetPickInfoMode = ListenObjectMessage(nil, "PickDropSystem.UpdatePickInfoMode", self, self.SetPickInfoMode)
    self:SetPickInfoMode()
    self:HandleItemType()
    self:HandleBetterItem()
    self:UnselectState()
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.MsgList = {
        { MsgName = GameDefine.Msg.InventoryItemSlotDragOnDrop,             Func = self.OnInventoryItemDragOnDrop,      bCppMsg = false },
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickPart,       Func = self.OnPickPart,                 bCppMsg = true, WatchedObject = self.LocalPC},
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickHalf,       Func = self.OnPickAll,                  bCppMsg = true, WatchedObject = self.LocalPC},
    }
    UserWidget.OnInit(self)
end

function PickItemDetailUI:OnShow()
    print("[Wzp]PickItemDetailUI >> OnShow")
end

function PickItemDetailUI:OnDestroy()
    if self.GMPSetPickInfoMode then
        UnListenObjectMessage("PickDropSystem.UpdatePickInfoMode", self, self.GMPSetPickInfoMode)
    end
    
    --self:Release()
    self.HandleSelect = nil
    self.IsHoldLeftMouseButton = nil
    self.PickupObjArray:Clear()
    self.HoldingTime = 0.0
    
    UserWidget.OnDestroy(self)
end

function PickItemDetailUI:Tick(InMyGeometry, InDeltaTime)
    if self.IsHoldLeftMouseButton then
        local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
        if not PickupSetting then
            return
        end
        self.HoldingTime = self.HoldingTime + InDeltaTime
        UE.UTipsManager.GetTipsManager(self):UpdateTipsUIDataByTipsId(self.HoldToPickTipId, self.HoldingTime,UE.FGenericBlackboardContainer(), self)
        if self.HoldingTime >= PickupSetting.HoldTime then
            self:HoldToPickup()
            self.HoldingTime = 0.0
            self.IsHoldLeftMouseButton = false
        end
    end
end

function PickItemDetailUI:HandleBetterItem()
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

    if TempItemType == "Weapon" and self.BulletTipIcons and self.BulletTipIcons:Length() > 0 then
        self.GUIImage_Bullet:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local BulletID, IsFindBullet = UE.UItemSystemManager.GetItemDataInt32(PlayerController, self.ItemID,
            "BulletItemID", GameDefine.NItemSubTable.Ingame, "PickItemDetailUI:HandleBetterItem")
        if not IsFindBullet then
            return
        end

        local TargetImageIcon = self.BulletTipIcons:Find(BulletID)
        if not TargetImageIcon then
            return
        end
        self.GUIImage_Bullet:SetBrushFromTexture(TargetImageIcon)
    else
        self.GUIImage_Bullet:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if not PickupSetting then
        return
    end

    if self.WidgetSwitcher_Better then
        self.WidgetSwitcher_Better:SetVisibility(UE.ESlateVisibility.Collapsed)
        if PickupSetting.ItemTypeNeedCompare:Contains(TempItemType) then
            self.IsBetter = TempPickupObj:IsBetter(tPawn)
            if self.IsBetter > 0 then
                self.WidgetSwitcher_Better:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
                self.WidgetSwitcher_Better:SetActiveWidgetIndex(0)
                -- VX
                if self.vx_hud_pick_better ~= nil then self:VXE_HUD_Tips_BetterGlow() end
            elseif self.IsBetter < 0 then
                self.WidgetSwitcher_Better:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
                self.WidgetSwitcher_Better:SetActiveWidgetIndex(1)
            end
        end
    end

end

function PickItemDetailUI:HandleItemType()
    if self.isInSimpleList then
        self.TextBlock_ItemType:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    else
        self.TextBlock_ItemType:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function PickItemDetailUI:SetPickInfoMode()
    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if PickupSetting and self.isInSimpleList then
        self.PickInfoMode = PickupSetting.PickInfoMode
    end

    if self.PickInfoMode == 1 then
        self.Border_Main:SetVisibility(UE.ESlateVisibility.Collapsed)
    elseif self.PickInfoMode == 2 then
        self.Border_Main:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    elseif self.PickInfoMode == 3 then
        self.Border_Main:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    end
end

function PickItemDetailUI:IsInfoValid()
    if not self.PickupObjArray then
        return false
    end
    for i = 1, self.PickupObjArray:Length() do
        local TestPickupObj = self.PickupObjArray:Get(i)
        if not UE.UKismetSystemLibrary.IsValid(TestPickupObj) then
            return false
        end
        
        if not TestPickupObj.ItemInfo then
            return false
        end

        if TestPickupObj.ItemInfo.ItemID <= 0 or TestPickupObj.ItemInfo.ItemNum <= 0 then
            return false
        end
    end

    return true
end

function PickItemDetailUI:SelectedState()
    local Color = self.SelectColorStateMap:Find("Selected")
    self.TextBlock_Name:SetColorAndOpacity(Color)
    self.ImageHover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- self.BgBlur:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.ImgBg:SetVisibility(UE.ESlateVisibility.Collapsed)
    local AlphaMask = self.BgBlur.AlphaMaskBrush
    UE.UWidgetBlueprintLibrary.SetBrushResourceToTexture(AlphaMask,nil)
end

function PickItemDetailUI:UnselectState()
    local Color = self.SelectColorStateMap:Find("Unselect")
    self.TextBlock_Name:SetColorAndOpacity(Color)
    self.ImageHover:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self.BgBlur:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.ImgBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local AlphaMask = self.BgBlur.AlphaMaskBrush
    UE.UWidgetBlueprintLibrary.SetBrushResourceToTexture(AlphaMask,self.AlphaMask) 
end

function PickItemDetailUI:HoldToPickup()
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPawn(LocalPC)
    if not LocalPC or not LocalPCPawn then
        return
    end
    for index = 1, self.PickupObjArray:Length() do
        local PrePickObj = self.PickupObjArray:Get(index)
        if UE.UKismetSystemLibrary.IsValid(PrePickObj) then
            local TempGameplayTag = UE.FGameplayTag()
            TempGameplayTag.TagName = "PickSystem.PickMode.Hold"
            local TempTagContainer = UE.FGameplayTagContainer()
            TempTagContainer.GameplayTags:Add(TempGameplayTag)
            UE.UPickupStatics.TryPickupItem(LocalPCPawn, PrePickObj, 0, UE.EPickReason.PR_Player, TempTagContainer)
        end
    end
    UE.UTipsManager.GetTipsManager(self):RemoveTipsUI(self.HoldToPickTipId)
end

function PickItemDetailUI:OnMouseButtonDown(MyGeometry, MouseEvent)
    self.bStartDetectDrag = false
    if not self:IsInfoValid() then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    --开始记录初始像素点
    self.MouseDwonPos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if MouseKey then
        if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton or MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton then
            if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton then
                self.IsHoldLeftMouseButton = true
                self.HoldingTime = 0.0
                UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId(self.HoldToPickTipId,-1,UE.FGenericBlackboardContainer(),self)
                return UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent,self, MouseKey)
            end
            self.bLeftOrRightMouseButtonDown = true
        end

    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function PickItemDetailUI:IsForceHold()
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPawn(LocalPC)
    if not LocalPC or not LocalPCPawn then
        return false
    end
    --判断是不是需要长按的pickup
    for index = 1, self.PickupObjArray:Length() do
        local PrePickObj = self.PickupObjArray:Get(index)
        if PrePickObj and PrePickObj:GetPickMode(LocalPCPawn,0,0) == UE.EPickupMode.PM_Hold then
            return true
        end
    end
    return false
end

function PickItemDetailUI:OnPickPart(InInputData)
    if not self.HandleSelect then
        return
    end
    local ItemType = UE.UItemSystemManager.GetItemDataFName(self,  self.ItemID, "ItemType", GameDefine.NItemSubTable.Ingame, "")
    if ItemType == ItemSystemHelper.NItemType.Weapon then
        if self:IsWeaponFull() then
            return
        end

        -- 未满 直接装备
        local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
        local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPawn(LocalPC)
        if not LocalPC or not LocalPCPawn then
            return
        end
        local PrePickObj = self.PickupObjArray:Get(1)
        if UE.UKismetSystemLibrary.IsValid(PrePickObj) then
            UE.UPickupStatics.TryPickupItem(LocalPCPawn, PrePickObj, 0, UE.EPickReason.PR_Player, UE.FGameplayTagContainer())
        end
    else--非武器拾取一堆
        self:PickPart()
    end
end

function PickItemDetailUI:OnPickAll(InInputData)
    if not self.HandleSelect then
        return
    end
    
    local ItemType = UE.UItemSystemManager.GetItemDataFName(self,  self.ItemID, "ItemType", GameDefine.NItemSubTable.Ingame, "")
    if ItemType == ItemSystemHelper.NItemType.Weapon then
        if not self:IsWeaponFull() then
            return
        end
        self:ReplaceCurrentWeapon()
    else
        -- 非 武器 拾取全部
        local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
        local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPawn(LocalPC)
        if not LocalPC or not LocalPCPawn then
            return
        end
        -- 如果IA配置为非一次性触发 会持续调用拾取函数
        for index = 1, self.PickupObjArray:Length() do
            local PrePickObj = self.PickupObjArray:Get(index)
            if UE.UKismetSystemLibrary.IsValid(PrePickObj) then
                UE.UPickupStatics.TryPickupItem(LocalPCPawn, PrePickObj, 0, UE.EPickReason.PR_Player, UE.FGameplayTagContainer())
            end
        end
    end
end

function PickItemDetailUI:IsWeaponFull()
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPawn(LocalPC)
    if not LocalPC or not LocalPCPawn then
        return false
    end
    local TempBagComp = UE.UBagComponent.Get(LocalPC)
    if not TempBagComp then
        return false
    end

    local WeaponItmeObjectArray = TempBagComp:GetItemByItemType(ItemSystemHelper.NItemType.Weapon)
    return WeaponItmeObjectArray and WeaponItmeObjectArray:Length() == 2
end

-- 武器 装备已满 替换当前手持武器
function PickItemDetailUI:ReplaceCurrentWeapon()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)

    local TempBagComp = UE.UBagComponent.Get(PlayerController)
    if not TempBagComp then
        return
    end

    local SlotData = TempBagComp:GetSlotsByType("Weapon")
    local WeaponSlotID = 1
    for i = 1, SlotData:Num() do
        local TempSlot = SlotData:GetRef(i)
        if TempSlot.bActive then -- 当前手持武器
            WeaponSlotID = TempSlot.SlotID
            break
        end
    end

    local TempGameplayTag = UE.FGameplayTag()
    if WeaponSlotID == 1 then
        TempGameplayTag.TagName = "InventoryItem.TryAddToSlot.1"
    elseif WeaponSlotID == 2 then
        TempGameplayTag.TagName = "InventoryItem.TryAddToSlot.2"
    end

    local TempTagContainer = UE.FGameplayTagContainer()
    TempTagContainer.GameplayTags:Add(TempGameplayTag)

    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPawn(PlayerController)
    if LocalPCPawn then
        for index = 1, self.PickupObjArray:Length() do
            local CurrentPickupObj = self.PickupObjArray:Get(index)
            if CurrentPickupObj then
                UE.UPickupStatics.TryPickupItem(LocalPCPawn, CurrentPickupObj,0, UE.EPickReason.PR_Player,TempTagContainer)
            end
        end
    end
end

function PickItemDetailUI:PickPart()
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPawn(LocalPC)
    if not LocalPC or not LocalPCPawn then
        return
    end
    local CurQuickDiscardNum, IsExistNum = UE.UItemSystemManager.GetItemDataInt32(self, self.ItemID, "InventoryQuickDiscardNum", GameDefine.NItemSubTable.Ingame,"PickItemDetailUI:OnMouseButtonUp")
    if IsExistNum and self.PickupObjArray then
        for index = 1, self.PickupObjArray:Length() do
            local PrePickObj = self.PickupObjArray:Get(index)
            if CurQuickDiscardNum <= 0 then
                break
            end
            local TempGameplayTag = UE.FGameplayTag()
            TempGameplayTag.TagName = "PickSystem.PickMode.Tap"
            local TempTagContainer = UE.FGameplayTagContainer()
            TempTagContainer.GameplayTags:Add(TempGameplayTag)
        
            if UE.UKismetSystemLibrary.IsValid(PrePickObj) and PrePickObj.ItemInfo.ItemNum <= CurQuickDiscardNum then
                UE.UPickupStatics.TryPickupItem(LocalPCPawn, PrePickObj, 0, UE.EPickReason.PR_Player, TempTagContainer)
                CurQuickDiscardNum = CurQuickDiscardNum - PrePickObj.ItemInfo.ItemNum
            else
                UE.UPickupStatics.TryPickupItem(LocalPCPawn, PrePickObj, CurQuickDiscardNum, UE.EPickReason.PR_Player, TempTagContainer)
                break
            end
        end
    end
end

function PickItemDetailUI:OnMouseButtonUp(MyGeometry, MouseEvent)
    self.bStartDetectDrag = false
    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if MouseKey then
        if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton or MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton then
            self.bLeftOrRightMouseButtonDown = false 
        end
    end
    
    self.CurMousePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    local CurDis = UE.UKismetMathLibrary.Distance2D(self.CurMousePos, self.MouseDwonPos)
    local bShouldClicked = CurDis <= (self.ClickDistance and self.ClickDistance or 10)--校验像素距离是否超限

    self.MouseDwonPos = UE.FVector2D(0.0)
    self.CurMousePos = UE.FVector2D(0.0)
    if not bShouldClicked then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    if not MouseKey then return end
    print("PickItemDetailUI:OnMouseButtonUp",MouseKey.KeyName,self:IsInfoValid(),GameDefine.NInputKey.MiddleMouseButton)
    if (MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton or MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton)
        and self:IsInfoValid() then
        UE.UTipsManager.GetTipsManager(self):RemoveTipsUI(self.HoldToPickTipId)
        if not self.HandleSelect then
            return
        end

        local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
        local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPawn(LocalPC)
        if not LocalPC or not LocalPCPawn then
            return
        end

        -- 点击执行拾取部分
        if not self:IsForceHold() and self.IsHoldLeftMouseButton then
            --普通抬起
            -- 查询最小堆叠数，现在叫快捷丢弃，点一下捡多少=点一下丢多少  没毛病
            self:PickPart()
        end
        UE.UTipsManager.GetTipsManager(self):RemoveTipsUI(self.HoldToPickTipId)

        self.IsHoldLeftMouseButton = false
    elseif MouseKey.KeyName == GameDefine.NInputKey.MiddleMouseButton and self:IsInfoValid() then
        local PrePickObj = self.PickupObjArray:Get(1)

        local AdvanceMarkBussinessComponent = UE.UAdvanceMarkBussinessComponent.GetAdvanceMarkBussinessComponentClientOnly(self)
        if AdvanceMarkBussinessComponent then
            -- body
            AdvanceMarkBussinessComponent:MarkPickUpListObj(PrePickObj, self.ItemID)
        end
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end


function PickItemDetailUI:AddPickupObj(InPickupObj)
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

function PickItemDetailUI:SetDetail(InPickupObj, ParentWidget)
    if self.InitSizeBoxWidth == 0.0 then
        self.InitSizeBoxWidth = self.SizeBox_BarArmor.WidthOverride
    end
    
    if not UE.UKismetSystemLibrary.IsValid(InPickupObj) then
        return
    end

    self.SkinId = 0
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
    if not SubTable then
        return
    end
    -- 设置物品类型
    local CurItemType, IsExistType = SubTable:BP_FindDataFName(StrItemID, "ItemType")
    if IsExistType then
        local TempItemTypeName = UE.UTableManagerSubsystem.GetIngameItemTypeName(self, CurItemType)
        local TranslatedItemTypeName = StringUtil.Format(TempItemTypeName)
        self.TextBlock_ItemType:SetText(TranslatedItemTypeName)
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
        self.SkinId = InPickupObj:GetSkinId()
        local ImageSoftObjectPtr = self:GetImageAssetFromSkinID(InPickupObj.ItemInfo.ItemID, self.SkinId)
        if ImageSoftObjectPtr then
            self.Image_Content:SetBrushFromSoftTexture(ImageSoftObjectPtr,true)
        end
        if self.Overlay_WeaponSkinName then
            self.Overlay_WeaponSkinName:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
            self:SetWeaponSkinNameBySkinId(self.SkinId)
            self:SetWeaponSkinBgColorBySkinId(self.SkinId)
        end
    else
        if self.Overlay_WeaponSkinName then
            self.Overlay_WeaponSkinName:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        -- 设置图片
        local CurItemIcon, IsExistIcon = SubTable:BP_FindDataFString(StrItemID,"ItemIcon")
        if IsExistIcon then
            local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurItemIcon)
            self.Image_Content:SetBrushFromSoftTexture(ImageSoftObjectPtr,true)
        end
    end


    -- 倍镜特殊处理
    local MiscSystemIns = UE.UMiscSystem.GetMiscSystem(self)
    local MagnifierType = MiscSystemIns.MagnifierTypeMap:Find(self.ItemID)
    print("[Wzp]PickItemDetailUI >> SetDetail MagnifierType=",MagnifierType," self.ItemID=",self.ItemID)
    self.Text_ScaleMutiplay:SetVisibility(MagnifierType and UE.ESlateVisibility.SelfHitTestInvisible or
                                            UE.ESlateVisibility.Collapsed)
    print("[Wzp]PickItemDetailUI >> SetDetail GetObjectName=",GetObjectName(self))
    print("[Wzp]PickItemDetailUI >> SetDetail self.Text_ScaleMutiplay=",self.Text_ScaleMutiplay)                                       
    if MagnifierType then
        -- 显示倍镜倍率文本
        self.Text_ScaleMutiplay:SetText(MagnifierType.Multiple)
    end

    --如果最大数量为1，不显示数量文本
    local TempMaxStack, IsFindTempMaxStack = UE.UItemSystemManager.GetItemDataInt32(self,self.ItemID, "MaxStack",GameDefine.NItemSubTable.Ingame,"ItemSlotNormal:SetItemInfo")
    local bIsShowItemNum = TempMaxStack > 1
    print("[Wzp]PickItemDetailUI >> SetDetail bIsShowItemNum=",bIsShowItemNum,"TempMaxStack=",TempMaxStack)

    if bIsShowItemNum then
            -- 设置个数
        self.TextBlock_Num:SetText(self.ItemNum)
    end
    self.TextBlock_Num:SetVisibility(bIsShowItemNum and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Hidden )




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
    
    --设置护甲类型能量值
    if IsExistType and IsFindItemLevel then
        if CurItemType == ItemSystemHelper.NItemType.ArmorBody then
            self.BarArmor:SetVisibility(UE.ESlateVisibility.HitTestInvisible)

            local AttributeArray = InPickupObj.ItemInfo.Attribute
            local CurArmor = 0
            local MaxArmor = 0
            for i = 1, AttributeArray:Length(), 1 do
                local att = AttributeArray:GetRef(i)
                if UE.UPickupStatics.IsFNameEqual(att.AttributeName,ItemSystemHelper.NItemAttrName.ArmorShield) then
                    CurArmor = att.FloatValue
                elseif UE.UPickupStatics.IsFNameEqual(att.AttributeName,ItemSystemHelper.NItemAttrName.MaxArmorShield) then
                    MaxArmor = att.FloatValue
                end
            end

            local NewPercent = (CurArmor > 0) and (CurArmor / MaxArmor) or 0
            --用材质之后修改参数实现
            self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("Value", NewPercent)
            local NewTxt = math.floor(CurArmor).. "/".. math.floor(MaxArmor)
            self.BarArmor:SetToolTipText(NewTxt)
            --这里开始使用MiscSystem的颜色
            local MiscSystem = UE.UMiscSystem.GetMiscSystem(self)
            local NewSizeBox_BarArmorSize = (self.InitSizeBoxWidth / 4)*ItemLevel
            self.SizeBox_BarArmor:SetWidthOverride(NewSizeBox_BarArmorSize)
            self.BarArmor:GetDynamicMaterial():SetScalarParameterValue("SegmentNumber", ItemLevel)
            local ArmorLvColor = MiscSystem.BarArmorAttributes:FindRef(ItemLevel).ArmorColor
            self.BarArmor:GetDynamicMaterial():SetVectorParameterValue("InnerFrontColor",ArmorLvColor)
        else
            self.BarArmor:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end

    --设置词条
    if InPickupObj:HasItemAttribute("EnhanceAttributeId") then
        self:SetEnhanceAttributeWidgetVisibility(true)
        self.EnhanceId = InPickupObj:GetItemAttributeFString("EnhanceAttributeId")
        self.WBP_EnhanceAttribute_Bar:UpdateEnhanceInfo(self.EnhanceId)
    else
        self.EnhanceId = nil
        self:SetEnhanceAttributeWidgetVisibility(false)
    end

    self:HandleBetterItem()
end

function PickItemDetailUI:OnMouseMove(MyGeometry, MouseEvent)
    self.CurMousePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    local Dis = UE.UKismetMathLibrary.Distance2D(self.CurMousePos, self.MouseDwonPos)
    local bShouldDrag = Dis > (self.ClickDistance and self.ClickDistance or 10) --校验像素距离是否超限
    if not bShouldDrag or self.bStartDetectDrag then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    --超过拖拽校验像素点后 开始拖拽
    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then
        return 
    end
    self.IsHoldLeftMouseButton = false
    UE.UTipsManager.GetTipsManager(self):RemoveTipsUI(self.HoldToPickTipId)

    if self.bLeftOrRightMouseButtonDown then
        self.bStartDetectDrag = true
        return UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent,self, MouseKey)
    end
    return UE.UWidgetBlueprintLibrary.UnHandled()
end

function PickItemDetailUI:SetEnhanceAttributeWidgetVisibility(InState)
    if self.WBP_EnhanceAttribute_Bar then
        if InState then
            self.WBP_EnhanceAttribute_Bar:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            if self.Border_ItemType then
                self.Border_ItemType:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        else
            self.WBP_EnhanceAttribute_Bar:SetVisibility(UE.ESlateVisibility.Collapsed)
            if self.Border_ItemType then
                self.Border_ItemType:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            end
        end
    end
end

function PickItemDetailUI:GetImageAssetFromSkinID(InItemId, InSkinId)
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


function PickItemDetailUI:WillDestroy()
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end

function PickItemDetailUI:OnMouseEnter(MyGeometry, MouseEvent)
    if self.ItemID <= 0 or self.ItemNum <= 0 then
        return
    end

    self:StartAttachmentGuide()
    --self.ImageHover:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    self:SelectedState()

    local DetailInfoInteractionKeyName = self:GetDetailInfoInteractionKeyName()

    self.HandleSelect = true
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo,
        { 
            HoverWidget = self, 
            ParentWidget = self, 
            IsShowAtLeftSide = true , 
            ItemID= self.ItemID, 
            ItemNum = self.ItemNum,
            ItemSkinId = self.SkinId,
            EnhanceId = self.EnhanceId,
            IsBetter = self.IsBetter,
            IsShowDiscardNum = false,
            InteractionKeyName = DetailInfoInteractionKeyName,
            ShowSourceType = ItemSystemHelper.ItemDetialInfoShowMsgSourceType.PickupSystem
        })
    UE.UGamepadUMGFunctionLibrary.ChangeCursorMoveRate(self, true)
end

function PickItemDetailUI:OnMouseLeave(MouseEvent)
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)

    if not self.bDraging then
        self:EndAttachmentGuide()
    end

    self.HandleSelect = false
    self.IsHoldLeftMouseButton = false
    UE.UTipsManager.GetTipsManager(self):RemoveTipsUI(self.HoldToPickTipId)
    self.HoldingTime = 0.0
    self:UnselectState()
    --self.ImageHover:SetVisibility(UE.ESlateVisibility.Hidden)
    UE.UGamepadUMGFunctionLibrary.ChangeCursorMoveRate(self, false)
end

function PickItemDetailUI:OnDragDetected(MyGeometry, PointerEvent)


    if self.ItemID == 0 then
        return
    end

    -- local ItemType, IsExistItemType = UE.UItemSystemManager.GetItemDataFName(self, self.ItemID, "ItemType", GameDefine.NItemSubTable.Ingame, "")
    -- if IsExistItemType then
    --     if ItemType == ItemSystemHelper.NItemType.Weapon then
    --         local DragWeaponVisualWidget = UE.UWidgetBlueprintLibrary.Create(self, self.DragWeaponVisualClass)
    --         DragWeaponVisualWidget:SetDragInfo(self.ItemID, 0, self.ItemNum, GameDefine.InstanceIDType.PickInstance)
    --         DragWeaponVisualWidget:SetPickupObjInfo(self.PickupObjArray)
    --         DragWeaponVisualWidget:SetDragSource(GameDefine.DragActionSource.PickZoom, self)
    --         local DragDropObject = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(self.DragDropOperationClass)
    --         if DragDropObject then
    --             DragDropObject.DefaultDragVisual = DragWeaponVisualWidget
    --             return DragDropObject
    --         end
    --     else

    --     end
    -- end


    local DefaultDragVisualWidget = UE.UWidgetBlueprintLibrary.Create(self, self.DefaultDragVisualClass)
    self:StartAttachmentGuide()
    self.bDraging = true
    if DefaultDragVisualWidget then
        DefaultDragVisualWidget:SetDragInfo(self.ItemID, 0, self.ItemNum, GameDefine.InstanceIDType.PickInstance)
        DefaultDragVisualWidget:SetPickupObjInfo(self.PickupObjArray)
        DefaultDragVisualWidget:SetDragSource(GameDefine.DragActionSource.PickZoom, self)
        local DragDropObject = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(self.DragDropOperationClass)
        if self.Border_Main then self:VXE_HUD_Bag_PickItem_Floating_In() end
        if DragDropObject then
            DragDropObject.DefaultDragVisual = DefaultDragVisualWidget
            return DragDropObject
        end
    end

    return nil
end

-- 获得细节信息中交互按键的ID
-- return : nil if cannot find.
function PickItemDetailUI:GetDetailInfoInteractionKeyName()
    local ReturnKeyName = nil

    local TempItemId = self.ItemID
    if not TempItemId then
        return ReturnKeyName
    end

    local TempPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not TempPC then
        return ReturnKeyName
    end

    local TempItemType, IsExistColumn_ItemType = UE.UItemSystemManager.GetItemDataFName(TempPC, TempItemId, "ItemType", GameDefine.NItemSubTable.Ingame, "PickItemDetailUI:GetDetailInfoInteractionKeyId")
    if not IsExistColumn_ItemType then
        return ReturnKeyName
    end

    local TempBagComp = UE.UBagComponent.Get(TempPC)
    if not TempBagComp then return end

    if TempItemType == ItemSystemHelper.NItemType.Weapon then
        -- 武器类型
        -- 1. 装备栏有武器空位
        -- 1.1 显示：装备、标记
        -- 2. 装备栏有无武器空位
        -- 2.1 显示：替换、标记

        -- 确定当前装备栏中武器个数，是否和最高上限相等
        local CurrentWeaponSlotNum = TempBagComp:GetNumInItemSlotsByItemType(TempItemType)

        local TempTableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(TempPC);
        if not TempBagComp then
            return ReturnKeyName
        end
    
        local EquippedWeaponMaxNum = TempTableManagerSubsystem:GetItemTypeSlotNum(TempItemType);

        if CurrentWeaponSlotNum < EquippedWeaponMaxNum then
            -- 装备栏有武器空位
            ReturnKeyName = "Pick.Weapon.HasEmptyWeaponSlot" -- 需要改为lua表
        else
            -- 装备栏无武器空位
            ReturnKeyName = "Pick.Weapon.NoEmptyWeaponSlot"
        end

    elseif TempItemType == ItemSystemHelper.NItemType.Bullet then
        ReturnKeyName = "Pick.Default"

    elseif TempItemType == ItemSystemHelper.NItemType.Attachment then
        ReturnKeyName = "Pick.Default"

    elseif TempItemType == ItemSystemHelper.NItemType.Throwable then
        ReturnKeyName = "Pick.Default"

    elseif TempItemType == ItemSystemHelper.NItemType.Potion then
        ReturnKeyName = "Pick.Default"

    elseif TempItemType == ItemSystemHelper.NItemType.ArmorBody then
        ReturnKeyName = "Pick.Armor.HasEmptyArmorSlot"

    elseif TempItemType == ItemSystemHelper.NItemType.Bag then
        ReturnKeyName = "Pick.Bag.HasEmptyBagSlot"

    else
        -- 默认拾取会显示的交互键
        ReturnKeyName = "Pick.Default"
    end

    return ReturnKeyName
end

function PickItemDetailUI:SetWeaponSkinNameBySkinId(InWeaponSkinId)
    if not InWeaponSkinId then
        return nil
    end

    local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, InWeaponSkinId)
    if not WeaponSkinCfg then
        return nil
    end

    if self.Text_WeaponSkinName then
        local TempTranslatedWeaponSkinName = StringUtil.Format(WeaponSkinCfg.SkinName)
        self.Text_WeaponSkinName:SetText(TempTranslatedWeaponSkinName)
    end
end

function PickItemDetailUI:SetWeaponSkinBgColorBySkinId(InWeaponSkinId)
    local TheQualityCfg = MvcEntry:GetModel(DepotModel):GetQualityCfgByItemId(InWeaponSkinId)
    local Color = TheQualityCfg[Cfg_ItemQualityColorCfg_P.HexColor]
    CommonUtil.SetBrushTintColorFromHex(self.GUIImage_WeaponSkinBgColor,Color)
end


function PickItemDetailUI:OnFocusReceived(MyGeometry,InFocusEvent)
    self.HandleSelect = true
    self.ImageHover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.ImgBg:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self.BgBlur:SetVisibility(UE.ESlateVisibility.Collapsed)


end

function PickItemDetailUI:OnFocusLost(InFocusEvent)
    self.HandleSelect = false
    self.ImageHover:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.ImgBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function PickItemDetailUI:OnInventoryItemDragOnDrop(InMsgBody)
    if self.Border_Main and self.Border_Main:GetRenderOpacity() ~= 1 then
        self:VXE_HUD_Bag_PickItem_Floating_Out()
    end
end

function PickItemDetailUI:OnDragComplete()
    print("PickItemDetailUI:OnDragComplete")
    self.bDraging = false
    self:EndAttachmentGuide()
end

function PickItemDetailUI:StartAttachmentGuide()
    local InventoryIdentity = UE.FInventoryIdentity()
    InventoryIdentity.ItemID = self.ItemID
    InventoryIdentity.ItemInstanceID = 0
    MsgHelper:Send(self, GameDefine.Msg.Attachment_Guide_Start, {GuideInventoryIdentity = InventoryIdentity})
end

function PickItemDetailUI:EndAttachmentGuide()
    MsgHelper:Send(self, GameDefine.Msg.Attachment_Guide_End)
end

return PickItemDetailUI
