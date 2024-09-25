--[[
    大厅 - 详情 - 捆绑包简介 - 目的提示单品在这个捆绑包中,会更加的优惠
]] -- require("Client.Modules.Shop.ShopDefine")

local class_name = "RecommendIntro"
RecommendIntro = RecommendIntro or BaseClass(nil, class_name)

-- ---@type GoodsItem
-- RecommendIntro.GoodsInfo = nil

-- RecommendIntro.LimitTimesStr = {
--     [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_INVALID] = "限购  {0}/{1}",
--     [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_DAY] = "每日限购  {0}/{1}",
--     [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_WEEK] = "每周限购  {0}/{1}",
--     [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_MONTH] = "每月限购  {0}/{1}",
--     [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_SEASON] = "每赛季限购  {0}/{1}",
--     [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_FOREVER] = "永久限购  {0}/{1}"
-- }

RecommendIntro.LimitTimesStr = {
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_INVALID] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_GoodsWidgetItem_BuyForLimit"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_DAY] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_GoodsWidgetItem_DayLimitBuy"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_WEEK] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_GoodsWidgetItem_WeekLimitBuy"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_MONTH] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_GoodsWidgetItem_MonthLimitBuy"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_SEASON] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_GoodsWidgetItem_SeasonLimitBuy"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_FOREVER] = G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_GoodsWidgetItem_longTimeLimitBuy")
}

--- 初始化
function RecommendIntro:OnInit()
    self.BindNodes = {
        {UDelegate = self.View.GUIButton.OnHovered, Func = Bind(self, self.OnHovered)},
        {UDelegate = self.View.GUIButton.OnUnHovered, Func = Bind(self, self.OnUnHovered)},
        {UDelegate = self.View.GUIButton.OnClicked, Func = Bind(self, self.OnClicked)}
    }

    self.MsgList = {
        { Model = ShopModel, MsgName = ShopModel.ON_GOODS_INFO_CHANGE, Func = Bind(self, self.ON_GOODS_INFO_CHANGE_Func) },
        { Model = ShopModel, MsgName = ShopModel.ON_GOODS_BUYTIMES_CHANGE, Func = Bind(self, self.OnGoodsBuytimesChange) },
    }

    ---@type ShopModel
    self.ShopModel = MvcEntry:GetModel(ShopModel)

    self.AutoCheckTime = 1
end

---@param Param any
function RecommendIntro:OnShow(Param)
    self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
end

--- 隐藏
function RecommendIntro:OnHide()
    self:CleanAutoCheckTimer()
    self.CallBackHandle = nil
    self.GoodsInfo = nil
end

function RecommendIntro:OnHovered()
    self.View.ImgHover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function RecommendIntro:OnUnHovered()
    self.View.ImgHover:SetVisibility(UE.ESlateVisibility.Collapsed)
end

--- 更新设置数据
---@param Param GoodsItem
function RecommendIntro:UpdateRecommendIntro(Param, cbHandle)
    -- CError(string.format("RecommendIntro:UpdateRecommendIntro(),Can't Find LinkPackGoods Info,Please Check ShopConfig !!!! GoodsId=[%s],LinkPackGoods=[%s].",Param.GoodsId,Param.LinkPackGoods))

    -- if not Param or Param.IsPackGoods then
    --     -- 1.传入的参数有误。2.传入的商品是捆绑包
    --     self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
    --     return
    -- end
    if not Param or Param.LinkPackGoods == nil or Param.LinkPackGoods <= 0 then
        -- 1.传入的参数有误。2.没有关联的捆绑包
        self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end

    self.GoodsInfo = self.ShopModel:GetData(Param.LinkPackGoods)
    if self.GoodsInfo == nil then
        -- 没有找到捆绑包信息
        CError(string.format("RecommendIntro:UpdateRecommendIntro(),Can't Find LinkPackGoods Info,Please Check ShopConfig !!!! GoodsId=[%s],LinkPackGoods=[%s].",Param.GoodsId,Param.LinkPackGoods))
        self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end

    self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    self:UpdateGoodsName()
    self:UpdateIcon()
    self:UpdateLimitTimes() -- 限购次数
    self:UpdateLeftTime() -- 限购时间
    self:UpdatePrice() -- 价格
    self:OnUnHovered()

    self.CallBackHandle = cbHandle
end

-- 更新礼包名称
function RecommendIntro:UpdateGoodsName()
    if not self.GoodsInfo then
        self.View.GUIText_GoodsName:SetText("")
        return
    end
    self.View.GUIText_GoodsName:SetText(StringUtil.Format(self.GoodsInfo.Name))

    --物品数目
    if self.GoodsInfo.PackGoodsIdList:Length() > 0 then
        -- 包含{0}个物品
        self.View.GUIText_GoodsNums:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_RecommendIntro_ContainNum"), self.GoodsInfo.PackGoodsIdList:Length()))
    else
        self.View.GUIText_GoodsNums:SetText(StringUtil.Format(""))
        -- self.View.GUIText_GoodsNums:SetText(StringUtil.Format("包含1个物品"))
        -- self.View.GUIText_GoodsNums:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_RecommendIntro_ContainNum"), 1))
    end
end

--- 更新商品图片展示
function RecommendIntro:UpdateIcon()
    if not CommonUtil.IsValid(self.View.GUIImageGoods) then
        return
    end

    if not self.GoodsInfo.Icon or self.GoodsInfo.Icon == "" then
        CError("RecommendIntro:UpdateIcon,self.GoodsInfo.Icon or self.GoodsInfo.Icon == \"\"!!!")
        self.View.GUIImageGoods:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.View.GUIImageGoods:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageGoods, self.GoodsInfo.Icon)
end

-- 更新礼包稀有度(暂无相关表现)
--[[
function RecommendIntro:UpdateGoodsQualityImg()
    local Quality = self.ShopModel:GetGoodsQuality(self.ItemInfo.GoodsId)
    if CommonUtil.IsValid(self.View.Quality_Front) then
        CommonUtil.SetImageColorFromQuality(self.View.Quality_Front, Quality)
    end
end
]] --

--- 商品信息发生变化
function RecommendIntro:ON_GOODS_INFO_CHANGE_Func()
    if not self.GoodsInfo then
        return
    end
    
    self:UpdateLimitTimes()
    self:UpdateLeftTime()
end

-- 更新礼包剩余时间
function RecommendIntro:OnGoodsBuytimesChange()
    if not self.GoodsInfo then
        return
    end
    
    self:UpdateLimitTimes()
    self:UpdateLeftTime()
end

--- 更新限购次数
function RecommendIntro:UpdateLimitTimes()
    -- if not self.GoodsInfo or self.GoodsInfo.MaxLimitCount <= 0 then
    --     self.View.LimitCount:SetText(StringUtil.Format(self.LimitTimesStr[self.GoodsInfo.LimitCircle], self.GoodsInfo.BuyTimes, self.GoodsInfo.MaxLimitCount))
    --     return
    -- end
    -- -- 限购次数
    -- self.View.LimitCount:SetText(StringUtil.Format(self.LimitTimesStr[self.GoodsInfo.LimitCircle], self.GoodsInfo.BuyTimes, self.GoodsInfo.MaxLimitCount))
end

function RecommendIntro:UpdatePrice()

    -- self.View.GUICurrencyImageNormal:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    -- 展示货币icon
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, self.GoodsInfo.CurrencyType)
    if not CfgItem then
        CError("[RecommendIntro]UpdatePrice CurrencyType is nil")
        return
    end
    CommonUtil.SetBrushFromSoftObjectPath(self.View.GUICurrencyImageNormal, CfgItem[Cfg_ItemConfig_P.IconPath])

    -- 展示价格
    ---@type ShopCtrl
    local ShopCtrl = MvcEntry:GetCtrl(ShopCtrl);

    ---@type SettlementSum
    local SettlementSum = ShopCtrl:GetGoodsPrice(self.GoodsInfo.GoodsId)
    -- local Price = SettlementSum.TotalSettlementPrice
    local OrginPrice = SettlementSum.TotalSuggestedPrice
    local TotalRealTimePrice = SettlementSum.TotalSettlementPrice

    -- local ExtShowPriceStr, ExtShowPriceStrColor = ShopCtrl:ConvertState2String(self.GoodsInfo.GoodsState)

    local DiscountValue = SettlementSum.Discount
    if DiscountValue > 0 then
        self.View.Overlay_Discount:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.GUIText_Discount:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_3"), DiscountValue))
    else
        self.View.Overlay_Discount:Setvisibility(UE.ESlateVisibility.Collapsed)
    end
  
    self.View.LbNormalPrice:SetText(TotalRealTimePrice)
    self.View.LbOriginPrice:SetText(OrginPrice)
end

---------------------
--- 更新限购时间
function RecommendIntro:UpdateLeftTime()
    -- print("RecommendIntro UpdateLeftTime")
    if self.GoodsInfo.SellBeginTime <= 0 and self.GoodsInfo.SellEndTime <= 0 then
        self.View.HorizontalBoxDate:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end

    local NowTimeStamp = GetTimestamp()
    if NowTimeStamp < self.GoodsInfo.SellBeginTime then
        CWaring("[RecommendIntro] UpdateLeftTime this Goods can not be on sell!")
        self.View.HorizontalBoxDate:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.View.HorizontalBoxDate:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.View.WidgetSwitcher_LeftDown:SetActiveWidget(self.View.HorizontalBoxDate)

    self:ScheduleCheckTimer()
    self:CheckLeftTime()
end

-- 设置限购时间数据
function RecommendIntro:CheckLeftTime()
    if self.GoodsInfo.SellBeginTime <= 0 and self.GoodsInfo.SellEndTime <= 0 then
        return
    end
    local NowTimeStamp = GetTimestamp()
    local LeftTime = self.GoodsInfo.SellEndTime - NowTimeStamp
    self.View.GUITextBlockLeftTime:SetText(StringUtil.FormatLeftTimeShowStr(LeftTime, G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_GoodsWidgetItem_SallDown"), G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_GoodsWidgetItem_SallBeenDown")))

    local Hex = "#F5EFDFFF"
    if LeftTime < 24 * 60 * 60 then
        Hex = UIHelper.HexColor.Red
    end
    CommonUtil.SetTextColorFromeHex(self.View.GUITextBlockLeftTime, Hex)
    CommonUtil.SetImageColorFromHex(self.View.GUIImage_Time, Hex)

    if LeftTime < 0 or NowTimeStamp < self.GoodsInfo.SellBeginTime then
        self.ShopModel:SetDirtyByType(ShopModel.DirtyFlagDefine.TimeStateChanged, true)
        self:CleanAutoCheckTimer()
    end
end

-- 定时回调(刷新限购时间数据)
function RecommendIntro:OnSchedule()
    if not CommonUtil.IsValid(self.View) then
        self:CleanAutoCheckTimer()
        return
    end
    self:CheckLeftTime()
end

-- 定时检测
function RecommendIntro:ScheduleCheckTimer()
    self:CleanAutoCheckTimer()
    self.CheckTimer = Timer.InsertTimer(self.AutoCheckTime, function()
        self:OnSchedule()
    end, true)
end

-- 删除定时器
function RecommendIntro:CleanAutoCheckTimer()
    if self.CheckTimer then
        Timer.RemoveTimer(self.CheckTimer)
    end
    self.CheckTimer = nil
end
---------------------

-- 点击当前礼包
function RecommendIntro:OnClicked()
    -- print("RecommendIntro OnRecommendWidgetItemClicked ")
    -- CError("-------------------- 点击当前礼包:::")

    -- MvcEntry:GetCtrl(ShopCtrl):OpenShopDetailView(self.GoodsInfo.GoodsId)
    self.CallBackHandle(self.GoodsInfo)

    -- if self.GoodsInfo and self.CallBack then
    --     self.CallBack(self.GoodsInfo, true)
    -- end
end

return RecommendIntro
