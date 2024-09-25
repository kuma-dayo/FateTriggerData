--[[
    系统解锁协议处理模块
]]

require("Client.Modules.System.NewSystemUnlockModel")
local class_name = "NewSystemUnlockCtrl"
---@class NewSystemUnlockCtrl : UserGameController
NewSystemUnlockCtrl = NewSystemUnlockCtrl or BaseClass(UserGameController,class_name)


function NewSystemUnlockCtrl:__init()
    CWaring("==NewSystemUnlockCtrl init")
end

function NewSystemUnlockCtrl:Initialize()
    self.NewSystemUnlockModel = MvcEntry:GetModel(NewSystemUnlockModel)
end
function NewSystemUnlockCtrl:__dispose()
    NewSystemUnlockCtrl.super.__dispose()
end
--[[
    玩家登入
]]
function NewSystemUnlockCtrl:OnLogin(data)
    CWaring("NewSystemUnlockCtrl OnLogin")
    self:SendProto_PlayerUnLockInfoReq()
end


function NewSystemUnlockCtrl:AddMsgListenersUser()
    self.ProtoList = {
    	{MsgName = Pb_Message.PlayerUnLockInfoRsp,	Func = self.PlayerUnLockInfoRsp_Func },
		{MsgName = Pb_Message.PlayerUnLockNotify,	Func = self.PlayerUnLockNotify_Func },
    }
end

-- 获取所有的解锁Id信息
function NewSystemUnlockCtrl:PlayerUnLockInfoRsp_Func(Msg)
    self.NewSystemUnlockModel:UpdateUnlockInfo(Msg.UnLockIdList,true)
    self.NewSystemUnlockModel:DispatchType(NewSystemUnlockModel.ON_PLAYER_UNLOCK_INFO_INITED)
end

-- 主动通知，解锁Id解锁
function NewSystemUnlockCtrl:PlayerUnLockNotify_Func(Msg)
    self.NewSystemUnlockModel:UpdateUnlockInfo(Msg.UnLockIdList)
end

------------------------------------请求相关----------------------------

-- 请求获取所有的解锁Id信息
function NewSystemUnlockCtrl:SendProto_PlayerUnLockInfoReq()
    local Msg = {
    }
    self: SendProto(Pb_Message.PlayerUnLockInfoReq,Msg,Pb_Message.PlayerUnLockInfoRsp)
end


