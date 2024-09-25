require("Core.Mvc.BaseClassInner");

G_ClassName2Class = G_ClassName2Class or {}
G_ClassIndexIncrement = G_ClassIndexIncrement or 1

local function GetAutoIncrementClassName()
	G_ClassIndexIncrement = G_ClassIndexIncrement + 1
	return "BaseClass" .. G_ClassIndexIncrement
end
 --[[lua基类]]
function BaseClass(super, class_name)
	if not class_name then
		class_name = GetAutoIncrementClassName()
		UnLua.LogWarn("BaseClass class_name nil,auto fix to:" .. class_name)
		UnLua.LogWarn(debug.traceback())
	end
	-- if G_ClassName2Class[class_name] then
	-- 	UnLua.LogError("BaseClass Same Class Name:" .. class_name .. "|Please Check!")
	-- 	UnLua.LogWarn(debug.traceback())
	-- 	return
	-- end
	local class_type = BaseClassInner(super,class_name)
	-- G_ClassName2Class[class_name] = class_type
	return class_type
end

return BaseClass