require "UnLua"

local BP_HeroDisplayBoard = Class()


function BP_HeroDisplayBoard:ReceiveBeginPlay()
	-- self.Super.ReceiveBeginPlay(self)
	CWaring("BP_HeroDisplayBoard:ReceiveBeginPlay")

	self.Overridden.ReceiveBeginPlay(self)
    self.PlatformName = UE.UGameplayStatics.GetPlatformName()

	self.WidgetComInfoList = {
		{Id = EHeroDisplayBoardTabID.Floor.TabId, WidgetComponent = self.BP_HeroDisplayUMGLayerBG},
		{Id = EHeroDisplayBoardTabID.Effect.TabId, WidgetComponent = self.BP_HeroDisplayUMGLayerEffect},
		{Id = EHeroDisplayBoardTabID.Role.TabId, WidgetComponent = self.BP_HeroDisplayUMGLayerHero},
		{Id = EHeroDisplayBoardTabID.Sticker.TabId, WidgetComponent = self.BP_HeroDisplayUMGLayerTexture},
		{Id = EHeroDisplayBoardTabID.Achieve.TabId, WidgetComponent = self.BP_HeroDisplayUMGLayerAchieve}
	}

	self:InitRotate()

    self:OpenOrCloseAvatorHoverRotate(true)

	--self:RegisterEvent(true)
end

function BP_HeroDisplayBoard:ReceiveEndPlay(EndPlayReason)
	self.Overridden.ReceiveEndPlay(self,EndPlayReason)

	self:CleanOnInputEndCursorOverTimer()

	--self:RegisterEvent(false)
end

-- function BP_HeroDisplayBoard:RegisterEvent(bRegister)
-- 	if bRegister then
-- 		-- MvcEntry:GetModel(TeamModel):AddListener(TeamModel.ON_TEAM_MEMBER_PREPARE,self.OnTeamMemberStateChange,self)
-- 		MvcEntry:GetModel(HeroModel):AddListener(HeroModel.NTF_SET_HERO_DISPLAYBOARD_SHOW, self.NTF_SET_HERO_DISPLAYBOARD_SHOW_Func, self)
-- 	else
-- 		MvcEntry:GetModel(HeroModel):RemoveListener(HeroModel.NTF_SET_HERO_DISPLAYBOARD_SHOW, self.NTF_SET_HERO_DISPLAYBOARD_SHOW_Func, self)
-- 	end
-- end

function BP_HeroDisplayBoard:Show(IsShow,SpawnParam)
	IsShow = IsShow or false
	self:SetActorHiddenInGame(not IsShow)	
	self:SetActorEnableCollision(IsShow)	
	self:SetActorTickEnabled(IsShow)

	if SpawnParam == nil then
		CError("BP_HeroDisplayBoard:Show  SpawnParam == nil !!!!")
		return
	end

	if IsShow and SpawnParam.DisplayBoardID > 0 then
		self:SetDisplayId(SpawnParam.DisplayBoardID,true)
	end

	-------------------------------------------------------------------------------
	if IsShow and SpawnParam then
		-- 参考:function BP_HallAvatarBase:Show(IsShow, SkinId)
		self.CacheSpawnParam = SpawnParam
		if self.CacheSpawnParam.TrackingFocus then
			local Param = {
				FocusMethod = UE.ECameraFocusMethod.Tracking,
				RelativeOffset = self:K2_GetActorLocation(),
			}
			MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_CAMERA_FOCUSSETTING_CHANGE, Param)
		elseif self.CacheSpawnParam.FocusMethodSetting then
			local FocusDistance = self.CacheSpawnParam.FocusMethodSetting.ManualFocusDistance or self:GetDistanceFromCarmera()
			local Param = {
				FocusMethod = self.CacheSpawnParam.FocusMethodSetting.FocusMethod,
				ManualFocusDistance = FocusDistance,
				FocusSettingsStruct = self.CacheSpawnParam.FocusMethodSetting.FocusSettingsStruct or self.CameraFocusSettingsCfg,
			}
			MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_CAMERA_FOCUSSETTING_CHANGE, Param)
		else
			local Param = {
				FocusMethod = UE.ECameraFocusMethod.Disable,
				ManualFocusDistance = 10000
			}
			MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_CAMERA_FOCUSSETTING_CHANGE, Param)
		end
	end
	-------------------------------------------------------------------------------
end

function BP_HeroDisplayBoard:SetTransformInLua(Trans)
	self:K2_SetActorTransform(Trans, false, UE.FHitResult(), false)
end

--- 获取距离相机的距离
function BP_HeroDisplayBoard:GetDistanceFromCarmera()
	local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor == nil then
		return 10000
	end
	local direction = self:K2_GetActorLocation() - CameraActor:K2_GetActorLocation()
	direction = UE.UKismetMathLibrary.Normal(direction)
	local targetLocation = CameraActor:K2_GetActorLocation() + direction
	local distance = UE.UKismetMathLibrary.Vector_Distance(self:K2_GetActorLocation(), targetLocation)
	return distance
end

--------局内结算创建
function BP_HeroDisplayBoard:ShowInBattle(IsShow, SpawnParam)
	self:SetActorHiddenInGame(not IsShow)	
	self:SetActorEnableCollision(IsShow)	
	self:SetActorTickEnabled(IsShow)

	if IsShow then
		for _, WidgetComInfo in pairs(self.WidgetComInfoList) do
			if WidgetComInfo then
				local UserWidget = WidgetComInfo.WidgetComponent:GetWidget()
				if UserWidget then
					CLog("BP_HeroDisplayBoard:ShowInBattle UpdateUIInBattle")
					UserWidget:UpdateUIInBattle(SpawnParam)
				end
			end
		end
	end
end
function BP_HeroDisplayBoard:SetDisplayId(DisplayId,NeedUpdate)
	for _, WidgetComInfo in pairs(self.WidgetComInfoList) do
		if WidgetComInfo then
			local UserWidget = WidgetComInfo.WidgetComponent:GetWidget()
			if UserWidget then
				UserWidget:SetDisplayId(DisplayId)
				UserWidget:SetLinkTabId(WidgetComInfo.Id)
				if NeedUpdate then
					UserWidget:UpdateUI()
				end
			end
		end
	end
end

function BP_HeroDisplayBoard:GetResponseCenter()
	if self.ResponseCenter == nil or self.ResponseCenterRadius == nil then
		self.ResponseCenter = nil
		self.ResponseCenterRadiusX = nil
		self.ResponseCenterRadiusY = nil
		local BuoysScreenPos, bSucc = UE.UGameplayStatics.ProjectWorldToScreen(CommonUtil.GetLocalPlayerC(), self:K2_GetActorLocation())
		if bSucc then
			self.ResponseCenter = BuoysScreenPos

			local Scene1WorldPosition = self.Scene1:K2_GetComponentLocation()
			local Scene1ScreenPosition, bSucc = UE.UGameplayStatics.ProjectWorldToScreen(CommonUtil.GetLocalPlayerC(), Scene1WorldPosition)

			self.ResponseCenterRadiusX = BuoysScreenPos.X - Scene1ScreenPosition.X
			self.ResponseCenterRadiusY = BuoysScreenPos.Y - Scene1ScreenPosition.Y


			if not self.OpenGyro then
				self.ResponseRotateXSpeed = self.RotationXRange/self.ResponseCenterRadiusX
				self.ResponseRotateYSpeed = self.RotationYRange/self.ResponseCenterRadiusY

				self.ResponseLocationXSpeed = self.LocationXRange/self.ResponseCenterRadiusX
				self.ResponseLocationYSpeed = self.LocationYRange/self.ResponseCenterRadiusY
			else
				self.ResponseRotateXSpeed = self.RotationXRange/self.TiltZRange
				self.ResponseRotateYSpeed = self.RotationYRange/self.TiltXRange

				self.ResponseLocationXSpeed = self.LocationXRange/self.TiltZRange
				self.ResponseLocationYSpeed = self.LocationYRange/self.TiltXRange
			end
		end
	end
end

function BP_HeroDisplayBoard:InitRotate()
	self.OpenGyro = false

	self.IsPressed = false
	self.RecoverTimerPass = nil
	self.RecoverTimerPassOrgRotation = nil
	self.RecoverTimerPassTargetRotation = nil

	self.TweenInTimerPass = nil
	self.TweenInTimerPassOrgRotation = nil
	self.TweenInTimerPassOrgScale = nil
	self.TweenInTimerPassOrgLocation = nil

	local CLocation = self:GetTargetLocation()
	local CRotation = self:GetTargetRotation()
	local CScale3D = self:GetCapsuleScale()
	self.OrgLocation = UE.FVector(CLocation.X,CLocation.Y,CLocation.Z);
	self.OrgRotation = UE.FRotator(CRotation.Pitch,CRotation.Yaw,CRotation.Roll)
	self.OrgCapsuleScale = UE.FVector(CScale3D.X,CScale3D.Y,CScale3D.Z);

	self.TargetRotationX = nil
	self.TargetRotationY = nil
	self.TargetLocationX = nil
	self.TargetLocationY = nil
end


--打开或者关闭 控制Avatar旋转
function BP_HeroDisplayBoard:OpenOrCloseAvatorHoverRotate(bValue)
    if bValue then
        if self.PlatformName == "Windows" then
            --FOR WINDOWS
            self.CapsuleComponent.OnBeginCursorOver:Add(self, self.OnInputBeginCursorOver)
			self.CapsuleComponent.OnEndCursorOver:Add(self, self.OnInputEndCursorOver)
        else
            -- --FOR MOBILE
			self.OpenGyro = true
        end
    else
		self.OpenGyro = false

        -- --FOR WINDOWS
        self.CapsuleComponent.OnBeginCursorOver:Remove(self, self.OnInputBeginCursorOver)
		self.CapsuleComponent.OnEndCursorOver:Remove(self, self.OnInputEndCursorOver)
    end
end

--FOR WINDOWS
function BP_HeroDisplayBoard:OnInputBeginCursorOver()
	local localPC = CommonUtil.GetLocalPlayerC()
	if localPC == nil then 
		return 
	end
	CWaring("============OnInputBeginCursorOver")
	self.OnInputBeginCursorOverTimer = nil
	self:GetResponseCenter()
	self.IsPressed = true

	self:CleanOnInputEndCursorOverTimer()
end


function BP_HeroDisplayBoard:OnInputEndCursorOver()
	-- CWaring("============OnInputEndCursorOver")
	if self.OnInputEndCursorOverTimer then
		return
	end
	self.OnInputEndCursorOverTimer = Timer.InsertTimer(0.1,function ()
		CWaring("============OnInputEndCursorOver")
		self.OnInputEndCursorOverTimer = nil
		self.IsPressed = false
	end)
end

function BP_HeroDisplayBoard:CleanOnInputEndCursorOverTimer()
	if self.OnInputEndCursorOverTimer then
		Timer.RemoveTimer(self.OnInputEndCursorOverTimer)
		self.OnInputEndCursorOverTimer = nil
	end
end

--FOR Common
function BP_HeroDisplayBoard:ReceiveTick(DeltaSeconds)
	if not self.IsPressed then 
		self.TweenInTimerPass = 0
		self.TweenInTimerPassOrgRotation = nil
		if not self.RecoverTimerPassOrgRotation and self.RecoverTimerPass then
			--设置为最终旋转角度及初始旋转数据
			self.RecoverTimerPassOrgRotation = self:GetTargetRotation()
			self.RecoverTimerPassTargetRotation = self.OrgRotation

			self.RecoverTimerPassOrgScale = self:GetCapsuleScale()
			self.RecoverTimerPassTargetScale = self.OrgCapsuleScale

			self.RecoverTimerPassOrgLocation = self:GetTargetLocation()
			self.RecoverTimerPassTargetLocation = self.OrgLocation
		end
		self:RecoverRotation(DeltaSeconds)
	else
		self.RecoverTimerPass = 0
		if not self.TweenInTimerPassOrgRotation and self.TweenInTimerPass then
			self.TweenInTimerPassOrgRotation = self:GetTargetRotation()
			self.TweenInTimerPassOrgScale = self:GetCapsuleScale()
			self.TweenInTimerPassOrgLocation = self:GetTargetLocation()
		end
		self.RecoverTimerPassOrgRotation = nil
		self:UpdateInteractionResponse(DeltaSeconds) 
	end
end

function BP_HeroDisplayBoard:GetTargetRotation()
	-- CError("CCCCCcccccccccc2 ="..table.tostring(self.SceneNeedAction.RelativeRotation))
	return UE.FRotator(self.SceneNeedAction.RelativeRotation.Pitch,self.SceneNeedAction.RelativeRotation.Yaw,self.SceneNeedAction.RelativeRotation.Roll)
end

function BP_HeroDisplayBoard:GetTargetLocation()
	-- CError("CCCCCcccccccccc ="..table.tostring(self.BaseScene.RelativeLocation))
	return UE.FVector(self.BaseScene.RelativeLocation.X,self.BaseScene.RelativeLocation.Y,self.BaseScene.RelativeLocation.Z);
end
-- function BP_HeroDisplayBoard:AddTargetLocalRotation(AddRotaion)
-- 	local sweepHitResult
-- 	self.CapsuleComponent:K2_AddLocalRotation(AddRotaion, false, sweepHitResult, false)
-- end
function BP_HeroDisplayBoard:SetTargetRotation(Rotaion)
	local sweepHitResult
	self.SceneNeedAction:K2_SetRelativeRotation(Rotaion, false, sweepHitResult, false)

	-- for k,WidgetComInfo in ipairs(self.WidgetComInfoList) do
	-- 	if WidgetComInfo then
	-- 		local sweepHitResult
	-- 		local RotaionFix = UE.UKismetMathLibrary.Multiply_RotatorFloat(Rotaion, WidgetComInfo.WidgetComponent.RotationScale)
	-- 		WidgetComInfo.WidgetComponent:K2_SetRelativeRotation(RotaionFix, false, sweepHitResult, false)
	-- 	end
	-- end
end

function BP_HeroDisplayBoard:SetTargetLocation(Location)
	local sweepHitResult
	self.BaseScene:K2_SetRelativeLocation(Location, false, sweepHitResult, false)
	-- print(StringUtil.Format("1X:{0} 1Y:{1} 1Z:{2}",Location.X,Location.Y,Location.Z))
	-- for k, WidgetComInfo in ipairs(self.WidgetComInfoList) do
	-- 	if WidgetComInfo then
	-- 		local sweepHitResult
	-- 		local LocationFix = UE.UKismetMathLibrary.Multiply_VectorFloat(Location, WidgetComInfo.WidgetComponent.LocationScale)
	-- 		LocationFix.X = WidgetComInfo.WidgetComponent.RelativeLocation.X
	-- 		-- print(StringUtil.Format("X:{0} Y:{1} Z:{2}",LocationFix.X,LocationFix.Y,LocationFix.Z))
	-- 		WidgetComInfo.WidgetComponent:K2_SetRelativeLocation(LocationFix, false, sweepHitResult, false)
	-- 	end
	-- end
end

function BP_HeroDisplayBoard:SetCapsuleScale(Scale)
	self.CapsuleComponent:SetRelativeScale3D(Scale)
end
function BP_HeroDisplayBoard:GetCapsuleScale(Scale)
	return UE.FVector(self.CapsuleComponent.RelativeScale3D.X,self.CapsuleComponent.RelativeScale3D.Y,self.CapsuleComponent.RelativeScale3D.Z);
end

function BP_HeroDisplayBoard:UpdateInteractionResponse(DeltaSeconds)
	local localPC = CommonUtil.GetLocalPlayerC()
	if localPC == nil then 
		return 
	end
	if not self.OpenGyro then
		local X, Y = localPC:GetMousePosition()
		local CRotation = self:GetTargetRotation()
		self:CalculateMouseRotateValue(X,Y,CRotation)
	else
		local Tilt,RotationRate,Gravity,Acceleration = localPC:GetInputMotionState()
		self:CalculateGyroRotateValue(Tilt);
	end
	local TargetRotaion = UE.FRotator(self.TargetRotationY, self.TargetRotationX, 0)
	local TargetLocation = UE.FVector(0,self.TargetLocationX, self.TargetLocationY)
	if self.TweenInTimerPass then
		self.TweenInTimerPass = self.TweenInTimerPass + DeltaSeconds
		local Aplha = self.TweenInTimerPass/self.TweenInTime
		if Aplha >= 1 then
			self.TweenInTimerPass = nil
		end
		Aplha = math.min(Aplha,1)

		local CurInterpRotation = UE.UKismetMathLibrary.REase(self.TweenInTimerPassOrgRotation,TargetRotaion,Aplha,false,self.TweenInEasingFunc)
		self:SetTargetRotation(CurInterpRotation)
	
		local CurInterpScale = UE.UKismetMathLibrary.VEase(self.TweenInTimerPassOrgScale,self.TweenTargetScale,Aplha,self.TweenInEasingFunc)
		self:SetCapsuleScale(CurInterpScale)
	
		local CurInterpLocation = UE.UKismetMathLibrary.VEase(self.TweenInTimerPassOrgLocation,TargetLocation,Aplha,self.TweenInEasingFunc)
		self:SetTargetLocation(CurInterpLocation)
	else
		self:SetTargetRotation(TargetRotaion)
		self:SetTargetLocation(TargetLocation)
	end
end


--[[
	当玩家不操控的时候，恢复AvatarY轴施转
]]
function BP_HeroDisplayBoard:RecoverRotation(DeltaSeconds)
	if not self.RecoverTimerPass then
		return
	end

	self.RecoverTimerPass = self.RecoverTimerPass + DeltaSeconds
	local Aplha = self.RecoverTimerPass/self.TweenOutTime
	if Aplha >= 1 then
		self.RecoverTimerPass = nil
	end
	Aplha = math.min(Aplha,1)

	local CurInterpRotation = UE.UKismetMathLibrary.REase(self.RecoverTimerPassOrgRotation,self.RecoverTimerPassTargetRotation,Aplha,false,self.TweenOutEasingFunc)
	self:SetTargetRotation(CurInterpRotation)

	local CurInterpScale = UE.UKismetMathLibrary.VEase(self.RecoverTimerPassOrgScale,self.RecoverTimerPassTargetScale,Aplha,self.TweenOutEasingFunc)
	self:SetCapsuleScale(CurInterpScale)

	local CurInterpLocation = UE.UKismetMathLibrary.VEase(self.RecoverTimerPassOrgLocation,self.RecoverTimerPassTargetLocation,Aplha,self.TweenOutEasingFunc)
	self:SetTargetLocation(CurInterpLocation)
end


function BP_HeroDisplayBoard:CalculateMouseRotateValue(X,Y,_Rotation)
	local deltaX = self.ResponseCenter.X - X
	local deltaY = self.ResponseCenter.Y - Y

	self.TargetRotationX = 0
	self.TargetRotationY = 0

	self.TargetLocationX = 0
	self.TargetLocationY = 0

	if deltaX ~= 0 then
		self.TargetRotationX = deltaX*self.ResponseRotateXSpeed	
		if math.abs(self.TargetRotationX) > self.RotationXRange then
			self.TargetRotationX = self.TargetRotationX > 0 and self.RotationXRange or -self.RotationXRange
		end

		self.TargetLocationX = deltaX*self.ResponseLocationXSpeed	
		if math.abs(self.TargetLocationX) > self.LocationXRange then
			self.TargetLocationX = self.TargetLocationX > 0 and self.LocationXRange or -self.LocationXRange
		end
	end
	if deltaY ~= 0 then
		self.TargetRotationY = deltaY*self.ResponseRotateYSpeed
		if math.abs(self.TargetRotationY) > self.RotationYRange then
			self.TargetRotationY = self.TargetRotationY > 0 and self.RotationYRange or -self.RotationYRange
		end

		self.TargetLocationY = deltaY*self.ResponseLocationYSpeed
		if math.abs(self.TargetLocationY) > self.LocationYRange then
			self.TargetLocationY = self.TargetLocationY > 0 and self.LocationYRange or -self.LocationYRange
		end
	end
end

function BP_HeroDisplayBoard:CalculateGyroRotateValue(Tilt)
	CWaring(StringUtil.Format("X:{0} Y:{1} Z:{2}",Tilt.X,Tilt.Y,Tilt.Z))
	local DeltaZ = Tilt.Z
	local DeltaX = Tilt.X

	self.TargetRotationX = 0
	self.TargetRotationY = 0

	self.TargetLocationX = 0
	self.TargetLocationY = 0


	if math.abs(DeltaZ) >= self.TiltZRange then
		DeltaZ = DeltaZ > 0 and self.TiltZRange or -self.TiltZRange
	end
	if DeltaZ ~= 0 then
		self.TargetRotationX = DeltaZ*self.ResponseRotateXSpeed	
		self.TargetLocationX = DeltaZ*self.ResponseLocationXSpeed	
	end

	if math.abs(DeltaX) >= self.TiltXRange then
		DeltaX = DeltaX > 0 and self.TiltXRange or -self.TiltXRange
	end
	if DeltaX ~= 0 then
		self.TargetRotationY = DeltaX*self.ResponseRotateYSpeed	
		self.TargetLocationY = DeltaX*self.ResponseLocationYSpeed	
	end
end

----------------------------------------局外直接设置角色面板时使用 >>

---@param Param table {HeroId:number, DisplayData:DisplayBoardNode}
function BP_HeroDisplayBoard:NTF_SET_HERO_DISPLAYBOARD_SHOW_Func(Param)
	-- {HeroId:number, DisplayData:DisplayBoardNode}
	self:SetDisplayBordUiByParam(Param)
end

---@param Param table {HeroId:number, DisplayData:DisplayBoardNode}
function BP_HeroDisplayBoard:SetDisplayBordUiByParam(Param)
	if Param == nil or Param.DisplayData == nil then
		return
	end

	---@type DisplayBoardNode
	local DisplayData = Param.DisplayData

	for _, WidgetComInfo in pairs(self.WidgetComInfoList) do
		if WidgetComInfo then
			local UserWidget = WidgetComInfo.WidgetComponent:GetWidget()
			if UserWidget then
				-- CLog("BP_HeroDisplayBoard:ShowInBattle UpdateUIInBattle")
				UserWidget:SetUIByParam(DisplayData)
			end
		end
	end
end

----------------------------------------局外直接设置角色面板时使用 <<

return BP_HeroDisplayBoard