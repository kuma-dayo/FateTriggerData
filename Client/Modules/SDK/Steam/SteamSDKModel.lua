local super = GameEventDispatcher;
local class_name = "SteamSDKModel";
---@class SteamSDKModel
SteamSDKModel = BaseClass(super, class_name);

-- SteamSDK初始化成功通知
SteamSDKModel.ON_STEAM_SDK_INIT_SUC = "ON_STEAM_SDK_INIT_SUC"


function SteamSDKModel:__init()
end

function SteamSDKModel:OnLogout()
end

return SteamSDKModel;
