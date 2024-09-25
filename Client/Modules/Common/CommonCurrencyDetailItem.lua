--[[
    通用的货币控件的详情ID控件
    传值ItemId和具体的控件，进行自动取值展示
]]

local class_name = "CommonCurrencyDetailItem"
CommonCurrencyDetailItem = CommonCurrencyDetailItem or BaseClass(nil, class_name)


function CommonCurrencyDetailItem:OnInit()
    self.MsgList = 
    {
		{Model = DepotModel, MsgName = ListModel.ON_UPDATED_MAP_CUSTOM, Func = self.ON_UPDATED_MAP_CUSTOM_Func },
	}

    -----------------TBT特殊处理-屏蔽 >>
    self.View.HBox_GiftDiamond:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.View.HBox_PlayDiamond:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.View.GUITextBlock_DiamondTip:SetVisibility(UE4.ESlateVisibility.Collapsed)
    -----------------TBT特殊处理-屏蔽 <<
end

function CommonCurrencyDetailItem:OnShow(Param)
    self:UpdateItemInfo(Param)
end

function CommonCurrencyDetailItem:OnHide()
end

-- function CommonCurrencyDetailItem:OnManualShow(Param)
--     self:UpdateItemInfo(Param)
-- end

-- function CommonCurrencyDetailItem:ShowItem(Param)
--     self.View:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
--     self:UpdateItemInfo(Param)
-- end

-- function CommonCurrencyDetailItem:HideItem()
--     self.View:SetVisibility(UE4.ESlateVisibility.Collapsed)
-- end

---@param Param {ItemID:number}
function CommonCurrencyDetailItem:UpdateItemInfo(Param)
    if Param == nil then
        CError("CommonCurrencyDetailItem:UpdateItemInfo(),Param == nil", true)
        return
    end

    self.CurCurrencyInfo = Param

    local ItemID = Param.ItemID 
    if ItemID == ShopDefine.CurrencyType.DIAMOND or ItemID == ShopDefine.CurrencyType.Gift_DIAMOND then
        self:SetDiamondItem(Param)
    else
        self:SetOtherItem(Param)
    end

    self:UpdateCurrencyInfo()
end

--- 展示钻石
---@param Param any
function CommonCurrencyDetailItem:SetDiamondItem(Param)
    self.View.WidgetSwitcher_Item:SetActiveWidget(self.View.Item_Diamond)

    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ShopDefine.CurrencyType.DIAMOND)
    if not CfgItem then
        CError("CommonCurrencyDetailItem:SetDiamondItem, Con't Find CfgItem, Param.ItemID " .. tostring(Param.ItemID), true)
        return
    end

    CommonUtil.SetBrushFromSoftObjectPath(self.View.ImgDiamond1, CfgItem[Cfg_ItemConfig_P.IconPath])
    CommonUtil.SetBrushFromSoftObjectPath(self.View.ImgDiamond2, CfgItem[Cfg_ItemConfig_P.IconPath])
    CommonUtil.SetBrushFromSoftObjectPath(self.View.ImgDiamond3, CfgItem[Cfg_ItemConfig_P.IconPath])
    self.View.TextBlock_DiamondName:SetText(CfgItem[Cfg_ItemConfig_P.Name])
    self.View.TextBlock_DiamondDes:SetText(CfgItem[Cfg_ItemConfig_P.Des])
    if Param.bTheLast then
        self.View.ImgLine_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
        self.View.ImgLine_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end

    if CommonUtil.IsValid(self.View.GUITextBlock_DiamondTip) then
        local StrTip = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_CommonCurrency_Diamond_ConsumeTip"), CfgItem[Cfg_ItemConfig_P.Name]) --*购买物品时，优先消费付费{0}
        self.View.GUITextBlock_DiamondTip:SetText(StrTip)
    end
end

--- 展示金币/其它
---@param Param any
function CommonCurrencyDetailItem:SetOtherItem(Param)
    self.View.WidgetSwitcher_Item:SetActiveWidget(self.View.Item_Gold)

    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, Param.ItemID)
    if not CfgItem then
        CError("CommonCurrencyDetailItem:SetOtherItem, Con't Find CfgItem, Param.ItemID " .. tostring(Param.ItemID), true)
        return
    end

    CommonUtil.SetBrushFromSoftObjectPath(self.View.ImgIconGold2, CfgItem[Cfg_ItemConfig_P.IconPath])
    self.View.TextBlock_GoldName:SetText(CfgItem[Cfg_ItemConfig_P.Name])
    self.View.TextBlock_GoldDes:SetText(CfgItem[Cfg_ItemConfig_P.Des])
    if Param.bTheLast then
        self.View.ImgLine:SetVisibility(UE4.ESlateVisibility.Collapsed)
    else
        self.View.ImgLine:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
end

--- func 道具发生变化时的回调
---@param ChangeMap any
function CommonCurrencyDetailItem:ON_UPDATED_MAP_CUSTOM_Func(ChangeMap)
    if ChangeMap[self.CurCurrencyInfo.ItemID] or ChangeMap[ShopDefine.CurrencyType.Gift_DIAMOND] then
        self:UpdateCurrencyInfo()
    end
end

--- func 更新详情里的数量信息
function CommonCurrencyDetailItem:UpdateCurrencyInfo()
    if self.CurCurrencyInfo.ItemID == ShopDefine.CurrencyType.DIAMOND or self.CurCurrencyInfo.ItemID == ShopDefine.CurrencyType.Gift_DIAMOND then
        local GiftDiamondNum = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ShopDefine.CurrencyType.Gift_DIAMOND, {bDisassociate = true}) -- 免费钻石数量
        local DiamondNum = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ShopDefine.CurrencyType.DIAMOND, {bDisassociate = true}) -- 付费钻石数量

        local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ShopDefine.CurrencyType.DIAMOND)
        if CfgItem then
            local StrTip1 = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_CommonCurrency_DiamondNum_Gift"), CfgItem[Cfg_ItemConfig_P.Name], GiftDiamondNum) --免费{0}数：{1}
            self.View.GUITextBlock_2:SetText(StrTip1) -- 免费钻石数量

            local StrTip2 = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_CommonCurrency_DiamondNum"), CfgItem[Cfg_ItemConfig_P.Name], DiamondNum) --付费{0}数：{1}
            self.View.GUITextBlock_3:SetText(StrTip2) -- 付费钻石数量
        end
    else
        --TODO:其它情况不需要更新
    end
end

return CommonCurrencyDetailItem