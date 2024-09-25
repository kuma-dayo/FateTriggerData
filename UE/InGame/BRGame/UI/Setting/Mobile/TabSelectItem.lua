local TabSelectItem = Class("Common.Framework.UserWidget")

function TabSelectItem:OnInit()
    self.Button.OnClicked:Add(self, self.OnClickedSelect)

    UserWidget.OnInit(self)
end

function TabSelectItem:OnClickedSelect()
   self.WidgetSwitcher:SetActiveWidgetIndex(1)
   local data = {
        ButtonTxt = self.Text,
        Index = self.LayerId,
        Brush = self.Image_Select,
        IsFromInit = false
   }
   MsgHelper:Send(self, "UIEvent.ChangeActiveTabSelectItem",data)
end



return TabSelectItem