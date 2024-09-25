--[[
    错误提示处理模块
]]
local class_name = "ErrorCtrl"
---@class ErrorCtrl : UserGameController
ErrorCtrl = ErrorCtrl or BaseClass(UserGameController,class_name)

ErrorCtrl.TIP_TYPE = {
    ERROR_CONFIG = 1,
    POPIDIP_CONFIG = 2 --安全文本
}

function ErrorCtrl:__init()
    CWaring("==ErrorCtrl init")
    self.model = nil
end

function ErrorCtrl:Initialize()
    --[[
        缓存需要返回登录界面后再进行展示的信息
    ]]
    self.ErrorMsgNeedShowOnLogin = {}
end


function ErrorCtrl:AddMsgListenersUser()
    self.ProtoList = {
        {MsgName = Pb_Message.ErrorSync,	Func = self.OnError_Func },
        {MsgName = Pb_Message.TipsSync,	Func = self.OnTipsSync_Func },
        {MsgName = Pb_Message.IdIpSync,	Func = self.OnIdIpSync_Func },
    }

    self.MsgList = {
        { Model = ViewModel, MsgName = ViewConst.LoginPanel,    Func = self.ON_LOGINPANEL_State },
    }
end

--[[
    message ErrorSync
    {
        int32           ErrCode = 1;    // 错误码
        string          ErrCmd  = 2;    // 错误命令
        string          ErrMsg  = 3;    // 错误信息
        repeated string ErrArgs = 4;    // 错误参数
    }
]]

-- 服务器返回ErrorMsg
function ErrorCtrl:OnError_Func(Msg)
    print_r(Msg, "OnError_Func ====Msg")
    self:PopTipsAction(Msg, ErrorCtrl.TIP_TYPE.ERROR_CONFIG)
end

-- 服务器返回IdIpMsg
function ErrorCtrl:OnIdIpSync_Func(Msg)
    print_r(Msg, "OnIdIpSync_Func ====Msg")
    self:PopTipsAction(Msg, ErrorCtrl.TIP_TYPE.POPIDIP_CONFIG)
end

-- 客户端弹出ErrorMsg
function ErrorCtrl:PopErrorSync(ErrCode,ErrCmd,ErrMsg,ErrArgs)
    local Msg = {
        ErrCode = ErrCode,
        ErrCmd = ErrCmd or "",
        ErrMsg = ErrMsg or "",
        ErrArgs = ErrArgs,
    }
    self:PopTipsAction(Msg, ErrorCtrl.TIP_TYPE.ERROR_CONFIG)
end

--[[
    根据Msg信息，创建提示 (GetErrorTipByMsg多模块有引用，暂时保留)
]]
function ErrorCtrl:GetErrorTipByMsg(Msg)
    return self:GetErrorTipByMsgInner(Msg.ErrCode,Msg.ErrMsg,Msg.ErrArgs)
end

function ErrorCtrl:GetErrorTipByMsgInner(ErrCode,ErrMsg,ErrArgs)
    ErrMsg = ErrMsg or ""
    --打印错误日志
    local PrintLog = StringUtil.FormatSimple("ErrorCode:{0},ErrorMsg:{1}",ErrCode,ErrMsg)
    CLog(PrintLog)
    --默认只展示错误码
    local ErrorCodeStr = G_ConfigHelper:GetStrFromCommonStaticST("ErrorCode")
    local Des = StringUtil.FormatSimple(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"),ErrorCodeStr,ErrCode)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ErrorCodeCfg,ErrCode)
    if Cfg then
        if Cfg[Cfg_ErrorCodeCfg_P.Des] and string.len(Cfg[Cfg_ErrorCodeCfg_P.Des]) > 0 then
            --有配置具体的描述，用具体描述替换展示
            Des = Cfg[Cfg_ErrorCodeCfg_P.Des]
            if ErrArgs and #ErrArgs > 0 then
                Des = StringUtil.Format(Des, table.unpack(ErrArgs))
                Des = CommonUtil.FixCustomText(Des)
            end
        end
    end
    return Des
end

function ErrorCtrl:GetErrorTipsDesByMsg(Msg, TipsType)
    local ErrMsg = ""
    local CommonSDKey = "ErrorCode"
    local ErrCode = 0
    local Cfg = nil
    local Cfg_Des = ""
    local ErrArgs = nil
    if TipsType == self.TIP_TYPE.ERROR_CONFIG then
        ErrMsg = Msg.ErrMsg
        ErrCode = Msg.ErrCode
        ErrArgs = Msg.ErrArgs
        Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ErrorCodeCfg, ErrCode)
        Cfg_Des = Cfg[Cfg_ErrorCodeCfg_P.Des]
    elseif TipsType == self.TIP_TYPE.POPIDIP_CONFIG then
        ErrMsg = Msg.IdIpsMsg
        ErrCode = Msg.IdIpCode
        ErrArgs = Msg.IdIpArgs
        CommonSDKey = "IdIpCode"
        Cfg = G_ConfigHelper:GetSingleItemById(Cfg_IdIpCode, Msg.IdIpCode)
        Cfg_Des = Cfg[Cfg_IdIpCode_P.Des]
    end

    --打印错误日志
    local PrintLog = StringUtil.FormatSimple("ErrorCode:{0},ErrorMsg:{1}", ErrCode, ErrMsg)
    CLog(PrintLog)
    --默认只展示错误码
    local ErrorCodeStr = G_ConfigHelper:GetStrFromCommonStaticST(CommonSDKey)
    local Des = StringUtil.FormatSimple(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"), ErrorCodeStr, ErrCode)
    if Cfg then
        if Cfg_Des and string.len(Cfg_Des) > 0 then
            --有配置具体的描述，用具体描述替换展示
            Des = Cfg_Des
            if ErrArgs and #ErrArgs > 0 then
                Des = StringUtil.Format(Des, table.unpack(ErrArgs))
                Des = CommonUtil.FixCustomText(Des)
            end
        end
    end
    return Des
end

function ErrorCtrl:PopTipsAction(Msg, TipsType)
    local Cfg = nil
    local CfgTipType = 0
    local Cmd = ""
    local Des = ""
    local ErrCode = 0
    local ErrArgs = nil
    if TipsType == self.TIP_TYPE.ERROR_CONFIG then
        Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ErrorCodeCfg, Msg.ErrCode)
        if not Cfg then
            print("ErrorCtrl:PopTipsAction Cfg nil:", Msg.ErrCode)
            return
        end
        Cmd = Msg.ErrCmd
        ErrCode = Msg.ErrCode
        ErrArgs = Msg.ErrArgs
        CfgTipType = Cfg[Cfg_ErrorCodeCfg_P.TipType]
    elseif TipsType == self.TIP_TYPE.POPIDIP_CONFIG then
        --[[
            message IdIpSync
            {
                int32           IdIpCode = 1;    // 错误码
                string          IdIpCmd  = 2;    // 错误命令
                string          IdIpsMsg  = 3;   // 错误信息
                repeated string IdIpArgs = 4;    // 错误参数
            }
        ]]
        Cfg = G_ConfigHelper:GetSingleItemById(Cfg_IdIpCode, Msg.IdIpCode)
        if not Cfg then
            print("ErrorCtrl:PopTipsAction Cfg nil:", Msg.IdIpCode)
            return
        end
        Cmd = Msg.IdIpCmd
        ErrCode = Msg.IdIpCode
        ErrArgs = Msg.IdIpArgs
        CfgTipType = Cfg[Cfg_IdIpCode_P.TipType]
    end

    if not Cmd then
        CError("ErrorCtrl:PopTipsAction Msg.ErrCmd nil:" .. Cmd,true)
    end

    NetLoading.CheckErrorSendMsgId(Cmd)

    Des = self:GetErrorTipsDesByMsg(Msg, TipsType)

    if Cfg then
        if CfgTipType == 1 then
            --普通提示
            UIAlert.Show(Des)
        elseif CfgTipType == 2 then
            --弹窗
            local msgParam = {
                describe = Des,
            }
            UIMessageBox.Show(msgParam)
        elseif CfgTipType == 3 then
            --系统弹窗
            self:GetSingleton(CommonCtrl):PopGameLogoutBoxTip(Des)
        elseif CfgTipType == 4 then
            CWaring("ErrorCtrl:PopErrorAction:" .. Des)
            MvcEntry:GetCtrl(UserSocketLoginCtrl):OnNetError()
        elseif CfgTipType == 5 then
            CWaring("ErrorCtrl:PopErrorAction:" .. Des)
            --[[
                1.将错误信息进行cache
                2.直接返回登录界面
            ]]
            if MvcEntry:GetCtrl(OnlineSubCtrl):IsOnlineEnabled() then
                --针对Steam子系统，还是走弹窗
                self:GetSingleton(CommonCtrl):PopGameLogoutBoxTip(Des,true)
            else
                self.ErrorMsgNeedShowOnLogin[#self.ErrorMsgNeedShowOnLogin + 1] = Des
                self:GetSingleton(CommonCtrl):GAME_LOGOUT()
            end
        elseif CfgTipType == 6 then
            CWaring("ErrorCtrl:PopErrorAction:" .. Des)
            self:GetSingleton(CommonCtrl):PopGameLogoutBoxTip(Des,true)
        else
            -- 配置为0 不做提示 仅为服务器返回错误操作

            -- 组队需要处理这个Error带回的信息 Msg.ErrArgs[1]为查询不到队伍信息的TeamId
            if ErrCode and ErrCode == ErrorCode.TeamNotExist.ID then
                local TeamId = table.unpack(ErrArgs)
                if TeamId then
                    MvcEntry:GetModel(TeamModel):DeleteOtherTeamInfo(tonumber(TeamId))
                end
            end
        end
    else
        UIAlert.Show(Des)
    end
end

--[[
    message TipsSync
    {
        int32           TipsCode = 1;    // 提示码
        string          TipsMsg  = 2;    // 提示信息
        repeated string TipsArgs = 3;    // 提示参数
    }
]]

-- 服务器返回TipsSync
function ErrorCtrl:OnTipsSync_Func(Msg)
    self:PopTipsSyncAction(Msg)
end

-- 客户端弹出Tips
function ErrorCtrl:PopTipsSync(TipsCode,TipsMsg,TipsArgs)
    local Msg = {
        TipsCode = TipsCode,
        TipsMsg = TipsMsg,
        TipsArgs = TipsArgs,
    }
    self:PopTipsSyncAction(Msg)
end

--[[
    根据Msg信息，创建提示
]]
function ErrorCtrl:GetTipsDesByMsg(Msg)
    local Des = StringUtil.Format("TipsCode:{0},TipsMsg:{1}",Msg.TipsCode,Msg.TipsMsg)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_TipsCode,Msg.TipsCode)
    if Cfg then
        Des = Cfg[Cfg_TipsCode_P.Des]
        if Msg.TipsArgs and #Msg.TipsArgs > 0 then
            Des = StringUtil.Format(Des, table.unpack(Msg.TipsArgs))
            Des = CommonUtil.FixCustomText(Des)
        end
    end
    return Des
end

function ErrorCtrl:PopTipsSyncAction(Msg)
    local Des = self:GetTipsDesByMsg(Msg)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_TipsCode,Msg.TipsCode)
    if Cfg then
        if Cfg[Cfg_TipsCode_P.TipType] == 2 then
            --弹窗
            local msgParam = {
                describe = Des,
            }
            UIMessageBox.Show(msgParam)
        elseif Cfg[Cfg_TipsCode_P.TipType] == 3 then
            UIAlert.Show(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ErrorCtrl_Functionisnotopen"))
        else
            --普通提示
            UIAlert.Show(Des)
        end
    else
        UIAlert.Show(Des)
    end
end

function ErrorCtrl:ON_LOGINPANEL_State(State)
    if State then
        self:CheckLoginNeedShowMsg()
    end
end

--[[
    会在登录界面打开时进行检查并提示
]]
function ErrorCtrl:CheckLoginNeedShowMsg()
    if not self.ErrorMsgNeedShowOnLogin or #self.ErrorMsgNeedShowOnLogin <= 0 then
        return
    end
    --[[
        这边只是取值第一个进行了展示
        后续看需求是否需要连续进行展示
    ]]
    self:GetSingleton(CommonCtrl):PopGameLogoutBoxTip(self.ErrorMsgNeedShowOnLogin[1])
    self.ErrorMsgNeedShowOnLogin = {}
end


