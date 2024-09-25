--[[
    大厅 - 切页 - 商店
]] 
--require("Client.Modules.Shop.ShopDefine")

local class_name = "RecommendWidgetItem"
RecommendWidgetItem = BaseClass(UIHandlerViewBase, class_name)

RecommendWidgetItem.LimitTimesStr = {
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_INVALID] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Restrictedpurchase"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_DAY] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Dailylimit"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_WEEK] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Weeklylimit"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_MONTH] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Monthlypurchaserestr"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_SEASON] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Limitedtoperseason"),
    [Pb_Enum_GOOD_REFRESH_TYPE.GOOD_REFRESH_TYPE_FOREVER] = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Permanentpurchaseres")
}

--- 初始化
function RecommendWidgetItem:OnInit()
    -- self.GoodsInfo = nil
    self.ShopModel = MvcEntry:GetModel(ShopModel)
    self.BindNodes = {
        -- { UDelegate = self.View.GUIButton.OnHovered,    Func = Bind(self, self.OnHovered)   }, 
        -- { UDelegate = self.View.GUIButton.OnUnHovered,  Func = Bind(self, self.OnUnHovered) }
    }

    self.MsgList = {
        { Model = ShopModel, MsgName = ShopModel.ON_GOODS_BUYTIMES_CHANGE, Func = Bind(self, self.OnGoodsBuytimesChange) },
        { Model = ShopModel, MsgName = ShopModel.ON_GOODS_INFO_CHANGE, Func = Bind(self, self.ON_GOODS_INFO_CHANGE_Func)  },
    }

    if CommonUtil.IsValid(self.View.GUIButton) then
        table.insert(
            self.BindNodes,
            {UDelegate = self.View.GUIButton.OnClicked, Func = Bind(self, self.OnRecommendWidgetItemClicked)}
        )
    end
    self.AutoCheckTime = 1
end
--- 设置数据
---@param Param GoodsItem
function RecommendWidgetItem:SetData(Param, CallBack, SelectGoodsData)
    if not Param then
        CWaring("[RecommendWidgetItem]SetData Param is nil!")
        self:SetSelect(false)
        return
    end
    self.GoodsInfo = Param
    self.CallBack = CallBack

    self:UpdateGoodsName()
    self:UpdateLimitTimes()
    self:UpdateLeftTime()
    self:UpdateIcon()
    self:OnUnHovered()
end

---@param Param any
function RecommendWidgetItem:OnShow(Param)
end

--- func 隐藏
function RecommendWidgetItem:OnHide()
    -- CError("RecommendWidgetItem:OnHide 隐藏")
    self:CleanAutoCheckTimer()
end

function RecommendWidgetItem:OnManualHide(Param)
    -- CError("RecommendWidgetItem:OnManualHide")
    self:CleanAutoCheckTimer()
end

function RecommendWidgetItem:OnHovered()
    -- if self.View.Hover then
    --     if not (self.bSelected) then
    --         self.View.Hover:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    --     end
    -- end
end

function RecommendWidgetItem:OnUnHovered()
    -- if self.View.Hover then
    --     self.View.Hover:SetVisibility(UE4.ESlateVisibility.Collapsed)
    -- end
end

function RecommendWidgetItem:SetSelect(Select)
    self.bSelected = Select
    if self.View.Select then
        self.View.Select:SetVisibility(Select and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)    
    end

    if self.bSelected then
        self:OnUnHovered()
    end
    
end

--更新礼包名称
function RecommendWidgetItem:UpdateGoodsName()
    if not self.GoodsInfo then
        self.View.RecommendName:SetText("")
        return
    end
    self.View.RecommendName:SetText(StringUtil.Format(self.GoodsInfo.Name))
end


--- 更新商品图片展示
function RecommendWidgetItem:UpdateIcon()
    if not CommonUtil.IsValid(self.View.GUIImageGoods) then
        return
    end

    if not self.GoodsInfo.Icon or self.GoodsInfo.Icon == "" then
        self.View.GUIImageGoods:SetVisibility(UE4.ESlateVisibility.Collapsed)
        return
    end
    self.View.GUIImageGoods:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageGoods, self.GoodsInfo.Icon)
end

--更新礼包稀有度(暂无相关表现)
--[[
function RecommendWidgetItem:UpdateGoodsQualityImg()
    local Quality = self.ShopModel:GetGoodsQuality(self.ItemInfo.GoodsId)
    if CommonUtil.IsValid(self.View.Quality_Front) then
        CommonUtil.SetImageColorFromQuality(self.View.Quality_Front, Quality)
    end
end
]]--
--更新礼包剩余时间
function RecommendWidgetItem:OnGoodsBuytimesChange()
    if not self.GoodsInfo then
        return
    end
    self.GoodsInfo = MvcEntry:GetModel(ShopModel):GetData(self.GoodsInfo.GoodsId)
    self:UpdateLimitTimes()
    self:UpdateLeftTime()
end

function RecommendWidgetItem:ON_GOODS_INFO_CHANGE_Func()
    if not self.GoodsInfo then
        return
    end
    self.GoodsInfo = MvcEntry:GetModel(ShopModel):GetData(self.GoodsInfo.GoodsId)
    self:UpdateLimitTimes()
    self:UpdateLeftTime()
end

--- 更新限购次数
function RecommendWidgetItem:UpdateLimitTimes()
    -- if not self.GoodsInfo or self.GoodsInfo.MaxLimitCount <= 0 then
    --     self.View.LimitCount:SetText(StringUtil.Format(
    --         self.LimitTimesStr[self.GoodsInfo.LimitCircle],
    --         self.GoodsInfo.BuyTimes,
    --         self.GoodsInfo.MaxLimitCount
    --     ))
    --     return
    -- end
    -- --限购次数
    -- self.View.LimitCount:SetText(
    --     StringUtil.Format(
    --         self.LimitTimesStr[self.GoodsInfo.LimitCircle],
    --         self.GoodsInfo.BuyTimes,
    --         self.GoodsInfo.MaxLimitCount
    --     )
    -- )

    if self.GoodsInfo == nil then
        self.View.LimitCount:SetText("")
        return
    end

    if self.GoodsInfo.MaxLimitCount <= 0 then
        -- local tipStr = StringUtil.Format(self.LimitTimesStr[self.GoodsInfo.LimitCircle], self.GoodsInfo.BuyTimes, self.GoodsInfo.MaxLimitCount)
        self.View.LimitCount:SetText("")
        return
    end

    local tipStr = StringUtil.Format(self.LimitTimesStr[self.GoodsInfo.LimitCircle], self.GoodsInfo.BuyTimes, self.GoodsInfo.MaxLimitCount)
    --限购次数
    self.View.LimitCount:SetText(tipStr)
end

--- 更新限购时间
function RecommendWidgetItem:UpdateLeftTime()
    if self.GoodsInfo == nil then
        return
    end
    -- print("RecommendWidgetItem UpdateLeftTime")
    if self.GoodsInfo.SellBeginTime <= 0 and self.GoodsInfo.SellEndTime <= 0 then
        self.View.HorizontalBoxDate:SetVisibility(UE4.ESlateVisibility.Collapsed)
        return
    end

    local NowTimeStamp = GetTimestamp()
    if NowTimeStamp < self.GoodsInfo.SellBeginTime then
        CWaring("[RecommendWidgetItem] UpdateLeftTime this Goods can not be on sell!")
        return
    end
    self.View.HorizontalBoxDate:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:ScheduleCheckTimer()
    self:CheckLeftTime()
end

--设置限购时间数据
function RecommendWidgetItem:CheckLeftTime()
    if self.GoodsInfo.SellBeginTime <= 0 and self.GoodsInfo.SellEndTime <= 0 then
        return
    end
    local NowTimeStamp = GetTimestamp()
    local LeftTime = self.GoodsInfo.SellEndTime - NowTimeStamp
    self.View.GUITextBlockLeftTime:SetText(StringUtil.FormatLeftTimeShowStr(LeftTime, G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Getofftheshelfafter"), G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_GoodsWidgetItem_Offtheshelf")))

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
function RecommendWidgetItem:OnSchedule()
    if not CommonUtil.IsValid(self.View) then
        self:CleanAutoCheckTimer()
        return
    end
    self:CheckLeftTime()
end

-- 定时检测
function RecommendWidgetItem:ScheduleCheckTimer()
    self:CleanAutoCheckTimer()

    self.CheckTimer = self:InsertTimer(self.AutoCheckTime, function()
        self:OnSchedule()
    end, true)

    -- self.CheckTimer =
    --     Timer.InsertTimer(
    --     self.AutoCheckTime,
    --     function()
    --         self:OnSchedule()
    --     end,
    --     true
    -- )
end

function RecommendWidgetItem:CleanAutoCheckTimer()
    if self.CheckTimer then
        -- Timer.RemoveTimer(self.CheckTimer)
        self:RemoveTimer(self.CheckTimer)
    end
    self.CheckTimer = nil
end

--点击当前礼包
function RecommendWidgetItem:OnRecommendWidgetItemClicked()
    --print("RecommendWidgetItem OnRecommendWidgetItemClicked ")
    if self.GoodsInfo and self.CallBack then
        self.CallBack(self.GoodsInfo, true)
    end
end

return RecommendWidgetItem