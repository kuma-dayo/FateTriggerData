local ReplyStateWidget = Class("Common.Framework.UserWidget")
function ReplyStateWidget:ToNextStatus()
    if self.CurrentStyle == 0 then
        if self.CurrentFriendName and #self.CurrentFriendName > 0 then
            self:ToFriendStyle()
        else
            self:ToTeamStyle()
        end
    elseif self.CurrentStyle == 1 then
        self:ToTeamStyle()
    elseif self.CurrentStyle == 2 then
        self:ToNearStyle()
    end
end
function ReplyStateWidget:ToNearStyle()
    self.CurrentStyle = 0
    -- self.FriendName:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.FriendName:SetText(self.NearText)
    self.WidgetSwitcher_State:SetActiveWidgetIndex(0)
end
function ReplyStateWidget:ToFriendStyle()
    self.CurrentStyle = 1
    self.FriendName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.WidgetSwitcher_State:SetActiveWidgetIndex(1)
    self.FriendName:SetText(self.CurrentFriendName)
end
function ReplyStateWidget:ToTeamStyle()
    self.CurrentStyle = 2
    -- self.FriendName:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.FriendName:SetText(self.TeamText)
    self.WidgetSwitcher_State:SetActiveWidgetIndex(2)
end
function ReplyStateWidget:SetReplayFreindName(InFriendName)
    self.CurrentFriendName = InFriendName
    self.FriendName:SetText("@"..self.CurrentFriendName)
end
function ReplyStateWidget:GetIngameMessageChannel()
    if self.CurrentStyle == 0 then
        return 4
    elseif self.CurrentStyle == 1 then
        return 2
    elseif self.CurrentStyle == 2 then
        return 1
    end
    return 0
end

return ReplyStateWidget