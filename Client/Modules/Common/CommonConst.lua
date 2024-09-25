--[[
    通用的常量定义
]]

CommonConst = 
{

}

--通用Tips的ID定义
CommonConst.CT_ESC = 2002
CommonConst.CT_ROTATE = 1001
CommonConst.CT_ZOOMINOUT = 1002
CommonConst.CT_LIKE = 2001
CommonConst.CT_BACK = 2002
CommonConst.CT_TAB = 2003
CommonConst.CT_ENTER = 2004
CommonConst.CT_SPACE = 2005
CommonConst.CT_LAlt = 2006
CommonConst.CT_BUY = 2007
CommonConst.CT_A = 3000
CommonConst.CT_B = 3001
CommonConst.CT_C = 3002
CommonConst.CT_D = 3003
CommonConst.CT_E = 3004
CommonConst.CT_F = 3005
CommonConst.CT_G = 3006
CommonConst.CT_H = 3007
CommonConst.CT_I = 3008
CommonConst.CT_J = 3009
CommonConst.CT_K = 3010
CommonConst.CT_L = 3011
CommonConst.CT_M = 3012
CommonConst.CT_N = 3013
CommonConst.CT_O = 3014
CommonConst.CT_P = 3015
CommonConst.CT_Q = 3016
CommonConst.CT_R = 3017
CommonConst.CT_S = 3018
CommonConst.CT_T = 3019
CommonConst.CT_U = 3020
CommonConst.CT_V = 3021
CommonConst.CT_W = 3022
CommonConst.CT_X = 3023
CommonConst.CT_Y = 3024
CommonConst.CT_Z = 3025
CommonConst.CT_LShift = 3026
CommonConst.CT_FillIn = 3027

--通用大厅标签定义
CommonConst.HL_PLAY = 1
CommonConst.HL_HERO = 2
CommonConst.HL_ARSENAL = 3
CommonConst.HL_SHOP = 4
CommonConst.HL_SEASON = 5
CommonConst.HL_FAV = 6


--钱类型:金币
CommonConst.GOLDEN = 1
--钱类型:钻石
CommonConst.DIAMOND = 2


--最大
CommonConst.MAX_SHOW_NUM = 999999
CommonConst.MAX_SHOW_NUM_COIN = 999999999

--适用于WidgetStyle的Flag定义
CommonConst.BTN_STYLE_FLAGS = {
    DEFAULT = 1,
    HOVER = 2,
    SELECT = 3,
    CLICK = 4
}

--角标类型定义
CommonConst.CORNER_TYPE = {
    IMG = 1,    -- 普通图片角标
    HERO_HEAD = 2,  -- 英雄头像样式角标
    WORD = 3,   -- 文字类型角标
}

----------------->>

-- 角标位置
CommonConst.CORNER_TAGPOS = {
    Left = 1,
    Right = 2,
    Mid = 3
}

-- Icon整体状态 状态互斥且优先于对应位置的角标设置 
CommonConst.ITEM_SHOW_STATE_DEFINE = {
    NONE = 0,
    LOCK = 1,   -- 锁定状态
    GOT = 2, -- 已领取
    OUTOFDATE = 3,   -- 过期状态
    NEW = 4, -- 新获得状态
    TIMER = 5,  -- 倒计时状态
    CANGET = 6, -- 可领取状态
}

CommonConst.DRAG_TYPE_DEFINE = {
    NONE = 0,
    CLICK = 1,
    DRAG_BEGIN = 2,
    DRAG_END = 3,
}

-- 红点触发类型
CommonConst.RED_DOT_INTERACT_TYPE = {
    NONE = 0,
    CLICK = 1,
}
-----------------<<

--双击间隔时间s
CommonConst.DOUBLECLICKTIME = 0.3

---@class CommonConst.BuyType 购买方式的枚举
CommonConst.BuyType = {
    -- 默认商城购买
    DEFAULT = 0,
    -- 解锁
    UNLOCK = 1,
}

return CommonConst
