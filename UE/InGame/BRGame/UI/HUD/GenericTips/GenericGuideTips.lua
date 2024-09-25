--通用Tips Guide类
--作者：许欣桐


local GenericGuideTips = Class("Common.Framework.UserWidget")

function GenericGuideTips:OnInit()
    print("GenericGuideTips:OnInit")
   

    UserWidget.OnInit(self)
end


function GenericGuideTips:OnDestroy()
    print("GenericGuideTips:OnDestroy")
 
    UserWidget.OnDestroy(self)
end


function GenericGuideTips:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    local InputKeySelector = UE.FGenericBlackboardKeySelector()  
    InputKeySelector.SelectedKeyName = "InputKey"
    local InputKeyValue,OutInputKeySelectorBool =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(TipGenricBlackboard,InputKeySelector)
    self.TxtGuideKey:SetText(InputKeyValue)
end


return GenericGuideTips