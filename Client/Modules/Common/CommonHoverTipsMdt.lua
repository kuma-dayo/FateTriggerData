--[[
    通用按钮HoverTips界面
]]

local class_name = "CommonHoverTipsMdt";
CommonHoverTipsMdt = CommonHoverTipsMdt or BaseClass(GameMediator, class_name);

function CommonHoverTipsMdt:__init()
end

function CommonHoverTipsMdt:OnShow(data)
end

function CommonHoverTipsMdt:OnHide()
end
CommonHoverTipsMdt.PositionType = {
    TopCenter = 1,  -- 顶部居中
    BottomCenter = 2,   -- 底部居中
    Left = 3,   -- 左侧
    Right = 4   -- 右侧
}
-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
	self.InputFocus = false
    -- 这个界面无需输入事件，强制关闭WidgetFocus;
    self.CloseWidgetFocus = true
    self.MsgList = {
        {Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_DEACTIVE_CHANGED,    Func = self.OnOtherViewClosed },
    }
    self.BindNodes = 
    {
        { UDelegate = self.OnAnimationFinished_vx_common_hovertips_up_out,	Func = Bind(self,self.On_vx_common_hovertips_up_out_Finished) },
        { UDelegate = self.OnAnimationFinished_vx_common_hovertips_down_out,	Func = Bind(self,self.On_vx_common_hovertips_down_out_Finished) },
    }
end

--由mdt触发调用
--[[
    Param = {
        ParentWidgetCls: 附着的父节点，必传，用于监听父节点关闭时，关闭此tips
        TipsStr: 提示的文本内容
        FocusWidget: 附着的节点，将位置设置在该节点四周可放入位置
        FocusOffset [Optional]: 采样位置偏移 FVector2D
        PositionType [Optional]: 指定在哪一测，不动态变化
    }
]]
function M:OnShow(Params)
    if not (Params and Params.ParentWidgetCls) or Params.TipsStr == "" then
        CError("CommonHoverTips Param Error")
        print_trackback()
        self:DoClose()
        return
    end
    self.Params = Params
    self:CheckParentViewId()
    self:UpdateShow()
    self:AdjustShowPos()
    self:PlayDynamicEffectOnShow(true, self.Params.PositionType == CommonHoverTipsMdt.PositionType.BottomCenter and true or false)
end

function M:OnRepeatShow(Params)
    self:OnShow(Params)
end

function M:CheckParentViewId()
    local ParentWidgetCls = self.Params.ParentWidgetCls
    self.ParentViewId = nil
    if ParentWidgetCls.IsA and ParentWidgetCls:IsA(UE.UUserWidget) then
        self.ParentViewId = ParentWidgetCls.viewId
    elseif ParentWidgetCls.IsClass and ParentWidgetCls.WidgetBase then
        self.ParentViewId = ParentWidgetCls.WidgetBase.viewId
        if not self.ParentViewId then
            local WidgetBase = ParentWidgetCls.WidgetBase
            while WidgetBase and not WidgetBase.viewId do
                ParentWidgetCls = ParentWidgetCls.ParentHandler
                WidgetBase = ParentWidgetCls.WidgetBase
            end
            self.ParentViewId = ParentWidgetCls.viewId
        end
    else
        CError("CommonHoverTipsMdt:CheckParentViewId ParentWidgetCls must be UUserWidget(UserWidgetBase) or UIHandlerView",true)
    end
    if not self.ParentViewId then
        CError("CommonHoverTipsMdt:CheckParentViewId Can't Find Parent ViewId",true)
        self:DoClose()
    end
end

function M:UpdateShow()
    self.TextTips:SetText(StringUtil.Format(self.Params.TipsStr))
end

-- 计算浮窗出现的位置
function M:AdjustShowPos()
    self.OverlayTips:SetRenderScale(UE.FVector2D(0.001,0.001))
    self:ClearPopTimer()
    -- Icon按钮存在Hover放大效果，下一帧再进行位置计算，避免放大影响了Position计算
    self.PopTimer = Timer.InsertTimer(-1,function ()
        if not CommonUtil.IsValid(self.OverlayTips) then
            return
        end
        self.OverlayTips:SetRenderScale(UE.FVector2D(1,1))
        self.OverlayTips:ForceLayoutPrepass()
        local ViewportSize = CommonUtil.GetViewportSize(self)
        -- local PanelSize = UE.USlateBlueprintLibrary.GetLocalSize(self.OverlayTips:GetCachedGeometry())
        local PanelSize = self.OverlayTips:GetDesiredSize()
        if not self.Params.FocusWidget then
            -- 没有要附着的点就居中显示
            self.OverlayTips.Slot:SetPosition(UE.FVector2D(ViewportSize.x/2-PanelSize.x/2,-ViewportSize.y/2+PanelSize.y/2))
        else
            local ShowPosition,IsFlipY = self:CalculateFocusPos(ViewportSize,PanelSize)
            self.OverlayTips.Slot:SetPosition(ShowPosition)
            local BgTransform = self.Bg.RenderTransform
            local TextPadding = self.TextTips.SLot.Padding
            BgTransform.Scale.Y = IsFlipY and -1 or 1
            TextPadding.Top = IsFlipY and 13 or 0
            self.Bg:SetRenderTransform(BgTransform)
            self.TextTips.Slot:SetPadding(TextPadding)
        end
    end)
end

function M:ClearPopTimer()
    if self.PopTimer then
        Timer.RemoveTimer(self.PopTimer)
    end
    self.PopTimer = nil
end
 
-- 计算在附着点的哪一侧位置显示
function M:CalculateFocusPos(ViewportSize,PanelSize)
    local _,FocusPosition = UE.USlateBlueprintLibrary.LocalToViewport(self,self.Params.FocusWidget:GetCachedGeometry(),self.Params.FocusOffset or UE.FVector2D(0,0))
    local FocusSize = UE.USlateBlueprintLibrary.GetLocalSize(self.Params.FocusWidget:GetCachedGeometry())
    local FocusScale = self.Params.FocusWidget.RenderTransform.Scale
    local PosX,PosY = 0,0
    local IsFlipY = false
    if self.Params.PositionType == CommonHoverTipsMdt.PositionType.TopCenter then
        PosY = ViewportSize.Y - FocusPosition.Y
        PosX = FocusPosition.X  - (PanelSize.X - FocusSize.X * FocusScale.X) * 0.5
    elseif self.Params.PositionType == CommonHoverTipsMdt.PositionType.BottomCenter then
        PosY = ViewportSize.Y - FocusPosition.Y - FocusSize.Y - PanelSize.Y
        PosX = FocusPosition.X  - (PanelSize.X - FocusSize.X * FocusScale.X) * 0.5
        IsFlipY = true
    elseif self.Params.PositionType == CommonHoverTipsMdt.PositionType.Left then
        PosY = ViewportSize.Y - FocusPosition.Y - PanelSize.Y
        PosX = FocusPosition.X - PanelSize.X
    elseif self.Params.PositionType == CommonHoverTipsMdt.PositionType.Right then
        PosY = ViewportSize.Y - FocusPosition.Y - PanelSize.Y
        PosX = FocusPosition.X + FocusSize.X * FocusScale.X
    else
        local TopPadding = FocusPosition.Y  - PanelSize.Y
        local LeftPadding = FocusPosition.X
        if TopPadding > 0 then
            -- 优先放顶部
            PosY = ViewportSize.Y - FocusPosition.Y
            if LeftPadding > (PanelSize.X - FocusSize.X * FocusScale.X) * 0.5 then
                -- 优先居中
                PosX = FocusPosition.X  - (PanelSize.X - FocusSize.X * FocusScale.X) * 0.5
            -- elseif LeftPadding > PanelSize.X - FocusSize.X then
            --     -- 优先靠左展示，与Widget右对齐
            --     PosX = FocusPosition.X - PanelSize.X + FocusSize.X 
            else
                -- 靠右展示，与Widget左对齐
                PosX = FocusPosition.X 
            end
        else
            -- 顶部放不下 放左/右侧 与Widget顶对齐
            PosY = ViewportSize.Y - FocusPosition.Y - PanelSize.Y
            if LeftPadding > PanelSize.X then
                -- 靠左显示
                PosX = FocusPosition.X - PanelSize.X
            else
                -- 靠右显示
                PosX = FocusPosition.X + FocusSize.X * FocusScale.X
            end
        end
    end
    return UE.FVector2D(PosX,-PosY),IsFlipY
end

function M:OnHide()
    self:ClearPopTimer()
end

-- 监听父节点依赖界面，则关闭自身
function M:OnOtherViewClosed(ViewId)
    if ViewId == self.viewId then
        return
    end
   
    if ViewId == self.ParentViewId then
        self:DoClose()
    end
end

--关闭界面
function M:DoClose()
    --MvcEntry:CloseView(self.viewId)
    self:PlayDynamicEffectOnShow(false, self.Params.PositionType == CommonHoverTipsMdt.PositionType.BottomCenter and true or false)
end

--[[
    播放显示退出动效
]]
function M:PlayDynamicEffectOnShow(InIsOnShow, InIsDown)
    if self.VXV_isDown ~= nil then
        self.VXV_isDown = InIsDown
    end
    if InIsOnShow then
        if self.VXE_Common_HoverTips_In then
            self:VXE_Common_HoverTips_In()
        end
    else
        if self.VXE_Common_HoverTips_Out then
            self:VXE_Common_HoverTips_Out()
        end
    end
end

function M:On_vx_common_hovertips_up_out_Finished()
    MvcEntry:CloseView(self.viewId)
end

function M:On_vx_common_hovertips_down_out_Finished()
    MvcEntry:CloseView(self.viewId)
end


return M