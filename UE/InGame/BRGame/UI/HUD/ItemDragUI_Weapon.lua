require "UnLua"

local ItemDragUI_Weapon = Class()


function ItemDragUI_Weapon:Construct()
    self.ItemID = self.ItemID and self.ItemID or 0
    self.InstanceID = self.InstanceID and self.InstanceID or 0
    self.ItemNum = self.ItemNum and self.ItemNum or 0
    self.LevelNumber = self.LevelNumber and self.LevelNumber or 0
    self.WeaponSlotIndex = self.WeaponSlotIndex and self.WeaponSlotIndex or 0
    self.CurWeaponName = self.CurWeaponName and self.CurWeaponName or ""
    self.DragToItemID = self.DragToItemID and self.DragToItemID or 0
    self.DragToItemInstanceID = self.DragToItemInstanceID and self.DragToItemInstanceID or 0

    self.bFinsihDragDrop = false
    self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.BAG_WhenShowHideBag,    Func = self.CloseBagPanel,  bCppMsg = true }
    }

    self:HideDragDropPurpose()

    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Drag_01")

    self:InitSetDragInfo()

    -- 注册消息监听
    if self.MsgList then
	    MsgHelper:RegisterList(self, self.MsgList)
    end
end


function ItemDragUI_Weapon:Destruct()
    if self.DragSourceWidget ~= nil and not self.bFinsihDragDrop then
        MsgHelper:Send(nil, GameDefine.Msg.WEAPON_WeaponSlotDragOnDrop, {WeaponItemID = self.ItemID})
    end

    self.ItemID = nil
    self.InstanceID = nil
    self.ItemNum = nil
    self.LevelNumber = nil
    self.DragDropAction = nil
    self.DragSourceFlag = nil
    self.InstanceIDType = nil
    self.DragSourceWidget = nil
    self.PickupObj = nil
    self.DragToItemID = nil
    self.DragToItemInstanceID = nil


    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Release_01")

    -- 注销消息监听
	if self.MsgList then
		MsgHelper:UnregisterList(self, self.MsgList)
		self.MsgList = nil
	end
end


function ItemDragUI_Weapon:CloseBagPanel(IsVisible)
    if (not IsVisible) then
        UE.UWidgetBlueprintLibrary.CancelDragDrop()
    end
end

function ItemDragUI_Weapon:SetPickupObjInfo(InPickupObj)
    self.PickupObj = InPickupObj
end

-- 设置拖拽信息
function ItemDragUI_Weapon:SetDragInfo(ItemID, ItemInstanceID, ItemNum, InstanceIDType, InWeaponSlotIndex, InCurWeaponName, InWeaponInstance)
    self.ItemID = ItemID
    self.InstanceID = ItemInstanceID
    self.ItemNum = ItemNum
    self.InstanceIDType = InstanceIDType
    self.WeaponSlotIndex = InWeaponSlotIndex
    self.CurWeaponName = InCurWeaponName
    self.WeaponInstance = InWeaponInstance
end

function ItemDragUI_Weapon:InitSetDragInfo()
    if not self.ItemID then
        return
    end

    -- set Level color
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local CurrentItemLevel, IsFindItemLevel = UE.UItemSystemManager.GetItemDataUInt8(TempLocalPC, self.ItemID, "ItemLevel","Ingame","ItemDragUI_Weapon:SetDragInfo")
    if IsFindItemLevel then
        self:SetItemLevel(CurrentItemLevel)
    end

    -- set Icon
    local ImageSoftObjectPtr = self:GetDragWeaponSkinImage(self.WeaponInstance)
    if ImageSoftObjectPtr then
        self.Image_Content:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
    end

    -- set text
    self.GUIText_WeaponSlotIndex:SetText(tostring(self.WeaponSlotIndex))
    self.GUIText_WeaponName:SetText(tostring(self.CurWeaponName))
end

function ItemDragUI_Weapon:GetDragWeaponSkinImage(InWeaponInstance)
    if not InWeaponInstance then
        return nil
    end

    local TempAvatarManagerSubsystem = UE.UAvatarManagerSubsystem.Get(self)
    if not TempAvatarManagerSubsystem then
        return nil
    end

    local TempTargetSlot = UE.FGameplayTag()
    TempTargetSlot.TagName = GameDefine.NTag.WEAPON_SKIN_ATTACHSLOT_GUNBODY
    local TempWeaponSkinId = TempAvatarManagerSubsystem:GetWeaponCurrentAvatarID(InWeaponInstance, TempTargetSlot)

    local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, TempWeaponSkinId)
    if not WeaponSkinCfg then
        return nil
    end

    local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(WeaponSkinCfg.WeaponSlotImage)
    return ImageSoftObjectPtr
end


-- 获得拖拽信息
function ItemDragUI_Weapon:GetDragInfo()
    return self.ItemID, self.InstanceID, self.ItemNum, self.InstanceIDType
end

function ItemDragUI_Weapon:SetDragVisibility(InVisableBool)
    if InVisableBool then
        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

function ItemDragUI_Weapon:SetDragToHoverItemInfo(ItemID, ItemInstanceID)
    self.DragToItemID = ItemID
    self.DragToItemInstanceID = ItemInstanceID
end

function ItemDragUI_Weapon:GetDragToHoverItemInfo()
    return self.DragToItemID, self.DragToItemInstanceID
end

-- 更新拖拽UI边框和左上角图标的颜色
function ItemDragUI_Weapon:UpdateBorderColor(InDragDropAction)
    print("ItemDragUI_Weapon:UpdateBorderColor-->InDragDropAction:", InDragDropAction)
    local BorderColor = self.ImageBorderColour:Find(InDragDropAction)
    if BorderColor then
        print("ItemDragUI_Weapon:UpdateBorderColor-->BorderColor:", BorderColor)
        self.Image_Border:SetColorAndOpacity(BorderColor)
    end



end

-- 显示“行动目的”角标
function ItemDragUI_Weapon:ShowDragDropPurpose(DragDropAction)
    if self.DragDropAction == DragDropAction then return end
    self.DragDropAction = DragDropAction
    self:UpdateBorderColor(DragDropAction)
end

-- 隐藏“行动目的”角标
function ItemDragUI_Weapon:HideDragDropPurpose()

end

function ItemDragUI_Weapon:GetDropPurpose()
    return self.DragDropAction
end

function ItemDragUI_Weapon:SetItemLevel(LevelNumber)
    print("ItemDragUI_Weapon:SetItemLevel-->LevelNumber:", LevelNumber)
    if self.LevelNumber ~= LevelNumber then
        self.LevelNumber = LevelNumber

        --[[
        -- Border Color
        local BorderColor = self.BorderColorItemLevels:Find(self.LevelNumber)
        if BorderColor then
            print("ItemDragUI_Weapon:SetItemLevel-->BorderColor:", BorderColor)
            self.Image_Border:SetColorAndOpacity(BorderColor)
        end
        ]]

        -- -- Background Color
        -- local BackgroundColor = self.BackgroundColorItemLevels:Find(self.LevelNumber)
        -- if BackgroundColor then
        --     self.Image_Background:SetColorAndOpacity(BackgroundColor)
        -- end
    end
end

-- Set 拖拽 源 信息
function ItemDragUI_Weapon:SetDragSource(SourceFlag, SourceWidget)
    self.DragSourceFlag = SourceFlag
    self.DragSourceWidget = SourceWidget
end

-- Get 拖拽 源 信息
function ItemDragUI_Weapon:GetDragSource()
    return self.DragSourceFlag,self.DragSourceWidget
end

-- Set 拖拽 终点 信息
function ItemDragUI_Weapon:SetDropEnd(EndFlag, EndWidget)
    self.DropEndFlag = EndFlag
    self.DropEndWidget = EndWidget
end

-- Get 拖拽 终点 信息
function ItemDragUI_Weapon:GetDropEnd()
    return self.DropEndFlag, self.DropEndWidget
end

function ItemDragUI_Weapon:BagItemDropProcess()
    if not self.DragDropAction then return end
    if self.DragDropAction == GameDefine.DropAction.PURPOSE_Equip then
        
    elseif self.DragDropAction == GameDefine.DropAction.PURPOSE_Discard then

    end
end

function ItemDragUI_Weapon:AttachmentDropProcess()

end

function ItemDragUI_Weapon:UnEquipToBag()
    
end





-- 完成拖拽操作的OnDrop回调
function ItemDragUI_Weapon:OnDropCallBack()
    print("ItemDragUI_Weapon:OnDropCallBack-->DragSourceWidget:", self.DragSourceWidget, "obj name:", GetObjectName(self.DragSourceWidget))
    if self.DragSourceWidget ~= nil and not self.bFinsihDragDrop then
        print("ItemDragUI_Weapon:OnDropCallBack-->self.ItemID:", self.ItemID)
        self.bFinsihDragDrop = true
        MsgHelper:Send(nil, GameDefine.Msg.WEAPON_WeaponSlotDragOnDrop, {WeaponItemID = self.ItemID})
    end
end

return ItemDragUI_Weapon


