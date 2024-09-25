---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 举报类型
--- Created At: 2023/08/30 17:07
--- Created By: 朝文
---

local class_name = "ReportTypeItem"
---@class ReportTypeItem
local ReportTypeItem = BaseClass(nil, class_name)

function ReportTypeItem:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.GUIButton_TabBg.OnClicked,    Func = Bind(self, self.OnButtonClicked_GUIButton_TabBg) }, 
    }
end

function ReportTypeItem:OnShow(Param) end
function ReportTypeItem:OnHide()      end

--[[
    Param = {
        ReportType = 3.
        ReportIds = {1007, 1008},
    }
--]]
function ReportTypeItem:SetData(Param)
    self.Data = Param
end

---@param ClickCallback fun(Data:table):void
function ReportTypeItem:SetClickCallback(ClickCallback)
    self.ClickCallback = ClickCallback
end

function ReportTypeItem:UpdateView()
    ---@type ReportModel
    local ReportModel = MvcEntry:GetModel(ReportModel)
    local Name = ReportModel:GetReportTypeName(self.Data.ReportType)
    self.View.LabelNormal:SetText(Name)
    self.View.LabelSelect:SetText(Name)
end

------------------------------------------------------- 按钮相关 ---------------------------------------------------------

function ReportTypeItem:OnButtonClicked_GUIButton_TabBg()
    CLog("[cw] self.Data.ReportType: " .. tostring(self.Data.ReportType))
    if self.ClickCallback then
        self.ClickCallback(self.Data)
    end
end

function ReportTypeItem:Select()
    self.View.WidgetSwitcher:SetActiveWidgetIndex(1)
end

function ReportTypeItem:Unselect()
    self.View.WidgetSwitcher:SetActiveWidgetIndex(0)
end

return ReportTypeItem
