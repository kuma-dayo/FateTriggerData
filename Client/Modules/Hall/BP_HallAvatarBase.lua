require "UnLua"
require("Client.Modules.Common.CommonTransformLerp")

local BP_HallAvatarBase = Class()


function BP_HallAvatarBase:ReceiveBeginPlay()
	CWaring("BP_HallAvatarBase ReceiveBeginPlay")
	self.Overridden.ReceiveBeginPlay(self)

	-- 通用的插值
	self.CommonTransformLerpInst = CommonTransformLerp.New()

    self.PlatformName = UE.UGameplayStatics.GetPlatformName()

    self:OpenOrCloseAvatorRotate(true)
    self:OpenOrCloseCameraAction(true)
	-- self:OpenOrCloseCameraMoveAction(true)
	self:OpenOrCloseGestureAction(true)
	self:OpenOrCloseAutoRotateAction(false)
	self:OpenOrCloseRightMouseAction(false)

	self:InitRotate()

	self:InitAvatarSkin()

	self:InitApparelSlotTypeList()
end

function BP_HallAvatarBase:ReceiveEndPlay(EndPlayReason)
	-- CWaring("BP_HallAvatarBase ReceiveEndPlay")
	self.Overridden.ReceiveEndPlay(self,EndPlayReason)
    self:OpenOrCloseAvatorRotate(false)
    self:OpenOrCloseCameraAction(false)
	self:OpenOrCloseCameraMoveAction(false)
	self:OpenOrCloseGestureAction(false)
	self:OpenOrCloseRightMouseAction(false)
	self:DestroyAvatarSkin()
end

function BP_HallAvatarBase:ReceiveDestroyed()
	self.Overridden.ReceiveDestroyed(self)
	-- CWaring("BP_HallAvatarBase ReceiveDestroyed")
end

function BP_HallAvatarBase:IsAvatarValid()
	if self.bHidden then
		return false
	end
	return true
end

----【皮肤相关功能】-----
function BP_HallAvatarBase:InitAvatarSkin()
	self.SkinId2AvatorActor = {}
	self.CurShowSkinId = 0
	self.CameraFocusHeight = 0
end


function BP_HallAvatarBase:DestroyAvatarSkin()
	for k,v in pairs(self.SkinId2AvatorActor) do
		if CommonUtil.IsValid(v) then
			v:K2_DestroyActor()
		end
	end
	self.SkinId2AvatorActor = {}
	self.CurShowSkinId = 0
	self.CameraFocusHeight = 0
end

--[[
	获取当前展示的皮肤ID
]]
function BP_HallAvatarBase:GetCurShowSkinId()
	return self.CurShowSkinId
end

function BP_HallAvatarBase:SetSpawnParam(SpawnParam)
	self.CacheSpawnParam = SpawnParam
end

--设置胶囊体大小
function BP_HallAvatarBase:SetCapsuleComponentSize(Radius, HalfHeight)
	if Radius == nil or Radius == 0 then
		return 
	end
	if HalfHeight == nil or HalfHeight == 0 then
		return
	end
	if self.CapsuleComponent == nil then
		return
	end
	self.CapsuleComponent:SetCapsuleRadius(Radius)
	self.CapsuleComponent:SetCapsuleHalfHeight(HalfHeight)
end

--- 设置摄像机移动范围
---@param CameraDistanceMax number
---@param CameraDistanceMin number
function BP_HallAvatarBase:SetCameraDistance(CameraDistanceMin, CameraDistanceMax, CameraFocusHeight)
	self:SetCameraBeginLocation()
	if not self.SupportDistance then
		return
	end

	if CameraDistanceMax ~= nil then
		self.CameraDistanceMax = CameraDistanceMax
	end
	if CameraDistanceMin ~= nil then
		self.CameraDistanceMin = CameraDistanceMin
	end
	if CameraFocusHeight ~= nil then
		self.CameraFocusHeight = CameraFocusHeight
	end
end

--- 获取距离相机的距离
function BP_HallAvatarBase:GetDistanceFromCarmera()
	if not self:IsAvatarValid() then
		return 0
	end
	local CameraActor =UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor == nil then
		return 0
	end
	local direction = self:K2_GetActorLocation() - CameraActor:K2_GetActorLocation()
	direction = UE.UKismetMathLibrary.Normal(direction)
	local targetLocation = CameraActor:K2_GetActorLocation() + direction
	local distance = UE.UKismetMathLibrary.Vector_Distance(self:K2_GetActorLocation(),targetLocation)
	return distance
end

function BP_HallAvatarBase:Show(IsShow, SkinId)
	if not IsShow then 
		self:HideCurSkinAvatar()
		self:DoActiveActorInGame(self,false)
		self.CapsuleComponent:SetCollisionEnabled(UE.ECollisionEnabled.NoCollision)	
		self.CurShowSkinId = nil
	else
		self:ShowSkinAvatar(SkinId)
		self:DoActiveActorInGame(self,true)
		self.CapsuleComponent:SetCollisionEnabled(UE.ECollisionEnabled.QueryAndPhysics)
	
		if self.CacheSpawnParam.TrackingFocus then
			local Param = {
				FocusMethod = UE.ECameraFocusMethod.Tracking,
				RelativeOffset = self:K2_GetActorLocation()
			}
			MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_CAMERA_FOCUSSETTING_CHANGE,Param)
		elseif self.CacheSpawnParam.FocusMethodSetting then
			local Param = {
				FocusMethod = self.CacheSpawnParam.FocusMethodSetting.FocusMethod,
				ManualFocusDistance = self.CacheSpawnParam.FocusMethodSetting.ManualFocusDistance or 10000
			}
			MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_CAMERA_FOCUSSETTING_CHANGE,Param)
		else
			local Param = {
				FocusMethod = UE.ECameraFocusMethod.Disable,
				ManualFocusDistance = 10000
			}
			MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_CAMERA_FOCUSSETTING_CHANGE,Param)
		end

		--适配相机推进距离
		if self.CacheSpawnParam.bAdaptCameraDistance then
			self:AdaptCameraDistanceMinAndMax()
		end
	end
end

function BP_HallAvatarBase:CreateAvatorActorByClassBp(ClassBp, ForbidUseRelativeTransform)
	local AvatorClass = UE.UClass.Load(CommonUtil.FixBlueprintPathWithoutPre(ClassBp))
	if AvatorClass == nil then 
		return 
	end

	local CurWorld = self:GetWorld() 
    if CurWorld == nil then
        return 
    end

	local avatorActor = CurWorld:SpawnActor(AvatorClass, 
		UE.FTransform.Identity, 
		UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn,
		self)
	if avatorActor == nil then
		return 
	end
	avatorActor:K2_SetActorRelativeTransform(not ForbidUseRelativeTransform and avatorActor.RelativeTransform or UE.FTransform.Identity, false, nil, false)
	avatorActor:K2_AttachToComponent(self.DefaultSceneRoot,
		"",
		UE.EAttachmentRule.KeepRelative,
		UE.EAttachmentRule.KeepRelative,
		UE.EAttachmentRule.KeepRelative,
		true
	)
	return avatorActor
end

function BP_HallAvatarBase:SpawnSkinAvatar(SkinId, ForbidUseRelativeTransform)
	CError("Please overide this func")
end

function BP_HallAvatarBase:SpawnSkinAvatarAction(SkinId, ClassBp, ForbidUseRelativeTransform)
	if self.SkinId2AvatorActor[SkinId] ~= nil then 
		CWaring("SpawnSkinAvatar Repeate Skinid")
		return
	end

	if ClassBp == nil then 
		return
	end
	local avatarActor = self:CreateAvatorActorByClassBp(ClassBp, ForbidUseRelativeTransform)
	if avatarActor == nil then 
		return 
	end
	self:OpenOrCloseCapture2D(avatarActor,false)
	self.SkinId2AvatorActor[SkinId] = avatarActor
	-- 不能在Show之前，先赋值，否则影响ShowSkinAvatar的判断。在判断完了再赋值。
	--self.CurShowSkinId = SkinId
	return true
end

function BP_HallAvatarBase:GetSkinActor(SkinId)
	SkinId = SkinId or self.CurShowSkinId
	return self.SkinId2AvatorActor[SkinId]
end

function BP_HallAvatarBase:ShowSkinAvatar(SkinID)
	if self.CurShowSkinId ~= SkinID then 
		self:HideCurSkinAvatar()
		self.CurShowSkinId = SkinID
	end
	local CurSkinActor = self.SkinId2AvatorActor[self.CurShowSkinId]
	if CurSkinActor ~= nil then 
		self:DoActiveActorInGame(CurSkinActor,true)

		local LightingChannel = self.CacheSpawnParam.LightingChannel or 0
		if CurSkinActor.SkeletalMesh then
			CurSkinActor.SkeletalMesh:SetLightingChannels(LightingChannel == 0,LightingChannel == 1,LightingChannel == 2)
		end
		if self.CacheSpawnParam.OpenCapture2D then
			self:OpenOrCloseCapture2D(CurSkinActor,true)
		end
	end
end

function BP_HallAvatarBase:HideCurSkinAvatar()
	local AvatorActor = self.SkinId2AvatorActor[self.CurShowSkinId]
	if AvatorActor ~= nil then 
		self:DoActiveActorInGame(AvatorActor,false)
		self:OpenOrCloseCapture2D(AvatorActor,false)
	end
	self:OpenOrCloseRightMouseAction(false)
	self.NeedLerpCamera = false
end

function BP_HallAvatarBase:DoActiveActorInGame(Actor,Active)
	Actor:SetActorHiddenInGame(not Active)	
	Actor:SetActorEnableCollision(Active)	
	Actor:SetActorTickEnabled(Active)
end

function BP_HallAvatarBase:OpenOrCloseCapture2D(CurSkinActor,IsOpen)
	if not CurSkinActor then
		return
	end
	if not CurSkinActor.SceneCapture2D then
		return
	end

	CurSkinActor.SceneCapture2D:SetActive(IsOpen)
	CurSkinActor.SceneCapture2D:SetComponentTickEnabled(IsOpen)
	if IsOpen then
		CurSkinActor.SceneCapture2D.PostProcessSettings.bOverride_DynamicGlobalIlluminationMethod = true
		CurSkinActor.SceneCapture2D.ShowOnlyActors:Add(CurSkinActor)
	else
		--SceneCapture用不到时不勾选Lumen，结算要用时候动态勾选, 避免游戏启动时候发生Ensure
		CurSkinActor.SceneCapture2D.PostProcessSettings.bOverride_DynamicGlobalIlluminationMethod = false
		CurSkinActor.SceneCapture2D.ShowOnlyActors:Clear()
	end
end


----【通用相机控制】-----

--打开或者关闭  控制相机动作（FOV修改）
function BP_HallAvatarBase:OpenOrCloseCameraAction(bValue, CameraConfigType)
    if bValue then
		self:ApplyCameraScrollConfigByKey(CameraConfigType)
        MvcEntry:GetModel(InputModel):AddListener(ActionPressed_Event(ActionMappings.MouseScrollUp),self.OnMouseScrollUp,self)
        MvcEntry:GetModel(InputModel):AddListener(ActionPressed_Event(ActionMappings.MouseScrollDown),self.OnMouseScrollDown,self)
    else
        MvcEntry:GetModel(InputModel):RemoveListener(ActionPressed_Event(ActionMappings.MouseScrollUp),self.OnMouseScrollUp,self)
	    MvcEntry:GetModel(InputModel):RemoveListener(ActionPressed_Event(ActionMappings.MouseScrollDown),self.OnMouseScrollDown,self)
    end
end

function BP_HallAvatarBase:OpenOrCloseCameraMoveAction(bValue)
	if bValue then
		MvcEntry:GetModel(InputModel):AddListener(EnhanceInputActionTriggered_Event(AxisMappings.MoveRight),self.OnMoveRightAction,self)
		MvcEntry:GetModel(InputModel):AddListener(EnhanceInputActionTriggered_Event(AxisMappings.MoveForward),self.OnMoveForwardAction,self)
		MvcEntry:GetModel(InputModel):AddListener(EnhanceInputActionTriggered_Event(AxisMappings.TurnRate),self.OnMoveRightAction,self)
    else
		MvcEntry:GetModel(InputModel):RemoveListener(EnhanceInputActionTriggered_Event(AxisMappings.MoveRight),self.OnMoveRightAction,self)
		MvcEntry:GetModel(InputModel):RemoveListener(EnhanceInputActionTriggered_Event(AxisMappings.MoveForward),self.OnMoveForwardAction,self)
		MvcEntry:GetModel(InputModel):RemoveListener(EnhanceInputActionTriggered_Event(AxisMappings.TurnRate),self.OnMoveRightAction,self)
    end
end

function BP_HallAvatarBase:OpenOrCloseGestureAction(bValue)
	if bValue then
		MvcEntry:GetModel(InputModel):AddListener(EnhanceInputActionTriggered_Event(AxisMappings.Pinch),self.OnPinchAction,self)
    else
		MvcEntry:GetModel(InputModel):RemoveListener(EnhanceInputActionTriggered_Event(AxisMappings.Pinch),self.OnPinchAction,self)
    end
end

function BP_HallAvatarBase:OpenOrCloseRightMouseAction(bValue, CameraConfigType)
	if bValue then
		self:ApplyCameraMoveConfigByKey(CameraConfigType)
		MvcEntry:GetModel(InputModel):AddListener(ActionPressed_Event(ActionMappings.RightMousePress),self.RightMouseButtonPressFunc,self)
		MvcEntry:GetModel(InputModel):AddListener(ActionPressed_Event(ActionMappings.RightMouseRelease),self.RightMouseButtonReleaseFunc,self)
    else
		MvcEntry:GetModel(InputModel):RemoveListener(ActionPressed_Event(ActionMappings.RightMousePress),self.RightMouseButtonPressFunc,self)
		MvcEntry:GetModel(InputModel):RemoveListener(ActionPressed_Event(ActionMappings.RightMouseRelease),self.RightMouseButtonReleaseFunc,self)
    end
end

function BP_HallAvatarBase:SetCameraBeginLocation()
	local CameraActor =UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor ~= nil then
		self.CameraBeginLocation = CameraActor:K2_GetActorLocation()
	end
end

function BP_HallAvatarBase:RightMouseButtonPressFunc()
    -- CWaring("==============RightMouseButtonPressFunc")
    self.IsRightMouseButtonPress = true
	self.NeedEndLerpCamera = false
	local localPC = CommonUtil.GetLocalPlayerC()
	if localPC == nil then 
		return 
	end
	self.MousePosBegin = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
	self.StartLerpTimerPass = 0
	-- print("=================RightMouseButtonPressFunc:", X, Y)
end

function BP_HallAvatarBase:RightMouseButtonReleaseFunc()
    -- CWaring("==============RightMouseButtonReleaseFunc")
    self.IsRightMouseButtonPress = false
	if self.NeedEndLerpCamera then
		self.NeedLerpCamera = true
	end
	self.StartLerpTimerPass = 0
end

function BP_HallAvatarBase:OpenOrCloseAutoRotateAction(bValue)
	self.SupportAutoRotate = bValue
	self:SetAutoRotate(false)
end


--打开或者关闭 控制Avatar旋转
function BP_HallAvatarBase:OpenOrCloseAvatorRotate(bValue)
    if bValue then
        if self.PlatformName == "Windows" then
            --FOR WINDOWS
            self.CapsuleComponent.OnClicked:Add(self, self.OnInputClicked)
            self.CapsuleComponent.OnReleased:Add(self, self.OnInputReleased)
			self.CapsuleComponent.OnEndCursorOver:Add(self, self.OnInputEndCursorOver)
        else
            --FOR MOBILE
            self.CapsuleComponent.OnInputTouchBegin:Add(self, self.OnInputTouchBegin)
            self.CapsuleComponent.OnInputTouchEnd:Add(self, self.OnInputTouchEnd)
			self.CapsuleComponent.OnInputTouchLeave:Add(self, self.OnInputTouchLeave)
        end
    else
        --FOR MOBILE
        self.CapsuleComponent.OnInputTouchBegin:Remove(self, self.OnInputTouchBegin)
        self.CapsuleComponent.OnInputTouchEnd:Remove(self, self.OnInputTouchEnd)
		self.CapsuleComponent.OnInputTouchLeave:Remove(self, self.OnInputTouchLeave)

        -- --FOR WINDOWS
        self.CapsuleComponent.OnClicked:Remove(self, self.OnInputClicked)
        self.CapsuleComponent.OnReleased:Remove(self, self.OnInputReleased)
		self.CapsuleComponent.OnEndCursorOver:Remove(self, self.OnInputEndCursorOver)
    end
end

--[[
	是否禁用后处理效果
]]
function BP_HallAvatarBase:SetDisablePostProcessBlueprint(Value)
	local AvatarActor = self:GetSkinActor()
	if not AvatarActor then
		return
	end
	local SkeletalMesh = AvatarActor:GetSkeletalMesh()
	if SkeletalMesh then 
		SkeletalMesh:SetDisablePostProcessBlueprint(Value)
	end
end

function BP_HallAvatarBase:InitRotate()
	self.TouchFingerIndex = 0
	self.LocationX = 0
	self.LocationY = 0
	self.IsPressed = false
	self.OrgRotation = self:K2_GetActorRotation()
	self.RecoverTimerPass = nil
	self.RecoverTimerPassOrgRotation = nil
	self.RecoverTimerPassTargetRotation = nil
end

function BP_HallAvatarBase:SetAutoRotate(Val)
	self.IsAutoRotate = Val
	MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.HALL_AVATAR_AUTO_ROTATE, {AvatarActor = self, AutoRoate = Val, AutoRotateSpeed = self.AutoRotateSpeed})
end



--FOR MOBILE
function BP_HallAvatarBase:OnInputTouchBegin(FingerIndex, TouchedComponent)
	self.TouchFingerIndex = FingerIndex
	self.IsPressed = true
	self:SetAutoRotate(false)
	self.LocationX, self.LocationY = self:GetTouchLocation()
end

function BP_HallAvatarBase:OnInputTouchEnd(FingerIndex, TouchedComponent)
	self.IsPressed = false
	MvcEntry:GetModel(InputModel):DispatchType(InputModel.ON_END_TOUCH)
end

function BP_HallAvatarBase:OnInputTouchLeave(FingerIndex, TouchedComponent)
	self.IsPressed = false
	MvcEntry:GetModel(InputModel):DispatchType(InputModel.ON_END_TOUCH)
end


function BP_HallAvatarBase:GetTouchLocation()
	local localPC = CommonUtil.GetLocalPlayerC()
	if localPC ~= nil then
		local X, Y, IsCurrentlyPressed = localPC:GetInputTouchState(self.TouchFingerIndex)
		return X, Y
	end
	return 0, 0
end

function BP_HallAvatarBase:UpdateTouchRotate()
	local X, Y = self:GetTouchLocation()
	local deltaX,deltaY = self:CalculateRotateValue(X,Y)
	local addRotaion = UE.FRotator(-deltaY, deltaX, 0)
	if math.abs(deltaX) > 0 or math.abs(deltaY) > 0 then
		MvcEntry:GetModel(InputModel):DispatchType(InputModel.ON_BEGIN_TOUCH)
	end
	
	--[[
		对摄像机的旋转偏移做反处理
		因为仓库场景中的相机不是正的，有角度调整，所以世界中的坐标系和相机本地坐标系的旋转是不同的
		导致直接旋转的效果会变得很奇怪，所以需要根据相机的旋转调整一下物品的旋转，等做完最终的旋转后再反回去
	]]
	--对摄像机的旋转偏移做反处理
	local _CameraRotation = self:GetCurrentSceneCameraRotation()
	local _Rotation = self:K2_GetActorRotation()
	_Rotation.Yaw 	= _Rotation.Yaw   - _CameraRotation.Yaw
	_Rotation.Pitch = _Rotation.Pitch - _CameraRotation.Pitch
	_Rotation.Roll 	= _Rotation.Roll  - _CameraRotation.Roll
	self:K2_SetActorRotation(_Rotation, false)

	--真正处理旋转
	local sweepHitResult
	self:K2_AddActorWorldRotation(addRotaion, false, sweepHitResult, false)

	--对摄像机的旋转偏移做处理
	_Rotation = self:K2_GetActorRotation()
	_Rotation.Yaw 	= _Rotation.Yaw   + _CameraRotation.Yaw
	_Rotation.Pitch = _Rotation.Pitch + _CameraRotation.Pitch
	_Rotation.Roll 	= _Rotation.Roll  + _CameraRotation.Roll
	self:K2_SetActorRotation(_Rotation, false)

	--重置
	self.LocationX = X
	self.LocationY = Y
end



--FOR WINDOWS
function BP_HallAvatarBase:OnInputClicked()
	local localPC = CommonUtil.GetLocalPlayerC()
	if localPC == nil then 
		return 
	end

	self.IsPressed = true
	self:SetAutoRotate(false)
	self.LocationX, self.LocationY = localPC:GetMousePosition()
end

function BP_HallAvatarBase:OnInputReleased()
	self.IsPressed = false
	MvcEntry:GetModel(InputModel):DispatchType(InputModel.ON_END_TOUCH)
end

function BP_HallAvatarBase:OnInputEndCursorOver()
	self.IsPressed = false
	MvcEntry:GetModel(InputModel):DispatchType(InputModel.ON_END_TOUCH)
end

--[[
	ActionValue
	2D平面
	上 1
	下 -1
	左 -1
	右 1
]]
function BP_HallAvatarBase:OnMoveRightAction(FInputActionInstanceExtend)
	if not self:IsAvatarValid() then
		return
	end
	--(FVector DeltaLocation, bool bSweep, FHitResult& SweepHitResult, bool bTeleport);
	if not self.SupportCameraMoveX then
		return
	end
	-- print("ActionValue:" .. ActionValue)
	local ActionValue = FInputActionInstanceExtend.InputActionValueCopy.Value.X
	local CameraActor =UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor == nil then
		return
	end
	-- local ActionValue = InputData.ActionValue.X
	ActionValue = ActionValue * self.CameraMoveXSpeed
	local addLocation = UE.FVector(0, ActionValue, 0)
	CameraActor:K2_AddActorWorldOffset(-addLocation, false, nil, false)
end

function BP_HallAvatarBase:OnMoveForwardAction(FInputActionInstanceExtend)
	if not self:IsAvatarValid() then
		return
	end
	if not self.SupportCameraMoveY then
		return
	end
	-- print("ActionValue:" .. ActionValue)
	local ActionValue = FInputActionInstanceExtend.InputActionValueCopy.Value.X
	local CameraActor =UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor == nil then
		return
	end
	-- local ActionValue = InputData.ActionValue.X
	ActionValue = ActionValue * self.CameraMoveYSpeed
	local addLocation = UE.FVector(0, 0, ActionValue)
	CameraActor:K2_AddActorWorldOffset(-addLocation, false, nil, false)
end

function BP_HallAvatarBase:OnPinchAction(FInputActionInstanceExtend)
	local ActionValue = FInputActionInstanceExtend.InputActionValueCopy.Value.X
	if self.PinchActionValue ~= ActionValue then 
		self.PinchActionValue = ActionValue

		if ActionValue > 1 then
			self:UpdateCameraTranslation(false)
		else
			self:UpdateCameraTranslation(true)
		end
	end
end

---获取当前场景下的摄像机旋转
function BP_HallAvatarBase:GetCurrentSceneCameraRotation()
	local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor == nil then
		return UE.FRotator(0, 0, 0)
	end

	return CameraActor:K2_GetActorRotation()
end

function BP_HallAvatarBase:UpdateMouseRotate()
	local localPC = CommonUtil.GetLocalPlayerC()
	if localPC == nil then 
		return 
	end

	local X, Y = localPC:GetMousePosition()
	local deltaX,deltaY = self:CalculateRotateValue(X,Y)
	local sweepHitResult
	local addRotaion = UE.FRotator(-deltaY, deltaX, 0)
	if math.abs(deltaX) > 0 or math.abs(deltaY) > 0 then
		MvcEntry:GetModel(InputModel):DispatchType(InputModel.ON_BEGIN_TOUCH)
	end
	
	--对摄像机的旋转偏移做反处理
	--因为仓库场景中的相机不是正的，有角度调整，所以世界中的坐标系和相机本地坐标系的旋转是不同的
	--导致直接旋转的效果会变得很奇怪，所以需要根据相机的旋转调整一下物品的旋转，等做完最终的旋转后再反回去
	local _CameraRotation = self:GetCurrentSceneCameraRotation()
	local _Rotation = self:K2_GetActorRotation()
	_Rotation.Yaw 	= _Rotation.Yaw   - _CameraRotation.Yaw  
	_Rotation.Pitch = _Rotation.Pitch - _CameraRotation.Pitch
	_Rotation.Roll 	= _Rotation.Roll  - _CameraRotation.Roll 
	self:K2_SetActorRotation(_Rotation, false)
	
	--真正处理旋转
	self:K2_AddActorWorldRotation(addRotaion, false, sweepHitResult, false)

	--对摄像机的旋转偏移做处理
	_Rotation = self:K2_GetActorRotation()
	_Rotation.Yaw 	= _Rotation.Yaw   + _CameraRotation.Yaw
	_Rotation.Pitch = _Rotation.Pitch + _CameraRotation.Pitch
	_Rotation.Roll 	= _Rotation.Roll  + _CameraRotation.Roll
	self:K2_SetActorRotation(_Rotation, false)

	--重置
	self.LocationX = X
	self.LocationY = Y
end

function BP_HallAvatarBase:OnMouseScrollUp()
	self:UpdateCameraTranslation(false)
end

function BP_HallAvatarBase:OnMouseScrollDown()
	self:UpdateCameraTranslation(true)
end

function BP_HallAvatarBase:UpdateCameraTranslation(IsBackward)
	if not self:IsAvatarValid() then
		return
	end
	local CameraActor =UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor == nil then
		return
	end
	-- CWaring("UpdateCameraTranslation")
	if self.SupportFov == true then
		-- CWaring("UpdateCameraTranslation1")
		--TODO 走FOV变换
		local FieldOfViewFix = CameraActor.CameraComponent.FieldOfView + (IsBackward and (self.FovScrollStep) or -self.FovScrollStep)
		FieldOfViewFix = math.min(FieldOfViewFix,self.FovMax)
		FieldOfViewFix = math.max(FieldOfViewFix,self.FovMin)
		-- CWaring("FieldOfViewFix:" .. FieldOfViewFix)
		CameraActor.CameraComponent:SetFieldOfView(FieldOfViewFix)
	elseif self.SupportDistance == true then
		-- CWaring("UpdateCameraTranslation2:" .. self.CameraDistanceScrollSpeed)
		-- CWaring("功能未做")
		local Location = self:K2_GetActorLocation() + UE.FVector(0, 0, self.CameraFocusHeight)
		local direction = Location - CameraActor:K2_GetActorLocation()
		-- direction.Normalize()
		local DirNormal = UE.UKismetMathLibrary.Normal(direction)
		direction = (IsBackward and -DirNormal or DirNormal) * self.CameraDistanceScrollSpeed
		-- print(direction)
		local targetLocation = CameraActor:K2_GetActorLocation() + direction
		-- local distance = 
		local distance = UE.UKismetMathLibrary.Vector_Distance(Location,targetLocation)
		-- repeat
		-- 	if distance > self.CameraDistanceMax then
		-- 		CWaring("distance to actor too far,now distance is:" .. distance)
		-- 		break
		-- 	end
		-- 	if distance < self.CameraDistanceMin then
		-- 		CWaring("distance to actor too close,now distance is:" .. distance)
		-- 		break
		-- 	end
		-- 	-- CameraActor:K2_AddActorWorldOffset(direction, false, nil, false)
		-- 	CameraActor:K2_SetActorLocation(targetLocation, false, nil, false)
		-- until true
		
		if distance > self.CameraDistanceMax then
			targetLocation = Location - DirNormal * self.CameraDistanceMax
		end
		if distance < self.CameraDistanceMin then
			targetLocation = Location - DirNormal * self.CameraDistanceMin
		end

		if self.CommonTransformLerpInst then
			local Rotation = CameraActor:K2_GetActorRotation()
			local Scale = UE.FVector(1.0, 1.0, 1.0)

			local TargetTranform = UE.UKismetMathLibrary.MakeTransform(targetLocation, Rotation, Scale)
			local Param = 
			{
				ActorInst = CameraActor,
				TargetTransform = TargetTranform,
				LerpTime = self.CameraDistanceScrollLerpTime,
				LerpType = self.CameraDistanceScrollLerpType,
				LerpCurve = self.CameraDistanceScrollFloatCurve,
				Reset = true
			}
			self.CommonTransformLerpInst:Start(Param)
			-- end
		end
	else
		CWaring("不支持相机推进")
		-- CWaring("UpdateCameraTranslation3")
	end
	-- CWaring("UpdateCameraTranslation4")
end


function BP_HallAvatarBase:StopTransformLerp()
	if self.CommonTransformLerpInst then
		self.CommonTransformLerpInst:End()
	end
end

---适配相机推进距离,目的是将配的 self.CameraDistanceMax,self.CameraDistanceMin 适配到一个合理的范围内。
function BP_HallAvatarBase:AdaptCameraDistanceMinAndMax()
	local distance = self:GetDistanceFromCarmera()
	if distance > self.CameraDistanceMax then
		-- CWaring(string.format("AdaptCameraDistanceMinAndMax : distance > self.CameraDistanceMax => %s > %s",tostring(distance), tonumber(self.CameraDistanceMax)))
		self:SetCameraDistance(self.CameraDistanceMin, distance)
	elseif distance < self.CameraDistanceMin then
		-- CWaring(string.format("AdaptCameraDistanceMinAndMax : distance < self.CameraDistanceMin => %s < %s",tostring(distance), tonumber(self.CameraDistanceMin)))
		self:SetCameraDistance(distance, self.CameraDistanceMax)
	end
end
--//


--FOR Common
function BP_HallAvatarBase:ReceiveTick(DeltaSeconds)
	if not self.IsPressed then 
		if self.SupportRotateRecover then
			if not self.RecoverTimerPassOrgRotation and self.RecoverTimerPass then
				--排除Z轴，计算模型前方一个点根据当前旋转之后的位置，再计算角度
				local CurRotation = self:K2_GetActorRotation()
				local FrontPoint = UE.FVector(100, 0, 0)
				local NewPointLocation = UE.UKismetMathLibrary.GreaterGreater_VectorRotator(FrontPoint, CurRotation)
				NewPointLocation.Z = 0
				local NewPointRotation = UE.UKismetMathLibrary.FindLookAtRotation(UE.FVector(0, 0, 0), NewPointLocation)		
				local TargetRotation = UE.FRotator(CurRotation.Pitch, NewPointRotation.Yaw, CurRotation.Roll)
				
				--如果Roll大于90°，就说明进行了一个翻转，测试100°效果比较好，顾留下此Magic Number
				-- if math.abs(CurRotation.Roll) > 100 then
				-- 	--翻面的时候，不需要移动Yaw，只需要对Pitch和Roll进行翻转即可。
				-- 	--为了转正，需要最后值为 0 或 180
				-- 	if CurRotation.Roll > 0 then
				-- 		TargetRotation.Pitch = 180
				-- 		TargetRotation.Roll = 180
				-- 	else
				-- 		TargetRotation.Pitch = -180
				-- 		TargetRotation.Roll = -180
				-- 	end
				-- else
				-- 	TargetRotation.Pitch = self.OrgRotation.Pitch
				-- 	TargetRotation.Roll = self.OrgRotation.Roll
				-- end
				
				-- 需求改为松手后回归原始角度，不需要上面的Roll的翻转判断 @chenyishui
				TargetRotation.Pitch = self.OrgRotation.Pitch
				TargetRotation.Roll = self.OrgRotation.Roll
				TargetRotation.Yaw = self.OrgRotation.Yaw
				if CurRotation.Yaw < -90 then
					-- 避免回归过程中通过另一边转一圈返回
					CurRotation.Yaw = 360 + CurRotation.Yaw
				end
				
				--设置为最终旋转角度及初始旋转数据
				self.RecoverTimerPassOrgRotation = CurRotation
				self.RecoverTimerPassTargetRotation = TargetRotation
			end
			self:RecoverRotation(DeltaSeconds)
		else
			self:AutoRotate(DeltaSeconds)
		end
	else
		self.RecoverTimerPass = 0
		self.RecoverTimerPassOrgRotation = nil
		if self.PlatformName == "Windows" then
			self:UpdateMouseRotate() 
		else
			self:UpdateTouchRotate() 
		end
	end

	if self.IsRightMouseButtonPress then
		self:UpdateCameraPosition(DeltaSeconds)
	end
	self:TickLerpCamera(DeltaSeconds)
end


function BP_HallAvatarBase:TickLerpCamera(DeltaSeconds)
	if not self.NeedLerpCamera or not self.LerpCameraTargetPos then
		return
	end

	local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor == nil then
		return
	end
	self.StartLerpTimerPass = self.StartLerpTimerPass or 0
	self.StartLerpTimerPass = self.StartLerpTimerPass + DeltaSeconds
	local Value = self.StartLerpTimerPass / self.CameraMoveLerpTime
	Value = math.min(Value, 1)
	local Aplha = self.CameraMoveFloatCurve and self.CameraMoveFloatCurve:GetFloatValue(Value) or Value
	local Location = CameraActor:K2_GetActorLocation()
	local Rotation = CameraActor:K2_GetActorRotation()
	local Scale = CameraActor:GetActorScale3D()
	local OriginTrans = UE.UKismetMathLibrary.MakeTransform(Location, Rotation, Scale)
	local TargetTrans = UE.UKismetMathLibrary.MakeTransform(self.LerpCameraTargetPos, Rotation, Scale)
	local CurInterpTransform = UE.UKismetMathLibrary.TLerp(OriginTrans, TargetTrans, Value, self.CameraMoveLerpType)  
	CameraActor:K2_SetActorTransform(CurInterpTransform, false, UE.FHitResult(), false)
	if Value == 1 then
		self.NeedLerpCamera = false
		self.LerpCameraTargetPos = nil
		self.StartLerpTimerPass = 0
	end
end

function BP_HallAvatarBase:UpdateCameraPosition(DeltaSeconds)
	if not self.SupportCameraMove then
		return
	end	
	if not self:IsAvatarValid() then
		return
	end
	local localPC = CommonUtil.GetLocalPlayerC()
	if localPC == nil then 
		return 
	end
	
	local CameraActor =UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor == nil then
		return
	end

	self.NeedLerpCamera = false
	local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform()
	if math.abs(MousePos.X - self.MousePosBegin.X) < 1 and math.abs(- MousePos.Y + self.MousePosBegin.Y) < 1 then
		self.NeedEndLerpCamera = false
		return
	end

	local CurWorld = self:GetWorld() 
    if CurWorld == nil then
        return 
    end
	
	local ViewportSize = UE.UWidgetLayoutLibrary.GetViewportSize(CurWorld)
	local TempDirection = MousePos - self.MousePosBegin
	local ModifyPos = UE.FVector(-TempDirection.X, 0,TempDirection.Y) * self.CameraMoveSpeed
	local ActorPos = self:K2_GetActorLocation()

	--方式一
	-- local CheckPos = function(InDirection, InModifyPos, IsHorizontal)
	-- 	local IsOuter = function()
	-- 		local ActorPos = self:K2_GetActorLocation() - InModifyPos
			
	-- 		if IsHorizontal then
	-- 			if InDirection.X >= 0 then
	-- 				local WorldPos = ActorPos + UE.FVector(self.CameraMoveHorizontalDistanceRight, 0, 0)
	-- 				local Pos = localPC:ProjectWorldLocationToScreen(WorldPos)
	-- 				return Pos.X > ViewportSize.X
	-- 			else
	-- 				local WorldPos = ActorPos + UE.FVector(-self.CameraMoveHorizontalDistanceLeft, 0, 0)
	-- 				local Pos = localPC:ProjectWorldLocationToScreen(WorldPos)
	-- 				return Pos.X <= 0
	-- 			end
	-- 		else
	-- 			if InDirection.Y < 0 then
	-- 				local WorldPos = ActorPos + UE.FVector(0, 0, self.CameraMoveVerticalDistanceUp)
	-- 				local Pos = localPC:ProjectWorldLocationToScreen(WorldPos)
	-- 				-- print("+++++",Pos)
	-- 				return Pos.Y <= 0
	-- 			else
	-- 				local WorldPos = ActorPos + UE.FVector(0, 0, -self.CameraMoveVerticalDistanceDown)
	-- 				local Pos = localPC:ProjectWorldLocationToScreen(WorldPos)
	-- 				-- print("-----",Pos)
	-- 				return Pos.Y > ViewportSize.Y
	-- 			end
	-- 		end
	-- 	end

	-- 	local ReValueModify = function(ModifyValue, IsLower)
	-- 		local IsOutOfLimit = false
	-- 		if IsLower ~= nil and (ModifyValue <= 0 and IsLower or ModifyValue >= 0 and not IsLower) then
	-- 			IsOutOfLimit = true
	-- 			ModifyValue = 0
	-- 		end
	-- 		if IsHorizontal then
	-- 			InModifyPos.X = ModifyValue
	-- 		else
	-- 			InModifyPos.Z = ModifyValue
	-- 		end
	-- 		return IsOutOfLimit
	-- 	end

	-- 	local ModifyValue = IsHorizontal and InModifyPos.X or InModifyPos.Z
	-- 	local Space = ModifyValue < 0 and 1 or -1
	-- 	if IsOuter() then
	-- 		local ExecCount = 0
	-- 		local MaxExecCount = 99999
	-- 		while true do
	-- 			ModifyValue = IsHorizontal and InModifyPos.X or InModifyPos.Z
	-- 			ModifyValue = ModifyValue + Space
				
	-- 			if ReValueModify(ModifyValue, Space < 0) or not IsOuter() then
	-- 				break
	-- 			end

	-- 			ExecCount = ExecCount + 1
	-- 			if ExecCount > MaxExecCount then
	-- 				CWaring("BP_HallAvatarBase break for exec max count")
	-- 				break
	-- 			end
	-- 		end
	-- 	end
	-- 	ReValueModify(ModifyValue, Space < 0)
	-- end
	-- print("=============1", TempDirection, ModifyPos)
	-- CheckPos(TempDirection, ModifyPos, true)
	-- CheckPos(TempDirection, ModifyPos, false)
	-- UE.UKismetSystemLibrary.DrawDebugLine(CurWorld,  PivotLagLocation , PivotLagLocation+PivotTargetLocation*500 ,UE.FLinearColor(1, 1, 1, 1), 100 , 0.01)

	--方式二
	local GetBoundPosition = function(InScreenX, InScreenY)
		local WorldPos,WorldDir = localPC:DeprojectScreenPositionToWorld(InScreenX,InScreenY)
		local DirNormal = UE.UKismetMathLibrary.Normal(WorldDir)
		local ActorNormalDir = UE.FVector(0, 1, 0)
		local ActorNormal = UE.UKismetMathLibrary.Normal(ActorNormalDir)
		local Dot1 = UE.UKismetMathLibrary.Dot_VectorVector(DirNormal , ActorNormal)
		local Dot2 = UE.UKismetMathLibrary.Dot_VectorVector(ActorPos - WorldPos, ActorNormal)
		if Dot2 == 0 then
			CError("GetBoundPosition Dot2 Is Zero")
			return WorldPos
		end
		return DirNormal * Dot2/Dot1 + WorldPos
	end
	local MinPos = GetBoundPosition(0,0)
	local MaxPos = GetBoundPosition(ViewportSize.X,ViewportSize.Y)

	local VirtualPos = ActorPos - ModifyPos

	local DiffX = VirtualPos.X + self.CameraMoveHorizontalDistanceRight - MaxPos.X
	if DiffX > 0 then
		ModifyPos.X = math.min(ModifyPos.X + DiffX, 0)
	else
		DiffX = VirtualPos.X - self.CameraMoveHorizontalDistanceLeft - MinPos.X
		if DiffX < 0 then
			ModifyPos.X = math.max(ModifyPos.X + DiffX, 0)
		end
	end

	local DiffZ = VirtualPos.Z + self.CameraMoveVerticalDistanceUp - MinPos.Z
	if DiffZ > 0 then
		ModifyPos.Z = math.min(ModifyPos.Z + DiffZ, 0)
	else
		DiffZ = VirtualPos.Z - self.CameraMoveVerticalDistanceDown - MaxPos.Z
		if DiffZ < 0 then
			ModifyPos.Z = math.max(ModifyPos.Z + DiffZ, 0)
		end
	end
	
	local NewLocation = CameraActor:K2_GetActorLocation() + ModifyPos
	self.LerpCameraTargetPos = NewLocation
	self.NeedLerpCamera = true
	self.NeedEndLerpCamera = true
	self.StartLerpTimerPass = 0
	self.MousePosBegin = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
end

function BP_HallAvatarBase:SetSetTransformByParam(Location, Rotation, Scale)
	local Trans = UE.UKismetMathLibrary.MakeTransform(Location, Rotation, Scale)
	self:SetTransformInLua(Trans)
end

function BP_HallAvatarBase:SetTransformInLua(Trans)
	self:K2_SetActorTransform(Trans, false, UE.FHitResult(), false)
	--设置为最终旋转角度及初始旋转数据
	-- self.RecoverTimerPassOrgRotation = self:K2_GetActorRotation()
	-- self.RecoverTimerPassTargetRotation = self:K2_GetActorRotation()
	self.RecoverTimerPassOrgRotation = nil
	self.RecoverTimerPassTargetRotation = nil
end

function BP_HallAvatarBase:CalculateRotateValue(X,Y)
	local deltaX = self.LocationX - X
	local deltaY = self.LocationY - Y
	local sweepHitResult
	deltaX = self.SupportRotateX and deltaX or 0
	deltaY = self.SupportRotateY and deltaY or 0
	local DivideValue = 5  
	if deltaX ~= 0 then
		--根据旋转速度计算偏移值
		deltaX = deltaX*self.RotateSpeedX/DivideValue	--deltaX > 0 and self.RotateSpeedX or (-self.RotateSpeedX)
	end
	if deltaY ~= 0 then
		--根据旋转速度计算偏移值
		deltaY = deltaY*self.RotateSpeedY/DivideValue	--deltaY > 0 and self.RotateSpeedY or (-self.RotateSpeedY)
	end
	return deltaX,deltaY
end

--[[
	当玩家不操控的时候，恢复AvatarY轴施转
]]
function BP_HallAvatarBase:RecoverRotation(DeltaSeconds)
	if not self.RecoverTimerPass then
		return
	end
	if not self.SupportRotateRecover then
		return
	end

	self.RecoverTimerPass = self.RecoverTimerPass + DeltaSeconds
	local Aplha = self.RecoverTimerPass/self.RotateRecoverTime
	if Aplha >= 1 then
		self.RecoverTimerPass = nil
	end
	Aplha = math.min(Aplha,1)
	-- CWaring("DeltaSeconds:" .. DeltaSeconds .. "|Aplha:" .. Aplha)
	-- local CurInterpRotation = UE.UKismetMathLibrary.RLerp(self.RecoverTimerPassOrgRotation,self.RecoverTimerPassTargetRotation,Aplha,false)
	local CurInterpRotation = UE.UKismetMathLibrary.REase(self.RecoverTimerPassOrgRotation,self.RecoverTimerPassTargetRotation,Aplha,false,self.RotateRecoverEasingFunc)--UE.EEasingFunc.EaseOut
	-- local CurInterpRotation = UE.UKismetMathLibrary.REase(self.RecoverTimerPassOrgRotation,self.RecoverTimerPassTargetRotation,Aplha,true,self.RotateRecoverEasingFunc)
	self:K2_SetActorRotation(CurInterpRotation,false)
end


--[[
	当玩家不操控的时候，载具自动不断围绕垂直轴逆时针旋转，旋转速度支持配置
	玩家手动调节摄像头后，载具不再自动旋转
]]

function BP_HallAvatarBase:CheckAutoRotate(DeltaSeconds)
	if self.IsAutoRotate then
		return
	end
	self.CheckAutoRotateDetaTime = self.CheckAutoRotateDetaTime or 0
	self.CheckAutoRotateDetaTime = self.CheckAutoRotateDetaTime + DeltaSeconds
	if self.CheckAutoRotateDetaTime > self.CheckAutoRotateTime then
		self:SetAutoRotate(true)
		self.CheckAutoRotateDetaTime = 0
	end
end


function BP_HallAvatarBase:AutoRotate(DeltaSeconds)
	if not self.SupportAutoRotate then
		return
	end
	self:CheckAutoRotate(DeltaSeconds)
	if not self.IsAutoRotate then
		return
	end
	local CurRotation = self:K2_GetActorRotation()
	self:K2_SetActorRotation(UE.FRotator(CurRotation.Pitch, 
		CurRotation.Yaw + self.AutoRotateSpeed, 
		CurRotation.Roll), false)
end



----【穿戴功能】-----

function BP_HallAvatarBase:InitApparelSlotTypeList()
	
end

function BP_HallAvatarBase:GetApparelAttachPoint(SlotType)
	return self.SlotTypeToAttachPoint[SlotType]
end

function BP_HallAvatarBase:GetApparelAttachMesh(Skid)
	return nil
end

function BP_HallAvatarBase:GetSlotAvatarInfo(SlotType)
	return self.SlotTypeToAvatarList[SlotType] or nil
end

function BP_HallAvatarBase:RegisterApparelInfo(SlotType, AvatarID, AvatarActor)
	self.SlotTypeToAvatarList[SlotType] = {}
	self.SlotTypeToAvatarList[SlotType].AvatarID = AvatarID
	self.SlotTypeToAvatarList[SlotType].AvatarActor = AvatarActor
end

function BP_HallAvatarBase:UnRegisterApparelInfo(SlotType)
	self.SlotTypeToAvatarList[SlotType] = {}
end

function BP_HallAvatarBase:PutOnAvatar(SlotType, AvatarID, AvatarActor)
	if AvatarActor == nil then 
		return 
	end
	local AttachMesh = self:GetApparelAttachMesh(self.CurShowSkinId)
	if AttachMesh == nil then
		return
	end
	
	local SlotAvatarInfo = self.SlotTypeToAvatarList[SlotType]
	if SlotAvatarInfo ~= nil then
		if AvatarID and SlotAvatarInfo.AvatarID == AvatarID then
			return
		end
		if CommonUtil.IsValid(SlotAvatarInfo.AvatarActor) then
			SlotAvatarInfo.AvatarActor:K2_DestroyActor()
		end
	end
	
	local AttachPoint = self:GetApparelAttachPoint(SlotType)
	AvatarActor:K2_AttachToComponent(AttachMesh,
		AttachPoint,
		UE.EAttachmentRule.KeepRelative,
		UE.EAttachmentRule.KeepRelative,
		UE.EAttachmentRule.KeepRelative,
		true
	)
	self:RegisterApparelInfo(SlotType, AvatarID, AvatarActor)
end


function BP_HallAvatarBase:TakeOffAvatar(SlotType)
	local SlotAvatarInfo = self.SlotTypeToAvatarList[SlotType]
	if SlotAvatarInfo == nil then
		return
	end

	if CommonUtil.IsValid(SlotAvatarInfo.AvatarActor) then
		SlotAvatarInfo.AvatarActor:K2_DestroyActor()
	end

	self:UnRegisterApparelInfo(SlotType)
end

--[[
    重置模型的相关参数
    ResetLocation 重置位置 nil值表示真
    ResetRotation 重置施转 nil值表示真
]]
function BP_HallAvatarBase:ResetAvatar(ResetLocation,ResetRotation,ResetScale)
	if not self.CacheSpawnParam then
		return
	end
    if ResetLocation ~= false and self.CacheSpawnParam.Location then
        self:K2_SetActorLocation(self.CacheSpawnParam.Location, false, nil, false)
    end
    if ResetRotation ~= false and self.CacheSpawnParam.Rotation then
        self:K2_SetActorRotation(self.CacheSpawnParam.Rotation, false)
    end
	if ResetScale ~= false and self.CacheSpawnParam.Scale then
        self:SetActorScale3D(self.CacheSpawnParam.Scale)
    end
end

--[[
	添加对Avatar的自定义点击事件
	记得调用RemoveCustomOnClickedFunc移除对应的点击
]]
function BP_HallAvatarBase:AddCustomOnClickedFunc(OnClickedFunc)
	if self.CapsuleComponent and OnClickedFunc then
		if self.PlatformName == "Windows" then
            --FOR WINDOWS
			self.CapsuleComponent.OnClicked:Add(self, OnClickedFunc)
        else
            --FOR MOBILE
            self.CapsuleComponent.OnInputTouchBegin:Add(self, OnClickedFunc)
        end
	end
end

--[[
	删除对Avatar的自定义点击事件
]]
function BP_HallAvatarBase:RemoveCustomOnClickedFunc(OnClickedFunc)
	if self.CapsuleComponent and OnClickedFunc then
		if self.PlatformName == "Windows" then
            --FOR WINDOWS
			self.CapsuleComponent.OnClicked:Remove(self, OnClickedFunc)
        else
            --FOR MOBILE
            self.CapsuleComponent.OnInputTouchBegin:Remove(self, OnClickedFunc)
        end
	end
end

function BP_HallAvatarBase:AttachAvatarByID(AvatarId)
	
end
function BP_HallAvatarBase:RemoveAvatarByID(AvatarId)
	
end

function BP_HallAvatarBase:GetAvatarComponent(SkinId)
	
end

function BP_HallAvatarBase:GetHallAvatarCommonComponent(SkinId)
	local SkinActor = self:GetSkinActor(SkinId)
	if not SkinActor then
		return
	end
	local AvatarComponent = SkinActor.BP_HallAvatarCommonComponent
	return AvatarComponent
end

function BP_HallAvatarBase:ApplyCameraScrollConfigByKey(InKey)
	if not InKey then
		return
	end
	if self.ApplyScrollKey and self.ApplyScrollKey == InKey then
		return
	end
	if not self.CameraConfigMap or not self.CameraConfigMap.ConfigMap then
		return
	end
	local Config = self.CameraConfigMap.ConfigMap:Find(InKey)
	if not Config then
		return
	end
	self.ApplyScrollKey = InKey
	self.CameraDistanceScrollSpeed = Config.Speed
	self.CameraDistanceMax = Config.LerpParams[1]
	self.CameraDistanceMin = Config.LerpParams[2]
	self.CameraDistanceScrollFloatCurve = Config.FloatCurve
	self.CameraDistanceScrollLerpTime = Config.LerpTime
	self.CameraDistanceScrollLerpType = Config.LerpType
	
end

function BP_HallAvatarBase:ApplyCameraMoveConfigByKey(InKey)
	if not InKey then
		return
	end
	if self.ApplyMoveKey and self.ApplyMoveKey == InKey then
		return
	end
	if not self.CameraConfigMap or not self.CameraConfigMap.ConfigMap then
		return
	end
	local Config = self.CameraConfigMap.ConfigMap:Find(InKey)
	if not Config then
		return
	end
	self.ApplyMoveKey = InKey
	self.CameraMoveSpeed = Config.Speed
	self.CameraMoveHorizontalDistanceLeft = Config.LerpParams[1]
	self.CameraMoveHorizontalDistanceRight = Config.LerpParams[2]
	self.CameraMoveVerticalDistanceUp = Config.LerpParams[3]
	self.CameraMoveVerticalDistanceDown = Config.LerpParams[4]
	self.CameraMoveFloatCurve = Config.FloatCurve
	self.CameraMoveLerpTime = Config.LerpTime
	self.CameraMoveLerpType = Config.LerpType
end

return BP_HallAvatarBase
