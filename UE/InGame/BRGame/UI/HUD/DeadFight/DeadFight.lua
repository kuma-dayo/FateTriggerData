

local DeadFight = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function DeadFight:OnInit()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	self.GameState = UE.UGameplayStatics.GetGameState(self)
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState, Func = self.OnUpdateLocalPCPS,      bCppMsg = true, WatchedObject = self.LocalPC },
        { MsgName = GameDefine.MsgCpp.GenericStatistic_Msg_SpecificCampData, Func = self.OnSpecificCampData,  bCppMsg = true, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.GMP_Camp_ScoreChanged, Func = self.OnCampScoreChanged,  bCppMsg = true, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.GAMESTATE_GameFlowStateChange, Func = self.OnGameFlowStateChange,  bCppMsg = true, WatchedObject = nil },
	}

	UserWidget.OnInit(self)
    print("DeadFight >> OnInit")
    self.Text_Kill:SetText(0)
    self:InitData()
    
end

function DeadFight:OnDestroy()
    print("DeadFight >> OnDestroy")
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------


function DeadFight:InitData()

    print("DeadFight >> InitData")

    self.RootPtr = UE.AGUVGameState.GetGUVObjectRootPtr(self)
    local time = 0.0
    if self.RootPtr then
        time  =  self.RootPtr:GetStateTimeByName("Fighting")
    end

    if time then
        self.totalTime = time
        self.currentTime = time
        local timeFormat = self:ConvertSecondsToTimeString(self.currentTime)
        self.Text_Time:SetText(timeFormat)
    end


end


function DeadFight:OnFightTimer()
    print("DeadFight >> OnFightTimer")
    if self.totalTime then
        self.curServerTime = UE.UAdvancedWorldBussinessMarkSystem.GetTimeSeconds(self)
        if self.lastServerTime == nil then
            self.lastServerTime = self.curServerTime
        end
        if self.RootPtr then
            self.currentTime  =  self.RootPtr:GetCurStateLeftTime()
        end
        --self.currentTime = self.currentTime - (self.curServerTime - self.lastServerTime)
        self.lastServerTime = self.curServerTime


        if self.currentTime > 0 then
           local timeInt = math.floor(self.currentTime)
           local timeFormat = self:ConvertSecondsToTimeString(timeInt)
           self.Text_Time:SetText(timeFormat)
           if  timeInt > (self.TimeThreshold or 60) then
                self.Text_Time:SetColorAndOpacity(self.TimeColor_Default)
           else
                self.Text_Time:SetColorAndOpacity(self.TimeColor_Red)
           end
        end
    end
end


function DeadFight:UpdateKillAssist(PlayerId,PlayerKill,PlayerAssist,PlayerDamage)
    print("DeadFight >> UpdateKillAssist > PlayerId =",PlayerId)
    print("DeadFight >> UpdateKillAssist > PlayerKill =",PlayerKill)
    print("DeadFight >> UpdateKillAssist > PlayerAssist =",PlayerAssist)
    print("DeadFight >> UpdateKillAssist > PlayerAssist =",PlayerDamage)

    if PlayerKill then
        self.Text_Kill:SetText(PlayerKill)
    end
end


function DeadFight:OnSpecificCampData(PlayerCampData)
    print("DeadFight >> OnSpecificCampData > PlayerCampData=",PlayerCampData)
    if PlayerCampData then
        print("DeadFight >> OnSpecificCampData > PlayerCampData.Kills=",PlayerCampData.Kills)
        print("DeadFight >> OnSpecificCampData > PlayerCampData.Assists=",PlayerCampData.Assists)
        print("DeadFight >> OnSpecificCampData > PlayerCampData.Damages=",PlayerCampData.Damages)
        self:UpdateKillAssist(PlayerCampData.PlayerId,PlayerCampData.Kills,PlayerCampData.Assists,PlayerCampData.Damages)
    end
end

-- 本地更新PS/Pawn
function DeadFight:OnUpdateLocalPCPS(InLocalPC, InOldPS, InPCPS)

    if InPCPS and self.LocalPC == InLocalPC then
        self.LocalPS = InPCPS
        self.PlayerId = self.LocalPS.PlayerId;
        local CampSharedInfo =  UE.UCampExSubsystem.Get(self):GetCampPlayerDataById(self.PlayerId)
        local Rank = UE.UCampExSubsystem.Get(self):GetPlayerRankInGameById(self.PlayerId, true)
        if  Rank then
            self.Text_Ranking:SetText(Rank)
            print("nzyp " .. "Rank",Rank)
        end
        if CampSharedInfo then
            self:UpdateKillAssist(CampSharedInfo.PlayerId,CampSharedInfo.PlayerKill,CampSharedInfo.PlayerAssist,CampSharedInfo.PlayerDamage)
        end
    end
end


function DeadFight:ConvertSecondsToTimeString(seconds)
    local totalSeconds = math.floor(seconds)
    local minutes = math.floor(totalSeconds / 60)
    local secondsRemainder = totalSeconds % 60
    
    local timeString = string.format("%02d:%02d", minutes, secondsRemainder)
    return timeString
end


function DeadFight:OnCampScoreChanged(CampId,CampScore)
    local Rank = UE.UCampExSubsystem.Get(self):GetPlayerRankInGameById(self.PlayerId, true)
    if  Rank then
        self.Text_Ranking:SetText(Rank)
        print("nzyp " .. "Rank" , Rank, self.PlayerId)
    end

    local NumberOfCamps = UE.UCampExSubsystem.Get(self).CampSharedInfoLookup:Length()
    self.Text_RankingCount:SetText(NumberOfCamps)

    local CampSharedInfo =  UE.UCampExSubsystem.Get(self):GetCampPlayerDataById(self.PlayerId)
    if CampSharedInfo then
        self:UpdateKillAssist(CampSharedInfo.PlayerId,CampSharedInfo.PlayerKill,CampSharedInfo.PlayerAssist,CampSharedInfo.PlayerDamage)
    end
end



function DeadFight:OnGameFlowStateChange(PreStateName,CurStateName)
    print("DeadFight >> OnGameFlowStateChange > PreStateName=",PreStateName,",CurStateName=",CurStateName)
    if CurStateName == "Fighting" then
        --战斗开始
        self:FightStart()
    elseif CurStateName == "Settlement"then
        --结算，战斗结束
        self:FightEnd()
    end

    self:OnCampScoreChanged()
end

function DeadFight:FightStart()
    if  self.totalTime then
        self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnFightTimer}, 0.1, true, 0, 0)
    end
end

function DeadFight:FightEnd()
    if self.TimerHandle then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
   end
end

return DeadFight
