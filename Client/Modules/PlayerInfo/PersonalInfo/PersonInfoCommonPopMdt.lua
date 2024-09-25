--[[
    个人信息 - 公用弹窗界面
]] 

local class_name = "PersonInfoCommonPopMdt";
PersonInfoCommonPopMdt = PersonInfoCommonPopMdt or BaseClass(GameMediator, class_name);

PersonInfoCommonPopMdt.TabTypeEnum = {
    --社交标签
    SocialTag = 1
}

function PersonInfoCommonPopMdt:__init()
end

function PersonInfoCommonPopMdt:OnShow(data)
end

function PersonInfoCommonPopMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    local TitleTabDataList = {
        {
            TabId = PersonInfoCommonPopMdt.TabTypeEnum.SocialTag,
            TabName = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Information", "1031_Btn")),
            UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Information/PersonolInformation/WBP_Imformation_EditPopUp.WBP_Imformation_EditPopUp",
            LuaClass = require("Client.Modules.PlayerInfo.PersonalInfo.PersonInfoTagEdit"),
        },
    }
    self.TabTypeId2Vo = {}
    for k,v in ipairs(TitleTabDataList) do
        self.TabTypeId2Vo[v.TabId] = v
    end
    
    self.SelectTabId = PersonInfoCommonPopMdt.TabTypeEnum.SocialTag
    local PopParam = {
        SelectTabId = self.SelectTabId,
        TitleTabDataList = TitleTabDataList,
        OnTitleTabBtnClickCb = Bind(self,self.OnTitleTabBtnClick),
        OnTitleTabValidCheckFunc = Bind(self,self.OnTitleTabValidCheck),
        ContentType = CommonPopUpPanel.ContentType.Content,
        CloseCb = Bind(self,self.OnEscClick),
    }
    self.CommonPopUpPanel = UIHandler.New(self,self.WBP_CommonPopPanel,CommonPopUpPanel,PopParam).ViewInstance
end

function M:OnShow(Param)
    Param = Param or {}
    if Param.PlayerId then
        self.PlayerId = Param.PlayerId
        self.SelectTabId = Param.SelectTabId or PersonInfoCommonPopMdt.TabTypeEnum.SocialTag
        self.CommonPopUpPanel:TriggerInitTabClick()
    else
        CError("PersonInfoCommonPopMdt:OnShow() cannot find PlayerId")
    end
end

function M:OnHide()
end

function M:OnTitleTabBtnClick(TabId,MenuItem,IsInit)
    self.SelectTabId = TabId
    local VoItem = self.TabTypeId2Vo[self.SelectTabId]
    if not VoItem then
        CError("PersonInfoCommonPopMdt:UpdateTabShow() VoItem nil")
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

    for _,TheVo in pairs(self.TabTypeId2Vo) do
        local TheShow = false
        if TheVo.TabId == self.SelectTabId then
            TheShow = true
        end
        if TheVo.View then
            TheVo.View:SetVisibility(TheShow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
        end
        
        if not TheShow and TheVo.ViewItem then
            TheVo.ViewItem:OnHide()
        end
    end
    local Param = {
        PlayerId = self.PlayerId,
    }
    VoItem.ViewItem:OnShow(Param)
end

-- function M:UpdateRecordItemList()
    
-- end


function M:OnTitleTabValidCheck(TabId)
    return true
end

function M:OnEscClick()
    MvcEntry:CloseView(ViewConst.PersonInfoCommonPopMdt)
end

return M
