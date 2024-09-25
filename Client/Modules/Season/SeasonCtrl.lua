--[[
    赛季控制模块
]]
require("Client.Modules.Season.SeasonConst")
require("Client.Modules.Season.SeasonModel")
require("Client.Modules.Season.Lottery.SeasonLotteryModel")

local class_name = "SeasonCtrl";
SeasonCtrl = SeasonCtrl or BaseClass(UserGameController,class_name);

function SeasonCtrl:__init()
    CWaring("==SeasonCtrl init")
    self.Model = nil
end

function SeasonCtrl:Initialize()
    CWaring("==SeasonCtrl Initialize")
    self.Model = self:GetModel(SeasonModel)
    self.ModelLottery = self:GetModel(SeasonLotteryModel)
end

--[[
    玩家登入的时候，进行请求数据
]]
function SeasonCtrl:OnLogin(data)
    --TODO 请求已开放的奖池信息
    self:SendProto_PlayerGetStartLotteryReq()
end

--[[
    玩家登出
]]
function SeasonCtrl:OnLogout(data)
    CWaring("SeasonCtrl OnLogout")
end

function SeasonCtrl:AddMsgListenersUser()
    self.ProtoList = {
        {MsgName = Pb_Message.SeasonChangeSync, Func = self.SeasonChangeSync_Func },

        {MsgName = Pb_Message.SeasonWeaponDataRsp,	Func = self.SeasonWeaponDataRsp_Func },

        --抽奖相关
        --返回：获取当前正在开放的奖池
        {MsgName = Pb_Message.PlayerGetStartLotteryRsp,	Func = self.PlayerGetStartLotteryRsp_Func },
        --返回：获取某个奖池当前已抽奖次数
        {MsgName = Pb_Message.PlayerLotteryInfoRsp,	Func = self.PlayerLotteryInfoRsp_Func },
        --返回：获取某个奖池的奖池概率信息
        {MsgName = Pb_Message.PlayerGetPrizePoolRateRsp,	Func = self.PlayerGetPrizePoolRateRsp_Func },
        --返回：获取某个类型的抽奖记录信息
        {MsgName = Pb_Message.PlayerGetLotteryRecordRsp,	Func = self.PlayerGetLotteryRecordRsp_Func },
        --返回：抽奖结果返回
        {MsgName = Pb_Message.PlayerLotteryRsp,	Func = self.PlayerLotteryRsp_Func },
    }
end


function SeasonCtrl:SendProto_SeasonWeaponDataReq(SeasonId, WeaponId)
    local Msg = {
        SeasonId = SeasonId,
        WeaponId = WeaponId,
    }
    self:SendProto(Pb_Message.SeasonWeaponDataReq, Msg, Pb_Message.SeasonWeaponDataRsp)
end

--[[
    // 赛季变化同步
    message SeasonChangeSync
    {
        int32 SeasonId = 1;
    }
]]
function SeasonCtrl:SeasonChangeSync_Func(Msg)
    self.Model:UpdateCurrentSeasonId(Msg.SeasonId)
end

--[[
    赛季武器数据
        message SeasonWeaponDataRsp
        {
            int64 WeaponId = 1;
            int32 KnockDownNum = 2;
            int32 KillNum = 3;
            int32 HeadShotNum = 4;
            int64 TotalDamage = 5;
            int64 PossessedTime = 6;
        }
]]
function SeasonCtrl:SeasonWeaponDataRsp_Func(Msg)
    if self.Model == nil then
        return
    end
    local SeasonWeaponData = 
    {
        SeasonId = Msg.SeasonId,
        WeaponId = Msg.WeaponId,
        KnockDownNum = Msg.KnockDownNum,
        KillNum = Msg.KillNum,
        HeadShotNum = Msg.HeadShotNum,
        TotalDamage = Msg.TotalDamage,
        PossessedTime = Msg.PossessedTime
    }
    self.Model:AddSeasonWeaponData(SeasonWeaponData)

    self.Model:DispatchType(SeasonModel.ON_ADD_SEASON_WEAPON_DATA)
end

-----------------------------------------------------抽奖相关------------------------------------------------------------
--协议返回
function SeasonCtrl:PlayerGetStartLotteryRsp_Func(Msg)
    self.ModelLottery:PlayerGetStartLotteryRsp_Func(Msg)
end
function SeasonCtrl:PlayerLotteryInfoRsp_Func(Msg)
    self.ModelLottery:PlayerLotteryInfoRsp_Func(Msg)
end
function SeasonCtrl:PlayerGetPrizePoolRateRsp_Func(Msg)
    self.ModelLottery:PlayerGetPrizePoolRateRsp_Func(Msg)
end
function SeasonCtrl:PlayerGetLotteryRecordRsp_Func(Msg)
    self.ModelLottery:PlayerGetLotteryRecordRsp_Func(Msg)
end
function SeasonCtrl:PlayerLotteryRsp_Func(Msg)
    self.ModelLottery:PlayerLotteryRsp_Func(Msg)
end
--协议请求
--[[
    获取已经开始的奖池列表
]]
function SeasonCtrl:SendProto_PlayerGetStartLotteryReq()
    self:SendProto(Pb_Message.PlayerGetStartLotteryReq,{})
end
--[[
    获取某个奖池已抽奖的次数
]]
function SeasonCtrl:SendProto_PlayerLotteryInfoReq(PrizePoolId)
    local Msg = {
        PrizePoolId = PrizePoolId,
    }
    self:SendProto(Pb_Message.PlayerLotteryInfoReq,Msg,Pb_Message.PlayerLotteryInfoRsp)
end
--[[
    请求抽奖
]]
function SeasonCtrl:SendProto_PlayerLotteryReq(PrizePoolId,Count)
    local Msg = {
        PrizePoolId = PrizePoolId,
        Count = Count,
    }
    self:SendProto(Pb_Message.PlayerLotteryReq,Msg,Pb_Message.PlayerLotteryRsp)
end
--[[
    请求对应奖池的概率信息
]]
function SeasonCtrl:SendProto_PlayerGetPrizePoolRateReq(PrizePoolId)
    local Msg = {
        PrizePoolId = PrizePoolId,
    }
    self:SendProto(Pb_Message.PlayerGetPrizePoolRateReq,Msg,Pb_Message.PlayerGetPrizePoolRateRsp)
end
--[[
    请求对应抽奖类型的抽奖记录
]]
function SeasonCtrl:SendProto_PlayerGetLotteryRecordReq(RecordType)
    local Msg = {
        RecordType = RecordType,
    }
    self:SendProto(Pb_Message.PlayerGetLotteryRecordReq,Msg,Pb_Message.PlayerGetLotteryRecordRsp)
end

