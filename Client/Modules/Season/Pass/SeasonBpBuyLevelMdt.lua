--[[    
    赛季行证等级购买界面
]] 
local class_name = "SeasonBpBuyLevelMdt"

SeasonBpBuyLevelMdt = SeasonBpBuyLevelMdt or BaseClass(GameMediator, class_name)

function SeasonBpBuyLevelMdt:__init()
end

function SeasonBpBuyLevelMdt:OnShow(data)
end

function SeasonBpBuyLevelMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.TheModel = MvcEntry:GetModel(SeasonBpModel)
    self.TheDepotModel = MvcEntry:GetModel(DepotModel)
    self.TheShopModel = MvcEntry:GetModel(ShopModel)
    self.BindNodes = {
        { UDelegate = self.WBP_ReuseList.OnUpdateItem,				Func = self.OnUpdateItem },
    }

    local PopUpBgParam = {
		HideCloseTip = true,
        CloseCb = Bind(self, self.OnEscClick),
	}
    self.CommonPopUp_BgIns = UIHandler.New(self, self.WBP_CommonPopUp_Bg_L, CommonPopUpBgLogic, PopUpBgParam).ViewInstance
    self.SliderCls = UIHandler.New(self, self.WBP_CommonEditableSlider, CommonEditableSlider).ViewInstance
    self.Widget2Handler = {}
end

--[[
    {
        SeasonBpId = 0,
    }
]]
function M:OnShow(Param)
    if not Param or not Param.SeasonBpId then
        CError("SeasonBpBuyLevelMdt Param Invalid!")
        return
    end
    self.SeasonBpId = Param.SeasonBpId
    self.BpCfg = G_ConfigHelper:GetSingleItemById(Cfg_SeasonBpCfg,self.SeasonBpId)
    local PassStatus = self.TheModel:GetPassStatus()
    self.CurLevel = PassStatus.Level
    self.AddLevel = 0
    self.MaxLevel = self.TheModel:GetBpLevelMax()

    self.AddLevel2ItemList = nil
    self.AddLevel2AllItemList =  {}

    
    self:CalculatePreCache()

    local Param = {
        ValueChangeCallBack = Bind(self, self.ValueChangeCallBack),
        MaxValue = self.MaxLevel - PassStatus.Level,
        DefaultValue = 1,
    }
    self.SliderCls:UpdateItemInfo(Param)
end

function M:OnHide()
end

function M:OnUpdateItem(Widget,Index)
    CWaring("Index:" .. Index)
    local Index = Index + 1
    local ItemInfo = self.NeedShowItems[Index]
    if not ItemInfo then
        CWaring("SeasonBpBuyLevelMdt:OnUpdateItem ItemInfo Error; Index = "..tostring(Index))
        return
    end

    if not self.Widget2Handler[Widget] then
        self.Widget2Handler[Widget] =  UIHandler.New(self,Widget,CommonItemIcon)
    end

    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemInfo.ItemId,
        ItemNum = ItemInfo.ItemNum,
        ClickFuncType = CommonItemIcon.CLICK_FUNC_TYPE.TIP,
        ShowCount = true,
    }
    self.Widget2Handler[Widget].ViewInstance:UpdateUI(IconParam)
end

function M:CalculatePreCache()
    if not self.AddLevel2ItemList then
        self.AddLevel2ItemList = {}
        local BeginLevel = self.CurLevel + 1
        for i=BeginLevel,self.MaxLevel do
            -- ConfigHelper:
            -- G_ConfigHelper:GetDict
            local RewardCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_SeasonBpRewardCfg,{Cfg_SeasonBpRewardCfg_P.SeasonBpId,Cfg_SeasonBpRewardCfg_P.Level},{self.SeasonBpId,i})
            local DropItemList = self.TheModel:GetDropItemListByBpReward(RewardCfg)--self.TheDepotModel:GetItemListForDropId(RewardCfg[Cfg_SeasonBpRewardCfg_P.DropId])
            if #DropItemList > 0 then
                self.AddLevel2ItemList[i] = DropItemList
            end
        end
    end
end
function M:GetAddLevel2AllItem(AddLevel)
    self:CalculatePreCache()
    if not self.AddLevel2AllItemList[AddLevel] then
        self.AddLevel2AllItemList[AddLevel] = {}
        local BeginLevel = self.CurLevel
        for i=1,AddLevel do
            local NeedShowLevel = BeginLevel + i
            local ItemInfoList = self.AddLevel2ItemList[NeedShowLevel]
            ListMerge(self.AddLevel2AllItemList[AddLevel],ItemInfoList)
        end
    end
    return self.AddLevel2AllItemList[AddLevel]
end

function M:ValueChangeCallBack(CurValue)
    CWaring("ValueChangeCallBack========:" .. CurValue)
    if self.AddLevel == CurValue then
        return
    end
    self.AddLevel = CurValue

    self.NeedShowItems = self:GetAddLevel2AllItem(self.AddLevel)
    -- print_r(self.NeedShowItems)
    self.WBP_ReuseList:Reload(#self.NeedShowItems)

    local GoodsId = self.BpCfg[Cfg_SeasonBpCfg_P.LevelGoodsId]
    local GoodCount = self.AddLevel
    local Goods = self.TheShopModel:GetData(GoodsId)
    -- local ItemName = self.DepotModel:GetItemName(Goods.CurrencyType)
    -- local Balance = self.DepotModel:GetItemCountByItemId(Goods.CurrencyType)
    
    -- ---@type ReferenceUnitPrice
    -- local PriceBook = self.TheShopModel:GetGoodsUnitPrice(GoodsId)
    -- local UnitPrice = PriceBook.SettlementPrice
    -- local Cost = UnitPrice * GoodCount

    ---@type SettlementSum
    local SettlementSum = MvcEntry:GetCtrl(ShopCtrl):GetGoodsPrice(GoodsId, GoodCount)
    local Cost = SettlementSum.TotalSettlementPrice

    --按钮参数
    local BtnParamLeft = {
        OnItemClick = Bind(self,self.OnEscClick),
        CommonTipsID = CommonConst.CT_F,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        TipStr = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("102")),
        ActionMappingKey = ActionMappings.F
    }
    --需要计算购买等级的商品ID及售价，未做
    ---@type CommonPriceParam
    local CommonPriceParam = {
        CurrencyType = Goods.CurrencyType,
        Price = Cost,
    }
    local BtnParamRight = {
        OnItemClick = Bind(self,self.OnSureClick),
        CommonTipsID = CommonConst.CT_SPACE,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        TipStr = "",
        ActionMappingKey = ActionMappings.SpaceBar,
        ShowStyleType 		= WCommonBtnTips.ShowStyleType.Price,
        CommonPriceParam    = CommonPriceParam,
    }

    local BtnList = {
        [1]={IsWeak = true, BtnParam = BtnParamLeft},
        [2]={IsWeak = false, BtnParam = BtnParamRight},
    }
    self.CommonPopUp_BgIns:UpdateBtnList(BtnList)
    self.CommonPopUp_BgIns:UpdateTitleText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Season","BuyLevelDes"),self.AddLevel))
end

function M:OnEscClick()
    MvcEntry:CloseView(self.viewId)
end

--[[
    确认点击回调
]]
function M:OnSureClick()
    local GoodsId = self.BpCfg[Cfg_SeasonBpCfg_P.LevelGoodsId]
    local GoodCount = self.AddLevel
    if not MvcEntry:GetCtrl(ShopCtrl):CheckCanBuyGoods(GoodsId, GoodCount, true) then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop","GoodNotFound"))
        return false
    end

    local Goods = self.TheShopModel:GetData(GoodsId)
    local ItemName = self.TheDepotModel:GetItemName(Goods.CurrencyType)
    local Balance = self.TheDepotModel:GetItemCountByItemId(Goods.CurrencyType)

    -- ---@type ReferenceUnitPrice
    -- local PriceBook = self.TheShopModel:GetGoodsUnitPrice(GoodsId)
    -- local UnitPrice = PriceBook.SettlementPrice
    -- local Cost = UnitPrice * GoodCount

    ---@type SettlementSum
    local SettlementSum = MvcEntry:GetCtrl(ShopCtrl):GetGoodsPrice(GoodsId, GoodCount)
    local Cost = SettlementSum.TotalSettlementPrice

    if Balance < Cost then
        local msgParam = {
            describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Insufficientcurrency"), ItemName),
            -- leftBtnInfo = {},
            -- rightBtnInfo = {
            --     callback = function()
            --         --TODO 跳往充值界面
            --         MvcEntry:GetCtrl(ViewJumpCtrl):JumpTo(JumpCode.ChargeCurrencyBuy.JumpId)
            --     end
            -- }
        }
        UIMessageBox.Show(msgParam)
        return
    end
    MvcEntry:GetCtrl(ShopCtrl):SendPlayerBuyGoodReq(GoodsId, GoodCount,true)
    self:OnEscClick()
end



return M
