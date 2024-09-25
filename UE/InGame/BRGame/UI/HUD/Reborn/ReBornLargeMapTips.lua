

local ReBornLargeMapTips = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function ReBornLargeMapTips:OnInit()
   print("ReBornLargeMapTips >> OnInit", GetObjectName(self))
   self.TimerHandle = nil
   self.WarningTime = self.WarningTime or 10

   self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
   self.RefPS = UE.UPlayerStatics.GetCPS(self.LocalPC)


    self.CountDownText = G_ConfigHelper:GetStrFromIngameStaticST("SD_ParachuteRespawn","RebornCountDown")
    UserWidget.OnInit(self)
end

function ReBornLargeMapTips:OnDestroy()
    self:ClearTimerHandle()
	UserWidget.OnDestroy(self)
end

--获取开始倒数
function ReBornLargeMapTips:OnShow(InContext, InGenericBlackboard)

end

function ReBornLargeMapTips:StartCountDown(ParachuteRemainTime, ParachuteRespawnNum, ParachuteStartTime)
    self.RebornStopTime = ParachuteStartTime + ParachuteRemainTime
    self.RebornTime = ParachuteRemainTime

    local CoundDownNumText = G_ConfigHelper:GetStrFromIngameStaticST("SD_ParachuteRespawn","RebornCountNum")

    self.Text_Num:SetText(StringUtil.FormatSimple(CoundDownNumText, ParachuteRespawnNum))
    self:ClearTimerHandle()
    self:UpdateTime()
    print("ReBornLargeMapTips >> StartCountDown ParachuteRemainTime ",ParachuteRemainTime,"ParachuteRespawnNum",ParachuteRespawnNum,"ParachuteStartTime",ParachuteStartTime)
    if not self.TimerHandle then
        self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.UpdateTime}, 1, true, 0, 0)
    end
end


function ReBornLargeMapTips:UpdateTime()

    -- 拿DS时间差算，第一次不记录
    self.curServerTime = UE.UAdvancedWorldBussinessMarkSystem.GetTimeSeconds(self)
	if self.lastServerTime == nil then
		self.lastServerTime = self.curServerTime
	end
    self.RebornTime = self.RebornTime - (self.curServerTime - self.lastServerTime)
    self.lastServerTime = self.curServerTime

    if self.RebornTime >= 0 then
        self:SetRebornCountDownTime(self.RebornTime)

    end

    if self.curServerTime > self.RebornStopTime then
        self:ClearTimerHandle()
    end
end


function ReBornLargeMapTips:SetRebornCountDownTime(TimeSecond)
    local CD = math.ceil(TimeSecond)
    self.Text_Time:SetText(StringUtil.FormatSimple(self.CountDownText, CD))
    --MsgHelper:SendCpp(self, GameDefine.Msg.AdvanceMarkSystem_Reborn_CountDown)
    UE.UGTSoundStatics.PostAkEvent(self, "AKE_Play_UI_StartGame_Countdown")
end

function ReBornLargeMapTips:ClearTimerHandle()
    if self.TimerHandle then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
        self.TimerHandle = nil
   end
   self.lastServerTime = nil
end

return ReBornLargeMapTips