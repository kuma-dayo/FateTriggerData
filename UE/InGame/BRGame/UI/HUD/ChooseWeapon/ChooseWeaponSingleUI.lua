require "UnLua"

local ChooseWeaponSingleUI = Class("Common.Framework.UserWidget")

function ChooseWeaponSingleUI:Construct()
    self.MagItemList = nil
end

function ChooseWeaponSingleUI:InitItemCombinationId(ChooseItemGroup, Index)
    print("dyptest ChooseWeaponSingleUI:InitItemCombinationId")
    self.Index = Index
    self.ChooseItemGroup = ChooseItemGroup
    -- 根据物品显示
    local len = ChooseItemGroup.ItemListArray:Length()

    if len <= 2 then
        print("ChooseItemCombinationUI error! Item ListArray num less then 2")
    end

    self.MainItemCombinaton = ChooseItemGroup.ItemListArray:Get(1)
    self.SecondItemCombinaton = ChooseItemGroup.ItemListArray:Get(2)
    self.MainWeaponId = self.MainItemCombinaton.ItemCellArray:Get(1).ItemId
    self.SecondWeaponId = self.SecondItemCombinaton.ItemCellArray:Get(1).ItemId

    -- self.Description = ChooseItemGroup.GroupDescribe
    -- self.GUITextBlock:SetText(self.Description)

    local DefaultMainMagItem = ChooseItemGroup.ItemListArray:Get(1).DefaultItemCellArray:Get(1)
    if DefaultMainMagItem == nil then
        print("ChooseItemCombinationUI error! Don't have Default Item Cell")
    end
    self.MainMagAttribute = DefaultMainMagItem.ItemAttribute

    local DefaultSecondMagItem = ChooseItemGroup.ItemListArray:Get(2).DefaultItemCellArray:Get(1)
    if DefaultSecondMagItem == nil then
        print("ChooseItemCombinationUI error! Don't have Default Item Cell")
    end
    self.SecondMagAttribute = DefaultSecondMagItem.ItemAttribute

    self.MainMagId = DefaultMainMagItem.ItemId
    self.SecondMagId = DefaultSecondMagItem.ItemId

    if len ~= 3 then
        print("ChooseItemCombinationUI error! Item ListArray num is not 3. Num is ",len)
    end
    self:UpdateUIperformance()
    -- Bind Button
    self.Button_Item.OnClicked:Add(self, self.OnChooseSelf)
    self.Button_Item.OnPressed:Add(self, self.OnSelfButtonPressed)
    self.Button_Item.OnReleased:Add(self, self.OnSelfButtonReleased)
    self.Button_Item.OnHovered:Add(self, self.OnSelfButtonHovered)
    self.Button_Item.OnUnhovered:Add(self, self.OnSelfButtonUnhovered)

    self.BP_AimItemWidget1:InitWeaponAim(self.MainWeaponId, self.MainMagId, true, self)
    self.BP_AimItemWidget2:InitWeaponAim(self.SecondWeaponId, self.SecondMagId, false, self)

end

function ChooseWeaponSingleUI:OnSelfButtonHovered()
    self.WidgetSwitcher_BgState:SetActiveWidgetIndex(1)
end

function ChooseWeaponSingleUI:OnSelfButtonUnhovered()
    self.WidgetSwitcher_BgState:SetActiveWidgetIndex(0)
end

function ChooseWeaponSingleUI:OnSelfButtonPressed()
    self.WidgetSwitcher_BgState:SetActiveWidgetIndex(2)
end

function ChooseWeaponSingleUI:OnSelfButtonReleased()
    self.WidgetSwitcher_BgState:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.WidgetSwitcher_BgState:SetActiveWidgetIndex(0)
end

-- 更新UI整体表现
function ChooseWeaponSingleUI:UpdateUIperformance()
    -- 显示主武器及其配件
    self.WBP_ReuseList_Parts1.OnUpdateItem:Add(self, self.OnMainItemUIUpdate)
    local MagRow_MainWeapon = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.WeaponDT, self.MainWeaponId)
    local MainWeaponSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(MagRow_MainWeapon.SlotImage)
    self.Image_Icon1:SetBrushFromSoftTexture(MainWeaponSoftObjectPtr, false)
    self.Text_Name1:SetText(self:GetRealName(MagRow_MainWeapon.ItemName))
    self.WBP_ReuseList_Parts1:Reload(self.MainItemCombinaton.ItemCellArray:Length() - 1)

    -- 显示副武器及其配件
    self.WBP_ReuseList_Parts2.OnUpdateItem:Add(self, self.OnSecondItemUIUpdate)
    local MagRow_SecondWeapon = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.WeaponDT, self.SecondWeaponId)
    local SecondWeaponSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(MagRow_SecondWeapon.SlotImage)
    self.Image_Icon2:SetBrushFromSoftTexture(SecondWeaponSoftObjectPtr, false)
    self.Text_Name2:SetText(self:GetRealName(MagRow_SecondWeapon.ItemName))
    self.WBP_ReuseList_Parts2:Reload(self.SecondItemCombinaton.ItemCellArray:Length() - 1)

    -- 显示其他物品
    local OtherItems = self.ChooseItemGroup.ItemListArray:Get(3).ItemCellArray
    local OtherItemsNum = OtherItems:Length()
    print("ChooseItemCombinationUI. Other Item Type Num is", OtherItemsNum)

    local CurItemId = OtherItems:Get(1).ItemId
    local CurItemNum = OtherItems:Get(1).ItemNum
    local MagRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.ItemDT, CurItemId)
    local ItemIconSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(MagRow.ItemIcon)
    local ItemName = MagRow.ItemName
    self.Image_Icon:SetBrushFromSoftTexture(ItemIconSoftObjectPtr, false)
    self.Text_IconName:SetText(ItemName)
    self.Text_IconNum:SetText("X" .. tostring(CurItemNum))
end

function ChooseWeaponSingleUI:OnMainItemUIUpdate(Widget, Index)
    local i = Index + 1
    local CurMainItemWidget = Widget

    -- 配置项的第一把是武器，其他是配件
    local CurItem = self.MainItemCombinaton.ItemCellArray:Get(i + 1)
    local MagRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.ItemDT, CurItem.ItemId)
    local ItemIconSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(MagRow.ItemIcon)
    CurMainItemWidget.Image_Icon:SetBrushFromSoftTexture(ItemIconSoftObjectPtr, false)
end

function ChooseWeaponSingleUI:OnSecondItemUIUpdate(Widget, Index)
    local i = Index + 1
    local CurSecondItemWidget = Widget

    -- 配置项的第一把是武器，其他是配件
    local CurItem = self.SecondItemCombinaton.ItemCellArray:Get(i + 1)
    local MagRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.ItemDT, CurItem.ItemId)
    local ItemIconSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(MagRow.ItemIcon)
    CurSecondItemWidget.Image_Icon:SetBrushFromSoftTexture(ItemIconSoftObjectPtr, false)
end

function ChooseWeaponSingleUI:GetRealName(InName)
    return StringUtil.Format(InName)
end

-- 改变当前选择的准镜
function ChooseWeaponSingleUI:OnChangeMagId(MagId, IsMain)
    if IsMain then
        self.MainMagId = MagId
    else
        self.SecondMagId = MagId
    end
    self:OnChooseSelf()
end

-- 点选此界面
function ChooseWeaponSingleUI:OnChooseSelf()
    --self.WidgetSwitcher_BgState:SetActiveWidgetIndex(0)
    self.ChooseItemCombination:Broadcast(self.MainMagId, self.SecondMagId, self.Index)
end

-- 改变选择状态
function ChooseWeaponSingleUI:ChangeSelectState(NewState)
    if NewState then
        self.Image_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WidgetSwitcher_BgState:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.Image_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WidgetSwitcher_BgState:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

-- 改变准镜子界面的显示状态
function ChooseWeaponSingleUI:ChangeMagUIState(NewState)
    if NewState then
        self.BP_AimItemWidget1.WidgetSwitcher_State:SetActiveWidgetIndex(1)
        self.BP_AimItemWidget2.WidgetSwitcher_State:SetActiveWidgetIndex(1)
    else
        self.BP_AimItemWidget1.WidgetSwitcher_State:SetActiveWidgetIndex(0)
        self.BP_AimItemWidget2.WidgetSwitcher_State:SetActiveWidgetIndex(0)
    end
end
--
return ChooseWeaponSingleUI

