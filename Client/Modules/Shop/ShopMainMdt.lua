
--- 视图控制器
local class_name = "ShopMainMdt";
ShopMainMdt = ShopMainMdt or BaseClass(GameMediator, class_name);

function ShopMainMdt:__init()
end

function ShopMainMdt:OnShow(data)
    
end

function ShopMainMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    -- self.MsgList = 
    -- {
	-- 	{Model = ShopModel, MsgName = ListModel.ON_UPDATED, Func = self.OnShopUpdate},
    -- }

    -- self.BindNodes = 
    -- {
	-- 	{ UDelegate = self.GUIButton_Back.OnClicked,				    Func = self.GUIButton_Close_ClickFunc },
	-- }

    self.Model = MvcEntry:GetModel(ShopModel)
   
end

function M:OnHide()
    
end

function M:OnShow(Params)
end

return M
