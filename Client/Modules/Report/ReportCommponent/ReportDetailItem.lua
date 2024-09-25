---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 举报细节条目
--- Created At: 2023/08/30 16:33
--- Created By: 朝文
---

local class_name = "ReportDetailItem"
---@class ReportDetailItem
local ReportDetailItem = BaseClass(nil, class_name)

function ReportDetailItem:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.GUIButton_ClickArea.OnClicked,    Func = Bind(self,self.OnButtonClicked_GUIButton_ClickArea) },
    }
end

function ReportDetailItem:OnShow(Param) end
function ReportDetailItem:OnHide()      end

function ReportDetailItem:SetData(Param)
    self.Data = Param
end

---@param ClickCallback fun(number):void
function ReportDetailItem:SetClickCallback(ClickCallback)
    self.ClickCallback = ClickCallback
end

function ReportDetailItem:UpdateView()
    ---@type ReportModel
    local ReportModel = MvcEntry:GetModel(ReportModel)
    local Name = ReportModel:GetReportDetailTextByReportID(self.Data)
    self.View.Text_Content1:SetText(Name)
    -- self.View.Text_Content2:SetText(Name)
    -- self.View.Text_Content3:SetText(Name)
end

function ReportDetailItem:Select()
    --self.View.Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.GUIImage_8:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.GUIImage_9:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if self.View.VXE_Btn_Select then
        self.View:VXE_Btn_Select()
    end
end

function ReportDetailItem:Unselect()
    --self.View.Select:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.GUIImage_8:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.GUIImage_9:SetVisibility(UE.ESlateVisibility.Collapsed)
    if self.View.VXE_Btn_UnSelect then
        self.View:VXE_Btn_UnSelect()
    end
end

------------------------------------------------------- 按钮相关 ---------------------------------------------------------

function ReportDetailItem:OnButtonClicked_GUIButton_ClickArea()
    if self.ClickCallback then
        self.ClickCallback(self.Data)
    end
end

return ReportDetailItem
