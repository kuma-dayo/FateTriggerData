--[[
    UI包装器
    目标：UMG对象 且根结点必须是允许多孩子的PanelWidget
    功能：
    用于给指定UI（非Mdt）添加代理脚本

    会对代理脚本赋值view为 指定的UI对象
    代理脚本面向BaseClass

	ViewInstance可实现（以下实现按顺序执行）：
	OnInit  用于委托列表，事件列表的声明及初始化
    OnShow  界面打开时会调用，可传参数
	OnManualShow  当父Handler调用ManualOpen时，会触发此实现
	OnShowAvator  界面展示会触发/此界面打开情况下上层虚拟关卡被关卡  （用于3D物品的展示和隐藏）
	OnHideAvator  界面关闭状态或者销毁时会调用/此界面打开情况下再打开虚拟关卡会触发 （用于3D物品的展示和隐藏）
    OnHide  界面关闭状态或者销毁时会调用
	OnManualHide  当父Handler调用ManualClose时，会触发此实现
	OnDestroy 界面销毁时被调用


	BindNodes 结构范例：
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
	self.MsgList = {
		{Model = nil, MsgName = CommonEvent.ON_LOGIN_FINISHED,	Func = self.ON_LOGIN_FINISHED_Func},
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
local class_name = "UIHandler";
---@class UIHandler
UIHandler = UIHandler or BaseClass(nil, class_name);

--[[
    New() 时调用

	会优先对 View 进行挂载节点来监控其自身的生命周期
	如果挂载失败，会依赖 WidgetBaseOrHandler 进行生命周期管理
		这种情况会打印警告，目的是需要开发者确认View的生命周期与WidgetBaseOrHandle生命周期一致
		注意：如果会出现需要动态创建View和销毁View的情况，导致其生命周期与WidgetBaseOrHandler不一致，逻辑会出问题
			需要保证View自身能挂载节点去管理自身的生命周期
			否则View销毁了，WidgetBaseOrHandler生命还在的情况下，View的对应的解耦逻辑却还在运行，导致报错
]]
---@private
---@param WidgetBaseOrHandler table 所属的WidgetBase实例，也方便用于Debug/或者是UIHandler实例，依赖UIHandler进行销毁和释放
---@param View userdata|table widget实例在lua的表示
---@param ClassHandler table|string BaseClass形式创建的类, 需要提供OnShow(param)来显示ui 和OnHide()来清理
function UIHandler:__init(WidgetBaseOrHandler,View, ClassHandler, ...)
	if not WidgetBaseOrHandler then
		CError("UIHandler WidgetBaseOrHandler nil,please check",true)
		return
	end
	if not View then
		CError("UIHandler view nil,please check",true)
		return
	end
	if not ClassHandler then
		CError("UIHandler ClassHandler nil,please check",true)
		return
	end
	local ClassType = type(ClassHandler)
	local Class = nil
	if 'string' == ClassType then
		Class = require(ClassHandler)
	else
		Class = ClassHandler
	end
	self.ShowUIRegisterIndex = 0
	self.ShowUICallBackList = {}
	self.ShowUICallBackListDirty = false
	self.ShowUICallBackListAfterSort = {}

	self.DisposeUIRegisterIndex = 0
	self.DisposeUICallBackList = {}
	self.DisposeUICallBackListDirty = false
	self.DisposeUICallBackListAfterSort = {}


	self.DestructUICallBackList = {}

	--注册虚拟场景触发的显示/隐藏回调
	self.OnVirtualTriggerShowCallBackList = {}
	self.OnVirtualTriggerHideCallBackList = {}

    self.ViewInstance = Class.New()
	self.ViewInstance.Handler = self
    self.ViewInstance.View = View
	self.ViewName = View:GetName()


	local IsHandler = false
	local WidgetBase = nil
	if WidgetBaseOrHandler.IsA and WidgetBaseOrHandler:IsA(UE.UUserWidget) then
		WidgetBase = WidgetBaseOrHandler
	elseif WidgetBaseOrHandler.IsClass and WidgetBaseOrHandler:IsClass(UIHandler) then
		WidgetBase = WidgetBaseOrHandler.ViewInstance.WidgetBase
		IsHandler = true
		self.ViewInstance.ParentHandler = WidgetBaseOrHandler
	elseif WidgetBaseOrHandler.IsClass and WidgetBaseOrHandler.Handler and WidgetBaseOrHandler.Handler.IsClass and WidgetBaseOrHandler.Handler:IsClass(UIHandler) then
		WidgetBaseOrHandler = WidgetBaseOrHandler.Handler
		WidgetBase = WidgetBaseOrHandler.ViewInstance and WidgetBaseOrHandler.ViewInstance.WidgetBase or nil
		IsHandler = true
		self.ViewInstance.ParentHandler = WidgetBaseOrHandler
	end
	if not WidgetBase then
		CError("UIHandler WidgetBase nil:" .. View:GetName(),true)
		return
	end
	local IsViewSameWithBase = (WidgetBaseOrHandler == View)
	if IsHandler then
		if WidgetBaseOrHandler.ViewInstance.View == View then
			-- CError("UIHandler WidgetBaseOrHandler.View Equal View",true)
			IsViewSameWithBase = true
		end
	end

	self.WidgetBaseOrHandler = WidgetBaseOrHandler
	self.ViewInstance.WidgetBase = WidgetBase
	self.ControlViewId = WidgetBase.viewId

	local FromHandler = false
	local FromBridge = false
	local FromWidgetBase = false
	if IsViewSameWithBase then
		CWaring("UIHandler IsViewSameWithBase,Please pay attention to the life cycle of view:" .. self.ViewName .. " ClassId:" .. self:ClassId())
		if not IsHandler then
			FromWidgetBase = true
		else
			FromHandler = true
		end
	else
		local IsViewUserWidget = false
		local IsViewPanelWidget = false
		if View.IsA then
			IsViewUserWidget = View:IsA(UE.UUserWidget)
			IsViewPanelWidget = View:IsA(UE.UPanelWidget)
		end
		local TryUseHandler = false
		if IsViewUserWidget or IsViewPanelWidget then
			local IsViewGUIUserWidget = IsViewUserWidget and View:IsA(UE.UGUIUserWidget) or false
			if IsViewGUIUserWidget then
				--TODO 绑定Destruct委托，用于控制生命周期
				-- CWaring("UIHandler addBrige:" .. self.ViewName)
				self.OnDestructEventBindFunc = Bind(self,self.DisposeUIByNodeFromLuaBindBrige)
				View.OnDestructEvent:Add(GameInstance, self.OnDestructEventBindFunc)
				FromBridge = true
				if not IsHandler then
					FromWidgetBase = true
				else
					FromHandler = true
				end
			else
				-- 添加一个钩子，当root widget被销毁时，会调用对应的lua侧清理函数OnHide()
				local rootWidget = nil
				if IsViewUserWidget then
					-- CWaring("IsViewUserWidget")
					rootWidget = View.WidgetTree and View.WidgetTree.RootWidget or nil--View:GetRootWidget() -- UMG节点呈树状结构，可通过GetRootWidget()获取根节点
				else
					-- CWaring("IsViewUserWidget not")
					rootWidget = View
				end

				if self:CheckRootWidgetValid(rootWidget) then
					local brige_class = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(UIBrigeUMGPath))
					self.BrigeWidget = NewObject(brige_class, GameInstance, nil, "Client.Common.UIBrige")
					rootWidget:AddChild(self.BrigeWidget)  
					if not self.BrigeWidget.InitSuccess then
						CError("UIHandler AddBrigeWidget Fail please check:" .. View:GetName(),true)
						return
					end
					self.BrigeWidget:SetHandlerViewId(self.ControlViewId)
					--监听组件设置为不可见状态
					self.BrigeWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
					--添加移除监听
					self.BrigeWidget:AddListener(UIBrige.ON_DESTRUCT,self.DisposeUIByNodeFromBrige,self)
					FromBridge = true
					if not IsHandler then
						FromWidgetBase = true
					else
						FromHandler = true
					end
				else
					CWaring("UIHandler addBrige fail,Try user handler,Please pay attention to the life cycle of view:" .. self.ViewName)
					TryUseHandler = true
				end
			end
		else
			TryUseHandler = true
		end
		if TryUseHandler then
			if IsHandler then
				FromHandler = true
			else
				CError("UIHandler Invalid,please check!:" .. View:GetName(),true)
				return
			end
		end
	end
	if FromHandler then
		WidgetBaseOrHandler:RegisterShowUICallBack(Bind(self,self.ShowUIByNodeFromHandler),self)
		WidgetBaseOrHandler:RegisterDisposeUICallBack(Bind(self,self.DisposeUIByNodeFromHandler),self)
		if not FromBridge then
			WidgetBaseOrHandler:RegisterDestructUICallBack(Bind(self,self.DestructUIByNodeFromHandler),self)
		end

		WidgetBaseOrHandler:RegisterVirtualTriggerShowCallBack(Bind(self,self.VirtualTriggerShowFromHandler),self)
		WidgetBaseOrHandler:RegisterVirtualTriggerHideCallBack(Bind(self,self.VirtualTriggerHideFromHandler),self)
	elseif FromWidgetBase then
		WidgetBaseOrHandler:RegisterShowUICallBack(Bind(self,self.ShowUIByNodeFromWidgetBase),self)
		WidgetBaseOrHandler:RegisterDisposeUICallBack(Bind(self,self.DisposeUIByNodeFromWidgetBase),self)
		if not FromBridge then
			WidgetBaseOrHandler:RegisterDestructUICallBack(Bind(self,self.DestructUIByNodeFromWidgetBase),self)
		end

		WidgetBaseOrHandler:RegisterVirtualTriggerShowCallBack(Bind(self,self.VirtualTriggerShowFromWidgetBase),self)
		WidgetBaseOrHandler:RegisterVirtualTriggerHideCallBack(Bind(self,self.VirtualTriggerHideFromWidgetBase),self)
	else
		CError("UIHandler FromBridge Invalid,please check!:" .. View:GetName(),true)
		return
	end

	--是否UI不可用（不在逻辑生命周期）
	self.IsDisposeUI = false
	self.IsDestructUI = false
	self.IsManualDispose = false
	--是否锁定输入,锁定后，InputModel的事件只当前View 可见性为真的时候，才会生效
	self.ViewInstance.InputFocus = false

    self.ViewInstance.BindNodes = nil
	self.ViewInstance.BindUniNodes = nil
	self.ViewInstance.MsgList = nil
    self.ViewInstance.MsgListGMP = nil
	self.ViewInstance.MvvmBindList = nil
	--[[
		计时器管理
	]]
	self.ViewInstance.TimerList = nil

	
	self.ViewInstance.GetName = Bind(self,self.__GetName)
	self.ViewInstance.IsValid = Bind(self,self.__DoIsValid)
	self.ViewInstance.InsertTimer = Bind(self,self.__InsertTimer)
	self.ViewInstance.RemoveTimer = Bind(self,self.__RemoveTimer)
	self.ViewInstance.ReRegister = Bind(self,self.__ReRegister)
	self.ViewInstance.InsertTimerByEndTime = Bind(self,self.__InsertTimerByEndTime) 
	self.ViewInstance.DoSwitchVirtualScene = Bind(self,self.__DoSwitchVirtualScene)
	self.ViewInstance.ManualOpen = Bind(self,self.__DoManualOpen)
	self.ViewInstance.ManualClose = Bind(self,self.__DoManualClose)
	

	self.Param = table.pack(...)
	if #self.Param <= 0 then
		self.Param = nil
	elseif #self.Param <= 1 then
		self.Param = self.Param[1]
	end
    if self.ViewInstance.OnInit then
        self.ViewInstance:OnInit(self.Param)
    end
    self:ShowUIByHandlerInit()
    self.ViewInstance:OnShow(self.Param)
	if self.ViewInstance.OnShowAvator then
		self.ViewInstance:OnShowAvator(self.Param,true)
	end
end


function UIHandler:OnNodeDestructClean()
	self.WidgetBaseOrHandler:UnRegisterShowUICallBack(self)
	self.WidgetBaseOrHandler:UnRegisterDisposeUICallBack(self)
	self.WidgetBaseOrHandler:UnRegisterDestructUICallBack(self)
	self.WidgetBaseOrHandler:UnRegisterVirtualTriggerHideCallBack(self)
	self.WidgetBaseOrHandler:UnRegisterVirtualTriggerShowCallBack(self)

	self.Param = nil
	self.IsDestructUI = true
    self.ViewInstance = nil
	self.BrigeWidget = nil
	self.WidgetBaseOrHandler = nil
	--注册ShowUI和DisposeUI的回调
	self.ShowUIRegisterIndex = 0
	self.ShowUICallBackList = {}
	self.ShowUICallBackListDirty = false
	self.ShowUICallBackListAfterSort = {}


	self.DisposeUIRegisterIndex = 0
	self.DisposeUICallBackList = {}
	self.DisposeUICallBackListDirty = false
	self.DisposeUICallBackListAfterSort = {}
	--//
end

function UIHandler:CheckRootWidgetValid(rootWidget)
	if not rootWidget then
		-- CError("UIHandler View.rootWidget nil:" .. self.ViewName,true)
		CWaring("UIHandler View.rootWidget nil:" .. self.ViewName)
		return
	end
	-- CWaring("rootWidget:" .. rootWidget:GetName())
	if not (rootWidget:IsA(UE.UContentWidget) or rootWidget:IsA(UE.UPanelWidget)) then
		-- CError("UIHandler rootWidget Need PanelWidget:" .. self.ViewName,true)
		CWaring("UIHandler rootWidget Need PanelWidget:" .. self.ViewName)
		return
	end
	if rootWidget:IsA(UE.UContentWidget) then
		-- CError("UIHandler View.rootWidget is UContentWidget,but Need PanelWidget:" .. self.ViewName,true)
		CWaring("UIHandler View.rootWidget is UContentWidget,but Need PanelWidget:" .. self.ViewName)
		return
	end
	return true
end


function UIHandler:ShowUIByHandlerInit()
	-- CWaring("UIHandler:ShowUIByHandlerInit:" .. self.ViewName)
	self:ShowUIInner(true)
end

function UIHandler:ShowUIByNodeFromHandler(OnShowType)
	-- CWaring("UIHandler:ShowUIByNodeFromHandler:" .. self.ViewName)
	self:ShowUIInner(nil,OnShowType)
end
function UIHandler:ShowUIByNodeFromWidgetBase()
	-- CWaring("UIHandler:ShowUIByNodeFromWidgetBase:" .. self.ViewName)
	self:ShowUIInner()
end

---@private
function UIHandler:DisposeUIByNodeFromHandler(OnHideType)
	-- CWaring("UIHandler:DisposeUIByNodeFromHandler:" .. self.ViewName)
	self:DisposeUIInner(OnHideType)
end
function UIHandler:DisposeUIByNodeFromBrige()
	-- CWaring("UIHandler:DisposeUIByNodeFromBrige:" .. self.ViewName)
	self:DisposeUIInner()
	self:DestructUIByNodeFromBrige()
end
function UIHandler:DisposeUIByNodeFromLuaBindBrige()
	-- CWaring("UIHandler:DisposeUIByNodeFromLuaBindBrige:" .. self.ViewName)
	if self.OnDestructEventBindFunc then
		-- CWaring("UIHandler:DisposeUIByNodeFromLuaBindBrige2:" .. self.ViewName)
		self.ViewInstance.View.OnDestructEvent:Remove(GameInstance, self.OnDestructEventBindFunc)
	end
	self.OnDestructEventBindFunc = nil
	self:DisposeUIInner()
	self:DestructUIByNodeFromBrige()
end
function UIHandler:DisposeUIByNodeFromWidgetBase()
	-- CWaring("UIHandler:DisposeUIByNodeFromWidgetBase:" .. self.ViewName)
	self:DisposeUIInner()
end

function UIHandler:DestructUIByNodeFromBrige()
	-- CWaring("UIHandler:DestructUIByNodeFromBrige:" .. self.ViewName)
	self:DestructUIInner()
end

function UIHandler:DestructUIByNodeFromHandler()
	-- CWaring("UIHandler:DestructUIByNodeFromHandler:" .. self.ViewName)
	self:DestructUIInner()
end

function UIHandler:DestructUIByNodeFromWidgetBase()
	-- CWaring("UIHandler:DestructUIByNodeFromWidgetBase:" .. self.ViewName)
	self:DestructUIInner()
end


--OnVirtualTriggerShow
function UIHandler:VirtualTriggerShowFromHandler()
	-- CWaring("UIHandler:VirtualTriggerShowFromHandler:" .. self.ViewName)
	self:VirtualTriggerShowInner()
end
function UIHandler:VirtualTriggerShowFromWidgetBase()
	-- CWaring("UIHandler:VirtualTriggerShowFromWidgetBase:" .. self.ViewName)
	self:VirtualTriggerShowInner()
end

---@private
function UIHandler:VirtualTriggerHideFromHandler()
	-- CWaring("UIHandler:VirtualTriggerHideFromHandler:" .. self.ViewName)
	self:VirtualTriggerHideInner()
end
function UIHandler:VirtualTriggerHideFromWidgetBase()
	-- CWaring("UIHandler:VirtualTriggerHideFromWidgetBase:" .. self.ViewName)
	self:VirtualTriggerHideInner()
end



--[[
	显示UI的详细逻辑
]]
function UIHandler:ShowUIInner(IsInit,OnShowType)
	if self.IsDestructUI then
		return
	end
	if not OnShowType then
		OnShowType = UIConst.OnShowTypeEnum.MVC
	end
	--and OnShowType ~= UIConst.OnShowTypeEnum.Manual
	if not IsInit and self.IsDisposeUI == false then
		if OnShowType ~= UIConst.OnShowTypeEnum.Manual then
			CError("UIHandler:ShowUIInner Repeat ShowUIInner:" .. self.ViewName,true)
		end
		return
	end
	if not IsInit and self.IsManualDispose then
		CWaring("UIHandler:ShowUIInner Already ManualDispose,Break:" .. self.ViewName)
		return
	end 
	--self.ViewName.find("WBP_HallMatchEntrance")
	-- if  string.find(self.ViewName,"WBP_HallMatchEntrance") then
	-- 	CError("UIHandler:ShowUIInner ShowUIInner:" .. self.ViewName,true)
	-- end
	-- CWaring("UIHandler:ShowUIInner ShowUIInner:" .. self.ViewName)
	self.IsDisposeUI = false
	self:DynamicRegisterOrUnRegister(true)

	if not IsInit then
		self:CalculateShowUICallBackListAfterSort()
		if OnShowType == UIConst.OnShowTypeEnum.Manual then
			if self.ViewInstance.OnManualShow then
				self.ViewInstance:OnManualShow(self.Param)
			end
		else
			self.ViewInstance:OnShow(self.Param)
		end
		if self.ViewInstance.OnShowAvator then
			self.ViewInstance:OnShowAvator(self.Param,true)
		end
		for _,V in ipairs(self.ShowUICallBackListAfterSort) do
			V.CallBack(OnShowType)
		end
	else
		self:_PlayShowEffect()
	end
end

--[[
	不显示UI的详细逻辑
]]
function UIHandler:DisposeUIInner(OnHideType)
	if self.IsDestructUI then
		return
	end
	if self.IsDisposeUI then
		-- CWaring("UIHandler:DisposeUIInner IsDisposeUI true,So return:" .. self.ViewName)
		return
	end
	-- CWaring("UIHandler:DisposeUIInner DisposeUI:" .. self.ViewName)
	self.IsDisposeUI = true
	if not OnHideType then
		OnHideType = UIConst.OnHideTypeEnum.MVC
	end
	-- for _,V in pairs(self.DisposeUICallBackList) do
	-- 	V(OnHideType)
	-- end
	self:CalculateDisposeUICallBackListAfterSort()
	for _,V in ipairs(self.DisposeUICallBackListAfterSort) do
		V.CallBack(OnHideType)
	end
	if self.ViewInstance.OnHideAvator then
		self.ViewInstance:OnHideAvator(nil,true)
	end
	if OnHideType == UIConst.OnHideTypeEnum.Manual then
		if self.ViewInstance.OnManualHide then
			self.ViewInstance:OnManualHide()
		end
	else
		self.ViewInstance:OnHide()
	end
    self:DynamicRegisterOrUnRegister(false)
end

function UIHandler:DestructUIInner()
	if self.IsDestructUI then
		return
	end
	if not self.IsDisposeUI then
		CWaring("UIHandler:DestructUIInner Fix DisposeUI:" .. self.ViewName)
		self:DisposeUIInner()
	end
	-- CWaring("UIHandler:DestructUIInner:" .. self.ViewName)
	self.IsDestructUI = true
	for _,V in pairs(self.DestructUICallBackList) do
		V()
	end
	if self.ViewInstance.OnDestroy then
		self.ViewInstance:OnDestroy()
	end
	self:OnNodeDestructClean()
end

function UIHandler:VirtualTriggerShowInner()
	if self.IsDestructUI then
		return
	end
	if self.IsDisposeUI then
		return
	end
	if self.IsManualDispose then
		CWaring("UIHandler:VirtualTriggerShowInner Already ManualDispose,Break:" .. self.ViewName)
		return
	end
	for _,V in pairs(self.OnVirtualTriggerShowCallBackList) do
		V()
	end
	if self.ViewInstance.OnShowAvator then
		self.ViewInstance:OnShowAvator(nil,false)
	end
end
function UIHandler:VirtualTriggerHideInner()
	if self.IsDestructUI then
		return
	end
	if self.IsDisposeUI then
		return
	end
	if self.IsManualDispose then
		CWaring("UIHandler:VirtualTriggerHideInner Already ManualDispose,Break:" .. self.ViewName)
		return
	end
	for _,V in pairs(self.OnVirtualTriggerHideCallBackList) do
		V()
	end
	if self.ViewInstance.OnHideAvator then
		self.ViewInstance:OnHideAvator(nil,false)
	end
end


function UIHandler:GetAutoIncrementRegisterShowUIIndex()
	self.ShowUIRegisterIndex = self.ShowUIRegisterIndex + 1
	if self.ShowUIRegisterIndex >= math.maxinteger then
		self:CalculateShowUICallBackListAfterSort()
		for k,v in ipairs(self.ShowUICallBackListAfterSort) do
			v.SortIndex = k
		end
		self.ShowUIRegisterIndex = #self.ShowUICallBackListAfterSort + 1
	end
	return self.ShowUIRegisterIndex
end
function UIHandler:GetAutoIncrementRegisterDisposeUIIndex()
	self.DisposeUIRegisterIndex = self.DisposeUIRegisterIndex + 1
	if self.DisposeUIRegisterIndex >= math.maxinteger then
		self:CalculateDisposeUICallBackListAfterSort()
		local Count = #self.DisposeUICallBackListAfterSort + 1
		for k,v in ipairs(self.DisposeUICallBackListAfterSort) do
			v.SortIndex = Count - k
		end
		self.DisposeUIRegisterIndex = #self.DisposeUICallBackListAfterSort + 1
	end
	return self.DisposeUIRegisterIndex
end

function UIHandler:CalculateShowUICallBackListAfterSort()
	if self.ShowUICallBackListDirty then
		self.ShowUICallBackListDirty = false
		self.ShowUICallBackListAfterSort = {}
		for k,v in pairs(self.ShowUICallBackList) do
			if v then
				self.ShowUICallBackListAfterSort[#self.ShowUICallBackListAfterSort + 1] = v
			end
		end
		table.sort(self.ShowUICallBackListAfterSort, function(a, b)
			return (a.SortIndex < b.SortIndex)
		end)
	end
end
function UIHandler:CalculateDisposeUICallBackListAfterSort()
	if self.DisposeUICallBackListDirty then
		self.DisposeUICallBackListDirty = false
		self.DisposeUICallBackListAfterSort = {}
		for k,v in pairs(self.DisposeUICallBackList) do
			if v then
				self.DisposeUICallBackListAfterSort[#self.DisposeUICallBackListAfterSort + 1] = v
			end
		end
		table.sort(self.DisposeUICallBackListAfterSort, function(a, b)
			return (a.SortIndex > b.SortIndex)
		end)
	end
end

--[[
	动态添加UI可用行为回调
]]
function UIHandler:RegisterShowUICallBack(Cb,Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	if self.ShowUICallBackList[ClassId] then
		CError(StringUtil.Format("UIHandler:RegisterShowUICallBack Already Registered targetid:{0} targetname:{1} source:{2} sourcename:{3}",self:ClassId(),self.ViewName,ClassId,HandlerViewName),true)
		return
	end
	-- CWaring(StringUtil.Format("UIHandler:RegisterShowUICallBack targetid:{0} targetname:{1} source:{2} sourcename:{3}",self:ClassId(),self.ViewName,ClassId,HandlerViewName))
	local CallBackInfo = {CallBack = Cb,SortIndex = self:GetAutoIncrementRegisterShowUIIndex()}
	self.ShowUICallBackList[ClassId] = CallBackInfo
	self.ShowUICallBackListDirty = true
end
function UIHandler:UnRegisterShowUICallBack(Handler)
	if self.IsDestructUI then
		--[[
			由于注册给UserWidgetBase或者Handler的 Destruct回调没有保序
			很可能由子类Destruct触发UnRegister时，父类已经标记Destruct了，相关回调列表已经清空

			下述同理
		]]
		return
	end
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	if not self.ShowUICallBackList[ClassId] then
		CError(StringUtil.Format("UIHandler:UnRegisterShowUICallBack Not Found Registered targetid:{0} targetname:{1} source:{2} sourcename:{3}",self:ClassId(),self.ViewName,ClassId,HandlerViewName),true)
		return
	end
	-- CWaring(StringUtil.Format("UIHandler:UnRegisterShowUICallBack targetid:{0} targetname:{1} source:{2} sourcename:{3}",self.ViewName,ClassId,HandlerViewName),true)
	self.ShowUICallBackList[ClassId] = nil
	self.ShowUICallBackListDirty = true
end

--[[
	动态添加UI不可用行为回调
]]
function UIHandler:RegisterDisposeUICallBack(Cb,Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	if self.DisposeUICallBackList[ClassId] then
		CError(StringUtil.Format("UIHandler:RegisterDisposeUICallBack Already Registered targetid:{0} targetname:{1} source:{2} sourcename:{3}",self:ClassId(),self.ViewName,ClassId,HandlerViewName))
		return
	end
	-- CWaring(StringUtil.Format("UIHandler:RegisterDisposeUICallBack target:{0} source:{1} sourcename:{2}",self.ViewName,ClassId,HandlerViewName))
	local CallBackInfo = {CallBack = Cb,SortIndex = self:GetAutoIncrementRegisterDisposeUIIndex()}
	self.DisposeUICallBackList[ClassId] = CallBackInfo
	self.DisposeUICallBackListDirty = true
end
function UIHandler:UnRegisterDisposeUICallBack(Handler)
	if self.IsDestructUI then
		return
	end
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	if not self.DisposeUICallBackList[ClassId] then
		CError(StringUtil.Format("UIHandler:UnRegisterDisposeUICallBack Not Found Registered targetid:{0} targetname:{1} source:{2} sourcename:{3}",self:ClassId(),self.ViewName,ClassId,HandlerViewName),true)
		return
	end
	-- CWaring(StringUtil.Format("UIHandler:UnRegisterDisposeUICallBack target:{0} source:{1} sourcename:{2}",self.ViewName,ClassId,HandlerViewName))
	self.DisposeUICallBackList[ClassId] = nil
	self.DisposeUICallBackListDirty = true
end

--[[
	动态添加UI被销毁行为回调
]]
function UIHandler:RegisterDestructUICallBack(Cb,Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UIHandler:RegisterDestructUICallBack target:{0} source:{1} sourcename:{2}",self.ViewName,ClassId,HandlerViewName))
	self.DestructUICallBackList[ClassId] = Cb
end
function UIHandler:UnRegisterDestructUICallBack(Handler)
	if self.IsDestructUI then
		return
	end
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UIHandler:UnRegisterDestructUICallBack target:{0} source:{1} sourcename:{2}",self.ViewName,ClassId,HandlerViewName))
	self.DestructUICallBackList[ClassId] = nil
end

--[[
	动态添加虚拟场景触发的显示/隐藏回调
]]
function UIHandler:RegisterVirtualTriggerShowCallBack(Cb,Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UIHandler:RegisterDestructUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	self.OnVirtualTriggerShowCallBackList[ClassId] = Cb
end
function UIHandler:UnRegisterVirtualTriggerShowCallBack(Handler)
	if self.IsDestructUI then
		return
	end
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UIHandler:UnRegisterDestructUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	self.OnVirtualTriggerShowCallBackList[ClassId] = nil
end
--[[
	动态添加虚拟场景触发的显示/隐藏回调
]]
function UIHandler:RegisterVirtualTriggerHideCallBack(Cb,Handler)
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UIHandler:RegisterDestructUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	self.OnVirtualTriggerHideCallBackList[ClassId] = Cb
end
function UIHandler:UnRegisterVirtualTriggerHideCallBack(Handler)
	if self.IsDestructUI then
		return
	end
	local ClassId = Handler:ClassId()
	local HandlerViewName = Handler.ViewName
	-- CWaring(StringUtil.Format("UIHandler:UnRegisterDestructUICallBack target:{0} source:{1} sourcename:{2}",self:GetName(),ClassId,HandlerViewName))
	self.OnVirtualTriggerHideCallBackList[ClassId] = nil
end


--[[
	动态绑定或者移除临听 (跟随UMG生命周期进行绑定和解绑)
]]
---@private
function UIHandler:DynamicRegisterOrUnRegister(bRegister)
    if not self.ViewInstance or not self.ViewInstance.View then 
        return
    end
	-- if self.ViewInstance.BindNodes and #self.ViewInstance.BindNodes > 0 then
	-- 	CWaring("UIHandler:BindNodes:" .. (bRegister and "true" or "false"))
	-- end
	if bRegister then
		-- 注册节点监听
		if self.ViewInstance.BindNodes then
			MsgHelper:OpDelegateList(self.ViewInstance.View, self.ViewInstance.BindNodes, true)
		end
		if self.ViewInstance.BindUniNodes then
			MsgHelper:OpUniDelegateList(self.ViewInstance.View, self.ViewInstance.BindUniNodes, true)
		end
		-- 注册消息监听
		if self.ViewInstance.MsgListGMP then
			MsgHelper:RegisterList(self.ViewInstance.View, self.ViewInstance.MsgListGMP)
		end
		-- 注册Mvc消息监听
		CommonUtil.MvcMsgRegisterOrUnRegister(self.ViewInstance,self.ViewInstance.MsgList,true)
		CommonUtil.MvvmBindRegisterOrUnRegister(self.ViewInstance.MvvmBindList,true)
		CommonUtil.TimerRegisterOrUnRegister(self.ViewInstance.TimerList,true)
	else
		-- 注销节点监听
		if self.ViewInstance.BindNodes then
			MsgHelper:OpDelegateList(self.ViewInstance.View, self.ViewInstance.BindNodes, false)
		end
		if self.ViewInstance.BindUniNodes then
			MsgHelper:OpUniDelegateList(self.ViewInstance.View, self.ViewInstance.BindUniNodes, false)
		end
		-- 注销消息监听
		if self.ViewInstance.MsgListGMP then
			MsgHelper:UnregisterList(self.ViewInstance.View, self.ViewInstance.MsgListGMP)
		end
		-- 注销Mvc消息监听
		CommonUtil.MvcMsgRegisterOrUnRegister(self.ViewInstance,self.ViewInstance.MsgList,false)
		CommonUtil.MvvmBindRegisterOrUnRegister(self.ViewInstance.MvvmBindList,false)
		CommonUtil.TimerRegisterOrUnRegister(self.ViewInstance.TimerList,false)
	end
end

-------------------------------------额外给ViewInstance注册的方法回调-------------------------------
--[[
	重新注册
	方便有些依赖参数在OnShow接口，对MsgList进行动态添加，然后绑定的行为
	可以手动触发 ReRegister 去实现
]]
function UIHandler:__ReRegister(ViewInstance)
	self:DynamicRegisterOrUnRegister(true)
end
--[[
	切换虚拟场景
]]
function UIHandler:__DoSwitchVirtualScene(ViewInstance,VirtualSceneId,SucCallBack)
	if not VirtualSceneId then
		return
	end
	MvcEntry:GetCtrl(ViewRegister):RegisterVirtualLevelView(self.ControlViewId,VirtualSceneId)
	--添加InputShieldLayer屏蔽玩家操作，防止串用引发问题
	InputShieldLayer.Close()
	InputShieldLayer.Add(15,1,function ()
		--超时
		CWaring("UIHandler SwitchScene Maybe Timeout Please Check!")
		InputShieldLayer.Close()
	end)
	_G.HallSceneMgrInst:SwitchScene(VirtualSceneId,function ()
		InputShieldLayer.Close()
		if SucCallBack then
			SucCallBack()
		end
	end)
end

function UIHandler:__DoManualOpen(ViewInstance, ... )
	self:ManualOpen(...)
end
function UIHandler:__DoManualClose(ViewInstance, ... )
	self:ManualClose(...)
end

--[[
	动态添加计时器
	--TimeOffset (必填) 单位是秒 0的话，遇到tick就会执行；-1的话，会在下一帧执行。
	--Func   (必填) 执行回调
	--Loop  boolean 是否循环（可选，默认为false）
	--TimerType 计时器类型 （可选，默认为TimerTypeEnum.Timer）
	--Name  计时器名称（可选）
]]
function UIHandler:__InsertTimer(ViewInstance,TimeOffset, Func, Loop, TimerType,Name)
	if self.IsDestructUI then
		return
	end
	--复用UserWidgetBase的 InsertTimer 实现，需要保证此实现内部对self的方法调用，方法也存在于UIHandler类
	return UserWidgetBase.InsertTimer(ViewInstance,TimeOffset, Func, Loop, TimerType,Name)
end

--[[
	动态移除计时器
]]
function UIHandler:__RemoveTimer(ViewInstance,TimerObject)
	----复用UserWidgetBase的 RemoveTimer 实现，需要保证此实现内部对self的方法调用，方法也存在于UIHandler类
	UserWidgetBase.RemoveTimer(ViewInstance,TimerObject)
end

function UIHandler:__InsertTimerByEndTime(ViewInstance,EndTime,CallBack,CountDownType,AtOnce)
	--复用UserWidgetBase的InsertTimerByEndTime实现，需要保证此实现内部对self的方法调用，方法也存在于UIHandler类
	return UserWidgetBase.InsertTimerByEndTime(ViewInstance,EndTime,CallBack,CountDownType,AtOnce)
end

function UIHandler:__DoIsValid(ViewInstance)
	return self:IsValid()
end

function UIHandler:__GetName(ViewInstance)
	if self:IsValid() then
		return "UIHandler ClassName:" .. ViewInstance:ClassName() .. "|ViewName:" ..  ViewInstance.View:GetName()
	else
		return "UIHandler None"
	end
end
--//


-------------------------------------供外部调用接口----------------------------------------------------
--[[
	手动调用，用于显示UI逻辑
	1.会触发当前Handler及所有子Handler其ViewInstace的OnManualShow方法
	2.会针对当前Handler及所有子Handler的事件、委托、计时器重新绑定或生效
]]
function UIHandler:ManualOpen(...)
	self.IsManualDispose = false
	self.ViewInstance.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	self:_PlayShowEffect()
	if ... then
		self.Param = table.pack(...)
		if #self.Param <= 0 then
			self.Param = nil
		elseif #self.Param <= 1 then
			self.Param = self.Param[1]
		end
	end
	self:ShowUIInner(nil,UIConst.OnShowTypeEnum.Manual)
end
--[[
	手动调用，用于隐藏UI逻辑
	1.会触发当前Handler及所有子Handler其ViewInstace的OnManualHide方法
	2.会针对当前Handler及所有子Handler的事件、委托、计时器重新解绑和停止
]]
function UIHandler:ManualClose()
	-- self:_PlayHideEffect()
	self.ViewInstance.View:SetVisibility(UE.ESlateVisibility.Collapsed)
	self:DisposeUIInner(UIConst.OnHideTypeEnum.Manual)
	self.IsManualDispose = true
end


function UIHandler:IsValid()
	if self.IsDestructUI then
		return false
	end
	if not self.ViewInstance then
		return false
	end
	local Result = CommonUtil.IsValid(self.ViewInstance.View)
	return Result
end

---------------------
--[[
	播放入场动效
	1. ShowUIInner - init为true时候播放
	2. ManualOpen 播放
]]
function UIHandler:_PlayShowEffect()
	if self.ViewInstance.View.VXE_Common_In then
		CWaring("UIHandler PlayAni VXE_Common_In")
		self.ViewInstance.View:VXE_Common_In()
	end
end

--[[
	播放退场动效
	-- todo
]]
function UIHandler:_PlayHideEffect()
	if self.ViewInstance.View.VXE_Common_Out then
		CWaring("UIHandler PlayAni VXE_Common_Out")
		self.ViewInstance.View:VXE_Common_Out()
	end
end