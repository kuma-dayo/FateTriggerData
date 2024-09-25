--[[
    虚拟大厅界面
]]
local class_name = "VirtualHallMdt"
---@class VirtualHallMdt : GameMediator
VirtualHallMdt = VirtualHallMdt or BaseClass(GameMediator, class_name)

function VirtualHallMdt:__init()
	UIDebug.Show()
end

function VirtualHallMdt:OnShow(Param)
	UIDebug.Show()

	--是否从战斗返回
	local IsFromBattle = false
	local LastLevel = MvcEntry:GetModel(ViewModel).last_LEVEL_Fix
	if LastLevel == ViewConst.LevelBattle then
		IsFromBattle = true
	end
	local PlayInGameAnim_Func = function()
		self:PlayInGameAnim(Param,IsFromBattle)
		SoundMgr:PlaySound(SoundCfg.Music.MUSIC_PLAY)
		SoundMgr:PlaySound(SoundCfg.Music.MUSIC_HALL)
	end

	local bJumpCGByCMD = false
	local TheUserModel = MvcEntry:GetModel(UserModel)
	if TheUserModel.IsLoginByCMD then
		--自动化流程下，跳过逻辑
		bJumpCGByCMD = true
	end

	if bJumpCGByCMD then
		--自动化流程下，跳过CG逻辑
		PlayInGameAnim_Func()
	else
		if IsFromBattle then
			PlayInGameAnim_Func()
		else
			local ModuleId = 0
			if ECGSettingConfig and ECGSettingConfig.EnterHall then
				ModuleId = ECGSettingConfig.EnterHall.ModuleId
			end 
			---@type CGPlayParam
			local CGParams = {
				ModuleId = ModuleId,
				OnCGFinished = function(_, InParam)
					CLog(string.format("VirtualHallMdt:OnShow, PlayCG Finish !!! EndMode = %s !!", tostring(InParam.EndMode)))
					PlayInGameAnim_Func()
				end
			}
			--播放CG
			MvcEntry:GetCtrl(EndinCGCtrl):TryPlayCG(CGParams)
		end
	end
end

function VirtualHallMdt:PlayInGameAnim(Param,IsFromBattle)
	local LastLevel = MvcEntry:GetModel(ViewModel).last_LEVEL_Fix
	CWaring("VirtualHallMdt LastLevel:" .. LastLevel)
	MvcEntry:GetModel(HeroModel):ResetHeroDataRecord()
	MvcEntry:GetModel(HallModel):SetCurVirtualSceneType(HallModel.HallVirtualType.PreEntering)
	if IsFromBattle then
		local EnterFunc = function()
			CWaring("VirtualHallMdt:EnterFunc")
			--TODO 手动停止Loading界面
			UE.UAsyncLoadingScreenLibrary.StopLoadingScreen();
			--从战斗返回，需要播放一下摄相机的LS进行校证位置
			local function _EnterHallDelay()
				CWaring("VirtualHallMdt:_EnterHallDelay")
				local HallCameraMgr = CommonUtil.GetHallCameraMgr()
				if HallCameraMgr ~= nil then
					HallCameraMgr:ResetCameraByLS()
				end

				--局内返回
				local HallParam = {
					IsInGameFinished = true
				}
				MvcEntry:OpenView(ViewConst.Hall, HallParam)

				self:EnterHallFunc()
				CWaring("VirtualHallMdt EnterHallFunc2")

				if Param and Param.ExitBattleReason then
					if Param.ExitBattleReason == ConstUtil.ExitBattleReson.TravelFailure or Param.ExitBattleReason == ConstUtil.ExitBattleReson.NetSocketError then
						--TODO 需要弹窗进行提示
						CWaring("VirtualHallMdt:PlayInGameAnim ExitBattleReason:" .. Param.ExitBattleReason)
						local DescribeStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Match', "EnterDSBattleFailed")
						MvcEntry:GetCtrl(CommonCtrl):TryFaceActionOrInCache(function ()
							UIMessageBox.Show({
								describe = DescribeStr,
							})    
						end)
					end
				end
			end
			--检查是否有结算缓存，如果有缓存，则需要展示大厅结算界面
			--这里依赖 HallSceneMgrInst，所以需要先包裹一层，确保 HallSceneMgrInst 创建成功后再执行
			MvcEntry:GetModel(HallModel):DoHallSceneMgrAction(function()
				CWaring("VirtualHallMdt:EnterFunc1")
				--TODO 从战斗返回，需要检查一下网络连接，如果不好会尝试重连
				MvcEntry:GetCtrl(UserSocketLoginCtrl):SetTriedCount(0);
				MvcEntry:GetCtrl(UserSocketLoginCtrl):CheckAndTriggerSocketReconnect(0)
				
				-- 只要是正常退出就打开结算面板
				if Param.ExitBattleReason == ConstUtil.ExitBattleReson.Normal then
					---@type HallSettlementCtrl
					local HallSettlementCtrl = MvcEntry:GetCtrl(HallSettlementCtrl)
					HallSettlementCtrl:TryingToShowHallSettlement(_EnterHallDelay)			
				else
					if _EnterHallDelay then
						_EnterHallDelay()
					end
				end				
			end)
		end

		--[[
			预加载好局外所需的资源，再关闭Loading
		]]
		CWaring("VirtualHallMdt:PreLoadOutSideAction")
		MvcEntry:GetCtrl(PreLoadCtrl):PreLoadOutSideAction(function ()
			EnterFunc()
		end)
	else
		--从登录进入，需要播放入场LS
		MvcEntry:GetModel(HallModel):DoHallSceneMgrAction(function ()
			MvcEntry:GetModel(CommonModel):AddListener(CommonModel.ON_HALL_TAB_SWITCH_COMPLETED,self.OnHallSceneLoadFinsh,self)
			--因为大厅角色的创建也依赖HallSceneMgr,所以将Open Hall操作放在这里
			local HallParam = {
				NeedWaitEnterLS = true
			}
			MvcEntry:OpenView(ViewConst.Hall,HallParam)
		end)
	end
end

function VirtualHallMdt:EnterHallFunc()
	MvcEntry:GetModel(HallModel):DispatchType(HallModel.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE,true)
	MvcEntry:GetModel(HallModel):SetIsHallReady(true)
	-- print("VirtualHallMdt EnterHallFunc")

	--尝试触发未成年防沉迷禁玩
	MvcEntry:GetModel(UserModel):CheckAntiAddictionMessageBox(false)

	MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(HallLSCfg.LS_SCREEN_ANIM_LOOP.LSTypeIdEnum, nil, {LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallLSCfg.LS_SCREEN_ANIM_LOOP.HallLSId)})
end

function VirtualHallMdt:OnHallSceneLoadFinsh()
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	local TheFHeroId = MvcEntry:GetModel(HeroModel):GetFavoriteId()
	local TheFSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteHeroFavoriteSkinId()
	local HallActor = HallAvatarMgr:GetHallAvatar(MvcEntry:GetModel(UserModel).PlayerId, ViewConst.Hall, TheFHeroId)
	local HallActorAvatar = HallActor and HallActor:GetSkinActor() or nil
	if not HallActorAvatar then
		CWaring("VirtualHallMdt HallActorAvatar nil",true)
		return
	end
	local SetBindings = {
		{
			ActorTag = "", --如场景中静态放置的可用tag搜索出Actor
			Actor = HallActorAvatar, --需要在播动画前生成Actor(且直接具有SkeletaMesh组件)
			TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_ANIM,
		},
		{
			ActorTag = "",
			Actor = HallActorAvatar, 
			TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_COMPONENT,
		}
	}
	local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor ~= nil then
		local CameraBinding = {
			ActorTag = "",
			Actor = CameraActor, 
			TargetTag = SequenceModel.BindTagEnum.CAMERA,
		}
		table.insert(SetBindings,CameraBinding)
	end

	--[[
		将LS_ENTER_HALL播放前置，并手动StopAllSequences

		之前是后置的，LS_ENTER_HALL好像会影响进场的LS特效播放（原因未知）
	]]
	MvcEntry:GetCtrl(SequenceCtrl):StopAllSequences()
	local PlayParam2 = {
		LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_ENTER_HALL),
	}
	MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(tostring(ViewConst.VirtualHall) .. "Scene", nil, PlayParam2)

	local LevelSequenceAsset, IsEnablePostProcess = MvcEntry:GetModel(HeroModel):GetSkinLSPathBySkinIdAndKey(TheFSkinId,HeroModel.LSEventTypeEnum.LSPathEnterHall)
	local PlayParam = {
		LevelSequenceAsset = LevelSequenceAsset,
		SetBindings = SetBindings,
		SaveCameraConfig = true,
		TransformOrigin = HallActor:GetTransform(),
		TimeOut = 15,
		ForceCallback = true,
		FocusMethodSetting = {
			FocusMethod = UE.ECameraFocusMethod.Manual,
			ManualFocusDistance = 100000,
		},
		IsEnablePostProcess = IsEnablePostProcess,
		-- WaitUtilActorHasBeenPrepared = true
	}
	MvcEntry:GetModel(HallModel):SetCurVirtualSceneType(HallModel.HallVirtualType.Entering)
	MvcEntry:GetModel(HallModel):DispatchType(HallModel.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE,false)
	MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(tostring(ViewConst.VirtualHall), function (IsForceStop)
		if not MvcEntry:GetModel(ViewModel):GetState(ViewConst.VirtualHall) then
			CWaring("PlaySequenceByTag : ".. tostring(ViewConst.VirtualHall).." Finish But VirtualHall Is Invalid")
			return
		end
		CommonUtil.SetMainCameraInViewTarget(0)
		MvcEntry:GetModel(HallModel):SetCurVirtualSceneType(HallModel.HallVirtualType.Hall)
		self:EnterHallFunc()
		-- UE.UGFUnluaHelper.UnlockFrameRate()
		HallActor:SetRenderOnTop(TheFSkinId, false)
	end, PlayParam)

	--大厅进入时播放角色语音
	---@type HeroModel
	local HeroModel = MvcEntry:GetModel(HeroModel)
	local CurrentPlayerHeroSkinId = HeroModel:GetFavoriteHeroFavoriteSkinId()
	SoundMgr:PlayHeroVoice(CurrentPlayerHeroSkinId, SoundCfg.Voice.HALL_ENTER)

	MvcEntry:GetModel(CommonModel):RemoveListener(CommonModel.ON_HALL_TAB_SWITCH_COMPLETED,self.OnHallSceneLoadFinsh,self)
end

function VirtualHallMdt:OnHide()
	CWaring("VirtualHallMdt OnHide")

	SoundMgr:PlaySound(SoundCfg.Music.MUSIC_STOP)
end