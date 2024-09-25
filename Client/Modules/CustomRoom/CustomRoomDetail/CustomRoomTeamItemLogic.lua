--[[
    房间列表Item逻辑
]]
local class_name = "CustomRoomTeamItemLogic"
local CustomRoomTeamItemLogic = BaseClass(nil, class_name)


function CustomRoomTeamItemLogic:OnInit()
    self.TheCustomRommModel = MvcEntry:GetModel(CustomRoomModel)

    self.BindNodes = {
        {UDelegate = self.View.WBP_ReuseList.OnUpdateItem, Func = Bind(self, self.OnUpdateTeamMemberItem)},
	}
    self.Widget2Item = {}
    ---列表不响应鼠标滚轮事件
    self.View.WBP_ReuseList.ScrollBoxList:SetConsumeMouseWheel(UE.EConsumeMouseWheel.Never)
    -- self.View.WBP_ReuseList.OnUpdateItem:Add(self.View, Bind(self,self.OnUpdateTeamMemberItem))
end
function CustomRoomTeamItemLogic:OnShow(Param)
end

--[[
    local Param = {
        TeamId = TeamId,
        TeamInfo = TeamInfo,
        TeamType = TeamType,
    }
]]
function CustomRoomTeamItemLogic:SetData(Param)
    if not Param then
        return
    end
    self.TeamId = Param.TeamId
    self.TeamInfo = Param.TeamInfo
    self.TeamType = Param.TeamType
    self.Param = Param

    -- if self.TeamInfo then
    --     print_r(self.TeamInfo,"===============")
    -- end

    self.View.WBP_ReuseList:Reload(self.TeamType)


    if self.TeamType ~= 1 and self.View["Text_TeamName"] then
        self.View["Text_TeamName"]:SetText(self.TeamId .. "")
    end
end

function CustomRoomTeamItemLogic:OnHide()
end

function CustomRoomTeamItemLogic:UpdateShow()

end


function CustomRoomTeamItemLogic:OnUpdateTeamMemberItem(Handler,Widget, Index)
    local Pos = Index + 1
	local MemberInfo = self.TeamInfo and self.TeamInfo[Pos]

	local TargetItem = self:CreateItem(Widget)
	if TargetItem == nil then
		return
	end
    local param = {
        TeamId = self.TeamId,
        MemberInfo = MemberInfo,
        Pos = Pos,
        TeamType = self.TeamType,
    }
	TargetItem:SetData(param)
end
function CustomRoomTeamItemLogic:CreateItem(Widget)
	local Item = self.Widget2Item[Widget]
	if not Item then
		Item = UIHandler.New(self,Widget,require("Client.Modules.CustomRoom.CustomRoomDetail.CustomRoomTeamMemberLogic"))
		self.Widget2Item[Widget] = Item
	end
	return Item.ViewInstance
end


return CustomRoomTeamItemLogic
