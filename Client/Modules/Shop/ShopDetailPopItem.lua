--[[
    大厅 - 切页 - 商店 - WBP_Shop_Item 
]]
local class_name = "ShopDetailPopItem"
ShopDetailPopItem = BaseClass(UIHandlerViewBase, class_name)

function ShopDetailPopItem:OnInit()
    ---@type ShopModel
    self.Model = MvcEntry:GetModel(ShopModel)

    
    self.BindNodes = {
        { UDelegate = self.View.WBP_ReuseList.OnUpdateItem, Func = Bind(self, self.OnUpdateItem) }, 
        -- { UDelegate = self.GUIButton_Close.OnClicked, Func = self.OnCloseClicked}
    }
end

function ShopDetailPopItem:OnShow(Param)
    self:UpdateUI(Param)
end

function ShopDetailPopItem:OnManualShow(Param)
    self:UpdateUI(Param)
end

function ShopDetailPopItem:OnManualHide(Param)

end

function ShopDetailPopItem:OnHide(Param)
    self.BuyNum = 0
    self.ItemList = nil
    self.Widget2ItemIconCls = nil
end

function ShopDetailPopItem:UpdateUI(Param)
    if Param == nil then
        return
    end
    ---@type GoodsItem
    self.GoodsInfo = Param.GoodsInfo

    self.BuyNum = 1

    self.OnBuyNumChanage = Param.OnBuyNumChanage

    self:UpdateItemsShow()

    self:ShowWBP_CommonEditableSlider()

    self:UpdateShowIcon()
    self:UpdatePrice()
end

function ShopDetailPopItem:UpdatePrice()
    local SettlementSum = MvcEntry:GetCtrl(ShopCtrl):GetGoodsPrice(self.GoodsInfo.GoodsId, self.BuyNum)
    local DiscountValue = SettlementSum.Discount

    local bCanBuy = MvcEntry:GetCtrl(ShopCtrl):CheckCanBuyGoods(self.GoodsInfo.GoodsId)
    if bCanBuy and DiscountValue > 0 then
        -- self.View.GUITextDiscount:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.GUIOverlay_Discount:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.GUITextDiscount:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_3"), DiscountValue))
    else
        -- self.View.GUITextDiscount:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.View.GUIOverlay_Discount:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function ShopDetailPopItem:UpdateItemsShow()
    self.ItemList = {}

    if self.GoodsInfo.IsPackGoods then
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
            return
        end
    else
        table.insert(self.ItemList, {
            GoodsId = self.GoodsInfo.GoodsId,
            ItemId = self.GoodsInfo.ItemId,
            ItemNum = self.GoodsInfo.ItemNum
        })
    end

    if #self.ItemList == 1 and self.ItemList[1].ItemNum == 1 then
        self.View.WidgetSwitcher:SetActiveWidgetIndex(1)
        local ItemData = self.ItemList[1]
        local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemData.ItemId)
        if not ItemCfg then
            return
        end
        self.View.GUITextBlock:SetText(StringUtil.Format(ItemCfg[Cfg_ItemConfig_P.Des]))
    else
        self.View.WidgetSwitcher:SetActiveWidgetIndex(0)
        self.View.WBP_ReuseList:Reload(#self.ItemList)
    end
end

function ShopDetailPopItem:OnUpdateItem(_, Widget, idx)
    if self.ItemList == nil or next(self.ItemList) == nil then
        return
    end
    local Index = idx + 1
    local ItemData = self.ItemList[Index]
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemData.ItemId,
        ItemNum = ItemData.ItemNum,
        HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP
    }

    self.Widget2ItemIconCls = self.Widget2ItemIconCls or {}
    local ItemIconCls = self.Widget2ItemIconCls[Widget]
    if not ItemIconCls then
        ItemIconCls = UIHandler.New(self, Widget, CommonItemIcon, IconParam).ViewInstance
        self.Widget2ItemIconCls[Widget] = ItemIconCls
    else
        ItemIconCls:UpdateUI(IconParam)
    end
end


function ShopDetailPopItem:ShowWBP_CommonEditableSlider()
    local MaxValue = 1
    local ShowSlider = true

    --还能拥有的物品数量
    local _, _, CanBuyGoodsNum = self:GetCanGetNumMin()
    local MinVal = CanBuyGoodsNum
    if self.GoodsInfo.MaxLimitCount > 0 then
        --剩余购买数量
        local LeftBuyTimes = self.GoodsInfo.MaxLimitCount - self.GoodsInfo.BuyTimes
        MinVal = LeftBuyTimes > CanBuyGoodsNum and CanBuyGoodsNum or LeftBuyTimes
    end

    local limitMaxVal = 100
    MaxValue = MinVal > limitMaxVal and limitMaxVal or MinVal
    ShowSlider = MaxValue > 1 and true or false

    self.View.WBP_CommonEditableSlider:SetVisibility(ShowSlider and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if ShowSlider then
        local Param = {
            ValueChangeCallBack = Bind(self, self.ValueChangeCallBack),
            MinValue = 1,
            MaxValue = MaxValue,
            DefaultValue = 1,
        }
        UIHandler.New(self, self.View.WBP_CommonEditableSlider, CommonEditableSlider, Param)
    end
end

function ShopDetailPopItem:ValueChangeCallBack(Value)
    -- CLog("---------------" .. Value)
    self.BuyNum = Value

    if self.OnBuyNumChanage then
        
        self.OnBuyNumChanage({BuyNum = self.BuyNum})
    end

    -- if self.BuyButtonIns and self.BuyButtonIns:IsValid() then
    --     local SettlementSum, CommonPriceParam = self:GetPriceInfo(self.BuyNum)
    --     self.BuyButton:UpdatePriceShow(CommonPriceParam)
    -- end

    -- self:UpdateBtnPirce(self.BuyNum)
end


---通过商品Id获得这个商品中的物品还能够拥有的物品数量的最小值
---@return number.物品ID,number.还能拥有这个物品的数量,number.能够购买几个这样的商品
function ShopDetailPopItem:GetCanGetNumMin()
    local KeyItemIds,KeyItemIdToNum = self.Model:GetKeyItemIds(self.GoodsInfo.GoodsId)
    if #KeyItemIds <= 0 then
        table.insert(KeyItemIds, self.GoodsInfo.ItemId)
    end
    
    local RetItemNum = 0
    local RetItemID = 0
    local RetBuyGoodsNum = 0
    ---@type DepotModel
    local DepotModel = MvcEntry:GetModel(DepotModel)
    local MaxItemNum = 0
    local OwnerItemNum = 0
    local CanGetNum = 0
    local CanBuyGoodsNum = 0
   
    local divisor = 0
    for _, KeyItemId in pairs(KeyItemIds) do
        MaxItemNum = DepotModel:GetItemMaxCountByItemId(KeyItemId)
        OwnerItemNum = DepotModel:GetItemCountByItemId(KeyItemId)
        CanGetNum = MaxItemNum - OwnerItemNum

        divisor = KeyItemIdToNum[KeyItemId] == 0 and 1 or KeyItemIdToNum[KeyItemId]
        if divisor == nil then
            CError(string.format("ShopDetailPopItem:GetCanGetNumMin, divisor == nil, 配置错误!! GoodsId = [%s], GoodsInfo.ItemId = [%s], KeyItemId=[%s]", tostring(self.GoodsInfo.GoodsId), tostring(self.GoodsInfo.ItemId), tostring(KeyItemId)), true)
            divisor = 1
        end
        CanBuyGoodsNum = math.ceil(CanGetNum / divisor)
 
        if RetBuyGoodsNum == 0 then
            RetBuyGoodsNum = CanBuyGoodsNum
            RetItemNum = CanGetNum
            RetItemID = KeyItemId
        elseif RetBuyGoodsNum < CanBuyGoodsNum then
            --取 RetBuyGoodsNum 的最小值
            RetBuyGoodsNum = CanBuyGoodsNum
            RetItemNum = CanGetNum
            RetItemID = KeyItemId
        end
   end

   return RetItemID, RetItemNum, CanBuyGoodsNum
end

function ShopDetailPopItem:GetLimitMax(GoodsId, LimitMaxVal)
    LimitMaxVal = LimitMaxVal or 100
    ---@type GoodsItem
    local Data = self.Model:GetData(GoodsId)
    if Data == nil then
       return 0
    end
    local KeyItemIds = self.Model:GetKeyItemIds(GoodsId)
    if #KeyItemIds <= 0 then
        table.insert(KeyItemIds, Data.ItemId)
    end

    local MinVal = 0
    for _, KeyItemId in pairs(KeyItemIds) do
       ---@type DepotModel
       local DepotModel = MvcEntry:GetModel(DepotModel)
       local MaxItemNum = DepotModel:GetItemMaxCountByItemId(KeyItemId)
       local OwnerItemNum = DepotModel:GetItemCountByItemId(KeyItemId)
       local BuyTimes = self.Model:GetGoodsBuyTimes(GoodsId)
       local CanGetNum = MaxItemNum - OwnerItemNum
       local CanBuyTimes = Data.MaxLimitCount - Data.BuyTimes
       local mVal = CanGetNum > CanBuyTimes and CanBuyTimes or CanGetNum
       if MinVal == 0 then
           MinVal = mVal
       else
           MinVal = MinVal > mVal and mVal or MinVal
       end
   end
   MinVal = MinVal > LimitMaxVal and LimitMaxVal or MinVal
   return MinVal
end


function ShopDetailPopItem:UpdateGoodsInfo()
    if not CommonUtil.IsValid(self.View.GUITextBlockName) then
        return
    end
    self.GUITextBlockName:SetText(StringUtil.Format(self.GoodsInfo.Name))
    local Quality = MvcEntry:GetModel(ShopModel):GetGoodsQuality(self.GoodsInfo.GoodsId)
    CommonUtil.SetTextColorFromQuality(self.View.GUITextBlockName, Quality)
end


--- 更新商品图片展示
function ShopDetailPopItem:UpdateShowIcon()
    if self.GoodsInfo == nil then
        return
    end

    local ItemId = self.GoodsInfo.ItemId
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
    if ItemCfg == nil then
        CError(string.format("ShopDetailPopItem:UpdateShowIcon, ItemCfg == nil !!! ItemId = %s", tostring(ItemId)))
        return
    end

    if not CommonUtil.IsValid(self.View.AchievementIcon) then
        return
    end

    -- if not self.ItemInfo.Icon or self.ItemInfo.Icon == "" then
    --     self.View.GUIImageGoods:SetVisibility(UE.ESlateVisibility.Collapsed)
    --     return
    -- end
    -- self.View.GUIImageGoods:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageGoods, self.ItemInfo.Icon)

    local Img = self.GoodsInfo.Icon
    -- if self.GoodsInfo.SceneModelIcon ~= nil and self.GoodsInfo.SceneModelIcon ~= "" then
    --     Img = self.GoodsInfo.SceneModelIcon
    -- end

    if not Img or Img == "" then
        self.View.AchievementIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.View.AchievementIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.View.AchievementIcon, Img)
    end

    -- CommonUtil.SetQualityShowForQualityId(self.GoodsInfo.Quality,{
    --     QualityBgIcon = self.GUIImageQuality,
    --     QualityVerticalImg = self.QualityVerticalImg,
    --     QualityIcon = self.WBP_Common_QualityLevel.GUIImageQuality,
    --     -- QualityLevelText = self.WBP_Common_QualityLevel.GUITextBlock_QualityLevel,
    -- })


    self:SetQualityBgQuality(ItemCfg[Cfg_ItemConfig_P.Quality])
end

-- 设置品质底（用于商城圆圈背景品质底图）
function ShopDetailPopItem:SetQualityBgQuality(Quality)

    local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg, Quality)
    if QualityCfg == nil then
        return
    end

    -- local HexColor = QualityCfg[Cfg_ItemQualityColorCfg_P.HexColor]
    -- local HexColor = QualityCfg[Cfg_ItemQualityColorCfg_P.BgHexColor]
    CommonUtil.SetImageColorFromQuality(self.View.Image_QualityHigh, Quality)
    CommonUtil.SetImageColorFromQuality(self.View.Image_QualityLow, Quality)

    if Quality >= EItemQuality.Orange.Quality then
        self.View.WidgetSwitcher_State:SetActiveWidget(self.View.Image_QualityHigh)
        -- CommonUtil.SetBrushTintColorFromHex(self.View.Image_QualityHigh, HexColor, 1)
    else
        self.View.WidgetSwitcher_State:SetActiveWidget(self.View.Image_QualityLow)
        -- CommonUtil.SetBrushTintColorFromHex(self.View.Image_QualityLow, HexColor, 1)
    end
end

return ShopDetailPopItem