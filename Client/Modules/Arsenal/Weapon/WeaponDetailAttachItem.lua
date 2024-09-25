--[[
	配件Item
]]
local class_name = "WeaponDetailAttachItem";
local WeaponDetailAttachItem = BaseClass(nil, class_name)

function WeaponDetailAttachItem:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.GUIButtonSelect.OnClicked,  Func = Bind(self,self.OnItemClicked) },
		{ UDelegate = self.View.GUIButtonSelect.OnHovered,  Func = Bind(self,self.OnItemHover) },
		{ UDelegate = self.View.GUIButtonSelect.OnUnhovered,  Func = Bind(self,self.OnItemUnhovered) }
	}
	self.TheWeaponModel =  MvcEntry:GetModel(WeaponModel)
end

function WeaponDetailAttachItem:OnShow(Param)
    self.Param = Param
	self.bVXE_Btn_Select = false

	self.ReqGetCurAttachmentId = self.Param.ReqGetCurAttachmentId
end

function WeaponDetailAttachItem:GetCurAttachmentId()
	if self.ReqGetCurAttachmentId then
		return self.ReqGetCurAttachmentId()
	end
	CError("WeaponDetailAttachItem:GetCurAttachmentId() self.ReqGetCurAttachmentId == nil", true)
	return WeaponModel.RESERVED_ATTACHMENT_ID
end

function WeaponDetailAttachItem:OnHide()
end

function WeaponDetailAttachItem:IsReservedAttachmentId()
	return self.TheAttachmentId == WeaponModel.RESERVED_ATTACHMENT_ID
end

--设置配件名称
function WeaponDetailAttachItem:UpdateAttachmentName()
	if self:IsReservedAttachmentId() then
		self.View.GUITBName:SetText(MvcEntry:GetModel(ArsenalModel):GetArsenalText(10010))
		return
	end

	local WeaponPartCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartConfig, self.TheAttachmentId)
	if WeaponPartCfg == nil then
		return
	end
	local ItemCfg =  G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, WeaponPartCfg[Cfg_WeaponPartConfig_P.ItemId])
	self.View.GUITBName:SetText(StringUtil.Format(ItemCfg and ItemCfg[Cfg_ItemConfig_P.Name] or ""))
end

--设置配件图标
function WeaponDetailAttachItem:SetWeaponDetailAttachItemIcon(AttchmentId)
	if self:IsReservedAttachmentId() then
		self.View.WBP_Attachment_ItemIcon.WidgetSwitcher_0:SetActiveWidgetIndex(1)
		return
	end

	local WeaponPartCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartConfig, AttchmentId)
	if WeaponPartCfg == nil then
		return
	end
	local ItemCfg =  G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, WeaponPartCfg[Cfg_WeaponPartConfig_P.ItemId])
	if ItemCfg == nil then
		return
	end
	self.View.WBP_Attachment_ItemIcon.WidgetSwitcher_0:SetActiveWidgetIndex(0)
	self.View.WBP_Attachment_ItemIcon.TextNum:SetVisibility(UE.ESlateVisibility.Collapsed)	

	CommonUtil.SetBrushFromSoftObjectPath(self.View.WBP_Attachment_ItemIcon.GUIImageIcon, ItemCfg[Cfg_ItemConfig_P.IconPath])
	local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg, ItemCfg[Cfg_ItemConfig_P.Quality])
	if QualityCfg then
		local QualityBgPath = QualityCfg[Cfg_ItemQualityColorCfg_P.QualityBg]
		CommonUtil.SetBrushFromSoftObjectPath(self.View.WBP_Attachment_ItemIcon.GUIImage_QualityBg,QualityBgPath)
	end
end

function WeaponDetailAttachItem:UpdateWeaponDetailAttachItemIcon()
	self:SetWeaponDetailAttachItemIcon(self.TheAttachmentId)
end

function WeaponDetailAttachItem:UpdateAttachmentEquiped(bSelected)
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

function WeaponDetailAttachItem:UpdateCommonBuy()
	self.View.BuyNode:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function WeaponDetailAttachItem:UpdateHover()
end

function WeaponDetailAttachItem:SetHover()
end

function WeaponDetailAttachItem:SetUnhover()
end


function WeaponDetailAttachItem:SetItemData(AttachmentId, Index, Slot, HoverIndex)
	self.TheAttachmentId = AttachmentId
	self.Slot = Slot
	self.Index = Index
	self.HoverIndex = HoverIndex

	local bSelected = self:IsSelected()
	self:UpdateAttachmentEquiped(bSelected)
	self:UpdateWeaponDetailAttachItemIcon()
	self:UpdateAttachmentName()
	self:UpdateCommonBuy()
	self:UpdateHover()
end


function WeaponDetailAttachItem:OnItemClicked()
    if self.Param.OnItemClick then
        self.Param.OnItemClick(self, self.TheAttachmentId, self.Index)
    end
	local WeaponId = self.Param and self.Param.Handler and self.Param.Handler.CurSelectWeaponId or 0
	local Slot = self.Slot

	local SlotTmp, SubType = self.TheWeaponModel:GetSlotTypeByAttachmentId(self.TheAttachmentId)
	local WeaponSkinId = self.TheWeaponModel:GetWeaponSkinId(WeaponId)
	local AvatarId = self.TheWeaponModel:GetAvatartIdShowByWeaponSkinIdAndSlotType(WeaponSkinId, Slot, SubType)
	local Param = {
		SlotType = Slot,
		AvatarId = AvatarId,
		IsAdd = (AvatarId and AvatarId > 0)
	}
	self.TheWeaponModel:DispatchType(WeaponModel.ON_WEAPON_AVATAR_PREVIEW_UPDATE,Param)

	if self:IsReservedAttachmentId() then
		self.TheWeaponModel:WeaponUnEquipPart(WeaponId, Slot, nil)
	else
		self.TheWeaponModel:WeaponEquipPart(WeaponId, Slot, self.TheAttachmentId)
	end
end

function WeaponDetailAttachItem:IsSelected()
	local CurAttachmentId = self:GetCurAttachmentId()
	if CurAttachmentId > 0 and CurAttachmentId == self.TheAttachmentId then
		return true
	end
	return false
end


function WeaponDetailAttachItem:UpdateHoverIndex()
	local Handler = self.Param and self.Param.Handler or nil
	if Handler ~= nil then
		self.Param.Handler:UpdateHoverItem(self.Index)
	end
end

function WeaponDetailAttachItem:OnItemHover()
	self:UpdateHoverIndex()
end

function WeaponDetailAttachItem:OnItemUnhovered()
	self:SetUnhover()
end

function WeaponDetailAttachItem:Select()
	if not(self.bVXE_Btn_Select) and self.View.VXE_Btn_Select then
		self.bVXE_Btn_Select = true
		self.View:VXE_Btn_Select()
	end

	self:UpdateAttachmentEquiped(true)
end

function WeaponDetailAttachItem:UnSelect()
	if self.bVXE_Btn_Select and self.View.VXE_Btn_UnSelect then
		self.bVXE_Btn_Select = false
		self.View:VXE_Btn_UnSelect()
	end


	self:UpdateAttachmentEquiped(false)
end

return WeaponDetailAttachItem