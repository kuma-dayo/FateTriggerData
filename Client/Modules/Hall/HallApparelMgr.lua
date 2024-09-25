
local class_name = "HallApparelMgr"
HallApparelMgr = HallApparelMgr or BaseClass(nil, class_name)

--- 【角色穿戴插槽】---
HallApparelMgr.HERO_SLOT_MAINWEAPON = 1
HallApparelMgr.HERO_SLOT_SECWEAPON = 2
HallApparelMgr.HERO_SLOT_HEADSHOW = 3
HallApparelMgr.HERO_SLOT_CAMERAFOCUS = 4

--- 【武器穿戴插槽】--- 
HallApparelMgr.WEAPON_SLOT_MASTER = 1


HallApparelMgr.HEADSHOW_BP_PATH = "/Game/BluePrints/Hall/Hero/HeadShow/BP_Hall_Hero_HeadShow.BP_Hall_Hero_HeadShow"

function HallApparelMgr:__init()
    CLog("HallApparelMgr:__init")
end

function HallApparelMgr:__dispose()	
    CLog("HallApparelMgr:__dispose")
    self:UnInit()
    self.model = nil
    self.HallSceneMgr = nil
end

function HallApparelMgr:Init(HallSceneMgr)
    CLog("HallApparelMgr:Init")
    self.HallSceneMgr = HallSceneMgr
    self.model = MvcEntry:GetModel(HallModel)
    --资源引用Cache
    self.RefCache = {}
	self:AddListeners()
end

function HallApparelMgr:UnInit()
	self:RemoveListeners()
    
    --清空资源引用Cache
    for _, RefTable in pairs(self.RefCache) do
        RefTable.Ref = nil
    end
    self.RefCache = {}
end

function HallApparelMgr:AddListeners()
	if self.model == nil then 
		return
	end
    self.model:AddListener(HallModel.ON_HERO_PUTON_WEAPON, self.OnHeroPutOnWeapon, self)
    self.model:AddListener(HallModel.ON_HERO_TAKEOFF_WEAPON, self.OnHeroTakeOffWeapon, self)
    self.model:AddListener(HallModel.ON_HERO_ADD_HEADSHOW, self.OnHeroAddHeadShow, self)
    self.model:AddListener(HallModel.ON_HERO_REMOVE_HEADSHOW, self.OnHeroRemoveHeadShow, self)
end


function HallApparelMgr:RemoveListeners()
	if self.model == nil then 
		return
	end
    self.model:RemoveListener(HallModel.ON_HERO_PUTON_WEAPON, self.OnHeroPutOnWeapon, self)
    self.model:RemoveListener(HallModel.ON_HERO_TAKEOFF_WEAPON, self.OnHeroTakeOffWeapon, self)
    self.model:RemoveListener(HallModel.ON_HERO_ADD_HEADSHOW, self.OnHeroAddHeadShow, self)
    self.model:RemoveListener(HallModel.ON_HERO_REMOVE_HEADSHOW, self.OnHeroRemoveHeadShow, self)
end

function HallApparelMgr:SpawnWeapon(SkinId)
    local WeaponSkinCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_WeaponSkinConfig,
    Cfg_WeaponSkinConfig_P.SkinId, SkinId)
    if WeaponSkinCfg == nil then 
        return 
    end
    local ClassBp = WeaponSkinCfg[Cfg_WeaponSkinConfig_P.SystemBP]
    local AvatorClass = UE.UClass.Load(CommonUtil.FixBlueprintPathWithoutPre(ClassBp))
	if AvatorClass == nil then 
		return 
	end

    --增加皮肤资源引用Cache
    local RefProxy = UnLua.Ref(AvatorClass)
    local RefTable = {
        Ref = RefProxy
    }
    table.insert(self.RefCache, RefTable)

	local CurWorld = self.HallSceneMgr:GetWorld() 
    if CurWorld == nil then
        return 
    end

	return CurWorld:SpawnActor(AvatorClass, 
		UE.FTransform.Identity, 
		UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
end

--[[
    Param
    {
        --需要进行穿戴的角色实例ID
        HeroInstID = TeamMemPlayerId, 
        --需要装备的武器皮肤ID
        WeaponSkinID = 300010001,
        --是否开启内部动画切换（根据是否持枪切换IdleLoop动作）
        AnimControl = true,
    }
]]
function HallApparelMgr:OnHeroPutOnWeapon(PutOnParam)
    print("HallApparelMgr:OnHeroPutOnWeapon")
    if PutOnParam == nil then 
        return
    end
    if self.HallSceneMgr == nil then 
        return 
    end
    local AvatarMgr = self.HallSceneMgr.AvatarMgr
    if AvatarMgr == nil then 
        return 
    end
    local HallHero = AvatarMgr:GetHallAvatar(PutOnParam.HeroInstID)
    if HallHero == nil then 
        return 
    end
    print("HallApparelMgr:OnHeroPutOnWeapon", PutOnParam.HeroInstID, PutOnParam.WeaponSkinID)
    local SkinId = PutOnParam.WeaponSkinID
    local SlotAvatarInfo = HallHero:GetSlotAvatarInfo(HallApparelMgr.HERO_SLOT_MAINWEAPON)
    local AvatarActor = SlotAvatarInfo and SlotAvatarInfo.AvatarActor
    if not AvatarActor then
        local WeaponAvatar = self:SpawnWeapon(SkinId)
        if WeaponAvatar == nil then
            return
        end

        HallHero:PutOnAvatar(HallApparelMgr.HERO_SLOT_MAINWEAPON, SkinId, WeaponAvatar)
        AvatarActor = WeaponAvatar
    end


    local AvatarComponent = AvatarActor.BP_HallWeaponAvatarComponent
    if AvatarComponent then
        -- --进行枪的avatar组装 
        MvcEntry:GetModel(WeaponModel):CreateDefaultAvatarsBySkinId(AvatarComponent,SkinId)
    end

    if PutOnParam.AnimControl then
        --角色持枪时，需要根据持枪类型，来决定当前需要播放的IdleLoop动作
        local HeroSkinId = HallHero:GetCurShowSkinId()
        local WeaponSkinId = PutOnParam.WeaponSkinID
        local WeaponMappingCfg = MvcEntry:GetModel(WeaponModel):GetWeaponAnimMappingCfg(WeaponSkinId,HeroSkinId)
        if WeaponMappingCfg then
            local AnimClipPath = WeaponMappingCfg[Cfg_WeaponAnimMappingCfg_P.AnimClipIdle]
            HallHero:PlayAnimClip(AnimClipPath)
        else
            CError("HallApparelMgr:OnHeroPutOnWeapon WeaponMappingCfg not found!")
        end
    end

    local HallAvatarComponent = AvatarActor.BP_HallAvatarComponent
    if HallAvatarComponent then
		HallAvatarComponent:SetForceLOD(1)
	end

    if PutOnParam.PlayDissolveLS then
        local LSPath = MvcEntry:GetModel(HallModel):GetLSPathById(HallModel.LSTypeIdEnum.LS_WEAPON_DISSOLVE)
        if not LSPath then
            return
        end
        local SetBindings = {{
            Actor = AvatarActor, 
            TargetTag = SequenceModel.BindTagEnum.WEAPON_SKELETMESH_COMPONENT,
        }}
        local PlayParam = {
            LevelSequenceAsset = LSPath,
            SetBindings = SetBindings,
        }
        MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("WeaponDissolve", function()
        end, PlayParam)
    end
end

--[[
    Param
    {
        --需要进行穿戴的角色实例ID
        HeroInstID = TeamMemPlayerId, 
        --需要装备的武器皮肤ID
        WeaponSkinID = 300010001,
        --是否开启内部动画切换（根据是否持枪切换IdleLoop动作）
        AnimControl = true,
    }
]]
function HallApparelMgr:OnHeroTakeOffWeapon(TakeOffParam)
    print("HallApparelMgr:OnHeroTakeOffWeapon")
    if TakeOffParam == nil then 
        return 
    end
    local AvatarMgr = self.HallSceneMgr.AvatarMgr
    if AvatarMgr == nil then 
        return 
    end
    local HallHero = AvatarMgr:GetHallAvatar(TakeOffParam.HeroInstID)
    if HallHero == nil then 
        return 
    end
    print("HallApparelMgr:OnHeroTakeOffWeapon", TakeOffParam.HeroInstID)
    HallHero:TakeOffAvatar(HallApparelMgr.HERO_SLOT_MAINWEAPON)
    
    if TakeOffParam.AnimControl then
        --角色非持枪时，需要切回非持枪的Idle动作
        local SkinID = HallHero.CurShowSkinId
        HallHero:PlayAnimClip(MvcEntry:GetModel(HeroModel):GetAnimClipPathBySkinIdAndKey(SkinID,HeroModel.LSEventTypeEnum.IdleDefault))
    end
end



function HallApparelMgr:OnHeroAddHeadShow(InParam)
    print("HallApparelMgr:OnHeroAddHeadShow")
    if InParam == nil then 
        return
    end
    if self.HallSceneMgr == nil then 
        return 
    end
    local AvatarMgr = self.HallSceneMgr.AvatarMgr
    if AvatarMgr == nil then 
        return 
    end
    local HallHero = AvatarMgr:GetHallAvatar(InParam.HeroInstID)
    if HallHero == nil then 
        return 
    end
    local CurWorld = self.HallSceneMgr:GetWorld() 
    if CurWorld == nil then
        return 
    end

    print("HallApparelMgr:OnHeroAddHeadShow", InParam.HeroInstID)
    local SlotAvatarInfo = HallHero:GetSlotAvatarInfo(HallApparelMgr.HERO_SLOT_HEADSHOW)
    local AvatarActor = SlotAvatarInfo and SlotAvatarInfo.AvatarActor
    if not AvatarActor then
        local HeadShowClass = UE.UClass.Load(HallApparelMgr.HEADSHOW_BP_PATH)
        if HeadShowClass == nil then
            return
        end
        local RefProxy = UnLua.Ref(HeadShowClass)
        local RefTable = {
            Ref = RefProxy
        }
        table.insert(self.RefCache, RefTable)
        local HeroSkinId = HallHero:GetCurShowSkinId()
        local SpawnLocation = MvcEntry:GetModel(HeroModel):GetHeroTeamMarkLocation(HeroSkinId)
        local SpawnRotation = UE.FRotator(0, 0, 0)
        local SpawnScale = UE.FVector(1, 1, 1)
        local SpawnTrans = UE.UKismetMathLibrary.MakeTransform(SpawnLocation, SpawnRotation, SpawnScale)
        
        local WeaponAvatar = CurWorld:SpawnActor(HeadShowClass, 
            SpawnTrans, 
            UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
        if WeaponAvatar == nil then
            return
        end
        HallHero:PutOnAvatar(HallApparelMgr.HERO_SLOT_HEADSHOW, InParam.HeroInstID, WeaponAvatar)
        WeaponAvatar:InitData(
            {
                PlayerId = InParam.HeroInstID,
                NotNeedPlayInAni = InParam.NotNeedPlayInAni
            }
        )
    end

    local SlotAvatarInfo = HallHero:GetSlotAvatarInfo(HallApparelMgr.HERO_SLOT_HEADSHOW)
    if SlotAvatarInfo and SlotAvatarInfo.AvatarActor and not InParam.NotNeedPlayInAni then
        Timer.InsertTimer(0.2,function()
            if AvatarMgr == nil then 
                return 
            end
            local HallHero = AvatarMgr:GetHallAvatar(InParam.HeroInstID)
            if HallHero == nil then 
                return 
            end
            local SlotAvatarInfo = HallHero:GetSlotAvatarInfo(HallApparelMgr.HERO_SLOT_HEADSHOW)
            if SlotAvatarInfo and SlotAvatarInfo.AvatarActor then
                SlotAvatarInfo.AvatarActor:TriggerInOutChange(true)
            end
        end)
    end
end

function HallApparelMgr:OnHeroRemoveHeadShow(InParam)
    print("HallApparelMgr:OnHeroRemoveHeadShow")
    if InParam == nil then 
        return 
    end
    if self.HallSceneMgr == nil then 
        return 
    end
    local AvatarMgr = self.HallSceneMgr.AvatarMgr
    if AvatarMgr == nil then 
        return 
    end
    local HallHero = AvatarMgr:GetHallAvatar(InParam.HeroInstID)
    if HallHero == nil then 
        return 
    end
    print("HallApparelMgr:OnHeroAddHeadShow", InParam.HeroInstID)
    local SlotAvatarInfo = HallHero:GetSlotAvatarInfo(HallApparelMgr.HERO_SLOT_HEADSHOW)
    if SlotAvatarInfo and SlotAvatarInfo.AvatarActor then
        SlotAvatarInfo.AvatarActor:PreDestroyed()
    end
    if SlotAvatarInfo and SlotAvatarInfo.AvatarActor and not InParam.NotNeedPlayInAni then
        Timer.InsertTimer(0.2,function()
            if AvatarMgr == nil then 
                return 
            end
            local HallHero = AvatarMgr:GetHallAvatar(InParam.HeroInstID)
            if HallHero == nil then 
                return 
            end
            HallHero:TakeOffAvatar(HallApparelMgr.HERO_SLOT_HEADSHOW)
        end)
    else
        HallHero:TakeOffAvatar(HallApparelMgr.HERO_SLOT_HEADSHOW)
    end
end

return HallApparelMgr