require "UnLua"

local BP_HallWeapon = Class("Client.Modules.Hall.BP_HallAvatarBase")

require("Client.Modules.Common.CommonTransformLerp")

BP_HallWeapon.ShowLSTag = "ShowWeapon"

function BP_HallWeapon:ReceiveBeginPlay()
	self.Super.ReceiveBeginPlay(self)
	-- 通用的插值
	self.CommonTransformLerpInst = CommonTransformLerp.New()

	--装配的虚拟配件
	self.WeaponSkin2Slot2VirtualAvatarIdList = {}
end

function BP_HallWeapon:ReceiveEndPlay(EndPlayReason)
	self.Super.ReceiveEndPlay(self,EndPlayReason)

	if self.CommonLerpInst ~= nil then
		self.CommonLerpInst:End()
		self.CommonLerpInst = nil
	end
end

function BP_HallWeapon:Show(IsShow, SkinId)
	if not IsShow then
		if self.CacheSpawnParam.PlayShowLS then
			MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(BP_HallWeapon.ShowLSTag)
		end
	end
	self.Super.Show(self,IsShow, SkinId)
	if IsShow then
		if self.CacheSpawnParam.PlayShowLS then
			self:PlayShowLS()
		end
		if self.CacheSpawnParam.PlayDissolveLS then
			self:PlayDissolveLS()
		end
	end
end

function BP_HallWeapon:SpawnSkinAvatar(SkinId, ForbidUseRelativeTransform)
	local WeaponSkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig,
		Cfg_WeaponSkinConfig_P.SkinId, SkinId)
    if WeaponSkinCfg == nil then 
        return 
    end
	local IsCreate = self.Super.SpawnSkinAvatarAction(self, SkinId, WeaponSkinCfg[Cfg_WeaponSkinConfig_P.SystemBP], ForbidUseRelativeTransform)

	local AvatarComponent = self:GetAvatarComponent(SkinId)
	if AvatarComponent then
		MvcEntry:GetModel(WeaponModel):CreateDefaultAvatarsBySkinId(AvatarComponent, SkinId,self.CacheSpawnParam.UserSelectPartCache or false)
	end

	local HallAvatarComponent = self:GetHallAvatarComponent(SkinId)
	if HallAvatarComponent then
		HallAvatarComponent:SetForceLOD(1)
	end
end

function BP_HallWeapon:PlayShowLS()
	local CfgWeapon = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig,self:GetCurShowSkinId())
	if not CfgWeapon then
		return
	end
	local CfgWeaponItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, CfgWeapon[Cfg_WeaponSkinConfig_P.ItemId])
	if not CfgWeaponItem then
		return
	end
	local CfgWeaponItemQuality = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg, CfgWeaponItem[Cfg_ItemConfig_P.Quality])
	if not CfgWeaponItemQuality then
		return
	end
	local SetBindings = {{
		Actor = self:GetSkinActor(), 
		TargetTag = SequenceModel.BindTagEnum.WEAPON_SKELETMESH_COMPONENT,
	}}
	local PlayParam = {
		LevelSequenceAsset = CfgWeaponItemQuality[Cfg_ItemQualityColorCfg_P.CommonWeaponLS],
		SetBindings = SetBindings,
		-- ForceStopAfterFinish = true,
		UseCacheSequenceActorByTag = true,
	}
	MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(BP_HallWeapon.ShowLSTag, nil, PlayParam)
end

function BP_HallWeapon:PlayDissolveLS(IsOut)
	local LSPath = MvcEntry:GetModel(HallModel):GetLSPathById(IsOut and HallModel.LSTypeIdEnum.LS_WEAPON_DISSOLVE_OUT or HallModel.LSTypeIdEnum.LS_WEAPON_DISSOLVE)
    if not LSPath then
        return
    end
	local SetBindings = {{
		Actor = self:GetSkinActor(), 
		TargetTag = SequenceModel.BindTagEnum.WEAPON_SKELETMESH_COMPONENT,
	}}
    local PlayParam = {
        LevelSequenceAsset = LSPath,
        SetBindings = {SetBindings},
    }
    MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("WeaponDissolve", function()
    end, PlayParam)
end

----【穿戴功能】-----

function BP_HallWeapon:InitApparelSlotTypeList()
	self.Super.InitApparelSlotTypeList(self)
end


function BP_HallWeapon:GetApparelAttachMesh(SkinId)
	return self.Super.GetApparelAttachMesh(self, SkinId)
end

function BP_HallWeapon:RefreshAllDefaultAvatars(SkinId)
	local AvatarComponent = self:GetAvatarComponent(SkinId)
	if not AvatarComponent then
		return
	end
	AvatarComponent:RefreshAllDefaultAvatars()
end

--[[
	为枪支更新配件
	AvatarId 配件ID，对应DA ID
	SkinId  皮肤ID  可选，不填则是当前皮肤ID
]]
function BP_HallWeapon:AttachAvatarByID(AvatarId,SkinId, ForceLodAfterAttach)
	if not AvatarId or AvatarId <= 0  then
		return
	end
	local AvatarComponent = self:GetAvatarComponent(SkinId)
	if not AvatarComponent then
		return
	end
	CWaring("BP_HallWeapon:AttachAvatarByID:" .. AvatarId)
	AvatarComponent:AddAvatarByID(AvatarId)
	
	if ForceLodAfterAttach then
		local HallAvatarComponent = self:GetHallAvatarComponent(SkinId)
		if HallAvatarComponent then
			HallAvatarComponent:SetForceLOD(1)
		end
	end
end
--[[
	为枪支移除配件
	AvatarId 配件ID，对应DA ID
	SkinId  皮肤ID  可选，不填则是当前皮肤ID
]]
function BP_HallWeapon:RemoveAvatarByID(AvatarId,SkinId)
	if not AvatarId or AvatarId <= 0 then
		return
	end
	local AvatarComponent = self:GetAvatarComponent(SkinId)
	if not AvatarComponent then
		return
	end
	CWaring("BP_HallWeapon:RemoveAvatarByID:" .. AvatarId)
	AvatarComponent:RemoveAvatarByID(AvatarId)
end

function BP_HallWeapon:RemoveAvatarBySlotTag(SlotTag,SkinId)
	if not SlotTag then
		return
	end
	local AvatarComponent = self:GetAvatarComponent(SkinId)
	if not AvatarComponent then
		return
	end
	CWaring("BP_HallWeapon:RemoveAvatarBySlotType:" .. SlotTag.TagName)
	AvatarComponent:RemoveAvatarBySlotType(SlotTag)
end

--[[
	获取当前皮肤的AvatarComponent
	没有则返回空值
]]
function BP_HallWeapon:GetAvatarComponent(SkinId)
	local SkinActor = self:GetSkinActor(SkinId)
	if not SkinActor then
		return
	end
	local AvatarComponent = SkinActor.BP_HallWeaponAvatarComponent
	return AvatarComponent
end

function BP_HallWeapon:GetHallAvatarComponent(SkinId)
	local SkinActor = self:GetSkinActor(SkinId)
	if not SkinActor then
		return
	end
	local AvatarComponent = SkinActor.BP_HallAvatarComponent
	return AvatarComponent
end


--[[
	获取组装进的Component组件
]]
function BP_HallWeapon:GetAvatarAttachedMeshComponent(Slot)
	local AvatarComponent = self:GetAvatarComponent()
	if not AvatarComponent then
		return
	end
	local ComponentTag = MvcEntry:GetModel(WeaponModel):GetSlotTagBySlotType(Slot)
	return AvatarComponent:GetAttachedMeshComponent(ComponentTag, false)
end

--[[
	获取武器中的部件特效
]]
function BP_HallWeapon:GetAvatarNiagraConfig(Slot)
	local SkinActor = self:GetSkinActor()
	if SkinActor == nil then
		return
	end
	return SkinActor.SlotSocket2NiagaraMap:Find(Slot)
end


--[[
	预览配件
]]
function BP_HallWeapon:PreviewWeaponPartWithCamerFocus(TargetTrans, Slot)
	if self.CommonTransformLerpInst == nil then
		return
	end
	local Param = 
	{
		ActorInst = self,
		ActorComponentInst = self:GetAvatarAttachedMeshComponent(Slot),
		TargetTransform = TargetTrans,
		LerpTime = self.TLerpLerpTime,
		LerpType = self.TLerpLerpType,
		LerpCurve = self.TLerpFloatCurve,
		ChgCameraFoucsSetting2ActorComponentInst = true
	}
	self.CommonTransformLerpInst:Start(Param)
end


--[[
	枪械皮肤槽位上展示虚拟配件，用于效果展示
]]--
function BP_HallWeapon:AttachVirutalPartSkinList(SkinId)
	local AvatarComponent = self:GetAvatarComponent(SkinId)
	if AvatarComponent == nil then
		return
	end
	local WeaponSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponSkinConfig, SkinId) 
    local WeaponId = WeaponSkinCfg[Cfg_WeaponSkinConfig_P.WeaponId]
    local WeaponCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponConfig,WeaponId)
    local SlotTypeList = WeaponCfg[Cfg_WeaponConfig_P.AvailableSlotList]
	local TheWeaponModel =  MvcEntry:GetModel(WeaponModel)
	
	for k,SlotType in pairs(SlotTypeList) do
		local ComponentTag = TheWeaponModel:GetSlotTagBySlotType(SlotType)
		local AttachedMeshComponent = AvatarComponent:GetAttachedMeshComponent(ComponentTag, false)
		if not AttachedMeshComponent then
			local AvatarId = TheWeaponModel:GetVirtualAvatarIdIdBySkindAndSlot(SkinId, SlotType)
			if AvatarId > 0 then
				-- CWaring("NOT ATTACHED: WeaponModel:AttachVirutalPartSkinList WeaponId:".. WeaponId .. " SkinId:" .. SkinId .. " SlotType:" .. SlotType .. " AddAvatarByID:" .. AvatarId)
				self:AttachAvatarByID(AvatarId, SkinId)
		
				--设置它的虚空材质
				AttachedMeshComponent = AvatarComponent:GetAttachedMeshComponent(ComponentTag, false)
				if AttachedMeshComponent then
					local WeaponPartSlotCfg = G_ConfigHelper:GetSingleItemById(Cfg_WeaponPartSlotConfig, SlotType)
					local Material = LoadObject(WeaponPartSlotCfg[Cfg_WeaponPartSlotConfig_P.SlotDefaultMaterialInst])
					if Material ~= nil then
						local MaterialInst = UE.UKismetMaterialLibrary.CreateDynamicMaterialInstance(self, Material)
						UE.UGameHelper.SetMeshComponentMaterial(AttachedMeshComponent, MaterialInst)
					end
				end
			end		
		end
		if AttachedMeshComponent then
			local AvatarId = AvatarComponent:GetAttachAvatarID(ComponentTag)
			local VirtualAvatarId = TheWeaponModel:GetVirtualAvatarIdIdBySkindAndSlot(SkinId, SlotType)
			-- CWaring(StringUtil.Format("AttachVirutalPartSkinList: AvatarId = {0} ========== VirtualAvatarId = {1} ",AvatarId, VirtualAvatarId))
			if AvatarId > 0 and VirtualAvatarId == AvatarId then
				AttachedMeshComponent:SetHiddenInGame(true)
			else
				AttachedMeshComponent:SetHiddenInGame(false)
			end
		end
    end
end


return BP_HallWeapon
