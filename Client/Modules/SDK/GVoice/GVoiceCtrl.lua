require("Client.Modules.SDK.GVoice.GVoiceModel")

--[[
    GVoice 交互Ctrl
]]

local class_name = "GVoiceCtrl"
---@class GVoiceCtrl
GVoiceCtrl = GVoiceCtrl or BaseClass(UserGameController,class_name)

function GVoiceCtrl:__init()
    self.Model = nil
    -- 成员同步有网络延迟，需要设置一个延迟时间获取
    self.GetRoomMembersDelayTime = 3
    self.PressedCount = 0
    self.IsAutoOpenMic = false
    self.IsAutoOpenSpeaker = false
    self.BanDataSync_Delegate = {}
    self:__dataInit()
end

function GVoiceCtrl:Initialize()
    ---@type GVoiceModel
    self.Model = self:GetModel(GVoiceModel)
end

function GVoiceCtrl:__dataInit()
    
end

function GVoiceCtrl:OnLogin()

end

function GVoiceCtrl:OnLogout()
    self:UnInit()
    self:__dataInit()
end

--[[
    判断返回SDK是否可用
]]
function GVoiceCtrl:IsSDKEnable(DoTip)
    local TheEnable = true
    if not GVoiceModel.FunctionOpen then
        TheEnable = false
    end
    if not UE.UGVoiceHelper:IsEnable() then
        TheEnable = false
    end
    if not TheEnable and DoTip then
        CWaring("GVoice暂不支持")
    end
    return TheEnable
end

function GVoiceCtrl:AddMsgListenersUser()
    if not self:IsSDKEnable() then
        return
    end
    --SDK GMP事件监听
    local SDKTags = UE.USDKTags.Get()
    self.MsgListGMP = {
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.GVoiceSDKInitStateChange,Func = Bind(self,self.GVoiceSDKInitStateChange), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.GVoiceSDKOnJoinRoom,Func = Bind(self,self.GVoiceSDKOnJoinRoom), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.GVoiceSDKOnQuitRoom,Func = Bind(self,self.GVoiceSDKOnQuitRoom), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.GVoiceSDKOnMemberVoice,Func = Bind(self,self.GVoiceSDKOnMemberVoice), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.GVoiceSDKOnRoomMemberVoice,Func = Bind(self,self.GVoiceSDKOnRoomMemberVoice), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.GVoiceSDKOnRoomMemberChanged,Func = Bind(self,self.GVoiceSDKOnRoomMemberChanged), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.GVoiceSDKOnRoomMemberMicChanged,Func = Bind(self,self.GVoiceSDKOnRoomMemberMicChanged), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.GVoiceSDKOnMemberOffline,Func = Bind(self,self.GVoiceSDKOnMemberOffline), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.GVoiceSDKOnMicIsOpen,Func = Bind(self,self.GVoiceSDKOnMicIsOpen), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.GVoiceSDKOnMicState,Func = Bind(self,self.GVoiceSDKOnMicState), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.GVoiceSDKOnRoleChanged,Func = Bind(self,self.GVoiceSDKOnRoleChanged), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.GVoiceSDKOnSpeakerIsOpen,Func = Bind(self,self.GVoiceSDKOnSpeakerIsOpen), bCppMsg = true, WatchedObject = nil },
    }

    self.MsgList = {
		{Model = GlobalInputModel, MsgName = EnhanceInputActionTriggered_Event(GlobalActionMappings.V_Down),	Func = self.OnPressed_V },
		{Model = GlobalInputModel, MsgName = EnhanceInputActionCompleted_Event(GlobalActionMappings.V_Down),	Func = self.OnReleased_V },
		-- {Model = MatchSeverModel, MsgName = MatchSeverModel.ON_MATCH_SERVER_INFO_UPDATED,	Func = self.ON_MATCH_SERVER_INFO_UPDATED_Func },
        {Model = BanModel, MsgName = BanModel.ON_BAN_STATE_CHANGED, Func = self.OnBanDataStateChange },


        {Model = SocketMgr, MsgName = SocketMgr.CMD_ON_MANUAL_CLOSED_PRE, Func = self.CMD_ON_MANUAL_CLOSED_PRE_Func },
    }


    --服务器协议监听
    if GVoiceModel.FunctionOpen then
        self.ProtoList = {
            {MsgName = Pb_Message.GetRtcTokenRsp,	Func = self.GetRtcTokenRsp_Func },
        }
    end
end

function GVoiceCtrl:DoSDKInit()
    if self.Model.SDKInit then
        -- 只有未初始化的时候需要
        return
    end
    -- TODO: AppId,AppKey 后续接入动态
    local PlayerIdStr = MvcEntry:GetModel(UserModel):GetPlayerIdStr()
    local InitParam = self.Model:GetCurUseParam()
    if self:SetAppInfo(InitParam.AppId,InitParam.AppKey,PlayerIdStr) then
        self:SetServerInfo(GVoiceModel.DefaultServerUrl)
        self:Init()
    else
        CError("GVoiceCtrl SetAppInfo Error!") 
    end
end

-- ds服务器信息更新
-- 设置GVoice的服务器域名 并进行初始化
-- function GVoiceCtrl:ON_MATCH_SERVER_INFO_UPDATED_Func()
--     if self.Model.SDKInit then
--         -- 只有未初始化的时候需要
--         return
--     end
--     local MatchSeverModel = MvcEntry:GetModel(MatchSeverModel)
--     local MinPingDs = MatchSeverModel:GetLowestPingSever()
--     local DsGroupId
--     if MinPingDs then
--         DsGroupId = MinPingDs.DsGroupId
--     end
--     self:UpdateServerUrlForDSGroupId(DsGroupId)
--     self:DoSDKInit()
-- end

-- 根据DsGroupId，取对应的Url更新
function GVoiceCtrl:UpdateServerUrlForDSGroupId(DsGroupId)
    local Url = GVoiceModel.DefaultServerUrl   
    if DsGroupId then
        local DsGroupsConfig = MatchSeverModel:GetDsGroupsConfig(DsGroupId)
        if DsGroupsConfig then
            Url = DsGroupsConfig[Cfg_ModeSelect_DsGroupsConfig_P.GVoiceSvrUrl]
        end
    end
    self:SetServerInfo(Url)
end

function GVoiceCtrl:CMD_ON_MANUAL_CLOSED_PRE_Func()
    self:LeaveAllRoom()
end

function GVoiceCtrl:LeaveAllRoom()
    self:QuitAllRoom()
end

-------------------------------------------------------Begin-协议相关-------------------------------------------------------------------
--[[
    服务器返回最新的Token
    message GetRtcTokenRsp
    {
        int64 RoomId    = 1;    // 房间Id
        string RtcToken = 2;    // 生成的RtcToken
    }

    Token这里作为加入房间的RoomName使用
]]
function GVoiceCtrl:GetRtcTokenRsp_Func(Msg)
    print_r(Msg,"GVoiceCtrl:GetRtcTokenRsp_Func:",true)
    local RoomIdStr = tostring(Msg.RoomId)
    self.Model:SetRoomNameByRoomId(RoomIdStr,Msg.RtcToken)
end
--[[
    message GetRtcTokenReq
    {
        int64 RoomId    = 1;    // 房间Id
    }
    根据传入房间ID 生成玩家自身的Token
]]
function GVoiceCtrl:SendProto_GetRtcTokenReq(RoomId)
    local Msg = {
        RoomId = RoomId,
    }
    -- print_r(Msg)
    -- self:SendProto(Pb_Message.GetRtcTokenReq,Msg)

    -- todo 暂时测试
    self:GetRtcTokenRsp_Func({RoomId = RoomId, RtcToken = "RoomName_"..tostring(RoomId)})
end

---------------End-协议相关//

-------------------------------------------------------Begin-SDK交互回调-------------------------------------------------------------------

--[[
	 * SDK初始化状态发生修改时
	 * 回调参数：
	 * bool TheInitValue
]]
function GVoiceCtrl:GVoiceSDKInitStateChange(TheInitValue)
    self.Model.SDKInit = TheInitValue
    if TheInitValue then
        -- 默认开启多房间模式
        self:EnableMultiRoom(true)
    end
    self.Model:DispatchType(GVoiceModel.ON_INIT_STATE_CHANGED, TheInitValue)
end

--[[
     * SDK加入房间后
	 * 回调参数：
	 * FString RoomName
	 * bool IsJoinSuccess
]]
function GVoiceCtrl:GVoiceSDKOnJoinRoom(RoomName,IsJoinSuccess)
    if IsJoinSuccess then
        self.SelfInRoom = true
        -- self.Model.SelfRoomName = RoomName
        self.Model:UpdateRoomInfo(RoomName,self.Model:GetSelfPlayerIdStr(),1,true)
        -- 加入房间后，获取房间内其他成员信息
        self.GetRoomMembersTimer = self:InsertTimer(self.GetRoomMembersDelayTime,function()
            if self.SelfInRoom then
                self:GetRoomMembers(RoomName)    
            end
        end)
        self.Model:DispatchType(GVoiceModel.ON_JOIN_ROOM_SUCCESS,RoomName)
    else
        self.SelfInRoom = false
        self.Model:DispatchType(GVoiceModel.ON_JOIN_ROOM_FAILED,RoomName)
    end
end

--[[
	 * SDK退出房间后
	 * 回调参数：
	 * FString RoomName
	 * bool IsQuitSuccess
]]
function GVoiceCtrl:GVoiceSDKOnQuitRoom(RoomName,IsQuitSuccess)
    print("===================== OnQuitRoom room_name = "..RoomName)
    if IsQuitSuccess then
        -- if self.Model.SelfRoomName and self.Model.SelfRoomName ~= RoomName then
        --     return
        -- end
        if self.GetRoomMembersTimer then
            self:RemoveTimer(self.GetRoomMembersTimer)
            self.GetRoomMembersTimer = nil
        end
        self:__dataInit()
        -- self.Model.SelfRoomName = nil
        self.Model:UpdateRoomInfo(RoomName,self.Model:GetSelfPlayerIdStr(),1,nil)
        if self.Model.SelfRoomName and self.Model.SelfRoomName == RoomName then
            self.Model.SelfRoomName = nil
        end
    end
end

--[[
	* 当房间中的其他成员开始说话或停止说话时，通过该回调接口进行通知。
    * VolArrayJsonStr格式为
    * {
    *	"VolArray" = [
    *		{
    *			"memberid": int,
    *			"status": int (当前状态，零值表示没有说话，非零值表示正在说话)
    *		},...
    *	]
    */
]]
function GVoiceCtrl:GVoiceSDKOnMemberVoice(VolArrayJsonStr)
    local JsonObject = json.decode(VolArrayJsonStr)
    if JsonObject and JsonObject.VolArray then
        local VolArray = JsonObject.VolArray
        for I = 1, #VolArray do
            local MemberVolInfo = VolArray[I]
            local MemberId = MemberVolInfo.memberid
            local Status = MemberVolInfo.status
            if Status > 0 then
                local Level = self:GetSpeakerLevel()
                -- [0, 25]: 无声
                if Level > 25 then
                    print("Others TriggerMicSpeakOn Volume = "..tostring(Level))
                    local Param = {
                        UserIdStr = self.Model:GetMemberUserId(MemberId),
                        Volume = Level
                    }
                    self.Model:DispatchType(GVoiceModel.ON_RECEIVE_REMOTE_AUDIO,Param)
                end
            end
        end
    end
end

--[[
	* 多房间模式下，当玩家加入的多个房间中的某个房间有其他成员开始说话或者停止说话的时候，通过该回调进行通知。
	* FString RoomName
	* int32 MemberId
	* int32 Vol
]]
function GVoiceCtrl:GVoiceSDKOnRoomMemberVoice(RoomName,MemberId,Vol)
    if Vol > 0 then
        print("Others TriggerMicSpeakOn RoomName = "..RoomName.." MemberId = "..tostring(MemberId))
        local Param = {
            UserIdStr = self.Model:GetMemberUserId(MemberId),
            Volume = Vol
        }
        self.Model:DispatchType(GVoiceModel.ON_RECEIVE_REMOTE_AUDIO,Param)
    end
end

--[[
	* 当房间中有成员加入或退出时，通过该回调接口通知。 注：国战语音房间暂不支持该功能。
	* FString RoomName
	* int32 MemberId
	* FString OpenId
	* bool IsIn true 进房/false 退房
]]
function GVoiceCtrl:GVoiceSDKOnRoomMemberChanged(RoomName,MemberId,OpenId,IsIn)
    print(StringUtil.Format("GVoiceSDKOnRoomMemberChanged RoomName = {0} OpenId = {1} MemberId = {2} IsIn = {3}",RoomName, OpenId, MemberId, IsIn and "true" or "false"))
    self.Model:UpdateRoomInfo(RoomName,OpenId,MemberId,IsIn or nil)
    if IsIn then
        local IsForbid = self:IsMemberBeForbidVoice(MemberId)
        self.Model:UpdateSubscribeState(RoomName, OpenId, not IsForbid)
    end
end

--[[
    * 当房间中有成员开/关麦操作时，通过该回调接口通知。 注：国战语音房间暂不支持该功能。
    * FString RoomName
    * int32 MemberId
    * FString OpenId
    * bool IsIn true 开/false 关
]]
function GVoiceCtrl:GVoiceSDKOnRoomMemberMicChanged(RoomName,MemberId,OpenId,IsOpen)
    self.Model:UpdatePublishState(RoomName,OpenId,IsOpen)
end

--[[
    * 当成员掉线时，通过该回调进行通知。
	* 当某玩家断网超过1min时，会从该房间中掉线，需要重新调用进房接口，才能继续游戏。
	* FString RoomName
	* int32 MemberId
]]
function GVoiceCtrl:GVoiceSDKOnMemberOffline(RoomName,MemberId)
    
end

--[[
* 麦克风开启状态改变回调
* bool MicIsOpen
]]
function GVoiceCtrl:GVoiceSDKOnMicIsOpen(IsMicOpen)
    local PlayerIdStr = self.Model:GetSelfPlayerIdStr()
    if not self.Model.SelfRoomName or not PlayerIdStr then
        return
    end
    if IsMicOpen then
        -- 打开麦克风时候，将音量改大
        self:SetMicVolume(100)
    end
    self.Model:UpdatePublishState(self.Model.SelfRoomName,PlayerIdStr,IsMicOpen)
end

--[[
* 麦克风状态改变回调
* int32 State 麦克风状态，0：停止说话，1：开始说话
]]
function GVoiceCtrl:GVoiceSDKOnMicState(State)
    if State > 0 then
        local Level = self:GetMicLevel()
        -- [0, 25]: 无声
        if Level > 25 then
	        print("Self TriggerMicSpeakOn Volume = "..tostring(Level))
            self.Model:DispatchType(GVoiceModel.ON_RECEIVE_LOCAL_AUDIO,Level)
        end
    else
        self.Model:DispatchType(GVoiceModel.ON_RECEIVE_LOCAL_AUDIO_END)
    end
end

--[[
	* 成员角色改变回调
	* 当国战语音房间中的玩家角色发生变化时，通过该回调进行通知，如从主播角色变为观众角色等
	* FString RoomName
	* int32 MemberId
	* uint8 RoleType
]]
function GVoiceCtrl:GVoiceSDKOnRoleChanged(RoomName,MemberId,RoleType)
    --todo
end

--[[
* 扬声器开启状态改变回调
* bool SpeakerIsOpen
]]
function GVoiceCtrl:GVoiceSDKOnSpeakerIsOpen(IsSpeakerOpen)
    -- todo 此回调目前sdk侧存在bug。
--    self.Model:DispatchType(GVoiceModel.ON_SELF_SPEAKER_STATE_CHANGE,IsSpeakerOpen)
end

-------------------------------------------------------End-SDK交互回调-------------------------------------------------------------------

--------------------------------------------------Begin-SDK交互请求---------------------------------------------------------
--[[
    初始化SDK引擎
]]
function GVoiceCtrl:InitEngine(IsOverSea)
    if UE.UGVoiceHelper.InitEngine() then
        -- 目前仅使用海外参数
        -- self.Model.UseParamType = IsOverSea and UE.EGVoiceParamType.International or UE.EGVoiceParamType.Domestic
        if not self.Model then
            self.Model = self:GetModel(GVoiceModel)
        end
        self.Model.UseParamType = UE.EGVoiceParamType.International
    end
end

--[[
    UnInitEngine在USDKSystem中执行
]]

--[[
	/**
	* 在初始化之前，需要设置在官网申请的游戏 ID 和游戏 Key 以及用户的唯一标识 OpenID。
	* 调用时机：获取引擎对象（GetEngine）以后，初始化引擎（Init）之前。
	* 注意：
	* 在使用 GVoice SDK 功能前，需要先在 GCloud 官网的管理控制台注册应用，并开通 GVoice 服务，具体操作详见控制台操作指南。开通服务后，便可在网页上看到所注册游戏的游戏 ID 和游戏 Key
	* OpenID 则为用户的唯一性标识，可以是手 Q 账号、微信账号、设备 ID 等任何可以唯一识别用户的字符序列。
	*/
    UFUNCTION(BlueprintPure, Category = "SDK")
    static bool SetAppInfo(FString app_id, FString app_key, FString open_id);
]]
function GVoiceCtrl:SetAppInfo(AppId,AppKey,OpenId)
    if not self:IsSDKEnable() then
        return false
    end
    if not (AppId and AppKey and OpenId) then
        return false
    end
    if UE.UGVoiceHelper.SetAppInfo(AppId,AppKey,OpenId) then
        self.Model.AppId = AppId
        self.Model.AppKey = AppKey
        self.Model.OpenId = OpenId
        self.Model.PlayerIdStr = OpenId
        return true
    end
    return false
end

--[[
    /**
    * 在初始化之前，需要设置在官网申请的游戏 ID 和游戏 Key 以及用户的唯一标识 OpenID。
    * 调用时机：获取引擎对象（GetEngine）以后，初始化引擎（Init）之前。
    * 注意：
    * 在使用 GVoice SDK 功能前，需要先在 GCloud 官网的管理控制台注册应用，并开通 GVoice 服务，具体操作详见控制台操作指南。开通服务后，便可在网页上看到所注册游戏的游戏 ID 和游戏 Key
    * OpenID 则为用户的唯一性标识，可以是手 Q 账号、微信账号、设备 ID 等任何可以唯一识别用户的字符序列。
    */
    UFUNCTION(BlueprintPure, Category = "SDK")
    static bool SetAppInfo(FString app_id, FString app_key, FString open_id);
]]
function GVoiceCtrl:SetServerInfo(Url)
    if not self:IsSDKEnable() then
        return
    end
    if not Url or Url == "" then
        return
    end
    if UE.UGVoiceHelper.SetServerInfo(Url) then
        CWaring("GVoiceCtrl:SetServerInfo Url = "..Url)
        self.Model.ServerUrl = Url
    end
end

--[[
    //初始化SDK
    UFUNCTION(BlueprintCallable, Category = "SDK")
    static void Init();
]]
function GVoiceCtrl:Init()
    if not self:IsSDKEnable() then
        return
    end
    if not (self.Model.AppId and self.Model.AppKey and self.Model.OpenId) then
        CError("GVoiceCtrl:Init Can't Get AppInfo")
        return
    end
    UE.UGVoiceHelper.Init(GameInstance)
end

--[[
    //卸载SDK
    UFUNCTION(BlueprintCallable, Category = "SDK")
    static void UnInit();
]]
function GVoiceCtrl:UnInit()
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.UnInit()
end

--[[
    // 当系统发生 Pause 事件时，需要同时通知 GVoice 引擎进行 Pause，如应用退后台时
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void Pause();
]]
function GVoiceCtrl:Pause()
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.Pause()
end

--[[
    // 当系统发生 Resume 事件时，需要同时通知 GVoice 引擎进行 Resume，如应用从后台返回时。
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void Resume();
]]
function GVoiceCtrl:Resume()
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.Resume()
end

--[[
    // 设置引擎模式
    // 参数详见 ESDKGCloudVoiceMode
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void SetMode(ESDKGCloudVoiceMode voice_mode);
]]
function GVoiceCtrl:SetMode(voice_mode)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.SetMode(voice_mode)
end

--[[
    设置是否自动开启麦克风，默认为自动开启
    调用JoinRoom之前调用
]]
function GVoiceCtrl:SetIsAutoOpenMic(is_auto_open_mic)
    self.IsAutoOpenMic = is_auto_open_mic
end

--[[
    设置是否自动开启扬声器，默认为自动开启
    调用JoinRoom之前调用
]]
function GVoiceCtrl:SetIsAutoOpenSpeaker(is_auto_open_speaker)
    self.IsAutoOpenSpeaker = is_auto_open_speaker
end

--[[
    /*
	* 加入小队语音房间
	* 调用时机：设置模式（SetMode）为实时语音模式之后，使用小队语音功能（如开关麦克风）之前。
	* room_name：想要加入的房间名；房间名最大长度为127字节且由a-z,A-Z,0-9,-,_组成
	* ms_timeout：加入房间的超时时间，单位是毫秒（5000ms～60000ms）
	* 通过 OnJoinRoom 接收加入结果
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void JoinTeamRoom(FString room_name, int32 ms_timeout = 10000);
]]
function GVoiceCtrl:JoinTeamRoom(room_name,ms_timeout)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    ms_timeout = ms_timeout or 10000
    UE.UGVoiceHelper.JoinTeamRoom(room_name,ms_timeout)
end

--[[
    /*
	* 基于场景的房间管理
	* 小队语音进房，参考中的 JoinTeamRoom 接口，不同点是该函数是基于场景名的房间管理机制。
	* 应用场景：和 JoinTeamRoom 接口使用场景一致。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void JoinTeamRoom_Scenes(FString scenes_name, FString room_name, int32 ms_timeout = 10000);
]]
function GVoiceCtrl:JoinTeamRoom_Scenes(scenes_name,room_name,ms_timeout)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    ms_timeout = ms_timeout or 10000
    print("===================== JoinTeamRoom_Scenes room_name = "..room_name)
    UE.UGVoiceHelper.JoinTeamRoom_Scenes(scenes_name,room_name,ms_timeout)
end

--[[
    /*
	* 加入国战语音房间
	* 使用实时语音的国战语音功能时，需要先加入国战语音房间。国战语音功能介绍详见中的国战语音部分。
	* 调用时机：设置模式（SetMode）为实时语音模式之后，使用国战语音功能（如开关麦克风）之前
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void JoinNationalRoom(FString room_name, ESDKGGCloudVoiceMemberRole role_type, int32 ms_timeout = 10000);
]]
function GVoiceCtrl:JoinNationalRoom(room_name,role_type,ms_timeout)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    ms_timeout = ms_timeout or 10000
    UE.UGVoiceHelper.JoinNationalRoom(room_name,role_type,ms_timeout)
end

--[[
    /*
    * 基于场景的房间管理
    * 国战语音进房，参考 JoinNationalRoom 接口，不同点是该函数是基于场景名的房间管理机制。
    * 应用场景：和 JoinNationalRoom 接口使用场景一致。
    */
    UFUNCTION(BlueprintCallable, Category = "SDK")
    static void JoinNationalRoom_Scenes(FString scenes_name, FString room_name, ESDKGGCloudVoiceMemberRole role_type, int32 ms_timeout = 10000);
]]
function GVoiceCtrl:JoinNationalRoom_Scenes(scenes_name,room_name,role_type,ms_timeout)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    ms_timeout = ms_timeout or 10000
    UE.UGVoiceHelper.JoinNationalRoom_Scenes(scenes_name,room_name,role_type,ms_timeout)
end

--[[
    /*
	* 使用范围语音功能时，需要先加入范围语音房间。范围语音提供在以当前用户为中心的指定半径范围内的语音获取能力，超出该范围的用户的语音将不被听到。范围语音功能介绍详见中的范围语音部分。
	* 调用时机：设置模式（SetMode）为实时语音模式之后，使用范围语音功能（如开关麦克风）之前。
	* 注意：
	* 范围语音属于实时语音，所以需要将语音模式设置为实时模式，即调用 SetMode(RealTime) 方法。
	* GVoice 2.5.0 之前的版本中，范围语音功能只能在多房间模式下使用；从 GVoice 2.5.0 版本开始，范围语音功能支持在非多房间模式下使用，或如小队语音般单独使用
	* 通过 OnJoinRoom 接收加入结果
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void JoinRangeRoom(FString room_name, int32 ms_timeout = 10000);
]]
function GVoiceCtrl:JoinRangeRoom(room_name,ms_timeout)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    ms_timeout = ms_timeout or 10000
    UE.UGVoiceHelper.JoinRangeRoom(room_name,ms_timeout)
end

--[[
    /*
	* 基于场景的房间管理
	* 范围语音进房，参考 JoinRangeRoom 接口，不同点是该函数是基于场景名的房间管理机制。
	* 应用场景：和 JoinRangeRoom 接口使用场景一致。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void JoinRangeRoom_Scenes(FString scenes_name, FString room_name, int32 ms_timeout = 10000);
]]
function GVoiceCtrl:JoinRangeRoom_Scenes(scenes_name,room_name,ms_timeout)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    ms_timeout = ms_timeout or 10000
    UE.UGVoiceHelper.JoinRangeRoom_Scenes(scenes_name,room_name,ms_timeout)
end

--[[
    	/**
	 * 更新坐标
	 * 在范围语音房间中，x、y、z 三点决定了用户在空间中的坐标，r 为半径，即用户可以接收到以(x, y, z)为中心，r 为半径的空间范围内的语音。
	 * 调用时机：加入范围语音房间后。
	 * 注意：坐标为范围语音房间中独有的特性，因此该接口只能在范围语音房间中使用。
	 */
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void UpdateCoordinate(FString room_name, int64 x , int64 y, int64 z, int64 r);
]]
function GVoiceCtrl:UpdateCoordinate(room_name,x,y,z,r)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.UpdateCoordinate(room_name,x,y,z,r)
end

--[[
    /*
	* 打开麦克风
	* 在实时语音的模式下，加入房间成功后（包括小队语音和国战语音），需要打开麦克风才能采集音频并发送到网络，以供房间中其他玩家收听。
	* 调用时机：加入小队语音、国战语音（主播）或范围语音等实时语音房间后
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void OpenMic();
]]
function GVoiceCtrl:OpenMic()
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.OpenMic()
end

--[[
	/*
	* 设置麦克风音量
	* 调节麦克风音量大小，Windows 平台支持 -1000～1000 间的音量，其他平台支持 -150～150 间的音量。
	* 注意：该接口用于设置采集后语音数据的放大或缩小倍数。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void SetMicVolume(int vol);
]]
function GVoiceCtrl:SetMicVolume(vol)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.SetMicVolume(vol)
end

--[[
	/*
	* 获取麦克风音量
	* 获取数据采集时麦克风音量大小。
	* 应用场景：在玩家说话时，实时呈现玩家音量大小，如微信录音时不停闪动的音量条。
	* 调用时机：开麦后。
	* 注意： GetMicLevel 接口返回的是语音数据的均值大小，不是音量值，该接口返回的值是实时变动的，取值范围是 0~65535。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static int GetMicLevel(bool fadeOut = true);
]]
function GVoiceCtrl:GetMicLevel(fadeOut)
    if not self:IsSDKEnable() then
        return 0
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    return UE.UGVoiceHelper.GetMicLevel(fadeOut)
end

--[[
	/*
	* 检测麦克风状态
	* 检测麦克风当前状态，开麦成功，失败或被占用。
	* -1 麦克风处于关闭状态; 0 开麦失败; 1 开麦成功; 2 麦克风被占用
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static int GetMicState();
]]
function GVoiceCtrl:GetMicState()
    if not self:IsSDKEnable() then
        return -1
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    return UE.UGVoiceHelper.GetMicState()
end

--[[
	/**
	* 检测麦克风是否可用
	* 检测麦克风是否可用，可以在开麦前调用，当麦克风状态正常时再开麦。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static bool TestMic();
]]
function GVoiceCtrl:TestMic()
    if not self:IsSDKEnable() then
        return false
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    return UE.UGVoiceHelper.TestMic()
end

--[[
    /**
	* 关闭麦克风
	* 在实时语音的模式下，加入房间成功后（包括小队语音和国战语音），当不需要采集音频发送到网络时，可以调用该接口关闭麦克风
	* 调用时机：麦克风打开后。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void CloseMic();
]]
function GVoiceCtrl:CloseMic()
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.CloseMic()
end

--[[
	/*
	* 打开扬声器
	* 在实时语音的模式下，加入房间成功后（包括小队语音和国战语音），需要打开扬声器才能从网络接收数据并播放。扬声器打开后，才能收听到同一语音房间中的其他玩家的语音内容。
	* 调用时机：加入小队语音、国战语音或范围语音等实时语音房间后。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void OpenSpeaker();
]]

function GVoiceCtrl:OpenSpeaker()
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    local PlatformName = UE.UGameplayStatics.GetPlatformName()
    if PlatformName == "Android" then
        UE.UGVoiceHelper.EnableSpeakerOn(true)
    else
        UE.UGVoiceHelper.OpenSpeaker()
    end
end

--[[
/*
	* 设置扬声器音量
	* 设置扬声器音量，参数表示想要设置的音量大小。
	* 应用场景：提供一个设置项给玩家，让玩家自己控制在现有音量的基础上放大/缩小扬声器播放音量。
	* 调用时机：开扬声器前。
	* vol: 扬声器音量大小，windows 支持的音量为0～100；其他平台支持0～150
	*	实际音量 = (vol / 100 * 原始音量)
	*	即若 vol 等于 120，那么实际音量等于 1.2 倍原始音量
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void SetSpeakerVolume(int vol);
]]
function GVoiceCtrl:SetSpeakerVolume(vol)
    if not self:IsSDKEnable() then
        return 
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    return UE.UGVoiceHelper.SetSpeakerVolume(vol)
end

--[[
/*
* 获取扬声器音量
* 获取扬声器音量，返回值表示音量大小。
* 应用场景：GetSpeakerVolumn 接口获取的是实时的扬声器播放音量，适用于实现类似音乐播放器一样的波形闪动效果。
* 调用时机：开扬声器后。
* 扬声器音量大小: 大于等于零的整数
*/
UFUNCTION(BlueprintCallable, Category = "SDK")
static int GetSpeakerLevel();
]]
function GVoiceCtrl:GetSpeakerLevel()
    if not self:IsSDKEnable() then
        return 0
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    return UE.UGVoiceHelper.GetSpeakerLevel()
end


--[[
    /*
	* 关闭扬声器
	* 在实时语音的模式下，加入房间成功后（包括小队语音和国战语音），当不需要从网络接收数据并播放时，可以调用该接口关闭扬声器。
	* 调用时机：扬声器打开后。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void CloseSpeaker();
]]
	
function GVoiceCtrl:CloseSpeaker()
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    local PlatformName = UE.UGameplayStatics.GetPlatformName()
    if PlatformName == "Android" then
        UE.UGVoiceHelper.EnableSpeakerOn(false)
    else
        UE.UGVoiceHelper.CloseSpeaker()
    end
end

--[[
    /*
	* 退出实时语音房间
	* 当不需要使用实时语音功能或需要切换到其他语音房间时，可以从当前实时语音（包括小队语音和国战语音）房间中退出。
	* 调用时机：加入小队语音、国战语音、范围语音等实时语音房间后。
	* 通过 OnQuitRoom 接收退出结果
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void QuitRoom(FString room_name, int32 ms_timeout = 10000);
]]
function GVoiceCtrl:QuitRoom(room_name,ms_timeout)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    ms_timeout = ms_timeout or 10000
    UE.UGVoiceHelper.QuitRoom(room_name,ms_timeout)
end

--[[
    /*
	* 基于场景的房间管理
	* 退出语音房间，参考 QuitRoom 接口，不同点是该函数是基于场景名的房间管理机制。
	* 应用场景：和 QuiteRoom 接口使用场景一致。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void QuitRoom_Scenes(FString scenes_name, int32 ms_timeout = 10000);
]]
function GVoiceCtrl:QuitRoom_Scenes(scenes_name,ms_timeout)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    ms_timeout = ms_timeout or 10000
    UE.UGVoiceHelper.QuitRoom_Scenes(scenes_name,ms_timeout)
end

--[[
    /**
	* 允许多房间
	* GVoice 提供多房间语音功能，该功能允许同一个用户进入不同的语音房间，分别与不同语音房间的其他用户进行交流。多房间语音功能详见中的多房间模式部分。
	* 注：该功能属于实时语音模式下的功能，所以需要先设置模式为实时语音模式。
	* 调用时机：设置模式（SetMode）为实时语音（RealTime）模式后，加入房间（JoinTeamRoom 或 JoinRangeRoom）之前。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void EnableMultiRoom(bool is_enable);
]]
function GVoiceCtrl:EnableMultiRoom(is_enable)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.EnableMultiRoom(is_enable)
end

--[[
    /*
	* 开关房间麦克风
	* 该接口用于开关多房间模式下某个指定房间的麦克风。
	* 调用时机：开启多房间模式（EnableMultiRoom(true)），并加入至少一个语音房间以后。
	* 注意：在调用该接口时，需要确认当前玩家处于多房间模式下的某个语音房间中。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void EnableRoomMicrophone(FString room_name, bool is_enable);
]]
function GVoiceCtrl:EnableRoomMicrophone(room_name,is_enable)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    if not room_name then
        return
    end
    UE.UGVoiceHelper.EnableRoomMicrophone(room_name,is_enable)
end

--[[
    /**
	* 开关房间扬声器
	* 该接口用于开关多房间模式下某个指定房间的扬声器。
	* 调用时机：开启多房间模式（EnableMultiRoom(true)），并加入至少一个语音房间以后。
	* 注意：在调用该接口时，需要确认当前玩家处于多房间模式下的某个语音房间中。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void EnableRoomSpeaker(FString room_name, bool is_enable);
]]
function GVoiceCtrl:EnableRoomSpeaker(room_name,is_enable)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    if not room_name then
        return
    end
    UE.UGVoiceHelper.EnableRoomSpeaker(room_name,is_enable)
end

--[[
    /**
	* 设置语音收听白名单
	* 设置能够接收到房间中语音的成员列表，如果有调用该接口，那么在列表范围以外的成员将不能接收到房间中的语音内容。
	* 调用时机：实时语音模式下，当前成员和成员 members 均已加入房间 roomName 后。
	* 应用场景：当房间中的语音数据只需要部分玩家收听时，可通过调用该接口实现。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void SetAudience(TArray<int32>& members, FString room_name);
]]
function GVoiceCtrl:SetAudience(members,room_name)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.SetAudience(members,room_name)
end

--[[
    /**
	* 禁止接收某成员语音
	* 该接口控制玩家是否不接收房间中另一名玩家的语音数据。
	* 当 enable 设置为 true 时，该成员将不会接收到房间 roomName 中的成员 member 的语音。
	* 调用时机：实时语音模式下，当前成员和成员 member 均已加入房间 roomName 后。
	* 应用场景：当玩家不想/不需要收听房间中另一名玩家的语音数据时，可通过调用该接口实现。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void ForbidMemberVoice(int32 member_id, bool is_enable, FString room_name);
]]
function GVoiceCtrl:ForbidMemberVoice(room_name,member_id,is_enable)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    if UE.UGVoiceHelper.ForbidMemberVoice(member_id,is_enable,room_name) then
        local UserId = self.Model:GetMemberUserId(room_name,member_id)
        if UserId then
            self.Model:UpdateSubscribeState(room_name,UserId, not is_enable)
        else
            print("GVoiceCtrl:ForbidMemberVoice Not Found User For Id = "..tostring(member_id))
        end
    end
end

--[[
    /**
    * get is the room member's is be mute
    *
    * @param memid: the room member's memberid
    * @return : if the membervoice be forbid,return true(means can't hear this memberid voice), else return false
    */
    UFUNCTION(BlueprintCallable, Category = "SDK")
    static bool IsMemberBeForbidVoice(int32 member_id);    
]]
function GVoiceCtrl:IsMemberBeForbidVoice(member_id)
    if not self:IsSDKEnable() then
        return false
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    local IsForbid = UE.UGVoiceHelper.IsMemberBeForbidVoice(member_id)
    print("IsMemberBeForbidVoice MemberId = "..tostring(member_id).."IsForbid = "..(IsForbid and "true" or "false"))
	return IsForbid
end

--[[
    /*
	* 判断当前用户是否正在讲话
	* 在实时语音模式下，调用该接口可以判断当前用户是否正在讲话。
	* 注： 该接口用于实时语音模式，需要先调用 SetMode 方法设置模式为实时语音模式。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static bool IsSpeaking();
]]
function GVoiceCtrl:IsSpeaking()
    if not self:IsSDKEnable() then
        return false
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
	return UE.UGVoiceHelper.IsSpeaking()
end

--[[
	/*
	* 设置房间成员音量
	* 设置玩家在语音房间内收听语音时的音量。
	* 调用时机： 进房成功后。
	* vol: 0~100
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void SetPlayerVolume(FString player_id, int32 vol);
]]
function GVoiceCtrl:SetPlayerVolume(player_id,vol)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.SetPlayerVolume(player_id,vol)
end

--[[
    /*
	* 获取房间成员音量
	* 获取玩家在语音房间内收听语音时的音量。
	* 调用时机： 进房成功后。
	* PlayerId:需要设置收听音量的玩家 ID; 该 ID 值需与 SetAppInfo 接口中传入的 openid 值一致
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static int32 GetPlayerVolume(FString player_id);
]]
function GVoiceCtrl:GetPlayerVolume(player_id)
    if not self:IsSDKEnable() then
        return 0
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
	return UE.UGVoiceHelper.GetPlayerVolume(player_id)
end

--[[
    /*
    * 获取房间成员信息
    * 获取实时语音房间中的成员人数及其 openID 和 memberID 信息。
    * 调用时机：进房成功后。
    * 返回一个Json字符串，Json格式为
    * {
	*	"MemberList" = [
	*		{
	*			"memberid": int,
	*			"openid": string,
	*			"micstatus": int (1为打开，其他为关闭)
	*		},...
	*	]
	* }
    UFUNCTION(BlueprintCallable, Category = "SDK")
    FString GetRoomMembers(FString roomName);
]]
function GVoiceCtrl:GetRoomMembers(room_name)
    if not self:IsSDKEnable() then
        return nil
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    local RoomMembersJsonStr = UE.UGVoiceHelper.GetRoomMembers(room_name)
    print("OnGetRoomMembers:"..RoomMembersJsonStr)
    if RoomMembersJsonStr ~= "" then
        local JsonObject = json.decode(RoomMembersJsonStr)
        if JsonObject and JsonObject.MemberList then
            local MemberList = JsonObject.MemberList
            local PlayerIdStr = self.Model:GetSelfPlayerIdStr()
            for I = 1, #MemberList do
                local Member = MemberList[I]
                if Member.openid ~= PlayerIdStr then
                    self.Model:UpdateRoomInfo(room_name, Member.openid, Member.memberid, true)
                    self.Model:UpdatePublishState(room_name, Member.openid, Member.micstatus == 1)
                    local IsForbid = self:IsMemberBeForbidVoice(Member.memberid)
                    self.Model:UpdateSubscribeState(room_name, Member.openid, not IsForbid)
                end
            end
        end
    end
end


--[[
    * 获取耳机连接状态
    * 调用该接口可以获取耳机连接状态。
    * 0	无设备连接； 1	连接了有线耳机 ；2	连接了蓝牙耳机
    UFUNCTION(BlueprintCallable, Category = "SDK")
    static int GetAudioDeviceConnectionState();
]]
function GVoiceCtrl:GetAudioDeviceConnectionState()
    if not self:IsSDKEnable() then
        return 0
    end
    if not self.Model:IsGVoiceInited() then
        return 0
    end
    return UE.UGVoiceHelper.GetAudioDeviceConnectionState()
end

--[[
    * 设置有线耳机连接状态
    * true: 耳机已连接 false: 耳机未连接
    UFUNCTION(BlueprintCallable, Category = "SDK")
    static void SetHeadSetState(bool state);
-]]
function GVoiceCtrl:SetHeadSetState(state)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.SetHeadSetState(state)
end


--[[
* 设置蓝牙耳机连接状态
* true: 耳机已连接 false: 耳机未连接
*/
UFUNCTION(BlueprintCallable, Category = "SDK")
static void SetBluetoothState(bool state);
]]
function GVoiceCtrl:SetBluetoothState(state)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.SetBluetoothState(state)
end

--[[
* 开关蓝牙SCO模式
* 当需要使用蓝牙设备采集语音数据时，调用该接口开启蓝牙采集功能。
* 注：默认情况下该功能不开启，如非必须采用蓝牙设备采集语音数据，也请不要调用该接口。该接口需要在引擎初始化以后，开麦前调用。
*/
UFUNCTION(BlueprintCallable, Category = "SDK")
static void EnableBluetoothSCO(bool is_enable);
]]
function GVoiceCtrl:EnableBluetoothSCO(is_enable)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.EnableBluetoothSCO(is_enable)
end


---------------- ~3D语音相关 start -----------
--[[
	/*
	* 开关3D语音功能
	* 应用场景：需要在实时语音（范围语音）中开启/关闭3D语音功能的场景。
	* 调用时机：实时语音模式下进入范围语音房间后调用。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void Enable3DVoice(bool is_enable);
]]
function GVoiceCtrl:Enable3DVoice(is_enable)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.Enable3DVoice(is_enable)
end

--[[
	/*
	* 设置3D位置向量
	* 设置监听者（self）的3D位置向量。
	* 调用时机：开启3D语音功能后调用。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void Set3DPosition(FVector pos);
]]
function GVoiceCtrl:Set3DPosition(pos)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.Set3DPosition(pos)
end

--[[
	/*
	* 设置脸部朝向
	* 设置监听者的脸部（Y轴）朝向向量，如朝前（0,1,0）或朝后（0,-1,0）。
	* 调用时机：开启3D语音功能后调用。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void Set3DForward(FVector forward);
]]
function GVoiceCtrl:Set3DForward(forward)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.Set3DForward(forward)
end

--[[
	/*
	* 设置头部朝向
	* 设置监听者的头部（Z轴）朝向向量，如朝上（0,0,1）或朝后（0,0,-1）。
	* 调用时机：开启3D语音功能后调用。
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void Set3DUpward(FVector upward);
]]
function GVoiceCtrl:Set3DUpward(upward)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.Set3DUpward(upward)
end

--[[
	/*
	* 设置距离-音量属性
	* 设置音量随距离衰减的属性。
	* 调用时机：开启3D语音功能后调用
	* Model: 参见 EVoiceChatAttenuationModel
	* Properties: X - MinDistance 音量开始衰减的距离，0.2 <= MinDistance <= 100
	* Properties: Y - MaxDistance 音量衰减为0的距离，1 <= MaxDistance <= 500
	* Properties: Z - Rolloff 音量衰减速度系数，0.1 <= Rolloff <= 100
	*/
	UFUNCTION(BlueprintCallable, Category = "SDK")
	static void Set3DDistProperties(ESDKGCloudChatAttenuationModel model, FVector properties);
]]
function GVoiceCtrl:Set3DDistProperties(model,properties)
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.Set3DDistProperties(model,properties)
end

---------------- ~3D语音相关 end -----------

function GVoiceCtrl:QuitAllRoom()
    if not self:IsSDKEnable() then
        return
    end
    if not self.Model:IsGVoiceInited() then
        return
    end
    UE.UGVoiceHelper.QuitAllRoom()
end

--------------------------------------------------End-SDK交互请求---------------------------------------------------------
-- 控制是否响应按键，进入房间才开始响应
function GVoiceCtrl:SetKeyboardIsOpen(IsOpen)
    self.IsKeyboardOpen = IsOpen
end


-- 语音聊天，按下说话
function GVoiceCtrl:OnPressed_V()
    --[[
        PressedCount 逻辑是因为，当按下V键期间，打开带输入框的界面，输入焦点进入输入框；
        当焦点离开输入框后，V的响应会变成Triggered和Completed交替出现，暂找不到别的解决方法
        先判断当持续响应Triggered，才是正常的Down状态 @chenyishui
    ]]
    if not self.Model.SelfRoomName then
        return
    end
    self.PressedCount = self.PressedCount + 1
    if self.PressedCount < 5 then return end
	if not self.IsKeyboardOpen or self.IsPressingKey then
		return
	end
	local SystemMenuModel = MvcEntry:GetModel(SystemMenuModel)
	if not (SystemMenuModel:GetVoiceSetting(SystemMenuConst.VoiceSettingType.VoiceIsOpen) and SystemMenuModel:GetVoiceSetting(SystemMenuConst.VoiceSettingType.VoiceMode)) then
		return
	end
	if not self:TestMic() then
		return
	end
	if not self.Model:IsUserIdInRoom(self.Model.SelfRoomName,self.Model:GetSelfPlayerIdStr()) then
		return
	end
    self:EnableRoomMicrophone(self.Model.SelfRoomName,true)
	self.IsPressingKey = true
end

function GVoiceCtrl:OnReleased_V()
    self.PressedCount = 0
    if not self.IsKeyboardOpen then
        return
    end
	if self.IsPressingKey then
	    local SystemMenuModel = MvcEntry:GetModel(SystemMenuModel)
        if SystemMenuModel:GetVoiceSetting(SystemMenuConst.VoiceSettingType.VoiceMode) then
            -- 松开按键检测，只有状态为‘按键说话’，才处理闭麦
            self:EnableRoomMicrophone(self.Model.SelfRoomName,false)
        end
		self.IsPressingKey = false
	end
end

-- 语音封禁状态变化
function GVoiceCtrl:OnBanDataStateChange(Msg)
    if not (Msg and Msg.BanType) or Msg.BanType ~= Pb_Enum_BAN_TYPE.BAN_VOICE  then
        return
    end
    self:CallBanDataSyncDelegate(Msg)
    local IsBan = Msg.IsBan
    local TeamModel = MvcEntry:GetModel(TeamModel)
    if IsBan then
        -- 开始封禁，要调用退出当前语音房间
        TeamModel:QuitTeamVoiceRoom()
    else
        -- 封禁结束调用一下加入语音房间
        TeamModel:EnterTeamVoiceRoom()
    end
end

function GVoiceCtrl:OnJoinTeamRoomOutside(RoomName)
    self.Model.SelfRoomName = RoomName
    -- 是否自动打开麦克风
    if self.IsAutoOpenMic and self:TestMic() then
        self:EnableRoomMicrophone(self.Model.SelfRoomName,true)
    else
        self:EnableRoomMicrophone(self.Model.SelfRoomName,false)
    end
    -- 是否自动打开扬声器
    if self.IsAutoOpenSpeaker then
        self:EnableRoomSpeaker(self.Model.SelfRoomName,true)
    else
        self:EnableRoomSpeaker(self.Model.SelfRoomName,false)
    end
end

--【【安全合规】禁止语音功能接口（AQ）】https://www.tapd.cn/68880148/bugtrace/bugs/view/1168880148001022733 局内接入
-- lua模拟多播委托
function GVoiceCtrl:BindBanDataSyncDelegate(Context,Delegate)
    print("(Wzp)GVoiceCtrl >> BindBanDataSyncDelegate ")
    table.insert(self.BanDataSync_Delegate,{Obj = Context,Func =Delegate })
end

function GVoiceCtrl:CallBanDataSyncDelegate(Msg)
    print("(Wzp)GVoiceCtrl >> CallBanDataSyncDelegate ")
    for _, delegate in ipairs(self.BanDataSync_Delegate) do
        delegate.Func(delegate.Obj,Msg)
    end
end

function GVoiceCtrl:UnBindBanDataSyncDelegate()
    print("(Wzp)GVoiceCtrl >> UnBindBanDataSyncDelegate ")
    --如果你的事件多次调用，那代表你没解绑
    self.BanDataSync_Delegate = {}
end
