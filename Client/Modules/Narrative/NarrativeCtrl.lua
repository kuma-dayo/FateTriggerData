require("Client.Modules.Narrative.NarrativeModel")
local class_name = "NarrativeCtrl"
---@class NarrativeCtrl : UserGameController
---@field private super UserGameController
NarrativeCtrl = NarrativeCtrl or BaseClass(UserGameController, class_name)

function NarrativeCtrl:__init()
    CWaring("==NarrativeCtrl init")
    self.Model = nil
end


function NarrativeCtrl:Initialize()
    self.Model = self:GetModel(NarrativeModel)
end

--- 玩家登出
---@param data any
function NarrativeCtrl:OnLogout(data)
    CWaring("NarrativeCtrl OnLogout")
end

function NarrativeCtrl:OnLogin(data)
    CWaring("NarrativeCtrl OnLogin")
    -- self.Model:OnLogin()
end
