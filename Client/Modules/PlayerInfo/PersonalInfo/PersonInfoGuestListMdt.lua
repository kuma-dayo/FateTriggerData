--[[
    个人信息 - 最近访客列表界面
]] 

local class_name = "PersonInfoGuestListMdt";
PersonInfoGuestListMdt = PersonInfoGuestListMdt or BaseClass(GameMediator, class_name);


function PersonInfoGuestListMdt:__init()
end

function PersonInfoGuestListMdt:OnShow(data)
end

function PersonInfoGuestListMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.UMGInfo = {
        UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Information/PersonolInformation/WBP_Imformation_GuestUI.WBP_Imformation_GuestUI",
        LuaClass = require("Client.Modules.PlayerInfo.PersonalInfo.PersonInfoGuestListLogic"),
    }
    self.PersonalModel = MvcEntry:GetModel(PersonalInfoModel)
    local PopParam = {
        TitleStr = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PersonInfoGuestListMdt_Recentvisitors")),
        ContentType = CommonPopUpPanel.ContentType.Content,
        CloseCb = Bind(self,self.OnEscClick),
    }
    self.CommonPopUpPanel = UIHandler.New(self,self.WBP_CommonPopPanel,CommonPopUpPanel,PopParam).ViewInstance
end

function M:OnShow(TargetPlayerId)
    self.PlayerId = TargetPlayerId
    local DetailData = self.PersonalModel:GetPlayerDetailInfo(TargetPlayerId)
    if not DetailData then
        CError("PersonInfoGuestListMdt GetPlayerDetailInfo Error!",true)
        return
    end
    self.GuestList = DetailData.RecentVisitorList
    if #self.GuestList == 0 then
        self.CommonPopUpPanel:SetEmptyTips(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_PersonInfoGuestListMdt_Novisitorsforthetime")))
        self.CommonPopUpPanel:SetContentType(CommonPopUpPanel.ContentType.Empty)
    else
        self.CommonPopUpPanel:SetContentType(CommonPopUpPanel.ContentType.Content)
        self:UpdateGuestList()
    end
end

function M:OnHide()
end

-- 更新访客列表
function M:UpdateGuestList()
    if not self.UMGInfo.ViewItem then
        local WidgetClassPath = self.UMGInfo.UMGPATH
        local WidgetClass = UE.UClass.Load(WidgetClassPath)
        local Widget = NewObject(WidgetClass, self)
        UIRoot.AddChildToPanel(Widget,self.CommonPopUpPanel:GetContentPanel())
        Widget.Slot:SetAutoSize(true)
        local ViewItem = UIHandler.New(self,Widget,self.UMGInfo.LuaClass).ViewInstance
        self.UMGInfo.ViewItem = ViewItem
        self.UMGInfo.View = Widget
    end
    self.UMGInfo.ViewItem:UpdateUI(self.GuestList)
end

function M:OnEscClick()
    MvcEntry:CloseView(self.viewId)
end

return M
