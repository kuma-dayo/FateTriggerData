
--
-- 玩家复活状态和观战状态
--
-- @COMPANY	ByteDance
-- @AUTHOR	许欣桐
-- @DATE	2023.5.15
--
require ("InGame.BRGame.ItemSystem.PickSystemHelper")
require ("InGame.BRGame.ItemSystem.RespawnSystemHelper")
local testProfile = require("Common.Utils.InsightProfile")
local OBEaster = Class("Common.Framework.UserWidget")

function OBEaster:OnInit()
    print("OBEaster:OnInit")
    --OriginalPlayerState
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.LocalPS = self.LocalPC.OriginalPlayerState
    self.ViewPS = self.LocalPC.PlayerState
    print("OBEaster:OnInit PS",GetObjectName(self.LocalPS),GetObjectName(self.ViewPS))  
    
    self:InitPCInfo()
    self:InitPlayerStateOBInfo()
    self:InitData()
    UserWidget.OnInit(self)
end

function OBEaster:OnDestroy()
    self:ClearGeneTimer()
	UserWidget.OnDestroy(self)
end


function OBEaster:InitPCInfo()
    MsgHelper:UnregisterList(self, self.MsgPCList or {})
    self.MsgPCList =
    {
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState,	Func = self.OnUpdateLocalPCPS,		bCppMsg = true, WatchedObject = self.LocalPC },
    }
    MsgHelper:RegisterList(self, self.MsgPCList)
end


function OBEaster:InitData()
    print("OBEaster:InitData")
    local IsTeamMate = self:IsViewTeamMate()
    if IsTeamMate == true then
        self.WidgetSwitcher:SetActiveWidgetIndex(0)
        self:UpdateGeneData()
    else
        self.WidgetSwitcher:SetActiveWidgetIndex(3)
    end
end
function OBEaster:InitPlayerStateOBInfo()
    MsgHelper:UnregisterList(self, self.MsgList or {})
    self.MsgList = {
        {
        MsgName = GameDefine.MsgCpp.PLAYER_PSDeadTimeSec,
        Func = self.OnChangeDeadTimeSec,
        bCppMsg = true,
        WatchedObject = self.LocalPS
        },
    {
        MsgName = GameDefine.MsgCpp.PLAYER_PSUpdateRespawnGeneState,
        Func = self.OnChangeRespawnGeneState,
        bCppMsg = true,
        WatchedObject = self.LocalPS
    }
    }
    MsgHelper:RegisterList(self, self.MsgList)
    self:UpdateGeneData()


end

function OBEaster:Tick(MyGeometry, InDeltaTime)
    --self:UpdateGeneTime(InDeltaTime)
    
end


function OBEaster:OnChangeDeadTimeSec(InPS, InDeadTimeSec)
    print("OBEaster:OnChangeDeadTimeSec", ">> OnChangeDeadTimeSec[Gene], ", GetObjectName(self.LocalPS), GetObjectName(InPS))
    if (InPS == self.LocalPS) then
        self:UpdateGeneData()
    end
end

function OBEaster:OnChangeRespawnGeneState(InPS, InState)
    print("OBEaster:OnChangeRespawnGeneState-->InPS:", InPS, "InState:", InState)
    if (InPS == self.LocalPS) then
        self:UpdateGeneData()
    end
end

function OBEaster:UpdateGeneData()
    print("OBEaster:UpdateGeneData")
    if (not UE.UKismetSystemLibrary.IsValid(self.LocalPS)) then
        print("OBEaster:UpdateGeneData self.LocalPS", self.LocalPS, GetObjectName(self.LocalPS))
        return
    end


    local gene = UE.URespawnSubsystem.Get(self):HasGeneRespawnRule()
    if not gene then
        self.WidgetSwitcher:SetActiveWidgetIndex(2)
        return
    end

    local RespawnGeneState = RespawnSystemHelper.GetRespawnGeneState(self.LocalPS)
	local DeadTime = RespawnSystemHelper.GetPlayerDeadTimeSec(self.LocalPS)
	local TotalTime = RespawnSystemHelper.GetGeneDurationTimeFromDead(self.LocalPS)

    local TimeSeconds = UE.UAdvancedWorldBussinessMarkSystem.GetTimeSeconds(self)
    local RemainTime = math.max(0, (DeadTime + TotalTime) - TimeSeconds)
    self.GeneTimeData = {
        RemainTime = RemainTime,
        TotalTime = TotalTime
    }
    if not self.GeneTimerHandle then
        self.GeneTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.UpdateGeneTime}, 1, true, 0, 0)
    end
    
    if (UE.ERespawnGeneState.Default == RespawnGeneState) then
        -- 活着,无基因
    elseif (UE.ERespawnGeneState.Drop == RespawnGeneState) then
        -- 基因未拾取
        self.WidgetSwitcher:SetActiveWidgetIndex(0)
    elseif (UE.ERespawnGeneState.PickingUp == RespawnGeneState) or (UE.ERespawnGeneState.PickingUpExtend == RespawnGeneState) then
        -- 基因提取中
        self.WidgetSwitcher:SetActiveWidgetIndex(0)
    elseif (UE.ERespawnGeneState.FinishPickedUp == RespawnGeneState) then
        -- 基因已被拾取
        self.WidgetSwitcher:SetActiveWidgetIndex(1)
    elseif (UE.ERespawnGeneState.TimeOut == RespawnGeneState) then
        -- 基因已被删除
        self.WidgetSwitcher:SetActiveWidgetIndex(2)
    elseif (UE.ERespawnGeneState.NoMoreRespawn == RespawnGeneState) then
        -- 无法继续复活
        self.WidgetSwitcher:SetActiveWidgetIndex(2)
    elseif (UE.ERespawnGeneState.UnDeployed == RespawnGeneState) then
        -- 基因未部署
        self.WidgetSwitcher:SetActiveWidgetIndex(1)
    elseif (UE.ERespawnGeneState.Deploying == RespawnGeneState) then
        -- 基因部署中
        self.WidgetSwitcher:SetActiveWidgetIndex(1)
    elseif (UE.ERespawnGeneState.FinishDeployed == RespawnGeneState) then
        -- 基因完成部署   
    end
    print("OBEaster:UpdateGeneData", self.LocalPS.PlayerId, self.LocalPS:GetPlayerName(),
    RespawnGeneState, DeadTime, TotalTime, TimeSeconds, RemainTime)
end

function OBEaster:ClearGeneTimer()
    if self.GeneTimerHandle then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.GeneTimerHandle)
        self.GeneTimerHandle = nil
   end
end

function OBEaster:UpdateGeneTime(InDeltaTime)
    if not self.GeneTimeData then
        return
    end

    -- 拿DS时间差算，第一次不记录
    self.curServerTime = UE.UAdvancedWorldBussinessMarkSystem.GetTimeSeconds(self)
	if self.lastServerTime == nil then
		self.lastServerTime = self.curServerTime
	end
    self.GeneTimeData.RemainTime = self.GeneTimeData.RemainTime - (self.curServerTime - self.lastServerTime)
    self.lastServerTime = self.curServerTime

    if self.GeneTimeData.RemainTime >= 0 then
        local NewTime = math.max(0, self.GeneTimeData.RemainTime)
        if NewTime ~= 0 then
            local NewTxtTime = string.format("%.f", NewTime)
            self.WaitTime:SetText(NewTxtTime)
        else
            self:ClearGeneTimer()
        end
    end
end

function OBEaster:IsViewTeamMate()
    
    local TeamExSubsystem = UE.UTeamExSubsystem.Get(self)
	if TeamExSubsystem then
		return TeamExSubsystem:IsTeammateByPSandPS(self.LocalPS,self.ViewPS)
	end
    return false
end

function OBEaster:OnViewTarget(OBData)
    print("OBEaster:OnViewTarget",OBData.ViewerPlayerState)
    
end

function OBEaster:OnUpdateLocalPCPS(InLocalPC, InOldPS, InNewPS)
    print("OBEaster:OnUpdateLocalPCPS",GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS))
    testProfile.Begin("OBEaster:OnUpdatePlayerState")
	if self.LocalPC == InLocalPC then
		self.ViewPS = InNewPS
        self:InitData()
	end
    testProfile.End("OBEaster:OnUpdatePlayerState")
end



return OBEaster