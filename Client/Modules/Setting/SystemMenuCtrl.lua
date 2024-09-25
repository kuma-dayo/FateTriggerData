--[[
    系统菜单协议处理模块
]]

require("Client.Modules.Setting.SystemMenuConst")
require("Client.Modules.Setting.SystemMenuModel")
local class_name = "SystemMenuCtrl"
---@class SystemMenuCtrl : UserGameController
SystemMenuCtrl = SystemMenuCtrl or BaseClass(UserGameController,class_name)


function SystemMenuCtrl:__init()
    CWaring("==SystemMenuCtrl init")
end

function SystemMenuCtrl:Initialize()
    ---@type SystemMenuModel
    self.SystemMenuModel = MvcEntry:GetModel(SystemMenuModel)
    ---@type GVoiceModel
    self.GVoiceModel = MvcEntry:GetModel(GVoiceModel)
end

--[[
    玩家登入
]]
function SystemMenuCtrl:OnLogin(data)
    CWaring("SystemMenuCtrl OnLogin")
    -- self.SystemMenuModel:OnLogin()
end

function SystemMenuCtrl:OnLogout()
    -- self.SystemMenuModel:OnLogout()
end

-- function SystemMenuCtrl:AddMsgListenersUser()
--     self.ProtoList = {
        
--     }
-- end

function SystemMenuCtrl:EnableTeamMic(IsEnable)
    if not self.GVoiceModel.SelfRoomName then
        return
    end
    MvcEntry:GetCtrl(GVoiceCtrl):EnableRoomMicrophone(self.GVoiceModel.SelfRoomName,IsEnable)
end

function SystemMenuCtrl:EnableTeamSpeaker(IsEnable)
    if not self.GVoiceModel.SelfRoomName then
        return
    end
    MvcEntry:GetCtrl(GVoiceCtrl):EnableRoomSpeaker(self.GVoiceModel.SelfRoomName,IsEnable)
end

