--
-- 好感度系统 - 电脑界面
--
-- @COMPANY	Saros
-- @AUTHOR	朱越
-- @DATE	2024.04.09
--

local FavorabilityComputerPanel = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------


-------------------------------------------- Init/Destroy ------------------------------------

function FavorabilityComputerPanel:OnInit()
	print("FavorabilityComputerPanel", ">> OnInit ")
	self:InitData()

	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	self.LocalPawn = UE.UPlayerStatics.GetLocalPCPawn(self.LocalPC)
	self.LocalPS = self.LocalPC.OriginalPlayerState
	self.bMissionFinished = false
	self.BindNodes = {
		{ UDelegate = self.Tab_Ordinary01.OnClicked, Func = self.OnClicked_Tab01 },
		{ UDelegate = self.Tab_Ordinary02.OnClicked, Func = self.OnClicked_Tab02 },
		{ UDelegate = self.Tab_Ordinary03.OnClicked, Func = self.OnClicked_TabTask },
		{ UDelegate = self.Button_Select01.OnClicked, Func = self.OnClicked_PasswordSelect01 },
		{ UDelegate = self.Button_Select02.OnClicked, Func = self.OnClicked_PasswordSelect02 },
		{ UDelegate = self.Button_Select03.OnClicked, Func = self.OnClicked_PasswordSelect03 },
		{ UDelegate = self.Tab_Ordinary_Big01.OnClicked, Func = self.OnClicked_Folder01 },
		{ UDelegate = self.Tab_Ordinary_Big02.OnClicked, Func = self.OnClicked_Folder02 },
		{ UDelegate = self.Tab_Task_Big.OnClicked, Func = self.OnClicked_FolderTask },
		{ UDelegate = self.WBP_ReuseList.OnUpdateItem, Func = Bind(self, self.OnReuseListUpdate)},
		{ UDelegate = self.WBP_CommonBtnTips.GUIButton_Tips.OnClicked, Func = Bind(self, self.OnButtonClicked_Back)},
	}

	UserWidget.OnInit(self)
end

function FavorabilityComputerPanel:OnShow(Param, Blackboard)
	print("FavorabilityComputerPanel >> OnShow")
	if self.LocalPC then
		self.bIsFocusable = true
		self:SetFocus(true)
		UE.UWidgetBlueprintLibrary.SetInputMode_UIOnlyEx(self.LocalPC, self, UE.EMouseLockMode.LockAlways, true)
	end

	local MissionIdSelector = UE.FGenericBlackboardKeySelector()
    MissionIdSelector.SelectedKeyName = "MissionId"
	local EventIdSelector = UE.FGenericBlackboardKeySelector()
    EventIdSelector.SelectedKeyName = "EventId"
    local MissionId, Result1 = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(Blackboard, MissionIdSelector)
    local EventId, Result2 = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(Blackboard, EventIdSelector)

	if self.LocalPS and Result1 and Result2 then
		local MissionSubSystem = UE.UMissionSubSystem.Get(GameInstance)
		if MissionSubSystem ~= nil then
			print("DSServerCtrl", ">> TaskUpdateProcessNotify_Func MissionSubSystem->OnTaskUpdateProcessNotify" )
			local MissionProgress = MissionSubSystem:GetPlayerMissionEventProgress(self.LocalPS.PlayerId, MissionId, EventId)
			if MissionProgress > 0 then
				-- 已完成
				self.bMissionFinished = true
				self.Ordinary_Text:SetVisibility(UE.ESlateVisibility.Visible)
				self.Ordinary_PassWord:SetVisibility(UE.ESlateVisibility.Collapsed)
				self.TabLogWidget.Text_Content:SetVisibility(UE.ESlateVisibility.Visible)
				self.TabLogWidget.Text_Content:SetText(self.LogTxt3)
			end
		end
	end
	
end

function FavorabilityComputerPanel:OnClose()
	print("FavorabilityComputerPanel:OnClose")
	if self.LocalPC then
		self:SetFocus(false)
		UE.UWidgetBlueprintLibrary.SetInputMode_GameOnly(self.LocalPC)
	end
end

function FavorabilityComputerPanel:OnDestroy()
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Function ------------------------------------

function FavorabilityComputerPanel:InitData(InParameters)
    self.WBP_ReuseList:Reload(1)

	local CommonTipsID = CommonConst.CT_ESC
	local CommonTipsCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_CommonBtnTipsConfig, Cfg_CommonBtnTipsConfig_P.TipsID, CommonTipsID)
	local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(CommonTipsCfg.TipsIcon)
	self.WBP_CommonBtnTips.ControlTipsIcon:SetBrushFromSoftTexture(ImageSoftObjectPtr, true)
	self.WBP_CommonBtnTips.ControlTipsTxt:SetText(G_ConfigHelper:GetStrFromCommonStaticST("102"))

	self.LogTxt1 = G_ConfigHelper:GetStrFromIngameStaticST("SD_Favorability","2906")
	self.LogTxt2 = G_ConfigHelper:GetStrFromIngameStaticST("SD_Favorability","2907")
	self.LogTxt3 = G_ConfigHelper:GetStrFromIngameStaticST("SD_Favorability","2908")
end

-------------------------------------------- Callable ------------------------------------

function FavorabilityComputerPanel:OnReuseListUpdate(_, Widget, Index)
	self.TabLogWidget = Widget;

	self.TabLogWidget.Text_Content:SetVisibility(UE.ESlateVisibility.Visible)
	self.TabLogWidget.Text_Content:SetText(self.LogTxt1)
end

function FavorabilityComputerPanel:OnClicked_Folder01()
end

function FavorabilityComputerPanel:OnClicked_Folder02()
end

function FavorabilityComputerPanel:OnClicked_FolderTask()
	self.Tab_OrdinaryBig:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.OrdinaryContentGroup:SetVisibility(UE.ESlateVisibility.Visible)
end

function FavorabilityComputerPanel:OnClicked_Tab01()
	self.Tab_OrdinaryBig:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.OrdinaryContentGroup:SetVisibility(UE.ESlateVisibility.Visible)
	self.TabLogWidget.Text_Content:SetVisibility(UE.ESlateVisibility.Visible)
	self.TabLogWidget.Text_Content:SetText(self.LogTxt1)
end

function FavorabilityComputerPanel:OnClicked_Tab02()
	self.Ordinary_Text:SetVisibility(UE.ESlateVisibility.Visible)
	self.Ordinary_PassWord:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.TabLogWidget.Text_Content:SetVisibility(UE.ESlateVisibility.Visible)
	self.TabLogWidget.Text_Content:SetText(self.LogTxt2)
end

function FavorabilityComputerPanel:OnClicked_TabTask()
	if self.bMissionFinished then
		self.Ordinary_Text:SetVisibility(UE.ESlateVisibility.Visible)
		self.Ordinary_PassWord:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.TabLogWidget.Text_Content:SetVisibility(UE.ESlateVisibility.Visible)
		self.TabLogWidget.Text_Content:SetText(self.LogTxt3)
	else
		self.Ordinary_Text:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.Ordinary_PassWord:SetVisibility(UE.ESlateVisibility.Visible)
		self.TabLogWidget.Text_Content:SetVisibility(UE.ESlateVisibility.Collapsed)
	end
end

function FavorabilityComputerPanel:OnClicked_PasswordSelect01()
	self.WidgetSwitcher_PWState:SetActiveWidgetIndex(1)
end

function FavorabilityComputerPanel:OnClicked_PasswordSelect02()
	self.WidgetSwitcher_PWState:SetActiveWidgetIndex(1)
end

function FavorabilityComputerPanel:OnClicked_PasswordSelect03()
	self.WidgetSwitcher_PWState:SetActiveWidgetIndex(0)
	MsgHelper:SendCpp(self.LocalPawn, "FavorabilitySystem.Action.Complete", self.LocalPawn)
end

function FavorabilityComputerPanel:OnButtonClicked_Back()
	UE.UGUIManager.GetUIManager(self):TryCloseDynamicWidget("UMG_FavorabilityComputer")
	MsgHelper:SendCpp(self.LocalPawn, "FavorabilitySystem.Action.Return", self.LocalPawn)
end

function FavorabilityComputerPanel:OnKeyDown(MyGeometry, InKeyEvent)
	local Key = UE.UKismetInputLibrary.GetKey(InKeyEvent)

	if Key.KeyName == "Escape" then
		self:OnButtonClicked_Back()
	end

	return UE.UWidgetBlueprintLibrary.Handled()
end

return FavorabilityComputerPanel
