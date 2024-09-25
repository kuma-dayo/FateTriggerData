--[[
    AppsflyerSteam SDK中间健
]]
local class_name = "AppsflyerSteamCtrl"
AppsflyerSteamCtrl = AppsflyerSteamCtrl or BaseClass(UserGameController,class_name)

function AppsflyerSteamCtrl:__init()
end

function AppsflyerSteamCtrl:Initialize()
    self.bSDKEnable = nil
end

--- 玩家登出
---@param data any
function AppsflyerSteamCtrl:OnLogout(data)
	--TODO 玩家主动登出，需要通知SDK登出，但不触发SDK登出回调（否则触发死循环）
    CWaring("AppsflyerSteamCtrl OnLogout")
end

function AppsflyerSteamCtrl:OnLogin(data)
    CWaring("AppsflyerSteamCtrl OnLogin")
end

function AppsflyerSteamCtrl:OnGameInit()
end

function AppsflyerSteamCtrl:AddMsgListenersUser()
    if not self:IsSDKEnable() then
		return
	end
    self.MsgList = {
        {Model = SteamSDKModel, MsgName = SteamSDKModel.ON_STEAM_SDK_INIT_SUC, Func = self.ON_STEAM_SDK_INIT_SUC_Func },
    }

    self.AppId2DevKey = {
        ["2951950"] = "ZA9aGVGb9FzjTNZ8Vaat5W",
        ["3092530"] = "ZA9aGVGb9FzjTNZ8Vaat5W",
    }
end

--[[
    SteamSDK初始化成功通知
    TODO:
    1.通过SteamSDK 获取GetUniquePlayerId, GetAppId
    2.调用Init
    3.调用SetCustomerUserId
    4.调用Start
]]
function AppsflyerSteamCtrl:ON_STEAM_SDK_INIT_SUC_Func()
    local UniquePlayerId = self:GetSingleton(SteamSDKCtrl):GetUniquePlayerId()
    self:Init(GameInstance)
    self:SetCustomerUserId(UniquePlayerId)
    self:Start()
end

--- 判断SDK是否可用
function AppsflyerSteamCtrl:IsSDKEnable()
    if self.bSDKEnable == nil then
        local bIsEnable =  UE.UAppsflyerSteamHelper.IsEnable()
        local CustomEnable = true
        if UE.UGFUnluaHelper.IsEditor() then
            CustomEnable = false
            if UE.UGFUnluaHelper.IsRunningGame() then
                CustomEnable = true
            end
        end
        self.bSDKEnable = bIsEnable and CustomEnable or false

        -- self.bSDKEnable = false
        CWaring("AppsflyerSteamCtrl:IsSDKEnable():" .. (self.bSDKEnable and "1" or "0"))
    end
	return self.bSDKEnable 
end

--[[
    初始化SDK，需要在Steam启动之后，AppsflyerSteam::SetCustomerUserId之前
]]
function AppsflyerSteamCtrl:Init(InContext)
    if not self:IsSDKEnable() then
		return
	end
    local AppId = self:GetSingleton(SteamSDKCtrl):GetAppId()
    local DevKey = self.AppId2DevKey[AppId]
    if not DevKey then
        CError("AppsflyerSteamCtrl:Init DevKey not Found")
        self.bSDKEnable = false
        return
    end
    local CollectSteamUid = true
    UE.UAppsflyerSteamHelper.Init(InContext,DevKey,AppId,CollectSteamUid)
end

--[[
    设置用户ID，需要在Steam启动之后，AppsflyerSteam::Start之前
]]
function AppsflyerSteamCtrl:SetCustomerUserId(UserId)
    if not self:IsSDKEnable() then
		return
	end
    UE.UAppsflyerSteamHelper.SetCustomerUserId(UserId)
end

--[[
    SDK开始，需要放至Steam启动之后
]]
function AppsflyerSteamCtrl:Start()
    if not self:IsSDKEnable() then
		return
	end
    UE.UAppsflyerSteamHelper.Start(false)
end

--[[
    停止SDK运行，可以在BP_Subsystem OnDeinitialize时触发
]]
function AppsflyerSteamCtrl:Stop()
    if not self:IsSDKEnable() then
		return
	end
    UE.UAppsflyerSteamHelper.Stop()
end

--[[
    进行相关事件上报
]]
function AppsflyerSteamCtrl:LogEvent(EventName,EventValue,CustomEventValue)
    if not self:IsSDKEnable() then
		return
	end
    UE.UAppsflyerSteamHelper.LogEvent(EventName,EventValue,CustomEventValue)
end

--[[
    获取AppsFlyerUIDID
]]
function AppsflyerSteamCtrl:GetAppsFlyerUID()
    if not self:IsSDKEnable() then
		return
	end
    local AppsFlyerUID = UE.UAppsflyerSteamHelper.GetAppsFlyerUID()
    return AppsFlyerUID
end





