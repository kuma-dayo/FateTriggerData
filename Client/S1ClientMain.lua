--[[
    客户端入口 由 BP_ClientMainSubSystem 蓝图驱动
    用于初始化框架等等
]]

-- 存放全局协议
_G.s2c = _G.s2c or {} 
_G.c2s = _G.c2s or {} 

require "UnLua"
require("BaseRequire")
CommonUtil.IsDS = false
--[[
	旧框架基础

	目前用到旧协议框架及旧框架的内容有：
	局外自建房
	局外匹配
	局内结算
]]
require("Common.Framework.Class")
require("Common.Framework.CommFuncs")
require("Common.Framework.Json")
require("Common.Framework.Functions")
require ("Common.Framework.SaveGame")
require("Common.Framework.TimeUtils")
ConfigDefine    = require("Common.Framework.ConfigDefine")
IOHelper        = require("Common.Framework.IOHelper")
MsgDefine		= require("Common.Framework.MsgDefine")
-- MsgHelper		= require("Common.Framework.MsgHelper")
-- HttpHelper		= require("Common.Framework.HttpHelper")
BridgeHelper	= require("Common.Framework.BridgeHelper")
ObjectBase		= require("Common.Framework.ObjectBase")
--旧协议框架没了之后，这个需废弃
ProxyBase		= require("Common.Framework.ProxyBase")		
--旧协议框架没了之后，这个需废弃		
ModelManager	= require("Common.Framework.ModelManager")
---@type ConfigHelper
require("Common.Framework.G_ConfigHelper")
G_ConfigHelper:Init()
-- G_ConfigHelper   = require("Common.Framework.ConfigHelper").New()
MsgHelper		= require("Common.Framework.MsgHelper").New()
HttpHelper		= require("Common.Framework.HttpHelper").New()
require("Client.Net.HttpRequestJobLogic")
BridgeHelper		= require("Common.Framework.BridgeHelper")
_G.UIHelper		    = require("Common.Framework.UIHelper")
_G.UserWidget		= require("Common.Framework.UserWidget")
--旧协议框架没了之后，这个需废弃
G_ModelManager = ModelManager.New()

--[[旧框架功能+旧协议框架实现  后续需废弃]]
require("Client.Modules.Login.Debug.LoginDebug")
-- require ("Client.Modules.Login.Login")
-- require ("Client.Modules.Login.Lobby")

require("UE.InGame.BRGame.UI.HUD.DeadSettle.SettlementProtocol")
require ("UE.InGame.BRGame.UI.HUD.DeadSettle.Settlement")
SettlementProxy:Register()
--//


--MVC
require("Client.Common.UIHandler")
require("Client.Common.NetLoading")
require("Client.Common.UIAlert")
require("Client.Common.UILockFunctionTip")
require("Client.Common.UIMaskLayer")
require("Client.Common.InputShieldLayer")
require("Client.Common.UIDebug")

require("Client.Modules.Common.CommonConst")
require("Client.Modules.Common.CommonHallTab")
require("Client.Modules.Common.CommonBtnTips")
require("Client.Modules.Common.CommonBtnEnhanced")
require("Client.Modules.Common.CommonRedDot")
require("Client.Modules.Common.CommonHeadIcon")
require("Client.Modules.Common.CommonMenuTab")
require("Client.Modules.Common.CommonMenuTabUp")
require("Client.Modules.Common.CommonButtonExtend")
require("Client.Modules.Common.CommonTextBoxInput")
require("Client.Modules.Common.CommonMultiLineTextBoxInput")
require("Client.Modules.Common.CommonItemIcon")
require("Client.Modules.Common.CommonItemIconVertical")
require("Client.Modules.Common.CommonItemDescription")
require("Client.Modules.Common.CommonSkillIcon")
require("Client.Modules.Common.CommonMediaPlayer")
require("Client.Modules.Common.CommonCurrencyTip")
require("Client.Modules.Common.CommonListWASDControl")
require("Client.Modules.Common.CommonEditableSlider")
require("Client.Modules.Common.CommonCurrencyList")
require("Client.Modules.Common.CommonPrice")
require("Client.Modules.Common.CommonComboBox")
require("Client.Modules.Common.CommonPopUpPanel")
require("Client.Modules.Common.CommonTouchInput")
require("Client.Modules.Common.CommonPopQueue")
require("Client.Modules.Common.CommonEntryIcon")
require("Client.Modules.Common.CommonPopUpBgLogic")
require("Client.Modules.Common.CommonPopUpEditableSliderLogic")
require("Client.Modules.Common.CommonTabUpBar")
require("Client.Modules.Common.CommonCheckBox")
require("Client.Modules.Common.CommonDescription")
-- require("Client.Modules.Common.CommonScrollWidget")


require("Client.GameConfig")
require("Client.MainCtrl")

print("S1ClientMain", ">> MainInit, Lua_Ver: ", _VERSION)


--# LuaDebug 都先屏蔽了, 本地调试请自行打开

--## 一、使用 VS Code 调试Lua断点使用
--参考wiki: (UnLua 调式工具)[https://bytedance.feishu.cn/wiki/wikcnRiiWqlNthv0qMdgzMPjkJb]
--1.下载 *LuaPanda* 插件
--2.选择 LuaPanda 调试
--3.开启下方三行代码（反注释即可）
-- if UE.UGFUnluaHelper.IsEditor() then
-- -- 请勿提交！请勿提交！请勿提交！
--   require("LuaPanda").start("127.0.0.1", 8818)
-- end
--4.VS Code中开启调试
--5.运行游戏

--## 二、使用 Rider|IntelliJ 等 JetBrain 全家桶调试Lua断点使用
--参考wiki: (mobdebug Lua断点调试)[https://bytedance.feishu.cn/wiki/N445w3vDjiQQmVk09ofcg69WnMb]
--1.下载 *EmmyLua* 插件
--2.右上角新增一个配置 Edit Configuration，选择Lua Remote(Mobdebug)，并保存
--3.右上角点击Debug开启调试(Rider会出现提示Error:Sources root not found. 不需要关心，点击Debug即可。二次弹窗点击 Continue Anyway)
--4.Debug页签会出现 
--    Start mobdebug server at port:8172
--    Waiting for process connection...
--5.开启下一行代码（反注释即可）
--pcall(function() require("mobdebug").start() end)
--6.运行游戏


local S1ClientMain = Class()

function S1ClientMain:OnInitialize(GameInstance)
    self.Overridden.OnInitialize(self)
	print("S1ClientMain", "OnInitialize, ...")

    _G.GameInstance = GameInstance
	_G.MainSubSystem = self
	UE.UAsyncLoadingScreenLibrary.SetGameInstance(GameInstance)

	math.randomseed(os.time());
	GameConfig.Init()
	SaveGame.Init()

	--MVC框架初始化
	---@type MainCtrl
 	_G.MvcEntry = MainCtrl.New();
	_G.MvcEntry:Initialize();
end

function S1ClientMain:OnStart(GameInstance)
    self.Overridden.OnStart(self)
	print("S1ClientMain", "OnStart, ...")
	CommonUtil.g_client_main_start = true
	_G.MvcEntry:InitializeGame();
	CommonUtil.CheckMvcEntyActionCache();
    if _G.InitLevel then
		_G.InitLevel:OnShowByEngine()
	end
end

function S1ClientMain:OnDeinitialize()
    self.Overridden.OnDeinitialize(self)
	print("S1ClientMain", "OnDeinitialize, ...")

	if UE.UGFUnluaHelper.IsEditor() then
		require("LuaPanda").disconnect()
	 end
end

--[[
    Tick
]]
function S1ClientMain:ReceiveOnTick(DeltaTime)
	--print("S1ClientMain:ReceiveOnTick" .. DeltaTime)
    self.Overridden.ReceiveOnTick(self, DeltaTime)

    Timer.Tick(DeltaTime)
	-- SoundMgr:Tick(DeltaTime)
end

-- 地图开始加载
function S1ClientMain:ReceiveOnPreLoadMap(InMapName)
	print(">> S1ClientMain.OnPreLoadMap, ...", InMapName)
	MvcEntry:GetModel(ViewModel):DispatchType(ViewModel.ON_PRE_LOAD_MAP,InMapName)

	local MsgBody = { MapName = InMapName }
    MsgHelper:Send(nil, MsgDefine.LEVEL_PreLoadMap, MsgBody)
	MsgHelper:ReleaseInvalidObject()

	if MvcEntry:GetModel(CommonModel):HasListeners(CommonModel.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD) then
		print(">>1 S1ClientMain.OnPreLoadMap, ...", InMapName)
		MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD, InMapName)
	end
end

-- 地图加载完成
function S1ClientMain:ReceiveOnPostLoadMapWithWorld(InNewWorld, InLocalURL, InMapName)
	print(">>0 S1ClientMain.OnPostLoadMapWithWorld, ...", InNewWorld, InLocalURL, InMapName)

	MvcEntry:GetModel(ViewModel):DispatchType(ViewModel.ON_POST_LOAD_MAP,InMapName)
	local MsgBody = {
		NewWorld = InNewWorld, LocalURL = InLocalURL, MapName = InMapName
	}
    MsgHelper:Send(InNewWorld, MsgDefine.LEVEL_PostLoadMapWithWorld, MsgBody)
	MsgHelper:ReleaseInvalidObject()

	if MvcEntry:GetModel(CommonModel):HasListeners(CommonModel.ON_LEVEL_BATTLE_POSTLOADMAPWITHWORLD) then
		print(">>1 S1ClientMain.OnPostLoadMapWithWorld BattleMap, ...", InNewWorld, InLocalURL, InMapName)
		-- GameFlowSystem:ToState(GameFlow.EState.Battle)
		MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_LEVEL_BATTLE_POSTLOADMAPWITHWORLD, InMapName)
		MvcEntry:GetModel(MatchModel):DispatchType(MatchModel.ON_BATTLE_MAP_LOAED) --单独用MatchModel监听,怕影响MvcEntry:GetModel(CommonModel):HasListeners
	else
		print(">>1 S1ClientMain.OnPostLoadMapWithWorld NormalMap, ...", InNewWorld, InLocalURL, InMapName)
		MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_LEVEL_POSTLOADMAPWITHWORLD, InMapName)
	end
end

function S1ClientMain:ReceiveOnClientHitKeyStep(Message)
	-- print(StringUtil.Format("[KeyStep-->Client][{0}] ReceiveOnClientHitKeyStep",Message))

	MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_CLIENT_HIT_KEY_STEP,Message)
end

--[[
	接收到DS网络异常提示
]]
function S1ClientMain:ReceiveOnNetworkFailure(FailureType,ErrorMessage)
	CWaring("S1ClientMain:ReceiveOnNetworkFailure")
	-- if FailureType == UE.ENetworkFailure.ConnectionTimeout then
	-- 	CWaring("S1ClientMain:ReceiveOnNetworkFailure ConnectionTimeout")
	-- 	MvcEntry:GetCtrl(CommonCtrl):ExitBattle(ConstUtil.ExitBattleReson.NetworkFailure)
	-- end
	MvcEntry:GetCtrl(CommonCtrl):ExitBattle(ConstUtil.ExitBattleReson.NetworkFailure)
end

--[[
	接收到travelDS失败提示
]]
function S1ClientMain:ReceiveOnTravelFailure(FailureType,ErrorMessage)
	MvcEntry:GetCtrl(CommonCtrl):ExitBattle(ConstUtil.ExitBattleReson.TravelFailure)
end

--[[
	接收到连接DS失败提示
]]
function S1ClientMain:ReceiveOnNetSocketError()
	MvcEntry:GetCtrl(CommonCtrl):ExitBattle(ConstUtil.ExitBattleReson.NetSocketError)
end

--[[
	接收到本地文化发生改变
]]
function S1ClientMain:ReceiveOnCultureChange()
	CLog("S1ClientMain:ReceiveOnCultureChange")
	local SupportLanguage = MvcEntry:GetModel(LocalizationModel):ConvertCurrentLanguage2SupportLanguage(true)
	MvcEntry:GetModel(LocalizationModel):SetCurSelectLanTxtLanguage(SupportLanguage,false,false,true)
	--需要延迟一帧生效事件，需要等待文化相关的资产重新加载（文本本地化资产，文化映射，字体等等）
	Timer.InsertTimer(Timer.NEXT_FRAME,function ()
		MvcEntry:SendMessage(CommonEvent.ON_CULTURE_INIT)
	end)
end

--[[
    App切入后台
	注意：此接口在IOS系统运行时呼出其他窗口时不会触发
]]
function S1ClientMain:OnAppWillEnterBackground()
	CLog("S1ClientMain:OnAppWillEnterBackground")
	if _G.MvcEntry == nil then
		return 
	end
	MvcEntry:SendMessage(CommonEvent.ON_APP_WILL_ENTER_BACKGROUND)

	if CommonUtil.IsPlatform_Windows() then
		--TODO 针对PC平台，补足事件
		MvcEntry:SendMessage(CommonEvent.ON_APP_WILL_DEACTIVATE)
	end
end

--[[
    App切回前台
	注意：此接口在IOS系统运行时呼出其他窗口时不会触发
]]
function S1ClientMain:OnAppHasEnteredForeground()
	CLog("S1ClientMain:OnAppHasEnteredForeground")
	if _G.MvcEntry == nil then
		return 
	end
	MvcEntry:SendMessage(CommonEvent.ON_APP_HAS_ENTERED_FOREGROUND)

	if CommonUtil.IsPlatform_Windows() then
		--TODO 针对PC平台，补足事件
		MvcEntry:SendMessage(CommonEvent.ON_APP_HAS_REACTIVATED)
	end
end

--[[
	App即将停用

	注意：此接口在PC系统不会触发
]]
function S1ClientMain:OnAppWillDeactivate()
	CLog("S1ClientMain:OnAppWillDeactivate")
	if _G.MvcEntry == nil then
		return 
	end
	MvcEntry:SendMessage(CommonEvent.ON_APP_WILL_DEACTIVATE)
end
--[[
	App已经重新激活

	注意：此接口在PC系统不会触发
]]
function S1ClientMain:OnAppHasReactivated()
	CLog("S1ClientMain:OnAppHasReactivated")
	if _G.MvcEntry == nil then
		return 
	end
	MvcEntry:SendMessage(CommonEvent.ON_APP_HAS_REACTIVATED)
end

---------------------------------着色器预编译相关-------------------------------
function S1ClientMain:ReceiveShaderPrecompileWorking(RemainTasksNum,TotalTasksNum)
	if _G.MvcEntry == nil then
		return 
	end
	local Param = {
        RemainTasks = RemainTasksNum,
        TotalTasks = TotalTasksNum,
    }
	MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_SHADER_PRECOMPILE_UPDATE,Param)
end
function S1ClientMain:ReceiveShaderPrecompileComplete(TotalTasksNum)
	if _G.MvcEntry == nil then
		return 
	end
	local Param = {
        TotalTasks = TotalTasksNum,
    }
	MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_SHADER_PRECOMPILE_COMPLETE,Param)
end

return S1ClientMain