require "UnLua"
require "InGame.BRGame.ItemSystem.ItemBase.ItemAttachmentHelper"
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")
local ItemSlotWeaponAttachment = Class("Common.Framework.UserWidget")


-- function ItemSlotWeaponAttachment:Construct()
--     self.ItemID = -1
--     self.ItemInstanceID = -1
--     self.AttachmentEffectInstanceID = -1
--     self.IsHoldRightMouseButton = false
--     self.IsHoldLeftMouseButton = false
--     self.CanDetachFlag = true
--     self.bMobilePlatform = BridgeHelper.IsMobilePlatform()

--     self.Image_AttachmentType:SetBrushFromTexture(self.AttachmentType)
--     self:SetHighLightVisibility(false)
--     self:Reset()
-- end

-- function ItemSlotWeaponAttachment:Destruct()
--     self.ItemID = -1
--     self.ItemInstanceID = -1
--     self.AttachmentEffectInstanceID = -1
--     self.IsHoldRightMouseButton = nil
--     self.IsHoldLeftMouseButton = nil
-- end


function ItemSlotWeaponAttachment:OnInit()
    self.ItemID = -1
    self.ItemInstanceID = -1
    self.AttachmentEffectInstanceID = -1
    self.IsHoldRightMouseButton = false
    self.IsHoldLeftMouseButton = false
    self.CanDetachFlag = true
    self.bMobilePlatform = BridgeHelper.IsMobilePlatform()
    self.bStartGuide = false

    self.Image_AttachmentType:SetBrushFromTexture(self.AttachmentType)
    self:SetHighLightVisibility(false)
    self:Reset()

    self.MsgList = {
        { MsgName = GameDefine.Msg.InventoryItemSlotDragOnDrop,             Func = self.OnInventoryItemDragOnDrop,   bCppMsg = false},
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickAll,              Func = self.OnDropAll ,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
        -- { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickHalf,             Func = self.OnDiscardHalf,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
        { MsgName = GameDefine.MsgCpp.BagUI_DiscardAndPickPart,             Func = self.OnDropPart,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
        -- { MsgName = GameDefine.MsgCpp.BagUI_UseItem,             Func = self.OnUseItem,                  bCppMsg = true  ,WatchedObject = self.LocalPC},
    }


    UserWidget.OnInit(self)
end

function ItemSlotWeaponAttachment:OnDestroy()
    self.ItemID = -1
    self.ItemInstanceID = -1
    self.AttachmentEffectInstanceID = -1
    self.IsHoldRightMouseButton = nil
    self.IsHoldLeftMouseButton = nil
    UserWidget.OnDestroy(self)
end



function ItemSlotWeaponAttachment:UpdateTypeBackground(WeaponTag)
    
    local WeaponTagName = WeaponTag.TagName;
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
    self.Image_AttachmentType:SetBrushFromTexture(self.AttachmentType)
end

--移除配件到背包
function ItemSlotWeaponAttachment:OnDropPart()
    if not self.HandleSelect then
        return
    end
    self:DropInBag()
end

-- 丢弃配件
function ItemSlotWeaponAttachment:OnDropAll()
    if not self.HandleSelect then
        return
    end
    if not self:IsValidAttachmentUI() then
        return
    end
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    local DiscardInventoryIdentity = UE.FInventoryIdentity()
    DiscardInventoryIdentity.ItemID = self.ItemID
    DiscardInventoryIdentity.ItemInstanceID = self.ItemInstanceID
    local TempDiscardTag = UE.FGameplayTag()
    UE.UItemStatics.DiscardItem(PlayerController, DiscardInventoryIdentity, 1, TempDiscardTag)
    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Item_Discard")
end

-- move to C++
-- function ItemSlotWeaponAttachment:SetAttachmentInfo(InGAWeaponInstance, InGAWAttachmentEffect)
--     self.WeaponInstance = InGAWeaponInstance
--     self.ItemID = InGAWAttachmentEffect.ItemID
--     self.ItemInstanceID = InGAWAttachmentEffect.ItemInstanceID
--     self.AttachmentEffectInstanceID = InGAWAttachmentEffect.EffectHandle
-- end

-- move to C++
function ItemSlotWeaponAttachment:Reset()
    self.WeaponInstance = nil
    self.ItemID = -1
    self.ItemInstanceID = -1
    self.AttachmentEffectInstanceID = -1
    self.CanDetachFlag = true
    self:SetColor_ContentAndType(false)
    self.Image_Content:SetColorAndOpacity(self.BgImageBeUsedOpacity)
    self.Text_ScaleMutiplay:SetVisibility(UE.ESlateVisibility.Collapsed )
end

-- move to C++
-- 根据 配件等级 更新 背景颜色
function ItemSlotWeaponAttachment:UpdateBackGroundImage(InAttachmentLv,bInDatech)
    if InAttachmentLv and InAttachmentLv > 0  then

        if bInDatech == false then
           local DatechTex = self.CantDetachTexMap:Find(InAttachmentLv)
            if DatechTex then
                self.Image_Background:SetBrushFromSoftTexture(DatechTex, false)
                self.Image_Background:SetColorAndOpacity(self.BgImageDetachOpacity)
                return
            end
        end
        local BgImageObject = self.BgImageMap:Find(InAttachmentLv)
        if BgImageObject then
            -- 有配件
            self.Image_Background:SetBrushFromSoftTexture(BgImageObject, false)
            self.Image_Background:SetColorAndOpacity(self.BgImageBeUsedOpacity)
            return
        end
    end

    -- 无配件
    self.Image_Background:SetBrushFromSoftTexture(self.BgEmptyImageSoftObject, false)
    self.Image_Background:SetColorAndOpacity(self.BgImageEmptyOpacity)
end

-- move to C++
function ItemSlotWeaponAttachment:UpdateAttachment()
    -- 图片
    local SlotImage, RetSlotImage = UE.UItemSystemManager.GetItemDataFString(self, self.ItemID, "SlotImage", GameDefine.NItemSubTable.Ingame, "ItemSlotWeaponAttachment:UpdateAttachment")
    if RetSlotImage then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(SlotImage)
        self.Image_Content:SetBrushFromSoftTexture(ImageSoftObjectPtr)
    end


    local CurrentItemLevel, IsFindItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, self.ItemID, "ItemLevel", GameDefine.NItemSubTable.Ingame, "ItemSlotWeaponAttachment:UpdateAttachment")


    -- 倍镜特殊处理
    local MiscSystemIns = UE.UMiscSystem.GetMiscSystem(self)

    local MagnifierType = MiscSystemIns.MagnifierTypeMap:Find(self.ItemID)
    print("[Wzp]ItemSlotWeaponAttachment >> UpdateAttachment MagnifierType=",MagnifierType," self.ItemID=",self.ItemID)
    self.Text_ScaleMutiplay:SetVisibility(MagnifierType and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed )
    if MagnifierType then
        --显示倍镜倍率文本
        self.Text_ScaleMutiplay:SetText(MagnifierType.Multiple)
    end

    local MainWeaponTag = self.WeaponInstance:GetMainWeaponTag()
    self:UpdateTypeBackground(MainWeaponTag)
   -- 更新锁定状态
   local CurrentAttachmentObject = UE.UGAWAttachmentFunctionLibrary.GetAttachmentInstance(self.WeaponInstance, self.AttachmentEffectInstanceID)
   if CurrentAttachmentObject then

       local CanDetachFromWeapon = CurrentAttachmentObject:IsDetachable(MainWeaponTag)
       if CanDetachFromWeapon then
        self.CanDetachFlag = true
        self.Image_Content:SetColorAndOpacity(self.BgImageBeUsedOpacity)
       else
        local CantDetachColor = self.CantDetachColorMap:Find(CurrentItemLevel)
        self.CanDetachFlag = false
        self.Image_Content:SetColorAndOpacity(CantDetachColor)
       end
   end
    -- 等级颜色
    if IsFindItemLevel then
        self:UpdateBackGroundImage(CurrentItemLevel,self.CanDetachFlag)
    end

    local UIManager = UE.UGUIManager.GetUIManager(self)
    if UIManager:IsAnyDynamicWidgetShowByKey("UMG_Bag") then
        self:VXE_HUD_Bag_Attach() 
    end

    if self.HandleSelect then
        local TempInteractionKeyName = ""
        MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo, {
            HoverWidget = self,
            ParentWidget = nil,
            IsShowAtLeftSide = true,
            ItemID = self.ItemID,
            ItemInstanceID = self.ItemInstanceID,
            ItemNum = 1,
            InteractionKeyName = TempInteractionKeyName,
            ShowSourceType = ItemSystemHelper.ItemDetialInfoShowMsgSourceType.BagSystem
        })
    end
end

-- move to C++
-- function ItemSlotWeaponAttachment:UpdateNewAttachment(PlayerController, GAWeaponInstance, InGAWAttachmentEffect)
--     self:SetAttachmentInfo(GAWeaponInstance, InGAWAttachmentEffect)
--     self:UpdateAttachment()
--     self:SetColor_ContentAndType(true)
-- end


function ItemSlotWeaponAttachment:SetHighLightVisibility(VisibilityState)
    if VisibilityState then
        self.Image_Hover:SetVisibility(UE.ESlateVisibility.Visible)
        self.GUIImage_LightMask:SetVisibility(UE.ESlateVisibility.Visible)
    else
        self.Image_Hover:SetVisibility(UE.ESlateVisibility.Hidden)
        self.GUIImage_LightMask:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

--move to C++
-- Empty Slot Color
function ItemSlotWeaponAttachment:SetColor_ContentAndType(IsEmpty)
    if IsEmpty and IsEmpty == true then
        self.Image_AttachmentType:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Image_Content:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self:UpdateBackGroundImage(0,false)

        self.Image_AttachmentType:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Image_Content:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end



function ItemSlotWeaponAttachment:OnMouseEnter(MyGeometry, MouseEvent)
    if self.bMobilePlatform then
        return
    end
    self.HandleSelect = true
    if self.ItemID ~= -1 then
        self.Image_Hover:SetVisibility(UE.ESlateVisibility.Visible) -- 高亮
        self.GUIImage_LightMask:SetVisibility(UE.ESlateVisibility.Visible)

        local TempInteractionKeyName = ""
        -- 锁定 则不能 卸下
        if not self.CanDetachFlag then
            TempInteractionKeyName = "Bag.Attachment.CanNotDetach"
        else
            TempInteractionKeyName = "Bag.Attachment.JustDetach"
        end

        MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo, {
            HoverWidget = self,
            ParentWidget = nil,
            IsShowAtLeftSide = true,
            ItemID = self.ItemID,
            ItemInstanceID = self.ItemInstanceID,
            ItemNum = 1,
            InteractionKeyName = TempInteractionKeyName,
            ShowSourceType = ItemSystemHelper.ItemDetialInfoShowMsgSourceType.BagSystem
        })
    end
end


function ItemSlotWeaponAttachment:OnMouseLeave(MouseEvent)
    if self.bMobilePlatform then
        return
    end
    self.HandleSelect = false
    self.IsHoldLeftMouseButton = false
    self.IsHoldRightMouseButton = false
    self.Image_Hover:SetVisibility(UE.ESlateVisibility.Hidden) -- 取消高亮
    self.GUIImage_LightMask:SetVisibility(UE.ESlateVisibility.Collapsed)
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end


function ItemSlotWeaponAttachment:OnDragEnter(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDragEnter:Broadcast(MyGeometry, PointerEvent, Operation)
end


function ItemSlotWeaponAttachment:OnDragLeave(PointerEvent, Operation)
    self.Delegate_TransportOnDragLeave:Broadcast(PointerEvent, Operation)
end


function ItemSlotWeaponAttachment:OnDrop(MyGeometry, PointerEvent, Operation)
    self.Delegate_TransportOnDrop:Broadcast(MyGeometry, PointerEvent, Operation)
    return true
end


function ItemSlotWeaponAttachment:IsValidAttachmentUI()
    return self.ItemID ~= -1 and self.AttachmentEffectInstanceID ~= -1
end


function ItemSlotWeaponAttachment:OnMouseButtonDown(MyGeometry, MouseEvent)
    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if not MouseKey then
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton then
        -- 左键拖拽
        -- 锁定 则不能 拖拽
        if not self.CanDetachFlag then
            return UE.UWidgetBlueprintLibrary.Handled()
        end

        if not self.IsHoldRightMouseButton then
            self.IsHoldLeftMouseButton = true
            if self:IsValidAttachmentUI() then
                return UE.UWidgetBlueprintLibrary.DetectDragIfPressed(MouseEvent,self,MouseKey)
            end
        end
    elseif MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton then
        -- 右键卸下

        if not self.IsHoldLeftMouseButton then
            self.IsHoldRightMouseButton = true
        end
    elseif MouseKey.KeyName == GameDefine.NInputKey.MiddleMouseButton then
        -- 中键标记
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)

        if PlayerController then
            local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(self)
            if BattleChatComp then
                local SlotName = ""
                if self.AttachmentSlotName then
                    SlotName = self.AttachmentSlotName.TagName
                end
                local TextStr = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, SlotName)

                if self:IsValidAttachmentUI() then
                    AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithItemId(self, self.ItemID)
                    print("ItemSlotWeaponAttachment:OnMouseButtonDown SendMsg Own ItemSlotWeaponAttachment !")
                else
                    AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemType(self,self.DefaultType)
                    print("ItemSlotWeaponAttachment:OnMouseButtonDown SendMsg Need ItemSlotWeaponAttachment !")
                end
            end
        end
    end

    return UE.UWidgetBlueprintLibrary.Handled()
end

-- 鼠标按键抬起
function ItemSlotWeaponAttachment:OnMouseButtonUp(MyGeometry, MouseEvent)
    if self.bMobilePlatform then
        if self.ItemID ~= -1 then
            MsgHelper:Send(self, GameDefine.Msg.PLAYER_ShowItemDetailInfo, {
                HoverWidget = self,
                ParentWidget = self.ParentWidget,
                IsShowAtLeftSide = true,
                ItemID=self.ItemID,
                ItemInstanceID = self.ItemInstanceID,
                ItemNum = 1,
                IsShowDiscardNum = true,
                InteractionKeyName = nil,
                ShowSourceType = ItemSystemHelper.ItemDetialInfoShowMsgSourceType.BagSystem
            })
        end
    else
        local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)

        if MouseKey.KeyName == GameDefine.NInputKey.LeftMouseButton and self.IsHoldLeftMouseButton then
            self.IsHoldLeftMouseButton = false
        end

        if MouseKey.KeyName == GameDefine.NInputKey.RightMouseButton and self.IsHoldRightMouseButton then
            self:DropInBag()
        end
    end
end

function ItemSlotWeaponAttachment:OnDragDetected(MyGeometry, PointerEvent)
    local DefaultDragVisualWidget = UE.UWidgetBlueprintLibrary.Create(self, self.DefaultDragVisualClass)
    self.bDraging = true
    self:StartAttachmentGuide()
    DefaultDragVisualWidget:SetDragInfo(self.ItemID, self.ItemInstanceID, 1, GameDefine.InstanceIDType.ItemInstance)
    DefaultDragVisualWidget:SetDragSource(GameDefine.DragActionSource.EquipZoom, self)
    local DragDropObject = UE.UWidgetBlueprintLibrary.CreateDragDropOperation(self.DragDropOperationClass)
    DragDropObject.DefaultDragVisual = DefaultDragVisualWidget
    if self.SizeBox_Active then self:VXE_HUD_Bag_Attach_Floating_In() end
    return DragDropObject
end

function ItemSlotWeaponAttachment:OnDragComplete()
    print("ItemSlotWeaponAttachment:OnDragComplete")
    self.bDraging = false
    self:EndAttachmentGuide()
end

function ItemSlotWeaponAttachment:DropInBag()
    self.IsHoldRightMouseButton = false

    -- 锁定 则不能 卸下
    if not self.CanDetachFlag then
        local CurrentAttachmentObject = UE.UGAWAttachmentFunctionLibrary.GetAttachmentInstance(self.WeaponInstance, self.AttachmentEffectInstanceID)
        if CurrentAttachmentObject then
            UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId(CurrentAttachmentObject.CanNotDetachMsg, -1, UE.FGenericBlackboardContainer(), nil)
        end
        return
    end

    if self:IsValidAttachmentUI() then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        local BagComponent = UE.UBagComponent.Get(PlayerController)
        local TempInventoryIdentity = UE.FInventoryIdentity()
        TempInventoryIdentity.ItemID = self.ItemID
        TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID
        local TempWAttachmentObject = BagComponent:GetInventoryInstance(TempInventoryIdentity)
        if TempWAttachmentObject then
            UE.UItemStatics.UseItem(PlayerController, TempInventoryIdentity, ItemAttachmentHelper.NUsefulReason.UnEquipFromWeapon)
        end
    end
end
-- move to C++
-- function ItemSlotWeaponAttachment:SetParentWeaponSlotID(SlotID)
--     self.ParentWeaponSlotID = SlotID
-- end
-- move to C++
-- function ItemSlotWeaponAttachment:GetParentWeaponSlotID()
--     return self.ParentWeaponSlotID
-- end

function ItemSlotWeaponAttachment:OnFocusReceived(MyGeometry,InFocusEvent)
    -- local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
    -- if IsInCursorMode then
    --     return
    -- end
    print("(Wzp)ItemSlotWeaponAttachment:OnFocusReceived")
    self.HandleSelect = true
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function ItemSlotWeaponAttachment:OnFocusLost(InFocusEvent)
    -- local IsInCursorMode = UE.UGamepadUMGFunctionLibrary.IsInCursorMode(self)
    -- if IsInCursorMode then
    --     return
    -- end
    print("(Wzp)ItemSlotWeaponAttachment:OnFocusLost")
    self.HandleSelect = false
    self.HanldSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function ItemSlotWeaponAttachment:OnInventoryItemDragOnDrop(InMsgBody)
    if self.SizeBox_Active and self.SizeBox_Active:GetRenderOpacity() ~= 1 then
        self:VXE_HUD_Bag_Attach_Floating_Out()
    end
end

function ItemSlotWeaponAttachment:StartGuideHightLight(bIsWeaponInHand)
    self.bStartGuide = true
    self.VXV_Attach_Focus = bIsWeaponInHand
    self:PlayStartGuideVXE()
    --self.HanldSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function ItemSlotWeaponAttachment:EndGuideHightLight()
    self.bStartGuide = false
    self:PlayStartGuideVXE()
    --self.HanldSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function ItemSlotWeaponAttachment:PlayStartGuideVXE()
    if self.bStartGuide then
        self:VXE_HUD_Bag_Attach_Dragon_In()
        if self.VXV_Attach_Focus then 
            self:VXE_HUD_Bag_Attach_Focus_In()
        else
            self:VXE_HUD_Bag_Attach_Focus_Out()
        end
    else
        self:VXE_HUD_Bag_Attach_Dragon_Out()
        self:VXE_HUD_Bag_Attach_Focus_Out()
    end
end


function ItemSlotWeaponAttachment:OnUseItem()
    self:SwapAttachment()
end

-- function ItemSlotWeaponAttachment:OnKeyDown(MyGeometry,InKeyEvent)  
-- 	local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
--     if PressKey == UE.FName("Gamepad_FaceButton_Bottom") then      

--         if not self.HandleSelect then
--             return UE.UWidgetBlueprintLibrary.Handled()
--         end

--         self:SwapAttachment()

--         --return UE.UWidgetBlueprintLibrary.Unhandled()
--     end

--     return UE.UWidgetBlueprintLibrary.Handled()
-- end

function ItemSlotWeaponAttachment:SwapAttachment()
    if not self.HandleSelect then
        return
    end

    if self.ItemID == -1 or self.ItemInstanceID == -1  then
        return
    end


    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    local TempBagComponent = UE.UBagComponent.Get(PlayerController)

    local AttachmentInventoryIdentity = UE.FInventoryIdentity()
    AttachmentInventoryIdentity.ItemID = self.ItemID
    AttachmentInventoryIdentity.ItemInstanceID = self.ItemInstanceID
    local CurrentWAttachmentInventoryInstance = TempBagComponent:GetInventoryInstance(AttachmentInventoryIdentity)
    if not CurrentWAttachmentInventoryInstance then return end

    local OldWeaponInstance = CurrentWAttachmentInventoryInstance:GetCurrentAttachedWInstance()
    if OldWeaponInstance then
        local OldEffectObject = UE.UGAWAttachmentFunctionLibrary.GetAttachmentInstance(OldWeaponInstance,
        CurrentWAttachmentInventoryInstance.AttachmentHandleID)

        local WeaponInventoryIdentity = OldWeaponInstance:GetInventoryIdentity()
        local WeaponInventoryIdentityObj = TempBagComponent:GetItemSlot(WeaponInventoryIdentity)
        if WeaponInventoryIdentityObj ~= 0 then

            local AttachmentEffectArray = UE.UGAWAttachmentFunctionLibrary.GetAllAttachmentEffectHandleInSlot(OldWeaponInstance,
                OldEffectObject.SlotName)
            local CurrentWeaponAttachmentCountInSlot = AttachmentEffectArray:Length()
            local IsExistAttachment = CurrentWeaponAttachmentCountInSlot > 0


            local WeaponSlotID = WeaponInventoryIdentityObj.SlotID
            local InReason = nil
            if (WeaponSlotID == 2) then
                if IsExistAttachment then
                    InReason = ItemAttachmentHelper.NUsefulReason.EquippedSwapWeapon_1
                else
                    InReason = ItemAttachmentHelper.NUsefulReason.AttachWeapon1
                end
            elseif (WeaponSlotID == 1) then
                if IsExistAttachment then
                    InReason = ItemAttachmentHelper.NUsefulReason.EquippedSwapWeapon_2
                else
                    InReason = ItemAttachmentHelper.NUsefulReason.AttachWeapon2
                end
            end

            if InReason then
                CurrentWAttachmentInventoryInstance:RequestUseItem(InReason)
            end
        end
    end

end


function ItemSlotWeaponAttachment:OnKeyDown(MyGeometry,InKeyEvent)  
	local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey == UE.FName("Gamepad_FaceButton_Bottom") then      

        if not self.HandleSelect then
            return UE.UWidgetBlueprintLibrary.Handled()
        end

        self:SwapAttachment()

        return UE.UWidgetBlueprintLibrary.Handled()
    end
    return UE.UWidgetBlueprintLibrary.Unhandled()
end

function ItemSlotWeaponAttachment:SetGuideVXEStyle(bFocusInWeapon)
    self.VXV_Attach_Focus = bFocusInWeapon
    if bFocusInWeapon and self.bStartGuide then
        self:VXE_HUD_Bag_Attach_Focus_In()
    elseif not bFocusInWeapon and self.bStartGuide then
        self:VXE_HUD_Bag_Attach_Focus_Out()
    end
end


function ItemSlotWeaponAttachment:StartAttachmentGuide()
    local InventoryIdentity = UE.FInventoryIdentity()
    InventoryIdentity.ItemID = self.ItemID
    InventoryIdentity.ItemInstanceID = self.ItemInstanceID
    self.StartAttachmentGuideEvent:Broadcast(InventoryIdentity)
end

function ItemSlotWeaponAttachment:EndAttachmentGuide()
    self.EndAttachmentGuideEvent:Broadcast()
end

return ItemSlotWeaponAttachment