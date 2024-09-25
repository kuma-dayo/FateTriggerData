--[[
    大厅SequenceActor的代理Lua类
]]
local BP_HallLSActor = Class()

function BP_HallLSActor:ReceiveBeginPlay()
	CLog("BP_HallLSActor: BeginPlay")
	self.Overridden.ReceiveBeginPlay(self)

    self.CustomLSName2Func = {
        ["TeamCAnimPlay"] = self.OnTeamCAnimPlayFunc,
        ["TeamCAnimPlayExit"] = self.TeamCAnimPlayExit,
        ["FavorSpawnGift"] = self.OnFavorSpawnGift,
        ["FavorDestroyGift"] = self.OnFavorDestroyGift,
        ["SpeCialPopLineEvent"] = self.OnSpeCialPopLineEvent,
    }
end

--[[
    重写蓝图LS事件回调
]]
function BP_HallLSActor:OnLSEventCall(EventName,Param1,Param2)
    CWaring("BP_HallLSActor:OnLSEventCall:" .. EventName)

    if not self.CustomLSName2Func[EventName] then
        CError("BP_HallLSActor:OnLSEventCall not found Event callback:" .. EventName)
        return
    end
    self.CustomLSName2Func[EventName](self,EventName,Param1,Param2)
end

function BP_HallLSActor:ReceiveEndPlay(EndPlayReason)
    self.Overridden.ReceiveEndPlay(self,EndPlayReason)	
	CLog("BP_HallLSActor: ReceiveEndPlay")
    if self.LSId > 0 then
        MvcEntry:GetCtrl(SequenceCtrl):CleanSequenceActorByLSId(self.LSId)
    else
        CWaring("BP_HallLSActor LSId <=0  please check!!!!")
    end
end

function BP_HallLSActor:OnSpeCialPopLineEvent()
    MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_SPECIAL_POP_LINE_EVENT)
end


--[[
    播放玩家进队时，主C位置的LS
]]
function BP_HallLSActor:OnTeamCAnimPlayFunc(EventName,Param1,Param2)
    self:HandleTeamCAnimPlay(EventName, false)
end

--[[
    播放玩家出队时，主C位置的LS
]]
function BP_HallLSActor:TeamCAnimPlayExit(EventName,Param1,Param2)
    self:HandleTeamCAnimPlay(EventName, true)
end

function BP_HallLSActor:HandleTeamCAnimPlay(EventName, IsExit)
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if not HallAvatarMgr then
        CWaring("BP_HallLSActor:OnTeamCAnimPlayFunc HallAvatarMgr nil")
        return
    end
    local HallActor = HallAvatarMgr:GetHallAvatar(MvcEntry:GetModel(UserModel).PlayerId, ViewConst.Hall, MvcEntry:GetModel(HeroModel):GetFavoriteId())
    if not HallActor then
        CWaring("BP_HallLSActor:OnTeamCAnimPlayFunc HallActor nil")
        return
    end
    local TheFSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteHeroFavoriteSkinId()
    local HallActorAvatar = HallActor:GetSkinActor()

    local SetBindings = {
        {
            ActorTag = "",
            Actor = HallActorAvatar,
            TargetTag = SequenceModel.BindTagEnum.ACTOR_SKELETMESH_ANIM,
        }
    }

    local WeaponBinding
    local SlotAvatarInfo = HallActor:GetSlotAvatarInfo(HallApparelMgr.HERO_SLOT_MAINWEAPON)
    local WeaponAvatar = SlotAvatarInfo and SlotAvatarInfo.AvatarActor
    if WeaponAvatar then
        WeaponBinding = {
			Actor = WeaponAvatar, 
			TargetTag = SequenceModel.BindTagEnum.WEAPON_SKELETMESH_COMPONENT,
		}
		table.insert(SetBindings,WeaponBinding)
    end

    --角色持枪时，需要根据持枪类型，来决定当前需要播放的LS
    local HeroSkinId = HallActor:GetCurShowSkinId()
    local WeaponSkinId = SlotAvatarInfo.AvatarID
    local WeaponMappingCfg = MvcEntry:GetModel(WeaponModel):GetWeaponAnimMappingCfg(WeaponSkinId,HeroSkinId)
    if WeaponMappingCfg then
        local LSPath
        if IsExit then
            HallActor:PlayAnimClip(MvcEntry:GetModel(HeroModel):GetAnimClipPathBySkinIdAndKey(HeroSkinId,HeroModel.LSEventTypeEnum.IdleDefault))
            LSPath = WeaponMappingCfg[Cfg_WeaponAnimMappingCfg_P.LSPathExitTeam]
        else
            HallActor:PlayAnimClip(WeaponMappingCfg[Cfg_WeaponAnimMappingCfg_P.AnimClipIdle])
            LSPath = WeaponMappingCfg[Cfg_WeaponAnimMappingCfg_P.LSPathEnterTeam]
        end
        local IsEnablePostProcess = WeaponMappingCfg[Cfg_WeaponAnimMappingCfg_P.IsEnablePostProcess]
        local PlayParam = {
            LevelSequenceAsset = LSPath,
            SetBindings = SetBindings,
            IsEnablePostProcess = IsEnablePostProcess
        }
        MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag(EventName, function ()
        end, PlayParam)
    else
        CError("BP_HallLSActor:TeamCAnimPlayExit WeaponMappingCfg not found!")
    end

    self:HandleDissolve(IsExit,WeaponBinding)
end


--[[
    播放溶解特效
]]
function BP_HallLSActor:HandleDissolve(IsOut, SetBindings)
    if not SetBindings then
        return
    end
    local LSPath = MvcEntry:GetModel(HallModel):GetLSPathById(IsOut and HallModel.LSTypeIdEnum.LS_WEAPON_DISSOLVE_OUT or HallModel.LSTypeIdEnum.LS_WEAPON_DISSOLVE)
    if not LSPath then
        return
    end
    local PlayParam = {
        LevelSequenceAsset = LSPath,
        SetBindings = {SetBindings},
    }
    MvcEntry:GetCtrl(SequenceCtrl):PlaySequenceByTag("WeaponDissolve", function()
        if IsOut then
            MvcEntry:GetModel(HallModel):DispatchType(HallModel.ON_HERO_TAKEOFF_WEAPON, {HeroInstID = MvcEntry:GetModel(UserModel).PlayerId})
        end
    end, PlayParam)
end

function BP_HallLSActor:OnFavorSpawnGift()
    MvcEntry:GetModel(FavorabilityModel):DispatchType(FavorabilityModel.SPAWN_GIFT_BOX)
end

function BP_HallLSActor:OnFavorDestroyGift()
    MvcEntry:GetModel(FavorabilityModel):DispatchType(FavorabilityModel.DESTROY_GIFT_BOX)
end

return BP_HallLSActor