require ("Client.Modules.Hall.HallCameraMgr")
require ("Client.Modules.Hall.HallAvatarMgr")
require ("Client.Modules.Hall.HallLightMgr")
require ("Client.Modules.Hall.HallApparelMgr")
require("Client.Modules.Hall.HallModel")

---@class HallSceneMgr
local HallSceneMgr = Class()

function HallSceneMgr:ReceiveBeginPlay()
	CLog("HallSceneMgr: BeginPlay")
	self.Overridden.ReceiveBeginPlay(self)

	self:Init()
	_G.HallSceneMgrInst = self
	MvcEntry:GetModel(HallModel):CheckHallSceneMgrActionCache()
end

function HallSceneMgr:Init()
	self.Model = MvcEntry:GetModel(HallModel)
	self.AvatarMgr = HallAvatarMgr.New()
	if self.AvatarMgr then
		self.AvatarMgr:Init(self)
	end

	self.CameraMgr = HallCameraMgr.New()
	if self.CameraMgr ~= nil then
		self.CameraMgr:Init(self)
	end	

	self.LightMgr = HallLightMgr.New()
	if self.LightMgr ~= nil then
		self.LightMgr:Init(self)
	end

	self.ApparelMgr = HallApparelMgr.New()
	if self.ApparelMgr ~= nil then
		self.ApparelMgr:Init(self)
	end

	self.SwitchSucCallback = nil

	self.HallIsLoadingLeveld = nil
	self.HallIsUnLoadingLevelIdPool = {}
	self.HallCacheNeedLoadInfo = nil
	self.HallCacheCheckTimer = nil
	self.HallDelayHideSceneTimer = nil

	--标记是否预加载
	self.IsPreloading = false
	-- self.PreloadingLevelList = {}

	self.bShouldBlockOnLoad = false

	MvcEntry:GetCtrl(CommonCtrl):AddMsgListener(CommonEvent.ON_APP_WILL_ENTER_BACKGROUND, self.OnAppWillEnterBackground, self)
	MvcEntry:GetCtrl(CommonCtrl):AddMsgListener(CommonEvent.ON_APP_HAS_ENTERED_FOREGROUND, self.OnAppHasEnteredForeground, self)

	if not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelHall) then
		CWaring("HallSceneMgr Wait LevelHall Loaded then RegisterCamera")
		MvcEntry:GetModel(ViewModel):AddListener(ViewConst.LevelHall, self.OnLoadHallLevelComplete, self)
	else
		CWaring("HallSceneMgr RegisterCamera")
		self:RegisterCamera();
	end
end

function HallSceneMgr:ReceiveEndPlay(EndPlayReason)
	CLog("HallSceneMgr: ReceiveEndPlay")
	--SoundMgr:PlaySound(SoundCfg.Music.MUSIC_STOP)
	self:UnInit()
	self.Overridden.ReceiveEndPlay(self,EndPlayReason)	
	_G.HallSceneMgrInst = nil
end


function HallSceneMgr:UnInit()
	if self.AvatarMgr ~= nil then
		self.AvatarMgr:Dispose()
		self.AvatarMgr = nil
	end
	if self.CameraMgr ~= nil then
		self.CameraMgr:Dispose()
		self.CameraMgr = nil
	end
	if self.LightMgr ~= nil then
		self.LightMgr:Dispose()
		self.LightMgr = nil
	end
	if self.ApparelMgr ~= nil then
		self.ApparelMgr:Dispose()
		self.ApparelMgr = nil
	end
	self.SwitchSucCallback = nil
	self:CleanCacheLoadCheck();

	CLog("HallSceneMgr:UnInit()")
	MvcEntry:GetCtrl(CommonCtrl):RemoveMsgListener(CommonEvent.ON_APP_WILL_ENTER_BACKGROUND, self.OnAppWillEnterBackground, self)
	MvcEntry:GetCtrl(CommonCtrl):RemoveMsgListener(CommonEvent.ON_APP_HAS_ENTERED_FOREGROUND, self.OnAppHasEnteredForeground, self)
	MvcEntry:GetModel(ViewModel):RemoveListener(ViewConst.LevelHall, self.OnLoadHallLevelComplete, self)

	self.Model:ReInit()
	self.Model = nil
end


function HallSceneMgr:OnLoadHallLevelComplete(State)
	if State then
		MvcEntry:GetModel(ViewModel):RemoveListener(ViewConst.LevelHall, self.OnLoadHallLevelComplete, self)
		self:RegisterCamera()
	end
end


function HallSceneMgr:RegisterCamera()
	CLog("RegisterCamera")
    local CameraActors = UE.UGameplayStatics.GetAllActorsWithTag(self, "HallCameraF")
    if CameraActors:Length() >= 1 then
        UE.UGameHelper.RegisterSceneCamera("HallCameraF", CameraActors:Get(1))
    end

    CameraActors = UE.UGameplayStatics.GetAllActorsWithTag(self, "HallCameraS")
    if CameraActors:Length() >= 1 then
        UE.UGameHelper.RegisterSceneCamera("HallCameraS", CameraActors:Get(1))
    end
end

function HallSceneMgr:CleanCacheLoadCheck()
	self.HallCacheNeedLoadInfo = nil
	if self.HallCacheCheckTimer then
		Timer.RemoveTimer(self.HallCacheCheckTimer)
	end
	self.HallCacheCheckTimer = nil
end
function HallSceneMgr:StartCacheLoadCheck(SceneId,LevelId)
	self.HallCacheNeedLoadInfo = {
		SceneId = SceneId,
		LevelId = LevelId,
	}
	if not self.HallCacheCheckTimer then
		self.HallCacheCheckTimer = Timer.InsertTimer(0,function()
			self:CacheLoadCheckFunc()
		end,true)
	end
end
function HallSceneMgr:CacheLoadCheckFunc()
	if not self.HallCacheNeedLoadInfo then
		self:CleanCacheLoadCheck()
	end
	if self.HallIsUnLoadingLevelIdPool[self.HallCacheNeedLoadInfo.LevelId] then
		return
	end
	local SceneID = self.HallCacheNeedLoadInfo.SceneId
	self:CleanCacheLoadCheck()
	self:SwitchScene(SceneID)
end

--[[
	SwitchSucCallback 切换成功回调
	流关卡及相机切换好，即表示切换成功
]]
function HallSceneMgr:SwitchScene(SceneID,SwitchSucCallback, DelayHideOldScene)
	DelayHideOldScene = DelayHideOldScene or 0
	CWaring("HallSceneMgr:SwitchScene" .. SceneID)
	if self.Model == nil then
		CError("HallSceneMgr:SwitchScene self.Model nil",true)
		return
	end
	if self.NeedWaitLoadStreamLevelComplete then
		CWaring("HallSceneMgr:SwitchScene NeedWaitLoadStreamLevelComplete")
		return
	end
	if self.NeedWaitUnloadStreamLevelComplete then
		CWaring("HallSceneMgr:SwitchScene NeedWaitUnloadStreamLevelComplete")
		return
	end

	local StreamLevelID, StreamLevelName = self.Model:GetSceneStreamLevel(SceneID)
	if StreamLevelID == nil or StreamLevelID == 0 then
		CError("HallSceneMgr:SwitchScene not found config:" .. SceneID,true)
		return
	end
	self.SwitchSucCallback = SwitchSucCallback
	self.NeedWaitLoadStreamLevelComplete = false
	self.NeedWaitUnloadStreamLevelComplete = false
	--TODO 判断场景ID是否一致，如果一致，直接执事件标记流关卡加载完成
	local CurSceneID = self.Model:GetSceneID()
	if CurSceneID == SceneID then
		CWaring("SwitchScene same===============:" .. SceneID)
		local InPackageName = StringUtil.Format("/Game/Maps/Hall/StreamLevel/{0}",StreamLevelName)
		local StreamLevel = UE.UGameplayStatics.GetStreamingLevel(self, InPackageName)
		if StreamLevel then
			local LoadedLevel = StreamLevel:GetLoadedLevel()
			if LoadedLevel then	
				-- 可见性会被预加载关掉，这里需要开启一下
				StreamLevel:SetShouldBeVisible(true)
			end
		end
		local Linkage = self:CalculateLinkage(StreamLevelID,HallModel.LevelType.STREAM_LEVEL)
		self:OnLoadStreamLevelCompleteInner(Linkage)
		return
	end

	--TODO 判断旧场景与新场景的流关卡是否一致，如果一致，切换当前场景ID，直接抛事件标记流关卡加载完成
	if CurSceneID > 0 then
		local CurStreamLevelID, CurStreamLevelName = self.Model:GetSceneStreamLevel(CurSceneID)
		if CurStreamLevelID == StreamLevelID then
			CWaring("StreamLevelID same===============:" .. StreamLevelID)
			self:OnSwitchSceneAction(SceneID)
			local Linkage = self:CalculateLinkage(StreamLevelID,HallModel.LevelType.STREAM_LEVEL)--(StreamLevelID * 10 + 1)  * 10 + HallModel.LevelType.STREAM_LEVEL
			self:OnLoadStreamLevelCompleteInner(Linkage)
			return
		end
	end


	--检测是否正在加载
	if self.HallIsLoadingLeveld == StreamLevelID then
		CWaring(StringUtil.Format("SwitchScene Fail: Target StreamLevelID:{0} is Loading",StreamLevelID))
		return
	end
	--检测是否在加载池里面
	if self.HallCacheNeedLoadInfo and self.HallCacheNeedLoadInfo.LevelId == StreamLevelID then
		CWaring(StringUtil.Format("SwitchScene Fail: Target StreamLevelID:{0} is in Cache",StreamLevelID))
		return
	end
	--检测是否正在卸载中
	if self.HallIsUnLoadingLevelIdPool[StreamLevelID] then
		CWaring(StringUtil.Format("SwitchScene Fail: StreamLevelID:{0} is UnLoading!!",StreamLevelID))
		self:StartCacheLoadCheck(SceneID,StreamLevelID)
		return
	end

	self.NeedWaitLoadStreamLevelComplete = true
	self:CleanCacheLoadCheck();
	self:CleanHallDelayHideSceneTimer()
	--加载新的
	self.HallIsLoadingLeveld = StreamLevelID
	CWaring("StreamLevelName:" .. StreamLevelName)
	CWaring("StreamLevelID:" .. StreamLevelID)
	-- self:LoadStreamLevel(StreamLevelName, StreamLevelID, HallModel.LevelType.STREAM_LEVEL)


	local NeedFlushSteam = false
	self:OnSwitchSceneAction(SceneID)
	local InPackageName = StringUtil.Format("/Game/Maps/Hall/StreamLevel/{0}",StreamLevelName)
	local StreamLevel = UE.UGameplayStatics.GetStreamingLevel(self, InPackageName)
	if not StreamLevel then
		CError("StreamLevel nil with package:" .. InPackageName)
		return
	end
	local LoadedLevel = StreamLevel:GetLoadedLevel()
	if LoadedLevel then
		--存在Cache
		StreamLevel:SetShouldBeVisible(true)

		local Linkage = self:CalculateLinkage(StreamLevelID,HallModel.LevelType.STREAM_LEVEL)
		CWaring("SwitchScene From Cache")
		self:OnLoadStreamLevelCompleteInner(Linkage)
		NeedFlushSteam = true
	else
		self:LoadStreamLevel(StreamLevelName, StreamLevelID, HallModel.LevelType.STREAM_LEVEL,self.bShouldBlockOnLoad)
	end


	--TODO 处于旧关卡卸载
	if CurSceneID > 0 and CurSceneID ~= SceneID then
		self.Model:DispatchType(HallModel.ON_HALL_SCENE_SWITCH)
		local CurStreamLevelID, CurStreamLevelName = self.Model:GetSceneStreamLevel(CurSceneID)
		if CurStreamLevelID ~= nil and CurStreamLevelID ~= 0 and CurStreamLevelID ~= StreamLevelID then
			self.NeedWaitUnloadStreamLevelComplete = true
			self.HallIsUnLoadingLevelIdPool[StreamLevelID] = 1
			CWaring("HallSceneMgr Unload StreamLevelID:" .. CurStreamLevelID)

			local InPackageName = StringUtil.Format("/Game/Maps/Hall/StreamLevel/{0}",CurStreamLevelName)
			local StreamLevel = UE.UGameplayStatics.GetStreamingLevel(self, InPackageName)
			if DelayHideOldScene == 0 then
				StreamLevel:SetShouldBeVisible(false)
			else
				self.HallDelayHideSceneTimer = Timer.InsertTimer(DelayHideOldScene,function()
					StreamLevel:SetShouldBeVisible(false)
				end)
			end

			local Linkage = self:CalculateLinkage(CurStreamLevelID,HallModel.LevelType.STREAM_LEVEL)
			self:OnUnLoadStreamLevelComplete(Linkage)
			NeedFlushSteam = true
		end
	end
	if NeedFlushSteam then
		self:FlushStreamLevel()
	end

	self:LocateBGEffection(SceneID)
end

function HallSceneMgr:CleanHallDelayHideSceneTimer()
	if self.HallDelayHideSceneTimer then
		Timer.RemoveTimer(self.HallDelayHideSceneTimer)
	end
	self.HallDelayHideSceneTimer = nil
end

function HallSceneMgr:OnSwitchSceneAction(SceneID)
	self.Model:SetSceneID(SceneID)
end

function HallSceneMgr:CleanSwitchSucCallBack()
	self.SwitchSucCallback = nil
end


function HallSceneMgr:LocateBGEffection(SceneID)
	local Actors = UE.UGameplayStatics.GetAllActorsWithTag(self, "HallBGEffect")
	if Actors:Num() > 0 then
		local BGEffectionActor = Actors:Get(1):Cast(UE.ANiagaraActor)
		if BGEffectionActor and BGEffectionActor.NiagaraComponent then
			local BGEffectLocation = self.Model:GetSceneEffectPosition(SceneID)
			if not BGEffectLocation then
				CWaring("LocateBGEffection: Not Found The Position!")
				BGEffectionActor.NiagaraComponent:SetActive(false, false)
			else
				BGEffectionActor.NiagaraComponent:SetActive(true, false)
				BGEffectionActor:SetActorHiddenInGame(false)
				BGEffectionActor:K2_SetActorLocation(BGEffectLocation, false, nil, false)
			end
			return
		end
	else
		CWaring("LocateBGEffection: Not Found The Effect!")
	end
end

function HallSceneMgr:ActiveHallBGEffect(bActive)
	local Actors = UE.UGameplayStatics.GetAllActorsWithTag(self, "HallBGEffect")
	if Actors:Num() > 0 then
		local BGEffectionActor = Actors:Get(1):Cast(UE.ANiagaraActor)
		if BGEffectionActor then
			BGEffectionActor:SetActorHiddenInGame(not(bActive))
		end
		if BGEffectionActor and BGEffectionActor.NiagaraComponent then
			if not bActive then
				BGEffectionActor.NiagaraComponent:SetActive(false, false)
				BGEffectionActor:SetActorHiddenInGame(true)
			else
				BGEffectionActor.NiagaraComponent:SetActive(true, false)
				BGEffectionActor:SetActorHiddenInGame(false)
			end
			return
		end
	end
end

function HallSceneMgr:SetActorHiddenByTag(Tag, bHide)
	local Actors = UE.UGameplayStatics.GetAllActorsWithTag(self, Tag)
	if Actors:Num() > 0 then
		for k, TempActor in pairs(Actors) do
			TempActor:SetActorHiddenInGame(bHide)
		end
	end
end

--CALLBACK FROM C++
function HallSceneMgr:OnLoadStreamLevelComplete(Linkage)
	CLog("HallSceneMgr: OnLoadStreamLevelComplete:" .. Linkage)
	if self.IsPreloading then
		-- 预加载完成通知
		self:OnPreloadCompleted(Linkage)
	else
		local LevelID, LevelType, IsLoading = self:GetCurLinkageInfo(Linkage)
		if LevelType == HallModel.LevelType.STREAM_LEVEL then
			self:OnLoadStreamLevelCompleteInner(Linkage)
		end
		self:FlushStreamLevel()
	end
end 

function HallSceneMgr:OnLoadStreamLevelCompleteInner(Linkage)
	CLog("HallSceneMgr: OnLoadStreamLevelCompleteInner:" .. Linkage)
	-- 正常加载完成
	self.NeedWaitLoadStreamLevelComplete = false
	self.HallIsLoadingLeveld = nil
	if self.Model == nil then
		return
	end
	self.Model:OnLoadStreamLevelComplete(Linkage)	

	self:CheckSucCallBackExcute()
end

function HallSceneMgr:CheckSucCallBackExcute()
	if self.NeedWaitLoadStreamLevelComplete then
		CWaring("HallSceneMgr:CheckSucCallBackExcute NeedWaitLoadStreamLevelComplete")
		return
	end
	if self.NeedWaitUnloadStreamLevelComplete then
		CWaring("HallSceneMgr:CheckSucCallBackExcute NeedWaitUnloadStreamLevelComplete")
		return
	end
	self:FlushStreamLevel()
	--在此帧，流关卡和相机分别加载好了和切换好了
	if self.SwitchSucCallback then
		CWaring("HallSceneMgr:CheckSucCallBackExcute Suc")
		self.SwitchSucCallback()
	end
	self.Model:DispatchType(HallModel.ON_HALL_SCENE_SWITCH_COMPLETED)
	self.SwitchSucCallback = nil
end



--CALLBACK FROM C++
function HallSceneMgr:OnUnLoadStreamLevelComplete(Linkage)
	self.NeedWaitUnloadStreamLevelComplete = false
	local LevelID, LevelType, IsLoading = self:GetCurLinkageInfo(Linkage)
	CWaring("HallSceneMgr:OnUnLoadStreamLevelComplete StreamLevelID:" .. LevelID)
	if LevelType == HallModel.LevelType.STREAM_LEVEL then
		self.HallIsUnLoadingLevelIdPool[LevelID] = nil
		-- CLog("HallSceneMgr: OnUnLoadStreamLevelComplete")
		if self.Model == nil then
			return
		end

		self.Model:OnUnLoadStreamLevelComplete(Linkage)
		self:CheckSucCallBackExcute()
	end
end



function HallSceneMgr:OnAppWillEnterBackground()
	-- CLog("HallSceneMgr:OnAppWillEnterBackground")
end	

function HallSceneMgr:OnAppHasEnteredForeground()
	-- CLog("HallSceneMgr:OnAppHasEnteredForeground")
end

function HallSceneMgr:GetCurLinkageInfo(linkage)
    local LevelType = math.fmod(linkage, 10)
    local IsLoading = math.fmod(math.modf(linkage, 10) ,10)
    local LevelID = math.floor(linkage/100);
    return LevelID, LevelType, IsLoading
end

function HallSceneMgr:CalculateLinkage(StreamLevelID,LevelType)
	local Linkage = (StreamLevelID * 10 + 1)  * 10 + LevelType
	print("Linkage:" .. Linkage)
	return Linkage
end


--------------------------
function HallSceneMgr:PreloadSteamLevel(StreamLevelID,StreamLevelName,LevelType)
	if self.Model == nil then
		CError("HallSceneMgr:PreloadSteamLevel self.Model nil",true)
		return false
	end
	if StreamLevelID == nil or StreamLevelID == 0 then
		CError("HallSceneMgr:PreloadSteamLevel StreamLevelID error")
		return false
	end
	if not CommonUtil.IsShipping() then
		CLog(StringUtil.Format("PreloadSteamLevel: Target StreamLevelID:{0} StreamLevelName:{1}",StreamLevelID,StreamLevelName))
	end

	-- --检测是否正在加载
	-- if self.PreloadingLevelList[StreamLevelID] then
	-- 	CWaring(StringUtil.Format("PreloadSteamLevel Fail: Target StreamLevelID:{0} is Loading",StreamLevelID))
	-- 	return
	-- end
	--加载新的
	local InPackageName = nil
	if LevelType == HallModel.LevelType.STREAM_LEVEL then
		InPackageName = StringUtil.Format("/Game/Maps/Hall/StreamLevel/{0}",StreamLevelName)
	else
		InPackageName = StringUtil.Format("/Game/Maps/Hall/LightLevel/{0}",StreamLevelName)
	end

	if not InPackageName then
		CError("PreloadSteamLevel InPackageName nil:" .. StreamLevelID)
		return false
	end
	
	local StreamLevel = UE.UGameplayStatics.GetStreamingLevel(self, InPackageName)
	if not StreamLevel then
		CError("PreloadSteamLevel StreamLevel nil with package:" .. InPackageName)
		return false
	end
	
	local LoadedLevel = StreamLevel:GetLoadedLevel()
	if LoadedLevel then
		--存在Cache
		-- StreamLevel:SetShouldBeVisible(false)
		self:CheckStreamLevelShouldBeVisible(StreamLevel,StreamLevelID)

		-- local Linkage = self:CalculateLinkage(StreamLevelID,HallModel.LevelType.STREAM_LEVEL)
		-- self:OnLoadStreamLevelComplete(Linkage)
		return false
	else
		-- self.PreloadingLevelList[StreamLevelID] = StreamLevelName
		self:LoadStreamLevel(StreamLevelName, StreamLevelID, LevelType,self.bShouldBlockOnLoad)
		return true
	end
end

function HallSceneMgr:CheckStreamLevelShouldBeVisible(StreamLevel,LevelID)
	-- if LevelID == 1010 or LevelID == 2010 then
	-- 	CWaring("HallSceneMgr:CheckStreamLevelShouldBeVisible ShouldBeVisible false")
	-- 	self:FlushStreamLevel()
	-- else
		StreamLevel:SetShouldBeVisible(false)
	-- end
end

function HallSceneMgr:OnPreloadCompleted(Linkage)
	if self.Model == nil then
		CError("HallSceneMgr:OnPreloadCompleted self.Model nil.Completed Linkage = "..Linkage,true)
		return
	end
	local LevelID, LevelType = self.Model:ParseLinkageInfo(Linkage)
	-- local StreamLevelID = self.Model:ParseLinkageInfo(Linkage)
	-- local StreamLevelName = self.PreloadingLevelList[StreamLevelID]
	-- if not StreamLevelName then
	-- 	CError("HallSceneMgr:OnPreloadCompleted Can't Find Record For Id = "..StreamLevelID,true)
	-- 	return
	-- end
	if LevelType == HallModel.LevelType.STREAM_LEVEL then
		local StreaLevelID,StreamLevelName = MvcEntry:GetModel(HallModel):GetStreamLevel(LevelID)
		local InPackageName = StringUtil.Format("/Game/Maps/Hall/StreamLevel/{0}",StreamLevelName)
		local StreamLevel = UE.UGameplayStatics.GetStreamingLevel(self, InPackageName)
		if not StreamLevel then
			CError("OnPreloadCompleted StreamLevel nil with package:" .. InPackageName)
		else
			local LoadedLevel = StreamLevel:GetLoadedLevel()
			if LoadedLevel then
				-- StreamLevel:SetShouldBeVisible(false)
				self:CheckStreamLevelShouldBeVisible(StreamLevel,StreaLevelID)
				self.Model:DispatchType(HallModel.ON_STREAM_LEVEL_PRELOAD_COMPLELTED,LevelID)
			else
				CWaring("OnPreloadCompleted StreamLevel Not Loaded: " .. InPackageName)
			end
		end
	else
		local LightLevelID,LightLevelName = MvcEntry:GetModel(HallModel):GetLightLevel(LevelID)
		local InPackageName = StringUtil.Format("/Game/Maps/Hall/LightLevel/{0}",LightLevelName)
		local StreamLevel = UE.UGameplayStatics.GetStreamingLevel(self, InPackageName)
		if not StreamLevel then
			CError("HallLightMgr:LoadNewLightLevel StreamLevel nil with package:" .. InPackageName)
			return
		end
		local LoadedLevel = StreamLevel:GetLoadedLevel()
		if LoadedLevel then
			-- StreamLevel:SetShouldBeVisible(false)
			self:CheckStreamLevelShouldBeVisible(StreamLevel,LightLevelID)
			self.Model:DispatchType(HallModel.ON_STREAM_LEVEL_PRELOAD_COMPLELTED,LevelID)
		end
	end
end

function HallSceneMgr:SetIsPreloading(Value)
	self.IsPreloading = Value
end


function HallSceneMgr:SetMediaSound(MediaPlayer)
    local MediaAudioActor = self:GetMediaSoundActor()
    if CommonUtil.IsValid(MediaAudioActor) then
        local Name = GetObjectName(MediaAudioActor:GetMediaPlayer())
        CWaring("HallSceneMgr:SetMediaSound, ObjectName = "..tostring(Name))
        MediaAudioActor:SetMediaPlayer(MediaPlayer)
        Name = GetObjectName(MediaAudioActor:GetMediaPlayer())
        CWaring("HallSceneMgr:SetMediaSound, ObjectName = "..tostring(Name))
    end
end

function HallSceneMgr:GetMediaSoundActor()
    if not(CommonUtil.IsValid(self.MediaSoundActor)) then
        local CurWorld = _G.GameInstance:GetWorld()
        if CurWorld == nil then
            CWaring("HallSceneMgr:GetMediaSoundActor, Not Found CurWorld")
            return 
        end
        local MediaSoundActorClass = UE.UClass.Load("/Game/BluePrints/Hall/MediaSound/BP_MediaSound.BP_MediaSound")
        if MediaSoundActorClass == nil then
            CError("HallSceneMgr:GetMediaSoundActor, Not Found BP_MediaSound Class !!!", true)
            return
        end
    
        local SpawnLocation = UE.FVector(0, 0, 0)
        local SpawnRotation = UE.FRotator(0, 0, 0)
        local SpawnScale = UE.FVector(1, 1, 1)
        local SpawnTrans = UE.UKismetMathLibrary.MakeTransform(SpawnLocation, SpawnRotation, SpawnScale)
        self.MediaSoundActor = CurWorld:SpawnActor(MediaSoundActorClass, SpawnTrans, UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
        if not(CommonUtil.IsValid(self.MediaSoundActor)) then 
            CError("HallSceneMgr:GetMediaSoundActor, Create MediaSoundActor Failed !!!", true)
            return
        end
    end

    return self.MediaSoundActor
end


return HallSceneMgr
