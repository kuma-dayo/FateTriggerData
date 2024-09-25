require("Core.BaseClass");

--单一类专用对象池
local class_name = "PoolUtil";
PoolUtil = PoolUtil or BaseClass(nil,class_name);
PoolUtil.serial_number = 0;
function PoolUtil:__init(class_ref)
	-- self.__class_name = "PoolUtil";

	if class_ref == nil or class_ref.New == nil then
		print("PoolUtil: 对象池初始化错误: 请给正确的类对象!");
		class_ref.New.error = false;
	end

	PoolUtil.serial_number = PoolUtil.serial_number +1;
	self.serial_id = PoolUtil.serial_number;

	self.class_ref = class_ref;
	self.obj_list = {};
	self.count = 0;
	self.limit = 10;
end

function PoolUtil:Length()
	local len = #self.obj_list;
	return len;	
end

function PoolUtil:GetInstance(bool)
	local obj = nil;
	local len = #self.obj_list;

	if len < 1 or bool then
		obj = self.class_ref.New();
		obj.__pool_id = self.serial_id;
		self.count = self.count + 1;

		if self.count > self.limit and not bool then
			print("PoolUtil: out of length", obj:ClassName(), "Created: "..self.count);
		end
	else
		obj = self.obj_list[len];
		table.remove(self.obj_list, len);
	end

	if obj and obj.Init then
		obj:Init()
	end

	return obj;	
end

function PoolUtil:CreateInstance(count)
	count = count or 1;
	local list = {};
	for i = 1, count do
		local obj = self:GetInstance(true);
		table.insert(list, obj);
	end

	for k, obj in ipairs(list) do
		self:Reclaim(obj)
	end

	return list;
end

function PoolUtil:Reclaim(obj)
	if obj == nil or obj.__pool_id ~= self.serial_id then
		local name = "";
		if obj ~= nil then
			name =  obj.__class_name;
		end
		print("PoolUtil: 对象回收错误: 非法对象!", name);
		return false;
	end

	if obj and obj.Recycle then
		obj:Recycle()
	end
	table.insert(self.obj_list, obj);

	return true;
	
end

function PoolUtil:Clear(del)
	del = del or true;
	for k, obj in pairs(self.obj_list) do
		if obj ~= nil and del then
			obj:Dispose();
		end
	end

	self.obj_list = {};

	return true;
	
end


--**************************************************
--对象池管理器
PoolManager = PoolManager or {};
PoolManager.pool_list = {};
PoolManager.pool_refer = {};

function PoolManager.GetPool(class_ref)
	local pool = PoolManager.pool_list[class_ref];
	if pool == nil then
		pool = PoolUtil.New(class_ref);
		PoolManager.pool_list[class_ref] = pool;
		PoolManager.pool_refer[pool.serial_id] = pool;
	end
	return pool;
end

function PoolManager.SetPool(class_ref, pool)
	PoolManager.pool_list[class_ref] = pool;
end

function PoolManager.GetInstance(class_ref)
	local pool = PoolManager.GetPool(class_ref);
	return pool:GetInstance();	
end

function PoolManager.CreateInstance(class_ref, count)
	local pool = PoolManager.GetPool(class_ref);
	return pool:CreateInstance(count);
end

function PoolManager.Reclaim(obj)
	
	local pool = PoolManager.pool_refer[obj.__pool_id];
	if pool == nil then
		return false;
	end

	return pool:Reclaim(obj);
	
end

function PoolManager.Clear()
	
	for k, pool in pairs(PoolManager.pool_list) do
		pool:Clear(true);
	end
	
	PoolManager.pool_list = {};
	PoolManager.pool_refer = {};
	
end