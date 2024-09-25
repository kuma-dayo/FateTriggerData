--
-- Http
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.01.13
--

local HttpHelper = _G.HttpHelper or BaseClass(nil,"HttpHelper")

function HttpHelper:__init()
	print(">> HttpHelper:Init, ...")
end

function HttpHelper:__dispose()
	print(">> HttpHelper:Destroy, ...")
end

-- 
function HttpHelper:HttpGetByUE(InUrl, InCallable,Timeout)
	Timeout = Timeout or -2
	print(">> HttpHelper:HttpGetByUE, ", InUrl, InCallable,Timeout)
	
    local bReqSuccess = UE.UGFUnluaHelper.ReqHttp(InUrl,Timeout, function(bValidHttp, bRespSucc, InCode, InContent)
    	if (not bValidHttp) or (not bRespSucc) or (InCode ~= 200) then
    		GameLog.Error(">> HttpHelper:HttpGetByUE, Error!!! InUrl:", InUrl, bValidHttp, bRespSucc, InCode, InContent)
    		InContent = nil
    	end

		if InCallable then InCallable(InContent) end
	end)

	return bReqSuccess
end


return HttpHelper
