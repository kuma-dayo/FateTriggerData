--[[
    个人统计数据数据模型
]]

local super = GameEventDispatcher;
local class_name = "PersonalStatisticsModel";

---@class PersonalStatisticsModel : GameEventDispatcher
---@field private super GameEventDispatcher
PersonalStatisticsModel = BaseClass(super, class_name)
-- 个人统计数据 - 赛季数据更新事件 携带玩家ID
PersonalStatisticsModel.ON_STATISTICS_SEASON_DATA_UPDATE_EVENT = "ON_STATISTICS_SEASON_DATA_UPDATE_EVENT"
-- 单位转换类型
PersonalStatisticsModel.Const_UnitConversionType = {
	-- 不需要转换
	None = 1,
	-- 秒转分钟 目前用于存活时间 四舍五入
 	Minute = 2,
	-- 秒转小时 目前用于游戏时长 向上取整
	Hour = 3,	
	-- 厘米转千米 目前用于移动距离 保留两位小数
	Kilometre = 4,
	-- 转化成百分比展示
	Percentage = 5,
}

function PersonalStatisticsModel:__init()
    self:_dataInit()
end

function PersonalStatisticsModel:_dataInit()
	-- 赛季配置列表
	self.SeasonConfigList = {}
	-- 模式配置列表
	self.ModeConfigList = {}
	-- 赛季数据   
	self.SeasonBattleDataList = {}
end

function PersonalStatisticsModel:OnLogin(data)
	self:InitConfig()
end

function PersonalStatisticsModel:OnLogout(data)
    PersonalStatisticsModel.super.OnLogout(self)
    self:_dataInit()
end


-------- 初始化配置相关数据 -----------
-- 初始化配置数据
function PersonalStatisticsModel:InitConfig()
	self.SeasonConfigList = {}
    local SeasonCfgTable = G_ConfigHelper:GetDict(Cfg_SeasonConfig)
	if SeasonCfgTable then
		for _, SeasonCfg in pairs(SeasonCfgTable) do
			---@class PersonalStatistSeasonConfig
			---@field SeasonId number 赛季ID
			---@field SeasonName string 赛季名称
			local SeasonConfig = {
				SeasonId = SeasonCfg[Cfg_SeasonConfig_P.SeasonId],
				SeasonName = SeasonCfg[Cfg_SeasonConfig_P.SeasonName],
			}
			self.SeasonConfigList[#self.SeasonConfigList + 1] = SeasonConfig
		end
		table.sort(self.SeasonConfigList, function(A, B)
			return A.SeasonId < B.SeasonId
		end)
	end

	self.ModeConfigList = {}
	local ModeSelect_ModeEnumCfg = G_ConfigHelper:GetDict(Cfg_ModeSelect_ModeEnumCfg)
	if ModeSelect_ModeEnumCfg then
		for _, ModeEnumCfg in pairs(ModeSelect_ModeEnumCfg) do
			local DefaultId = ModeEnumCfg[Cfg_ModeSelect_ModeEnumCfg_P.DefaultId]
			local ModeName = ModeEnumCfg[Cfg_ModeSelect_ModeEnumCfg_P.ModeName]
			local PlayModeId = ModeEnumCfg[Cfg_ModeSelect_ModeEnumCfg_P.PlayModeId]
			local IsShow = ModeEnumCfg[Cfg_ModeSelect_ModeEnumCfg_P.IsShowStatistics]
			if IsShow > 0 then
				local IsOpen = self:CheckPlayModeIdIsOpen(PlayModeId, ModeEnumCfg)
				if IsOpen then
					---@class PersonalStatisticsModeConfig
					---@field DefaultId number 枚举模式ID
					---@field ModeName string 模式描述名称
					---@field PlayModeId number 赛单ID
					local ModeConfig = {
						DefaultId = DefaultId,
						ModeName = ModeName,
						PlayModeId = PlayModeId,
					}
					self.ModeConfigList[#self.ModeConfigList + 1] = ModeConfig
				end
			end
		end
		table.sort(self.ModeConfigList, function(A, B)
			return A.DefaultId < B.DefaultId
		end)
	end
end

-- 检测赛单ID是否开启
---@param PlayModeId number 赛单ID
---@param ModeEnumCfg string 需要检测的配置信息
function PersonalStatisticsModel:CheckPlayModeIdIsOpen(PlayModeId, ModeEnumCfg)
	local IsOpen = false
	-- 赛单配置 需要做筛选 视角、支持小队人数
	local ModeSelect_PlayModeEntryCfg = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_PlayModeEntryCfg, PlayModeId)
	if ModeSelect_PlayModeEntryCfg then
		-- 检测入口开关
		IsOpen = ModeSelect_PlayModeEntryCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.IsOpen] >= 1

		-- 需要检测的视角
		if IsOpen then
			IsOpen = false
			local CheckPerspective = ModeEnumCfg[Cfg_ModeSelect_ModeEnumCfg_P.Perspective]
			local PerspectiveTable = ModeSelect_PlayModeEntryCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.Perspective]
			for _, Perspective in pairs(PerspectiveTable) do
				if Perspective == CheckPerspective then
					IsOpen = true
					break
				end
			end
		end

		-- 需要检测的队伍人数
		if IsOpen then
			IsOpen = false
			local CheckModeType = ModeEnumCfg[Cfg_ModeSelect_ModeEnumCfg_P.ModeType]
			local TeamModeTable = ModeSelect_PlayModeEntryCfg[Cfg_ModeSelect_PlayModeEntryCfg_P.TeamMode]
			for _, TeamMode in pairs(TeamModeTable) do
				if TeamMode == CheckModeType then
					IsOpen = true
					break
				end
			end
		end
	end
	return IsOpen
end

-------- 协议数据处理接口 -----------

-- 请求赛季玩家个人战斗数据返回
function PersonalStatisticsModel:On_SeasonBattleDataRsp(Msg)
	self.SeasonBattleDataList[Msg.QueryPlayerId] = self.SeasonBattleDataList[Msg.QueryPlayerId] or {}
	self.SeasonBattleDataList[Msg.QueryPlayerId][Msg.SeasonId] = self.SeasonBattleDataList[Msg.QueryPlayerId][Msg.SeasonId] or {}
	self.SeasonBattleDataList[Msg.QueryPlayerId][Msg.SeasonId][Msg.TeamType] = self.SeasonBattleDataList[Msg.QueryPlayerId][Msg.SeasonId][Msg.TeamType] or {}
	self.SeasonBattleDataList[Msg.QueryPlayerId][Msg.SeasonId][Msg.TeamType][Msg.View] = {}
	self.SeasonBattleDataList[Msg.QueryPlayerId][Msg.SeasonId][Msg.TeamType][Msg.View].HasData = true
	self:SetRankDataInfo(Msg)
	self:SetHighestLightDataList(Msg)
	self:SetActiveCumulativeData(Msg)
	self:SetBaseData(Msg)
	self:SetLikeCountData(Msg)

	self:DispatchType(PersonalStatisticsModel.ON_STATISTICS_SEASON_DATA_UPDATE_EVENT, Msg.QueryPlayerId)
end

-- 设置段位信息
function PersonalStatisticsModel:SetRankDataInfo(Msg)
	local IsHasRankData = false
	local RankName = ""
	local WinPoint = 0
	if Msg and Msg.DivisionInfo and Msg.DivisionInfo.DivisionId then
		IsHasRankData = Msg.DivisionInfo.DivisionId > 0
		RankName = MvcEntry:GetModel(SeasonRankModel):GetDivisionNameByDivisionId(Msg.DivisionInfo.DivisionId)
		WinPoint = Msg.DivisionInfo.WinPoint
	end
	---@class PersonalStatisticRankData
	---@field IsHasRankData boolean 是否拥有段位信息
	---@field RankName string 段位名称
	---@field WinPoint number 胜点
	---@field RankTagDesc string 当前段位描述 段位排名超过{0}
	local RankData = {
		IsHasRankData = IsHasRankData,
		RankName = RankName,
		WinPoint = WinPoint,
		RankTagDesc = "",--G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1057"), 一期先不做
	}
	self.SeasonBattleDataList[Msg.QueryPlayerId][Msg.SeasonId][Msg.TeamType][Msg.View].RankData = RankData
end

-- 设置高光数据
function PersonalStatisticsModel:SetHighestLightDataList(Msg)
	self.SeasonBattleDataList[Msg.QueryPlayerId][Msg.SeasonId][Msg.TeamType][Msg.View].HighestLightDataList = {}
	local ParamList = { 
		{
			-- 最高击杀
			ValueParam = Msg.MaxKill,
		},
		{
			-- 最高伤害
			ValueParam = Msg.MaxDamage,
		},
		{
			-- 最高助攻
			ValueParam = Msg.MaxAssist,
		},
		{
			-- 最高救援
			ValueParam = Msg.MaxRescue,
		},
		{
			-- 最久存活
			ValueParam = Msg.MaxSurvivalTime,
			-- 单位换算类型
			UnitConversionType = PersonalStatisticsModel.Const_UnitConversionType.Minute,
		},
		{
			-- 最高治疗
			ValueParam = Msg.MaxHeal,
		},
		{
			-- 最远移动距离
			ValueParam = Msg.MaxMoveDis,
			-- 单位换算类型
			UnitConversionType = PersonalStatisticsModel.Const_UnitConversionType.Kilometre,
		},
	}
 	for _, Param in ipairs(ParamList) do
		local MaxValBase = Param.ValueParam
		local Value = MaxValBase and MaxValBase.Val or 0
		local Time = MaxValBase and MaxValBase.Time or 0
		local HighestLightResult = Param.UnitConversionType and self:GetUnitConversionResult(Value, Param.UnitConversionType) or StringUtil.FormatNumberWithComma(Value)
		---@class PersonalStatisticHighestLightData
		---@field HighestLightValue number 高光数值
		---@field HighestLightDesc string 高光数值描述
		---@field HighestLightTimeStr string 数据达成时间
		local HighestLightData = {
			HighestLightValue = Value,
			HighestLightDesc = HighestLightResult,
			HighestLightTimeStr = Time > 0 and TimeUtils.GetDateTimeStrFromTimeStamp(Time, "%04d-%02d-%02d") or "",
		}
		local HighestLightDataList = self.SeasonBattleDataList[Msg.QueryPlayerId][Msg.SeasonId][Msg.TeamType][Msg.View].HighestLightDataList
		HighestLightDataList[#HighestLightDataList + 1] = HighestLightData
	end
end

-- 设置活跃累计数据
function PersonalStatisticsModel:SetActiveCumulativeData(Msg)
	local GameDurationValue = Msg.TotGameTime or 0
	local GameDurationStr = self:GetUnitConversionResult(GameDurationValue, PersonalStatisticsModel.Const_UnitConversionType.Hour)
	---@class PersonalStatisticActiveCumulativeData
	---@field GameDurationValue number 游戏时长数值
	---@field GameDuration string 游戏时长
	---@field BattleCount number 对战次数
	---@field WinCount number 获胜次数
	---@field TopFiveCount number 前5次数
	local ActiveCumulativeData = {
		GameDurationValue = GameDurationValue,
		GameDuration = GameDurationStr,
		BattleCount = Msg.RecordsNum  or 0,
		WinCount = Msg.WinNum  or 0,
		TopFiveCount = Msg.Top5Num  or 0,
	}
	self.SeasonBattleDataList[Msg.QueryPlayerId][Msg.SeasonId][Msg.TeamType][Msg.View].ActiveCumulativeData = ActiveCumulativeData
end

-- 设置基础数据 依次分别为击杀数、生存时间、伤害总量、爆头数、助攻、移动距离、场均伤害、爆头率、救援数量、治疗量、严谨KD
function PersonalStatisticsModel:SetBaseData(Msg)
	self.SeasonBattleDataList[Msg.QueryPlayerId][Msg.SeasonId][Msg.TeamType][Msg.View].BaseDataList = {}
	local IsSelf = Msg.QueryPlayerId == MvcEntry:GetModel(UserModel):GetPlayerId()
	local ParamList = { 
		{
			TitleDesc = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "KillCount")),
			-- 总击杀
			ValueParam = Msg.TotKill or 0,
		},
		{
			TitleDesc = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "SurvivalTime")),
			-- 总生存时间
			ValueParam = Msg.TotSurvivalTime or 0,
			-- 单位换算类型
			UnitConversionType = PersonalStatisticsModel.Const_UnitConversionType.Minute,
		},
		{
			TitleDesc = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "TotalDamage")),
			-- 伤害总量
			ValueParam = Msg.TotDamage or 0,
		},
		{
			TitleDesc = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "BurstCount")),
			-- 爆头总数
			ValueParam = Msg.TotHeadShot or 0,
		},
		{
			TitleDesc = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "Assists")),
			-- 助攻总数
			ValueParam = Msg.TotAssist or 0,
		},
		{
			TitleDesc = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "MoveDistance")),
			-- 移动距离总数
			ValueParam = Msg.TotMoveDis or 0,
			-- 单位换算类型
			UnitConversionType = PersonalStatisticsModel.Const_UnitConversionType.Kilometre,
		},
		{
			TitleDesc = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "AverageDamage")),
			-- 场均伤害
			ValueParam = Msg.RecordsNum > 0 and Msg.TotDamage / Msg.RecordsNum or 0,
		},
		{
			TitleDesc = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "RescueQuantity")),
			-- 救援总数
			ValueParam = Msg.TotRescue or 0,
		},
		{
			TitleDesc = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "TreatmentVolume")),
			-- 总治疗量
			ValueParam = Msg.TotHeal or 0,
		},
		{
			TitleDesc = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "StrictKD")),
			-- 严谨KDA 玩家击杀数/玩家死亡数
			ValueParam = self:CalculateKDAValue(Msg.TotKill, Msg.TotDeath),
			-- 是否隐藏
			IsHide = not IsSelf,
		},
		{
			TitleDesc = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "BurstRate")),
			-- 爆头率
			ValueParam = Msg.TotHeadShotRate,
			-- 单位换算类型
			UnitConversionType = PersonalStatisticsModel.Const_UnitConversionType.Percentage,
			-- 是否隐藏
			IsHide = true,
		},
	}
 	for _, Param in ipairs(ParamList) do
		local BaseDataResult = Param.UnitConversionType and self:GetUnitConversionResult(Param.ValueParam, Param.UnitConversionType) or StringUtil.FormatNumberWithComma(Param.ValueParam)
		local RankTagStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1061")
		local RankTagDesc = "" -- StringUtil.Format(RankTagStr, "5")
		local IsHide = Param.IsHide and true or false
		---@class PersonalStatisticBaseData
		---@field TitleDesc string 标题描述
		---@field BaseDataValue number 基础数据值
		---@field BaseDataDesc string 基础数据描述
		---@field RankTagDesc string 排名tag 例：段位前5%
		local BaseData = {
			TitleDesc = Param.TitleDesc,
			BaseDataValue = Param.ValueParam,
			BaseDataDesc = BaseDataResult,
			RankTagDesc = RankTagDesc,
			IsHide = IsHide,
		}
		local BaseDataList = self.SeasonBattleDataList[Msg.QueryPlayerId][Msg.SeasonId][Msg.TeamType][Msg.View].BaseDataList
		BaseDataList[#BaseDataList + 1] = BaseData
	end
end

-- 设置点赞数据
function PersonalStatisticsModel:SetLikeCountData(Msg)
	self.SeasonBattleDataList[Msg.QueryPlayerId][Msg.SeasonId][Msg.TeamType][Msg.View].LikeCount = Msg.TotLike
end

-- 获取单位转换结果
---@param CalculateValue number 计算的值
---@param UnitConversionType number 单位转换类型
---@return string 转换单位后的结果
function PersonalStatisticsModel:GetUnitConversionResult(CalculateValue, UnitConversionType)
	-- 数值描述
	local ValueDescParam = G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam")
	local UnitConversionValue = CalculateValue
	if UnitConversionType == PersonalStatisticsModel.Const_UnitConversionType.Minute then
		UnitConversionValue = StringUtil.FormatNumberWithComma(math.round(CalculateValue / 60))
		-- "{0}分钟"
		ValueDescParam = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1058")
	elseif UnitConversionType == PersonalStatisticsModel.Const_UnitConversionType.Hour then
		UnitConversionValue = StringUtil.FormatNumberWithComma(math.ceil(CalculateValue / 3600))
		-- "{0}小时"
		ValueDescParam = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1059")
	elseif UnitConversionType == PersonalStatisticsModel.Const_UnitConversionType.Kilometre then
		UnitConversionValue = StringUtil.FormatNumberWithComma(CalculateValue / 100000)
		-- "{0}千米"
		ValueDescParam = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1060")
	elseif UnitConversionType == PersonalStatisticsModel.Const_UnitConversionType.Percentage then
		-- 转化成百分比展示
		UnitConversionValue = StringUtil.FormatFloat_Reamain2Float(CalculateValue)
		ValueDescParam = G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_1")
	end 
	local UnitConversionResult = StringUtil.Format(ValueDescParam, UnitConversionValue)
	return UnitConversionResult
end

-------- 对外接口 -----------

--- 获取赛季配置列表
---@return PersonalStatistSeasonConfig[]
function PersonalStatisticsModel:GetSeasonConfigList()
	-- return self.SeasonConfigList
	-- 临时加当前赛季屏蔽 策划需求 后面需要去掉判断 @huangzhong
	local SeasonConfigList = {}
	local CurrentSeasonId = MvcEntry:GetModel(SeasonModel):GetCurrentSeasonId()
	for _, Value in ipairs(self.SeasonConfigList) do
		if Value.SeasonId == CurrentSeasonId then
			SeasonConfigList[#SeasonConfigList + 1] = Value
		end
	end
	return SeasonConfigList
end

--- 获取模式配置列表
---@return PersonalStatisticsModeConfig[]
function PersonalStatisticsModel:GetModeConfigList()
	return self.ModeConfigList
end

--- 获取对应玩家ID的排位段位数据
---@param PlayerId number 玩家id
---@param SeasonId number 赛季ID
---@param TeamType number 队伍类型 1, 2, 4单双四
---@param View number 视角 1，3 第一第三人称
---@return PersonalStatisticRankData
function PersonalStatisticsModel:GetRankDataByPlayerId(PlayerId, SeasonId, TeamType, View)
	local RankData = self.SeasonBattleDataList[PlayerId][SeasonId][TeamType][View].RankData
	return RankData
end

--- 获取对应玩家的高光数据
---@param PlayerId number 玩家id
---@param SeasonId number 赛季ID
---@param TeamType number 队伍类型 1, 2, 4单双四
---@param View number 视角 1，3 第一第三人称
---@return PersonalStatisticHighestLightData[] 依次为最高击杀、最高伤害、最高助攻、最高救援、最久存活、最高治疗、最远移动距离  必须顺序不然会显示异常
function PersonalStatisticsModel:GetHighestLightDataByPlayerId(PlayerId, SeasonId, TeamType, View)
	local HighestLightDataList = self.SeasonBattleDataList[PlayerId][SeasonId][TeamType][View].HighestLightDataList
	return HighestLightDataList
end

--- 获取对应玩家的活跃累计数据
---@param PlayerId number 玩家id
---@param SeasonId number 赛季ID
---@param TeamType number 队伍类型 1, 2, 4单双四
---@param View number 视角 1，3 第一第三人称
---@return PersonalStatisticActiveCumulativeData  
function PersonalStatisticsModel:GetActiveCumulativeDataByPlayerId(PlayerId, SeasonId, TeamType, View)
	local ActiveCumulativeData = self.SeasonBattleDataList[PlayerId][SeasonId][TeamType][View].ActiveCumulativeData
	return ActiveCumulativeData
end

--- 获取对应玩家的基础数据
---@param PlayerId number 玩家id
---@param SeasonId number 赛季ID
---@param TeamType number 队伍类型 1, 2, 4单双四
---@param View number 视角 1，3 第一第三人称
---@return PersonalStatisticBaseData[] 
function PersonalStatisticsModel:GetBaseDataByPlayerId(PlayerId, SeasonId, TeamType, View)
	local BaseData = self.SeasonBattleDataList[PlayerId][SeasonId][TeamType][View].BaseDataList
	return BaseData  
end

--- 获取对应玩家的获赞次数
---@param PlayerId number 玩家id
---@param SeasonId number 赛季ID
---@param TeamType number 队伍类型 1, 2, 4单双四
---@param View number 视角 1，3 第一第三人称
---@return number  
function PersonalStatisticsModel:GetLikeCountByPlayerId(PlayerId, SeasonId, TeamType, View)
	local LikeCount = self.SeasonBattleDataList[PlayerId][SeasonId][TeamType][View].LikeCount
	return LikeCount
end

-- 检测是否有赛季数据
---@param PlayerId number 玩家id
---@param SeasonId number 赛季ID
---@param TeamType number 队伍类型 1, 2, 4单双四
---@param View number 视角 1，3 第一第三人称
---@return boolean 是否有赛季数据  
function PersonalStatisticsModel:CheckIsHasSeasonData(PlayerId, SeasonId, TeamType, View)
	local IsHasSeasonData = false
	if self.SeasonBattleDataList[PlayerId] and self.SeasonBattleDataList[PlayerId][SeasonId] and self.SeasonBattleDataList[PlayerId][SeasonId][TeamType] and self.SeasonBattleDataList[PlayerId][SeasonId][TeamType][View] 
		and self.SeasonBattleDataList[PlayerId][SeasonId][TeamType][View].HasData then
		IsHasSeasonData = true
	end
	return IsHasSeasonData
end

-- 通过模式Id获取对应的队伍类型枚举、视角枚举
---@param ModeId number 模式ID
---@return number number 队伍类型枚举、视角枚举
function PersonalStatisticsModel:GetTeamTypeAndViewByModeId(ModeId)
	local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ModeSelect_ModeEnumCfg, ModeId)
	local TeamType, View = nil, nil
	if Cfg then
		---@type MatchModel
		local MatchModel = MvcEntry:GetModel(MatchModel)
		local ModeType = Cfg[Cfg_ModeSelect_ModeEnumCfg_P.ModeType]
		local Perspective = Cfg[Cfg_ModeSelect_ModeEnumCfg_P.Perspective]
		TeamType = MatchModel:ChangeTeamTypeStringToInt(ModeType)
		View = MatchModel:ChangeViewStringToInt(Perspective)
	end
	return TeamType, View
end

-- 清空缓存的统计数据
function PersonalStatisticsModel:ClearSeasonBattleDataList()
	self.SeasonBattleDataList = {}
end

-- 计算KDA方法 严谨KDA 玩家击杀数/玩家死亡数
---@param TotKill number 总击杀
---@param TotDeath number 总死亡
function PersonalStatisticsModel:CalculateKDAValue(TotKill, TotDeath)
	local KDA = 0
	if TotKill and TotKill > 0 then
		TotDeath = (TotDeath and TotDeath > 0) and TotDeath or 1
		KDA = TotKill / TotDeath
	end
	return KDA
end
