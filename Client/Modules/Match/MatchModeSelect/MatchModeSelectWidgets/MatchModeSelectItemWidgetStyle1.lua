---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 适用于补满队伍和跨平台匹配按钮
--- Created At: 2023/07/17 16:53
--- Created By: 朝文
---

local class_name = "MatchModeSelectItemWidgetStyle1"
---@class MatchModeSelectItemWidgetStyle1
local MatchModeSelectItemWidgetStyle1 = BaseClass(nil, class_name)

--[[
Param = {
    Text = "",
    ClickedCallback = function() end,
}
--]]
function MatchModeSelectItemWidgetStyle1:OnInit(Param)
    self.Data = Param
    
    self.BindNodes = {
        { UDelegate = self.View.GUIButton_ClickArea.OnClicked,				Func = Bind(self,self.OnButtonClicked) },
    }

    if Param and Param.Text then
        self.View.Text_Team:SetText(StringUtil.Format(Param.Text))
    else
        self.View.Text_Team:SetText("")
    end
    -- 是否响应回调，Unavailable 状态下，不应该响应点击回调 @chenyishui
    self.IsAvailable = true
end

function MatchModeSelectItemWidgetStyle1:OnShow(Param) end
function MatchModeSelectItemWidgetStyle1:OnHide() end

function MatchModeSelectItemWidgetStyle1:SwitchState_Normal() 
    -- self.View.WidgetSwitcher_State:SetActiveWidgetIndex(0) 
    if self.View.VXE_Btn_Normal then
        self.View:VXE_Btn_Normal()
    end
    self.View.WidgetSwitcher_Icon:SetActiveWidget(self.View.Icon_Empty)
    self.IsAvailable = true
end
function MatchModeSelectItemWidgetStyle1:SwitchState_Select() 
    if self.View.VXE_Btn_Select then
        self.View:VXE_Btn_Select()
    end
    self.View.WidgetSwitcher_Icon:SetActiveWidget(self.View.Icon_Select)
    self.IsAvailable = true
end
function MatchModeSelectItemWidgetStyle1:SwitchState_UnSelect() 
    -- self.View.WidgetSwitcher_State:SetActiveWidgetIndex(1) 
    if self.View.VXE_Btn_UnSelect then
        self.View:VXE_Btn_UnSelect()
    end
    self.IsAvailable = true
end
function MatchModeSelectItemWidgetStyle1:SwitchState_Unavailable() 
    -- self.View.WidgetSwitcher_State:SetActiveWidgetIndex(2) 
    if self.View.VXE_Btn_Forbid then
        self.View:VXE_Btn_Forbid()
    end
    self.View.WidgetSwitcher_Icon:SetActiveWidget(self.View.Icon_Forbid)
    self.IsAvailable = false
end

function MatchModeSelectItemWidgetStyle1:OnButtonClicked()
    if self.IsAvailable and self.Data and self.Data.ClickedCallback then
        self.Data.ClickedCallback()
    end
end

return MatchModeSelectItemWidgetStyle1
