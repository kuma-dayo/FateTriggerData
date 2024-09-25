local const = require("Common.Framework.Constants.Const")
local lume = require("Common.Framework.Lualibs.lume")

TimeUtils = TimeUtils or {}

---倒计时方式展示时间，样式策划初步讨论后的结果
---
--- 常规
--- 秒       文字描述        结果
--- 123456   大于1天         1天 (本地化天)
--- 12345    3时25分45秒    3h25m45s (无本地化)
--- 1234     12分34秒       12m34s (无本地化)
--- 12       12秒           12s  (无本地化)
function TimeUtils.GetTimeString_CountDownStyle(passTimeInSec)
    local ResultParam = {
        IsDay = false,
        Expired = false,
    }
    if passTimeInSec <= 0 then
        ResultParam.Expired = true
        return "--",ResultParam
    end
    local days = math.floor(passTimeInSec / 86400)
    if days > 0 then 
        ResultParam.IsDay = true
        return StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_TimeUtils_Day"), days),ResultParam
    end

    local res = ""
    local hours = math.floor(passTimeInSec / 3600)
    local minutes = math.floor(passTimeInSec % 3600 / 60)
    local seconds = passTimeInSec % 3600 % 60
    
    if hours > 0 then
        res = hours .. "h"
    end
    if minutes > 0 then
        res = res .. minutes .. "m"
    end
    if seconds > 0 then
        res = res .. seconds .. "s"
    end
    
    return res,ResultParam
end

---使用分钟作为单位进行显示处理，不足1分钟显示1分钟。
--- 秒      文字描述      转换结果
--- 4       4s          1分钟
--- 154     2m34s       3分钟
--- 754     12m34s      13分钟
--- 4354    1h12m34s    72分钟
---@param passTimeInSec number 秒数
---@return string 以分钟显示的时间
function TimeUtils.GetTimeStringMin(passTimeInSec)
    passTimeInSec = math.max(0, math.floor(passTimeInSec))
    local hours = math.floor(passTimeInSec / 3600)
    local minutes = math.floor(passTimeInSec % 3600 / 60)
    local seconds = passTimeInSec % 3600 % 60
    
    if seconds > 0 then minutes = minutes + 1 end
    minutes = minutes + hours * 60
    return StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_TimeUtils_Minute"), minutes)
end

---使用冒号分割时间
--- 秒      文字描述      转换结果
--- 4       4s          00:04
--- 34      34s         00:34
--- 154     2m34s       02:34
--- 754     12m34s      12:34
--- 4354    1h12m34s    01:12:34
---@param passTimeInSec number 秒数
---@return string 使用逗号表示的时间字符串
function TimeUtils.GetTimeStringColon(passTimeInSec)
    passTimeInSec = math.max(0, math.floor(passTimeInSec))
    local hours = math.floor(passTimeInSec / 3600)
    local minutes = math.floor(passTimeInSec % 3600 / 60)
    local seconds = passTimeInSec % 3600 % 60

    local res = ""
    --处理小时
    if hours > 0 then
        if hours < 10 then
            res = "0"
        end
        res = res .. hours .. ":"
    end

    --处理分钟
    if minutes < 10 then
        res = res .. "0"
    end
    res = res .. tostring(minutes) .. ":"
    
    --处理秒
    if seconds < 10 then
        res = res .. "0"
    end    
    res = res .. tostring(seconds)
    
    return res
end

-- 将时长（秒）格式化成字符串：x分x秒
-- bForceShowSecond：是否超过1小时也都强制显示时间
function TimeUtils.getTimeStringSimple(passTimeInSec, bForceShowSecond)
    passTimeInSec = math.max(0, math.floor(passTimeInSec))
    local hours = math.floor(passTimeInSec / 3600)
    local mins = math.floor(passTimeInSec % 3600 / 60)
    local seconds = passTimeInSec % 3600 % 60

    local hourStr = 'h' --strConfigData.data.TIME_UTIL_SIMPLE_HOUR
    local minStr = 'm' --strConfigData.data.TIME_UTIL_SIMPLE_MIN
    local secondStr = 's' --strConfigData.data.TIME_UTIL_SIMPLE_SECOND

    if (hours <= 0 and mins > 0) then
        return string.format("%d%s%d%s", mins, minStr, seconds, secondStr)
    end

    if (hours <= 0 and mins <= 0) then
        return string.format("%d%s", seconds, secondStr)
    end

    if bForceShowSecond then
        return string.format("%d%s%d%s%d%s", hours, hourStr, mins, minStr, seconds, secondStr)
    else
        return string.format("%d%s%d%s", hours, hourStr, mins, minStr)
    end
end

-- 输入秒数
-- 返回days, hours, minutes, seconds
function TimeUtils.sec2Time(timeInSec)
    local days = math.floor(timeInSec / const.SECONDS_ONE_DAY)
    local hours = math.floor((timeInSec % const.SECONDS_ONE_DAY) / const.SECONDS_ONE_HOUR)
    local minutes = math.floor((timeInSec % const.SECONDS_ONE_DAY % const.SECONDS_ONE_HOUR) / const.SECONDS_ONE_MINUTE)
    local seconds = timeInSec % const.SECONDS_ONE_DAY % const.SECONDS_ONE_HOUR % const.SECONDS_ONE_MINUTE
    return days, hours, minutes, seconds
end

--[[
    @desc: 获取当前时区数据
    time:2020-04-16 20:15:38
    @return: 时区，夏令时标签
]]
function TimeUtils.getTimeZone()
    -- 获取当前时区
    local timezone = os.difftime(os.time(), os.time(os.date("!*t", os.time())))/3600
    -- 是否有夏令时
    local isdst = os.date("*t", os.time()).isdst

    return timezone, isdst
end

-- 获取时间戳
-- timestr格式 2023-04-06 00:00:00
function TimeUtils.getTimestamp(timestr, useDong8)
    if not timestr or timestr == "" then
        -- CLog("getTimestamp: Param Failed")
        return 0
    end
    
	local patern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
	local year, month, day, hour, min, sec = string.match(timestr, patern)
	local time_table = {year=year, month=month, day=day, hour=hour, min=min, sec=sec}
	
    return TimeUtils.getTimestampByTimeTable(time_table, useDong8)
end

-- 获取时间戳
---@param time_table table:{year=year, month=month, day=day, hour=hour, min=min, sec=sec}
function TimeUtils.getTimestampByTimeTable(time_table, useDong8)
    if useDong8 then
        local curTimestamp = os.time(time_table)
        local curTimeZone, isdst = TimeUtils.getTimeZone()
        local timeInterval = curTimestamp + (curTimeZone - 8) * 3600 + (isdst and -1 or 0) * 3600

        if curTimeZone ~= 8 then
            -- 本地时区不是东8区时打个日志
            CLog("curTimeZone = "..curTimeZone.." isdst = "..tostring(isdst))
            CLog("curTimestamp = "..curTimestamp.." timeInterval = "..timeInterval)
        end
        return timeInterval
    else
        return os.time(time_table)
    end
end

---获取活动下次重置时间的时间戳:特指循环活动
---@param startTimestamp number 活动配置的启动时间戳,单位s(秒)
---@param cycleDays number 活动循环的天数
---@param offsetTime number 服务器返回的重置偏移时间,单位s(秒)
---@return number 单位s(秒)
function TimeUtils.GetActivityNextResetTimestamp(startTimestamp, cycleDays, offsetTime)
    startTimestamp = startTimestamp or 0
    cycleDays = cycleDays or 1
    offsetTime = offsetTime or 0

    local nextTimeStamp = 0
    local stTimeStamp = startTimestamp + offsetTime
    if stTimeStamp > GetTimestamp() then
        nextTimeStamp = stTimeStamp
    else
        ---@type number 活动已经循环了几次 86400 = 24 * 3600
        local cycle_nums = math.floor((GetTimestamp() - stTimeStamp) / (cycleDays * 86400))
        nextTimeStamp =  stTimeStamp +  (cycleDays * 86400) * (cycle_nums + 1)
    end

    -- local serverDate = os.date("!*t",GetTimestamp())
    -- local resetDay = os.date("!*t",nextTimeStamp)
    -- CError(string.format("获取服务器时间戳 = %s-%s-%s %s:%s:%s",serverDate.year,serverDate.month,serverDate.day,serverDate.hour,serverDate.min,serverDate.sec))
    -- CError(string.format("获取活动下次重置时间 = %s-%s-%s %s:%s:%s",resetDay.year,resetDay.month,resetDay.day,resetDay.hour,resetDay.min,resetDay.sec))
    -- CError(string.format("获取活动下次重置时间的时间戳 = %s, 间隔时间 = %s",nextTimeStamp, nextTimeStamp - GetTimestamp()))

    return nextTimeStamp
end

---获取活动下次重置时间的时间戳:特指循环活动
---@param timeStr string 2023-07-13 10:00:00 活动配置的启动时间
---@param cycleDays number 活动循环的天数
---@param offsetTime number 服务器返回的重置偏移时间,单位s(秒)
---@return number 单位s(秒)
function TimeUtils.GetActivityNextResetTimestampPro(timeStr, cycleDays, offsetTime)
    local year, month, day, hour, min, sec = string.match(timeStr, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    if not year or not month or not day or not hour or not min or not sec then
        CError("[cw] Cannot parse timeStr(" .. tostring(timeStr) .. ", please make sure your format looks like 2023-07-13 10:00:00)", true)
        return 0 
    end
        
    local stDateTime = UE.UKismetMathLibrary.MakeDateTime(tonumber(year), tonumber(month), tonumber(day), tonumber(hour), tonumber(min), tonumber(sec))
    -- local utcDate = {year = 0, month = 0, day = 0, hour = 0, min = 0, sec = 0}
    -- utcDate.year, utcDate.month, utcDate.day, utcDate.hour, utcDate.min, utcDate.sec = UE.UKismetMathLibrary.BreakDateTime(stDateTime)
    -- CError(string.format("start = %s-%s-%s %s:%s:%s,stTimeStamp =%s",utcDate.year,utcDate.month,utcDate.day,utcDate.hour,utcDate.min,utcDate.sec,stTimeStamp))
    --计算出基于UTC0的时间戳
    local stTimeStamp = UE.UKismetMathLibrary.ToUnixTimestamp(stDateTime)

    local nextTimeStamp = TimeUtils.GetActivityNextResetTimestamp(stTimeStamp, cycleDays, offsetTime)
    return nextTimeStamp
end

--region 时间戳本地化相关

---内部使用，把时间戳转换为UE的DateTime
---@param TimeStamp number 时间戳 例如：1689242400
---@return userdata UE.DateTime
function TimeUtils._TimestampToDateTime(TimeStamp)
    local DataTimeOffset = UE.UKismetMathLibrary.MakeDateTime(1970, 1, 1)
    local timeStampSpan = UE.UKismetMathLibrary.MakeTimeSpan(0, 0, 0, TimeStamp, 0)
    local dateTime = UE.UKismetMathLibrary.Add_DateTimeTimespan(DataTimeOffset, timeStampSpan);
    return dateTime
end

function TimeUtils.TimestampToDateTime(TimeStamp)
    local UTCO = TimeUtils._TimestampToDateTime(TimeStamp)
    return UE.UKismetMathLibrary.BreakDateTime(UTCO)
end

---内部使用，把UE的DateTime拆分为luaTable
---@param DateTime userdata DateTime
---@return table 以 UTC0 为基准的年、月、日、时、分、秒、毫秒
function TimeUtils._BreakDateTime(DateTime)
    local Year, Month, Day, Hour, Minute, Second, Millisecond = UE.UKismetMathLibrary.BreakDateTime(DateTime)
    return {
        Year = Year,
        Month = Month,
        Day = Day,
        Hour = Hour,
        Minute = Minute,
        Second = Second,
        Millisecond = Millisecond
    }
end

---传入时间戳，获取UTC0及本地的时间，以table的形式展示
---@param TimeStamp number 时间戳 例如：1689242400
---@return table 包含原始时间戳，UTC0时间及本地时间
function TimeUtils.TableTime_FromTimeStamp(TimeStamp)
    local UTCO = TimeUtils._TimestampToDateTime(TimeStamp)
    local Year, Month, Day, Hour, Minute, Second, Millisecond = UE.UKismetMathLibrary.BreakDateTime(UTCO)
    local LocalTimeStamp = os.time({year = Year, month = Month, day = Day, hour = Hour, min = Minute, sec = Second})
    local Dif = TimeStamp - LocalTimeStamp
    local TempDateTime = UE.UKismetMathLibrary.Add_DateTimeTimespan(UTCO, UE.UKismetMathLibrary.MakeTimeSpan(0, 0, 0, Dif, 0))
    local T_Year, T_Month, T_Day, T_Hour, T_Minute, T_Second, T_Millisecond = UE.UKismetMathLibrary.BreakDateTime(TempDateTime)
    
    local res = {
        OriginTimeStamp = TimeStamp,
        --UTC0
        UTC0 = {
            Year = Year,
            Month = Month,
            Day = Day,
            Hour = Hour,
            Minute = Minute,
            Second = Second
        },
        --当地时间
        Local = {
            Year = T_Year,
            Month = T_Month,
            Day = T_Day,
            Hour = T_Hour,
            Minute = T_Minute,
            Second = T_Second
        }}
    
    return res
end

--- OptionTimeZone 描述：
--- GMT+0, GMT+1, ... GMT+8,
--- GMT（Greenwich Mean Time，格林威治标准时间）是指经过英格兰伦敦市郊格林威治的本初子午线的标准时间。
--- 它是世界上最早的标准时间之一，从1884年开始使用。在全球范围内，许多国家和地区都使用GMT作为参考时间，以便协调全球的时间计算。

--- 在明确当前时区、是否使用夏令时之前，最好不要使用这个函数 
--- 1689242400 Thu 2023-07-13 10:00:00 GMT+0
---            Thu 2023-07-13 18:00:00 GMT+8
--- 调用 TimeUtils.TimeStamp_FromTimeStr("2023-07-13 10:00:00") 为 1689213600
---     TimeUtils.TimeStamp_FromTimeStr("2023-07-13 10:00:00", "GMT+8") 为 1689242400
---@param TimeStr string 例如：2023-07-13 10:00:00
---@param OptionTimeZone string 传入的时间所处的时区，例如：GMT+8
---@param IsDst boolean 是否是夏令时
---@return number 时间戳，例如：1689242400
function TimeUtils.TimeStamp_FromTimeStr(TimeStr, OptionTimeZone, IsDst)
    --计算出基于UTC0的时间戳
    local year, month, day, hour, min, sec = string.match(TimeStr, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    if not year or not month or not day or not hour or not min or not sec then
        CError("[cw] Cannot parse TimeStr(" .. tostring(TimeStr) .. ", please make sure your format looks like 2023-07-13 10:00:00)")
        CError(debug.traceback())
        return nil 
    end
    local curTimestamp = os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec, isdst = IsDst})

    --因为传入的时间可能是其他时区的，所以需要修正一下
    OptionTimeZone = OptionTimeZone or "GMT+0"
    if not OptionTimeZone then CError("[cw] Please specify your time zone") return end
    local offsetDir, offsetNum = string.match(OptionTimeZone, "GMT([+-])([0-9]*)")
    if not offsetDir or not offsetNum then CError("[cw] Please use format looks like GMT+8") return end
    local OffsetSec = offsetNum * (offsetDir == "-" and -3600 or 3600)
        
    --修正时区
    local adjustTimeStamp = curTimestamp + OffsetSec
    return adjustTimeStamp
end

---获取传入时间戳的 UTC0 时间字符串，未修正
---@param TimeStamp number 时间戳 例如：1689242400
---@return string 例如：2023年7月13日
function TimeUtils.DateStr_FromTimeStamp(TimeStamp)
    local DateTime = TimeUtils._TimestampToDateTime(TimeStamp)
    local Str = UE.UKismetTextLibrary.AsDate_DateTime(DateTime)
    return Str
end

---获取传入时间戳的 UTC0 时间字符串，未修正
---@param TimeStamp number 时间戳 例如：1689242400
---@return string 例如：上午10:00:00
function TimeUtils.TimeStr_FromTimeStamp(TimeStamp)
    local DateTime = TimeUtils._TimestampToDateTime(TimeStamp)
    local Str = UE.UKismetTextLibrary.AsTime_DateTime(DateTime)
    return Str
end

---获取传入时间戳的 UTC0 时间字符串，未修正
---@param TimeStamp number 时间戳 例如：1689242400
---@return string 例如：2023年7月13日 上午10:00:00 
function TimeUtils.DateTimeStr_FromTimeStamp(TimeStamp)
    local DateTime = TimeUtils._TimestampToDateTime(TimeStamp)
    local Str = UE.UKismetTextLibrary.AsDateTime_DateTime(DateTime)
    return Str
end


---获取传入时间戳的 UTC0 时间字符串，未修正
---@param TimeStamp number 时间戳 例如：1689242400
---@return string 例如：yyyy-MM-dd HH:mm:ss
function TimeUtils.DateTimeStr2_FromTimeStamp(TimeStamp)
    -- 将时间戳转换为表格形式的日期和时间
    local dateTable = os.date("*t", TimeStamp)
    -- 格式化日期和时间为 yyyy-MM-dd HH:mm:ss
    local formattedDate = string.format("%04d-%02d-%02d %02d:%02d:%02d",
                                        dateTable.year, dateTable.month, dateTable.day,
                                        dateTable.hour, dateTable.min, dateTable.sec)

    return formattedDate
end

---获取传入时间戳的当地时间的时间字符串，使用获取到的时区作为修正
---如所处的国家为中国，时区为 GMT+8，那么调用 TimeUtils.ZoneDateStr_FromTimeStamp(1689242400) 结果为 2023年7月13日
---如果想调整为其他时区，例如 GMT+0，那么调用 TimeUtils.ZoneDateStr_FromTimeStamp(1689242400, "GMT+0") 结果为 2023年7月13日
---如果想调整为其他时区，例如 GMT-11，那么调用 TimeUtils.ZoneDateStr_FromTimeStamp(1689242400, "GMT-11") 结果为 2023年7月12日
---@param TimeStamp number 时间戳 例如：1689242400
---@param OptionTimeZone string 需要偏移的时区，不传的话会默认取得当前时区，例如：GMT+8
---@return string 例如：2023年7月13日
function TimeUtils.ZoneDateStr_FromTimeStamp(TimeStamp, OptionTimeZone)
    local DateTime = TimeUtils._TimestampToDateTime(TimeStamp)
    local Str = UE.UKismetTextLibrary.AsTimeZoneDate_DateTime(DateTime, OptionTimeZone)
    return Str
end

---获取传入时间戳的当地时间的时间字符串，使用获取到的时区作为修正
---如所处的国家为中国，时区为 GMT+8，那么调用 TimeUtils.ZoneTimeStr_FromTimeStamp(1689242400) 结果为 下午6:00:00
---如果想调整为其他时区，例如 GMT+3，那么调用 TimeUtils.ZoneTimeStr_FromTimeStamp(1689242400, "GMT+3") 结果为 下午1:00:00
---如果想调整为其他时区，例如 GMT+0，那么调用 TimeUtils.ZoneTimeStr_FromTimeStamp(1689242400, "GMT+0") 结果为 上午10:00:00
---@param TimeStamp number 时间戳 例如：1689242400
---@param OptionTimeZone string 需要偏移的时区，不传的话会默认取得当前时区，例如：GMT+8
---@return string 例如：下午6:00:00
function TimeUtils.ZoneTimeStr_FromTimeStamp(TimeStamp, OptionTimeZone)
    local DateTime = TimeUtils._TimestampToDateTime(TimeStamp)
    local Str = UE.UKismetTextLibrary.AsTimeZoneTime_DateTime(DateTime, OptionTimeZone)
    return Str
end

---获取传入时间戳的当地时间的时间字符串，使用获取到的时区作为修正
---如所处的国家为中国，时区为 GMT+8，那么调用 TimeUtils.ZoneDateTimeStr_FromTimeStamp(1689242400) 结果为 2023年7月13日 下午6:00:00
---如果想调整为其他时区，例如 GMT+3，那么调用 TimeUtils.ZoneDateTimeStr_FromTimeStamp(1689242400, "GMT+3") 结果为 2023年7月13日 下午1:00:00 
---如果想调整为其他时区，例如 GMT+0，那么调用 TimeUtils.ZoneDateTimeStr_FromTimeStamp(1689242400, "GMT+0") 结果为 2023年7月13日 上午10:00:00 
---@param TimeStamp number 时间戳 例如：1689242400
---@param OptionTimeZone string 需要偏移的时区，不传的话会默认取得当前时区，例如：GMT+8
---@return string 例如：2023年7月13日 下午6:00:00 (UTC0 为 2023年7月13日 上午10:00:00，如果不传入OptionTimeZone的话，就取到了当地的时区，所以就导致)
function TimeUtils.ZoneDateTimeStr_FromTimeStamp(TimeStamp, OptionTimeZone)
    local DateTime = TimeUtils._TimestampToDateTime(TimeStamp)
    local Str = UE.UKismetTextLibrary.AsTimeZoneDateTime_DateTime(DateTime, OptionTimeZone)
    return Str
end

---快捷计算出经过了多长时间，返回Ue.TimeSpan结构
---TimeSpan与DateTime不一样，前者表示的是一段时间的长度，后者表示的是一个时间点
---@param PassDay number 经过的小时，默认为0
---@param PassHour number 经过的小时，默认为0
---@param PassMinutes number 经过的分钟，默认为0
---@param PassSecond number 经过的秒，默认为0
---@param PassMillisecond number 经过的毫秒，默认为0
function TimeUtils._PassTimeToTimeSpan(PassDay, PassHour, PassMinutes, PassSecond, PassMillisecond)
    PassDay = PassDay or 0
    PassHour = PassHour or 0
    PassMinutes = PassMinutes or 0
    PassSecond = PassSecond or 0
    PassMillisecond = PassMillisecond or 0
    
    return UE.UKismetMathLibrary.MakeTimeSpan(PassDay, PassHour, PassMinutes, PassSecond, PassMillisecond)
end

---传入经过的秒数，转化为本地化时间字符串
function TimeUtils.TimeStr_FromPassSecond(PassSecond)
    local timeSpan = TimeUtils._PassTimeToTimeSpan(0, 0, 0, PassSecond, 0)
    local str = UE.UKismetTextLibrary.AsTimespan_Timespan(timeSpan)
    return str
end

-- @param time
-- @return 获取0点时间戳
function TimeUtils.GetOffsetDayZeroTime(Time, OffsetDay)
    OffsetDay = OffsetDay or 0
    local Ts = os.date("*t", math.max(Time, 0))
    return os.time({ year = Ts.year, month = Ts.month, day = Ts.day + OffsetDay, hour = 0, min = 0, sec = 0 }) or 0
end

--计算出基于UTC0的时间戳
---@param TimeStr string 格式为2024-7-15 00:00:00
function TimeUtils.TimeStampUTC0_FromTimeStr(TimeStr)
    local year, month, day, hour, min, sec = string.match(TimeStr, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    if not year or not month or not day or not hour or not min or not sec then
        CError("[cw] Cannot parse TimeStr(" .. tostring(TimeStr) .. ", please make sure your format looks like 2023-07-13 10:00:00)")
        CError(debug.traceback())
        return nil 
    end
    --因为本地时间可能是其他时区的，所以需要修正一下
    local offsetNum, IsDst = TimeUtils.getTimeZone()
    local curTimestamp = os.time({year = year, month = month, day = day, hour = hour, min = min, sec = sec, isdst = IsDst})

    if not offsetNum then CError("[cw] Please use format looks like GMT+8") return end
    local OffsetSec = offsetNum * 3600
        
    --修正时区
    local adjustTimeStamp = curTimestamp + OffsetSec
    return adjustTimeStamp
end

--根据UTC0时间戳计算出本地日期
---@return string 如2024年7月23日
function  TimeUtils.GetDateFromTimeStamp(TimeStamp)
    return os.date(G_ConfigHelper:GetStrFromCommonStaticST("Lua_StringUtil_Yyearmmonthdday"):ToString(),TimeStamp)
end

---获取传入时间戳的字符串
---@param TimeStamp number 时间戳 例如：1689242400
---@param FormatText string 填充字符串  不传默认为 %04d-%02d-%02d %02d:%02d:%02d
---@param UseUtc0 boolean 是否转化为UTC0时间 默认为false
---@return string 例如：yyyy-MM-dd HH:mm:ss
function TimeUtils.GetDateTimeStrFromTimeStamp(TimeStamp, FormatText, UseUtc0)
    -- 将时间戳转换为表格形式的日期和时间
    local DateTable = os.date("*t", TimeStamp)
    if UseUtc0 then
        DateTable = os.date("!*t", TimeStamp)
    end
    local CurFormatText = FormatText or "%04d-%02d-%02d %02d:%02d:%02d"
    local FormattedDate = string.format(CurFormatText,
    DateTable.year, DateTable.month, DateTable.day,
    DateTable.hour, DateTable.min, DateTable.sec)

    return FormattedDate
end
--endregion 时间戳本地化相关

--return TimeUtils