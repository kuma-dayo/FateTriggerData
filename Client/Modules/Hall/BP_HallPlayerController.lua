
require "UnLua"
require("Common.Utils.CommonUtil");


local M = Class()

function M:ReceiveBeginPlay()
	self.Overridden.ReceiveBeginPlay(self)	
	-- CLog("BP_PC_OutGame:ReceiveBeginPlay()==================")
	self:DoShowMouseCursor(true)

	CommonUtil.DoMvcEntyAction(function ()
		if MvcEntry then
			self.model = MvcEntry:GetModel(CommonModel)
			if self:IsLocalController() then
				self.model:AddListener(CommonModel.ON_SHOWMOUSECURSOR,self.ON_SHOWMOUSECURSOR,self)
				self.model:AddListener(CommonModel.ON_WIDGET_TO_FOCUS,self.ON_WIDGET_TO_FOCUS,self)
				-- MsgHelper:OpDelegateList(self, self.BindNodes, true)
			end
		end
	end)

	local UIManager = UE.UGUIManager.GetUIManager(self)
	if not UIManager then
		return
	end
	UIManager:CreateDefaultCursorWidget(self)
	UIManager:SetDefaultCursorVisibility(true)
	if self:IsLocalController() and UE.UGFStatics.IsMobilePlatform() then
		UIManager:SetDefaultCursorVisibility(false)
	end
	UIManager:InitOnPCBeginPlay()
end

function M:ON_WIDGET_TO_FOCUS(ViewId)
	local mdt = MvcEntry:GetCtrl(ViewRegister):GetView(ViewId)
	local WidgetToFocus = mdt and mdt.view or nil
	if WidgetToFocus then
		CLog("ON_WIDGET_TO_FOCUS:" .. ViewId)
		--APlayerController* PlayerController, UWidget* InWidgetToFocus = nullptr, EMouseLockMode InMouseLockMode = EMouseLockMode::DoNotLock, bool bHideCursorDuringCapture = true, const bool bFlushInput = false
		UE.UWidgetBlueprintLibrary.SetInputMode_GameAndUIEx(self, WidgetToFocus, UE.EMouseLockMode.DoNotLock, false);
	end
end

function M:DoShowMouseCursor(value)
    -- CLog("BP_PC_OutGame:DoShowMouseCursor" .. UE.UGameplayStatics.GetPlatformName())
	if UE.UGameplayStatics.GetPlatformName() == "Windows" then
		local UIManager = UE.UGUIManager.GetUIManager(self)
		if not UIManager then
			return
		end
		UIManager:SetDefaultCursorVisibility(value)
	end
end

function M:ON_SHOWMOUSECURSOR(value)
	self:DoShowMouseCursor(value)
end

function M:ReceiveEndPlay(EndPlayReason)
	if self.model then
        self.model:RemoveListener(CommonModel.ON_SHOWMOUSECURSOR,self.ON_SHOWMOUSECURSOR,self)
		self.model:RemoveListener(CommonModel.ON_WIDGET_TO_FOCUS,self.ON_WIDGET_TO_FOCUS,self)
		MsgHelper:OpDelegateList(self, self.BindNodes, false)
	end
	local UIManager = UE.UGUIManager.GetUIManager(self)
	if UIManager then
		UIManager:UninitOnPCEndPlay()
	end
	-- 关闭局外手柄光标设置
	MvcEntry:GetCtrl(InputCtrl):ResetGamePadSetting(self,false)
	self.Overridden.ReceiveEndPlay(self,EndPlayReason)	
end



return M
