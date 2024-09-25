--[[
    通用的CommonRotationLerp控件: 用于旋转Lerp
    local Param = {
        ActorInst,
        ActorComponentInst,
        DeltaRotation,
        PitchLimit = 
        {
            Min,
            Max,
        },
    }
]]

local class_name = "CommonRotationLerp"
CommonRotationLerp = CommonRotationLerp or BaseClass(nil, class_name)


--LERP时间
CommonRotationLerp.LERP_TIME = 0.3

function CommonRotationLerp:Start(Param)
    self.Param = Param
    if self.Param.ActorInst == nil and 
        self.Param.ActorComponentInst == nil then
        return
    end

    if not self.IsStartLerp then
		self.IsStartLerp = true
		self.StartLerpTimerPass = 0
		local CurRotation = self.Param.ActorInst and self.Param.ActorInst:K2_GetActorRotation() or self.Param.ActorComponentInst:K2_GetComponentRotation()
		self.BeginRotation = CurRotation
		self.TargetRotation = CurRotation + self.Param.DeltaRotation
	else
		self.TargetRotation = self.TargetRotation + self.Param.DeltaRotation
	end

    if self.Param.PitchLimit then
        self.TargetRotation.Pitch = UE.UKismetMathLibrary.FClamp(self.TargetRotation.Pitch, self.Param.PitchLimit.Min, self.Param.PitchLimit.Max)
    end

    self:AddTickHandler()
end

function CommonRotationLerp:End()
    self:RemoveTickHandler()
end

function CommonRotationLerp:AddTickHandler()
    if self.TickHandler ~= nil then
        return
    end
    self.TickHandler = Timer.InsertTimer(0,function (deltaTime)
        self:OnTickEvent(deltaTime)
    end,true)
end

function CommonRotationLerp:RemoveTickHandler()
    if self.TickHandler then
        Timer.RemoveTimer(self.TickHandler)
        self.TickHandler = nil
    end
end

function CommonRotationLerp:IsLerping()
    return self.IsStartLerp or false
end

function CommonRotationLerp:OnTickEvent(DeltaSeconds)
    if self.Param.ActorInst == nil and
        self.Param.ActorComponentInst == nil then
        return
    end
    if not self.IsStartLerp then
        return
	end

    if not self.StartLerpTimerPass then
        return 
    end

    self.StartLerpTimerPass = self.StartLerpTimerPass + DeltaSeconds
    local Aplha = self.StartLerpTimerPass / CommonRotationLerp.LERP_TIME
    if Aplha >= 1 then
        self.StartLerpTimerPass = nil
        self.IsStartLerp = false
    end
    Aplha = math.min(Aplha, 1)

    local CurInterpRotation = UE.UKismetMathLibrary.RLerp(self.BeginRotation,
        self.TargetRotation, Aplha, false)  

    if self.Param.ActorInst then
        self.Param.ActorInst:K2_SetActorRotation(CurInterpRotation,false)
    else 
        self.Param.ActorComponentInst:K2_SetRelativeRotation(CurInterpRotation, false, UE.FHitResult(), false)
    end
    MvcEntry:GetModel(InputModel):DispatchType(InputModel.ON_TOUCH_LERP)
end



return CommonRotationLerp
