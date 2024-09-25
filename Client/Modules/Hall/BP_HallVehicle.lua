require "UnLua"

local BP_HallVehicle = Class("Client.Modules.Hall.BP_HallAvatarBase")

require("Client.Modules.Common.CommonRotationLerp")

function BP_HallVehicle:ReceiveBeginPlay()
	self.Super.ReceiveBeginPlay(self)
	self:CheckCameraSpringArm()
	self:OpenOrCloseCameraRotateAction(true)

	--初始SpringArm旋转
	self.SpringArmOriginRotation = UE.FRotator(-12, 100, -0.5)
	self.SpringArmOriginLength = 1050
	
	-- 通用的插值旋转
	self.CommonLerpInst = CommonRotationLerp.New()
	self.CameraCommonLerpInst = CommonRotationLerp.New()
end

function BP_HallVehicle:OpenOrCloseCameraRotateAction(bValue)
	if bValue then
		MvcEntry:GetModel(InputModel):AddListener(InputModel.ON_COMMON_TOUCH_INPUT, self.OnCommonTouchInput, self)
    else
		MvcEntry:GetModel(InputModel):RemoveListener(InputModel.ON_COMMON_TOUCH_INPUT, self.OnCommonTouchInput, self)
    end
end


function BP_HallVehicle:OpenOrCloseCameraTranslation(bValue)
	self.SupportDistance = bValue
end


function BP_HallVehicle:ReceiveEndPlay(EndPlayReason)
	self.Super.ReceiveEndPlay(self,EndPlayReason)
	self:OpenOrCloseCameraRotateAction(false)

	if self.CommonLerpInst ~= nil then
		self.CommonLerpInst:End()
		self.CommonLerpInst = nil
	end
	if self.CameraCommonLerpInst ~= nil then
		self.CameraCommonLerpInst:End()
		self.CameraCommonLerpInst = nil
	end
end

function BP_HallVehicle:SpawnSkinAvatar(SkinId, ForbidUseRelativeTransform)
	local VehicleCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig, Cfg_VehicleSkinConfig_P.SkinId, SkinId)
	if VehicleCfg == nil then 
        return 
    end
	local IsCreate = self.Super.SpawnSkinAvatarAction(self, SkinId, VehicleCfg[Cfg_VehicleSkinConfig_P.SystemBP], ForbidUseRelativeTransform)
	if IsCreate then
	
	end
end

--[[
	重写父类方法
]]
function BP_HallVehicle:ShowSkinAvatar(SkinId)
	self.Super.ShowSkinAvatar(self, SkinId)

	--每次显示的时候，贴上贴纸
	self:UpdateVehicleSkinAllSticker(SkinId)

	local VehicleCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig, Cfg_VehicleSkinConfig_P.SkinId, SkinId)
	if VehicleCfg == nil then 
        return 
    end
	self:UpdateVehiclePlate(VehicleCfg[Cfg_VehicleSkinConfig_P.VehicleId], SkinId)
end


function BP_HallVehicle:GetCamera()
	return self.SpringArmCamera
end

function BP_HallVehicle:GetSkinDecalComponentTag(Slot)
	return StringUtil.FormatSimple("DecalComponent.Slot{0}", Slot)
end

function BP_HallVehicle:GetSkinDecalComponent(VehicleSkinId, StickerSlot)
	local SkinActor = self:GetSkinActor(VehicleSkinId)
	if SkinActor == nil then
		return
	end
	local DecalComponent = SkinActor:FindComponentByTag(UE.UDecalComponent, self:GetSkinDecalComponentTag(StickerSlot))
	if not CommonUtil.IsValid(DecalComponent) then
		return
	end
	return DecalComponent
end

function BP_HallVehicle:AddVehicleSkinSticker(VehicleSkinId, StickerInfo)
	if StickerInfo == nil then
		return
	end

	local SkinActor = self:GetSkinActor(VehicleSkinId)
	if SkinActor == nil then
		return
	end
	
	local DecalComponent = self:GetSkinDecalComponent(VehicleSkinId, StickerInfo.Slot)
	if DecalComponent then
		CWaring(StringUtil.FormatSimple("AddVehicleSkinSticker: {0} Exist!", StickerInfo.Slot))
		return
	end

	local StickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker, StickerInfo.StickerId)
    if StickerCfg == nil then 
		return
	end

	local MaterialInst = nil
	local StickerMaterial = LoadObject(StickerCfg[Cfg_VehicleSkinSticker_P.StickerMaterial])
	if StickerMaterial ~= nil then
		MaterialInst = UE.UKismetMaterialLibrary.CreateDynamicMaterialInstance(self, StickerMaterial)
		if MaterialInst ~= nil then
			MaterialInst:SetScalarParameterValue("DT_CustomRotate", (StickerInfo.RotateAngle or 0) *  0.15)
			--设置纹理
			local StickerMaterialTex = LoadObject(StickerCfg[Cfg_VehicleSkinSticker_P.StickerMaterialTex])
			if StickerMaterialTex ~= nil then
				MaterialInst:SetTextureParameterValue("T_DecalAtlas", StickerMaterialTex)
			end
		end
	end

	--世界坐标
	local Position = UE.FVector(StickerInfo.Position.X, StickerInfo.Position.Y, StickerInfo.Position.Z)
	local Rotator = UE.FRotator(StickerInfo.Rotator.X, StickerInfo.Rotator.Y, StickerInfo.Rotator.Z)
	local Scale =  UE.FVector(StickerInfo.Scale.X, StickerInfo.Scale.Y, StickerInfo.Scale.Z)
	local DecalSize = UE.FVector(25, 25, 25) * StickerInfo.ScaleLength
	DecalComponent = UE.UGameplayStatics.SpawnDecalAttached(
		MaterialInst, 
		DecalSize, 
		SkinActor:K2_GetRootComponent(),
		"",
		Position,
		Rotator,
		UE.EAttachLocation.KeepRelativeOffset)
	if DecalComponent ~= nil then
		DecalComponent.ComponentTags:Clear()
		DecalComponent.ComponentTags:Add(self:GetSkinDecalComponentTag(StickerInfo.Slot))
		DecalComponent:K2_SetRelativeTransform(UE.UKismetMathLibrary.MakeTransform(Position, Rotator, Scale), false, nil, false)
	end
end


function BP_HallVehicle:RemoveVehicleSkinSticker(VehicleSkinId, StickerSlot)
	local DecalComponent = self:GetSkinDecalComponent(VehicleSkinId, StickerSlot)
	if not DecalComponent then
		CWaring(StringUtil.FormatSimple("RemoveVehicleSkinSticker: {0} Not Exist!", StickerSlot))
		return
	end
	local SkinActor = self:GetSkinActor(VehicleSkinId)
	if SkinActor == nil then
		return
	end
	DecalComponent:K2_DetachFromComponent()
	DecalComponent:K2_DestroyComponent(SkinActor)
end


function BP_HallVehicle:UpdateVehicleSkinSticker(VehicleSkinId, StickerInfo)
	if StickerInfo == nil then
		return
	end

	local DecalComponent = self:GetSkinDecalComponent(VehicleSkinId, StickerInfo.Slot)
	if not DecalComponent then
		CWaring(StringUtil.FormatSimple("UpdateVehicleSkinSticker: {0} Not Exist!", StickerInfo.Slot))
		return
	end

	local StickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker, StickerInfo.StickerId)
    if StickerCfg ~= nil then 
		local StickerMaterial = LoadObject(StickerCfg[Cfg_VehicleSkinSticker_P.StickerMaterial])
		if StickerMaterial ~= nil then
			local MaterialInst = UE.UKismetMaterialLibrary.CreateDynamicMaterialInstance(self, StickerMaterial)
			if MaterialInst ~= nil then
				DecalComponent:SetDecalMaterial(MaterialInst)
				MaterialInst:SetScalarParameterValue("DT_CustomRotate", (StickerInfo.RotateAngle or 0) * 0.15)

				--设置纹理
				local StickerMaterialTex = LoadObject(StickerCfg[Cfg_VehicleSkinSticker_P.StickerMaterialTex])
				if StickerMaterialTex ~= nil then
					MaterialInst:SetTextureParameterValue("T_DecalAtlas", StickerMaterialTex)
				end
			end
			
		end	
	end
	
	DecalComponent.DecalSize = UE.FVector(25, 25, 25) * StickerInfo.ScaleLength
	local Position = UE.FVector(StickerInfo.Position.X, StickerInfo.Position.Y, StickerInfo.Position.Z)
	local Scale =  UE.FVector(StickerInfo.Scale.X, StickerInfo.Scale.Y, StickerInfo.Scale.Z)
	local Rotator = UE.FRotator(StickerInfo.Rotator.X, StickerInfo.Rotator.Y, StickerInfo.Rotator.Z)
	DecalComponent:K2_SetRelativeTransform(UE.UKismetMathLibrary.MakeTransform(Position, Rotator, Scale), false, nil, false)
end


function BP_HallVehicle:UpdateVehicleSkinAllSticker(SkinId)
	local SkinActor = self:GetSkinActor(SkinId)
	if SkinActor == nil then
		return
	end
	local DecalComponents = SkinActor:K2_GetComponentsByClass(UE.UDecalComponent)
	local Num =  DecalComponents:Num()
	for i=1, Num do
		local DecalComponent = DecalComponents:Get(i)
		if CommonUtil.IsValid(DecalComponent) then
			DecalComponent:K2_DetachFromComponent()
			DecalComponent:K2_DestroyComponent(SkinActor)
		end
	end

	local StickerList = MvcEntry:GetModel(VehicleModel):GetVehicleSkinId2StickerList(SkinId) or {}
	for _, V in ipairs(StickerList) do
		self:AddVehicleSkinSticker(SkinId, V)
	end
end


--[[
	更新车牌
]]
function BP_HallVehicle:UpdateVehiclePlate(VehicleId, VehicleSkinId)
	local SkinActor = self:GetSkinActor(VehicleSkinId)
	if SkinActor == nil then
		return
	end
	local SkeleteComponent = SkinActor.SkeletalMesh
	if SkeleteComponent == nil then
		return
	end
	
	local PlateNo = MvcEntry:GetModel(VehicleModel):GetVehicleLicensePlate(VehicleId)
	local PlateNoLength = string.len(PlateNo)
	PlateNo = string.upper(PlateNo)
	for Index = 1, PlateNoLength do
		local ANo = string.sub(PlateNo, Index, Index)
		local NumberIndex = PlateMaterialParamMapping[ANo]
		if NumberIndex ~= nil then
			SkeleteComponent:SetScalarParameterValueOnMaterials("PlateNumber_"..Index-1, NumberIndex)
		end
	end
end


function BP_HallVehicle:CheckCameraSpringArm()
	if not self.OpenCheckCameraSpringArm then
		CWaring("BP_HallVehicle: CheckCameraSpringArm Not Support")
		return
	end
	local Actors = UE.UGameplayStatics.GetAllActorsWithTag(self, "SpringArmCamera")
    if Actors:Length() >= 1 then
		self.SpringArmCamera = Actors:Get(1)
    end
	if self.SpringArmCamera ~= nil then
		local localPC = CommonUtil.GetLocalPlayerC()
		localPC:SetViewTargetWithBlend(self.SpringArmCamera)
	end
end

function BP_HallVehicle:GetCameraSpringArm()
	if self.SpringArmCamera == nil or self.SpringArmCamera.SpringArm == nil then
		CWaring("Not Found The SpringArm Camera")
		return nil
	end
	return self.SpringArmCamera.SpringArm
end

function BP_HallVehicle:ResetCameraSpringArmRotation()
	if self.SpringArmOriginRotation ~= nil then
		local SpringArmComponent = self:GetCameraSpringArm()
		if SpringArmComponent ~= nil then
			SpringArmComponent:K2_SetRelativeRotation(self.SpringArmOriginRotation, false, UE.FHitResult(), false)
			SpringArmComponent.TargetArmLength = self.SpringArmOriginLength 
		end
	end
end

function BP_HallVehicle:SetSpringArmRotator(Rotator)
	local SpringArmComponent = self:GetCameraSpringArm()
	if SpringArmComponent == nil then
		return
	end
	SpringArmComponent:K2_SetRelativeRotation(Rotator, false, UE.FHitResult(), false)
end

function BP_HallVehicle:RotateSpringArm(DeltaRotation)
	local SpringArmComponent = self:GetCameraSpringArm()
	if SpringArmComponent == nil then
		return
	end
	local CurRotation = SpringArmComponent:K2_GetComponentRotation()
	if self.SupportCameraRotatePitch then
		CurRotation.Pitch = UE.UKismetMathLibrary.FClamp(CurRotation.Pitch + DeltaRotation.Pitch, 
		self.RotatePitchMin, self.RotatePitchMax)
	end
	if self.SupportCameraRotateYaw then
		CurRotation.Yaw = CurRotation.Yaw + DeltaRotation.Yaw
	end
	CurRotation.Roll = 0

	SpringArmComponent:K2_SetRelativeRotation(CurRotation, false, UE.FHitResult(), false)
end

function BP_HallVehicle:SetCameraFocusTracking()
	if self.SpringArmCamera == nil then
		return
	end
	local CineCameraComponent = self.SpringArmCamera.CineCamera
	if CineCameraComponent == nil then
		return
	end
	CineCameraComponent.FocusSettings.FocusMethod = UE.ECameraFocusMethod.Tracking
	CineCameraComponent.FocusSettings.TrackingFocusSettings.RelativeOffset = self:K2_GetActorLocation()
end

function BP_HallVehicle:UpdateCameraTranslation(IsBackward)
	if self.SupportFov == true then
		CWaring("Vehicle: Not Support Fov")
	elseif self.SupportDistance == true then
		local SpringArmComponent = self:GetCameraSpringArm()
		if SpringArmComponent ~= nil then
			local DeltaArmLength = (IsBackward and 1 or -1) * self.CameraDistanceScrollSpeed
			SpringArmComponent.TargetArmLength = UE.UKismetMathLibrary.FClamp(SpringArmComponent.TargetArmLength + DeltaArmLength, self.CameraDistanceMin, self.CameraDistanceMax)
		end
	else
		CWaring("不支持相机推进")
	end
end




-- 复合，X转车, Y转相机Pitch
function BP_HallVehicle:OnCommonTouchInput(RotateDegreeParam)
	if self.bHidden then
		return
	end

	if self.CommonLerpInst ~= nil then
		local Param = {
			ActorInst = self, 
			DeltaRotation =  UE.FRotator(0, RotateDegreeParam and -RotateDegreeParam.X or 0, 0)
		}
		self.CommonLerpInst:Start(Param)
	end

	if self.CameraCommonLerpInst ~= nil then
		local Param = {
			ActorComponentInst =  self:GetCameraSpringArm(), 
			DeltaRotation = UE.FRotator(RotateDegreeParam and -RotateDegreeParam.Y or 0, 0, 0),
			PitchLimit = {Min = self.RotatePitchMin, Max = self.RotatePitchMax }
		}
		self.CameraCommonLerpInst:Start(Param)
	end

	-- --设置相机Pitch
	-- self:RotateSpringArm(UE.FRotator(-RotateDegreeParam.Y, 0, 0))
end

function BP_HallVehicle:IsLerping()
	return self.CommonLerpInst and self.CommonLerpInst:IsLerping() or false
end


return BP_HallVehicle
