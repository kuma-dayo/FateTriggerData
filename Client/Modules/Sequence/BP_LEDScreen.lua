---@class BP_LEDScreen 商城场景 StreamLevel_Raffle, 静态绑定 BP_LEDScreen 蓝图
local BP_LEDScreen = UnLua.Class()

-- function BP_LEDScreen:Construct()
--     CLog("BP_LEDScreen:Construct")
-- end

-- function BP_LEDScreen:Tick(MyGeometry, InDeltaTime)
-- end

-- function BP_LEDScreen:Destruct()
--     -- CLog("BP_LEDScreen:Destruct")
-- end

---重写蓝图函数 InitMeiaSound
-- function BP_LEDScreen:InitMeiaSound()
--     CError("BP_LEDScreen:InitMeiaSound")
-- end

---重写蓝图函数 OnBeginPlayEvent
function BP_LEDScreen:OnBeginPlayEvent()
    CLog("BP_LEDScreen:OnBeginPlayEvent")

    MvcEntry:GetModel(ShopModel):AddListener(ShopModel.ON_HIDE_HALLTABSHOP, self.ON_HIDE_HALLTABSHOP_Func, self)
    MvcEntry:GetModel(ShopModel):AddListener(ShopModel.ON_SHOW_HALLTABSHOP, self.ON_SHOW_HALLTABSHOP_Func, self)
    MvcEntry:GetModel(ShopModel):AddListener(ShopModel.ON_CHANGLE_BP_LEDSCREEN, self.ON_CHANGLE_BP_LEDSCREEN_Func, self)
    

    -- self:InitMeiaSound()
    -- self:StartDebugPrintTimer()
end

---重写蓝图函数 OnBeginPlayEvent
function BP_LEDScreen:OnEndPlayEvent()
    CLog("BP_LEDScreen:OnEndPlayEvent")

    -- self:ClearDebugPrintTimer()

    MvcEntry:GetModel(ShopModel):RemoveListener(ShopModel.ON_HIDE_HALLTABSHOP, self.ON_HIDE_HALLTABSHOP_Func, self)
    MvcEntry:GetModel(ShopModel):RemoveListener(ShopModel.ON_SHOW_HALLTABSHOP, self.ON_SHOW_HALLTABSHOP_Func, self)
    MvcEntry:GetModel(ShopModel):RemoveListener(ShopModel.ON_CHANGLE_BP_LEDSCREEN, self.ON_CHANGLE_BP_LEDSCREEN_Func, self)
end

function BP_LEDScreen:ON_CHANGLE_BP_LEDSCREEN_Func(Param)
    Param = Param or {}
    local bShow = Param.bShow
    CLog(string.format("BP_LEDScreen:ON_CHANGLE_BP_LEDSCREEN_Func, bShow=[%s]", tostring(bShow)))
    if bShow then
        self:SetActorHiddenInGame(false)
    else
        self:SetActorHiddenInGame(true)
    end
end

function BP_LEDScreen:ON_SHOW_HALLTABSHOP_Func()
    CLog("BP_LEDScreen:ON_SHOW_HALLTABSHOP_Func, ")
    
    -- if self.ColseAllMedia then
    --     self:ColseAllMedia() --这里调用蓝图函数    
    -- end
end

function BP_LEDScreen:ON_HIDE_HALLTABSHOP_Func()
    CLog("BP_LEDScreen:ON_HIDE_HALLTABSHOP_Func, ")

    if self.ColseAllMedia then
        self:ColseAllMedia() --这里调用蓝图函数    
    end
end

function BP_LEDScreen:StartDebugPrintTimer()
    self:ClearDebugPrintTimer()
    self.DebugTimer = Timer.InsertTimer(1,function()
        local bIsPaused = self.MediaPlayer_1:IsPaused()
        local Rate = self.MediaPlayer_1:GetRate()

        local PlayListIdx = self.MediaPlayer_1:GetPlaylistIndex()
        local PlaySource = self.MediaPlayer_1:GetPlayList():Get(PlayListIdx)
        local PlayName = UE.UKismetSystemLibrary.GetObjectName(PlaySource)
        CLog(string.format("BP_LEDScreen:DebugPrintTimer, PlayName=[%s],bIsPaused=[%s],Rate=[%s]",tostring(PlayName),tostring(bIsPaused),tostring(Rate)))
    end,true)
end

function BP_LEDScreen:ClearDebugPrintTimer()
    if self.DebugTimer then
        Timer.RemoveTimer(self.DebugTimer)
    end
    self.DebugTimer = nil
end

return BP_LEDScreen