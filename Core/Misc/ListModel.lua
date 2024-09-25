--[[
    数据列表管理器
]]
local super = GameEventDispatcher;
local class_name = "ListModel";
---@class ListModel : GameEventDispatcher
ListModel = BaseClass(super, class_name);

ListModel.ON_CHANGED = "ON_CHANGED"
ListModel.ON_DELETED = "ON_DELETED"
ListModel.ON_UPDATED = "ON_UPDATED"
ListModel.ON_UPDATED_MAP = "ON_UPDATED_MAP"
ListModel.ON_UPDATED_MAP_CUSTOM = "ON_UPDATED_MAP_CUSTOM"

EDataUpdateType = {
    NONE = 0,
    --[[
        更新
    ]]
    UPDATE = 1,
    --[[
        增加
    ]]
    ADD = 2,
    --[[
        移除
    ]]
    DELETE = 3,
}

function ListModel:__init()	
    self.mDataList = {}
    self.mDataMap = {}
    self.mIsChanged = false
    --保证数据更新后顺序不变，消耗一点儿性能，如查有必要，可对其赋值。
    self.keepSortIndexFunc = nil
    --自增ID
    self.indexIncrement = 0
end

function ListModel:__dispose()	

end

function ListModel:OnLogout()	
    self:Clean()
end

--[[
    清空所有数据缓存
]]
function ListModel:Clean()
    self.mDataList = {}
    self.mDataMap = {}
    self.mIsChanged = false;
end

--[[
    可重写此方法，用于获取数据变化情况
]]
function ListModel:SetIsChange(value)
    self.mIsChanged = value
end

function ListModel:GetIsChange()
    return self.mIsChanged
end

--[[
    格式不同需要重写此方法

    返回数据格式的唯一Key
]]
function ListModel:KeyOf(vo)
    if vo["CfgId"] then
        return vo["CfgId"]
    end
    CError("ListModel:KeyOf not found key,use incrementid to fix,Please Check")
    self.indexIncrement = self.indexIncrement + 1
    return self.indexIncrement;
end

function ListModel:CustomKeyOf(Vo)
    return self:KeyOf(Vo)
end

--[[
    是否可用,不可用将会从Cache移除（表示Delete）
    格式不同需要重写此方法
]]
function ListModel:IsValidOf(vo)
    if vo["StackNum"] then
        if vo["StackNum"] > 0 then
            return true
        end
        return false
    end
    return true
end

function ListModel:GetDataList()
    if self:GetIsChange() then
        self:SetIsChange(false)

        self.mDataList = {}
        for k,v in pairs(self.mDataMap) do
            if v then
                table.insert(self.mDataList,v)
            end
        end
        self:CheckSortDataList()
    end
    return self.mDataList;
end

function ListModel:GetDataMapKeys()
    return table.keys(self.mDataMap)
end

function ListModel:CheckSortDataList()
    if self.keepSortIndexFunc then
        table.sort(self.mDataList,self.keepSortIndexFunc)
    end
end

function ListModel:SetDataList(list,need_force_change)
    self.mDataList = list
    self.mDataMap = {}
    self:SetIsChange(need_force_change and true or false)
    for _,v in ipairs(list) do
        local key = self:KeyOf(v)
        self.mDataMap[key] = v
    end
    self:CheckSortDataList()
    self:DispatchType(ListModel.ON_CHANGED)
end

--[[
    获取的数据结构是Map。又想用ListModel存储。使用此接口初始化数据
    避免在外部再循环一次换成List才能存储进来
]]
function ListModel:SetDataListFromMap(Map)
    self.mDataMap = {}
    self.mDataList = {}
    self:SetIsChange(false)
    for _,v in pairs(Map) do
        local key = self:KeyOf(v)
        self.mDataMap[key] = v
        self.mDataList[#self.mDataList + 1] = v
    end
    self:CheckSortDataList()
    self:DispatchType(ListModel.ON_CHANGED)
end

function ListModel:GetLength()
    if not self.mDataList then
        return 0
    end
    return #self.mDataList
end

--[[
    获取指定Key的数据
]]
function ListModel:GetData(key)
    return self.mDataMap[key]
end

--[[
    添加数据

    result true表示添加成功 false表示添加失败（兼容成更新）
]]
function ListModel:AppendData(item)
    local key = self:KeyOf(item)
    local result = true
    if not self.mDataMap[key]  then
        table.insert(self.mDataList,item)
    else
        result = false
    end
    self.mDataMap[key] = item
    if result then
        -- 子类如果重写了标记方法，需要在append时候通知下数据发生变化
        self:SetIsChange(true)
    end
    return result
end

--[[
    移除数据

    key 唯一ID
]]
function ListModel:DeleteData(key)
    self:DeleteDatas({key})
end

--[[
    移除数据（列表）
    keyList 唯一ID列表
]]
function ListModel:DeleteDatas(keyList)
    if #keyList > 0 then
        for _,key in ipairs(keyList) do
            self.mDataMap[key] = nil
        end
        self:SetIsChange(true)
        self:DispatchType(ListModel.ON_DELETED,keyList)
    end
end


--[[
    增量/全量：
        更新数据/增加数据/移除数据

    itemList 数据列表
    fullCheck 是否全量对比 默认不是
]]
function ListModel:UpdateDatas(itemList,fullCheck)
    local stateList = {};
    local map = {}
    if #itemList > 0 then
        local changeMap = {}
        local changeMapCustom = {}
        map["AddMap"] = {}
        map["UpdateMap"] = {}
        map["DeleteMap"] = {}
        local TheCurDataList = {}
        if fullCheck then
            TheCurDataList = self:GetDataList()
        end
        local TheNewDataMap = {}
        for _,vo in ipairs(itemList) do
            local key = self:KeyOf(vo)
            local keyCustom = self:CustomKeyOf(vo)
            TheNewDataMap[key] = vo
            local dataUpdateType = EDataUpdateType.NONE
            if self:IsValidOf(vo) then
                if not self.mDataMap[key] then
                    table.insert(map["AddMap"],vo)
                    dataUpdateType = EDataUpdateType.ADD
                else
                    table.insert(map["UpdateMap"],vo)
                    dataUpdateType = EDataUpdateType.UPDATE
                end
                self.mDataMap[key] = vo
            else
                table.insert(map["DeleteMap"],vo)
                dataUpdateType = EDataUpdateType.DELETE
                self.mDataMap[key] = nil
            end
            changeMap[key] = {Vo = vo,UpdateType = dataUpdateType}
            changeMapCustom[keyCustom] = {Vo = vo,UpdateType = dataUpdateType}
        end
        if fullCheck then
            for _,vo in pairs(TheCurDataList) do
                local key = self:KeyOf(vo)
                local keyCustom = self:CustomKeyOf(vo)
                if not TheNewDataMap[key] then
                    table.insert(map["DeleteMap"],vo)
                    self.mDataMap[key] = nil
                    changeMap[key] = {Vo = vo,UpdateType = EDataUpdateType.DELETE}
                    changeMapCustom[keyCustom] = {Vo = vo,UpdateType = EDataUpdateType.DELETE}
                end
            end
        end
        if #map["AddMap"] > 0 then
            table.insert(stateList,EDataUpdateType.ADD)
        end
        if #map["UpdateMap"] > 0 then
            table.insert(stateList,EDataUpdateType.UPDATE)
        end
        if #map["DeleteMap"] > 0 then
            table.insert(stateList,EDataUpdateType.DELETE)
        end
        self:SetIsChange(true)
        self:DispatchType(ListModel.ON_UPDATED,map)
        self:DispatchType(ListModel.ON_UPDATED_MAP,changeMap)
        self:DispatchType(ListModel.ON_UPDATED_MAP_CUSTOM,changeMapCustom)
    end
    return stateList,map;
end
