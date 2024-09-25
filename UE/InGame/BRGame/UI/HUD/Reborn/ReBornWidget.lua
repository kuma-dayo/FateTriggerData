require ("InGame.BRGame.ItemSystem.RespawnSystemHelper")

local ReBornWidget = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function ReBornWidget:OnInit()
    print("ReBornWidget:OnInit")
   self.TimerHandle =nil
   self.RebornTime = {}
   self:AddActiveWidgetStyleFlags(0)
   self.IsShowTips = false
    UserWidget.OnInit(self)
end

function ReBornWidget:OnDestroy()
    self:ClearTimerHandle()
	UserWidget.OnDestroy(self)
end

function ReBornWidget:OnShow()
   
    self.RichText_Time:SetText("")
   
    --self.RichText_Time:ForceLayoutPrepass()
    
 end

--获取开始倒数
function ReBornWidget:StartToreciprocal(InRuleActiveTimeSec)
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
    if InRuleActiveTimeSec == nil then
        print("ReBornWidget:StartToreciprocal InRuleActiveTimeSec is nil")
        return 
    end
    self:ClearTimerHandle()
    
   local RuleActiveTime =InRuleActiveTimeSec
    --读配置时长
    local ParachuteRespawnAvailableTime = RespawnSystemHelper.GetParachuteRespawnAvailableTime(LocalPS)
    if ParachuteRespawnAvailableTime == nil  then
        print("ReBornWidget:StartToreciprocal ParachuteRespawnAvailableTime",ParachuteRespawnAvailableTime)
        return
    end
    local TimeSeconds = UE.UAdvancedWorldBussinessMarkSystem.GetTimeSeconds(self)
    local RemainTime = math.max(0, (RuleActiveTime + ParachuteRespawnAvailableTime) - TimeSeconds)
    self.RebornTime = 
    {
        RemainTime = RemainTime
    }
    self:UpdateTime()
   print("ReBornWidget:StartToreciprocal RuleActiveTime ",RuleActiveTime,"ParachuteRespawnAvailableTime",ParachuteRespawnAvailableTime,"RemainTime",RemainTime,"TimeSeconds",TimeSeconds)
    if not self.TimerHandle then
        self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.UpdateTime}, 1, true, 0, 0)
    end

end



function ReBornWidget:UpdateTime()
    if not self.RebornTime then
        return
    end

    -- 拿DS时间差算，第一次不记录
    self.curServerTime = UE.UAdvancedWorldBussinessMarkSystem.GetTimeSeconds(self)
	if self.lastServerTime == nil then
		self.lastServerTime = self.curServerTime
	end
    self.RebornTime.RemainTime = self.RebornTime.RemainTime - (self.curServerTime - self.lastServerTime)
    self.lastServerTime = self.curServerTime

    if self.RebornTime.RemainTime >= 0 then
        
        local NewTime = math.max(0, self.RebornTime.RemainTime)
        local TimeMin = string.format("%.f", math.floor(NewTime/60))
        local TimeSecond = string.format("%.f", math.floor(NewTime%60))
        if NewTime > self.WarningTime then
            self.RichText_Time:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ReBornWidget_minutesseconds"),self.NormalColor,TimeMin,TimeSecond))
            self.RichText_Time:ForceLayoutPrepass()
            if self:HasActiveWidgetStyleFlags(1) == true then
                self:RemoveActiveWidgetStyleFlags(1)
            end
            
        else
            self.RichText_Time:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ReBornWidget_minutesseconds"),self.WarningColor,TimeMin,TimeSecond))
            self.RichText_Time:ForceLayoutPrepass()
            if self:HasActiveWidgetStyleFlags(1) == false then
                self:AddActiveWidgetStyleFlags(1)
            end

        end
        --到了showtips的时间
        
        if NewTime <= self.TipsShowTime  then
            
            local TipsManager =  UE.UTipsManager.GetTipsManager(self)
            local IsTipsIsShowing = TipsManager:IsTipsIsShowing(self.WarningTipsId)
            if IsTipsIsShowing  == false and self.IsShowTips == false then
                TipsManager:ShowTipsUIByTipsId(self.WarningTipsId,self.TipsDuration)
                TipsManager:UpdateTipsUIDataByTipsId(self.WarningTipsId,NewTime,UE.FGenericBlackboardContainer(),self)
            else
                TipsManager:UpdateTipsUIDataByTipsId(self.WarningTipsId,NewTime,UE.FGenericBlackboardContainer(),self)
            end  
            self.IsShowTips = true
        end
        
        print("ReBornWidget:UpdateTime NewTime", NewTime,"TimeMin",TimeMin,"TimeSecond",TimeSecond," self.WarningTime", self.WarningTime)
        
    else
        
        self:ClearTimerHandle()
    end
end


function ReBornWidget:ClearTimerHandle()
    if self.TimerHandle then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
        self.TimerHandle = nil
        local TipsManager = UE.UTipsManager.GetTipsManager(self)
        TipsManager:RemoveTipsUI(self.WarningTipsId)
   end
end

return ReBornWidget