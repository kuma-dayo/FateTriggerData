require "UnLua"

local EmptySlotInContainer = Class("Common.Framework.UserWidget")
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")



function EmptySlotInContainer:OnInit()

    self.IsLock = false

    self.Image_MarkPanel:SetVisibility(self.OnlySupportItemId ~= 0 and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
    
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.MsgList  = {
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickPart,             Func = self.OnDiscardPart,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickAll,              Func = self.OnDiscardAll ,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickHalf,             Func = self.OnDiscardHalf,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardPopTip,             Func = self.OnDiscardPopTip,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
        -- { MsgName = GameDefine.MsgCpp.BagUI_UseItem,             Func = self.OnUseItem,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
    }

    if self.OnlySupportItemId ~= 0 then
        self:SetLockState(false)

        self.BP_ItemSlotNormal:SetOnlySupportItemId(self.OnlySupportItemId)

        self.Img_PerviewIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        -- 空状态预览物品图标
        local CurItemIcon, IsExistIcon = UE.UItemSystemManager.GetItemDataFString(self, self.OnlySupportItemId, "ItemIcon",
            GameDefine.NItemSubTable.Ingame, "EmptySlotInContainer:OnInit")
        if IsExistIcon then
            local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurItemIcon)
            self.Img_PerviewIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, true)
        end

    end
    self.HandleSelect =false
    UserWidget.OnInit(self)
end

function EmptySlotInContainer:OnDestroy()
    UserWidget.OnDestroy(self)
end



function EmptySlotInContainer:HasValidData()
    print("(Wzp)EmptySlotInContainer:HasValidData  [ObjectName]=",GetObjectName(self))
    if self.BP_ItemSlotNormal then
        return self.BP_ItemSlotNormal:IsValidItemSlotNormal()
    end
    return false
end

function EmptySlotInContainer:GetOnlySupportItemId()
    if self.OnlySupportItemId then
        print("(Wzp)EmptySlotInContainer:GetOnlySupportItemId  [self.OnlySupportItemId]=",self.OnlySupportItemId)
        return self.OnlySupportItemId
    end

    return 0
end

--设置是否锁定状态
function EmptySlotInContainer:SetLockState(InState)
    local HasValidData = self:HasValidData()
    if HasValidData then
        self.WS_LockState:SetActiveWidgetIndex(1)
        self.BP_ItemSlotNormal:SetVisibility(UE.ESlateVisibility.Visible)

    else
        if InState then
            self.IsLock = true
        else
            self.IsLock = false
        end


        self.BP_ItemSlotNormal:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
        self.WS_LockState:SetActiveWidgetIndex(InState and 0 or 1)
end

function EmptySlotInContainer:SetInvItemInfo(InInventoryInstance)
    if self.BP_ItemSlotNormal and InInventoryInstance then
        self.BP_ItemSlotNormal:SetItemInfo(InInventoryInstance:GetInventoryIdentity(), InInventoryInstance:GetStackNum())
        self:SetLockState(false)
    end
end

function EmptySlotInContainer:SetInvItemInfoV2(InInventoryIdentity, ItemNum)
    if self.BP_ItemSlotNormal and InInventoryIdentity and ItemNum then
        self.BP_ItemSlotNormal:SetItemInfo(InInventoryIdentity, ItemNum)
        self:SetLockState(false)
    end
end

function EmptySlotInContainer:ResetInvItemInfo()
    self.WS_LockState:SetActiveWidgetIndex(self.IsLock and 0 or 1)
    self.BP_ItemSlotNormal:SetVisibility(UE.ESlateVisibility.Collapsed)

    self.BP_ItemSlotNormal:ResetItemInfo()

end



function EmptySlotInContainer:OnDrop(MyGeometry, PointerEvent, Operation)
    local ItemID, ItemInstanceID = self.BP_ItemSlotNormal:GetSlotNormalInventoryIdentity()
    if ItemID and Operation and Operation.DefaultDragVisual then
        Operation.DefaultDragVisual:SetDragToHoverItemInfo(ItemID, ItemInstanceID)
    end

    self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    return true
end


function EmptySlotInContainer:OnMouseButtonDown(MyGeometry, MouseEvent)
    local DefaultReturnValue = UE.UWidgetBlueprintLibrary.Handled()
    
    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then
        return DefaultReturnValue
    end

    if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton then
        self.IsHoldLeftMouseButton = true
        DefaultReturnValue = UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent, self, MouseKey)
    elseif MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton then
    elseif GameDefine.NInputKey.MiddleMouseButton == MouseKey.KeyName then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        if PlayerController then
            local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
            if BattleChatComp then
                if self:GetOnlySupportItemId() == 0 then
                    local ItemID, ItemInstanceID = self.BP_ItemSlotNormal:GetSlotNormalInventoryIdentity()
                    if ItemID then
                        AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemTypeId(BattleChatComp, ItemID)
                        print("EmptySlotInContainer:OnMouseButtonDown SendMsg Need  !")
                    end
                else
                    AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemTypeId(BattleChatComp, self:GetOnlySupportItemId())
                    print("EmptySlotInContainer:OnMouseButtonDown SendMsg Need  !")
                end
            end
        end
    end

    return DefaultReturnValue
end

--显示物品详细Tips
function EmptySlotInContainer:OnMouseEnter(MyGeometry, MouseEvent)
    self.HandleSelect = true
end

--隐藏物品详细Tips
function EmptySlotInContainer:OnMouseLeave(MouseEvent)
    self.HandleSelect = false
end

function EmptySlotInContainer:OnFocusReceived(MyGeometry,InFocusEvent)

    self.HandleSelect = true
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function EmptySlotInContainer:OnFocusLost(InFocusEvent)
    self.HandleSelect = false
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function EmptySlotInContainer:OnDiscardPart(InInputData)
    if not self.HandleSelect then
        return
    end
    local bIsValid =  self:HasValidData()
    if bIsValid then
        self.BP_ItemSlotNormal:DiscardItemQuick()
    end
end

function EmptySlotInContainer:OnDiscardAll(InInputData)
    if not self.HandleSelect then
        return
    end
    local bIsValid =  self:HasValidData()
    if bIsValid then
        self.BP_ItemSlotNormal:DiscardItemNormal()
    end
end

function EmptySlotInContainer:OnDiscardHalf(InInputData)
    if not self.HandleSelect then
        return
    end
    local bIsValid =  self:HasValidData()
    if bIsValid then
        self.BP_ItemSlotNormal:DiscardHalf()
    end
end

function EmptySlotInContainer:OnUseItem()
    if not self.HandleSelect then
        return
    end
    local bIsValid =  self:HasValidData()
    if bIsValid then
        self.BP_ItemSlotNormal:UseItem()
    end
end


function EmptySlotInContainer:OnKeyDown(MyGeometry,InKeyEvent) 
	local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey == UE.FName("Gamepad_FaceButton_Bottom") then
        self:OnUseItem()
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    return UE.UWidgetBlueprintLibrary.Unhandled()
end

function EmptySlotInContainer:GetItemNormal()
    return self.BP_ItemSlotNormal
end

function EmptySlotInContainer:OnDiscardPopTip(InInputData)

    if not self.HandleSelect then
        return
    end

    local TempPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not TempPC then
        return
    end

    local bIsValid =  self:HasValidData()
    if bIsValid then
        self.BP_ItemSlotNormal:DiscardItemPopUI(TempPC)
    end
end

return EmptySlotInContainer