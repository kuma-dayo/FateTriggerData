local SettingLayoutControlWidget = Class("Common.Framework.UserWidget")

function SettingLayoutControlWidget:OnInit()
    self.IsCanMove = false
    UserWidget.OnInit(self)
end

function SettingLayoutControlWidget:OnShow(data)
    self.IsCanMove = false
end

function SettingLayoutControlWidget:OnTouchStarted(InMyGeometry, InTouchEvent)
   
    if self:HasActiveWidgetStyleFlags(5) then
        self.IsCanMove = true

    end
    return UE.FEventReply()
end



return SettingLayoutControlWidget