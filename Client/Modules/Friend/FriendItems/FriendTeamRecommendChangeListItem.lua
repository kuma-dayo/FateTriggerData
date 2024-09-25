--[[
    组队推荐-换一批 Item
]]
local class_name = "FriendTeamRecommendChangeListItem"
local FriendTeamRecommendChangeListItem = BaseClass(nil, class_name)

function FriendTeamRecommendChangeListItem:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.GUIButton_Change.OnClicked,				Func = Bind(self,self.OnClick_GUIButton_Change) },
	}
end

function FriendTeamRecommendChangeListItem:OnShow(Param)
end

function FriendTeamRecommendChangeListItem:OnHide()
end

function FriendTeamRecommendChangeListItem:OnClick_GUIButton_Change()
    MvcEntry:GetCtrl(RecommendCtrl):ReqRecommendTeammateList()
end

return FriendTeamRecommendChangeListItem
