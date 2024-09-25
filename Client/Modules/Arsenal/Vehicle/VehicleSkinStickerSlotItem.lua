--[[
    贴纸插槽Item
]]
local class_name = "VehicleSkinStickerSlotItem";
VehicleSkinStickerSlotItem = VehicleSkinStickerSlotItem or BaseClass(nil, class_name);

function VehicleSkinStickerSlotItem:OnInit()
    self.BindNodes = 
    {
	}
end


function VehicleSkinStickerSlotItem:OnShow(Param)
	self.Param = Param
	self.VehicleSkinId = self.Param.VehicleSkinId or 0
end

function VehicleSkinStickerSlotItem:OnHide()
	self.CommonItemInst = nil
end

function VehicleSkinStickerSlotItem:SetItemData( Slot)
	self.Slot = Slot or 0

	self.View.Name:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.View.Event:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.View.Quantity:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.View.Subscript:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.View.Lottery:SetVisibility(UE.ESlateVisibility.Collapsed)

	local StickerInfo = MvcEntry:GetModel(VehicleModel):GetVehicleSkinStickerBySlot(self.VehicleSkinId, self.Slot)
	if StickerInfo == nil then
		CError("Sorry: Never Happened")
		return
	end
	local StickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker, StickerInfo.StickerId)
	if StickerCfg == nil then
		return
	end
	self.View.Name:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	self.View.GUITextName:SetText(StringUtil.Format(StickerCfg[Cfg_VehicleSkinSticker_P.StickerName]))
	
	local IconParam = {
		IconType = CommonItemIcon.ICON_TYPE.PROP,
		ItemId = StickerCfg[Cfg_VehicleSkinSticker_P.ItemId],
		ClickCallBackFunc = Bind(self,self.OnItemClick),
		IsBreakClick = true,
		HoverScale = 1.05,
	}
	if not self.CommonItemInst then
		self.CommonItemInst = UIHandler.New(self,self.View.WBP_CommonItemIcon,CommonItemIcon, IconParam).ViewInstance
	else
		self.CommonItemInst:UpdateUI(IconParam,true)	
	end
end

function VehicleSkinStickerSlotItem:OnItemClick()
	if self.Param and self.Param.OnItemClick then
		self.Param.OnItemClick(self, self.VehicleSkinId, self.Slot)
	end
end


function VehicleSkinStickerSlotItem:Select()
	if self.CommonItemInst ~= nil then
		self.CommonItemInst:SetIsSelect(true)
	end
end

function VehicleSkinStickerSlotItem:UnSelect()
	if self.CommonItemInst ~= nil then
		self.CommonItemInst:SetIsSelect(false)
	end
end

return VehicleSkinStickerSlotItem