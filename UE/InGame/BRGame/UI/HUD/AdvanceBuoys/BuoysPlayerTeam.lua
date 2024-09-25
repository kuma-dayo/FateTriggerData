
local ParentClassName = "InGame.BRGame.UI.HUD.AdvanceBuoys.BuoysCommUI"
local BuoysCommUI = require(ParentClassName)
local BuoysPlayerTeam = Class(ParentClassName)
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")
require ("InGame.BRGame.ItemSystem.RespawnSystemHelper")

function BuoysPlayerTeam:OnInit()
	print("BuoysPlayerTeam >> OnInit, ", GetObjectName(self))

    self.GameTagSettings = UE.US1GameTagSettings.Get()

	self.TrsDying:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.ImgState:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.MI_TimeProgress:SetVisibility(UE.ESlateVisibility.Collapsed)

	self.bIsDying = false
	self.bBindState = false

    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	if LocalPC then
		local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(LocalPC)
		self.MsgList_Pawn =
		{
			{ MsgName = GameDefine.MsgCpp.PLAYER_OnBeginRescue, Func = self.OnBeginRescue, bCppMsg = true, WatchedObject = LocalPCPawn },
			{ MsgName = GameDefine.MsgCpp.PLAYER_OnEndRescue, Func = self.OnEndRescue, bCppMsg = true, WatchedObject = LocalPCPawn },
			{ MsgName = GameDefine.MsgCpp.PLAYER_OnRescuing, Func = self.OnRescuing, bCppMsg = true, WatchedObject = LocalPCPawn },
			{ MsgName = GameDefine.Msg.BuoysSystem_ShowBootyBox, Func = self.OnShowBootyBox, bCppMsg = false },
		}
	end

	MsgHelper:RegisterList(self, self.MsgList_Pawn)
	self:InitRangeAnimation()
	BuoysCommUI.OnInit(self)
end

function BuoysPlayerTeam:OnDestroy()
    print("BuoysPlayerTeam >> OnDestroy, ", GetObjectName(self))

    MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})
	MsgHelper:UnregisterList(self, self.PlayerTeamMsgList or {})

	if self.TimerDestroy then 
		UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerDestroy)
		self.TimerDestroy = nil
	end

    BuoysCommUI.OnDestroy(self)
end

function BuoysPlayerTeam:InitRangeAnimation()
	if self.BuoysWidgetAnimationDataMap then
		local TextDistAnim = UE.FBuoysWidgetAnimationData()
		TextDistAnim.InAnimationDelegate:Add(self, self.VXE_TeamPlayer_Distance_In)
		TextDistAnim.OutAnimationDelegate:Add(self, self.VXE_TeamPlayer_Distance_Out)
		local TextNameAnim = UE.FBuoysWidgetAnimationData()
		TextNameAnim.InAnimationDelegate:Add(self, self.VXE_TeamPlayer_Name_In)
		TextNameAnim.OutAnimationDelegate:Add(self, self.VXE_TeamPlayer_Name_Out)
		self.BuoysWidgetAnimationDataMap:Add("TextDistAnim", TextDistAnim)
		self.BuoysWidgetAnimationDataMap:Add("TextNameAnim", TextNameAnim)
	end
end

function BuoysPlayerTeam:OnBeginRescue()
    print("[HS]BuoysPlayerTeam:OnBeginRescue")

    self.MI_TimeProgress:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function BuoysPlayerTeam:OnEndRescue()
    print("[HS]BuoysPlayerTeam:OnEndRescue")

    self.MI_TimeProgress:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function BuoysPlayerTeam:OnRescuing(RescueRemainingTime, TotalRescueTime)
    print("[HS]BuoysPlayerTeam:OnRescuing. RescueRemainingTime = ", RescueRemainingTime, "; TotalRescueTime = ", TotalRescueTime)

    self.MI_TimeProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", 1 - (RescueRemainingTime / TotalRescueTime))
end

function BuoysPlayerTeam:OnShowBootyBox()
    print("[HS]BuoysPlayerTeam:OnShowBootyBox")
	self:VXE_TeamPlayer_Revive_Success()
end

-- function BuoysPlayerTeam:BPImpFunc_Update(CurRefPS)
-- 	self:UpdatePlayerInitInfo(CurRefPS)
-- 	self:UpdateGeneTime(0)
-- end


-- 已挪到cpp
-- 这里写成了一坨屎，这地方单纯擦屁股。原作者在这里写了同名函数，导致下方函数永远以不会调到，现在改个名手动再call一次 --yanzu
-- function BuoysPlayerTeam:UpdateRangeMode_Inner(InMode)
-- 	local bShowDist_Last = self.bShowDist
-- 	local bShowName_Last = self.bShowName

-- 	local bDistanceMatch = self.ToTargetDistM >= self.RangeTxtDist.X and self.ToTargetDistM <= self.RangeTxtDist.Y
	
-- 	if (InMode == self:Mark3DRangeMode("L1")) then
-- 		self.bShowDist = false
-- 		self.bShowName = true
-- 	elseif (InMode == self:Mark3DRangeMode("L2")) then
-- 		self.bShowDist = bDistanceMatch
-- 		self.bShowName = true
-- 	else--if (InMode == EBuoysRangeMode.Default) or (InMode == EBuoysRangeMode.Adsorb) then
-- 		self.bShowDist = bDistanceMatch
-- 		self.bShowName = false
-- 	end

-- 	if bShowDist_Last ~= self.bShowDist then
-- 		if self.bShowDist then
-- 			self.TxtDist:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
-- 			self:VXE_TeamPlayer_Distance_In()
-- 		else
-- 			self.TxtDist:SetVisibility(UE.ESlateVisibility.Hidden)
-- 			self:VXE_TeamPlayer_Distance_Out()
-- 		end
-- 	end
-- 	if bShowName_Last ~= self.bShowName then
-- 		if self.bShowName then
-- 			self.TxtName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
-- 			self:VXE_TeamPlayer_Name_In()
-- 		else
-- 			self.TxtName:SetVisibility(UE.ESlateVisibility.Hidden)
-- 			self:VXE_TeamPlayer_Name_Out()
-- 		end
-- 	end
-- end

function BuoysPlayerTeam:IfCanUpdateState(PawnStateName)
	-- 死亡后就不能再接受到其他状态
    if "Normal" == self.CurPawnStateName and "Normal" == PawnStateName then
		return false
	end

	if "Dead" == self.CurPawnStateName and "Dead" == PawnStateName then
		return false
	end

	if "Dying" == self.CurPawnStateName and "Dying" == PawnStateName then
		return false
	end
	 
	if "Dead" == self.CurPawnStateName and "Normal" ~= PawnStateName and "GeneRespawnUpdate" ~= PawnStateName and "Dead" ~= PawnStateName then
		print("BuoysPlayerTeam >> SetPlayerStateInfo Cannot OldPawnStateName is Dead, PawnStateName is", PawnStateName)
		return false
	end

	return true
end

function BuoysPlayerTeam:UpdateRangeMode(InMode, InWidgetScreenPos, InScreenCenterPos, bForceUpdate)	-- override

end

function BuoysPlayerTeam:CheckDyingState()
	local RefPS = self:GetInitRefPS()
	if not RefPS then return end
	local HudDataCenter = UE.UHudNetDataCenter.GetUHudNetDataCenter(RefPS)
	if not HudDataCenter then return end
	local bIsDying = HudDataCenter.DyingInfo.bIsDying
	if bIsDying then
		print("BuoysPlayerTeam>>CheckDyingState: ", self.CurTeamPos, self.LastPawnStateName)
		self:IsDying(true)
	end
end

function BuoysPlayerTeam:BindCheckState()
	local RefPS = self:GetInitRefPS()
	if not RefPS then return end

	MsgHelper:UnregisterList(self, self.PlayerTeamMsgList or {})
	self.PlayerTeamMsgList = {
		{
			MsgName = GameDefine.MsgCpp.UISync_UpdateOnBeginDying,
			Func = self.UpdateDyingInfo,
			bCppMsg = true,
			WatchedObject = RefPS
		}
	}

	MsgHelper:RegisterList(self, self.PlayerTeamMsgList)
	self.bBindState = true
end

function BuoysPlayerTeam:UpdateDyingInfo(InDyingInfo)
	if self.bIsDying ~= InDyingInfo.bIsDying then
		if InDyingInfo.bIsDying == true then
			print("BuoysPlayerTeam>>UpdateDyingInfo>>Enter bIsDying", InDyingInfo.bIsDying)
			self:IsDying(true)
		else
			print("BuoysPlayerTeam>>UpdateDyingInfo>>Exit bIsDying", InDyingInfo.bIsDying)
			self:IsDying(false)
		end
	end

	self.bIsDying = InDyingInfo.bIsDying
end

function BuoysPlayerTeam:BPImpFunc_UpdatePlayerStateInfo()
	print("BuoysPlayerTeam>>BPImpFunc_UpdatePlayerStateInfo self.CurTeamPos:", self.CurTeamPos, "self.CurPawnStateName:", self.CurPawnStateName, GetObjectName(self), self)
	if "Normal" == self.CurPawnStateName then
		self:UpdateWidgetColor()
		self:IsDriveCar(false)
		self:IsOffLine(false)
		if self.LastPawnStateName ==  "RescueStart" then
			if AdvanceMarkHelper and AdvanceMarkHelper.TeamPosColor then
				self.VX_State_Color_Team = AdvanceMarkHelper.TeamPosColor:FindRef(self.CurTeamPos)
			end
			self:VXE_TeamPlayer_Revive_Success()
			self:IsDying(false)
		elseif  self.LastPawnStateName ==  "Dying" then
			self:IsDying(false)
		end
		self:CheckDyingState()
	elseif "Dead" == self.CurPawnStateName then
		self:IsDead(true)
	elseif "Dying" == self.CurPawnStateName then
		self:IsDying(true)
	elseif "Vehicle" == self.CurPawnStateName then
		self:IsDriveCar(true)
	elseif "Fire" == self.CurPawnStateName then
		--self:UpdateWidgetFire()
	elseif "OffLine" == self.CurPawnStateName then
		self:IsOffLine(true)
	elseif "RescueStart" == self.CurPawnStateName then
		self:VXE_TeamPlayer_Revive_In()
	elseif "RescueSuccess" == self.CurPawnStateName then
		if AdvanceMarkHelper and AdvanceMarkHelper.TeamPosColor then
			self.VX_State_Color_Team = AdvanceMarkHelper.TeamPosColor:FindRef(self.CurTeamPos)
		end
		self:VXE_TeamPlayer_Revive_Success()
		self:IsDriveCar(false)
		self:IsDying(false)
	elseif "RescueStop" == self.CurPawnStateName then
		self:VXE_TeamPlayer_Revive_Out()
		
	end
	self.LastPawnStateName = self.CurPawnStateName

	if self.TxtName then self.TxtName:SetText(self.CurPlayerName) end
	if not self.bBindState then self:BindCheckState() end
end

function BuoysPlayerTeam:IsOffLine(IsOffLine)

	if IsOffLine then
		self:UpdateImgStateByKey("Offline", true)
		self.TxtNumber:SetVisibility(UE.ESlateVisibility.Collapsed)
	else
		self:UpdateImgStateByKey("Offline", false)
		self.TxtNumber:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
	end
end

function BuoysPlayerTeam:IsDriveCar(IsDrive)

	if IsDrive then
		self:UpdateImgStateByKey("Ride", true)
		self.TxtNumber:SetVisibility(UE.ESlateVisibility.Collapsed)
	else
		self:UpdateImgStateByKey("Ride", false)
		self.TxtNumber:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
	end
end

function BuoysPlayerTeam:IsDying(bIfDying)
	-- 倒地
	if bIfDying then
		if AdvanceMarkHelper and  AdvanceMarkHelper.MarkIconColor then
			local NewLinearColor = AdvanceMarkHelper.MarkIconColor:FindRef("Dying")
			self:UpdateWidgetColor(NewLinearColor)
		end
		self:VXE_TeamPlayer_Fell_In()
	else
		self:VXE_TeamPlayer_Fell_Out()
		self:UpdateWidgetColor()
	end
end

-- 死亡
function BuoysPlayerTeam:IsDead(bIfDead)
	if bIfDead then
		if AdvanceMarkHelper and AdvanceMarkHelper.MarkIconColor then
			local NewLinearColor = AdvanceMarkHelper.MarkIconColor:FindRef("Dead")
			self:UpdateWidgetColor(NewLinearColor)
		end
		self:VXE_TeamPlayer_Fell_Out()
	else
		self:UpdateWidgetColor()
	end
end


-- 更新状态图片
function BuoysPlayerTeam:UpdateImgStateByKey(InKey, bIsShow)
	local ImgStateAsset = self.ImgStateMap:FindRef(InKey)
	if not UE.UKismetSystemLibrary.IsValidSoftObjectReference(ImgStateAsset) then
		Warning("BuoysPlayerTeam >> UpdateWidgetState, UpdateImgStateByKey[ImgStateAsset is invalid!]!", InKey, ImgStateAsset)
	end
	self.ImgState:SetBrushFromSoftTexture(ImgStateAsset, false)
	self.ImgState:SetVisibility(bIsShow and UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
end

-- function BuoysPlayerTeam:UpdateWidgetColor(InLinearColor)
-- 	self.NewLinearColor = InLinearColor
--     if nil == InLinearColor then
--         if AdvanceMarkHelper and AdvanceMarkHelper.TeamPosColor then
--             self.NewLinearColor = AdvanceMarkHelper.TeamPosColor:FindRef(self.CurTeamPos)
--         end
--     end
-- 	self.VX_State_Color_Team =self.NewLinearColor
--     self.ImgBg:SetColorAndOpacity(self.NewLinearColor)
-- 	self.ImgDir:SetColorAndOpacity(self.NewLinearColor)
-- 	self.ImgState:SetColorAndOpacity(self.NewLinearColor)
-- 	if self.CurSlateColor then
-- 		self.CurSlateColor.SpecifiedColor = self.NewLinearColor
-- 		self.TxtNumber:SetColorAndOpacity(self.CurSlateColor)
-- 	else
-- 		self.TxtNumber:SetColorAndOpacity(UIHelper.ToSlateColor_LC(self.NewLinearColor))
-- 	end
-- end

-- function BuoysPlayerTeam:UpdatePlayerInitInfo(CurRefPS)
--     if nil == self.CurTeamPos or nil == CurRefPS or self.bIfInitTeamPos then
--         return
--     end
--     -- 队友低层级
--     if self.Slot then
-- 		self.bIfInitTeamPos = true
-- 		local ZOrder = self.Slot:GetZorder()
-- 		self.Slot:SetZOrder(ZOrder - self.CurTeamPos)
-- 	end
-- 	self:UpdateWidgetColor()
-- 	if self.TxtName then self.TxtName:SetText(CurRefPS:GetPlayerName() or "") end
--     self.TxtNumber:SetText(self.CurTeamPos)
-- end

-- 更新基因剩余时间
function BuoysPlayerTeam:UpdateGeneTime(InDeltaTime)
 	if -1 == self.GeneTimeData.RemainTime then
		return
	end

	local bAlive = CommonUtil.IsValid(self.RefPS) and self.RefPS:IsAlive()

	-- 拿DS时间差算，第一次不记录
	self.curServerTime = UE.UAdvancedWorldBussinessMarkSystem.GetTimeSeconds(self)
	if self.lastServerTime == nil then
		self.lastServerTime = self.curServerTime
	end
    --print("BuoysPlayerTeam:UpdateGeneTime. self.curServerTime. ", self.curServerTime, "self.lastServerTime. ", self.lastServerTime)

	self.GeneTimeData.RemainTime = self.GeneTimeData.RemainTime - (self.curServerTime - self.lastServerTime)
    self.lastServerTime = self.curServerTime

	local bRealDead = (not bAlive) and (self.GeneTimeData.RemainTime <= 0)
	--UIHelper.SetToGrey(self, bRealDead)

	if self.GeneTimeData.RemainTime >= 0 then
		local TxtSeconds = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Common_Seconds")
		local NewTxtTime = string.format("%.f", math.max(0, self.GeneTimeData.RemainTime))
        local NewProgress = self.GeneTimeData.RemainTime / self.GeneTimeData.TotalTime
		self.TxtOthers:SetText(NewTxtTime ..TxtSeconds)
		--print("BuoysTeamItem >> UpdateGeneTime, NewProgress:", NewProgress, "SetText:", NewTxtTime ..TxtSeconds)
		self.ImgGeneTime:GetDynamicMaterial():SetScalarParameterValue("Progress", NewProgress)
	else
		self:BPImpFunc_ResetGeneTimeAndUi()
	end
	--print("BuoysTeamItem >> UpdateGeneTime, ", self.GeneTimeData.RemainTime)
end

function BuoysPlayerTeam:UpdateLifeSpanTimer(bEnableTimer)
	print("BuoysPlayerTeam >> UpdateLifeSpanTimer, ", bEnableTimer, self.DelayLifeSpan)

	if self.TimerDestroy then
		UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerDestroy)
		self.TimerDestroy = nil
	end
	if bEnableTimer then
		self.TimerDestroy = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.UpdateGeneTime}, 1, true, 0, 0)
	end
end

-- 更新基因状态
function BuoysPlayerTeam:BPImpFunc_UpdateGeneData(CurRefPS, RespawnGeneState, DeadTime, TotalTime)
	if (not CurRefPS) or not RespawnGeneState or not DeadTime or not TotalTime then
		return
	end
	
	self:IsDriveCar(false)
	-- 颜色/倒计时/剩余时间
	
	-- 显示基因状态
	if (UE.ERespawnGeneState.Drop == RespawnGeneState) or (UE.ERespawnGeneState.PickingUp == RespawnGeneState) then
		-- 基因未拾取/提取中
		self:BPImpFunc_ResetGeneTimeAndUi()
		self:VXE_TeamPlayer_Fell_Out()--跟重构和策划共通过，这里需要播这个动效的逻辑，在蓝图里更改了播放的动画
		self:IsDead(false)
		self.DelayLifeSpan = TotalTime
		local bEnableTimer = self.DelayLifeSpan and (self.DelayLifeSpan > 0)
		self:UpdateLifeSpanTimer(bEnableTimer)-- and (not CurRefPS:IsAlive()))
		print("BuoysPlayerTeam >> BPImpFunc_UpdateGeneData", GetObjectName(self),"DelayLifeSpan:", self.DelayLifeSpan)
		local TimeSeconds = UE.UAdvancedWorldBussinessMarkSystem.GetTimeSeconds(self)
		local RemainTime = math.max(0, (DeadTime + TotalTime) - TimeSeconds)

		local bAlive = false --CurRefPS:IsAlive()
		local bShowGeneTime = true --(DeadTime > 0) and (TotalTime > 0) and (RemainTime > 0) and (not bAlive) 
		local NewVisible = (bShowGeneTime) and 
			UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
		self.TrsGene:SetVisibility(NewVisible)
		self.TxtOthers:SetVisibility(NewVisible)
		
		-- 显示剩余时间数据
		if bShowGeneTime then
			self.TxtOthers:SetColorAndOpacity(UIHelper.ToSlateColor_LC(self.GeneColor))
			self.GeneTimeData.RemainTime = RemainTime
			self.GeneTimeData.TotalTime = TotalTime
			self:UpdateGeneTime(0)
		else
			self.GeneTimeData = nil
			self.lastServerTime = nil
			self.TxtOthers:SetText("")
			self.ImgGeneTime:GetDynamicMaterial():SetScalarParameterValue("Progress", 1)
		end
	elseif (UE.ERespawnGeneState.FinishPickedUp == RespawnGeneState) then
		-- 基因已被拾取，停止倒计时
		self:BPImpFunc_ResetGeneTimeAndUi()
	elseif (UE.ERespawnGeneState.TimeOut == RespawnGeneState) then
		-- 基因已经超时，停止倒计时
		self:BPImpFunc_ResetGeneTimeAndUi()
		self:IsDead(true)
	elseif (UE.ERespawnGeneState.NoMoreRespawn == RespawnGeneState) then
		-- 不能继续复活了，停止倒计时
		self:BPImpFunc_ResetGeneTimeAndUi()
		self:IsDead(true)
	elseif (UE.ERespawnGeneState.UnDeployed == RespawnGeneState) then
		-- 基因部署被打断，停止倒计时
		self:BPImpFunc_ResetGeneTimeAndUi()
	elseif (UE.ERespawnGeneState.Deploying == RespawnGeneState) then
		print("BuoysPlayerTeam:BPImpFunc_UpdateGeneData-->玩家基因正在部署，销毁倒计时")
		self:BPImpFunc_ResetGeneTimeAndUi()
		--self:IsDead(false)
	elseif (UE.ERespawnGeneState.FinishDeployed == RespawnGeneState) then
		print("BuoysPlayerTeam:BPImpFunc_UpdateGeneData-->玩家基因部署成功，销毁倒计时")
		self:BPImpFunc_ResetGeneTimeAndUi()
		self:UpdateLifeSpanTimer(false)
		self:IsDead(false)
	else
		self:BPImpFunc_ResetGeneTimeAndUi()
		self:VXE_TeamPlayer_Fell_Out()
		self:IsDead(false)
	end

	-- print("BuoysPlayerTeam >> BPImpFunc_UpdateGeneData, ", GetObjectName(self),
	-- 	CurRefPS.PlayerId, CurRefPS:GetPlayerName(),
	-- 	RespawnGeneState, DeadTime, TotalTime, TimeSeconds, RemainTime, bAlive, bShowGeneTime, NewVisible)
end

function BuoysPlayerTeam:BPImpFunc_ResetGeneTimeAndUi()
    self.GeneTimeData = nil
    self.lastServerTime = nil
	self.TxtOthers:SetText("")
	self.ImgGeneTime:GetDynamicMaterial():SetScalarParameterValue("Progress", 0)
	self.TrsGene:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.TxtOthers:SetVisibility(UE.ESlateVisibility.Collapsed)
end

-- 挪到cpp
-- function BuoysPlayerTeam:BPImpFunc_OnTick3DMarkIconCustomUpdateFrom3DMark()
-- 	self:UpdateRangeMode_Inner(self.UpdateMode)
-- end


return BuoysPlayerTeam