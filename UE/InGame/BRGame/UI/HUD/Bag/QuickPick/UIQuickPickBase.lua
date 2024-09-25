--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--


local UIQuickPickBase = Class("Common.Framework.UserWidget")

local BAG_FULL = "CanObtainResult.FullBag"

function UIQuickPickBase:OnInit()
    print("(Wzp)UIQuickPickBase >> OnInit")

    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    -- 注册消息监听
    self.MsgList = { -- 监听离开物品范围通知
    {
        MsgName = "Bag.ReadyPickup.Update",
        Func = self.UpdateTracePickup,
        bCppMsg = true,
        WatchedObject = nil
    },
    {
        MsgName = "MarkSystem.Update.AutoMarkItem",
        Func = self.OnAutoMarkItem,
        bCppMsg = true,
        WatchedObject = nil
    },
    {
        MsgName = GameDefine.Msg.InventoryItemNumChangeSingle,
        Func = self.OnInventoryItemNumChangeSingle,
        bCppMsg = true
    },
    {
        MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnNew,
        Func = self.OnInventoryNew,
        bCppMsg = true
    },
    {
        MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnDestroy,
        Func = self.OnInventoryDestroy,
        bCppMsg = true
    },
    {
        MsgName = GameDefine.MsgCpp.BagUI_UseItem,
        Func = self.OnBagUI_UseItem,
        bCppMsg = true,
        WatchedObject = LocalPC
    },
    {   MsgName = GameDefine.Msg.InventoryClearBag,
        Func = self.OnInventoryClearBag,
        bCppMsg = true
    }
    }


    self:InitEmptySlotWidget()
    self:InitGamepadData()

    self.BP_DropZoom_Discard.ImgEventPanel.OnMouseButtonDownEvent:Bind(self, self.OnMouseButtonDown_ImgEventPanel)
    
    if BridgeHelper.IsMobilePlatform() then
        self.Btn_Close.OnClicked:Add(self,self.Close)
    end

    UserWidget.OnInit(self)
end


function UIQuickPickBase:InitGamepadData()
    print("(Wzp)UIQuickPickBase:InitGamepadData  [ObjectName]=",GetObjectName(self))
    self.GamepadSelectWidget = nil
end

function UIQuickPickBase:OnInventoryItemNumChangeSingle(InGMPMessage_InventoryItemChange)
    self:TryUpdateQuickPickItemsAtNextFrame(false)
end

function UIQuickPickBase:OnInventoryNew(InInventoryInstance, TagContainer)
    self:TryUpdateQuickPickItemsAtNextFrame(false)
end

function UIQuickPickBase:OnInventoryDestroy(InInventoryInstance)
    self:TryUpdateQuickPickItemsAtNextFrame(false)
end

function UIQuickPickBase:OnInventoryClearBag(InInventoryArrayStruct)
    self:TryUpdateQuickPickItemsAtNextFrame(false)
end


function UIQuickPickBase:OnCursorModeChanged(bNewCursorMode)
    print("(Wzp)UIQuickPickBase:OnCursorModeChanged  [ObjectName]=",GetObjectName(self),",[bNewCursorMode]=",bNewCursorMode)
    local bIsGamepadMode = not bNewCursorMode

    local AllSlotWidgets = self:GetAllSlotWidgets()
    
    local AllNavigationArr = UE.TArray(UE.FWidgetCustomNavigationData)

    --别问我为什么这么写，手柄设置导航接口有问题，只能用UE原生方法去做
    if bIsGamepadMode then
        local Row = 5
        for i = 1, 10 do

            local DownWidget = nil
            local UpWidget = nil
            local LeftWidget = nil
            local RigghtWidget = nil
            if i <= Row then
                DownWidget = AllSlotWidgets[i + Row]
            else
                UpWidget = AllSlotWidgets[i - Row]
            end

            if (i - 1) > 0 then
                LeftWidget = AllSlotWidgets[i - 1]
            end

            if (i + 1) <= 10 then
                RigghtWidget = AllSlotWidgets[i + 1]
            end

            local CurrentWidget = AllSlotWidgets[i]

            if UpWidget then
                CurrentWidget:SetNavigationRule(UE.EUINavigation.Up,UE.EUINavigationRule.Explicit,GetObjectName(UpWidget))
            end

            if DownWidget then
                CurrentWidget:SetNavigationRule(UE.EUINavigation.Down,UE.EUINavigationRule.Explicit,GetObjectName(DownWidget))
            end

            if LeftWidget then
                CurrentWidget:SetNavigationRule(UE.EUINavigation.Left,UE.EUINavigationRule.Explicit,GetObjectName(LeftWidget))
            end

            if RigghtWidget then
                CurrentWidget:SetNavigationRule(UE.EUINavigation.Right,UE.EUINavigationRule.Explicit,GetObjectName(RigghtWidget))
            end

            -- local CurrentWidgetNavgation = UE.UGamepadUMGFunctionLibrary.SetSingleWidgetNavgationData(CurrentWidget,
            --     UpWidget, DownWidget, LeftWidget, RigghtWidget)
            -- AllNavigationArr:Add(CurrentWidgetNavgation)
            CurrentWidget.bIsFocusable = bIsGamepadMode
        end
        -- UE.UGamepadUMGFunctionLibrary.InitAllCustomNaviagtionDataWithWidget(AllNavigationArr)
        AllSlotWidgets[1]:SetFocus()
    end


    

    -- for _, SlotWidget in pairs(AllSlotWidgets) do
    --     SlotWidget.bIsFocusable = bIsGamepadMode
    -- end
end


function UIQuickPickBase:SetGamepadSelectWidget(Widget)
    print("(Wzp)UIQuickPickBase >> SetGamepadSelectWidget [ObjectName]=",GetObjectName(self))
    self.GamepadSelectWidget = Widget
end

function UIQuickPickBase:GetGamepadSelectWidget()
    return self.GamepadSelectWidget
end

function UIQuickPickBase:OnGamepadReplaceOrPickItem()
    print("(Wzp)UIQuickPickBase:OnGamepadReplaceOrPickItem")
    local GamepadSelectWidget = self:GetGamepadSelectWidget()
    if GamepadSelectWidget then
        self.GamepadSelectWidget:ReplaceOrPickItem()
    end
end

function UIQuickPickBase:OnGamepadDiscardItem()
    print("(Wzp)UIQuickPickBase:OnGamepadDiscardItem")
    local GamepadSelectWidget = self:GetGamepadSelectWidget()
    if GamepadSelectWidget then
        local ItemID,ItemInstanceID,ItemMaxNum,ItemNum = GamepadSelectWidget:GetItemData()
        print("(Wzp)UIQuickPickBase:OnGamepadDiscardItem [GamepadSelectWidget]=",GamepadSelectWidget,",[ItemID]=",ItemID,",[ItemInstanceID]=",ItemInstanceID,",[ItemMaxNum]=",ItemMaxNum,",[ItemNum]=",ItemNum)
        self:DiscardItem(ItemID,ItemInstanceID,ItemNum)
    end
end

function UIQuickPickBase:OnAutoMarkItem(TmpPickHighItem)
    print("(Wzp)UIQuickPickBase >> OnAutoMarkItem")

    if not self.QuickPickObj then
        return
    end

    if not CommonUtil.IsValid(self.QuickPickObj) then
        self.QuickPickObj = nil
        self.ItemInfo = nil
        return
    end

    if not self.ItemInfo then
        return
    end
    local RemovedPickArr = TmpPickHighItem.ArrayPickUpObj
    local RemovedPickListNum = RemovedPickArr:Num()
    for i = 1, RemovedPickListNum do
        local RemovePickObj = RemovedPickArr:Get(i)
        if RemovePickObj.ItemInfo == self.ItemInfo then
            self:Close()
        end
    end
end



function UIQuickPickBase:OnDestroy()
    print("(Wzp)UIQuickPickBase >> OnDestroy")

    UserWidget.OnDestroy(self)
end


--离开拾取物品的范围通知
function UIQuickPickBase:OnLeaveItemRange()
    print("(Wzp)UIQuickPickBase >> OnLeaveItemRange")
    --关闭面板：设置可见性
    self:Close()
end


function UIQuickPickBase:OnShow(Param,Blackboard) 
    print("(Wzp)UIQuickPickBase:OnShow  [ObjectName]=",GetObjectName(self))

    self:SetFocus()
    self:TryChangeInputMode(false)
    local PC = UE.UGameplayStatics.GetPlayerController(self,0)
    PC.bShowMouseCursor = true

    local QuickPlayerSelector = UE.FGenericBlackboardKeySelector()
    QuickPlayerSelector.SelectedKeyName ="QuickPickObj"
    local QuickPickObj ,bQuickPickObj =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsObject(Blackboard,QuickPlayerSelector)
    if bQuickPickObj then
        self.QuickPickObj = QuickPickObj
        if not self.QuickPickObj then return end
        self.ItemInfo = QuickPickObj.ItemInfo
       
        self:TryUpdateQuickPickItemsAtNextFrame(true)
    end
end

function UIQuickPickBase:Close()
    local PC = UE.UGameplayStatics.GetPlayerController(self,0)
    PC.bShowMouseCursor = false
    self:TryChangeInputMode(true)

    local UIManager = UE.UGUIManager.GetUIManager(self)
    if UIManager then
        
       UIManager:TryCloseDynamicWidget("UMG_QuickPick")
    end
end


function UIQuickPickBase:OnKeyDown(MyGeometry,InKeyEvent)  
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey == self.PC_QuitKey or PressKey == self.Gamepad_QuitKey then
        self:Close()
    elseif PressKey == self.Gamepad_ReplaceOrPickKey then
        self:OnGamepadReplaceOrPickItem()
    elseif PressKey == self.Gamepad_DiscardKey then  
        self:OnGamepadDiscardItem()
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function UIQuickPickBase:UpdateQuickPickItems()
    local PC = UE.UGameplayStatics.GetPlayerController(self,0)
    local BagComponent = UE.UBagComponent.Get(PC)
    if not BagComponent then return end
    local SortedInventoryInstanceArray = BagComponent:GetSortedInventoryElements()
    local InventoryInstanceNum = SortedInventoryInstanceArray:Length()

    local RealIndex = 0
    for index = 1, InventoryInstanceNum, 1 do
        local TempInventoryInstance = SortedInventoryInstanceArray:Get(index)
        if not TempInventoryInstance then
            goto continue
        end

        local CurrentInventoryInstanceNum = TempInventoryInstance:GetStackNum()
        if CurrentInventoryInstanceNum <= 0 then
            goto continue
        end

        if TempInventoryInstance:GetIsHasRemoveFlag() then
            goto continue
        end

        local CurrentItemType, RetItemType = UE.UItemSystemManager.GetItemDataFName(BagComponent, TempInventoryInstance:GetInventoryIdentity().ItemID, "ItemType", GameDefine.NItemSubTable.Ingame, "UIQuickPickBase:UpdateQuickPickItems")
        if not RetItemType then
            print("Error: UIQuickPickBase:UpdateQuickPickItems ItemType can't find. ItemId = ", tostring(TempInventoryInstance:GetInventoryIdentity().ItemID))
            goto continue
        end

        local IsSupportItemType = self.SupportDisplayItemTypeSet:Contains(CurrentItemType)
        if IsSupportItemType then
            local TempRuntimeSlotNum = TempInventoryInstance:GetRuntimeSlotNum()
            if TempRuntimeSlotNum > 0 then
                RealIndex = RealIndex + 1
                local TargetWidget = self:GetEmptySlotWidgetByIndex(RealIndex)
                if TargetWidget then
                    TargetWidget:SetItemInfo(TempInventoryInstance)
                    TargetWidget:OnInitData(self)
                end
            end
        end

        ::continue::
    end
    local LoopCount = 0
    if self.EmptySlotWidgetArray then
        LoopCount = #self.EmptySlotWidgetArray
    end

    for i = RealIndex + 1, LoopCount, 1 do
        local TargetWidget = self:GetEmptySlotWidgetByIndex(i)
        if TargetWidget then
            TargetWidget:ResetItemInfo()
            TargetWidget:OnInitData(self)
        end
    end

    self:UpdateLockSlotState()
end


function UIQuickPickBase:UpdateLockSlotState()
    local TempPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not TempPC then
        return
    end

    local TempBagComp = UE.UBagComponent.Get(TempPC)
    if not TempBagComp then
        return
    end

    local TempMaxSlotNum = TempBagComp:GetMaxSlotNum()

    local LoopCount = 0
    if self.EmptySlotWidgetArray then
        LoopCount = #self.EmptySlotWidgetArray
    end

    for i = 1, LoopCount, 1 do
        local TempEmptySlotWidget = self:GetEmptySlotWidgetByIndex(i)
        if TempEmptySlotWidget then
            if i <= TempMaxSlotNum then
                -- 设置为 非锁定
                TempEmptySlotWidget:SetLockState(false)
            else
                -- 设置为 锁定
                TempEmptySlotWidget:SetLockState(true)
            end
        end
    end
end

function UIQuickPickBase:GetEmptySlotWidgetByIndex(InIndex)
    if self.EmptySlotWidgetArray then
        return self.EmptySlotWidgetArray[InIndex]
    end

    return nil
end



function UIQuickPickBase:InitEmptySlotWidget()
    self.EmptySlotWidgetArray = {
        self.WBP_QuickPickItem_1,
        self.WBP_QuickPickItem_2,
        self.WBP_QuickPickItem_3,
        self.WBP_QuickPickItem_4,
        self.WBP_QuickPickItem_5,
        self.WBP_QuickPickItem_6,
        self.WBP_QuickPickItem_7,
        self.WBP_QuickPickItem_8,
        self.WBP_QuickPickItem_9,
        self.WBP_QuickPickItem_10,
    }
end


function UIQuickPickBase:GetAllSlotWidgets()
    if self.EmptySlotWidgetArray then
        return self.EmptySlotWidgetArray
    else
        return {
            self.WBP_QuickPickItem_1,
            self.WBP_QuickPickItem_2,
            self.WBP_QuickPickItem_3,
            self.WBP_QuickPickItem_4,
            self.WBP_QuickPickItem_5,
            self.WBP_QuickPickItem_6,
            self.WBP_QuickPickItem_7,
            self.WBP_QuickPickItem_8,
            self.WBP_QuickPickItem_9,
            self.WBP_QuickPickItem_10,
        }
    end

    return nil
end


function UIQuickPickBase:DiscardItem(ItemID,ItemInstanceID,ItemNum)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    local TempInventoryIdentity = UE.FInventoryIdentity()
    TempInventoryIdentity.ItemID = ItemID
    TempInventoryIdentity.ItemInstanceID = ItemInstanceID

    local TempDiscardTag = UE.FGameplayTag()
    UE.UItemStatics.DiscardItem(PlayerController, TempInventoryIdentity, ItemNum, TempDiscardTag)
    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Item_Discard")
end




function UIQuickPickBase:PickItem()

    if not self.QuickPickObj then
        return
    end

    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPawn(LocalPC)

    local TempGameplayTagDragDrop = UE.FGameplayTag()
    TempGameplayTagDragDrop.TagName = "PickSystem.PickMode.Drag"
    local TempGameplayTagDropEndAtZoom = UE.FGameplayTag()
    TempGameplayTagDropEndAtZoom.TagName = "PickSystem.PickMode.DropEndAtZoom"
    local TempTagContainer = UE.FGameplayTagContainer()
    TempTagContainer.GameplayTags:Add(TempGameplayTagDragDrop)
    TempTagContainer.GameplayTags:Add(TempGameplayTagDropEndAtZoom)



    UE.UPickupStatics.TryPickupItem(LocalPCPawn, self.QuickPickObj,0, UE.EPickReason.PR_Player, TempTagContainer)
    self.QuickPickObj = nil
    self:Close()
end


function UIQuickPickBase:ReplaceItem(ItemID,ItemInstanceID,ItemNum)
    if not self.QuickPickObj then
        return
    end

    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

    local TempDiscardAndTryPickInfo = UE.FDiscardInventoryAndTryPickData()

    local DiscardInventoryIdentity = UE.FInventoryIdentity()
    DiscardInventoryIdentity.ItemID = ItemID
    DiscardInventoryIdentity.ItemInstanceID = ItemInstanceID

    TempDiscardAndTryPickInfo.DiscardInventoryIdentity = DiscardInventoryIdentity

    TempDiscardAndTryPickInfo.PickID = self.QuickPickObj.PickID
    -- 0 就是捡所有
    TempDiscardAndTryPickInfo.PickNum = 0

    UE.US1InventoryStatics.DiscardInventoryAndTryPick(LocalPC, TempDiscardAndTryPickInfo);

    -- self:DiscardItem(ItemID,ItemInstanceID,ItemNum)
    -- self:PickItem()

    self:Close()
end


function UIQuickPickBase:OnMouseButtonDown_ImgEventPanel(InMyGeometry, InMouseEvent)
    self:Close()
    return UE.UWidgetBlueprintLibrary.Handled();
end

function UIQuickPickBase:OnMouseButtonDown(InMyGeometry, InMouseEvent)
    return UE.UWidgetBlueprintLibrary.Handled();
end

function UIQuickPickBase:OnMouseButtonUp(InMyGeometry, InMouseEvent)
    return UE.UWidgetBlueprintLibrary.Handled();
end


return UIQuickPickBase