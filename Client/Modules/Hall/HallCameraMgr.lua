---@class HallCameraMgr

local class_name = "HallCameraMgr"
HallCameraMgr = HallCameraMgr or BaseClass(nil, class_name)

function HallCameraMgr:__init()
    CLog("HallCameraMgr:__init")
end

function HallCameraMgr:__dispose()	
    CLog("HallCameraMgr:__dispose")
    self:UnInit()
    ---@type HallModel
    self.ModelHall = nil
    self.HallSceneMgr = nil
    self.TrackingFocusRelativeOffset = nil
end

function HallCameraMgr:Init(HallSceneMgr)
    CLog("HallCameraMgr:Init")
    self.HallSceneMgr = HallSceneMgr
    self.ModelHall = MvcEntry:GetModel(HallModel)
	self:AddListeners()

    self.TrackingFocusParam = nil
end

function HallCameraMgr:UnInit()
	self:RemoveListeners()
end

function HallCameraMgr:AddListeners()
	if self.ModelHall == nil then 
		return
	end
    self.ModelHall:AddListener(HallModel.ON_STREAM_LEVEL_LOAD_COMPLELTED, self.OnLoadStreamLevelComplete, self)
    self.ModelHall:AddListener(HallModel.TRIGGER_CAMERA_SWITCH, self.TRIGGER_CAMERA_SWITCH_Func, self)
    self.ModelHall:AddListener(HallModel.ON_CAMERA_FOCUSSETTING_CHANGE, self.ON_CAMERA_FOCUSSETTING_CHANGE_Func, self)
end

function HallCameraMgr:RemoveListeners()
	if self.ModelHall == nil then 
		return
	end
    self.ModelHall:RemoveListener(HallModel.ON_STREAM_LEVEL_LOAD_COMPLELTED, self.OnLoadStreamLevelComplete, self)
    self.ModelHall:RemoveListener(HallModel.TRIGGER_CAMERA_SWITCH, self.TRIGGER_CAMERA_SWITCH_Func, self)
    self.ModelHall:RemoveListener(HallModel.ON_CAMERA_FOCUSSETTING_CHANGE, self.ON_CAMERA_FOCUSSETTING_CHANGE_Func, self)
end

function HallCameraMgr:ON_CAMERA_FOCUSSETTING_CHANGE_Func(Param)
    self.TrackingFocusParam = Param
    self:UpdateCameraFocusSetting();
    self.TrackingFocusParam = nil -- 使用了之后必须置空
end

function HallCameraMgr:UpdateCameraFocusSetting()
    local CameraActor =UE.UGameHelper.GetCurrentSceneCamera()
    if CameraActor and CameraActor:GetCineCameraComponent() then
        -- local CineCameraActor = self.Avatar:Cast(UE.A)
        local CineCameraComponent = CameraActor:GetCineCameraComponent()
        if self.TrackingFocusParam then
            if self.TrackingFocusParam.FocusSettingsStruct then
                ---是否是 FCameraFocusSettings 结构体 
                CineCameraComponent.FocusSettings.FocusMethod = self.TrackingFocusParam.FocusSettingsStruct.FocusMethod
                CineCameraComponent.FocusSettings.TrackingFocusSettings.ActorToTrack = nil
                CineCameraComponent.FocusSettings.ManualFocusDistance = 10000
                
                if CineCameraComponent.FocusSettings.FocusMethod == UE.ECameraFocusMethod.Tracking then
                    CineCameraComponent.FocusSettings.TrackingFocusSettings.ActorToTrack = self.TrackingFocusParam.FocusSettingsStruct.TrackingFocusSettings.ActorToTrack
                    local RelativeOffset = self.TrackingFocusParam.FocusSettingsStruct.TrackingFocusSettings.RelativeOffset
                    CineCameraComponent.FocusSettings.TrackingFocusSettings.RelativeOffset = UE.FVector(RelativeOffset.X, RelativeOffset.Y, RelativeOffset.Z) 
                    CineCameraComponent.FocusSettings.TrackingFocusSettings.bDrawDebugTrackingFocusPoint = self.TrackingFocusParam.FocusSettingsStruct.TrackingFocusSettings.bDrawDebugTrackingFocusPoint

                    CineCameraComponent.FocusSettings.bSmoothFocusChanges = self.TrackingFocusParam.FocusSettingsStruct.bSmoothFocusChanges
                    CineCameraComponent.FocusSettings.FocusSmoothingInterpSpeed = self.TrackingFocusParam.FocusSettingsStruct.FocusSmoothingInterpSpeed
                    CineCameraComponent.FocusSettings.FocusOffset = self.TrackingFocusParam.FocusSettingsStruct.FocusOffset
                elseif CineCameraComponent.FocusSettings.FocusMethod == UE.ECameraFocusMethod.Manual then
                    CineCameraComponent.FocusSettings.ManualFocusDistance = self.TrackingFocusParam.FocusSettingsStruct.ManualFocusDistance
                    CineCameraComponent.FocusSettings.bSmoothFocusChanges = self.TrackingFocusParam.FocusSettingsStruct.bSmoothFocusChanges
                    CineCameraComponent.FocusSettings.FocusSmoothingInterpSpeed = self.TrackingFocusParam.FocusSettingsStruct.FocusSmoothingInterpSpeed
                    CineCameraComponent.FocusSettings.FocusOffset = self.TrackingFocusParam.FocusSettingsStruct.FocusOffset
                end
            else
                CineCameraComponent.FocusSettings.FocusMethod = self.TrackingFocusParam.FocusMethod
                if CineCameraComponent.FocusSettings.FocusMethod == UE.ECameraFocusMethod.Tracking then
                    CineCameraComponent.FocusSettings.TrackingFocusSettings.RelativeOffset = self.TrackingFocusParam.RelativeOffset
                else
                    CineCameraComponent.FocusSettings.ManualFocusDistance = self.TrackingFocusParam.ManualFocusDistance
                end 
            end
        else
            CineCameraComponent.FocusSettings.FocusMethod = UE.ECameraFocusMethod.Disable
            CineCameraComponent.FocusSettings.ManualFocusDistance = 10000
        end
        -- CineCameraComponent.FocusSettings.FocusMethod = UE.ECameraFocusMethod.Disable

        -- self.TrackingFocusParam = nil -- 使用了之后必须置空
    end
end

function HallCameraMgr:SwitchCamera(CameraIndex, BlendTime, PositionOffset, AbnormalPositionOffset, CameraAniLoop)
    if self.ModelHall == nil then
        return
    end

    if self.HallSceneMgr == nil then
        return
    end

    local CameraConfig = self.ModelHall:GetCameraConfig(CameraIndex)
    if CameraConfig == nil then
        return
    end

    if CameraAniLoop == nil then
        CameraAniLoop = true
    end

    CWaring("HallCameraMgr:SwitchCamera:" .. CameraIndex)
    local Param = {
        CameraIndex = CameraIndex
    }
    self.ModelHall:DispatchType(HallModel.ON_CAMERA_SWITCH_PRELOAD,Param)

	local Offset = UE.FVector()
	if PositionOffset ~= ""  and PositionOffset ~= nil then
		local OffsetStr = StringUtil.Split(PositionOffset, ",")
        Offset.x = tonumber(OffsetStr[1])
        Offset.y = tonumber(OffsetStr[2])
        Offset.z = tonumber(OffsetStr[3])
	end
	
	local AbnormalOffset = UE.FVector()
	if AbnormalPositionOffset ~= "" and AbnormalPositionOffset ~= nil then
		local abOffsetStr = StringUtil.Split(AbnormalPositionOffset, ",")
        AbnormalOffset.x = tonumber(abOffsetStr[1])
        AbnormalOffset.y = tonumber(abOffsetStr[2])
        AbnormalOffset.z = tonumber(abOffsetStr[3])
	end
    

	local FinalLoc = UE.FVector()
    local NewLoc = StringUtil.Split(CameraConfig.CameraLocation, ",")
    FinalLoc.x = tonumber(NewLoc[1]) + Offset.X
    FinalLoc.y = tonumber(NewLoc[2]) + Offset.y
    FinalLoc.z = tonumber(NewLoc[3]) + Offset.z

    local FinalRot = UE.FRotator()
	local NewRot = StringUtil.Split(CameraConfig.CameraRotation, ",")
    FinalRot.Pitch = tonumber(NewRot[1])
    FinalRot.Yaw = tonumber(NewRot[2])
    FinalRot.Roll = tonumber(NewRot[3])


    local FinalScl = UE.FVector()
	local NewScl = StringUtil.Split(CameraConfig.CameraScale, ",")
    FinalScl.x = tonumber(NewScl[1])
    FinalScl.y = tonumber(NewScl[2])
    FinalScl.z = tonumber(NewScl[3])

    if self.HallSceneMgr ~= nil then
        local ViewPortSize = UE.UWidgetLayoutLibrary.GetViewPortSize(self.HallSceneMgr)
        -- 狭长屏
        if ViewPortSize.X / ViewPortSize.Y >= 2 and CameraConfig.CameraLocationX and CameraConfig.CameraLocationX ~= "" then 
            local NewLocX = StringUtil.Split(CameraConfig.CameraLocationX, ",")
            if NewLocX ~= nil and #NewLocX == 3 then
                local FinalLocX = 
                {
                    x = tonumber(NewLocX[1]) + AbnormalOffset.x, 
                    y = tonumber(NewLocX[2]) + AbnormalOffset.y, 
                    z = tonumber(NewLocX[3]) + AbnormalOffset.z
                }
                FinalLoc.x = FinalLocX.x
                FinalLoc.y = FinalLocX.y
                FinalLoc.z = FinalLocX.z
            end
        end
        -- 短屏
        if ViewPortSize.X / ViewPortSize.Y <= 1.5 and CameraConfig.CameraLocationShort and CameraConfig.CameraLocationShort ~= "" then 
            local NewLocX = StringUtil.Split(CameraConfig.CameraLocationShort, ",")
            if NewLocX ~= nil and #NewLocX == 3 then
                local FinalLocX = 
                {
                    x = tonumber(NewLocX[1]) + AbnormalOffset.x, 
                    y = tonumber(NewLocX[2]) + AbnormalOffset.y, 
                    z = tonumber(NewLocX[3]) + AbnormalOffset.z
                }
                FinalLoc.x = FinalLocX.x
                FinalLoc.y = FinalLocX.y
                FinalLoc.z = FinalLocX.z
            end
        end
    end

    local NewTrans = UE.UKismetMathLibrary.MakeTransform(FinalLoc, FinalRot, FinalScl)
    local SwitchBlendTime = self:GetBlendTime(self.ModelHall.CameraIndex, CameraIndex, BlendTime)
    
    -- CLog("CameraConfig.FieldOfView = "..CameraConfig.FOV)
    if self.HallSceneMgr ~= nil then
        local NeedSwitch = false
        local NeedForce = true
        -- SwitchBlendTime = 0
        UE.UGameHelper.SwitchSceneCameraToTransform(
            self.HallSceneMgr,
            NewTrans, 
            CameraConfig.ProjectMode, 
            CameraConfig.FOV, 
            SwitchBlendTime, 
            NeedForce,NeedSwitch)

        local CameraActor =UE.UGameHelper.GetCurrentSceneCamera()
        if CameraActor and CameraActor:GetCineCameraComponent() then
            -- local CineCameraActor = self.Avatar:Cast(UE.A)
            local CineCameraComponent = CameraActor:GetCineCameraComponent()
            self:UpdateCameraFocusSetting()
            CLog("CameraConfig[Cfg_HallCameraConfig_P.CurrentFocalLength] = "..CameraConfig[Cfg_HallCameraConfig_P.CurrentFocalLength])
            CineCameraComponent:SetCurrentFocalLength(CameraConfig[Cfg_HallCameraConfig_P.CurrentFocalLength])
            CineCameraComponent:SetCurrentAperture(CameraConfig[Cfg_HallCameraConfig_P.CurrentAperture])
        end
    else
        CLog("HallSceneMgr Is Not Found")
    end

    self.ModelHall:SetCurCameraIndex(CameraIndex)
    
    if self.HallSceneMgr ~= nil then
        local PlayerCamerMgr = UE.UGameplayStatics.GetPlayerCameraManager(self.HallSceneMgr, 0)
        if PlayerCamerMgr == nil then
            return
        end
        -- PlayerCamerMgr:StopAllCameraAnims()

        if CameraConfig.CameraAnimPath ~= "" then
            local cameraAnimPath = CameraConfig.CameraAnimPath
            if viewPortSize.X / viewPortSize.Y >= 2 and CameraConfig.CameraAnimPathIpx ~= "" then 
                cameraAnimPath = CameraConfig.CameraAnimPathIpx
            end
          
            local SoftObjPath = UE.KismetSystemLibrary.MakeSoftObjectPath(CameraConfig.CameraAnimPath);
            local AssetObj = UE.URAFBlueprintFunctionLibrary.GetAssetByAssetReference(SoftObjPath);
            if AssetObj ~= nil then
                PlayerCamerMgr:PlayCameraAnim(AssetObj, 1, 1, 0, 0, CameraAniLoop)
            end
        end
    end
end

function HallCameraMgr:ResetPositionFromConfig(CameraIndex)
    -- local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
	-- if CameraActor == nil then
	-- 	return
	-- end
    local CameraConfig = self.ModelHall:GetCameraConfig(CameraIndex)
    if CameraConfig == nil then
        return
    end

	local FinalLoc = UE.FVector()
    local NewLoc = StringUtil.Split(CameraConfig.CameraLocation, ",")
    FinalLoc.x = tonumber(NewLoc[1])
    FinalLoc.y = tonumber(NewLoc[2])
    FinalLoc.z = tonumber(NewLoc[3])
    self:SetCurCameraLocation(FinalLoc)
end

function HallCameraMgr:ResetCurCameraPos()
    if not self.ModelHall then
        return
    end
    self:ResetPositionFromConfig(self.ModelHall.CurCameraIndex)
end

---重置相机
function HallCameraMgr:ResetCurCamera(BlendTime, PositionOffset, AbnormalPositionOffset, CameraAniLoop)
    if not self.ModelHall then
        return
    end
    self:SwitchCamera(self.ModelHall.CurCameraIndex, BlendTime, PositionOffset, AbnormalPositionOffset, CameraAniLoop)
end

function HallCameraMgr:GetBlendTime(CurCamerIndex, NextCameraIndex, InBlendTime)
    if self.ModelHall == nil then
        return 0
    end

	InBlendTime = InBlendTime or 0
	if InBlendTime ~= 0 then
		return InBlendTime
	end
    
	local CurCameraCfg = self.ModelHall:GetCameraConfig(CurCamerIndex)
	local NextCameraCfg = self.ModelHall:GetCameraConfig(NextCameraIndex)
		
	if CurCameraCfg ~= nil and NextCameraCfg ~= nil 
	    and CurCameraCfg.CameraGroup == NextCameraCfg.CameraGroup then
		    return NextCameraCfg.BlendTime
	end

	return 0
end


function HallCameraMgr:OnLoadStreamLevelComplete()
    if self.ModelHall == nil then
        return
    end
    local SceneID = self.ModelHall:GetSceneID()
    local CameraID = self.ModelHall:GetSceneCameraID(SceneID)
    if CameraID == 0  or CameraID == nil then
        CLog("Not Found Camera ID: SceneID = ".. SceneID)
        return 
    end
    CWaring("CameraID:" .. CameraID)
    self:SwitchCamera(CameraID, 0, "", "")

    local Param = {
        SceneID = SceneID
    }
    self.ModelHall:DispatchType(HallModel.ON_CAMERA_SWITCH_SUC,Param)
end

function HallCameraMgr:TRIGGER_CAMERA_SWITCH_Func(Param)
    self:SwitchCamera(Param.CameraID, 0, "", "")
end


function HallCameraMgr:OnUnLoadStreamLevelComplete()
    if self.ModelHall == nil then
        return
    end

    local Linkage = self.ModelHall.CurLinkage
end

function HallCameraMgr:ResetCameraByLS()
    --播放一下摄相机的LS进行校证位置
    local SetBindings = {}
    local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
    if CameraActor ~= nil then
        local CameraBinding = {
            ActorTag = "",
            Actor = CameraActor, 
            TargetTag = SequenceModel.BindTagEnum.CAMERA,
        }
        table.insert(SetBindings,CameraBinding)
    end
    local PlayParam = {
        LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_ENTER_HALL_FROMBATTLE),
        SetBindings = SetBindings,
    }
    MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(tostring(ViewConst.VirtualHall),nil, PlayParam)
end

-- 设置当前场景相机位置
function HallCameraMgr:SetCurCameraLocation(FinalLoc)
    if FinalLoc == nil then
        return
    end
    local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor == nil then
		return
	end
    CameraActor:K2_SetActorLocation(FinalLoc, false, nil, false)
end

function HallCameraMgr:GetCurCameraRotator()
    local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor == nil then
		return nil
	end

    return CameraActor:K2_GetActorRotation()
end

function HallCameraMgr:GetCurCameraLocation()
    local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor == nil then
		return nil
	end

    return CameraActor:K2_GetActorLocation()
end