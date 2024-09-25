--
-- 结算
--
-- @COMPANY	ByteDance
-- @AUTHOR	邱天
-- @DATE	2022.11.09
--

local Settlement = { }

-- PlayerRawData 
-- int32 PlayerId
-- int32 HeroId
-- FString PlayerName
-- // 击杀致死数
-- int32 PlayerKill = INDEX_NONE;
-- // 把人击倒数
-- int32 KnockDown = INDEX_NONE;
-- // 救援次数 （并不是BeRescued）
-- int32 RescueTimes = INDEX_NONE;
-- // 复活别人的次数 （并不是BeRespawned）
-- int32 RespawnTimes = INDEX_NONE;
-- // Player结算时：当前剩余玩家数量
-- int32 RemainingPlayers = INDEX_NONE;
-- // Player结算时：当前剩余队伍数量
--  int32 RemainingTeams = INDEX_NONE;
Settlement.PlayerRawData= {}

--TeamRawData
-- TArray<FS1Settlement_BR_Player> PlayerArray;
-- int32 RemainingPlayers = INDEX_NONE;
-- int32 RemainingTeams = INDEX_NONE;
-- bool bIsGameOver
-- bool bIsWinnerTeam
Settlement.TeamRawData= {}

--GameRawData
-- FString GameId = "0";
-- int32 WinnerTeamId = INDEX_NONE;
Settlement.GameRawData= {}



-- 结算类型 --0:个人 1：组队
Settlement.SettleMode = 0

-- 个人/组队排名
Settlement.SettleRank = 1

-- 结果类型
Settlement.EResultMode = {
	None = 0,
	DieToLive = 1,  -- 还能复活
	DieToOut = 2,   -- 死到不能复活
	Victory = 3,    -- 胜利
	AllDead = 4,    -- 全军覆没
	Finish = 5      -- 结束
}

-- 结算的模式类型
Settlement.EGameMode = {
	BR = 0,
	BR_Review = 1,
	TeamCompetition = 2,
	DeathFight = 3,
	Conquest = 4
}
-- 当前游戏模式
Settlement.CurrentGameMode = Settlement.EGameMode.BR
-- BR_Review:
Settlement.bReviewStart = false
Settlement.bForceReviewStart = true
Settlement.bIsTeamOver = false

-- 当前结果类型
Settlement.CurrentResultMode = Settlement.EResultMode.None
--玩家列表
Settlement.PlayerList = {}
--观察目标
Settlement.OBViewTargetDesc = nil


-- Editor本地结算
Settlement.bLocalSettlement = false
Settlement.LocalSettlement = {}

-- GM面板结算UI
Settlement.bLocalSettlementGM = false

-- 收到对局结束消息
Settlement.bReceivedBattleSettlement = false
Settlement.bReceivedPlayerSettlement = false

------------------------------------------- Require ----------------------------------------

SettlementProxy			= require "UE.InGame.BRGame.UI.HUD.DeadSettle.SettlementProxy"
if not BUILD_SHIPPING then
	SettlementTest			= require "UE.InGame.BRGame.UI.HUD.DeadSettle.SettlementTest"
end

------------------------------------------  Callable ------------------------------------

local function IsPlayerNotAdded(PlayerArray, PlayerId)
	for key, value in pairs(PlayerArray) do
		if value.PlayerId == PlayerId then
			return false
		end
	end

	return true
end

Settlement.ExitBattle = function()
	print("Settlement >> ExitBattle")
	MvcEntry:GetCtrl(CommonCtrl):ExitBattle(ConstUtil.ExitBattleReson.Normal)
end

Settlement.OnReviewStart = function()
	print("Settlement.OnReviewStart = true")
	Settlement.bReviewStart = true
end

Settlement.OnMode_TeamCompetition = function()
	Settlement.CurrentGameMode = Settlement.EGameMode.TeamCompetition
end

Settlement.OnMode_DeathFight = function()
	Settlement.CurrentGameMode = Settlement.EGameMode.DeathFight
end

Settlement.OnMode_Conquest = function()
	Settlement.CurrentGameMode = Settlement.EGameMode.Conquest
end

Settlement.OnLocalSettlementBRPlayer = function(InPlayerId, InPlayerInfo, InKillsAndDeathsInfo)
    print("OnSettlementBRPlayer")
    local SettlePlayerId = InPlayerId

    if InPlayerInfo.HeroTypeId then
        print("OnSettlementBRPlayer HeroTypeId:", InPlayerInfo.HeroTypeId)
    end

    if InPlayerInfo.RuntimeHeroId then
        print("OnSettlementBRPlayer RuntimeHeroId:", InPlayerInfo.RuntimeHeroId)
    end

    local SettleInfoPlayer =
    {
        HeroTypeId = InPlayerInfo.RuntimeHeroId,

        PlayerKill = InPlayerInfo.PlayerKill,
        KnockDown = InPlayerInfo.KnockDown,
        RescueTimes = InPlayerInfo.RescueTimes,
        RespawnTimes = InPlayerInfo.RespawnTimes,

        PlayerAssist = InPlayerInfo.PlayerAssist,
        PlayerDamage = InPlayerInfo.PlayerDamage,
        PlayerSurvivalTime = InPlayerInfo.PlayerSurvivalTime,

        RemainingPlayers = InPlayerInfo.RemainingPlayers,
        RemainingTeams = InPlayerInfo.RemainingTeams,
        PosInTeam = InPlayerInfo.PosInTeam,

        bIsTeamOver = InPlayerInfo.bIsTeamOver,
        bIsTeamWinner = InPlayerInfo.bIsTeamWinner,
        bRespawnable = InPlayerInfo.bRespawnable,

        bIsLive = InPlayerInfo.bIsLive,
        HealAmount = InPlayerInfo.HealAmount,
        MoveDistance = InPlayerInfo.MoveDistance,
        HeadShotNum = InPlayerInfo.HeadShotNum,
        HeadShotRate = InPlayerInfo.HeadShotRate,

        PlayerDeath = InPlayerInfo.PlayerDeath,

        UseGrowthMoneyNum = InPlayerInfo.BaseVirtualCurrency,
        LeftGrowthMoneyNum = InPlayerInfo.CurrentVirtualCurrency,
    }

    SettleInfoPlayer.HeroSkillPerfs = {}
    for DataId, DataValue in pairs(InPlayerInfo.HeroSkillIndex) do
        SettleInfoPlayer.HeroSkillPerfs[DataValue] = InPlayerInfo.HeroSkillData[DataId];
    end

    local KillsAndDeathsInfo = {}
    KillsAndDeathsInfo.Kills = {}
    for DataIndex, DataValue in pairs(InKillsAndDeathsInfo.Kills) do
        print("OnSettlementBRPlayer KillsAndDeathsInfo.Kills >> DataIndex = ", DataIndex)
        print("OnSettlementBRPlayer KillsAndDeathsInfo.Kills >> DataValue = ", DataValue)
        local tempKills = {
            PlayerId = DataValue
        }
        KillsAndDeathsInfo.Kills[DataIndex] = tempKills
    end

    KillsAndDeathsInfo.Deaths = {}
    for DataIndex, DataValue in pairs(InKillsAndDeathsInfo.Deaths) do
        print("OnSettlementBRPlayer KillsAndDeathsInfo.Deaths >> DataIndex = ", DataIndex)
        print("OnSettlementBRPlayer KillsAndDeathsInfo.Deaths >> DataValue = ", DataValue)
        local tempDeaths = {
            PlayerId = DataValue
        }
        KillsAndDeathsInfo.Deaths[DataIndex] = tempDeaths
    end

    Dump(SettleInfoPlayer, SettleInfoPlayer)
    Dump(KillsAndDeathsInfo, KillsAndDeathsInfo)
end

-- Pure data gather, Do not affect settlement logic by any means.
--【TBT】【玩法】【结算】玩家退出房间时获取结算字段 https://www.tapd.cn/68880148/s/1359321
Settlement.OnLocalSettlementBRTeam_Early = function(InPlayerId, InTeamId, InTeamInfo)
    print("OnSettlementBRTeam_Early")
    local SettlePlayerId = InPlayerId
    local SettleTeamId = InTeamId

    local SettleInfoTeam =
    {
        RemainingPlayers = InTeamInfo.RemainingPlayers,
        RemainingTeams = InTeamInfo.RemainingTeams,
        TeamRank = InTeamInfo.TeamRank,
        bIsGameOver = InTeamInfo.bIsGameOver,
        bIsWinnerTeam = InTeamInfo.bIsWinnerTeam,
        TeamSurvivalTime = InTeamInfo.TeamSurvivalTime,
        bIsTeamOver = InTeamInfo.bIsTeamOver,
    }

    local PlayerDataArray = InTeamInfo.PlayerArray
    local PlayerArray = {}
    for PlayerIndex, PlayerDataValue in pairs(PlayerDataArray) do
        local localPlayerSettlement = 
        {
            HeroTypeId = PlayerDataValue.RuntimeHeroId,

            PlayerKill = PlayerDataValue.PlayerKill,
            KnockDown = PlayerDataValue.KnockDown,
            RescueTimes = PlayerDataValue.RescueTimes,
            RespawnTimes = PlayerDataValue.RespawnTimes,

            PlayerAssist = PlayerDataValue.PlayerAssist,
            PlayerDamage = PlayerDataValue.PlayerDamage,
            PlayerSurvivalTime = PlayerDataValue.PlayerSurvivalTime,

            RemainingPlayers = PlayerDataValue.RemainingPlayers,
            RemainingTeams = PlayerDataValue.RemainingTeams,
            PosInTeam = PlayerDataValue.PosInTeam,

            bIsTeamOver = PlayerDataValue.bIsTeamOver,
            bIsTeamWinner = PlayerDataValue.bIsTeamWinner,
            bRespawnable = PlayerDataValue.bRespawnable,

            bIsLive = PlayerDataValue.bIsLive,
            HealAmount = PlayerDataValue.HealAmount,
            MoveDistance = PlayerDataValue.MoveDistance,
            HeadShotNum = PlayerDataValue.HeadShotNum,
            HeadShotRate = PlayerDataValue.HeadShotRate,
			PlayerDeath = PlayerDataValue.PlayerDeath
        }

        localPlayerSettlement.HeroSkillPerfs = {}
        for DataId, DataValue in pairs(PlayerDataValue.HeroSkillIndex) do
            localPlayerSettlement.HeroSkillPerfs[DataValue] = PlayerDataValue.HeroSkillData[DataId];
        end

        PlayerArray[PlayerDataValue.PlayerId] = localPlayerSettlement
    end

    Dump(SettleInfoTeam, SettleInfoTeam)
    Dump(PlayerArray, PlayerArray)
end

------------------------------------------  Settlement ------------------------------------

Settlement.OnLocalPlayerSettlement = function(InMsgBodyRaw, PS)
	print(">> OnLocalPlayerSettlement")
	GameLog.Dump(InMsgBodyRaw, InMsgBodyRaw)

	Settlement.bLocalSettlement = true

	local PlayerId = PS.PlayerId
	if Settlement.LocalSettlement[PlayerId] == nil then
		Settlement.LocalSettlement[PlayerId] = {}
	end

	local InContext = PS;

	local InMsgBody = {}
	InMsgBody.bWin = InMsgBodyRaw.bWin
	InMsgBody.PlayerId = InMsgBodyRaw.PlayerId
	InMsgBody.PlayerName = InMsgBodyRaw.PlayerName
	InMsgBody.RuntimeHeroId = InMsgBodyRaw.RuntimeHeroId
	InMsgBody.PlayerKill = InMsgBodyRaw.PlayerKill
	InMsgBody.KnockDown = InMsgBodyRaw.KnockDown
	InMsgBody.RescueTimes = InMsgBodyRaw.RescueTimes
	InMsgBody.RespawnTimes = InMsgBodyRaw.RespawnTimes
	InMsgBody.RemainingPlayers = InMsgBodyRaw.RemainingPlayers
	InMsgBody.PlayerAssist = InMsgBodyRaw.PlayerAssist
	InMsgBody.PlayerDamage = InMsgBodyRaw.PlayerDamage
	InMsgBody.RemainingTeams = InMsgBodyRaw.RemainingTeams
	InMsgBody.PosInTeam = InMsgBodyRaw.PosInTeam
	InMsgBody.PlayerSurvivalTime = InMsgBodyRaw.PlayerSurvivalTime
	InMsgBody.bIsTeamOver = InMsgBodyRaw.bIsTeamOver
	InMsgBody.bIsTeamWinner = InMsgBodyRaw.bIsTeamWinner
	InMsgBody.bRespawnable = InMsgBodyRaw.bRespawnable
	InMsgBody.PlayerDeath = InMsgBodyRaw.PlayerDeath

	Settlement.bIsTeamOver = InMsgBody.bIsTeamOver or InMsgBody.bIsTeamWinner
	-- 3D结算展示牌 韩胜辉
	local TempDisplayBoardInfo = {}
	local PlayerExInfo = UE.UPlayerExSubsystem.Get(InContext):GetPlayerExInfoById(InMsgBodyRaw.PlayerId)
	if PlayerExInfo then
		local DisplayInfo = PlayerExInfo:GetDisplayBoardInfo()

		TempDisplayBoardInfo.FloorId = DisplayInfo.FloorId
		TempDisplayBoardInfo.RoleId = DisplayInfo.RoleId
		TempDisplayBoardInfo.EffectId = DisplayInfo.EffectId
		TempDisplayBoardInfo.StickerMap = {}
		for StickerId, StickerInfo in pairs(DisplayInfo.StickerMap) do
			local StickerNodeInfo = {}
			StickerNodeInfo.StickerId = StickerInfo.StickerId
			StickerNodeInfo.XPos = StickerInfo.XPos
			StickerNodeInfo.YPos = StickerInfo.YPos
			StickerNodeInfo.Angle = StickerInfo.Angle
			StickerNodeInfo.ScaleX = StickerInfo.ScaleX
			StickerNodeInfo.ScaleY = StickerInfo.ScaleY
			table.insert(TempDisplayBoardInfo.StickerMap, StickerNodeInfo)
		end     
		TempDisplayBoardInfo.AchieveMap = {}
		for AchiveId, AchiveInfo in pairs(DisplayInfo.AchieveMap) do
			table.insert(TempDisplayBoardInfo.AchieveMap, AchiveInfo)
		end   
	end
	InMsgBody.DisplayBoardInfo = TempDisplayBoardInfo
	-- if not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
	-- 	return
	-- end

	Settlement.LocalSettlement[PlayerId].PlayerRawData = InMsgBody

	if Settlement.LocalSettlement[PlayerId].PlayerList == nil then
		Settlement.LocalSettlement[PlayerId].PlayerList = {}
	end

	if IsPlayerNotAdded(Settlement.LocalSettlement[PlayerId].PlayerList, InMsgBody.PlayerId) then
		table.insert(Settlement.LocalSettlement[PlayerId].PlayerList, InMsgBody)
	end

	MsgHelper:Send(nil,GameDefine.Msg.SETTLEMENT_PlayerSettlementComplate)

	--如果最后胜利的玩家不处理该协议，等到team协议统一处理
	if InMsgBody.bIsTeamOver or InMsgBody.bIsTeamWinner then
		return
	end

	Settlement.LocalSettlement[PlayerId].SettleRank = InMsgBody.RemainingTeams

	local GameState = UE.UGameplayStatics.GetGameState(InContext)
	local IsDisSettlementUIShow = GameState:IsDisableSettlementUI()
	if IsDisSettlementUIShow then
		return
	end

	local UIManager = UE.UGUIManager.GetUIManager(InContext)
	UIManager:TryCloseDynamicWidget("UMG_SettlementDetail")

	if InMsgBody.bRespawnable then
		Settlement.LocalSettlement[PlayerId].CurrentResultMode = Settlement.EResultMode.DieToLive
		UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")
	else
		Settlement.LocalSettlement[PlayerId].CurrentResultMode = Settlement.EResultMode.DieToOut
		UIManager:TryLoadDynamicWidget("UMG_SettlementResult")
	end
end

Settlement.OnLocalPlayerSettlementDF = function(InMsgBodyRaw, PS)
	print(">> OnLocalPlayerSettlementDF")
	GameLog.Dump(InMsgBodyRaw, InMsgBodyRaw)

	Settlement.bLocalSettlement = true

	local PlayerId = PS.PlayerId
	if Settlement.LocalSettlement[PlayerId] == nil then
		Settlement.LocalSettlement[PlayerId] = {}
	end

	local InContext = PS;

	local InMsgBody = {}
	InMsgBody.bWin = InMsgBodyRaw.bWin
	InMsgBody.PlayerId = InMsgBodyRaw.PlayerId
	InMsgBody.PlayerName = InMsgBodyRaw.PlayerName
	InMsgBody.RuntimeHeroId = InMsgBodyRaw.RuntimeHeroId
	InMsgBody.PlayerKill = InMsgBodyRaw.PlayerKill
	InMsgBody.PlayerDeath = InMsgBodyRaw.PlayerDeath
	InMsgBody.KnockDown = InMsgBodyRaw.KnockDown
	InMsgBody.RescueTimes = InMsgBodyRaw.RescueTimes
	InMsgBody.RespawnTimes = InMsgBodyRaw.RespawnTimes
	InMsgBody.RemainingPlayers = InMsgBodyRaw.RemainingPlayers
	InMsgBody.PlayerAssist = InMsgBodyRaw.PlayerAssist
	InMsgBody.PlayerDamage = InMsgBodyRaw.PlayerDamage
	InMsgBody.RemainingTeams = InMsgBodyRaw.RemainingTeams
	InMsgBody.PosInTeam = InMsgBodyRaw.PosInTeam
	InMsgBody.PlayerSurvivalTime = InMsgBodyRaw.PlayerSurvivalTime
	InMsgBody.bIsTeamOver = InMsgBodyRaw.bIsTeamOver
	InMsgBody.bIsTeamWinner = InMsgBodyRaw.bIsTeamWinner
	InMsgBody.bRespawnable = InMsgBodyRaw.bRespawnable
	-- 3D结算展示牌 韩胜辉
	local TempDisplayBoardInfo = {}
	local PlayerExInfo = UE.UPlayerExSubsystem.Get(InContext):GetPlayerExInfoById(InMsgBodyRaw.PlayerId)
	if PlayerExInfo then
		local DisplayInfo = PlayerExInfo:GetDisplayBoardInfo()

		TempDisplayBoardInfo.FloorId = DisplayInfo.FloorId
		TempDisplayBoardInfo.RoleId = DisplayInfo.RoleId
		TempDisplayBoardInfo.EffectId = DisplayInfo.EffectId
		TempDisplayBoardInfo.StickerMap = {}
		for StickerId, StickerInfo in pairs(DisplayInfo.StickerMap) do
			local StickerNodeInfo = {}
			StickerNodeInfo.StickerId = StickerInfo.StickerId
			StickerNodeInfo.XPos = StickerInfo.XPos
			StickerNodeInfo.YPos = StickerInfo.YPos
			StickerNodeInfo.Angle = StickerInfo.Angle
			StickerNodeInfo.ScaleX = StickerInfo.ScaleX
			StickerNodeInfo.ScaleY = StickerInfo.ScaleY
			table.insert(TempDisplayBoardInfo.StickerMap, StickerNodeInfo)
		end     
		TempDisplayBoardInfo.AchieveMap = {}
		for AchiveId, AchiveInfo in pairs(DisplayInfo.AchieveMap) do
			table.insert(TempDisplayBoardInfo.AchieveMap, AchiveInfo)
		end   
	end
	InMsgBody.DisplayBoardInfo = TempDisplayBoardInfo

	Settlement.LocalSettlement[PlayerId].PlayerRawData = InMsgBody

	if Settlement.LocalSettlement[PlayerId].PlayerList == nil then
		Settlement.LocalSettlement[PlayerId].PlayerList = {}
	end

	if IsPlayerNotAdded(Settlement.LocalSettlement[PlayerId].PlayerList, InMsgBody.PlayerId) then
		table.insert(Settlement.LocalSettlement[PlayerId].PlayerList, InMsgBody)
	end

	MsgHelper:Send(nil,GameDefine.Msg.SETTLEMENT_PlayerSettlementComplate)

	Settlement.LocalSettlement[PlayerId].SettleRank = InMsgBody.Rank

	local GameState = UE.UGameplayStatics.GetGameState(InContext)
	local IsDisSettlementUIShow = GameState:IsDisableSettlementUI()
	if IsDisSettlementUIShow then
		return
	end

	local UIManager = UE.UGUIManager.GetUIManager(InContext)
	UIManager:TryCloseDynamicWidget("UMG_SettlementDetail")

	if InMsgBody.bWin then
		Settlement.LocalSettlement[PlayerId].CurrentResultMode = Settlement.EResultMode.Victory
		UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")
	else
		Settlement.LocalSettlement[PlayerId].CurrentResultMode = Settlement.EResultMode.Finish
		UIManager:TryLoadDynamicWidget("UMG_SettlementResult")
	end
end

Settlement.OnLocalTeamSettlement = function(InMsgBodyRaw, PS)
	print(">> OnLocalTeamSettlement")
	GameLog.Dump(InMsgBodyRaw, InMsgBodyRaw)

	Settlement.bLocalSettlement = true
	Settlement.bIsTeamOver = true

	local PlayerId = PS.PlayerId
	if Settlement.LocalSettlement[PlayerId] == nil then
		Settlement.LocalSettlement[PlayerId] = {}
	end

	local InContext = PS;

	-- TArray to Lua
	local InMsgBody = {}
	InMsgBody.bWin = InMsgBodyRaw.bWin
	InMsgBody.RemainingPlayers = InMsgBodyRaw.RemainingPlayers
	InMsgBody.RemainingTeams = InMsgBodyRaw.RemainingTeams
	InMsgBody.bIsGameOver = InMsgBodyRaw.bIsGameOver
	InMsgBody.bIsWinnerTeam = InMsgBodyRaw.bIsWinnerTeam
	InMsgBody.PlayerArray = {}

	for i = 1, InMsgBodyRaw.PlayerArray:Length(), 1 do
		local Raw = InMsgBodyRaw.PlayerArray:GetRef(i)
		InMsgBody.PlayerArray[i] = {}

		InMsgBody.PlayerArray[i].bWin = Raw.bWin
		InMsgBody.PlayerArray[i].PlayerId = Raw.PlayerId
		InMsgBody.PlayerArray[i].PlayerName = Raw.PlayerName
		InMsgBody.PlayerArray[i].RuntimeHeroId = Raw.RuntimeHeroId
		InMsgBody.PlayerArray[i].PlayerKill = Raw.PlayerKill
		InMsgBody.PlayerArray[i].KnockDown = Raw.KnockDown
		InMsgBody.PlayerArray[i].RescueTimes = Raw.RescueTimes
		InMsgBody.PlayerArray[i].RespawnTimes = Raw.RespawnTimes
		InMsgBody.PlayerArray[i].RemainingPlayers = Raw.RemainingPlayers
		InMsgBody.PlayerArray[i].PlayerAssist = Raw.PlayerAssist
		InMsgBody.PlayerArray[i].PlayerDamage = Raw.PlayerDamage
		InMsgBody.PlayerArray[i].RemainingTeams = Raw.RemainingTeams
		InMsgBody.PlayerArray[i].PosInTeam = Raw.PosInTeam
		InMsgBody.PlayerArray[i].PlayerSurvivalTime = Raw.PlayerSurvivalTime
		InMsgBody.PlayerArray[i].bIsTeamOver = Raw.bIsTeamOver
		InMsgBody.PlayerArray[i].bIsTeamWinner = Raw.bIsTeamWinner
		InMsgBody.PlayerArray[i].bRespawnable = Raw.bRespawnable
		
		-- 3D结算展示牌 韩胜辉
		local TempDisplayBoardInfo = {}
		local PlayerExInfo = UE.UPlayerExSubsystem.Get(InContext):GetPlayerExInfoById(Raw.PlayerId)
		if PlayerExInfo then
			local DisplayInfo = PlayerExInfo:GetDisplayBoardInfo()

	
			TempDisplayBoardInfo.FloorId = DisplayInfo.FloorId
			TempDisplayBoardInfo.RoleId = DisplayInfo.RoleId
			TempDisplayBoardInfo.EffectId = DisplayInfo.EffectId
			TempDisplayBoardInfo.StickerMap = {}
			for StickerId, StickerInfo in pairs(DisplayInfo.StickerMap) do
				local StickerNodeInfo = {}
				StickerNodeInfo.StickerId = StickerInfo.StickerId
				StickerNodeInfo.XPos = StickerInfo.XPos
				StickerNodeInfo.YPos = StickerInfo.YPos
				StickerNodeInfo.Angle = StickerInfo.Angle
				StickerNodeInfo.ScaleX = StickerInfo.ScaleX
				StickerNodeInfo.ScaleY = StickerInfo.ScaleY
				table.insert(TempDisplayBoardInfo.StickerMap, StickerNodeInfo)
			end     
			TempDisplayBoardInfo.AchieveMap = {}
			for AchiveId, AchiveInfo in pairs(DisplayInfo.AchieveMap) do
				table.insert(TempDisplayBoardInfo.AchieveMap, AchiveInfo)
			end     
		end
		InMsgBody.PlayerArray[i].DisplayBoardInfo = TempDisplayBoardInfo
	end

	-- if not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
	-- 	return
	-- end

	Settlement.LocalSettlement[PlayerId].TeamRawData = InMsgBody

	if Settlement.LocalSettlement[PlayerId].PlayerList == nil then
		Settlement.LocalSettlement[PlayerId].PlayerList = {}
	end

	for key, value in pairs(InMsgBody.PlayerArray) do
		if IsPlayerNotAdded(Settlement.LocalSettlement[PlayerId].PlayerList, value.PlayerId) then
			table.insert(Settlement.LocalSettlement[PlayerId].PlayerList, value)
		end
	end

	table.sort(Settlement.LocalSettlement[PlayerId].PlayerList,function(a,b)
		local TeamSubsystem = UE.UTeamExSubsystem.Get(InContext)
		return TeamSubsystem:GetPlayerNumberInTeamById(a.PlayerId) < TeamSubsystem:GetPlayerNumberInTeamById(b.PlayerId)
	end)

	Settlement.LocalSettlement[PlayerId].SettleRank = InMsgBody.RemainingTeams
	Settlement.LocalSettlement[PlayerId].CurrentResultMode = InMsgBody.bIsGameOver
			and Settlement.EResultMode.Finish
			or Settlement.EResultMode.AllDead
	if InMsgBody.TeamRank == 1 or InMsgBody.bIsWinnerTeam then
		Settlement.LocalSettlement[PlayerId].CurrentResultMode = Settlement.EResultMode.Victory
	end
	local UIManager = UE.UGUIManager.GetUIManager(InContext)
	UIManager:TryCloseDynamicWidget("UMG_SettlementDetail")
	UIManager:TryCloseDynamicWidget("UMG_SettlementResult")
	
	UIManager:TryLoadDynamicWidget("UMG_SettlementResult")
end

Settlement.OnLocalBattleSettlement = function(InMsgBodyRaw, PS)
	print(">> OnLocalBattleSettlement")
	GameLog.Dump(InMsgBodyRaw, InMsgBodyRaw)

	Settlement.bReceivedBattleSettlement = true

	Settlement.bLocalSettlement = true

	local PlayerId = PS.PlayerId
	if Settlement.LocalSettlement[PlayerId] == nil then
		Settlement.LocalSettlement[PlayerId] = {}
	end

	local InContext = PS;

	local InMsgBody = {}
	InMsgBody.GameId = InMsgBodyRaw.GameId
	InMsgBody.WinnerTeamId = InMsgBodyRaw.WinnerTeamId

	-- if not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
	-- 	return
	-- end

	Settlement.LocalSettlement[PlayerId].GameRawData = InMsgBody

	if Settlement.LocalSettlement[PlayerId].CurrentResultMode ~= Settlement.EResultMode.Victory then

		Settlement.LocalSettlement[PlayerId].CurrentResultMode = Settlement.EResultMode.Finish

		local UIManager = UE.UGUIManager.GetUIManager(InContext)
		UIManager:TryCloseDynamicWidget("UMG_SettlementDetail")
		UIManager:TryCloseDynamicWidget("UMG_SettlementResult")

		if not SettlementProxy:IsReviewStart() then
			print(">> SOnLocalBattleSettlement: Game Show UMG_SettlementResult")
			UIManager:TryLoadDynamicWidget("UMG_SettlementResult")
		end
	end

	--发送一条胜利或失败的消息，目前只给EventManager用来播语音
	local IsVictory = Settlement.LocalSettlement[PlayerId].CurrentResultMode == Settlement.EResultMode.Victory
	local SettleRank = Settlement.LocalSettlement[PlayerId].SettleRank

	if IsVictory ~= nil and SettleRank ~= nil then
		MsgHelper:SendCpp(nil, "BattleSettlement.GameResult", IsVictory, SettleRank)
		print("nzyp " .. "BattleSettlement.GameResult", tostring(IsVictory), SettleRank)
	end
end

Settlement.OnLocalCampSettlement = function(InMsgBodyRaw, PS)
	print(">> SettlementProxy:OnLocalCampSettlement")
	GameLog.Dump(InMsgBodyRaw, InMsgBodyRaw)

	Settlement.bLocalSettlement = true

	local PlayerId = PS.PlayerId
	if Settlement.LocalSettlement[PlayerId] == nil then
		Settlement.LocalSettlement[PlayerId] = {}
	end

	local InContext = PS;

	-- TArray to Lua
	local InMsgBody = {}
	InMsgBody.CampRank = InMsgBodyRaw.CampRank
	InMsgBody.PlayerArray = {}

	for i = 1, InMsgBodyRaw.PlayerDataArray:Length(), 1 do
		local Raw = InMsgBodyRaw.PlayerDataArray:GetRef(i)
		InMsgBody.PlayerArray[i] = {}

		InMsgBody.PlayerArray[i].CampId = Raw.CampId
		InMsgBody.PlayerArray[i].TeamId = Raw.TeamId
		InMsgBody.PlayerArray[i].PlayerId = Raw.PlayerId
		InMsgBody.PlayerArray[i].PlayerName = Raw.PlayerName
		InMsgBody.PlayerArray[i].PlayerKill = Raw.PlayerKill
		InMsgBody.PlayerArray[i].PlayerDeath = Raw.PlayerDeath
		InMsgBody.PlayerArray[i].PlayerAssist = Raw.PlayerAssist
		InMsgBody.PlayerArray[i].PlayerDamage = Raw.PlayerDamage
		InMsgBody.PlayerArray[i].PlayerScore = Raw.PlayerScore
		InMsgBody.PlayerArray[i].RuntimeHeroId = Raw.RuntimeHeroId
		InMsgBody.PlayerArray[i].PosInTeam = Raw.PosInTeam

		-- 3D结算展示牌 韩胜辉
		local TempDisplayBoardInfo = {}
		local PlayerExInfo = UE.UPlayerExSubsystem.Get(InContext):GetPlayerExInfoById(Raw.PlayerId)
		if PlayerExInfo then
			local DisplayInfo = PlayerExInfo:GetDisplayBoardInfo()

	
			TempDisplayBoardInfo.FloorId = DisplayInfo.FloorId
			TempDisplayBoardInfo.RoleId = DisplayInfo.RoleId
			TempDisplayBoardInfo.EffectId = DisplayInfo.EffectId
			TempDisplayBoardInfo.StickerMap = {}
			for StickerId, StickerInfo in pairs(DisplayInfo.StickerMap) do
				local StickerNodeInfo = {}
				StickerNodeInfo.StickerId = StickerInfo.StickerId
				StickerNodeInfo.XPos = StickerInfo.XPos
				StickerNodeInfo.YPos = StickerInfo.YPos
				StickerNodeInfo.Angle = StickerInfo.Angle
				StickerNodeInfo.ScaleX = StickerInfo.ScaleX
				StickerNodeInfo.ScaleY = StickerInfo.ScaleY
				table.insert(TempDisplayBoardInfo.StickerMap, StickerNodeInfo)
			end     
			TempDisplayBoardInfo.AchieveMap = {}
			for AchiveId, AchiveInfo in pairs(DisplayInfo.AchieveMap) do
				table.insert(TempDisplayBoardInfo.AchieveMap, AchiveInfo)
			end     
		end
		InMsgBody.PlayerArray[i].DisplayBoardInfo = TempDisplayBoardInfo
	end

	-- if not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
	-- 	return
	-- end

	Settlement.LocalSettlement[PlayerId].TeamRawData = InMsgBody

	if Settlement.LocalSettlement[PlayerId].PlayerList == nil then
		Settlement.LocalSettlement[PlayerId].PlayerList = {}
	end

	for key, value in pairs(InMsgBody.PlayerArray) do
		if IsPlayerNotAdded(Settlement.LocalSettlement[PlayerId].PlayerList, value.PlayerId) then
			table.insert(Settlement.LocalSettlement[PlayerId].PlayerList, value)
		end
	end

	table.sort(Settlement.LocalSettlement[PlayerId].PlayerList,function(a,b)
		local TeamSubsystem = UE.UTeamExSubsystem.Get(InContext)
		return TeamSubsystem:GetPlayerNumberInTeamById(a.PlayerId) < TeamSubsystem:GetPlayerNumberInTeamById(b.PlayerId)
	end)

	Settlement.LocalSettlement[PlayerId].SettleRank = InMsgBody.CampRank
	Settlement.LocalSettlement[PlayerId].CurrentResultMode = Settlement.EResultMode.Finish

	if InMsgBody.CampRank == 1 then
		Settlement.LocalSettlement[PlayerId].CurrentResultMode = Settlement.EResultMode.Victory
	end

	local UIManager = UE.UGUIManager.GetUIManager(InContext)
	UIManager:TryLoadDynamicWidget("UMG_SettlementResult")
end

------------------------------------------  UI Function ------------------------------------

Settlement.SettlementUIResult = function(Owner, Skill)
	print(">> Settlement.SettlementUIResult")

	local UIManager = UE.UGUIManager.GetUIManager(Owner)
	UIManager:TryCloseDynamicWidget("UMG_SettlementResult")

	print(">> TryLoadDynamicWidget: SettlementUIResult")
	UIManager:TryLoadDynamicWidget("UMG_SettlementResult")
end

Settlement.CloseSettlementUIResult = function(Owner, Skill)
	print(">> Settlement.CloseSettlementUIResult")

	local UIManager = UE.UGUIManager.GetUIManager(Owner)
	UIManager:TryCloseDynamicWidget("UMG_SettlementResult")
end

Settlement.SettlementUIDetail = function(Owner, Skill)
	print(">> Settlement.SettlementUIDetail")

	if SettlementProxy:IsReviewStart() then
		print(">> Settlement.SettlementUIDetail review return!")
		return
	end

	local UIManager = UE.UGUIManager.GetUIManager(Owner)

	if Settlement.bLocalSettlement then
		SettlementProxy:InitLocalPlayerId(Owner)
	end

	UIManager:TryCloseDynamicWidget("UMG_SettlementResult")

	print(">> TryLoadDynamicWidget: SettlementUIDetail")
	UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")
end


Settlement.SettlementUIDetail_Review = function(Owner, Skill)
	print(">> Settlement.SettlementUIDetail")

	local UIManager = UE.UGUIManager.GetUIManager(Owner)

	if Settlement.bLocalSettlement then
		SettlementProxy:InitLocalPlayerId(Owner)
	end

	UIManager:TryCloseDynamicWidget("UMG_SettlementResult")
	UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")
end

-- 弹出选择继续、退出UI
Settlement.SettlementUIReviewSelection = function(Owner, Skill)
	print(">> Settlement.SettlementUIReviewSelection")

	local UIManager = UE.UGUIManager.GetUIManager(Owner)
	UIManager:TryCloseDynamicWidget("UMG_BRReview_Selection")
	UIManager:TryLoadDynamicWidget("UMG_BRReview_Selection")
end

-- -- 选择继续后弹出对应UI
-- Settlement.SettlementUIReviewContinue = function(Owner, Skill)
-- 	print(">> Settlement.SettlementUIReviewContinue")

-- 	local UIManager = UE.UGUIManager.GetUIManager(Owner)
-- 	local SettlementHandle = UIManager:GetHandleByKey("UMG_BRReview_Continue")
-- 	if SettlementHandle ~= 0 then
-- 		UIManager:CloseByHandle(SettlementHandle)
-- 	end

--     UIManager:ShowByKey("UMG_BRReview_Continue")
-- end

-- -- 选择退出后弹出对应UI
-- Settlement.SettlementUIReviewExit = function(Owner, Skill)
-- 	print(">> Settlement.SettlementUIReviewExit")

-- 	local UIManager = UE.UGUIManager.GetUIManager(Owner)
-- 	local SettlementHandle = UIManager:GetHandleByKey("UMG_BRReview_Exit")
-- 	if SettlementHandle ~= 0 then
-- 		UIManager:CloseByHandle(SettlementHandle)
-- 	end

--     UIManager:ShowByKey("UMG_BRReview_Exit")
-- end

Settlement.ShowDetailByMode = function(UIManager)
	print(">> Settlement.ShowDetailByMode")
	if Settlement.CurrentGameMode == Settlement.EGameMode.TeamCompetition then
		UIManager:TryLoadDynamicWidget("UMG_SettlementDetail_TC")
	else
		UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")
	end
end

Settlement.TestDsTaskDataNotify = function(MissionInfo)
    print("DSProtocol", ">> TestDsTaskDataNotify, ",  MissionInfo)

	if MissionInfo == nil then
        print("DSServerCtrl", ">> error:MissionInfo fail")
        return;
    end
    if MissionInfo.TaskListMap == nil then
        print("DSServerCtrl", ">> error:TaskListMap fail")
        return;
    end
    local msg ={
        GameId = MissionInfo.GameId,
        PlayerId = MissionInfo.PlayerId,
        TaskListMap = {},
        ResultFlag = MissionInfo.ResultFlag
    }
    local MissionInfoItem =nil
    local TaskIds = MissionInfo.TaskListMap:Keys()
    for i = 1, TaskIds:Length() do
        local TaskId = TaskIds:Get(i)
        MissionInfoItem = MissionInfo.TaskListMap:Find(TaskId)
        if MissionInfoItem then
            local TaskInfoNodeTable ={}
            TaskInfoNodeTable.FinishFlag = MissionInfoItem.FinishFlag
            TaskInfoNodeTable.TargetProcessList = {}
            for j = 1 , MissionInfoItem.TargetProcessList:Length() do
                local TaskProcessNode = MissionInfoItem.TargetProcessList:Get(j)
                local TaskProcessNodeTable = {}
                TaskProcessNodeTable.EventId = TaskProcessNode.EventId
                TaskProcessNodeTable.ProcessValue = TaskProcessNode.Progress
                table.insert(TaskInfoNodeTable.TargetProcessList,TaskProcessNodeTable)
    
            end
            msg["TaskListMap"][TaskId] = TaskInfoNodeTable
        end
   
    end

    Dump(msg, msg,5)

end

_G.Settlement = Settlement
return Settlement