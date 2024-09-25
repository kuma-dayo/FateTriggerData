---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 服务器列表item
--- Created At: 2023/07/25 11:14
--- Created By: 朝文
---

require("Client.Modules.Match.MatchSever.MatchSeverModel")

local class_name = "MatchModeSelectSeverItem"
---@class MatchModeSelectSeverItem : ComboBoxItem
local MatchModeSelectSeverItem = BaseClass(ComboBoxItem, class_name)

function MatchModeSelectSeverItem:OnInit()
    MatchModeSelectSeverItem.super.OnInit(self)
    if not self.MsgList then self.MsgList = {} end
    table.insert(self.MsgList, {Model = MatchSeverModel, MsgName = MatchSeverModel.ON_MATCH_SERVER_INFO_UPDATED, Func = Bind(self, self.ON_MATCH_SERVER_INFO_UPDATED_func)})
end
function MatchModeSelectSeverItem:OnShow(Param) end
function MatchModeSelectSeverItem:OnHide() end

function MatchModeSelectSeverItem:OnHovered()
    MatchModeSelectSeverItem.super.OnHovered(self)

    self.View.WidgetSwitcher:SetActiveWidgetIndex(1)
    
    --延迟很低的话不显示文字
    ---@type MatchSeverModel
    local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
    if tonumber(self.ComboBoxItemData.Ping or 0) < MatchSeverModel.Const.MaxYellowDelay then
        return
    end
    
    --高延迟显示提示文字
    self.View.GUIImage_TipBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.BP_RichText:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function MatchModeSelectSeverItem:OnUnHovered()
    MatchModeSelectSeverItem.super.OnUnHovered(self)

    self:_UpdateSelect()
    
    self.View.GUIImage_TipBg:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.View.BP_RichText:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function MatchModeSelectSeverItem:UpdateContent()
    self:_UpdateText()
    self:_UpdateDelay()
    self:_UpdateSelect()
end

local function _SafeSetText(self, widgetName, textStr)
    if not self or not self.View or not self.View[widgetName] then return end

    self.View[widgetName]:SetText(StringUtil.Format(textStr))
end

function MatchModeSelectSeverItem:_UpdateText()
    _SafeSetText(self, "Text_Area", self.ComboBoxItemData.Region)
    _SafeSetText(self, "Text_Area_1", self.ComboBoxItemData.Region)
    _SafeSetText(self, "Text_Area_2", self.ComboBoxItemData.Region)

    _SafeSetText(self, "Text_Country", self.ComboBoxItemData.Area)
    _SafeSetText(self, "Text_Country_1", self.ComboBoxItemData.Area)
    _SafeSetText(self, "Text_Country_2", self.ComboBoxItemData.Area)
end

---处理延迟
function MatchModeSelectSeverItem:_UpdateDelay()
    ---@type MatchSeverModel
    local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
    local delay = MatchSeverModel:GetDsPingByDsGroupId(self.ComboBoxItemData.DsGroupId)
    --local delay = tonumber(math.min(tonumber(self.ComboBoxItemData.Ping), MatchSeverModel.Const.MaxDisplayDelay)) --max 999
    local tip = "{0}ms"
    if delay <= MatchSeverModel.Const.MaxGreenDelay then
        self.View.Text_ms:SetColorAndOpacity(self.View.Green)   --蓝图字段
    elseif delay <= MatchSeverModel.Const.MaxYellowDelay then
        self.View.Text_ms:SetColorAndOpacity(self.View.Yellow)  --蓝图字段
    else
        self.View.Text_ms:SetColorAndOpacity(self.View.Red)     --蓝图字段
        tip = ">{0}ms"
        delay = MatchSeverModel.Const.MaxYellowDelay
    end
    _SafeSetText(self, "Text_ms", StringUtil.Format(tip, delay))
end

---处理选中
function MatchModeSelectSeverItem:_UpdateSelect()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local CurSelServerId = MatchModeSelectModel:_GetCurSelServeId()
    if self.ComboBoxItemData.DsGroupId == CurSelServerId then
        self.View.WidgetSwitcher:SetActiveWidgetIndex(2)
        self.View.Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.View.WidgetSwitcher:SetActiveWidgetIndex(0)
        self.View.Select:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function MatchModeSelectSeverItem:ON_MATCH_SERVER_INFO_UPDATED_func()
    self:_UpdateDelay()
end

return MatchModeSelectSeverItem
