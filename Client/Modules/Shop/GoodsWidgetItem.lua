--[[
    大厅 - 切页 - 商店 -占1/2/4个格子的同样是这个脚本
]]
local class_name = "GoodsWidgetItem"
GoodsWidgetItem = BaseClass(nil, class_name)

GoodsWidgetItem.LimitTimesStr = {
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_INVALID] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Restrictedpurchase"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_DAY] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Dailylimit"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_WEEK] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Weeklylimit"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_MONTH] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Monthlypurchaserestr"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_SEASON] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Limitedtoperseason"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_FOREVER] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Permanentpurchaseres")
}

--- 初始化
function GoodsWidgetItem:OnInit()

    --CError("xxxxxxxxxxxxxxxxxxxxxxxxxxx="..UE.UKismetSystemLibrary.GetDisplayName(self.View))
    ---@type GoodsItem
    self.ItemInfo = nil

    ---@type ShopModel
    self.ShopModel = MvcEntry:GetModel(ShopModel)
    self.BindNodes = {
        { UDelegate = self.View.GUIButton.OnHovered,Func = Bind(self, self.OnHovered)}, 
        { UDelegate = self.View.GUIButton.OnUnHovered, Func = Bind(self, self.OnUnHovered)},
        { UDelegate = self.View.GUIButton.OnClicked, Func = Bind(self, self.OnGoodsWidgetItemClicked)},
    }

    -- if self.View.OnMouseButtonDownEvent then
    --     table.insert(self.BindNodes, { UDelegate = self.View.OnMouseButtonDownEvent, Func = Bind(self, self.OnMouseButtonDownEvent_Func)})
    -- end
    -- if self.View.OnMouseButtonUpEvent then
    --     table.insert(self.BindNodes, { UDelegate = self.View.OnMouseButtonUpEvent, Func = Bind(self, self.OnMouseButtonUpEvent_Func)})
    -- end

    self.MsgList = {
        { Model = ShopModel, MsgName = ShopModel.ON_GOODS_BUYTIMES_CHANGE, Func = Bind(self, self.OnGoodsBuytimesChange)  },
        { Model = ShopModel, MsgName = ShopModel.ON_GOODS_INFO_CHANGE, Func = Bind(self, self.ON_GOODS_INFO_CHANGE_Func)  },
        { Model = ShopModel, MsgName = ShopModel.ON_SCROLL_CHANGE, Func = self.OnScrollChange },
        -- { Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.RightMouseButton),	Func = Bind(self, self.RightMouseButtonReleased_Func) },
        -- { Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.RightMouseButton),	Func = Bind(self, self.RightMouseButtonReleased_Func) },
        { Model = InputModel, MsgName = ActionReleased_Event(ActionMappings.RightMouseButtonTap),	Func = Bind(self, self.RightMouseButtonReleased_Func) },
        -- { Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.RightMouseButtonTap),	Func = Bind(self, self.RightMouseButtonReleased_Func) },
    }

    if CommonUtil.IsValid(self.View.WBP_SpecialMark) then
        self.SpecialMark = UIHandler.New(self, self.View.WBP_SpecialMark,require("Client.Modules.Common.CommonSpecialMark"), nil).ViewInstance
    end
    self.AutoCheckTime = 1

    ---详情按钮
    if CommonUtil.IsValid(self.View.Item_DetailBtn) then
        self.DetailBtnIns = UIHandler.New(self, self.View.Item_DetailBtn, WCommonBtnTips, {
            CheckButtonIsVisible = true,
            OnItemClick = Bind(self, self.OnClickDetailBtn),
            CommonTipsID = CommonConst.CT_SPACE,
            TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop","GoodsDetail"),
            -- HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.None,
            ActionMappingKey = ActionMappings.SpaceBar
        }).ViewInstance

        self.DetailBtnIns:SetBtnEnabled(false)
    end
    ---购买按钮
    if CommonUtil.IsValid(self.View.Item_BuyBtn) then
        self.BuyBtnIns = UIHandler.New(self, self.View.Item_BuyBtn, WCommonBtnTips, {
            CheckButtonIsVisible = true,
            OnItemClick = Bind(self, self.OnClickBuyBtn),
            CommonTipsID = CommonConst.CT_R,
            TipStr = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop","GoodsBuy"),
            -- HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.None,
            ActionMappingKey = ActionMappings.R
        }).ViewInstance

        self.BuyBtnIns:SetBtnEnabled(false)
    end
end

--- 显示
---@param Param any
function GoodsWidgetItem:OnShow(Param)
  
    self:CleanAutoCheckTimer()

    if self.DetailBtnIns and self.DetailBtnIns:IsValid() then
        self.DetailBtnIns:SetBtnEnabled(false)
    end
    if self.BuyBtnIns and self.BuyBtnIns:IsValid() then
        self.BuyBtnIns:SetBtnEnabled(false)
    end
end

--- 隐藏
function GoodsWidgetItem:OnHide()

    self:CleanAutoCheckTimer()
    self.ItemInfo = nil
    self.ShopModel = nil
    self.CommonPrice = nil
end

function GoodsWidgetItem:OnClickDetailBtn()
    -- CError("点击了详情页签按钮")
    self:OnGoodsWidgetItemClicked()

    -- self.ShopModel:DispatchType(ShopModel.ON_CLICK_GOODS_CHANGE, {ClickType = ShopDefine.ClickGoodsType.DetailBtn, GoodsId = self.ItemInfo.GoodsId})
    self:ReqEventTracking(EventTrackingModel.SHOP_ACTION.CLICK_ENTER_TO_CONTENT, self.ItemInfo.GoodsId, 1, self.Index > -1 and self.Index or 0, EventTrackingModel.SHOP_BUY_TYPE.NOT_BUY)
end

function GoodsWidgetItem:OnClickBuyBtn()
    -- CError("点击了购买页签按钮")
    -- if self.ItemInfo and next(self.ItemInfo) then
    --     MvcEntry:GetCtrl(ShopCtrl):RequestBuyShopItem(self.ItemInfo.GoodsId, 1)
    -- end

    self:BuyGoodsNow_Quick()
end

function GoodsWidgetItem:BuyGoodsNow_Quick()
    self:BuyGoodsNow()

    -- self.ShopModel:DispatchType(ShopModel.ON_CLICK_GOODS_CHANGE, {ClickType = ShopDefine.ClickGoodsType.BuyBtn, GoodsId = self.ItemInfo.GoodsId})
    self:ReqEventTracking(EventTrackingModel.SHOP_ACTION.CLICK_BUY, self.ItemInfo.GoodsId, 0, self.Index > -1 and self.Index or 0, EventTrackingModel.SHOP_BUY_TYPE.BUY_SINGLE)
end

function GoodsWidgetItem:OnHovered()
    if self.ItemInfo and self.CallBack then
        --CError("OnHovered=="..UE.UKismetSystemLibrary.GetDisplayName(self.View))

        self.CallBack(self.ItemInfo.GoodsId, true)
        self:OnRedDotTrigger(RedDotModel.Enum_RedDotTriggerType.Hover)
    end

    -- CWaring("GoodsWidgetItem:OnHovered")

    if self.DetailBtnIns and self.DetailBtnIns:IsValid() then
        self.DetailBtnIns:SetBtnEnabled(true)
    end
    if self.BuyBtnIns and self.BuyBtnIns:IsValid() then
        self.BuyBtnIns:SetBtnEnabled(true)
    end
end

function GoodsWidgetItem:OnUnHovered()
    if self.ItemInfo and self.CallBack then
        self.CallBack(-1, false)
    end

    if self.ItemInfo then
        self.ShopModel:SetLastOnUnHoverGoodsId(self.ItemInfo.GoodsId)
    else
        self.ShopModel:SetLastOnUnHoverGoodsId(0)
    end

    -- CError("GoodsWidgetItem:OnUnHovered") 
    if self.DetailBtnIns and self.DetailBtnIns:IsValid() then
        self.DetailBtnIns:SetBtnEnabled(false)
    end
    if self.BuyBtnIns and self.BuyBtnIns:IsValid() then
        self.BuyBtnIns:SetBtnEnabled(false)
    end
end

--- 监听到选中的Item发生改变
---@param Param table{GoodsId:number.商品ID, IsMouseMode:boolen.是否鼠标模式}
function GoodsWidgetItem:OnScrollChange(Param)
    if Param == nil then
        CError("GoodsWidgetItem:OnScrollChange, Param == nil !!!",true)
        return
    end

    if self.ItemInfo == nil then
        return
    end

    local GoodsId = Param.GoodsId
    local bVal = GoodsId == self.ItemInfo.GoodsId
    -- CError(string.format("--监听到选中的Item发生改变,bVal = %s, Param = %s",tostring(bVal), table.tostring(Param)))

    if self.bSelect ~= bVal then
        self.bSelect = bVal

        local IsMouseMode = Param and Param.IsMouseMode or false
        if GoodsId == self.ItemInfo.GoodsId then
            if self.DetailBtnIns and self.DetailBtnIns:IsValid() then
                self.DetailBtnIns:SetBtnEnabled(true)    
            end
            if self.BuyBtnIns and self.BuyBtnIns:IsValid() then
                self.BuyBtnIns:SetBtnEnabled(true)
            end
            if not(IsMouseMode) and self.View.SetSelectMark_WidgetStyle_BP then
                --鼠标模式下不需要走这里,因为蓝图已经实现,在按钮OnHover时被调用
                self.View:SetSelectMark_WidgetStyle_BP(true)
            end
        else
            if self.DetailBtnIns and self.DetailBtnIns:IsValid() then
                self.DetailBtnIns:SetBtnEnabled(false)    
            end
            if self.BuyBtnIns and self.BuyBtnIns:IsValid() then
                self.BuyBtnIns:SetBtnEnabled(false)
            end
            if self.View.SetSelectMark_WidgetStyle_BP then
                self.View:SetSelectMark_WidgetStyle_BP(false)
            end
        end
    end
end

--绑定商品红点
function GoodsWidgetItem:RegisterGoodsWidgetRedDot()
    if not self.ItemInfo then
        return
    end
    local RedDotKey = "ShopTabItem_"
    local RedDotSuffix = self.ItemInfo.GoodsId
    if not self.GoodRedDot then
        if self.View.WBP_RedDotFactory then
            self.View.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.GoodRedDot = UIHandler.New(self, self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
        end
    else 
        self.GoodRedDot:ChangeKey(RedDotKey, RedDotSuffix)
    end
end

--- 设置数据
---@param Param GoodsItem
function GoodsWidgetItem:SetData(Param, CallBack, SelectGoodsId, CategoryID, InIndex)
    if not Param then
        CWaring("[GoodsWidgetItem]SetData Param is nil!")
        return
    end

    self.ItemInfo = Param
    self.CallBack = CallBack
    self.CategoryID = CategoryID
    self.Index = InIndex and InIndex or -1

    self:UpdateGoodsInfo()
    self:UpdateGoodsQualityImg()
    self:UpdatePrice()
    self:UpdateLimitTimes()
    self:UpdateLeftTime()
    self:UpdateCurrencyIcon()
    self:UpdateIcon()
    self:UpdateSpecialMarkIcon()
    self:OnScrollChange({GoodsId = SelectGoodsId, IsMouseMode = nil})
    self:RegisterGoodsWidgetRedDot()
end

function GoodsWidgetItem:UpdatePrice()
    if not CommonUtil.IsValid(self.View.WBP_Shop_List_Information.WBP_CommonPrice) then
        return
    end

    local DiscountStyle = CommonPrice.DiscountStyle.Default
    if self.ItemInfo.GridType == ShopDefine.GridType.Wider then
        DiscountStyle = CommonPrice.DiscountStyle.Large
    end

    ---@type ShopCtrlr
    local ShopCtrl = MvcEntry:GetCtrl(ShopCtrl);
    ---@type SettlementSum
    local SettlementSum = ShopCtrl:GetGoodsPrice(self.ItemInfo.GoodsId)

    local ExtShowPriceStr, ExtShowPriceStrColor = ShopCtrl:ConvertState2String(self.ItemInfo.GoodsState)
    local Params = {
        CurrencyType = self.ItemInfo.CurrencyType,
        SettlementSum = SettlementSum,
        DiscountStyle = DiscountStyle,
        -- Price = SettlementSum.TotalSettlementPrice,
        -- OriginPrice = SettlementSum.TotalSuggestedPrice,
        ExtShowPriceStr = ExtShowPriceStr,
        ExtShowPriceStrColor = ExtShowPriceStrColor,
        GoodsState = self.ItemInfo.GoodsState
    }
    if self.CommonPrice == nil then
        self.CommonPrice = UIHandler.New(self, self.View.WBP_Shop_List_Information.WBP_CommonPrice, CommonPrice, Params).ViewInstance
    else
        self.CommonPrice:UpdateItemInfo(Params)
    end
end


function GoodsWidgetItem:UpdateGoodsInfo()
    if not CommonUtil.IsValid(self.View.WBP_Shop_List_Information.GUITextBlockName) then
        return
    end

    self.View.WBP_Shop_List_Information.GUITextBlockName:SetText(StringUtil.Format(self.ItemInfo.Name))    
    -- if UE.UGFUnluaHelper.IsEditor() then
    --     self.View.WBP_Shop_List_Information.GUITextBlockName:SetText(StringUtil.Format(self.ItemInfo.Name .. "(".. self.ItemInfo.GoodsId ..")"))
    -- end
    
    -- local Quality = self.ShopModel:GetGoodsQuality(self.ItemInfo.GoodsId)
    -- CommonUtil.SetTextColorFromQuality(self.View.WBP_Shop_List_Information.GUITextBlockName, Quality)
end

---品质
function GoodsWidgetItem:UpdateGoodsQualityImg()
    local Quality = self.ShopModel:GetGoodsQuality(self.ItemInfo.GoodsId)
    if CommonUtil.IsValid(self.View.Quality_Front) then
        CommonUtil.SetImageColorFromQuality(self.View.Quality_Front, Quality)
    end

    -- if CommonUtil.IsValid(self.View.Img_Goods_Bg) then
    --     -- CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageCurrency, self.ItemInfo.Icon)
    --     CommonUtil.SetImageColorFromQuality(self.View.Img_Goods_Bg, Quality)
    -- end

    -- if CommonUtil.IsValid(self.View.Quality_Behind) then
    --     CommonUtil.SetImageColorFromQuality(self.View.Quality_Behind, Quality)
    -- end
end

--- 更新限购次数
function GoodsWidgetItem:UpdateLimitTimes()
    if not CommonUtil.IsValid(self.View.WBP_Shop_List_Information.HBox_LimitTimes) then
        return
    end
    if not self.ItemInfo or self.ItemInfo.MaxLimitCount <= 0 then
        self.View.WBP_Shop_List_Information.HBox_LimitTimes:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.View.WBP_Shop_List_Information.HBox_LimitTimes:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    self.View.WBP_Shop_List_Information.GUITextBlockLimitTimes:SetText(
        StringUtil.Format(
            self.LimitTimesStr[self.ItemInfo.LimitCircle],
            self.ItemInfo.BuyTimes,
            self.ItemInfo.MaxLimitCount
        )
    )
    
    self.View.WBP_Shop_List_Information.GUITextBlockLimitTimesCur:SetText(tostring(self.ItemInfo.BuyTimes))
    self.View.WBP_Shop_List_Information.GUITextBlockLimitTimesTotal:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_6"),self.ItemInfo.MaxLimitCount))
    self.View.WBP_Shop_List_Information.GUITextBlockLimitTimesCur:Setvisibility(UE.ESlateVisibility.Collapsed)
    self.View.WBP_Shop_List_Information.GUITextBlockLimitTimesTotal:Setvisibility(UE.ESlateVisibility.Collapsed)
end

function GoodsWidgetItem:OnGoodsBuytimesChange()
    if not self.ItemInfo then
        return
    end
    self.ItemInfo = MvcEntry:GetModel(ShopModel):GetData(self.ItemInfo.GoodsId)
    self:UpdateLimitTimes()
    self:UpdatePrice()
end

function GoodsWidgetItem:ON_GOODS_INFO_CHANGE_Func()
    if not self.ItemInfo then
        return
    end
    self.ItemInfo = MvcEntry:GetModel(ShopModel):GetData(self.ItemInfo.GoodsId)
    self:UpdateLimitTimes()
    self:UpdatePrice()
end

--- 更新限购时间
function GoodsWidgetItem:UpdateLeftTime()
    if not CommonUtil.IsValid(self.View.WBP_Shop_LimitedTime_Mark) then
        return
    end

    if self.ItemInfo.SellBeginTime <= 0 and self.ItemInfo.SellEndTime <= 0 then
        self.View.WBP_Shop_LimitedTime_Mark:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end

    local NowTimeStamp = GetTimestamp()
    if NowTimeStamp < self.ItemInfo.SellBeginTime then
        CWaring("[GoodsWidgetItem] UpdateLeftTime this Goods can not be on sell!")
        return
    end
    self.View.WBP_Shop_LimitedTime_Mark:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:ScheduleCheckTimer()
    self:CheckLeftTime()
end

function GoodsWidgetItem:CheckLeftTime()
    if not(CommonUtil.IsValid(self.View.WBP_Shop_LimitedTime_Mark)) then
        return
    end

    if self.ItemInfo.SellBeginTime <= 0 and self.ItemInfo.SellEndTime <= 0 then
        return
    end
    local NowTimeStamp = GetTimestamp()
    local LeftTime = self.ItemInfo.SellEndTime - NowTimeStamp
    self.View.WBP_Shop_LimitedTime_Mark.GUITextBlockLeftTime:SetText(StringUtil.FormatLeftTimeShowStr(LeftTime, G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Getofftheshelfafter"), G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Offtheshelf")))

    local Hex = "#F5EFDFFF"
    if LeftTime < 24 * 60 * 60 then
        Hex = UIHelper.HexColor.Red
    end
    -- CommonUtil.SetTextColorFromeHex(self.View.GUITextBlockLeftTime, Hex)
    -- CommonUtil.SetImageColorFromHex(self.View.GUIImage_Time, Hex)
    CommonUtil.SetTextColorFromeHex(self.View.WBP_Shop_LimitedTime_Mark.GUITextBlockLeftTime, Hex)
    CommonUtil.SetImageColorFromHex(self.View.WBP_Shop_LimitedTime_Mark.GUIImage_Time, Hex)

    if LeftTime < 0 or NowTimeStamp < self.ItemInfo.SellBeginTime then
        self.ShopModel:SetDirtyByType(ShopModel.DirtyFlagDefine.TimeStateChanged, true)
        self:CleanAutoCheckTimer()
    end
end

-- 定时回调
function GoodsWidgetItem:OnSchedule()
    if not CommonUtil.IsValid(self.View) then
        self:CleanAutoCheckTimer()
        return
    end
    self:CheckLeftTime()
end

-- 定时检测
function GoodsWidgetItem:ScheduleCheckTimer()
    self:CleanAutoCheckTimer()
    self.CheckTimer =
        self:InsertTimer(
        self.AutoCheckTime,
        function()
            self:OnSchedule()
        end,
        true
    )
end

function GoodsWidgetItem:CleanAutoCheckTimer()
    if self.CheckTimer then
        self:RemoveTimer(self.CheckTimer)
    end
    self.CheckTimer = nil
end

--- 更新货币展示
function GoodsWidgetItem:UpdateCurrencyIcon()
    if not CommonUtil.IsValid(self.View.GUIImageCurrency) then
        return
    end

    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, self.ItemInfo.CurrencyType)
    if not CfgItem then
        return
    end
    CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageCurrency, CfgItem[Cfg_ItemConfig_P.IconPath])
end

--- 更新商品图片展示
function GoodsWidgetItem:UpdateIcon()
    if not CommonUtil.IsValid(self.View.GUIImageGoods) then
        return
    end

    --设置物品图片
    local SetGUIImageGoods = function()
        if (CommonUtil.IsValid(self.View.GUIImageWeapon)) then
            self.View.GUIImageWeapon:SetVisibility(UE.ESlateVisibility.Collapsed)
        end

        if not self.ItemInfo.Icon or self.ItemInfo.Icon == "" then
            self.View.GUIImageGoods:SetVisibility(UE.ESlateVisibility.Collapsed)
            return
        end
        self.View.GUIImageGoods:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageGoods, self.ItemInfo.Icon)
    end

    --设置武器图片
    local SetGUIImageWeapon = function()
        self.View.GUIImageGoods:SetVisibility(UE.ESlateVisibility.Collapsed)

        if not self.ItemInfo.Icon or self.ItemInfo.Icon == "" then
            self.View.GUIImageWeapon:SetVisibility(UE.ESlateVisibility.Collapsed)
            return
        end
    
        self.View.GUIImageWeapon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageWeapon, self.ItemInfo.Icon)
    end

    -- local GridType = self.ItemInfo.GridType
    -- if GridType == ShopDefine.GridType.Wider then
    --     --设置物品图片
    --     SetGUIImageGoods()
    -- else
    --     if not(CommonUtil.IsValid(self.View.GUIImageWeapon)) then
    --         --设置物品图片
    --         SetGUIImageGoods()
    --     else
    --         local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, self.ItemInfo.ItemId)
    --         local ItemType = ItemCfg[Cfg_ItemConfig_P.Type]
    --         if ItemType == Pb_Enum_ITEM_TYPE.ITEM_WEAPON then
    --             --设置武器图片
    --             SetGUIImageWeapon()
    --         else
    --             --设置物品图片
    --             SetGUIImageGoods()
    --         end
    --     end
    -- end

    if not(CommonUtil.IsValid(self.View.GUIImageWeapon)) then
        --设置物品图片
        SetGUIImageGoods()
    else
        local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, self.ItemInfo.ItemId)
        if ItemCfg then
            local ItemType = ItemCfg[Cfg_ItemConfig_P.Type]
            if ItemType == Pb_Enum_ITEM_TYPE.ITEM_WEAPON then
                --设置武器图片
                SetGUIImageWeapon()
            else
                --设置物品图片
                SetGUIImageGoods()
            end
        else
            --设置物品图片
            SetGUIImageGoods()  
        end
    end
end

--- 更新限定标记显示
function GoodsWidgetItem:UpdateSpecialMarkIcon()
    if not self.SpecialMark then
        return
    end

    ---@type CommonSpecialMarkParam
    local Param = {
        SpecialMarkText = self.ItemInfo.SpecialMarkText,
        SpecialMarkBg = self.ItemInfo.SpecialMarkIcon
    }
    self.SpecialMark:UpdataShow(Param)
end

function GoodsWidgetItem:BuyGoodsNow()
    -- CError("点击了购买页签按钮")
    if self.ItemInfo == nil or next(self.ItemInfo) == nil then
        CError("GoodsWidgetItem:BuyGoodsNow() self.ItemInfo == nil", true)
        return
    end

    MvcEntry:GetCtrl(ShopCtrl):RequestBuyShopItem(self.ItemInfo.GoodsId, 1)
    self:OnRedDotTrigger(RedDotModel.Enum_RedDotTriggerType.Click)
end

function GoodsWidgetItem:OnGoodsWidgetItemClicked()
    if self.ItemInfo == nil or next(self.ItemInfo) == nil then
        CError("GoodsWidgetItem:OnGoodsWidgetItemClicked() self.ItemInfo == nil", true)
        return
    end

    if self.ItemInfo.RechargeInfo then
        self:BuyGoodsNow()
    else
        --self:ReqEventTracking(EventTrackingModel.SHOP_ACTION.CLICK_ENTER_TO_CONTENT, self.ItemInfo.GoodsId, 1, self.Index > -1 and self.Index or self.ItemInfo.Prority, EventTrackingModel.SHOP_BUY_TYPE.NOT_BUY)
        MvcEntry:GetCtrl(ShopCtrl):OpenShopDetailView(self.ItemInfo.GoodsId)
        self:OnRedDotTrigger(RedDotModel.Enum_RedDotTriggerType.Click)
    end
end

function GoodsWidgetItem:ReqEventTracking(action, goodId, isShowInDetail, index, buyType)
    local eventTrackingData = {
        action = action,
        product_id = goodId,
        belong_product_id = 0,
        isShowInDetail = isShowInDetail,
        product_index = MvcEntry:GetModel(EventTrackingModel):GetItemIndexFromShopItemsIdTemp(goodId),
        buy_type = buyType
    }

    MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SHOP_EVENTTRACKING_CLICK, eventTrackingData)
end

--红点触发逻辑
function GoodsWidgetItem:OnRedDotTrigger(TriggerType)
    if not self.ItemInfo or not self.GoodRedDot then
        return
    end
    self.GoodRedDot:Interact(TriggerType)
end

function GoodsWidgetItem:RightMouseButtonReleased_Func()
    -- CError("GoodsWidgetItem:RightMouseButtonReleased_Func")

    if self.ItemInfo.GoodsId == self.ShopModel:GetLastOnUnHoverGoodsId() then
        --移动拖拽Widget
        local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
        -- local bIsUnder = UE.USlateBlueprintLibrary.IsUnderLocation(self.View.Img_Frame:GetCachedGeometry(), MousePos)
        local bIsUnder = UE.USlateBlueprintLibrary.IsUnderLocation(self.View:GetCachedGeometry(), MousePos)

        if bIsUnder then
            self:InsertTimer(Timer.NEXT_FRAME, function()
                -- CError("GoodsWidgetItem:RightMouseButtonReleased_Func Next")
                if not(CommonUtil.IsValid(self.View)) or not(self.View:IsVisible()) then
                    CWaring(string.format("GoodsWidgetItem:RightMouseButtonReleased_Func, not Valid !! or no IsVisible !!"))
                    return
                end

                local VisibilityVal = self.View:GetVisibility()
                if VisibilityVal == UE.ESlateVisibility.Collapsed or VisibilityVal == UE.ESlateVisibility.Hidden then
                    CWaring(string.format("GoodsWidgetItem:RightMouseButtonReleased_Func, GetVisibility !!"))
                    return
                end

                if self.ItemInfo.GoodsId ~= self.ShopModel:GetLastOnUnHoverGoodsId() then
                    CWaring(string.format("GoodsWidgetItem:RightMouseButtonReleased_Func, GoodsId=[%s] ~= GetLastOnUnHoverGoodsId=[%s] !!", tostring(self.ItemInfo.GoodsId), tostring(self.ShopModel:GetLastOnUnHoverGoodsId())))
                    return
                end

                local bOnHoverMark = MvcEntry:GetCtrl(ShopCtrl):GetTabListOnHoverMark()
                if bOnHoverMark then
                    CWaring(string.format("GoodsWidgetItem:RightMouseButtonReleased_Func, bOnHoverMark = [%s] !!", bOnHoverMark))
                    return 
                end

                self:BuyGoodsNow_Quick() 
            end, false)
        end
    end
end

-- function GoodsWidgetItem:OnMouseButtonDownEvent_Func(_,MyGeometry,MouseEvent)
--     CError("GoodsWidgetItem:OnMouseButtonDownEvent_Func 111")

--     local bIsRightMouseButton = UE.UKismetInputLibrary.PointerEvent_IsMouseButtonDown(MouseEvent, UE.EKeys.RightMouseButton)
--     if bIsRightMouseButton then
--         CError("GoodsWidgetItem:OnMouseButtonDownEvent_Func 222")
--     end
-- end


-- function GoodsWidgetItem:OnMouseButtonUpEvent_Func(_,MyGeometry,MouseEvent)
--     CError("GoodsWidgetItem:OnMouseButtonUpEvent_Func 111")

--     local bIsRightMouseButton = UE.UKismetInputLibrary.PointerEvent_IsMouseButtonDown(MouseEvent, UE.EKeys.RightMouseButton)
--     if bIsRightMouseButton then
--         CError("GoodsWidgetItem:OnMouseButtonUpEvent_Func 222")
--     end
-- end

return GoodsWidgetItem
