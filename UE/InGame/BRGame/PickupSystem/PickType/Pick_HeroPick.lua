require "UnLua"
require ("InGame.BRGame.ItemSystem.ItemSystemHelper")
require ("Common.Utils.StringUtil")

local Pick_HeroPick = Class()

--处理数据
function Pick_HeroPick:ShowPickResultTip(InPickResult)
    self.Overridden.ShowPickResultTip(self,InPickResult)
    local PickupSetting = UE.UPickupManager.GetGPSSeting(self.Owner)
    if not PickupSetting then
        return
    end

    --DS会主动调
    if self.Owner:GetLocalRole() == UE.ENetRole.ROLE_Authority then
        return
    end

    --客户端等rep下来
    if InPickResult.PickSuccess then

        local PC = UE.UGameplayStatics.GetPlayerController(self, 0)
        if not PC then
            return
        end

        local IngameDT = UE.UTableManagerSubsystem.GetIngameItemDataTableByItemID(PC, InPickResult.ItemInfo.ItemID)
        if not IngameDT then
            return
        end

        local StructInfo_PickObj = UE.UDataTableFunctionLibrary.GetRowDataStructure(IngameDT, tostring(InPickResult.ItemInfo.ItemID))
        if not StructInfo_PickObj then
            return
        end

        local TranslatedItemName = StringUtil.Format(StructInfo_PickObj.ItemName)
        local Tip = PickupSetting.PickResultTipsMap:Find(InPickResult.PickResultTypeTag)
        local ShowPickNum = false
        if StructInfo_PickObj.MaxStack == 1 then
            ShowPickNum = false
        else
            ShowPickNum = true
        end
        local GenericBlackboard = UE.FGenericBlackboardContainer()
        local BlackboardKeySelector = UE.FGenericBlackboardKeySelector()
        BlackboardKeySelector.SelectedKeyName = "PickNum"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsInt(GenericBlackboard, BlackboardKeySelector, InPickResult.PickNum)
        BlackboardKeySelector.SelectedKeyName = "TipText"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard, BlackboardKeySelector, StringUtil.ConvertFText2String(TranslatedItemName))
        BlackboardKeySelector.SelectedKeyName = "Tip"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard, BlackboardKeySelector, StringUtil.ConvertFText2String(Tip))
        BlackboardKeySelector.SelectedKeyName = "ShowPickNum"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsBool(GenericBlackboard,BlackboardKeySelector, ShowPickNum)
        BlackboardKeySelector.SelectedKeyName = "ItemID"
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsInt(GenericBlackboard,BlackboardKeySelector, InPickResult.ItemInfo.ItemID)
        UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId("PickUpFeedback",-1, GenericBlackboard,self.Owner,StringUtil.ConvertString2FText(TranslatedItemName))
    else
        if InPickResult.PickReason == UE.EPickReason.PR_Player then
            local TipText = PickupSetting.PickResultTipsMap:Find(InPickResult.PickResultTypeTag)
            UE.UTipsManager.GetTipsManager(self):ShowTipsUIByTipsId("PickUpFeedbackWarning",-1,UE.FGenericBlackboardContainer(),self.Owner,StringUtil.ConvertString2FText(TipText))
        end
    end
end

return Pick_HeroPick