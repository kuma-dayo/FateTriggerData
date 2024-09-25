--[[
    大厅 - 切页 - 开始游戏
]]
local class_name = "HallTabPlay"
local HallTabPlay = BaseClass(UIHandlerViewBase, class_name)
local HallEntryListHandle = require("Client.Modules.Hall.HallEntryListHandle")

--打开其他界面, 停止本页面动画以及音频时, 需要排除的页面
HallTabPlay.OpenOtherViewExcludeViewId = {
	[ViewConst.Chat] = true,
	[ViewConst.FriendMain] = true,
	[ViewConst.MailMain] = true,
	[ViewConst.SystemMenu] = true,
	[ViewConst.TeamAndChat] = true,
}

--空闲动画检查过滤的界面ID
HallTabPlay.IdleCheckExcludeViewId = {
	[ViewConst.TeamAndChat] = true,
}

function HallTabPlay:OnInit(Param)
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
	self.BindNodes = 
    {
		--{ UDelegate = self.View.BtnBackLogin.OnClicked,				Func = Bind(self,self.OnClicked_BtnBackLogin) },
	}

    self.MsgList = {
        {Model = TeamModel, MsgName = TeamModel.ON_TEAM_INITED,							Func = Bind(self,self.OnTeamInfoInited) },
		{Model = TeamModel, MsgName = TeamModel.ON_SELF_JOIN_TEAM,						Func = Bind(self,self.OnSelfJoinTeam) },
		{Model = TeamModel, MsgName = TeamModel.ON_SELF_SINGLE_IN_TEAM,						Func = Bind(self,self.OnSelfSingleInTeam) },
		{Model = TeamModel, MsgName = TeamModel.ON_ADD_TEAM_MEMBER,						Func = Bind(self,self.OnAddTeamMember) },
		{Model = TeamModel, MsgName = TeamModel.ON_DEL_TEAM_MEMBER,						Func = Bind(self,self.OnDelTeamMember) },
		-- {Model = TeamModel, MsgName = TeamModel.ON_UPDATE_TEAM_MEMBER,					Func = self.OnUpdateTeamMember },
		{Model = TeamModel, MsgName = TeamModel.ON_TEAM_MEMBER_HERO_INFO_CHANGED,	Func = Bind(self,self.OnTeamMemberHeroInfoChanged) },
		{Model = TeamModel, MsgName = TeamModel.ON_TEAM_MEMBER_WEAPON_INFO_CHANGED,	Func = Bind(self,self.OnTeamMemberWeaponInfoChanged) },

		-- 好友模块

		{Model = HallModel, 	MsgName = HallModel.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE,	Func = Bind(self,self.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE) },
		{Model = HallModel, 	MsgName = HallModel.ON_HALL_LS_CHANGE_TEST,	Func = Bind(self,self.OnPlayIdleLS) },

		{Model = ViewModel,			MsgName = ViewModel.ON_SATE_DEACTIVE_CHANGED,			Func = Bind(self,self.OnOtherViewClosed) },
		{Model = ViewModel,			MsgName = ViewModel.ON_SATE_ACTIVE_CHANGED,			Func = Bind(self,self.OnOtherViewShowed )},
		{Model = HeroModel,  MsgName = HeroModel.ON_PLAYER_LIKE_HERO_CHANGE,         Func = Bind(self, self.OnHeroShowChange) },
		{Model = HeroModel,  MsgName = HeroModel.ON_HERO_LIKE_SKIN_CHANGE,         Func = Bind(self, self.OnHeroShowChange) },

		{Model = WeaponModel,  MsgName = WeaponModel.ON_SELECT_WEAPON,         Func = Bind(self, self.OnWeaponShowChange) },
		{Model = WeaponModel,  MsgName = WeaponModel.ON_SELECT_WEAPON_SKIN,         Func = Bind(self, self.OnWeaponShowChange) },
		
		{Model = MatchModel,  MsgName = MatchModel.ON_MATCH_IDLE,         			Func = Bind(self,self.ON_MATCH_IDLE_Func)},
		{Model = MatchModel,  MsgName = MatchModel.ON_MATCHING,         			Func = Bind(self,self.ON_GAMEMATCHING_Func)},
		{Model = MatchModel,  MsgName = MatchModel.ON_MATCH_CANCELED,         		Func = Bind(self,self.ON_GAMESTART_MATHCANCEL_Func)},	--主动取消
		{Model = MatchModel,  MsgName = MatchModel.ON_MATCH_FAIL,         			Func = Bind(self,self.ON_GAMESTART_MATHCANCEL_Func)},	--被动取消
		{Model = MatchModel,  MsgName = MatchModel.ON_DS_ERROR,         			Func = Bind(self,self.ON_DS_ERROR_Func)},
		{Model = MatchModel,  MsgName = MatchModel.ON_MATCH_SUCCESS,         		Func = Bind(self,self.ON_GAMEMATCH_SUCCECS_Func)},
		{Model = MatchModel,  MsgName = MatchModel.ON_GAMEMATCH_DSMETA_SYNC,        Func = Bind(self,self.ON_GAMEMATCH_DSMETA_SYNC_Func)},
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnClicked_ESC },
    }

    -- self.MvvmBindList = {
	-- 	{ Model = UserModel, BindSource = self.View.LbName, PropertyName = "PlayerName", MvvmBindType = MvvmBindTypeEnum.SETTEXT }
	-- }


    --[[
		进场LS是否播完完成
		播放完成
		如果玩家处于队伍中
		需要生成队伍成员
		需要生成武器

		才可以播放队伍进场LS
	]]
	self.LSHallEnterFinished = true

	--[[
		需要等待组队LS延时一段时间之后，才能创建队员展示
	]]
	self.WaitLSEnterTeamDealyTimer = nil

	--[[
		当前已经创建avatar的队友
		{
			Pos = 1
		}
	]]
	self.MemberAvatarIds = {}
	--[[
		当前正在播放消融特效的信息
		{
			--队员ID
			MemberId = 0,
			--位置信息
			Pos = 0,
			--回调
			CallBack = nil
		}
	]]
	self.MemberId2PlayingDissolveInfo = {}
	--同上，只是Key不一样
	self.Pos2PlayingDissolveInfo = {}

	self.LSEventTagName = "HeroModel.LSEventTypeEnum"

	-- 此页签内子类的列表，用于Show/Hide时，注册和销毁监听的事件
    -- self.SubClassList = {}

	--MVP 自建房临时入口，后续删除 2023/05/29
	--self.HallCustomRoomEntrance = UIHandler.New(self, self.View.WBP_HallCustomerRoomEntrance, require("Client.Modules.CustomRoom.CustomRoom_EntryMdt")).ViewInstance

	UIHandler.New(self, self.View.Panel_ActivityEntrance, HallEntryListHandle)

	if Param and Param.InData and Param.InData.NeedWaitEnterLS then
		self.LSHallEnterFinished = false
	end
end

function HallTabPlay:OnPlayIdleLS(_,Param)
	if Param.IsClick then
		self:PlayClickLS(Param.ID)
	else
		self:_IdleFunc(Param.ID)
	end
end

function HallTabPlay:GetViewKey()
    return ViewConst.Hall*100 + CommonConst.HL_PLAY
end
--[[
    Param = {
        InData
        {
            NeedWaitEnterLS
        }
    }
]]
function HallTabPlay:OnShow(Param)
	-- self.View:PlayAnimation(self.View.vx_hall_in_common)

	self:InitMatchEntrance()
	self:InitQuestionnaireEntrance()
    self:UpdateUI(Param)
end

function HallTabPlay:OnManualShow()
	self:AddOrRemoveIdleTimer(true)
	SoundMgr:PlaySound(SoundCfg.Music.MUSIC_HALL)
end
function HallTabPlay:OnManualHide()
	self:AddOrRemoveIdleTimer(false)
	self:AddOrRemoveLSEnterTeamDealyTimer(false)
end

function HallTabPlay:OnHide()
	self:AddOrRemoveIdleTimer(false)
	self:AddOrRemoveLSEnterTeamDealyTimer(false)
end

-- -- 由 CommonHallTab 控制调用，显示当前页签时调用，重新注册监听事件
-- function HallTabPlay:OnCustomShow()
-- 	if self.IsHide then 
--         if self.MsgList then
--             CommonUtil.MvcMsgRegisterOrUnRegister(self,self.MsgList,true)
--         end
--         if self.SubClassList then
--             for _,Btn in ipairs(self.SubClassList) do
--                 CommonUtil.MvcMsgRegisterOrUnRegister(Btn,Btn.MsgList,true)
--             end
--         end
-- 		self:AddOrRemoveIdleTimer(true)
--         self.IsHide = false
--     end
-- 	SoundMgr:PlaySound(SoundCfg.Music.MUSIC_HALL)
-- end

-- 由 CommonHallTab 控制调用，隐藏当前页签时调用，销毁监听事件
-- function HallTabPlay:OnCustomHide()
-- 	CommonUtil.MvcMsgRegisterOrUnRegister(self,self.MsgList,false)
-- 	if self.SubClassList then
--         for _,Btn in ipairs(self.SubClassList) do
-- 		    CommonUtil.MvcMsgRegisterOrUnRegister(Btn,Btn.MsgList,false)
--         end
--     end
-- 	self:AddOrRemoveIdleTimer(false)
-- 	self:AddOrRemoveLSEnterTeamDealyTimer(false)
--     self.IsHide = true
-- end

---初始化匹配入口显示，重新创建一个挂载
function HallTabPlay:InitMatchEntrance()
	if not self.HallMatchEntrance then
		local WidgetClass = UE4.UClass.Load("/Game/BluePrints/UMG/OutsideGame/Match/WBP_MatchEntrance.WBP_MatchEntrance")
		local Widget = NewObject(WidgetClass, self.View)
		UIRoot.AddChildToPanel(Widget, self.View.GUICanvasPanel_MatchEntrance)
		
		if Widget and CommonUtil.IsValid(Widget) then
			---@type HallMatchEntranceLogic
			self.HallMatchEntrance = UIHandler.New(self, Widget, require("Client.Modules.Match.MatchEntrance.HallMatchEntranceLogic")).ViewInstance
			-- self.SubClassList[#self.SubClassList + 1] = self.HallMatchEntrance
		end
	end
	self.HallMatchEntrance:InitEntranceAnim()
	self.HallMatchEntrance:UpdateLeftPartDisplay()
end

function HallTabPlay:UpdateUI(Param)
    -- if Param and Param.InData and Param.InData.NeedWaitEnterLS then
	-- 	self.LSHallEnterFinished = false
	-- end

    --检查本地P4版本是否跟Gate一致
	MvcEntry:GetModel(UserModel):ComparePVersion()
	local PVersionShow = MvcEntry:GetModel(UserModel):GetPVersionShow()
	if PVersionShow and string.len(PVersionShow) > 0 then
		self.View.LbNetVersion:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		self.View.LbNetVersion:SetText(PVersionShow .. "")
	else
		self.View.LbNetVersion:SetVisibility(UE.ESlateVisibility.Collapsed)
	end
	if CommonUtil.IsShipping() then
		self.View.LbNetVersion:SetVisibility(UE.ESlateVisibility.Collapsed)
	end

	if self.HallMatchEntrance then
		self.HallMatchEntrance:UpdateView()		
	end
	if self.QuestionnaireHallEntrance then
		self.QuestionnaireHallEntrance:UpdateUI()
	end
	
	--if self.HallCustomRoomEntrance then
	--	self.HallCustomRoomEntrance:UpdateView()		
	--end	
end

function HallTabPlay:UIAllHide()
	self.View.PanelContent:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function HallTabPlay:OnInGameFinished()
	self.View.PanelContent:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function HallTabPlay:TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE(_,Value)
	self.View.PanelContent:SetVisibility(Value and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
	if not Value then
		return
	end

	self.LSHallEnterFinished = true

	if MvcEntry:GetModel(TeamModel):IsSelfInTeam() then
		self:CheckEnterTeamLs()
		self:SpawnTeamMemberAvatars(true)
		self:AddOrRemoveIdleTimer(true)
	else
		if MvcEntry:GetModel(MatchModel):IsMatching() then
			self:ON_GAMEMATCHING_Func()
		end
		self:AddOrRemoveIdleTimer(true)
	end
end

---------------------------- 组队状态变化 start -----------------------------------
	
-- 首次登录时，收到队伍信息
function HallTabPlay:OnTeamInfoInited()
	CWaring("HallMdt_OnTeamInfoInited=========================")
	if MvcEntry:GetModel(TeamModel):IsSelfInTeam() then
		-- 检测是否播放进队LS
		self:CheckEnterTeamLs()
	end
end

-- 自己进队
function HallTabPlay:OnSelfJoinTeam()
	CWaring("HallMdt_OnSelfJoinTeam=========================")
	MvcEntry:GetModel(HallModel):SetCurVirtualSceneType(HallModel.HallVirtualType.Match)
	-- 检测是否播放进队LS
	self:CheckEnterTeamLs()
end

-- 自己退队（变回单人）
function HallTabPlay:OnSelfSingleInTeam()
	CWaring("HallMdt_OnSelfSingleInTeam=========================")
	if self.IsTriggerHideAvatar then
		return
	end
	MvcEntry:GetModel(HallModel):SetCurVirtualSceneType(HallModel.HallVirtualType.Hall)
	-- 播放出队LS
	self:PlayExistTeamLs()
end

---队伍成员变化
function HallTabPlay:OnAddTeamMember(_,MemberChgList)
	if not self.LSHallEnterFinished then
		return
	end
	if MemberChgList == nil then 
		return 
	end
	CWaring("HallTabPlay:OnAddTeamMember")
	local TheTeamModel = MvcEntry:GetModel(TeamModel)
	local PlayVoiceSkinId = 0
	local MyPlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()

	for Index, Info in ipairs(MemberChgList) do
		local Actor = self:SpawnSingleTeamMemberAvatar(Info.k, Info.v, true)
		local Pos = TheTeamModel:GetMemberHallPos(Info.k)
		if Info.k ~= MyPlayerId then
			if PlayVoiceSkinId == 0 then
				PlayVoiceSkinId = Info.v.HeroSkinId or 0
			else
				-- 一个人进队的时候才播。有多个人代表是自己进别人队。重置回0不播语音
				PlayVoiceSkinId = 0
			end
		end
	end
	if PlayVoiceSkinId ~= 0 and TheTeamModel:IsTeamInfoInited() then
		-- 别人进队。（我进入别人多人队伍时，不对自己播进队语音）
		SoundMgr:PlayHeroVoice(PlayVoiceSkinId, SoundCfg.Voice.TEAM_JOIN)
	end
end 

-- 队员离队
function HallTabPlay:OnDelTeamMember(_,MemberChgList)
	if MemberChgList == nil then 
		return 
	end
	CWaring("HallTabPlay:OnDelTeamMember")
	for _, v in pairs(MemberChgList) do
		self:RemoveSingleTeamMemAvatar(v.k,true)
	end
end


---------------------------- 组队状态变化   end -----------------------------------

---------------------------- 匹配相关     start -----------------------------------
--[[
	开始匹配/正在匹配
]]
function HallTabPlay:ON_GAMEMATCHING_Func()
	if not self.LSHallEnterFinished then
		return
	end

	MvcEntry:GetModel(HallModel):SetCurVirtualSceneType(HallModel.HallVirtualType.Match)
	-- 触发新手引导关闭
	MvcEntry:GetModel(GuideModel):DispatchType(GuideModel.GUIDE_CLOSE_POPUP)

	local LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_SOLO_MATCH_BEGIN)
	local StartTime, EndTime = MvcEntry:GetModel(SequenceModel):GetLevelSequenceEndSeconds(LevelSequenceAsset)
	local TheUserModel =  MvcEntry:GetModel(UserModel)
	local TheTeamModel = MvcEntry:GetModel(TeamModel)
	local MyPlayerId = TheUserModel:GetPlayerId()
	local IsInTeam = TheTeamModel:IsInTeam(MyPlayerId)
	if not IsInTeam then
		--[[
			TODO 如果是单人，需要播放LS
			需要展示武器
		]]
		self:ForceStopPlayingDissolveLS()
		self:HandleHeashow(self.SelfId, true, true)
		self:CheckSelfAvatarWeapon(true)
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
			LevelSequenceAsset = LevelSequenceAsset,
			SetBindings = SetBindings,
			TransformOrigin = UE.FTransform.Identity,
			NeedStopAllSequence = true,
		}
		MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("LS_SOLO_MATCH_BEGIN", function ()
			CWaring("LobbyMatchInfo:PlaySequenceByTag Suc")
		end, PlayParam)

		self:ManaulTraceMesh(false)
		
		SoundMgr:StopPlayAllEffect()
		SoundMgr:StopPlayAllVoice()
		
		self:InsertTimer(MvcEntry:GetCtrl(SequenceCtrl):GetDuration("LS_SOLO_MATCH_BEGIN") - 1,function ()
		end)
		-- self:PlayBlackWhiteSoloSquardLS(nil,true)
	else
		-- 队伍时，队长要播放语音
		local LeaderId = TheTeamModel:GetLeaderId()
		local LeaderInfo = TheTeamModel:GetData(LeaderId)
		if LeaderInfo then
			SoundMgr:PlayHeroVoice(LeaderInfo.HeroSkinId, SoundCfg.Voice.MATCH_START)
		end
	end
	self:AddOrRemoveIdleTimer(false)
end

function HallTabPlay:ManaulTraceMesh(Open)
    local PlayerController = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    UE.UKismetSystemLibrary.ExecuteConsoleCommand(GameInstance, StringUtil.FormatSimple("r.Lumen.TraceMeshSDFs {0}", Open and "1" or "0"), PlayerController)
    UE.UKismetSystemLibrary.ExecuteConsoleCommand(GameInstance, StringUtil.FormatSimple("r.Lumen.TraceGlobalSDF {0}", Open and "1" or "0"), PlayerController)
end
--[[
	停止匹配
]]
function HallTabPlay:ON_GAMESTART_MATHCANCEL_Func()
	self.WaitEnterDS = false
	MvcEntry:GetModel(HallModel):SetIsLevelTravel(false)
	local LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_SOLO_MATCH_CANCEL)
	local StartTime, EndTime = MvcEntry:GetModel(SequenceModel):GetLevelSequenceEndSeconds(LevelSequenceAsset)
	local TheUserModel =  MvcEntry:GetModel(UserModel)
	local TheTeamModel = MvcEntry:GetModel(TeamModel)
	local MyPlayerId = TheUserModel:GetPlayerId()
	local IsInTeam = TheTeamModel:IsInTeam(MyPlayerId)
	if not IsInTeam then
		MvcEntry:GetModel(HallModel):SetCurVirtualSceneType(HallModel.HallVirtualType.Hall)
		--[[
			单人取消匹配：
			需要隐藏武器
			需要播回角色当前模块Idle动画
			需要播放对应LS
		]]
		self:ForceStopPlayingDissolveLS()

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
			LevelSequenceAsset = LevelSequenceAsset, 
			SetBindings = SetBindings,
			TransformOrigin = UE.FTransform.Identity,
			NeedStopAllSequence = true,
			ForceCallback = true,
		}
		self:HandleHeashow(self.SelfId, true, false)
		MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("Match", function ()
			CWaring("LobbyMatchInfo:PlaySequenceByTag Suc")
			self:CheckSelfAvatarWeapon()
			self:ManaulTraceMesh(true)
		end, PlayParam)

		self:AddOrRemoveIdleTimer(true)
	else
		MvcEntry:GetModel(HallModel):SetCurVirtualSceneType(HallModel.HallVirtualType.Match)
	end
end

---进入DS失败
function HallTabPlay:ON_DS_ERROR_Func()
	--多人模式复用取消匹配LS
	---@type TeamModel
	local TeamModel = MvcEntry:GetModel(TeamModel)
	if not TeamModel:IsSelfInTeam() then
		self:ON_GAMESTART_MATHCANCEL_Func()
		
	--组队模式复用进入队伍LS
	else
		self:HandleHeashow(self.SelfId, true)
		self:CheckSelfAvatarWeapon()
		self:PlayEnterTeamLs()
		self:PlayBlackWhiteSoloSquardLS(nil, true)
	end
	self:InitMatchEntrance()
end

--[[
	匹配成功
]]
function HallTabPlay:ON_GAMEMATCH_SUCCECS_Func()
	self.WaitEnterDS = true
	MvcEntry:GetModel(HallModel):SetIsLevelTravel(false)
	MvcEntry:OpenView(ViewConst.MatchSuccessPop)
	--TODO 匹配成功需要播放指定LS
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
        LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_MATCH_SUC),
        SetBindings = SetBindings,
        TransformOrigin = UE.FTransform.Identity,
        NeedStopAllSequence = true,
		TimeOut = 5,
		ForceCallback = true,
    }
	self.WaitMatchInLSFinish = true
	self.CacheDSMeta = nil
    MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("Match", function ()
        CWaring("ON_GAMEMATCH_SUCCECS_Func:PlaySequenceByTag Suc")
		self.WaitMatchInLSFinish = false
		self:CheckDSMetaTravel()
    end, PlayParam)

	--TODO 播放白点LS
	local TheUserModel =  MvcEntry:GetModel(UserModel)
	local TheTeamModel = MvcEntry:GetModel(TeamModel)
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	local MyPlayerId = TheUserModel:GetPlayerId()
	local IsInTeam = TheTeamModel:IsInTeam(MyPlayerId)
	local TeamMemberActorSkeletal = {}
	local TeamWeaponActorList = {}
	if IsInTeam then
		local TeamMembers = MvcEntry:GetModel(TeamModel):GetDataMap()
		for Index,Info in pairs(TeamMembers) do
			local HeroAvatar = HallAvatarMgr:GetHallAvatar(Info.PlayerId)
			if HeroAvatar then
				table.insert(TeamMemberActorSkeletal,HeroAvatar:GetSkinActor())

				local SlotAvatarInfo = HeroAvatar:GetSlotAvatarInfo(HallApparelMgr.HERO_SLOT_MAINWEAPON)
				local WeaponAvatar = SlotAvatarInfo and SlotAvatarInfo.AvatarActor
				if WeaponAvatar then
					table.insert(TeamWeaponActorList,WeaponAvatar)
				end
			end

			self:HandleHeashow(Info.PlayerId, true, false)
		end
	else
		local HeroAvatar = HallAvatarMgr:GetHallAvatar(self.SelfId)
		table.insert(TeamMemberActorSkeletal,HeroAvatar:GetSkinActor())

		local SlotAvatarInfo = HeroAvatar:GetSlotAvatarInfo(HallApparelMgr.HERO_SLOT_MAINWEAPON)
		local WeaponAvatar = SlotAvatarInfo and SlotAvatarInfo.AvatarActor
		if WeaponAvatar then
			table.insert(TeamWeaponActorList,WeaponAvatar)
		end

		self:HandleHeashow(self.SelfId, true, false)
	end
	self:PlayBlackWhiteMatchLS(TeamMemberActorSkeletal,TeamWeaponActorList)
end

function HallTabPlay:ON_GAMEMATCH_DSMETA_SYNC_Func(_,InData)
	self.CacheDSMeta = InData
	self:CheckDSMetaTravel()
end


--[[
	检查是否满足进战斗条件
	满足的话，播放进入LS然后进行Travel战斗
]]
function HallTabPlay:CheckDSMetaTravel()
	if not self.CacheDSMeta then
		CWaring("HallMdt:CheckDSMetaTravel CacheDSMeta nil")
		return
	end
	if self.WaitMatchInLSFinish then
		CWaring("HallMdt:CheckDSMetaTravel WaitMatchInLSFinish")
		return
	end

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
        LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_MATCH_DSMETA_SUC),
        SetBindings = SetBindings,
        TransformOrigin = UE.FTransform.Identity,
        NeedStopAllSequence = true,
		TimeOut = 3,
		ForceCallback = true,
    }
    MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("Match", function ()
        CWaring("CheckDSMetaTravel:PlaySequenceByTag Suc")
		if self.CacheDSMeta then
			---@type MatchCtrl
			local MatchCtrl = MvcEntry:GetCtrl(MatchCtrl)
			MatchCtrl:ReqConnectDServer(self.CacheDSMeta)
			self.CacheDSMeta = nil
			self.WaitMatchInLSFinish = nil
			self.WaitEnterDS = false

		else
			ReportError("CheckDSMetaTravel:PlaySequenceByTag Repeat! CacheDSMeta is nil",true)
		end
    end, PlayParam)
end

--[[
	进入等待匹配状态
	需要检查是否是从匹配成功，因为断线重连，导致回到此状态。如果是，需要将匹配成功的表现移除，恢复正常等待表现
]]
function HallTabPlay:ON_MATCH_IDLE_Func()
	MvcEntry:GetModel(HallModel):SetIsLevelTravel(false)
	if self.WaitEnterDS then
		self:ON_DS_ERROR_Func()
		self.CacheDSMeta = nil
		self.WaitMatchInLSFinish = nil
		self.WaitEnterDS = false
	end
end

---------------------------- 匹配相关       end -----------------------------------

---------------------------- Avatar 相关 start -----------------------------------

function HallTabPlay:OnShowAvator(Param,IsNotVirtualTrigger)
	CWaring("HallTabPlay OnShowAvator")
	self.IsTriggerHideAvatar = false
	if self.LSHallEnterFinished and (MvcEntry:GetModel(TeamModel):IsSelfInTeam() or MvcEntry:GetModel(MatchModel):IsMatching() or self.WaitEnterDS) then
		--TODO 需要播放LS进行相机校正
		local SetBindings = {}
		local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
		if CameraActor ~= nil then
			local CameraBinding = {
				Actor = CameraActor, 
				TargetTag = SequenceModel.BindTagEnum.CAMERA,
			}
			table.insert(SetBindings,CameraBinding)
		end
		local PlayParam = {
			LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_TEAMORMATCH_CAMERA), 
			SetBindings = SetBindings,
			TransformOrigin = UE.FTransform.Identity,
		}
		MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("LS_TEAMORMATCH_CAMERA", function ()
			CWaring("HeroMdt:PlaySequenceByTag LS_TEAMORMATCH_CAMERA Suc")
		end, PlayParam)

		if MvcEntry:GetModel(TeamModel):IsSelfInTeam() or MvcEntry:GetModel(MatchModel):IsMatching() then
			MvcEntry:GetModel(HallModel):SetCurVirtualSceneType(HallModel.HallVirtualType.Match)
		else
			MvcEntry:GetModel(HallModel):SetCurVirtualSceneType(HallModel.HallVirtualType.Hall)
		end
		CWaring("HallTabPlay OnShowAvator LS_TEAMORMATCH_CAMERA")
	-- elseif MvcEntry:GetModel(FavorabilityModel):GetIsCloseFromFavorMain() then
	-- 	-- 从好感度返回，需要播放LS进行相机
	-- 	local SetBindings = {}
	-- 	local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
	-- 	if CameraActor ~= nil then
	-- 		local CameraBinding = {
	-- 			Actor = CameraActor, 
	-- 			TargetTag = SequenceModel.BindTagEnum.CAMERA,
	-- 		}
	-- 		table.insert(SetBindings,CameraBinding)
	-- 	end
	-- 	local PlayParam = {
	-- 		LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_FAVORMAIN_TO_HALL_CAMERA), 
	-- 		SetBindings = SetBindings,
	-- 		TransformOrigin = UE.FTransform.Identity,
	-- 	}
	-- 	MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("LS_FAVORMAIN_TO_HALL_CAMERA", function ()
	-- 		CWaring("HeroMdt:PlaySequenceByTag Suc")
	-- 	end, PlayParam)
	end
	self:SpawnSelfAvatar(IsNotVirtualTrigger)
	--测试
	-- if MvcEntry:GetModel(TeamModel):IsSelfInTeam() then
	-- 	self:CheckEnterTeamLs()
	-- end
	--//
    self:SpawnTeamMemberAvatars(false)
end

function HallTabPlay:OnHideAvator(Param,IsNotVirtualTrigger)
	-- 由外部触发了场景切换隐藏Avatar，用此字段控制隐藏Avatar期间，LS不进行播放
	self.IsTriggerHideAvatar = true
    self:HideHallAvatars()
end

function HallTabPlay:HideHallAvatars()
	-- CWaring("HallTabPlay:HideHallAvatars")
	if not CommonUtil.IsValid(self.View) then
		return
	end
	self:RemoveSelfAvatar()
	self:RemoveTeamMemberAvatars()
end


---------------- 大厅中自己的角色 ----------------

function HallTabPlay:SpawnSelfAvatar(IsNotVirtualTrigger)
	self.SelfId = MvcEntry:GetModel(UserModel).PlayerId
	print("HallTabPlay:SpawnSelfAvatar", IsNotVirtualTrigger, self.SelfId)
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr ~= nil then
		local TeamTransform = MvcEntry:GetModel(TeamModel):GetTeamTransform(self.SelfId)
		local CurSelectHeroId = MvcEntry:GetModel(HeroModel):GetFavoriteId()
		local CurSelectSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(CurSelectHeroId)
		local SpawnHeroParam = {
			ViewID = self:GetViewKey(),
			InstID = self.SelfId,
			HeroId = CurSelectHeroId,
			SkinID = CurSelectSkinId,
			-- 自己默认站1号位
			Location = TeamTransform.Location,
			Rotation = TeamTransform.Rotation,
			-- LightingChannel = 1,
			-- SetRenderOnTop = true
		}
		local HeroAvatar = HallAvatarMgr:GetHallAvatar(self.SelfId)
		if not HeroAvatar then
			HeroAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
		end
		if  HeroAvatar ~= nil then
			HeroAvatar:OpenOrCloseCameraAction(false)
			HeroAvatar:OpenOrCloseAvatorRotate(false)
			--清除之前注册的点击回调，方便重新绑定
			if self.OnClickedHeroAvatarBind then
				HeroAvatar:RemoveCustomOnClickedFunc(self.OnClickedHeroAvatarBind)
				self.OnClickedHeroAvatarBind = nil
			end
			self.OnClickedHeroAvatarBind = Bind(self,self.OnClickedHeroAvatar)
			HeroAvatar:AddCustomOnClickedFunc(self.OnClickedHeroAvatarBind)
		end
		self:HandleHeashow(self.SelfId, IsNotVirtualTrigger)
		self:CheckSelfAvatarWeapon(nil, true)

		MvcEntry:GetModel(HallModel):DispatchType(HallModel.HALL_PLAY_SPAWN_SELF_AVATAR)
	end
end

function HallTabPlay:RemoveSelfAvatar()
	print("HallTabPlay:RemoveSelfAvatar", self.SelfId)
	if not self.SelfId or self.SelfId == 0 then
		return
	end
	--脱掉武器
	MvcEntry:GetModel(HallModel):DispatchType(
		HallModel.ON_HERO_TAKEOFF_WEAPON, {HeroInstID = self.SelfId})

	self:HandleHeashow(self.SelfId, false, false)

	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr ~= nil then
		local HeroAvatar = HallAvatarMgr:GetHallAvatar(self.SelfId)
		if HeroAvatar then
			if self.OnClickedHeroAvatarBind then
				HeroAvatar:RemoveCustomOnClickedFunc(self.OnClickedHeroAvatarBind)
				self.OnClickedHeroAvatarBind = nil
			end
		end
		HallAvatarMgr:RemoveAvatarByInstID(self.SelfId)	
	end
end

function HallTabPlay:OnClickedHeroAvatar()
	if not self:CheckCanPlayIdleOrTouch() then
		print("HallTabPlay:OnClickedHeroAvatar CheckCanPlayIdleOrTouch")
		return
	end
	if MvcEntry:GetModel(TeamModel):IsSelfInTeam()  then
		return
	end
	if MvcEntry:GetCtrl(SequenceCtrl):IsSequencePlaying(self.LSEventTagName) then
		print("HallTabPlay:OnClickedHeroAvatar IsSequencePlaying")
		return
	end
	if MvcEntry:GetModel(SoundModel):IsSoundEventInCD(SoundCfg.Voice.HALL_CLICK) then
		CWaring("HallTabPlay:OnClickedHeroAvatar Sound HALL_CLICK CD")
		return
	end
	if MvcEntry:GetModel(HallModel):IsLSEventInCD(HeroModel.LSEventTypeEnum.HallClick) then
		CWaring("HallTabPlay:OnClickedHeroAvatar LS HallClick CD")
		return
	end
	self:PlayClickLS()
end

-- 点击大厅中的角色
function HallTabPlay:PlayClickLS(ForceID)
	-- 单人状态下，点击播放语音
	---@type HeroModel
	local TheHeroModel = MvcEntry:GetModel(HeroModel)
	local CurrentPlayerHeroSkinId = TheHeroModel:GetFavoriteHeroFavoriteSkinId()
	local SoundItem = SoundMgr:PlayHeroVoice(CurrentPlayerHeroSkinId, SoundCfg.Voice.HALL_CLICK)

	print("HallTabPlay:OnClickedHeroAvatar")
	--TODO 播放互动LS
	self:ForceStopPlayingDissolveLS()
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	local HallActor = HallAvatarMgr:GetHallAvatar(MvcEntry:GetModel(UserModel).PlayerId, ViewConst.Hall, TheHeroModel:GetFavoriteId())
	if not HallActor then
		return
	end
	local SetBindings = {
		{
			Actor = HallActor:GetSkinActor(),
			TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_ANIM,
		}
	}
	local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor ~= nil then
		local CameraBinding = {
			Actor = CameraActor, 
			TargetTag = SequenceModel.BindTagEnum.CAMERA,
		}
		table.insert(SetBindings,CameraBinding)
	end

	local FilterId
	if MvcEntry:GetModel(HallModel):IsLastPlayLSOverTimes() then
		FilterId = MvcEntry:GetModel(HallModel).LastPlayIdleID
	end
	local EventLSCfg = TheHeroModel:GetHeroEventLSCfg(HeroModel.LSEventTypeEnum.HallClick,CurrentPlayerHeroSkinId, FilterId)
	if ForceID then
		local Temp = G_ConfigHelper:GetSingleItemById(Cfg_HeroEventLSCfg, ForceID)
		if Temp then
			EventLSCfg = Temp
		end
	end
	local PlayParam = {
		LevelSequenceAsset = EventLSCfg and EventLSCfg[Cfg_HeroEventLSCfg_P.LSPath] or nil, 
		SetBindings = SetBindings,
		TransformOrigin = UE.FTransform.Identity,
		-- NeedStopAllSequence = true,
		NeedAssign2Material = EventLSCfg and EventLSCfg[Cfg_HeroEventLSCfg_P.NeedAssign2Material] or false,
		IsEnablePostProcess = EventLSCfg and EventLSCfg[Cfg_HeroEventLSCfg_P.IsEnablePostProcess] or false,
	}
	MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(self.LSEventTagName, function ()
		CWaring("HeroMdt:PlaySequenceByTag OnClickedHeroAvatar Suc")
	end, PlayParam)

	
	if EventLSCfg then
		if EventLSCfg[Cfg_HeroEventLSCfg_P.EventCD] > 0 then
			print("HallTabPlay:OnClickedHeroAvatar EventCD", EventLSCfg[Cfg_HeroEventLSCfg_P.EventCD])
			MvcEntry:GetModel(HallModel):RefreshLSEventCD(HeroModel.LSEventTypeEnum.HallClick,EventLSCfg[Cfg_HeroEventLSCfg_P.EventCD])
		end
		MvcEntry:GetModel(HallModel):SetCurrentPlayLS(EventLSCfg[Cfg_HeroEventLSCfg_P.Id])
	end
	
	--TODO 重新Idle计时
	self:AddOrRemoveIdleTimer(true)

	self:OnClickedEventTrackingHeroInfo(TheHeroModel:GetFavoriteId())
end

function HallTabPlay:ShouldShowWeapon()
	if MvcEntry:GetModel(TeamModel):IsInTeam(self.SelfId) then
		return true
	end
	if MvcEntry:GetModel(MatchModel):IsMatching() then
		return true
	end
	if self.WaitEnterDS then
		return true
	end
	if MvcEntry:GetModel(HallModel):IsLevelTravel() then
		return true
	end
	return false
end

--[[
	检测自己的英雄模型是否佩戴武器 （ 组队时佩戴 ）
	ForceControl不为空时，为布尔值 ，根据布尔值才决定是否显示枪支
]]
function HallTabPlay:CheckSelfAvatarWeapon(ForceControl, AnimControl)
	print("HallTabPlay:CheckSelfAvatarWeapon", ForceControl, AnimControl)
	if not self.LSHallEnterFinished then
		return
	end
	local TheWeaponShow = false
	if ForceControl ~= nil then
		TheWeaponShow = ForceControl
	else
		TheWeaponShow = self:ShouldShowWeapon()
	end
	local WeaponSkinID = MvcEntry:GetModel(WeaponModel):GetWeaponShowSkinId()
	if TheWeaponShow then
		--穿戴武器
		MvcEntry:GetModel(HallModel):DispatchType(
			HallModel.ON_HERO_PUTON_WEAPON, 
			{HeroInstID = self.SelfId, WeaponSkinID = WeaponSkinID,AnimControl = AnimControl,})
	else
		--脱掉武器
		MvcEntry:GetModel(HallModel):DispatchType(
			HallModel.ON_HERO_TAKEOFF_WEAPON, {HeroInstID = self.SelfId,AnimControl = AnimControl,})
	end
end

function HallTabPlay:HandleHeashow(PlayerId, NeedPlayInAni, ForceControl)
	if not self.LSHallEnterFinished then
		return
	end
	local Show = false
	if ForceControl ~= nil then
		Show = ForceControl
	else
		if MvcEntry:GetModel(TeamModel):IsInTeam(PlayerId) or MvcEntry:GetModel(MatchModel):IsMatching() then
			Show = true
		end
	end
	MvcEntry:GetModel(HallModel):DispatchType(Show and HallModel.ON_HERO_ADD_HEADSHOW or HallModel.ON_HERO_REMOVE_HEADSHOW,{HeroInstID = PlayerId, NotNeedPlayInAni = not NeedPlayInAni})
end


function HallTabPlay:OnHeroShowChange()
	if MvcEntry:GetCtrl(ViewRegister):IsViewBeVirtualHiding(ViewConst.Hall) then
        CWaring("HallTabPlay:OnHeroShowChange IsViewBeVirtualHiding,So return")
        return
    end
	self:SpawnSelfAvatar()
end

--[[
	当前玩家自身展示的武器发生变化，
	需要切换展示
]]
function HallTabPlay:OnWeaponShowChange()
	self:CheckSelfAvatarWeapon()
end

---------------- 大厅中队伍中的其他角色 ----------------

function HallTabPlay:SpawnTeamMemberAvatars(NeedEffect)
	if not self.LSHallEnterFinished then
		CWaring("SpawnTeamMemberAvatars fail")
		return
	end
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr == nil then
		return 
	end
	local TheTeamModel = MvcEntry:GetModel(TeamModel)
	local TeamMembers = TheTeamModel:GetDataMap()
	if not TeamMembers then
		CWaring("[HallTabPlay]SpawnTeamMemberAvatars TeamMembers is nil")
		return
	end
	local List = TheTeamModel:GetSortedMembersList(TeamMembers)
	for Index,Info in ipairs(List) do
		local Actor = self:SpawnSingleTeamMemberAvatar(Info.PlayerId, TeamMembers[Info.PlayerId],NeedEffect)
	end
end

function HallTabPlay:RemoveTeamMemberAvatars()
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if HallAvatarMgr == nil then
		return
	end
	if not self.MemberAvatarIds then
		return
	end
	for PlayerId,_ in pairs(self.MemberAvatarIds) do
		self:RemoveSingleTeamMemAvatar(PlayerId)
	end
	self.MemberAvatarIds = {}
end

--[[
	创建队员Avatar显示
]]
function HallTabPlay:SpawnSingleTeamMemberAvatar(TeamMemPlayerId, MemberInfo,NeedEffect, Force)
	if MvcEntry:GetModel(UserModel):IsSelf(TeamMemPlayerId) then
		return
	end
	if not MemberInfo or not MemberInfo.HeroId or MemberInfo.HeroId == 0 then
		CError("SpawnSingleTeamMemberAvatar HeroId Error!!!!")
		print_trackback()
		return
	end
	if self.WaitLSEnterTeamDealyTimer then
		CWaring("HallTabPlay:SpawnSingleTeamMemberAvatar WaitLSEnterTeamDealyTimer not nil,So return")
		return
	end

	if not Force and self.MemberAvatarIds[TeamMemPlayerId] then
		return
	end

	local TheTeamModel = MvcEntry:GetModel(TeamModel)
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	local TeamTransform = TheTeamModel:GetTeamTransform(TeamMemPlayerId)
	local Pos = TheTeamModel:GetMemberHallPos(TeamMemPlayerId)
	local HeroAvatar = nil
	if HallAvatarMgr ~= nil then
		local WeaponMappingCfg = MvcEntry:GetModel(WeaponModel):GetWeaponAnimMappingCfg(MemberInfo.WeaponSkinId,MemberInfo.HeroSkinId)
		local DefaultIdelAnimClip = nil
		if WeaponMappingCfg then
			DefaultIdelAnimClip = WeaponMappingCfg[Cfg_WeaponAnimMappingCfg_P.AnimClipIdle]
		end
		local SpawnHeroParam = 
		{
			ViewID = ViewConst.Hall,
			InstID = TeamMemPlayerId,
			HeroId = MemberInfo.HeroId,
			SkinID = MemberInfo.HeroSkinId,
			Location = TeamTransform.Location,
			Rotation = TeamTransform.Rotation,
			-- LightingChannel = 1,
			CustomPartList = MemberInfo.HeroSkinPartList,
			-- SetRenderOnTop = true
			DefaultIdelAnimClip = DefaultIdelAnimClip
		}
		if not SpawnHeroParam.SkinID or SpawnHeroParam.SkinID == 0 then
			-- 设置默认皮肤Id
			SpawnHeroParam.SkinID = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(MemberInfo.HeroId)
		end
		HeroAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
		if  HeroAvatar ~= nil then
			HeroAvatar:OpenOrCloseCameraAction(false)
			HeroAvatar:OpenOrCloseAvatorRotate(false)
		end
	end

	-- 更换武器
	self:ChangeMemberWeapon(TeamMemPlayerId, MemberInfo.WeaponSkinId)
	
	-- 记录Id，用于登出时清除
	local AvatarIdInfo = {
		Pos = Pos,
	}
	self.MemberAvatarIds[TeamMemPlayerId] = AvatarIdInfo

	if NeedEffect then
			--播放进场溶解特效
			local DissolveInfo = {
				MemberId = TeamMemPlayerId,
				HeroActor = HeroAvatar,
				Pos = Pos,
			}
			self:PlayDissolveLS(DissolveInfo)
			
			--播放溶解声音
			SoundMgr:PlaySound(SoundCfg.SoundEffects.TEAM_PARTNER_ENTER)
	end

	self:HandleHeashow(TeamMemPlayerId, NeedEffect, true)

	return HeroAvatar
end

--[[
	移除队员avatar显示
]]
function HallTabPlay:RemoveSingleTeamMemAvatar(TeamMemPlayerId,NeedEffect)
	if MvcEntry:GetModel(UserModel):IsSelf(TeamMemPlayerId) then
		return
	end
	local AvatarIdInfo = self.MemberAvatarIds[TeamMemPlayerId]
	self.MemberAvatarIds[TeamMemPlayerId] = nil
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	if not HallAvatarMgr then
		return
	end
	
	self:HandleHeashow(TeamMemPlayerId, NeedEffect, false)

	local RemoveInnerFunc = function()
		--脱掉武器
		MvcEntry:GetModel(HallModel):DispatchType(
			HallModel.ON_HERO_TAKEOFF_WEAPON, {HeroInstID = TeamMemPlayerId})
		
		--需要在角色destroy之前再次删除一下头顶显示
		self:HandleHeashow(TeamMemPlayerId, false, false)

		HallAvatarMgr:RemoveAvatarByInstID(TeamMemPlayerId)	
	end
	if not NeedEffect or not AvatarIdInfo then
		RemoveInnerFunc()
	else
		local HeroAvatar = HallAvatarMgr:GetHallAvatar(TeamMemPlayerId)
		local DissolveInfo = {
			MemberId = TeamMemPlayerId,
			HeroActor = HeroAvatar,
			Pos = AvatarIdInfo.Pos,
		}
		CWaring(StringUtil.Format("RemoveSingleTeamMemAvatar:{0}|{1}",TeamMemPlayerId,AvatarIdInfo.Pos))
		self:PlayExitDissolveLS(DissolveInfo,function ()
			RemoveInnerFunc()
		end)

		--播放溶解声音
		SoundMgr:PlaySound(SoundCfg.SoundEffects.TEAM_PARTNER_QUIT)
	end
end

-- 更换武器
function HallTabPlay:ChangeMemberWeapon(TeamMemPlayerId,WeaponSkinId, PlayDissolveLS)
	if self.MemberAvatarIds[TeamMemPlayerId] then
		MvcEntry:GetModel(HallModel):DispatchType(
				HallModel.ON_HERO_TAKEOFF_WEAPON, 
				{HeroInstID = TeamMemPlayerId, AnimControl = false,})
	end
	MvcEntry:GetModel(HallModel):DispatchType(
				HallModel.ON_HERO_PUTON_WEAPON, 
				{HeroInstID = TeamMemPlayerId, WeaponSkinID = WeaponSkinId, AnimControl = true, PlayDissolveLS = PlayDissolveLS})
end

-- 队友的英雄或皮肤Id改变了
function HallTabPlay:OnTeamMemberHeroInfoChanged(_,TeamMember)
	self:SpawnSingleTeamMemberAvatar(TeamMember.PlayerId, TeamMember, true, true)
end

-- 队友的武器或武器皮肤Id改变了
function HallTabPlay:OnTeamMemberWeaponInfoChanged(_,TeamMember)
	self:ChangeMemberWeapon(TeamMember.PlayerId, TeamMember.WeaponSkinId, true)
end

---------------------------- Avatar 相关   end -----------------------------------

---------------------------- LS 相关     start -----------------------------------

--[[
	检测是否播放进队LS
]]
function HallTabPlay:CheckEnterTeamLs()
	if not self.LSHallEnterFinished or self.IsTriggerHideAvatar then
		return
	end
	self:HandleHeashow(self.SelfId, true)
	self:CheckSelfAvatarWeapon()
	self:PlayEnterTeamLs()
	self:PlayBlackWhiteSoloSquardLS(nil,true)
end

--[[
	添加或者创建进队LS延时 操控参数计时器
]]
function HallTabPlay:AddOrRemoveLSEnterTeamDealyTimer(IsAdd,CallBack)
	if self.WaitLSEnterTeamDealyTimer then
		self:RemoveTimer(self.WaitLSEnterTeamDealyTimer)
		self.WaitLSEnterTeamDealyTimer = nil
	end
	if IsAdd then
		self.WaitLSEnterTeamDealyTimer = self:InsertTimer(1,function ()
			self:RemoveTimer(self.WaitLSEnterTeamDealyTimer)
			self.WaitLSEnterTeamDealyTimer = nil
			if CallBack then
				CallBack()
			end
		end,false,TimerTypeEnum.TimerDelegate)
	end
end

--[[
	播放进队LS
]]
function HallTabPlay:PlayEnterTeamLs()
	CWaring("HallMdt_PlayEnterTeamLs=========================")
	MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(self.LSEventTagName)
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
		LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_ENTER_TEAM), 
		SetBindings = SetBindings,
		TransformOrigin = UE.FTransform.Identity,
		--这边开启，但是必须过滤队友融相关，如果不过滤会停止队员相关的溶解效果。特别是上一队刚取消，下一队又创建的情况。上一队的消失效果没有播完
		NeedStopAllSequence = true,
		StopAllFilterTags = self:GetPlayingDissolveLSTagList(),
	}
	--[[
		如里需要不开启上述的StopAllFilterTags
		就必须调用下述的方法进行 强制暂停当前正在播放的消融
	]]
	--self:ForceStopPlayingDissolveLS()
	MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("HallTeam", function ()
		CWaring("HeroMdt:PlaySequenceByTag PlayEnterTeamLs HallTeam")
	end, PlayParam)

	self:AddOrRemoveLSEnterTeamDealyTimer(true,function ()
		self:SpawnTeamMemberAvatars(true)
	end)


	self:AddOrRemoveIdleTimer(false)
end

--[[
	播放出队LS
	根随着匹配状态的取消
]]
function HallTabPlay:PlayExistTeamLs()
	CWaring("HallMdt_PlayExistTeamLs=========================")
	self.IsExitingTeam = true
	self:AddOrRemoveLSEnterTeamDealyTimer(false)
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	local HallActor = HallAvatarMgr:GetHallAvatar(MvcEntry:GetModel(UserModel).PlayerId, ViewConst.Hall, MvcEntry:GetModel(HeroModel):GetFavoriteId())

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
		LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_EXIT_TEAM),
		SetBindings = SetBindings,
		TransformOrigin = UE.FTransform.Identity,
		--这边开启，但是必须过滤队友融相关，如果不过滤会停止队员相关的溶解效果。，特别是多人时，可能上一个队友离开的消融没有播完
		NeedStopAllSequence = true,
		StopAllFilterTags = self:GetPlayingDissolveLSTagList(),
	}
	--[[
		如里需要不开启上述的StopAllFilterTags
		就必须调用下述的方法进行 强制暂停当前正在播放的消融
	]]
	--self:ForceStopPlayingDissolveLS()
	self:HandleHeashow(self.SelfId, true, false)
	MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("HallTeam", function ()
		CWaring("HallTabPlay: HallTeam PlaySequenceByTag PlayExistTeamLs Suc")
		self:CheckSelfAvatarWeapon(false)
		self.IsExitingTeam = false
		self:AddOrRemoveIdleTimer(true)
	end, PlayParam)

end

--[[
	播放Solo白点LS (目前逻辑应该是只针对主角生效)
	单人匹配时
	进队伍时
]]
function HallTabPlay:PlayBlackWhiteSoloSquardLS(SkeletalActorList,JustSelf)
	-- if JustSelf then
	-- 	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	-- 	local HeroAvatar = HallAvatarMgr:GetHallAvatar(self.SelfId)
	-- 	if not HeroAvatar then
	-- 		return
	-- 	end
	-- 	SkeletalActorList = {HeroAvatar:GetSkinActor()}
	-- end
	-- if not SkeletalActorList or #SkeletalActorList <= 0 then
	-- 	return
	-- end
	-- CWaring("PlayBlackWhiteSoloSquardLS Length:" .. #SkeletalActorList)
	-- local SetBindings = {}
	-- for k,SkeletalActor in ipairs(SkeletalActorList) do
	-- 	local Binding = 
	-- 	{
	-- 		Actor = SkeletalActor, 
	-- 		TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_COMPONENT,
	-- 	}
	-- 	table.insert(SetBindings,Binding)
	-- end
	-- local PlayParam = {
	-- 	LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_HERO_BLACKWHITE_SOLOSQUARD),
	-- 	SetBindings = SetBindings,
	-- }
	-- MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("LS_HERO_BLACKWHITE_SOLOSQUARD", function (IsForceStop)
	-- 	CWaring("PlayBlackWhiteSoloSquardLS:PlaySequenceByTag Suc")
	-- 	-- if not IsForceStop then
	-- 	-- 	return
	-- 	-- end
	-- 	-- local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	-- 	-- local HeroAvatar = HallAvatarMgr:GetHallAvatar(self.SelfId)
	-- 	-- if not HeroAvatar then
	-- 	-- 	return
	-- 	-- end
	-- 	-- local HallAvatarCommonComponent = HeroAvatar:GetHallAvatarCommonComponent()
	-- 	-- if not HallAvatarCommonComponent then
	-- 	-- 	return
	-- 	-- end
	-- 	-- HallAvatarCommonComponent:ResumeMaterial()
	-- end, PlayParam)
end

--[[
	播放Match白点LS（应该是对所有队员）
	匹配成功时
]]
function HallTabPlay:PlayBlackWhiteMatchLS(SkeletalActorList,WeaponActorList)
	-- if not SkeletalActorList or #SkeletalActorList <= 0 then
	-- 	CWaring("HallMdt:PlayBlackWhiteMatchLS SkeletalActorList nil,Please Check")
	-- 	return
	-- end
	-- if not WeaponActorList or #WeaponActorList <= 0 then
	-- 	CWaring("HallMdt:PlayBlackWhiteMatchLS WeaponActorList nil,Please Check")
	-- 	return
	-- end
	-- CWaring("PlayBlackWhiteMatchLS Length:" .. #SkeletalActorList)
	-- local SetBindings = {}
	-- for k,SkeletalActor in ipairs(SkeletalActorList) do
	-- 	local Binding = 
	-- 	{
	-- 		Actor = SkeletalActor, 
	-- 		TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_COMPONENT,
	-- 	}
	-- 	table.insert(SetBindings,Binding)
	-- end
	-- for k,WeaponActor in ipairs(WeaponActorList) do
	-- 	local Binding = 
	-- 	{
	-- 		Actor = WeaponActor, 
	-- 		TargetTag = SequenceModel.BindTagEnum.WEAPON_SKELETMESH_COMPONENT,
	-- 	}
	-- 	table.insert(SetBindings,Binding)
	-- end
	-- local PlayParam = {
	-- 	LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_HERO_BLACKWHITE_MATCH),
	-- 	SetBindings = SetBindings,
	-- }
	-- MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("LS_HERO_BLACKWHITE_MATCH", function ()
	-- 	CWaring("PlayBlackWhiteMatchLS:PlaySequenceByTag Suc")
	-- end, PlayParam)
end


--[[
	强制停止相关消融表现LS的播放，并且强制回调
]]
function HallTabPlay:ForceStopPlayingDissolveLS()
	for k,DissolveInfo in pairs(self.MemberId2PlayingDissolveInfo) do
		if DissolveInfo.Callback then
			DissolveInfo.Callback()
		end
	end
	self.MemberId2PlayingDissolveInfo = {}
	self.Pos2PlayingDissolveInfo = {}
end

--[[
	获取当前正在播放的消融表现LS的Tag列表
]]
function HallTabPlay:GetPlayingDissolveLSTagList()
	local TagList = {}
	for k,DissolveInfo in pairs(self.MemberId2PlayingDissolveInfo) do
		if DissolveInfo.SequenceTagName then
			table.insert(TagList,DissolveInfo.SequenceTagName)
		end
	end
	return TagList
end

--[[
	播放角色溶解LS
	队员加入的时候

	local DissolveInfo = {
		MemberId = 0
		HeroActor = nil,
		Pos = Pos,
	}
]]
function HallTabPlay:PlayDissolveLS(DissolveInfo,Callback)
	local SequenceTagName = "LS_TEAM_DISSOLVE" .. DissolveInfo.Pos
	if self.MemberId2PlayingDissolveInfo[DissolveInfo.MemberId] then
		CWaring("HallTabPlay:PlayDissolveLS Playing MemberId:" .. DissolveInfo.MemberId)
		--表示当前这个队友有溶解特效在播放，中断当前特效，不再播放
		local OldDissolveInfo = self.MemberId2PlayingDissolveInfo[DissolveInfo.MemberId]
		local OldSequenceTagName = "LS_TEAM_DISSOLVE" .. OldDissolveInfo.Pos
		self.MemberId2PlayingDissolveInfo[OldDissolveInfo.MemberId] = nil
		self.Pos2PlayingDissolveInfo[OldDissolveInfo.Pos] = nil
		MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(OldSequenceTagName)

		if OldDissolveInfo.Pos == DissolveInfo.Pos then
			if Callback then
				Callback()
			end
			-- return
		end
	end
	if self.Pos2PlayingDissolveInfo[DissolveInfo.Pos] then
		CWaring("HallTabPlay:PlayDissolveLS Playing Pos:" .. DissolveInfo.Pos)
		--当前位置，有其他队员溶解效果在播放，中断当前特效，并提前执行对应的回调
		local OldPosDissolveInfo = self.Pos2PlayingDissolveInfo[DissolveInfo.Pos]
		local OldSequenceTagName = "LS_TEAM_DISSOLVE" .. OldPosDissolveInfo.Pos
		MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(OldSequenceTagName)
		if OldPosDissolveInfo.Callback then
			OldPosDissolveInfo.Callback()
		end
		self.Pos2PlayingDissolveInfo[OldPosDissolveInfo.Pos] = nil
		self.MemberId2PlayingDissolveInfo[OldPosDissolveInfo.MemberId] = nil
	end
	local SkinActor = DissolveInfo.HeroActor:GetSkinActor()
	local SetBindings = {}
	local Binding = 
	{
		Actor = SkinActor, 
		TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_COMPONENT,
	}
	table.insert(SetBindings,Binding)
	local SlotAvatarInfo = DissolveInfo.HeroActor:GetSlotAvatarInfo(HallApparelMgr.HERO_SLOT_MAINWEAPON)
    local WeaponAvatar = SlotAvatarInfo and SlotAvatarInfo.AvatarActor
    if WeaponAvatar then
        local WeaponBinding = {
			Actor = WeaponAvatar, 
			TargetTag = SequenceModel.BindTagEnum.WEAPON_SKELETMESH_COMPONENT,
		}
		table.insert(SetBindings,WeaponBinding)
    end
	DissolveInfo.Callback = Callback
	DissolveInfo.SequenceTagName = SequenceTagName
	self.MemberId2PlayingDissolveInfo[DissolveInfo.MemberId] = DissolveInfo
	self.Pos2PlayingDissolveInfo[DissolveInfo.Pos] = DissolveInfo
	local PlayParam = {
		LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_HERO_DISSOLVE),
		SetBindings = SetBindings,
		NeedStopAfterFinish = true,
		RestoreState = false,
	}
	print("HallTabPlay:PlayDissolveLS", SequenceTagName, DissolveInfo.MemberId)
	MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(SequenceTagName, function ()
		CWaring("PlayDissolveLS:PlaySequenceByTag PlayDissolveLS Suc")
		self.MemberId2PlayingDissolveInfo[DissolveInfo.MemberId] = nil
		self.Pos2PlayingDissolveInfo[DissolveInfo.Pos] = nil
		if Callback then
			Callback()
		end
		local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
		local HeroAvatar = HallAvatarMgr:GetHallAvatar(DissolveInfo.MemberId)
		if not HeroAvatar then
			return
		end
		local SkinActor = HeroAvatar:GetSkinActor()
		if not SkinActor then
			return
		end
		if SkinActor.BP_HallAvatarCommonComponent then
			CWaring("PlayDissolveLS:PlaySequenceByTag SkinActor ResumeMaterial")
			SkinActor.BP_HallAvatarCommonComponent:ResumeMaterial()
		end
		if SkinActor.BP_HallAvatarComponent then
			CWaring("PlayDissolveLS:PlaySequenceByTag SkinActor StopEffect")
			SkinActor.BP_HallAvatarComponent:StopEffect()
		end
	end, PlayParam)
end

--[[
	播放角色溶解LS
	队员离开的时候
	local DissolveInfo = {
		MemberId = 0
		HeroActor = nil,
		Pos = Pos,
	}
]]
function HallTabPlay:PlayExitDissolveLS(DissolveInfo,Callback)
	local SequenceTagName = "LS_TEAM_DISSOLVE" .. DissolveInfo.Pos
	if self.MemberId2PlayingDissolveInfo[DissolveInfo.MemberId] then
		CWaring("HallTabPlay:PlayExitDissolveLS Playing MemberId:" .. DissolveInfo.MemberId)
		--表示当前这个队友有溶解特效在播放，中断当前特效，不再播放
		local OldDissolveInfo = self.MemberId2PlayingDissolveInfo[DissolveInfo.MemberId]
		local OldSequenceTagName = "LS_TEAM_DISSOLVE" .. OldDissolveInfo.Pos
		self.MemberId2PlayingDissolveInfo[OldDissolveInfo.MemberId] = nil
		self.Pos2PlayingDissolveInfo[OldDissolveInfo.Pos] = nil
		MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(OldSequenceTagName)

		if OldDissolveInfo.Pos == DissolveInfo.Pos then
			CWaring("HallTabPlay:PlayExitDissolveLS Playing MemberId Pos:" .. DissolveInfo.Pos)
			if Callback then
				Callback()
			end
			return
		end
	end
	if self.Pos2PlayingDissolveInfo[DissolveInfo.Pos] then
		CWaring("HallTabPlay:PlayExitDissolveLS Playing Pos:" .. DissolveInfo.Pos)
		--当前位置，有其他队员溶解效果在播放，中断当前特效，并提前执行对应的回调
		local OldPosDissolveInfo = self.Pos2PlayingDissolveInfo[DissolveInfo.Pos]
		local OldSequenceTagName = "LS_TEAM_DISSOLVE" .. OldPosDissolveInfo.Pos
		MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(OldSequenceTagName)
		if OldPosDissolveInfo.Callback then
			OldPosDissolveInfo.Callback()
		end
		self.Pos2PlayingDissolveInfo[OldPosDissolveInfo.Pos] = nil
		self.MemberId2PlayingDissolveInfo[OldPosDissolveInfo.MemberId] = nil
	end
	local SkinActor = DissolveInfo.HeroActor:GetSkinActor()
	local SetBindings = {}
	local Binding = 
	{
		Actor = SkinActor, 
		TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_COMPONENT,
	}
	table.insert(SetBindings,Binding)
	local SlotAvatarInfo = DissolveInfo.HeroActor:GetSlotAvatarInfo(HallApparelMgr.HERO_SLOT_MAINWEAPON)
    local WeaponAvatar = SlotAvatarInfo and SlotAvatarInfo.AvatarActor
    if WeaponAvatar then
        local WeaponBinding = {
			Actor = WeaponAvatar, 
			TargetTag = SequenceModel.BindTagEnum.WEAPON_SKELETMESH_COMPONENT,
		}
		table.insert(SetBindings,WeaponBinding)
    end
	DissolveInfo.Callback = Callback
	DissolveInfo.SequenceTagName = SequenceTagName
	self.MemberId2PlayingDissolveInfo[DissolveInfo.MemberId] = DissolveInfo
	self.Pos2PlayingDissolveInfo[DissolveInfo.Pos] = DissolveInfo
	local PlayParam = {
		LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_HERO_EXIT_DISSOLVE),
		SetBindings = SetBindings,
		NeedStopAfterFinish = true,
		RestoreState = false,
	}
	print("HallTabPlay:PlayExitDissolveLS", SequenceTagName, DissolveInfo.MemberId)
	MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(SequenceTagName, function ()
		CWaring("PlayExitDissolveLS:PlaySequenceByTag Suc")
		self.MemberId2PlayingDissolveInfo[DissolveInfo.MemberId] = nil
		self.Pos2PlayingDissolveInfo[DissolveInfo.Pos] = nil
		if Callback then
			Callback()
		end
	end, PlayParam)
end
---------------------------- LS 相关        end -----------------------------------


--region ------------------------------------- 闲置计时器处理 -------------------------------------------------------------

---当其他界面关闭时，需要监听，判断当前界面是否是最上层界面，如果是的话则重置一下闲置计时器
function HallTabPlay:OnOtherViewClosed()
    -- TODO Hall 
	local IsTopHall,TopView = self:CheckTopViewIsHall() 
	if IsTopHall then
		self:AddOrRemoveIdleTimer(true)
	-- else 
	-- 	CWaring("HallTabPlay:OnOtherViewClosed Top not Hall:" .. TopView.viewId)
	end	
end

--检查当前UI堆栈上层，是不是大厅界面
function HallTabPlay:CheckTopViewIsHall()
	---@type ViewModel
	local ViewModel = MvcEntry:GetModel(ViewModel) 
	local TopView = ViewModel:GetOpenLastView()
	-- if TopView and TopView.viewId == self.viewId then
	-- TODO Hall 待测试
	if TopView and TopView.viewId == ViewConst.Hall then
		return true,nil
	end
	return false,TopView
end

---当其他界面展开时，移除闲置计时器
function HallTabPlay:OnOtherViewShowed(_, ViewId)		
	if not HallTabPlay.IdleCheckExcludeViewId[ViewId] then
		self:AddOrRemoveIdleTimer(false)
	end
	print("HallTabPlay:OnOtherViewShowed",ViewId)
	local Mdt =  MvcEntry:GetCtrl(ViewRegister):GetView(ViewId)
    if Mdt and Mdt.uiLayer and Mdt.uiLayer >  UIRoot.UILayerType.Pop then
		return
	end
	if self.LSHallEnterFinished and not HallTabPlay.OpenOtherViewExcludeViewId[ViewId] then
		print("HallTabPlay:OnOtherViewShowed StopSequenceByTag",ViewId)
		SoundMgr:StopPlayAllEffect()
		SoundMgr:StopPlayAllVoice()
		MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(self.LSEventTagName)
	end
end

--[[
	封装一个大厅空闲的计时器

	重置一下闲置计时器
	触发时机：
	1.上层界面关闭且不在队伍中
	2.退出队伍
	3.取消匹配且不在队伍中

	移除时机：
	1.上层界面打开
	2.在队伍中
	3.开始匹配
]]
function HallTabPlay:AddOrRemoveIdleTimer(Add)
	if self.IdleTimer  then
		self:RemoveTimer(self.IdleTimer)
	end
	self.IdleTimer  = nil
	if Add then
		if not self:CheckCanPlayIdleOrTouch() then
			return
		end
		--15秒没有动过之后，走这里
		local function _PlayerHaveNotDoAnythingWithin15s()
			self.IdleTimer  = nil
			self:_IdleFunc()
		end
		print("HallTabPlay:AddOrRemoveIdleTimer true")
		self.IdleTimer = self:InsertTimer(MvcEntry:GetModel(HallModel):GetHallIdleAnimGapTime(), _PlayerHaveNotDoAnythingWithin15s,false,TimerTypeEnum.TimerDelegate)
	else
		print("HallTabPlay:AddOrRemoveIdleTimer false")
	end
end

function HallTabPlay:CheckCanPlayIdleOrTouch()
	if not self.LSHallEnterFinished then
		print("HallTabPlay:CheckCanPlayIdleOrTouch not LSHallEnterFinished")
		return false
	end
	if MvcEntry:GetModel(TeamModel):IsSelfInTeam() then
		--队伍中不能开启此逻辑
		CWaring("HallTabPlay:CheckCanPlayIdleOrTouch IsSelfInTeam return")
		return false
	end
	if MvcEntry:GetModel(MatchModel):IsMatching() then
		--匹配中，不能开启此逻辑
		CWaring("HallTabPlay:CheckCanPlayIdleOrTouch _IdleFunc IsMatching return")
		return false
	end
	if self.WaitEnterDS then
		--等待DS进入，不能响应
		print("HallTabPlay:CheckCanPlayIdleOrTouch WaitEnterDS")
		return false
	end
	if MvcEntry:GetModel(HallModel):IsLevelTravel() then
		print("HallTabPlay:CheckCanPlayIdleOrTouch IsLevelTravel")
		return false
	end
	if self.IsExitingTeam then
		-- 出队ls播放中，不响应（否则会导致回调中关于枪支展示的逻辑/其他逻辑，无法正常执行）
		CWaring("HallTabPlay:CheckCanPlayIdleOrTouch IsExitingTeam return")
		return false
	end
	return true
end


--[[
	满足闲置计时器的触发条件，触发的函数
]]
function HallTabPlay:_IdleFunc(ForceID)
	self:AddOrRemoveIdleTimer(true)
	if not ForceID then
		if not self:CheckCanPlayIdleOrTouch() then
			return
		end
		if MvcEntry:GetCtrl(SequenceCtrl):IsSequencePlaying(self.LSEventTagName) then
			return
		end
		if MvcEntry:GetModel(SoundModel):IsSoundEventInCD(SoundCfg.Voice.HALL_IDLE) then
			CWaring("HallTabPlay:_IdleFunc Sound HALL_IDLE CD")
			return
		end
		if MvcEntry:GetModel(HallModel):IsLSEventInCD(HeroModel.LSEventTypeEnum.HallIdle) then
			CWaring("HallTabPlay:_IdleFunc LS HallIdle CD")
			return
		end
	end

	--玩家已经15秒没有动过了
	CLog("[cw] Player haven't do anything within 15s")
	--大厅进入时播放角色语音
	---@type HeroModel
	local TheHeroModel = MvcEntry:GetModel(HeroModel)
	local CurrentPlayerHeroSkinId = TheHeroModel:GetFavoriteHeroFavoriteSkinId()
	SoundMgr:PlayHeroVoice(CurrentPlayerHeroSkinId, SoundCfg.Voice.HALL_IDLE)

	--TODO 播放互动LS
	self:ForceStopPlayingDissolveLS()
	local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	local HallActor = HallAvatarMgr:GetHallAvatar(MvcEntry:GetModel(UserModel).PlayerId, ViewConst.Hall, TheHeroModel:GetFavoriteId())
	if not HallActor then
		return
	end
	local SetBindings = {
		{
			Actor = HallActor:GetSkinActor(),
			TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_ANIM,
		}
	}
	local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
	if CameraActor ~= nil then
		local CameraBinding = {
			Actor = CameraActor, 
			TargetTag = SequenceModel.BindTagEnum.CAMERA,
		}
		table.insert(SetBindings,CameraBinding)
	end
	local FilterId
	if MvcEntry:GetModel(HallModel):IsLastPlayLSOverTimes() then
		FilterId = MvcEntry:GetModel(HallModel).LastPlayIdleID
	end
	local EventLSCfg = TheHeroModel:GetHeroEventLSCfg(HeroModel.LSEventTypeEnum.HallIdle,CurrentPlayerHeroSkinId,FilterId)
	if ForceID then
		local Temp = G_ConfigHelper:GetSingleItemById(Cfg_HeroEventLSCfg, ForceID)
		if Temp then
			EventLSCfg = Temp
		end
	end
	local PlayParam = {
		LevelSequenceAsset = EventLSCfg and EventLSCfg[Cfg_HeroEventLSCfg_P.LSPath] or nil, 
		SetBindings = SetBindings,
		TransformOrigin = UE.FTransform.Identity,
		NeedStopAllSequence = true,
		NeedAssign2Material = EventLSCfg and EventLSCfg[Cfg_HeroEventLSCfg_P.NeedAssign2Material] or false,
		IsEnablePostProcess = EventLSCfg and EventLSCfg[Cfg_HeroEventLSCfg_P.IsEnablePostProcess] or false,
	}
	MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(self.LSEventTagName, function ()
		CWaring("HeroMdt:PlaySequenceByTag _IdleFunc Suc")
	end, PlayParam)

	if EventLSCfg then
		if EventLSCfg[Cfg_HeroEventLSCfg_P.EventCD] > 0 then
			MvcEntry:GetModel(HallModel):RefreshLSEventCD(HeroModel.LSEventTypeEnum.HallIdle,EventLSCfg[Cfg_HeroEventLSCfg_P.EventCD])
		end
		
		MvcEntry:GetModel(HallModel):SetCurrentPlayLS(EventLSCfg[Cfg_HeroEventLSCfg_P.Id])
	end
end

--endregion ----------------------------------- 闲置计时器处理 ------------------------------------------------------------

---------------- 按钮点击 ----------------------------

-- 返回登录
function HallTabPlay:OnClicked_BtnBackLogin()
	MvcEntry:GetCtrl(CommonCtrl):GAME_LOGOUT()
end

function HallTabPlay:OnClicked_ESC()
	---@type MatchModel
	local MatchModel = MvcEntry:GetModel(MatchModel)
	if MatchModel:IsMatchSuccessed() then return end
	
	-- MvcEntry:OpenView(ViewConst.MainMenu)
	if MvcEntry:GetModel(InputModel):IsPCInput() then
		-- 仅PC输入支持ESC打开系统菜单 （目前是针对手柄输入不响应
		MvcEntry:OpenView(ViewConst.SystemMenu)
	end
end

function HallTabPlay:InitQuestionnaireEntrance()
	local WidgetClass = UE4.UClass.Load("/Game/BluePrints/UMG/OutsideGame/Questionnaire/WBP_Questionnaire_Entrance.WBP_Questionnaire_Entrance")
	local Widget = NewObject(WidgetClass, self.View)
	UIRoot.AddChildToPanel(Widget, self.View.Panel_ActivityEntrance_1)
	
	if Widget and CommonUtil.IsValid(Widget) then
		---@type QuestionnaireHallEntrance
		self.QuestionnaireHallEntrance = UIHandler.New(self, Widget, require("Client.Modules.Questionnaire.QuestionnaireHallEntrance")).ViewInstance
	end
end

--[[
	点击英雄上报
]]
function HallTabPlay:OnClickedEventTrackingHeroInfo(InHeroId)
	if not InHeroId then return end
	local EventTrackingData = {
		hero_id = InHeroId,
		duration = 0,
		action = MvcEntry:GetModel(EventTrackingModel).CLICKHEROACTSCENE.HALL
	}
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_HERO_INFO_EVENTTRACKING, EventTrackingData)
end

return HallTabPlay
