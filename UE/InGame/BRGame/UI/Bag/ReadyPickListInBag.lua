require "UnLua"
require ("InGame.BRGame.ItemSystem.PickSystemHelper")

local ReadyPickListInBag = Class("Common.Framework.UserWidget")

function ReadyPickListInBag:OnInit()
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.MsgList = {
        { MsgName = "Bag.ReadyPickup.Update",	            Func = self.ReadyPickupUpdate,          bCppMsg = true, WatchedObject = nil},
        { MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDead,	Func = self.CharacterBeginDead,         bCppMsg = true, WatchedObject = nil},
        -- { MsgName = GameDefine.MsgCpp.BagUI_UseItem,       Func = self.OnSelectArea,    bCppMsg = true, WatchedObject = TempLocalPC },
    }
    self:ReadyPickupUpdate()
    
    UserWidget.OnInit(self)
end

function ReadyPickListInBag:OnShow()
    print("[Wzp]ReadyPickListInBag >> OnShow")
end

function ReadyPickListInBag:OnClose()
    local TipsManager = UE.UTipsManager.GetTipsManager(self)
    TipsManager:RemoveTipsUI("Guide.PickupItemList")
end

function ReadyPickListInBag:OnDestroy()
    UserWidget.OnDestroy(self)
end

function ReadyPickListInBag:ReadyPickupUpdate()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)

    --因为目前主端发死亡消息的地方，和查询人物状态的地方不一样，所以，两边都需要判断。
    local LocalPS = PlayerController.PlayerState
    if not LocalPS or not LocalPS:IsAlive() then
        return
    end
    --因为目前主端发死亡消息的地方，和查询人物状态的地方不一样，所以，两边都需要判断。
    local Character = PlayerController:K2_GetPawn()
    if not Character or not UE.US1PickupStatics.IsPlayerAlive(Character) then
        return
    end

    local AllChildWidget = self.ScrollBox_ReadyPick:GetAllChildren()
    local ChildNum = AllChildWidget:Length()
    for index = 1, ChildNum, 1 do
        local Widget = AllChildWidget:GetRef(index)
        if Widget then
            Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end

    local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
    if not PickupSetting then
        return
    end
    if not PickupSetting.SinglePickList then
        self.ScrollBox_ReadyPick_1:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        -- body
        local AllChildWidget = self.ScrollBox_ReadyPick_1:GetAllChildren()
        local ChildNum = AllChildWidget:Length()
        for index = 1, ChildNum, 1 do
            local Widget = AllChildWidget:GetRef(index)
            if Widget then
                Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        end
    else
        self.ScrollBox_ReadyPick_1:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    -- -- -- 剩下的就是要添加的
    local PickupObjArray = PickSystemHelper.GetLastReadyToPickObjArray(Character)
    if not PickupObjArray then
        return
    end

    self.ItemIdToWidgetTable:Clear()

    local ChildIndex = 0
    local ChildIndex2 = 0
    local ReadyPickNum = PickupObjArray:Length()
    for index = 1, ReadyPickNum, 1 do
        -- 如果是更新的，则不会处理
        local PickupObj = PickupObjArray:GetRef(index)
        if not PickupObj or PickupObj:IsBootyBox() then
            goto continue
        end

        -- 处理类型
        local CurItemType, IsFindType = UE.UItemSystemManager.GetItemDataFName(self, PickupObj.ItemInfo.ItemID,
            "ItemType", GameDefine.NItemSubTable.Ingame, "ReadyPickListInBag:ReadyPickupUpdate")
        if not IsFindType then
            goto continue
        end
        --判断该拾取物是否可融合拾取
        if PickupSetting.ItemTypeForCombine:Contains(tostring(CurItemType))then
            local TargetWidget = self.ItemIdToWidgetTable:Find(PickupObj.ItemInfo.ItemID)
            if TargetWidget then
                TargetWidget:AddPickupObj(PickupObj)
                goto continue
            end
        end

        local UseList1 = true
        --如果是双列表模式，需要判断物品类型
        if not PickupSetting.SinglePickList then
            if PickupSetting.ItemTypeInList2:Contains(tostring(CurItemType)) then
                UseList1 = false
            end
        end

        --决定使用哪个list
        self.TargeteScrollBox = UseList1 and self.ScrollBox_ReadyPick or self.ScrollBox_ReadyPick_1
        local TargetIndex = UseList1 and ChildIndex or ChildIndex2

        local IsShowInUI, IsFindShowInUI = UE.UItemSystemManager.GetItemDataBool(self,
        PickupObj.ItemInfo.ItemID, "IsShowInUI",GameDefine.NItemSubTable.Ingame,"ReadyPickListInBag:ReadyPickupUpdate")
        if IsFindShowInUI and not IsShowInUI then
            goto continue
        end
        local NotLoopToMax = TargetIndex < self.TargeteScrollBox:GetChildrenCount()
        local OldChildWidget = self.TargeteScrollBox:GetChildAt(TargetIndex)
        if UseList1 then
            ChildIndex = ChildIndex + 1
        else
            ChildIndex2 = ChildIndex2 + 1
        end
        if OldChildWidget and NotLoopToMax then
            OldChildWidget:SetDetail(PickupObj, self)
            OldChildWidget:SetVisibility(UE.ESlateVisibility.Visible)
            if PickupSetting.ItemTypeForCombine:Contains(tostring(CurItemType)) then
                self.ItemIdToWidgetTable:Add(PickupObj.ItemInfo.ItemID,OldChildWidget)
            end
        else
            local ReadyPickWidget = UE.UWidgetBlueprintLibrary.Create(self, self.ReadyPickWidgetClass)
            local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
            ReadyPickWidget.bIsFocusable = not IsInCursorMode

            ReadyPickWidget:SetDetail(PickupObj, self)
            ReadyPickWidget:SetVisibility(UE.ESlateVisibility.Visible)
            if PickupSetting.ItemTypeForCombine:Contains(tostring(CurItemType)) then
                self.ItemIdToWidgetTable:Add(PickupObj.ItemInfo.ItemID,ReadyPickWidget)
            end
            local ScrollSlot = self.TargeteScrollBox:AddChild(ReadyPickWidget)
            if ScrollSlot then
                local margin = UE.FMargin()
                margin.Top = 4.0
                ScrollSlot:SetPadding(margin)
            end
        end

        ::continue::
    end

    self.ScrollBox_ReadyPick:SetVisibility(ChildIndex <= 0 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    local bIsFocusable = ChildIndex > 0 
    self.Delegate_ReadyPickListRetrunFocus:Broadcast(bIsFocusable)
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if not UIManager then return end
    local LobbyPlayerInfoViewModel = UIManager:GetViewModelByName("TagLayout.Gameplay.LobbyPlayerInfo")
    if not LobbyPlayerInfoViewModel then return end
    if LobbyPlayerInfoViewModel.PlayerPlayCount < 3 then self:UpdateGuideTips() end
end

function ReadyPickListInBag:UpdateGuideTips()
    local UIManager = UE.UGUIManager.GetUIManager(self)
    local bIsOpenBagUI = UIManager:IsAnyDynamicWidgetShowByKey("UMG_Bag")
    if not bIsOpenBagUI then return end
    if not self.TargeteScrollBox then return end
    if self.TargeteScrollBox:GetChildrenCount() <= 0 then return end
    local bShowPickupItem = self.TargeteScrollBox:GetChildAt(0):GetVisibility()
    local TipsManager = UE.UTipsManager.GetTipsManager(self)
    local bShowGuideTips = TipsManager:IsTipsIsShowing("Guide.PickupItemList")
    
    if bShowPickupItem == 0 and not bShowGuideTips then
        local GenericBlackboardContainer = UE.FGenericBlackboardContainer()
        local BlackboardKeySelector = UE.FGenericBlackboardKeySelector()
        BlackboardKeySelector.SelectedKeyName = "Anchors"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsVector(GenericBlackboardContainer,BlackboardKeySelector,UE.FVector(1,0,0))
        BlackboardKeySelector.SelectedKeyName = "Alignment"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsVector(GenericBlackboardContainer,BlackboardKeySelector,UE.FVector(1,0,0))
        TipsManager:ShowTipsUIByTipsId("Guide.PickupItemList", -1, GenericBlackboardContainer, self)
    elseif bShowPickupItem == 1 and bShowGuideTips then
        TipsManager:RemoveTipsUI("Guide.PickupItemList")
    end
end


function ReadyPickListInBag:GetReadyPickListAllWidget()
    if not self.TargeteScrollBox then return end
    local PickupCount = self.TargeteScrollBox:GetChildrenCount()
    local PickupTable = {}
    if PickupCount <= 0 then
        return false,PickupTable
    end
    for index = 1, PickupCount do
         local Widget = self.TargeteScrollBox:GetChildAt(index-1)
         table.insert(PickupTable,index,Widget)
    end
    return true,PickupTable
end

function ReadyPickListInBag:CharacterBeginDead(InDeadMessageInfo)
    print("nzyp " .. "ReadyPickListInBag:CharacterBeginDead")
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not InDeadMessageInfo then return end
    local Character = InDeadMessageInfo.DeadActor
    if not Character then return end
    if PlayerController == Character:GetController() then
        self.ScrollBox_ReadyPick:ClearChildren()
    end
end

function ReadyPickListInBag:OnDragEnter(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDragEnter:Broadcast(MyGeometry, PointerEvent, Operation)
end

function ReadyPickListInBag:OnDragLeave(PointerEvent, Operation)
    self.Delegate_TransportOnDragLeave:Broadcast(PointerEvent, Operation)
end

function ReadyPickListInBag:OnDrop(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    return true
end

function ReadyPickListInBag:OnFocusReceived(MyGeometry,InFocusEvent)

    self.HandleSelect = true
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function ReadyPickListInBag:OnFocusLost(InFocusEvent)

    self.HandleSelect = false
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
end



function ReadyPickListInBag:OnSelectArea()

    if not self.HandleSelect then
        return
    end

    local bHaveWidget,WidgetList = self:GetReadyPickListAllWidget()

    for _, Widget in pairs(WidgetList) do
        Widget.bIsFocusable = true
    end

    if bHaveWidget then
        WidgetList[1]:SetFocus()
    end
end



function ReadyPickListInBag:OnKeyDown(MyGeometry,InKeyEvent) 
	local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey == UE.FName("Gamepad_FaceButton_Bottom") then
        self:OnSelectArea()
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    return UE.UWidgetBlueprintLibrary.Unhandled()
end




return ReadyPickListInBag
