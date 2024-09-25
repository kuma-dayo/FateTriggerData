
local class_name = "HallAvatarMgr"
---@class HallAvatarMgr
HallAvatarMgr = HallAvatarMgr or BaseClass(nil, class_name)


HallAvatarMgr.AVATAR_HERO = "HERO"
HallAvatarMgr.AVATAR_WEAPON = "WEAPON"
HallAvatarMgr.AVATAR_ITEM = "ITEM"
HallAvatarMgr.AVATAR_VEHICLE = "VEHICLE"
HallAvatarMgr.AVATAR_DISPLAYBOARD = "AVATAR_DISPLAYBOARD"


function HallAvatarMgr:__init()	
    CLog("HallAvatarMgr:__init")
    self.HallAvatarList = {}
end

function HallAvatarMgr:__dispose()	
    CLog("HallAvatarMgr:__dispose")
    self:UnInit()
    self.model = nil
    self.HallSceneMgr = nil
end

function HallAvatarMgr:Init(HallSceneMgr)
    CLog("HallAvatarMgr:Init")
    self.HallSceneMgr = HallSceneMgr
    self.model = MvcEntry:GetModel(HallModel)
    
    self.HallAvatarList = 
    {
        -- 界面ID{}
    }
end


function HallAvatarMgr:UnInit()
    self:DestroyHallAvatarList()
end

function HallAvatarMgr:DestroyHallAvatarList()
    --大厅中创建的所有的Avatar
    for _, v in pairs(self.HallAvatarList) do 
        for _, _v in pairs(v) do 
            if CommonUtil.IsValid(v) then
                v:K2_DestroyActor()
            end
        end
    end
    self.HallAvatarList = {}
end

function HallAvatarMgr:GetHallAvatar(InstID, ViewID, AvatarID)
    if InstID == 0 then 
        ViewID = self:__InnerGetAvatarViewID(ViewID)
        if self.HallAvatarList[ViewID] == nil then 
            return 
        end
        return self.HallAvatarList[ViewID][AvatarID]        
    end
    return self.HallAvatarList[InstID]
end

function HallAvatarMgr:AddHallAvatar(InstID, ViewID, AvatarID, HallAvatar)
    if HallAvatar == nil then
        return 
    end
    if InstID == 0 then 
        ViewID = self:__InnerGetAvatarViewID(ViewID)
        if self.HallAvatarList[ViewID] == nil then 
            self.HallAvatarList[ViewID] = {}
        end
        if self.HallAvatarList[ViewID][AvatarID] ~= nil then 
            return
        end
        self.HallAvatarList[ViewID][AvatarID] = HallAvatar
    else 
        self.HallAvatarList[InstID] = HallAvatar
    end
end


function HallAvatarMgr:HideAvatarByViewID(ViewID)
    local ViewID = self:__InnerGetAvatarViewID(ViewID)

    if self.HallAvatarList[ViewID] == nil then
        return
    end
    if next(self.HallAvatarList[ViewID]) ~= nil then
        for _, v in pairs(self.HallAvatarList[ViewID]) do 
            if CommonUtil.IsValid(v) then
                --v:K2_DestroyActor()
                v:Show(false, _)
            end
        end
        --self.HallAvatarList[ViewID] = {}
    end
end

function HallAvatarMgr:HideAvatarByAvatarID(ViewID, AvatarID)
    if ViewID == nil or AvatarID == nil then
        return
    end
    
    local ViewID = self:__InnerGetAvatarViewID(ViewID)
    if self.HallAvatarList[ViewID] == nil then
        return
    end
    local HallAvatar = self.HallAvatarList[ViewID][AvatarID]
    if CommonUtil.IsValid(HallAvatar) then
        --HallAvatar:K2_DestroyActor()
        HallAvatar:Show(false, _)
    end
    --self.HallAvatarList[ViewID][AvatarID] = nil
end


function HallAvatarMgr:RemoveAvatarByInstID(InstID)
    local v = self.HallAvatarList[InstID]
    if CommonUtil.IsValid(v) then
        v:K2_DestroyActor()
    end
    self.HallAvatarList[InstID] = nil
end



--生成模型
function HallAvatarMgr:ShowAvatar(AvatorType, SpawnParam)
    local Avatar = nil
    if not SpawnParam.Scale then
        SpawnParam.Scale = UE.FVector(1,1,1)
    end
    if not SpawnParam.Location then
        SpawnParam.Location = UE.FVector(0,0,0)
    end
    if not SpawnParam.Rotation then
        SpawnParam.Rotation = UE.FRotator(0, 0, 0)
    end
    if AvatorType == HallAvatarMgr.AVATAR_HERO then 
        Avatar = self:__SpawnHero(SpawnParam)
    elseif AvatorType == HallAvatarMgr.AVATAR_WEAPON then 
        Avatar = self:__SpawnWeapon(SpawnParam)
    elseif AvatorType == HallAvatarMgr.AVATAR_ITEM then 
        Avatar = self:__SpawnItem(SpawnParam)
    elseif AvatorType == HallAvatarMgr.AVATAR_VEHICLE then
        Avatar = self:__SpawnVehicle(SpawnParam)
    elseif AvatorType == HallAvatarMgr.AVATAR_DISPLAYBOARD then
        Avatar = self:__SpawnDisplayBoard(SpawnParam)
    end

    if Avatar ~= nil then 
        if AvatorType == HallAvatarMgr.AVATAR_DISPLAYBOARD then
            Avatar:Show(true,SpawnParam)
        else
            Avatar:SetSpawnParam(SpawnParam)
            Avatar:SpawnSkinAvatar(SpawnParam.SkinID, SpawnParam.ForbidUseRelativeTransform or false)
            Avatar:Show(true, SpawnParam.SkinID)
        end
    end
    return Avatar
end

function HallAvatarMgr:HideAvatar(InstID, ViewID, AvatarID)
    local Avatar = self:GetHallAvatar(InstID, ViewID, AvatarID)
    if Avatar ~= nil then 
        Avatar:Show(false)
        return Avatar
    end
end


function HallAvatarMgr:ShowAvatarByViewID(ViewID, IsShow, SkinId)
    local ViewID = self:__InnerGetAvatarViewID(ViewID)

    if self.HallAvatarList[ViewID] == nil then
        return
    end
    if next(self.HallAvatarList[ViewID]) ~= nil then
        for _, Avatar in pairs(self.HallAvatarList[ViewID]) do
            if CommonUtil.IsValid(Avatar) then
                Avatar:Show(IsShow,SkinId)
            end
        end
    end
end


function HallAvatarMgr:__InnerGetAvatarViewID(ViewID)
    if not ViewID then
        return "AvatarMgr_ViewIdIsNil"
    end
    return "AvatarMgr_"..ViewID
end

function HallAvatarMgr:__SpawnHero(SpawnHeroParam)
    if SpawnHeroParam == nil then 
        return 
    end
    if self.HallSceneMgr == nil then
        return
    end
    local CurWorld = self.HallSceneMgr:GetWorld() 
    if CurWorld == nil then
        return 
    end

    local ViewID = SpawnHeroParam.ViewID
    local InstID = SpawnHeroParam.InstID
    local HeroId = SpawnHeroParam.HeroId
    
    local HeroAvatar = self:GetHallAvatar(InstID, ViewID, HeroId)
    if HeroAvatar ~= nil then
        CLog("Get Cached Hero Avatar: InstID = "..InstID.." ViewID = "..ViewID.." HeroId ="..HeroId)
        local SpawnTrans = UE.UKismetMathLibrary.MakeTransform(SpawnHeroParam.Location, 
            SpawnHeroParam.Rotation, SpawnHeroParam.Scale)
        -- HeroAvatar:K2_SetActorTransform(SpawnTrans,false, UE.FHitResult(), false)
        HeroAvatar:SetTransformInLua(SpawnTrans)
        return HeroAvatar
    end

    local CharacterClass = UE.UClass.Load("/Game/BluePrints/Hall/BP_HallCharacter.BP_HallCharacter")
    if CharacterClass ~= nil then
        local SpawnTrans = UE.UKismetMathLibrary.MakeTransform(SpawnHeroParam.Location, 
            SpawnHeroParam.Rotation, SpawnHeroParam.Scale)

        HeroAvatar = UE.UGameplayStatics.BeginDeferredActorSpawnFromClass(CurWorld,
        CharacterClass, 
        SpawnTrans, 
        UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
        
        if HeroAvatar then
            UE.UGameplayStatics.FinishSpawningActor(HeroAvatar,SpawnTrans)
        end
    end
    if HeroAvatar ~= nil then 
        self:AddHallAvatar(InstID, ViewID, HeroId, HeroAvatar)
    end
    return HeroAvatar
end


function HallAvatarMgr:__SpawnWeapon(SpawnWeaponParam)
    if SpawnWeaponParam == nil then 
        return 
    end
    if self.HallSceneMgr == nil then
        return
    end
    local CurWorld = self.HallSceneMgr:GetWorld() 
    if CurWorld == nil then
        return 
    end

    local ViewID = SpawnWeaponParam.ViewID
    local InstID = SpawnWeaponParam.InstID
    local WeaponID = SpawnWeaponParam.WeaponID

    local WeaponAvatar = self:GetHallAvatar(InstID, ViewID, WeaponID)
    if WeaponAvatar ~= nil then
        CLog("Get Cached Weapon Avatar: InstID = "..InstID.." ViewID = "..ViewID.." WeaponID ="..WeaponID)
        local SpawnTrans = UE.UKismetMathLibrary.MakeTransform(SpawnWeaponParam.Location, SpawnWeaponParam.Rotation, SpawnWeaponParam.Scale)
        -- WeaponAvatar:K2_SetActorTransform(SpawnTrans,false, UE.FHitResult(), false)
        WeaponAvatar:SetTransformInLua(SpawnTrans)
        return WeaponAvatar
    end

    local WeaponAvatarClass = UE.UClass.Load("/Game/BluePrints/Hall/BP_HallWeapon.BP_HallWeapon")
    if WeaponAvatarClass ~= nil then
        local SpawnTrans = UE.UKismetMathLibrary.MakeTransform(SpawnWeaponParam.Location, SpawnWeaponParam.Rotation, SpawnWeaponParam.Scale)

        --旧写法，无法生效Scale属性
        -- WeaponAvatar = CurWorld:SpawnActor(WeaponAvatarClass, 
        --     SpawnTrans, 
        --     UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
        --新写法 Deferred Spawning，并且方向在对象进入世界之前进行一些额外设置
        WeaponAvatar = UE.UGameplayStatics.BeginDeferredActorSpawnFromClass(CurWorld,
        WeaponAvatarClass, 
        SpawnTrans, 
        UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
        
        if WeaponAvatar then
            UE.UGameplayStatics.FinishSpawningActor(WeaponAvatar,SpawnTrans)
        end
    end
    if WeaponAvatar ~= nil then 
        self:AddHallAvatar(InstID, ViewID, WeaponID, WeaponAvatar)
    end
    return WeaponAvatar
end


function HallAvatarMgr:__SpawnVehicle(SpawnVehicleParam)
    if SpawnVehicleParam == nil then 
        return 
    end
    if self.HallSceneMgr == nil then
        return
    end
    local CurWorld = self.HallSceneMgr:GetWorld() 
    if CurWorld == nil then
        return 
    end

    local ViewID = SpawnVehicleParam.ViewID
    local InstID = SpawnVehicleParam.InstID
    local VehicleID = SpawnVehicleParam.VehicleID

    local VehicleAvatar = self:GetHallAvatar(InstID, ViewID, VehicleID)
    if VehicleAvatar ~= nil then
        CLog("Get Cached Vehicle Avatar: InstID = "..InstID.." ViewID = "..ViewID.." VehicleID ="..VehicleID)
        return VehicleAvatar
    end

    local VehicleAvatarClass = UE.UClass.Load("/Game/BluePrints/Hall/BP_HallVehicle.BP_HallVehicle")
    if VehicleAvatarClass ~= nil then
        local SpawnTrans = UE.UKismetMathLibrary.MakeTransform(SpawnVehicleParam.Location, 
        SpawnVehicleParam.Rotation, SpawnVehicleParam.Scale)

        VehicleAvatar = UE.UGameplayStatics.BeginDeferredActorSpawnFromClass(CurWorld,
            VehicleAvatarClass, 
            SpawnTrans, 
            UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
        VehicleAvatar.OpenCheckCameraSpringArm = SpawnVehicleParam.OpenCheckCameraSpringArm or false
        
        if VehicleAvatar then
            UE.UGameplayStatics.FinishSpawningActor(VehicleAvatar,SpawnTrans)
        end
    end
    if VehicleAvatar ~= nil then 
        self:AddHallAvatar(InstID, ViewID, VehicleID, VehicleAvatar)
    end
    return VehicleAvatar
end



function HallAvatarMgr:__SpawnDisplayBoard(SpawnDisplayBoardParam)
    if SpawnDisplayBoardParam == nil then 
        return 
    end
    if self.HallSceneMgr == nil then
        return
    end
    local CurWorld = self.HallSceneMgr:GetWorld() 
    if CurWorld == nil then
        return 
    end

    local ViewID = SpawnDisplayBoardParam.ViewID
    local InstID = SpawnDisplayBoardParam.InstID
    local DisplayBoardID = SpawnDisplayBoardParam.DisplayBoardID

    local DisplayBoardAvatar = self:GetHallAvatar(InstID, ViewID, DisplayBoardID)
    if DisplayBoardAvatar ~= nil then
        CLog("Get Cached Vehicle Avatar: InstID = "..InstID.." ViewID = "..ViewID.." DisplayBoardID ="..DisplayBoardID)
        local SpawnTrans = UE.UKismetMathLibrary.MakeTransform(SpawnDisplayBoardParam.Location, 
            SpawnDisplayBoardParam.Rotation, SpawnDisplayBoardParam.Scale)
        -- HeroAvatar:K2_SetActorTransform(SpawnTrans,false, UE.FHitResult(), false)
        DisplayBoardAvatar:SetTransformInLua(SpawnTrans)
        return DisplayBoardAvatar
    end

    --UE.UClass.Load("/Game/BluePrints/Hall/Hero/Hero03/BP_Hall_Hero_TestWidget.BP_Hall_Hero_TestWidget")
    --UE.UClass.Load("/Game/BluePrints/Hall/BP_HeroDisplayBoard.BP_HeroDisplayBoard")
    local DisplayBoardAvatarClass = UE.UClass.Load("/Game/BluePrints/Hall/BP_HeroDisplayBoard.BP_HeroDisplayBoard")
    if DisplayBoardAvatarClass ~= nil then
        local SpawnTrans = UE.UKismetMathLibrary.MakeTransform(SpawnDisplayBoardParam.Location, 
            SpawnDisplayBoardParam.Rotation, SpawnDisplayBoardParam.Scale)

        DisplayBoardAvatar = UE.UGameplayStatics.BeginDeferredActorSpawnFromClass(CurWorld,
        DisplayBoardAvatarClass, 
        SpawnTrans, 
        UE.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
        
        if DisplayBoardAvatar then
            UE.UGameplayStatics.FinishSpawningActor(DisplayBoardAvatar,SpawnTrans)
        end
    end
    if DisplayBoardAvatar ~= nil then 
        self:AddHallAvatar(InstID, ViewID, DisplayBoardID, DisplayBoardAvatar)
    end
    return DisplayBoardAvatar
end



function HallAvatarMgr:__SpawnItem(SpawnItemParam)
    if SpawnItemParam == nil then 
        return 
    end
    if SpawnItemParam == nil then 
        return
    end
    local ViewID = SpawnItemParam.ViewID
    local InstID = SpawnItemParam.InstID
end
