--[[
    通用标签文本控件
]]

local class_name = "CommonDescriptionLabel"
local CommonDescriptionLabel = CommonDescriptionLabel or BaseClass(nil, class_name)

---@class CommonDescriptionLabelParam
---@field ShowIndex number 展示下标0、文本1、高级标志2、免费标志
---@field ShowText string ShowIndex为1时文本描述
function CommonDescriptionLabel:OnInit()
end

function CommonDescriptionLabel:OnShow(Param)
    self:UpdateUI(Param)
end

function CommonDescriptionLabel:UpdateUI(Param)
    if not Param or not Param.ShowIndex then
        self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
		CWaring("CommonDescriptionLabel Param is nil, Please Check!",true)
        return
    end
    self.Param = Param
    self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.WidgetSwitcher_0:SetActiveWidgetIndex(Param.ShowIndex)
    if Param.ShowText then
        self.View.LbGoodName:SetText(StringUtil.Format(Param.ShowText))
    elseif Param.ShowIndex == 0 then
        self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function CommonDescriptionLabel:OnHide()  
end

return CommonDescriptionLabel