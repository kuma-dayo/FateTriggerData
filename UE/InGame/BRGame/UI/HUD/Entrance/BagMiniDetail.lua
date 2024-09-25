--
-- 背包详情入口
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.08.04
--

local BagMiniDetail = Class("Common.Framework.UserWidget")



-------------------------------------------- Config/Enum ------------------------------------

-------------------------------------------- Override ------------------------------------

-------------------------------------------- Init/Destroy ------------------------------------

--
function BagMiniDetail:OnInit()
	print("BagMiniDetail", ">> OnInit, ", GetObjectName(self))
	--
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	self.MsgList = {
		-- 背包
        { MsgName = GameDefine.MsgCpp.BAG_WhenShowHideBag,         Func = self.OnOpenBagPanel,	 		bCppMsg = false, WatchedObject = nil },
        { MsgName = GameDefine.Msg.PLAYER_ItemSlots,            Func = self.OnItemSlotsChange,      bCppMsg = true,  WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.BAG_WeightOrSlotNum,      Func = self.OnUpdateBagData,        bCppMsg = true },

        --头甲
        { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Change_Helmet, Func = self.OnInventoryItemSlotChangeHelmetOrArmor, bCppMsg = true},
        { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Change_Armor, Func = self.OnInventoryItemSlotChangeHelmetOrArmor, bCppMsg = true},
        { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Reset, Func = self.OnReset, bCppMsg = true}
        --{ MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Change_Bag, Func = self.OnInventoryItemSlotChangeBag, bCppMsg = true},

	}
    self.BindNodes = 
    {
        { UDelegate = self.GUIButton_Toggle.OnClicked, Func = self.OnClicked_Toggle },

    }

    self.bIsPCPlatform = BridgeHelper.IsPCPlatform()

    self.ImgBagBg  = self.bIsPCPlatform and self["ImgBagBg_PC"] or self["ImgBagBg_Mobile"]
    self.ImgBagActive = self.bIsPCPlatform and self["ImgBagActive_PC"] or self["ImgBagActive_Mobile"]
    self.ImgBagIcon = self.bIsPCPlatform and self["ImgBagIcon_PC"] or self["ImgBagIcon_Mobile"]
    self.Image_bag_progress = self.bIsPCPlatform and self["Image_bag_progress_PC"] or self["Image_bag_progress_Mobile"]
    self.TxtBagLv =  self.bIsPCPlatform and self["TxtBagLv_PC"] or self["TxtBagLv_Mobile"]
	-- 背包
    self.TxtBagLv:SetText('')
    self.WeightPercentWarnValue = 90	-- 背包负重警告
    self.DefaultTextureNone = self.ImgBagIcon.Brush.ResourceObject
    self:UpdateBagInfo()

    self.bMobilePlatform = BridgeHelper.IsMobilePlatform()

    if self.bMobilePlatform then
        self.TrsGuideTab:SetVisibility(UE.ESlateVisibility.Collapsed)
        
    end

    self.WidgetSwitcher_Bag:SetActiveWidgetIndex(self.bIsPCPlatform and 0 or 1)
    
    --头甲
    self.BPEquipmentMiniDetailTable = {
        ["ArmorBody"] = self.BP_EquipmentMini_Detail_Armor,
        ["ArmorHead"] = self.BP_EquipmentMini_Detail_Helmet,
    }
    self:InitHelmetAndArmorIcon()
	UserWidget.OnInit(self)
end

--
function BagMiniDetail:OnDestroy()
	print("BagMiniDetail", ">> OnDestroy, ", GetObjectName(self))
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------

-------------------------------------------- Function ------------------------------------

function BagMiniDetail:SetBagPicColorAndOpacity(InR, InG, InB, InA)
    print("SelectItemInfo::SetBagPicColorAndOpacity-->R:", InR, "G:", InG, "B:", InB, "A:", InA)
    local ValueToSet = UE.FLinearColor(InR, InG, InB, InA)
    self.ImgBagIcon:SetColorAndOpacity(ValueToSet)
end

-- 更新背包小图标的变化
function BagMiniDetail:UpdateMiniBagPic(InCurrentWeight)
    print("BagMiniDetail::UpdateMiniBagPic-->Start   InCurrentWeight:", InCurrentWeight)
    if InCurrentWeight == 0 then
        -- 空包状态修改颜色变化
        --self:SetBagPicColorAndOpacity(0.631373, 0.235294, 0.07451, 0.3)     -- #d0854d
        
        -- 空包状态修改透明度变化
        --self.ImgBagIcon:SetRenderOpacity(self.NullStateOpacity)
        self.ImgBagIcon:SetColorAndOpacity(self.BagIconInitColor)
        self.PnlIcon:SetRenderOpacity(self.NullStateOpacity)
    else
        self:SetBagPicColorAndOpacity(1.0, 1.0, 1.0, 1.0)
        self.PnlIcon:SetRenderOpacity(self.StandStateOpacity)
    end
end

-- 更新背包等级颜色
function BagMiniDetail:UpdateBagLvColour()
        --[[
        品质色
        红：f66f53
        紫：ca80d1
        蓝：75a9e6
        白：c5bfb7
    ]]  
    local CurBagLV = self.TxtBagLv:GetText()
    -- 表中获取的到等级字符串前面有空格
    CurBagLV = string.gsub(CurBagLV, "%s", "")
    print("BagMiniDetail:UpdateBagLvColour CurBagLV:", CurBagLV)
    if not self.bMobilePlatform then
        local BglevelColor = self.BagLevelColorMap:FindRef(CurBagLV)
        print("BagMiniDetail >> UpdateBagLvColour > BglevelColor:",BglevelColor)
        print("BagMiniDetail >> UpdateBagLvColour > self.DefaultBgColor:",self.BagBgnInitColor)
        self.ImgBagBg:SetColorAndOpacity(BglevelColor or self.BagBgnInitColor)
    end

    if CurBagLV == "" then
        return
    end

    local CurBagLVNum = nil
    if CurBagLV == "I" then     
        CurBagLVNum = 1
    elseif CurBagLV == "II" then
        CurBagLVNum = 2     
    end

    if CurBagLVNum ~= nil then       
        print("BagMiniDetail::UpdateBagLvColour  self.BagLvColorConfigs size:", self.BagLvColorConfigs:Length())
        local SlateColorToSet = self.BagLvColorConfigs:Get(CurBagLVNum)
        if SlateColorToSet ~= nil then
            print("BagMiniDetail::UpdateBagLvColour    SlateColorToSet is:", SlateColorToSet.SpecifiedColor)
            self.TxtBagLv:SetColorAndOpacity(SlateColorToSet)
        else
            print("BagMiniDetail::UpdateBagLvColour    SlateColorToSet is nil") 
        end
    else
        print("BagMiniDetail::UpdateBagLvColour  CurBagLVNum is nil") 
    end
end

-- 更新背包信息(背包)
function BagMiniDetail:UpdateBagInfo()
	local LocalPCPawn = self.LocalPC:GetPawn()
    self.LocalPCBag = UE.UBagComponent.Get(self.LocalPC)
    self.LocalPCEquip = UE.UEquipmentStatics.GetEquipmentComponent(LocalPCPawn)
    
    -- 背包/负重
    print("BagMiniDetail", ">> UpdateBagInfo[Bag], ", GetObjectName(self.LocalPCEquip), self.LocalPCBag.BagData.CurrentWeight, self.LocalPCBag.BagData.MaxWeightNum)
    BattleUIHelper.SetImageTexture_BagItem(self.LocalPCEquip, self.ImgBagIcon, self.TxtBagLv, ItemSystemHelper.NItemType.Bag, 1, self.DefaultTextureNone)
    self:UpdateBagLvColour()
    if self.LocalPCBag:IsWeightMode() then
        local WeightPercentValue = (self.LocalPCBag.BagData.CurrentWeight / self.LocalPCBag.BagData.MaxWeightNum) * 100
        local NewTxtColor = (WeightPercentValue > self.WeightPercentWarnValue) and UIHelper.LinearColor.Red or UIHelper.LinearColor.White
        print("BagMiniDetail >> UpdateBagInfo SetScalarParameterValue   Progress:", self.LocalPCBag.BagData.CurrentWeight / self.LocalPCBag.BagData.MaxWeightNum)
        self.Image_bag_progress:GetDynamicMaterial():SetScalarParameterValue("Progress", (self.LocalPCBag.BagData.CurrentWeight / self.LocalPCBag.BagData.MaxWeightNum) )
        
        -- 不再显示百分比
        --self.TxtBagWeight:SetText(math.floor(WeightPercentValue).. "%")
        --self.TxtBagWeight:SetColorAndOpacity(UIHelper.ToSlateColor_LC(NewTxtColor))
        --self.TxtBagWeight:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    else
        self.TxtBagWeight:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Image_bag_progress:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self:UpdateMiniBagPic(self.LocalPCBag.BagData.CurrentWeight)
end

-------------------------------------------- Callable ------------------------------------

-- 是否打开背包
function BagMiniDetail:OnOpenBagPanel(bIsVisible)
    local NewVisible = (bIsVisible) and
        UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
    self.ImgBagActive:SetVisibility(NewVisible)
end

-- 物品插槽改变
function BagMiniDetail:OnItemSlotsChange(InOwnerActor)
    --print("BagMiniDetail:OnItemSlotsChange")
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if InOwnerActor == TempLocalPC then
        self:UpdateBagInfo()

        
    end
end

-- 物品插槽改变
function BagMiniDetail:OnUpdateBagData(InBagComponent)
    self:UpdateBagInfo()
end


function BagMiniDetail:OnClicked_Toggle()
    if self.bMobilePlatform then
        NotifyObjectMessage(self.LocalPC, "EnhancedInput.ToggleBagUI")
    end
    
end

function BagMiniDetail:InitHelmetAndArmorIcon()

    -- for _, BP in ipairs(self.BPEquipmentMiniDetailTable) do
    --     BP.Img_Icon:SetBrushFromTexture(self.BP_EquipmentMini_Detail_Armor.DefaultIconTexture)
    --     BP.Img_Line:SetVisibility(UE.ESlateVisibility.Collapsed)
    --     BP.BP_EquipmentMini_Detail_Armor.Img_Quality:SetColorAndOpacity(self.BP_EquipmentMini_Detail_Armor.DefaultIconColor)
    -- end
    
    --写ipairs好像有点问题，暂时先这样设置
    self.BP_EquipmentMini_Detail_Armor.Img_Icon:SetBrushFromTexture(self.BP_EquipmentMini_Detail_Armor.DefaultIconTexture)
    --self.BP_EquipmentMini_Detail_Armor.Img_Line:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.BP_EquipmentMini_Detail_Armor.Img_Quality:SetColorAndOpacity(self.BP_EquipmentMini_Detail_Armor.DefaultIconColor)

    self.BP_EquipmentMini_Detail_Helmet.Img_Icon:SetBrushFromTexture(self.BP_EquipmentMini_Detail_Helmet.DefaultIconTexture)
    --self.BP_EquipmentMini_Detail_Helmet.Img_Line:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.BP_EquipmentMini_Detail_Helmet.Img_Quality:SetColorAndOpacity(self.BP_EquipmentMini_Detail_Helmet.DefaultIconColor)
end


function BagMiniDetail:OnInventoryItemSlotChangeHelmetOrArmor(InBagComponentOwner, InInventoryItemSlot)

    -- 物品图标
    local CurItemIcon, IsExistIcon = UE.UItemSystemManager.GetItemDataFString(self, InInventoryItemSlot.InventoryIdentity.ItemID, "ItemIcon", GameDefine.NItemSubTable.Ingame, "ItemSlotNormal:SetItemInfo")

    if (IsExistIcon) then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CurItemIcon)
        self.BPEquipmentMiniDetailTable[InInventoryItemSlot.ItemType].Img_Icon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
    end

    -- 物品等级
    local ItemLevel, IsFindItemLevel = UE.UItemSystemManager.GetItemDataUInt8(self, InInventoryItemSlot.InventoryIdentity.ItemID, "ItemLevel", GameDefine.NItemSubTable.Ingame, "ItemSlotNormal:SetItemInfo")

    local MicSystem = UE.UMiscSystem.GetMiscSystem(self)

    if (IsFindItemLevel and MicSystem) then

         self.BPEquipmentMiniDetailTable[InInventoryItemSlot.ItemType].Img_Quality:SetColorAndOpacity(MicSystem.BagLvImageColor:Find(ItemLevel))
    end

    --self.BPEquipmentMiniDetailTable[InInventoryItemSlot.ItemType].Img_Line:SetVisibility(UE.ESlateVisibility.Visible)
end

function BagMiniDetail:OnReset(InBagComponentOwner, InInventoryItemSlot)

    if not self.BPEquipmentMiniDetailTable[InInventoryItemSlot.ItemType] then return end
    self.BPEquipmentMiniDetailTable[InInventoryItemSlot.ItemType].Img_Icon:SetBrushFromTexture(self.BPEquipmentMiniDetailTable[InInventoryItemSlot.ItemType].DefaultIconTexture)

    self.BPEquipmentMiniDetailTable[InInventoryItemSlot.ItemType].Img_Quality:SetColorAndOpacity(self.BPEquipmentMiniDetailTable[InInventoryItemSlot.ItemType].DefaultIconColor)

    --self.BPEquipmentMiniDetailTable[InInventoryItemSlot.ItemType].Img_Line:SetVisibility(UE.ESlateVisibility.Collapsed)

end

return BagMiniDetail
