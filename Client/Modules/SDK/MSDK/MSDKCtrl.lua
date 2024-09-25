require("Client.Modules.SDK.MSDK.MSDKConst")

local class_name = "MSDKCtrl"
MSDKCtrl = MSDKCtrl or BaseClass(UserGameController,class_name)


function MSDKCtrl:__init()
    self.Model = nil
end

function MSDKCtrl:Initialize()
    self.SDKHelperLoginRet = nil
end

--- 玩家登出
---@param data any
function MSDKCtrl:OnLogout(data)
	--TODO 玩家主动登出，需要通知SDK登出，但不触发SDK登出回调（否则触发死循环）
    CWaring("MSDKCtrl OnLogout")
end

function MSDKCtrl:OnLogin(data)
    CWaring("MSDKCtrl OnLogin")
end

function MSDKCtrl:OnGameInit()
    self.IsForceUsingSDKLogin = false
    self.Channle = "EGame"
    self.SubChannel = ""
    self.LangType = "zh_CN"
    self.AreaCode = "86"
    self.AccountType = MSDKConst.AccountTypeEnum.PhoneNum  --手机号
    self.LoginType = MSDKConst.LoginTypeEnum.None
    self.Account = ""
    self.LogoutActionType = MSDKConst.LogoutActionTypeEnum.None


    --需要初始化SDK登录错误码的对应描述信息
    self.MSDKErrorCode2Str = {
        [21] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "MSDKErrorCode21"),
        [27] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "MSDKErrorCode27"),
    }
    self.MSDKMethodAndErrorCode2Str = {
        [112] = {
            [5] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "MSDKM112Code5"),
        }
    }
end

function MSDKCtrl:AddMsgListenersUser()
    if not self:IsSDKEnable() then
		return
	end
    CLog("MSDKCtrl AddMsgListenersUser")
    --SDK GMP事件监听
    local SDKTags = UE.USDKTags.Get()
    self.MsgListGMP = {
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.MSDKOnUserLoginResult,Func = Bind(self,self.OnMSDKOnUserLoginResult), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.MSDKOnUserAutoLoginResult,Func = Bind(self,self.OnMSDKOnUserAutoLoginResult), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.MSDKOnLogoutResult,Func = Bind(self,self.OnMSDKOnLogoutResult), bCppMsg = true, WatchedObject = nil },
        -- { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.MSDKOnSwitchUserResult,Func = Bind(self,self.OnMSDKOnSwitchUserResult), bCppMsg = true, WatchedObject = nil },
        -- { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.MSDKOnWakeUpResult,Func = Bind(self,self.OnMSDKOnWakeUpResult), bCppMsg = true, WatchedObject = nil },

        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.MSDKOnAccountVerifyCodeResult,Func = Bind(self,self.OnMSDKOnAccountVerifyCodeResult), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.MSDKOnAccountGetRegisterStatusResult,Func = Bind(self,self.OnMSDKOnAccountGetRegisterStatusResult), bCppMsg = true, WatchedObject = nil },
        -- { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.MSDKOnGetVerifyCodeStatusResult,Func = Bind(self,self.OnMSDKOnGetVerifyCodeStatusResult), bCppMsg = true, WatchedObject = nil },
    }
end


--[[
    根据错误码进行弹窗提示
]]
function MSDKCtrl:DoAlertTipByErrorCode(MethodId,ErrorCode,DefaultTip)
    if self.MSDKMethodAndErrorCode2Str[MethodId] and self.MSDKMethodAndErrorCode2Str[MethodId][ErrorCode] then
        UIAlert.Show(self.MSDKMethodAndErrorCode2Str[MethodId][ErrorCode])
    elseif self.MSDKErrorCode2Str[ErrorCode] then
        UIAlert.Show(self.MSDKErrorCode2Str[ErrorCode])
    else
        UIAlert.Show(DefaultTip)
    end
end

--[[
    帐号注册登录/验证码登录
    返回
]]
function MSDKCtrl:OnMSDKOnUserLoginResult(TheFMSDKHelperLoginRet)
    CWaring(StringUtil.FormatSimple("MSDKCtrl:OnMSDKOnUserLoginResult methodId:{0} retMsg:{1} retCode:{2}",TheFMSDKHelperLoginRet.BaseRet.methodNameID,TheFMSDKHelperLoginRet.BaseRet.retMsg,TheFMSDKHelperLoginRet.BaseRet.retCode))
    if TheFMSDKHelperLoginRet.BaseRet.retCode == 0 then
        --登录成功
        self:SyncLoginSucAccountInfo(TheFMSDKHelperLoginRet)
    else
        if TheFMSDKHelperLoginRet.BaseRet.retCode == 20 then
            --20表示需要实名，不代表错误，忽略即可
            MvcEntry:GetCtrl(EventTrackingCtrl):ReqOnStepFlow(EventTrackingCtrl.LoginBeforEnum.StartCertification)
            self:GetModel(LoginModel):DispatchType(LoginModel.ON_SDK_LOGIN_NEED_REAL_NAME)
            return
        end
        self:DoAlertTipByErrorCode(TheFMSDKHelperLoginRet.BaseRet.methodNameID,TheFMSDKHelperLoginRet.BaseRet.retCode,StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "LoginFailedTip"),TheFMSDKHelperLoginRet.BaseRet.retCode))
        self:GetModel(LoginModel):DispatchType(LoginModel.ON_SDK_LOGIN_FAILED,TheFMSDKHelperLoginRet.BaseRet.retCode)
    end
end
--[[
    自动登录返回
]]
function MSDKCtrl:OnMSDKOnUserAutoLoginResult(TheFMSDKHelperLoginRet)
    CWaring(StringUtil.FormatSimple("MSDKCtrl:OnMSDKOnUserAutoLoginResult methodId:{0} retMsg:{1} retCode:{2}",TheFMSDKHelperLoginRet.BaseRet.methodNameID,TheFMSDKHelperLoginRet.BaseRet.retMsg,TheFMSDKHelperLoginRet.BaseRet.retCode))

    if TheFMSDKHelperLoginRet.BaseRet.retCode ~= 0 then
        --TODO 打开SDK登录界面
        MvcEntry:OpenView(ViewConst.LoginSDK)
    else
        self:SyncLoginSucAccountInfo(TheFMSDKHelperLoginRet)
    end
end
--[[
    SDK登出回调
]]
function MSDKCtrl:OnMSDKOnLogoutResult(TheFMSDKHelperBaseRet)
    CWaring(StringUtil.FormatSimple("MSDKCtrl:OnMSDKOnLogoutResult methodId:{0} retMsg:{1} retCode:{2}",TheFMSDKHelperBaseRet.methodNameID,TheFMSDKHelperBaseRet.retMsg,TheFMSDKHelperBaseRet.retCode))
    NetLoading.Close()
    if TheFMSDKHelperBaseRet.retCode == 0 then
        self:OnLogoutSucInnerAction()
    else
        self:DoAlertTipByErrorCode(TheFMSDKHelperBaseRet.methodNameID,TheFMSDKHelperBaseRet.retCode,StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "LogoutFailedTip"),TheFMSDKHelperBaseRet.retCode))
    end
end
function MSDKCtrl:OnLogoutSucInnerAction()
    self:GetModel(LoginModel):DispatchType(LoginModel.ON_SDK_LOGIN_OUT_SUC,self.LogoutActionType)
    self.LogoutActionType = MSDKConst.LogoutActionTypeEnum.None
    self.LoginType = MSDKConst.LoginTypeEnum.None
    self.Account = ""
end
function MSDKCtrl:OnMSDKOnAccountGetRegisterStatusResult(TheFMSDKHelperAccountRet)
    CWaring(StringUtil.FormatSimple("MSDKCtrl:OnMSDKOnAccountGetRegisterStatusResult methodId:{0} retMsg:{1} retCode:{2}",TheFMSDKHelperAccountRet.BaseRet.methodNameID,TheFMSDKHelperAccountRet.BaseRet.retMsg,TheFMSDKHelperAccountRet.BaseRet.retCode))

    if TheFMSDKHelperAccountRet.BaseRet.retCode == 0 then
        local ExtraJsonObject = JSON:decode(TheFMSDKHelperAccountRet.BaseRet.extraJson)
        if ExtraJsonObject.register_status ~= 0 then
            --触发登录验证码
            CWaring("MSDKCtrl:OnMSDKOnAccountGetRegisterStatusResult Login")
            self.LoginType = MSDKConst.LoginTypeEnum.Login
            MvcEntry:GetCtrl(EventTrackingCtrl):ReqOnStepFlow(EventTrackingCtrl.LoginBeforEnum.LoginRegisterSuc)
        else
            --触发注册验证吗
            CWaring("MSDKCtrl:OnMSDKOnAccountGetRegisterStatusResult Register")
            self.LoginType = MSDKConst.LoginTypeEnum.Register
        end
        self:SendCode()
    else
        CWaring("MSDKCtrl:OnMSDKOnAccountGetRegisterStatusResult failed")
        self:GetModel(LoginModel):DispatchType(LoginModel.ON_SDK_LOGIN_FAILED,TheFMSDKHelperAccountRet.BaseRet.retCode)
    end
end

function MSDKCtrl:OnMSDKOnAccountVerifyCodeResult(TheFMSDKHelperAccountRet)
    CWaring(StringUtil.FormatSimple("MSDKCtrl:OnMSDKOnAccountVerifyCodeResult methodId:{0} retMsg:{1} retCode:{2}",TheFMSDKHelperAccountRet.BaseRet.methodNameID,TheFMSDKHelperAccountRet.BaseRet.retMsg,TheFMSDKHelperAccountRet.BaseRet.retCode))
    if TheFMSDKHelperAccountRet.BaseRet.retCode ~= 0 then
        self:DoAlertTipByErrorCode(TheFMSDKHelperAccountRet.BaseRet.methodNameID,TheFMSDKHelperAccountRet.BaseRet.retCode,StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "LoginCodeSendFailedTip"),TheFMSDKHelperAccountRet.BaseRet.retCode))
        self:GetModel(LoginModel):DispatchType(LoginModel.ON_SDK_LOGIN_FAILED,TheFMSDKHelperAccountRet.BaseRet.retCode)
    else
        self:GetModel(LoginModel):DispatchType(LoginModel.ON_SDK_LOGIN_SEND_CODE_SUC)
    end
end

--[[
    根据登录成功后的结果，同步帐号数据到LoingModel中
]]
function MSDKCtrl:SyncLoginSucAccountInfo(TheFMSDKHelperLoginRet)
    local Param = {
		IsFromCacheLogin = false
	}
    if TheFMSDKHelperLoginRet then
        self.SDKHelperLoginRet = TheFMSDKHelperLoginRet
        MvcEntry:GetCtrl(EventTrackingCtrl):ReqOnStepFlow(EventTrackingCtrl.LoginBeforEnum.LoginSeccecedByCode)
    else
        TheFMSDKHelperLoginRet = self.SDKHelperLoginRet
        Param.IsFromCacheLogin = true
    end
    if not TheFMSDKHelperLoginRet then
        CError("MSDKCtrl:SyncLoginSucAccountInfo TheFMSDKHelperLoginRet nil",true)
        self:GetModel(LoginModel):DispatchType(LoginModel.ON_SDK_LOGIN_FAILED)
        return
    end
    local LoginAccountInfo  = {
        GameId = self:GetGameId(),
        SdkVersion = "",
        AccountType = self.AccountType,
        ChannelId = TheFMSDKHelperLoginRet.channelID,
        PortraitUrl = "",
    }
    print_r(LoginAccountInfo,"MSDKCtrl:SyncLoginSucAccountInfo",true)
    SaveGame.SetItem("CacheSDKAccount", self.Account, true)
    local TheUserModel = self:GetModel(UserModel)
    TheUserModel:SetSdkOpenId(TheFMSDKHelperLoginRet.openID)
    TheUserModel:SetToken(TheFMSDKHelperLoginRet.token)
    self:GetModel(LoginModel):SetLoginAccountInfo(LoginAccountInfo)

    self:GetModel(LoginModel):DispatchType(LoginModel.ON_SDK_LOGIN_SUC,Param)
end



-----------------------------------提供对外使用方法---------------------------------------------------------
--- 判断是强制启用SDK登录
function MSDKCtrl:GetIsForceUsingSDKLogin()
    return (self:IsSDKEnable() and self.IsForceUsingSDKLogin)
end
--- 判断SDK是否可用
function MSDKCtrl:IsSDKEnable()
	local bIsEnable =  UE.UMSDKHelper.IsEnable()
	return bIsEnable 
end

--[[
    获取当前登录流程的帐号
]]
function MSDKCtrl:GetAccount()
    return self.Account
end

--[[
    获取当前登录的帐号类型
]]
function MSDKCtrl:GetAccountType()
    return self.AccountType
end

--[[
    自动登录
]]
function MSDKCtrl:AutoLogin()
    if not self:IsSDKEnable() then
		return
	end
    if UE.UMSDKHelper.IsLogined() then
        self:SyncLoginSucAccountInfo()
    else
        UE.UMSDKHelper.AutoLogin()
    end
end

--[[
    获取对应帐号的注册状态
    进行查询注册状态，查询后会自动触发请求验证码
]]
function MSDKCtrl:GetRegisterStatus(Account)
    if not self:IsSDKEnable() then
		return
	end
    self.Account = Account
    UE.UMSDKHelper.GetRegisterStatus(self.Channle,Account,self.AccountType,self.LangType,self.AreaCode,"");
end

function MSDKCtrl:SendCode()
    if not self:IsSDKEnable() then
		return
	end
    local CodeType = MSDKConst.SendCodeTypeEnum.Register
    if self.LoginType == MSDKConst.LoginTypeEnum.Login then
        CodeType = MSDKConst.SendCodeTypeEnum.Login

        MvcEntry:GetCtrl(EventTrackingCtrl):ReqOnStepFlow(EventTrackingCtrl.LoginBeforEnum.LoginCodeSend)
    elseif self.LoginType == MSDKConst.LoginTypeEnum.Register then
        CodeType = MSDKConst.SendCodeTypeEnum.Register

        MvcEntry:GetCtrl(EventTrackingCtrl):ReqOnStepFlow(EventTrackingCtrl.LoginBeforEnum.RegisterCodeSend)
    end
    local ExtraJsonObject = {
        qcaptcha = {
            ticket = "",
            randstr = "",
            userip = "",
        }
    }
    local ExtraJsonStr = JSON:encode(ExtraJsonObject)
    --"{\"qcaptcha\":{\"ticket\":\"\",\"randstr\":\"\",\"userip\":\"\"}}"
    UE.UMSDKHelper.SendCode(self.Channle, self.Account,CodeType,self.AccountType, self.LangType,self.AreaCode, ExtraJsonStr);
end
function MSDKCtrl:Login(CodeStr)
    if not self:IsSDKEnable() then
		return
	end
    if self.LoginType == MSDKConst.LoginTypeEnum.None then
        CError("MSDKCtrl:Login() LoginType None",true)
        return
    end
    if not CodeStr or string.len(CodeStr) <= 0 then
        CError("MSDKCtrl:Login() CodeStr None",true)
        return
    end
    -- Login(const FString& Channle, const FString& SubChannel, const FString& ExtraJson)

    local ExtraJsonStr = ""
    if self.LoginType == MSDKConst.LoginTypeEnum.Register then
        local ExtraJsonObject = {
            type = self.LoginType,
            account = self.Account,
            --password密码预留 ，传默认值即可
            password = "Aa123456",
            verifyCode = CodeStr,
            accountType = self.AccountType,
            langType = self.LangType,
            areaCode = self.AreaCode,
            webview_window_scale = 0.52,
        }
        ExtraJsonStr = JSON:encode(ExtraJsonObject)
    elseif self.LoginType == MSDKConst.LoginTypeEnum.Login then
        local ExtraJsonObject = {
            type = self.LoginType,
            account = self.Account,
            verifyCode = CodeStr,
            accountType = self.AccountType,
            langType = self.LangType,
            areaCode = self.AreaCode,
        }
        ExtraJsonStr = JSON:encode(ExtraJsonObject)
    end
    --"{\"qcaptcha\":{\"ticket\":\"\",\"randstr\":\"\",\"userip\":\"\"}}"
    UE.UMSDKHelper.Login(self.Channle, self.SubChannel, ExtraJsonStr);
end

--[[
    发起帐号登出
]]
function MSDKCtrl:Logout(LogoutActionType)
    if not self:IsSDKEnable() then
		return
	end
    if not LogoutActionType then
        CError("MSDKCtrl:Login() LogoutActionType None",true)
        return
    end
    self.LogoutActionType = LogoutActionType
    if not UE.UMSDKHelper.IsLogined() then
        self:OnLogoutSucInnerAction()
        return
    end
    NetLoading.Add(nil, nil, nil, 0)
    UE.UMSDKHelper.Logout(self.Channle, self.SubChannel, false);
end

function MSDKCtrl:GetGameId()
    if not self:IsSDKEnable() then
		return 0
	end
    local GameId = UE.UMSDKHelper.GetGameId()
    return GameId
end


