require "UnLua"

local SettingListItem = Class("Common.Framework.UserWidget")

function SettingListItem:OnInit()
    self.MsgListGMP = nil
    self.MsgListGMP = 
    {
        { MsgName = "Setting.ListItem.Change",            Func = self.OnActivateIndexChange,      bCppMsg = false },
    }
    MsgHelper:RegisterList(self, self.MsgListGMP)
    UserWidget.OnInit(self)
end

function SettingListItem:OnDestroy()
   if self.MsgListGMP then
    MsgHelper:UnregisterList(self, self.MsgListGMP)
   end
	
    UserWidget.OnDestroy(self)
end


function SettingListItem:SetHoverStyle()
   
    UE.UGTSoundStatics.PostAkEvent(self, self.HoverSound)
    
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.TextBlock_Title:SetColorAndOpacity(self.TextHoverColor)
    self.GUIImage_Bg_List:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.SettingComboBox.TextBlock_Content:SetColorAndOpacity(self.TextHoverColor)
    
    
    self.SettingComboBox.WidgetSwitcher:SetActiveWidgetIndex(1)
    --通知detail更新
     local data =
    {
        InTag = self.ParentTag,
        IsShowTableDetailWidget = false,
        InBlackboard = UE.FGenericBlackboardContainer()
    }
    MsgHelper:Send(self, "UIEvent.ChangeDetailContent",data)
end


function SettingListItem:SetNormalStyle()
    
    self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TextBlock_Title:SetColorAndOpacity(self.TextOriginalColor)
    self.SettingComboBox.TextBlock_Content:SetColorAndOpacity(self.TextOriginalColor)
    self.GUIImage_Bg_List:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.SettingComboBox.WidgetSwitcher:SetActiveWidgetIndex(0)
    
end


-- 鼠标按键移入
function SettingListItem:OnMouseEnter(InMyGeometry, InMouseEvent)
    
    self:SetHoverStyle()
    --通知detail更新
   
end


-- 鼠标按键移出
function SettingListItem:OnMouseLeave(InMouseEvent)
    
	self:SetNormalStyle()
end


function SettingListItem:RefreshShowingItem(InWidget,InIndex)
    --print("SettingListItem:RefreshShowingItem",InIndex,self.ListData:GetRef(InIndex+1).ShowText)
    
    InWidget:BP_InitData(InIndex,self.ListData[InIndex+1],self.ParentTag.TagName)
   
end



function SettingListItem:OnActivateIndexChange(InComboBoxItemData)
    print("SettingListItem:OnActivateIndexChange",InComboBoxItemData.Index,InComboBoxItemData.TagName)
    if InComboBoxItemData.TagName == self.ParentTag.TagName then
        self.ActivateIndex = InComboBoxItemData.Index
        self:ChangeShowText()
        self.SettingComboBox:OnClickedEvent()
    end
end

function SettingListItem:ChangeShowText()
    print("SettingListItem:ChangeShowText",self.ActivateIndex,self.ListData:Length())
    self.SettingComboBox.TextBlock_Content:SetText(self.ListData[self.ActivateIndex+1].ShowText)
    for k,v in pairs(self.ListData) do
        if k == self.ActivateIndex+1 then
            v.Value = true
        else
            v.Value = false
        end
        local ComboBoxItemData =
    {
        Index = k-1,
        TagName = self.ParentTag.TagName,
        Value = v.Value
    }
    MsgHelper:Send(self, "Setting.ListItem.ChangeVlaue",ComboBoxItemData)
    end

    local NewSettingValue = UE.FSettingValue()
    NewSettingValue.Value_Int = self.ActivateIndex
    local SettingSubsystem = UE.UGenericSettingSubsystem.Get(self)
    SettingSubsystem:ApplySetting(self.ParentTag.TagName,NewSettingValue)
end


function SettingListItem:RefreshItemContent(ItemContent)
    print("SettingListItem:RefreshItemContent DefaultValue",ItemContent.DefaultValue,self.ParentTag.TagName)
    if ItemContent.DefaultValue <0 then
        return
    end
    self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    --需要刷新的话，数组的数量一定不能小于0
    --如果数组的值等于0，代表只需要刷新默认值
    if ItemContent.TextArray:Num()>0 then
        self.ListData:Clear()
    else
        if ItemContent == UE.FSettingItemReturnValue() then
            return 
        end
       
    end
    self.ActivateIndex = ItemContent.DefaultValue
    local TmpValue = UE.FSettingListItemData()
    for k,v in pairs(ItemContent.TextArray) do
        TmpValue.ShowText = v
        if k == self.ActivateIndex+1 then
            TmpValue.Value = true 
        else
            TmpValue.Value = false
        end
        self.ListData:Add(TmpValue)
    end
   self.SettingComboBox.ComboboxContent:Reload(self.ListData:Length())
    self:ChangeShowText()
    
    
end

function SettingListItem:OnFocusReceived(MyGeometry,InFocusEvent)
    self:SetHoverStyle()
    -- self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- self.GUIImage_Bg_List:SetVisibility(UE.ESlateVisibility.Collapsed)
    return UE.UWidgetBlueprintLibrary.Handled()
end

function SettingListItem:OnFocusLost(InFocusEvent)
    self:SetNormalStyle()
    -- self.IM_BG_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
    -- self.GUIImage_Bg_List:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end


return SettingListItem
