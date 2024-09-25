-- 二进制标志管理器
local class_name = "DitryFlag"
---@class DitryFlag
local DitryFlag = BaseClass(nil, class_name)

---@class DirtyFlagDefine
DitryFlag.DirtyFlagDefine = {
    NoChanged = 0,
}

DitryFlag.DirtyFlagDefineValue = {
}

function DitryFlag:__init(Param)
    self:InitDirtyFlagDefine(Param)
    self:Reset()
end

function DitryFlag:Reset()
    self.DirtyFlag = 0
    self:InitAllDirtyFlag()
    self.DirtyFlag = self.AllDirtyFlag
end

--- 设置所有状态为脏状态
function DitryFlag:SetAllFlagDirty()
    self.DirtyFlag = 0
    self:RefreshAllDirtyFlag()
    self.DirtyFlag = self.AllDirtyFlag
end

--- 初始化所有的DirtyFlag
function DitryFlag:InitAllDirtyFlag()
    self.AllDirtyFlag = 0
    for _, Flag in pairs(DitryFlag.DirtyFlagDefine) do
        local FlagValue = 1 << Flag
        DitryFlag.DirtyFlagDefineValue[Flag] = FlagValue
        self.AllDirtyFlag = self.AllDirtyFlag | FlagValue
    end
end

--- 刷新所有的DirtyFlag
function DitryFlag:RefreshAllDirtyFlag()
    self.AllDirtyFlag = 0
    for _, FlagValue in pairs(DitryFlag.DirtyFlagDefineValue) do
        self.AllDirtyFlag = self.AllDirtyFlag | FlagValue
    end
end

--- 初始化脏数据定义
---@param DirtyFlagList any
function DitryFlag:InitDirtyFlagDefine(DirtyFlagList)
    if not DirtyFlagList then
        return
    end
    for _, v in pairs(DirtyFlagList) do
        self:InsertDirtyByType(v)
    end
end

--- 动态插入DirtyFlag
---@param DirtyFlag DirtyFlagDefine
---@param IsDirty boolean
function DitryFlag:InsertDirtyByType(DirtyFlag, Offset)
    Offset = Offset or 0
    local NewDirtyFlag = Offset + DirtyFlag
    if DitryFlag.DirtyFlagDefineValue[NewDirtyFlag] then
        CWaring("[DitryFlag]InsertDirtyByType can not insert new value when exist define flag")
        return DitryFlag.DirtyFlagDefineValue[NewDirtyFlag]
    end
    local FlagValue = 1 << NewDirtyFlag
    DitryFlag.DirtyFlagDefineValue[NewDirtyFlag] = FlagValue
    self:RefreshAllDirtyFlag()
    return FlagValue
end

--- 设置脏数据状态
---@param DirtyFlag DirtyFlagDefine
---@param IsDirty boolean
function DitryFlag:SetDirtyByType(DirtyFlag, IsDirty, Offset)
    Offset = Offset or 0
    local NewDirtyFlag = Offset + DirtyFlag
    local FlagValue =  DitryFlag.DirtyFlagDefineValue[NewDirtyFlag]
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
function DitryFlag:IsDirtyByType(DirtyFlag, Offset, IsReset)
    Offset = Offset or 0
    local NewDirtyFlag = Offset + DirtyFlag
    local FlagValue =  DitryFlag.DirtyFlagDefineValue[NewDirtyFlag]
    if FlagValue == nil then
        return true
    end
    local Res = self.DirtyFlag & FlagValue > 0
    self:SetDirtyByType(DirtyFlag, false, Offset)
    return Res
end


return DitryFlag