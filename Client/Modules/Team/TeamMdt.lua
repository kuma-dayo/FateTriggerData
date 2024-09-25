--[[
    组队界面
]]
local class_name = "TeamMdt"
TeamMdt = TeamMdt or BaseClass(GameMediator, class_name)

function TeamMdt:__init()
end

function TeamMdt:OnShow(data)
	
end

function TeamMdt:OnHide()

end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
	self.BindNodes = 
	{
		{ UDelegate = self.GUIButton_Team.OnClicked,				Func = self.OnClicked_GUIButton_Team },
		{ UDelegate = self.GUIButton_Close.OnClicked,				Func = self.OnClicked_GUIButton_Close },
		
	}
end

--由mdt触发调用
function M:OnShow(data)

end

function M:OnHide()

end

function M:OnClicked_GUIButton_Team()
	
end


function M:OnClicked_GUIButton_Close()
	MvcEntry:CloseView(ViewConst.Team)
end




return M