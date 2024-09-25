
local class_name = "LoginAgeAcceptConentLogic"
local LoginAgeAcceptConentLogic = BaseClass(nil, class_name)

function LoginAgeAcceptConentLogic:OnInit()
    self.AgeAcceptConent = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_LoginAgeAcceptConentLogic_gametips")
end


function LoginAgeAcceptConentLogic:OnShow()
    self.View.Content:SetText(self.AgeAcceptConent)
end

function LoginAgeAcceptConentLogic:OnHide()

end


return LoginAgeAcceptConentLogic
