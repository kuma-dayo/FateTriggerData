--[[
    赛季段位升级界面
]]

local class_name = "SeasonRankUpgradeSettlementMdt";
SeasonRankUpgradeSettlementMdt = SeasonRankUpgradeSettlementMdt or BaseClass(GameMediator, class_name);

function SeasonRankUpgradeSettlementMdt:__init()
end

function SeasonRankUpgradeSettlementMdt:OnShow(data)
end

function SeasonRankUpgradeSettlementMdt:OnHide()
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

--[[
    Param = {
    }
]]
function M:OnShow(Param)
    self:UpdateUI()
end

function M:OnRepeatShow(Param)
    self:UpdateUI()
end

-- 刷新UI
function M:UpdateUI()
    self.DivisionSettlementData = self.HallSettlementModel:GetDivisionSettlementData() 
    if self.DivisionSettlementData then
        self:UpdateRankIcon()
        self:UpdateRankName()
        self:UpdateRankWinPoint() 
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
    self.TextBlock_CurWinPoint:SetText(self.DivisionSettlementData.WinPoint)
end

function M:OnHide()
   
end

-- 关闭界面
function M:OnClick_CloseBtn()
    MvcEntry:CloseView(self.viewId)
end


return M
