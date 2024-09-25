--[[
    无好友 Item
]]
local class_name = "FriendListEmptyItem"
local FriendListEmptyItem = BaseClass(nil, class_name)

function FriendListEmptyItem:OnInit()
end

function FriendListEmptyItem:OnShow(Param)
    self:UpdateListShow()
end

function FriendListEmptyItem:OnHide()
end

function FriendListEmptyItem:UpdateListShow()
end

return FriendListEmptyItem
