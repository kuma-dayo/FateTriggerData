--[[
    赛季段位规则界面
]]

local class_name = "SeasonRankRuleMdt";
SeasonRankRuleMdt = SeasonRankRuleMdt or BaseClass(GameMediator, class_name);

function SeasonRankRuleMdt:__init()
end

function SeasonRankRuleMdt:OnShow(data)
end

function SeasonRankRuleMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = 
    {

	}
    -- -- 屏蔽多余的两个按钮
    -- self.WBP_Common_ConfirmPopUp_L.WCommonBtn_Cancel:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self.WBP_Common_ConfirmPopUp_L.WCommonBtn_Middle:SetVisibility(UE.ESlateVisibility.Collapsed)

    -- UIHandler.New(self, self.WBP_Common_ConfirmPopUp_L.WCommonBtn_Confirm, WCommonBtnTips,
    -- {
    --     OnItemClick = Bind(self,self.OnClick_CloseBtn),
    --     TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("GotIt")),
    --     HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    -- })

    local PopUpBgParam = {
        TitleText = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Rank", "SeasonRankRuleTitle")),
        -- 按钮列表
        BtnList = {
            [1] = {
                BtnParam = {
                    OnItemClick = Bind(self,self.OnClick_CloseBtn),
                    TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("GotIt_Btn")),
                    HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
                    CommonTipsID = CommonConst.CT_F,
                    ActionMappingKey = ActionMappings.F,
                },
                IsWeak = true
            },
        },
        HideCloseTip = true
    }
    self.CommonPopUpWigetLogic = UIHandler.New(self,self.WBP_CommonPopUp_Bg_L,CommonPopUpBgLogic,PopUpBgParam).ViewInstance

    ---@type SeasonRankModel
    self.SeasonRankModel = MvcEntry:GetModel(SeasonRankModel)

    -- 规则item列表
    self.RankRuleItemList = {}
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
    self:UpdateRankRuleShow()
end

-- 更新段位规则展示
function M:UpdateRankRuleShow()
    for _, Item in ipairs(self.RankRuleItemList) do
        if Item and Item.View then
            Item.View:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    local SeasonRankRuleConfigList = self.SeasonRankModel:GetSeasonRankRuleConfigList()
    for Index, SeasonRankRuleConfig in ipairs(SeasonRankRuleConfigList) do
        local Item = self.RankRuleItemList[Index]
        local Param = {
            ConfigData = SeasonRankRuleConfig
        }
        if not (Item and CommonUtil.IsValid(Item.View)) then
            local RankItem = self["WBP_Season_Rank_Rule_Item_" .. Index]
            if RankItem then
                Item = UIHandler.New(self,RankItem,require("Client.Modules.Season.Rank.SeasonRankRuleItemLogic"),Param).ViewInstance
                self.RankRuleItemList[Index] = Item
            end
        end
        Item.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        Item:OnShow(Param) 
    end
end

function M:OnHide()
   
end

-- 关闭界面
function M:OnClick_CloseBtn()
    MvcEntry:CloseView(self.viewId)
end


return M
