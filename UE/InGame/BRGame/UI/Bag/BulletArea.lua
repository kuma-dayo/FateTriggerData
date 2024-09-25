require "UnLua"

local BulletArea = Class("Common.Framework.UserWidget")

function BulletArea:OnInit()
    print("BulletArea", ">> OnInit, ", GetObjectName(self))

    self.MsgList={
        { MsgName = GameDefine.MsgCpp.BagUI_UseItem,             Func = self.OnSelectArea,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
        { MsgName = GameDefine.Msg.InventoryItemNumChangeSingle,    Func = self.OnInventoryItemNumChangeSingle, bCppMsg = true },
        { 
            MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnNew, 
            Func = self.OnInventoryNew, 
            bCppMsg = true
        }, {
            MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnDestroy,
            Func = self.OnInventoryDestroy,
            bCppMsg = true
        },
        {
            MsgName = GameDefine.Msg.InventoryClearBag,
            Func = self.OnInventoryClearBag,
            bCppMsg = true
        }
    }

    local BulletTable = self:GetAllWidget()
    self.BulletMap = {}
    for k, Widget in pairs(BulletTable) do
        local OnlySupportItemId = Widget:GetOnlySupportItemId()
        if OnlySupportItemId ~= 0 then
            self.BulletMap[OnlySupportItemId] = Widget
        end
    end

    UserWidget.OnInit(self)
end


function BulletArea:OnShow()
    print("(Wzp)BulletArea:OnShow [ObjectName]=",GetObjectName(self))
    self:RefreshBulletInfo()
end

function BulletArea:RefreshBulletInfo()
    print("(Wzp)BulletArea:RefreshBulletInfo [ObjectName]=",GetObjectName(self))
    local PC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not PC then return end
    local tBagComp = UE.UBagComponent.Get(PC)
    if not tBagComp then return end

    for OnlySupportItemId, Widget in pairs(self.BulletMap) do
        local HasValidData =  Widget:HasValidData()
        if not HasValidData then
            local CurrentBulletArray = tBagComp:GetAllItemObjectByItemID(OnlySupportItemId)
            if CurrentBulletArray:Length() > 0 then
                local CurrenBulletInstance = CurrentBulletArray:Get(1)
                Widget:SetInvItemInfo(CurrenBulletInstance)
            end
        end
    end
end

function BulletArea:OnInventoryNew(InInventoryInstance, TagContainer)
    print("(Wzp)BulletArea:OnInventoryNew  [ObjectName]=",GetObjectName(self))
    local CurrentInventoryIdentity = InInventoryInstance:GetInventoryIdentity()
    print("(Wzp)BulletArea:OnInventoryNew  [CurrentInventoryIdentity.ItemID]=",CurrentInventoryIdentity.ItemID)
    local BulletWidget = self.BulletMap[CurrentInventoryIdentity.ItemID]
    if BulletWidget then
        BulletWidget:SetInvItemInfo(InInventoryInstance)
    end
end


function BulletArea:OnInventoryClearBag(InInventoryArrayStruct)
    for OnlySupportItemId, CurrentWidget in pairs(self.BulletMap) do
        if CurrentWidget then
            CurrentWidget:ResetInvItemInfo()
        end
    end
end


function BulletArea:OnInventoryItemNumChangeSingle(InGMPMessage_InventoryItemChange)
    if not InGMPMessage_InventoryItemChange.ItemObject then return end
    local TempLocalPC = InGMPMessage_InventoryItemChange.ItemObject:GetPlayerController()
    if not TempLocalPC then return end
    if TempLocalPC:GetWorld() ~= self:GetWorld() then return end
    local CurrentInventoryIdentity = InGMPMessage_InventoryItemChange.ItemObject:GetInventoryIdentity()
    -- 武器使用的弹药数量有修改时，更新UI
    local BulletWidget = self.BulletMap[CurrentInventoryIdentity.ItemID]
    if BulletWidget then
        BulletWidget:SetInvItemInfo(InGMPMessage_InventoryItemChange.ItemObject)
    end
end

function BulletArea:OnInventoryDestroy(InInventoryInstance)
    print("(Wzp)BulletArea:OnInventoryDestroy  [ObjectName]=",GetObjectName(self))
        local CurrentInventoryIdentity = InInventoryInstance:GetInventoryIdentity()
        print("(Wzp)BulletArea:OnInventoryDestroy  [CurrentInventoryIdentity.ItemID]=",CurrentInventoryIdentity.ItemID)
        local BulletWidget = self.BulletMap[CurrentInventoryIdentity.ItemID]
        if BulletWidget then
            BulletWidget:ResetInvItemInfo()
        end
end

function BulletArea:OnDestroy()
    print("(Wzp)BulletArea:OnDestroy  [ObjectName]=",GetObjectName(self))
    UserWidget.OnDestroy(self)
end

function BulletArea:OnFocusReceived(MyGeometry,InFocusEvent)
    print("(Wzp)BulletArea:OnFocusReceived  [ObjectName]=",GetObjectName(self))
    local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
    if IsInCursorMode then
        return
    end
    self.HandleSelect = true
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimationByName("SelectionAnim", 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function BulletArea:OnFocusLost(InFocusEvent)
    print("(Wzp)BulletArea:OnFocusLost  [ObjectName]=",GetObjectName(self))
    -- local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
    -- if IsInCursorMode then
    --     return
    -- end
    self.HandleSelect = false
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:StopAnimationByName("SelectionAnim")
end

function BulletArea:OnSelectArea()
    print("(Wzp)BulletArea:OnSelectArea  [ObjectName]=",GetObjectName(self))
    if not self.HandleSelect then
        return
    end

    self.BulletSlot_0:SetFocus()
    --SetFocus
end


function BulletArea:OnKeyDown(MyGeometry,InKeyEvent)  
	local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    --https://docs.unrealengine.com/4.26/en-US/API/Runtime/InputCore/EKeys/
    if PressKey == UE.FName("Gamepad_FaceButton_Bottom") then
        print("ItemSlotWeapon >> OnKeyDown")
        self:OnSelectArea()
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    return UE.UWidgetBlueprintLibrary.Unhandled()
end

function BulletArea:GetAllWidget()
    return {self.BulletSlot_0,self.BulletSlot_1,self.BulletSlot_2,self.BulletSlot_3,self.BulletSlot_4}
end 


function BulletArea:UpdateIsFocusable(bIsFocus)
    local AllWidget = self:GetAllWidget()
    for Index, Widget in pairs(AllWidget) do
        Widget.bIsFocusable = bIsFocus
    end
end

return BulletArea
