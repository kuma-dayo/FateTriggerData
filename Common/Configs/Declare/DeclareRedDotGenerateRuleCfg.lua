-- RedDot.xlsx
Cfg_RedDotGenerateRuleCfg = "RedDotGenerateRuleCfg"
G_CfgName2MainKey = G_CfgName2MainKey or {}
G_CfgName2MainKey[Cfg_RedDotGenerateRuleCfg] = "RedDotGenerateId"
Cfg_RedDotGenerateRuleCfg_P_MainKey = "RedDotGenerateId"
Cfg_RedDotGenerateRuleCfg_P = {
    RedDotGenerateId = "RedDotGenerateId",
    RedDotGenerateRuleApplyModule = "RedDotGenerateRuleApplyModule",
    RedDotGenerateRuleApplyItemMainType = "RedDotGenerateRuleApplyItemMainType",
    RedDotGenerateRuleApplyItemSubType = "RedDotGenerateRuleApplyItemSubType",
    RedDotGenerateRulePreStr = "RedDotGenerateRulePreStr"
}

local Cfg_RedDotGenerateRuleCfg_Custom = {
    UseUds = true
}
G_CfgName2Custom = G_CfgName2Custom or {}
G_CfgName2Custom[Cfg_RedDotGenerateRuleCfg] = Cfg_RedDotGenerateRuleCfg_Custom
