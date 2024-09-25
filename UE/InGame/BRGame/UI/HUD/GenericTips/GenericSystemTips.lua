--
-- 战斗界面控件 - 通用反馈提示(阶段/缩圈/毒圈提示...)
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.30
--

local GenericSystemTips = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function GenericSystemTips:OnInit()
    self.TxtTips:SetText("")
    self.TxtTime:SetText("")
    self.TrsSystemTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TrsPlayzoneTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    
    local TextStr0 = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Common_Minutes")
    local TextStr1 = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Common_Seconds")
    local TextStr3 = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "GameState_WarmingUp")
    local TextStr4 = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "GameState_InProgress")
    local TextStr5 = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "GameState_GameOver")
    local TextStr6 = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "GameState_GameVictory")
    local TextStr7 = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "GameState_GameDefeated")

    self.TxtMinutes = TextStr0 or "m"
    self.TxtSeconds = TextStr1 or "s"
    self.StateConfigs = {
        WarmingUp       = { TagName = GameDefine.NTag.GAMESTATE_WarmingUp,  Text = TextStr3 or "" },
        InProgress      = { TagName = GameDefine.NTag.GAMESTATE_InProgress, Text = TextStr4 or "" },
        GameOver        = { TagName = GameDefine.NTag.GAMESTATE_GameOver,   Text = TextStr4 or "" },
        --GameVictory   = { Text = Text = TextStr5 or "", DelayTime = 0, DisplayTime = 3},
        --GameDefeated  = { Text = Text = TextStr5 or "", DelayTime = 0, DisplayTime = 3}
    }

    local GameState = UE.UGameplayStatics.GetGameState(self)
	self.MsgList = {
		{ MsgName = GameDefine.Msg.PLAYER_InPoisonCircle,	Func = self.OnChanged_InPoisonCircle,   bCppMsg = false },
		{ MsgName = GameDefine.MsgCpp.GAMESTATE_EnterState,	Func = self.OnChanged_ModeState,        bCppMsg = true, WatchedObject = GameState.StateMachineComponent },
		{ MsgName = GameDefine.MsgCpp.RING_RunningChange,	Func = self.OnChanged_RingRunning,      bCppMsg = true, WatchedObject = nil},
		{ MsgName = GameDefine.MsgCpp.RING_StateChange,	    Func = self.OnChanged_RingState,        bCppMsg = true, WatchedObject = nil },
	}

	UserWidget.OnInit(self)
end

function GenericSystemTips:OnDestroy()

	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------

function GenericSystemTips:GetPhaseTimeConfig(InTagName)
    local InGameplayTag = UE.FGameplayTag()
    InGameplayTag.TagName = InTagName

    local GameState = UE.UGameplayStatics.GetGameState(self)
    local PhaseTime = GameState.PhaseTimeConfig:FindRef(InGameplayTag)

    if GameState.StateMachineComponent then
        local Duration = GameState.StateMachineComponent:GetStateCurrentDuration(InGameplayTag)
        return math.max(0, PhaseTime - Duration)
    end

    return PhaseTime
end

function GenericSystemTips:GetIconTexture(InTextureKey)
    local Texture = self.TextureMap:FindRef(InTextureKey)
    if (not Texture) then
        Texture = self.TextureMap:FindRef("Default")
    end
    return Texture
end

-------------------------------------------- Function ------------------------------------

function GenericSystemTips:Tick(MyGeometry, InDeltaTime)
    if (not self.CurTime) or (self.CurTime < 0) then return end
    
	--InDeltaTime = UE.UGameplayStatics.GetWorldDeltaSeconds(self)
    self.CurTime = self.CurTime - InDeltaTime
    --print("GenericSystemTips", ">> Tick, ", InDeltaTime, UE.UGameplayStatics.GetWorldDeltaSeconds(self))

    local _, _, minutes, seconds = TimeUtils.sec2Time(math.max(0, self.CurTime))
	local Minutes, Seconds = math.floor(minutes), math.floor(seconds)
    local TxtMinutes = (minutes > 0) and (Minutes.. self.TxtMinutes) or ""
    local TxtSeconds = (seconds > 0) and (Seconds.. self.TxtSeconds) or ""
    self.TxtTime:SetText(TxtMinutes.. TxtSeconds)
    
    if self.CurTime < 0 then
        self.TrsSystemTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

--[[
    InTipsInfo: { Text = xxx, Time = xxx, Texture = xxx }
]]
function GenericSystemTips:UpdateSystemTips(InTipsInfo)
    --Dump(InTipsInfo, InTipsInfo, 9)
    self.CurTime = InTipsInfo.Time

    self.TxtTips:SetText(InTipsInfo.Text)
    self.TxtTime:SetText(InTipsInfo.Time or "")
    if InTipsInfo.Texture then
        self.ImgIcon:SetBrushFromTexture(InTipsInfo.Texture, false)
    end

    self.TrsSystemTips:SetVisibility(UE.ESlateVisibility.Visible)
end

-------------------------------------------- Callable ------------------------------------

function GenericSystemTips:OnChanged_ModeState(InParams)
    local StateTagName = InParams.StateName.TagName
    print("GenericSystemTips", ">> OnChanged_ModeState, ", StateTagName)

    if StateTagName == self.StateConfigs.WarmingUp.TagName then
        self.StateData = self.StateConfigs.WarmingUp
        local InTipsInfo = {
            Text = self.StateConfigs.WarmingUp.Text,
            Time = self:GetPhaseTimeConfig(StateTagName),
        }
        self:UpdateSystemTips(InTipsInfo)
    elseif StateTagName == self.StateConfigs.InProgress.TagName then
        self.StateData = self.StateConfigs.InProgress
        
    elseif StateTagName == self.StateConfigs.GameOver.TagName then
        self.StateData = self.StateConfigs.GameOver
        --[[local InTipsInfo = {
            Text = self.StateConfigs.GameOver.Text,
            Time = 10,
        }
        self:UpdateSystemTips(InTipsInfo)]]
    end
end

function GenericSystemTips:OnChanged_RingState(InRingActor)
    if not UE.UKismetSystemLibrary.IsValid(self.RingActor) then
		self.RingActor = MinimapHelper.GetRingActor(self)
	end
	if (not UE.UKismetSystemLibrary.IsValid(self.RingActor)) or (self.RingActor:GetWorld() ~= self:GetWorld()) then return end

    
    print("GenericSystemTips", ">> OnChanged_RingState, ", self.RingActor.ClientData.CurrentKeyPoint.HoldingTime, self.RingActor.ClientData.CurrentKeyPoint.WaittingShowTipsTime,self.RingActor.ClientData.CurrentKeyPoint.ShrinkTime)
    if (self.RingActor.ClientData.CurrentIndex > 0) and (not self.RingActor:GetRunning()) then return end
    --timer的时间：HoldingTime-WaittingShowTipsTime
    self.bIsStandingBy = self.RingActor:GetState() == UE.ERingKeyState.STANDINGBY
    if (not self.bIsStandingBy) then
        return
    end

    self.TotalTime = self.bIsStandingBy and self.RingActor.ClientData.CurrentKeyPoint.WaittingShowTipsTime or self.RingActor.ClientData.CurrentKeyPoint.ShrinkTime
    --这时候show "Minimap_EnergyInStorage"
    if self.bIsStandingBy then
        if not(self.RingActor.ClientData.CurrentKeyPoint.IsNeedToShowShrinkTips) then
            return
        end
        print("GenericSystemTips", ">> OnChanged_RingState, in Minimap_EnergyInStorage")
        local TmpTime = self.RingActor.ClientData.CurrentKeyPoint.HoldingTime - self.RingActor.ClientData.CurrentKeyPoint.WaittingShowTipsTime
        self.HoldTimer = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.ShowSystemTipsUI}, TmpTime, false, 0, 0)
    else
        --这时候show "Minimap_EnergyInProliferation"
        print("GenericSystemTips", ">> OnChanged_RingState, Minimap_EnergyInProliferation")
        self:ShowSystemTipsUI()
    end
    
end

function GenericSystemTips:OnChanged_RingRunning(InRingActor, InRunning)
    self:OnChanged_RingState(nil)
end


function GenericSystemTips:ShowSystemTipsUI()
    if self.HoldTimer then
		UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.HoldTimer)
		self.HoldTimer = nil
    end
    --local bIsStandingBy = InRingActor:GetState() == UE.ERingKeyState.STANDINGBY
    local NewTxtKey = (self.bIsStandingBy and "Minimap_EnergyInStorage" or "Minimap_EnergyInProliferation")
    local NewTxtTips = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, NewTxtKey) or ""
    
    local InTipsInfo = {
        Text = NewTxtTips,
        Time = self.TotalTime,
        Texture = self:GetIconTexture("PoisonCircle"),
    }
    self:UpdateSystemTips(InTipsInfo)
end

return GenericSystemTips


