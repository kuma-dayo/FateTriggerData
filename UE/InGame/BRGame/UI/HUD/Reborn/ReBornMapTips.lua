require ("InGame.BRGame.ItemSystem.RespawnSystemHelper")

local ReBornMapTips = Class("Common.Framework.UserWidget")

-------------------------------------------- Init/Destroy ------------------------------------
-- 复活倒计时
function ReBornMapTips:OnInit()
    print("ReBornMapTips:OnInit")
    self.TimerHandle = nil
    self.WarningTime = self.WarningTime or 10

    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.RefPS = UE.UPlayerStatics.GetCPS(self.LocalPC)

    self.WidgetSyle = {
        ["PressToReborn"] = 1, -- 选点重生
        ["WarningCloseReborn"] = 2 -- 警告即将关闭选点重生
    }

    local LocalGS = UE.UGameplayStatics.GetGameState(self)
	if LocalGS then
		self.MsgList_GS = {
			{MsgName = GameDefine.MsgCpp.UISync_Update_RuleActiveTimeSec,     Func = self.OnRuleActiveParachuteRespawn,  bCppMsg = true,  WatchedObject = LocalGS},
		 }
		MsgHelper:RegisterList(self, self.MsgList_GS)
	end
    

    if (not self.MsgList_PS) then
        self.MsgList_PS = {
            {
                MsgName = GameDefine.MsgCpp.UISync_Update_ParachuteRespawnFinished,
                Func = self.OnRuleFinishedParachuteRespawn,
                bCppMsg = true,
                WatchedObject = self.RefPS
            },
            {
                MsgName = GameDefine.MsgCpp.UISync_Update_ParachuteRespawnStart,
                Func = self.OnParachuteRespawnStart,
                bCppMsg = true,
                WatchedObject = self.RefPS
            },
            {
                MsgName = GameDefine.MsgCpp.UISync_Update_ParachuteRespawnRuleEnd,
                Func = self.OnParachuteRespawnEnd,
                bCppMsg = true,
                WatchedObject = self.RefPS
            }
        }
        MsgHelper:RegisterList(self, self.MsgList_PS)
    end

    UserWidget.OnInit(self)
end

function ReBornMapTips:OnRuleFinishedParachuteRespawn(bParachuteRespawnFinished)
    print("ReBornMapTips >> OnRuleFinishedParachuteRespawn", bParachuteRespawnFinished)
    if bParachuteRespawnFinished == true then
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
        self:ClearTimerHandle()
    end
end

function ReBornMapTips:OnRuleFinishedParachuteRespawn()
    print("ReBornMapTips >> OnRuleFinishedParachuteRespawn")

    self:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:ClearTimerHandle()
end

function ReBornMapTips:OnParachuteRespawnStart(bParachuteRespawnStart,ParachuteRespawnCDTime,AvailableChance, ActiveTime,InContext)
    print("ReBornMapTips >> OnParachuteRespawnStart", bParachuteRespawnStart)
    if bParachuteRespawnStart == true then
        self:StartToreciprocal()
    else
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
        self:ClearTimerHandle()
    end
end

function ReBornMapTips:OnDestroy()
    self:ClearTimerHandle()
    UserWidget.OnDestroy(self)
end

function ReBornMapTips:GetResPS()
    if self.RefPS then
        return self.RefPS
    end

    if not self.LocalPC then
        self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    end

    if self.LocalPC then
        self.RefPS = self.LocalPC.OriginalPlayerState
    end

    return self.RefPS
end

-- 复活还剩多少时间
function ReBornMapTips:OnRuleActiveParachuteRespawn(InRuleActiveTimeSec, InRuleTag)
    print("ReBornMapTips >> OnRuleActiveParachuteRespawn", InRuleActiveTimeSec)
    if InRuleTag and InRuleTag.TagName ~= "GameplayAbility.GMS_GS.Respawn.Rule.Parachute" then
        print("ReBornMapTips >> OnRuleActiveParachuteRespawn", InRuleTag.TagName)
        return
    end
    if InRuleActiveTimeSec > 0 then
        self:StartToreciprocal()
    end
end

--获取开始倒数
function ReBornMapTips:OnShow(InContext, InGenericBlackboard)
    local IfAlive = true

    if not self.RefPS then
        self:GetResPS()
    end

    local IfCanRespawn = UE.URespawnSubsystem.Get(self.RefPS):IsParachuteRespawnValid()
    if self.RefPS then
        IfAlive = self.RefPS:IsAlive()
    end

    if not IfAlive and IfCanRespawn then
        self:StartToreciprocal()
    else
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function ReBornMapTips:StartToreciprocal()
    if not self.RefPS then
        self:GetResPS()
    end

    if not self.RefPS then
        print("ReBornMapTips >> StartToreciprocal InRuleActiveTimeSec self.RefPS nil")
        return
    end

    local IfStartRespawn = RespawnSystemHelper.IsPlayerParachuteRespawnStart(self.RefPS)

    if not IfStartRespawn then
        print("ReBornMapTips >> IfStartRespawn is false,localps is", self.RefPS)
        return
    end

    local RuleTag = UE.FGameplayTag()
    Ruletag.TagName = "GameplayAbility.GMS_GS.Respawn.Rule.Parachute"
    local RuleActiveTime = RespawnSystemHelper.GetRuleActiveTimeSec(self, RuleTag)

    if RuleActiveTime == nil or 0 == RuleActiveTime then
        print("ReBornMapTips >> StartToreciprocal InRuleActiveTimeSec is nil")
        return
    end

    --读配置时长
    local ParachuteRespawnAvailableTime = RespawnSystemHelper.GetParachuteRespawnAvailableTime(self.RefPS)
    local NowTimeSeconds = UE.UAdvancedWorldBussinessMarkSystem.GetTimeSeconds(self)
    local RemainTime = math.max(0, (RuleActiveTime + ParachuteRespawnAvailableTime) - NowTimeSeconds)
    local DeadTime = RespawnSystemHelper.GetPlayerDeadTimeSec(self.RefPS)
    local RespawnConfigCDTime = RespawnSystemHelper.GetParachuteRespawnCDTime(self.RefPS)

    if not self.RebornTime then
        self.RebornTime = {
            RemainTime = RemainTime,
        }
    end

    -- 复活cd结束的时刻
    local RespawnCDEndTime = DeadTime + RespawnConfigCDTime
    local RespawnCD = RespawnCDEndTime - NowTimeSeconds
    -- 复活间隔cd时间大于0，且复活剩余倒计时大于复活间隔的cd时间，那么就让复活间隔cd时间过了，才可以进行选点复活


    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:ClearTimerHandle()
    self:UpdateTime()
    -- print("ReBornMapTips:StartToreciprocal RuleActiveTime ",RuleActiveTime,"ParachuteRespawnAvailableTime",ParachuteRespawnAvailableTime,"RemainTime",RemainTime,"TimeSeconds",TimeSeconds)
    if not self.TimerHandle then
        self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.UpdateTime}, 1, true, 0, 0)
    end
    

    local RespawnCountNumber = 0
    if self.RespawnCount then
        self.RespawnCount:SetText(tostring(RespawnCountNumber))
    end
end

function ReBornMapTips:UpdateTime()
    if not self.RebornTime then
        return
    end

    -- 拿DS时间差算，第一次不记录
    self.curServerTime = UE.UAdvancedWorldBussinessMarkSystem.GetTimeSeconds(self)
    if self.lastServerTime == nil then
        self.lastServerTime = self.curServerTime
    end
    self.RebornTime.RemainTime = self.RebornTime.RemainTime - (self.curServerTime - self.lastServerTime)
    local NewTime = math.max(0, self.RebornTime.RemainTime)
    local TimeMin = string.format("%.f", math.floor(NewTime / 60))
    local TimeSecond = string.format("%.f", NewTime % 60)

    if self.RebornTime.RemainTime >= 0 then
        --print("ReBornMapTips >> UpdateTime NewTime", NewTime,"TimeMin",TimeMin,"TimeSecond",TimeSecond," self.WarningTime", self.WarningTime)
        if NewTime > self.WarningTime then
            self:SetPressToRebornCountDownTime(TimeMin, TimeSecond)
            --self:SelectWigetStyle("PressToReborn")
        else
            self:SetWarningCloseRebornCountDownTime(TimeSecond)
            --self:SelectWigetStyle("WarningCloseReborn")
        end
    else
        self:ClearTimerHandle()
    end

    self.lastServerTime = self.curServerTime
end

function ReBornMapTips:SelectWigetStyle(SelectKey)
    for k, v in pairs(self.WidgetSyle) do
        if k == SelectKey then
            self:AddActiveWidgetStyleFlags(v)
        else
            self:RemoveActiveWidgetStyleFlags(v)
        end
    end
end

function ReBornMapTips:ClearRebornInfo()
    self:SelectWigetStyle("PressToReborn")
end

function ReBornMapTips:SetPressToRebornCountDownTime(TimeMin, TimeSecond)
    self.PressToRebornCountDownTime:SetText(
        StringUtil.Format(self.PressToRebornCountDownTimeRichString, TimeMin, TimeSecond)
    )
end

function ReBornMapTips:SetWarningCloseRebornCountDownTime(TimeSecond)
    self.WarningCloseRebornCountDownTime:SetText(
        StringUtil.Format(self.WarningCloseRebornCountDownTimeRichString, TimeSecond)
    )
end

function ReBornMapTips:SetRespawnCount(RespawnCountNumber)
    if self.RespawnCount then
        self.RespawnCount:SetText(StringUtil.Format(self.RespawnCountNumberRichString, RespawnCountNumber))
    end
end

function ReBornMapTips:ClearTimerHandle()
    if self.TimerHandle then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
        self.TimerHandle = nil
    end
end

return ReBornMapTips
