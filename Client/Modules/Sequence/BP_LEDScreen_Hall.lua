---@class BP_LEDScreen_Hall 大厅场景, 静态绑定 BP_LEDScreen_Hall 蓝图
local BP_LEDScreen_Hall = UnLua.Class()

-- function BP_LEDScreen_Hall:Construct()
--     CLog("BP_LEDScreen_Hall:Construct")
-- end

-- function BP_LEDScreen_Hall:Tick(MyGeometry, InDeltaTime)
-- end

-- function BP_LEDScreen_Hall:Destruct()
--     -- CLog("BP_LEDScreen_Hall:Destruct")
-- end

---重写蓝图函数 InitMeiaSound
-- function BP_LEDScreen_Hall:InitMeiaSound()
--     CError("BP_LEDScreen_Hall:InitMeiaSound")
-- end

-- ---重写蓝图函数 OnDestroyedEvent
-- function BP_LEDScreen_Hall:OnDestroyedEvent()
--     CError("BP_LEDScreen_Hall:OnDestroyedEvent")
-- end

---重写蓝图函数 OnBeginPlayEvent
function BP_LEDScreen_Hall:OnBeginPlayEvent()
    CLog("11111111111:BP_LEDScreen_Hall:OnBeginPlayEvent")
    MvcEntry:GetModel(HallModel):AddListener(HallModel.NTF_PLAY_SCREEN_MEDIA, self.NTF_PLAY_SCREEN_MEDIA_Func, self)
end

---重写蓝图函数 OnBeginPlayEvent
function BP_LEDScreen_Hall:OnEndPlayEvent()
    CLog("11111111111:BP_LEDScreen_Hall:OnEndPlayEvent")
    MvcEntry:GetModel(HallModel):RemoveListener(HallModel.NTF_PLAY_SCREEN_MEDIA, self.NTF_PLAY_SCREEN_MEDIA_Func, self)
end

function BP_LEDScreen_Hall:NTF_PLAY_SCREEN_MEDIA_Func()
    CLog("11111111111:BP_LEDScreen_Hall:NTF_PLAY_SCREEN_MEDIA_Func")
    if self.VXE_Play_MainHall_BigScreen then
        self:VXE_Play_MainHall_BigScreen()--这里调用蓝图函数    
    end
    
    if self.VXE_Play_MainHall_SmallScreen then
        self:VXE_Play_MainHall_SmallScreen()--这里调用蓝图函数    
    end
end



return BP_LEDScreen_Hall