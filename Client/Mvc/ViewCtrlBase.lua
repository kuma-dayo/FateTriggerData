require("Core.Mvc.GameController");
require("Common.Events.CommonEvent");
require("Client.Views.ViewModel");

local class_name = "ViewCtrlBase";

---@class ViewCtrlBase : UserGameController
ViewCtrlBase = ViewCtrlBase or BaseClass(UserGameController, class_name);

function ViewCtrlBase:__init()
    self.id_refer = {};
    self.mediatorMap = {}
	---@type ViewModel
	self.model = self:GetModel(ViewModel);

	--[[注册的界面ID需要虚拟场景支撑显示3D物件
		id为界面Id
		值为HallSceneCfg 的 SceneID
	]]
	self.id2HallSceneRefer = {}

	self.Level2VirtualMap = {}
	self.ViewId2VirtualLevel = {}

	self.IsHallStreamLevelLoading = false
	self.IsCacheNeedOpenViewLooping = false
	self:DataInit()
end

function ViewCtrlBase:DataInit()
	self.CacheNeedOpenView = {}
end

function ViewCtrlBase:OnLogout(Data)
	self:DataInit()
end

function ViewCtrlBase:GetView(viewId)
	if viewId == nil then
        CError("ViewCtrlBase:GetView viewId nil")
		return nil;
    end
    local mediator = self.mediatorMap[viewId];
    if not mediator then
        local view_class = self.id_refer[viewId];

        if view_class == nil then
            CError("ViewId=" .. viewId .. "没有指定界面类")
			print_trackback()
        else
            mediator = view_class.New();
			mediator:ConfigViewId(viewId)
            self.mediatorMap[viewId] = mediator
        end
    end

	return mediator;
end

--[[
	判断对应界面ID，是否当前因为虚拟场景，导致被隐藏
]]
function ViewCtrlBase:IsViewBeVirtualHiding(viewId)
	local mediator = self:GetView(viewId)
	if mediator then
		return mediator:IsVirtualHiding()
	end
	return false
end


function ViewCtrlBase:CheckOpenCache()
	CWaring("ViewCtrlBase:CheckOpenCache")
	if self.IsHallStreamLevelLoading then
		CWaring("ViewCtrlBase:CheckOpenCache IsHallStreamLevelLoading")
		return
	end
	if self.IsCacheNeedOpenViewLooping then
		CWaring("ViewCtrlBase:CheckOpenCache IsCacheNeedOpenViewLooping")
		return
	end
	self.IsCacheNeedOpenViewLooping = true
	InputShieldLayer.Close()
	local NewCacheNeedOpenView = {}
	local ExistBreak = false
	for k,event in ipairs(self.CacheNeedOpenView) do
		CWaring("ViewCtrlBase:CheckOpenCache:" .. event.viewId)
		if ExistBreak then
			--中断执行以后，需要将剩作的OpenList加到列表中
			table.insert(NewCacheNeedOpenView,event)
		else
			local resultId = self.show_view(event)
			if resultId == 1 then
				--表示存在流加载，需要中断执行
				ExistBreak = true
			end
		end
	end
	self.CacheNeedOpenView = NewCacheNeedOpenView
	self.IsCacheNeedOpenViewLooping = false

	if #self.CacheNeedOpenView > 0 then
		self:CheckOpenCache()
	end
end

function ViewCtrlBase:Initialize()
	--事件处理

	--打开界面
	self.show_view = self.show_view or function(event)		
		local mediator  = self:GetView(event.viewId);
		if self.model:GetState(event.viewId) then
			mediator:CallOnRepeatShow(event.param)
			CWaring("repeat open view:" .. event.viewId)
			
			--[[
				重复打开界面时，会将目前上该界面上层的Mdt主动进行关闭
			]]
			if mediator.resType == GameMediator.UIResType.UMG 
			and mediator.uiLayer ~= UIRoot.UILayerType.Tips 
			and mediator.uiLayer ~= UIRoot.UILayerType.Scene 
			then
				-- 先把当前状态下的OpenList取出，再根据此份数据进行循环和判断，避免循环中，某个界面的onhide逻辑，修改了OpenList的数据，导致数据判断异常 @chenyishui
				local OpenList =  self.model:GetOpenListByLayerList({
					UIRoot.UILayerType.Dialog,
					UIRoot.UILayerType.Pop,
					-- UIRoot.UILayerType.Fix,	-- 当前只有HallMdt属于Fix，执行关闭上层界面逻辑可以排除Fix。没有需要关闭Fix层的需求，后续有再调整 @chenyishui
				})
				-- while true do
				for _,lastView in ipairs(OpenList) do
					-- local lastView = self.model:GetOpenLastView()
					if lastView and lastView.viewId and lastView.viewId ~= event.viewId then
						CWaring("repeat open view trigger clsoe front view:" .. lastView.viewId)
						self.hide_view(lastView)
					else
						break
					end
				end
			end

			return
		end
		-- if mediator.resType == GameMediator.UIResType.LEVEL_STREAM or mediator.resType == GameMediator.UIResType.LEVEL then
		-- 	if self.model.show_LEVEL_STREAM == event.viewId then
		-- 		CError("duplicate open Level:" .. event.viewId)
		-- 	end
		-- end

		if mediator.resType == GameMediator.UIResType.LEVEL and not self.Level2VirtualMap[event.viewId] then
			--正常关卡切换记录
			self.model.last_LEVEL_Fix = self.model.show_LEVEL_Fix
			self.model.show_LEVEL_Fix = event.viewId
			-- CWaring(StringUtil.Format("last_LEVEL_Fix:{0} show_LEVEL_Fix:{1}",self.model.last_LEVEL_Fix,self.model.show_LEVEL_Fix))
		end
		
		if self.ViewId2VirtualLevel[event.viewId] ~= nil then
			--[[
				如果属于虚拟视图关卡界面
			]]
			local DependLevelId = mediator.DependLevelId
			--TODO 需要检查依赖关卡是否已打开，如果未打开，需要优先打开真实关卡
			if not self.model:GetState(DependLevelId) then
				local mediatorDepend  = self:GetView(DependLevelId);
				local delayOpenViewId = event.viewId
				local delayOpenViewParam = event.param
				mediatorDepend:AddOnShowCustomCallBackList(function ()
					self:OpenView(delayOpenViewId,delayOpenViewParam)
				end)
				--TODO 更新上次关卡，由于此关卡为被依赖真实关卡，前置先将上次关卡进行记录
				--TODO 当前关卡等待虚拟关卡加载再进行赋值
				self.model.last_LEVEL_Fix = self.model.show_LEVEL_Fix
				self:OpenView(DependLevelId)
				return
			end
			--TODO 更新当前关卡/上次关卡
			self.model.last_LEVEL_Fix = self.model.show_LEVEL_Fix
			self.model.show_LEVEL_Fix = event.viewId
			-- CWaring(StringUtil.Format("last_LEVEL_Fix2:{0} show_LEVEL_Fix:{1}",self.model.last_LEVEL_Fix,self.model.show_LEVEL_Fix))

			--TODO 需要互斥掉已打开的同依赖界面
			for viewId,v in pairs(self.Level2VirtualMap[DependLevelId]) do
				if viewId ~= event.viewId then
					if self.model:GetState(viewId) then
						self:CloseView(viewId,nil,true,true)
					end
				end
			end
			--TODO 模拟真实关卡切换，会将所有已创建UMG进行关闭
			self:CloseAll()
		end


		if self.IsHallStreamLevelLoading then
			table.insert(self.CacheNeedOpenView,event)
			return
		end
		local TheShowViewFunc = function(NeedCheckVirtualHide)
			if NeedCheckVirtualHide then
				local popOpenList = self.model:GetOpenListByLayerList({UIRoot.UILayerType.Pop,UIRoot.UILayerType.Fix})
				local TheViewController = self:GetSingleton(ViewController)
				for k,v in pairs(popOpenList) do
					-- SpecialViewList 不参与VirtualTriggerHide
					if v.viewId ~= event.viewId and not TheViewController:IsInViewCheckWhiteList(ViewController.VIEW_CHECK_TYPE.SpecialView, v.viewId) then
						local mediatorTrigger  = self:GetView(v.viewId);
						if mediatorTrigger then
							mediatorTrigger:VirtualTriggerHide();
						end
					end
				end
			end

			self.model:SetState(event.viewId, true,event,mediator.uiLayer);
			mediator:Show(event.param);
			self.model:DispatchType(ViewModel.ON_AFTER_SATE_ACTIVE_CHANGED,event.viewId)
		end
		if self.id2HallSceneRefer[event.viewId] and _G.HallSceneMgrInst then
			--[[
				依赖虚拟场景的UI展示，
				需要将Pop层的UI都置为不可见
				需要进行SwitchScene切换流关卡及摄相机
			]]
			local SwitchSceneId = self.id2HallSceneRefer[event.viewId]
			CLog("SwitchScene:" .. SwitchSceneId .. "|ViewId:" .. event.viewId)
			self.IsHallStreamLevelLoading = true
			--TODO 添加InputShieldLayer屏蔽玩家操作，防止串用引发问题
			InputShieldLayer.Add(15,1,function ()
				--超时
				CWaring("SwitchScene Maby BeTimeout Please Check!")
				-- --超时需要清除回调，避免逻辑错误
				-- _G.HallSceneMgrInst:CleanSwitchSucCallBack()
				-- self.IsHallStreamLevelLoading = false
				-- TheShowViewFunc(true)
				-- self:CheckOpenCache()
			end)
			_G.HallSceneMgrInst:SwitchScene(SwitchSceneId,function ()
				--切换成功，才能执行打开逻辑
				self.IsHallStreamLevelLoading = false
				TheShowViewFunc(true)
				self:CheckOpenCache()
			end)
			--TODO 返回1，方便上层逻辑中断循环
			return 1
		end
		TheShowViewFunc()
	end

	--关闭界面
	self.hide_view = self.hide_view or function(event,notSwitchScene)
		if event.viewId == ViewConst.AllPopViews then
			self:CloseAllPops()
			return
		elseif event.viewId == ViewConst.AllPopViewsOnTargetId then
			self:CloseAllPopsOnTargetView(event.param)
			return
		end
		if event.notSwitchScene ~= nil and notSwitchScene == nil then
			notSwitchScene = event.notSwitchScene
		end
		local  view_mdt  = self:GetView(event.viewId);
		if view_mdt ~= nil then
			local TheIsOpen = self.model:GetState(event.viewId)
			if not TheIsOpen then
				CWaring("repeate close view:" .. event.viewId)
				return
			end 
			if view_mdt.resType == GameMediator.UIResType.LEVEL_STREAM or view_mdt.resType == GameMediator.UIResType.LEVEL
			or (view_mdt.resType == GameMediator.UIResType.VIRTUAL and view_mdt.virtualType == GameMediator.UIVirtualType.LEVEL)
			then
				if not event.force then
					CError("关卡/流关卡/关卡类虚拟视图，不能主动关闭")
					return
				end
			end

			if self.Level2VirtualMap[event.viewId] ~= nil then
				--TODO 需要关闭此关卡ID 旗下所依赖的虚拟视图界面
				for viewId,v in pairs(self.Level2VirtualMap[event.viewId]) do
					self:CloseView(viewId,nil,true)
				end
			end

			self.model:SetState(event.viewId, false);
			view_mdt:Hide(event.param);
			self.model:DispatchType(ViewModel.ON_AFTER_SATE_DEACTIVE_CHANGED,event.viewId)
			-- 默认会进行虚拟场景切换 notSwitchScene可阻拦这一操作
			if not notSwitchScene  then
				self:SwitchVirtualScene(event.viewId,true)
			end
		end
	end

	--反转显示界面
	self.toggle_view = self.toggle_view or function(event)
		local  view_mdt  = self:GetView(event.viewId);
		if view_mdt ~= nil then
			view_mdt:Toggle(event.param);
		end
	end

	self:AddMsgListener(CommonEvent.SHOW_VIEW, self.show_view);
	self:AddMsgListener(CommonEvent.HIDE_VIEW, self.hide_view);
	self:AddMsgListener(CommonEvent.TOGGLE_VIEW, self.toggle_view);
end

function ViewCtrlBase:__dispose()
	self.id_refer = nil;
	self.model = nil;


	--事件处理
	if self.show_view ~= nil then
		self:RemoveMsgListener(CommonEvent.SHOW_VIEW, self.show_view);
		self.show_view = nil;
	end

	if self.hide_view ~= nil then
		self:RemoveMsgListener(CommonEvent.HIDE_VIEW, self.hide_view);
		self.hide_view = nil;
	end

	if self.toggle_view ~= nil then
		self:RemoveMsgListener(CommonEvent.TOGGLE_VIEW, self.toggle_view);
		self.toggle_view = nil;
	end
end

---@param id number View的唯一Id
---@param view_class Class 对应的Mediator类
function ViewCtrlBase:RegisterView(id, view_class)
	if not id then
		CError("ViewCtrlBase:RegisterView viewId nil! please check")
		return
	end
	if not view_class then
		CError("ViewCtrlBase:RegisterView view_class nil! please check")
		return
	end
	self.id_refer[id] = view_class;

	local viewCfg = ViewConstConfig and ViewConstConfig[id] or nil
	if not viewCfg then
		CError("ViewCtrlBase:RegisterView cfg not found,the view id:" .. id,true)
		return
	end
	if viewCfg.UIResType and viewCfg.UIResType == GameMediator.UIResType.VIRTUAL then
		viewCfg.UIVirtualType = viewCfg.UIVirtualType or GameMediator.UIVirtualType.NORMAL
		if viewCfg.UIVirtualType == GameMediator.UIVirtualType.LEVEL then
			if not viewCfg.DependLevelId then
				CError("ViewCtrlBase:RegisterView cfg.DependLevelId not found,the view id:" .. id,true)
				return
			end
			self.ViewId2VirtualLevel[id] = 1
			self.Level2VirtualMap[viewCfg.DependLevelId] = self.Level2VirtualMap[viewCfg.DependLevelId] or {}
			self.Level2VirtualMap[viewCfg.DependLevelId][id] = 1
		end
	end
end

function ViewCtrlBase:RegisterVirtualLevelView(id,sceneId)
	self.id2HallSceneRefer[id] = sceneId
end

--[[
	依赖虚拟场景的UI隐藏
	需要将Pop层的UI都置为可见
	计算剩余打开UI还存在的（依赖虚拟场景的UI），就近取这个UI依赖的场景进行Switch
	isCloseTarget为true时，targetViewId为即将关闭的界面Id。直接找剩余打开界面的场景信息
]]
function ViewCtrlBase:SwitchVirtualScene(targetViewId,isCloseTarget)
	if self.id2HallSceneRefer[targetViewId] and _G.HallSceneMgrInst then
		local findHallSceneViewInfo = nil
		if not isCloseTarget and self.id2HallSceneRefer[targetViewId] then
			findHallSceneViewInfo = {}
			findHallSceneViewInfo.viewId = targetViewId
			findHallSceneViewInfo.sceneId = self.id2HallSceneRefer[targetViewId]
		else
			local openList = self.model:GetOpenListByLayerList({UIRoot.UILayerType.Pop,UIRoot.UILayerType.Fix})
			for k,v in pairs(openList) do
				if v.viewId ~= targetViewId then
					if self.id2HallSceneRefer[v.viewId] then
						if not findHallSceneViewInfo then
							CWaring("findVirtualScene:" .. v.viewId)
							findHallSceneViewInfo = {}
							findHallSceneViewInfo.viewId = v.viewId
							findHallSceneViewInfo.sceneId = self.id2HallSceneRefer[v.viewId]
							break
						else
							CWaring("findVirtualScene Keep Hide:" .. v.viewId)
						end
					else
						local mediatorTrigger  = self:GetView(v.viewId);
						if mediatorTrigger then
							mediatorTrigger:VirtualTriggerShow();
						end
					end
				end
			end
		end
		if findHallSceneViewInfo then
			CWaring("SwitchVirtualScene:" .. findHallSceneViewInfo.sceneId)
			local TheViewId = findHallSceneViewInfo.viewId
			local TheSceneId = findHallSceneViewInfo.sceneId
			_G.HallSceneMgrInst:SwitchScene(TheSceneId,function ()
				local mediatorTrigger  = self:GetView(TheViewId);
				if mediatorTrigger then
					mediatorTrigger:VirtualTriggerShow();
				end
			end)
		end
	end
end
--[[
	所有弹出窗口（仅用于关闭
	关闭Pop层
]]
function ViewCtrlBase:CloseAllPops()
	CWaring("CloseAllPops")
	local list = self.model:GetOpenList(UIRoot.UILayerType.Pop)

	for _,v in pairs(list) do
		-- print(v)
		self.hide_view(v,true)
	end
	--执行成功以后，派出通知
	self.model:DispatchType(ViewModel.ON_CLOSE_ALLPOPVIEWS);
end

function ViewCtrlBase:CloseAll()
	local list = self.model:GetOpenListFilterLayers({UIRoot.UILayerType.Scene,UIRoot.UILayerType.KeepAlive})
	for _,v in pairs(list) do
		-- print(v)
		self.hide_view(v,true)
	end
	--执行成功以后，派出通知
	self.model:DispatchType(ViewModel.ON_CLOSE_ALLVIEWS);
end

--[[
	1. 关闭所有弹出窗口（关闭期间不切换虚拟场景）
	2. 切换到targetViewId依赖的虚拟场景(如果有）/ 否则，从剩余打开UI还存在的（依赖虚拟场景的UI）中找就近的，同hide_view逻辑
]]
function ViewCtrlBase:CloseAllPopsOnTargetView(targetViewId)
	-- local list = self.model:GetOpenList(UIRoot.UILayerType.Pop)
	local list = self.model:GetOpenListByLayerList({UIRoot.UILayerType.Pop,UIRoot.UILayerType.Dialog,UIRoot.UILayerType.Tips})
	for _,v in pairs(list) do	
		-- print(v)
		self.hide_view(v,true)
	end
	self:SwitchVirtualScene(targetViewId)
end