require "UnLua"
require "InGame.BRGame.PlayzoneData"
require ("InGame.BRGame.GameDefine")

local BP_Playzone_C = Class()

local function ProcRun(self)
    --self.MeshComponent:K2_SetWorldLocation(UE.FVector(0,0,0),false,nil,false)
    self:EnablePlayzoneShrinking()
    UE.UKismetSystemLibrary.Delay(self, self.DelaySecond)

    self.MeshComponent:SetVisibility(true)
    local point_count = self.SplineComponent:GetNumberOfSplinePoints()
    if self.IsRandomPlayzone then
        self:PlayzoneShrinkingByRandomPoints(self.Keypoints)
    else
        self:PlayzoneShrinkingByStaticPoints(self.Keypoints)
    end
end

function BP_Playzone_C:PlayzoneShrinkingByRandomPoints(points)
    
    print("BP_Playzone_C", "BEGIN PlayzoneShrinkingByRandomPoints")
    --需要计算出第一个点的位置
    local randomDistanceX = math.random(-self.originRandomDistance,self.originRandomDistance )
    local randomDistanceY = math.random(-self.originRandomDistance,self.originRandomDistance )
    points:GetRef(1).CircleCenter = UE.FVector(points:GetRef(1).CircleCenter.X+randomDistanceX,points:GetRef(1).CircleCenter.Y+randomDistanceY, self.ZScale)
    
    --获取第一个点之后才能进行后面的计算
    local pointsLength = points:Length()
    for i = 1, pointsLength do
        local currentPoint = points:GetRef(i)
        print("BP_Playzone_C", "huijin current point",currentPoint.CircleCenter)
        --计算到这个点之后开始计算下一个点的位置
        if i ~= pointsLength then 
            local nextPoint = points:GetRef(i+1)
            local nextPosition = self:GetNextPointPosition(currentPoint,nextPoint,i)
            nextPoint.CircleCenter = nextPosition
        end
        self:ShrinkingPoint(currentPoint)
        
        UE.UKismetSystemLibrary.Delay(self, currentPoint.HoldingTime + currentPoint.ShrinkTime)
    end
end


function BP_Playzone_C:GetNextPointPosition(currentPoint,nextPoint,index)
    if self.IsWeighted then
       local v = self:CalculatePlayzoneCenter(currentPoint,index)
       -- print("BP_Playzone_C", "testreturn",v)
       return UE.FVector(v.X,v.Y,self.ZScale)
    else
        local RadiusDifference = currentPoint.Radius - nextPoint.Radius
        local nextPosition = UE.FVector(
            currentPoint.CircleCenter.X + math.random(-RadiusDifference,RadiusDifference),
            currentPoint.CircleCenter.Y + math.random(-RadiusDifference,RadiusDifference), 
            self.ZScale) 
        return nextPosition
    end
end

function BP_Playzone_C:PlayzoneShrinkingByStaticPoints(points)
    print("BP_Playzone_C", "BEGIN PlayzoneShrinkingByStaticPoints")
    for i = 1, points:Length() do
        local keypoint = points:Get(i)
        local Prevkeypoint = keypoint
        if i > 1 then 
            Prevkeypoint = points:Get(i-1)
        else
             
        end
        self:ShrinkingPoint(keypoint,Prevkeypoint)

        UE.UKismetSystemLibrary.Delay(self, keypoint.HoldingTime)
    end
end

function BP_Playzone_C:ShrinkingPoint(point,Prevkeypoint)

    local keypoint = point
    local centerFrom =  self:K2_GetActorLocation()
    if Prevkeypoint then
        centerFrom = Prevkeypoint.CircleCenter + self.OriginalCenter
    end

    local radiusFrom = self.LastRadiusUnit
    local centerTo = keypoint.CircleCenter + self.OriginalCenter
    local radiusTo = keypoint.Radius
    print("BP_Playzone_C", "huijin data",centerFrom, centerTo, radiusFrom, radiusTo,keypoint.CircleCenter)
    self.CurrentPoint = keypoint
    
    -- 执行缩圈
    self.ClientData.bHoldingTime = false
    self.ClientData.Keypoint = self.CurrentPoint
    self:ForceUpdateClientData()
    print("BP_Playzone_C", ">> bHoldingTime ", false)

    self:ShrinkPlayzone(keypoint.ShrinkTime, centerFrom, centerTo, radiusFrom, radiusTo)
    self.LastRadiusUnit = radiusTo
        
    -- 执行静置
    self.ClientData.bHoldingTime = true
    self.ClientData.Keypoint = self.CurrentPoint
    local OldCircleNum = self.ClientData.CurCircleNum
    self.ClientData.bEnded = (self.Keypoints:Length() == OldCircleNum)
    if not self.ClientData.bEnded then
        self.ClientData.CurCircleNum = OldCircleNum + 1
    end
    self:ForceUpdateClientData()
    print("BP_Playzone_C", ">> bHoldingTime ", true)
end

function BP_Playzone_C:BeginPlayzone()
    if self.IsRandomPlayzone then
        self.Keypoints = self.RandomKeypoints
    else
        self.Keypoints = self.RandomKeypoints:GetRef(self.CurrentEditorKeyPointIndex+1)
    end

    UE.UKismetSystemLibrary.PrintString(nil, "Playzone Begin at", true, true, UE.FLinearColor(0,1,1,1), 10)

    coroutine.resume(coroutine.create(ProcRun), self)
end

function BP_Playzone_C:Initialize(_)
    -- self.DelaySecond = self.CurrentPoint.ShrinkTime
    -- self.InitialRadiusUnit = self.CurrentPoint.Radius
    -- print("BP_Playzone_C", "huijin value ",self.CurrentPoint.ShrinkTime)
    -- self.LastRadiusUnit = self.InitialRadiusUnit

end

function BP_Playzone_C:ReceiveBeginPlay()
    self.MeshComponent:SetVisibility(false)
   -- self:K2_SetActorLocation(UE.FVector(0,0,0), false, nil, false)

   MsgHelper:SendCpp(self, GameDefine.MsgCpp.PLAYZONE_Beginplay, self)
end

function BP_Playzone_C:EnablePlayzoneShrinking()
    -- 启动静置
    self.ClientData.bEnable = true
    self.ClientData.bHoldingTime = true
    self.ClientData.Keypoint = self.CurrentPoint
    self.ClientData.CurCircleNum = self.ClientData.CurCircleNum + 1
    self:ForceUpdateClientData()
    print("BP_Playzone_C", ">> bHoldingTime ", true)

    --
    self.DelaySecond = self.CurrentPoint.HoldingTime
    self.InitialRadiusUnit = self.CurrentPoint.Radius
    self.LastRadiusUnit = self.InitialRadiusUnit

    print("BP_Playzone_C", "playzone shrink enabled")
    --SetPlayzoneRadius(self.InitialRadiusUnit, self)
    local scale = self.InitialRadiusUnit * 0.02
    print("BP_Playzone_C", "huijin value ",self.InitialRadiusUnit)
    --print("BP_Playzone_C", self.MeshComponent.SetRelativeScale3D, self.K2_GetActorLocation)
    self.MeshComponent:SetWorldScale3D(UE.FVector(scale, scale, self.ZScale))
    local location = self:K2_GetActorLocation()
    self.OriginalCenter = location
    print("BP_Playzone_C", "playzone now at", location)
    self.bIsShrinking = true
end

--function BP_Playzone_C:ReceiveEndPlay()
--end

function BP_Playzone_C:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)
    --print("BP_Playzone_C", "Tick PlayZone ", self:GetLocalRole(), UE.ENetRole.ROLE_Authority)
    if self:GetLocalRole() ~= UE.ENetRole.ROLE_Authority then
        return
    end
    if self.bIsShrinking then
        local NumPlayerNotInside = self.PlayerNotInside:Length()
        for i = 1, NumPlayerNotInside do
            local EachPawn = self.PlayerNotInside:Get(i)
            self:ApplyPlayzoneDamageToPlayer(EachPawn, self.CurrentPoint)
            --print("BP_Playzone_C", "Tick PlayZone ", EachPS.PlayerId)
        end
    end
end

--function BP_Playzone_C:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
--end

--function BP_Playzone_C:ActorBeginOverlap(PlayerState)
--end

--function BP_Playzone_C:ReceiveActorEndOverlap(OtherActor)
--end

return BP_Playzone_C