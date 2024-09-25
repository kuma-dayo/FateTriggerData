--[[
    等级成长历程数据模型
]]

local super = GameEventDispatcher;
local class_name = "PlayerLevelGrowthModel";

---@class PlayerLevelGrowthModel : GameEventDispatcher
---@field private super GameEventDispatcher
PlayerLevelGrowthModel = BaseClass(super, class_name)

-- 等级成长历程数据更新事件
PlayerLevelGrowthModel.ON_PLAYER_LEVEL_GROWTH_DATA_UPDATE_EVENT = "ON_PLAYER_LEVEL_GROWTH_DATA_UPDATE_EVENT"
-- 等级成长历程奖励数据更新事件
PlayerLevelGrowthModel.ON_PLAYER_LEVEL_GROWTH_REWARD_DATA_UPDATE_EVENT = "ON_PLAYER_LEVEL_GROWTH_REWARD_DATA_UPDATE_EVENT"

-- 等级奖励状态
PlayerLevelGrowthModel.Enum_LevelRewardState = {
	-- 不可获得奖励
	NotGetReward = 1,
	-- 可以获得奖励
	CanGetReward = 2,
	-- 已经领取奖励
	AlreadyGotReward = 3,
}

function PlayerLevelGrowthModel:__init()
    self:_dataInit()
end

function PlayerLevelGrowthModel:_dataInit()
	-- 玩家等级成长奖励数据列表 Key为等级
	self.PlayerLevelRewardData = {}
	-- 任务ID奖励数据列表 key为任务ID  value为奖励领取的相关数据
	self.TaskRewardDataList = {}
end

function PlayerLevelGrowthModel:OnLogin(data)

end

function PlayerLevelGrowthModel:OnLogout(data)
    PlayerLevelGrowthModel.super.OnLogout(self)
    self:_dataInit()
end

-------- 对外接口 -----------

-------- 协议数据处理接口 -----------
--[[
	Msg = {
		int32 Level=1; -- 等级
		int32 Experience=2; 经验
		repeated PlayerAdvanceLevelData AdvanceLevelData = 3 奖励状态
	}
]]
-- 请求玩家等级成长奖励状态返回
function PlayerLevelGrowthModel:On_PlayerLevelUpSyc(Msg)
	self.TaskRewardDataList = {}
	for _, Value in pairs(Msg.AdvanceLevelData) do
		self.TaskRewardDataList[Value.TaskId] = Value
	end
	self:DispatchType(PlayerLevelGrowthModel.ON_PLAYER_LEVEL_GROWTH_DATA_UPDATE_EVENT)
end


--[[
	Msg = {
		int32 Level = 1;                // 领取奖励等级
		repeated PlayerAdvanceLevelData AdvanceLevelData = 2;   奖励状态
	}
]]
-- 请求玩家等级成长奖励状态返回
function PlayerLevelGrowthModel:On_PlayerReceiveLevelRewardRsp(Msg)
	for _, Value in pairs(Msg.AdvanceLevelData) do
		self.TaskRewardDataList[Value.TaskId] = Value
	end
	self:DispatchType(PlayerLevelGrowthModel.ON_PLAYER_LEVEL_GROWTH_REWARD_DATA_UPDATE_EVENT)
end

-- 获取玩家等级表-全表
function PlayerLevelGrowthModel:GetPlayerLevelConfigDict()
	local PlayerLevelConfigDict = G_ConfigHelper:GetDict(Cfg_PlayerLevelConfig)
	return PlayerLevelConfigDict
end

-- 获取玩家等级表-单表
function PlayerLevelGrowthModel:GetPlayerLevelConfig(Level)
	local PlayerLevelConfig = G_ConfigHelper:GetSingleItemById(Cfg_PlayerLevelConfig, Level)
	return PlayerLevelConfig
end

-- 获取玩家等级最终奖励配置表 默认取第一项
function PlayerLevelGrowthModel:GetPlayerLevelFinalRewardConfig()
	local PlayerLevelFinalRewardConfigTable = G_ConfigHelper:GetDict(Cfg_PlayerLevelFinalRewardConfig)
	local PlayerLevelFinalRewardConfig = PlayerLevelFinalRewardConfigTable and PlayerLevelFinalRewardConfigTable[1] or nil
	return PlayerLevelFinalRewardConfig
end

-- 获取玩家等级满级展示配置表 默认取第一项
function PlayerLevelGrowthModel:GetPlayerLevelMaxConfig()
	local PlayerLevelMaxConfigTable = G_ConfigHelper:GetDict(Cfg_PlayerLevelMaxConfig)
	local PlayerLevelMaxConfig = PlayerLevelMaxConfigTable and PlayerLevelMaxConfigTable[1] or nil
	return PlayerLevelMaxConfig
end

-- 获取对应等级的奖励状态
---@param Level number 等级
---@param TaskId number 任务ID
function PlayerLevelGrowthModel:GetLevelRewardState(Level, TaskId)
	---@type UserModel
	local UserModel = MvcEntry:GetModel(UserModel)
	local CurLevel = UserModel:GetPlayerLvAndExp()
	local LevelRewardState = PlayerLevelGrowthModel.Enum_LevelRewardState.NotGetReward
	local IsMeetLevel = CurLevel >= Level and true or false
	if TaskId > 0 then
		-- 有任务ID的是特殊奖励
		local TaskRewardData = self.TaskRewardDataList[TaskId]
		if TaskRewardData then
			if TaskRewardData.State then
				LevelRewardState = PlayerLevelGrowthModel.Enum_LevelRewardState.AlreadyGotReward
			else
				LevelRewardState = (TaskRewardData.Finish and IsMeetLevel) and PlayerLevelGrowthModel.Enum_LevelRewardState.CanGetReward or PlayerLevelGrowthModel.Enum_LevelRewardState.NotGetReward
			end	
		end
	else
		LevelRewardState = CurLevel >= Level and PlayerLevelGrowthModel.Enum_LevelRewardState.AlreadyGotReward or PlayerLevelGrowthModel.Enum_LevelRewardState.NotGetReward
	end
	return LevelRewardState
end

-- 获取等级奖励信息列表
---@return LevelGrowthInfo[]
function PlayerLevelGrowthModel:GetLevelGrowthInfoList()
	local LevelGrowthInfoList = {}
	local PlayerLevelConfigDict = self:GetPlayerLevelConfigDict()
	---@type TaskModel
	local TaskModel = MvcEntry:GetModel(TaskModel)
	---@type UserModel
	local UserModel = MvcEntry:GetModel(UserModel)
	local CurLevel = UserModel:GetPlayerLvAndExp()
	local MaxIndex = #PlayerLevelConfigDict

	for Index, PlayerLevelConfig in ipairs(PlayerLevelConfigDict) do
		-- 第一项不读
		if Index > 1 then
			local Level = PlayerLevelConfig[Cfg_PlayerLevelConfig_P.Lv]
			local LastIndex = Index - 1
			-- 当前等级获得的奖励信息得读取上一等级的配置  服务器结构导致
			local LastPlayerLevelConfig = PlayerLevelConfigDict[LastIndex]
			if LastPlayerLevelConfig then
				local IsMeetLevel = CurLevel >= Level and true or false
				local LevelAwardItemID = LastPlayerLevelConfig[Cfg_PlayerLevelConfig_P.LevelAwardItemID]
				local LevelAwardItemNum = LastPlayerLevelConfig[Cfg_PlayerLevelConfig_P.LevelAwardItemNum]
				local LevelTaskId = LastPlayerLevelConfig[Cfg_PlayerLevelConfig_P.LevelTaskId]
				local IsHasLevelTask = (LevelTaskId and LevelTaskId > 0) and true or false
				local LevelAdvanceItemID = LastPlayerLevelConfig[Cfg_PlayerLevelConfig_P.LevelAdvanceItemID]
				local LevelAdvanceItemNum = LastPlayerLevelConfig[Cfg_PlayerLevelConfig_P.LevelAdvanceItemNum]
				local LevelRewardState = self:GetLevelRewardState(Level, LevelTaskId)
				local TaskDesc = LevelTaskId > 0 and TaskModel:GetTaskDescription(LevelTaskId) or ""
				local TaskProcess = LevelTaskId > 0 and TaskModel:GetTaskProcess(LevelTaskId) or nil
				local CurProgress = TaskProcess and TaskProcess.ProcessValue or 0
				local MaxProgress = TaskProcess and TaskProcess.MaxProcess or 0
				local LevelTaskDesc = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "LevelTaskDesc"), TaskDesc, CurProgress, MaxProgress)
				local ExpProgress = self:GetLevelExpProgress(Level)
				-- 拼接奖励数据
				local LevelRewardItemIconList = {}
				-- 普通等级奖励
				if LevelAwardItemID and LevelAwardItemID > 0 then
					---@type CommonItemIconParam
					local LevelRewardItemIcon = {
						IconType = CommonItemIcon.ICON_TYPE.PROP,
						ItemId = LevelAwardItemID,
						ItemNum = LevelAwardItemNum,
						HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
						IsGot = IsMeetLevel,
						IsLock = not IsMeetLevel,
					}
					LevelRewardItemIconList[#LevelRewardItemIconList + 1] = LevelRewardItemIcon
				end
				-- 任务奖励
				if LevelAdvanceItemID and LevelAdvanceItemID > 0 then
					---@type CommonItemIconParam
					local LevelRewardItemIcon = {
						IconType = CommonItemIcon.ICON_TYPE.PROP,
						ItemId = LevelAdvanceItemID,
						ItemNum = LevelAdvanceItemNum,
						HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
						IsGot = LevelRewardState == PlayerLevelGrowthModel.Enum_LevelRewardState.AlreadyGotReward,
						IsLock = LevelRewardState == PlayerLevelGrowthModel.Enum_LevelRewardState.NotGetReward,
					}
					LevelRewardItemIconList[#LevelRewardItemIconList + 1] = LevelRewardItemIcon
				end
				local IsLastLevel = Index == MaxIndex
				---@class LevelGrowthInfo
				---@field Level number 等级ID
				---@field IsLastLevel boolean 是否最后一个等级
				---@field IsMeetLevel boolean 是否达到目标等级
				---@field LevelTaskId number 等级任务ID
				---@field IsHasLevelTask boolean 是否拥有等级任务 任务ID不等于0
				---@field LevelRewardState number 奖励状态 PlayerLevelGrowthModel.Enum_LevelRewardState
				---@field LevelTaskDesc string 任务描述
				---@field ExpProgress number 经验进度条
				---@field LevelRewardItemIconList CommonItemIconParam[] 奖励列表
				local LevelGrowthInfo = {
					Level = Level,
					IsLastLevel = IsLastLevel,
					IsMeetLevel = IsMeetLevel,
					ExpProgress = ExpProgress,
					LevelTaskId = LevelTaskId,
					IsHasLevelTask = IsHasLevelTask,
					LevelRewardState = LevelRewardState,
					LevelTaskDesc = LevelTaskDesc,
					LevelRewardItemIconList = LevelRewardItemIconList,
				}
				LevelGrowthInfoList[#LevelGrowthInfoList + 1] = LevelGrowthInfo
			end
		end
	end
	return LevelGrowthInfoList
end

-- 获取经验进度条数值 
function PlayerLevelGrowthModel:GetLevelExpProgress(TargetLevel)
	---@type UserModel
	local UserModel = MvcEntry:GetModel(UserModel)
	local CurLevel, CurExperience = UserModel:GetPlayerLvAndExp()
	local CurMaxExperience = UserModel:GetPlayerMaxExpForLv(CurLevel)
	local MaxLevel = UserModel:GetPlayerMaxCfgLevel()
	-- 上一个等级
	local LastLevel = CurLevel - 1
	-- 下一个等级
	local NextLevel = CurLevel + 1
	local LastMaxExperience = UserModel:GetPlayerMaxExpForLv(LastLevel)
	-- 当前等级是否大于目标等级
	local IsMeetLevel = CurLevel >= TargetLevel and true or false
	-- 经验进度条 分成左右两个进度条 0.5为最大值
	local LeftProgress = 0
	local RightProgress = 0

	if IsMeetLevel then
		-- 大于目标等级 左边进度条是满的
		LeftProgress = 0.5
		if TargetLevel >= MaxLevel then
			-- 满级的情况右边进度条不需要展示
			RightProgress = 0
		else
			if CurLevel == TargetLevel then
				-- 只有等于当前等级才需要计算右边进度条的长度
				local CurProgressLength = self:GetLevelExpProgressLength(CurLevel)
				local NextProgressLength = self:GetLevelExpProgressLength(NextLevel)
	
				-- 进度条总长度 = 当前等级右进度条的长度 + 下一等级左进度条的长度
				local TotalProgresslength = CurProgressLength + NextProgressLength
				-- 算出经验的比例 当前经验 除于 总经验
				local Progress = CurExperience / CurMaxExperience
				-- 算出经验进度条的实际长度
				local RealProgressLength = Progress * TotalProgresslength
				-- 计算出当前等级右进度条的长度比例
				RightProgress = (RealProgressLength / CurProgressLength) / 2
				RightProgress = RightProgress > 0.5 and 0.5 or RightProgress
			else
				RightProgress = 0.5
			end
		end
	else
		-- 小于目标等级 右边进度条是0
		RightProgress = 0
		if NextLevel == TargetLevel then
			local CurProgressLength = self:GetLevelExpProgressLength(CurLevel)
			local TargetProgressLength = self:GetLevelExpProgressLength(TargetLevel)
	
			-- 进度条总长度 = 当前等级右进度条的长度 + 目标等级的左进度条的长度
			local TotalProgresslength = CurProgressLength + TargetProgressLength
			-- 算出经验的比例
			local Progress = CurExperience / CurMaxExperience
			-- 算出经验进度条的实际长度
			local RealProgressLength = Progress * TotalProgresslength
			-- 计算出当前等级左进度条的长度比例
			LeftProgress = ((RealProgressLength - CurProgressLength) / TargetProgressLength) / 2
			LeftProgress = LeftProgress < 0 and 0 or LeftProgress
		else
			LeftProgress = 0
		end
	end
	local ExpProgress = LeftProgress + RightProgress
	return ExpProgress
end

-- 获取经验进度条长度(居中对齐所以直接取一半的长度)   只能写死两种长度（普通等级奖励跟任务等级）才能计算进度条
function PlayerLevelGrowthModel:GetLevelExpProgressLength(Level)
	local ProgressLength = 100
	-- 当前等级获得的等级奖励信息得读取上一等级的配置  服务器结构导致
	local LastLevel = Level - 1
	local PlayerLevelConfig = self:GetPlayerLevelConfig(LastLevel)
	if PlayerLevelConfig then
		local LevelTaskId = PlayerLevelConfig[Cfg_PlayerLevelConfig_P.LevelTaskId]
		local IsHasTask = LevelTaskId and LevelTaskId > 0
		ProgressLength = IsHasTask and 150 or 100
	end
	return ProgressLength
end