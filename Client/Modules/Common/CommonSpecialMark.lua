local class_name = "CommonSpecialMark"
local CommonSpecialMark = BaseClass(nil, class_name)

---@class CommonSpecialMarkParam
---@field SpecialMarkBg string
---@field SpecialMarkText string
---@field SpecialMarkIcon string
CommonSpecialMark.InParam = nil

--- func desc
---@param Param CommonSpecialMarkParam
function CommonSpecialMark:OnShow(Param)
    if not Param then
        return
    end
    self:UpdataShow(Param)
end

function CommonSpecialMark:OnHide()
    self.Param = nil
end

function CommonSpecialMark:UpdataShow(Param)
    if not Param or not Param.SpecialMarkText or Param.SpecialMarkText == "" then
        self.View:SetVisibility(UE4.ESlateVisibility.Collapsed)
        return
    end
    self.View:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Param = Param
    -- print("CommonSpecialMark OnShow")
    if Param.SpecialMarkIcon and Param.SpecialMarkIcon ~= "" then
        CommonUtil.SetBrushFromSoftObjectPath(self.View.SpecialMarkIcon, Param.SpecialMarkIcon)
    end
    self:UpdateSpecialMarkText(StringUtil.Format(Param.SpecialMarkText))
end

function CommonSpecialMark:UpdateSpecialMarkText(Text)
    self.View.SpecialMarkText:SetText(Text)
end

return CommonSpecialMark