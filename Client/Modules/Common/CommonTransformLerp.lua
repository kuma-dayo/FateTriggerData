--[[
    通用的CommonTransformLerp控件: 用于旋转Lerp
    local Param = 
    {
       ActorInst, 
       TargetTransform,
       LerpTime = 0.3
       LerpType = 1 -- UE.ELerpInterpolationMode.QuatInterp,EulerInterp,DualQuatInterp
       Curve, --使用定制曲线
    }
]]

local class_name = "CommonTransformLerp"
CommonTransformLerp = CommonTransformLerp or BaseClass(nil, class_name)


function CommonTransformLerp:Start(Param)
    self.Param = Param
    if self.Param.ActorInst == nil then
        return
    end
    if self.Param.TargetTransform == nil then
        return
    end

    self.LerpTime = self.Param.LerpTime or 0.3
    self.LerpType = self.Param.LerpType  or UE.ELerpInterpolationMode.QuatInterp
    self.LerpCurve = self.Param.LerpCurve

    self.TargetTransform = self.Param.TargetTransform
    if not self.IsStartLerp then
		self.IsStartLerp = true
        self:UpdateTransform(self.Param.TargetTransform)
    else
        --重新开始
		self.StartLerpTimerPass = 0
        if self.Param.Reset then
            self:UpdateTransform(self.Param.TargetTransform)
        end
	end

    self:AddTickHandler()
end

function CommonTransformLerp:End()
    self:RemoveTickHandler()
end

function CommonTransformLerp:AddTickHandler()
    if self.TickHandler ~= nil then
        return
    end
    self.TickHandler = Timer.InsertTimer(0,function (deltaTime)
        self:OnTickEvent(deltaTime)
    end,true)
end

function CommonTransformLerp:RemoveTickHandler()
    if self.TickHandler then
        Timer.RemoveTimer(self.TickHandler)
        self.TickHandler = nil
    end
end

function CommonTransformLerp:IsLerping()
    return self.IsStartLerp or false
end

function CommonTransformLerp:UpdateTransform(TargetTransform)
    self.StartLerpTimerPass = 0
    self.TargetTransform = TargetTransform
    local Location = self.Param.ActorInst:K2_GetActorLocation()
    local Rotation = self.Param.ActorInst:K2_GetActorRotation()
    local Scale = self.Param.ActorInst:GetActorScale3D()
    self.CurTransform = UE.UKismetMathLibrary.MakeTransform(Location, Rotation, Scale)
end

function CommonTransformLerp:OnTickEvent(DeltaSeconds)
    if self.Param.ActorInst == nil then
        return
    end
    if not self.IsStartLerp then
        return
	end

    if not self.StartLerpTimerPass then
        return 
    end

    self.StartLerpTimerPass = self.StartLerpTimerPass + DeltaSeconds
    local Value = self.StartLerpTimerPass / self.LerpTime
    Value = math.min(Value, 1)
    local Aplha = self.LerpCurve and self.LerpCurve:GetFloatValue(Value) or Value
    if Aplha >= 1 then
        self.StartLerpTimerPass = nil
        self.IsStartLerp = false
    end

    local CurInterpTransform = UE.UKismetMathLibrary.TLerp(self.CurTransform, self.TargetTransform, Aplha, self.LerpType)  
    self.Param.ActorInst:K2_SetActorTransform(CurInterpTransform, false, UE.FHitResult(), false)

    if self.Param.ChgCameraFoucsSetting2ActorComponentInst then
        local Param = {
            FocusMethod = UE.ECameraFocusMethod.Tracking,
            RelativeOffset = self.Param.ActorComponentInst and self.Param.ActorComponentInst:K2_GetComponentLocation() or self.Param.ActorInst:K2_GetActorLocation()
        }
        MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_CAMERA_FOCUSSETTING_CHANGE,Param)
    end
end



return CommonTransformLerp
