--
-- Model Manager
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.01.17
--

---@class ModelManager
local ModelManager = classmul("ModelManager", ObjectBase)

function ModelManager:ctor(...)
	print("ModelManager", ">> ctor, ...")

	ObjectBase.ctor(self, ...)
	
	self.ProxyMap = {}
end

function ModelManager:RegisterProxy(InProxyCls)
	if not InProxyCls then
		Error(self:GetName(), ">> RegisterProxy, InProxyCls is invalid!!!")
		return
	end

	local ProxyName = InProxyCls:GetName()
	local NewProxyInst = InProxyCls.New()
	self.ProxyMap[ProxyName] = NewProxyInst

	NewProxyInst:Init()
	return NewProxyInst
end

function ModelManager:UnregisterProxy(InProxyCls)
	if not InProxyCls then
		Error(self:GetName(), ">> UnregisterProxy, InProxyCls is invalid!!!")
		return
	end

	local CurProxy = self:GetProxy(InProxyCls)
	if CurProxy then
		self.ProxyMap[CurProxy:GetName()] = nil
		CurProxy:Destroy()
	end

	return CurProxy
end

function ModelManager:GetProxy(InProxyCls)
	return self.ProxyMap[InProxyCls:GetName()]
end

function ModelManager:HasProxy(InProxyCls)
	return nil ~= self.ProxyMap[InProxyCls:GetName()]
end

return ModelManager
