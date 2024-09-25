--[[
    好感度常量定义
]]

FavorabilityConst = 
{

}


-- 剧情状态
FavorabilityConst.STORY_STATUS = {
    LOCK = 1,
    NORMAL = 2,
    COMPLETED = 3
}

-- 剧情类型
FavorabilityConst.STORY_TYPE = {
    TASK = 1, -- 任务
    STORY = 2, -- 剧情
}

-- 剧情解锁条件
FavorabilityConst.STORY_UNLOCK_TYPE = {
    LEVEL = 1, -- 灵感度等级
    PART = 2, -- 段落
    TASK = 3, -- 任务
}