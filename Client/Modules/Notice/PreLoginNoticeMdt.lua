--[[
    登录前公告
]]

local class_name = "PreLoginNoticeMdt";
PreLoginNoticeMdt = PreLoginNoticeMdt or BaseClass(GameMediator, class_name);
PreLoginNoticeMdt.SingleContentUMGPath = "/Game/BluePrints/UMG/OutsideGame/Notice/WBP_Notice_Content.WBP_Notice_Content"
PreLoginNoticeMdt.ContentUMGPath = "/Game/BluePrints/UMG/OutsideGame/Notice/WBP_Notice_ContentTab.WBP_Notice_ContentTab"

function PreLoginNoticeMdt:__init()
end

function PreLoginNoticeMdt:OnShow(data)
end

function PreLoginNoticeMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = 
    {
	
	}
    --- @type PreLoginNoticeModel
    self.Model = MvcEntry:GetModel(PreLoginNoticeModel)

    self.CommonPopUpPanel = UIHandler.New(self, self.WBP_CommonPopPanel, CommonPopUpPanel).ViewInstance
end

--[[
    Param = {
    }
]]
function M:OnShow(Param)
    Param = Param or {}
    self.SelectTabId = Param.SelectTabId or 1
    local PopParam = {
        CloseCb = Bind(self, self.CloseSelf),
        IsCloseBtnVisible = true,
        TitleStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Announcement", "11801")
    }

    if self:IsSingleNotice() then
        PopParam.ContentType = CommonPopUpPanel.ContentType.Content

        -- self.CommonPopUpPanel = UIHandler.New(self, self.WBP_CommonPopPanel, CommonPopUpPanel, PopParam).ViewInstance
        self.CommonPopUpPanel:UpdateUI(PopParam)
        self:MakeSingleNoticeWidget()
    else
        PopParam.ContentType = CommonPopUpPanel.ContentType.List
        PopParam.OnRefreshListContentCb = Bind(self, self.OnRefreshContent)
        
        -- self.CommonPopUpPanel = UIHandler.New(self, self.WBP_CommonPopPanel, CommonPopUpPanel, PopParam).ViewInstance
        self.CommonPopUpPanel:UpdateUI(PopParam)
        self.CommonPopUpPanel:SetContentList(M.NoticeListToCommonPanelList(self.Model:GetNoticeList()))
    end

    local ViewParam = {
        ViewId = ViewConst.PreLoginNotice,
        TabId = ""
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
end

function M.NoticeListToCommonPanelList(NoticeList)
    local CommonPanelList = {}
    for _, Notice in ipairs(NoticeList) do
        table.insert(CommonPanelList, {
            Id = Notice.Id,
            Name = Notice.ListName
        })
    end
    return CommonPanelList
end

function M:IsSingleNotice()
    return #self.Model:GetNoticeList() <= 1
end


function M:OnRepeatShow(Param)
end

function M:OnHide()
    self.Model = nil
    self.CommonPopUpPanel = nil
    self.ContentInstance = nil
    self.SingleContentInstance = nil
end

function M:OnRefreshContent(SelectTabId, SelectContentId)
    if not self.ContentInstance then
        local WidgetClass = UE.UClass.Load(PreLoginNoticeMdt.ContentUMGPath)
        if not WidgetClass then
            CError("PreLoginNoticeMdt OnRefreshContent WidgetClass Error",true)
            return
        end
        local Widget = NewObject(WidgetClass, self)
        if not Widget then
            CError("PreLoginNoticeMdt OnRefreshContent Widget Error",true)
            return
        end
        self.CommonPopUpPanel:AddWidgetToContentSubPanel(Widget)
        self.ContentInstance = UIHandler.New(self, Widget, require("Client.Modules.Notice.PreLoginNoticeContentPanel")).ViewInstance
    end
    local Param = {
        NoticeId = SelectContentId
    }
    self.ContentInstance:UpdateUI(Param)
end

function M:MakeSingleNoticeWidget()
    if not self.SingleContentInstance then
        local WidgetClass = UE.UClass.Load(PreLoginNoticeMdt.SingleContentUMGPath)
        if not WidgetClass then
            CError("PreLoginNoticeMdt MakeSingleNoticeWidget WidgetClass Error",true)
            return
        end
        local Widget = NewObject(WidgetClass, self)
        if not Widget then
            CError("PreLoginNoticeMdt MakeSingleNoticeWidget Widget Error",true)
            return
        end
        UIRoot.AddChildToPanel(Widget, self.CommonPopUpPanel.View.ContentPanel)
        self.SingleContentInstance = UIHandler.New(self, Widget, require("Client.Modules.Notice.PreLoginNoticeContentPanel")).ViewInstance
    end
    local Param = {
        NoticeId = self.Model:GetNoticeList()[1].Id
    }
    self.SingleContentInstance:UpdateUI(Param)
end

function M:CloseSelf()
    MvcEntry:CloseView(self.viewId)
end



return M
