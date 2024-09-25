--
-- DS-LobbyServer通信协议
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2021.12.20
-- @Refactorer wangyang

_G.DSProtocol = {}

-- -- 销毁
-- DSProtocol.Destroy = function()
--     print("DSProtocol", "---> Destroy")

-- end


--[[
    Call From C++
]]
-- 请求连接Server
DSProtocol.StartConnectServer = function(InGameInstance)
	print("DSProtocol", ">> StartConnectServer..", InGameInstance)

    _G.GameInstance = InGameInstance
    -- d2s.ConnectServer()
    MvcEntry:GetModel(DSSocketMgr):Connect()
end

-- 加载新地图完成(from cpp)
DSProtocol.OnPostLoadMapWithWorld = function(InNewWorld, InLocalURL, InMapName)
	print("[KeyStep-->DS][7] DSProtocol", "::OnPostLoadMapWithWorld Call ReqPlayerInfo, ", InNewWorld, InLocalURL, InMapName)

    MvcEntry:GetCtrl(DSServerCtrl):SendProto_PlayerInfoReq()
end

-- 父进程加载新地图完成，可以开始 Fork(from cpp)
DSProtocol.ReadyForkProcess = function()
	print("ReadyForkProcess")
    
    local DSAgent = UE.UDSAgent.Get(GameInstance)
    local GameId = DSAgent:GetDSGameInfo().GameId
    
    MvcEntry:GetCtrl(DSServerCtrl):SendProto_ReadyForkProcess(GameId)
end

-- 父进程返回子进程的 GameId 和 Pid(from cpp)
DSProtocol.ForkProcessRsp = function(InGameId, InChildGameId, InPid)
	print("ForkProcessRsp")

    MvcEntry:GetCtrl(DSServerCtrl):SendProto_ForkProcessRsp(InGameId, InChildGameId, InPid)
end

-- DS 崩溃通知后台
DSProtocol.NotifyDSCrash = function()
	print("DSProtocol", ">> NotifyDSCrash")
    local ProcessId = UE.US1MiscLibrary.GetCurrentProcessId()

    MvcEntry:GetCtrl(DSServerCtrl):SendProto_NotifyDSCrash(ProcessId)
end

-- 玩家在线状态改变
DSProtocol.NotifyPlayerOnlineStateChanged = function(PlayerId, NewState)
    local StateTagName = tostring(NewState)
    print("DSProtocol", ">> NotifyPlayerOnlineStateChanged, ", PlayerId, StateTagName)

    -- d2s.CallLuaRpc("PlayerOnlineStateChange", PlayerId, StateTagName)
    MvcEntry:GetCtrl(DSServerCtrl):SendProto_PlayerOnlineStateChangeReq(PlayerId,StateTagName)
end

-- 游戏进度状态改变
DSProtocol.NotifyGameStateChanged = function(NewState)
    local CurGUVRootObjectState = NewState
    print("DSProtocol", ">> NotifyGameStateChanged, ", CurGUVRootObjectState)

    -- d2s.CallLuaRpc("GameStateChange", CurGUVRootObjectState)
    MvcEntry:GetCtrl(DSServerCtrl):SendProto_GameStateChangeReq(CurGUVRootObjectState)
end

--游戏时长同步
DSProtocol.SendProto_GameTotalTime = function()
    local GameMode = UE.UGameplayStatics.GetGameMode(GameInstance)
    local GameTotalTime = GameMode:GetGameTotalTime()
    MvcEntry:GetCtrl(DSServerCtrl):SendProto_GameParamSyncReq(GameTotalTime)
end


-- DS结束同步：被Shutdown
DSProtocol.NotifyDedicatedServerEnd = function(EndReason)
    local Reason = EndReason
    print("DSProtocol", ">> NotifyDedicatedServerEnd", Reason)

    MvcEntry:GetCtrl(DSServerCtrl):CatchDedicatedServerEnd()
    MvcEntry:GetCtrl(DSServerCtrl):SendProto_DedicatedServerEnd(Reason)
end

--游戏玩法结束，包括所有模式的结束通知
DSProtocol.OnGameOverEvent = function()
    print("DSProtocol.OnGameOverEvent")
    MvcEntry:GetCtrl(DSServerCtrl):CatchDedicatedGameOver()
end


DSProtocol.OnSettlementBRPlayer = function(InPlayerId, InPlayerInfo, InKillsAndDeathsInfo)
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
    Dump(HeroSkillData, HeroSkillData)
    Dump(KillsAndDeathsInfo, KillsAndDeathsInfo)
    MvcEntry:GetCtrl(DSServerCtrl):SendProto_PlayerSettlementReq(SettlePlayerId, SettleInfoPlayer, KillsAndDeathsInfo)
end

DSProtocol.OnSettlementBRTeam = function(InTeamId, InTeamInfo)
    print("OnSettlementBRTeam")
    local SettleTeamId = InTeamId

    local SettleInfoTeam =
    {
        TeamId = InTeamId,
        RemainingPlayers = InTeamInfo.RemainingPlayers,
        RemainingTeams = InTeamInfo.RemainingTeams,
        TeamRank = InTeamInfo.TeamRank,
        bIsGameOver = InTeamInfo.bIsGameOver,
        bIsWinnerTeam = InTeamInfo.bIsWinnerTeam,
        TeamSurvivalTime = InTeamInfo.TeamSurvivalTime,
        bIsTeamOver = InTeamInfo.bIsTeamOver,
    }

    Dump(SettleInfoTeam, SettleInfoTeam)
    -- d2s.CallLuaRpc("BroadcastTeamSettlement", SettleTeamId, SettleInfoTeam)
    MvcEntry:GetCtrl(DSServerCtrl):SendProto_TeamSettlementReq(SettleTeamId,SettleInfoTeam)
end

-- Pure data gather, Do not affect settlement logic by any means.
--【TBT】【玩法】【结算】玩家退出房间时获取结算字段 https://www.tapd.cn/68880148/s/1359321
DSProtocol.OnSettlementBRTeam_Early = function(InPlayerId, InTeamId, InTeamInfo)
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

    MvcEntry:GetCtrl(DSServerCtrl):SendProto_EarlyTeamSettlementReq(SettlePlayerId, SettleInfoTeam, PlayerArray)
end

DSProtocol.OnSettlementBRGame = function(InGameInfo)
    print("OnSettlementBRGame")
    local SettleInfoGame =
    {
        WinnerTeamId = InGameInfo.WinnerTeamId
    }

    Dump(SettleInfoGame, SettleInfoGame)
    -- d2s.CallLuaRpc("BroadcastBattleSettlement", SettleInfoGame)
    MvcEntry:GetCtrl(DSServerCtrl):SendProto_BattleSettlementReq(SettleInfoGame)
end

DSProtocol.OnSettlementCamp = function(InGameData)
    print("OnSettlementCamp")
    local CampDataArray = InGameData.CampDataArray
    local localCampSettlement = {}    
    local localPlayerInfoList = {}
    for CampDataKey, CampDataValue in pairs(CampDataArray) do
		local TeamDataArray = CampDataValue.TeamDataArray
        localCampSettlement[CampDataKey] = {}
        local localTeamSettlement = {}
        for TeamDataKey, TeamDataValue in pairs(TeamDataArray) do
            local PlayerDataArray = TeamDataValue.PlayerDataArray
            localTeamSettlement[TeamDataKey] = {}
            local localPlayerSettlement = {}
            for PlayerDataKey, PlayerDataValue in pairs(PlayerDataArray) do
                localPlayerSettlement[PlayerDataKey] = 
                {
                    PlayerKill = PlayerDataValue.PlayerKill,
                    PlayerDeath = PlayerDataValue.PlayerDeath,
                    PlayerAssist = PlayerDataValue.PlayerAssist,
                    PlayerDamage = PlayerDataValue.PlayerDamage,
                    PlayerScore = PlayerDataValue.PlayerScore,
                    ConquestCount = PlayerDataValue.ConquestCount,

                    PlayerId = PlayerDataValue.PlayerId,
                    TeamId = PlayerDataValue.TeamId,
                    CampId = PlayerDataValue.CampId,
                    PosInTeam = PlayerDataValue.PosInTeam,
                    HeroTypeId = PlayerDataValue.RuntimeHeroId,
                    PlayerName = PlayerDataValue.PlayerName,
                    KDA = PlayerDataValue.KDA,
                    bIsWinner = PlayerDataValue.bWin
                }

                localPlayerInfoList[PlayerDataKey] = {
                    CampId = PlayerDataValue.CampId,
                    TeamId = PlayerDataValue.TeamId,
                }
            end
            localTeamSettlement[TeamDataKey].PlayerArray = localPlayerSettlement
        end
        localCampSettlement[CampDataKey].TeamSettlement = localTeamSettlement
        localCampSettlement[CampDataKey].Rank = CampDataValue.CampRank
        localCampSettlement[CampDataKey].bIsWinner = CampDataValue.bIsCampWinner
	end
    
    local SettlementData = {
        CampSettlement = localCampSettlement,
        PlayerInfoList = localPlayerInfoList,
        BattleTime = InGameData.BattleTime,
    }

	Dump(SettlementData, SettlementData)
    MvcEntry:GetCtrl(DSServerCtrl):SendProto_CampSettlementReq(SettlementData)
end

---------- Settlement ----------

--//END

---------- GenericStatisticSystem ----------

DSProtocol.OnGSBattleData = function(BattleDataReq)
    print("OnGSBattleData")
    local BattleData = {}
    local BattleDataList = BattleDataReq.BattleDataList
    for i = 1, BattleDataList:Length(), 1 do

        local WeaponsData = {}
        local HerosData = {}
        local VehiclesData = {}
        
        local TempBattleData = BattleDataList:GetRef(i)
        local TempWeaponsData = TempBattleData.GunDataInfos
        local TempHerosData = TempBattleData.HeroDataInfos
        local TempVehiclesData = TempBattleData.VehicleDataInfos

        local PlayerId = TempBattleData.PlayerId
        
        for j = 1, TempWeaponsData:Length(), 1 do
            local Temp = TempWeaponsData:GetRef(j)
            local FinalData = {}
            local ItemId = Temp.ItemId
            
            FinalData.GunTotalKill = Temp.GunTotalKill
            FinalData.GunTotalHeadShot = Temp.GunTotalHeadShot
            FinalData.GunTotalDamage = Temp.GunTotalDamage
            FinalData.GunPossessedTime = Temp.GunPossessedTime
            FinalData.GunTotalKnockDown = Temp.GunTotalKnockDown
            -- print("table.insert TempWeaponsData " .. j)
            WeaponsData[ItemId] = FinalData
        end
        -- print("WeaponsData")
        -- Dump(WeaponsData, WeaponsData)

        for j = 1, TempHerosData:Length(), 1 do
            local Temp = TempHerosData:GetRef(j)
            local FinalData = {}
            local HeorId = Temp.HeroId
            FinalData.KnockDownNum = Temp.KnockDownNum
            FinalData.KillNum = Temp.KillNum
            -- print("table.insert TempHerosData " .. j)
            HerosData[HeroId] = FinalData
        end
        -- print("HerosData")
        -- Dump(HerosData, HerosData)

        for j = 1, TempVehiclesData:Length(), 1 do
            local Temp = TempVehiclesData:GetRef(j)
            local FinalData = {}
            local ItemId = Temp.ItemId
            FinalData.KnockDownNum = Temp.KnockDownNum
            FinalData.KillNum = Temp.KillNum
            -- print("table.insert TempVehiclesData " .. j)
            VehiclesData[ItemId] = FinalData
        end
        -- print("VehiclesData")
        -- Dump(VehiclesData, VehiclesData)

        BattleData[PlayerId] = {
            WeaponsData = WeaponsData,
            HerosData = HerosData,
            VehiclesData = VehiclesData
        }
    end

    -- Dump(BattleData, BattleData)

    MvcEntry:GetCtrl(DSServerCtrl):SendProto_SaveBattleDataReq({BattleData=BattleData})
end

---------- GenericStatisticSystem ----------

--//END

---------- DS SelectHero ----------
DSProtocol.SendProto_PlayerRuntimeHero = function(GameId, PlayerId, HeroId)
    print("SendProto_PlayerRuntimeHero")

    MvcEntry:GetCtrl(DSServerCtrl):SendProto_PlayerRuntimeHero(GameId, PlayerId, HeroId)
end
---------- DS SelectHero ----------

DSProtocol.OnClientGetPlayGameModeCount = function(GameModeId)
    print("OnClientGetPlayGameModeCount")
    local QueryPlayGameModeCountData =
    {
        DataType = GameModeId,
    }
    
    Dump(QueryPlayGameModeCountData, QueryPlayGameModeCountData)

    -- MvcEntry:GetCtrl(DSServerCtrl):SendProto_ClientGetPlayGameModeCountReq(QueryPlayGameModeCountData)
end

--//END

--[[
    下述逻辑已挪至 DSProtoCtrl 该文件只处于C++ 到 Lua的通信
]]
-- DSProtocol.OnConnectedToServer = function()
-- 	print("DSProtocol", ">> OnConnectedToServer")

--     local DSAgent = UE.UDSAgent.Get(GameInstance)
--     DSAgent:OnConnected()

--     local ProcessId = UE.US1MiscLibrary.GetCurrentProcessId()
--     d2s.CallLuaRpc("StartNotify", ProcessId)
-- end

-- -- 接收游戏参数
-- s2d.SyncGameParam = function(InParams)
-- 	print("DSProtocol", ">> s2d.SyncGameParam")
--     Dump(InParams, InParams, 9)

--     local GameParam = UE.FDSGameInfo()
--     --{
--         GameParam.GameID = InParams.GameId
--         GameParam.MapPath = InParams.ScenePath
--         GameParam.GameModePath = InParams.GameModePath
--         GameParam.Port = InParams.Port
--     --}
    
--     local GameId = InParams.GameId
--     local Ip = InParams.OuterIp
--     local Branch = InParams.GameBranch
--     Netlog.GameId = GameId
--     if (Ip ~= nil) and (Ip ~= "") and (Ip ~= "127.0.0.1")  then
--         Netlog.DSLogURL = "http://"..Ip.."/"..Branch.."/DSLogs/"..GameId..".log"
--     end
--     local debug={
--         GameId=Netlog.GameId,
--         DSLogURL=Netlog.DSLogURL,
--     }
--     Dump(debug,debug)

--     local DSAgent = UE.UDSAgent.Get(GameInstance)
--     DSAgent:SyncGameParam(GameParam)
-- end

-- -- 接收玩家数据
-- s2d.SyncPlayerInfo = function(InPlayerInfo)
-- 	print("DSProtocol", ">> s2d.sync_player_info")
--     Dump(InPlayerInfo, InPlayerInfo, 9)

--     local PlayerInfo = UE.FDSPlayerInfo()
--     --{
--         PlayerInfo.Name = InPlayerInfo.Name
--         PlayerInfo.PlayerId = InPlayerInfo.PlayerId
--         PlayerInfo.TeamId = InPlayerInfo.TeamId
--         PlayerInfo.HeroId = InPlayerInfo.HeroId
--         PlayerInfo.TeamPosition = InPlayerInfo.TeamPosition
--         PlayerInfo.bReconnect = InPlayerInfo.bReconnect
--         PlayerInfo.bAIPlayer = InPlayerInfo.bAIPlayer
--     --}

--     local DSAgent = UE.UDSAgent.Get(GameInstance)
--     local VerifyKey = DSAgent:SyncPlayerInfo(PlayerInfo)

--     print("[KeyStep-->DS][9] d2s", "::SyncLoginKey PlayerId = ", InPlayerInfo.PlayerId)
--     d2s.CallLuaRpc("SyncLoginKey", InPlayerInfo.PlayerId, VerifyKey)
-- end

-------------------------------------------- DS/Game/Player State Change ------------------------------------



-- -- 响应退出App
-- DSProtocol.OnRespQuitDS = function(InReason, InDelayTime)
-- 	print("DSProtocol", ">> OnRespQuitDS, ", InReason, InDelayTime)
--     --UE.UKismetSystemLibrary.QuitGame(GameInstance, )
-- 	UE.UKismetSystemLibrary.ExecuteConsoleCommand(GameInstance, "Quit")
-- end

---------- Settlement ----------

DSProtocol.OnDsTaskDataFlowReq = function(Kill, KnockDown,Damage,LiftUp,SurviveTime,ModeId,Hero,Weapon)
    print("OnDsTaskDataFlowReq")
    local SettleTeamId = InTeamId

    local Result =
    {
        Kill = Kill,
        KnockDown = KnockDown,
        Damage = Damage,
        LiftUp = LiftUp,
        SurviveTime =SurviveTime,
    }

	-- Dump(Result, Result)
    
    -- d2s.CallLuaRpc("BroadcastTeamSettlement", SettleTeamId, SettleInfoTeam)
    --MvcEntry:GetCtrl(DSServerCtrl):SendProto_DsTaskDataFlowReq(Result, ModeId, Hero, Weapon)
end


DSProtocol.DsTaskDataNotify = function(MissionInfo)
    -- 【【DS性能】GenericStatistic 巨量log】https://www.tapd.cn/68880148/prong/stories/view/1168880148001018815
    -- print("DSProtocol", ">> DsTaskDataNotify, ",  MissionInfo)

    -- d2s.CallLuaRpc("GameStateChange", CurGUVRootObjectState)
    MvcEntry:GetCtrl(DSServerCtrl):SendProto_DsTaskDataNotify(MissionInfo)
end

DSProtocol.TestTaskUpdateProcessNotify = function(MissionInfo)
    print("DSProtocol", ">> TestTaskUpdateProcessNotify, ",  MissionInfo)

    -- d2s.CallLuaRpc("GameStateChange", CurGUVRootObjectState)
    MvcEntry:GetCtrl(DSServerCtrl):TaskUpdateProcessNotify_Func(MissionInfo)
end
return DSProtocol