-- 通用按键提示控件

local InputHintPanel = Class("Common.Framework.UserWidget")

-------------------------------------------- Init/Destroy ------------------------------------

function InputHintPanel:OnInit()
    print("InputHintPanel OnInit")
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.MsgList = {
	}

    UserWidget.OnInit(self)
end

function InputHintPanel:OnDestroy()
    MsgHelper:UnregisterList(self, self.MsgList or {})

	UserWidget.OnDestroy(self)
end

return InputHintPanel
