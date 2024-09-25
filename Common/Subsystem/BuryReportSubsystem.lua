--[[
    埋点信息上报子系统
]]
require("InGame.Protocal.LobbyProtocalHelper")
local TablePool = require("Common.Utils.TablePool")
local BuryReportSubsystem = Class()

--每间隔X秒会触发埋点Cache信息上传
local TimerOut = 30
--Cahce信息数超过X条，会触发埋点Cache信息上传
local CacheCountMax = 10
--[[
    针对客户端环境:
        需要将目前的Cache信息立即发送，清除cache
            1.玩家登出
            2.战斗结束
    针对SDK直接上报(--目前只应用在埋点,所以公参只处理局外的)：
        需要针对玩家登录后，设置公参
        需要针对局内外，更新公参：
            玩家等级改变
            玩家VIP等级改变
            玩家名称改变
    针对编辑器环境，需要取消上报
]]
local BuryTypeEnum = {
    CLIENT = 1,
    DS = 2,
    CLIENT_SDK = 3,   --目前只应用在埋点
}

local TmpProfile = require("Common.Utils.InsightProfile")
local PoolTagName = "BuryReportSubsystem"

--[[
    初始化
]]
function BuryReportSubsystem:ReceiveInitialize()
    self.Overridden.ReceiveInitialize(self)
    CWaring("BuryReportSubsystem:ReceiveInitialize")
    TablePool.PreFetch(PoolTagName,30)
    self.EventName2MiscInfo = TablePool.Fetch(PoolTagName)
    --依赖框架初始化后，再执行逻辑
    CommonUtil.DoMvcEntyAction(function ()
        if not CommonUtil.IsDedicatedServer() then
            --客户端
            MvcEntry:AddMsgListener(CommonEvent.ON_PRE_ENTER_BATTLE,       self.OnPreEnterBattleHandler,    self)
            MvcEntry:AddMsgListener(CommonEvent.ON_PRE_BACK_TO_HALL,       self.OnPreBackToHallHandler,    self)
            -- MvcEntry:AddMsgListener(CommonEvent.ON_MAIN_LOGOUT, self.OnLogoutHandler, self);
            MvcEntry:GetModel(SocketMgr):AddListener(SocketMgr.CMD_ON_MANUAL_CLOSED_PRE,self.Socket_ON_MANUAL_CLOSED_PRE_Func,self)
            -- MvcEntry:AddMsgListener(CommonEvent.ON_MAIN_LOGOUT, self.OnLogoutHandler, self);
            MvcEntry:AddMsgListener(CommonEvent.ON_LOGIN_INFO_SYNCED, self.OnLoginHandler, self);
    
            --[[
                玩家帐号设置完成
                玩家等级改变
                玩家VIP等级改变 未制作
                玩家名称改变
            ]]
            MvcEntry:GetModel(UserModel):AddListener(UserModel.ON_OPEN_ID_SET,self.ON_OPEN_ID_SET_Func,self)
            MvcEntry:GetModel(UserModel):AddListener(UserModel.ON_PLAYER_LV_CHANGE,self.ON_PLAYER_LV_CHANGE_Func,self)
            MvcEntry:GetModel(UserModel):AddListener(UserModel.ON_MODIFY_NAME_SUCCESS,self.ON_MODIFY_NAME_SUCCESS_Func,self)
        else
            TablePool.PreFetch(PoolTagName,100)
            --DS  
            --[[
                添加DS关闭通知
            ]]
            -- MvcEntry:GetModel(DSServerModel):AddListener(DSServerModel.ON_DEDICATED_SERVER_END,self.ON_DEDICATED_SERVER_END_Func,self)
            MvcEntry:GetModel(DSServerModel):AddListener(DSServerModel.ON_DEDICATED_GAMEOVER,self.ON_DEDICATED_GAMEOVER_Func,self)

            -- todo 暂时注释，DS里调用的时候，ListenObjectMessage为nil，引发崩溃 @chenyishui
            -- self.MsgListTmp = {
            --     { InBindObject = self,	MsgName = "GameStage.OnGameOverEvent",Func = Bind(self,self.OnGameOverEventFunc), bCppMsg = true, WatchedObject = nil },
            -- }
            -- CommonUtil.MsgGMPRegisterOrUnRegister(self.MsgListTmp,true)
        end
    end)
end
function BuryReportSubsystem:ReceiveDeinitialize()
    self.Overridden.ReceiveDeinitialize(self)
    CWaring("BuryReportSubsystem:ReceiveDeinitialize")
    if MvcEntry then
        if not CommonUtil.IsDedicatedServer() then
            MvcEntry:RemoveMsgListener(CommonEvent.ON_PRE_ENTER_BATTLE,       self.OnPreEnterBattleHandler,    self)
            MvcEntry:RemoveMsgListener(CommonEvent.ON_PRE_BACK_TO_HALL,       self.OnPreBackToHallHandler,    self)
            -- MvcEntry:RemoveMsgListener(CommonEvent.ON_MAIN_LOGOUT, self.OnLogoutHandler, self);
            MvcEntry:GetModel(SocketMgr):RemoveListener(SocketMgr.CMD_ON_MANUAL_CLOSED_PRE,self.Socket_ON_MANUAL_CLOSED_PRE_Func,self)
            MvcEntry:RemoveMsgListener(CommonEvent.ON_LOGIN_INFO_SYNCED, self.OnLoginHandler, self);

            MvcEntry:GetModel(UserModel):RemoveListener(UserModel.ON_OPEN_ID_SET,self.ON_OPEN_ID_SET_Func,self)
            MvcEntry:GetModel(UserModel):RemoveListener(UserModel.ON_PLAYER_LV_CHANGE,self.ON_PLAYER_LV_CHANGE_Func,self)
            MvcEntry:GetModel(UserModel):RemoveListener(UserModel.ON_MODIFY_NAME_SUCCESS,self.ON_MODIFY_NAME_SUCCESS_Func,self)
        else
            -- MvcEntry:GetModel(DSServerModel):RemoveListener(DSServerModel.ON_DEDICATED_SERVER_END,self.ON_DEDICATED_SERVER_END_Func,self)
            MvcEntry:GetModel(DSServerModel):RemoveListener(DSServerModel.ON_DEDICATED_GAMEOVER,self.ON_DEDICATED_GAMEOVER_Func,self)
            -- CommonUtil.MsgGMPRegisterOrUnRegister(self.MsgListTmp,false)
        end
        self:RemoveReporyBuryTimer()
    end
end


--即将进入战斗
function BuryReportSubsystem:OnPreEnterBattleHandler()
    --需要将目前的Cache信息立即发送，清除cache
    self:FlushBuryCache("BuryReportSubsystem:OnPreEnterBattleHandler EventName2MiscInfo:")
end
--即将进入大厅
function BuryReportSubsystem:OnPreBackToHallHandler()
    --需要将目前的Cache信息立即发送，清除cache
    self:FlushBuryCache("BuryReportSubsystem:OnPreBackToHallHandler EventName2MiscInfo:")
end
-- function BuryReportSubsystem:OnLogoutHandler()
--     --需要将目前的Cache信息立即发送，清除cache
--     self:FlushBuryCache("BuryReportSubsystem:OnLogoutHandler EventName2MiscInfo:")
-- end
function BuryReportSubsystem:Socket_ON_MANUAL_CLOSED_PRE_Func()
    --需要将目前的Cache信息立即发送，清除cache
    self:FlushBuryCache("BuryReportSubsystem:Socket_ON_MANUAL_CLOSED_PRE_Func EventName2MiscInfo:")
end
function BuryReportSubsystem:OnLoginHandler()
    --TOD 重新设置SDK上报公参
    local TheUserModel = MvcEntry:GetModel(UserModel)
    local TheTDCtrl = MvcEntry:GetCtrl(TDAnalyticsCtrl)
    local LoginAccountInfo = MvcEntry:GetModel(LoginModel):GetLoginAccountInfo()
    local TheSeasonModel = MvcEntry:GetModel(SeasonModel)

    local Lv,Exp = TheUserModel:GetPlayerLvAndExp()

    local SuperProperties = {}
    SuperProperties.svr_version = TheUserModel:GetGatewayP4Show()
    SuperProperties.open_id = TheUserModel:GetSdkOpenId()
    SuperProperties.app_id = TheTDCtrl:GetAppId()
    SuperProperties.create_role_time = TheUserModel:GetPlayerCreateTime()
    SuperProperties.role_id = TheUserModel:GetPlayerId()
    SuperProperties.server_id = TheUserModel:GetServerId()
    SuperProperties.login_channel = LoginAccountInfo.ChannelId
    SuperProperties.vip_level = 1
    SuperProperties.season_id = TheSeasonModel:GetCurrentSeasonId()
    SuperProperties.role_level = Lv
    SuperProperties.role_name = TheUserModel:GetPlayerName()

    self:SetSuperPropertiesInner(SuperProperties)
end


--[[
    DS结算成功
]]
function BuryReportSubsystem:OnGameOverEventFunc()
    self:TryPrintLog("BuryReportSubsystem:OnGameOverEventFunc")
    Timer.InsertTimer(1,function ()
        self:TryPrintLog("BuryReportSubsystem:OnGameOverEventFunc2")
        self:FlushBuryCacheByTick("BuryReportSubsystem:OnGameOverEventFunc EventName2MiscInfo:",true)
    end)
end

-- --[[
--     DS关闭成功
-- ]]
-- function BuryReportSubsystem:ON_DEDICATED_SERVER_END_Func()
--     -- 暂时不运行了，改由OnGameOverEventFunc 驱动分帧上报
--     -- self:FlushBuryCache("BuryReportSubsystem:ON_DEDICATED_SERVER_END_Func EventName2MiscInfo:")
-- end
--[[
    DS玩法游戏结束通知,将Cache信息进行分帧发送
]]
function BuryReportSubsystem:ON_DEDICATED_GAMEOVER_Func()
    self:TryPrintLog("BuryReportSubsystem:ON_DEDICATED_GAMEOVER_Func")
    Timer.InsertTimer(1,function ()
        self:TryPrintLog("BuryReportSubsystem:ON_DEDICATED_GAMEOVER_Func2")
        self:FlushBuryCacheByTick("BuryReportSubsystem:ON_DEDICATED_GAMEOVER_Func EventName2MiscInfo:")
        --强制设置CacheCountMax为0，不生效Cache逻辑，有值则触发发送
        CacheCountMax = 0
    end)
end

function BuryReportSubsystem:FlushBuryCacheByTick(PrintTip,NeedPrintMiscInfo)
    if not PrintTip then
        PrintTip = "BuryReportSubsystem:FlushBuryCache EventName2MiscInfo:"
    end
    self:TryPrintLog(PrintTip)
    if self:IsTickSendTimerExist() then
        self:TryPrintLog("BuryReportSubsystem:FlushBuryCacheByTick IsTickSendTimerExist true,Break")
        return
    end
    --需要将目前的Cache进行分帧上报
    if self.CacheNeedSendList and #self.CacheNeedSendList > 0 then
        self.TickIndex2CacheList = TablePool.Fetch(PoolTagName)
        local TickSendNumUnit = 2
        local TickIndex = 1
        for k,v in ipairs(self.CacheNeedSendList) do
            self.TickIndex2CacheList[TickIndex] = self.TickIndex2CacheList[TickIndex] or {}
            local Length = #self.TickIndex2CacheList[TickIndex]
            self.TickIndex2CacheList[TickIndex][Length + 1] = v 
            if (Length + 1) >= TickSendNumUnit then
                TickIndex = TickIndex + 1
            end
        end
        TablePool.Recycle(PoolTagName,self.CacheNeedSendList)
        self.CacheNeedSendList = nil
        CWaring("BuryReportSubsystem:FlushBuryCacheByTick TickIndex:" .. TickIndex)
        self:AddTickSendTimer();
    end

    if NeedPrintMiscInfo then
        self:TryPrintTable(self.EventName2MiscInfo)
        self:RecycleTable(self.EventName2MiscInfo,PoolTagName)
        self.EventName2MiscInfo = TablePool.Fetch(PoolTagName)
    end
end

function BuryReportSubsystem:FlushBuryCache(PrintTip)
    if not PrintTip then
        PrintTip = "BuryReportSubsystem:FlushBuryCache EventName2MiscInfo:"
    end
    self:TryPrintLog(PrintTip)
    --需要将目前的Cache信息立即发送，清除cache
    if self.CacheNeedSendList and #self.CacheNeedSendList > 0 then
        self:OnReportBuryActionTriggerInner(self.CacheNeedSendList)
        TablePool.Recycle(PoolTagName,self.CacheNeedSendList)
        self.CacheNeedSendList = nil
    end

    self:TryPrintTable(self.EventName2MiscInfo)
    self:RecycleTable(self.EventName2MiscInfo,PoolTagName)
    self.EventName2MiscInfo = TablePool.Fetch(PoolTagName)
end


--[[
    玩家设置帐号
]]
function BuryReportSubsystem:ON_OPEN_ID_SET_Func()
    local TheUserModel = MvcEntry:GetModel(UserModel)
    local SdkOpenId = TheUserModel:GetSdkOpenId()

    CWaring("BuryReportSubsystem:ON_OPEN_ID_SET_Func SdkOpenId:" .. SdkOpenId)
    local SuperProperties = {}
    SuperProperties.open_id = SdkOpenId

    self:SetSuperPropertiesInner(SuperProperties)
end

--[[
    玩家等级发生变化
]]
function BuryReportSubsystem:ON_PLAYER_LV_CHANGE_Func()
    local TheUserModel = MvcEntry:GetModel(UserModel)
    local Lv,Exp = TheUserModel:GetPlayerLvAndExp()

    local SuperProperties = {}
    SuperProperties.role_level = Lv

    self:SetSuperPropertiesInner(SuperProperties)
end
--[[
    玩家名称发生变化
]]
function BuryReportSubsystem:ON_MODIFY_NAME_SUCCESS_Func()
    local TheUserModel = MvcEntry:GetModel(UserModel)

    local SuperProperties = {}
    SuperProperties.role_name = TheUserModel:GetPlayerName()

    self:SetSuperPropertiesInner(SuperProperties)
end
--[[
    设置事件公用属性
]]
function BuryReportSubsystem:SetSuperPropertiesInner(SuperProperties)
    local SuperPropertiesJsonStr = CommonUtil.JsonSafeEncode(SuperProperties)
    MvcEntry:GetCtrl(TDAnalyticsCtrl):SetSuperPropertiesWithJsonStr(SuperPropertiesJsonStr)
end

--此功能暂时用不上
function BuryReportSubsystem:ReceiveTrackFirst(EventName, Properties)
    if CommonUtil.IsDedicatedServer() then
        return
    end
    --TODO 直接调用SDK 进行一次性埋点上报
end

--[[
    重写C++方法
]]
function BuryReportSubsystem:SendBury(InPlayerId,InIsBot, EventName, Properties)
    self.Overridden.SendBury(self,InPlayerId,InIsBot, EventName, Properties)
    self:TryPrintLog(StringUtil.FormatSimple("BuryReportSubsystem:SendBury:{0} jsonvalue:{1}",EventName,Properties))

    if not MvcEntry then
        self:TryPrintLog("BuryReportSubsystem:SendBury MvcEntry not Initialize yet")
        CommonUtil.DoMvcEntyAction(function ()
            -- local PropertiesObject = CommonUtil.JsonSafeDecode(Properties)
            self:ReporyBury(InPlayerId,InIsBot,EventName,Properties)
        end)
    else
        --[[
            TODO 具体的埋点行为

            DS环境
                发送协议与DSMgr进行交互
            Client环境
                跟Lobby服进行交互
        ]]
        -- local PropertiesObject = CommonUtil.JsonSafeDecode(Properties)
        self:ReporyBury(InPlayerId,InIsBot,EventName,Properties)
    end
end

function BuryReportSubsystem:ProfileBegin(TagString)
    -- if CommonUtil.IsDedicatedServer() then
    --     TmpProfile.Begin(TagString)
    -- end
    -- self.BeginTime = GetTimestampMilliseconds()
end
function BuryReportSubsystem:ProfileEnd(TagString)
    -- if CommonUtil.IsDedicatedServer() then
    --     TmpProfile.End(TagString)
    -- end
    -- local EndTime = GetTimestampMilliseconds()
    -- CWaring("BuryReportSubsystem:ProfileEnd:" .. TagString .. "|" .. (EndTime - self.BeginTime))
end

function BuryReportSubsystem:ReporyBury(InPlayerId,InIsBot,EventName,Properties,MsgParam)
    if not EventName or not Properties then
        CWaring("BuryReportSubsystem:ReporyBury: EventName Not Found")
        return
    end
    --是否AI机器人
    local IsBot = InIsBot

    if IsBot then
        --AI行为过滤掉，不进行上传
        self:TryPrintLog("BuryReportSubsystem:ReporyBury: AI Break")
        return
    end
    if not self.EventName2MiscInfo[EventName] then
        self.EventName2MiscInfo[EventName] = TablePool.Fetch(PoolTagName)
        self.EventName2MiscInfo[EventName].BuryTimes = 0
    end
    self.EventName2MiscInfo[EventName].BuryTimes = self.EventName2MiscInfo[EventName].BuryTimes + 1
    local BuryType = BuryTypeEnum.CLIENT
    local PlayerId = 0
    local GameId = 0
    local IsDS = CommonUtil.IsDedicatedServer()
    if IsDS then
        BuryType = BuryTypeEnum.DS
        PlayerId = InPlayerId
    else
        PlayerId = MvcEntry:GetModel(UserModel):GetPlayerId()

        local force_sdk = (EventName == "step_flow")--PropertiesObject["force_sdk"] or false
        if not CommonUtil.IsInGameScene() or force_sdk then
            BuryType = BuryTypeEnum.CLIENT_SDK
        end
    end
    if IsDS or CommonUtil.IsInBattle() then
        GameId = LobbyProtocalHelper.GetGameId(UE.UGameplayStatics.GetGameState(self))
    end
    if not IsDS then
        local PropertiesObject = CommonUtil.JsonSafeDecode(Properties)
        if not PropertiesObject then
            return
        end
        -- self:ProfileBegin("BuryReportSubsystem:ReporyBury1")

        -- if CommonUtil.IsDedicatedServer() or CommonUtil.IsInBattle() then
        --     if not PropertiesObject.game_uuid then
        --         PropertiesObject.game_uuid = GameId
        --     end
        --     if not PropertiesObject.evolve_index then
        --         local RingIndex = LobbyProtocalHelper.GetRingIndex(self)
        --         PropertiesObject.evolve_index = RingIndex
        --     end
        -- end
        if not PropertiesObject.time then
            PropertiesObject.time = GetTimestamp()
        end
        if BuryType ~= BuryTypeEnum.CLIENT_SDK then
            if not PropertiesObject["#time"] then
                PropertiesObject["#time"] = TimeUtils.DateTimeStr2_FromTimeStamp(PropertiesObject.time)
            end
        end
        PropertiesObject.BuryType = BuryType
        -- self:ProfileEnd("BuryReportSubsystem:ReporyBury1")
        -- self:ProfileBegin("BuryReportSubsystem:ReporyBury2")
        Properties = CommonUtil.JsonSafeEncode(PropertiesObject)
    end
    if Properties then
        local CacheNeedSend = TablePool.Fetch(PoolTagName)
        CacheNeedSend.BuryType = BuryType
        CacheNeedSend.PlayerId = PlayerId
        CacheNeedSend.GameId = GameId
        CacheNeedSend.EventName = EventName
        CacheNeedSend.Properties = Properties

        self.CacheNeedSendList = self.CacheNeedSendList or TablePool.Fetch(PoolTagName)
        self.CacheNeedSendList[#self.CacheNeedSendList + 1] = CacheNeedSend
    end
    -- self:ProfileEnd("BuryReportSubsystem:ReporyBury2")

    --DS环境不参与策略上报，直接由相关事件驱动（目前为DS关闭通知的时候进行发送）
    -- if not CommonUtil.IsDedicatedServer() then
    --     if #self.CacheNeedSendList >= CacheCountMax then
    --         CWaring("BuryReportSubsystem:OnReportBuryActionTrigger CacheCountMax:" .. #self.CacheNeedSendList)
    --         self:OnReportBuryActionTrigger()
    --     else
    --         self:AddReporyBuryTimer()
    --     end
    -- end

    --DS也参与策略上报，现在策略修改为Tick分帧上报
    if #self.CacheNeedSendList >= CacheCountMax then
        self:TryPrintLog("BuryReportSubsystem:OnReportBuryActionTrigger CacheCountMax:" .. #self.CacheNeedSendList)
        self:OnReportBuryActionTrigger()
    else
        self:AddReporyBuryTimer()
    end
end

function BuryReportSubsystem:AddReporyBuryTimer()
    self:ProfileBegin("BuryReportSubsystem:AddReporyBuryTimer")
    if not self.ReprotTimer then
        self.ReprotTimer = Timer.InsertTimer(TimerOut,Bind(self,self.OnReprotTimerOut))
    end
    self:ProfileEnd("BuryReportSubsystem:AddReporyBuryTimer")
end
function BuryReportSubsystem:RemoveReporyBuryTimer()
    if self.ReprotTimer then
        Timer.RemoveTimer(self.ReprotTimer)
        self.ReprotTimer = nil
    end
end
function BuryReportSubsystem:OnReprotTimerOut()
    CWaring("BuryReportSubsystem:OnReportBuryActionTrigger TimerOut")
    self:OnReportBuryActionTrigger()
end

function BuryReportSubsystem:OnReportBuryActionTrigger()
    self:RemoveReporyBuryTimer()

    -- if self:IsTickSendTimerExist() then
    --     CWaring("BuryReportSubsystem:OnReportBuryActionTrigger IsTickSendTimerExist true,Break")
    --     return
    -- end
    self:FlushBuryCacheByTick()
    -- if true then
    --     self:FlushBuryCacheByTick()
    --     return
    -- end

    -- self:ProfileBegin("BuryReportSubsystem:OnReportBuryActionTrigger1")
    -- self.CacheNeedSendList = self.CacheNeedSendList or TablePool.Fetch(PoolTagName)
    -- self:ProfileEnd("BuryReportSubsystem:OnReportBuryActionTrigger1")
    -- if #self.CacheNeedSendList <= 0 then
    --     return
    -- end
    -- local LoopSendNum = 20
    -- if #self.CacheNeedSendList <= LoopSendNum then
    --     self:OnReportBuryActionTriggerInner(self.CacheNeedSendList)
    -- else 
    --     local LoopSendList = TablePool.Fetch(PoolTagName)
    --     local LoopIndex = 0
    --     for k,v in ipairs(self.CacheNeedSendList) do
    --         LoopSendList = LoopSendList or TablePool.Fetch(PoolTagName)
    --         LoopSendList[#LoopSendList + 1] = v
    --         LoopIndex = LoopIndex + 1

    --         if LoopIndex >= LoopSendNum then
    --             self:OnReportBuryActionTriggerInner(LoopSendList)
    --             TablePool.Recycle(PoolTagName,LoopSendList)
    --             LoopSendList = nil
    --             LoopIndex = 0
    --         end 
    --     end
    --     if LoopSendList and #LoopSendList > 0 then
    --         self:OnReportBuryActionTriggerInner(LoopSendList)
    --         TablePool.Recycle(PoolTagName,LoopSendList)
    --         LoopSendList = nil
    --     end
    -- end
    -- self:RecycleTable(self.CacheNeedSendList,PoolTagName)
    -- self.CacheNeedSendList = nil
end

function BuryReportSubsystem:OnReportBuryActionTriggerInner(CacheNeedSendList)
    self:ProfileBegin("BuryReportSubsystem:OnReportBuryActionTrigger2-0")
    local PlayerId2ClientSendMsg = TablePool.Fetch(PoolTagName)
    local GameId2DSSendMsg  = TablePool.Fetch(PoolTagName)
    self:ProfileEnd("BuryReportSubsystem:OnReportBuryActionTrigger2-0")
    self:ProfileBegin("BuryReportSubsystem:OnReportBuryActionTrigger2")
    for k,CacheNeedSend in ipairs(CacheNeedSendList) do
        if CacheNeedSend.BuryType == BuryTypeEnum.CLIENT then
            PlayerId2ClientSendMsg[CacheNeedSend.PlayerId] = PlayerId2ClientSendMsg[CacheNeedSend.PlayerId] or TablePool.Fetch(PoolTagName)
            local ClientSendMsg = PlayerId2ClientSendMsg[CacheNeedSend.PlayerId]

            local ClientBuryingPoint = TablePool.Fetch(PoolTagName)
            ClientBuryingPoint.EventName = CacheNeedSend.EventName
            ClientBuryingPoint.JsonContext = CacheNeedSend.Properties

            ClientSendMsg.BuryingPoints = ClientSendMsg.BuryingPoints or TablePool.Fetch(PoolTagName)
            ClientSendMsg.BuryingPoints[#ClientSendMsg.BuryingPoints + 1] = ClientBuryingPoint
        elseif CacheNeedSend.BuryType == BuryTypeEnum.CLIENT_SDK then
            --TODO 直接调用SDK接口进行上报
            self:TryPrintLog(StringUtil.FormatSimple("BuryReportSubsystem:OnReportBuryActionTrigger SDkSendMsg:{0} {1}",CacheNeedSend.EventName,CacheNeedSend.Properties))
            MvcEntry:GetCtrl(TDAnalyticsCtrl):TrackWithJsonStr(CacheNeedSend.EventName,CacheNeedSend.Properties)
        elseif CacheNeedSend.BuryType == BuryTypeEnum.DS then
            GameId2DSSendMsg[CacheNeedSend.GameId] = GameId2DSSendMsg[CacheNeedSend.GameId] or TablePool.Fetch(PoolTagName)
            local DSSendMsg = GameId2DSSendMsg[CacheNeedSend.GameId]
            DSSendMsg.GameId = CacheNeedSend.GameId

            local DSBuryingPoint = TablePool.Fetch(PoolTagName)
            DSBuryingPoint.PlayerId = CacheNeedSend.PlayerId
            DSBuryingPoint.EventName = CacheNeedSend.EventName
            DSBuryingPoint.JsonContext = CacheNeedSend.Properties
    
            DSSendMsg.BuryingPoints = DSSendMsg.BuryingPoints or TablePool.Fetch(PoolTagName)
            DSSendMsg.BuryingPoints[#DSSendMsg.BuryingPoints + 1] = DSBuryingPoint
        end
    end
    self:ProfileEnd("BuryReportSubsystem:OnReportBuryActionTrigger2")
    self:ProfileBegin("BuryReportSubsystem:OnReportBuryActionTrigger3")
    for PlayerId,ClientSendMsg in pairs(PlayerId2ClientSendMsg) do
        -- print_r(ClientSendMsg,"BuryReportSubsystem:OnReportBuryActionTrigger ClientSendMsg")
        MvcEntry:SendProto(Pb_Message.ClientBuryingPointSync, ClientSendMsg,nil,true)
    end
    for GameId,DSSendMsg in pairs(GameId2DSSendMsg) do
        -- print_r(DSSendMsg,"BuryReportSubsystem:OnReportBuryActionTrigger DSSendMsg")
        MvcEntry:SendProto(DSPb_Message.DsBuryingPointSync, DSSendMsg)
    end
    self:ProfileEnd("BuryReportSubsystem:OnReportBuryActionTrigger3")

    self:ProfileBegin("BuryReportSubsystem:OnReportBuryActionTrigger4")

    self:RecycleTable(PlayerId2ClientSendMsg,PoolTagName)
    self:RecycleTable(GameId2DSSendMsg,PoolTagName)

    self:ProfileEnd("BuryReportSubsystem:OnReportBuryActionTrigger4")
end

function BuryReportSubsystem:RecycleTable(TheTable,TagName)
    TablePool.RecycleTable(TagName,TheTable)
end


function BuryReportSubsystem:AddTickSendTimer()
    if not self.TickSendTimer then
        CWaring("BuryReportSubsystem:AddTickSendTimer()")
        self.TickIndexIncrement = 1
        self.TickSendTimer = Timer.InsertTimer(Timer.NEXT_TICK,Bind(self,self.OnTickSendTimerTrigger),true)
    end
end
function BuryReportSubsystem:RemoveTickSendTimer()
    if self.TickSendTimer then
        CWaring("BuryReportSubsystem:RemoveTickSendTimer()")
        Timer.RemoveTimer(self.TickSendTimer)
    end
    self.TickSendTimer = nil
end
function BuryReportSubsystem:IsTickSendTimerExist()
    return (self.TickSendTimer ~= nil)
end

--[[
    分帧进行协议同步
]]
function BuryReportSubsystem:OnTickSendTimerTrigger()
    local NeedSendList = self.TickIndex2CacheList[self.TickIndexIncrement]
    if not NeedSendList then
        self:TryPrintLog("BuryReportSubsystem:OnTickSendTimerTrigger:" .. self.TickIndexIncrement)
        TablePool.Recycle(PoolTagName,self.TickIndex2CacheList)
        self.TickIndex2CacheList = nil
        self:RemoveTickSendTimer()

        --此次分帧行为结束，发现还有Cache队列，需要再次触发分帧派发
        if self.CacheNeedSendList and #self.CacheNeedSendList > 0 then
            self:FlushBuryCacheByTick("BuryReportSubsystem:OnTickSendTimerTrigger End Retry")
        else
            CWaring("BuryReportSubsystem:OnTickSendTimerTrigger End No Cache Now")
        end
        return
    end
    self:OnReportBuryActionTriggerInner(NeedSendList)
    self:RecycleTable(NeedSendList,PoolTagName)
    self.TickIndexIncrement = self.TickIndexIncrement + 1
end

--[[
    尝试打印log
]]
function BuryReportSubsystem:TryPrintLog(Log)
    if CommonUtil.IsShipping() then
        --Shipping不打印log
        return
    end
    CLog(Log)
end

function BuryReportSubsystem:TryPrintTable(TheTable)
    if CommonUtil.IsShipping() then
        --Shipping不打印log
        return
    end
    print_r(TheTable)
end


return BuryReportSubsystem