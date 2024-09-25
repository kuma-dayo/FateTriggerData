require("Client.Modules.DownloadPatch.ChoicePatchPanelModel")

local class_name = "ChoicePatchPanelMdt";
ChoicePatchPanelMdt = ChoicePatchPanelMdt or BaseClass(GameMediator, class_name);

function ChoicePatchPanelMdt:__init()
end

function ChoicePatchPanelMdt:OnShow(data)
	CLog("-----OnShow")
	
end

function ChoicePatchPanelMdt:OnHide()
	CLog("-----OnHide")
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

--由mdt触发调用
function M:OnShow(data)
	CLog("-----Choice Patch ")
	self:SetAllButtonVersion()
	self:DownloadAllPackageVersion()
end

function M:OnInit()
	CLog(">>>>>>>>>>>>>>>>>>")
end

function M:OnHide()

end

-- 设置当前UI基础状态
function M:InitState()

end

function M:ClearState()

end

function M:CalPercentage(Current,Total)

end

function M:CreateDownloadProcessText()

end

function M:CreateMergeProcessText()

end

--开始下载流程
function M:StartDownloadPatch()

end

function M:DelayEnterLogin()
	
end

function M:EnterLogin()
	
end

function M:DownloadAllPackageVersion()
end

function M:SetAllButtonVersion()
	self.BindNodes = {}
	local AllVersion = UE.UGenericPatchLib.GetAllChangelist()
	local ChildrenCount = self.WrapBox_0:GetChildrenCount()
	for i=1, ChildrenCount  do
		if AllVersion:Num() < i then
			self.WrapBox_0:GetChildAt(i-1):GetChildAt(0):GetChildAt(0):SetText("None")
		else
			local Changelist = AllVersion[i]
			self.WrapBox_0:GetChildAt(i-1):GetChildAt(0):GetChildAt(0):SetText(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ChoicePatchPanelMdt_Updateto")..Changelist)
			self.WrapBox_0:GetChildAt(i-1):GetChildAt(0).OnClicked:Add(self, function()
				self:Btn_Input_DownloadPackage(Changelist)
			end)
		end
	end
end

function M:Btn_Input_DownloadPackage(Changelist)
	MvcEntry:CloseView(ViewConst.ChoicePatchPanel)
	local NotUpdate = function()
		MvcEntry:OpenView(ViewConst.VirtualLogin)
		MvcEntry:CloseView(ViewConst.ChoicePatchPanel)
	end
	local UpDateGame = function()
		MvcEntry:OpenView(ViewConst.DownloadPatchPanel)
		MvcEntry:CloseView(ViewConst.ChoicePatchPanel)
	end
	
	local msgParam = {
		describe = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ChoicePatchPanelMdt_ClicktoupdatetotheCh")..Changelist),
		leftBtnInfo = {
			name = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ChoicePatchPanelMdt_Stillnotupdated")),
			callback =  NotUpdate
		},
		rightBtnInfo = {
			name = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ChoicePatchPanelMdt_Confirmupdate")),
			callback =  UpDateGame
		},
	}
	UIMessageBox.Show(msgParam)
end

function M:Btn_Input_GetVersions()

end

return M