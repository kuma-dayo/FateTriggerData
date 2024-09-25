--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

local MenuOption = Class("Common.Framework.UserWidget")

function MenuOption:OnInit()

    UserWidget.OnInit(self)
end

function MenuOption:OnDestroy()

    UserWidget.OnDestroy(self)
end

function MenuOption:OnKeyDown(MyGeometry,InKeyEvent)
    local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)
    if PressKey == self.GamepadKey then
        self.GamepadKeyDownDelegate:Broadcast()
    end
    return UE.UWidgetBlueprintLibrary.Unhandled()
end

return MenuOption
