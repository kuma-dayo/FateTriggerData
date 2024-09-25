--[[
    协议转圈
    作用时协议交互期间屏蔽触摸 等待协议返回
]]
NetLoading = NetLoading or {}

NetLoading.NetMsgMapStatic = NetLoading.NetMsgMapStatic  or {}
if NetLoading.Active == nil then
    NetLoading.Active = false
end
if NetLoading.ReconnectActive == nil then
    NetLoading.ReconnectActive = false
end
NetLoading.Instance = NetLoading.Instance or nil
NetLoading.ReconnectInstance = NetLoading.ReconnectInstance or nil

--[[
    添加协议请求转圈
    SendNetMsgId 发送的协议号
    RemoveNetMsgId 期待返回的协议号
    Duration 转圈超时时间，超过X时间，会强制关闭转圈
    CircleShowDelay  转圈实际显示内容延迟显示
    DurationCallback 超时回调
]]
function NetLoading.Add(SendNetMsgId,RemoveNetMsgId,Duration,CircleShowDelay,DurationCallback)
    if MvcEntry and MvcEntry:GetModel(ViewModel):GetState(ViewConst.OnlineSubLoginPanel) then
        --在线子系统登录时，不显示Loading
        return
    end
    -- 重连弹窗显示的时候不需要转圈
    if NetLoading.ReconnectActive then return end

    SendNetMsgId = SendNetMsgId or 0
    RemoveNetMsgId = RemoveNetMsgId or 0
    Duration = Duration or 8
    CircleShowDelay = CircleShowDelay or 1

    local netMsgKey = SendNetMsgId .. "_" .. RemoveNetMsgId
    if NetLoading.NetMsgMapStatic[netMsgKey] then
        if SendNetMsgId then
            CWaring("NetLoading repeat add:" .. netMsgKey)
        end
        return
    end
    local NetInfo = {
        SendNetMsgId=SendNetMsgId,
        RemoveNetMsgId=RemoveNetMsgId,
        Time=GetTimestamp(),
    }
    NetLoading.NetMsgMapStatic[netMsgKey] = NetInfo
    NetLoading.Active = true
    if not CommonUtil.IsValid(NetLoading.Instance) then
        local widget_class = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(NetLoadingUMGPath))
        NetLoading.Instance = NewObject(widget_class, GameInstance, nil, "Client.Common.NetLoadingLogic")
        UIRoot.AddChildToLayer(NetLoading.Instance,UIRoot.UILayerType.Tips)
    end
    NetLoading.Instance:Show()
    NetLoading.Instance:ScheduleAutoHide(Duration,DurationCallback)
    NetLoading.Instance:ScheduleCicleShow(CircleShowDelay);
end

--[[
    添加断线重连弹窗
]]
function NetLoading.AddReconnectPopup()
    if MvcEntry and MvcEntry:GetModel(ViewModel):GetState(ViewConst.OnlineSubLoginPanel) then
        --在线子系统登录时，不显示Loading
        return
    end
    NetLoading.CloseLoadingPopup()
    NetLoading.ReconnectActive = true
    if not CommonUtil.IsValid(NetLoading.ReconnectInstance) then
        local widget_class = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(NetLoadingReconnectUMGPath))
        NetLoading.ReconnectInstance = NewObject(widget_class, GameInstance, nil, "Client.Common.NetLoadingReconnectLogic")
        UIRoot.AddChildToLayer(NetLoading.ReconnectInstance,UIRoot.UILayerType.Tips)
    end
    NetLoading.ReconnectInstance:Show()
end

--[[
    协议返回 会主动调用这个接口 
]]
function NetLoading.CheckRecvMsgId(MsgId)
    local len = 0
    local newTab = {}
    for k,v in pairs(NetLoading.NetMsgMapStatic) do
        if v.RemoveNetMsgId == MsgId then
            NetLoading.NetMsgMapStatic[k] = nil
        else
            newTab[k] = v
            len = len + 1
        end
    end
    NetLoading.NetMsgMapStatic = newTab
    if len <= 0 then
        NetLoading.CloseLoadingPopup()
    end
end

--[[
    服务器报错返回，会调用这个接口
]]
function NetLoading.CheckErrorSendMsgId(MsgId)
    local len = 0
    local newTab = {}
    for k,v in pairs(NetLoading.NetMsgMapStatic) do
        if v.SendNetMsgId == MsgId then
            NetLoading.NetMsgMapStatic[k] = nil
        else
            newTab[k] = v
            len = len + 1
        end
    end
    NetLoading.NetMsgMapStatic = newTab
    if len <= 0 then
        NetLoading.CloseLoadingPopup()
    end
end

function NetLoading.CheckTimeout()
    NetLoading.NetMsgMapStatic = NetLoading.NetMsgMapStatic or {}
    for key,v in pairs(NetLoading.NetMsgMapStatic) do
        local NetInfo = NetLoading.NetMsgMapStatic[key]
        if NetInfo and NetInfo.SendNetMsgId then
            local s = GetTimestamp() - NetInfo.Time;
            if s >= 1 then
                local str = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_NetLoading_Protocolresponsetime"),NetInfo.SendNetMsgId,NetInfo.RemoveNetMsgId,s,NetInfo.Time)
                CError(str);
            end
        end
    end
    NetLoading.CloseLoadingPopup()
end

-- 关闭协议转圈弹窗
function NetLoading.CloseLoadingPopup()
    NetLoading.NetMsgMapStatic = {}
    NetLoading.Active = false
    if CommonUtil.IsValid(NetLoading.Instance) then
        NetLoading.Instance:Hide()
    -- else
        -- CLog('NetLoading.Instance nil')
    end
end

-- 关闭重连弹窗
function NetLoading.CloseReconnectPopup()
    NetLoading.ReconnectActive = false
    if CommonUtil.IsValid(NetLoading.ReconnectInstance) then
        NetLoading.ReconnectInstance:Hide()
    -- else
        -- CLog('NetLoading.ReconnectInstance nil')
    end
end

function NetLoading.Close()
    -- CLog('recv close indicator..')
    NetLoading.CloseLoadingPopup()
    NetLoading.CloseReconnectPopup()
end

function NetLoading.IsActive()
    return NetLoading.Active or NetLoading.ReconnectActive
end


