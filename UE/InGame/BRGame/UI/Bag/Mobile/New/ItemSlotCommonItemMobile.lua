
local ItemSlotCommonItemMobile = Class("Common.Framework.UserWidget")

local IETM_SHOW_STATE ={
    Empty = 0,
    Locked = 1,
    Normal = 2,
}

function ItemSlotCommonItemMobile:OnInit()
    print("NewBagMobile@ItemSlotCommonItemMobile Init")

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

function ItemSlotCommonItemMobile:InitUI()
    self:ResetWidget()
    self:SetSelectState(false)
end

function ItemSlotCommonItemMobile:InitData()
    self.ItemData = nil
    self.IsNotRecommend = false

    self.HandleSelect = false
    self.CurrentTouchState = GameDefine.TouchType.None
    self.DragDistance = 0
    self.DragOperationActiveMinDistance = 10.0;
    self.DragStartPosition = UE.FVector2D()
    self.DragStartPosition.X = 0
    self.DragStartPosition.Y = 0

    self.CurrentDragVisualWidget = nil
end

function ItemSlotCommonItemMobile:InitGameEvent()
    -- 注册消息监听
    self.MsgList = { 
       
    }
end

function ItemSlotCommonItemMobile:InitUIEvent()

end

function ItemSlotCommonItemMobile:SetItemData(NewData)
    self.ItemData = NewData
end


--   _   _ ___   ____  _____ _____ ____  _____ ____  _   _ 
--  | | | |_ _| |  _ \| ____|  ___|  _ \| ____/ ___|| | | |
--  | | | || |  | |_) |  _| | |_  | |_) |  _| \___ \| |_| |
--  | |_| || |  |  _ <| |___|  _| |  _ <| |___ ___) |  _  |
--   \___/|___| |_| \_\_____|_|   |_| \_\_____|____/|_| |_|

function ItemSlotCommonItemMobile:ShowWidget()
    if not self.ItemData then
        return
    end

    self:RefreshItemNumArea(self.ItemData.ItemNum, self.ItemData.ItemMaxNum)
    self:RefreshItemIcon(self.ItemData.ItemIcon)
    self:RefreshItemLevelBg(self.ItemData.ItemQuality)
    self:RefreshItemRecommond(self.ItemData.ItemID)

    self:SetShowState(IETM_SHOW_STATE.Normal)
end

function ItemSlotCommonItemMobile:ResetWidget()
    -- 设置物品槽位空状态
    self:InitData()
    self:SetShowState(IETM_SHOW_STATE.Empty)

    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
end

function ItemSlotCommonItemMobile:SetLockState()
    self.ItemData = nil
    self:SetShowState(IETM_SHOW_STATE.Locked)
end


function ItemSlotCommonItemMobile:RefreshItemNumArea(ItemNum, ItemMaxNum)
     --如果最大数量为1，不显示数量文本
     local bIsShowItemNum = ItemMaxNum > 1
     if bIsShowItemNum then
         self:RefreshItemCurNum(ItemNum)
         self:RefreshItemNumBar(ItemNum, ItemMaxNum)
     end
     self.Text_Num:SetVisibility(bIsShowItemNum and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
     self.GUIHorizontalBox_Stack:SetVisibility(bIsShowItemNum and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function ItemSlotCommonItemMobile:RefreshItemCurNum(ItemNum)
    self.Text_Num:SetText(tostring(ItemNum))
end

function ItemSlotCommonItemMobile:RefreshItemNumBar(ItemNum, ItemMaxNum)
    local BarNum = self.GUIHorizontalBox_Stack:GetChildrenCount()
    for index = 1, BarNum do
        local BarWidget = self.GUIHorizontalBox_Stack:GetChildAt(index - 1)
        if index > ItemMaxNum then
            BarWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            BarWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            BarWidget:SetShowFill(index <= ItemNum)
        end
    end
end

function ItemSlotCommonItemMobile:RefreshItemIcon(ItemIconPtr)
    if not ItemIconPtr then
        return
    end
    self.Image_Content:SetBrushFromSoftTexture(ItemIconPtr, true)
end

function ItemSlotCommonItemMobile:RefreshItemLevelBg(ItemLevel)
    if ItemLevel > 0 then
        local BgImageObject = ItemSystemHelper.GetItemLevelColorBgByLevel(ItemLevel)
        if BgImageObject then
            self.Image_Level:SetBrushFromTexture(BgImageObject, false)
        end
    end 
end

function ItemSlotCommonItemMobile:RefreshItemRecommond(ItemID)
    self.IsNotRecommend = ItemSystemHelper.IsShowNotRecommendSuperscript(ItemID)
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

function ItemSlotCommonItemMobile:SetShowState(showState)
    if showState == IETM_SHOW_STATE.Locked then
        self.WS_ItemState:SetActiveWidgetIndex(0)
    end
    
    if showState == IETM_SHOW_STATE.Empty then
        self.WS_ItemState:SetActiveWidgetIndex(1)
    end

    if showState == IETM_SHOW_STATE.Normal then
        self.WS_ItemState:SetActiveWidgetIndex(2)
        self:SetVisibility(UE.ESlateVisibility.Visible)
        self.bIsFocusable = true
        print("BagM@ItemSlotCommonItemMobile SetShowState Visible")
    else
        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.bIsFocusable = false
    end
end

function ItemSlotCommonItemMobile:SetSelectState(isSelect)
    self.Image_Select:SetVisibility(isSelect and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed) 
end

function ItemSlotCommonItemMobile:SetTouchState(InState)
    local PreState = self.CurrentTouchState
    self.CurrentTouchState = InState

    return PreState
end

--   _   _ ___   _______     _______ _   _ _____ 
--  | | | |_ _| | ____\ \   / / ____| \ | |_   _|
--  | | | || |  |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| || |  | |___  \ V / | |___| |\  | | |  
--   \___/|___| |_____|  \_/  |_____|_| \_| |_|  
function ItemSlotCommonItemMobile:OnMouseButtonDown(MyGeometry, MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    print("BagM@ItemSlotCommonItemMobile OnMouseButtonDown 1")
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

function ItemSlotCommonItemMobile:OnMouseButtonUp(MyGeometry, MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    -- 默认Mobile平台
    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Handled()
    self.CurrentTouchState = GameDefine.TouchType.None
    
    return DefaultReturnValue
end

function ItemSlotCommonItemMobile:OnMouseEnter(MyGeometry, MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotCommonItemMobile:OnMouseEnter 1")
end

function ItemSlotCommonItemMobile:OnMouseLeave(MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotNormal:OnMouseLeave 1")
end

function ItemSlotCommonItemMobile:OnDragDetected(MyGeometry, PointerEvent)
    if self.ItemData == nil then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotCommonItemMobile:OnDragDetected")
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

function ItemSlotCommonItemMobile:OnDragOver(MyGeometry, MouseEvent, Operation)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    if not self.CurrentDragVisualWidget then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

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

function ItemSlotCommonItemMobile:OnDragComplete()
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotCommonItemMobile:OnDragComplete")
    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)

    self.bDraging = false
end

function ItemSlotCommonItemMobile:OnDragEnter(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDragEnter:Broadcast(MyGeometry, PointerEvent, Operation)
end

function ItemSlotCommonItemMobile:OnDrop(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    return true
end

function ItemSlotCommonItemMobile:OnDragLeave(PointerEvent, Operation)
    self.Delegate_TransportOnDragLeave:Broadcast(PointerEvent, Operation)
end

function ItemSlotCommonItemMobile:OnFocusReceived(MyGeometry,InFocusEvent)
    self.HandleSelect = true
    self:SetSelectState(true)

    if self.HandleSelect then
        MsgHelper:Send(self, GameDefine.Msg.BagMobile_ShowItemDetail, {
            ItemID =  self.ItemData.ItemID,
            ItemInstanceID = self.ItemData.ItemInstanceID,
            ItemNum = self.ItemData.ItemNum,
            CanUse = not self.IsNotRecommend,
        })
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function ItemSlotCommonItemMobile:OnFocusLost(InFocusEvent)
    self.HandleSelect = false
    self:SetSelectState(false)
    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
end


--    ____    _    __  __ _____   _______     _______ _   _ _____ 
--   / ___|  / \  |  \/  | ____| | ____\ \   / / ____| \ | |_   _|
--  | |  _  / _ \ | |\/| |  _|   |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| |/ ___ \| |  | | |___  | |___  \ V / | |___| |\  | | |  
--   \____/_/   \_\_|  |_|_____| |_____|  \_/  |_____|_| \_| |_| 


return ItemSlotCommonItemMobile