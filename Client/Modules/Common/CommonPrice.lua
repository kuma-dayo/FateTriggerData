--[[
    通用的CommonTips控件
    传值ItemId和具体的控件，进行自动取值展示
]]
local class_name = "CommonPrice"
CommonPrice = CommonPrice or BaseClass(nil, class_name)

---@class CommonPrice.DiscountStyle 折扣UI样式
CommonPrice.DiscountStyle = {
    ---默认样式
    Default = 0,
    --大的样式
    Large = 1
}

---@class CommonPrice.FreeStyle 免费UI样式
CommonPrice.FreeStyle = {
    ---默认样式:使用蓝图本来颜色
    Default = 0,
    ---黑色样式:
    Black = 1,
}

---@class CommonPriceParam
---@field CurrencyType ShopDefine.CurrencyType 货币类型
---@field SettlementSum SettlementSum
---@field DiscountStyle CommonPrice.DiscountStyle 折扣UI样式
---@field FreeStyle CommonPrice.FreeStyle 免费UI样式
---@field Price number 价格
---@field OriginPrice number 原价
---@field ExtShowPriceStr string 价格显示,此处不为空,价格显示此处字符串
---@field ExtShowPriceStrColor "E47A30" 额外显示文本的颜色
---@field GoodsState ShopDefine.GoodsState 商品状态
---@field JumpIDList TArray 跳转id列表
CommonPrice.Param = nil

function CommonPrice:OnInit()
    self.OriginColor = self.View.LbPrice.ColorAndOpacity
end

function CommonPrice:OnShow(Param)
    self:UpdateItemInfo(Param)
end

function CommonPrice:OnHide()
end

---@param Param CommonPriceParam
function CommonPrice:UpdateItemInfo(Param)
    if not Param then
        -- body
        CError("[CommonPrice]UpdateItemInfo param is nil")
        return
    end
    self.Param = Param
    self.Param.DiscountStyle = Param.DiscountStyle and Param.DiscountStyle or CommonPrice.DiscountStyle.Default
    self.Param.FreeStyle = Param.FreeStyle and Param.FreeStyle or CommonPrice.FreeStyle.Default
    self.NeedShowExtStr = (self.Param.ExtShowPriceStr ~= nil and self.Param.ExtShowPriceStr ~= "")
    self.Param.CurrencyType = self.Param.CurrencyType or 0
    self.Param.Price = self.Param.SettlementSum and self.Param.SettlementSum.TotalSettlementPrice or (self.Param.Price or 0)
    self.Param.OriginPrice = self.Param.SettlementSum and self.Param.SettlementSum.TotalSuggestedPrice or (self.Param.OriginPrice or 0)
    self.IsShowIcon = not self.NeedShowExtStr
    

    self.DiscountValue = 0
    if not self.NeedShowExtStr and self.Param.Price > 0 and self.Param.OriginPrice > 0 then
        -- 向下取整数
        -- self.DiscountValue = math.floor((self.Param.OriginPrice - self.Param.Price)/self.Param.OriginPrice * 100)
        if self.Param.SettlementSum then
            self.DiscountValue = self.Param.SettlementSum.Discount
        else
            self.DiscountValue = MvcEntry:GetCtrl(ShopCtrl):CalculateDiscount(self.Param.Price, self.Param.OriginPrice)
        end
    end
    self:UpdateItemShow()
end

function CommonPrice:UpdateCurrencyShow(GUICurrencyImage)
    if self.IsShowIcon then
        GUICurrencyImage:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        -- body
        local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, self.Param.CurrencyType)
        if not CfgItem then
            CError("[CommonPrice]UpdateCurrencyShow CurrencyType is nil")
            return
        end
        CommonUtil.SetBrushFromSoftObjectPath(GUICurrencyImage, CfgItem[Cfg_ItemConfig_P.IconPath])
    else
        GUICurrencyImage:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
end

function CommonPrice:UpdatePrice(CurPriceWidget, OriginPriceWidget, DiscountPersentWidget, DiscountPersentWidget_1)
    if CommonUtil.IsValid(CurPriceWidget) then
        CurPriceWidget:SetText(StringUtil.Format(self.Param.Price))
    end
    if CommonUtil.IsValid(OriginPriceWidget) then
        OriginPriceWidget:SetText(StringUtil.Format(self.Param.OriginPrice))
    end
    if CommonUtil.IsValid(DiscountPersentWidget) then
        DiscountPersentWidget:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_3"),self.DiscountValue))
    end
    if CommonUtil.IsValid(DiscountPersentWidget_1) then
        DiscountPersentWidget_1:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_3"),self.DiscountValue))
    end
end


function CommonPrice:UpdateItemShow()
    if self.NeedShowExtStr and self.Param.ExtShowPriceStr then
        if self.Param.GoodsState ~= nil then
            -- 这里是新逻辑
            if self.Param.GoodsState == ShopDefine.GoodsState.OutOfSell then
                -- 已售罄
                self.View.WidgetSwitcher:SetActiveWidget(self.View.ExtStr_1)
            elseif self.Param.GoodsState == ShopDefine.GoodsState.Have then
                -- 已拥有
                if CommonUtil.IsValid(self.View.LbExtStr) then
                    self.View.WidgetSwitcher:SetActiveWidget(self.View.ExtStr)
                    local Str = self.Param.ExtShowPriceStr
                    -- if self.Param.ExtShowPriceStrColor then
                    --     --这里代码不需要了,用蓝图重构给的颜色
                    --     CommonUtil.SetTextColorFromeHex(self.View.LbExtStr, self.Param.ExtShowPriceStrColor)
                    -- end
                    self.View.LbExtStr:SetText(StringUtil.Format(Str))
                end
            else
                if CommonUtil.IsValid(self.View.LbExtStr) then
                    self.View.WidgetSwitcher:SetActiveWidget(self.View.ExtStr)
                    local Str = self.Param.ExtShowPriceStr
                    -- if self.Param.ExtShowPriceStrColor then
                    --     CommonUtil.SetTextColorFromeHex(self.View.LbExtStr, self.Param.ExtShowPriceStrColor)
                    -- end
                    self.View.LbExtStr:SetText(StringUtil.Format(Str))
                end
            end
        else
            -- 这里是老逻辑
            self.View.WidgetSwitcher:SetActiveWidget(self.View.ExtStr)
            if CommonUtil.IsValid(self.View.LbExtStr) then
                local Str = self.Param.ExtShowPriceStr
                if self.Param.ExtShowPriceStrColor then
                    CommonUtil.SetTextColorFromeHex(self.View.LbExtStr,self.Param.ExtShowPriceStrColor)
                end
                self.View.LbExtStr:SetText(StringUtil.Format(Str))
            end
        end
    elseif self.DiscountValue > 0 then
        --折扣价格显示
        self.View.WidgetSwitcher:SetActiveWidget(self.View.Discount)
        self:UpdatePrice(self.View.LbPrice, self.View.LbOriginPrice, self.View.LbDiscountPersent_1)
        self:UpdateCurrencyShow(self.View.GUICurrencyImage)
        if CommonUtil.IsValid(self.View.WidgetSwitcher_Discount) then
            if self.Param.DiscountStyle == CommonPrice.DiscountStyle.Large then
                self.View.WidgetSwitcher_Discount:SetActiveWidget(self.View.Panel_Discount2)
            else
                self.View.WidgetSwitcher_Discount:SetActiveWidget(self.View.Panel_Discount1)
            end
        end
    elseif self.Param.Price == 0  then
        self:ShowJumpAndPrice()
    else
        self:ShowJumpAndPrice()
    end
end

---跳转与价格显示
function CommonPrice:ShowJumpAndPrice()
    
    if self.Param.JumpIDList ~= nil and self.Param.JumpIDList:Length() > 0 then
        --前往获取等...
        self.View.WidgetSwitcher:SetActiveWidget(self.View.Free)
        local strTip = MvcEntry:GetCtrl(ViewJumpCtrl):GetBtnName(self.Param.JumpIDList)
        self.View.LbNormalPrice_1:SetText(strTip)
        -- self.View.GUICurrencyImageNormal:SetVisibility(UE.ESlateVisibility.Collapsed)
        -- self.View.LbNormalPrice:SetText(StringUtil.FormatText(MvcEntry:GetCtrl(ViewJumpCtrl):GetBtnName(self.Param.JumpIDList)))
    elseif self.Param.Price == 0 then
        --免费节点
        self.View.WidgetSwitcher:SetActiveWidget(self.View.Free)
        self.View.LbNormalPrice_1:SetText(G_ConfigHelper:GetStrFromCommonStaticST("123"))--免费
        if self.View.ModifyFreeNodeColor then
            --调用蓝图函数修改 免费节点 的样式
            if self.Param.FreeStyle == CommonPrice.FreeStyle.Black  then
                self.View:ModifyFreeNodeColor(1)
            else
                self.View:ModifyFreeNodeColor(0)
            end
        end
    else
        --价格正常显示
        self.View.WidgetSwitcher:SetActiveWidget(self.View.Normal)
        self:UpdatePrice(self.View.LbNormalPrice)
        self:UpdateCurrencyShow(self.View.GUICurrencyImageNormal)
    end
end

return CommonPrice
