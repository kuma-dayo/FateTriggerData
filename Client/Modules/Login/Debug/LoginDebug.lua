--
-- Debug
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.01.27
--
local LoginDebug = {}

function LoginDebug.ExecDebug()
    --[[
	LoginDebug.ExecPing()
	LoginDebug.ExecNetwork()
	LoginDebug.ExecGameFlow()
	LoginDebug.ExecStructObject()
	LoginDebug.ExecSaveGame()
	LoginDebug.ExecLuaMisc()
	LoginDebug.ExecGMPanel()
	]]
    LoginDebug.ExecDataTable()
end

function LoginDebug.ExecPing()
    local Ping1 = UE.US1MiscLibrary.GetPing("10.93.189.246")
    local Ping2 = UE.US1MiscLibrary.GetPing("www.baidu.com")
    print("LoginDebug", ">> ExecPing, ...", Ping1, Ping2)
end

function LoginDebug.ExecNetwork()
    LoginProxy:Get():ReqLogout()

    -- RoomInfo
    -- bd.player:ReqRoomInfo(1001)
    print("LoginDebug", ">> ExecNetwork, ...", Ping)
end

function LoginDebug.ExecGameFlow()
    -- if not self.bInitTest then
    --     self.bInitTest = true
    --     GameFlowSysTest:Init()
    -- else
    --     -- GameFlowSysTest:Next()
    --     GameFlowSysTest:EndCurNode()
    -- end
end

function LoginDebug.ExecStructObject()
    --[[
	-- UStruct - TArray
	local DSAgent = UE.UDSAgent.Get()
	local GISubSysClass = UE.UClass.Load("Class'/Script/S1Game.DSAgent'")
	DSAgent = DSAgent and DSAgent or UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(self, GISubSysClass)

	local NewPlayerData = UE.FS1GameDSPlayerData("Name", 10, 20)
	NewPlayerData.Name = "--Name--"
	NewPlayerData.PlayerId = 1008611
	NewPlayerData.TeamId = "22"
	DSAgent:AddPlayerData(NewPlayerData)
	print(DSAgent:ToString(), NewPlayerData)
	
	-- Ret TArray
	local RetPlayerDatas = DSAgent:GetPlayerDatasRet()
	print(RetPlayerDatas:Length(), RetPlayerDatas:Get(1).Name)

	-- FFunctionDesc::PostCall - Handling 'out' properties
	-- Out TArray - 0
	local InPlayerDatas0 = {}
	local PlayerDatas = DSAgent:GetPlayerDatas(InPlayerDatas0)
	print(PlayerDatas:Length(), PlayerDatas:Get(1).Name)
	print(table.tostring(InPlayerDatas0))
	
	-- Out TArray - 1
	local InPlayerDatas1 = UE.TArray(UE.FS1GameDSPlayerData)
	local PlayerDatas1 = DSAgent:GetPlayerDatas(InPlayerDatas1)
	print(InPlayerDatas1:Length(), InPlayerDatas1:Get(1).Name)
	print(PlayerDatas1:Length(), PlayerDatas1:Get(1).Name)		-- PlayerDatas1 is invalid/Nil!!!

	-- TArray<>&
	--static void GetAllWidgetsOfClass(UObject* WorldContextObject, TArray<UUserWidget*>& FoundWidgets, TSubclassOf<UUserWidget> WidgetClass, bool TopLevelOnly = true);
	local FoundWidgets = {}
	local MiscSystem = UE.UMiscSystem.GetMiscSystem(self)
	local WidgetClass = UE.UKismetSystemLibrary.LoadClassAsset_Blocking(MiscSystem.RoomPanelClass)
	local RetFoundWidgets = UE.UWidgetBlueprintLibrary.GetAllWidgetsOfClass(self, FoundWidgets, WidgetClass, true)
	print(table.tostring(FoundWidgets), table.tostring(RetFoundWidgets))
	print(RetFoundWidgets:Length(), GetObjectName(RetFoundWidgets:Get(1)), GetObjectName(RetFoundWidgets:GetRef(1)))
	]]
end

function LoginDebug.ExecSaveGame()
    -- SaveGame
    local SaveData = {
        [1] = 10086001,
        [2] = 10086002,
        PlayerName = "ls001",
        Account = "Account",
        [5] = 10086005
    }
    GameLog.Dump(SaveData, SaveData, 5)
    SaveGame:SaveFile("TestCache", SaveData)
    local TestCache = SaveGame:LoadFile("TestCache")
    GameLog.Dump(TestCache, TestCache, 5)
end

function LoginDebug.ExecLuaMisc()
    local function TestParams(InP1, ...)
        local ParamsList = {...}
        -- local ParamsList = table.pack(...)

        print(table.tostring(InP1))
        print(#ParamsList)
        print(table.tostring(ParamsList))
        print(table.unpack(ParamsList))

        local arr = {1, 2, 3, 4, 5}
        -- arr = { table.unpack(arr) }
        arr = table.pack(table.unpack(arr))
        print(table.tostring(arr))
    end

    -- table.unpack table.pack
    local P1 = {
        K = "k"
    }
    TestParams(P1, {
        Name = "1",
        "2"
    }, P1, self.Object, nil, "String")

    -- __index __newindex
    --[[local _Login = Login
	local _LoginMember = Login.Member
	local _LoginMiscMaxChar = Login.Misc.MaxChar_PlayerName
	local _LoginMiscMember = Login.Misc.Member
	--Login.Misc.MaxChar_PlayerName = "new value"
	Login.Misc.MaxChar = "new value"
	print(_Login, _LoginMember, _LoginMiscMaxChar, _LoginMiscMember)
	]]
end

function LoginDebug.ExecGMPanel()
    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then -- 局内
        local UIManager = UE.UGUIManager.GetUIManager(_G.GameInstance)
        if UIManager then
            local GMPanelKey = "UMG_GM"
            local bIsGMOpen = UIManager:IsAnyDynamicWidgetShowByKey(GMPanelKey)
            if bIsGMOpen then
                UIManager:TryCloseDynamicWidget(GMPanelKey);
            else
                UIManager:TryLoadDynamicWidget(GMPanelKey);
            end
        end
    else
        if MvcEntry:GetModel(ViewModel):GetState(ViewConst.GMPanel) then
            MvcEntry:CloseView(ViewConst.GMPanel)
        else
            MvcEntry:OpenView(ViewConst.GMPanel)
        end
    end
end

function LoginDebug.ExecDataTable()
    -- 蓝图结构行的数据表格读取奔溃...
    local DataRowKey = "AimCenter"
    local DataTablePath = "/Game/DataTable/UI/DT_TestHudLayoutData"
    -- local DataTablePath = "/Game/DataTable/UI/DT_BattleHudLayoutAsset"
    local DataTableObject = UE.UObject.Load(DataTablePath)
    local BaseDataRow = UE.UDataTableFunctionLibrary.GetRowDataStructure(DataTableObject, DataRowKey)
    print("LoginDebug", ">> ExecDataTable[0], ...", BaseDataRow)
    if BaseDataRow then
        print("LoginDebug", ">> ExecDataTable[1], ...", BaseDataRow.Parent, BaseDataRow.Asset, BaseDataRow.LayoutData,
            BaseDataRow.bAutoSize, BaseDataRow.ZOrder, BaseDataRow.Visibility)
    end
end

function LoginDebug.ExecGmCmd(...)
    print("LoginDebug", ">> ExecGmCmd start")

    local CmdName = ""
	local CmdArray = {}
    for k,v in ipairs({...}) do

        if(k == 2) then
            CmdName = v
        end

        if(k > 2) then
            table.insert(CmdArray,v)
        end

    end

    print("LoginDebug", ">> ExecGmCmd...", CmdName)

    local InData = {
        FuncName = CmdName;
        Param = CmdArray;
    }
    MvcEntry:GetCtrl(GMPanelCtrl):ReqCallFunc(InData)
end

function LoginDebug.ExecUIManager()
    --[[
    local MinimapWidget = UIManager:GetWidgetByHandle(MinimapHandle)
    --MsgHelper:SendCpp(nil, "UIManager.ShowByWidget", MinimapWidget, 0)        -- 无效
    --MsgHelper:SendCpp(nil, "UIManager.CloseByWidget", MinimapWidget, false)
    UIManager:SendShowByWidget(MinimapWidget, 0)
    UIManager:SendCloseByWidget(MinimapWidget, false)
    --local MinimapHandle1 = UIManager:ShowByWidget(MinimapWidget)
    --local bSucc = UIManager:CloseByWidget(MinimapWidget)
    Warning("DisplayHUD", ">> OnInit, ", GetObjectName(UIManager), GetObjectName(MinimapWidget),
                                MinimapHandle.Handle, MinimapHandle1 and MinimapHandle1.Handle, bSucc)
    ]]
end

function LoginDebug.ExecMath()
    -- table append
    -- table.move
    function Extend(t1, t2)
        return table.move(t2, 1, #t2, #t1 + 1, t1)
    end
    local a = {"a", "b"}
    local b = {"c", "d", "e"}
    local c = Extend(a, b)
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>[1_0]", table.tostring(a))
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>[1_1]", table.tostring(b))
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>[1_2]", table.tostring(c))

    -- table metatable __add
    local metatable = {
        __add = function(t1, t2)
            local ret = {}
            for i, v in ipairs(t1) do
                table.insert(ret, v)
            end
            for i, v in ipairs(t2) do
                table.insert(ret, v)
            end
            return ret
        end
    }
    local x = {1, 2, 3}
    local y = {4, 5, 6}
    setmetatable(x, metatable)
    setmetatable(y, metatable)
    local z = x + y
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>[2_0]", table.tostring(x))
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>[2_1]", table.tostring(y))
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>[2_2]", table.tostring(z))

    -- table.insert
    local function Union(a, b)
        local result = {}
        for k, v in pairs(a) do
            table.insert(result, v)
        end
        for k, v in pairs(b) do
            table.insert(result, v)
        end
        return result
    end
    local x1 = {1, 2, 3}
    local x2 = {8, 9, 10}
    local xx = Union(x1, x2)
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>[3]", table.tostring(xx))
end

function LoginDebug.ExecAddBuff(InActor, InBuffKey)
    print("LoginDebug", ">> ExecAddBuff, ", InActor, InBuffKey)

end

function LoginDebug.HotLoad(InActor)
    print("LoginDebug", ">> HotLoad[Original], ", InActor)

end

-- CommandLine: -skipcompile -ForceSDKEnable -RoomId=10086
function LoginDebug.ExecCommandLine(InActor)
    print("LoginDebug", ">> ExecCommandLine, ", InActor)

    local CommandLine = UE.UKismetSystemLibrary.GetCommandLine()
    local bIsCommandEnable = UE.UKismetSystemLibrary.ParseParam(CommandLine, "ForceSDKEnable")
    local RoomIdString, bHasRoomId = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "RoomId=")
    print("LoginDebug", ">> ExecCommandLine[V1], ", CommandLine)
    print("LoginDebug", ">> ExecCommandLine[V2], ", bIsCommandEnable, bHasRoomId, RoomIdString)
end

function LoginDebug.ExecLuaG(InActor)
    print("LoginDebug", ">> ExecLuaG, ", InActor)

	--[[do	-- 全局表数打印
		function treaverse_global_env(curtable, level)
			for key, value in pairs(curtable or {}) do
				local prefix = string.rep(" ", level * 5)
				print(string.format("%s%s(%s)", prefix, key, type(value)))

				-- 注意死循环
				if (type(value) == "table") and key ~= "_G" and (not value.package) then
					treaverse_global_env(value, level + 1)
				elseif (type(value) == "table") and (value.package) then
					print(string.format("%sSKIPTABLE:%s", prefix, key))
				end
			end
		end
		treaverse_global_env(_G, 0)
	end]]

	--[[do	-- 全局表修改测试
		local cf = loadstring(" local i=0  i=i+1 print(i) ")
	
		-- 从后面两个输出我们可以看出，生成的函数的环境就是全局_G
		print(cf, getfenv(cf), _G) -- function: 0025AF58      table: 00751C68 table: 00751C68
	
		-- 改变_G的值
		_G = {}
		cf() -- 1
	
		-- 虽然改变了_G的值，但函数的的环境仍然是全局环境table地址仍然是00751C68
		print(cf, getfenv(cf), _G) -- function: 0075AF58      table: 00751C68 table: 0075B468
	end]]
end

_G.LoginDebug = LoginDebug
return LoginDebug
