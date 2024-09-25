
--- 视图控制器
local class_name = "AchievementMainMdt";
AchievementMainMdt = AchievementMainMdt or BaseClass(GameMediator, class_name);

function AchievementMainMdt:__init()
    self:ConfigViewId(ViewConst.AchievementMain)
end

function AchievementMainMdt:OnShow(data)
    
end

function AchievementMainMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    -- self.MsgList = 
    -- {
	-- 	{Model = AchievementModel, MsgName = ListModel.ON_UPDATED, Func = self.OnAchievementUpdate},
    -- }

    -- self.BindNodes = 
    -- {
	-- 	{ UDelegate = self.GUIButton_Back.OnClicked,				    Func = self.GUIButton_Close_ClickFunc },
	-- }

    self.Model = MvcEntry:GetModel(AchievementModel)
   
end

function M:OnHide()
    
end

function M:OnShow(Params)
end

return M
