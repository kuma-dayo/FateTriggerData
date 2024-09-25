require("Core.BaseClass");
require("Core.Events.EventDispatcher");

UnrealSocketMgr = UnrealSocketMgr or BaseClass(EventDispatcher, "UnrealSocketMgr");


function UnrealSocketMgr:__init()
	CLog("")
	self.TryWaitTimes = 0
end

-- 由C++层触发调用
function UnrealSocketMgr.OnUnrealNetworkFailed(FailureType, FailureReason)
	if FailureType == "" then 
		MvcEntry:GetModel(UnrealSocketMgr):OnFailed(FailureReason)
	else 
		MvcEntry:GetModel(UnrealSocketMgr):OnFailedWithFailureType(FailureType, FailureReason)
	end
end

-- 由C++层触发调用
function UnrealSocketMgr.OnUnrealNetworkSuccess(Reason)
	CLog("OnUnrealNetworkSuccess: Reason" .. Reason)
	MvcEntry:GetModel(UnrealSocketMgr):OnSuccess(Reason)
end


--------------------------------------------------------------------
function UnrealSocketMgr:OnSuccess(Reason)
	self:SetTryWaitTimes(0)
end

function UnrealSocketMgr:OnFailed(FailureReason)
	CLog("FailureReason == "..FailureReason)
	if FailureReason == "LongTimeNoReceived" and self:GetTryWaitTimes() < 3 then
		self:IncreaseTryWaitTimes()
		self:ShowWaitingMessageBox()
		return
	end

	local IsNeedReLogin = true 
	if FailureReason == "Closed" then
	elseif FailureReason == "ChannelActorError" then
	elseif FailureReason == "ConnectingDSTimeOut" then
	end
	self:ShowReturnHallMessageBox(IsNeedReLogin)
end

function UnrealSocketMgr:OnFailedWithFailureType(FailureType, FailureReason)
	CLog("OnFailedWithFailureType: FailureType="..FailureType.. " FailureReason="..FailureReason)
	local IsNeedReLogin = false 
	if FailureType == "FailureReceived" or 
		FailureReceived == "PendingConnectionFailure" then 
	elseif FailureType == "ConnectionTimeout" then
		IsNeedReLogin = true 
	elseif FailureType == "ConnectionLost" then
		IsNeedReLogin = true
	end
	self:ShowReturnHallMessageBox(IsNeedReLogin)
end

function UnrealSocketMgr:SetTryWaitTimes(TryTimes)
	self.TryWaitTimes = TryTimes
end

function UnrealSocketMgr:GetTryWaitTimes()
	return self.TryWaitTimes
end

function UnrealSocketMgr:IncreaseTryWaitTimes()
	self.TryWaitTimes = self.TryWaitTimes + 1
end

function UnrealSocketMgr:ShowWaitingMessageBox()
	--后续重新制作，暂时屏蔽
	-- MvcEntry:GetCtrl(CommonCtrl):PopGamePlayNetErrorTip(1)
end

function UnrealSocketMgr:ShowReturnHallMessageBox(IsNeedReLogin)
	IsNeedReLogin = IsNeedReLogin or false
	--后续重新制作，暂时屏蔽
	-- MvcEntry:GetCtrl(CommonCtrl):PopGamePlayNetErrorTip(2,IsNeedReLogin)
end



return UnrealSocketMgr;