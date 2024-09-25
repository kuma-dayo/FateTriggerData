--
-- 战斗HUD - 受击信息
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.21
--

local HurtInfo = Class("Common.Framework.UserWidget")

-------------------------------------------- Init/Destroy ------------------------------------

function HurtInfo:OnInit()
    print("HurtInfo >> OnInit, ...", GetObjectName(self))

    self.bCanTick = false
    self.CurWidgetNum = 0
    self.CurAutoFreeTime = 0
    self.ForwardVec2D = UE.FVector2D(1, 0)
    
    self.DirWidgetInfos = { }
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	assert(self.LocalPC, "HurtInfo >> LocalPC is invalid!!!")

	self.MsgList = {
		{ MsgName = GameDefine.NTag.WEAPON_HitActorForUI,	Func = self.OnWeaponHitActor, bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState,	Func = self.OnUpdateLocalPCPS,      bCppMsg = true,	WatchedObject = nil },
	}

    local LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
    if LocalPS then
        print("HurtInfo >> OnInit, RegisterList MsgList_PS")
        MsgHelper:UnregisterList(self, self.MsgList_PS or {})
        self.MsgList_PS = {
            { MsgName = GameDefine.MsgCpp.UISync_UpdateOnDead,       Func = self.UpdateDeadInfo,         bCppMsg = true,WatchedObject =LocalPS },
        }
        MsgHelper:RegisterList(self, self.MsgList_PS)
    end

    self.AdvBussiness = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(self)
    if self.AdvBussiness then
        local MarkSettingName = UE.UBlueprintGameplayTagLibrary.GetTagName(self.AdvBussiness.MarkMaterialActorSetting)
        if MarkSettingName then
           table.insert(self.MsgList, { MsgName = MarkSettingName,	Func = self.OnHurtSettingUpdate, bCppMsg = true })
        end
    end

    self:InitDirWidgetInfosPool()

    UserWidget.OnInit(self)
end

function HurtInfo:InitDirWidgetInfosPool()
    if not self.Root then
        return
    end
    local MiscSystem = UE.UMiscSystem.GetMiscSystem(self)
    if not MiscSystem then
       return 
    end
    local TargetClass = MiscSystem.HurtInfoItemClass
    local NewAnchors = UE.FAnchors()
    for index = 1, math.ceil(self.MaxUnusedWidgetNum/4) do
        local NewWidgetObject = UE.UGUIUserWidget.Create(self.LocalPC, TargetClass, self.LocalPC)
        if NewWidgetObject then
            self.Root:AddChild(NewWidgetObject)
            NewWidgetObject:SetVisibility(UE.ESlateVisibility.Collapsed)
            NewWidgetObject.Slot:SetAutoSize(true)
            NewWidgetObject.Slot:SetZOrder(1)
    
            NewAnchors.Minimum = UE.FVector2D(0.5)
            NewAnchors.Maximum = NewAnchors.Minimum
            NewWidgetObject.Slot:SetAnchors(NewAnchors)
            NewWidgetObject.Slot:SetAlignment(UE.FVector2D(0.5))
    
            local TempHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.UpdateHurtInfo}, self.UpdateTime, true, 0, 0)
            local DirWidgetInfo = {
                Widget = NewWidgetObject,
                CurTime = 0,
                WeaponInstId = nil,
                BulletHitUIData = nil,
                TimerHandle = TempHandle
            }
            table.insert(self.DirWidgetInfos, DirWidgetInfo)
        end
    end
end

function HurtInfo:OnHurtSettingUpdate()
    for _, DirWidgetInfo in pairs(self.DirWidgetInfos) do
        if DirWidgetInfo and DirWidgetInfo.Widget and DirWidgetInfo.Widget:IsVisible() then
            if true and (DirWidgetInfo.CurTime > self.ShowHitEffectTime) then
                DirWidgetInfo.Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
            else
                self.bCanTick = true
                if self:GetIfHurt2DOpen() then
                    DirWidgetInfo.Widget:SetVisibility(UE.ESlateVisibility.Visible)
                else
                    DirWidgetInfo.Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
                end
            end
        end
    end
end

-- 0是开启2D 1是仅开启3D, 不等于1就代表开启了2D
function HurtInfo:GetIfHurt2DOpen()
    if not self.AdvBussiness then UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(self) end
    local SettSystem = UE.UGenericSettingSubsystem.Get(self)
    if SettSystem then
        if not self.AdvBussiness then return false end
        if self.AdvBussiness.MarkMaterialActorSetting == nil then return false end
        local Result = SettSystem:GetSettingValue_int32(self.AdvBussiness.MarkMaterialActorSetting)
        if Result == nil then return false end
        return 1 ~= Result
    end
end



function HurtInfo:OnDestroy()
    print("HurtInfo >> OnDestroy, ...", GetObjectName(self))

	UserWidget.OnDestroy(self)
end

function HurtInfo:OnUpdateLocalPCPS(InLocalPC, InOldPS, InNewPS)
	print("HurtInfo >> OnUpdateLocalPCPS, ", GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS))
	if self.LocalPC == InLocalPC then
		local LocalPS = UE.UPlayerStatics.GetCPS(self.LocalPC)
        if LocalPS then
            print("HurtInfo >> OnUpdateLocalPCPS, RegisterList MsgList_PS")
            MsgHelper:UnregisterList(self, self.MsgList_PS or {})
            self.MsgList_PS = {
                { MsgName = GameDefine.MsgCpp.UISync_UpdateOnDead,       Func = self.UpdateDeadInfo,         bCppMsg = true,WatchedObject =LocalPS },
            }
            MsgHelper:RegisterList(self, self.MsgList_PS)
        end
	end
end


function HurtInfo:UpdateDeadInfo(InDeadInfo)
    print("HurtInfo >> UpdateDeadInfo, ", InDeadInfo.bIsDead)
    if not InDeadInfo.bIsDead or not self.DirWidgetInfos then
        return
    end

    for index = #self.DirWidgetInfos, 1,-1 do
        local DirWidgetInfo = self.DirWidgetInfos[index]
        if DirWidgetInfo then
            UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, DirWidgetInfo.TimerHandle)
            if DirWidgetInfo.Widget then
                DirWidgetInfo.Widget:RemoveFromViewport()
                DirWidgetInfo.Widget = nil
            end
            table.remove(self.DirWidgetInfos)
        end
    end
end
-------------------------------------------- Get/Set ------------------------------------

function HurtInfo:GetHurtDirInfo(InVictimTrans, InSourceLoc)
    local LocalSpaceLoc = UE.UKismetMathLibrary.InverseTransformLocation(InVictimTrans, InSourceLoc)
    local LocalSpacePos2D = UE.FVector2D(LocalSpaceLoc.X, LocalSpaceLoc.Y)
    local DotVal = UE.UKismetMathLibrary.DotProduct2D(self.ForwardVec2D, LocalSpacePos2D)
    local VecLen = UE.UKismetMathLibrary.VSize2D(LocalSpacePos2D)
    if (VecLen == 0) then
        return 
    end

    local Angle = UE.UKismetMathLibrary.DegAcos(DotVal / VecLen)
    local CrossVal = UE.UKismetMathLibrary.CrossProduct2D(self.ForwardVec2D, LocalSpacePos2D)
    local PosX = math.sin(math.rad(Angle)) * self.ItemDistRadius
    local PosY = (-1) * math.cos(math.rad(Angle)) * self.ItemDistRadius
    if (CrossVal < 0) then
        PosX = -PosX
        Angle = -Angle
    end
    return Angle, PosX, PosY
end

function HurtInfo:GetVictimConvTrans()
    local VictimActor = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
    local VictimLoc = VictimActor and
        VictimActor:K2_GetActorLocation() or self.LocalPC:K2_GetActorLocation()
    local CameraRot = self.LocalPC.PlayerCameraManager:GetCameraRotation()
    return UE.FTransform(CameraRot:ToQuat(), VictimLoc)
end

-------------------------------------------- Function ------------------------------------

function HurtInfo:AddDirWidgetInfo(InWeaponInstId, InBulletHitUIData)
    local OpDirWidgetInfo = nil
    for _, DirWidgetInfo in pairs(self.DirWidgetInfos) do
        if DirWidgetInfo and DirWidgetInfo.Widget and not DirWidgetInfo.Widget:IsVisible() then
            DirWidgetInfo.CurTime = 0
            DirWidgetInfo.WeaponInstId = InWeaponInstId
            DirWidgetInfo.BulletHitUIData = InBulletHitUIData

            DirWidgetInfo.Widget:SetVisibility(UE.ESlateVisibility.Visible)
            DirWidgetInfo.Widget:BPFunction_PlayHurtAnimation()
            OpDirWidgetInfo = DirWidgetInfo
            break
        end
    end

    -- Create sub item
    local MiscSystem = UE.UMiscSystem.GetMiscSystem(self)
    if not OpDirWidgetInfo then
        if not MiscSystem then
            return
        end
        local NewWidgetClass = MiscSystem.HurtInfoItemClass
        local NewWidgetObject = UE.UGUIUserWidget.Create(self.LocalPC, NewWidgetClass, self.LocalPC)
        if NewWidgetObject then
            if not self.Root then
                return
            end
            self.Root:AddChild(NewWidgetObject)
            NewWidgetObject:SetVisibility(UE.ESlateVisibility.Visible)
            NewWidgetObject:BPFunction_PlayHurtAnimation()
            NewWidgetObject.Slot:SetAutoSize(true)
            NewWidgetObject.Slot:SetZOrder(1)

            local NewAnchors = UE.FAnchors()
            NewAnchors.Minimum = UE.FVector2D(0.5)
            NewAnchors.Maximum = NewAnchors.Minimum
            NewWidgetObject.Slot:SetAnchors(NewAnchors)
            NewWidgetObject.Slot:SetAlignment(UE.FVector2D(0.5))

            local TempHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.UpdateHurtInfo}, self.UpdateTime, true, 0, 0)
            local DirWidgetInfo = {
                Widget = NewWidgetObject,
                CurTime = 0,
                WeaponInstId = InWeaponInstId,
                BulletHitUIData = InBulletHitUIData,
                TimerHandle = TempHandle
            }
            table.insert(self.DirWidgetInfos, DirWidgetInfo)
            print("HurtInfo >> AddDirWidgetInfo, Create[HurtInfo]!", GetObjectName(self), InWeaponInstId, InBulletHitUIData, GetObjectName(NewWidgetObject),#self.DirWidgetInfos)
            OpDirWidgetInfo = DirWidgetInfo
        end
    end
    
    if OpDirWidgetInfo then
        self.bCanTick = true
        self:UpdateHurtDirInfo(OpDirWidgetInfo)
    end
end

function HurtInfo:AddDirWidgetInfo_3D(InBulletHitUIData)
    local PlayerPawn = UE.UGameplayStatics.GetPlayerPawn(self,0)
    if not PlayerPawn or not UE.UKismetSystemLibrary.IsValid(PlayerPawn) then
        return
    end
    local PlayerState = UE.UGameplayStatics.GetPlayerState(self,0)
    if not PlayerState then
        return
    end

    local ADCMarkSystem = UE.UAdvancedWorldMarkSystem.GetAdvancedWorldMarkSystem(self)
    local MarkableInfo = UE.FAdvancedWorldMarkTaskData()
    local HitActor = InBulletHitUIData.WeaponOwningPawn
    MarkableInfo.Position = HitActor:K2_GetActorLocation()--敌方位置
    MarkableInfo.Rotation = HitActor:K2_GetActorRotation()--敌方旋转
    MarkableInfo.ItemKey = "HurtInfoIcon"
    MarkableInfo.WatchedObject = InBulletHitUIData.WeaponOwningPawn
    MarkableInfo.Owner = PlayerState
    MarkableInfo.ItemHandle = UE.FGMapItemHandle()
    MarkableInfo.TaskType = UE.EGMapItemTaskAction.Show
    print("HurtInfo >> AddDirWidgetInfo_3D ", GetObjectName(self))
    local ItemHandle = ADCMarkSystem:AddNewWorldMarkActionWithAdvancedWorldMarkTaskData(MarkableInfo)
end

function HurtInfo:UpdateHurtDirInfo(InDirWidgetInfo, InFinalTransform)
    local FinalTransform = InFinalTransform or self:GetVictimConvTrans()
    local Angle, PosX, PosY = self:GetHurtDirInfo(FinalTransform, InDirWidgetInfo.BulletHitUIData.SourceLoc)
    --print("HurtInfo >> UpdateHurtDirInfo, ", InDirWidgetInfo, FinalTransform, Angle, PosX, PosY)
    if Angle then
        InDirWidgetInfo.Widget:SetRenderTransformAngle(Angle)
        InDirWidgetInfo.Widget.Slot:SetPosition(UE.FVector2D(PosX, PosY))
    end
end

-- 
function HurtInfo:AutoFreeWidget(InDeltaTime)
    if (not self.CurWidgetNum) or (self.CurWidgetNum <= self.MaxUnusedWidgetNum) then
        return
    end
    self.CurAutoFreeTime = self.CurAutoFreeTime + self.UpdateTime
    if (self.CurAutoFreeTime <= self.MaxAutoFreeWaitTime) then
        return
    else
        self.CurAutoFreeTime = 0
    end

    local LastDirWidgetInfo = self.DirWidgetInfos[self.CurWidgetNum]
    if true and LastDirWidgetInfo then
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, LastDirWidgetInfo.TimerHandle)
        if LastDirWidgetInfo.Widget then
            LastDirWidgetInfo.Widget:RemoveFromViewport()
            LastDirWidgetInfo.Widget = nil
        end
        table.remove(self.DirWidgetInfos, self.CurWidgetNum)
        print("HurtInfo >> AutoFreeWidget remove data length = ",#self.DirWidgetInfos)
        self.CurWidgetNum = self.CurWidgetNum - 1
        --Dump(self.DirWidgetInfos, self.DirWidgetInfos, 9)
    end
end

-------------------------------------------- Callable ------------------------------------

function HurtInfo:UpdateHurtInfo()
    if not self.bCanTick then
        self:AutoFreeWidget()
        return
    end

    self.bCanTick = false
    self.CurWidgetNum = 0
    local ConvTrans = self:GetVictimConvTrans()
    for _, DirWidgetInfo in pairs(self.DirWidgetInfos) do
        if DirWidgetInfo and DirWidgetInfo.Widget and DirWidgetInfo.Widget:IsVisible() then
            DirWidgetInfo.CurTime = DirWidgetInfo.CurTime + self.UpdateTime
            if true and (DirWidgetInfo.CurTime > self.ShowHitEffectTime) then
                DirWidgetInfo.Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
            else
                self.bCanTick = true
                if self:GetIfHurt2DOpen() then
                    DirWidgetInfo.Widget:SetVisibility(UE.ESlateVisibility.Visible)
                else
                    DirWidgetInfo.Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
                end
                self:UpdateHurtDirInfo(DirWidgetInfo, ConvTrans)
            end
        end
        self.CurWidgetNum = self.CurWidgetNum + 1
    end
end

function HurtInfo:OnWeaponHitActor(InBulletHitUIData)
    local WeaponInstId = InBulletHitUIData.WeaponInstId
    local WeaponOwningPawn = InBulletHitUIData.WeaponOwningPawn
    local DamageAmount = InBulletHitUIData.DamageAmount
    local HitActor = InBulletHitUIData.HitActor
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)
    local GameTagSettings = UE.US1GameTagSettings.Get()

    print("HurtInfo >> OnWeaponHitActor[0], ", 
        GetObjectName(LocalPCPawn), WeaponInstId, DamageAmount, GetObjectName(WeaponOwningPawn), GetObjectName(HitActor))
    if (not LocalPCPawn) or (LocalPCPawn ~= HitActor) or (not GameTagSettings.HasASC(LocalPCPawn)) then
        -- 不是本地被攻击对象/或者人形对象
        return
    end

    print("HurtInfo >> OnWeaponHitActor[1], ", WeaponInstId)
    local bDead = GameTagSettings.HasTagBy(LocalPCPawn, GameTagSettings.DeathTag)

    local TeamExSubsystem = UE.UTeamExSubsystem.Get(LocalPCPawn)
	if not TeamExSubsystem then 
        return 
    end

    if bDead or TeamExSubsystem:IsTeammateByCHandCH(LocalPCPawn, WeaponOwningPawn) then
        -- 本地对象死亡/或者是队友
        return
    end
    
    print("HurtInfo >> OnWeaponHitActor[3], ", WeaponInstId)
    self:AddDirWidgetInfo(WeaponInstId, InBulletHitUIData)
    self:AddDirWidgetInfo_3D(InBulletHitUIData)
end
return HurtInfo