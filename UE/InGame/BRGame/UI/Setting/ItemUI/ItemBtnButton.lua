require "UnLua"

local ItemBtnButton = Class("Common.Framework.UserWidget")

function ItemBtnButton:OnInit()
   
    UserWidget.OnInit(self)
    self:InitData()

end

function ItemBtnButton:OnDestroy()

    UserWidget.OnDestroy(self)
end

function ItemBtnButton:InitData()
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    self.GUITextBlockShowText:SetText(self.Text)
    self.HoverIcon = SettingSubsystem.KeyIconMap:TryGetSoftIconByKeyWithState(self,self.Key, UE.EkeyStateType.Hover)
    self.NormalIcon = SettingSubsystem.KeyIconMap:TryGetSoftIconByKeyWithState(self,self.Key, UE.EkeyStateType.Default)
    self.ControlTipsIcon:SetBrushFromSoftTexture(self.NormalIcon,true)
    
end

function ItemBtnButton:InitGamepadData(InGamepadKey)
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    self.GamepadHoverIcon = SettingSubsystem.KeyIconMap:TryGetSoftIconByKeyWithState(self,InGamepadKey, UE.EkeyStateType.Hover)
    self.GamepadNormalIcon = SettingSubsystem.KeyIconMap:TryGetSoftIconByKeyWithState(self,InGamepadKey, UE.EkeyStateType.Default)
    self.GamepadControlTipsIcon:SetBrushFromSoftTexture(self.GamepadNormalIcon,true)
end
--担心这里动得频繁，所以用了两个框区分
function ItemBtnButton:SetGamepadIconShow(InStatus)
    
    if InStatus == true then
        self.GamepadIconBox:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.IconBox:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.GamepadIconBox:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.IconBox:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    
end




return ItemBtnButton