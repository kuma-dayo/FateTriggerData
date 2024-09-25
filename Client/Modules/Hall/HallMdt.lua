--[[
    大厅界面
]]
local class_name = "HallMdt"
---@class HallMdt : GameMediator
HallMdt = HallMdt or BaseClass(GameMediator, class_name)

function HallMdt:__init()
end

function HallMdt:OnShow(data)

end

function HallMdt:OnHide()
end

-------------------------------------------------------------------------------
---@class HallMdt_C
local M = Class("Client.Mvc.UserWidgetBase")

M.ShowSmallWidgetConfig = {
	[CommonConst.HL_PLAY] = true,
	[CommonConst.HL_HERO] = true,
	[CommonConst.HL_ARSENAL] = true,
	[CommonConst.HL_SHOP] = true,
	[CommonConst.HL_SEASON] = true,
}

function M:OnInit()
    self.MsgList = {
		{Model = HallModel, 	MsgName = HallModel.TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE,	Func = self.On_TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE_Func },
		{Model = MatchModel,  	MsgName = MatchModel.ON_DS_ERROR,         					Func = self.ON_DS_ERROR_Func},
		{Model = MatchModel,  	MsgName = MatchModel.ON_MATCH_IDLE,         					Func = self.ON_MATCH_IDLE_Func},
		{Model = MatchModel,  	MsgName = MatchModel.ON_MATCH_SUCCESS,         				Func = self.ON_GAMEMATCH_SUCCECS_Func},
		
		{Model = FriendModel,  	MsgName = FriendModel.ON_FRIEND_LIST_UPDATED,         				Func = self.UpdateFriendCount},
		{Model = FriendModel,  	MsgName = ListModel.ON_DELETED,         				Func = self.UpdateFriendCount},
		{Model = FriendModel,  	MsgName = FriendModel.ON_ADD_FRIEND,         				Func = self.UpdateFriendCount},
		{Model = CommonModel,  	MsgName = CommonModel.ON_ASYNC_LOADING_FINISHED_HALL,         				Func = self.OnAsyncLoadingScreenLoadingFinished},
		{Model = SeasonModel,  	MsgName = SeasonModel.ON_UPDATE_CURRENT_SEASON_EVENT,         				Func = self.UpdateSeasonName},
		{Model = SeasonBpModel,  	MsgName = SeasonBpModel.ON_SEASON_BP_INFO_INIT,         				Func = self.UpdateSeasonBPLevel},
		{Model = SeasonBpModel,  	MsgName = SeasonBpModel.ON_SEASON_BP_LEVEL_UPDATE,         				Func = self.UpdateSeasonBPLevel},
		
		{ Model = nil, MsgName = CommonEvent.ON_AFTER_BACK_TO_HALL, Func = self.OnAfterBackToHall },
	}
	self.BindNodes = {
		-- {UDelegate = self.OnCustomAniFinished_VxHallIn,Func = Bind(self,self.SetAllUIVisibilityCB,true)},
		{UDelegate = self.OnCustomAniFinished_VxHallMatchSuccess,Func = Bind(self,self.SetAllUIVisibilityCB,false)},
		
		{ UDelegate = self.WBP_Setting.GUIButton.OnClicked,			Func = self.OnCliked_BtnSetting},
		{ UDelegate = self.WBP_Mail.GUIButton.OnClicked,			Func = self.OnCliked_BtnMail },
		-- { UDelegate = self.WBP_More.GUIButton.OnClicked,			Func = self.OnCliked_BtnMore },		
		{ UDelegate = self.WBP_Broadcast.GUIButton.OnClicked,			Func = self.OnCliked_BtnBroadcast },		
		{ UDelegate = self.WBP_FriendManager.GUIButton.OnClicked,			Func = self.OnCliked_BtnFriendManager },	
		{ UDelegate = self.WBP_Depot.GUIButton.OnClicked,			Func = self.OnCliked_Depot },	
	}
	local Param = {
		Container = self.PanelTabContent,
		ClickCallBack = Bind(self,self.OnCheckSmallWidgetShow),
		-- OnShowTabHallTabView = Bind(self,self.OnShowTabHallTabView)
	}
	self.CommonHallTab = UIHandler.New(self,self.WBP_Common_TabUPBar_01, WCommonHallTab, Param).ViewInstance

	--注册红点
	self.WBP_RedDotFactory_Mail:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	self.MailRedDot = UIHandler.New(self, self.WBP_RedDotFactory_Mail, CommonRedDot, {RedDotKey = "Mail", RedDotSuffix = ""}).ViewInstance
	self.WBP_RedDotFactory_Broadcast:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	self.BroadcastRedDot = UIHandler.New(self, self.WBP_RedDotFactory_Broadcast, CommonRedDot, {RedDotKey = "Broadcast", RedDotSuffix = ""}).ViewInstance
	self.WBP_RedDotFactory_More:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
	self.MenuRedDot = UIHandler.New(self, self.WBP_RedDotFactory_More, CommonRedDot, {RedDotKey = "SidebarDirectory", RedDotSuffix = ""}).ViewInstance
end

function M:OnCheckSmallWidgetShow(TabKey,IsInit)
	if not CommonUtil.IsValid(self.LeftUpUI) then
		return
	end
	local Show = self.ShowSmallWidgetConfig[TabKey]
	self.LeftUpUI:SetVisibility(Show == true and UE4.ESlateVisibility.SelfHitTestInvisible or UE4.ESlateVisibility.Collapsed)

	local ViewParam = {
        ViewId = ViewConst.Hall,
        TabId = TabKey,
		Name = EventTrackingModel.ONCLICKED_HALLTAB_NAME[TabKey]
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
	MvcEntry:SendMessage(CommonEvent.HAll_PANELTAB_CLICK,TabKey)
end

-- function M:OnShowTabHallTabView(InParam)
-- 	if InParam then
-- 		---打开对应的页签时 是否屏蔽 LeftUpUI 节点
-- 		if self.LeftUpUI then
-- 			local Visibility = InParam.bHideTabOnShow and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible
-- 			self.LeftUpUI:SetVisibility(Visibility)
-- 		end
-- 	end
-- end

--[[
	InData
	{
		NeedWaitEnterLS	 = false
		IsInGameFinished = false --是否是从局内返回的
	}
]]
function M:OnShow(InData)
	-- Tab页内有参数需要从外部传入的，用此参数设置
	local TabInitParam = {
		[CommonConst.HL_PLAY] = InData
	}
	if self.CommonHallTab then
		self.CommonHallTab:InitShow(TabInitParam)
	end
	
	-- 从战斗中返回，需要播放TeamAndChat的入场动效
	local TeaAndChatData = {}
	if InData.IsInGameFinished then
		self:OnInGameFinished()
		TeaAndChatData.NeedPlayDisplayAnim = true
	end
	self:UpdateFriendCount()
	self:UpdateSeasonName()
	self:UpdateSeasonBPLevel()
	-- 打开组队侧边和聊天界面
	MvcEntry:OpenView(ViewConst.TeamAndChat, TeaAndChatData)

	self:PlayDynamicEffectOnShow(true)
	MvcEntry:GetModel(FriendModel):CheckApplyTips()
end
function M:OnHide()
	--MvcEntry:CloseView(ViewConst.TeamAndChat)
	MvcEntry:GetModel(TeamModel):DispatchType(TeamModel.ON_CLOSE_TEAM_AND_CHAT_VIEW_BY_ACTION)
end

-- 更新赛季名称
function M:UpdateSeasonName()
	self.Text_SeasonName:SetText(MvcEntry:GetModel(SeasonModel):GetCurrentSeasonName())
end

-- 更新赛季通行证奖励
function M:UpdateSeasonBPLevel()
	local PassStatus = MvcEntry:GetModel(SeasonBpModel):GetPassStatus()
    if PassStatus then
		self.Text_SeasonBPLevel:SetText(tostring(PassStatus.Level))
	else
		self.Text_SeasonBPLevel:SetText(0)
    end
end
-- -- IsNotVirtualTrigger 第一次调用为true
-- function M:OnShowAvator(Param,IsNotVirtualTrigger)
-- 	if self.CommonHallTab then
-- 		self.CommonHallTab:OnShowAvator(Param,IsNotVirtualTrigger)
-- 	end
-- end

-- function M:OnHideAvator(Param,IsNotVirtualTrigger)
-- 	if self.CommonHallTab then
-- 		self.CommonHallTab:OnHideAvator(Param,IsNotVirtualTrigger)
-- 	end
-- end

function M:GetIsShowSidebar()
	if self.CommonHallTab then
		return self.CommonHallTab:GetIsShowSidebar()
	end
end

--[[
	VirtualHallMdt 播放LS控制UI显隐
]]
function M:On_TRIGGER_HALL_PANEL_CONTENT_SHOW_STATE_Func(IsVisible)
	-- 这里IsVisible为false时，直接隐藏不播动效
	self:SetAllUIVisibility(IsVisible,IsVisible)
end

--恢复等待匹配状态
function M:ON_MATCH_IDLE_Func()
	CLog("HallMdt ON_MATCH_IDLE_Func self.IsMatchSuccess =" .. tostring(self.IsMatchSuccess))
	if self.IsMatchSuccess then
		self:SetAllUIVisibility(true,true)
		self:PlayDynamicEffectOnShow(true)
		self.IsMatchSuccess = false
	end
end

---进入DS失败
function M:ON_DS_ERROR_Func()
	self:SetAllUIVisibility(true,true)
	self:PlayDynamicEffectOnShow(true)
end
--[[
	匹配成功
]]
function M:ON_GAMEMATCH_SUCCECS_Func()
	self:PlayDynamicEffectOnShow(false)
	self.IsMatchSuccess = true
	self:SetAllUIVisibility(false,true)
	-- if UE.UGameplayStatics.GetPlatformName() == "Windows" then
	-- 	MvcEntry:CloseView(ViewConst.Setting)
	-- else
	-- 	MvcEntry:CloseView(ViewConst.SettingMobile)
	-- end
	if  BridgeHelper.IsPCPlatform() then
        MvcEntry:CloseView(ViewConst.Setting)
    else
        MvcEntry:CloseView(ViewConst.SettingMobile)
   end

end


--[[
	局内返回
]]
function M:OnInGameFinished()
	self:SetAllUIVisibility(true,true)
end

function M:OnAfterBackToHall(Param)
	CWaring("HallMdt OnAfterBackToHall")
	if Param and Param.TravelFailedResult then
		CWaring("HallMdt OnAfterBackToHall Because Travel Failed, Result = "..Param.TravelFailedResult)
		if Param.TravelFailedResult == GameStageCtrl.TRAVEL_FAILED_ENUM.BEFORE_PRELOADMAP then
			-- 进战斗Travel失败了直接返回，要将大厅UI显示回来
			self:SetAllUIVisibility(true,false)
			self:PlayDynamicEffectOnShow(true)
		end
	end
end

-- 播放UI动效
function M:SetAllUIVisibility(IsVisible,IsPlayAni)
	if not CommonUtil.IsValid(self) then
		CError("HallMdt SetAllUIVisibility self is nil", true)
		return
	end
	if false then
	-- if IsPlayAni then
		-- if not CommonUtil.IsValid(self.vx_hall_in) then
		-- 	ReportError("SetAllUIVisibility vx_hall_in not valid",true)
		-- 	return
		-- end
		-- if not CommonUtil.IsValid(self.vx_hall_match_success) then
		-- 	ReportError("SetAllUIVisibility vx_hall_match_success not valid",true)
		-- 	return
		-- end
		-- self:StopAllAnimations()
		-- local Animation = IsVisible and self.vx_hall_in or self.vx_hall_match_success
		-- self:PlayAnimation(Animation)	
	else
		self:SetAllUIVisibilityCB(IsVisible)
	end
end

function M:SetAllUIVisibilityCB(IsVisible)
	local Visibility = IsVisible and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed
	-- self.BgPanel:SetVisibility(Visibility)
	-- self.WBP_HallCommonTab:SetVisibility(Visibility)	
	-- if self:IsAnimationPlaying(self.vx_hall_in)  then
	-- 	self:StopAnimation(self.vx_hall_in)
	-- 	-- Animation中有对Visibility的设置，Stop之后，立刻设置会失效，延迟一帧设置
	-- 	self:InsertTimer(-1,function ()
	-- 		self.Root:SetVisibility(Visibility)
	-- 	end)
	-- else
	-- 	self.Root:SetVisibility(Visibility)	
	-- end
		self.Root:SetVisibility(Visibility)	
end

-- 更新好友管理入口 好友数量显示
function M:UpdateFriendCount()
	local FriendCount = MvcEntry:GetModel(FriendModel):GetAllFriendNum()	
	if FriendCount > 0 then
		self.Text_FriendCount:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
		self.Text_FriendCount:SetText(FriendCount)
	else
		self.Text_FriendCount:SetVisibility(UE.ESlateVisibility.Collapsed)
	end
end

-- 从战斗中返回，异步加载完成，Loading移除
function M:OnAsyncLoadingScreenLoadingFinished()
	print("== OnAsyncLoadingScreenLoadingFinished")
	-- 检查是否有缓存的新增申请需要展示
	MvcEntry:GetModel(FriendModel):CheckApplyTips()
end

--点击设置
function M:OnCliked_BtnSetting()
	local FastLoad = require("Client.Modules.DeveloperTools.FastLoad")
	if UE.UGFUnluaHelper.IsEditor() and FastLoad.CustomFunc then
		FastLoad.CustomFunc()
		return
	end
	
	-- local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
	-- local TeamMemPlayerId = self.SelfId
	-- local HeroAvatar = HallAvatarMgr:GetHallAvatar(TeamMemPlayerId)
	-- local DissolveInfo = {
	-- 	MemberId = TeamMemPlayerId,
	-- 	HeroActor = HeroAvatar,
	-- 	Pos = 1,
	-- }
	-- self:PlayExitDissolveLS(DissolveInfo,function ()
	-- 	-- RemoveInnerFunc()
	-- end)
	-- MvcEntry:OpenView(ViewConst.Setting)
	 
	if GVoiceModel.TestOpen then
		MvcEntry:OpenView(ViewConst.TeamVoiceDemo)
	else
		-- MvcEntry:OpenView(ViewConst.MainMenu)
		MvcEntry:OpenView(ViewConst.SystemMenu)
	end
end

--点击邮件
function M:OnCliked_BtnMail()
	local ViewParam = {
        ViewId = ViewConst.MailMain,
		Name = "邮件"
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
	MvcEntry:OpenView(ViewConst.MailMain)
end

--点击更多
function M:OnCliked_BtnMore()
	local ViewParam = {
        ViewId = ViewConst.HallMenuEntry,
		Name = "更多"
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
	MvcEntry:OpenView(ViewConst.HallMenuEntry)
end

-- 点击喇叭
function M:OnCliked_BtnBroadcast()
	local ViewParam = {
        ViewId = ViewConst.Notice,
		Name = "公告"
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
	MvcEntry:OpenView(ViewConst.Notice)
end

-- 点击好友管理
function M:OnCliked_BtnFriendManager()
	local ViewParam = {
        ViewId = ViewConst.FriendManagerMain,
		Name = "好友管理"
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
	MvcEntry:OpenView(ViewConst.FriendManagerMain)
end

-- 点击仓库
function M:OnCliked_Depot()
	local ViewParam = {
        ViewId = ViewConst.DepotMain,
		Name = "仓库"
    }
	MvcEntry:GetModel(EventTrackingModel):DispatchType(EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID, ViewParam)
	MvcEntry:OpenView(ViewConst.DepotMain)
end

--[[
    播放显示退出动效
]]
function M:PlayDynamicEffectOnShow(InIsOnShow)
    if InIsOnShow then
        if self.VXE_HalllMain_Tab_In then
            self:VXE_HalllMain_Tab_In()
        end
    else
        if self.VXE_HalllMain_Tab_Out then
            self:VXE_HalllMain_Tab_Out()
        end
    end
end

return M
