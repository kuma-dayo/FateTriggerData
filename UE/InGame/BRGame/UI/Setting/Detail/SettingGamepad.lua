require "UnLua"

local SettingGamepad = Class("Common.Framework.UserWidget")

function SettingGamepad:OnInit()
    print("SettingGamepad:OnInit")
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    --初始化咨询一下当前用哪个手柄
    local UseXbox =  SettingSubsystem:GetSettingValueByTagName("Setting.GamepadKey.IsUseXBox")
    self:SwitchGamePad("Setting.GamepadKey.IsUseXBox",UseXbox)
    self.MsgListGMP = {

        { MsgName = "Setting.GamepadKey.IsUseXBox",            Func = self.SwitchGamePad,      bCppMsg = true },
        { MsgName = "Setting.GamepadKey.NormalSkill",            Func = self.SwitchComboxButtonIconLeft,      bCppMsg = true },
        { MsgName = "Setting.GamepadKey.Mark",            Func = self.SwitchComboxButtonIconRight,      bCppMsg = true },
        
    }
    MsgHelper:RegisterList(self, self.MsgListGMP)
    UserWidget.OnInit(self)
end

function SettingGamepad:OnDestroy()
   
	if self.MsgListGMP then
        MsgHelper:UnregisterList(self, self.MsgListGMP)
        self.MsgListGMP = nil
    end
    UserWidget.OnDestroy(self)
end

function SettingGamepad:InitGamepadKeyData()
    --print("SettingGamepad:InitGamepadKeyData")
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    local NeedTab = UE.FGameplayTag()
    NeedTab.TagName = "Setting.GamepadKey"
    local SettingBaseDataForUIMap = SettingSubsystem:GetTotalSettingBaseDataForUIByTabTag(NeedTab)
    --为了后续找数据方便，先将所有的键位存进一个map
    --同时设置好他的图标，因为手柄键位的位置是不变的
    local KeyNameBaseLeft = "BP_Item_GamepadButtonLeft_"
    local KeyNameBaseRight = "BP_Item_GamepadButtonRight_"
    local KeyNameLeft= nil
    local KeyNameRight= nil
    local GamepadKeyIcon =nil
    for i = 0,7 do
        KeyNameLeft = self[KeyNameBaseLeft..i]
        KeyNameRight = self[KeyNameBaseRight..i]
        
        GamepadKeyIcon = SettingSubsystem.KeyIconMap:TryGetIconByKey(self,KeyNameLeft.GamepadKey)
        if GamepadKeyIcon and GamepadKeyIcon:IsValid() then
            KeyNameLeft.ImgIcon_Button:SetBrushFromTexture(GamepadKeyIcon,true)
        end
        KeyNameLeft.GamepadKeyValue = SettingSubsystem.KeyIconMap:TryGetKeyMappedValueByKey(self,KeyNameLeft.GamepadKey)
        --print("SettingGamepad:InitGamepadKeyData left",KeyNameLeft.GamepadKey.KeyName,GamepadKeyIcon,KeyNameLeft.GamepadKeyValue)

        GamepadKeyIcon = SettingSubsystem.KeyIconMap:TryGetIconByKey(self,KeyNameRight.GamepadKey)
        if GamepadKeyIcon and GamepadKeyIcon:IsValid() then
            KeyNameRight.ImgIcon_Button:SetBrushFromTexture(GamepadKeyIcon,true)
        end
        KeyNameRight.GamepadKeyValue = SettingSubsystem.KeyIconMap:TryGetKeyMappedValueByKey(self,KeyNameRight.GamepadKey)
        --print("SettingGamepad:InitGamepadKeyData right",KeyNameRight.GamepadKey.KeyName,GamepadKeyIcon,KeyNameRight.GamepadKeyValue)
        local IsFindLeft = false
        local IsFindRight = false
        local ActivatePad = self.WidgetSwitcher_Type:GetActiveWidget()
        --设置他的文本和判断是否和默认值不同，不同需要将文字的颜色设置
        for k,v in pairs(SettingBaseDataForUIMap) do
            if v.ApplyingSettingValue.Value_IntArray:Num()>0 then
                --print("SettingGamepad:InitGamepadKeyData v.ApplyingSettingValue.Value_IntArray:GetRef(1) ",v.ApplyingSettingValue.Value_IntArray:GetRef(1),"KeyNameLeft.GamepadKeyValue",KeyNameLeft.GamepadKeyValue)
                --print("SettingGamepad:InitGamepadKeyData ",k,v.TextName,v.ApplyingSettingValue.Value_IntArray:GetRef(1),KeyNameLeft.GamepadKey.KeyName,KeyNameLeft.GamepadKeyValue,KeyNameRight.GamepadKey.KeyName,KeyNameRight.GamepadKeyValue)
                if v.ApplyingSettingValue.Value_IntArray:GetRef(1) == KeyNameLeft.GamepadKeyValue then
                     KeyNameLeft.Text_ButtonName:SetText(v.TextName)
                    --print(("SettingGamepad:InitGamepadKeyData11111"),KeyNameLeft.Text_ButtonName:GetText(),KeyNameLeft.GamepadKey.KeyName,KeyNameLeft.GamepadKeyValue,GetObjectName(KeyNameLeft))
                    if v.IsSameAsDefault == false then
                        KeyNameLeft.Text_ButtonName:SetColorAndOpacity(self.Color_Text_Modified)
                        ActivatePad[KeyNameLeft.GamepadKey.KeyName]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    else
                        KeyNameLeft.Text_ButtonName:SetColorAndOpacity(self.Color_Text_Default)
                        ActivatePad[KeyNameLeft.GamepadKey.KeyName]:SetVisibility(UE.ESlateVisibility.Collapsed)
                    end
                    IsFindLeft = true
                elseif v.ApplyingSettingValue.Value_IntArray:GetRef(1) == KeyNameRight.GamepadKeyValue then
                     KeyNameRight.Text_ButtonName:SetText(v.TextName)
                    --print(("SettingGamepad:InitGamepadKeyData11111"),StringUtil.ConvertFText2String(v.TextName),KeyNameRight.Text_ButtonName:GetText(),KeyNameRight.GamepadKey.KeyName,KeyNameRight.GamepadKeyValue,GetObjectName(KeyNameRight))
                    if v.IsSameAsDefault == false then
                        KeyNameRight.Text_ButtonName:SetColorAndOpacity(self.Color_Text_Modified)
                        ActivatePad[KeyNameRight.GamepadKey.KeyName]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                    else
                        KeyNameLeft.Text_ButtonName:SetColorAndOpacity(self.Color_Text_Default)
                        ActivatePad[KeyNameLeft.GamepadKey.KeyName]:SetVisibility(UE.ESlateVisibility.Collapsed)
                    end
                    IsFindRight = true
                end
                if IsFindLeft == true and IsFindRight == true then
                    break
                end
            end
        end


        self.GamepadKeyMap:Add(KeyNameLeft.GamepadKey.KeyName,KeyNameLeft)
        self.GamepadKeyMap:Add(KeyNameRight.GamepadKey.KeyName,KeyNameRight)
    end
    

    --最后需要初始化组合键,组合键跟着战术技能和标记走的，需要初始化的时候读一次人家的值，且监听变化
    local SettingValue =  SettingSubsystem:GetSettingValueByTagName("Setting.GamepadKey.NormalSkill")
    self:SwitchComboxButtonIconLeft(nil,SettingValue)
    SettingValue =  SettingSubsystem:GetSettingValueByTagName("Setting.GamepadKey.Mark")
    self:SwitchComboxButtonIconRight(nil,SettingValue)
end



--更新数据
function SettingGamepad:OnInitialize(InActiviteTag,InTargetBlackboard,InIsShow)
   
    local HoverKey,IsFindHoverKey =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsNameSimple(InTargetBlackboard,"HoverKey")
    if IsFindHoverKey == true then
        self:SetKeyHover(HoverKey)
    end

    local ModifyKey,IsFindModifyKey =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsNameSimple(InTargetBlackboard,"ModifyKey")
    if IsFindModifyKey == true then
        local ModifyKeyText,IsFindModifyKeyText =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsStringSimple(InTargetBlackboard,"ModifyKeyText")
        if IsFindModifyKeyText then
            self:SetKeyModify(ModifyKey,ModifyKeyText)
        end
       
    end

    local DefaultKey,IsFindDefaultKey =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsNameSimple(InTargetBlackboard,"DefaultKey")
    if IsFindDefaultKey == true then
        local DefaultKeyText,IsFindDefaultKeyText =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsStringSimple(InTargetBlackboard,"DefaultKeyText")
        if IsFindDefaultKeyText then
            self:SetKeyDefault(DefaultKey,DefaultKeyText)
        end
        
    end
end

--hover状态,先恢复上一个key的状态为正常
function SettingGamepad:SetKeyHover(Inkey)
    self:SetKeyNormal(self.HoverKey)
    self.GamepadKeyMap:Find(Inkey).ImgBg_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.HoverKey = Inkey
end

--unhover
function SettingGamepad:SetKeyNormal(Inkey)
    if self.GamepadKeyMap:Find(Inkey) then
        self.GamepadKeyMap:Find(Inkey).ImgBg_Selected:SetVisibility(UE.ESlateVisibility.Collapsed) 
    end
    
end

--和默认值不同
function SettingGamepad:SetKeyModify(Inkey,InKeyText)
    if self.GamepadKeyMap:Find(Inkey) then
        self.GamepadKeyMap:Find(Inkey).Text_ButtonName:SetText(InKeyText)
        self.GamepadKeyMap:Find(Inkey).Text_ButtonName:SetColorAndOpacity(self.Color_Text_Modified)
        local ActivatePad = self.WidgetSwitcher_Type:GetActiveWidget()
        ActivatePad[Inkey]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    
end

--和默认值相同
function SettingGamepad:SetKeyDefault(Inkey,InKeyText)
    if self.GamepadKeyMap:Find(Inkey) then
        self.GamepadKeyMap:Find(Inkey).Text_ButtonName:SetText(InKeyText)
        self.GamepadKeyMap:Find(Inkey).Text_ButtonName:SetColorAndOpacity(self.Color_Text_Default)
        local ActivatePad = self.WidgetSwitcher_Type:GetActiveWidget()
        ActivatePad[Inkey]:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function SettingGamepad:SwitchGamePad(InTagName,InValue)
    print("SettingGamepad:SwitchGamePad",InTagName,InValue.Value_Int)
    self.WidgetSwitcher_Type:SetActiveWidgetIndex(InValue.Value_Int)
    self:InitGamepadKeyData()
end

function SettingGamepad:SwitchComboxButtonIconLeft(InTagName,InValue)
    print("SettingGamepad:SwitchComboxButtonIconLeft",InTagName,InValue.Value_IntArray[1])
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    local Key,IsSucceed = SettingSubsystem.KeyIconMap:TryGetKeyByKeyMappedValue(InValue.Value_IntArray:GetRef(1))
    self.BP_Item_GamepadComboxButton.GamepadKey = Key
    local GamepadKeyIcon = SettingSubsystem.KeyIconMap:TryGetIconByKey(self,self.BP_Item_GamepadComboxButton.GamepadKey)
    self.BP_Item_GamepadComboxButton.ImgIcon_Button_Left:SetBrushFromTexture(GamepadKeyIcon,true)
end

function SettingGamepad:SwitchComboxButtonIconRight(InTagName,InValue)
    print("SettingGamepad:SwitchComboxButtonIconRight",InTagName,InValue.Value_IntArray[1])
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    local Key,IsSucceed = SettingSubsystem.KeyIconMap:TryGetKeyByKeyMappedValue(InValue.Value_IntArray:GetRef(1))
    self.BP_Item_GamepadComboxButton.GamepadKey_Right = Key
    local GamepadKeyIcon = UE.UGenericSettingSubsystem.Get(self).KeyIconMap:TryGetIconByKey(self,self.BP_Item_GamepadComboxButton.GamepadKey_Right)
    self.BP_Item_GamepadComboxButton.ImgIcon_Button_Right:SetBrushFromTexture(GamepadKeyIcon,true)
end

return SettingGamepad
