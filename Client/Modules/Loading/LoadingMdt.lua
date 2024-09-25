local class_name = "LoadingMdt"
LoadingMdt = LoadingMdt or BaseClass(GameMediator, class_name)



function LoadingMdt:__init()
end

function LoadingMdt:OnShow(InData)

end

function LoadingMdt:OnHide()
	
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
	CWaring("LoadingMdt:OnInit")
	MsgHelper:SendCpp(GameInstance, ConstUtil.MsgCpp.ASYNCLOADINGSCREEN_START)
	self.IsWorking = false

	self.InputFocus = false

	self.BindNodes = {
		{ UDelegate = self.GUIButtonQuit.OnClicked,				Func = self.OnClicked_GUIButtonQuit },
		{ UDelegate = self.GUIButtonClick.OnClicked,				Func = self.OnClicked_GUIButtonClick },
	}

	self.MsgList = 
	{
		{Model = CommonModel, MsgName = CommonModel.ON_ASYNC_LOADING_SHOW_STOP, Func = self.ON_ASYNC_LOADING_SHOW_STOP_Func },

		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Q), Func = Bind(self,self.OnQEClick,-1) },
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.E), Func = Bind(self,self.OnQEClick,1)  },
	}
	if CommonUtil.IsShipping() or not UE.UAsyncLoadingScreenLibrary.GetIsEnableLoadingDebugShow() then
        self.DebugPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        --TODO 非Shipping模式展示CL相关DEBUG信息
        self.DebugPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        local TheUserModel = MvcEntry:GetModel(UserModel)
        self.LbClientCl:SetText(TheUserModel:GetClientP4Show())
        self.LbSeverCl:SetText(TheUserModel:GetGatewayP4Show())
        self.LbDsCl:SetText(TheUserModel:GetDSP4Show())
        self.LbGameId:SetText(TheUserModel:GetDSGameIdShow())
        self.LbKeyStep:SetText("--")
		
		self.MsgList[#self.MsgList + 1] = {Model = CommonModel, MsgName = CommonModel.ON_CLIENT_HIT_KEY_STEP, Func = self.ON_CLIENT_HIT_KEY_STEP_Func }
    end
end

--[[
]]
function M:OnShow(Param)
	CWaring("LoadingMdt:OnShow")
	self.ShowTipGapTime = CommonUtil.GetParameterConfig(ParameterConfig.LoadingTipsChangeTime,2)
	self.ShowTipsList = MvcEntry:GetCtrl(LoadingCtrl):GetTipSelectList()
	self.ShowTipsIndex = 1
	self:OnTimerTipUpdateHandler()
	self:StartOrStopTipUpdateTimer(true)
    CommonUtil.SetBrushFromSoftObjectPath(self.GUIImageBg,MvcEntry:GetCtrl(LoadingCtrl):GetImgSelect())

	self.IsSlow = false
	self.ProgressValueBeginSlow = 75
	self.ProgressValueMaxTarget = 90
	self.ProgressValueMaxStatic = 101
	self.ProgressUpdateRateNormal = 2
	self.ProgressUpdateRateSlow = 0.1
	self.ProgressUpdateRateFast = 30

	self.IsWorking = true
	self.ProgressValue = 0
	self.ProgressUpdateRate = self.ProgressUpdateRateNormal
	self.ProgressValueMax = self.ProgressValueMaxTarget

	self.ProgressBar:SetPercent(self.ProgressValue)
	self.LbPercentValue:SetText("0")

	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_LOADING_FLOW_EVENTTRACKING, EventTrackingModel.OpenType.OnShow)
	self:InsertTimer(Timer.NEXT_TICK,Bind(self,self.OnTickHandler),true)
end

--[[
	重复打开此界面时，会触发此方法调用
]]
function M:OnRepeatShow(data)
	CWaring("LoadingMdt:OnRepeatShow")
	self.ShowTipsList = MvcEntry:GetCtrl(LoadingCtrl):GetTipSelectList()
	self.ShowTipsIndex = 0
	self:OnTimerTipUpdateHandler()
    CommonUtil.SetBrushFromSoftObjectPath(self.GUIImageBg,MvcEntry:GetCtrl(LoadingCtrl):GetImgSelect())

	self.ProgressValue = 0
	self.ProgressValueMax = self.ProgressValueMaxTarget
	self.ProgressUpdateRate = self.ProgressUpdateRateNormal
end

--由mdt触发调用
function M:OnHide()
end


function M:ON_CLIENT_HIT_KEY_STEP_Func(Msg)
    if not Msg then
        return
    end
    self.LbKeyStep:SetText("" .. Msg)
end

--[[
	收到通知，需要关闭Loading
	TODO 修改进度最大值，取消等待，快速进度涨至100，然后触发关闭
]]
function M:ON_ASYNC_LOADING_SHOW_STOP_Func()
	CWaring("LoadingMdt:ON_ASYNC_LOADING_SHOW_STOP_Func")
	self.ProgressValueMax = self.ProgressValueMaxStatic
	self.ProgressUpdateRate = self.ProgressUpdateRateFast
	self.IsSlow = true
end

function M:OnClicked_GUIButtonQuit()
	CWaring("LoadingMdt:OnClicked_GUIButtonQuit")
	self:DoClose()
end

--[[
	开启或者关闭Tip更新计时器
]]
function M:StartOrStopTipUpdateTimer(IsStart)
	if IsStart then
		if not self.TimerHandler then
			self.TimerHandler = self:InsertTimer(self.ShowTipGapTime,Bind(self,self.OnTimerTipUpdateHandler),true)
		end
	else
		if self.TimerHandler then
			self:RemoveTimer(self.TimerHandler)
		end
		self.TimerHandler = nil
	end
end

--[[
	定时器回调
]]
function M:OnTimerTipUpdateHandler()
	self.ShowTipsIndex = self.ShowTipsIndex + 1
	if self.ShowTipsIndex > #self.ShowTipsList then
		self.ShowTipsIndex = 1
	end
	self:UpdateTipShow()
end

function M:UpdateTipShow()
	local ShowStr = self.ShowTipsList[self.ShowTipsIndex] or "None"
	self.LbTips:SetText(ShowStr)
end


--[[
	键盘QE点击回调
]]
function M:OnQEClick(Value)
	self:StartOrStopTipUpdateTimer(false)
	self:StartOrStopTipUpdateTimer(true)

	self.ShowTipsIndex = self.ShowTipsIndex + Value
	if self.ShowTipsIndex > #self.ShowTipsList then
		self.ShowTipsIndex = 1
	elseif self.ShowTipsIndex <= 0 then
		self.ShowTipsIndex = #self.ShowTipsList
	end
	self:UpdateTipShow()
end

--[[
	点击后，触发下一条Tip展示
]]
function M:OnClicked_GUIButtonClick()
	CWaring("LoadingMdt:OnClicked_GUIButtonClick")
	self:OnQEClick(1)
end

function M:OnTickHandler(DeltaTime)
	if not self.IsWorking then
		return
	end
	local TmpProgressValue = self.ProgressValue + 0.02*self.ProgressUpdateRate
	if not self.IsSlow and TmpProgressValue >= self.ProgressValueBeginSlow then
		self.ProgressUpdateRate = self.ProgressUpdateRateSlow
		self.IsSlow = true
	end
	if TmpProgressValue >= self.ProgressValueMax then
		TmpProgressValue = self.ProgressValueMax
	end
	self.ProgressValue = TmpProgressValue
	self.ProgressBar:SetPercent(self.ProgressValue/100)
	self.LbPercentValue:SetText(math.floor(self.ProgressValue) .. "%")
	-- CWaring("LoadingMdt:ProgressValue:" .. self.ProgressValue/100 .. "|DeltaTime:" .. DeltaTime)

	if self.ProgressValue >= self.ProgressValueMaxStatic then
		self:DoClose()
	end
end

function M:DoClose()
	CWaring("LoadingMdt:DoClose")
	self.IsWorking = false
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_LOADING_FLOW_EVENTTRACKING, EventTrackingModel.OpenType.OnClose)
	MvcEntry:CloseView(self.viewId)
	MsgHelper:SendCpp(GameInstance, ConstUtil.MsgCpp.ASYNCLOADINGSCREEN_END)
end



return M