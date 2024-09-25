--[[
    Steam SDK中间健
]]
require("Client.Modules.SDK.Steam.SteamSDKModel")
local class_name = "SteamSDKCtrl"
SteamSDKCtrl = SteamSDKCtrl or BaseClass(UserGameController,class_name)

function SteamSDKCtrl:__init()
end

function SteamSDKCtrl:Initialize()
    self.bSDKEnable = nil
    self.Model = self:GetModel(SteamSDKModel)
end

--- 玩家登出
---@param data any
function SteamSDKCtrl:OnLogout(data)
	--TODO 玩家主动登出，需要通知SDK登出，但不触发SDK登出回调（否则触发死循环）
    CWaring("SteamSDKCtrl OnLogout")
end

function SteamSDKCtrl:OnLogin(data)
    CWaring("SteamSDKCtrl OnLogin")
end

function SteamSDKCtrl:OnGameInit()
end

function SteamSDKCtrl:AddMsgListenersUser()
    if not self:IsSDKEnable() then
		return
	end
end

--- 判断SDK是否可用
function SteamSDKCtrl:IsSDKEnable()
    if self.bSDKEnable == nil then
        local bIsEnable =  UE.USteamOnlineHelper.IsEnable()
        local CustomEnable = true
        if UE.UGFUnluaHelper.IsEditor() then
            CustomEnable = false
            if UE.UGFUnluaHelper.IsRunningGame() then
                CustomEnable = true
            end
        end

        self.bSDKEnable = bIsEnable and CustomEnable or false

        -- self.bSDKEnable = true
        CWaring("SteamSDKCtrl:IsSDKEnable():" .. (self.bSDKEnable and "1" or "0"))
    end
	return self.bSDKEnable 
end

--[[
    SDK初始化
]]
function SteamSDKCtrl:Init(InContext)
    if not self:IsSDKEnable() then
		return
	end
    local Result = UE.USteamOnlineHelper.Init(InContext)
    if not Result then
        --初始化失败，标记SDK不可用
        self.bSDKEnable = false
    else
        --派发SteamSDK初始化成功通知
        self:GetAppId()
        self.Model:DispatchType(SteamSDKModel.ON_STEAM_SDK_INIT_SUC)
    end
end

--[[
    获取当前生效的SteamAppId
]]
function SteamSDKCtrl:GetAppId()
    if not self:IsSDKEnable() then
		return nil
	end
    local AppId =  UE.USteamOnlineHelper.GetAppId()
    CWaring("SteamSDKCtrl:GetAppId():" .. AppId)
    return AppId
end

--[[
    获取Steam玩家当前名称
]]
function SteamSDKCtrl:GetPlayerNickname()
    if not self:IsSDKEnable() then
		return nil
	end
    local PlayerNickname = UE.USteamOnlineHelper.GetPlayerNickname()
    CWaring("SteamSDKCtrl:GetPlayerNickname():" .. PlayerNickname)
    return PlayerNickname
end
--[[
    获取Steam玩家当前ID
]]
function SteamSDKCtrl:GetUniquePlayerId()
    if not self:IsSDKEnable() then
		return nil
	end
    local UniquePlayerId =  UE.USteamOnlineHelper.GetUniquePlayerId()
    CWaring("SteamSDKCtrl:GetUniquePlayerId():" .. UniquePlayerId)
    return UniquePlayerId
end


--[[
    获取当前玩家头像Texture
]]
function SteamSDKCtrl:GetSelfAvatarTexture()
    if not self:IsSDKEnable() then
		return
	end
    local ImageTexture = UE.USteamOnlineHelper.GetSelfAvatarTexture()
    if ImageTexture then
        CWaring("SteamSDKCtrl:GetSelfAvatarTexture() ImageData Suc")
    else
        CWaring("SteamSDKCtrl:GetSelfAvatarTexture() ImageData Empty")
    end
    return ImageTexture
end





