require "UnLua"

---@class DSServerHub
local DSServerHub = Class()

--DSServerHub 改成依赖 ServerNetwork 模块的 StartupModule 创建，此时可能 S1DSMain 还未初始化，CLog 会报错
function DSServerHub:Initialize()
	--CLog("DSServerHub:Initialize")
end

function DSServerHub:OnInit()
	self.Overridden.OnInit(self)
end

function DSServerHub:OnTick(DeltaTime)
	Timer.Tick(DeltaTime)
	self.Overridden.OnTick(self, DeltaTime)
end

function DSServerHub:OnShutdown()
end


return DSServerHub