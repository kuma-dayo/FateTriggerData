require "InGame.BRGame.GameDefine"

local MobileSkillInfoThrow = Class("Common.Framework.UserWidget")

local DefaultSlotId = 1
local SelectConsumableItemProxy = require("InGame.BRGame.UI.HUD.SelectItem.SelectConsumableItemProxy")
local BattleUIHelper = require ("InGame.BRGame.UI.HUD.BattleUIHelper")
local ESelectItemType = UE.ESelectItemType

-------------------------------------------- Init/Destroy ------------------------------------

function MobileSkillInfoThrow:OnInit()
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

    self.DisableColor = self.DisableColor or UIHelper.LinearColor.DarkGrey
    self.DefaultTextureNone = self.ImgIconThrow.Brush.ResourceObject
    self.CurrentItemId = nil    -- 记录当前UI上表示的投掷物是什么，如果是空就是nil
    self.SelectItemNum = SelectItemHelper.GetDefaultItemNum(self,"1",ESelectItemType.Throw)      -- 记录物品选择轮盘上一共有多少不同种类的投掷物 TODO 后续有获取 modeId 的接口后再对接
    self.TxtNumThrow:SetText('')
    self.TxtCDThrow:SetText('')

    self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.PC_UpdatePlayerPawn,  Func = self.OnLocalPCUpdatePawn,    bCppMsg = true,     WatchedObject = self.LocalPC }, 
        { MsgName = GameDefine.Msg.PLAYER_OpenSelectItem,   Func = self.OnOpenSelectItem,       bCppMsg = false,    WatchedObject = nil },       
        { MsgName = GameDefine.Msg.PLAYER_ItemSlots,        Func = self.OnItemSlotsChange,      bCppMsg = true,    WatchedObject = nil },
        { MsgName = GameDefine.Msg.InventoryItemNumChangeTotal, Func = self.OnInventoryItemNumChangeTotal, bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Change_Throwable, Func = self.OnInventoryItemSlotChangeThrowable, bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Reset, Func = self.OnInventoryItemSlotReset, bCppMsg = true },

	}
    self.Joystick.BPDelegate_OnJoystickTagEvent:Add(self, self.OnJoystickTagEvent)

    --print("MobileSkillInfoThrow", ">> OnInit, ", self.Joystick, self.Joystick.OnJoystickTagEvent)
    --self.Joystick.OnPressed:Add(self, MobileSkillInfoThrow.OnPressedThrowBtn)
    --self.Joystick.OnReleased:Add(self, MobileSkillInfoThrow.OnReleasedThrowBtn)
    self:InitPlayerPawnInfo()
    
	UserWidget.OnInit(self)
end

function MobileSkillInfoThrow:OnDestroy()
    UserWidget.OnDestroy(self)
end

-------------------------------------------- Function ------------------------------------

function MobileSkillInfoThrow:InitPlayerPawnInfo()
    print("MobileSkillInfoThrow:InitPlayerPawnInfo")
    self.LocalPCPawn = self.LocalPC:GetPawn()
    if self.LocalPCPawn then
        self.LocalPCBag = UE.UBagComponent.Get(self.LocalPC)
        self.LocalPCEquip = UE.UEquipmentStatics.GetEquipmentComponent(self.LocalPCPawn)
        self:UpdateThrowableInfoInner(self.LocalPC)
    end
end

-- 背包物品个数改变
function MobileSkillInfoThrow:OnInventoryItemNumChangeTotal(In_FGMPMessage_InventoryItemChange_Total)
    self:UpdateThrowableInfoInner(self.LocalPC)
end

-- 物品数据改变
function MobileSkillInfoThrow:OnInventoryItemSlotChangeThrowable(InBagComponentOwner, InInventoryItemSlot)
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempLocalPC == InBagComponentOwner then
        self:UpdateThrowableInfoInner(InBagComponentOwner)
    end
end


function MobileSkillInfoThrow:OnInventoryItemSlotReset(InBagComponentOwner, InInventoryItemSlot)
    if not InBagComponentOwner then
        return
    end

    if ItemSystemHelper.NItemType.Throwable == InInventoryItemSlot.ItemType then
        self:UpdateThrowableInfoInner(self.LocalPC)
    end
end

function MobileSkillInfoThrow:OnLocalPCUpdatePawn(InLocalPC, InPCPwn)
	if self.LocalPC == InLocalPC then
		self:InitPlayerPawnInfo()
	end
end

function MobileSkillInfoThrow:UpdateThrowableInfoInner(InLocalPC)

    -- 先把Ui初始化到最初状态
    self.ImgBgCircle:GetDynamicMaterial():SetScalarParameterValue("ItemIndex", 0)
    self.ImgBgCircle:GetDynamicMaterial():SetVectorParameterValue("ColorSelected", self.BgCircleDeactivateColor)
    self.WidgetSwitcherThrow:SetActiveWidgetIndex(0)

    local TempCharacter = InLocalPC:GetPawn()
    if not TempCharacter then return end
    local TempEquipmentComp = UE.UEquipmentStatics.GetEquipmentComponent(TempCharacter)
    if not TempEquipmentComp then return end
    local TempBagComp = UE.UBagComponent.Get(InLocalPC)
    if not TempBagComp then return end

    local TempDefaultSlotId = 1
    local ThrowNumber = 0
    -- 总是获取当前装备的武器
    local CurrentItemSlot, ExistCurrentItemSlot = TempBagComp:GetItemSlotByTypeAndSlotID(ItemSystemHelper.NItemType.Throwable, TempDefaultSlotId)
    if ExistCurrentItemSlot and CurrentItemSlot.InventoryIdentity.ItemID ~= 0 then
        ThrowNumber = TempBagComp:GetItemNumByItemID(CurrentItemSlot.InventoryIdentity.ItemID)
        local StrSlotImagePath, ExistStrSlotImagePath = UE.UItemSystemManager.GetItemDataFString(InLocalPC, CurrentItemSlot.InventoryIdentity.ItemID, "SlotImage",
                GameDefine.NItemSubTable.Ingame, "MobileSkillInfoThrow:UpdateThrowableInfoInner")
        if ExistStrSlotImagePath then
            local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(StrSlotImagePath)
            self.ImgIconThrow:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
            self.WidgetSwitcherThrow:SetActiveWidgetIndex(1)
            self.CurrentItemId = CurrentItemSlot.InventoryIdentity.ItemID
            print("MobileSkillInfoThrow:UpdateThrowableInfoInner        ItemId:", self.CurrentItemId)
            --self:IsEquiped(self.CurrentItemId)
            self:UpdataArcUI(CurrentItemSlot.InventoryIdentity.ItemID, ThrowNumber)
        end
    end
    if ThrowNumber ~= 0 then
        self.TxtNumThrow:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self.TxtNumThrow:SetText(tostring(ThrowNumber))
    else
        self.TxtNumThrow:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TxtNumThrow:SetText('')
    end
end

-- 判断这个ItemID当前是否拿在手上
function MobileSkillInfoThrow:IsEquiped(InItemID)
    print("MobileSkillInfoThrow:IsEquiped   InItemID:", InItemID)
    local RetResult = false
    local TempPlayerController = self.LocalPC

	-- 切出投掷物
	local TempCharacter = TempPlayerController:GetPawn();
	if not TempCharacter then 
        print("MobileSkillInfoThrow:IsEquiped   GetPlayerPawn Failed...")
        return RetResult
    end
	local TempEquipmentComp = UE.UEquipmentStatics.GetEquipmentComponent(TempCharacter)
	if not TempEquipmentComp then 
        print("MobileSkillInfoThrow:IsEquiped   GetEquipmentComponent Failed...")
        return RetResult
    end
	local CurrentEquip = TempEquipmentComp:GetEquippedInstance()
    if  CurrentEquip ~= nil then
        local CurrentIdentity = CurrentEquip:GetInventoryIdentity()
        if  CurrentIdentity ~= nil then
            print("MobileSkillInfoThrow:IsEquiped   CurrentIdentity.ItemID:", CurrentIdentity.ItemID)
            if  InItemID == CurrentIdentity.ItemID then
                print("MobileSkillInfoThrow:IsEquiped   Yes")
                RetResult = true
            else
                print("MobileSkillInfoThrow:IsEquiped   No")
            end
        else
            print("MobileSkillInfoThrow:IsEquiped   CurrentIdentity is nil")
        end
    else
        print("MobileSkillInfoThrow:IsEquiped   CurrentEquip is nil")
    end
    print("MobileSkillInfoThrow:IsEquiped   RetResult:", RetResult)
	return RetResult
end

-- 更新外圈圆弧UI
function MobileSkillInfoThrow:UpdataArcUI(InItemID, InItemNum)
    print("MobileSkillInfoThrow:UpdataArcUI-->InItemID:", InItemID)
    print("MobileSkillInfoThrow:UpdataArcUI-->ItemNum:", InItemNum)
    if self.SelectItemNum ~= nil then
        print("MobileSkillInfoThrow:UpdataArcUI-->UI圆弧一共划分为:", self.SelectItemNum, "份")
        self.ImgBgCircle:GetDynamicMaterial():SetScalarParameterValue("ItemNum", self.SelectItemNum)
    end
    local ItemIdenx = SelectItemHelper.GetItemIndexByItemId(self,"1",InItemID)--TODO 后续有获取 modeId 的接口后再对接
    print("MobileSkillInfoThrow:UpdataArcUI-->处理圆弧的index:", ItemIdenx)
    self.ImgBgCircle:GetDynamicMaterial():SetScalarParameterValue("ItemIndex", ItemIdenx)
    if InItemNum ~= 0 then
        --local VisibilityType = self.ImgActiveThrow:GetVisibility()
        local VisibilityType = UE.ESlateVisibility.Visible  -- 目前默认都是选中状态
        if (VisibilityType == UE.ESlateVisibility.Collapsed) or (VisibilityType == UE.ESlateVisibility.Hidden) then
            -- 如果这个组件是隐藏的，说明这个物品没有被选中
            print("MobileSkillInfoThrow:UpdataArcUI-->全都是未选中状态")
            self.ImgBgCircle:GetDynamicMaterial():SetVectorParameterValue("ColorSelected", self.BgCircleDeactivateColor)
        else
            print("MobileSkillInfoThrow:UpdataArcUI-->ItemIdenx:", ItemIdenx, "是选中态（橙色），其余是未选中状态（灰色）")
            self.ImgBgCircle:GetDynamicMaterial():SetVectorParameterValue("ColorSelected", self.BgCircleActiveColor)
        end
    else
        print("MobileSkillInfoThrow:UpdataArcUI-->没有：", ItemIdenx, "这个物品(透明色)")
    end
end

-- 是否在选择投掷物中
function MobileSkillInfoThrow:OnOpenSelectItem(InMsgBody)
    print("MobileSkillInfoThrow:OnOpenSelectItem")
    if InMsgBody and (InMsgBody.Type == ESelectItemType.Throw) then
        local NewVisible = (InMsgBody.bEnable) and
			UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
        print("MobileSkillInfoThrow:OnOpenSelectItem-->NewVisible")
		self.ImgActiveThrow:SetVisibility(NewVisible)
        self:UpdateThrowableInfoInner(self.LocalPC)
    end
end

-- 物品数据改变
function MobileSkillInfoThrow:OnItemSlotsChange(InOwnerActor)
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    print("MobileSkillInfoThrow:OnItemSlotsChange   InMsgBody.PlayerController:", InOwnerActor, "GetPlayerController(self,0)->", TempLocalPC)
    if InOwnerActor == TempLocalPC then
        self:UpdateThrowableInfoInner(self.LocalPC)
    end
end



function MobileSkillInfoThrow:OnPressedThrowBtn()
    print("MobileSkillInfoThrow:OnPressedThrowBtn")   
    -- 快速切投掷物
    -- CallBack --> US1InventoryItemSlotComponent::OnUISwitchSlotItem(const FString& TempSwitchTag)
    --MsgHelper:SendCpp(self.LocalPC, "EnhancedInput.UISwitch", "SlotItem.Switch.Throwable.1")
    --MsgHelper:SendCpp(self.LocalPC, GameDefine.MsgCpp.PC_Input_UISwitch, "SlotItem.Switch.Throwable.1")
    --MsgHelper:Send(self, GameDefine.Msg.SelectPanel_JustTrigger, {SelectItemType = ESelectItemType.Throw, TriggerItemId = self.CurrentItemId})
end

function MobileSkillInfoThrow:OnReleasedThrowBtn()
    print("MobileSkillInfoThrow:OnReleasedThrowBtn")
    --self.Joystick:SetVisibility(UE.ESlateVisibility.Collapsed)
    
    --MsgHelper:Send(self, GameDefine.Msg.SelectPanel_Close, ESelectItemType.Throw)
end


function MobileSkillInfoThrow:OnJoystickTagEvent(InControllorId, InAnalogValue)
    print("MobileSkillInfoThrow", ">> OnJoystickTagEvent, ", InControllorId, InAnalogValue)
    MsgHelper:Send(self, GameDefine.Msg.SelectPanel_Open, {AnalogValue = InAnalogValue, SelectItemType = ESelectItemType.Throw})
    --self.LocalPC:UseThrowable()
    --MsgHelper:SendCpp(self.LocalPC, "EnhancedInput.SKill.Prepare") 
end

return MobileSkillInfoThrow