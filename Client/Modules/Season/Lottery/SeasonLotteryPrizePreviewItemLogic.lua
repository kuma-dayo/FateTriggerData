--[[
   赛季，抽奖奖励预览奖励每个实际Item 解耦逻辑
]] local class_name = "SeasonLotteryPrizePreviewItemLogic"
local SeasonLotteryPrizePreviewItemLogic = BaseClass(nil, class_name)

function SeasonLotteryPrizePreviewItemLogic:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.GUIButton.OnClicked,				Func = Bind(self,self.OnButtonClick) },
    }
end

--[[
    local Param = {
        PrizeId = PrizeId,
        PreviewItemType = PreviewItemType,
        PrizeClickCallback = Bind(self,self.OnPreviewPrizeClick,PrizeInfo[Cfg_PrizePreviewConfig_P.PreviewPrizeId]),
    }
]]
function SeasonLotteryPrizePreviewItemLogic:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function SeasonLotteryPrizePreviewItemLogic:OnHide()
end

function SeasonLotteryPrizePreviewItemLogic:UpdateUI(Param)
    if not Param then
        CError("SeasonLotteryPrizePreviewItemLogic:UpdateUI Param nil", true)
        return
    end
    self.Param = Param
    self.PrizeId = self.Param.PrizeId

    local PrizePreviewConfig = G_ConfigHelper:GetSingleItemById(Cfg_PrizePreviewConfig,self.PrizeId)
    --TODO 更新图片显示
    CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageGoods,PrizePreviewConfig[Cfg_PrizePreviewConfig_P.PreviewIcon])

    --TODO 暂时不制作限时功能，将其隐藏
    -- self.View.HorizontalBoxDate:SetVisibility(UE.ESlateVisibility.Collapsed)

    local ItemId = PrizePreviewConfig[Cfg_PrizePreviewConfig_P.ItemId]
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
    --TODO 更新颜色
    if self.View["Quality_Behind"] then
        CommonUtil.SetImageColorFromQuality(self.View["Quality_Behind"],CfgItem[Cfg_ItemConfig_P.Quality])
    end
    if self.View["Quality_Front"] then
        CommonUtil.SetImageColorFromQuality(self.View["Quality_Front"],CfgItem[Cfg_ItemConfig_P.Quality])
    end

    local TheDepotModel = MvcEntry:GetModel(DepotModel)
    self.View.LbName:SetText(TheDepotModel:GetItemName(ItemId))
    -- CommonUtil.SetTextColorFromeHex(self.View.LbName, TheDepotModel:GetHexColorByItemId(ItemId))

    local ItemCount = TheDepotModel:GetItemCountByItemId(ItemId)

    self.View.WBP_Lottery_LeftTopMark:SetVisibility(ItemCount > 0 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function SeasonLotteryPrizePreviewItemLogic:Select()
    self.View.Select:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end
function SeasonLotteryPrizePreviewItemLogic:UnSelect()
    self.View.Select:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function SeasonLotteryPrizePreviewItemLogic:OnButtonClick()
    if self.Param.PrizeClickCallback then
        self.Param.PrizeClickCallback(self.PrizeId)
    end
end

function SeasonLotteryPrizePreviewItemLogic:ShowUI()
    self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function SeasonLotteryPrizePreviewItemLogic:HideUI()
    self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return SeasonLotteryPrizePreviewItemLogic
