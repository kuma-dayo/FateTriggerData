local ActivityDefine = require("Client.Modules.Activity.ActivityDefine")
--- 视图控制器
local class_name = "ActivityMainMdt"
ActivityMainMdt = ActivityMainMdt or BaseClass(GameMediator, class_name)

function ActivityMainMdt:__init()
    self:ConfigViewId(ViewConst.ActivityMain)
end

function ActivityMainMdt:OnShow(data)
end

function ActivityMainMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.InputFocus = true
    self.MsgList =
    {
        {Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_TABLISTITEM_SELECT, Func = Bind(self, self.OnAcTabItemSelect)},
        {Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_ACTIVITYLIST_CHANGE, Func = Bind(self, self.OnAcListChange)},
        {Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_STATE_CHANGE, Func = Bind(self, self.OnAcListChange)},
    }

    self.BindNodes = {
        {UDelegate = self.WBP_ReuseListEx.OnUpdateItem, Func = Bind(self, self.OnUpdateItem)},
        { UDelegate = self.WBP_ReuseListEx.OnReloadFinish, Func = Bind(self, self.OnReloadFinish)},
    }

    ---@type ActivityModel
    self.Model = MvcEntry:GetModel(ActivityModel)

    UIHandler.New(self, self.CommonBtnTips_ESC, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnButtonClicked_Back),
        TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_PlayerInfoLayerMdt_return_Btn"),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })
    self.Widget2Item = {}

    self.CommonTabUpBarInstance = UIHandler.New(self,self.WBP_TabUpBar,CommonTabUpBar).ViewInstance

    self.CurSelAcId = 0
    self.LastSelAcId = 0
end

function M:OnAcListChange()
    self.InitSelectAcId = self.CurSelAcId
    self:FreshTabInfo(self.TabIndex)
    -- local AcTabList = self.Model:GetEntryAvailbleTabList(self.EntryId)
    -- if not AcTabList or #AcTabList == 0 then
    --     self:OnButtonClicked_Back()
    --     return
    -- end
    -- self.CurSelAcId = 0
    -- self:RefreshList(self.TabIndex)
end

function M:OnHide()
    self.EntryData = nil
    self.CurSelAcId = 0
    self.LastSelAcId = 0
    self.Widget2Item = nil
    self.OpenActivityMap = nil
end

function M:OnShow(AcParam)
    if not AcParam then
        return
    end
    self.EntryId = AcParam.EntryId
    self.InitSelectAcId = AcParam.ActivityId

    if AcParam and AcParam.JumpParam and AcParam.JumpParam:Length() > 0 then
        self.EntryId= tonumber(AcParam.JumpParam[1]) or 0
        self.InitSelectAcId = tonumber(AcParam.JumpParam[2]) or 0
    end

    ---@type EntryData
    self.EntryData = self.Model:GetEntryData(self.EntryId)
    if not self.EntryData then
        CError("M:InitTabInfo EntryData is nil, EntryId:"..self.EntryId)
        return
    end
    self:FreshTabInfo()
end

function M:FreshTabInfo(CurSelectId)
    local AcTabList = self.Model:GetEntryAvailbleTabList(self.EntryId)

    if not AcTabList then
        CWaring("M:FreshTabInfo AcTabList is nil, EntryId:"..self.EntryId)
        return
    end

    self.RedDotKey = "ActivityTab_"
    local TypeTabParam = {
        ClickCallBack = Bind(self, self.OnTypeBtnClick),
        -- CurSelectId = CurSelectId
    }
    TypeTabParam.ItemInfoList = {}

    for _, TabId in ipairs(AcTabList) do
        local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ActivityTabConfig, TabId)
        local TabItemInfo = {
            Id = TabId,
            LabelStr = Cfg[Cfg_ActivityTabConfig_P.TabText],
            TabIcon = Cfg[Cfg_ActivityTabConfig_P.TabIcon],
            RedDotKey = self.RedDotKey,
            RedDotSuffix = TabId,
        }
        TypeTabParam.ItemInfoList[#TypeTabParam.ItemInfoList + 1] = TabItemInfo
        if CurSelectId and CurSelectId == TabId then
            TypeTabParam.CurSelectId = CurSelectId
        end
    end

    self.TabIndex = 0
    -- self.TabListCls = UIHandler.New(self, self.WBP_TabUpBar.WBP_Common_TabUpBar_03, CommonMenuTabUp, TypeTabParam).ViewInstance
    self.CommonTabUpBarInstance:UpdateTabInfo(TypeTabParam)

    --MvcEntry:GetModel(RedDotModel):_Debug_PrintRedDotTree()
end

function M:InteractRedDot(TabId)
    local AcIDList = self.Model:GetTabAvailbleAcList(TabId)
    if AcIDList == nil then
        return
    end
    ---@type RedDotCtrl
    local RedDotCtrl = MvcEntry:GetCtrl(RedDotCtrl)
    for _, AcID in ipairs(AcIDList) do
        -- RedDotCtrl:Interact("ActivitySubItem_", self.SubData.SubItemId, RedDotModel.Enum_RedDotTriggerType.Click) 
        -- 注意:这里写死了ActivityType_
        RedDotCtrl:Interact("ActivityType_", AcID) 
    end
end


function M:OnTypeBtnClick(TabId, ItemInfo, IsInit)
    self.TabIndex = TabId
    self:CloseLastView(self.CurSelAcId)
    self.CurSelAcId = 0
    self:RefreshList(TabId)
    -- if not IsInit then
    --     self:InteractRedDot(TabId)
    -- end

    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ActivityTabConfig, TabId)
    if Cfg then
        self.CommonTabUpBarInstance:UpdateTitleText(Cfg[Cfg_ActivityTabConfig_P.TittleText])
    end
end

function M:RefreshCurrencyShow(CurrencyParam)
    if not CurrencyParam then
        return
    end
    -- if not self.CurrencyViewInstance then
    --     self.CurrencyViewInstance = UIHandler.New(self, self.WBP_TabUpBar.WBP_CommonCurrency, CommonCurrencyList, CurrencyParam).ViewInstance
    -- else
    --     self.CurrencyViewInstance:UpdateShowByParam(CurrencyParam)
    -- end
    self.CommonTabUpBarInstance:UpdateCurrency(CurrencyParam)
end

function M:RefreshList(TabId)
    self.DataList = self.Model:GetTabAvailbleAcList(TabId)
    print_r(self.DataList, "ActivityMainMdt RefreshList")
    if not self.DataList or #self.DataList < 1 then
        self.Root:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.WBP_ReuseListEx:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
    self.Root:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.WBP_ReuseListEx:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    if self.InitSelectAcId and self.InitSelectAcId > 0 and not table.contains(self.DataList, self.InitSelectAcId) then
        self.InitSelectAcId = 0
    end

    if not self.InitSelectAcId or self.InitSelectAcId == 0 then
        self.InitSelectAcId = self.DataList[1]
    end

    self.WBP_ReuseListEx:Reload(#self.DataList)
end

function M:OnReloadFinish()
    if self.InitSelectAcId == 0 then
        self.InitSelectAcId = self.CurSelAcId
    end
    self.Model:DispatchType(ActivityModel.ACTIVITY_TABLISTITEM_SELECT, self.InitSelectAcId)
    self.InitSelectAcId = 0
end

function M:CreateItem(Widget)
    local Item = self.Widget2Item[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, require("Client/Modules/Activity/ActivityTabListItem"))
        self.Widget2Item[Widget] = Item
    end
    return Item.ViewInstance
end

function M:OnUpdateItem(_, Widget, Index)
    local FixIndex = Index + 1
    local AcId = self.DataList[FixIndex]
    if AcId == nil then
        return
    end

    local TargetItem = self:CreateItem(Widget)
    if TargetItem == nil then
        return
    end
    TargetItem:SetData(AcId)
end

function M:OnAcTabItemSelect(_, AcId)
    if not AcId then
        CError("ActivityMainMdt OnAcTabItemSelect AcId is nil")
        return
    end

    if self.CurSelAcId == AcId then
        return
    end

    local LastSelAcId = self.CurSelAcId

    self.CurSelAcId = AcId

    ---@type table<number,number>
    self.OpenActivityMap = self.OpenActivityMap or {}

    local IsInit = self.OpenActivityMap[AcId] == nil
    if IsInit then
        self:InitUMGHandle(AcId, self.Root)
    end

    self:CloseLastView(LastSelAcId)

    self:ManualAcViewVisible(AcId, true)
    self.OpenActivityMap[AcId] = true

    -- if IsInit then
    --     MvcEntry:GetCtrl(ActivityCtrl):SendProtoPlayerGetActivityDataReq(AcId)
    -- end

    self.Model:RefreshBannerState(AcId)

    self.LastSelAcId = LastSelAcId

    local ViewParam = {
        ViewId = ViewConst.ActivityMain,
        TabId = AcId
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)

    local IconData = {
        icon_name = "活动" .. AcId,
        fct_type = ViewConst.ActivityMain,
        fct_tab = AcId,
        click_count = 1
    }

    MvcEntry:GetModel(EventTrackingModel):ReqIconClicked(IconData)
end

function M:CloseLastView(AcId)
    if not AcId or AcId <= 0 then
        return
    end
    self:ManualAcViewVisible(AcId, false)
    self.OpenActivityMap[AcId] = false
end
--- 初始化绑定数据
---@param Context table 上下文
function M:InitUMGHandle(AcId, OwnerWidget)
    ---@type ActivityData
    local Data = self.Model:GetData(AcId)

    if not Data then
        CError("ActivityMainMdt InitUMGHandle Data is nil AcId:"..AcId)
        return
    end

    if Data.Type == Pb_Enum_ACTIVITY_TYPE.ACTIVITY_TYPE_INVAILD then
        return
    end

    if not OwnerWidget then
        return
    end

    self.BindViewHandleList = self.BindViewHandleList or {}

    local BindViewHandle = self.BindViewHandleList[Data.ID]

    if BindViewHandle and BindViewHandle:IsValid() then
        return
    end

    ---@type ActivityUMGBinds
    local HandleBinds = ActivityDefine.ActivityUMGBinds[Data.Type]
    if not HandleBinds then
        return
    end

    if not HandleBinds.UMGPath or string.len(HandleBinds.UMGPath) == 0 then
        return
    end

    local WidgetClass = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(HandleBinds.UMGPath))
    if not CommonUtil.IsValid(WidgetClass) then
        CError(string.format("ActivityData:InitUMGHandle ,UE.UClass.Load Failed !!! UMGPath=[%s]",HandleBinds.UMGPath), true)
        return
    end

    local Widget = NewObject(WidgetClass, self)
    --OwnerWidget:AddChild(Widget)
    UIRoot.AddChildToPanel(Widget, OwnerWidget)
    self.BindViewHandleList[Data.ID] = UIHandler.New(self, Widget, HandleBinds.Script, {Id = Data.ID})
end

function M:ManualAcViewVisible(AcId, Show)
    ---@type ActivityData
    local Data = self.Model:GetData(AcId)

    if not Data then
        CError("ActivityMainMdt ManualAcViewVisible Data is nil AcId:"..AcId)
        return
    end

    if Data.Type == Pb_Enum_ACTIVITY_TYPE.ACTIVITY_TYPE_INVAILD then
        return
    end

    self.BindViewHandleList = self.BindViewHandleList or {}

    local BindViewHandle = self.BindViewHandleList[Data.ID]

    if not BindViewHandle or not BindViewHandle:IsValid() then
        return
    end

    if Show then
        self:RefreshCurrencyShow(Data.ShowCurrency)
        BindViewHandle:ManualOpen({Id = AcId})
    else
        BindViewHandle:ManualClose()
    end
end

function M:OnButtonClicked_Back()
    MvcEntry:CloseView(self.viewId)
    MvcEntry:CloseView(ViewConst.CommonItemTips)
end

return M
