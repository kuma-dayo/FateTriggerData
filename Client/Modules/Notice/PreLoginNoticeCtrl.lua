require("Client.Modules.Notice.PreLoginNoticeModel")
local class_name = "PreLoginNoticeCtrl"
---@class PreLoginNoticeCtrl : UserGameController
---@field private super UserGameController
PreLoginNoticeCtrl = PreLoginNoticeCtrl or BaseClass(UserGameController, class_name)

function PreLoginNoticeCtrl:__init()
    CWaring("==PreLoginNoticeCtrl init")
    self.Model = nil
end


function PreLoginNoticeCtrl:Initialize()
    self.Model = MvcEntry:GetModel(PreLoginNoticeModel)
end

--- 玩家登出
---@param data any
function PreLoginNoticeCtrl:OnLogout(data)
    CWaring("PreLoginNoticeCtrl OnLogout")
end

function PreLoginNoticeCtrl:OnLogin(data)
    CWaring("PreLoginNoticeCtrl OnLogin")
    -- self.Model:OnLogin()
end
