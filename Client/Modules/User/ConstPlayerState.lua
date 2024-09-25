---
--- Description: 客户端所需要的玩家状态信息
--- Created At: 2023/04/07 16:48
--- Created By: 朝文
---

---逻辑状态，后台控制
---参考：Pb_Enum_PLAYER_STATE

---逻辑状态枚举值到逻辑状态字符串的映射，这里为了配合PlayerStateDisplayCfg使用
local Enum_PLAYER_LOGIC_STATE_STR = {
    [Pb_Enum_PLAYER_STATE.PLAYER_OFFLINE] = Cfg_PlayerStateDisplayCfg_P.PLAYER_OFFLINE,
    [Pb_Enum_PLAYER_STATE.PLAYER_LOGIN]   = Cfg_PlayerStateDisplayCfg_P.PLAYER_LOGIN,--"PLAYER_LOGIN",
    [Pb_Enum_PLAYER_STATE.PLAYER_LOBBY]   = Cfg_PlayerStateDisplayCfg_P.PLAYER_LOBBY,--"PLAYER_LOBBY",
    [Pb_Enum_PLAYER_STATE.PLAYER_TEAM]    = Cfg_PlayerStateDisplayCfg_P.PLAYER_TEAM,--"PLAYER_TEAM",
    [Pb_Enum_PLAYER_STATE.PLAYER_CUSTOMROOM]  = Cfg_PlayerStateDisplayCfg_P.PLAYER_CUSTOMROOM,--"PLAYER_CUSTOMROOM",
    [Pb_Enum_PLAYER_STATE.PLAYER_MATCH]   = Cfg_PlayerStateDisplayCfg_P.PLAYER_MATCH,--"PLAYER_MATCH",
    [Pb_Enum_PLAYER_STATE.PLAYER_BATTLE]  = Cfg_PlayerStateDisplayCfg_P.PLAYER_BATTLE,--"PLAYER_BATTLE",
    [Pb_Enum_PLAYER_STATE.PLAYER_SETTLE]  = Cfg_PlayerStateDisplayCfg_P.PLAYER_SETTLE,--"PLAYER_SETTLE", 
}

---客户端发送告诉后台玩家当前的状态，属于显示状态
---这里使用枚举方便跳转与避免硬编码
---修改这里需要同步新增/删除/修改 PlayerStateDisplay.xlsx 中对应的 key 的值
local Enum_PLAYER_CLIENT_HALL_STATE = {
    Hall            = "Hall",            -- 大厅空闲
    HallSettlement  = "HallSettlement",  -- 大厅结算
    HallHero        = "HallHero",        -- 大厅英雄
    HallWeapon      = "HallWeapon",      -- 大厅武器
    HallShop        = "HallShop",        -- 大厅商店
    HallSeason        = "HallSeason",        -- 赛季
    HallFavor        = "HallFavor",        -- 好感度
}

---如果打开某个界面需要同步状态给服务器，那么就需要在底下表格中进行配置
---例如当用户A打开英雄界面的时候，其他玩家需要知道玩家A正在浏览英雄界面，则需要用户A玩家告诉服务器他正在浏览英雄界面，其他玩家在询问服务器时，才能返回正确的结果
---为了实现这一点，在用户A打开界面的时候，UserCtl 会监听 UI 打开事件，如果对应的 UI 的 ViewConstId 在下面表里有配置，则会发送对应的字符串给后台
---这么一来就实现了上述逻辑，并只需要维护较少的代码，也更容易扩展
local ViewId2State = {
    --下方的因为框架改动，已经废弃，不过可以作为参考，后续使用ViewConst打开的界面的话可以参考下方的来书写
    --[ViewConst.Hall]            = Enum_PLAYER_CLIENT_HALL_STATE.Hall,           -- 大厅空闲
    --[ViewConst.Hero]            = Enum_PLAYER_CLIENT_HALL_STATE.HallHero,       -- 大厅英雄
    --[ViewConst.Arsenal]          = Enum_PLAYER_CLIENT_HALL_STATE.HallArsenal,     -- 大厅武器
    
    --ViewConst 中的id           id对应的界面字符串，此字符串需要使用 Enum_PLAYER_CLIENT_HALL_STATE 宏来定义
    [ViewConst.HallSettlement]  = Enum_PLAYER_CLIENT_HALL_STATE.HallSettlement, -- 大厅结算
}

---@class ConstPlayerState 
local ConstPlayerState = {
    PlayerStateDataOutOfDate = -1,                                  --数据过期唯一标识
    REQUEST_DELAY = 0.2,                                            --当收到发送请求的时候，不会立马请求，会延迟一定时间，等待看一下其他模块是否有相同的需求
    MAX_REQUIRE_TIME_GAP = 1,                                       --两次请求的间隔最小为1秒
    MAX_REQUIRE_LIST_SIZE = 50,                                     --使用接口的时候每次最大请求数量
    OUT_OF_DATE_TIME_OFFSET = 1,                                    --表明状态过期时间，如果为1的话，则说明如果当前时间与之前取得的玩家状态时间间隔超过1秒，则判断这个数据已经过期了，需要更新
    DEFAULT_KEY = "DefaultState",
    VIEW_ID_2_PLAYER_CLIENT_HALL_STATE_MAP = ViewId2State,          --ViewId到界面string的映射，用于在打开界面时候同步客户端大厅状态给后台
    
    UPDATE_CLIENT_HALL_STATE_GAP = 1,                               --客户端更新玩家大厅状态限频

    Enum_PLAYER_LOGIC_STATE_STR = Enum_PLAYER_LOGIC_STATE_STR,      --用于把后台的number类型的显示状态转换为string，方便表格读取
    Enum_PLAYER_CLIENT_HALL_STATE = Enum_PLAYER_CLIENT_HALL_STATE,  --客户端状态
}

return ConstPlayerState