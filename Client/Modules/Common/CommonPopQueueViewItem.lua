local M = Class()

---@class QueueViewItemData
---@field Icon string 图标路径
---@field IconBg string 图标背景
---@field Bg string 背景图
---@field Tittle string 标题
---@field Desc string 描述
---@field SubDesc string 子标题
---@field SubDescHex string 子标题字色
M.Data = nil
M.UUID = -1

function M:Construct()
    self.AutoHideTimer = nil
    self.DurationCallback = nil
    self.UUID = -1
end

function M:Destruct()
    self:Hide()
    self:Release()
end

function M:Show(Data, Duration, DurationCallback)
    CLog("==============CommonPopQueueViewItem Show" .. self.UUID)
    self.Data = Data
    self:SetVisibility(UE.ESlateVisibility.Visible)
    self:UpdateShow()
    self:ScheduleAutoHide(Duration,DurationCallback)
end

function M:UpdateShow()
    if self.Data.Tittle then
        self.Tittle:SetText(self.Data.Tittle)
    end
    if self.Data.Desc then
        self.Desc:SetText(self.Data.Desc)
    end
    if self.Data.SubDesc then
        self.SubDesc:SetText(self.Data.SubDesc)
    end
    CommonUtil.SetBrushFromSoftObjectPath(self.Bg,self.Data.Bg)
    CommonUtil.SetBrushFromSoftObjectPath(self.IconBg,self.Data.IconBg)
    CommonUtil.SetBrushFromSoftObjectPath(self.Icon,self.Data.Icon)
    if self.Data.SubDescHex then
        CommonUtil.SetTextColorFromeHex(self.SubDesc, self.Data.SubDescHex)
    end
end

function M:Hide()
    CLog("==============CommonPopQueueViewItem Hide" .. self.UUID)
    self.Data = nil
    self:CleanAutoHideTimer()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function M:ScheduleAutoHide(Duration,DurationCallback)
    self:CleanAutoHideTimer()
    self.DurationCallback = DurationCallback
    CLog("==============CommonPopQueueViewItem InsertTimer" .. self.UUID)
    self.AutoHideTimer = Timer.InsertTimer(Duration,function()
        CLog("==============CommonPopQueueViewItem OnAutoHide" .. self.UUID)
        self.AutoHideTimer = nil
		self:OnAutoHide()
	end)   
end

function M:OnAutoHide()
    if self.DurationCallback then
        self.DurationCallback(self.UUID)
    end
end

function M:CleanAutoHideTimer()
    if self.AutoHideTimer then
        Timer.RemoveTimer(self.AutoHideTimer)
    end
    self.AutoHideTimer = nil
    self.DurationCallback = nil
end

return M