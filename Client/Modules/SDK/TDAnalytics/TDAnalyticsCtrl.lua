--[[
    数数SDK Ctrl 
]]
local class_name = "TDAnalyticsCtrl"
TDAnalyticsCtrl = TDAnalyticsCtrl or BaseClass(UserGameController,class_name)


function TDAnalyticsCtrl:__init()
end

function TDAnalyticsCtrl:Initialize()
    self.bSDKEnable = nil


    self.IsUserLogin = false
end

--- 玩家登出
---@param data any
function TDAnalyticsCtrl:OnLogout(data)
	--TODO 玩家主动登出，需要通知SDK登出，但不触发SDK登出回调（否则触发死循环）
    CWaring("TDAnalyticsCtrl OnLogout")
    self:Logout()
end

function TDAnalyticsCtrl:OnLogin(data)
    CWaring("TDAnalyticsCtrl OnLogin")
end

function TDAnalyticsCtrl:AddMsgListenersUser()
    if not self:IsSDKEnable() then
		return
	end
end

--- 判断SDK是否可用
function TDAnalyticsCtrl:IsSDKEnable()
    if self.bSDKEnable == nil then
        local bIsEnable =  UE.UTDAnalyticsHelper.IsEnable()
        local CustomEnable = true
        if UE.UGFUnluaHelper.IsEditor() then
            CustomEnable = false
            if UE.UGFUnluaHelper.IsRunningGame() then
                CustomEnable = true
            end
        end

        self.bSDKEnable = bIsEnable and CustomEnable or false

        CWaring("TDAnalyticsCtrl:IsSDKEnable():" .. (self.bSDKEnable and "1" or "0"))
    end
	return self.bSDKEnable 
end

--- SDK初始化
function TDAnalyticsCtrl:Init()
    if not self:IsSDKEnable() then
        return
    end
    UE.UTDAnalyticsHelper.Init(GameInstance)
end

--[[
    设置帐号ID
]]
function TDAnalyticsCtrl:Login(AccountId)
    if not self:IsSDKEnable() then
        return ""
    end
    if self.IsUserLogin then
        return
    end
    CWaring("TDAnalyticsCtrl:Login")
    self.IsUserLogin = true
	UE.UTDAnalyticsHelper.Login(AccountId)
end
--[[
    数数帐号登出
]]
function TDAnalyticsCtrl:Logout()
    if not self:IsSDKEnable() then
        return ""
    end
    if not self.IsUserLogin then
        return
    end
    CWaring("TDAnalyticsCtrl:Logout")
    self.IsUserLogin = false
	UE.UTDAnalyticsHelper.Logout()
end

--[[
    获取访客ID
]]
function TDAnalyticsCtrl:GetDistinctId()
    if not self:IsSDKEnable() then
        return ""
    end
	local DistinctId =  UE.UTDAnalyticsHelper.GetDistinctId()
	return DistinctId 
end

--[[
    获取预设属性字符串
]]
function TDAnalyticsCtrl:GetPresetProperties()
    if not self:IsSDKEnable() then
        return ""
    end
	local PresetProperties =  UE.UTDAnalyticsHelper.GetPresetProperties()
	return PresetProperties 
end

--[[
    校准时间，登入后调用
    @param timestamp 时间戳 秒
]]
function TDAnalyticsCtrl:CalibrateTime(timestamp)
    if not self:IsSDKEnable() then
        return
    end
	UE.UTDAnalyticsHelper.CalibrateTime(timestamp)
end

--[[
    设置事件公用属性
]]
function TDAnalyticsCtrl:SetSuperPropertiesWithJsonStr(JsonStr)
    if not self:IsSDKEnable() then
        return
    end
    if not JsonStr then
        return
    end
    CWaring("TDAnalyticsCtrl:SetSuperPropertiesWithJsonStr:" .. JsonStr)
	UE.UTDAnalyticsHelper.SetSuperPropertiesWithJsonStr(JsonStr)
end

--[[
    发送事件
]]
function TDAnalyticsCtrl:TrackWithJsonStr(EventName,JsonStr)
    if not self:IsSDKEnable() then
        return
    end
	UE.UTDAnalyticsHelper.TrackWithJsonStr(EventName,JsonStr)
end

--[[
    获取数数AppId
]]
function TDAnalyticsCtrl:GetAppId()
    if not self:IsSDKEnable() then
        return ""
    end
	return UE.UTDAnalyticsHelper.GetAppId()
end







