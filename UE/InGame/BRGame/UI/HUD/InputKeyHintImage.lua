-- 通用按键提示控件

local InputKeyHintImage = Class("Common.Framework.UserWidget")

-------------------------------------------- Init/Destroy ------------------------------------

function InputKeyHintImage:OnInit()
    print("InputKeyHintImage OnInit")
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.MsgList = {
	}

    UserWidget.OnInit(self)
end

function InputKeyHintImage:OnDestroy()
    MsgHelper:UnregisterList(self, self.MsgList or {})

	UserWidget.OnDestroy(self)
end

function InputKeyHintImage:OnShow(Date, Blackboard)
    self:RefreshKeyIcon(self.InputAction)
end

function InputKeyHintImage:InitNotifyHideObjects(InTable)
    self.ObjectTable = InTable
end

function InputKeyHintImage:BPImpFunc_OnCommonInputNotify(InCurType)
    if not self.ObjectTable then return end
    if #self.ObjectTable == 0 then return end

    if InCurType == UE.ECommonInputNotifyType.Gamepad then
        for _, obj in ipairs(self.ObjectTable) do
            if obj then obj:SetVisibility(UE.ESlateVisibility.Collapsed) end
        end
    end
end

return InputKeyHintImage
