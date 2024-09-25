MSDKConst = {}

--帐号类型
MSDKConst.AccountTypeEnum = {
    --手机号
    PhoneNum = 2,
}

--生成的验证码类型
MSDKConst.SendCodeTypeEnum = {
    --注册
    Register = 0,
    --登录
    Login = 2,
    --实名
    AuthName = 6,
}

--登录类型
MSDKConst.LoginTypeEnum = {
    None = "",
    --注册登录
    Register = "register",
    --验证码登录
    Login = "loginWithCode",
}

--登出类型
MSDKConst.LogoutActionTypeEnum = {
    None = "",
    --注销帐号
    Logout = 1,
    --切换用户
    SwitcherUser = 2,
}