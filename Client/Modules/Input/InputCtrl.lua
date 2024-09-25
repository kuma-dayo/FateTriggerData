require("Client.Modules.Input.InputModel")
require("Client.Modules.Input.GlobalInputModel")

--[[
    玩家输入模块
]]
local class_name = "InputCtrl"
---@class InputCtrl : UserGameController
---@field private InputModel InputModel
---@field private GlobalInputModel GlobalInputModel
InputCtrl = InputCtrl or BaseClass(UserGameController,class_name)


function InputCtrl:__init()
    CWaring("==InputCtrl init")
    self.IsBlockInput = false
    self.InputModel = nil
    self.GlobalInputModel = nil
    self.CachePreInputMode = nil    -- 缓存修改前的InputMode
    self.CachePreInputModeObj = nil
    self.IsOpenHallInput = true -- 大厅输入IMCE是否开启，默认为true
end

function InputCtrl:Initialize()
    self.InputModel = self:GetModel(InputModel)
    self.GlobalInputModel = self:GetModel(GlobalInputModel)
    self.UGenericGamepadUMGSubsystem = UE.UGenericGamepadUMGSubsystem.Get(GameInstance);
end

function InputCtrl:OnPreEnterBattle()
    self.CachePreInputMode = nil
    self.CachePreInputModeObj = nil
end

function InputCtrl:AddMsgListenersUser()
    -- 监听输入设备变化
    if self.UGenericGamepadUMGSubsystem then
        self.UGenericGamepadUMGSubsystem.OnCommonInputChange:Add(self.UGenericGamepadUMGSubsystem, Bind(self,self.OnCommonInputChange))
    end

    -- 监听局内IAE输入触发的GMP消息
    self.MsgListGMP = {
        {   InBindObject = _G.MainSubSystem,    MsgName = "UIEvent.GUIButton.OnPressed",   Func = Bind(self, self.OnGUIButtonPressed),   bCppMsg = true,  WatchedObject = nil},
    }
    local MainSubSystem = _G.MainSubSystem
    local function RegistGMPKey(Key)
        local TriggeredTag = EnhanceInputActionTriggered_GMPEvent(Key)
        local TriggeredMsg = { 
            InBindObject = MainSubSystem,	
            MsgName = TriggeredTag,
            -- Func = Bind(self,self.OnReceiveTriggeredGmpMsg, Key), 
            Func = function(FInputActionInstanceExtend)
                self:OnReceiveTriggeredGmpMsg(Key,FInputActionInstanceExtend)
            end, 
            bCppMsg = true, 
            WatchedObject = nil }
        table.insert(self.MsgListGMP,TriggeredMsg)
        local CompletedTag = EnhanceInputActionCompleted_GMPEvent(Key)
        local CompletedMsg = { 
            InBindObject = MainSubSystem,	
            MsgName = CompletedTag,
            -- Func = Bind(self,self.OnReceiveCompletedGmpMsg, Key), 
            Func = function(FInputActionInstanceExtend)
                self:OnReceiveCompletedGmpMsg(Key,FInputActionInstanceExtend)
            end, 
            bCppMsg = true, 
            WatchedObject = nil }
        table.insert(self.MsgListGMP,CompletedMsg)
    end
    for _,Key in pairs(ActionMappings) do
        RegistGMPKey(Key)
    end
    for _,Key in pairs(AxisMappings) do
        RegistGMPKey(Key)
    end
    for _,Key in pairs(GlobalActionMappings) do
        RegistGMPKey(Key)
    end

    self.MsgList = 
    {
        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_ACTIVE_CHANGED,    Func = self.OnViewShowed },
        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_DEACTIVE_CHANGED,  Func = self.OnViewClosed },
    }
    	-- if self.view:IsA(UE.UUserWidget) then
        -- 	local ViewportSize = CommonUtil.GetViewportSize(self.view)
		-- 	UE.UGamepadUMGFunctionLibrary.UpdateWidgetOnShowOrClose(self.view, self.view.StartFocusWidget,true,self.view.StickMoveType,self.view.bIsOnlyCursorMode,self.view.bIsChangeCursorPosition,UE.FVector2D(ViewportSize.X*0.5,ViewportSize.Y*0.5))
		-- end

end

function InputCtrl:RemoveMsgListeners()
    InputCtrl.super.RemoveMsgListeners(self)
	if self.UGenericGamepadUMGSubsystem then
        self.UGenericGamepadUMGSubsystem.OnCommonInputChange:Remove(self.UGenericGamepadUMGSubsystem, Bind(self,self.OnCommonInputChange))
    end
end

-- 输入模式改变 键鼠/手柄
function InputCtrl:OnCommonInputChange(_,CommonInputNotifyType)
    self.InputModel:SetCurInputType(CommonInputNotifyType)
    self.InputModel:DispatchType(InputModel.SET_KEYBOARD_ICON_VISIBLE,CommonInputNotifyType == UE.ECommonInputNotifyType.PC)  
    if CommonInputNotifyType == UE.ECommonInputNotifyType.Gamepad then
        -- 改为手柄的时候，需要更新下当前的手柄光标设置
        self:UpdateCurShowViewGamePadSetting()
    end
end

function InputCtrl:OnReceiveTriggeredGmpMsg(InputGmpMappingKey,FInputActionInstanceExtend)
    if self.IsBlockInput then
        CWaring("InputCtrl Input Is Blocking!")
        return
    end
    local EventKey = InputGmpMappingKey
    -- 是否需要UI层级控制
    local IsInputForUI = true
    if ActionMappings[InputGmpMappingKey] ~= nil then
        EventKey = ActionMappings[InputGmpMappingKey]
    elseif AxisMappings[InputGmpMappingKey] ~= nil then
        EventKey = AxisMappings[InputGmpMappingKey]
    elseif GlobalActionMappings[InputGmpMappingKey] ~= nil then
        EventKey = GlobalActionMappings[InputGmpMappingKey]
        IsInputForUI = false
    end

    if IsInputForUI then
        -- 由InputModel派发，会加入UI层级路由管理
        self.InputModel:DispatchType(EnhanceInputActionTriggered_Event(EventKey),FInputActionInstanceExtend)
    else
        -- 由GlobalInputModel派发，与UI无关，全局会收到输入
        self.GlobalInputModel:DispatchType(EnhanceInputActionTriggered_Event(EventKey),FInputActionInstanceExtend)
    end
    -- 派发一个输入触发的事件，给外部判断是否处于挂机状态
    self.GlobalInputModel:DispatchType(GlobalInputModel.ON_ANY_INPUT_TRIGGERED,EventKey)
end

function InputCtrl:OnReceiveCompletedGmpMsg(InputGmpMappingKey,FInputActionInstanceExtend)
    if self.IsBlockInput then
        CWaring("InputCtrl Input Is Blocking!")
        return
    end
    local EventKey = InputGmpMappingKey
    -- 是否需要UI层级控制
    local IsInputForUI = true
    if ActionMappings[InputGmpMappingKey] ~= nil then
        -- 已经存在对应大厅按键的IA, 转换为对应的IA名称
        EventKey = ActionMappings[InputGmpMappingKey]
    elseif AxisMappings[InputGmpMappingKey] ~= nil then
        EventKey = AxisMappings[InputGmpMappingKey]
    elseif GlobalActionMappings[InputGmpMappingKey] ~= nil then
        EventKey = GlobalActionMappings[InputGmpMappingKey]
        IsInputForUI = false
    end

    if IsInputForUI then
        -- 由InputModel派发，会加入UI层级路由管理
        self.InputModel:DispatchType(EnhanceInputActionCompleted_Event(EventKey),FInputActionInstanceExtend)
    else
        -- 由GlobalInputModel派发，与UI无关，全局会收到输入
        self.GlobalInputModel:DispatchType(EnhanceInputActionCompleted_Event(EventKey),FInputActionInstanceExtend)
    end
end

function InputCtrl:SetIsBlockInput(IsBlockInput)
    self.IsBlockInput = IsBlockInput
end

-- 监听界面打开
function InputCtrl:OnViewShowed(ViewId)
    if ViewConstConfig and ViewConstConfig[ViewId] and  (ViewConstConfig[ViewId].UIResType == GameMediator.UIResType.LEVEL or ViewConstConfig[ViewId].UIResType == GameMediator.UIResType.VIRTUAL or ViewId == ViewConst.Loading) then
        -- level变换 or 打开loading的时候不需要这块操作
        return
    end
    if CommonUtil.IsInBattle() then
        -- 在局内打开Mvc框架内界面,需要设置InputMode以及开启大厅的IMCE
        self:SetIsOpenHallInput(true)
    else
        if not self.IsOpenHallInput then
            -- fix逻辑 防止在非局内情况但输入未正确打开，修正未打开
            self:SetIsOpenHallInput(true)
        end
        if ViewConstConfig and ViewConstConfig[ViewId] and ViewConstConfig[ViewId].NeedUpdateGamepadSetting then
            -- 如果标记为需要更新手柄设置，调用更新
            self:UpdateGamePadSettingOnView(ViewId,true)
        end
    end
end

function InputCtrl:OnViewClosed(ViewId)
    if ViewConstConfig and ViewConstConfig[ViewId] and  (ViewConstConfig[ViewId].UIResType == GameMediator.UIResType.LEVEL or ViewConstConfig[ViewId].UIResType == GameMediator.UIResType.VIRTUAL or ViewId == ViewConst.Loading) then
        -- level变换 or 打开loading的时候不需要这块操作
        return
    end
    if CommonUtil.IsInBattle() then
        -- 在局内关闭Mvc框架内界面，需要恢复InputMode以及关闭大厅的IMCE
        self:SetIsOpenHallInput(false)
    end
end
---------------------------------------------- 

function InputCtrl:SetIsOpenHallInput(IsOpen)
    local LocalPC = CommonUtil.GetLocalPlayerC()
    if not LocalPC then
        CError("InputCtrl:IsOpenHallInput Can't Get LocalPC !",true)
        return
    end
    if IsOpen then
        CWaring("InputCtrl: OpenHallInput") 
        -- 将InputMode修改为GameAndUI
        if not self.CachePreInputMode then
            self.CachePreInputMode = LocalPC:GetCurInputModeData()
            self.CachePreInputModeObj = self.CachePreInputMode.InWidgetToFocus
            local LastFocusView = MvcEntry:GetModel(ViewModel):GetOpenLastViewWithInputFocus()
            local LastFocusWidget = nil
            if LastFocusView then
                LastFocusWidget = MvcEntry:GetCtrl(ViewRegister):GetView(LastFocusView.viewId)
            end
            UE.UWidgetBlueprintLibrary.SetInputMode_GameAndUIEx(LocalPC,LastFocusWidget,UE.EMouseLockMode.DoNotLock,false)
            UE.UGameHelper.SetIsOpenHallInput(LocalPC,true)
            self.IsOpenHallInput = true
        end
    else
        -- 检查是否还有Mvc框架界面
        local OpenedViewList = MvcEntry:GetModel(ViewModel):GetOpenListByLayerList(
        {
            UIRoot.UILayerType.Pop, UIRoot.UILayerType.Dialog,
        })
        CWaring("InputCtrl: ToCloseHallInput OpenedViewCount = "..#OpenedViewList) 
        if #OpenedViewList == 0 then
            -- 没有界面打开了，重置InputMode，并移除大厅IMCE
            if self.CachePreInputMode and (not self.CachePreInputModeObj or self.CachePreInputModeObj:IsValid()) then
                CommonUtil.SetInputModeData(LocalPC,self.CachePreInputMode)
                self.CachePreInputMode = nil
                self.CachePreInputModeObj = nil
            end
            UE.UGameHelper.SetIsOpenHallInput(LocalPC,false)
            self.IsOpenHallInput = false
        end
    end
end

----------------------------------------------- 手柄相关接口 ---------------------------------------------
-- 改为手柄的时候，需要更新下当前的手柄光标设置
function InputCtrl:UpdateCurShowViewGamePadSetting()
    local TopView = MvcEntry:GetModel(ViewModel):GetOpenLastView()
    if TopView and TopView.viewId then
        -- 这里不理会是否有更新标记，只需要更新设置为打开
        self:UpdateGamePadSettingOnView(TopView.viewId,true)
    end
end

-- 刷新界面的手柄光标设置
function InputCtrl:UpdateGamePadSettingOnView(ViewId,IsShow)
    local Mdt =  MvcEntry:GetCtrl(ViewRegister):GetView(ViewId)
    if Mdt and Mdt.view and CommonUtil.IsValid(Mdt.view) then
        local ViewportSize = nil
        if IsShow then
            ViewportSize = CommonUtil.GetViewportSize(GameInstance)
        end
        -- todo 位置后续看需求是否作为参数传入
        CWaring("== InputCtrl UpdateGamePadSettingOnView ViewId = "..ViewId)
        UE.UGamepadUMGFunctionLibrary.UpdateWidgetOnShowOrClose(Mdt.view,IsShow,Mdt.view.StickMoveType,Mdt.view.bIsOnlyCursorMode,Mdt.view.bIsChangeCursorPosition,ViewportSize and UE.FVector2D(ViewportSize.X*0.5,ViewportSize.Y*0.5) or nil)
    else
        CWaring("== InputCtrl UpdateGamePadSettingOnView Failed For ViewId = "..ViewId)
    end
end

-- 关闭 光标设置
function InputCtrl:ResetGamePadSetting(TheHallPlayerController)
    CWaring("== InputCtrl ResetGamePadSetting")
    UE.UGamepadUMGFunctionLibrary.UpdateWidgetOnShowOrClose(TheHallPlayerController or GameInstance, false)
end


-----------

-- 监听GUIButton事件
function InputCtrl:OnGUIButtonPressed()
    self.GlobalInputModel:DispatchType(GlobalInputModel.ON_GUIBUTTON_PRESSED)
end