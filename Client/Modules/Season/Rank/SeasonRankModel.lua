--[[
    赛季排位数据模型
]]

local super = GameEventDispatcher;
local class_name = "SeasonRankModel";

---@class SeasonRankModel : GameEventDispatcher
---@field private super GameEventDispatcher
SeasonRankModel = BaseClass(super, class_name)

-- 排位人数分布数据更新事件 携带赛季id RankPlayMapId (RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id)
SeasonRankModel.ON_DISTRIBUTION_INFO_UPDATE_EVENT = "ON_DISTRIBUTION_INFO_UPDATE_EVENT"
-- 个人排位信息数据(胜点 段位信息)更新事件 携带赛季id RankPlayMapId (RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id)
SeasonRankModel.ON_PERSONAL_DIVISION_INFO_UPDATE_EVENT = "ON_PERSONAL_DIVISION_INFO_UPDATE_EVENT"
-- 个人排位排名信息更新事件 携带赛季id RankPlayMapId (RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id)
SeasonRankModel.ON_PERSONAL_DIVISION_RANK_INFO_UPDATE_EVENT = "ON_PERSONAL_DIVISION_RANK_INFO_UPDATE_EVENT"
-- 个人排位奖励状态更新事件 携带赛季id RankPlayMapId (RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id)
SeasonRankModel.ON_DIVISION_REWARD_STATUS_UPDATE_EVENT = "ON_DIVISION_REWARD_STATUS_UPDATE_EVENT"

-- 配置枚举 对应RankConfig.xlsx里的积分类型
SeasonRankModel.Enum_RatingMode = {
	-- 不积分模式
	Not_RatingMode = 0,
	-- 排位积分模式
	RankRatingMode = 1,
	-- 匹配积分模式
	MatchRatingMode = 2,
}

-- 排位相关颜色信息
SeasonRankModel.Const_DivisionFontColorInfoList = {
	---@class DivisionFontColorInfo
	---@field BarColor string 柱状图颜色值
	---@field BarBottomColor string 柱状图底部颜色值
	---@field BarAlpha number 柱状图颜色透明度
	---@field DivisionFontColor string 段位字体颜色
	---@field DivisionLineColor string 段位下划线颜色
	{
		-- 柱状图颜色值
        BarColor = "#969696",        
        -- 柱状图底部颜色值
        BarBottomColor = "#626262",
        -- 柱状图颜色透明度
        BarAlpha = 1, 
        -- 段位字体颜色
        DivisionFontColor = "#A3A3A3",
        -- 段位下划线颜色
        DivisionLineColor = "#939393",
    },
    {
        BarColor = "#A0B0B8",
        BarBottomColor = "#4B5A60",
        BarAlpha = 1,
        DivisionFontColor = "#ABBDC0",
        DivisionLineColor = "#A0B0B8",
    },
    {
        BarColor = "#C0B07E",
        BarBottomColor = "#A8954B",
        BarAlpha = 1,
        DivisionFontColor = "#EDCD6C",
        DivisionLineColor = "#EDCD6C",
    },
    {
        BarColor = "#55CCD2",
        BarBottomColor = "#2696A5",
        BarAlpha = 1,
        DivisionFontColor = "#30E5DE",
        DivisionLineColor = "#54CAD0",
    },
    {
        BarColor = "#7490FA",
        BarBottomColor = "#4356C8",
        BarAlpha = 1,
        DivisionFontColor = "#6096E8",
        DivisionLineColor = "#6096E8",
    },
    {
        BarColor = "#BD73FF",
        BarBottomColor = "#A72DFF",
        BarAlpha = 1,
        DivisionFontColor = "#AC60E8",
        DivisionLineColor = "#BD71FF",
    },
    {
        BarColor = "#EA8C16",
        BarBottomColor = "#CE6211",
        BarAlpha = 1,
        DivisionFontColor = "#F8913E",
        DivisionLineColor = "#E98B16",
    },
    {
        BarColor = "#FF3A3A",
        BarBottomColor = "#B20404",
        BarAlpha = 1,
        DivisionFontColor = "#FF0000",
        DivisionLineColor = "#FF0000",
    },
}


-- 树状图最高高度
SeasonRankModel.Const_MaxBarChartHeight = 220
function SeasonRankModel:__init()
    self:_dataInit()
end

function SeasonRankModel:_dataInit()
	-- 赛季配置列表
	self.SeasonConfigList = {}
	-- 模式配置列表 
	self.ModeConfigList = {}
	-- 赛季排位杂项表
	self.SeasonRankParameterConfigList = {}
	-- 赛季排位规则表
	self.SeasonRankRuleConfigList = {}
	-- 赛季排位Elo表
	self.SeasonRankEloConfigList = {}

	-- 排位大段位ID列表 顺序
	self.BigDivisionIdList = {}

	-- 排位赛单ID
	self.RankPlayModeId = nil
	-- 最高段位人数
	self.HighestRankPeopleNum = nil

	-- 段位人数分布图列表 key 分别为赛季id 配置模式ID 段位唯一ID
	self.DistributionInfoList = {}
	-- 奖励状态列表 key 分别为赛季id 配置模式ID 段位唯一ID
	self.DivisionRewardIdAndStatusList = {}
	-- 排位个人信息列表 key 分别为赛季id 配置模式ID
	self.PersonalDivisionInfoList = {}
	--  排位个人排名信息列表 key 分别为赛季id 配置模式ID
	self.PersonalDivisionRankInfo = {}

	-- 当前选择的赛季ID
	self.CurSelectSeasonId = nil
	-- 当前选择的RankPlayMapId (RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id)
	self.CurSelectRankPlayMapId = nil
end

function SeasonRankModel:OnLogin(data)
	self:InitConfig()
end

function SeasonRankModel:OnLogout(data)
    SeasonRankModel.super.OnLogout(self)
    self:_dataInit()
end

-- 初始化配置
function SeasonRankModel:InitConfig()
	self.SeasonConfigList = {}
    local SeasonCfgTable = G_ConfigHelper:GetDict(Cfg_SeasonConfig)
	if SeasonCfgTable then
		for _, SeasonCfg in pairs(SeasonCfgTable) do
			---@class SeasonRankConfig
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
	local RankPlayMapListConfig = G_ConfigHelper:GetDict(Cfg_RankPlayMapListConfig)
	if RankPlayMapListConfig then
		for _, RankPlayMapCfg in pairs(RankPlayMapListConfig) do
			local DefaultId = RankPlayMapCfg[Cfg_RankPlayMapListConfig_P.DefaultId]
			local ModeName = RankPlayMapCfg[Cfg_RankPlayMapListConfig_P.ModeName]
			local PlayModeId = RankPlayMapCfg[Cfg_RankPlayMapListConfig_P.PlayModeId]
			local RatingType = RankPlayMapCfg[Cfg_RankPlayMapListConfig_P.RatingType]
			-- 类型1才是排位
			if RatingType == SeasonRankModel.Enum_RatingMode.RankRatingMode then
				---@class SeasonRankModeConfig
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
		table.sort(self.ModeConfigList, function(A, B)
			return A.DefaultId < B.DefaultId
		end)
	end

	-- 初始化赛季排位杂项表 key 为 ParameterKey  无序table
	self.SeasonRankParameterConfigList = {}
	local RankParameterConfigTable = G_ConfigHelper:GetDict(Cfg_RankParameterConfig)
	if RankParameterConfigTable then
		for _, RankParameterConfig in pairs(RankParameterConfigTable) do
			local ParamKey = RankParameterConfig[Cfg_RankParameterConfig_P.ParameterKey]
			local ParamValue = RankParameterConfig[Cfg_RankParameterConfig_P.ParameterValue]
			self.SeasonRankParameterConfigList[ParamKey] = ParamValue
		end
	end

	-- 初始化段位规则描述配置
	self.SeasonRankRuleConfigList = {}
    local RankDescConfigTable = G_ConfigHelper:GetDict(Cfg_RankDescConfig)
	if RankDescConfigTable then
		for _, RankDescConfig in pairs(RankDescConfigTable) do
			---@class SeasonRankRuleConfig
			---@field DescID number 规则Id
			---@field DescTitle string 规则标题
			---@field DescText string 规则内容
			---@field DescIcon string 规则icon图标
			local SeasonRankRuleConfig = {
				DescID = RankDescConfig[Cfg_RankDescConfig_P.DescID],
				DescTitle = RankDescConfig[Cfg_RankDescConfig_P.DescTitle],
				DescText = RankDescConfig[Cfg_RankDescConfig_P.DescText],
				DescIcon = RankDescConfig[Cfg_RankDescConfig_P.DescIcon],
			}
			self.SeasonRankRuleConfigList[#self.SeasonRankRuleConfigList + 1] = SeasonRankRuleConfig
		end
		table.sort(self.SeasonRankRuleConfigList, function(A, B)
			return A.DescID < B.DescID
		end)
	end
	
	-- 初始化赛季排位Elo表
	self.SeasonRankEloConfigList = {}
	self.BigDivisionIdList = {}
	local SeasonRankEloConfigTable = G_ConfigHelper:GetDict(Cfg_RankEloConfig)
	if SeasonRankEloConfigTable then
		for _, Config in ipairs(SeasonRankEloConfigTable) do
			-- 大段位相关信息
			local BigDivisionId = Config[Cfg_RankEloConfig_P.BigDivisionId]
			self.SeasonRankEloConfigList[BigDivisionId] = self.SeasonRankEloConfigList[BigDivisionId] or {}
			if not self.SeasonRankEloConfigList[BigDivisionId].BigDivisionInfo then
				---@class SeasonBigDivisionInfo
				---@field BigDivisionId number 大段位ID
				---@field BigDivisionName string 大段位名称
				---@field DivisionIconPath string 段位ICON路径
				---@field IsHighestDivision boolean 是否最高段位
				---@field SmallDivisionNum number 小段位的数量
				local BigDivisionInfo = {
					BigDivisionId = BigDivisionId,
					BigDivisionName = Config[Cfg_RankEloConfig_P.BigDivisionName],
					DivisionIconPath = Config[Cfg_RankEloConfig_P.DivisionIconPath],
					IsHighestDivision = Config[Cfg_RankEloConfig_P.IsHighestDivision] > 0,
					SmallDivisionNum = 0,
				}
				self.SeasonRankEloConfigList[BigDivisionId].BigDivisionInfo = BigDivisionInfo
				self.BigDivisionIdList[#self.BigDivisionIdList + 1] = BigDivisionId
			end

			self.SeasonRankEloConfigList[BigDivisionId].BigDivisionInfo.SmallDivisionNum = self.SeasonRankEloConfigList[BigDivisionId].BigDivisionInfo.SmallDivisionNum + 1

			-- 小段位信息
			local SmallDivisionId = Config[Cfg_RankEloConfig_P.SmallDivisionId]
			local DivisionRewardId = nil
			-- 是否有奖励
			local IsHasDivisionReward = Config[Cfg_RankEloConfig_P.IsHasDivisionReward] > 0
			if IsHasDivisionReward then
				DivisionRewardId = Config[Cfg_RankEloConfig_P.DivisionRewardId]
			end
			self.SeasonRankEloConfigList[BigDivisionId].SmallDivisionInfoList = self.SeasonRankEloConfigList[BigDivisionId].SmallDivisionInfoList or {}
			---@class SeasonSmallDivisionInfo
			---@field DivisionId number 唯一段位ID
			---@field SmallDivisionId number 小段位ID
			---@field SmallDivisionName string 小段位名称
			---@field DivisionHistogramMaterialPath string 段位天梯图材质路径
			---@field DivisionDeclineProtectNum number 掉段保护次数
			---@field DivisionDefaultPeopleNum number 段位人数默认配置
			---@field DivisionRewardId number|nil 奖励ID
			local SmallDivisionInfo = {
				DivisionId = Config[Cfg_RankEloConfig_P.DivisionId],
				SmallDivisionId = SmallDivisionId,
				SmallDivisionName = Config[Cfg_RankEloConfig_P.SmallDivisionName],
				DivisionHistogramMaterialPath = Config[Cfg_RankEloConfig_P.DivisionHistogramMaterialPath],
				DivisionDeclineProtectNum = Config[Cfg_RankEloConfig_P.DivisionDeclineProtectNum],
				DivisionDefaultPeopleNum = Config[Cfg_RankEloConfig_P.DivisionDefaultPeopleNum],
				DivisionRewardId = DivisionRewardId,
			}
			self.SeasonRankEloConfigList[BigDivisionId].SmallDivisionInfoList[SmallDivisionId] = SmallDivisionInfo
		end

		table.sort(self.BigDivisionIdList, function(A, B)
			return A < B
		end)
	end
end

-------- 服务器数据保存 -------
-- 段位分布信息返回
function SeasonRankModel:On_DivisionDistributionInfoRes(Msg)
	local QueryParam = Msg.QueryParam
	local SeasonId = QueryParam.SeasonId
	local RankPlayMapId = QueryParam.RankPlayMapId
	self.DistributionInfoList[SeasonId] = self.DistributionInfoList[SeasonId] or {}
	self.DistributionInfoList[SeasonId][RankPlayMapId] = {}
	-- 计算人数相关数据
	local TotalDivisionPeople = 0
	-- 最多人数是多少
	local MaxDivisionPeople = 0
	for DivisionId, People in ipairs(Msg.Distribution) do
		TotalDivisionPeople = TotalDivisionPeople + People
		MaxDivisionPeople = People > MaxDivisionPeople and People or MaxDivisionPeople
	end
	for DivisionId, DivisionPeople in ipairs(Msg.Distribution) do
		local PeopleRatio = TotalDivisionPeople > 0 and (math.round((DivisionPeople/TotalDivisionPeople)*100))/100 or 0
		---@class SeasonDistributionInfo
		---@field DivisionId number 唯一段位ID
		---@field DivisionPeople number 当前段位人数
		---@field TotalDivisionPeople number 段位总人数
		---@field PeopleRatio number 当前段位人数占比
		---@field MaxDivisionPeople number 最多的人数数量
		local DistributionInfo = {
			DivisionId = DivisionId,
			DivisionPeople = DivisionPeople,
			TotalDivisionPeople = TotalDivisionPeople,
			PeopleRatio = PeopleRatio,
			MaxDivisionPeople = MaxDivisionPeople,
		}
		self.DistributionInfoList[SeasonId][RankPlayMapId][DivisionId] = DistributionInfo
	end

	local Param = {
		SeasonId = SeasonId,
		RankPlayMapId = RankPlayMapId,
	}
	self:DispatchType(SeasonRankModel.ON_DISTRIBUTION_INFO_UPDATE_EVENT, Param)
end

-- 个人段位信息返回
function SeasonRankModel:On_PersonalDivisionInfoRes(Msg)
	local QueryParam = Msg.QueryParam
	local SeasonId = QueryParam.SeasonId
	local RankPlayMapId = QueryParam.RankPlayMapId

	self.PersonalDivisionInfoList[SeasonId] = self.PersonalDivisionInfoList[SeasonId] or {}

	local RankEloConfig = self:GetSeasonRankEloConfigByDivisionId(Msg.DivisionId)
	if not RankEloConfig then
        CError("SeasonRankModel:On_PersonalDivisionInfoRes RankEloConfig Is Nil, Msg.DivisionId = " .. tostring(Msg.DivisionId))
        return
    end
	
	local BigDivisionId = RankEloConfig[Cfg_RankEloConfig_P.BigDivisionId]
	local SmallDivisionId = RankEloConfig[Cfg_RankEloConfig_P.SmallDivisionId]
	---@class SeasonPersonalDivisionInfo
	---@field CurDivisionId number 当前所在唯一段位ID
	---@field BigDivisionId number 大段位ID
	---@field SmallDivisionId number 小段位ID
	---@field WinPoint number 胜点
	local PersonalDivisionInfo = {
		CurDivisionId = Msg.DivisionId,
		BigDivisionId = BigDivisionId,
		SmallDivisionId = SmallDivisionId,
		WinPoint = Msg.WinPoint,
	}
	self.PersonalDivisionInfoList[SeasonId][RankPlayMapId] = PersonalDivisionInfo


	-- 缓存奖励相关数据
	self.DivisionRewardIdAndStatusList[SeasonId] = self.DivisionRewardIdAndStatusList[SeasonId] or {}
	self.DivisionRewardIdAndStatusList[SeasonId][RankPlayMapId] = {}

	for _, RewardIdAndStatus in pairs(Msg.DivisionRewardIdAndStatus) do
		local DivisionId = RewardIdAndStatus.DivisionId
		self.DivisionRewardIdAndStatusList[SeasonId][RankPlayMapId][DivisionId] = RewardIdAndStatus.Status
	end
	local Param = {
		SeasonId = SeasonId,
		RankPlayMapId = RankPlayMapId,
	}
	self:DispatchType(SeasonRankModel.ON_PERSONAL_DIVISION_INFO_UPDATE_EVENT, Param)
	self:DispatchType(SeasonRankModel.ON_DIVISION_REWARD_STATUS_UPDATE_EVENT, Param)
end

-- 个人段位排名信息回复
function SeasonRankModel:On_PersonalDivisionRankInfoRes(Msg)
	local QueryParam = Msg.QueryParam
	local SeasonId = QueryParam.SeasonId
	local RankPlayMapId = QueryParam.RankPlayMapId

	self.PersonalDivisionRankInfo[SeasonId] = self.PersonalDivisionRankInfo[SeasonId] or {}

	local RankEloConfig = self:GetSeasonRankEloConfigByDivisionId(Msg.DivisionId)
	if not RankEloConfig then
        CError("SeasonRankModel:On_PersonalDivisionInfoRes RankEloConfig Is Nil")
        return
    end
	
	local BigDivisionId = RankEloConfig[Cfg_RankEloConfig_P.BigDivisionId]
	local SmallDivisionId = RankEloConfig[Cfg_RankEloConfig_P.SmallDivisionId]
	---@class SeasonPersonalDivisionRankInfo
	---@field CurDivisionId number 当前所在唯一段位ID
	---@field BigDivisionId number 大段位ID
	---@field SmallDivisionId number 小段位ID
	---@field DivisionRankRatio number 超过xx%的玩家（按照小段计算，各段位权重数值同段位天梯图，精确到小数点0位，向下取整）
	---@field DivisionRank number 超限者段位显示实时排名（分端）
	local PersonalDivisionRankInfo = {
		CurDivisionId = Msg.DivisionId,
		BigDivisionId = BigDivisionId,
		SmallDivisionId = SmallDivisionId,
		DivisionRankRatio = Msg.DivisionRankRatio,
		DivisionRank = Msg.DivisionRankRatio,
	}
	self.PersonalDivisionRankInfo[SeasonId][RankPlayMapId] = PersonalDivisionRankInfo
	local Param = {
		SeasonId = SeasonId,
		RankPlayMapId = RankPlayMapId,
	}
	self:DispatchType(SeasonRankModel.ON_PERSONAL_DIVISION_RANK_INFO_UPDATE_EVENT, Param)
end

-- 领用奖励返回
function SeasonRankModel:On_DivisionRewardRes(Msg)
	local QueryParam = Msg.QueryParam
	local SeasonId = QueryParam.SeasonId
	local RankPlayMapId = QueryParam.RankPlayMapId

	if self.DivisionRewardIdAndStatusList[SeasonId] and self.DivisionRewardIdAndStatusList[SeasonId][RankPlayMapId] then
		self.DivisionRewardIdAndStatusList[SeasonId][RankPlayMapId][Msg.RewardIdStatus.DivisionId] = Msg.RewardIdStatus.Status

		local Param = {
			SeasonId = SeasonId,
			RankPlayMapId = RankPlayMapId,
		}
		self:DispatchType(SeasonRankModel.ON_DIVISION_REWARD_STATUS_UPDATE_EVENT, Param)
	end
end

-------- 对外接口 -----------
-- 重置个人段位信息 离开界面后重置
function SeasonRankModel:ResetDivisionInfo()
	self.DistributionInfoList = {}
	self.PersonalDivisionInfoList = {}
	self.PersonalDivisionInfoList = {}
	self.PersonalDivisionRankInfo = {}
end

-- 获取赛季排位规则表
---@return SeasonRankRuleConfig[]
function SeasonRankModel:GetSeasonRankRuleConfigList()
	return self.SeasonRankRuleConfigList
end

-- 获取赛季信息配置表
---@return SeasonRankRuleConfig[]
function SeasonRankModel:GetSeasonConfigList()
	return self.SeasonConfigList
end

--- 获取模式配置列表
---@return PersonalStatisticsModeConfig[]
function SeasonRankModel:GetModeConfigList()
	return self.ModeConfigList
end

--- 通过段位唯一ID获取排位Elo配置表
function SeasonRankModel:GetSeasonRankEloConfigByDivisionId(DivisionId)
	local SeasonRankEloConfig = G_ConfigHelper:GetSingleItemById(Cfg_RankEloConfig, DivisionId)
	return SeasonRankEloConfig
end

--- 通过枚举ID获取排位RankPlayMapListConfig配置表
function SeasonRankModel:GetRankPlayMapListConfigByDefaultId(DefaultId)
	local RankPlayMapListConfig = G_ConfigHelper:GetSingleItemById(Cfg_RankPlayMapListConfig, DefaultId)
	return RankPlayMapListConfig
end

-- 通过key获取排位杂项表的配置值
---@return string|nil 杂项配置值 注意判空
function SeasonRankModel:GetSeasonRankParameterConfigByKey(ParamKey)
	local ParamValue = self.SeasonRankParameterConfigList[ParamKey]
	return ParamValue
end

-- 获取排位赛单ID
function SeasonRankModel:GetRankPlayModeId()
	if not self.RankPlayModeId then
		local PlayMapListStr = self:GetSeasonRankParameterConfigByKey("PlayMapList")
		self.RankPlayModeId = PlayMapListStr and tonumber(PlayMapListStr) or nil
	end
	return self.RankPlayModeId
end

-- 获取排位提示说明
function SeasonRankModel:GetRankTipText()
	local TipText = self:GetSeasonRankParameterConfigByKey("RankIntroduce") or ""
	return TipText
end

-- 获取最高段位人数
function SeasonRankModel:GetHighestRankPeopleNum()
	if not self.HighestRankPeopleNum then
		local RankingListNumStr = self:GetSeasonRankParameterConfigByKey("RankingListNum")
		self.HighestRankPeopleNum = RankingListNumStr and tonumber(RankingListNumStr) or 500
	end
	return self.HighestRankPeopleNum
end

-- 获取大段位ID列表
---@return number[]
function SeasonRankModel:GetBigDivisionIdList()
	return self.BigDivisionIdList
end

-- 通过大段位ID获取赛季排位配置表信息
function SeasonRankModel:GetEloConfigListByBigDivisionId(BigDivisionId)
	local SeasonRankEloConfigList = self.SeasonRankEloConfigList[BigDivisionId]
	return SeasonRankEloConfigList
end

-- 检测是否有段位分布信息数据
---@param SeasonId number 赛季ID
---@param RankPlayMapId number 配置模式ID RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id
---@return boolean
function SeasonRankModel:CheckIsHasDistributionInfoList(SeasonId, RankPlayMapId)
	local DistributionInfoList = self:GetDistributionInfoList(SeasonId, RankPlayMapId)
	local IsHasData = DistributionInfoList and true or false
	return IsHasData
end

-- 获取段位分布信息
---@param SeasonId number 赛季ID
---@param RankPlayMapId number 配置模式ID RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id
---@return SeasonDistributionInfo[] 
function SeasonRankModel:GetDistributionInfoList(SeasonId, RankPlayMapId)
	local DistributionInfoList = nil
	if self.DistributionInfoList[SeasonId] and self.DistributionInfoList[SeasonId][RankPlayMapId]then
		DistributionInfoList = self.DistributionInfoList[SeasonId][RankPlayMapId]
	end
	return DistributionInfoList
end

-- 获取奖励状态信息
---@param SeasonId number 赛季ID
---@param RankPlayMapId number 配置模式ID RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id
---@return table key为唯一段位ID value为服务器下发的奖励状态 
function SeasonRankModel:GetRewardIdAndStatusList(SeasonId, RankPlayMapId)
	local RewardIdAndStatusList = nil
	if self.DivisionRewardIdAndStatusList[SeasonId] and self.DivisionRewardIdAndStatusList[SeasonId][RankPlayMapId]then
		RewardIdAndStatusList = self.DivisionRewardIdAndStatusList[SeasonId][RankPlayMapId]
	end
	return RewardIdAndStatusList
end

-- 检测是否有个人排位信息数据
---@param SeasonId number 赛季ID
---@param RankPlayMapId number 配置模式ID RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id
---@return boolean
function SeasonRankModel:CheckIsHasPersonalDivisionInfo(SeasonId, RankPlayMapId)
	local PersonalDivisionInfo = self:GetPersonalDivisionInfo(SeasonId, RankPlayMapId)
	local IsHasData = PersonalDivisionInfo and true or false
	return IsHasData
end

-- 获取个人排位信息
---@param SeasonId number 赛季ID
---@param RankPlayMapId number 配置模式ID RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id
---@return SeasonPersonalDivisionInfo 
function SeasonRankModel:GetPersonalDivisionInfo(SeasonId, RankPlayMapId)
	local PersonalDivisionInfo = nil
	if self.PersonalDivisionInfoList[SeasonId] and self.PersonalDivisionInfoList[SeasonId][RankPlayMapId]then
		PersonalDivisionInfo = self.PersonalDivisionInfoList[SeasonId][RankPlayMapId]
	end
	return PersonalDivisionInfo
end

-- 检测是否有个人排位排名信息
---@param SeasonId number 赛季ID
---@param RankPlayMapId number 配置模式ID RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id
---@return SeasonPersonalDivisionRankInfo
function SeasonRankModel:CheckIsHasPersonalDivisionRankInfo(SeasonId, RankPlayMapId)
	local PersonalDivisionRankInfo = self:GetPersonalDivisionRankInfo(SeasonId, RankPlayMapId)
	local IsHasData = PersonalDivisionRankInfo and true or false
	return IsHasData
end

-- 获取个人排位排名信息
---@param SeasonId number 赛季ID
---@param RankPlayMapId number 配置模式ID RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id
---@return SeasonPersonalDivisionRankInfo
function SeasonRankModel:GetPersonalDivisionRankInfo(SeasonId, RankPlayMapId)
	local PersonalDivisionRankInfo = nil
	if self.PersonalDivisionRankInfo[SeasonId] and self.PersonalDivisionRankInfo[SeasonId][RankPlayMapId] then
		PersonalDivisionRankInfo = self.PersonalDivisionRankInfo[SeasonId][RankPlayMapId]
	end
	return PersonalDivisionRankInfo
end

-- 设置当前选择页签参数信息
---@param SeasonId number 赛季ID
---@param RankPlayMapId number RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id
function SeasonRankModel:SetCurSelectQueryParam(SeasonId, RankPlayMapId)
	-- 当前选择的赛季ID
	self.CurSelectSeasonId = SeasonId
	-- 当前选择的RankPlayMapId
	self.CurSelectRankPlayMapId = RankPlayMapId
end

-- 设置当前选择页签参数信息
---@return number 赛季ID 
---@return number 队伍类型 1, 2, 4单双四  
---@return number 视角 1，3 第一第三人称
function SeasonRankModel:GetCurSelectQueryParam()
	return self.CurSelectSeasonId, self.CurSelectRankPlayMapId
end

-- 检测是否需要显示实时排名
function SeasonRankModel:CheckIsRealTimeDivision(DivisionId)
	local IsRealTimeDivision = false
	local Cfg = self:GetSeasonRankEloConfigByDivisionId(DivisionId)
	if Cfg then
		-- 是否实时排名
		IsRealTimeDivision = Cfg[Cfg_RankEloConfig_P.IsRealTimeDivision] > 0
	end
	return IsRealTimeDivision
end

-- 获取该段位最大胜点 
function SeasonRankModel:GetMaxWinPointByDivisionId(DivisionId)
	local MaxWinPoint = 200
	local RankEloConfig = self:GetSeasonRankEloConfigByDivisionId(DivisionId)
	if RankEloConfig then
		local NextDivisionId = self:GetNextDivisionId(DivisionId)
		local NextRankEloConfig = self:GetSeasonRankEloConfigByDivisionId(NextDivisionId)
		if NextRankEloConfig then
			-- 下一段位的起始分 - 当前段位的起始分
			local PointRangeList = RankEloConfig[Cfg_RankEloConfig_P.DivisionPointRangeList]
			local NextPointRangeList = NextRankEloConfig[Cfg_RankEloConfig_P.DivisionPointRangeList]
			if PointRangeList and PointRangeList[1] and NextPointRangeList and NextPointRangeList[1] then
				MaxWinPoint = NextPointRangeList[1] - PointRangeList[1]
			end
		else
			-- 取不到下一个段位的情况 直接加1
			local PointRangeList = RankEloConfig[Cfg_RankEloConfig_P.DivisionPointRangeList]
			if PointRangeList and PointRangeList[1] and PointRangeList[2] then
				MaxWinPoint = PointRangeList[2] - PointRangeList[1] + 1
			end
		end
	end
	return MaxWinPoint
end

-- 获取下一个段位的ID
function SeasonRankModel:GetNextDivisionId(DivisionId)
	-- 目前配置里直接+1就可以了
	local NextDivisionId = DivisionId + 1
	return NextDivisionId
end

-- 通过段位的唯一ID获取对应的段位图标
function SeasonRankModel:GetDivisionIconPathByDivisionId(DivisionId)
	local DivisionIconPath = ""
	local Cfg = self:GetSeasonRankEloConfigByDivisionId(DivisionId)
	if Cfg then
		DivisionIconPath = Cfg[Cfg_RankEloConfig_P.DivisionIconPath]
	end
	return DivisionIconPath
end

-- 通过段位的唯一ID获取对应的段位名称  大段位名+小段位名
function SeasonRankModel:GetDivisionNameByDivisionId(DivisionId)
	local DivisionName = ""
	local Cfg = self:GetSeasonRankEloConfigByDivisionId(DivisionId)
	if Cfg and Cfg[Cfg_RankEloConfig_P.BigDivisionName] and Cfg[Cfg_RankEloConfig_P.SmallDivisionName] then
		DivisionName = Cfg[Cfg_RankEloConfig_P.BigDivisionName] .. Cfg[Cfg_RankEloConfig_P.SmallDivisionName]
	end
	return DivisionName
end

-- 获取排位模式名称 
function SeasonRankModel:GetRankModeNameByPlayModeId(PlayModeId)
	local RankModeName = ""
	local Config = self:GetRankPlayMapListConfigByDefaultId(PlayModeId)
	if Config then
		RankModeName = Config[Cfg_RankPlayMapListConfig_P.ModeName]
	end
	return RankModeName
end

--[[
	MatchSelectInfo = {
        PlayModeId         = 1,                 --玩法模式id
        Perspective        = 1,                 --视角类型
        TeamType           = 1,                 --队伍类型
        LevelId            = 2,                 --关卡id
        SceneId            = 3,                 --场景id
        ModeId             = 101                --模式id
        CrossPlatformMatch = true,              --是否跨平台匹配
        FillTeam           = true,              --是否补满队伍
        SeverId            = 4,                 --服务器id
    }
]]
-- 获取排位的匹配选择信息 用于修改匹配参数
---@param RankPlayMapId number 配置模式ID RankConfig.xlsx表格中RankPlayMapListConfig的枚举模式Id
---@return table
function SeasonRankModel:GetRankMatchSelectInfo(RankPlayMapId)
	local RankMatchSelectInfo = nil
	---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    local PlayModeId = MatchModel:GetPlayModeId()
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
	local RankPlayMapListConfig = self:GetRankPlayMapListConfigByDefaultId(RankPlayMapId)
	if RankPlayMapListConfig then
		local CurSelectPlayModeId = RankPlayMapListConfig[Cfg_RankPlayMapListConfig_P.PlayModeId]
		local TeamType = MatchModel:ChangeTeamTypeStringToInt(RankPlayMapListConfig[Cfg_RankPlayMapListConfig_P.ModeType])
		local Perspective = MatchModel:ChangeViewStringToInt(RankPlayMapListConfig[Cfg_RankPlayMapListConfig_P.Perspective])
		--如果所选模式和已选的模式是同一个，则不改变相关数据
		if PlayModeId ~= CurSelectPlayModeId then
			-- 是否允许自动补满
			local IsSelFillTeam = MatchModeSelectModel:GetPlayModeCfg_IsAllowAutoFill(CurSelectPlayModeId)
			-- 是否允许跨平台匹配
			local IsAllowCrossPlatformMatch = MatchModeSelectModel:GetPlayModeCfg_IsCrossPlayFormMatch(CurSelectPlayModeId)
			--默认设置选中的服务器，并触发后续刷新，玩法模式等
			local SeverId = MatchModel:GetSeverId()
			if not SeverId then
				---@type MatchSeverModel
				local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
				CWaring("SeasonRankModel:GetRankMatchSelectInfo Delay not got yet, choose first DsGroupId as SeverId")
				local _, severCfg = next(MatchSeverModel:GetDataList())
				SeverId = severCfg and severCfg.DsGroupId or 0
			end
			local CurLevelId = MatchModeSelectModel:GetPlayModeCfg_Extra_CurAvailableGameLevelId(CurSelectPlayModeId)
			local SceneId = MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(CurLevelId)
			local ModeId = MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(CurLevelId)
			RankMatchSelectInfo = {
				PlayModeId         = CurSelectPlayModeId,  --玩法模式id
				Perspective        = Perspective,                 --视角类型
				TeamType           = TeamType,                 --队伍类型
				LevelId            = CurLevelId,                 --关卡id
				SceneId            = SceneId,                 --场景id
				ModeId             = ModeId,                --模式id
				CrossPlatformMatch = IsAllowCrossPlatformMatch,              --是否跨平台匹配
				FillTeam           = IsSelFillTeam,              --是否补满队伍
				SeverId            = SeverId,                 --服务器id
			}
		end
	end
	return RankMatchSelectInfo
end

-- 通过模式ID判断是否排位模式
function SeasonRankModel:CheckIsRankModeByPlayModeId(PlayModeId)
	local IsRankMode = false
	local Config = self:GetRankPlayMapListConfigByDefaultId(PlayModeId)
	if Config then
		IsRankMode = Config[Cfg_RankPlayMapListConfig_P.RatingType] == SeasonRankModel.Enum_RatingMode.RankRatingMode
	end
	return IsRankMode
end

-- 通过段位唯一ID获取对应的
function SeasonRankModel:GetDivisionFontColorByDivisionId(DivisionId)
	local DivisionFontColor = "#FFFFFF"
	local Cfg = self:GetSeasonRankEloConfigByDivisionId(DivisionId)
	if Cfg and Cfg[Cfg_RankEloConfig_P.BigDivisionId] and SeasonRankModel.Const_DivisionFontColorInfoList[Cfg[Cfg_RankEloConfig_P.BigDivisionId]] then
		local BigDivisionId = Cfg[Cfg_RankEloConfig_P.BigDivisionId]
		---@type DivisionFontColorInfo
		local DivisionFontColorInfo = SeasonRankModel.Const_DivisionFontColorInfoList[Cfg[Cfg_RankEloConfig_P.BigDivisionId]]
		DivisionFontColor = DivisionFontColorInfo and DivisionFontColorInfo.DivisionFontColor or DivisionFontColor
	end
	return DivisionFontColor
end

