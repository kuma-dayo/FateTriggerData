--
-- BR_Review 选择结算界面
--
-- @COMPANY	ByteDance
-- @AUTHOR	李明空
-- @DATE	2023.07.12
--

local BRReviewSelectionPanel = Class("Common.Framework.UserWidget")

-------------------------------------------- Init/Destroy ------------------------------------

function BRReviewSelectionPanel:OnInit()
	local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
	if PlayerController then
		self.LocalPC = PlayerController
	end

	self.MsgList = {
		{ MsgName =  GameDefine.NTag.GameState_PreGameOver, Func = self.OnClicked_ExitButton, bCppMsg = true, WatchedObject = self.LocalPC },
		{ MsgName = "EnhancedInput.OpenMainMenu", Func = self.OnClicked_ExitButton,      bCppMsg = true, WatchedObject = self.LocalPC },
		{ MsgName = GameDefine.MsgCpp.PC_Input_Review_Exit,    Func = self.OnClicked_ExitButton,  bCppMsg = true, WatchedObject = self.LocalPC },
		{ MsgName = GameDefine.MsgCpp.PC_Input_Review_Continue,    Func = self.OnClicked_ContinueButton,  bCppMsg = true, WatchedObject = self.LocalPC },
	}

	self:InitData()
	UserWidget.OnInit(self)
end

function BRReviewSelectionPanel:OnShow()
	print("BRReviewSelectionPanel:OnShow")
	self.BindNodes = {
		{ UDelegate = self.ExitButton.GUIButton.OnClicked, Func = self.OnClicked_ExitButton },
		{ UDelegate = self.ContinueButton.GUIButton.OnClicked, Func = self.OnClicked_ContinueButton },
	}
	self:UpdateTimer()
end

function BRReviewSelectionPanel:OnDestroy()
	print("BRReviewSelectionPanel:OnDestroy >>")
	if self.TimerHandle then
		UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
		self.TimerHandle = nil
	end
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Function ------------------------------------

function BRReviewSelectionPanel:InitData()
	print("BRReviewSelectionPanel >> InitData ")
	if Settlement.bLocalSettlement then
		SettlementProxy:InitLocalPlayerId(self)
	end

	self.CountDownTime = 10
	self.CurRemainTime = self.CountDownTime
end

function BRReviewSelectionPanel:UpdateTimer()
	print("BRReviewSelectionPanel >> UpdateTxtTime ")
	self.TimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.OnTimerEnd}, 1.0, true, 0, 0)
	local NewTxt = string.format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_BRReviewSelectionPanel_dseconds"), math.max(0, self.CurRemainTime or 0))
	self.Text_Time:SetText(NewTxt)
end

function BRReviewSelectionPanel:OnTimerEnd()
	print("BRReviewSelectionPanel >> OnTimerEnd ")
	if self.CurRemainTime then
		self.CurRemainTime = self.CurRemainTime - 1
		if self.CurRemainTime < 0 then
			UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle)
			self:OnClicked_ContinueButton()
		end
		self:UpdateTimer()
	end
end

function BRReviewSelectionPanel:OnClicked_ExitButton()
	print(">> BRReviewSelectionPanel:OnClicked_ExitButton")
	if self.LocalPC then
		-- MsgHelper:SendCpp(nil, GameDefine.MsgCpp.GUV_BRReview_Continue)
		MsgHelper:SendCpp(self.LocalPC, GameDefine.MsgCpp.GUV_BRReview_Exit)

		local UIManager = UE.UGUIManager.GetUIManager(self)
		UIManager:CloseByWidget(self)
	end
end

function BRReviewSelectionPanel:OnClicked_ContinueButton()
	print(">> BRReviewSelectionPanel:OnClicked_ContinueButton")
	if self.LocalPC then
		-- MsgHelper:SendCpp(nil, GameDefine.MsgCpp.GUV_BRReview_Continue)
		MsgHelper:SendCpp(self.LocalPC, GameDefine.MsgCpp.GUV_BRReview_Continue)

		local UIManager = UE.UGUIManager.GetUIManager(self)
		UIManager:TryCloseDynamicWidget("UMG_BRReview_Selection")
	end
end

--function BRReviewSelectionPanel:OnKeyDown(MyGeometry, InKeyEvent)
--	local Key = UE.UKismetInputLibrary.GetKey(InKeyEvent)
--
--	if Key.KeyName == "SpaceBar" then
--		self:OnClicked_ContinueButton()
--	elseif Key.KeyName == "Escape" then
--		self:OnClicked_ExitButton()
--	end
--
--  return UE.UWidgetBlueprintLibrary.Handled()
--end

return BRReviewSelectionPanel
