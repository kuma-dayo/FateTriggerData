--[[
    赛季-段位结算界面
]]

local class_name = "SeasonRankSettlementMdt";
SeasonRankSettlementMdt = SeasonRankSettlementMdt or BaseClass(GameMediator, class_name);

function SeasonRankSettlementMdt:__init()
end

function SeasonRankSettlementMdt:OnShow(data)
end

function SeasonRankSettlementMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.Button_BGClose.OnClicked,				    Func = self.OnClick_CloseBtn },
	}

    ---@type HallSettlementModel
    self.HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)

    ---@type SeasonRankModel
    self.SeasonRankModel = MvcEntry:GetModel(SeasonRankModel)

    ---@type DivisionSettlementData
    self.DivisionSettlementData = nil
end

function M:OnShow()
    self:UpdateUI()
end

function M:OnRepeatShow()
    self:UpdateUI()
end

-- 刷新UI
function M:UpdateUI()
    self.DivisionSettlementData = self.HallSettlementModel:GetDivisionSettlementData() 
    if self.DivisionSettlementData then
        self:UpdateRankIcon()
        self:UpdateRankName()
        self:UpdateRankWinPoint() 
        self:UpdateWinPointProgress()
    end
end

-- 更新排位的ICON
function M:UpdateRankIcon()
    local Img_RankIcon = self.SeasonRankModel:GetDivisionIconPathByDivisionId(self.DivisionSettlementData.NewDivisionId)
    if Img_RankIcon and Img_RankIcon ~= "" then
        CommonUtil.SetBrushFromSoftObjectPath(self.Img_RankIcon, Img_RankIcon) 
    end
end

-- 更新段位名称
function M:UpdateRankName()
    local RankEloConfig = self.SeasonRankModel:GetSeasonRankEloConfigByDivisionId(self.DivisionSettlementData.NewDivisionId)
    if RankEloConfig then
        local DivisionFontColor = self.SeasonRankModel:GetDivisionFontColorByDivisionId(self.DivisionSettlementData.NewDivisionId)
        CommonUtil.SetTextColorFromeHex(self.TextBlock_BigRank, DivisionFontColor)
        self.TextBlock_BigRank:SetText(StringUtil.Format(RankEloConfig[Cfg_RankEloConfig_P.BigDivisionName]))
        self.TextBlock_SmallRank:SetText(StringUtil.Format(RankEloConfig[Cfg_RankEloConfig_P.SmallDivisionName])) 
    end
end

-- 更新排位的胜点信息
function M:UpdateRankWinPoint()
    -- 根据胜点加减 更改颜色
    local IsWin = self.DivisionSettlementData.DeltaWinPoint >= 0
    local ChangeColor = IsWin and "#39E8B9FF" or "#FA090C"
    local WinPointColor = IsWin and "#1B2024" or "#F5EFDF"
    CommonUtil.SetTextColorFromeHex(self.TextBlock_WinPointWord, WinPointColor)
    CommonUtil.SetImageColorFromHex(self.Img_WinPointBg, ChangeColor)
    CommonUtil.SetTextColorFromeHex(self.TextBlock_DeltaWinPoint, ChangeColor)
    CommonUtil.SetTextColorFromeHex(self.TextBlock_DeltaRankPoint, ChangeColor)
    CommonUtil.SetTextColorFromeHex(self.TextBlock_DeltaScorePoint, ChangeColor)
    
    self.TextBlock_CurWinPoint:SetText(self.DivisionSettlementData.WinPoint)
    self.TextBlock_CurRank:SetText(self.DivisionSettlementData.TeamRank)
    self.TextBlock_TotalRank:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_6"),self.DivisionSettlementData.TeamCount))
    self.TextBlock_Score:SetText(self.DivisionSettlementData.GradeName)

    local SymbolParam = IsWin and G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_9") or G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam")
    self.TextBlock_DeltaWinPoint:SetText(StringUtil.Format(SymbolParam, self.DivisionSettlementData.DeltaWinPoint))
    self.TextBlock_DeltaRankPoint:SetText(StringUtil.Format(SymbolParam, self.DivisionSettlementData.DeltaRankRating))
    self.TextBlock_DeltaScorePoint:SetText(StringUtil.Format(SymbolParam, self.DivisionSettlementData.PerformanceRating))
end

-- 更新胜点进度条
function M:UpdateWinPointProgress()
    local RankEloConfig = self.SeasonRankModel:GetSeasonRankEloConfigByDivisionId(self.DivisionSettlementData.NewDivisionId)
    if RankEloConfig then
        local Line1_Length = 1
        local Line2_Length = 0
        local IsWin = self.DivisionSettlementData.DeltaWinPoint > 0
        -- 实时排名的情况 进度条直接为满
        local IsRealTimeDivision = self.SeasonRankModel:CheckIsRealTimeDivision(self.DivisionSettlementData.NewDivisionId)
        if not IsRealTimeDivision then 
            local MaxWinPoint = self.SeasonRankModel:GetMaxWinPointByDivisionId(self.DivisionSettlementData.NewDivisionId)
            -- 胜利的是展示之前的胜点，失败是展示当前胜点
            local Line1_Point = IsWin and (self.DivisionSettlementData.WinPoint - self.DivisionSettlementData.DeltaWinPoint) or self.DivisionSettlementData.WinPoint
            Line1_Point = Line1_Point > 0 and Line1_Point or 0
            local DeltaWinPoint = math.abs(self.DivisionSettlementData.DeltaWinPoint)
            Line1_Length = math.floor((Line1_Point/MaxWinPoint)*1000)/1000
            Line2_Length = math.floor((DeltaWinPoint/MaxWinPoint)*1000)/1000
        end
        local ImageBarMaterial = self.Img_Progress:GetDynamicMaterial()
        if ImageBarMaterial then
            ImageBarMaterial:SetScalarParameterValue("Line1_Length", Line1_Length)
            ImageBarMaterial:SetScalarParameterValue("Line2_Length", Line2_Length)

            local ColorFromHex = IsWin and "#F5EFDF" or "#FA090C"
            local ShowColor = UE.UGFUnluaHelper.FLinearColorFromHex(ColorFromHex)
            ShowColor.A = 0.8
            ImageBarMaterial:SetVectorParameterValue("Line2_Color",ShowColor)
        end 
    end
end

function M:OnHide()
   
end

-- 关闭界面
function M:OnClick_CloseBtn()
    MvcEntry:CloseView(self.viewId)
end


return M
