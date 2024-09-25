--[[
    虚拟登录界面
]]
local class_name = "VirtualLoginMdt"
---@class VirtualLoginMdt : GameMediator
VirtualLoginMdt = VirtualLoginMdt or BaseClass(GameMediator, class_name)

function VirtualLoginMdt:__init()
end

--[[
	Param = {
		LogoutActionType  （MSDKConst.LogoutActionTypeEnum） 登出类型
	}
]]
function VirtualLoginMdt:OnShow(Param)
	--[[
		旧的LS播放，暂时注释，后面确认后进行删除
	]]
	-- local PlayParam = {
	-- 	NeedStopAllSequence = true,
	-- 	PlayRate = 3,
	-- 	LevelSequenceAsset = "/Game/Maps/Hall/Hall_LS/HallMain_LS_1.HallMain_LS_1",
	-- 	TimeOut = 15,
	-- }
	-- MvcEntry:GetCtrl(CameraMouseFollowCtrl):StopCameraMove()
	-- MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(nil, function ()
	-- 	print("LevelHallMdt:OnStartLogin  HallMain_LS_1>>>>")
	-- 	MvcEntry:OpenView(ViewConst.LoginPanel)
	-- 	self:AutoLoginByCMD()
	-- end, PlayParam)


	-- print("LevelHallMdt:OnStartLogin  HallMain_LS_1>>>>")
	if MvcEntry:GetCtrl(OnlineSubCtrl):IsOnlineEnabled() then
		MvcEntry:OpenView(ViewConst.OnlineSubLoginPanel,Param)
	else
		MvcEntry:OpenView(ViewConst.LoginPanel,Param)
		self:AutoLoginByCMD()
	end
	-- --尝试触发未成年防沉迷禁玩
	-- MvcEntry:GetModel(UserModel):CheckAntiAddictionMessageBox()
end

--[[
	重复打开此界面时，会触发此方法调用
]]
function VirtualLoginMdt:OnRepeatShow(data)
	MvcEntry:CloseView(ViewConst.NameInputPanel)
end

--通过CMDCommandLine自动登录游戏
function VirtualLoginMdt:AutoLoginByCMD()
	---@type UserModel
	local Model = MvcEntry:GetModel(UserModel)
	if not Model.IsLoginByCMD then
		return false
	end
	local InputName = Model.CMDLoginName
	-- 名字检测(非SDK)
	if (not MvcEntry:GetModel(LoginModel):IsSDKLogin()) then
		-- print("LoginPanel", ">> OnClicked_StartGame, ", InputName)
		-- if not InputName or InputName == "" then
		-- 	UIAlert.Show(StringUtil.Format("LoginName= 项不能为空"))
		-- 	print("LoginPanel", ">> OnClicked_StartGame, CurPlayerName is empty!")
		-- 	return
		-- end

		-- if not self:IsValidAccount(InputName) then
		-- 	UIAlert.Show(StringUtil.Format("LoginName= 中存在不合法字符"))						
		-- 	print("LoginPanel", ">> OnClicked_StartGame, CurPlayerName is invalid!")
		-- 	return
		-- end
		if not CommonUtil.AccountCheckValid(InputName) then
			return false
		end
	end

	local LoginConnectServerId = Model.CMDLoginConnectServerId or 0

	-- 缓存数据
	SaveGame.SetItem("CachePlayerName", InputName, true)
	SaveGame.SetItem("CacheIp", Model.CMDLoginServerIP, true)
	SaveGame.SetItem("CachePort", Model.CMDLoginServerPort, true)
	SaveGame.SetItem("ServerId", LoginConnectServerId, true)

	-- 设置连接服务器数据
	Model.Ip = Model.CMDLoginServerIP
	Model.Port = Model.CMDLoginServerPort
	Model.ServerId = LoginConnectServerId
	Model.SdkOpenId = InputName

	--TODO 进行Socket连接
	MvcEntry:SendMessage(CommonEvent.CONNECT_TO_MAIN_SOCKET)

	-- 请求登录提示
	UIGameWorldTip.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_VirtualLoginMdt_startlogging"),3,nil, UIGameWorldTip.ViewData.LoginTipUMG)
	return true
end

-- 检测输入账号字符(ASCII)
function VirtualLoginMdt:IsValidAccount(InString)
	if not InString then
		return false
	end

	local StrLen = string.len(InString)
	--[[for i = 1, StrLen do
		print("LoginPanel", ">> IsValidAccount, -> ", i, string.sub(InString, i, i))
	end]]

	--[[
		大写字母：A到Z（26个字符）
		小写字母：a到z（26个字符）
		数字：0到9（10个字符）
		符号：（空格）!"#$%&'()*+,-./:<=>?@[\]^_`{|}~（33个字符）
	]]
	local Idx = #string.gsub(InString, "[^\33-\126]", "")		-- 有效字符
	--local Idx = #string.gsub(InString, "[^\128-\191]", "")	-- 中文字符
	print("LoginPanel", ">> IsValidAccount, Idx = ", Idx, StrLen)

	return (Idx == StrLen)
end

function VirtualLoginMdt:OnHide()
	CWaring("VirtualLoginMdt OnHide")
end