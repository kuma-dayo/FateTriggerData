local M = Class()

function M:Construct()
    self.autoHideTimer = nil
    self.autoCircleShowTimer = nil
    self.DurationCallback = nil

    self:PlayAnimation(self.circleAnim,0,0)
end

function M:Destruct()
    self:Hide()
    NetLoading.instance = nil
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
    NetLoading.NetMsgMapStatic = {}
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
    -- NetLoading.NetMsgMapStatic = NetLoading.NetMsgMapStatic or {}
    -- for k,v in pairs(NetLoading.NetMsgMapStatic) do
    --     NetLoading.CheckTimeout(k)
    -- end
    if self.DurationCallback then
        self.DurationCallback()
    end
    self.DurationCallback = nil
    NetLoading.CheckTimeout()
    -- self:Hide();
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

return M