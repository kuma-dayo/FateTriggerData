require ("Common.Utils.StringUtil")

local SelectConsumableItemProxy = Class()

-------------------------------------------- Interface ------------------------------------
function SelectConsumableItemProxy:Init(InOwner)
	print("xuyanzu InitInitInitInit")
	self.WidgetOwner = InOwner
end

function SelectConsumableItemProxy.GetTexture2D(WidgetOwner,Index)
	return SelectConsumableItemProxy.GetIconFromTable(WidgetOwner,Index)
end
function SelectConsumableItemProxy.UpdateSelectName(WidgetOwner,Index)
	return SelectConsumableItemProxy.GetItemNameFromTable(WidgetOwner,Index)
end
function SelectConsumableItemProxy.UpdateSelectDescribe(WidgetOwner,Index)
	return SelectConsumableItemProxy.GetItemDescFromTable(WidgetOwner,Index)
end
function SelectConsumableItemProxy.TriggerOperation(WidgetOwner,ItemId)
	SelectConsumableItemProxy.ItemSkillSwitchUIAndEquip(WidgetOwner, ItemId)
end

function SelectConsumableItemProxy.GetNumDetail(InOwner, ItemId)
	print("SelectConsumableItemProxy.GetNumDetail InOwner:",InOwner, "ItemId:", ItemId)
    local LocalPCBag = UE.UBagComponent.Get(InOwner:GetOwningPlayer())
    local ItemNum = LocalPCBag:GetItemNumByItemID(ItemId)	-- 这个InOwner必须是个widget
	local bCanUseItem = (ItemNum and ItemNum > 0)
    local NewColor = bCanUseItem and UIHelper.LinearColor.White or UIHelper.LinearColor.DarkGrey

	return ItemNum,UIHelper.ToSlateColor_LC(NewColor)
end

function SelectConsumableItemProxy.GetNameDetail(InOwner, ItemId)
	return nil,nil
end

function SelectConsumableItemProxy.GetInfiniteDetail(InOwner, ItemId)
	local LocalPC = UE.UGameplayStatics.GetPlayerController(InOwner, 0)

	if not LocalPC then
        return false
    end

    local CurrentItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(LocalPC, ItemId, "ItemType", GameDefine.NItemSubTable.Ingame, "SelectConsumableItemProxy.GetInfiniteDetail")
	if not IsFindItemType then
        return false
    end

    local CurrentPawn = LocalPC:K2_GetPawn()
    if CurrentPawn then
        local TempASC = CurrentPawn:GetGameAbilityComponent()
        if TempASC then
            local TempInfiniteAbilityTag = UE.FGameplayTag()
			if CurrentItemType == ItemSystemHelper.NItemType.Potion then
				TempInfiniteAbilityTag.TagName = GameDefine.NTag.ABILITY_INFINITE_POTION
			elseif CurrentItemType == ItemSystemHelper.NItemType.Throwable then
				TempInfiniteAbilityTag.TagName = GameDefine.NTag.ABILITY_INFINITE_PROJECTILE
			else
				return false
			end

            local HasInfinitePotionAbilityTag = TempASC:HasMatchingGameplayTag(TempInfiniteAbilityTag)
            return HasInfinitePotionAbilityTag
        end
    end

	return false
end

function SelectConsumableItemProxy.GetLayoutVisibility(InOwner, ItemId)
	local NameVis,DescribeVis,LVis,MVis,RVis
	RVis = UE.ESlateVisibility.HitTestInvisible
	MVis = UE.ESlateVisibility.Collapsed
	if ItemId then
		NameVis = UE.ESlateVisibility.HitTestInvisible
		DescribeVis = UE.ESlateVisibility.HitTestInvisible
		LVis = UE.ESlateVisibility.HitTestInvisible
	else
		NameVis = UE.ESlateVisibility.Collapsed
		DescribeVis = UE.ESlateVisibility.Collapsed
		LVis = UE.ESlateVisibility.Collapsed
	end
	return  NameVis,DescribeVis,LVis,MVis,RVis
end
--return res1：是否Trigger res2：是否Handled
function SelectConsumableItemProxy.ShouldTriggerOperation(InOwner, MouseKey, IsMouseDown)
	print("ShouldTriggerOperation",MouseKey)
	if MouseKey == "LeftMouseButton" and IsMouseDown then
		return true,true
	end
	return false,true
end

function SelectConsumableItemProxy.ShouldClose(InOwner, MouseKey, IsMouseDown)
	return true
end

function SelectConsumableItemProxy.TriggerClose(InOwner, ItemId)
	local ItemType, IsFindItemType = UE.UItemSystemManager.GetItemDataFName(InOwner, ItemId, "ItemType", GameDefine.NItemSubTable.Ingame,"SelectConsumableItemProxy.ItemSkillSwitchUI")
	if ItemType == "Throwable" then
		SelectConsumableItemProxy.ThrowalbeItemSkillSwitchUIAndEquip(InOwner, ItemId)
	else
		SelectConsumableItemProxy.ItemSkillSwitchUI(InOwner, ItemId)
	end
end
-- 切换道具插槽装备的道具
function SelectConsumableItemProxy.ItemSkillSwitchUI(InOwner, ItemId)
	-- TODO start :这段可以封装
	local TempPlayerController = UE.UGameplayStatics.GetPlayerController(InOwner, 0)
	local TempBagComp = UE.UBagComponent.Get(TempPlayerController)
	if not TempBagComp then return end
	local TempInventoryInstanceArray = TempBagComp:GetAllItemObjectByItemID(ItemId)
	if not TempInventoryInstanceArray then return end
	if TempInventoryInstanceArray:Num()<1 then return end
	local FirstInventoryInstance = TempInventoryInstanceArray:Get(1)
	if not FirstInventoryInstance then return end
	-- TODO end :这段可以封装

	FirstInventoryInstance:RequestUseItem(ItemSystemHelper.NUsefulReason.SwitchEquipItem)
end

-- 切换道具插槽装备的道具，并且立刻切出
function SelectConsumableItemProxy.ItemSkillSwitchUIAndEquip(InOwner, ItemId)

	-- TODO start :这段可以封装
	local TempPlayerController = UE.UGameplayStatics.GetPlayerController(InOwner, 0)
	local TempBagComp = UE.UBagComponent.Get(TempPlayerController)
	if not TempBagComp then return end
	local TempInventoryInstanceArray = TempBagComp:GetAllItemObjectByItemID(ItemId)
	if not TempInventoryInstanceArray then return end
	if TempInventoryInstanceArray:Num()<1 then return end
	local FirstInventoryInstance = TempInventoryInstanceArray:Get(1)
	-- TODO end :这段可以封装

	if FirstInventoryInstance and FirstInventoryInstance.ClientUseSkill then
		FirstInventoryInstance:ClientUseSkill()
	end
end

-- 切换道具插槽装备的道具，并且立刻切出
function SelectConsumableItemProxy.ThrowalbeItemSkillSwitchUIAndEquip(InOwner, ItemId)

	-- TODO start :这段可以封装
	local TempPlayerController = UE.UGameplayStatics.GetPlayerController(InOwner, 0)
	local TempBagComp = UE.UBagComponent.Get(TempPlayerController)
	if not TempBagComp then return end
	local TempInventoryInstanceArray = TempBagComp:GetAllItemObjectByItemID(ItemId)
	if not TempInventoryInstanceArray then return end
	if TempInventoryInstanceArray:Num()<1 then return end
	local FirstInventoryInstance = TempInventoryInstanceArray:Get(1)
	-- TODO end :这段可以封装

	if FirstInventoryInstance and FirstInventoryInstance.ClientJustTryEquipSkill then
		FirstInventoryInstance:ClientJustTryEquipSkill()
	end
end

-------------------------------------------- Get/Set ------------------------------------

function SelectConsumableItemProxy.GetIconFromTable(WidgetOwner,ItemId)
    local ItemIdString = tostring(ItemId)
    local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(WidgetOwner)
    local ItemSubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(ItemId, "Ingame")
    if ItemSubTable then
        local ItemIcon, bValidItemIcon = ItemSubTable:BP_FindDataFString(ItemIdString, "ItemIcon")
        --print("SelectItemInfo", ">> InitData, ", ItemId, ItemIcon, bValidItemIcon)
        if bValidItemIcon then
            return ItemIcon
        end
    end
	return nil
end
function SelectConsumableItemProxy.GetItemNameFromTable(WidgetOwner,ItemId)
	if not WidgetOwner then
		return ""
	end

	if not ItemId then
		return ""
	end

	local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(WidgetOwner, ItemId)
	if not IngameDT then
		return ""
	end

	local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(ItemId))
	if not StructInfo_Item then
		return ""
	end
	
	local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)
	return TranslatedItemName
end
function SelectConsumableItemProxy.GetItemDescFromTable(WidgetOwner,ItemId)
    local ItemIdString = tostring(ItemId)

    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(WidgetOwner, ItemId)
    if not IngameDT then
        return ""
    end
    
    local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, ItemIdString)
    if not StructInfo_Item then
        return ""
    end

    local TranslatedItemName = StringUtil.Format(StructInfo_Item.SimpleDescribe)
    return TranslatedItemName
end
return SelectConsumableItemProxy
