--MatchConfigUS.xlsx
Cfg_MatchConfigUS = "MatchConfigUS"
G_CfgName2MainKey = G_CfgName2MainKey or {}
G_CfgName2MainKey[Cfg_MatchConfigUS] = "MatchModeId"
Cfg_MatchConfigUS_P_MainKey = "MatchModeId"
Cfg_MatchConfigUS_P = {
    MatchModeId = "MatchModeId",
    PlayModeId = "PlayModeId",
    LevelId = "LevelId",
    TeamType = "TeamType",
    Perspective = "Perspective",
}

local Cfg_MatchConfigUS_Custom = {
    Path = "/MatchConfig/MatchConfigUS/",
}
G_CfgName2Custom = G_CfgName2Custom or {}
G_CfgName2Custom[Cfg_MatchConfigUS] = Cfg_MatchConfigUS_Custom