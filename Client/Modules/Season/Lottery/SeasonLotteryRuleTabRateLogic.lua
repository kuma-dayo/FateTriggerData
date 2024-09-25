--[[
   赛季，抽奖规则  Tab分页--概率 子逻辑
]] 
local class_name = "SeasonLotteryRuleTabRateLogic"
local SeasonLotteryRuleTabRateLogic = BaseClass(nil, class_name)

function SeasonLotteryRuleTabRateLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    self.MsgList = {
        {Model = SeasonLotteryModel, MsgName = SeasonLotteryModel.ON_POOL_RATE_UPDATE,Func = Bind(self,self.ON_POOL_RATE_UPDATE_Func) },
    }
end

--[[
    Param = {
        PrizePoolId
    }
]]
function SeasonLotteryRuleTabRateLogic:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function SeasonLotteryRuleTabRateLogic:OnHide()
end

function SeasonLotteryRuleTabRateLogic:UpdateUI(Param)
    self.PrizePoolId = Param.PrizePoolId
    -- local PrizePoolConfig = G_ConfigHelper:GetSingleItemById(Cfg_PrizePoolConfig,self.PrizePoolId)

    self:UpdateRateShow()
end
function SeasonLotteryRuleTabRateLogic:UpdateRateShow()
    local TheSeasonLotteryModel = MvcEntry:GetModel(SeasonLotteryModel)
    if TheSeasonLotteryModel:IsPoolRateInit(self.PrizePoolId) then
        self.View.LbRichDes:SetText(TheSeasonLotteryModel:GetPoolRateShowStr(self.PrizePoolId))
    else
        MvcEntry:GetCtrl(SeasonCtrl):SendProto_PlayerGetPrizePoolRateReq(self.PrizePoolId)
    end
end

function SeasonLotteryRuleTabRateLogic:ON_POOL_RATE_UPDATE_Func()
    self:UpdateRateShow()
end

return SeasonLotteryRuleTabRateLogic
