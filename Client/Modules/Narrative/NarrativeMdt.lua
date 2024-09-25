--[[
    世界观界面
]]

local class_name = "NarrativeMdt";
NarrativeMdt = NarrativeMdt or BaseClass(GameMediator, class_name);
NarrativeMdt.ContentUMGPath = "/Game/BluePrints/UMG/OutsideGame/WorldView/WBP_WorldView_Content.WBP_WorldView_Content"

function NarrativeMdt:__init()
end

function NarrativeMdt:OnShow(data)
end

function NarrativeMdt:OnHide()
end

-------------------------------------------------------------------------------
local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    ---@type NarrativeModel
    self.Model = MvcEntry:GetModel(NarrativeModel)
end

function M:OnShow(Param)
    Param = Param or {}
    self.SelectTabId = Param.SelectTabId or 1
    local TitleTabDataList = self.Model:GetTabDataList()
    if not TitleTabDataList or #TitleTabDataList == 0 then
        CError("NarrativeMdt GetTabDataList Error !!!!",true)
        self:CloseSelf()
    end

    local PopParam = {
        SelectTabId = self.SelectTabId,
        TitleTabDataList = TitleTabDataList,
        OnTitleTabBtnClickCb = Bind(self,self.OnTitleTabBtnClick),
        OnTitleTabValidCheckFunc = Bind(self,self.OnTitleTabValidCheck),
        ContentType = CommonPopUpPanel.ContentType.List,
        OnRefreshListContentCb = Bind(self,self.OnRefreshContent),
        CloseCb = Bind(self,self.CloseSelf),
    }
    self.CommonPopUpPanel = UIHandler.New(self,self.WBP_CommonPopPanel,CommonPopUpPanel,PopParam).ViewInstance
    self.CommonPopUpPanel:TriggerInitTabClick()
end

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

function M:OnRefreshContent(SelectTabId,SelectContentId)
    if not self.ContentCls then
        local WidgetClass = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(NarrativeMdt.ContentUMGPath))
        if not WidgetClass then
            CError("NarrativeMdt OnRefreshContent WidgetClass Error",true)
            return
        end
        local Widget = NewObject(WidgetClass, self)
        if not Widget then
            CError("NarrativeMdt OnRefreshContent Widget Error",true)
            return
        end
        self.CommonPopUpPanel:AddWidgetToContentScroll(Widget)
        self.ContentCls = UIHandler.New(self,Widget,require("Client.Modules.Narrative.NarrativeContentPanel")).ViewInstance
    end
    local Param = {
        TabId = SelectTabId,
        ContentId = SelectContentId
    }
    self.ContentCls:UpdateUI(Param)
end

function M:CloseSelf()
    MvcEntry:CloseView(self.viewId)
end

return M