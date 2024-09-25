--[[
    大厅 - 切页 - 商店
--]] --
require("Client.Modules.Shop.GoodsWidgetItem")
require("Client.Modules.Shop.GoodsWidgetItemList")
require("Client.Modules.Shop.ShopDefine")

local class_name = "HallTabShop"
local HallTabShop = BaseClass(UIHandlerViewBase, class_name)

local TabUIType = {
    Default = 0,
    FullScreen = 1
}

local EClickedArrowState = {
    None = 0,
    Left = 1,
    Right = 2
}

function HallTabShop:ResetData()
    self.CategoryCfgs = nil
    self.CategoryIDToIdx = nil
    self.Widget2Item = {}
    self.Widget2ItemLast = {}
    self.Tab2Widget = {} -- 商城左侧菜单页签ID对应是否全屏方式
    self.CurTabUIType = TabUIType.Default
    self.Tab2Item = {} -- 商城左侧菜单页签ID对应的UserWidget
    self.CurTabType = -1 -- 商城左侧菜单当前选中的页签ID
    self.CurSelectType = -1 -- 商城左侧菜单页签当前选中第几个页签
    self.LastSelectType = 0
    self.TabListCls = nil
    self.MaxTabListNum = 0 -- 商城左侧菜单页签数量
    self.CurSelectItem = -1
    self.LastSelectItem = -1
    self.CurSelectPositionItem = 1
    self.StartItemIndex = -1
    self.EndItemIndex = -1
    self.CurSelectGoodsId = -1
    self.IsPlayFinishAnim = false
    self.AutoCheckTime = 0
    self.ShopModel = nil
    self.InitSelectId = 0

    self.ShopRecommendHandler = nil
    self.CanPlayHoverAnim = true

    self.IsScrollUpOrDown = false --是否属于垂直滚动,用于阻挡垂直滚动时播放按钮动效
end

function HallTabShop:GetViewKey()
    return ViewConst.Hall * 100 + CommonConst.HL_SHOP
end

function HallTabShop:OnInit()
    CWaring("HallTabShop:OnInit")
    self:ResetData()

    ---@type ShopModel
    self.ShopModel = MvcEntry:GetModel(ShopModel)
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    self.BindNodes = {
        { UDelegate = self.View.WBP_ReuseListEx.OnUpdateItem, Func = Bind(self, self.OnUpdateItem) }, 
        { UDelegate = self.View.WBP_ReuseListEx.OnScrollItem, Func = Bind(self, self.OnScrollItem) }, 
        { UDelegate = self.View.WBP_ReuseListEx.ScrollBoxList.OnUserScrolled,Func = Bind(self, self.OnUserScrolled) }, 
        { UDelegate = self.View.WBP_ReuseListEx.OnPreUpdateItem, Func = Bind(self, self.OnPreUpdateItem) }, 
        -- { UDelegate = self.View.WBP_ReuseListEx.OnReloadFinish, Func = Bind(self, self.OnReloadFinish) }, 
        { UDelegate = self.View.WBP_ReuseListEx.OnListSizeChanged, Func = Bind(self, self.OnListSizeChanged) }, 
        { UDelegate = self.View.WBP_ReuseListEx_Last.OnUpdateItem, Func = Bind(self, self.OnUpdateItemLast) }, 
        { UDelegate = self.View.WBP_ReuseListEx_Last.OnPreUpdateItem, Func = Bind(self, self.OnPreUpdateItemLast) }, 
        { UDelegate = self.View.Btn_Left.GUIButton_Main.OnClicked, Func = Bind(self, self.OnLastClick) }, 
        { UDelegate = self.View.Btn_Right.GUIButton_Main.OnClicked, Func = Bind(self, self.OnNextClick) }, 
        { UDelegate = self.View.GUIButtonHover.OnHovered, Func = Bind(self, self.OnHovered) }, 
        { UDelegate = self.View.GUIButtonHover.OnUnHovered, Func = Bind(self, self.OnUnHovered) }, 
    }

    self.MsgList = {
        { Model = ShopModel, MsgName = ShopModel.ON_GOODS_INFO_CHANGE, Func = Bind(self, self.ON_GOODS_INFO_CHANGE_Func) },
        { Model = CommonModel, MsgName = CommonModel.ON_WIDGET_TO_FOCUS, Func = Bind(self, self.ON_WIDGET_TO_FOCUS_Fun) }, 
        { Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.MouseScrollUp), Func = Bind(self, self.OnMouseScrollUp) }, 
        { Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.MouseScrollDown), Func = Bind(self, self.OnMouseScrollDown) }, 
        { Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.W), Func = Bind(self, self.OnWClick) }, 
        { Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.A), Func = Bind(self, self.OnAClick) }, 
        { Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.S), Func = Bind(self, self.OnSClick) }, 
        { Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.D), Func = Bind(self, self.OnDClick) },
        -- { Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.SpaceBar), Func = Bind(self, self.OnSpaceBarClick) }
    }

    self.UIType2Widget = {
        [TabUIType.Default] = self.View.ReuseListRoot,
        -- [TabUIType.FullScreen] = self.View.MainTabContent
    }

    ---列表不响应鼠标滚轮事件
    self.View.WBP_ReuseListEx.ScrollBoxList:SetConsumeMouseWheel(UE.EConsumeMouseWheel.Never)
    self.View.WBP_ReuseListEx_Last.ScrollBoxList:SetConsumeMouseWheel(UE.EConsumeMouseWheel.Never)

    self.AutoCheckTime = CommonUtil.GetParameterConfig(ParameterConfig.ShopRefreshTime, 60)
    -- self.AutoCheckTime = 5
    self.View.WBP_ShopRecommend_Main:Setvisibility(UE.ESlateVisibility.Collapsed)

    self:InitShopTabInfo()
    self:InitHallTabShopScene()    
    self:InitCommonUI()

    -- 推荐页面:必须传false
    local RecommemdData = self.ShopModel:GetAvailableDataListByPageId(ShopDefine.RECOMMEND_PAGE, false)   
    ---@type RtGoodsItem[] 
    self.DataList = RecommemdData
end

function HallTabShop:OnShow(Param)
    CWaring("HallTabShop:OnShow, SSSSSSSSSSSSSSSSSSS ")

    self.ShopModel:DispatchType(ShopModel.ON_SHOW_HALLTABSHOP)
    self.ShopModel:DispatchType(ShopModel.ON_HIDE_HALLTABSHOP,{bShow = true}) 
    SoundMgr:PlaySound(SoundCfg.Music.MUSIC_SHOP)
    
    self.bNeedPlayOpenLSMark = true
    self:UpdateUI(Param)
    self:ScheduleCheckTimer()
end

function HallTabShop:OnManualShow(Param)
    CWaring("HallTabShop:OnManualShow, SSSSSSSSSSSSSSSSSSS ")

    self.ShopModel:DispatchType(ShopModel.ON_SHOW_HALLTABSHOP)
    self.ShopModel:DispatchType(ShopModel.ON_HIDE_HALLTABSHOP,{bShow = true}) 
    SoundMgr:PlaySound(SoundCfg.Music.MUSIC_SHOP)

    self.bNeedPlayOpenLSMark = true
    self:UpdateUI(Param)
    self:ScheduleCheckTimer()
    self:ShowWBP_Common_TabUpBar_02()
end

function HallTabShop:OnManualHide(Param)
    CWaring("HallTabShop:OnManualHide, SSSSSSSSSSSSSSSSSSS")

    -- self.LastSelectType = 0
    self:CleanAutoCheckTimer()
    self:ClearSetIsPlayFinishAnimMarkTimer()

    self.View.TurnPageUp:UnbindAllFromAnimationFinished(self.View)
    self.View.TurnPageDown:UnbindAllFromAnimationFinished(self.View)

    self:ShowShopRecommend(false)

    self.ShopModel:DispatchType(ShopModel.ON_HIDE_HALLTABSHOP)
end

function HallTabShop:OnHide(Param,MvcParam)
    CWaring("HallTabShop:OnHide, SSSSSSSSSSSSSSSSSSS ")

    self.LastSelectType = 0
    self:ClearSetIsPlayFinishAnimMarkTimer()
    self:CleanAutoCheckTimer()
    self:ResetData()
end

-----------------------------------------------------------------------左侧商城页签逻辑处理:初始化 >>

function HallTabShop:ClearPlayOpenLSMark()
    self.bNeedPlayOpenLSMark = false
end


function HallTabShop:InitCategoryCfgs()
    self.CategoryIDToIdx = {}
    self.CategoryCfgs = {}
    -- 商城tab页签配置,并且已经排序了,从小到大排序
    local CategoryCfgs = G_ConfigHelper:GetDict(Cfg_ShopCategoryConfig) or {}
    for key, Cfg in pairs(CategoryCfgs) do
        if Cfg[Cfg_ShopCategoryConfig_P.IsShow] then
            table.insert(self.CategoryCfgs, Cfg)
        end
    end

    table.sort(self.CategoryCfgs, function(Cfg1, Cfg2)
        return (Cfg1[Cfg_ShopCategoryConfig_P.SortIdx] or 0) < (Cfg2[Cfg_ShopCategoryConfig_P.SortIdx] or 0)
    end)

    for idx, CCfg in pairs(self.CategoryCfgs) do
        self.CategoryIDToIdx[CCfg[Cfg_ShopCategoryConfig_P.CategoryId]] = idx
    end
end

--初始化商城左侧Tab表
function HallTabShop:InitShopTabInfo()
    if self.TabListCls and self.TabListCls:IsValid() then
        return
    end

    self:InitCategoryCfgs()

    local CategoryNum = table_leng(self.CategoryCfgs)
    local UITabWidgets = self.View.MenuTabs:GetAllChildren()
    local UITabNum = table_leng(UITabWidgets)
    if UITabNum < CategoryNum then
        CWaring("HallTabShop:InitShopTabInfo() UITabNum < CategoryNum !!")
    end

    local ItemInfoList = {}
    local CCfg = nil
    for idx = 1, UITabNum, 1 do
        if idx <= CategoryNum then
            CCfg = self.CategoryCfgs[idx]

            local TabItemInfo = {
                -- Id = CCfg[Cfg_ShopCategoryConfig_P.CategoryId],
                Id = idx,
                Widget = UITabWidgets[idx],
                LabelStr = CCfg[Cfg_ShopCategoryConfig_P.CategoryName],
                TabIcon = CCfg[Cfg_ShopCategoryConfig_P.TabIcon]
                --Item.RedDotKey = "MailTab_"
                --Item.RedDotSuffix = Cfg[Cfg_MailPageConfig_P.PageId]
            }

            ItemInfoList[idx] = TabItemInfo

            local UIType = CCfg[Cfg_ShopCategoryConfig_P.IsFull] and TabUIType.FullScreen or TabUIType.Default
            self.Tab2Widget[CCfg[Cfg_ShopCategoryConfig_P.CategoryId]] = UIType
            self.Tab2Item[CCfg[Cfg_ShopCategoryConfig_P.CategoryId]] = UITabWidgets[idx]

            UITabWidgets[idx]:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            CommonUtil.SetBrushFromSoftObjectPath(UITabWidgets[idx].TabIconNormal, TabItemInfo.TabIcon)
        else
            UITabWidgets[idx]:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
    self.MaxTabListNum = table_leng(self.Tab2Widget)

    local MenuTabParam = {
        CurSelectId = -1,
        ClickCallBack = Bind(self, self.OnTypeBtnClick),
        ValidCheck = Bind(self, self.TypeValidCheck),
        HideInitTrigger = true,
        ItemInfoList = ItemInfoList,
        -- IsOpenKeyboardSwitch = true
    }

    self.TabListCls = UIHandler.New(self, self.View.MenuTabs, CommonMenuTab, MenuTabParam).ViewInstance
end
-----------------------------------------------------------------------左侧商城页签逻辑处理:初始化 <<

function HallTabShop:InitCommonUI()
    if CommonUtil.IsValid(self.View.CommonBtnTips_Purchase) then
        self.View.CommonBtnTips_Purchase:SetVisibility(UE.ESlateVisibility.Visible)
        --右键购买
        UIHandler.New(self, self.View.CommonBtnTips_Purchase, WCommonBtnTips, {
            OnItemClick = nil,
            CommonTipsID = CommonConst.CT_BUY,
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
            ActionMappingKey = ActionMappings.RightMouseButtonTap
        })
    end

    --esc退出
    UIHandler.New(self, self.View.CommonBtnTips_ESC, WCommonBtnTips, {
        OnItemClick = Bind(self, self.OnEscClicked),
        CommonTipsID = CommonConst.CT_ESC,
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
        ActionMappingKey = ActionMappings.Escape
    })

    self:ShowWBP_Common_TabUpBar_02()

    -- 商城合规功能
    self:ShowShopCompliant()
end

--- 商城合规功能
function HallTabShop:ShowShopCompliant()
    if ShopDefine.OPEN_ShopCompliant then
        UIHandler.New(self, self.View.WBP_ShopCompliant, require("Client.Modules.Shop.ShopCompliant"))
        self.View.WBP_ShopCompliant:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    else
        self.View.WBP_ShopCompliant:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function HallTabShop:ShowWBP_Common_TabUpBar_02()
    if CommonUtil.IsValid(self.View.WBP_Common_TabUpBar_02) then
        self.View.WBP_Common_TabUpBar_02:SetVisibility(UE.ESlateVisibility.Collapsed)
    end

    if CommonUtil.IsValid(self.View.WBP_CommonCurrency) then
        -- 商城货币栏
        if self.CommonCurrencyListIns == nil or not(self.CommonCurrencyListIns:IsValid()) then
            self.CommonCurrencyListIns = UIHandler.New(self, self.View.WBP_CommonCurrency, CommonCurrencyList, {ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND}).ViewInstance
        end
        self.View.WBP_CommonCurrency:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
end

--用来管理商城的场景相关的东西
function HallTabShop:InitHallTabShopScene()
    local Param = { Agent = self }
    if self.HallTabShopSceneIns == nil or not(self.HallTabShopSceneIns:IsValid()) then
        ---@type HallTabShopScene
        self.HallTabShopSceneIns = UIHandler.New(self, self.View.GUICanvasPanel_31, require("Client.Modules.Shop.HallTabShopScene"),Param).ViewInstance
    else
        self.HallTabShopSceneIns:ManualOpen(Param)
    end
end

--显示推荐页
function HallTabShop:ShowShopRecommend(bShow, RecommemdData)
    if bShow then
        local Param = {RecommemdData = RecommemdData, Agent = self, TabTypeID = ShopDefine.RECOMMEND_PAGE }
        if self.ShopRecommendHandler == nil or not(self.ShopRecommendHandler:IsValid()) then
            self.View.WBP_ShopRecommend_Main:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.ShopRecommendHandler = UIHandler.New(self, self.View.WBP_ShopRecommend_Main, require("Client.Modules.Shop.ShopRecommend"), Param)
        else
            self.ShopRecommendHandler:ManualOpen(Param)
        end
    else
        if self.ShopRecommendHandler and self.ShopRecommendHandler:IsValid() then
            self.ShopRecommendHandler:ManualClose()
        end
    end
end

function HallTabShop:UpdateUI(Param)
    -- self:TestDeubg_Editor(true)

    MvcEntry:GetCtrl(ShopCtrl):SetTabListOnHoverMark(false)

    self.IsPlayFinishAnim = false
    self.InitSelectId = 0
    local ShowTab = ShopDefine.RECOMMEND_PAGE
    if Param then
        if Param.TabType then
            ShowTab = Param.TabType
        end
        if Param.SelectId then
            self.InitSelectId = Param.SelectId
        end
    end

    local Idx = self.CategoryIDToIdx[ShowTab]
    self.ShopModel:SetCurTabIndex(Idx)
    self.CurSelectType = Idx

    self.TabListCls:OnTabItemClick(Idx, true, true)

    local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
    EventTrackingModel:SetShopEnterSource(EventTrackingModel:GetNowViewId())
end

-------------------------------------------------------------------------------定时刷新商城信息 >>
function HallTabShop:OnSchedule()
    if not CommonUtil.IsValid(self.View) then
        self:CleanAutoCheckTimer()
        return
    end
    MvcEntry:GetCtrl(ShopCtrl):CheckIsNeedRefreshByTime(true)
end

-- 定时检测社交信息状态
function HallTabShop:ScheduleCheckTimer()
    self:CleanAutoCheckTimer()
    self.CheckTimer = self:InsertTimer(self.AutoCheckTime, function()
        self:OnSchedule()
    end, true)
end

function HallTabShop:CleanAutoCheckTimer()
    if self.CheckTimer then
        self:RemoveTimer(self.CheckTimer)
    end
    self.CheckTimer = nil
end

-------------------------------------------------------------------------------定时刷新商城信息 <<

-------------------------------------------------------------------------------Input Event>>

function HallTabShop:HandleKeyMove(KeyType)
    self.View.IsMouseMode = false
    self.View:HandleModeMaskVisible()

    self.LastSelectItem = self.CurSelectItem
    if self.CurSelectItem < 0 then
        local FixIndex = self.StartItemIndex + 1
        local Data = self.DataList[FixIndex]

        if Data == nil or #(Data.Goods) < 1 then
            self.CurSelectPositionItem = 1
            self.CurSelectItem = -1
            if KeyType == ActionMappings.W then
                self:OnMouseScrollUp()
            end
            if KeyType == ActionMappings.S then
                self:OnMouseScrollDown()
            end
            return
        end
        self.CurSelectPositionItem = 1
        self.CurSelectItem = self.StartItemIndex
        self:HandleMoveOneGrid(self.CurSelectItem)
        ---@type GoodsItem[]
        local GoodsId = Data.Goods[1].GoodsId
        self.ShopModel:DispatchType(ShopModel.ON_SCROLL_CHANGE, {GoodsId = GoodsId, IsMouseMode = self.View.IsMouseMode})
        return
    end

    local FixIndex = self.CurSelectItem + 1
    local CurData = self.DataList[FixIndex]
    if KeyType == ActionMappings.W then
        if CurData == nil or #CurData.Goods < 2 or (#CurData.Goods == 2 and self.CurSelectPositionItem == 1) then
            ---向上翻页
            self.CurSelectPositionItem = 2
            self:OnMouseScrollUp()
            return
        end
        if self.CurSelectPositionItem == 2 then
            self.CurSelectPositionItem = 1
        end
    elseif KeyType == ActionMappings.S then
        if CurData == nil or #CurData.Goods < 2 or (#CurData.Goods == 2 and self.CurSelectPositionItem == 2) then
            ---向下翻页
            self.CurSelectPositionItem = 1
            self:OnMouseScrollDown()
            return
        end
        if self.CurSelectPositionItem == 1 then
            self.CurSelectPositionItem = 2
        end
    end

    local NextIndex = self.CurSelectItem
    if KeyType == ActionMappings.A then
        NextIndex = self.CurSelectItem - 1
    elseif KeyType == ActionMappings.D then
        NextIndex = self.CurSelectItem + 1
    end

    local NextData = self.DataList[NextIndex + 1]
    if NextData == nil then
        return
    end
    local NextGoods = NextData.Goods[self.CurSelectPositionItem]
    if NextGoods == nil then
        if self.CurSelectPositionItem == 2 then
            self.CurSelectPositionItem = 1
            NextGoods = NextData.Goods[self.CurSelectPositionItem]
        end
        if NextGoods == nil then
            return
        end
    end

    self.CurSelectItem = NextIndex
    local GoodsId = NextGoods.GoodsId

    local Delay = false
    if self.CurSelectItem <= self.StartItemIndex then
        self:HandleMoveOneGrid(self.CurSelectItem)
        Delay = true
    end
    if self.CurSelectItem >= self.EndItemIndex - 1 then
        self:HandleMoveOneGrid(self.CurSelectItem, true)
        Delay = true
    end

    if Delay then
        self:InsertTimer(-1, function()
            if self.ShopModel then
                self.ShopModel:DispatchType(ShopModel.ON_SCROLL_CHANGE, {GoodsId = GoodsId, IsMouseMode = self.View.IsMouseMode})
            end
        end)
    else
        self.ShopModel:DispatchType(ShopModel.ON_SCROLL_CHANGE, {GoodsId = GoodsId, IsMouseMode = self.View.IsMouseMode})
    end
end

function HallTabShop:OnWClick()
    self:HandleKeyMove(ActionMappings.W)
end

function HallTabShop:OnAClick()
    if self.View.WBP_ShopRecommend_Main:GetVisibility() == UE.ESlateVisibility.SelfHitTestInvisible then
        if self.ShopRecommendHandler and self.ShopRecommendHandler:IsValid() then
            self.ShopRecommendHandler.ViewInstance:OnAClick()
        end
        return
    end
    self:HandleKeyMove(ActionMappings.A)
end

function HallTabShop:OnSClick()
    self:HandleKeyMove(ActionMappings.S)
end

function HallTabShop:OnDClick()
    if self.View.WBP_ShopRecommend_Main:GetVisibility() == UE.ESlateVisibility.SelfHitTestInvisible then
        if self.ShopRecommendHandler and self.ShopRecommendHandler:IsValid() then
            self.ShopRecommendHandler.ViewInstance:OnDClick()
        end
        return
    end
    self:HandleKeyMove(ActionMappings.D)
end
-------------------------------------------------------------------------------Input Event<<

function HallTabShop:UpdateArrowShow(ClickedArrowVal)
    if not CommonUtil.IsValid(self.View) or not CommonUtil.IsValid(self.View.WBP_ReuseListEx) or not CommonUtil.IsValid(self.View.left) or not CommonUtil.IsValid(self.View.right) then
        return
    end
    ClickedArrowVal = ClickedArrowVal or EClickedArrowState.None
    if ClickedArrowVal ~= EClickedArrowState.None then
        self.View.left:SetVisibility(ClickedArrowVal == EClickedArrowState.Left and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.right:SetVisibility(ClickedArrowVal == EClickedArrowState.Right and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    else
        local Offset = self.View.WBP_ReuseListEx:GetScrollOffset()
        local MaxOffset = self.View.WBP_ReuseListEx:GetScrollOffsetOfEnd()
        local OffsetDiff = 10
        self.View.left:SetVisibility(Offset < OffsetDiff and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.right:SetVisibility(Offset > MaxOffset - OffsetDiff and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    end

    self:PlayDynamicEffectOnBtnLeftShow(ClickedArrowVal == EClickedArrowState.Left and false or true)
    self:PlayDynamicEffectOnBtnRightShow(ClickedArrowVal == EClickedArrowState.Right and false or true)
   
    self:UpdateArrowRedDotState()
end

function HallTabShop:PlayDynamicEffectOnBtnLeftShow(InIsOnShow)
    if self.IsScrollUpOrDown then
        return
    end
    local VisibleLeft = self.View.left:GetVisibility()
    if InIsOnShow then
        if VisibleLeft == UE.ESlateVisibility.Collapsed then
            if self.View.VXE_Hall_Shop_BTN_Left_In then
                self.View:VXE_Hall_Shop_BTN_Left_In()
            end
        end
    else
        if VisibleLeft == UE.ESlateVisibility.SelfHitTestInvisible then
            if self.View.VXE_Hall_Shop_BTN_Left_Out then
                self.View:VXE_Hall_Shop_BTN_Left_Out()
            end
        end
    end
end

function HallTabShop:PlayDynamicEffectOnBtnRightShow(InIsOnShow)
    if self.IsScrollUpOrDown then
        self.IsScrollUpOrDown = false
        return
    end
    local VisibleRight = self.View.right:GetVisibility()
    if InIsOnShow then
        if VisibleRight == UE.ESlateVisibility.Collapsed then
            if self.View.VXE_Hall_Shop_BTN_Right_In then
                self.View:VXE_Hall_Shop_BTN_Right_In()
            end
        end
    else
        if VisibleRight == UE.ESlateVisibility.SelfHitTestInvisible then
            if self.View.VXE_Hall_Shop_BTN_Right_Out then
                self.View:VXE_Hall_Shop_BTN_Right_Out()
            end
        end
    end
end

-- 更新红点状态
function HallTabShop:UpdateArrowRedDotState()
    -- 左箭头
    if self.StartItemIndex > -1 and self.View.left:GetVisibility() == UE.ESlateVisibility.SelfHitTestInvisible then
        ---@type RedDotModel
        local RedDotModel = MvcEntry:GetModel(RedDotModel)
        local wholeKey = RedDotModel:ContactKey("ShopTab_", self.CurTabType)
        local RedDotNode = RedDotModel:GetNodeWithKey(wholeKey)
        if not RedDotNode then
            return
        end

        local IsShowRedDot = false
        local FixIndex = self.StartItemIndex + 1
        for i = 1, FixIndex, 1 do
            local ItemInfo = self.DataList[i]
            if ItemInfo then
                local Goods = ItemInfo.Goods
                for i, GoodsId in ipairs(Goods) do
                    local wholeKey = RedDotModel:ContactKey("ShopTabItem_", GoodsId)
                    local RedDotNode = RedDotModel:GetNodeWithKey(wholeKey)
                    if RedDotNode then
                        IsShowRedDot = true
                        break
                    end
                end
                if IsShowRedDot then
                    break
                end
            end
        end
        -- todo 设置红点状态
    end

    -- 右箭头
    if self.EndItemIndex > -1 and self.View.right:GetVisibility() == UE.ESlateVisibility.SelfHitTestInvisible then
        ---@type RedDotModel
        local RedDotModel = MvcEntry:GetModel(RedDotModel)
        local wholeKey = RedDotModel:ContactKey("ShopTab_", self.CurTabType)
        local RedDotNode = RedDotModel:GetNodeWithKey(wholeKey)
        if not RedDotNode then
            return
        end

        local IsShowRedDot = false
        local FixIndex = self.EndItemIndex - 1
        for i = FixIndex, #self.DataList, 1 do
            local ItemInfo = self.DataList[i]
            if ItemInfo then
                local Goods = ItemInfo.Goods
                for i, GoodsId in ipairs(Goods) do
                    local wholeKey = RedDotModel:ContactKey("ShopTabItem_", GoodsId)
                    local RedDotNode = RedDotModel:GetNodeWithKey(wholeKey)
                    if RedDotNode then
                        IsShowRedDot = true
                        break
                    end
                end
                if IsShowRedDot then
                    break
                end
            end
        end
        -- todo 设置红点状态
    end
end

function HallTabShop:HandleMoveOneGrid(Idx, IsRight)
    local Size = self.View.WBP_ReuseListEx:GetItemSize(Idx)
    local Pos = self.View.WBP_ReuseListEx:GetItemPos(Idx)
    -- local Offset = self.View.WBP_ReuseListEx:GetScrollOffset()
    local ViewSize = self.View.WBP_ReuseListEx:GetViewSize()
    -- local ContentSize = self.View.WBP_ReuseListEx:GetContentSize()
    -- print(Size, Pos, Offset, ViewSize, ContentSize)
    local ItemInitPadding = self.View.WBP_ReuseListEx.ItemInitPadding
    self.View.WBP_ReuseListEx:SetScrollOffset(IsRight and (Pos + ItemInitPadding.X + Size - ViewSize.X) or (Pos - ItemInitPadding.X))
    self:UpdateArrowShow()
end

function HallTabShop:OnLastClick()
    -- local GroupSlotGeometry = self.View.WBP_ReuseListEx:GetCachedGeometry()
    -- local GroupSizeLoc = UE.USlateBlueprintLibrary.GetLocalSize(GroupSlotGeometry)
    -- self.View.WBP_ReuseListEx:SetScrollOffset(self.View.WBP_ReuseListEx:GetScrollOffset() - GroupSizeLoc.X)

    self.View.WBP_ReuseListEx:ScrollByIdxStyle(0, UE.EReuseListJumpStyle.Begin)
    self:UpdateArrowShow(EClickedArrowState.Left)
end

function HallTabShop:OnNextClick()
    -- local GroupSlotGeometry = self.View.WBP_ReuseListEx:GetCachedGeometry()
    -- local GroupSizeLoc = UE.USlateBlueprintLibrary.GetLocalSize(GroupSlotGeometry)
    -- self.View.WBP_ReuseListEx:SetScrollOffset(self.View.WBP_ReuseListEx:GetScrollOffset() + GroupSizeLoc.X)
    
    self.View.WBP_ReuseListEx:ScrollByIdxStyle(#(self.DataList)-1, UE.EReuseListJumpStyle.End)
    self:UpdateArrowShow(EClickedArrowState.Right)
end

function HallTabShop:OnMouseScrollUp()
    if MvcEntry:GetModel(InputModel):IsGamePadInput() then
        -- 策划需求当前版本，手柄输入不响应滚动
        return
    end
    if self.IsPlayFinishAnim then
        CWaring("HallTabShop:OnMouseScrollUp, self.IsPlayFinishAnim == true !!!!!")
        return
    end
    if self.CurSelectType - 1 < 1 then
        CWaring(string.format("HallTabShop:OnMouseScrollUp, self.CurSelectType - 1 < 1 !!!!! self.CurSelectType = %s", tostring(self.CurSelectType)))
        return
    end

    self.IsScrollUpOrDown = true
    self.ShopModel:SetCurTabIndex(self.CurSelectType - 1)
    self.TabListCls:OnTabItemClick(math.max(self.CurSelectType - 1, 1))
end

function HallTabShop:OnMouseScrollDown()
    if MvcEntry:GetModel(InputModel):IsGamePadInput() then
        -- 策划需求当前版本，手柄输入不响应滚动
        return
    end
    if self.IsPlayFinishAnim then
        CWaring("HallTabShop:OnMouseScrollDown, self.IsPlayFinishAnim == true !!!!!")
        return
    end
    if self.CurSelectType + 1 > self.MaxTabListNum then
        CWaring(string.format("HallTabShop:OnMouseScrollDown, self.CurSelectType + 1 > self.MaxTabListNum !!!!! self.CurSelectType = %s, self.MaxTabListNum = %s", tostring(self.CurSelectType), tostring(self.MaxTabListNum)))
        return
    end

    self.IsScrollUpOrDown = true
    self.ShopModel:SetCurTabIndex(self.CurSelectType + 1)
    self.TabListCls:OnTabItemClick(math.min(self.CurSelectType + 1, self.MaxTabListNum))
end

-------------------------------------------------------------------------------左侧商城页签逻辑处理:FadeIn,FadeOut >>
---OnHovered左侧Tab菜单
function HallTabShop:OnHovered()
    -- CError("HallTabShop:OnHovered")

    MvcEntry:GetCtrl(ShopCtrl):SetTabListOnHoverMark(true)
    for _, widget in pairs(self.Tab2Item) do
        widget.LbName:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    self:PlayDynamicEffectOnTabHover(true)
end

function HallTabShop:OnUnHovered()
    -- CError("HallTabShop:OnUnHovered")

    for _, widget in pairs(self.Tab2Item) do
        widget.LbName:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
    self:PlayDynamicEffectOnTabHover(false)

    self:InsertTimer(Timer.NEXT_FRAME, function()
        -- CError("HallTabShop:OnUnHovered Next")
        if CommonUtil.IsValid(self.View) and self.View:IsVisible() then
            MvcEntry:GetCtrl(ShopCtrl):SetTabListOnHoverMark(false)
        end
    end, false)
end

--[[
    播放显示退出动效
]]
function HallTabShop:PlayDynamicEffectOnTabHover(InIsOnTabHover)
    if InIsOnTabHover then
        if self.CanPlayHoverAnim then
            if self.View.VXE_Hall_Shop_Tab_Hover then
                self.View:VXE_Hall_Shop_Tab_Hover()
            end
        end
        self.CanPlayHoverAnim = false
    else
        if self.View.VXE_Hall_Shop_Tab_Unhover then
            self.View:VXE_Hall_Shop_Tab_Unhover()
        end
        self.CanPlayHoverAnim = true
    end
end
-------------------------------------------------------------------------------左侧商城页签逻辑处理:FadeIn,FadeOut <<

-------------------------------------------------------------------------------左侧商城页签逻辑处理 >>

function HallTabShop:SetShopTabType(CurTabType)
    self.CurTabType = CurTabType
    if self.HallTabShopSceneIns and self.HallTabShopSceneIns:IsValid() then
        self.HallTabShopSceneIns:SetShopTabType(self.CurTabType)
    end

    if CommonUtil.IsValid(self.View.CommonBtnTips_Purchase) then
        if self.CurTabType == ShopDefine.RECOMMEND_PAGE then
            self.View.CommonBtnTips_Purchase:Setvisibility(UE.ESlateVisibility.Collapsed)
        else
            self.View.CommonBtnTips_Purchase:Setvisibility(UE.ESlateVisibility.Visible)
        end
    end
end

function HallTabShop:HandleTabClickEvent(Index, ItemInfo, IsInit)
    -- if self.CurSelectType == Index then
    --    return
    -- end
    -- CError("---------- Index = "..tostring(Index))
    self.CurSelectType = Index
    self.ShopModel:SetCurTabIndex(Index)
    local ClickTabType = self.CategoryCfgs[Index][Cfg_ShopCategoryConfig_P.CategoryId]
    self:SetShopTabType(ClickTabType)
    self.CurTabUIType = self.Tab2Widget[self.CurTabType]
    self.View.GUICategoryName:SetText(ItemInfo.LabelStr)

    if self.CommonCurrencyListIns then
        if self.CurTabType == ShopDefine.Category.QuarterlyItem then
            self.CommonCurrencyListIns:UpdateShowByParam({ShopDefine.CurrencyType.SUPPLY_COUPON, ShopDefine.CurrencyType.DIAMOND})
        else
            self.CommonCurrencyListIns:UpdateShowByParam({ShopDefine.CurrencyType.Gold, ShopDefine.CurrencyType.DIAMOND})
        end
    end

    MvcEntry:GetCtrl(ShopCtrl):CheckIsNeedRefreshByTime()

    local bNeedPlaySwitchTabLS = true
    if self.CurTabType == ShopDefine.RECOMMEND_PAGE then
        bNeedPlaySwitchTabLS = not(self.bNeedPlayOpenLSMark)

        local RecommemdData = self.ShopModel:GetAvailableDataListByPageId(ShopDefine.RECOMMEND_PAGE, false);
        self:ShowShopRecommend(true, RecommemdData)

        self:UpdateTabShow(false)
    else
        self:UpdateTabInfo(IsInit)
        self:UpdateTabShow(true)

        self:ShowShopRecommend(false)
    end

    if bNeedPlaySwitchTabLS then
        self:PlaySwitchTabLS()
    end

    self.LastSelectType = self.CurSelectType
end


---左侧菜单页签被点击
---@param ItemInfo {Id:number,Widget:UUserWidget,LabelStr:string,TabIcon:string}
function HallTabShop:OnTypeBtnClick(Index, ItemInfo, IsInit)
    local ViewParam = {
        ViewId = ViewConst.Hall,
        TabId = CommonConst.HL_SHOP .. "-" .. Index,
        Name = "商店" ---埋点功能,必须中文显示
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)

    self:HandleTabClickEvent(Index, ItemInfo, IsInit)
end

function HallTabShop:TypeValidCheck(Type)
    return true
end

function HallTabShop:UpdateTabShow(bShow)
    if bShow then
        for UIType, Widget in pairs(self.UIType2Widget) do
            if CommonUtil.IsValid(Widget) then
                Widget:SetVisibility(self.CurTabUIType == UIType and UE.ESlateVisibility.Visible or UE.ESlateVisibility.Collapsed)    
            end
        end
    else
        for UIType, Widget in pairs(self.UIType2Widget) do
            if CommonUtil.IsValid(Widget) then
                Widget:SetVisibility(UE.ESlateVisibility.Collapsed)    
            end
        end
    end
end

function HallTabShop:UpdateTabInfo(IsInit)
    if self.CurTabUIType == TabUIType.FullScreen then
        -- --这里是什么逻辑？已经废弃？？
        -- self:RefreshMainDetailInfo()
        -- self:UpdateShowAvatar()

        -- 防止意外调用下面这个函数
        self:RefreshReuseListEx(IsInit)
    else
        self:RefreshReuseListEx(IsInit)
        -- self:OnHideAvatorInner()
    end
end

-- function HallTabShop:RefreshMainDetailInfo()
--     --这是什么逻辑？已经废弃？？先做安全处理，对 self.View.MainTabContent 做判断先
--     if self.View.MainTabContent then
--         self.ShopMainTabContentHandle = UIHandler.New(self, self.View.MainTabContent, GoodsWidgetItem).ViewInstance

--         ---@type RtGoodsItem[] 获取分页商品
--         self.DataList = self.ShopModel:GetAvailableDataListByPageId(self.CurTabType)
--         if #self.DataList <= 0 then
--             return
--         end
--         self.ShopMainTabContentHandle:SetData(self.DataList[1].Goods)
--     end
-- end
-------------------------------------------------------------------------------左侧商城页签逻辑处理 <<

----------------------------------------------------------------------列表处理逻辑滚动刷新 >>

function HallTabShop:ClearSetIsPlayFinishAnimMarkTimer()
    if self.SetIsPlayFinishAnimMarkTimer then
        self:RemoveTimer(self.SetIsPlayFinishAnimMarkTimer)
    end
    self.SetIsPlayFinishAnimMarkTimer = nil
end

---列表处理逻辑
function HallTabShop:RefreshReuseListEx(IsInit)
    -- print("sssssssssssssssIsInit=",IsInit)

    if not IsInit then
        self.LastDataList = self.DataList
        self.LastDataList = self.LastDataList or {}
        self.View.WBP_ReuseListEx_Last:Reload(#self.LastDataList)
        local Offset = self.View.WBP_ReuseListEx:GetScrollOffset()
        self.View.WBP_ReuseListEx_Last:SetScrollOffset(Offset)

        self.IsPlayFinishAnim = true
        
        local SetIsPlayFinishAnimMark = function()
            self.IsPlayFinishAnim = false
            self:ClearSetIsPlayFinishAnimMarkTimer()
        end

        local AniTimeLen = 0
        if self.LastSelectType > self.CurSelectType then
            AniTimeLen = self.View.TurnPageDown:GetEndTime()
            self.View:PlayAnimation(self.View.TurnPageDown)
            self.View.TurnPageDown:UnbindAllFromAnimationFinished(self.View)
            self.View.TurnPageDown:BindToAnimationFinished(self.View, function()
                SetIsPlayFinishAnimMark()
            end)
        else
            AniTimeLen = self.View.TurnPageUp:GetEndTime()
            self.View:PlayAnimation(self.View.TurnPageUp)
            self.View.TurnPageUp:UnbindAllFromAnimationFinished(self.View)
            self.View.TurnPageUp:BindToAnimationFinished(self.View, function()
                SetIsPlayFinishAnimMark()
            end)
        end

        self:ClearSetIsPlayFinishAnimMarkTimer()
        if self.SetIsPlayFinishAnimMarkTimer == nil then
            local DelayTime = AniTimeLen + 0.11
            self.SetIsPlayFinishAnimMarkTimer = self:InsertTimer(DelayTime, function()
                SetIsPlayFinishAnimMark()
            end, false)
        end
    end
    
    self.DataList = self.ShopModel:GetAvailableDataListByPageId(self.CurTabType, true)
    self.DataList = self.DataList or {}
    self.View.WBP_ReuseListEx:Reload(#self.DataList)
    self.View.WBP_ReuseListEx:ScrollToStart()
    self.View.WBP_ReuseListEx.ScrollBoxList:EndInertialScrolling()
    if self.View.IsMouseMode then
        self.CurSelectItem = -1
        self.CurSelectGoodsId = -1
        self.CurSelectPositionItem = 1
    end
    self:InsertTimer(0.1, function()
        if IsInit then
            if self.InitSelectId > 0 then
                local FoundIndex = -1
                for Index, v in ipairs(self.DataList) do
                    if v.Goods then
                        -- body
                        for _, GoodsItem in pairs(v.Goods) do
                            if GoodsItem.GoodsId == self.InitSelectId then
                                FoundIndex = Index - 1
                                break
                            end
                        end
                    end
                    if FoundIndex >= 0 then
                        break
                    end
                end
                if FoundIndex >= 0 then
                    self.CurSelectItem = FoundIndex
                    self.CurSelectGoodsId = self.InitSelectId
                    self.ShopModel:DispatchType(ShopModel.ON_SCROLL_CHANGE, {GoodsId = self.InitSelectId, IsMouseMode = self.View.IsMouseMode})
                    MvcEntry:GetCtrl(ShopCtrl):OpenShopDetailView(self.InitSelectId)
                    self.InitSelectId = 0
                end
            end
        else
            if not self.View.IsMouseMode then
                self.CurSelectItem = self:CalNextSelectItemWhenPageMove(self.LastSelectItem)
                self.CurSelectGoodsId = self:GetCurSelectGoodsId()
                self.ShopModel:DispatchType(ShopModel.ON_SCROLL_CHANGE, {GoodsId = self.CurSelectGoodsId, IsMouseMode = self.View.IsMouseMode})
            end
        end

        if self.CurSelectItem == self.EndItemIndex - 1 then
            self:HandleMoveOneGrid(self.CurSelectItem, true)
        else
            self:UpdateArrowShow()
        end
    end)
end

function HallTabShop:GetCurSelectGoodsId()
    if self.CurSelectItem == -1 then
        return
    end
    local FixIndex = self.CurSelectItem + 1
    local Data = self.DataList[FixIndex]
    if Data == nil then
        self.LastSelectItem = self.CurSelectItem
        self.CurSelectItem = #self.DataList - 1
        Data = self.DataList[#self.DataList]
    end

    if Data == nil then
        return
    end

    local GoodsId = 0
    if self.CurSelectPositionItem == 2 and #Data.Goods > 1 then
        GoodsId = Data.Goods[self.CurSelectPositionItem].GoodsId
    else
        self.CurSelectPositionItem = 1
        GoodsId = Data.Goods[1].GoodsId
    end
    return GoodsId
end

function HallTabShop:CalNextSelectItemWhenPageMove(SelectItem)
    local Size = self.View.WBP_ReuseListEx_Last:GetItemSize(SelectItem)
    local Pos = self.View.WBP_ReuseListEx_Last:GetItemPos(SelectItem)
    local Offset = self.View.WBP_ReuseListEx_Last:GetScrollOffset()
    -- local ViewSize = self.View.WBP_ReuseListEx_Last:GetViewSize()
    local RealPosFront = Pos - Offset
    local RealPosBehind = RealPosFront + Size
    -- print("============RealPosFront:",RealPosFront, "RealPosBehind:",RealPosBehind, SelectItem)
    local Max = -1
    local MaxIdx = -1
    for Idx = self.StartItemIndex, self.EndItemIndex - 1 do
        local TSize = self.View.WBP_ReuseListEx:GetItemSize(Idx)
        local TPos = self.View.WBP_ReuseListEx:GetItemPos(Idx)
        local TRealPosFront = TPos
        local TRealPosBehind = TRealPosFront + TSize
        -- print("============TRealPosFront:",TRealPosFront, "TRealPosBehind:",TRealPosBehind, Idx)
        local TArea = 0
        if TRealPosFront < RealPosFront and TRealPosBehind > RealPosBehind then
            TArea = Size
        elseif TRealPosFront > RealPosFront and TRealPosBehind < RealPosBehind then
            TArea = TSize
        elseif TRealPosFront <= RealPosBehind and TRealPosFront >= RealPosFront then
            TArea = RealPosBehind - TRealPosFront
        elseif TRealPosBehind >= RealPosFront and TRealPosBehind <= RealPosBehind then
            TArea = TRealPosBehind - RealPosFront
        end
        if TArea > Max then
            Max = TArea
            MaxIdx = Idx
        end
    end
    -- print("============SelectItem:",SelectItem, "MaxIdx:",MaxIdx)
    return MaxIdx
end

----------------------------------------------------------------------列表处理逻辑滚动刷新 <<

------------------------------------------------------------------------------WBP_ReuseListEx >>

function HallTabShop:OnScrollItem(_, Start, End)
    self.StartItemIndex = Start
    self.EndItemIndex = End
end

function HallTabShop:OnUserScrolled(Offset)
    self:UpdateArrowShow()
end

function HallTabShop:OnPreUpdateItem(_, Index)
    local FixIndex = Index + 1
    local Data = self.DataList[FixIndex]
    if Data ~= nil then
        if Data.GridType == ShopDefine.GridType.Big then
            self.View.WBP_ReuseListEx:ChangeItemClassForIndex(Index, ShopDefine.GridType.Big)
        elseif Data.GridType == ShopDefine.GridType.Wider then
            self.View.WBP_ReuseListEx:ChangeItemClassForIndex(Index, ShopDefine.GridType.Wider)
        else
            self.View.WBP_ReuseListEx:ChangeItemClassForIndex(Index, "")
        end
    end
end

function HallTabShop:OnListSizeChanged()
    -- 之前是在C++代码里大小变化内部调用reload。现在里面大小变化不调用了。手动调用后再更新箭头显示 @chenyishui
    self.View.WBP_ReuseListEx:Reload(#self.DataList)
    self:UpdateArrowShow()
end

--- func desc
---@param Widget any
---@param Data GoodsItem
function HallTabShop:CreateItem(Widget, Data)
    --CError("CreateItem,Widget="..UE.UKismetSystemLibrary.GetDisplayName(Widget))
    local Item = self.Widget2Item[Widget]
    if not Item then
        if Data.GridType == ShopDefine.GridType.Normal or Data.GridType == ShopDefine.GridType.None then
            Item = UIHandler.New(self, Widget, GoodsWidgetItemList)
        else
            Item = UIHandler.New(self, Widget, GoodsWidgetItem)
        end
        self.Widget2Item[Widget] = Item
    end
    return Item.ViewInstance
end

function HallTabShop:OnUpdateItem(_, Widget, Index)
    -- CError("ssssssssssssssssssss Index="..Index)
    local FixIndex = Index + 1
    ---@type RtGoodsItem
    local Data = self.DataList[FixIndex]
    if Data == nil then
        return
    end

    local TargetItem = self:CreateItem(Widget, Data)
    if TargetItem == nil then
        return
    end
    -- Data.Category = self.CurTabType
    if Data.GridType == ShopDefine.GridType.Normal or Data.GridType == ShopDefine.GridType.None then
        TargetItem:SetData(Data, Bind(self, self.OnItemSelect, Index), self.CurSelectGoodsId, self.CurTabType)
    elseif Data.Goods then
        TargetItem:SetData(Data.Goods[1], Bind(self, self.OnItemSelect, Index), self.CurSelectGoodsId, self.CurTabType)
    end

    local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
    local LastShopItemIndex = EventTrackingModel:GetShopItemLoadIndex()
    if Data.Goods then
        for _, ItemInfo in pairs(Data.Goods) do
            if not EventTrackingModel:IsIdExistInShopItemsIdTemp(ItemInfo.GoodsId, LastShopItemIndex + 1) then
                EventTrackingModel:SetShopItemLoadIndex(LastShopItemIndex + 1)
                local eventTrackingData = {
                    action = EventTrackingModel.SHOP_ACTION.DEFAULT_VIEW,
                    product_id = ItemInfo.GoodsId,
                    belong_product_id = 0,
                    isShowInDetail = 0,
                    product_index = EventTrackingModel:GetShopItemLoadIndex(),
                    buy_type = EventTrackingModel.SHOP_BUY_TYPE.NOT_BUY
                }

                EventTrackingModel:DispatchType(EventTrackingModel.ON_SHOP_EVENTTRACKING_CLICK, eventTrackingData)
            end
        end
    end
end

---@param Index number 控件ReuseListEx的第几个Item对象(0-n)
---@param GoodsId number 商品ID
function HallTabShop:OnItemSelect(Index, GoodsId, IsHovered)
    --CError("HallTabShop:OnItemSelect() ")
    if not self.View.IsMouseMode then
        return
    end
    if self.IsPlayFinishAnim and not IsHovered then
        return
    end
    if GoodsId == -1 then
        self.CurSelectItem = -1
    else
        self.LastSelectItem = self.CurSelectItem
        self.CurSelectItem = Index
        if not self.DataList then
            return
        end
        local FixIndex = self.CurSelectItem + 1
        local NextData = self.DataList[FixIndex]
        if NextData == nil then
            return
        end
        for i, GoodItem in ipairs(NextData.Goods) do
            if GoodItem.GoodsId == GoodsId then
                self.CurSelectPositionItem = i
            end
        end
    end
    self.ShopModel:DispatchType(ShopModel.ON_SCROLL_CHANGE, {GoodsId = GoodsId, IsMouseMode = self.View.IsMouseMode})
end

------------------------------------------------------------------------------WBP_ReuseListEx <<

------------------------------------------------------------------------------WBP_ReuseListEx_Last >>

function HallTabShop:OnPreUpdateItemLast(_, Index)
    local FixIndex = Index + 1
    local Data = self.LastDataList[FixIndex]
    if Data ~= nil then
        if Data.GridType == ShopDefine.GridType.Big then
            self.View.WBP_ReuseListEx_Last:ChangeItemClassForIndex(Index, ShopDefine.GridType.Big)
        elseif Data.GridType == ShopDefine.GridType.Wider then
            self.View.WBP_ReuseListEx_Last:ChangeItemClassForIndex(Index, ShopDefine.GridType.Wider)
        else
            self.View.WBP_ReuseListEx_Last:ChangeItemClassForIndex(Index, "")
        end
    end
end

--- func desc
---@param Widget any
---@param Data GoodsItem
function HallTabShop:CreateItemLast(Widget, Data)
    local Item = self.Widget2ItemLast[Widget]
    if not Item then
        if Data.GridType == ShopDefine.GridType.Normal or Data.GridType == ShopDefine.GridType.None then
            Item = UIHandler.New(self, Widget, GoodsWidgetItemList)
        else
            Item = UIHandler.New(self, Widget, GoodsWidgetItem)
        end
        self.Widget2ItemLast[Widget] = Item
    end
    return Item.ViewInstance
end

function HallTabShop:OnUpdateItemLast(_, Widget, Index)
    local FixIndex = Index + 1
    local Data = self.LastDataList[FixIndex]
    if Data == nil then
        return
    end
    local TargetItem = self:CreateItemLast(Widget, Data)
    if TargetItem == nil then
        return
    end
    if Data.GridType == ShopDefine.GridType.Normal or Data.GridType == ShopDefine.GridType.None then
        TargetItem:SetData(Data, nil)
    elseif Data.Goods then
        TargetItem:SetData(Data.Goods[1], nil)
    end
end

------------------------------------------------------------------------------WBP_ReuseListEx_Last <<


function HallTabShop:OnEscClicked()
    CommonUtil.SwitchHallTab(CommonConst.HL_PLAY)
end

-----------------------------------------------------------------------Avator Show >>

function HallTabShop:PlaySwitchTabLS()
    if self.HallTabShopSceneIns == nil or not(self.HallTabShopSceneIns:IsValid()) then
        return
    end

    local Param = {
        ToLSState = ShopDefine.ELSState.None
    }

    if self.CurSelectType == ShopDefine.RECOMMEND_PAGE then
        if self.bNeedPlayOpenLSMark then
            --第一次打开商城
            Param.ToLSState = ShopDefine.ELSState.RecommendOpen --这里不做播放LS的逻辑处理
        else
            --从其它页滚动到推荐页签
            Param.ToLSState = ShopDefine.ELSState.ScrollTabIn
            self.HallTabShopSceneIns:PlaySwitchTabLS(Param)
        end
    else
        if self.LastSelectType == ShopDefine.RECOMMEND_PAGE then
            --从推荐页滚动到其它页签
            Param.ToLSState = ShopDefine.ELSState.ScrollTabOut
        else
            --用来处理商城界面离开，然后又回到商城页的情况
            Param.ToLSState = ShopDefine.ELSState.RaffleLEDVisOff
        end
        self.HallTabShopSceneIns:PlaySwitchTabLS(Param)
    end
end

function HallTabShop:OnShowAvator(Param, IsNotVirtualTrigger)
    CWaring("HallTabShop:OnShowAvator, self.CurTabType =" .. tostring(self.CurTabType))

    if self.CurSelectType == ShopDefine.RECOMMEND_PAGE then
        if self.ShopRecommendHandler and self.ShopRecommendHandler:IsValid() then
            self.ShopRecommendHandler.ViewInstance:HandleOnShowAvator(Param, IsNotVirtualTrigger)
        end
    end

    if self.HallTabShopSceneIns and self.HallTabShopSceneIns:IsValid() then
        local Param2 = {
            CurTabType = self.CurTabType
        }
        self.HallTabShopSceneIns:HandleOnShowAvator(Param, IsNotVirtualTrigger, Param2)
    end

    if self.CurSelectType > 0 and self.CurSelectType ~= ShopDefine.RECOMMEND_PAGE then
        self:PlaySwitchTabLS()
    end
end

function HallTabShop:OnHideAvator(Param, IsNotVirtualTrigger)
    CWaring("HallTabShop:OnHideAvator(), self.CurTabType =" .. tostring(self.CurTabType))

    -- if self.CurSelectType == ShopDefine.RECOMMEND_PAGE then
    --     if self.ShopRecommendHandler and self.ShopRecommendHandler:IsValid() then
    --         self.ShopRecommendHandler.ViewInstance:HandleOnHideAvator(Param, IsNotVirtualTrigger)
    --     end
    -- end

    if self.HallTabShopSceneIns and self.HallTabShopSceneIns:IsValid() then
        local AuxParam = {
            CurTabType = self.CurTabType
        }
        self.HallTabShopSceneIns:HandleOnHideAvator(Param, IsNotVirtualTrigger, AuxParam)
    end
end

function HallTabShop:UpdateShowAvator(Param)
    CWaring(string.format("HallTabShop:UpdateShowAvator, Param = %s", table.tostring(Param)))

    if self.CurTabType == Param.TriggerTabTypeID then
        if self.HallTabShopSceneIns and self.HallTabShopSceneIns:IsValid() then
            local AuxParam = { 
                bNeedPlayOpenLSMark = false 
            }
            if self.CurSelectType == ShopDefine.RECOMMEND_PAGE then
                AuxParam.bNeedPlayOpenLSMark = self.bNeedPlayOpenLSMark 
            end

            self.HallTabShopSceneIns:UpdateShowAvator(Param, AuxParam)
        end
    end
end

function HallTabShop:UpdateHideAvator(Param)
    CWaring(string.format("HallTabShop:UpdateHideAvator, Param = %s", table.tostring(Param)))

    if self.HallTabShopSceneIns and self.HallTabShopSceneIns:IsValid() then
        self.HallTabShopSceneIns:UpdateHideAvator(Param)
    end
end

-----------------------------------------------------------------------Avator Show <<

--- 监听 商品信息修改
function HallTabShop:ON_GOODS_INFO_CHANGE_Func()
    -- CWaring("HallTabShop:ON_GOODS_INFO_CHANGE_Func , 监听 商品信息修改 !!")
end

--- 监听 UI 焦点切换
function HallTabShop:ON_WIDGET_TO_FOCUS_Fun(_, viewId)
    -- CError(string.format("监听 UI 焦点切换,Param =%s",tostring(viewId)))

    -------------------------------------------------------------------------------
    -- 需求变化,不需要此逻辑了
    -- --当商城界面重新获取焦点时,刷新UI数据
    -- if viewId == ViewConst.Hall then
    --     if self.CurTabType == ShopDefine.RECOMMEND_PAGE then
    --         local RecommemdData = self.ShopModel:GetAvailableDataListByPageId(ShopDefine.RECOMMEND_PAGE, false);
    --         self:ShowShopRecommend(true, RecommemdData)
    --     else
    --         self.DataList = self.ShopModel:GetAvailableDataListByPageId(self.CurTabType, true)
    --         self.DataList = self.DataList or {}
    --         self.View.WBP_ReuseListEx:Refresh()
    --         -- self.View.WBP_ReuseListEx:Reload(#self.DataList)
    --         -- self:UpdateTabInfo(nil)
    --         -- self.View.WBP_ReuseListEx:Reload(#self.DataList)
    --     end
    -- end
    -------------------------------------------------------------------------------
end

---UX同学要求帮输出一些参数
function HallTabShop:TestDeubg_Editor(bStart)
    if UE.UGFUnluaHelper.IsEditor() then
        if self.TestDugTimer then
            self:RemoveTimer(self.TestDugTimer)
        end
        
        self.TestDugTimer = nil
        if bStart then
            self.TestDugTimer = self:InsertTimer(0.5,function ()
                local DirectionalLightsArr = UE.TArray(UE.ADirectionalLight)
                -- local TagPostProcessVolume = PPTags[TagIndex] or ""
    
                UE.UGameplayStatics.GetAllActorsOfClass(self.View, UE.ADirectionalLight, DirectionalLightsArr)
                for k, DirLight in pairs(DirectionalLightsArr) do
                    -- DirLight
                    local Name = UE.UKismetSystemLibrary.GetDisplayName(DirLight)
                    local Intensity = DirLight.LightComponent.Intensity
    
                    CLog(string.format("HallTabShop:TestDeubg_Editor, Name=[%s],Intensity=[%s]",Name,Intensity))
                end
                -- self.View:DebugPrintDirLight()
            end,true)
        end
    end
end


return HallTabShop
