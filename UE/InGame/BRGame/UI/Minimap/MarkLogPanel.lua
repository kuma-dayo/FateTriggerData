



local MarkLogPanel = Class("Common.Framework.UserWidget")

function MarkLogPanel:OnInit()
    UserWidget.OnInit(self)
end

function MarkLogPanel:SetAllCollosped()
    self.BagItemInfo:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.ItemInfo:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.EnemyInfo:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.PlaceInfo:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.SkillInfo:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.SomeOneComeHere:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.NoticeDefense:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function MarkLogPanel:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackBoardKeySelector.SelectedKeyName ="Type"

    local MarkType, OutMarkTypeType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(TipGenricBlackboard, BlackBoardKeySelector)
    
    BlackBoardKeySelector.SelectedKeyName ="PlayState"

    local PlayerState, OutPlayerNameType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsObject(TipGenricBlackboard, BlackBoardKeySelector)

    if not UE.UKismetSystemLibrary.IsValid(PlayerState) then
        return
    end

    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

    print("MarkLogPanel:OnTipsInitialize", GetObjectName(self), GetObjectName(PlayerState))

    -- 是否是自己的标记信息
    local bIfSelfMarkLog = PlayerState == LocalPC.PlayerState
    local PlayerName = PlayerState:GetPlayerName()

    print("MarkLogPanel:OnTipsInitialize", GetObjectName(self),"ItemTypeName is ",tostring(MarkType))

    if MarkType == UE.EMarkDataType.InBagItem then
        self.BagItemInfoTextPlayerName:SetText(PlayerName)
        BlackBoardKeySelector.SelectedKeyName ="bIfOwn"

        local bIfOwn, OutPlayerNameType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBool(TipGenricBlackboard, BlackBoardKeySelector)

        if bIfOwn then
            BlackBoardKeySelector.SelectedKeyName ="ItemId"

            local ItemId, OutPlayerNameType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(TipGenricBlackboard, BlackBoardKeySelector)
            local StrItemID = tostring(ItemId)
            local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, ItemId)
            if not IngameDT then
                return
            end

            local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, StrItemID)
            if not StructInfo_Item then
                return
            end
            
            local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)
            local CurrentItemLevel, RetItemName = IngameDT:BP_FindDataUInt8(StrItemID,"ItemLevel")

            self.BagItemText:SetText(TranslatedItemName)
            
            self.NeedText:SetText(StringUtil.Format("拥有"))
            if RetItemName and CurrentItemLevel > 0 then
                 local NewLinearColor = self.QualityColor[CurrentItemLevel]
                 self.BagItemText:SetColorAndOpacity(UIHelper.ToSlateColor_LC(NewLinearColor))
             end
        else
            BlackBoardKeySelector.SelectedKeyName = "ItemTypeName"
            local ItemTypeName, OutPlayerNameType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsName(TipGenricBlackboard, BlackBoardKeySelector)
            
            print("MarkLogPanel:OnTipsInitialize",GetObjectName(self),"ItemTypeName is ",ItemTypeName)
            self.BagItemText:SetText(ItemTypeName)
            self.BagItemText:SetColorAndOpacity(UIHelper.ToSlateColor_LC(UIHelper.LinearColor.White))
            self.NeedText:SetText(StringUtil.Format("需要"))
        end
        self:SetAllCollosped()
        self.BagItemInfo:SetVisibility(UE.ESlateVisibility.Visible)
    elseif MarkType == UE.EMarkDataType.Item then
        self.ItemInfoTextPlayerName:SetText(PlayerName)

        BlackBoardKeySelector.SelectedKeyName ="ItemId"

        local ItemId, OutPlayerNameType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(TipGenricBlackboard, BlackBoardKeySelector)
        
        -- 因为无法取到武器皮肤，这里暂时注释
        --self.ItemImage:SetDetailByItemId(ItemId)

        local StrItemID = tostring(ItemId)
        local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(self, ItemId)
        if not IngameDT then
            return
        end

        local StructInfo_Item = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, StrItemID)
        if not StructInfo_Item then
            return
        end
            
        local TranslatedItemName = StringUtil.Format(StructInfo_Item.ItemName)
        local CurrentItemLevel, RetItemName = IngameDT:BP_FindDataUInt8(StrItemID,"ItemLevel")

        self.ItemText:SetText(TranslatedItemName)
        if RetItemName then
            local NewLinearColor = self.QualityColor[CurrentItemLevel]
            self.ItemText:SetColorAndOpacity(UIHelper.ToSlateColor_LC(NewLinearColor))
        end

        BlackBoardKeySelector.SelectedKeyName = "BookId"

        local BookId, OutBookType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(TipGenricBlackboard, BlackBoardKeySelector)
        local bIfBook = BookId ~= 0 and BookId ~= nil
        local DisPlayTipsText
        if bIfBook then
            DisPlayTipsText = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Minimap_Log_Item_BookTips")
        else
            DisPlayTipsText = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Minimap_Log_Item_MarkTips")
        end

        BlackBoardKeySelector.SelectedKeyName = "ItemLoc"

        local ItemLoc, OutItemLocType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsVector(TipGenricBlackboard, BlackBoardKeySelector)

        self.ItemTips:SetText(DisPlayTipsText)
        self.ItemPos:SetText(tostring(ItemLoc))
        
        self:SetAllCollosped()
        self.ItemInfo:SetVisibility(UE.ESlateVisibility.Visible)
    elseif MarkType == UE.EMarkDataType.Enemy then
        self.EnemyInfoTextPlayerName:SetText(PlayerName)
        self:SetAllCollosped()
        self.EnemyInfo:SetVisibility(UE.ESlateVisibility.Visible)
    elseif MarkType == UE.EMarkDataType.Point then
        self.PlaceInfoTextPlayerName:SetText(PlayerName)
        self:SetAllCollosped()
        self.PlaceInfo:SetVisibility(UE.ESlateVisibility.Visible)
    elseif MarkType == UE.EMarkDataType.Defense then
        self.NoticeDefenseTextPlayerName:SetText(PlayerName)
        self:SetAllCollosped()
        self.NoticeDefense:SetVisibility(UE.ESlateVisibility.Visible)
    elseif MarkType == UE.EMarkDataType.SomeOneComeHere then
        self.SomeOneComeHereTextPlayerName:SetText(PlayerName)
        self:SetAllCollosped()
        self.SomeOneComeHere:SetVisibility(UE.ESlateVisibility.Visible)
    elseif MarkType == UE.EMarkDataType.Skill then
        self.SkillInfoTextPlayerName:SetText(PlayerName)
        BlackBoardKeySelector.SelectedKeyName ="SkillState"
        local SkillState, OutSkillStateType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(TipGenricBlackboard, BlackBoardKeySelector)

        BlackBoardKeySelector.SelectedKeyName ="SkillType"
        local SkillType, OutSkillType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(TipGenricBlackboard, BlackBoardKeySelector)

        BlackBoardKeySelector.SelectedKeyName ="ItemTypeName"
        local SkillTypeName, OutSkillType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsName(TipGenricBlackboard, BlackBoardKeySelector)

        -- 0 被动 1 战术技能 2 绝招
        local StateStr
        local SkillTypeStr
        local TipsName
        local DisPlayTipsText

        if 0 == SkillType then
        elseif 1 == SkillType then
            SkillTypeStr = "TacticalSkill"
        elseif 2 == SkillType then
            SkillTypeStr = "UltimateSkill"
        end

        if UE.EGeSkillStatus.Activating == SkillState then
            StateStr = "Activating"
            TipsName = "Minimap_Log_"..SkillTypeStr.."_"..StateStr.."Tips"
            DisPlayTipsText = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, TipsName)
            DisPlayTipsText = string.format(DisPlayTipsText, SkillTypeName)
            self.SkillTextTips:SetText(DisPlayTipsText)
        elseif UE.EGeSkillStatus.Cooling == SkillState then
            BlackBoardKeySelector.SelectedKeyName ="CoolTime"
            StateStr = "CoolTime"
            TipsName = "Minimap_Log_"..SkillTypeStr.."_"..StateStr.."Tips"
            local CoolTime, OutCoolTimeType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(TipGenricBlackboard, BlackBoardKeySelector)
            DisPlayTipsText = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, TipsName)
            DisPlayTipsText = string.format(DisPlayTipsText, SkillTypeName, CoolTime)
            self.SkillTextTips:SetText(DisPlayTipsText)
        elseif UE.EGeSkillStatus.Normal == SkillState then
            StateStr = "Normal"
            TipsName = "Minimap_Log_"..SkillTypeStr.."_"..StateStr.."Tips"
            DisPlayTipsText = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, TipsName)
            DisPlayTipsText = string.format(DisPlayTipsText, SkillTypeName)
            self.SkillTextTips:SetText(DisPlayTipsText)
        elseif UE.EGeSkillStatus.Invalid == SkillState then
            StateStr = "Invalid"
            TipsName = "Minimap_Log_"..SkillTypeStr.."_"..StateStr.."Tips"
            DisPlayTipsText = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, TipsName)
            DisPlayTipsText = string.format(DisPlayTipsText, SkillTypeName)
            self.SkillTextTips:SetText(DisPlayTipsText)
        elseif UE.EGeSkillStatus.CantUse == SkillState then
            StateStr = "Cannot"
            TipsName = "Minimap_Log_"..SkillTypeStr.."_"..StateStr.."Tips"
            DisPlayTipsText = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, TipsName)
            DisPlayTipsText = string.format(DisPlayTipsText, SkillTypeName)
            self.SkillTextTips:SetText(DisPlayTipsText)
        end
        
        self:SetAllCollosped()
        self.SkillInfo:SetVisibility(UE.ESlateVisibility.Visible)
    end

end

return MarkLogPanel