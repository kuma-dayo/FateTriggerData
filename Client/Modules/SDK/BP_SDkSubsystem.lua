--[[
    SDK中间件管理子系统
]]
local BP_SDkSubsystem = Class()


--[[
    初始化
]]
function BP_SDkSubsystem:OnInitialize()
    self.Overridden.OnInitialize(self)
    CWaring("BP_SDkSubsystem:OnInitialize()")
    --SDK初始化可能涉及到U对象创建，将一些SDK初始化行为放置OnGameInstanceStart之后
    
    CommonUtil.DoMvcEntyAction(function ()
        --子系统初始化 会驱动当前子系统的SDK进行初始化
        MvcEntry:GetCtrl(OnlineSubCtrl):Init(self)
    end)
end
--[[
    反初始化
]]
function BP_SDkSubsystem:OnDeinitialize()
    self.Overridden.OnDeinitialize(self)
    CWaring("BP_SDkSubsystem:OnDeinitialize()")
    if MvcEntry then
        --TODO 是世界卸载时，将对应SDK进行 UnInit/Stop 此行为也可制作到C++
        MvcEntry:GetCtrl(AppsflyerSteamCtrl):Stop()
    end
end
--[[
    游戏Gameinstance Start
]]
function BP_SDkSubsystem:ReceiveOnGameInstanceStart()
    self.Overridden.ReceiveOnGameInstanceStart(self)
    CWaring("BP_SDkSubsystem:ReceiveOnGameInstanceStart()")


    --TODO 初始化数数SDK
    if not CommonUtil.IsDedicatedServer() then
        --客户端
        local IsOverSea = self:GetIsOversea()   
        MvcEntry:GetCtrl(TDAnalyticsCtrl):Init()
        MvcEntry:GetCtrl(ACESDKCtrl):Init()
        MvcEntry:GetCtrl(PerfSightSDKCtrl):Init(IsOverSea)
        MvcEntry:GetCtrl(BianQueCtrl):Init(IsOverSea)
        MvcEntry:GetCtrl(GVoiceCtrl):InitEngine(IsOverSea)
    end
end


return BP_SDkSubsystem