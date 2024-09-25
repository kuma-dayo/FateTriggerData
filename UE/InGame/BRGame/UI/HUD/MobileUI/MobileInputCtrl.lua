local MobileInputCtrl = Class("Common.Framework.UserWidget")

function MobileInputCtrl:OnInit()
    print("MobileInputCtrl",">> OnInit")
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.MsgListGMP = {
        { MsgName = "Setting.MobileInputMode.Item",            Func = self.SwitchMobileInputCtrlMode,      bCppMsg = true },
        { MsgName = "UIEvent.HideCommonCancelBtn",             Func = self.HideCommonCancelBtn,            bCppMsg = true },
        { MsgName = "UIEvent.ShowCommonCancelBtn",             Func = self.ShowCommonCancelBtn,            bCppMsg = true },
    }
    MsgHelper:RegisterList(self, self.MsgListGMP)
    self.WB_JoystickRightScreen.OnTouchMovePosChange:Add(self,self.OnRightScreenTouchMovePosChange)
    self.WB_JoystickLeftScreen.OnTouchMovePosChange:Add(self,self.OnLeftScreenTouchMovePosChange)
    UserWidget.OnInit(self)

    --获取当前操控模式设置值
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self.LocalPC)
    if not SettingSubsystem then
        return
    end
    local CurInputMode = SettingSubsystem:GetSettingValue_int32(self.MobileInputModeTag)
    if CurInputMode == UE.EInputCtrlModeType.LeftFixedMoveAndRightFixedFire then
        self:ChangeLeftScreenVisibility(false)
    else
        self:ChangeLeftScreenVisibility(true)
    end
end

function MobileInputCtrl:OnDestroy()
    MsgHelper:UnregisterList(self, self.MsgListGMP or {})
    UserWidget.OnDestroy(self)
end

function MobileInputCtrl:SwitchMobileInputCtrlMode(InTagName,InValue)
    print("MobileInputCtrl:SwitchMobileInputCtrlMode",InTagName,InValue.Value_Int)
    if InValue.Value_Int == UE.EInputCtrlModeType.LeftFixedMoveAndRightFixedFire then
        self:ChangeLeftScreenVisibility(false)
    else
        self:ChangeLeftScreenVisibility(true)
    end
end

function MobileInputCtrl:ChangeLeftScreenVisibility(bLeftMove)
    print("MobileInputCtrl:ChangeLeftScreenVisibility",bLeftMove)
    self.WB_JoystickLeftScreen.GUIImage_VisibleBorder:SetVisibility(bLeftMove and UE.ESlateVisibility.Visible or UE.ESlateVisibility.SelfHitTestInvisible)
    self.JoystickMove.GUIImage_VisibleBorder:SetVisibility(bLeftMove and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Visible)
    self.JoystickMove.bCanDrag = not bLeftMove
    local TempSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.WB_JoystickRightScreen)
    TempSlot:SetAnchors(bLeftMove and self.RightHalfAnchors or self.AllScreenAnchors)
    TempSlot:SetOffsets(self.AllScreenOffset)
end

function MobileInputCtrl:UpdataFireBtnPos(NewPos)
    self:TryToChangeFireBtnPos(NewPos)
end

function MobileInputCtrl:OnRightScreenTouchMovePosChange(InCurIndex,NewPos)
    self:TryToChangeFireBtnPos(NewPos)
end

function MobileInputCtrl:OnLeftScreenTouchMovePosChange(InCurIndex,NewPos)
    local GTInputManager = UE.UGTInputManager.GetGTInputManager(self)
    if not GTInputManager then
        return
    end
    local CurModeType = GTInputManager:GetCurInputModeType()
    if CurModeType == UE.EInputCtrlModeType.LeftFixedMoveAndRightFixedFire then
        return
    end
    local TopLeftPos = UE.UGUIHelper.GetCurViewportTopLeftPos(self.LocalPC)
    local ViewportSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
    if TopLeftPos.X <= NewPos.X and (NewPos.X - TopLeftPos.X) < (ViewportSize.X /2) then
        self:ChangeJoystickMovePos(NewPos)
    end
end

function MobileInputCtrl:TryToChangeFireBtnPos(NewPos)
    local GTInputManager = UE.UGTInputManager.GetGTInputManager(self)
    if not GTInputManager then
        return
    end
    local CurModeType = GTInputManager:GetCurInputModeType()
    if CurModeType ~= UE.EInputCtrlModeType.LeftMoveAndRightFlowFire then
        return
    end
    
    local ButtonRightPos = UE.UGUIHelper.GetCurViewportBottomRightPos(self.LocalPC)
    local ViewportSize = UE.UWidgetLayoutLibrary.GetViewportSize(self)
    if ButtonRightPos.X >= NewPos.X and (ButtonRightPos.X - NewPos.X) < (ViewportSize.X /2) then
        self:ChangeFireBtnPos(NewPos)
    end
end

--设置右开火键位置
function MobileInputCtrl:ChangeFireBtnPos(NewPos)
    local TargetPos = UE.FVector2D()
    local ButtonRightPos = UE.UGUIHelper.GetCurViewportBottomRightPos(self.LocalPC)
    local WidgetSize = UE.USlateBlueprintLibrary.GetLocalSize(self.FireRight:GetCachedGeometry())
    local ViewportScale = UE.UWidgetLayoutLibrary.GetViewportScale(self)
    TargetPos.X = (ButtonRightPos.X - NewPos.X)*-1/ViewportScale+WidgetSize.X/2
    TargetPos.Y = (ButtonRightPos.Y - NewPos.Y)*-1/ViewportScale+WidgetSize.Y/2
    local TempSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.FireRIght)
    TempSlot:SetPosition(TargetPos)
end

--设置移动遥感位置
function MobileInputCtrl:ChangeJoystickMovePos(NewPos)
    local TargetPos = UE.FVector2D()
    local TopLeftPos = UE.UGUIHelper.GetCurViewportTopLeftPos(self.LocalPC)
    local WidgetSize = UE.USlateBlueprintLibrary.GetLocalSize(self.JoystickMove:GetCachedGeometry())
    local ViewportScale = UE.UWidgetLayoutLibrary.GetViewportScale(self)
    TargetPos.X = (NewPos.X - TopLeftPos.X)/ViewportScale-WidgetSize.X/2
    TargetPos.Y = (NewPos.Y - TopLeftPos.Y)/ViewportScale-WidgetSize.Y/2
    local TempSlot = UE.UWidgetLayoutLibrary.SlotAsCanvasSlot(self.JoystickMove)
    TempSlot:SetPosition(TargetPos)
end

function MobileInputCtrl:HideCommonCancelBtn(BtnCancelIA)
    self.BtnCancel:SetVisibility(UE.ESlateVisibility.Collapsed)
    local TempIA = BtnCancelIA:Cast(UE.InputActionExtend)
    if TempIA then
        self.BtnCancel:AddInputActionExtend(TempIA)
    end
end

function MobileInputCtrl:ShowCommonCancelBtn(BtnCancelIA)
    self.BtnCancel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local TempIA = BtnCancelIA:Cast(UE.InputActionExtend)
    if TempIA then
        self.BtnCancel:RemoveInputActionExtend(TempIA)
    end
end

return MobileInputCtrl