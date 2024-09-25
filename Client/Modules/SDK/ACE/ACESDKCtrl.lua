require("Client.Modules.SDK.ACE.ACESDKModel")

--[[
    ACESDK 交互Ctrl
]]
local class_name = "ACESDKCtrl"
ACESDKCtrl = ACESDKCtrl or BaseClass(UserGameController,class_name)

function ACESDKCtrl:__init()
end

function ACESDKCtrl:Initialize()
    self.IsSDKEanbled = nil
end

--[[
    判断返回SDK是否可用
]]
function ACESDKCtrl:IsSDKEnable()
    if self.IsSDKEanbled == nil then
        local IsEditor = UE.UGFUnluaHelper.IsEditor()
        if IsEditor then
            self.IsSDKEanbled = false
        else
            local SDKEanbled =  UE.UACESDKHelper.IsEnable()
            CWaring("ACESDKCtrl:IsSDKEnable:" .. (SDKEanbled and "1" or "0"))
            
            --自定义是否启用
            local CustomEnabled = true
            local BValue = SDKEanbled and CustomEnabled or false
            self.IsSDKEanbled = BValue
            CWaring("ACESDKCtrl:BValue:" .. (BValue and "1" or "0"))
        end
    end
    return self.IsSDKEanbled
end


function ACESDKCtrl:OnLogin(data)
    CWaring("ACESDKCtrl OnLogin")
    self:AceLogin()
    self:StartAceTimer()
end

function ACESDKCtrl:OnLogout(data)
    CWaring("ACESDKCtrl OnLogout")
    self:StopAceTimer()
    self:AceLogout()
end


function ACESDKCtrl:AddMsgListenersUser()
    self.ProtoList = {
        {MsgName = Pb_Message.AcePackageS2cSync, Func = self.AcePackageS2cSync_Func},
    }
end

--收到服力器下发，需要透传给到SDK
function ACESDKCtrl:AcePackageS2cSync_Func(Msg)
    self:AceReceivePacket(Msg.PackData)
end


--发送ACE游戏通道数据
function ACESDKCtrl:SendProto_AcePackageC2sReq(PackData)
    local Msg = {
        PackData = PackData,
    }
    self:SendProto(Pb_Message.AcePackageC2sReq, Msg)
end



-------------------------------------------------SDK交互接口------------------------------------------------------------------------
--[[
    SDK初始化
]]
function ACESDKCtrl:Init()
    if not self:IsSDKEnable() then
        return
    end
    CWaring("ACESDKCtrl Init")
    UE.UACESDKHelper.Init()
end

--[[
    登录
]]
function ACESDKCtrl:AceLogin()
    if not self:IsSDKEnable() then
        return
    end
    local AccountInfo = self:GetModel(LoginModel):GetLoginAccountInfo()
    local AccountId = self:GetModel(UserModel):GetSdkOpenId()
    local ZoneID = self:GetModel(UserModel).ZoneID
    CWaring(StringUtil.FormatSimple("ACESDKCtrl AceLogin:{0}_{1}_{2}",AccountId,AccountInfo.AceAccType,ZoneID))
    UE.UACESDKHelper.LoginIn(AccountId, AccountInfo.AceAccType, ZoneID)
end
--[[
    登出
]]
function ACESDKCtrl:AceLogout()
    if not self:IsSDKEnable() then
        return
    end
    CWaring("ACESDKCtrl AceLogout")
    UE.UACESDKHelper.LoginOut()
end

--[[
    在调用 ace_sdk_client_log_in 和 ace_sdk_client_log_out 之间，每隔100ms调用一次。需确保每秒钟调用不小于10次。
    注意仅当此函数返回成功时上报数据（请参阅Demo）。如果暂时没有数据需要上报，函数会返回 ACE_SDK_RESULT_NO_PACKET_NEED_SENDING，此时不需要做任何事情。
    获取到的数据大小不会大于2048字节。
]]--
function ACESDKCtrl:AceSendPacket()
    if not self:IsSDKEnable() then
        return
    end
    local PackData = UE.UACESDKHelper.GetPacketToString()
    if PackData and string.len(PackData) > 0 then
        -- CWaring("ACESDKCtrl:PackData:" .. PackData)
        self:SendProto_AcePackageC2sReq(PackData)
    -- else
    --     CWaring("ACESDKCtrl:AceSendPacket PackData Empty")
    end
end

--[[
    调用时机
    游戏客户端收到游戏服务器下发的ACE数据时。
]]--
function ACESDKCtrl:AceReceivePacket(PackData)
    if not self:IsSDKEnable() then
        return
    end
    if string.len(PackData) > 0 then
        UE.UACESDKHelper.ReceivePacketString(PackData)
    -- else
    --     CWaring("ACESDKCtrl:AceReceivePacket PackData Empty")
    end
end

--[[
    开启定时器，定时采集ACE数据，上报到Lobby服务器
]]
function ACESDKCtrl:StartAceTimer()
    self:StopAceTimer()
    self.AceTimer = Timer.InsertTimer(0.07, function()
        self:AceSendPacket()
    end,true)
end

function ACESDKCtrl:StopAceTimer()
    if self.AceTimer ~= nil then
        Timer.RemoveTimer(self.AceTimer)
        self.AceTimer = nil
    end
end
-----//




