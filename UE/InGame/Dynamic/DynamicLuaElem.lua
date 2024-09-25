require "UnLua"

DynamicLuaElem = { DynamicLuaPath = 0, RefObjName = {} }

function DynamicLuaElem:new(o, DynamicLuaPath, ObjectName)
	local o = o or {}
	setmetatable(o, {__index = self})
	o.DynamicLuaPath = DynamicLuaPath
	o.RefObjName = { ObjectName }
	return o
end

function DynamicLuaElem:AddRefObjectName(ObjectName)
	if not self:contains(self.RefObjName, ObjectName) then
		table.insert(self.RefObjName, ObjectName)
	end
end

function DynamicLuaElem:contains(t, element)
    if t == nil then
        return false
    end

    for _, value in pairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

function DynamicLuaElem:RemoveRefObjectName(ObjectName)
	local RemoveIndex = 0
	for Index, Value in ipairs(self.RefObjName) do
		if Value == ObjectName then
			RemoveIndex = Index
			break
		end
	end
	if RemoveIndex ~= 0 then
		table.remove(self.RefObjName, RemoveIndex)
	end
end

function DynamicLuaElem:RefObjectCount()
	return #self.RefObjName
end
