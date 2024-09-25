--[[
    大厅 - 切页 - 商店
]]
local class_name = "GoodsWidgetItemList"
GoodsWidgetItemList = BaseClass(nil, class_name)

local GoodsWidgetItem = require("Client.Modules.Shop.GoodsWidgetItem")

---@type GoodsItem[]
GoodsWidgetItemList.ItemInfo = nil

--- 初始化
function GoodsWidgetItemList:OnInit()
    self.BindNodes = {}
    self.MsgList = {}

    self.BaseGoodsItemTopHandle =
        UIHandler.New(self, self.View.BaseGoodsItemTop, GoodsWidgetItem).ViewInstance
    self.BaseGoodsItemDownHandle =
        UIHandler.New(self, self.View.BaseGoodsItemDown, GoodsWidgetItem).ViewInstance

    self.ItemList = {
        self.BaseGoodsItemTopHandle,
        self.BaseGoodsItemDownHandle
    }
end

--- func 显示
---@param Param any
function GoodsWidgetItemList:OnShow(Param)
end

--- func 隐藏
function GoodsWidgetItemList:OnHide()
end

--- 设置数据
---@param Param GoodsItem[]
function GoodsWidgetItemList:SetData(Param, CallBack, SelectGoodsId, CategoryID)
    if not Param then
        return
    end
    self.ItemInfo = Param
    self.CategoryID = CategoryID

    for Index, item in ipairs(self.ItemList) do
        if self.ItemInfo.Goods[Index] then
            item.View:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            item:SetData(self.ItemInfo.Goods[Index], CallBack, SelectGoodsId, CategoryID)
        else
            item.View:SetVisibility(UE4.ESlateVisibility.Collapsed)
        end
    end
end

function GoodsWidgetItemList:ReqEventTracking(action, goodId, isShowInDetail, index, buyType)
    local eventTrackingData = {
        action = action,
        product_id = goodId,
        belong_product_id = 0,
        isShowInDetail = isShowInDetail,
        product_index = index,
        buy_type = buyType
    }

    MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SHOP_EVENTTRACKING_CLICK, eventTrackingData)
end


function GoodsWidgetItemList:OnGoodsItemClicked()
    if not self.ItemInfo then
        return
    end

    MvcEntry:GetCtrl(ShopCtrl):OpenShopDetailView(self.ItemInfo.GoodsId)
end

return GoodsWidgetItemList
