require "UnLua"

local EquipmentArea = Class("Common.Framework.UserWidget")

function EquipmentArea:OnInit()
    print("EquipmentArea", ">> OnInit, ", GetObjectName(self))

    -- self.MsgList={
    --     { MsgName = GameDefine.MsgCpp.BagUI_UseItem,             Func = self.OnSelectArea,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
    -- }
    UserWidget.OnInit(self)
end

function EquipmentArea:OnDestroy()
    print("EquipmentArea", ">> OnDestroy, ", GetObjectName(self))
    UserWidget.OnDestroy(self)
end


function EquipmentArea:GetBagWidget()
    return self.BP_Bag
end

function EquipmentArea:GetArmorHeadWidget()
    return self.BP_ArmorHead
end


function EquipmentArea:GetArmorBodyWidget()
    return self.BP_ArmorBody
end

function EquipmentArea:CurrencyInBagWidget()
    return self.BP_CurrencyInBag
end

function EquipmentArea:GetAllWidget()
    local ArmorHead = self:GetArmorHeadWidget()
    local ArmorBody =  self:GetArmorBodyWidget()
    local BagWidget = self:GetBagWidget()
    local CurrencyInBag = self:CurrencyInBagWidget()
    return ArmorHead,ArmorBody,BagWidget,CurrencyInBag
end

function EquipmentArea:OnFocusReceived(MyGeometry,InFocusEvent)
    print("[Wzp]EquipmentArea:OnFocusReceived")
    self.HandleSelect = true
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimationByName("SelectionAnim", 0, 0, UE.EUMGSequencePlayMode.Forward, 1, false)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function EquipmentArea:OnFocusLost(InFocusEvent)
    print("[Wzp]EquipmentArea:OnFocusLost")
    self.HandleSelect = false
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:StopAnimationByName("SelectionAnim")
end

function EquipmentArea:OnSelectArea()
    if not self.HandleSelect then
        return
    end

    self.BP_ArmorHead:SetFocus()
end


function EquipmentArea:OnKeyDown(MyGeometry,InKeyEvent) 
	local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey == UE.FName("Gamepad_FaceButton_Bottom") then
        self:OnSelectArea()
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    return UE.UWidgetBlueprintLibrary.Unhandled()
end

function EquipmentArea:UpdateIsFocusable(bIsFocus)
    local ArmorHeadWidget, ArmorBodyWidget, BagWidgetWidget, CurrencyInBagWidget = self:GetAllWidget()
    ArmorHeadWidget.bIsFocusable = bIsFocus
    ArmorBodyWidget.bIsFocusable = bIsFocus
    BagWidgetWidget.bIsFocusable = bIsFocus
    CurrencyInBagWidget.bIsFocusable = bIsFocus
end


return EquipmentArea
