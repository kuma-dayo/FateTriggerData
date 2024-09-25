require "UnLua"

local SettingCustomKey = Class("Common.Framework.UserWidget")
local StateType = {
	Default	        = 0,
	Hovered	        = 1,
	Clicked	        = 2,
	Conflict_Front	= 3,
	Conflict_Behind	= 4,
    Special         = 5,
    Selected	    = 6,

}

function SettingCustomKey:OnInit()
    print("SettingCustomKey","<<:OnInit",GetObjectName(self))
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.MsgList = {
        { MsgName = "SETTING_CustomKey_SelectedState",	    Func = self.OnSelectedState,      bCppMsg = false},
        { MsgName = "SETTING_CustomKey_HoverState",	        Func = self.OnHoveredState,       bCppMsg = false},
        { MsgName = "SETTING_CustomKey_FinishInput",        Func = self.OnFinishInput,        bCppMsg = false}, 
    }
    MsgHelper:RegisterList(self, self.MsgList)
    self.BindNodes ={
        { UDelegate = self.GUIImage_Bg_List.OnMouseEnter, Func = self.OnMouseEnter },
        { UDelegate = self.GUIImage_Bg_List.OnMouseLeave, Func = self.OnMouseLeave },
    }
    MsgHelper:OpDelegateList(self, self.BindNodes, true)
    UserWidget.OnInit(self)
end

function SettingCustomKey:OnDestroy()
    print("SettingCustomKey","<<:OnDestroy")
	if self.MsgList then
		MsgHelper:UnregisterList(self, self.MsgList)
		self.MsgList = nil
	end
    if self.BindNodes then
        MsgHelper:OpDelegateList(self, self.BindNodes, false)
		self.BindNodes = nil
	end
    UserWidget.OnDestroy(self)
end

-- 初始化
function SettingCustomKey:LuaInitData(InSecondTag,InParentTag,InIANameList)
    print("SettingCustomKey","<<:LuaInitData 111",InParentTag)
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if not SettingSubsystem then
        print("SettingCustomKey","<<:OnInitData Fail not SettingSubsystem !")
        return
    end
    self.SecondTag = InSecondTag
    local ConfigData = SettingSubsystem:GetSubContentDefaultDataByTag(InParentTag)
	self.BP_SettingCustomKeyInputItem:InitData(0, self.FirstCurKeys,self.DefaultKeys,self.FirstTag,InIANameList,ConfigData.Name,InSecondTag, false)
    local SecondIANameList = UE.TArray(UE.FString)
    if InIANameList and InIANameList:Num()>0 then
        for i = 1, InIANameList:Num() do
            local IAName = InIANameList:GetRef(i)
            if IAName then
                IAName = UE.UKismetStringLibrary.Concat_StrStr(IAName,self.SecondKeyStr)
            end
            SecondIANameList:AddUnique(IAName)
        end
    end
	self.BP_SettingCustomKeyInputItem_1:InitData(1,self.SecondCurKeys, nil,InSecondTag,SecondIANameList,ConfigData.Name,self.FirstTag, false)
    self.CurTagList:AddUnique(self.FirstTag)
    self.CurTagList:AddUnique(InSecondTag)

    SettingSubsystem:CheckNeedToFreshData(InParentTag.TagName)
end

function SettingCustomKey:CheckObjectIsValid(InIA)
    return InIA and InIA:IsValid()
end

-- 重置成默认
function SettingCustomKey:ResetDefaultData(InParentTag,ItemName,InWidgetDataBase)
    print("SettingCustomKey","<<:RestDefaultData")
	self.BP_SettingCustomKeyInputItem:RevertToDefault()
	self.BP_SettingCustomKeyInputItem_1:RevertToDefault()
end

function SettingCustomKey:OnSelectedState(InData)
    print("SettingCustomKey","<<:OnStateChange Tag:", InData.Tag)
    if not self.CurTagList:Contains(InData.Tag) then
        return
    end

    if InData.IsFromDetail then--Detail 跳转
        MsgHelper:Send(self, "UIEvent.SetScrollWidgetIntoView", self)--滑动到指定位置
        self:RefreshItemHoverStyle(true)
        return
    end
    -- self:RefreshItemHoverStyle(false)
end

function SettingCustomKey:OnHoveredState(InData)
    print("SettingCustomKey","<<:OnHoveredState Tag:", InData.Tag)
    if self.CurTagList:Contains(InData.Tag) then
        return
    end
    -- self:RefreshItemHoverStyle(false)
end

function SettingCustomKey:OnFinishInput(InData)
    print("SettingCustomKey","<<:OnFinishInput Tag:", InData.Tag)
    if not self.CurTagList:Contains(InData.Tag) then
        return
    end
    --其中一个 槽 的状态是 Conflict_Front
    local bIsFirstSlotConflict = self.BP_SettingCustomKeyInputItem.CurState == StateType.Conflict_Front
    local bIsSecondSlotConflict = self.BP_SettingCustomKeyInputItem_1.CurState == StateType.Conflict_Front
    if not bIsFirstSlotConflict and not bIsSecondSlotConflict then
        return
    end
    -- 当前改的是非冲突的槽 但是需要更新冲突的槽
    local TargetItem = self.BP_SettingCustomKeyInputItem
    if bIsSecondSlotConflict then
        TargetItem = self.BP_SettingCustomKeyInputItem_1
    end
    InData.Tag = TargetItem.CurTag
    TargetItem:OnFinishInputUpdateItem(InData,true)
end

-- 鼠标移入
function SettingCustomKey:OnMouseEnter(InMyGeometry, InMouseEvent)
    self:SetHoverStyle()
end

-- 鼠标移出
function SettingCustomKey:OnMouseLeave(InMouseEvent)
    self:SetNormalStyle()
end

function SettingCustomKey:SetHoverStyle()
    UE.UGTSoundStatics.PostAkEvent(self, self.HoverSound)
    local Data = {
        Tags = self.CurTagList
    }
    MsgHelper:Send(self, "SETTING_CustomKey_HoverState", Data)
    self:RefreshItemHoverStyle(true)

    -- 显示 detail
    self:RefreshDetail()
end

function SettingCustomKey:SetNormalStyle()
    self:RefreshItemHoverStyle(false)
end

function SettingCustomKey:RefreshItemHoverStyle(bIsHover)
    print("SettingCustomKey","<<:RefreshItemHoverStyle bIsHover:",bIsHover)
    self.IM_BG_Hover:SetVisibility(bIsHover and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if bIsHover then
        return
    end

    local function RefreshToNormal(InTargetItem)
        if InTargetItem.CurState ~= StateType.Default and InTargetItem.CurState ~= StateType.Conflict_Front
         and InTargetItem.CurState ~= StateType.Conflict_Behind and InTargetItem.CurState ~= StateType.Selected then
            InTargetItem.CurState = StateType.Default
            InTargetItem:RefreshItem()
        end
	end
    RefreshToNormal(self.BP_SettingCustomKeyInputItem)
    RefreshToNormal(self.BP_SettingCustomKeyInputItem_1)
end

-- 获取目标按键的组合名
function SettingCustomKey:GetTargetKeysName(InFirstKeys,InScendKeys)
    local TargetName = UE.FText("")
    local KeysNum = 0
    for index = 1, InFirstKeys:Length() do
        local TempValue = InFirstKeys:GetRef(index)
        local DisplayName = UE.UKismetInputLibrary.Key_GetDisplayName(TempValue,true)
        if UE.UKismetTextLibrary.Conv_TextToString(DisplayName) == "None" then
            break
        end
        KeysNum = KeysNum + 1
        if index > 1 and KeysNum > 1 then
            local TempStr = UE.UKismetTextLibrary.Conv_TextToString(TargetName)
            TempStr = TempStr..","
            TargetName = UE.UKismetTextLibrary.Conv_StringToText(TempStr)
        end
        local ResultStr = string.match(DisplayName, G_ConfigHelper:GetStrFromCommonStaticST("Lua_SettingCustomKey_key"))
        if ResultStr then
            TargetName = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"),TargetName,DisplayName)
        else
            TargetName = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SettingCustomKey_key"),TargetName,DisplayName)
        end
    end
    for index = 1, InScendKeys:Length() do
        local TempValue = InScendKeys:GetRef(index)
        local DisplayName = UE.UKismetInputLibrary.Key_GetDisplayName(TempValue,true)
        if UE.UKismetTextLibrary.Conv_TextToString(DisplayName) == "None" then
            break
        end
        KeysNum = KeysNum + 1
        if KeysNum > 1 then
            local TempStr = UE.UKismetTextLibrary.Conv_TextToString(TargetName)
            TempStr = TempStr..","
            TargetName = UE.UKismetTextLibrary.Conv_StringToText(TempStr)
        end
        local ResultStr = string.match(DisplayName, G_ConfigHelper:GetStrFromCommonStaticST("Lua_SettingCustomKey_key"))
        if ResultStr then
            TargetName = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"),TargetName,DisplayName)
        else
            TargetName = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_SettingCustomKey_key"),TargetName,DisplayName)
        end
    end
    print("SettingCustomKey","<<:GetTargetKeysName TargetName:",TargetName)
    return TargetName
end

-- 获取目标按键的映射值
function SettingCustomKey:GetTargetKeysValue(InKeys)
    local TargetValues = {}
    if not InKeys then
        return TargetValues
    end
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if not SettingSubsystem then
        return TargetValues
    end
    for index = 1, InKeys:Length() do
        local TempKey = InKeys:GetRef(index)
        local DisplayName = UE.UKismetInputLibrary.Key_GetDisplayName(TempKey,true)
        local TargetValue = SettingSubsystem.KeyIconMap:TryGetKeyMappedValueByKey(self,TempKey)
        table.insert(TargetValues,TargetValue)
        print("SettingCustomKey","<<:GetTargetKeysValue TargetValue:",TargetValue,DisplayName)
    end
    return TargetValues
end

function SettingCustomKey:RefreshDetail()
    --组建黑板
    local GenericBlackboard = UE.FGenericBlackboardContainer()
    local CustomKeySelector= UE.FGenericBlackboardKeySelector() 
    CustomKeySelector.SelectedKeyName = "DefaultKeysStr"
    local DefaultKeysStr = self:GetTargetKeysName(self.BP_SettingCustomKeyInputItem.DefaultKeys,self.BP_SettingCustomKeyInputItem_1.DefaultKeys)
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,CustomKeySelector, tostring(DefaultKeysStr))
    CustomKeySelector.SelectedKeyName = "CurKeysStr"
    local CurKeysStr = self:GetTargetKeysName(self.BP_SettingCustomKeyInputItem.CurKeys,self.BP_SettingCustomKeyInputItem_1.CurKeys)
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,CustomKeySelector, tostring(CurKeysStr))
    CustomKeySelector.SelectedKeyName = "FirstKeyDes"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,CustomKeySelector, tostring(self.BP_SettingCustomKeyInputItem.ConflictFrontDes))
    CustomKeySelector.SelectedKeyName = "FirstKeyValue"
    local FirstKeyValue = self:GetTargetKeysValue(self.BP_SettingCustomKeyInputItem.ConflictFrontPreEffectiveKeys)
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,CustomKeySelector, tostring(FirstKeyValue[1]))
    CustomKeySelector.SelectedKeyName = "FirstKeyTag"
    local FirstKeyTag =  self.BP_SettingCustomKeyInputItem.ConflictFrontItemTag
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard, CustomKeySelector,tostring(FirstKeyTag))
    CustomKeySelector.SelectedKeyName = "SecondKeyDes"
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,CustomKeySelector, tostring(self.BP_SettingCustomKeyInputItem_1.ConflictFrontDes))
    CustomKeySelector.SelectedKeyName = "SecondKeyValue"
    local SecondKeyValue = self:GetTargetKeysValue(self.BP_SettingCustomKeyInputItem_1.ConflictFrontPreEffectiveKeys)
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,CustomKeySelector, tostring(SecondKeyValue[1]))
    CustomKeySelector.SelectedKeyName = "SecondKeyTag"
    local SecondKeyTag =  self.BP_SettingCustomKeyInputItem_1.ConflictFrontItemTag
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard, CustomKeySelector,tostring(SecondKeyTag))
    print("SettingCustomKey:RefreshDetail DefaultKeysStr:", DefaultKeysStr, ",CurKeysStr:", CurKeysStr,
       ",FirstKeyValue:", FirstKeyValue[1], ",SecondKeyValue:", SecondKeyValue[1], ",FirstConflictFrontDes:",
       self.BP_SettingCustomKeyInputItem.ConflictFrontDes, ",SecondConflictFrontDes:",
       self.BP_SettingCustomKeyInputItem_1.ConflictFrontDes,",FirstKeyTag:",FirstKeyTag,",SecondKeyTag:",SecondKeyTag)
    local data =
    {
       InTag = self.ParentTag,
       IsShowTableDetailWidget = true,
       InBlackboard = GenericBlackboard
    }
    MsgHelper:Send(self, "UIEvent.ChangeDetailContent",data)
end

function SettingCustomKey:RefreshItemContent(ItemContent)
    if ItemContent == nil then
        EnsureCall("SettingCustomKey:RefreshItemContent ItemContent is nil")
        return
    end
    
    local SettingSubsystem  = UE.UGenericSettingSubsystem.Get(self)
    if not SettingSubsystem then
        return
    end

    local curKeys = UE.TArray(UE.FKey)
   
    local KeyArray = ItemContent.KeyArray
    if KeyArray then
        for i = 1, KeyArray:Num() do
            local outKey, bsuccess
            outKey, bsuccess = SettingSubsystem.KeyIconMap:TryGetKeyByKeyMappedValue(KeyArray:GetRef(i), outKey)
            if bsuccess then
                curKeys:AddUnique(outKey)
            end
        end
    end

    self.SecondCurKeys:Clear()
    local SecondConfigData = SettingSubsystem:GetSubContentConfigDataByTagName(self.SecondTag)
    if SecondConfigData then
        local KeyArray = SecondConfigData.KeyArray
        if KeyArray then
            for i = 1, KeyArray:Num() do
                local outKey, bsuccess
                outKey, bsuccess = SettingSubsystem.KeyIconMap:TryGetKeyByKeyMappedValue(KeyArray:GetRef(i), outKey)
                if bsuccess then
                    self.SecondCurKeys:AddUnique(outKey)
                end
            end
        end
    end

    local ConfigData = SettingSubsystem:GetSubContentDefaultDataByTag(self.ParentTag)
	self.BP_SettingCustomKeyInputItem:InitData(0, curKeys, self.DefaultKeys, self.FirstTag, nil, ConfigData.Name, self.SecondTag, true)
	self.BP_SettingCustomKeyInputItem_1:InitData(1, self.SecondCurKeys, nil, self.SecondTag, nil, ConfigData.Name, self.FirstTag, true)
end

function SettingCustomKey:PrintIAMessage(Obj)
    print("SettingCustomKey:PrintMessage IA",Obj)
    print("SettingCustomKey:PrintMessage IAName",GetObjectName(Obj))
end

function SettingCustomKey:OnFocusReceived(MyGeometry,InFocusEvent)
    if BridgeHelper.IsPCPlatform() then self:SetHoverStyle() end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function SettingCustomKey:OnFocusLost(InFocusEvent)
    if BridgeHelper.IsPCPlatform() then self:SetNormalStyle() end
   
end
 
function SettingCustomKey:OnKeyDown(MyGeometry,InKeyEvent)  
	local PressKey = UE.UKismetInputLibrary.GetKey(InKeyEvent)

    if PressKey == self.Gamepad_Select then      
        self.BP_SettingCustomKeyInputItem:SetParentFocusWidget(self)
        self.BP_SettingCustomKeyInputItem:SetFocus()
        return UE.UWidgetBlueprintLibrary.Handled()
    end
    return UE.UWidgetBlueprintLibrary.Unhandled()
end


return SettingCustomKey