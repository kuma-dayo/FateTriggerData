local M = Class()

function M:Construct()
    self.autoHideTimer = nil
    self.autoCircleShowTimer = nil
    self.DurationCallback = nil
    self.IsListenToInput = false
    self.ShieldBtn.OnClicked:Add(self,self.OnImageClicked)
    self:PlayAnimation(self.circleAnim,0,0)
end

function M:Destruct()
    self:Hide()
    self.ShieldBtn.OnClicked:Remove(self,self.OnImageClicked)
    self.IsListenToInput = false
    InputShieldLayer.Active = false
    InputShieldLayer.instance = nil
    self:Release()
end

function M:Show()
    -- CLog("UIAlert Show")
    self:SetVisibility(UE.ESlateVisibility.Visible)
end

function M:Hide()
    -- CLog("UIAlert Hide")
    self:CleanAutoHideTimer()
    self:CleanAutoCircleShowTimer()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.n_circle:SetVisibility(UE.ESlateVisibility.Collapsed)
    InputShieldLayer.Active = false
end

--[[
    转圈 超时 关闭
]]
function M:ScheduleAutoHide(duration,DurationCallback)
    self:CleanAutoHideTimer()
    self.DurationCallback = DurationCallback
    self.autoHideTimer = Timer.InsertTimer(duration,function()
        self.autoHideTimer = nil
		self:OnAutoHide()
	end)   
end

function M:OnAutoHide()
    if self.DurationCallback then
        self.DurationCallback()
    end
    self.DurationCallback = nil
    self:Hide();
end

function M:CleanAutoHideTimer()
    if self.autoHideTimer then
        Timer.RemoveTimer(self.autoHideTimer)
    end
    self.autoHideTimer = nil
    self.DurationCallback = nil
end

function M:CleanAutoCircleShowTimer()
    if self.autoCircleShowTimer then
        Timer.RemoveTimer(self.autoCircleShowTimer)
    end
    self.autoCircleShowTimer = nil
end

--[[
    转圈实际内容展示延时
]]
function M:ScheduleCicleShow(circleShowDelay)
    self:CleanAutoCircleShowTimer()
    if circleShowDelay then
        self.n_circle:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.autoCircleShowTimer = Timer.InsertTimer(circleShowDelay,function()
            self.autoCircleShowTimer = nil
            -- CLog("UIAlert n_circle show")
            self.n_circle:SetVisibility(UE.ESlateVisibility.Visible)
        end)   
    else
        self.n_circle:SetVisibility(UE.ESlateVisibility.Visible)
    end
end

--[[
    添加屏蔽层,直到有任何输入操作（键盘&鼠标），抛出事件并关闭自身
]]
function M:AddUntilReceiveInput()
    InputShieldLayer.Active = true
    self:Show()
    self.IsListenToInput = true
    -- 修改输入模式，监听任意按键输入响应
    self.bIsFocusable = true
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    UE.UWidgetBlueprintLibrary.SetInputMode_UIOnlyEx(LocalPC,self)
end


function M:OnKeyDown(MyGeometry,InKeyEvent)
    self:CheckInputListen()
    return UE.UWidgetBlueprintLibrary.Handled()
end

function M:OnImageClicked()
    CWaring("InputShieldLayer Shield Click")
    self:CheckInputListen()
end

function M:CheckInputListen()
    if not self.IsListenToInput then
        return
    end
    self.bIsFocusable = false
    self.IsListenToInput = false
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    local LastFocusView = MvcEntry:GetModel(ViewModel):GetOpenLastViewWithInputFocus()
    local LastFocusWidget = nil
    if LastFocusView then
        LastFocusWidget = MvcEntry:GetCtrl(ViewRegister):GetView(LastFocusView.viewId)
    end
    UE.UWidgetBlueprintLibrary.SetInputMode_GameAndUIEx(LocalPC,LastFocusWidget, UE.EMouseLockMode.DoNotLock, false)
    self:Hide()
    MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_INPUT_SHIELD_LAYER_HIDE_AFTER_INPUT)
end

return M