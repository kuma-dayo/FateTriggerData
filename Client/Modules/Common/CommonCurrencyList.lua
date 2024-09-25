--[[
    通用的CommonCurrencyList控件
]] -- 
local class_name = "CommonCurrencyList"
CommonCurrencyList = CommonCurrencyList or BaseClass(nil, class_name)

function CommonCurrencyList:OnInit()

    self.bShowDetailState = false -- 详情UI的显示状态

    self.CurrencyWidgetList = {
        {self.View.SizeBox_1, self.View.GUIImage_1, self.View.LbCurrency_1, Handler = nil}, 
        {self.View.SizeBox_2, self.View.GUIImage_2, self.View.LbCurrency_2, Handler = nil}, 
        {self.View.SizeBox_3, self.View.GUIImage_3, self.View.LbCurrency_3, Handler = nil}
    }

    self.BindNodes = { 
            --{UDelegate = self.View.BtnCoin.OnClicked, Func = Bind(self, self.OnClicked_BtnCoin)},
            {UDelegate = self.View.BtnCoin.OnHovered, Func = Bind(self, self.OnHovered_BtnCoin)}, 
            {UDelegate = self.View.BtnCoin.OnUnHovered, Func = Bind(self, self.OnUnHovered_BtnCoin)}
        }

end

--- OnShow
---@param Params number[] 展示的货币类型数组 [ShopDefine.CurrencyType]
function CommonCurrencyList:OnShow(Params)
    if Params == nil then
        CWaring("CommonCurrencyList:OnShow() Params == nil !!!")
    end

    self:InitDetailNode()

    self:UpdateShowByParam(Params)
end

function CommonCurrencyList:OnHide()
    self.IDToWidgetInstance = nil
end

---@param Params number[] 展示的货币类型数组 [ShopDefine.CurrencyType]
function CommonCurrencyList:UpdateShowByParam(Params)
    Params = Params or {ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND}
    if not Params then
        return
    end

    for Index, WidgetList in ipairs(self.CurrencyWidgetList) do
        if Params[Index] then
            local CommonCurrencyTipParam = {
                ItemId = Params[Index],
                IconWidget = WidgetList[2],
                LabelWidget = WidgetList[3]
            }
            WidgetList[1]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)

            if not WidgetList.Handler then
                WidgetList.Handler = UIHandler.New(self, WidgetList[1], CommonCurrencyTip, CommonCurrencyTipParam)
            else
                WidgetList.Handler.ViewInstance:UpdateItemInfo(CommonCurrencyTipParam)
            end
        else
            WidgetList[1]:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
    end

    -- 更新详情信息
    self:UpdateCurrencyDetail(Params)
end

--- func 点击打开/关闭货币详情提示
function CommonCurrencyList:OnClicked_BtnCoin()
    if self.bShowDetailState then
        ---如果详情是打开的,则直接关闭
        self:HideDetail()
        return
    end

    self:ShowDetail()
end

function CommonCurrencyList:OnHovered_BtnCoin()
    self:ShowDetail()
end

function CommonCurrencyList:OnUnHovered_BtnCoin()
    self:HideDetail()
end

function CommonCurrencyList:HideDetail()
    self.bShowDetailState = false
    self.View.CurrencyDetail:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function CommonCurrencyList:ShowDetail()
    self.bShowDetailState = true
    self.View.CurrencyDetail:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)

    for _, WidgetInstance in pairs(self.IDToWidgetInstance) do
        WidgetInstance:UpdateCurrencyInfo()
    end
end

function CommonCurrencyList:InitDetailNode()
    --- 默认关闭详情UI
    self:HideDetail()
    self.View.WBP_CommonCurrency_DetailItem1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.View.WBP_CommonCurrency_DetailItem2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.View.WBP_CommonCurrency_DetailItem3:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

--- func 初始化详情里的UI
---@param Param any
function CommonCurrencyList:UpdateCurrencyDetail(Param)
    -- CError("初始化详情里的UI =",table.tostring(Param))

    if Param == nil or next(Param) == nil then
        -- 传进来的参数是空
        CError("CommonCurrencyList:UpdateCurrencyDetail() Param == nil", true)
        return
    end
    
    local bHasDiamond = false
    for _, ItemID in pairs(Param) do
        if ItemID == ShopDefine.CurrencyType.DIAMOND or ItemID == ShopDefine.CurrencyType.Gift_DIAMOND then
            bHasDiamond = true
            break
        end
    end

    self.IDToWidgetInstance = self.IDToWidgetInstance or {}
    local TempCount = 0
    local TempParam =  {ItemID = 0, bTheLast = false}
    for _, ItemID in pairs(Param) do
        TempParam.ItemID = ItemID
        if self.IDToWidgetInstance[ItemID] == nil then
            if ItemID == ShopDefine.CurrencyType.DIAMOND or ItemID == ShopDefine.CurrencyType.Gift_DIAMOND then
                TempParam.bTheLast = true
                self.View.WBP_CommonCurrency_DetailItem3:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
                self.IDToWidgetInstance[ItemID] = UIHandler.New(self, self.View.WBP_CommonCurrency_DetailItem3, require("Client.Modules.Common.CommonCurrencyDetailItem"), TempParam).ViewInstance
            else
                TempCount = TempCount + 1
                TempParam.bTheLast = (not(bHasDiamond) and TempCount >= 2) and true or false
                local WigetName = "WBP_CommonCurrency_DetailItem" .. tostring(TempCount)
                self.View[WigetName]:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
                self.IDToWidgetInstance[ItemID] = UIHandler.New(self, self.View[WigetName], require("Client.Modules.Common.CommonCurrencyDetailItem"), TempParam).ViewInstance
            end
        else
            if ItemID == ShopDefine.CurrencyType.DIAMOND or ItemID == ShopDefine.CurrencyType.Gift_DIAMOND then
                TempParam.bTheLast = true
                self.IDToWidgetInstance[ItemID]:UpdateItemInfo(TempParam)
            else
                TempCount = TempCount + 1
                TempParam.bTheLast = (not(bHasDiamond) and TempCount >= 2) and true or false
                self.IDToWidgetInstance[ItemID]:UpdateItemInfo(TempParam)
            end
        end
       
        -- self.IDToWidgetInstance[ItemID]:UpdateItemInfo(TempParam)
    end
end

return CommonCurrencyList
