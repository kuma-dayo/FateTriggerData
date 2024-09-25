--[[
   赛季通行证特殊item展示逻辑
]] 
local class_name = "SeasonBpSpecialGoodItemLogic"
local SeasonBpSpecialGoodItemLogic = BaseClass(UIHandlerViewBase, class_name)
---@class SeasonBpSpecialGoodItemLogicParam
---@field SeasonBpId number 赛季id
---@field Lv number 配置等级

function SeasonBpSpecialGoodItemLogic:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.ItemBtnShow.OnClicked, Func = Bind(self, self.OnItemBtnClick)},
    }
    self.MsgList = 
    {
        {Model = SeasonBpModel, MsgName = SeasonBpModel.ON_SEASON_BP_MAIN_SELECT_ITEM_SHOW, Func = self.UnSelect },
	}
    self.IsSelect = false
end

function SeasonBpSpecialGoodItemLogic:OnShow(Param)
    if not Param then
        return
    end
    self:UpdateUI(Param)
end

function SeasonBpSpecialGoodItemLogic:OnHide()
end

function SeasonBpSpecialGoodItemLogic:UpdateUI(Param)
    if not Param then
        return
    end
    local CfgBpReward = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpRewardCfg, {Cfg_SeasonBpRewardCfg_P.Level, Cfg_SeasonBpRewardCfg_P.SeasonBpId}, {Param.Lv, Param.SeasonBpId})
    if not CfgBpReward then
        CWaring("CfgBpReward is nil,please check")
        return
    end
    self.Param = Param
    self.View.Good:SetVisibility(UE.ESlateVisibility.Collapsed)
    if string.len(CfgBpReward[Cfg_SeasonBpRewardCfg_P.SpecialItemTinyIconPath]) > 0 then
        self.View.Good:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.View.Good, CfgBpReward[Cfg_SeasonBpRewardCfg_P.SpecialItemTinyIconPath])
    end
    if string.len(CfgBpReward[Cfg_SeasonBpRewardCfg_P.SpecialItemShowLvStr]) > 0 then
        self.View.LbItemShow:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "Level"), CfgBpReward[Cfg_SeasonBpRewardCfg_P.SpecialItemShowLvStr]))
    end
end

function SeasonBpSpecialGoodItemLogic:Select()
    self.IsSelect = true
    if self.View.VXE_Btn_Select then
        self.View:VXE_Btn_Select()
    end
end
function SeasonBpSpecialGoodItemLogic:UnSelect()
    if self.View.VXE_Btn_UnSelect then
        self.View:VXE_Btn_UnSelect()
    end
    self.IsSelect = false
end

function SeasonBpSpecialGoodItemLogic:OnItemBtnClick()
    if not self.Param.Lv then
        return
    end
    if self.IsSelect then
        return
    end
    
    MvcEntry:GetModel(SeasonBpModel):DispatchType(SeasonBpModel.ON_SEASON_BP_MAIN_SELECT_SPECIAL_ITEM_SHOW, self.Param.Lv)
end

return SeasonBpSpecialGoodItemLogic
