G_ClassIdIncrement = G_ClassIdIncrement or 1

local function GetAutoIncrementClassId()
	G_ClassIdIncrement = G_ClassIdIncrement + 1
	if G_ClassIdIncrement >= math.maxinteger then
		G_ClassIdIncrement = 1
	end
	return G_ClassIdIncrement
end

--保存类类型的虚表
local _class = {}
 --[[lua基类]]
function BaseClassInner(super, class_name)
	-- 生成一个类类型
	local class_type = {};
	-- 在创建对象的时候自动调用
	class_type.__init = false;
	class_type.__dispose = false;
	-- class_type.__name = "BaseClass";
	if super ~= class_type then
		class_type.super = super;
	end

	class_type.__class_name = class_name;
	class_type.__inner_type = "lua"

	class_type.ClassName = function()
		if not class_type.__class_name then
			local obj = class_type.New();
			class_type.__class_name = obj:ClassName();
		end
		
		return class_type.__class_name;
	end

	--判断类结构父级继承关系
	class_type.IsClass = function(class_ref)
		if class_ref == nil then
			print("Error: class_ref is nil!");
			return false;
		end
		local super = class_type;
		while (super ~= nil) do
			if (super == class_ref) then
				return true;
			end
			super = super.super;
		end
		return false;
	end
	-- if(super == nil)then
	-- 	class_type.super_class_list = {};
	-- else
	-- 	class_type.super_class_list = super.super_class_list;
	-- end
	--[[实例化函数]]
	class_type.New = function(...)
		-- 生成一个类对象
		local obj = {}
		obj.__class_type = class_type;
		obj.__class_name = class_name or "BaseClassInner";
		obj.__class_id = GetAutoIncrementClassId()

		-- 在初始化之前注册基类方法
		setmetatable(obj, { __index = _class[class_type] })

		-- 注册一个dispose方法
		obj.Dispose = function(self)
			local _super = self.__class_type 
			while _super ~= nil do	
				if _super.__dispose then
					_super.__dispose(self)
				end
				_super = _super.super
			end
		end
		--[[取出类唯一ID]]
		obj.ClassId = function(self)
			return self.__class_id;
		end
		--[[取出类名，自定义：类.__class_name 或者 实例化对象的__class_name]]
		obj.ClassName = function(self)
			if class_type.__class_name then
				return class_type.__class_name;
			end
			return self.__class_name;
		end
		--[[
			判断类及父级类继承关系
		]]
		obj.IsClass = function(self, class_ref)
			-- print("-------------", self, class_ref)
			local _super = obj.__class_type;
			while _super ~= nil do
				if _super == class_ref then
					return true;
				end
				_super = _super.super;
			end

			return false;
		end

		-- 调用初始化方法
		do
			local create 
			create = function(c, ...)
				if c.super then
					create(c.super, ...)
				end
				if c.__init then
					c.__init(obj, ...)
				end
			end

			create(class_type, ...)
		end

		return obj
	end

	local vtbl = {}
	_class[class_type] = vtbl
 
	setmetatable(class_type, {__newindex =
		function(t,k,v)
			vtbl[k] = v
		end
		, 
		__index = vtbl, --For call parent method
	})
 
	if super then
		setmetatable(vtbl, {__index =
			function(t,k)
				local ret = _class[super][k]
				--do not do accept, make hot update work right!
				--vtbl[k] = ret
				return ret
			end
		})
	end
 
	return class_type
end
return BaseClassInner;