--MatchConfigCN.xlsx
Cfg_MatchConfigCN = "MatchConfigCN"
G_CfgName2MainKey = G_CfgName2MainKey or {}
G_CfgName2MainKey[Cfg_MatchConfigCN] = "MatchModeId"
Cfg_MatchConfigCN_P_MainKey = "MatchModeId"
Cfg_MatchConfigCN_P = {
    MatchModeId = "MatchModeId",
    PlayModeId = "PlayModeId",
    LevelId = "LevelId",
    TeamType = "TeamType",
    Perspective = "Perspective",
}

local Cfg_MatchConfigCN_Custom = {
    Path = "/MatchConfig/MatchConfigCN/",
}
G_CfgName2Custom = G_CfgName2Custom or {}
G_CfgName2Custom[Cfg_MatchConfigCN] = Cfg_MatchConfigCN_Custom