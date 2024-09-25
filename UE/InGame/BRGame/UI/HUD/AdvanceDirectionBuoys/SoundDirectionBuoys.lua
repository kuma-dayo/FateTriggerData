local SoundDirectionBuoys = Class("Common.Framework.UserWidget")

function SoundDirectionBuoys:OnInit()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    print("SoundDirectionBuoys >> OnInit, ", GetObjectName(self))

    self.ADCBussinessSystem = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(self)
	UserWidget.OnInit(self)
end

function SoundDirectionBuoys:GetLocalPCPawnLoc()
    local LocalPCPawn = UE.UPlayerStatics.GetLocalPCPlayerPawn(self.LocalPC)

	if (not LocalPCPawn) then 
        return nil
    end

    return LocalPCPawn:K2_GetActorLocation()
end

function SoundDirectionBuoys:BPNativeFunc_OnCustomUpdate(InTaskData)
    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()

    BlackBoardKeySelector.SelectedKeyName = "Opacity"
    local Opacity, OpacityType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsFloat(self.In3DDirectionTaskData.OtherData, BlackBoardKeySelector)

    if OpacityType then
        self:SetRenderOpacity(Opacity)
    end
    
end

function SoundDirectionBuoys:BPNativeFunc_OnTickCustomUpdate()
     local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()

    BlackBoardKeySelector.SelectedKeyName = "DistanceIndex"
    local DistanceIndex, DistanceIndexType = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(self.In3DDirectionTaskData.OtherData, BlackBoardKeySelector)
    
    --print("SoundDirectionBuoys >> BPNativeFunc_OnTickCustomUpdate, ", GetObjectName(self))
    self:RemoveAllActiveWidgetStyleFlags()

    if not self.LocalPC then
        self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    end
    if not self.LocalPC.PlayerState then
        return
    end
    local LocalViewTarget = UE.UPlayerStatics.GetPSPlayerPawn(self.LocalPC.PlayerState)
    local LocalPawnLoc = LocalViewTarget and LocalViewTarget:K2_GetActorLocation()
    local LocalPawnZ = LocalPawnLoc and LocalPawnLoc.Z
    local TargetActor = self.In3DDirectionTaskData.WatchedObj
    local LocalTargetLoc = TargetActor and TargetActor:K2_GetActorLocation()
    local TargetZ = LocalTargetLoc and LocalTargetLoc.Z

    if not self.ADCBussinessSystem then
        self.ADCBussinessSystem = UE.UAdvancedWorldBussinessMarkSystem.GetAdvancedWorldBussinessMarkSystem(self)
    end

    self.TopState = UE.EGDirectionRuleTopMode.None
    if LocalPawnZ and TargetZ and self.ADCBussinessSystem then
        if LocalPawnZ - TargetZ > self.ADCBussinessSystem.SoundVisualizationWidgetHighDistance then
            self.TopState = UE.EGDirectionRuleTopMode.Down
        elseif TargetZ - LocalPawnZ > self.ADCBussinessSystem.SoundVisualizationWidgetHighDistance then
            self.TopState = UE.EGDirectionRuleTopMode.Top
        end
    end

    if DistanceIndexType then
        if 1 == DistanceIndex then
            self:RemoveAllActiveWidgetStyleFlags()
            if UE.EGDirectionRuleAbsorbMode.Middle == self.AbsorbState then
                if UE.EGDirectionRuleTopMode.Top == self.TopState then
                    self:AddActiveWidgetStyleFlags(14)
                    --print("SoundDirectionBuoys >> BPNativeFunc_OnTickCustomUpdate, UE.EGDirectionRuleTopMode.Top", GetObjectName(self))
                elseif UE.EGDirectionRuleTopMode.Down == self.TopState then
                    self:AddActiveWidgetStyleFlags(11)
                    --print("SoundDirectionBuoys >> BPNativeFunc_OnTickCustomUpdate, UE.EGDirectionRuleTopMode.Down", GetObjectName(self))
                end
            elseif UE.EGDirectionRuleAbsorbMode.Left == self.AbsorbState then
                self:AddActiveWidgetStyleFlags(8)
            elseif UE.EGDirectionRuleAbsorbMode.Right == self.AbsorbState then
                 self:AddActiveWidgetStyleFlags(5)
            end

        elseif 2 == DistanceIndex then
            self:AddActiveWidgetStyleFlags(1)
            if UE.EGDirectionRuleAbsorbMode.Middle == self.AbsorbState then
                self:AddActiveWidgetStyleFlags(3)
                if UE.EGDirectionRuleTopMode.Top == self.TopState then
                     self:AddActiveWidgetStyleFlags(15)
                     --print("SoundDirectionBuoys >> BPNativeFunc_OnTickCustomUpdate, UE.EGDirectionRuleTopMode.Top", GetObjectName(self))
                elseif UE.EGDirectionRuleTopMode.Down == self.TopState then
                    self:AddActiveWidgetStyleFlags(12)
                end
            elseif UE.EGDirectionRuleAbsorbMode.Left == self.AbsorbState then
                self:AddActiveWidgetStyleFlags(9)
            elseif UE.EGDirectionRuleAbsorbMode.Right == self.AbsorbState then
                self:AddActiveWidgetStyleFlags(6)
            end
        elseif 3 == DistanceIndex then
            self:AddActiveWidgetStyleFlags(2)
            if UE.EGDirectionRuleAbsorbMode.Middle == self.AbsorbState then
                self:AddActiveWidgetStyleFlags(4)
                if UE.EGDirectionRuleTopMode.Top == self.TopState then
                    self:AddActiveWidgetStyleFlags(16)
                elseif UE.EGDirectionRuleTopMode.Down == self.TopState then
                    self:AddActiveWidgetStyleFlags(13)
                end
            elseif UE.EGDirectionRuleAbsorbMode.Left == self.AbsorbState then
                self:AddActiveWidgetStyleFlags(10)
            elseif UE.EGDirectionRuleAbsorbMode.Right == self.AbsorbState then
                self:AddActiveWidgetStyleFlags(7)
            end
        end
    end
    
end

return SoundDirectionBuoys