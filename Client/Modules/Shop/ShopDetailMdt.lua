--- 视图控制器
local class_name = "ShopDetailMdt"
ShopDetailMdt = ShopDetailMdt or BaseClass(GameMediator, class_name)

function ShopDetailMdt:__init()
end

function ShopDetailMdt:OnShow(data)
end

function ShopDetailMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

---3D效果展示
M.Type2ShowText = {
    [2] = "HERO",
    [3] = "WEAPON",
}

---@type GoodsItem
M.GoodsInfo = nil

function M:OnInit()
    self.ShowAvatarGoodsId = nil
    self:ResetData()

    ---@type ShopModel
    self.ModelShop = MvcEntry:GetModel(ShopModel)

    self.SequenceTag = "ShopDetailMdt_" .. tostring(self.viewId)

    self.MsgList = {
        {Model = ShopModel, MsgName = ShopModel.ON_GOODS_BUYTIMES_CHANGE, Func = Bind(self, self.OnGoodsBuytimesChange)},
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.SpaceBarHold), Func = Bind(self,self.OnSpaceBarHold) },
    }

    self.BindNodes = {
        { UDelegate = self.WBP_ReuseList.OnUpdateItem, Func = self.OnUpdateItem},
        { UDelegate = self.WBP_Common_Btn.Btn_List.OnClicked, Func = Bind(self, self.OnButtonClickedBuy) },
    }

    UIHandler.New(self,self.CommonBtnTips_ESC, WCommonBtnTips,{
            OnItemClick = Bind(self, self.OnEscClicked),
            CommonTipsID = CommonConst.CT_ESC,
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
            ActionMappingKey = ActionMappings.Escape
        }
    )

    -- 商城货币栏
    if self.CommonCurrencyListIns == nil or not(self.CommonCurrencyListIns:IsValid()) then
        self.CommonCurrencyListIns = UIHandler.New(self, self.WBP_CommonCurrency, CommonCurrencyList, {ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND}).ViewInstance
    end

    if self.ShopDetailScenceIns == nil or not(self.ShopDetailScenceIns:IsValid()) then
        ---@type ShopDetailScence
        self.ShopDetailScenceIns = UIHandler.New(self, self.GUICanvasPanel_27, require("Client.Modules.Shop.ShopDetailScence")).ViewInstance
    end

    -- 商城合规功能
    self:ShowShopCompliant()

    self.GUISceneImage:SetVisibility(UE.ESlateVisibility.Collapsed)
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
    -- CError("ShopDetailMdt:ResetData()")
    self.GoodsInfo = nil --商品详情的商品信息，如果是捆绑包则是捆绑包的信息
    self.bShowing = false
    self.BuyNum = 1
    ---@type table<number,CommonItemIcon>
    self.ItemIconClsToIndex = {}
    self.Widget2ItemIconCls = {}

    self.CurSelectItemIndex = 1
    ---@type GoodsItem
    self.CurSelectItemData = nil --商品详情里当前选中的商品（如果是捆绑包，则是捆绑包里的商品）

    self.BuyButtonIns = nil
    self.RecommendIntro_Instance  = nil
end

function M:OnShow(InParams)
    CLog("ShopDetailMdt:OnShow")
    self:ShowUI_Inner(InParams)
end

function M:OnRepeatShow(InParams)
    CLog("ShopDetailMdt:OnRepeatShow")

    self:ShowUI_Inner(InParams)
end

function M:ShowUI_Inner(InParams)
    --先Hidden，防止UI闪现/闪变
    if CommonUtil.IsValid(self.GUITextBlockType) then
        self.GUITextBlockType:SetVisibility(UE.ESlateVisibility.Hidden)
    end
    if CommonUtil.IsValid(self.GUITextBlockItemName) then
        self.GUITextBlockItemName:SetVisibility(UE.ESlateVisibility.Hidden)
    end
    if CommonUtil.IsValid(self.GUITextBlockDesc) then
        self.GUITextBlockDesc:SetVisibility(UE.ESlateVisibility.Hidden)
    end
    if CommonUtil.IsValid(self.WBP_Common_QualityLevel) then
        self.WBP_Common_QualityLevel:SetVisibility(UE.ESlateVisibility.Hidden)
    end
    if CommonUtil.IsValid(self.WidgetSwitcher_Purchase) then
        self.WidgetSwitcher_Purchase:SetVisibility(UE.ESlateVisibility.Hidden)
    end

    if not InParams then
        return
    end

    if not(InParams.bInTheShop) then
        self.ModelShop:DispatchType(ShopModel.ON_HIDE_HALLTABSHOP,{bShow = false})  
    end

    self.bInTheShop = InParams.bInTheShop or false
    local Goods = InParams.Goods

    self:RefreshView(Goods)
end

function M:OnHide()
    self:OnHideAvator_Inner()
    self:ResetData()
    MvcEntry:GetModel(ShopModel):DispatchType(ShopModel.HANDLE_SHOPBG_SHOW, {Open = false})
end

function M:RefreshView(Params)
    self.GoodsInfo = Params
    self.bShowing = true
    self.BuyNum = 1
    
    self:UpdatePrice()
    self:UpdateItemsShow()
    self:UpdateGoodsInfo()
    self:ShowRecommendPack()
    --self:EventDataUpdate()
    self:ReqEventTrackingSimple(EventTrackingModel.SHOP_ACTION.CLICK_ENTER_TO_CONTENT, self.GoodsInfo.GoodsId, 0, EventTrackingModel.SHOP_BUY_TYPE.NOT_BUY) 
end

function M:ReqEventTrackingSimple(InAction, IngoodId, InIsShowInDetail, InBuyType)
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

function M:EventDataUpdate()
    if not self.GoodsInfo or not self.GoodsInfo.PackGoodsList then return end
    for _, v in pairs(self.GoodsInfo.PackGoodsList) do
        local ItemIndex = MvcEntry:GetModel(EventTrackingModel):GetItemIndexFromShopItemsIdTemp(v.PackGoodsId)
        self:ReqEventTracking(EventTrackingModel.SHOP_ACTION.DEFAULT_VIEW, v.PackGoodsId, self.GoodsInfo.GoodsId, 0, ItemIndex, EventTrackingModel.SHOP_BUY_TYPE.NOT_BUY) 
    end
end

function M:OnShowAvator(Param,IsNotVirtualTrigger)
    CLog("ShopDetailMdt:OnShowAvator")

    if self.CurSelectItemData then
        local CurItemGoods = self.CurSelectItemData.GoodsId

        self:UpdateGoodsIconAndModel_Inner(CurItemGoods)
    end
end

function M:OnHideAvator(Param,IsNotVirtualTrigger)
    self:OnHideAvator_Inner()
end

function M:OnHideAvator_Inner()
    self.ShowAvatarGoodsId = 0

    -- self:HideAvator_Inner() 
    if self.ShopDetailScenceIns and self.ShopDetailScenceIns:IsValid() then
        self.ShopDetailScenceIns:HideAvator()
    end
end

--- 展示推荐的捆绑包
function M:ShowRecommendPack()
    -- 推荐的对应捆绑包
    if self.RecommendIntro_Instance == nil or not(self.RecommendIntro_Instance:IsValid()) then
        self.RecommendIntro_Instance = UIHandler.New(self, self.WBP_Shop_DetailItem_Recommend, require("Client.Modules.Shop.RecommendIntro")).ViewInstance
    end
    self.RecommendIntro_Instance:UpdateRecommendIntro(self.GoodsInfo, Bind(self, self.RefreshView))
end

-------------------------------------------GoodsInfo >>

function M:UpdateGoodsInfo()
    if not CommonUtil.IsValid(self.GUITextBlockName) then
        return
    end

    self.GUITextBlockName:SetText(StringUtil.Format(self.GoodsInfo.Name))
    -- if UE.UGFUnluaHelper.IsEditor() then
    --     self.GUITextBlockName:SetText(StringUtil.Format(self.GoodsInfo.Name .. "(".. self.GoodsInfo.GoodsId ..")"))
    -- end
end

---更新商品价格
function M:UpdatePrice()
    ---@type SettlementSum
    local SettlementSum = MvcEntry:GetCtrl(ShopCtrl):GetGoodsPrice(self.GoodsInfo.GoodsId)
    local Price = SettlementSum.TotalSettlementPrice
    local OriginPrice = SettlementSum.TotalSuggestedPrice

    local ExtShowPriceStr, ExtShowPriceStrColor = ShopCtrl:ConvertState2String(self.GoodsInfo.GoodsState)
    ---@type CommonPriceParam
    local CommonPriceParam = {
        CurrencyType = self.GoodsInfo.CurrencyType,
        SettlementSum = SettlementSum,
        -- Price = Price,
        -- OriginPrice = OriginPrice,
        ExtShowPriceStr = ExtShowPriceStr,
        ExtShowPriceStrColor = ExtShowPriceStrColor,
        GoodsState = self.GoodsInfo.GoodsState
    }

    local BtnParam = {
        OnItemClick = Bind(self, self.OnBuyClick),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        CommonPriceParam = CommonPriceParam,
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
        BtnParam.TipStr = ExtShowPriceStr --StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Alreadyowned")) --"已拥有"
        BtnParam.bHideTipStr = false
    end

    if self.BuyButtonIns == nil or not(self.BuyButtonIns:IsValid()) then
        self.BuyButtonIns = UIHandler.New(self,self.WBP_HeroBuyButton, WCommonBtnTips, BtnParam).ViewInstance
    else
        -- self.BuyButtonIns:UpdatePriceShow(CommonPriceParam)
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
-------------------------------------------GoodsInfo <<

-------------------------------------------List >>

---更新商品详情List
function M:UpdateItemsShow()
    ---@type {GoodsId:number,ItemId:number,ItemNum:number}[]
    self.ItemList = {}
    if self.GoodsInfo.IsPackGoods then
        -- 如果是捆绑包
        if self.GoodsInfo.PackGoodsList then
            for Idx, PackGoods in pairs(self.GoodsInfo.PackGoodsList) do
                table.insert(self.ItemList,{
                        GoodsId = PackGoods.PackGoodsId,
                        ItemId = PackGoods.PackItemId,
                        ItemNum = PackGoods.PackItemNum,
                        PackItemIdx = PackGoods.PackItemIdx
                    })
            end
        else
            -- 捆绑包中没有商品
        end
    else
        -- 如果是 非捆绑包
        table.insert(self.ItemList, {
            GoodsId = self.GoodsInfo.GoodsId,
            ItemId = self.GoodsInfo.ItemId,
            ItemNum = self.GoodsInfo.ItemNum
        })
    end

    local ItemListCount = #self.ItemList

    if ItemListCount > 1 then
        self:SwithSomeUIToVisible(true)

        -- 重新设置的尺寸
        self:ResizeGUISizeBox(ItemListCount)

        self.ItemIconClsToIndex = {}
        self.WBP_ReuseList:Reload(ItemListCount)
    else
        self:SwithSomeUIToVisible(false)

        self:SelectItemAndShow(1, self.ItemList[1])
    end
end

function M:SwithSomeUIToVisible(bVisible)
    if CommonUtil.IsValid(self.GUIHorizontalBox_List) then
        self.GUIHorizontalBox_List:SetVisibility(bVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    end
    if CommonUtil.IsValid(self.GUIOverlay_TitleNode) then
        self.GUIOverlay_TitleNode:SetVisibility(bVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    end
    if CommonUtil.IsValid(self.Bg_Line2) then
        self.Bg_Line2:SetVisibility(bVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    end
end

--- 重新设置的尺寸
function M:ResizeGUISizeBox(ItemListCount)
    local BaseHeight = 110
    if ItemListCount <= 5 then
        self.GUISizeBox_ReuseList:SetHeightOverride(BaseHeight)
    elseif ItemListCount <= 10 then
        self.GUISizeBox_ReuseList:SetHeightOverride(BaseHeight * 2)
    else
        self.GUISizeBox_ReuseList:SetHeightOverride(BaseHeight * 2.5)
    end
end

function M:OnUpdateItem(Widget, Index)
    local TempIndex = Index + 1
    local ItemData = self.ItemList[TempIndex]
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemData.ItemId,
        ItemNum = ItemData.ItemNum,
        ClickCallBackFunc = Bind(self, self.OnItemClick, TempIndex, ItemData)
    }
    local ItemIconCls = self.Widget2ItemIconCls[Widget]
    if not ItemIconCls then
        ItemIconCls = UIHandler.New(self, Widget, CommonItemIcon, IconParam).ViewInstance
        self.Widget2ItemIconCls[Widget] = ItemIconCls
    else
        ItemIconCls:UpdateUI(IconParam)
    end

    self.ItemIconClsToIndex[ItemIconCls] = TempIndex
    local IsSelected = self.CurSelectItemIndex == TempIndex
    ItemIconCls:SetIsSelect(IsSelected)

    if TempIndex == 1 then
        self:OnItemClick(TempIndex, ItemData)
    end
end

-- 商品单品被点击事件
function M:OnItemClick(Index, ItemData)
    for ItemIconCls, TempIndex in pairs(self.ItemIconClsToIndex) do
        if TempIndex == Index then
            ItemIconCls:SetIsSelect(true)
        else
            ItemIconCls:SetIsSelect(false)
        end
    end

    self:SelectItemAndShow(Index, ItemData)
end

function M:SelectItemAndShow(Index, ItemData)
    self.CurSelectItemIndex = Index
    self.CurSelectItemData = ItemData

    self:UpdateItemsInfo(ItemData)
end

function M:UpdateItemsInfo(ItemData, Index)
    -- local ItemData = self.ItemList[Index]
    if not ItemData then
        CError(string.format("M:UpdateItemsInfo() ItemData == nil!!! "),true)
        return
    end
    
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemData.ItemId)
    if not ItemCfg then
        CError(string.format("M:UpdateItemsInfo() ItemCfg == nil!!! ,"), true)
        return
    end

    -- 显示当前选中的礼包(如果是捆绑包,则是捆绑包里的某个商品)
    if CommonUtil.IsValid(self.WBP_Common_Description) then
        self.WBP_Common_Description:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        local Param = {
            HideBtnSearch = true,
            -- HideDescription = true,
            ItemID = ItemData.ItemId,
            HideLine = false,
        }

        if self.GoodsInfo then
            Param.HideLine = self.GoodsInfo.IsPackGoods or false
        end

        if not self.CommonDescriptionCls then
            self.CommonDescriptionCls = UIHandler.New(self,self.WBP_Common_Description, CommonDescription, Param).ViewInstance
        else
            self.CommonDescriptionCls:UpdateUI(Param)
        end
    end

    -- 单品购买UI
    self:UpdateItemBuyNode(ItemData)

    self:UpdateGoodsIconAndModel_Inner(ItemData.GoodsId)
end

--- 更新单品购买UI
---@param ItemData table:{GoodsId:number,ItemId:number,ItemNum:number}
function M:UpdateItemBuyNode(ItemData)
    if not self.GoodsInfo.IsPackGoods then
        -- 判断当前商品详情是否是捆绑包
        self.WidgetSwitcher_Purchase:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end

    -- local bCanBuyGoods = MvcEntry:GetCtrl(ShopCtrl):CheckCanBuyGoods(self.GoodsInfo.GoodsId, self.BuyNum)
    -- if bCanBuyGoods then
    --     self.WidgetSwitcher_Purchase:SetVisibility(UE.ESlateVisibility.Collapsed)
    --     return
    -- end

    self.WidgetSwitcher_Purchase:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    ---@type GoodsItem
    local PackGoodsInfo = MvcEntry:GetModel(ShopModel):GetData(ItemData.GoodsId)

    ---@type number 当前选择的单品商品ID
    self.CurSingleGoodsID = ItemData.GoodsId
    ---@type ShopCtrl
    local ShopCtrl = MvcEntry:GetCtrl(ShopCtrl);

    if PackGoodsInfo.GoodsState == ShopDefine.GoodsState.ForbidSingleBuy then
        self.WidgetSwitcher_Purchase:Setvisibility(UE.ESlateVisibility.Collapsed)
        
    elseif PackGoodsInfo.GoodsState == ShopDefine.GoodsState.CanBuy then
        self.WidgetSwitcher_Purchase:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WidgetSwitcher_Purchase:SetActiveWidget(self.Panel_Buy)

        ---捆绑包中的单品购买的商品价格
        ---@type SettlementSum
        local SettlementSum = ShopCtrl:GetGoodsPrice(PackGoodsInfo.GoodsId, 1)

        --购买
        self.WBP_Common_Btn.Text_Count:SetText(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_buy"))

        local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, PackGoodsInfo.CurrencyType)
        if ItemCfg then
            CommonUtil.SetBrushFromSoftObjectPath(self.Image_Coin, ItemCfg[Cfg_ItemConfig_P.IconPath])    
        end

        self.Text_Number:SetText(SettlementSum.TotalSettlementPrice)
    else
        self.WidgetSwitcher_Purchase:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.WidgetSwitcher_Purchase:SetActiveWidget(self.Panel_TextGoodsState)
        -- Lua_ShopCtrl_Alreadyowned_Cur:当前选中物品已拥有
        local ExtShowPriceStr, ExtShowPriceStrColor = ShopCtrl:ConvertState2String(PackGoodsInfo.GoodsState, "Lua_ShopCtrl_Alreadyowned_Cur")
        self.GUITextGoodsState_1:SetText(ExtShowPriceStr)
        CommonUtil.SetTextColorFromeHex(self.GUITextGoodsState_1, ExtShowPriceStrColor)
    end
end

-------------------------------------------List <<


-------------------------------------------Avatar >>

function M:DispatchShopPageShow_Inner(GoodsInfo)
    if GoodsInfo.ItemId > 0 then
        local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, GoodsInfo.ItemId)
        if not ItemCfg then
            return
        end
        local ItemType = ItemCfg[Cfg_ItemConfig_P.Type]
        local ShowText = "" --self.Type2ShowText[ItemType] or "ITEMS"
        local Param = {
            Open = true,
            Type = 0
        }
        if ItemType == 2 then
            Param.Type = 1
            Param.Path =  ItemCfg[Cfg_ItemConfig_P.ImagePath]
        else
            Param.Text = StringUtil.Format(ShowText)
        end
        MvcEntry:GetModel(ShopModel):DispatchType(ShopModel.HANDLE_SHOPBG_SHOW, Param)
    end
end

---@param GoodsInfo GoodsItem
function M:ShowGoodsIcon_Inner(GoodsInfo)
    if GoodsInfo.SceneModelType == ShopDefine.SceneModelType.Icon then
        self.GUISceneImage:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.GUISceneImage, GoodsInfo.SceneModelIcon, true)
        ---@type RtShowTran
        local FinalTran = self.ModelShop:GetShopModeTranFinal(GoodsInfo.GoodsId, ETransformModuleID.Shop_Detail.ModuleID, false)
        if FinalTran and FinalTran.RenderTran then
            CommonUtil.SetBrushRenderTransform(self.GUISceneImage, FinalTran.RenderTran)
        end
    else
        self.GUISceneImage:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---跟新商品 图片 与 模型
function M:UpdateGoodsIconAndModel_Inner(GoodsId)
    if not GoodsId then
        CWaring("ShopDetailMdt:UpdateGoodsIconAndModel_Inner, GoodsId == nil !!!! ")
        return
    end

    -- CError("ShopDetailMdt:UpdateGoodsIconAndModel_Inner")
    if self.ShowAvatarGoodsId == GoodsId then
        CWaring(string.format("ShopDetailMdt:UpdateGoodsIconAndModel_Inner, self.ShowAvatarGoodsId == GoodsId !!!! GoodsId = %s",tostring(GoodsId)))
        return
    end

    ---@type GoodsItem
    local GoodsInfo = self.ModelShop:GetData(GoodsId)
    if not GoodsInfo then
        return
    end

    self.ShowAvatarGoodsId = GoodsId

    self:DispatchShopPageShow_Inner(GoodsInfo)
    -- 商品图片
    self:ShowGoodsIcon_Inner(GoodsInfo)

    -- local Param = { 
    --     GoodsId = GoodsId,
    --     TransparentViewId = self.viewId,
    --     ETranModuleID = ETransformModuleID.Shop_Detail.ModuleID 
    -- }
    -- -- MvcEntry:GetCtrl(ShopCtrl):SetLastShowParam(Param)
    -- -- CError("ShopRecommend:UpdateGoodsIconAndModel_Inner  ON_UPDATE_GOODS_MODEL_SHOW")
    -- self.ModelShop:DispatchType(ShopModel.ON_UPDATE_GOODS_MODEL_SHOW, Param)

    if self.ShopDetailScenceIns and self.ShopDetailScenceIns:IsValid() then
        --商品模型
        self.ShopDetailScenceIns:TryUpdateShowAvatar(GoodsInfo, self.GoodsInfo.GoodsId, self.bInTheShop)
    end
end
-------------------------------------------Avatar <<

-------------------------------------------btn >>

--礼包购买按钮
function M:OnBuyClick()
    -- CError("================ OnSpaceBarClick")
    MvcEntry:GetCtrl(ShopCtrl):RequestBuyShopItem(self.GoodsInfo.GoodsId, self.BuyNum)

    local GoodsInfo = MvcEntry:GetModel(ShopModel):GetData(self.GoodsInfo.GoodsId)
    local IsPackGoods = GoodsInfo.IsPackGoods
    local IsBuySingle = IsPackGoods and EventTrackingModel.SHOP_BUY_TYPE.BUY_BUNDLE or EventTrackingModel.SHOP_BUY_TYPE.BUY_SINGLE

    local ItemIndex = MvcEntry:GetModel(EventTrackingModel):GetItemIndexFromShopItemsIdTemp(self.GoodsInfo.GoodsId)
    self:ReqEventTracking(EventTrackingModel.SHOP_ACTION.CLICK_BUY, self.GoodsInfo.GoodsId, IsPackGoods and self.GoodsInfo.GoodsId or 0, 1, ItemIndex, IsBuySingle)
end

function M:OnSpaceBarHold()
    --  CError("================ OnSpaceBarHold")
    MvcEntry:GetCtrl(ShopCtrl):RequestBuyShopItem(self.GoodsInfo.GoodsId, self.BuyNum, true)
end

--- 点击了单品购买按钮
function M:OnButtonClickedBuy()
    local ItemData = self.CurSelectItemData
    MvcEntry:GetCtrl(ShopCtrl):RequestBuyShopItem(ItemData.GoodsId, 1)
    self:ReqEventTracking(EventTrackingModel.SHOP_ACTION.CLICK_BUY, ItemData.GoodsId, 0, 0, self.CurSelectItemIndex, EventTrackingModel.SHOP_BUY_TYPE.BUY_SINGLE)
end


function M:OnEscClicked()
    MvcEntry:CloseView(ViewConst.ShopDetail)
end

-------------------------------------------btn <<



-------------------------------------------Event >>

function M:OnGoodsBuytimesChange()
    if not self.bShowing then
        return
    end

    if not self.GoodsInfo then
        return
    end
    self.GoodsInfo = MvcEntry:GetModel(ShopModel):GetData(self.GoodsInfo.GoodsId)
    self:UpdatePrice()

    local ItemData = self.ItemList[self.CurSelectItemIndex]
    self:UpdateItemBuyNode(ItemData)
end

-------------------------------------------Event <<


function M:ReqEventTracking(action, goodId, withBundle, isShowInDetail, index, buyType)
    local eventTrackingData = {
        action = action,
        product_id = goodId,
        belong_product_id = withBundle,
        isShowInDetail = isShowInDetail,
        product_index = index,
        buy_type = buyType
    }

    MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SHOP_EVENTTRACKING_CLICK, eventTrackingData)
end

return M
