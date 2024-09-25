require "UnLua"

local SettingItemOptionButton = Class("Common.Framework.UserWidget")

function SettingItemOptionButton:OnInit()
    print("SettingItemOptionButton:OnInit")
    if BridgeHelper.IsMobilePlatform() then self.BP_Text_Title.ParentTag = self.ParentTag end
    UserWidget.OnInit(self)
end

function SettingItemOptionButton:OnDestroy()
	--MsgHelper:UnregisterList(self, self.MsgListGMP)
    UserWidget.OnDestroy(self)
end

function SettingItemOptionButton:OnShow(data)
end

function SettingItemOptionButton:OnClose(bDestroy)
    --MsgHelper:UnregisterList(self, self.MsgListGMP)
end


function SettingItemOptionButton:RefreshActivateIndex(Index)
    print("SettingItemOptionButton:ActivateIndex",Index,self.ParentTag.TagName)
    self.ActivateIndex = Index
    local count = 0
    if self.ItemHorizontalBox then count = self.ItemHorizontalBox:GetChildrenCount()-1 end
    if self.HorBox_Contain then count = self.HorBox_Contain:GetChildrenCount()-1 end
    for i=0, count do
        local ChildWidget = nil
        if self.ItemHorizontalBox then ChildWidget = self.ItemHorizontalBox:GetChildAt(i) end
        if self.HorBox_Contain then ChildWidget = self.HorBox_Contain:GetChildAt(i) end
        if Index == i then
            ChildWidget:ChangeBusy(true)
        else
            ChildWidget:ChangeBusy(false)
        end
        
    end
    local NewSettingValue = UE.FSettingValue()
    NewSettingValue.Value_Int = Index
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    SettingSubsystem:ApplySetting(self.ParentTag.TagName,NewSettingValue)
end

function SettingItemOptionButton:ResetOptionButtonData(Index)
    --print("SettingItemOptionButton:ResetOptionButtonData",Index)
    local ChildWidget = nil
    if self.ItemHorizontalBox then ChildWidget = self.ItemHorizontalBox:GetChildAt(Index) end
    if self.HorBox_Contain then ChildWidget = self.HorBox_Contain:GetChildAt(Index) end
    if self.ActivateIndex == Index then
        ChildWidget:ChangeBusy(true)
    else
        ChildWidget:ChangeBusy(false)
    end
end

-- 鼠标按键移入
function SettingItemOptionButton:OnMouseEnter(InMyGeometry, InMouseEvent)
    if BridgeHelper.IsPCPlatform() then self:SetHoverStyle() end
end


-- 鼠标按键移出
function SettingItemOptionButton:OnMouseLeave(InMouseEvent)
	if BridgeHelper.IsPCPlatform() then self:SetNormalStyle() end
end

function SettingItemOptionButton:SetHoverStyle()
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.TextBlock_Title:SetColorAndOpacity(self.TextHoverColor)
    self.GUIImage_Bg_List:SetVisibility(UE.ESlateVisibility.Collapsed) 
    UE.UGTSoundStatics.PostAkEvent(self, self.HoverSound)
     --通知detail更新
   
    local data =
    {
        InTag = self.ParentTag,
        
        IsShowTableDetailWidget = false,
        InBlackboard = UE.FGenericBlackboardContainer()
    }
    MsgHelper:Send(self, "UIEvent.ChangeDetailContent",data)
end

function SettingItemOptionButton:SetNormalStyle()
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TextBlock_Title:SetColorAndOpacity(self.TextOriginalColor)
    self.GUIImage_Bg_List:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end


function SettingItemOptionButton:RefreshItemContent(ItemContent)
    print("SettingItemOptionButton:RefreshItemContent DefaultValue",ItemContent.DefaultValue,self.ParentTag.TagName,ItemContent.TextArray:Num())
    if ItemContent.DefaultValue <0 then
        return
    end
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    
    --需要刷新的话，数组的数量一定不能小于0
    --如果数组的值等于0，代表只需要刷新默认值
    if ItemContent.TextArray:Num()>0 then
        if self.ItemHorizontalBox then self.ItemHorizontalBox:ClearChildren() end
        if self.HorBox_Contain then self.HorBox_Contain:ClearChildren() end
    else
        if ItemContent == UE.FSettingItemReturnValue() then
            return 
        end
        self:RefreshActivateIndex(ItemContent.DefaultValue)
    end
    self.ActivateIndex = ItemContent.DefaultValue
    
    local ChildWidget = nil
    for k,v in pairs(ItemContent.TextArray) do
       
        ChildWidget =  UE.UGUIUserWidget.Create(self.LocalPC, self.OptionButtonClass, self.LocalPC)
        ChildWidget.Index = k-1
        if self.ItemHorizontalBox then self.ItemHorizontalBox:AddChild(ChildWidget) end
        if self.HorBox_Contain then self.HorBox_Contain:AddChild(ChildWidget) end
        --local Slot = UE.UWidgetLayoutLibrary:SlotAsHorizontalBoxSlot(ChildWidget)
        ChildWidget.Slot:SetSize(UE.FSlateChildSize())
        local optiondata = UE.FSettingOptionButtonData()
        optiondata.ShowText = v
        if ChildWidget.Index == ItemContent.DefaultValue then
            optiondata.Value = true
        else
            optiondata.Value = false
        end
        ChildWidget.OptionButtonData = optiondata
        ChildWidget:OnInitialize(ChildWidget.OptionButtonData,UE.ESettingDataType.RadioButton)
        self.NewBindNodes ={
            { UDelegate = ChildWidget.NotifyRdioButtonBusy, Func = self.RefreshActivateIndex }
        }
        MsgHelper:OpDelegateList(self, self.NewBindNodes, true)
    end
    
end

function SettingItemOptionButton:OnFocusReceived(MyGeometry,InFocusEvent)
    
    if BridgeHelper.IsPCPlatform() then self:SetHoverStyle() end
   
    return UE.UWidgetBlueprintLibrary.Handled()
end

function SettingItemOptionButton:OnFocusLost(InFocusEvent)
     if BridgeHelper.IsPCPlatform() then self:SetNormalStyle() end
    
end

return SettingItemOptionButton