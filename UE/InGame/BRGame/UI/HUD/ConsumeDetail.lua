
require ("InGame.BRGame.UI.HUD.BattleUIHelper")

local ConsumeDetail = Class("Common.Framework.UserWidget")

local ESelectItemType = UE.ESelectItemType

-------------------------------------------- Init/Destroy ------------------------------------

function ConsumeDetail:OnInit()
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

    self.TxtConsumeCD:SetVisibility(UE.ESlateVisibility.Collapsed)
    --self.DefaultTextureNone = self.ImgConsumeIcon_None.Brush.ResourceObject

    self:UpdatePotionInfo(self.LocalPC)
    self:InitPlayerPawnInfo()

    -- 绑定角色数据消息
    self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.PC_UpdatePlayerPawn,          Func = self.OnLocalPCUpdatePawn,            bCppMsg = true,     WatchedObject = self.LocalPC },
        { MsgName = GameDefine.Msg.PLAYER_OpenSelectItem,           Func = self.OnOpenSelectItem,               bCppMsg = false,    WatchedObject = nil },
        { MsgName = GameDefine.Msg.InventoryItemNumChangeTotal,     Func = self.OnInventoryItemNumChangeTotal,  bCppMsg = true,     WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Change_Potion,                Func = self.OnInventoryItemSlotChangePotion,              bCppMsg = true,     WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.INVENTORY_InventoryItemSlot_Reset, Func = self.OnInventoryItemSlotReset, bCppMsg = true, WatchedObject = nil },
    }

	UserWidget.OnInit(self)
    self.CurrentTime = 0
    self.Totaltime = 0
end

function ConsumeDetail:OnDestroy()
    MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})
    self.MsgList_Pawn = nil
    self.CurrentItemID = nil
	UserWidget.OnDestroy(self)
end

function ConsumeDetail:OnLocalPCUpdatePawn(InLocalPC, InPCPwn)
	if self.LocalPC == InLocalPC then
		self:InitPlayerPawnInfo()
	end
end

function ConsumeDetail:InitPlayerPawnInfo()
    self.ProgressBar_Consume:SetPercent(0)
    self.Rate = 0.0167
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
	if LocalPCPawn then
        -- 重置玩家状态
        self:OnEndDying(nil)

        -- 监听对象消息
        MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})
        self.MsgList_Pawn = {
            { MsgName = GameDefine.MsgCpp.PLAYER_OnBeginDying,  Func = self.OnBeginDying,   bCppMsg = true, WatchedObject = LocalPCPawn },
            { MsgName = GameDefine.MsgCpp.PLAYER_OnEndDying,    Func = self.OnEndDying,     bCppMsg = true, WatchedObject = LocalPCPawn },
            { MsgName = GameDefine.MsgCpp.PLAYER_GenericItemUseProgress,    Func = self.OnUseConsume,     bCppMsg = true, WatchedObject = LocalPCPawn },
            { MsgName = GameDefine.MsgCpp.BAG_InventoryItemInfinitePotion,    Func = self.OnInfinitePotionChange,     bCppMsg = true, WatchedObject = LocalPCPawn },
        }
        MsgHelper:RegisterList(self, self.MsgList_Pawn)
    end
end


-------------------------------------------- Function ------------------------------------


function ConsumeDetail:UpdatePotionInfo(InLocalPC)
    if not InLocalPC then return end
    local BagComp = UE.UBagComponent.Get(InLocalPC)
    if not BagComp then return end
    local CurrentPotionSlot, ExistSlot = BagComp:GetItemSlotByTypeAndSlotID(ItemSystemHelper.NItemType.Potion, 1)
    if ExistSlot and CurrentPotionSlot.InventoryIdentity.ItemID ~= 0 then
        print("ConsumeDetail:UpdatePotionInfo ItemId:", CurrentPotionSlot.InventoryIdentity.ItemID)
        self.CurrentItemID = CurrentPotionSlot.InventoryIdentity.ItemID
        self.WidgetSwitcherItem:SetActiveWidgetIndex(1)
        self:UpdatePotionInfoInner(InLocalPC, CurrentPotionSlot)
    else
        -- 显示物品图片
        self.WidgetSwitcherItem:SetActiveWidgetIndex(0)
        self.WidgetSwitcherNum:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end


function ConsumeDetail:UpdatePotionInventoryItemSlot(InLocalPC, InInventoryItemSlot)
    if not InLocalPC then return end
    local BagComp = UE.UBagComponent.Get(InLocalPC)
    if not BagComp then return end
    if InInventoryItemSlot.InventoryIdentity.ItemID ~= 0 then
        self.CurrentItemID = InInventoryItemSlot.InventoryIdentity.ItemID
        self.WidgetSwitcherItem:SetActiveWidgetIndex(1)
        self:UpdatePotionInfoInner(InLocalPC, InInventoryItemSlot)
    else
        -- 显示物品图片
        self.WidgetSwitcherItem:SetActiveWidgetIndex(0)
        self.WidgetSwitcherNum:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end



function ConsumeDetail:GetInfinitePotion(InLocalPC)
    if not InLocalPC then
        return false
    end

    local CurrentPawn = InLocalPC:K2_GetPawn()
    if CurrentPawn then
        local TempASC = CurrentPawn:GetGameAbilityComponent()
        if TempASC then
            local TempInfinitePotionAbilityTag = UE.FGameplayTag()
            TempInfinitePotionAbilityTag.TagName = GameDefine.NTag.ABILITY_INFINITE_POTION
            local HasInfinitePotionAbilityTag = TempASC:HasMatchingGameplayTag(TempInfinitePotionAbilityTag)
            return HasInfinitePotionAbilityTag
        end
    end

    return false
end


-- 更新药品信息
function ConsumeDetail:UpdatePotionInfoInner(InLocalPC, InInventoryItemSlot)
    if not UE.UKismetSystemLibrary.IsValid(InLocalPC) then
        self:CollapsedItemWidget()
        return
    end
    local TempCharacter = InLocalPC:GetPawn()
    if not TempCharacter then
        self:CollapsedItemWidget()
        return
    end
    local TempEquipmentComp = UE.UEquipmentStatics.GetEquipmentComponent(TempCharacter)
    if not TempEquipmentComp then
        self:CollapsedItemWidget()
        return
    end
    local TempBagComp = UE.UBagComponent.Get(InLocalPC)
    if not TempBagComp then
        self:CollapsedItemWidget()
        return
    end

    print("ConsumeDetail:UpdatePotionInfoInner")
    self.WidgetSwitcherNum:SetVisibility(UE.ESlateVisibility.HitTestInvisible)

    -- 设置图片
    local StrSlotImagePath, ExistStrSlotImagePath = UE.UItemSystemManager.GetItemDataFString(InLocalPC, InInventoryItemSlot.InventoryIdentity.ItemID, "SlotImage",GameDefine.NItemSubTable.Ingame,"SkillInfo:InitBagInfo")
    if ExistStrSlotImagePath then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(StrSlotImagePath)
        self.ImgConsumeIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, false)
    end

    local TempIsInfinitePotion = self:GetInfinitePotion(InLocalPC)
    if TempIsInfinitePotion then
        -- 显示无限
        self.WidgetSwitcherNum:SetActiveWidgetIndex(1)
    else
        -- 显示数字
        self.WidgetSwitcherNum:SetActiveWidgetIndex(0)

        -- 得到数字，设置数字
        local PotionNumber = TempBagComp:GetItemNumByItemID(InInventoryItemSlot.InventoryIdentity.ItemID)
        if PotionNumber then
            self.TxtConsumeNum:SetText(tostring(PotionNumber))
        end
    end
end

function ConsumeDetail:CollapsedItemWidget()
    print("ConsumeDetail:CollapsedItemWidget Update ItemInfo Failed")
    self.WidgetSwitcherItem:SetActiveWidgetIndex(0)
    self.WidgetSwitcherNum:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function ConsumeDetail:OnInfinitePotionChange(InOnOff)
    if InOnOff then
        self.WidgetSwitcherNum:SetActiveWidgetIndex(1)
    else
        self.WidgetSwitcherNum:SetActiveWidgetIndex(0)
    end
end

--[[
    濒死/救援
    InParamters: { 
        DyingInfo(FS1LifetimeDyingInfo):  { bIsDying, DyingCounter, DeadCountdownTime }
    }
]]
function ConsumeDetail:UpdateDyingState(InParamters)
    if not InParamters then return end
    local NewVisible1 = InParamters.bIsDying and
        UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.HitTestInvisible
    self.TrsConsumeDetail:SetVisibility(NewVisible1)--
end

-- 是否在选择药品
function ConsumeDetail:OnOpenSelectItem(InMsgBody) --
    if InMsgBody and (InMsgBody.Type == ESelectItemType.Medicines) then
        local NewVisible = (InMsgBody.bEnable) and
			UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
		self.ImgConsumeActive:SetVisibility(NewVisible) --
    end
end

-- 插槽数据改变
function ConsumeDetail:OnInventoryItemSlotChangePotion(InBagComponentOwner, InInventoryItemSlot)
    local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if TempLocalPC ~= InBagComponentOwner then return end
    self:UpdatePotionInventoryItemSlot(TempLocalPC, InInventoryItemSlot);
end

-- 背包物品个数改变
function ConsumeDetail:OnInventoryItemNumChangeTotal(In_FGMPMessage_InventoryItemChange_Total)
    local CurrentItemID = In_FGMPMessage_InventoryItemChange_Total.ItemID
    if self.CurrentItemID and self.CurrentItemID == CurrentItemID then
        local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
        self:UpdatePotionInfo(TempLocalPC)
    end
end


function ConsumeDetail:OnBeginDying(InDyingMessageInfo)
    self.bIsDying = InDyingMessageInfo.DyingInfo.bIsDying
    self:UpdateDyingState({ DyingInfo = InDyingMessageInfo.DyingInfo })
end

function ConsumeDetail:OnEndDying(InDyingMessageInfo)
    local DyingInfo = UE.FS1LifetimeDyingInfo()
    DyingInfo.bIsDying = false
    self.bIsDying = DyingInfo.bIsDying
    self:UpdateDyingState({ DyingInfo = DyingInfo })
end

function ConsumeDetail:OnUseConsume(TotalTime,ItemText)
    print("ConsumeDetail:OnUseConsume TotalTime",TotalTime,"ItemText",ItemText)
    if(TotalTime<0) then
        --打断吃药，清Timer且进度条回0
        self.ProgressBar_Consume:SetPercent(0)
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.HoldTimer)
        self.HoldTimer =nil
    else
        --开始吃药,设置timer
        self.CurrentTime = 0
        self.Totaltime = TotalTime
        self.HoldTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.UpdateProgressBar}, self.Rate, true, 0, 0)
    end
end
function ConsumeDetail:UpdateProgressBar()
  
    if self.CurrentTime > self.Totaltime then
        self.ProgressBar_Consume:SetPercent(0)
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.HoldTimer)
        self.HoldTimer = nil
    else
        
        self.CurrentTime = self.CurrentTime + self.Rate
        self.ProgressBar_Consume:SetPercent(self.CurrentTime / self.Totaltime)   
        --print("ConsumeDetail:OnUseConsume CurrentTime", self.CurrentTime,"Percent",self.CurrentTime / self.Totaltime)
    end
end

function ConsumeDetail:OnInventoryItemSlotReset(InBagComponentOwner, InInventoryItemSlot)
    if not InBagComponentOwner then
        return
    end

    if ItemSystemHelper.NItemType.Potion == InInventoryItemSlot.ItemType then
        local TempLocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
        self:UpdatePotionInventoryItemSlot(TempLocalPC, InInventoryItemSlot)
    end
end

return ConsumeDetail
