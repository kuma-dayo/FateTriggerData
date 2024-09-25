--
-- 战斗界面Helper
--
-- @COMPANY	ByteDance
-- @AUTHOR	曾伟
-- @DATE	2022.11.04
--

local SelectItemHelper = _G.SelectItemHelper or {}

------------------------------------------- Config/Enum ------------------------------------

------------------------------------------- Function ----------------------------------------

-- 根据物品类型获取对应的选择物品配置表
function SelectItemHelper.GetSelectItemIdMap(InTarget,InModeId,InSelectItemType)
	print("SelectItemHelper.GetSelectItemIdMap	InTarget:", InTarget,"InModeId:",InModeId,"InSelectItemType:",InSelectItemType)
	local MiscSystem = UE.UMiscSystem.GetMiscSystem(InTarget)
	if not MiscSystem then
		return
	end
	local IsSucceed,TargetData = MiscSystem:BPFunction_GetTargetModeData(InModeId,InSelectItemType)
	print("SelectItemHelper.GetSelectItemIdMap	IsSucceed,TargetData:", IsSucceed,TargetData,IsSucceed and TargetData:Length() or -1)
	return IsSucceed and TargetData or nil
end

--获取该类型物品的总数
function SelectItemHelper.GetDefaultItemNum(InTarget,InModeId,InSelectItemType)
	local TargetData = SelectItemHelper.GetSelectItemIdMap(InTarget,InModeId,InSelectItemType)
	print("SelectItemHelper.GetDefaultItemNum	TargetIndex:",TargetData)
	return TargetData and TargetData:Length() or -1
end

-- 根据物品id获取对应的物品类型
function SelectItemHelper.GetItemTypeByItemId(InItemId)
	print("SelectItemHelper.GetItemTypeByItemId	InItemId:", InItemId)
	local ItemType = nil
	for Type, ItemIdTable in pairs(SelectItemHelper.SelectConfig) do      		
		for TableIndex, ItemIdDetail in pairs(ItemIdTable) do
			if ItemIdDetail.ItemId == InItemId then
				ItemType = Type
				print("SelectItemHelper.GetItemTypeByItemId	Target Item Type is:", ItemType)
				break
			end
		end
	end
	return ItemType
end

-- 根据物品id获取该物品在配置表中的顺序，也就是index索引
function SelectItemHelper.GetItemIndexByItemId(InTarget,InModeId,InItemId)
	print("SelectItemHelper.GetItemTypeByItemId	InTarget:", InTarget,"InModeId:",InModeId,"InSelectItemType:",InItemId)
	local MiscSystem = UE.UMiscSystem.GetMiscSystem(InTarget)
	if not MiscSystem then
		return
	end
	local IsSucceed,TargetIndex = MiscSystem:BPFunction_GetTargetItemIndex(InModeId,InItemId)
	print("SelectItemHelper.GetItemTypeByItemId	IsSucceed:",IsSucceed,"TargetIndex:",TargetIndex)
	return IsSucceed and TargetIndex or -1
end

function SelectItemHelper.GetSelectItemDisplayStyle(InTarget,InModeId,InSelectItemType)
	print("SelectItemHelper.GetSelectItemDisplayStyle InTarget:", InTarget,"InModeId:",InModeId,"InSelectItemType:",InSelectItemType)
	local MiscSystem = UE.UMiscSystem.GetMiscSystem(InTarget)
	if not MiscSystem then
		return
	end
	local IsSucceed, TargetTexture, TargetBrush, TargetMargin = MiscSystem:BPFunction_GetTargetDisplayStyle(InModeId,InSelectItemType)
	print("SelectItemHelper.GetSelectItemIdMap	IsSucceed,TargetData:", IsSucceed, " TargetMargin:", TargetMargin)
	return IsSucceed and TargetTexture or nil, IsSucceed and TargetBrush or nil, IsSucceed and TargetMargin or nil
end

------------------------------------------- Debug ----------------------------------------



------------------------------------------- Require ----------------------------------------

_G.SelectItemHelper = SelectItemHelper
return SelectItemHelper
