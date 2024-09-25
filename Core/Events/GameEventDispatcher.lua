require("Core.BaseClass");
require("Core.Events.EventDispatcher");

local class_name = "GameEventDispatcher";

---@class GameEventDispatcher : EventDispatcher
GameEventDispatcher = GameEventDispatcher or BaseClass(EventDispatcher, class_name);

GameEventDispatcher.dispatchers = GameEventDispatcher.dispatchers or {}
GameEventDispatcher.id = GameEventDispatcher.id or 0

MvvmBindTypeEnum = {
    --回调
    CALLBACK = 1,
    --执行SetText动作
    SETTEXT = 2,
}

--[[
游戏内消息派发器 

注意注意！！！！
额外处理：
    在断线重连阶段，不会派发事件，待重连结束才会将事件派发出去 （此功能暂时屏蔽）
]]
function GameEventDispatcher:__init()	
    GameEventDispatcher.id = GameEventDispatcher.id + 1
    if GameEventDispatcher.id >= 1000000000 then
        GameEventDispatcher.id = 1
    end

	self._id = GameEventDispatcher.id
    self._canDispatch = true
    self._cacheDispatchInfos = {}

    self.Mvvm_Key2Setter = {}
    self.Mvvm_Key2AlreadBind = {}

    -- CWaring("GameEventDispatcher new:" .. self._id)
    GameEventDispatcher.dispatchers[self._id] = self;
end

function GameEventDispatcher:__dispose()	
    GameEventDispatcher.dispatchers[self._id] = nil
    self._id = 0
    self._canDispatch = true
    self._cacheDispatchInfos = {}
end

function GameEventDispatcher:GetCanDispatch()
    return self._canDispatch
end
function GameEventDispatcher:SetCanDispatch(value)
    self._canDispatch = value
    -- if self._canDispatch then
    --     for _,info in pairs(self._cacheDispatchInfos) do
    --         -- CWaring("Cache DispatchType:" .. info.type_name)
    --         self:DispatchType(info.type_name, info.data)
    --     end
    --     self._cacheDispatchInfos = {}
    -- end
end

-- --[[
-- 重写DispatchType 当标记为不能发事件时，将事件缓存起来
-- ]]
-- function GameEventDispatcher:DispatchType(type_name, data)
--     if self._canDispatch then
--         return GameEventDispatcher.super.DispatchType(self,type_name,data)
--     else
--         -- CWaring("add Cache DispatchType:" .. type_name)
--         local info = {
--             type_name = type_name,
--             data = data,
--         }
--         table.insert(self._cacheDispatchInfos,info)
--     end
--     return 0;
-- end

function GameEventDispatcher:CleanCacheDispatchInfos()
    self._cacheDispatchInfos = {}
end

--[[
    游戏初始化完成，用于一些基础常量的定义，例如从字符串表取值
]]
function GameEventDispatcher:OnGameInit(data) end

---【重写】游戏文化初始化完成（初始化/文化发生改变时会调用），用于一些基础常量的定义，例如从字符串表取值(涉及到本地化的)
---@param data any
function GameEventDispatcher:OnCultureInit(data) end

--[[
    用户登入/重连，用于初始化数据,当玩家帐号信息同步完成，会触发
    【注意】重连情景也会触发 并不跟OnLogout成对出现，该接口可能会反复触发
    data 为真表示 为断线重连 值为断线重连类型
]]
function GameEventDispatcher:OnLogin(data) end
--[[
    用户登出，用于清除旧用户的数据相关  data有值表示为断线重连
    @param data data有值表示为断线重连
]]
function GameEventDispatcher:OnLogout(data)  end

---【重写】用户重连，登录，用于重连情景需要清除数据的场景
---@param data any data有值表示为断线重连类型
function GameEventDispatcher:OnLogoutReconnect(data) end

--[[
    进行mvvm模拟绑定
    将源 绑定到 指定的属性上
    当属性改变时，会触发源的行为更新
    目前只支持单向绑定（已能满足绝大部分需求）
            属性->源
]]
function GameEventDispatcher:MvvmBind(BindSource,PropertyName,MvvmBindType)
    if not BindSource then
        CError("GameEventDispatcher:Mvvm Not Exist BindSource,Please Check:" .. self:ClassName(),true)
        return
    end
    local EventName = "MvvmBind_" .. PropertyName
    local GetFuncName = "Get" .. PropertyName
    local SetFuncName = "Set" .. PropertyName
    if not self[GetFuncName] then
        self[GetFuncName] = function()
            return self[PropertyName]
        end
    end
    if not self[SetFuncName] then
        CError("GameEventDispatcher:Mvvm Not Exist Setter,Please Check:" .. self:ClassName(),true)
        return
    end
    if not self.Mvvm_Key2Setter[PropertyName] then
        local OlderSetter = self[SetFuncName]
        self[SetFuncName] = function(Handler,TheValue)
            -- CWaring("TheValue:" .. TheValue)
            OlderSetter(self,TheValue)
            self:DispatchType(EventName)
        end
        self.Mvvm_Key2Setter[PropertyName] = true
    end

    self.Mvvm_Key2AlreadBind[PropertyName] = self.Mvvm_Key2AlreadBind[PropertyName] or {}
    if self.Mvvm_Key2AlreadBind[PropertyName][BindSource] then
        CWaring("GameEventDispatcher:Mvvm Repeated Bind:" .. PropertyName .. "|ClassName:" .. self:ClassName())
        return
    end

    local BindAction = self:MvvmBindActionByType(BindSource,MvvmBindType,GetFuncName)
    if not BindAction then
        CError("GameEventDispatcher:Mvvm BindAction nil,Please Check MvvmBindType:" .. self:ClassName(),true)
        return
    end
    BindAction(); 
    self.Mvvm_Key2AlreadBind[PropertyName][BindSource] = BindAction
    self:AddListener(EventName,BindAction)
end

function GameEventDispatcher:MvvmUnBind(BindSource,PropertyName)
    local EventName = "MvvmBind_" .. PropertyName
    local BindAction = self.Mvvm_Key2AlreadBind[PropertyName][BindSource]
    self:RemoveListener(EventName,BindAction)
    self.Mvvm_Key2AlreadBind[PropertyName][BindSource] = nil
end

function GameEventDispatcher:MvvmBindActionByType(BindSource,MvvmBindType,GetFuncName)
    local BindAction = nil
    if MvvmBindType == MvvmBindTypeEnum.SETTEXT then
        BindAction = function()
            local RValue = self[GetFuncName](self)
            -- CWaring("RValue:" .. RValue)
            BindSource:SetText(self[GetFuncName](self))
        end
    elseif MvvmBindType == MvvmBindTypeEnum.CALLBACK then
        BindAction = BindSource
    end
    return BindAction
end


return GameEventDispatcher;