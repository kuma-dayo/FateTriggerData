--
-- 战斗界面控件 - 观战对局信息(剩余玩家/剩余队伍/击杀数)
--
-- @COMPANY	ByteDance
-- @AUTHOR	王泽平
-- @DATE	2023.05.18
--

local OBTeamMatchInfo = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function OBTeamMatchInfo:OnInit()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	self.GameState = UE.UGameplayStatics.GetGameState(self)
    self.MsgList = {
        --{ MsgName = GameDefine.MsgCpp.GAMESync_UpdateAlivePlayers,  Func = self.OnUpdateAlivePlayers,   bCppMsg = true, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.TeamExSystemInfo_RemainTeamNumChange, Func = self.OnUpdateTeamInfo,bCppMsg = true,WatchedObject = nil},
        { MsgName = GameDefine.MsgCpp.PlayerExSubsystemState_NumberOfPlayersChange, Func = self.OnUpdatePlayerNumber,bCppMsg = true,WatchedObject = nil},
	}

    self:InitData()
    
	UserWidget.OnInit(self)
end

function OBTeamMatchInfo:OnDestroy()
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function OBTeamMatchInfo:InitData()
        print("OBTeamMatchInfo >> InitData")

        local CurNumberOfPlayers = UE.UPlayerExSubsystem.Get(self):GetCurNumberOfPlayers()
        if CurNumberOfPlayers then
            self.TxtPlayerNum:SetText(tostring(CurNumberOfPlayers))
        end

        local NumberOfTeams = UE.UTeamExSubsystem.Get(self):GetCurNumberOfTeams()
        if NumberOfTeams then
            self.TxtTeamNum:SetText(tostring(NumberOfTeams))
        end
end

function OBTeamMatchInfo:UpdateAlivePlayers(InNum)
    if InNum then
        self.TxtTeamNum:SetText(InNum)
    elseif self.GameState.GetNumAlivePlayers then
        self.TxtTeamNum:SetText(self.GameState:GetNumAlivePlayers())
    end
end

------------------------------------ Callable ------------------------------------

function OBTeamMatchInfo:OnUpdateAlivePlayers(InGameSyncComp, InNumAlivePlayers)
    if self:GetWorld() == InGameSyncComp:GetWorld() then
        self:UpdateAlivePlayers(InNumAlivePlayers)
    end
end

function OBTeamMatchInfo:OnUpdateStatistic(InPlayerState, InStatisticComp)
    if self.LocalPC and (self.LocalPC.PlayerState == InPlayerState) then

    end
end


function OBTeamMatchInfo:OnUpdateTeamInfo(NumberOfTeams,MaxNumberOfTeams)
    print("OBTeamMatchInfo >> OnUpdateTeamInfo > teamNum=",NumberOfTeams,"  maxTeamNum=",MaxNumberOfTeams)
    if NumberOfTeams then
        self.TxtTeamNum:SetText(tostring(NumberOfTeams))
    end

end



function OBTeamMatchInfo:OnUpdatePlayerNumber(NumberOfPlayers)
    print("OBTeamMatchInfo >> OnUpdatePlayerNumber > NumberOfPlayers=",NumberOfPlayers)
    self.TxtPlayerNum:SetText(tostring(NumberOfPlayers))
end


return OBTeamMatchInfo
