local RingTakeOffTips = Class("Common.Framework.UserWidget")

function RingTakeOffTips:OnInit()
    print("RingTakeOffTips:OnInit")
    if BridgeHelper.IsMobilePlatform() and self.WBP_SelectHero then
        self:AddActiveWidgetStyleFlags(1)
        self.WBP_SelectHero.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_SelectHero.ControlTipsTxt:SetText(self.WBP_SelectHero.TextContent)
        self.BindNodes = { 
            {UDelegate = self.WBP_SelectHero.GUIButton_Tips.OnClicked, Func = self.OnClicked_ShowBirthLandWidget},
            {UDelegate = self.WBP_SelectHero.GUIButton_Tips.OnHovered, Func = self.OnHoveredChanged},
            {UDelegate = self.WBP_SelectHero.GUIButton_Tips.OnUnhovered, Func = self.OnUnhoveredChanged},
        }
    end
    UserWidget.OnInit(self)
end

function RingTakeOffTips:OnDestroy()
    print("RingTakeOffTips:OnDestroy")
    if self.BindNodes then
        MsgHelper:OpDelegateList(self, self.BindNodes, false)
        self.BindNodes = nil
    end
    UserWidget.OnDestroy(self)
end

function RingTakeOffTips:OnClicked_ShowBirthLandWidget()
    print("RingTakeOffTips:OnClicked_ShowBirthLandWidget")
    local UIManager = UE.UGUIManager.GetUIManager(self)
    UIManager:TryLoadDynamicWidget("UMG_Birthland")
end

function RingTakeOffTips:OnHoveredChanged()
    self.WBP_SelectHero.ControlTipsTxt:SetColorAndOpacity(self.WBP_SelectHero.HoverColor)
end

function RingTakeOffTips:OnUnhoveredChanged()
    self.WBP_SelectHero.ControlTipsTxt:SetColorAndOpacity(self.WBP_SelectHero.NormalColor)
end

return RingTakeOffTips