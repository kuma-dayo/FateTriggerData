require "UnLua"
require "InGame.Dynamic.DynamicLuaElem"

local DynamicLuaMgr = Class()

function GetDynamicLuaInstance()
    if not _G.DynamicLuaMgr then
        _G.DynamicLuaMgr = DynamicLuaMgr
        _G.DynamicLuaMgr.Init()
    end
    return _G.DynamicLuaMgr
end

function DynamicLuaMgr.Init()
    _G.DynamicLuaTable = {} -- class is DynamicLuaElem
end

function DynamicLuaMgr.GetDynamicLua(DynamicLuaPath)
    if _G.DynamicLuaTable[DynamicLuaPath] then
        return require(DynamicLuaPath)
    end
    return nil
end

function DynamicLuaMgr.LoadDynamicLua(ObjectName, DynamicLuaPath)
    if not ObjectName or ObjectName == "" then
        return
    end
    
    if not DynamicLuaPath or DynamicLuaPath == "" then
        return
    end
    
    if _G.DynamicLuaTable[DynamicLuaPath] then
        _G.DynamicLuaTable[DynamicLuaPath]:AddRefObjectName(ObjectName)
    else
        require(DynamicLuaPath)
        local Elem = DynamicLuaElem:new(nil, DynamicLuaPath, ObjectName)
        _G.DynamicLuaTable[DynamicLuaPath] = Elem
    end
end

function DynamicLuaMgr.UnLoadDynamicLua(ObjectName, DynamicLuaPath)
    if not ObjectName or ObjectName == "" then
        return
    end

    if not DynamicLuaPath or DynamicLuaPath == "" then
        return
    end

    if _G.DynamicLuaTable[DynamicLuaPath] then
        _G.DynamicLuaTable[DynamicLuaPath]:RemoveRefObjectName(ObjectName)
    end

    if _G.DynamicLuaTable[DynamicLuaPath]:RefObjectCount() == 0 then
        -- unload dynamic lua
        package.loaded[DynamicLuaPath] = nil
        _G.DynamicLuaTable[DynamicLuaPath] = nil
    end
end

return DynamicLuaMgr