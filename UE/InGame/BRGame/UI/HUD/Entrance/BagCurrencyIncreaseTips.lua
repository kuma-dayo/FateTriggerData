require "UnLua"

local BagCurrencyIncreaseTips = Class("Common.Framework.UserWidget")

function BagCurrencyIncreaseTips:OnInit()
    print("BagCurrencyIncreaseTips:OnInit")
    UserWidget.OnInit(self)
end

function BagCurrencyIncreaseTips:OnDestroy()
    print("BagCurrencyIncreaseTips:OnDestroy")
    UserWidget.OnDestroy(self)
end

function BagCurrencyIncreaseTips:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    print("BagCurrencyIncreaseTips:OnTipsInitialize")
    local BlackboardKeySelector = UE.FGenericBlackboardKeySelector() 
    BlackboardKeySelector.SelectedKeyName = "ItemNum"
    local ItemNum, bFoundItemNum = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(TipGenricBlackboard, BlackboardKeySelector)
    BlackboardKeySelector.SelectedKeyName = "TextTips"
    local TipName, bFoundTipName = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsName(TipGenricBlackboard, BlackboardKeySelector)
    if bFoundTipName and self.TextTipsMap then
        local DisplayText = self.TextTipsMap:Find(TipName)
        if DisplayText then self.TextTips:SetText(DisplayText) end
        if bFoundItemNum then self.Txt_MoneyNum:SetText(ItemNum) end
    end
    self:VXE_HUD_BrushRing_In()
end

return BagCurrencyIncreaseTips