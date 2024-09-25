--Hero06_Voice.xlsx
Cfg_DT_Vo_Hero_06 = "DT_Vo_Hero_06"
G_CfgName2MainKey = G_CfgName2MainKey or {}
G_CfgName2MainKey[Cfg_DT_Vo_Hero_06] = "SoundID"
Cfg_DT_Vo_Hero_06_P_MainKey = "SoundID"
Cfg_DT_Vo_Hero_06_P = {
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
    TeamCD = "TeamCD",
    DelayTime = "DelayTime",
    ExpireTime = "ExpireTime",
}

local Cfg_DT_Vo_Hero_06_Custom = {
    DTName = "DT_Vo_Hero_06",
    Path = "/HeroVo/Hero_06/",
}
G_CfgName2Custom = G_CfgName2Custom or {}
G_CfgName2Custom[Cfg_DT_Vo_Hero_06] = Cfg_DT_Vo_Hero_06_Custom