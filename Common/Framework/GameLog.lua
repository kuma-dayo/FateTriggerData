local GameLog = {}

local debug_getinfo = debug.getinfo
local string_format = string.format
local tostring = tostring
local unpack = table.unpack or unpack

local rawPrint = print
--local logInternal = _LogInternal or function(i, ...) rawPrint(...) end

local nativeInfo, nativeWarn, nativeError = (UELog or UEPrint), (UEWarn or UEPrint), (UEError or UEPrint)
nativeInfo = UnLua.Log

local blackList = {}

local function getLogHeader()
    local info=debug_getinfo(3)
    return string_format("<color=#0077ff>%s:%d</color>", info.source, info.currentline)
end

function GameLog.AddToBlackList(modelName)
    blackList[modelName] = true
end

function GameLog.RemoveFromBlacklist(modelName)
    blackList[modelName] = nil
end

function GameLog.Log(modelName, ...)
    if blackList[modelName] then return end
    --logInternal(0, getLogHeader(), modelName, ...)
    nativeInfo(modelName, ...)
end

function GameLog.LogFormat(str, ...)
    --logInternal(0, getLogHeader(), string_format(str, ...))
    nativeInfo(string_format(str, ...))
end

function GameLog.Warning(modelName, ...)
    --logInternal(1, getLogHeader(), modelName, ...)
    nativeWarn(modelName, ...)
end

function GameLog.WarningFormat(str, ...)
    --logInternal(1, getLogHeader(), string_format(str, ...))
    nativeWarn(string_format(str, ...))
end

function GameLog.Error(modelName, ...)
    --logInternal(2, getLogHeader(), modelName, ...)
    nativeError(modelName, ...)
end

function GameLog.ErrorFormat(str, ...)
    --logInternal(2, getLogHeader(), string_format(str, ...))
    nativeError(string_format(str, ...))
end

function GameLog.Debug(...)
    --logInternal(0, getLogHeader(), "[Debug]", ...)
    nativeInfo("[Debug]", ...)
end

_G.print = GameLog.Log
_G.printFormat = GameLog.LogFormat

GameLog.Context = function()

    local funcName = debug.getinfo(2).name

    local name1, value1, ret

    for it = 1, 255 do
        local name, value = debug.getlocal(2, it)

        if name == '(*temporary)' or not name then
            break
        end

        if it == 1 then
            name1 = name
            value1 = value
        else
            if it == 2 then ret = {funcName, name1, value1 == nil and 'nil' or value, nil, nil} end
            ret[it * 2] = name
            ret[it * 2 + 1] = value == nil and 'nil' or value
        end

    end

    if ret then return unpack(ret)
    elseif name1 then return funcName, name1, value1
    else return funcName
    end
end

local print = print

local function dump_value_(v)
    if type(v) == "string" then
        return string_format('"%s"', v)
    end
    return tostring(v)
end

local rawPrint = nativeInfo --function(...) logInternal(0, ...) end
local function split(str, sep)
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end
local function dump(value, description, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local traceback = split(debug.traceback("", 2), "\n")
    --print("dump from: " .. string.trim(traceback[3]))
    for i = 1 , #traceback do
        print(tostring(traceback[i]))
    end

    local function dump_(value, description, indent, nest, keylen)
        description = description or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_value_(description)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, dump_value_(description), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, dump_value_(description), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, dump_value_(description))
            else
                result[#result +1 ] = string.format("%s%s = {", indent, dump_value_(description))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, description, "- ", 1)

    for i, line in ipairs(result) do
        rawPrint(line)
    end
end

--dump table
GameLog.Dump = dump

_G.GameLog = GameLog

_G.Log = GameLog.Log
_G.Warning = GameLog.Warning
_G.Error = GameLog.Error
_G.Dump = GameLog.Dump

GameLog.Log("加载GameLog模块完成")

return GameLog

