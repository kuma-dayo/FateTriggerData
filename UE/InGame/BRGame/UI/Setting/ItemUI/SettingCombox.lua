require "UnLua"

local SettingCombox = Class("Common.Framework.UserWidget")

function SettingCombox:OnInit()
    self.ButtonCombobox.OnHovered:Add(self, Bind(self,self.OnHovered))
    self.ButtonCombobox.OnUnHovered:Add(self, Bind(self,self.OnUnHovered))
    self.ButtonCombobox.OnClicked:Add(self, Bind(self,self.OnClicked))
    self.ComboBoxMask.OnFocusLosted:Add(self,Bind(self,self.OnLostFocus))
    --self.ComboBoxMask.OnClicked:Add(self,Bind(self,self.OnClickedEvent))
    self.IsOpen = false
    -- self.MsgListGMP = nil
    -- self.MsgListGMP = 
    -- {
    --     { MsgName = "Setting.ListItem.HoverList",            Func = self.OnHoveredList,      bCppMsg = false },
    -- }
    -- MsgHelper:RegisterList(self, self.MsgListGMP)
    self.WidgetSwitcher:SetActiveWidgetIndex(0)
    self.IsFromClick = true
    UserWidget.OnInit(self)

end

function SettingCombox:OnDestroy()
   
	
    UserWidget.OnDestroy(self)
end


function SettingCombox:OnHovered()
    
    self.WidgetSwitcher:SetActiveWidgetIndex(2)
    self.TextBlock_Content:SetColorAndOpacity(self.TextHoverColor)
end

function SettingCombox:OnHoveredList()
  
    self.WidgetSwitcher:SetActiveWidgetIndex(1)
    self.TextBlock_Content:SetColorAndOpacity(self.TextHoverColor)
end


function SettingCombox:OnUnHovered()
    self.WidgetSwitcher:SetActiveWidgetIndex(0)
    self.TextBlock_Content:SetColorAndOpacity(self.TextUnHoverColor)
end

function SettingCombox:OnClickedEvent(IsFromClick)
    print("SettingCombox:OnClickedEvent IsFromClick",IsFromClick)
--    if self.IsFromClick == false and IsFromClick == true and self.IsOpen == false then
--         self.IsFromClick = IsFromClick
--         return
--    end
    self.TextBlock_Content:SetColorAndOpacity(self.TextHoverColor)
    if self.IsOpen == false then
        self.WidgetSwitcher:SetActiveWidgetIndex(3)
        self.LIstRoot:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.IsOpen =true
        self.ComboBoxMask:SetFocus()
    else
        self.LIstRoot:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.IsOpen =false
    end
    self.IsFromClick = IsFromClick
    print("SettingCombox:OnClickedEvent",self.IsOpen)
end

function SettingCombox:OnClicked()
    self:OnClickedEvent(true)
end

function SettingCombox:OnLostFocus()
    print("SettingCombox:OnLostFocus")
    self.LIstRoot:SetVisibility(UE.ESlateVisibility.Collapsed)
    --self.IsOpen =false
    self:OnUnHovered()
end


return SettingCombox
