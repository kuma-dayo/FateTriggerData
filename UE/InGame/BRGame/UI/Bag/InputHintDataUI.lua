require "UnLua"
require "InGame.BRGame.GameDefine"

local InputHintDataUI = Class("Common.Framework.UserWidget")

function InputHintDataUI:Initialize(Initializer)

end

----- UserWidget Functions -----
function InputHintDataUI:OnInit()
	UserWidget.OnInit(self)
end

function InputHintDataUI:OnDestroy()

	UserWidget.OnDestroy(self)
end

----- UserWidget Functions -----
function InputHintDataUI:SetDataFromKeyCombination(KeyCombinationName, InteractKeyCombinationInfo)
    if not InteractKeyCombinationInfo then
        return
    end

    self.GUITextBlock_Parentheses_Value:SetColorAndOpacity(InteractKeyCombinationInfo.ParenthesesNumberColorAndOpacity)
    self.DisplayName:SetText(InteractKeyCombinationInfo.KeyDescription)
    self.KeyCombinationName = KeyCombinationName
    
    local KeyInputModeList = InteractKeyCombinationInfo.KeyInputInfoArray:Keys()
    for i = 1, KeyInputModeList:Length() do
        local KeyInputMode = KeyInputModeList:Get(i)
        local KeyInputInfo = InteractKeyCombinationInfo.KeyInputInfoArray:FindRef(KeyInputMode)

        local showIconNum = KeyInputInfo.KeyInputArray:Length()
        if showIconNum > 0 then
            self.BP_PlatformKeyIcon:DynamicSetKey(KeyInputMode, KeyInputInfo.KeyInputArray)
        end
    end
    self.BP_PlatformKeyIcon:UpdatePlatformMode()
end

return InputHintDataUI