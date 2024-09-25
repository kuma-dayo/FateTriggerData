--
-- Bridge - Lua与Cpp
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.02.21
--

local BridgeHelper = _G.BridgeHelper or {}


-------------------------------------------- ExecCommand ------------------------------------

-- 通用执行入口
function BridgeHelper.Exec(InContext, InCmdString, InDelimiter)
	InDelimiter = InDelimiter or " "
	Log("BridgeHelper", ">> Exec[Start], ", InCmdString, InDelimiter)
	
	-- LuaObject Function Params
    local CmdArray = string.split(InCmdString, InDelimiter)
    if (#CmdArray < 2) or (CmdArray[1] == '') or (CmdArray[2] == '') then
		Error("BridgeHelper", ">> Exec[Fail], Invalid Params!!!", #CmdArray)
		return
	end

	local TableName, FuncName = CmdArray[1], CmdArray[2]
	local TableObj = _G[TableName]
	local TableFunc = TableObj and TableObj[FuncName] or nil
	if TableFunc then
		table.remove(CmdArray, 1, 1) table.remove(CmdArray, 1, 1)
		Log("BridgeHelper", ">> Exec[Ok]: ", TableName, FuncName, "CmdString: ".. InCmdString)
		
		TableFunc(InContext, table.unpack(CmdArray))
	else
		Error("BridgeHelper", ">> Exec[Fail]: ", TableName, FuncName, TableObj, TableFunc)
	end
end

-- 通用执行入口(Cpp)
function BridgeHelper.ExecFromCpp(InContext, InFuncString, InParamsString, InDelimiter)
	local CmdString = InFuncString .. " " .. InParamsString
	BridgeHelper.Exec(InContext, CmdString, InDelimiter)
end

-------------------------------------------- Platform ------------------------------------

-- Windows, Mac, IOS, Android, PS4, XboxOne, Linux
function BridgeHelper.IsPCPlatform()
	return UE.UGUIManager.IsPCPlatform()
end

function BridgeHelper.IsMobilePlatform()
	return UE.UGUIManager.IsMobilePlatform()
end

return BridgeHelper
