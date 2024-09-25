local super = EventDispatcher;
local class_name = "DSSocketMgr";
DSSocketMgr = DSSocketMgr or BaseClass(super, class_name);

-- 主游戏Socket 连接成功
DSSocketMgr.CMD_ON_CONNECTED = 50001
-- 主游戏Socket 连接关闭
DSSocketMgr.CMD_ON_CLOSED = 50002
-- 主游戏Socket 连接错误
DSSocketMgr.CMD_ON_ERROR = 50003

-- 存放全局协议
_G.s2c = _G.s2c or {} -- lobbyserver to client
_G.c2s = _G.c2s or {} -- client to lobbyserver

function DSSocketMgr:__init()
    self.mConnected = false

    self.SocketStream = nil
    self.Pb2AlreadyParsed = {}

    self.PingTimerId = nil
    self.PingTimeGap = 10
end

--[[客户端主动关闭socket]]
function DSSocketMgr:Close(InReason)
    self:StopPingTimer();
    self.mConnected = false
    local Req = {
        Reason = InReason or "UserLogout"
    }
    self:SendProto(DSPb_Message.LogoutReq, Req)
    if self.SocketStream then
        self.SocketStream.close()
    end
    self.SocketStream = nil
    CLog("DSSocketMgr:Close")
end

--[[是否已经连接]]
function DSSocketMgr:IsConnected()
    return self.mConnected
end

-- 发送协议
function DSSocketMgr:SendProto(Cmd, MsgBody)
    local DSAgent = UE.UDSAgent.Get(GameInstance)
    if not DSAgent then
        print("SendProto: Invalid DSAgent")
        return
    end

    local GameId = DSAgent:GetDSGameInfo().GameId
    if not GameId or GameId == "" then
        print("SendProto: Incorrect GameId=" .. GameId)
        return
    end

    -- 统一填充 GameId
    MsgBody.GameId = GameId

    if not self.SocketStream then
        return
    end
    -- if not self.CallPbRpc  then
    -- 	return
    -- end
    -- print_r(MsgBody, StringUtil.Format("SendProto {0}:", Cmd))
    -- self.CallPbRpc(Cmd, MsgBody)
    self.SocketStream.CallPbRpc(Cmd, MsgBody)
end
--[[连接Socket成功]]
function DSSocketMgr:OnConnect()
    self.mConnected = true
    self:DispatchType(DSSocketMgr.CMD_ON_CONNECTED);
end

--[[Socket 关闭]]
function DSSocketMgr:OnClose()
    if self.mConnected then
        -- 被动关闭，可触发断线重连
    end
    self.mConnected = false
    self.SocketStream = nil
    self:DispatchType(DSSocketMgr.CMD_ON_CLOSED);
    self:StopPingTimer();
end

--[[Socket 错误]]
function DSSocketMgr:OnError()
    if self.mConnected then
        -- 被动关闭，可触发断线重连
    end
    self.mConnected = false
    self.SocketStream = nil
    self:DispatchType(DSSocketMgr.CMD_ON_ERROR);
    self:StopPingTimer();
end

function DSSocketMgr:TheParseFunc(Pb)
    local PbDes = DSPb_ProtoList[Pb]
    local ImportPbList = PbDes.ImportPbList
    if ImportPbList and #ImportPbList > 0 then
        for _, ImportPb in ipairs(ImportPbList) do
            if not self.Pb2AlreadyParsed[Pb] then
                print("parsing ImportPb " .. ImportPb .. " by " .. Pb)
                self:TheParseFunc(ImportPb)
            end
        end
    end
    if not self.Pb2AlreadyParsed[Pb] then
        print("parsing " .. Pb)
        LuaProto.Parse(Pb)
        self.Pb2AlreadyParsed[Pb] = true
    else
        -- print("pb from cache,skip parsing " .. Pb)
    end
end

function DSSocketMgr:DoParseProto()
    self.Pb2AlreadyParsed = {}
    LuaProto.AddSearchPath("Server/Net/Protocols/")
    for Pb, v in pairs(DSPb_ProtoList) do
        self:TheParseFunc(Pb)
    end
end

--[[Socket 连接]]
function DSSocketMgr:Connect()
    print("DSStartLogin:", Host, Port)

    -- TODO 解析Proto文件
    self:DoParseProto()
    -- //
    -- ip, port, timeout 由dsmgr通过命令行传入
    local SocketStream = UEConnect.connect()
    if SocketStream then
        self.SocketStream = SocketStream
        SocketStream.on_connect = function(result)
            print("on_connect, result=" .. result)
            if result == "ok" then
                SocketStream.set_recv_buffer_size(1024 * 1024);
                SocketStream.set_send_buffer_size(1024 * 1024);
                SocketStream.set_timeout(60000)

                MvcEntry:GetModel(DSSocketMgr):OnConnect()
                self:StartPingTimer()
            else
                MvcEntry:GetModel(DSSocketMgr):OnError()
            end
        end

        SocketStream.on_error = function(Err)
            print("SocketStream on_error:" .. Err)
            if Err == "connection-lost" then
                SocketStream.close()
            end
            MvcEntry:GetModel(DSSocketMgr):OnError()
        end

        -- 客户端收到PB返回
        SocketStream.OnPbRpcCall = function(Func, Msgtab)
            print("OnPbRpcCall Func: " .. tostring(Func))
            -- print_r(Msgtab)
            if not Func then
                print("OnPbRpcCall failed, recv Func not exist!")
                return
            end

            local Proc = s2c[Func]
            if not Proc then
                print("OnPbRpcCall failed, Func name not exist![" .. Func .. "]")
                return
            end

            local ErrorTypeStr = StringUtil.Format("DS OnPbRpcCall failed with funcname {0}:",Func)
            EnsureCall(ErrorTypeStr, Proc, Msgtab)
        end
    else
        print("SocketStream is nil")
    end
end

--[[
    开始心跳包
]]
function DSSocketMgr:StartPingTimer()
    if not self.PingTimerId then
        self:OnPingTimer();
        self.PingTimerId = Timer.InsertTimer(self.PingTimeGap, Bind(self, self.OnPingTimer), true)
    end
end

--[[
    停止心跳包
]]
function DSSocketMgr:StopPingTimer()
    if self.PingTimerId then
        Timer.RemoveTimer(self.PingTimerId)
    end

    print("StopPingTimer")
    self.PingTimerId = nil
end

function DSSocketMgr:OnPingTimer()
    local Msg = {
        -- timestamp=timestamp
    }
    print("call_heartbeat")
    self:SendProto(DSPb_Message.DSHeartbeatReq, Msg)
end

return DSSocketMgr;
