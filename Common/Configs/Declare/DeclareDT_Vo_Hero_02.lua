--Hero02_Voice.xlsx
Cfg_DT_Vo_Hero_02 = "DT_Vo_Hero_02"
G_CfgName2MainKey = G_CfgName2MainKey or {}
G_CfgName2MainKey[Cfg_DT_Vo_Hero_02] = "SoundID"
Cfg_DT_Vo_Hero_02_P_MainKey = "SoundID"
Cfg_DT_Vo_Hero_02_P = {
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

local Cfg_DT_Vo_Hero_02_Custom = {
    DTName = "DT_Vo_Hero_02",
    Path = "/HeroVo/Hero_02/",
}
G_CfgName2Custom = G_CfgName2Custom or {}
G_CfgName2Custom[Cfg_DT_Vo_Hero_02] = Cfg_DT_Vo_Hero_02_Custom