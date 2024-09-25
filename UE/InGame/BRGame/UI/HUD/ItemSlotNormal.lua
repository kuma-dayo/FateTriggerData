require "UnLua"
require ("InGame.BRGame.ItemSystem.ItemSystemHelper")
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")


local ItemSlotNormal = Class("Common.Framework.UserWidget")

local TouchType = {
    None = 1,
    Selected = 2,
    Drag = 3
}

function ItemSlotNormal:OnInit()
    self.ItemID = 0
    self.OnlySupportItemId = 0
    self.ItemInstanceID = 0
    self.ItemNum = 0
    self.HandleSelect = false
    self.IsHoldRightMouseButton = false
    self.CurrentTouchState = TouchType.None
    self.DragDistance = 0
    self.DragOperationActiveMinDistance = 10.0;
    self.DragStartPosition = UE.FVector2D()
    self.DragStartPosition.X = 0
    self.DragStartPosition.Y = 0


    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.MsgList = {
		{ MsgName = GameDefine.Msg.PLAYER_SkillProgressNotifyUI_Start,      Func = self.SkillProgressNotifyUI_Start,    bCppMsg = false },
		{ MsgName = GameDefine.Msg.PLAYER_SkillProgressNotifyUI_End,        Func = self.SkillProgressNotifyUI_End,      bCppMsg = false },
        {MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Change_Weapon,Func = self.UpdateWeaponSlotSingle,bCppMsg = true },
        {MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Reset,Func = self.ResetWeaponSlotSingle,bCppMsg = true},
        { MsgName = GameDefine.Msg.InventoryItemMaxNumChange,               Func = self.OnInventoryItemMaxNumChange, bCppMsg = true  },
        { MsgName = GameDefine.Msg.InventoryItemSlotDragOnDrop,             Func = self.OnInventoryItemDragOnDrop,      bCppMsg = false },
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickAll,              Func = self.OnDiscardAll ,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickHalf,             Func = self.OnDiscardHalf,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickPart,             Func = self.OnDiscardPart,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
    }
    self.ProgressBar_Bullet:SetVisibility(UE.ESlateVisibility.Collapsed)

    UserWidget.OnInit(self)
end


function ItemSlotNormal:OnDestroy()
    self.ItemID = nil
    self.ItemInstanceID = nil
    self.ItemNum = nil
    self.HandleSelect = nil
    self.IsHoldRightMouseButton = nil

    UserWidget.OnDestroy(self)
end

function ItemSlotNormal:OnClose(...)
    -- 清理UI状态变量
    self.HandleSelect = nil
    self.IsHoldRightMouseButton = nil
    self.bDraging = false
end

function ItemSlotNormal:UpdateWeaponSlotSingle()
    if self.ItemID == 0 then return end
    self:UpdateRecommendSupers()
end

function ItemSlotNormal:ResetWeaponSlotSingle()
    if self.ItemID == 0 then return end
    self:UpdateRecommendSupers()
end

function ItemSlotNormal:SetOnlySupportItemId(OnlySupportItemId)
    self.OnlySupportItemId = OnlySupportItemId
end

function ItemSlotNormal:SkillProgressNotifyUI_Start(MsgBody)
    --self:StartAnimation_ProgressBar(MsgDuration)
end

function ItemSlotNormal:SkillProgressNotifyUI_End(MsgBody)
    --self:EndAnimation_ProgressBar()
end


function ItemSlotNormal:OnInventoryItemMaxNumChange(ItemID, newValue)
    if self.ItemID ~= ItemID then return end
    local CurrentItemMaxNum = self:UpdateItemMaxNum()
    self:UpdateItemNumBar(self.ItemNum, self.ItemMaxNum)
end


--处理左键拖拽、右键丢弃逻辑
function ItemSlotNormal:OnMouseButtonDown(MyGeometry, MouseEvent)
    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Click_01")
    if (self.ItemID == 0 or self.ItemInstanceID == 0) then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    if BridgeHelper.IsMobilePlatform() then
        -- Mobile平台
        self:SetTouchState(TouchType.Selected)
        self.DragDistance = 0

        local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
        if not MouseKey then return UE.UWidgetBlueprintLibrary.Handled() end

        local CurrentDragPositionInViewport = UE.UGFUnluaHelper.FPointerEvent_GetScreenSpacePosition(MouseEvent)
        self.DragStartPosition = CurrentDragPositionInViewport

        return UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent, self, MouseKey)
    else
        -- PC平台
        local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
        if not MouseKey then return UE.UWidgetBlueprintLibrary.Handled() end

        if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton then
            return UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent,self, MouseKey)
        elseif MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton then
            self:TryDiscardItem()
        end

        return UE.UWidgetBlueprintLibrary.Handled()
    end
end


function ItemSlotNormal:OnMouseButtonUp(MyGeometry, MouseEvent)
    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Handled()
    if BridgeHelper.IsMobilePlatform() then
        self.CurrentTouchState = TouchType.None
        if self.HandleSelect then
            if self.ItemID~=-1 then
                MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo, {
                    HoverWidget = self,
                    ParentWidget = nil,
                    IsShowAtLeftSide = true,
                    ItemID=self.ItemID,
                    ItemInstanceID = self.ItemInstanceID,
                    ItemNum = self.ItemNum,
                    IsShowDiscardNum = true,
                    InteractionKeyName = nil,
                    ShowSourceType = ItemSystemHelper.ItemDetialInfoShowMsgSourceType.BagSystem
                })
            end
        end
        return DefaultReturnValue
    end

    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then
        return DefaultReturnValue
    end

    if MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton then
        return DefaultReturnValue
    end

    if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton and (self.ItemID ~= 0 and self.ItemInstanceID ~= 0) then
        -- if self.HandleSelect then
        --     -- 使用物品
        --     local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        --     local TempBagComp = UE.UBagComponent.Get(PlayerController)
        --     if not TempBagComp then
        --         return DefaultReturnValue
        --     end

        --     local TempItemType, IsFindTempItemType = UE.UItemSystemManager.GetItemDataFName(PlayerController,self.ItemID, "ItemType",GameDefine.NItemSubTable.Ingame,"ItemSlotNormal:OnMouseButtonUp")
        --     if not IsFindTempItemType then
        --         return DefaultReturnValue
        --     end

        --     if (TempItemType == "Throwable") or (TempItemType == "Potion") then
        --         -- 使用物品
        --         local TempPlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        --         local TempBagComp = UE.UBagComponent.Get(TempPlayerController)
        --         if not TempBagComp then return end
        --         local TempInventoryInstanceArray = TempBagComp:GetAllItemObjectByItemID(self.ItemID)
        --         if not TempInventoryInstanceArray then return end
        --         local FirstInventoryInstance = TempInventoryInstanceArray:Get(1)
        --         if FirstInventoryInstance and FirstInventoryInstance.ClientUseSkill then
        --             FirstInventoryInstance:ClientUseSkill()
        --         end
        --     else
        --         -- 其他物品

        --         local TempInventoryIdentity = UE.FInventoryIdentity()
        --         TempInventoryIdentity.ItemID = self.ItemID
        --         TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID

        --         UE.UItemStatics.UseItem(PlayerController, TempInventoryIdentity, ItemSystemHelper.NUsefulReason.PlayerActiveUse)
        --     end
        -- end
        if self.HandleSelect then
            self:UseItem()
        end

    elseif GameDefine.NInputKey.MiddleMouseButton == MouseKey.KeyName then
        if self.ItemID ~= 0 and nil ~= self.ItemID then
            AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithItemId(self, self.ItemID)
            print("ItemSlotNormal:OnMouseButtonUp SendMsg Own ItemSlotNormal !")
        else
            AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemTypeId(self, self.OnlySupportItemId)
            print("ItemSlotNormal:OnMouseButtonUp SendMsg Need ItemSlotNormal !")
        end
    end

    return DefaultReturnValue
end

function ItemSlotNormal:UseItem()




        -- 使用物品
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        local TempBagComp = UE.UBagComponent.Get(PlayerController)
        if not TempBagComp then
            return
        end

        local TempItemType, IsFindTempItemType = UE.UItemSystemManager.GetItemDataFName(PlayerController,self.ItemID, "ItemType",GameDefine.NItemSubTable.Ingame,"ItemSlotNormal:OnMouseButtonUp")
        if not IsFindTempItemType then
            return
        end

        if (TempItemType == "Throwable") or (TempItemType == "Potion") then
            -- 使用物品
            local TempPlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
            local TempBagComp = UE.UBagComponent.Get(TempPlayerController)
            if not TempBagComp then return end
            local TempInventoryInstanceArray = TempBagComp:GetAllItemObjectByItemID(self.ItemID)
            if not TempInventoryInstanceArray then return end
            local FirstInventoryInstance = TempInventoryInstanceArray:Get(1)
            if FirstInventoryInstance and FirstInventoryInstance.ClientUseSkill then
                FirstInventoryInstance:ClientUseSkill()
            end
        else
            -- 其他物品

            local TempInventoryIdentity = UE.FInventoryIdentity()
            TempInventoryIdentity.ItemID = self.ItemID
            TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID

            UE.UItemStatics.UseItem(PlayerController, TempInventoryIdentity, ItemSystemHelper.NUsefulReason.PlayerActiveUse)
        end
end

function ItemSlotNormal:SetTouchState(InState)
    local PreState = self.CurrentTouchState

    self.CurrentTouchState = InState

    if self.CurrentTouchState == TouchType.None then

    elseif self.CurrentTouchState == TouchType.Selected then

    elseif self.CurrentTouchState == TouchType.Drag then

    end

    return PreState
end

function ItemSlotNormal:OnDiscardAll (InInputData)
    if not self.HandleSelect then
        return
    end
    self:DiscardItemNormal()
end

function ItemSlotNormal:OnDiscardHalf(InInputData)
    if not self.HandleSelect then
        return
    end

    self:DiscardHalf()
end

function ItemSlotNormal:OnDiscardPart(InInputData)
    if not self.HandleSelect then
        return
    end
    self:DiscardItemQuick()
end


function ItemSlotNormal:DiscardItemPopUI(InPC)

    -- 如果是不可主动丢弃的，则无法打开界面
    local TempInventoryIdentity = UE.FInventoryIdentity()
    TempInventoryIdentity.ItemID = self.ItemID
    TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID
    local BagComponent = UE.UBagComponent.Get(InPC)
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
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsInt(GenericBlackboardContainer, BlackboardKeySelector, self.ItemID)
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
    -- MsgHelper:Send(self, GameDefine.Msg.PLAYER_ToggleDropPartOfItem, {isShow = true, ItemID = self.ItemID, InstanceID = self.ItemInstanceID, MinNum = 1, MaxNum = self.ItemNum , CurrentNum = self.ItemNum/2})

end



function ItemSlotNormal:DiscardHalf()
    local TempPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not TempPC then
        return
    end

    local TempInventoryIdentity = UE.FInventoryIdentity()
    TempInventoryIdentity.ItemID = self.ItemID
    TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID

    local TempDiscardNum = math.ceil(self.ItemNum/2)
    local TempDiscardReasonTag = UE.FGameplayTag()
    self:DiscardItemFromTheMin(TempPC, TempDiscardNum, TempDiscardReasonTag)
end

--丢弃
function ItemSlotNormal:TryDiscardItem()
    local TempPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not TempPC then
        return
    end

    -- （Ctrl + 右键）----> 丢弃部分物品
    if TempPC:IsInputKeyDown(UE.EKeys.LeftControl) or TempPC:IsInputKeyDown(UE.EKeys.RightControl) then
        -- 如果是不可主动丢弃的，则无法打开界面
        self:DiscardItemPopUI(TempPC)
        return
    end

    -- （Alt + 右键）----> 丢弃一半物品
    if TempPC:IsInputKeyDown(UE.EKeys.LeftAlt) or TempPC:IsInputKeyDown(UE.EKeys.RightAlt) then
        self:DiscardHalf()
        return
    end

    -- （右键）----> 快捷丢弃 or 全部丢弃
    if (self.ItemID ~= 0 and self.ItemInstanceID ~= 0) then
        local IsQuickDiscard = false;
        local InventoryItemDevSettingCDO = UE.UGFUnluaHelper.GetDefaultObject(self.InventoryItemDevSettingClass)
        if InventoryItemDevSettingCDO then
            IsQuickDiscard = InventoryItemDevSettingCDO.IsQuickDiscardFlag
        end
        if IsQuickDiscard then
            self:DiscardItemQuick()
        else
            self:DiscardItemNormal()
        end

        return
    end

end

-- 普通丢弃（丢弃个数 = 当前堆叠个数）
function ItemSlotNormal:DiscardItemNormal()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    local TempInventoryIdentity = UE.FInventoryIdentity()
    TempInventoryIdentity.ItemID = self.ItemID
    TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID
    local BagComponent = UE.UBagComponent.Get(PlayerController)
    if not BagComponent then return end
    local TempInventoryInstance = BagComponent:GetInventoryInstance(TempInventoryIdentity)
    if not TempInventoryInstance then return end
    local DiscardNum = TempInventoryInstance:GetStackNum()
    local TempDiscardReasonTag = UE.FGameplayTag()

    self:DiscardItemFromTheMin(PlayerController, DiscardNum, TempDiscardReasonTag)
end

-- 快速丢弃（丢弃个数 = 快捷丢弃配置个数）
function ItemSlotNormal:DiscardItemQuick()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)

    -- 这里需要判断ItemSlotNormal中的物品类型
    -- 这个UI控件支持的物品类型有各种药品，各种投掷物，还有武器配件

    local TempDiscardReasonTag = UE.FGameplayTag()

    local TempItemType, IsFindTempItemType = UE.UItemSystemManager.GetItemDataFName(self,self.ItemID, "ItemType",GameDefine.NItemSubTable.Ingame,"ItemSlotNormal:SetItemInfo")
    if not IsFindTempItemType then
        return
    end

    -- 如果是配件，则丢弃一个；如果非配件，则从最小堆开始丢弃
    if TempItemType == ItemSystemHelper.NItemType.Attachment then
        self:DiscardItemDirectly(PlayerController, self.ItemID, self.ItemInstanceID, 1, TempDiscardReasonTag)
    else
        local InventoryQuickDiscardNum, bInventoryQuickDiscardNum = UE.UItemSystemManager.GetItemDataInt32(PlayerController, self.ItemID, "InventoryQuickDiscardNum", GameDefine.NItemSubTable.Ingame,"ItemSlotNormal:DiscardItemQuick")
        if bInventoryQuickDiscardNum then
            self:DiscardItemFromTheMin(PlayerController, InventoryQuickDiscardNum, TempDiscardReasonTag)
        end
    end
end


function ItemSlotNormal:DiscardItemFromTheMin(InPlayerController, InDiscardNum, InTag)
    UE.UItemStatics.DiscardItemFromTheMinStack(InPlayerController, self.ItemID, InDiscardNum, InTag)
    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Item_Discard")
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end

function ItemSlotNormal:DiscardItemDirectly(InPlayerController, ItemId, ItemInstanceId, InDiscardNum, InTag)
    local TempInventoryIdentity = UE.FInventoryIdentity()
    TempInventoryIdentity.ItemID = ItemId
    TempInventoryIdentity.ItemInstanceID = ItemInstanceId
    UE.UItemStatics.DiscardItem(InPlayerController, TempInventoryIdentity, InDiscardNum, InTag)
    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Item_Discard")
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end


--Override 拖拽事件
function ItemSlotNormal:OnDragDetected(MyGeometry, PointerEvent)
    print("ItemSlotNormal:OnDragDetected")
    local DragDropObject = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(self.DragDropOperationClass)
    self:StartAttachmentGuide()
    self.bDraging = true
    local DefaultDragVisualWidget = UE.UWidgetBlueprintLibrary.Create(self, self.DefaultDragVisualClass)
    self.CurrentDragVisualWidget = DefaultDragVisualWidget
    if BridgeHelper.IsMobilePlatform() then
        self.CurrentDragVisualWidget:SetDragVisibility(false)
    end
    DragDropObject.DefaultDragVisual = DefaultDragVisualWidget

    if self.Overlay_Active then self:VXE_HUD_Bag_Attach_Floating_In() end
    DefaultDragVisualWidget:SetDragInfo(self.ItemID, self.ItemInstanceID, self.ItemNum, GameDefine.InstanceIDType.ItemInstance)
    DefaultDragVisualWidget:SetDragSource(GameDefine.DragActionSource.BagZoom,self)
    return DragDropObject
end

function ItemSlotNormal:OnDragComplete()
    print("ItemSlotNormal:OnDragComplete")
    self.bDraging = false
    self:EndAttachmentGuide()
end

function ItemSlotNormal:GetSlotNormalInventoryIdentity()
    return self.ItemID, self.ItemInstanceID
end

--该物品槽是否存在有效数据
function ItemSlotNormal:IsValidItemSlotNormal()
    local TempItemId, TempItemInstanceId = self:GetSlotNormalInventoryIdentity()
    if TempItemId ~= 0 then
        return true
    end

    return false
end

function ItemSlotNormal:SetItemInfo(InInventoryIdentity, ItemNum)
    -- 新 ItemId
    local NewItemId = self.ItemID ~= InInventoryIdentity.ItemID
    self.ItemID = InInventoryIdentity.ItemID
    self.ItemInstanceID = InInventoryIdentity.ItemInstanceID

    if NewItemId then
        -- 物品图标
        self.Image_Item:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:SetItemIconImage(self.ItemID)

        -- 物品等级
        local ItemLevel, IsFindItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, self.ItemID, "ItemLevel", GameDefine.NItemSubTable.Ingame, "ItemSlotNormal:SetItemInfo")
        if IsFindItemLevel then
            local BackgroundImage = self.BackgroundImageMap:Find(ItemLevel)
            if BackgroundImage then
                self.BrushImage = BackgroundImage
            end
        end

        local TempItemType, IsFindTempItemType = UE.UItemSystemManager.GetItemDataFName(self, self.ItemID, "ItemType",GameDefine.NItemSubTable.Ingame,"ItemSlotNormal:SetItemInfo")
        if IsFindTempItemType then
            self.ItemType = TempItemType
        end



        -- 倍镜特殊处理（显示/隐藏）
        local MiscSystemIns = UE.UMiscSystem.GetMiscSystem(self)
        local MagnifierType = MiscSystemIns.MagnifierTypeMap:Find(self.ItemID)
        if MagnifierType then
            self.Text_ScaleMutiplay:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.Text_ScaleMutiplay:SetText(MagnifierType.Multiple)
        else
            self.Text_ScaleMutiplay:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        self.ItemNum = 0
        self:UpdateItemNumBarType()
        self:UpdateNumTextVisiable()
    end

    if self.ItemNum ~= ItemNum then
        -- 更新物品的个数进度条类型
        self.ItemNum = ItemNum
        self:UpdateNum(self.ItemNum)
    end

    self:UpdateRecommendSupers()
end

function ItemSlotNormal:UpdateNumTextVisiable()
    self.ItemMaxNum = self:UpdateItemMaxNum(self.ItemID)
    -- 设置文本是否显示
    if self.ItemMaxNum > 1 then
        self.TextBlock_Num:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.TextBlock_Num:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end


function ItemSlotNormal:UpdateRecommendSupers()
    local IsShowNotRecommendUI = self:IsShowNotRecommendSuperscript()
    if IsShowNotRecommendUI then
        self.GUIImage_NotRecommend:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.GUIImage_NotRecommend:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end


function ItemSlotNormal:SetFlushFlag(InState)

    self.FlushFlag = InState
end


function ItemSlotNormal:CheckFluchFlag()
    if not self.FlushFlag then
        self:ResetItemInfo()
    end
end


--重置物品图标
function ItemSlotNormal:ResetItemInfo()
    self.ItemID = 0
    self.ItemInstanceID = 0
    self.ItemMaxNum = 0
    self.ItemNum = 0
    self.ItemType = "None"

    self.Image_Item:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.CountLine:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.ProgressBar_Bullet:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TextBlock_Num:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Image_Item:SetBrushFromTexture(nil, true)
    self.GUIImage_NotRecommend:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Text_ScaleMutiplay:SetVisibility(UE.ESlateVisibility.Collapsed )
end


function ItemSlotNormal:SetItemSlotToEmptySlotStyle()
    self.ItemID = 0
    self.ItemInstanceID = 0
    self.ItemNum = 0

    self.Image_Item:SetVisibility(UE.ESlateVisibility.Hidden)
    self.TextBlock_Num:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Image_Item:SetBrushFromTexture(nil, true)
    self.GUIImage_NotRecommend:SetVisibility(UE.ESlateVisibility.Collapsed)

    -- 设置为空物品的风格底图
    self.BrushImage = self.EmptySlotBackgroundImage
end


function ItemSlotNormal:UpdateNum(NewNum)
    if self.ItemMaxNum > 1 then
        self.TextBlock_Num:SetText(tostring(self.ItemNum))
    end

    self:UpdateItemNumBar(self.ItemNum, self.ItemMaxNum)
end

function ItemSlotNormal:GetNum()
    if self.ItemNum then
        return self.ItemNum
    else
        return 0
    end
end


function ItemSlotNormal:VXE_NumAdd()
    local UIManager = UE.UGUIManager.GetUIManager(self)
    local bIsOpenBagUI = UIManager:IsAnyDynamicWidgetShowByKey("UMG_Bag")
    if bIsOpenBagUI then
        self:VXE_HUD_Bag_Attach()
    end
end


function ItemSlotNormal:UpdateItemNumBarType()
    if self.ItemType == ItemSystemHelper.NItemType.Bullet then
        self.CountLine:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.ProgressBar_Bullet:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.CountLine:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.ProgressBar_Bullet:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function ItemSlotNormal:UpdateItemNumBar(ItemNum, ItemMaxNum)
    if self.ItemType == ItemSystemHelper.NItemType.Bullet then
        -- 是子弹
        if ItemMaxNum > 0 then
            local value = ItemNum / ItemMaxNum
            self.ProgressBar_Bullet:SetPercent(value)
        else
            self.ProgressBar_Bullet:SetPercent(0.0)
        end
    else
        --是其他
        local BarNum = self.CountLine:GetChildrenCount()
        for index = 1, BarNum do
            local BarWidget = self.CountLine:GetChildAt(index-1)

            if index > self.ItemMaxNum then
                BarWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
            else
                BarWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                local IsEmptyBlockState = index <= ItemNum
                BarWidget:SetNumState(IsEmptyBlockState)
            end
        end
    end
end


function ItemSlotNormal:IsShowNotRecommendSuperscript()
    local ReturnValue = false

    if not self.ItemID then
        return ReturnValue
    end

    local TempPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not TempPC then
        return ReturnValue
    end

    local TempBagComp = UE.UBagComponent.Get(TempPC)
    if not TempBagComp then
        return ReturnValue
    end

    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(TempPC, self.ItemID)
    if not IngameDT then
        return ReturnValue
    end

    local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(self.ItemID))
    if not StructInfo_Item then
        return ReturnValue
    end

    if StructInfo_Item.ItemType == ItemSystemHelper.NItemType.Attachment or StructInfo_Item.ItemType ==
        ItemSystemHelper.NItemType.Bullet then

        local WeaponItmeObjectArray = TempBagComp:GetItemByItemType(ItemSystemHelper.NItemType.Weapon)
        local WeaponNum = WeaponItmeObjectArray:Length()
        if WeaponNum <= 0 then
            return true
        end

        local IsSupportWAttachmentFinal = false
        local IsLowestLevelWAttachment = true
        local IsMatchBulletType = false

        -- 获取当前武器
        for i = 1, WeaponNum, 1 do
            -- 获取背包物品
            local TempInventoryInstance_Weapon = WeaponItmeObjectArray:Get(i)
            if not TempInventoryInstance_Weapon then
                goto continue
            end

            -- 获取武器实例
            local TempWeaponInstance = TempInventoryInstance_Weapon.CurrentEquippableInstance
            if not TempWeaponInstance then
                goto continue
            end

            local TempWeaponInventoryIdentity = TempInventoryInstance_Weapon:GetInventoryIdentity()
            if not TempWeaponInventoryIdentity then
                goto continue
            end

            local IngameDTForWeapon = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(TempPC,
                TempWeaponInventoryIdentity.ItemID)
            if not IngameDT then
                goto continue
            end

            local StructInfo_LoopWeapon = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDTForWeapon, tostring(
                TempWeaponInventoryIdentity.ItemID))
            if not StructInfo_LoopWeapon then
                goto continue
            end

            -- 根据类型判断
            if StructInfo_Item.ItemType == ItemSystemHelper.NItemType.Attachment then
                -- 芯片
                -- 瞄准镜和芯片都视为平级的，都不显示不推荐
                if (StructInfo_Item.SlotName.TagName == GameDefine.NTag.WEAPON_AttachSlot_Optics) and
                    (StructInfo_Item.SlotName.TagName == GameDefine.NTag.WEAPON_AttachSlot_HopUp) then
                    goto continue
                end

                local IsSupportWAttachment = UE.UGAWAttachmentFunctionLibrary.CanAttachToWeapon(TempWeaponInstance,
                    self.ItemID)
                if not IsSupportWAttachment then
                    goto continue
                end

                -- 得到特定槽位中配件的等级，进行对比，如果更低，则显示
                local WAttachmentHandleArray = UE.UGAWAttachmentFunctionLibrary.GetAllAttachmentEffectHandleInSlot(
                    TempWeaponInstance, StructInfo_Item.SlotName)
                if WAttachmentHandleArray:Length() > 0 then
                    local TempWAttachmentHandle = WAttachmentHandleArray:Get(1);
                    if not TempWAttachmentHandle then
                        goto continue
                    end

                    local StructInfo_AttachmentInWewpon = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT,
                        tostring(TempWAttachmentHandle.ItemID))
                    if not StructInfo_AttachmentInWewpon then
                        goto continue
                    end

                    if StructInfo_Item.ItemLevel >= StructInfo_AttachmentInWewpon.ItemLevel then
                        IsLowestLevelWAttachment = false
                    end
                else
                    IsLowestLevelWAttachment = false
                end

                if not IsSupportWAttachmentFinal then
                    if IsSupportWAttachment then
                        IsSupportWAttachmentFinal = true
                    end
                end

            elseif StructInfo_Item.ItemType == ItemSystemHelper.NItemType.Bullet then
                -- 子弹
                if self.ItemID == StructInfo_LoopWeapon.BulletItemID then
                    IsMatchBulletType = true
                    break
                end
            end

            ::continue::
        end

        -- 根据类型判断
        if StructInfo_Item.ItemType == ItemSystemHelper.NItemType.Attachment then
            if (StructInfo_Item.SlotName.TagName ~= GameDefine.NTag.WEAPON_AttachSlot_Optics) and
                (StructInfo_Item.SlotName.TagName ~= GameDefine.NTag.WEAPON_AttachSlot_HopUp) then
                -- 芯片
                if IsSupportWAttachmentFinal then
                    if IsLowestLevelWAttachment then
                        ReturnValue = true
                    end
                else
                    ReturnValue = true
                end
            end
        elseif StructInfo_Item.ItemType == ItemSystemHelper.NItemType.Bullet then
            -- 没有匹配到任何一种当前持有武器的子弹类型，则显示
            if not IsMatchBulletType then
                ReturnValue = true
            end
        end
    end

    return ReturnValue
end

function ItemSlotNormal:WillDestroy()
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end

--显示物品详细Tips
function ItemSlotNormal:OnMouseEnter(MyGeometry, MouseEvent)
    print("ItemSlotNormal:OnMouseEnter")
    self.HandleSelect = true
    if BridgeHelper.IsMobilePlatform() then
        return
    end
    UE.UGamepadUMGFunctionLibrary.ChangeCursorMoveRate(self, true)

    self:StartAttachmentGuide()
    self.Img_Border:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local TempInteractionKeyName = self:GetDetailInfoInteractionKeyName()

    if self.ItemID ~= 0 then
        MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo, {
            HoverWidget = self,
            ParentWidget = nil,
            IsShowAtLeftSide = true,
            ItemID = self.ItemID,
            ItemInstanceID = self.ItemInstanceID,
            ItemNum = self.ItemNum,
            IsShowDiscardNum = true,
            InteractionKeyName = TempInteractionKeyName,
            ShowSourceType = ItemSystemHelper.ItemDetialInfoShowMsgSourceType.BagSystem
        })
    end
end

--隐藏物品详细Tips
function ItemSlotNormal:OnMouseLeave(MouseEvent)
    print("ItemSlotNormal:OnMouseLeave")
    self.HandleSelect = false
    if BridgeHelper.IsMobilePlatform() then
        return
    end

    if not self.bDraging then
        self:EndAttachmentGuide()
    end

    self.Img_Border:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.IsHoldRightMouseButton = false

    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
    UE.UGamepadUMGFunctionLibrary.ChangeCursorMoveRate(self, false)
end

-- function ItemSlotNormal:OnMouseButtonDoubleClick(InMyGeometry, InMouseEvent)
--     return UE.UWidgetBlueprintLibrary.Unhandled()
-- end
function ItemSlotNormal:OnDragEnter(MyGeometry, PointerEvent, Operation)
    self.Img_Border:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function ItemSlotNormal:OnDragLeave(PointerEvent, Operation)
    self.Img_Border:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function ItemSlotNormal:OnDragOver(MyGeometry, MouseEvent, Operation)
    if not self.CurrentDragVisualWidget then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    print("ItemSlotNormal:OnDragOver")
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

function ItemSlotNormal:StartAnimation_ProgressBar(DurationTime)
    if not DurationTime then return end
    self.CanvasPanel_Anim:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:PlayAnimation(self.ReplaceAnim,0.0, 1,0, 1.0 / DurationTime)
    self.HoldTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.EndAnimation_ProgressBar}, DurationTime, false, 0, 0)
end

function ItemSlotNormal:EndAnimation_ProgressBar()
    self.CanvasPanel_Anim:SetVisibility(UE.ESlateVisibility.Collapsed)
    if self.HoldTimer then
		UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.HoldTimer)
		self.HoldTimer = nil
    end
end

function ItemSlotNormal:GetDetailInfoInteractionKeyName()
    local ReturnKeyName = nil

    local TempItemId = self.ItemID
    if not TempItemId then
        return ReturnKeyName
    end

    local TempPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not TempPC then
        return ReturnKeyName
    end

    local TempItemType, IsExistColumn_ItemType = UE.UItemSystemManager.GetItemDataFName(TempPC, TempItemId, "ItemType", GameDefine.NItemSubTable.Ingame, "ItemSlotNormal:GetDetailInfoInteractionKeyName")
    if not IsExistColumn_ItemType then
        return ReturnKeyName
    end

    if TempItemType == ItemSystemHelper.NItemType.Bullet then
        ReturnKeyName = "Bag.Default.4Action"

    elseif TempItemType == ItemSystemHelper.NItemType.Attachment then
        ReturnKeyName = "Bag.Attachment.CanAttach"

    elseif TempItemType == ItemSystemHelper.NItemType.Throwable then
        ReturnKeyName = "Bag.Throwable.Default"

    elseif TempItemType == ItemSystemHelper.NItemType.Potion then
        ReturnKeyName = "Bag.Potion.Default"
        
    else
        ReturnKeyName = "Bag.Default.2Action"

    end

    return ReturnKeyName
end

function ItemSlotNormal:StartAttachmentGuide()
    local InventoryIdentity = UE.FInventoryIdentity()
    InventoryIdentity.ItemID = self.ItemID
    InventoryIdentity.ItemInstanceID = self.ItemInstanceID
    self.StartAttachmentGuideEvent:Broadcast(InventoryIdentity)
end

function ItemSlotNormal:EndAttachmentGuide()
    self.EndAttachmentGuideEvent:Broadcast()
end

function ItemSlotNormal:OnInventoryItemDragOnDrop(InMsgBody)
    if self.Overlay_Active and self.Overlay_Active:GetRenderOpacity() ~= 1 then
        self:VXE_HUD_Bag_Attach_Floating_Out()
    end
end




return ItemSlotNormal
