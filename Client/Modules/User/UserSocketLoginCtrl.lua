--[[
    玩家主Socket连接管理器
]] local class_name = "UserSocketLoginCtrl"
UserSocketLoginCtrl = UserSocketLoginCtrl or BaseClass(UserGameController, class_name)

--[[
    区分普通断线重连还是快速断线
区分方法
后台断线切前台，判断切后台时间小于某个值属于快速重连
前台断线直接属于快速重连

快速重连只登录，不检查token，不请求模块数据，不触发onLogot事件，不缓存游戏model派发 (服务器暂不支持)
普通重连，登录，不检查token，请求模块数据，触发onLogout事件，并传参表示重连，缓存游戏model事件派发

UserModel和GameModel 重连状态不清楚数据

在玩家登录过程中断线触发断线重连，出于数据完整性考虑，都归于普通重连
]]
UserSocketLoginCtrl.EReConnectType = {
    -- 非重连状态
    NONE = 0,
    -- 普通重连
    NORMAL = 1,
    -- 普通重连（但使用普通登录协议）
    NORMAL_USELOGIN = 2,
    -- 快速重连  (还未支持)
    FAST = 3,
}

function UserSocketLoginCtrl:__init()
    self.TryTimerId = nil
    self.TriedCount = 0
    --重连尝试次数
    self.TryCount = CommonUtil.GetParameterConfig(ParameterConfig.TryCount,5)
    --重连尝试间隔
    self.TryDelayGap =  CommonUtil.GetParameterConfig(ParameterConfig.TryDelayGap,5)
    self.TryDelayGap = math.max(self.TryDelayGap,2)
    self.lastConnectTime = 0
    self.NetBadCount = 0
    self.NetErrorTimerId = nil
    self.ReConnectType = UserSocketLoginCtrl.EReConnectType.NONE
    self.IsAppDelayFocus = true
    self.IsAppFocus = true
    self.NetBadCount = 0
    self.NetBadCountMax = 3
    self.PingTimerId = nil
    self.PingTimeGap = 10
    self.SleepStartTime = 0
    self.GoodTime = 1
    self.NormalTime = 3
    self.PongSimulateTime = self.NormalTime + 1
    self.PongValid = true
    self.PongIdIncrement = 1
    self.PongId2Working = {}
    self.PongId2SimulateTimerId = {}

    --[[
        是否开启断线重连 GM
        开启后   
            按{ 键可以 断开Socket连接
            按} 键可以 重连Socket连接
    ]]
    self.OpenGMReconnect = false
    --[[
        断线重连 GM 当前开关状态

        开启表示，断开Socket连接，但不允许连接成功
        关闭表示，允许Socket重连
    ]]
    self.GMReconnectSwitch = false
end

function UserSocketLoginCtrl:Initialize()

end
function UserSocketLoginCtrl:OnLogout()
    self:CleanPingInfo();
    self.TriedCount = 0
    self.ReConnectType = UserSocketLoginCtrl.EReConnectType.NONE
    self.GMReconnectSwitch = false
    self:StopPingTimer();
end

function UserSocketLoginCtrl:AddMsgListenersUser()
    self.ProtoList = {
        { MsgName = Pb_Message.LoginRsp,        Func = self.LoginRsp_Func },
        { MsgName = Pb_Message.ContinueRsp,        Func = self.ContinueRsp_Func },
        { MsgName = Pb_Message.GateVersionSync,        Func = self.GateVersionSync_Func },
        { MsgName = Pb_Message.AuthFailSync,    Func = self.OnAuthFailSync },
        -- 返回账号信息
        {MsgName = Pb_Message.WaitCreatePlayerSync,Func = self.WaitCreatePlayerNotify_Func}, 
        {MsgName = Pb_Message.CreatePlayerRsp,Func = self.CreatePlayerRsp_Func}, 
        {MsgName = Pb_Message.PlayerBaseSync,Func = self.PlayerBaseData_Func}, 
        {MsgName = Pb_Message.PlayerDataCompleteSync,Func = self.SyncPlayerData_Func}, 
        {MsgName = Pb_Message.HeartbeatRsp,Func = self.OnPongHandler}, 
        {MsgName = Pb_Message.KickoutSync,Func = self.Kickout_Func},
        {MsgName = Pb_Message.CommonDayRefreshSync,Func = self.SyncCommonDayRefresh},
        {MsgName = Pb_Message.PlayerDataBeginSync,Func = self.PlayerDataBeginSync},
        {MsgName = Pb_Message.LoginQueueSync,Func = self.LoginQueueSync},--登录排队进度通知
        --客户端热更新通知
        {MsgName = Pb_Message.ClientUpdateSync,Func = self.ClientUpdateSync_Func},
    }

    self.MsgList = {
        {Model = SocketMgr,MsgName = SocketMgr.CMD_ON_CONNECTED,Func = self.OnConnectedHandler}, 
        {Model = SocketMgr,MsgName = SocketMgr.CMD_ON_CLOSED,Func = self.OnClosedHandler}, 
        {Model = SocketMgr,MsgName = SocketMgr.CMD_ON_ERROR,Func = self.OnErrorHandler}, 
        {Model = nil,MsgName = CommonEvent.CONNECT_TO_MAIN_SOCKET,Func = self.ConnectToServer}, 
        -- {Model = nil,MsgName = CommonEvent.ON_APP_WILL_ENTER_BACKGROUND,Func = self.OnAppWillEnterBackground}, 
        -- {Model = nil,MsgName = CommonEvent.ON_APP_HAS_ENTERED_FOREGROUND,Func = self.OnAppHasEnteredForeground},


        {Model = nil,MsgName = CommonEvent.ON_APP_WILL_DEACTIVATE,Func = self.OnAppWillDeactivate}, 
        {Model = nil,MsgName = CommonEvent.ON_APP_HAS_REACTIVATED,Func = self.OnAppHasReactivated}, 

        {Model = nil,MsgName = CommonEvent.RECONNECT_STATE,Func = self.RECONNECT_STATE_func},

        {Model = ViewModel,MsgName = ViewModel.ON_PRE_LOAD_MAP,Func = self.ON_PRE_LOAD_MAP_Func}, 
        {Model = ViewModel,MsgName = ViewModel.ON_POST_LOAD_MAP,Func = self.ON_POST_LOAD_MAP_Func}, 

        {Model = GlobalInputModel, MsgName = EnhanceInputActionTriggered_Event(GlobalActionMappings.BracketLeft),	Func = self.OnBracketLeftTrigger },
        {Model = GlobalInputModel, MsgName = EnhanceInputActionTriggered_Event(GlobalActionMappings.BracketRight),	Func = self.OnBracketRightTrigger },
        
        {Model = PreLoadModel,MsgName = PreLoadModel.PRELOAD_VIEW_PLAY_FINISH,Func = self.OnSyncPlayerDataSucFunc}, 
    }
end

-- message PlayerDataBeginSync
-- {    
--     int64 ServerTimestamp  = 1; // 服务器逻辑时间戳
--     int64 OtherDayOffset   = 2;  // 服务器跨天刷新的时间偏移值，单位秒
--     int32 SeasonId         = 3; // 玩家当前赛季Id
--     int32 ZoneId           = 4; // 服务器的ZoneId
-- }
function UserSocketLoginCtrl:PlayerDataBeginSync(Msg)
    self:GetModel(LoginModel):DispatchType(LoginModel.ON_STEP_LOGIN,LoginModel.SocketLoginStepTypeEnum.LOGIN_PLAYER_DATA_SYNC_BEGIN)
    print_r(Msg, "UserSocketLoginCtrl:PlayerDataBeginSync")
    if not Msg then
        return
    end

    ---修正服务器时间
    SetTimestampOffsetMilliseconds(Msg.ServerTimestamp - GetLocalTimestampMillisecondsUtc())
    -- 校正数数事件时间戳
    self:GetSingleton(TDAnalyticsCtrl):CalibrateTime(GetTimestamp())
    self:GetModel(UserModel):SetDayOffset(Msg.OtherDayOffset)
    self:GetModel(SeasonModel):UpdateCurrentSeasonId(Msg.SeasonId)
    self:GetModel(UserModel).ZoneID = Msg.ZoneId
end

---登录排队进度通知
function UserSocketLoginCtrl:LoginQueueSync(Msg)
    --CError(string.format("UserSocketLoginCtrl:LoginQueueSync 登录排队进度通知 Msg = %s", table.tostring(Msg)))
    CLog(string.format("UserSocketLoginCtrl:LoginQueueSync 登录排队进度通知 Msg = %s", table.tostring(Msg)))


    --[[
        这段逻辑只是临时兼容   非子系统登录（子系统登录界面LoginOnlineSubMdt已经接了排除逻辑）

        非子系统登录LoginPanelMdt后续需要接入正式排除流程，再将这段代码干掉
    ]]
    local NeedPopMessageBox = false
    if not MvcEntry:GetCtrl(OnlineSubCtrl):IsOnlineEnabled() then
        NeedPopMessageBox = true
    end
    if NeedPopMessageBox then
        local WarningDec = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Login', "1735") ---排队中...
        local describe = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"), Msg.CurrNum, Msg.TotalNum) ---{0}/{1}
        local msgParam = {
            describe = describe,
            warningDec = WarningDec,
            HideCloseBtn = true,
            HideCloseTip  = true,
            bRepeatShow = true,
        }
        UIMessageBox.Show(msgParam)
    end
    --//

    self:GetModel(LoginModel):DispatchType(LoginModel.ON_LOGINQUEUE_SYNC, Msg)
end

function UserSocketLoginCtrl:ON_PRE_LOAD_MAP_Func()
    self.PongValid = false
    self:CleanPingInfo()
end
function UserSocketLoginCtrl:ON_POST_LOAD_MAP_Func()
    self.PongValid = true
end

function UserSocketLoginCtrl:OnBracketLeftTrigger()
    if not self.OpenGMReconnect then
        return
    end
    if self.GMReconnectSwitch then
        return
    end
    if not self:CheckIsInGameScene() then
        UIAlert.Show("请不要在非游戏场景测试断线重连")
        return
    end
    self.GMReconnectSwitch = true
    self:OnNetError()
end
function UserSocketLoginCtrl:OnBracketRightTrigger()
    if not self.OpenGMReconnect then
        return
    end
    if not self:CheckIsInGameScene() then
        UIAlert.Show("请不要在非游戏场景测试断线重连")
        return
    end
    self.GMReconnectSwitch = false
end

function UserSocketLoginCtrl:DoLoginFinish(Msg)
    local TheUserModel = self:GetModel(UserModel)
    UE.UCrashSightHelper.SetUserId(Msg.PlayerId)
    TheUserModel:SetPlayerId(Msg.PlayerId)
    TheUserModel:SetGameToken(Msg.GameToken)
    self.TriedCount = 0;
end

--[[
    登录成功返回
]]
function UserSocketLoginCtrl:LoginRsp_Func(Msg)
    print_r(Msg, "UserSocketLoginCtrl:LoginRsp_Func")
    self:DoLoginFinish(Msg)
end

--[[
    快速重连返回
]]
function UserSocketLoginCtrl:ContinueRsp_Func(Msg)
    print_r(Msg)
    if Msg.ErrCode ~= 0 then
        CWaring(StringUtil.Format("UserSocketLoginCtrl:ContinueRsp_Func: error ID:{0}",Msg.ErrCode))
        --重连连接，不走重连，走普通登录
        self:OnNetError(UserSocketLoginCtrl.EReConnectType.NORMAL_USELOGIN)
    else
        self:ShowOrHideNetLoading(false)
        self.TriedCount = 0;
        if Msg.GameToken > 0 then
            self:GetModel(UserModel):SetGameToken(Msg.GameToken)
        else
            CWaring("UserSocketLoginCtrl:ContinueRsp_Func: GameToken <= 0")
        end
    end
end

--[[
    message GateVersionSync
    {
        string Stream       = 1;    // 分支信息:trunk、release、weekrun……
        string Changelist   = 2;    // 123456
        string ZoneName     = 3;    // 分区名
        string PackTime     = 4;    // gate打包时间
    }
]]
function UserSocketLoginCtrl:GateVersionSync_Func(Msg)
    Netlog.GateVersion=Msg.Stream .."_"..Msg.Changelist
    -- //
    self:GetModel(UserModel).GateVersion = Msg
    print_r(Msg,"GateVersionSync_Func:")
end

function UserSocketLoginCtrl:WaitCreatePlayerNotify_Func(Msg)
    self:GetModel(LoginModel):DispatchType(LoginModel.ON_STEP_LOGIN,LoginModel.SocketLoginStepTypeEnum.LOGIN_CREATE_PLAYER)
    self:ShowOrHideNetLoading(false)
    if self:GetModel(UserModel).IsLoginByCMD then
        self:AutoCreatePlayerInfo(Msg.UserId,self:GetModel(UserModel).CMDLoginName)
        return
    end
    if self:GetSingleton(OnlineSubCtrl):IsOnlineEnabled() then
        self:AutoCreatePlayerInfo(Msg.UserId,self:GetSingleton(OnlineSubCtrl):GetPlayerNickname())
        return
    end
    UIGameWorldTip.Hide()
    local Param = {
        UserId = Msg.UserId,
        Type = self:GetModel(LoginModel).NAMECHANGETYPE.CHANGENAME --修改昵称/创建角色
    }
    self:OpenView(ViewConst.NameInputPanel, Param)
end

--自动创建账号
function UserSocketLoginCtrl:AutoCreatePlayerInfo(UserId,PlayerNikeName)
    local req = {
        UserId = UserId,
        PlayerName = PlayerNikeName,
        HeadId = 0,
    }
    self:SendProto(Pb_Message.CreatePlayerReq, req,Pb_Message.CreatePlayerRsp)
end

--[[
    创建玩家成功返回
]]
function UserSocketLoginCtrl:CreatePlayerRsp_Func(Msg)
    print_r(Msg, "UserSocketLoginCtrl:CreatePlayerRsp_Func CreatePlayerRsp")
    if Msg.ErrorCode > 0 then
        self:GetModel(UserModel):DispatchType(UserModel.ON_PLAYER_CREATE_FAIL,Msg.ErrorCode)
    else
        -- 创角成功
        self:CloseView(ViewConst.NameInputPanel)
        print("On CreatePlayerRsp: userid=" .. Msg.UserId)
        self:DoLoginFinish(Msg)

        self:OnlineUpdateSelfHeadImage()
    end
end

--[[
    创角后，根据子系统情况，可以更新子系统的玩家头像进行设置
    （例如steam的玩家头像）
]]
function UserSocketLoginCtrl:OnlineUpdateSelfHeadImage()
    local TargetTexture = self:GetSingleton(OnlineSubCtrl):GetSelfAvatarTexture()
    if TargetTexture then
        local PictureIntType = HttpModel.Const_PictureIntType.PNG
        UE.UGFUnluaHelper.EncodeTextureToString(TargetTexture, PictureIntType,0, function(ImageData)
            if ImageData then
                local ActType = 1
                local PictureStringType = self:GetModel(HttpModel):GetPictureStringTypeByIntType(PictureIntType)
                self:GetSingleton(PersonalInfoCtrl):SendProto_UploadPortraitReq(ImageData, PictureStringType,ActType)
            else
                CError("UserSocketLoginCtrl:OnlineUpdateSelfHeadImage  ImageData is Nil")
            end
        end)
    end
end

function UserSocketLoginCtrl:PlayerBaseData_Func(Msg)
    print_r(Msg)

    local UModel = self:GetModel(UserModel)
    UModel.PlayerName = Msg.BaseData.Name
    UModel.Level = Msg.BaseData.Level
    UModel.Experience = Msg.BaseData.Experience
    UModel.PlayerId = Msg.BaseData.ID
    UModel.HeadId = Msg.BaseData.HeadId
    UModel.HeadFrameId = Msg.BaseData.HeadFrameId
    UModel.PortraitUrl = Msg.BaseData.PortraitUrl
    UModel.AuditPortraitUrl = Msg.BaseData.AuditPortraitUrl
    UModel.SelectPortraitUrl = Msg.BaseData.SelectPortraitUrl and true or false --有可能为nil
    UModel.PlayerCreateTime = Msg.BaseData.CreateTime
    CommonUtil.NetLogUserName(Msg.BaseData.Name .. "(".. Msg.BaseData.ID .. ")")
    _G.SaveGame.SetUid(UModel.PlayerId)

    local PersonalInfoModel = self:GetModel(PersonalInfoModel)
    PersonalInfoModel:SetPlayerHeadId(UModel.PlayerId, UModel.HeadId)
    PersonalInfoModel:SetPlayerCustomHeadInfo(UModel.PlayerId, UModel.PortraitUrl, UModel.AuditPortraitUrl, UModel.SelectPortraitUrl)
    PersonalInfoModel:SetPlayerHeadFrameId(UModel.PlayerId, UModel.HeadFrameId)

    --数数SDK设置帐号ID
    self:GetSingleton(TDAnalyticsCtrl):Login(UModel.PlayerId)
end

--[[
    登录&信息同步完成 进入大厅 触发:
    1. 正常登录 由PreloadViewLogic派发事件 PRELOAD_VIEW_PLAY_FINISH 通知
    2. 游戏内的断连 直接调用
    
]]
function UserSocketLoginCtrl:OnSyncPlayerDataSucFunc()
    CWaring("UserSocketLoginCtrl:Time3:" .. GetLocalTimestampMillisecondsUtc())
    self.CacheReconnectState = self.CacheReconnectState or UserSocketLoginCtrl.EReConnectType.NONE
    self:SendMessage(CommonEvent.ON_LOGIN_FINISHED, self.CacheReconnectState)
    local LoginParm = false
    if self.CacheReconnectState ~= UserSocketLoginCtrl.EReConnectType.NONE then
        LoginParm = self.CacheReconnectState
    end
    self:SendMessage(CommonEvent.ON_LOGIN_INFO_SYNCED,LoginParm)    -- OnLogin事件放到预加载完成后执行，避免触发同步加载block
    --置空
    self.CacheReconnectState = nil
    CWaring("UserSocketLoginCtrl:Time4:" .. GetLocalTimestampMillisecondsUtc())
end

function UserSocketLoginCtrl:SyncPlayerData_Func(Msg)
    self:GetModel(LoginModel):DispatchType(LoginModel.ON_STEP_LOGIN,LoginModel.SocketLoginStepTypeEnum.LOGIN_PLAYER_DATA_SYNC_COMPLETE)
    -- local LoginParm = false
    if self.ReConnectType ~= UserSocketLoginCtrl.EReConnectType.NONE then
        -- LoginParm = self.ReConnectType
        self:ShowActionTip(G_ConfigHelper:GetStrFromCommonStaticST("Lua_UserSocketLoginCtrl_Reconnectsuccessfull"))
    end
    self.TriedCount = 0
    self:ShowOrHideNetLoading(false)
    UIGameWorldTip.Hide()

    -- local LoginParm = false
    -- if self.ReConnectType ~= UserSocketLoginCtrl.EReConnectType.NONE then
    --     LoginParm = self.ReConnectType
    -- end
    CWaring("UserSocketLoginCtrl:Time:" .. GetLocalTimestampMillisecondsUtc())
    -- self:SendMessage(CommonEvent.ON_LOGIN_INFO_SYNCED,LoginParm)
    -- self:SendMessage(CommonEvent.ON_LOGIN_INFO_SYNCED_READY)
    -- 缓存的连接类型，供 :OnSyncPlayerDataSucFunc 使用
    self.CacheReconnectState = self.ReConnectType
    self:SendMessage(CommonEvent.RECONNECT_STATE, {State = 0})
    -- self:SendMessage(CommonEvent.ON_LOGIN_INFO_SYNCED_WITH_EVENT)
    --TODO 关闭重连提示界面，未做
    -- self:CloseView(ViewConst.ReconnectTip)
    self:ResetReConnectState(UserSocketLoginCtrl.EReConnectType.NONE)
    self:GetModel(UserModel).PlayerLoginFinished = true
    CWaring("UserSocketLoginCtrl:Time2:" .. GetLocalTimestampMillisecondsUtc())

    -- local TheLoginModel = self:GetModel(LoginModel)
    -- local ClientDHKeyInfo = TheLoginModel:GetClientDHKeyInfo()
    -- print_r(ClientDHKeyInfo,"ClientDHKeyInfo:")
    -- local ReqData = {
    --     ClientPubicKey = ClientDHKeyInfo.PublicKey,
    -- }
    -- self:SendProto(Pb_Message.DHKeyExchangeReq, ReqData)

    if CommonUtil.IsInGameScene() then
        -- 游戏内的断连 直接走原来的同步逻辑
        CWaring("== SyncPlayerData_Func IsInGameScene")
        self:OnSyncPlayerDataSucFunc()
    else
        -- 登录期间同步 走资源预加载
        CWaring("== SyncPlayerData_Func Not InGameScene")
        CLog("== DoPreload")
        MvcEntry:GetModel(PreLoadModel):DispatchType(PreLoadModel.START_PRELOAD)
        -- 目前GVoiceSDK初始化会有四五帧小卡，放在这里初始化让卡顿在预加载的表现中过度，后续待SDK解决再挪走
        MvcEntry:GetCtrl(GVoiceCtrl):DoSDKInit()
    end
end

--[[
    被服务器T出 返回
]]
function UserSocketLoginCtrl:Kickout_Func(Msg)
    CWaring("Kickout_Func")

    local debug = {
        Reason = Msg.Reason,
        ErrCode = Msg.ErrCode,
        ErrMsg = Msg.ErrMsg
    }
    GameLog.Dump(debug, debug)

    if Msg.ErrCode == 10135 then
        MvcEntry:GetCtrl(EventTrackingCtrl):ReqOnStepFlow(EventTrackingCtrl.LoginBeforEnum.StartPreventAddiction)
    end

    self:ShowOrHideNetLoading(false)
    local socketMgr = self:GetModel(SocketMgr)
    socketMgr:Close("Kickout")
    local ErrorDes = self:GetSingleton(ErrorCtrl):GetErrorTipByMsgInner(Msg.ErrCode,Msg.ErrMsg,Msg.ErrArgs)
    self:PopGameLogoutBoxTip(ErrorDes,true)
end


function UserSocketLoginCtrl:OnAppWillDeactivate()
    if CommonUtil.IsPlatform_Windows() then
        return
    end
    CWaring("OnAppWillDeactivate")
    self:OnAppFocusHandler(false)
end
function UserSocketLoginCtrl:OnAppHasReactivated()
    if CommonUtil.IsPlatform_Windows() then
        return
    end
    CWaring("OnAppHasReactivated")
    self:OnAppFocusHandler(true)
end

function UserSocketLoginCtrl:OnAppFocusHandler(Value)
    if not CommonUtil.g_in_play then
        -- CWaring("not g_in_play==================")
        return
    end
    if Value then
        if self.IsAppFocus == false then
            print("onAppFocusHandler=======================true")
            if self:GetModel(ViewModel):GetState(ViewConst.VirtualLogin) == false then
                -- 确保情况真的是从后台切前台且不在在登录场景   才能触发检测
                print("onAppFocusHandler true")
                self:CleanAppFocusDealyTimeout()
                -- 延迟一帧触发，确保如果有Socket onError onClose 的方法先触发。然后再触发检测逻辑
                self.AppFocusDelayTimerId = Timer.InsertTimer(-1, Bind(self, self.DelayAppFocusCheck))
            end
        end
        self.IsAppFocus = true
    else
        print("onAppFocusHandler=======================false")
        self:CleanPingInfo()
        self:CleanAppFocusDealyTimeout()
        self.SleepStartTime = GetLocalTimestamp()
        self.IsAppFocus = false
        self.IsAppDelayFocus = false
    end
end

function UserSocketLoginCtrl:CleanAppFocusDealyTimeout()
    if self.AppFocusDelayTimerId then
        Timer.RemoveTimer(self.AppFocusDelayTimerId)
        self.AppFocusDelayTimerId = nil
    end
end

function UserSocketLoginCtrl:DelayAppFocusCheck()
    print("DelayAppFocusCheck=======================")
    self:CleanAppFocusDealyTimeout()
    self.IsAppDelayFocus = true

    local GapTime = GetLocalTimestamp() - self.SleepStartTime
    self.SleepStartTime = GetLocalTimestamp()

    if GameConfig.TestReconnect() then
        self:OnNetError()
    else
        self:CheckAndTriggerSocketReconnect(GapTime)
    end
end

--[[
    检查网络状态
    如果网络连接不上，则触发Socket重连

    GapTime如果有值，则会额外判断休眠时间
]]
function UserSocketLoginCtrl:CheckAndTriggerSocketReconnect(GapTime)
    CWaring("UserSocketLoginCtrl:GapTime:" .. GapTime)
    local GapTime = GapTime or 0
    local GapTimeStatic = 60 * 15 -- 秒为单位
    local socketMgr = self:GetModel(SocketMgr)
    local GapTimeStaticFast = 30

    if socketMgr:IsConnected() then
        if GapTime > 0 and GapTime > GapTimeStatic then
            -- cc.log(getClassName(this), '休眠超過' + GapTime + '秒~~~~~~~~~~~~~~~~~~~~~~~:' + time)
            -- 休眠超过GapTime秒，切回来后重连
            self:OnNetError()
            return false
        else
            -- 发送心跳包，获取最新服务器时间
            self:OnPingTimer(0,true)
            return true
        end
    else
        self:OnNetError()
        return false
    end
end

--[[
    开始连接逻辑服
]]
function UserSocketLoginCtrl:ConnectToServer()
    self:ShowOrHideNetLoading(true)
    if self.TryTimerId then
        return
    end

    local socketMgr = self:GetModel(SocketMgr)
    local model = self:GetModel(UserModel)
    if socketMgr:IsConnected() then
        self:OnMainSocketConnect()
    else
        local DealyTime = self:GetConnectDelayTime()
        if DealyTime > 0 then
            self.TryTimerId = Timer.InsertTimer(self.TryDelayGap, function()
                self:TryConnectAction()
            end)
        else
            self:TryConnectAction()
        end
    end
end

-- Socket连接成功
function UserSocketLoginCtrl:OnMainSocketConnect()
    self:SendMessage(CommonEvent.ON_MAIN_SOCKET_CONNECTED)
    if not self:CheckIsInGameScene() then
        -- 不是在游戏中连上socket，开启登录到进游戏期间的界面拦截
        self:GetModel(HallModel):DispatchType(HallModel.ON_START_ENTERING_HALL)
    end
end

--[[
    第一次重连在0-2秒进行随机
    后续重连的间隔配的是5秒，走配置的，走3-5秒随机，你看一下能不能符合需求

    防止客户端同一时间重连对LBS等基础服务的冲击
]]
function UserSocketLoginCtrl:GetConnectDelayTime()
    local DelayTime = 0
    if self.TriedCount > 0 then
        local TheMin = self.TryDelayGap-2
        DelayTime = math.random(TheMin*100,self.TryDelayGap*100)/100.0
    else
        if self.ReConnectType ~= UserSocketLoginCtrl.EReConnectType.NONE then
            DelayTime = math.random(0,2*100)/100.0
        end
    end
    CWaring("UserSocketLoginCtrl:GetConnectDelayTime:" .. DelayTime)
    return DelayTime
end

--[[
    开始连接逻辑服-inner
]]
function UserSocketLoginCtrl:TryConnectAction()
    if self.TryTimerId then
        Timer.RemoveTimer(self.TryTimerId)
        self.TryTimerId = nil
    end
    local TheSocketMgr = self:GetModel(SocketMgr)
    self.TriedCount = self.TriedCount + 1
    if self.TriedCount <= self.TryCount or self.TryCount <= 0 then
        CWaring("tryConnectAction:" .. self.TriedCount)

        if not self.GMReconnectSwitch then
            local TheUserModel = self:GetModel(UserModel)
            TheSocketMgr:Connect(TheUserModel.Ip, TheUserModel.Port)
        else
            --self.GMReconnectSwitch 为真时，不允许Socket连接，延时0.5秒后模拟再次连接
            Timer.InsertTimer(0.5,function ()
                self:OnNetError()
            end)
        end
    else
        self:ShowOrHideNetLoading(false)
        self:PopGameLogoutBoxTip(G_ConfigHelper:GetStrFromCommonStaticST("Lua_UserSocketLoginCtrl_Theserverisdisconnec"))
        CWaring("##UserSocketLoginCtrl:TryConnectAction: 重连失败,暂停尝试")
    end
end

--[[
    游戏主Socket连接成功
]]
function UserSocketLoginCtrl:OnConnectedHandler()
    -- Socket连接成功，请求登录
    -- self:SendMessage(CommonEvent.ON_MAIN_SOCKET_CONNECTED)
    self:OnMainSocketConnect()
    self:StartPingTimer()
    local socketMgr = self:GetModel(SocketMgr)
    if socketMgr and socketMgr.SocketStream then
        local TheUserModel = self:GetModel(UserModel)
        local TheLoginModel = self:GetModel(LoginModel)
        if self.ReConnectType == UserSocketLoginCtrl.EReConnectType.NONE or self.ReConnectType == UserSocketLoginCtrl.EReConnectType.NORMAL_USELOGIN then
            --TODO 走正常登录流程
            if self:GetModel(LoginModel):IsSDKLogin() then
                --TODO SDK的登录接口
                -- // SDK登录
                local ReqData = {
                    UserId = TheUserModel.SdkOpenId,
                    Token = TheUserModel:GetToken(),
                    ClientInfo = TheLoginModel:GetLoginClientInfo(),
                    AccountInfo = TheLoginModel:GetLoginAccountInfo(),
                    DeviceInfo = TheLoginModel:GetLoginDeviceInfo(),
                    LocationInfo = TheLoginModel:GetLoginLocationInfo(),
                }
                print_r(ReqData,"GSDKLoginReq:")
                self:SendProto(Pb_Message.SDKLoginReq, ReqData)
                -- self:PopGameLogoutBoxTip("登录SDK还未接入,暂无此功能")
            else
                --TODO 非SDK登录接口
                local req = {
                    UserId = TheUserModel.SdkOpenId,
                    ClientInfo = TheLoginModel:GetLoginClientInfo(),
                    DeviceInfo = TheLoginModel:GetLoginDeviceInfo(),
                    LocationInfo = TheLoginModel:GetLoginLocationInfo(),
                    AccountInfo = TheLoginModel:GetLoginAccountInfo(),
                }
                print_r(req,"DevLoginReq:")
                self:SendProto(Pb_Message.DevLoginReq, req)
            end
        else
            --这里暂时不需要区分快速和普连，服务器逻辑没有支撑，都视做普通重连处理
            local req = {
                UserId = TheUserModel.SdkOpenId,
                PlayerId = TheUserModel:GetPlayerIdReConnect(),
                GameToken = TheUserModel:GetPlayerGameTokenReConnect(),
                ClientInfo = TheLoginModel:GetLoginClientInfo(),
                AccountInfo = TheLoginModel:GetLoginAccountInfo(),
                DeviceInfo = TheLoginModel:GetLoginDeviceInfo(),
                LocationInfo = TheLoginModel:GetLoginLocationInfo(),
            }
            print_r(req,"ContinueReq:")
            self:SendProto(Pb_Message.ContinueReq, req)
        end
    else
        CWaring("UserSocketLoginCtrl:OnConnectedHandler:Socket ERROR")
    end
end

function UserSocketLoginCtrl:OnClosedHandler()
    -- 可添加重连逻辑
    CWaring("onClosedHandler=======================")
    self:OnSocketCloseOrError()
end

function UserSocketLoginCtrl:OnErrorHandler()
    CWaring("OnErrorHandler=======================")
    self:OnSocketCloseOrError()
end

function UserSocketLoginCtrl:OnSocketCloseOrError()
    self:OnNetError()
end

--[[
    清除定时器
]]
function UserSocketLoginCtrl:CleanNetErrorTimer()
    if self.NetErrorTimerId then
        Timer.RemoveTimer(self.NetErrorTimerId)
        self.NetErrorTimerId = nil
    end
end

--[[
    检查玩家是否在游戏中
]]
function UserSocketLoginCtrl:CheckIsInGameScene()
    return CommonUtil.IsInGameScene()
end

--[[
    检查玩家是否已经在战斗场景
]]
function UserSocketLoginCtrl:CheckIsInBattle()
    return CommonUtil.IsInBattle()
end

function UserSocketLoginCtrl:OnNetError(ReConnectType, tip)
    -- if self:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
    --     --局内状态时，不处理跟大厅的Socket重连
    --     --等局内回来时，进行检查
    --     return
    -- end
    if self.NetErrorTimerId then
        return
    end
    ReConnectType = ReConnectType or UserSocketLoginCtrl.EReConnectType.NORMAL
    -- 是否在游戏场景(不在欢迎场景)
    if not self:CheckIsInGameScene() then
        -- 欢迎界面强制将重连选项置空,不属于重连状态
        ReConnectType = UserSocketLoginCtrl.EReConnectType.NONE
    end
    self:ResetReConnectState(ReConnectType)

    self:StopPingTimer();
    self:CleanPingInfo()
    self:ShowOrHideNetLoading(true)
    self.NetErrorTimerId = Timer.InsertTimer(0.1, Bind(self, self.OnNetErrorHandler, tip))
end

function UserSocketLoginCtrl:ResetReConnectState(value)
    self.ReConnectType = value
    CLog("self.ReConnectType:" .. self.ReConnectType)
end

function UserSocketLoginCtrl:RECONNECT_STATE_func(Param)
    if not Param then
        return
    end
    local TheCanDispatch = Param.State == 0 and true or false
    local NeedCleanCahhe = Param.CleanCache or false
    if GameEventDispatcher.dispatchers then
        for k, v in pairs(GameEventDispatcher.dispatchers) do
            if NeedCleanCahhe then
                v:CleanCacheDispatchInfos()
            end
            v:SetCanDispatch(TheCanDispatch)
        end
    end
end

function UserSocketLoginCtrl:OnNetErrorHandler(Tip)
    self:CleanNetErrorTimer()
    self:CleanPingInfo()
    -- self:ShowOrHideNetLoading(false)

    if self.IsAppDelayFocus then
        if Tip then
            self:PopGameLogoutBoxTip(Tip)
        else
            self:ReConnect()
        end
    end
end

--[[
    等待预加载行为完成，再触发重连
]]
function UserSocketLoginCtrl:OnPreloadFinishThenReconnect(Step)
    if not self:GetModel(PreLoadModel):IsPreloadWorking() then
        CWaring("UserSocketLoginCtrl:OnPreloadFinishThenReconnect DO_PRELOADING Finish,Trigger ReConnect")
        self:GetModel(PreLoadModel):RemoveListener(PreLoadModel.DO_PRELOADING,self.OnPreloadFinishThenReconnect,self)
        self:ReConnect()
    end
end

function UserSocketLoginCtrl:ReConnect()
    if self:GetSingleton(CommonCtrl):IsPoppingServerCloseTip() then
        --当前已有网络错误提示在显示，跳过重连逻辑
        return
    end
    if self:GetModel(PreLoadModel):IsPreloadWorking() then
        --正在预加载，添加预加载结束监听，等其结束再触发重连
        CWaring("UserSocketLoginCtrl:ReConnect IsPreloadWorking true,So Break Reconnect")
        self:GetModel(PreLoadModel):AddListener(PreLoadModel.DO_PRELOADING,self.OnPreloadFinishThenReconnect,self)
        return
    end
    if self.ReConnectType ~= UserSocketLoginCtrl.EReConnectType.NONE then
        local TheTip = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_UserSocketLoginCtrl_Reconnectingfortheti"),self.TriedCount)
        CWaring(TheTip)
        if self.ReConnectType == UserSocketLoginCtrl.EReConnectType.NORMAL then
            self:SendMessage(CommonEvent.RECONNECT_STATE, {State = 1})
        elseif self.ReConnectType == UserSocketLoginCtrl.EReConnectType.NORMAL_USELOGIN then
            self:SendMessage(CommonEvent.RECONNECT_STATE, {State = 1,CleanCache = true})
        end
        local param = {
            ReConnectType = self.ReConnectType
        }

        --测试用
        self:ShowActionTip(TheTip)
    end
    self:ReConnectSocket()
end

function UserSocketLoginCtrl:ReConnectSocket()
    -- self:ShowOrHideNetLoading(false)
    local TheSocketMgr = self:GetModel(SocketMgr)
    TheSocketMgr:Close(nil,true)
    local LogoutParm = false
    if self.ReConnectType ~= UserSocketLoginCtrl.EReConnectType.NONE then
        LogoutParm = self.ReConnectType
    end
    self:SendMessage(CommonEvent.ON_RECONNECT_LOGOUT, LogoutParm)
    self:SendMessage(CommonEvent.CONNECT_TO_MAIN_SOCKET)
end



--[[
    开始心跳包
    
    开始心跳包时机：Socket连接成功并且加密握手之后
]]
function UserSocketLoginCtrl:StartPingTimer()
    if not self.PingTimerId then
        self:OnPingTimer();
        self.PingTimerId = Timer.InsertTimer(self.PingTimeGap,Bind(self,self.OnPingTimer),true)
    end	
end

--[[
    停止心跳包
]]
function UserSocketLoginCtrl:StopPingTimer()
    if self.PingTimerId  then
        Timer.RemoveTimer(self.PingTimerId)
    end
    self.PingTimerId = nil
end

-- 清除心跳包相关及网络坏点数量
function UserSocketLoginCtrl:CleanPingInfo()
    self:CleanSimulateTimerId(nil)
    self.NetBadCount = 0
    self.PongId2Working = {}
end

function UserSocketLoginCtrl:GetAutoIncrementPongId()
    self.PongIdIncrement = self.PongIdIncrement + 1
	if self.PongIdIncrement >= math.maxinteger then
		self.PongIdIncrement = 1
	end
    return self.PongIdIncrement
end

--[[
    发送心跳包
]]
function UserSocketLoginCtrl:OnPingTimer(DeltaTime,BACK_FOREGROUND)
    if BACK_FOREGROUND then
        print_trackback()
    end
    -- CWaring("----------OnPingTimer")
    if not self.PongValid then
        CWaring("----------OnPingTimer PongValid false")
        return
    end
    local LastPingTimestampMilliseconds = GetLocalTimestampMillisecondsUtc()
    local PongId = self:GetAutoIncrementPongId()
    self.PongId2Working[PongId] = true
    local Msg = {
        ClientTimestamp = LastPingTimestampMilliseconds,
        PingIndex = PongId,
    }
    self:SendProto(Pb_Message.HeartbeatReq, Msg)

    CWaring("----------OnPingTimer111")
    --[[
        5秒后模拟一个心跳回包 防止出现网络阻塞包的状况而导致网络状态不更新
    ]]
    self.PongId2SimulateTimerId[PongId] = Timer.InsertTimer(self.PongSimulateTime,Bind(self,self.OnSimulateTimer,BACK_FOREGROUND,PongId,LastPingTimestampMilliseconds))
    CWaring("----------OnPingTimer222")
    if BACK_FOREGROUND then
        self.NetBadCount = self.NetBadCountMax - 2
    end
end

-- 模拟心跳包返回
function UserSocketLoginCtrl:OnSimulateTimer(BACK_FOREGROUND,PongId,LastPingTimestampMilliseconds)
    self.PongId2Working[PongId] = nil
    if BACK_FOREGROUND then
        -- 从后台返回前台  如果心跳包超时，则重连
        CWaring("onPingTimer out of time====================================")
        local TheSocketMgr = self:GetModel(SocketMgr)
        TheSocketMgr:Close(nil,true)
        self:OnNetError()
    else
        self:OnPongHandler(nil,PongId,LastPingTimestampMilliseconds)
    end
end

--[[
    心跳包返回
]]
function UserSocketLoginCtrl:OnPongHandler(Msg,PongId,LastPingTimestampMilliseconds)
    -- CWaring("----------OnPongHandler")
    LastPingTimestampMilliseconds = Msg and Msg.ClientTimestamp or LastPingTimestampMilliseconds
    PongId = Msg and Msg.PingIndex or PongId
    self:CleanSimulateTimerId(PongId)

    if not self.PongId2Working[PongId] then
        CWaring("OnPongHandler PongId not valid:" .. PongId)
        return
    end
    self.PongId2Working[PongId] = nil
   
    local ReceiveTimePing = GetLocalTimestampMillisecondsUtc()
    if LastPingTimestampMilliseconds ~= 0 then
        local GapTime = ReceiveTimePing - LastPingTimestampMilliseconds
        if GapTime < (self.GoodTime*1000) then
            print("onPongHandler good")
            self:CleanNetBadCount()
        elseif GapTime < (self.NormalTime*1000) then
            print("onPongHandler normal")
            self:CleanNetBadCount()
        else
            print("onPongHandler bad")
            self:AddNetBadCount()
        end
    end

    if Msg then
        -- print_r(Msg)
        -- CWaring("proto.Time 101：" .. msgBody.Time)
        local ServerTimestamp = Msg.ServerTimestamp
        SetTimestampOffsetMilliseconds(ServerTimestamp - LastPingTimestampMilliseconds)
        local LocalUtcString = TimeUtils.DateTimeStr_FromTimeStamp(ReceiveTimePing//1000)
        local SeverUtcString = TimeUtils.DateTimeStr_FromTimeStamp(ServerTimestamp//1000)
        print("pongRes()==>","本地时间: " .. ReceiveTimePing .. "(" .. tostring(LocalUtcString) .. " UTC0)" , "返回服务器时间: " .. ServerTimestamp .. "(" .. tostring(SeverUtcString) .. " UTC0)")
    end
    self:CalculateNetDelay(LastPingTimestampMilliseconds)
end

--[[
    计算网络延迟
]]
function UserSocketLoginCtrl:CalculateNetDelay(LastPingTimestampMilliseconds)
    local CurTImestampMillseconds = GetLocalTimestampMillisecondsUtc()
    if CurTImestampMillseconds > LastPingTimestampMilliseconds then
        local TheUserModel = self:GetModel(UserModel)
        TheUserModel.NetDelayTime = CurTImestampMillseconds - LastPingTimestampMilliseconds
        CWaring("UserModel.NetDelayTime:" .. TheUserModel.NetDelayTime)
    end
end

function UserSocketLoginCtrl:CleanNetBadCount()
    self.NetBadCount = 0
end

function UserSocketLoginCtrl:AddNetBadCount()
    self.NetBadCount = self.NetBadCount + 1

    if self.NetBadCount >= self.NetBadCountMax then
        self:CleanPingInfo()
        -- self:PopGameLogoutBoxTip(StringUtil.FormatText("网络状况不佳，请重新连接！"))

        --尝试进行重连
        self:OnNetError()
    end
end

function UserSocketLoginCtrl:CleanSimulateTimerId(PongId)
    if PongId then
        if self.PongId2SimulateTimerId[PongId] then
            Timer.RemoveTimer(self.PongId2SimulateTimerId[PongId])
            self.PongId2SimulateTimerId[PongId] = nil
        end
    else
        for k,v in pairs(self.PongId2SimulateTimerId) do
            Timer.RemoveTimer(v)
        end
        self.PongId2SimulateTimerId = {}
    end
end

-- 认证失败同步
function UserSocketLoginCtrl:OnAuthFailSync(InData)
    Error("UserSocketLoginCtrl", ">> OnAuthFailSync!!!")
    if InData  ~= 0 then
        CWaring(StringUtil.Format("ErrorCode:{0}, ErrorMsg:{1}, SdkMsg={2}, SdkLogId={3}",InData.ErrCode, InData.ErrMsg, InData.SdkMsg, InData.SdkLogId))
        local Param = { describe = InData.SdkMsg }
        UIMessageBox.Show(Param)
        return
    end
end

function UserSocketLoginCtrl:SetTriedCount(Value)
    self.TriedCount = Value
end

--[[
    重新封装一下NetLoading的显示

    在战斗中静默
]]
function UserSocketLoginCtrl:ShowOrHideNetLoading(IsShow)
    if not IsShow then
        NetLoading.Close()
    else
        if self:CheckIsInBattle() then
            --战斗场景静默
            return
        end
        if self:GetModel(ViewModel):GetState(ViewConst.OnlineSubLoginPanel) then
            --子系统加载界面静默
            return
        end
        local IsReConnect = self.ReConnectType ~= UserSocketLoginCtrl.EReConnectType.NONE
        if IsReConnect then
            NetLoading.AddReconnectPopup()
        else
            NetLoading.Add(nil, nil, nil, 0)
        end
    end
end

--[[
    重新封装一下PopGameLogoutBoxTip的显示

    在战斗中静默
]]
function UserSocketLoginCtrl:PopGameLogoutBoxTip(Msg,SkipBattleCheck)
    --战斗中也依赖跟大厅服的连接，战斗中socket断开，需要提示
    -- if not SkipBattleCheck and self:CheckIsInBattle() then
    --     --战斗场景静默
    --     return
    -- end
    self:GetSingleton(CommonCtrl):PopGameLogoutBoxTip(Msg)
end

--[[
    重新封装一下UIAlert的显示

    在战斗中静默
]]
function UserSocketLoginCtrl:ShowActionTip(Msg)
    if self:CheckIsInBattle() then
        --战斗场景静默
        return
    end
    if CommonUtil.IsShipping() then
        --Shipping版本不进行提示
        return
    end
    UIAlert.Show(Msg)
end

function UserSocketLoginCtrl:SetIsOpenGMReconnect(Value)
    self.OpenGMReconnect = Value
end

--[[
    跨天逻辑  及 新版本热更新逻辑，需要后续接入
]]
function UserSocketLoginCtrl:SyncCommonDayRefresh(msgBody)
    --TODO 跨天逻辑
    CLog("UserSocketLoginCtrl:SyncCommonDayRefresh")
    MvcEntry:SendMessage(CommonEvent.ON_COMMON_DAYREFRESH);
end

function UserSocketLoginCtrl:ClientUpdateSync_Func(MsgBody)
    --TODO 存在新版本热更新  逻辑未处理
    -- // 客户端热更新通知
    -- message ClientUpdateSync{
    --     string  ClientVersion  = 1;
    --     string  ActType         = 2;
    -- }
    print_r(MsgBody,"UserSocketLoginCtrl:ClientUpdateSync_Func")
    if UE.UGFUnluaHelper.IsEditor() then
        return
    end

    local CAppVersion = self:GetModel(UserModel):GetAppVersion()
    local SAppVersion = MsgBody.ClientVersion

    -- CAppVersion = "1.0.0.2"

    local CAppVersionList = string.split(CAppVersion,".")
    local SAppVersionList = string.split(SAppVersion,".")


    if #CAppVersionList ~= #SAppVersionList then
        CWaring(StringUtil.FormatSimple("UserSocketLoginCtrl:ClientUpdateSync_Func Version Len not equal,CVersion:{0},SVersion:{1}",CAppVersion,SAppVersion))
        return
    end
    local IsServerBig = false
    for i=1,#CAppVersionList do
        local SNum = tonumber(SAppVersionList[i])
        local CNum = tonumber(CAppVersionList[i])
        if SNum == nil or CNum == nil then
            CWaring(StringUtil.FormatSimple("UserSocketLoginCtrl:ClientUpdateSync_Func Version invalid,CVersion:{0},SVersion:{1}",CAppVersion,SAppVersion))
            return
        end
        if SNum > CNum then
            IsServerBig = true
            break
        elseif SNum < CNum then
            IsServerBig = false
            break
        end
    end
    if not IsServerBig then
        return
    end
    --TODO 弹窗提示
    self:GetSingleton(CommonCtrl):TryFaceActionOrInCache(function ()
        local describe = G_ConfigHelper:GetStrTableRow("/Game/Maps/Login/HotUpdate/DataTable/SD_HotUpdate.SD_HotUpdate", "InGameFoundUpdateTip")
        -- local describe = "发现热更新，是否退出游戏进行更新"
        local msgParam = {
            describe = describe,
            rightBtnInfo = {
                callback = function()
                    UE.UKismetSystemLibrary.QuitGame(GameInstance,CommonUtil.GetLocalPlayerC(),UE.EQuitPreference.Quit,true)
                end
            },
            -- leftBtnInfo = {},
            HideCloseBtn = true,
            HideCloseTip = true,
        }
        UIMessageBox.Show(msgParam) 
    end)
end

