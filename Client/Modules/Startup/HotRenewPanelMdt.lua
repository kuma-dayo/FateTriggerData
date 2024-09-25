
local class_name = "HotRenewPanelMdt";
HotRenewPanelMdt = HotRenewPanelMdt or BaseClass(GameMediator, class_name);

function HotRenewPanelMdt:__init()
end

function HotRenewPanelMdt:OnShow(data)
	CLog("-----OnShow")
end

function HotRenewPanelMdt:OnHide()
	CLog("-----OnHide")
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.Enter_Button.OnClicked,				    Func = self.OnClicked_OpenStartup},
	}
    CLog("-----HotRenew init")
end


--由mdt触发调用
function M:OnShow(data)
    
end

function M:OnHide()
end

--获取命令行参数(满足自动登录及进入房间)
function M:GetCommandLineParams()
    local CommandLine = UE.UKismetSystemLibrary.GetCommandLine()
	local UserHotRenew = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "UseHotRenew=")
 
end

function M:OnClicked_OpenStartup()
    CLog("-----OnClicked_OpenStartup")
    MvcEntry:OpenView(ViewConst.StartupPanel)
end


return M