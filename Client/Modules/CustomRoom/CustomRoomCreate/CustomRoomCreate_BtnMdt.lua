---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 自建房房间设置按钮
--- Created At: 2023/06/15 17:16
--- Created By: 朝文
---

local class_name = "CustomRoomCreateBtnMdt"
---@class CustomRoomCreate_BtnMdt
local CustomRoomCreateBtnMdt = BaseClass(nil, class_name)
CustomRoomCreateBtnMdt.Enum_BgIndex = {
    Normal      = 2,
    Selected    = 1,
}
CustomRoomCreateBtnMdt.Enum_TextColor = {
    Hovered     = UIHelper.ToSlateColor_LC(UE.FLinearColor(0.01, 0.01, 0.02, 1)),
    UnHovered   = UIHelper.ToSlateColor_LC(UE.FLinearColor(0.91, 0.86, 0.73, 1)),
    Normal      = UIHelper.ToSlateColor_LC(UE.FLinearColor(0.91, 0.86, 0.73, 1)),
    Selected    = UIHelper.ToSlateColor_LC(UE.FLinearColor(0.01, 0.01, 0.02, 1)),
}

function CustomRoomCreateBtnMdt:OnInit()
    self._isSelected = nil
    
    self.BindNodes = {
        { UDelegate = self.View.BtnSelect.OnClicked,	Func = Bind(self, self.OnClicked_Select) },        
    }
end

function CustomRoomCreateBtnMdt:OnShow(Param)
    self:UnSelect()    
end

function CustomRoomCreateBtnMdt:OnHide() end

--[[
    Param = {
        DisplayName = "",
    }
--]]
function CustomRoomCreateBtnMdt:SetData(Param)
    self.Data = Param
end

---@param NewClickCallback fun(table):void
function CustomRoomCreateBtnMdt:SetButtonClickCallback(NewClickCallback)
    self.ClickCallback = NewClickCallback
end

function CustomRoomCreateBtnMdt:UpdateView()
    if not self.Data then return end
    
    self.View.TxtName:SetText(self.Data.DisplayName)
end

function CustomRoomCreateBtnMdt:Select()
    if self._isSelected == true then return end

    self._isSelected = true
    self.View.BGSwitch:SetActiveWidgetIndex(CustomRoomCreateBtnMdt.Enum_BgIndex.Selected)
    self.View.TxtName:SetColorAndOpacity(CustomRoomCreateBtnMdt.Enum_TextColor.Selected)
end

function CustomRoomCreateBtnMdt:UnSelect()
    if self._isSelected == false then return end
    
    self._isSelected = false
    self.View.BGSwitch:SetActiveWidgetIndex(CustomRoomCreateBtnMdt.Enum_BgIndex.Normal)
    self.View.TxtName:SetColorAndOpacity(CustomRoomCreateBtnMdt.Enum_TextColor.Normal)    
end

function CustomRoomCreateBtnMdt:OnClicked_Select()
    if not self.ClickCallback or type(self.ClickCallback) ~= "function" then return end

    self.ClickCallback()
end

return CustomRoomCreateBtnMdt
