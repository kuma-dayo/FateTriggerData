--[[
    公用功能未开启提示信息组件
]]
UILockFunctionTip = UILockFunctionTip or {}

UILockFunctionTip.instance = UILockFunctionTip.instance or nil

--[[
    创建提示
]]
function UILockFunctionTip.Show(msg,autoHideTime)
    msg = StringUtil.Format(msg);
    if not UILockFunctionTip.instance then
        local widget_class = UE.UClass.Load("/Game/Resources/UMG/Common/LockFunctionTip")
        UILockFunctionTip.instance = NewObject(widget_class, GameInstance, nil, "client.common.UILockFunctionTip")
        UIRoot.AddChildToLayer(UILockFunctionTip.instance,UIRoot.UILayerType.Tips)
    end
    if not autoHideTime then
        autoHideTime = 3
    end
    UILockFunctionTip.instance:Show(msg,autoHideTime)
end


local M = Class()

function M:Construct()
end

function M:Destruct()
    UILockFunctionTip.instance = nil
    self:Release()
end

function M:Show(msg,autoHideTime)
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:ScheduleAutoHide(autoHideTime)

    self.lbTip:SetText(msg)

    -- local size = self.lbTip.Slot:GetSize()
    -- local desiredX = size.x + 100
    -- size.x = math.max(desiredX,300)
    -- self.imgBg.Slot:SetSize(size)
end

function M:Hide()
    self:CleanAutoHideTimer()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
end

--[[
    提示信息 超时 关闭
]]
function M:ScheduleAutoHide(duration)
    self:CleanAutoHideTimer()
    self.autoHideTimer = Timer.InsertTimer(duration,function()
        self.autoHideTimer = nil
		self:OnAutoHide()
	end)   
end

function M:OnAutoHide()
    self:Hide();
end

function M:CleanAutoHideTimer()
    if self.autoHideTimer then
        Timer.RemoveTimer(self.autoHideTimer)
    end
    self.autoHideTimer = nil
end


return M