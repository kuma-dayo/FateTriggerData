--
--
--
-- @COMPANY	ByteDance
-- @AUTHOR	子羽
-- @DATE	
--

require("Common.Framework.CommFuncs")

local PickSystemHelper = _G.PickSystemHelper or {}

-------------------------------------------- Config/Enum ------------------------------------



-------------------------------------------- Common ------------------------------------

function PickSystemHelper.GetRespawnObjectByPlayerId(WorldContext, InPlayerId)
    if not WorldContext then
        return nil
    end
    
    local Tag = UE.FGameplayTag()
    Tag.TagName = "GameplayAbility.GMS_GS.Respawn.Rule.GeneEx"
    local ResapwnObj = UE.URespawnSubsystem.Get(WorldContext):GetGUVRespawnStateById(Tag,InPlayerId)
    return ResapwnObj
end

function PickSystemHelper.GetRespawnObjectByPlayerState(InPlayerState)
    if not InPlayerState then
        return nil
    end
    local Tag = UE.FGameplayTag()
    Tag.TagName = "GameplayAbility.GMS_GS.Respawn.Rule.GeneEx"
    local ResapwnObj = UE.URespawnSubsystem.Get(InPlayerState):GetGUVRespawnStateById(Tag,InPlayerState.PlayerId)
    return ResapwnObj
end

function PickSystemHelper.GetRespawnGeneState(InRespawnObj)
    if not InRespawnObj then
        return 0
    end
    return InRespawnObj.GeneExState
end

function PickSystemHelper.GetPlayerDeadTimeSec(InRespawnObj)
    if not InRespawnObj then
        return 0
    end
    return InRespawnObj.PlayerDeadTimeSec
end

function PickSystemHelper.GetGeneDurationTimeFromDead(InRespawnObj)
    if not InRespawnObj then
        return 0
    end
    return InRespawnObj.GeneLifespanInSec
end


----跳伞复活一些函数，主要没啥地方放了，基因也是放这里--------
--GameplayAbility.GMS_GS.Respawn.Rule.ParachuteRespawn  ----跳伞复活
--GameplayAbility.GMS_GS.Respawn.Rule.GeneEx   ---基因复活

function PickSystemHelper.GetRespawnObjectByPlayerStateAndTag(InPlayerState,InTagName)
    if not InPlayerState then
        return nil
    end
    local Tag = UE.FGameplayTag()
    --Tag.TagName = "GameplayAbility.GMS_GS.Respawn.Rule.ParachuteRespawn"
    Tag.TagName = InTagName
    local ResapwnObj = UE.URespawnSubsystem.Get(InPlayerState):GetGUVRespawnStateById(Tag,InPlayerState.PlayerId)
    return ResapwnObj
end


function  PickSystemHelper.GetRuleActiveTimeSec(InRespawnObj)
    if not InRespawnObj then
        return 0
    end
    return InRespawnObj.RuleActiveTimeSec
end

function  PickSystemHelper.GetbParachuteRespawnStart(InRespawnObj)
    if not InRespawnObj then
        return 0
    end
    return InRespawnObj.bParachuteRespawnStart
end

function  PickSystemHelper.GetbParachuteRespawnFinished(InRespawnObj)
    if not InRespawnObj then
        return 0
    end
    return InRespawnObj.bParachuteRespawnFinished
end

--读取跳伞时长配置
function  PickSystemHelper.GetParachuteRespawnAvailableTime(InPlayerState)
    if not InPlayerState then
        return nil
    end
    return UE.URespawnSubsystem.Get(InPlayerState):GetRespawnSubsystemConfig().ParachuteRespawnAvailableTime
end

--读取跳伞 每次玩家死亡，会等待该时长然后判断是否给予跳伞符合Creator技能
function  PickSystemHelper.GetParachuteRespawnIntervalTime(InPlayerState)
    if not InPlayerState then
        return nil
    end
    return UE.URespawnSubsystem.Get(InPlayerState):GetRespawnSubsystemConfig().ParachuteRespawnIntervalTime
end

--读取复活CD配置
function  PickSystemHelper.GetParachuteRespawnCDTime(InPlayerState)
    if not InPlayerState then
        return nil
    end
    return UE.URespawnSubsystem.Get(InPlayerState):GetRespawnSubsystemConfig().ParachuteRespawnCDTime
end
----------------------------------------------------------------------------------------改造GA

function PickSystemHelper.GetCurrentPickObj(InCharacter)
    if not InCharacter then
        return nil
    end
    
    local PickupGA = UE.UPickupStatics.GetPickupAbility(InCharacter)
    if not PickupGA then
        return nil
    end
    return PickupGA.LastPickObj
end

function PickSystemHelper.GetReadyPickObj(InCharacter)
    if not InCharacter then
        return nil
    end
    local PickupGA = UE.UPickupStatics.GetPickupAbility(InCharacter)
    if not PickupGA then
        return nil
    end
    return PickupGA.ReadyPickObj
end

function PickSystemHelper.SetReadyPickObj(InCharacter, InValue)
    if not InCharacter then
        return
    end
    
    local PickupGA = UE.UPickupStatics.GetPickupAbility(InCharacter)
    if PickupGA then
        PickupGA.ReadyPickObj = InValue
    end
end

function PickSystemHelper.GetCurrentPickObjNearby(InCharacter)
    if not InCharacter then
        return nil
    end
    
    local PickupGA = UE.UPickupStatics.GetPickupAbility(InCharacter)
    if not PickupGA then
        return nil
    end
    return PickupGA.CurrentPickObjNearby
end

function PickSystemHelper.GetGenerateValuesFromReadyToPickMap(InCharacter)
    if not InCharacter then
        return nil
    end
    local PickupSetting = UE.UPickupManager.GetGPSSeting(InCharacter)
    if not PickupSetting then
        return nil
    end
    local Ret = nil
    
    local PickupGA = UE.UPickupStatics.GetPickupAbility(InCharacter)
    if PickupGA then
        Ret = PickupGA:GenerateValuesFromReadyToPickMap()
    end
    return Ret
end

function PickSystemHelper.GetLastReadyToPickObjArray(InCharacter)
    if not InCharacter then
        return nil
    end

    local PickupGA = UE.UPickupStatics.GetPickupAbility(InCharacter)
    if PickupGA then
        return PickupGA:GetLastReadyToPickObjArray()
    end
    return nil
end

function PickSystemHelper.SetSimpleListDataArray(InCharacter, InValue)
    if not InCharacter then
        return
    end
    local PickupGA = UE.UPickupStatics.GetPickupAbility(InCharacter)
    if PickupGA then
        PickupGA:SetSimpleListDataArray(InValue)
    end
end

-------------------------------------------- Debug ------------------------------------


-- 
_G.PickSystemHelper = PickSystemHelper
return PickSystemHelper
