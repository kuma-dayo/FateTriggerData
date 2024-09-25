--
-- 数据/代理相关
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.01.17
--

local ProxyBase = classmul("ProxyBase", ObjectBase)

function ProxyBase:ctor(...)
	ObjectBase.ctor(self, ...)
end

------------------------------------------- Static ----------------------------------------

-- 注册/注销
function ProxyBase.Register(InProxyCls)
	print("ProxyBase", ">> Register, ... ", InProxyCls:GetName())
	return G_ModelManager:RegisterProxy(InProxyCls)
end
function ProxyBase.Unregister(InProxyCls)
	print("ProxyBase", ">> Unregister, ... ", InProxyCls:GetName())
	return G_ModelManager:UnregisterProxy(InProxyCls)
end

function ProxyBase.Get(InProxyCls)
	return G_ModelManager:GetProxy(InProxyCls)
end

return ProxyBase
