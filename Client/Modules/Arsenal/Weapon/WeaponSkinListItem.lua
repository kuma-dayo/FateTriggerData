--[[
    武器皮肤Item
]]
local class_name = "WeaponSkinListItem";
local WeaponSkinListItem = BaseClass(nil, class_name)

function WeaponSkinListItem:OnInit()
    self.BindNodes = 
    {
		-- { UDelegate = self.View.BtnUnLock.OnClicked,				Func = Bind(self, self.OnSkinClicked) },
		-- { UDelegate = self.View.BtnUnLock.OnHovered,				Func = Bind(self, self.OnSkinHovered) },
		-- { UDelegate = self.View.BtnUnLock.OnUnhovered,				Func = Bind(self, self.OnSkinUnhovered) },

		-- { UDelegate = self.View.BtnLock.OnClicked,				    Func = Bind(self, self.OnSkinClicked) },
		-- { UDelegate = self.View.BtnLock.OnHovered,				    Func = Bind(self, self.OnSkinHovered) },
		-- { UDelegate = self.View.BtnLock.OnUnhovered,				Func = Bind(self, self.OnSkinUnhovered) },

		{ UDelegate = self.View.GUIButtonItem.OnClicked,				Func = Bind(self, self.OnSkinClicked) },
	}
end


function WeaponSkinListItem:OnShow(Param)
    self.Param = Param
	-- self:Unhover()
end

function WeaponSkinListItem:OnHide()
end

function WeaponSkinListItem:OnSkinClicked()
    if self.Param.OnItemClick then
        self.Param.OnItemClick(self, self.WeaponSkinInfo, self.Index)
    end
end

-- function WeaponSkinListItem:OnSkinHovered()
-- 	self:Hover()
-- end

-- function WeaponSkinListItem:OnSkinUnhovered()
-- 	self:Unhover()
-- end


--皮肤是否解锁
function WeaponSkinListItem:GetIsUnLocked()
	if self.WeaponSkinInfo == nil then
		return false
	end
	local SkinId = self.WeaponSkinInfo.SkinId
	return MvcEntry:GetModel(WeaponModel):HasWeaponSkin(SkinId)
end

--皮肤是否装备
function WeaponSkinListItem:GetIsSkinEquiped()
	if self.WeaponSkinInfo == nil then
		return false
	end
	local CurSelectWeaponSkinId = MvcEntry:GetModel(WeaponModel):GetWeaponSelectSkinId(self.WeaponId) 
    return CurSelectWeaponSkinId == self.WeaponSkinInfo.SkinId
end

-- -- 设置名字在不同状态下的显示
-- function WeaponSkinListItem:SetLbNameColorAndOpacity(LbName,IsLock,IsSelect)
-- 	local HexColor  = IsSelect and (IsLock and "1B2024" or "2F2926") or (IsLock and "F5EFDF" or "A29F96")
-- 	local Opacity = IsSelect and (IsLock and 0.5 or 1) or (IsLock and 0.2 or 1)
-- 	CommonUtil.SetTextColorFromeHex(LbName,HexColor,Opacity)
--  end

--  -- 设置角标在不同状态的显示
-- function WeaponSkinListItem:SetTagIconColocAndOpacity(TagIcon,IsLock,IsSelect)
-- 	local CurOpacity = TagIcon:GetRenderOpacity()
-- 	local HexColor = IsSelect and (IsLock and "1B2024" or "B14900") or "FFFFFF"
-- 	local Opacity = IsSelect and (IsLock and 0.2 or 1)/CurOpacity or (IsLock and 0.2/CurOpacity or 0.3/CurOpacity)
-- 	CommonUtil.SetBrushTintColorFromHex(TagIcon,HexColor,Opacity)
-- end

function WeaponSkinListItem:IsSelected()
	-- if self.View.OverlayUnLockSelect:GetVisibility() == UE.ESlateVisibility.SelfHitTestInvisible 
	-- 	or self.View.OverlayLockSelect:GetVisibility() == UE.ESlateVisibility.SelfHitTestInvisible then
	-- 	return true
	-- end
	-- return false
	return self.Secected or false
end
	
function WeaponSkinListItem:SetItemData(WeaponSkinInfo, WeaponId, Index)
	if WeaponSkinInfo == nil or Index == nil then
		return
	end
	
	self.Index = Index
	self.WeaponSkinInfo = WeaponSkinInfo
	self.WeaponId = WeaponId

	if WeaponSkinInfo == nil then
		CError(string.format("WeaponSkinListItem:SetItemData WeaponSkinInfo == nil !!!! WeaponId = %s", tostring(WeaponId)))
		return
	end

	local SkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig, Cfg_WeaponSkinConfig_P.SkinId, self.WeaponSkinInfo.SkinId)
	if SkinCfg == nil then
		CError(string.format("WeaponSkinListItem:SetItemData WeaponSkinInfo == nil !!!! WeaponId = %s,SkinId = %s", tostring(WeaponId),tostring(self.WeaponSkinInfo.SkinId)))
		return
	end
	local ItemId = SkinCfg[Cfg_WeaponSkinConfig_P.ItemId]

	self.IsEquiped = self:GetIsSkinEquiped()
	self.IsUnLocked = self:GetIsUnLocked()

	--名字
	local SkinName = self.WeaponSkinInfo.SkinName
	local Param ={
		ItemId = ItemId,
		ItemName = SkinName
	}
	CommonUtil.SetCommonName(self.View.WBP_Common_Name, Param)

	--图标
	local WSCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig, Cfg_WeaponSkinConfig_P.SkinId, self.WeaponSkinInfo.SkinId)
	local SkinIconPath = WSCfg and WSCfg[Cfg_WeaponSkinConfig_P.SkinListIcon] or ""
	CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageIcon, SkinIconPath)

	--品质
	self:SetItemQuality(ItemId)

	--设置角标
	self:SetCornerTag()

	-- 绑定红点
	self:RegisterRedDot()
end

---品质
function WeaponSkinListItem:SetItemQuality(ItemId)
	local itemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
	local Quality = itemCfg and itemCfg[Cfg_ItemConfig_P.Quality] or 0
	CommonUtil.SetQualityBgHorizontal(self.View.GUIImageBg, Quality)
end

---设置角标
function WeaponSkinListItem:SetCornerTag()
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

function WeaponSkinListItem:Select()
	self.Secected = true
	self.View:VXE_Btn_Select()

	self:InteractRedDot()
end

function WeaponSkinListItem:UnSelect()
	self.Secected = false
	self.View:VXE_Btn_UnSelect()
end

----------------------------------------------reddot >>
-- 绑定红点
function WeaponSkinListItem:RegisterRedDot()
	if self.View.WBP_RedDotFactory and self.WeaponSkinInfo and self.WeaponSkinInfo.SkinId then
		local RedDotKey = "ArsenalWeaponSkinItem_"
		local RedDotSuffix = self.WeaponSkinInfo.SkinId
		if not self.RedDotItem then
			self.RedDotItem = UIHandler.New(self,  self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
		else
			self.RedDotItem:ChangeKey(RedDotKey, RedDotSuffix)
		end
	end

	if self.IsEquiped then
		self:InteractRedDot()
	end
end

-- 红点触发逻辑
function WeaponSkinListItem:InteractRedDot()
    if self.RedDotItem then
        self.RedDotItem:Interact()
    end
end
----------------------------------------------reddot >>

return WeaponSkinListItem