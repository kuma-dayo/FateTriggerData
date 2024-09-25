--[[
    +16适龄提示界面
]]
local class_name = "LoginAgeAcceptMdt";
LoginAgeAcceptMdt = LoginAgeAcceptMdt or BaseClass(GameMediator, class_name);

function LoginAgeAcceptMdt:__init()
end

function LoginAgeAcceptMdt:OnShow(data)
	-- CLog("-----OnShow")
end

function LoginAgeAcceptMdt:OnHide()
	-- CLog("-----OnHide")
end


-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
    self.UMGInfo = {
        UMGPATH = "/Game/BluePrints/UMG/OutsideGame/Login/WBP_LoginAgeAcceptContent.WBP_LoginAgeAcceptContent",
        LuaClass = require("Client.Modules.Login.LoginAgeAcceptConentLogic"),
    }

    local PopParam = {
        TitleStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_LoginAgeAcceptMdt_Ageprompt")),
        ContentType = CommonPopUpPanel.ContentType.Content,
        CloseCb = Bind(self,self.CloseSelf),
    }
    self.CommonPopUpPanel = UIHandler.New(self,self.WBP_CommonPopPanel,CommonPopUpPanel,PopParam).ViewInstance
    self.CommonPopUpPanel:SetContentType(CommonPopUpPanel.ContentType.Content)
end

--由mdt触发调用
--[[

]]
function M:OnShow(Param)
    self:SetAgeAcceptContent()
end

function M:SetAgeAcceptContent()
    if not self.UMGInfo.ViewItem then
        local WidgetClassPath = self.UMGInfo.UMGPATH
        local WidgetClass = UE.UClass.Load(WidgetClassPath)
        local Widget = NewObject(WidgetClass, self)
        UIRoot.AddChildToPanel(Widget,self.CommonPopUpPanel:GetContentPanel())
        local ViewItem = UIHandler.New(self,Widget,self.UMGInfo.LuaClass).ViewInstance
        self.UMGInfo.ViewItem = ViewItem 
    end
end


--由mdt触发调用
function M:OnHide()
end


function M:CloseSelf()
    MvcEntry:CloseView(self.viewId)
end


return M