--[[
    封禁状态 协议处理模块
]]
require("Client.Modules.Ban.BanModel")
local class_name = "BanCtrl"
---@class BanCtrl : UserGameController
BanCtrl = BanCtrl or BaseClass(UserGameController,class_name)


function BanCtrl:__init()
    CWaring("==BanCtrl init")
    ---@type BanModel
	self.BanModel = MvcEntry:GetModel(BanModel)
end

function BanCtrl:Initialize()
end

--[[
    玩家登入
]]
function BanCtrl:OnLogin(data)
    CWaring("BanCtrl OnLogin")
end

function BanCtrl:OnDayRefresh()
    CWaring("BanCtrl ========================= OnDayRefresh")
end


function BanCtrl:AddMsgListenersUser()
    self.ProtoList = {
    	{MsgName = Pb_Message.BanDataSync,	Func = self.BanDataSync_Func },
    }
end

--Ban.proto

--[[
	Msg = {
	    repeated BanData BanList    = 1;    // 禁止列表
	}
]]
function BanCtrl:BanDataSync_Func(Msg)
	self.BanModel:On_BanDataSync(Msg)
end



------------------------------------请求相关----------------------------



