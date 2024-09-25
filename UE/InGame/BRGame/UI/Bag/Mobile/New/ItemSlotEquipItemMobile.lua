local ItemSlotEquipItemMobile = Class("Common.Framework.UserWidget")

function ItemSlotEquipItemMobile:OnInit()
    print("NewBagMobile@ItemSlotBulletAreaMobile Init")

    self:InitData()
    self:InitUI()
    self:InitGameEvent()
    self:InitUIEvent()

    UserWidget.OnInit(self)
end

function ItemSlotEquipItemMobile:SetArmorData(ItemData)
    self.ItemData = ItemData
end
--   ___ _   _ ___ _____ 
--  |_ _| \ | |_ _|_   _|
--   | ||  \| || |  | |  
--   | || |\  || |  | |  
--  |___|_| \_|___| |_|  

function ItemSlotEquipItemMobile:InitUI()
    self:ResetWidget()
end

function ItemSlotEquipItemMobile:InitData()
    self.ItemData = nil

    self.HandleSelect = false
    self.CurrentTouchState = GameDefine.TouchType.None
    self.DragDistance = 0
    self.DragOperationActiveMinDistance = 10.0;
    self.DragStartPosition = UE.FVector2D()
    self.DragStartPosition.X = 0
    self.DragStartPosition.Y = 0

    self.CurrentDragVisualWidget = nil
end

function ItemSlotEquipItemMobile:InitGameEvent()
    -- 注册消息监听
    self.MsgList = { 
       
    }
end

function ItemSlotEquipItemMobile:InitUIEvent()

end
--   _   _ ___   ____  _____ _____ ____  _____ ____  _   _ 
--  | | | |_ _| |  _ \| ____|  ___|  _ \| ____/ ___|| | | |
--  | | | || |  | |_) |  _| | |_  | |_) |  _| \___ \| |_| |
--  | |_| || |  |  _ <| |___|  _| |  _ <| |___ ___) |  _  |
--   \___/|___| |_| \_\_____|_|   |_| \_\_____|____/|_| |_|
function ItemSlotEquipItemMobile:ShowWidget()
    if not self.ItemData then
        return
    end
    self:SetEquipState(1)

    self.Image_Content:SetBrushFromSoftTexture(self.ItemData.ItemIcon, false)

    local BgImageObject = ItemSystemHelper.GetItemLevelColorBgByLevel(self.ItemData.ItemQuality)
    if BgImageObject then
        self.Image_Quality:SetBrushFromTexture(BgImageObject, false)
    end

    -- 物品词条
    if self.ItemData.ItemInstance then
        if self.ItemData.ItemInstance:HasItemAttribute("EnhanceAttributeId") then
            self.Image_Enhance:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.Image_Enhance:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

function ItemSlotEquipItemMobile:ResetWidget()
    self:InitData()
    self:SetEquipState(0)
    self:SetSelectState(false)
    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
end

--   _   _ ___    ____ ___  _   _ _____ ____   ___  _      
--  | | | |_ _|  / ___/ _ \| \ | |_   _|  _ \ / _ \| |     
--  | | | || |  | |  | | | |  \| | | | | |_) | | | | |     
--  | |_| || |  | |__| |_| | |\  | | | |  _ <| |_| | |___  
--   \___/|___|  \____\___/|_| \_| |_| |_| \_\\___/|_____|
function ItemSlotEquipItemMobile:SetSelectState(isSelect)
    self.Image_Select:SetVisibility(isSelect and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed) 
end

function ItemSlotEquipItemMobile:SetEquipState(ShowState)
    if ShowState == 0 then
        self.WS_ArmorState:SetActiveWidgetIndex(0)
        self.Image_Bg:SetBrushFromSoftTexture(self.DefaultBg_Texture, false)
        self.Image_Bg:SetColorAndOpacity(self.DafaultBg_Color)
        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.bIsFocusable = false
    end

    if ShowState == 1 then
        self.WS_ArmorState:SetActiveWidgetIndex(1)
        self:SetVisibility(UE.ESlateVisibility.Visible)
        self.bIsFocusable = true
    end
end

function ItemSlotEquipItemMobile:SetTouchState(InState)
    local PreState = self.CurrentTouchState
    self.CurrentTouchState = InState

    return PreState
end

--   _   _ ___   _______     _______ _   _ _____ 
--  | | | |_ _| | ____\ \   / / ____| \ | |_   _|
--  | | | || |  |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| || |  | |___  \ V / | |___| |\  | | |  
--   \___/|___| |_____|  \_/  |_____|_| \_| |_|  

function ItemSlotEquipItemMobile:OnMouseButtonDown(MyGeometry, MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    print("BagM@ItemSlotEquipItemMobile OnMouseButtonDown 1")
    -- UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Click_01")

    -- 默认Mobile平台
    self:SetTouchState(GameDefine.TouchType.Selected)
    self.DragDistance = 0

    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then return UE.UWidgetBlueprintLibrary.Handled() end

    local CurrentDragPositionInViewport = UE.UGFUnluaHelper.FPointerEvent_GetScreenSpacePosition(MouseEvent)
    self.DragStartPosition = CurrentDragPositionInViewport

    return UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent, self, MouseKey)
end

function ItemSlotEquipItemMobile:OnMouseButtonUp(MyGeometry, MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    -- 默认Mobile平台
    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Handled()
    self.CurrentTouchState = GameDefine.TouchType.None
    
    return DefaultReturnValue
end

function ItemSlotEquipItemMobile:OnMouseEnter(MyGeometry, MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotEquipItemMobile:OnMouseEnter 1")
end

function ItemSlotEquipItemMobile:OnMouseLeave(MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotNormal:OnMouseLeave 1")
end

function ItemSlotEquipItemMobile:OnDragDetected(MyGeometry, PointerEvent)
    if self.ItemData == nil then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotEquipItemMobile:OnDragDetected 1")
    self.bDraging = true

    local DragDropObject = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(self.DragDropOperationClass)    
    local DefaultDragVisualWidget = UE.UWidgetBlueprintLibrary.Create(self, self.DefaultDragVisualClass)

    self.CurrentDragVisualWidget = DefaultDragVisualWidget
    self.CurrentDragVisualWidget:SetDragVisibility(false)
    
    DragDropObject.DefaultDragVisual = DefaultDragVisualWidget

    DefaultDragVisualWidget:SetDragItemData(self.ItemData.ItemID, self.ItemData.ItemInstanceID, self.ItemData.ItemNum, GameDefine.InstanceIDType.ItemInstance)
    DefaultDragVisualWidget:SetDragSource(GameDefine.DragActionSource.BagZoom, self)
    DefaultDragVisualWidget:ShowWidget()

    return DragDropObject
end

function ItemSlotEquipItemMobile:OnDragOver(MyGeometry, MouseEvent, Operation)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    if not self.CurrentDragVisualWidget then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotEquipItemMobile:OnDragOver")
    if self.CurrentTouchState == GameDefine.TouchType.Selected then
        local CurrentDragPositionInViewport = UE.UGFUnluaHelper.FPointerEvent_GetScreenSpacePosition(MouseEvent)
        local TempX = math.abs(CurrentDragPositionInViewport.X - self.DragStartPosition.X)
        local TempY = math.abs(CurrentDragPositionInViewport.Y - self.DragStartPosition.Y)

        if (TempX > self.DragOperationActiveMinDistance) or (TempY > self.DragOperationActiveMinDistance) then
            local PreState = self:SetTouchState(GameDefine.TouchType.Drag)
            if (PreState == GameDefine.TouchType.Selected) and (self.CurrentTouchState == GameDefine.TouchType.Drag) then
                self.CurrentDragVisualWidget:SetDragVisibility(true)
            end
        end
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function ItemSlotEquipItemMobile:OnDragComplete()
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotEquipItemMobile:OnDragComplete")
    self.bDraging = false
    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
end

function ItemSlotEquipItemMobile:OnDragEnter(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDragEnter:Broadcast(MyGeometry, PointerEvent, Operation)
end

function ItemSlotEquipItemMobile:OnDrop(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    return true
end

function ItemSlotEquipItemMobile:OnDragLeave(PointerEvent, Operation)
    self.Delegate_TransportOnDragLeave:Broadcast(PointerEvent, Operation)
end

function ItemSlotEquipItemMobile:OnFocusReceived(MyGeometry,InFocusEvent)
    self.HandleSelect = true
    self:SetSelectState(true)

    if self.HandleSelect then
        MsgHelper:Send(self, GameDefine.Msg.BagMobile_ShowItemDetail, {
            ItemID=  self.ItemData.ItemID,
        })
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function ItemSlotEquipItemMobile:OnFocusLost(InFocusEvent)
    self.HandleSelect = false
    self:SetSelectState(false)
    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
end

--    ____    _    __  __ _____   _______     _______ _   _ _____ 
--   / ___|  / \  |  \/  | ____| | ____\ \   / / ____| \ | |_   _|
--  | |  _  / _ \ | |\/| |  _|   |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| |/ ___ \| |  | | |___  | |___  \ V / | |___| |\  | | |  
--   \____/_/   \_\_|  |_|_____| |_____|  \_/  |_____|_| \_| |_| 


return ItemSlotEquipItemMobile