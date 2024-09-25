--[[
    载具车牌摇号界面
]]


local class_name = "VehiclePlateLotteryMdt";
VehiclePlateLotteryMdt = VehiclePlateLotteryMdt or BaseClass(GameMediator, class_name);

require("Client.Modules.Arsenal.Vehicle.VehicleDetailItem")

function VehiclePlateLotteryMdt:__init()
end

function VehiclePlateLotteryMdt:OnShow(data)
end

function VehiclePlateLotteryMdt:OnHide()

end

VehiclePlateLotteryMdt.Stage = 
{
	READY = 1,
	DOING = 2,
	FINISHED = 3
} 
-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")


function M:OnInit()
	self.BindNodes = 
    {
		--{ UDelegate = self.Button_BGClose.OnClicked,				Func = self.OnButton_BGCloseClicked },
	}

	self.MsgList = 
    {
		{Model = VehicleModel, MsgName = VehicleModel.ON_LICENSEPLATE_LOTTERY_RESULT,	Func =  Bind(self, self.OnLicensePlateLotteryResult) },
		{Model = VehicleModel, MsgName = VehicleModel.ON_LICENSEPLATE_SELECT,	Func =  Bind(self, self.OnLicensePlateSelect) },
		
	}
	self.TheVehicleModel = MvcEntry:GetModel(VehicleModel)
	self.TheArsenalModel = MvcEntry:GetModel(ArsenalModel)
end

--由mdt触发调用
function M:OnShow(data)
	self.VehicleId = data.VehicleId or 0

	self:UpdateCommonPopUp_Bg()

	---内容
	local Param = {VehicleId = self.VehicleId}
	if self.LotteryContentInst == nil or not(self.LotteryContentInst:IsValid()) then
		self.LotteryContentInst = UIHandler.New(self, self.WBP_VehiclePlate_Content, require("Client.Modules.Arsenal.Vehicle.VehiclePlateLotteryContent"),Param).ViewInstance
	else
		self.LotteryContentInst:ManualOpen(Param)
	end

	self:UpdateLotteryStage(VehiclePlateLotteryMdt.Stage.READY)
end

function M:UpdateCommonPopUp_Bg()

	local TitleText = self.TheArsenalModel:GetArsenalText(10024)

	local PopUpBgParam = {
		TitleText = self.TheArsenalModel:GetArsenalText(10024),
		HideCloseTip = true,
	}
	if self.CommonPopUp_BgIns == nil or not(self.CommonPopUp_BgIns:IsValid()) then
		self.CommonPopUp_BgIns = UIHandler.New(self,self.WBP_CommonPopUp_Bg_L, CommonPopUpBgLogic, PopUpBgParam).ViewInstance
	end

	-----title >>
	if CommonUtil.IsValid(self.TextBlock_Subtitle) then
		--您当前的车牌号：B728141
		self.TextBlock_Subtitle:SetText(StringUtil.Format(self.TheArsenalModel:GetArsenalText(10031), self.TheVehicleModel:GetVehicleLicensePlate(self.VehicleId)))
	end
	self.CommonPopUp_BgIns:UpdateTitleText(TitleText)	
	-----title <<
	
	-----btn >>
	--左边
	local BtnParam_L = {
		OnItemClick = Bind(self,self.OnClicked_CancelBtn),
		CommonTipsID = CommonConst.CT_BACK,
		TipStr = self.TheArsenalModel:GetArsenalText(10030),
		ActionMappingKey = ActionMappings.Escape,
		HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.None,
	}

	--中间
	local BtnParam_C = {
		OnItemClick = Bind(self, self.OnClicked_MiddleButton),
		CommonTipsID = CommonConst.CT_ENTER,
		TipStr = self.TheArsenalModel:GetArsenalText(10033),
		ActionMappingKey = ActionMappings.Enter,
		HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.None,
	}

	--右边
	local LotteryCount = self.TheVehicleModel:GetVehicleLotteryCount(self.VehicleId)
	local BtnParam_R = nil 
	if LotteryCount == 0 then
		--首次免费
		BtnParam_R = {
			OnItemClick = Bind(self,self.OnClicked_ConfirmButton),
			CommonTipsID = CommonConst.CT_SPACE,
			TipStr = self.TheArsenalModel:GetArsenalText(10029),
			ActionMappingKey = ActionMappings.SpaceBar,
			HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.None,
		}
	else
		--收费
		BtnParam_R = {
			OnItemClick = Bind(self,self.OnClicked_ConfirmButton),
			CommonTipsID = CommonConst.CT_SPACE,
			CurrencyId = CommonUtil.GetParameterConfig(ParameterConfig.VehicleLicenseItemId, 0),
			CurrencyStr = CommonUtil.GetParameterConfig(ParameterConfig.VehicleLicenseItemNum, 0),
			ActionMappingKey = ActionMappings.SpaceBar,
			HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.None,
		}
	end

	local BtnList = {
        [1]={IsWeak = true, BtnParam = BtnParam_L, OnCreateBtnCallFunc = Bind(self, self.OnCreateBtn)},
		[2]={IsWeak = true, BtnParam = BtnParam_C, OnCreateBtnCallFunc = Bind(self, self.OnCreateBtn)},
		[3]={IsWeak = true, BtnParam = BtnParam_R, OnCreateBtnCallFunc = Bind(self, self.OnCreateBtn)},
    }
    self.CommonPopUp_BgIns:UpdateBtnList(BtnList)
	-----btn <<
end

---@param Param {Index = Index, BtnWidget = BtnWidget, BtnCls = BtnCls}
function M:OnCreateBtn(Param)
	if Param == nil then
		return
	end
	if Param.Index == 1 then
		self.CanelButtonInst = Param.BtnCls
		self.WCommonBtn_Cancel = Param.BtnWidget
	elseif Param.Index == 2 then
		self.MiddleButtonInst = Param.BtnCls
		self.WCommonBtn_Middle = Param.BtnWidget
	elseif Param.Index == 3 then
		self.ConfirmButtonInst = Param.BtnCls
		self.WCommonBtn_Confirm = Param.BtnWidget
	end
end

function M:UpdateLotteryButton()
	if self.ConfirmButtonInst == nil then
		return
	end
	local Param = {
		OnItemClick = Bind(self,self.OnClicked_ConfirmButton),
		CommonTipsID = CommonConst.CT_SPACE,
		CurrencyId = CommonUtil.GetParameterConfig(ParameterConfig.VehicleLicenseItemId, 0),
		CurrencyStr = CommonUtil.GetParameterConfig(ParameterConfig.VehicleLicenseItemNum, 0),
		HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
	}
	self.ConfirmButtonInst:UpdateItemInfo(Param)
end

function M:OnClicked_CancelBtn()
	if self.LotteryStage == VehiclePlateLotteryMdt.Stage.READY then
		MvcEntry:CloseView(self.viewId)
	elseif self.LotteryStage == VehiclePlateLotteryMdt.Stage.DOING then
		return
	elseif self.LotteryStage == VehiclePlateLotteryMdt.Stage.FINISHED then
		local msgParam = {
			describe = self.TheArsenalModel:GetArsenalText(10026),
			leftBtnInfo = {
				name = self.TheArsenalModel:GetArsenalText(10027),  
			},
			rightBtnInfo = {
				name = self.TheArsenalModel:GetArsenalText(10028),                                                  
				callback = function()
					MvcEntry:CloseView(self.viewId)
				end
			}
		}
		UIMessageBox.Show(msgParam)
	end
end

function M:OnClicked_MiddleButton()
	if self.LotteryContentInst == nil 
		or  not self.LotteryContentInst.CurLicensePlate  then
			local msgParam = {
				describe = StringUtil.Format(self.TheArsenalModel:GetArsenalText(10035)),
			}
			UIMessageBox.Show(msgParam)
		return
	end
	MvcEntry:GetCtrl(ArsenalCtrl):SendProto_VehicleSelectLicensePlateReq(self.VehicleId, self.LotteryContentInst.CurLicensePlate)
end


function M:OnClicked_ConfirmButton()
	if self.LotteryStage == VehiclePlateLotteryMdt.Stage.DOING then
		return
	end
	local LotteryCount = self.TheVehicleModel:GetVehicleLotteryCount(self.VehicleId)
	if LotteryCount > 0 then
		local ItemId = CommonUtil.GetParameterConfig(ParameterConfig.VehicleLicenseItemId, 0)
		local Cost = CommonUtil.GetParameterConfig(ParameterConfig.VehicleLicenseItemNum, 0)
		local ItemName = MvcEntry:GetModel(DepotModel):GetItemName(ItemId)
		local Balance = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ItemId)
		if Balance < Cost then
			local msgParam = {
				describe = StringUtil.Format(self.TheArsenalModel:GetArsenalText(10034),ItemName)
			}
			UIMessageBox.Show(msgParam)
			return
		end
	end
	self:UpdateLotteryStage(VehiclePlateLotteryMdt.Stage.DOING)
	MvcEntry:GetCtrl(ArsenalCtrl):SendProto_RandomVehicleLicensePlateReq(self.VehicleId)
end

function M:OnLicensePlateLotteryResult(_, LicensePlateList)
	if LicensePlateList and #LicensePlateList > 0 then
		self.LotteryTimer = Timer.InsertTimer(5, function ()
			self:UpdateLotteryStage(VehiclePlateLotteryMdt.Stage.FINISHED, LicensePlateList)
			self:UpdateLotteryButton()	
		end)
	else
		self:UpdateLotteryStage(VehiclePlateLotteryMdt.Stage.READY)
	end
end

function M:OnLicensePlateSelect(_, LicensePlate)
	local msgParam = {
		describe = StringUtil.Format(self.TheArsenalModel:GetArsenalText(10031), LicensePlate),
		rightBtnInfo = {                                              
			callback = function()
				MvcEntry:CloseView(self.viewId)
			end
		}
	}
	UIMessageBox.Show(msgParam)
end


function M:UpdateLotteryStage(Stage, LicensePlateList)
	if self.LotteryStage == Stage then
		return
	end
	self.LotteryStage = Stage

	if self.LotteryContentInst  ~= nil then
		if self.LotteryStage == VehiclePlateLotteryMdt.Stage.READY then
			self.LotteryContentInst:SetReady()
		elseif self.LotteryStage == VehiclePlateLotteryMdt.Stage.DOING  then
			self.CanelButtonInst:SetBtnEnabled(false)
			self.ConfirmButtonInst:SetBtnEnabled(false)
			self.LotteryContentInst:SetDoing()
		else
			self.CanelButtonInst:SetBtnEnabled(true)
			self.ConfirmButtonInst:SetBtnEnabled(true)
			self.LotteryContentInst:SetFinished(LicensePlateList)
		end
	end

	local IsFinishedStage = self.LotteryStage == VehiclePlateLotteryMdt.Stage.FINISHED
	local Visible = IsFinishedStage and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed
	local Title = self.TheArsenalModel:GetArsenalText(IsFinishedStage and 10025 or 10024)
	self.WCommonBtn_Middle:SetVisibility(Visible)

	if self.CommonPopUp_BgIns and self.CommonPopUp_BgIns:IsValid() then
		self.CommonPopUp_BgIns:UpdateTitleText(Title)
	end
end


function M:OnHide()
end


return M