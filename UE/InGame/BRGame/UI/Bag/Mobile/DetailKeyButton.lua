require "UnLua"
require "InGame.BRGame.GameDefine"

local DetailKeyButton = Class()

function DetailKeyButton:Initialize(Initializer)

end

function DetailKeyButton:Construct()
	self.MsgList = {
		--{ MsgName = GameDefine.Msg.PLAYER_ShowItemDetailInfo,     Func = self.ShowItemDetailInfo,   bCppMsg = false },
		--{ MsgName = GameDefine.Msg.PLAYER_HideItemDetailInfo,     Func = self.HideItemDetailInfo,   bCppMsg = false }
    }
    self.BindNodes = {
		{ UDelegate = self.GUIButton_DropAllBullet.OnClicked, Func = self.OnClicked_DropAllBullet },
		{ UDelegate = self.GUIButton_DropPartBullet.OnClicked, Func = self.OnClicked_DropPartBullet },
		{ UDelegate = self.GUIButton_Use.OnClicked, Func = self.OnClicked_Use },
		{ UDelegate = self.GUIButton_DrapPartItem.OnClicked, Func = self.OnClicked_DrapPartItem },
		{ UDelegate = self.GUIButton_DropAllItem.OnClicked, Func = self.OnClickedDropAllItem },
		{ UDelegate = self.GUIButton_Equip.OnClicked, Func = self.OnClicked_Equip },
		{ UDelegate = self.GUIButton_Discard.OnClicked, Func = self.OnClickedDropAllItem },
		{ UDelegate = self.GUIButton_UnEquip.OnClicked, Func = self.OnClicked_UnEquip },
		{ UDelegate = self.GUIButton_DropWeapon.OnClicked, Func = self.OnClicked_DropWeapon },

	}
    MsgHelper:OpDelegateList(self, self.BindNodes, true)
	MsgHelper:RegisterList(self, self.MsgList)
end

function DetailKeyButton:Destruct()
	if self.MsgList then
		MsgHelper:UnregisterList(self, self.MsgList)
		self.MsgList = nil
	end
	if self.BindNodes then
        MsgHelper:OpDelegateList(self, self.BindNodes, false)
		self.BindNodes = nil
	end
    --self:Release()
end

function DetailKeyButton:SetItemInfo(InItemID, InItemInstanceID,InItemNum,ParentWidget)
    self.ItemID = InItemID
    self.ItemInstanceID = InItemInstanceID
    self.ItemNum = InItemNum
    --self.ParentWidget = ParentWidget

    local ItemSystemManager = UE.UItemSystemManager.GetItemSystemManager(self)
    -- 查类型
    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)

    
    local ItemUniqueInfo, IsConsumable = ItemSystemManager:GetItemUniqueInfo(self.ItemID)

    local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(self)
    local IngameTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(self.ItemID, "Ingame")
    local StrItemID = tostring(self.ItemID)
    local CurrentItemType, RetItemType = IngameTable:BP_FindDataFName(StrItemID,"ItemType")
    print("DetailKeyButton::SetItemInfo   BP_FindDataFName()  CurrentItemType:", CurrentItemType, "RetItemType:", RetItemType)
    if not RetItemType then return end
    
    local ItemUniqueInfo, IsConsumable = ItemSystemManager:GetItemUniqueInfo(InItemID)
    if ItemUniqueInfo.ItemCategory == GameDefine.NIngameItemMapCategory.Consumables then
        if CurrentItemType == "Bullet" then
            self.WidgetSwitcher_ShowPanel:SetActiveWidget(self.GUIButton_DropAllBullet)
        elseif CurrentItemType == "Attachment" then
            self.WidgetSwitcher_ShowPanel:SetActiveWidget(self.HorizontalBox_Equipment)
            --配件是否装备
            local TempInventoryIdentity = UE.FInventoryIdentity()
            TempInventoryIdentity.ItemID = self.ItemID
            TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID
            local BagComponent = UE.UBagComponent.Get(PlayerController)
            local InventoryInstanceWAttachment = BagComponent:GetInventoryInstance(TempInventoryIdentity)
            if InventoryInstanceWAttachment then
                local TempWAttachmentHandle = InventoryInstanceWAttachment:GetAttachmentHandle()
                --local TempWAttachmentWeapon = InventoryInstanceWAttachment:GetCurrentAttachedWInstance()
                if TempWAttachmentHandle ~= -1 then --  or TempWAttachmentWeapon
                    self.WidgetSwitcher_UnEquipOrDiscard:SetActiveWidget(self.SizeBtnUnEquip)
                else
                    self.WidgetSwitcher_UnEquipOrDiscard:SetActiveWidget(self.SizeBtnDiscard)
                end                
            end
        elseif CurrentItemType == "Potion" then
            self.WidgetSwitcher_ShowPanel:SetActiveWidget(self.VerticalBox_UseableItem)
        end
    elseif ItemUniqueInfo.ItemCategory == GameDefine.NIngameItemMapCategory.Weapon then
        self.WidgetSwitcher_ShowPanel:SetActiveWidget(self.HorizontalBox_Weapon)
    elseif ItemUniqueInfo.ItemCategory == GameDefine.NIngameItemMapCategory.Equipment then
        self.WidgetSwitcher_ShowPanel:SetActiveWidget(self.HorizontalBox_Equipment)
        self.WidgetSwitcher_UnEquipOrDiscard:SetActiveWidget(self.SizeBtnUnEquip)
    end

    if InItemNum >= 2 then
        self.GUIButton_DrapPartItem:SetVisibility(UE.ESlateVisibility.Visible)
        self.GUIButton_DropPartBullet:SetVisibility(UE.ESlateVisibility.Visible)
    else
        self.GUIButton_DrapPartItem:SetVisibility(UE.ESlateVisibility.Hidden)
        self.GUIButton_DropPartBullet:SetVisibility(UE.ESlateVisibility.Hidden)
    end
end

----------------------------- Callback---------------------------------------
function DetailKeyButton:OnClicked_DropAllBullet()

    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    local TempInventoryIdentity = UE.FInventoryIdentity()
    TempInventoryIdentity.ItemID = self.ItemID
    TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID
    local BagComponent = UE.UBagComponent.Get(PlayerController)
    local TempInventoryInstance = BagComponent:GetInventoryInstance(TempInventoryIdentity)
    if not TempInventoryInstance then return end
    local DiscardNum = TempInventoryInstance:GetStackNum()
    local TempDiscardReasonTag = UE.FGameplayTag()
    UE.UItemStatics.DiscardItem(PlayerController, TempInventoryIdentity, DiscardNum, TempDiscardReasonTag)
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end
function DetailKeyButton:OnClicked_DropPartBullet()

    MsgHelper:Send(self, GameDefine.Msg.PLAYER_ToggleDropPartOfItem, {isShow = true, ItemID = self.ItemID, InstanceID = self.ItemInstanceID, MinNum = 1, MaxNum = self.ItemNum , CurrentNum = self.ItemNum/2})
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end
function DetailKeyButton:OnClicked_Use()
    -- 使用物品
    local TempPlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    local TempBagComp = UE.UBagComponent.Get(TempPlayerController)
    if not TempBagComp then return end
    local TempInventoryInstanceArray = TempBagComp:GetAllItemObjectByItemID(self.ItemID)
    if not TempInventoryInstanceArray then return end
    local FirstInventoryInstance = TempInventoryInstanceArray:Get(1)
    if FirstInventoryInstance and FirstInventoryInstance.ClientUseSkill then
        FirstInventoryInstance:ClientUseSkill()
    end

    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end
function DetailKeyButton:OnClicked_DrapPartItem()

    MsgHelper:Send(self, GameDefine.Msg.PLAYER_ToggleDropPartOfItem, {isShow = true, ItemID = self.ItemID, InstanceID = self.ItemInstanceID, MinNum = 1, MaxNum = self.ItemNum , CurrentNum = self.ItemNum/2})
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end
function DetailKeyButton:OnClickedDropAllItem()

    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    local TempInventoryIdentity = UE.FInventoryIdentity()
    TempInventoryIdentity.ItemID = self.ItemID
    TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID

    local BagComponent = UE.UBagComponent.Get(PlayerController)
    local TempInventoryInstance = BagComponent:GetInventoryInstance(TempInventoryIdentity)
    if not TempInventoryInstance then return end
    local DiscardNum = TempInventoryInstance:GetStackNum()
    local TempDiscardReasonTag = UE.FGameplayTag()
    UE.UItemStatics.DiscardItem(PlayerController, TempInventoryIdentity, DiscardNum, TempDiscardReasonTag)
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end
function DetailKeyButton:OnClicked_Equip()

    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    local TempInventoryIdentity = UE.FInventoryIdentity()
    TempInventoryIdentity.ItemID = self.ItemID
    TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID

    UE.UItemStatics.UseItem(PlayerController, TempInventoryIdentity, ItemSystemHelper.NUsefulReason.PlayerActiveUse)
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end
function DetailKeyButton:OnClicked_UnEquip()

    local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
    local BagComponent = UE.UBagComponent.Get(PlayerController)

    local TempInventoryIdentity = UE.FInventoryIdentity()
    TempInventoryIdentity.ItemID = self.ItemID
    TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID

    local TempWAttachmentObject = BagComponent:GetInventoryInstance(TempInventoryIdentity)
    if TempWAttachmentObject then
        UE.UItemStatics.UseItem(PlayerController, TempInventoryIdentity, ItemAttachmentHelper.NUsefulReason.UnEquipFromWeapon)
    end
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end
function DetailKeyButton:OnClicked_DropWeapon()

    if self.ItemID ~= 0 and self.ItemInstanceID ~= 0 then
        local TempInventoryIdentity = UE.FInventoryIdentity()
        TempInventoryIdentity.ItemID = self.ItemID
        TempInventoryIdentity.ItemInstanceID = self.ItemInstanceID

        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)

        local TempDiscardReasonTag = UE.FGameplayTag()
        UE.UItemStatics.DiscardItem(PlayerController, TempInventoryIdentity, 1, TempDiscardReasonTag)
    end
    MsgHelper:Send(self, GameDefine.Msg.PLAYER_HideItemDetailInfo)
end

return DetailKeyButton