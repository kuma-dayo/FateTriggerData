--[[
    HttpRequestJobLogic 一个Http请求

    1.会有超时逻辑，超时后仍然会执行回调，但是返回空值
    2.会有请求异常处理，异常仍然会执行回调，但是返回空值
]] 
local class_name = "HttpRequestJobLogic"
HttpRequestJobLogic = BaseClass(nil, class_name)


--[[
    @param Url 连接URL
    @param Timeout 超时时间
    @param CallBackFunc 执行回调
    @param TryTimes 尝试次数（当URL请求失败时，会尝试X次）
]]
function HttpRequestJobLogic:__init(Url,Timeout, CallBackFunc,TryTimes)
    self.IsWorking = false
    self:ReqAction(Url,Timeout, CallBackFunc,TryTimes)
end

function HttpRequestJobLogic:ReqAction(Url,Timeout, CallBackFunc,TryTimes)
    if self.IsWorking then
        CError("HttpRequestJobLogic Already IsWorking")
        return
    end
    self.Url = Url
    self.CallBackFunc =  CallBackFunc
    self.Timeout =  Timeout
    self.TryTimesMax = TryTimes or 3
    self.TryTimes = 0
    self.IsWorking = true
    self:_DoHttpReqInner()
end

function HttpRequestJobLogic:_DoHttpReqInner()
    if not self.IsWorking then
        return
    end
    if self.TryTimes >= self.TryTimesMax then
        CWaring("HttpRequestJobLogic:_DoHttpReqInner TryTimesMax")
        self:OnReqSucCallback(nil)
        return
    end
    self.TryTimes = self.TryTimes + 1
    local bReqSuccess = HttpHelper:HttpGetByUE(self.Url, function(InContent)
        if not InContent then
            self:_DoHttpReqInner()
        else
		    self:OnReqSucCallback(InContent)
        end
	end,self.Timeout)
    if not bReqSuccess then
        self:_DoHttpReqInner()
    end
end

function HttpRequestJobLogic:Close()
    self.IsWorking = false
end

function HttpRequestJobLogic:OnReqSucCallback(InContent)
    if not self.IsWorking then
        return
    end
    self.IsWorking = false
    self.CallBackFunc(InContent)
end


return HttpRequestJobLogic
