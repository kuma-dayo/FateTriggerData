require "UnLua"

local BagMianMobile = Class("Common.Framework.UserWidget")

function BagMianMobile:OnInit()
    print("BagmM@BagMianMobile Init")
    self:InitData()
    self:InitUI()
    self:InitGameEvent()
    self:InitUIEvent()

    UserWidget.OnInit(self)
end

function BagMianMobile:OnShow(InContext, InGenericBlackboard)
    self.Overridden.OnShow(self, InContext, InGenericBlackboard)

    self:ShowWidget()
end

function BagMianMobile:OnDestroy()
    self:UnregUIEvent()
    self.ViewModel_PlayerBag = nil

    UserWidget.OnDestroy(self)
end

--   ___ _   _ ___ _____ 
--  |_ _| \ | |_ _|_   _|
--   | ||  \| || |  | |  
--   | || |\  || |  | |  
--  |___|_| \_|___| |_|  
                      
function BagMianMobile:InitUI() 
    -- 侧边栏
    self.BP_Bag_TabZoom:SetTabIndex(1)

    -- 武器槽位
    self.WeaponWidgetList ={
        self.BP_ItemSlotWeapon_1,
        self.BP_ItemSlotWeapon_2,
    }
    for Index, WeaponBp in ipairs(self.WeaponWidgetList) do
        WeaponBp:SetSlotIndex(Index)
    end
    
    -- 丢弃区域设置
    self.BP_DropZoom_Equip:AddItemSlot(self.WeaponWidgetList[1])
    self.BP_DropZoom_Equip:AddItemSlot(self.WeaponWidgetList[2])

    local ItemWidgetList = self.BP_ItemSlotContainer_Item:GetAllItemWidget()
    for _, ItemWidget in pairs(ItemWidgetList) do
        self.BP_DropZoom_Bag:AddItemSlot(ItemWidget)
    end
    local BulletWidgetList = self.BP_ItemSlotContainer_Bullet:GetAllBulletWidget()
    for _, BulletWidget in pairs(BulletWidgetList) do
        self.BP_DropZoom_Bag:AddItemSlot(BulletWidget)
    end
    local EquipWidgetList = self.BP_ItemSlotContainer_Equip:GetAllEquipWidget()
    for _, EquipWidget in pairs(EquipWidgetList) do
        self.BP_DropZoom_Bag_Left:AddItemSlot(EquipWidget)
    end

    self.BP_DropZoom_DiscardRight:AddItemSlot(self.BP_Bag_TabZoom)

    -- 其余区域初始化设置
    self.BP_Bag_SelectAmount_Mobile:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.BP_ItemDetailInfo_Mobile:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.BP_ItemSlotContainer_Btn:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function BagMianMobile:InitData()
    self.ViewModel_PlayerBag = UE.UGUIManager.GetUIManager(self):GetViewModelByName("ViewModel_PlayerBag")
end

function BagMianMobile:InitGameEvent()
    -- 注册消息监听
    self.MsgList = {
		{ MsgName = GameDefine.Msg.BagMobile_ShowItemDetail,     Func = self.ShowItemDetail,   bCppMsg = false },
		{ MsgName = GameDefine.Msg.BagMobile_HideItemDetail,     Func = self.HideItemDetail,   bCppMsg = false },
		{ MsgName = GameDefine.Msg.BagMobile_ShowDropAmount,     Func = self.ShowDropAmount,   bCppMsg = false },
		{ MsgName = GameDefine.Msg.BagMobile_HideDropAmount,     Func = self.HideDropAmount,   bCppMsg = false },
        { MsgName = GameDefine.Msg.BagMobile_HideItemButton,     Func = self.HideItemButton,   bCppMsg = false },

    }
end

function BagMianMobile:InitUIEvent()
    self.ViewModel_PlayerBag.UIEvent_Weapon_SingleUpdate:Add(self,self.OnWeaponUpdate)
    self.ViewModel_PlayerBag.UIEvent_Weapon_SingleClear:Add(self,self.OnWeaponClear)

    self.ViewModel_PlayerBag.UIEvent_Weapon_MagUpdate:Add(self,self.OnWeaponMagUpdate)
    self.ViewModel_PlayerBag.UIEvent_Weapon_BulletNumUpdate:Add(self,self.OnWeaponBulletNumUpdate)
    self.ViewModel_PlayerBag.UIEvent_Weapon_BulletMaxNumUpdate:Add(self,self.OnWeaponBulletMaxNumUpdate)
    self.ViewModel_PlayerBag.UIEvent_Weapon_AttachmentUpdate:Add(self,self.OnWeaponAttachmentUpdate)
    self.ViewModel_PlayerBag.UIEvent_Weapon_EnhanceUpdate:Add(self,self.OnWeaponEnhanceUpdate)
end

function BagMianMobile:UnregUIEvent()
    self.ViewModel_PlayerBag.UIEvent_Weapon_SingleUpdate:Remove(self,self.OnWeaponUpdate)
    self.ViewModel_PlayerBag.UIEvent_Weapon_SingleClear:Remove(self,self.OnWeaponClear)

    self.ViewModel_PlayerBag.UIEvent_Weapon_MagUpdate:Remove(self,self.OnWeaponMagUpdate)
    self.ViewModel_PlayerBag.UIEvent_Weapon_BulletNumUpdate:Remove(self,self.OnWeaponBulletNumUpdate)
    self.ViewModel_PlayerBag.UIEvent_Weapon_BulletMaxNumUpdate:Remove(self,self.OnWeaponBulletMaxNumUpdate)
    self.ViewModel_PlayerBag.UIEvent_Weapon_AttachmentUpdate:Remove(self,self.OnWeaponAttachmentUpdate)
    self.ViewModel_PlayerBag.UIEvent_Weapon_EnhanceUpdate:Remove(self,self.OnWeaponEnhanceUpdate)
end

--   _   _ ___   ____  _____ _____ ____  _____ ____  _   _ 
--  | | | |_ _| |  _ \| ____|  ___|  _ \| ____/ ___|| | | |
--  | | | || |  | |_) |  _| | |_  | |_) |  _| \___ \| |_| |
--  | |_| || |  |  _ <| |___|  _| |  _ <| |___ ___) |  _  |
--   \___/|___| |_| \_\_____|_|   |_| \_\_____|____/|_| |_|
function BagMianMobile:ShowWidget()
    -- 武器展示区域背包直接管理 其余槽位有对应的area管理
    self:ActiveShowAllWeapon()  
end


function BagMianMobile:ActiveShowAllWeapon()
    for Index, WeaponWidget in ipairs(self.WeaponWidgetList) do
        local WeaponData = self.ViewModel_PlayerBag.WeaponSlotMap:FindRef(Index)
        if WeaponData then
            WeaponWidget:SetWeaponData(WeaponData)
            WeaponWidget:ShowWidget()
        end
    end
end

--   _   _ ___   _______     _______ _   _ _____ 
--  | | | |_ _| | ____\ \   / / ____| \ | |_   _|
--  | | | || |  |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| || |  | |___  \ V / | |___| |\  | | |  
--   \___/|___| |_____|  \_/  |_____|_| \_| |_|  
function BagMianMobile:OnWeaponUpdate(SlotIndex)
    local NewData = self.ViewModel_PlayerBag.WeaponSlotMap:FindRef(SlotIndex)
    local Widget = self.WeaponWidgetList[SlotIndex]
    if NewData and Widget then
        Widget:SetWeaponData(NewData)
        Widget:ShowWidget()
    end
end

function BagMianMobile:OnWeaponClear(SlotIndex)
    local Widget = self.WeaponWidgetList[SlotIndex]
    if Widget then
        Widget:ResetWidget()
    end
end

function BagMianMobile:OnWeaponMagUpdate(SlotIndex)
    -- TODO 性能组优化 当前玩家移动就会触发
    local NewData = self.ViewModel_PlayerBag.WeaponSlotMap:FindRef(SlotIndex)
    local Widget = self.WeaponWidgetList[SlotIndex]
    if NewData and Widget then
        Widget:SetWeaponData(NewData)
        Widget:RefreshWeaponBulletNumTotal(NewData.BulletNum, NewData.BulletMaxNum)
        Widget:RefreshWeaponInfiniteBullet(NewData.InfiniteAmmo)
    end
end

function BagMianMobile:OnWeaponBulletNumUpdate(SlotIndex)
    local NewData = self.ViewModel_PlayerBag.WeaponSlotMap:FindRef(SlotIndex)
    local Widget = self.WeaponWidgetList[SlotIndex]
    if NewData and Widget then
        Widget:SetWeaponData(NewData)
        Widget:RefreshWeaponBulletNumCurrent(NewData.BulletNum)
    end
end

function BagMianMobile:OnWeaponBulletMaxNumUpdate(SlotIndex)
    local NewData = self.ViewModel_PlayerBag.WeaponSlotMap:FindRef(SlotIndex)
    local Widget = self.WeaponWidgetList[SlotIndex]
    if NewData and Widget then
        Widget:SetWeaponData(NewData)
        Widget:RefreshWeaponBulletNumMax(NewData.BulletMaxNum)
    end
end

function BagMianMobile:OnWeaponAttachmentUpdate(SlotIndex)
    local NewData = self.ViewModel_PlayerBag.WeaponSlotMap:FindRef(SlotIndex)
    local Widget = self.WeaponWidgetList[SlotIndex]
    if NewData and Widget then
        Widget:SetWeaponData(NewData)
        Widget:RefreshWeaponAttachmentWidget(
            NewData.WeaponSupportAttachmentTypeList, 
            NewData.WeaponAttachments, 
            NewData.GAWeaponInstance
        )
    end
end

function BagMianMobile:OnWeaponEnhanceUpdate(SlotIndex)
    local NewData = self.ViewModel_PlayerBag.WeaponSlotMap:FindRef(SlotIndex)
    local Widget = self.WeaponWidgetList[SlotIndex]
    if NewData and Widget then
        Widget:SetWeaponData(NewData)
        Widget:RefreshWeaponEnhanceWidget(NewData.WeaponEnhanceAttrID)
    end
end

--    ____    _    __  __ _____   _______     _______ _   _ _____ 
--   / ___|  / \  |  \/  | ____| | ____\ \   / / ____| \ | |_   _|
--  | |  _  / _ \ | |\/| |  _|   |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| |/ ___ \| |  | | |___  | |___  \ V / | |___| |\  | | |  
--   \____/_/   \_\_|  |_|_____| |_____|  \_/  |_____|_| \_| |_|  
                                                               
function BagMianMobile:ShowItemDetail(ItemInfo)
    print("BagmM@ShowItemDetail")
    -- 详情面板
    self:OnShowItemDetailHandle(ItemInfo)
    -- 详情按钮面板
    self:OnShowItemDetailKeyBtnHandle(ItemInfo)
end

function BagMianMobile:HideItemDetail() 
    print("BagmM@HideItemDetail")
    self.BP_ItemDetailInfo_Mobile:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function BagMianMobile:OnShowItemDetailHandle(ItemInfo)
    local preVisibility = self.BP_ItemDetailInfo_Mobile:GetVisibility()
    if preVisibility == UE.ESlateVisibility.Visible then
        self.BP_ItemDetailInfo_Mobile:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    self.BP_ItemDetailInfo_Mobile:UpdataDetailInfo(ItemInfo)
    self.BP_ItemDetailInfo_Mobile:SetVisibility(UE.ESlateVisibility.Visible)
end

function BagMianMobile:OnShowItemDetailKeyBtnHandle(ItemInfo)
    -- 强化词条不显示
    if not ItemInfo.ItemID then
        return
    end

    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(self, ItemInfo.ItemID, "ItemType",
    GameDefine.NItemSubTable.Ingame, "BagMianMobile:ShowItemDetail")
    if not IsFindItemType then
        return
    end

    -- 武器/在武器上的配件 不显示
    if CurrentItemType == ItemSystemHelper.NItemType.Weapon then
        return
    end
    if CurrentItemType == ItemSystemHelper.NItemType.Attachment and ItemInfo.InWeaponInstance then
        return
    end

    -- 背包区域的配件
    if CurrentItemType == ItemSystemHelper.NItemType.Attachment and (not ItemInfo.InWeaponInstance) then
        if ItemInfo.CanUse then
            ItemInfo.KeyButtonState = ItemSystemHelper.NKeyButtonState.AttachmentCanUse
            self.BP_ItemSlotContainer_Btn:UpdateDetailButton(ItemInfo)
        else
            ItemInfo.KeyButtonState = ItemSystemHelper.NKeyButtonState.AttachmentCanNotUse
            self.BP_ItemSlotContainer_Btn:UpdateDetailButton(ItemInfo)
        end
    end
    
    if CurrentItemType == ItemSystemHelper.NItemType.Potion then
        ItemInfo.KeyButtonState = ItemSystemHelper.NKeyButtonState.Potion
        self.BP_ItemSlotContainer_Btn:UpdateDetailButton(ItemInfo)
    end

    if CurrentItemType == ItemSystemHelper.NItemType.Throwable then
        ItemInfo.KeyButtonState = ItemSystemHelper.NKeyButtonState.Throwable
        self.BP_ItemSlotContainer_Btn:UpdateDetailButton(ItemInfo)
    end

    if CurrentItemType == ItemSystemHelper.NItemType.Bullet then
        if ItemInfo.CanUse then
            ItemInfo.KeyButtonState = ItemSystemHelper.NKeyButtonState.BulletCanUse
            self.BP_ItemSlotContainer_Btn:UpdateDetailButton(ItemInfo)
        else
            ItemInfo.KeyButtonState = ItemSystemHelper.NKeyButtonState.BulletCanNotUse
            self.BP_ItemSlotContainer_Btn:UpdateDetailButton(ItemInfo)
        end
    end
    self.BP_ItemSlotContainer_Btn:SetVisibility(UE.ESlateVisibility.Visible)
end

function BagMianMobile:ShowDropAmount(InItemData)
    self.BP_Bag_SelectAmount_Mobile:UpdateSelectAmount(InItemData)
    self.BP_Bag_SelectAmount_Mobile:SetVisibility(UE.ESlateVisibility.Visible)
end

function BagMianMobile:HideDropAmount(ItemInfo)
    self.BP_Bag_SelectAmount_Mobile:UpdateSelectAmount(ItemInfo)
    self.BP_Bag_SelectAmount_Mobile:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function BagMianMobile:HideItemButton()
    self.BP_ItemSlotContainer_Btn:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return BagMianMobile