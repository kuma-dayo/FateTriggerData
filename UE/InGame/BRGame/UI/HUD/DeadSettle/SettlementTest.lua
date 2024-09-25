--
-- 结算
--
-- @COMPANY	ByteDance
-- @AUTHOR	邱天
-- @DATE	2022.11.09
--

local SettlementTest = { }



------------------------------------------- Test    ----------------------------------------

function SettlementTest:OnPlayerSettlement ()
    --测试数据
    local PlayerSettlement = {
        PlayerId = 280,
        RuntimeHeroId = 200010000,
        PlayerName = "test1",
        PlayerKill = 10,
        KnockDown = 11,
        RescueTimes = 12,
        RespawnTimes = 13,
        RemainingPlayers = 14,
        RemainingTeams = 15,
        PlayerSurvivalTime = 0,
        PlayerAssist = 0,
        PlayerDamage = 0,
    }

    Settlement.bLocalSettlementGM = true

    MsgHelper:Send(nil, MsgDefine.SETTLEMENT_PlayerSettlement, PlayerSettlement)
end
SettlementTest.PlayerList = {
    [0] = {
        PlayerId = 259,
        RuntimeHeroId = 200010000,
        PlayerName = "test1",
        PlayerKill = 10,
        KnockDown = 11,
        RescueTimes = 12,
        RespawnTimes = 13,
        RemainingPlayers = 14,
        RemainingTeams = 15,
        PlayerSurvivalTime = 0,
        PlayerAssist = 0,
        PlayerDamage = 0,
        PosInTeam = 1,
    },
    [1] = {
        PlayerId = 260,
        RuntimeHeroId = 200020000,
        PlayerName = "test2",
        PlayerKill = 10,
        KnockDown = 11,
        RescueTimes = 12,
        RespawnTimes = 13,
        RemainingPlayers = 14,
        RemainingTeams = 15,
        PlayerSurvivalTime = 0,
        PlayerAssist = 0,
        PlayerDamage = 0,
        PosInTeam = 2,
    },
    [2] = {
        PlayerId = 261,
        RuntimeHeroId = 200030000,
        PlayerName = "test3",
        PlayerKill = 10,
        KnockDown = 11,
        RescueTimes = 12,
        RespawnTimes = 13,
        RemainingPlayers = 14,
        RemainingTeams = 15,
        PlayerSurvivalTime = 0,
        PlayerAssist = 0,
        PlayerDamage = 0,
        PosInTeam = 3,
    }
}
function SettlementTest:OnPlayerTeamSettlement_Normal()
        --测试数据
    local TeamSettlement = {
        PlayerArray = SettlementTest.PlayerList,
        RemainingPlayers = 7,
        RemainingTeams = 6,
        bIsGameOver = false,
        bIsWinnerTeam = false,
    }
  
    Settlement.bLocalSettlementGM = true

    MsgHelper:Send(nil, MsgDefine.SETTLEMENT_TeamSettlement, TeamSettlement)
end

function SettlementTest:OnPlayerTeamSettlement_LastTeams_2()
        --测试数据
    local TeamSettlement = {
        PlayerArray = SettlementTest.PlayerList,
        RemainingPlayers = 7,
        RemainingTeams = 2,
        bIsGameOver = true,
        bIsWinnerTeam = false,
    }

    Settlement.bLocalSettlementGM = true
  
    MsgHelper:Send(nil, MsgDefine.SETTLEMENT_TeamSettlement, TeamSettlement)
end
function SettlementTest:OnPlayerTeamSettlement_LastTeams_1()
        --测试数据
    local TeamSettlement = {
        PlayerArray = SettlementTest.PlayerList,
        RemainingPlayers = 7,
        RemainingTeams = 1,
        bIsGameOver = true,
        bIsWinnerTeam = true,
    }
  
    Settlement.bLocalSettlementGM = true

    MsgHelper:Send(nil, MsgDefine.SETTLEMENT_TeamSettlement, TeamSettlement)
end

function SettlementTest:OnBattleSettlement()
    local GameSettlement = {
        GameId = 1,
        WinnerTeamId = 1,
    }

    Settlement.bLocalSettlementGM = true

    MsgHelper:Send(nil, MsgDefine.SETTLEMENT_GameSettlement, GameSettlement)
end

function SettlementTest:OnCacheOberserData()
    local OBData = UE.FObserveViewTargetDesc()
    local PC = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    if PC then
        OBData.ViewerPlayerState = PC.PlayerState
        OBData.ViewerActor = PC:K2_GetPawn()
        NotifyObjectMessage(self.LocalPC, "ObserveX.System.BecomeObserver", OBData)
    end
end

------------------------------------------- Require ----------------------------------------

return SettlementTest