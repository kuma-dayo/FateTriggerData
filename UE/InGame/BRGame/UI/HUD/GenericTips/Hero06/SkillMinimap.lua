local SkillMinimap = Class("Common.Framework.UserWidget")

function SkillMinimap:OnInit()
    UserWidget.OnInit(self)
end

function SkillMinimap:OnDestroy()
    UserWidget.OnDestroy(self)
end

function SkillMinimap:OnShow()
    self:VXE_Map_Hero6_Skill_In()
end

function SkillMinimap:OnClose()
    self:VXE_Map_Hero6_Skill_Out()
end

return SkillMinimap