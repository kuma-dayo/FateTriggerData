--[[
    玩家统计数据模块
]]
require("Client.Modules.PlayerStat.PlayerStatModel")

local class_name = "PlayerStatCtrl";
PlayerStatCtrl = PlayerStatCtrl or BaseClass(UserGameController,class_name);

function PlayerStatCtrl:__init()
    -- CLog("==PlayerStatCtrl init")
    self.Model = nil
end

function PlayerStatCtrl:Initialize()
    -- CLog("==PlayerStatCtrl Initialize")
    self.Model = self:GetModel(PlayerStatModel)
end

--[[
    玩家登入的时候，进行请求数据
]]
function PlayerStatCtrl:OnLogin(data)
end

--[[
    玩家登出
]]
function PlayerStatCtrl:OnLogout(data)
    -- CLog("PlayerStatCtrl OnLogout")
end

function PlayerStatCtrl:AddMsgListenersUser()
    self.ProtoList = {
        {MsgName = Pb_Message.PlayerStatSyncData, Func = self.PlayerStatSyncData_Func },
    }
end

--[[
    玩家统计数据同步
]]
function PlayerStatCtrl:PlayerStatSyncData_Func(Msg)
    print_r(Msg,"PlayerStatCtrl:PlayerStatSyncData_Func",true)
    self.Model:PlayerStatSyncData_Func(Msg)
end
