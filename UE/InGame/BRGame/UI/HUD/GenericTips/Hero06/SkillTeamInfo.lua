local SkillTeamInfo = Class("Common.Framework.UserWidget")

function SkillTeamInfo:OnInit()
    UserWidget.OnInit(self)
end

function SkillTeamInfo:OnDestroy()
    UserWidget.OnDestroy(self)
end

function SkillTeamInfo:OnShow()
    self:VXE_Hero_06_In()
end

function SkillTeamInfo:OnClose()
    self:VXE_Hero_06_Position()
    self:VXE_Hero_06_Out()
end

return SkillTeamInfo