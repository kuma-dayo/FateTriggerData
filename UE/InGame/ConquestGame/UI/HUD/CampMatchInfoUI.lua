--
-- 战斗界面控件 - 对局信息(击杀数/助攻数。。)
--
-- @COMPANY	ByteDance
-- @AUTHOR	qiutian
-- @DATE	2023.9.20
--

local CampMatchInfoUI = Class("Common.Framework.UserWidget")

function CampMatchInfoUI:OnInit()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	self.GameState = UE.UGameplayStatics.GetGameState(self)
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState, Func = self.OnUpdateLocalPCPS,      bCppMsg = true, WatchedObject = self.LocalPC },
        { MsgName = GameDefine.MsgCpp.GenericStatistic_Msg_SpecificCampData, Func = self.OnSpecificCampData,  bCppMsg = true, WatchedObject = nil },
        { MsgName = GameDefine.MsgCpp.GMP_Camp_ScoreChanged, Func = self.OnCampScoreChanged,  bCppMsg = true, WatchedObject = nil },
	}

	UserWidget.OnInit(self)
    print("CampMatchInfoUI >> OnInit")
    self:InitData()
    
end

function CampMatchInfoUI:OnDestroy()
    print("CampMatchInfoUI >> OnDestroy")
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Init/Destroy ------------------------------------

function CampMatchInfoUI:InitData()
    print("CampMatchInfoUI >> InitData")
    self.Text_Kill:SetText(0)
    self.Text_Assist:SetText(0)
    self.Text_Hurt:SetText(0)
end

function CampMatchInfoUI:UpdateKillAssist(PlayerId,PlayerKill,PlayerAssist,PlayerDamage)
    print("CampMatchInfoUI >> UpdateKillAssist > PlayerId =",PlayerId)
    print("CampMatchInfoUI >> UpdateKillAssist > PlayerKill =",PlayerKill)
    print("CampMatchInfoUI >> UpdateKillAssist > PlayerAssist =",PlayerAssist)
    print("CampMatchInfoUI >> UpdateKillAssist > PlayerAssist =",PlayerDamage)
    -- if PlayerId == self.PlayerId then

    -- end

    if PlayerKill then
        self.Text_Kill:SetText(PlayerKill)
    end

    if PlayerAssist then
        self.Text_Assist:SetText(PlayerAssist)
    end

    if PlayerDamage then
        local Damage = math.floor(PlayerDamage)
        self.Text_Hurt:SetText(Damage)
    end
end


function CampMatchInfoUI:OnSpecificCampData(PlayerCampData)
    print("CampMatchInfoUI >> OnSpecificCampData > PlayerCampData=",PlayerCampData)
    if PlayerCampData then
        print("CampMatchInfoUI >> OnSpecificCampData > PlayerCampData.Kills=",PlayerCampData.Kills)
        print("CampMatchInfoUI >> OnSpecificCampData > PlayerCampData.Assists=",PlayerCampData.Assists)
        print("CampMatchInfoUI >> OnSpecificCampData > PlayerCampData.Damages=",PlayerCampData.Damages)
        self:UpdateKillAssist(PlayerCampData.PlayerId,PlayerCampData.Kills,PlayerCampData.Assists,PlayerCampData.Damages)
    end
end

-- 本地更新PS/Pawn
function CampMatchInfoUI:OnUpdateLocalPCPS(InLocalPC,OldPS,NewPS)

    if self.LocalPC == InLocalPC then
        self.LocalPS = NewPS
        self.PlayerId = self.LocalPS.PlayerId;
        local CampSharedInfo =  UE.UCampExSubsystem.Get(self):GetCampPlayerDataById(self.PlayerId)
        if CampSharedInfo then
            self:UpdateKillAssist(CampSharedInfo.PlayerId,CampSharedInfo.PlayerKill,CampSharedInfo.PlayerAssist,CampSharedInfo.PlayerDamage)
        end

        self.CampId = UE.UCampExSubsystem.Get(self):GetCampIdByPlayerId(self,self.PlayerId)
    end
end


return CampMatchInfoUI
