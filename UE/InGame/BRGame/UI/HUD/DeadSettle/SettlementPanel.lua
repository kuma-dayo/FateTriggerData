--
-- 战斗界面 - 结算界面
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.04.15
--

local SettlementPanel = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------


-------------------------------------------- Init/Destroy ------------------------------------

function SettlementPanel:OnInit()
	self.MiscConfigTable = {
		--{ Tag = GameDefine.NStatistic.PlayerRanking,	TxtKey = "PlayerRanking" },
		{ Tag = GameDefine.NStatistic.PlayerKill,		TxtKey = "PlayerKill" },
		{ Tag = GameDefine.NStatistic.PlayerTeamKill,	TxtKey = "PlayerTeamKill" },
	}

    local TextStr = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Settlement_ReturnLobby")
    self.TxtCfgReturnLobby = TextStr or "RetureLobby(%ds)"

	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	self.LocalPC.bShowMouseCursor = true

	self.BtnReport:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.BtnDeathReplay:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.BtnExitTeam:SetVisibility(UE.ESlateVisibility.Collapsed)
	
	self.BindNodes = {
		{ UDelegate = self.BtnReturnLobby.OnClicked, Func = self.OnClicked_ReturnLobby },
	}
    self.MsgList = {
	}

	self:InitData()

	UserWidget.OnInit(self)
end

function SettlementPanel:OnDestroy()

	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function SettlementPanel:InitData(InParameters)
	local DelayRecycleTime = nil
	self.CurRemainTime = DelayRecycleTime or self.ReturnLobbyTime or 10
    self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnTimer_ReturnLobbyTime}, 1.0, true, 0, 0)
	
	self:UpdateTxtTime()
	self:UpdateResultInfo()
end

function SettlementPanel:UpdateResultInfo()
	-- 排行
	local OriginalLocalPS = self.LocalPC:GetOriginalPlayerState() --or self.LocalPC.PlayerState
	--local bIsAlive = OriginalLocalPS:IsAlive()
	local NumRanking = UE.UGenericStatics.GetRepStackCount(OriginalLocalPS, GameDefine.NStatistic.PlayerTeamRanking, 0)
    local TextStrRanking = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Settlement_Ranking")
	self.TxtRanking:SetText((NumRanking > 0) and string.format(TextStrRanking, math.floor(NumRanking)) or '')
	
	-- 详情
	local MiscConfigNum = #self.MiscConfigTable
	local MiscWidgetNum = self.TrsMiscList:GetChildrenCount()
	local MaxNum = math.max(MiscConfigNum, MiscWidgetNum)
	for i = 1, MaxNum do
		local MiscConfigData = self.MiscConfigTable[i]
		local MiscWidgetObj = self.TrsMiscList:GetChildAt(i - 1)
		if MiscConfigData and (not MiscWidgetObj) then
			MiscWidgetObj = UE.UGUIUserWidget.Create(self.LocalPC, self.ChildClass, self.LocalPC)
			if MiscWidgetObj then
				self.TrsMiscList:AddChild(MiscWidgetObj)
			end
			print("SettlementPanel", ">> UpdateResultInfo[Create], ", i, MiscConfigData, MiscWidgetObj)
		end
		if MiscWidgetObj then
			self:UpdateChildData(MiscWidgetObj, MiscConfigData)
		end
		print("SettlementPanel", ">> UpdateResultInfo, ", i, MiscConfigData, MiscWidgetObj)
	end
	
	-- 胜负
	if (NumRanking > 0) then
		local bWinGame = (NumRanking <= 1)
		local ImageIndex = bWinGame and 2 or 1
		local NewTexture = self.TextureBg:IsValidIndex(ImageIndex) and self.TextureBg:GetRef(ImageIndex) or nil
		if NewTexture then
			self.ImgResultBgM:SetBrushFromTexture(NewTexture, false)
			self.ImgResultInfoBgM:SetBrushFromTexture(NewTexture, false)
		end
		local NewTexture1 = self.TextureBgSide:IsValidIndex(ImageIndex) and self.TextureBgSide:GetRef(ImageIndex) or nil
		if NewTexture1 then
			self.ImgResultBgL:SetBrushFromTexture(NewTexture1, false)
			self.ImgResultBgR:SetBrushFromTexture(NewTexture1, false)
			self.ImgResultInfoBg:SetBrushFromTexture(NewTexture1, false)
		end
		local TxtKey = bWinGame and "GameState_GameVictory" or "GameState_GameDefeated"
		local TextStr = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, TxtKey)
		if TextStr and ('' ~= TextStr) then
			self.TxtResult:SetText(TextStr)
		end
		self.TrsRanking:SetVisibility(UE.ESlateVisibility.Visible)
	end
end

function SettlementPanel:UpdateChildData(InMiscWidgetObj, InConfigData)
	if (not InMiscWidgetObj) then return end

	if InConfigData then
		local OriginalLocalPS = self.LocalPC:GetOriginalPlayerState() --or self.LocalPC.PlayerState
		local TextStr = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, InConfigData.TxtKey)
		local SyncValue = UE.UGenericStatics.GetRepStackCount(OriginalLocalPS, InConfigData.Tag, 0)
		InMiscWidgetObj.TxtName:SetText(TextStr or '')
		InMiscWidgetObj.TxtValue:SetText(math.floor(SyncValue))
	end
    local NewVisible = InConfigData and
        UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed
	InMiscWidgetObj:SetVisibility(NewVisible)
end

--
function SettlementPanel:UpdateTxtTime()
	local NewTxt = string.format(self.TxtCfgReturnLobby, math.max(0, self.CurRemainTime))
	self.TxtReturnLobby:SetText(NewTxt)
end

-------------------------------------------- Callable ------------------------------------

-- 
function SettlementPanel:Tick(MyGeometry, InDeltaTime)
end

function SettlementPanel:OnTimer_ReturnLobbyTime()
	self.CurRemainTime = self.CurRemainTime - 1
	if self.CurRemainTime < 0 then
		UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)

		self:OnClicked_ReturnLobby()
	end
	self:UpdateTxtTime()
end

function SettlementPanel:OnClicked_ReturnLobby()
	MvcEntry:GetCtrl(CommonCtrl):ExitBattle(ConstUtil.ExitBattleReson.Normal)
end

function SettlementPanel:OnUpdateStatistic(InPlayerState, InStatisticComp)
    print("SettlementPanel", ">> OnUpdateStatistic, Start ", 
        GetObjectName(self.LocalPC.PlayerState), GetObjectName(InPlayerState), GetObjectName(InStatisticComp))

    if self.LocalPC and (self.LocalPC:IsOriginalPlayerState(InPlayerState)) then
        self:UpdateResultInfo()
    end
end

return SettlementPanel
