local SettingGamepadInputItem = Class("Common.Framework.UserWidget")

function SettingGamepadInputItem:OnInit()
    print("SettingGamepadInputItem","<<:OnInit")

    self.BindNodes ={
        { UDelegate = self.GUIButton_Clicked.OnClicked, Func = self.OnGamepadInputBtnClicked },
    }
    MsgHelper:OpDelegateList(self, self.BindNodes, true)

    self.MsgList = {
        { MsgName = "SETTING_CustomKey_FinishInput",        Func = self.OnFinishInput,                bCppMsg = false}, 
        { MsgName = "SETTING_CustomKey_ConflictState",      Func = self.OnConflictState,              bCppMsg = false}, 
    }

    UserWidget.OnInit(self)
end

function SettingGamepadInputItem:OnDestroy()
    print("SettingGamepadInputItem","<<:OnDestroy")

    if self.BindNodes then
        MsgHelper:OpDelegateList(self, self.BindNodes, false)
		self.BindNodes = nil
	end

    if self.MsgList then
		MsgHelper:UnregisterList(self, self.MsgList)
		self.MsgList = nil
	end

    UserWidget.OnDestroy(self)
end

function SettingGamepadInputItem:OnInitData(InParentTag, ItemName, curKeys, CurIANameList)
    self.OwnWidgetParentTag = InParentTag
    self.OwnWidgetParentName = ItemName
    self.curKeys = curKeys or {}
    self.curTagName = InParentTag.TagName or ""
    self.CurIANameList = CurIANameList

    self:RefreshCurKeysItem()
end

function SettingGamepadInputItem:OnGamepadInputBtnClicked()
    print("SettingGamepadInputItem","<<:OnGamepadInputBtnClicked")

    self.GUIImage_Bg_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    local Data = {
        Tag = self.curTagName,
        IsFromDetail = false
    }
    MsgHelper:Send(self, "SETTING_CustomKey_SelectedState", Data)
    --局外
    if not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        local Data ={
            CurTagName = self.curTagName,
            TargetkeyCount = 1,
            IsGamePad = true,
        }
        print("SettingCustomKeyInput <<:RefreshItemOnReleased OpenView")
        MvcEntry:OpenView(ViewConst.SettingCustomKeyInputingUI,Data)
        return
    end
    print("SettingCustomKeyInput <<:RefreshItemOnReleased ShowTipsUIByTipsId")
    local UIManager = UE.UGUIManager.GetUIManager(self)
    if not UIManager then
        return
    end

    -- 局内
    local GenericBlackboard = UE.FGenericBlackboardContainer()
    local BBSStringType = UE.FGenericBlackboardKeySelector()  
    BBSStringType.SelectedKeyName = "CurTagName" 
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,BBSStringType, tostring(self.curTagName));
    BBSStringType.SelectedKeyName = "TargetkeyCount" 
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,BBSStringType, tostring(1));--当前默认是单键
    BBSStringType.SelectedKeyName = "IsGamePad" 
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsBool(GenericBlackboard,BBSStringType, true)
    local TipsManager = UE.UTipsManager.GetTipsManager(self)
    TipsManager:ShowTipsUIByTipsId("Setting.CustomKeyInputing",-1,GenericBlackboard,self)
end

function SettingGamepadInputItem:OnFinishInput(InData)
    self.GUIImage_Bg_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)

    if self.curTagName ~= InData.Tag or InData.IsClose then
        return
    end

    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if not SettingSubsystem then
        return
    end

    if self.ParentWidet then
        self.ParentWidet:SetFocus()
    end
    
    local bRefreshCurKeys = false
    local curKeys = {}

    local newSettingValue = UE.FSettingValue()
    local newSettingValueArray = UE.TArray(UE.int32)
    for index = 1, InData.TargetKeys:Length() do
        local key = InData.TargetKeys:Get(index)
        local TargetValue = SettingSubsystem.KeyIconMap:TryGetKeyMappedValueByKey(self, key)
        if TargetValue ~= -1 then
            newSettingValueArray:AddUnique(TargetValue)
        end
        table.insert(curKeys, key)
    end
    newSettingValue.Value_IntArray = newSettingValueArray
    local conflictTagName, bConflict
    conflictTagName, bConflict = SettingSubsystem:IsKeyMapSettingConflict(self.curTagName, newSettingValue, conflictTagName, true)
    if bConflict then
        if self.curTagName ~= conflictTagName then
            bRefreshCurKeys = true

            local Data =
            {
                Tag = conflictTagName,
                AnotherTag = self.curTagName,
                AnotherTagKeys = self.curKeys,
            }
            MsgHelper:Send(self, "SETTING_CustomKey_ConflictState", Data)
        end
    else
        bRefreshCurKeys = true
    end

    if bRefreshCurKeys then
        self.curKeys = curKeys

        SettingSubsystem:ApplySetting(self.curTagName, newSettingValue)

        self:RefreshCurKeysItem()
    end
end
 
function SettingGamepadInputItem:OnConflictState(InData)
    if self.curTagName ~= InData.Tag then
        return
    end

    if self.curTagName == InData.AnotherTag then
        return
    end

    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if not SettingSubsystem then
        return
    end

    self.curKeys = InData.AnotherTagKeys

    local newSettingValue = UE.FSettingValue()
    local newSettingValueArray = UE.TArray(UE.int32)
    for index, value in ipairs(self.curKeys) do
        local TargetValue = SettingSubsystem.KeyIconMap:TryGetKeyMappedValueByKey(self, value)
        if TargetValue ~= -1 then
            newSettingValueArray:AddUnique(TargetValue)
        end
    end
    newSettingValue.Value_IntArray = newSettingValueArray
    SettingSubsystem:ApplySetting(self.curTagName, newSettingValue)

    self:RefreshCurKeysItem()
end

function SettingGamepadInputItem:RevertToDefault(DefaultKeys)
    self.curKeys = DefaultKeys
    self:RefreshCurKeysItem()
end

function SettingGamepadInputItem:RefreshCurKeysItem()
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if not SettingSubsystem then
        return
    end

    local allKeyWidget = self.HorizontalBox_KeyIconList:GetAllChildren()
    for index = 1, self.HorizontalBox_KeyIconList:GetChildrenCount() do
        local keyWidget = allKeyWidget:GetRef(index)
        if keyWidget and keyWidget:IsValid() then
            keyWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    for index, value in ipairs(self.curKeys) do
        local targetKeyWidgetIndex = index * 2 - 1
        local keyWidget = self.HorizontalBox_KeyIconList:GetChildAt(targetKeyWidgetIndex - 1)
        if keyWidget and keyWidget:IsValid() then
            local targetIcon = SettingSubsystem.KeyIconMap:TryGetIconByKeyWithState(self, value, UE.EkeyStateType.Default)
            if targetIcon and targetIcon:IsValid() then
                keyWidget:SetBrushFromTexture(targetIcon)
                keyWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            end

            local keyCombineWidget = self.HorizontalBox_KeyIconList:GetChildAt(targetKeyWidgetIndex - 2)
            if keyCombineWidget and keyCombineWidget:IsValid() then
                keyCombineWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            end
        end
    end

    if SettingSubsystem:IsSameAsDefaultValue(self.curTagName) then
        self.ImgIcon_RedDot:SetVisibility(UE.ESlateVisibility.Collapsed)
        self:NotifyDetailContentChange(self.OwnWidgetParentTag, "DefaultKey", false,"DefaultKeyText", self.OwnWidgetParentName)  
    else
        self.ImgIcon_RedDot:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:NotifyDetailContentChange(self.OwnWidgetParentTag, "ModifyKey", false, "ModifyKeyText", self.OwnWidgetParentName)
    end

    self:BPFunction_AddPlayerMappedKey(self.curKeys, self.CurIANameList)
end

--- 通知detail更新
---@param SelectedKeyName string 
function SettingGamepadInputItem:NotifyDetailContentChange(InParentTag, SelectedKeyName,InIsShowTitle, SelectedKeyTextName, ItemName)
    local GenericBlackboard = UE.FGenericBlackboardContainer()
    local CustomKeySelector= UE.FGenericBlackboardKeySelector() 
    CustomKeySelector.SelectedKeyName = SelectedKeyName
    -- 暂不考虑组合键
    if self.curKeys and next(self.curKeys) and self.curKeys[1] then
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsName(GenericBlackboard, CustomKeySelector, self.curKeys[1].KeyName)
    end

    if SelectedKeyTextName then
        CustomKeySelector.SelectedKeyName = SelectedKeyTextName
        UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard, CustomKeySelector, StringUtil.ConvertFText2String(ItemName))
    end

    local data =
    {
        InTag = InParentTag,
        IsShowTableDetailWidget = false,
        InBlackboard = GenericBlackboard,
        IsShowTitle = InIsShowTitle
    }
    MsgHelper:Send(self, "UIEvent.ChangeDetailContent", data)
end


function SettingGamepadInputItem:SetParentFocusWidget(InParentWidet)
    self.ParentWidet = InParentWidet
end

return SettingGamepadInputItem