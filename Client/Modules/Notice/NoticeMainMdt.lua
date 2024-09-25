
--- 视图控制器
local class_name = "NoticeMainMdt";
NoticeMainMdt = NoticeMainMdt or BaseClass(GameMediator, class_name);
NoticeMainMdt.ContentUMGPath = "/Game/BluePrints/UMG/OutsideGame/Notice/WBP_NoticeView_Content.WBP_NoticeView_Content"

function NoticeMainMdt:__init()
end

function NoticeMainMdt:OnShow(data)
    
end

function NoticeMainMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    print("NoticeMainMdt OnInit")
    ---@type NoticeModel
    self.Model = MvcEntry:GetModel(NoticeModel)
end

function M:OnShow(Param)
    Param = Param or {}
    self.SelectTabId = Param.SelectTabId or 1
    local TitleTabDataList = self.Model:GetTabDataList()
    if not TitleTabDataList or #TitleTabDataList == 0 then
        CError("NoticeMainMdt GetTabDataList Error !!!!",true)
        self:CloseSelf()
        return
    end

    local PopParam = {
        SelectTabId = self.SelectTabId,
        TitleTabDataList = TitleTabDataList,
        OnTitleTabBtnClickCb = Bind(self,self.OnTitleTabBtnClick),
        OnTitleTabValidCheckFunc = Bind(self,self.OnTitleTabValidCheck),
        ContentType = CommonPopUpPanel.ContentType.List,
        OnRefreshListContentCb = Bind(self,self.OnRefreshContent),
        TitleRedDotKey = "BroadcastTab_",
        ContentRedDotKey = "BroadcastTabItem_",
        CloseCb = Bind(self,self.CloseSelf),
    }
    self.CommonPopUpPanel = UIHandler.New(self,self.WBP_CommonPopPanel,CommonPopUpPanel,PopParam).ViewInstance
    self.CommonPopUpPanel:TriggerInitTabClick()
end

--override
function M:OnHide()
    self.Model = nil
    self.ContentList = nil
    self.ContentCls = nil

    self.CommonPopUpPanel = nil
end


function M:OnTitleTabBtnClick(TabId,MenuItem,IsInit)
    self.SelectTabId = TabId
    local ContentTabDataList = self.Model:GetContentDataList(TabId)
    self.CommonPopUpPanel:SetContentList(ContentTabDataList)
end

function M:OnTitleTabValidCheck(TabId)
    return true
end


--override
function M:OnRefreshContent(SelectTabId,SelectContentId)
    if not self.ContentCls then
        local WidgetClass = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(NoticeMainMdt.ContentUMGPath))
        if not WidgetClass then
            CError("NoticeMainMdt OnRefreshContent WidgetClass Error",true)
            return
        end
        local Widget = NewObject(WidgetClass, self)
        if not Widget then
            CError("NoticeMainMdt OnRefreshContent Widget Error",true)
            return
        end
        self.CommonPopUpPanel:AddWidgetToContentScroll(Widget)
        self.ContentCls = UIHandler.New(self,Widget,require("Client.Modules.Notice.NoticeContentPanel")).ViewInstance
    end
    ---@type NoticeItem
    local NoticeItem =  self.Model:GetData(SelectContentId)
    self.ContentCls:UpdateUI(NoticeItem)
end

--override
function M:CloseSelf()
    MvcEntry:CloseView(self.viewId)
end

return M
