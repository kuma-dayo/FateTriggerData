--[[
    Lua层，公用工具方法库
]]

local unpack = unpack or table.unpack
local TablePool = require("Common.Utils.TablePool")

-- 解决原生pack的nil截断问题，SafePack与SafeUnpack要成对使用
function SafePack(...)
	local params = {...}
	params.n = select('#', ...) --返回可变参数的数量,赋值给n
	return params
end

-- 解决原生unpack的nil截断问题，SafePack与SafeUnpack要成对使用
function SafeUnpack(safe_pack_tb)
	return unpack(safe_pack_tb, 1, safe_pack_tb.n)
end

-- 对两个SafePack的表执行连接
function ConcatSafePack(out_concat, safe_pack_l, safe_pack_r)
    -- local concat = {}
    for i = 1,safe_pack_l.n do
        out_concat[i] = safe_pack_l[i]
    end
    for i = 1,safe_pack_r.n do
        out_concat[safe_pack_l.n + i] = safe_pack_r[i]
    end
    out_concat.n = safe_pack_l.n + safe_pack_r.n
    return out_concat
end

---打印表里面的内容
---@param t table 需要打印的table
---@param tipMsg string 需要同时打印的提示文本
---@param needWarning boolean 是否需要以Waring的级别来打印
function print_r (t, tipMsg, needWarning)  
    local printTmp = function(theStr)
        if needWarning then
            if CWaring then
                CWaring(theStr)
            else
                print(theStr)
            end
        else
            print(theStr)
        end
    end
    if tipMsg then
        printTmp(tipMsg .. "====:")
    end
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            printTmp(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        printTmp(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        printTmp(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        printTmp(indent.."["..pos..'] => "'..val..'"')
                    else
                        printTmp(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                printTmp(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        printTmp(tostring(t).." {")
        sub_print_r(t,"  ")
        printTmp("}")
    else
        sub_print_r(t,"  ")
    end
end

--打印Lua堆栈
function print_trackback(tipMsg)
    local ShowStr = tipMsg and (tipMsg .. ":\n" .. debug.traceback()) or debug.traceback()
    if CWaring then
        CWaring(ShowStr)
    else
        print(ShowStr)
    end
end

--[[
    获取table长度
]]
function table_leng(t)
    local leng=0
    for k, v in pairs(t) do
        leng=leng+1
    end
    return leng;
end

-- 判断table是否是空表
function table_isEmpty(t)
    if not t then return true end
    local isEmpty = true
    for k, v in pairs(t) do
        isEmpty = false
        break
    end
    return isEmpty
end
--清空表
function table_clear(tbl)
    for k, v in pairs(tbl) do tbl[k] = nil end
end

-- 闭包绑定
function Bind(self, func, ...)
    -- assert(self == nil or type(self) == "table")
    assert(func ~= nil and type(func) == "function")
    local params = nil
    if self == nil then
        params = SafePack(...)
    else
        params = SafePack(self, ...)
    end
    return function(...)
        if ... then
            local out_concat = TablePool.Fetch("ConcatSafePack")
            ConcatSafePack(out_concat, params, SafePack(...))
            local result = func(SafeUnpack(out_concat))
            TablePool.Recycle("ConcatSafePack", out_concat)
            return result
        else
            local result = func(SafeUnpack(params))
            return result
        end
    end
end

-- 回调绑定
-- 重载形式：
-- 1、成员函数、私有函数绑定：BindCallback(obj, callback, ...)
-- 2、闭包绑定：BindCallback(callback, ...)
function BindCallback(...)
    local bindFunc = nil
    local params = SafePack(...)
    assert(params.n >= 1, "BindCallback : error params count!")
    if type(params[1]) == "table" and type(params[2]) == "function" then
        bindFunc = Bind(...)
    elseif type(params[1]) == "function" then
        bindFunc = Bind(nil, ...)
    else
        error("BindCallback : error params list!")
    end
    return bindFunc
end

function BindPressKeyCallBackWithSound(Callback, Widget)
    if not Widget then
        return Callback
    end
    if not Widget:IsA(UE.UButton) then
        return Callback
    end
    local BindFunc = function()
        if Widget.ClickedSoundEventName and string.len(Widget.ClickedSoundEventName) > 0 then
            SoundMgr:PlaySound(Widget.ClickedSoundEventName) 
        end
        Callback()
    end
    return BindFunc
end

--[[
    深拷贝
]]
function DeepCopy(object)
    local lookup_table = {}
    local i = 0
    local function _copy(object)
        -- print("copy")
        -- print(object)

        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end

        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end

        i = i+1
        -- print("index:" .. i)
            for index, value in pairs(lookup_table) do
            -- print(value)
        end

        return new_table

        --return setmetatable(new_table, {__index = object})
    end

    return _copy(object)
end

--[[
    深拷贝Vecotr
]]
function DeepCopyVector(Vector)
    return UE.FVector(Vector.X,Vector.Y,Vector.Z)
end

--[[
    深拷贝Rotator
]]
function DeepCopyRotator(Rotator)
    return UE.FRotator(Rotator.Pitch,Rotator.Yaw,Rotator.Roll)
end

--[[
    三目运算符
]]
function Triplet(Condition, A, B)
    if Condition then
        return A
    else
        return B
    end
end

--[[
    字符串，减去左右空格
]]
function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end
 
--数组合并，list2合到list1尾，无排序
function ListMerge(List1,List2)
    if not List1 then
        CError("ListMerge List1 Empty")
        return List1
    end
    if List2 == nil or #List2 <=0 then
        return List1
    end
    local NewList = List1
    for Index, Value in ipairs(List2) do
        table.insert(NewList,Value)
    end
    return NewList
end


--保留两位浮点数
function RoundFloat(num)
    return math.floor(num * 100 + 0.5) / 100
end