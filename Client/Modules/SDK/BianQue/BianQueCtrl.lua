require("Client.Modules.SDK.BianQue.BianQueModel")

--[[
    扁鹊SDK Ctrl 
]]
local class_name = "BianQueCtrl"
BianQueCtrl = BianQueCtrl or BaseClass(UserGameController,class_name)


function BianQueCtrl:__init()
end

function BianQueCtrl:Initialize()
end

--- 玩家登出
---@param data any
function BianQueCtrl:OnLogout(data)
	--TODO 玩家主动登出，需要通知SDK登出，但不触发SDK登出回调（否则触发死循环）
    CWaring("BianQueCtrl OnLogout")
end

function BianQueCtrl:OnLogin(data)
    CWaring("BianQueCtrl OnLogin")
    if not self:IsSDKEnable() then
        return
    end
    
    local TheUserModel = MvcEntry:GetModel(UserModel)
    local PlayerId = TheUserModel:GetPlayerId()
    local PlayerName = TheUserModel:GetPlayerName()
    local AppVersion =  TheUserModel:GetAppVersion()
    local DeviceId = UE.UTDAnalyticsHelper.GetDeviceId()
    
    UE.UBianQueHelper.UpdatePortraitInt(BianQueModel.SYSTEMPORTAINT.NETTYPE, 1)
    UE.UBianQueHelper.UpdatePortraitString(BianQueModel.SYSTEMPORTAINT.REGION, "CN")
    UE.UBianQueHelper.UpdatePortraitString(BianQueModel.SYSTEMPORTAINT.ACCOUNT, PlayerId)
    UE.UBianQueHelper.UpdatePortraitString(BianQueModel.SYSTEMPORTAINT.DEVICEID, DeviceId)
    UE.UBianQueHelper.UpdatePortraitString(BianQueModel.SYSTEMPORTAINT.APPVERSION, AppVersion)
    UE.UBianQueHelper.UpdatePortraitString(BianQueModel.USERPORTAINT.ACCOUNTNAME, PlayerName)
    CWaring(string.format("BianQue: PlayerId=%s, DeviceId=%s, PlayerName=%s, AppVersion=%s", PlayerId, DeviceId, PlayerName, AppVersion))
    UE.UBianQueHelper.Flush()
end

--- 判断SDK是否可用
function BianQueCtrl:IsSDKEnable()
	local bIsEnable =  UE.UBianQueHelper.IsEnable()
	return bIsEnable 
end

function BianQueCtrl:Init(IsOversea)
    if not self:IsSDKEnable() then
		return
	end
    if not IsOversea then
        UE.UBianQueHelper.Init(GameInstance, "cn-bq.ingame.tencent.com", 12016)
    else
        UE.UBianQueHelper.Init(GameInstance, "sg-gr-bq.intl.ingame.tencent.com", 12001)
    end
end


function BianQueCtrl:AddMsgListenersUser()
    if not self:IsSDKEnable() then
		return
	end
    CLog("BianQueCtrl AddMsgListenersUser")
    --SDK GMP事件监听
    local SDKTags = UE.USDKTags.Get()
    self.MsgListGMP = {
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.RemoteConfigCallback,Func = Bind(self,self.OnRemoteConfigCallback), bCppMsg = true, WatchedObject = nil },
        { InBindObject = _G.MainSubSystem,	MsgName = SDKTags.TaskCallback,Func = Bind(self,self.OnTaskCallback), bCppMsg = true, WatchedObject = nil },
    }
end



--[[
    远端的配置发生更改: 获取云控配置数据（可以在远端配置更新回调函数中获取）
]]
function BianQueCtrl:OnRemoteConfigCallback(ConfigKey)
    CLog(StringUtil.Format("OnRemoteConfigCallback ==== ConfigKey = {0}", ConfigKey))

    local degreeOfDifficulty = 1.0
    if ConfigKey == "GameDemo_Monster_DegreeOfDifficulty" then
        degreeOfDifficulty = UE.UBianQueHelper.GetRemoteConfigDoubleValue(ConfigKey, 0.0)
        CLog(StringUtil.Format("degreeOfDifficulty = {0}", degreeOfDifficulty))
    else
        local Value = UE.UBianQueHelper.GetRemoteConfigStringValue(ConfigKey, "")
        CLog(StringUtil.Format("Value = {0}", Value))
    end
end


--[[
    远端下发任务
]]
function BianQueCtrl:OnTaskCallback(TaskId, TaskCmd, JsonTaskCmdContent)
    CWaring(StringUtil.Format("OnTaskCallback ==== TaskId = {0}, TaskCmd = {1}, TaskCmdContent = {2}", TaskId, TaskCmd, JsonTaskCmdContent))
    if TaskCmd == "scSettingsModule_Update" then
        local TaskCmdContent = json.decode(JsonTaskCmdContent)
        if TaskCmdContent and TaskCmdContent.settingData then
            UE.UBianQueHelper.ToggleLogSwitch(TaskCmdContent.settingData.LogSwitch == "on" and true or false)
            UE.UBianQueHelper.ToggleResCollect(TaskCmdContent.settingData.ResCollect == "on" and true or false)
            UE.UBianQueHelper.ToggleResUpload(TaskCmdContent.settingData.ResUpload == "on" and true or false)
        end
    end
end