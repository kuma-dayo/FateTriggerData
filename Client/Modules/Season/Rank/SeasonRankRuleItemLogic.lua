--[[
   排位规则信息item
]] 
local class_name = "SeasonRankRuleItemLogic"
local SeasonRankRuleItemLogic = BaseClass(UIHandlerViewBase, class_name)

function SeasonRankRuleItemLogic:OnInit()

end

--[[
    ConfigData
]]
function SeasonRankRuleItemLogic:OnShow(Param)
    if not Param then
        return
    end
    ---@type SeasonRankRuleConfig
    self.ConfigData = Param.ConfigData
    self:UpdateUI(Param)
end

function SeasonRankRuleItemLogic:OnHide()

end

function SeasonRankRuleItemLogic:UpdateUI(Param)
    if not Param then
        return
    end
    self.Param = Param
    self:UpdateRuleIcon()
    self:UpdateRuleName()
    self:UpdateRuleDesc()
end

-- 更新规则图片
function SeasonRankRuleItemLogic:UpdateRuleIcon()
    if self.ConfigData.DescIcon and self.ConfigData.DescIcon ~= "" then
        CommonUtil.SetBrushFromSoftObjectPath(self.View.Img_Icon, self.ConfigData.DescIcon) 
    end
end

-- 更新规则名称
function SeasonRankRuleItemLogic:UpdateRuleName()
    self.View.TextBlock_RuleName:SetText(StringUtil.Format(self.ConfigData.DescTitle))
end

-- 更新规则描述
function SeasonRankRuleItemLogic:UpdateRuleDesc()
    self.View.RichTextBlock_RuleDesc:SetText(StringUtil.Format(self.ConfigData.DescText))
end

return SeasonRankRuleItemLogic
