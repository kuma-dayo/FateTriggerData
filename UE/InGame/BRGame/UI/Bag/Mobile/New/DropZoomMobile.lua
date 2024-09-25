require "UnLua"
require("InGame.BRGame.ItemSystem.ItemBase.ItemAttachmentHelper")

local DropZoomMobile = Class("Common.Framework.UserWidget")

function DropZoomMobile:OnInit()
	UserWidget.OnInit(self)
end

function DropZoomMobile:OnDestroy()
    self.ItemSlotArray:Clear()
    UserWidget.OnDestroy(self)
end

function DropZoomMobile:OnDragEnter(MyGeometry, PointerEvent, Operation)
    self:Transport_OnDragEnter(MyGeometry, PointerEvent, Operation)
end

function DropZoomMobile:OnDragLeave(PointerEvent, Operation)
    self:Transport_OnDragLeave(PointerEvent, Operation)
end

function DropZoomMobile:OnDrop(MyGeometry, PointerEvent, Operation)
    return self:Transport_OnDrop(MyGeometry, PointerEvent, Operation)
end

-- self.ItemSlotArray 之中的控件，可能发现无需处理 OnDragEnter 会调用此函数
function DropZoomMobile:Transport_OnDragEnter(MyGeometry, PointerEvent, Operation)
    if not Operation then
        return
    end
    local DragSource = Operation.DefaultDragVisual:GetDragSource()
    if not DragSource then
        return
    end
    if DragSource == GameDefine.DragActionSource.BagZoom then
        if self.ZoomName == "Pick" then

        elseif self.ZoomName == "Discard" then
            Operation.DefaultDragVisual:ShowDragDropPurpose(GameDefine.DropAction.PURPOSE_Discard)
        elseif self.ZoomName == "Bag" then
            -- 把边框改为默认颜色
            Operation.DefaultDragVisual:ShowDragDropPurpose(GameDefine.DropAction.PURPOSE_Equip)
            Operation.DefaultDragVisual:HideDragDropPurpose()
        elseif self.ZoomName == "Equip" then
            local TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType =
                Operation.DefaultDragVisual:GetDragItemData()
            local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, TempItemID, "ItemType",
                GameDefine.NItemSubTable.Ingame, "DropZoomMobile:Transport_OnDragEnter")
            if CurrentItemType == "Weapon" or CurrentItemType == "Attachment" or CurrentItemType == "ArmorHead" or
                CurrentItemType == "ArmorBody" then
                self:TryShowAllHighLight(Operation.DefaultDragVisual, true)
                Operation.DefaultDragVisual:ShowDragDropPurpose(GameDefine.DropAction.PURPOSE_Equip)
            else
                Operation.DefaultDragVisual:HideDragDropPurpose()
            end
        end
    elseif DragSource == GameDefine.DragActionSource.EquipZoom then
        if self.ZoomName == "Pick" then

        elseif self.ZoomName == "Discard" then
            Operation.DefaultDragVisual:ShowDragDropPurpose(GameDefine.DropAction.PURPOSE_Discard)
        elseif self.ZoomName == "Bag" then
            local TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType =
                Operation.DefaultDragVisual:GetDragItemData()
            local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, TempItemID, "ItemType",
                GameDefine.NItemSubTable.Ingame, "DropZoomMobile:Transport_OnDragEnter")
            if CurrentItemType == "ArmorHead" or CurrentItemType == "ArmorBody" then
                Operation.DefaultDragVisual:HideDragDropPurpose()
            else
                Operation.DefaultDragVisual:ShowDragDropPurpose(GameDefine.DropAction.PURPOSE_UnEquip)
            end
        elseif self.ZoomName == "Equip" then
            Operation.DefaultDragVisual:HideDragDropPurpose()
        end
    elseif DragSource == GameDefine.DragActionSource.PickZoom then
        if self.ZoomName == "Pick" then
            Operation.DefaultDragVisual:HideDragDropPurpose()
        elseif self.ZoomName == "Discard" then
            Operation.DefaultDragVisual:ShowDragDropPurpose(GameDefine.DropAction.PURPOSE_Pick)
        elseif self.ZoomName == "Bag" then
            Operation.DefaultDragVisual:ShowDragDropPurpose(GameDefine.DropAction.PURPOSE_Pick)
        elseif self.ZoomName == "Equip" then
            Operation.DefaultDragVisual:ShowDragDropPurpose(GameDefine.DropAction.PURPOSE_Equip)
        end
    end
end

function DropZoomMobile:Transport_OnDragLeave(PointerEvent, Operation)
    self:HideAllHighLight()
end

function DropZoomMobile:Transport_OnDrop(MyGeometry, PointerEvent, Operation)
    if self.ZoomName == "Pick" then

    elseif self.ZoomName == "Discard" then
        self:OnDropToDiscardZoom(MyGeometry, PointerEvent, Operation)
    elseif self.ZoomName == "Bag" then
        self:OnDropToBagZoom(MyGeometry, PointerEvent, Operation)
    elseif self.ZoomName == "Equip" then
        self:OnDropToEquipZoom(MyGeometry, PointerEvent, Operation)
    end
    -- 通知拖拽组件完成了OnDrop
    print("DropZoomMobile:Transport_OnDrop", self.ZoomName)
    Operation.DefaultDragVisual:OnDropCallBack()
    return true
end

function DropZoomMobile:AddItemSlot(Widget)
    if not Widget then
        return
    end

    if Widget.Delegate_TransportOnDragEnter then
        Widget.Delegate_TransportOnDragEnter:Add(self, self.Transport_OnDragEnter)
    end

    if Widget.Delegate_TransportOnDrop then
        Widget.Delegate_TransportOnDrop:Add(self, self.Transport_OnDrop)
    end

    if Widget.Delegate_TransportOnDragLeave then
        Widget.Delegate_TransportOnDragLeave:Add(self, self.Transport_OnDragLeave)
    end

    self.ItemSlotArray:Add(Widget)
end

function DropZoomMobile:HideAllHighLight()
    local LoopNum = self.ItemSlotArray:Length()
    for i = 1, LoopNum do
        local TempWidget = self.ItemSlotArray:GetRef(i)
        if TempWidget and TempWidget.HideAllHighLight then
            TempWidget:HideAllHighLight()
        end
    end
end

function DropZoomMobile:TryShowAllHighLight(WidgetDragVisual, IsShow)
    local LoopNum = self.ItemSlotArray:Length()
    for i = 1, LoopNum do
        local TempWidget = self.ItemSlotArray:GetRef(i)
        -- 武器可能处理一些高亮边框（没有就不处理）
        if TempWidget and TempWidget.DragEnterSetHighLight then
            TempWidget:DragEnterSetHighLight(WidgetDragVisual, IsShow)
        end
    end
end

function DropZoomMobile:OnDropToDiscardZoom(MyGeometry, PointerEvent, Operation)
    if not Operation then
        return true
    end
    if not Operation.DefaultDragVisual then
        return true
    end
    local TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType = Operation.DefaultDragVisual:GetDragItemData()
    print("BagM@DropZoomMobile:OnDropToDiscardZoom:", TempItemID, " num: " ,TempItemNum)

    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, TempItemID, "ItemType",
        GameDefine.NItemSubTable.Ingame, "DropZoomMobile:OnDropToDiscardZoom")
    if not IsFindItemType then
        return true
    end

    if (TempInstanceIDType == GameDefine.InstanceIDType.ItemInstance) then
        self:TryToDiscardItem(TempItemID, TempInstanceID, TempItemNum)
    elseif TempInstanceIDType == GameDefine.InstanceIDType.PickInstance then
        self:TryToPick(Operation)
    end
end

function DropZoomMobile:OnDropToBagZoom(MyGeometry, PointerEvent, Operation)
    if not Operation then
        return true
    end
    if not Operation.DefaultDragVisual then
        return true
    end
    local TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType = Operation.DefaultDragVisual:GetDragItemData()
    print("BagM@DropZoomMobile:OnDropToBagZoom:", TempItemID, " num: " ,TempItemNum)

    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, TempItemID, "ItemType",
        GameDefine.NItemSubTable.Ingame, "DropZoomMobile:OnDropToBagZoom")
    if not IsFindItemType then
        return true
    end

    if TempInstanceIDType == GameDefine.InstanceIDType.PickInstance then
        -- 拾取
        self:TryToPick(Operation)
    else
        if CurrentItemType == "Weapon" then

        elseif CurrentItemType == "Attachment" then
            -- 尝试对每个武器 装配 配件
            self:TryToUnEquipAttachment(TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType)
            self:HideAllHighLight()
        end
    end
end

function DropZoomMobile:OnDropToEquipZoom(MyGeometry, PointerEvent, Operation)
    if not Operation then
        return true
    end
    if not Operation.DefaultDragVisual then
        return true
    end
    local TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType = Operation.DefaultDragVisual:GetDragItemData()
    print("BagM@DropZoomMobile:OnDropToEquipZoom:", TempItemID, " num: " ,TempItemNum)

    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, TempItemID, "ItemType",
        GameDefine.NItemSubTable.Ingame, "DropZoomMobile:OnDropToEquipZoom")
    if not IsFindItemType then
        return true
    end

    if TempInstanceIDType == GameDefine.InstanceIDType.PickInstance then
        -- 拾取
        self:TryToPick(Operation)
    else
        if CurrentItemType == "Weapon" then

        elseif CurrentItemType == "Attachment" then
            -- 尝试对每个武器 装配 配件
            self:TryToEquipAttachmentToAnyWeapon(TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType)
            self:HideAllHighLight()
        end
    end
end

function DropZoomMobile:TryToEquipAttachmentToAnyWeapon(ItemID, InstanceID, ItemNum, InstanceIDType)
    print("BagM@DropZoomMobile:TryToEquipAttachmentToAnyWeapon:", ItemID," num: ", ItemNum)
    if InstanceIDType == GameDefine.InstanceIDType.ItemInstance then
        local AttachmentInventoryIdentity = UE.FInventoryIdentity()
        AttachmentInventoryIdentity.ItemID = ItemID
        AttachmentInventoryIdentity.ItemInstanceID = InstanceID

        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        UE.UItemStatics.UseItem(PlayerController, AttachmentInventoryIdentity,
            ItemAttachmentHelper.NUsefulReason.AttachAnyWeapon)
    end
end

function DropZoomMobile:TryToUnEquipAttachment(ItemID, InstanceID, ItemNum, InstanceIDType)
    print("BagM@DropZoomMobile:TryToUnEquipAttachment:", ItemID," num: ", ItemNum)

    if InstanceIDType == GameDefine.InstanceIDType.ItemInstance then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        local TempBagComp = UE.UBagComponent.Get(PlayerController)
        if not TempBagComp then
            return
        end
        local CurrentWAttachmentInventoryIdentity = UE.FInventoryIdentity()
        CurrentWAttachmentInventoryIdentity.ItemID = ItemID
        CurrentWAttachmentInventoryIdentity.ItemInstanceID = InstanceID

        UE.UItemStatics.UseItem(PlayerController, CurrentWAttachmentInventoryIdentity,
            ItemAttachmentHelper.NUsefulReason.UnEquipFromWeapon)
    end
end

function DropZoomMobile:TryToPick(Operation)
    if not Operation then
        return
    end
    if not Operation.DefaultDragVisual then
        return
    end
    local PickupObjArray = Operation.DefaultDragVisual:GetPickupObjInfo()
    if not PickupObjArray then
        return
    end
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPawn(LocalPC)
    if LocalPC and LocalPCPawn then
        for index = 1, PickupObjArray:Length() do
            local CurrentPickupObj = PickupObjArray:Get(index)
            if CurrentPickupObj then
                local TempGameplayTagDragDrop = UE.FGameplayTag()
                TempGameplayTagDragDrop.TagName = "PickSystem.PickMode.Drag"
                local TempGameplayTagDropEndAtZoom = UE.FGameplayTag()
                TempGameplayTagDropEndAtZoom.TagName = "PickSystem.PickMode.DropEndAtZoom"
                local TempTagContainer = UE.FGameplayTagContainer()
                TempTagContainer.GameplayTags:Add(TempGameplayTagDragDrop)
                TempTagContainer.GameplayTags:Add(TempGameplayTagDropEndAtZoom)
                UE.UPickupStatics.TryPickupItem(LocalPCPawn, CurrentPickupObj, 0, UE.EPickReason.PR_Player,
                    TempTagContainer)
            end
        end
    end
end

function DropZoomMobile:TryToDiscardItem(ItemID, ItemInstanceID, ItemNum)
    print("BagM@DropZoomMobile:TryToDiscardItem:", ItemID," num: ", ItemNum)

    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    local DiscardInventoryIdentity = UE.FInventoryIdentity()
    DiscardInventoryIdentity.ItemID = ItemID
    DiscardInventoryIdentity.ItemInstanceID = ItemInstanceID
    local TempDiscardTag = UE.FGameplayTag()
    UE.UItemStatics.DiscardItem(PlayerController, DiscardInventoryIdentity, ItemNum, TempDiscardTag)
    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Item_Discard")
end

return DropZoomMobile
