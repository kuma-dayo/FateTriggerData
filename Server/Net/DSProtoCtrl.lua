require("Server.Net.DSSocketMgr");
require("Server.Net.Protocols.DSPbDeclare")

--[[协议收发管理]]
local super = GameController;
DSProtoCtrl = BaseClass(super, "DSProtoCtrl");

function DSProtoCtrl:__init()

end

function DSProtoCtrl:__dispose()
	self.SocketMgr:Dispose();
end

function DSProtoCtrl:Initialize()
    self.SocketMgr = self:GetModel(DSSocketMgr);
end



function DSProtoCtrl:AddMsgListeners()
    DSProtoCtrl.super.AddMsgListeners(self);
    self:AddMsgListener(CommonEvent.SEND_PROTO, 	self.OnSendProto,  self);
end

function DSProtoCtrl:RemoveMsgListeners()
    DSProtoCtrl.super.RemoveMsgListeners(self);
    self:RemoveMsgListener(CommonEvent.SEND_PROTO,     self.OnSendProto,  self);
end

--[[发送协议]]
function DSProtoCtrl:OnSendProto(proto)
    if self.SocketMgr:IsConnected() then
        self.SocketMgr:SendProto(proto.cmd,proto.msgBody);
    else
        CWaring("Error:Socket已经断开连接！请重新连接");
    end
end
