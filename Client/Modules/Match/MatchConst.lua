-- local MatchConst = require("Client.Modules.Match.MatchConst")
local MatchConst = {
    Enum_MatchType = {
        Survive     = "Survive",    --大逃杀模式
        Conqure     = "Conqure",    --征服模式
        TeamMatch   = "TeamMatch",  --团队竞技模式
        DeathMatch  = "DeathMatch", --死斗模式
    },
    
    --视角
    Enum_View = {
        fpp = 1,    --第一人称
        tpp = 3,    --第三人称
    },    
    Enum_ViewStringToInt = {        --这一块外部不要调用，留给转表
        ["fpp"]   = 1,
        ["tpp"]   = 3,
    },
    Enum_ViewIntToString = {        --这一块外部谨慎调用
        [1]       = "fpp",
        [3]       = "tpp"
    },
    
    --队伍类型
    Enum_TeamType = {
        solo    = 1,    --单排
        duo     = 2,    --双排
        squad   = 4,    --四排
    },
    Enum_TeamTypeStringToInt = {    --这一块外部不要调用，留给转表
        ["solo"]  = 1,
        ["duo"]   = 2,
        ["squad"] = 4,
    },
    Enum_TeamTypeIntToString = {        --这一块外部谨慎调用
        [1]       = "solo",
        [2]       = "duo",
        [4]       = "squad"
    },
    
    --MatchAndDsStateSync中的MatchState枚举
    Enum_MatchAndDsStateSync_MatchState = {
        ["NOT_IN_MATCHING"] = 0,    --没有在匹配中
        ["MATCHING"]        = 1,    --匹配中
        ["MATCH_SUCCESS"]   = 2     --匹配成功
    }
    
}

return MatchConst