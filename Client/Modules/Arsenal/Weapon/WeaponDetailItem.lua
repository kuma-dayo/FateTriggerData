--[[
    详情中：武器Item
]]
local class_name = "WeaponDetailItem";
WeaponDetailItem = WeaponDetailItem or BaseClass(nil, class_name);

function WeaponDetailItem:OnInit()
	CLog("WeaponDetailItem:OnInit()")
    self.BindNodes = 
    {
		{ UDelegate = self.View.GUIButtonItem.OnClicked,				    Func = Bind(self, self.OnUnLockWeaponClick) },
	}
end

function WeaponDetailItem:OnShow(Param)
    self.Param = Param
end

function WeaponDetailItem:OnHide()
end

function WeaponDetailItem:OnUnLockWeaponClick()
	if self.Param.OnItemClick then
        self.Param.OnItemClick(self, self.WeaponId, self.Index)
    end
end
 
function WeaponDetailItem:SetItemData(WeaponId, Index)
	if Index == nil then
		return
	end
	
	self.Index = Index
	self.WeaponId = WeaponId

	local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponConfig, Cfg_WeaponConfig_P.WeaponId, WeaponId)
	local ItemId = Cfg[Cfg_WeaponConfig_P.ItemId]

	--设置是否装备
	self.IsEquiped = MvcEntry:GetModel(WeaponModel):GetSelectWeaponId() == self.WeaponId
	self.IsUnLocked = true

	--名称
	local Param ={
		ItemId = ItemId,
		ItemName = MvcEntry:GetModel(DepotModel):GetItemName(ItemId),
		bCancelQuality = true
	}
	CommonUtil.SetCommonName(self.View.WBP_Common_Name, Param)
	
	--图标
	local WeaponSkinId = MvcEntry:GetModel(WeaponModel):GetWeaponSkinId(self.WeaponId)
	local WSCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig, Cfg_WeaponSkinConfig_P.SkinId, WeaponSkinId)
	local SkinIconPath = WSCfg and WSCfg[Cfg_WeaponSkinConfig_P.SkinListIcon] or ""
	CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageIcon, SkinIconPath)
	
	--质量
	self:SetItemQuality(ItemId)
	-- 设置角标
	self:SetCornerTag()

	-- 绑定红点
	self:RegisterRedDot()
end

--皮肤是否解锁
function WeaponDetailItem:GetIsUnLocked()
	if self.VehicleSkinInfo == nil then
		return false
	end
	local SkinId = self.VehicleSkinInfo.SkinId
	return MvcEntry:GetModel(VehicleModel):HasVehicleSkin(SkinId)
end


---品质
function WeaponDetailItem:SetItemQuality(ItemId)
	-- 背景图片暂不需要品质,用T_Common_Bg_Arsenal_None
	local Path = "Texture2D'/Game/Arts/UI/2DTexture/Common/Common_Bg_Quality/T_Common_Bg_Arsenal_None.T_Common_Bg_Arsenal_None'"
	CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageBg, Path)
end

---设置角标
function WeaponDetailItem:SetCornerTag()
	-- 在详情界面不需要显示角标
	self.View.GUIImage_CornerTag:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.View.ImgBgLock:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function WeaponDetailItem:IsSelected()
	return self.Secected or false
end

function WeaponDetailItem:Select()
	self.Secected = true
	self.View:VXE_Btn_Select()
	self:InteractRedDot()
end

function WeaponDetailItem:UnSelect()
	self.Secected = false
	self.View:VXE_Btn_UnSelect()
end

----------------------------------------------reddot >>
-- 绑定红点
function WeaponDetailItem:RegisterRedDot()
	if self.View.WBP_RedDotFactory then
		local RedDotKey = "ArsenalWeapon_"
		local RedDotSuffix = self.WeaponId
		if not self.RedDotItem then
			self.RedDotItem = UIHandler.New(self,  self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
		else
			self.RedDotItem:ChangeKey(RedDotKey, RedDotSuffix)
		end
	end
end

-- 红点触发逻辑
function WeaponDetailItem:InteractRedDot()
    if self.RedDotItem then
        self.RedDotItem:Interact()
    end
end
----------------------------------------------reddot >>

return WeaponDetailItem