require "UnLua"

local BP_HallCharacter = Class("Client.Modules.Hall.BP_HallAvatarBase")

BP_HallCharacter.ShowLSTag = "ShowCharater"
BP_HallCharacter.DISAPPEAR_SCALE = UE.FVector(0.0001,0.0001,1)
BP_HallCharacter.ORIGIN_SCALE = UE.FVector(1,1,1)
BP_HallCharacter.CHECK_MAX_TIME = 0.5

function BP_HallCharacter:ReceiveBeginPlay()
	self.Super.ReceiveBeginPlay(self)
	self:SetCompHasBeenPrepared(false)
end

function BP_HallCharacter:ReceiveEndPlay(EndPlayReason)
	self.Super.ReceiveEndPlay(self,EndPlayReason)
	---角色销毁或隐藏时,停止她的语音
	SoundMgr:StopPlayAllVoice()
	SoundMgr:StopPlayAllEffect()
	self:SetCompHasBeenPrepared(false)
end

function BP_HallCharacter:Show(IsShow, SkinId)
	self:SetCompHasBeenPrepared(false)
	if not IsShow then
		if self.CacheSpawnParam.PlayShowLS then
			print("Sequence play ============ hidden", self.CurShowSkinId)
			MvcEntry:GetCtrl(SequenceCtrl):StopSequenceByTag(BP_HallCharacter.ShowLSTag)
		end
	end
	self.Super.Show(self,IsShow, SkinId)
	if not IsShow then
		---角色销毁或隐藏时,停止她的语音
		SoundMgr:StopPlayAllVoice()
		SoundMgr:StopPlayAllEffect()
	else
		if self.CacheSpawnParam.PlayShowLS then
			self:PlayShowLS()
		end
	end
end

--[[
	重写父类方法
]]
function BP_HallCharacter:SpawnSkinAvatar(SkinId, ForbidUseRelativeTransform)
	local HeroSkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin, Cfg_HeroSkin_P.SkinId, SkinId)
	if HeroSkinCfg == nil then 
        return 
    end
	local IsCreate = self.Super.SpawnSkinAvatarAction(self, SkinId, HeroSkinCfg.SkinBP, ForbidUseRelativeTransform)

	local AvatarComponent = self:GetAvatarComponent(SkinId)
	MvcEntry:GetModel(HeroModel):CreateDefaultAvatarsBySkinId(AvatarComponent, self.CacheSpawnParam.InstID, SkinId, self.CacheSpawnParam.CustomPartList)
	
	-- if IsCreate then
		local DefaultIdelAnimClip = self.CacheSpawnParam.DefaultIdelAnimClip
		if not self.CacheSpawnParam.DefaultIdelAnimClip then
			DefaultIdelAnimClip = MvcEntry:GetModel(HeroModel):GetAnimClipPathBySkinIdAndKey(SkinId,HeroModel.LSEventTypeEnum.IdleDefault)
		end
		self:PlayAnimClip(DefaultIdelAnimClip,true,SkinId)
	-- end
	
	-- if OpenCapture2D then 
	-- 	local AvatarActor = self.Super.GetSkinActor(self, SkinId)
	-- 	if AvatarActor ~= nil then
	-- 		self:OpenOrCloseCapture2D(AvatarActor,true)
	-- 	end
	-- end
	
	self:SetRenderOnTop(SkinId, self.CacheSpawnParam.SetRenderOnTop or false)
	self:SetAvatarAnimBlend(SkinId, true)

	local TActor = self:GetSkinActor(SkinId)
	TActor:SetActorScale3D(BP_HallCharacter.DISAPPEAR_SCALE)

	self.OriginTimeStamp = GetTimestamp()
end

function BP_HallCharacter:PlayShowLS()
	local SetBindings = {{
		Actor = self:GetSkinActor(), 
		TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_COMPONENT,
	}}

	local WaitUtilActorHasBeenPrepared = self.CacheSpawnParam.ShowLSNeedWaitCharaterPrepared
	if WaitUtilActorHasBeenPrepared == nil then
		WaitUtilActorHasBeenPrepared = true
	end

	local PlayParam = {
		LevelSequenceAsset = MvcEntry:GetModel(HallModel):GetLSPathById(HallLSCfg.LS_COMMON_CHARATER_SWITCH.HallLSId),
		SetBindings = SetBindings,
		ForceStopAfterFinish = true,
		UseCacheSequenceActorByTag = true,
		WaitUtilActorHasBeenPrepared = WaitUtilActorHasBeenPrepared
	}
	print("Sequence play ============", self.CurShowSkinId)
	MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(BP_HallCharacter.ShowLSTag, nil, PlayParam)
end

function BP_HallCharacter:SetRenderOnTop(SkinId, InRenderOnTop)
	local HallAvatarCommonComponent = self:GetHallAvatarCommonComponent(SkinId)
	if not HallAvatarCommonComponent then
		return
	end
	HallAvatarCommonComponent:SetRenderOnTop(InRenderOnTop)
end

function BP_HallCharacter:GetAvatarComponent(SkinId)
	local SkinActor = self:GetSkinActor(SkinId)
	if not SkinActor then
		return
	end
	local AvatarComponent = SkinActor.BP_HallCharaterAvatarComponent
	return AvatarComponent
end

--[[
	为角色皮肤更新配件
	AvatarId 配件ID，对应DA ID
	SkinId  皮肤ID  可选，不填则是当前皮肤ID
]]
function BP_HallCharacter:AttachAvatarByID(AvatarId,SkinId)
	if not AvatarId or AvatarId <= 0  then
		return
	end
	local AvatarComponent = self:GetAvatarComponent(SkinId)
	if not AvatarComponent then
		return
	end
	CWaring("BP_HallCharacter:AttachAvatarByID:" .. AvatarId)
	AvatarComponent:AddAvatarByID(AvatarId)
end
--[[
	为角色皮肤移除配件
	AvatarId 配件ID，对应DA ID
	SkinId  皮肤ID  可选，不填则是当前皮肤ID
]]
function BP_HallCharacter:RemoveAvatarByID(AvatarId,SkinId)
	if not AvatarId or AvatarId <= 0 then
		return
	end
	local AvatarComponent = self:GetAvatarComponent(SkinId)
	if not AvatarComponent then
		return
	end
	CWaring("BP_HallCharacter:RemoveAvatarByID:" .. AvatarId)
	AvatarComponent:RemoveAvatarByID(AvatarId)
end

function BP_HallCharacter:AttachAvatarByIDs(AvatarIds,SkinId)
	if not AvatarIds or #AvatarIds <= 0 then
		return
	end
	local AvatarComponent = self:GetAvatarComponent(SkinId)
	if not AvatarComponent then
		return
	end
	-- CWaring("BP_HallCharacter:AddAvatarByIDs:" .. AvatarId)
	print_r(AvatarIds,"AttachAvatarByIDs")
	AvatarComponent:AddAvatarByIDs(AvatarIds)
end

--[[
	重写父类方法
]]
function BP_HallCharacter:ShowSkinAvatar(SkinId)
	self.Super.ShowSkinAvatar(self, SkinId)
	--默认关闭描边
	self:SetSkeleMeshRenderStencilState(0)
	self:SetCameraFocusHeight()
	self:SetPostProcessSwitch(false)
end

function BP_HallCharacter:SetCameraFocusHeight()
	local SkeletalMesh = self:GetSkeleMesh()
	if SkeletalMesh then 
		---@type UE.FTransform
		local SpawnTransform = SkeletalMesh:GetSocketTransform(self:GetApparelAttachPoint(HallApparelMgr.HERO_SLOT_CAMERAFOCUS), UE.ERelativeTransformSpace.RTS_Component)
		---@type UE.FVector
		local Position = SpawnTransform.Translation
		self.CameraFocusHeight = Position.Z
	end
end

function BP_HallCharacter:SetPostProcessSwitch(Enable)
	self:SetDisablePostProcessBlueprint(not Enable)
	self:SetAnimInstanceContrilRigAlpha(Enable and 1 or 0)
end

--[[
	设置是否启用头发模拟
	0表示不启用
	1表示启用
]]
function BP_HallCharacter:SetAnimInstanceContrilRigAlpha(Alpha)
	local SkeletalMesh = self:GetSkeleMesh()
	if SkeletalMesh then 
		local TheAnimInstance = SkeletalMesh:GetAnimInstance()
		if TheAnimInstance then
			TheAnimInstance.ContrilRigAlpha = Alpha
		end	
	end
end

--[[
	根据AnimClip路径播放动画
	根据ABP，有不同的播放方案
	对于角色身上的ABP，需要通过赋值ABP属性才达到切换动画效果
]]
function BP_HallCharacter:PlayAnimClip(Path,IsLoop,SkinId)
	if not Path then
		CWaring("BP_HallCharacter:PlayAnimClip Path nil")
		return
	end
	print("BP_HallCharacter:PlayAnimClip", SkinId)
	local SkeletalMesh = self:GetSkeleMesh(SkinId)
	if SkeletalMesh then 
		local Animclip = LoadObject(Path)
		if Animclip then
			local TheAnimInstance = SkeletalMesh:GetAnimInstance()
			if TheAnimInstance  then
				CLog("BP_HallCharacter:PlayAnimClip Sequence:" .. Path)
				TheAnimInstance.Sequence = Animclip
			else
				CLog("BP_HallCharacter:PlayAnimClip SkeletalMesh:" .. Path)
				SkeletalMesh:PlayAnimation(Animclip,IsLoop)
			end
		else
			CWaring("BP_HallCharacter:PlayAnimClip Object not found:" .. Path)
		end
	else
		CWaring("BP_HallCharacter:PlayAnimClip SkeletalMesh nil")
	end
end

--- 设置动画之间是否相互融合
---@param IsBlend any
---@param SkinId any
function BP_HallCharacter:SetAvatarAnimBlend(SkinId, IsBlend)
	IsBlend = IsBlend or false
	print("BP_HallCharacter:SetAvatarAnimBlend", SkinId, IsBlend)
	local SkeletalMesh = self:GetSkeleMesh(SkinId)
	if SkeletalMesh then 
		local TheAnimInstance = SkeletalMesh:GetAnimInstance()
		if TheAnimInstance  then
			TheAnimInstance.IsBlend = IsBlend
		end
	else
		CWaring("BP_HallCharacter:SetAvatarAnimBlend SkeletalMesh nil")
	end
end

--[[
	开启或者关闭 动画蓝图模式
]]
function BP_HallCharacter:SetAnimClassCtrlActive(Value)
	local SkeletalMesh = self:GetSkeleMesh()
	if not SkeletalMesh then
		return
	end
	SkeletalMesh:SetAnimationMode((not Value) and UE.EAnimationMode.AnimationSingleNode or UE.EAnimationMode.AnimationBlueprint)
end

----【穿戴功能】-----

function BP_HallCharacter:InitApparelSlotTypeList()
	self.Super.InitApparelSlotTypeList(self)

	self.SlotTypeToAvatarList = 
	{
		[HallApparelMgr.HERO_SLOT_MAINWEAPON] = {},
		[HallApparelMgr.HERO_SLOT_SECWEAPON] = {}
	}
	self.SlotTypeToAttachPoint = 
	{		
		[HallApparelMgr.HERO_SLOT_MAINWEAPON] =	"Weapon_Socket" ,
		[HallApparelMgr.HERO_SLOT_SECWEAPON] = "",
		
		[HallApparelMgr.HERO_SLOT_HEADSHOW] = "root_head",
		[HallApparelMgr.HERO_SLOT_CAMERAFOCUS] = "facial_Root",
	}
end


function BP_HallCharacter:GetApparelAttachMesh(SkinId)
	local AvatarActor = self.Super.GetSkinActor(self, SkinId)
	if AvatarActor ~= nil then
		return AvatarActor:GetSkeletalMesh()
	end
	return nil
end

function BP_HallCharacter:GetSkeleMesh(SkinId)
	SkinId = SkinId or self.CurShowSkinId
	return self:GetApparelAttachMesh(SkinId)
end

-- 设置角色描边开关
function BP_HallCharacter:SetSkeleMeshRenderStencilState(StateValue)
	local SkeleMesh = self:GetSkeleMesh()
	if SkeleMesh then
		SkeleMesh:SetGameplayStencilState(StateValue)
	end
end

-- 动画蓝图是否准备成功
function BP_HallCharacter:IsCompHasBeenPrepared()
	return self._IsComponentPrepared
end

function BP_HallCharacter:SetCompHasBeenPrepared(InValue)
	if self._IsComponentPrepared == InValue then
		return
	end
	self._IsComponentPrepared = InValue
	local TActor = self:GetSkinActor()
	if InValue then
		TActor:SetActorScale3D(self.CacheSpawnParam.Scale)
	end
	MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_AVATAR_PREPARE_STATE_NOTIFY,{Actor = TActor, State = InValue})
	if InValue then
		self:SetPostProcessSwitch(true)
	end
end

function BP_HallCharacter:ReceiveTick(DeltaSeconds)
	self.Super.ReceiveTick(self,DeltaSeconds)

	if self:IsCompHasBeenPrepared() then
		return
	end
	local TActor = self:GetSkinActor()
	if not TActor then
		return
	end

	local Timeout = GetTimestamp() - self.OriginTimeStamp > BP_HallCharacter.CHECK_MAX_TIME
	if Timeout or TActor:IsComponentPrepared() then
		if Timeout then
			CError("BP_HallCharacter:IsAnimInstanceHasBeenUpdated out of time, must check!!")
		end
		print("BP_HallCharacter:IsAnimInstanceHasBeenUpdated :", self.CurShowSkinId)
		self:SetCompHasBeenPrepared(true)
	end
end
return BP_HallCharacter
