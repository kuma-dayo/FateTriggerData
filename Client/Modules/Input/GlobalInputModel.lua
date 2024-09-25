--[[
    玩家输入事件派发器
]]
local super = GameEventDispatcher;
local class_name = "GlobalInputModel";
---@class GlobalInputModel : GameEventDispatcher
GlobalInputModel = BaseClass(super, class_name);
GlobalInputModel.ON_ANY_INPUT_TRIGGERED = "ON_ANY_INPUT_TRIGGERED"  -- 输入触发通知
GlobalInputModel.ON_GUIBUTTON_PRESSED = "ON_GUIBUTTON_PRESSED"  -- 按钮按下通知

GlobalInputModel.Enable = true

function GlobalInputModel:__init()
    self:DataInit()
end

function GlobalInputModel:DataInit()
    self.Enable = true
end

--[[
    玩家登出时调用
]]
function GlobalInputModel:OnLogout(data)
    if data then
        --断线重连
        return
    end
    -- CWaring("GlobalInputModel:OnLogout===============")
    self:DataInit()
end

--[[
    判断是否需要派发这个事件
]]
function GlobalInputModel:IsListenerCanCall(Listener,LastFocusView)
    if not self.Enable then
        return
    end
    if InputShieldLayer.IsActive() then
        -- 交互屏蔽层存在期间，不响应键盘事件
        return false
    end
    if not Listener then
        return false
    end
    return true
end


return GlobalInputModel;