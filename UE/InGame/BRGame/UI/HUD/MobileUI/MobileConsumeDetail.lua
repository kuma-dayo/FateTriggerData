
require "InGame.BRGame.GameDefine"


local MobileConsumeDetail = Class("Common.Framework.UserWidget")

local DefaultSlotId = 1
local BattleUIHelper = require ("InGame.BRGame.UI.HUD.BattleUIHelper")
local SelectConsumableItemProxy = require("InGame.BRGame.UI.HUD.SelectItem.SelectConsumableItemProxy")
local ESelectItemType = UE.ESelectItemType


-------------------------------------------- Init/Destroy ------------------------------------

function MobileConsumeDetail:OnInit()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

    self.TxtConsumeNum:SetText('')
    self.TxtConsumeCD:SetText('')
    self.DefaultTextureNone = self.ImgConsumeIcon.Brush.ResourceObject
    self.SelectItemNum = SelectItemHelper.GetDefaultItemNum(self,"1",ESelectItemType.Medicines)      -- 记录物品选择轮盘上一共有多少不同种类的消耗品 TODO 后续有获取 modeId 的接口后再对接

    self:UpdatePotionInfo(self.LocalPC)
    self:InitPlayerPawnInfo()
    
	self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.PC_UpdatePlayerPawn,          Func = self.OnLocalPCUpdatePawn,    bCppMsg = true, WatchedObject = self.LocalPC },
        { MsgName = GameDefine.Msg.PLAYER_OpenSelectItem,           Func = self.OnOpenSelectItem,       bCppMsg = false, WatchedObject = nil },
		{ MsgName = GameDefine.Msg.PLAYER_ItemSlots,                Func = self.OnItemSlotsChange,      bCppMsg = true, WatchedObject = nil },
        { MsgName = GameDefine.Msg.InventoryItemNumChangeTotal, Func = self.OnInventoryItemNumChangeTotal, bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Change_Potion, Func = self.OnInventoryItemSlotChangePotion, bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Reset, Func = self.OnInventoryItemSlotReset, bCppMsg = true },
	}
    self.Joystick.BPDelegate_OnJoystickTagEvent:Add(self, self.OnJoystickTagEvent)
    --self.Joystick.OnPressed:Add(self, MobileConsumeDetail.OnPressedThrowBtn)
    --self.Joystick.OnReleased:Add(self, MobileConsumeDetail.OnReleasedThrowBtn)
	UserWidget.OnInit(self)
end

function MobileConsumeDetail:OnDestroy()
    MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})
	UserWidget.OnDestroy(self)
end

function MobileConsumeDetail:OnLocalPCUpdatePawn(InLocalPC, InPCPwn)
	if self.LocalPC == InLocalPC then
		self:InitPlayerPawnInfo()
	end
end

function MobileConsumeDetail:InitPlayerPawnInfo()
	local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
	if LocalPCPawn then
        -- 重置玩家状态
        self:OnEndDying(nil)

        -- 监听对象消息
        MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})
        self.MsgList_Pawn = {
            { MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDying,          Func = self.OnBeginDying,           bCppMsg = true, WatchedObject = LocalPCPawn },
            { MsgName = GameDefine.MsgCpp.PLAYER_OnEndDying,            Func = self.OnEndDying,             bCppMsg = true, WatchedObject = LocalPCPawn },
        }
        MsgHelper:RegisterList(self, self.MsgList_Pawn)
    end
end


-------------------------------------------- Function ------------------------------------

function MobileConsumeDetail:SetConsumeIconImage(InEquipComp)
    local TempBagComp = UE.UBagComponent.Get(self.LocalPC)
    print("MobileConsumeDetail:SetConsumeIconImage-->TempBagComp:", TempBagComp)
    local ThrowableWeaponSlot, bValidWeaponSlot = TempBagComp:GetItemSlotByTypeAndSlotID(ItemSystemHelper.NItemType.Potion, 1)
    if (not bValidWeaponSlot) or (ThrowableWeaponSlot.InventoryIdentity.ItemID == 0) then
        print("MobileConsumeDetail:SetConsumeIconImage-->GetItemSlotByTypeAndSlotID failed...")
        self.ImgConsumeIcon:SetBrushFromTexture(nil, false)
        return nil, false
    end
     --下面一行为获取ItemID（获取对应等级的物品）
	local ItemId = ThrowableWeaponSlot.InventoryIdentity.ItemID
	local ItemIdString = tostring(ItemId)
	local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(InEquipComp)
	local SubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(ItemId, "Ingame")
	if SubTable then		
		-- 物品图片图标
		local ImageAsset, bValidImage = SubTable:BP_FindDataFString(ItemIdString, "SlotImage")
		if (not bValidImage) then
			ImageAsset, bValidImage = SubTable:BP_FindDataFString(ItemIdString, "ItemIcon")
		end
		if bValidImage then
			local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(ImageAsset)
			self.ImgConsumeIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
			print("MobileConsumeDetail", ">> SetImageTexture_BagItem[3], ", GetObjectName(self.ImgConsumeIcon), ImageAsset, ImageSoftObjectPtr)
			return ThrowableWeaponSlot, bValidWeaponSlot
		end
	end
end

function MobileConsumeDetail:UpdatePotionInfoInner(InLocalPC)
    
    -- 先把Ui初始化到最初状态
    self.WidgetSwitcherItem:SetActiveWidgetIndex(0)
    self.ImgBgCircle:GetDynamicMaterial():SetScalarParameterValue("ItemIndex", 0)
    self.ImgBgCircle:GetDynamicMaterial():SetVectorParameterValue("ColorSelected", self.BgCircleDeactivateColor)

    local TempCharacter = InLocalPC:GetPawn()
    if not TempCharacter then return end
    local TempEquipmentComp = UE.UEquipmentStatics.GetEquipmentComponent(TempCharacter)
    if not TempEquipmentComp then return end
    local TempBagComp = UE.UBagComponent.Get(InLocalPC)
    if not TempBagComp then return end
    local TempDefaultSlotId = 1
    local ConsumeNumber = 0
    -- 获取当前装备的武器
    local CurrentItemSlot, ExistCurrentItemSlot = TempBagComp:GetItemSlotByTypeAndSlotID(ItemSystemHelper.NItemType.Potion, TempDefaultSlotId)
    if ExistCurrentItemSlot and CurrentItemSlot.InventoryIdentity.ItemID ~= 0 then
        ConsumeNumber = TempBagComp:GetItemNumByItemID(CurrentItemSlot.InventoryIdentity.ItemID)
        local StrSlotImagePath, ExistStrSlotImagePath = UE.UItemSystemManager.GetItemDataFString(InLocalPC, CurrentItemSlot.InventoryIdentity.ItemID, "SlotImage",
                GameDefine.NItemSubTable.Ingame, "MobileConsumeDetail:UpdatePotionInfoInner")
        if ExistStrSlotImagePath then
            local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(StrSlotImagePath)
            self.ImgConsumeIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
            self.WidgetSwitcherItem:SetActiveWidgetIndex(1)
            self.CurrentItemId = CurrentItemSlot.InventoryIdentity.ItemID
            print("MobileConsumeDetail:UpdatePotionInfoInner        ItemId:", self.CurrentItemId)
            --self:IsEquiped(self.CurrentItemId)
            self:UpdataArcUI(CurrentItemSlot.InventoryIdentity.ItemID, ConsumeNumber)
        end
    end
    if ConsumeNumber ~= 0 then
        self.TxtConsumeNum:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.TxtConsumeNum:SetText(tostring(ConsumeNumber))
    else
        self.TxtConsumeNum:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TxtConsumeNum:SetText('')
    end

end

function MobileConsumeDetail:UpdatePotionInfo(InLocalPC)
    if not InLocalPC then return end
    local BagComp = UE.UBagComponent.Get(InLocalPC)
    if not BagComp then return end
    local CurrentPotionSlot, ExistSlot = BagComp:GetItemSlotByTypeAndSlotID(ItemSystemHelper.NItemType.Potion, 1)
    if ExistSlot and CurrentPotionSlot.InventoryIdentity.ItemID ~= 0 then
        self.CurrentItemID = CurrentPotionSlot.InventoryIdentity.ItemID
        self.WidgetSwitcherItem:SetActiveWidgetIndex(1)
        self:UpdatePotionInfoInnerMobile(InLocalPC, CurrentPotionSlot)
    else
        -- 显示物品图片
        self.WidgetSwitcherItem:SetActiveWidgetIndex(0)
        self.TxtConsumeNum:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function MobileConsumeDetail:UpdatePotionInventoryItemSlot(InLocalPC, InInventoryItemSlot)
    if not InLocalPC then return end
    local BagComp = UE.UBagComponent.Get(InLocalPC)
    if not BagComp then return end
    if InInventoryItemSlot.InventoryIdentity.ItemID ~= 0 then
        self.CurrentItemID = InInventoryItemSlot.InventoryIdentity.ItemID
        self.WidgetSwitcherItem:SetActiveWidgetIndex(1)
        self:UpdatePotionInfoInnerMobile(InLocalPC, InInventoryItemSlot)
    else
        self.WidgetSwitcherItem:SetActiveWidgetIndex(0)
        self.TxtConsumeNum:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

-- 更新药品信息
function MobileConsumeDetail:UpdatePotionInfoInnerMobile(InLocalPC, InInventoryItemSlot)
    --初始化
    self.WidgetSwitcherItem:SetActiveWidgetIndex(0)
    self.ImgBgCircle:GetDynamicMaterial():SetScalarParameterValue("ItemIndex", 0)
    self.ImgBgCircle:GetDynamicMaterial():SetVectorParameterValue("ColorSelected", self.BgCircleDeactivateColor)

    if not UE.UKismetSystemLibrary.IsValid(InLocalPC) then return end
    local TempCharacter = InLocalPC:GetPawn()
    if not TempCharacter then return end
    local TempEquipmentComp = UE.UEquipmentStatics.GetEquipmentComponent(TempCharacter)
    if not TempEquipmentComp then return end
    local TempBagComp = UE.UBagComponent.Get(InLocalPC)
    if not TempBagComp then return end

    self.TxtConsumeNum:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    local ConsumeNumber = TempBagComp:GetItemNumByItemID(InInventoryItemSlot.InventoryIdentity.ItemID)

    -- 设置
    local StrSlotImagePath, ExistStrSlotImagePath = UE.UItemSystemManager.GetItemDataFString(InLocalPC, InInventoryItemSlot.InventoryIdentity.ItemID, "SlotImage",GameDefine.NItemSubTable.Ingame,"SkillInfo:InitBagInfo")
    if ExistStrSlotImagePath then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(StrSlotImagePath)
        self.ImgConsumeIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
        self.WidgetSwitcherItem:SetActiveWidgetIndex(1)
        self:UpdataArcUI(InInventoryItemSlot.InventoryIdentity.ItemID, ConsumeNumber)
    end

    if ConsumeNumber ~= 0 then
        self.TxtConsumeNum:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.TxtConsumeNum:SetText(tostring(ConsumeNumber))
    else
        self.TxtConsumeNum:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TxtConsumeNum:SetText('')
    end
end

--[[
    濒死/救援
    InParamters: {
        DyingInfo(FS1LifetimeDyingInfo):  { bIsDying, DyingCounter, DeadCountdownTime }
    }
]]
function MobileConsumeDetail:UpdateDyingState(InParamters)
    local NewVisible1 = InParamters.DyingInfo.bIsDying and
        UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.Visible
    print("MobileConsumeDetail",NewVisible1)
    self.Root:SetVisibility(NewVisible1)--
end

-- 更新外圈圆弧UI
function MobileConsumeDetail:UpdataArcUI(InItemID, InItemNum)
    print("MobileConsumeDetail:UpdataArcUI-->ItemNum:", InItemNum, "InItemID:", InItemID)
    if self.SelectItemNum ~= nil then
        print("MobileConsumeDetail:UpdataArcUI-->UI圆弧一共划分为:", self.SelectItemNum, "份")
        self.ImgBgCircle:GetDynamicMaterial():SetScalarParameterValue("ItemNum", self.SelectItemNum)
    end
    local ItemIdenx = SelectItemHelper.GetItemIndexByItemId(self,"1",InItemID)--TODO 后续有获取 modeId 的接口后再对接
    print("MobileConsumeDetail:UpdataArcUI-->处理圆弧的index:", ItemIdenx)
    self.ImgBgCircle:GetDynamicMaterial():SetScalarParameterValue("ItemIndex", ItemIdenx)
    if InItemNum ~= 0 then
        --local VisibilityType = self.ImgConsumeActive:GetVisibility()
        local VisibilityType = UE.ESlateVisibility.Visible
        if (VisibilityType == UE.ESlateVisibility.Collapsed) or (VisibilityType == UE.ESlateVisibility.Hidden) then
            -- 如果这个组件是隐藏的，说明这个物品没有被选中
            print("MobileConsumeDetail:UpdataArcUI-->全都是未选中状态")
            self.ImgBgCircle:GetDynamicMaterial():SetVectorParameterValue("ColorSelected", self.BgCircleDeactivateColor)
        else
            print("MobileConsumeDetail:UpdataArcUI-->ItemIdenx:", ItemIdenx, "是选中态（橙色），其余是未选中状态（灰色）")
            self.ImgBgCircle:GetDynamicMaterial():SetVectorParameterValue("ColorSelected", self.BgCircleActiveColor)
        end
    else
        print("MobileConsumeDetail:UpdataArcUI-->没有：", ItemIdenx, "这个物品(透明色)")
    end
end

-------------------------------------------- Callable ------------------------------------

-- 是否在选择药品 抽
function MobileConsumeDetail:OnOpenSelectItem(InMsgBody) --
    if InMsgBody and (InMsgBody.Type == ESelectItemType.Medicines) then
        local NewVisible = (InMsgBody.bEnable) and
			UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
		self.ImgConsumeActive:SetVisibility(NewVisible) --
    end
end

-- 物品插槽改变 stay
function MobileConsumeDetail:OnItemSlotsChange(InOwnerActor)
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if InOwnerActor == TempLocalPC then
        self:UpdatePotionInfo(TempLocalPC)
    end
end

-- 当物品个数改变
function MobileConsumeDetail:OnInventoryItemNumChangeTotal(In_FGMPMessage_InventoryItemChange_Total)
    self:UpdatePotionInfo(TempLocalPC)
end

-- 插槽数据改变
function MobileConsumeDetail:OnInventoryItemSlotChangePotion(InBagComponentOwner, InInventoryItemSlot)
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempLocalPC ~= InBagComponentOwner then return end
    self:UpdatePotionInventoryItemSlot(TempLocalPC, InInventoryItemSlot)
end

-- 插槽数据重置
function MobileConsumeDetail:OnInventoryItemSlotReset(InBagComponentOwner, InInventoryItemSlot)
    self:UpdatePotionInfo(InBagComponentOwner)
end

function MobileConsumeDetail:OnBeginDying(InDyingMessageInfo)
    print("PlayerInfo", ">> OnBeginDying, ", InDyingMessageInfo.DyingInfo)

    self.bIsDying = InDyingMessageInfo.DyingInfo.bIsDying
    self:UpdateDyingState({ DyingInfo = InDyingMessageInfo.DyingInfo })
end

function MobileConsumeDetail:OnEndDying(InDyingMessageInfo)
    print("PlayerInfo", ">> OnEndDying, ")

    local DyingInfo = UE.FS1LifetimeDyingInfo()
    DyingInfo.bIsDying = false
    self.bIsDying = DyingInfo.bIsDying
    self:UpdateDyingState({ DyingInfo = DyingInfo })
end

function MobileConsumeDetail:OnJoystickTagEvent(InControllorId, InAnalogValue)
    print("MobileConsumeDetail", ">> OnJoystickTagEvent, ", InControllorId, InAnalogValue)
    MsgHelper:Send(self, GameDefine.Msg.SelectPanel_Open, {AnalogValue = InAnalogValue, SelectItemType = ESelectItemType.Medicines})
end

function MobileConsumeDetail:OnButtonUp()
    print("MobileConsumeDetail ButtonUp")
    MsgHelper:Send(self, GameDefine.Msg.SelectPanel_Open, {AnalogValue = nil, SelectItemType = ESelectItemType.Medicines})
end

function MobileConsumeDetail:OnPressedThrowBtn()
    print("MobileConsumeDetail:OnPressedThrowBtn")   
    -- 快速切投消耗品
    --MsgHelper:SendCpp(self.LocalPC, "EnhancedInput.UISwitch", "SlotItem.Switch.Potion.1")
end

function MobileConsumeDetail:OnReleasedThrowBtn()
    print("MobileConsumeDetail:OnReleasedThrowBtn")    
    --MsgHelper:Send(self, GameDefine.Msg.SelectPanel_Close, ESelectItemType.Medicines)
end




return MobileConsumeDetail
