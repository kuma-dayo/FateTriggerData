local super = GameEventDispatcher;
local class_name = "HallModel";
---@class HallModel : GameEventDispatcher
HallModel = BaseClass(super, class_name);

HallModel.CAMERA_CONFIG_CONST = {
    PREVIEW = 1,
    SEASON = 2
}

HallModel.CAMERA_CONFIG = {
    [HallModel.CAMERA_CONFIG_CONST.PREVIEW] = {
        Charater = {
            SRCROLL = "PreviewSroll",
            MOVE = "PreviewMove"
        },
    },
    [HallModel.CAMERA_CONFIG_CONST.SEASON] = {
        Charater = {
            SRCROLL = "SeasonCharaterScroll",
            MOVE = "SeasonCharaterMove"
        },
        Weapon = {
            SRCROLL = "SeasonWeaponScroll",
            MOVE = "SeasonWeaponMove"
        }
    }
}


HallModel.HallVirtualType =
{
    PreEntering = "PreHallShowTag",
    Entering = "EnterHallShowTag",
    Hall = "HallShowTag",
    Match = "MatchShowTag",
}

--TEST
HallModel.ON_HALL_LS_CHANGE_TEST = "ON_HALL_LS_CHANGE_TEST"
--TEST


--大厅场景切换事件
HallModel.ON_HALL_SCENE_SWITCH = "ON_HALL_SCENE_SWITCH"
HallModel.ON_HALL_SCENE_SWITCH_COMPLETED = "ON_HALL_SCENE_SWITCH_COMPLETED"
HallModel.ON_STREAM_LEVEL_LOAD_COMPLELTED = "ON_STREAM_LEVEL_LOAD_COMPLELTED"
HallModel.ON_STREAM_LEVEL_UNLOAD_COMPLELTED = "ON_STREAM_LEVEL_UNLOAD_COMPLELTED"
HallModel.ON_LIGHT_LEVEL_LOAD_COMPLELTED = "ON_LIGHT_LEVEL_LOAD_COMPLELTED"
HallModel.ON_LIGHT_LEVEL_UNLOAD_COMPLELTED = "ON_LIGHT_LEVEL_UNLOAD_COMPLELTED"
HallModel.ON_STREAM_LEVEL_PRELOAD_COMPLELTED = "ON_STREAM_LEVEL_PRELOAD_COMPLELTED"
HallModel.ON_SPECIAL_POP_LINE_EVENT = "ON_SPECIAL_POP_LINE_EVENT"
--[[
    表示即将开始相机切换
    用于处理一些清理动作
    回调参数
    local Param = {
        CameraIndex = CameraIndex
    }    
]]
HallModel.ON_CAMERA_SWITCH_PRELOAD = "ON_CAMERA_SWITCH_PRELOAD"
--[[
    大厅相机切换成功
    回调参数
    Param = {
        SceneId = XX
    }
]]
HallModel.ON_CAMERA_SWITCH_SUC = "ON_CAMERA_SWITCH_SUC"

--[[
    触发摄相机切换
    Param
    {
        CameraID
    }
]]
HallModel.TRIGGER_CAMERA_SWITCH = "TRIGGER_CAMERA_SWITCH"

--[[
    相机Focus设置变更，参数为偏移值
    为空，表示focus设置为Manual
    为有值 ，且示为tracking 
]]
HallModel.ON_CAMERA_FOCUSSETTING_CHANGE = "ON_CAMERA_FOCUSSETTING_CHANGE"


HallModel.ON_HERO_PUTON_WEAPON = "ON_HERO_PUTON_WEAPON"
HallModel.ON_HERO_TAKEOFF_WEAPON = "ON_HERO_TAKEOFF_WEAPON"

--触发HallMdt的实现内容显示与否
HallModel.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE = "TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE"
--当IsHallReady会触发此事件更新
HallModel.ON_HALL_READY_UPDATE = "ON_HALL_READY_UPDATE"

--大厅场景加载完成
HallModel.HALL_SCENE_LOAD_FINISH = "HALL_SCENE_LOAD_FINISH"

--触发英雄主界面的背景板显示或者隐藏
HallModel.TRIGGER_BP_Hall_HeroBg_CharAndName_SHOWOROUT = "TRIGGER_BP_Hall_HeroBg_CharAndName_SHOWOROUT"


HallModel.ON_HERO_ADD_HEADSHOW = "ON_HERO_ADD_HEADSHOW"
HallModel.ON_HERO_REMOVE_HEADSHOW = "ON_HERO_REMOVE_HEADSHOW"

-- 通知外部：输入屏蔽层InputShieldLayer 通过输入事件关闭了自身
HallModel.ON_INPUT_SHIELD_LAYER_HIDE_AFTER_INPUT = "ON_INPUT_SHIELD_LAYER_HIDE_AFTER_INPUT"

-- 通知正在开始执行登录完成进入大厅的操作
HallModel.ON_START_ENTERING_HALL = "ON_START_ENTERING_HALL"

-- 设置组队聊天栏是否可见
HallModel.SET_TEAMANDCHAT_VISIBLE = "SET_TEAMANDCHAT_VISIBLE"

-- 通知大厅中MediaPlayer播放视频
HallModel.NTF_PLAY_SCREEN_MEDIA = "NTF_PLAY_SCREEN_MEDIA"

-- 大厅同步自己角色Avatar
HallModel.HALL_PLAY_SPAWN_SELF_AVATAR = "HALL_PLAY_SPAWN_SELF_AVATAR"

--流关卡类型
HallModel.LevelType = 
{
    STREAM_LEVEL = 1,
    LIGHT_LEVEL = 2,
}

--[[
    大厅公用LS的ID 枚举
    通过ID 可以从配置HallLSCfg里面获取到对应的LS路径
]]
HallModel.LSTypeIdEnum = {
    --进场LS
    LS_ENTER_HALL = 1001,
    --进队LS
    LS_ENTER_TEAM = 1002,
    --出队LS
    LS_EXIT_TEAM = 1003,
    --单人匹配LS
    LS_SOLO_MATCH_BEGIN = 1004,
    --单人取消匹配LS
    LS_SOLO_MATCH_CANCEL = 1005,
    --匹配成功LS
    LS_MATCH_SUC = 1006,
    --切换英雄主界面LS
    LS_HERO_MAIN = 1007,
    --匹配成功后开始DSTravel之前播的LS
    LS_MATCH_DSMETA_SUC = 1008,
    --角色溶解效果(进入时)
    LS_HERO_DISSOLVE = 1009,
    --角色闪点效果（Match）
    LS_HERO_BLACKWHITE_MATCH = 1010,
    --角色闪点效果（SoloSquard）
    LS_HERO_BLACKWHITE_SOLOSQUARD = 1011,
    --角色溶解效果(离开时)
    LS_HERO_EXIT_DISSOLVE = 1012,
    --大厅玩家组队及匹配状态下的相机位置
    LS_TEAMORMATCH_CAMERA = 1013,
    --从战斗返回进场大厅时的相机位置
    LS_ENTER_HALL_FROMBATTLE = 1014,

    --消融效果
    LS_WEAPON_DISSOLVE = 2000,
    LS_WEAPON_DISSOLVE_OUT = 2001,
    --英雄分页英雄板LS较正相机
    LS_HEROMAIN_TAB_DISPLAYBOARD = 3001,
  
    -- 好感度主界面相机LS
    LS_CAM_FAVOR_OFFSET = 4000,
    LS_CAM_FAVOR_RESET = 4001,

    -- LS_FAVORMAIN_TO_HERO_CAMERA = 4001,
    -- LS_FAVORMAIN_TO_HALL_CAMERA = 4002,

    --战备大厅
    LS_ARSENAL_HALL = 5000,
    LS_ARSENAL_HALL_FOCUS_CAR = 5001,
    LS_ARSENAL_HALL_FOCUS_CHAR = 5002,
    LS_ARSENAL_HALL_FOCUS_WEAPONPART = 5003,
    --赛季通行证
    LS_SEASON_PASS_BACKGROUND = 5004,
}

function HallModel:OnLogout(Param)
    self:LogicDataInit()
end

function HallModel:__init()
    self:_dataInit()
    self:LogicDataInit()
end

function HallModel:_dataInit()
    --当前加载的场景ID
    self.CurSceneID = 0
    --当前灯光流关卡
    self.CurActiveLightLevelID = 0
    --当前摄像机
    self.CurCameraIndex = 0
    --当前正在加载的流关卡
    self.CurLinkage = 0    
    --当前摄像机ID对应的配置信息（支撑运行时修改）
    self.CameraId2CameraConfig = {}
    --依赖HallSceneMgrInst的一些行为缓存
    self.HallSceneMgrActionCache = {}
    self.CurHallVirtualType = HallModel.HallVirtualType.PreEntering
    --大厅页签值
    self.CurHallTabType = CommonConst.HL_PLAY
    --上次角色休闲或点击反馈的LS播放次数
    self.LastPlayIdleID = 0
    self.LastPlayIdleTimes = 0

    --是否在进入局内
    self._IsLevelTravel = false
end

--@@
function HallModel:ReInit()
     self.CurSceneID = 0
     self.CurActiveLightLevelID = 0
     self.CurCameraIndex = 0
     self.CurLinkage = 0    
end

function HallModel:LogicDataInit()
    self.LSEvent2CD = {}

    --[[
        用于标记大厅展示是否准备好
        (需要注意的是，在从登录界面到大厅，需要播放完LS，才会将这个字段置为true)
    ]]
    self.IsHallReady = false
end

function HallModel:IsLevelTravel()
    return self._IsLevelTravel
end

function HallModel:SetIsLevelTravel(Value)
    self._IsLevelTravel = Value
end

--@@Scene
function HallModel:GetSceneID()
    return self.CurSceneID
end

function HallModel:SetSceneID(SceneID)
    self.CurSceneID = SceneID
end

function HallModel:SetIsHallReady(IsHallReady)
    self.IsHallReady = IsHallReady
    self:DispatchType(HallModel.ON_HALL_READY_UPDATE)
end
function HallModel:GetIsHallReady(IsHallReady)
    return self.IsHallReady
end



function HallModel:GetSceneStreamLevel(SceneID)
    local HallSceneCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HallSceneConfig,Cfg_HallSceneConfig_P.SceneID,SceneID)
	if HallSceneCfg == nil then
		return
	end

   return self:GetStreamLevel(HallSceneCfg.StreamLevelID)
end


function HallModel:GetSceneLightLevel(SceneID)
    local HallSceneCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HallSceneConfig,Cfg_HallSceneConfig_P.SceneID,SceneID)
	if HallSceneCfg == nil then
		return 
	end

    return self:GetLightLevel(HallSceneCfg.LightStreamID)
end

function HallModel:GetSceneCameraID(SceneID)
    local HallSceneCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HallSceneConfig,Cfg_HallSceneConfig_P.SceneID,SceneID)
	if HallSceneCfg == nil then
		return 0
	end
    return HallSceneCfg.CameraID
end


function HallModel:GetSceneEffectPosition(SceneID)
    local HSCfg = G_ConfigHelper:GetSingleItemById(Cfg_HallSceneConfig, SceneID)
	if HSCfg == nil then
		return
	end

    local StrBGEffectLocation = HSCfg[Cfg_HallSceneConfig_P.BGEffectLocation]
    if not StrBGEffectLocation or StrBGEffectLocation == "" then
        return 
    end
    local Pattern = "X=([%d%.%-]+),Y=([%d%.%-]+),Z=([%d%.%-]+)"
    local X, Y, Z = string.match(StrBGEffectLocation, Pattern)
    if X and Y and Z then
        return UE.FVector(X, Y, Z)
    end
end

function HallModel:GetStreamLevel(StreaLevelID)
    local HallStreamLevelCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HallStreamLevelConfig,Cfg_HallStreamLevelConfig_P.StreamLevelID,StreaLevelID)
	if HallStreamLevelCfg == nil then
		return "", nil
	end
    return StreaLevelID, HallStreamLevelCfg.StreamLevelName
end


function HallModel:GetLightLevel(LightLevelID)
    local HallLightCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HallLightConfig,Cfg_HallLightConfig_P.LightID,LightLevelID)
	if HallLightCfg == nil then
		return 
	end
    return LightLevelID, HallLightCfg.LightLevelName
end

--[[
    获取 触发闲置计时器的时长 间隔
]]
function HallModel:GetHallIdleAnimGapTime()
    local GapTimeTbl = G_ConfigHelper:GetSingleItemByKey(Cfg_ParameterConfig,Cfg_ParameterConfig_P.ParameterId,ParameterConfig.HallIdleAnimGapTime.ParameterId)
    local GapTime = GapTimeTbl and GapTimeTbl[Cfg_ParameterConfig_P.ParameterValue] or 15
    print("GapTime:" .. GapTime)
    return GapTime
end



--@@Light
function HallModel:SetCurActiveLightLevelID(ActiveLightLevelID)
    self.CurActiveLightLevelID = ActiveLightLevelID
end


function HallModel:GetCurActiveLightLevelID()
    return self.CurActiveLightLevelID
end

--@@Camera
function HallModel:GetCameraConfig(CameraIndex)
    if not CameraIndex then
        return
    end
    if not self.CameraId2CameraConfig[CameraIndex] then
        local HallCameraCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HallCameraConfig,Cfg_HallCameraConfig_P.CameraID,CameraIndex)
        self.CameraId2CameraConfig[CameraIndex] = HallCameraCfg
        -- CWaring("" .. HallCameraCfg[Cfg_HallCameraConfig_P.CameraLocation])
    end

    return self.CameraId2CameraConfig[CameraIndex]
end

function HallModel:SaveNowCameraConfig(CameraIndex)
    CameraIndex = CameraIndex or self.CurCameraIndex
    local CameraActor = UE.UGameHelper.GetCurrentSceneCamera()
    if CameraActor ~= nil then
        local Rotation = CameraActor:K2_GetActorRotation()
        local Location = CameraActor:K2_GetActorLocation()
        local Scale = CameraActor:GetActorScale3D()

        local Config = self:GetCameraConfig(CameraIndex)
        if not Config then
            CError("HallModel:SaveNowCameraConfig Config nil",true)
            return
        end
        Config[Cfg_HallCameraConfig_P.CameraLocation] = StringUtil.FormatSimple("{0},{1},{2}",Location.X,Location.Y,Location.Z)
        Config[Cfg_HallCameraConfig_P.CameraRotation] = StringUtil.FormatSimple("{0},{1},{2}",Rotation.Pitch,Rotation.Yaw,Rotation.Roll)
        Config[Cfg_HallCameraConfig_P.CameraScale] = StringUtil.FormatSimple("{0},{1},{2}",Scale.X,Scale.Y,Scale.Z)
        if CameraActor and CameraActor:GetCineCameraComponent() then
            local CineCameraComponent = CameraActor:GetCineCameraComponent()
            Config[Cfg_HallCameraConfig_P.CurrentFocalLength] = CineCameraComponent.CurrentFocalLength
            Config[Cfg_HallCameraConfig_P.CurrentAperture] = CineCameraComponent.CurrentAperture
        end
        CWaring("SaveNowCameraConfig CameraLocation:" .. CameraIndex)
        -- CWaring("SaveNowCameraConfig CameraLocation:" .. Config[Cfg_HallCameraConfig_P.CameraLocation])
        -- CWaring("SaveNowCameraConfig CameraRotation:" .. Config[Cfg_HallCameraConfig_P.CameraRotation])
        -- CWaring("SaveNowCameraConfig CurrentFocalLength:" .. Config[Cfg_HallCameraConfig_P.CurrentFocalLength])
        -- CWaring("SaveNowCameraConfig CurrentAperture:" .. Config[Cfg_HallCameraConfig_P.CurrentAperture])
    end
end

function HallModel:SetCurCameraIndex(CameraIndex)
    self.CurCameraIndex = CameraIndex
end

function HallModel:ParseLinkageInfo(Linkage)
    local LevelType = math.fmod(Linkage, 10)
    local IsLoading = math.fmod(math.modf(Linkage, 10) ,10)
    local LevelID = math.floor(Linkage/100);
    return LevelID, LevelType, IsLoading
end

--@@Event
function HallModel:GetCurLinkageInfo()
    return self:ParseLinkageInfo(self.CurLinkage)
end


function HallModel:OnLoadStreamLevelComplete(Linkage)
    self.CurLinkage = Linkage
    print("self.CurLinkage:" .. self.CurLinkage)

    local _, LevelType, _ = self:GetCurLinkageInfo()
    if LevelType == HallModel.LevelType.STREAM_LEVEL then
        self:DispatchType(HallModel.ON_STREAM_LEVEL_LOAD_COMPLELTED)
    elseif LevelType == HallModel.LevelType.LIGHT_LEVEL then
        self:DispatchType(HallModel.ON_LIGHT_LEVEL_LOAD_COMPLELTED)
    end
end

function HallModel:OnUnLoadStreamLevelComplete(Linkage)
    -- self.Linkage = Linkage

    local _, LevelType, _ = self:GetCurLinkageInfo()
    if LevelType == HallModel.LevelType.STREAM_LEVEL then
        self:DispatchType(HallModel.ON_STREAM_LEVEL_UNLOAD_COMPLELTED)
    elseif LevelType == HallModel.LevelType.LIGHT_LEVEL then
        self:DispatchType(HallModel.ON_LIGHT_LEVEL_UNLOAD_COMPLELTED)
    end
end

--[[
    执行依赖HallSceneMgrInst的动作
    会检测HallSceneMgrInst是否可用，如果是则立即执行
    如果不是，则会进行Cache，待HallSceneMgrInst初始化完成会进行调用
]]
function HallModel:DoHallSceneMgrAction(Action)
    if _G.HallSceneMgrInst then
        Action();
    else
        table.insert(self.HallSceneMgrActionCache,Action)
    end
end

--[[
    在框架初始化完成时进行调用
    对Cache的行为进行调用
]]
function HallModel:CheckHallSceneMgrActionCache()
    for k, v in pairs(self.HallSceneMgrActionCache) do
        v()
    end
    self.HallSceneMgrActionCache = {}
end

--[[
    获取LS路径
]]
function HallModel:GetLSPathById(Id)
    local LSPath = nil
    local CfgHallLS =  G_ConfigHelper:GetSingleItemById(Cfg_HallLSCfg,Id)
    if CfgHallLS then
        LSPath =  CfgHallLS[Cfg_HallLSCfg_P.LSPath]
        if LSPath and string.len(LSPath) <= 0 then
            LSPath = nil
        end
    end
    return LSPath
end

--[[
    刷新LSEvent事件的CD时间缀
    CD 为秒
]]
function HallModel:RefreshLSEventCD(EventName,CD)
    self.LSEvent2CD[EventName] = GetTimestampMilliseconds() + CD*1000;
end

--[[
    判断当前LSEvent事件是否在CD中
]]
function HallModel:IsLSEventInCD(EventName)
    local CTime = GetTimestampMilliseconds();
    local CDTime = self.LSEvent2CD[EventName] or 0
    return (CDTime > CTime)
end

function HallModel:UpdateVirtualSceneType()
    for _, Tag in pairs(HallModel.HallVirtualType) do
        local Show = self.CurHallVirtualType == Tag
        local Actors = UE.UGameplayStatics.GetAllActorsWithTag(GameInstance, Tag)
        for _, TActor in pairs(Actors) do
            TActor:SetActorHiddenInGame(not Show)
        end
    end
end

function HallModel:SetCurVirtualSceneType(Type)
    print("HallModel:SetCurVirtualSceneType", self.CurHallVirtualType, Type)
    if self.CurHallVirtualType == Type then
        return
    end
    self.CurHallVirtualType = Type
    self:UpdateVirtualSceneType()
end


function HallModel:SetCurHallTabType(type)
    self.CurHallTabType = type
end

function HallModel:GetCurHallTabType(type)
    return self.CurHallTabType
end

function HallModel:SetCurrentPlayLS(Id)
    if self.LastPlayIdleID ~= Id then
        self.LastPlayIdleTimes = 0
    end
    self.LastPlayIdleTimes = self.LastPlayIdleTimes + 1
    self.LastPlayIdleID = Id
    print("HallModel:SetCurrentPlayLS",self.LastPlayIdleID , self.LastPlayIdleTimes)
end

function HallModel:IsLastPlayLSOverTimes()
    if not self.LastPlayIdleID then
        return
    end
    local LSItem = G_ConfigHelper:GetSingleItemById(Cfg_HeroEventLSCfg, self.LastPlayIdleID)
    if not LSItem then
        CWaring("HallModel:IsLastPlayLSOverTimes LSItem is nil"..self.LastPlayIdleID)
        return false
    end
    local MinTimes = LSItem[Cfg_HeroEventLSCfg_P.MinTimes] or 0

    print("HallModel:IsLastPlayLSOverTimes",self.LastPlayIdleID , MinTimes, self.LastPlayIdleTimes)
    if MinTimes > 0 and self.LastPlayIdleTimes >= MinTimes then
        return true
    end
    return false
end

return HallModel

