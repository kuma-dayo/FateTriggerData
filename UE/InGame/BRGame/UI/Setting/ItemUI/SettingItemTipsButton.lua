require "UnLua"

local SettingItemTipsButton = Class("Common.Framework.UserWidget")

function SettingItemTipsButton:OnInit()
    print("SettingItemTipsButton:OnInit")
    self.Button_Tips.OnPressed:Add(self, self.OnPressedShowTips)
    self.Button_Tips.OnReleased:Add(self, self.OnReleasedHideTips)
end

function SettingItemTipsButton:OnDestroy()
    self.Button_Tips.OnPressed:Clear()
    self.Button_Tips.OnReleased:Clear()
    UserWidget.OnDestroy(self)
end

function SettingItemTipsButton:OnPressedShowTips()
    self.BP_Function_Tips.RichText_Content:SetText(self.TextContent)
    self.BP_Function_Tips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end


function SettingItemTipsButton:OnReleasedHideTips()
    self.BP_Function_Tips:SetVisibility(UE.ESlateVisibility.Collapsed) 
end

return SettingItemTipsButton