--[[登录服务器选择面板]]
local class_name = "LoginServerListPanelMdt"
LoginServerListPanelMdt = LoginServerListPanelMdt or BaseClass(GameMediator, class_name)

function LoginServerListPanelMdt:__init()
end

function LoginServerListPanelMdt:OnShow(InData)

end

function LoginServerListPanelMdt:OnHide()
	
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
	self.LoginModel = MvcEntry:GetModel(LoginModel)
	self.BindNodes = {
		{ UDelegate = self.BtnClose.OnClicked,				Func = self.OnClicked_CloseView },
	}

	self.MsgList = {
		{Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnClicked_CloseView},
		{Model = LoginModel, MsgName = LoginModel.ON_SERVER_LIST_UPDATE_FINISH, Func = self.InitServerListShow},
	}
end

--由mdt触发调用
function M:OnShow(data)
	if data~=nil and data.IsPatch ~= nil and  data.IsPatch then
		self.IsPatch = data.IsPatch
	end
	self:InitServerListShow()
end

--[[
	重复打开此界面时，会触发此方法调用
]]
function M:OnRepeatShow(data)
	
end

--由mdt触发调用
function M:OnHide()
end

function M:InitServerListShow()
	CWaring("Patch  Test @huijin")
	self.ListServerItem:ClearChildren()
	local ServerList = self.LoginModel:GetServerListData()
	if self.IsPatch then
		CWaring("self.IsPatch ")
		ServerList = self.LoginModel:GetPatchListData()
	end
	if ServerList and #ServerList > 0 then
		for Index, Data in pairs(ServerList) do
			self:CreateServerItem(Data, Index)
		end
		self:SetSelectedServer(self.LoginModel:GetCurSelectIndex(), true)
	end
end

function M:CreateServerItem(InServerData, InIndex)
	local instance = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(LoginModel.Const.DefaultUMGPath))
    local SelectItem = NewObject(instance, self)
	if not SelectItem then return end
    self.ListServerItem:AddChild(SelectItem)
	self:SetItemShow(SelectItem, InServerData, InIndex)
end

function M:SetSelectedServer(SelectIndex, IsInit)
	local CurSelectIndex = self.LoginModel:GetCurSelectIndex()
	if not IsInit and SelectIndex == CurSelectIndex then
		return
	end
	local ServerList = self.LoginModel:GetServerListData()
	-- 确定这部分逻辑之后直接调用patch逻辑
	if self.IsPatch and not IsInit then
		ServerList = self.LoginModel:GetPatchListData()
		local VersionName = string.match( ServerList[SelectIndex].Name, ":(%d+%.%d+%.%d+%.%d+)")
		CLog("[huijin] Patch"..ServerList[SelectIndex].Name)
		if VersionName then
			CLog("[huijin] Patch"..VersionName)
		else
			CLog("[huijin] Patch VersionName is nil")
		end
		msg =
		{
			TargetVersion = VersionName
		}
		--TODO:: 后续会修复
		UE.UGenericPatchSubsystem.GetGenericPatchSubsystem(GameInstance):GetPatchPipeline():SetSpecialVersion(VersionName)
		MvcEntry:OpenView(ViewConst.DownloadPatchPanel,msg)
		return 
	end
	
	if not (SelectIndex and SelectIndex > 0 and SelectIndex <= #ServerList) then
		SelectIndex = 1
	end
	local ServerItem = ServerList[SelectIndex]
	if not ServerItem then
		CWaring("LoginServerListPanelMdt:SetSelectedServer ServerItem nil")
		return
	end
	self.LoginModel:SetCurSelectData(ServerList[SelectIndex])
	self.LoginModel:SetCurSelectIndex(SelectIndex)

	--取消旧
	if self.LastSelectItem then
		self:SetSelectItemShow(self.LastSelectItem, false)
	end

	--选中新
	local SelectItem = self.ListServerItem:GetChildAt(SelectIndex - 1)
	if SelectItem ~= nil then
		self:SetSelectItemShow(SelectItem, true)
	end
	self.LastSelectItem = SelectItem
end

function M:SetItemShow(InSelectItem, InServerData, InIndex)
	local BtnSelect = InSelectItem.BtnServerSelect
	local ImgServerStatus = InSelectItem.ImgServerStatus --待后台字段产出
	local TxtServerName = InSelectItem.TxtServerName
	local TxtServerDelay = InSelectItem.TxtServerDelay --待后台字段产出
	self:SetSelectItemShow(InSelectItem, false)
	TxtServerName:SetText(InServerData.Name)

	BtnSelect.OnClicked:Clear()
	BtnSelect.OnClicked:Add(self, function ()
		self:SetSelectedServer(InIndex)
	end)

	BtnSelect.OnHovered:Clear()
	BtnSelect.OnHovered:Add(self, function ()
		self:SetItemColorShow(InSelectItem, true)
	end)
	BtnSelect.OnUnHovered:Clear()
	BtnSelect.OnUnHovered:Add(self, function ()
		self:SetItemColorShow(InSelectItem, InIndex == self.LoginModel:GetCurSelectIndex())
	end)
	BtnSelect.OnPressed:Clear()
	BtnSelect.OnPressed:Add(self, function ()
		self:SetItemColorShow(InSelectItem, true)
	end)
end

function M:SetSelectItemShow(InItem, InIsShowSelect)
	InItem.ImgSelect:SetVisibility(InIsShowSelect and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
	InItem.ImgNormal:SetVisibility(not InIsShowSelect and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)
	self:SetItemColorShow(InItem, InIsShowSelect)
end

--设置Item的文字和Icon色
function M:SetItemColorShow(InItem, InIsShowSelect)
	local SlateColor = UE.FSlateColor()
	local ImgColor = UIHelper.LinearColor.White
	if InIsShowSelect then
		SlateColor.SpecifiedColor = UIHelper.LinearColor.Black
		ImgColor = UIHelper.LinearColor.Black
	else
		SlateColor.SpecifiedColor = UIHelper.LinearColor.White
	end
	InItem.TxtServerName:SetColorAndOpacity(SlateColor)
	InItem.ImgServerStatus:SetColorAndOpacity(ImgColor)
end

function M:OnClicked_CloseView()
	self.LoginModel:DispatchType(LoginModel.SHOWSERVER_SELECTED)
	MvcEntry:CloseView(ViewConst.LoginServerListPanel)
end

return M