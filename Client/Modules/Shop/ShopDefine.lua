---@class ShopDefine
ShopDefine = {}

-- 商品品质类型
ShopDefine.Quality = {
    Gray = 1,
    Blue = 2,
    Purple = 3,
    Yellow = 4,
    Red = 5
}

-- 商品所属分类
---1	当期推荐
---2	热门搭配
---3	季度单品
---4	常驻
---5	功能道具
---6	充值
ShopDefine.Category = {
    -- 当期推荐
    Recommend = 1,
    -- 热门搭配
    HotActivity = 2,
    -- 季度单品
    QuarterlyItem = 3,
    -- 常驻
    Resident = 4,
    -- 功能道具
    ItemShop = 5,
    -- 充值
    Charge = 6
}

---@type number 商品推荐页签值
ShopDefine.RECOMMEND_PAGE = ShopDefine.Category.Recommend    

-- 商品货币类型
ShopDefine.CurrencyType = {
    -- 金币
    Gold = 900000001,
    -- 钻石
    DIAMOND = 900000002,
    -- 补给点数/补给点券
    SUPPLY_COUPON = 130000006,
    -- 系统赠送钻石
    Gift_DIAMOND = 999999999,
    -- 法律货币
    MONEY = 900000004,
}

-- 商品格子展示类型
ShopDefine.GridType = {
    None = 0,
    -- 占用1个格子
    Normal = 1,
    -- 占用2个格子
    Big = 2,
    -- 占用4个格子
    Wider = 4
}

-- 商品状态
ShopDefine.GoodsState = {
    --禁止单独购买:捆绑包中不能单独购买
    ForbidSingleBuy = 0,
    -- 可购买
    CanBuy = 1,
    -- 已拥有
    Have = 2,
    -- 已达储存上限
    UpToMax = 3,
    -- 已售罄
    OutOfSell = 4,
}

-- 商品模型展示类型
ShopDefine.SceneModelType = {
    -- 展示图片
    Icon = 0,
    -- 展示英雄
    Hero = 2,
    -- 展示武器
    Weapon = 3
}

-- 商品交易状态
ShopDefine.TradingStatus = {
    -- 正在出售
    OnSale = 0,
    -- 配置表禁止交易
    ForbidByCfg = 1,
    -- 商品不存在
    ForbidByNoExist = 2,
    -- 其它错误导致不能交易
    ForbidByOther = 999
}


-- -- 点击商品的方式
-- ShopDefine.ClickGoodsType = {
--     Default = 1,
--     BuyBtn = 2,
--     DetailBtn = 3
-- }

-- 开启商城合规
ShopDefine.OPEN_ShopCompliant = false

--- 推荐的商品ID
ShopDefine.RecommendGoodsId = 100001
--- 推荐的商品ID-英雄
ShopDefine.RecommendHeroGoodsId = 100002


---@class ETabLSState 商城页签相关LS枚举
ShopDefine.ELSState = {
    None = 0,
    RecommendOpen = 1,
    RecommendHeroIn = 2,
    RecommendOtherIn = 3,
    ScrollTabIn = 4,
    ScrollTabOut = 5,
    RaffleLEDVisOff = 6,
    RaffleLEDVisOn = 7,
}

---@class ShopTabLSCfg 商城页签相关LS配置
---@field LSState ETabLSState
---@field LSTag string
---@field HallLSId number
---@field bPostProcess boolean
---@field bUseCache boolean 是否使用缓存播放
---@field bNeedStopAfterFinish boolean 是否停止在Finish后
---@type table ShopTabLSCfg[]
ShopDefine.ShopTabLSCfgs = {
    {LSState = ShopDefine.ELSState.RecommendOpen, HallLSId = HallLSCfg.LS_SHOP_RECOMMONED_OPEN.HallLSId, bUseCache = true, bNeedStopAfterFinish = true, LSTag = "RecommendOpen_LSQ", bPostProcess = false, Des="切换到页签"},
    {LSState = ShopDefine.ELSState.RecommendHeroIn, HallLSId = HallLSCfg.LS_SHOP_RECOMMONED_HERO_IN.HallLSId, bUseCache = true, bNeedStopAfterFinish = false, LSTag = "RecommendHeroIn_LSQ", bPostProcess = false, Des="选择推荐页签英雄皮肤"},
    {LSState = ShopDefine.ELSState.RecommendOtherIn, HallLSId = HallLSCfg.LS_SHOP_RECOMMONED_OTHER_IN.HallLSId, bUseCache = true, bNeedStopAfterFinish = false, LSTag = "RecommendOtherIn_LSQ", bPostProcess = false, Des="选择推荐页签其它"},
    {LSState = ShopDefine.ELSState.ScrollTabIn, HallLSId = HallLSCfg.LS_SHOP_SCROLL_TAB_IN.HallLSId, bUseCache = true, bNeedStopAfterFinish = true, LSTag = "ScrollTabIn_LSQ", bPostProcess = false, Des="从其它页签滚到到推荐页签"},
    {LSState = ShopDefine.ELSState.ScrollTabOut, HallLSId = HallLSCfg.LS_SHOP_SCROLL_TAB_OUT.HallLSId, bUseCache = true, bNeedStopAfterFinish = false, LSTag = "ScrollTabOut_LSQ", bPostProcess = false, Des="从推荐页签滚到到其它页签"},
    {LSState = ShopDefine.ELSState.RaffleLEDVisOff, HallLSId = HallLSCfg.LS_SHOP_RECOMMONED_GO_DETAIL.HallLSId, bUseCache = true, bNeedStopAfterFinish = false, LSTag = "RaffleLED_VisOff_LSQ", bPostProcess = false, Des="非推荐进入到详情页签"},
    {LSState = ShopDefine.ELSState.RaffleLEDVisOn, HallLSId = HallLSCfg.LS_SHOP_DETAIL_GO_RECOMMONED.HallLSId, bUseCache = true, bNeedStopAfterFinish = false, LSTag = "RaffleLED_VisOn_LSQ", bPostProcess = false, Des="详情页签退出到非推荐进入"},
}



