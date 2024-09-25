require "UnLua"

local class_name = "SettingCustomKeyInputingUI"
SettingCustomKeyInputingUI = SettingCustomKeyInputingUI or BaseClass(GameMediator, class_name);

function SettingCustomKeyInputingUI:__init()
    print("SettingCustomKeyInputingUI:__init")
    self:ConfigViewId(ViewConst.SettingCustomKeyInputingUI)
end

local SettingCustomKeyInputing = Class("Client.Mvc.UserWidgetBase")

function SettingCustomKeyInputing:OnInit()
    print("SettingCustomKeyInputing:OnInit")
    
    self.ListenKeyInputingList = {}
    
    UserWidgetBase.OnInit(self)
end
function SettingCustomKeyInputing:OnShow(data)
    print("SettingCustomKeyInputing:OnShow",data)

    self.ListenKeyInputingList = {}

    self.IsShow = true
    self:SetVisibility(UE.ESlateVisibility.Visible) 
    if self.MvcCtrl and self.viewId then
        local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
        if PlayerController then
            self.bIsFocusable = true
            self:SetFocus(true)
            UE.UWidgetBlueprintLibrary.SetInputMode_UIOnlyEx(PlayerController)
        end
    end
    if data and data.CurTagName and data.TargetkeyCount then
        self.TargetKeys:Clear()
        self.CurTag = data.CurTagName
        self.TargetkeyCount = data.TargetkeyCount
        self.IsGamePad = data.IsGamePad or false
    end
end

function SettingCustomKeyInputing:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    print("SettingCustomKeyInputing:OnTipsInitialize")

    self.ListenKeyInputingList = {}

    self.TargetKeys:Clear()
    local TxtKey = UE.FGenericBlackboardKeySelector()
    TxtKey.SelectedKeyName ="CurTagName"
    local CurTagName,IsFindCurTagName=UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(TipGenricBlackboard,TxtKey)
    if IsFindCurTagName then
        self.CurTag = CurTagName
    end
    TxtKey.SelectedKeyName ="TargetkeyCount"
    local TargetkeyCount,IsFindTargetkeyCount=UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(TipGenricBlackboard,TxtKey)
    if IsFindTargetkeyCount then
        self.TargetkeyCount = TargetkeyCount
    end
    TxtKey.SelectedKeyName ="IsGamePad"
    local IsGamePad,IsFindIsGamePad=UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBool(TipGenricBlackboard,TxtKey)
    if IsFindIsGamePad then
        self.IsGamePad = IsGamePad
    end
    print("SettingCustomKeyInputing:OnShow ShowMouseCursor true CurTagName :",self.CurTag,IsFindCurTagName,TargetkeyCount,IsFindTargetkeyCount)  
end

function SettingCustomKeyInputing:CloseSelf()
    print("SettingCustomKeyInputing:CloseSelf")
    --关闭界面
    self:SetFocus(false)
    if self.MvcCtrl and self.viewId then
        MvcEntry:CloseView(self.viewId)  
        return
    end

    local TipsManager = UE.UTipsManager.GetTipsManager(self)
    TipsManager:RemoveTipsUI("Setting.CustomKeyInputing")
end

function SettingCustomKeyInputing:OnKeyDown(MyGeometry,InKeyEvent)  
    local InKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if self.ClosedKeys:Contains(InKey) then
        self.ListenKeyInputingList[InKey.KeyName] = true
    elseif not self.IsGamePad then
        if UE.UKismetInputLibrary.Key_IsKeyboardKey(InKey) then
            self.ListenKeyInputingList[InKey.KeyName] = true
        end
    else
        if UE.UKismetInputLibrary.Key_IsGamepadKey(InKey) and not self.IgnoreKeys_GamePad:Contains(InKey) then
            self.ListenKeyInputingList[InKey.KeyName] = true
        end
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function SettingCustomKeyInputing:OnKeyUp(MyGeometry,InKeyEvent)
    local InKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if self.ListenKeyInputingList[InKey.KeyName] then
        self.ListenKeyInputingList[InKey.KeyName] = false
        return self:OnKeyOrMouseButtonUp(InKey)
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function SettingCustomKeyInputing:OnMouseButtonUp(MyGeometry,InMouseEvent)
    if self.IsGamePad then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    return self:OnKeyOrMouseButtonUp(UE.UKismetInputLibrary.PointerEvent_GetEffectingButton(InMouseEvent))
end

function SettingCustomKeyInputing:OnMouseWheel(MyGeometry,InMouseEvent)
    if self.IsGamePad then
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    local CurWheelDelta = UE.UKismetInputLibrary.PointerEvent_GetWheelDelta(InMouseEvent)
    local PressKey = CurWheelDelta > 0 and self.WheelUp or self.WheelDown
    return self:OnKeyOrMouseButtonUp(PressKey)
end

function SettingCustomKeyInputing:OnKeyOrMouseButtonUp(InPressKey)
    local DisplayName = UE.UKismetInputLibrary.Key_GetDisplayName(InPressKey,true)
    print("SettingCustomKeyInputing:OnKeyOrMouseButtonUp",DisplayName)
    if self.ClosedKeys:Contains(InPressKey) then--关闭界面 清空当前键位信息
        self:CloseSelf()
        local Data = {
            Tag = self.CurTag,
            TargetKeys = self.TargetKeys,
            IsClose = true;
        }
        MsgHelper:Send(self, "SETTING_CustomKey_FinishInput", Data)   
        return UE.UWidgetBlueprintLibrary.Handled()
    elseif self.IgnoreKeys:Contains(InPressKey) then--忽略输入
        return UE.UWidgetBlueprintLibrary.Handled()
    end

    local CurLength = self.TargetKeys:AddUnique(InPressKey)
    print("SettingCustomKeyInputing:OnKeyOrMouseButtonUp",CurLength,self.TargetKeys:Length(),self.TargetkeyCount)
    if CurLength == self.TargetkeyCount then
        self:CloseSelf()
        local Data = {
            Tag = self.CurTag,
            TargetKeys = self.TargetKeys,
            IsClose = false;
        }
        MsgHelper:Send(self, "SETTING_CustomKey_FinishInput", Data)   
    end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function SettingCustomKeyInputing:OnFocusReceived(MyGeometry,InKeyEvent)  
    print("SettingCustomKeyInputing:OnFocusReceived")
    self:SetFocus(true)
    return UE.UWidgetBlueprintLibrary.Handled()
end

return SettingCustomKeyInputing