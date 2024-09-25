--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR 公亮亮
-- @DATE 2024.5.11
--

---@type BP_StartGameWidget_C
local StartGameWidget = Class("Common.Framework.UserWidget")

function StartGameWidget:OnInit()
    print("StartGameWidget:OnInit")

    self.UIManager = UE.UGUIManager.GetUIManager(self)

    if BridgeHelper.IsMobilePlatform() then

        self.HorizontalBox_1:SetVisibility(UE.ESlateVisibility.Collapsed)  --- 隐藏PC端的提示

        self.GUIHorizontalBox_0:SetVisibility(UE.ESlateVisibility.Visible) --- 显示安卓端的提示
        self.WBP_ChangeHeroBtn.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)  --- 隐藏tab图标
        self.WBP_ChangeWeaponBtn.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)

        self.BindNodes ={
            { UDelegate = self.WBP_ChangeHeroBtn.GUIButton_Tips.OnClicked, Func = self.OnClicked_WBP_ChangeHeroBtn },
            { UDelegate = self.WBP_ChangeWeaponBtn.GUIButton_Tips.OnClicked, Func = self.OnClicked_WBP_ChangeWeaponBtn},
        }
        self.WBP_ChangeHeroBtn.ControlTipsTxt:SetText(self.WBP_ChangeHeroBtn.TextContent)
        self.WBP_ChangeWeaponBtn.ControlTipsTxt:SetText(self.WBP_ChangeWeaponBtn.TextContent)
    end

    UserWidget.OnInit(self)
end

function StartGameWidget:OnDestory()
    UserWidget.OnDestory(self)
end

function StartGameWidget:OnClicked_WBP_ChangeHeroBtn()
    print("StartGameWidget >> OnClicked_WBP_ChangeHeroBtn")
    if self.UIManager ~= nil then
        print("UIManager is not nil")
        self.UIManager:TryLoadDynamicWidget("UMG_Birthland")
    end
    
end

function StartGameWidget:OnClicked_WBP_ChangeWeaponBtn()
    print("StartGameWidget >> OnClicked_WBP_ChangeWeaponBtn")
    if self.UIManager ~= nil then
        print("UIManager is not nil")
        self.UIManager:TryLoadDynamicWidget("UMG_ChooseWeaponCombination")
    end
end

return StartGameWidget