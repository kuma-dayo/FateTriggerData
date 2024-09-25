require("Common.Framework.CommFuncs")

local RespawnSystemHelper = _G.RespawnSystemHelper or {}


function RespawnSystemHelper.GetRespawnGeneState(InPlayerState)
    if not InPlayerState then
        return -1
    end
    local RuleTag = UE.FGameplayTag()
    RuleTag.TagName = "GameplayAbility.GMS_PS.Respawn.BeRespawned.Gene"
    local BeRespawnedGA = UE.URespawnSubsystem.Get(InPlayerState):GetGUVBeRespawnedByPS_Client(RuleTag, InPlayerState)
    if not BeRespawnedGA then
        return -1
    end
    return BeRespawnedGA.GeneState
end

function RespawnSystemHelper.GetPlayerDeadTimeSec(InPlayerState)
    if not InPlayerState then
        return 0
    end
    local RuleTag = UE.FGameplayTag()
    RuleTag.TagName = "GameplayAbility.GMS_PS.Respawn.BeRespawned.Gene"
    local BeRespawnedGA = UE.URespawnSubsystem.Get(InPlayerState):GetGUVBeRespawnedByPS_Client(RuleTag, InPlayerState)
    if not BeRespawnedGA then
        return 0
    end
    return BeRespawnedGA.PlayerDeadTimeSec
end

function RespawnSystemHelper.GetGeneDurationTimeFromDead(InPlayerState)
    if not InPlayerState then
        return 0
    end
    local RuleTag = UE.FGameplayTag()
    RuleTag.TagName = "GameplayAbility.GMS_PS.Respawn.BeRespawned.Gene"
    local BeRespawnedGA = UE.URespawnSubsystem.Get(InPlayerState):GetGUVBeRespawnedByPS_Client(RuleTag, InPlayerState)
    if not BeRespawnedGA then
        return 0
    end
    return BeRespawnedGA.GeneLifespanInSec
end

function  RespawnSystemHelper.GetRuleActiveTimeSec(InWorldContext, InRuleTag)
    if not InRuleTag or not InWorldContext then
        return 0
    end
    local Rule = UE.URespawnSubsystem.Get(InWorldContext):GetGUVRespawnRule(InRuleTag)
    if not Rule then
        return 0
    end
    return Rule.RuleActiveTimeSec
end

function  RespawnSystemHelper.IsPlayerParachuteRespawnStart(InPlayerState)
    if not InPlayerState then
        return false
    end
    local RuleTag = UE.FGameplayTag()
    RuleTag.TagName = "GameplayAbility.GMS_GS.Respawn.Rule.Parachute"
    local ResapwnSubsystem = UE.URespawnSubsystem.Get(InPlayerState)
    if not ResapwnSubsystem then
        return false
    end
    local Rule = ResapwnSubsystem:GetGUVRespawnRule(RuleTag)
    if not Rule then
        return false
    end
    if not Rule.RespawningPlayer:Contains(InPlayerState.PlayerId) then
        return false
    end
    return true
end

--读取跳伞时长配置
function  RespawnSystemHelper.GetParachuteRespawnAvailableTime(InPlayerState)
    if not InPlayerState then
        return nil
    end
    local RuleTag = UE.FGameplayTag()
    RuleTag.TagName = "GameplayAbility.GMS_GS.Respawn.Rule.Parachute"
    local Rule = UE.URespawnSubsystem.Get(InPlayerState):GetGUVRespawnRule(RuleTag)
    if not Rule then
        return nil
    end
    for index = 1, Rule.AllSkillStates:Length() do
        local StateWrap = Rule.AllSkillStates:Get(index)
        if StateWrap and UE.UPickupStatics.IsFNameEqual(StateWrap.StateName, "InProgress") then
            return StateWrap.StateLength
        end
    end
    return nil
end

--读取复活CD配置
function  RespawnSystemHelper.GetParachuteRespawnCDTime(InPlayerState)
    if not InPlayerState then
        return -1
    end
    local RuleTag = UE.FGameplayTag()
    RuleTag.TagName = "GameplayAbility.GMS_GS.Respawn.Rule.Parachute"
    local AsRespawnerGA = UE.URespawnSubsystem.Get(InPlayerState):GetGUVBeRespawnedByPS_Client(RuleTag, InPlayerState)
    if not AsRespawnerGA then
        return -1
    end
    return AsRespawnerGA.ParachuteRespawnCDTime
end

--获取IsBeginRespawner变量，是否真的在跳伞复活中
function RespawnSystemHelper.CheckIsBeginRespawner(InPlayerState)
    if not InPlayerState then
        return false
    end
    local Tag = UE.FGameplayTag()
    Tag.TagName = "GameplayAbility.GMS_PS.Respawn.AsRespawner.Parachute"
    local ResapwnSubsystem = UE.URespawnSubsystem.Get(InPlayerState)
    if not ResapwnSubsystem then
        return false
    end
    local GUVObject_AsRespawner = ResapwnSubsystem:GetGUVAsRespawnerByPS_Client(Tag,InPlayerState)
    if not GUVObject_AsRespawner then
        return false
    end
   
    return GUVObject_AsRespawner.IsBeginRespawner
end

--
_G.RespawnSystemHelper = RespawnSystemHelper
return RespawnSystemHelper
