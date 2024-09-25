--[[
    协议log数据模型
]]

local super = GameEventDispatcher;
local class_name = "NetProtoLogModel";

---@class NetProtoLogModel : GameEventDispatcher
---@field private super GameEventDispatcher
NetProtoLogModel = BaseClass(super, class_name)

function NetProtoLogModel:__init()
    self:_dataInit()
end

function NetProtoLogModel:_dataInit()
    self.GMOpenNetProtoLog = nil
end

function NetProtoLogModel:OnLogin(data)

end

--[[
    玩家登出时调用
]]
function NetProtoLogModel:OnLogout(data)
    NetProtoLogModel.super.OnLogout(self)
    self:_dataInit()
end

-- 设置GM打开协议log状态
function NetProtoLogModel:SetGMOpenNetProtoLogState(GMOpenNetProtoLogState)
    self.GMOpenNetProtoLog = GMOpenNetProtoLogState
end

--- 检测是否开启协议log打印
---@return boolean 
function NetProtoLogModel:CheckIsOpenNetProtoLog()
    local IsOpenNetProtoLog = true
    if self.GMOpenNetProtoLog ~= nil then
        IsOpenNetProtoLog = self.GMOpenNetProtoLog
    else
        -- shipping包关闭
        if CommonUtil.IsShipping() then
            IsOpenNetProtoLog = false
        end
    end
    return IsOpenNetProtoLog
end