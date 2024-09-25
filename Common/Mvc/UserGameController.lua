--- 用户游戏控制器，
--- 1）更方便地注册协议事件
--- 2）提供了几个基础的可供重写的方法
--- 3）提供了 Timer 相关的函数接口，子类可以通过 self 直接调用
---
--- 【重写】
--- UserGameController:OnLogin(data)            --用户登入，用于初始化数据,当玩家帐号信息同步完成，会触发
--- UserGameController:OnLogout(data)           --用户登出，用于清除旧用户的数据相关  data有值表示为断线重连
--- UserGameController:OnPreEnterBattle()          --用户从大厅进入战斗处理的逻辑（即将进入，还未进入）
--- UserGameController:OnPreBackToHall()           --用户从战斗返回大厅处理的逻辑（即将进入，还未进入）
--- UserGameController:AddMsgListenersUser()    --填写需要监听的事件
---
--- 子类可以使用 self 调用的 Timer 函数
--- UserGameController:InsertTimer(TimeOffset, Func, Loop, TimerType, Name) --动态添加计时器
--- UserGameController:RemoveTimer(TimerObject)                             --动态移除计时器

local class_name = "UserGameController"
require("Core.Mvc.GameController")
---@class UserGameController : GameController
---@field super GameController
UserGameController = UserGameController or BaseClass(GameController,class_name)

function UserGameController:AddMsgListeners()
    UserGameController.super.AddMsgListeners(self)
    
    self.ProtoList = nil
    self.MsgList = nil
    self.MsgListGMP = nil
	self.TimerList = nil
    
    self:AddMsgListenersUser()    
    self:AddMsgListener(CommonEvent.ON_MAIN_LOGOUT,             self.OnLogoutHandler,   self)
    self:AddMsgListener(CommonEvent.ON_LOGIN_INFO_SYNCED,       self.OnLoginHandler,    self)
    self:AddMsgListener(CommonEvent.ON_RECONNECT_LOGOUT,       self.OnReconnectLogoutHandler,    self)
    self:AddMsgListener(CommonEvent.ON_GAME_INIT,       self.ON_GAME_INIT,    self)
    self:AddMsgListener(CommonEvent.ON_PRE_ENTER_BATTLE,       self.OnPreEnterBattleHandler,    self)
    self:AddMsgListener(CommonEvent.ON_PRE_BACK_TO_HALL,       self.OnPreBackToHallHandler,    self)
    self:AddMsgListener(CommonEvent.ON_AFTER_ENTER_BATTLE,       self.OnAfterEnterBattleHandler,    self)
    self:AddMsgListener(CommonEvent.ON_AFTER_BACK_TO_HALL,       self.OnAfterBackToHallHandler,    self)
    self:AddMsgListener(CommonEvent.ON_COMMON_DAYREFRESH,       self.OnDayRefreshHandler,    self)
    self:AddMsgListener(CommonEvent.ON_CULTURE_INIT,       self.OnCultureInitHandler,    self)
    
    CommonUtil.ProtoMsgRegisterOrUnRegister(self, self.ProtoList, true)
    CommonUtil.MvcMsgRegisterOrUnRegister(self, self.MsgList, true)
    CommonUtil.MsgGMPRegisterOrUnRegister(self.MsgListGMP, true)
    CommonUtil.TimerRegisterOrUnRegister(self.TimerList, true)
end

function UserGameController:RemoveMsgListeners()
    UserGameController.super.RemoveMsgListeners(self)
    
    self:RemoveMsgListener(CommonEvent.ON_MAIN_LOGOUT,         self.OnLogoutHandler,   self)
    self:RemoveMsgListener(CommonEvent.ON_LOGIN_INFO_SYNCED,   self.OnLoginHandler,    self)
    self:RemoveMsgListener(CommonEvent.ON_RECONNECT_LOGOUT,       self.OnReconnectLogoutHandler,    self)
    self:RemoveMsgListener(CommonEvent.ON_GAME_INIT,       self.ON_GAME_INIT,    self)
    self:RemoveMsgListener(CommonEvent.ON_PRE_ENTER_BATTLE,       self.OnPreEnterBattleHandler,    self)
    self:RemoveMsgListener(CommonEvent.ON_PRE_BACK_TO_HALL,       self.OnPreBackToHallHandler,    self)
    self:RemoveMsgListener(CommonEvent.ON_COMMON_DAYREFRESH,       self.OnDayRefreshHandler,    self)
    self:RemoveMsgListener(CommonEvent.ON_CULTURE_INIT,       self.OnCultureInitHandler,    self)

    CommonUtil.ProtoMsgRegisterOrUnRegister(self, self.ProtoList,false)
    self.ProtoList = nil
    CommonUtil.MvcMsgRegisterOrUnRegister(self, self.MsgList,false)
    self.MsgList = nil
    CommonUtil.MsgGMPRegisterOrUnRegister(self.MsgListGMP,false)
    self.MsgListGMP = nil
    CommonUtil.TimerRegisterOrUnRegister(self.TimerList,false)
    self.TimerList = nil
end

function UserGameController:ON_GAME_INIT()
    self:OnGameInit();
end

function UserGameController:OnLogoutHandler(data)
    self:OnLogout(data)
end


function UserGameController:OnLoginHandler(data)
    self:OnLogin(data)
end

function UserGameController:OnReconnectLogoutHandler(data)
    self:OnLogoutReconnect(data)
end

function UserGameController:OnPreEnterBattleHandler()
    self:OnPreEnterBattle()
end
function UserGameController:OnPreBackToHallHandler(data)
    self:OnPreBackToHall(data)
end
function UserGameController:OnAfterEnterBattleHandler()
    self:OnAfterEnterBattle()
end
function UserGameController:OnAfterBackToHallHandler(data)
    self:OnAfterBackToHall(data)
end
function UserGameController:OnDayRefreshHandler()
	self:OnDayRefresh()
end
function UserGameController:OnCultureInitHandler()
	self:OnCultureInit()
end


---【重写】游戏初始化完成，
---@param data any
function UserGameController:OnGameInit(data) end


---【重写】游戏文化初始化完成（初始化/文化发生改变时会调用），用于一些基础常量的定义，例如从字符串表取值(涉及到本地化的)
---@param data any
function UserGameController:OnCultureInit(data) end

---【重写】用户登入/重连，用于初始化数据,当玩家帐号信息同步完成，会触发
---【注意】重连情景也会触发  并不跟OnLogout成对出现，该接口可能会反复触发
--  data 为真表示 为断线重连 值为断线重连类型
---@param data any
function UserGameController:OnLogin(data) end

---【重写】用户登出，用于清除旧用户的数据相关  
---@param data any data暂地没用，占位
function UserGameController:OnLogout(data) end

---【重写】用户重连，登录，用于重连情景需要清除数据的场景
---@param data any data有值表示为断线重连类型
function UserGameController:OnLogoutReconnect(data) end

---【重写】用户即将从大厅进入战斗处理的逻辑
function UserGameController:OnPreEnterBattle()
end
---【重写】用户已经从大厅进入战斗处理的逻辑
function UserGameController:OnAfterEnterBattle()
end

---【重写】用户即将从战斗返回大厅处理的逻辑
---@param data any 无值代表正常从战斗返回 / { TravelFailedResult -- Travel失败原因枚举}
function UserGameController:OnPreBackToHall(data)
end
---【重写】用户已经从战斗返回大厅处理的逻辑
---@param data any 无值代表正常从战斗返回 / { TravelFailedResult -- Travel失败原因枚举}
function UserGameController:OnAfterBackToHall(data)
end

---【重写】用户跨天逻辑
function UserGameController:OnDayRefresh()
end

--[[
    --协议
    self.ProtoList = {
        事件名称                                     处理回调
        {MsgName = pb_ResID.Account_RepPlayerInfo,	Func = self.Account_RepPlayerInfo_Func},
    }
    
    --事件，通过Mvc框架进行绑定，框架事件或者是Model事件
    self.MsgList = {
        想要处理对应事件的Model，空值表示框架事件  事件名称                                     处理回调
        {Model = nil,                       MsgName = CommonEvent.ON_LOGIN_FINISHED,	Func = self.ON_LOGIN_FINISHED_Func},
    }
    
    --事件，通过MsgHelper进行绑定
    MsgListGMP = {
        事件绑定的UObject 事件会跟随UObject的生命周期进行自动销毁  事件名称        处理回调              是否是与C++交互的事件
  	    {InBindObject = xxx,                                MsgName = xxx, Func = self.On_xxx, bCppMsg = true,          WatchedObject = nil}
    }
--]]
---【重写】子类重写这个函数，填写需要监听的事件
function UserGameController:AddMsgListenersUser() end

---动态添加计时器
---@param TimeOffset number 延迟时间，可以使用 Timer.NEXT_TICK|Timer.NEXT_FRAME
---@param Func fun(deltaTime:number):void 计时器到点触发回调
---@param Loop boolean 是否为循环timer，如果为true则会在timer触发后，timeoffset秒之后执行(Timer.NEXT_TICK|Timer.NEXT_FRAME会在之后每一帧执行)
---@param TimerType number|nil TimerTypeEnum.Timer|CoroutineTimer|TimerDelegate, 默认为TimerTypeEnum.Timer
---@param Name string|nil 计时器名字，后续可以通过名字来移除计时器，名字也可以在timer报错时提供信息方便排查
---@return table Timer
function UserGameController:InsertTimer(TimeOffset, Func, Loop, TimerType, Name)
	TimerType = TimerType or TimerTypeEnum.Timer
	local TimerObject = { TimeOffset = TimeOffset, Func = Func, Loop = Loop,TimerType = TimerType,Name = Name }
	CommonUtil.TimerRegisterOrUnRegister({TimerObject}, true)
	if not TimerObject.TimerHandler then
		CError("UserGameController:InsertTimer:" .. self:ClassName() .. "|TimerHandler nil,please check",true)
		return
	end
	self.TimerList = self.TimerList or {}
	table.insert(self.TimerList, TimerObject)

	return TimerObject
end

---动态移除计时器
---@param TimerObject table Timer
function UserGameController:RemoveTimer(TimerObject)
	if not TimerObject.TimerHandler then
		CError("UserGameController:RemoveTimer:" .. self:ClassName() .. "|TimerHandler nil,please check",true)
		return
	end
	CommonUtil.TimerRegisterOrUnRegister({TimerObject},false)
    if self.TimerList then
		local FixTimerList = {}
		for k, v in ipairs(self.TimerList) do
			if v.TimerHandler then
				table.insert(FixTimerList,v)
			end
		end
		self.TimerList = FixTimerList
	end
end