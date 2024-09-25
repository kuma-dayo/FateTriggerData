require("Client.Modules.Shop.ShopDefine")

local super = ListModel
local class_name = "ShopModel"

---@class ShopModel : ListModel
---@field private super ListModel
ShopModel = BaseClass(super, class_name)

ShopModel.ON_GOODS_INFO_CHANGE = "ON_GOODS_INFO_CHANGE" -- 商品数据变化
ShopModel.ON_GOODS_BUYTIMES_CHANGE = "ON_GOODS_BUYTIMES_CHANGE" -- 商品购买次数变化
ShopModel.ON_SCROLL_CHANGE = "ON_SCROLL_CHANGE" -- 商品列表选中状态变化
-- ShopModel.ON_CLICK_GOODS_CHANGE = "ON_CLICK_GOODS_CHANGE" -- 点击了某个商品
ShopModel.ON_UPDATE_GOODS_MODEL_SHOW = "ON_UPDATE_GOODS_MODEL_SHOW" --更新商城模型
ShopModel.ON_UPDATE_GOODS_MODEL_HIDE = "ON_UPDATE_GOODS_MODEL_HIDE" --隐藏商城模型

ShopModel.ON_SHOW_HALLTABSHOP = "ON_SHOW_HALLTABSHOP" --商城界面SHOW
ShopModel.ON_HIDE_HALLTABSHOP = "ON_HIDE_HALLTABSHOP" --商城界面关闭
ShopModel.ON_CHANGLE_BP_LEDSCREEN = "ON_HIDE_HALLTABSHOP" --商城BP_LEDScreen 面板显示与隐藏

ShopModel.HANDLE_SHOPBG_SHOW = "HANDLE_SHOPBG_SHOW" -- 更改3DUI背景


---@class DirtyFlagDefine
---@field NoChanged number 无变化
---@field InitListChanged number 初始化列表变化
---@field AvailableStateChanged number 可用状态变化
---@field PageListChanged number 列表变化
---@field BuyStateChanged number 购买状态变化
---@field TimeStateChanged number 跟商品时间状态有关的变化,需要刷新列表
ShopModel.DirtyFlagDefine = {
    -- NoChanged = 0,
    InitListChanged = 1,
    AvailableStateChanged = 2,
    BuyStateChanged = 3,
    TimeStateChanged = 4,
    -- PageListChangedStart = 5,
    PageListChanged = 5,
    CurTabIndex = 0 --商店页签
    -- PageListChangedEnd = 10,
}

ShopModel.DirtyFlagDefineValue = {
}

--- 玩家登出时调用
---@param data any
function ShopModel:OnLogout(data)
    ShopModel.super.OnLogout(self)
    self:_dataInit()
end

--- 玩家登出时调用
---@param data any
function ShopModel:OnLogin(data)
    ShopModel.super.OnLogin(self)
end

--- 重写父方法,返回唯一Key
---@param vo any
function ShopModel:KeyOf(vo)
    return vo["GoodsId"]
end

--- 重写父类方法,如果数据发生改变
--- 进行通知到这边的逻辑
---@param vo any
function ShopModel:SetIsChange(value)
    ShopModel.super.SetIsChange(self, value)
end

function ShopModel:__init()
    self:InitAllDirtyFlag()
    self:_dataInit()
end

function ShopModel:_dataInit()
    self:Clean()
    self.CacheAvailableGoodsList = {}
    self.CacheCategoryShopItemList = {}
    self.CacheCategoryShopItemListKeys = {}
    self:SetAllFlagDirty()
end

--- 设置所有状态为脏状态
function ShopModel:SetAllFlagDirty()
    self.DirtyFlag = 0
    self.AllDirtyFlag = 0
    self:RefreshAllDirtyFlag()
    self.DirtyFlag = self.AllDirtyFlag
end

--- 初始化所有的DirtyFlag
function ShopModel:InitAllDirtyFlag()
    self.AllDirtyFlag = 0
    for _, Flag in pairs(ShopModel.DirtyFlagDefine) do
        local FlagValue = 1 << Flag
        ShopModel.DirtyFlagDefineValue[Flag] = FlagValue
        self.AllDirtyFlag = self.AllDirtyFlag | FlagValue
    end
end

--- 刷新所有的DirtyFlag
function ShopModel:RefreshAllDirtyFlag()
    self.AllDirtyFlag = 0
    for _, FlagValue in pairs(ShopModel.DirtyFlagDefineValue) do
        self.AllDirtyFlag = self.AllDirtyFlag | FlagValue
    end
end

--- 动态插入DirtyFlag
---@param DirtyFlag DirtyFlagDefine
---@param IsDirty boolean
function ShopModel:InsertDirtyByType(DirtyFlag, Offset)
    Offset = Offset or 0
    local NewDirtyFlag = Offset + DirtyFlag
    if ShopModel.DirtyFlagDefineValue[NewDirtyFlag] then
        CWaring("[ShopModel]InsertDirtyByType can not insert new value when exist define flag")
        return ShopModel.DirtyFlagDefineValue[NewDirtyFlag]
    end
    local FlagValue = 1 << NewDirtyFlag
    ShopModel.DirtyFlagDefineValue[NewDirtyFlag] = FlagValue
    self:RefreshAllDirtyFlag()
    return FlagValue
end

--- 设置脏数据状态
---@param DirtyFlag DirtyFlagDefine
---@param IsDirty boolean
function ShopModel:SetDirtyByType(DirtyFlag, IsDirty, Offset)
    Offset = Offset or 0
    local NewDirtyFlag = Offset + DirtyFlag
    local FlagValue =  ShopModel.DirtyFlagDefineValue[NewDirtyFlag]
    if FlagValue == nil then
        FlagValue = self:InsertDirtyByType(DirtyFlag, Offset)
    end
    if IsDirty then
        self.DirtyFlag = self.DirtyFlag | FlagValue
    else
        self.DirtyFlag = self.DirtyFlag & ~FlagValue
    end

    if Offset ~= 0 then
        self:SetDirtyByType(DirtyFlag, true)
    end
end

--- 判断是否是脏数据
---@param DirtyFlag DirtyFlagDefine
function ShopModel:IsDirtyByType(DirtyFlag, Offset)
    Offset = Offset or 0
    local NewDirtyFlag = Offset + DirtyFlag
    local FlagValue =  ShopModel.DirtyFlagDefineValue[NewDirtyFlag]
    if FlagValue == nil then
        return true
    end
    return self.DirtyFlag & FlagValue > 0
end

---获取商城中对应商品模型显示的最终的 Tran
---@param GoodsID 商品ID
---@param ModuleID ETransformModuleID.Shop_Recommend 
---@return RtShowTran
---@return table {Pos:UE.FVector, Rot:UE.FRotator, Scale:UE.FVector, BaseTran:{{number,number,number},{number,number,number},{number,number,number}}}
function ShopModel:GetShopModeTranFinal(GoodsID, ModuleID, bShow3D, DefPos, DefRot)
    DefPos = DefPos or UE.FVector(80001, 290, 133)
    DefRot = DefRot or UE.FRotator(-10.5, 53, 65)
    ---@type GoodsItem
    local GoodsInfo = self:GetData(GoodsID)
    if GoodsInfo == nil then
        CLog("ShopModel:GetShopModeTranFinal() GoodsInfo == nil !!! GoodsID =" .. GoodsID)
        return {}
    end
    local SceneModelSkinID = GoodsInfo and GoodsInfo.SceneModelSkinID or 0
    local ItemID = bShow3D and SceneModelSkinID or GoodsInfo.ItemId
    if ItemID == 0 then
        CLog("ShopModel:GetShopModeTranFinal() ItemID == 0 !!! GoodsID =" .. GoodsID)
        return {}
    end

    local DefParam = {DefPos = DefPos, DefRot = DefRot, DefScale = UE.FVector(1, 1, 1)}
    ---@type RtShowTran
    local FinalTran = CommonUtil.GetShowTranByItemID(ModuleID, ItemID, DefParam)
    return FinalTran
end

--- 初始化商城数据
--- @return GoodsItem[]
function ShopModel:InitShopConfig()
    if not self:IsDirtyByType(ShopModel.DirtyFlagDefine.InitListChanged) then
        return
    end
    CLog("ShopModel InitShopConfig")

    self.CategoryShopItemList = {}
    ---@type number[] 记录商品是否是IsShowInPage
    self.ShopItemCanShowList = {}
    local ShopItemList = {}

    local ShopConfigs = G_ConfigHelper:GetDict(Cfg_ShopConfig)
    if not ShopConfigs then
        CError("ShopConfigs is nil, need check!")
        return
    end
    for _, Cfg in pairs(ShopConfigs) do
        local GoodsId = Cfg[Cfg_ShopConfig_P.GoodsId]
        local Category = Cfg[Cfg_ShopConfig_P.PageList] -- ShopDefine.Category.HotActivity
        local Name = Cfg[Cfg_ShopConfig_P.Name]
        local Icon = Cfg[Cfg_ShopConfig_P.Icon]
        local SpecialMarkIcon = Cfg[Cfg_ShopConfig_P.SpecialMarkIcon]
        local SpecialMarkText = Cfg[Cfg_ShopConfig_P.SpecialMarkText]
        local SceneModelSkinID = Cfg[Cfg_ShopConfig_P.SceneModelSkinID]
        local SceneModelIcon = Cfg[Cfg_ShopConfig_P.SceneModelIcon]
        local Quality = Cfg[Cfg_ShopConfig_P.Quality] -- ShopDefine.Quality.Gray,
        local CurrencyType = Cfg[Cfg_ShopConfig_P.CurrencyType] ---ShopDefine.CurrencyType.Diamond,
        local Price = Cfg[Cfg_ShopConfig_P.Price]
        local GridType = Cfg[Cfg_ShopConfig_P.GridType] -- ShopDefine.GridType.Mini,
        local Prority = Cfg[Cfg_ShopConfig_P.Prority]
        local IsOpenPopDetail = Cfg[Cfg_ShopConfig_P.IsOpenFullDetail]
        local ItemId = Cfg[Cfg_ShopConfig_P.ItemId]
        local ItemNum = Cfg[Cfg_ShopConfig_P.ItemNum]
        local EventName = Cfg[Cfg_ShopConfig_P.EventName]
        local IsShowInPage =  Cfg[Cfg_ShopConfig_P.IsShowInPage]
        local IsSingleCanBuy =  Cfg[Cfg_ShopConfig_P.IsSingleCanBuy]

        local SceneModelType = 0
        if SceneModelSkinID > 0 then
            -- SceneModelType = tonumber(string.sub(tostring(SceneModelSkinID), 1, 1))
            local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, SceneModelSkinID)
            if ItemCfg then
                if ItemCfg[Cfg_ItemConfig_P.Type] == Pb_Enum_ITEM_TYPE.ITEM_PLAYER and ItemCfg[Cfg_ItemConfig_P.SubType] == DepotConst.ItemSubType.Sticker then
                    SceneModelType = ShopDefine.SceneModelType.Icon
                else
                    SceneModelType = ItemCfg[Cfg_ItemConfig_P.Type]
                end
            end
        end

        -- CError("====================="..SceneModelType .. "====GoodsId:"..GoodsId)
        ---@class GoodsItem
        ---@field GoodsId number
        ---@field Category ShopDefine.Category[]
        ---@field IsShowInPage boolean 商品能否在对应的Category中显示
        ---@field IsSingleCanBuy boolean 商品能否被单独购买
        ---@field Name string
        ---@field Icon string
        ---@field SpecialMarkIcon string
        ---@field SpecialMarkText string
        ---@field SceneModelType  ShopDefine.SceneModelType
        ---@field SceneModelSkinID number 商品模型展示ID
        ---@field SceneModelIcon string
        ---@field Quality ShopDefine.Quality
        ---@field CurrencyType ShopDefine.CurrencyType
        ---@field Price number 货柜上的价格.捆绑包是包含商品的优惠价格的和值.没有去除已经拥有的商品.
        ---@field SuggestedPrice number 商品的厂商建议价.即原价
        ---@field GridType ShopDefine.GridType
        ---@field Prority number
        ---@field IsOpenFullDetail boolean 是否全屏
        ---@field ItemId number 外观展示商品ID
        ---@field ItemNum number 外观展示商品数量
        ---@field EventName string
        ---@field BuyTimes number 商品已经购买了的次数
        ---@field IsHaveDiscount boolean 是否有BUFF折扣价格
        ---@field MaxLimitCount number 商品BUFF限购次数
        ---@field DisCountPrice number 商品Buff折扣价格
        ---@field DisCountBeginTime number 商品BUFF中的折扣开始时间
        ---@field DisCountEndTime number 商品BUFF中的折扣结束时间
        ---@field SellBeginTime number 商品BUFF中的起售时间
        ---@field SellEndTime number 商品BUFF中的结束售买时间
        ---@field IsPackGoods boolean 此商品是否是捆绑包?
        ---@field PackGoodsList PackGoodsItem[] 捆绑包中的商品信息
        ---@field PackGoodsMap table<number,PackGoodsItem[]> 捆绑包中的商品信息
        ---@field PackGoodsIdList number[] 捆绑包中的商品ID
        ---@field TotalDisCountPrice number 捆绑包中总优惠价格,不是BUFF优惠
        ---@field Available boolean 是否可用
        ---@field GoodsState ShopDefine.GoodsState
        ---@field LimitCircle Pb_Enum_GOOD_REFRESH_TYPE 商品BUFF限购周期
        ---@field LinkPackGoods number 关联捆绑包
        ---@field IsDirty boolean
        ---@field RechargeInfo RechargeCfg 充值的挡位相关配置
        local GoodsItem = {
            GoodsId = GoodsId,
            Category = Category, -- ShopDefine.Category.HotActivity
            IsShowInPage = IsShowInPage,
            IsSingleCanBuy = IsSingleCanBuy,
            Name = Name,
            Icon = Icon,
            SpecialMarkIcon = SpecialMarkIcon,
            SpecialMarkText = SpecialMarkText,
            SceneModelType = SceneModelType,
            SceneModelSkinID = SceneModelSkinID,
            SceneModelIcon = SceneModelIcon,
            Quality = Quality, -- ShopDefine.Quality.Gray,
            CurrencyType = CurrencyType, ---ShopDefine.CurrencyType.Diamond,
            Price = Price,
            SuggestedPrice = Price,
            -- SavePrice = Price,
            -- SaveOriginPrice = Price,
            GridType = GridType,
            Prority = Prority,
            IsOpenFullDetail = not IsOpenPopDetail,
            ItemId = ItemId,
            ItemNum = ItemNum,
            EventName = EventName,
            MaxLimitCount = 0,
            LimitCircle = 0,
            BuyTimes = 0,
            DisCountPrice = 0,
            DisCountBeginTime = 0,
            DisCountEndTime = 0,
            SellBeginTime = 0,
            SellEndTime = 0,
            IsPackGoods = false,
            PackGoodsList = nil,
            PackGoodsMap = nil,
            TotalDisCountPrice = 0,
            Available = false,
            IsHaveDiscount = false,
            IsDirty = true,
            RechargeInfo = nil
        }

        GoodsItem.LinkPackGoods = Cfg[Cfg_ShopConfig_P.LinkPackGoods] or 0

        self.ShopItemCanShowList[GoodsId] = GoodsItem.IsShowInPage

        -- 商品页签分类
        local bIsCharge = false
        if Category then
            for _, value in pairs(Category) do
                self.CategoryShopItemList[value] = self.CategoryShopItemList[value] or {}
                table.insert(self.CategoryShopItemList[value], GoodsId)
                if value == ShopDefine.Category.Charge then
                    bIsCharge = true
                end
            end
        end
        if bIsCharge then
            GoodsItem.RechargeInfo = self:GetRechargeInfo(GoodsId)
        end

        -- 捆绑包相关
        local PackGoodsIdList = Cfg[Cfg_ShopConfig_P.PackGoodsIdList]
        GoodsItem.IsPackGoods = (PackGoodsIdList and PackGoodsIdList:Length() > 0) and true or false
        GoodsItem.PackGoodsIdList = PackGoodsIdList
        if GoodsItem.IsPackGoods then
            GoodsItem.PackGoodsList, GoodsItem.PackGoodsMap, GoodsItem.TotalDisCountPrice, GoodsItem.SuggestedPrice = self:InitPackShopConfig(Cfg)
            GoodsItem.Price = GoodsItem.TotalDisCountPrice
        end

        -- 商品BUFF相关
        local GoodsBuffId = Cfg[Cfg_ShopConfig_P.GoodsBuffId]
        if GoodsBuffId and GoodsBuffId > 0 then
            local ShopBuffCfg = G_ConfigHelper:GetSingleItemById(Cfg_ShopBuffConfig, GoodsBuffId)
            if not ShopBuffCfg then
                CError(StringUtil.Format("Cfg_ShopBuffConfig is nil! GoodsId:{0} GoodsBuffId:{1}", GoodsId, GoodsBuffId))
                return
            end
            GoodsItem.IsHaveDiscount = true
            local DisCountPrice = ShopBuffCfg[Cfg_ShopBuffConfig_P.DisCountPrice]
            if DisCountPrice == 0 then
                GoodsItem.IsHaveDiscount = false
                ---折扣价格为0 不折扣
                -- GoodsItem.DisCountPrice = Price
                GoodsItem.DisCountPrice = GoodsItem.Price
            elseif DisCountPrice <= -1 then
                ---折扣价格小于0 免费
                GoodsItem.DisCountPrice = 0
            else
                GoodsItem.DisCountPrice = DisCountPrice
            end
            GoodsItem.MaxLimitCount = ShopBuffCfg[Cfg_ShopBuffConfig_P.LimitCount] or 0
            GoodsItem.LimitCircle = ShopBuffCfg[Cfg_ShopBuffConfig_P.LimitCircle] or 0
            GoodsItem.DisCountBeginTime = TimeUtils.getTimestamp(ShopBuffCfg[Cfg_ShopBuffConfig_P.DisCountBeginTime]) or 0
            GoodsItem.DisCountEndTime = TimeUtils.getTimestamp(ShopBuffCfg[Cfg_ShopBuffConfig_P.DisCountEndTime]) or 0
            GoodsItem.SellBeginTime = TimeUtils.getTimestamp(ShopBuffCfg[Cfg_ShopBuffConfig_P.SellBeginTime]) or 0
            GoodsItem.SellEndTime = TimeUtils.getTimestamp(ShopBuffCfg[Cfg_ShopBuffConfig_P.SellEndTime]) or 0
        end

        table.insert(ShopItemList, GoodsItem)
    end
    self:SetDataList(ShopItemList)
    self:SetDirtyByType(ShopModel.DirtyFlagDefine.InitListChanged, false)
    self:SetDirtyByType(ShopModel.DirtyFlagDefine.TimeStateChanged, false)
end

---@class RechargeCfg 重置配置
---@field RechargeId number 档位Id
---@field MoneyNum number 金额
---@field GetItemId number 获得物品Id
---@field GetItemNum number 获得物品数量
---@return table RechargeCfg
function ShopModel:GetRechargeInfo(GoodsId)
    GoodsId = GoodsId or 0
    ---@type RechargeCfg
    local Info = nil
    local Dicts = G_ConfigHelper:GetDict(Cfg_RechargeConfig)
    for k, Cfg in pairs(Dicts) do
        if Cfg[Cfg_RechargeConfig_P.GoodsId] == GoodsId then
            Info = Info or {}
            Info.RechargeId = Cfg[Cfg_RechargeConfig_P.RechargeId]
            Info.MoneyNum = Cfg[Cfg_RechargeConfig_P.MoneyNum]
            Info.GetItemId = Cfg[Cfg_RechargeConfig_P.GetItemId]
            Info.GetItemNum = Cfg[Cfg_RechargeConfig_P.GetItemNum]
            break
        end
    end
    return Info
end

---@class PackGoodsItem 捆绑包中的的商品结构
---@field PackGoodsId number 商品ID
---@field PackItemId number 对应的物品ID
---@field PackItemNum number 对应的物品的数量
---@field PackItemOriginPrice number 对应的物品的原价
---@field PackGoodsDisCountPrice number 捆绑包内对应商品的优惠价
---@field IsKeyMark boolean 关键物品标记
---@field PackItemIdx number 顺序
--- 初始化捆绑包数据
---@param ShopCfg any
---@return PackGoodsItem[],table<number,PackGoodsItem[]>,number,number
function ShopModel:InitPackShopConfig(ShopCfg)
    local GoodsId = ShopCfg[Cfg_ShopConfig_P.GoodsId]
    -- 捆绑包内含商品ID List
    local PackGoodsIdList = ShopCfg[Cfg_ShopConfig_P.PackGoodsIdList]
    -- 捆绑包内含商品优惠价 List
    local PackGoodsIdPriceList = ShopCfg[Cfg_ShopConfig_P.PackGoodsIdPriceList]
    -- 捆绑包内关键物品标记
    local KeyMarkList = ShopCfg[Cfg_ShopConfig_P.KeyMarkList]
    local KeyMarkMap = {}
    for k, val in pairs(KeyMarkList) do
        KeyMarkMap[val] = true
    end

    if not PackGoodsIdList or PackGoodsIdList:Length() == 0 then
        return nil,nil,0,0
    end

    if not PackGoodsIdPriceList or PackGoodsIdPriceList:Length() == 0 then
        CError(StringUtil.Format("PackGoodsIdPriceList is nil! GoodsId:{0}", GoodsId))
        return nil,nil,0,0
    end

    ---@type PackGoodsItem[]
    local PackGoodsList = {}
    ---@type table<number,PackGoodsItem[]>
    local PackGoodsMap= {}
    -- 捆绑包商品总优惠
    local TotalDisCountPrice = 0
    -- 建议总售价
    local TotalSuggestedPrice = 0
    -- 解释捆绑包内含商品
    for index, PackGoods in pairs(PackGoodsIdList) do
        local PackGoodsCfg = G_ConfigHelper:GetSingleItemById(Cfg_ShopConfig, PackGoods)

        if not PackGoodsCfg then
            CError(StringUtil.Format("PackGoodsCfg is nil!-1 GoodsId:{0} PackGoods:{1}", GoodsId, PackGoods))
            return nil,nil,0,0
        end

        -- 商品ID
        local PackGoodsId = PackGoodsCfg[Cfg_ShopConfig_P.GoodsId]
        -- 外观展示物品ID
        local PackItemId = PackGoodsCfg[Cfg_ShopConfig_P.ItemId]

        if PackGoodsId <= 0 then
            CError(StringUtil.Format("PackGoodsCfg is nil!-2 GoodsId:{0} PackGoods is equal 0!", GoodsId))
            -- return
        end

        if PackItemId <= 0 then
            CError(StringUtil.Format("PackGoodsCfg is nil!-3 GoodsId:{0} PackItemId is equal 0!", GoodsId))
            -- return
        end

        -- 外观展示物品数量
        local PackItemNum = PackGoodsCfg[Cfg_ShopConfig_P.ItemNum]
        -- 对应的物品的原价
        local PackItemOriginPrice = PackGoodsCfg[Cfg_ShopConfig_P.Price]
        -- 捆绑包内对应商品的优惠价
        local PackGoodsDisCountPrice = PackGoodsIdPriceList[index] or 0
        -- 判断是否关键商品
        local IsKeyMark = KeyMarkMap[PackGoodsId] or false
      
        ---@type PackGoodsItem
        local PackGoodsInfo = {
            PackGoodsId = PackGoodsId,
            PackItemId = PackItemId,
            PackItemNum = PackItemNum,
            PackItemOriginPrice = PackItemOriginPrice,
            PackGoodsDisCountPrice = PackGoodsDisCountPrice,
            IsKeyMark = IsKeyMark,
            PackItemIdx = index
        }
        
        table.insert(PackGoodsList, PackGoodsInfo)

        PackGoodsMap[PackGoodsId] = PackGoodsMap[PackGoodsId] or {}
        table.insert(PackGoodsMap[PackGoodsId], PackGoodsInfo)

        TotalDisCountPrice = TotalDisCountPrice + PackGoodsDisCountPrice
        TotalSuggestedPrice = TotalSuggestedPrice + PackItemOriginPrice

        ShopModel:CollectGoodsIDToPack(PackGoodsId, GoodsId)
    end

    return PackGoodsList, PackGoodsMap, TotalDisCountPrice, TotalSuggestedPrice
end

--- 收集商品Id对应的捆绑包Id
---@param PackGoodsId number 商品ID
---@param PackID number 捆绑包ID
function ShopModel:CollectGoodsIDToPack(PackGoodsId, PackID)
    ---@type table<number,number[]> 收集商品Id对应的捆绑包Id
    self.GoodsIDToPack = self.GoodsIDToPack or {}
    self.GoodsIDToPack[PackGoodsId] = self.GoodsIDToPack[PackGoodsId] or {}
    if not(table.contains(self.GoodsIDToPack[PackGoodsId], PackID)) then
        table.insert(self.GoodsIDToPack[PackGoodsId], PackID)
    end
end

---处理服务器返回的商品信息数据
---@param Res PlayerShopGoodInfoListRsp
function ShopModel:HandleShopGoodsInfo(Res)
    CLog("ShopModel:HandleShopGoodsInfo")
    for _, Goods in ipairs(Res.GoodList) do
        ---@type GoodsItem
        local GoodsItem = self:GetData(Goods.GoodId)
        if not GoodsItem then
            CError(StringUtil.Format("Can not get Goods! GoodsId:{0}", Goods.GoodId))
            return
        end
        GoodsItem.BuyTimes = Goods.HadBuyCount
        GoodsItem.SellBeginTime = Goods.SellBeginTime
        GoodsItem.SellEndTime = Goods.SellEndTime
        GoodsItem.Available = true
        GoodsItem.IsDirty = true
        self:HandleGoodState(Goods.GoodId)
    end

    for PageId, v in pairs(self.CategoryShopItemList) do
        self:SetDirtyByType(ShopModel.DirtyFlagDefine.PageListChanged, true , PageId)
    end
    self:SetDirtyByType(ShopModel.DirtyFlagDefine.AvailableStateChanged, true)
    self:SetDirtyByType(ShopModel.DirtyFlagDefine.BuyStateChanged, true)

    self:DispatchType(ShopModel.ON_GOODS_INFO_CHANGE)
    -- print_r(self:GetDataList())
end

---处理购买返回的商品数据
---@param Res PlayerBuyGoodRsp
function ShopModel:HandleShopGoodsLimitTimes(Res)
    local GoodsItem = self:GetData(Res.GoodId)
    if not GoodsItem then
        CError(StringUtil.Format("Can not get Goods! GoodsId:{0}", Res.GoodId))
        return
    end
    GoodsItem.BuyTimes = Res.HadBuyCount
    GoodsItem.IsDirty = true
    self:HandleGoodState(Res.GoodId)
    for PageId, v in pairs(self.CategoryShopItemList) do
        self:SetDirtyByType(ShopModel.DirtyFlagDefine.PageListChanged, true , PageId)
    end
    self:SetDirtyByType(ShopModel.DirtyFlagDefine.BuyStateChanged, true)

    local ParamN = {
        GoodId = Res.GoodId,
        BuyTimes = Res.HadBuyCount
    }
    self:DispatchType(ShopModel.ON_GOODS_BUYTIMES_CHANGE, ParamN)

    self:DispatchType(ShopModel.ON_GOODS_INFO_CHANGE)
end

--- 处理所有商品的状态
function ShopModel:HandleAllGoodState()
    ---@type GoodsItem[]
    local DataList = self:GetDataList()
    for _, Data in ipairs(DataList) do
        self:HandleGoodState(Data.GoodsId)
    end

    if self.CategoryShopItemList and next(self.CategoryShopItemList) then
        for PageId, v in pairs(self.CategoryShopItemList) do
            self:SetDirtyByType(ShopModel.DirtyFlagDefine.PageListChanged, true , PageId)
        end
    end

    self:DispatchType(ShopModel.ON_GOODS_INFO_CHANGE)
end

--- 处理单个商品的状态
---@param GoodsId number
function ShopModel:HandleGoodState(GoodsId)
    ---@type GoodsItem
    local Data = self:GetData(GoodsId)
    local KeyItemIds = self:GetKeyItemIds(GoodsId)
    if #KeyItemIds <= 0 then
        table.insert(KeyItemIds, Data.ItemId)
    end
    local FinalState = Data.IsSingleCanBuy and ShopDefine.GoodsState.CanBuy or ShopDefine.GoodsState.ForbidSingleBuy
    local State = FinalState
    ---@type DepotModel
    local DepotModel = MvcEntry:GetModel(DepotModel)
    for _, KeyItemId in pairs(KeyItemIds) do
        local MaxItemNum = DepotModel:GetItemMaxCountByItemId(KeyItemId)
        local ItemNum = DepotModel:GetItemCountByItemId(KeyItemId)
        local BuyTimes = self:GetGoodsBuyTimes(Data.GoodsId)
        if MaxItemNum > 0 and ItemNum >= MaxItemNum then
            State = MaxItemNum == 1 and ShopDefine.GoodsState.Have or ShopDefine.GoodsState.UpToMax
        elseif Data.MaxLimitCount > 0 and BuyTimes >= Data.MaxLimitCount then
            State = ShopDefine.GoodsState.OutOfSell
        end
        if State ~= FinalState then
            FinalState = State
        end
    end
    self:SetGoodsState(Data.GoodsId, FinalState)

    ---处理一下捆绑包子商品的状态
    if Data.PackGoodsList then
        for _, PackGoods in pairs(Data.PackGoodsList) do
            self:HandleGoodState(PackGoods.PackGoodsId)
        end
    end
end

--- 获取可用的商品
--- @return GoodsItem[]
function ShopModel:GetAvailableDataList()
    if not self:IsDirtyByType(ShopModel.DirtyFlagDefine.AvailableStateChanged) then
        return self.CacheAvailableGoodsList
    end
    local AvailableGoodsList = {}
    local GoodsList = self:GetDataList()
    for _, Goods in pairs(GoodsList) do
        if Goods.Available then
            table.insert(AvailableGoodsList, Goods)
        end
    end
    self.CacheAvailableGoodsList = AvailableGoodsList
    self:SetDirtyByType(ShopModel.DirtyFlagDefine.AvailableStateChanged, false)
    return AvailableGoodsList
end

--- 获取分页商品
---@alias RtGoodsItem table{GridType:number,Goods:GoodsItem[]}
---@param PageId number
---@return RtGoodsItem[]
function ShopModel:GetAvailableDataListByPageId(PageId, GroupByGrid)
    if not PageId then
        return nil
    end

    if not self:IsDirtyByType(ShopModel.DirtyFlagDefine.PageListChanged, PageId) then
        return self.CacheCategoryShopItemList[PageId]
    end

    local GoodsList = self.CategoryShopItemList[PageId]
    if GoodsList == nil or next(GoodsList) == nil then
        CError("ShopModel:GetAvailableDataListByPageId, 11, GoodsList == nil or next(GoodsList) == nil Error !!! 11")
        return nil
    end
    --过滤去除不被展示的商品ID
    local CanShowGoodsList = {}
    for k, GoodsId in pairs(GoodsList) do
        if self.ShopItemCanShowList[GoodsId] then
            table.insert(CanShowGoodsList, GoodsId)
        end
    end
    GoodsList = CanShowGoodsList
    if GoodsList == nil or next(GoodsList) == nil then
        CError("ShopModel:GetAvailableDataListByPageId, 22, GoodsList == nil or next(GoodsList) == nil Error !!! 22")
        return nil
    end

    local AvailableGoodsList = {}
    ---@type GoodsItem[]
    local SortGoodsList = {}
    for _, GoodsId in ipairs(GoodsList) do
        ---@type GoodsItem
        local Goods = self:GetData(GoodsId)
        if Goods and Goods.Available then
            table.insert(SortGoodsList, Goods)
        end
    end
    SortGoodsList = self:SortGoodsList(SortGoodsList)
    local LastFindNormalTypeIndex = -1
    for _, tGoodsItem in ipairs(SortGoodsList) do
        if GroupByGrid then
            if tGoodsItem.GridType == ShopDefine.GridType.Normal or tGoodsItem.GridType == ShopDefine.GridType.None then
                if LastFindNormalTypeIndex == -1 then
                    table.insert(AvailableGoodsList, {
                        GridType = tGoodsItem.GridType,
                        Goods = {tGoodsItem}
                    })
                    LastFindNormalTypeIndex = #AvailableGoodsList
                else
                    table.insert(AvailableGoodsList[LastFindNormalTypeIndex].Goods, tGoodsItem)
                    LastFindNormalTypeIndex = -1
                end
            else
                table.insert(AvailableGoodsList, {
                    GridType = tGoodsItem.GridType,
                    Goods = {tGoodsItem}
                })
                LastFindNormalTypeIndex = -1
            end
        else
            table.insert(AvailableGoodsList, {
                GridType = ShopDefine.GridType.None,
                Goods = {tGoodsItem}
            })
        end
    end

    self.CacheCategoryShopItemList[PageId] = AvailableGoodsList
    self:SetDirtyByType(ShopModel.DirtyFlagDefine.PageListChanged, false, PageId)
    return AvailableGoodsList
end


--- 获取商品购买次数
---@param GoodsId number
---@return number
function ShopModel:GetGoodsBuyTimes(GoodsId)
    local Goods = self:GetData(GoodsId)
    return Goods.BuyTimes
end

--- 是否达到限购次数
---@param GoodsId number
---@return number
function ShopModel:IsUpToMaxLimitTimes(GoodsId, GoodCount)
    GoodCount = GoodCount or 1
    ---@type GoodsItem
    local Goods = self:GetData(GoodsId)
    if Goods.MaxLimitCount > 0 then
        return Goods.BuyTimes + GoodCount > Goods.MaxLimitCount
    end
    return false
end

--- 设置商品购买次数
---@param GoodsId number
---@param BuyTimes number
function ShopModel:SetGoodsBuyTimes(GoodsId, BuyTimes)
    ---@type GoodsItem
    local Goods = self:GetData(GoodsId)
    Goods.BuyTimes = BuyTimes
    Goods.IsDirty = true
end

--- 获取商品状态
---@param GoodsId number
---@return ShopDefine.GoodsState
function ShopModel:GetGoodsState(GoodsId)
    local Goods = self:GetData(GoodsId)
    return Goods.GoodsState
end

--- 设置商品状态
---@param GoodsId number
---@param GoodsState ShopDefine.GoodsState
function ShopModel:SetGoodsState(GoodsId, GoodsState)
    -- CError(string.format("--- 设置商品状态 GoodsId=[%s],GoodsState=[%s]",GoodsId,GoodsState))
    ---@type GoodsItem
    local Goods = self:GetData(GoodsId)
    Goods.GoodsState = GoodsState
    Goods.IsDirty = true
end

--- 获取关键商品的物品ID
---@param GoodsId number
---@return number[],table<number,number>
function ShopModel:GetKeyItemIds(GoodsId)
    local KeyItemIds = {}
    local KeyItemIdToNum = {}
    local mVal = 0
    ---@type GoodsItem
    local Goods = self:GetData(GoodsId)
    if Goods.ItemId > 0 then
        table.insert(KeyItemIds, Goods.ItemId)

        mVal = KeyItemIdToNum[Goods.ItemId] or 0
        mVal = mVal + Goods.ItemNum
        KeyItemIdToNum[Goods.ItemId] = mVal
    end

    if Goods.PackGoodsList then
        for _, PackGoods in pairs(Goods.PackGoodsList) do
            if PackGoods.IsKeyMark then
                table.insert(KeyItemIds, PackGoods.PackItemId)

                mVal = KeyItemIdToNum[PackGoods.PackItemId] or 0
                mVal = mVal + PackGoods.PackItemNum
                KeyItemIdToNum[PackGoods.PackItemId] = mVal
            end
        end
    end
    return KeyItemIds, KeyItemIdToNum
end

--- 检测折扣价格是否生效
---@param GoodsId number
function ShopModel:CheckGoodsIsInDiscount(GoodsId)
     ---@type GoodsItem
    local Goods = self:GetData(GoodsId)
    if not Goods.IsHaveDiscount then
        return false
    end
    ---未配置折扣时间,则折扣生效
    if Goods.DisCountBeginTime <= 0 and Goods.DisCountEndTime <= 0 then
        return true
    end

    ---配置了折扣时间,但未到时间,则折扣不生效
    local NowTimeStamp = GetTimestamp()
    if NowTimeStamp < Goods.DisCountBeginTime or NowTimeStamp > Goods.DisCountEndTime  then
        return false
    end
    return true
end

--- 判断商品或子物品是否dirty
---@param GoodsId any
function ShopModel:IsGoodsDirty(GoodsId)
    ---@type GoodsItem
    local Goods = self:GetData(GoodsId)
    if Goods.IsDirty then
        return true
    end
    if Goods.PackGoodsList then
        for _, PackGoods in pairs(Goods.PackGoodsList) do
            ---@type GoodsItem
            local PackGoods = self:GetData(PackGoods.PackGoodsId)
            if PackGoods.IsDirty then
                return true
            end
        end
    end
    return false
end

---@class ReferenceUnitPrice 单价参考
---@field SettlementPrice number 结算价格.实时价格.玩家实际支付价格.捆绑包去除了已经拥有的商品
---@field Price number 货柜上的价格.捆绑包是包含商品的优惠价格的和值.没有去除已经拥有的商品.
---@field SuggestedPrice number 建议出售价格.即原价
---@field USDiscount number 折扣值.美国式折扣
---@field OwnPrice number 已经拥有的
---@field CurrencyType number 货币Id

----@field OriginPrice number 原价
----@field DPrice number 划线价格
----@field RealTimePrice number 实时价格
--- 获取商品单价,所有希望获取商品价格的方法都应从这里取价格
---@param GoodsId number
---@param WithDiscount boolean 是否需要算折扣价格
---@return ReferenceUnitPrice
function ShopModel:GetGoodsUnitPrice(GoodsId)
    ---@type GoodsItem
    local Goods = self:GetData(GoodsId)
    if not self:IsGoodsDirty(GoodsId) then
        return Goods.ReferenceUnitPrice
    end
    local FinalPrice = 0
    local FinalOriginPrice = 0
    local WindowPrice = 0

    -- if Goods.RechargeInfo then
    --     FinalPrice = Goods.RechargeInfo.MoneyNum
    --     FinalOriginPrice = Goods.RechargeInfo.MoneyNum
    --     Goods.SavePrice = FinalPrice
    --     Goods.SaveOriginPrice = FinalPrice
    --     Goods.IsDirty = false
    --     return FinalPrice, FinalOriginPrice
    -- end

    local OwnPrice = 0 --已经拥有的商品的价格总计
    local SettlementPrice = 0
    if Goods.PackGoodsList then
        -- local OriginPrice = 0
        -- local DisCountPrice = 0
        for _, PackGoods in pairs(Goods.PackGoodsList) do
            -- OriginPrice = OriginPrice + PackGoods.PackItemOriginPrice
            -- DisCountPrice = DisCountPrice + PackGoods.PackGoodsDisCountPrice
            local State = self:GetGoodsState(PackGoods.PackGoodsId)

            --特别注意::ShopDefine.GoodsState.ForbidSingleBuy:只能代表它单个商品不能购买。当购买捆绑包商品时,认定里面的单个商品是默认能够购买的
            --禁止单独购买+能够购买的 都属于捆绑包中能一起购买的商品
            local bCanBuy = State == ShopDefine.GoodsState.ForbidSingleBuy or State == ShopDefine.GoodsState.CanBuy
            if not(bCanBuy) then
                --TODO:捆绑包中不能购买的商品:已经拥有的商品/捆绑包中不能购买的:计算出已经拥有的商品的价格,目的是将这些商品要从商品总单价中移除
                OwnPrice = OwnPrice + PackGoods.PackGoodsDisCountPrice
            end
        end
        -- FinalOriginPrice = OriginPrice
        -- if DisCountPrice == 0 then
        --     DisCountPrice = 1
        --     CError("[ShopModel]GetGoodsUnitPrice DisCountPrice is zero! GoodsId:" .. GoodsId)
        -- end

        -- local TempPrice = Goods.Price
        -- if self:CheckGoodsIsInDiscount(GoodsId) then
        --     TempPrice = Goods.DisCountPrice
        -- end
        -- if TempPrice == 0 then
        --     TempPrice = DisCountPrice
        -- end
        -- ---价格向下取整
        -- FinalPrice = math.floor(TempPrice - (TempPrice / DisCountPrice * OwnPrice))

        ---结算价格计算公式:https://sarosgame.feishu.cn/wiki/M2wVwrozfiu52wk2giDcE0OAnUc
        -- (10002,10003,10016):捆绑包商品Ids -> (350,150,0):捆绑包优惠价 -> 300:为商品Buff价
        ---商品BUFF-商品折扣价格:如果玩家10003达到储存上限（该商品不为关键商品），则最终价格为(350+150+0=350)*(300/500)%=210，%向下取整至个位
        -- FinalOriginPrice = Goods.Price
        if self:CheckGoodsIsInDiscount(GoodsId) then
            FinalPrice = math.floor((Goods.Price - OwnPrice) * Goods.DisCountPrice / Goods.Price)
        else
            FinalPrice = Goods.Price - OwnPrice
        end

        WindowPrice = Goods.Price
    else
        -- FinalOriginPrice = Goods.Price
        if self:CheckGoodsIsInDiscount(GoodsId) then
            FinalPrice = Goods.DisCountPrice
            WindowPrice = Goods.DisCountPrice
        else
            FinalPrice = Goods.Price
            WindowPrice = Goods.Price
        end
    end
   
    ---@type ReferenceUnitPrice
    local ReferenceUnitPrice = {}
    ReferenceUnitPrice.CurrencyType = Goods.CurrencyType
    ReferenceUnitPrice.SettlementPrice = FinalPrice
    ReferenceUnitPrice.Price = WindowPrice
    ReferenceUnitPrice.SuggestedPrice = Goods.SuggestedPrice
    ReferenceUnitPrice.OwnPrice = OwnPrice
    ReferenceUnitPrice.USDiscount = self:CalculateDiscount(ReferenceUnitPrice.Price, ReferenceUnitPrice.SuggestedPrice)
    Goods.ReferenceUnitPrice = ReferenceUnitPrice

    Goods.IsDirty = false

    return Goods.ReferenceUnitPrice 
end

---计算折扣公式.美国式折扣-12%
function ShopModel:CalculateDiscount(Price, OriginPrice)
    Price = Price or 0
    OriginPrice = OriginPrice or 0

    local finDiscount = 0
    if Price ~= OriginPrice then
        local USDiscount = 0
        if OriginPrice > 0 then
            local CNDiscount = Price / OriginPrice 
            USDiscount = (1 - CNDiscount)
        end
        finDiscount = math.floor(USDiscount * 100)
    end
    
    return finDiscount
end

--- 获取商品品质,所有希望获取商品品质的方法都应从这里取
---@param GoodsId number
---@return ShopDefine.Quality
function ShopModel:GetGoodsQuality(GoodsId)
    if not GoodsId then
        CError("[ShopModel]GetGoodsQuality GoodsId is nil! ")
        return
    end
    ---@type GoodsItem
    local Goods = self:GetData(GoodsId)
    if not Goods then
        CError("[ShopModel]GetGoodsQuality Goods is nil! GoodsId:" .. GoodsId)
        return
    end
    if Goods.Quality > 0 then
        return Goods.Quality
    end

    local MaxQuality = 1
    if Goods.ItemId > 0 then
        MaxQuality = MvcEntry:GetModel(DepotModel):GetItemQualityByItemId(Goods.ItemId)
    end
    if Goods.PackGoodsList then
        for _, PackGoods in pairs(Goods.PackGoodsList) do
            local TempQuality = MvcEntry:GetModel(DepotModel):GetItemQualityByItemId(PackGoods.PackItemId)
            if TempQuality > MaxQuality then
                MaxQuality = TempQuality
            end
        end
    end
    Goods.Quality = MaxQuality
    return MaxQuality
end

--- 重置商品状态
function ShopModel:ResetAllGoodsState()
    ---@type GoodsItem
    local GoodsKeys = self:GetDataMapKeys()
    for _, GoodsId in pairs(GoodsKeys) do
        self:ResetGoodsState(GoodsId)
    end
end

--- 重置商品状态
---@param GoodsId number
function ShopModel:ResetGoodsState(GoodsId)
    ---@type GoodsItem
    local Goods = self:GetData(GoodsId)
    Goods.Available = false
    Goods.IsDirty = true
    Goods.BuyTimes = 0
    Goods.GoodsState = Goods.IsSingleCanBuy and ShopDefine.GoodsState.CanBuy or ShopDefine.GoodsState.ForbidSingleBuy
end

--- 商品排序
---@param GoodsItem[]
function ShopModel:SortGoodsList(GoodsList)
    ---@type GoodsItem[]
    local SortGoodsList = {}
    ---@param v GoodsItem
    for _, v in ipairs(GoodsList) do
        table.insert(SortGoodsList, v)
    end
    table.sort(SortGoodsList, function(a, b)
        if a.GoodsState ~= b.GoodsState then
            ---排序优先级:商品状态越小越靠前
            return a.GoodsState < b.GoodsState
        end

        ---排序优先级数字越大排序越靠前
        if a.Prority ~= b.Prority then
            return a.Prority > b.Prority
        else
            --  - 限时购买＞限时折扣＞常驻折扣(配置了优惠价BUFF但是没配置优惠起始/结束时间)＞其他

            local ASellSort = a.SellBeginTime > 0 and 1 or 0
            local BSellSort = b.SellBeginTime > 0 and 1 or 0

            if ASellSort ~= BSellSort then
                return ASellSort > BSellSort
            end

            local ADiscountSort = a.DisCountBeginTime > 0 and 1 or 0
            local BDiscountSort = b.DisCountBeginTime > 0 and 1 or 0

            if ADiscountSort ~= BDiscountSort then
                return ADiscountSort > BDiscountSort
            end

            local ADisPriceSort = a.DisCountPrice ~= 0 and 1 or 0
            local BDisPriceSort = b.DisCountPrice ~= 0 and 1 or 0

            if ADisPriceSort ~= BDisPriceSort then
                return ADisPriceSort > BDisPriceSort
            end

            -- if a.LimitCircle ~= b.LimitCircle then
            --     return a.LimitCircle > b.LimitCircle
            -- end
            --- 稀有度高＞稀有度低
            if a.Quality ~= b.Quality then
                return a.Quality > b.Quality
            end

            local ItemSortA = self:GetGoodsItemSortPrority(a)
            local ItemSortB = self:GetGoodsItemSortPrority(b)
            if ItemSortA ~= ItemSortB then
                return ItemSortA > ItemSortB
            end
            return a.GoodsId > b.GoodsId
        end
    end)
    return SortGoodsList
end

ShopModel.ItemTypeSortList = {
    [Pb_Enum_ITEM_TYPE.ITEM_PARAGLIDER] = 1,
    [Pb_Enum_ITEM_TYPE.ITEM_WEAPON] = 4,
    [Pb_Enum_ITEM_TYPE.ITEM_VEHICLE] = 8,
    [Pb_Enum_ITEM_TYPE.ITEM_PLAYER] = 12
}
ShopModel.ItemSubTypeSortList = {
    ["Hero"] = 1,
    ["Weapon"] = 1,
    ["Vehicle"] = 1,
    ["Skin"] = 2
}

--- 获取商品的SortId
---@param GoodsItem GoodsItem
---@return number
function ShopModel:GetGoodsItemSortPrority(GoodsItem)
    if GoodsItem.ItemId <=0 then
        return 0
    end
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, GoodsItem.ItemId)
    if not ItemCfg then
        return 0
    end
    local ItemType = ItemCfg[Cfg_ItemConfig_P.Type]
    local ItemTypeSort = self.ItemTypeSortList[ItemType] or 0
    local ItemSubType = ItemCfg[Cfg_ItemConfig_P.SubType]
    local ItemSubTypeSort = self.ItemSubTypeSortList[ItemSubType] or 0

    return ItemTypeSort + ItemSubTypeSort
end

---从配置中获取此商品能否购买的状态
---@return table{bCanBuy:boolean, Status:ShopDefine.TradingStatus}
function ShopModel:GetGoodsCanBuyInCfg(GoodsId, CategoryID)
    local OutRet = {bCanBuy = true, Status = ShopDefine.TradingStatus.OnSale}
    ---@type GoodsItem
    local Goods = self:GetData(GoodsId)
    if not Goods then
        CError(string.format("ShopCtrl:GetGoodsCanBuyInCfg Goods == nil !!! GoodsId = [%s],CategoryID = [%s]", GoodsId, CategoryID), true)
        OutRet.bCanBuy = false
        OutRet.Status = ShopDefine.TradingStatus.ForbidByNoExist
        return OutRet
    end

    if not(Goods.IsSingleCanBuy) then
        OutRet.bCanBuy = false
        OutRet.Status = ShopDefine.TradingStatus.ForbidByNoExist
        return OutRet
    end

    local CategoryIDs = { CategoryID }
    if next(CategoryIDs) == nil  then
        CategoryIDs = Goods.Category
    end
    
    for _, TempCategoryID in pairs(CategoryIDs) do
        if TempCategoryID ~= 0 then
            local CategoryCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_ShopCategoryConfig, Cfg_ShopCategoryConfig_P.CategoryId, TempCategoryID)
            if CategoryCfg then
                -- 是否提审禁充值
                if CategoryCfg[Cfg_ShopCategoryConfig_P.IsNoTopUp] then
                    -- 配置表禁止充值/交易
                    OutRet.bCanBuy = false
                    OutRet.Status = ShopDefine.TradingStatus.ForbidByCfg
                    return OutRet
                else
                    -- 可以交易
                    OutRet.bCanBuy = true
                    OutRet.Status = ShopDefine.TradingStatus.OnSale
                    return OutRet
                end
            else
                CError(string.format("ShopCtrl:GetGoodsCanBuyInCfg CategoryCfg == nil !!! GoodsId = [%s],TempCategoryID = [%s]", GoodsId, TempCategoryID), true)
            end
        end
    end

    -- 可以交易
    OutRet.bCanBuy = true
    OutRet.Status = ShopDefine.TradingStatus.OnSale
    return OutRet
end

function ShopModel:SetCurTabIndex(InIndex)
    self.CurTabIndex = InIndex
    local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
    EventTrackingModel:SetShopItemLoadIndex(0)
    EventTrackingModel:ClearShopItemsIdTemp()
end

function ShopModel:GetCurTabIndex()
    return self.CurTabIndex
end

function ShopModel:SetLastOnUnHoverGoodsId(InLastGoodsId)
    self.InLastGoodsId = InLastGoodsId
end

function ShopModel:GetLastOnUnHoverGoodsId()
    return self.InLastGoodsId
end

---@return ShopTabLSCfg
function ShopModel:GetShopTabLSCfg(InLSState)
    for k, Cfg in pairs(ShopDefine.ShopTabLSCfgs) do
        if Cfg.LSState == InLSState then
            return Cfg
        end
    end
    return nil
end

return ShopModel
