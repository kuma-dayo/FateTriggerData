--[[
    SDK登录界面
]]

local class_name = "LoginSDKMdt";
LoginSDKMdt = LoginSDKMdt or BaseClass(GameMediator, class_name);

function LoginSDKMdt:__init()
end

function LoginSDKMdt:OnShow(data)
end

function LoginSDKMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.BtnGetCode.OnClicked,	Func = self.BtnGetCode_OnClicked },
		{ UDelegate = self.Btn_Login.OnClicked,	Func = self.Btn_Login_OnClicked },
		{ UDelegate = self.Btn_Close.OnClicked,	Func = self.Btn_Close_OnClicked },
	}

	self.MsgList = {
        {Model = LoginModel, MsgName = LoginModel.ON_SDK_LOGIN_FAILED, Func = self.ON_SDK_LOGIN_FAILED_Func},
		{Model = LoginModel, MsgName = LoginModel.ON_SDK_LOGIN_NEED_REAL_NAME, Func = self.ON_SDK_LOGIN_NEED_REAL_NAME_Func},
		{Model = LoginModel, MsgName = LoginModel.ON_SDK_LOGIN_SUC, Func = self.ON_SDK_LOGIN_SUC_Func},
		{Model = LoginModel, MsgName = LoginModel.ON_SDK_LOGIN_SEND_CODE_SUC, Func = self.ON_SDK_LOGIN_SEND_CODE_SUC_Func},
    }

	UIHandler.New(self,self,CommonTextBoxInput,{
        InputWigetName = "NumberInput",
        FoucsViewId = self.viewId,
		SizeLimit = 11,
		InputFormatType = CommonTextBoxInput.InputFormatType.NUMBER,
    })

	UIHandler.New(self,self,CommonTextBoxInput,{
        InputWigetName = "CodeInput",
        FoucsViewId = self.viewId,
		SizeLimit = 6,
		InputFormatType = CommonTextBoxInput.InputFormatType.NUMBER,
    })

	--是否获取验证码倒计时
	self.CodeGetCountdownValue = nil
end

--[[
    Param = {
    }
]]
function M:OnShow(Param)
	MvcEntry:GetCtrl(EventTrackingCtrl):ReqOnStepFlow(EventTrackingCtrl.LoginBeforEnum.StartSDKRegister)
	local CacheSDKAccount = SaveGame.GetItem("CacheSDKAccount", true)
	if CacheSDKAccount and string.len(CacheSDKAccount) > 0 then
		self.NumberInput:SetText(CacheSDKAccount)
	end
	self:UpdateCodeSwitchShow()
end

function M:OnRepeatShow(Param)
    
end

function M:OnHide()
   self:ClearSendCoderTimerHandler()
end

function M:ClearSendCoderTimerHandler()
	if self.SendCoderTimerHandler then
		self:RemoveTimer(self.SendCoderTimerHandler)
		self.SendCoderTimerHandler = nil
	end
end

function M:UpdateCodeSwitchShow(NeedUpdateTimer)
	self.WidgetSwitcher_Code:SetActiveWidget(self.CodeGetCountdownValue ~= nil and self.Text_TimeCount or self.BtnGetCode)

	if NeedUpdateTimer then
		self:ClearSendCoderTimerHandler()
		if self.CodeGetCountdownValue then
			--TODO 新增倒计时
			self.SendCoderTimerHandler = self:InsertTimer(1,Bind(self,self.OnGetCoderTimerCountDown),true)
			self:OnGetCoderTimerCountDown()
		end
	end
end

function M:OnGetCoderTimerCountDown()
	if not self.CodeGetCountdownValue then
		return
	end
	self.CodeGetCountdownValue = self.CodeGetCountdownValue - 1
	self.Text_TimeCount:SetText(StringUtil.FormatSimple(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "LoginSDKCodeCountDown"),self.CodeGetCountdownValue))
	if self.CodeGetCountdownValue <= 0 then
		self.CodeGetCountdownValue = nil
		self:UpdateCodeSwitchShow(true)
	end
end

--[[
	登录失败回调
]]
function M:ON_SDK_LOGIN_FAILED_Func(ErrorId)
	NetLoading.Close()
	-- if not ErrorId then
	-- 	UIAlert.Show("登录失败")
	-- else
	-- 	UIAlert.Show(StringUtil.Format("登录失败,错误Id:{0}",ErrorId))
	-- end

	-- 非实名原因，验证码只能60秒发一次
	-- self.CodeGetCountdownValue = nil
	-- self:UpdateCodeSwitchShow(true)
end

--[[
	触发需要启用实名通知
]]
function M:ON_SDK_LOGIN_NEED_REAL_NAME_Func()
	NetLoading.Close()
	UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "LoginRealNameSucTip"))
	self.CodeInput:SetText("")
	self.CodeGetCountdownValue = nil
	self:UpdateCodeSwitchShow(true)
end
--[[
	登录成功回调
]]
function M:ON_SDK_LOGIN_SUC_Func(ErrorId)
	NetLoading.Close()
	self:Btn_Close_OnClicked();
end

--[[
	发送验证码成功回调
]]
function M:ON_SDK_LOGIN_SEND_CODE_SUC_Func()
	NetLoading.Close()
	self.CodeGetCountdownValue = 60
	self:UpdateCodeSwitchShow(true)
end

function M:CheckPhoneInput()
	local PhoneNumText = self.NumberInput:GetText()
	if string.len(PhoneNumText) <= 0 then
		UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "LoginPhoneNumEmpty"))
		return false
	end
	return true
end
function M:CheckCodeInput()
	local CodeNumText = self.CodeInput:GetText()
	if string.len(CodeNumText) <= 0 then
		UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "LoginCodeEmpty"))
		return false
	end
	return true
end

function M:BtnGetCode_OnClicked()
	if not self:CheckPhoneInput() then
		return
	end
	local PhoneNumText = self.NumberInput:GetText()
	self.CodeInput:SetText("")
	NetLoading.Add(nil, nil, nil, 0)
	--TODO 进行查询注册状态，查询后会自动触发请求验证码
	MvcEntry:GetCtrl(MSDKCtrl):GetRegisterStatus(PhoneNumText)
end

function M:Btn_Login_OnClicked()
	if not self:CheckPhoneInput() then
		return
	end
	if not self:CheckCodeInput() then
		return
	end
	local PhoneNumText = self.NumberInput:GetText()
	local CacheAccount = MvcEntry:GetCtrl(MSDKCtrl):GetAccount()
	if not CacheAccount or string.len(CacheAccount) <= 0 then
		--需要先请求验证码
		UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "LoginNeedSendCode"))
		return
	elseif PhoneNumText ~= MvcEntry:GetCtrl(MSDKCtrl):GetAccount() then
		UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "LoginSDKPhoneNumChange"))
		-- 非实名原因，验证码只能60秒发一次
		-- self.CodeGetCountdownValue = nil
		-- self:UpdateCodeSwitchShow(true)
		return
	end
	local CodeNumText = self.CodeInput:GetText()
	NetLoading.Add(nil, nil, nil, 0)
	MvcEntry:GetCtrl(MSDKCtrl):Login(CodeNumText)
end

function M:Btn_Close_OnClicked()
	MvcEntry:CloseView(self.viewId)
end

return M
