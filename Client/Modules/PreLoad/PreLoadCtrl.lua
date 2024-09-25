--[[
    资源预加载模块
]]

require("Client.Modules.PreLoad.PreLoadModel")

local class_name = "PreLoadCtrl"
---@class PreLoadCtrl : UserGameController
PreLoadCtrl = PreLoadCtrl or BaseClass(UserGameController,class_name)

function PreLoadCtrl:__init()
	---@type PreLoadModel
	self.PreLoadModel = MvcEntry:GetModel(PreLoadModel)
end

function PreLoadCtrl:Initialize()
    self.PreLoadOutSideAssetList = 
    {
		{Path = "/Game/BluePrints/Hall/Weapon/BP_HallWeaponBase.BP_HallWeaponBase_C", IsPersistence = false},
		{Path = "/Game/BluePrints/Hall/Hero/BP_HallHeroBase.BP_HallHeroBase_C", IsPersistence = false},
		{Path = "/Game/BluePrints/Hall/LS/BP_HallLSActor.BP_HallLSActor_C", IsPersistence = false},
		{Path = "/Game/BluePrints/UMG/OutsideGame/Hall/WBP_HallMain.WBP_HallMain_C", IsPersistence = false},
		{Path = "/Game/BluePrints/UMG/OutsideGame/Hall/WBP_HallTabPlay.WBP_HallTabPlay_C", IsPersistence = false},
		{Path = "/Game/BluePrints/UMG/OutsideGame/Hall/WBP_Hall_ActivityEntrance.WBP_Hall_ActivityEntrance_C", IsPersistence = false},
		{Path = "/Game/BluePrints/UMG/OutsideGame/Match/WBP_MatchEntrance.WBP_MatchEntrance_C", IsPersistence = false},
		{Path = "/Game/BluePrints/UMG/OutsideGame/Questionnaire/WBP_Questionnaire_Entrance.WBP_Questionnaire_Entrance_C", IsPersistence = false},

		{Path = "/Game/BluePrints/UMG/Components/WBP_NetLoading.WBP_NetLoading_C", IsPersistence = true},
		{Path = "/Game/BluePrints/UMG/Components/WBP_Common_ConfirmPopUp.WBP_Common_ConfirmPopUp_C", IsPersistence = true},
		{Path = "/Game/BluePrints/UMG/Components/WBP_UIAlert.WBP_UIAlert_C", IsPersistence = true},
		
		{Path = "StringTable'/Game/DataTable/ExtractLocalization/SD_ExtractLocalization.SD_ExtractLocalization'", IsPersistence = true},
		{Path = "ExcelPlusDataTable'/Game/DataTable/DT_TerminologyCfg.DT_TerminologyCfg'", IsPersistence = true},
		
		--英雄
		--SkeletalMesh
		{Path = "SkeletalMesh'/Game/Arts/Character/Hero01/Base/Meshes/SK_Hero01.SK_Hero01'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Character/Hero02N/Base/Meshes/SK_Hero02N.SK_Hero02N'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Character/Hero03/Base/Meshes/SK_Hero03.SK_Hero03'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Character/Hero04/Base/Meshes/SK_Hero04.SK_Hero04'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Character/Hero06/Base/Meshes/SK_Hero06.SK_Hero06'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Character/Hero06/Epic01/Meshes/SK_Hero06_Epic01.SK_Hero06_Epic01'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Character/Hero07/Base/Meshes/SK_Hero07.SK_Hero07'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Character/Hero09/Base/Meshes/SK_Hero09.SK_Hero09'", IsPersistence = false},
		--AB
		{Path = "/Game/Arts/Character/Hero01/Base/Animations/ABPC_Hero01.ABPC_Hero01_C", IsPersistence = false},
		{Path = "/Game/Arts/Character/Hero02N/Base/Animations/ABPC_Hero02N.ABPC_Hero02N_C", IsPersistence = false},
		{Path = "/Game/Arts/Character/Hero03/Base/Animations/ABPC_Hero03.ABPC_Hero03_C", IsPersistence = false},
		{Path = "/Game/Arts/Character/Hero04/Base/Animations/ABPC_Hero04.ABPC_Hero04_C", IsPersistence = false},
		{Path = "/Game/Arts/Character/Hero06/Base/Animations/ABPC_Hero06.ABPC_Hero06_C", IsPersistence = false},
		{Path = "/Game/Arts/Character/Hero07/Base/Animations/ABPC_Hero07.ABPC_Hero07_C", IsPersistence = false},
		{Path = "/Game/Arts/Character/Hero09/Base/Animations/ABPC_Hero09.ABPC_Hero09_C", IsPersistence = false},
		--英雄入场语音
		{Path = "AkAudioEvent'/Game/WwiseAsset/Event/VO/VO_Hero01/AKE_Play_VO_Hero01_10101.AKE_Play_VO_Hero01_10101'", IsPersistence = false},
		{Path = "AkAudioEvent'/Game/WwiseAsset/Event/VO/VO_Hero02/AKE_Play_VO_Hero02_10102.AKE_Play_VO_Hero02_10102'", IsPersistence = false},
		{Path = "AkAudioEvent'/Game/WwiseAsset/Event/VO/VO_Hero03/AKE_Play_VO_Hero03_10101.AKE_Play_VO_Hero03_10101'", IsPersistence = false},
		{Path = "AkAudioEvent'/Game/WwiseAsset/Event/VO/VO_Hero04/AKE_Play_VO_Hero04_10101.AKE_Play_VO_Hero04_10101'", IsPersistence = false},
		{Path = "AkAudioEvent'/Game/WwiseAsset/Event/VO/VO_Hero06/AKE_Play_VO_Hero06_10102.AKE_Play_VO_Hero06_10102'", IsPersistence = false},
		{Path = "AkAudioEvent'/Game/WwiseAsset/Event/VO/VO_Hero07/AKE_Play_VO_Hero07_10101.AKE_Play_VO_Hero07_10101'", IsPersistence = false},
		{Path = "AkAudioEvent'/Game/WwiseAsset/Event/VO/VO_Hero09/AKE_Play_VO_Hero09_10201.AKE_Play_VO_Hero09_10201'", IsPersistence = false},
		--枪
		{Path = "SkeletalMesh'/Game/Arts/Weapon/SMG/FMG9/Base/Meshes/SK_FMG9.SK_FMG9'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Weapon/Rifle/M4/Base/Meshes/SK_M4.SK_M4'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Weapon/Sniper/M24/Base/Meshes/SK_M24.SK_M24'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Weapon/Rifle/AK/Base/Meshes/SK_AK.SK_AK'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Weapon/SMG/Thompson/Base/Meshes/SK_Thompson.SK_Thompson'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Weapon/Sniper/SKS/Base/Meshes/SK_SKS.SK_SKS'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Weapon/Shotgun/S12k/Base/Meshes/SK_S12K.SK_S12K'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Weapon/SMG/Vector/Base/Meshes/SK_Vector.SK_Vector'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Weapon/Sniper/Kleber/Base/Meshes/SK_Kleber.SK_Kleber'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Weapon/MG/ChauChat/Base/Meshes/SK_Chauchat.SK_Chauchat'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Weapon/Rifle/Famas/Base/Meshes/SK_W3P_Famas.SK_W3P_Famas'", IsPersistence = false},
		{Path = "SkeletalMesh'/Game/Arts/Weapon/MG/M249/Base/Meshes/SK_M249.SK_M249'", IsPersistence = false},
		--载具
		{Path = "/Game/BluePrints/Hall/Vehicle/BP_Hall_Vehicle01.BP_Hall_Vehicle01_C", IsPersistence = false},
		{Path = "/Game/BluePrints/Hall/Vehicle/BP_Hall_Vehicle02.BP_Hall_Vehicle02_C", IsPersistence = false},

	}

	self.PreLoadStrTableList = {
		"/Game/DataTable/ExtractLocalization/SD_ExtractLocalization.SD_ExtractLocalization"
	}

	self.NeedUnRefPathMap = {}
	self.PreLoadOutSideAssetListFix = nil

	-- self.IsPreLoading = false


	self.NeedLoadStreamLevelMap = {}
end

function PreLoadCtrl:OnLogout()
	self:CleanPreSpawnActors()
end

function PreLoadCtrl:AddMsgListenersUser()
	self.MsgList = {
        { Model = CommonModel, MsgName = CommonModel.ON_PRELOAD_OUTSIDE_ASSTE_LIST_NEED_UPDATE,    Func = self.ON_PRELOAD_OUTSIDE_ASSTE_LIST_NEED_UPDATE },
        { Model = HallModel, MsgName = HallModel.ON_STREAM_LEVEL_PRELOAD_COMPLELTED,    Func = self.ON_STREAM_LEVEL_PRELOAD_COMPLELTED },
    }
end

function PreLoadCtrl:ON_PRELOAD_OUTSIDE_ASSTE_LIST_NEED_UPDATE()
	self.PreLoadOutSideAssetListFix = nil
end

function PreLoadCtrl:CheckPreLoadOutSideAssetListFix(IsFromStarup)
	local TheHeroModel = self:GetModel(HeroModel)
	if not self.PreLoadOutSideAssetListFix then
		--TODO 根据当前选择找英雄及武器去定制需要预加载的资源
		self.PreLoadOutSideAssetListFix = DeepCopy(self.PreLoadOutSideAssetList)

		local CacheSelectHeroId = SaveGame.GetItem("CacheSelectHeroId",true) or nil
		if not CacheSelectHeroId then
			CacheSelectHeroId = TheHeroModel:GetDefaultHeroId()
		end
		if CacheSelectHeroId and CacheSelectHeroId > 0 then
			-- SkinBP
			local SkinId = TheHeroModel:GetFavoriteSkinIdByHeroId(CacheSelectHeroId)
			local HeroSkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin, Cfg_HeroSkin_P.SkinId, SkinId)
			if HeroSkinCfg and HeroSkinCfg[Cfg_HeroSkin_P.SkinBP] then
				local SkinBPPath = CommonUtil.FixBlueprintPathWithoutPre(HeroSkinCfg[Cfg_HeroSkin_P.SkinBP],true)

				table.insert(self.PreLoadOutSideAssetListFix,{Path = SkinBPPath, IsPersistence = false})
			end

			-- DA
			-- local AvatarIDs = TheHeroModel:GetAvatarIDsBySkinId(SkinId)
			-- if AvatarIDs and #AvatarIDs > 0 then
			-- 	local DAPathList = UE.UHallAvatarCommonComponent.GetAvatarAssetPathStrByIDs(GameInstance, AvatarIDs)
			-- 	if DAPathList and DAPathList:Length() > 0 then
    		-- 		for _,DAPath in pairs(DAPathList) do
			-- 			print(" ======================== DAPathList: "..DAPath)
			-- 			-- table.insert(self.PreLoadOutSideAssetListFix,{Path = DAPath, IsPersistence = false})
			-- 			-- 当帧加载DA，再预加载DA中的资源
			-- 			local DAObj = LoadObject(DAPath)
			-- 			if DAObj then
			-- 				-- todo 
			-- 			end
			-- 		end
			-- 	end
			-- end


			if IsFromStarup then
				-- 入场LS
				local LevelSequenceAsset, IsEnablePostProcess = TheHeroModel:GetSkinLSPathBySkinIdAndKey(SkinId,HeroModel.LSEventTypeEnum.LSPathEnterHall)
				if LevelSequenceAsset then
					table.insert(self.PreLoadOutSideAssetListFix,{Path = LevelSequenceAsset, IsPersistence = false})
				end
				LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_ENTER_HALL)
				if LevelSequenceAsset then
					table.insert(self.PreLoadOutSideAssetListFix,{Path = LevelSequenceAsset, IsPersistence = false})
				end
			end
			
		end

		for k,v in ipairs(self.PreLoadOutSideAssetListFix) do
			if not v.IsPersistence then
				self.NeedUnRefPathMap[v.Path] = 1
			end
		end
	end
end

--[[
	预加载局外所需资源
]]
function PreLoadCtrl:PreLoadOutSideAction(FinishedCallBack,IsFromStarup)
	-- if self.IsPreLoading then
	-- 	CWaring("PreLoadCtrl:PreLoadOutSideAction IsPreLoading true,please check logic")
	-- 	return
	-- end
	self:CheckPreLoadOutSideAssetListFix(IsFromStarup)
	if not self.PreLoadOutSideAssetListFix then
		CWaring("PreLoadCtrl:PreLoadOutSideAction PreLoadOutSideAssetListFix nil,please check logic")
		FinishedCallBack();
		return
	end
	self.FinishCallBack = FinishedCallBack

	self.PreLoadModel:SetPreloadStep(PreLoadModel.PRELOADING_STEP.ASSET)
	-- self.IsPreLoading = true
	self:GetSingleton(AsyncLoadAssetCtrl):StartAyncLoad(self.PreLoadOutSideAssetListFix,function ()
		CWaring("PreLoadCtrl:RequestAsyncLoadList Suc")
		
		for k,InStrTableKey in ipairs(self.PreLoadStrTableList) do
			G_ConfigHelper:GetStrTableRow(InStrTableKey, nil,true)
		end
		if self.PreLoadModel:IsQuitPreload() then
			CWaring("RequestAsyncLoadListSuc After Quit.")
			-- 提前结束了
			return
		end
		self:DoPreSpawnActors()
		if not self:DoPreLoadStreamLevels() then
			self:DoPreloadFinish()
		end
	end)
end

function PreLoadCtrl:CleanPreSpawnActors()
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if not HallAvatarMgr then
		return
	end
	local SelfId = MvcEntry:GetModel(UserModel).PlayerId
	print("PreLoadCtrl:CleanPreSpawnActors", SelfId)
	local HeroAvatar = HallAvatarMgr:GetHallAvatar(SelfId)
	if HeroAvatar then
		HallAvatarMgr:RemoveAvatarByInstID(SelfId)	
	end
end

function PreLoadCtrl:DoPreSpawnActors()
	--目前只有入场角色需要预先创建
	local SelfId = MvcEntry:GetModel(UserModel).PlayerId
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr ~= nil then
		local TeamTransform = MvcEntry:GetModel(TeamModel):GetTeamTransform(SelfId)
		local CurSelectHeroId = MvcEntry:GetModel(HeroModel):GetFavoriteId()
		local CurSelectSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(CurSelectHeroId)
		local SpawnHeroParam = {
			ViewID = ViewConst.Hall*100 + CommonConst.HL_PLAY,
			InstID = SelfId,
			HeroId = CurSelectHeroId,
			SkinID = CurSelectSkinId,
			Location = TeamTransform.Location,
			Rotation = TeamTransform.Rotation,
			SetRenderOnTop = true
		}
		HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
	end
end	

-- 流关卡预加载
function PreLoadCtrl:DoPreLoadStreamLevels()
	---@type HallSceneMgr
    local HallSceneMgr = _G.HallSceneMgrInst
    if HallSceneMgr == nil then
        return false
    end
	local Cfgs = G_ConfigHelper:GetDict(Cfg_HallStreamLevelConfig)
	if not Cfgs then
		return false
	end
	self.PreLoadModel:SetPreloadStep(PreLoadModel.PRELOADING_STEP.LEVEL_STREAM)
	self.NeedLoadStreamLevelMap = {}
	local NeedLoadNum = 0
	for _,Cfg in ipairs(Cfgs) do
		local StreamLevelID = Cfg[Cfg_HallStreamLevelConfig_P.StreamLevelID]
		local StreamLevelName = Cfg[Cfg_HallStreamLevelConfig_P.StreamLevelName]
		if not self.NeedLoadStreamLevelMap[StreamLevelID] then
			if HallSceneMgr:PreloadSteamLevel(StreamLevelID,StreamLevelName,HallModel.LevelType.STREAM_LEVEL) then
				--需要等待加载的流关卡列表
				self.NeedLoadStreamLevelMap[StreamLevelID] = 1
				NeedLoadNum = NeedLoadNum + 1
			else
				self.NeedLoadStreamLevelMap[StreamLevelID] = 0
			end
		else
			CWaring("PreLoadCtrl:DoPreLoadStreamLevels StreamLevelID repeat")
		end
	end

	local CfgsLight = G_ConfigHelper:GetDict(Cfg_HallLightConfig)
	for _,Cfg in ipairs(CfgsLight) do
		local LightID = Cfg[Cfg_HallLightConfig_P.LightID]
		local LightLevelName = Cfg[Cfg_HallLightConfig_P.LightLevelName]
		if not self.NeedLoadStreamLevelMap[LightID] then
			if HallSceneMgr:PreloadSteamLevel(LightID,LightLevelName,HallModel.LevelType.LIGHT_LEVEL) then
				--需要等待加载的流关卡列表
				self.NeedLoadStreamLevelMap[LightID] = 1
				NeedLoadNum = NeedLoadNum + 1
			else
				self.NeedLoadStreamLevelMap[LightID] = 0
			end
		else
			CWaring("PreLoadCtrl:DoPreLoadStreamLevels StreamLevelID repeat")
		end
	end

	CWaring("PreLoadCtrl:DoPreLoadStreamLevels NeedLoadStreamLevelMap Length:" .. NeedLoadNum)
	if NeedLoadNum <= 0 then
		--不存在需要等待加载的流关卡，直接调用完成回调
		self:OnPreloadStreamLevelSuc(HallSceneMgr)
	else
		HallSceneMgr:SetIsPreloading(true)
	end
	return true
end

-- 流关卡预加载完成
function PreLoadCtrl:ON_STREAM_LEVEL_PRELOAD_COMPLELTED(StreamLevelID)
	local HallSceneMgr = _G.HallSceneMgrInst
    if HallSceneMgr == nil then
		CError("PreLoadCtrl:ON_STREAM_LEVEL_PRELOAD_COMPLELTED HallSceneMgr nil!",true)
        return false
    end
	-- self:DoPreloadFinish()
	if not self.NeedLoadStreamLevelMap[StreamLevelID] then
		CError("PreLoadCtrl:ON_STREAM_LEVEL_PRELOAD_COMPLELTED StreamLevelID Invalid!",true)
		return
	end
	self.NeedLoadStreamLevelMap[StreamLevelID] = 0

	local NeedLoadNum = 0
	for k,v in pairs(self.NeedLoadStreamLevelMap) do
		if v and v > 0 then
			NeedLoadNum = NeedLoadNum + 1
		end
	end
	CWaring("PreLoadCtrl:ON_STREAM_LEVEL_PRELOAD_COMPLELTED NeedLoadNum:" .. NeedLoadNum)
	if NeedLoadNum <= 0 then
		self:OnPreloadStreamLevelSuc(HallSceneMgr)
	end
end

--[[
	预加载流关卡，全部成功回调
]]
function PreLoadCtrl:OnPreloadStreamLevelSuc(TheHallSceneMgr)
	if self.PreLoadModel:IsQuitPreload() then
		CWaring("OnPreloadStreamLevelSuc After Quit.")
		-- 提前结束了
		return
	end
	TheHallSceneMgr:SetIsPreloading(false)
	self.PreLoadModel:SetPreloadStep(PreLoadModel.PRELOADING_STEP.FINISH)
	self:DoPreloadFinish()
end

function PreLoadCtrl:DoPreloadFinish()
	if self.PreLoadModel:IsQuitPreload() then
		CWaring("DoPreloadFinish After Quit.")
		-- 提前结束了
		return
	end
	if self.FinishCallBack then
		self.FinishCallBack()
		self.FinishCallBack = nil
	end
end

function PreLoadCtrl:UnLoadOutSideAction()
	--需要主动UnRef已加载的资产
	local PathList = {}
	for k,v in pairs(self.NeedUnRefPathMap) do
		PathList[#PathList + 1] = k
	end
	self:GetSingleton(AsyncLoadAssetCtrl):UnLoadList(PathList)
end

function PreLoadCtrl:StopPreloadOutSideAction()
	self.PreLoadModel:SetPreloadStep(PreLoadModel.PRELOADING_STEP.QUIT)
	self.FinishCallBack = nil
	local TheHallSceneMgr = _G.HallSceneMgrInst
    if TheHallSceneMgr then
		TheHallSceneMgr:SetIsPreloading(false)
    end
end