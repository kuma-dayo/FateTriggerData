require "UnLua"

local ItemDragUI_Normal = Class()


function ItemDragUI_Normal:Construct()
    self.ItemID = self.ItemID and self.ItemID or 0
    self.InstanceID = self.InstanceID and self.InstanceID or 0
    self.ItemNum = self.ItemNum and self.ItemNum or 0
    self.LevelNumber = self.LevelNumber and self.LevelNumber or 0
    self.DragToItemID = self.DragToItemID and self.DragToItemID or 0
    self.DragToItemInstanceID = self.DragToItemInstanceID and self.DragToItemInstanceID or 0

    self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.BAG_WhenShowHideBag,      Func = self.CloseBagPanel,     bCppMsg = true },
        { MsgName ="UIEvent.QuickPick.Close",      Func = self.CloseQuickPickUIPanel,     bCppMsg = false }
    }
    
    self:HideDragDropPurpose()

    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Drag_01")

    self:InitSetDragInfo()
    
    -- 注册消息监听
    if self.MsgList then
	    MsgHelper:RegisterList(self, self.MsgList)
    end
end

function ItemDragUI_Normal:Destruct()
    if self.DragSourceWidget ~= nil and not self.bFinishDragDrop then
        MsgHelper:Send(nil, GameDefine.Msg.InventoryItemSlotDragOnDrop, {DragItemID = self.ItemID})
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


function ItemDragUI_Normal:CloseBagPanel(IsVisible)
    if (not IsVisible) then
        UE.UWidgetBlueprintLibrary.CancelDragDrop()
    end
end

function ItemDragUI_Normal:CloseQuickPickUIPanel()
    UE.UWidgetBlueprintLibrary.CancelDragDrop()
end

function ItemDragUI_Normal:SetPickupObjInfo(InPickupObjArray)
    self.PickupObjArray = InPickupObjArray
end

function ItemDragUI_Normal:GetPickupObjInfo()
    return self.PickupObjArray
end

-- 设置拖拽信息
function ItemDragUI_Normal:SetDragInfo(ItemID, ItemInstanceID, ItemNum, InstanceIDType)
    self.ItemID = ItemID
    self.InstanceID = ItemInstanceID
    self.ItemNum = ItemNum
    self.InstanceIDType = InstanceIDType
end

function ItemDragUI_Normal:SetDragToHoverItemInfo(ItemID, ItemInstanceID)
    self.DragToItemID = ItemID
    self.DragToItemInstanceID = ItemInstanceID
end

function ItemDragUI_Normal:GetDragToHoverItemInfo()
    return self.DragToItemID, self.DragToItemInstanceID
end

function ItemDragUI_Normal:InitSetDragInfo()
    if not self.ItemID then
        return
    end

    -- ItemLevel convert to color
    local CurrentItemLevel, IsFindItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, self.ItemID, "ItemLevel", GameDefine.NItemSubTable.Ingame, "ItemDragUI_Normal:SetDragInfo")
    if IsFindItemLevel then
        self:SetItemLevel(CurrentItemLevel)
    end

    -- Icon
    local CurrentItemIconPath, IsFindIcon = UE.UItemSystemManager.GetItemDataFString(self, self.ItemID, "ItemIcon", GameDefine.NItemSubTable.Ingame, "ItemDragUI_Normal:SetDragInfo")
    if IsFindIcon then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurrentItemIconPath)
        self.Image_Content:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
    end

    -- 倍镜特殊处理
    local MiscSystemIns = UE.UMiscSystem.GetMiscSystem(self)
    local MagnifierType = MiscSystemIns.MagnifierTypeMap:Find(self.ItemID)
    print("[Wzp]ItemDragUI_Normal >> SetDragInfo MagnifierType=",MagnifierType," self.ItemID=",self.ItemID)
    self.Text_ScaleMutiplay:SetVisibility(MagnifierType and UE.ESlateVisibility.SelfHitTestInvisible or
                                            UE.ESlateVisibility.Collapsed)
    if MagnifierType then
        -- 显示倍镜倍率文本
        self.Text_ScaleMutiplay:SetText(MagnifierType.Multiple)
    end

end

-- 获得拖拽信息
function ItemDragUI_Normal:GetDragInfo()
    return self.ItemID, self.InstanceID, self.ItemNum, self.InstanceIDType
end

function ItemDragUI_Normal:SetDragVisibility(InVisableBool)
    if InVisableBool then
        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

-- 更新拖拽UI边框和左上角图标的颜色
function ItemDragUI_Normal:UpdateBorderColor(InDragDropAction)
    local BorderColor = self.ImageBorderColor:Find(InDragDropAction)
    local BorderLeftTopColor = self.ImageBorderLeftTopColor:Find(InDragDropAction)
    local Image_LeftTopTex = self.ImageLeftTopBorderTexMap:Find(InDragDropAction)

    if BorderColor then
        self.T_Image_Border:SetColorAndOpacity(BorderColor)
        -- self.T_Hover_Border_1:GetDynamicMaterial():SetVectorParameterValue("HoverColor", BorderColor)
    end

    if BorderLeftTopColor then
        self.Image_LeftTop:SetColorAndOpacity(BorderLeftTopColor)

    end
    if Image_LeftTopTex then
        self.Image_LeftTop_Border:SetBrushFromTexture(Image_LeftTopTex,true)
    end

    print("ItemDragUI_Normal >> UpdateBorderColor InDragDropAction=",InDragDropAction)
end

-- 显示“行动目的”角标
function ItemDragUI_Normal:ShowDragDropPurpose(DragDropAction)
    self.Image_LeftTop:SetVisibility(UE.ESlateVisibility.Visible)
    self.Image_LeftTop_Border:SetVisibility(UE.ESlateVisibility.Visible)
    if self.DragDropAction == DragDropAction then return end
    local Texture2D_LeftTop = self.DragDropPurposeImages:Find(DragDropAction)
    if Texture2D_LeftTop then
        self.DragDropAction = DragDropAction
        print("ItemDragUI_Normal:ShowDragDropPurpose-->DragDropAction:", DragDropAction, "Texture2D_LeftTop:", Texture2D_LeftTop)
        self.Image_LeftTop:SetBrushFromTexture(Texture2D_LeftTop, true)
    end
    self:UpdateBorderColor(DragDropAction)
end

-- 隐藏“行动目的”角标
function ItemDragUI_Normal:HideDragDropPurpose()
    self.Image_LeftTop:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Image_LeftTop_Border:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function ItemDragUI_Normal:GetDropPurpose()
    return self.DragDropAction
end

function ItemDragUI_Normal:SetItemLevel(LevelNumber)
    if self.LevelNumber ~= LevelNumber then
        self.LevelNumber = LevelNumber
        
        local PickupSetting = UE.UPickupManager.GetGPSSeting(self)
        if PickupSetting then
            local BackgroundImagePath = PickupSetting.PickupBGImageMap:Find(self.LevelNumber)
            local BackgroundPic = UE.UGFUnluaHelper.SoftObjectPathToSoftObjectPtr(BackgroundImagePath)
            if BackgroundPic then            
                self.Image_Background:SetBrushFromSoftTexture(BackgroundPic, true)
            end
        end
    end
end

-- Set 拖拽 源 信息
function ItemDragUI_Normal:SetDragSource(SourceFlag, SourceWidget)
    self.DragSourceFlag = SourceFlag
    self.DragSourceWidget = SourceWidget
end

-- Get 拖拽 源 信息
function ItemDragUI_Normal:GetDragSource()
    return self.DragSourceFlag,self.DragSourceWidget
end

-- Set 拖拽 终点 信息
function ItemDragUI_Normal:SetDropEnd(EndFlag, EndWidget)
    self.DropEndFlag = EndFlag
    self.DropEndWidget = EndWidget
end

-- Get 拖拽 终点 信息
function ItemDragUI_Normal:GetDropEnd()
    return self.DropEndFlag, self.DropEndWidget
end

function ItemDragUI_Normal:BagItemDropProcess()
    if not self.DragDropAction then return end
    if self.DragDropAction == GameDefine.DropAction.PURPOSE_Equip then
        
    elseif self.DragDropAction == GameDefine.DropAction.PURPOSE_Discard then

    end
end

function ItemDragUI_Normal:AttachmentDropProcess()

end

function ItemDragUI_Normal:UnEquipToBag()
    
end

-- 完成拖拽操作的OnDrop回调
function ItemDragUI_Normal:OnDropCallBack()
    print("ItemDragUI_Normal:OnDropCallBack-->DragSourceWidget:", self.DragSourceWidget, "obj name:", GetObjectName(self.DragSourceWidget))
    if self.DragSourceWidget ~= nil and not self.bFinishDragDrop then
        self.bFinsihDragDrop = true
        MsgHelper:Send(self, GameDefine.Msg.InventoryItemSlotDragOnDrop, {DragItemID = self.ItemID})

        if self.DragSourceWidget.OnDragComplete then
            self.DragSourceWidget:OnDragComplete()
        end
    end
end

return ItemDragUI_Normal


