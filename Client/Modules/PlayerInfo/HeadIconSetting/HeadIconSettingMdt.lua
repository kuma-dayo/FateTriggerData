--[[
   个人信息 - 个性化设置界面
]] 
local class_name = "HeadIconSettingMdt";
HeadIconSettingMdt = HeadIconSettingMdt or BaseClass(GameMediator, class_name);

function HeadIconSettingMdt:__init()
end

function HeadIconSettingMdt:OnShow(data)
end

function HeadIconSettingMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    local TitleTabDataList = {
        {
            TabId = HeadIconSettingModel.SettingType.HeadIcon,
            TabName = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingMdt_headportrait_Btn")),
            -- 可选 红点前缀
            RedDotKey = "InformationPersonalHeadIcon",
            -- 可选 红点后缀
            RedDotSuffix = "",
        },
        {
            TabId = HeadIconSettingModel.SettingType.HeadFrame,
            TabName = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingMdt_Avatarframe_Btn")),
            -- 可选 红点前缀
            RedDotKey = "InformationPersonalHeadIconFrame",
            -- 可选 红点后缀
            RedDotSuffix = "",
        },
        {
            TabId = HeadIconSettingModel.SettingType.HeadWidget,
            TabName = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingMdt_Avatarpendant_Btn")),
            -- 可选 红点前缀
            RedDotKey = "InformationPersonalHeadWidget",
            -- 可选 红点后缀
            RedDotSuffix = "",
        }
    }

    self.UMGInfo = {
        UMGPATH="/Game/BluePrints/UMG/OutsideGame/Information/PersonolInformation/WBP_Imformation_SettingUI.WBP_Imformation_SettingUI",
        LuaClass=require("Client.Modules.PlayerInfo.HeadIconSetting.HeadIconSettingLogic"),
    }
    
    self.SelectTabId = HeadIconSettingModel.SettingType.HeadIcon
    local PopParam = {
        TitleStr = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_HeadIconSettingMdt_personalized")),
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
    Param = Param or {}
    self.SelectTabId = Param.SelectTabId or HeadIconSettingModel.SettingType.HeadIcon
    self.CommonPopUpPanel:TriggerInitTabClick()
end

function M:OnHide()
    MvcEntry:GetModel(HeadIconSettingModel):ClearHeadWidgetTemp()
end

function M:OnTitleTabBtnClick(TabId,MenuItem,IsInit)
    self.SelectTabId = TabId

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
        SettingType = self.SelectTabId,
    }
    self.UMGInfo.ViewItem:UpdateUI(Param)
end

function M:OnTitleTabValidCheck(TabId)
    return true
end

function M:OnEscClick()
    MvcEntry:CloseView(self.viewId)
end

return M
