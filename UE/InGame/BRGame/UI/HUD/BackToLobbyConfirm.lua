require "UnLua"



local class_name = "BackToLobbyConfirm"
BackToLobbyConfirm = BackToLobbyConfirm or BaseClass(GameMediator, class_name);


function BackToLobbyConfirm:__init()
    
    print("BackToLobbyConfirm:__init")
    self:ConfigViewId(ViewConst.BackToLobbyConfirm)
    
end


function BackToLobbyConfirm:OnHide()
end



local BackToLobbyConfirm   = Class("Client.Mvc.UserWidgetBase")

function BackToLobbyConfirm:OnInit()
   -- print("BackToLobbyConfirm:OnInit")
    
    self.CommonBtn_Cancel.GUIButton_Tips.OnClicked:Add(self, BackToLobbyConfirm.OnClicked_GUIButton_Close)
    self.CommonBtn_Confirm.GUIButton_Tips.OnClicked:Add(self, BackToLobbyConfirm.OnClicked_GUIButton_ResetDefault)

    self.CommonBtn_Cancel.ControlTipsTxt:SetText(self.RetrunText)
    self.CommonBtn_Cancel.ControlTipsIcon:SetBrushFromSoftTexture(self.ReturnNoramlIcon)
    self.CommonBtn_Cancel.ControlTipsTxt:SetColorAndOpacity(self.TxtNormalColor)
    self.CommonBtn_Confirm.ControlTipsTxt:SetText(self.ConfirmText)
    self.CommonBtn_Confirm.ControlTipsIcon:SetBrushFromSoftTexture(self.ConfirmNormalIcon)
    self.CommonBtn_Confirm.ControlTipsTxt:SetColorAndOpacity(self.TxtNormalColor)
    --self:SetHoveredStyle(self.CommonBtn_Cancel,self.ReturnNoramlIcon,self.ReturnHoverIcon)
    --self:SetHoveredStyle(self.CommonBtn_Confirm,self.ConfirmNormalIcon,self.ConfirmHoverIcon)
    if BridgeHelper.IsMobilePlatform() then
        self.CommonBtn_Confirm.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.CommonBtn_Cancel.ControlTipsIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    UserWidgetBase.OnInit(self)
end

function BackToLobbyConfirm:OnShow(data)
    print("BackToLobbyConfirm:OnShow",data)
    if self.MvcCtrl and self.viewId then
        self.GUITextBlock_TabText:SetText(self.QuitGameTitle)
        self.GUITextBlock_Detail:SetText(self.QuitGameDetail)
        self.CommonBtn_Confirm:OnShow(data,nil)
        self.CommonBtn_Cancel:OnShow(data,nil)
    end
    local GenericGamepadUMGSubsystem = UE.UGenericGamepadUMGSubsystem.Get(GameInstance)
    if GenericGamepadUMGSubsystem  then 
        local status = GenericGamepadUMGSubsystem:IsInGamepadInput()
        self.CommonBtn_Confirm:SetKeyIcon(status)
        self.CommonBtn_Cancel:SetKeyIcon(status)
    end
end

function BackToLobbyConfirm:OnTipsInitialize(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
    print("BackToLobbyConfirm:OnTipsInitialize")
    self:OnTipsInitialize_Implementation(TipsText,TipsBrush,NewCountDownTime,TipGenricBlackboard,Owner)
end

function BackToLobbyConfirm:SetHoveredStyle(Button,UnhoverIcon,HoverIcon)
    Button.GUIButton_Tips.OnHovered:Add(self, function()
        Button.ControlTipsIcon:SetBrushFromSoftTexture(HoverIcon)
        Button.ControlTipsTxt:SetColorAndOpacity(self.TxtHoverColor)
    end)

    Button.GUIButton_Tips.OnUnhovered:Add(self, function()
        Button.ControlTipsIcon:SetBrushFromSoftTexture(UnhoverIcon)
        Button.ControlTipsTxt:SetColorAndOpacity(self.TxtNormalColor)
    end)
end

function BackToLobbyConfirm:OnClicked_GUIButton_Close()
    --print("BackToLobbyConfirm:OnClicked_GUIButton_Close ESC")
    if self.MvcCtrl and self.viewId then
        MvcEntry:CloseView(self.viewId)
        return
    end
   
    self:SetFocus(false)
    local TipsManager = UE.UTipsManager.GetTipsManager(self)
    TipsManager:RemoveTipsUI("MainMenu.BackToLobbyConfirm")

    --MsgHelper:Send(self, "UIEvent.ESCSetting")
end

function BackToLobbyConfirm:OnClicked_GUIButton_ResetDefault()
    --print("BackToLobbyConfirm:OnClicked_GUIButton_ResetDefault")
    if self.MvcCtrl and self.viewId then
         --退出游戏
         local PlayerController = UE.UGameplayStatics.GetPlayerController(self, 0)
         if PlayerController then
             UE.UKismetSystemLibrary.QuitGame(self,PlayerController,0,false)
         end
    else
        self:OnClicked_GUIButton_Close()
        MvcEntry:GetCtrl(CommonCtrl):ExitBattle(ConstUtil.ExitBattleReson.Normal)
    end
end

function BackToLobbyConfirm:OnKeyDown(MyGeometry,InKeyEvent)  
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    print("BackToLobbyConfirm:OnKeyDown",PressKey)
    if PressKey == self.CommonBtn_Cancel.Key or  PressKey ==  self.CommonBtn_Cancel.GamepadKey  then
        self:OnClicked_GUIButton_Close()
        return UE.UWidgetBlueprintLibrary.Handled()
    elseif  PressKey == self.CommonBtn_Confirm.Key or  PressKey == self.CommonBtn_Confirm.GamepadKey  then
        self:OnClicked_GUIButton_ResetDefault()
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    return UE.UWidgetBlueprintLibrary.Unhandled()
end

function BackToLobbyConfirm:OnChangeInputType(InStatus)
    self.CommonBtn_Confirm:SetKeyIcon(InStatus)
    self.CommonBtn_Cancel:SetKeyIcon(InStatus)
end

return BackToLobbyConfirm