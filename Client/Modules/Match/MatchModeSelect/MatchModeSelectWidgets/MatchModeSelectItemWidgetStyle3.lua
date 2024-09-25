---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 适用于第三人称、第一人称
--- Created At: 2023/07/17 17:44
--- Created By: 朝文
---

local class_name = "MatchModeSelectItemWidgetStyle3"
---@class MatchModeSelectItemWidgetStyle3
local MatchModeSelectItemWidgetStyle3 = BaseClass(nil, class_name)

--[[
Param = {
    Text = "",
    ClickedCallback = function() end,
}
--]]
function MatchModeSelectItemWidgetStyle3:OnInit(Param)
    self.Data = Param

    self.BindNodes = {
        { UDelegate = self.View.GUIButton_ClickArea.OnClicked,				Func = Bind(self,self.OnButtonClicked) },
    }

    if Param and Param.Text then
        self.View.Text_Mode:SetText(StringUtil.Format(Param.Text))
    else
        self.View.Text_Mode:SetText("")
    end
end

function MatchModeSelectItemWidgetStyle3:OnShow(Param) end
function MatchModeSelectItemWidgetStyle3:OnHide() end

function MatchModeSelectItemWidgetStyle3:SwitchState_Normal() 
    if self.View.VXE_Btn_Normal then
        self.View:VXE_Btn_Normal()
    end
    -- self.View.WidgetSwitcher_State:SetActiveWidgetIndex(0) 
end
function MatchModeSelectItemWidgetStyle3:SwitchState_Select() 
    -- self.View.WidgetSwitcher_State:SetActiveWidgetIndex(1) 
    if self.View.VXE_Btn_Select then
        self.View:VXE_Btn_Select()
    end
end
function MatchModeSelectItemWidgetStyle3:SwitchState_UnSelect() 
    -- self.View.WidgetSwitcher_State:SetActiveWidgetIndex(1) 
    if self.View.VXE_Btn_UnSelect then
        self.View:VXE_Btn_UnSelect()
    end
end
function MatchModeSelectItemWidgetStyle3:SwitchState_Unavailable() 
    -- self.View.WidgetSwitcher_State:SetActiveWidgetIndex(2) 
    if self.View.VXE_Btn_Lock then
        self.View:VXE_Btn_Lock()
    end
end

function MatchModeSelectItemWidgetStyle3:OnButtonClicked()
    if self.Data and self.Data.ClickedCallback then
        self.Data.ClickedCallback()
    end
end

return MatchModeSelectItemWidgetStyle3
