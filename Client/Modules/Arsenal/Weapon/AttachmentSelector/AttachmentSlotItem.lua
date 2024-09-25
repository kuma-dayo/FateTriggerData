--[[
	配件槽位Item
]]
local class_name = "AttachmentSlotItem";
local AttachmentSlotItem = BaseClass(nil, class_name)
local AdvanceMarkHelper = require ("InGame.BRGame.UI.HUD.AdvanceMark.AdvanceMarkHelper")

function AttachmentSlotItem:OnInit()
    self.BindNodes = {
		{ UDelegate = self.View.GUIButtonSlot.OnClicked,  Func = Bind(self,self.OnSlotClicked) },
		{ UDelegate = self.View.GUIButtonSlot.OnHovered,  Func = Bind(self,self.OnSlotItemHover) },
		{ UDelegate = self.View.GUIButtonSlot.OnUnhovered,  Func = Bind(self,self.OnSlotItemUnhovered) }
	}
	-- UserWidget.OnInit(self)
	self.TheWeaponModel = MvcEntry:GetModel(WeaponModel)
end

function AttachmentSlotItem:OnDestroy()
	-- UserWidget.OnDestroy(self)
end


function AttachmentSlotItem:OnShow(Param)
    self.Param = Param
end

function AttachmentSlotItem:OnHide()
end

function AttachmentSlotItem:SetItemData(Slot, Index)
	self.AttachmentSlot = Slot
	self.Index = Index
	self:UpdateSlotIcon()
end


--设置默认槽位图标
function AttachmentSlotItem:SetDefaultSlotIcon(WeaponId)
	local SlotDefaultIcon =  self.TheWeaponModel:GetWeaponPartSlotDefaultIcon(WeaponId, self.AttachmentSlot)
	CommonUtil.SetBrushFromSoftObjectPath(self.View.Item_Icon, SlotDefaultIcon)
	
	local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg, 1)
	if QualityCfg then
		local QualityBgPath = QualityCfg[Cfg_ItemQualityColorCfg_P.PartSlotQualityIcon]
		CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_Bg_Quality, QualityBgPath)
	end

	self:SetGUIButtonSlotEmpty_VXE(true)
end

--设置皮肤图标
function AttachmentSlotItem:SetAttachmentSkinSlotIcon(AttchmentSkinId)
	local WeaponPartSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartSkinConfig, AttchmentSkinId)
	if WeaponPartSkinCfg == nil then
		return
	end
	local ItemCfg =  G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, WeaponPartSkinCfg[Cfg_WeaponPartSkinConfig_P.ItemId])
	if ItemCfg == nil then
		return
	end

	CommonUtil.SetBrushFromSoftObjectPath(self.View.Item_Icon, ItemCfg[Cfg_ItemConfig_P.IconPath])
	local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg, ItemCfg[Cfg_ItemConfig_P.Quality])
	if QualityCfg then
		local QualityBgPath = QualityCfg[Cfg_ItemQualityColorCfg_P.PartSlotQualityIcon]
		CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_Bg_Quality, QualityBgPath)
	end

	self:SetGUIButtonSlotEmpty_VXE(false)
end

--设置配件图标
function AttachmentSlotItem:SetAttachmentSlotIcon(AttchmentId)
	local WeaponPartCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartConfig, AttchmentId)
	if WeaponPartCfg == nil then
		return
	end
	local ItemCfg =  G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, WeaponPartCfg[Cfg_WeaponPartConfig_P.ItemId])
	if ItemCfg == nil then
		return
	end

	CommonUtil.SetBrushFromSoftObjectPath(self.View.Item_Icon, ItemCfg[Cfg_ItemConfig_P.IconPath])
	local QualityCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg, ItemCfg[Cfg_ItemConfig_P.Quality])
	if QualityCfg then
		local QualityBgPath = QualityCfg[Cfg_ItemQualityColorCfg_P.PartSlotQualityIcon]
		CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_Bg_Quality, QualityBgPath)
	end

	self:SetGUIButtonSlotEmpty_VXE(false)
end

function AttachmentSlotItem:SetGUIButtonSlotEmpty_VXE(bEmpty_VXE)
	if self.bIsEmpty_VXE == bEmpty_VXE then
		return
	end
	self.bIsEmpty_VXE = bEmpty_VXE
	if self.bIsEmpty_VXE then
		if self.View.VXE_Btn_Empty then
			self.View:VXE_Btn_Empty()
		end
	else
		if self.View.VXE_Btn_Normal then
			self.View:VXE_Btn_Normal()
		end
	end
end


function AttachmentSlotItem:UpdateSlotIcon()
	local WeaponId = self.Param and self.Param.Handler  and self.Param.Handler.CurSelectWeaponId or 0
	local WeaponSkinId =  self.Param and self.Param.Handler  and self.Param.Handler.CurWeaponSkinId or 0
	local UseAttachItemIcon = self.Param and self.Param.Handler  and self.Param.Handler.CanShowSelectAttachmentList or false
	if UseAttachItemIcon then
		local AttachmentId = self.TheWeaponModel:GetSlotEquipAttachmentId(WeaponId, self.AttachmentSlot)
		if AttachmentId and AttachmentId ~= 0 then
			self:SetAttachmentSlotIcon(AttachmentId)
		else 
			self:SetDefaultSlotIcon(WeaponId)
		end
	else
		local AttachmentSkinId = self.TheWeaponModel:GetSelectPartSkinIdBySelectPartId(WeaponSkinId, self.AttachmentSlot)
		if AttachmentSkinId and AttachmentSkinId ~= 0 then
			self:SetAttachmentSkinSlotIcon(AttachmentSkinId)
		else 
			self:SetDefaultSlotIcon(WeaponId)
		end
	end
end




function AttachmentSlotItem:OnSlotClicked()
	if self.Param and self.Param.Handler ~= nil then
		self.Param.Handler:SetKeyEventFocus(true)
	end
    if self.Param and self.Param.OnItemClick then
        self.Param.OnItemClick(self, self.AttachmentSlot, self.Index)
    end
end

function AttachmentSlotItem:OnSlotItemHover()
	if self.Param and self.Param.OnItemHover then
        self.Param.OnItemHover(self.AttachmentSlot)
    end
end

function AttachmentSlotItem:OnSlotItemUnhovered()
	if self.Param and self.Param.OnItemHover then
        self.Param.OnItemUnHover(self.AttachmentSlot)
    end
end

function AttachmentSlotItem:Select()
	if self.View.VXE_Btn_Select then
		self.View:VXE_Btn_Select()
	end
end

function AttachmentSlotItem:UnSelect()
	if self.View.VXE_Btn_UnSelect then
		self.View:VXE_Btn_UnSelect()
	end
end

return AttachmentSlotItem