

local MobileMarkButton = Class("Common.Framework.UserWidget")

function MobileMarkButton:OnInit()
    print("MobileMarkButton:OnInit", GetObjectName(self))
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.Joystick.BPDelegate_OnJoystickTagEvent:Add(self,self.OnJoystickEvent)
    self.bIsFirest = true
    UserWidget.OnInit(self)
end

function MobileMarkButton:OnDestroy()
    print("MobileMarkButton:OnDestroy")
    UserWidget.OnDestroy(self)
end

function MobileMarkButton:OnJoystickEvent(InControllerId, InAnalogValue)
    print("MobileMarkButton:OnJoystickEvent",InControllerId, InAnalogValue)
    MsgHelper:Send(self, GameDefine.Msg.SelectPanel_Open, {AnalogValue = InAnalogValue, SelectItemType = UE.ESelectItemType.MarkSystem})
end

return MobileMarkButton