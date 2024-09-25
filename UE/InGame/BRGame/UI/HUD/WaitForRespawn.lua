--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR 公亮亮
-- @DATE 2024.5.11
--


---@type WBP_WaitForRespawn_C
local WaitForRespawn = Class("Common.Framework.UserWidget")

function WaitForRespawn:OnInit()
    print("WaitForRespawn:OnInit")

    self.UIManager = UE.UGUIManager.GetUIManager(self)

    if BridgeHelper.IsMobilePlatform() then
        print("WaitForRespawn:IsMobilePlatform")
        self.HorizontalBox_122:SetVisibility(UE.ESlateVisibility.Collapsed) --- 隐藏PC端的选择武器
        self.GUICanvasPanel_1:SetVisibility(UE.ESlateVisibility.Visible) --- 显示Mobile端的选择武器
        self.WBP_ChangeWeaponBtn.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed) ---隐藏tab操作图标
        self.BindNodes ={
            { UDelegate = self.WBP_ChangeWeaponBtn.GUIButton_Tips.OnClicked, Func = self.OnClicked_WBP_ChangeWeaponBtn},
        }
        self.WBP_ChangeWeaponBtn.ControlTipsTxt:SetText(self.WBP_ChangeWeaponBtn.TextContent)
    end


    UserWidget.OnInit(self)
end

function WaitForRespawn:OnDestory()
    UserWidget.OnDestory(self)
end

function WaitForRespawn:OnClicked_WBP_ChangeWeaponBtn()
    print("WaitForRespawn >> OnClicked_WBP_ChangeWeaponBtn")
    if self.UIManager ~= nil then
        print("UIManager is not nil")
        self.UIManager:TryLoadDynamicWidget("UMG_ChooseWeaponCombination")
    end
end

return WaitForRespawn
