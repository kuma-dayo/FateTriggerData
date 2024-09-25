local YouCanFlyTips = Class("Common.Framework.UserWidget")

function YouCanFlyTips:OnInit()
    print("YouCanFlyTips:OnInit")
    if BridgeHelper.IsMobilePlatform() then
        self.Image_2:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.TxtBagWeight_2:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

return YouCanFlyTips