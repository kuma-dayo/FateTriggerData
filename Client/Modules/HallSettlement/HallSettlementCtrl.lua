---
--- Ctrl 模块，主要用于处理协议
--- Description: 大厅结算，协议及控制
--- Created At: 2023/04/07 17:00
--- Created By: 朝文
---

require("Client.Modules.HallSettlement.HallSettlementModel")

local class_name = "HallSettlementCtrl"
---@class HallSettlementCtrl : UserGameController
HallSettlementCtrl = HallSettlementCtrl or BaseClass(UserGameController, class_name)

function HallSettlementCtrl:__init()
    ---@type HallSettlementModel
    self.Model = nil
end

---用户从大厅进入战斗处理的逻辑
---进入战斗时，清一下结算数据 防止有数据残留
function HallSettlementCtrl:OnPreEnterBattle()
    CLog("HallSettlementCtrl:OnPreEnterBattle")
    self.Model:ClearSettlementData()
end

function HallSettlementCtrl:Initialize()
    self.Model = self:GetModel(HallSettlementModel)
end

---尝试展示大厅结算面板，此时有缓存才显示，没有缓存则不显示
---@param endCallback function 打开失败或成功打开后的界面被关闭时触发的回调
function HallSettlementCtrl:TryingToShowHallSettlement(endCallback)
    ---@type MainCtrl
    local MvcEntry = MvcEntry
    ---@type HallSettlementModel
    local HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)
    CLog("[cw] HallSettlementModel:HasSettlementCache()")
    self:SendProtoSetLobbyStatusReqReq()
    self.Model:SetHideViewCallbackFunc(endCallback)

    local IsRankMode = HallSettlementModel:CheckIsRankModeSettlement()
    if IsRankMode then
        local IsUpgradeDivision = HallSettlementModel:CheckIsUpgradeDivision()
        local DivisionSettmentViewId = IsUpgradeDivision and ViewConst.SeasonRankUpgradeSettlement or ViewConst.SeasonRankSettlement
        MvcEntry:OpenView(DivisionSettmentViewId)
    else
        MvcEntry:OpenView(ViewConst.HallSettlement)   ---@see HallSettlementMdt_Obj#OnShow() 
    end
end

function HallSettlementCtrl:AddMsgListenersUser()
    self.ProtoList = {
        -- {MsgName = Pb_Message.TeamSettlementSync, Func = self.OnTeamSettlementSync},
    }

    self.MsgList = {
        {Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_DEACTIVE_CHANGED,  Func = self.OnOtherViewClosed },
        {Model = HallModel, MsgName = HallModel.HALL_PLAY_SPAWN_SELF_AVATAR,  Func = self.CheckPlayHeroVoice },
    }
end


---播放英雄语音，包含四种情况
--- 1) 使用了主界面展示的英雄，且进了前50%
--- 2) 使用了主界面展示的英雄，且没进前50%
--- 3) 没有使用主界面展示的英雄，且进了前50%
--- 4) 没有使用主界面展示的英雄，且没进前50%
function HallSettlementCtrl:CheckPlayHeroVoice()
    ---@type HallSettlementModel
    local HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)
    local PlayHeroVoiceInfo = HallSettlementModel:GetPlayHeroVoiceInfo()
    if PlayHeroVoiceInfo then
        SoundMgr:PlayHeroVoice(PlayHeroVoiceInfo.SkinId, PlayHeroVoiceInfo.EventID)
        HallSettlementModel:ClearPlayHeroVoiceInfo()
    end
end

-- 监听界面关闭事件
function HallSettlementCtrl:OnOtherViewClosed(ViewId)
    -- 排位结算相关界面关闭，打开结算面板
    if ViewId == ViewConst.SeasonRankSettlement or ViewId == ViewConst.SeasonRankUpgradeSettlement then
        local HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)
        if HallSettlementModel:HasSettlementCache() then
            MvcEntry:OpenView(ViewConst.HallSettlement)   ---@see HallSettlementMdt_Obj#OnShow() 
        end
    end
end

-----------------------------------------请求相关------------------------------

--[[
    Msg = {
        GameId = 123,
        RankNum = 1,
        TotalTeams = 100,
        GameplayCfg = {
            TeamType = 4,
            GameplayId = 10005,
            View = 3,
            LevelId = 1031002,
        },
        Level = 1,              // 当前等级
        Experience = 50,        // 当前经验
        DeltaExperience = 120,  // 增量经验

        Settlements = {
            [1] = {
                PlayerId = 1,
                HeroTypeId = 200030001,
                PlayerName = "玩家1",
                PlayerSurvivalTime = 1234,
                PlayerKill = 1,
                PlayerAssist = 2,
                RespawnTimes = 12,
                PlayerDamage = 1234,
                PosInTeam = 1
            },
            [2] = {
                PlayerId = 2,
                HeroTypeId = 200030002,
                PlayerName = "玩家2",
                PlayerSurvivalTime = 1111,
                PlayerKill = 3,
                PlayerAssist = 4,
                RespawnTimes = 22,
                PlayerDamage = 333334,
                PosInTeam = 2
            },
        }
    }
--]]
-- 协议合并到Battle.proto里的GameTeamSettlement里  做统一
-- ---@param Msg table 上一局数据的协议
-- function HallSettlementCtrl:OnTeamSettlementSync(Msg)
--     CLog("[cw] HallSettlementCtrl:OnTeamSettlementSync(" .. tostring(Msg) .. ")")
--     if Msg then print_r(Msg, "[cw] Msg") end

--     local MatchConst = require("Client.Modules.Match.MatchConst")
--     self.Model:SetSettlementData(MatchConst.Enum_MatchType.Survive, Msg)
-- end

-- 玩家设置到大厅状态 当前只允许结算状态时主动设置
function HallSettlementCtrl:SendProtoSetLobbyStatusReqReq()
    CLog("HallSettlementCtrl:SendProtoSetLobbyStatusReqReq")
    local Msg = {

	}
	self:SendProto(Pb_Message.SetLobbyStatusReq, Msg)
end