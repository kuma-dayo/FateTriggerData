

local ItemSlotWeaponAttachmentMobile = Class("Common.Framework.UserWidget")
function ItemSlotWeaponAttachmentMobile:OnInit()
    print("NewBagMobile@ItemSlotWeaponAttachmentMobile Init")

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
function ItemSlotWeaponAttachmentMobile:InitUI()
    self:SetAttchmentTypeDefaultBG()
    self:SetSelectState(false)

    self:ResetWidget()
end

function ItemSlotWeaponAttachmentMobile:InitData()
    self.ItemData = nil

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

function ItemSlotWeaponAttachmentMobile:InitGameEvent()
    -- 注册消息监听
    self.MsgList = { 
       
    }
end

function ItemSlotWeaponAttachmentMobile:InitUIEvent()

end

function ItemSlotWeaponAttachmentMobile:SetAttachmentData(ItemData)
    self.ItemData = ItemData
end

function ItemSlotWeaponAttachmentMobile:IsValidAttachmentUI()
    return self.ItemData ~= nil
end

function ItemSlotWeaponAttachmentMobile:DropInBag()
    -- 锁定 则不能 卸下
    if not self.ItemData.CanDetachFlag then
        local CurrentAttachmentObject = UE.UGAWAttachmentFunctionLibrary.GetAttachmentInstance(self.ItemData.WeaponInstance, self.ItemData.EffectInstanceID)
        if CurrentAttachmentObject then
            UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId(CurrentAttachmentObject.CanNotDetachMsg, -1, UE.FGenericBlackboardContainer(), nil)
        end
        return
    end

    if self:IsValidAttachmentUI() then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        local BagComponent = UE.UBagComponent.Get(PlayerController)
        local TempInventoryIdentity = UE.FInventoryIdentity()
        TempInventoryIdentity.ItemID = self.ItemData.ItemID
        TempInventoryIdentity.ItemInstanceID = self.ItemData.ItemInstanceID
        local TempWAttachmentObject = BagComponent:GetInventoryInstance(TempInventoryIdentity)
        if TempWAttachmentObject then
            UE.UItemStatics.UseItem(PlayerController, TempInventoryIdentity, ItemAttachmentHelper.NUsefulReason.UnEquipFromWeapon)
        end
    end

end
--   _   _ ___   ____  _____ _____ ____  _____ ____  _   _ 
--  | | | |_ _| |  _ \| ____|  ___|  _ \| ____/ ___|| | | |
--  | | | || |  | |_) |  _| | |_  | |_) |  _| \___ \| |_| |
--  | |_| || |  |  _ <| |___|  _| |  _ <| |___ ___) |  _  |
--   \___/|___| |_| \_\_____|_|   |_| \_\_____|____/|_| |_|

function ItemSlotWeaponAttachmentMobile:ShowWidget()
    if not self.ItemData then
        return    
    end

    self:RefreshAttachmentIcon(self.ItemData.ItemID)
    self:RefreshAttachmentQuality(self.ItemData.ItemID)
    self:RefreshAttachmentLockState(self.ItemData.CanDetachFlag)

    self:SetAttachmentVisible(true)
end

function ItemSlotWeaponAttachmentMobile:ResetWidget()
    self:InitData()

    self:SetAttachmentVisible(false)
    self:SetSelectState(false)
    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
end

function ItemSlotWeaponAttachmentMobile:RefreshAttachmentIcon(ItemID)
    local SlotImage, RetSlotImage = UE.UItemSystemManager.GetItemDataFString(self, ItemID, "SlotImage", GameDefine.NItemSubTable.Ingame, "ItemSlotWeaponAttachmentMobile:RefreshAttachmentIcon")
    if RetSlotImage then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(SlotImage)
        self.Image_Content:SetBrushFromSoftTexture(ImageSoftObjectPtr)
    end
end

function ItemSlotWeaponAttachmentMobile:RefreshAttachmentQuality(ItemID)
    local CurrentItemLevel, IsFindItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, ItemID, "ItemLevel", GameDefine.NItemSubTable.Ingame, "ItemSlotWeaponAttachmentMobile:RefreshAttachmentQuality")
    if IsFindItemLevel then
        self:RefreshAttachmentQualityBg(CurrentItemLevel)
    end
end

function ItemSlotWeaponAttachmentMobile:RefreshAttachmentQualityBg(InAttachmentLv)
    if InAttachmentLv and InAttachmentLv > 0 then
        local BgImageObject = ItemSystemHelper.GetItemLevelColorBgByLevel(InAttachmentLv)
        if BgImageObject then
            -- 使用硬链接
            self.Image_Quality:SetBrushFromTexture(BgImageObject, false)
            return
        end
    end

    -- 无配件
    self.Image_Quality:SetBrushFromSoftTexture(self.BgEmptyImageSoftObject, false)
end

-- TODO 暂时缺少UI控件
function ItemSlotWeaponAttachmentMobile:RefreshMagnifierSpecialShow(ItemID)
    local MiscSystemIns = UE.UMiscSystem.GetMiscSystem(self)

    local MagnifierType = MiscSystemIns.MagnifierTypeMap:Find(ItemID)
    print("[Wzp]RefreshMagnifierSpecialShow >> UpdateAttachment MagnifierType=",MagnifierType," self.ItemID=", ItemID)
    -- self.Text_ScaleMutiplay:SetVisibility(MagnifierType and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed )
    if MagnifierType then
        --显示倍镜倍率文本
        -- self.Text_ScaleMutiplay:SetText(MagnifierType.Multiple)
    end
end

function ItemSlotWeaponAttachmentMobile:RefreshAttachmentLockState(CanDetachFlag)
    if CanDetachFlag then
        self.Image_Lock:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Image_Content:SetColorAndOpacity(self.BgImageBeUsedOpacity)
    else
        self.Image_Lock:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Image_Content:SetColorAndOpacity(self.BgImageEmptyOpacity)
    end
end

function ItemSlotWeaponAttachmentMobile:RefreshAttachmentTypeBG(weaponTag)
    local WeaponTagName = weaponTag.TagName;
    --使用正则将 Tag 过滤一部分
    local WeaponKey = string.match(WeaponTagName, "(.-)%.[^%.]*$")

    --根据枪Tag 去DataAsset中查找配件Container
    if self.AttachmentTypeDataAsset then
        local AttachmentCollection = self.AttachmentTypeDataAsset.WeaponAttachmentMap:FindRef(WeaponKey)
        if AttachmentCollection then
            local ImageSoftObjectPtr = AttachmentCollection.AttachmentIconMap:FindRef(self.AttachmentSlotName)
            if ImageSoftObjectPtr then
                self.Image_AttachmentType:SetBrushFromSoftTexture(ImageSoftObjectPtr,false)
                return
            end
        end
    end
    
    --没找到配件的图标则给默认图标
    self.Image_AttachmentType:SetBrushFromSoftTexture(self.AttachmentType)
end

--   _   _ ___    ____ ___  _   _ _____ ____   ___  _      
--  | | | |_ _|  / ___/ _ \| \ | |_   _|  _ \ / _ \| |     
--  | | | || |  | |  | | | |  \| | | | | |_) | | | | |     
--  | |_| || |  | |__| |_| | |\  | | | |  _ <| |_| | |___  
--   \___/|___|  \____\___/|_| \_| |_| |_| \_\\___/|_____|

function ItemSlotWeaponAttachmentMobile:SetAttchmentTypeDefaultBG()
    self.Image_AttachmentType:SetBrushFromSoftTexture(self.AttachmentType)
end

function ItemSlotWeaponAttachmentMobile:SetSelectState(IsSelect)
    if IsSelect then
        self.Image_Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.Image_Select:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function ItemSlotWeaponAttachmentMobile:SetAttachmentVisible(IsVisible)
    if IsVisible then
        self.Overlay_DefaultBg:SetVisibility(UE.ESlateVisibility.Collapsed)

        self.Image_Quality:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Image_Content:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        -- 响应触摸
        self:SetVisibility(UE.ESlateVisibility.Visible)
        self.bIsFocusable = true
    else
        self.Image_AttachmentType:SetColorAndOpacity(self.BgImageEmptyOpacity)
        self.Overlay_DefaultBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        self.Image_Quality:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Image_Content:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Image_Content:SetColorAndOpacity(self.BgImageEmptyOpacity)
        self:RefreshAttachmentLockState(true)

        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.bIsFocusable = false
    end
end

function ItemSlotWeaponAttachmentMobile:SetTouchState(InState)
    local PreState = self.CurrentTouchState
    self.CurrentTouchState = InState

    return PreState
end

--   _   _ ___   _______     _______ _   _ _____ 
--  | | | |_ _| | ____\ \   / / ____| \ | |_   _|
--  | | | || |  |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| || |  | |___  \ V / | |___| |\  | | |  
--   \___/|___| |_____|  \_/  |_____|_| \_| |_|  
function ItemSlotWeaponAttachmentMobile:OnMouseButtonDown(MyGeometry, MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    print("BagM@ItemSlotWeaponAttachmentMobile OnMouseButtonDown 1")
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

function ItemSlotWeaponAttachmentMobile:OnMouseButtonUp(MyGeometry, MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    -- 默认Mobile平台
    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Handled()
    self.CurrentTouchState = GameDefine.TouchType.None
    
    return DefaultReturnValue
end

function ItemSlotWeaponAttachmentMobile:OnMouseEnter(MyGeometry, MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotWeaponAttachmentMobile:OnMouseEnter 1")
end

function ItemSlotWeaponAttachmentMobile:OnMouseLeave(MouseEvent)
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotWeaponAttachmentMobile:OnMouseLeave 1")
end

function ItemSlotWeaponAttachmentMobile:OnDragDetected(MyGeometry, PointerEvent)
    if self.ItemData == nil then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotWeaponAttachmentMobile:OnDragDetected 1")
    self.bDraging = true

    local DragDropObject = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(self.DragDropOperationClass)    
    local DefaultDragVisualWidget = UE.UWidgetBlueprintLibrary.Create(self, self.DefaultDragVisualClass)

    self.CurrentDragVisualWidget = DefaultDragVisualWidget
    self.CurrentDragVisualWidget:SetDragVisibility(false)
    
    DragDropObject.DefaultDragVisual = DefaultDragVisualWidget

    DefaultDragVisualWidget:SetDragItemData(self.ItemData.ItemID, self.ItemData.ItemInstanceID, 1, GameDefine.InstanceIDType.ItemInstance)
    DefaultDragVisualWidget:SetDragSource(GameDefine.DragActionSource.BagZoom, self)
    DefaultDragVisualWidget:ShowWidget()

    return DragDropObject
end

function ItemSlotWeaponAttachmentMobile:OnDragOver(MyGeometry, MouseEvent, Operation)
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

function ItemSlotWeaponAttachmentMobile:OnDragComplete()
    if (self.ItemData == nil) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    print("BagM@ItemSlotCommonItemMobile:OnDragComplete")
    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
    self.bDraging = false
end

function ItemSlotWeaponAttachmentMobile:OnDragEnter(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDragEnter:Broadcast(MyGeometry, PointerEvent, Operation)
end


function ItemSlotWeaponAttachmentMobile:OnDragLeave(PointerEvent, Operation)
    self.Delegate_TransportOnDragLeave:Broadcast(PointerEvent, Operation)
end


function ItemSlotWeaponAttachmentMobile:OnDrop(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    return true
end

function ItemSlotWeaponAttachmentMobile:OnFocusReceived(MyGeometry, InFocusEvent)
    print("BagM@ItemSlotWeaponAttachmentMobile:OnFocusReceived:",self.SlotIndex)
    self.HandleSelect = true
    self:SetSelectState(true)

    if self.HandleSelect then
        MsgHelper:Send(self, GameDefine.Msg.BagMobile_ShowItemDetail, {
            ItemID = self.ItemData.ItemID,
            EnhanceId = self.ItemData.EffectInstanceID,
            InWeaponInstance = self.ItemData.GAWeaponInstance,
        })
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function ItemSlotWeaponAttachmentMobile:OnFocusLost( InFocusEvent)
    print("BagM@ItemSlotWeaponAttachmentMobile:OnFocusLost:",self.SlotIndex)
    self.HandleSelect = false
    self:SetSelectState(false)

    MsgHelper:Send(self, GameDefine.Msg.BagMobile_HideItemDetail)
end

--    ____    _    __  __ _____   _______     _______ _   _ _____ 
--   / ___|  / \  |  \/  | ____| | ____\ \   / / ____| \ | |_   _|
--  | |  _  / _ \ | |\/| |  _|   |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| |/ ___ \| |  | | |___  | |___  \ V / | |___| |\  | | |  
--   \____/_/   \_\_|  |_|_____| |_____|  \_/  |_____|_| \_| |_| 


return ItemSlotWeaponAttachmentMobile