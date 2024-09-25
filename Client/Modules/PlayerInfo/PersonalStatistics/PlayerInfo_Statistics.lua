--[[
    个人信息-数据统计
]]

local class_name = "PlayerInfo_Statistics"
---@class PlayerInfo_Statistics
local PlayerInfo_Statistics = BaseClass(nil, class_name)

function PlayerInfo_Statistics:OnInit()
    self.InputFocus = true
    self.BindNodes = {

    }
    self.MsgList = {
        {Model = PersonalStatisticsModel, MsgName = PersonalStatisticsModel.ON_STATISTICS_SEASON_DATA_UPDATE_EVENT, Func = self.ON_STATISTICS_SEASON_DATA_UPDATE_EVENT},
    }
    ---@type PersonalStatisticsCtrl
    self.PersonalStatisticsCtrl = MvcEntry:GetCtrl(PersonalStatisticsCtrl)
    ---@type PersonalStatisticsModel
    self.PersonalStatisticsModel = MvcEntry:GetModel(PersonalStatisticsModel)

    -- 当前选择的赛季ID
    self.CurSelectSeasonId = nil
    -- 当前选择的模式ID
    self.CurSelectModeId = nil
    -- 当前选择的队伍类型枚举
    self.CurTeamType = nil
    -- 当前选择的视口枚举
    self.CurView = nil
    -- 玩家ID
    self.PlayerId = nil
    -- 是否自己
    self.IsSelf = false

    self.View.WBP_Common_Btn_Like.Btn_List:SetIsEnabled(false)

    self:InitSeasonDropDown()
    self:InitModeDropDown()
end

--[[
	初始化赛季数据展示
]]
function PlayerInfo_Statistics:InitSeasonDropDown()
    -- 当前选择的赛季ID
    self.CurSelectSeasonId = MvcEntry:GetModel(SeasonModel):GetCurrentSeasonId()
    if self.CurSelectSeasonId ~= -1 then
    	local SeasonConfigList = self.PersonalStatisticsModel:GetSeasonConfigList()
        local OptionList = {}
        local DefaultSelect = 1
        for Index, SeasonConfig in ipairs(SeasonConfigList) do
            OptionList[#OptionList + 1] = {
                ItemDataString = SeasonConfig.SeasonName,
                ItemIndex = Index,
                ItemID = SeasonConfig.SeasonId,
            }
            if self.CurSelectSeasonId == SeasonConfig.SeasonId then
                DefaultSelect = Index
            end
        end
        if #OptionList > 0 then
            local params = {
                OptionList = OptionList,
                DefaultSelect = DefaultSelect,
                SelectCallBack = Bind(self, self.OnSelectionSeasonChanged)
            }
            UIHandler.New(self, self.View.WBP_ComboBoxSeason, CommonComboBox, params)
        end
    end
end

--[[
	初始化模式数据展示
]]
function PlayerInfo_Statistics:InitModeDropDown()
    -- 当前选择的模式ID
    self.CurSelectModeId = nil
	local ModeConfigList = self.PersonalStatisticsModel:GetModeConfigList()
    local OptionList = {}
    local DefaultSelect = 1
    for Index, ModeConfig in ipairs(ModeConfigList) do
        OptionList[#OptionList + 1] = {
            ItemDataString = ModeConfig.ModeName,
            ItemIndex = Index,
            ItemID = ModeConfig.DefaultId,
        }
        if not self.CurSelectModeId then
            self.CurSelectModeId = ModeConfig.DefaultId
            DefaultSelect = Index
            self:UpdateTeamTypeAndViewType()
        end
    end
    if #OptionList > 0 then
        local params = {
            OptionList = OptionList,
            DefaultSelect = DefaultSelect,
            SelectCallBack = Bind(self, self.OnSelectionModeChanged)
        }
        UIHandler.New(self, self.View.WBP_ComboBoxMode, CommonComboBox, params)
    end
end

function PlayerInfo_Statistics:OnShow(TargetPlayerId)
    self.PlayerId = TargetPlayerId
    self.IsSelf = TargetPlayerId == MvcEntry:GetModel(UserModel):GetPlayerId()
    self:OnCheckSeasonDataAndUpdate()
end

-- 更新队伍类型以及视口类型
function PlayerInfo_Statistics:UpdateTeamTypeAndViewType()
    local TeamType, View = self.PersonalStatisticsModel:GetTeamTypeAndViewByModeId(self.CurSelectModeId)
    -- 当前选择的队伍类型枚举
    self.CurTeamType = TeamType
    -- 当前选择的视口枚举
    self.CurView = View
end

function PlayerInfo_Statistics:OnHide()

end

----------------事件监听回调--------------------- 
-- 个人统计数据 - 赛季数据更新事件回调
function PlayerInfo_Statistics:ON_STATISTICS_SEASON_DATA_UPDATE_EVENT(PlayerId)
    if PlayerId == self.PlayerId then
        self:UpdateUI() 
    end
end

-- 选择赛季页签回调
function PlayerInfo_Statistics:OnSelectionSeasonChanged(Index, IsInit, Data)
    if not IsInit then
        self.CurSelectSeasonId = Data.ItemID
        self:OnCheckSeasonDataAndUpdate()
    end
end

-- 检测赛季数据并刷新
function PlayerInfo_Statistics:OnCheckSeasonDataAndUpdate()
    local IsHasSeasonData = self.PersonalStatisticsModel:CheckIsHasSeasonData(self.PlayerId, self.CurSelectSeasonId, self.CurTeamType, self.CurView)
    if IsHasSeasonData then
        self:UpdateUI()
    else
        local QueryPlayerId = self.IsSelf and 0 or self.PlayerId
        -- 缺少数据就请求 数据返回后会通过事件监听回调刷新
        self.PersonalStatisticsCtrl:SendProtoSeasonBattleDataReq(self.CurSelectSeasonId, self.CurTeamType, self.CurView, QueryPlayerId)
    end
end

-- 选择模式页签回调
function PlayerInfo_Statistics:OnSelectionModeChanged(Index, IsInit, Data)
    if not IsInit then
        self.CurSelectModeId = Data.ItemID
        self:UpdateTeamTypeAndViewType()
        self:OnCheckSeasonDataAndUpdate()
    end
end

----------------界面UI刷新-------------------

-- 更新UI展示
function PlayerInfo_Statistics:UpdateUI()
    self:UpdateRankDataShow()
    self:UpdateHighestLightDataShow()
    self:UpdateActiveCumulativeDataShow()
    self:UpdateBaseDataShow()
    self:UpdateLikeCountShow()
end

-- 更新排位数据展示
function PlayerInfo_Statistics:UpdateRankDataShow()
    local RankData = self.PersonalStatisticsModel:GetRankDataByPlayerId(self.PlayerId, self.CurSelectSeasonId, self.CurTeamType, self.CurView)
    local IsHasRankData = RankData and RankData.IsHasRankData or false
    if IsHasRankData then
        self.View.WidgetSwitcher_RankInfo:SetActiveWidget(self.View.HorizontalBox_Rank)

        self.View.Text_RankName:SetText(StringUtil.Format(RankData.RankName))
        self.View.Text_WinPoint:SetText(RankData.WinPoint)

        local IsHasRankTag = (RankData and RankData.RankTagDesc ~= "") and true or false
        self.View.Text_RankDesc:SetVisibility(IsHasRankTag and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        if IsHasRankTag then
            self.View.Text_RankDesc:SetText(StringUtil.Format(RankData.RankTagDesc)) 
        end
    else
        self.View.WidgetSwitcher_RankInfo:SetActiveWidget(self.View.HorizontalBox_Empty)
    end
end

-- 更新高光表现数据展示
function PlayerInfo_Statistics:UpdateHighestLightDataShow()
    local HighestLightDataList = self.PersonalStatisticsModel:GetHighestLightDataByPlayerId(self.PlayerId, self.CurSelectSeasonId, self.CurTeamType, self.CurView)
    if HighestLightDataList then
        for Index, HighestLightData in ipairs(HighestLightDataList) do
            local Text_Highest = self.View["Text_Highest_" .. Index]
            local Text_HighestTime = self.View["Text_HighestTime_" .. Index]
            if Text_Highest and Text_HighestTime then
                Text_Highest:SetText(StringUtil.Format(HighestLightData.HighestLightDesc))
                Text_HighestTime:SetText(StringUtil.Format(HighestLightData.HighestLightTimeStr))

                self:UpdateValueOpactiy(Text_Highest, HighestLightData.HighestLightValue, 0.5)
            else
                CError("[hz] PlayerInfo_Statistics:UpdateHighestLightDataShow() Text_Highest = " .. tostring(Text_Highest and true or false) .. " Text_HighestTime = " .. tostring(Text_HighestTime and true or false))
            end
        end
    end
end

-- 更新活跃累计数据展示
function PlayerInfo_Statistics:UpdateActiveCumulativeDataShow()
    local ActiveCumulativeData = self.PersonalStatisticsModel:GetActiveCumulativeDataByPlayerId(self.PlayerId, self.CurSelectSeasonId, self.CurTeamType, self.CurView)
    if ActiveCumulativeData then
        -- 游戏时长
        self.View.Text_GameDuration:SetText(StringUtil.Format(ActiveCumulativeData.GameDuration))

        -- {0}场
        local CountDesc = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "Venue")
        -- 对战场次
        self.View.Text_BattleCount:SetText(StringUtil.Format(CountDesc, ActiveCumulativeData.BattleCount))
        -- 获胜次数
        self.View.Text_WinCount:SetText(StringUtil.Format(CountDesc, ActiveCumulativeData.WinCount))
        -- 前五次数
        self.View.Text_TopFiveCount:SetText(StringUtil.Format(CountDesc, ActiveCumulativeData.TopFiveCount))

        self:UpdateValueOpactiy(self.View.Text_GameDuration, ActiveCumulativeData.GameDurationValue, 0.3)
        self:UpdateValueOpactiy(self.View.Text_BattleCount, ActiveCumulativeData.BattleCount, 0.3)
        self:UpdateValueOpactiy(self.View.Text_WinCount, ActiveCumulativeData.WinCount, 0.3)
        self:UpdateValueOpactiy(self.View.Text_TopFiveCount, ActiveCumulativeData.TopFiveCount, 0.3)
    end
end

-- 更新基础数据展示
function PlayerInfo_Statistics:UpdateBaseDataShow()
    local BaseDataList = self.PersonalStatisticsModel:GetBaseDataByPlayerId(self.PlayerId, self.CurSelectSeasonId, self.CurTeamType, self.CurView)
    if BaseDataList then
        for Index, BaseData in ipairs(BaseDataList) do
            local BaseItem = self.View["WBP_Informatin_PersonalDate_Content_Item_" .. Index]
            if BaseItem then
                local Text_Title = BaseItem["Text_Title"]
                local Text_BaseData = BaseItem["Text_BaseData"]
                local Overlay_BaseDataRank = BaseItem["Overlay_BaseDataRank"]
                local Text_BaseDataRank = BaseItem["Text_BaseDataRank"]
                
                BaseItem:SetVisibility(BaseData.IsHide and UE.ESlateVisibility.Hidden or UE.ESlateVisibility.SelfHitTestInvisible)
                if not BaseData.IsHide then
                    if Text_Title and Text_BaseData and Overlay_BaseDataRank and Text_BaseDataRank then
                        Text_Title:SetText(StringUtil.Format(BaseData.TitleDesc))
                        Text_BaseData:SetText(StringUtil.Format(BaseData.BaseDataDesc))
                        local IsHasRankTagDesc = (BaseData.RankTagDesc and BaseData.RankTagDesc ~= "") and true or false
                        Overlay_BaseDataRank:SetVisibility(IsHasRankTagDesc and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
                        if IsHasRankTagDesc then
                            Text_BaseDataRank:SetText(StringUtil.Format(BaseData.RankTagDesc))
                        end

                        self:UpdateValueOpactiy(Text_BaseData, BaseData.BaseDataValue, 0.3)
                    else
                        CError("[hz] PlayerInfo_Statistics:UpdateHighestLightDataShow() Text_Title = " .. tostring(Text_Title and true or false) .. " Text_BaseData = " .. tostring(Text_BaseData and true or false) .. " Overlay_BaseDataRank = " .. tostring(Overlay_BaseDataRank and true or false)
                            .. " Text_BaseDataRank = " .. tostring(Text_BaseDataRank and true or false))
                    end 
                end
            end
        end
    end
end

-- 更新点赞数据展示
function PlayerInfo_Statistics:UpdateLikeCountShow()
    local LikeCount = self.PersonalStatisticsModel:GetLikeCountByPlayerId(self.PlayerId, self.CurSelectSeasonId, self.CurTeamType, self.CurView)
    self.View.WBP_Common_Btn_Like.Text_Count:SetText(tostring(LikeCount))
end

-- 更新数值显示  为0的时候需要 设置透明度
---@param Widget any
---@param Value number 数值
---@param TargetOpactiy number 数值为0时的透明度
function PlayerInfo_Statistics:UpdateValueOpactiy(Widget, Value, TargetOpactiy)
    local Opactiy = (Value and Value ~= 0) and 1 or TargetOpactiy
    if Widget then
        Widget:SetRenderOpacity(Opactiy)
    end
end


return PlayerInfo_Statistics

