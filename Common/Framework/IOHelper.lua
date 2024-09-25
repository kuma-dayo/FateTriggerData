--
-- I/O
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.01.17
--

local IOHelper = _G.IOHelper or {}

local CacheLuaSavePathRoot = nil
local CacheStandardSavedDir = nil
local CacheSavedGamesDir = nil

-------------------------------------------- Config ------------------------------------

--[[
    LuaSaveDir:默认保存路径(../../../Saved/SaveGames/LuaFiles/)
    StandardSavedDir:标准保存路径(Android:标准App数据路径)(../../../Saved/)
    SaveGamesDir:数据存储路径(../../../Saved/SaveGames/)
]]
IOCachePathType = {
	LuaSaveDir = 1,
	StandardSavedDir = 2,
	SaveGamesDir = 3
}

-------------------------------------------- Logic ------------------------------------

-- 获取Lua默认存储路径
function IOHelper.GetLuaFileSavedDir(InFileName, InPathType)
	InFileName = InFileName or ""
	InPathType = InPathType or IOCachePathType.LuaSaveDir

	local LuaSavePathRoot = ""
	if InPathType == IOCachePathType.LuaSaveDir then
		if not CacheLuaSavePathRoot then
			CacheLuaSavePathRoot = UE.UUEPathHelper.ProjectSavedDirLua()
		end
		LuaSavePathRoot = CacheLuaSavePathRoot
	elseif InPathType == IOCachePathType.StandardSavedDir then
		if not CacheStandardSavedDir then
			CacheStandardSavedDir = UE.UUEPathHelper.ProjectSavedDir()

			if not IOHelper.FolderExists(CacheStandardSavedDir) then
				IOHelper.FolderCreate(CacheStandardSavedDir)
			end
		end
		LuaSavePathRoot = CacheStandardSavedDir
		-- print("warning: >> IOHelper.GetLuaFileSavedDir.", LuaSavePathRoot)
	elseif InPathType == IOCachePathType.SaveGamesDir then
		if not CacheSavedGamesDir then
			CacheSavedGamesDir = string.format("%s/SaveGames", UE.UUEPathHelper.ProjectSavedDir())

			if not IOHelper.FolderExists(CacheSavedGamesDir) then
				IOHelper.FolderCreate(CacheSavedGamesDir)
			end
		end
		LuaSavePathRoot = CacheSavedGamesDir
		-- print("Error: >> IOHelper.GetLuaFileSavedDir.", LuaSavePathRoot)
	end

	return string.format("%s/%s", LuaSavePathRoot, InFileName)
end

-- 加载路径数据lua
function IOHelper.LoadStringByLua(InPath, InMode, InLen)
	if IOHelper.FileExists(InPath) then
		local file = io.open(InPath, InMode)
		if file then
			local s
			if InLen then
				s = file:read(InLen)
			else
				s = file:read("*a")
			end
			file:close()
			return s
		end
	end
end

-- 文件是否存在
function IOHelper.FileExists(InPath)
	local file, err = io.open(InPath, "rb")
	if file then
		file:close()
	else
		print("IOHelper.FileExists:" .. err)
	end
	return file ~= nil
end

-- 文件夹是否存在
function IOHelper.FolderExists(InPath)
	return UE.UUEPathHelper.IsExistsFolder(InPath)
end

-- 文件夹创建
function IOHelper.FolderCreate(InPath)
	return UE.UUEPathHelper.CreateFolder(InPath)
end

_G.IOHelper = IOHelper
return IOHelper
