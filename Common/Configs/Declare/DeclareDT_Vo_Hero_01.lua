--Hero01_Voice.xlsx
Cfg_DT_Vo_Hero_01 = "DT_Vo_Hero_01"
G_CfgName2MainKey = G_CfgName2MainKey or {}
G_CfgName2MainKey[Cfg_DT_Vo_Hero_01] = "SoundID"
Cfg_DT_Vo_Hero_01_P_MainKey = "SoundID"
Cfg_DT_Vo_Hero_01_P = {
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

local Cfg_DT_Vo_Hero_01_Custom = {
    DTName = "DT_Vo_Hero_01",
    Path = "/HeroVo/Hero_01/",
}
G_CfgName2Custom = G_CfgName2Custom or {}
G_CfgName2Custom[Cfg_DT_Vo_Hero_01] = Cfg_DT_Vo_Hero_01_Custom