--[[
    贴纸Item
]]
local class_name = "VehicleSkinStickerListItem";
VehicleSkinStickerListItem = VehicleSkinStickerListItem or BaseClass(nil, class_name);

function VehicleSkinStickerListItem:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.View.BtnDelete.OnClicked,				Func = Bind(self, self.OnItemDeleteClick) },
		{ UDelegate = self.View.BtnDelete.OnHovered,				Func = Bind(self, self.OnItemDeleteHover) },
		{ UDelegate = self.View.BtnDelete.OnUnhovered,				Func = Bind(self, self.OnItemDeleteUnhover) },
	}
end


function VehicleSkinStickerListItem:OnShow(Param)
    self.Param = Param or {}
	self.UseByEquipList = self.Param.UseByEquipList or false
	self.UseByBuyList = self.Param.UseByBuyList or false
	self.UseByStickerList = self.Param.UseByStickerList or false
end

function VehicleSkinStickerListItem:OnHide()
	self.CommonItemInst = nil
end

function VehicleSkinStickerListItem:SetItemData(StickerId, Slot)
	if StickerId == nil then
		return
	end
	self.StickerId = StickerId
	self.Slot = Slot or 0

	if StickerId == 0 then
		local IconParam = {
			IconType = CommonItemIcon.ICON_TYPE.PROP,
			ItemId = nil,
			ItemNum = 0,
			ClickCallBackFunc = Bind(self,self.OnItemClick),
			IsBreakClick = true,
			HoverScale = 1.05,
			ShowEmpty = true,
		}
		if not self.CommonItemInst then
			self.CommonItemInst = UIHandler.New(self,self.View.WBP_CommonItemIcon,CommonItemIcon, IconParam).ViewInstance
		else
			self.CommonItemInst:UpdateUI(IconParam,true)	
		end
		self.View.Name:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.View.Event:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.View.Quantity:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.View.Subscript:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.View.Lottery:SetVisibility(UE.ESlateVisibility.Collapsed)
	else
		local StickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker, StickerId)
		if StickerCfg == nil then
			return
		end
		local ItemNum = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(StickerCfg[Cfg_VehicleSkinSticker_P.ItemId]) or 0
		
		local IconParam = {
			IconType = CommonItemIcon.ICON_TYPE.PROP,
			ItemId = StickerCfg[Cfg_VehicleSkinSticker_P.ItemId],
			ClickCallBackFunc = Bind(self,self.OnItemClick),
			HoverCallBackFunc = Bind(self,self.OnItemHover),
			UnhoverCallBackFunc = Bind(self, self.OnItemUnhover),
			IsBreakClick = true,
			HoverScale = 1.05,
			IsBreakHover = false,
			IsBreakUnhover = true,
			IsLock = not self.UseByBuyList and ItemNum <= 0 or false
		}
		if not self.CommonItemInst then
			self.CommonItemInst = UIHandler.New(self,self.View.WBP_CommonItemIcon,CommonItemIcon, IconParam).ViewInstance
		else
			self.CommonItemInst:UpdateUI(IconParam,true)	
		end
		self.View.Name:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		self.View.GUITextName:SetText(StringUtil.Format(StickerCfg[Cfg_VehicleSkinSticker_P.StickerName]))

		self.View.Lottery:SetVisibility(UE.ESlateVisibility.Collapsed)

		if self.UseByStickerList then
			--已装配数/总拥有数
			if ItemNum > 0 then
				self.View.Event:SetVisibility(UE.ESlateVisibility.Collapsed)
				self.View.Quantity:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
				self.View.GTBItemNum:SetText(ItemNum)
			else
				self.View.Event:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
				self.View.Quantity:SetVisibility(UE.ESlateVisibility.Collapsed)
			end
			--获取途径
			local UnlockFlag =  StickerCfg[Cfg_VehicleSkinSticker_P.UnlockFlag]
			if UnlockFlag == 0 then
				self.View.GTBBuy:SetVisibility(UE.ESlateVisibility.Collapsed)
				self.View.GTBActivity:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
				self.View.GTBActivity:SetText(StringUtil.Format(StickerCfg[Cfg_VehicleSkinSticker_P.ObtainWay]))
			elseif UnlockFlag == 1 then
				self.View.GTBActivity:SetVisibility(UE.ESlateVisibility.Collapsed)
				self.View.GTBBuy:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

				local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_VehicleSkinSticker,StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemId])
				CommonUtil.SetBrushFromSoftObjectPath(self.View.Icon_Normal, CfgItem and CfgItem[Cfg_ItemConfig_P.IconPath] or "")
				self.View.TextNum_Normal:SetText(StickerCfg[Cfg_VehicleSkinSticker_P.UnlockItemNum])
				--解锁
				-- if ItemNum <= 0 then
				-- 	self.View.Subscript:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
				-- 	self.View.WidgetSwitcherState:SetActiveWidgetIndex(0)
				-- else
				-- 	self.View.Subscript:SetVisibility(UE.ESlateVisibility.Collapsed)
				-- end
				self.View.Subscript:SetVisibility(UE.ESlateVisibility.Collapsed)
			elseif UnlockFlag == 2 then
				CLog("Jump To ViewId: ")
			end
		elseif self.UseByEquipList or self.UseByBuyList then
			self.View.Event:SetVisibility(UE.ESlateVisibility.Collapsed)
			self.View.Quantity:SetVisibility(UE.ESlateVisibility.Collapsed)
			self.View.Subscript:SetVisibility(UE.ESlateVisibility.Collapsed)
			self.View.Lottery:SetVisibility(UE.ESlateVisibility.Collapsed)
		end
	end
end

function VehicleSkinStickerListItem:ShowDeleteButton(IsShow)
	if IsShow and self.UseByEquipList and self.StickerId ~= 0 then
		self.View.Subscript:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		self.View.WidgetSwitcherState:SetActiveWidgetIndex(1)
	else
		self.View.Subscript:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.View.WidgetSwitcherState:SetActiveWidgetIndex(0)
	end
end


function VehicleSkinStickerListItem:OnItemClick()
	if self.Param and self.Param.OnItemClick then
		self.Param.OnItemClick(self, self.StickerId, self.Slot)
	end
end

function VehicleSkinStickerListItem:OnItemHover()
	-- self:ShowDeleteButton(true)	
-- 	if self.Param and self.Param.OnItemHover then
-- 		self.Param.OnItemHover(self.Slot)
-- 	end
end

function VehicleSkinStickerListItem:OnItemUnhover()
	-- self:ShowDeleteButton(false)	
	-- if self.Param and self.Param.OnItemUnhover then
	-- 	self.Param.OnItemUnhover(self.Slot)
	-- end
end

function VehicleSkinStickerListItem:OnItemDeleteClick()
	if self.Param and self.Param.OnItemRemoveClick then
		self.Param.OnItemRemoveClick(self.StickerId, self.Slot)
	end
end

function VehicleSkinStickerListItem:OnItemDeleteHover()
end

function VehicleSkinStickerListItem:OnItemDeleteUnhover()
end


function VehicleSkinStickerListItem:Select()
	if self.CommonItemInst ~= nil then
		self.CommonItemInst:SetIsSelect(true)
	end
	self:ShowDeleteButton(true)
end

function VehicleSkinStickerListItem:UnSelect()
	if self.CommonItemInst ~= nil then
		self.CommonItemInst:SetIsSelect(false)
	end
	self:ShowDeleteButton(false)
end

return VehicleSkinStickerListItem