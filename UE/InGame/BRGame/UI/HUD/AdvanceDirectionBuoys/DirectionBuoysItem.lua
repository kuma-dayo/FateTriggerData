local DirectionBuoysItem = Class("Common.Framework.UserWidget")
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

function DirectionBuoysItem:OnInit()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    print("DirectionBuoysItem >> OnInit, ", GetObjectName(self))
    self.OtherSlateColor = UE.FSlateColor()
	UserWidget.OnInit(self)
end

function DirectionBuoysItem:GetLocalPCPawnLoc()
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)

	if (not LocalPCPawn) then 
        return nil
    end

    return LocalPCPawn:K2_GetActorLocation()
end

function DirectionBuoysItem:BPNativeFunc_OnCustomUpdate(InTaskData)
    
    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackBoardKeySelector.SelectedKeyName = "ItemId"
    local ItemId, ItemIdType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(InTaskData.OtherData, BlackBoardKeySelector)

	if ItemIdType then
		self.ItemId = ItemId
    else
        print("BuoysItem:BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark does not have ItemId!")
        return
	end

    -- 处理类型
	local CurItemType, IsFindType = UE.UItemSystemManager.GetItemDataFName(self, self.ItemId, "ItemType",
    GameDefine.NItemSubTable.Ingame, "BuoysItem.BPImpFunc_On3DMarkIconCustomUpdateFrom3DMark")

    local PickupItemId = self.ItemId
    local PickupItemIdStr = tostring(PickupItemId)

    local TableManagerSubsystem = UE.UTableManagerSubsystem.GetTableManagerSubsystem(self)
    local SubTable = TableManagerSubsystem:GetItemCategorySubTableByItemID(PickupItemId, "Ingame")

    if SubTable then
        local ItemLevel, bValidLevel = SubTable:BP_FindDataUInt8(PickupItemIdStr, "ItemLevel")
        if CurItemType ~= "Weapon" then
            --获得物品品质信息
            local NewLinearColor = bValidLevel and AdvanceMarkHelper.GetMarkItemQualityColor(self, ItemLevel) or
                UIHelper.LinearColor.White
            -- 设置背景框颜色
            if NewLinearColor then
                -- 控件颜色都设置好NewLinearColor
                self:UpdateWidgetColor(NewLinearColor)
            end
        end
    end
end

-- 更新控件颜色
function DirectionBuoysItem:UpdateWidgetColor(InNewLinearColor)
    if self.Image_Bg then
        if not self.NewSlateColor then
            self.NewSlateColor = UE.FSlateColor()
        end
        self.NewSlateColor.SpecifiedColor = InNewLinearColor
        self.Image_Bg:SetColorAndOpacity(InNewLinearColorr)
    end
	--print("BuoysMarkSysPointItem", ">> UpdateWidgetColor, ...", GetObjectName(self))
end


return DirectionBuoysItem