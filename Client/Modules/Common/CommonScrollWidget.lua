--[[
    使用方法:
    1.代码不用绑定此脚本，此脚本已经静态绑定到了WBP_CommonScrollWidget蓝图中
    2.WBP_CommonScrollWidget类似特殊的控件,支持将它的第一个孩子节点按照配置滚动
    3.支持 TextBlock , BP_TemaranSampleRichTextBlock(即RichTextBlock),作为孩子节点
    4.支持 GUICanvasPanel,CanvasPanel作为孩子节点，在其下添加的子节点需要勾选 SizeToContent
]]

-- local class_name = "CommonScrollWidget"
-- CommonScrollWidget = BaseClass(UIHandlerViewBase, class_name)

---@class CommonScrollWidget 通用滚动控件,蓝图-WBP_CommonScrollWidget
local CommonScrollWidget = UnLua.Class()

local EScrollState = {
    None = 0,
    WaitStart = 1,
    Scorlling = 2,
    WaitEnd = 3
}

function CommonScrollWidget:Construct()
    CLog("CommonScrollWidget:Construct")

    self:InitScrollWidget()
    self:OnInit()
    self:StartAutoScroll()
end

function CommonScrollWidget:Tick(MyGeometry, InDeltaTime)
    -- CLog("CommonScrollWidget:Tick")

    if self.bCanSroll and self.bIsVaildTarget then
        self:DoTickAction(InDeltaTime)
    end
end

function CommonScrollWidget:Destruct()
    CLog("CommonScrollWidget:Destruct")

    -- self:ClearTickTimer()
end

function CommonScrollWidget:OnInit()
    self.ScrollState = EScrollState.None
    self.MinDelayFrame = 2
    self.DTimeStart = 0
    self.DTimeEnd = 0
end

-------------------------------------------------------------------------------

function CommonScrollWidget:StartAutoScroll()
    self:ResetScorllWidget()
end

function CommonScrollWidget:ResetScorllWidget()
    CLog(string.format("CommonScrollWidget:ResetScorllWidget "))
    self:ResetTranslation()
    self.InitX = self.InitTranslation.X
    self.InitY = self.InitTranslation.Y
    
    self.DTimeStart = 0
    self.DelayFrame = 0
    self.DTimeEnd = 0
    self.MaxMoveVal = 0
    self.CheckLengthFrame = 0

    self.bIsVaildTarget = CommonUtil.IsValid(self.TargetWidget)

    self.ScrollState = EScrollState.WaitStart
end

function CommonScrollWidget:ResetTranslation()
    if CommonUtil.IsValid(self.TargetWidget) then
        self.TargetWidget:SetRenderTranslation(self.InitTranslation)
    else
        CError("CommonScrollWidget:ResetTranslation, self.TargetWidget == nil", true)
    end
end

function CommonScrollWidget:DoTickAction(dt)
    if not(self.bCanSroll) then
        return
    end

    if not(CommonUtil.IsValid(self.TargetWidget)) then
        return
    end

    self.CheckLengthFrame = self.CheckLengthFrame + 1
    if self.CheckLengthFrame >= self.MinDelayFrame + 1 then
        self.CheckLengthFrame = 0
        local DesiredSize = self.TargetWidget:GetDesiredSize()
        if self.Orientation == UE.EOrientation.Orient_Horizontal then
            if DesiredSize.X ~= self.LastLength then
                self.LastLength = DesiredSize.X
                self:ResetScorllWidget()
                return
            end
        elseif self.Orientation == UE.EOrientation.Orient_Vertical then
            if DesiredSize.Y ~= self.LastLength then
                self.LastLength = DesiredSize.Y
                self:ResetScorllWidget()
                return
            end
        end
    end

    if self.ScrollState == EScrollState.None then
        return
    end

    if self.ScrollState == EScrollState.WaitStart then
        self.DTimeStart = self.DTimeStart + dt
        self.DelayFrame = self.DelayFrame + 1
        -- CError(string.format("CommonScrollWidget:DoTickAction, EScrollState.WaitStart, dt=[%s]",dt))
        if self.DelayFrame >= self.MinDelayFrame and self.DTimeStart >= self.WaitStartTime then
            local DesiredSize = self.TargetWidget:GetDesiredSize()
            -- local Geometry = self.TargetWidget:GetCachedGeometry()
            local Geometry = self.GUICanvasPanel_Root:GetCachedGeometry()
            local LocalSize = UE.USlateBlueprintLibrary.GetLocalSize(Geometry)
            local DeltaVal = DesiredSize.X - LocalSize.X 
            if self.Orientation == UE.EOrientation.Orient_Horizontal then
                DeltaVal = DesiredSize.X - LocalSize.X 
            elseif self.Orientation == UE.EOrientation.Orient_Vertical then
                DeltaVal = DesiredSize.Y - LocalSize.Y 
            end
            -- CLog(string.format("CommonScrollWidget:DoTickAction, EScrollState.WaitStart, DeltaVal=[%s]",DeltaVal))
            if DeltaVal > 0 then
                self.MaxMoveVal = DeltaVal
                self.ScrollState = EScrollState.Scorlling
            else
                self.ScrollState = EScrollState.None
                -- self:ClearTickTimer()
            end
        end
    elseif self.ScrollState == EScrollState.Scorlling then
        if self.bCanSroll then
            if self.Orientation == UE.EOrientation.Orient_Horizontal then
                local FinalX = self.InitX - self.MaxMoveVal
                local MoveToX = self.TargetWidget.RenderTransform.Translation.X - self.Speed * dt
                -- CLog(string.format("CommonScrollWidget:DoTickAction, EScrollState.Scorlling, MoveToX=[%s], FinalX=[%s]",MoveToX,FinalX))
                if MoveToX > FinalX then
                    self.TargetWidget:SetRenderTranslation(UE.FVector2D(MoveToX, self.InitY))
                else
                    MoveToX = FinalX
                    self.TargetWidget:SetRenderTranslation(UE.FVector2D(MoveToX, self.InitY))
                    self.ScrollState = EScrollState.WaitEnd
                end
            elseif self.Orientation == UE.EOrientation.Orient_Vertical then
                local FinalY = self.InitY - self.MaxMoveVal
                local MoveToY = self.TargetWidget.RenderTransform.Translation.Y - self.Speed * dt
                -- CLog(string.format("CommonScrollWidget:DoTickAction, EScrollState.Scorlling, MoveToX=[%s], FinalX=[%s]",MoveToX,FinalX))
                if MoveToY > FinalY then
                    self.TargetWidget:SetRenderTranslation(UE.FVector2D(self.InitX, MoveToY))
                else
                    MoveToY = FinalY
                    self.TargetWidget:SetRenderTranslation(UE.FVector2D(self.InitX, MoveToY))
                    self.ScrollState = EScrollState.WaitEnd
                end
            end
        end
    elseif self.ScrollState == EScrollState.WaitEnd then
        -- CLog(string.format("CommonScrollWidget:DoTickAction, EScrollState.WaitEnd, dt=[%s]",dt))
        self.DTimeEnd = self.DTimeEnd + dt
        if self.DTimeEnd >= self.WaitEndTime then
            self.ScrollState = EScrollState.WaitStart
            self:ResetScorllWidget()
        end
    end
end


-------------------------------------------------------------------------------

--- 为 UTextBlock 设置 SetText(txt)
function CommonScrollWidget:SetText(txt)
    if not CommonUtil.IsValid(self.TargetWidget) then
        return
    end

    local SetText_Temp = function(TWidget)
        if TWidget.IsA and TWidget:IsA(UE.UTextBlock) then
            TWidget:SetText(txt)
            return true
        end
    
        if TWidget.IsA and TWidget:IsA(UE.URichTextBlock) then
            TWidget:SetText(txt)
            return true
        end
    end

    local bRet = SetText_Temp(self.TargetWidget)
    if bRet then
        self:ResetScorllWidget()
        return
    end

    if self.TargetWidget.IsA and self.TargetWidget:IsA(UE.UCanvasPanel) then
        local ChildWidget = self.TargetWidget:GetChildAt(0)
        if CommonUtil.IsValid(ChildWidget) then
            local bRet = SetText_Temp(ChildWidget)
            if bRet then
                self:ResetScorllWidget()
            end
        end
    end
end

--- 为 UTextBlock 设置 SetTextColorFromQuality()
---@param Quality number
function CommonScrollWidget:SetTextColorFromQuality(Quality)
    if not CommonUtil.IsValid(self.TargetWidget) then
        return
    end

    local SetColor_Temp = function(TWidget)
        if TWidget.IsA and TWidget:IsA(UE.UTextBlock) then
            CommonUtil.SetTextColorFromQuality(TWidget, Quality)
            return true
        end
    
        if TWidget.IsA and TWidget:IsA(UE.URichTextBlock) then
            CommonUtil.SetTextColorFromQuality(TWidget, Quality)
            return true
        end
    end

    local bRet = SetColor_Temp(self.TargetWidget)
    if bRet then
        return
    end

    if self.TargetWidget.IsA and self.TargetWidget:IsA(UE.UCanvasPanel) then
        local ChildWidget = self.TargetWidget:GetChildAt(0)
        if CommonUtil.IsValid(ChildWidget) then
            local bRet = SetColor_Temp(ChildWidget)
        end
    end
end

--- 为 UTextBlock 设置 SetTextColorFromeHex()
---@param Hex string "ff00ff"
---@param Opacity number 0-1
function CommonScrollWidget:SetTextColorFromeHex(Hex, Opacity)
    Opacity = Opacity or 1
    if not CommonUtil.IsValid(self.TargetWidget) then
        return
    end

    local SetColor_Temp = function(TWidget)
        if TWidget.IsA and TWidget:IsA(UE.UTextBlock) then
            CommonUtil.SetTextColorFromeHex(TWidget, Hex, Opacity)
            return true
        end
    
        if TWidget.IsA and TWidget:IsA(UE.URichTextBlock) then
            CommonUtil.SetTextColorFromeHex(TWidget, Hex, Opacity)
            return true
        end
    end

    local bRet = SetColor_Temp(self.TargetWidget)
    if bRet then
        return
    end

    if self.TargetWidget.IsA and self.TargetWidget:IsA(UE.UCanvasPanel) then
        local ChildWidget = self.TargetWidget:GetChildAt(0)
        if CommonUtil.IsValid(ChildWidget) then
            local bRet = SetColor_Temp(ChildWidget)
        end
    end
end

-------------------------------------------------------------------------------


return CommonScrollWidget