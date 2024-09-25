require "UnLua"

local CommonItemContainerInBag = Class("Common.Framework.UserWidget")


function CommonItemContainerInBag:OnInit()
    self:InitEmptySlotWidget()
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.BAG_WeightOrSlotNum, Func = self.OnUpdateBagData, bCppMsg = true },
        { MsgName = GameDefine.Msg.InventoryItemNumChangeSingle, Func = self.OnInventoryItemNumChangeSingle, bCppMsg = true},
        { MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnNew, Func = self.OnInventoryNew, bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnDestroy, Func = self.OnInventoryDestroy, bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.INVENTORY_WeaponAttachment_UIUpdate_Attach, Func = self.OnWeaponAttachmentUIUpdate, bCppMsg = true },
        { MsgName = GameDefine.Msg.InventoryClearBag, Func = self.OnInventoryClearBag, bCppMsg = true }
        -- { MsgName = GameDefine.MsgCpp.BagUI_UseItem, Func = self.OnSelectArea, bCppMsg = true, WatchedObject = self.LocalPC },
    }

    self:TryUpdateContainerAtNextFrame()

	UserWidget.OnInit(self)
end


function CommonItemContainerInBag:OnDestroy()
	UserWidget.OnDestroy(self)
end


function CommonItemContainerInBag:InitEmptySlotWidget()
    self:AddEmptySlotWidget(self.WBP_EmptySlotInContainer_0)
    self:AddEmptySlotWidget(self.WBP_EmptySlotInContainer_1)
    self:AddEmptySlotWidget(self.WBP_EmptySlotInContainer_2)
    self:AddEmptySlotWidget(self.WBP_EmptySlotInContainer_3)
    self:AddEmptySlotWidget(self.WBP_EmptySlotInContainer_4)
    self:AddEmptySlotWidget(self.WBP_EmptySlotInContainer_5)
    self:AddEmptySlotWidget(self.WBP_EmptySlotInContainer_6)
    self:AddEmptySlotWidget(self.WBP_EmptySlotInContainer_7)
    self:AddEmptySlotWidget(self.WBP_EmptySlotInContainer_8)
    self:AddEmptySlotWidget(self.WBP_EmptySlotInContainer_9)
    -- self:AddEmptySlotWidget(self.WBP_EmptySlotInContainer_10)
    -- self:AddEmptySlotWidget(self.WBP_EmptySlotInContainer_11)
end

function CommonItemContainerInBag:GetAllSlotWidget()
    return self.EmptySlotWidgetArray
end

function CommonItemContainerInBag:OnUpdateBagData(InBagComponent)
    self:TryUpdateContainerAtNextFrame()
end

function CommonItemContainerInBag:OnInventoryItemNumChangeSingle(InGMPMessage_InventoryItemChange)
    self:TryUpdateContainerAtNextFrame()
end

function CommonItemContainerInBag:OnInventoryNew(InInventoryInstance, TagContainer)
    self:TryUpdateContainerAtNextFrame()
end


function CommonItemContainerInBag:OnInventoryDestroy(InInventoryInstance)
    self:TryUpdateContainerAtNextFrame()
end


function CommonItemContainerInBag:OnWeaponAttachmentUIUpdate(InInventoryIdentity, InAttachOrDetach)
    self:TryUpdateContainerAtNextFrame()
end

function CommonItemContainerInBag:OnInventoryClearBag(InInventoryArrayStruct)
    self:TryUpdateContainerAtNextFrame()
end

function CommonItemContainerInBag:UpdateWidgetNumAddVXEImpl(InInventoryIdentitySet)
    local EmptySlotWidgetNum = self.EmptySlotWidgetArray:Num()
    for i = 1, EmptySlotWidgetNum do
        local Widget = self.EmptySlotWidgetArray:Get(i)
        if Widget then
            local RealWidget = Widget:GetItemNormal()
            if not RealWidget then return end
            local CurrentItemId, CurrentItemInstanceId = RealWidget:GetSlotNormalInventoryIdentity()
            local CurrentInventoryIdentity = UE.FInventoryIdentity()
            CurrentInventoryIdentity.ItemID = CurrentItemId
            CurrentInventoryIdentity.ItemInstanceID = CurrentItemInstanceId
            local IsContains = InInventoryIdentitySet:Contains(CurrentInventoryIdentity)
            if IsContains then
                RealWidget:VXE_NumAdd()
            end
        end
    end
end

function CommonItemContainerInBag:UpdateLockSlotState()
    local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
    local TempMaxSlotNum = self:GetCurrentMaxSlotNum()

    local LoopCount = self.EmptySlotWidgetArray:Length()

    for i = 1, LoopCount, 1 do
        local TempEmptySlotWidget = self.EmptySlotWidgetArray:Get(i)
        if TempEmptySlotWidget then
            if i <= TempMaxSlotNum then
                -- 设置为 非锁定
                TempEmptySlotWidget:SetLockState(false)
                if not IsInCursorMode then
                    TempEmptySlotWidget.bIsFocusable = true
                end
            else
                -- 设置为 锁定
                TempEmptySlotWidget:ResetInvItemInfo()
                TempEmptySlotWidget:SetLockState(true)
                if not IsInCursorMode then
                    TempEmptySlotWidget.bIsFocusable = false
                end
            end
        end
    end
end

-- 刷新单个物品
function CommonItemContainerInBag:UpdateRealSingleWidget(RealWidget, InInventoryIdentity, InItemNum)
    if RealWidget then
        RealWidget:SetInvItemInfoV2(InInventoryIdentity, InItemNum)
    end
end

function CommonItemContainerInBag:UpdateCommonItemContainer()
    self:UpdateLockSlotState()
end

function CommonItemContainerInBag:WidgetResetInvItemInfo(InWidget)
    if InWidget then
        InWidget:ResetInvItemInfo()
    end
end


function CommonItemContainerInBag:OnFocusReceived(MyGeometry,InFocusEvent)
    print("[Wzp]CommonItemContainerInBag:OnFocusReceived")
    self.HandleSelect = true
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    return UE.UWidgetBlueprintLibrary.Handled()
end


function CommonItemContainerInBag:OnFocusLost(InFocusEvent)
    print("[Wzp]CommonItemContainerInBag:OnFocusLost")
    self.HandleSelect = false
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
end


function CommonItemContainerInBag:OnSelectArea()
    if not self.HandleSelect then
        return
    end

    local Widget = self.EmptySlotWidgetArray:Get(1)
    if Widget then
        Widget:SetFocus()
    end
end


function CommonItemContainerInBag:OnKeyDown(MyGeometry,InKeyEvent)
	local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey == UE.FName("Gamepad_FaceButton_Bottom") then      
        print("ItemSlotWeapon >> OnKeyDown")
        self:OnSelectArea()
        return UE.UWidgetBlueprintLibrary.Handled()
    end
end


function CommonItemContainerInBag:UpdateIsFocusable(bIsFocus)
    self:InitEmptySlotWidget()
    for Index, Widget in pairs(self.EmptySlotWidgetArray) do
        Widget.bIsFocusable = bIsFocus
    end
end


return CommonItemContainerInBag