--
-- 结算
--
-- @COMPANY	ByteDance
-- @AUTHOR	邱天
-- @DATE	2022.11.09
--

--  结算结果面板中（SettlementResultPanel）获取游戏结算的结果，根据结果打开不同的游戏结束界面，当结束界面播放完成执行回调，打开结算细节面板（SettlementDetailPanel）.
--  在结算细节面板中初始化结算代理类，结算细节面板中显示玩家和队友的死亡数据.
--  WangZeping

local SettlementProxy = classmul("SettlementProxy", ProxyBase)

SettlementProxy.LocalPlayerId = 0;

function SettlementProxy:ctor(...)
	ProxyBase.ctor(self, ...)


end

function SettlementProxy:OnInit()
	self.MsgList = {
		{ MsgName = MsgDefine.SETTLEMENT_PlayerSettlement, 		    Func = self.OnPlayerSettlement },
		{ MsgName = MsgDefine.SETTLEMENT_TeamSettlement, 			Func = self.OnTeamSettlement },
		{ MsgName = MsgDefine.SETTLEMENT_GameSettlement, 			Func = self.OnBattleSettlement },
		{ MsgName = MsgDefine.SETTLEMENT_CampSettlement, 			Func = self.OnCampSettlement },
		{ MsgName = MsgDefine.SETTLEMENT_CacheObserverData, 		Func = self.OnCacheOberserData },
		{ MsgName = MsgDefine.LEVEL_PreLoadMap, 					Func = self.OnPreLoadMap },
	}

	ProxyBase.OnInit(self)
	print("SettlementProxy", ">> OnInit:", self)
end

function SettlementProxy:InitLocalPlayerId(inContext)
	print("SettlementProxy:InitLocalPlayerId Start")
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(inContext, 0)
	if not self.LocalPC then
		return 0
	end
	--self.LocalPS = self.LocalPC.PlayerState 
	self.LocalPS = self.LocalPC.OriginalPlayerState
	if not self.LocalPS then
		return 0
	end
	self.LocalPlayerId =self.LocalPS.PlayerId
	print("SettlementProxy:InitLocalPlayerId", self.LocalPlayerId)
end

function SettlementProxy:GetLocalPlayerId()
	print("SettlementProxy:InitLocalPlayerId", self.LocalPlayerId)
	if self.LocalPlayerId then
		return self.LocalPlayerId
	end
	return nil
end

function SettlementProxy:GetPlayerDataByIndex(InDataIndex)
	if Settlement.bLocalSettlement then
		local PlayerId = self.LocalPlayerId
		if PlayerId ~= 0 and Settlement.LocalSettlement and Settlement.LocalSettlement[PlayerId] then
			print("GetPlayerDataByIndex>> InDataIndex:", InDataIndex)
			return Settlement.LocalSettlement[PlayerId].PlayerList[InDataIndex]
		else
			return nil
		end
	else
		print("SettlementProxy>> InDataIndex:", InDataIndex)
		return Settlement.PlayerList[InDataIndex]
	end
end

function SettlementProxy:GetPlayerDataByPosInTeam(InPos)
	if Settlement.bLocalSettlement then
		local PlayerId = self.LocalPlayerId
		if PlayerId ~= 0 and Settlement.LocalSettlement and Settlement.LocalSettlement[PlayerId] then
			print("SettlementProxyLocal>> InPos:", InPos)
			for index, value in ipairs(Settlement.LocalSettlement[PlayerId].PlayerList) do
				if(value.PosInTeam == InPos) then
					return value
				end
			end
		else
			return nil
		end
	else
		print("SettlementProxy>> InPos:", InPos)
		for index, value in ipairs(Settlement.PlayerList) do
			if(value.PosInTeam == InPos) then
				return value
			end
		end
		return nil
	end
end

--获取结算信息数量
function SettlementProxy:GetPlayerNum()
	if Settlement.bLocalSettlement then
		local PlayerId = self.LocalPlayerId
		if PlayerId ~= 0 and Settlement.LocalSettlement and Settlement.LocalSettlement[PlayerId] then
			print("SettlementProxyLocal>> GetPlayerNum:",#Settlement.LocalSettlement[PlayerId].PlayerList)
			return #Settlement.LocalSettlement[PlayerId].PlayerList
		else
			return nil
		end
	else
		print("SettlementProxy>> GetPlayerNum:",#Settlement.PlayerList)
		return #Settlement.PlayerList
	end
end

--排序玩家结算信息后，返回结算信息数组
function SettlementProxy:GetSortedPlayer()
	if Settlement.bLocalSettlement then
		self.LocalPS = self.LocalPC.OriginalPlayerState --观战玩家（死亡的）
		local PlayerId = self.LocalPS.PlayerId
		if PlayerId ~= 0 and Settlement.LocalSettlement and Settlement.LocalSettlement[PlayerId] then
			print("SettlementProxyLocal>> GetSortedPlayer:",#Settlement.LocalSettlement[PlayerId].PlayerList)
			table.sort(Settlement.LocalSettlement[PlayerId].PlayerList,function(a,b)
				return a.PosInTeam < b.PosInTeam
			end)
			return Settlement.LocalSettlement[PlayerId].PlayerList
		else
			return nil
		end
	else
		print("SettlementProxy>> GetSortedPlayer:",#Settlement.PlayerList)
		table.sort(Settlement.PlayerList,function(a,b)
			return a.PosInTeam < b.PosInTeam
		end)
		return Settlement.PlayerList
	end
end

--获取结算模式：个人、组队
function SettlementProxy:GetSettleMode()
	if Settlement.bLocalSettlement then
		local PlayerId = self.LocalPlayerId
		if PlayerId ~= 0 and Settlement.LocalSettlement and Settlement.LocalSettlement[PlayerId] then
			print("SettlementProxyLocal>> GetSettleMode:",Settlement.LocalSettlement[PlayerId].SettleMode)
			return Settlement.LocalSettlement[PlayerId].SettleMode
		else
			return nil
		end
	else
		print("SettlementProxy>> GetSettleMode:",Settlement.SettleMode)
		return Settlement.SettleMode
	end
end

--获取当前结算结果：胜利 、还能复活、死到不能复活、全军覆没、结束
function SettlementProxy:GetCurrentResultMode()
	if Settlement.bLocalSettlement then
		local PlayerId = self.LocalPlayerId
		if PlayerId ~= 0 then
			if Settlement.LocalSettlement[PlayerId] ~= nil then
				print("SettlementProxyLocal>> GetCurrentResultMode:", Settlement.LocalSettlement[PlayerId].CurrentResultMode)
				return Settlement.LocalSettlement[PlayerId].CurrentResultMode
			else
				-- Editor 单独处理出局，默认即为 Settlement.EResultMode.DieToOut （已出局）
				-- 真正原因：Editor时，因为延迟结算，此时实际的玩家Id变成了被观战玩家的Id
				return Settlement.EResultMode.DieToOut
			end
		end
	else
		print("SettlementProxy>> GetCurrentResultMode:", Settlement.CurrentResultMode)
		return Settlement.CurrentResultMode
	end
end

function SettlementProxy:IsReviewStart()
	print("SettlementProxy>> IsReviewStart:", Settlement.bReviewStart)
	return Settlement.bReviewStart and Settlement.bForceReviewStart
end

function SettlementProxy:IsTeamOver()
	print("SettlementProxy>> IsTeamOver:", Settlement.bIsTeamOver)
	return Settlement.bIsTeamOver
end

function SettlementProxy:GetCurrentGameMode()
	print("SettlementProxy>> GetCurrentGameMode:", Settlement.CurrentGameMode)
	return Settlement.CurrentGameMode
end

function SettlementProxy:GetSettleRank()
	if Settlement.bLocalSettlement then
		local PlayerId = self.LocalPlayerId
		if PlayerId ~= 0 and Settlement.LocalSettlement and Settlement.LocalSettlement[PlayerId] then
			print("SettlementProxyLocal>> GetSettleRank:",Settlement.LocalSettlement[PlayerId].SettleRank)
			return Settlement.LocalSettlement[PlayerId].SettleRank
		else
			return nil
		end
	else
		print("SettlementProxy>> GetSettleRank:",Settlement.SettleRank)
		return Settlement.SettleRank
	end
end

function SettlementProxy:ResetSettlement()
	print("SettlementProxy>> ResetSettlement")

	Settlement.CurrentGameMode = Settlement.EGameMode.BR
	Settlement.bReviewStart = false
	Settlement.bIsTeamOver = false
end

function SettlementProxy:IsGameOver()
	print("SettlementProxy >> IsGameOver ")
	local ResultMode = self:GetCurrentResultMode()
	if Settlement.bReceivedBattleSettlement or ResultMode == Settlement.EResultMode.Victory or ResultMode == Settlement.EResultMode.Finish  then
		return true
	end
	return false
end

--获取英雄ID
function SettlementProxy:GetPlayerDataHeroID(InPlayerData)
	if InPlayerData.RuntimeHeroId and InPlayerData.RuntimeHeroId > 1 then
		return InPlayerData.RuntimeHeroId
	elseif InPlayerData.HeroTypeId and InPlayerData.HeroTypeId > 1 then
		return InPlayerData.HeroTypeId
	end
	return 1
end

function SettlementProxy:GetPlayerDataPlayerName(InPlayerData)
	return UE.UPlayerExSubsystem.Get(GameInstance):GetPlayerNameById(InPlayerData.PlayerId) or "-"
end

--击杀致死数
function SettlementProxy:GetPlayerDataKill(InPlayerData)
	return InPlayerData.PlayerKill
end
--击杀致死数 改个名字
function SettlementProxy:GetPlayerDataPlayerKill(InPlayerData)
	return InPlayerData.PlayerKill
end
-- 玩家死亡数
function SettlementProxy:GetPlayerDataDeath(InPlayerData)
	return InPlayerData.PlayerDeath
end
-- 把人击倒数
function SettlementProxy:GetPlayerDataLayDown(InPlayerData)
	return InPlayerData.KnockDown
end
--救援次数 （并不是BeRescued）
function SettlementProxy:GetPlayerDataSaveCnt(InPlayerData)
	return InPlayerData.RescueTimes
end
--复活别人的次数 （并不是BeRespawned）
function SettlementProxy:GetPlayerDataResurrectionCnt(InPlayerData)
	return InPlayerData.RespawnTimes
end
-- Player结算时：当前剩余玩家数量
function SettlementProxy:GetPlayerDataRemainingPlayers(InPlayerData)
	return InPlayerData.RemainingPlayers
end
function SettlementProxy:GetPlayerDataPosInTeam(InPlayerData)
	return InPlayerData.PosInTeam
end
function SettlementProxy:GetPlayerDataDisplayBoardInfo(InPlayerData)
	return InPlayerData.DisplayBoardInfo
end
-- Player结算时：玩家助攻数
function SettlementProxy:GetPlayerDataPlayerAssist(InPlayerData)
	return InPlayerData.PlayerAssist or 0
end
-- Player结算时：玩家伤害量
function SettlementProxy:GetPlayerDataPlayerDamage(InPlayerData)
	return InPlayerData.PlayerDamage or 0
end
-- Player结算时：玩家存活时间 转化为分钟
function SettlementProxy:GetPlayerDataPlayerSurvivalTime(InPlayerData)
	local timespan = UE.UKismetMathLibrary.FromSeconds(InPlayerData.PlayerSurvivalTime or 0)
	return UE.UKismetTextLibrary.AsTimespan_Timespan(timespan) or ""
	--return InPlayerData.PlayerSurvivalTime
end

--获取观战对象FOBViewTargetDesc
function SettlementProxy:GetObserverData()
	return Settlement.OBViewTargetDesc
end

-------------------------------------------- Callable ------------------------------------
function SettlementProxy:IsSettlementInfoValid(PlayerId)
	if Settlement.PlayerList ~= nil and Settlement.PlayerList[PlayerId] ~= nil then
		return true
	end
	return false
end

function SettlementProxy:OnPlayerSettlement(InMsgBody)
	print(">> SettlementProxy:OnPlayerSettlement")
	GameLog.Dump(InMsgBody, InMsgBody)

	Settlement.bReceivedPlayerSettlement = true

	print(">> SettlementProxy:OnPlayerSettlement + ", Settlement.bLocalSettlementGM)
	if not Settlement.bLocalSettlementGM and not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
		print(">> SettlementProxy:OnPlayerSettlement should not go this!")
		return
	end

	Settlement.PlayerRawData = InMsgBody
	table.insert(Settlement.PlayerList, InMsgBody)

	MsgHelper:Send(nil,GameDefine.Msg.SETTLEMENT_PlayerSettlementComplate)

	--如果最后胜利的玩家不处理该协议，等到team协议统一处理
	Settlement.bIsTeamOver = InMsgBody.bIsTeamOver or InMsgBody.bIsTeamWinner

	if InMsgBody.bIsTeamWinner then
		Settlement.CurrentResultMode = Settlement.EResultMode.Victory
	end

	if InMsgBody.bIsTeamOver or InMsgBody.bIsTeamWinner then
		return
	end

	--if self:IsReviewStart() then
	--	if not InMsgBody.bIsTeamOver then
	--		return
	--	end
	--end

	Settlement.SettleRank = InMsgBody.RemainingTeams
	local GameState = UE.UGameplayStatics.GetGameState(GameInstance)
	local IsDisSettlementUIShow = GameState:IsDisableSettlementUI()
	if IsDisSettlementUIShow then
		return
	end

	local UIManager = UE.UGUIManager.GetUIManager(GameInstance)
	UIManager:TryCloseDynamicWidget("UMG_SettlementDetail")

	if InMsgBody.bRespawnable then
		Settlement.CurrentResultMode = Settlement.EResultMode.DieToLive
		print(">> SettlementProxy: Player Show UMG_SettlementDetail")
		UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")
	else
		Settlement.CurrentResultMode = Settlement.EResultMode.DieToOut
		print(">> SettlementProxy: Player Show UMG_SettlementResult")
		UIManager:TryLoadDynamicWidget("UMG_SettlementResult")
	end
end

function SettlementProxy:OnTeamSettlement(InMsgBody)
	print(">> SettlementProxy:OnTeamSettlement")
	GameLog.Dump(InMsgBody, InMsgBody)

	print(">> SettlementProxy:OnTeamSettlement + ", Settlement.bLocalSettlementGM)

	if not Settlement.bLocalSettlementGM and not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
		print(">> SettlementProxy:OnTeamSettlement should not go this!")
		return
	end

	Settlement.bIsTeamOver = true
	Settlement.TeamRawData = InMsgBody
	Settlement.PlayerList = {}
	for key, value in pairs(InMsgBody.PlayerArray) do
		print(">> SettlementProxy:PlayerArray ==> table.insert + ", key)

		value.PlayerId = key
		table.insert(Settlement.PlayerList, value)
	end

	table.sort(Settlement.PlayerList,function(a,b)
		local TeamSubsystem = UE.UTeamExSubsystem.Get(GameInstance)
		return TeamSubsystem:GetPlayerNumberInTeamById(a.PlayerId) < TeamSubsystem:GetPlayerNumberInTeamById(b.PlayerId)
	end)

	Settlement.SettleRank = InMsgBody.TeamRank
	Settlement.CurrentResultMode = InMsgBody.bIsGameOver
			and Settlement.EResultMode.Finish
			or Settlement.EResultMode.AllDead

	if InMsgBody.TeamRank == 1 or InMsgBody.bIsWinnerTeam then
		Settlement.CurrentResultMode = Settlement.EResultMode.Victory
	end

	local UIManager = UE.UGUIManager.GetUIManager(GameInstance)
	UIManager:TryCloseDynamicWidget("UMG_SettlementDetail")
	UIManager:TryCloseDynamicWidget("UMG_SettlementResult")

	print(">> SettlementProxy: Team Show UMG_SettlementResult")
	UIManager:TryLoadDynamicWidget("UMG_SettlementResult")
end

function SettlementProxy:OnBattleSettlement(InMsgBody)
	print(">> SettlementProxy:OnBattleSettlement")
	GameLog.Dump(InMsgBody, InMsgBody)

	print(">> SettlementProxy:OnBattleSettlement + ", Settlement.bLocalSettlementGM)
	Settlement.bReceivedBattleSettlement = true

	if not Settlement.bLocalSettlementGM and not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
		print(">> SettlementProxy:OnBattleSettlement should not go this!")
		return
	end

	Settlement.GameRawData = InMsgBody

	if Settlement.CurrentResultMode ~= Settlement.EResultMode.Victory then
		Settlement.CurrentResultMode = Settlement.EResultMode.Finish

		local UIManager = UE.UGUIManager.GetUIManager(GameInstance)
		UIManager:TryCloseDynamicWidget("UMG_SettlementDetail")

		if not self:IsReviewStart() then
			print(">> SettlementProxy: Game Show UMG_SettlementResult")
			UIManager:TryLoadDynamicWidget("UMG_SettlementResult")
		end
	end

	--发送一条胜利或失败的消息，目前只给EventManager用来播语音
	local IsVictory = Settlement.CurrentResultMode == Settlement.EResultMode.Victory
	MsgHelper:SendCpp(nil, "BattleSettlement.GameResult", IsVictory, Settlement.SettleRank)
	print("nzyp " .. "BattleSettlement.GameResult", tostring(IsVictory), Settlement.SettleRank)
end

function SettlementProxy:OnCampSettlement(InMsgBody)
	print(">> SettlementProxy:OnCampSettlement")
	GameLog.Dump(InMsgBody, InMsgBody)

	if not Settlement.bLocalSettlementGM and not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
		return
	end

	Settlement.TeamRawData = InMsgBody
	Settlement.PlayerList = {}
	for key, value in pairs(InMsgBody.PlayerArray) do
		table.insert(Settlement.PlayerList, value)
	end

	table.sort(Settlement.PlayerList,function(a,b)
		local TeamSubsystem = UE.UTeamExSubsystem.Get(GameInstance)
		return TeamSubsystem:GetPlayerNumberInTeamById(a.PlayerId) < TeamSubsystem:GetPlayerNumberInTeamById(b.PlayerId)
	end)

	Settlement.SettleRank = InMsgBody.TeamRank
	Settlement.CurrentResultMode = Settlement.EResultMode.Finish
	if InMsgBody.TeamRank == 1 then
		Settlement.CurrentResultMode = Settlement.EResultMode.Victory
	end

	local UIManager = UE.UGUIManager.GetUIManager(GameInstance)
	UIManager:TryCloseDynamicWidget("UMG_SettlementDetail")
	UIManager:TryLoadDynamicWidget("UMG_SettlementResult")
end

function SettlementProxy:OnCacheOberserData(InMsgBody)
	print(">> SettlementProxy:OnCacheOberserData")
	GameLog.Dump(InMsgBody, InMsgBody)
	Settlement.OBViewTargetDesc = InMsgBody
	MsgHelper:Send(nil, MsgDefine.SETTLEMENT_ShowObserverInfo)
end

function SettlementProxy:OnPreLoadMap(InMapName)
	print(">> SettlementProxy:OnPreLoadMap")
	Settlement.CurrentResultMode = Settlement.EResultMode.None
	Settlement.PlayerList = {}
	Settlement.bReceivedBattleSettlement = false
	Settlement.bReceivedPlayerSettlement = false
end


return SettlementProxy
