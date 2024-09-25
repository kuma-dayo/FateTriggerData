--[[n
    武器皮肤Item
]]
local class_name = "VehicleSkinListItem";
local VehicleSkinListItem = BaseClass(nil, class_name)

function VehicleSkinListItem:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.View.GUIButtonItem.OnClicked,				Func = Bind(self, self.OnSkinClicked) },
	}
end


function VehicleSkinListItem:OnShow(Param)
    self.Param = Param
end

function VehicleSkinListItem:OnHide()
end

function VehicleSkinListItem:OnSkinClicked()
    if self.Param.OnItemClick then
        self.Param.OnItemClick(self, self.VehicleSkinInfo, self.Index)
    end
end


--皮肤是否解锁
function VehicleSkinListItem:GetIsUnLocked()
	if self.VehicleSkinInfo == nil then
		return false
	end
	local SkinId = self.VehicleSkinInfo.SkinId
	return MvcEntry:GetModel(VehicleModel):HasVehicleSkin(SkinId)
end

--皮肤是否装备
function VehicleSkinListItem:GetIsSkinEquiped()
	if self.VehicleSkinInfo == nil then
		return false
	end
	local CurSelectVehicleSkinId = MvcEntry:GetModel(VehicleModel):GetVehicleSelectSkinId(self.VehicleId) 
    return CurSelectVehicleSkinId == self.VehicleSkinInfo.SkinId
end

function VehicleSkinListItem:IsSelected()
	return self.Secected or false
end
	
function VehicleSkinListItem:SetItemData(VehicleSkinInfo, VehicleId, Index)
	if VehicleSkinInfo == nil or Index == nil then
		return
	end
	
	self.Index = Index
	self.VehicleSkinInfo = VehicleSkinInfo
	self.VehicleId = VehicleId

	if VehicleSkinInfo == nil then
		CError(string.format("VehicleSkinListItem:SetItemData VehicleSkinInfo == nil !!!! VehicleId = %s", tostring(VehicleId)))
		return
	end

	local SkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig, Cfg_VehicleSkinConfig_P.SkinId, self.VehicleSkinInfo.SkinId)
	if SkinCfg == nil then 
		CError(string.format("VehicleSkinListItem:SetItemData SkinCfg == nil !!!! VehicleId = %s,SkinId = %s", tostring(VehicleId), tostring(self.VehicleSkinInfo.SkinId)))
		return
	end
	local ItemId = SkinCfg[Cfg_VehicleSkinConfig_P.ItemId]

	self.IsEquiped = self:GetIsSkinEquiped()
	self.IsUnLocked = self:GetIsUnLocked()
	
	--名字
	local SkinName = self.VehicleSkinInfo.SkinName
	local Param ={
		ItemId = ItemId,
		ItemName = StringUtil.Format(SkinName)
	}
	CommonUtil.SetCommonName(self.View.WBP_Common_Name, Param)

	--图标
	local WSCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig, Cfg_VehicleSkinConfig_P.SkinId, self.VehicleSkinInfo.SkinId)
	local SkinIconPath = WSCfg and WSCfg[Cfg_VehicleSkinConfig_P.SkinListIcon] or ""
	CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageIcon, SkinIconPath)

	self:SetItemQuality(ItemId)

	--设置角标
	self:SetCornerTag()
	
	-- 绑定红点
	self:RegisterRedDot()
end

---品质
function VehicleSkinListItem:SetItemQuality(ItemId)
	local itemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
	local Quality = itemCfg and itemCfg[Cfg_ItemConfig_P.Quality] or 0
	CommonUtil.SetQualityBgHorizontal(self.View.GUIImageBg, Quality)
end

---设置角标
function VehicleSkinListItem:SetCornerTag()
	if self.IsEquiped then
		CommonUtil.SetCornerTagImg(self.View.GUIImage_CornerTag, CornerTagCfg.Equipped.TagId)
		self.View.GUIImage_CornerTag:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		self.View.ImgBgLock:SetVisibility(UE.ESlateVisibility.Collapsed)
		return
	end

	if not(self.IsUnLocked) then
		CommonUtil.SetCornerTagImg(self.View.GUIImage_CornerTag, CornerTagCfg.Lock.TagId)
		self.View.GUIImage_CornerTag:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		self.View.ImgBgLock:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	else
		self.View.GUIImage_CornerTag:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.View.ImgBgLock:SetVisibility(UE.ESlateVisibility.Collapsed)
	end
end

function VehicleSkinListItem:Select()
	self.Secected = true
	self.View:VXE_Btn_Select()

	self:InteractRedDot()
end

function VehicleSkinListItem:UnSelect()
	self.Secected = false
	self.View:VXE_Btn_UnSelect()
end

----------------------------------------------reddot >>
-- 绑定红点
function VehicleSkinListItem:RegisterRedDot()
	if self.View.WBP_RedDotFactory and self.VehicleSkinInfo and self.VehicleSkinInfo.SkinId then
		local RedDotKey = "ArsenalVehicleSkinItem_"
		local RedDotSuffix = self.VehicleSkinInfo.SkinId
		if not self.RedDotItem then
			self.RedDotItem = UIHandler.New(self,  self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
		else
			self.RedDotItem:ChangeKey(RedDotKey, RedDotSuffix)
		end
	end
end

-- 红点触发逻辑
function VehicleSkinListItem:InteractRedDot()
    if self.RedDotItem then
        self.RedDotItem:Interact()
    end
end
----------------------------------------------reddot >>

return VehicleSkinListItem