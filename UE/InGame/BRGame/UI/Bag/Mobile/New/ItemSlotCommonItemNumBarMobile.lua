local ItemSlotCommonItemNumBarMobile = Class("Common.Framework.UserWidget")
function ItemSlotCommonItemNumBarMobile:OnInit()
    print("NewBagMobile@ItemSlotCommonItemNumBarMobile Init")

    UserWidget.OnInit(self)
end


function ItemSlotCommonItemNumBarMobile:SetShowFill(isShowFill)
    self.Image_Fill:SetVisibility(isShowFill and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end


return ItemSlotCommonItemNumBarMobile