local class_name = "LoginOnlineSubMdt"
LoginOnlineSubMdt = LoginOnlineSubMdt or BaseClass(GameMediator, class_name)

function LoginOnlineSubMdt:__init()
end

function LoginOnlineSubMdt:OnShow(InData)

end

function LoginOnlineSubMdt:OnHide()
	
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
	self.TheLoginModel = MvcEntry:GetModel(LoginModel)
	self.TheOnlineSubCtrl = MvcEntry:GetCtrl(OnlineSubCtrl)

	self.MsgList = {
		{ Model = nil, MsgName = CommonEvent.ON_LOGIN_FINISHED, Func = self.ON_LOGIN_FINISHED_Func },
		{ Model = LoginModel, MsgName = LoginModel.ON_STEP_LOGIN, Func = self.ON_STEP_LOGIN_Func },

		{ Model = LoginModel, MsgName = LoginModel.ON_LOGINQUEUE_SYNC, Func = self.ON_LOGINQUEUE_SYNC_Func },
		-- { Model = nil, MsgName = CommonEvent.ON_MAIN_LOGINED, Func =  self.ON_MAIN_LOGINED_Func },
		-- { Model = nil, MsgName = CommonEvent.ON_MAIN_LOGINED_FAIL, Func =  self.ON_MAIN_LOGINED_FAIL_Func},
		{ Model = UserModel, MsgName = UserModel.ON_PLAYER_CREATE_FAIL,	Func = self.ON_PLAYER_CREATE_FAIL_Func},
		{ Model = UserModel, MsgName = UserModel.ON_GET_RANDOM_NAME, Func = self.ON_GET_RANDOM_NAME_Func},
	}	

	self.BindNodes = {
		{ UDelegate = self.ButtonSeverCheck.OnClicked,				Func = self.OnClicked_ButtonSeverCheck },
	}

	self:UpdateTip("")
	UIHandler.New(self,self.WBP_ResourcePreLoading,require("Client.Modules.PreLoad.PreLoadViewLogic"))


	local CommandLine = UE.UKismetSystemLibrary.GetCommandLine()
    local bForceCustomServer = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "bForceCustomServer=")
	bForceCustomServer = tonumber(bForceCustomServer)
	if not CommonUtil.IsShipping() or (bForceCustomServer and bForceCustomServer > 0) then
		self.PanelServerInput:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	else
		self.PanelServerInput:SetVisibility(UE.ESlateVisibility.Collapsed)
	end
end

--[[
	Param = {
		LogoutActionType  （MSDKConst.LogoutActionTypeEnum） 登出类型
	}
]]
function M:OnShow(Param)
	UIDebug.Show()
	
	self:SetvisibilityQueue(false)

	if not self.TheOnlineSubCtrl:IsOnlineSDKEnabled() then
		--"子系统SDK初始化失败,请检查"
		MvcEntry:GetCtrl(CommonCtrl):PopGameLogoutBoxTip(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","SubsysmInitFailed"),true)
		return
	end

	if CommonUtil.IsShipping()  then
		self.ServerLists = {
			{ Ip = "grgame-cbt.global.sarosgame.com",		Port = 13751,	Name = "Closed Alpha" },
		}
		self:UpdateServerShowOrStartProgress()
	else
		--TODO 请求服务器列表
		local ClientCL,ClientStream = MvcEntry:GetModel(UserModel):GetP4ChangeList()
		local OnlineSubTypeName = self.TheOnlineSubCtrl:GetOnlineSubTypeName()
		LoginModel.Const.Url_ServerList_Fix = StringUtil.FormatSimple("{0}?branch={1}_{2}&bincl={3}",LoginModel.Const.Url_ServerList,ClientStream,OnlineSubTypeName,ClientCL)
		-- CWaring("LoginModel.Const.Url_ServerList_Fix  SubFix:" .. LoginModel.Const.Url_ServerList_Fix)
		HttpRequestJobLogic.New(LoginModel.Const.Url_ServerList_Fix,5,function (InContent)
			self:OnResp_ServerList(InContent)
		end)
	end
end

--[[
	重复打开此界面时，会触发此方法调用
]]
function M:OnRepeatShow(data)
end

--由mdt触发调用
function M:OnHide()

end

--[[
	服务器列表返回
]]
function M:OnResp_ServerList(InContent)
	self.ServerLists = {}
	local ResultJson = InContent and ('' ~= InContent) and CommonUtil.JsonSafeDecode(InContent) or {}
	if ResultJson.code and ResultJson.code == 0 then
		for ServerName,ServerInfo in pairs(ResultJson.data) do
			table.insert(self.ServerLists, {
				Ip = ServerInfo.ip,
				Name = ServerName,
				Port = ServerInfo.port
			})
		end
	end
	if #self.ServerLists <= 0 then
		if not CommonUtil.IsShipping() then
			CWaring("LoginOnlineSubMdt:OnResp_ServerList ServerLists Empty")
			self.ServerLists = {
				{ Ip = "127.0.0.1",		Port = 13751,	Name = "本地" },
			}
		else
			MvcEntry:GetCtrl(CommonCtrl):PopGameLogoutBoxTip(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","ServerListEmptyTip"),true)
			return
		end
	end

	self:UpdateServerShowOrStartProgress()
end

function M:UpdateServerShowOrStartProgress()
	CWaring("LoginOnlineSubMdt:UpdateServerShowOrStartProgress")
	self.CurSelectServerIndex = 1
	self.CurSelectServerData = self.ServerLists[self.CurSelectServerIndex]
	if self.PanelServerInput:GetVisibility() ~= UE.ESlateVisibility.SelfHitTestInvisible  then
		self:StartOnlineProgress()
    else
        --TODO 非Shipping模式展示定服务器按钮   并且需要点击才会进行继续运行
		--设置当前获取到的即将连接的服务器信息
		self.InputIp:SetText(self.CurSelectServerData.Ip)
		self.InputPort:SetText(self.CurSelectServerData.Port)
	end
end

--[[
	开始子系统登录流程
]]
function M:StartOnlineProgress()
	CWaring("LoginOnlineSubMdt:StartOnlineProgress")
	local Step = {ViewId = 0,CustomLogic = function()
		self.TheLoginModel:SetCurSelectIndex(self.CurSelectServerIndex)
		self.TheLoginModel:SetCurSelectData(self.CurSelectServerData)
		local CurPlayerName = self.TheOnlineSubCtrl:GetUniquePlayerId()
		MvcEntry:GetCtrl(LoginCtrl):TryLogin(CurPlayerName,true)
	end}
	MvcEntry:GetCtrl(LoginStepCtrl):DynamicRegisterLoginStep(Step)

	MvcEntry:GetCtrl(LoginStepCtrl):RunLoginStep()
end

function M:UpdateTip(TipStr)
	self.LbTip:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	self.LbTip:SetText(TipStr)
end

function M:ON_STEP_LOGIN_Func(StepType)
	local Tip = self.TheLoginModel:GetStrBySocketLoginStepEnum(StepType)
	self:UpdateTip(Tip)
end

---登录排队进度通知
function M:ON_LOGINQUEUE_SYNC_Func(Param)
	-- CError("ON_LOGINQUEUE_SYNC_Func 同步 排队进程!!!! Param = "..table.tostring(Param))
	CLog("ON_LOGINQUEUE_SYNC_Func 同步 排队进程!!!! Param = "..table.tostring(Param))
	if Param == nil then
		return
	end

	if not CommonUtil.IsValid(self.GUIVerticalBox_Queue) then
		return
	end

	---进入排队状态时,清空Tip
	self:UpdateTip("")

	local TotalNum = Param.TotalNum or 0
	local CurrNum = Param.CurrNum or 0
	if CurrNum < 1  then
		self:SetvisibilityQueue(false)
	else
		self.LbTip:Setvisibility(UE.ESlateVisibility.Collapsed)

		self:SetvisibilityQueue(true)

		-- G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_LoginQueueSync_Tip")
		local describe = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"), CurrNum, TotalNum )--{0}/{1}
		self.Text_Queue:SetText(describe)

		self.GUITextBlock:SetText(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "1735")) --排队中...
	end
end

function M:SetvisibilityQueue(bVisibility)
	if not CommonUtil.IsValid(self.GUIVerticalBox_Queue) then
		return
	end

	if bVisibility then
		self.GUIVerticalBox_Queue:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	else
		self.GUIVerticalBox_Queue:Setvisibility(UE.ESlateVisibility.Collapsed)
	end
	
end

-- ---登陆成功通知
-- function M:ON_MAIN_LOGINED_Func()
-- 	self:SetvisibilityQueue(false)
-- end

-- ---登陆失败通知
-- function M:ON_MAIN_LOGINED_FAIL_Func()
-- 	self:SetvisibilityQueue(false)
-- end

--[[
	创角失败通知
]]
function M:ON_PLAYER_CREATE_FAIL_Func(ErrorCode)
	--创角失败，请求随机名称继续创角
	self.CreateFailedRetyTime = self.CreateFailedRetyTime or 0
	self.CreateFailedRetyTime = self.CreateFailedRetyTime + 1
	if self.CreateFailedRetyTime > 3 then
		MvcEntry:GetCtrl(CommonCtrl):PopGameLogoutBoxTip(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "LOGIN_SUB_CREATE_FAILED"),true)
	else
		MvcEntry:GetCtrl(UserCtrl):SendProto_RandomNameReq(true)
	end
end

--[[
	随机名称返回，继续尝试重新创角
]]
function M:ON_GET_RANDOM_NAME_Func(Name)
	local TheUserModel = MvcEntry:GetModel(UserModel)
	MvcEntry:GetCtrl(UserSocketLoginCtrl):AutoCreatePlayerInfo(TheUserModel:GetSdkOpenId(),Name)
end

--[[
	玩家登录成功,进入大厅
]]
function M:ON_LOGIN_FINISHED_Func()
	MvcEntry:OpenView(ViewConst.VirtualHall)
end

function M:OnClicked_ButtonSeverCheck()
	--TODO 检查是否输入了IP和端口
	local TheInputIp = self.InputIp:GetText()
	local FixTheInputIp = StringUtil.Trim(TheInputIp)
	if string.len(FixTheInputIp) <= 0 then
		UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_LoginPanelMdt_Pleaseentertheserver"))
		return
	end
	local TheInputPort = self.InputPort:GetText()
	local FixTheInputPort = StringUtil.Trim(TheInputPort)
	if string.len(FixTheInputPort) <= 0 then
		UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_LoginPanelMdt_Pleaseentertheserver"))
		return
	end
	FixTheInputPort = tonumber(FixTheInputPort)
	if not FixTheInputPort then
		UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_LoginPanelMdt_Portformaterror"))
		return
	end
	local ServerNode = { Ip = FixTheInputIp, Port = FixTheInputPort,	Name = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_LoginPanelMdt_customize") }
	self.CurSelectServerData = ServerNode

	self:StartOnlineProgress()
end



return M