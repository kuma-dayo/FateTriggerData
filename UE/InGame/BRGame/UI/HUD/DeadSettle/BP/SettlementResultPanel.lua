--
-- 战斗界面 - 结算详情界面
--
-- @COMPANY	ByteDance
-- @AUTHOR	邱天
-- @DATE	2022.011.9
--

local SettlementResultPanel = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------


-------------------------------------------- Init/Destroy ------------------------------------

function SettlementResultPanel:OnInit()
	
	-- self.BindNodes = {
	-- 	{ UDelegate = self.BtnReturnLobby.OnClicked, Func = self.OnClicked_ReturnLobby },
	-- }
	-- self.MsgList = {
	--     { MsgName = GameDefine.MsgCpp.Statistic_RepDatasPS,	Func = self.OnUpdateStatistic,	bCppMsg = true,	WatchedObject = nil },
	-- }
	
	UserWidget.OnInit(self)
	self.bPlaySound = true
end

function SettlementResultPanel:OnDestroy()
	if self.ValidWidget then
		if self.ValidWidget.AnimFinishDispatche then
			self.ValidWidget.AnimFinishDispatcher:Clear()
		end
		self.ValidWidget = nil
	end
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function SettlementResultPanel:InitData(InParameters)

	if not self.ShowAnimationTime then self.ShowAnimationTime = 3 end

	print("SettlementResultPanel >> InitData")

	local bOver = SettlementProxy:IsGameOver()
	local ResultMode = SettlementProxy:GetCurrentResultMode()
	local bReviewStart = SettlementProxy:IsReviewStart()
	local bIsTeamOver = SettlementProxy:IsTeamOver()
	print("SettlementResultPanel >> InitData > bOver =", bOver)
	print("SettlementResultPanel >> InitData > ResultMode =", ResultMode)
	print("SettlementResultPanel >> InitData > bReviewStart =", bReviewStart)
	print("SettlementResultPanel >> InitData > bIsTeamOver =", bIsTeamOver)

	local animtime = self.ShowAnimationTime
	self.ValidWidget = nil
	if ResultMode == Settlement.EResultMode.None then
	elseif ResultMode == Settlement.EResultMode.DieToOut then
		self.ValidWidget = self.BP_SettlementResultItem_Outing
	elseif ResultMode == Settlement.EResultMode.DieToLive then
	elseif ResultMode == Settlement.EResultMode.Victory then
		self.ValidWidget = self.BP_SettlementResultItem_Success
		print("SettlementResultPanel >> setanimtime = ", animtime)
	elseif ResultMode == Settlement.EResultMode.AllDead then
		self.ValidWidget = self.BP_SettlementResultItem_AllDead
	elseif ResultMode == Settlement.EResultMode.Finish then
		self.ValidWidget = self.BP_SettlementResultItem_Finish
	end

	if bReviewStart then
		if ResultMode == Settlement.EResultMode.DieToOut then
			self.ValidWidget = self.BP_SettlementResultItem_Outing
			self.ImgBg:SetVisibility(UE.ESlateVisibility.Hidden)
		else
			self.ValidWidget = self.BP_SettlementResultItem_Success
			self.ImgBg:SetVisibility(UE.ESlateVisibility.Hidden)
		end
	end

	print("SettlementResultPanel >> animtime = ", animtime)

	--是什么枚举就切换相应的动画界面
	if self.ValidWidget then
		self.WidgetSwitcher_Show:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		self.WidgetSwitcher_Show:SetActiveWidget(self.ValidWidget)
		
		if self.bPlaySound then
			local index = self.WidgetSwitcher_Show:GetActiveWidgetIndex()
			local Sound = self.ModeSoundMap:Find(index)
			if Sound then
				UE.UGTSoundStatics.PostAkEvent(self, Sound)
			end
			self.bPlaySound = false
		end
		
		--print("SettlementResultPanel:InitData",Sound,GetObjectName(self.ValidWidget),self.ValidWidget.SoundEventWhenShow)
		self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnAnimFinish}, animtime, false, 0, 0)
		
		if self.ValidWidget.AnimFinishDispatcher then
			self.ValidWidget.AnimFinishDispatcher:Add(self,self.OnAnimFinish)
		end

		print("SettlementResultPanel >> K2_SetTimerDelegate animtime = ", animtime)
	else
		self.WidgetSwitcher_Show:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.ImgBg:SetVisibility(UE.ESlateVisibility.Collapsed)
	end
end

function SettlementResultPanel:OnShow()
	local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
	if PlayerController then
		PlayerController.bShowMouseCursor = true;
		UE.UWidgetBlueprintLibrary.SetInputMode_GameAndUIEx(PlayerController,nil,0,true)
	end
	self.ImgBg:SetVisibility(UE.ESlateVisibility.Visible)
	self:InitData()
end

-------------------------------------------- Callable ------------------------------------


--动画播放完成了 执行这个回调
function SettlementResultPanel:OnAnimFinish()
	print("SettlementResultPanel >> OnAnimFinish")
	UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)

	--强行隐藏这块该死的灰色Image！
	self.ImgBg:SetVisibility(UE.ESlateVisibility.Collapsed)


	local ResultMode = SettlementProxy:GetCurrentResultMode()
	local UIManager = UE.UGUIManager.GetUIManager(self)

	print("SettlementResultPanel >> OnAnimFinish > ResultMode=", ResultMode)

	if ResultMode == Settlement.EResultMode.AllDead or ResultMode == Settlement.EResultMode.Finish or ResultMode == Settlement.EResultMode.DieToOut then
		print("SettlementResultPanel >> OnAnimFinish > ResultMode=AllDead in")
		if not SettlementProxy:IsReviewStart() then
			print("SettlementResultPanel >> OnAnimFinish > ResultMode=AllDead no reviewstart")
			UIManager:TryCloseDynamicWidget("UMG_SettlementResult")
			UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")
		else
			if ResultMode == Settlement.EResultMode.DieToOut then
				print("SettlementResultPanel >> OnAnimFinish > ResultMode == Settlement.EResultMode.DieToOut")
				UIManager:TryCloseDynamicWidget("UMG_SettlementResult")
			end
		end
	elseif ResultMode == Settlement.EResultMode.Victory then
		print("SettlementResultPanel >> OnAnimFinish > ResultMode=Victory in")

		local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
		if LocalPC then
			local LocalPS = LocalPC.OriginalPlayerState
			if LocalPS then
				local LocalPlayerId =LocalPS.PlayerId
				if LocalPlayerId then
					if not SettlementProxy:IsReviewStart() then
						print("SettlementResultPanel >> OnAnimFinish > ResultMode=Victory no reviewstart")
						UIManager:TryCloseDynamicWidget("UMG_SettlementResult")
						
						local GameMode =  SettlementProxy:GetCurrentGameMode()
						if Settlement.bLocalSettlement
								or GameMode == Settlement.EGameMode.TeamCompetition
								or GameMode == Settlement.EGameMode.Conquest then
							UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")
						else
							GameLog.Dump(Settlement.PlayerList, Settlement.PlayerList)
							for index, value in ipairs(Settlement.PlayerList) do
								if value and value.PlayerId then
									print("SettlementResultPanel >> OnAnimFinish > Victory Pairs index="..index..", value.PlayerId = "..value.PlayerId)
									if value.PlayerId == LocalPlayerId then
										if value.bIsTeamWinner == false then
											UIManager:TryLoadDynamicWidget("UMG_SettlementDetail")
										end
									end
								else
									print("SettlementResultPanel >> OnAnimFinish > Victory Pairs index="..index..", value.PlayerId = nil !")
								end
							end
						end
					end
				end
			end
		end

	else
		print("SettlementResultPanel >> OnAnimFinish > ResultMode=else in")
		if not SettlementProxy:IsReviewStart() then
			print("SettlementResultPanel >> OnAnimFinish > ResultMode=else no reviewstart")
			UIManager:TryCloseDynamicWidget("UMG_SettlementResult")
		end
	end
end


return SettlementResultPanel
