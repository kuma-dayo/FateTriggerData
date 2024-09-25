--[[
    赛季排位协议处理模块
]]
require("Client.Modules.Season.Rank.SeasonRankModel")
local class_name = "SeasonRankCtrl"
---@class SeasonRankCtrl : UserGameController
SeasonRankCtrl = SeasonRankCtrl or BaseClass(UserGameController,class_name)


function SeasonRankCtrl:__init()
    CWaring("==SeasonRankCtrl init")
    ---@type SeasonRankModel
	self.SeasonRankModel = MvcEntry:GetModel(SeasonRankModel)
end

function SeasonRankCtrl:Initialize()
end

--[[
    玩家登入
]]
function SeasonRankCtrl:OnLogin(data)
    CWaring("SeasonRankCtrl OnLogin")
end


function SeasonRankCtrl:AddMsgListenersUser()
    self.ProtoList = {
    	{MsgName = Pb_Message.DivisionDistributionInfoRes,	Func = self.DivisionDistributionInfoRes_Func},
        {MsgName = Pb_Message.PersonalDivisionInfoRes,	Func = self.PersonalDivisionInfoRes_Func},
        {MsgName = Pb_Message.PersonalDivisionRankInfoRes,	Func = self.PersonalDivisionRankInfoRes_Func},
        {MsgName = Pb_Message.DivisionRewardRes,	Func = self.DivisionRewardRes_Func},
    }
end

--[[
    DivisionQueryParam QueryParam = 1; 
    repeated int32 Distribution = 2;  //每个段位的人数
]]
-- 段位分布信息回复
function SeasonRankCtrl:DivisionDistributionInfoRes_Func(Msg)
    print_r(Msg, "[hz] SeasonRankCtrl:DivisionDistributionInfoRes_Func() ==== Msg")
    if Msg and Msg.QueryParam and Msg.Distribution then
        self.SeasonRankModel:On_DivisionDistributionInfoRes(Msg) 
    end
end

--[[
    DivisionQueryParam QueryParam = 1; 
    int32 DivisionId = 2;                           //当前所在段位Id
    int32 WinPoint = 3;                             //胜点
    repeated DivisionRewardIdAndStatus DivisionRewardIdAndStatus = 4;  //奖励状态列表
]]
-- 个人段位信息回复
function SeasonRankCtrl:PersonalDivisionInfoRes_Func(Msg)
    print_r(Msg, "[hz] SeasonRankCtrl:PersonalDivisionInfoRes_Func() ==== Msg")
    if Msg and Msg.QueryParam and Msg.DivisionRewardIdAndStatus then
        self.SeasonRankModel:On_PersonalDivisionInfoRes(Msg)
    end
end

-- message PersonalDivisionRankInfoRes
-- {
--     DivisionQueryParam QueryParam = 1; 
--     int32 DivisionId = 2; 
--     int32 DivisionRankRatio=3;               //超过xx%的玩家（按照小段计算，各段位权重数值同段位天梯图，精确到小数点0位，向下取整）
--     int32 DivisionRank = 4;                      //超限者段位显示实时排名（分端）
-- }
-- 个人段位排名信息回复
function SeasonRankCtrl:PersonalDivisionRankInfoRes_Func(Msg)
    print_r(Msg, "[hz] SeasonRankCtrl:PersonalDivisionRankInfoRes_Func() ==== Msg")
    if Msg and Msg.QueryParam then
        self.SeasonRankModel:On_PersonalDivisionRankInfoRes(Msg)
    end
end

--[[
    DivisionQueryParam QueryParam = 1; 
    int32 DivisionId = 2;                                                                         //当前所在段位Id
    DivisionRewardIdAndStatus RewardIdStatus = 3;                                                 //当前奖励状态
    int32  ErrCode  = 4;                                                                          //错误码
]]
-- 领用奖励回复
function SeasonRankCtrl:DivisionRewardRes_Func(Msg)
    print_r(Msg, "[hz] SeasonRankCtrl:DivisionRewardRes_Func() ==== Msg")
    if Msg and Msg.QueryParam and Msg.RewardIdStatus then
        if Msg.ErrCode == ErrorCode.Success.ID then
            self.SeasonRankModel:On_DivisionRewardRes(Msg)
        else
            local MsgObject = {
                ErrCode = Msg.ErrCode,
                ErrCmd = "",
                ErrMsg = "",
            }
            MvcEntry:GetCtrl(ErrorCtrl):PopTipsAction(MsgObject, ErrorCtrl.TIP_TYPE.ERROR_CONFIG)
        end
    end
end

------------------------------------请求相关----------------------------

--- 段位分布信息请求
---@param SeasonId number 赛季ID
---@param RankPlayMapId number 当前选择的RankPlayMapId (RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id)
function SeasonRankCtrl:SendProto_DivisionDistributionInfoReq(SeasonId, RankPlayMapId)
	local Msg = {
        QueryParam = {
            SeasonId = SeasonId,
            RankPlayMapId = RankPlayMapId,
        }
	}
    print_r(Msg, "[hz] SeasonRankCtrl:SendProto_DivisionDistributionInfoReq() ==== Msg")
	self:SendProto(Pb_Message.DivisionDistributionInfoReq, Msg, Pb_Message.DivisionDistributionInfoRes)
end

--- 个人段位信息请求
---@param SeasonId number 赛季ID
---@param RankPlayMapId number 当前选择的RankPlayMapId (RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id)
function SeasonRankCtrl:SendProto_PersonalDivisionInfoReq(SeasonId, RankPlayMapId)
	local Msg = {
        QueryParam = {
            SeasonId = SeasonId,
            RankPlayMapId = RankPlayMapId,
        }
	}
    print_r(Msg, "[hz] SeasonRankCtrl:SendProto_PersonalDivisionInfoReq() ==== Msg")
	self:SendProto(Pb_Message.PersonalDivisionInfoReq, Msg, Pb_Message.PersonalDivisionInfoRes)
end

--- 个人段位排名信息请求
---@param SeasonId number 赛季ID
---@param RankPlayMapId number 当前选择的RankPlayMapId (RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id)
function SeasonRankCtrl:SendProto_PersonalDivisionRankInfoReq(SeasonId, RankPlayMapId)
	local Msg = {
        QueryParam = {
            SeasonId = SeasonId,
            RankPlayMapId = RankPlayMapId,
        }
	}
    print_r(Msg, "[hz] SeasonRankCtrl:SendProto_PersonalDivisionRankInfoReq() ==== Msg")
	self:SendProto(Pb_Message.PersonalDivisionRankInfoReq, Msg, Pb_Message.PersonalDivisionRankInfoRes)
end

--- 领用奖励请求
---@param SeasonId number 赛季ID
---@param RankPlayMapId number 当前选择的RankPlayMapId (RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id)
---@param DivisionId number 唯一段位ID
function SeasonRankCtrl:SendProto_DivisionRewardReq(SeasonId,RankPlayMapId,DivisionId)
	local Msg = {
        QueryParam = {
            SeasonId = SeasonId,
            RankPlayMapId = RankPlayMapId,
        },
		DivisionId = DivisionId,
	}
    print_r(Msg, "[hz] SeasonRankCtrl:SendProto_DivisionRewardReq() ==== Msg")
	self:SendProto(Pb_Message.DivisionRewardReq, Msg, Pb_Message.DivisionRewardRes)
end