require("Client.Modules.Login.LoginModel")

--[[

]]
local class_name = "LoginCtrl"
---@class LoginCtrl : UserGameController
---@field private model UserModel
LoginCtrl = LoginCtrl or BaseClass(UserGameController,class_name)


function LoginCtrl:__init()
    CWaring("==LoginCtrl init")
    self.Model = nil
end

function LoginCtrl:Initialize()
    ---@type LoginModel
    self.Model = self:GetModel(LoginModel)

	self:DataInit()

	self.ReqPreServerCloseInfoCallBackList = {}
end

function LoginCtrl:DataInit()
	self.NeedAutoEnterGameOnLoginSuc = false

	--停服通知内容
	self.ServerCloseTip = nil
end

function LoginCtrl:OnLogout()
	self:DataInit()
end


function LoginCtrl:AddMsgListenersUser()
    self.MsgList = {
        { Model = LoginModel, MsgName = LoginModel.ON_SDK_LOGIN_SUC,    Func = self.ON_SDK_LOGIN_SUC_Func },
    }
end

function LoginCtrl:ON_SDK_LOGIN_SUC_Func()
	if self.NeedAutoEnterGameOnLoginSuc then
    	self:DoSocketLogin()
	end
	self.NeedAutoEnterGameOnLoginSuc = false
end

function LoginCtrl:TryLogin(CurPlayerName,NeedAutoEnterGame)
	self.NeedAutoEnterGameOnLoginSuc = NeedAutoEnterGame
	if self.Model:IsSDKLogin() then
		MvcEntry:GetCtrl(MSDKCtrl):AutoLogin()
	else
		local TheUserModel = MvcEntry:GetModel(UserModel)
		TheUserModel:SetSdkOpenId(CurPlayerName)
		SaveGame.SetItem("CachePlayerName", CurPlayerName, true)
		self:DoSocketLogin()
	end
end

function LoginCtrl:DoSocketLogin()
	if self:IsServerCloseByNotice() then
		CWaring("LoginCtrl:DoSocketLogin() IsServerCloseByNotice true")
		MvcEntry:OpenView(ViewConst.ServerCloseNotice)
		return
	end
	MvcEntry:GetCtrl(EventTrackingCtrl):ReqOnStepFlow(EventTrackingCtrl.LoginBeforEnum.StartGame)
	self:_DoSocketLoginInner()
	-- local IsAlreadyEnter = false
	-- local EnterFunc = function()
	-- 	if  IsAlreadyEnter then
	-- 		CWaring("LoginCtrl:DoSocketLogin IsAlreadyEnter")
	-- 		return
	-- 	end
	-- 	IsAlreadyEnter = true
	-- 	InputShieldLayer.Close()
	-- 	self:_DoSocketLoginInner()
	-- end
	-- MvcEntry:GetModel(PreLoadModel):DispatchType(PreLoadModel.START_PRELOAD,EnterFunc)
	-- --[[
	-- 	添加超时接口
	-- ]]
	-- InputShieldLayer.Add(10,1,function ()
	-- 	--超时
	-- 	CWaring("LoginCtrl:EnterFunc TimeOut")
	-- 	EnterFunc()
	-- end)
	-- self:GetModel(LoginModel):DispatchType(LoginModel.ON_STEP_LOGIN,LoginModel.SocketLoginStepTypeEnum.LOGIN_PRE_LOAD_ASSET)
	-- self:GetSingleton(PreLoadCtrl):PreLoadOutSideAction(function ()
	-- 	CWaring("LoginCtrl:PreLoadOutSideAction Suc")
	-- 	EnterFunc()
	-- end,true)
end

function LoginCtrl:_DoSocketLoginInner()
	-- 获取当前选择服务器节点
	local ServerIdx = self.Model:GetCurSelectIndex()
	local ServerNode = self.Model:GetCurSelectData()--self.ServerLists[ServerIdx + 1]
	if ServerIdx < 0 or not ServerNode then
		print("LoginPanel", string.format(">> OnClicked_StartGame, ServerIdx[%d] is invalid!", ServerIdx))
		return false
	end

	-- 缓存数据
	SaveGame.SetItem("CacheIp", ServerNode.Ip, true)
	SaveGame.SetItem("CachePort", ServerNode.Port, true)
	SaveGame.SetItem("ServerId", ServerNode.ServerId, true)
	SaveGame.SetItem("LoginType", self.Model.CurLoginType, true)
	print("LoginPanelMdt", ">> SaveDir, ", UE.UKismetSystemLibrary.GetProjectSavedDirectory())

	-- 设置连接服务器数据
	local userModel = MvcEntry:GetModel(UserModel)
	userModel.Ip = ServerNode.Ip
	userModel.Port = ServerNode.Port
	userModel.ServerId = ServerNode.ServerId or 0

	--TODO 进行Socket连接
	local socketMgr = MvcEntry:GetModel(SocketMgr)
	if socketMgr:IsConnected() then
		socketMgr:Close()
	end
	self:SendMessage(CommonEvent.CONNECT_TO_MAIN_SOCKET)

	-- 请求登录提示
	UIGameWorldTip.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_LoginCtrl_startlogging"),3,nil, UIGameWorldTip.ViewData.LoginTipUMG)
end

--[[
	请求关服信息
]]
function LoginCtrl:ReqPreServerCloseInfo()
	if self.ReqPreServerCloseInfoHandler then
		return
	end
	local SucCallBackFunc = function()
		self:GetModel(LoginModel):DispatchType(LoginModel.ON_PRE_SEVER_CLOST_INFO_UPDATE)
		for k,v in ipairs(self.ReqPreServerCloseInfoCallBackList) do
			v(self.ServerCloseTip)
		end
		self.ReqPreServerCloseInfoCallBackList = {}
	end
	local CommandLine = UE.UKismetSystemLibrary.GetCommandLine()
	local bUseServerCloseNotive = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "bUseServerCloseNotive=")
	bUseServerCloseNotive = tonumber(bUseServerCloseNotive)
	if bUseServerCloseNotive and bUseServerCloseNotive <= 0 then
		--通过命令行，强制跳过关服公告提示流程
		self.ServerCloseTip = ""
		SucCallBackFunc()
		return
	end
	
	local Seed = os.time()
	self.ReqPreServerCloseInfoHandler = HttpRequestJobLogic.New("https://game-tbt-sgp-1323424167.cos.ap-singapore.myqcloud.com/TBTNotices/CloseNotices.txt?seed=" .. Seed,5,function (InContent)
		self.ReqPreServerCloseInfoHandler = nil
		
		self.ServerCloseTip = ""
		local ResultJson = InContent and ('' ~= InContent) and CommonUtil.JsonSafeDecode(InContent) or {}
		-- ResultJson.code = 1
		print_r(ResultJson,"LoginCtrl:ReqPreServerCloseInfo")
		if ResultJson.code and ResultJson.code ~= 0 then
			local CAppVersion = self:GetModel(UserModel):GetAppVersion()
			local ChangeList,Stream = self:GetModel(UserModel):GetP4ChangeList()
			-- CAppVersion = "1.0.0.2"

			local BranchObject = ResultJson and ResultJson[Stream] or nil
			if BranchObject then
				local SAppVersion = BranchObject["appversion"] or nil
				if SAppVersion then
					local IsServerBig = true
					local IsVersionValid = true
					repeat
						local CAppVersionList = string.split(CAppVersion,".")
						local SAppVersionList = string.split(SAppVersion,".")

						if #CAppVersionList ~= #SAppVersionList then
							CWaring(StringUtil.FormatSimple("LoginCtrl:ReqPreServerCloseInfo Version Len not equal,CVersion:{0},SVersion:{1}",CAppVersion,SAppVersion))
							IsVersionValid = false
							break
						end
						for i=1,#CAppVersionList do
							local SNum = tonumber(SAppVersionList[i])
							local CNum = tonumber(CAppVersionList[i])
							if SNum == nil or CNum == nil then
								CWaring(StringUtil.FormatSimple("LoginCtrl:ReqPreServerCloseInfo Version invalid,CVersion:{0},SVersion:{1}",CAppVersion,SAppVersion))
								IsVersionValid = false
								break
							end
							if SNum > CNum then
								IsServerBig = true
								break
							elseif SNum < CNum then
								IsServerBig = false
								break
							end
						end
					until true
					if IsServerBig and IsVersionValid then
						local Language = self:GetModel(LocalizationModel):GetCurSelectLanguage()
						self.ServerCloseTip = BranchObject.content and BranchObject.content[Language] or BranchObject.content['en-US'] or ""
					end
				end
			end
		end
		SucCallBackFunc()
	end)
end

--[[
	获取关服信息
	如果当前没请求过关服信息，则触发请求
]]
function LoginCtrl:GetPreServerCloseInfo(Callback)
	if self.ServerCloseTip == nil then
		self.ReqPreServerCloseInfoCallBackList[#self.ReqPreServerCloseInfoCallBackList + 1] = Callback
		self:ReqPreServerCloseInfo()
	else
		Callback(self.ServerCloseTip)
		return true
	end
	return false
end

function LoginCtrl:GetServerCloseInfo()
	return self.ServerCloseTip
end

function LoginCtrl:IsServerCloseByNotice()
	if self.ServerCloseTip and string.len(self.ServerCloseTip) > 0 then
		return true
	end
	return false
end

