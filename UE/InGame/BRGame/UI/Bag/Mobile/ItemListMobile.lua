
require "UnLua"
require ("InGame.BRGame.ItemSystem.PickSystemHelper")

local ItemListMobile = Class("Common.Framework.UserWidget")

-------------------------------------------- Init/Destroy ------------------------------------

function ItemListMobile:Initialize(Initializer)
    self.ReadyPickShowNum = 0
    self.SingleCol = true
end

function ItemListMobile:OnInit()
    -- self.MsgList = {
    --     { MsgName = "Bag.ReadyPickup.Update",	            Func = self.ReadyPickupUpdate,          bCppMsg = true, WatchedObject = nil},
    -- }
    UserWidget.OnInit(self)
end

function ItemListMobile:OnDestroy()
    UserWidget.OnDestroy(self)
end

-------------------------------------------- Function ------------------------------------

function ItemListMobile:Tick(MyGeometry, InDeltaTime)

end

function ItemListMobile:SwitchCol()
    self.SingleCol = not self.SingleCol
    --local Children = self.Grid_List:GetAllChildren()
    self.Grid_List:ClearChildren()
    self:ReadyPickupUpdate()
    -- for i = 1, Children:Length(), 1 do
    --     local child = Children:GetRef(i)
    --     if child then
    --         if self.SingleCol then
    --             self.Grid_List:AddChildToUniformGrid(child, i - 1, 0)
    --         else
    --             local row = math.floor((i - 1) / 2)
    --             self.Grid_List:AddChildToUniformGrid(child, row,  (i - 1) % 2)
    --         end
    --     end
    -- end
end

function ItemListMobile:ReadyPickupUpdate()
    local Character = UE.UGameplayStatics.GetPlayerCharacter(self, 0)
    if not Character then
        return
    end
    -- 重置个数
    self.ReadyPickShowNum = 0
    -- 隐藏所有 子Widget
    local AllChildWidget = self.Grid_List:GetAllChildren()
    local ChildNum = AllChildWidget:Length()
    for index = 1, ChildNum, 1 do
        local Widget = AllChildWidget:GetRef(index)
        if Widget then
            Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end

    local PickList = PickSystemHelper.GetLastReadyToPickObjArray(Character)
    if not PickList then
        return
    end
    
    for index = 1, PickList:Length(), 1 do
        local PickupObj = PickList:GetRef(index)
        if not PickupObj then
            goto continue
        end

        local NotLoopToMax = index <= self.Grid_List:GetChildrenCount()
        local OldChildWidget = self.Grid_List:GetChildAt(index - 1)
        if OldChildWidget and NotLoopToMax then
            OldChildWidget:SetDetail(PickupObj)
            OldChildWidget:SetVisibility(UE.ESlateVisibility.Visible)
            self.ReadyPickShowNum = self.ReadyPickShowNum + 1
        else
            local ReadyPickWidget = UE.UWidgetBlueprintLibrary.Create(self, self.ReadyPickWidgetClass)
            if ReadyPickWidget then
                ReadyPickWidget:SetDetail(PickupObj)
                if self.SingleCol then
                    self.Grid_List:AddChildToUniformGrid(ReadyPickWidget, index - 1, 0)
                else
                    local row = math.floor((index - 1) / 2)
                    self.Grid_List:AddChildToUniformGrid(ReadyPickWidget, row,  (index - 1) % 2)
                end
                self.ReadyPickShowNum = self.ReadyPickShowNum + 1
            end
        end

        ::continue::
    end

    if self.ReadyPickShowNum > 0 then
        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    --ScrollBar出现后将ScrollBox设置为Visible
    local ScrollBoxDesiredSize = self.ScrollBox:GetDesiredSize()
    local ScrollBoxLocalSize = UE.USlateBlueprintLibrary.GetLocalSize(self.ScrollBox:GetCachedGeometry())
    if  ScrollBoxDesiredSize.Y > ScrollBoxLocalSize.Y then
        self.ScrollBox:SetVisibility(UE.ESlateVisibility.Visible)
    else
        self.ScrollBox:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

return ItemListMobile