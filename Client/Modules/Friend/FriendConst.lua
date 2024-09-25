--[[
    好友的常量定义
]]
FriendConst = 
{

}

-- 主界面弹出消息 持续时间
FriendConst.NOTICE_DURATION = 5
-- 主界面弹出提示 持续时间
FriendConst.NOTICE_TIPS_DURATION = 3

-- 好友在线状态
FriendConst.PLAYER_STATE_ENUM = {
    --离线
    PLAYER_OFFLINE = 0,
    -- 在线 单人
    PLAYER_SINGLE = 1,
    -- 在线 队伍中
    PLAYER_INTEAM = 2,
    -- 在线 匹配中
    PLAYER_MATCHING = 3,
    -- 在线 游戏中
    PLAYER_GAMING = 4,
    -- 在线 自建房中
    PLAYER_CUSTOMROOM = 5,
}

-- 好友列表类型
FriendConst.LIST_TYPE_ENUM = {
    -- 空
    EMPTY = 0,
    --好友
    FRIEND = 1,
    --申请入队Item
    TEAM_REQUEST = 2,
    --邀请入队Item
    TEAM_INVITE_REQUEST = 3,
    --申请合并队伍item
    TEAM_MERGE_REQUEST = 4, 
    --好友申请Item
    FRIEND_REQUEST = 5,
    --组队推荐列表item
    TEAM_RECOMMEND = 6,
    --组队推荐 换一批
    TEAM_RECOMMEND_CHANGE_LIST = 7,
    --组队推荐-子项
    TEAM_RECOMMEND_INNER = 8,
}

-- 好友列表排序类型
FriendConst.LIST_SORT_TYPE = {
   DEFAULT = 1,  -- 默认排序
   INTIMACY = 2,  -- 亲密度降序
   FIRSTWORD = 3,  -- 首字母降序
}
-- 好友列表筛选类型
FriendConst.LIST_FILTER_TYPE = {
   ALL = 1,  -- 全部
   ONLINE = 2,  -- 最近在线
   PLAY_TOGETHER = 3,  -- 最近组队
}

-- 队伍最大人数
FriendConst.MAX_TEAM_MEMBER_COUNT = 4

-- 队伍提示类型
FriendConst.TEAM_SHOW_TIPS_TYPE = {
    ADD = 1,   -- 加入 
    EXIT = 2,   -- 退出
    REJECT_INVITE = 3, -- 拒绝邀请
    REJECT_APPLY = 4, -- 拒绝申请
    ADD_FRIEND = 5, -- 添加好友
}

-- 出入队通知Item类型
FriendConst.TEAM_NOTICE_ITEM_TYPE = {
    SINGLE = 0,
    MULTI = 1,
}

-- 出入队通知类型
FriendConst.TEAM_STATUS_SYNC_TYPE = {
    NONE = 0,
    QUIT = 1,
    JOIN = 2
}


return FriendConst