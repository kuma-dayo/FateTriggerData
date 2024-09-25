--
-- 战斗界面 - 结算详情界面
--
-- @COMPANY	ByteDance
-- @AUTHOR	邱天
-- @DATE	2022.011.9
--

local SettlementDetailPanel = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------


-------------------------------------------- Init/Destroy ------------------------------------

function SettlementDetailPanel:OnInit()
	print("SettlementDetailPanel", ">> OnInit ")
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

	self.BindNodes = {
		{ UDelegate = self.BtnOberserve.OnClicked, Func = self.OnClicked_BtnOberserve },
		{ UDelegate = self.BtnReturnLobby.OnClicked, Func = self.OnClicked_ReturnLobby },
		{ UDelegate = self.BtnOberserve_Moblie.OnClicked, Func = self.OnClicked_BtnOberserve },
		{ UDelegate = self.BtnReturnLobby_Moblie.OnClicked, Func = self.OnClicked_ReturnLobby },
	}
	self.MsgList = {
		{ MsgName = GameDefine.MsgCpp.Statistic_RepDatasPS,	Func = self.OnUpdateStatistic,	bCppMsg = true,	WatchedObject = nil },
		{ MsgName = GameDefine.MsgCpp.ObserveX_TryActivate,	Func = self.OnObserveXTryActivate,	bCppMsg = true,	WatchedObject = nil },
		{ MsgName = MsgDefine.SETTLEMENT_ShowObserverInfo,	Func = self.OnShowOberverInfo,	bCppMsg = false,	WatchedObject = nil },
		{ MsgName=   GameDefine.Msg.SETTLEMENT_PlayerSettlementComplate, Func = self. OnPlayerSettlementComplate,bCppMsg = false,	WatchedObject = nil },
		--{ MsgName=  GameDefine.NTag.GameState_PreGameOver, Func = self. OnClicked_ReturnLobby,bCppMsg = true,	WatchedObject = nil },
	}
	if BridgeHelper.IsMobilePlatform() then self:AddActiveWidgetStyleFlags(1) end
	UserWidget.OnInit(self)
end

function SettlementDetailPanel:OnDestroy()
	print("SettlementDetailPanel:OnDestroy >>")

	UE.UWidgetBlueprintLibrary.SetInputMode_GameOnly(self.LocalPC)
	if self.TimerHandle then
		UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
		self.TimerHandle = nil
	end
	UserWidget.OnDestroy(self)
end

function SettlementDetailPanel:OnShow()
	print("SettlementDetailPanel:OnShow")
	if self.LocalPC then
		self.bIsFocusable = true
		self:SetFocus(true)
		UE.UWidgetBlueprintLibrary.SetInputMode_UIOnlyEx(self.LocalPC,self)
	end
	
	self.CanvasPanel_TrsRankInfo:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.CanvasPanel_TrsResultInfo_Out:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.CanvasPanel_TrsResultInfo_Success:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.CanvasPanel_TrsResultInfo_Finish:SetVisibility(UE.ESlateVisibility.Collapsed)
	-- self.BtnOberserve:SetVisibility(UE.ESlateVisibility.Hidden)
	--self.ImgBg_success:SetVisibility(UE.ESlateVisibility.Collapsed)
	--self.ImgBg_out:SetVisibility(UE.ESlateVisibility.Collapsed)
	--self.HorizontalBox_PlayerList:SetVisibility(UE.ESlateVisibility.Collapsed)


	local ItemName = "BP_SettlementPlayerItem_"
	for index = 1, 4 do
		self[ItemName..index]:SetVisibility(UE.ESlateVisibility.Collapsed)
	end

	self:InitData()
end

function SettlementDetailPanel:OnClose()
	print("SettlementDetailPanel:OnClose")
	if self.LocalPC then
		self:SetFocus(false)
		UE.UWidgetBlueprintLibrary.SetInputMode_GameOnly(self.LocalPC)
	end
	
	Settlement.bForceReviewStart = true
end
-------------------------------------------- Function ------------------------------------

function SettlementDetailPanel:InitData(InParameters)
	print("SettlementDetailPanel >> InitData ")
	if Settlement.bLocalSettlement then
		SettlementProxy:InitLocalPlayerId(self)
	end

	local DelayRecycleTime = nil
	self.CurRemainTime = DelayRecycleTime or self.ReturnLobbyTime or 5

	-- 依据模式初始化结算Panel
	self:InitPanelByMode()

	self:UpdateTxtTime()
	self:UpdateObBtn()
	self:UpdateResultInfo()
end

function SettlementDetailPanel:InitPanelByMode()
	local bReviewStart = SettlementProxy:IsReviewStart()
	local GameMode =  SettlementProxy:GetCurrentGameMode()
	if bReviewStart then
		self.BtnOberserve:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.BtnOberserve_Moblie:SetVisibility(UE.ESlateVisibility.Collapsed)
	end

	-- if GameMode == Settlement.EGameMode.TeamCompetition or GameMode == Settlement.EGameMode.Conquest then
	-- 	self.BtnOberserve:SetVisibility(UE.ESlateVisibility.Collapsed)
	-- 	self.CurRemainTime = 30
	-- end
end

function SettlementDetailPanel:OnPlayerSettlementComplate()
	print("SettlementDetailPanel >> OnPlayerSettlementComplate ")
	self:UpdateResultInfo()
end

--显示结算信息ItemUI
function SettlementDetailPanel:UpdateResultInfo()

	print("SettlementDetailPanel >> UpdateResultInfo ")
	-- PlayerItem 更新
	local ItemName = "BP_SettlementPlayerItem_"
	local SortedPlayerList = SettlementProxy:GetSortedPlayer()
	if #SortedPlayerList > 0 then
		self:SetVisibility(UE.ESlateVisibility.Visible)
	end
	for index, value in ipairs(SortedPlayerList) do
		print("UpdateResultInfo init data at:",ItemName,index)
		local ItemWidget = self[ItemName..index]
		if ItemWidget then
			if #SortedPlayerList == 1 and value.PlayerId == nil then
				SettlementProxy:InitLocalPlayerId(self)
				value.PlayerId = SettlementProxy:GetLocalPlayerId()
				print("value.PlayerId = ", value.PlayerId)
			end
			ItemWidget:InitData(value)
		end
		ItemWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	end

	-- 依据模式更新数据
	self:UpdateTitleByMode()
end

function SettlementDetailPanel:UpdateTitleByMode()
	-- Title/排名更新
	local ResultMode = SettlementProxy:GetCurrentResultMode()
	local GameMode =  SettlementProxy:GetCurrentGameMode()
	local bReviewStart = SettlementProxy:IsReviewStart()
	print("SettlementDetailPanel >> UpdateResultInfo > ResultMode=",ResultMode)
	print("SettlementDetailPanel >> UpdateResultInfo > GameMode=",GameMode)
	print("SettlementDetailPanel >> UpdateResultInfo > bReviewStart=",bReviewStart)
	if bReviewStart then
		if ResultMode == Settlement.EResultMode.DieToOut then
			self.CanvasPanel_TrsResultInfo_Out:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		else
			self.CanvasPanel_TrsResultInfo_Success:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		end
	else
		if GameMode == Settlement.EGameMode.TeamCompetition or GameMode == Settlement.EGameMode.Conquest then
			if ResultMode == Settlement.EResultMode.Victory then
				self.CanvasPanel_TrsResultInfo_Success:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
				--self.ImgBg_success:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
			elseif ResultMode == Settlement.EResultMode.AllDead or ResultMode == Settlement.EResultMode.Finish then
				self.CanvasPanel_TrsResultInfo_Finish:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

				-- self.CanvasPanel_TrsRankInfo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
				-- --self.ImgBg_out:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

				-- local NumRanking = SettlementProxy:GetSettleRank()
				-- local TextStrRanking = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Settlement_Ranking")
				-- local Num = (NumRanking > 0) and string.format(TextStrRanking, math.floor(NumRanking)) or ''
				-- self.TxtRanking:SetText(Num)
				-- self.TxtRanking_4:SetText(Num)
				-- self.TxtRanking_3:SetText(Num)
			end
		elseif GameMode == Settlement.EGameMode.DeathFight then
			if ResultMode == Settlement.EResultMode.Victory then
				self.CanvasPanel_TrsResultInfo_Success:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
			else
				self.CanvasPanel_TrsRankInfo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

				local NumRanking = SettlementProxy:GetSettleRank()
				local TextStrRanking = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Settlement_Ranking")
				local Num = (NumRanking > 0) and string.format(TextStrRanking, math.floor(NumRanking)) or ''
				self.TxtRanking:SetText(Num)
				self.TxtRanking_4:SetText(Num)
				self.TxtRanking_3:SetText(Num)
			end
		else
			if ResultMode == Settlement.EResultMode.Victory then
				self.CanvasPanel_TrsResultInfo_Success:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
				--self.ImgBg_success:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
			elseif ResultMode == Settlement.EResultMode.DieToOut then
				self.CanvasPanel_TrsResultInfo_Out:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
				--self.ImgBg_out:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
			elseif ResultMode == Settlement.EResultMode.AllDead or ResultMode == Settlement.EResultMode.Finish then
				self.CanvasPanel_TrsRankInfo:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
				--self.ImgBg_out:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

				local NumRanking = SettlementProxy:GetSettleRank()
				local TextStrRanking = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Settlement_Ranking")
				local Num = (NumRanking > 0) and string.format(TextStrRanking, math.floor(NumRanking)) or ''
				self.TxtRanking:SetText(Num)
				self.TxtRanking_4:SetText(Num)
				self.TxtRanking_3:SetText(Num)
			end
		end
	end
end

-- 更新返回大厅按钮上的倒计时
function SettlementDetailPanel:UpdateTxtTime()
	print("SettlementDetailPanel >> UpdateTxtTime ")
	local ResultMode = SettlementProxy:GetCurrentResultMode()
	-- 胜利时才显示倒计时
	if SettlementProxy:IsGameOver() or SettlementProxy:IsReviewStart() then
		self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnTimer_ReturnLobbyTime}, 1.0, true, 0, 0)
		local TextStr = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Settlement_ReturnLobby")
		self.TxtCfgReturnLobby = TextStr -- or "RetureLobby(%d秒)"
		local NewTxt = string.format(self.TxtCfgReturnLobby, math.max(0, self.CurRemainTime or 0))
		self.TxtReturnLobby:SetText(NewTxt)
		self.TxtReturnLobby_Moblie:SetText(NewTxt)
	else
		local TextStr = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Settlement_RawReturnLobby")
		self.TxtCfgReturnLobby = TextStr -- or "RetureLobby"
		self.TxtReturnLobby:SetText(self.TxtCfgReturnLobby)
		self.TxtReturnLobby_Moblie:SetText(self.TxtCfgReturnLobby)
	end
end

function SettlementDetailPanel:UpdateObBtn()
	print("SettlementDetailPanel >> UpdateObBtn ")
	local bOver = SettlementProxy:IsGameOver()
	local ResultMode = SettlementProxy:GetCurrentResultMode()
	local bReviewStart = SettlementProxy:IsReviewStart()
	local bIsTeamOver = SettlementProxy:IsTeamOver()
	print("SettlementDetailPanel >> UpdateObBtn > bOver =", bOver)
	print("SettlementDetailPanel >> UpdateObBtn > ResultMode =", ResultMode)
	print("SettlementDetailPanel >> UpdateObBtn > bReviewStart =", bReviewStart)
	print("SettlementDetailPanel >> UpdateObBtn > bIsTeamOver =", bIsTeamOver)

	if bOver then
		print("SettlementDetailPanel >> BtnOberserve bOver = true ")
		self.BtnOberserve:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.BtnOberserve_Moblie:SetVisibility(UE.ESlateVisibility.Collapsed)
	else
		if not bReviewStart  then
			print("SettlementDetailPanel >> BtnOberserve - Show It!")
			self.BtnOberserve:SetVisibility(UE.ESlateVisibility.Visible)
			self.BtnOberserve_Moblie:SetVisibility(UE.ESlateVisibility.Visible)
		end
	end
	-- local  ObserverData = SettlementProxy:GetObserverData() 
	-- if ObserverData then
	-- 	self.BtnOberserve:SetVisibility(UE.ESlateVisibility.Visible)
	-- else
	-- 	self.BtnOberserve:SetVisibility(UE.ESlateVisibility.Collapsed)
	-- end
end


-------------------------------------------- Callable ------------------------------------



function SettlementDetailPanel:OnTimer_ReturnLobbyTime()
	print("SettlementDetailPanel >> OnTimer_ReturnLobbyTime ")
	if self.CurRemainTime then
		self.CurRemainTime = self.CurRemainTime - 1
		if self.CurRemainTime < 0 then
			UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
			self:OnClicked_ReturnLobby()
		end
		self:UpdateTxtTime()
	end

end

function SettlementDetailPanel:OnClicked_BtnOberserve()
	--GameFlowSystem.ExitBattle(self)
	-- local  ObserverData = SettlementProxy:GetObserverData() 
	-- if ObserverData then
	-- 	--NotifyObjectMessage(self.LocalPC, "ObserveX.System.BecomeObserver", ObserverData)
	-- 	local UIManager = UE.UGUIManager.GetUIManager(self)
	-- 	UIManager:CloseByWidget(self)
	-- end
	--MsgHelper:SendCpp(self.LocalPC, "EnhancedInput.OpenSettlementDetailPanel")
	
	if self.LocalPC then
		self.LocalPC:OpenSettlementDetailPanel()
	end
end

function SettlementDetailPanel:OnClicked_ReturnLobby()
	-- print("SettlementDetailPanel", ">> SettlementDetailPanel.ExitBattle ")
	-- MvcEntry:GetCtrl(CommonCtrl):ExitBattle(ConstUtil.ExitBattleReson.Normal)

	-- SendMsg
	if self.LocalPC then
		MsgHelper:SendCpp(self.LocalPC, "EnhancedInput.Settlement.ExitBattle")
	end
end

function SettlementDetailPanel:OnObserveXTryActivate(bTryActivateAsObserver)
	print("SettlementDetailPanel >> OnObserveXTryActivate bTryActivateAsObserver = ", bTryActivateAsObserver)
	if bTryActivateAsObserver then
		print("SettlementDetailPanel >> OnObserveXTryActivate - Show It!")
		self.BtnOberserve:SetVisibility(UE.ESlateVisibility.Visible)
		self.BtnOberserve_Moblie:SetVisibility(UE.ESlateVisibility.Visible)
	else
		print("SettlementDetailPanel >> OnObserveXTryActivate - Hide It!")
		self.BtnOberserve:SetVisibility(UE.ESlateVisibility.Hidden)
		self.BtnOberserve_Moblie:SetVisibility(UE.ESlateVisibility.Hidden)
	end
end

function SettlementDetailPanel:OnShowOberverInfo()
	print("SettlementDetailPanel >> OnShowOberverInfo")
	self:UpdateObBtn()
end

function SettlementDetailPanel:OnCloseUIActionFunction()
	self:OnClicked_ReturnLobby()
end


function SettlementDetailPanel:OnKeyDown(MyGeometry, InKeyEvent)
	local Key = UE.UKismetInputLibrary.GetKey(InKeyEvent)

	if Key.KeyName == "SpaceBar" and self.BtnOberserve:GetVisibility() == UE.ESlateVisibility.Visible then
		self:OnClicked_BtnOberserve()
	elseif Key.KeyName == "Escape" then
		self:OnClicked_ReturnLobby()
	end

	return UE.UWidgetBlueprintLibrary.Handled()
end

return SettlementDetailPanel
