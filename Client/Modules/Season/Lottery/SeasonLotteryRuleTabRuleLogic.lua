--[[
   赛季，抽奖规则  Tab分页--规则 子逻辑
]] 
local class_name = "SeasonLotteryRuleTabRuleLogic"
local SeasonLotteryRuleTabRuleLogic = BaseClass(nil, class_name)

function SeasonLotteryRuleTabRuleLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
end

--[[
    Param = {
        PrizePoolId
    }
]]
function SeasonLotteryRuleTabRuleLogic:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function SeasonLotteryRuleTabRuleLogic:OnHide()
end

function SeasonLotteryRuleTabRuleLogic:UpdateUI(Param)
    local PrizePoolId = Param.PrizePoolId
    local PrizePoolConfig = G_ConfigHelper:GetSingleItemById(Cfg_PrizePoolConfig,PrizePoolId)

    self.View.LbRichDes:SetText(PrizePoolConfig[Cfg_PrizePoolConfig_P.RuleDes])
end

return SeasonLotteryRuleTabRuleLogic
