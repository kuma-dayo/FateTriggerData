--[[
    赛季 - 切页 - 排位
]]

local class_name = "SeasonTabRank"
local SeasonTabRank = BaseClass(nil, class_name)


function SeasonTabRank:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true

    self.MsgList = {
        {Model = SeasonRankModel, MsgName = SeasonRankModel.ON_DISTRIBUTION_INFO_UPDATE_EVENT,	Func = self.OnUpdateSeasonRankDataCallBack },
        {Model = SeasonRankModel, MsgName = SeasonRankModel.ON_PERSONAL_DIVISION_INFO_UPDATE_EVENT,	Func = self.OnUpdateSeasonRankDataCallBack },
        {Model = SeasonRankModel, MsgName = SeasonRankModel.ON_PERSONAL_DIVISION_RANK_INFO_UPDATE_EVENT, Func = self.OnUpdateSeasonRankDataCallBack },
        {Model = SeasonRankModel, MsgName = SeasonRankModel.ON_DIVISION_REWARD_STATUS_UPDATE_EVENT,	Func = self.OnUpdateSeasonRankDataCallBack },
	}
    self.BindNodes = {
		{ UDelegate = self.View.WBP_CommonBtn_RankTip.GUIButton_Main.OnClicked,	Func = Bind(self,self.OnBtnRankTipClick) },
    }

    UIHandler.New(self,self.View.WBP_CommonBtn_JumpRank, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnSpaceClicked),
        CommonTipsID = CommonConst.CT_SPACE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "JumpRank")),
        ActionMappingKey = ActionMappings.SpaceBar
    })

    UIHandler.New(self,self.View.CommonBtnTips_ESC, WCommonBtnTips, 
    {
        OnItemClick = Bind(self,self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_HallTabSeason_return")),
        ActionMappingKey = ActionMappings.Escape
    })

    ---@type SeasonRankCtrl
    self.SeasonRankCtrl = MvcEntry:GetCtrl(SeasonRankCtrl)
    ---@type SeasonRankModel
    self.SeasonRankModel = MvcEntry:GetModel(SeasonRankModel)
    -- 当前选择的赛季ID
    self.CurSelectSeasonId = nil
    -- 当前选择的枚举ID
    self.CurSelectRankPlayMapId = nil
    -- 排位信息item列表
    self.RankItemList = {}
    -- 个人排位信息
    ---@type SeasonPersonalDivisionInfo
    self.PersonalDivisionInfo = nil

    -- 段位分布信息列表 key为唯一段位ID value为段位分布信息列表
    ---@type SeasonDistributionInfo[]
    self.DistributionInfoList = nil

    -- 奖励状态列表 key为唯一段位ID value为服务器下发的奖励状态 
    self.RewardIdAndStatusList = nil

    ---@type SeasonPersonalDivisionRankInfo
    self.PersonalDivisionRankInfo = nil

    self.View.WBP_Season_Rank_PopTips:SetVisibility(UE.ESlateVisibility.Collapsed)
end


--[[
    Param = {
    }
]]
function SeasonTabRank:OnShow(Param)
    self:InitUI()
    self:OnCheckSeasonRankData(true)
end

function SeasonTabRank:OnManualShow(Param)
    self:InitUI()
    self:OnCheckSeasonRankData(true)
end

function SeasonTabRank:OnManualHide()
    self.SeasonRankModel:ResetDivisionInfo()
end

function SeasonTabRank:OnHide()
    self.SeasonRankModel:ResetDivisionInfo()
    self:ClearPopTimer()
end

function SeasonTabRank:InitUI()
    self:InitSeasonDropDown()
    self:InitModeDropDown()
    self:InitRankItem()
    self:InitRankTip()
end

--[[
	初始化赛季下拉框展示
]]
function SeasonTabRank:InitSeasonDropDown()
    -- 当前选择的赛季ID
    self.CurSelectSeasonId = MvcEntry:GetModel(SeasonModel):GetCurrentSeasonId()
    if self.CurSelectSeasonId ~= -1 then
    	local SeasonConfigList = self.SeasonRankModel:GetSeasonConfigList()
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
        local params = {
            OptionList = OptionList,
            DefaultSelect = DefaultSelect,
            SelectCallBack = Bind(self, self.OnSelectionSeasonChanged)
        }
        UIHandler.New(self, self.View.WBP_ComboBoxSeason, CommonComboBox, params)
    end
end

--[[
    初始化模式下拉框展示
]]
function SeasonTabRank:InitModeDropDown()
    -- 当前选择的模式ID
    self.CurSelectRankPlayMapId = nil
    local ModeConfigList = self.SeasonRankModel:GetModeConfigList()
    local OptionList = {}
    local DefaultSelect = 1
    for Index, ModeConfig in ipairs(ModeConfigList) do
        OptionList[#OptionList + 1] = {
            ItemDataString = ModeConfig.ModeName,
            ItemIndex = Index,
            ItemID = ModeConfig.DefaultId,
        }
        if not self.CurSelectRankPlayMapId then
            self.CurSelectRankPlayMapId = ModeConfig.DefaultId
            DefaultSelect = Index
            self:OnSaveSelectQueryParam()
        end
    end
    local params = {
        OptionList = OptionList,
        DefaultSelect = DefaultSelect,
        SelectCallBack = Bind(self, self.OnSelectionModeChanged)
    }
    UIHandler.New(self, self.View.WBP_ComboBoxMode, CommonComboBox, params)
end

-- 初始化段位信息
function SeasonTabRank:InitRankItem()
    for _, Item in pairs(self.RankItemList) do
        if Item and Item.View then
            Item.View:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    local BigDivisionIdList = self.SeasonRankModel:GetBigDivisionIdList()
    for Index, BigDivisionId in ipairs(BigDivisionIdList) do
        local Item = self.RankItemList[Index]
        local ConfigData = self.SeasonRankModel:GetEloConfigListByBigDivisionId(BigDivisionId)
        if ConfigData then
            local Param = {
                -- 大段位相关配置信息 
                BigDivisionInfo = ConfigData.BigDivisionInfo,
                -- 小段位相关配置信息
                SmallDivisionInfoList = ConfigData.SmallDivisionInfoList,
            }
            if not (Item and CommonUtil.IsValid(Item.View)) then
                local RankItem = self.View["WBP_Season_Rank_Item_" .. Index]
                if RankItem then
                    Item = UIHandler.New(self,RankItem,require("Client.Modules.Season.Rank.SeasonRankItemLogic")).ViewInstance
                    self.RankItemList[BigDivisionId] = Item
                end
            end
            Item.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            Item:OnShow(Param)  
        else
            CError("SeasonTabRank:InitRankItem ConfigData Is Nil")
        end
    end
end

-- 选择赛季页签回调
function SeasonTabRank:OnSelectionSeasonChanged(Index, IsInit, Data)
    if not IsInit then
        self.CurSelectSeasonId = Data.ItemID
        self:OnSaveSelectQueryParam()
        self:OnCheckSeasonRankData(true)
    end
end

-- 更新排位提示文本
function SeasonTabRank:InitRankTip()
    local TipText = self.SeasonRankModel:GetRankTipText()
    self.View.Text_RankTip:SetText(StringUtil.Format(TipText))
end

-- 服务器请求数据返回
function SeasonTabRank:OnUpdateSeasonRankDataCallBack(Param)
    if Param and Param.SeasonId == self.CurSelectSeasonId and Param.RankPlayMapId == self.CurSelectRankPlayMapId then
        self:OnCheckSeasonRankData(false)
    end
end

-- 检测赛季排位数据并刷新
function SeasonTabRank:OnCheckSeasonRankData(IsUpdateData)
    -- 检测是否排位分布信息数据（人数分布信息 以及奖励信息） 没有就请求 数据返回后刷新界面
    local IsHasDistributionInfo = self.SeasonRankModel:CheckIsHasDistributionInfoList(self.CurSelectSeasonId, self.CurSelectRankPlayMapId)
    -- 检测是否有个人排位信息数据 没有就请求 数据返回后刷新界面
    local IsHasPersonalDivisionInfo = self.SeasonRankModel:CheckIsHasPersonalDivisionInfo(self.CurSelectSeasonId, self.CurSelectRankPlayMapId)
    -- 检测是否有段位排名信息 没有就请求 数据返回后刷新界面
    local IsHasPersonalDivisionRankInfo = self.SeasonRankModel:CheckIsHasPersonalDivisionRankInfo(self.CurSelectSeasonId, self.CurSelectRankPlayMapId)
    if IsHasDistributionInfo and IsHasPersonalDivisionInfo and IsHasPersonalDivisionRankInfo then
        self:UpdateUI()
    elseif IsUpdateData then
        if not IsHasDistributionInfo then
            self.SeasonRankCtrl:SendProto_DivisionDistributionInfoReq(self.CurSelectSeasonId, self.CurSelectRankPlayMapId)
        end
        if not IsHasPersonalDivisionInfo then
            self.SeasonRankCtrl:SendProto_PersonalDivisionInfoReq(self.CurSelectSeasonId, self.CurSelectRankPlayMapId)
        end
        if not IsHasPersonalDivisionRankInfo then
            self.SeasonRankCtrl:SendProto_PersonalDivisionRankInfoReq(self.CurSelectSeasonId, self.CurSelectRankPlayMapId)
        end
    end
end

-- 选择模式页签回调
function SeasonTabRank:OnSelectionModeChanged(Index, IsInit, Data)
    if not IsInit then
        self.CurSelectRankPlayMapId = Data.ItemID
        self:OnSaveSelectQueryParam()
        self:OnCheckSeasonRankData(true)
    end
end

-- 保存当前选中页签结果
function SeasonTabRank:OnSaveSelectQueryParam()
    self.SeasonRankModel:SetCurSelectQueryParam(self.CurSelectSeasonId, self.CurSelectRankPlayMapId)
end

function SeasonTabRank:UpdateUI()
    self.DistributionInfoList = self.SeasonRankModel:GetDistributionInfoList(self.CurSelectSeasonId, self.CurSelectRankPlayMapId)
    self.PersonalDivisionInfo = self.SeasonRankModel:GetPersonalDivisionInfo(self.CurSelectSeasonId, self.CurSelectRankPlayMapId)
    self.RewardIdAndStatusList = self.SeasonRankModel:GetRewardIdAndStatusList(self.CurSelectSeasonId, self.CurSelectRankPlayMapId)
    self.PersonalDivisionRankInfo = self.SeasonRankModel:GetPersonalDivisionRankInfo(self.CurSelectSeasonId, self.CurSelectRankPlayMapId)
    if self.DistributionInfoList and self.PersonalDivisionInfo and self.RewardIdAndStatusList and self.PersonalDivisionRankInfo then
        self:UpdateItemShow()
        self:UpdateRankInfoShow() 
    end
end

-- 更新UI  依赖服务器数据刷新
function SeasonTabRank:UpdateItemShow()
    for BigDivisionId, Item in pairs(self.RankItemList) do
        if Item and Item.View and Item.View:GetVisibility() == UE.ESlateVisibility.SelfHitTestInvisible then
            Item:UpdateUI(self.DistributionInfoList, self.PersonalDivisionInfo, self.RewardIdAndStatusList)
        end
    end
end

-- 更新排位数据展示
function SeasonTabRank:UpdateRankInfoShow()
    local RankItem = self.RankItemList[self.PersonalDivisionRankInfo.BigDivisionId]
    if self.PersonalDivisionInfo and self.PersonalDivisionRankInfo and RankItem then
        self.View.WBP_Season_Rank_PopTips:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        -- 延迟一帧
        self:ClearPopTimer()
        self.PopTimer = Timer.InsertTimer(-1,function ()
            if not CommonUtil.IsValid(self.View.WBP_Season_Rank_PopTips) then
                return
            end
            local ImageBarScreenPos, ImageSize = RankItem:GetCurRankImageBarScreenPos(self.PersonalDivisionRankInfo.CurDivisionId)
            local PopTipsSize = self.View.WBP_Season_Rank_PopTips.Slot:GetSize()
            local OffsetY = 10
            local OffsetHeight = PopTipsSize.Y
            -- 转换成局部位置 (0,0)描点位置
            local WidgetLocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(self.View:GetCachedGeometry(), ImageBarScreenPos) 
            WidgetLocalPos.X = WidgetLocalPos.X + ImageSize.X / 2 
            WidgetLocalPos.Y = WidgetLocalPos.Y - OffsetHeight
            self.View.WBP_Season_Rank_PopTips.Slot:SetPosition(WidgetLocalPos)
            -- 是否显示实时排名
            local IsRealTimeDivision = self.SeasonRankModel:CheckIsRealTimeDivision(self.PersonalDivisionInfo.CurDivisionId)
            local DescText = IsRealTimeDivision and G_ConfigHelper:GetStrFromOutgameStaticST("SD_Season","RealTimeRankDescription") or G_ConfigHelper:GetStrFromOutgameStaticST("SD_Season","BeyondRankDescription")
            local RankDesc = IsRealTimeDivision and self.PersonalDivisionRankInfo.DivisionRank or self.PersonalDivisionRankInfo.DivisionRankRatio
            local TipText = StringUtil.Format(DescText, RankDesc)
            self.View.WBP_Season_Rank_PopTips.RichTextBlock_TextTips:SetText(TipText)
        end)
    end
end

function SeasonTabRank:ClearPopTimer()
    if self.PopTimer then
        Timer.RemoveTimer(self.PopTimer)
    end
    self.PopTimer = nil
end

-- 段位提示按钮点击
function SeasonTabRank:OnBtnRankTipClick()
    MvcEntry:OpenView(ViewConst.SeasonRankRule)
end

-- 空格按键
function SeasonTabRank:OnSpaceClicked()
    CommonUtil.SwitchHallTab(CommonConst.HL_PLAY)
    ---@type MatchModel
    local MatchModel = MvcEntry:GetModel(MatchModel)
    --匹配中不允许更改模式
    if not MatchModel:IsMatching() then
        ---@type TeamModel
        local TeamModel = MvcEntry:GetModel(TeamModel)
        local IsInTeam = TeamModel:IsSelfInTeam() 
        local IsSelfTeamCaptain = TeamModel:IsSelfTeamCaptain(false)
        if not IsInTeam or IsSelfTeamCaptain then
            -- 单人&队长 才允许更改
            local RankMatchSelectInfo = self.SeasonRankModel:GetRankMatchSelectInfo(self.CurSelectRankPlayMapId)
            if RankMatchSelectInfo then
                ---@type MatchCtrl
                local MatchCtrl = MvcEntry:GetCtrl(MatchCtrl)
                MatchCtrl:ChangeMatchModeInfo(RankMatchSelectInfo)
            end
        end
    end
end

-- ESC按键
function SeasonTabRank:OnEscClicked()
    --TODO 返回游戏大厅
    CommonUtil.SwitchHallTab(CommonConst.HL_PLAY)
end

return SeasonTabRank
