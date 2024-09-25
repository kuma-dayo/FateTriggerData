local super = EventDispatcher;
local class_name = "SocketMgr";
SocketMgr = SocketMgr or BaseClass(super, class_name);

local RsaPubKey = [[-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDGgve/VaLPp6/S/G5BAdBiavwr
vZtlxa7b8ToqkaS/Hkg9F+IxMpru+R0Yk6oDmWYOKv+SHszBh+Du4P3+p7UQQxMI
X2TDCvtHlR3wUOwF4uXHxpAsL3eFS17GyM/Ph1ouL62sF6dUs84FmEOGQ2asMwRo
RO91k/SEeJLFNeTS3wIDAQAB
-----END PUBLIC KEY-----]]

-- 主游戏Socket 连接成功
SocketMgr.CMD_ON_CONNECTED = 50001
-- 主游戏Socket 连接关闭
SocketMgr.CMD_ON_CLOSED = 50002
-- 主游戏Socket 连接错误
SocketMgr.CMD_ON_ERROR = 50003

-- 主游戏Socket 连接关闭(手动) 即将关闭
SocketMgr.CMD_ON_MANUAL_CLOSED_PRE = 50004
-- 主游戏Socket 连接关闭(手动)
SocketMgr.CMD_ON_MANUAL_CLOSED = 50005

-- 存放全局协议
_G.s2c = _G.s2c or {} -- lobbyserver to client
_G.c2s = _G.c2s or {} -- client to lobbyserver

function SocketMgr:__init()
    self.mConnected = false

    self.SocketStream = nil
    self.CallPbRpc = nil
    self.Pb2AlreadyParsed = {}
end

--[[客户端主动关闭socket]]
--[[
	InReason Socket关闭原因
	IsReconnect  是否重连
]]
function SocketMgr:Close(InReason, IsReconnect)
    if not IsReconnect then
        --非重连需要登出
        local Req = {
            Reason = InReason or "UserLogout"
        }
        self:SendProto(Pb_Message.LogoutReq, Req)
    end
    if not IsReconnect and self.SocketStream then
        self:DispatchType(SocketMgr.CMD_ON_MANUAL_CLOSED_PRE);
    end
    if self.SocketStream then
        self.SocketStream.close()
    end
    self.mConnected = false
    if not IsReconnect and self.SocketStream then
        self:DispatchType(SocketMgr.CMD_ON_MANUAL_CLOSED);
    end
    self.SocketStream = nil
    CLog("SocketMgr:Close")
end

--[[是否已经连接]]
function SocketMgr:IsConnected()
    return self.mConnected
end

-- 发送协议
function SocketMgr:SendProto(Cmd, MsgBody)
    if not self.SocketStream then
        return
    end
    if self.SocketStream.token == 0 then
        print("SocketStream is closed, login first!")
        return
    end

    print("CallPbRpc Func: " .. tostring(Cmd))
    self.SocketStream.CallPbRpc(Cmd, MsgBody)
end
--[[连接Socket成功]]
function SocketMgr:OnConnect()
    self.mConnected = true
    self:DispatchType(SocketMgr.CMD_ON_CONNECTED);
end

--[[Socket 关闭]]
function SocketMgr:OnClose()
    if self.mConnected then
        -- 被动关闭，可触发断线重连
    end
    self.mConnected = false
    self.SocketStream = nil
    self:DispatchType(SocketMgr.CMD_ON_CLOSED);
end

--[[Socket 错误]]
function SocketMgr:OnError()
    if self.mConnected then
        -- 被动关闭，可触发断线重连
    end
    self.mConnected = false
    self.SocketStream = nil
    self:DispatchType(SocketMgr.CMD_ON_ERROR);
end

function SocketMgr:TheParseFunc(Pb)
    local PbDes = Pb_ProtoList[Pb]
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
        -- print("parsing " .. Pb)
        LuaProto.Parse(Pb)
        self.Pb2AlreadyParsed[Pb] = true
    else
        -- print("pb from cache,skip parsing " .. Pb)
    end
end

function SocketMgr:DoParseProto()
    self.Pb2AlreadyParsed = {}
    LuaProto.AddSearchPath("Client/Net/Protocols/")
    for Pb, v in pairs(Pb_ProtoList) do
        self:TheParseFunc(Pb)
    end
end

--[[Socket 连接]]
function SocketMgr:Connect(Host, Port)
    local Url = Host .. ":" .. Port
    CLog(Url)
    -- UE.UNetworkMgr:LuaConnectSvr(Url)
    print("StartLogin:", Host, Port)
    CWaring("StartLogin")
    MvcEntry:GetModel(LoginModel):DispatchType(LoginModel.ON_STEP_LOGIN,LoginModel.SocketLoginStepTypeEnum.LOGIN_CONNECT_PARSE_PB)
    -- TODO 解析Proto文件
    self:DoParseProto()
    -- //
    MvcEntry:GetModel(LoginModel):DispatchType(LoginModel.ON_STEP_LOGIN,LoginModel.SocketLoginStepTypeEnum.LOGIN_MAIN_CONNECT_BEGIN)
    local SocketStream = UEConnect.connect(Host, Port, 2000)
    if SocketStream then
        self.SocketStream = SocketStream
        SocketStream.on_connect = function(result)
            CWaring("on_connect, result=" .. result)
            if result == "ok" then
                -- 暂时先改大，后续与后端统一为一个合适的值
                SocketStream.set_recv_buffer_size(1024 * 1024);
                SocketStream.set_send_buffer_size(1024 * 1024);
                SocketStream.SSLHandshakeReq(RsaPubKey)
                SocketStream.set_timeout(60000)
                -- MvcEntry:GetModel(SocketMgr):OnConnect()
            else
                MvcEntry:GetModel(SocketMgr):OnError()
            end
        end

        SocketStream.OnSSLHandshakeRsp = function(result)
            if result then
                CWaring("SocketStream.OnSSLHandshakeRsp suc")
                MvcEntry:GetModel(SocketMgr):OnConnect()

                MvcEntry:GetModel(LoginModel):DispatchType(LoginModel.ON_STEP_LOGIN,LoginModel.SocketLoginStepTypeEnum.LOGIN_MAIN_CONNECT_SUC)
            else
                CWaring("SocketStream.OnSSLHandshakeRsp fail")
                MvcEntry:GetModel(SocketMgr):OnError()
            end
        end

        SocketStream.on_error = function(Err)
            CWaring("SocketStream on_error:" .. Err)
            if Err == "connection-lost" then
                SocketStream.close()
            end
            MvcEntry:GetModel(SocketMgr):OnError()
        end

        -- 客户端收到PB返回
        SocketStream.OnPbRpcCall = function(Func, Msgtab)
            CWaring("OnPbRpcCall Func: " .. tostring(Func))

            if not Func then
                print("OnPbRpcCall failed, recv Func not exist!")
                return
            end

            local Proc = s2c[Func]
            NetLoading.CheckRecvMsgId(Func)
            MvcEntry:GetCtrl(NetProtoLogCtrl):CheckRecvMsgId(Func, Msgtab)
            if not Proc then
                print("OnPbRpcCall failed, Func name not exist![" .. Func .. "]")
                return
            end

            local ErrorTypeStr = StringUtil.FormatSimple("OnPbRpcCall failed with funcname {0}:", Func)
            EnsureCall(ErrorTypeStr, Proc, Msgtab)
        end

        -- self.CallPbRpc = function(Func, MsgTab)
        -- 	if not SocketStream then
        -- 		print("SocketStream is nil, connect failed!")
        -- 		return
        -- 	end

        -- 	if SocketStream.token == 0 then
        -- 		print("SocketStream is closed, login first!")
        -- 		return
        -- 	end

        -- 	print("CallPbRpc Func: " .. tostring(Func))
        -- 	SocketStream.CallPbRpc(Func, MsgTab)
        -- end

        -- --客户端发起PB请求(临时兼容，后面统一走SendProto) 要废弃
        -- c2s.CallPbRpc = function(Func, MsgTab)
        -- 	self.CallPbRpc(Func, MsgTab)
        -- end

        -- --客户端收到协议返回  旧代码，走参数模式，要废弃
        -- SocketStream.OnLuaRpcCall = function(Func, ...)
        --     print("on Func: " .. tostring(Func))

        --     if not Func then
        --         print("OnLuaRpcCall failed, recv Func not exist!")
        --         return
        --     end

        --     local Proc = s2c[Func]
        --     if not Proc then
        --         print("OnLuaRpcCall failed, Func name not exist![" .. Func .. "]")
        --         return
        --     end

        --     local ok, err = xpcall(Proc, debug.traceback, ...)
        --     if not ok then
        --         print("OnLuaRpcCall failed, err=" .. err)
        --     end
        -- end

        -- --旧代码，走参数模式，要废弃
        -- c2s.CallLuaRpc = function(Func, ...)
        -- 	if not SocketStream then
        -- 		print("SocketStream is nil, connect failed!")
        -- 		return
        -- 	end

        -- 	if SocketStream.token == 0 then
        -- 		print("SocketStream is closed, login first!")
        -- 		return
        -- 	end

        -- 	print("CallLuaRpc Func: " .. tostring(Func))
        -- 	SocketStream.CallLuaRpc(Func, ...)
        -- end

        -- --旧代码，走参数模式，要废弃
        -- c2s.call = function(Func, ...)
        -- 	c2s.CallLuaRpc(Func, ...)
        -- end
    else
        print("SocketStream is nil")
    end
end

return SocketMgr;
