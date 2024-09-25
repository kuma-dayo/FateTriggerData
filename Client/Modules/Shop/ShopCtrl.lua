require("Client.Modules.Shop.ShopModel")
require("Client.Modules.Shop.ShopDefine")

local class_name = "ShopCtrl"
---@class ShopCtrl : UserGameController
---@field private super UserGameController
ShopCtrl = ShopCtrl or BaseClass(UserGameController, class_name)

function ShopCtrl:__init()
    CWaring("==ShopCtrl init")
    ---@type ShopModel 商城Mode
    self.Model = nil
    ---@type DepotModel
    self.DepotModel = nil
end

function ShopCtrl:Initialize()
    self.Model = self:GetModel(ShopModel)
    self.DepotModel = self:GetModel(DepotModel)
    self:DataInit()
end

--- 玩家登出
---@param data any
function ShopCtrl:OnLogout(data)
    CWaring("ShopCtrl OnLogout")
    self:DataInit()
end

function ShopCtrl:OnLogin(data)
    CWaring("ShopCtrl OnLogin")
    self.Model:InitShopConfig()
    self:RequestShopGoodsListInfo()
end

function ShopCtrl:DataInit()
    self.GoodId2BuySucCallBackList = {}
end

function ShopCtrl:AddMsgListenersUser()
    self.ProtoList = {
        {MsgName = Pb_Message.PlayerShopGoodInfoListRsp, Func = self.OnPlayerShopGoodsInfoListRsp},
        {MsgName = Pb_Message.PlayerBuyGoodRsp, Func = self.OnPlayerBuyGoodRsp},
        {MsgName = Pb_Message.PlayerShopClearLimitNotify, Func = self.OnPlayerShopClearLimitNotify},
        {MsgName = Pb_Message.PlayerRechargeRsp, Func = self.OnPlayerRechargeNotify},
    }
    self.MsgList = {
        { Model = DepotModel, MsgName = ListModel.ON_UPDATED, Func = self.OnDepotModelChanged },
        -- {Model = DepotModel, MsgName = ListModel.ON_UPDATED_MAP_CUSTOM, Func = self.ON_UPDATED_MAP_CUSTOM_Func },
    }
end

function ShopCtrl:OnDepotModelChanged()
    print("ShopCtrl:OnDepotModelChanged")
    self.Model:InitShopConfig()
    self.Model:HandleAllGoodState()
end

function ShopCtrl:OnPlayerShopClearLimitNotify(Res)
    -- print_r(Res, "ShopCtrl:OnPlayerShopClearLimitNotify")
    self.Model:SetDirtyByType(ShopModel.DirtyFlagDefine.TimeStateChanged, true)
    self:CheckIsNeedRefreshByTime()
end

function ShopCtrl:OnPlayerShopGoodsInfoListRsp(Res)
    CLog(string.format("ShopCtrl:OnPlayerShopGoodsInfoListRsp, bNeedResetAllGoodsState = %s, Res = %s", tostring(self.bNeedResetAllGoodsState),table.tostring(Res)))
    -- CWaring(string.format("ShopCtrl:OnPlayerShopGoodsInfoListRsp, bNeedResetAllGoodsState = %s, Res = %s", tostring(self.bNeedResetAllGoodsState),table.tostring(Res)))

    if self.bNeedResetAllGoodsState then
        self.bNeedResetAllGoodsState = false
        self.Model:ResetAllGoodsState()
    end
    self.Model:HandleShopGoodsInfo(Res)
end

function ShopCtrl:OnPlayerBuyGoodRsp(Res)
    CLog(string.format("ShopCtrl:OnPlayerBuyGoodRsp, Res = %s",table.tostring(Res)))
    self.Model:HandleShopGoodsLimitTimes(Res)
    local GoodsId = Res.GoodId

    local CallBackList = self.GoodId2BuySucCallBackList[GoodsId] or {}
    for k,v in ipairs(CallBackList) do
        v()
    end
    self.GoodId2BuySucCallBackList[GoodsId] = nil
end

--- 客户端请求某些商品的信息
function ShopCtrl:RequestShopGoodsListInfo()
    local UtcNow = UE.UKismetMathLibrary.UtcNow()
    if self.LastReqTime then
        local tt = UE.UKismetMathLibrary.Subtract_DateTimeDateTime(UtcNow, self.LastReqTime)
        local tt2 = UE.UKismetMathLibrary.GetTotalMilliseconds(tt)
        if tt2 < 200 then
            --消息间隔< 200 ms跳过
            if UE.UGFUnluaHelper.IsEditor() then
                CWaring("ShopCtrl:RequestShopGoodsListInfo, < 200ms skip !!!!", true)
            else
                CWaring("ShopCtrl:RequestShopGoodsListInfo, < 200ms skip !!!!")
            end
            return
        end
    end
    self.LastReqTime = UtcNow

    local ShopIdList = self.Model:GetDataMapKeys()
    if #ShopIdList == 0 then
        return
    end
    local Msg = {
        GoodIdList = ShopIdList
    }
    
    CLog(string.format("ShopCtrl:RequestShopGoodsListInfo, to Send Msg = %s", table.tostring()))
    self.bNeedResetAllGoodsState = true
    self:SendProto(Pb_Message.PlayerShopGoodInfoListReq, Msg)
end

--- 通用商品购买协议
---@param GoodsId number
---@param GoodCount number
---@param NotDropPrizeItemSyn boolean  默认为false 为真表示购买成功之后不同步奖励获取协议（触发奖励获取界面展示）
function ShopCtrl:SendPlayerBuyGoodReq(GoodsId, GoodCount,NotDropPrizeItemSyn)
    if not GoodsId then
        CError("GoodsId is nil!", true)
        return
    end
    GoodCount = GoodCount or 1

    --[[
        string ReferSource = 4;         // 购买来源，埋点数据时，使用，客户端赋值
        string EnterShopSource = 5;     // 进入商城方式
    ]]

    local EventTrackingModel = MvcEntry:GetModel(EventTrackingModel)
    local Msg = {
        GoodId = GoodsId,
        GoodCount = GoodCount,
        NotDropPrizeItemSyn = NotDropPrizeItemSyn or false,
        ReferSource = EventTrackingModel:GetNowViewId(),
        EnterShopSource = EventTrackingModel:GetShopEnterSource()
    }

    self:SendProto(Pb_Message.PlayerBuyGoodReq, Msg, Pb_Message.PlayerBuyGoodRsp)
end

--- 通用商品购买逻辑
---@param GoodsId number
---@param GoodCount number
---@param ForceBuy boolean 是否跳过二级购买确定的弹窗
function ShopCtrl:RequestBuyShopItem(GoodsId, GoodCount, ForceBuy)
    ForceBuy = ForceBuy or false
    GoodCount = GoodCount or 1

    if not self:CheckCanBuyGoods(GoodsId, GoodCount, true) then
        return
    end

    ---@type GoodsItem
    local Goods = self.Model:GetData(GoodsId)
    if Goods == nil then
        CError("ShopCtrl:RequestBuyShopItem Goods == nil")
        return
    end
 
    local ItemName = self.DepotModel:GetItemName(Goods.CurrencyType)
    local Balance = self.DepotModel:GetItemCountByItemId(Goods.CurrencyType)

    ---@type SettlementSum
    local SettlementSum = self:GetGoodsPrice(GoodsId, GoodCount)
    local Cost = SettlementSum.TotalSettlementPrice
	if Goods.CurrencyType ~= ShopDefine.CurrencyType.MONEY and Balance < Cost then
        -- 货币不足，购买失败。
        UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Insufficientcurrency"), ItemName))
		return
	end

    -- 确定要花 {0}{1} 购买吗？
    local describe = CommonUtil.GetBuyCostDescribeText(Goods.CurrencyType, Cost)
    local bUpToMax, ItemId, Diff = self:CheckIsUpToMax(GoodsId, GoodCount)
    local WarningDec = nil
    if bUpToMax then
        local UpToMaxItemName = self.DepotModel:GetItemName(ItemId)
        -- 购买后{0}将超出储存上限{1}个，超出部分无法获得。
        WarningDec = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Afterpurchasewillexc"), UpToMaxItemName,Diff)
        ForceBuy = false
    end

    if ForceBuy then
        if Goods.RechargeInfo then
            self:SendPlayerRechargeReq(GoodsId, Goods.RechargeInfo.RechargeId)
        else
            self:SendPlayerBuyGoodReq(GoodsId, GoodCount)
        end
        return
    end

	local msgParam = {
		describe = describe,
        warningDec = WarningDec,
		leftBtnInfo = {},
		rightBtnInfo = {
			callback = function()
                --CError("----超出存储上线我也要买!!!!!!")
                if Goods.RechargeInfo then
                    self:SendPlayerRechargeReq(GoodsId, Goods.RechargeInfo.RechargeId)
                else
                    self:SendPlayerBuyGoodReq(GoodsId, GoodCount)
                end
			end
		}
	}
	UIMessageBox.Show(msgParam)
end

--[[
    检查代币是否足够
    - 代币不足时，但需要的充值货币充足时，弹确认弹窗询问玩家是否用对应数量充值货币兑换抽奖代币
    - 代币与充值货币的兑换关系配置在商品表中
    - 代币不足，需要的充值货币也不足时，弹窗提示兑换对应的抽奖代币还需充值货币数量。
]]
function ShopCtrl:CheckShopItemEnoughThenAction(ItemId,GoodsId,GoodCount,SucCallback,NotDropPrizeItemSyn)
    if self.DepotModel:IsEnoughByItemId(ItemId,GoodCount) then
        return true
    end
    if not self:CheckCanBuyGoods(GoodsId, GoodCount, true) then
        -- GoodsId商品不存在
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop","GoodNotFound"))
        return false
    end

    local Goods = self.Model:GetData(GoodsId)
    local ItemName = self.DepotModel:GetItemName(Goods.CurrencyType)
    local Balance = self.DepotModel:GetItemCountByItemId(Goods.CurrencyType)
    
    -- ---@type ReferenceUnitPrice
    -- local PriceBook = self.Model:GetGoodsUnitPrice(GoodsId)
    -- local UnitPrice = PriceBook.SettlementPrice
    -- local Cost = UnitPrice * GoodCount

    ---@type SettlementSum
    local SettlementSum = self:GetGoodsPrice(GoodsId, GoodCount)
    local Cost = SettlementSum.TotalSettlementPrice

	if Balance < Cost then
        local msgParam = {
            describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop","ItemNotEnough"),ItemName),
            leftBtnInfo = {},
            rightBtnInfo = {
                callback = function()
                    --TODO 跳往充值界面
                    MvcEntry:GetCtrl(ViewJumpCtrl):JumpTo(JumpCode.ChargeCurrencyBuy.JumpId)
                end
            }
        }
        UIMessageBox.Show(msgParam)
		return false
	end

    --{0}不足，是否消耗 {1}{2} 购买？
    local describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop","ItemNotEnoughNeedCostBuy"),StringUtil.GetRichTextImgForId(ItemId),StringUtil.GetRichTextImgForId(Goods.CurrencyType), Cost)
    local msgParam = {
        describe = describe,
        leftBtnInfo = {},
        rightBtnInfo = {
            callback = function()
                --TODO 购买
                self.GoodId2BuySucCallBackList[GoodsId] = self.GoodId2BuySucCallBackList[GoodsId] or {}
                table.insert(self.GoodId2BuySucCallBackList[GoodsId],SucCallback)
                self:SendPlayerBuyGoodReq(GoodsId, GoodCount,NotDropPrizeItemSyn)
            end
        }
    }
    UIMessageBox.Show(msgParam)
    return false
end

--[[
    检查货币是否足够，不足够支持直接跳转到钻石购买界面

    - 点击购买，货币充足则弹出购买确认弹窗“是否消耗xxx购买”。货币不足则跳转充值界面

    local Param = {
        ItemId = 0,
        Cost = 0,
        SucTipStr = 0,   --可选
        --可选
        SucThenActionCallback = function()
            
        end,
        --可选
        FailCallback = function()
            
        end,
        --可选，默认跳到钻石购买界面
        JumpId = 0,
    }
]]
function ShopCtrl:CheckItemEnoughThenAction(Param,NeedFailedDialog)
    local Balance = self.DepotModel:GetItemCountByItemId(Param.ItemId)
    if not Param.JumpId then
        Param.JumpId = JumpCode.ChargeCurrencyBuy.JumpId
    end
    if Balance >= Param.Cost then
        local Describe = Param.SucTipStr
        if not Describe then
            --是否消耗{0}{1}购买？
            -- Describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop","ConfirmToBuy"),StringUtil.GetRichTextImgForId(Param.ItemId), Param.Cost)
            Describe = CommonUtil.GetBuyCostDescribeText(Param.ItemId, Param.Cost) --确定要花 {0}{1} 购买吗？
        end
        local msgParam = {
            describe = Describe,
            leftBtnInfo = {},
            rightBtnInfo = {
                callback = function()
                    if Param.SucThenActionCallback then
                        Param.SucThenActionCallback()
                    end
                end
            }
        }
        UIMessageBox.Show(msgParam)
    else
        if NeedFailedDialog then
            local ItemName = self.DepotModel:GetItemName(Param.ItemId)
            local msgParam = {
                describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Shop","ItemNotEnough"),ItemName),
                leftBtnInfo = {},
                rightBtnInfo = {
                    callback = function()
                        --TODO 跳往充值界面
                        MvcEntry:GetCtrl(ViewJumpCtrl):JumpTo(JumpCode.ChargeCurrencyBuy.JumpId)
                    end
                }
            }
            UIMessageBox.Show(msgParam)
        else
            if Param.JumpId then
                MvcEntry:GetCtrl(ViewJumpCtrl):JumpTo(Param.JumpId)
            end
        end
        if Param.FailCallback then
            Param.FailCallback()
        end
    end
end

--- 检测是否商品内的物品达到物品存储上限
---@param GoodsId any
---@param GoodCount any
---@param NeedAlert any
---@return boolean:是否超出,number:物品ID,number:超出的数量
function ShopCtrl:CheckIsUpToMax(GoodsId, GoodCount)
    ---@type DepotModel
    local DepotModel = MvcEntry:GetModel(DepotModel)
    ---@type GoodsItem
    local Goods = self.Model:GetData(GoodsId)

    if Goods.PackGoodsMap and next(Goods.PackGoodsMap) then
        ---如果是捆绑包
        local ItemNum = 0
        for ItemId, PGoodsList in pairs(Goods.PackGoodsMap) do
            for _, PackGoods in pairs(PGoodsList) do
                ItemNum = PackGoods.PackItemNum * GoodCount
            end
 
            local State, Diff = DepotModel:IsItemUpToMaxNum(ItemId, ItemNum)
            if State then
                return State, ItemId, Diff
            end
        end
    else
        local ItemId = Goods.ItemId
        local ItemNum = Goods.ItemNum * GoodCount
        local State, Diff = DepotModel:IsItemUpToMaxNum(ItemId,ItemNum)
        if State then
            return State, ItemId, Diff
        end
    end
    return false,0,0
end

--- 通用商品购买逻辑
---@param GoodsId number
function ShopCtrl:CheckCanBuyGoods(GoodsId, GoodCount, NeedAlert)
    NeedAlert = NeedAlert or false

    ---检查商品是否可交易：是不是配置表禁止购买/不存在等因素/提审禁止充值
    if not self:CheckTradingStatusCanBuy(GoodsId, NeedAlert) then
        return false
    end

    ---@type GoodsItem
    local Goods = self.Model:GetData(GoodsId)
    if not Goods then
        CError("ShopCtrl:CheckCanBuyGoods Goods nil:" .. GoodsId)
        return false
    end
    local NowTimeStamp = GetTimestamp()
    if Goods.SellBeginTime > 0 and NowTimeStamp < Goods.SellBeginTime 
    or Goods.SellEndTime > 0 and NowTimeStamp > Goods.SellEndTime then
        if NeedAlert then
            -- 非售卖时段
            UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Cantbuynotforsale"))
        end
        return false
    end
    if Goods.GoodsState == ShopDefine.GoodsState.OutOfSell then
        if NeedAlert then
            -- 已售罄
            UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Itissoldoutandcannot"))
        end
        return false
    end
    if Goods.GoodsState == ShopDefine.GoodsState.Have or Goods.GoodsState == ShopDefine.GoodsState.UpToMax then
        if NeedAlert then
            -- 已达到拥有数量上限，无法购买。
            UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Youhavereachedthemax"))
        end
        return false
    end
    if self.Model:IsUpToMaxLimitTimes(GoodsId, GoodCount) then
        if NeedAlert then
            -- 无法购买，商品已达最大限购数量。
            UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Unabletopurchasetheg"))
        end
        return false
    end
    if Goods.PackGoodsList then
        local State = false
        for _, PackGoods in pairs(Goods.PackGoodsList) do
             if self:CheckCanBuyGoods(PackGoods.PackGoodsId) then
                -- 捆绑包中只要有一个商品可以购买,那么这个捆绑包就可以购买
                State = true
             end
        end
        if not State and NeedAlert then
            -- 已达到拥有数量上限，无法购买。
            UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Youhavereachedthemax"))
        end
        return State
    end
    return true
end

---@class SettlementSum 结算账单
---@field GoodsId number 商品Id
---@field Count number 数量
---@field CurrencyType number 货币Id
---@field TotalSettlementPrice number 结算价格.总计
---@field TotalPrice number 货柜上的价格.总计.捆绑包是优惠价之和
---@field TotalSuggestedPrice number 厂家建议价格.总计
---@field TotalOwnPrice number 拥有商品价格.总计
---@field Discount number 美式折扣
--- 获取商品价格
---@return SettlementSum
function ShopCtrl:GetGoodsPrice(GoodsId, Count)
    Count = Count or 1

    ---@type ReferenceUnitPrice
    local PriceBook = self.Model:GetGoodsUnitPrice(GoodsId)

    local TotalSettlementPrice = math.floor(PriceBook.SettlementPrice * Count)
    local TotalPrice = math.floor(PriceBook.Price * Count)
    local TotalSuggestedPrice = math.floor(PriceBook.SuggestedPrice * Count)
    local TotalOwnPrice = math.floor(PriceBook.OwnPrice * Count)

    ---@type SettlementSum
    local Invoice = {
        GoodsId = GoodsId,
        Count = Count,
        CurrencyType = PriceBook.CurrencyType,
        TotalSettlementPrice = TotalSettlementPrice,
        TotalPrice = TotalPrice,
        TotalSuggestedPrice = TotalSuggestedPrice,
        TotalOwnPrice = TotalOwnPrice,
        Discount = PriceBook.USDiscount
    }
    return Invoice
end

--- 将价格转换根据状态为字符串
---@param State ShopDefine.GoodsState
function ShopCtrl:ConvertState2String(State, InRowKey)
    local PriceStr,Color = nil,nil
    if State == ShopDefine.GoodsState.OutOfSell then
        PriceStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Soldout")) --已售罄
        Color = "#E47A30"
    elseif State == ShopDefine.GoodsState.UpToMax then
        PriceStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Thestoragelimithasbe")) --已达储存上限
        Color = "#E47A30"
    elseif State == ShopDefine.GoodsState.Have then
        if InRowKey then
            PriceStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', InRowKey))
        else
            PriceStr = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Alreadyowned_Btn")) --已拥有
        end
        
        Color = "#3AF9C3"
    end
    return PriceStr, Color
end

--- 检测是否需要刷新
function ShopCtrl:CheckIsNeedRefreshByTime(IsForce)
    print("ShopCtrl:CheckIsNeedRefreshByTime IsForce = " .. tostring(IsForce))
    IsForce = IsForce or false
    if not(IsForce) and not(self.Model:IsDirtyByType(ShopModel.DirtyFlagDefine.TimeStateChanged)) then
        return
    end
    print("ShopCtrl:CheckIsNeedRefreshByTime 检测是需要刷新 !!!")
    self.Model:SetDirtyByType(ShopModel.DirtyFlagDefine.TimeStateChanged, false)
    -- self.Model:ResetAllGoodsState()
    self:RequestShopGoodsListInfo()
    -- CError("==========================CheckIsNeedRefreshByTime")
end

---返回商品能否被交易的状态
---@return ShopDefine.TradingStatus
function ShopCtrl:GetTradingStatus(GoodsId, CategoryID)
    local RetVal = self.Model:GetGoodsCanBuyInCfg(GoodsId, CategoryID)
    return RetVal.Status
end

---检查商品是否可交易：是不是配置表禁止购买/不存在等因素/提审禁止充值
---@param CategoryID table:{CategoryID:number}
---@return boolean true 代表可交易
function ShopCtrl:CheckTradingStatusCanBuy(GoodsId, bNeedAlert, Param)
    Param = Param or {}
    local TradingStatus = self:GetTradingStatus(GoodsId, Param.CategoryID)
    if TradingStatus == ShopDefine.TradingStatus.OnSale then
        return true
    end

    if bNeedAlert then
        self:ShowForbidMessageBox(TradingStatus)
    end

    return false
end

function ShopCtrl:ShowForbidMessageBox(TradingStatus)
    local describe = ""
    if TradingStatus == ShopDefine.TradingStatus.ForbidByCfg then
        -- 游戏尚未正式上线，未开通充值付费
        describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_Thegamehasnotbeenoff"))
    elseif TradingStatus == ShopDefine.TradingStatus.ForbidByNoExist then
        -- 商品不存在
        describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "GoodNotFound"))
    elseif TradingStatus == ShopDefine.TradingStatus.ForbidByOther then
        -- 未知的原因
        describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "GoodNotFound"))
    end
    local msgParam = {
        describe = describe,
        leftBtnInfo = {},
        rightBtnInfo = {
            callback = function()
            end
        }
    }
    UIMessageBox.Show(msgParam)
end

-- ---检查交易状态并请求购买
-- ---@param Param table:{TradingStatus:ShopDefine.TradingStatus, ForceBuy:boolean}
-- function ShopCtrl:CheckTradingStatusAndRequestBuyShopItem(GoodsId, Num, Param)
--     Param = Param or {}
--     if Param.TradingStatus and Param.TradingStatus ~= ShopDefine.TradingStatus.OnSale then
--         self:ShowForbidMessageBox(Param.TradingStatus)
--         return
--     end

--     ---@type GoodsItem
--     local Goods = self.Model:GetData(GoodsId)
--     if not Goods then
--         CError(string.format("ShopCtrl:CheckTradingStatusAndRequestBuyShopItem Goods == nil !!! GoodsId = [%s]", GoodsId), true)
--         return
--     end

--     self:RequestBuyShopItem(GoodsId, Num, Param.ForceBuy)
-- end

---打开商品详情
---@param Param table:{bCheckCanBuy:boolean.检查是否能够买,能够买才打开}
function ShopCtrl:OpenShopDetailView(GoodsId, Param)
    Param = Param or {}

    if Param.bCheckCanBuy then
        if not self:CheckCanBuyGoods(GoodsId, 1, true) then
            return false
        end
    end

    local bIsJumpCtrl = Param.bIsJumpCtrl or false

    ---@type GoodsItem
    local Goods = self.Model:GetData(GoodsId)
    local ViewId = Goods.IsOpenFullDetail and ViewConst.ShopDetail or ViewConst.ShopDetailPop
    local TempParam = { Goods = Goods, bInTheShop = not(bIsJumpCtrl) }
    MvcEntry:OpenView(ViewId, TempParam)

    return true
end

--- 玩家充值
---@param RechargeId number, 充值的挡位
function ShopCtrl:SendPlayerRechargeReq(GoodsId, RechargeId)
    local Msg = {
        RechargeId = RechargeId,
    }
    self:SendProto(Pb_Message.PlayerRechargeReq, Msg, Pb_Message.PlayerRechargeRsp)
end

--- 玩家充值返回
---@param RechargeId number, 充值的挡位
function ShopCtrl:OnPlayerRechargeNotify(Msg)
    CLog("RechargeId = "..Msg.RechargeId)

    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_RechargeConfig, Msg.RechargeId)
    if Cfg == nil then
        CError("ShopCtrl:OnPlayerRechargeNotify Cfg == nil !! Msg = "..table.tostring(Msg))
        return 
    end

    local GoodsId = Cfg[Cfg_RechargeConfig_P.GoodsId]
    local Res = { GoodId = GoodsId, HadBuyCount = Msg.HadBuyCount or 0}
    self.Model:HandleShopGoodsLimitTimes(Res)

    local CallBackList = self.GoodId2BuySucCallBackList[GoodsId] or {}
    for k,v in ipairs(CallBackList) do
        v()
    end
    self.GoodId2BuySucCallBackList[GoodsId] = nil
end

---计算折扣公式
function ShopCtrl:CalculateDiscount(Price, OriginPrice)
    local finDiscount = self.Model:CalculateDiscount(Price,OriginPrice)
    return finDiscount
end

function ShopCtrl:SetTabListOnHoverMark(bOnHover)
    self.bOnHoverMark = bOnHover
end

function ShopCtrl:GetTabListOnHoverMark()
    return self.bOnHoverMark or false
end

-- function ShopCtrl:SetLastShowParam(LastParam)
--     self.LastParam = LastParam
-- end

-- function ShopCtrl:GetLastShowParam()
--     return self.LastParam
-- end

-- ---@param Param table {ItemId:number.,CurrencyId:number,CostNum:number,}
-- function ShopCtrl:RequestBuyDropByItemId(Param)
--     local CurrencyId = Param.CurrencyId or 0
--     local CostNum = Param.CostNum or 0
--     local BuyType = Param.BuyType or CommonConst.BuyType.DEFAULT
--     local OwnerNum = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(CurrencyId)

--     local describe = ""
--     if CostNum > OwnerNum then
--         local CurrencyName = MvcEntry:GetModel(DepotModel):GetItemName(CurrencyId)
--         if BuyType == 1 then
--             ---{0}不够，无法解锁！
--             describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Arsenal", "10008"), CurrencyName) 
--         else

--         end
--     else
--         if Param == CommonConst.BuyType.UNLOCK then
--             -- Lua_ShopCtrl_SureWantToUnlock --确定要花 {0}{1} 解锁吗？
--             describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_SureWantToUnlock"), StringUtil.GetRichTextImgForId(CurrencyId), CostNum)
--         else
--             -- Lua_ShopCtrl_SureWantToBuy 确定要花 {0}{1} 购买吗？
--             describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_SureWantToBuy"), StringUtil.GetRichTextImgForId(CurrencyId), CostNum)
--         end
--     end

--     local msgParam = {
-- 		describe = describe,
--         warningDec = WarningDec,
-- 		leftBtnInfo = {},
-- 		rightBtnInfo = {
-- 			callback = function()
--                 --CError("----超出存储上线我也要买!!!!!!")
--                 if Goods.RechargeInfo then
--                     self:SendPlayerRechargeReq(GoodsId, Goods.RechargeInfo.RechargeId)
--                 else
--                     self:SendPlayerBuyGoodReq(GoodsId, GoodCount)
--                 end
-- 			end
-- 		}
-- 	}
-- 	UIMessageBox.Show(msgParam)

--     -- CommonUtil.SetBorderBrushColorFromHex
-- end