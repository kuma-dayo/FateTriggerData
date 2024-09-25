--[[
   赛季，抽奖记录  记录列表的每个Item逻辑
]] 
local class_name = "SeasonLotteryRecordItemLogic"
local SeasonLotteryRecordItemLogic = BaseClass(nil, class_name)

function SeasonLotteryRecordItemLogic:OnInit()
    self.PrizeItemHandler = UIHandler.New(self,self.View.WBP_CommonItemIcon,CommonItemIcon).ViewInstance
    self.PrizeItemAfterHandler = UIHandler.New(self,self.View.WBP_CommonItemIcon_After,CommonItemIcon).ViewInstance
end

--[[
    local Param = {
        RecordInfo
    }

    RecordInfo
    message PrizeDecomposNode
    {
        int64 PrizeItemId = 1;          // 抽奖获得的物品Id
        int32 PrizeItemNum = 2;         // 抽奖获得的物品数量
        int64 DecomposItemId = 3;       // 物品分解后的物品Id
        int32 DeconmposItemNum = 4;     // 物品分解后的总数量
    }
]]
function SeasonLotteryRecordItemLogic:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function SeasonLotteryRecordItemLogic:OnHide()
end

function SeasonLotteryRecordItemLogic:UpdateUI(Param)
    local TheDepotModel = MvcEntry:GetModel(DepotModel)
    local RecordInfo = Param.RecordInfo
    local ItemName = TheDepotModel:GetItemName(RecordInfo.PrizeItemId)
    self.View.LbItemName:SetText(ItemName)
    CommonUtil.SetTextColorFromeHex(self.View.LbItemName,TheDepotModel:GetHexColorByItemId(RecordInfo.PrizeItemId))
    self.View.LbShowType:SetText( TheDepotModel:GetItemTypeShowByItemId(RecordInfo.PrizeItemId))
    self.View.LbGetTime:SetText(TimeUtils.DateStr_FromTimeStamp(RecordInfo.OpTime))


    --更新当前Icon显示
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = RecordInfo.PrizeItemId,
        ItemNum = RecordInfo.PrizeItemNum,
        ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.TIP,
        ShowCount = true,
    }
    self.PrizeItemHandler:UpdateUI(IconParam,true)

    if RecordInfo.DecomposItemId > 0 and RecordInfo.DeconmposItemNum > 0 then
        self.View.NConvert:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        --TODO 更新分解表现
        local IconParam = {
            IconType = CommonItemIcon.ICON_TYPE.PROP,
            ItemId = RecordInfo.DecomposItemId,
            ItemNum = RecordInfo.DeconmposItemNum,
            ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.TIP,
            ShowCount = true,
        }
        self.PrizeItemAfterHandler:UpdateUI(IconParam,true)
    else
        self.View.NConvert:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end


return SeasonLotteryRecordItemLogic
