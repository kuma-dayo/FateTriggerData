--[[
    用于 WBP_VehicleSkinStickerEdit 的逻辑类
]]

local class_name = "VehicleSkinStickerEdit"
VehicleSkinStickerEdit = VehicleSkinStickerEdit or BaseClass(nil, class_name)

---@class VehicleSkinStickerEditParam

function VehicleSkinStickerEdit:OnInit()
	self.BindNodes = {
        { UDelegate = self.View.Btn_Close.OnClicked,				Func = Bind(self,self.OnBtnCloseClick) },
        { UDelegate = self.View.Btn_Close.OnHovered,				Func = Bind(self, self.OnBtnCloseHover) },
		{ UDelegate = self.View.Btn_Close.OnUnhovered,				Func = Bind(self, self.OnBtnCloseUnhover) },

        { UDelegate = self.View.Btn_Alignment.OnClicked,			Func = Bind(self,self.OnBtnAlignmentClick) },
        { UDelegate = self.View.Btn_Alignment.OnHovered,				Func = Bind(self, self.OnBtnAlignmentHover) },
		{ UDelegate = self.View.Btn_Alignment.OnUnhovered,				Func = Bind(self, self.OnBtnAlignmentUnhover) },

        { UDelegate = self.View.Btn_Mirror.OnClicked,			Func = Bind(self,self.OnBtnMirrorClick) },
        { UDelegate = self.View.Btn_Mirror.OnHovered,				Func = Bind(self, self.OnBtnMirrorHover) },
		{ UDelegate = self.View.Btn_Mirror.OnUnhovered,				Func = Bind(self, self.OnBtnMirrorUnhover) },
    }

    self.MsgList = 
    {
        {Model = InputModel, MsgName = InputModel.ON_COMMON_TOUCH_INPUT,		Func =  Bind(self,self.ON_COMMON_TOUCH_INPUT) },
        {Model = InputModel, MsgName = InputModel.ON_TOUCH_LERP,		Func =  Bind(self,self.ON_COMMON_TOUCH_INPUT) }, 
    }
    self.VehicleSkinStickerEditUtil = require("Client.Modules.Arsenal.Vehicle.VehicleSkinStickerEditUtil")
end

function VehicleSkinStickerEdit:OnShow(Param)
    self.Param = self.Param or Param or {}
    self.VehicleId = self.Param.VehicleId or 0
    self.VehicleSkinId = self.Param.VehicleSkinId or 0
    self.StickerId = self.Param.StickerId or 0
    self.StickerSlot = self.Param.StickerSlot or 0

    self.StickerEditInfo = {
        StickerId =  self.StickerId,
        Slot = self.StickerSlot,
        Position =  {X=0, Y=0, Z=0},
        Rotator =  {X=0, Y=0, Z=0},
        RotateAngle = 0,
        ScaleLength = 1
    }
  
    self.HitResult = UE.FHitResult()
    self:UpdateStickerShow(self.VehicleSkinId, self.StickerId)
end


function VehicleSkinStickerEdit:OnHide()
    if self.VehicleSkinStickerEditUtil ~= nil then
        self.VehicleSkinStickerEditUtil.FinishEditImage()
    end

    if self.DelayFlushTimer then
        self:RemoveTimer(self.DelayFlushTimer)
        self.DelayFlushTimer = nil
    end

    --清理
    self:OnEditEnd(true)
end

function VehicleSkinStickerEdit:SetPreviewing(Previewing)
    self.Previewing = Previewing
end

--[[
    根据2DUI编辑结果，来存储，并同步更新贴纸Component展示
]]
function VehicleSkinStickerEdit:SetEditInfoTransform(InputChgData)
    if InputChgData == nil then
        return
    end
    local LocalPC = CommonUtil.GetLocalPlayerC()
    if  LocalPC == nil then
        return 
    end
    local SkinActor = self:GetVehicleSkinActor()
    if SkinActor == nil then
        return
    end
    local Position = InputChgData.Position
    local Scale = InputChgData.Scale
    local RotateAngle = InputChgData.RotateAngle
    local ScaleLength = InputChgData.ScaleLength

    local AbsolutePos = UE.USlateBlueprintLibrary.LocalToAbsolute(self.View.ImgPanel:GetParent():GetCachedGeometry(), UE.FVector2D(Position.X, Position.Y))
    local ViewPortPosition = UE.USlateBlueprintLibrary.AbsoluteToLocal(UE.UWidgetLayoutLibrary.GetViewportWidgetGeometry(LocalPC), AbsolutePos)
    local ViewportScale = UE.UWidgetLayoutLibrary.GetViewportScale(LocalPC)
    local ScreenPos = ViewPortPosition * ViewportScale
    local WorldLocation, WorldDirection, IsOK = LocalPC:DeprojectScreenPositionToWorld(ScreenPos.X, ScreenPos.Y)
    if not IsOK then
        self:UpdateDecalComponentVisiblity(false)
        CWaring("TraceLine: Screen 2 World Failed")
        return
    end
    
    local IsHit = UE.UGameHelper.LineTrace(LocalPC, self.HitResult, WorldLocation, WorldDirection, 10000, 
        UE.ECollisionChannel.ECC_GameTraceChannel13, false)
    if not IsHit then
        CWaring("TraceLine: World Line Trance Failed")
        self:UpdateDecalComponentVisiblity(false)
        return
    end
    self:UpdateDecalComponentVisiblity(true)

   -- local Z = self.HitResult.ImpactNormal
    -- local X = WorldDirection
    -- local Y = Z:Cross(X)
    -- X = Y:Cross(Z)
    -- -- local RotateByZ = UE.UKismetMathLibrary.Quat_MakeFromEuler(UE.FVector(0.0, 0.0, RotateDegree))
    -- -- X = RotateByZ:RotateVector(X)
    -- -- Y = RotateByZ:RotateVector(Y)
    -- local Rotator = UE.UKismetMathLibrary.MakeRotationFromAxes(X, Y, Z)
    
    local Rotator = self.HitResult.ImpactNormal:ToRotator()
    local SkinActorTransform = SkinActor:GetTransform()
    local ActorRotator = UE.UKismetMathLibrary.InverseTransformRotation(SkinActorTransform, Rotator)
    local ActorPosition = SkinActorTransform:InverseTransformPositionNoScale(self.HitResult.ImpactPoint)
   

    --UI信息
    self.StickerEditInfo.RotateAngle = RoundFloat(UE.UKismetMathLibrary.DegreesToRadians(RotateAngle or 0))
    self.StickerEditInfo.ScaleLength = RoundFloat(ScaleLength)

    --贴纸信息
    self.StickerEditInfo.Position = {
        X = RoundFloat(ActorPosition.X), 
        Y = RoundFloat(ActorPosition.Y), 
        Z = RoundFloat(ActorPosition.Z)
    }
    self.StickerEditInfo.Rotator = {
        X = RoundFloat(ActorRotator.Pitch),
        Y = RoundFloat(ActorRotator.Yaw),
        Z = RoundFloat(ActorRotator.Roll),
    }
    self.StickerEditInfo.Scale = {
        X = RoundFloat(Scale.X),
        Y = RoundFloat(Scale.Y),
        Z = RoundFloat(Scale.Z),
    }

    --保存编辑现场
    local CameraSpringArmRotation,Length = self:GetVehicleSpringArmRotationAndLength()
    local VehicleRotation = self:GetVehicleRotation()
    if CameraSpringArmRotation ~= nil and VehicleRotation ~= nil then
        self.StickerEditInfo.Restore = 
        {
            VehicleRotation = {
                X = RoundFloat(VehicleRotation.Pitch),
                Y = RoundFloat(VehicleRotation.Yaw),
                Z = RoundFloat(VehicleRotation.Roll),
            },
            SpringArmRotation = {
                X = RoundFloat(CameraSpringArmRotation.Pitch),
                Y = RoundFloat(CameraSpringArmRotation.Yaw),
                Z = RoundFloat(CameraSpringArmRotation.Roll),
            },
            SpringArmArmLength = Length
        }  
    end

    self:OnEditChange()
end


function VehicleSkinStickerEdit:UpdateDecalComponentVisiblity(bVisible)
    local Component = self:GetSkinDecalComponent(self.VehicleSkinId,self.StickerEditInfo.Slot)
    if Component ~= nil then
        Component:SetVisibility(bVisible)
        Component:SetHiddenInGame(not bVisible)
    end
end

--[[
    要据贴纸Component实际位置，还原到UI显示位置
]]
function VehicleSkinStickerEdit:GetEditPanelPosition(Slot)
    local Position = UE.FVector2D(0, 0)
    local LocalPC = CommonUtil.GetLocalPlayerC()
    if  LocalPC == nil then
        return Position
    end
    local Component = self:GetSkinDecalComponent(self.VehicleSkinId, Slot)
    if not Component then
        CWaring("VehicleSkinStickerEdit:GetEditPanelPosition Component nil")
        return Position
    end
    local ScreenPos = UE.FVector2D(0, 0)
    local IsOK = LocalPC:ProjectWorldLocationToScreen(Component:K2_GetComponentLocation(), ScreenPos, true)
    if not IsOK then
        CWaring("GetEditPanelPosition: World 2 Screen Failed")
        return Position
    end
    local ViewportPosition = UE.FVector2D(0, 0)
    UE.USlateBlueprintLibrary.ScreenToViewport(self.View,ScreenPos,ViewportPosition)
    return ViewportPosition
end

function VehicleSkinStickerEdit:GetStickerEditInfo()
    return self.StickerEditInfo
end

function VehicleSkinStickerEdit:IsStickerEquip()
   return self.StickerEditInfo and self.StickerEditInfo.Slot ~= 0 or false
end

function VehicleSkinStickerEdit:UpdateStickerEditInfo()
    local EditInfo = MvcEntry:GetModel(VehicleModel):GetVehicleSkinStickerBySlot(self.VehicleSkinId, self.StickerSlot)
    if EditInfo then
        self.StickerEditInfo = DeepCopy(EditInfo)
    else
        self.StickerEditInfo.StickerId = self.StickerId
        self.StickerEditInfo.Slot = self.StickerSlot
        self.StickerEditInfo.Position =  self.StickerEditInfo.Position  or {X=0, Y=0, Z=0}
        self.StickerEditInfo.Rotator =  self.StickerEditInfo.Rotator or {X=0, Y=0, Z=0}
        self.StickerEditInfo.Scale =  self.StickerEditInfo.Scale or {X=1, Y=1, Z=1}
        self.StickerEditInfo.RotateAngle = self.StickerEditInfo.RotateAngle  or 0
        self.StickerEditInfo.ScaleLength = self.StickerEditInfo.ScaleLength  or 1
        self.StickerEditInfo.Restore = {}
    end
    self:OnEditStart()
    self.BeforeEditInfo = DeepCopy(self.StickerEditInfo) 
end

function VehicleSkinStickerEdit:GetVehicleSkinActor()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return 
    end
    local VehicleAvatar = HallAvatarMgr:GetHallAvatar(0, ViewConst.VehicleDetail, self.VehicleId)
    if VehicleAvatar == nil then
        return
    end
    return VehicleAvatar:GetSkinActor(self.VehicleSkinId)
end

function VehicleSkinStickerEdit:GetSkinDecalComponent(VehicleSkinId, StickerSlot)
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return 
    end
    local VehicleAvatar = HallAvatarMgr:GetHallAvatar(0, ViewConst.VehicleDetail, self.VehicleId)
    if VehicleAvatar == nil then
        return
    end
    local SkinDecalComponent = VehicleAvatar:GetSkinDecalComponent(VehicleSkinId, StickerSlot)
    return SkinDecalComponent
end


--以下两个用来还原现场
function VehicleSkinStickerEdit:GetVehicleSpringArmRotationAndLength()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return 
    end
    local VehicleAvatar = HallAvatarMgr:GetHallAvatar(0, ViewConst.VehicleDetail, self.VehicleId)
    if VehicleAvatar == nil then
        return
    end
    local Arm = VehicleAvatar:GetCameraSpringArm()
    if Arm == nil then
        return
    end
    return Arm:K2_GetComponentRotation(), Arm.TargetArmLength
end

function VehicleSkinStickerEdit:SetVehicleSpringArmRotationAndLength(Rotation, Length)
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return 
    end
    local VehicleAvatar = HallAvatarMgr:GetHallAvatar(0, ViewConst.VehicleDetail, self.VehicleId)
    if VehicleAvatar == nil then
        return
    end
    local Arm = VehicleAvatar:GetCameraSpringArm()
    if Arm == nil then
        return
    end
    Arm.bEnableCameraRotationLag = true
    Arm.TargetArmLength = Length or Arm.TargetArmLength
    Arm:K2_SetWorldRotation(Rotation, false, UE.FHitResult(), false)
end

function VehicleSkinStickerEdit:GetVehicleRotation()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return 
    end
    local VehicleAvatar = HallAvatarMgr:GetHallAvatar(0, ViewConst.VehicleDetail, self.VehicleId)
    if VehicleAvatar == nil then
        return
    end
    return VehicleAvatar:K2_GetActorRotation()
end


function VehicleSkinStickerEdit:SetVehicleRotation(Rotation)
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return 
    end
    local VehicleAvatar = HallAvatarMgr:GetHallAvatar(0, ViewConst.VehicleDetail, self.VehicleId)
    if VehicleAvatar == nil then
        return
    end
    VehicleAvatar:K2_SetActorRotation(Rotation, false)
end


function VehicleSkinStickerEdit:UpdateStickerShow(VehicleSkinId, StickerId, StickerSlot)
    self.VehicleSkinId = VehicleSkinId or 0
    self.StickerId = StickerId or 0
    self.StickerSlot = StickerSlot or 0

    self.StickerEditInfo.StickerId = self.StickerId
    self.StickerEditInfo.Slot = self.StickerSlot
    self.BeforeEditInfo = DeepCopy(self.StickerEditInfo)

    if self.StickerId == 0 then
        self.View:SetVisibility( UE.ESlateVisibility.Collapsed)
        return
    end
    self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self:UpdateStickerEditInfo()
end


function VehicleSkinStickerEdit:UpdateStickerHoverState(Slot, HoverOrNot)
    local Component = self:GetSkinDecalComponent(self.VehicleSkinId, Slot)
    if not Component then
        CError("VehicleSkinStickerEdit:UpdateStickerHoverState Component nil",true)
        return
    end
    --贴纸高亮
    local HoverColor = UE.FLinearColor(0.01, 0.01, 0.02, 1)
    local UnhoverColor = UE.FLinearColor(0.91, 0.86, 0.73, 1)
    if HoverOrNot then 
        Component:SetDecalColor(HoverColor)
    else
        Component:SetDecalColor(UnhoverColor)
    end

    --编辑框出现，但不能编辑
    self.View:SetVisibility(HoverOrNot and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if HoverOrNot then
        local StickerEditInfo = MvcEntry:GetModel(VehicleModel):GetVehicleSkinStickerBySlot(self.VehicleSkinId, Slot)
        if StickerEditInfo == nil then
            return
        end
        if StickerEditInfo.Restore then
            if StickerEditInfo.Restore.VehicleRotation and StickerEditInfo.Restore.SpringArmRotation then
                local VehicleRotation = UE.FRotator(StickerEditInfo.Restore.VehicleRotation.X, 
                    StickerEditInfo.Restore.VehicleRotation.Y, 
                    StickerEditInfo.Restore.VehicleRotation.Z)
                self:SetVehicleRotation(VehicleRotation)
    
                local SpringArmRotation = UE.FRotator(StickerEditInfo.Restore.SpringArmRotation.X, 
                    StickerEditInfo.Restore.SpringArmRotation.Y, 
                    StickerEditInfo.Restore.SpringArmRotation.Z) 
                self:SetVehicleSpringArmRotationAndLength(SpringArmRotation, StickerEditInfo.Restore.SpringArmArmLength)
            end
        end

        if self.DelayFlushTimer then
            self:RemoveTimer(self.DelayFlushTimer)
            self.DelayFlushTimer = nil
        end
        self.DelayFlushTimer = self:InsertTimer(Timer.NEXT_FRAME, function ()
            if StickerEditInfo ~= nil then
                local InitEditParam =  
                {
                    Position = self:GetEditPanelPosition(StickerEditInfo.Slot),
                    Scale = StickerEditInfo.Scale,
                    RotateAngle = RoundFloat(UE.UKismetMathLibrary.RadiansToDegrees(StickerEditInfo.RotateAngle)),
                    ScaleLength = StickerEditInfo.ScaleLength,
                }
                self.VehicleSkinStickerEditUtil.EnterPreEditImage(self, InitEditParam)
            end
        end)
    end
end

function VehicleSkinStickerEdit:OnEditStart()
    if self.StickerId == 0 then
        return
    end

    --还原现场
    if self.StickerEditInfo.Restore then
        if self.StickerEditInfo.Restore.VehicleRotation and self.StickerEditInfo.Restore.SpringArmRotation then
            local VehicleRotation = UE.FRotator(self.StickerEditInfo.Restore.VehicleRotation.X, 
                self.StickerEditInfo.Restore.VehicleRotation.Y, 
                self.StickerEditInfo.Restore.VehicleRotation.Z)
            self:SetVehicleRotation(VehicleRotation)

            local SpringArmRotation = UE.FRotator(self.StickerEditInfo.Restore.SpringArmRotation.X, 
                self.StickerEditInfo.Restore.SpringArmRotation.Y, 
                self.StickerEditInfo.Restore.SpringArmRotation.Z) 
            self:SetVehicleSpringArmRotationAndLength(SpringArmRotation, self.StickerEditInfo.Restore.SpringArmArmLength)
        end
    end

    if self.DelayFlushTimer then
        self:RemoveTimer(self.DelayFlushTimer)
        self.DelayFlushTimer = nil
    end
    self.DelayFlushTimer = self:InsertTimer(Timer.NEXT_FRAME, function ()
        -- 进入编辑
        local InitEditParam =  
        {
            Position = self:GetEditPanelPosition(self.StickerEditInfo.Slot),
            Scale = self.StickerEditInfo.Scale,
            RotateAngle = RoundFloat(UE.UKismetMathLibrary.RadiansToDegrees(self.StickerEditInfo.RotateAngle)),
            ScaleLength = self.StickerEditInfo.ScaleLength,
        }
        self.VehicleSkinStickerEditUtil.EnterEditImage(self, InitEditParam)
        self:UpdateStickerEditPos()

        local Param = {
            VehicleSkinId = self.VehicleSkinId,
            StickerInfo = self.StickerEditInfo,
        }
        MvcEntry:GetModel(VehicleModel):DispatchType(VehicleModel.ON_ADD_VEHICLE_SKIN_STICKER, Param) 
    end)
end

function VehicleSkinStickerEdit:OnEditChange()
    if self.StickerId == 0 then
        return
    end
    local Param = {
        VehicleSkinId = self.VehicleSkinId,
        StickerInfo = self.StickerEditInfo,
    }
    MvcEntry:GetModel(VehicleModel):DispatchType(VehicleModel.ON_UPDATE_VEHICLE_SKIN_STICKER, Param)
end

function VehicleSkinStickerEdit:OnEditEnd(bClean)
    if self:IsStickerEquip() then
        return
    end
    CommonUtil.SetCursorType(GameConfig.CursorType.Default)
    if not bClean then
        self:UpdateDecalComponentVisiblity(false)
    else
        local Param = {
            VehicleSkinId = self.VehicleSkinId,
            StickerInfo = self.StickerEditInfo,
        }
        MvcEntry:GetModel(VehicleModel):DispatchType(VehicleModel.ON_REMOVE_VEHICLE_SKIN_STICKER, Param)
    end
end

function VehicleSkinStickerEdit:ON_COMMON_TOUCH_INPUT()
    if self.StickerId == 0 then
        return
    end
    if self.Previewing then
        return
    end
    if  self.VehicleSkinStickerEditUtil then
        self.VehicleSkinStickerEditUtil.PostTransformChg()
    end
end

function VehicleSkinStickerEdit:OnBtnCloseClick()
    if self:IsStickerEquip() then
        MvcEntry:GetCtrl(ArsenalCtrl):SendProto_RemoveVehicleSkinSticker(self.VehicleSkinId, 
            self.StickerEditInfo.StickerId, self.StickerEditInfo.Slot, VehicleSkinStickerMdt.StickerUpdateType.UNEQUIP)
    else
        self:OnEditEnd()
        self:UpdateStickerShow(self.VehicleSkinId, 0, 0)
        if self.Param.CallCloseFunc ~= nil then
            self.Param.CallCloseFunc()
        end
        self.StickerEditInfo.Position = {X=0, Y=0, Z=0}
        self.StickerEditInfo.Rotator = {X=0, Y=0, Z=0}
        self.StickerEditInfo.Scale =  {X=1, Y=1, Z=1}
        self.StickerEditInfo.RotateAngle = 0
        self.StickerEditInfo.ScaleLength = 1
    end
end

function VehicleSkinStickerEdit:OnBtnCloseHover()
    self.View:PlayAnimation(self.View.vx_btn_close_hover)
end

function VehicleSkinStickerEdit:OnBtnCloseUnhover()
    self.View:PlayAnimation(self.View.vx_btn_close_unhover)
end

function VehicleSkinStickerEdit:OnBtnAlignmentClick()
    if not self.Param.CallAlignmentFunc then
        return
    end
    self.View:PlayAnimation(self.View.vx_btn_aligment_click)
    if self.VehicleSkinStickerEditUtil then
        self.VehicleSkinStickerEditUtil.DoHorizontalFlip()
    end
    self.Param.CallAlignmentFunc(self.StickerId)
    self.View:PlayAnimation(self.View.vx_btn_aligment_unclick)
end

function VehicleSkinStickerEdit:OnBtnAlignmentHover()
    self.View:PlayAnimation(self.View.vx_btn_aligment_hover)
end

function VehicleSkinStickerEdit:OnBtnAlignmentUnhover()
    self.View:PlayAnimation(self.View.vx_btn_aligment_unhover)
end


function VehicleSkinStickerEdit:OnBtnMirrorClick()
    if not self.Param.CallMirrorFunc then
        return
    end
    self.View:PlayAnimation(self.View.vx_btn_mirror_click)
    if self.VehicleSkinStickerEditUtil then
        self.VehicleSkinStickerEditUtil.DoMirrorFlip()
    end
    self.Param.CallMirrorFunc(self.StickerId)
    self.View:PlayAnimation(self.View.vx_btn_mirror_unclick)
end

function VehicleSkinStickerEdit:OnBtnMirrorHover()
    self.View:PlayAnimation(self.View.vx_btn_mirror_hover)
end

function VehicleSkinStickerEdit:OnBtnMirrorUnhover()
    self.View:PlayAnimation(self.View.vx_btn_mirror_unhover)
end

function VehicleSkinStickerEdit:CanCommit()
    --未装备的贴纸无Slot
    if not self:IsStickerEquip() then
        return false
    end

    --数据是否修改
    local ToleranceForModify =  0.5
    if math.abs(self.BeforeEditInfo.Position.X - self.StickerEditInfo.Position.X) > ToleranceForModify 
     or math.abs(self.BeforeEditInfo.Position.Y - self.StickerEditInfo.Position.Y) > ToleranceForModify
     or math.abs(self.BeforeEditInfo.Rotator.X - self.StickerEditInfo.Rotator.X) > ToleranceForModify 
     or math.abs(self.BeforeEditInfo.Rotator.Y - self.StickerEditInfo.Rotator.Y) > ToleranceForModify 
     or math.abs(self.BeforeEditInfo.Rotator.Z - self.StickerEditInfo.Rotator.Z) > ToleranceForModify 
     or math.abs(self.BeforeEditInfo.RotateAngle - self.StickerEditInfo.RotateAngle) > ToleranceForModify
     or math.abs(self.BeforeEditInfo.ScaleLength - self.StickerEditInfo.ScaleLength) > ToleranceForModify then
        return true
    end

    if self.BeforeEditInfo.Scale.X ~= self.StickerEditInfo.Scale.X 
     or self.BeforeEditInfo.Scale.Y ~= self.StickerEditInfo.Scale.Y then
        return true
    end
    
    return false
end


function VehicleSkinStickerEdit:CommitEdit(AutoSave)
    if AutoSave then
        self:OnEditEnd()
    end
    if not self:CanCommit() then
        return false
    end
    MvcEntry:GetCtrl(ArsenalCtrl):SendProto_UpdateVehicleSkinSticker(self.VehicleSkinId, self.StickerEditInfo, 
        AutoSave and VehicleSkinStickerMdt.StickerUpdateType.AUTOSAVED or VehicleSkinStickerMdt.StickerUpdateType.EQUIP)
    return true
end


-- 更新底部按钮栏位置
-- 这里需要动态计算位置，蓝图锚点需左上方 alignmengt （1,0）
function VehicleSkinStickerEdit:UpdateStickerEditPos()
    local Position = self.View.ImgPanel.Slot:GetPosition()
    local Size = self.View.ImgPanel.Slot:GetSize()
    local CurAlignment = self.View.ImgPanel.Slot:GetAlignment()
    local Angle = self.View.ImgPanel.RenderTransform.Angle
    if Angle < 0 then
        Angle = 360 + Angle
    end
    local Width = Size.X
    local CulAngle = Angle % 180
    if CulAngle > 90 then
        CulAngle = 180 - CulAngle
    end
    local Height = Size.X/2 * math.sin(UE.UKismetMathLibrary.DegreesToRadians(CulAngle)) + Size.Y / 2 * math.cos(UE.UKismetMathLibrary.DegreesToRadians(CulAngle)) + Size.Y / 2
    local StickerEditSize = self.View.Sticker_Edit.Slot:GetSize()
    self.View.Sticker_Edit.Slot:SetPosition(UE.FVector2D(Position.X +  Width - CurAlignment.X * Width + (StickerEditSize.X  - Width)* 0.5,Position.Y + Height  - CurAlignment.Y * Size.Y))
end

function VehicleSkinStickerEdit:OnMouseMove(LimitBox,InMyGeometry, InMouseEvent)
    if self.StickerId == 0 then
        return UE.UWidgetBlueprintLibrary.Unhandled()
    end
	if self.VehicleSkinStickerEditUtil and self.VehicleSkinStickerEditUtil.OnMouseMove then
		local ReturnEvent = self.VehicleSkinStickerEditUtil.OnMouseMove(self.View,LimitBox,InMyGeometry, InMouseEvent)
        self:UpdateStickerEditPos()
        return ReturnEvent
	end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function VehicleSkinStickerEdit:OnMouseButtonDown(InMyGeometry, InMouseEvent)
    if self.StickerId == 0 then
        return UE.UWidgetBlueprintLibrary.Unhandled()
    end
	if self.VehicleSkinStickerEditUtil and self.VehicleSkinStickerEditUtil.OnMouseButtonDown then
		return self.VehicleSkinStickerEditUtil.OnMouseButtonDown(self.View,InMyGeometry, InMouseEvent)
	end
    return UE.UWidgetBlueprintLibrary.Handled()
end

function VehicleSkinStickerEdit:OnMouseButtonUp(InMyGeometry, InMouseEvent)
    if self.StickerId == 0 then
        return UE.UWidgetBlueprintLibrary.Unhandled()
    end
    if self.VehicleSkinStickerEditUtil and self.VehicleSkinStickerEditUtil.OnMouseButtonUp then
		return self.VehicleSkinStickerEditUtil.OnMouseButtonUp(self.View,InMyGeometry, InMouseEvent)
	end
    return UE.UWidgetBlueprintLibrary.Handled()
end

return VehicleSkinStickerEdit
