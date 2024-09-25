--[[
    贴纸对应载具皮肤Item
]]
local class_name = "VehicleSkinStickerShortageItem";
VehicleSkinStickerShortageItem = VehicleSkinStickerShortageItem or BaseClass(nil, class_name);

function VehicleSkinStickerShortageItem:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.View.GUIButtonSelect.OnClicked,				Func = Bind(self, self.OnItemClicked) },
		{ UDelegate = self.View.GUIButtonSelect.OnHovered,				Func = Bind(self, self.OnItemHover) },
		{ UDelegate = self.View.GUIButtonSelect.OnUnhovered,				Func = Bind(self, self.OnItemUnhovered) },
	}
end


function VehicleSkinStickerShortageItem:OnShow(Param)
	if Param == nil then
		return
	end
    self.Param = Param
	self.StickerId = self.Param.StickerId or 0
end

function VehicleSkinStickerShortageItem:OnHide()
end

function VehicleSkinStickerShortageItem:SetItemData(VehicleSkinInfo)
	self.VehicleSkinInfo = VehicleSkinInfo

	self.View.WBP_WeaponVehicle_StickerItem.Name:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.View.WBP_WeaponVehicle_StickerItem.Event:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.View.WBP_WeaponVehicle_StickerItem.Quantity:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.View.WBP_WeaponVehicle_StickerItem.Subscript:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.View.WBP_WeaponVehicle_StickerItem.Lottery:SetVisibility(UE.ESlateVisibility.Collapsed)
	
	local VehicleSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinConfig, self.VehicleSkinInfo.VehicleSkinId)
	if VehicleSkinCfg == nil then
		return
	end
	self.View.GUITBName:SetText(VehicleSkinCfg[Cfg_VehicleSkinConfig_P.SkinName])

	local IconParam = {
		IconType = CommonItemIcon.ICON_TYPE.PROP,
		ItemId = VehicleSkinCfg[Cfg_VehicleSkinConfig_P.ItemId],
		IsBreakClick = true,
		HoverScale = 1.05,
	}
	if not self.CommonItemInst then
		self.CommonItemInst = UIHandler.New(self,self.View.WBP_WeaponVehicle_StickerItem.WBP_CommonItemIcon,CommonItemIcon, IconParam).ViewInstance
	else
		self.CommonItemInst:UpdateUI(IconParam,true)	
	end
end

function VehicleSkinStickerShortageItem:OnItemClicked(Index)
	if self.Param and self.Param.OnItemClick then
		self.Param.OnItemClick(self, self.VehicleSkinInfo)
	end
end

function VehicleSkinStickerShortageItem:OnItemHover()
	self.View.Img_Hover:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function VehicleSkinStickerShortageItem:OnItemUnhovered()
	self.View.Img_Hover:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function VehicleSkinStickerShortageItem:Select()
	self.View.Img_Selected:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function VehicleSkinStickerShortageItem:UnSelect()
	self.View.Img_Selected:SetVisibility(UE.ESlateVisibility.Collapsed)
end


return VehicleSkinStickerShortageItem