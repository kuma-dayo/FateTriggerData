require("Core.Mvc.GameController");

--[[UI逻辑控制器, 就是MVC中的Mediator, 但同时有Controller的所有功能。如果UI是复杂UI，请重写view类并重写Show()函数。
把View和Mediator分得更清楚。简单UI可以直接在续承后的GameMediator类中写解析逻辑。]]
local class_name = "GameMediator";
local super = GameController;
---@class GameMediator : GameController
---@field super GameController
GameMediator = GameMediator or BaseClass(super,class_name);

-- GameMediator.openingViewMap = GameMediator.openingViewMap or {};
--[[View资源类型]]
GameMediator.UIResType = {
	--空值
	NONE = 0,
	--UMG
	UMG = 1,
	--关卡
	LEVEL = 2,
	--流关卡
	LEVEL_STREAM = 3,
	--虚拟视图
	VIRTUAL = 4,
	--自定义
	CUSTOM = 255,
}
GameMediator.VisibleMode = {
	--销毁模式
	Destroy = 0,
	--隐藏模式
	HIDE = 1,
}
--虚拟视图类型
GameMediator.UIVirtualType = {
	--常规
	NORMAL = 0,
	--[[
		关卡  赋带逻辑
		1.切换时，模拟真实关卡切换，会将所有已创建UMG进行关闭
		2.界面配置必须有依赖的真实关卡界面ID
		3.相同依赖真实关卡的 虚拟关卡之间是互斥关系，只会同时打开一个
	]]
	LEVEL = 1,
}

-- --[[
-- 	玩家输入模式  默认为UI
-- ]]
-- GameMediator.InputMode = {
-- 	--仅UI
-- 	UI = 0,
-- 	--仅游戏
-- 	GAME = 1,
-- }

function GameMediator:__init()
	-- self.__class_name = "GameMediator";

	--持久化数据，跟着mdt实例走
	self.resType = GameMediator.UIResType.UMG;
	self.virtualType = GameMediator.UIVirtualType.NORMAL;
	self.DependLevelId = nil
	self.resUrl = ""
	self.scriptUrl = ""
	self.uiLayer = UIRoot.UILayerType.Pop
	--输入模式针对关卡生效
	-- self.inputMode = GameMediator.InputMode.UI
	self.viewId = 0;
	self.isUrlTravel = false
	self.visible_mode = GameMediator.VisibleMode.Destroy;	
	
	self:DataInit()
end

--[[
	非持久化数据，当mdt关闭，需要初始化
]]
function GameMediator:DataInit()
	self.data = nil;
	--[[
		是否因为Virtual场景，导致被隐藏
	]]
	self.virtualBeHiding = false
	self.OnShowCustomCallBackList = {}
end

function GameMediator:DestructInner()
	self.is_opening = false
	self:removeBrigeEvents()
end

-- --[[
-- 	resUrl UMG的路径/流关卡路戏/关卡路径(DS章局时此字段会变成 DS服务器的URL)
-- 	scriptUrl 动态绑定的Lua脚本路径/流关卡所属主关卡/空值
-- 	resType 资源类型 默认是UMG
-- ]]
-- ---注册资源和对应可选的脚本
-- ---@param resUrl string UMG的路径/流关卡路戏/关卡路径(DS章局时此字段会变成 DS服务器的URL)
-- ---@param scriptUrl string 动态绑定的Lua脚本路径/流关卡所属主关卡/空值
-- ---@param resType UIResType optional 资源类型，默认是UIResType.UMG
-- function GameMediator:ConfigData(resUrl,scriptUrl,resType)
-- 	self.resUrl = resUrl or self.resUrl
-- 	self.scriptUrl = scriptUrl or self.scriptUrl
-- 	self.resType = resType or self.resType

-- 	if self.resType == GameMediator.UIResType.LEVEL_STREAM or self.resType == GameMediator.UIResType.LEVEL then
-- 		self.uiLayer = UIRoot.UILayerType.Scene
-- 	end
-- end

---注册资源和对应可选的脚本
---@param viewId number 注册界面ID，通过界面ID可获取UMG路径、Lua代理，资源类型等配置
function GameMediator:ConfigViewId(viewId)
	local viewCfg = ViewConstConfig and ViewConstConfig[viewId] or nil
	if not viewCfg then
		CError("GameMediator:ConfigViewId cfg not found,the view id:" .. viewId)
		print_trackback()
		return
	end
	self.viewId = viewId
	self.resUrl = viewCfg.Path or self.resUrl
	self.scriptUrl = viewCfg.LuaPath or self.scriptUrl
	self.resType = viewCfg.UIResType or self.resType
	self.uiLayer = viewCfg.UILayerType or self.uiLayer
	self.customZorder = viewCfg.CustomZOrder or nil
	self.virtualType = viewCfg.UIVirtualType or self.virtualType
	self.DependLevelId = viewCfg.DependLevelId or self.DependLevelId
	self.visible_mode = viewCfg.VisibleMode or self.visible_mode

	if self.resType == GameMediator.UIResType.LEVEL_STREAM or self.resType == GameMediator.UIResType.LEVEL then
		self.uiLayer = UIRoot.UILayerType.Scene
	end
	if self.resType == GameMediator.UIResType.VIRTUAL and self.virtualType == GameMediator.UIVirtualType.LEVEL then
		self.uiLayer = UIRoot.UILayerType.Scene
	end
end

--[[
	关闭自身
]]
function GameMediator:CloseSelf()
	self:CloseView(self.viewId)
end

--释放界面资源 由mvc主动调用
function GameMediator:DisposeUI(isDisposeUIByNode)
	CWaring("============GameMediator:DisposeUI:" .. self.viewId .. "|isDisposeUIByNode:" .. (isDisposeUIByNode and "1" or "0"))
	if self.is_opening then
		self.is_opening = false
		self:OnDisposeUI();
		if self.view ~= nil then
			if self:isUMGValid(self.view) then
				if self.resType == GameMediator.UIResType.UMG then
					if self.visible_mode == GameMediator.VisibleMode.HIDE then
						--TODO
						self.view:SetVisibility(UE.ESlateVisibility.Collapsed)
					else
						self:removeBrigeEvents()
						self.view:RemoveFromParent()
						self.view = nil
					end
				else
					self.view = nil
				end
			else
				self.view = nil
			end
		end
		if self.resType == GameMediator.UIResType.UMG then
			-- 通知UIRoot更新层级子节点计数
			UIRoot.OnLayerChildDisposed(self.uiLayer,self.viewId)
		end
		if not isDisposeUIByNode then
			if self.resType == GameMediator.UIResType.LEVEL_STREAM then
				--清除流关卡缓存
				self:UnloadStreamLevelFunc(self.resUrl,false)
			end
		end
		self:DataInit();
	end
	if isDisposeUIByNode then
		self:DestructInner()
	end
end

function GameMediator:UnloadStreamLevelFunc(levelName,bShouldBlockOnLoad)
	coroutine.resume(coroutine.create(GameMediator.DoUnloadStreamLevelFunc),self,GameInstance,levelName,bShouldBlockOnLoad)
end

function GameMediator:DoUnloadStreamLevelFunc(WorldContectObject,levelName,bShouldBlockOnLoad)    
	-- UE.UKismetSystemLibrary.Delay(WorldContectObject,duration)
	CWaring("unloading---levelName:" .. levelName)
	UE.UGameplayStatics.UnloadStreamLevel(WorldContectObject,levelName,bShouldBlockOnLoad)
	CWaring("unloaded---levelName:" .. levelName)
end

--释放界面资源，由蓝图销毁被动触发
function GameMediator:DisposeUIByNode()
	CLog("============GameMediator:DisposeUIByNode:" .. self:ClassName())
	--[[
		SetState必须模拟mvc关闭顺序
		在CallOnHide之前调用
	]]
	self:GetModel(ViewModel):SetState(self.viewId,false)
	self:CallOnHide()
	self:DisposeUI(true);
end

--[[/**释放UI调用，子类重写此方法实现自己的逻辑。 */]]
function GameMediator:OnDisposeUI()
	-- body
end

--[[显示时调用，子类重写此方法实现自己的逻辑]]
function GameMediator:OnShow(data)
	-- body
end
--[[重复显示时调用，子类重写此方法实现自己的逻辑]]
function GameMediator:OnRepeatShow(data)
	-- body
end
--[[隐藏时调用，子类重写此方法实现自己的逻辑]]
function GameMediator:OnHide()
	-- body
end
--[[虚拟场景触发还原时调用，子类重写此方法实现自己的逻辑]]
function GameMediator:OnVirtualTriggerShow()
end
--[[
	虚拟场景展示时调用，触发隐藏其它UI
]]
function GameMediator:OnVirtualTriggerHide()
end

function GameMediator:CallOnShow()
	if self.resType == GameMediator.UIResType.LEVEL or self.resType == GameMediator.UIResType.LEVEL_STREAM then
		-- if self.inputMode == GameMediator.InputMode.UI then
		-- 	CLog("SetInputMode_UIOnly============")
		-- 	UE.UWidgetBlueprintLibrary.SetInputMode_UIOnly(CommonUtil.GetLocalPlayerC())
		-- elseif self.inputMode == GameMediator.InputMode.GAME then
		-- 	CLog("SetInputMode_GameOnly============")
		-- 	UE.UWidgetBlueprintLibrary.SetInputMode_GameOnly(CommonUtil.GetLocalPlayerC())
		-- end
	end
	local IsViewValid = self:isUMGValid(self.view)
	-- Change Focus Before OnShow Called
	if IsViewValid then
		if self.resType == GameMediator.UIResType.UMG then
			-- 如果界面确定无需输入事件，设置了强制关闭WidgetFocus，则不触发focus事件派发
			if not self.view or not self.view.CloseWidgetFocus then
			--TODO Focus
				CWaring("CallOnShow:" .. self.viewId)
				self:GetModel(CommonModel):DispatchType(CommonModel.ON_WIDGET_TO_FOCUS,self.viewId)
			end
		end
	end
	self:OnShow(self.data);
	if IsViewValid then
		if self.view and self.view.PreOnShow then
			self.view:PreOnShow(self.data)
		else
			CWaring("View nil or view.PreOnShow nil:" .. self.viewId)
		end
		if self.view and self.view.OnShow then
			self.view:OnShow(self.data)
		else
			CWaring("View nil or view.OnShow nil:" .. self.viewId)
		end
		if self.view and self.view.OnShowSound then
			self.view:OnShowSound(self.data)
		end
		if self.view and self.view.OnShowAvator then
			self.view:OnShowAvator(self.data,true)
		end
	end
	for k,v in ipairs(self.OnShowCustomCallBackList) do
		v();
	end
	self:ClearOnShowCustomCallBackList()
	self:GetModel(ViewModel):DispatchType(ViewModel.ON_VIEW_ON_SHOW .. self.viewId)
end

function GameMediator:CallOnRepeatShow(data)
	self:OnRepeatShow(data);
	if self:isUMGValid(self.view) then
		if self.view and self.view.OnRepeatShow then
			self.view:OnRepeatShow(data)
		else
			CWaring("GameMediator:CallOnRepeatShow OnRepeatShow not found:" .. self:ClassName())
		end
	end
	self:GetModel(ViewModel):DispatchType(ViewModel.ON_REPEAT_SHOW .. self.viewId,data)
end

function GameMediator:CallOnHide()
	if self:isUMGValid(self.view) then
		if self.view and self.view.PreOnHide then
			self.view:PreOnHide(self.data)
		else
			CWaring("View nil or view.PreOnHide nil:" .. self.viewId)
		end
		if self.view and self.view.OnHideSound then
			self.view:OnHideSound(self.data)
		end
		if self.view and self.view.OnHideAvator then
			self.view:OnHideAvator(self.data,true)
		end
		if self.view and self.view.OnHide then
			self.view:OnHide()
		else
			CWaring("View nil or view.OnHide nil:" .. self.viewId)
		end
	else
		if self.resType == GameMediator.UIResType.UMG then
			CWaring("view not valid:" .. self.viewId)
		end
	end
	self:OnHide();
	--TODO Focus Last
	-- 如果界面确定无需输入事件，设置了强制关闭WidgetFocus，则不触发focus事件派发
	if not self.view or not self.view.CloseWidgetFocus then
		local lastView = self:GetModel(ViewModel):GetOpenLastView()
		if lastView and lastView.viewId then
			self:GetModel(CommonModel):DispatchType(CommonModel.ON_WIDGET_TO_FOCUS,lastView.viewId)
		end
	end
end


function GameMediator:isUMGValid(node)
	return CommonUtil.IsValid(node)
end

function GameMediator:addBrigeEvents()
	if not self:isUMGValid(self.view) then
		return
	end
	self.view:AddListener(CommonEvent.ON_DESTRUCT,self.DisposeUIByNode,self)

	-- if self:isUMGValid(self.brige_widget) then
	-- 	return
	-- end
	-- CLog("GameMediator:addBrigeEvents")
	-- --TODO 添加事件监听
	-- ---添加钩子, 当目标widget销毁时调用GameMediator的OnHide()函数
	-- local brige_class = UE.UClass.Load('/Game/UMG/Base/WBP_UIBrige.WBP_UIBrige')
	-- self.brige_widget = NewObject(brige_class, GameInstance, nil, "Client.Common.UIBrige")
	-- local rootWidget = self.view.WidgetTree and self.view.WidgetTree.RootWidget or nil--self.view:GetRootWidget()
	-- rootWidget:AddChild(self.brige_widget)
	-- --设置目标widget，销毁时清理在c++的引用
	-- self.brige_widget:SetHandlerUMGRelease(self.view)
	-- --监听组件设置为不可见状态
	-- self.brige_widget:SetVisibility(UE.ESlateVisibility.Hidden)
	-- --添加移除监听
	-- self.brige_widget:AddListener(UIBrige.ON_DESTRUCT,self.DisposeUIByNode,self)
end

function GameMediator:removeBrigeEvents()
	if not self:isUMGValid(self.view) then
		return
	end
	self.view:RemoveListener(CommonEvent.ON_DESTRUCT,self.DisposeUIByNode,self)

	-- if not self:isUMGValid(self.brige_widget) then
	-- 	return
	-- end
	-- CLog("GameMediator:removeBrigeEvents")
	-- self.brige_widget:RemoveListener(UIBrige.ON_DESTRUCT,self.DisposeUIByNode,self)
	-- self.brige_widget:RemoveFromParent()
	-- self.brige_widget = nil
end

--[[由mvc调用]]
function GameMediator:Show(data)
	self.data = data;
	self.is_opening = true
	
	if self.resType == GameMediator.UIResType.UMG then
		--UMG视图
		if self:isUMGValid(self.view) == false then
			--TODO 创建
			-- CWaring("self:ClassName():" .. self.resUrl)
			self.resUrl = CommonUtil.FixBlueprintPathWithC(self.resUrl)
			local widget_class = UE.UClass.Load(self.resUrl)
			if not widget_class then
				CError("widget_class not found:" .. self.resUrl,true)
				return
			end
			CWaring("self:ClassName():" .. self:ClassName() .. "|ScriptUrl:" .. self.scriptUrl)
			local widget = NewObject(widget_class, GameInstance, nil, self.scriptUrl)
			-- 为了兼容UserWidget能执行OnNativeInitialize，手动调用设置PlayerContext
			UE.UGFUnluaHelper.UserWidgetSetPlayerContext(GameInstance,widget)
			self.view = widget
			self.view.viewId = self.viewId
			self.view.MvcCtrl = true
			-- self.view.mdt = self
			UIRoot.AddChildToLayer(self.view,self.uiLayer,self.customZorder)
			-- --TODO 添加事件监听
			self:addBrigeEvents()
		else
			if self.visible_mode ~= GameMediator.VisibleMode.HIDE then
				CError("GameMediator:Show  view not be Destruct,Logic Error,Please Check:" .. self.viewId,true)
				return
			else
				self.view:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
				UIRoot.OnLayerChildAdd(self.view,self.uiLayer,self.customZorder)
			end
		end
		self:CallOnShow()
	elseif self.resType == GameMediator.UIResType.LEVEL_STREAM then
		--流关卡
		self.uiLayer = UIRoot.UILayerType.Scene
		--需要判断主关卡是否存在 (未做，后续迭代)

		--进行加载流关卡
		self:LoadStreamLevelFunc(self.resUrl,true,false)
	elseif self.resType == GameMediator.UIResType.LEVEL then
		--关卡
		self.uiLayer = UIRoot.UILayerType.Scene
		-- local data = {
		-- 	resUrl = StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam_Pro2_1"),ds_info.wanip,ds_info.port),
		-- 	option = option,
		-- }
		if self.data and self.data.option and self.data.resUrl then
			--属于DS章局关卡，定制resUrl为  DS服务器URL
			self.isUrlTravel = true
			self.resUrl = self.data.resUrl
		end
		self:LoadLevelFunc()
	elseif self.resType == GameMediator.UIResType.CUSTOM then
		-- 自定义逻辑
		self:CallOnShow()
	elseif self.resType == GameMediator.UIResType.VIRTUAL then
		-- 虚拟视图
		self:CallOnShow()
	end
end

--[[
	使用协程加载流关卡1
]]
function GameMediator:LoadStreamLevelFunc(levelName,bMakeVisibleAfterLoad,bShouldBlockOnLoad)
	coroutine.resume(coroutine.create(GameMediator.DoLoadStreamLevel),self,GameInstance,levelName,bMakeVisibleAfterLoad,bShouldBlockOnLoad)
end

--[[
	使用协程加载流关卡2
]]
function GameMediator:DoLoadStreamLevel(WorldContectObject,levelName,bMakeVisibleAfterLoad,bShouldBlockOnLoad)    
	-- UE.UKismetSystemLibrary.Delay(WorldContectObject,duration)
	-- CWaring("loading---levelName:" .. levelName)
	UE.UGameplayStatics.LoadStreamLevel(WorldContectObject,levelName,bMakeVisibleAfterLoad,bShouldBlockOnLoad)
	CWaring("loaded-StreamLevel---levelName:" .. levelName)

	local model = self:GetModel(ViewModel)
	if model.show_LEVEL_STREAM > 0 and model.show_LEVEL_STREAM ~= self.viewId then
		--清除流关卡缓存
		self:CloseView(model.show_LEVEL_STREAM,nil,true)
	end
	model.show_LEVEL_STREAM = self.viewId

	local level = UE.UGameplayStatics.GetStreamingLevel(WorldContectObject,levelName)
	local actor = level:GetLevelScriptActor()
	self.view = actor
	self.view.viewId = self.viewId
	
	self:CallOnShow()
end

--[[
	加载普通关卡1
]]
function GameMediator:LoadLevelFunc()
	if self.isUrlTravel then
		--传Data记录DS相关信息 切关卡同时连接DS服务器
		self:GetModel(CommonModel):AddListener(CommonModel.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP,self.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP_Func,self,3)
		self:GetModel(CommonModel):AddListener(CommonModel.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD,self.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_Func,self)
		self:GetModel(CommonModel):AddListener(CommonModel.ON_LEVEL_BATTLE_POSTLOADMAPWITHWORLD,self.ON_LEVEL_BATTLE_POSTLOADMAPWITHWORLD_Func,self)
		self:GetModel(CommonModel):DispatchType(CommonModel.ON_LEVEL_BATTLE_START_TRAVEL)
		local Params = ""
		for Key, Value in pairs(self.data.option) do
			Params = string.format("%s?%s=%s", Params, tostring(Key), tostring(Value))
		end
		local ExecUrl = self.resUrl .. Params
		CWaring("GameMediator:LoadLevelFunc", ">> ReqConnectDServer, ", ExecUrl)
		local LocalPC = UE.UGameplayStatics.GetPlayerController(GameInstance, 0)
		UE.UKismetSystemLibrary.ExecuteConsoleCommand(LocalPC, ExecUrl, LocalPC)
	else
		self:GetModel(CommonModel):AddListener(CommonModel.ON_LEVEL_POSTLOADMAPWITHWORLD,self.ON_LEVEL_POSTLOADMAPWITHWORLD_Func,self)
		CWaring("LoadLevelFunc:" .. self.resUrl .. "|viewId:" .. self.viewId)
		UE.UGameplayStatics.OpenLevel(GameInstance,self.resUrl,true)
	end  
end

--战斗地图还未开始Load，由于网络原因Trave行为被停止了
function GameMediator:ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP_Func()
	CWaring("GameMediator:ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP_Func")
	self:GetModel(CommonModel):RemoveListener(CommonModel.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP,self.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP_Func,self)

	local TheViewModel = self:GetModel(ViewModel)
	local Show = TheViewModel.show_LEVEL_Fix
	TheViewModel.show_LEVEL_Fix = TheViewModel.last_LEVEL_Fix 
	TheViewModel.last_LEVEL_Fix = Show
	TheViewModel:SetState(self.viewId, false);
end

--战斗地图开始加载
function GameMediator:ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_Func()
	self:GetModel(CommonModel):RemoveListener(CommonModel.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD,self.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_Func,self)
	self:GetModel(CommonModel):RemoveListener(CommonModel.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP,self.ON_LEVEL_BATTLE_PRELOADMAPWITHWORLD_STOP_Func,self)
end

--战斗地图加载完成
function GameMediator:ON_LEVEL_BATTLE_POSTLOADMAPWITHWORLD_Func(InMapName)
	self:GetModel(CommonModel):RemoveListener(CommonModel.ON_LEVEL_BATTLE_POSTLOADMAPWITHWORLD,self.ON_LEVEL_BATTLE_POSTLOADMAPWITHWORLD_Func,self)
	self:DoLoadLevel()
end

function GameMediator:ON_LEVEL_POSTLOADMAPWITHWORLD_Func(InMapName)
	CWaring("GameMediator:ON_LEVEL_POSTLOADMAPWITHWORLD_Func:" .. InMapName)
	self:GetModel(CommonModel):RemoveListener(CommonModel.ON_LEVEL_POSTLOADMAPWITHWORLD,self.ON_LEVEL_POSTLOADMAPWITHWORLD_Func,self)
	if UE.UGFUnluaHelper.IsEditor() then
		-- 编辑器模式下地图名称会给带上前缀，临时处理，匹配去除，后续再根据需要修改 @chenyishui
		InMapName = string.gsub(InMapName, "UEDPIE_%d_", "")
		CWaring("GameMediator:ON_LEVEL_POSTLOADMAPWITHWORLD_Func Fix InMapName:" .. InMapName)
	end
	if string.match(self.resUrl, InMapName) then
		self:DoLoadLevel()
	else
		CError(StringUtil.Format("GameMediator:ON_LEVEL_POSTLOADMAPWITHWORLD_Func InMapName not match  InMapName:{0} resUrl:{1}",InMapName,self.resUrl),true)
	end
end

--[[
	加载普通关卡2
]]
function GameMediator:DoLoadLevel() 
    local level = GameInstance:GetWorld().PersistentLevel
	self.view = level.LevelScriptActor
	if self.view ~= nil then
		self.view.viewId = self.viewId
	end
	
	CWaring("loaded-Level---levelName:" .. self.resUrl .. "|viewId:" .. self.viewId)

	local model = self:GetModel(ViewModel)
	if model.show_LEVEL > 0 and model.show_LEVEL ~= self.viewId then
		--清除旧关卡缓存及将旧关卡状态置空
		self:CloseView(model.show_LEVEL,nil,true)
		model.last_LEVEL = model.show_LEVEL
	end
	self:GetModel(ViewModel).show_LEVEL = self.viewId
	--TODO 关闭所有弹窗界面 openLevel会动将所有UMG内容关闭不需要主动调用
	-- self:CloseView(ViewConst.AllPopViews)

	self:CallOnShow()
end

--[[由mvc调用  关闭自己请调用CloseSelf]]
function GameMediator:Hide()
	if self.is_opening then
		self:CallOnHide()
	end
	self:DisposeUI()
end

function GameMediator:Toggle(data)
	if self:IsOpen() then
		self:Hide();
	else
		self:Show(data);
	end
end

function GameMediator:VirtualTriggerShow()
	if self.virtualBeHiding == false then
		return
	end
	if self:isUMGValid(self.view) == false then
		return
	end
	if self.resType ~= GameMediator.UIResType.UMG then
		return
	end
	self.view:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	self.virtualBeHiding = false
	self:OnVirtualTriggerShow();
	CWaring("VirtualTriggerShow:" .. self.viewId)
	if self.view and self.view.OnVirtualTriggerShow then
		self.view:OnVirtualTriggerShow()
	end
end
function GameMediator:VirtualTriggerHide()
	if self.virtualBeHiding == true then
		return
	end
	if self:isUMGValid(self.view) == false then
		return false
	end
	if self.resType ~= GameMediator.UIResType.UMG then
		return false
	end
	if self.view:GetVisibility() == UE.ESlateVisibility.Collapsed or self.view:GetVisibility() == UE.ESlateVisibility.Hidden then
		CWaring("VirtualTriggerHide unsuc")
		return false
	end
	self.view:SetVisibility(UE.ESlateVisibility.Collapsed)
	self.virtualBeHiding = true
	self:OnVirtualTriggerHide();
	CWaring("VirtualTriggerHide:" .. self.viewId)
	if self.view and self.view.OnVirtualTriggerHide then
		self.view:OnVirtualTriggerHide()
	end
	
	return true;
end

function GameMediator:AddOnShowCustomCallBackList(Callback)
	table.insert(self.OnShowCustomCallBackList,Callback)
end
function GameMediator:ClearOnShowCustomCallBackList()
	self.OnShowCustomCallBackList = {}
end

function GameMediator:IsVirtualHiding()
	return self.virtualBeHiding
end


return GameMediator;