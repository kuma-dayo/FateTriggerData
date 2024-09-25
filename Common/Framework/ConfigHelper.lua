--
-- 配置表相关

--引入配置描述（配置常量）
require("Common.Configs.Declare.DeclareRequire")
require("Common.Configs.TipsCode")
require("Common.Configs.ErrorCode")
require("Common.Configs.JumpCode")
require("Common.Configs.ParameterConfig")
require("Common.Configs.GameModuleCfg")
require("Common.Configs.ETransformModuleID")
require("Common.Configs.EItemQuality")
require("Common.Configs.EHeroDisplayBoardTabID")
require("Common.Configs.CornerTagCfg")
require("Common.Configs.CornerTagWordCfg")
require("Common.Configs.HallLSCfg")
require("Common.Configs.ECGSettingConfig")
--//

---@class ConfigHelper
local ConfigHelper = BaseClass(nil,"ConfigHelper")

-------------------------------------------- Lua Config ------------------------------------

function ConfigHelper:__init()
    self.CacheConfigs = {}

    -- self.cacheTblRow = {}
    self.cacheTbl = {}
    self.cacheFullTpl = {}
    self.LogEnabled = true

    self.StructPath2RefProxy = {}

    self.CacheStrTable = {}
end

function ConfigHelper:LogWarning(str)
    if not self.LogEnabled then
        return
    end
    CWaring(str)
end

local function IsParamValid(Param)
    if Param == nil then
        return false
    end
    return true
end

function ConfigHelper:ReadConfig(cfgName,keyOrKyes,isMulti)
    local ret = {}
    local fields = {}
    if type(keyOrKyes) == "string" then
        fields[1] = keyOrKyes
    else
        fields = keyOrKyes
    end
    local numOfKeys = table_leng(fields)
    local mDataList = self:GetDict(cfgName)
    if not mDataList then
        return nil
    end
    for _,template in pairs(mDataList) do
        local dst = ret
        local key = nil
        local cur = nil
        for j=1,(numOfKeys-1) do
            key = template[fields[j]]
            if key then
                cur = dst[key]
                if not cur then
                    cur = {}
                    dst[key] = cur
                end
                dst = cur
            else
                CError(StringUtil.FormatText("配置表[{0}]发现一条记录关键字[{1}]不存在，请修改",cfgName,key),true)
                return nil
            end
        end
        local lastKey = template[fields[numOfKeys]]
        if lastKey ~= nil then
            if isMulti then
                dst[lastKey] = dst[lastKey] or {}
                table.insert(dst[lastKey],template)
            else
                dst[lastKey] = template
            end
        else
            CError(StringUtil.FormatText("配置表[{0}]找不到关键Key值[{1}]不存在，请修改",cfgName,lastKey),true)
            return nil
        end
    end
    return ret
end

function ConfigHelper:LoadDataTable(DataTablePath)
    -- local DataTablePath = string.format("/Game/DataTable/DT_%s",cfgName)
    local DataTableObject = UE.UObject.Load(DataTablePath)
    if not DataTableObject then
        CError("ConfigHelper:LoadDataTable DataTablePath not found:" .. DataTablePath)
        return nil
    end
    return DataTableObject
end

function ConfigHelper:LoadUserDefinedStruct(StructPath)
    -- local StructPath = string.format("/Game/DataTable/UserDefinedStruct/T_%s",cfgName)
    local StructObject = UE.UObject.Load(StructPath)
    if StructObject and not self.StructPath2RefProxy[StructPath] then
        local RefProxy = UnLua.Ref(StructObject)
        self.StructPath2RefProxy[StructPath] = RefProxy
    end
    return StructObject
end


------------------------------------------------------------------------------------------------------------
-----------------------------------------------------供外部调用----------------------------------------------

--[[
    获取配置表所有记录列表  注意这边返回的是数组
]]
function ConfigHelper:GetDict(cfgName)
    if not cfgName then
        CError("ConfigHelper:GetTblDict param Error")
        return
    end
    if not self.cacheFullTpl[cfgName] then
        local CustomUseUds = false
        local CustomPathFix = ""
        local CustomDTName = "DT_" .. cfgName
        if G_CfgName2Custom and G_CfgName2Custom[cfgName] then
            local CustomInfo = G_CfgName2Custom[cfgName]
            if CustomInfo.Path then
                CustomPathFix = CustomInfo.Path
            end
            if CustomInfo.DTName then
                CustomDTName = CustomInfo.DTName
            end
            if CustomInfo.UseUds ~= nil then
                CustomUseUds = CustomInfo.UseUds
            end
        end
        local DataTablePath = string.format("/Game/DataTable/%s/%s",CustomPathFix,CustomDTName)
        DataTablePath = string.gsub(DataTablePath,"//","/")
        local DataTableObject = self:LoadDataTable(DataTablePath)

        local StructObject = nil
        if CustomUseUds then
            local StructPath = string.format("/Game/DataTable/UserDefinedStruct/T_%s",cfgName)
            StructObject = self:LoadUserDefinedStruct(StructPath)
            if not StructObject then
                CError("ConfigHelper:GetDict Need StructObject,but got nil:" .. StructPath,true)
                return nil
            end
        end
        if DataTableObject then
            self.cacheFullTpl[cfgName] = {}
            local rowNameList = UE.UDataTableFunctionLibrary.GetDataTableRowNames(DataTableObject)
            for i = 1, rowNameList:Length() do
                if rowNameList:Get(i) then
                    if StructObject then
                        local Row = StructObject()
                        local Result = UE.UDataTableFunctionLibrary.GetDataTableRowFromName(DataTableObject, rowNameList:Get(i),Row)
                        if Result then
                            table.insert(self.cacheFullTpl[cfgName],Row)
                        end
                    else
                        local DataTableRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(DataTableObject, rowNameList:Get(i))
                        table.insert(self.cacheFullTpl[cfgName],DataTableRow)
                    end
                end
            end
        end
    end
    if not self.cacheFullTpl[cfgName] then
        CError("ConfigHelper:GetDict return nil:" .. cfgName)
    end
    return self.cacheFullTpl[cfgName];
end

--[[
    适用主Key unique模式 （主Key一般指Excel表的第一个字段）此方法主Key不需要额外传参
    cfgName 配置表名称
    rowValue 主Key的值
    recKey 想获取此行对应字段的字段值 （可选）
]]
function ConfigHelper:GetSingleItemById(cfgName,rowValue,recKey)
    local MainKeyName = G_CfgName2MainKey[cfgName]
    if not MainKeyName then
        CError("ConfigHelper:GetSingleItemById param Error",true)
        return nil
    end
    return self:GetSingleItemByKey(cfgName,MainKeyName,rowValue,recKey)
end

--[[
    适用单key unique模式 单Key 返回一条记录(Key可以是任意唯一Key，不需要主Key)
    cfgName 配置表名称
    keyName Key字段名
    keyValue Key值
    recKey 想获取此行对应字段的字段值 （可选）

    返回单行值
]]
function ConfigHelper:GetSingleItemByKey(cfgName,keyName,keyValue,recKey)
    if not cfgName or not keyName or not IsParamValid(keyValue) then
        CError(StringUtil.Format("ConfigHelper:GetSingleItemByKey param Error cfgName:{0}|keyName:{1}|keyVaue:{2}",cfgName or "",keyName or "",keyValue or ""),true)
        return
    end
    -- local mainKeyName = UE.UConfigHelper:GetTblRowKey(cfgName)
    -- if mainKeyName == keyName then
    --     return ConfigHelper:GetSingleItemByTbl(cfgName,keyValue)
    -- end
    self.cacheTbl[cfgName] = self.cacheTbl[cfgName] or {}
    if not self.cacheTbl[cfgName][keyName] then
        self.cacheTbl[cfgName][keyName] = self:ReadConfig(cfgName,keyName,false)
    -- else
    --     CWaring("GetSingleItemByKey From Cache========")
    end
    if self.cacheTbl[cfgName][keyName] then
        if self.cacheTbl[cfgName][keyName][keyValue] then
            if recKey then
                return self.cacheTbl[cfgName][keyName][keyValue][recKey]
            else
                return self.cacheTbl[cfgName][keyName][keyValue]
            end
        else
            self:LogWarning(StringUtil.FormatText("func[GetSingleItemByKey] not found config:{0}|key:{1}|keyValue:{2}",cfgName,keyName,keyValue))
            return nil
        end
    end
    self:LogWarning(StringUtil.FormatText("func[GetSingleItemByKey] not found config:{0}|key:{1} return nil",cfgName,keyName))
    return nil
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
function ConfigHelper:GetSingleItemByKeys(cfgName, keyNames, keyValues, recKey)
    if not cfgName or not keyNames or not keyValues then
        CError("ConfigHelper:GetSingleItemByKeys param Error",true)
        return
    end
    if type(keyNames) ~= "table" or type(keyValues) ~= "table" then
        CError("ConfigHelper:GetSingleItemByKeys param Error Need Table",true)
        return
    end
    local keyName = ""
    for _,v in pairs(keyNames) do
        keyName = keyName .. v
    end
    self.cacheTbl[cfgName] = self.cacheTbl[cfgName] or {}
    if not self.cacheTbl[cfgName][keyName] then
        self.cacheTbl[cfgName][keyName] = self:ReadConfig(cfgName,keyNames,false)
    -- else
    --     CWaring("GetSingleItemByKeys From Cache========")
    end
    if self.cacheTbl[cfgName][keyName] then
        local ret = self.cacheTbl[cfgName][keyName]
        for _,v in pairs(keyValues) do
            ret = ret[v]
            if not ret then
                break
            end
        end
        if ret then
            if recKey then
                return ret[recKey]
            else
                return ret
            end
        else
            -- self:LogWarning(StringUtil.FormatText("func[GetSingleItemByKeys] not found config:{0}|keys:{1}|keyValues:{2}",cfgName,keyNames,keyValues))
            if cfgName == Cfg_ItemIdentificationCfg then
                -- 这个配置查询不到数据概率太高，不输出打印了
                return nil
            end
            self:LogWarning(StringUtil.FormatText("func[GetSingleItemByKeys] not found config:{0}|keys:{1} and keyValues:{2} ",cfgName,table.concat(keyNames,","),table.concat(keyValues,",")))
            return nil
        end
    end
    self:LogWarning(StringUtil.FormatText("func[GetSingleItemByKeys] not found config:{0}|keys:{1} return nil",cfgName,table.concat(keyNames,",")))
    return nil
end

--[[
    根据某个Key值获取列表 适用key非unique模式 单Key 返回列表
    cfgName 配置表名称
    keyNames Key字段名列表
    keyValues Key值列表

    返回多行列表值
]]
function ConfigHelper:GetMultiItemsByKey(cfgName,keyName,keyValue)
    if not cfgName or not keyName or not IsParamValid(keyValue) then
        CError("ConfigHelper:GetMultiItemsByKey param Error",true)
        return {}
    end
    self.cacheTbl[cfgName] = self.cacheTbl[cfgName] or {}
    if not self.cacheTbl[cfgName][keyName] then
        self.cacheTbl[cfgName][keyName] = self:ReadConfig(cfgName,keyName,true)
    -- else
    --     CWaring("GetMultiItemsByKey From Cache========")
    end
    if self.cacheTbl[cfgName][keyName] then
        if self.cacheTbl[cfgName][keyName][keyValue] then
            return self.cacheTbl[cfgName][keyName][keyValue]
        else
            self:LogWarning(StringUtil.FormatText("func[GetMultiItemsByKey] not found config:{0}|key:{1}|keyValue:{2}",cfgName,keyName,keyValue))
            return {}
        end
    end
    self:LogWarning(StringUtil.FormatText("func[GetMultiItemsByKey] not found config:{0}|key:{1} return nil",cfgName,keyName))
    return nil
end

--[[
    适用于多key组成非unique模式  多key，返回列表
    cfgName 配置表名称
    keyNames Key字段名列表
    keyValues Key值列表

    返回多行列表值
]]
function ConfigHelper:GetMultiItemsByKeys(cfgName,keyNames,keyValues)
    if not cfgName or not keyNames or not keyValues then
        CError("ConfigHelper:GetSingleItemByKeys param Error",true)
        return {}
    end
    if type(keyNames) ~= "table" or type(keyValues) ~= "table" then
        CError("ConfigHelper:GetSingleItemByKeys param Error Need Table",true)
        return
    end
    local keyName = ""
    for _,v in pairs(keyNames) do
        keyName = keyName .. v
    end
    self.cacheTbl[cfgName] = self.cacheTbl[cfgName] or {}
    if not self.cacheTbl[cfgName][keyName] then
        self.cacheTbl[cfgName][keyName] = self:ReadConfig(cfgName,keyNames,true)
    -- else
    --     CWaring("GetMultiItemsByKeys From Cache========")
    end
    if self.cacheTbl[cfgName][keyName] then
        local ret = self.cacheTbl[cfgName][keyName]
        for _,v in pairs(keyValues) do
            ret = ret[v]
            if not ret then
                break
            end
        end
        if ret then
            return ret
        else
            self:LogWarning(StringUtil.FormatText("func[GetMultiItemsByKeys] not found config:{0}|keys:{1}|keyValues:{2}",cfgName,table.concat(keyNames,","),table.concat(keyValues,",")))
            return {}
        end
    end
    self:LogWarning(StringUtil.FormatText("func[GetMultiItemsByKeys] not found config:{0}|keys:{1} return nil",cfgName,table.concat(keyNames,",")))
    return nil
end

-------------------------------------------- String Table ------------------------------------

--[[
    从指定的StringTable里面取值 
    InStrTableKey 路径 举例"/Game/DataTable/ExtractLocalization/SD_ExtractLocalization.SD_ExtractLocalization"
    InRowKey 查找的Key值
    PreLoad 标记是否预加载
]]
function ConfigHelper:GetStrTableRow(InStrTableKey, InRowKey,PreLoad)
    if (not InStrTableKey) or (not InRowKey and not PreLoad) then
        Error("ConfigHelper", ">> GetStrTableRow, Invalid Params!!!", InStrTableKey, InRowKey, "\n".. debug.traceback())
        return
    end
    if not CommonUtil.g_client_main_start then
        print_trackback("client not ready,please check!!!!")
        return "<MISSING STRING TABLE ENTRY>"
    end
    if not self.CacheStrTable[InStrTableKey] then
        -- CWaring("ConfigHelper:GetStrTableRow Generate Cache:" .. InStrTableKey)
        --Fix:额外添加Load代码，是为了更好取值，否则GetKeysFromStringTable方法可能返回空列表
        local StrTableObject = UE.UObject.Load(InStrTableKey)
        if StrTableObject then
            self.CacheStrTable[InStrTableKey] = {}
            local Keys = UE.UKismetStringTableLibrary.GetKeysFromStringTable(InStrTableKey)
            for _,Key in pairs(Keys) do
                local StrTableValue = UE.UKismetTextLibrary.TextFromStringTable(InStrTableKey, Key)
                self.CacheStrTable[InStrTableKey][Key] = StrTableValue
            end
        else
            CWaring("ConfigHelper:GetStrTableRow Generate Cache Failed:" .. InStrTableKey)
        end
    end

    -- print(InStrTableKey, InRowKey)
    return InRowKey and self.CacheStrTable[InStrTableKey] and self.CacheStrTable[InStrTableKey][InRowKey] or "<MISSING STRING TABLE ENTRY>"
    
	-- local StrTableObject = UE.UObject.Load(InStrTableKey)
    -- local StrTableValue = UE.UKismetTextLibrary.TextFromStringTable(InStrTableKey, InRowKey)
    -- return StrTableValue
end

local LocalizationTextSDPath = "/Game/DataTable/ExtractLocalization/SD_ExtractLocalization.SD_ExtractLocalization"
--[[
    快速从杂项StringTable里面进行查询取值
    路径会默认索引至 "/Game/DataTable/ExtractLocalization/SD_ExtractLocalization.SD_ExtractLocalization"

    InRowKey 查找的Key值
]]
function ConfigHelper:GetStrFromMiscST(InRowKey)
    return self:GetStrTableRow(LocalizationTextSDPath, InRowKey,false)
end

--[[
    快速从公用StringTable里面进行查询取值
    路径会默认索引至 Content/DataTable/UIStatic/SD_CommonText

    InRowKey 查找的Key值
]]
function ConfigHelper:GetStrFromCommonStaticST(InRowKey)
    return self:GetStrTableRow("/Game/DataTable/UIStatic/SD_CommonText.SD_CommonText", InRowKey,false)
end


--[[
    快速从局外UI模块查找对应StringTable进行取值
    路径会默认索引至 Content/DataTable/UIStatic/Text_OutsideGame/
    只需要传参上述目录下的StringTable名称

    SDName StringTable名称
    InRowKey 查找的Key值
]]
function ConfigHelper:GetStrFromOutgameStaticST(SDName,InRowKey)
    local SDPath = StringUtil.FormatSimple("/Game/DataTable/UIStatic/Text_OutsideGame/{0}.{0}",SDName)
    return self:GetStrTableRow(SDPath, InRowKey,false)
end

--[[
    快速从局内UI模块查找对应StringTable进行取值
    路径会默认索引至 Content/DataTable/UIStatic/Text_InsideGame/
    只需要传参上述目录下的StringTable名称

    SDName StringTable名称
    InRowKey 查找的Key值
]]
function ConfigHelper:GetStrFromIngameStaticST(SDName,InRowKey)
    local SDPath = StringUtil.FormatSimple("/Game/DataTable/UIStatic/Text_InsideGame/{0}.{0}",SDName)
    return self:GetStrTableRow(SDPath, InRowKey,false)
end


--[[
    注意Text_Special目录下的表，不会参与到本地化扫描，属于黑名单
    快速从特殊UI模块查找对应StringTable进行取值
    路径会默认索引至 Content/DataTable/UIStatic/Text_Special/
    只需要传参上述目录下的StringTable名称

    SDName StringTable名称
    InRowKey 查找的Key值
]]
function ConfigHelper:GetStrFromSpecialStaticST(SDName,InRowKey)
    local SDPath = StringUtil.FormatSimple("/Game/DataTable/UIStatic/Text_Special/{0}.{0}",SDName)
    return self:GetStrTableRow(SDPath, InRowKey,false)
end

-----------------------------------------Localizatio Clean Cache-------------------------------------------------------------------
function ConfigHelper:OnCurrentLanguageChange()
    CWaring("ConfigHelper:OnCurrentLanguageChange")
    if FTextSupportUtil.IsEnabledFText then
        CWaring("ConfigHelper:OnCurrentLanguageChange IsEnabledFText Break")
    else
        self.CacheStrTable = {}
        self.cacheTbl = {}
    end
end


return ConfigHelper
