--[[
    公用游戏世界提示信息组件
]]
UIGameWorldTip = UIGameWorldTip or {}

UIGameWorldTip.instance = UIGameWorldTip.instance or nil

UIGameWorldTip.ViewData = {
    LoginTipUMG = "/Game/BluePrints/UMG/OutsideGame/Login/WBP_LoginTipsPanel.WBP_LoginTipsPanel",
    InGameCommonTips = "/Game/Resources/UMG/Common/UIGameWorldTip"
}

--[[
    创建提示
]]
function UIGameWorldTip.Show(msg,autoHideTime,img, InUMGPath)
    if MvcEntry and MvcEntry:GetModel(ViewModel):GetState(ViewConst.OnlineSubLoginPanel) then
        --在线子系统登录时，不显示
        return
    end
    msg = StringUtil.Format(msg);
    InUMGPath = InUMGPath or self.ViewData.InGameCommonTips
    if not UIGameWorldTip.instance then
        local widget_class = UE.UClass.Load(InUMGPath)
        UIGameWorldTip.instance = NewObject(widget_class, GameInstance, nil, "client.common.UIGameWorldTip")
        UIRoot.AddChildToLayer(UIGameWorldTip.instance,UIRoot.UILayerType.Tips)
    end
    if not autoHideTime then
        autoHideTime = 3
    end
    UIGameWorldTip.instance:Show(msg,autoHideTime,img)
end
function UIGameWorldTip.Hide()
    if UIGameWorldTip.instance then
        UIGameWorldTip.instance:Hide()
    end
end


local M = Class()

function M:Construct()
end

function M:Destruct()
    self:Hide()
    UIGameWorldTip.instance = nil
    self:Release()
end

function M:Show(msg,autoHideTime,img)
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:ScheduleAutoHide(autoHideTime)

    self.lbTip:SetText(StringUtil.Format(msg))
    if img then
        self.Img_Bg:SetVisibility(UE.ESlateVisibility.Visible)
        self.Img_Bg:SetBrushFromTexture(img)
    end
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