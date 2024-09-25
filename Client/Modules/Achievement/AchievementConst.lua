
--- AchievementConst
local class_name = "AchievementConst";
---@class AchievementConst
local AchievementConst = BaseClass(nil, class_name);

---拥有状态
AchievementConst.OWN_STATE = {
    None = 0, --
    Not = 1,  -- 未拥有
    Have = 2  -- 拥有
}

-- 1	英雄
-- 2	战斗
-- 3	财富
-- 4	勤奋
AchievementConst.GROUP_DEF = {
    None = 0,
    HERO = 1,
    BATTLE = 2,
    WEALTH = 3,
    DILIGENT = 4,
}

AchievementConst.PopShowWidgetUMGPath = "/Game/BluePrints/UMG/OutsideGame/Achievement/WBP_Achievement_Pop_Item.WBP_Achievement_Pop_Item"
return AchievementConst
