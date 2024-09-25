--[[
    登录成功顶部提示
]]

local class_name = "LoginTipStartGameMdt";
LoginTipStartGameMdt = LoginTipStartGameMdt or BaseClass(GameMediator, class_name);

function LoginTipStartGameMdt:__init()
end

function LoginTipStartGameMdt:OnShow(data)
end

function LoginTipStartGameMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.BindNodes = 
    {
	
	}
end

--[[
    Param = {
    }
]]
function M:OnShow(Param)
   self.Text_Account:SetText(StringUtil.Format("{0},欢迎进入游戏！",MvcEntry:GetModel(LoginModel):GetStartGameTipShowId()))

   self:Event_FadeOut()
end

function M:OnRepeatShow(Param)
    
end

function M:OnHide()
   
end

function M:OnFadeOutFinished()
    MvcEntry:CloseView(self.viewId)
end



return M
