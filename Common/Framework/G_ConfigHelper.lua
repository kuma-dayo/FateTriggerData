G_ConfigHelper = G_ConfigHelper or {}

 
function G_ConfigHelper:Init()
    ---@type ConfigHelper
    G_ConfigHelper.Helper = require("Common.Framework.ConfigHelper").New()
end

function G_ConfigHelper:SetLogEnabled(Value)
    G_ConfigHelper.Helper.LogEnabled = Value
end

--[[
    获取配置表所有记录列表  注意这边返回的是数组
]]
function G_ConfigHelper:GetDict(cfgName)
    return G_ConfigHelper.Helper:GetDict(cfgName)
end

--[[
    适用主Key unique模式 （主Key一般指Excel表的第一个字段）此方法主Key不需要额外传参
    cfgName 配置表名称
    rowValue 主Key的值
    recKey 想获取此行对应字段的字段值 （可选）
]]
function G_ConfigHelper:GetSingleItemById(cfgName,rowValue,recKey)
    return G_ConfigHelper.Helper:GetSingleItemById(cfgName,rowValue,recKey)
end

--[[
    适用单key unique模式 单Key 返回一条记录(Key可以是任意唯一Key，不需要主Key)
    cfgName 配置表名称
    keyName Key字段名
    keyValue Key值
    recKey 想获取此行对应字段的字段值 （可选）

    返回单行值
]]
function G_ConfigHelper:GetSingleItemByKey(cfgName,keyName,keyValue,recKey)
    return G_ConfigHelper.Helper:GetSingleItemByKey(cfgName,keyName,keyValue,recKey)
end

--[[
    适用多key组成unique模式 多Key 返回一条记录
    cfgName 配置表名称
    keyNames Key字段名列表
    keyValues Key值列表
    recKey 想获取此行对应字段的字段值 （可选）

    返回单行值
]]
---@param cfgName string 表名
---@param keyNames table key名称list
---@param keyValues table key值list
---@param recKey table 可选的返回项list
---@return table 找不到返回nil
function G_ConfigHelper:GetSingleItemByKeys(cfgName, keyNames, keyValues, recKey)
    return G_ConfigHelper.Helper:GetSingleItemByKeys(cfgName, keyNames, keyValues, recKey)
end

--[[
    根据某个Key值获取列表 适用key非unique模式 单Key 返回列表
    cfgName 配置表名称
    keyNames Key字段名列表
    keyValues Key值列表

    返回多行列表值
]]
function G_ConfigHelper:GetMultiItemsByKey(cfgName,keyName,keyValue)
    return G_ConfigHelper.Helper:GetMultiItemsByKey(cfgName,keyName,keyValue)
end

--[[
    适用于多key组成非unique模式  多key，返回列表
    cfgName 配置表名称
    keyNames Key字段名列表
    keyValues Key值列表

    返回多行列表值
]]
function G_ConfigHelper:GetMultiItemsByKeys(cfgName,keyNames,keyValues)
    return G_ConfigHelper.Helper:GetMultiItemsByKeys(cfgName,keyNames,keyValues)
end

-------------------------------------------- String Table ------------------------------------

--[[
    从指定的StringTable里面取值 
    InStrTableKey 路径 举例"/Game/DataTable/ExtractLocalization/SD_ExtractLocalization.SD_ExtractLocalization"
    InRowKey 查找的Key值
    PreLoad 标记是否预加载
]]
function G_ConfigHelper:GetStrTableRow(InStrTableKey, InRowKey,PreLoad)
    return G_ConfigHelper.Helper:GetStrTableRow(InStrTableKey, InRowKey,PreLoad)
end

-- local LocalizationTextSDPath = "/Game/DataTable/ExtractLocalization/SD_ExtractLocalization.SD_ExtractLocalization"
--[[
    快速从杂项StringTable里面进行查询取值
    路径会默认索引至 "/Game/DataTable/ExtractLocalization/SD_ExtractLocalization.SD_ExtractLocalization"

    InRowKey 查找的Key值
]]
function G_ConfigHelper:GetStrFromMiscST(InRowKey)
    return G_ConfigHelper.Helper:GetStrFromMiscST(InRowKey)
end

--[[
    快速从公用StringTable里面进行查询取值
    路径会默认索引至 Content/DataTable/UIStatic/SD_CommonText

    InRowKey 查找的Key值
]]
function G_ConfigHelper:GetStrFromCommonStaticST(InRowKey)
    return G_ConfigHelper.Helper:GetStrFromCommonStaticST(InRowKey)
end


--[[
    快速从局外UI模块查找对应StringTable进行取值
    路径会默认索引至 Content/DataTable/UIStatic/Text_OutsideGame/
    只需要传参上述目录下的StringTable名称

    SDName StringTable名称
    InRowKey 查找的Key值
]]
function G_ConfigHelper:GetStrFromOutgameStaticST(SDName,InRowKey)
    return G_ConfigHelper.Helper:GetStrFromOutgameStaticST(SDName,InRowKey)
end

--[[
    快速从局内UI模块查找对应StringTable进行取值
    路径会默认索引至 Content/DataTable/UIStatic/Text_InsideGame/
    只需要传参上述目录下的StringTable名称

    SDName StringTable名称
    InRowKey 查找的Key值
]]
function G_ConfigHelper:GetStrFromIngameStaticST(SDName,InRowKey)
    return G_ConfigHelper.Helper:GetStrFromIngameStaticST(SDName,InRowKey)
end

function G_ConfigHelper:GetStrFromSpecialStaticST(SDName,InRowKey)
    return G_ConfigHelper.Helper:GetStrFromSpecialStaticST(SDName,InRowKey)
end


function G_ConfigHelper:OnCurrentLanguageChange()
    G_ConfigHelper.Helper:OnCurrentLanguageChange()
end