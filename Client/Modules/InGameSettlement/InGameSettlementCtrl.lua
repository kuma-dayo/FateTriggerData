---
--- Ctrl 模块，主要用于处理协议
--- Description: 局内结算相关协议，先放在这里，后续再说
--- Created At: 2023/08/03 18:53
--- Created By: 朝文
---

local class_name = "InGameSettlementCtrl"
---@class InGameSettlementCtrl : UserGameController
InGameSettlementCtrl = InGameSettlementCtrl or BaseClass(UserGameController, class_name)

function InGameSettlementCtrl:__init()
    self.Model = nil
end

function InGameSettlementCtrl:Initialize()
    -- self.Model = self:GetModel(InGameSettlementModel)
end

function InGameSettlementCtrl:AddMsgListenersUser()
    --添加协议回包监听事件
    self.ProtoList = {
        {MsgName = Pb_Message.GamePlayerSettlementSync,   Func = self.OnGamePlayerSettlementSync},
        {MsgName = Pb_Message.GameTeamSettlementSync,     Func = self.OnGameTeamSettlementSync},
        {MsgName = Pb_Message.GameBattleSettlementSync,   Func = self.OnGameBattleSettlementSync},
        {MsgName = Pb_Message.GameCampSettlementSync,   Func = self.OnGameCampSettlementSync},
    }
end

-----------------------------------------请求相关------------------------------

-- 响应登录信息
function InGameSettlementCtrl:OnGamePlayerSettlementSync(PlayerSettlement)
    print_r(PlayerSettlement, "[cw] ====PlayerSettlement")
    GameLog.Dump(PlayerSettlement, PlayerSettlement)
    MsgHelper:Send(nil, MsgDefine.SETTLEMENT_PlayerSettlement, PlayerSettlement)
end

-- BR结算协议返回
function InGameSettlementCtrl:OnGameTeamSettlementSync(TeamSettlement)
    print_r(TeamSettlement, "[cw] ====TeamSettlement")
    GameLog.Dump(TeamSettlement, TeamSettlement)
    MsgHelper:Send(nil, MsgDefine.SETTLEMENT_TeamSettlement, TeamSettlement)

    -- 讲BR模式结算协议注册进model
    local MatchConst = require("Client.Modules.Match.MatchConst")
    ---@type HallSettlementModel
    local HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)
    HallSettlementModel:SetSettlementData(MatchConst.Enum_MatchType.Survive, TeamSettlement)
end

function InGameSettlementCtrl:OnGameBattleSettlementSync(BattleSettlement)
    print_r(BattleSettlement, "[cw] ====BattleSettlement")
    GameLog.Dump(BattleSettlement, BattleSettlement)
    MsgHelper:Send(nil, MsgDefine.SETTLEMENT_GameSettlement, BattleSettlement)
end

-- 新模式（团竞、死斗、征服等）新增基于阵营的结算协议
function InGameSettlementCtrl:OnGameCampSettlementSync(CampSettlement)
    print_r(CampSettlement, "[cw] ====CampSettlement")
    GameLog.Dump(CampSettlement, CampSettlement)
    MsgHelper:Send(nil, MsgDefine.SETTLEMENT_CampSettlement, CampSettlement)

    --局外结算使用相同的数据，这里先做一下缓存
    --[[
    lua.do  local InData = {
        FuncName = "CampSettlement";
        Param = {};
    };
    MvcEntry:GetCtrl(GMPanelCtrl):ReqCallFunc(InData);
    
    --]]

    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    local ModeId = MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(CampSettlement.GameplayCfg.LevelId)
    local GameType = MatchModeSelectModel:GetModeEntryCfg_ModeType(ModeId)

    ---@type HallSettlementModel
    local HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)
    HallSettlementModel:SetSettlementData(GameType, CampSettlement)
end