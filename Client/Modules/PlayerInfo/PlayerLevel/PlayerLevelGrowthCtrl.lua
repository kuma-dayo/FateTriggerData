--[[
    等级成长历程协议处理模块
]]
require("Client.Modules.PlayerInfo.PlayerLevel.PlayerLevelGrowthModel")
local class_name = "PlayerLevelGrowthCtrl"
---@class PlayerLevelGrowthCtrl : UserGameController
PlayerLevelGrowthCtrl = PlayerLevelGrowthCtrl or BaseClass(UserGameController,class_name)


function PlayerLevelGrowthCtrl:__init()
    CWaring("==PlayerLevelGrowthCtrl init")
    ---@type PlayerLevelGrowthModel
	self.PlayerLevelGrowthModel = MvcEntry:GetModel(PlayerLevelGrowthModel)
end

function PlayerLevelGrowthCtrl:Initialize()
end

--[[
    玩家登入
]]
function PlayerLevelGrowthCtrl:OnLogin(data)
    CWaring("PlayerLevelGrowthCtrl OnLogin")
end


function PlayerLevelGrowthCtrl:AddMsgListenersUser()
    self.ProtoList = {
    	-- {MsgName = Pb_Message.PlayerLevelUpSyc,	Func = self.PlayerLevelUpSyc_Func },
		{MsgName = Pb_Message.PlayerReceiveLevelRewardRsp,	Func = self.PlayerReceiveLevelRewardRsp_Func },
    }
	self.MsgList = {
        { Model = UserModel, MsgName = UserModel.ON_PLAYER_LEVEL_UP_SYC_DATA,    Func = self.PlayerLevelUpSyc_Func },
	}
end

--[[
	Msg = {
		int32 Level=1; -- 等级
		int32 Experience=2; 经验
		repeated PlayerAdvanceLevelData AdvanceLevelData = 3 奖励状态
	}
]]
-- 请求玩家等级成长奖励状态返回
function PlayerLevelGrowthCtrl:PlayerLevelUpSyc_Func(Msg)
	print_r(Msg, "[hz] PlayerLevelGrowthCtrl:PlayerLevelUpSyc_Func ==== Msg")
	self.PlayerLevelGrowthModel:On_PlayerLevelUpSyc(Msg)
end

--[[
	Msg = {
		int32 Level = 1;                // 领取奖励等级
		repeated PlayerAdvanceLevelData AdvanceLevelData = 2;   奖励状态
	}
]]
-- 领取等级奖励请求返回
function PlayerLevelGrowthCtrl:PlayerReceiveLevelRewardRsp_Func(Msg)
	print_r(Msg, "[hz] PlayerLevelGrowthCtrl:PlayerReceiveLevelRewardRsp_Func ==== Msg")
	self.PlayerLevelGrowthModel:On_PlayerReceiveLevelRewardRsp(Msg)
end
------------------------------------请求相关----------------------------

-- 玩家等级成长奖励状态请求
function PlayerLevelGrowthCtrl:SendProtoPlayerLevelReq()
	local Msg = {

	}
	self:SendProto(Pb_Message.PlayerLevelReq, Msg, Pb_Message.PlayerLevelUpSyc)
end

-- 领取等级奖励请求
---@param Level number 领取奖励等级
function PlayerLevelGrowthCtrl:SendProtoPlayerReceiveLevelRewardReq(Level)
	local Msg = {
		Level = Level,
	}
	self:SendProto(Pb_Message.PlayerReceiveLevelRewardReq, Msg, Pb_Message.PlayerReceiveLevelRewardRsp)
end