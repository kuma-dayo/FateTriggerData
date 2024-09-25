require "UnLua"
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")
local ItemSlotArmor = Class("Common.Framework.UserWidget")

function ItemSlotArmor:OnInit()
    self:ResetItemInfo()
    self:ShowDontHasArmor()

    self.MsgList = {
		{ MsgName = GameDefine.Msg.WEAPON_ArmorSlotDragOnDrop,      Func = self.OnArmorSlotDragOnDrop   },
        { MsgName = GameDefine.MsgCpp.BAG_WhenShowHideBag,          Func = self.CloseBagPanel,          bCppMsg = true }
    }

    UserWidget.OnInit(self)
end

function ItemSlotArmor:OnDestroy()
    self.ItemID = nil
    self.ItemInstanceID = nil
    self.ShowRedLimit = nil
    self.InWidgetRange = nil
    self.IsHoldLeftMouseButton = nil

	UserWidget.OnDestroy(self)
end

function ItemSlotArmor:ResetItemInfo()
    self.ItemID = 0
    self.ItemInstanceID = 0
    self.ShowRedLimit = 0.25
    self.InWidgetRange = false
    self.IsHoldLeftMouseButton = false
end


function ItemSlotArmor:GetInventoryIdentity()
    return self.ItemID, self.ItemInstanceID
end


function ItemSlotArmor:InitSlotTypeInfo(InSlotTypeName)
    print("ItemSlotArmor:InitSlotTypeInfo-->InSlotTypeName:", InSlotTypeName, "Class:", self)
    self.ItemSlotType = tostring(InSlotTypeName)
    self:SetEmptyArmorImage()
end

function ItemSlotArmor:SetSlotInfo(ItemSlotData)
    print("ItemSlotArmor:SetSlotInfo-->ItemSlotType:", ItemSlotData.ItemType)
    if ItemSlotData.InventoryIdentity.ItemID == 0 then
        print("ItemSlotArmor::SetSlotInfo >> ItemSlotData.InventoryIdentity.ItemID == 0")
        self.ItemSlotType = tostring(ItemSlotData.ItemType)
        self:Reset()
    else
        self.ItemID = ItemSlotData.InventoryIdentity.ItemID
        self.ItemInstanceID = ItemSlotData.InventoryIdentity.ItemInstanceID
        self.ItemSlotType = tostring(ItemSlotData.ItemType)
        self:SetSlotActive(true)
        self:ShowHasArmor()
        self:SetLvImageValue()
    end
end


function ItemSlotArmor:UpdateArmorInfoFromFeatureSet(BagElem, ShieldValue, MaxShieldValue)
    if not BagElem then return end
    if self.ItemID and (self.ItemID ~= BagElem.InventoryIdentity.ItemID) then return end
    if self.ItemInstanceID and (self.ItemInstanceID ~= BagElem.InventoryIdentity.ItemInstanceID) then return end
    self:SetCurrentShieldTextValue(ShieldValue)
    self:SetMaxShieldTextValue(MaxShieldValue)
    self:UpdateCurrentArmorShieldColor(ShieldValue, MaxShieldValue)
end

function ItemSlotArmor:SetSlotActive(NewState)
    -- 装备激活无效果
end

function ItemSlotArmor:IsSlotInfoValid()
    if self.ItemID ~= 0 and self.ItemInstanceID ~= 0 then
        return true
    end
    return false
end

function ItemSlotArmor:OnMouseButtonDown(MyGeometry, MouseEvent)
    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Handled()
    
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)

    if not PlayerController then
        return DefaultReturnValue
    end

    if not self:IsSlotInfoValid() then
        --return DefaultReturnValue
    end

    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then return DefaultReturnValue end
    if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton and self:IsSlotInfoValid() then
        self.IsHoldLeftMouseButton = true
        return UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent,self, MouseKey)
    elseif MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton then
        if self:IsSlotInfoValid() then
            local tPawn = PlayerController:GetPawn()
            local tEquipmentComponent = UE.UEquipmentStatics.GetEquipmentComponent(tPawn)

            local TempInventoryIdentity = UE.FInventoryIdentity()
            TempInventoryIdentity.ItemID = self.ItemID
            TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID

            local TempDiscardTag = UE.FGameplayTag()
            UE.UItemStatics.DiscardItem(PlayerController, TempInventoryIdentity, 1, TempDiscardTag)
            UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Item_Discard")
        end
    elseif MouseKey.KeyName == GameDefine.NInputKey.MiddleMouseButton then
        local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
        if BattleChatComp then
            local PlayerName = ""
            local PS = PlayerController.PlayerState
            if PS then
                PlayerName = PS:GetPlayerName()
            end
            if self:IsSlotInfoValid() then
                AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithItemId(self, self.ItemID)
                print("ItemSlotArmor:OnMouseButtonDown SendMsg Own Armor !")
            else
                AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemTypeId(self, self.ItemID)
                print("ItemSlotArmor:OnMouseButtonDown SendMsg Need Armor !")
            end
        end
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

-- 鼠标按键抬起
function ItemSlotArmor:OnMouseButtonUp(MyGeometry, MouseEvent)
    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton and self.IsHoldLeftMouseButton then
        self.IsHoldLeftMouseButton = false
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

function ItemSlotArmor:OnClicked_Weapon()
    self.OnClickedItem:Broadcast(self)
end

function ItemSlotArmor:Reset()
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
    self:ResetItemInfo()
    self:SetCurrentShieldTextValue(0)
    self:SetMaxShieldTextValue(0)
    self:SetCurrentShieldTextVisibility(false)
    self:SetMaxShieldTextVisibility(false)
    
    self.GUIText_Delimiter:SetVisibility(UE.ESlateVisibility.Hidden)
    -- 处理背景颜色
    self:SetArmorLevelColor(0)
    self:ShowDontHasArmor()
end

function ItemSlotArmor:IsSameContent(InInventoryIdentity)
    return (self.ItemID == InInventoryIdentity.ItemID) and (self.ItemInstanceID == InInventoryIdentity.ItemInstanceID)
end

-- display
function ItemSlotArmor:ShowHasArmor()
    self.Image_Content:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:SetCurrentShieldTextVisibility(true)
    self:SetMaxShieldTextVisibility(true)
    self.GUIText_Delimiter:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function ItemSlotArmor:ShowDontHasArmor()
    self.GUIText_Delimiter:SetVisibility(UE.ESlateVisibility.Hidden)
    self:SetCurrentShieldTextVisibility(false)
    self:SetMaxShieldTextVisibility(false)
    self:UpdateBackGroundImage(0)
    self:SetEmptyArmorImage()
end

-- 
function ItemSlotArmor:SetEmptyArmorImage()
    print("ItemSlotArmor:SetEmptyArmorImage-->self.ItemSlotType:", self.ItemSlotType, "class:", self)
    if self.ItemSlotType == "ArmorBody" then
        --local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(self.EmptyBodyArmorPicPath)
        print("ItemSlotArmor:SetEmptyArmorImage-->EmptyHeadArmorPic:", self.EmptyBodyArmorPic)
        if  self.EmptyBodyArmorPic ~= nil then
            self.Image_Content:SetBrushFromSoftTexture(self.EmptyBodyArmorPic, true)
            self.Image_Content:SetColorAndOpacity(self.EmptyArmorPicColor)
        else
            print("ItemSlotArmor:SetEmptyArmorImage-->ImageSoftObjectPtr is nil")
        end
    end
    if self.ItemSlotType == "ArmorHead" then
        --local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(self.EmptyHeadArmorPicPath)
        print("ItemSlotArmor:SetEmptyArmorImage-->EmptyHeadArmorPic:", self.EmptyHeadArmorPic)
        if  self.EmptyHeadArmorPic ~= nil then
            self.Image_Content:SetBrushFromSoftTexture(self.EmptyHeadArmorPic, true)
            self.Image_Content:SetColorAndOpacity(self.EmptyArmorPicColor)
        else
            print("ItemSlotArmor:SetEmptyArmorImage-->ImageSoftObjectPtr is nil")
        end
    end
    
end

-- 设置 level image value
function ItemSlotArmor:SetLvImageValue()
    local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(self)
    local SubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(self.ItemID, "Ingame")
    local StrItemID = tostring(self.ItemID)
    local CurrentItemLevel, RetItemName = SubTable:BP_FindDataUInt8(StrItemID,"ItemLevel")
    if RetItemName then
        self:SetArmorLevelColor(CurrentItemLevel)
    end
    --self:SetArmorImageValueByLV(self.ItemID, CurrentItemLevel)

    local SlotImage, RetSlotImage = SubTable:BP_FindDataFString(StrItemID,"SlotImage")
    if RetSlotImage then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(SlotImage)
        self.Image_Content:SetBrushFromSoftTexture(ImageSoftObjectPtr, true)
        self.Image_Content:SetColorAndOpacity(self.DefaultArmorPicColor)
    end

    -- 这里假设这个组件只给主控端使用
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    local BagComponent = UE.UBagComponent.Get(PlayerController)

    local CurrentInventoryIdentity = UE.FInventoryIdentity()
    CurrentInventoryIdentity.ItemID = self.ItemID
    CurrentInventoryIdentity.ItemInstanceID = self.ItemInstanceID

    -- 设置当前护甲值
    local ArmorShieldValue, IsFindCurrentArmorShield = BagComponent:GetItemAttribute(CurrentInventoryIdentity, ItemSystemHelper.NItemAttrName.ArmorShield)
    local TempCurrentArmorShield = ArmorShieldValue.FloatValue
    if IsFindCurrentArmorShield then
        self:SetCurrentShieldTextValue(TempCurrentArmorShield)
    else
        self:SetCurrentShieldTextValue(-1)
    end

    -- 设置最大护甲值
    local MaxArmorShield, IsFindMaxArmorShield = BagComponent:GetItemAttribute(CurrentInventoryIdentity, ItemSystemHelper.NItemAttrName.MaxArmorShield)
    local TempMaxArmorShield = MaxArmorShield.FloatValue
    if IsFindMaxArmorShield then
        self:SetMaxShieldTextValue(TempMaxArmorShield)
    else
        self:SetMaxShieldTextValue(-1)
    end

    if IsFindCurrentArmorShield and IsFindMaxArmorShield then
        self:UpdateCurrentArmorShieldColor(TempCurrentArmorShield, TempMaxArmorShield)
    end
    
end

function ItemSlotArmor:UpdateCurrentArmorShieldColor(InCurrentArmorShield,InCurrentMaxArmorShield)
    if InCurrentArmorShield and InCurrentMaxArmorShield then
        local Percentage = (InCurrentArmorShield+.0) / (InCurrentMaxArmorShield+.0)
        if Percentage > self.ShowRedLimit then
            self.GUIText_CurrentShield:SetColorAndOpacity(self.ArmorValueBackgroundColorDefault)
        else
            self.GUIText_CurrentShield:SetColorAndOpacity(self.ArmorValueBackgroundColorDanger)
        end
    else
        self.GUIText_CurrentShield:SetColorAndOpacity(self.ArmorValueBackgroundColorDefault)
    end
end

function ItemSlotArmor:OnMouseEnter(MyGeometry, MouseEvent)
    if BridgeHelper.IsMobilePlatform() then
        return
    end

    local TempInteractionKeyName = "Bag.Default.2Action"

    if self.ItemID ~= 0 then
        MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo, {
            HoverWidget = self,
            ParentWidget = nil,
            IsShowAtLeftSide = true ,
            ItemID=self.ItemID,
            ItemInstanceID = self.ItemInstanceID,
            ItemNum = 1,
            IsShowDiscardNum = true,
            InteractionKeyName = TempInteractionKeyName,
            ShowSourceType = ItemSystemHelper.ItemDetialInfoShowMsgSourceType.BagSystem
        })

        self.Image_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    self.InWidgetRange = true
end

function ItemSlotArmor:OnMouseLeave(MouseEvent)
    if BridgeHelper.IsMobilePlatform() then
        return
    end

    self.Image_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
    self.InWidgetRange = false
    self.IsHoldLeftMouseButton = false
end

-- 动态加载不同的颜色材质材质
function ItemSlotArmor:UpdateBackGroundImage(CurItemLevel)
    local LvBgColorTexture = BattleUIHelper.GetMiscSystemValue(self,"BagLvBgColorTexture", CurItemLevel)
    if LvBgColorTexture then
        local CurrentMaterial = self.Image_Background:GetDynamicMaterial()
        if CurrentMaterial then
            CurrentMaterial:SetTextureParameterValue("FillTexture", LvBgColorTexture)
        end                
        self.Image_Background:SetVisibility(UE.ESlateVisibility.Visible)
    else
       
        self.Image_Background:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

-- 设置：当前护盾 Text 值
function ItemSlotArmor:SetCurrentShieldTextValue(InNumber)
    if self.GUIText_CurrentShield then
        if InNumber >= 0 then
            local TempCurrentShieldValue = math.tointeger(math.ceil(InNumber))
            self.GUIText_CurrentShield:SetText(tostring(TempCurrentShieldValue))
        else
            self.GUIText_CurrentShield:SetText("Error")
            print("[Error][ItemSlotArmor:SetCurrentShieldTextValue] InNumber = ", tostring(InNumber))
        end
    else
        print("[Error][ItemSlotArmor:SetCurrentShieldTextValue] self.GUIText_CurrentShield is nil. ")
    end
end

-- 显示/隐藏：当前护盾 Text 控件
function ItemSlotArmor:SetCurrentShieldTextVisibility(InState)
    if self.GUIText_CurrentShield then
        if InState then
            self.GUIText_CurrentShield:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.GUIText_CurrentShield:SetVisibility(UE.ESlateVisibility.Hidden)
        end
    end
end

-- 设置：最大护盾 Text 值
function ItemSlotArmor:SetMaxShieldTextValue(InNumber)
    if self.GUIText_MaxShield then
        if InNumber >= 0 then
            local TempMaxShieldValue = math.tointeger(math.floor(InNumber))
            self.GUIText_MaxShield:SetText(tostring(TempMaxShieldValue))
        else
            self.GUIText_MaxShield:SetText("Error")
            print("[Error][ItemSlotArmor:SetMaxShieldTextValue] InNumber = ", tostring(InNumber))
        end
    else
        print("[Error][ItemSlotArmor:SetMaxShieldTextValue] self.GUIText_MaxShield is nil. ")
    end
end

-- 显示/隐藏：最大护盾 Text 控件
function ItemSlotArmor:SetMaxShieldTextVisibility(InState)
    if self.GUIText_MaxShield then
        if InState then
            self.GUIText_MaxShield:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.GUIText_MaxShield:SetVisibility(UE.ESlateVisibility.Hidden)
        end
    end
end

function ItemSlotArmor:SetArmorLevelColor(InLevelNumber)
    self:UpdateBackGroundImage(InLevelNumber)
end

function ItemSlotArmor:OnDragEnter(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDragEnter:Broadcast(MyGeometry, PointerEvent, Operation)
end

function ItemSlotArmor:OnDragLeave(PointerEvent, Operation)
    self.Delegate_TransportOnDragLeave:Broadcast(PointerEvent, Operation)
end

function ItemSlotArmor:OnDrop(MyGeometry, PointerEvent, Operation)

    self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    local TempItemID, TempInstanceID, TempItemNum, TempInstanceIDType = Operation.DefaultDragVisual:GetDragInfo()
    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, TempItemID, "ItemType", GameDefine.NItemSubTable.Ingame , "DropZoomUI:OnDropToPickZoom")
    print("ItemSlotArmor:OnDrop >> CurrentItemType:",CurrentItemType)
    if CurrentItemType == "ArmorHead" or CurrentItemType == "ArmorBody" then
        local SourceFlag,DragSourceWidget = Operation.DefaultDragVisual:GetDragSource()
        -- DragSourceWidget.GUIImage_Mask:SetVisibility(UE.ESlateVisibility.Hidden) --GUIImage_Mask这个控件已被删除
    end
    

    return true
end

function ItemSlotArmor:OnDragDetected(MyGeometry, PointerEvent)
    self.GUIImage_Mask:SetVisibility(UE.ESlateVisibility.Visible)
    local DefaultDragVisualWidget = UE.UWidgetBlueprintLibrary.Create(self, self.DefaultDragVisualClass)
    DefaultDragVisualWidget:SetDragInfo(self.ItemID, self.ItemInstanceID, 1, GameDefine.InstanceIDType.ItemInstance)
    DefaultDragVisualWidget:SetDragSource(GameDefine.DragActionSource.EquipZoom, self)
    local DragDropObject = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(self.DragDropOperationClass)
    DragDropObject.DefaultDragVisual = DefaultDragVisualWidget
    return DragDropObject
end

-- CallBack
function ItemSlotArmor:OnArmorSlotDragOnDrop(InMsgBody)
    print("ItemSlotArmor:OnArmorSlotDragOnDrop-->InMsgBody   ArmorItemID:", InMsgBody.ArmorItemID, "self.ItemID:", self.ItemID)
    if InMsgBody.ArmorItemID == self.ItemID then
        self.GUIImage_Mask:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

function ItemSlotArmor:CloseBagPanel(IsVisible)
    if (not IsVisible) then
        self.GUIImage_Mask:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

return ItemSlotArmor