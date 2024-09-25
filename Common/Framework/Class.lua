---@generic S1, S2
---@param super S1
---@param super2 S2
---@return S1 | S2
function class(classname, super, super2)
    local superType = type(super)
    local cls

    if superType ~= "function" and superType ~= "table" then
        superType = nil
        super = nil
    end

    -- inherited from Lua Object
    if super then
        if super2 then
            cls = setmetatable( {super = super, super2 = super2}, {
                __index = function(_, k)
                    local ret = super[k]
                    if ret == nil then ret = super2[k] end
                    return ret
                end
            } )
        else
            cls = setmetatable({ super = super }, {__index = super})
        end

    else
        cls = { ctor = function() end }
    end

    cls.__cname = classname
    cls.__index = cls

    function cls.new(...)
        local instance = setmetatable({}, cls)
        --instance.class = cls
        instance:ctor(...)
        return instance
    end

    return cls
end

function getClassName(classOrInstance)
    return classOrInstance.__cname
end

function isInstance(classOrInstance, className)
    if getClassName(classOrInstance) == className then
        return true
    elseif classOrInstance.super and isInstance(classOrInstance.super, className) then
        return true
    elseif classOrInstance.super2 and isInstance(classOrInstance.super2, className) then
        return true
    end
    return false
end

-- 扩展class
function classmul(clsname, ...)
	local cls = { __cname = clsname }

	local args = { ... }
	if #args > 0 then
		setmetatable(cls, {
			__index = function(t, k)
				for i, v in ipairs(args) do
					local ret = v[k]
					if ret ~= nil then
						return ret
					end
				end
			end,
		})
	end

	cls.New = function(...)
		local self = setmetatable({ __classtype = cls }, { __index = cls })
		if cls.ctor then
			cls.ctor(self, ...)
		end
		return self
	end
	return cls
end