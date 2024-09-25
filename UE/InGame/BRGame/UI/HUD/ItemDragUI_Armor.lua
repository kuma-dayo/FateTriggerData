require "UnLua"

local ItemDragUI_Armor = Class()

function ItemDragUI_Armor:Construct()
    self.ItemID = self.ItemID and self.ItemID or 0
    self.InstanceID = self.InstanceID and self.InstanceID or 0
    self.ItemNum = self.ItemNum and self.ItemNum or 0
    self.LevelNumber = self.LevelNumber and self.LevelNumber or 0
    self.DragToItemID = self.DragToItemID and self.DragToItemID or 0
    self.DragToItemInstanceID = self.DragToItemInstanceID and self.DragToItemInstanceID or 0

    self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.BAG_WhenShowHideBag,      Func = self.CloseBagPanel,     bCppMsg = true }
    }

    self:HideDragDropPurpose()

    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Drag_01")

    self:InitSetDragInfo()

    -- 注册消息监听
    if self.MsgList then
	    MsgHelper:RegisterList(self, self.MsgList)
    end
end

function ItemDragUI_Armor:Destruct()
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


function ItemDragUI_Armor:CloseBagPanel(IsVisible)
    if (not IsVisible) then
        UE.UWidgetBlueprintLibrary.CancelDragDrop()
    end
end

function ItemDragUI_Armor:SetPickupObjInfo(InPickupObj)
    self.PickupObj = InPickupObj
end

-- 设置拖拽信息
function ItemDragUI_Armor:SetDragInfo(ItemID, ItemInstanceID, ItemNum, InstanceIDType)
    self.ItemID = ItemID
    self.InstanceID = ItemInstanceID
    self.ItemNum = ItemNum
    self.InstanceIDType = InstanceIDType
end

function ItemDragUI_Armor:SetDragToHoverItemInfo(ItemID, ItemInstanceID)
    self.DragToItemID = ItemID
    self.DragToItemInstanceID = ItemInstanceID
end

function ItemDragUI_Armor:GetDragToHoverItemInfo()
    return self.DragToItemID, self.DragToItemInstanceID
end

-- OnInit时调用的
function ItemDragUI_Armor:InitSetDragInfo()
    if not self.ItemID then
        return
    end

    -- ItemLevel convert to color
    local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(self)
    local SubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(self.ItemID, "Ingame")
    if not SubTable then return end
    local StrItemID = tostring(self.ItemID)
    local CurrentItemLevel, IsFindItemLevel = SubTable:BP_FindDataUInt8(StrItemID,"ItemLevel")
    if IsFindItemLevel then
        self:SetItemLevel(CurrentItemLevel)
    end

    -- Icon
    local CurrentItemIconPath, IsFindIcon = SubTable:BP_FindDataFString(StrItemID,"ItemIcon")
    if IsFindIcon then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurrentItemIconPath)
        self.Image_Content:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
    end
end

-- 获得拖拽信息
function ItemDragUI_Armor:GetDragInfo()
    return self.ItemID, self.InstanceID, self.ItemNum, self.InstanceIDType
end

function ItemDragUI_Armor:SetDragVisibility(InVisableBool)
    if InVisableBool then
        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

-- 更新拖拽UI边框和左上角图标的颜色
function ItemDragUI_Armor:UpdateBorderColor(InDragDropAction)
    print("ItemDragUI_Armor:UpdateBorderColor-->InDragDropAction:", InDragDropAction)
    local BorderColor = self.ImageBorderColour:Find(InDragDropAction)
    if BorderColor then
        print("ItemDragUI_Armor:UpdateBorderColor-->BorderColor:", BorderColor)
        self.Image_Border:SetColorAndOpacity(BorderColor)
        self.Image_LeftTop_Border:SetColorAndOpacity(BorderColor)
    end
end

-- 显示“行动目的”角标
function ItemDragUI_Armor:ShowDragDropPurpose(DragDropAction)
    self.Image_LeftTop:SetVisibility(UE.ESlateVisibility.Visible)
    self.Image_LeftTop_Border:SetVisibility(UE.ESlateVisibility.Visible)
    if self.DragDropAction == DragDropAction then return end
    local Texture2D_LeftTop = self.DragDropPurposeImages:Find(DragDropAction)
    if Texture2D_LeftTop then
        self.DragDropAction = DragDropAction
        self.Image_LeftTop:SetBrushFromTexture(Texture2D_LeftTop, true)
    end
    self:UpdateBorderColor(DragDropAction)
end

-- 隐藏“行动目的”角标
function ItemDragUI_Armor:HideDragDropPurpose()
    self.Image_LeftTop:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Image_LeftTop_Border:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function ItemDragUI_Armor:GetDropPurpose()
    return self.DragDropAction
end

function ItemDragUI_Armor:SetItemLevel(LevelNumber)
    if self.LevelNumber ~= LevelNumber then
        self.LevelNumber = LevelNumber

        --[[
        -- Border Color
        local BorderColor = self.BorderColorItemLevels:Find(self.LevelNumber)
        if BorderColor then
            self.Image_Border:SetColorAndOpacity(BorderColor)
            self.Image_LeftTop_Border:SetColorAndOpacity(BorderColor)
        end
        ]]

        -- Background Color
        local BackgroundColor = self.BackgroundColorItemLevels:Find(self.LevelNumber)
        if BackgroundColor then
            self.Image_Background:SetColorAndOpacity(BackgroundColor)
        end
    end
end

-- Set 拖拽 源 信息
function ItemDragUI_Armor:SetDragSource(SourceFlag, SourceWidget)
    self.DragSourceFlag = SourceFlag
    self.DragSourceWidget = SourceWidget
end

-- Get 拖拽 源 信息
function ItemDragUI_Armor:GetDragSource()
    return self.DragSourceFlag,self.DragSourceWidget
end

-- Set 拖拽 终点 信息
function ItemDragUI_Armor:SetDropEnd(EndFlag, EndWidget)
    self.DropEndFlag = EndFlag
    self.DropEndWidget = EndWidget
end

-- Get 拖拽 终点 信息
function ItemDragUI_Armor:GetDropEnd()
    return self.DropEndFlag, self.DropEndWidget
end

function ItemDragUI_Armor:BagItemDropProcess()
    if not self.DragDropAction then return end
    if self.DragDropAction == GameDefine.DropAction.PURPOSE_Equip then
        
    elseif self.DragDropAction == GameDefine.DropAction.PURPOSE_Discard then

    end
end

function ItemDragUI_Armor:AttachmentDropProcess()

end

function ItemDragUI_Armor:UnEquipToBag()
    
end

-- 完成拖拽操作的OnDrop回调
function ItemDragUI_Armor:OnDropCallBack()
    print("ItemDragUI_Armor:OnDropCallBack-->DragSourceWidget:", self.DragSourceWidget, "obj name:", GetObjectName(self.DragSourceWidget))
    if self.DragSourceWidget ~= nil then
        print("ItemDragUI_Armor:OnDropCallBack-->WEAPON_ArmorSlotDragOnDrop self.ItemID:", self.ItemID)
        MsgHelper:Send(nil, GameDefine.Msg.WEAPON_ArmorSlotDragOnDrop, {ArmorItemID = self.ItemID})
    end
end

return ItemDragUI_Armor


