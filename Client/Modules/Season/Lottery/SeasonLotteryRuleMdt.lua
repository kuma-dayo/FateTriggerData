--[[
    赛季，抽奖规则界面
]] local class_name = "SeasonLotteryRuleMdt";
SeasonLotteryRuleMdt = SeasonLotteryRuleMdt or BaseClass(GameMediator, class_name);


SeasonLotteryRuleMdt.TabTypeEnum = {
    --[[
        规则描述
    ]]
    RuleDes = 1,
    --[[
        概率说明
    ]]
    RateShow = 2,
}

function SeasonLotteryRuleMdt:__init()
end

function SeasonLotteryRuleMdt:OnShow(data)
end

function SeasonLotteryRuleMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    local TitleTabDataList = {
        {
            TabId = SeasonLotteryRuleMdt.TabTypeEnum.RuleDes,
            TabName = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_SeasonLotteryRuleMdt_Ruledescription")),

            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Lottery/PopUpDetail/WBP_Rules_Content.WBP_Rules_Content",
            LuaClass=require("Client.Modules.Season.Lottery.SeasonLotteryRuleTabRuleLogic"),
        },
        {
            TabId = SeasonLotteryRuleMdt.TabTypeEnum.RateShow,
            TabName = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_SeasonLotteryRuleMdt_Probabilitydetails")),

            UMGPATH="/Game/BluePrints/UMG/OutsideGame/Lottery/PopUpDetail/WBP_Rules_Content.WBP_Rules_Content",
            LuaClass=require("Client.Modules.Season.Lottery.SeasonLotteryRuleTabRateLogic"),
        }
    }
    self.TabTypeId2Vo = {}
    for k,v in ipairs(TitleTabDataList) do
        self.TabTypeId2Vo[v.TabId] = v
    end
    
    self.SelectTabId = SeasonLotteryRuleMdt.TabTypeEnum.RuleDes
    local PopParam = {
        TitleStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_SeasonLotteryRuleMdt_Ruledescription")),
        SelectTabId = self.SelectTabId,
        TitleTabDataList = TitleTabDataList,
        OnTitleTabBtnClickCb = Bind(self,self.OnTitleTabBtnClick),
        OnTitleTabValidCheckFunc = Bind(self,self.OnTitleTabValidCheck),
        ContentType = CommonPopUpPanel.ContentType.Content,
        CloseCb = Bind(self,self.OnEscClick),
    }
    self.CommonPopUpPanel = UIHandler.New(self,self.WBP_CommonPopPanel,CommonPopUpPanel,PopParam).ViewInstance
end

--[[
    Param = {
        PrizePoolId
        SelectTabId
    }
]]
function M:OnShow(Param)
    self.Param = Param
    self.PrizePoolId = Param.PrizePoolId
    self.SelectTabId = Param.SelectTabId or SeasonLotteryRuleMdt.TabTypeEnum.RuleDes

    self.CommonPopUpPanel:TriggerInitTabClick()
end

function M:OnHide()
end

function M:OnTitleTabBtnClick(TabId,MenuItem,IsInit)
    self.SelectTabId = TabId

    local VoItem = self.TabTypeId2Vo[self.SelectTabId]
    if not VoItem then
        CError("HeroDetailPanelMdt:UpdateTabShow() VoItem nil")
        return
    end
    if not VoItem.ViewItem then
        local WidgetClassPath = VoItem.UMGPATH
        local WidgetClass = UE.UClass.Load(WidgetClassPath)
        local Widget = NewObject(WidgetClass, self)
        UIRoot.AddChildToPanel(Widget,self.CommonPopUpPanel:GetContentPanel())
        local ViewItem = UIHandler.New(self,Widget,VoItem.LuaClass).ViewInstance
        VoItem.ViewItem = ViewItem
        VoItem.View = Widget
    end

    for TheTabId,TheVo in pairs(self.TabTypeId2Vo) do
        local TheShow = false
        if TheTabId == self.SelectTabId then
            TheShow = true
        end
        if TheVo.View then
            TheVo.View:SetVisibility(TheShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        end
    end

    local Param = {
        PrizePoolId = self.PrizePoolId,
    }
    VoItem.ViewItem:UpdateUI(Param)
end


function M:OnTitleTabValidCheck(TabId)
    return true
end

function M:OnEscClick()
    MvcEntry:CloseView(self.viewId)
end

return M
