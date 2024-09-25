--
-- 战斗界面 - 技能信息
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.04.18
--
local ThrowSkillInfo = Class("Common.Framework.UserWidget")

local ESelectItemType = UE.ESelectItemType

-------------------------------------------- Init/Destroy ------------------------------------

function ThrowSkillInfo:OnInit()
    print("ThrowSkillInfo:OnInit")
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

    -- self.DisableColor = self.DisableColor or UIHelper.LinearColor.DarkGrey
    -- self.DefaultTextureNone = self.ImgIconThrow.Brush.ResourceObject

    self.TxtNumThrow:SetText('')
    self.TxtCDThrow:SetText('')

    -- 绑定角色数据消息
    self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.PC_UpdatePlayerPawn,          Func = self.OnLocalPCUpdatePawn, 	        bCppMsg = true, WatchedObject = self.LocalPC },
        { MsgName = GameDefine.Msg.PLAYER_OpenSelectItem,           Func = self.OnOpenSelectItem,               bCppMsg = false,    WatchedObject = nil },
        { MsgName = GameDefine.Msg.InventoryItemNumChangeTotal,     Func = self.OnInventoryItemNumChangeTotal,  bCppMsg = true,     WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Change_Throwable,                Func = self.OnInventoryItemSlotChangeThrowable,              bCppMsg = true,     WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Reset, Func = self.OnInventoryItemSlotReset, bCppMsg = true, WatchedObject = nil },
    }

    self:InitPlayerPawnInfo()

    UserWidget.OnInit(self)
end

function ThrowSkillInfo:OnDestroy()
    UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

-- 初始化角色信息
function ThrowSkillInfo:InitPlayerPawnInfo()
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
	if LocalPCPawn then
        -- 监听对象消息
        MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})
        self.MsgList_Pawn = {
            { MsgName = GameDefine.MsgCpp.BAG_InventoryItemInfiniteProjectile,    Func = self.OnInfiniteProjectileChange,     bCppMsg = true, WatchedObject = LocalPCPawn },
        }
        MsgHelper:RegisterList(self, self.MsgList_Pawn)
    end

    self:UpdateThrowableInfo(self.LocalPC)
end

function ThrowSkillInfo:UpdateThrowableInfo(InLocalPC)
    if not InLocalPC then return end
    local TempBagComp = UE.UBagComponent.Get(InLocalPC)
    if not TempBagComp then return end
    local CurrentThrowableSlot, ExistSlot = TempBagComp:GetItemSlotByTypeAndSlotID(ItemSystemHelper.NItemType.Throwable, 1)
    if ExistSlot then
        if CurrentThrowableSlot.InventoryIdentity.ItemID ~= 0 then
            self.CurrentItemID = CurrentThrowableSlot.InventoryIdentity.ItemID
            self.WidgetSwitcherThrow:SetActiveWidgetIndex(1)
            self:UpdateThrowableInfoInner(InLocalPC, CurrentThrowableSlot)
        else
            self:SetEmptyState()
        end
    end
end

function ThrowSkillInfo:SetEmptyState()
    self.WidgetSwitcherThrow:SetActiveWidgetIndex(0)
    self.WidgetSwitcherNum:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function ThrowSkillInfo:UpdateTargetInventoryItemSlot(InLocalPC, InInventoryItemSlot)
    if InInventoryItemSlot.InventoryIdentity.ItemID ~= 0 then
        self.CurrentItemID = InInventoryItemSlot.InventoryIdentity.ItemID
        self.WidgetSwitcherThrow:SetActiveWidgetIndex(1)
        self:UpdateThrowableInfoInner(InLocalPC, InInventoryItemSlot)
    else
        self.WidgetSwitcherThrow:SetActiveWidgetIndex(0)
        self.WidgetSwitcherNum:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function ThrowSkillInfo:UpdateThrowableInfoInner(InLocalPC, InInventoryItemSlot)
    if not UE.UKismetSystemLibrary.IsValid(InLocalPC) then return end
    local TempCharacter = InLocalPC:GetPawn()
    if not TempCharacter then return end
    local TempEquipmentComp = UE.UEquipmentStatics.GetEquipmentComponent(TempCharacter)
    if not TempEquipmentComp then return end
    local TempBagComp = UE.UBagComponent.Get(InLocalPC)
    if not TempBagComp then return end
    self.WidgetSwitcherNum:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    local TempIsInfiniteProjectile = self:GetInfinitePotion(InLocalPC)
    if TempIsInfiniteProjectile then
        -- 显示无限
        self.WidgetSwitcherNum:SetActiveWidgetIndex(1)
    else
        -- 显示数字
        self.WidgetSwitcherNum:SetActiveWidgetIndex(0)

        -- 显示个数
        local ThrowNumber = 0
        if InInventoryItemSlot.InventoryIdentity.ItemID ~= 0 then
            ThrowNumber = TempBagComp:GetItemNumByItemID(InInventoryItemSlot.InventoryIdentity.ItemID)
            local StrSlotImagePath, ExistStrSlotImagePath = UE.UItemSystemManager.GetItemDataFString(
                InLocalPC, InInventoryItemSlot.InventoryIdentity.ItemID, "SlotImage", GameDefine.NItemSubTable.Ingame,"ThrowSkillInfo:UpdateThrowableInfoInner")
            if ExistStrSlotImagePath then
                local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(StrSlotImagePath)
                self.ImgIconThrow:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
            end
        end
        
        self.TxtNumThrow:SetText(tostring(ThrowNumber))
        if ThrowNumber > 0 then
            self.TxtNumThrow:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        else
            self:SetEmptyState()
        end
    end
end

function ThrowSkillInfo:OnInfiniteProjectileChange(InOnOff)
    if InOnOff then
        self.WidgetSwitcherNum:SetActiveWidgetIndex(1)
    else
        self.WidgetSwitcherNum:SetActiveWidgetIndex(0)
    end
end

function ThrowSkillInfo:GetInfinitePotion(InLocalPC)
    if not InLocalPC then
        return false
    end

    local CurrentPawn = InLocalPC:K2_GetPawn()
    if CurrentPawn then
        local TempASC = CurrentPawn:GetGameAbilityComponent()
        if TempASC then
            local TempInfiniteProjectileAbilityTag = UE.FGameplayTag()
            TempInfiniteProjectileAbilityTag.TagName = GameDefine.NTag.ABILITY_INFINITE_PROJECTILE
            local HasInfinitePotionAbilityTag = TempASC:HasMatchingGameplayTag(TempInfiniteProjectileAbilityTag)
            return HasInfinitePotionAbilityTag
        end
    end

    return false
end

-------------------------------------------- Callable ------------------------------------

function ThrowSkillInfo:OnLocalPCUpdatePawn(InLocalPC, InPCPwn)
    if self.LocalPC == InLocalPC then
        self:InitPlayerPawnInfo()
    end
end

-- 是否在选择投掷物中
function ThrowSkillInfo:OnOpenSelectItem(InMsgBody)
    if InMsgBody and (InMsgBody.Type == ESelectItemType.Throw) then
        local NewVisible = (InMsgBody.bEnable) and
            UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
         self.ImgConsumeActive:SetVisibility(NewVisible)
    end
end

-- 物品数据改变
function ThrowSkillInfo:OnInventoryItemSlotChangeThrowable(InBagComponentOwner, InInventoryItemSlot)
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempLocalPC == InBagComponentOwner then
        self:UpdateTargetInventoryItemSlot(InBagComponentOwner, InInventoryItemSlot)
    end
end

-- 背包物品个数改变
function ThrowSkillInfo:OnInventoryItemNumChangeTotal(In_FGMPMessage_InventoryItemChange_Total)
    local CurrentItemID = In_FGMPMessage_InventoryItemChange_Total.ItemID
    local CurrentItemTotalNum = In_FGMPMessage_InventoryItemChange_Total.ItemTotalNum
    if self.CurrentItemID and self.CurrentItemID == CurrentItemID then
        self:UpdateThrowableInfo(self.LocalPC)
    end
end

function ThrowSkillInfo:OnInventoryItemSlotReset(InBagComponentOwner, InInventoryItemSlot)
    if not InBagComponentOwner then
        return
    end

    if ItemSystemHelper.NItemType.Throwable == InInventoryItemSlot.ItemType then
        self:UpdateThrowableInfo(self.LocalPC)
    end
end

return ThrowSkillInfo
