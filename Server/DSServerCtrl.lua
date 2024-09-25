require("Server.DSServerModel");


local class_name = "DSServerCtrl";
DSServerCtrl = DSServerCtrl or BaseClass(UserGameController,class_name);


function DSServerCtrl:__init()
end

function DSServerCtrl:Initialize()
    self.IsDSServerEnd = false
    self.IsDSGameover = false
end

function DSServerCtrl:AddMsgListenersUser()
    self.ProtoList = {
        { MsgName = DSPb_Message.DSHeartbeatRsp,        Func = self.DSHeartbeatRsp_Func },
        { MsgName = DSPb_Message.GameParamSync,    Func = self.GameParamSync_Func },
        { MsgName = DSPb_Message.ForkProcessReq,    Func = self.ForkProcessReq_Func },
        { MsgName = DSPb_Message.PlayerInfoRsp,    Func = self.PlayerInfoRsp_Func },
        { MsgName = DSPb_Message.PlayerReconnectReq,    Func = self.PlayerReconnect_Func },
        { MsgName = DSPb_Message.UpdatePlayerInfoSync,    Func = self.UpdatePlayerInfoSync_Func },
        { MsgName = DSPb_Message.PlayerExitDSSync,    Func = self.PlayerExitDSSync_Func },
        { MsgName = DSPb_Message.DSSelectHeroRsp,	Func = self.DSSelectHeroRsp_Func },
        { MsgName = DSPb_Message.TaskUpdateProcessNotify,	Func = self.TaskUpdateProcessNotify_Func },
        { MsgName = DSPb_Message.KillDSSync, Func = self.KillDSSync_Func },
    }
    self.MsgList = {
        {Model = DSSocketMgr,MsgName = DSSocketMgr.CMD_ON_CONNECTED,Func = self.OnConnectedHandler},
    }
end

function DSServerCtrl:OnConnectedHandler()
    local DSAgent = UE.UDSAgent.Get(GameInstance)
    DSAgent:OnConnected()

    local ProcessId = UE.US1MiscLibrary.GetCurrentProcessId()
    local IsAsanDS = UE.US1MiscLibrary.IsBuildWithASAN()
    local GameId = DSAgent:GetDSGameInfo().GameId

    print("DSServerCtrl", ">> OnConnectedHandler GameId=", GameId, "IsChildProcessDS=", DSAgent:IsChildProcessDS())

    self:SendProto_RegistDSReq(ProcessId, IsAsanDS, GameId)

    -- if not DSAgent:IsChildProcessDS() then
    --     self:SendProto_RegistDSReq(ProcessId, IsAsanDS, GameId)
    -- else
    --     print("OnConnectedHandler SendProto_PlayerInfoReq")
    --     -- 子进程连接完成，直接请求玩家数据
    --     self:SendProto_PlayerInfoReq(ProcessId, GameId)
    -- end
end

function DSServerCtrl:DSHeartbeatRsp_Func(Msg)
    --TODO 心跳包处理
end
--[[
    message GameParamSync
    {
        string GameId = 1;
        string Ip = 2;
        string HostIp = 3;
        int32 Port = 4;
        string ScenePath = 5;
        string GameBranch = 6;
        string Stream = 7;
        string Changelist = 8;
        bool RunInWsl = 9;
        GameplayInfoBase GameplayInfo = 10;
    }
]]
function DSServerCtrl:GameParamSync_Func(InParams)
    print("DSServerCtrl", ">> GameParamSync_Func")
    -- Dump(InParams, InParams, 9)
    -- print_r(InParams)

    local GameParam = UE.FDSGameInfo()
    --{
        GameParam.GameId = InParams.GameId
        GameParam.GameModeId = InParams.GameplayInfo.ModeId
        GameParam.MapPath = InParams.ScenePath
        GameParam.Port = InParams.Port
        GameParam.TeamType = InParams.GameplayInfo.TeamType
        GameParam.SceneId = InParams.GameplayInfo.SceneId
        GameParam.bCanRepeatHero = InParams.GameplayInfo.bCanRepeatHero
        GameParam.bForkDS = InParams.IsForkDS
        GameParam.EncryptionSeedKey = InParams.DsEncryptKey
        GameParam.bEnableObjectPool = InParams.bEnableObjectPool
		GameParam.HumanTeamCount = InParams.HumanTeamCount
		GameParam.HumanPlayerCount = InParams.HumanPlayerCount
    --}

    local GameId = InParams.GameId
    local Ip = InParams.Ip
    local HostIp = InParams.HostIp
    local Branch = InParams.GameBranch
    Netlog.GameId = GameId
    Netlog.bRunInWsl = InParams.RunInWsl or false
    Netlog.GateVersion = InParams.Stream .. "_" .. InParams.Changelist
    if (HostIp ~= nil) and (HostIp ~= "") and (HostIp ~= "127.0.0.1")  then
        Netlog.DSLogURL = "http://"..HostIp.."/"..Branch.."/DSLogs/"..GameId..".log"
    end
    local debug={
        GameId=Netlog.GameId,
        DSLogURL=Netlog.DSLogURL,
        bRunInWsl=Netlog.bRunInWsl,
        GateVersion=Netlog.GateVersion
    }
    -- Dump(debug,debug)

    local DSAgent = UE.UDSAgent.Get(GameInstance)
    DSAgent:SyncGameParam(GameParam)

    local GameMode = UE.UGameplayStatics.GetGameMode(GameInstance)
    local GameTotalTime = GameMode:GetGameTotalTime()

    MvcEntry:GetCtrl(DSServerCtrl):SendProto_GameParamSyncReq(GameTotalTime)
    if DSAgent:IsChildProcessDS() then
        MvcEntry:GetCtrl(DSServerCtrl):SendProto_PlayerInfoReq() 
    end
end

function DSServerCtrl:ForkProcessReq_Func(InParams)
    print("DSServerCtrl", ">> ForkProcessReq_Func")

    local ForkDSInfo = UE.FForkDSInfo()
    --{
        ForkDSInfo.ChildId = InParams.ForkIndex
        ForkDSInfo.ChildCmdLine = InParams.ChildCmdLine
        ForkDSInfo.GameId = InParams.GameId
        ForkDSInfo.bEnableThreading = InParams.bEnableThreading
    --}

    local DSAgent = UE.UDSAgent.Get(GameInstance)
    DSAgent:SyncForkProcess(ForkDSInfo)

end

--[[
    message PlayerInfoRsp
    {
    string GameId = 1;
    string LobbyAddr = 2;
    int64 TeamId = 3;
    int64 TeamPosition = 4;
    string Name = 5;
    int64 HeroId = 6;
    bool bAIPlayer = 7;
    int64 PlayerId = 8;
    bool bInBattle = 9;
    bool bReconnect = 10;
    int64 SkinId = 11;
    map<int64, HeroSkinListBase> HeroInfoList = 12;
    string RtcGameToken = 13;
    string RtcTeamToken = 14;
    string Changelist = 15;
    WeaponSkinListBase WeaponSkinList = 16;                 // 玩家皮肤列表
    map<int64, DisplayBoardInfo> DisplayBoardMap = 17;      // 不同角色的展示板数据,key是角色Id，value角色的展示板数据
    FavorInfo FavorData = 18;                               // 好感度数据
    map<int64, TaskInfoNode> TaskInfoMap = 19;              // 传给局内任务数据,Key是任务Id,Value是任务的进度信息
    map<int64, HeroVehicleNode> HeroVehicleMap = 20;        // Key是载具对应的物品Id, Value是单个载具携带的解锁皮肤数据以及贴纸数据
    }
]]

function DSServerCtrl:PlayerInfoRsp_Func(InPlayerInfo)
    print("DSServerCtrl", ">> PlayerInfoRsp_Func")
    -- Dump(InPlayerInfo, InPlayerInfo, 9)
    local PlayerInfo = UE.FDSPlayerInfo()
    --{
        PlayerInfo.PlayerName = InPlayerInfo.PlayerName
        PlayerInfo.PlayerId = InPlayerInfo.PlayerId
        PlayerInfo.TeamId = InPlayerInfo.TeamId
        PlayerInfo.HeroId = InPlayerInfo.HeroId
        PlayerInfo.TeamPosition = InPlayerInfo.TeamPosition
        PlayerInfo.bReconnect = InPlayerInfo.bReconnect or false
        PlayerInfo.bAIPlayer = InPlayerInfo.bAIPlayer
        
        print("GLL_Debug UserID is",InPlayerInfo.UserId)

        self:PlayerInfoRsp_ParseHeroSkins(InPlayerInfo.HeroInfoList, PlayerInfo.HeroInfoList)
        self:PlayerInfoRsp_ParseTasks(InPlayerInfo.TaskInfoMap, PlayerInfo.TaskInfoMap)
        
        if not PlayerInfo.bAIPlayer then
            self:PlayerInfoRsp_ParseWeaponSkins(InPlayerInfo.WeaponSkinList, PlayerInfo.RawWeaponInfoSkinList)
            self:PlayerInfoRsp_ParseVehicleSkins(InPlayerInfo.HeroVehicleMap, PlayerInfo.RawVehicleInfoSkinList)
            
            self:PlayerInfoRsp_ParseDisplayBoardMap(InPlayerInfo.DisplayBoardMap, PlayerInfo.DisplayBoardMap)
            self:PlayerInfoRsp_ItemInfoMap(InPlayerInfo.ItemInfoMap, PlayerInfo.ItemInfoMap)
        end

        PlayerInfo.RtcGameToken = InPlayerInfo.RtcGameToken
        PlayerInfo.RtcTeamToken = InPlayerInfo.RtcTeamToken
    --}

    local DSAgent = UE.UDSAgent.Get(GameInstance)
    local VerifyKey = DSAgent:SyncPlayerInfo(PlayerInfo)

    print("[KeyStep-->DS][9] d2s", "::CheckLoginKey PlayerId = ", InPlayerInfo.PlayerId)
    -- d2s.CallLuaRpc("SyncLoginKey", InPlayerInfo.PlayerId, VerifyKey)
    self:SendProto_CheckLoginKeyReq(InPlayerInfo.PlayerId,VerifyKey)
end

function DSServerCtrl:UpdatePlayerInfoSync_Func(Msg)

end

function DSServerCtrl:PlayerReconnect_Func(InPlayerInfo)
    print("DSServerCtrl PlayerReconnect_Func PlayerId = ", InPlayerInfo.PlayerId)

    local PlayerInfo = UE.FDSPlayerInfo()
    --{
        PlayerInfo.PlayerId = InPlayerInfo.PlayerId
        PlayerInfo.bReconnect = true
    --}

    local DSAgent = UE.UDSAgent.Get(GameInstance)
    local VerifyKey = DSAgent:SyncPlayerInfo(PlayerInfo)

    self:SendProto_PlayerReconnectRsp(InPlayerInfo.GameId,InPlayerInfo.PlayerId,VerifyKey)
end

--玩家退出DS
function DSServerCtrl:PlayerExitDSSync_Func(InExitPlayerInfo)
    print("DSServerCtrl: PlayerExitDSSync")

    local PlayerInfo = UE.FDSPlayerExitInfo()
    --{
        PlayerInfo.PlayerId = InExitPlayerInfo.PlayerId
        PlayerInfo.ExitReason = InExitPlayerInfo.Reason
    --}

    local DSAgent = UE.UDSAgent.Get(GameInstance)
    DSAgent:SyncPlayerExit(PlayerInfo)
end

--DS收到更换英雄的反馈
function DSServerCtrl:DSSelectHeroRsp_Func(ChooseHeroData)
    print("DSServerCtrl", ">> DSSelectHeroRsp_Func")
    local GameState = UE.UGameplayStatics.GetGameState(GameInstance)
    local GameState_ASC = GameState.GameState_ASC
    if not CommonUtil.IsValid(GameState_ASC) then
        return
    end

    local HeroIslandRuleTag = UE.FGameplayTag()
    HeroIslandRuleTag.TagName = "GameplayAbility.GMS_GS.Gameplay.HeroIsland.HeroIslandRule"
    
    local HeroIslandRuleGA = UE.UGeSkillBlueprintLibrary.GetAbilityInstanceByAssetTag(GameState, HeroIslandRuleTag)
    
    if not CommonUtil.IsValid(HeroIslandRuleGA) then
        return
    end

    HeroIslandRuleGA:RecvHeroSelectedResFromLobby(  ChooseHeroData.PlayerId,
                                                    ChooseHeroData.bChanged,
                                                    ChooseHeroData.HeroId,
                                                    ChooseHeroData.bPreSelectHero,
                                                    ChooseHeroData.Reason
                                                    )
    
                                     
end

-- 杀死DS同步
function DSServerCtrl:KillDSSync_Func(Info)
    print_r(Info, "KillDSSync===========")
    self:CatchDedicatedServerEnd()
end

------------------------------------请求相关----------------------------
--注册DSPid到DSAgent
function DSServerCtrl:SendProto_RegistDSReq(Pid, IsAsanDS, GameId)
    local Msg = {
        Pid = Pid,
        bAsanDs = IsAsanDS,
        GameId = GameId,
    }
    self:SendProto(DSPb_Message.RegistDSReq,Msg)
end

--通知后台 DS 崩溃
function DSServerCtrl:SendProto_NotifyDSCrash(pid)
    local Msg = {
        Pid = pid,
    }
    self:SendProto(DSPb_Message.OnDSCrash,Msg)
end

--请求玩家信息
function DSServerCtrl:SendProto_PlayerInfoReq()
    local Msg = {
    }
    print("SendProto_PlayerInfoReq")
    self:SendProto(DSPb_Message.PlayerInfoReq,Msg)
end

--父进程通知后台可以开始 Fork
function DSServerCtrl:SendProto_ReadyForkProcess(GameId)
    local Msg = {
        GameId = GameId,
    }

    print("SendProto_ReadyForkProcess")
    self:SendProto(DSPb_Message.ReadyForkProcess,Msg)
end

--父进程返回子进程的 GameId 和 Pid
function DSServerCtrl:SendProto_ForkProcessRsp(GameId, ChildGameId, Pid)
    local Msg = {
        GameId = GameId,
        ChildGameId = ChildGameId,
        Pid = Pid,
    }

    print("SendProto_ForkProcessRsp")
    self:SendProto(DSPb_Message.ForkProcessRsp,Msg)
end

--DS接收并验证玩家信息后通知后台
function DSServerCtrl:SendProto_CheckLoginKeyReq(PlayerId,Key)
    local Msg = {
        PlayerId = PlayerId,
        Key = Key,
    }
    self:SendProto(DSPb_Message.CheckLoginKeyReq,Msg)
end

--DS验证重连玩家信息后通知后台
function DSServerCtrl:SendProto_PlayerReconnectRsp(GameId,PlayerId,Key)
    local Msg = {
        GameId = GameId,
        PlayerId = PlayerId,
        Key = Key,
    }
    self:SendProto(DSPb_Message.PlayerReconnectRsp,Msg)
end

--玩家在线状态同步
function DSServerCtrl:SendProto_PlayerOnlineStateChangeReq(PlayerId,StateTagName)
    local Msg = {
        PlayerId = PlayerId,
        StateTagName = StateTagName,
    }
    self:SendProto(DSPb_Message.PlayerOnlineStateChangeReq,Msg)
end

--玩家选定英雄同步
function DSServerCtrl:SendProto_PlayerRuntimeHero(GameId, PlayerId, HeroId)
    local Msg = {
        GameId = GameId,
        PlayerId = PlayerId,
        HeroId = HeroId,
    }
    self:SendProto(DSPb_Message.PlayerRuntimeHeroSync, Msg)
end


--游戏状态同步
function DSServerCtrl:SendProto_GameStateChangeReq(Status)
    local Msg = {
        Status = Status,
    }
    self:SendProto(DSPb_Message.GameStateChangeReq,Msg)
end

--DS结束同步：被Shutdown
function DSServerCtrl:SendProto_DedicatedServerEnd(Reason)
    local Msg = {
        Reason = Reason,
    }
    self:SendProto(DSPb_Message.DedicatedServerEndSync,Msg)
end

--玩家结算
function DSServerCtrl:SendProto_PlayerSettlementReq(PlayerId, PlayerSettlement, KillsAndDeaths)
    local Msg = {
        PlayerId = PlayerId,
        PlayerSettlement = PlayerSettlement,
        KillsAndDeaths = KillsAndDeaths
    }
    self:SendProto(DSPb_Message.PlayerSettlementReq,Msg)
end

--队伍结算
function DSServerCtrl:SendProto_TeamSettlementReq(TeamId,TeamSettlement)
    local Msg = {
        TeamId = TeamId,
        TeamSettlement = TeamSettlement,
    }
    self:SendProto(DSPb_Message.TeamSettlementReq,Msg)
end

-- 队伍信息协议 随同玩家结算发送
function DSServerCtrl:SendProto_EarlyTeamSettlementReq(PlayerId, TeamSettlement, PlayerArray)
    local Msg = {
        PlayerId = PlayerId,
        TeamSettlement = TeamSettlement,
        PlayerArray = PlayerArray
    }
    self:SendProto(DSPb_Message.EarlyTeamSettlementReq,Msg)
end

--游戏结算
function DSServerCtrl:SendProto_BattleSettlementReq(BattleSettlement)
    local Msg = {
        BattleSettlement = BattleSettlement,
    }
    self:SendProto(DSPb_Message.BattleSettlementReq,Msg)
end

--游戏结算 —— 带阵营
function DSServerCtrl:SendProto_CampSettlementReq(SettlementData)
    local Msg = SettlementData
    self:SendProto(DSPb_Message.CampSettlementReq,Msg)
end

--统计系统：枪械、英雄、车辆数据
function DSServerCtrl:SendProto_SaveBattleDataReq(BattleDataList)
    local Msg = BattleDataList
    self:SendProto(DSPb_Message.SaveBattleDataReq,Msg)
end

--DS更换英雄
function DSServerCtrl:SendProto_DSSelectHeroReq(PlayerId, HeroId, bPreSelectHero)
    local Msg = {
        PlayerId = PlayerId,
        HeroId = HeroId,
        bPreSelectHero = bPreSelectHero,
    }
    self:SendProto(DSPb_Message.DSSelectHeroReq,Msg)
end

--游戏参数同步
function DSServerCtrl:SendProto_GameParamSyncReq(GameTotalTime)
    local DSAgent = UE.UDSAgent.Get(GameInstance)
    local GameId = DSAgent:GetDSGameInfo().GameId

    print("SendProto_GameParamSyncReq=",GameTotalTime," Gameid=",GameId)

    local Msg = {
        GameId = GameId,
        GameTotalTime = GameTotalTime,
    }
    self:SendProto(DSPb_Message.GameParamSyncReq,Msg)
end

--局内数据上报
function DSServerCtrl:SendProto_DsTaskDataFlowReq(Result, ModeId, Hero, Weapon)
    print("SendProto_DsTaskDataFlowReq",Result, ModeId, Hero, Weapon)

    local Msg = {
        Result = Result,
        ModeId = ModeId,
        Hero = Hero,
        Weapon = Weapon,
    }
    --self:SendProto(DSPb_Message.OnDsTaskDataFlowReq,Msg)
end

-- example skininfo tables:
-- WeaponSkinList = {
--     ["WeaponSelectSkinTb"] = {
--         ["300090000"] = {
--             ["WeaponItemId"] = 300090000,
--             ["WeaponSkinId"] = 300090001
--         },
--         ["300060000"] = {
--             ["WeaponItemId"] = 300060000,
--             ["WeaponSkinId"] = 300060001
--         },
--     },
--     ["WeaponSkinPartSkinTb"] = {
--         ["300070001"] = {
--             ["PartSkinList"] = {}
--         },
--         ["300010001"] = {
--             ["PartSkinList"] = {
--                 ["601"] = {
--                     ["SkinIdList"] = {
--                         316010002
--                     }
--                 }
--             }
--         },
--     },
--     ["WeaponSkinTb"] = {
--         ["300020000"] = {
--             ["SkinIdList"] = {
--                 300020001
--             }
--         },
--         ["300060000"] = {
--             ["SkinIdList"] = {
--                 300060001,
--                 300060002
--             }
--         },
--     }
-- }

-- HeroInfoList = {
--     ["200010000"] = {
--         ["SelectSkinId"] = 200010001
--         ["SkinList"] = {
--             200010001
--         }
--     },
--     ["200020000"] = {
--         ["SelectSkinId"] = 200020001
--         ["SkinList"] = {
--             200020001
--         }
--     },
-- }
function DSServerCtrl:PlayerInfoRsp_ParseTasks(InPlayerInfoTask, OutDSPlayerInfoTask)
    if InPlayerInfoTask == nil  then
        print("DSServerCtrl", ">> PlayerInfoRsp_ParseTasks, InPlayerInfoTask == nil!!!")
        return
	end
    
    if  OutDSPlayerInfoTask == nil then
        print("DSServerCtrl", ">> PlayerInfoRsp_ParseTasks, OutDSPlayerInfoTask == nil!!!")
        return
	end

    print("DSServerCtrl", ">> PlayerInfoRsp_ParseTasks")
    
    for TaskId, TaskInfoNode in pairs(InPlayerInfoTask) do
        local UETaskInfoNode = UE.FTaskInfoNode()
        if TaskInfoNode ~= nil then
            UETaskInfoNode.FinishFlag = TaskInfoNode.FinishFlag
            for i, LuaTaskProcessNode in ipairs(TaskInfoNode.TargetProcessList) do

                local UETaskProcessNode = UE.FTaskProcessNode()
                UETaskProcessNode.EventId = LuaTaskProcessNode.EventId
                UETaskProcessNode.Progress = LuaTaskProcessNode.ProcessValue
                UETaskInfoNode.TargetProcessList:Add(UETaskProcessNode)
            end
    
        end
     
        OutDSPlayerInfoTask:Add(TaskId,UETaskInfoNode)
    end
end


function DSServerCtrl:PlayerInfoRsp_ParseHeroSkins(InRawHeroInfoList, OutHeroInfoList)
    if InRawHeroInfoList == nil or OutHeroInfoList == nil then
        print("DSServerCtrl", ">> PlayerInfoRsp_ParseWeaponSkins, In or OutHeroInfoList == nil!!!")
        return
	end
    
    print("DSServerCtrl", ">> PlayerInfoRsp_ParseHeroSkins")
    
    for HeroIDStr, HeroSkinInfo in pairs(InRawHeroInfoList) do
        local HeroID = tonumber(HeroIDStr)
        local IngameHeroSkinId = UE.FIngameHeroSkinId()
        IngameHeroSkinId.HallEquippedAvatar = HeroSkinInfo["SelectSkinId"]
        for Idx, SkinID in pairs(HeroSkinInfo["SkinList"]) do
            IngameHeroSkinId.AllHeroAvatars:Add(SkinID)
        end
        for SkinIdStr, SkinPartInfoList in pairs(HeroSkinInfo["SkinPartMap"]) do
            local SkinID      = tonumber(SkinIdStr)
            local PartSkinIDs = UE.FAvailableSkinId()
            for Idx, PartSkinId in pairs(SkinPartInfoList) do
                PartSkinIDs.AvailableSkinIds:Add(tonumber(PartSkinId))
            end
            IngameHeroSkinId.AllAvatarPartsList:Add(SkinID, PartSkinIDs)
        end
        OutHeroInfoList:Add(HeroID, IngameHeroSkinId)
    end
end

function DSServerCtrl:PlayerInfoRsp_ParseWeaponSkins(InRawWeaponSkinList, OutWeaponInfoList)
	if InRawWeaponSkinList == nil or OutWeaponInfoList == nil then
        print("DSServerCtrl", ">> PlayerInfoRsp_ParseWeaponSkins, In or OutWeaponInfoList == nil!!!")
        return
	end
    
    print("DSServerCtrl", ">> PlayerInfoRsp_ParseWeaponSkins")

    local WeaponSelectSkinTb = InRawWeaponSkinList["WeaponSelectSkinTb"]
    for WeaponID, WeaponSkins in pairs(WeaponSelectSkinTb) do
        local WeaponItemID = WeaponSkins["WeaponItemId"]
        local WeaponSkinID = WeaponSkins["WeaponSkinId"]
        OutWeaponInfoList.EquippedWeaponAvatarList:Add(WeaponItemID, WeaponSkinID)
    end

    print("DSServerCtrl", ">> parsing weaponskinpart ids")
    local WeaponSkinPartSkinTb = InRawWeaponSkinList["WeaponSkinPartSkinTb"]
    for WeaponSkinID, PartSkinList in pairs(WeaponSkinPartSkinTb) do
        local PartAvatarList = UE.FAvailableSkinId()
        for Idx, PartSkinIDStr in pairs(PartSkinList["SkinIdList"]) do
            print("DSServerCtrl", ">> --WeaponSkinPartSkinTb Add SkinId=", PartSkinIDStr)
            PartAvatarList.AvailableSkinIds:Add(tonumber(PartSkinIDStr))
        end
        OutWeaponInfoList.EquippedWeaponPartAvatarList:Add(WeaponSkinID, PartAvatarList)
    end

    local WeaponSkinTb = InRawWeaponSkinList["WeaponSkinTb"]
    for WeaponIDStr, WeaponSkins in pairs(WeaponSkinTb) do
        local WeaponItemID = tonumber(WeaponIDStr)
        local WeaponSkinIDs = UE.FAvailableSkinId()
        for Idx, SkinIdList in pairs(WeaponSkins) do
            for Idx, SkinId in pairs(SkinIdList) do
                WeaponSkinIDs.AvailableSkinIds:Add(SkinId)
            end
        end
        OutWeaponInfoList.AllWeaponAvatarList:Add(WeaponItemID, WeaponSkinIDs)
    end
end

function DSServerCtrl:PlayerInfoRsp_ParseVehicleSkins(InRawVehicleInfoList, OutVehicleInfoList)
    if InRawVehicleInfoList == nil or OutVehicleInfoList == nil then
        print("DSServerCtrl", ">> PlayerInfoRsp_ParseVehicleSkins, In or OutVehicleInfoList == nil!!!")
        return
	end
    
    print("DSServerCtrl", ">> PlayerInfoRsp_ParseVehicleSkins")
    
    for VehicleIDStr, VehicleIDInfo in pairs(InRawVehicleInfoList) do
        local VehicleID = tonumber(VehicleIDStr)
        local IngameVehicleSkinId = UE.FIngameVehicleSkinId()
        for Idx, SkinID in pairs(VehicleIDInfo["VehicleSkinItemIdList"]) do
            IngameVehicleSkinId.VehicleSkinItemIdList:Add(SkinID)
        end
        IngameVehicleSkinId.SelectSkinItemId = VehicleIDInfo["SelectSkinItemId"]
        OutVehicleInfoList:Add(VehicleID, IngameVehicleSkinId)
    end
end

-- 结算展示牌信息
-- {
--     FloorId = 210011002,
--     RoleId = 210023005,
--     EffectId = 210032003,
--     StickerMap = 
--     {
--         {
--             StickerId = 210024002,
--             XPos = -1360000,
--             YPos = 3520000,
--             Angle = 200000,
--             ScaleX = 10000,
--             ScaleY = 10000,
--         },
--         {
--             StickerId = 210034002,
--             XPos = -1720000,
--             YPos = -3040000,
--             Angle = 200000,
--             ScaleX = 5000,
--             ScaleY = 5000,
--         },
--         {
--             StickerId = 210034001,
--             XPos = 1090000,
--             YPos = 3810000,
--             Angle = 200000,
--             ScaleX = 10000,
--             ScaleY = 10000
--         },
--     },
--     AchieveMap = 
--     {
--         1,
--         2,
--         3
--     }
-- }
function DSServerCtrl:PlayerInfoRsp_ParseDisplayBoardMap(InDisplayBoardInfoMap, OutDisplayBoardInfoMap)
	if InDisplayBoardInfoMap == nil or OutDisplayBoardInfoMap == nil then
        print("DSServerCtrl", ">> PlayerInfoRsp_ParseDisplayBoardMap, In or Out DisplayBoardInfo == nil!!!")
        return
	end
    print("DSServerCtrl", ">> PlayerInfoRsp_ParseDisplayBoardMap")

    for HeroId, DisplayBoardInfo in pairs(InDisplayBoardInfoMap) do
        local HeroIdNum = tonumber(HeroId)
        local DisplayBoardInfo = UE.FDisplayBoardInfo()

        DisplayBoardInfo.FloorId = InDisplayBoardInfoMap[HeroId].FloorId
        DisplayBoardInfo.RoleId = InDisplayBoardInfoMap[HeroId].RoleId
        DisplayBoardInfo.EffectId = InDisplayBoardInfoMap[HeroId].EffectId
        
        for StickerId, StickerInfo in pairs(InDisplayBoardInfoMap[HeroId].StickerMap) do
            local StickerNodeInfo = UE.FStickerNodeInfo()
            StickerNodeInfo.StickerId = StickerInfo.StickerId
            StickerNodeInfo.XPos = StickerInfo.XPos
            StickerNodeInfo.YPos = StickerInfo.YPos
            StickerNodeInfo.Angle = StickerInfo.Angle
            StickerNodeInfo.ScaleX = StickerInfo.ScaleX
            StickerNodeInfo.ScaleY = StickerInfo.ScaleY
            DisplayBoardInfo.StickerMap:Add(StickerId, StickerNodeInfo)
        end     
        
        for AchiveId, AchiveInfo in pairs(InDisplayBoardInfoMap[HeroId].AchieveMap) do
            DisplayBoardInfo.AchieveMap:Add(AchiveId, AchiveInfo)
        end       
        for AchiveId, AchiveInfo in pairs(InDisplayBoardInfoMap[HeroId].AchieveSubMap) do
            DisplayBoardInfo.AchieveSubMap:Add(AchiveId, AchiveInfo)
        end       
        OutDisplayBoardInfoMap:Add(HeroIdNum, DisplayBoardInfo)
    end
end


function DSServerCtrl:PlayerInfoRsp_ItemInfoMap(InItemInfoMap, OutItemInfoMap)
	if InItemInfoMap == nil or OutItemInfoMap == nil then
        print("DSServerCtrl", ">> PlayerInfoRsp_ItemInfoMap, In or Out ItemInfoMap == nil!!!")
        return
	end
    print("DSServerCtrl", ">> PlayerInfoRsp_ItemInfoMap")

    for ItemInfoMapKey, ItemInfoMapValue in pairs(InItemInfoMap) do
        local ItemId = tonumber(ItemInfoMapKey)
        local ItemNum = tonumber(ItemInfoMapValue)
        OutItemInfoMap:Add(ItemId, ItemNum)
    end
end

function DSServerCtrl:SendProto_DsTaskDataNotify(MissionInfo)
    
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

    --Dump(msg, msg,5)
    self:SendProto(DSPb_Message.DsTaskDataNotify,msg)
end

-- // 大厅任务状态发生变化时，给对局的玩家同步任务状态
-- message TaskUpdateProcessNotify
-- {
--     string GameId               = 1;
--     int64 PlayerId              = 2;
--     map<int64, TaskInfoNode> TaskListMap = 3;           // 任务Id的列表
--     int64 UpdateType            = 4;                    // 1接取任务 2删除任务 3重置任务进度
-- }
function DSServerCtrl:TaskUpdateProcessNotify_Func(MissionInfo)
    
    if MissionInfo == nil then
        print("DSServerCtrl", ">> error:TaskUpdateProcessNotify_Func MissionInfo fail")
        return;
    end
    if MissionInfo.TaskListMap == nil then
        print("DSServerCtrl", ">> error:TaskUpdateProcessNotify_Func TaskIdList fail")
        return;
    end
    

    print("DSServerCtrl", ">> TaskUpdateProcessNotify_Func")
    local NewTaskIdMap = UE.TMap(0, UE.FTaskInfoNode())

    for TaskId, TaskInfoNode in pairs(MissionInfo.TaskListMap) do
        local UETaskInfoNode = UE.FTaskInfoNode()
        if TaskInfoNode ~= nil then
            UETaskInfoNode.FinishFlag = TaskInfoNode.FinishFlag
            for i, LuaTaskProcessNode in ipairs(TaskInfoNode.TargetProcessList) do

                local UETaskProcessNode = UE.FTaskProcessNode()
                UETaskProcessNode.EventId = LuaTaskProcessNode.EventId
                UETaskProcessNode.Progress = LuaTaskProcessNode.ProcessValue
                UETaskInfoNode.TargetProcessList:Add(UETaskProcessNode)
            end
    
        end
     
        NewTaskIdMap:Add(TaskId,UETaskInfoNode)
    end
    local MissionSubSystem = UE.UMissionSubSystem.Get(GameInstance)
    if MissionSubSystem ~= nil then
        print("DSServerCtrl", ">> TaskUpdateProcessNotify_Func MissionSubSystem->OnTaskUpdateProcessNotify" )
        MissionSubSystem:OnTaskUpdateProcessNotify(MissionInfo.GameId,MissionInfo.PlayerId,NewTaskIdMap,MissionInfo.UpdateType)--MissionInfo.UpdateType
    end
end


--[[
    捕捉DS即将关闭，可重复调用，但只会触发一次实际逻辑

    处理以下几种DS结束情况
    1.模式主动通知，需要关闭DS  （通过DSProtocol.NotifyDedicatedServerEnd）
    2.DSMgr管理，通知需要关闭DS  (DSPb_Message.KillDSSync 通过协议靠知)
    

    DS Crash（不处理）
]]
function DSServerCtrl:CatchDedicatedServerEnd()
    if self.IsDSServerEnd then
        return
    end
    CWaring("DSServerCtrl:CatchDedicatedServerEnd")
    self.IsDSServerEnd = true
    self:GetModel(DSServerModel):DispatchType(DSServerModel.ON_DEDICATED_SERVER_END)
end


--[[
    捕捉DS游戏玩法结束，可重复调用，但只会触发一次实际逻辑
]]
function DSServerCtrl:CatchDedicatedGameOver()
    if self.IsDSGameover then
        return
    end
    CWaring("DSServerCtrl:CatchDedicatedGameOver")
    self.IsDSGameover = true
    self:GetModel(DSServerModel):DispatchType(DSServerModel.ON_DEDICATED_GAMEOVER)
end

