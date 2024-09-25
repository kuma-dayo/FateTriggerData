require "UnLua"

local ChooseHero_TeamMate = Class("Common.Framework.UserWidget")

function ChooseHero_TeamMate:GetRealName(InName)
    return StringUtil.Format(InName)
end

return ChooseHero_TeamMate
