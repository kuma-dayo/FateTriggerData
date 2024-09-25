local super = GameEventDispatcher;
local class_name = "GVoiceModel";

--[[ 
    GVoice 交互Model
    小队语音使用
]]
---@class GVoiceModel
GVoiceModel = BaseClass(super, class_name);

GVoiceModel.FunctionOpen = true
GVoiceModel.AppParam = {
    [UE.EGVoiceParamType.Domestic] = {
        AppId = "866902464",
        AppKey = "2353246a5b143578b4a3a47e6bedb675"
    },
    [UE.EGVoiceParamType.International] = {
        AppId = "923389807",
        AppKey = "dd98d884482933d721db74af61b3fdcc"
    },
}

GVoiceModel.UseParamType = UE.EGVoiceParamType.International  -- 当前使用海外版，后续看这个参数从哪确定
GVoiceModel.DefaultServerUrl = "udp://sg.voice.gcloudcs.com:8700"   -- 默认域名使用新加坡服务器
GVoiceModel.OpenId = nil

-- 初始化状态变化
GVoiceModel.ON_INIT_STATE_CHANGED = "ON_INIT_STATE_CHANGED"
-- 从服务器请求到RoomName
GVoiceModel.ON_ROOM_ROOMNAME_UPDATE = "ON_ROOM_ROOMNAME_UPDATE"
-- 进房成功
GVoiceModel.ON_JOIN_ROOM_SUCCESS = "ON_JOIN_ROOM_SUCCESS"
-- 进房失败
GVoiceModel.ON_JOIN_ROOM_FAILED = "ON_JOIN_ROOM_FAILED"
-- 房间玩家变化
GVoiceModel.ON_ROOM_USER_LIST_CHANGE = "ON_ROOM_USER_LIST_CHANGE"
-- 房间玩家麦克风状态变化
GVoiceModel.ON_ROOM_USER_PUBLISH_STATE_CHANGE = "ON_ROOM_USER_PUBLISH_STATE_CHANGE"
-- 房间玩家收听状态变化
GVoiceModel.ON_ROOM_USER_SUBSCRIBE_STATE_CHANGE = "ON_ROOM_USER_SUBSCRIBE_STATE_CHANGE"
-- 收到自己麦克风的声音
GVoiceModel.ON_RECEIVE_LOCAL_AUDIO = "ON_RECEIVE_LOCAL_AUDIO"
-- 收到他人麦克风的声音
GVoiceModel.ON_RECEIVE_REMOTE_AUDIO = "ON_RECEIVE_REMOTE_AUDIO"
-- 自己麦克风停止说话
GVoiceModel.ON_RECEIVE_LOCAL_AUDIO_END = "ON_RECEIVE_LOCAL_AUDIO_END"


GVoiceModel.SceneName = {
    HALL = "Hall",
}


--[[
    GVoiceSDK测试参数
]]
GVoiceModel.TestOpen = false
GVoiceModel.TestRoomId = {
    "1",
    "2",
    "3"
}

function GVoiceModel:__init()
    self.AppId = ""
    self.SDKInit = false
    --SDK是否初始化成功
    --[[
        房间Name对应当前房间玩家列表 
        {
            [房间Name] = {
                [玩家ID] = 是否存在状态
            }
        }
    ]]
    self.RoomName2UserIdMap = {}
 --[[
        房间Name对应当前房间玩家列表 
        {
            [房间Name] = {
                [MemberId] = 玩家ID
            }
        }
    ]]
    self.MemberId2UserIdMap = {}
--[[
        房间Name对应当前房间玩家列表 
        {
            [房间Name] = {
                [玩家ID] = MemberId
            }
        }
    ]]
    self.UserId2MemberIdMap = {}
    --[[
        房间Name内 对应每个玩家的开麦情况
        {
            [房间Name] = {
                [玩家ID] = 玩家开麦情况
            }
        }
    ]]
    self.UserId2PublishState = {}

    --[[
        房间Name内  玩家自身对其它玩家的订阅情况
        {
            [房间Name] = {
                [玩家ID] = 是否订阅
            }
        }
    ]]
    self.UserId2SubscribeMap = {}
  --[[
        每个房间，玩家自身的RoomName
    ]]
    self.RoomId2SelfRoomName = {}
    self.PlayerIdStr = nil
    self.SelfRoomName = nil
    self.ServerUrl = nil
end

function GVoiceModel:OnLogout()
    self.RoomName2UserIdMap = {}
    self.MemberId2UserIdMap = {}
    self.UserId2MemberIdMap = {}
    self.UserId2PublishState = {}
    self.UserId2SubscribeMap = {}
    self.RoomId2SelfRoomName = {}
    self.PlayerIdStr = nil
    self.SelfRoomName = nil
    self.BanData = nil
end

--[[
    获取当前正在使用的App参数
]]
function GVoiceModel:GetCurUseParam()
    if GVoiceModel.AppParam[GVoiceModel.UseParamType] then
        return GVoiceModel.AppParam[GVoiceModel.UseParamType]
    end
    return GVoiceModel.AppParam[UE.EGVoiceParamType.Domestic]
end

--[[
    获取使用的服务器Url
]]
function GVoiceModel:GetServerUrl()
    return self.ServerUrl
end

--[[
    SDK是否成功初始化
]]
function GVoiceModel:IsGVoiceInited()
    if not self.SDKInit then
        CWaring("GVoiceCtrl Not Init!",true)
    end
    return self.SDKInit
end

--[[
    获取自身UserId
]]

function GVoiceModel:GetSelfPlayerIdStr()
    if not self.PlayerIdStr then
        CWaring("GetSelfPlayerIdStr Error! Check Is Init Success")
        return MvcEntry:GetModel(UserModel):GetPlayerIdStr()
    end
    return self.PlayerIdStr
end
--[[
    根据房间ID 获取房间名称
]]
function GVoiceModel:GetRoomNameByRoomId(RoomId)
    -- print_r(self.RoomId2SelfToken)
    return self.RoomId2SelfRoomName[RoomId] or nil
end

--[[
    获取指定房间内的 玩家列表
]]
function GVoiceModel:GetRoomUserList(RoomName)
    return self.RoomName2UserIdMap[RoomName] or {}
end

--[[
    根据RoomName和MemberId，获取对应的UserId
]]
function GVoiceModel:GetMemberUserId(RoomName,MemberId)
    if self.MemberId2UserIdMap[RoomName] and self.MemberId2UserIdMap[RoomName][MemberId] then
        return self.MemberId2UserIdMap[RoomName][MemberId]
    end
    return nil
end

--[[
    根据RoomName和UserId，获取对应的MemberId
]]
function GVoiceModel:GetUserMemberId(RoomName,UserId)
    if self.UserId2MemberIdMap[RoomName] and self.UserId2MemberIdMap[RoomName][UserId] then
        return self.UserId2MemberIdMap[RoomName][UserId]
    end
    return nil
end


-- 获取玩家开关麦状态
function GVoiceModel:GetUserPublishState(RoomName,UserId)
    if self.UserId2PublishState[RoomName] and self.UserId2PublishState[RoomName][UserId] then
        return self.UserId2PublishState[RoomName][UserId]
    end
    return false
end

-- 获取对玩家的收听状态
function GVoiceModel:GetUserSubscribeState(RoomName,UserId)
    if self.UserId2SubscribeMap[RoomName] and self.UserId2SubscribeMap[RoomName][UserId] then
        return self.UserId2SubscribeMap[RoomName][UserId]
    end
    return false
end

function GVoiceModel:SetRoomNameByRoomId(RoomId,RoomName)
    if self.RoomId2SelfRoomName[RoomId] and RoomName == self.RoomId2SelfRoomName[RoomId] then
        return
    end
    self.RoomId2SelfRoomName[RoomId] = RoomName
    local Param = {
        RoomId = RoomId,
        RoomName = RoomName
    }
    self:DispatchType(GVoiceModel.ON_ROOM_ROOMNAME_UPDATE,Param)
end

function GVoiceModel:UpdateRoomInfo(RoomName,UserId,MemberId,TheIsInRoom)
    CWaring("GVoiceModel:UpdateRoomInfo RoomName" .. RoomName .. "|UerId:" .. UserId .."|MemberId:" .. MemberId .. "|IsInRoom:" .. (TheIsInRoom and "true" or "false"))
    if UserId == self.PlayerIdStr and not TheIsInRoom then
        -- 自己退房，清除所有房间缓存
        self.RoomName2UserIdMap[RoomName] = {}
        self.MemberId2UserIdMap[RoomName] = {}
        self.UserId2MemberIdMap[RoomName] = {}
        self.UserId2PublishState[RoomName] = {}
        self.UserId2SubscribeMap[RoomName] = {}
    else
        self.RoomName2UserIdMap[RoomName] = self.RoomName2UserIdMap[RoomName] or {}
        self.RoomName2UserIdMap[RoomName][UserId] = TheIsInRoom

        self.MemberId2UserIdMap[RoomName] = self.MemberId2UserIdMap[RoomName] or {}
        self.MemberId2UserIdMap[RoomName][MemberId] = TheIsInRoom and UserId or nil

        self.UserId2MemberIdMap[RoomName] = self.UserId2MemberIdMap[RoomName] or {}
        self.UserId2MemberIdMap[RoomName][UserId] = TheIsInRoom and MemberId or nil
        if not TheIsInRoom then
            self:UpdatePublishState(RoomName,UserId,nil)
            self:UpdateSubscribeState(RoomName,UserId,nil)
        end
    end
    
    self:DispatchType(GVoiceModel.ON_ROOM_USER_LIST_CHANGE)
end

function GVoiceModel:IsUserIdInRoom(RoomName,UserId)
    if not self.RoomName2UserIdMap[RoomName] then
        return
    end
    if not self.RoomName2UserIdMap[RoomName][UserId] then
        return
    end
    CWaring("GVoiceModel:IsUserIdInRoom RoomName:" .. RoomName .. "|UserId:" .. UserId .. "|IsInRoom:" .. (self.RoomName2UserIdMap[RoomName][UserId] and "true" or "false"))
    -- print_r(self.RoomName2UserIdMap)
    return self.RoomName2UserIdMap[RoomName][UserId]
end

--[[
    是否开麦--数据更新
]]
function GVoiceModel:UpdatePublishState(RoomName,UserId,IsMicOpen)
    self.UserId2PublishState[RoomName] = self.UserId2PublishState[RoomName] or {}
    self.UserId2PublishState[RoomName][UserId] = IsMicOpen
    local Param = {
        RoomName = RoomName,
        UserId = UserId,
        IsMicOpen = IsMicOpen
    }
    CWaring("GVoiceModel:UpdatePublishState RoomName:" .. RoomName .. "|UserId:" .. UserId .. "|IsMicOpen:" .. (IsMicOpen and "true" or "false"))
    self:DispatchType(GVoiceModel.ON_ROOM_USER_PUBLISH_STATE_CHANGE,Param)
end

--[[
    是否收听--数据更新
]]
function GVoiceModel:UpdateSubscribeState(RoomName,UserId,IsSubscribe)
    self.UserId2SubscribeMap[RoomName] = self.UserId2SubscribeMap[RoomName] or {}
    self.UserId2SubscribeMap[RoomName][UserId] = IsSubscribe
    CWaring("GVoiceModel:UpdateSubscribeState RoomName:" .. RoomName .. "|UserId:" .. UserId .. "|IsSpeakerOpen:" .. (IsSubscribe and "true" or "false"))
    if IsSubscribe ~= nil then
        local Param = {
            RoomName = RoomName,
            UserId = UserId,
        }
        self:DispatchType(GVoiceModel.ON_ROOM_USER_SUBSCRIBE_STATE_CHANGE,Param)
    end
end

-----------
return GVoiceModel;
