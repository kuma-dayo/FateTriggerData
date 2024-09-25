--[[
    玩家输入事件派发器
]]
local super = GameEventDispatcher;
local class_name = "InputModel";
---@class InputModel : GameEventDispatcher
InputModel = BaseClass(super, class_name);


--开始滑动
InputModel.ON_BEGIN_TOUCH = "ON_BEGIN_TOUCH"
InputModel.ON_END_TOUCH = "ON_END_TOUCH"

--滑动RLERP
InputModel.ON_TOUCH_LERP = "ON_TOUCH_LERP"

--通用Touch输入
InputModel.ON_COMMON_TOUCH_INPUT = "ON_COMMON_TOUCH_INPUT"

--输入设备方式发生变化
InputModel.ON_COMMON_INPUT_TYPE_CHANGED = "ON_COMMON_INPUT_TYPE_CHANGED"
-- 统一设置键位图标显隐
InputModel.SET_KEYBOARD_ICON_VISIBLE = "SET_KEYBOARD_ICON_VISIBLE"

InputModel.Enable = true

function InputModel:__init()
    --开启事件吞噬
    self.Swallow = true
    self.Enable = true
    self.CallOrderType = EventDispatcher.ECallOrderType.REVERSE_ORDER
    self.CurInputType = UE.ECommonInputNotifyType.PC
    self:DataInit()
end

function InputModel:DataInit()

end

--[[
    玩家登出时调用
]]
function InputModel:OnLogout(data)
    if data then
        --断线重连
        return
    end
    -- CWaring("InputModel:OnLogout===============")
    self:DataInit()
end

--[[
    新增AddListenerWithCheckInput 添加检测 及 路由逻辑
]]
function InputModel:AddListenerWithCheckInput(type_name, call_back, caller,priority) 
    if not caller then
        CError("InputModel:AddListener caller can not be nil",true)
        return
    end
    local WidgetBase = nil
    local IsHandlerView = false
    local IsHandlerViewInputFocus = false
    if caller.IsA and caller:IsA(UE.UUserWidget) then
        WidgetBase = caller
    elseif caller.IsClass and caller.WidgetBase then
        WidgetBase = caller.WidgetBase
        IsHandlerView = true

        if caller.InputFocus then
            IsHandlerViewInputFocus = true
        else
            local ParentHandler = caller.ParentHandler
            while (ParentHandler and ParentHandler.ViewInstance) do
                IsHandlerViewInputFocus = ParentHandler.ViewInstance.InputFocus
                if IsHandlerViewInputFocus then
                    -- CWaring("====================IsHandlerViewInputFocus Fix:" .. caller:ClassName())
                    break
                end
                ParentHandler = ParentHandler.ViewInstance.ParentHandler
            end
        end
    else
        CError("InputModel:AddListener caller must be UUserWidget(UserWidgetBase) or UIHandlerView",true)
    end
    if not (WidgetBase and WidgetBase.IsA and WidgetBase:IsA(UE.UUserWidget)) then
        CError("InputModel:AddListener WidgetBase must be UUserWidget(UserWidgetBase)",true)
        return
    end
    
    local Listener =  InputModel.super.AddListener(self,type_name, call_back, caller,priority)
    if WidgetBase.InputFocus then
        local ViewId = WidgetBase.viewId
        if not ViewId then
            CError("InputModel:AddListener caller must be UUserWidget(UserWidgetBase) With ViewId",true)
            return
        end
        Listener.InputFocusViewId = ViewId
    end
    if IsHandlerViewInputFocus then
        Listener.InputFocusHandlerView = caller
    end
    return Listener
end

--[[
    重写基类方法，获取当前有开启InputFocus的UI堆栈列表
]]
function InputModel:GetUIStack()
    return MvcEntry:GetModel(ViewModel):GetOpenLastViewWithInputFocus()
end
--[[
    判断是否需要派发这个事件
]]
function InputModel:IsListenerCanCall(Listener,LastFocusView)
    if not self.Enable then
        return
    end
    if not LastFocusView then
        return true
    end
    if InputShieldLayer.IsActive() then
        -- 交互屏蔽层存在期间，不响应键盘事件
        return false
    end
    if NetLoading.IsActive() then
        -- 交互屏蔽层存在期间，不响应键盘事件
        return false
    end
    if not Listener then
        return false
    end
    if Listener.InputFocusViewId then
        -- local lastView = MvcEntry:GetModel(ViewModel):GetOpenLastViewWithInputFocus()
        if LastFocusView.viewId == Listener.InputFocusViewId then
            if Listener.InputFocusHandlerView and Listener.InputFocusHandlerView.View and not CommonUtil.GetWidgetIsVisibleReal(Listener.InputFocusHandlerView.View) then
                CWaring(StringUtil.Format("InputModel:Listener(UnValid) Because View UnVisibleReal 1:{0}",Listener.InputFocusHandlerView:ClassName()))
                return false
            else
                return true
            end
        else
            CWaring(StringUtil.Format("InputModel:Listener(UnValid) ViewId is {0},but current show viewId is {1}",Listener.InputFocusViewId,LastFocusView.viewId))
            return false
        end
    elseif Listener.InputFocusHandlerView then
        if Listener.InputFocusHandlerView.View and not CommonUtil.GetWidgetIsVisibleReal(Listener.InputFocusHandlerView.View) then
            CWaring(StringUtil.Format("InputModel:Listener(UnValid) Because View UnVisibleReal 2:{0}",Listener.InputFocusHandlerView:ClassName()))
            return false
        else
            return true
        end
    end
    return true
end

-- 通用输入设备发生变化 例如鼠标点击则更新为PC，手柄按下则更新为手柄
---@field TheInputType UE.ECommonInputNotifyType
function InputModel:SetCurInputType(TheInputType)
    self.CurInputType = TheInputType
    self:DispatchType(InputModel.ON_COMMON_INPUT_TYPE_CHANGED,TheInputType)
end

-- 是否PC输入模式
function InputModel:IsPCInput()
    return self.CurInputType == UE.ECommonInputNotifyType.PC
end

-- 是否手柄输入模式
function InputModel:IsGamePadInput()
    return self.CurInputType == UE.ECommonInputNotifyType.Gamepad
end

return InputModel;