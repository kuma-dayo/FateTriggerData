---
--- Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 适用于单排、双排、四排
--- Created At: 2023/07/17 17:21
--- Created By: 朝文
---

local class_name = "MatchModeSelectItemWidgetStyle2"
---@class MatchModeSelectItemWidgetStyle2
local MatchModeSelectItemWidgetStyle2 = BaseClass(nil, class_name)

--[[
Param = {
    DebugText = "",
    DisplayIconNum = 1,
    ClickedCallback = function() end,
}
--]]
function MatchModeSelectItemWidgetStyle2:OnInit(Param)
    self.Data = Param

    self.BindNodes = {
        { UDelegate = self.View.GUIButton_ClickArea.OnClicked,				Func = Bind(self, self.OnButtonClicked) },
    }

    local DisplayIconNum = Param.DisplayIconNum or 0
    self.View.GUIImage_Lock:SetVisibility(UE.ESlateVisibility.Collapsed)
    for i = 1, 4 do
        local NormalWidget = self.View["NormalImage_" .. tostring(i)]
        -- local SelectWidget = self.View["SelectImage_" .. tostring(i)]
        -- local UnavailableWidget = self.View["UnavailableImage_" .. tostring(i)]
        
        if i > DisplayIconNum then
            NormalWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
            -- SelectWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
            -- UnavailableWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            NormalWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            -- SelectWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            -- UnavailableWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
    end
end

function MatchModeSelectItemWidgetStyle2:OnShow(Param) end
function MatchModeSelectItemWidgetStyle2:OnHide() end

function MatchModeSelectItemWidgetStyle2:SwitchState_Normal() 
    if self.View.VXE_Btn_Normal then
        self.View:VXE_Btn_Normal()
    end
    self.View.IsSelect = false
    -- self.View.GUIImage_Lock:SetVisibility(UE.ESlateVisibility.Collapsed)
end
function MatchModeSelectItemWidgetStyle2:SwitchState_Select() 
    if self.View.VXE_Btn_Select then
        self.View:VXE_Btn_Select()
    end
    self.View.IsSelect = true
    -- self.View.GUIImage_Lock:SetVisibility(UE.ESlateVisibility.Collapsed)
end
function MatchModeSelectItemWidgetStyle2:SwitchState_UnSelect() 
    -- self.View.WidgetSwitcher_State:SetActiveWidgetIndex(1) 
    if self.View.VXE_Btn_UnSelect then
        self.View:VXE_Btn_UnSelect()
    end
    self.View.IsSelect = false
end
function MatchModeSelectItemWidgetStyle2:SwitchState_Unavailable() 
    if self.View.VXE_Btn_Lock then
        self.View:VXE_Btn_Lock()
    end
    self.View.IsSelect = false
    -- self.View.GUIImage_Lock:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function MatchModeSelectItemWidgetStyle2:OnButtonClicked()
    if self.Data and self.Data.ClickedCallback then
        if self.Data.DebugText then CLog("[cw] self.Data.DebugText: " .. tostring(self.Data.DebugText)) end
        self.Data.ClickedCallback()
    end
end

return MatchModeSelectItemWidgetStyle2