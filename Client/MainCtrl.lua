--Base
require("Common.Utils.PoolManager")
require("Core.Mvc.ModuleListRegister")
require("Core.Misc.ListModel")
require("Core.Misc.MapModel")
require("Common.Events.CommonEvent")
require("Common.Mvc.UserGameController")

--NetDeclare
require("Client.Net.Protocols.PbDeclare")

--UI
require("Client.Common.UIConst")
require("Client.Common.UIRoot")
require("Client.Mvc.GameMediator")
require("Client.Mvc.UserWidgetBase")
require("Client.Mvc.UIHandlerViewBase")
require("Client.Views.ViewRegister")
require("Client.Views.ViewController")


--Sound
require ("Client.Sound.SoundMgr")

--Net
require("Client.Net.ProtoCtrl")

--Module
require("Client.Modules.GameStage.GameStageCtrl")
require("Client.Modules.Common.CommonCtrl")
require("Client.Modules.Login.LoginCtrl")
require("Client.Modules.Login.LoginStepCtrl")
require("Client.Modules.User.UserSocketLoginCtrl")
require("Client.Modules.User.UserCtrl")
require("Client.Modules.User.PlayerStateQueryCtrl")
require("Client.Modules.Input.InputCtrl")
require("Client.Modules.Depot.DepotCtrl")
require("Client.Modules.Team.TeamCtrl")
require("Client.Modules.Error.ErrorCtrl")
require("Client.Modules.Friend.FriendCtrl")
require("Client.Modules.Sequence.SequenceCtrl")
require("Client.Modules.Hero.HeroCtrl")
require("Client.Modules.Arsenal.ArsenalCtrl")
require("Client.Modules.Mail.MailCtrl")
require("Client.Modules.Chat.ChatCtrl")
require("Client.Modules.Season.SeasonCtrl")
require("Client.Modules.Season.Pass.SeasonBpCtrl")
require("Client.Modules.Match.MatchCtrl")
require("Client.Modules.Match.MatchSever.MatchSeverCtrl")
require("Client.Modules.Match.MatchEntrance.HallMatchEntranceCtrl")
require("Client.Modules.Match.MatchModeSelect.MatchModeSelectCtrl")
require("Client.Modules.CustomRoom.CustomRoomCtrl")
require("Client.Modules.CustomRoom.CustomRoomList.CustomRoomListCtrl")
require("Client.Modules.CustomRoom.CustomRoomDetail.CustomRoomDetailCtrl")
require("Client.Modules.Setting.SettingCtrl")
require("Client.Modules.GMPanel.GMPanelCtrl")
require("Client.Modules.ItemGet.ItemGetCtrl")
require("Client.Modules.HallSettlement.HallSettlementCtrl")
require("Client.Modules.InGameSettlement.InGameSettlementCtrl")
-- require("Client.Modules.SDK.GSDK.GSDKCtrl")
require("Client.Modules.SDK.PerfSight.PerfSightSDKCtrl")
require("Client.Modules.SDK.ACE.ACESDKCtrl")
require("Client.Modules.SDK.MSDK.MSDKCtrl")
require("Client.Modules.SDK.TDAnalytics.TDAnalyticsCtrl")
require("Client.Modules.SDK.Steam.SteamSDKCtrl")
require("Client.Modules.SDK.AppsflyerSteam.AppsflyerSteamCtrl")
require("Client.Modules.SDK.OnlineSub.OnlineSubCtrl")
require("Client.Modules.SDK.BianQue.BianQueCtrl")
require("Client.Modules.Localization.LocalizationCtrl")

require("Client.Modules.AsyncLoadAsset.AsyncLoadAssetCtrl")

-- require("UEConnect.Client.GameFlow.CameraMouseFollowCtrl")

require("Client.Modules.Shop.ShopCtrl")
require("Client.Modules.EndinCG.EndinCGCtrl")

require("Client.Modules.Narrative.NarrativeCtrl")

require("Client.Modules.PlayerInfo.PlayerInfoCtrl")
require("Client.Modules.PlayerInfo.MatchHistory.PlayerInfo_MatchHistoryCtrl")
require("Client.Modules.Notice.NoticeCtrl")
require("Client.Modules.Notice.PreLoginNoticeCtrl")
require("Client.Modules.System.NewSystemUnlockCtrl")
require("Client.Modules.PlayerInfo.PersonalInfo.PersonalInfoCtrl")

require("Client.Modules.RankSystem.RankSystemCtrl")

require("Client.Modules.Guide.GuideCtrl");
require("Client.Modules.System.ViewJumpCtrl")
require("Client.Modules.Report.ReportCtrl")
require("Client.Modules.Loading.LoadingCtrl")
require("Client.Modules.Setting.SystemMenuCtrl")
require("Client.Modules.RedDot.RedDotCtrl")

require("Client.Modules.PreLoad.PreLoadCtrl")

require("Client.Modules.Achievement.AchievementCtrl")
require("Client.Modules.Favorability.FavorabilityCtrl")
require("Client.Modules.Dialog.DialogSystemCtrl")
require("Client.Modules.Task.TaskCtrl")
require("Client.Modules.Http.HttpCtrl")
require("Client.Modules.SDK.GVoice.GVoiceCtrl")
require("Client.Modules.PlayerInfo.PersonalStatistics.PersonalStatisticsCtrl")

require("Client.Modules.Activity.ActivityCtrl")

require("Client.Modules.Season.Rank.SeasonRankCtrl")
require("Client.Modules.Recommend.RecommendCtrl")
require("Client.Modules.Questionnaire.QuestionnaireCtrl")
require("Client.Modules.Ban.BanCtrl")
require("Client.Modules.PlayerInfo.PlayerLevel.PlayerLevelGrowthCtrl")

require("Client.Modules.EventTracking.EventTrackingCtrl")
require("Client.Modules.PlayerInfo.PlayerBaseInfoSyncCtrl")
require("Client.Modules.PlayerStat.PlayerStatCtrl")
require("Client.Modules.NetProtoLog.NetProtoLogCtrl")

local class_name = "MainCtrl";
local super = ModuleListRegister;
--[[主控制注册器]]
---@class MainCtrl : ModuleListRegister
MainCtrl = MainCtrl or BaseClass(super, class_name)

function MainCtrl:__init()
	-- --主控制器或小模块控制器注册
	self:RegisterModule(ProtoCtrl)		--协议管理器
	self:RegisterModule(ViewRegister)	--View Mediator注册器
	self:RegisterModule(ViewController)	--View 打开管理器
	self:RegisterModule(GameStageCtrl)
	self:RegisterModule(CommonCtrl)		--公用控制器

	self:RegisterModule(LoginCtrl)
	self:RegisterModule(UserSocketLoginCtrl)		--玩家登录管理器
	self:RegisterModule(LoginStepCtrl)
	self:RegisterModule(UserCtrl)
	self:RegisterModule(InputCtrl)
	self:RegisterModule(DepotCtrl)
	self:RegisterModule(TeamCtrl)
	self:RegisterModule(ErrorCtrl)
	self:RegisterModule(FriendCtrl)
	self:RegisterModule(SequenceCtrl)
	self:RegisterModule(HeroCtrl)
	self:RegisterModule(ArsenalCtrl)
	self:RegisterModule(MailCtrl)
	self:RegisterModule(SettingCtrl)
	-- self:RegisterModule(CameraMouseFollowCtrl)
	self:RegisterModule(GMPanelCtrl)
	self:RegisterModule(ItemGetCtrl)
	self:RegisterModule(HallSettlementCtrl)
	-- self:RegisterModule(GSDKCtrl)
	self:RegisterModule(OnlineSubCtrl)
	self:RegisterModule(PerfSightSDKCtrl)
	self:RegisterModule(ACESDKCtrl)
	self:RegisterModule(MSDKCtrl)
	self:RegisterModule(TDAnalyticsCtrl)
	self:RegisterModule(SteamSDKCtrl)
	self:RegisterModule(AppsflyerSteamCtrl)
	self:RegisterModule(ChatCtrl)
	self:RegisterModule(SeasonCtrl)
	self:RegisterModule(SeasonBpCtrl)
	self:RegisterModule(MatchCtrl)
	self:RegisterModule(MatchSeverCtrl)
	self:RegisterModule(HallMatchEntranceCtrl)
	self:RegisterModule(MatchModeSelectCtrl)	
	self:RegisterModule(CustomRoomCtrl)	
	self:RegisterModule(CustomRoomListCtrl)
	self:RegisterModule(CustomRoomDetailCtrl)
	self:RegisterModule(LocalizationCtrl)	
	self:RegisterModule(AsyncLoadAssetCtrl)	
	self:RegisterModule(ShopCtrl)	
	self:RegisterModule(NarrativeCtrl)	
	self:RegisterModule(NoticeCtrl)
	self:RegisterModule(PreLoginNoticeCtrl)
	self:RegisterModule(InGameSettlementCtrl)
	self:RegisterModule(PlayerInfoCtrl)
	self:RegisterModule(PlayerInfo_MatchHistoryCtrl)
	self:RegisterModule(NewSystemUnlockCtrl)
	self:RegisterModule(PersonalInfoCtrl)
	self:RegisterModule(RankSystemCtrl)
	self:RegisterModule(GuideCtrl)
	self:RegisterModule(PlayerStateQueryCtrl)
	self:RegisterModule(ViewJumpCtrl)
	self:RegisterModule(ReportCtrl)
	self:RegisterModule(LoadingCtrl)
	self:RegisterModule(SystemMenuCtrl)
	self:RegisterModule(RedDotCtrl)
	self:RegisterModule(PreLoadCtrl)
	self:RegisterModule(AchievementCtrl)
	self:RegisterModule(FavorabilityCtrl)
	self:RegisterModule(DialogSystemCtrl)
	self:RegisterModule(TaskCtrl)
	self:RegisterModule(HttpCtrl)
	self:RegisterModule(GVoiceCtrl)
	self:RegisterModule(PersonalStatisticsCtrl)
	self:RegisterModule(ActivityCtrl)
	self:RegisterModule(SeasonRankCtrl)
	self:RegisterModule(RecommendCtrl)
	self:RegisterModule(QuestionnaireCtrl)
	self:RegisterModule(BanCtrl)
	self:RegisterModule(PlayerLevelGrowthCtrl)

	self:RegisterModule(EventTrackingCtrl)
	self:RegisterModule(BianQueCtrl)
	self:RegisterModule(PlayerBaseInfoSyncCtrl)
	self:RegisterModule(PlayerStatCtrl)
	self:RegisterModule(NetProtoLogCtrl)
end

function MainCtrl:__dispose()
	PoolManager.Clear()
end

function MainCtrl:Initialize()
	super.Initialize(self)

	self:AddMsgListener(CommonEvent.ON_MAIN_LOGOUT, self.OnLogoutHandler, self);
    self:AddMsgListener(CommonEvent.ON_LOGIN_INFO_SYNCED, self.OnLoginHandler, self);
	self:AddMsgListener(CommonEvent.ON_RECONNECT_LOGOUT,       self.OnReconnectLogoutHandler,    self)

	self:AddMsgListener(CommonEvent.ON_GAME_INIT,       self.ON_GAME_INIT,    self)
	self:AddMsgListener(CommonEvent.ON_CULTURE_INIT,       self.OnCultureInitHandler,    self)

	-- self:AddMsgListener(CommonEvent.ON_COMMON_DAYREFRESH, self.OnDayRefreshHandler, self);

	-- if not CommonUtil.IsDedicatedServer() then
    --     --TODO 只针对非DS环境的逻辑 ，避免 非DS的 相关类找不到
    --     ---@type ViewModel
    --     local ViewModel = self:GetModel(ViewModel)
    --     ViewModel:AddListener(ViewConst.VirtualHall, self.OnVirtualHallState,  self)
    --     ViewModel:AddListener(ViewConst.LevelBattle, self.OnLevelBattleState, self)
    -- end
end

function MainCtrl:InitializeGame()
	self:SendMessage(CommonEvent.ON_GAME_INIT_BEFORE)
	self:SendMessage(CommonEvent.ON_GAME_INIT)
end


function MainCtrl:OnQuit(is_press)
    self:RemoveMsgListener(CommonEvent.ON_MAIN_LOGOUT, self.OnLogoutHandler, self);
    self:RemoveMsgListener(CommonEvent.ON_LOGIN_INFO_SYNCED, self.OnLoginHandler, self);
	self:RemoveMsgListener(CommonEvent.ON_RECONNECT_LOGOUT,       self.OnReconnectLogoutHandler,    self)
	self:RemoveMsgListener(CommonEvent.ON_GAME_INIT,       self.ON_GAME_INIT,    self)
	self:RemoveMsgListener(CommonEvent.ON_CULTURE_INIT,       self.OnCultureInitHandler,    self)

	-- self:RemoveMsgListener(CommonEvent.ON_COMMON_DAYREFRESH, self.OnDayRefreshHandler, self);

	-- if not CommonUtil.IsDedicatedServer() then
    --     ---@type ViewModel
    --     local ViewModel = self:GetModel(ViewModel)
    --     ViewModel:RemoveMsgListener(ViewConst.VirtualHall, self.OnVirtualHallState,  self)
    --     ViewModel:RemoveMsgListener(ViewConst.LevelBattle, self.OnLevelBattleState, self)
    -- end
end

-- function MainCtrl:OnLevelBattleState(State)
--     if State then
--         ---@type ViewModel
--         local ViewModel = self:GetModel(ViewModel)
--         if ViewModel.last_LEVEL_Fix == ViewConst.VirtualHall then
--             self:SendMessage(CommonEvent.ON_PRE_ENTER_BATTLE)
--         end
--     end
-- end

-- function MainCtrl:OnVirtualHallState(State)
--     if State then
--         ---@type ViewModel
--         local ViewModel = self:GetModel(ViewModel)
--         if ViewModel.last_LEVEL_Fix == ViewConst.LevelBattle then
-- 			self:SendMessage(CommonEvent.ON_PRE_BACK_TO_HALL)
--         end
--     end
-- end


function MainCtrl:ON_GAME_INIT(data)
	if GameEventDispatcher.dispatchers then
        for k,v in pairs(GameEventDispatcher.dispatchers) do
            v:OnGameInit(data)
        end
    end
end

function MainCtrl:OnCultureInitHandler(data)
	if GameEventDispatcher.dispatchers then
        for k,v in pairs(GameEventDispatcher.dispatchers) do
            v:OnCultureInit(data)
        end
    end
end

--[[
	给所有Model派发玩家【登录】事件
]]
function MainCtrl:OnLoginHandler(data)
	if GameEventDispatcher.dispatchers then
        for k,v in pairs(GameEventDispatcher.dispatchers) do
            v:OnLogin(data)
        end
    end
end

--[[
	给所有Model派发玩家【登出】事件
]]
function MainCtrl:OnLogoutHandler(data)
	if GameEventDispatcher.dispatchers then
        for k,v in pairs(GameEventDispatcher.dispatchers) do
            v:OnLogout(data)
        end
    end
end

function MainCtrl:OnReconnectLogoutHandler(data)
	if GameEventDispatcher.dispatchers then
        for k,v in pairs(GameEventDispatcher.dispatchers) do
            v:OnLogoutReconnect(data)
        end
    end
end


-- function MainCtrl:OnDayRefreshHandler()
-- 	if GameEventDispatcher.dispatchers then
--         for k,v in pairs(GameEventDispatcher.dispatchers) do
--             v:OnDayRefresh()
--         end
--     end
-- end



