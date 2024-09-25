--[[
    异步加载数据模型
]]

local super = GameEventDispatcher;
local class_name = "AsyncLoadAssetModel";

---@class AsyncLoadAssetModel : GameEventDispatcher
---@field private super GameEventDispatcher
AsyncLoadAssetModel = BaseClass(super, class_name)

AsyncLoadAssetModel.ON_ASYNC_LOAD_ASSET_FINISHED = "ON_ASYNC_LOAD_ASSET_FINISHED"

function AsyncLoadAssetModel:__init()
    self:_dataInit()
end

function AsyncLoadAssetModel:_dataInit()
end

--[[
    玩家登出时调用
]]
function AsyncLoadAssetModel:OnLogout(data)
    AsyncLoadAssetModel.super.OnLogout(self)
    self:_dataInit()
end