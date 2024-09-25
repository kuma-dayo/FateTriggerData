---
--- Model 模块，用于数据存储与逻辑运算
--- Description: 通用的恭喜获得面板数据，包含了三个方面的数据
--- * 主要数据： 
---     1.获得的物品列表
---     @see ItemGetModel#DisplayData 具体数据结构参考下方
---     @see ItemGetCtrl#ShowItemGet 中的 Param.PrizeItemList 注释
---     2.获取标题文字
---     @see ItemGetModel#GetTittleText()
---     3.获取提示文字
---     @see ItemGetModel#GetHintText()
--- * 次要数据：
---     1.设置自定义标题文字
---     @see ItemGetModel#SetCustomerTittle(sNewTitle)
---     @see ItemGetCtrl#ShowItemGet 中的 Param.Title 注释
---     2.设置自定义提示文字
---     @see ItemGetModel#SetCustomerHint(sNewHint)
---     @see ItemGetCtrl#ShowItemGet 中的 Param.Tips 注释
---
--- Created At: 2023/03/27 17:16
--- Created By: 朝文
---

local super = ListModel
local class_name = "ItemGetModel"
---@class ItemGetModel : ListModel
ItemGetModel = ItemGetModel or BaseClass(super, class_name)
ItemGetModel.ON_SET_SPECIAL_GET_BG = "ON_SET_SPECIAL_GET_BG"
local Const = {}

---这里不适合使用其他字段名作为key，使用index作为key，重写这个方法可以避免修改更多逻辑。
---因为在ListMode中，便利使用了ipairs，所以会根据array顺序进行便利，这里的索引也能对上去
---@see ListModel#KeyOf
---@param vo table 单个数据
function ItemGetModel:KeyOf(vo)
    local key = self.CacheList[vo]
    if not key then
        self.CacheList[vo] = self.CacheIncreaseIndex
        self.CacheIncreaseIndex = self.CacheIncreaseIndex + 1
        key = self.CacheList[vo]
    end
    
    return key
end

function ItemGetModel:OnGameInit()
    Const = {
        DefaultTittleText = G_ConfigHelper:GetStrFromCommonStaticST("Lua_ItemGetModel_Congratulationsonobt"),
        DefaultHintText = G_ConfigHelper:GetStrFromCommonStaticST("Lua_ItemGetModel_Clickontheblankspace")
    }
end

function ItemGetModel:__init()
    self:DataInit()

    --排序规则
    self.keepSortIndexFunc = function(A, B)
        if A == nil or B == nil then return false end

        --1.稀有度不同：稀有度高的＞稀有度低的
        local AInfo = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, A.ItemId)
        local BInfo = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, B.ItemId)
        local AQuality = AInfo[Cfg_ItemConfig_P.Quality]
        local BQuality = BInfo[Cfg_ItemConfig_P.Quality]
        if AQuality > BQuality then
            return true
        elseif AQuality < BQuality then
            return false
        end
        
        --2.稀有度相同：ID小的＞ID大
        return A.ItemId < B.ItemId
    end
end

---初始化数据，用于第一次调用及登出的时候调用
function ItemGetModel:DataInit()
    self:Clean()
    
    self.DisplayData = {}       --所有获得物品的数据
    self.CacheList = {}         --用于记录索引
    self.CacheIncreaseIndex = 1 --用于计数索引
    
    --customer settings
    self.customerTitle = nil    --自定义标题
    self.customerHint = nil     --自定义提示
end

---@overwrite 这里重写一下，在调用前先初始化一下数据，每一次数据都应该是全新的
---@param list table 数据列表
function ItemGetModel:SetDataList(list)
    self:DataInit()
    ---@type ListModel
    local super = ItemGetModel.super
    super.SetDataList(self, list)
end

---玩家登出时调用
function ItemGetModel:OnLogout(data)
    self:DataInit()
end

------------------- 用户自定义方法，一般不需要调用 -------------------

---自定义标题名称，需要设置的时候调用，请在 SetDataList 之后调用
---@param sNewTitle string 新的标题名称
function ItemGetModel:SetCustomerTittle(sNewTitle)
    if not sNewTitle or type(sNewTitle) ~= "string" then
        CWaring("[cw] sNewTitle(" .. tostring(sNewTitle) .. ") is not illegal, please check it.")
        return 
    end
    
    self.customerTitle = sNewTitle
end

---获取标题名称，如果用户设定了自定义的则返回自定义标题名称，否则则返回默认标题名称
---@return string 标题名称(已本地化好的文本)
function ItemGetModel:GetTittleText()
    if not self.customerTitle then
        return StringUtil.Format(Const.DefaultTittleText)
    end

    return StringUtil.Format(self.customerTitle)
end

---自定义提示名称，需要设置的时候调用，请在 SetDataList 之后调用
---@param sNewHint string 新的提示文字
function ItemGetModel:SetCustomerHint(sNewHint)
    if not sNewHint or type(sNewHint) ~= "string" then
        CWaring("[cw] sNewHint (" .. tostring(sNewHint) .. ") is not illegal, please check it.")
        return
    end

    self.customerHint = sNewHint
end

---获取提示文字，如果用户设定了自定义的提示文字内容则返回自定义内容，否则则返回默认提示文字
---@return string 提示文字(已本地化好的文本)
function ItemGetModel:GetHintText()
    if not self.customerHint then
        return StringUtil.Format(Const.DefaultHintText)
    end

    return StringUtil.Format(self.customerHint)
end

-------------------


return ItemGetModel