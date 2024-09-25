--
-- 保存数据
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2021.12.07
--

require("Common.Framework.IOHelper")
require("Common.Utils.CommonUtil");

local SaveGame = {
}

-- Const
SaveGame.SaveName = {
	Login = "LoginCache",
	Minimap = "MinimapCache",
}

-- 本地文件定义
local SaveFileSuffix = ".cache"
--local SaveFileDir = UE.UKismetSystemLibrary.GetProjectSavedDirectory()
local SaveFilePath = function (InFileName)
	return IOHelper.GetLuaFileSavedDir(InFileName)
	--return string.format("%s%s%s", SaveFileDir, InFileName, SaveFileSuffix)
end
SaveGame.SaveFilePath = SaveFilePath

-- 
local StringToValuePairs = {
	["true"] = true, ["false"] = false,
}

-- 加载本地文件
function SaveGame:LoadFile(InFileName)
	local RetTable = {}
	local SearchPath = SaveFilePath(InFileName)
	--print(InFileName, SearchPath)

	local File = io.open(SearchPath, "a+")
	if not File then
		GameLog.Warning("SaveGame", SearchPath.. " isn't found[LoadFile]!!!")
		return RetTable
	end

	-- 缓存并关闭文件
	local FileContent = tostring(File:read())
	io.close(File)
	if not FileContent then
		return RetTable
	end

	-- 去除首尾字符({})
	local TargetStr = string.sub(FileContent, 2, -2)
	local StringToValue = function(InString)
		local TryToNumber = tonumber(InString)
		if TryToNumber then
			return TryToNumber
		end
		for TmpKey, TmpValue in pairs(StringToValuePairs) do
			if (TmpKey == InString) then
				return TmpValue
			end
		end
		return InString
	end
	--print("SaveGame", ">> LoadFile, ", TargetStr, FileContent)

	-- 解析键值对
	local AllElemArray = string.split(TargetStr, ",")
	for i, KeyValuePiar in ipairs(AllElemArray) do
		--print("SaveGame", ">> LoadFile, ", "KeyValuePiar", KeyValuePiar)
		local KeyValueTable = string.split(KeyValuePiar, "=")
		local ParseParamNum = table.nums(KeyValueTable)
		if ParseParamNum == 2 then
			-- 键值对模式
			local Key = KeyValueTable[1]
			local Value = KeyValueTable[2]
			if string.find(Key, "%[") then
				Key = string.sub(Key, 2, -2)		-- remove '[]'
			end
			if string.find(Value, "%\"") then
				Value = string.sub(Value, 2, -2)	-- remove '""'
			end
			Key = StringToValue(Key)
			Value = StringToValue(Value)
			
			--print("SaveGame", ">> LoadFile, ", "Key-Value:", Key, Value)
			RetTable[Key] = Value
		elseif ParseParamNum == 1 then
			-- 数字序号模式
			local Value = StringToValue(KeyValueTable[1])

			--print("SaveGame", ">> LoadFile, ", "i-Value:", Value)
			RetTable[i] = Value
		end
	end
	--GameLog.Dump(RetTable)

	return RetTable
end

-- 保存本地文件
function SaveGame:SaveFile(InFileName, InTable, bClearSaveData)
	local SearchPath = SaveFilePath(InFileName)
	--print(InFileName, SearchPath)

	if not bClearSaveData then
		local CacheData = self:LoadFile(InFileName)
		if CacheData then
			for Key, Value in pairs(CacheData) do
				if not InTable[Key] then
					InTable[Key] = Value
				end
			end
		end
	end

	local File = io.open(SearchPath, "w+")
	if not File then
		GameLog.Warning("SaveGame", SearchPath.. " isn't found[SaveFile]!!!")
		return
	end

	local SaveString = table.tostring(InTable)
	--local SaveString = table.val_to_str(InTable)
	--print("SaveGame", ">> SaveFile, ", SaveString)

	File:write(SaveString)
	io.close(File)
end


--[[
    公用本地Cache读写  采用Json简单实现，不建议常用

    在Lua中替换USaveGame功能，实现轻量化
]]
local _cacheInfo = nil
local _dirty = true
local _cahceFileName = "localstorage.json"
local _Uid = 0
local _AccountId = ""

local function Save()
    _cacheInfo = _cacheInfo or {}
	-- if CommonUtil.IsPlatform_IOS() then
	-- 	CWaring("SaveGame IsPlatform_IOS return1")
	-- 	return
	-- end
    local saveStr = JSON:encode(_cacheInfo)
    CommonUtil.SaveStringToFileInSave(saveStr,_cahceFileName)
end

local function GenerateKey(Key,Root,IsAccount)
    local CacheKey = Key
    if not Root then
		if IsAccount then
			if string.len(_AccountId) <= 0 then
				CWaring("SaveGame AccountId nil========")
			else
				CacheKey = _AccountId .. "|" .. Key
			end
		else
			if _Uid <= 0 then
				CWaring("SaveGame Uid nil========")
			else
				CacheKey = _Uid .. "|" .. Key
			end
		end
    end
    return CacheKey
end

--[[
    存储器初始化
	先临时放置S1ClientHub进行初始化
	之前在ClientMain进行初始化，触发调用GFUnluaHelper  会找不到GFUnluaHelper
]]
function SaveGame.Init()
    if not _cacheInfo then
		_cacheInfo = {}
		-- if CommonUtil.IsPlatform_IOS() then
		-- 	CWaring("SaveGame IsPlatform_IOS return2")
		-- 	return
		-- end
        _cacheInfo = CommonUtil.JSONDecodeFileInSave(_cahceFileName) or {}
    end
end

function SaveGame.SetUid(Uid)
    _Uid = Uid
end

function SaveGame.SetAccountId(AccountId)
    _AccountId = AccountId
end

---根据对应的key和全局属性获取对应的本地数据
---@param Key string 读取的key值
---@param IsGlobal boolean|nil 参数nil或者false表示角色Id相关；为true表示全局值
---@param IsAccount boolean|nil IsGlobal为false/nil时生效 为true表示帐号Id相关
---@return any 本地存储的数据
function SaveGame.GetItem(Key, IsGlobal,IsAccount)
    local CacheKey = GenerateKey(Key, IsGlobal,IsAccount)

    return _cacheInfo[CacheKey]
end

---根据对应的key和全局值，存储对应的数据到本地
---@param Key string 存储的key值
---@param Value any 需要存储的数据
---@param IsGlobal boolean|nil 参数nil或者false表示角色Id相关；为true表示全局值
---@param IsAccount boolean|nil IsGlobal为false/nil时生效 为true表示帐号Id相关
function SaveGame.SetItem(Key, Value, IsGlobal,IsAccount)
    local CacheKey = GenerateKey(Key,IsGlobal,IsAccount)
    _cacheInfo[CacheKey] = Value

    Save()
end

-- SaveGame.Init()
_G.SaveGame = SaveGame
return SaveGame