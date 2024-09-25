local BP_HallHeroHeadShow = Class()

function BP_HallHeroHeadShow:ReceiveBeginPlay()
	CLog("BP_HallHeroHeadShow ReceiveBeginPlay")
	self.Overridden.ReceiveBeginPlay(self)
	MvcEntry:GetModel(TeamModel):AddListener(TeamModel.ON_TEAM_MEMBER_PREPARE,self.OnTeamMemberStateChange,self)
	MvcEntry:GetModel(TeamModel):AddListener(TeamModel.ON_TEAM_LEADER_CHANGED,self.OnTeamMemberLeaderChange,self)
	MvcEntry:GetModel(GVoiceModel):AddListener(GVoiceModel.ON_ROOM_USER_PUBLISH_STATE_CHANGE,self.CheckMicIsValid,self)
	MvcEntry:GetModel(GVoiceModel):AddListener(GVoiceModel.ON_ROOM_USER_SUBSCRIBE_STATE_CHANGE,self.CheckMicIsValid,self)
	MvcEntry:GetModel(GVoiceModel):AddListener(GVoiceModel.ON_RECEIVE_REMOTE_AUDIO,self.OnReceiveRemoteAudio,self)
	MvcEntry:GetModel(GVoiceModel):AddListener(GVoiceModel.ON_RECEIVE_LOCAL_AUDIO,self.OnReceiveLocalAudio,self)

end

function BP_HallHeroHeadShow:ReceiveEndPlay(EndPlayReason)
	CLog("BP_HallHeroHeadShow ReceiveEndPlay")
	self.Overridden.ReceiveEndPlay(self,EndPlayReason)
	MvcEntry:GetModel(TeamModel):RemoveListener(TeamModel.ON_TEAM_MEMBER_PREPARE,self.OnTeamMemberStateChange,self)
	MvcEntry:GetModel(TeamModel):RemoveListener(TeamModel.ON_TEAM_LEADER_CHANGED,self.OnTeamMemberLeaderChange,self)
	MvcEntry:GetModel(GVoiceModel):RemoveListener(GVoiceModel.ON_ROOM_USER_PUBLISH_STATE_CHANGE,self.CheckMicIsValid,self)
	MvcEntry:GetModel(GVoiceModel):RemoveListener(GVoiceModel.ON_ROOM_USER_SUBSCRIBE_STATE_CHANGE,self.CheckMicIsValid,self)
	MvcEntry:GetModel(GVoiceModel):RemoveListener(GVoiceModel.ON_RECEIVE_REMOTE_AUDIO,self.OnReceiveRemoteAudio,self)
	MvcEntry:GetModel(GVoiceModel):RemoveListener(GVoiceModel.ON_RECEIVE_LOCAL_AUDIO,self.OnReceiveLocalAudio,self)
end

function BP_HallHeroHeadShow:ReceiveDestroyed()
	self.Overridden.ReceiveDestroyed(self)
	CLog("BP_HallHeroHeadShow ReceiveDestroyed")
end

function BP_HallHeroHeadShow:InitData(InData)
	if not InData then
		return
	end
	CLog("BP_HallHeroHeadShow InitData")
	self.PlayerId = InData.PlayerId
	self.PlayerIdStr = tostring(InData.PlayerId)
	local UserModel =  MvcEntry:GetModel(UserModel)
	local TeamModel = MvcEntry:GetModel(TeamModel)
	local IsInTeam = TeamModel:IsInTeam(self.PlayerId)
	local MyPlayerId = UserModel:GetPlayerId()
	self.IsSelf = MyPlayerId == self.PlayerId
	local PlayerInfo = nil
	self.IsLeader = false
	self.IsShowMic = false
	self.IsMicValid = false
	if IsInTeam then
		self.IsShowMic = true
		self.CurLeaderId = TeamModel:GetLeaderId()
		self.IsLeader = TeamModel:GetLeaderId() == self.PlayerId
		PlayerInfo = DeepCopy(TeamModel:GetTeamPlayerInfo(self.PlayerId))
		if self.IsSelf then
			-- 队伍中的名字可能是改名前的旧名字
			PlayerInfo.PlayerName = UserModel:GetPlayerName()
		end
		-- if PlayerInfo.PlayerName then ----story=1004214 --user=郭洪 【社交】账号系统迭代 https://www.tapd.cn/68880148/s/1211315
		-- 	PlayerInfo.PlayerName = StringUtil.SplitPlayerName(PlayerInfo.PlayerName)--string.match(PlayerInfo.PlayerName, "(.-)#")
		-- end
		self:CheckMicIsValid()
	elseif self.IsSelf then
		---单人只有在匹配状态下会有头顶的显示
		PlayerInfo = {
			PlayerId = self.PlayerId,
			PlayerName = UserModel:GetPlayerName(),
			Status = Pb_Enum_TEAM_MEMBER_STATUS.MATCH
		}
		self.IsLeader = true
	end
	if not PlayerInfo then
		CError("BP_HallHeroHeadShow PlayerInfo is nil")
		return
	end
	print("BP_HallHeroHeadShow", "InitData, ", self.PlayerId, self.IsReady, self.CurLeaderId, PlayerInfo.Status)
	self:UpdateMatchStatus(PlayerInfo)
	
	self:InitShowState(InData.NotNeedPlayInAni, self.IsReady and not self.IsLeader , self.IsLeader, math.floor(self.PlayerId), StringUtil.ConvertString2FText(StringUtil.Format(PlayerInfo.PlayerName)), self.IsShowMic, self.IsMicValid)

	self.LastIsReady = self.IsReady
end

function BP_HallHeroHeadShow:UpdateMatchStatus(InData)
	if not InData then
		return
	end
	if not self.PlayerId or self.PlayerId ~= InData.PlayerId  then
		return
	end
	if  InData.Status == Pb_Enum_TEAM_MEMBER_STATUS.MATCH then
		-- self.IsReady = true
		self.IsReady = not self.IsLeader
	else
		if self.IsLeader then
			self.IsReady = false
		else
			self.IsReady = InData.Status == Pb_Enum_TEAM_MEMBER_STATUS.READY
		end
	end
end

function BP_HallHeroHeadShow:OnTeamMemberStateChange(InData)
	if not InData then
		return
	end
	if not self.PlayerId or self.PlayerId ~= InData.PlayerId  then
		return
	end
	self:UpdateMatchStatus(InData)
	print("BP_HallHeroHeadShow", "OnTeamMemberStateChange, ",self.PlayerId,  self.IsReady, InData.Status)
	if self.LastIsReady ~= self.IsReady then
		self:TriggerStatusChange(self.IsReady)
		self.LastIsReady = self.IsReady
	end
end

function BP_HallHeroHeadShow:OnTeamMemberLeaderChange(InData)
	if not InData then
		return
	end
	self.CurLeaderId = InData.NewLeader
	print("BP_HallHeroHeadShow", "OnTeamMemberLeaderChange, ",self.PlayerId, self.IsReady, self.CurLeaderId)
	if InData.OldLeader ~= self.CurLeaderId then
		local Changed = false
		if InData.OldLeader == self.PlayerId then
			Changed = false
		end
		if self.CurLeaderId == self.PlayerId then
			Changed = true
		end
		self.IsLeader = self.CurLeaderId == self.PlayerId
		self:TriggerLeaderChange(Changed)
	end
	local PlayerInfo = MvcEntry:GetModel(TeamModel):GetTeamPlayerInfo(self.PlayerId)
	if not PlayerInfo then
		CError("BP_HallHeroHeadShow OnTeamMemberLeaderChange PlayerInfo is nil")
		return
	end
	self:OnTeamMemberStateChange(PlayerInfo)
end

function BP_HallHeroHeadShow:PreDestroyed()
	CLog("BP_HallHeroHeadShow PreDestroyed")
	self:TriggerInOutChange(false)
end

-- 检测是否开启麦克风 - 对应麦克风Icon：true = 开麦未说话状态 / false = 闭麦状态
function BP_HallHeroHeadShow:CheckMicIsValid()
	local SystemMenuModel = MvcEntry:GetModel(SystemMenuModel)
	if not SystemMenuModel:GetVoiceSetting(SystemMenuConst.VoiceSettingType.VoiceIsOpen) then
		self.IsMicValid = false
	else
		local GVoiceModel = MvcEntry:GetModel(GVoiceModel)
		local TeamModel = MvcEntry:GetModel(TeamModel)
		local RoomName = TeamModel:GetTeamVoiceRoomName()
		if RoomName then
			if self.IsSelf then
				self.IsMicValid = GVoiceModel:GetUserPublishState(RoomName,self.PlayerIdStr) 
			else
				-- 他人的麦开启的条件为：他人开麦 & 自己收听他人
				self.IsMicValid = GVoiceModel:GetUserPublishState(RoomName,self.PlayerIdStr) and GVoiceModel:GetUserSubscribeState(RoomName,self.PlayerIdStr)
			end
		else
			self.IsMicValid = false
		end
	end
	self:TriggerMicValidChange(self.IsMicValid)
end

-- 收到他人的音频
function BP_HallHeroHeadShow:OnReceiveRemoteAudio(Param)
	if not (Param and Param.UserIdStr and Param.Volume)  then
		return
	end
	
    local UserIdStr = Param.UserIdStr
	if UserIdStr ~= self.PlayerIdStr then
		return
	end
	local RoomName = MvcEntry:GetModel(TeamModel):GetTeamVoiceRoomName()
	local PublishState = MvcEntry:GetModel(GVoiceModel):GetUserPublishState(RoomName,UserIdStr)
	if not PublishState then
		return
	end
	local Volume = Param.Volume
	self:TriggerMicSpeakOn()
end

-- 收到自己的音频 
function BP_HallHeroHeadShow:OnReceiveLocalAudio(Volume)
	if not self.IsSelf then
		return
	end
	local RoomName = MvcEntry:GetModel(TeamModel):GetTeamVoiceRoomName()
	local PublishState = MvcEntry:GetModel(GVoiceModel):GetUserPublishState(RoomName,self.PlayerIdStr)
	if not PublishState then
		return
	end
	self:TriggerMicSpeakOn()
end

return BP_HallHeroHeadShow
