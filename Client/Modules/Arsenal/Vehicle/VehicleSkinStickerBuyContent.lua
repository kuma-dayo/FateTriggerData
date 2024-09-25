--[[
    贴纸购买内容逻辑
]]

local class_name = "VehicleSkinStickerBuyContent"
VehicleSkinStickerBuyContent = BaseClass(nil, class_name)

function VehicleSkinStickerBuyContent:OnInit()
    self.BindNodes = 
    {
     --   {UDelegate = self.View.WBP_ReuseList.OnUpdateItem, Func = Bind(self, self.OnUpdateItem)},
    }
    --self.Widget2Item = {}
end

function VehicleSkinStickerBuyContent:OnShow(data)
    self.Param = data or {}
    self.StickerId = self.Param.StickerId or 0
    local Param = {
        UseByBuyList = true,
    }
    self.ItemInst = UIHandler.New(self, self.View.WBP_VehicleSkinSticker_Item,
        require("Client.Modules.Arsenal.Vehicle.VehicleSkinStickerListItem"), Param).ViewInstance
    if self.ItemInst then
        self.ItemInst:SetItemData(self.StickerId)
    end

    self.SliderCls = UIHandler.New(self, self.View.WBP_CommonEditableSlider, CommonEditableSlider).ViewInstance
	Param = {
        ValueChangeCallBack = Bind(self, self.ValueChangeCallBack),
        MaxValue = self.Param.BuyMax or 10,
        DefaultValue = self.Param.BuyNum or 1,
    }
    self.View.WBP_CommonEditableSlider.RichTextBlock_Intimacy:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.SliderCls:UpdateItemInfo(Param)
end

function VehicleSkinStickerBuyContent:OnHide()

end


function VehicleSkinStickerBuyContent:ValueChangeCallBack(CurValue)
    if self.WidgetBase then
        self.WidgetBase:UpdateStickerBuyInfo(CurValue)
    end
end


return VehicleSkinStickerBuyContent
