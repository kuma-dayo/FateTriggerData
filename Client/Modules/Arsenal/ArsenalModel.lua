--[[
    局外战备数据模型
]]
require("Client.Modules.Arsenal.Weapon.WeaponModel")
require("Client.Modules.Arsenal.Vehicle.VehicleModel")


local super = GameEventDispatcher;
local class_name = "ArsenalModel";
ArsenalModel = BaseClass(super, class_name);


function ArsenalModel:__init()
    self:_dataInit()
end

function ArsenalModel:_dataInit()
end

--[[
    玩家登出
]]
function ArsenalModel:OnLogout(data)
    CWaring("ArsenalModel OnLogout")
    self:_dataInit()
end


function ArsenalModel:GetArsenalText(RowKey)
    return G_ConfigHelper:GetStrFromOutgameStaticST("SD_Arsenal", tostring(RowKey))
end


--切换后处理
function ArsenalModel:SwitchPostProcessVolume(TagIndex)
    local PPTags = {
        [1] = "PP_HallArsenal",
        [2] = "PP_HoverPart",
        [3] = "PP_PickPart",
        [4] = "PP_PickWeapon",
    }
    local World = UE.UKismetSystemLibrary.GetWorld(_G.GameInstance)
    local PostProcessVolumes = UE.TArray(UE.APostProcessVolume)
    UE.UGameplayStatics.GetAllActorsOfClass(World, UE.APostProcessVolume, PostProcessVolumes)
    for i=1, PostProcessVolumes:Num() do
        local PostProcessVolume = PostProcessVolumes:Get(i)
        if PostProcessVolume:ActorHasTag(PPTags[TagIndex]) then
            PostProcessVolume.bEnabled = true
        elseif PostProcessVolume:ActorHasTag(PPTags[1])
            or PostProcessVolume:ActorHasTag(PPTags[2])
            or PostProcessVolume:ActorHasTag(PPTags[3])
            or PostProcessVolume:ActorHasTag(PPTags[4]) then
            PostProcessVolume.bEnabled = false
        end
    end
end

--[[
   获取后处理动态材质
]]
function ArsenalModel:GetPostProcessVolumeDymicMaterial(TagIndex)
    local PPTags = {
        [1] = "PP_HallArsenal",
        [2] = "PP_HoverPart",
        [3] = "PP_PickPart",
        [4] = "PP_PickWeapon",
    }
    local World = UE.UKismetSystemLibrary.GetWorld(_G.GameInstance)
    local PostProcessVolumes = UE.TArray(UE.APostProcessVolume)
    local TagPostProcessVolume = PPTags[TagIndex] or ""
    UE.UGameplayStatics.GetAllActorsOfClassWithTag(World, UE.APostProcessVolume, TagPostProcessVolume, PostProcessVolumes)
    if PostProcessVolumes:Num() == 0 then
        return
    end
    local  TheUsedPostProcessVolume = PostProcessVolumes:Get(1)
    if TheUsedPostProcessVolume == nil then
        return
    end
    if TheUsedPostProcessVolume.Settings.WeightedBlendables.Array:Num() == 0 then
        return
    end
    local WeightedBlendable = TheUsedPostProcessVolume.Settings.WeightedBlendables.Array:Get(1)
    if WeightedBlendable == nil or WeightedBlendable.Object == nil then
        return
    end

    local DynamicMI = WeightedBlendable.Object:Cast(UE.UMaterialInstanceDynamic)
    if DynamicMI ~= nil then        
        return DynamicMI
    end

    local MaterialInst = WeightedBlendable.Object:Cast(UE.UMaterialInstance)
    if MaterialInst ~= nil then
        DynamicMI = UE.UKismetMaterialLibrary.CreateDynamicMaterialInstance(World, MaterialInst)
        if DynamicMI ~= nil then
            DynamicMI:CopyParameterOverrides(MaterialInst)

            TheUsedPostProcessVolume.Settings.WeightedBlendables.Array:Clear()
            local NewWeightedBlendable = UE.FWeightedBlendable()
            NewWeightedBlendable.Weight = 1.0
            NewWeightedBlendable.Object = DynamicMI
            TheUsedPostProcessVolume.Settings.WeightedBlendables.Array:Add(NewWeightedBlendable)
            return DynamicMI
        end
    end
end

function ArsenalModel:ChangePostProcessVolumeMaterialParam(TagIndex, Param)
    if Param == nil then
        return
    end
    local DynamicMI = self:GetPostProcessVolumeDymicMaterial(TagIndex) 
    if DynamicMI == nil then
        return
    end
    --描边
    if Param.StencilOutlineWidth then
        DynamicMI:SetScalarParameterValue("StencilOutlineWidth", Param.StencilOutlineWidth)    
    end
    if Param.OutlineColor then 
        DynamicMI:SetVectorParameterValue("OutlineColor", Param.OutlineColor) 
    end
    if Param.StencilOutlineWidth then
        DynamicMI:SetScalarParameterValue("StencilOutlineWidth", Param.StencilOutlineWidth)
    end
    --全息参数
    if Param.HologramMoveColor then
        DynamicMI:SetScalarParameterValue("HologramMoveColor", Param.HologramMoveColor)
    end
    if Param.HologramRadius then
        DynamicMI:SetScalarParameterValue("HologramRadius", Param.HologramRadius)
    end
    if Param.HologramSpeed then
        DynamicMI:SetScalarParameterValue("HologramSpeed", Param.HologramSpeed)
    end
    if Param.HologramStaticColor then
        DynamicMI:SetScalarParameterValue("HologramStaticColor", Param.HologramStaticColor)
    end
    if Param.Radius then
        DynamicMI:SetScalarParameterValue("Radius", Param.Radius)
    end
    if Param.Tilling then
        DynamicMI:SetScalarParameterValue("Tilling", Param.Tilling)
    end
    
    --其他
    if Param.OtlnOverIndex then
        DynamicMI:SetScalarParameterValue("OtlnOver"..Param.OtlnOverIndex, Param.OtlnOverValue)
    end

    if Param.GlobalOpacity then
        DynamicMI:SetScalarParameterValue("GlobalOpacity", Param.GlobalOpacity)
    end
end



return ArsenalModel