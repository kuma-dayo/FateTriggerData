--[[
    通用的CommonSkillIcon控件

    通用的技能Icon控件
]]

local class_name = "CommonSkillIcon"
CommonSkillIcon = CommonSkillIcon or BaseClass(nil, class_name)

CommonSkillIcon.ClickTypeEnum = {
    --无
    None = 1,
}

function CommonSkillIcon:OnInit()
end
--[[
   local Param = {
        SkillId
   }
]]
function CommonSkillIcon:OnShow(Param)
    self:UpdateUI(Param)
end
function CommonSkillIcon:OnHide()
    self.SkillTagColor = nil
end
function CommonSkillIcon:UpdateUI(Param)
    self.Param = Param
    if not self.Param then
        CError("CommonSkillIcon:UpdateUI Param Error")
        print_trackback()
        return
    end
    local CfgHeroSkill = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkillCfg,self.Param.SkillId)
    local CfgSkillTag = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkillTag,CfgHeroSkill[Cfg_HeroSkillCfg_P.SkillTag])

    --TODO 更新技能图标展示
    CommonUtil.SetBrushFromSoftObjectPath(self.View.SkillIcon,CfgHeroSkill[Cfg_HeroSkillCfg_P.SkillIcon])
    --TODO 更新技能标签展示
    self.View.SkillTag:SetText(StringUtil.Format(CfgSkillTag[Cfg_HeroSkillTag_P.SkillTagName]))
    if not self.SkillTagColor then
        self.SkillTagColor = CfgSkillTag[Cfg_HeroSkillTag_P.SkillTagColor]
    end
    self:SetSkillTagColor()
end

-- 供外部设置不同状态时文本的颜色
function CommonSkillIcon:SetSkillTagColor(HexColor)
    if not HexColor then
        HexColor = self.SkillTagColor
    end
    CommonUtil.SetTextColorFromeHex(self.View.SkillTag,HexColor)
end

return CommonSkillIcon
