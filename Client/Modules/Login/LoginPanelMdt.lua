local class_name = "LoginPanelMdt"
LoginPanelMdt = LoginPanelMdt or BaseClass(GameMediator, class_name)

function LoginPanelMdt:__init()
end

function LoginPanelMdt:OnShow(InData)

end

function LoginPanelMdt:OnHide()
	
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
	self.TheLoginModel = MvcEntry:GetModel(LoginModel)
	
	self.BindNodes = {
		{ UDelegate = self.BtnStartGame.OnClicked,				Func = self.OnClicked_StartGame },
		{ UDelegate = self.WBP_BtnRegister.GUIButton_Main.OnClicked,Func = self.OnClicked_Register },
		{ UDelegate = self.WBP_BtnLanguage.GUIButton_Main.OnClicked,Func = self.OnClicked_BtnLanguage },
		{ UDelegate = self.WBP_BtnAnnouncement.GUIButton_Main.OnClicked,Func = self.OnClicked_BtnAnnouncement },
		{ UDelegate = self.WBP_BtnSwitchAccount.GUIButton_Main.OnClicked,		Func = self.OnClicked_SwitchAccount },
		{ UDelegate = self.BtnOpenServerList.OnClicked,				Func = self.OnClicked_BtnOpenServerList },
		{ UDelegate = self.WBP_BtnSwitchLoginType.GUIButton_Main.OnClicked,		Func = self.OnClicked_BtnSwitchLoginType },
		{ UDelegate = self.WBP_BtnQuit.GUIButton_Main.OnClicked,					Func = self.OnClicked_BtnQuit },
		{ UDelegate = self.GUIButtonAcceptAge.OnClicked,		Func = self.OnClicked_GUIButtonAcceptAge },
		
	}
	
	if UE.UProjectBuildInformationLib:bIsInternalPackage() then
		self.DownloadPatch:SetVisibility(UE.ESlateVisibility.Visible)
		self.BindNodes[#self.BindNodes + 1] = { UDelegate = self.DownloadPatch.OnClicked,				Func = self.OnClicked_BtnOpenPatchServerList }	
	else
		self.DownloadPatch:SetVisibility(UE.ESlateVisibility.Collapsed)
	end

	self.MsgList = {
		{ Model = nil, MsgName = CommonEvent.ON_LOGIN_FINISHED, Func = self.ON_LOGIN_FINISHED_Func },
		{ Model = LoginModel, MsgName = LoginModel.SHOWSERVER_SELECTED, Func = self.ON_SERVER_SELECT_Func },
		{ Model = LoginModel, MsgName = LoginModel.ON_SDK_LOGIN_START,    Func = self.ON_SDK_LOGIN_START_Func },
		{ Model = LoginModel, MsgName = LoginModel.ON_SDK_LOGIN_FAILED,    Func = self.ON_SDK_LOGIN_FAILED_Func },
		{ Model = LoginModel, MsgName = LoginModel.ON_SDK_LOGIN_SUC,    Func = self.ON_SDK_LOGIN_SUC_Func },
		{ Model = LoginModel, MsgName = LoginModel.ON_SDK_LOGIN_OUT_SUC,    Func = self.ON_SDK_LOGIN_OUT_SUC_Func },

		{ Model = LoginModel, MsgName = LoginModel.ON_CUSTOM_IP_INPUT_SWITCH,    Func = self.UpdateCustomInputIpShow },
		{ Model = PreLoadModel, MsgName = PreLoadModel.START_PRELOAD,    Func = Bind(self,self.IsShowPreload,true) },
		{ Model = PreLoadModel, MsgName = PreLoadModel.PRELOAD_VIEW_PLAY_QUIT,    Func = Bind(self,self.IsShowPreload,false) },
	}	

	UIHandler.New(self,self.WBP_ResourcePreLoading,require("Client.Modules.PreLoad.PreLoadViewLogic"))
end

--[[
	Param = {
		LogoutActionType  （MSDKConst.LogoutActionTypeEnum） 登出类型
	}
]]
function M:OnShow(Param)
	UIDebug.Show()
	--玩家名字
	self.CurPlayerName = ""
	local CachePlayerName = SaveGame.GetItem("CachePlayerName", true)
	self:UpdatePlayerName(CachePlayerName or "")
	self:UpdateCustomInputIpShow()


	local CommandLine = UE.UKismetSystemLibrary.GetCommandLine()
    local bForceCustomServer = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "bForceCustomServer=")
	bForceCustomServer = tonumber(bForceCustomServer)
	if (bForceCustomServer and bForceCustomServer > 0) then
		--启动命令下强行开启服务器自定义输入
		MvcEntry:GetModel(LoginModel):SetCustomIpInputSwitch(true)
	end

	-- 请求服务器列表
	self.PingList = {}
	self.ServerLists = {}
	-- local bReqSuccess = HttpHelper:HttpGetByUE(LoginModel.Const.Url_ServerList_Fix, function(InContent)
	-- 	self:OnResp_ServerList(InContent)
	-- end)
	-- if not bReqSuccess then
	-- 	self:TryAddLocalServerList()
	-- 	self:AfterServerListUpdate()
	-- end
	-- HttpRequestJobLogic.New(LoginModel.Const.Url_ServerList_Fix,5,function (InContent)
	-- 	self:OnResp_ServerList(InContent)
	-- end,3)

	-- HttpRequestJobLogic.New(LoginModel.Const.Url_PatchList_Fix,5,function (PatchInContent)
	-- 	self:OnResp_PatchList(PatchInContent)
	-- end)
	self:OnResp_ServerList(nil)
	
	MvcEntry:GetCtrl(LoginCtrl):ReqPreServerCloseInfo()
	CWaring("CurP4Version:" .. MvcEntry:GetModel(UserModel):GetClientP4Show())
	CWaring("GetAppVersion:" .. MvcEntry:GetModel(UserModel):GetAppVersion())
	MvcEntry:GetModel(UserModel):CheckClientP4Version()

	if not MvcEntry:GetCtrl(MSDKCtrl):IsSDKEnable() or MvcEntry:GetCtrl(MSDKCtrl):GetIsForceUsingSDKLogin() then
		--SDK不启用或者强制使用SDK登录时，此模式切换进行隐藏
		self.Panel_LogDefault:SetVisibility(UE.ESlateVisibility.Collapsed)
	else
		self.Panel_LogDefault:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	end
	self.Panel_UserCenter:SetVisibility(UE.ESlateVisibility.Collapsed)

	if CommonUtil.IsPlatform_Windows() then
		self.Panel_Quit:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	else
		self.Panel_Quit:SetVisibility(UE.ESlateVisibility.Collapsed)
	end

	--登录方式	
	self.LoginTypeText:SetText(MvcEntry:GetModel(LoginModel):GetStrByLoginType(MvcEntry:GetModel(LoginModel):GetLoginType()))


	if MvcEntry:GetModel(LoginModel):IsSDKLogin() then
		local NeedDoLogout = false
		if Param and Param.LogoutActionType then
			if Param.LogoutActionType == MSDKConst.LogoutActionTypeEnum.SwitcherUser or Param.LogoutActionType == MSDKConst.LogoutActionTypeEnum.Logout then
				NeedDoLogout = true
			end
		end

		if NeedDoLogout then
			MvcEntry:GetCtrl(MSDKCtrl):Logout(Param.LogoutActionType)
		end
	else
		if Param and Param.LogoutActionType then
			if Param.LogoutActionType == MSDKConst.LogoutActionTypeEnum.SwitcherUser then
				self:CleanCacheLoginInfo()
				local Param = {
					Type = 0,
				}
				MvcEntry:OpenView(ViewConst.NameInputPanel, Param)
			end
		end
	end

	SoundMgr:PlaySound(SoundCfg.Music.MUSIC_LOGIN)
	if not (Param and Param.LogoutActionType) then
		-- MvcEntry:OpenView(ViewConst.PreLoginNotice)
		MvcEntry:GetCtrl(LoginStepCtrl):RunLoginStep()


		-- self:TryOpenRegionPolicy()
	end
end

-- ---尝试打开地区合规隐私政策
-- function M:TryOpenRegionPolicy()
-- 	local RegionPolicyID = SaveGame.GetItem(SystemMenuConst.RegionPolicyIdKey, true) or 0
-- 	if RegionPolicyID == 0 then
-- 		MvcEntry:OpenView(ViewConst.RegionPolicyPopup)
-- 	end
-- end

--[[
	重复打开此界面时，会触发此方法调用
]]
function M:OnRepeatShow(data)
	MvcEntry:CloseView(ViewConst.NameInputPanel)
end

--由mdt触发调用
function M:OnHide()
	SoundMgr:PlaySound(SoundCfg.Music.MUSIC_STOP_LOGIN)
end


-------------------------------------------- Getter/Setter ------------------------------------
function M:ON_SERVER_SELECT_Func()
	self:SetServerInfoShowInPanel()
end

-------------------------------------------- Function ------------------------------------

function M:UpdateServerList()
	-- print("LoginPanel", ">> UpdateServerList, " .. self.CurPlayerName)

	self.PingList = {}
	local ExecFunc = function()
		print("LoginPanel", ">> --------ExecFunc--------"--[[, UE.UGFUnluaHelper.ThreadData()]])

		for _, Node in ipairs(self.ServerLists) do
			self.PingList[Node.Ip] = UE.US1MiscLibrary.GetPing(Node.Ip, 0.1)
			print("LoginPanel", ">> UpdateServerList[ExecFunc], ", Node.Ip, self.PingList[Node.Ip])
		end
	end
	local FinishedFunc = function()
		print("LoginPanel", ">> --------FinishedFunc--------", UE.UGFUnluaHelper.ThreadData())
		
		-- self.CBServerList:ClearSelection()
		-- self.CBServerList:ClearOptions()

		local SelectIdx = 0
		local CacheIp = SaveGame.GetItem("CacheIp",true) or ""
		local CachePort = SaveGame.GetItem("CachePort",true) or 0
		for i, Node in ipairs(self.ServerLists) do
			local Ping = self.PingList[Node.Ip]

			if (CacheIp == Node.Ip) and (CachePort == Node.Port) then
				SelectIdx = i - 1
			end
			-- print("LoginPanel", ">> UpdateServerList[FinishedFunc][For], ", Node.Ip, Node.Port, Node.ServerId, Node.Name, Ping)
		end
		-- print("LoginPanel", ">> UpdateServerList[FinishedFunc][Cache], ", CacheIp, CachePort, SelectIdx)
		--self.CBServerList:SetSelectedIndex(SelectIdx or 0)
		SelectIdx = SelectIdx + 1
		self.TheLoginModel:SetCurSelectIndex(SelectIdx)
		self.TheLoginModel:SetCurSelectData(self.ServerLists[SelectIdx])
		self:SetServerInfoShowInPanel()
	end

	if false then
		local bReqSuccess = UE.UGFUnluaHelper.AsyncTask(ExecFunc, FinishedFunc)
	else
		--ExecFunc()
		FinishedFunc()
	end
	print("LoginPanel", ">> UpdateServerList[Start]")
end

function M:UpdateCustomInputIpShow()
	local CustomIpInputSwitch = MvcEntry:GetModel(LoginModel):GetCustomIpInputSwitch()
	self.PanelServerInput:SetVisibility(CustomIpInputSwitch and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function M:UpdatePlayerName(InName, bNotUpdateText)
	self.CurPlayerName = InName or ""
	print("LoginPanel", ">> UpdatePlayerName, " .. self.CurPlayerName)
end

function M:SetServerInfoShowInPanel()
	local ServerData = self.TheLoginModel:GetCurSelectData()
	if not ServerData then	
		CWaring("ServerData nil!!!!!!!!!")
		return
	end
	self.TxtServerName:SetText(ServerData.Name)
end

function M:IsShowPreload(IsShow)
	self.PanelInput:SetVisibility(IsShow and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
	self.VerticalBox_PC:SetVisibility(IsShow and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
end

-------------------------------------------- Callable ------------------------------------

function M:OnResp_ServerList(InContent)
	print("LoginPanel", ">> OnResp_ServerList, HttpGetByUE, ", (InContent or ""))
	if not CommonUtil.IsValid(self) then
		return
	end

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
	-- print_r(self.ServerLists, "Serverlist Server==========")
	
	self:TryAddLocalServerList()
	self:AfterServerListUpdate();
end

function M:OnResp_PatchList(PatchInContent)
	print("LoginPanel", ">> OnResp_PatchList, HttpGetByUE, ", (PatchInContent or ""))
	if not CommonUtil.IsValid(self) then
		return
	end
	self.PatchList = {}
	local ResultJson = PatchInContent and ('' ~= PatchInContent) and CommonUtil.JsonSafeDecode(PatchInContent) or {}
	if ResultJson.code and ResultJson.code == 0 then
		for ServerName,ServerInfo in pairs(ResultJson.data) do
			table.insert(self.PatchList, {
				Ip = ServerInfo.ip,
				Name = ServerName,
				Port = ServerInfo.port
			})
		end
	end
	self:AfterPatchListUpdate();
end


function M:TryAddLocalServerList()
	-- 添加本地配置
	local LocalServerList = nil
	if LoginModel.PUBLICATION_TYPE == 0 then
		LocalServerList = LoginModel.ServerListCfg
	elseif LoginModel.PUBLICATION_TYPE == 1 then
		LocalServerList = LoginModel.ServerList4ReleaseCfg
	elseif LoginModel.PUBLICATION_TYPE == 2 then
		LocalServerList = LoginModel.ServerList4TencentAceCfg
	end
	if LocalServerList then
		for LocalServerIdx, LocalServerNode in pairs(LocalServerList) do
			table.insert(self.ServerLists, LocalServerNode)
		end	
		print_r(self.ServerLists, "Serverlist All==========")
	end
end

function M:AfterServerListUpdate()
	self.TheLoginModel:SetServerListData(self.ServerLists)
	self.TheLoginModel:SetCurSelectData(self.ServerLists[1])
	self:UpdateServerList()
	self.TheLoginModel:DispatchType(LoginModel.ON_SERVER_LIST_UPDATE_FINISH)
	
	if UE.UGFUnluaHelper.IsEditor() then		
		local FastLoad = require("Client.Modules.DeveloperTools.FastLoad")
		FastLoad.FastLoadCehck(self.ServerLists)
	end
end

function M:AfterPatchListUpdate()
	self.TheLoginModel:SetPatchListData(self.PatchList)
end


function M:OnClicked_StartGame()
	if MvcEntry:GetModel(LoginModel):GetCustomIpInputSwitch() then
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
		self.TheLoginModel:SetCurSelectData(ServerNode)
	end
	if not MvcEntry:GetModel(LoginModel):IsSDKLogin() then
		--针对非SDK登录的适配
		if not self.CurPlayerName or string.len(self.CurPlayerName) <= 0 then
			--没有帐号，弹出输入帐号
			local Param = {
				Type = 0,
			}
			MvcEntry:OpenView(ViewConst.NameInputPanel, Param)
			return
		end
		if not CommonUtil.AccountCheckValid(self.CurPlayerName,40,true) then
			return
		end
	end
	MvcEntry:GetCtrl(LoginCtrl):TryLogin(self.CurPlayerName,true)
end


--[[
	切换帐号
]]
function M:OnClicked_SwitchAccount()
	if MvcEntry:GetModel(LoginModel):IsSDKLogin() then
		--发起SDK登出
		MvcEntry:GetCtrl(MSDKCtrl):Logout(MSDKConst.LogoutActionTypeEnum.SwitcherUser)
	else
		local Param = {
			Type = 0,
		}
		MvcEntry:OpenView(ViewConst.NameInputPanel, Param)
	end
end

function M:CleanCacheLoginInfo()
	self.CurPlayerName = nil
	SaveGame.SetItem("CachePlayerName", nil, true)
end

-- 注销账号
function M:OnClicked_Register()
	local LogoutFunc = function ()
		self:CleanCacheLoginInfo()

		if MvcEntry:GetModel(LoginModel):IsSDKLogin() then
			MvcEntry:GetCtrl(MSDKCtrl):Logout(MSDKConst.LogoutActionTypeEnum.Logout)
		else
			-- local TipsStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_LoginPanelMdt_Youarecurrentlynotlo"))
			-- UIGameWorldTip.Show(TipsStr,3,nil, UIGameWorldTip.ViewData.LoginTipUMG)
			UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "LogoutSucTip"))
		end
	end
	local Param = {
		title = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_LoginPanelMdt_logout"),
		describe = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_LoginPanelMdt_Areyousureyouwanttol"),
		leftBtnInfo = {}, 
		rightBtnInfo = {            --【可选】右铵钮信息，默认是【关闭弹窗】             
			callback = function ()
				LogoutFunc()
			end,        --【可选】按钮回调
		}, 
	}
	UIMessageBox.Show(Param)
end

--[[
	打开语言切换界面
]]
function M:OnClicked_BtnLanguage()
	MvcEntry:OpenView(ViewConst.LocalizationSetting)


	-- local ImageTexture = UE.USteamOnlineHelper.GetSelfAvatarTexture()
	-- if ImageTexture then
	-- 	CWaring("SteamSDKCtrl:GetSelfAvatarImageData() ImageTexture suc")
	-- 	self.ImageHead:SetBrushFromTexture(ImageTexture)
	-- else
	-- 	CWaring("SteamSDKCtrl:GetSelfAvatarImageData() ImageTexture Empty")
	-- end

	-- local Ip = UE.UGFUnluaHelper.GetLocalIPAddress()
	-- CWaring("OnClicked_BtnLanguage Ip:" .. Ip)
	-- MvcEntry:GetCtrl(SteamSDKCtrl):GetPlayerNickname()
	-- MvcEntry:GetCtrl(SteamSDKCtrl):GetUniquePlayerId()

	-- local Text = '<span color="#A29F96FF">存活：</><br>成功换行了'
	-- self.LbRichText:SetText(Text)
end


function M:OnSelectionChanged_ServerList(InSelectedItem, InSelectionType)
	print("LoginPanel", ">> OnSelectionChanged_ServerList...".. InSelectedItem .. " - " .. InSelectionType)
end

--[[
	玩家登录成功,进入大厅
]]
function M:ON_LOGIN_FINISHED_Func()
	MvcEntry:OpenView(ViewConst.VirtualHall)
end

function M:ON_SDK_LOGIN_START_Func()
	CWaring("Login: SDK Login Start")
	--self.MaskButton:SetVisibility(UE.ESlateVisibility.Visible)
end

function M:ON_SDK_LOGIN_FAILED_Func()
	CWaring("Login: SDK Login Failed")
	--self.MaskButton:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function M:ON_SDK_LOGIN_SUC_Func(Param)
	CWaring("Login: SDK Login Succ")
	--self.MaskButton:SetVisibility(UE.ESlateVisibility.Collapsed)
	if Param and Param.IsFromCacheLogin == false then
		MvcEntry:OpenView(ViewConst.LoginTipStartGame)
	end
end

--[[
	登出成功通知
]]
function M:ON_SDK_LOGIN_OUT_SUC_Func(LogoutActionType)
	if LogoutActionType == MSDKConst.LogoutActionTypeEnum.Logout then
		UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "LogoutSucTip"))
	elseif LogoutActionType == MSDKConst.LogoutActionTypeEnum.SwitcherUser then
		MvcEntry:GetCtrl(MSDKCtrl):AutoLogin()
	end
end

function M:OnClicked_BtnOpenServerList()
	local msgParams = {
		IsPatch = false,
	}
	MvcEntry:OpenView(ViewConst.LoginServerListPanel,msgParams)
end

function M:OnClicked_BtnOpenPatchServerList()
	local msgParams = {
		IsPatch = true,
	}
	MvcEntry:OpenView(ViewConst.LoginServerListPanel,msgParams)
end

--[[
	切换登录方式
]]
function M:OnClicked_BtnSwitchLoginType()
	local LoginType = MvcEntry:GetModel(LoginModel):GetLoginType()
	if LoginType == LoginModel.LoginType.DEAULT then
		MvcEntry:GetModel(LoginModel):SetLoginType(LoginModel.LoginType.SDK)
		self.LoginTypeText:SetText(MvcEntry:GetModel(LoginModel):GetStrByLoginType(LoginModel.LoginType.SDK))
	else 
		MvcEntry:GetModel(LoginModel):SetLoginType(LoginModel.LoginType.DEAULT)
		self.LoginTypeText:SetText(MvcEntry:GetModel(LoginModel):GetStrByLoginType(LoginModel.LoginType.DEAULT))
	end
end

function M:OnClicked_BtnQuit()
	UE.UKismetSystemLibrary.QuitGame(GameInstance, CommonUtil.GetLocalPlayerC(), UE.EQuitPreference.Quit, true)
end

function M:OnClicked_GUIButtonAcceptAge()
	MvcEntry:OpenView(ViewConst.LoginAgeAccept)
end

function M:OnClicked_BtnAnnouncement()
	MvcEntry:OpenView(ViewConst.PreLoginNotice)
end


return M