--[[
   赛季等级面板逻辑
]] 
local class_name = "SeasonBpLevelPanelLogic"
local SeasonBpLevelPanelLogic = BaseClass(nil, class_name)

function SeasonBpLevelPanelLogic:OnInit()
    self.TheModel = MvcEntry:GetModel(SeasonBpModel)

    self.MsgList = {
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_LEVEL_UPDATE, Func = self.UpdateUI },
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_EXP_UPDATE, Func = self.UpdateUI },
    }
end

function SeasonBpLevelPanelLogic:OnShow(Param)
    self:UpdateUI()
end

function SeasonBpLevelPanelLogic:OnHide()
end

function SeasonBpLevelPanelLogic:UpdateUI()
    local PassStatus = self.TheModel:GetPassStatus()
    if not PassStatus then
        return
    end
    

    local CfgBpReward = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpRewardCfg,{Cfg_SeasonBpRewardCfg_P.Level,Cfg_SeasonBpRewardCfg_P.SeasonBpId},{PassStatus.Level,PassStatus.SeasonBpId})

    self.View.LbLevel:SetText(tostring(PassStatus.Level))
    self.View.LbExp:SetText(tostring(PassStatus.Exp))
    if not CfgBpReward then
        CWaring(StringUtil.FormatSimple("SeasonBpLevelPanelLogic:UpdateUI CfgBpReward is nil, Level is{0}, SeasonBpId is{1}"), PassStatus.Level, PassStatus.SeasonBpId)
        return
    end
    self.View.LbExpMax:SetText(tostring(CfgBpReward[Cfg_SeasonBpRewardCfg_P.NeedExp]))

    local Rate = PassStatus.Exp/CfgBpReward[Cfg_SeasonBpRewardCfg_P.NeedExp]

    self.View.ProgressLv:SetPercent(Rate)
end


return SeasonBpLevelPanelLogic
