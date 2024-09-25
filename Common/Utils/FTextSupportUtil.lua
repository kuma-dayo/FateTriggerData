--[[
    FText传递开启

    Lua层需要针对进行支撑
]]
if FTextSupportUtil then
    --保证只执行一次
    return
end
FTextSupportUtil = {}
if FTextSupportUtil.IsEnabledFText == nil then
    --获取Unlua是否开启FText C++对象传递
    FTextSupportUtil.IsEnabledFText = UE.UGFUnluaHelper.IsEnabledFText()
    CWaring("FTextSupportUtil.IsEnabledFText:" .. (FTextSupportUtil.IsEnabledFText and "1" or "0"))
end

local CheckStrIsText = function(Str,TypeStr)
    if not FTextSupportUtil.IsEnabledFText then
        return false
    end
    if Str then
        TypeStr = TypeStr or type(Str)
        if TypeStr == "userdata" and Str.ToString then
            return true
        end
    end
    return false
end

function FTextSupportUtil.CheckStrIsText(Str,TypeStr)
    return CheckStrIsText(Str,TypeStr)
end


if FTextSupportUtil.IsEnabledFText then
    local StringLen = string.len;
    string.len = function(s)
        if CheckStrIsText(s) then
            return StringLen(s:ToString())
        else
            return StringLen(s)
        end
    end

    local StringGsub = string.gsub
    string.gsub = function(s, pattern, repl, n)
        if CheckStrIsText(pattern) then
            CWaring("Pattern Is FText, Please Check Is Need To Use It!",true)
            pattern = pattern:ToString()
        end
        if CheckStrIsText(repl) then
            repl = repl:ToString()
        end
        if CheckStrIsText(s) then
            return StringGsub(s:ToString(),pattern, repl, n)
        else
            return StringGsub(s,pattern, repl, n)
        end
    end


    local StringGmatch = string.gmatch
    string.gmatch = function(s, pattern, init)
        if CheckStrIsText(pattern) then
            CWaring("Pattern Is FText, Please Check Is Need To Use It!",true)
            pattern = pattern:ToString()
        end
        if CheckStrIsText(s) then
            return StringGmatch(s:ToString(),pattern, init)
        else
            return StringGmatch(s,pattern, init)
        end
    end

    local StringFind = string.find
    string.find = function(s, pattern, init, plain)
        if CheckStrIsText(pattern) then
            CWaring("Pattern Is FText, Please Check Is Need To Use It!",true)
            pattern = pattern:ToString()
        end
        if CheckStrIsText(s) then
            return StringFind(s:ToString(),pattern, init, plain)
        else
            return StringFind(s,pattern, init, plain)
        end
    end

    local StringByte = string.byte
    string.byte = function(s, i, j)
        if CheckStrIsText(s) then
            return StringByte(s:ToString(), i, j)
        else
            return StringByte(s, i, j)
        end
    end

    local StringFormat = string.format
    string.format = function(s,  ...)
        if CheckStrIsText(s) then
            return StringFormat(s:ToString(),  ...)
        else
            return StringFormat(s,  ...)
        end
    end

    local StringMatch = string.match
    string.match = function(s, pattern, init)
        if CheckStrIsText(pattern) then
            CWaring("Pattern Is FText, Please Check Is Need To Use It!",true)
            pattern = pattern:ToString()
        end
        if CheckStrIsText(s) then
            return StringMatch(s:ToString(), pattern, init)
        else
            return StringMatch(s, pattern, init)
        end
    end

    local StringSub = string.sub
    string.sub = function(s, i, j)
        if CheckStrIsText(s) then
            return StringSub(s:ToString(), i, j)
        else
            return StringSub(s, i, j)
        end
    end

    local StringRep = string.rep
    string.rep = function(s, n, sep)
        if CheckStrIsText(s) then
            return StringRep(s:ToString(), n, sep)
        else
            return StringRep(s, n, sep)
        end
    end

    local TheToNumber = tonumber
    tonumber = function(e, base)
        if CheckStrIsText(e) then
            return TheToNumber(e:ToString(),base)
        else
            return TheToNumber(e, base)
        end
    end
end
