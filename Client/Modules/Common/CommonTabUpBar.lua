---@class CommonTabUpBar 蓝图 WBP_Common_TabUpBar_02

local class_name = "CommonTabUpBar"
CommonTabUpBar = BaseClass(UIHandlerViewBase, class_name)

function CommonTabUpBar:OnInit()
    self.BindNodes = {}
    self.MsgList = {}
end

---@class TabUpBarParam
---@field TitleTxt:string  标题
---@field CurrencyIDs:number 货币
---@field TabParam: table 参考 CommonMenuTabUp 参数

---@param InParam TabUpBarParam
function CommonTabUpBar:OnShow(InParam)
    self:RefreshUI(InParam)
end

---@param InParam TabUpBarParam
function CommonTabUpBar:OnManualShow(InParam)
    self:RefreshUI(InParam)
end

function CommonTabUpBar:OnManualHide(InParam)
end

function CommonTabUpBar:OnHide(InParam)
end

---@param InParam TabUpBarParam
function CommonTabUpBar:RefreshUI(InParam)
    InParam = InParam or {}
    -- 顶部标题
    self:UpdateTitleText(InParam.TitleTxt)
    -- 刷新货币展示
    self:UpdateCurrency(InParam.CurrencyIDs)
    -- 处理Tab栏，逻辑交由 CommonMenuTabUp 处理
    self:UpdateTabInfo(InParam.TabParam)
end

function CommonTabUpBar:UpdateTabInfo(TabParam)
    if not TabParam then
        self.View.TabPanel:SetVisibility(UE.ESlateVisibility.Collapsed) 
        return
    end
    self.View.TabPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) 
    if not self.MenuTabUpInstance then
        self.MenuTabUpInstance =  UIHandler.New(self,self.View.WBP_Common_TabUp_02,CommonMenuTabUp).ViewInstance
    end
    -- WBP_Common_TabUp_02 对应 ItemType 为2
    TabParam.TabItemType = CommonMenuTabUp.TabItemTypeEnum.TYPE2
    self.MenuTabUpInstance:UpdateUI(TabParam)
end

function CommonTabUpBar:SetTabVisibility(TheSlateVisibility)
    self.View.TabPanel:SetVisibility(TheSlateVisibility) 
end

-- 刷新顶部文字展示
---@param TitleText string 顶部标题文字
function CommonTabUpBar:UpdateTitleText(TitleText)
    if CommonUtil.IsValid(self.View) and CommonUtil.IsValid(self.View.Text_Sys) then
        TitleText = TitleText or ""
        self.View.Text_Sys:SetText(StringUtil.Format(TitleText))  
    end
  
end

-- 刷新货币展示
---@param CurrencyParams table 参考 CommonCurrencyList 参数
function CommonTabUpBar:UpdateCurrency(CurrencyParams)
    if not CurrencyParams then
        self.View.WBP_CommonCurrency:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.View.WBP_CommonCurrency:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if self.CurrencyViewInstance == nil or not(self.CurrencyViewInstance:IsValid()) then
        self.CurrencyViewInstance = UIHandler.New(self, self.View.WBP_CommonCurrency, CommonCurrencyList, CurrencyParams).ViewInstance
    else
        self.CurrencyViewInstance:UpdateShowByParam(CurrencyParams)
    end
end

function CommonTabUpBar:Switch2MenuTab(TabId,IsForceSelect)
    if not self.MenuTabUpInstance then
        return
    end
    self.MenuTabUpInstance:Switch2MenuTab(TabId,IsForceSelect)
end

function CommonTabUpBar:GetCurSelectID()
    if not self.MenuTabUpInstance then
        return 1
    end
    return self.MenuTabUpInstance.CurSelectTabId
end

return CommonTabUpBar
