--
-- 标记系统Helper

local AdvanceMarkHelper = {}
local MiscSystem = UE.UMiscSystem.GetMiscSystem(GameInstance)

if MiscSystem then
    AdvanceMarkHelper.TeamPosColor = MiscSystem.TeamColors
    AdvanceMarkHelper.MarkIconColor = MiscSystem.MarkIconColor
end

function AdvanceMarkHelper.InitData(Context)
    if not AdvanceMarkHelper.TeamPosColor then
		local MiscSystem = UE.UMiscSystem.GetMiscSystem(Context)
		if MiscSystem then
			AdvanceMarkHelper.TeamPosColor = MiscSystem.TeamColors
			AdvanceMarkHelper.MarkIconColor = MiscSystem.MarkIconColor
		end
	end
end

function AdvanceMarkHelper.GetMarkLogToChatDisplay(Context, MarkLogValue)

    local AdvMarkSystem = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(Context)

    if AdvMarkSystem then
        local MarkLogTex = AdvMarkSystem.MarkLogText:FindRef(MarkLogValue)
        if nil == MarkLogTex then
            print("AdvanceMarkHelper.GetMarkLogToChatDisplay does not have AdvMarkSystem.MarkLogText[MarkLogValue]!")
        else
            return MarkLogTex
        end
    end
    return "ErrorMarkLog Check AdvanceBussinesss!"
end

function AdvanceMarkHelper.GetMarkLogToChatDisplaySafe(Context, MarkLogValue)

    local AdvMarkSystem = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(Context)

    if AdvMarkSystem then
        local MarkLogTex = AdvMarkSystem.MarkLogText:FindRef(MarkLogValue)
        if nil == MarkLogTex then
            print("AdvanceMarkHelper.GetMarkLogToChatDisplay does not have AdvMarkSystem.MarkLogText[MarkLogValue]!")
        else
            return MarkLogTex
        end
    end
end

function AdvanceMarkHelper.GetMarkLogItemName(Context, ItemID)
    local StrItemID = tostring(ItemID)
    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(Context, ItemID)
    if not IngameDT then
        return
    end
    local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, StrItemID)
    if not StructInfo_Item then
        return ""
    end

    local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)

    return TranslatedItemName
end

-- 获取芯片名字
function AdvanceMarkHelper.GetMarkEnhanveItemName(Context, InEnhanceId)

    local TempGameplayTag = UE.FGameplayTag()
    TempGameplayTag.TagName = GameDefine.NTag.TABLE_EnhanceAttribute
    -- 查找表资源
    local TempEnhanceAttributeDT = UE.UTableManagerSubsystem.GetDataTableByTag(Context, TempGameplayTag)
    if TempEnhanceAttributeDT then
        -- 查找表的某行
        local StructInfoEnhanceAttr = UE.UDataTableFunctionLibrary.GetRowDataStructure(TempEnhanceAttributeDT, tostring(InEnhanceId))
        if StructInfoEnhanceAttr then
            -- 查找强化词条图片
            local EnhanceName = StructInfoEnhanceAttr.EnhanceName
            
            return EnhanceName
        end
    end
end

function AdvanceMarkHelper.GetMarkLogItemTypeName(Context, ItemID, bReturnItemType)
    local StrItemID = tostring(ItemID)
    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(Context, ItemID)
    if not IngameDT then
        return ""
    end

    local ItemType, RetItemType = IngameDT:BP_FindDataFName(StrItemID, "ItemType")
    if RetItemType and bReturnItemType then return ItemType end

    if RetItemType then
        local TempItemTypeName = UE.UTableManagerSubsystem.GetIngameItemTypeName(Context, ItemType)
        local TranslatedItemTypeName = StringUtil.Format(TempItemTypeName)
        return TranslatedItemTypeName
    end
    
    return ""
end

function AdvanceMarkHelper.GetMarkLogItemLevelQualityColor(Context, ItemID)
    local StrItemID = tostring(ItemID)
    local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(Context, ItemID)
    if not IngameDT then
        return ""
    end

    local CurrentItemLevel, RetItemName = IngameDT:BP_FindDataUInt8(StrItemID,"ItemLevel")

    return AdvanceMarkHelper.GetMarkLogItemQualityColor(Context,CurrentItemLevel)
end

function AdvanceMarkHelper.GetMarkLogItemQualityColor(Context, MarkLogValue)

    local AdvMarkSystem = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(Context)

    if AdvMarkSystem then
        local MarkItemLogColor =  AdvMarkSystem.MarkItemLogColor:FindRef(MarkLogValue)
        if nil == MarkItemLogColor then
            print("AdvanceMarkHelper.GetMarkLogToChatDisplay does not have AdvMarkSystem.MarkItemLogColor[MarkLogValue]!")
        else
            return MarkItemLogColor
        end
    end

    return ""
end

function AdvanceMarkHelper.GetMarkLogEhanveQualityColor(Context)

    local AdvMarkSystem = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(Context)

    if AdvMarkSystem and AdvMarkSystem.MarkItemLogColor and AdvMarkSystem.MarkItemLogColor:Length() > 1 then
        local Length = AdvMarkSystem.MarkItemLogColor:Length() - 2
        local MarkItemLogColor =  AdvMarkSystem.MarkItemLogColor:FindRef(Length)
        return MarkItemLogColor
    end

    print("AdvanceMarkHelper.GetMarkLogEhanveQualityColor does not have AdvMarkSystem.MarkItemLogColor[MarkLogValue]!")
    return ""
end

function AdvanceMarkHelper.GetMarkItemQualityColor(Context, MarkLogValue)

    local AdvMarkSystem = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(Context)

    if AdvMarkSystem then
        local MarkItemLogColor =  AdvMarkSystem.MarkItemColor:FindRef(MarkLogValue)
        if nil == MarkItemLogColor then
            print("AdvanceMarkHelper.GetMarkItemQualityColor does not have AdvMarkSystem.MarkItemColor[MarkLogValue]!")
        else
            return MarkItemLogColor
        end
    end

    return ""
end

function AdvanceMarkHelper.SendMarkLog(Context, MarkLogValue)
    local AdvMarkSystem = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(Context)

    if AdvMarkSystem then
        AdvMarkSystem:MarkLogToChatDisplay(MarkLogValue)
    end
end

function AdvanceMarkHelper.SendMarkLogHelper(Context, MarkLogKey, ...)
    local LogText = AdvanceMarkHelper.GetMarkLogToChatDisplay(Context, MarkLogKey)
	if LogText then
		LogText = StringUtil.Format(LogText, ...)
		AdvanceMarkHelper.SendMarkLog(Context, LogText)
	end
end

function AdvanceMarkHelper.SendMarkLogHelperSafe(Context, MarkLogKey, ...)
    local LogText = AdvanceMarkHelper.GetMarkLogToChatDisplaySafe(Context, MarkLogKey)
	if LogText then
		LogText = StringUtil.Format(LogText, ...)
		AdvanceMarkHelper.SendMarkLog(Context, LogText)
	end
end

function AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, MarkLogKey, ...)
    local LogText = AdvanceMarkHelper.GetMarkLogToChatDisplay(BattleChatComp, MarkLogKey)
    if LogText then
        LogText = StringUtil.Format(LogText,...)
        BattleChatComp:SendMarkLogMsg(MarkLogKey, LogText)
        print(" AdvanceMarkHelper.SendMarkLogMessageHelper SendMsg LogText:", LogText)
    end  
end

function AdvanceMarkHelper.SendMarkLogMessageHelperWithItemId(Context, Itemid)
    print("AdvanceMarkHelper.SendMarkLogMessageHelperWithItemId Itemid",Itemid)
    local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(Context)
    if BattleChatComp then
        local TypeName = AdvanceMarkHelper.GetMarkLogItemTypeName(Context, Itemid, false)
        print("AdvanceMarkHelper.SendMarkLogMessageHelperWithItemId TypeName",TypeName)
        local MarkLogKey = AdvanceMarkHelper.GetMarkLogToChatDisplay(Context, TypeName)
        local PlayerController = UE.UGameplayStatics.GetPlayerController(Context, 0)
        local PlayerName
        if PlayerController.PlayerState then
            PlayerName = PlayerController.PlayerState:GetPlayerName()
        end
        if MarkLogKey then
            local LogText = StringUtil.Format(MarkLogKey, PlayerName)

            BattleChatComp:SendMarkLogMsg(MarkLogKey, LogText)
        end  
    end
end

function AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithItemId(Context, Itemid, ItemTypeName)
    local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(Context)
    if BattleChatComp then
        local TypeName = ItemTypeName or AdvanceMarkHelper.GetMarkLogItemTypeName(Context, Itemid, true)
        local ItemName = AdvanceMarkHelper.GetMarkLogItemName(Context, Itemid)
        local ItemQualityColor = AdvanceMarkHelper.GetMarkLogItemLevelQualityColor(Context, Itemid)
        TypeName = "Own"..TypeName
        local PlayerController = UE.UGameplayStatics.GetPlayerController(Context, 0)
        local PlayerName = ""
        if PlayerController.PlayerState then
            PlayerName = PlayerController.PlayerState:GetPlayerName()
        end
        AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, TypeName, PlayerName, ItemQualityColor, ItemName)
        --print(" AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithItemId SendMsg ItemTypeName:",ItemTypeName, "PlayerName",PlayerName, "ItemName", ItemName, GetObjectName(Context))
        print(" AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithItemId SendMsg TypeName:",TypeName, GetObjectName(Context))
    end
end

function AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemType(Context, ItemTypeName)
    local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(Context)
    if BattleChatComp and ItemTypeName then
        ItemTypeName = "Need"..ItemTypeName
        local PlayerController = UE.UGameplayStatics.GetPlayerController(Context, 0)
        local PlayerName = ""
        if PlayerController.PlayerState then
            PlayerName = PlayerController.PlayerState:GetPlayerName()
        end
        AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, ItemTypeName, PlayerName)
        print(" AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemType SendMsg ItemTypeName:",ItemTypeName, "PlayerName",PlayerName, GetObjectName(Context))
    end
end

function AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemTypeId(Context, ItemTypeNameId)
    local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(Context)
    local TypeName = AdvanceMarkHelper.GetMarkLogItemTypeName(Context, ItemTypeNameId, true)
    local ItemName
    if TypeName == "Bullet" then
        -- body
        ItemName = AdvanceMarkHelper.GetMarkLogItemName(Context, ItemTypeNameId)
        if BattleChatComp and TypeName then
            TypeName = "Need"..TypeName
            local PlayerController = UE.UGameplayStatics.GetPlayerController(Context, 0)
            local PlayerName = ""
            if PlayerController.PlayerState then
                PlayerName = PlayerController.PlayerState:GetPlayerName()
            end
            AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, TypeName, PlayerName, ItemName)
            print(" AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemTypeId SendMsg ItemTypeName:",TypeName, "PlayerName",PlayerName, "ItemName", ItemName, GetObjectName(Context))
        end
    else
        if BattleChatComp and TypeName then
            TypeName = "Need"..TypeName
            local PlayerController = UE.UGameplayStatics.GetPlayerController(Context, 0)
            local PlayerName = ""
            if PlayerController.PlayerState then
                PlayerName = PlayerController.PlayerState:GetPlayerName()
            end
            AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, TypeName, PlayerName)
            print(" AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemTypeId SendMsg ItemTypeName:",TypeName, "PlayerName",PlayerName, GetObjectName(Context))
        end
    end
    
end

function AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemId(Context, ItemTypeNameId)
    local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(Context)
    local TypeName = AdvanceMarkHelper.GetMarkLogItemName(Context, ItemTypeNameId)
    if BattleChatComp and TypeName then
        TypeName = "Need"..TypeName
        local PlayerController = UE.UGameplayStatics.GetPlayerController(Context, 0)
        local PlayerName = ""
        if PlayerController.PlayerState then
            PlayerName = PlayerController.PlayerState:GetPlayerName()
        end
        AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, TypeName, PlayerName)
        print(" AdvanceMarkHelper.SendNeedMarkLogMessageHelperWithItemId SendMsg ItemTypeName:",TypeName, "PlayerName",PlayerName, GetObjectName(Context))
    end
end

function AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithEnhanveAttributeId(Context, EnhanveAttributeId)
    local BattleChatComp = UE.UPlayerChatComponent.GetPlayerChatComponentClientOnly(Context)
    local TypeName
    local ItemName = AdvanceMarkHelper.GetMarkEnhanveItemName(Context, EnhanveAttributeId)
    if BattleChatComp then
        TypeName = "Own芯片"
        local PlayerController = UE.UGameplayStatics.GetPlayerController(Context, 0)
        local PlayerName = ""
        if PlayerController.PlayerState then
            PlayerName = PlayerController.PlayerState:GetPlayerName()
        end

        local EhanceQuality = AdvanceMarkHelper.GetMarkLogEhanveQualityColor(Context)

        AdvanceMarkHelper.SendMarkLogMessageHelper(BattleChatComp, TypeName, PlayerName, EhanceQuality, ItemName)
        print(" AdvanceMarkHelper.SendOwnMarkLogMessageHelperWithEnhanveAttributeId SendMsg ItemTypeName:",TypeName, "PlayerName",PlayerName, GetObjectName(Context))

    end
end


return AdvanceMarkHelper
