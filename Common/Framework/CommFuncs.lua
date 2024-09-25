--
-- CommFuncs
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2021.12.13
--

require("Common.Framework.GameLog")

local CommFuncs = {
}

-------------------------------------------- Debug ------------------------------------


-------------------------------------------- Function ------------------------------------

-- 获取UObject
function GetObjectName(InObject)
	return InObject and UE.UKismetSystemLibrary.GetObjectName(InObject)  or "None"
end

-- 通用获取对象名字
function ToObjName(InObj)
	if (not InObj) then return "None" end

	if ('userdata' == type(InObj.Object)) then
		return GetObjectName(InObj)
	end
	return getClassName(InObj) or "None"
end

-- 获取UObject
function GetPathName(InObject)
	return InObject and UE.UKismetSystemLibrary.GetPathName(InObject)  or "None"
end

-- 设置表元方法__index和__newindex
function SetErrorIndex(t, InOverrideGetIndex, InOverrideSetIndex)
	local BaseMT = {
        __index = function(t, k)
            if InOverrideGetIndex then
                return InOverrideGetIndex()
            end
            Error("Comm", ">> Attempt to getter not exist key!", tostring(k), "\n".. debug.traceback())
        end,
        __newindex = function(t, k, v)
            if InOverrideSetIndex then
                return InOverrideSetIndex(k, v)
            end
            Error("Comm", ">> Attempt to modify not exist key!", tostring(k), "\n".. debug.traceback())
        end,
    }
    
    if type(t) == "table" then
        setmetatable(t, BaseMT)
    end
	for k, v in pairs(t) do
		if type(v) == "table" then
			setmetatable(v, BaseMT)
		end
	end

	BaseMT.__metatable = false
end

--[[
    调用pcall执行方法
    1.避免报错中断
    2.也能正常打印报错，并且上报
]]
function EnsureCall(ErrorTypeStr,f, arg1, ...)
    ErrorTypeStr = ErrorTypeStr or ""
    local res, info = xpcall(f, debug.traceback, arg1, ...)
    if res == false then 
        local WarnInfo = ErrorTypeStr .. info
        UE.UGFUnluaHelper.ReportError(WarnInfo)
    end
    return res, info
end


-- --[[
--    调用通用的埋点上报接口
--     1. 如果是DS：需要通过DSMgr后台转发
--         转发的路径：1）后台转发到埋点到业授
--                    2）后台转发到指标平台
--     2. 如果是客户端：
--         1) 客户端可以直接上报埋点到业授
--         2）上报指标，同样需要转发到后台【不建议，暂时不提供】

--         MsgParam:
--         {
--             EventName： https://data.bytedance.net/byteio/event/schema?subAppId=463739预定义的事件名, 埋点上报不能为空
--             EventConent: 上报的内容，Lua表
--         }
-- ]]
-- function ReportCall(IsBuryPoint, MsgParam)
--     if MsgParam == nil then
--         return
--     end
--     if not MsgParam.EventName or MsgParam.EventName == "" then
--         CWaring("ReportCall: EventName Not Found")
--         return
--     end
--     if CommonUtil.IsDedicatedServer() then
--         if IsBuryPoint then
--             local MsgBody =
--             {
--                 GameId = MsgParam.GameId,
--                 PlayerId = MsgParam.PlayerId,
--                 EventName = MsgParam.EventName,
--                 JsonContext = JSON:encode(MsgParam.EventConent)
--             }
--             print_r(MsgBody)
--             MvcEntry:SendProto(DSPb_Message.DsBuryingPointSync, MsgBody)
--         else
--             local MsgBody =
--             {
--                 GameId = MsgParam.GameId,
--                 EventName = MsgParam.EventName,
--                 JsonContext = JSON:encode(MsgParam.EventConent)
--             }
--             print_r(MsgBody)
--             MvcEntry:SendProto(DSPb_Message.DsMetricsReport, MsgBody)
--         end
--     else
--         if IsBuryPoint then
-- 			-- todo 后续替换为其他
--             -- UE.UGSDKHelper.ReportTrackEvent(MsgParam.EventName, JSON:encode(MsgParam.EventConent))
--         else
--             CWaring("ReportCall: Report Ignore")
--         end
--     end
-- end

--[[
    主动上报错误信息
    NeedTraceback 是否上报堆栈 默认为false
]]
function ReportError(ErrorInfo,NeedTraceback)
    ErrorInfo = ErrorInfo or ""
    if NeedTraceback then
        ErrorInfo = ErrorInfo..'\n'..debug.traceback()
    end
    CWaring(ErrorInfo)
    UE.UGFUnluaHelper.ReportError(ErrorInfo)
end


-------------------------------------------- Exec ------------------------------------

_G.CommFuncs = CommFuncs
return CommFuncs