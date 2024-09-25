require "UnLua"
local SettingCustomKeyInput = Class("Common.Framework.UserWidget")
local StateType = {
	Default	        = 0,
	Hovered	        = 1,
	Clicked	        = 2,
	Conflict_Front	= 3,
	Conflict_Behind	= 4,
    Special         = 5,
    Selected	    = 6,

}

function SettingCustomKeyInput:OnInit()
    print("SettingCustomKeyInput","<<:OnInit")
    self.BindNodes ={
        { UDelegate = self.GUIButton_Clicked.OnHovered, Func = self.RefreshItemOnHovered },
        { UDelegate = self.GUIButton_Clicked.OnUnhovered, Func = self.RefreshItemOnUnhovered },
        { UDelegate = self.GUIButton_Clicked.OnPressed, Func = self.RefreshItemOnPressed },
        { UDelegate = self.GUIButton_Clicked.OnReleased, Func = self.RefreshItemOnReleased },

        { UDelegate = self.GUIButton_Default.OnClicked, Func = self.DefaultBtnOnClicked },
        { UDelegate = self.GUIButton_Default.OnHovered, Func = self.RefreshItemOnHovered },
        { UDelegate = self.GUIButton_Default.OnUnhovered, Func = self.RefreshItemOnUnhovered },

        { UDelegate = self.GUIButton_Remove.OnClicked, Func = self.RemoveBtnOnClicked },
        { UDelegate = self.GUIButton_Remove.OnHovered, Func = self.RefreshItemOnHovered },
        { UDelegate = self.GUIButton_Remove.OnUnhovered, Func = self.RefreshItemOnUnhovered },
    }
   
    MsgHelper:OpDelegateList(self, self.BindNodes, true)
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.MsgList = {
        { MsgName = "SETTING_CustomKey_ConflictState",      Func = self.OnConflictState,              bCppMsg = false}, 
        { MsgName = "SETTING_CustomKey_FinishInput",        Func = self.OnFinishInput,                bCppMsg = false}, 
        { MsgName = "SETTING_CustomKey_SelectedState",      Func = self.OnSelectedState,              bCppMsg = false}, 
        { MsgName = "SETTING_CustomKey_HoverState",         Func = self.OnHoverState,                 bCppMsg = false}, 
        { MsgName = "SETTING_CustomKey_UpdateConflictInfo", Func = self.OnUpdateConflictInfo,         bCppMsg = false}, 
    }
    UserWidget.OnInit(self)
end

function SettingCustomKeyInput:OnDestroy()
    print("SettingCustomKeyInput","<<:OnDestroy")
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

function SettingCustomKeyInput:InitData(InKeySlotIndex,InCurKeys,InDefaultKeys,InTag,InIANameList,InIADes,InAnotherItemTag, bNeedApplySetting)
    print("SettingCustomKeyInput","<<:InitData",InKeySlotIndex,InDefaultKeys and InDefaultKeys:Length() or "not InDefaultKeys",InCurKeys:Length(),InTag,InIADes,InAnotherItemTag)
    self.CurKeySlotIndex = InKeySlotIndex
    if InDefaultKeys then
        self.DefaultKeys = InDefaultKeys
    end
    self.bIsHover = false
    self.CurKeys = InCurKeys and InCurKeys or self.DefaultKeys
    self.CurState = StateType.Default
    self.CurTag = UE.UKismetStringLibrary.Conv_StringToName(InTag)
    self.AnotherItemTag = InAnotherItemTag
    self.CurIANameList = InIANameList or self.CurIANameList
    self.CurIADes = InIADes

    self.ConflictFrontItemTag = ""--冲突前者对应的 tag
    self.ConflictFrontDes = ""--冲突前者对应的 功能描述
    self.ConflictFrontPreEffectiveKeys = self.NoneKeys--冲突前者对应的 上一个有效按键信息
    self.ConflictBehindItemTag = "" --冲突后者的tag
    self:RefreshItem()
    self:UpdateCustomKeyInfo(bNeedApplySetting)
end

-- 还原成默认按键
function SettingCustomKeyInput:DefaultBtnOnClicked()
    print("SettingCustomKeyInput","<<:DefaultBtnOnClicked")
    self.bIsHover = false
    self:CopyCurKeysToPreEffectiveKeys()
    self.CurKeys = self.DefaultKeys
    self:CheckConflictState(self.CurKeys)
    self:RefreshItem()
    self:UpdateCustomKeyInfo(true)
end

--清空按键配置
function SettingCustomKeyInput:RemoveBtnOnClicked()
    print("SettingCustomKeyInput","<<:RemoveBtnOnClicked")
    self:CopyCurKeysToPreEffectiveKeys()
    self.CurKeys = self.NoneKeys
    self:CheckConflictState(self.CurKeys)
    self:RefreshItem()
    self:UpdateCustomKeyInfo(true)
end

-- 接一个时机 点 Apply 或是关闭 设置界面 需要清空状态
function SettingCustomKeyInput:RevertToDefault()
    print("SettingCustomKeyInput","<<:RevertToDefault")
    self:CopyCurKeysToPreEffectiveKeys()
    self.CurKeys = self.DefaultKeys
    self.CurState = StateType.Default
    self:ResetConflictData()
    self:RefreshItem()
    self:UpdateCustomKeyInfo(false)
end

function SettingCustomKeyInput:RefreshItemOnHovered()
    print("SettingCustomKeyInput","<<:RefreshItemOnHovered")
    self.bIsHover = true
    if self.CurState ~= StateType.Conflict_Front and self.CurState ~= StateType.Conflict_Behind then
        self.CurState = StateType.Hovered
    end
    self:RefreshItem()
end

function SettingCustomKeyInput:RefreshItemOnUnhovered()
    print("SettingCustomKeyInput","<<:RefreshItemOnUnhovered",self.CurState)
    self.bIsHover = false
    -- 冲突 或 正在输入中
    if self.CurState ~= StateType.Conflict_Front and self.CurState ~= StateType.Conflict_Behind and self.CurState ~= StateType.Selected then
        self.CurState = StateType.Default
    end
    self:RefreshItem()
end

function SettingCustomKeyInput:RefreshItemOnPressed()
    print("SettingCustomKeyInput","<<:RefreshItemOnPressed")
    if self.CurState ~= StateType.Conflict_Front and self.CurState ~= StateType.Conflict_Behind then
        self.CurState = StateType.Clicked
        self:RefreshItem()
    end
    self:SetTargetVisibility(self.GUIButton_Default,true,false)
    self:SetTargetVisibility(self.GUIButton_Remove,true,false)
end

function SettingCustomKeyInput:RefreshItemOnReleased()
    print("SettingCustomKeyInput <<:RefreshItemOnReleased",self.CurState)
    if self.CurState ~= StateType.Conflict_Front and self.CurState ~= StateType.Conflict_Behind then
        self.CurState = StateType.Selected
        self:RefreshItem()
    end
    local Data = {
        Tag = self.CurTag,
        IsFromDetail = false
    }
    MsgHelper:Send(self, "SETTING_CustomKey_SelectedState", Data)
    --局外
    if not MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        local Data ={
            CurTagName = self.CurTag,
            TargetkeyCount = self.DefaultKeys:Length()>0 and self.DefaultKeys:Length() or 1,
            IsGamePad = false,
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
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,BBSStringType, tostring(self.CurTag));
    BBSStringType.SelectedKeyName = "TargetkeyCount" 
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsString(GenericBlackboard,BBSStringType, tostring(1));--当前默认是单键
    BBSStringType.SelectedKeyName = "IsGamePad" 
    UE.UGenericBlackboardBlueprintFunctionLibrary.SetValueAsBool(GenericBlackboard,BBSStringType, false)
    local TipsManager = UE.UTipsManager.GetTipsManager(self)
    TipsManager:ShowTipsUIByTipsId("Setting.CustomKeyInputing",-1,GenericBlackboard,self)
end

-- 输入按键结束后出来直接在 进入 另一个 item 的 select
function SettingCustomKeyInput:OnSelectedState(InData)
    print("SettingCustomKey", "<<:OnSelectedState Tag:", InData.Tag, self.CurTag)
    if self.CurTag == InData.Tag and InData.IsFromDetail then--Detail 跳转
        self:RefreshItem()
        return
    end
    if self.CurTag == InData.Tag or self.CurState == StateType.Default or self.CurState == StateType.Conflict_Front or self.CurState == StateType.Conflict_Behind then
        return
    end
    self.CurState = StateType.Default
    self:RefreshItem()
end

-- 输入按键结束后出来直接在 进入 另一个 item 的 hover
function SettingCustomKeyInput:OnHoverState(InData)
    print("SettingCustomKey", "<<:OnHoverState Tag:", InData.Tag, self.CurTag)
    if InData.Tags:Contains(self.CurTag) or self.CurState == StateType.Default or self.CurState == StateType.Conflict_Front or self.CurState == StateType.Conflict_Behind then
        return
    end
    self.CurState = StateType.Default
    self:RefreshItem()
end

function SettingCustomKeyInput:OnUpdateConflictInfo(InData)
    --print("SettingCustomKey", "<<:OnUpdateConflictInfo Tag:", InData.Tag, self.CurTag)
    if self.CurTag ~= InData.Tag then
        return
    end
    print("SettingCustomKey", "<<:OnUpdateConflictInfo Tag:", InData.Tag,InData.IADes)
    self.ConflictFrontPreEffectiveKeys = InData.PreEffectiveKeys
    for index = 1, InData.PreEffectiveKeys:Length() do
        local TempKey = InData.PreEffectiveKeys:GetRef(index)
        local DisplayName = UE.UKismetInputLibrary.Key_GetDisplayName(TempKey,true)
        print("SettingCustomKey","<<:OnUpdateConflictInfo TargetValue:",DisplayName)
    end
    self.ConflictFrontDes = InData.IADes
end

function SettingCustomKeyInput:OnConflictState(InData)
    --print("SettingCustomKey", "<<:OnConflictState Tag:", InData.Tag, self.CurTag)
    if self.CurTag ~= InData.Tag then
        return
    end
    print("SettingCustomKey", "<<:OnConflictState Tag:", InData.Tag,",IsClearConflict:",InData.IsClearConflict,",AnotherTag:",InData.AnotherTag,",ConflictFrontItemTag:",self.ConflictFrontItemTag)
    local IsRepateConflict = self.ConflictFrontItemTag ~= "" and self.ConflictFrontItemTag == InData.AnotherTag--两个 item 重复冲突
    if not InData.IsClearConflict and not IsRepateConflict then
        self.ConflictBehindItemTag = InData.AnotherTag
    end
    if InData.IsClearConflict then
        self.CurState = StateType.Default
        self.ConflictFrontDes = ""
        self.ConflictFrontPreEffectiveKeys = self.NoneKeys
        self:RefreshItem()
        return
    end

    if self.AnotherItemTag ~= InData.AnotherTag and not IsRepateConflict then
        local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
        SettingSubsystem:SetKeyMapConflict(self.CurTag,true)
        print("SettingSubsystem:SetKeyMapConflict set tag ",self.CurTag," true")
        self.CurState = StateType.Conflict_Front
    else
        self.CurState = StateType.Default
    end
    self:CopyCurKeysToPreEffectiveKeys()

    if self.AnotherItemTag ~= InData.AnotherTag then
        local Data = {
            Tag = InData.AnotherTag,--被冲突的 item tag
            PreEffectiveKeys = self.PreEffectiveKeys,
            IADes = self.CurIADes,
        }
        MsgHelper:Send(self, "SETTING_CustomKey_UpdateConflictInfo", Data)
    end

    self.CurKeys = self.NoneKeys
    self:RefreshItem()
    self:UpdateCustomKeyInfo(true)

end

function SettingCustomKeyInput:OnFinishInput(InData)
    --print("SettingCustomKey","<<:OnFinishInput Tag:", InData.Tag,self.CurTag,InData.TargetKeys:Length(),InData.IsClose)
    if self.CurTag ~= InData.Tag then
        return
    end
    self:SetFocus(true)
    print("SettingCustomKey","<<:OnFinishInput Tag:", InData.Tag,self.CurTag,InData.TargetKeys:Length(),InData.IsClose)
    if InData.IsClose then
        if self.CurState ~= StateType.Conflict_Front and self.CurState ~= StateType.Conflict_Behind then
            self.CurState = StateType.Default
        end
        self:RefreshItem()
        return
    end
    local PreIsConflict = false
    if self.CurState == StateType.Conflict_Front then
        PreIsConflict = true
        self.CurState = StateType.Default
    end
    if self.CurState == StateType.Conflict_Behind then
        self.CurState = StateType.Default
    end
    local bIsConflict = self:CheckConflictState(InData.TargetKeys)
    self:CopyCurKeysToPreEffectiveKeys()
    self.CurKeys = InData.TargetKeys
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if PreIsConflict then
        local Data = {
            Tag = self.ConflictBehindItemTag,
            AnotherTag = self.CurTag,
            IsClearConflict = true,
        }
        MsgHelper:Send(self, "SETTING_CustomKey_ConflictState", Data)
        SettingSubsystem:SetKeyMapConflict(self.CurTag,false)
        print("SettingSubsystem:SetKeyMapConflict set tag PreIsConflict",self.CurTag," false")
        if not bIsConflict then
            self.ConflictFrontPreEffectiveKeys = self.NoneKeys
            self.ConflictFrontDes = ""
        end
    end

    self:RefreshItem()
    self:UpdateCustomKeyInfo(false)
end

function SettingCustomKeyInput:OnFinishInputUpdateItem(InData)
    self:SetFocus(true)
    print("SettingCustomKey","<<:OnFinishInputUpdateItem ", InData.Tag,self.CurTag,InData.TargetKeys:Length(),self.CurState)
    local PreIsConflict = false
    if self.CurState == StateType.Conflict_Front then
        PreIsConflict = true
        self.CurState = StateType.Default
    end
    if self.CurState == StateType.Conflict_Behind then
        self.CurState = StateType.Default
    end
    local bIsConflict = false
    self:CopyCurKeysToPreEffectiveKeys()
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if PreIsConflict then
        local Data = {
            Tag = self.ConflictBehindItemTag,
            AnotherTag = self.CurTag,
            IsClearConflict = true,
        }
        MsgHelper:Send(self, "SETTING_CustomKey_ConflictState", Data)
        SettingSubsystem:SetKeyMapConflict(self.CurTag,false)
        print("OnFinishInputUpdateItem SettingSubsystem:SetKeyMapConflict set tag PreIsConflict",self.CurTag," false")
        if not bIsConflict then
            self.ConflictFrontPreEffectiveKeys = self.NoneKeys
            self.ConflictFrontDes = ""
        end
    end
    self:RefreshItem()
    self:UpdateCustomKeyInfo(false)
end

--检测冲突
function SettingCustomKeyInput:CheckConflictState(InTargetKeys)
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    local CurSettingData = UE.FSettingValue()
    CurSettingData.Value_IntArray = self:GetTargetValueArrayByCurKeys(InTargetKeys)
    local ConflictTagName ,bIsConflict = SettingSubsystem:IsKeyMapSettingConflict(self.CurTag,CurSettingData)
    print("SettingCustomKey","<<:CheckConflictState bIsConflict:",bIsConflict,",ConflictTagName:",ConflictTagName,",AnotherItemTag:",self.AnotherItemTag,",ConflictBehindItemTag:",self.ConflictBehindItemTag)
    if bIsConflict then--冲突
        local Data = {
            Tag = ConflictTagName,
            AnotherTag = self.CurTag,
            IsClearConflict = false,
        }
        MsgHelper:Send(self, "SETTING_CustomKey_ConflictState", Data)
        --同一行数据键位位置互换 不算冲突或者 两个item 相互冲突 第二次冲突时需要更新成默认状态
        if self.AnotherItemTag ~= ConflictTagName and self.ConflictFrontPreEffectiveKeys ~= InTargetKeys and self.ConflictBehindItemTag ~= ConflictTagName then
            self.CurState = StateType.Conflict_Behind
            self.ConflictFrontItemTag = ConflictTagName
        else
            self.CurState = StateType.Default
        end
        if self.ConflictBehindItemTag == ConflictTagName then
            self.ConflictFrontPreEffectiveKeys = self.NoneKeys
            self.ConflictFrontDes = ""    
        end
    end
    return bIsConflict
end

-- 重置 冲突相关数据
function SettingCustomKeyInput:ResetConflictData()
    self.ConflictFrontItemTag = ""
    self.ConflictFrontPreEffectiveKeys = self.NoneKeys
    self.ConflictFrontDes = ""
    self.ConflictBehindItemTag = ""
end

-- 更新当前按键
function SettingCustomKeyInput:UpdateCustomKeyInfo(bNeedApplySetting)
    print("SettingCustomKeyInput:UpdateCustomKeyInfo",bNeedApplySetting)
    -- 调 设置接口 更新数据
    if bNeedApplySetting then
        local NewSettingValue = UE.FSettingValue()
        NewSettingValue.Value_IntArray = self:GetTargetValueArrayByCurKeys(self.CurKeys)
        print("SettingCustomKeyInput:UpdateCustomKeyInfo",NewSettingValue.Value_IntArray:Length(),self.CurTag)
        local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
        SettingSubsystem:ApplySetting(self.CurTag,NewSettingValue)
      
    end
    
    -- 应用 输入数据
    self:BPFunction_AddPlayerMappedKey(self.CurKeySlotIndex == 0 and UE.EPlayerMappableKeySlot.First or UE.EPlayerMappableKeySlot.Second)
end

-- 根据当前 keys 获取对应的 映射值 array
function SettingCustomKeyInput:GetTargetValueArrayByCurKeys(InTargetKeys)
    local NeedData = UE.TArray(UE.int32)
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if not SettingSubsystem then
        return NeedData
    end
    for index = 1,InTargetKeys:Length() do
        local TempKey = InTargetKeys:GetRef(index)
        local TargetValue = SettingSubsystem.KeyIconMap:TryGetKeyMappedValueByKey(self,TempKey)
        print("SettingCustomKeyInput:GetTargetValueArrayByCurKeys",UE.UKismetInputLibrary.Key_GetDisplayName(TempKey,true),"TargetValue:",TargetValue)
        if TargetValue ~= -1 then
            NeedData:AddUnique(TargetValue)
        end
    end
    return NeedData
end

function SettingCustomKeyInput:RefreshItem()
    self:RefreshToDefaultItem()
    self:RefreshByCurState()
    print("SettingCustomKey","<<:RefreshItem CurState:", self.CurState,self:IsNoneKeys())
    if self:IsNoneKeys() then--空值
        -- if self.CurState == StateType.Selected then
        --     self:SetTargetVisibility(self.HorizontalBox_Inputing,false,false)
        -- end
    else
        self:RefreshCurKeysIcon()
        if self.CurState == StateType.Hovered then
            self:SetTargetVisibility(self.GUIButton_Remove,false,true)
            self:SetTargetVisibility(self.GUIButton_Default,self:IsDefaultKeys(),true)
        end
    end
end

function SettingCustomKeyInput:RefreshToDefaultItem()
    self.WidgetSwitcher_State:SetActiveWidgetIndex(0)
    self:SetTargetVisibility(self.GUIImage_Bg_Selected,true,false)
    self:SetTargetVisibility(self.GUIButton_Default,true,false)
    self:SetTargetVisibility(self.GUIButton_Remove,true,false)
    self:SetTargetVisibility(self.HorizontalBox_KeyIconList,true,false)
end

function SettingCustomKeyInput:RefreshByCurState()
    local TargetIndex = self.CurState
    self.WidgetSwitcher_State:SetActiveWidgetIndex(TargetIndex)
end

function SettingCustomKeyInput:RefreshCurKeysIcon()
    self:SetTargetVisibility(self.HorizontalBox_KeyIconList,false,false)
    local AllChildWidget = self.HorizontalBox_KeyIconList:GetAllChildren()
    local ChildNum = AllChildWidget:Length()
    local CurKeysNum = self.CurKeys:Length()
    print("SettingCustomKey","<<:RefreshCurKeysIcon CurState:" ,CurKeysNum)
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    if not SettingSubsystem then
        return
    end
    local function RefreshKeyIcon(InTempImage, InTargetIndex,InIndex)
        self:SetTargetVisibility(InTempImage,false,false)
        if InIndex%2 == 0 then
            local TargetIcon = SettingSubsystem.KeyIconMap:TryGetIconByKeyWithState(self,self.CurKeys:GetRef(InTargetIndex),self.CurState == StateType.Hovered and UE.EkeyStateType.Hover or UE.EkeyStateType.Default)
            if TargetIcon and TargetIcon:IsValid() then
                InTempImage.Brush = UE.UWidgetBlueprintLibrary.MakeBrushfromTexture(TargetIcon,TargetIcon:Blueprint_GetSizeX(),TargetIcon:Blueprint_GetSizeY())
                InTempImage:SetRenderScale(UE.FVector2D(1,1))
            end
        end
	end

    if CurKeysNum == 1 then
        print("SettingCustomKey","<<:RefreshCurKeysIcon CurState:")
        RefreshKeyIcon(AllChildWidget:GetRef(1),1,0)
        return
    end
    for index = 1, ChildNum do
        local TempImage = AllChildWidget:GetRef(index):Cast(UE.GUIImage)
        local TargetIndex = ((index+2)/2)-1
        local bIsValidIndex = self.CurKeys:IsValidIndex(TargetIndex)
        if TempImage and index <= CurKeysNum*2-2 and bIsValidIndex then
            RefreshKeyIcon(TempImage,TargetIndex,index)
        end
    end
end

function SettingCustomKeyInput:CopyCurKeysToPreEffectiveKeys()
    local CurKeysNum = self.CurKeys:Length()
    self.PreEffectiveKeys:Clear()
    for index = 1, CurKeysNum do
        local TempKey = self.CurKeys:Get(index)
        self.PreEffectiveKeys:Add(TempKey:Copy())
    end
end

function SettingCustomKeyInput:IsNoneKeys()
    local CurKeysNum = self.CurKeys:Length()
    for index = 1, CurKeysNum do
        local TempKey = self.CurKeys:GetRef(index)
        print("SettingCustomKey","<<:IsNoneKeys TempKey:", TempKey ~= self.NoneKey)
        if TempKey ~= self.NoneKey then
            return false
        end
    end
    return true
end

function SettingCustomKeyInput:IsDefaultKeys()
    local CurKeysNum = self.CurKeys:Length()
    local DefaultKeys = self.DefaultKeys:Length()
    if DefaultKeys ~= CurKeysNum then
        return false
    end
    
    for index = 1, CurKeysNum do
        local TempKey = self.CurKeys:GetRef(index)
        local TempDefaultKey = self.DefaultKeys:GetRef(index)
        if TempKey ~= TempDefaultKey then
            return false
        end
    end
    return true
end

function SettingCustomKeyInput:SetTargetVisibility(Target,IsHide,NeedVisibility)
    local TargetVisibility = NeedVisibility and UE.ESlateVisibility.Visible or UE.ESlateVisibility.SelfHitTestInvisible 
    TargetVisibility = IsHide and UE.ESlateVisibility.Collapsed or TargetVisibility
    if Target then
        Target:SetVisibility(TargetVisibility)
    else
        print("SettingCustomKey","<<:SetTargetVisibility Target:",Target,"is not valid")
    end
end

return SettingCustomKeyInput