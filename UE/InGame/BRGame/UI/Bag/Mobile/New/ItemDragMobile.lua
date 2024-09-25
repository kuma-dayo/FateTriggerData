
local ItemDragMobile = Class("Common.Framework.UserWidget")

function ItemDragMobile:OnInit()
    --数据在设置后 才执行init
    self.ItemID = self.ItemID and self.ItemID or 0
    self.InstanceID = self.InstanceID and self.InstanceID or 0
    self.ItemNum = self.ItemNum and self.ItemNum or 0
    self.LevelNumber = self.LevelNumber and self.LevelNumber or 0

    self:InitUI()
    self:InitGameEvent()
    self:InitUIEvent()

    self:ShowWidget()

    UserWidget.OnInit(self)
end

function ItemDragMobile:OnDestroy()
    self:InitData()
    
    if self.MsgList then
		MsgHelper:UnregisterList(self, self.MsgList)
		self.MsgList = nil
	end
    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Release_01")

    UserWidget.OnDestroy(self)
end

--   ___ _   _ ___ _____ 
--  |_ _| \ | |_ _|_   _|
--   | ||  \| || |  | |  
--   | || |\  || |  | |  
--  |___|_| \_|___| |_|  

function ItemDragMobile:InitUI()

    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_Bag_Drag_01")
    self:HideDragDropPurpose()
end

function ItemDragMobile:InitData()
    print("BagM@ItemDragMobile:InitData")

    self.ItemID = nil
    self.InstanceID = nil
    self.ItemNum = nil
    self.InstanceIDType = nil

    self.DragDropAction = nil
    self.DragSourceFlag = nil
    self.DragSourceWidget = nil
end

function ItemDragMobile:InitGameEvent()
    -- 注册消息监听
    self.MsgList = { 
        { MsgName = GameDefine.MsgCpp.BAG_WhenShowHideBag,      Func = self.OnCloseBagPanel,     bCppMsg = true }
    }
end

function ItemDragMobile:InitUIEvent()

end

--   ____    _  _____  _       ____ ___  _   _ _____ ____   ___  _     
--  |  _ \  / \|_   _|/ \     / ___/ _ \| \ | |_   _|  _ \ / _ \| |    
--  | | | |/ _ \ | | / _ \   | |  | | | |  \| | | | | |_) | | | | |    
--  | |_| / ___ \| |/ ___ \  | |__| |_| | |\  | | | |  _ <| |_| | |___ 
--  |____/_/   \_\_/_/   \_\  \____\___/|_| \_| |_| |_| \_\\___/|_____|
                                                                    
function ItemDragMobile:SetDragItemData(ItemID, InstanceID, ItemNum, InstanceIDType)
    print("BagM@ItemDragMobile:SetDragItemData", ItemID, InstanceID, ItemNum, InstanceIDType)

    self.ItemID = ItemID
    self.InstanceID = InstanceID
    self.ItemNum = ItemNum
    self.InstanceIDType = InstanceIDType
end

function ItemDragMobile:GetDragItemData()
    return self.ItemID, self.InstanceID, self.ItemNum, self.InstanceIDType
end

function ItemDragMobile:SetDragSource(SourceFlag, SourceWidget)
    self.DragSourceFlag = SourceFlag
    self.DragSourceWidget = SourceWidget
end

function ItemDragMobile:GetDragSource()
    return self.DragSourceFlag, self.DragSourceWidget
end

function ItemDragMobile:GetDropPurpose()
    return self.DragDropAction
end

--   _   _ ___   ____  _____ _____ ____  _____ ____  _   _ 
--  | | | |_ _| |  _ \| ____|  ___|  _ \| ____/ ___|| | | |
--  | | | || |  | |_) |  _| | |_  | |_) |  _| \___ \| |_| |
--  | |_| || |  |  _ <| |___|  _| |  _ <| |___ ___) |  _  |
--   \___/|___| |_| \_\_____|_|   |_| \_\_____|____/|_| |_|

function ItemDragMobile:ShowWidget()
    if not self.ItemID then
        return
    end

    self:RefreshItemIcon(self.ItemID)
end

function ItemDragMobile:RefreshItemIcon(ItemID)
    if not ItemID then
        return
    end
    local CurrentItemIconPath, IsFindIcon = UE.UItemSystemManager.GetItemDataFString(self, ItemID, "SlotImage", GameDefine.NItemSubTable.Ingame, "ItemDragMobile:RefreshItemIcon")
    if IsFindIcon then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurrentItemIconPath)
        self.Image_Icon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
    end
end

function ItemDragMobile:ShowDragDropPurpose(DragDropAction)
    if DragDropAction == GameDefine.DropAction.PURPOSE_Discard then
        self.WS_DragBehavior:SetActiveWidgetIndex(0)
    end
    if DragDropAction == GameDefine.DropAction.PURPOSE_Equip then
        self.WS_DragBehavior:SetActiveWidgetIndex(1)
    end

    self.WS_DragBehavior:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.DragDropAction = DragDropAction
end

function ItemDragMobile:HideDragDropPurpose()
    self.WS_DragBehavior:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function ItemDragMobile:SetDragVisibility(InVisableBool)
    if InVisableBool then
        self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

-- Set 拖拽 终点 信息
function ItemDragMobile:SetDropEnd(EndFlag, EndWidget)
    self.DropEndFlag = EndFlag
    self.DropEndWidget = EndWidget
end

-- Get 拖拽 终点 信息
function ItemDragMobile:GetDropEnd()
    return self.DropEndFlag, self.DropEndWidget
end
--   _   _ ___   _______     _______ _   _ _____ 
--  | | | |_ _| | ____\ \   / / ____| \ | |_   _|
--  | | | || |  |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| || |  | |___  \ V / | |___| |\  | | |  
--   \___/|___| |_____|  \_/  |_____|_| \_| |_|  
function ItemDragMobile:OnDropCallBack(PointerEvent)
    print("ItemDragMobile:OnDropCallBack:", self.DragSourceWidget, "obj name:", GetObjectName(self.DragSourceWidget))
end

--    ____    _    __  __ _____   _______     _______ _   _ _____ 
--   / ___|  / \  |  \/  | ____| | ____\ \   / / ____| \ | |_   _|
--  | |  _  / _ \ | |\/| |  _|   |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| |/ ___ \| |  | | |___  | |___  \ V / | |___| |\  | | |  
--   \____/_/   \_\_|  |_|_____| |_____|  \_/  |_____|_| \_| |_| 
function ItemDragMobile:OnCloseBagPanel(IsVisible)
    if not IsVisible then
        UE.UWidgetBlueprintLibrary.CancelDragDrop()
    end
end


return ItemDragMobile