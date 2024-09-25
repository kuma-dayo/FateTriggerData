--
-- 战斗界面控件 - 对局信息(剩余玩家/剩余队伍/击杀数)
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.04.11
--

local TeamMatchInfo = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function TeamMatchInfo:OnInit()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.LocalPS =self.LocalPC.PlayerState
   
	self.GameState = UE.UGameplayStatics.GetGameState(self)
    self.MsgList = {
        --{ MsgName = GameDefine.MsgCpp.GAMESync_UpdateAlivePlayers,  Func = self.OnUpdateAlivePlayers,   bCppMsg = true, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.TeamExSystemInfo_RemainTeamNumChange, Func = self.OnUpdateTeamInfo,bCppMsg = true,WatchedObject = nil},
        { MsgName = GameDefine.MsgCpp.PlayerExSubsystemState_NumberOfPlayersChange, Func = self.OnUpdatePlayerNumber,bCppMsg = true,WatchedObject = nil},
        { MsgName = GameDefine.MsgCpp.UISync_Update_LocalPlayerBattleRecord, Func = self.UpdateKillNum,bCppMsg = true,WatchedObject = nil},
        
	}

    self:InitData()
    
	UserWidget.OnInit(self)
end

function TeamMatchInfo:OnDestroy()
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function TeamMatchInfo:InitData()
    print("TeamMatchInfo >> InitData")

    local NumberOfTeams = UE.UTeamExSubsystem.Get(self):GetCurNumberOfTeams()
    if NumberOfTeams then
        self.TxtTeamNum:SetText(tostring(NumberOfTeams))
    end

    local CurNumberOfPlayers = UE.UPlayerExSubsystem.Get(self):GetCurNumberOfPlayers()
    if CurNumberOfPlayers then
        self.TxtPlayerNum:SetText(tostring(CurNumberOfPlayers))
    end

    -- local CurNumberOfPlayers = UE.UPlayerExSubsystem.Get(self):GetCurNumberOfPlayers()
    
    -- local SettleMode = SettlementProxy:GetSettleMode()
    -- print("TeamMatchInfo >> InitData > SettleMode=",SettleMode)
    -- if SettleMode == 0 then
    --     --个人
    --     self.RemainPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    --     self.TxtPlayerNum:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --     if CurNumberOfPlayers then
    --         self.TxtPlayerNum:SetText(tostring(CurNumberOfPlayers))
    --     end
    -- else
    --     --队伍
    --     self.RemainPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --     self.PlayerPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    --     local NumberOfTeams = UE.UTeamExSubsystem.Get(self):GetCurNumberOfTeams()
    --     if NumberOfTeams then
    --         self.TxtTeamNum:SetText(tostring(NumberOfTeams))
    --     end
    --     if CurNumberOfPlayers then
    --         self.TxtPlayerNum:SetText(tostring(CurNumberOfPlayers))
    --     end
    -- end
    local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(self.LocalPC.OriginalPlayerState)
    if UE.UKismetSystemLibrary.IsValid(HudDataCenter) then
        print("TeamMatchInfo:InitData",HudDataCenter,GetObjectName(HudDataCenter))
        self.TxtKillNum:SetText(HudDataCenter.LocalPlayerBattleRecord.KillDeath)
    else
        self.TxtKillNum:SetText(0)
    end
   
    
end

function TeamMatchInfo:UpdateAlivePlayers(InNum)
    if InNum then
        self.TxtTeamNum:SetText(InNum)
    elseif self.GameState.GetNumAlivePlayers then
        self.TxtTeamNum:SetText(self.GameState:GetNumAlivePlayers())
    end
end





function TeamMatchInfo:UpdateKillNum(InPlayerBattleRecord)
    --[[
    if (not InNum) and self.LocalPC.PlayerState then
        InNum = math.floor(UE.UGenericStatics.GetRepStackCount(self.LocalPC.PlayerState, GameDefine.NStatistic.PlayerKill, 0))
    end
    self.TxtKillNum:SetText(InNum)]]--
    print("TeamMatchInfo:UpdateKillNum KillDeath",InPlayerBattleRecord.KillDeath,"Playerid is ",InPlayerBattleRecord.PlayerId)
    self.LocalPS = self.LocalPC.OriginalPlayerState
    if self.LocalPS.PlayerId == InPlayerBattleRecord.PlayerId then
        self.TxtKillNum:SetText(InPlayerBattleRecord.KillDeath)
    end
    

end

-------------------------------------------- Callable ------------------------------------

-- function TeamMatchInfo:OnUpdateAlivePlayers(InGameSyncComp, InNumAlivePlayers)
--     if self:GetWorld() == InGameSyncComp:GetWorld() then
--         self:UpdateAlivePlayers(InNumAlivePlayers)
--     end
-- end

function TeamMatchInfo:OnUpdateStatistic(InPlayerState, InStatisticComp)
    if self.LocalPC and (self.LocalPC.PlayerState == InPlayerState) then
        --print("TeamMatchInfo", ">> OnUpdateStatistic, ", InStatisticComp:ToString())

        --self:UpdateKillNum()
    end
end


function TeamMatchInfo:OnUpdateTeamInfo(NumberOfTeams,MaxNumberOfTeams)
    print("TeamMatchInfo >> OnUpdateTeamInfo > teamNum=",NumberOfTeams,"  maxTeamNum=",MaxNumberOfTeams)
    self.TxtTeamNum:SetText(tostring(NumberOfTeams))
end

function TeamMatchInfo:OnUpdatePlayerNumber(NumberOfPlayers)
    print("TeamMatchInfo >> OnUpdatePlayerNumber > NumberOfPlayers=",NumberOfPlayers)
    self.TxtPlayerNum:SetText(tostring(NumberOfPlayers))
end


return TeamMatchInfo
