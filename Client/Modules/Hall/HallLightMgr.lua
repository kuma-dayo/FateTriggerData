
local class_name = "HallLightMgr"
HallLightMgr = HallLightMgr or BaseClass(nil, class_name)

function HallLightMgr:__init(HallSceneMgr)	
    CLog("HallLightMgr:__init")
end

function HallLightMgr:__dispose()
    CLog("HallLightMgr:__dispose")	
    self:UnInit()
    self.HallSceneMgr = nil
    self.model = nil
end


function HallLightMgr:Init(HallSceneMgr)
    CLog("HallLightMgr:Init")
    self.HallSceneMgr = HallSceneMgr
    self.model = MvcEntry:GetModel(HallModel)
	self:AddListeners()
    self.bShouldBlockOnLoad = false
end

function HallLightMgr:UnInit()
	self:RemoveListeners()
end

function HallLightMgr:AddListeners()
	if self.model == nil then 
		return
	end
    self.model:AddListener(HallModel.ON_STREAM_LEVEL_LOAD_COMPLELTED, self.OnLoadStreamLevelComplete, self)
    -- self.model:AddListener(HallModel.ON_LIGHT_LEVEL_LOAD_COMPLELTED, self.OnLoadLightLevelComplete,	self)
    self.model:AddListener(HallModel.ON_STREAM_LEVEL_UNLOAD_COMPLELTED, self.OnUnLoadStreamLevelComplete, self)
    -- self.model:AddListener(HallModel.ON_LIGHT_LEVEL_UNLOAD_COMPLELTED, self.OnUnLoadLightLevelComplete, self)
end

function HallLightMgr:RemoveListeners()
	if self.model == nil then 
		return
	end
    self.model:RemoveListener(HallModel.ON_STREAM_LEVEL_LOAD_COMPLELTED, self.OnLoadStreamLevelComplete, self)
    -- self.model:RemoveListener(HallModel.ON_LIGHT_LEVEL_LOAD_COMPLELTED, self.OnLoadLightLevelComplete, self)
    self.model:RemoveListener(HallModel.ON_STREAM_LEVEL_UNLOAD_COMPLELTED, self.OnUnLoadStreamLevelComplete, self)
    -- self.model:RemoveListener(HallModel.ON_LIGHT_LEVEL_UNLOAD_COMPLELTED, self.OnUnLoadLightLevelComplete, self)
end

function HallLightMgr:OnLoadStreamLevelComplete()
    if self.model == nil then
        return
    end
    CLog("HallLightMgr.OnLoadStreamLevelComplete")
    local NewLightLevelID, _ = self.model:GetSceneLightLevel(self.model:GetSceneID())
    local ActiveLightLevelID = self.model:GetCurActiveLightLevelID()
    if ActiveLightLevelID == NewLightLevelID then
        self:LoadNewLightLevel(ActiveLightLevelID)
        return
    end

    self:UnLoadCurLightLevel()
    self:LoadNewLightLevel(NewLightLevelID)
end

function HallLightMgr:OnUnLoadStreamLevelComplete()
    if self.model == nil then
        return
    end
    CLog("HallLightMgr.OnUnLoadStreamLevelComplete")
end

function HallLightMgr:UnLoadCurLightLevel()
    if self.HallSceneMgr == nil then
        return
    end

    if self.model == nil then
        return
    end

    local ActiveLightLevelID = self.model:GetCurActiveLightLevelID()
    local LightLevelID, LightLevelName = self.model:GetLightLevel(ActiveLightLevelID)
    if LightLevelID == nil or LightLevelID == 0 then
        return
    end

    -- if self.HallSceneMgr:IsStreamLevelLoaded(LightLevelID) then
    --     self.HallSceneMgr:EnableStreamLevel(LightLevelID, false)
    -- else
    --     self.HallSceneMgr:UnLoadStreamLevel(LightLevelName, LightLevelID, HallModel.LevelType.LIGHT_LEVEL)
    -- end
    local InPackageName = StringUtil.Format("/Game/Maps/Hall/LightLevel/{0}",LightLevelName)
	local StreamLevel = UE.UGameplayStatics.GetStreamingLevel(self.HallSceneMgr, InPackageName)
	if not StreamLevel then
		CError("HallLightMgr:UnLoadCurLightLevel StreamLevel nil with package:" .. InPackageName)
		return
	end
    local LoadedLevel = StreamLevel:GetLoadedLevel()
	if LoadedLevel then
		--存在Cache
		StreamLevel:SetShouldBeVisible(false)
	end

    self.model:SetCurActiveLightLevelID(0)    
end


function HallLightMgr:LoadNewLightLevel(NewLightLevelID)
    if self.HallSceneMgr == nil then
        return
    end

    local LightLevelID, LightLevelName = self.model:GetLightLevel(NewLightLevelID)
    if LightLevelID == nil or LightLevelID == 0 then
        return
    end

    -- if self.HallSceneMgr:IsStreamLevelLoaded(LightLevelID) then
    --     self.HallSceneMgr:EnableStreamLevel(LightLevelID, true)
    -- else
    --     self.HallSceneMgr:LoadStreamLevel(LightLevelName, LightLevelID, HallModel.LevelType.LIGHT_LEVEL)
    -- end
    local NeedFlushSteam = false
    local InPackageName = StringUtil.Format("/Game/Maps/Hall/LightLevel/{0}",LightLevelName)
	local StreamLevel = UE.UGameplayStatics.GetStreamingLevel(self.HallSceneMgr, InPackageName)
	if not StreamLevel then
		CError("HallLightMgr:LoadNewLightLevel StreamLevel nil with package:" .. InPackageName)
		return
	end
    local LoadedLevel = StreamLevel:GetLoadedLevel()
	if LoadedLevel then
		--存在Cache
        if not CommonUtil.IsShipping() then
            CWaring("LoadNewLightLevel From Cache:" .. InPackageName)
        end
		StreamLevel:SetShouldBeVisible(true)
        NeedFlushSteam = true
    else
        self.HallSceneMgr:LoadStreamLevel(LightLevelName, LightLevelID, HallModel.LevelType.LIGHT_LEVEL,self.bShouldBlockOnLoad)
	end
    if NeedFlushSteam then
        self.HallSceneMgr:FlushStreamLevel()
    end

    self.model:SetCurActiveLightLevelID(NewLightLevelID)
end

-- function HallLightMgr:OnLoadLightLevelComplete()
--     if self.model == nil then
--         return
--     end

--     CLog("HallLightMgr.OnLoadLightLevelComplete")
-- end


-- function HallLightMgr:OnUnLoadLightLevelComplete()
--     if self.model == nil then
--         return
--     end

--     -- local _, StreamLevelID = self.model:GetCurLoadStreamLevel()
-- end
