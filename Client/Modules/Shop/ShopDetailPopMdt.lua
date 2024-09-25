--- 视图控制器
local class_name = "ShopDetailPopMdt"
ShopDetailPopMdt = ShopDetailPopMdt or BaseClass(GameMediator, class_name)

function ShopDetailPopMdt:__init()
end

function ShopDetailPopMdt:OnShow(data)
end

function ShopDetailPopMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self:ResetData()

    self.MsgList =
    {
        {Model = ShopModel, MsgName = ShopModel.ON_GOODS_BUYTIMES_CHANGE, Func = Bind(self, self.OnGoodsBuytimesChange)},
    }

    self.BindNodes = {

    }

    ---@type ShopModel
    self.Model = MvcEntry:GetModel(ShopModel)

    -- 通用货币栏
    if self.CommonCurrencyListIns == nil or not(self.CommonCurrencyListIns:IsValid()) then
        self.CommonCurrencyListIns = UIHandler.New(self, self.WBP_CommonCurrency, CommonCurrencyList, {ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND}).ViewInstance
    end

    -- 商城合规功能
    self:ShowShopCompliant()
end

--- 商城合规功能
function M:ShowShopCompliant()
    if ShopDefine.OPEN_ShopCompliant then
        UIHandler.New(self, self.WBP_ShopCompliant, require("Client.Modules.Shop.ShopCompliant"))
        self.WBP_ShopCompliant:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.WBP_ShopCompliant:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function M:ResetData()
    ---@type GoodsItem
    self.GoodsInfo = nil
    self.BuyNum = 1
end

function M:OnCloseClicked()
    MvcEntry:CloseView(ViewConst.ShopDetailPop)
end

--- 显示
---@param InParams {Goods:GoodsItem,bInTheShop:boolen}
function M:OnShow(InParams)
    if not InParams then
        return
    end
    local bInTheShop = InParams.bInTheShop or false
    self.GoodsInfo = InParams.Goods

    self:ShowWBP_CommonPopUp_Bg_L()

    self:ShowBtns()
    self:ShowWBP_Shop_Item()
    self:ReqEventTracking(EventTrackingModel.SHOP_ACTION.CLICK_ENTER_TO_CONTENT, self.GoodsInfo.GoodsId, 0, EventTrackingModel.SHOP_BUY_TYPE.NOT_BUY)
end

function M:OnHide()
    self:ResetData()
end

---------------------------------------CommonPopUp_Bg_L >>

function M:ShowWBP_CommonPopUp_Bg_L()
    local Quality = 1
    local ItemId = self.GoodsInfo.ItemId
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
    if ItemCfg then
        Quality = ItemCfg[Cfg_ItemConfig_P.Quality]
    end

    -- local UMGPath = '/Game/BluePrints/UMG/OutsideGame/Shop/Detail/WBP_Shop_Item.WBP_Shop_Item'
    -- local ContentWidgetCls = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(UMGPath))
    -- self.ContentWidget_Shop_Item = NewObject(ContentWidgetCls, self)

    local PopUpBgParam = {
		TitleText = self.GoodsInfo.Name,
        Quality = Quality,
        -- ContentWidget = self.WBP_Shop_Item,
		-- HideCloseTip = true,
        CloseCb = Bind(self, self.OnCloseClicked),
	}

	if self.CommonPopUp_BgIns == nil or not(self.CommonPopUp_BgIns:IsValid()) then
		self.CommonPopUp_BgIns = UIHandler.New(self, self.WBP_CommonPopUp_Bg_L, CommonPopUpBgLogic, PopUpBgParam).ViewInstance
        -- self.CommonPopUp_BgIns:UpdateBtnList(BtnList)
    else
        self.CommonPopUp_BgIns:ManualOpen(PopUpBgParam)
	end
end

-- ---@param Param {Index = Index, BtnWidget = BtnWidget, BtnCls = BtnCls}
-- function M:OnCreateBtn(Param)
-- 	if Param == nil then
-- 		return
-- 	end
-- 	if Param.Index == 1 then
-- 		self.BuyButtonIns = Param.BtnCls
-- 	end
-- end

function M:ShowBtns()
    --按钮参数-取消
    local CancelBtnParam =  {
        OnItemClick = Bind(self, self.OnCloseClicked),
        CommonTipsID = CommonConst.CT_ESC,
        -- TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_buy"),--购买
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_UIMessageBoxLogic_cancel_Btn"),--取消
        bHideTipStr = false,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.Escape
    }
    if self.CancelBtnIns == nil or not(self.CancelBtnIns:IsValid()) then
        self.CancelBtnIns = UIHandler.New(self, self.WCommonBtn_Cancel, WCommonBtnTips, CancelBtnParam).ViewInstance    
    end
    
    --按钮参数-确定购买
    self:UpdateConfirmBtn()
end

function M:OnBuyClick()
    -- print_r(self.GoodsInfo.GoodsId, "xxxxxxxxxx=")
    -- CError("self.BuyNum =" .. self.BuyNum)
    MvcEntry:GetCtrl(ShopCtrl):RequestBuyShopItem(self.GoodsInfo.GoodsId, self.BuyNum, true)
    self:ReqEventTracking(EventTrackingModel.SHOP_ACTION.CLICK_BUY, self.GoodsInfo.GoodsId, 1, EventTrackingModel.SHOP_BUY_TYPE.BUY_SINGLE)
end

function M:GetPriceInfo(buyNum)
    buyNum = buyNum or 1
    ---@type SettlementSum
    local SettlementSum = MvcEntry:GetCtrl(ShopCtrl):GetGoodsPrice(self.GoodsInfo.GoodsId, buyNum)
    -- local Price = SettlementSum.TotalSettlementPrice
    -- local OriginPrice = SettlementSum.TotalSuggestedPrice

    local ExtShowPriceStr, ExtShowPriceStrColor = ShopCtrl:ConvertState2String(self.GoodsInfo.GoodsState)
    ---@type CommonPriceParam
    local CommonPriceParam = {
        CurrencyType = self.GoodsInfo.CurrencyType,
        SettlementSum = SettlementSum,
        FreeStyle = CommonPrice.FreeStyle.Default,
        -- Price = Price,
        -- OriginPrice = OriginPrice,
        ExtShowPriceStr = ExtShowPriceStr,
        ExtShowPriceStrColor = ExtShowPriceStrColor,
        GoodsState = self.GoodsInfo.GoodsState
    }

    return SettlementSum, CommonPriceParam
end

---更新确定按钮
function M:UpdateConfirmBtn()
    local _,CommonPriceParam = self:GetPriceInfo(self.BuyNum)
    --按钮参数-确定购买
    local BtnParam = {
        OnItemClick = Bind(self, self.OnBuyClick),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        CommonPriceParam = CommonPriceParam
    }

    local bCanBuyGoods = MvcEntry:GetCtrl(ShopCtrl):CheckCanBuyGoods(self.GoodsInfo.GoodsId, self.BuyNum)
    if bCanBuyGoods then
        BtnParam.ShowStyleType = WCommonBtnTips.ShowStyleType.Price
        BtnParam.CommonTipsID = CommonConst.CT_SPACE
        BtnParam.ActionMappingKey = ActionMappings.SpaceBar
        BtnParam.TipStr = ""
        BtnParam.bHideTipStr = true
    else
        BtnParam.ShowStyleType = WCommonBtnTips.ShowStyleType.None
        BtnParam.CommonTipsID = nil
        BtnParam.ActionMappingKey = nil
        BtnParam.TipStr = CommonPriceParam.ExtShowPriceStr --StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Alreadyowned")) --"已拥有"
        BtnParam.bHideTipStr = false
    end

    if self.BuyButtonIns == nil or not(self.BuyButtonIns:IsValid()) then
        self.BuyButtonIns = UIHandler.New(self, self.WCommonBtn_Confirm, WCommonBtnTips, BtnParam).ViewInstance
    else
        self.BuyButtonIns:UpdateItemInfo(BtnParam)
    end
    if bCanBuyGoods then
        self.BuyButtonIns:SetBtnEnabled(true)
    else
        self.BuyButtonIns:SetBtnEnabled(false)
    end

    -- 更新货币栏
    if self.CommonCurrencyListIns then
        if self.GoodsInfo.CurrencyType == ShopDefine.CurrencyType.SUPPLY_COUPON then
            self.CommonCurrencyListIns:UpdateShowByParam({ShopDefine.CurrencyType.SUPPLY_COUPON, ShopDefine.CurrencyType.DIAMOND})
        else
            self.CommonCurrencyListIns:UpdateShowByParam({ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND})
        end
    end
end

function M:UpdateBtnPirce(BuyNum)
    if self.BuyButtonIns and self.BuyButtonIns:IsValid() then
        local SettlementSum, CommonPriceParam = self:GetPriceInfo(BuyNum)
        self.BuyButtonIns:UpdatePriceShow(CommonPriceParam)
    end
end


---------------------------------------CommonPopUp_Bg_L <<

---------------------------------------WBP_Shop_Item >>

function M:ShowWBP_Shop_Item()
    local Param = {
        GoodsInfo = self.GoodsInfo,
        OnBuyNumChanage = Bind(self, self.OnBuyNumChanage)
    }

    if self.WBPShopItemIns == nil or not(self.WBPShopItemIns:IsValid()) then
        self.WBPShopItemIns = UIHandler.New(self, self.WBP_Shop_Item, require("Client.Modules.Shop.ShopDetailPopItem"), Param)
    else
        self.WBPShopItemIns:ManualOpen(Param)
    end
end

function M:OnBuyNumChanage(Param)
    self.BuyNum = Param.BuyNum

    self:UpdateBtnPirce(self.BuyNum)
end

---------------------------------------WBP_Shop_Item <<

function M:OnGoodsBuytimesChange()
    self:OnCloseClicked()
end

--浏览/购买埋点
function M:ReqEventTracking(InAction, IngoodId, InIsShowInDetail, InBuyType)
    local eventTrackingData = {
        action = InAction,--EventTrackingModel.SHOP_ACTION.CLICK_BUY,
        product_id = IngoodId,
        belong_product_id = 0,
        isShowInDetail = InIsShowInDetail,
        product_index = MvcEntry:GetModel(EventTrackingModel):GetItemIndexFromShopItemsIdTemp(IngoodId),
        buy_type = InBuyType--EventTrackingModel.SHOP_BUY_TYPE.BUY_SINGLE
    }

    MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SHOP_EVENTTRACKING_CLICK, eventTrackingData)
end

return M
