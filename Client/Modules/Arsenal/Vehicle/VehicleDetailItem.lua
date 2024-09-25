--[[
    载具Item
]]
local class_name = "VehicleDetailItem";
VehicleDetailItem = VehicleDetailItem or BaseClass(nil, class_name);

function VehicleDetailItem:OnInit()
    self.BindNodes = 
    {
		{ UDelegate = self.View.GUIButtonItem.OnClicked,				Func = Bind(self, self.OnUnLockWeaponClick) },
	}
end


function VehicleDetailItem:OnShow(Param)
    self.Param = Param
	-- self:Unhover()
end

function VehicleDetailItem:OnHide()
end

function VehicleDetailItem:OnUnLockWeaponClick()
	if self.Param.OnItemClick then
        self.Param.OnItemClick(self, self.VehicleId, self.Index)
    end
end
 
function VehicleDetailItem:SetItemData(VehicleId, Index)
	self.Index = Index
	self.VehicleId = VehicleId


	--设置名称
	local VehicleCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleConfig, Cfg_VehicleConfig_P.VehicleId, VehicleId)

	local ItemId = VehicleCfg[Cfg_VehicleConfig_P.ItemId]

	--装备状态
	self.IsEquiped = MvcEntry:GetModel(VehicleModel):GetSelectVehicleId() == VehicleId
	self.IsUnLocked = true

	local Param ={
		ItemId = ItemId,
		ItemName = StringUtil.Format(VehicleCfg and VehicleCfg[Cfg_VehicleConfig_P.Name] or ""),
		bCancelQuality = true
	}
	CommonUtil.SetCommonName(self.View.WBP_Common_Name, Param)
	
	--设置图标
	local VehicleSkinId = MvcEntry:GetModel(VehicleModel):GetVehicleSkinId(VehicleId)
	local VehicleSkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_VehicleSkinConfig, Cfg_VehicleSkinConfig_P.SkinId, VehicleSkinId)
	local SkinIconPath = VehicleSkinCfg and VehicleSkinCfg[Cfg_VehicleSkinConfig_P.SkinListIcon] or ""

	CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageIcon, SkinIconPath)
	
	--质量
	self:SetItemQuality(ItemId)
	
	--设置角标
	self:SetCornerTag()

	-- 绑定红点
	self:RegisterRedDot()
end

---品质
function VehicleDetailItem:SetItemQuality(ItemId)
	-- local itemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemId)
	-- local Quality = itemCfg and itemCfg[Cfg_ItemConfig_P.Quality] or 0
	-- CommonUtil.SetQualityBgHorizontal(self.View.GUIImageBg, Quality)

	-- 背景图片暂不需要品质,用T_Common_Bg_Arsenal_None
	local Path = "Texture2D'/Game/Arts/UI/2DTexture/Common/Common_Bg_Quality/T_Common_Bg_Arsenal_None.T_Common_Bg_Arsenal_None'"
	CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageBg, Path)
end

---设置角标
function VehicleDetailItem:SetCornerTag()
	
	-- if self.IsEquiped then
	-- 	CommonUtil.SetCornerTagImg(self.View.GUIImage_CornerTag, CornerTagCfg.Equipped.TagId)
	-- 	self.View.GUIImage_CornerTag:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	-- 	self.View.ImgBgLock:SetVisibility(UE.ESlateVisibility.Collapsed)
	-- 	return
	-- end

	-- if not(self.IsUnLocked) then
	-- 	CommonUtil.SetCornerTagImg(self.View.GUIImage_CornerTag, CornerTagCfg.Lock.TagId)
	-- 	self.View.GUIImage_CornerTag:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	-- 	self.View.ImgBgLock:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	-- else
	-- 	self.View.GUIImage_CornerTag:SetVisibility(UE.ESlateVisibility.Collapsed)
	-- 	self.View.ImgBgLock:SetVisibility(UE.ESlateVisibility.Collapsed)
	-- end

	-- 在详情界面不需要显示角标
	self.View.GUIImage_CornerTag:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.View.ImgBgLock:SetVisibility(UE.ESlateVisibility.Collapsed)
end

function VehicleDetailItem:IsSelected()
	return self.Secected or false
end

function VehicleDetailItem:Select()
	self.Secected = true
	self.View:VXE_Btn_Select()
	self:InteractRedDot()
end

function VehicleDetailItem:UnSelect()
	self.Secected = false
	self.View:VXE_Btn_UnSelect()
end

----------------------------------------------reddot >>
-- 绑定红点
function VehicleDetailItem:RegisterRedDot()
	if self.View.WBP_RedDotFactory then
		local RedDotKey = "ArsenalVehicle_"
		local RedDotSuffix = self.VehicleId
		if not self.RedDotItem then
			self.RedDotItem = UIHandler.New(self,  self.View.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
		else
			self.RedDotItem:ChangeKey(RedDotKey, RedDotSuffix)
		end
	end
end

-- 红点触发逻辑
function VehicleDetailItem:InteractRedDot()
    if self.RedDotItem then
        self.RedDotItem:Interact()
    end
end
----------------------------------------------reddot >>