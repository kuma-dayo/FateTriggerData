--HeroTemp_Voice.xlsx
Cfg_DT_Vo_Hero_Temp = "DT_Vo_Hero_Temp"
G_CfgName2MainKey = G_CfgName2MainKey or {}
G_CfgName2MainKey[Cfg_DT_Vo_Hero_Temp] = "SoundID"
Cfg_DT_Vo_Hero_Temp_P_MainKey = "SoundID"
Cfg_DT_Vo_Hero_Temp_P = {
    SoundID = "SoundID",
    GroupID = "GroupID",
    EventID = "EventID",
    SoundEvent = "SoundEvent",
    CD = "CD",
    RandomWeight = "RandomWeight",
    ListenerRoleArray = "ListenerRoleArray",
    PrioritySelf = "PrioritySelf",
    PriorityTeam = "PriorityTeam",
    BreakStrategy = "BreakStrategy",
    ClearStrategy = "ClearStrategy",
    MixStrategy = "MixStrategy",
}

local Cfg_DT_Vo_Hero_Temp_Custom = {
    DTName = "DT_Vo_Hero_Temp",
    Path = "/HeroVo/Hero_Temp/",
}
G_CfgName2Custom = G_CfgName2Custom or {}
G_CfgName2Custom[Cfg_DT_Vo_Hero_Temp] = Cfg_DT_Vo_Hero_Temp_Custom