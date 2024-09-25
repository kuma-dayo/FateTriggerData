--[[
    在线子系统管理
]]
local class_name = "OnlineSubCtrl"
OnlineSubCtrl = OnlineSubCtrl or BaseClass(UserGameController,class_name)


--[[
    在线子系统类型枚举
]]
OnlineSubCtrl.OnlineSubTypeEnum = {
    NONE = 0,
    STEAM = 1,
}


function OnlineSubCtrl:__init()
end

function OnlineSubCtrl:Initialize()
    self.OnlineSubType2Name = {
        [OnlineSubCtrl.OnlineSubTypeEnum.STEAM] = "Steam"
    }
    --不同在线子系统对应的是否启用接口
    self.OnlineSubType2SDKEnabled = {
        [OnlineSubCtrl.OnlineSubTypeEnum.STEAM] = function()
            return self:GetSingleton(SteamSDKCtrl):IsSDKEnable()
        end,
    }
    --不同在线子系统对应的初始化接口
    self.OnlineSubType2Init = {
        [OnlineSubCtrl.OnlineSubTypeEnum.STEAM] = function(InContext)
            self:GetSingleton(SteamSDKCtrl):Init(InContext)
        end,
    }
    --不同在线子系统对应的获取玩家昵称接口
    self.OnlineSubType2GetPlayerNickname = {
        [OnlineSubCtrl.OnlineSubTypeEnum.STEAM] = function()
            return self:GetSingleton(SteamSDKCtrl):GetPlayerNickname()
        end,
    }
    --不同在线子系统对应的获取玩家ID接口
    self.OnlineSubType2GetUniquePlayerId = {
        [OnlineSubCtrl.OnlineSubTypeEnum.STEAM] = function()
            return self:GetSingleton(SteamSDKCtrl):GetUniquePlayerId()
        end,
    }
    --不同在线子系统对应的获取玩家头像接口
    self.OnlineSubType2GetSelfAvatarTexture = {
        [OnlineSubCtrl.OnlineSubTypeEnum.STEAM] = function()
            return self:GetSingleton(SteamSDKCtrl):GetSelfAvatarTexture()
        end,
    }
end

function OnlineSubCtrl:OnGameInit()
    self.OnlineSubType = UE.USDKSystem.GetRunningOnlineSubType()

    CWaring("OnlineSubCtrl:OnGameInit OnlineSubType:" .. self.OnlineSubType)
end

--- 玩家登出
---@param data any
function OnlineSubCtrl:OnLogout(data)
	--TODO 玩家主动登出，需要通知SDK登出，但不触发SDK登出回调（否则触发死循环）
    CWaring("OnlineSubCtrl OnLogout")
end

function OnlineSubCtrl:OnLogin(data)
    CWaring("OnlineSubCtrl OnLogin")
end

function OnlineSubCtrl:AddMsgListenersUser()
end

--[[
    获取在线子系统类型
]]
function OnlineSubCtrl:GetOnlineSubType()
    return self.OnlineSubType
end
--[[
    获取当前在线子系数类型对应的英文名称
]]
function OnlineSubCtrl:GetOnlineSubTypeName()
    return self.OnlineSubType2Name[self.OnlineSubType] or "None"
end

--[[
    是否启用了在线子系统
]]
function OnlineSubCtrl:IsOnlineEnabled()
    if self.OnlineSubType == OnlineSubCtrl.OnlineSubTypeEnum.NONE then
        return false
    end
    return true;
end

--[[
    检查在线子系统依赖的SDK，是否可用
]]
function OnlineSubCtrl:IsOnlineSDKEnabled()
    if self.OnlineSubType == OnlineSubCtrl.OnlineSubTypeEnum.NONE then
        return false
    end
    local SubTypeFunc  = self.OnlineSubType2SDKEnabled[self.OnlineSubType] or nil
    if not SubTypeFunc then
        local SubType = self.OnlineSubType or "None"
        CWaring("OnlineSubCtrl:IsOnlineSDKEnabled SubTypeFunc nil:" .. SubType)
        return false
    end
    return SubTypeFunc()
end

--[[
    初始化在线子系统
]]
function OnlineSubCtrl:Init(InContext)
    if not self:IsOnlineSDKEnabled() then
		return
	end
    local SubTypeFunc = self.OnlineSubType2Init[self.OnlineSubType] or nil
    SubTypeFunc()

    --设置帐号ID
    local PlayerId = self:GetUniquePlayerId()
    if PlayerId and string.len(PlayerId) > 0 then
        local TheUserModel = self:GetModel(UserModel)
        TheUserModel:SetSdkOpenId(PlayerId)
    end
end

--[[
    获取子系统玩家当前名称
]]
function OnlineSubCtrl:GetPlayerNickname()
    if not self:IsOnlineSDKEnabled() then
		return nil
	end
    local SubTypeFunc  = self.OnlineSubType2GetPlayerNickname[self.OnlineSubType] or nil
    return SubTypeFunc()
end
--[[
    获取子系统玩家当前ID
]]
function OnlineSubCtrl:GetUniquePlayerId()
    if not self:IsOnlineSDKEnabled() then
		return nil
	end
    local SubTypeFunc  = self.OnlineSubType2GetUniquePlayerId[self.OnlineSubType] or nil
    return SubTypeFunc()
end

--[[
    获取子系统玩家当前头像
]]
function OnlineSubCtrl:GetSelfAvatarTexture()
    if not self:IsOnlineSDKEnabled() then
		return nil
	end
    local SubTypeFunc  = self.OnlineSubType2GetSelfAvatarTexture[self.OnlineSubType] or nil
    return SubTypeFunc()
end






