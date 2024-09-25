--[[
	购买贴纸
]]


local class_name = "VehicleSkinStickerBuyMdt";
VehicleSkinStickerBuyMdt = VehicleSkinStickerBuyMdt or BaseClass(GameMediator, class_name);

function VehicleSkinStickerBuyMdt:__init()
end

function VehicleSkinStickerBuyMdt:OnShow(data)
end

function VehicleSkinStickerBuyMdt:OnHide()

end


local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
	self.BindNodes = 
    {
		--{ UDelegate = self.Button_BGClose.OnClicked,				Func = self.OnButton_BGCloseClicked },
	}

	self.MsgList = 
    {
		{Model = VehicleModel, MsgName = VehicleModel.ON_BUY_VEHICLE_SKIN_STICKER_LIST, Func = self.ON_BUY_VEHICLE_SKIN_STICKER_LIST},
	}
	self.TheVehicleModel = MvcEntry:GetModel(VehicleModel)
	self.TheArsenalModel = MvcEntry:GetModel(ArsenalModel)
	self.BuyMax = 10
	self.BuyNum = 1
end

--由mdt触发调用
function M:OnShow(data)
	self.StickerId = data.StickerId or 0
	self.StickerBuyFrom = data.StickerBuyFrom or 0

	local StickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker, self.StickerId)
	local UMGPath = '/Game/BluePrints/UMG/OutsideGame/Arsenal/Vehicle/WBP_VehicleSkinSticker_Buy_Content.WBP_VehicleSkinSticker_Buy_Content'
    local ContentWidgetCls = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(UMGPath))
    self.ContentWidget = NewObject(ContentWidgetCls, self)

	-- 设置通用背景部分
    local PopUpBgParam = {
        TitleText = self.TheArsenalModel:GetArsenalText(10046),
        ContentWidget = self.ContentWidget,
        BtnList = {
            [1] = {
                BtnParam = {
                    OnItemClick = Bind(self,self.OnClicked_CancelBtn),
                    TipStr = self.TheArsenalModel:GetArsenalText(10030),
                    CommonTipsID = CommonConst.CT_ESC,
                    ActionMappingKey = ActionMappings.Escape,
                    HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
                },
                IsWeak = true
            },
            [2] = {
                BtnParam = {
                    OnItemClick = Bind(self,self.OnClicked_ConfirmButton),
                    CurrencyId = StickerCfg and StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemId] or 0,
					CurrencyStr = StickerCfg and StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemNum] * self.BuyNum or 0,
                    CommonTipsID = CommonConst.CT_SPACE,
                    ActionMappingKey = ActionMappings.SpaceBar,
                    HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
                },
            }
        },
        CloseCb = Bind(self,self.OnClicked_CancelBtn)
    }
    self.CommonPopUpBgLogicCls = UIHandler.New(self,self.WBP_CommonPopUp_Bg,CommonPopUpBgLogic,PopUpBgParam).ViewInstance

	---内容
	local Param = {
		StickerId = self.StickerId,
		BuyMax = self.BuyMax,
		BuyNum = self.BuyNum
	}
	self.CommonPopUpBgLogicContentCls = UIHandler.New(self, self.ContentWidget, 
		require("Client.Modules.Arsenal.Vehicle.VehicleSkinStickerBuyContent"), Param).ViewInstance
end

function M:UpdateStickerBuyInfo(BuyStickerNum)
	local StickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker, self.StickerId)
    if StickerCfg == nil then
        return
    end
	local ConfirmBtn = self.CommonPopUpBgLogicCls:GetBtnHandler(2)
	if ConfirmBtn == nil then
		return
	end
	self.BuyNum = BuyStickerNum
	local Param = {
		OnItemClick = Bind(self,self.OnClicked_ConfirmButton),
		CommonTipsID = CommonConst.CT_SPACE,
		CurrencyId = StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemId],
		CurrencyStr = StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemNum] * BuyStickerNum ,
		HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
	}
	ConfirmBtn:UpdateItemInfo(Param)
end

function M:OnHide()

end


function M:OnClicked_CancelBtn()
	MvcEntry:CloseView(self.viewId)
end


function M:OnClicked_ConfirmButton()
	local StickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker, self.StickerId)
    if StickerCfg == nil then 
		return
	end
	local UnlockItemId = StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemId]
	local ItemName = MvcEntry:GetModel(DepotModel):GetItemName(UnlockItemId)
    local Cost = StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemNum] * self.BuyNum
	local Balance = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(UnlockItemId)
	if Balance < Cost then
		local msgParam = {
			describe = StringUtil.Format(self.TheArsenalModel:GetArsenalText(10014),ItemName)
		}
		UIMessageBox.Show(msgParam)
		return
	end
	local msgParam = {
		describe = StringUtil.Format(self.TheArsenalModel:GetArsenalText(10015), Cost,ItemName),
		leftBtnInfo = {},
		rightBtnInfo = {
			callback = function()
				local StickerIdList = {}
				table.insert(StickerIdList, 
				{
					StickerId = self.StickerId,
					BuyCount = self.BuyNum
				})
				MvcEntry:GetCtrl(ArsenalCtrl):SendProto_BuyVehicleStickerReq(StickerIdList, self.StickerBuyFrom)
			end
		}
	}
	UIMessageBox.Show(msgParam)
end


function M:ON_BUY_VEHICLE_SKIN_STICKER_LIST(Param)
	if Param == nil then
		return
	end
	if Param.StickerInfoList == nil or #Param.StickerInfoList == 0 then
		return
	end
	MvcEntry:CloseView(self.viewId)
	UIAlert.Show(self.TheArsenalModel:GetArsenalText(10047))
end


return M