local super = GameEventDispatcher;
local class_name = "ACESDKModel";

--[[ 
]]
ACESDKModel = BaseClass(super, class_name);

function ACESDKModel:__init()
    self.IsInit = false

    self.AccountId = 0
    self.AccountType = 0
    self.AccountWorldId = 0
end


function ACESDKModel:AceLogin()
    UE.UACESDKHelper.LoginIn(self.AccountId, self.AccountType, self.AccountWorldId)
end

function ACESDKModel:AceLogout()
    UE.UACESDKHelper.LoginOut()
end

--[[
    在调用 ace_sdk_client_log_in 和 ace_sdk_client_log_out 之间，每隔100ms调用一次。需确保每秒钟调用不小于10次。
    注意仅当此函数返回成功时上报数据（请参阅Demo）。如果暂时没有数据需要上报，函数会返回 ACE_SDK_RESULT_NO_PACKET_NEED_SENDING，此时不需要做任何事情。
    获取到的数据大小不会大于2048字节。
]]--
function ACESDKModel:AceSendPacket()
    local Buffer = UE.TArray(UE.uint8)
    local HadGot = UE.UACESDKHelper.GetPacket(Buffer)
    if HadGot then
        MvcEntry:GetCtrl(ACESDKCtrl):SendProto_AceChannelDataReq(Buffer)
    end
end

--[[
    调用时机
    游戏客户端收到游戏服务器下发的ACE数据时。
]]--
function ACESDKModel:AceReceivePacket(Buffer)
    UE.UACESDKHelper.ReceivePacket(Buffer)
end

function ACESDKModel:StartAceTimer()
    self:StopAceTimer()
    self.AceTimer = Timer.InsertTimer(0.1, function()
        self:AceSendPacket()
    end)
end

function ACESDKModel:StopAceTimer()
    if self.AceTimer ~= nil then
        Timer.RemoveTimer(self.AceTimer)
        self.AceTimer = nil
    end
end


return ACESDKModel