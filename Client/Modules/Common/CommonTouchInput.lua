--[[
    通用处理Touch输入，进而转到HallAvatarBase
]] local class_name = "CommonTouchInput"
CommonTouchInput = CommonTouchInput or BaseClass(nil, class_name)


--检查移动偏移最小值
CommonTouchInput.TOUCH_INPUT_MIN_X = 0
CommonTouchInput.TOUCH_INPUT_MIN_Y = 0

--长度兑换成度数
CommonTouchInput.LENGTH2DEGREE = 5


function CommonTouchInput:OnInit()
    self.BindUniNodes = {
        { UDelegate =  self.View.TouchImage.OnMouseButtonDownEvent,	Func = Bind(self, self.OnMouseButtonDown) },
        { UDelegate =  self.View.TouchImage.OnMouseButtonUpEvent,	Func = Bind(self, self.OnMouseButtonUp) },
        { UDelegate =  self.View.TouchImage.OnMouseMoveEvent,	Func = Bind(self, self.OnMouseMove) },
        { UDelegate =  self.View.TouchImage.OnMouseLeaveEvent,	Func = Bind(self, self.OnMouseLeave) },
    }
end

function CommonTouchInput:OnShow(Param)
    self.Param = Param
end

function CommonTouchInput:OnHide()
    self.Param = nil

    self.BeginScreenSpacePos = {X = 0, Y = 0}
    self.BeginTouch = false
end

function CommonTouchInput:OnMouseButtonDown(Handler, Geometry, MouseEvent)
    local MouseKey = UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(MouseEvent)
    if MouseKey.KeyName == "RightMouseButton" then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    self.BeginScreenSpacePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    self.BeginTouch = true
    return UE.UWidgetBlueprintLibrary.Handled()
end

function CommonTouchInput:OnMouseButtonUp(Handler, Geometry, MouseEvent)
    self.BeginTouch = false
    MvcEntry:GetModel(InputModel):DispatchType(InputModel.ON_END_TOUCH)
    return UE.UWidgetBlueprintLibrary.Handled()
end


function CommonTouchInput:OnMouseMove(Handler, Geometry, MouseEvent)
    if not self.BeginTouch then
        return UE.UWidgetBlueprintLibrary.Unhandled()
    end
    local CurScreenSpacePos = UE.UKismetInputLibrary.PointerEvent_GetScreenSpacePosition(MouseEvent)
    if CurScreenSpacePos.X == 0 or CurScreenSpacePos.Y == 0 then
        return UE.UWidgetBlueprintLibrary.Unhandled()
    end
    local DeltaX = CurScreenSpacePos.X - self.BeginScreenSpacePos.X
    local DeltaY = CurScreenSpacePos.Y - self.BeginScreenSpacePos.Y
    if math.abs(DeltaX) > 0 or math.abs(DeltaY) > 0 then
        MvcEntry:GetModel(InputModel):DispatchType(InputModel.ON_BEGIN_TOUCH)
    end

    DeltaX = math.abs(DeltaX) > CommonTouchInput.TOUCH_INPUT_MIN_X and DeltaX or 0
    DeltaY = math.abs(DeltaY) > CommonTouchInput.TOUCH_INPUT_MIN_Y and DeltaY or 0
    if DeltaX ~= 0 or DeltaY ~= 0 then
        MvcEntry:GetModel(InputModel):DispatchType(InputModel.ON_COMMON_TOUCH_INPUT, 
            {X = DeltaX / CommonTouchInput.LENGTH2DEGREE , Y = DeltaY / CommonTouchInput.LENGTH2DEGREE})
        self.BeginScreenSpacePos = CurScreenSpacePos  
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end


function CommonTouchInput:OnMouseLeave(Handler, Geometry, MouseEvent)
    self.BeginTouch = false
    MvcEntry:GetModel(InputModel):DispatchType(InputModel.ON_END_TOUCH, true)
    return UE.UWidgetBlueprintLibrary.Handled()
end



return CommonTouchInput
