---
--- Convenient lua implementation which uses some interesting features from python and golang.
--- In order to make a clear distinction from normal functions, we make all functions in UPPERCASE.
--- Then you can use them just like using some kind of keywords.
--- Reference: https://bytedance.feishu.cn/docs/doccnkrzBMFuMm8GbJpOw896nRd
--- Created by zhonghua.elvis.
--- DateTime: 2020/5/15 14:58
---
require "debug"

---
--- Inner functions
---
-------------------------------------------------------------------------------------------

---
--- Inner functions for pythonic decorator which is recommended for global functions.
---
local switchGlobalDecorators = {}
local globalDecorators = {}

local function setCurEnvDec()
    local old_env = getfenv(3)
    local old_mt = getmetatable(old_env) or {}
    local old_newindex = old_mt.__newindex
    local old_index = old_mt.__index
    local mt = {
        __newindex = function (t, k, v)
            if #globalDecorators > 0 and next(globalDecorators) and type(v) == "function" then
                for i = #globalDecorators, 1, -1 do
                    v = globalDecorators[i](v)
                end
                globalDecorators = {}
            end
            if old_newindex then
                if type(old_newindex) == "table" then
                    old_newindex[k] = v
                elseif type(old_newindex) == "function" then
                    old_newindex(t, k, v)
                end
            else
                rawset(t, k, v)
            end
        end,
        
        __index = old_index
    }
    setmetatable(old_env, mt)
end

---
--- Inner functions for pythonic decorator which is recommended for CLASS METHODS.
---
local methodDecorators = {}
local dClassIndex = {}
local dClassMT = {
    __newindex = function (t, k, v)
        if #methodDecorators > 0 and next(methodDecorators) and type(v) == "function" then
            for i = #methodDecorators, 1, -1 do
                v = methodDecorators[i](v)
            end
            methodDecorators = {}
        end
        t[dClassIndex][k] = v
    end,

    __index = function(t, k)
        return t[dClassIndex][k]
    end,
}

---
--- API
---
-------------------------------------------------------------------------------------------

--- SIMPLE DECORATOR which is recommended for COMMON FUNCTIONS or HOTFIX.
--- Receives a predefined decorator function and a wrapped function, then returns new function
--- which will call function `dec` and function `fun`.
--- Usages:
---     function checkTypes(...)
---         local types = {...}
---         return function(f, ...)
---             args = {...}
---             print("checkTypes", f, args)
---             for i = 1, table.maxn(types) do
---                 if type(args[i]) ~= types[i] then
---                     error(string.format("Type of arg %d is not %s", i, types[i]), 2)
---                 end
---             end
---             return f(...)
---        end
---     end
---
---     function printFirst(f, ...)
---         print("printFirst", f, ...)
---         return f(...)
---     end
---
---     function test(a, b, c)
---         print("I'm test", a, b, c)
---     end
---     test = DECORATOR_COMMON(printFirst, test)
---     test = DECORATOR_COMMON(checkTypes("number", "string", "boolean"), test)
---
---@param dec function
---@param fun function
---@return function
function DECORATOR_COMMON(dec, fun)
    return function(...)
        dec(fun, ...)
    end
end

---
--- PYTHONIC DECORATOR which is recommended for GLOBAL FUNCTIONS.
--- Receives a predefined decorator function and record it for global metatable.__newindex.
--- Usages:
--- Decorator functions example
---     function checkTypes(...)
---         local types = {...}
---         return function(f)
---             return function(...)
---                 args = {...}
---                 print("checkTypes", f, args)
---                 for i = 1, table.maxn(types) do
---                     if type(args[i]) ~= types[i] then
---                         error(string.format("Type of arg %d is not %s", i, types[i]), 2)
---                     end
---                 end
---                 return f(...)
---             end
---         end
---     end
---
---     function printFirst(f)
---         return function(...)
---             print("printFirst", f, ...)
---             return f(...)
---         end
---     end
---
---     DECORATOR_GLOBAL(printFirst)
---     DECORATOR_GLOBAL(checkTypes("number", "string", "boolean"))
---     function test(a, b, c)
---        print("I'm test", a, b, c)
---     end
---
---@param dec function
---@return nil
function DECORATOR_GLOBAL(dec)
    local old_env = getfenv(2)
    if not switchGlobalDecorators[old_env] then
        setCurEnvDec()
        switchGlobalDecorators[old_env] = true
    end
    globalDecorators[#globalDecorators + 1] = dec
end

---
--- INNER-CLASS METHOD DECORATOR which is recommended for CLASS METHODS.
--- Receives a predefined decorator function and record it for class proxy's metatable.__newindex.
--- Usages(More details can be got in https://bytedance.feishu.cn/docs/doccnkrzBMFuMm8GbJpOw896nRd):
---     function checkTypes(...)
---         local types = {...}
---         return function(f)
---             return function(...)
---                 args = {...}
---                 print("checkTypes", f, args)
---                 for i = 1, table.maxn(types) do
---                     if type(args[i]) ~= types[i] then
---                         error(string.format("Type of arg %d is not %s", i, types[i]), 2)
---                     end
---                 end
---                 return f(...)
---             end
---         end
---     end
---
---     function printFirst(f)
---         return function(...)
---             print("printFirst", f, ...)
---             return f(...)
---         end
---     end
---
---     local classA = {}
---     classA = DECORATOR_PROXY_CLASS(classA)  -- reset classA to support decorator
---
---     DECORATOR_METHOD(printFirst)
---     DECORATOR_METHOD(checkTypes("number", "string", "boolean"))
---     function classA.test(a, b, c)
---         print("I'm test", a, b, c)
---     end
---
--- Wrap class
---@param class table
---@return table
function DECORATOR_PROXY_CLASS(class)
    if getmetatable(class) == dClassMT then
        return class 
    end
    local proxy = {}
    proxy[dClassIndex] = class
    setmetatable(proxy, dClassMT)
    return proxy
end

--- Wrap method
---@param dec function
---@return nil
function DECORATOR_METHOD(dec)
    methodDecorators[#methodDecorators + 1] = dec
end

---
--- Golang style DEFER which usually used for releasing resource before function returning.
--- You can use it in getting lock and releasing lock.
--- Usages:
---    function test()
---        local xx = 12
---        print("xx start", xx)
---        DEFER(
---                function()
---                    xx = 0
---                    print("xx end", xx)
---                end
---        )
---        -- assert(false, "ss")
---        -- error("wrong")
---        print("xx running", xx)
---    end
---
---@param handler function
---@return nil
function DEFER(handler)
    local h, m, c = debug.gethook()
    local fun = debug.getinfo(2, "f").func
    local function hook(mode)
        local caller = debug.getinfo(2, "f").func
        if (mode == "call" and caller == error or caller == assert) or
                (mode == "return" and caller == fun) then
            handler()
            debug.sethook(h, m, c)
        end
    end
    debug.sethook(hook, "cr")
end

---
--- Context manager for code chunk can be used when you need manager logic context.
--- Usages:
---    function contextFun(s)
---        print("context start", s)
---        coroutine.yield(s)
---        print("context end", s)
---    end

---    function test()
---        print("start test")
---        WITH(contextFun, "TEST")(function (res) -- res可以不使用，类似python的as
---            print("use res", res)
---        end)
---        print("end test")
---    end
---
---@param context function(coroutine in fact)
---@return function
function WITH(context, ...)
    co = coroutine.wrap(context)
    res = co(...)
    return function(fun)
        pcall(fun, res)
        co()
    end
end

---
--- Convenient Iterator implemented with yield.
--- Usages:
---    function test(s)
---        print(s)
---        for i = 1, 10 do
---            coroutine.yield(i)
---        end
---        coroutine.yield('do something else ...')
---        coroutine.yield('do something finish ...')
---    end

---    for j in ITERATOR(test, "hello") do
---        print(j)
---    end
---
---@param fun function(coroutine in fact)
---@return function
function ITERATOR(fun, ...)
    local co = coroutine.wrap(fun)
    local args = {...}
    return function()
        return co(unpack(args))
    end
end

---
--- You can call this function in the beginning of lua project if you want to
--- FORBID UNDEFINED VARIABLE. It will raise error when undefined variable is used.
---
function setCurEnvForbidUndefined()
    local old_env = getfenv(1)
    local old_mt = getmetatable(old_env) or {}
    local old_index = old_mt.__index
    local old_newindex = old_mt.__newindex or rawset
    local common_mt_handle = setmetatable({}, {__index=function(_, _) error("Undefned varaible") end})
    local mt = {
        __index = function (t, k)
            local v
            if type(old_index) == "table" then
                v = old_index[k]
            elseif type(old_index) == "function" then
                v = old_index(t, k)
            elseif old_index ~= nil then
                error("Invalid __index")
            end
            if v == nil then
                error("Undefned varaible")
            end
            return v
        end,
        -- 此处对于普通class不处理，因为一方面可能会被外部重设metatable，另一方面普通和数据table太多。故普通class需要的时候自行处理
        -- 目前只处理defineClass中有supers的情况
        __newindex = function(t, k, v)
            if type(v) ~= "table" or v["__supers"] == nil then
                old_newindex(t, k, v)
                return
            end
            local supers = v["__supers"]
            supers[#supers + 1] = common_mt_handle
        end
    }
    setmetatable(old_env, mt)
end
