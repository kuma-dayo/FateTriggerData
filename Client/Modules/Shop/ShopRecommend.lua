--[[
    大厅 - 切页 - 商店 - 推荐页签
]] 
--require("Client.Modules.Shop.ShopDefine")
require("Client.Modules.Shop.RecommendWidgetItem")


local class_name = "ShopRecommend"
local ShopRecommend = BaseClass(UIHandlerViewBase, class_name)

ShopRecommend.MAX_SHOW_RECOMMEND_ITEMNUM = 4
ShopRecommend.SHOPRECOMMENDITEMSTATE = {
    UNHOVER = 1,
    SELECT = 2,
    UNSELECT = 3
}

function ShopRecommend:OnInit()
    self:ResetData()

    self.BindNodes = {
        { UDelegate = self.View.WBP_ReuseList.OnUpdateItem,Func = Bind(self, self.OnDetailUpdateItem) },
        { UDelegate = self.View.WBP_RecommendReuseListEx.OnUpdateItem, Func = Bind(self, self.OnUpdateItem) },
        { UDelegate = self.View.WBP_RecommendReuseListEx.OnScrollItem,Func = Bind(self, self.OnScrollItem) },
        -- {UDelegate = self.View.WBP_RecommendReuseListEx.OnPreUpdateItem,Func = Bind(self, self.OnPreUpdateItem)},
        -- {UDelegate = self.View.WBP_RecommendReuseListEx.OnReloadFinish,Func = Bind(self, self.OnReloadFinish)},
    }

    self.MsgList = {
        -- {Model = ShopModel, MsgName = ShopModel.HANDLE_SHOPBG_SHOW, Func = self.DetailPanelChanged},
        { Model = ShopModel, MsgName = ShopModel.ON_GOODS_BUYTIMES_CHANGE, Func = Bind(self, self.ON_GOODS_BUYTIMES_CHANGE_Func)  },
        { Model = ShopModel, MsgName = ShopModel.ON_GOODS_INFO_CHANGE, Func = Bind(self, self.ON_GOODS_INFO_CHANGE_Func) },
    }

    if CommonUtil.IsValid(self.View.WBP_CommonBtn_Cir_Small) then
        local BtnEvent = { UDelegate = self.View.WBP_CommonBtn_Cir_Small.GUIButton_Main.OnClicked, Func = Bind(self, self.OnGoodsWidgetItemClicked) }
        table.insert(self.BindNodes, BtnEvent)
    end

    if CommonUtil.IsValid(self.View.WBP_CommonBtn_Cir_Small_1) then
        local BtnEvent = { UDelegate = self.View.WBP_CommonBtn_Cir_Small_1.GUIButton_Main.OnClicked, Func = Bind(self, self.OnGoodsWidgetItemClicked) }
        table.insert(self.BindNodes, BtnEvent)
    end

    if CommonUtil.IsValid(self.View.GUIButton_Detail) then
        local BtnEvent = { UDelegate = self.View.GUIButton_Detail.GUIButton.OnClicked, Func = Bind(self, self.OnGoodsWidgetItemClicked) }
        table.insert(self.BindNodes, BtnEvent)
    end

    ---@type ShopModel
    self.ShopModel = MvcEntry:GetModel(ShopModel)
end

function ShopRecommend:ResetData()
    self.Widget2ItemHandler = {}           --单个推荐礼包Widget数据
    self.Widget2ItemIconCls = {}    --礼包详情页的Widget数据
    self.GoodsDataList = nil        --所有推荐礼包数据列表

    ---@type number 当前选中礼包(捆绑包)Index,即第几个捆绑包
    self.CurSelectIndex = -1
    ---@type GoodsItem 当前选中礼包(捆绑包)信息 
    self.SelectedGiftbagGoods = nil
    ---@type number 当前选中礼包(捆绑包)Id
    self.CurSelectGoodsId = -1      
    
    ---@type number 当前选中礼包(捆绑包)中的某个商品ID(捆绑包中有多个商品ID)
    self.SelectedGiftbagDetailGoodsId = 0 
    ---@type number 正在展示的当前选中礼包(捆绑包)中的某个商品ID(捆绑包中有多个商品ID)
    self.ShowAvatarGoodsId = -1

    self.StartItemIndex = -1
    self.EndItemIndex = -1
    self.bShowing = false

    self.DetailItemList = {}
    self.ItemIconClsToGoodsId = {}
    self.CurShowAvatar = nil
    self.BuyButtonIns = nil

    self.LastShopRecommendItemsState = {} --记录每个item上次触发Sel和Unsel状态
end

function ShopRecommend:ResetSelectData()
    self.CurSelectGoodsId = -1
    self.SelectedGiftbagGoods = nil   --当前选中商品信息
    self.CurSelectIndex = -1        --当前选中商品Index

    self.SelectedGiftbagDetailGoodsId = 0
    -- self.CurSelectDetailItemIndex = -1

    self.ShowAvatarGoodsId = -1
end

function ShopRecommend:RegiestShowAvatarFunc(ShowAvatarFunc)
    
end

function ShopRecommend:SetIntermediaryAgent(Agent)
    self.HallTabShopIns = Agent
end

---@param Param any
function ShopRecommend:OnShow(Param) 
    CWaring("ShopRecommend:OnShow, ::00000000")

    if Param == nil then
        CError("ShopRecommend:OnShow, Param == nil ,return", true)
        return
    end

    self.TabTypeID = Param.TabTypeID
    self:SetIntermediaryAgent(Param.Agent)
    self:UpdateUI(Param.RecommemdData)
end

function ShopRecommend:OnManualShow(Param)
    CWaring("ShopRecommend:OnManualShow, ::555555,Param=")

    if Param == nil then
        CError("ShopRecommend:OnManualShow, Param == nil ,return", true)
        return
    end

    self:UpdateUI(Param.RecommemdData)
end

function ShopRecommend:OnManualHide()
    CWaring("ShopRecommend:OnManualHide, ::666666666")

    self.bShowing = false
end

--- func 隐藏
function ShopRecommend:OnHide()
    CWaring("ShopRecommend:OnHide, ::2222222")

    self:OnHideAvatorInner()
    self:ResetData()
    self.bShowing = false
end

-- function ShopRecommend:OnShowAvator(Param, IsNotVirtualTrigger)
--     CError("ShopRecommend:OnShowAvator, ")
--     self:UpdateGoodsIconAndModel_Inner(self.SelectedGiftbagDetailGoodsId)
-- end

function ShopRecommend:OnHideAvator(Param, IsNotVirtualTrigger)
    CWaring("ShopRecommend:OnHideAvator, IsNotVirtualTrigger = " .. tostring(IsNotVirtualTrigger))

    self:OnHideAvatorInner()
end

function ShopRecommend:HandleOnShowAvator(Data, IsNotVirtualTrigger)
    CWaring("ShopRecommend:HandleOnShowAvator, IsNotVirtualTrigger = " .. tostring(IsNotVirtualTrigger))

    self:UpdateGoodsIconAndModel_Inner(self.SelectedGiftbagDetailGoodsId)
end

-- function ShopRecommend:HandleOnHideAvator(Data, IsNotVirtualTrigger)
--     CError("ShopRecommend:HandleOnHideAvator, IsNotVirtualTrigger = "..tostring(IsNotVirtualTrigger))
-- end

function ShopRecommend:OnHideAvatorInner()
    -- CError("ShopRecommend:OnHideAvatorInner  12")
    self.ShowAvatarGoodsId = 0

    local Param = { 
        GoodsId = self.SelectedGiftbagDetailGoodsId,
        TransparentViewId = self:GetViewKey(),
        ETranModuleID = ETransformModuleID.Shop_Recommend.ModuleID 
    }
    
    if self.HallTabShopIns then
        -- 更新模型
        self.HallTabShopIns:UpdateHideAvator(Param)
    end
end

function ShopRecommend:GetDefaultSelectIndex()
    if self.CurSelectIndex < 1 then
        self.CurSelectIndex = 1
    elseif self.CurSelectIndex > #(self.GoodsDataList) then
        self.CurSelectIndex = #(self.GoodsDataList)
    end
end

function ShopRecommend:UpdateUI(Param)
    if Param == nil then
        CError("ShopRecommend:UpdateUI(), Param == nil")
        return
    end

    self.SelectedGiftbagDetailGoodsId = 0
    self.bShowing = true
    self.GoodsDataList = Param

    self:GetDefaultSelectIndex()

    self.GiftItemIns2ToFixIndex = {}
    --动态修改 self.View.WBP_RecommendReuseListEx 尺寸
    if CommonUtil.IsValid(self.View.WBP_RecommendReuseListEx) then
        if #self.GoodsDataList < 2 then
            -- local size = self.View.WBP_RecommendReuseListEx.Slot:GetSize()
            -- local newSize = UE.FVector2D(547, size.Y)
            -- self.View.WBP_RecommendReuseListEx.Slot:SetSize(newSize)
            
            if self.View.ModifyRecommendReuseListExSize_BP then
                self.View:ModifyRecommendReuseListExSize_BP(1)
            end
        else
            -- local size = self.View.WBP_RecommendReuseListEx.Slot:GetSize()
            -- local newSize = UE.FVector2D(1056, size.Y)
            -- self.View.WBP_RecommendReuseListEx.Slot:SetSize(newSize)
    
            if self.View.ModifyRecommendReuseListExSize_BP then
                self.View:ModifyRecommendReuseListExSize_BP(2)
            end
        end
    end
    
    --列表刷新
    self.View.WBP_RecommendReuseListEx:Reload(#self.GoodsDataList)
    self.View.WBP_RecommendReuseListEx:ScrollToStart()

    self:SetDefaultSeletedItem()
end

-------------------------------------------礼包List >>

function ShopRecommend:SetDefaultSeletedItem()
    self:GetDefaultSelectIndex()
    if self.CurSelectIndex == nil then
        CError(string.format("ShopRecommend:SetDefaultSeletedItem, self.CurSelectIndex == nil !!!! self.CurSelectIndex = %s",tostring(self.CurSelectIndex)), true)
        return
    end
    if self.GoodsDataList == nil then
        CError(string.format("ShopRecommend:SetDefaultSeletedItem, self.GoodsDataList == nil !!!! self.CurSelectIndex = %s",tostring(self.CurSelectIndex)), true)
        return
    end
    if next(self.GoodsDataList) == nil then
        CError(string.format("ShopRecommend:SetDefaultSeletedItem, next(self.GoodsDataList) == nil !!!! self.CurSelectIndex = %s",tostring(self.CurSelectIndex)), true)
        return
    end
    local Goods = self.GoodsDataList[self.CurSelectIndex].Goods
    if Goods == nil then
        CError("ShopRecommend:SetDefaultSeletedItem, Goods == nil !!!!", true)
        return
    end
    if next(Goods) == nil then
        CError("ShopRecommend:SetDefaultSeletedItem, next(Goods) == nil !!!!", true)
        return
    end
    self.SelectedGiftbagGoods = Goods[1]
    self.CurSelectGoodsId = self.SelectedGiftbagGoods.GoodsId

    --设置默认选中礼包
    self:OnItemSelect(self.CurSelectIndex, self.SelectedGiftbagGoods, false)
end

--- func desc
---@param Widget any
---@param Data Index
function ShopRecommend:CreateItem(Widget, Index)
    local Item = self.Widget2ItemHandler[Widget]
    if not Item then
        Item = UIHandler.New(self, Widget, RecommendWidgetItem)
        self.Widget2ItemHandler[Widget] = Item
    end
    return Item.ViewInstance
end

--更新礼包List内容
function ShopRecommend:OnUpdateItem(_, Widget, Index)
    local FixIndex = Index + 1
    local Data = self.GoodsDataList[FixIndex]
    if not Data then
        return
    end

    local TargetItemIns = self:CreateItem(Widget, FixIndex)
    if TargetItemIns == nil then
        return
    end

    if Data.Goods then
        -- 正常应该都走这里
        TargetItemIns:SetData(Data.Goods[1], Bind(self, self.OnItemSelect, FixIndex), self.CurSelectGoodsId)
    else
        -- 异常状态!!
        CError(string.format("ShopRecommend:OnUpdateItem() 异常状态!!! Index = %s",tostring(Index)), true)
        TargetItemIns:SetData(Data, Bind(self, self.OnItemSelect, FixIndex), self.CurSelectGoodsId)
    end

    self.GiftItemIns2ToFixIndex = self.GiftItemIns2ToFixIndex or {}
    self.GiftItemIns2ToFixIndex[TargetItemIns] = FixIndex

    local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
    local ActionType = EventTrackingModel.SHOP_ACTION.DEFAULT_VIEW
    
    if self.CurSelectIndex == FixIndex then
        TargetItemIns:SetSelect(true)
        self:PlayDynamicEffectByRecommendItemState(ShopRecommend.SHOPRECOMMENDITEMSTATE.SELECT, FixIndex, TargetItemIns)
        ActionType = EventTrackingModel.SHOP_ACTION.CLICK_AND_VIEW
    else
        TargetItemIns:SetSelect(false)
        self:PlayDynamicEffectByRecommendItemState(ShopRecommend.SHOPRECOMMENDITEMSTATE.UNSELECT, FixIndex, TargetItemIns)
    end

    self:ReqEventTracking(ActionType, TargetItemIns.GoodsInfo.GoodsId, self.SelectedGiftbagGoods.GoodsId, 0, FixIndex, EventTrackingModel.SHOP_BUY_TYPE.NOT_BUY)
end

--选中礼包
function ShopRecommend:OnItemSelect(Index, GoodsInfo, IsHovered)
    if GoodsInfo == nil then
        return
    end
    self.CurSelectIndex = Index
    self.SelectedGiftbagGoods = GoodsInfo
    self.CurSelectGoodsId = self.SelectedGiftbagGoods.GoodsId
   
    for ItemIns, FixIndex in pairs(self.GiftItemIns2ToFixIndex) do
        if self.CurSelectIndex == FixIndex then
            ItemIns:SetSelect(true)
            self:PlayDynamicEffectByRecommendItemState(ShopRecommend.SHOPRECOMMENDITEMSTATE.SELECT, FixIndex, ItemIns)
        else
            ItemIns:SetSelect(false)
            self:PlayDynamicEffectByRecommendItemState(ShopRecommend.SHOPRECOMMENDITEMSTATE.UNSELECT, FixIndex, ItemIns)
        end
    end

    --更新当前选中礼包信息
    self:UpdateSelectGoodsInfo()

    --礼包购买按钮刷新
    self:UpdateSelectGoodsBtn()

    self:UpdateDetailItemsShow()
    
    self.ShopModel:DispatchType(ShopModel.ON_SCROLL_CHANGE, {GoodsId = self.CurSelectGoodsId, IsMouseMode = nil})

    self:ReqEventTracking(EventTrackingModel.SHOP_ACTION.DEFAULT_VIEW, GoodsInfo.GoodsId, self.SelectedGiftbagGoods.GoodsId, 0, Index, EventTrackingModel.SHOP_BUY_TYPE.NOT_BUY)
end

---更新当前选中礼包信息
function ShopRecommend:UpdateSelectGoodsInfo()
    if not self.bShowing then
        return
    end

    if self.SelectedGiftbagGoods == nil then
        return
    end
   
    ---@type GoodsItem
    local SelectGoodsData = nil
    --如果礼包包含多个内容 选中其中的角色皮肤 其次枪械皮肤
    if self.SelectedGiftbagGoods.IsPackGoods then
        local FristGoodData = nil
        ---@type GoodsItem
        local GoodsInfo = self.ShopModel:GetData(self.SelectedGiftbagGoods.GoodsId)
        for _, GoodsId in pairs(GoodsInfo.PackGoodsIdList) do
            local GoodsInfo = self.ShopModel:GetData(GoodsId)
            if GoodsInfo ~= nil then
                if FristGoodData == nil then
                    FristGoodData = GoodsInfo
                end
                if GoodsInfo.SceneModelType == ShopDefine.SceneModelType.Hero then
                    SelectGoodsData = GoodsInfo
                    break
                end
                if GoodsInfo.SceneModelType == ShopDefine.SceneModelType.Weapon then
                    SelectGoodsData = GoodsInfo
                    break
                end
            end
        end
        if SelectGoodsData == nil then
            SelectGoodsData = FristGoodData
        end
    else
        SelectGoodsData = self.SelectedGiftbagGoods
    end
    
    self.SelectedGiftbagDetailGoodsId = SelectGoodsData.GoodsId

    --捆绑包名字
    if CommonUtil.IsValid(self.View.GoodsName) then
        self.View.GoodsName:SetText(self.SelectedGiftbagGoods.Name)
    end
    --捆绑包物品数目
    if self.SelectedGiftbagGoods.PackGoodsIdList:Length() > 0 then
        -- 包含{0}个物品
        self.View.GUITextGoodsNum:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_RecommendIntro_ContainNum"), self.SelectedGiftbagGoods.PackGoodsIdList:Length()))
    else
        -- self.View.GUITextGoodsNum:SetText(StringUtil.Format("包含1个物品"))
        self.View.GUITextGoodsNum:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop", "Lua_RecommendIntro_ContainNum"), 1))
    end

    --显示礼包中被选中的商品信息
    self:UpdateDetailItemsInfo(self.SelectedGiftbagDetailGoodsId)
end

---礼包购买按钮刷新
function ShopRecommend:UpdateSelectGoodsBtn()
    if self.SelectedGiftbagGoods == nil then
        return 
    end
    ---@type SettlementSum
    local SettlementSum = MvcEntry:GetCtrl(ShopCtrl):GetGoodsPrice(self.SelectedGiftbagGoods.GoodsId)
    local Price = SettlementSum.TotalSettlementPrice
    local OriginPrice = SettlementSum.TotalSuggestedPrice

    local ExtShowPriceStr, ExtShowPriceStrColor = ShopCtrl:ConvertState2String(self.SelectedGiftbagGoods.GoodsState)
    ---@type CommonPriceParam
    local CommonPriceParam = {
        CurrencyType = self.SelectedGiftbagGoods.CurrencyType,
        SettlementSum = SettlementSum,
        -- Price = Price,
        -- OriginPrice = OriginPrice,
        ExtShowPriceStr = ExtShowPriceStr,
        ExtShowPriceStrColor = ExtShowPriceStrColor,
        GoodsState = self.SelectedGiftbagGoods.GoodsState
    }

    local BtnParam = {
        OnItemClick = Bind(self, self.OnSpaceBarHold),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        CommonPriceParam = CommonPriceParam,
    }
    
    local bCanBuyGoods = MvcEntry:GetCtrl(ShopCtrl):CheckCanBuyGoods(self.SelectedGiftbagGoods.GoodsId, 1)
    if bCanBuyGoods then
        BtnParam.ShowStyleType = WCommonBtnTips.ShowStyleType.Price
        BtnParam.CommonTipsID = CommonConst.CT_SPACE
        BtnParam.ActionMappingKey = ActionMappings.SpaceBar
        BtnParam.TipStr = ""
        BtnParam.bHideTipStr = true
    else
        BtnParam.ShowStyleType = WCommonBtnTips.ShowStyleType.None
        BtnParam.CommonTipsID = nil
        BtnParam.ActionMappingKey = nil
        BtnParam.TipStr = ExtShowPriceStr --StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Alreadyowned")) --"已拥有"
        BtnParam.bHideTipStr = false
    end

    if self.BuyButtonIns == nil or not(self.BuyButtonIns:IsValid()) then
        self.BuyButtonIns = UIHandler.New(self, self.View.WBP_HeroBuyButton, WCommonBtnTips, BtnParam).ViewInstance
    else
        -- self.BuyButtonIns:UpdatePriceShow(CommonPriceParam)
        self.BuyButtonIns:UpdateItemInfo(BtnParam)
    end

    if bCanBuyGoods then
        self.BuyButtonIns:SetBtnEnabled(true)
    else
        self.BuyButtonIns:SetBtnEnabled(false)
    end

end

---礼包购买按钮
function ShopRecommend:OnSpaceBarHold()
    if self.CurSelectGoodsId > 0 then
        MvcEntry:GetCtrl(ShopCtrl):RequestBuyShopItem(self.CurSelectGoodsId, 1)
        self:ReqEventTracking(EventTrackingModel.SHOP_ACTION.CLICK_BUY, self.CurSelectGoodsId, self.SelectedGiftbagGoods.GoodsId, 0, self.CurSelectIndex, EventTrackingModel.SHOP_BUY_TYPE.BUY_BUNDLE)
    end
end

-------------------------------------------礼包List <<


-- 按钮选择
function ShopRecommend:OnScrollItem(_, Start, End)
    --因为下标从0开始,所以要 +1
    self.StartItemIndex = Start + 1
    self.EndItemIndex = End + 1
end

-------------------------------------------礼包详情 >>

--初始化礼包详情页面物品列表
function ShopRecommend:UpdateDetailItemsShow()
    if self.CurSelectGoodsId == -1 then
        return
    end
    ---@type GoodsItem
    local GoodsInfo = self.ShopModel:GetData(self.CurSelectGoodsId)
    self.DetailItemList = {}
    local bShowMoreItem = false

    if GoodsInfo.IsPackGoods then
        --收集礼包详情:是捆绑包的情况
        if GoodsInfo.PackGoodsList then
            for Idx, PackGoods in pairs(GoodsInfo.PackGoodsList) do
                if #self.DetailItemList < ShopRecommend.MAX_SHOW_RECOMMEND_ITEMNUM then
                    table.insert(self.DetailItemList, {
                            GoodsId = PackGoods.PackGoodsId,
                            ItemId = PackGoods.PackItemId,
                            ItemNum = PackGoods.PackItemNum,
                            PackItemIdx = PackGoods.PackItemIdx
                        })
                else
                    bShowMoreItem = true
                end
            end
        else
            --捆绑包里没有商品
        end
    else
        --收集礼包详情:不是捆绑包的情况
        table.insert(self.DetailItemList, {
            GoodsId = GoodsInfo.GoodsId,
            ItemId = GoodsInfo.ItemId,
            ItemNum = GoodsInfo.ItemNum
        })
    end

    self.ItemIconClsToGoodsId = {}
    self.View.WBP_ReuseList:Reload(#self.DetailItemList)
    self.View.WBP_CommonBtn_Cir_Small_1:SetVisibility(bShowMoreItem and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)
end

function ShopRecommend:GetDetailItemByGoodsId(GoodsId)
    if self.DetailItemList and next(self.DetailItemList) then
        for k, DetailItem in pairs(self.DetailItemList) do
            if DetailItem.GoodsId == GoodsId then
               return  DetailItem
            end
        end
    end
    return nil
end

--更新礼包详情物品
function ShopRecommend:OnDetailUpdateItem(_,Widget, Index)
    local TempIndex = Index + 1
    local ItemData = self.DetailItemList[TempIndex]

    local GoodsId = ItemData.GoodsId
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemData.ItemId,
        ItemNum = ItemData.ItemNum,
        ClickCallBackFunc = Bind(self, self.OnDetailItemClick, ItemData)
    }
    local ItemIconCls = self.Widget2ItemIconCls[Widget]
    if not ItemIconCls then
        ItemIconCls = UIHandler.New(self, Widget, CommonItemIcon, IconParam).ViewInstance
        self.Widget2ItemIconCls[Widget] = ItemIconCls
    else
        ItemIconCls:UpdateUI(IconParam)
    end
    self.ItemIconClsToGoodsId[ItemIconCls] = GoodsId

    if GoodsId == self.SelectedGiftbagDetailGoodsId then
        ItemIconCls:SetIsSelect(true)
        self.CurItemIconCls = ItemIconCls
    else
        ItemIconCls:SetIsSelect(false)
    end

    if TempIndex >= #(self.DetailItemList) then
        local tItemData = self:GetDetailItemByGoodsId(self.SelectedGiftbagDetailGoodsId)
        self:OnDetailItemClick(tItemData)
    end

    MvcEntry:GetModel(EventTrackingModel):IsIdExistInShopItemsIdTemp(ItemData.GoodsId, TempIndex + 1)
    self:ReqEventTracking(EventTrackingModel.SHOP_ACTION.DEFAULT_VIEW, ItemData.GoodsId, self.SelectedGiftbagGoods.GoodsId, 0, TempIndex + 1, EventTrackingModel.SHOP_BUY_TYPE.NOT_BUY)
end

function ShopRecommend:OnDetailItemClick(ItemData)
    local GoodsId = ItemData.GoodsId
    self.SelectedGiftbagDetailGoodsId = GoodsId

    if self.CurItemIconCls then
        self.CurItemIconCls:SetIsSelect(false)
    end

    for ItemIconCls, TempID in pairs(self.ItemIconClsToGoodsId) do
        if TempID == GoodsId then
            self.CurItemIconCls = ItemIconCls
            self.CurItemIconCls:SetIsSelect(true)
            break
        end
    end

    --显示礼包中被选中的商品信息
    self:UpdateDetailItemsInfo(self.SelectedGiftbagDetailGoodsId)

    -- CError("ShopRecommend:OnDetailItemClick, 点击了礼包里的东西")

    self:UpdateGoodsIconAndModel_Inner(self.SelectedGiftbagDetailGoodsId)

    local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
    
    local ItemIndex = EventTrackingModel:GetItemIndexFromShopItemsIdTemp(GoodsId)
    self:ReqEventTracking(EventTrackingModel.SHOP_ACTION.CLICK_AND_VIEW, GoodsId, self.SelectedGiftbagGoods.GoodsId, 0, ItemIndex, EventTrackingModel.SHOP_BUY_TYPE.NOT_BUY)
end

---显示礼包中被选中的商品信息
function ShopRecommend:UpdateDetailItemsInfo(GoodsId)
    ---@type GoodsItem
    local GoodsInfo = self.ShopModel:GetData(GoodsId)
    if not GoodsInfo then
        return
    end

    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, GoodsInfo.ItemId)
    if not ItemCfg then
        return
    end

    if CommonUtil.IsValid(self.View.WBP_Common_Description) then
        self.View.WBP_Common_Description:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        local Param = {
            HideBtnSearch = true,
            HideDescription = true,
            ItemID = GoodsInfo.ItemId,
            HideLine = true,
        }
        if not self.CommonDescriptionCls then
            self.CommonDescriptionCls = UIHandler.New(self,self.View.WBP_Common_Description, CommonDescription, Param).ViewInstance
        else
            self.CommonDescriptionCls:UpdateUI(Param)
        end
    end
end


-------------------------------------------礼包详情 <<

-------------------------------------------Avatar >>

function ShopRecommend:GetViewKey()
    return ViewConst.Hall * 100 + CommonConst.HL_SHOP
end

---@param GoodsInfo GoodsItem
function ShopRecommend:ShowGoodsIcon_Inner(GoodsInfo)
    if GoodsInfo.SceneModelType == ShopDefine.SceneModelType.Icon then
        self.View.GUISceneImage:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.View.GUISceneImage, GoodsInfo.SceneModelIcon, true)
        ---@type RtShowTran
        local FinalTran = self.ShopModel:GetShopModeTranFinal(GoodsInfo.GoodsId, ETransformModuleID.Shop_Recommend.ModuleID, false)
        if FinalTran and FinalTran.RenderTran then
            CommonUtil.SetBrushRenderTransform(self.View.GUISceneImage, FinalTran.RenderTran)
        end
    else
        self.View.GUISceneImage:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---跟新商品 图片 与 模型
function ShopRecommend:UpdateGoodsIconAndModel_Inner(GoodsId)
    -- CError("ShopRecommend:UpdateGoodsIconAndModel_Inner")
    if self.ShowAvatarGoodsId == GoodsId then
        CWaring(string.format("ShopRecommend:UpdateGoodsIconAndModel_Inner, self.ShowAvatarGoodsId == GoodsId !!!! GoodsId = %s",tostring(GoodsId)))
        return
    end

    ---@type GoodsItem
    local GoodsInfo = self.ShopModel:GetData(GoodsId)
    if not GoodsInfo then
        return
    end

    self.ShowAvatarGoodsId = GoodsId
    --商品图片
    self:ShowGoodsIcon_Inner(GoodsInfo)

    local Param = { 
        GoodsId = GoodsId,
        TransparentViewId = self:GetViewKey(),
        ETranModuleID = ETransformModuleID.Shop_Recommend.ModuleID,
        TriggerTabTypeID = self.TabTypeID
    }
    -- MvcEntry:GetCtrl(ShopCtrl):SetLastShowParam(Param)
    -- -- CError("ShopRecommend:UpdateGoodsIconAndModel_Inner  ON_UPDATE_GOODS_MODEL_SHOW")
    -- self.ShopModel:DispatchType(ShopModel.ON_UPDATE_GOODS_MODEL_SHOW, Param)

    if self.HallTabShopIns then
        -- 更新模型
        self.HallTabShopIns:UpdateShowAvator(Param)
    end
end

-------------------------------------------Avatar <<


-------------------------------------------btn >>


--打开购买详情面板
function ShopRecommend:OnGoodsWidgetItemClicked()
    if self.CurSelectGoodsId <= 0 then
        return
    end

    self:ReqEventTracking(EventTrackingModel.SHOP_ACTION.CLICK_ENTER_TO_CONTENT, self.CurSelectGoodsId, self.SelectedGiftbagGoods.GoodsId, 1, self.CurSelectIndex, EventTrackingModel.SHOP_BUY_TYPE.NOT_BUY)
    MvcEntry:GetCtrl(ShopCtrl):OpenShopDetailView(self.CurSelectGoodsId, {bCheckCanBuy = false})
end

function ShopRecommend:OnAClick()
    local NextSelectIndex = self.CurSelectIndex - 1
    if NextSelectIndex < self.StartItemIndex then
        NextSelectIndex = self.StartItemIndex
    end

    if NextSelectIndex == self.CurSelectIndex then
        return
    end

    -- if self.CurSelectIndex < 1 then
    --     self.CurSelectIndex = 1
    -- end
    if self.GoodsDataList[NextSelectIndex] ~= nil then
        self:OnItemSelect(NextSelectIndex, self.GoodsDataList[NextSelectIndex].Goods[1], false)
    end
end

function ShopRecommend:OnDClick()
    local NextSelectIndex = self.CurSelectIndex + 1
    if NextSelectIndex > self.EndItemIndex then
        NextSelectIndex = self.EndItemIndex
    end

    if NextSelectIndex == self.CurSelectIndex then
        return
    end

    if self.GoodsDataList[NextSelectIndex] ~= nil then
        self:OnItemSelect(NextSelectIndex, self.GoodsDataList[NextSelectIndex].Goods[1], false)
    end
end
-------------------------------------------btn <<


-------------------------------------------Event >>

-- function ShopRecommend:DetailPanelChanged(Parame)
--     if not self.bShowing then
--         return
--     end

--     if not Parame then
--         return
--     end
    
--     if Parame.Open == true then
--         self:OnHideAvatorInner()
--         return
--     end

--     self:UpdateSelectGoodsInfo()
--     --礼包购买按钮刷新
--     self:UpdateSelectGoodsBtn()
-- end

function ShopRecommend:ON_GOODS_BUYTIMES_CHANGE_Func()
    self:UpdateSelectGoodsInfo()
    --礼包购买按钮刷新
    self:UpdateSelectGoodsBtn()
end

function ShopRecommend:ON_GOODS_INFO_CHANGE_Func()
    self:UpdateSelectGoodsInfo()
    --礼包购买按钮刷新
    self:UpdateSelectGoodsBtn()
end


-------------------------------------------Event <<

function ShopRecommend:ReqEventTracking(action, goodId, withBundle, isShowInDetail, index, buyType)
    local eventTrackingData = {
        action = action,
        product_id = goodId,
        belong_product_id = goodId == withBundle and 0 or withBundle,
        isShowInDetail = isShowInDetail,
        product_index = index,
        buy_type = buyType
    }

    MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SHOP_EVENTTRACKING_CLICK, eventTrackingData)
end

--[[
    播放ShopRecommend_Item选中动效
]]
function ShopRecommend:PlayDynamicEffectByRecommendItemState(InState, InIndex, InItemWidget)
    if not InItemWidget then
        return
    end
    if InState == ShopRecommend.SHOPRECOMMENDITEMSTATE.UNHOVER then
        if InItemWidget.View.VXE_BTN_Unhover then
            InItemWidget.View:VXE_BTN_Unhover()
        end
    elseif InState == ShopRecommend.SHOPRECOMMENDITEMSTATE.SELECT then
        if not self.LastShopRecommendItemsState[InIndex] or self.LastShopRecommendItemsState[InIndex] == ShopRecommend.SHOPRECOMMENDITEMSTATE.UNSELECT then
            if InItemWidget.View.VXE_Btn_Select then
                InItemWidget.View:VXE_Btn_Select()
            end
            self.LastShopRecommendItemsState[InIndex] = ShopRecommend.SHOPRECOMMENDITEMSTATE.SELECT
        end
    elseif InState == ShopRecommend.SHOPRECOMMENDITEMSTATE.UNSELECT then
        if not self.LastShopRecommendItemsState[InIndex] or self.LastShopRecommendItemsState[InIndex] == ShopRecommend.SHOPRECOMMENDITEMSTATE.SELECT then
            if InItemWidget.View.VXE_Btn_UnSelect then
                InItemWidget.View:VXE_Btn_UnSelect()
            end
            self.LastShopRecommendItemsState[InIndex] = ShopRecommend.SHOPRECOMMENDITEMSTATE.UNSELECT
        end
    end
end

return ShopRecommend