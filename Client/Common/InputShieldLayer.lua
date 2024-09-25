--[[
    屏蔽交互操作转圈
    作用期间屏蔽触摸 键盘输入
]]
InputShieldLayer = InputShieldLayer or {}

if InputShieldLayer.Active == nil then
    InputShieldLayer.Active = false
end
InputShieldLayer.Instance = InputShieldLayer.Instance or nil

--[[
    添加协议请求转圈
    SendNetMsgId 发送的协议号
    RemoveNetMsgId 期待返回的协议号
    Duration 转圈超时时间，超过X时间，会强制关闭转圈
    CircleShowDelay  转圈实际显示内容延迟显示
    DurationCallback 超时回调
]]
function InputShieldLayer.Add(Duration,CircleShowDelay,DurationCallback)
    if MvcEntry and MvcEntry:GetModel(ViewModel):GetState(ViewConst.OnlineSubLoginPanel) then
        --在线子系统登录时，不显示转圈
        return
    end
    Duration = Duration or 8
    CircleShowDelay = CircleShowDelay or 1
    
    InputShieldLayer.Active = true
    if not CommonUtil.IsValid(InputShieldLayer.Instance) then
        local widget_class = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(InputShieldLayerUMGPath))
        InputShieldLayer.Instance = NewObject(widget_class, GameInstance, nil, "Client.Common.InputShieldLayerLogic")
        UIRoot.AddChildToLayer(InputShieldLayer.Instance,UIRoot.UILayerType.Tips, 99)
    end
    InputShieldLayer.Instance:Show()
    InputShieldLayer.Instance:ScheduleAutoHide(Duration,DurationCallback)
    InputShieldLayer.Instance:ScheduleCicleShow(CircleShowDelay);
end

--[[
    添加屏蔽层,直到有任何输入操作（键盘&鼠标），抛出事件 ON_INPUT_SHIELD_LAYER_HIDE_AFTER_INPUT 并关闭自身
]]
function InputShieldLayer.AddUntilReceiveInput()
    InputShieldLayer.Instance:AddUntilReceiveInput()
end

function InputShieldLayer.Close()
    -- CLog('recv close indicator..')
    if CommonUtil.IsValid(InputShieldLayer.Instance) then
        InputShieldLayer.Instance:Hide()
    -- else
        -- CLog('InputShieldLayer.Instance nil')
    end
end

function InputShieldLayer.IsActive()
    return InputShieldLayer.Active
end

