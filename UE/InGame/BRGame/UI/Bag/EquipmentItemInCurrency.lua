require "UnLua"

local EquipmentItemInCurrency = Class("Common.Framework.UserWidget")
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

local TouchType = {
    None = 1,
    Selected = 2,
    Drag = 3
}

local bIsOpenBag = false

function EquipmentItemInCurrency:OnInit()
    print("(Wzp)EquipmentItemInCurrency:OnInit  [ObjectName]=",GetObjectName(self))
    self.ItemInstanceID = 0
    self.ItemNum = 0

    self.CurrentTouchState = TouchType.None
    self.DragDistance = 0
    self.DragOperationActiveMinDistance = 10.0;
    self.DragStartPosition = UE.FVector2D()
    self.DragStartPosition.X = 0
    self.DragStartPosition.Y = 0
    
    --初始化绑定消息
    self.InitListenList = { 
        { MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnNew_Currency, Func = self.OnNewItem , bCppMsg = true }, 
        { MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnDestroy_Currency, Func = self.OnDestroyItem, bCppMsg = true },
        { MsgName = GameDefine.Msg.InventoryItemSlotDragOnDrop,             Func = self.OnInventoryItemDragOnDrop,      bCppMsg = false }
    }

    MsgHelper:RegisterList(self, self.InitListenList)
    UserWidget.OnInit(self)
end

function EquipmentItemInCurrency:OnDestroy()
    print("(Wzp)EquipmentItemInCurrency:OnDestroy  [ObjectName]=",GetObjectName(self))
    --每次打开绑定一次物品更新消息
    if self.InitListenList then
        MsgHelper:UnregisterList(self, self.InitListenList)
    end 
    UserWidget.OnDestroy(self)
end


function EquipmentItemInCurrency:OnShow()
    print("(Wzp)EquipmentItemInCurrency:OnShow  [ObjectName]=",GetObjectName(self))
    -- 注册消息监听
    self.CustomListenList = { {
        MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnStackNum_Change_Currency,
        Func = self.OnCurrencyStackNumChange,
        bCppMsg = true
    } }

    MsgHelper:RegisterList(self, self.CustomListenList)
    self:UpdateItemInfo()
    self:UpdateCurrencyNumber()
    bIsOpenBag = true
end

function EquipmentItemInCurrency:OnClose()
    if self.CustomListenList then
        MsgHelper:UnregisterList(self, self.CustomListenList)
    end
    bIsOpenBag = false
end


--region 更新货币数量
function EquipmentItemInCurrency:UpdateCurrencyNumber()
    print("(Wzp)EquipmentItemInBag:OnCurrencyStackNumChange  [ObjectName]=",GetObjectName(self))
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local TempBagComp = UE.UBagComponent.Get(TempLocalPC)
    if TempBagComp then
        local PreItemNum = self.ItemNum
        self.ItemNum = TempBagComp:GetItemNumByItemID(self.DefaultItem)
        if self.ItemNum > PreItemNum and bIsOpenBag then self:VXE_HUD_Bag_Attach() end
        self:UpdateCurrencyNumberText(self.ItemNum)
        print("(Wzp)EquipmentItemInBag:UpdateItemInfo  [self.ItemNum]=",self.ItemNum,",[self.DefaultItem]=",self.DefaultItem)
    end
end

function EquipmentItemInCurrency:UpdateCurrencyNumberText(InNumber)
    print("(Wzp)EquipmentItemInBag:UpdateCurrencyNumberText  [InNumber]=",InNumber)
    if self.Txt_CurrencyNum then
        self.Txt_CurrencyNum:SetText(InNumber)
    end
end
--endregion


--region GMP消息回调

--GMP物品发生数量变化会收到通知
function EquipmentItemInCurrency:OnCurrencyStackNumChange(InInventoryInstance)
    print("(Wzp)EquipmentItemInBag:OnCurrencyStackNumChange  [ObjectName]=",GetObjectName(self))
    if not InInventoryInstance then
        return
    end
    self:UpdateCurrencyNumber()
end


--GMP拾取新物品会收到通知
function EquipmentItemInCurrency:OnNewItem(InInventoryInstance)
    print("(Wzp)EquipmentItemInBag:OnNewItem  [ObjectName]=",GetObjectName(self))
    if not InInventoryInstance then
        return
    end

    local TempInventoryIdentity = InInventoryInstance:GetInventoryIdentity()
    self:SetInventoryIdentity(TempInventoryIdentity)
end

--GMP物品丢弃时调用
function EquipmentItemInCurrency:OnDestroyItem(InInventoryInstance)
    print("(Wzp)EquipmentItemInBag:OnDestroyItem  [ObjectName]=",GetObjectName(self))
    self:ResetItemInfo()
    
    -- self:UpdateCurrencyNumber()
end

--endregion


--region 处理拖拽和丢弃

function EquipmentItemInCurrency:OnMouseButtonDown(MyGeometry, MouseEvent)
    --判断物品是否执行拖拽或丢弃操作
    if (self.DefaultItem == 0 or self.ItemInstanceID == 0) then
        --return UE.UWidgetBlueprintLibrary.Handled()
    end

    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Handled()

    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then
        return DefaultReturnValue
    end

    --左键按下拖拽，右键按下丢弃
    if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton then
        DefaultReturnValue = UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent, self, MouseKey)
        
    elseif MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton then
        if (self.DefaultItem ~= 0) and (self.ItemInstanceID ~= 0) then



            local TempPC = UE.UGameplayStatics.GetPlayerController(self, 0)
            if not TempPC then
                return
            end
        
            -- （Ctrl + 右键）----> 丢弃部分物品
            if TempPC:IsInputKeyDown(UE.EKeys.LeftControl) or TempPC:IsInputKeyDown(UE.EKeys.RightControl) then
                -- 如果是不可主动丢弃的，则无法打开界面
                local TempInventoryIdentity = UE.FInventoryIdentity()
                TempInventoryIdentity.ItemID = self.ItemID
                TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID
                local BagComponent = UE.UBagComponent.Get(TempPC)
                if BagComponent then
                    local CurItemObj = BagComponent:GetInventoryInstance(TempInventoryIdentity)
                    if CurItemObj then
                        local HasIsActivelyDiscard = CurItemObj:HasItemAttribute("IsActivelyDiscard")
                        if HasIsActivelyDiscard then
                            local CurIsActivelyDiscardValue = CurItemObj:GetItemAttributeFloat("IsActivelyDiscard")
                            if CurIsActivelyDiscardValue == 0 then
                                return
                            end
                        end
                    end
                end
        
        
                
                local UIManager = UE.UGUIManager.GetUIManager(self)
                --UIManager:ShowByKey("UMG_DropItem")
        
                local GenericBlackboardContainer = UE.FGenericBlackboardContainer()
                local BlackboardKeySelector = UE.FGenericBlackboardKeySelector()
                BlackboardKeySelector.SelectedKeyName = "ItemID"
                UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsInt(GenericBlackboardContainer, BlackboardKeySelector, self.DefaultItem)
                BlackboardKeySelector.SelectedKeyName = "InstanceID"
                UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsInt(GenericBlackboardContainer, BlackboardKeySelector, self.ItemInstanceID)
                BlackboardKeySelector.SelectedKeyName = "MinNum"
                UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsInt(GenericBlackboardContainer, BlackboardKeySelector, 1)
                BlackboardKeySelector.SelectedKeyName = "MaxNum"
                UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsInt(GenericBlackboardContainer, BlackboardKeySelector, self.ItemNum)
                BlackboardKeySelector.SelectedKeyName = "CurrentNum"
                local CurrenNum = math.floor(self.ItemNum/2)
                UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsInt(GenericBlackboardContainer, BlackboardKeySelector, CurrenNum)
        
                self.ReportHandle = UIManager:TryLoadDynamicWidget("UMG_DropItem",GenericBlackboardContainer,true)
        
                MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
                return
            end

            local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
            local TempInventoryIdentity = UE.FInventoryIdentity()
            TempInventoryIdentity.ItemID = self.DefaultItem
            TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID
            local TempDiscardTag = UE.FGameplayTag()
            TempDiscardTag.TagName = "InventoryItem.Reason.DiscardActively"
            local FinalDiscardNum = 1

            local InventoryQuickDiscardNum, bInventoryQuickDiscardNum = UE.UItemSystemManager.GetItemDataInt32(PlayerController, TempInventoryIdentity.ItemID, "InventoryQuickDiscardNum", GameDefine.NItemSubTable.Ingame,"EquipmentItemInCurrency:OnMouseButtonDown")
            if bInventoryQuickDiscardNum then
                FinalDiscardNum = InventoryQuickDiscardNum
            end

            UE.UItemStatics.DiscardItem(PlayerController, TempInventoryIdentity, FinalDiscardNum, TempDiscardTag)
            UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Item_Discard")
        end
    elseif GameDefine.NInputKey.MiddleMouseButton == MouseKey.KeyName then
        if self.DefaultItem ~= 0 and self.ItemNum > 0 then
            AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithItemId(self, self.DefaultItem, self.DefaultType)
            print("EquipmentItemInCurrency:OnMouseButtonDown SendMsg Own EquipmentItemInCurrency !")
        else
            AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemType(self, self.DefaultType)
            print("EquipmentItemInCurrency:OnMouseButtonDown SendMsg Need EquipmentItemInCurrency !")
        end
    end

    return DefaultReturnValue
end


function EquipmentItemInCurrency:OnDragDetected(MyGeometry, PointerEvent)
    local DragDropObject = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(self.DragDropOperationClass)
    if self.ItemNum <= 0 then
        return
    end
    local DefaultDragVisualWidget = UE.UWidgetBlueprintLibrary.Create(self, self.DefaultDragVisualClass)
    self.CurrentDragVisualWidget = DefaultDragVisualWidget
    if BridgeHelper.IsMobilePlatform() then
        self.CurrentDragVisualWidget:SetDragVisibility(false)
    end
    DragDropObject.DefaultDragVisual = DefaultDragVisualWidget

    DefaultDragVisualWidget:SetDragInfo(self.DefaultItem, self.ItemInstanceID, self.ItemNum,
        GameDefine.InstanceIDType.ItemInstance)
    DefaultDragVisualWidget:SetDragSource(GameDefine.DragActionSource.BagZoom, self)
    if self.Overlay_Active then self:VXE_HUD_Bag_Attach_Floating_In() end
    return DragDropObject
end


function EquipmentItemInCurrency:OnDragOver(MyGeometry, MouseEvent, Operation)
    if not self.CurrentDragVisualWidget then
        -- self.CurrentDragVisualWidget:SetDragVisibility(true)
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    if self.CurrentTouchState == TouchType.Selected then
        local CurrentDragPositionInViewport = UE.UGFUnluaHelper.FPointerEvent_GetScreenSpacePosition(MouseEvent)
        local TempX = math.abs(CurrentDragPositionInViewport.X - self.DragStartPosition.X)
        local TempY = math.abs(CurrentDragPositionInViewport.Y - self.DragStartPosition.Y)

        if (TempX > self.DragOperationActiveMinDistance) or (TempY > self.DragOperationActiveMinDistance) then
            local PreState = self:SetTouchState(TouchType.Drag)
            if (PreState == TouchType.Selected) and (self.CurrentTouchState == TouchType.Drag) then
                self.CurrentDragVisualWidget:SetDragVisibility(true)
            end
        end
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

--endregion 

function EquipmentItemInCurrency:UpdateItemInfo()
    print("(Wzp)EquipmentItemInBag:UpdateItemInfo  [ObjectName]=",GetObjectName(self))
    -- 要解锁
    -- 根据物品ID更新图片
    local CurItemIcon, IsExistIcon = UE.UItemSystemManager.GetItemDataFString(self, self.DefaultItem, "ItemIcon",
        GameDefine.NItemSubTable.Ingame, "EquipmentItemInCurrency:UpdateItemInfo")
    if IsExistIcon then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurItemIcon)
        self.GUIImage_CurrencyIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
    end

    -- 根据物品ID更新等级颜色
    local ItemLevel, bValidItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, self.DefaultItem, "ItemLevel",
        GameDefine.NItemSubTable.Ingame, "EquipmentItemInCurrency:UpdateItemInfo")
    if bValidItemLevel then
        local TempBgImageTexture = self.LevelBgImageMap:Find(ItemLevel)
        if TempBgImageTexture then
            self.GUIImage_Bg:SetBrushFromTexture(TempBgImageTexture, false)
        end
    end

    print("(Wzp)EquipmentItemInBag:UpdateItemInfo  [ObjectName]=",GetObjectName(self),",[self.ItemID]=",self.ItemID,",[IsExistIcon]=",IsExistIcon,",[bValidItemLevel]=",bValidItemLevel)
    -- 改成配置的id
    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, self.DefaultItem)
    if IngameDT then
        local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(self.DefaultItem))
        local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)
        self.Txt_CurrencyName:SetText(TranslatedItemName)
    end
end

function EquipmentItemInCurrency:ResetItemInfo()
    print("(Wzp)EquipmentItemInBag:ResetItemInfo  [ObjectName]=",GetObjectName(self))
    self:ResetInventoryIdentity()
end

function EquipmentItemInCurrency:ResetInventoryIdentity()
    print("(Wzp)EquipmentItemInBag:ResetInventoryIdentity  [ObjectName]=",GetObjectName(self))
    self.ItemInstanceID = 0
    self.ItemNum = 0
    self:UpdateCurrencyNumberText(self.ItemNum)
end

function EquipmentItemInCurrency:SetInventoryIdentity(InInventoryIdentity)
    print("(Wzp)EquipmentItemInBag:UpdateItemInfo  [ObjectName]=",GetObjectName(self),",[self.DefaultItem]=",self.DefaultItem,",[InInventoryIdentity.ItemID]=",InInventoryIdentity.ItemID)
    if self.DefaultItem == InInventoryIdentity.ItemID then
        print("(Wzp)EquipmentItemInBag:UpdateItemInfo  [ObjectName]=",GetObjectName(self),",[self.ItemInstanceID]=",self.ItemInstanceID,",[nInventoryIdentity.ItemInstanceID]=",InInventoryIdentity.ItemInstanceID)
        self.ItemInstanceID = InInventoryIdentity.ItemInstanceID
    end
end



function EquipmentItemInCurrency:OnMouseEnter(MyGeometry, MouseEvent)
    if BridgeHelper.IsMobilePlatform() then
        return
    end

    local TempInteractionKeyName = "Bag.Currency.Default"
    self.Img_Border:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if self.DefaultItem ~= 0 then
        --显示物品详情Tips
        MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo, {
            HoverWidget = self,
            ParentWidget = nil,
            IsShowAtLeftSide = true,
            ItemID = self.DefaultItem,
            ItemInstanceID = self.ItemInstanceID,
            ItemNum = 1,
            IsShowDiscardNum = true,
            InteractionKeyName = TempInteractionKeyName,
            ShowSourceType = ItemSystemHelper.ItemDetialInfoShowMsgSourceType.BagSystem
        })
    end
end

function EquipmentItemInCurrency:OnMouseLeave(MouseEvent)

    if BridgeHelper.IsMobilePlatform() then
        return
    end
    self.Img_Border:SetVisibility(UE.ESlateVisibility.Collapsed)
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end

function EquipmentItemInCurrency:OnDrop(MyGeometry, PointerEvent, Operation)
    print("(Wzp)EquipmentItemInBag:OnDrop  [ObjectName]=",GetObjectName(self))
    self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    return true
end

function EquipmentItemInCurrency:OnFocusReceived(MyGeometry,InFocusEvent)
    print("(Wzp)EquipmentItemInBag:OnFocusReceived  [ObjectName]=",GetObjectName(self))
    -- local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
    -- if IsInCursorMode then
    --     return
    -- end
    self.HandleSelect = true
    self.Img_Border:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function EquipmentItemInCurrency:OnFocusLost(InFocusEvent)
    print("(Wzp)EquipmentItemInBag:OnFocusLost  [ObjectName]=",GetObjectName(self))
    -- local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
    -- if IsInCursorMode then
    --     return
    -- end
    self.HandleSelect = false
    self.Img_Border:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function EquipmentItemInCurrency:OnInventoryItemDragOnDrop(InMsgBody)
    print("(Wzp)EquipmentItemInBag:OnInventoryItemDragOnDrop  [ObjectName]=",GetObjectName(self))
    if self.Overlay_Active and self.Overlay_Active:GetRenderOpacity() ~= 1 then
        self:VXE_HUD_Bag_Attach_Floating_Out()
    end
end

return EquipmentItemInCurrency
