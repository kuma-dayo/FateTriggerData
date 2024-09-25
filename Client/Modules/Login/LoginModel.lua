--[[登录数据模型]]
local super = GameEventDispatcher;
local class_name = "LoginModel";
---@class LoginModel : GameEventDispatcher
LoginModel = BaseClass(super, class_name);


--[[关服信息同步]]
LoginModel.ON_PRE_SEVER_CLOST_INFO_UPDATE = "ON_PRE_SEVER_CLOST_INFO_UPDATE"

--[[
	服务器列表更新事件
]]
LoginModel.ON_SERVER_LIST_UPDATE = "ON_SERVER_LIST_UPDATE"
LoginModel.ON_SERVER_LIST_UPDATE_FINISH = "ON_SERVER_LIST_UPDATE_FINISH"

LoginModel.ON_SDK_LOGIN_START = "ON_SDK_LOGIN_START"
--[[
	local Param = {
		IsFromCacheLogin = false
	}
]]
LoginModel.ON_SDK_LOGIN_SUC = "ON_SDK_LOGIN_SUC"
LoginModel.ON_SDK_LOGIN_FAILED = "ON_SDK_LOGIN_FAILED"
LoginModel.ON_SDK_LOGIN_OUT_SUC = "ON_SDK_LOGIN_OUT_SUC"
--SDK登录发送验证码成功
LoginModel.ON_SDK_LOGIN_SEND_CODE_SUC = "ON_SDK_LOGIN_SEND_CODE_SUC"
LoginModel.ON_SDK_LOGIN_NEED_REAL_NAME = "ON_SDK_LOGIN_NEED_REAL_NAME"


--[[
	开始登录后的步骤枚举
]]
LoginModel.SocketLoginStepTypeEnum = {
	LOGIN_PRE_LOAD_ASSET = 1,
	LOGIN_MAIN_CONNECT = 2,
	LOGIN_CONNECT_PARSE_PB = 3,
	LOGIN_MAIN_CONNECT_BEGIN = 4,
	LOGIN_MAIN_CONNECT_SUC = 5,
	LOGIN_CREATE_PLAYER = 6,
	LOGIN_PLAYER_DATA_SYNC_BEGIN = 7,
	LOGIN_PLAYER_DATA_SYNC_COMPLETE = 8,
}
LoginModel.ON_STEP_LOGIN = "ON_STEP_LOGIN"

-- 登录排队进度通知
LoginModel.ON_LOGINQUEUE_SYNC = "ON_LOGINQUEUE_SYNC"

--自定义服务器开关通知事件
LoginModel.ON_CUSTOM_IP_INPUT_SWITCH = "ON_CUSTOM_IP_INPUT_SWITCH"

LoginModel.NAMECHANGETYPE = { --使用昵称设置界面类型
    LOGIN = 0, --登录
    CHANGENAME = 1 --改变昵称
}

LoginModel.SHOWSERVER_SELECTED = "SHOWSERVER_SELECTED" --更新登录页服务器信息展示通知

--[[
 	对外类型
	-1:外网
	0：内网
	1：运营Release
	2: 腾讯安全
]]--
LoginModel.PUBLICATION_TYPE = 0



-- 杂项设置
LoginModel.Misc = {
	MaxChar_PlayerName = 15,
}

-- ConstData
LoginModel.Const = LoginModel.Const or {
	-- Url_ServerList 		= "https://sf3-g-cn.dailygn.com/obj/rt-game-lf/gravitation/gops/serverlist/serverlist_test.json",
	Url_ServerList 		= "http://grgame-dir.sarosgame.com/hall/game_server",
	Url_ServerList_Fix = "",
    DefaultZOrder = 100,
    DefaultUMGPath = "/Game/BluePrints/UMG/OutsideGame/Login/WBP_Login_ServerList_Item.WBP_Login_ServerList_Item",
}
LoginModel.LoginType = 
{
	DEAULT = 1,
	SDK = 2,
}


function LoginModel:__init()
    -- self:DataInit()

	--自定义服务器IP输入功能开关 默认为关
	self.CustomIpInputSwitch = false
end

function LoginModel:OnGameInit()
	--内网私服
	LoginModel.ServerListCfg = 
	{
		{ Ip = "grgame-cbt.global.sarosgame.com",		Port = 13751,	Name = "Closed Alpha" },
		-- { Ip = "10.97.218.207",  Port = 13751,   Name = "宁森私服" }, -- 宁森私服
		-- { Ip = "10.97.218.197",  Port = 13751,   Name = "成风私服" }, -- 成风私服
		-- { Ip = "10.97.218.219",  Port = 13751,   Name = "徐放私服" }, -- 徐放私服
		-- { Ip = "10.97.218.214",	Port = 13751,	Name = "旭尧私服" }, -- 旭尧私服
		-- { Ip = "10.97.218.75",	Port = 13751,	Name = "晓然私服" }, -- 晓然私服
		-- { Ip = "10.97.218.237",	Port = 13751,	Name = "天翊私服" }, -- 天翊私服
		-- { Ip = "10.97.218.233",	Port = 13751,	Name = "一水私服" }, -- 一水私服
	}

	--发行Release外网包支持
	LoginModel.ServerList4ReleaseCfg = {
		{ Ip = "119.45.17.54",		Port = 13751,	Name = "发行测试服" },
	}

	--腾讯安全测试
	LoginModel.ServerList4TencentAceCfg = {
		{ Ip = "175.27.161.233",		Port = 13751,	Name = "腾讯安全测试" },
	}

	--子系统登录
	LoginModel.ServerList4OnlineSub = {
		{ Ip = "127.0.0.1",		Port = 13751,	Name = "本地" },
	}

	local ClientCL,ClientStream = MvcEntry:GetModel(UserModel):GetP4ChangeList()
	LoginModel.Const.Url_ServerList_Fix = StringUtil.FormatSimple("{0}?branch={1}&bincl={2}",LoginModel.Const.Url_ServerList,ClientStream,ClientCL)
	LoginModel.Const.Url_PatchList_Fix = StringUtil.FormatSimple("{0}?branch={1}",LoginModel.Const.Url_ServerList,ClientStream)

	CWaring("LoginModel.Const.Url_ServerList_Fix:" .. LoginModel.Const.Url_ServerList_Fix)

	-- LoginModel.SocketLoginStepTypeEnum = {
	-- 	LOGIN_PRE_LOAD_ASSET = 1,
	-- 	LOGIN_MAIN_CONNECT = 2,
	-- 	LOGIN_CONNECT_PARSE_PB = 3,
	-- 	LOGIN_MAIN_CONNECT_SUC = 4,
	-- 	LOGIN_CREATE_PLAYER = 5,
	-- 	LOGIN_PLAYER_DATA_SYNC_BEGIN = 6,
	-- 	LOGIN_PLAYER_DATA_SYNC_COMPLETE = 7,
	-- }
	self.LoginStepEnum2Tip = {
		[LoginModel.SocketLoginStepTypeEnum.LOGIN_PRE_LOAD_ASSET] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","LOGIN_PRE_LOAD_ASSET"),--"开始预加载资源",
		[LoginModel.SocketLoginStepTypeEnum.LOGIN_MAIN_CONNECT] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","LOGIN_MAIN_CONNECT"),--"开始连接服务器",
		[LoginModel.SocketLoginStepTypeEnum.LOGIN_CONNECT_PARSE_PB] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","LOGIN_CONNECT_PARSE_PB"),--"开始解析传输协议",
		[LoginModel.SocketLoginStepTypeEnum.LOGIN_MAIN_CONNECT_BEGIN] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","LOGIN_MAIN_CONNECT_BEGIN"),--"开始服务器连接",
		[LoginModel.SocketLoginStepTypeEnum.LOGIN_MAIN_CONNECT_SUC] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","LOGIN_MAIN_CONNECT_SUC"),--"服务器连接成功",
		[LoginModel.SocketLoginStepTypeEnum.LOGIN_CREATE_PLAYER] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","LOGIN_CREATE_PLAYER"),--"开始创建角色",
		[LoginModel.SocketLoginStepTypeEnum.LOGIN_PLAYER_DATA_SYNC_BEGIN] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","LOGIN_PLAYER_DATA_SYNC_BEGIN"),--"开始同步角色信息",
		[LoginModel.SocketLoginStepTypeEnum.LOGIN_PLAYER_DATA_SYNC_COMPLETE] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Login","LOGIN_PLAYER_DATA_SYNC_COMPLETE"),--"角色信息同步完成,准备进入游戏",
	}
	

	LoginModel.LoginType2Str = 
	{
		[LoginModel.LoginType.DEAULT] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_LoginModel_Defaultlogin"),
		[LoginModel.LoginType.SDK] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "Lua_LoginModel_Platformlogin")
	}

	self.ServerList = {}
    self.CurSelectData = nil --当前选中服务器数据
    self.CurSelectIndex = 1 --当前选中服务器索引

	-- todo 后续替换为其他
	if MvcEntry:GetCtrl(MSDKCtrl):GetIsForceUsingSDKLogin() then
		self.CurLoginType = LoginModel.LoginType.SDK
	else
		local LoginType = SaveGame.GetItem("LoginType", true)
		LoginType = LoginType or LoginModel.LoginType.DEAULT
		self.CurLoginType = LoginType
	end


	self.LoginClientInfo = nil
    self.LoginAccountInfo = nil
    self.LoginDeviceInfo = nil
    self.LoginLocationInfo = nil
	self.ClientDHKeyInfo = nil


	EnsureCall("LoginModel:TDAnalyticsPresetPropertiesInit", self.TDAnalyticsPresetPropertiesInit,self)
	self.PresetProperties = self.PresetProperties or {}
	self.PresetProperties["DistinctId"] = MvcEntry:GetCtrl(TDAnalyticsCtrl):GetDistinctId()
end



--[[
    玩家登出时调用
]]
function LoginModel:OnLogout(data)
end

function LoginModel:TDAnalyticsPresetPropertiesInit()
	--[[通过数数SDK获取一些预设属性，例如系统版本，分辨率等等]]
	local JsonPresetProperties = MvcEntry:GetCtrl(TDAnalyticsCtrl):GetPresetProperties()
	if JsonPresetProperties and string.len(JsonPresetProperties) > 0 then
		self.PresetProperties = JSON:decode(JsonPresetProperties)
		if self.PresetProperties then
			print_r(self.PresetProperties,"LoginModel:OnGameInit TDAnalyticsCtrl.GetPresetProperties:",true)

			if self.PresetProperties["#ram"] then
				local RamInfoList = string.split(self.PresetProperties["#ram"],"/")
				if #RamInfoList > 1 then
					self.PresetProperties["ram_max_mb"] = tonumber(RamInfoList[2]) * 1024
				end
			end
		end
	end
end

function LoginModel:SetServerListData(InList)
	if InList and #InList > 0 then
    	self.ServerList = InList
		self:DispatchType(LoginModel.ON_SERVER_LIST_UPDATE)
	end
end

function LoginModel:GetServerListData()
    return self.ServerList
end

function LoginModel:SetPatchListData(InList)
	if InList and #InList > 0 then
		self.PatchList = InList
	end
end

function LoginModel:GetPatchListData()
	return self.PatchList
end

function LoginModel:GetStrByLoginType(LoginType)
	return LoginModel.LoginType2Str[LoginType] or tostring(LoginType)
end

--[[
	获取登录步骤对应的描述信息
]]
function LoginModel:GetStrBySocketLoginStepEnum(StepType)
	return self.LoginStepEnum2Tip[StepType] or tostring(StepType)
end

--[[
    服务器数据
    Name:"",
    bHidden:false,
    Port:13751,
    ServerId:123,
    Ip:"",
    OpStatus:1
]]
function LoginModel:SetCurSelectData(InData)
    self.CurSelectData = self.CurSelectData or {}
    self.CurSelectData = InData
end

--获取当前选中服务器Data
function LoginModel:GetCurSelectData()
    return self.CurSelectData
end

--设置所选择的服务器Index
function LoginModel:SetCurSelectIndex(InIndex)
	local SelIndex = InIndex > 0 and InIndex or 1
    self.CurSelectIndex = SelIndex
end

function LoginModel:GetCurSelectIndex()
    return self.CurSelectIndex
end

function LoginModel:SetLoginType(LoginType)
	self.CurLoginType = LoginType
end

function LoginModel:GetLoginType()
	return self.CurLoginType
end

function LoginModel:IsSDKLogin()
	return self.CurLoginType == LoginModel.LoginType.SDK
end

function LoginModel:GetCustomIpInputSwitch()
	return self.CustomIpInputSwitch
end

function LoginModel:SetCustomIpInputSwitch(Value)
	self.CustomIpInputSwitch = Value
	self:DispatchType(LoginModel.ON_CUSTOM_IP_INPUT_SWITCH,self.CustomIpInputSwitch)
end

local function ReplaceDigitsWithStars(Input,StartPos,Length,ReplaceSymbol)
	-- 检查输入是否为11位
	if not Input or string.len(Input) < StartPos then
		CError("ReplaceDigitsWithStars Input Invalid,Please check",true)
		return Input
	end

	-- 截取字符串的不同部分
	local prefix = string.sub(Input, 1, StartPos-1)
	local suffix = string.sub(Input, StartPos+Length)

	-- 将第4到第7位替换为****
	local replacement = ""
	for i=1,Length do
		replacement = replacement .. ReplaceSymbol
	end

	-- 拼接字符串
	local result = prefix .. replacement .. suffix

	return result
end

--[[
	获取登录后，置厅展示的ID
	1.SDK登录，尝试获取帐号ID
	2.非SDK登录，获取SDkOpenId
]]
function LoginModel:GetStartGameTipShowId()
	local TheShowId = ""
	if self:IsSDKLogin() then
		TheShowId = MvcEntry:GetCtrl(MSDKCtrl):GetAccount() .. ""

		--TODO 中国地区需要将手机号中间四位置为*
		TheShowId = ReplaceDigitsWithStars(TheShowId,4,4,"*")
	else
		TheShowId = MvcEntry:GetModel(UserModel):GetSdkOpenId() .. ""
	end
	return TheShowId
end

--[[
	获取客户端版本信息
]]
function LoginModel:GetLoginClientInfo()
	if not self.LoginClientInfo then
		local TheUserModel = MvcEntry:GetModel(UserModel)
		local ClientDHKeyInfo = self:GetClientDHKeyInfo()
		print_r(ClientDHKeyInfo,"ClientDHKeyInfo:")
		self.LoginClientInfo = {
			Platform = UE.UGameplayStatics.GetPlatformName(),
			Version = TheUserModel:GetAppVersion(),
			Changelist = TheUserModel:GetP4ChangeList(),
			ClientIP = "",
			ClientIPV6 = "",
			Bundle = self.PresetProperties["#bundle_id"] or "",
			GamePublicKey = ClientDHKeyInfo.PublicKey,
		}
	end
	self.LoginClientInfo.LangType = MvcEntry:GetModel(LocalizationModel):GetCurSelectLanguageServer()
	return self.LoginClientInfo
end
--[[
	获取客户端帐号信息，主要是MSDK相关
]]
function LoginModel:GetLoginAccountInfo()
	if not self.LoginAccountInfo then
		--[[
			这里只是为了兼容开发登录，
			SDK登录的话，MSDKCtrl会通过SetLoginAccountInfo进行设置，
			该值不会为空
		]]
		self.LoginAccountInfo  = {
			GameId = "",
			SdkVersion = "",
			Accounttype = 0,
			ChannelId = 0,
			RegChannel = 0,
			PortraitUrl = "",
			AceAccType = 302,
		}
	end
	return self.LoginAccountInfo
end
function LoginModel:SetLoginAccountInfo(LoginAccountInfo)
	if not LoginAccountInfo then
		return
	end
	self.LoginAccountInfo = LoginAccountInfo
end
--[[
	获取设备信息
]]
function LoginModel:GetLoginDeviceInfo()
	if not self.LoginDeviceInfo then
		self.LoginDeviceInfo = {
			OS = self.PresetProperties["#os"] or "",
			SystemSoftware = self.PresetProperties["#os_version"] or "",
			SystemHardware = self.PresetProperties["#device_model"] or "",
			TelecomOper = self.PresetProperties["#carrier"] or "",
			Network = self.PresetProperties["#network_type"] or "",
			ScreenWidth = self.PresetProperties["#screen_width"] or 0,
			ScreenHight = self.PresetProperties["#screen_height"] or 0,
			Density = 0,
			CpuHardware = UE.UGFUnluaHelper.GetCPUBrand(),
			Memory = self.PresetProperties["ram_max_mb"]  or 0,
			GLRender = UE.UGFUnluaHelper.GetGPUBrand(),
			GLVersion = "",
			DeviceId = self.PresetProperties["#device_id"] or "",
			OAID = self.PresetProperties["#device_id"] or "",
			DistinctId = self.PresetProperties["DistinctId"] or "",
		}
	end
	return self.LoginDeviceInfo
end
--[[
	获取位置信息
]]
function LoginModel:GetLoginLocationInfo()
	if not self.LoginLocationInfo then
		self.LoginLocationInfo = {
			CountryCode = "",
			CityAscii = "",
			Latitude = 0,
			Longitude = 0,
		}
	end
	return self.LoginLocationInfo
end
--[[
	获取DH信息
]]
function LoginModel:GetClientDHKeyInfo()
	if not self.ClientDHKeyInfo then
		UE.UGFUnluaHelper.InitDHKey("2", "373578232348234253", -1)
		local DHPrivateKey = UE.UGFUnluaHelper.GetDHPrivateKey()
		self.ClientDHKeyInfo = {
			PrivateKey = DHPrivateKey,
			PublicKey = UE.UGFUnluaHelper.GetDHPublicKey(DHPrivateKey),
		}
	end
	return self.ClientDHKeyInfo
end


return LoginModel