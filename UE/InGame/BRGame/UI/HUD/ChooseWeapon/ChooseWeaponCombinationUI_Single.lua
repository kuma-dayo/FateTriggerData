require "UnLua"

local ChooseWeaponCombinationUI_Single = Class("Common.Framework.UserWidget")

function ChooseWeaponCombinationUI_Single:Construct()
    self.MagItemList = nil
end

    
function ChooseWeaponCombinationUI_Single:InitItemCombinationId(ChooseItemGroup)
    self.ChooseItemGroup = ChooseItemGroup
    --根据物品显示
    local len = ChooseItemGroup.ItemListArray:Length()

    if len <= 2 then
        print("ChooseItemCombinationUI error! Item ListArray num less then 2")
    end

    self.MainItemCombinaton = ChooseItemGroup.ItemListArray:Get(1)
    self.SecondaryItemCombinaton = ChooseItemGroup.ItemListArray:Get(2)
    self.MainWeaponId = self.MainItemCombinaton.ItemCellArray:Get(1).ItemId
    self.SecondaryWeaponId = self.SecondaryItemCombinaton.ItemCellArray:Get(1).ItemId

    self.Description = ChooseItemGroup.GroupDescribe
    self.GUITextBlock:SetText(self.Description)

    self.GUITextBlock_Main:SetText(self.MainWeaponId)
    self.GUITextBlock_Second:SetText(self.SecondaryWeaponId)


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
    self.SecondaryMagId = DefaultSecondMagItem.ItemId

    --显示其他物品
    if len == 3 then
        local OtherItems = ChooseItemGroup.ItemListArray:Get(3).ItemCellArray
        local OtherItemsNum = OtherItems:Length()
        print("ChooseItemCombinationUI. Other Item Type Num is", OtherItemsNum)
        for i = 1, OtherItemsNum do
            local CurItemSingleWidget = UE.UWidgetBlueprintLibrary.Create(self, self.SingleItemUIClass)
            local CurItemId = OtherItems:Get(i).ItemId
            local MagRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.ItemDT, CurItemId)
            local ItemIconSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(MagRow.ItemIcon)
            CurItemSingleWidget:InitItemId(CurItemId, ItemIconSoftObjectPtr)
            self.HorizontalBox:AddChildToHorizontalBox(CurItemSingleWidget)
        end
    else
        print("ChooseItemCombinationUI error! Item ListArray num is not 3. Num is ",len)
    end

    --Bind Click
    self.GUIButton.OnClicked:Add(self, self.OnChooseSelf) 
end

--点选此界面,显示准镜界面
function ChooseWeaponCombinationUI_Single:OnChooseSelf()
    local UIManager = UE.UGUIManager.GetUIManager(self)
    local UIHandle = UIManager:TryLoadDynamicWidget("UMG_WeaponCombination_Magnification",nil) 
    self.MagWidget = UIManager:GetWidgetByDynamicWidgetHandle(UIHandle)
    self.MagWidget:InitWeaponId(self.MainWeaponId,self.SecondaryWeaponId,self.MainMagId,self.SecondaryMagId)
    self.MagWidget.ChooseAllMag:Add(self, self.ChooseAllMag)
end

--收到选择的准镜及武器
function ChooseWeaponCombinationUI_Single:ChooseAllMag(MagItemList)
    self.MainMagId = MagItemList.ItemCellArray:Get(1).ItemId
    self.SecondaryMagId = MagItemList.ItemCellArray:Get(2).ItemId
    self.MagItemList = MagItemList
    self.GiveItemGroup.ItemListArray:Clear()

    --将FChooseItemCombineGroup转换为FGiveInventoryItemList
    local Len_Item = self.ChooseItemGroup.ItemListArray:Length()
    local Len_Mag = self.MagItemList.ItemCellArray:Length()

    for i = 1 , Len_Item do
        --这里将ItemListArray改为倒序，目的是为了加完两把枪后，手上拿的是配置中的第一个武器
        local CurGiveItemList = UE.FGiveInventoryItemList()
        CurGiveItemList.ItemCellArray = self.ChooseItemGroup.ItemListArray:Get(Len_Item - i + 1).ItemCellArray
        if Len_Item - i + 1 <= Len_Mag then
            CurGiveItemList.ItemCellArray:Add(self.MagItemList.ItemCellArray:Get(Len_Item - i + 1))
        end
        self.GiveItemGroup.ItemListArray:Add(CurGiveItemList)
    end


    self.ChooseItemCombination:Broadcast(self.GiveItemGroup, self.MagItemList)

    local UIManager = UE.UGUIManager.GetUIManager(self)
    UIManager:TryCloseDynamicWidget("UMG_WeaponCombination_Magnification")
    self.MagWidget.ChooseAllMag:Remove(self, self.ChooseAllMag)
end
--
return ChooseWeaponCombinationUI_Single
 










