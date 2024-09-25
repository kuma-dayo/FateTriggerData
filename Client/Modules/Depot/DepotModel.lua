--[[
    仓库数据模型
]]
local super = ListModel;
local class_name = "DepotModel";

---@class DepotModel : ListModel
---@field private super ListModel
DepotModel = BaseClass(super, class_name);

DepotModel.ON_DEPOT_DATA_INITED = "ON_DEPOT_DATA_INITED"
--物品使用后返回结果
DepotModel.ON_ITEM_USE_RESULT = "ON_ITEM_USE_RESULT"
DepotModel.ON_ITEM_CHANGED = "ON_ITEM_CHANGED"





function DepotModel:__init()
    self:_dataInit()
    --排序规则
    --[[
        - 限时道具最优先显示，距离过期时间越短，越优先显示
        - 非限时道具，稀有度越高越优先显示
        - 同一优先级下，itemID越小越优先显示
    ]]
    self.keepSortIndexFunc = function(a,b)
        if a.ExpireTime > 0 and b.ExpireTime > 0 then
            return a.ExpireTime < b.ExpireTime
        elseif a.ExpireTime <= 0 and b.ExpireTime > 0 then
            return false
        elseif a.ExpireTime > 0 and b.ExpireTime <= 0 then
            return true
        else
            local Cfg_A =  G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,a.ItemId)
            local Cfg_B =  G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,b.ItemId)
            if Cfg_A and Cfg_B then
                local Quality_A = Cfg_A[Cfg_ItemConfig_P.Quality]
                local Quality_B = Cfg_B[Cfg_ItemConfig_P.Quality]
                if Quality_A ~= Quality_B then
                    return Quality_A > Quality_B
                else
                    return a.ItemId < b.ItemId
                end
            end
        end
    end
end

-- // 物品结构
-- message ItemInfoNode
-- {
--     int64 ItemId        = 1;    // 物品Id
--     int64 ItemNum       = 2;    // 物品数量
--     int64 ExpireTime    = 3;    // 过期截止时间戳，UT0时间，为0是永久物品
--     int64 ItemUniqId    = 4;    // 个人物品唯一Id,比如用来区分两个物品Id相同，过期时间不同
-- }
function DepotModel:_dataInit()
    self:Clean()
    --总列表
    self.ItemList = {}  
    --背包总列表
    self.DepotItemList = {}
    --类型对应列表
    self.ItemType2List = {}
    --类型对应列表（背包内）
    self.ItemType2DepotList = {}
    --物器配置ID对应数量
    self.ItemId2Count = {}
    --物品列表是否Dirty  为true的情况下，取值会触发计算
    self.ItemType2ListDirty = true
end


--[[
    玩家登出时调用
]]
function DepotModel:OnLogout(data)
    DepotModel.super.OnLogout(self)
    self:_dataInit()
end


--[[
    重写父方法，返回唯一Key
]]
function DepotModel:KeyOf(vo)
    return vo["ItemUniqId"]
end
--[[
    重写父方法，返回自定义唯一Key
]]
function DepotModel:CustomKeyOf(vo)
    return vo["ItemId"]
end

--[[
    重写父方法，判断物品是否可移除
]]
function DepotModel:IsValidOf(vo)
    if vo["ItemNum"] and vo["ItemNum"] > 0 then
        if vo.ExpireTime > 0 then
            if vo.ExpireTime > GetTimestamp() then
                return true
            end
        else
            return true
        end
    end
    return false
end

--[[
    重写父类方法，如果数据发生改变
    进行通知到这边的逻辑
]]
function DepotModel:SetIsChange(value)
    DepotModel.super.SetIsChange(self,value)
    if value then
        self.ItemType2ListDirty = true
    end
end

--[[
    重写父方法，更新列表数据
]]
function DepotModel:UpdateDatas(itemList,fullCheck)
    local stateList,map = DepotModel.super.UpdateDatas(self,itemList,fullCheck) 
    MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.CHECK_ITEM_COUNT_CORNER_TAG)
end

function DepotModel:CalculateItemType2ListDirty()
    if self.ItemType2ListDirty then
        self.ItemType2ListDirty = false
        self.ItemList = {}  -- 总列表
        self.ItemType2List = {} -- 分类列表
        self.DepotItemList = {}
        self.ItemType2DepotList = {}
        self.ItemId2Count = {}
        local dict = self:GetDataList() -- Vo数据参考 ItemInfoNode
        for _,Vo in ipairs(dict) do
            self.ItemId2Count[Vo.ItemId] = self.ItemId2Count[Vo.ItemId] or 0
            self.ItemId2Count[Vo.ItemId] = self.ItemId2Count[Vo.ItemId] + Vo.ItemNum
            local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,Vo.ItemId)
            if ItemCfg then
                local ItemType = ItemCfg[Cfg_ItemConfig_P.Type] -- 物品类别
                self.ItemType2List[ItemType] = self.ItemType2List[ItemType] or {}    
                self.ItemType2DepotList[ItemType] = self.ItemType2DepotList[ItemType] or {}
                local isDepot = ItemCfg[Cfg_ItemConfig_P.IsDepot]
                
                local cTime = GetTimestamp()
                if Vo.ExpireTime == 0 or
                    (Vo.ExpireTime > 0 and Vo.ExpireTime > cTime) then
                    -- 永久物品 / 未过期的限时物品
                    --  需要根据上限进行拆组
                    local MaxStackNum = ItemCfg[Cfg_ItemConfig_P.MaxStackNum]
                    if MaxStackNum > 0 then
                        local curCount = Vo.ItemNum
                        while (curCount > MaxStackNum) do
                            local ItemInfo = DeepCopy(Vo)
                            ItemInfo.ItemNum = MaxStackNum
                            curCount = curCount - MaxStackNum
                            self:InsertItemInfo(ItemType,ItemInfo,isDepot)
                        end
                        if curCount > 0 then
                            local ItemInfo = DeepCopy(Vo)
                            ItemInfo.ItemNum = curCount
                            self:InsertItemInfo(ItemType,ItemInfo,isDepot)
                        end
                    else
                        self:InsertItemInfo(ItemType,Vo,isDepot)
                    end
                else
                    CWaring("expire time:" .. Vo.ItemId .. "|EndTime:" .. Vo.ExpireTime .. "|CTime:" .. cTime)
                end
            end
        end
        -- print_r(self.ItemType2List)
        -- print_r(self.ItemType2List[pb_Item_EItemHeadType.ItemHeadTypeNone])
        -- print_r(self.UniqueKey2Count)
        -- print_r(self.ItemType2DepotList)
    end
end

function DepotModel:InsertItemInfo(ItemType,ItemInfo,isDepot)
    table.insert(self.ItemType2List[ItemType],ItemInfo)
    self.ItemList[#self.ItemList + 1] = ItemInfo
    if isDepot then
        -- 仓库中展示的物品
        table.insert(self.ItemType2DepotList[ItemType],ItemInfo)
        self.DepotItemList[#self.DepotItemList + 1] = ItemInfo
    end
end

--移除物品
function DepotModel:RemoveItem(ItemUniqId)
    self:DeleteData(ItemUniqId)
end

--[[
    获取相同类型的物品列表
    ItemType 为空或为0 则返回所有物品
    SubTypes 筛选指定物品子类的物品
]]
function DepotModel:GetItemListByType(ItemType,SubTypes)
    self:CalculateItemType2ListDirty();
    if not ItemType or ItemType == 0  then
        return self.ItemList
    elseif not SubTypes or #SubTypes == 0 then
        return self.ItemType2List[ItemType] or {}
    else
        local TypeList = self.ItemType2List[ItemType] or {}
        return self:FilterSubTypes(TypeList,SubTypes)
    end
end

--[[
    获取相同类型的仓库物品列表
    ItemType 为空或为0 则返回所有仓库物品
    SubTypes 筛选指定物品子类的物品
]]
function DepotModel:GetDepotItemList(ItemType,SubTypes)
    self:CalculateItemType2ListDirty();
    if not ItemType or ItemType == 0 then
        return self.DepotItemList
    elseif not SubTypes or #SubTypes == 0 then
        return self.ItemType2DepotList[ItemType] or {}
    else
        local TypeList = self.ItemType2DepotList[ItemType] or {}
        return self:FilterSubTypes(TypeList,SubTypes)
    end
end

-- 筛选物品子类
function DepotModel:FilterSubTypes(TypeList,SubTypes)
     local CheckInSubTypeList = function(TargetSubType)
         for _,SubType in ipairs(SubTypes) do
             if TargetSubType == SubType then
                 return true
             end
         end
         return false
     end

     local List = {}
     for _,ItemInfo in ipairs(TypeList) do
         local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemInfo.ItemId)
         if Cfg and CheckInSubTypeList(Cfg[Cfg_ItemConfig_P.SubType]) then
             List[#List + 1] = ItemInfo
         end
     end
     return List
end

--判断两个物品是否相同
function DepotModel:IsSameItem(Item1,Item2)
    if Item1 == nil or Item2 == nil then
        return false
    end
    return (Item1.ItemUniqId == Item2.ItemUniqId)
end

--[[
    获取对应物品的数量
    ItemUniqId  物品唯一ID
]]
function DepotModel:GetItemCountByUniqId(ItemUniqId)
    self:CalculateItemType2ListDirty()
    local Vo = self:GetData(ItemUniqId)
    return (Vo and Vo.ItemNum or 0)
end

--[[
    获取对应物品的数量
    ItemId 物品配置ID
    Param {bDisassociate:bool.取消关联.默认值为false.代表是关联的} bDisassociate=true 时代表获取钻石(ItemId=DepotConst.ITEM_ID_DIAMOND)数量时,不包含免费钻石(ItemId=DepotConst.ITEM_ID_DIAMOND_GIFT)的数量
]]
function DepotModel:GetItemCountByItemId(ItemId, Param)
    self:CalculateItemType2ListDirty()
    Param = Param or {}
    if ItemId == DepotConst.ITEM_ID_DIAMOND and not(Param.bDisassociate) then
        -- 获取钻石数量. bDisassociate=true 时代表获取钻石(ItemId=DepotConst.ITEM_ID_DIAMOND)数量时,不包含免费钻石(ItemId=DepotConst.ITEM_ID_DIAMOND_GIFT)的数量
        return (self.ItemId2Count[ItemId] or 0) + (self.ItemId2Count[DepotConst.ITEM_ID_DIAMOND_GIFT] or 0)
    end
    return self.ItemId2Count[ItemId] or 0
end

--[[
    获取对应物品的最大数量
    ItemId  物品配置ID
]]
function DepotModel:GetItemMaxCountByItemId(ItemId)
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
    if not CfgItem then
        return 0
    end
    return CfgItem[Cfg_ItemConfig_P.MaxCount]
end

--[[
    获取对应物品的品质
    ItemId  物品配置ID
]]
function DepotModel:GetItemQualityByItemId(ItemId)
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
    if not CfgItem then
        return 0
    end
    return CfgItem[Cfg_ItemConfig_P.Quality]
end

--[[
    获取某个道具名称
]]
function DepotModel:GetItemName(ItemId)
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
    if not CfgItem then
        return "None"
    end
    return StringUtil.Format(CfgItem[Cfg_ItemConfig_P.Name])
end

--[[
    判断指定物品及数量，是否仓库里面足够
    ItemId
    NeedNum
    Param {bDisassociate:bool.取消关联.默认值为false.代表是关联的} bDisassociate=true 时代表获取钻石(ItemId=DepotConst.ITEM_ID_DIAMOND)数量时,不包含免费钻石(ItemId=DepotConst.ITEM_ID_DIAMOND_GIFT)的数量
]]
function DepotModel:IsEnoughByItemId(ItemId,NeedNum,Param)
    local TheNumIn = self:GetItemCountByItemId(ItemId, Param)
    return (TheNumIn >= NeedNum )
end

--- 获取货币数量:通过货币类型
---@param MoneyType CommonConst.GOLDEN or CommonConst.DIAMOND
function DepotModel:GetMoneyNum(MoneyType)
    if MoneyType == CommonConst.GOLDEN then 
        return self:GetItemCountByItemId(DepotConst.ITEM_ID_GOLDEN)
    elseif  MoneyType == CommonConst.DIAMOND then
        -- return self:GetItemCountByItemId(DepotConst.ITEM_ID_DIAMOND) + self:GetItemCountByItemId(DepotConst.ITEM_ID_DIAMOND_GIFT)
        return self:GetItemCountByItemId(DepotConst.ITEM_ID_DIAMOND)
    end
    return 0
end

-- --- 获取货币数量:通过货币ID
-- --- 这里特殊处理获取钻石数量逻辑:MoneyID==900000002付费钻石时,返回的是付费钻石+系统赠送钻石的和
-- ---@param MoneyID number
-- function DepotModel:GetMoneyNumByItemID(MoneyID)
--     if MoneyID == DepotConst.ITEM_ID_GOLDEN then 
--         return self:GetItemCountByItemId(DepotConst.ITEM_ID_GOLDEN)
--     elseif MoneyID == DepotConst.ITEM_ID_DIAMOND then
--         -- 返回付费钻石 + 系统赠送钻石
--         return self:GetItemCountByItemId(DepotConst.ITEM_ID_DIAMOND) + self:GetItemCountByItemId(DepotConst.ITEM_ID_DIAMOND_GIFT)
--     elseif MoneyID == DepotConst.ITEM_ID_DIAMOND_GIFT then
--         -- 不应该传入 MoneyID == 999999999,如确实要获取此物品的数量建议直接使用 DepotModel:GetItemCountByItemId() 接口
--         CWaring("DepotModel:GetMoneyNumByItemID: MoneyID == DepotConst.ITEM_ID_DIAMOND_GIFT !!! Please use DepotModel:GetItemCountByItemId.")
--         return self:GetItemCountByItemId(DepotConst.ITEM_ID_DIAMOND_GIFT)
--     else
--         -- 不是货币,如确实要获取此物品的数量建议直接使用 DepotModel:GetItemCountByItemId() 接口
--         CWaring("DepotModel:GetMoneyNumByItemID: Currency does not include MoneyID == " .. MoneyID)
--         return self:GetItemCountByItemId(MoneyID)
--     end
--     return 0
-- end

-- --- 判断指定货币及数量，是否仓库里面足够
-- function DepotModel:IsEnoughMoneyByItemId(MoneyID, NeedNum)
--     local TheNumIn = self:GetItemCountByItemId(MoneyID)
--     return (TheNumIn >= NeedNum )
-- end

--[[
    获取仓库页签列表
    self.DepotTabList = {
        repeat TabInfo = {
            TabType,
            TabName,
            TypeList = {
                [ItemType] = { repeat ItemSubType }
            }
        }
    }
]]
function DepotModel:GetDepotTabList()
    if not self.DepotTabList then
        self.DepotTabList = {}
        -- 单独处理G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotModel_all")页签
        local TabInfo = {
            TabType = 0,
            TabName = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotModel_all_Btn")),
            TypeList = nil
        }
        self.DepotTabList[#self.DepotTabList + 1] = TabInfo
        local Type2Index = {}
        local TabCfgs = G_ConfigHelper:GetDict(Cfg_DepotTabCfg)
        for _,Cfg in pairs(TabCfgs) do
            local TabType = Cfg[Cfg_DepotTabCfg_P.TabType]
                local ItemType = Cfg[Cfg_DepotTabCfg_P.Type]
            local ItemSubType = Cfg[Cfg_DepotTabCfg_P.SubType]
            if Type2Index[TabType] then
                local TabInfo = self.DepotTabList[Type2Index[TabType]]
                if TabInfo then
                    TabInfo.TypeList[ItemType] = TabInfo.TypeList[ItemType] or {}
                    if ItemSubType ~= "None" then
                        TabInfo.TypeList[ItemType][#TabInfo.TypeList[ItemType] + 1] = ItemSubType
                    end
                end
            else
                local TabInfo = {
                    TabType = Cfg[Cfg_DepotTabCfg_P.TabType],
                    TabName = Cfg[Cfg_DepotTabCfg_P.TabName],
                }
                -- 物品类别
                TabInfo.TypeList = {}
                TabInfo.TypeList[ItemType] = {}
                if ItemSubType ~= "None" then
                    TabInfo.TypeList[ItemType][#TabInfo.TypeList[ItemType] + 1] = ItemSubType
                end
                self.DepotTabList[#self.DepotTabList + 1] = TabInfo
                Type2Index[TabType] = #self.DepotTabList
            end
            
        end
        table.sort(self.DepotTabList,function (a,b)
            return a.TabType < b.TabType
        end)
    end
    return self.DepotTabList
end

--[[
    按仓库排序规则排序
]]
function DepotModel:SortItems(List)
    if not List or #List == 0 then
        return List
    end
    table.sort(List,self.keepSortIndexFunc)
    return List
end

--[[
    根据物品ID获取品质Hex值 
]]
function DepotModel:GetHexColorByItemId(ItemId)
    local CfgQuality =self:GetQualityCfgByItemId(ItemId)
    if CfgQuality and CfgQuality[Cfg_ItemQualityColorCfg_P.HexColor] then
        return CfgQuality[Cfg_ItemQualityColorCfg_P.HexColor]
    end
    return nil
end

--[[
    根据物品获取该物品的类别描述
]]
function DepotModel:GetItemTypeShowByItemId(ItemId,NeedEmptyText)
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
    if not CfgItem then
        CError("DepotModel GetItemTypeAndNameByItemId error for id = "..ItemId,true)
        return ""
    end
    local TypeId = CfgItem[Cfg_ItemConfig_P.Type]
    local SubType = CfgItem[Cfg_ItemConfig_P.SubType]
    local ItemTypeNameConfig = G_ConfigHelper:GetSingleItemByKeys(Cfg_ItemTypeNameConfig,{Cfg_ItemTypeNameConfig_P.Type,Cfg_ItemTypeNameConfig_P.SubType},{TypeId,SubType})
    if ItemTypeNameConfig then
        return ItemTypeNameConfig[Cfg_ItemTypeNameConfig_P.ShowName]
    end
    return NeedEmptyText and "" or StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotModel_Configurationnotfoun"))
end

--[[
    根据物品ID获取品质配置
]]
function DepotModel:GetQualityCfgByItemId(ItemId)
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
    if not CfgItem then
        CError("DepotModel GetQualityCfgByItemId error for id = "..ItemId,true)
        return nil
    end
    local QualityId = CfgItem[Cfg_ItemQualityColorCfg_P.Quality]
    if QualityId <= 0 then
        QualityId = 1
    end
    local CfgQuality = G_ConfigHelper:GetSingleItemById(Cfg_ItemQualityColorCfg,QualityId)
    return CfgQuality
end

--[[
    根据物品ID获取物品品质
]]
function DepotModel:GetQualityByItemId(ItemId)
    local CfgItem = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
    if not CfgItem then
        CError("DepotModel GetQualityByItemId error for id = "..ItemId,true)
        return nil
    end
    local QualityId = CfgItem[Cfg_ItemQualityColorCfg_P.Quality]
    return QualityId
end

--- 判断在增加一定数量的物品,是否会超出上限
---@param ItemId number
---@param AddItemNum number
function DepotModel:IsItemUpToMaxNum(ItemId, AddItemNum)
    local MaxHaveItemNum = self:GetItemMaxCountByItemId(ItemId)
    if MaxHaveItemNum <= 0 then
        return false, 0
    end
    local HaveItemNum = self:GetItemCountByItemId(ItemId)
    local Diff = AddItemNum + HaveItemNum - MaxHaveItemNum
    return Diff > 0, Diff
end

-- 获取DropConfig配置的对应的道具列表
-- 返回格式为：{[1] = {ItemId = xx,Num = 1},...}
function DepotModel:GetItemListForDropId(DropId)
    local ItemList = {}
    -- 配置的Id 可能为道具Id，也可能为掉落Id，需要拿Id到掉落表再查询一次，如果是掉落Id，需要递归读取
    local function DeepReadDropCfg(DropId,ItemList,Count)
        Count = Count or 1
        G_ConfigHelper.LogEnabled = false
        local DropCfg = G_ConfigHelper:GetSingleItemById(Cfg_DropConfig,DropId)
        local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,DropId)
        if DropCfg and ItemCfg then
            -- 同个Id存在于道具表和掉落表
            CError("Exist Same Id In DropConfig And ItemConfig. Id = "..tostring(DropId))
            return false
        end
        G_ConfigHelper.LogEnabled = true
        if not DropCfg then
            return false
        end
        local TArrayDropInfo = DropCfg[Cfg_DropConfig_P.DropInfo]
        if not TArrayDropInfo or TArrayDropInfo:Num() == 0 then
            return false
        end
        for _,DropInfo in ipairs(TArrayDropInfo) do
            local Id = DropInfo.ItemId
            local ItemNum = DropInfo.ItemNum
            if Id > 0 and ItemNum > 0 then
                if not DeepReadDropCfg(Id,ItemList,DropInfo.ItemNum) then
                    -- 配置的若为掉落Id，则递归读取 ； 否则配置的为道具Id，存进列表
                    local Item = {
                        ItemId = Id,
                        ItemNum = ItemNum * Count,
                    }
                    ItemList[#ItemList + 1] = Item
                end
            else
                break
            end
        end
        return true
    end
    DeepReadDropCfg(DropId,ItemList)
    
    return ItemList
end

function DepotModel:GetItemListForDropId2(DropId)
    local ItemList = {}
    -- G_ConfigHelper.LogEnabled = false
    local DropCfg = G_ConfigHelper:GetSingleItemById(Cfg_DropConfig,DropId)
    -- G_ConfigHelper.LogEnabled = true
    if not DropCfg then
        return ItemList
    end
    CWaring("DropId:" .. DropId)
    local TArrayDropInfo = DropCfg[Cfg_DropConfig_P.DropInfo]
    if not TArrayDropInfo or TArrayDropInfo:Num() == 0 then
        return ItemList
    end
    for _,DropInfo in ipairs(TArrayDropInfo) do
        local Id = DropInfo.ItemId
        local ItemNum = DropInfo.ItemNum
        if Id > 0 and ItemNum > 0 then
            -- 配置的若为掉落Id，则递归读取 ； 否则配置的为道具Id，存进列表
            local Item = {
                ItemId = Id,
                ItemNum = ItemNum,
            }
            ItemList[#ItemList + 1] = Item
        else
            break
        end
    end
    return ItemList
end

--[[
    是否拥有物品
    ItemId  物品配置ID
]]
function DepotModel:HaveItem(ItemId)
    self:CalculateItemType2ListDirty()
    return self.ItemId2Count[ItemId] and self.ItemId2Count[ItemId] > 0
end

--[[
    根据使用类型检测是否可使用
]]
function DepotModel:CanItemUseForUseType(UseType)
    return UseType == Pb_Enum_ITEM_USE_TYPE.ITEM_USE_DROPID or UseType == Pb_Enum_ITEM_USE_TYPE.ITEM_USE_COMPOSE_ITEM or UseType == Pb_Enum_ITEM_USE_TYPE.ITEM_USE_ADD_GOLD_COF or UseType == Pb_Enum_ITEM_USE_TYPE.ITEM_USE_ADD_EXP_COF or UseType == Pb_Enum_ITEM_USE_TYPE.ITEM_USE_CLINET_OPEN_UI
end

--[[
    检测是否可合成
]]
function DepotModel:CanCompose(ItemId)
    local ItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,ItemId)
    if not ItemCfg then
        CLog("CanCompose Without ItemCfg Id = "..tostring(ItemId))
        return false,0
    end
    local UseParam = ItemCfg[Cfg_ItemConfig_P.UseParam]
    if not UseParam or UseParam == "" then
        CLog("CanCompose Without UseParam Id = "..tostring(ItemId))
        return false,0
    end
    local NeedCount = 0
    UseParam = string.split(UseParam,';')
    if UseParam and #UseParam > 0 then
        NeedCount = tonumber(UseParam[1])
        local TargetItemId = tonumber(UseParam[2])
        local TargetCount = tonumber(UseParam[3])
        if NeedCount and NeedCount > 0 then
            local HaveCount = self:GetItemCountByItemId(ItemId)
            if HaveCount < NeedCount then
                UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotModel_ComposeItemNotEnough"))
                return false,0
            end
        end
        if TargetItemId and TargetCount then
            local TargetItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,TargetItemId)
            if not TargetItemCfg then
                CLog("CanCompose Without TargetItemCfg Id = "..tostring(TargetItemId))
                return false,0
            end
            local MaxCount = TargetItemCfg[Cfg_ItemConfig_P.MaxCount]
            local TargetHaveCount = self:GetItemCountByItemId(TargetItemId)
            if MaxCount > 0 and TargetHaveCount + TargetCount > MaxCount then
                UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Depot', "Lua_DepotModel_ComposeReachMax"))
                return false,0
            end
        end
    else
        CLog("CanCompose UseParam Error Id = "..tostring(ItemId))
        return false,0
    end
    return true,NeedCount
end
return DepotModel;