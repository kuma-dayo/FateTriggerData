require "UnLua"

local EquipmentItemInBag = Class("Common.Framework.UserWidget")
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

local TouchType = {
    None = 1,
    Selected = 2,
    Drag = 3
}

function EquipmentItemInBag:OnInit()
    self.ItemID = 0
    self.ItemInstanceID = 0
    self.ItemNum = 1

    self.CurrentTouchState = TouchType.None
    self.DragDistance = 0
    self.DragOperationActiveMinDistance = 10.0;
    self.DragStartPosition = UE.FVector2D()
    self.DragStartPosition.X = 0
    self.DragStartPosition.Y = 0
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickPart,             Func = self.OnDiscardPart,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
        { MsgName = GameDefine.MsgCpp.INVENTORY_Enhance_Update,             Func = self.OnInventoryEnhanceUpdate,       bCppMsg = true}
    }

    -- 绑定护甲，背包，头盔各自的回调
    self.DynamicBindFunctions = {}
    if self.DefaultType == ItemSystemHelper.NItemType.ArmorHead then
        table.insert(self.DynamicBindFunctions, { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Change_Helmet, Func = self.OnInventoryItemSlotChangeHelmet, bCppMsg = true})
    elseif self.DefaultType == ItemSystemHelper.NItemType.Bag then
        table.insert(self.DynamicBindFunctions, { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Change_Bag, Func = self.OnInventoryItemSlotChangeBag, bCppMsg = true})
    elseif self.DefaultType == ItemSystemHelper.NItemType.ArmorBody then
        table.insert(self.DynamicBindFunctions, { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Change_Armor, Func = self.OnInventoryItemSlotChangeArmor, bCppMsg = true})
    end
    
    -- 绑定 Reset 回调
    table.insert(self.DynamicBindFunctions, { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Reset, Func = self.OnReset, bCppMsg = true})
    table.insert(self.DynamicBindFunctions, { MsgName = GameDefine.Msg.InventoryItemSlotDragOnDrop, Func = self.OnInventoryItemDragOnDrop, bCppMsg = false})
    table.insert(self.DynamicBindFunctions, { MsgName = GameDefine.MsgCpp.INVENTORY_Enhance_Update, Func = self.OnInventoryEnhanceUpdate, bCppMsg = true})

    -- 绑定
    MsgHelper:RegisterList(self, self.DynamicBindFunctions)

    print("EquipmentItemInBag Init")
    UserWidget.OnInit(self)
end


function EquipmentItemInBag:OnShow()
    self:ActiveRequestEquip()
end

function EquipmentItemInBag:OnDestroy()
    -- 解除绑定
    if self.DynamicBindFunctions then
        MsgHelper:UnregisterList(self, self.DynamicBindFunctions)
        self.DynamicBindFunctions = nil
    end
    print("EquipmentItemInBag OnDestroy")
end


function EquipmentItemInBag:ActiveRequestEquip()
    if self.ItemID ~= 0 then
        return
    end

    local PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not PC then return end
    local CH = PC:K2_GetPawn()
    if not CH then return end
    local EquipComp = UE.UEquipmentStatics.GetEquipmentComponent(CH)
    local tBagComp = UE.UBagComponent.Get(PC)

    if EquipComp and tBagComp then
        local ItemSlot1, HasSlot1 = tBagComp:GetItemSlotByTypeAndSlotID(self.DefaultType, 1)
        if HasSlot1 then
            self:SetInventoryIdentity(ItemSlot1.InventoryIdentity)
            self:UpdateItemInfo()
        end
    end
end

function EquipmentItemInBag:OnDiscardPart(InInputData)
    if not self.HandleSelect then
        return
    end
    self:DiscardSelf()
end

function EquipmentItemInBag:OnMouseButtonDown(MyGeometry, MouseEvent)


    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Handled()

    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then
        return DefaultReturnValue
    end

    if (self.ItemID == 0 or self.ItemInstanceID == 0) then
        if GameDefine.NInputKey.MiddleMouseButton == MouseKey.KeyName then
            if self.ItemID ~= 0 and nil ~= self.ItemID then
                AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithItemId(self, self.ItemID, self.DefaultType)
                print("EquipmentItemInBag:OnMouseButtonDown SendMsg Own EquipmentItemInBag !")
            else
                AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemType(self, self.DefaultType)
                print("EquipmentItemInBag:OnMouseButtonDown SendMsg Need EquipmentItemInBag !")
            end
        end
        return UE.UWidgetBlueprintLibrary.Handled()
    end


    if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton then
        DefaultReturnValue = UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent, self, MouseKey)
    elseif MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton then
        self:DiscardSelf()
    elseif GameDefine.NInputKey.MiddleMouseButton == MouseKey.KeyName then
        if self.ItemID ~= 0 and nil ~= self.ItemID then
            AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithItemId(self, self.ItemID, self.DefaultType)
            print("EquipmentItemInBag:OnMouseButtonDown SendMsg Own EquipmentItemInBag !")
        else
            AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemType(self, self.DefaultType)
            print("EquipmentItemInBag:OnMouseButtonDown SendMsg Need EquipmentItemInBag !")
        end
    end

    return DefaultReturnValue
end

-- 当装备强化后触发的回调
-- InInventoryInstance 是 UInventoryInstance 类型
function EquipmentItemInBag:OnInventoryEnhanceUpdate(InInventoryInstance)
    if InInventoryInstance then
        local InventoryIdentity = InInventoryInstance:GetInventoryIdentity()
        if InventoryIdentity.ItemID == self.ItemID and InventoryIdentity.ItemInstanceID == self.ItemInstanceID then
            self:UpdateEnhanceIcon(InInventoryInstance)
        end
    end
end

function EquipmentItemInBag:DiscardSelf()
    if (self.ItemID ~= 0) and (self.ItemInstanceID ~= 0) then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        local TempInventoryIdentity = UE.FInventoryIdentity()
        TempInventoryIdentity.ItemID = self.ItemID
        TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID
        local TempDiscardTag = UE.FGameplayTag()
        UE.UItemStatics.DiscardItem(PlayerController, TempInventoryIdentity, 1, TempDiscardTag)
        UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Item_Discard")
    end
end

function EquipmentItemInBag:OnDragDetected(MyGeometry, PointerEvent)
    local DragDropObject = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(self.DragDropOperationClass)
    local DefaultDragVisualWidget = UE.UWidgetBlueprintLibrary.Create(self, self.DefaultDragVisualClass)
    self.CurrentDragVisualWidget = DefaultDragVisualWidget
    if BridgeHelper.IsMobilePlatform() then
        self.CurrentDragVisualWidget:SetDragVisibility(false)
    end
    DragDropObject.DefaultDragVisual = DefaultDragVisualWidget

    DefaultDragVisualWidget:SetDragInfo(self.ItemID, self.ItemInstanceID, self.ItemNum, GameDefine.InstanceIDType.ItemInstance)
    DefaultDragVisualWidget:SetDragSource(GameDefine.DragActionSource.BagZoom,self)
    if self.EquipItem then self:VXE_HUD_Bag_Attach_Floating_In() end
    return DragDropObject
end


function EquipmentItemInBag:OnDragOver(MyGeometry, MouseEvent, Operation)
    if not self.CurrentDragVisualWidget then
        -- self.CurrentDragVisualWidget:SetDragVisibility(true)
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    if self.CurrentTouchState == TouchType.Selected then

        local CurrentDragPositionInViewport = UE.UGFUnluaHelper.FPointerEvent_GetScreenSpacePosition(MouseEvent)
        local TempX = math.abs(CurrentDragPositionInViewport.X - self.DragStartPosition.X)
        local TempY = math.abs(CurrentDragPositionInViewport.Y - self.DragStartPosition.Y)

        if (TempX > self.DragOperationActiveMinDistance) or (TempY > self.DragOperationActiveMinDistance) then
            local PreState = self:SetTouchState(TouchType.Drag)
            if (PreState == TouchType.Selected) and (self.CurrentTouchState == TouchType.Drag) then
                self.CurrentDragVisualWidget:SetDragVisibility(true)
            end
        end
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end



-- 当拖拽到本控件并释放鼠标按键的时候会触发此回调（拖拽完成）
function EquipmentItemInBag:OnDrop(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    return true
end


-- function EquipmentItemInBag:OnDragEnter(MyGeometry, PointerEvent, Operation)
--     self.Delegate_TransportOnDragEnter:Broadcast(MyGeometry, PointerEvent, Operation)
-- end

-- function EquipmentItemInBag:OnDragLeave(PointerEvent, Operation)
--     self.Delegate_TransportOnDragLeave:Broadcast(PointerEvent, Operation)
-- end


function EquipmentItemInBag:UpdateItemInfo()
    -- 根据物品ID更新图片
    local CurItemIcon, IsExistIcon = UE.UItemSystemManager.GetItemDataFString(self, self.ItemID, "ItemIcon",
        GameDefine.NItemSubTable.Ingame, "EquipmentItemInBag:UpdateItemInfo")
    if IsExistIcon then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurItemIcon)
        self.GUIImage_Icon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
        self.GUIImage_Icon:SetColorAndOpacity(self.ColorExist)
    end

    -- 根据物品ID更新等级颜色
    local ItemLevel, bValidItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, self.ItemID, "ItemLevel",
        GameDefine.NItemSubTable.Ingame, "EquipmentItemInBag:UpdateItemInfo")
    if bValidItemLevel then
        local TempBgImageTexture = self.LevelBgMap:Find(ItemLevel)
        if TempBgImageTexture then
            self.GUIImage_Bg:SetBrushFromTexture(TempBgImageTexture, false)
        end
    end

    -- 根据物品ID更新名字
    local bValidName = true
    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, self.ItemID)
    if IngameDT then
        local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(self.ItemID))
        local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)
        self.Txt_ItemName:SetText(TranslatedItemName)
        self:SetItemNameWidgetVisibility(true)
    end

    print("(Wzp)EquipmentItemInBag:UpdateItemInfo  [ObjectName]=",GetObjectName(self),",[self.ItemID]=",self.ItemID,",[IsExistIcon]=",IsExistIcon,",[bValidItemLevel]=",bValidItemLevel)

    -- 根据物品ID更新词条
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not TempLocalPC then
        return
    end
    local TempBagComp = UE.UBagComponent.Get(TempLocalPC)
    if not TempBagComp then
        return
    end
    local TempEnhanceId = nil
    local TempInventoryIdentity = UE.FInventoryIdentity()
    TempInventoryIdentity.ItemID = self.ItemID
    TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID
    local TempInventoryInstance = TempBagComp:GetInventoryInstance(TempInventoryIdentity)
    if TempInventoryInstance then
        self:UpdateEnhanceIcon(TempInventoryInstance)
    end
end

function EquipmentItemInBag:UpdateEnhanceIcon(InInventoryInstance)
    if InInventoryInstance then
        if InInventoryInstance:HasItemAttribute("EnhanceAttributeId") then
            self:SetEnhanceAttributeWidgetVisibility(true)
            local  TempEnhanceId = InInventoryInstance:GetItemAttributeFString("EnhanceAttributeId")
            print("(Wzp)EquipmentItemInBag:UpdateEnhanceIcon  [ObjectName]=",GetObjectName(self),",[TempEnhanceId]=",TempEnhanceId)
            self.WBP_EnhanceAttribute_Bar:UpdateEnhanceInfo(TempEnhanceId)
        else
            self:SetEnhanceAttributeWidgetVisibility(false)
        end
    end
end


function EquipmentItemInBag:OnReset(InBagComponentOwner, InInventoryItemSlot)
    print("(Wzp)EquipmentItemInBag:OnReset  [ObjectName]=",GetObjectName(self))
    if not InBagComponentOwner then
        return
    end

    if self.DefaultType == InInventoryItemSlot.ItemType then

        self:ResetItemInfo()
    end
end


function EquipmentItemInBag:ResetItemInfo()
    print("(Wzp)EquipmentItemInBag:ResetItemInfo  [ObjectName]=",GetObjectName(self))
    self:ResetInventoryIdentity()
    self:SetItemNameWidgetVisibility(false)
    self:SetEnhanceAttributeWidgetVisibility(false)
    self.GUIImage_Icon:SetBrushFromTexture(self.DefaultIcon, false)
    self.GUIImage_Icon:SetColorAndOpacity(self.ColorEmpty)
    self.GUIImage_Bg:SetBrushFromTexture(self.DefaultIconBg, false)
end

function EquipmentItemInBag:ResetInventoryIdentity()
    self.ItemID = 0
    self.ItemInstanceID = 0
end

function EquipmentItemInBag:SetInventoryIdentity(InInventoryIdentity)
    self.ItemID = InInventoryIdentity.ItemID
    self.ItemInstanceID = InInventoryIdentity.ItemInstanceID
    print("(Wzp)EquipmentItemInBag:SetInventoryIdentity  [ObjectName]=",GetObjectName(self),",[self.ItemID]=",self.ItemID,",[self.ItemInstanceID]=",self.ItemInstanceID)
end

function EquipmentItemInBag:SetEnhanceAttributeWidgetVisibility(InState)
    if self.WBP_EnhanceAttribute_Bar then
        print("(Wzp)EquipmentItemInBag:SetEnhanceAttributeWidgetVisibility  [ObjectName]=",GetObjectName(self),",[InState]=",InState)
        if InState then
            self.WBP_EnhanceAttribute_Bar:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.WBP_EnhanceAttribute_Bar:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

function EquipmentItemInBag:SetItemNameWidgetVisibility(InState)
    if self.Txt_ItemName then
        print("(Wzp)EquipmentItemInBag:SetItemNameWidgetVisibility  [ObjectName]=",GetObjectName(self),",[InState]=",InState)
        if InState then
            self.Txt_ItemName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.Txt_ItemName:SetText(self.DefaultName)
            -- self.Txt_ItemName:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

function EquipmentItemInBag:OnMouseEnter(MyGeometry, MouseEvent)
    if BridgeHelper.IsMobilePlatform() then
        return
    end
    self.HandleSelect = true
    -- 强化词条
    local TempEnhanceId = nil
    local TempWeaponInventoryIdentity = UE.FInventoryIdentity()
    TempWeaponInventoryIdentity.ItemID = self.ItemID
    TempWeaponInventoryIdentity.ItemInstanceID = self.ItemInstanceID
    local TempPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempPC then
        local TempBagComp = UE.UBagComponent.Get(TempPC)
        if not TempBagComp then return end
        local TempWeaponInventoryInstance = TempBagComp:GetInventoryInstance(TempWeaponInventoryIdentity)
        if TempWeaponInventoryInstance then
            if TempWeaponInventoryInstance:HasItemAttribute("EnhanceAttributeId") then
                TempEnhanceId = TempWeaponInventoryInstance:GetItemAttributeFString("EnhanceAttributeId")
            end
        end
    end

    local TempInteractionKeyName = "Bag.Default.2Action"

    if self.ItemID ~= 0 then
        self.Img_Border:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo, {
            HoverWidget = self,
            ParentWidget = nil,
            IsShowAtLeftSide = true,
            ItemID=self.ItemID,
            ItemInstanceID = self.ItemInstanceID,
            ItemNum = 1,
            IsShowDiscardNum = true,
            InteractionKeyName = TempInteractionKeyName,
            EnhanceId = TempEnhanceId,
            ShowSourceType = ItemSystemHelper.ItemDetialInfoShowMsgSourceType.BagSystem
        })
        UE.UGamepadUMGFunctionLibrary.ChangeCursorMoveRate(self, true)
    end
end

function EquipmentItemInBag:OnMouseLeave(MouseEvent)
    if BridgeHelper.IsMobilePlatform() then
        return
    end
    UE.UGamepadUMGFunctionLibrary.ChangeCursorMoveRate(self, false)

    self.Img_Border:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.HandleSelect = false
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end

function EquipmentItemInBag:OnInventoryItemSlotChangeArmor(InBagComponentOwner, InInventoryItemSlot)
    if self.DefaultType ~= ItemSystemHelper.NItemType.ArmorBody then
        print("EquipmentItemInBag>>OnInventoryItemSlotChangeArmor>>DefaultType not match ArmorBody: ", self.DefaultType)
        return
    end

    local TempBagComp = UE.UBagComponent.Get(InBagComponentOwner)
    if not TempBagComp then
        print("EquipmentItemInBag>>OnInventoryItemSlotChangeArmor>>TempBagComp is nil")
        return
    end
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if UIManager:IsAnyDynamicWidgetShowByKey("UMG_Bag") then self:VXE_HUD_Bag_Attach() end
    self:SetInventoryIdentity(InInventoryItemSlot.InventoryIdentity)

    self:UpdateItemInfo()
end

function EquipmentItemInBag:OnInventoryItemSlotChangeBag(InBagComponentOwner, InInventoryItemSlot)
    if self.DefaultType ~= ItemSystemHelper.NItemType.Bag then
        print("EquipmentItemInBag>>OnInventoryItemSlotChangeBag>>DefaultType not match Bag: ", self.DefaultType)
        return
    end

    local TempBagComp = UE.UBagComponent.Get(InBagComponentOwner)
    if not TempBagComp then
        print("EquipmentItemInBag>>OnInventoryItemSlotChangeBag>>TempBagComp is nil")
        return
    end
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if UIManager:IsAnyDynamicWidgetShowByKey("UMG_Bag") then self:VXE_HUD_Bag_Attach() end
    self:SetInventoryIdentity(InInventoryItemSlot.InventoryIdentity)

    self:UpdateItemInfo()
end


function EquipmentItemInBag:OnInventoryItemSlotChangeHelmet(InBagComponentOwner, InInventoryItemSlot)
    if self.DefaultType ~= ItemSystemHelper.NItemType.ArmorHead then
        print("EquipmentItemInBag>>OnInventoryItemSlotChangeHelmet>>DefaultType not match ArmorHead: ", self.DefaultType)
        return
    end

    local TempBagComp = UE.UBagComponent.Get(InBagComponentOwner)
    if not TempBagComp then
        print("EquipmentItemInBag>>OnInventoryItemSlotChangeHelmet>>TempBagComp is nil")
        return
    end
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if UIManager:IsAnyDynamicWidgetShowByKey("UMG_Bag") then self:VXE_HUD_Bag_Attach() end
    self:SetInventoryIdentity(InInventoryItemSlot.InventoryIdentity)

    self:UpdateItemInfo()
end

function EquipmentItemInBag:OnFocusReceived(MyGeometry,InFocusEvent)
    -- local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
    -- if IsInCursorMode then
    --     return
    -- end
    self.HandleSelect = true
    self.Img_Border:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    return UE.UWidgetBlueprintLibrary.Handled()

end

function EquipmentItemInBag:OnFocusLost(InFocusEvent)
    -- local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
    -- if IsInCursorMode then
    --     return
    -- end
    self.HandleSelect = false
    self.Img_Border:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function EquipmentItemInBag:OnInventoryItemDragOnDrop(InMsgBody)
    if self.EquipItem and self.EquipItem:GetRenderOpacity() ~= 1 then
        self:VXE_HUD_Bag_Attach_Floating_Out()
    end
end

return EquipmentItemInBag
