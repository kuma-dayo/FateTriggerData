--

local QuickPickItem = Class("Common.Framework.UserWidget")

function QuickPickItem:OnInit()
    self.ItemID = 0
    self.ItemInstanceID = 0
    self.ItemNum = 0
    self.ItemMaxNum = 0
    self.ParentWidget = nil

    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickAll,              Func = self.OnDiscardAll ,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickPart,             Func = self.OnDiscardPart,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
    }
    self.MouseHover = false
    UserWidget.OnInit(self)
end

function QuickPickItem:OnInitData(ParentWidget)
    self.ParentWidget = ParentWidget
end

function QuickPickItem:OnDestroy()

    UserWidget.OnDestroy(self)
end


function QuickPickItem:OnMouseButtonDown(MyGeometry, MouseEvent)

    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Click_01")
    if (self.ItemID == 0 or self.ItemInstanceID == 0) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if BridgeHelper.IsMobilePlatform() then
        -- Mobile平台
        self.DragDistance = 0


        if not MouseKey then return UE.UWidgetBlueprintLibrary.Handled() end

        local CurrentDragPositionInViewport = UE.UGFUnluaHelper.FPointerEvent_GetScreenSpacePosition(MouseEvent)
        self.DragStartPosition = CurrentDragPositionInViewport

        return UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent, self, MouseKey)
    else
        if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton then
            return UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent,self, MouseKey)
        end
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

-- ID1009564 快捷拾取页面不支持拖拽

function QuickPickItem:OnMouseButtonUp(MyGeometry, MouseEvent)
    if not self.ParentWidget then return end
    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Click_01")
    if (self.ItemID == 0 or self.ItemInstanceID == 0) then
        self.ParentWidget:PickItem()
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then return UE.UWidgetBlueprintLibrary.Handled() end

    if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton then
            self.ParentWidget:ReplaceItem(self.ItemID,self.ItemInstanceID,self.ItemNum)
    elseif MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton then
        self.ParentWidget:DiscardItem(self.ItemID,self.ItemInstanceID,self.ItemNum)
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function QuickPickItem:ReplaceOrPickItem()
    if (self.ItemID == 0 or self.ItemInstanceID == 0) then
        self.ParentWidget:PickItem()
        return UE.UWidgetBlueprintLibrary.Handled()
    else
        self.ParentWidget:ReplaceItem(self.ItemID,self.ItemInstanceID,self.ItemNum)
    end
end

function QuickPickItem:ResetItemInfo()
    self.ItemID = 0
    self.ItemInstanceID = 0
    self.ItemMaxNum = 0
    self.ItemNum=0
    self.ParentWidget = nil
    self:SetEmptyState(true)

end

function QuickPickItem:GetItemData()
    return  self.ItemID ,self.ItemInstanceID , self.ItemMaxNum ,self.ItemNum
end

function QuickPickItem:UpdateNum(NewNum)
    if (self.ItemNum ~= NewNum) then
        self.ItemNum = NewNum
        self.TextBlock_Num:SetText(tostring(self.ItemNum))
    end
    self:UpdateItemNumBar(NewNum)
end


function QuickPickItem:SetItemInfo(InInventoryInstance)
    -- 物品ID设置
    local Identity = InInventoryInstance:GetInventoryIdentity()
    local ItemNum = InInventoryInstance:GetStackNum()
    self.ItemID = Identity.ItemID
    self.ItemInstanceID = Identity.ItemInstanceID

    local TempPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not TempPC then
        return
    end
    local BagComp = UE.UBagComponent.Get(TempPC)


    self.TextBlock_Num:SetVisibility(bIsShowItemNum and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Hidden)

    self.Image_Item:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    local TempItemType, IsFindTempItemType = UE.UItemSystemManager.GetItemDataFName(self,self.ItemID, "ItemType",GameDefine.NItemSubTable.Ingame,"ItemSlotNormal:SetItemInfo")
    if  IsFindTempItemType then
        self.bShowItemNumBar = (TempItemType ~= ItemSystemHelper.NItemType.Bullet)
        self.CountLine:SetVisibility(self.bShowItemNumBar and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    end

    -- 物品图标
    local CurItemIcon, IsExistIcon = UE.UItemSystemManager.GetItemDataFString(self, self.ItemID, "ItemIcon", GameDefine.NItemSubTable.Ingame, "ItemSlotNormal:SetItemInfo")
    if IsExistIcon then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurItemIcon)
        self.Image_Item:SetBrushFromSoftTexture(ImageSoftObjectPtr, true)
    end

    -- 物品等级
    local ItemLevel, IsFindItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, self.ItemID, "ItemLevel", GameDefine.NItemSubTable.Ingame, "ItemSlotNormal:SetItemInfo")
    if IsFindItemLevel then
        local BackgroundImage = self.BackgroundImageMap:Find(ItemLevel)
        if BackgroundImage then
            self.BrushImage = BackgroundImage
        end
    end

    local RuntimeMaxStack = BagComp:GetRuntimeInventoryMaxStack(self.ItemID)
    self.ItemMaxNum = RuntimeMaxStack

    self:UpdateNum(ItemNum)
    self:SetEmptyState(false)

    --如果最大数量为1，不显示数量文本
    local bIsShowItemNum = self.ItemMaxNum > 1
    if bIsShowItemNum then
        self:UpdateNum(ItemNum)
    end

    -- 倍镜特殊处理
    local MiscSystemIns = UE.UMiscSystem.GetMiscSystem(self)
    local MagnifierType = MiscSystemIns.MagnifierTypeMap:Find(self.ItemID)
    self.Text_ScaleMutiplay:SetVisibility(MagnifierType and UE.ESlateVisibility.SelfHitTestInvisible or
                                            UE.ESlateVisibility.Collapsed)
    if MagnifierType then
        -- 显示倍镜倍率文本
        self.Text_ScaleMutiplay:SetText(MagnifierType.Multiple)
    end

end

function QuickPickItem:UpdateItemNumBar(NewItemNum)

    if  self.bShowItemNumBar then

        local BarNum = self.CountLine:GetChildrenCount()
        for index = 1, BarNum do
            local BarWidget = self.CountLine:GetChildAt(index-1)

            if index > self.ItemMaxNum then
                BarWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
            else
                BarWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                BarWidget:SetNumState( index <= NewItemNum )
            end
        end

    end

end


function QuickPickItem:SetEmptyState(bEmpty)
    self.WS_State:SetActiveWidgetIndex(bEmpty and 0 or 1)
end

function QuickPickItem:SetLockState(bLock)
    self:SetVisibility(bLock and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible)
end

-- 鼠标按键移入
function QuickPickItem:OnMouseEnter(InMyGeometry, InMouseEvent)
    self.MouseHover = true
    self.Img_Border:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end


-- 鼠标按键移出
function QuickPickItem:OnMouseLeave(InMouseEvent)
    self.MouseHover = false
    self.Img_Border:SetVisibility(UE.ESlateVisibility.Collapsed)
end


function QuickPickItem:OnFocusReceived(MyGeometry,InFocusEvent)
    self.ParentWidget:SetGamepadSelectWidget(self)
    self.Img_Border:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function QuickPickItem:OnFocusLost(InFocusEvent)
    self.Img_Border:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function QuickPickItem:OnDiscardPart(InInputData)
    if not self.MouseHover then
        return
    end
    self.ParentWidget:DiscardItem(self.ItemID,self.ItemInstanceID,self.ItemNum)
end


return QuickPickItem
