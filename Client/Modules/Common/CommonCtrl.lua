--[[
    用于一些游戏内杂项的处理（不适合独立成模块管理的）

    例如一些公用的方法（方法需要应用框架机制或者事件等等）
]]
require("Client.Modules.Common.CommonModel");
local TablePool = require("Common.Utils.TablePool")

local class_name = "CommonCtrl";
---@class CommonCtrl : UserGameController
CommonCtrl = CommonCtrl or BaseClass(UserGameController,class_name);


function CommonCtrl:__init()
    self.model = nil
end

function CommonCtrl:Initialize()
    self.model = self:GetModel(CommonModel)
    self.TheViewModel = self:GetModel(ViewModel)
    self.TheHallModel = self:GetModel(HallModel)
end
function CommonCtrl:OnGameInit()
    self.CacheOnHallLookupLayers = {
        UIRoot.UILayerType.Pop,
        UIRoot.UILayerType.Dialog,
    }
end

---【重写】用户从大厅进入战斗处理的逻辑
function CommonCtrl:OnLogout()
    --[[
        记录需要cache的行为，待下述条件都满足时会自动执行：
        1.在大厅界面（HallMdt）
        2.大厅展示已准备好，参考HallModel:GetIsHallReady 参数
        3.当前没有Pop、Dialog层界面打开
    ]]
    CWaring("CommonCtrl:OnLogout")
    self.CacheOnHallActionList = nil
    -- self:RemoveCacheOnHallActionTimer()
end

---【重写】用户即将从大厅进入战斗处理的逻辑
function CommonCtrl:OnPreEnterBattle()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    if PlayerController then
        UE.UKismetSystemLibrary.ExecuteConsoleCommand(GameInstance, StringUtil.FormatSimple("r.Lumen.TraceGlobalSDF 1"), PlayerController)
    end
    MvcEntry:GetCtrl(PreLoadCtrl):UnLoadOutSideAction()
end

---【重写】用户从战斗返回大厅处理的逻辑
function CommonCtrl:OnPreBackToHall()
    local PlayerController = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
    UE.UKismetSystemLibrary.ExecuteConsoleCommand(GameInstance, "r.Lumen.Reflections.ScreenTraceOnlyCharacter 1", PlayerController)
end

function CommonCtrl:OnAfterBackToHall()
    -- 将退出战斗字段挪到VirtualHall打开后重置，避免多次跑StartLoading，但VirtualHall只打开一次，结束一次Loading，导致Loading关闭不了
    self.IsExitingBattle = false
    MsgHelper:SendCpp(GameInstance, ConstUtil.MsgCpp.GAMESTAGE_BATTLE_TO_HALL_END)
end


function CommonCtrl:AddMsgListenersUser()
    self.MsgList = {
        { Model = ViewModel, MsgName = ViewConst.Hall,    Func = self.OnHallState },
        { Model = ViewModel, MsgName = ViewModel.ON_AFTER_SATE_DEACTIVE_CHANGED,    Func = self.ON_AFTER_SATE_DEACTIVE_CHANGED_Func },
        { Model = HallModel, MsgName = HallModel.ON_HALL_READY_UPDATE,    Func = self.ON_HALL_READY_UPDATE_Func },

        {Model = nil,MsgName = CommonEvent.ON_APP_WILL_DEACTIVATE,Func = self.OnAppWillDeactivate}, 
        {Model = nil,MsgName = CommonEvent.ON_APP_HAS_REACTIVATED,Func = self.OnAppHasReactivated},
        {Model = CommonModel, MsgName = CommonModel.ON_HALL_TAB_SWITCH_COMPLETED,	Func = self.ON_HALL_TAB_SWITCH_COMPLETED_func },  --大厅场景切换完成
    }
    self.MsgListGMP = {
		{ InBindObject = _G.MainSubSystem,	MsgName = "AsyncLoadingScreen_LoadingStarted",Func = Bind(self,self.OnAsyncLoadingScreenLoadingStarted), bCppMsg = true, WatchedObject = nil },
		{ InBindObject = _G.MainSubSystem,	MsgName = "AsyncLoadingScreen_LoadingFinished",Func = Bind(self,self.OnAsyncLoadingScreenLoadingFinished), bCppMsg = true, WatchedObject = nil },
    }
end

--[[
    异步Loading加载开始
]]
function CommonCtrl:OnAsyncLoadingScreenLoadingStarted()
    CWaring("== AsyncLoadingScreen_LoadingStarted")
    if self:GetModel(ViewModel):GetState(ViewConst.LevelHall) then
        -- 从大厅准备进局内
        self.model:DispatchType(CommonModel.ON_ASYNC_LOADING_START_TO_BATTLE)
    end
end

--[[
    异步Loading加载完成
]]
function CommonCtrl:OnAsyncLoadingScreenLoadingFinished()
    CWaring("== AsyncLoadingScreen_LoadingFinished")
    self.model:DispatchType(CommonModel.ON_ASYNC_LOADING_FINISHED)
    if self:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then
        -- 从大厅进入局内
        CWaring("== AsyncLoadingScreen_LoadingFinished Battle")
        self.model:DispatchType(CommonModel.ON_ASYNC_LOADING_FINISHED_BATTLE)
    else
        -- 从局内返回大厅
        CWaring("== AsyncLoadingScreen_LoadingFinished Hall")
        self.model:DispatchType(CommonModel.ON_ASYNC_LOADING_FINISHED_HALL)
    end
end


function CommonCtrl:OnHallState(State)
    if not State then
        self:GetModel(HallModel):SetIsHallReady(false)
    end
end
function CommonCtrl:ON_AFTER_SATE_DEACTIVE_CHANGED_Func(ViewId)
    self:__CheckCacheOnHallAction()
end
function CommonCtrl:ON_HALL_READY_UPDATE_Func()
    CWaring("CommonCtrl:ON_HALL_READY_UPDATE_Func")
    self:__CheckCacheOnHallAction()
end

function CommonCtrl:ON_HALL_TAB_SWITCH_COMPLETED_func()
    CWaring("CommonCtrl:ON_HALL_TAB_SWITCH_COMPLETED_func")
    self:__CheckCacheOnHallAction()
end
--[[
    触发条件：
    1.界面关闭
    2.HallModel.IsHallReady 值发生改变
    3.大厅顶部页签切换
]]
function CommonCtrl:__CheckCacheOnHallAction()
    if not self.CacheOnHallActionList then
        return
    end
    if #self.CacheOnHallActionList <= 0 then
        TablePool.Recycle("CommonCtrl", self.CacheOnHallActionList)
        self.CacheOnHallActionList = nil
        return
    end
    local NewList = TablePool.Fetch("CommonCtrl")
    local NewListIdx = 1
    for k,ActionInfo in ipairs(self.CacheOnHallActionList) do
        local CanDelete = false
        if self:__CheckHallActionCondition() then
            if not ActionInfo.ExtraCheck or ActionInfo.ExtraCheck() then
                CWaring("CommonCtrl:__CheckCacheOnHallAction Trigger Cache Action")
                ActionInfo.Action()
                CanDelete = true
            end
        end
        if not CanDelete then
            CWaring("CommonCtrl:__CheckCacheOnHallAction Add/Update Cache Action")
            NewList[NewListIdx] = ActionInfo
            NewListIdx = NewListIdx + 1
        end
    end
    TablePool.Recycle("CommonCtrl", self.CacheOnHallActionList)
    self.CacheOnHallActionList = NewList
end
function CommonCtrl:__CheckHallActionCondition()
    if CommonUtil.IsInBattle() then
        CWaring("CommonCtrl:__CheckHallActionCondition IsInBattle")
        return false
    end
    --[[
        注意单纯的判断Hall是不行的，还需要额外判断LevelBattle
        局外Travel进战斗的阶段

        加载地图， LevelBattle状态会置为true
        加载成功， 才会将旧关卡状态置为false
        恢复Tick
        (旧逻辑会在这边触发弹窗，因为条件会满足，由其他界面被动关闭触发，但此时Hall的还没触发被动卸载)
        开始卸载旧关卡之前创建的所有UMG，这个时候才会触发Hall的被动关闭
    ]]
    if not self.TheViewModel:GetState(ViewConst.Hall) then
        CWaring("CommonCtrl:__CheckHallActionCondition Hall Not Exist")
        return false
    end
    if not self.TheHallModel:GetIsHallReady() then
        CWaring("CommonCtrl:__CheckHallActionCondition GetIsHallReady Not Ready")
        return false
    end
    local OpenList = self.TheViewModel:GetOpenListByLayerList(self.CacheOnHallLookupLayers)
    if #OpenList > 0 then
        CWaring("__CheckHallActionCondition OpenList Length>0:" .. OpenList[1].viewId)
        return false
    end
    return true
end


-------------------------------------------------------------公用方法-------------------------------------------------------

--[[
    返回到登录场景

    local Param = {
		LogoutActionType  （MSDKConst.LogoutActionTypeEnum） 登出类型
	}
]]
function CommonCtrl:GAME_LOGOUT(Param)
    CLog("CommonCtrl:GAME_LOGOUT")
    if _G.GameInstance:GetGameStageType() == UE.EGameStageType.Travel2Battle then
        CWaring("CommonCtrl:GAME_LOGOUT: Travel Connect failed,Break Travel")
        if _G.MainSubSystem then
            --TODO 需要将Travel流程进行强制中止
            _G.MainSubSystem:ShutdownUnrealNetwork()
        end
        local PlayerController = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
        if PlayerController then
            CWaring("CommonCtrl:GAME_LOGOUT: bShowMouseCursor true")
            PlayerController.bShowMouseCursor = true
            MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_SHOWMOUSECURSOR,true)
        end
        MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP)
    end
    if _G.GameInstance:GetGameStageType() == UE.EGameStageType.Travel2Battle or _G.GameInstance:GetGameStageType() == UE.EGameStageType.Battle then
        CWaring("CommonCtrl:GAME_LOGOUT: StopLoadingScreen")
        --TODO 手动停止Loading界面
        UE.UAsyncLoadingScreenLibrary.StopLoadingScreen();
    end
    -- 停止登录预加载,避免登录预加载期间登出了还继续预加载导致流程错误
    MvcEntry:GetCtrl(PreLoadCtrl):StopPreloadOutSideAction()
    CommonUtil.NetLogUserName()
    MvcEntry:GetCtrl(UserSocketLoginCtrl):SetTriedCount(0);
    MvcEntry:GetCtrl(UserSocketLoginCtrl):CleanPingInfo();
    MvcEntry:GetCtrl(UserSocketLoginCtrl):ResetReConnectState(UserSocketLoginCtrl.EReConnectType.NONE)
    CommonUtil.g_in_play = false
    local TheSocketMgr = MvcEntry:GetModel(SocketMgr);
    TheSocketMgr:Close();
    --清除协议转圈
    NetLoading.Close();
    -- 在ON_MAIN_LOGOUT之前，先关闭上层所有界面，避免OnHide有逻辑依赖于Model，因为数据被清除，导致无法正常执行
    if not MvcEntry:GetModel(ViewModel):GetState(ViewConst.VirtualLogin) then
        MvcEntry:GetCtrl(ViewRegister):CloseAll()
    end
    --发送事件
    MvcEntry:SendMessage(CommonEvent.ON_MAIN_LOGOUT);

    --针对子系统，需要隐藏切换帐号及退出帐号按钮
    if MvcEntry:GetCtrl(OnlineSubCtrl):IsOnlineEnabled() then
        CommonUtil.QuitGame()
    else
        --返回到欢迎关卡
        MvcEntry:OpenView(ViewConst.VirtualLogin,Param);
    end
end

--[[
    退出战斗
    @param ExitReason退出原因  不填则默认为  ConstUtil.ExitBattleReson.Normal
]]
function CommonCtrl:ExitBattle(ExitReason)
    MvcEntry:GetModel(HallModel):SetIsLevelTravel(false)
    if not CommonUtil.g_in_playing then
        CWaring("CommonCtrl:ExitBattle: CommonUtil.g_in_playing false,So Break")
        return
    end
    if self.IsExitingBattle then
        CWaring("CommonCtrl:ExitBattle: Exiting")
        return
    end
    if not CommonUtil.IsInBattle() then
        CWaring("CommonCtrl:ExitBattle: IsInBattle false,So Break")
        return
    end
    if _G.GameInstance:GetGameStageType() == UE.EGameStageType.Travel2Battle then
        CWaring("CommonCtrl:ExitBattle: Travel Connect failed,Break Travel")
        MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP)
        return
    end
    ExitReason  = ExitReason or ConstUtil.ExitBattleReson.Normal
    self.IsExitingBattle = true
    CLog("CommonCtrl.ExitBattle")

    -- 结算G Table数据需要退出时清理
    SettlementProxy:ResetSettlement()

	local TheReqLoadingJob = nil
	local EnterFunc = function()
       
		CWaring("CommonCtrl:EnterFunc")
        local AlreadyEnter = false
        local EnterFuc2 = function()
            if TheReqLoadingJob then
                --可能存在超时情况，需要将请求Loading的Job停掉
                TheReqLoadingJob:Close()
                TheReqLoadingJob = nil
            end
            if AlreadyEnter then
                CWaring("CommonCtrl:ExitBattle EnterFuc2 AlreadyEnter")
                return
            end
            AlreadyEnter = true
            InputShieldLayer.Close()

            local PlayerController = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
            UE.UKismetSystemLibrary.ExecuteConsoleCommand(GameInstance, "ForceGC", PlayerController)
            --Lua侧GC
            LuaGC()
            local Param = {
                ExitBattleReason = ExitReason,
            }
            MvcEntry:OpenView(ViewConst.VirtualHall,Param)
            if ExitReason == ConstUtil.ExitBattleReson.Normal then
                --属于玩家主动退出对局，才需要发送协议
                MvcEntry:GetCtrl(UserCtrl):SendProto_PlayerExitDSReq(ExitReason)
            end
        end
        --[[
            添加超时接口
        ]]
        InputShieldLayer.Add(15,1,function ()
            --超时
            CWaring("CommonCtrl:EnterFuc2 Maybe TimeOut")
            EnterFuc2()
        end)
        local LoadingShowParam = {
            TypeEnum = LoadingCtrl.TypeEnum.BATTLE_TO_HALL,
        }
        TheReqLoadingJob = MvcEntry:GetCtrl(LoadingCtrl):ReqLoadingScreenShow(LoadingShowParam,EnterFuc2)
	end
    EnterFunc()
end

--[[
    是否 玩家大厅网络错误提示已弹出
]]
function CommonCtrl:IsPoppingServerCloseTip()
    if self:GetModel(ViewModel):GetState(ViewConst.MessageBoxSystem) then
        return true
    end
    return false
end

--[[
    弹出返回主界面提示
    describe 描述

    NeedQuitGame 是否需要退出游戏，而不是返回登录
]]
function CommonCtrl:PopGameLogoutBoxTip(describe,NeedQuitGame)
    if self:IsPoppingServerCloseTip() then
        CWaring("poppingServerCloseTipInstance already pop!!!")
        return
    end

    local msgParam = {
        describe = describe,
        rightBtnInfo = {
            callback = function()
                if not NeedQuitGame then
                    self:GAME_LOGOUT();
                else
                    UE.UKismetSystemLibrary.QuitGame(GameInstance,CommonUtil.GetLocalPlayerC(),UE.EQuitPreference.Quit,true)
                end
            end
        },
        closeCallback = function()
            self.poppingServerCloseTipInstance = nil
        end,
        HideCloseBtn = true,
        HideCloseTip = true,
    }
    UIMessageBox.Show_System(msgParam)
    -- 断开socket
    local socketMgr = self:GetModel(SocketMgr)
    socketMgr:Close("ErrorCode")
end

--[[
    跳转到某个界面
    id 参数为 跳转表的唯一ID
]]
function CommonCtrl:JumpTo(id)
    local jumpCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_JumpCfg,Prop_JumpCfg.Id,id)
    if not jumpCfg then
        return
    end
    local jumpId = jumpCfg[Prop_JumpCfg.JumpId]
    self:OpenView(tonumber(jumpId))
end

--[[
    尝试检查条件执行：（（常用于贴脸功能，功能开启弹窗，活动相关的拍脸提示））
    1.条件满足直接执行
    2.条件不满足会注册进cahce列表，待条件满足会自动执行

    条件：
    1.在大厅界面（HallMdt）
    2.大厅展示已准备好，参考HallModel:GetIsHallReady 参数
    3.当前没有Pop、Dialog层界面打开

    参数：
    TheAction 需要执行的Action行为 
    ExtraCheckFunc  额外的Action行为可执行条件（可选）
]]
function CommonCtrl:TryFaceActionOrInCache(TheAction,ExtraCheckFunc)
    if not TheAction then
        return
    end
    if not self.CacheOnHallActionList then
        self.CacheOnHallActionList = TablePool.Fetch("CommonCtrl")
    end
    self.CacheOnHallActionList[#self.CacheOnHallActionList + 1] = {
        ["Action"] = TheAction,
        ["ExtraCheck"] = ExtraCheckFunc,
    }

    self:__CheckCacheOnHallAction()
end


--[[
	兼容SDK双鼠标问题
	需要在  窗口进入后台 			去隐藏鼠标
	需要在  窗口进入后台前台 	 	去显示鼠标
]]
--[[窗口进入后台]]
function CommonCtrl:OnAppWillDeactivate()
	if CommonUtil.IsInBattle() then
		return
	end
	--隐藏鼠标
	MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_SHOWMOUSECURSOR,false)
end

--[[窗口进入后台前台]]
function CommonCtrl:OnAppHasReactivated()
	if CommonUtil.IsInBattle() then
		return
	end
	--显示鼠标
	MvcEntry:GetModel(CommonModel):DispatchType(CommonModel.ON_SHOWMOUSECURSOR,true)
end