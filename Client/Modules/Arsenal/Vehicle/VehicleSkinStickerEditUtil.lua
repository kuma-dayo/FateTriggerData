local VehicleSkinStickerEditUtil = VehicleSkinStickerEditUtil or {}
--[[
    载具贴纸编辑工具
    
]]

VehicleSkinStickerEditUtil.EditBoxSize = 20 -- 外框四角选中点的尺寸 
VehicleSkinStickerEditUtil.ScaleMax = 2 -- 缩放最大倍数
VehicleSkinStickerEditUtil.ScaleMin = 1   -- 缩放最小倍数
VehicleSkinStickerEditUtil.OPERATE_TYPE = {
    SIZE = 1,
    ROTATION = 2,
    POSITION = 3,
}

function VehicleSkinStickerEditUtil.SetScaleMax(NewScaleMax)
    VehicleSkinStickerEditUtil.ScaleMax = NewScaleMax
end

function VehicleSkinStickerEditUtil.SetScaleMin(NewScaleMin)
    VehicleSkinStickerEditUtil.ScaleMin = NewScaleMin
end

--[[
    View 下必须有ImgPanel，ImgIcon，BgMask 三个子节点
    InitParam ： 
            Scale,
            Position,
            RotateAngle,
            ScaleLength,
]]
function VehicleSkinStickerEditUtil.InitEditImage(ViewInst, InitParam)
    VehicleSkinStickerEditUtil.EditView = ViewInst
    local EditingPanel = ViewInst.View.ImgPanel
    local Image = ViewInst.View.ImgIcon
    local BgMask = ViewInst.View.BgMask
    VehicleSkinStickerEditUtil.EditingPanel = EditingPanel
    VehicleSkinStickerEditUtil.EditingImg = Image

    local InitSize = InitParam.InitSize and InitParam.InitSize or UE.FVector2D(192, 192)
    -- 记录原始尺寸，用于尺寸变化限制
    -- VehicleSkinStickerEditUtil.InitSize = UE.FVector2D(192, 192)--VehicleSkinStickerEditUtil.EditingImg.Brush.ImageSize
    VehicleSkinStickerEditUtil.InitSize = InitSize

    -- 初始化大小
    local Size =  UE.FVector2D(VehicleSkinStickerEditUtil.InitSize.X * InitParam.ScaleLength, VehicleSkinStickerEditUtil.InitSize.Y * InitParam.ScaleLength)
    local EditSize = UE.FVector2D(Size.X + VehicleSkinStickerEditUtil.EditBoxSize*2, Size.Y + VehicleSkinStickerEditUtil.EditBoxSize*2)
    EditingPanel.Slot:SetSize(EditSize)

    if InitParam.Position.X == 0 and InitParam.Position.Y == 0 then    
        -- 初始化位置
        local ViewportSize = CommonUtil.GetViewportSize(ViewInst.View)
        -- 屏幕中心是基准点
        VehicleSkinStickerEditUtil.InitPos = UE.FVector2D(ViewportSize.x*0.5,ViewportSize.y*0.5)
        local InitPos = UE.FVector2D( VehicleSkinStickerEditUtil.InitPos.X + InitParam.Position.X, VehicleSkinStickerEditUtil.InitPos.Y + InitParam.Position.Y)
        EditingPanel.Slot:SetPosition(InitPos)
    else
        EditingPanel.Slot:SetPosition(UE.FVector2D(InitParam.Position.X - EditSize.X / 2, InitParam.Position.Y - EditSize.Y / 2))
        -- EditingPanel.Slot:SetPosition(UE.FVector2D(InitParam.Position.X, InitParam.Position.Y))
        -- ViewInst.View.GUIImage_75.Slot:SetPosition(UE.FVector2D(InitParam.Position.X, InitParam.Position.Y+20))
        VehicleSkinStickerEditUtil.InitPos = EditingPanel.Slot:GetPosition()
    end

    -- 初始化旋转
    EditingPanel:SetRenderTransformAngle(InitParam.RotateAngle)
    --记录缩放
    VehicleSkinStickerEditUtil.Scale = InitParam.Scale
    -- EditingBgMask作用为当鼠标拖出目标编辑图片的时候，仍能获取到鼠标移动事件，仅在按下时显示即可
    VehicleSkinStickerEditUtil.EditingBgMask = BgMask
    VehicleSkinStickerEditUtil.CurCursorType = GameConfig.CursorType.Default
end

-- 进入预编辑，主要的是由于贴纸Hover效果，只要显示框即可，但不可以编辑
function VehicleSkinStickerEditUtil.EnterPreEditImage(ViewInst, InitParam)
    VehicleSkinStickerEditUtil.InitEditImage(ViewInst, InitParam)

    if VehicleSkinStickerEditUtil.EditView == nil or 
        VehicleSkinStickerEditUtil.EditView.View == nil then
        return
    end
    local View = VehicleSkinStickerEditUtil.EditView.View
    View.Sticker_Edit:SetVisibility(UE.ESlateVisibility.Hidden)
    VehicleSkinStickerEditUtil.SetCanEdit(false)
end

-- 进入编辑 
--[[
    View 下必须有ImgPanel，ImgIcon，BgMask 三个子节点
    InitParam ： 
            Scale,
            Position,
            RotateAngle,
            ScaleLength,
]]
function VehicleSkinStickerEditUtil.EnterEditImage(ViewInst,InitParam)
    VehicleSkinStickerEditUtil.InitEditImage(ViewInst, InitParam)

    if VehicleSkinStickerEditUtil.EditView == nil or 
        VehicleSkinStickerEditUtil.EditView.View == nil then
        return
    end
    local View = VehicleSkinStickerEditUtil.EditView.View
    View.Sticker_Edit:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    VehicleSkinStickerEditUtil.SetCanEdit(true)

    Timer.InsertTimer(-1,function ()
        VehicleSkinStickerEditUtil.PostTransformChg()
    end)
end

function VehicleSkinStickerEditUtil.SetCanEdit(bCanEdit)
    VehicleSkinStickerEditUtil.CanEdit = bCanEdit
end

-- 结束编辑
function VehicleSkinStickerEditUtil.FinishEditImage()
    -- VehicleSkinStickerEditUtil.CanEdit = false
    VehicleSkinStickerEditUtil.SetCanEdit(false)
    VehicleSkinStickerEditUtil.EditingImg = nil
    VehicleSkinStickerEditUtil.EditingPanel = nil
    VehicleSkinStickerEditUtil.EditingBgMask = nil
    VehicleSkinStickerEditUtil.OperateType = nil
    VehicleSkinStickerEditUtil.CurRotation = nil
    VehicleSkinStickerEditUtil.CurPosition = nil
    VehicleSkinStickerEditUtil.BeginPos = nil
    VehicleSkinStickerEditUtil.InitSize = nil
end

function VehicleSkinStickerEditUtil.OnMouseButtonDown(ParentContent, InMyGeometry, InMouseEvent)
    if not VehicleSkinStickerEditUtil.CanEdit then
        return
    end
    -- print("======================OnMouseButtonDown")
    if not VehicleSkinStickerEditUtil.CheckResource() then
        CWaring("VehicleSkinStickerEditUtil Image Error! Please Check!")
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    VehicleSkinStickerEditUtil.EditingBgMask:SetVisibility(UE.ESlateVisibility.Visible)
    local _,BeginPos = UE.USlateBlueprintLibrary.AbsoluteToViewport(ParentContent,UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InMouseEvent))
    VehicleSkinStickerEditUtil.BeginPos = BeginPos
    VehicleSkinStickerEditUtil.SetOperateTypeFromMousePos(InMouseEvent)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function VehicleSkinStickerEditUtil.OnMouseButtonUp(ParentContent, InMyGeometry, InMouseEvent)
    if not VehicleSkinStickerEditUtil.CanEdit then
        return
    end
    -- CError("======================OnMouseButtonUp")
    if not VehicleSkinStickerEditUtil.CheckResource() then
        CWaring("VehicleSkinStickerEditUtil Image Error! Please Check!")
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    CWaring("VehicleSkinStickerEditUtil.OnMouseButtonUp")
    local _,BeginPos = UE.USlateBlueprintLibrary.AbsoluteToViewport(ParentContent,UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InMouseEvent))
    VehicleSkinStickerEditUtil.BeginPos = BeginPos
    VehicleSkinStickerEditUtil.SetOperateTypeFromMousePos(InMouseEvent,true)

    VehicleSkinStickerEditUtil.EditingBgMask:SetVisibility(UE.ESlateVisibility.Collapsed)
    VehicleSkinStickerEditUtil.OperateType = nil
    VehicleSkinStickerEditUtil.BeginPos = nil
    VehicleSkinStickerEditUtil.CurRotation = nil
    VehicleSkinStickerEditUtil.ChangeAlignmentAndPos(UE.FVector2D(0),true)
    return UE.UWidgetBlueprintLibrary.Handled()
end

--鼠标移动到游戏屏幕外
function VehicleSkinStickerEditUtil.OnMouseLeaveScreen(ParentContent)
    if not VehicleSkinStickerEditUtil.CanEdit then
        return
    end
    -- CError("======================OnMouseLeaveScreen")
    if not VehicleSkinStickerEditUtil.CheckResource() then
        CWaring("VehicleSkinStickerEditUtil Image Error! Please Check!")
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    -- CError("VehicleSkinStickerEditUtil.OnMouseLeaveScreen, CommonUtil.SetCursorType = "..table.tostring(GameConfig.CursorType.Default))
    CommonUtil.SetCursorType(GameConfig.CursorType.Default)

    VehicleSkinStickerEditUtil.EditingBgMask:SetVisibility(UE.ESlateVisibility.Collapsed)
    VehicleSkinStickerEditUtil.OperateType = nil
    VehicleSkinStickerEditUtil.BeginPos = nil
    VehicleSkinStickerEditUtil.CurRotation = nil
    VehicleSkinStickerEditUtil.ChangeAlignmentAndPos(UE.FVector2D(0),true)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function VehicleSkinStickerEditUtil.OnMouseMove(ParentContent,LimitSize, InMyGeometry, InMouseEvent)
    if not VehicleSkinStickerEditUtil.CanEdit then
        return
    end
    if not VehicleSkinStickerEditUtil.CheckResource() then
        CWaring("VehicleSkinStickerEditUtil Image Error! Please Check!")
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    if not VehicleSkinStickerEditUtil.BeginPos then
        VehicleSkinStickerEditUtil.SetOperateTypeFromMousePos(InMouseEvent,true)
    end
    if not VehicleSkinStickerEditUtil.OperateType then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
	local _,CurPos = UE.USlateBlueprintLibrary.AbsoluteToViewport(ParentContent,UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InMouseEvent))
    if VehicleSkinStickerEditUtil.BeginPos then
        local DeltaPos = CurPos - VehicleSkinStickerEditUtil.BeginPos
        if VehicleSkinStickerEditUtil.OperateType == VehicleSkinStickerEditUtil.OPERATE_TYPE.SIZE then
            VehicleSkinStickerEditUtil.ChangeSize(DeltaPos)
            VehicleSkinStickerEditUtil.BeginPos = CurPos
        elseif VehicleSkinStickerEditUtil.OperateType == VehicleSkinStickerEditUtil.OPERATE_TYPE.ROTATION then
            VehicleSkinStickerEditUtil.ChangeRotation(CurPos)
        elseif VehicleSkinStickerEditUtil.OperateType == VehicleSkinStickerEditUtil.OPERATE_TYPE.POSITION then
            VehicleSkinStickerEditUtil.ChangePosition(LimitSize,DeltaPos)
        end
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function VehicleSkinStickerEditUtil.CheckResource()
    return CommonUtil.IsValid(VehicleSkinStickerEditUtil.EditingPanel) and CommonUtil.IsValid(VehicleSkinStickerEditUtil.EditingImg) and CommonUtil.IsValid(VehicleSkinStickerEditUtil.EditingBgMask)
end


-- 根据鼠标点击的位置。决定当前做什么操作
-- JustUpdateCursor 仅更新图标样式
function VehicleSkinStickerEditUtil.SetOperateTypeFromMousePos(InMouseEvent,JustUpdateCursor)
    local CursorType = GameConfig.CursorType.Default
    local CursorAngle = 0
    if not JustUpdateCursor then
        VehicleSkinStickerEditUtil.OperateType = nil
    end
    local CurScreenSpacePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(InMouseEvent)
    -- 在图片内的相对位置
	local Pos = UE.USlateBlueprintLibrary.AbsoluteToLocal(VehicleSkinStickerEditUtil.EditingPanel:GetCachedGeometry(), CurScreenSpacePos) -- 这个坐标系的左上角就是坐标原点，整个坐标点位于第一象限
    local BoxSize = VehicleSkinStickerEditUtil.EditBoxSize
	local ImgSize = UE.USlateBlueprintLibrary.GetLocalSize(VehicleSkinStickerEditUtil.EditingPanel:GetCachedGeometry())
    local CurRotation = VehicleSkinStickerEditUtil.EditingPanel.RenderTransform.Angle
    if(-BoxSize <= Pos.X and Pos.X <= BoxSize and -BoxSize <= Pos.Y and Pos.Y <= BoxSize ) then
        -- LeftTop
        -- print("====================== LeftTop")
        if(0 <= Pos.X and 0 <= Pos.Y) then
            if JustUpdateCursor then
                CursorType = GameConfig.CursorType.Scale
                CursorAngle = -90
            else
                VehicleSkinStickerEditUtil.ChangeAlignmentAndPos(UE.FVector2D(1))
                VehicleSkinStickerEditUtil.OperateType = VehicleSkinStickerEditUtil.OPERATE_TYPE.SIZE
            end
        else
            if JustUpdateCursor then
                CursorType = GameConfig.CursorType.Rotate
                CursorAngle = 210
            else
                VehicleSkinStickerEditUtil.OperateType = VehicleSkinStickerEditUtil.OPERATE_TYPE.ROTATION
            end
        end
    elseif (ImgSize.X - BoxSize <= Pos.X and Pos.X <= ImgSize.X + BoxSize and -BoxSize <= Pos.Y and Pos.Y <= BoxSize ) then
        -- RightTop
        -- print("====================== RightTop")
        if(Pos.X <= ImgSize.X and 0 <= Pos.Y) then
            if JustUpdateCursor then
                CursorType = GameConfig.CursorType.Scale
            else
                VehicleSkinStickerEditUtil.ChangeAlignmentAndPos(UE.FVector2D(0,1))
                VehicleSkinStickerEditUtil.OperateType = VehicleSkinStickerEditUtil.OPERATE_TYPE.SIZE
            end
        else
            if JustUpdateCursor then
                CursorType = GameConfig.CursorType.Rotate
                CursorAngle = -60
            else
                VehicleSkinStickerEditUtil.OperateType = VehicleSkinStickerEditUtil.OPERATE_TYPE.ROTATION
            end
        end
    elseif (-BoxSize <= Pos.X and Pos.X <= BoxSize and ImgSize.Y - BoxSize <= Pos.Y and Pos.Y <= ImgSize.Y + BoxSize) then
        -- LeftBottom
        -- print("====================== LeftBottom")
        if(0 <= Pos.X and Pos.Y <= ImgSize.Y) then
            if JustUpdateCursor then
                CursorType = GameConfig.CursorType.Scale
            else
                VehicleSkinStickerEditUtil.ChangeAlignmentAndPos(UE.FVector2D(1,0))
                VehicleSkinStickerEditUtil.OperateType = VehicleSkinStickerEditUtil.OPERATE_TYPE.SIZE
            end
        else
            if JustUpdateCursor then
                CursorType = GameConfig.CursorType.Rotate
                CursorAngle = 120
            else
                VehicleSkinStickerEditUtil.OperateType = VehicleSkinStickerEditUtil.OPERATE_TYPE.ROTATION
            end
        end
    elseif (ImgSize.X - BoxSize <= Pos.X and Pos.X <= ImgSize.X + BoxSize and ImgSize.Y - BoxSize <= Pos.Y and Pos.Y <= ImgSize.Y + BoxSize) then
        -- RightBottom
        -- print("====================== RightBottom")
        if(Pos.X <= ImgSize.X and Pos.Y <= ImgSize.Y) then
            if JustUpdateCursor then
                CursorType = GameConfig.CursorType.Scale
                CursorAngle = -90 
            else
                VehicleSkinStickerEditUtil.ChangeAlignmentAndPos(UE.FVector2D(0))
                VehicleSkinStickerEditUtil.OperateType = VehicleSkinStickerEditUtil.OPERATE_TYPE.SIZE
            end
        else
            if JustUpdateCursor then
                CursorType = GameConfig.CursorType.Rotate
                CursorAngle = 30
            else
                VehicleSkinStickerEditUtil.OperateType = VehicleSkinStickerEditUtil.OPERATE_TYPE.ROTATION
            end
        end
    elseif(0 <= Pos.X and Pos.X <= ImgSize.X and 0 <= Pos.Y and Pos.Y <= ImgSize.Y) then
        if JustUpdateCursor then
            CursorType = GameConfig.CursorType.Drag
        else
            VehicleSkinStickerEditUtil.OperateType = VehicleSkinStickerEditUtil.OPERATE_TYPE.POSITION
            VehicleSkinStickerEditUtil.CurPosition = VehicleSkinStickerEditUtil.EditingPanel.Slot:GetPosition()
        end
    end

    if JustUpdateCursor then
        local IsSetAngle = CursorType == GameConfig.CursorType.Scale or CursorType == GameConfig.CursorType.Rotate
        VehicleSkinStickerEditUtil.CursorAngleForType = CursorAngle

        -- CError("VehicleSkinStickerEditUtil.SetOperateTypeFromMousePos, CommonUtil.SetCursorType = "..table.tostring(CursorType))
        CommonUtil.SetCursorType(CursorType,IsSetAngle and CursorAngle + CurRotation or 0)
    else
        if VehicleSkinStickerEditUtil.OperateType == VehicleSkinStickerEditUtil.OPERATE_TYPE.ROTATION then
            VehicleSkinStickerEditUtil.CurRotation = CurRotation
        end
    end
end

-- 改变图片锚点
function VehicleSkinStickerEditUtil.ChangeAlignmentAndPos(NewAlignment,IsReset)
    VehicleSkinStickerEditUtil._ChangeAlignmentAndPos(VehicleSkinStickerEditUtil.EditingPanel,NewAlignment,IsReset)
end

function VehicleSkinStickerEditUtil._ChangeAlignmentAndPos(Widget,NewAlignment,IsReset)
    if not IsReset then
        -- 在计算对角锚点的时候，要考虑到Angle的影响，因为AbsoluteToLocal获取的结果是不受Angle影响的，即点击旋转前的右下角，在旋转后点击的获得的坐标依然是右下角
        -- 所以要将锚点进行角度转换
        local CurRotationAngle = VehicleSkinStickerEditUtil.EditingPanel.RenderTransform.Angle
        NewAlignment.X,NewAlignment.Y = VehicleSkinStickerEditUtil.AlignmentAfterRotate(NewAlignment.X,NewAlignment.Y,CurRotationAngle)
    end
	local ImgSize = UE.USlateBlueprintLibrary.GetLocalSize(Widget:GetCachedGeometry())
    local CurPos = Widget.SLot:GetPosition()
    local CurAlignment = Widget.Slot:GetAlignment()
    Widget.Slot:SetAlignment(NewAlignment)
    if NewAlignment.X - CurAlignment.X ~= 0 then
        CurPos.X = CurPos.X + (NewAlignment.X - CurAlignment.X)*ImgSize.X
    end
    if NewAlignment.Y - CurAlignment.Y ~= 0 then
        CurPos.Y = CurPos.Y + (NewAlignment.Y - CurAlignment.Y)*ImgSize.Y
    end
    Widget.Slot:SetPosition(CurPos)
end

function VehicleSkinStickerEditUtil.AlignmentAfterRotate(X, Y, Angle)
    local CenterX,CenterY = 0.5,0.5
    -- 移动到中心
    local TransX = X - CenterX
    local TransY = Y - CenterY

    local Rad = math.rad(Angle)
    local CosAngle = math.cos(Rad)
    local SinAngle = math.sin(Rad)

    -- 计算旋转后的坐标
    local NewX = TransX * CosAngle - TransY * SinAngle
    local NewY = TransX * SinAngle + TransY * CosAngle
    -- 移动回去
    NewX = NewX + CenterX
    NewY = NewY + CenterY
    return NewX, NewY
end

-- 改变图片大小
function VehicleSkinStickerEditUtil.ChangeSize(MouseDelta)
    VehicleSkinStickerEditUtil._ChangeSize(VehicleSkinStickerEditUtil.EditingPanel,MouseDelta)
    VehicleSkinStickerEditUtil.PostTransformChg()
end

function VehicleSkinStickerEditUtil._ChangeSize(Widget,MouseDelta)
    if MouseDelta.X == 0 and MouseDelta.Y == 0 then
        return
    end
    local IsX = math.abs(MouseDelta.X) > math.abs(MouseDelta.Y)
    local ChangeDelta = IsX and MouseDelta.X or MouseDelta.Y
    local CurAlignment = Widget.Slot:GetAlignment()
    local ChangeAlignment = IsX and (CurAlignment.X > 0.5 and -1 or 1) or (CurAlignment.Y > 0.5 and -1 or 1)
    local Size= Widget.Slot:GetSize()
    Size.X = Size.X + ChangeAlignment * ChangeDelta
    Size.Y = Size.Y + ChangeAlignment * ChangeDelta
    Size.X = UE.UKismetMathLibrary.FClamp(Size.X,VehicleSkinStickerEditUtil.InitSize.X * VehicleSkinStickerEditUtil.ScaleMin,VehicleSkinStickerEditUtil.InitSize.X * VehicleSkinStickerEditUtil.ScaleMax)
    Size.Y = UE.UKismetMathLibrary.FClamp(Size.Y,VehicleSkinStickerEditUtil.InitSize.Y * VehicleSkinStickerEditUtil.ScaleMin,VehicleSkinStickerEditUtil.InitSize.Y * VehicleSkinStickerEditUtil.ScaleMax)
    Widget.Slot:SetSize(Size)
end

-- 改变图片角度
function VehicleSkinStickerEditUtil.ChangeRotation(CurPos)
    VehicleSkinStickerEditUtil._ChangeRotation(VehicleSkinStickerEditUtil.EditingPanel,CurPos)

    VehicleSkinStickerEditUtil.PostTransformChg()
end

function VehicleSkinStickerEditUtil._ChangeRotation(Widget,CurPos)
	local ImgSize = UE.USlateBlueprintLibrary.GetLocalSize(VehicleSkinStickerEditUtil.EditingPanel:GetCachedGeometry())
    -- 以图片中心为基准点
    local ImgPosition = VehicleSkinStickerEditUtil.EditingPanel.Slot:GetPosition()
    local MidPoint = UE.FVector2D(ImgPosition.X+ ImgSize.X/2 , ImgPosition.Y+ImgSize.Y/2)
    -- 计算初始点击位置和基准点形成的向量
    local VectorBegin = VehicleSkinStickerEditUtil.BeginPos - MidPoint
    -- 计算当前点击位置和基准点形成的向量
    local VectorEnd = CurPos - MidPoint
    -- 计算两个向量间的夹角。即为当前图片旋转角度
    local DotProduct = UE.UKismetMathLibrary.DotProduct2D(VectorBegin,VectorEnd)
    local CrossProductLength = UE.UKismetMathLibrary.CrossProduct2D(VectorBegin,VectorEnd)
    local DeltaAngle =  UE.UKismetMathLibrary.DegAtan2(CrossProductLength,DotProduct)
    if DeltaAngle < 0 then
        DeltaAngle = DeltaAngle + 360
    end
    if(DeltaAngle ~= 0) then
        local FinalAngle = VehicleSkinStickerEditUtil.CurRotation + DeltaAngle
        if FinalAngle > 360 then
            FinalAngle = FinalAngle - 360
        end
        Widget:SetRenderTransformAngle(FinalAngle)
        CommonUtil.SetCursorAngle(VehicleSkinStickerEditUtil.CursorAngleForType + FinalAngle)
    end
end

-- 改变图片位置
function VehicleSkinStickerEditUtil.ChangePosition(LimitSize,MouseDelta)
    if MouseDelta == UE.FVector2D(0) then
        return
    end
    VehicleSkinStickerEditUtil._ChangePosition(VehicleSkinStickerEditUtil.EditingPanel,LimitSize,MouseDelta)

    VehicleSkinStickerEditUtil.PostTransformChg()
end

function VehicleSkinStickerEditUtil._ChangePosition(Widget,LimitBox,MouseDelta)
    local CurPosition = VehicleSkinStickerEditUtil.CurPosition
    local CurAlignment = Widget.Slot:GetAlignment()
	local ImgSize = UE.USlateBlueprintLibrary.GetLocalSize(Widget:GetCachedGeometry())
    local NewPosition = UE.FVector2D(CurPosition.X + MouseDelta.X,CurPosition.Y+ MouseDelta.Y)
    if LimitBox then
        local LimitPosition = LimitBox.Slot:GetPosition()
        local LimitSize = UE.USlateBlueprintLibrary.GetLocalSize(LimitBox:GetCachedGeometry())
        if LimitSize.X > 0 and LimitSize.Y > 0 then
            NewPosition.X = UE.UKismetMathLibrary.FClamp(NewPosition.X, LimitPosition.X,LimitPosition.X + LimitSize.X - ImgSize.X * (1- CurAlignment.X))
            NewPosition.Y = UE.UKismetMathLibrary.FClamp(NewPosition.Y, LimitPosition.Y,LimitPosition.Y + LimitSize.Y - ImgSize.Y * (1- CurAlignment.Y))
        end
    end
	Widget.Slot:SetPosition(NewPosition)
end

-- --水平翻转
function VehicleSkinStickerEditUtil.DoHorizontalFlip()
    ---VehicleSkinStickerEditUtil.EditingPanel.RenderTransform.Scale.X = VehicleSkinStickerEditUtil.EditingPanel.RenderTransform.Scale.X * -1
    VehicleSkinStickerEditUtil.Scale.X = VehicleSkinStickerEditUtil.Scale.X * -1
    VehicleSkinStickerEditUtil.PostTransformChg()
end

-- 镜像翻转
function VehicleSkinStickerEditUtil.DoMirrorFlip()
    VehicleSkinStickerEditUtil.Scale.X = VehicleSkinStickerEditUtil.Scale.X * -1
    VehicleSkinStickerEditUtil.Scale.Y = VehicleSkinStickerEditUtil.Scale.Y * -1

    -- VehicleSkinStickerEditUtil.EditingPanel.RenderTransform.Scale.X = VehicleSkinStickerEditUtil.EditingPanel.RenderTransform.Scale.X * -1
    -- VehicleSkinStickerEditUtil.EditingPanel.RenderTransform.Scale.Y = VehicleSkinStickerEditUtil.EditingPanel.RenderTransform.Scale.Y * -1
    VehicleSkinStickerEditUtil.PostTransformChg()
end

function VehicleSkinStickerEditUtil.PostTransformChg()
    if VehicleSkinStickerEditUtil.EditingPanel == nil then
        return
    end
    if VehicleSkinStickerEditUtil.EditView then
        local CurPosition = VehicleSkinStickerEditUtil.EditingPanel.Slot:GetPosition()
        local CurAlignment = VehicleSkinStickerEditUtil.EditingPanel.Slot:GetAlignment()
        local Size = VehicleSkinStickerEditUtil.EditingPanel.Slot:GetSize()
        -- 在改变大小的时候，会改变Alignment。这里要将坐标换算回Alignment0,0下的传递给外部
        CurPosition.X = CurPosition.X -  CurAlignment.X * Size.X
        CurPosition.Y = CurPosition.Y -  CurAlignment.Y * Size.Y
        local CurRotation = VehicleSkinStickerEditUtil.EditingPanel.RenderTransform.Angle
        local CurScale = VehicleSkinStickerEditUtil.EditingPanel.RenderTransform.Scale -- 仅记录翻转
        local InitSize = VehicleSkinStickerEditUtil.InitSize 
    
        local ChangeData = {
            Position = {X = CurPosition.X + Size.X / 2, Y = CurPosition.Y + Size.Y / 2 },
            --Scale = {X = Size.X/InitSize.X * CurScale.X , Y = Size.Y/InitSize.Y * CurScale.Y},
            Scale = VehicleSkinStickerEditUtil.Scale,
            RotateAngle = CurRotation,
            -- Size是加入了编辑边缘宽度EditBoxSize后的尺寸，计算缩放比例需要将尺寸减去再和初始尺寸相比
            ScaleLength = (Size.X - VehicleSkinStickerEditUtil.EditBoxSize*2) / InitSize.X * CurScale.X,
        }
        if ChangeData.RotateAngle < 0 then
            ChangeData.RotateAngle = 360 + ChangeData.RotateAngle
        end
        VehicleSkinStickerEditUtil.EditView:SetEditInfoTransform(ChangeData)
    end
end



return VehicleSkinStickerEditUtil