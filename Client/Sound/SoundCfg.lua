---@class SoundCfg
SoundCfg = {}

--背景音乐
SoundCfg.Music = {
    
    MUSIC_PAUSE = "AKE_Pause_BGM",
    MUSIC_RESUME = "AKE_Resume_BGM",
    
    MUSIC_LOGIN = "AKE_Play_BGM_Login",
    MUSIC_STOP_LOGIN = "AKE_Stop_BGM_Login",

    MUSIC_PLAY = "AKE_Play_BGM", --大厅音乐打开
    MUSIC_STOP = "AKE_Stop_BGM", --大厅音乐关闭

    MUSIC_HALL = "AKE_Play_BGM_Lobby",
    MUSIC_HERO = "AKE_Play_BGM_Hero",
    MUSIC_WEAPON = "AKE_Play_BGM_Combat_Readiness",
    MUSIC_SHOP = "AKE_Play_BGM_Shop",
    MUSIC_SEASON = "AKE_Play_BGM_Season",
    MUSIC_FAVORABILITY = "AKE_Play_BGM_Favorability",

    MUSIC_CG = "AKE_Play_BGM_CG", --登录CG打开
    MUSIC_STOP_CG = "AKE_Stop_BGM_CG", --登录CG关闭
}

--音效
SoundCfg.SoundEffects = {
    --匹配
    MATCH_START = "AKE_Play_UI_Match_Start_Button",                 --单人/队长点击匹配按钮
    MATCH_READY = "AKE_Play_UI_Match_Start_Button",                 --准备按钮点击
    MATCH_CANCEL = "AKE_Play_UI_Match_Cancel",                      --取消准备按钮点击
    MATCH_COMPLETE = "AKE_Play_UI_Match_Complete",                  --匹配成功
    MATCH_BTN_HOVER = "AKE_Play_UI_Highlight_Hover_04",             --匹配按钮Hover音效
    MATCH_SEARCHING_START = "AKE_Play_UI_Match_Search",             --匹配开始循环音效
    MATCH_SEARCHING_STOP = "AKE_Stop_UI_Match_Search",              --匹配结束循环音效
    
    --队伍
    TEAM_PARTNER_ENTER = "AKE_Play_UI_Match_Partner_Enter",         --玩家入队播放溶解ls时的音效
    TEAM_PARTNER_QUIT = "AKE_Play_UI_Match_Partner_Quit",           --玩家退队播放溶解ls时的音效
    
    --好友边框
    PATERNER_CALL = "AKE_Play_UI_Match_Partner_Call",
}

--语音
SoundCfg.Voice = {
    HALL_STOP_ALL = "AKE_Stop_Voice_All",
    HALL_STOP_EFFECT_ALL = "AKE_Stop_Effect_All",

    --大厅
    HALL_ENTER = "HallEnter",
    HALL_IDLE = "HallIdle",
    HALL_CLICK = "HallClick",
    
    --角色
    HERO_ENTER = "HallHeroEnter",
    HERO_NEW_HERO_IN = "HallHeroSwitch",
    
    --局外结算
    HALL_SETTLEMENT_FAVORITE_WIN_TOP50P = "HallSettlementFavorTop50p",
    HALL_SETTLEMENT_FAVORITE_WIN_NOT_TOP50P = "HallSettlementFavorNotTop50p",
    HALL_SETTLEMENT_NOT_FAVORITE_WIN_TOP50P = "HallSettlementNotFavorTop50p",
    HALL_SETTLEMENT_NOT_FAVORITE_WIN_NOT_TOP50P = "HallSettlementNotFavorNotTop50p",
    
    --组队
    TEAM_JOIN = "HallTeamJoin",

    --匹配
    MATCH_START = "HallMatchStart",

    --战斗返回大厅
    HALL_RETURN = "",

    -- 好感度
    FAVOR_LOW_LIKE  = "Favor_LowLike",   -- 低品级喜好物品反馈语音
    FAVOR_HIGH_LIKE  = "Favor_HighLike",   -- 高品级喜好物品反馈语音
    FAVOR_NOT_LIKE  = "Favor_NotLike",   -- 不喜好物品反馈语音
    FAVOR_LEVEL_UP  = "Favor_LevelUp",   -- 灵感等级提升反馈语音
    FAVOR_LEVEL_MAX  = "Favor_LevelMax",   -- 灵感等级满级反馈语音

}

return SoundCfg