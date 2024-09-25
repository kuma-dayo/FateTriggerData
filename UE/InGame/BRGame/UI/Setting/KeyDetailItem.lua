

require "UnLua"

local KeyDetailItem = Class("Common.Framework.UserWidget")
local StateType = {
	Default	        = 0,
	Hovered	        = 1,
	Clicked	        = 2,
}

function KeyDetailItem:OnInit()
    self.BindNodes ={
        { UDelegate = self.Button_FristSelected.OnClicked,        Func = self.OnFristItemClicked },
        { UDelegate = self.Button_FristSelected.OnHovered,        Func = self.OnFristItemHovered },
        { UDelegate = self.Button_FristSelected.OnUnhovered,      Func = self.OnFristItemUnhovered },

        { UDelegate = self.Button_SecondSelected.OnClicked,       Func = self.OnSecondItemClicked },
        { UDelegate = self.Button_SecondSelected.OnHovered,       Func = self.OnSecondItemHovered },
        { UDelegate = self.Button_SecondSelected.OnUnhovered,     Func = self.OnSecondItemUnhovered },
    }
   
    MsgHelper:OpDelegateList(self, self.BindNodes, true)
    UserWidget.OnInit(self)
end

function KeyDetailItem:OnDestroy()
    if self.BindNodes then
        MsgHelper:OpDelegateList(self, self.BindNodes, false)
		self.BindNodes = nil
	end
    
    UserWidget.OnDestroy(self)
end

-- 点击按钮 发消息
function KeyDetailItem:OnFristItemClicked()
    self.CurFirstState = StateType.Clicked
    local Data = {
        Tag = self.FirstKeyTag,
        IsFromDetail = true
    }
    MsgHelper:Send(self, "SETTING_CustomKey_SelectedState", Data)
end

function KeyDetailItem:OnFristItemHovered()
    self.CurFirstState = StateType.Hovered
end

function KeyDetailItem:OnFristItemUnhovered()
    self.CurFirstState = StateType.Default
end

function KeyDetailItem:OnSecondItemClicked()
    self.CurSecondState = StateType.Clicked
    local Data = {
        Tag = self.SecondKeyTag,
        IsFromDetail = true
    }
    MsgHelper:Send(self, "SETTING_CustomKey_SelectedState", Data)
end

function KeyDetailItem:OnSecondItemHovered()
    self.CurSecondState = StateType.Hovered
end

function KeyDetailItem:OnSecondItemUnhovered()
    self.CurSecondState = StateType.Default
end

function KeyDetailItem:OnInitialize(InActiviteTag,InTargetBlackboard,InIsShow)
    print("KeyDetailItem:OnInitialize")
    if not InIsShow then
        self:RefreshToDefaultStyle()
        return
    end
    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()    
    BlackBoardKeySelector.SelectedKeyName ="DefaultKeysStr"
    local DefaultKeysStr,IsFindTitle =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(InTargetBlackboard,BlackBoardKeySelector)
    
    BlackBoardKeySelector.SelectedKeyName ="CurKeysStr"
    local CurKeysStr,IsFindDetail =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(InTargetBlackboard,BlackBoardKeySelector)

    BlackBoardKeySelector.SelectedKeyName ="FirstKeyDes"
    local FirstKeyDes,IsFindFirstKeyDes =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(InTargetBlackboard,BlackBoardKeySelector)

    BlackBoardKeySelector.SelectedKeyName ="FirstKeyValue"
	local FirstKeyValue, IsFindFirstKeyDes = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(InTargetBlackboard, BlackBoardKeySelector)

    BlackBoardKeySelector.SelectedKeyName ="FirstKeyTag"
	local FirstKeyTag, IsFindFirstKeyTag = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(InTargetBlackboard, BlackBoardKeySelector)

    BlackBoardKeySelector.SelectedKeyName ="SecondKeyDes"
    local SecondKeyDes,IsFindSecondKeyDes =UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(InTargetBlackboard,BlackBoardKeySelector)

    BlackBoardKeySelector.SelectedKeyName ="SecondKeyValue"
	local SecondKeyValue, IsFindSecondKeyValue = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(InTargetBlackboard, BlackBoardKeySelector)
    
    BlackBoardKeySelector.SelectedKeyName ="SecondKeyTag"
	local SecondKeyTag, IsFindSecondKeyTag = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(InTargetBlackboard, BlackBoardKeySelector)

    print("KeyDetailItem:RefreshItemByBlackboardData DefaultKeysStr:",DefaultKeysStr,",CurKeysStr:",CurKeysStr,",FirstKeyValue:",FirstKeyValue,",SecondKeyValue:",SecondKeyValue,
    ",FirstKeyDes:",FirstKeyDes,",SecondKeyDes:",SecondKeyDes,",FirstKeyTag:",FirstKeyTag,",SecondKeyTag:",SecondKeyTag)
    self.FirstKeyTag = FirstKeyTag
    self.SecondKeyTag = SecondKeyTag
    local ConflictData = {}
    table.insert(ConflictData,{Des = FirstKeyDes, KeyValues = {tonumber(FirstKeyValue)},Tag = FirstKeyTag,})
    table.insert(ConflictData,{Des = SecondKeyDes,KeyValues = {tonumber(SecondKeyValue)},Tag = SecondKeyTag,})
    self:RefreshItem(DefaultKeysStr,CurKeysStr,ConflictData)
end

function KeyDetailItem:RefreshToDefaultStyle()
    self:RefreshItem("","",{
        {Des = "", KeyValues = {-1},Tag = "",},
        {Des = "", KeyValues = {-1},Tag = "",},
    })
end

-- 刷新样式
function KeyDetailItem:RefreshItem(InDefaultKeyStr,InCurKeyStr,InConflictData)
    self.Text_Default:SetText(InDefaultKeyStr)
    self.Text_Change:SetText(InCurKeyStr)
    local HasConflict = false
    if InConflictData[1].KeyValues[1] and InConflictData[2].KeyValues[1] then
        HasConflict = InConflictData[1].KeyValues[1] > 0  or  InConflictData[2].KeyValues[1] > 0
    end
    self:SetTargetVisibility(self.GUICanvasPanel_Conflict,not HasConflict)
    if not HasConflict then
        return
    end

    
    local function RefreshConflictItem(InWidget,InDesText,InTempConflictData)
        local IsConflict = InTempConflictData.KeyValues[1] > 0
        self:SetTargetVisibility(InWidget,not IsConflict)
        if not IsConflict then
            return
        end
        InDesText:SetText(IsConflict and InTempConflictData.Des or "")
        
        local KeyValues = InTempConflictData.KeyValues
        self:RefreshCurKeysIcon(self.HorizontalBox_FirstKeyIconList,KeyValues,self.CurFirstState)
        self:RefreshCurKeysIcon(self.HorizontalBox_SecondKeyIconList,KeyValues,self.CurSecondState)
    end
    RefreshConflictItem(self.GUICanvasPanel_FirstConflict,self.Text_FirstDes,InConflictData[1])
    RefreshConflictItem(self.GUICanvasPanel_SecondConflict,self.Text_SecondDes,InConflictData[2])
end

function KeyDetailItem:RefreshCurKeysIcon(InParentWidget,InkeyValues,InTargetState)
    local AllChildWidget = InParentWidget:GetAllChildren()
    local ChildNum = AllChildWidget:Length()
    local CurKeysNum = #InkeyValues
    print("KeyDetailItem","<<:RefreshCurKeysIcon CurKeysNum:" ,CurKeysNum)
    local function RefreshKeyIcon(InTempImage, InTargetIndex,InIndex)
        self:SetTargetVisibility(InTempImage,false)
        if InIndex%2 == 0 then
            local TargetKey = self.KeyIconMap:TryGetKeyByKeyMappedValue(InkeyValues[InTargetIndex])
            local TargetIcon = self.KeyIconMap:TryGetIconByKeyWithState(self,TargetKey,InTargetState == StateType.Hovered and UE.EkeyStateType.Hover or UE.EkeyStateType.Default)
            if TargetIcon:IsValid() then
                InTempImage.Brush = UE.UWidgetBlueprintLibrary.MakeBrushfromTexture(TargetIcon,TargetIcon:Blueprint_GetSizeX(),TargetIcon:Blueprint_GetSizeY())
                InTempImage:SetRenderScale(UE.FVector2D(1,1))
            end
        end
	end

    if CurKeysNum == 1 then
        print("KeyDetailItem","<<:RefreshCurKeysIcon CurState:")
        RefreshKeyIcon(AllChildWidget:GetRef(1),1,0)
        return      
    end
    for index = 1, ChildNum do
        local TempImage = AllChildWidget:GetRef(index):Cast(UE.GUIImage)
        local TargetIndex = ((index+2)/2)-1
        local bIsValidIndex = #InkeyValues>=TargetIndex
        if TempImage and index <= CurKeysNum*2-2 and bIsValidIndex then
            RefreshKeyIcon(TempImage,TargetIndex,index)
        end
    end
end

function KeyDetailItem:SetTargetVisibility(Target,IsHide)
    local TargetVisibility = IsHide and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible
    if Target then
        Target:SetVisibility(TargetVisibility)
    else
        print("KeyDetailItem","<<:SetTargetVisibility Target:",Target,"is not valid")
    end
end

return KeyDetailItem