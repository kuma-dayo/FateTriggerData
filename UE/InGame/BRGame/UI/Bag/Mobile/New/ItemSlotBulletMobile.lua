local ItemSlotBulletMobile = Class("Common.Framework.UserWidget")

local BULLET_SHOW_STATE ={
    Empty = 0,
    Normal = 2,
}

function ItemSlotBulletMobile:OnInit()
    print("NewBagMobile@ItemSlotBulletAreaMobile Init")

    self:InitData()
    self:InitUI()
    self:InitGameEvent()
    self:InitUIEvent()

    UserWidget.OnInit(self)
end

--   ___ _   _ ___ _____ 
--  |_ _| \ | |_ _|_   _|
--   | ||  \| || |  | |  
--   | || |\  || |  | |  
--  |___|_| \_|___| |_|  

function ItemSlotBulletMobile:InitUI()

end

function ItemSlotBulletMobile:InitData()
    self.ItemID = 0
    self.ItemData = nil
    self.IsNotRecommend = false

    self.HandleSelect = false
    self.CurrentTouchState = GameDefine.TouchType.None
    self.DragDistance = 0
    self.DragOperationActiveMinDistance = 10.0;
    self.DragStartPosition = UE.FVector2D()
    self.DragStartPosition.X = 0
    self.DragStartPosition.Y = 0
    self.bDraging = true

    self.CurrentDragVisualWidget = nil
end

function ItemSlotBulletMobile:InitGameEvent()
    -- 注册消息监听
    self.MsgList = { 
       
    }
end

function ItemSlotBulletMobile:InitUIEvent()

end

function ItemSlotBulletMobile:SetBulletID(BulletID)
    self.ItemID = BulletID
end

function ItemSlotBulletMobile:SetBulletData(data)
    self.ItemData = data
end

--   _   _ ___   ____  _____ _____ ____  _____ ____  _   _ 
--  | | | |_ _| |  _ \| ____|  ___|  _ \| ____/ ___|| | | |
--  | | | || |  | |_) |  _| | |_  | |_) |  _| \___ \| |_| |
--  | |_| || |  |  _ <| |___|  _| |  _ <| |___ ___) |  _  |
--   \___/|___| |_| \_\_____|_|   |_| \_\_____|____/|_| |_|

function ItemSlotBulletMobile:ShowWidget()
    if not self.ItemData then
        return
    end

    self:RefreshBulletIcon(false)
    self:RefreshBulletNum(self.ItemData.ItemNum, self.ItemData.ItemMaxNum)
    self:RefreshBulletRecommend(self.ItemID)

    self:SetBulletState(BULLET_SHOW_STATE.Normal)
end

function ItemSlotBulletMobile:ResetWidget()
    if self.ItemID == 0 then
        return
    end

    self:RefreshBulletIcon(true)
    self:RefreshBulletNum(0, 0)
    self:SetBulletState(BULLET_SHOW_STATE.Empty)
    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
end

function ItemSlotBulletMobile:RefreshBulletIcon(IsEmpty)
    local CurItemIcon, IsExistIcon = UE.UItemSystemManager.GetItemDataFString(self, self.ItemID, "ItemIcon", GameDefine.NItemSubTable.Ingame, "ItemSlotNormal:SetItemInfo")
    if IsExistIcon then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurItemIcon)
        self.Image_Content:SetBrushFromSoftTexture(ImageSoftObjectPtr, true)
        self.Image_Content:SetColorAndOpacity(IsEmpty and self.EmptyBulletColor or self.NormaBulletColor)
    end
end

function ItemSlotBulletMobile:RefreshBulletNum(BulletNum, BulletMaxNum)
    self.Text_Num:SetText(tostring(BulletNum))
    self.Text_Num:SetColorAndOpacity(BulletNum == 0 and self.EmptyBulleTextColor or self.NormalBulleTextColor)
    if BulletMaxNum > 0 then
        self.ProgressBar_Bullet:SetPercent(BulletNum / BulletMaxNum)
    end
end

function ItemSlotBulletMobile:RefreshBulletRecommend(ItemID)
    self.IsNotRecommend = ItemSystemHelper.IsShowNotRecommendSuperscript(ItemID)
    print("BagM@IsShowNotRecommendSuperscript 2", self.IsNotRecommend, ItemID)
    if self.IsNotRecommend then
        self.Image_NotRecommend:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Image_NotRecommend:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end
--   _   _ ___    ____ ___  _   _ _____ ____   ___  _      
--  | | | |_ _|  / ___/ _ \| \ | |_   _|  _ \ / _ \| |     
--  | | | || |  | |  | | | |  \| | | | | |_) | | | | |     
--  | |_| || |  | |__| |_| | |\  | | | |  _ <| |_| | |___  
--   \___/|___|  \____\___/|_| \_| |_| |_| \_\\___/|_____|
function ItemSlotBulletMobile:SetSelectState(isSelect)
    self.Image_Select:SetVisibility(isSelect and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed) 
end

function ItemSlotBulletMobile:SetBulletState(ShowState)
    if ShowState == BULLET_SHOW_STATE.Empty then
        self.WS_BulletState:SetActiveWidgetIndex(0)
        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.bIsFocusable = false
    end

    if ShowState == BULLET_SHOW_STATE.Normal then
        self.WS_BulletState:SetActiveWidgetIndex(1)
        self.Image_Content:SetColorAndOpacity(self.NormalBulletColor)
        self:SetVisibility(UE.ESlateVisibility.Visible)
        self.bIsFocusable = true
    end
end

function ItemSlotBulletMobile:SetTouchState(InState)
    local PreState = self.CurrentTouchState
    self.CurrentTouchState = InState

    return PreState
end
--   _   _ ___   _______     _______ _   _ _____ 
--  | | | |_ _| | ____\ \   / / ____| \ | |_   _|
--  | | | || |  |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| || |  | |___  \ V / | |___| |\  | | |  
--   \___/|___| |_____|  \_/  |_____|_| \_| |_|  

function ItemSlotBulletMobile:OnMouseButtonDown(MyGeometry, MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    print("BagM@ItemSlotBulletMobile OnMouseButtonDown 1")
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

function ItemSlotBulletMobile:OnMouseButtonUp(MyGeometry, MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    -- 默认Mobile平台
    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Handled()
    self.CurrentTouchState = GameDefine.TouchType.None
    
    return DefaultReturnValue
end

function ItemSlotBulletMobile:OnMouseEnter(MyGeometry, MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotBulletMobile:OnMouseEnter 1")
end

function ItemSlotBulletMobile:OnMouseLeave(MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotBulletMobile:OnMouseLeave 1")
end

function ItemSlotBulletMobile:OnDragDetected(MyGeometry, PointerEvent)
    if self.ItemData == nil then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotBulletMobile:OnDragDetected 1")
    self.bDraging = true

    local DragDropObject = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(self.DragDropOperationClass)    
    local DefaultDragVisualWidget = UE.UWidgetBlueprintLibrary.Create(self, self.DefaultDragVisualClass)

    self.CurrentDragVisualWidget = DefaultDragVisualWidget
    self.CurrentDragVisualWidget:SetDragVisibility(false)
    
    DragDropObject.DefaultDragVisual = DefaultDragVisualWidget

    DefaultDragVisualWidget:SetDragItemData(self.ItemID, self.ItemData.ItemInstanceID, self.ItemData.ItemNum, GameDefine.InstanceIDType.ItemInstance)
    DefaultDragVisualWidget:SetDragSource(GameDefine.DragActionSource.BagZoom, self)
    DefaultDragVisualWidget:ShowWidget()

    return DragDropObject
end

function ItemSlotBulletMobile:OnDragOver(MyGeometry, MouseEvent, Operation)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    if not self.CurrentDragVisualWidget then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotCommonItemMobile:OnDragOver")
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

function ItemSlotBulletMobile:OnDragComplete()
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotCommonItemMobile:OnDragComplete")
    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
    self.bDraging = false
end

function ItemSlotBulletMobile:OnDragEnter(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDragEnter:Broadcast(MyGeometry, PointerEvent, Operation)
end

function ItemSlotBulletMobile:OnDrop(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    return true
end

function ItemSlotBulletMobile:OnDragLeave(PointerEvent, Operation)
    self.Delegate_TransportOnDragLeave:Broadcast(PointerEvent, Operation)
end

function ItemSlotBulletMobile:OnFocusReceived(MyGeometry,InFocusEvent)
    self.HandleSelect = true
    self:SetSelectState(true)

    if self.HandleSelect then
        MsgHelper:Send(self, GameDefine.Msg.BagMobile_ShowItemDetail, {
            ItemID =  self.ItemID,
            ItemInstanceID = self.ItemData.ItemInstanceID,
            ItemNum = self.ItemData.ItemNum,
            CanUse = not self.IsNotRecommend,
        })
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function ItemSlotBulletMobile:OnFocusLost(InFocusEvent)
    self.HandleSelect = false
    self:SetSelectState(false)
    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
end

--    ____    _    __  __ _____   _______     _______ _   _ _____ 
--   / ___|  / \  |  \/  | ____| | ____\ \   / / ____| \ | |_   _|
--  | |  _  / _ \ | |\/| |  _|   |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| |/ ___ \| |  | | |___  | |___  \ V / | |___| |\  | | |  
--   \____/_/   \_\_|  |_|_____| |_____|  \_/  |_____|_| \_| |_| 


return ItemSlotBulletMobile