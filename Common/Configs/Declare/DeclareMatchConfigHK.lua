--MatchConfigHK.xlsx
Cfg_MatchConfigHK = "MatchConfigHK"
G_CfgName2MainKey = G_CfgName2MainKey or {}
G_CfgName2MainKey[Cfg_MatchConfigHK] = "MatchModeId"
Cfg_MatchConfigHK_P_MainKey = "MatchModeId"
Cfg_MatchConfigHK_P = {
    MatchModeId = "MatchModeId",
    PlayModeId = "PlayModeId",
    LevelId = "LevelId",
    TeamType = "TeamType",
    Perspective = "Perspective",
}

local Cfg_MatchConfigHK_Custom = {
    Path = "/MatchConfig/MatchConfigHK/",
}
G_CfgName2Custom = G_CfgName2Custom or {}
G_CfgName2Custom[Cfg_MatchConfigHK] = Cfg_MatchConfigHK_Custom