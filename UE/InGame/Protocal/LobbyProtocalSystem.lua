require "InGame.Protocal.PBPRIngameEndBattle"

local LobbyProtocalSystem = Class()

function LobbyProtocalSystem:SendProtocal(InPlayerState, InProtocalName, InProtocalJson)
    if InProtocalName == "game_end_battle_server" then
        --暂时注释，需要调试后
        --PBPRIngameEndBattle.SendProtocalImpl(InPlayerState, InProtocalName, InProtocalJson)
    end
end

return LobbyProtocalSystem