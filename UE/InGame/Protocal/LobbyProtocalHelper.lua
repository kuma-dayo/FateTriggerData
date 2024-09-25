
local LobbyProtocalHelper = Class()

-- 获取GameId（对局Id）。 InGameState 传入 AGeGameState
function LobbyProtocalHelper.GetGameId(InGeGameState)
    -- 如果当前的 AGameState 类型是 AGeGameState 则会有函数 AGeGameState::GetGameId()
    if InGeGameState and InGeGameState.GetGameId then
        return InGeGameState:GetGameId()
    end

    return nil
end

-- 获取PlayerId。 InPlayerState 传入 APlayerState
function LobbyProtocalHelper.GetPlayerId(InPlayerState)
    if InPlayerState and InPlayerState.GetPlayerId then
        return InPlayerState:GetPlayerId()
    end

    return nil
end

-- 判断是否AI。 InPlayerState 传入 APlayerState
function LobbyProtocalHelper.IsABot(InPlayerState)
    if InPlayerState and InPlayerState.IsABot then
        return InPlayerState:IsABot()
    end

    return false
end

-- 获取毒圈圈次
function LobbyProtocalHelper.GetRingIndex(InContext)
    local RingActor = UE.ARingActor.GetRingActorFromWorld(InContext)
    if RingActor then
        return RingActor:GetRingIndex()
    end
    return 0
end

-- 获取游戏模式Id。 InGameState 传入 AS1GameStateBase
function LobbyProtocalHelper.GetGameModeId(InS1GameStateBase)
    -- 如果当前的 AGameState 类型是 AS1GameStateBase 则会有成员变量 AS1GameStateBase::DSGameModeId 类型 int32
    if InS1GameStateBase and InS1GameStateBase.DSGameModeId then
        return InS1GameStateBase.DSGameModeId
    end

    return nil
end

-- 获取场景Id。 InGameState 传入 AS1GameStateBase
function LobbyProtocalHelper.GetSceneId(InS1GameStateBase)
    -- 如果当前的 AGameState 类型是 AS1GameStateBase 则会有函数 AS1GameStateBase::GetSceneId 类型 int32
    if InS1GameStateBase and InS1GameStateBase.GetSceneId then
        return InS1GameStateBase:GetSceneId()
    end
end

-- GetMatchId（先不用传递，等大厅区分 MatchId）
-- function LobbyProtocalHelper.GetMatchId(InGameState)
-- end

-- 获取英雄Id。 InPlayerState 传入 APlayerState
function LobbyProtocalHelper.GetHeroId(InPlayerState)
    local CurrentPlayerExSubsystem = UE.UPlayerExSubsystem.Get(InPlayerState)
    if CurrentPlayerExSubsystem then
        local CurrentPlayerExInfo = CurrentPlayerExSubsystem:GetPlayerExInfoByPlayerState(InPlayerState)
        if CurrentPlayerExInfo then
            return CurrentPlayerExInfo:GetHeroTypeId()
        end
    end

    return nil
end

_G.LobbyProtocalHelper = LobbyProtocalHelper
return LobbyProtocalHelper