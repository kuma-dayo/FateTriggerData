

require "UnLua"

local SettingComboBoxItem = Class("Common.Framework.UserWidget")

function SettingComboBoxItem:OnInit()
    self.ButtonClickItem.OnHovered:Add(self, Bind(self,self.OnHovered))
    self.ButtonClickItem.OnUnHovered:Add(self, Bind(self,self.OnUnHovered))
    self.ButtonClickItem.OnClicked:Add(self, Bind(self,self.OnClicked))
    self.MsgListGMP = nil
    self.MsgListGMP = 
    {
        { MsgName = "Setting.ListItem.ChangeVlaue",            Func = self.OnActivateIndexChange,      bCppMsg = false },
    }
    MsgHelper:RegisterList(self, self.MsgListGMP)
    UserWidget.OnInit(self)

end

function SettingComboBoxItem:OnDestroy()
   
    if self.MsgListGMP then
        MsgHelper:UnregisterList(self, self.MsgListGMP)
       end
    UserWidget.OnDestroy(self)
end


function SettingComboBoxItem:OnHovered()
    self.GUIImage:SetBrushTintColor(self.TextHoverColor)
    self.WidgetSwitcher:SetActiveWidgetIndex(1)
    self.TextBlock_Content:SetColorAndOpacity(self.TextHoverColor)
end


function SettingComboBoxItem:OnUnHovered()
    self.WidgetSwitcher:SetActiveWidgetIndex(0)
    
    self:CheckIsSelected()
end

function SettingComboBoxItem:OnClicked()
    self.WidgetSwitcher:SetActiveWidgetIndex(2)
    self.GUIImage:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.GUIImage:SetBrushTintColor(self.TextHoverColor)
    self.TextBlock_Content:SetColorAndOpacity(self.TextHoverColor)
    self.IsSelected =true
    local ComboBoxItemData =
    {
        Index = self.Index,
        TagName = self.MyParentTagName
    }
    MsgHelper:Send(self, "Setting.ListItem.Change",ComboBoxItemData)
    --print("SettingComboBoxItem:OnClicked",self.MyParentTagName,self.Index)
end


function SettingComboBoxItem:BP_InitData(InIndex,Indata,MyParentTagName)
    self.Index = InIndex
    self.IsSelected = Indata.Value
    self.TextBlock_Content:SetText(Indata.ShowText)
    self.MyParentTagName = MyParentTagName
    self:CheckIsSelected()
    --print("SettingComboBoxItem:BP_InitData",self.MyParentTagName)
end

function SettingComboBoxItem:CheckIsSelected()
    if self.IsSelected == true then
        self.GUIImage:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.GUIImage:SetBrushTintColor(self.TextSelectColor)
        self.TextBlock_Content:SetColorAndOpacity(self.TextSelectColor)
    else
        self.TextBlock_Content:SetColorAndOpacity(self.TextOriginalColor)
        self.GUIImage:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function SettingComboBoxItem:OnActivateIndexChange(InComboBoxItemData)
    if InComboBoxItemData.TagName == self.MyParentTagName then
        if InComboBoxItemData.Index == self.Index then
            self.IsSelected = InComboBoxItemData.Value
            self:CheckIsSelected()
            --print("SettingComboBoxItem:OnActivateIndexChange",self.MyParentTagName,InComboBoxItemData.Index,InComboBoxItemData.Value)
        end
    end
    
end

return SettingComboBoxItem
