--
-- 局内文本配置
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.11
--

---@class InGameTextConfig_C
local __default_values = 
{
}

local data = 
{
    ["Common_Year"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_year") },
    ["Common_Month"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_moon") },
    ["Common_Day"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_sun") },
    ["Common_Hours"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_time") },
    ["Common_Minutes"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_minute") },
    ["Common_Seconds"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_second") },
    
    ["RomanNum_1"] = { Text = "I", },
    ["RomanNum_2"] = { Text = "II", },
    ["RomanNum_3"] = { Text = "III", },
    ["RomanNum_4"] = { Text = "IV", },
    ["RomanNum_5"] = { Text = "V", },
    ["RomanNum_6"] = { Text = "VI", },
    ["RomanNum_7"] = { Text = "VII", },
    ["RomanNum_8"] = { Text = "VIII", },
    ["RomanNum_9"] = { Text = "IX", },
    ["RomanNum_10"] = { Text = "X", },

    ["Minimap_MarkRouteNumLimit"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Selectatmostdpoints"), },
    ["Minimap_MarkRouteDistLimit"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Theselectionpointdis"), },
    ["Minimap_EnterPlayzone"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Hasenteredthecircle"), },
    ["Minimap_EnergyInStorage"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Etherenergyisaboutto"), },
    ["Minimap_EnergyInProliferation"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Etherenergyispulling"), },

    ["MarkSystem_TraceFail"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Theaimingdistanceoft"), },
    ["MarkSystem_CancelMark"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Unmark"), },
    ["MarkSystem_CanBooker"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_schedule"), },
    ["MarkSystem_CancelBooker"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_cancelanappointment"), },
    ["MarkSystem_AlreadyBooker"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Reservedbys"), },
    
    ["SystemTips_WarnEnterPlayzone"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Pleasegotothesafeare"), },
    ["RescueTips_DoRescue"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Intherescue"), },
    
    ["Ruler_DirTxt1"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_north"), },
    ["Ruler_DirTxt2"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_northeast"), },
    ["Ruler_DirTxt3"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_east"), },
    ["Ruler_DirTxt4"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_southeast"), },
    ["Ruler_DirTxt5"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_south"), },
    ["Ruler_DirTxt6"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_southwest"), },
    ["Ruler_DirTxt7"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_west"), },
    ["Ruler_DirTxt8"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_northwest"), },

    ["GameState_WarmingUp"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Theshipisabouttosail"), },
    ["GameState_InProgress"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Gamestart"), },
    ["GameState_GameOver"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_gameover"), },
    ["GameState_GameVictory"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_TheChosenOne"), },
    ["GameState_GameDefeated"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_gameover"), },
    
    ["Settlement_ReturnLobby"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Exitds"), },
    ["Settlement_RawReturnLobby"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Returntothehall"), },
    ["Settlement_Ranking"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Numberd"), },

    ["PlayerRanking"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Personalranking"), },
    ["PlayerKill"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Individualkilling"), },
    ["PlayerTeamKill"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_Teamkill"), },
    
    ["RingActor_Name"] = { Text = G_ConfigHelper:GetStrFromCommonStaticST("Lua_InGameTextConfig_saferegion"), },

}

do
    local base = {
        __index = __default_values,
        __newindex = function(t, k, v)
            Error("InGameTextConfig_C_C", ">> Attempt to modify not exist key!", tostring(k), "\n".. debug.traceback())
        end
    }

    for k, v in pairs(data) do
        if type(v) == "table" then
            setmetatable(v, base)
        end
    end

    base.__metatable = false
end

return data
