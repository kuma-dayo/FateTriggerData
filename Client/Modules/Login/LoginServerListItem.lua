--[[登录服务器选择Item]]
local class_name = "LoginServerListItem"
LoginServerListItem = LoginServerListItem or BaseClass(GameMediator, class_name)

function LoginServerListItem:__init()
end

function LoginServerListItem:OnShow(InData)

end

function LoginServerListItem:OnHide()
	
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
	self.LoginModel = MvcEntry:GetModel(LoginModel)
	self.BindNodes = {
		--{ UDelegate = self.BtnClose.OnClicked,				Func = self.OnClicked_CloseView },
	}

	self.MsgList = {
		--{ Model = nil, MsgName = CommonEvent.ON_LOGIN_FINISHED, Func = self.ON_LOGIN_FINISHED_Func },
	}

end

--由mdt触发调用
function M:OnShow(data)
	
end

--[[
	重复打开此界面时，会触发此方法调用
]]
function M:OnRepeatShow(data)
	
end

--由mdt触发调用
function M:OnHide()
end

return M