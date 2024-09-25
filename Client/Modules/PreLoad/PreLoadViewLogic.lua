--[[
    预加载表现界面逻辑
]]
local class_name = "PreLoadViewLogic"
local PreLoadViewLogic = BaseClass(nil, class_name)


function PreLoadViewLogic:OnInit()
    self.MsgList = {
        {Model = PreLoadModel, MsgName = PreLoadModel.START_PRELOAD, Func = Bind(self,self.StartPreload) }, 
        {Model = PreLoadModel, MsgName = PreLoadModel.DO_PRELOADING, Func = Bind(self,self.UpdatePercentShow) }, 
    }
    self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function PreLoadViewLogic:OnShow()
    self.ProgressUpdateRateNormal = 20
	self.ProgressUpdateRateSlow = 5
	self.ProgressValue = 0
	self.ProgressUpdateRateFast = 100
	self.ProgressValueMaxStatic = 101
    
    local StepFinish = PreLoadModel.PRELOADING_STEP.FINISH
	self.ProgressValueMaxTarget = { 50, 90 ,[StepFinish] = self.ProgressValueMaxStatic}
    self.ProgressValueBeginSlowTarget = { 20, 90 ,[StepFinish] = self.ProgressValueMaxStatic}
end

function PreLoadViewLogic:OnHide()
end

function PreLoadViewLogic:StartPreload(_,FinishCallback)
    self.View:SetVisibility(UE.ESlateVisibility.Visible)
    self.View.ProgressBar:SetPercent(self.ProgressValue)
	self.View.LbPercentValue:SetText("0")
	self:InsertTimer(Timer.NEXT_TICK,Bind(self,self.OnTickHandler),true)
	-- 下一帧再执行开始加载，避免block住无法看到loading界面
    self:InsertTimer(0.1,function ()
        self.IsWorking = true
        MvcEntry:GetCtrl(PreLoadCtrl):PreLoadOutSideAction(FinishCallback,true)
    end)
    --修正相机位置
	local HallCameraMgr = CommonUtil.GetHallCameraMgr();
	HallCameraMgr:SwitchCamera(1, 0, "", "");
end

function PreLoadViewLogic:UpdatePercentShow(_,Step)
    local PRELOADING_STEP = PreLoadModel.PRELOADING_STEP
    if not Step or Step <= PRELOADING_STEP.NONE then
        self:DoClose()
        return
    end
	CWaring("PreLoadViewLogic:UpdatePercentShow Step = "..Step)
    self.IsSlow = false
    local NeedUpdateProgress = false
    if Step  == PRELOADING_STEP.FINISH then
        self.ProgressUpdateRate = self.ProgressUpdateRateFast
        self.ProgressValue = self.ProgressValueMaxTarget[#self.ProgressValueMaxTarget] 
        NeedUpdateProgress = true
    else
        self.ProgressUpdateRate = self.ProgressUpdateRateNormal
        if self.ProgressValueMaxTarget[Step-1] then
            self.ProgressValue = self.ProgressValueMaxTarget[Step-1] 
            NeedUpdateProgress = true
        end
    end
    if NeedUpdateProgress then
        self.View.ProgressBar:SetPercent(self.ProgressValue/100)
        self.View.LbPercentValue:SetText(math.floor(self.ProgressValue) .. "")
    end
    self.ProgressValueMax = self.ProgressValueMaxTarget[Step] 
    self.ProgressValueBeginSlow = self.ProgressValueBeginSlowTarget[Step] 
end

function PreLoadViewLogic:OnTickHandler(DeltaTime)
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
	self.View.ProgressBar:SetPercent(self.ProgressValue/100)
	self.View.LbPercentValue:SetText(math.floor(self.ProgressValue) .. "")

    if self.ProgressValue >= self.ProgressValueMaxStatic then
		self:DoClose(true)
	end
end

function PreLoadViewLogic:DoClose(IsFinish)
	CWaring("PreLoadViewLogic:DoClose")
	self.IsWorking = false
    self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
    if IsFinish then
        MvcEntry:GetModel(PreLoadModel):DispatchType(PreLoadModel.PRELOAD_VIEW_PLAY_FINISH)
    else
        MvcEntry:GetModel(PreLoadModel):DispatchType(PreLoadModel.PRELOAD_VIEW_PLAY_QUIT)
    end
end

return PreLoadViewLogic
