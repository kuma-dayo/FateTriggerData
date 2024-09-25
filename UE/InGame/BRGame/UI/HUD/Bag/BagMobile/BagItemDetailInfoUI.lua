local BagItemDetailInfoUIMobile = Class("Common.Framework.UserWidget")


local SelfVMTagName = "TagLayout.GamePlay.Bag.ItemDetail"

function BagItemDetailInfoUIMobile:GetSelfVM()
    local SelfVM
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if UIManager then
        SelfVM = UIManager:GetViewModelByName(SelfVMTagName)
    end
    return SelfVM
end

function BagItemDetailInfoUIMobile:OnInit()
    print("BagItemDetailInfoUIMobile >> OnInit.")

    local vm = self:GetSelfVM()
    if vm then
        self:InitView(vm)

        vm:K2_AddFieldValueChangedDelegateSimple("IsBetter",{ self, self.OnIsBetterUpdate })
        vm:K2_AddFieldValueChangedDelegateSimple("ItemName",{ self, self.OnItemNameUpdate })
        vm:K2_AddFieldValueChangedDelegateSimple("bShowItemType",{ self, self.OnbShowItemTypeUpdate })
        vm:K2_AddFieldValueChangedDelegateSimple("ItemTypeName",{ self, self.OnItemTypeNameUpdate })
        vm:K2_AddFieldValueChangedDelegateSimple("ItemSimpleDescribe",{ self, self.OnItemSimpleDescribeUpdate })
        vm:K2_AddFieldValueChangedDelegateSimple("ItemIconImage",{ self, self.OnItemIconImageUpdate })
        vm:K2_AddFieldValueChangedDelegateSimple("ItemBackgroundImage",{ self, self.OnItemBackgroundImageUpdate })
        vm:K2_AddFieldValueChangedDelegateSimple("bShowEnhanceDetailInfo",{ self, self.OnbShowEnhanceDetailInfoUpdate })
        vm:K2_AddFieldValueChangedDelegateSimple("EnhanceName",{ self, self.OnEnhanceNameUpdate })
        vm:K2_AddFieldValueChangedDelegateSimple("EnhanceDescription",{ self, self.OnEnhanceDescriptionUpdate })
        vm:K2_AddFieldValueChangedDelegateSimple("EnhanceIconImage",{ self, self.OnEnhanceIconImageUpdate })
        vm:K2_AddFieldValueChangedDelegateSimple("EnhanceBackgroundImage",{ self, self.OnEnhanceBackgroundImageUpdate })
    end

    UserWidget.OnInit(self)
end

function BagItemDetailInfoUIMobile:OnDestroy()
    print("BagItemDetailInfoUIMobile >> OnDestroy.")

    local vm = self:GetSelfVM()
    if vm then
        vm:K2_RemoveFieldValueChangedDelegateSimple("IsBetter",{ self, self.OnIsBetterUpdate })
        vm:K2_RemoveFieldValueChangedDelegateSimple("ItemName",{ self, self.OnItemNameUpdate })
        vm:K2_RemoveFieldValueChangedDelegateSimple("bShowItemType",{ self, self.OnbShowItemTypeUpdate })
        vm:K2_RemoveFieldValueChangedDelegateSimple("ItemTypeName",{ self, self.OnItemTypeNameUpdate })
        vm:K2_RemoveFieldValueChangedDelegateSimple("ItemSimpleDescribe",{ self, self.OnItemSimpleDescribeUpdate })
        vm:K2_RemoveFieldValueChangedDelegateSimple("ItemIconImage",{ self, self.OnItemIconImageUpdate })
        vm:K2_RemoveFieldValueChangedDelegateSimple("ItemBackgroundImage",{ self, self.OnItemBackgroundImageUpdate })
        vm:K2_RemoveFieldValueChangedDelegateSimple("bShowEnhanceDetailInfo",{ self, self.OnbShowEnhanceDetailInfoUpdate })
        vm:K2_RemoveFieldValueChangedDelegateSimple("EnhanceName",{ self, self.OnEnhanceNameUpdate })
        vm:K2_RemoveFieldValueChangedDelegateSimple("EnhanceDescription",{ self, self.OnEnhanceDescriptionUpdate })
        vm:K2_RemoveFieldValueChangedDelegateSimple("EnhanceIconImage",{ self, self.OnEnhanceIconImageUpdate })
        vm:K2_RemoveFieldValueChangedDelegateSimple("EnhanceBackgroundImage",{ self, self.OnEnhanceBackgroundImageUpdate })
    end

    UserWidget.OnDestroy(self)
end

function BagItemDetailInfoUIMobile:InitView(vm)
    print("BagItemDetailInfoUIMobile >> InitView.")

    self.WidgetSwitcher_Better:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.VerticalBox_Enhance:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function BagItemDetailInfoUIMobile:UpdataDetailInfo(InDetailData)
    print("BagItemDetailInfoUIMobile >> UpdataDetailInfo.")
    
    local vm = self:GetSelfVM()
    if vm and InDetailData then
        vm:UpdateDetail(InDetailData.ItemID or 0, InDetailData.ItemSkinId or 0, InDetailData.EnhanceId or "", InDetailData.InWeaponInstance or nil)
    end
end

function BagItemDetailInfoUIMobile:OnIsBetterUpdate(vm, fieldID)
    -- print("BagItemDetailInfoUIMobile >> OnIsBetterUpdate.")

    if vm.IsBetter > 0 then
        self.WidgetSwitcher_Better:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WidgetSwitcher_Better:SetActiveWidgetIndex(0)
    elseif vm.IsBetter < 0 then
        self.WidgetSwitcher_Better:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WidgetSwitcher_Better:SetActiveWidgetIndex(1)
    else
        self.WidgetSwitcher_Better:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function BagItemDetailInfoUIMobile:OnItemNameUpdate(vm, fieldID)
    -- print("BagItemDetailInfoUIMobile >> OnItemNameUpdate.")

    self.TextBlock_ItemName:SetText(vm.ItemName)
end

function BagItemDetailInfoUIMobile:OnbShowItemTypeUpdate(vm, fieldID)
    -- print("BagItemDetailInfoUIMobile >> OnbShowItemTypeUpdate.")

    if vm.bShowItemType then
        self.TextBlock_ItemType:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.TextBlock_ItemType:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function BagItemDetailInfoUIMobile:OnItemTypeNameUpdate(vm, fieldID)
    -- print("BagItemDetailInfoUIMobile >> OnItemTypeNameUpdate.")

    self.TextBlock_ItemType:SetText(vm.ItemTypeName)
end

function BagItemDetailInfoUIMobile:OnItemSimpleDescribeUpdate(vm, fieldID)
    -- print("BagItemDetailInfoUIMobile >> OnItemSimpleDescribeUpdate.")

    self.TextBlock_DetailDescribe:SetText(vm.ItemSimpleDescribe)
end

function BagItemDetailInfoUIMobile:OnItemIconImageUpdate(vm, fieldID)
    -- print("BagItemDetailInfoUIMobile >> OnItemIconImageUpdate.")

    self.Image_Item:SetBrushFromSoftTexture(vm.ItemIconImage, true)
end

function BagItemDetailInfoUIMobile:OnItemBackgroundImageUpdate(vm, fieldID)
    -- print("BagItemDetailInfoUIMobile >> OnItemBackgroundImageUpdate.")

    if vm.ItemBackgroundImage and vm.ItemBackgroundImage:IsValid() then
        self.Image_BG:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Image_BG:SetBrushFromSoftTexture(vm.ItemBackgroundImage, true)
    else
        self.Image_BG:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function BagItemDetailInfoUIMobile:OnbShowEnhanceDetailInfoUpdate(vm, fieldID)
    -- print("BagItemDetailInfoUIMobile >> OnbShowEnhanceDetailInfoUpdate.")

    if vm.bShowEnhanceDetailInfo then
        self.VerticalBox_Enhance:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    else
        self.VerticalBox_Enhance:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function BagItemDetailInfoUIMobile:OnEnhanceNameUpdate(vm, fieldID)
    -- print("BagItemDetailInfoUIMobile >> OnEnhanceNameUpdate.")

    self.TextBlock_EnhanceTitle:SetText(vm.EnhanceName)
end

function BagItemDetailInfoUIMobile:OnEnhanceDescriptionUpdate(vm, fieldID)
    -- print("BagItemDetailInfoUIMobile >> OnEnhanceDescriptionUpdate.")

    self.TextBlock_EnhanceDescribe:SetText(vm.EnhanceDescription)
end

function BagItemDetailInfoUIMobile:OnEnhanceIconImageUpdate(vm, fieldID)
    -- print("BagItemDetailInfoUIMobile >> OnEnhanceIconImageUpdate.")

    self.Image_Enhance:SetBrushFromSoftTexture(vm.EnhanceIconImage, false)
end

function BagItemDetailInfoUIMobile:OnEnhanceBackgroundImageUpdate(vm, fieldID)
    -- print("BagItemDetailInfoUIMobile >> OnEnhanceBackgroundImageUpdate.")

    self.Image_Enhance_Bg:SetBrushFromSoftTexture(vm.EnhanceBackgroundImage, false)
end


return BagItemDetailInfoUIMobile