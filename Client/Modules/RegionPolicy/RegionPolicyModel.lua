--[[区域政策]]
local super = GameEventDispatcher;
local class_name = "RegionPolicyModel";
---@class RegionPolicyModel : GameEventDispatcher
RegionPolicyModel = BaseClass(super, class_name);


--[[
    游戏初始化完成，用于一些基础常量的定义，例如从字符串表取值
]]
function RegionPolicyModel:OnGameInit(data) 
end

---【重写】游戏文化初始化完成（初始化/文化发生改变时会调用），用于一些基础常量的定义，例如从字符串表取值(涉及到本地化的)
---@param data any
function RegionPolicyModel:OnCultureInit(data) 
end

--[[
    用户登入/重连，用于初始化数据,当玩家帐号信息同步完成，会触发
    【注意】重连情景也会触发 并不跟OnLogout成对出现，该接口可能会反复触发
    data 为真表示 为断线重连 值为断线重连类型
]]
function RegionPolicyModel:OnLogin(data) 

end

--[[
    用户登出，用于清除旧用户的数据相关  data有值表示为断线重连
    @param data data有值表示为断线重连
]]
function RegionPolicyModel:OnLogout(data)  
end

-- --[[
--     用户即将登出，用于在断线后未返回登录界面前，清除旧用户的数据相关
--     @param data 无作用，占位
-- ]]
-- function RegionPolicyModel:OnPreLogout(data)  
-- end

---【重写】用户重连，登录，用于重连情景需要清除数据的场景
---@param data any data有值表示为断线重连类型
function RegionPolicyModel:OnLogoutReconnect(data) 
end

return RegionPolicyModel