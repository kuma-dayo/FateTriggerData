---@class UserWidgetBase
UserWidgetBase = Class("Core.Events.EventDispatcherUn")
local TablePool = require("Common.Utils.TablePool")

--[[
	子类可重写方法（以下实现按顺序执行）：
	OnInit  用于委托列表，事件列表的声明及初始化
    OnShow  界面打开动作时会调用，可传参数
	OnShowAvator  界面展示会触发/此界面打开情况下上层虚拟关卡被关卡  （用于3D物品的展示和隐藏）
	OnHideAvator  界面关闭状态或者销毁时会调用/此界面打开情况下再打开虚拟关卡会触发 （用于3D物品的展示和隐藏）
    OnHide  界面关闭状态或者销毁时会调用
	OnDestroy 界面销毁时被调用

	生命周期  VisibleMode 销毁模式
	Construct
	OnInit
	PreOnShow
	OnShow
	Destruct (VisibleMode 隐藏模式 下此方法不会调用）
	PreOnHide
	OnHide
	OnDestroy (VisibleMode 隐藏模式 下此方法不会调用）

	BindNodes 结构范例：
	--UDelegate 需要绑定的多播
	--Func  处理回调
	self.BindNodes = {
		{ UDelegate = self.BtnMvcTest.OnClicked,	Func = self.OnClicked_BtnMvcTest },
	}

	BindUniNodes 结构范例：
	--UDelegate 需要绑定的单播
	--Func  处理回调
	self.BindUniNodes = {
		{ UDelegate = self.TouchImage.OnMouseButtonDownEvent,	Func = self.OnClicked_BtnMvcTest },
	}

    MsgList结构范例：
    --Model 想要处理对应事件的Model，空值表示框架事件
    --MsgName  事件名称
    --Func  处理回调
	--Priority 回调优先级，值越大越优先执行
	self.MsgList = {
		{Model = nil, MsgName = CommonEvent.ON_LOGIN_FINISHED,	Func = self.ON_LOGIN_FINISHED_Func},
	}

	MsgListGMP结构范例：
	--MsgName  事件名称
    --Func  处理回调
	--bCppMsg  是否是与C++交互的事件
	MsgListGMP = {
		{ MsgName = xxx, Func = self.On_xxx, bCppMsg = true }
	}

	MvvmBindList 结构范例：
	--Model         绑定的指定Model
	--BindSource  	绑定的源（可以是回调，可以是具有SetText方法的UMG控件）
    --PropertyName  绑定的Model里面的属性名称
	--MvvmBindType  绑定类型
	MvvmBindList = {
		{ Model = UserModel, BindSource = self.LbName, PropertyName = "PlayerName", MvvmBindType = MvvmBindTypeEnum.SETTEXT }
	}

	TimerList  计时器结构范例（基于UObjectTick去实现）
	--TimeOffset (必填) 单位是秒 0的话，遇到tick就会执行；-1的话，会在下一帧执行。
	--Func   (必填) 执行回调
	--Loop  boolean 是否循环（可选，默认为false）
	--TimerType 计时器类型 （可选，默认为TimerTypeEnum.Timer）
	--Name  计时器名称（可选）

	--TimerHandler 隐藏值 ，当计时器生效时，此值会存在
	TimerList = {
		{ TimeOffset = 1, Func = Bind(self,self.OnUpdate), Loop = false,TimerType = TimerTypeEnum.Timer ,Name = Name}
	}
]]
function UserWidgetBase:Construct()
	EventDispatcherUn.Construct(self)
	-- CWaring("UserWidgetBase:Construct():"  .. self:GetName())

	--是否UI不可用（不在逻辑生命周期）
	self.IsDisposeUI = false
	self.IsMvcPreOnShow = false
	--是否锁定输入,锁定后，InputModel的事件只有匹配到当前展示的ViewId才会生效
	self.InputFocus = true
	--是否关闭Focus；设置为true则界面打开（关闭）不会触发当前界面（上一界面）的CommonModel.ON_WIDGET_TO_FOCUS。用于确定无需输入事件的界面
	self.CloseWidgetFocus = false
	self.IsConstruct = true

	self:DataInitInner()

	self:OnInit()
	self:ShowUIByNodeConstruct()
end
function UserWidgetBase:Destruct()
	CWaring("UserWidgetBase:Destruct():" .. self:GetName())
	self:OnDestroy()
	if  self.IsConstruct then
		self:DisposeUIByNodeDestruct()
	else
		-- 防止有子类继承，但覆盖了Construct，没有调用Super
		local TipStr = "UserWidgetBase: Not Construct! Please Check Is Override :" .. self:GetName()
		CError(TipStr,true)
		EnsureCall(TipStr)
	end
	self:DispatchType(CommonEvent.ON_DESTRUCT)
	EventDispatcherUn.Destruct(self)
	-- 解除LuaTable在C++侧的引用
	self:Release()
end

function UserWidgetBase:DataInitInner()
	--[[
		BindNodes  （多播）
		BindUniNodes  （单播）
		MsgList					通过Mvc框架进行绑定，框架事件或者是Model事件
		MsgListGMP				通过MsgHelper进行绑定
		跟随UMG生命周期进行绑定和解绑
	]]
	self.BindNodes = nil
	self.BindUniNodes = nil
	self.MsgList = nil
	self.MsgListGMP = nil
	self.MvvmBindList = nil
	--[[
		计时器管理
	]]
	self.TimerList = nil
	--注册ShowUI和DisposeUI的回调
	self.ShowUICallBackList = {}
	self.DisposeUICallBackList = {}
	self.DestructUICallBackList = {}
	--//
	--注册虚拟场景触发的显示/隐藏回调
	self.OnVirtualTriggerShowCallBackList = {}
	self.OnVirtualTriggerHideCallBackList = {}
end

function UserWidgetBase:PreOnShow(data)
	if not self.IsMvcPreOnShow then
		self.IsMvcPreOnShow = true
		return
	end
	self:ShowUIByMvcShow()
end
function UserWidgetBase:PreOnHide(data)
	self:DisposeUIByMvcHide()
end

function UserWidgetBase:OnVirtualTriggerShow(data)
	self:OnShowAvator(nil,false)
	for _,V in pairs(self.OnVirtualTriggerShowCallBackList) do
		V()
	end
end
function UserWidgetBase:OnVirtualTriggerHide(data)
	self:OnHideAvator(nil,false)
	for _,V in pairs(self.OnVirtualTriggerHideCallBackList) do
		V()
	end
end

function UserWidgetBase:ShowUIByNodeConstruct()
	-- CWaring("UserWidgetBase:ShowUIByNodeConstruct:" .. self:GetName())
	self:ShowUIInner(true)
end

function UserWidgetBase:ShowUIByMvcShow()
	-- CWaring("UserWidgetBase:ShowUIByMvcShow:" .. self:GetName())
	self:ShowUIInner()
end


function UserWidgetBase:DisposeUIByNodeDestruct()
	-- CWaring("UserWidgetBase:DisposeUIByNodeDestruct:" .. self:GetName())
	self:DisposeUIInner()
	self:DestructUIInner()
end
function UserWidgetBase:DisposeUIByMvcHide()
	-- CWaring("UserWidgetBase:DisposeUIByMvcHide:" .. self:GetName())
	self:DisposeUIInner()
end


--[[
	显示UI的详细逻辑
]]
function UserWidgetBase:ShowUIInner(IsInit)
	if not IsInit and self.IsDisposeUI == false then
		CError("UserWidgetBase:ShowUIInner Repeat ShowUIInner:" .. self:GetName(),true)
		return
	end
	self.IsDisposeUI = false
	self:DynamicRegisterOrUnRegister(true)

	if not IsInit then
		for _,V in pairs(self.ShowUICallBackList) do
			V()
		end
	else
		self:_PlayShowEffect()
	end
end

--[[
	不显示UI的详细逻辑
]]
function UserWidgetBase:DisposeUIInner()
	if self.IsDisposeUI then
		CWaring("UserWidgetBase:DisposeUIInner IsDisposeUI true,So return:" .. self:GetName())
		return
	end
	self.IsDisposeUI = true
	for _,V in pairs(self.DisposeUICallBackList) do
		V()
	end
	self:DynamicRegisterOrUnRegister(false)
end

function UserWidgetBase:DestructUIInner()
	for _,V in pairs(self.DestructUICallBackList) do
		V()
	end
	self:DataInitInner()
end

--[[
	动态添加UI可用行为回调
]]
function UserWidgetBase:RegisterShowUICallBack(Cb,Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidgetBase:RegisterShowUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	self.ShowUICallBackList[ClassId] = Cb
end
function UserWidgetBase:UnRegisterShowUICallBack(Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidgetBase:UnRegisterShowUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	if not self.ShowUICallBackList then
		if not self.IsConstruct then
			-- 防止有子类继承，但覆盖了Construct，没有调用Super
			local TipStr = "UserWidgetBase: Not Construct! Please Check Is Override :" .. self:GetName()
			CError(TipStr,true)
			EnsureCall(TipStr)
		end
		return
	end
	self.ShowUICallBackList[ClassId] = nil
end

--[[
	动态添加UI不可用行为回调
]]
function UserWidgetBase:RegisterDisposeUICallBack(Cb,Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidgetBase:RegisterDisposeUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	self.DisposeUICallBackList[ClassId] = Cb
end
function UserWidgetBase:UnRegisterDisposeUICallBack(Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidgetBase:UnRegisterDisposeUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	if not self.DisposeUICallBackList then
		return
	end
	self.DisposeUICallBackList[ClassId] = nil
end

--[[
	动态添加UI被销毁行为回调
]]
function UserWidgetBase:RegisterDestructUICallBack(Cb,Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidgetBase:RegisterDestructUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	self.DestructUICallBackList[ClassId] = Cb
end
function UserWidgetBase:UnRegisterDestructUICallBack(Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidgetBase:UnRegisterDestructUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	if not self.DestructUICallBackList then
		return
	end
	self.DestructUICallBackList[ClassId] = nil
end

--[[
	动态添加虚拟场景触发的显示/隐藏回调
]]
function UserWidgetBase:RegisterVirtualTriggerShowCallBack(Cb,Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidgetBase:RegisterDestructUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	self.OnVirtualTriggerShowCallBackList[ClassId] = Cb
end
function UserWidgetBase:UnRegisterVirtualTriggerShowCallBack(Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidgetBase:UnRegisterDestructUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	if not self.OnVirtualTriggerShowCallBackList then
		return
	end
	self.OnVirtualTriggerShowCallBackList[ClassId] = nil
end
--[[
	动态添加虚拟场景触发的显示/隐藏回调
]]
function UserWidgetBase:RegisterVirtualTriggerHideCallBack(Cb,Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidgetBase:RegisterDestructUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	self.OnVirtualTriggerHideCallBackList[ClassId] = Cb
end
function UserWidgetBase:UnRegisterVirtualTriggerHideCallBack(Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UserWidgetBase:UnRegisterDestructUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	if not self.OnVirtualTriggerHideCallBackList then
		return
	end
	self.OnVirtualTriggerHideCallBackList[ClassId] = nil
end


--[[
	动态绑定或者移除临听 (跟随UMG生命周期进行绑定和解绑)
]]
function UserWidgetBase:DynamicRegisterOrUnRegister(bRegister)
	if bRegister then
		-- 注册节点监听
		if self.BindNodes then
			MsgHelper:OpDelegateList(self, self.BindNodes, true)
		end
		if self.BindUniNodes then
			MsgHelper:OpUniDelegateList(self, self.BindUniNodes, true)
		end
		-- 注册消息监听
		if self.MsgListGMP then
			MsgHelper:RegisterList(self, self.MsgListGMP)
		end
		-- 注册Mvc消息监听
		CommonUtil.MvcMsgRegisterOrUnRegister(self,self.MsgList,true)
		CommonUtil.MvvmBindRegisterOrUnRegister(self.MvvmBindList,true)
		CommonUtil.TimerRegisterOrUnRegister(self.TimerList,true)
	else
		-- 注销节点监听
		if self.BindNodes then
			MsgHelper:OpDelegateList(self, self.BindNodes, false)
		end
		if self.BindUniNodes then
			MsgHelper:OpUniDelegateList(self, self.BindUniNodes, false)
		end
		-- 注销消息监听
		if self.MsgListGMP then
			MsgHelper:UnregisterList(self, self.MsgListGMP)
		end
		-- 注销Mvc消息监听
		CommonUtil.MvcMsgRegisterOrUnRegister(self,self.MsgList,false)
		CommonUtil.MvvmBindRegisterOrUnRegister(self.MvvmBindList,false)
		CommonUtil.TimerRegisterOrUnRegister(self.TimerList,false)
	end
end

--//


--[[
	Public
]]
function UserWidgetBase:OnInit()
	
end
function UserWidgetBase:OnShow(data,MvcParam)
	
end
function UserWidgetBase:OnRepeatShow(data)
	
end
function UserWidgetBase:OnHide(data,MvcParam)
	
end
function UserWidgetBase:OnDestroy()
	
end
--[[
	@param Data 自定义参数，首次创建时可能存在值
	@param IsNotVirtualTrigger 是否  不是因为虚拟场景切换触发的
		true  表示为初始化创建
		false 表示为虚拟场景切换触发
]]
function UserWidgetBase:OnShowAvator(Data,IsNotVirtualTrigger) end
function UserWidgetBase:OnHideAvator(Data,IsNotVirtualTrigger) end

function UserWidgetBase:OnShowSound(data)
	if self.WBP_Sound then
		SoundMgr:PlaySound(self.WBP_Sound.ShowSound)
	end
end
function UserWidgetBase:OnHideSound(data)
	if self.WBP_Sound then
		SoundMgr:PlaySound(self.WBP_Sound.HideSound)
	end
end

--[[
	重新注册
	方便有些依赖参数在OnShow接口，对MsgList进行动态添加，然后绑定的行为
	可以手动触发 ReRegister 去实现
]]
function UserWidgetBase:ReRegister()
	self:DynamicRegisterOrUnRegister(true)
end

--[[
	动态添加计时器
	--TimeOffset (必填) 单位是秒 0的话，遇到tick就会执行；-1的话，会在下一帧执行。
	--Func   (必填) 执行回调
	--Loop  boolean 是否循环（可选，默认为false）
	--TimerType 计时器类型 （可选，默认为TimerTypeEnum.Timer）
	--Name  计时器名称（可选）

	return 计时器句柄（方便手动移除）
]]
function UserWidgetBase:InsertTimer(TimeOffset, Func, Loop, TimerType,Name)
	TimerType = TimerType or TimerTypeEnum.Timer
	local TimerObject = { TimeOffset = TimeOffset, Func = Func, Loop = Loop,TimerType = TimerType,Name = Name }
	if not Loop then
		TimerObject.Func = Bind(self,UserWidgetBase.__OnceTimerFuncCallback,TimerObject,Func)
	end
	CommonUtil.TimerRegisterOrUnRegister({TimerObject},true)
	if not TimerObject.TimerHandler then
		CError("UserWidgetBase:InsertTimer:" .. self:GetName() .. "|TimerHandler nil,please check",true)
		return
	end
	self.TimerList = self.TimerList or TablePool.Fetch("UserWidgetBaseOrHandler")
	table.insert(self.TimerList,TimerObject)

	return TimerObject
end
--[[
	针对一次性的计时器，回调完成时，完成自清理动作
]]
function UserWidgetBase:__OnceTimerFuncCallback(TimerObject,Func)
	CWaring("UserWidgetBaseOrHandler:__OnceTimerFuncCallback")
	self:RemoveTimer(TimerObject)
	Func()
end

--[[
	动态移除计时器

	@param TimerObject 计时器句柄
]]
function UserWidgetBase:RemoveTimer(TimerObject)
	if not TimerObject.TimerHandler then
		CWaring("UserWidgetBase:RemoveTimer TimerHandler nil,maybe already removed,please check:" .. self:GetName())
		return
	end
	CommonUtil.TimerRegisterOrUnRegister({TimerObject},false)
	if self.TimerList then
		local FixTimerList = TablePool.Fetch("UserWidgetBaseOrHandler")
		for k, v in ipairs(self.TimerList) do
			if v.TimerHandler then
				table.insert(FixTimerList,v)
			end
		end
		TablePool.Recycle("UserWidgetBaseOrHandler", self.TimerList)
		self.TimerList = FixTimerList
	end
end

--[[
	根据结束时间缀固定频率触发回调  并回调 倒计时显示字符串

	频率逻辑可定制：
		当前为剩余时间大于1天，会间隔60S回调
		否则为一秒回调一次

	EndTime 结束时间缀
	CallBack 回调，回参：
	        TimeStr 需要显示的字符串
			ResultParam 时间转换结果
	CountDownType 预留，可控制不同的转换字符串接口
	AtOnce 是否立即执行回调，默认为真

	@param TimerObject 计时器句柄
]]
function UserWidgetBase:InsertTimerByEndTime(EndTime,CallBack,CountDownType,AtOnce)
	if AtOnce == nil then
		AtOnce = true
	end
	local CTime = GetTimestamp()
	local TimeStr,ResultParam = TimeUtils.GetTimeString_CountDownStyle(EndTime - CTime)
	if ResultParam.Expired then
		CallBack("--")
		return nil
	end
	local TimeOffset = 1
	if ResultParam.IsDay then
		TimeOffset = 60
	end
	local Timer = self:InsertTimer(TimeOffset,Bind(self,UserWidgetBase.__GetCountDownStrByEndTimeAndCallBack,EndTime,CallBack),true)
	if AtOnce then
		CallBack(TimeStr)
	end
	return Timer
end
function UserWidgetBase:__GetCountDownStrByEndTimeAndCallBack(EndTime,CallBack)
	local CTime = GetTimestamp()
	local TimeStr,ResultParam = TimeUtils.GetTimeString_CountDownStyle(EndTime - CTime)
	CallBack(TimeStr,ResultParam)
end

---------------------
--[[
	播放入场动效
	ShowUIInner - init为true时候播放
]]
function UserWidgetBase:_PlayShowEffect()
	if self.VXE_Common_In then
		CWaring("UserWidgetBase _PlayShowEffect VXE_Common_In")
		self:VXE_Common_In()
	end
end

return UserWidgetBase