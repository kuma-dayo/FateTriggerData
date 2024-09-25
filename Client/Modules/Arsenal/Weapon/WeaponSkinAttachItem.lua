--[[
	配件皮肤Item
]]
local class_name = "WeaponSkinAttachItem";
local WeaponSkinAttachItem = BaseClass(nil, class_name)


function WeaponSkinAttachItem:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.GUIButtonSelect.OnClicked,  Func = Bind(self,self.OnItemClicked) },
		{ UDelegate = self.View.GUIButtonSelect.OnHovered,  Func = Bind(self,self.OnItemHover) },
		{ UDelegate = self.View.GUIButtonSelect.OnUnhovered,  Func = Bind(self,self.OnItemUnhovered) }
	}
	self.TheWeaponModel = MvcEntry:GetModel(WeaponModel)
	self.TheArsenalModel = MvcEntry:GetModel(ArsenalModel)
end


function WeaponSkinAttachItem:OnShow(Param)
    self.Param = Param

	self.ReqGetCurAttachmentId = self.Param.ReqGetCurAttachmentId
end

function WeaponSkinAttachItem:GetCurAttachmentId()
	if self.ReqGetCurAttachmentId then
		return self.ReqGetCurAttachmentId()
	end
	CError("WeaponDetailAttachItem:GetCurAttachmentId() self.ReqGetCurAttachmentId == nil", true)
	return WeaponModel.RESERVED_ATTACHMENT_ID
end

function WeaponSkinAttachItem:OnHide()
end

function WeaponSkinAttachItem:IsReservedAttachmentSkinId()
	return self.CurAttachmentSkinId == WeaponModel.RESERVED_ATTACHMENT_SKIN_ID
end

function WeaponSkinAttachItem:UpdateWeaponSkinAttachItemIcon()
	local AttchmentSkinId = self.CurAttachmentSkinId

	if self:IsReservedAttachmentSkinId() then
		self.View.WBP_Attachment_ItemIcon.WidgetSwitcher_0:SetActiveWidgetIndex(1)
		self.View.GUITBName:SetText(self.TheArsenalModel:GetArsenalText(10010))
		return
	end

	local WeaponPartSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartSkinConfig, AttchmentSkinId)
	if WeaponPartSkinCfg == nil then
		return
	end
	local ItemCfg =  G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, WeaponPartSkinCfg[Cfg_WeaponPartSkinConfig_P.ItemId])
	if ItemCfg == nil then
		return
	end

	self.View.WBP_Attachment_ItemIcon.WidgetSwitcher_0:SetActiveWidgetIndex(0)
	self.View.GUITBName:SetText(StringUtil.Format(ItemCfg[Cfg_ItemConfig_P.Name]))
	CommonUtil.SetBrushFromSoftObjectPath(self.View.WBP_Attachment_ItemIcon.GUIImageIcon, ItemCfg[Cfg_ItemConfig_P.IconPath])
	local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg, ItemCfg[Cfg_ItemConfig_P.Quality])
	if QualityCfg then
		local QualityBgPath = QualityCfg[Cfg_ItemQualityColorCfg_P.QualityBg]
		CommonUtil.SetBrushFromSoftObjectPath(self.View.WBP_Attachment_ItemIcon.GUIImage_QualityBg,QualityBgPath)
	end
end

function WeaponSkinAttachItem:UpdateAttachmentEquiped(bSelected)
	if not(CommonUtil.IsValid(self.View.WidgetSwitcher_State)) then
		return
	end

	if bSelected then
		self.View.WidgetSwitcher_State:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		self.View.WidgetSwitcher_State:SetActiveWidget(self.View.HookNode)
	else
		self.View.WidgetSwitcher_State:SetVisibility(UE.ESlateVisibility.Collapsed)
	end	
end

function WeaponSkinAttachItem:UpdateCommonBuy()
	if self:IsReservedAttachmentSkinId() then
		self.View.BuyNode:SetVisibility(UE.ESlateVisibility.Collapsed)
		return
	end

	local IsUnlocked = self.TheWeaponModel:IsAttachmentSkinIdUnLocked(self.CurAttachmentSkinId)
	if IsUnlocked then 
		self.View.BuyNode:SetVisibility(UE.ESlateVisibility.Collapsed)
	else 
		local WeaponPartSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartSkinConfig, self.CurAttachmentSkinId)
		local UnlockFlag = WeaponPartSkinCfg and WeaponPartSkinCfg[Cfg_WeaponPartSkinConfig_P.UnlockFlag] or false
		if not UnlockFlag then
			self.View.BuyNode:SetVisibility(UE.ESlateVisibility.Collapsed)
			return
		end

		self.View.BuyNode:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		local UnlockItemId = WeaponPartSkinCfg and WeaponPartSkinCfg[Cfg_WeaponPartSkinConfig_P.UnlockItemId] or 0
		local UnlockCost = WeaponPartSkinCfg and WeaponPartSkinCfg[Cfg_WeaponPartSkinConfig_P.UnlockItemNum] or 0
		local Param = {
			ItemId = UnlockItemId,
			ItemShowNum = UnlockCost,
			IsSelect = false,
			CheckEnough = false,
			CallFunc = Bind(self, self.OnButtonClickedBuy),
			HoverFunc = Bind(self, self.OnItemHover),
			UnhoverFunc = Bind(self, self.OnItemUnhovered)
		}
		self.CommonPurchaseInst = UIHandler.New(self, self.View.WBP_Common_Btn, 
			require("Client.Modules.Common.CommonPurchaseBtn"),Param).ViewInstance
	end
end


function WeaponSkinAttachItem:UpdateHover()
	if self.Index == self.HoverIndex then
		self:SetHover()
	else 
		self:SetUnhover()
	end
end

function WeaponSkinAttachItem:SetHover()
	-- if self:IsSelected() then
	-- 	return
	-- end
	-- self.View.ListBg_Btn_Switch:SetActiveWidgetIndex(1)
end

function WeaponSkinAttachItem:SetUnhover()
	-- if self:IsSelected() then
	-- 	return
	-- end
	-- self.View.ListBg_Btn_Switch:SetActiveWidgetIndex(0)
end


function WeaponSkinAttachItem:SetItemData(AttachmentSkinId, Index, Slot, HoverIndex)
	self.CurAttachmentSkinId = AttachmentSkinId
	self.Index = Index
	self.Slot = Slot
	self.HoverIndex = HoverIndex

	local bSelected = self:IsSelected()
	self:UpdateWeaponSkinAttachItemIcon()
	self:UpdateAttachmentEquiped(bSelected)
	self:UpdateCommonBuy()
	self:UpdateHover()
end

function WeaponSkinAttachItem:OnItemClicked()
    if self.Param.OnItemClick then
        self.Param.OnItemClick(self, self.CurAttachmentSkinId, self.Index)
    end
	local TheWeaponModel = self.TheWeaponModel
	local WeaponSkinId = self.Param and self.Param.Handler and self.Param.Handler.CurWeaponSkinId or 0

	local SlotTmp, SubType = TheWeaponModel:GetSlotTypeByAttachmentSkinId(self.CurAttachmentSkinId)
	local AvatarId = TheWeaponModel:GetAvatartIdShowByWeaponSkinIdAndSlotType(WeaponSkinId, self.Slot, SubType)
	local Param = {
		SlotType = self.Slot,
		AvatarId = AvatarId,
		IsAdd = (AvatarId and AvatarId > 0)
	}
	TheWeaponModel:DispatchType(WeaponModel.ON_WEAPON_AVATAR_PREVIEW_UPDATE,Param)

	local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, WeaponSkinId)
	local WeaponId = WeaponSkinCfg[Cfg_WeaponSkinConfig_P.WeaponId]
	if self:IsReservedAttachmentSkinId() then
		TheWeaponModel:WeaponUnEquipPart(WeaponId, self.Slot, nil)
	else
		local PartId = TheWeaponModel:GetPartIdByPartSkinId(self.CurAttachmentSkinId)
		TheWeaponModel:WeaponEquipPart(WeaponId, self.Slot, PartId)
	end
end

function WeaponSkinAttachItem:IsSelected()
	-- local Handler = self.Param and self.Param.Handler or nil
	-- if Handler ~= nil and Handler.CurAttachmentId == self.CurAttachmentSkinId then
	-- 	return true
	-- end
	-- return false

	local CurAttachmentId = self:GetCurAttachmentId()
	if CurAttachmentId > 0 and CurAttachmentId == self.TheAttachmentId then
		return true
	end
	return false
end

function WeaponSkinAttachItem:UpdateHoverIndex()
	local Handler = self.Param and self.Param.Handler or nil
	if Handler ~= nil then
		self.Param.Handler:UpdateHoverItem(self.Index)
	end
end


function WeaponSkinAttachItem:OnItemHover()
	self:UpdateHoverIndex()
end

function WeaponSkinAttachItem:OnItemUnhovered()
	self:SetUnhover()	
end

function WeaponSkinAttachItem:Select()
	if self.View.VXE_Btn_Select then
		self.View:VXE_Btn_Select()
	end

	if self.CommonPurchaseInst ~= nil then
		self.CommonPurchaseInst:SetIsSelect(true)
	end

	self:UpdateAttachmentEquiped(true)
end

function WeaponSkinAttachItem:UnSelect()

	if self.View.VXE_Btn_UnSelect then
		self.View:VXE_Btn_UnSelect()
	end

	if self.CommonPurchaseInst ~= nil then
		self.CommonPurchaseInst:SetIsSelect(false)
	end

	self:UpdateAttachmentEquiped(false)
end

function WeaponSkinAttachItem:OnButtonClickedBuy()
	local WeaponPartSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartSkinConfig, self.CurAttachmentSkinId)
	local UnlockItemId = WeaponPartSkinCfg and WeaponPartSkinCfg[Cfg_WeaponPartSkinConfig_P.UnlockItemId] or 0
	local UnlockCost = WeaponPartSkinCfg and WeaponPartSkinCfg[Cfg_WeaponPartSkinConfig_P.UnlockItemNum] or 0
	
	if UnlockItemId == 0 then
		CLog("UnlockItemId Failed: No Need Buy")
		return
	end
	
    local ItemName = MvcEntry:GetModel(DepotModel):GetItemName(UnlockItemId)
    local Cost = UnlockCost
	local Balance = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(UnlockItemId)
	if Balance < Cost then
		local msgParam = {
			describe = StringUtil.Format(self.TheArsenalModel:GetArsenalText(10014),ItemName)
		}
		UIMessageBox.Show(msgParam)
		return
	end
	local msgParam = {
		describe = StringUtil.Format(self.TheArsenalModel:GetArsenalText(10015), Cost,ItemName),
		leftBtnInfo = {},
		rightBtnInfo = {
			callback = function()
				local WeaponSkinId = self.Param and self.Param.Handler and self.Param.Handler.CurWeaponSkinId or 0
				MvcEntry:GetCtrl(ArsenalCtrl):SendProto_BuyWeaponPartSkinReq(WeaponSkinId, 
						self.CurAttachmentSkinId)
			end
		}
	}
	UIMessageBox.Show(msgParam)
end




return WeaponSkinAttachItem