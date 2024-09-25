local ItemSlotCurrencyMobile = Class("Common.Framework.UserWidget")

local CURRENCY_SHOW_STATE ={
    Empty = 0,
    Normal = 2,
}
local bIsOpenBag = false

function ItemSlotCurrencyMobile:OnInit()
    print("NewBagMobile@ItemSlotCurrencyMobile Init")

    self:InitData()
    self:InitUI()
    self:InitGameEvent()
    self:InitUIEvent()

    UserWidget.OnInit(self)
end

function ItemSlotCurrencyMobile:OnShow(InContext, InGenericBlackboard)
    -- 动态更新消息
    self.CustomListenList = { {
        MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnStackNum_Change_Currency,
        Func = self.OnCurrencyStackNumChange,
        bCppMsg = true
    } }
    MsgHelper:RegisterList(self, self.CustomListenList)

    self:ShowWidget()
    bIsOpenBag = true
    self.Overridden.OnShow(self, InContext, InGenericBlackboard)
end

function ItemSlotCurrencyMobile:OnClose()
    if self.CustomListenList then
        MsgHelper:UnregisterList(self, self.CustomListenList)
    end
    bIsOpenBag = false
end

function ItemSlotCurrencyMobile:OnDestroy()
    --每次打开绑定一次物品更新消息
    if self.InitListenList then
        MsgHelper:UnregisterList(self, self.InitListenList)
    end 
    UserWidget.OnDestroy(self)
end

--   ___ _   _ ___ _____ 
--  |_ _| \ | |_ _|_   _|
--   | ||  \| || |  | |  
--   | || |\  || |  | |  
--  |___|_| \_|___| |_|  

function ItemSlotCurrencyMobile:InitUI()
    self.EmptyCurrencyColor = UE.FLinearColor(1, 1, 1, 0.3)
    self.NormalCurrencyColor = UE.FLinearColor(1, 1, 1, 1)

    self:ResetWidget()
end

function ItemSlotCurrencyMobile:InitData()
    -- 默认值
    self.ItemID = 130000006 
    self.ItemInstanceID = nil
    self.ItemNum = 0
    
    self.HandleSelect = false
    self.CurrentTouchState = GameDefine.TouchType.None
    self.DragDistance = 0
    self.DragOperationActiveMinDistance = 10.0;
    self.DragStartPosition = UE.FVector2D()
    self.DragStartPosition.X = 0
    self.DragStartPosition.Y = 0
    self.bDraging = true

    self.CurrentDragVisualWidget = nil
end

function ItemSlotCurrencyMobile:InitGameEvent()
    --初始化绑定消息
    self.InitListenList = { 
        { MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnNew_Currency, Func = self.OnNewItem , bCppMsg = true }, 
        { MsgName = GameDefine.MsgCpp.INVENTORY_ItemOnDestroy_Currency, Func = self.OnDestroyItem, bCppMsg = true },
        { MsgName = GameDefine.Msg.InventoryItemSlotDragOnDrop,             Func = self.OnInventoryItemDragOnDrop,      bCppMsg = false }
    }

    MsgHelper:RegisterList(self, self.InitListenList)
end

function ItemSlotCurrencyMobile:InitUIEvent()

end

function ItemSlotCurrencyMobile:SetInventoryIdentity(InInventoryIdentity)
    if self.ItemID == InInventoryIdentity.ItemID then
        self.ItemInstanceID = InInventoryIdentity.ItemInstanceID
    end
end

function ItemSlotCurrencyMobile:ResetInventoryIdentity()
    self.ItemInstanceID = nil
end
--   _   _ ___   ____  _____ _____ ____  _____ ____  _   _ 
--  | | | |_ _| |  _ \| ____|  ___|  _ \| ____/ ___|| | | |
--  | | | || |  | |_) |  _| | |_  | |_) |  _| \___ \| |_| |
--  | |_| || |  |  _ <| |___|  _| |  _ <| |___ ___) |  _  |
--   \___/|___| |_| \_\_____|_|   |_| \_\_____|____/|_| |_|

function ItemSlotCurrencyMobile:ShowWidget()
    if not self.ItemInstanceID then
        return
    end

    self:RefreshCurrencyNum()
    self:SetCurrencyState(CURRENCY_SHOW_STATE.Normal)
end

function ItemSlotCurrencyMobile:ResetWidget()
    self:InitData()
    
    self:RefreshCurrencyNum()
end

function ItemSlotCurrencyMobile:RefreshCurrencyIcon()
    local CurItemIcon, IsExistIcon = UE.UItemSystemManager.GetItemDataFString(self, self.ItemID, "ItemIcon",
    GameDefine.NItemSubTable.Ingame, "ItemSlotCurrencyMobile:UpdateItemInfo")
    if IsExistIcon then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurItemIcon)
        self.Image_Content:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
    end
end

function ItemSlotCurrencyMobile:RefreshCurrencyNum()
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempLocalPC == nil then
        return
    end

    local TempBagComp = UE.UBagComponent.Get(TempLocalPC)
    if TempBagComp then
        local PreItemNum = self.ItemNum
        self.ItemNum = TempBagComp:GetItemNumByItemID(self.ItemID)
        if self.ItemNum ~= PreItemNum and bIsOpenBag then 
            -- self:VXE_HUD_Bag_Attach() 
        end
        self.Text_Num:SetText(self.ItemNum)
        
        -- 初始化需要设置一次
        if self.ItemNum == 0 then
            self:SetCurrencyState(CURRENCY_SHOW_STATE.Empty)
        else
            self:SetCurrencyState(CURRENCY_SHOW_STATE.Normal)
        end
    end
end
--   _   _ ___    ____ ___  _   _ _____ ____   ___  _      
--  | | | |_ _|  / ___/ _ \| \ | |_   _|  _ \ / _ \| |     
--  | | | || |  | |  | | | |  \| | | | | |_) | | | | |     
--  | |_| || |  | |__| |_| | |\  | | | |  _ <| |_| | |___  
--   \___/|___|  \____\___/|_| \_| |_| |_| \_\\___/|_____|
function ItemSlotCurrencyMobile:SetSelectState(isSelect)
    -- self.Image_Select:SetVisibility(isSelect and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed) 
end

function ItemSlotCurrencyMobile:SetCurrencyState(NewState)
    if NewState == CURRENCY_SHOW_STATE.Empty then
        self.Image_Quality:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Image_Content:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Text_Num:SetVisibility(UE.ESlateVisibility.Collapsed)

    end

    if NewState == CURRENCY_SHOW_STATE.Normal then
        self.Image_Quality:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Image_Content:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.Text_Num:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

--   _   _ ___   _______     _______ _   _ _____ 
--  | | | |_ _| | ____\ \   / / ____| \ | |_   _|
--  | | | || |  |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| || |  | |___  \ V / | |___| |\  | | |  
--   \___/|___| |_____|  \_/  |_____|_| \_| |_|  

--    ____    _    __  __ _____   _______     _______ _   _ _____ 
--   / ___|  / \  |  \/  | ____| | ____\ \   / / ____| \ | |_   _|
--  | |  _  / _ \ | |\/| |  _|   |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| |/ ___ \| |  | | |___  | |___  \ V / | |___| |\  | | |  
--   \____/_/   \_\_|  |_|_____| |_____|  \_/  |_____|_| \_| |_| 
function ItemSlotCurrencyMobile:OnNewItem(InInventoryInstance)
    if not InInventoryInstance then
        return
    end
    local TempInventoryIdentity = InInventoryInstance:GetInventoryIdentity()
    self:SetInventoryIdentity(TempInventoryIdentity)
end

function ItemSlotCurrencyMobile:OnDestroyItem(InInventoryInstance)
    self:ResetWidget()
    self:UpdateCurrencyNumber()
end

function ItemSlotCurrencyMobile:OnInventoryItemDragOnDrop(InMsgBody)

end

function ItemSlotCurrencyMobile:OnCurrencyStackNumChange(InInventoryInstance)
    if not InInventoryInstance then
        return
    end
    self:RefreshCurrencyNum()
end

return ItemSlotCurrencyMobile