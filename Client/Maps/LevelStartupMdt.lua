--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"
require("Core.BaseClass");
require("Client.Mvc.GameMediator");
require("Common.Utils.CommonUtil");

local class_name = "LevelStartupMdt";
LevelStartupMdt = LevelStartupMdt or BaseClass(GameMediator, class_name);


_G.InitLevel = nil

function LevelStartupMdt:__init()
end

function LevelStartupMdt:OnShow(data)
	
end

function LevelStartupMdt:OnHide()
	
end

-------------------------------------------------------------------------------------
---@class LevelStartupMdt_C
local M = Class()

function M:Initialize(Initializer)
	CLog("LevelStartupMdt==========Initialize")
	_G.InitLevel = self
end
function M:ReceiveBeginPlay()
	self.Overridden.ReceiveBeginPlay(self)	
	CLog("LevelStartupMdt==========ReceiveBeginPlay")
end
function M:CheckInitAction()
	if not self.CheckInit then
		self.CheckInit = true


		--TODO 根据Cmd决定是否需要打开热更新流程
		local OpenHotUdpateFunc = false
		local CommandLine = UE.UKismetSystemLibrary.GetCommandLine()
		local bUseHotRenew = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "UseHotRenew=")
		CWaring("bUseHotRenew:" .. (bUseHotRenew and 1 or 0))
		if bUseHotRenew =="false" or CommonUtil.IsPlatform_IOS() or UE.UGFUnluaHelper.IsEditor() then
			OpenHotUdpateFunc = false
		else
			OpenHotUdpateFunc = true
		end

		local HealthAdviceActive = true
		if MvcEntry:GetCtrl(OnlineSubCtrl):IsOnlineEnabled() then
			--健康忠告界面，在子系统登录时不打开
			HealthAdviceActive = false
		end

		--是否启用着色器预编译功能
		local IsShaderPrecompileActive = true
		if not UE.UGFUnluaHelper.IsShaderPrecompilationManual() then
			IsShaderPrecompileActive = false
		end
		if UE.UGFUnluaHelper.IsEditor() then
			IsShaderPrecompileActive = false
		end

		--[[
			顺序打开的列表界面
			会按顺序打开第一个界面，等界面关闭会按顺序打开后一个
			所有阶段执先完成，会跳转至 self:Jump2Login()
			{
				--界面ID
				ViewId = ViewConst.StartupPanel,
				--定制参数（可选）
				Param = nil
				--是否将此条配置关闭，不执行，默认false（可选）
				IsClose
			},
		]]
		self.SequentialOpenViewList = {
			--健康忠告界面
			{ViewId = ViewConst.HealthAdvice,Param = nil,IsClose = not HealthAdviceActive},
			--热更新下载界面
			{ViewId = ViewConst.DownloadPatchPanel,Param = nil,IsClose = not OpenHotUdpateFunc},
			--着色器预编译界面
			{ViewId = ViewConst.ShaderPrecompile,Param = nil,IsClose = not IsShaderPrecompileActive},
			-- 准备加载资源
			{ViewId = ViewConst.ReadyToLoadResource,Param = nil,IsClose = false},
			
		}
		self.SequentialId = 0

		--[[
			计算最后展示的那个界面  最后显示的界面，通过ExtraCloseCheck不让其关闭，
			1.因为最终会触发关卡切换，让关卡切换触发关闭即可
			2.在关闭切换时，保持此界面展示，避免显示空场景
		]]
		self.SequentialIdLast = 0
		for k,v in ipairs(self.SequentialOpenViewList) do
			if not v.IsClose then
				self.SequentialIdLast = k
			end
		end
		

		MvcEntry:GetModel(ViewModel):AddListener(ViewModel.ON_SATE_DEACTIVE_CHANGED,self.ON_SATE_DEACTIVE_CHANGED_Func,self)
		MvcEntry:GetCtrl(ViewController):AddExtraCloseCheckFunc("LevelStartupMdt",Bind(self,self.ExtraCloseCheckFunc))
	end
end
function M:ReceiveEndPlay(EndPlayReason)
	_G.InitLevel = nil
	CLog("LevelStartupMdt==========ReceiveEndPlay")
	self.Overridden.ReceiveEndPlay(self,EndPlayReason)	

	if self.CheckInit then
		MvcEntry:GetModel(ViewModel):RemoveListener(ViewModel.ON_SATE_DEACTIVE_CHANGED,self.ON_SATE_DEACTIVE_CHANGED_Func,self)
		MvcEntry:GetCtrl(ViewController):RemoveExtraCloseCheckFunc("LevelStartupMdt")
	end
end

--[[
	初始关卡，游戏一启动即会加载此关卡（此关卡蓝图的Initialize和ReceiveBeginPlay会优于S1ClientHUB:OnInit调用）

	所以在初始关卡的Initialize方法里面，记录全局变量_G.InitLevel
	再由Raf_ClientHub  在 OnInit 方法里面主动调用Cl
]]
---@public
function M:OnShowByEngine()
	CLog("LevelStartupMdt==========OnShowByEngine")
	if CommonUtil.g_in_game == false then
		CommonUtil.g_in_game = true
		--由引擎打开的场景，并非由mvc打开的，需要强制改变mvc的状态
		MvcEntry:GetModel(ViewModel):SetState(ViewConst.LevelStartup, true,nil,UIRoot.UILayerType.Scene);
		MvcEntry:GetModel(ViewModel).show_LEVEL = ViewConst.LevelStartup
		MvcEntry:GetModel(ViewModel).show_LEVEL_Fix = ViewConst.LevelStartup
		self.ViewId = ViewConst.LevelStartup
		CLog("LevelStartupMdt==========OnShowByEngine3")

		self:OnShow()
		CLog("LevelStartupMdt==========OnShowByEngine4")
	end
end

---@private
function M:OnShow(data)
	MvcEntry:GetCtrl(EventTrackingCtrl):ReqOnStepFlow(EventTrackingCtrl.LoginBeforEnum.StartClient)

	self:CheckInitAction()
	self:GetCommandLineParams()
	if self.SequentialIdLast > 0 then
		self:DoSequentialOpenView()
	else
		self:Jump2Login()
	end
end

--[[
	按顺序执行预设步骤
]]
function M:DoSequentialOpenView()
	self.SequentialId = self.SequentialId + 1
	local ViewConfig = self.SequentialOpenViewList[self.SequentialId]

	if not ViewConfig then
		return
	end
	if ViewConfig.IsClose then
		CWaring("M:DoSequentialOpenView: Close Jump Next:" .. ViewConfig.ViewId)
		self:DoSequentialOpenView()
	elseif ViewConfig.CustomWaitCustomLogic then
        CWaring("M:DoSequentialOpenView: CustomWaitCustomLogic")
        ViewConfig.CustomWaitCustomLogic()
	else
		MvcEntry:OpenView(ViewConfig.ViewId,ViewConfig.Param)
	end
end

--[[
	某些界面关闭时回调
]]
function M:ON_SATE_DEACTIVE_CHANGED_Func(ViewId)
	local ViewConfig = self.SequentialOpenViewList[self.SequentialId]
	if not ViewConfig then
		return
	end
	if ViewConfig.ViewId == ViewId then
		CWaring("M:ON_SATE_DEACTIVE_CHANGED_Func Close,Try Triiger Next")
		self:DoSequentialOpenView()
	end
end
--[[
	关闭界面检查
]]
function M:ExtraCloseCheckFunc(Event)
	local ViewId = Event.viewId
	local ViewConfig = self.SequentialOpenViewList[self.SequentialIdLast]
	if ViewConfig then
		if ViewConfig.ViewId == ViewId then
			CWaring("M:ExtraCloseCheckFunc Close,ExtraClose false,not aloow to close view:" .. ViewId)
			self:Jump2Login()
			return false
		end
	end
	return true
end


--获取命令行参数(满足自动登录及进入房间)
function M:GetCommandLineParams()
	---@type UserModel
	local UserModel = MvcEntry:GetModel(UserModel)
	-- local OutCommonToken = {}
	-- local OutSwitches = {}
	-- local OutParams = {}
	-- local CommandLine = "-LoginName=guohong13 -LoginIp=127.0.0.1 -LoginPort=13751 -LoginRoomId=1 -LoginConnectServerId=0 -IsLoginByCMD=1 -SelectHeroId=200050000" --LoginName:登录用用户名, LoginIp及LoginPort不多解释, LoginRoomId房间ID, LoginConnectServerId:连接用服务器ID IsLoginByCMD:是否启用自动登录(0否1是)
	local CommandLine = UE.UKismetSystemLibrary.GetCommandLine()
	CWaring("CommandLine:" .. CommandLine)

	-- 设置新手引导开启状态
	local GMOpenGuideStateNum = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "GuideOpenState=")
	if GMOpenGuideStateNum and GMOpenGuideStateNum ~= "" then
		local GMOpenGuideState = tonumber(GMOpenGuideStateNum) == 1
		MvcEntry:GetCtrl(GuideCtrl):SetGMGuideOpenState(GMOpenGuideState)
	end
	-- 设置协议打印log开关状态
	local GMOpenNetProtoLogStateNum = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "OpenNetProtoLogState=")
	if GMOpenNetProtoLogStateNum and GMOpenNetProtoLogStateNum ~= "" then
		local GMOpenNetProtoLogState = tonumber(GMOpenNetProtoLogStateNum) == 1
		MvcEntry:GetCtrl(NetProtoLogCtrl):SetGMOpenNetProtoLogState(GMOpenNetProtoLogState)
	end

	--自动匹配相关指令参数
	-- CommandLine = "-LoginName=automatch5 -LoginIp=10.97.218.214 -LoginPort=13751 -IsLoginByCMD=1 -IsAutoEnterCustomRoom=1 -IsAutoStartCustomRoom=0 -CustomRoomModeId=1001 -CustomRoomView=3 -CustomRoomTeamType=4 -CustomRoomDsGroupId=3 -CustomRoomConfigId=1001 -CustomRoomSceneId=101 -CustomRoomMaxPlayerNum=10 -CustomRoomTimeToStart=40 -CustomRoomId=77877 -CustomRoomTeamNumLimit=11 -ParentDSExtParams=zz -DSExtParams=ll"
	-- local CommandLineEnable = UE.UKismetSystemLibrary.ParseParam(CommandLine, )
	-- local CommandLineParse = UE.UKismetSystemLibrary.ParseCommandLine(CommandLine, OutCommonToken, OutSwitches, OutParams)
	local IsLoginByCMD = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "IsLoginByCMD=")
	IsLoginByCMD = tonumber(IsLoginByCMD)
	if not IsLoginByCMD or IsLoginByCMD == 0 then --等同false
		return
	end
	UserModel.IsLoginByCMD = true
	UserModel.CMDLoginRoomID = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "LoginRoomId=")
	UserModel.CMDLoginRoomID = tonumber(UserModel.CMDLoginRoomID)
	UserModel.CMDLoginServerIP = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "LoginIp=")
	UserModel.CMDLoginName = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "LoginName=")
	UserModel.CMDLoginConnectServerId = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "LoginConnectServerId=")
	UserModel.CMDLoginConnectServerId = tonumber(UserModel.CMDLoginConnectServerId)
	UserModel.CMDLoginServerPort = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "LoginPort=")
	UserModel.CMDSelectHeroId = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "SelectHeroId=")

	--自动匹配相关
	local IsAutoMatch = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "IsAutoMatch=")
	UserModel.IsAutoMatch = IsAutoMatch and IsAutoMatch == "1" or false
	UserModel.CMDAutoMatchCfg = {
		DsGroupId			= UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "DsGroupId="),
		GameplayId			= UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "GameplayId="),
		LevelId				= UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "LevelId="),
		View				= UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "View="),
		TeamType			= UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "TeamType="),
		FillTeam			= UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "FillTeam="),
		IsCrossPlatformMatch= UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "IsCrossPlatformMatch="),
	}

	--自动创建自建房
	local IsAutoEnterCustomRoomNum = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "IsAutoEnterCustomRoom=")
	local IsAutoEnterCustomRoom = IsAutoEnterCustomRoomNum and tonumber(IsAutoEnterCustomRoomNum) == 1

	--是否自动开启自建房对局
	local IsAutoStartCustomRoomNum = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "IsAutoStartCustomRoom=")
	local IsAutoStartCustomRoom = IsAutoStartCustomRoomNum and tonumber(IsAutoStartCustomRoomNum) == 1
	----------- 创建自建房参数----------
	-- 是否自动进入自建房 0否1是 转换后为Boolean
	UserModel.IsAutoEnterCustomRoom = IsAutoEnterCustomRoom
	-- 是否自动开启自建房对局 0否1是 转换后为Boolean  一般用于单人测试直接开始游戏，多人的情况不需要自己开始游戏
	UserModel.IsAutoStartCustomRoom = IsAutoStartCustomRoom
	UserModel.CMDAutoEnterCustomRoomCfg = {
		-- 自建房模式Id 对应CustomRoomConfig.xlsx里的模式Id字段
		CustomRoomModeId         = tonumber(UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "CustomRoomModeId=") or 1001),
		-- 自建房视角 1，3
		CustomRoomView           = tonumber(UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "CustomRoomView=") or 3),
		-- 自建房队伍人数
		CustomRoomTeamType       = tonumber(UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "CustomRoomTeamType=") or 4),
		-- 自建房房主所在的DsGroupId，即选择的ds服务器环境
		CustomRoomDsGroupId      = tonumber(UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "CustomRoomDsGroupId=") or 3),
		-- 自建房ConfigId 对应CustomRoomConfig.xlsx里的ConfigId字段
		CustomRoomConfigId       = tonumber(UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "CustomRoomConfigId=") or 1001),
		-- 自建房地图ID 对应CustomRoomConfig.xlsx里的地图池字段
		CustomRoomSceneId        = tonumber(UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "CustomRoomSceneId=") or 101),
		-- 自建房最大人数，开局
		CustomRoomMaxPlayerNum   = tonumber(UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "CustomRoomMaxPlayerNum=") or 10),
		-- 自建房存在当前时间后自动开局
		CustomRoomTimeToStart    = tonumber(UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "CustomRoomTimeToStart=") or 40),
		-- 自建房房间Id 必须保证为正数
		CustomRoomId             = tonumber(UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "CustomRoomId=") or 777777),
		-- 自建房队伍数量
		CustomRoomTeamNumLimit   = tonumber(UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "CustomRoomTeamNumLimit=") or 16),
		-- 父DS扩展命令行参数，仅用于DS Fork模式时，父DS扩展命令行参数   转发给服务器
		ParentDSExtParams 		 = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "ParentDSExtParams=") or "",
		-- DS扩展命令行参数，非DS Fork模式 和 DS Fork模式下 子DS使用 的扩展命令行参数   转发给服务器
		DSExtParams 		 	 = UE.UKismetSystemLibrary.ParseParamValue(CommandLine, "DSExtParams=") or "",
	}	
end

--[[
	所有阶段完成，最终跳转到登录  由 ExtraCloseCheckFunc 触发
]]
function M:Jump2Login()
	MvcEntry:OpenView(ViewConst.VirtualLogin)

	--异步Loading测试
	-- local EnterFunc = function()
	-- 	MvcEntry:OpenView(ViewConst.VirtualLogin)
	-- end
	-- local LoadingShowParam = {
	-- 	TypeEnum = LoadingCtrl.TypeEnum.HALL_TO_BATTLE,
	-- 	Level = 5,
	-- 	SettlementRankIndex = 4,
	-- }
	-- MvcEntry:GetCtrl(LoadingCtrl):ReqLoadingScreenShow(LoadingShowParam,EnterFunc)
	-- Timer.InsertTimer(5,function ()
	-- 	CWaring("StopLoadingScreen2")
	-- 	UE.UAsyncLoadingScreenLibrary.StopLoadingScreen()
	-- end)
	-- -- 异步加载测试
	-- MvcEntry:GetCtrl(PreLoadCtrl):PreLoadOutSideAction(function ()
	-- 	MvcEntry:OpenView(ViewConst.VirtualLogin)
	-- end,true)
end

return M
