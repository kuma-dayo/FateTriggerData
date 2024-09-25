local ItemSlotCommonItemAreaMobile = Class("Common.Framework.UserWidget")

function ItemSlotCommonItemAreaMobile:OnInit()
    print("NewBagMobile@ItemSlotCommonItemListMobile Init")

    self:InitData()
    self:InitUI()
    self:InitGameEvent()
    self:InitUIEvent()

    UserWidget.OnInit(self)
end

function ItemSlotCommonItemAreaMobile:OnShow(InContext, InGenericBlackboard)
    self.Overridden.OnShow(self, InContext, InGenericBlackboard)
    self:ShowWidget()
end

function ItemSlotCommonItemAreaMobile:OnDestroy()
    self:InitData()
    self:UnregUIEvent()

    UserWidget.OnDestroy(self)
end

--   ___ _   _ ___ _____ 
--  |_ _| \ | |_ _|_   _|
--   | ||  \| || |  | |  
--   | || |\  || |  | |  
--  |___|_| \_|___| |_|  

function ItemSlotCommonItemAreaMobile:InitUI()
    self.ItemSlotWidgetArray = {
        self.BP_BagEquipWidget_1,
        self.BP_BagEquipWidget_2,
        self.BP_BagEquipWidget_3,
        self.BP_BagEquipWidget_4,
        self.BP_BagEquipWidget_5,
        self.BP_BagEquipWidget_6,
        self.BP_BagEquipWidget_7,
        self.BP_BagEquipWidget_8,
        self.BP_BagEquipWidget_9,
        self.BP_BagEquipWidget_10,
    }
end

function ItemSlotCommonItemAreaMobile:InitData()
    self.ViewModel_PlayerBag = UE.UGUIManager.GetUIManager(self):GetViewModelByName("ViewModel_PlayerBag")
    if not self.ViewModel_PlayerBag then
        print("BagM@ItemSlotCommonItemAreaMobile Init VM Failed!")
    end
end

function ItemSlotCommonItemAreaMobile:InitGameEvent()
    -- 注册消息监听
    self.MsgList = { 
       
    }
end

function ItemSlotCommonItemAreaMobile:InitUIEvent()
    if not self.ViewModel_PlayerBag then
        return
    end
    self.ViewModel_PlayerBag.UIEvent_CommonItemList_TotalUpdate:Add(self,self.OnTotalItemListUpdate)
end


function ItemSlotCommonItemAreaMobile:UnregUIEvent()
    if not self.ViewModel_PlayerBag then
        return
    end
    self.ViewModel_PlayerBag.UIEvent_CommonItemList_TotalUpdate:Add(self,self.OnTotalItemListUpdate)
end

function ItemSlotCommonItemAreaMobile:GetAllItemWidget()
    return self.ItemSlotWidgetArray
end

--   _   _ ___   ____  _____ _____ ____  _____ ____  _   _ 
--  | | | |_ _| |  _ \| ____|  ___|  _ \| ____/ ___|| | | |
--  | | | || |  | |_) |  _| | |_  | |_) |  _| \___ \| |_| |
--  | |_| || |  |  _ <| |___|  _| |  _ <| |___ ___) |  _  |
--   \___/|___| |_| \_\_____|_|   |_| \_\_____|____/|_| |_|
function ItemSlotCommonItemAreaMobile:ShowWidget()
    if not self.ViewModel_PlayerBag then
        return
    end
    self:RefreshTotalItemSlotList(self.ViewModel_PlayerBag.CommonSlotItemList)
end

function ItemSlotCommonItemAreaMobile:RefreshTotalItemSlotList(ItemDataList)
    local BagMaxSlotNum = self:GetBagMaxSlotNum()

    --1.更新背包格子锁定状态
    self:RefreshItemSlotLockState(BagMaxSlotNum)

    --2.更新背包格子显示内容
    local ItemDataNum = ItemDataList:Length()
    local RealIndex = 0
    for index = 1, ItemDataNum, 1 do
        local ItemData = ItemDataList:Get(index)
        if ItemData then
            RealIndex = RealIndex + 1
            local TargetWidget = self:GetItemSlotWidgetByIndex(RealIndex)
            if TargetWidget then
                TargetWidget:SetItemData(ItemData)
                TargetWidget:ShowWidget()
            end
        end
    end
    self.Text_UseNum:SetText(tostring(RealIndex))
    self.Text_MaxNum:SetText("/"..tostring(BagMaxSlotNum))

    -- 3.设置已解锁无内容的背包
    for i = RealIndex + 1, BagMaxSlotNum, 1 do
        local TargetWidget = self:GetItemSlotWidgetByIndex(i)
        if TargetWidget then
            TargetWidget:ResetWidget()
        end
    end

end

function ItemSlotCommonItemAreaMobile:RefreshItemSlotLockState(BagMaxSlotNum)    
    local LoopCount = 0
    if self.ItemSlotWidgetArray then
        LoopCount = #self.ItemSlotWidgetArray
    end

    for Index, ItemWidget in ipairs(self.ItemSlotWidgetArray) do
        if Index > BagMaxSlotNum then
            ItemWidget:SetLockState(true)
            -- TODO 设置不可选中
        else
            -- 不设置显示状态有内容 决定显示状态
        end
    end
end

--   _   _ ___    ____ ___  _   _ _____ ____   ___  _      
--  | | | |_ _|  / ___/ _ \| \ | |_   _|  _ \ / _ \| |     
--  | | | || |  | |  | | | |  \| | | | | |_) | | | | |     
--  | |_| || |  | |__| |_| | |\  | | | |  _ <| |_| | |___  
--   \___/|___|  \____\___/|_| \_| |_| |_| \_\\___/|_____|
function ItemSlotCommonItemAreaMobile:GetBagMaxSlotNum()
    local TempPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if not TempPC then
        return
    end

    local TempBagComp = UE.UBagComponent.Get(TempPC)
    if not TempBagComp then
        return
    end

    local TempMaxSlotNum = TempBagComp:GetMaxSlotNum()
    print("BagM@RefreshItemSlotLockState max slot:", TempMaxSlotNum)
    return TempMaxSlotNum
end

function ItemSlotCommonItemAreaMobile:GetAllSlotWidget()
    return self.ItemSlotWidgetArray
end

function ItemSlotCommonItemAreaMobile:GetItemSlotWidgetByIndex(InIndex)
    if self.ItemSlotWidgetArray then
        return self.ItemSlotWidgetArray[InIndex]
    end
    return nil
end
--   _   _ ___   _______     _______ _   _ _____ 
--  | | | |_ _| | ____\ \   / / ____| \ | |_   _|
--  | | | || |  |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| || |  | |___  \ V / | |___| |\  | | |  
--   \___/|___| |_____|  \_/  |_____|_| \_| |_|  

function ItemSlotCommonItemAreaMobile:OnTotalItemListUpdate()
    self:RefreshTotalItemSlotList(self.ViewModel_PlayerBag.CommonSlotItemList)
end

--    ____    _    __  __ _____   _______     _______ _   _ _____ 
--   / ___|  / \  |  \/  | ____| | ____\ \   / / ____| \ | |_   _|
--  | |  _  / _ \ | |\/| |  _|   |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| |/ ___ \| |  | | |___  | |___  \ V / | |___| |\  | | |  
--   \____/_/   \_\_|  |_|_____| |_____|  \_/  |_____|_| \_| |_| 

return ItemSlotCommonItemAreaMobile