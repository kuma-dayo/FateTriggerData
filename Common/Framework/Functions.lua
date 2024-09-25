local math_floor = math.floor
local math_ceil = math.ceil
local math_max = math.max
local math_min = math.min
local string_find = string.find
local string_gsub = string.gsub
local string_upper = string.upper
local string_sub = string.sub
local table_concat = table.concat
local table_insert = table.insert
local tonumber = tonumber
local tostring = tostring
local type = type
local math_random = math.random
local string_byte = string.byte
local string_char = string.char
local string_format = string.format
local string_len = string.len
local string_lower = string.lower

function traceback(msg)
    msg = debug.traceback(msg or "", 2)
    return msg
end

function LuaGC()
    GameLog.Log("Begin gc count = {0} kb", collectgarbage("count"))

    local StartupGCMode = UE.UUnLuaHelper.GetStartupGCMode()
    GameLog.Log("[LuaGC]Config:[StartupGCMode] = ", StartupGCMode)

    if StartupGCMode == 0 then
        -- Startup配置是分代的情况下，在进局内前仍有可能因为badgc被切换回了增量，因此强制切回分代并收敛内存阈值
        collectgarbage("generational")
        collectgarbage("step")
    elseif StartupGCMode == 1 then
        -- 增量情况下跑一次全量的fullinc
        collectgarbage("collect")
    else
        CError("[LuaGC]Wrong config. Check [UUnLuaSettings::StartupGCMode]")
    end

    GameLog.Log("End gc count = {0} kb", collectgarbage("count"))
end

--------------------------------------------------
-- Util functionsn about table
function RemoveTableItem(list, item, removeAll)
    local rmCount = 0

    for i = 1, #list do
        if list[i - rmCount] == item then
            table.remove(list, i - rmCount)

            if removeAll then
                rmCount = rmCount + 1
            else
                break
            end
        end
    end
end

function table.contains(t, element)
    if t == nil then
        return false
    end

    for _, value in pairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

--- 将src的内容写入dest中, list部分index相同的会覆盖, hash部分key相同的会覆盖
--- dest = {"a","b",nil,"d", name="e"} src = {"A", nil, "C", name="E"}
--- 经过处理之后
--- dest = {"A", nil, "C", "d", name="E"}
function table.merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

--- 将 src table array 部分拼接到 dest table array 部分之后
function table.listmerge(dest, src)
    for _, v in ipairs(src) do
        table.insert(dest, v)
    end
end

--- 将 table array种数字相加返回
function table.listsum(t)
    local ret = 0

    for _, v in ipairs(t) do
        ret = ret + v
    end

    return ret
end

--- @return: 返回 list table, 内容: 两个表 list部分元素的交集
function table.listIntersection(lhs, rhs)
    local ret = {}
    for _, i in ipairs(lhs) do
        for _, j in ipairs(rhs) do
            if i == j then
                ret[#ret + 1] = i
            end
        end
    end
    return ret
end

--- @return: 返回 list table, 内容: 所有[包含]在表a中, 不在表b中的元素
--- 此处包含是指, 该元素存在于 table.values() 之中
function table.arrayDiff(a, b)
    local union = {}
    for _, val in pairs(a) do
        union[val] = true
    end
    for _, val in pairs(b) do
        union[val] = nil
    end

    local ret = {}
    for _, val in pairs(a) do
        if union[val] then
            ret[#ret + 1] = val
        end
    end
    return ret
end

--- @return: 返回 dict table, 内容: 所有[包含]在表a中, 不在表b中的键
--- 此处包含是指, 该元素存在于 table.keys() 之中
function table.dictDiff(a, b)
    local ret = {}
    for key, val in pairs(a) do
        ret[key] = (b[key] == nil and val) or nil
    end
    return ret
end

--- 获取table中的总共包含的元素个数(包含array部分及hash部分)
function table.nums(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function table.keys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end

function table.values(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end

-- From http://lua-users.org/wiki/TableUtils
function table.val_to_str(v)
    if "string" == type(v) then
        v = string.gsub(v, "\n", "\\n")
        if string.match(string.gsub(v, '[^\'"]', ""), '^"+$') then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v, '"', '\\"') .. '"'
    else
        return table.tostring(v)
    end
end

function table.key_to_str(k)
    if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
        return k
    else
        return "[" .. table.val_to_str(k) .. "]"
    end
end

function table.tostring(tbl)
    if "table" ~= type(tbl) or tbl.__cname then
        return tostring(tbl)
    end
    local result, done = {}, {}
    for k, v in ipairs(tbl) do
        table.insert(result, table.val_to_str(v))
        done[k] = true
    end
    for k, v in pairs(tbl) do
        if not done[k] then
            table.insert(result, table.key_to_str(k) .. "=" .. table.val_to_str(v))
        end
    end
    return "{" .. table_concat(result, ",") .. "}"
end

function table.equal(lhs, rhs)
    local lhsType = type(lhs)
    local rhsType = type(rhs)
    if lhsType ~= rhsType then
        return false
    end

    if lhsType ~= "table" then
        return lhs == rhs
    end

    return table.tostring(lhs) == table.tostring(rhs)
end

--- @return: 返回可以用于在表t中索引值v的键
function table.indexOf(t, v)
    for key, value in pairs(t) do
        if value == v then
            return key
        end
    end
end

function table.isNotEmpty(t)
    return t and next(t) and true or false
end

function table.isEmpty(t)
    return (not t or not next(t)) and true or false
end

-- 深拷贝函数（拷贝配表数据，拷贝出来的table将不再是readonly的）
function table.dataCopy(t)
    return _deepCopy(t, {})
end

function _deepCopy(t, seen)
    local vt = type(t)
    if vt == "userdata" then
        error("tiny@table.deepCopy: copy error type userdata")
        return nil
    end

    if vt ~= "table" then
        return t
    end

    -- __data是引擎的包装，对应lua的真实table是__data
    -- 业务关注的也是lua数据，基础函数自动hook, 包装层对脚本开发应该不可见
    if rawget(t, "__data") then
        t = rawget(t, "__data")
    end

    if seen[t] ~= nil then
        return seen[t]
    end

    local ret = setmetatable({}, getmetatable(t))
    seen[t] = ret
    for k, v in pairs(t) do
        ret[k] = _deepCopy(v, seen)
    end

    return ret
end

-- 深拷贝函数
function table.deepCopy(t)
    return _deepCopy(t, {})
end

-- 浅拷贝函数，只拷贝table内第一层元素
function table.copy(t)
    -- __data是引擎的包装，对应lua的真实table是__data
    -- 业务关注的也是lua数据，基础函数自动hook, 包装层对脚本开发应该不可见
    if rawget(t, "__data") then
        t = rawget(t, "__data")
    end

    local ret = setmetatable({}, getmetatable(t))
    for k, v in pairs(t) do
        ret[k] = v
    end
    return ret
end

function table.setMapDefault(t, key)
    if t[key] == nil then
        t[key] = {}
    end
    return t[key]
end

function table.getMapDefault(t, key)
    if t then
        return t[key]
    else
        return nil
    end
end

function PrintLua(name, lib)
    local m
    lib = lib or _G

    for w in string.gmatch(name, "%w+") do
        lib = lib[w]
    end

    m = lib
    if (m == nil) then
        GameLog.Log("Lua Module {0} not exists", name)
        return
    end

    GameLog.Log("-----------------Dump Table {0}-----------------", name)
    if (type(m) == "table") then
        for k, v in pairs(m) do
            GameLog.Log("Key: {0}, Value: {1}", k, tostring(v))
        end
    end

    local meta = getmetatable(m)
    GameLog.Log("-----------------Dump meta {0}-----------------", name)

    while meta ~= nil and meta ~= m do
        for k, v in pairs(meta) do
            if k ~= nil then
                GameLog.Log("Key: {0}, Value: {1}", tostring(k), tostring(v))
            end
        end

        meta = getmetatable(meta)
    end

    GameLog.Log("-----------------Dump meta Over-----------------")
    GameLog.Log("-----------------Dump Table Over-----------------")
end

--------------------------------------------------
-- Util functions about string

--- @return: 将input的字符串的首字母转为小写
function string.lcfirst(input)
    return string_lower(string_sub(input, 1, 1)) .. string_sub(input, 2)
end

function string.starts(str, start)
    if type(str) ~= "string" then
        return false
    end

    return string_sub(str, 1, string_len(start)) == start
end

function string.ends(String, End)
    return End == "" or string_sub(String, -string_len(End)) == End
end

--- 分割指定字符串
--- @input: 目标字符串
--- @delimiter: 分隔符
--- @return: 以 list table 形式存储的分割结果
function string.split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == "") then
        return false
    end
    local pos, arr = 0, {}
    -- for each divider found
    while true do
        local st, sp = string_find(input, delimiter, pos, true)
        if not st then
            break
        end
        table_insert(arr, string_sub(input, pos, st - 1))
        pos = sp + 1
    end

    table_insert(arr, string_sub(input, pos))
    return arr
end

--- 删除字符串头部空白字符
function string.ltrim(input)
    return string_gsub(input, "^[ \t\n\r]+", "")
end

--- 删除字符串尾部空白字符
function string.rtrim(input)
    return string_gsub(input, "[ \t\n\r]+$", "")
end

--- 删除字符串头尾的空白字符
function string.trim(str)
    str = string_gsub(str, "^[ \t\n\r]+", "")
    return string_gsub(str, "[ \t\n\r]+$", "")
end

--- 将输入字符串的首字母转为大写
function string.ucfirst(input)
    return string_upper(string_sub(input, 1, 1)) .. string_sub(input, 2)
end

--- 设置字符串某一位的字符
function string.setbit(input, index, char)
    return string_sub(input, 1, index - 1) .. char .. string_sub(input, index + 1, string.len(input))
end

--- 计算utf8字符串的长度，一个中文算一个字符
function string.utf8len(input)
    local len = string.len(input)
    local left = len
    local cnt = 0
    local arr = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

local function chsize(char)
    local arr = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}

    if not char then
        print("not char")
        return 0
    else
        for i = #arr, 1, -1 do
            if char >= arr[i] then
                return i
            end
        end
    end
end

--- string.sub的utf8版本
function string.utf8sub(str, startChar, numChars)
    local startIndex = 1
    while startChar > 1 do
        local char = string.byte(str, startIndex)
        startIndex = startIndex + chsize(char)
        startChar = startChar - 1
    end
    local currentIndex = startIndex

    while numChars > 0 and currentIndex <= #str do
        local char = string.byte(str, currentIndex)
        currentIndex = currentIndex + chsize(char)
        numChars = numChars - 1
    end
    return str:sub(startIndex, currentIndex - 1)
end

local function checknumber(value, base)
    return tonumber(value, base) or 0
end

--- 将数字转换为千位分割的形式
--- e.g.
--- > print(string.formatnumberthousands(1231341))
--- "1,231,341"
function string.formatnumberthousands(num)
    local formatted = tostring(checknumber(num))
    local k
    while true do
        formatted, k = string_gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then
            break
        end
    end
    return formatted
end

function string.notNilOrEmpty(str)
    return str and string.len(str) > 0
end

string._htmlspecialchars_set = {}
string._htmlspecialchars_set["&"] = "&amp;"
string._htmlspecialchars_set['"'] = "&quot;"
string._htmlspecialchars_set["'"] = "&#039;"
string._htmlspecialchars_set["<"] = "&lt;"
string._htmlspecialchars_set[">"] = "&gt;"

--- 把预定义的字符转换为HTML转义后字符
--- "<color>" 会被转换成 "&lt;color&gt;"
function string.htmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string_gsub(input, k, v)
    end
    return input
end

--- 将HTML转义后字符转换为预定义字符
--- "&lt;color&gt;" 会被转换成 "<color>"
function string.restorehtmlspecialchars(input)
    for k, v in pairs(string._htmlspecialchars_set) do
        input = string_gsub(input, v, k)
    end
    return input
end

--- 在字符串中的每个新行(\n) 之前插入HTML换行符(<br />)
function string.nl2br(input)
    return string_gsub(input, "\n", "<br />")
end

--- 将普通文本转换为 html格式
function string.text2html(input)
    input = string_gsub(input, "\t", "    ")
    input = string.htmlspecialchars(input)
    input = string_gsub(input, " ", "&nbsp;")
    input = string.nl2br(input)
    return input
end

local function urlencodechar(char)
    return "%" .. string_format("%02X", string_byte(char))
end

--- 将字符串进行url编码
function string.urlencode(input)
    -- convert line endings
    input = string_gsub(tostring(input), "\n", "\r\n")
    -- escape all characters but alphanumeric, '.' and '-' and "_"
    input = string_gsub(input, "([^%w%.%-_ ])", urlencodechar)
    -- convert spaces to "+" symbols
    return string_gsub(input, " ", "+")
end

--- 将编码后的url字符串进行界面
function string.urldecode(input)
    input = string_gsub(input, "+", " ")
    input =
        string_gsub(
        input,
        "%%(%x%x)",
        function(h)
            return string_char(checknumber(h, 16))
        end
    )
    input = string_gsub(input, "\r\n", "\n")
    return input
end

--- 生成随机字符串
function string.random(length)
    local bytes = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"
    if length > 0 then
        local ret = ""
        local i = 1
        local len, math_random, string_char, string_byte = #bytes, math.random, string.char, string.byte
        while i <= length do
            ret = ret .. string_char(string_byte(bytes, math_random(1, len)))
            i = i + 1
        end
        return ret
    else
        return ""
    end
end

function string.mongoEscape(input)
    return input:gsub("%$", "\xFF\x04"):gsub("%.", "\xFF\x0E")
end

function string.mongoUnescape(input)
    return input:gsub("\xFF\x04", "$"):gsub("\xFF\x0E", ".")
end

--- 有低概率玩家sdkuid里也包含@字符，需要考虑这种情况
-- @param input string, unisdk认证后返回的accountId
-- @return sdkuid, platform，是2个返回值
function string.parseEmailAddress(input)
    local strs = input:split("@")
    local sdkuid = table_concat(strs, "@", 1, #strs - 1)
    local platform = strs[#strs]
    return sdkuid, platform
end

function Random(x, y)
    return x + (math_random() * (y - x))
end

--unity 对象判断为空, 如果你有些对象是在c#删掉了，lua 不知道
--判断这种对象为空时可以用下面这个函数。
function IsNil(uobj)
    return uobj == nil or uobj:Equals(nil)
end

function NotNil(uobj)
    return not IsNil(uobj)
end

-- isnan
function isnan(number)
    return not (number == number)
end

function math.clamp(val, lower, upper)
    assert(val and lower and upper, "any parameter is nil")
    if lower > upper then
        lower, upper = upper, lower
    end
    return math_max(lower, math_min(upper, val))
end

function math.round(value)
    return value >= 0 and math_floor(value + .5) or math_ceil(value - .5)
end

function math.lerp(from, to, t)
    return from + (to - from) * math.clamp(t, 0, 1)
end

function math.gauss()
    local r1 = math.random()
    local r2 = math.random()
    return math.sqrt(-2 * math.log(r1)) * math.cos(2 * math.pi * r2)
end

----------------------------------
--这段代码对外提供类似C#的string.format功能，支持语序
--示例：xxxLabel.Value = string.formatEx("{0}攻击了{1}", "A", "B")
local formatParams = nil
local function _searchParam(index)
    index = index + 1
    assert(index <= #formatParams and index > 0, "Format error:IndexOutOfRange")
    return tostring(formatParams[index])
end

function string.formatEx(str, ...)
    formatParams = {...}

    return (string.gsub(str, "{(%d)}", _searchParam))
end
----------------------------------
