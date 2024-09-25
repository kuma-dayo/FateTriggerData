

local ParentClassName = "Common.Framework.UserWidget"
local UserWidget = require(ParentClassName)
local VehicleStatus = Class(ParentClassName)

function VehicleStatus:OnShow(InContextObject, InBlackboard)
    print("(Wzp)VehicleStatus:OnShow  [GetObjectName]=",GetObjectName(InContextObject))


    self:VXE_GetOffVehicle_In()
    local VMTag = UE.FGameplayTag()
    VMTag.TagName = "ViewModel.VehicleBase"
    local UIManager = UE.UGUIManager.GetUIManager(self)
    self.VehicleViewModel = UIManager:GetDynamicViewModel(VMTag,InContextObject)
    self.SportsCarPawn = InContextObject
    if not self.VehicleViewModel then
        --如果是空的还要再拿一次，可能你会很好奇
        --因为输入方式改变，OnShow会重刷，InContext传过来的并不再是载具Pawn了，而是UIManager对象，这导致了ViewModel无法获取，后面逻辑不再执行
        --单号：【【手柄】【载具】乘坐载具 切换操作模式时 载具信息hud闪烁一次后不动，固定显示切换操作时的数据】https://www.tapd.cn/68880148/bugtrace/bugs/view/1168880148001032250
        local CarPawn = UE.UVehicleFunctionLibrary.GetLocalVehicle(InContextObject)
        self.VehicleViewModel = UIManager:GetDynamicViewModel(VMTag,CarPawn)
        self.SportsCarPawn = CarPawn
    end
    if not self.VehicleViewModel then return end

    self:InitView()
    self:AddFieldValueChangedDelegate()
end

function VehicleStatus:InitView()
    self:UpdateSpeed(self.VehicleViewModel, nil)
    self:UpdateHealth(self.VehicleViewModel, nil)
    self:UpdateFuel(self.VehicleViewModel, nil)
    self:OnNearDead(self.VehicleViewModel, nil)
    self:OnIPCSpark(self.VehicleViewModel, nil)
    self:RefreshVehicleSeat(nil, nil)
end

function VehicleStatus:OnClose()
    print("VehicleStatus:OnClose")    
    self.SportsCarPawn = nil
    self:RemoveFieldValueChangedDelegate()
end

function VehicleStatus:AddFieldValueChangedDelegate()
    if not self.VehicleViewModel then return end
    self.VehicleViewModel:K2_AddFieldValueChangedDelegateSimple("Speed",{ self, self.UpdateSpeed })
    self.VehicleViewModel:K2_AddFieldValueChangedDelegateSimple("HealthValue",{ self, self.UpdateHealth })
    self.VehicleViewModel:K2_AddFieldValueChangedDelegateSimple("FuelValue",{ self, self.UpdateFuel })
    self.VehicleViewModel:K2_AddFieldValueChangedDelegateSimple("bIsNearDead",{ self, self.OnNearDead })
    self.VehicleViewModel:K2_AddFieldValueChangedDelegateSimple("bIsTakingDamage",{ self, self.OnTakingDamage })
    self.VehicleViewModel:K2_AddFieldValueChangedDelegateSimple("bLowFuelValue",{ self, self.OnBeLowFuel })
    self.VehicleViewModel:K2_AddFieldValueChangedDelegateSimple("IPCSpark",{ self, self.OnIPCSpark })

    self.VehicleViewModel.OnVehicleAttachDetachDeleage:Add(self,self.RefreshVehicleSeat)


end

function VehicleStatus:RemoveFieldValueChangedDelegate()
    if not self.VehicleViewModel then return end
    self.VehicleViewModel:K2_RemoveFieldValueChangedDelegateSimple("Speed",{ self, self.UpdateSpeed })
    self.VehicleViewModel:K2_RemoveFieldValueChangedDelegateSimple("HealthValue",{ self, self.UpdateHealth })
    self.VehicleViewModel:K2_RemoveFieldValueChangedDelegateSimple("FuelValue",{ self, self.UpdateFuel })
    self.VehicleViewModel:K2_RemoveFieldValueChangedDelegateSimple("bIsNearDead",{ self, self.OnNearDead })
    self.VehicleViewModel:K2_RemoveFieldValueChangedDelegateSimple("bIsTakingDamage",{ self, self.OnTakingDamage })
    self.VehicleViewModel:K2_RemoveFieldValueChangedDelegateSimple("bLowFuelValue",{ self, self.OnBeLowFuel })
    self.VehicleViewModel:K2_RemoveFieldValueChangedDelegateSimple("IPCSpark",{ self, self.OnIPCSpark })

    self.VehicleViewModel.OnVehicleAttachDetachDeleage:Remove(self,self.RefreshVehicleSeat)

end

function VehicleStatus:OnBeLowFuel(vm, fieldID)
    if not vm then return end
    if vm.bLowFuelValue then
        self.FuelBar:SetFillColorAndOpacity(self.LowFuelColor)
    else
        self.FuelBar:SetFillColorAndOpacity(self.NormalFuelColor)
    end
end

function VehicleStatus:UpdateSpeed(vm, fieldID)
    if not vm then return end
    print("(Wzp)VehicleStatus:UpdateSpeed [vm.Speed]=",vm.Speed)
    self.GUITextBlock:SetText(vm.Speed)
end

function VehicleStatus:UpdateHealth(vm, fieldID)
    if not vm then return end
    self.HealthBar:SetPercent(vm.HealthValue*1.0 / vm.MaxHealth*1.0)
end
function VehicleStatus:UpdateFuel(vm, fieldID)
    if not vm then return end
    local FuelPercent = vm.FuelValue*1.0 / vm.MaxFuel*1.0
    self.FuelBar:SetPercent(FuelPercent)
    self:BPFunc_RefreshSparkEffectPosition(FuelPercent)
    --self:VXE_GetOffVehicle_Spark_In()

end
function VehicleStatus:RefreshVehicleSeat(Actor, GameplayTag)
    -- 蓝图老逻辑 这里不改了
    self:UpdateSeat() 
end
function VehicleStatus:OnTakingDamage(vm, fieldID)
    if not vm then return end
    if vm.bIsTakingDamage then
        self:VXE_GetOffVehicle_Hp_In()
    end
end

function VehicleStatus:OnIPCSpark(vm, fieldID)
    if not vm then return end
    if vm.IPCSpark then
        self:VXE_GetOffVehicle_Spark_In()
    else
        self:VXE_GetOffVehicle_Spark_Out()
    end
end

function VehicleStatus:OnNearDead(vm, fieldID)
    if not vm then return end
    if vm.bIsNearDead  then
        self:VXE_GetOffVehicle_Hp_Loop()
    else
        self:VXE_GetOffVehicle_HP_Stop()
    end
end
return VehicleStatus
