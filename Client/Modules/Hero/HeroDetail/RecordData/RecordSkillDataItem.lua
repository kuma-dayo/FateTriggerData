local class_name = "RecordSkillDataItem"
local RecordSkillDataItem = BaseClass(nil, class_name)


function RecordSkillDataItem:OnInit()
    self.MsgList = 
    {
	}
    self.BindNodes = 
    {
	}
end

function RecordSkillDataItem:OnShow(Param)
    self:SetData(Param)
end

function RecordSkillDataItem:OnHide()
end

function RecordSkillDataItem:SetData(Param)
    if not Param or not Param.SkillId then
        CWaring("RecordSkillDataItem:SetData Param is nil")
        return
    end
    local CfgHeroSkill = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkillStatisticsCfg, Param.SkillId)
    if not CfgHeroSkill then
        CWaring("RecordSkillDataItem:SetData CfgHeroSkill is nil")
        return
    end
    CommonUtil.SetBrushFromSoftObjectPath(self.View.ImgIcon, CfgHeroSkill[Cfg_HeroSkillStatisticsCfg_P.SkillIcon])
    CommonUtil.SetBorderBrushColorFromHex(self.View.SkillTagColor, CfgHeroSkill[Cfg_HeroSkillStatisticsCfg_P.SkillTagColor])
    self.View.GUITextBlock_SkillName:SetText(CfgHeroSkill[Cfg_HeroSkillStatisticsCfg_P.SkillTagName])
    self.View.GUITextBlock_Record:SetText(CfgHeroSkill[Cfg_HeroSkillStatisticsCfg_P.SkillRecordDesc])

    local FinalValue = Param.RecordValue
    if Param.RecordValue > 0 then
        local ShowRate = CfgHeroSkill[Cfg_HeroSkillStatisticsCfg_P.ShowRate] or 1
        local Value = Param.RecordValue/ShowRate
        if ShowRate > 1 then
            -- 不足1的时候保留两位小数，超过1的时候不保留小数
            if Value > 1 then
                FinalValue = math.floor(Value)
            else
                FinalValue = string.format("%.2f", Value)
            end
        else
            FinalValue = string.format("%.0f", Value)
        end
    end
    self.View.GUITextBlock_RecordValue:SetText(FinalValue)
end

return RecordSkillDataItem








