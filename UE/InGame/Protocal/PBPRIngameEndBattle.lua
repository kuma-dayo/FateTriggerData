require "InGame.Protocal.LobbyProtocalHelper"

local PBPRIngameEndBattle = Class()

function PBPRIngameEndBattle.SendProtocalImpl(InPlayerState, InProtocalName, InProtocalJson)
    local TempGameId = LobbyProtocalHelper.GetGameId(UE.UGameplayStatics.GetGameState(InPlayerState))
    local TempPlayerId = LobbyProtocalHelper.GetPlayerId(InPlayerState)

    print("yyp UpdateProtocalInfo TempGameId = ", TempGameId)
    print("yyp UpdateProtocalInfo TempPlayerId = ", TempPlayerId)

    local ProtocalMsgBody = {
        GameId = TempGameId,
        PlayerId = TempPlayerId,
        EventName = InProtocalName,
        JsonContext = InProtocalJson
    }

    if ProtocalMsgBody then
        -- ReportCall(true, ProtocalMsgBody)
    end
end

_G.PBPRIngameEndBattle = PBPRIngameEndBattle

return PBPRIngameEndBattle