--[[
    个人统计数据协议处理模块
]]
require("Client.Modules.PlayerInfo.PersonalStatistics.PersonalStatisticsModel")
local class_name = "PersonalStatisticsCtrl"
---@class PersonalStatisticsCtrl : UserGameController
PersonalStatisticsCtrl = PersonalStatisticsCtrl or BaseClass(UserGameController,class_name)


function PersonalStatisticsCtrl:__init()
    CWaring("==PersonalStatisticsCtrl init")
    ---@type PersonalStatisticsModel
	self.PersonalStatisticsModel = MvcEntry:GetModel(PersonalStatisticsModel)
end

function PersonalStatisticsCtrl:Initialize()
end

--[[
    玩家登入
]]
function PersonalStatisticsCtrl:OnLogin(data)
    CWaring("PersonalStatisticsCtrl OnLogin")
end


function PersonalStatisticsCtrl:AddMsgListenersUser()
    self.ProtoList = {
        -- 玩家信息相关
    	{MsgName = Pb_Message.SeasonBattleDataRsp,	Func = self.SeasonBattleDataRsp_Func},
    }

    self.MsgList = {
        { Model = ViewModel, MsgName = ViewConst.PlayerInfo,    Func = self.OnPlayerInfoState },
    }
end

--[[
    message MaxValBase
    {
        int32 Val = 1;
        int64 Time = 2;     // Max达成时间
    }
    //平均和Kda用下发的数据计算
    message SeasonBattleDataRsp
    {
        int32 SeasonId = 1;
        int32 TeamType = 2;
        int32 View = 3;
        MaxValBase MaxKill = 4;
        MaxValBase MaxDamage = 5;
        MaxValBase MaxAssist = 6;            // 最大助攻
        MaxValBase MaxRescue = 7;            // 最大救援
        MaxValBase MaxSurvivalTime = 8;      // 最大存活时间
        MaxValBase MaxHeal = 9;              // 最大治疗量
        MaxValBase MaxMoveDis = 10;          // 最大移动距离
        int64 TotGameTime = 11;         // 战斗时长
        int32 RecordsNum = 12;          // 战斗场次
        int32 WinNum = 13;              // 胜利次数
        int32 Top5Num = 14;             // 前5数
        int32 TotKill = 15;
        int64 TotSurvivalTime = 16;
        int64 TotDamage = 17;
        int32 TotHeadShotRate = 18;     // 爆头率
        int32 TotAssist = 19;           // 助攻总数
        int64 TotMoveDis = 20;          // 移动距离总数
        int32 TotRescue = 21;           // 救援总数
        int64 TotHeal = 22;             // 总治疗量
        int32 TotLike = 23;             // 总点赞
        int32 TotDeath = 24;            // 总死亡数
        int32 TotHeadShot = 25;         // 总爆头数
    }
]]
-- 请求赛季玩家个人战斗数据返回
function PersonalStatisticsCtrl:SeasonBattleDataRsp_Func(Msg)
    print_r(Msg, "[hz] PersonalStatisticsCtrl:SeasonBattleDataRsp_Func() ==== Msg")
	self.PersonalStatisticsModel:On_SeasonBattleDataRsp(Msg)
end

-- 关闭个人信息界面的时候 清空缓存的数据
function PersonalStatisticsCtrl:OnPlayerInfoState(State)
    if not State then
        self.PersonalStatisticsModel:ClearSeasonBattleDataList()
    end
end

------------------------------------请求相关----------------------------

-- 请求赛季玩家个人战斗数据
---@param SeasonId number 赛季ID
---@param TeamType number 队伍类型 1, 2, 4单双四
---@param View number 视角 1，3 第一第三人称
---@param QueryPlayerId number 请求的PlayerId 0为查询玩家自己
function PersonalStatisticsCtrl:SendProtoSeasonBattleDataReq(SeasonId, TeamType, View, QueryPlayerId)
	local Msg = {
		SeasonId = SeasonId,
		TeamType = TeamType,
		View = View,
        QueryPlayerId = QueryPlayerId,
	}
	self:SendProto(Pb_Message.SeasonBattleDataReq, Msg, Pb_Message.SeasonBattleDataRsp)
end




