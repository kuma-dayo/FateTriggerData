require "UnLua"

local ItemSlotLayOut = Class()

function ItemSlotLayOut:Construct()
    -- 当前分类ItemLayout的Item个数
    self.CurrentLayoutItemNum = 0

    -- 特殊物品类型的背包个数制逻辑
    self.ContainLimitNum = 0
    local IsOpenLimitLogic = false
    local InventoryManagerSettingCDO = UE.UGFUnluaHelper.GetDefaultObject(self.InventoryManagerSettingClass)
    if InventoryManagerSettingCDO then
        IsOpenLimitLogic = InventoryManagerSettingCDO.IsOpenInventoryManagerLimitNumByItemType
    end
    if IsOpenLimitLogic == true then
        local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
        if not TempLocalPC then return end
        local TempBagComponent = UE.UBagComponent.Get(TempLocalPC)
        if not TempBagComponent then return end
        self.ContainLimitNum = TempBagComponent:GetContainNumLimit(self.ContainItemType)

        self:TryFillToEmptySlot()
    end
end

function ItemSlotLayOut:Destruct()
    self.CurrentLayoutItemNum = nil
end

function ItemSlotLayOut:GetLimitNumInInventoryManagerByItemType()
    local ReturnValueInt = 0

    return ReturnValueInt
end

function ItemSlotLayOut:LayoutItemCountReset()
    self.CurrentLayoutItemNum = 0

    local ChildNum = self.UGP_ItemListPanel:GetChildrenCount()
    for index = 1, ChildNum, 1 do
        local Widget = self.UGP_ItemListPanel:GetChildAt(index - 1)
        if Widget then
            Widget:SetFlushFlag(false)
        end
    end
end

function ItemSlotLayOut:LayoutItemCountAddOne()
    self.CurrentLayoutItemNum = self.CurrentLayoutItemNum + 1
end

-- 直接在uniform容器中插入一个指定类型的Widget，不论是否重复
-- Uniform容器的布局是每一行4列
-- 函数会返回加入的 Widget。如果执行失败则返回nil
function ItemSlotLayOut:AddItem(InWidgetClass)
    local CurBagItemWidget = UE.UWidgetBlueprintLibrary.Create(self, InWidgetClass)
    local ReturnWidget = nil
    if CurBagItemWidget then
        local ChildNum = self.UGP_ItemListPanel:GetChildrenCount() + 1  -- 加的1就是即将插入的新物品
        -- 根据Uniform容器的布局计算插入坐标
        local InRow = ChildNum // 4	-- lua 版本5.3才支持
		local InColumn = ChildNum % 4
        if InColumn ~= 0 then
            -- 说明有余数，最后一行不满3个物品
            self.UGP_ItemListPanel:AddChildToUniformGrid(CurBagItemWidget, InRow, InColumn - 1)
        else
            -- 刚好整除，说明每行4列的布局刚刚好
            self.UGP_ItemListPanel:AddChildToUniformGrid(CurBagItemWidget, InRow - 1, 3)
        end
        --self.UGP_ItemListPanel:AddChild(CurBagItemWidget)
        ReturnWidget = CurBagItemWidget
    end
    return ReturnWidget
end

-- 将uniform容器中所有的Item子控件设置为隐藏
-- 为了提高性能，Item数量为0时其实并不会真正删除，只是把他设置为隐藏。当数量不为0时又会Update设置为显示
function ItemSlotLayOut:HideAllItem()
    local ChildNum = self.UGP_ItemListPanel:GetChildrenCount()
    for index = 1, ChildNum, 1 do
        local Widget = self.UGP_ItemListPanel:GetChildAt(index - 1)
        if Widget then
            local RetItemID, RetItemInstanceID = Widget:GetSlotNormalInventoryIdentity()
            Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

-- 在uniform容器中更新一个Item的信息，这个Item必须已经存在，否则将会创建新的Item
-- 如果创建了新的Item，函数会返回这个Item Class。如果只是更新了旧的Item数据（并没有新建）或者执行失败，则返回nil
function ItemSlotLayOut:UpDateItem(InInventoryIdentity, InIteamNumber, InParentWidget)
    local ReturnWidget= nil
    local ExistItemWidget = self:FindItemWidgetByIdentity(InInventoryIdentity)
    if ExistItemWidget then
        -- 更新数据
        ExistItemWidget:SetItemInfo(InInventoryIdentity, InIteamNumber, InParentWidget)
        ExistItemWidget:SetVisibility(UE.ESlateVisibility.Visible)
    else
        ReturnWidget = self:AddItem(self.BagItemWidgetClass)
        if ReturnWidget then
            ReturnWidget:SetItemInfo(InInventoryIdentity, InIteamNumber, InParentWidget)
        end
    end
    return ReturnWidget
end

-- 在uniform容器中更新一个Item的信息，这个Item必须已经存在，否则将会创建新的Item
-- 如果创建了新的Item，函数会返回这个Item Class。如果只是更新了旧的Item数据（并没有新建）或者执行失败，则返回nil
function ItemSlotLayOut:LayoutUpdateItem(InInventoryInstance, InParentWidget)
    local ExistItemWidget = self:FindLayoutNextItemWidget()
    if not ExistItemWidget then
        ExistItemWidget = self:AddItem(self.BagItemWidgetClass)
    end

    if ExistItemWidget then
        -- 更新数据
        ExistItemWidget:SetItemInfo(InInventoryInstance:GetInventoryIdentity(), InInventoryInstance:GetStackNum(), InParentWidget)
        ExistItemWidget:SetVisibility(UE.ESlateVisibility.Visible)
        ExistItemWidget:SetFlushFlag(true)
        self:LayoutItemCountAddOne()
    end


end

function ItemSlotLayOut:FindLayoutNextItemWidget()
    local ReturnWidget = nil

    local ChildNum = self.UGP_ItemListPanel:GetChildrenCount()

    if self.CurrentLayoutItemNum < ChildNum then
        local Widget = self.UGP_ItemListPanel:GetChildAt(self.CurrentLayoutItemNum)
        if Widget then
            ReturnWidget = Widget
        end
    end

    return ReturnWidget
end

function ItemSlotLayOut:HideOverCountWidget()
    local ChildNum = self.UGP_ItemListPanel:GetChildrenCount()
    for index = 1, ChildNum, 1 do
        local Widget = self.UGP_ItemListPanel:GetChildAt(index - 1)
        if Widget then
            Widget:CheckFluchFlag()
        end
    end
end

-- 查找指定物品，返回物品在uniform容器中对应的index
-- 如果查找失败。返回nil
function ItemSlotLayOut:FindItemIndexByIdentity(InInventoryIdentity)
    local RetIndex = nil
    local ChildNum = self.UGP_ItemListPanel:GetChildrenCount()
    for index = 1, ChildNum, 1 do
        local Widget = self.UGP_ItemListPanel:GetChildAt(index - 1)

        if Widget then
            local RetItemID, RetItemInstanceID = Widget:GetSlotNormalInventoryIdentity()
            if (InInventoryIdentity.ItemID == RetItemID) and (InInventoryIdentity.ItemInstanceID == RetItemInstanceID) then
                RetIndex = index - 1
                break
            end
        end
    end
    return RetIndex
end

-- 查找指定物品，返回物品在 uniform 容器中对应的 Widget
-- 如果查找失败。返回nil
function ItemSlotLayOut:FindItemWidgetByIdentity(InInventoryIdentity)
    local ReturnWidget = nil
    local ChildNum = self.UGP_ItemListPanel:GetChildrenCount()
    for index = 1, ChildNum, 1 do
        local Widget = self.UGP_ItemListPanel:GetChildAt(index - 1)

        if Widget then
            local RetItemID, RetItemInstanceID = Widget:GetSlotNormalInventoryIdentity()
            if (InInventoryIdentity.ItemID == RetItemID) and (InInventoryIdentity.ItemInstanceID == RetItemInstanceID) then
                ReturnWidget = Widget
                break
            end
        end
    end
    return ReturnWidget
end

-- 在 GridUniform 容器中删除所有 Item 对象
function ItemSlotLayOut:ClearAllItems()
    -- Step 1：在 ClearChildren() 之前，需要对所有子控件 调用 在销毁之前 需要执行的逻辑
    local ItemListPanelChildNum = self.UGP_ItemListPanel:GetChildrenCount()
    for index = 1, ItemListPanelChildNum, 1 do
        local ItemListChildWidget = self.UGP_ItemListPanel:GetChildAt(index - 1)
        if ItemListChildWidget and (ItemListChildWidget.WillDestroy) then
            ItemListChildWidget:WillDestroy()
        end
    end

    -- Step 2
    self.UGP_ItemListPanel:ClearChildren()
end

-- 在uniform容器中目标Item对象
-- 如果查找失败。返回false, 成功返回true
function ItemSlotLayOut:ClearItemByIdentity(InInventoryIdentity)
    local RetCode = false

    local RetIndex = self:FindItemIndexByIdentity(InInventoryIdentity)
    if  RetIndex == nil then
        return RetCode
    else
        local RemoveResult = self.UGP_ItemListPanel:RemoveChildAt(RetIndex)
        if  RemoveResult == true then
            RetCode = true
        else
            print("ItemSlotLayOut::ClearItemByIdentity Clear Item Failed, self.ScrollBox_Item:RemoveChildAt() return false")
        end

    end
    return RetCode

end

function ItemSlotLayOut:TryFillToEmptySlot()
    local CurrentChildNum = self.UGP_ItemListPanel:GetChildrenCount()
    if self.ContainLimitNum > 0 then
        if self.CurrentLayoutItemNum < CurrentChildNum then
            for index = self.CurrentLayoutItemNum + 1, CurrentChildNum, 1 do
                local Widget = self.UGP_ItemListPanel:GetChildAt(index - 1)
                if Widget then
                    Widget:SetItemSlotToEmptySlotStyle()
                    Widget:SetFlushFlag(true)
                    self:LayoutItemCountAddOne()
                end
            end
        end

        local CurrentChildNumNew = self.UGP_ItemListPanel:GetChildrenCount()
        if CurrentChildNumNew < self.ContainLimitNum then
            local WillAddWidgetNum = self.ContainLimitNum - CurrentChildNumNew
            for i = 1, WillAddWidgetNum, 1 do
                local NewWidget = self:AddItem(self.BagItemWidgetClass)
                if NewWidget then
                    NewWidget:SetItemSlotToEmptySlotStyle()
                    NewWidget:SetFlushFlag(true)
                    self:LayoutItemCountAddOne()
                end
            end
        end

    end
end


return ItemSlotLayOut