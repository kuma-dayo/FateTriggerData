--[[
    {KeyName}可以参考EKeys的文档：
    https://docs.unrealengine.com/4.26/en-US/API/Runtime/InputCore/EKeys/
    
    或者源码：
    \Engine\Source\Runtime\InputCore\Classes\InputCoreTypes.h
]]
--[[
    按键映射（由InputModel管理派发，受UI层级影响）
]]
ConstUtil = {}

ActionMappings = {
    Escape = "Escape",
    Tab = "Tab",
    SpaceBar = "SpaceBar",
    SpaceBarHold = "SpaceBarHold",
    Enter = "Enter",
    LShift = "LShift",
    LAlt = "LAlt",

    --字母按键
    E = "E",
    Q = "Q",
    A = "A",
    S = "S",
    D = "D",
    W = "W",
    F = "F",
    R = "R",
    H = "H",
    I = "I",
    L = "L",
    K = "K",
    V = "V",
    X = "X",
    C = "C",
    Z = "Z",

    --方向按键
    Up = "Up",
    Down = "Down",
    Left = "Left",
    Right = "Right",
    --鼠标按键
    LeftMouseButton = "LeftMouseButton",
    RightMouseButton = "RightMouseButton",
    MiddleMouseButton = "MiddleMouseButton",
    --鼠标滚轮
    MouseScrollUp = "MouseScrollUp",
    MouseScrollDown = "MouseScrollDown",
    --鼠标右键点击
    RightMousePress = "RightMousePress",
    --鼠标右键释放
    RightMouseRelease = "RightMouseRelease",
    --鼠标左键单击
    LeftMouseButtonTap = "LeftMouseButtonTap",
    --鼠标左键双击
    LeftMouseButtonDouble = "LeftMouseButtonDouble",
    --鼠标左键长按-只触发一次
    LeftMouseButtonHold = "LeftMouseButtonHold",
    --鼠标右键键单击
    RightMouseButtonTap = "RightMouseButtonTap",

    -- 手柄
    -- 手柄左肩键
    Gamepad_LeftShoulder = "Gamepad_LeftShoulder",
    -- 手柄右肩键
    Gamepad_RightShoulder = "Gamepad_RightShoulder",
}

--[[
    轴映射
]]
AxisMappings = {
    MoveForward = "MoveForward",
    MoveRight = "MoveRight",
    TurnRate = "TurnRate",
    Pinch = "Pinch",
    -- 暂没配置Action，按需添加
    -- Turn = "Turn",
    -- LookUp = "LookUp",
    -- LookUpRate = "LookUpRate",
}

--[[
    全局按键映射（不受UI层级影响）
    由GlobalInputModel派发，与UI无关，全局会收到输入
]]
GlobalActionMappings = {
    V_Down = "V_Down",

    --左方括号
    BracketLeft = "BracketLeft",
    --右方括号
    BracketRight = "BracketRight",
    --打开GM界面
    P = "P",
}

--[[
    EnhanceInput Triggered GMP事件名
    -- 对应的是对应IAE中配置的GMP Tag
]]
function EnhanceInputActionTriggered_GMPEvent(actionName)
    return StringUtil.Format("EnhancedInput.CommonUI.{0}_Triggered",actionName)
end

--[[
    EnhanceInput Completed GMP事件名
    -- 对应的是对应IAE中配置的GMP Tag
]]
function EnhanceInputActionCompleted_GMPEvent(actionName)
    return StringUtil.Format("EnhancedInput.CommonUI.{0}_Completed",actionName)
end

--[[
    按下事件名(兼容旧接口)
]]
function ActionPressed_Event(actionName)
    return EnhanceInputActionTriggered_Event(actionName)
end
--[[
    松下事件名(兼容旧接口)
]]
function ActionReleased_Event(actionName)
    return EnhanceInputActionCompleted_Event(actionName)
end

--[[
    EnhanceInput Triggered事件名
]]
function EnhanceInputActionTriggered_Event(actionName)
    return actionName .. "_Triggered"
end

--[[
    EnhanceInput Completed事件名
]]
function EnhanceInputActionCompleted_Event(actionName)
    return actionName .. "_Completed"
end

WorldTypeEnum = {
    None = 0,
    Game = 1,
    Editor = 2,
    PIE = 3,
    EditorPreview = 4,
    GamePreview = 5,
    GameRPC = 6,
    Inactive = 7,
}

--[[
    计时器类型
]]
TimerTypeEnum = {
    --[[
        基于UObject Tick进行计时器封装
    ]]
    Timer = 1,
    CoroutineTimer = 2,
    --[[
        基于UE TimerManager实现的计时器封装
    ]]
    TimerDelegate = 3,
}


--[[
    车牌材质索引的参数
]]
PlateMaterialParamMapping = 
{
    --A-Z
    ["A"] = 0,
    ["B"] = 1,
    ["C"] = 2,
    ["D"] = 3,
    ["E"] = 4,
    ["F"] = 5,
    ["G"] = 6,
    ["H"] = 7,
    ["I"] = 8,
    ["J"] = 9,
    ["K"] = 10,
    ["L"] = 11,
    ["M"] = 12,
    ["N"] = 13,
    ["O"] = 14,
    ["P"] = 15,
    ["Q"] = 16,
    ["R"] = 17,
    ["S"] = 18,
    ["T"] = 19,
    ["U"] = 20,
    ["V"] = 21,
    ["W"] = 22,
    ["X"] = 23,
    ["Y"] = 24,
    ["Z"] = 25,

    --0-9
    ["1"] = 26,
    ["2"] = 27,
    ["3"] = 28,
    ["4"] = 29,
    ["5"] = 30,
    ["6"] = 31,
    ["7"] = 32,
    ["8"] = 33,
    ["9"] = 34,
    ["0"] = 35
}

--GMP事件定义
ConstUtil.MsgCpp = {
    --客户端从战斗返回大厅成功后的GMP通知
    GAMESTAGE_BATTLE_TO_HALL_END = "GameStage.Battle2Hall.End",
    
    --触发展示Loading
    ASYNCLOADINGSCREEN_SHOW = "AsyncLoadingScreen_StartLoadingScreen",
    --触发关闭Loading
    ASYNCLOADINGSCREEN_HIDE = "AsyncLoadingScreen_StopLoadingScreen",

    --Loading开始显示通知
    ASYNCLOADINGSCREEN_START = "AsyncLoadingScreen_LoadingStarted",
    --Loading开始关闭通知
    ASYNCLOADINGSCREEN_END = "AsyncLoadingScreen_LoadingFinished",
}

--退出战斗原因，描述
ConstUtil.ExitBattleReson = {
    --正常退出对局
    Normal = "Normal",
    --因为DS网络原因退出
    NetworkFailure = "NetworkFailure",
    --因为travelDS失败原因退出
    TravelFailure = "TravelFailure",
    --因为连接DS失败原因退出
    NetSocketError = "NetSocketError",
}