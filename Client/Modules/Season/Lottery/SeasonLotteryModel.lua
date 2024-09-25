--[[
    赛季抽奖数据模型
]]
local super = GameEventDispatcher;
local class_name = "SeasonLotteryModel";

---@class SeasonLotteryModel : GameEventDispatcher
---@field private super GameEventDispatcher
SeasonLotteryModel = BaseClass(super, class_name);

SeasonLotteryModel.ON_POOL_OPENINFO_UPDATE = "ON_POOL_OPENINFO_UPDATE"
SeasonLotteryModel.ON_POOL_LOTTERY_INFO_UPDATE = "ON_POOL_LOTTERY_INFO_UPDATE"
SeasonLotteryModel.ON_POOL_RATE_UPDATE = "ON_POOL_RATE_UPDATE"
SeasonLotteryModel.ON_RECORD_LIST_UPDATE = "ON_RECORD_LIST_UPDATE"
SeasonLotteryModel.ON_LOTTERY_ACTION_SUC = "ON_LOTTERY_ACTION_SUC"

function SeasonLotteryModel:__init()
    self:DataInit()

    --排序过后的预览奖励列表
    self.PoolId2PreviewPrizeList = {}
end

--[[
    玩家登出时调用
]]
function SeasonLotteryModel:OnLogout(data)
    self:DataInit()
end

function SeasonLotteryModel:DataInit()
    self.OpenPoolList = {}
    self.OpenPoolListSortDirty = true
    self.PoolId2OpenInfo = {}
    self.PoolId2BaodiCount = {}
    self.PoolId2DayCount = {}
    self.PoolId2Quality2Rate = {}
    self.RocordType2RecordList = {}
    self.PoolId2RateShowStr = {}
end


--------------------协议数据处理-------------------------------------
--协议返回
function SeasonLotteryModel:PlayerGetStartLotteryRsp_Func(Msg)
    for k,v in ipairs(Msg.PrizePoolList) do
        self.PoolId2OpenInfo[v.PrizePoolId] = v
    end
    self.OpenPoolList = Msg.PrizePoolList
    self.OpenPoolListSortDirty = true
    self:DispatchType(SeasonLotteryModel.ON_POOL_OPENINFO_UPDATE)
end
function SeasonLotteryModel:PlayerLotteryInfoRsp_Func(Msg)
    -- print_r(Msg,"BaodiCount")
    self.PoolId2BaodiCount[Msg.PrizePoolId] = Msg.BaoDiOneCount
    self.PoolId2DayCount[Msg.PrizePoolId] = Msg.DayCount
    self:DispatchType(SeasonLotteryModel.ON_POOL_LOTTERY_INFO_UPDATE)
end
function SeasonLotteryModel:PlayerGetPrizePoolRateRsp_Func(Msg)
    -- print_r(Msg)
    self.PoolId2Quality2Rate[Msg.PrizePoolId] = {}
    --[[
        message ItemQualityRateNode
        {
            ITEM_QUALITY_TYPE Quality = 1;  // 物品的品质
            int32 Rate = 2;     // 每个品质的概率基数
        }
    ]]
    local RateAllCount = 0
    for k,ItemQualityRateNode in ipairs(Msg.QualityRateList) do
        RateAllCount = RateAllCount + ItemQualityRateNode.Rate
    end
    for k,ItemQualityRateNode in ipairs(Msg.QualityRateList) do
        self.PoolId2Quality2Rate[Msg.PrizePoolId][ItemQualityRateNode.Quality] = string.format("%.1f", ItemQualityRateNode.Rate*1.0/RateAllCount * 100)--math.floor(ItemQualityRateNode.Rate*1.0/RateAllCount * 100)
    end

    --TODO 计算需要概率显示字符串
    local PrizePoolConfig = G_ConfigHelper:GetSingleItemById(Cfg_PrizePoolConfig,Msg.PrizePoolId)
    local RateStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_SeasonLotteryModel_spancolorsizeoccurre")
    if string.len(PrizePoolConfig[Cfg_PrizePoolConfig_P.RateDes]) > 0 then
        RateStr = PrizePoolConfig[Cfg_PrizePoolConfig_P.RateDes]
    end
    local SepStr = "、"
    local RewardPreviewList = G_ConfigHelper:GetMultiItemsByKey(Cfg_PrizePreviewConfig,Cfg_PrizePreviewConfig_P.PoolId,Msg.PrizePoolId)--G_ConfigHelper:GetDict(Cfg_PrizePreviewConfig)
    local Quality2PrizeStr = {}
    for k,PreviewCfg in ipairs(RewardPreviewList) do
        local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,PreviewCfg[Cfg_PrizePreviewConfig_P.ItemId])
        local QualityId = CfgItem[Cfg_ItemConfig_P.Quality]

        Quality2PrizeStr[QualityId] = Quality2PrizeStr[QualityId] or ""
        Quality2PrizeStr[QualityId] = Quality2PrizeStr[QualityId] .. StringUtil.Format(CfgItem[Cfg_ItemConfig_P.Name]) .. SepStr
    end
    local PoolRateStr = ""
    local ItemQualityCfgDict = G_ConfigHelper:GetDict(Cfg_ItemQualityColorCfg)
    for i=#ItemQualityCfgDict,1,-1 do
        local QualityCfg = ItemQualityCfgDict[i]
        local QualityId = QualityCfg[Cfg_ItemQualityColorCfg_P.Quality]
        local QualityName = QualityCfg[Cfg_ItemQualityColorCfg_P.QualityName]

        local PrizeStr = Quality2PrizeStr[QualityId]
        local Rate = self:GetRateByPoolIdAndQuality(Msg.PrizePoolId,QualityId)
        if PrizeStr then
            PrizeStr = string.sub(PrizeStr,1,string.len(PrizeStr)-string.len(SepStr))
            PoolRateStr = PoolRateStr .. StringUtil.Format(RateStr,QualityCfg[Cfg_ItemQualityColorCfg_P.HexColor],Rate,PrizeStr,QualityName) .. "\n\n"
        end
    end
    self.PoolId2RateShowStr[Msg.PrizePoolId] = PoolRateStr

    self:DispatchType(SeasonLotteryModel.ON_POOL_RATE_UPDATE)
end
function SeasonLotteryModel:PlayerGetLotteryRecordRsp_Func(Msg)
    -- print_r(Msg)
    self.RocordType2RecordList[Msg.RecordType] = {}

    for k,v in ipairs(Msg.RecordList) do
        for _,PrizeDecomposNode in ipairs(v.PrizeItemList) do
            local Record  ={
                OpTime = v.OpTime,
                PrizeItemId = PrizeDecomposNode.PrizeItemId,
                PrizeItemNum = PrizeDecomposNode.PrizeItemNum,
                DecomposItemId = PrizeDecomposNode.DecomposItemId,
                DeconmposItemNum = PrizeDecomposNode.DeconmposItemNum,
            }
            table.insert(self.RocordType2RecordList[Msg.RecordType],Record)
        end
    end

    self:DispatchType(SeasonLotteryModel.ON_RECORD_LIST_UPDATE)
end
function SeasonLotteryModel:PlayerLotteryRsp_Func(Msg)
    self:DispatchType(SeasonLotteryModel.ON_LOTTERY_ACTION_SUC)
end
--//


----------------------提供数据读取-------------------------------------------
function SeasonLotteryModel:GetBaodiCountByPoolId(PoolId)
    return self.PoolId2BaodiCount[PoolId] or 0
end

function SeasonLotteryModel:GetRateByPoolIdAndQuality(PoolId,Quality)
    return self.PoolId2Quality2Rate[PoolId] and self.PoolId2Quality2Rate[PoolId][Quality] or 0
end

function SeasonLotteryModel:GetRecordListByRecordType(RecordType)
    return self.RocordType2RecordList[RecordType] or {}
end
function SeasonLotteryModel:GetPoolOpenInfoById(Id)
    return self.PoolId2OpenInfo[Id] or nil
end
function SeasonLotteryModel:GetOpenPoolList()
    if self.OpenPoolListSortDirty then
        self.OpenPoolListSortDirty = false
        --TODO 对当前打开的奖池进行排序

        if self.OpenPoolList and #self.OpenPoolList > 0 then
            table.sort(self.OpenPoolList,function(PoolA,PoolB)
                --[[
                    排序规则
                      - 有时限>无时限
                        - 新上线>老上线
                            - 早结束>晚结束
                                - 奖池ID大>奖池ID小
                ]]
                local IsLimitTimeA = PoolA.BeginTime > 0 and 1 or 0
                local IsLimitTimeB = PoolB.BeginTime > 0 and 1 or 0
                if IsLimitTimeA ~= IsLimitTimeB then
                    return (IsLimitTimeA > IsLimitTimeB)
                end
                if IsLimitTimeA == IsLimitTimeB and IsLimitTimeA == 1 then
                    --有时限排序
                    if PoolA.BeginTime ~= PoolB.BeginTime then
                        return (PoolA.BeginTime > PoolB.BeginTime)
                    end
                    if PoolA.EndTime ~= PoolB.EndTime then
                        return (PoolA.EndTime < PoolB.EndTime)
                    end
                end
                return (PoolA.PrizePoolId > PoolB.PrizePoolId)
            end)
        end
    end
    return self.OpenPoolList or {}
end

function SeasonLotteryModel:IsPoolRateInit(PoolId)
    return (self.PoolId2Quality2Rate and self.PoolId2Quality2Rate[PoolId]) and true or false
end
function SeasonLotteryModel:GetPoolRateShowStr(PoolId)
    return self.PoolId2RateShowStr[PoolId] or "None"
end
function SeasonLotteryModel:GetRecordListByRecordType(RecordType)
    return self.RocordType2RecordList[RecordType] or {}
end
function SeasonLotteryModel:GetDayCountByPoolId(PoolId)
    return self.PoolId2DayCount[PoolId] or 0
end
function SeasonLotteryModel:CheckLotteryDayCountLimit(PoolId,LotteryNum,DoTip)
    local DayCount = self.PoolId2DayCount[PoolId]
    local PrizePoolConfig = G_ConfigHelper:GetSingleItemById(Cfg_PrizePoolConfig,PoolId) 
    local LeftCount = PrizePoolConfig[Cfg_PrizePoolConfig_P.DayCountMax] - DayCount

    if LotteryNum > LeftCount then
        if DoTip then
            UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_SeasonLotteryModel_Thenumberofluckydraw"))
        end
        return false
    end
    return true
end
function SeasonLotteryModel:GetPreviewPrizeListByPoolId(PoolId)
    if not self.PoolId2PreviewPrizeList[PoolId] then
        local PreviewPrizeList = G_ConfigHelper:GetMultiItemsByKey(Cfg_PrizePreviewConfig,Cfg_PrizePreviewConfig_P.PoolId,PoolId)

        --[[
            排序规则：
            是否主奖励
                品质大小（大排前）(废弃)
                    ID（大排前）
        ]]
        local TheDepotModel = MvcEntry:GetModel(DepotModel)
        table.sort(PreviewPrizeList,function(PrizeA,PrizeB)
            local IsMainA = PrizeA[Cfg_PrizePreviewConfig_P.IsMainReward] and 1 or 0
            local IsMainB = PrizeB[Cfg_PrizePreviewConfig_P.IsMainReward] and 1 or 0
            if IsMainA ~= IsMainB then
                return (IsMainA > IsMainB)
            end
            -- local QualityA = TheDepotModel:GetQualityCfgByItemId(PrizeA[Cfg_PrizePreviewConfig_P.ItemId])
            -- local QualityB = TheDepotModel:GetQualityCfgByItemId(PrizeB[Cfg_PrizePreviewConfig_P.ItemId])
            -- if QualityA[Cfg_ItemQualityColorCfg_P.Quality] ~= QualityB[Cfg_ItemQualityColorCfg_P.Quality] then
            --     return (QualityA[Cfg_ItemQualityColorCfg_P.Quality] > QualityB[Cfg_ItemQualityColorCfg_P.Quality])
            -- end
            return PrizeA[Cfg_PrizePreviewConfig_P.PreviewPrizeId] < PrizeB[Cfg_PrizePreviewConfig_P.PreviewPrizeId]
        end)

        self.PoolId2PreviewPrizeList[PoolId] = PreviewPrizeList
    end
    return self.PoolId2PreviewPrizeList[PoolId] or {}
end
--//

return SeasonLotteryModel;