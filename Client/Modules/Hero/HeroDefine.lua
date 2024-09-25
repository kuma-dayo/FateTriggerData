---@class HeroDefine
HeroDefine = {}


-- ---英雄展示面板类型枚举
-- HeroDefine.DisplayBoardTypeEnum = {
--     --底板
--     Floor = 1,
--     --英雄
--     Role = 2,
--     --特效
--     Effect = 3,
--     --贴纸
--     Sticker = 4,
--     --成就
--     Achieve = 5,
-- }

HeroDefine.SLOT_NUM = 3

HeroDefine.STICKER_SLOT_NUM = 3

HeroDefine.STICKER_SIZE_MAX = 2
HeroDefine.STICKER_SIZE_MIN = 0.5


---英雄展示面板物品状态枚举
HeroDefine.EDisplayBoardItemState = {
    --锁住的,未解锁,未拥有
    Lock = 0,
    --已经拥有,可以被装备的状态
    Owned = 1,
    --已经被当前英雄装备
    EquippedByCur = 3,
    --已经被其它英雄装备
    EquippedByOther = 4,
}