require "UnLua"

local SettingGamepadItem = Class("Common.Framework.UserWidget")

function SettingGamepadItem:OnInit()
    self.MsgListGMP = {

        { MsgName = "Setting.GamepadKey.IsUseXBox",            Func = self.SwitchGamePad,      bCppMsg = true },
     
        
    }
    MsgHelper:RegisterList(self, self.MsgListGMP)
    UserWidget.OnInit(self)
end

function SettingGamepadItem:OnDestroy()
	if self.MsgListGMP then
        MsgHelper:UnregisterList(self, self.MsgListGMP)
        self.MsgListGMP = nil
    end
    UserWidget.OnDestroy(self)
end

function SettingGamepadItem:OnInitData(InParentTag, ItemName, InWidgetDataBase)
    self.Overridden.OnInitData(self, InParentTag, ItemName, InWidgetDataBase)
    self.ItemName = ItemName

    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if not SettingSubsystem then
        return
    end

    local curKeys = {}
    local settingValue = SettingSubsystem:GetSubContentConfigDataByTagName(InParentTag.TagName)
    if settingValue then
        for i = 1, settingValue.Value_IntArray:Num() do
            local outKey, bsuccess
            outKey, bsuccess = SettingSubsystem.KeyIconMap:TryGetKeyByKeyMappedValue(settingValue.Value_IntArray:GetRef(i), outKey)
            if bsuccess then
                table.insert(curKeys, outKey)
            end
        end
    end

    self.CurIANameList = self:BPFunction_GetGamepadKeyMapData(InWidgetDataBase)

    self.BP_SettingGamepadInputItem:OnInitData(InParentTag, ItemName, curKeys, self.CurIANameList)

    SettingSubsystem:CheckNeedToFreshData(InParentTag.TagName)
end

function SettingGamepadItem:SetHoverStyle()
    UE.UGTSoundStatics.PostAkEvent(self, self.HoverSound)
    
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.TextBlock_Title:SetColorAndOpacity(self.TextHoverColor)
    self.GUIImage_Bg_List:SetVisibility(UE.ESlateVisibility.Collapsed)
end


function SettingGamepadItem:SetNormalStyle()
    UE.UGTSoundStatics.PostAkEvent(self, self.UnhoverSound)
    
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TextBlock_Title:SetColorAndOpacity(self.TextOriginalColor)
    self.GUIImage_Bg_List:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end


-- 鼠标按键移入
function SettingGamepadItem:OnMouseEnter(InMyGeometry, InMouseEvent)
    
    self:SetHoverStyle()

    self.BP_SettingGamepadInputItem:NotifyDetailContentChange(self.ParentTag, "HoverKey",true)
end


-- 鼠标按键移出
function SettingGamepadItem:OnMouseLeave(InMouseEvent)
    
	self:SetNormalStyle()
end


function SettingGamepadItem:RefreshItemContent(ItemContent)
    if ItemContent ==nil then
        EnsureCall("SettingGamepadItem:RefreshItemContent ItemContent is nil")
        return
    end
    print("SettingGamepadItem:RefreshItemContent DefaultValue",ItemContent.DefaultValue,self.ParentTag.TagName,ItemContent.KeyArray:Num())

    local SettingSubsystem  = UE.UGenericSettingSubsystem.Get(self)
    if not SettingSubsystem then
        return
    end

    local curKeys = {}
    local KeyArray = ItemContent.KeyArray
    if KeyArray then
        for i = 1, KeyArray:Num() do
            local outKey, bsuccess
            outKey, bsuccess = SettingSubsystem.KeyIconMap:TryGetKeyByKeyMappedValue(KeyArray:GetRef(i), outKey)
            if bsuccess then
                table.insert(curKeys, outKey)
            end
        end
    end
    self.BP_SettingGamepadInputItem:OnInitData(self.ParentTag, self.ItemName, curKeys, self.CurIANameList)
end

function SettingGamepadItem:ResetDefaultData(InParentTag, ItemName, InWidgetDataBase)
    print("SettingGamepadItem:ResetDefaultData")

    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if not SettingSubsystem then
        return
    end

    local DefaultKeys = {}
    local settingValue = SettingSubsystem:GetDefaultValueByStruct(InWidgetDataBase)
    if settingValue then
        for i = 1, settingValue.Value_IntArray:Num() do
            local outKey, bsuccess
            outKey, bsuccess = SettingSubsystem.KeyIconMap:TryGetKeyByKeyMappedValue(settingValue.Value_IntArray:GetRef(i), outKey)
            if bsuccess then
                table.insert(DefaultKeys, outKey)
            end
        end
    end

	self.BP_SettingGamepadInputItem:RevertToDefault(DefaultKeys)
end
--切换手柄的时候刷新图标，因为这个只给手柄用，所以不配规则写了特殊逻辑
function SettingGamepadItem:SwitchGamePad()
    
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if not SettingSubsystem then
        return
    end
    local curKeys = {}
    local KeyArray = SettingSubsystem:GetSettingValueByTagName(self.ParentTag.TagName).Value_IntArray
    if KeyArray then
        for i = 1, KeyArray:Num() do
            local outKey, bsuccess
            outKey, bsuccess = SettingSubsystem.KeyIconMap:TryGetKeyByKeyMappedValue(KeyArray:GetRef(i), outKey)
            if bsuccess then
                table.insert(curKeys, outKey)
            end
        end
    end
    self.BP_SettingGamepadInputItem:OnInitData(self.ParentTag, self.ItemName, curKeys, self.CurIANameList)
    
end


function SettingGamepadItem:OnFocusReceived(MyGeometry,InFocusEvent)
    if BridgeHelper.IsPCPlatform() then self:SetHoverStyle() end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function SettingGamepadItem:OnFocusLost(InFocusEvent)
    if BridgeHelper.IsPCPlatform() then self:SetNormalStyle() end
   
end

function SettingGamepadItem:OnKeyDown(MyGeometry,InKeyEvent)  
	local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)

    --手柄按下开始改键
    if PressKey == self.Gamepad_Select then      
        --将焦距传给Item缓存，改键完成之后焦距可以顺利回来
        self.BP_SettingGamepadInputItem:SetParentFocusWidget(self)
        self.BP_SettingGamepadInputItem:OnGamepadInputBtnClicked()
    end
    return UE.UWidgetBlueprintLibrary.Unhandled()
end

return SettingGamepadItem
