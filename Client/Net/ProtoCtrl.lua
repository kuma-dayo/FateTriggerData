require("Client.Net.SocketMgr");

--[[协议收发管理]]
local super = UserGameController;
ProtoCtrl = BaseClass(super, "ProtoCtrl");

function ProtoCtrl:__init()
    self:DataInit()
end

function ProtoCtrl:__dispose()
	self.SocketMgr:Dispose();
end

function ProtoCtrl:Initialize()
    self.SocketMgr = self:GetModel(SocketMgr);
end


function ProtoCtrl:DataInit()
    self.CacheSendProtoList = {}
end

function ProtoCtrl:OnLogout(Data)
    if Data then
        return
    end
    self:DataInit()
end


function ProtoCtrl:AddMsgListeners()
    ProtoCtrl.super.AddMsgListeners(self);
    self:AddMsgListener(CommonEvent.SEND_PROTO, 	self.OnSendProto,  self);
    self:AddMsgListener(CommonEvent.ON_LOGIN_FINISHED, 	self.ON_LOGIN_FINISHED_Func,  self);
end

function ProtoCtrl:RemoveMsgListeners()
    ProtoCtrl.super.RemoveMsgListeners(self);
    self:RemoveMsgListener(CommonEvent.SEND_PROTO,     self.OnSendProto,  self);
    self:RemoveMsgListener(CommonEvent.ON_LOGIN_FINISHED, 	self.ON_LOGIN_FINISHED_Func,  self);
end

--[[发送协议]]
function ProtoCtrl:OnSendProto(proto)
    if self.SocketMgr:IsConnected() then
        self.SocketMgr:SendProto(proto.cmd,proto.msgBody);
    else
        CWaring("Error:Socket已经断开连接！请重新连接");
        if proto.reliable then
            self.CacheSendProtoList = self.CacheSendProtoList or {}
            table.insert(self.CacheSendProtoList,proto)
        end
    end
end

function ProtoCtrl:ON_LOGIN_FINISHED_Func()
    if self.SocketMgr:IsConnected() then
        if self.CacheSendProtoList and #self.CacheSendProtoList > 0 then
            for k,proto in ipairs(self.CacheSendProtoList) do
                CWaring("ProtoCtrl Retry Send Reliable Proto:" .. proto.cmd)
                self:OnSendProto(proto)
            end
        end
    end
    self.CacheSendProtoList = {}
end
