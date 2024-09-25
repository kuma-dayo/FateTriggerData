local class_name = "LevelLoginMdt";
---@class LevelLoginMdt : GameMediator
LevelLoginMdt = LevelLoginMdt or BaseClass(GameMediator, class_name);


function LevelLoginMdt:__init()
end

function LevelLoginMdt:OnShow(data)
	CLog("-----OnShow")
end

function LevelLoginMdt:OnHide()
	CLog("-----OnHide")
end

-------------------------------------------------------------------------------------
---@class LevelLoginMdt_C
local M = Class()


---@private
function M:OnShow(data)
	CLog("LevelLoginMdt==========ReceiveBeginPlay2")
	
	--打开登录界面
	MvcEntry:OpenView(ViewConst.LoginPanel)
end

function M:OnRepeatShow(data)
	MvcEntry:CloseView(ViewConst.NameInputPanel)
end

function M:ReceiveEndPlay(EndPlayReason)
	self.Overridden.ReceiveEndPlay(self,EndPlayReason)	
end

return M
