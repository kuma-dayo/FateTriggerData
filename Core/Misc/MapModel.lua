--[[
    数据Map列表管理器
]]
local super = GameEventDispatcher;
local class_name = "MapModel";
---@class MapModel : GameEventDispatcher
MapModel = BaseClass(super, class_name);

MapModel.ON_CHANGED = "ON_CHANGED"
MapModel.ON_DELETED = "ON_DELETED"
MapModel.ON_UPDATED = "ON_UPDATED"

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

function MapModel:__init()	
    self.mDataMap = {}
    self.mDataList = {}
    self.mDataLength = 0
    self.mIsChanged = false
    --保证数据更新后顺序不变，消耗一点儿性能，如查有必要，可对其赋值。
    self.keepSortIndexFunc = nil
end

function MapModel:__dispose()	

end

function MapModel:OnLogout()	
    self:Clean()
end

function MapModel:SetIsChange(value)
    self.mIsChanged = value
end

function MapModel:GetIsChange()
    return self.mIsChanged
end

function MapModel:GetDataList()
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

function MapModel:CheckSortDataList()
    if self.keepSortIndexFunc then
        table.sort(self.mDataList,self.keepSortIndexFunc)
    end
end

--[[
    清空所有数据缓存
]]
function MapModel:Clean()
    self.mDataMap = {}
end

function MapModel:SetDataMap(mapList)
    self:UpdateDatas(mapList,true)
end

function MapModel:GetDataMap()
    return self.mDataMap
end


function MapModel:GetLength()
    return self.mDataLength
end

function MapModel:GetData(key)
    return self.mDataMap[key]
end

--[[
    更新数据/增加数据/移除数据

    map 数据Map列表
    fullCheck 是否全量  默认是增量
]]
function MapModel:UpdateDatas(mapList,fullCheck)
    local map = {}
    map["AddMap"] = {}
    map["UpdateMap"] = {}
    map["DeleteMap"] = {}

    for _k, _v in pairs(mapList) do
        if self.mDataMap[_k] == nil then 
            self.mDataLength = self.mDataLength + 1
            table.insert(map["AddMap"], {k = _k, v = _v})  
        else
            table.insert(map["UpdateMap"], {k = _k, v = _v})  
        end
        self.mDataMap[_k] = _v
    end
    if fullCheck then
        self.mDataLength = 0
        local NewDataMap = {}
        for _k, _v in pairs(self.mDataMap) do
            if mapList[_k] == nil then
                table.insert(map["DeleteMap"], {k = _k, v = _v})  
            else
                NewDataMap[_k] = _v
                self.mDataLength = self.mDataLength + 1
            end
        end
        if #map["DeleteMap"] > 0 then
            self.mDataMap = NewDataMap
        end
    end

    local stateList = {}
    if #map["AddMap"] > 0 then
        table.insert(stateList,EDataUpdateType.ADD)
    end
    if #map["UpdateMap"] > 0 then
        table.insert(stateList,EDataUpdateType.UPDATE)
    end
    if #map["DeleteMap"] > 0 then
        table.insert(stateList,EDataUpdateType.DELETE)
    end

    if #stateList > 0 then 
        self:SetIsChange(true)
        self:DispatchType(MapModel.ON_UPDATED,map)    
    end

    return stateList, map
end
