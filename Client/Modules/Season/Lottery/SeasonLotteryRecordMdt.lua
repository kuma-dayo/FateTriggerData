--[[
    赛季，抽奖规则界面
]] local class_name = "SeasonLotteryRecordMdt";
SeasonLotteryRecordMdt = SeasonLotteryRecordMdt or BaseClass(GameMediator, class_name);


SeasonLotteryRecordMdt.TabTypeEnum = {
    --[[
        常驻类型
    ]]
    Forever = 1,
    --[[
        限时类型
    ]]
    Limit = 2,
}

function SeasonLotteryRecordMdt:__init()
end

function SeasonLotteryRecordMdt:OnShow(data)
end

function SeasonLotteryRecordMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    local TitleTabDataList = {
        {
            TabId = SeasonLotteryRecordMdt.TabTypeEnum.Forever,
            TabName = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_SeasonLotteryRecordMdt_bepermanent")),
        },
        {
            TabId = SeasonLotteryRecordMdt.TabTypeEnum.Limit,
            TabName = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_SeasonLotteryRecordMdt_limit")),
        }
    }

    self.UMGInfo = {
        UMGPATH="/Game/BluePrints/UMG/OutsideGame/Lottery/PopUpDetail/WBP_LotteryRecord_Content.WBP_LotteryRecord_Content",
        LuaClass=require("Client.Modules.Season.Lottery.SeasonLotteryRecordListLogic"),
    }
    self.SelectTabId = SeasonLotteryRecordMdt.TabTypeEnum.Forever
    local PopParam = {
        TitleStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Season', "Lua_SeasonLotteryRecordMdt_Extractrecords")),
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
        SelectTabId
    }
]]
function M:OnShow(Param)
    self.Param = Param
    self.SelectTabId = Param.SelectTabId or SeasonLotteryRecordMdt.TabTypeEnum.Forever

    self.CommonPopUpPanel:TriggerInitTabClick()
end

function M:OnHide()
end

function M:OnTitleTabBtnClick(TabId,MenuItem,IsInit)
    self.SelectTabId = TabId
    -- self:UpdateRecordItemList()

    if not self.UMGInfo.ViewItem then
        local WidgetClassPath = self.UMGInfo.UMGPATH
        local WidgetClass = UE.UClass.Load(WidgetClassPath)
        local Widget = NewObject(WidgetClass, self)
        UIRoot.AddChildToPanel(Widget,self.CommonPopUpPanel:GetContentPanel())
        local ViewItem = UIHandler.New(self,Widget,self.UMGInfo.LuaClass).ViewInstance
        self.UMGInfo.ViewItem = ViewItem
        self.UMGInfo.View = Widget
    end

    local Param = {
        RecordType = self.SelectTabId,
    }
    self.UMGInfo.ViewItem:UpdateUI(Param)
end

-- function M:UpdateRecordItemList()
    
-- end


function M:OnTitleTabValidCheck(TabId)
    return true
end

function M:OnEscClick()
    MvcEntry:CloseView(self.viewId)
end

return M
