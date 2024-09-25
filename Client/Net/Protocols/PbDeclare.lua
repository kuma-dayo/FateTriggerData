Pb_ProtoList = 
{
	["Achievement.proto"] = {PrePath="Client/Net/Protocols/",},
	["Activity.proto"] = {PrePath="Client/Net/Protocols/",ImportPbList={"Item.proto"}},
	["Ban.proto"] = {PrePath="Client/Net/Protocols/",},
	["Battle.proto"] = {PrePath="Client/Net/Protocols/",},
	["Chat.proto"] = {PrePath="Client/Net/Protocols/",},
	["Common.proto"] = {PrePath="Client/Net/Protocols/",},
	["CustomLayout.proto"] = {PrePath="Client/Net/Protocols/",},
	["Datapack.proto"] = {PrePath="Client/Net/Protocols/",},
	["DisplayBoard.proto"] = {PrePath="Client/Net/Protocols/",},
	["Division.proto"] = {PrePath="Client/Net/Protocols/",},
	["DsGroups.proto"] = {PrePath="Client/Net/Protocols/",},
	["Favor.proto"] = {PrePath="Client/Net/Protocols/",ImportPbList={"Item.proto"}},
	["Friend.proto"] = {PrePath="Client/Net/Protocols/",ImportPbList={"Lobby.proto"}},
	["Gateway.proto"] = {PrePath="Client/Net/Protocols/",ImportPbList={"Common.proto"}},
	["GM.proto"] = {PrePath="Client/Net/Protocols/",},
	["Head.proto"] = {PrePath="Client/Net/Protocols/",},
	["Hero.proto"] = {PrePath="Client/Net/Protocols/",},
	["HeroPerf.proto"] = {PrePath="Client/Net/Protocols/",},
	["Item.proto"] = {PrePath="Client/Net/Protocols/",},
	["Lobby.proto"] = {PrePath="Client/Net/Protocols/",ImportPbList={"Achievement.proto","Vehicle.proto"}},
	["Lottery.proto"] = {PrePath="Client/Net/Protocols/",ImportPbList={"Item.proto"}},
	["Mail.proto"] = {PrePath="Client/Net/Protocols/",},
	["Match.proto"] = {PrePath="Client/Net/Protocols/",},
	["Misc.proto"] = {PrePath="Client/Net/Protocols/",ImportPbList={"Head.proto","Weapon.proto","DisplayBoard.proto","Achievement.proto"}},
	["Netlog.proto"] = {PrePath="Client/Net/Protocols/",},
	["NewbieGuide.proto"] = {PrePath="Client/Net/Protocols/",},
	["Questionnaire.proto"] = {PrePath="Client/Net/Protocols/",},
	["Recharge.proto"] = {PrePath="Client/Net/Protocols/",},
	["RedDot.proto"] = {PrePath="Client/Net/Protocols/",},
	["Room.proto"] = {PrePath="Client/Net/Protocols/",},
	["Rtc.proto"] = {PrePath="Client/Net/Protocols/",},
	["Season.proto"] = {PrePath="Client/Net/Protocols/",},
	["SeasonBattlePass.proto"] = {PrePath="Client/Net/Protocols/",},
	["Settlement.proto"] = {PrePath="Client/Net/Protocols/",ImportPbList={"Battle.proto"}},
	["Shop.proto"] = {PrePath="Client/Net/Protocols/",},
	["Stat.proto"] = {PrePath="Client/Net/Protocols/",ImportPbList={"Achievement.proto","Vehicle.proto"}},
	["Task.proto"] = {PrePath="Client/Net/Protocols/",},
	["Team.proto"] = {PrePath="Client/Net/Protocols/",ImportPbList={"Lobby.proto"}},
	["UnLock.proto"] = {PrePath="Client/Net/Protocols/",},
	["Vehicle.proto"] = {PrePath="Client/Net/Protocols/",},
	["Weapon.proto"] = {PrePath="Client/Net/Protocols/",},
}

Pb_Message = 
{
	--Achievement.proto
	AchievementSlotInfoBase = "AchievementSlotInfoBase",
	GetAchievementInfoReq = "GetAchievementInfoReq",
	AchievementInfoNode = "AchievementInfoNode",
	GetAchievementInfoRsp = "GetAchievementInfoRsp",
	SetAchievementSlotReq = "SetAchievementSlotReq",
	SetAchievementSlotRsp = "SetAchievementSlotRsp",
	RemoveAchievementSlotReq = "RemoveAchievementSlotReq",
	RemoveAchievementSlotRsp = "RemoveAchievementSlotRsp",
	AchievementInfoUpdateNotify = "AchievementInfoUpdateNotify",

	--Activity.proto
	NoticeInfoBase = "NoticeInfoBase",
	NoticeListSync = "NoticeListSync",
	ActivityCfgNode = "ActivityCfgNode",
	OpenActivityListSync = "OpenActivityListSync",
	CloseActivityListSync = "CloseActivityListSync",
	ActivitySubItemCfgNode = "ActivitySubItemCfgNode",
	ActivityGetSubItemCfgReq = "ActivityGetSubItemCfgReq",
	ActivityGetSubItemCfgRsp = "ActivityGetSubItemCfgRsp",
	ActivityGetBannerCfgReq = "ActivityGetBannerCfgReq",
	ActivityBannerCfgNode = "ActivityBannerCfgNode",
	ActivityGetBannerCfgRsp = "ActivityGetBannerCfgRsp",
	ActivityGetPrizeReq = "ActivityGetPrizeReq",
	ActivityGetPrizeRsp = "ActivityGetPrizeRsp",
	PlayerGetActivityDataReq = "PlayerGetActivityDataReq",
	SubItemNode = "SubItemNode",
	PlayerGetActivityDataRsp = "PlayerGetActivityDataRsp",
	PlayerSetActivitySubItemPrizeStateReq = "PlayerSetActivitySubItemPrizeStateReq",
	PlayerSetActivitySubItemPrizeStateRsp = "PlayerSetActivitySubItemPrizeStateRsp",

	--Ban.proto
	BanData = "BanData",
	BanDataSync = "BanDataSync",

	--Battle.proto
	SeasonWeaponDataReq = "SeasonWeaponDataReq",
	SeasonWeaponDataRsp = "SeasonWeaponDataRsp",
	CareerWeaponDataReq = "CareerWeaponDataReq",
	CareerWeaponDataRsp = "CareerWeaponDataRsp",
	SeasonHeroDataReq = "SeasonHeroDataReq",
	SkillDataBase = "SkillDataBase",
	SeasonHeroDataRsp = "SeasonHeroDataRsp",
	CareerHeroDataReq = "CareerHeroDataReq",
	CareerHeroDataRsp = "CareerHeroDataRsp",
	VehicleDataReq = "VehicleDataReq",
	VehicleDataRsp = "VehicleDataRsp",
	CareerVehicleDataReq = "CareerVehicleDataReq",
	CareerVehicleDataRsp = "CareerVehicleDataRsp",
	SeasonBattleDataReq = "SeasonBattleDataReq",
	DivisionInfoBase = "DivisionInfoBase",
	MaxValBase = "MaxValBase",
	SeasonBattleDataRsp = "SeasonBattleDataRsp",
	StatisticsReq = "StatisticsReq",
	StatisticsBase = "StatisticsBase",
	StatisticsRsp = "StatisticsRsp",
	GamePlayerSettlementSync = "GamePlayerSettlementSync",
	SettlementRewardItem = "SettlementRewardItem",
	GameTeamSettlementSync = "GameTeamSettlementSync",
	GameBattleSettlementSync = "GameBattleSettlementSync",
	GameCampPlayerSettlementBase = "GameCampPlayerSettlementBase",
	GameCampSettlementSync = "GameCampSettlementSync",
	RecordsReq = "RecordsReq",
	GameplayCfgBase = "GameplayCfgBase",
	RecordGeneralData = "RecordGeneralData",
	RecordBase = "RecordBase",
	RecordsRsp = "RecordsRsp",
	DetailRecordReq = "DetailRecordReq",
	BrDetailRecordBase = "BrDetailRecordBase",
	CampDetailRecordBase = "CampDetailRecordBase",
	DetailRecordBase = "DetailRecordBase",
	DetailRecordRsp = "DetailRecordRsp",
	SingleRecordReq = "SingleRecordReq",
	SingleRecordRsp = "SingleRecordRsp",
	SettingBase = "SettingBase",
	SaveSettingsReq = "SaveSettingsReq",
	SaveSettinsRsp = "SaveSettinsRsp",
	GetSettingsReq = "GetSettingsReq",
	GetSettingsRsp = "GetSettingsRsp",
	SetLobbyStatusReq = "SetLobbyStatusReq",

	--Chat.proto
	ChatMsgType = "ChatMsgType",
	ChatReq = "ChatReq",
	ChatRsp = "ChatRsp",
	ChatSync = "ChatSync",
	ChatMergeSync = "ChatMergeSync",
	ChatPrivateOffMsgSync = "ChatPrivateOffMsgSync",
	ChatTipsSync = "ChatTipsSync",
	ClearPlayerChatSync = "ClearPlayerChatSync",
	ClientChgLangTypReq = "ClientChgLangTypReq",
	ClientChgLangTypRsp = "ClientChgLangTypRsp",

	--Common.proto
	ClientInfo = "ClientInfo",
	AccountInfo = "AccountInfo",
	DeviceInfo = "DeviceInfo",
	LocationInfo = "LocationInfo",

	--CustomLayout.proto
	LayoutBase = "LayoutBase",
	SaveLayoutBase = "SaveLayoutBase",
	SaveCustomLayoutReq = "SaveCustomLayoutReq",
	SaveCustomLayoutRsp = "SaveCustomLayoutRsp",
	GetCustomLayoutReq = "GetCustomLayoutReq",
	LayoutGroupBase = "LayoutGroupBase",
	GetCustomLayoutRsp = "GetCustomLayoutRsp",

	--Datapack.proto
	MsgHeadNormal = "MsgHeadNormal",
	HandshakeReq = "HandshakeReq",
	HandshakeRsp = "HandshakeRsp",

	--DisplayBoard.proto
	PlayerDisplayBoardDataReq = "PlayerDisplayBoardDataReq",
	LbStickerNode = "LbStickerNode",
	LbDisplayBoardInfo = "LbDisplayBoardInfo",
	PlayerDisplayBoardDataRsp = "PlayerDisplayBoardDataRsp",
	PlayerBuyFloorReq = "PlayerBuyFloorReq",
	PlayerBuyFloorRsp = "PlayerBuyFloorRsp",
	PlayerSelectFloorReq = "PlayerSelectFloorReq",
	PlayerSelectFloorRsp = "PlayerSelectFloorRsp",
	PlayerBuyRoleReq = "PlayerBuyRoleReq",
	PlayerBuyRoleRsp = "PlayerBuyRoleRsp",
	PlayerSelectRoleReq = "PlayerSelectRoleReq",
	PlayerSelectRoleRsp = "PlayerSelectRoleRsp",
	PlayerBuyEffectReq = "PlayerBuyEffectReq",
	PlayerBuyEffectRsp = "PlayerBuyEffectRsp",
	PlayerSelectEffectReq = "PlayerSelectEffectReq",
	PlayerSelectEffectRsp = "PlayerSelectEffectRsp",
	PlayerBuyStickerReq = "PlayerBuyStickerReq",
	PlayerBuyStickerRsp = "PlayerBuyStickerRsp",
	PlayerEquipStickerReq = "PlayerEquipStickerReq",
	PlayerEquipStickerRsp = "PlayerEquipStickerRsp",
	PlayerUnEquipStickerReq = "PlayerUnEquipStickerReq",
	PlayerUnEquipStickerRsp = "PlayerUnEquipStickerRsp",
	PlayerEquipAchieveReq = "PlayerEquipAchieveReq",
	PlayerEquipAchieveRsp = "PlayerEquipAchieveRsp",
	PlayerUnEquipAchieveReq = "PlayerUnEquipAchieveReq",
	PlayerUnEquipAchieveRsp = "PlayerUnEquipAchieveRsp",

	--Division.proto
	DivisionQueryParam = "DivisionQueryParam",
	DivisionRewardIdAndStatus = "DivisionRewardIdAndStatus",
	DivisionDistributionInfoReq = "DivisionDistributionInfoReq",
	DivisionDistributionInfoRes = "DivisionDistributionInfoRes",
	PersonalDivisionInfoReq = "PersonalDivisionInfoReq",
	PersonalDivisionInfoRes = "PersonalDivisionInfoRes",
	PersonalDivisionRankInfoReq = "PersonalDivisionRankInfoReq",
	PersonalDivisionRankInfoRes = "PersonalDivisionRankInfoRes",
	DivisionRewardReq = "DivisionRewardReq",
	DivisionRewardRes = "DivisionRewardRes",

	--DsGroups.proto
	DsGroupDetail = "DsGroupDetail",
	PullDsGroupsReq = "PullDsGroupsReq",
	PullDsGroupsRsp = "PullDsGroupsRsp",
	ReportDsGroupPingReq = "ReportDsGroupPingReq",
	ReportDsGroupPingRsp = "ReportDsGroupPingRsp",
	ReportDsGroupIdReq = "ReportDsGroupIdReq",
	ReportDsGroupIdRsp = "ReportDsGroupIdRsp",

	--Favor.proto
	PlayerGetFavorDataReq = "PlayerGetFavorDataReq",
	HeroFavorInfo = "HeroFavorInfo",
	PlayerGetFavorDataRsp = "PlayerGetFavorDataRsp",
	PlayerSetHeroFirstEnterFlagReq = "PlayerSetHeroFirstEnterFlagReq",
	PlayerSetHeroFirstEnterFlagRsp = "PlayerSetHeroFirstEnterFlagRsp",
	PlayerSendHeroGiftReq = "PlayerSendHeroGiftReq",
	PlayerSendHeroGiftRsp = "PlayerSendHeroGiftRsp",
	PlayerAddFavorSyn = "PlayerAddFavorSyn",
	PlayerGetFavorLevelPrizeReq = "PlayerGetFavorLevelPrizeReq",
	PlayerGetFavorLevelPrizeRsp = "PlayerGetFavorLevelPrizeRsp",
	PlayerStorePassageReq = "PlayerStorePassageReq",
	PlayerStorePassageRsp = "PlayerStorePassageRsp",
	PlayerAcceptPassageTaskReq = "PlayerAcceptPassageTaskReq",
	PlayerAcceptPassageTaskRsp = "PlayerAcceptPassageTaskRsp",

	--Friend.proto
	AddFriendReq = "AddFriendReq",
	AddFriendRsp = "AddFriendRsp",
	AddFriendApplyNode = "AddFriendApplyNode",
	AddFriendApplyListSyn = "AddFriendApplyListSyn",
	AddFriendOperateReq = "AddFriendOperateReq",
	AddFriendOperateRsp = "AddFriendOperateRsp",
	FriendListReq = "FriendListReq",
	FriendBaseNode = "FriendBaseNode",
	FriendBlackNode = "FriendBlackNode",
	FriendListRsp = "FriendListRsp",
	FriendBaseInfoChangeSyn = "FriendBaseInfoChangeSyn",
	FriendDeleteReq = "FriendDeleteReq",
	FriendDeleteRsp = "FriendDeleteRsp",
	FriendPlayerDataReq = "FriendPlayerDataReq",
	FriendPlayerDataRsp = "FriendPlayerDataRsp",
	FriendSetStarReq = "FriendSetStarReq",
	FriendSetStarRsp = "FriendSetStarRsp",
	FriendSetPlayerBlackReq = "FriendSetPlayerBlackReq",
	FriendSetPlayerBlackRsp = "FriendSetPlayerBlackRsp",
	FriendGetOpLogReq = "FriendGetOpLogReq",
	FriendOpLogNode = "FriendOpLogNode",
	FriendGetOpLogRsp = "FriendGetOpLogRsp",
	PlayerTimeTogetherReq = "PlayerTimeTogetherReq",
	PlayerTimeTogetherRsp = "PlayerTimeTogetherRsp",
	FriendsInRecentGamesReq = "FriendsInRecentGamesReq",
	FriendsInRecentGamesRsp = "FriendsInRecentGamesRsp",
	PlayerLookUpLastOnlineTimeReq = "PlayerLookUpLastOnlineTimeReq",
	LastOnlineTimeNode = "LastOnlineTimeNode",
	PlayerLookUpLastOnlineTimeRsp = "PlayerLookUpLastOnlineTimeRsp",
	PlayerGiveFriendItemGiftReq = "PlayerGiveFriendItemGiftReq",
	PlayerGiveFriendItemGiftRsp = "PlayerGiveFriendItemGiftRsp",
	PlayerIsFriendReq = "PlayerIsFriendReq",
	PlayerIsFriendRsp = "PlayerIsFriendRsp",

	--Gateway.proto
	HeartbeatReq = "HeartbeatReq",
	HeartbeatRsp = "HeartbeatRsp",
	ErrorSync = "ErrorSync",
	TipsSync = "TipsSync",
	IdIpSync = "IdIpSync",
	SDKLoginReq = "SDKLoginReq",
	DevLoginReq = "DevLoginReq",
	AuthFailSync = "AuthFailSync",
	LoginQueueSync = "LoginQueueSync",
	LoginRsp = "LoginRsp",
	WaitCreatePlayerSync = "WaitCreatePlayerSync",
	CreatePlayerReq = "CreatePlayerReq",
	CreatePlayerRsp = "CreatePlayerRsp",
	ContinueReq = "ContinueReq",
	ContinueRsp = "ContinueRsp",
	GateVersionSync = "GateVersionSync",
	LogoutReq = "LogoutReq",
	KickoutSync = "KickoutSync",

	--GM.proto
	GetGmListReq = "GetGmListReq",
	GmNode = "GmNode",
	GetGmListRsp = "GetGmListRsp",
	ExecuteOneGmCmdReq = "ExecuteOneGmCmdReq",
	ExecuteOneGmCmdRsp = "ExecuteOneGmCmdRsp",
	GMInstructionSync = "GMInstructionSync",
	SceneLdCpltdQuerySync = "SceneLdCpltdQuerySync",
	SceneLdCpltdResReq = "SceneLdCpltdResReq",

	--Head.proto
	PlayerBuyHeadReq = "PlayerBuyHeadReq",
	PlayerBuyHeadRsp = "PlayerBuyHeadRsp",
	PlayerSelectHeadReq = "PlayerSelectHeadReq",
	PlayerSelectHeadRsp = "PlayerSelectHeadRsp",
	PlayerBuyHeadFrameReq = "PlayerBuyHeadFrameReq",
	PlayerBuyHeadFrameRsp = "PlayerBuyHeadFrameRsp",
	PlayerBuyHeadWidgetReq = "PlayerBuyHeadWidgetReq",
	PlayerBuyHeadWidgetRsp = "PlayerBuyHeadWidgetRsp",
	HeadWidgetNode = "HeadWidgetNode",
	PlayerSaveHeadFrameWidgetDataReq = "PlayerSaveHeadFrameWidgetDataReq",
	PlayerSaveHeadFrameWidgetDataRsp = "PlayerSaveHeadFrameWidgetDataRsp",
	PlayerGetHeadDataReq = "PlayerGetHeadDataReq",
	PlayerGetHeadDataRsp = "PlayerGetHeadDataRsp",

	--Hero.proto
	BuyHeroReq = "BuyHeroReq",
	BuyHeroRsp = "BuyHeroRsp",
	SelectHeroReq = "SelectHeroReq",
	SelectHeroRsp = "SelectHeroRsp",
	BuyHeroSkinReq = "BuyHeroSkinReq",
	BuyHeroSkinRsp = "BuyHeroSkinRsp",
	SelectHeroSkinReq = "SelectHeroSkinReq",
	SelectHeroSkinRsp = "SelectHeroSkinRsp",
	HeroSelectShowReq = "HeroSelectShowReq",
	HeroSelectShowRsp = "HeroSelectShowRsp",
	BuyHeroSkinPartReq = "BuyHeroSkinPartReq",
	BuyHeroSkinPartRsp = "BuyHeroSkinPartRsp",
	SelectHeroSkinCustomPartReq = "SelectHeroSkinCustomPartReq",
	SelectHeroSkinCustomPartRsp = "SelectHeroSkinCustomPartRsp",
	SelectHeroSkinDefaultPartReq = "SelectHeroSkinDefaultPartReq",
	SelectHeroSkinDefaultPartRsp = "SelectHeroSkinDefaultPartRsp",

	--HeroPerf.proto
	HeroPerfRecordsReq = "HeroPerfRecordsReq",
	HeroPerfRecord = "HeroPerfRecord",
	HeroPerfRecordsRsp = "HeroPerfRecordsRsp",
	HeroBattleDataReq = "HeroBattleDataReq",
	HeroBattleDataRsp = "HeroBattleDataRsp",

	--Item.proto
	ItemInfoNode = "ItemInfoNode",
	PlayerItemChangeSyn = "PlayerItemChangeSyn",
	PlayerUseItemReq = "PlayerUseItemReq",
	PlayerUseItemRsp = "PlayerUseItemRsp",
	PrizeItemNode = "PrizeItemNode",
	DropPrizeItemSyn = "DropPrizeItemSyn",

	--Lobby.proto
	PlayerState = "PlayerState",
	RandomNameReq = "RandomNameReq",
	RandomNameRsp = "RandomNameRsp",
	CheckNameReq = "CheckNameReq",
	CheckNameRsp = "CheckNameRsp",
	ModifyNameReq = "ModifyNameReq",
	ModifyNameRsp = "ModifyNameRsp",
	PlayerBaseReq = "PlayerBaseReq",
	PlayerBaseMsg = "PlayerBaseMsg",
	PlayerBaseSync = "PlayerBaseSync",
	PlayerInfoSync = "PlayerInfoSync",
	PlayerAdvanceLevelData = "PlayerAdvanceLevelData",
	PlayerLevelReq = "PlayerLevelReq",
	PlayerLevelUpSyc = "PlayerLevelUpSyc",
	PlayerReceiveLevelRewardReq = "PlayerReceiveLevelRewardReq",
	PlayerReceiveLevelRewardRsp = "PlayerReceiveLevelRewardRsp",
	PlayerSysCofSync = "PlayerSysCofSync",
	HeroInfoReq = "HeroInfoReq",
	WeaponSkinNode = "WeaponSkinNode",
	HeroSkinNode = "HeroSkinNode",
	VehicleSkinNode = "VehicleSkinNode",
	PlayerMiscData = "PlayerMiscData",
	SkinSuitInfo = "SkinSuitInfo",
	VehicleStickSkinData = "VehicleStickSkinData",
	HeroInfoSync = "HeroInfoSync",
	PlayerDataBeginSync = "PlayerDataBeginSync",
	PlayerDataCompleteSync = "PlayerDataCompleteSync",
	SetPlayerDisplayStatusReq = "SetPlayerDisplayStatusReq",
	SetPlayerDisplayStatusRsp = "SetPlayerDisplayStatusRsp",
	QueryPlayerStatusReq = "QueryPlayerStatusReq",
	QueryPlayerStatusRsp = "QueryPlayerStatusRsp",
	QueryMultiPlayerStatusReq = "QueryMultiPlayerStatusReq",
	QueryMultiPlayerStatusRsp = "QueryMultiPlayerStatusRsp",
	PlayerExitDSReq = "PlayerExitDSReq",
	PlayerExitDSRsp = "PlayerExitDSRsp",
	RankReq = "RankReq",
	RankInfo = "RankInfo",
	RankRsp = "RankRsp",
	PlayerGetAllSkinNumReq = "PlayerGetAllSkinNumReq",
	PlayerGetAllSkinNumRsp = "PlayerGetAllSkinNumRsp",
	PlayerUpdateTagReq = "PlayerUpdateTagReq",
	PlayerUpdateTagRsp = "PlayerUpdateTagRsp",
	PlayerUnlockTagNotify = "PlayerUnlockTagNotify",
	UploadPortraitReq = "UploadPortraitReq",
	UploadPortraitSync = "UploadPortraitSync",
	SeasonChangeSync = "SeasonChangeSync",
	AcePackageC2sReq = "AcePackageC2sReq",
	AcePackageS2cSync = "AcePackageS2cSync",
	ClientUpdateSync = "ClientUpdateSync",
	GetHeadIdListReq = "GetHeadIdListReq",
	GetHeadIdListRsp = "GetHeadIdListRsp",
	CommonDayRefreshSync = "CommonDayRefreshSync",
	GetTextIdMultiLanguageContentReq = "GetTextIdMultiLanguageContentReq",
	GetTextIdMultiLanguageContentRsp = "GetTextIdMultiLanguageContentRsp",

	--Lottery.proto
	PlayerGetStartLotteryReq = "PlayerGetStartLotteryReq",
	LotteryInfoNodeNode = "LotteryInfoNodeNode",
	PlayerGetStartLotteryRsp = "PlayerGetStartLotteryRsp",
	PlayerLotteryInfoReq = "PlayerLotteryInfoReq",
	PlayerLotteryInfoRsp = "PlayerLotteryInfoRsp",
	PlayerLotteryReq = "PlayerLotteryReq",
	PlayerLotteryRsp = "PlayerLotteryRsp",
	PlayerGetPrizePoolRateReq = "PlayerGetPrizePoolRateReq",
	ItemQualityRateNode = "ItemQualityRateNode",
	PlayerGetPrizePoolRateRsp = "PlayerGetPrizePoolRateRsp",
	PlayerGetLotteryRecordReq = "PlayerGetLotteryRecordReq",
	PrizeDecomposNode = "PrizeDecomposNode",
	LotteryRecordNode = "LotteryRecordNode",
	PlayerGetLotteryRecordRsp = "PlayerGetLotteryRecordRsp",

	--Mail.proto
	AppendInfo = "AppendInfo",
	MailInfoNode = "MailInfoNode",
	PlayerMailInfoListReq = "PlayerMailInfoListReq",
	PlayerMailInfoListRsp = "PlayerMailInfoListRsp",
	PlayerAddMailSyn = "PlayerAddMailSyn",
	PlayerReadMailReq = "PlayerReadMailReq",
	PlayerReadMailRsp = "PlayerReadMailRsp",
	PlayerGetAppendReq = "PlayerGetAppendReq",
	PlayerGetAppendRsp = "PlayerGetAppendRsp",
	PlayerDeleteMailReq = "PlayerDeleteMailReq",
	PlayerDeleteMailRsp = "PlayerDeleteMailRsp",

	--Match.proto
	Team = "Team",
	MatchReq = "MatchReq",
	MatchRsp = "MatchRsp",
	MatchCancelReq = "MatchCancelReq",
	MatchCancelRsp = "MatchCancelRsp",
	MatchParam = "MatchParam",
	MatchResultSync = "MatchResultSync",
	DsConnectMeta = "DsConnectMeta",
	DsMetaSync = "DsMetaSync",
	MatchDsBaseInfoSync = "MatchDsBaseInfoSync",
	MatchAndDsStateReq = "MatchAndDsStateReq",
	MatchAndDsStateSync = "MatchAndDsStateSync",
	GiveupReconnectDsReq = "GiveupReconnectDsReq",
	GiveupReconnectDsRsp = "GiveupReconnectDsRsp",
	PlayerLogoutDs = "PlayerLogoutDs",
	GameExceptionSync = "GameExceptionSync",

	--Misc.proto
	PlayerLikeHeartReq = "PlayerLikeHeartReq",
	PlayerLikeHeartRsp = "PlayerLikeHeartRsp",
	PlayerLikeReq = "PlayerLikeReq",
	PlayerLikeRsp = "PlayerLikeRsp",
	PlayerLookUpDetailReq = "PlayerLookUpDetailReq",
	RecentVisitorNode = "RecentVisitorNode",
	ShowHeroNode = "ShowHeroNode",
	MaxDivisionNode = "MaxDivisionNode",
	RankStatisticsBase = "RankStatisticsBase",
	PlayerDetailData = "PlayerDetailData",
	PlayerLookUpDetailRsp = "PlayerLookUpDetailRsp",
	PlayerReportInfoReq = "PlayerReportInfoReq",
	PlayerReportInfoRsp = "PlayerReportInfoRsp",
	SetPersonalReq = "SetPersonalReq",
	SetPersonalRsp = "SetPersonalRsp",
	GetPlayerDetailInfoReq = "GetPlayerDetailInfoReq",
	PlayerDetailInfo = "PlayerDetailInfo",
	GetPlayerDetailInfoRsp = "GetPlayerDetailInfoRsp",
	GetPlayerCommonDialogDataReq = "GetPlayerCommonDialogDataReq",
	PlayerCommonDialogInfo = "PlayerCommonDialogInfo",
	GetPlayerCommonDialogDataRsp = "GetPlayerCommonDialogDataRsp",
	ClientBuryingPoint = "ClientBuryingPoint",
	ClientBuryingPointSync = "ClientBuryingPointSync",

	--Netlog.proto
	NetlogFile = "NetlogFile",
	NetlogMsg = "NetlogMsg",
	NetlogRes = "NetlogRes",
	NetlogHeartbeat = "NetlogHeartbeat",

	--NewbieGuide.proto
	SetNewbieGuideConditionReq = "SetNewbieGuideConditionReq",
	SetNewbieGuideConditionRsp = "SetNewbieGuideConditionRsp",
	QueryNewbieGuideConditionReq = "QueryNewbieGuideConditionReq",
	QueryNewbieGuideConditionRsp = "QueryNewbieGuideConditionRsp",
	GetGameModeDataReq = "GetGameModeDataReq",
	GetGameModeDataRsp = "GetGameModeDataRsp",
	PlayerChooseGenderReq = "PlayerChooseGenderReq",
	PlayerChooseGenderRsp = "PlayerChooseGenderRsp",

	--Questionnaire.proto
	QuestionnaireInfoBase = "QuestionnaireInfoBase",
	QuestionnaireReq = "QuestionnaireReq",
	QuestionnaireRsp = "QuestionnaireRsp",
	QuestionnaireDeliverySync = "QuestionnaireDeliverySync",
	QuestionnaireShowAckReq = "QuestionnaireShowAckReq",
	QuestionnairesSync = "QuestionnairesSync",

	--Recharge.proto
	PlayerRechargeReq = "PlayerRechargeReq",
	PlayerRechargeRsp = "PlayerRechargeRsp",

	--RedDot.proto
	RedDotNode = "RedDotNode",
	TagCustomInfo = "TagCustomInfo",
	RedDotInfo = "RedDotInfo",
	PlayerGetRedDotDataReq = "PlayerGetRedDotDataReq",
	PlayerGetRedDotDataRsp = "PlayerGetRedDotDataRsp",
	PlayerUpdateRedDotInfoSyn = "PlayerUpdateRedDotInfoSyn",
	CancelRedDotInfo = "CancelRedDotInfo",
	PlayerCancelRedDotInfoReq = "PlayerCancelRedDotInfoReq",
	PlayerCancelRedDotInfoRsp = "PlayerCancelRedDotInfoRsp",
	PlayerSetRedDotInfoTagReq = "PlayerSetRedDotInfoTagReq",
	PlayerSetRedDotInfoTagRsp = "PlayerSetRedDotInfoTagRsp",

	--Room.proto
	StartClientDsSync = "StartClientDsSync",
	BaseRoomInfoMsg = "BaseRoomInfoMsg",
	RoomPlayerInfo = "RoomPlayerInfo",
	BaseTeamInfo = "BaseTeamInfo",
	FullRoomInfo = "FullRoomInfo",
	CustomRoomInfoReq = "CustomRoomInfoReq",
	CustomRoomInfoRsp = "CustomRoomInfoRsp",
	RoomListReq = "RoomListReq",
	RoomListRsp = "RoomListRsp",
	SearchRoomReq = "SearchRoomReq",
	SearchRoomRsp = "SearchRoomRsp",
	CreateRoomReq = "CreateRoomReq",
	CreateRoomRsp = "CreateRoomRsp",
	JoinRoomReq = "JoinRoomReq",
	JoinRoomRsp = "JoinRoomRsp",
	JoinRoomSync = "JoinRoomSync",
	ExitRoomReq = "ExitRoomReq",
	PosChangeInfoBase = "PosChangeInfoBase",
	ExitRoomRsp = "ExitRoomRsp",
	MasterExitRoomSync = "MasterExitRoomSync",
	PlayerExitRoomSync = "PlayerExitRoomSync",
	ChangePosReq = "ChangePosReq",
	ChangePosRsp = "ChangePosRsp",
	ChangePosSync = "ChangePosSync",
	ChangeTeamReq = "ChangeTeamReq",
	ChangeTeamRsp = "ChangeTeamRsp",
	PlayerTeamChangeInfo = "PlayerTeamChangeInfo",
	ChangeTeamSync = "ChangeTeamSync",
	KickPlayerReq = "KickPlayerReq",
	KickPlayerRsp = "KickPlayerRsp",
	KickPlayerSync = "KickPlayerSync",
	TransMasterReq = "TransMasterReq",
	TransMasterRsp = "TransMasterRsp",
	TransMasterSync = "TransMasterSync",
	InviteReq = "InviteReq",
	InviteRsp = "InviteRsp",
	InviteSync = "InviteSync",
	DissolveRoomReq = "DissolveRoomReq",
	DissolveRoomRsp = "DissolveRoomRsp",
	DissolveRoomSync = "DissolveRoomSync",
	StartGameReq = "StartGameReq",
	StartGameRsp = "StartGameRsp",
	StartGameSync = "StartGameSync",
	AutoTestJoinRoomReq = "AutoTestJoinRoomReq",
	CustomRoomNameChangeSync = "CustomRoomNameChangeSync",
	ChangeToObserverReq = "ChangeToObserverReq",
	ChangeToObserverRsp = "ChangeToObserverRsp",
	ChangeToFighterReq = "ChangeToFighterReq",
	ChangeToFighterRsp = "ChangeToFighterRsp",
	ObserverChangeSync = "ObserverChangeSync",
	JoinRoomObserverSync = "JoinRoomObserverSync",
	ObserverExitRoomReq = "ObserverExitRoomReq",
	ObserverExitRoomRsp = "ObserverExitRoomRsp",
	ObserverExitSync = "ObserverExitSync",

	--Rtc.proto
	GetRtcTokenReq = "GetRtcTokenReq",
	GetRtcTokenRsp = "GetRtcTokenRsp",

	--Season.proto
	WeaponInjuryDataReq = "WeaponInjuryDataReq",
	WeaponInjuryDataRsp = "WeaponInjuryDataRsp",

	--SeasonBattlePass.proto
	BuyPassReq = "BuyPassReq",
	BuyPassRsp = "BuyPassRsp",
	RecvPassRewardReq = "RecvPassRewardReq",
	RecvPassRewardRsp = "RecvPassRewardRsp",
	PassStatusReq = "PassStatusReq",
	PassStatusRsp = "PassStatusRsp",
	PassExpReq = "PassExpReq",
	PassExpIncSync = "PassExpIncSync",
	PassDailyTaskReq = "PassDailyTaskReq",
	BpTaskBase = "BpTaskBase",
	PassDailyTaskRsp = "PassDailyTaskRsp",
	PassWeekTaskReq = "PassWeekTaskReq",
	PassWeekTaskRsp = "PassWeekTaskRsp",
	PassUnlockWeekTaskReq = "PassUnlockWeekTaskReq",
	WeeklyTasksBase = "WeeklyTasksBase",
	PassUnlockWeekTaskRsp = "PassUnlockWeekTaskRsp",

	--Settlement.proto
	PlayerSettlementUnit = "PlayerSettlementUnit",
	TeamSettlementSync = "TeamSettlementSync",

	--Shop.proto
	GoodNode = "GoodNode",
	PlayerShopGoodInfoListReq = "PlayerShopGoodInfoListReq",
	PlayerShopGoodInfoListRsp = "PlayerShopGoodInfoListRsp",
	PlayerBuyGoodReq = "PlayerBuyGoodReq",
	PlayerBuyGoodRsp = "PlayerBuyGoodRsp",
	PlayerShopClearLimitNotify = "PlayerShopClearLimitNotify",

	--Stat.proto
	StatItem = "StatItem",
	PlayerStatSyncData = "PlayerStatSyncData",

	--Task.proto
	PlayerAllTaskReq = "PlayerAllTaskReq",
	TargetProcessNode = "TargetProcessNode",
	LbTaskInfoNode = "LbTaskInfoNode",
	PlayerAllTaskRsp = "PlayerAllTaskRsp",
	PlayerAcceptTaskReq = "PlayerAcceptTaskReq",
	PlayerAcceptTaskRsp = "PlayerAcceptTaskRsp",
	PlayerTaskAcceptNotify = "PlayerTaskAcceptNotify",
	PlayerTaskDeleteNotify = "PlayerTaskDeleteNotify",
	LbProcessNode = "LbProcessNode",
	LbProcessNodeList = "LbProcessNodeList",
	PlayerTaskProcessNotify = "PlayerTaskProcessNotify",
	PlayerTaskStateNotify = "PlayerTaskStateNotify",

	--Team.proto
	InviteInfoMsg = "InviteInfoMsg",
	TeamMember = "TeamMember",
	TeamInviteReq = "TeamInviteReq",
	TeamInviteRsp = "TeamInviteRsp",
	TeamInviteSync = "TeamInviteSync",
	TeamInviteReplyReq = "TeamInviteReplyReq",
	TeamInviteReplyRsp = "TeamInviteReplyRsp",
	TeamInviteReplySync = "TeamInviteReplySync",
	TeamInviteCancelReq = "TeamInviteCancelReq",
	TeamInviteCancelRsp = "TeamInviteCancelRsp",
	TeamInviteCancelSync = "TeamInviteCancelSync",
	ApplyInfoMsg = "ApplyInfoMsg",
	TeamApplyReq = "TeamApplyReq",
	TeamApplyRsp = "TeamApplyRsp",
	TeamApplySync = "TeamApplySync",
	TeamApplyReplyReq = "TeamApplyReplyReq",
	TeamApplyReplyRsp = "TeamApplyReplyRsp",
	TeamApplyReplySync = "TeamApplyReplySync",
	TeamInfoReq = "TeamInfoReq",
	TeamInfoSync = "TeamInfoSync",
	UpdateTeamInfoReq = "UpdateTeamInfoReq",
	UpdateTeamInfoRsp = "UpdateTeamInfoRsp",
	TeamIncreInfoSync = "TeamIncreInfoSync",
	PlayerInfo = "PlayerInfo",
	InviteListInfo = "InviteListInfo",
	ApplyListInfo = "ApplyListInfo",
	MergeListInfo = "MergeListInfo",
	TeamQuitReq = "TeamQuitReq",
	TeamQuitRsp = "TeamQuitRsp",
	TeamKickReq = "TeamKickReq",
	TeamKickRsp = "TeamKickRsp",
	TeamChangeLeaderReq = "TeamChangeLeaderReq",
	TeamChangeLeaderRsp = "TeamChangeLeaderRsp",
	TeamChangeModeReq = "TeamChangeModeReq",
	TeamChangeModeRsp = "TeamChangeModeRsp",
	PlayerListTeamInfoReq = "PlayerListTeamInfoReq",
	PlayerListTeamInfoRsp = "PlayerListTeamInfoRsp",
	MergeInfoMsg = "MergeInfoMsg",
	TeamMergeReq = "TeamMergeReq",
	TeamMergeRsp = "TeamMergeRsp",
	TeamMergeSync = "TeamMergeSync",
	TeamMergeReplyReq = "TeamMergeReplyReq",
	TeamMergeReplyRsp = "TeamMergeReplyRsp",
	TeamMergeReplySync = "TeamMergeReplySync",
	QueryTeamMsg = "QueryTeamMsg",
	QueryMultiTeamInfoReq = "QueryMultiTeamInfoReq",
	QueryMultiTeamInfoRsp = "QueryMultiTeamInfoRsp",
	TeamChangeMemberStatusReq = "TeamChangeMemberStatusReq",
	TeamChangeMemberStatusRsp = "TeamChangeMemberStatusRsp",
	TeamInviteNotifyDelSync = "TeamInviteNotifyDelSync",
	TeamSingleChangeNotifyReq = "TeamSingleChangeNotifyReq",
	TeamSingleChangeNotifyRsp = "TeamSingleChangeNotifyRsp",
	RecommendTeammateInfo = "RecommendTeammateInfo",
	RecommendTeammateListReq = "RecommendTeammateListReq",
	RecommendTeammateListRsp = "RecommendTeammateListRsp",

	--UnLock.proto
	PlayerUnLockInfoReq = "PlayerUnLockInfoReq",
	PlayerUnLockInfoRsp = "PlayerUnLockInfoRsp",
	PlayerUnLockNotify = "PlayerUnLockNotify",

	--Vehicle.proto
	SelectVehicleReq = "SelectVehicleReq",
	SelectVehicleRsp = "SelectVehicleRsp",
	BuyVehicleSkinReq = "BuyVehicleSkinReq",
	BuyVehicleSkinRsp = "BuyVehicleSkinRsp",
	SelectVehicleSkinReq = "SelectVehicleSkinReq",
	SelectVehicleSkinRsp = "SelectVehicleSkinRsp",
	BuyStickerNode = "BuyStickerNode",
	BuyVehicleStickerReq = "BuyVehicleStickerReq",
	BuyVehicleStickerRsp = "BuyVehicleStickerRsp",
	StickerDataNode = "StickerDataNode",
	UpdateVehicleStickerDataReq = "UpdateVehicleStickerDataReq",
	UpdateVehicleStickerDataRsp = "UpdateVehicleStickerDataRsp",
	UnequipStickerFromVehicleSkinReq = "UnequipStickerFromVehicleSkinReq",
	UnequipStickerFromVehicleSkinRsp = "UnequipStickerFromVehicleSkinRsp",
	RandomVehicleLicensePlateReq = "RandomVehicleLicensePlateReq",
	RandomVehicleLicensePlateRsp = "RandomVehicleLicensePlateRsp",
	VehicleSelectLicensePlateReq = "VehicleSelectLicensePlateReq",
	VehicleSelectLicensePlateRsp = "VehicleSelectLicensePlateRsp",
	VehicleDefaultLicenseSync = "VehicleDefaultLicenseSync",

	--Weapon.proto
	SelectWeaponReq = "SelectWeaponReq",
	SelectWeaponRsp = "SelectWeaponRsp",
	BuyWeaponSkinReq = "BuyWeaponSkinReq",
	BuyWeaponSkinRsp = "BuyWeaponSkinRsp",
	SelectWeaponSkinReq = "SelectWeaponSkinReq",
	SelectWeaponSkinRsp = "SelectWeaponSkinRsp",
	WeaponPartSkinDetailReq = "WeaponPartSkinDetailReq",
	WeaponPartNode = "WeaponPartNode",
	WeaponPartSkinNode = "WeaponPartSkinNode",
	WeaponPartSkinDetailRsp = "WeaponPartSkinDetailRsp",
	WeaponEquipPartReq = "WeaponEquipPartReq",
	WeaponEquipPartRsp = "WeaponEquipPartRsp",
	WeaponUnEquipPartReq = "WeaponUnEquipPartReq",
	WeaponUnEquipPartRsp = "WeaponUnEquipPartRsp",
	BuyWeaponPartSkinReq = "BuyWeaponPartSkinReq",
	BuyWeaponPartSkinRsp = "BuyWeaponPartSkinRsp",
	WeaponSkinEquipPartSkinReq = "WeaponSkinEquipPartSkinReq",
	WeaponSkinEquipPartSkinRsp = "WeaponSkinEquipPartSkinRsp",
	WeaponSkinUnEquipPartSkinReq = "WeaponSkinUnEquipPartSkinReq",
	WeaponSkinUnEquipPartSkinRsp = "WeaponSkinUnEquipPartSkinRsp",

}

Pb_Enum_ACTIVITY_TYPE = 
{
	ACTIVITY_TYPE_INVAILD = 0, --// 无效
	ACTIVITY_TYPE_THREE_LOGIN = 1, --// 三日登录
	ACTIVITY_TYPE_WEEK_LOGIN = 2, --// 7日登录周循环和非循环
	ACTIVITY_TYPE_ATTATION = 3, --// 关注类活动，比如分享等
	ACTIVITY_TYPE_SINGLE_TASK = 4, --// 单任务大图活动
	ACTIVITY_TYPE_DAY_TASK = 5, --// 每日活动任务
	ACTIVITY_TYPE_TASK = 6, --// 任务
	ACTIVITY_TYPE_EXCHANGE = 7, --// 兑换任务
	ACTIVITY_TYPE_MULTI_JUMP = 8, --// 双跳大图活动
}
Pb_Enum_ACTIVITY_SUB_ITEM_TYPE = 
{
	ACTIVITY_SUB_ITEM_TYPE_INVAILD = 0, --// 无效
	ACTIVITY_SUB_ITEM_TYPE_TASK = 1, --// 活动子项任务类型
	ACTIVITY_SUB_ITEM_TYPE_ACTIVITY = 2, --// 活动子项活跃度类型
	ACTIVITY_SUB_ITEM_TYPE_SHARE = 3, --// 活动子项分享类型
	ACTIVITY_SUB_ITEM_TYPE_TEXT = 4, --// 活动子项文本类型
}
Pb_Enum_ACTIVITY_SUB_ITEM_PRIZE_STATE = 
{
	ACTIVITY_SUB_ITEM_PRIZE_STATE_INVAILD = 0, --// 0或者nil就标识未完成
	ACTIVITY_SUB_ITEM_PRIZE_STATE_FINISH = 1, --// 子项已经完成，可以领取奖励
	ACTIVITY_SUB_ITEM_PRIZE_STATE_PRIZE = 2, --// 子项已经完成，并且领取奖励
}
Pb_Enum_ACTIVITY_REDDOT_TYPE = 
{
	ACTIVITY_REDDOT_TYPE_INVAILD = 0, --// 无效
	ACTIVITY_REDDOT_TYPE_DAY = 1, --// 每日刷新红点
	ACTIVITY_REDDOT_TYPE_FIRST = 2, --// 首次
	ACTIVITY_REDDOT_TYPE_SUBITEM = 3, --// 子项有奖励红点
}
Pb_Enum_BAN_TYPE = 
{
	BAN_NONE = 0, --// 不禁止
	BAN_CHAT = 1, --// 禁止聊天
	BAN_VOICE = 2, --// 禁止语言
}
Pb_Enum_SettlementRewardSrcType = 
{
	SettlementRewardSrcTypeCoin = 0, --// 结算增加金币
	SettlementRewardSrcTypeLevelUp = 1, --// 结算增加经验
	SettlementRewardSrcTypeGrowthMoney = 2, --// 剩余成长货币
}
Pb_Enum_CHAT_TYPE = 
{
	PRIVATE_CHAT = 0, --// 私聊
	WORLD_CHANNEL_CHAT = 1, --// 世界频道聊天
	TEAM_CHAT = 2, --// 组队聊天
	DS_CHAT = 3, --// DS局内聊天
	CUSTOMROOM_CHAT = 4, --// 自建房聊天
}
Pb_Enum_DS_CHAT_SUBTYPE = 
{
	DS_CHAT_ALL = 0, --// 所有人
	DS_CHAT_TEAM = 1, --// 组队聊天
	DS_CHAT_PRIVATE = 2, --// 私聊
	DS_CHAT_SYSTEM = 3, --// 系统
	DS_CHAT_NEARBY = 4, --// 附近的人
	DS_CHAT_MARKSYSTEM = 5, --// 标记系统
}
Pb_Enum_MSG_STATUS = 
{
	CHAT_PASS = 0, --// 通过时使用filtertext字段替换原信息
	CHAT_SELF = 1, --// 自见是仅发送方自己可见消息，接受者看不见消息
	CHAT_PUNISH = 2, --// 用户被处罚禁言（聊天场景）处罚情况下，直接提示用户被处罚无法发送消息
	CHAT_REJECT = 3, --// 拒绝就是拒绝发送消息或拒绝修改编辑提示发送或编辑失败，或者存在不合法的信息发送或编辑失败
	CHAT_INVALID = 4, --// 聊天各种参数校验不合法
}
Pb_Enum_PackFlag = 
{
	PACK_NONE = 0, --// 无包头
	PACK_NORMAL = 1, --// 普通包
	PACK_SERVICE = 2, --// SERVICE包，带路由信息
}
Pb_Enum_MsgType = 
{
	MSG_NONE = 0, --// 无包头
	MSG_PBRPC = 1, --// PBRPC
	MSG_LUARPC = 2, --// LUARPC
}
Pb_Enum_CryptoType = 
{
	CRYPTO_NONE = 0, --// 明文
	CRYPTO_BLOWFISH = 1, --// BF
	CRYPTO_RC4 = 2, --// RC4
	CRYPTO_AES = 3, --// AES
}
Pb_Enum_EDivisionRewardStatus = 
{
	Invalid = 0, --// 非法类型
	Locked = 1, --//未解锁
	Unobtained = 2, --// 可领取
	Obtained = 3, --// 已获得
}
Pb_Enum_FAVORSTORY_UNLOCK_TYPE = 
{
	FAVORSTORY_UNLOCK_TYPE_NONE = 0, --// 无条件限制
	FAVORSTORY_UNLOCK_TYPE_FAVORLEVEL = 1, --// 好感度等级
	FAVORSTORY_UNLOCK_TYPE_PASSAGE = 2, --// 段落
	FAVORSTORY_UNLOCK_TYPE_TASK = 3, --// 任务
}
Pb_Enum_BASE_INFO_CHANGE_TYPE = 
{
	CHANGE_INVAILD = 0, --// 其他变化逻辑
	CHANGE_INTIMACY = 1, --// 亲密度变化
	CHANGE_STATUS = 2, --// 状态变化
	CHANGE_TEAM_DATA = 3, --// 游戏时长和组队场次变化
	CHANGE_ADD_FRIEND = 4, --// 添加好友
}
Pb_Enum_FRIEND_OP_TYPE = 
{
	FRIEND_OP_INVAILD = 0, --// 无效类型
	FRIEND_OP_ADD_FRIEND = 1, --// 添加好友
	FRIEND_OP_INTIMACY_LEVEL = 2, --// 亲密度等级提升
	FRIEND_OP_TEAM_PLAY_RANK = 3, --// 好友组队游戏排名
	FRIEND_OP_TEAM_PLAY_TIME = 4, --// 好友组队游戏时长
	FRIEND_OP_TEAM_PLAY_GAME = 5, --// 好友组队游戏场次
}
Pb_Enum_FRIEND_ADD_INTIMACY_TYPE = 
{
	FRIEND_ADD_INTIMACY_GM = 0, --// Gm类型
	FRIEND_ADD_INTIMACY_TEAM_PLAY = 1, --// 组队玩游戏
	FRIEND_ADD_INTIMACY_GIVE_ITEM = 999, --// 送礼礼物
}
Pb_Enum_HERO_SKIN_TYPE = 
{
	HERO_SKIN_TYPE_COMMON = 0, --// 普通的默认皮肤
	HERO_SKIN_TYPE_COLORFUL = 1, --// 炫彩套装类型皮肤
	HERO_SKIN_TYPE_PART = 2, --// 部件套装类型皮肤
}
Pb_Enum_HERO_SKIN_PART_TYPE = 
{
	HERO_SKIN_PART_TYPE_INVAILD = 0, --// 无效皮肤部位
	HERO_SKIN_PART_TYPE_HEAD = 1, --// 头部部件
	HERO_SKIN_PART_TYPE_MAIN = 2, --// 主体部件
	HERO_SKIN_PART_TYPE_LEG = 3, --// 腿部部件
}
Pb_Enum_ITEM_QUALITY_TYPE = 
{
	ITEM_QUALITY_INVAILD = 0, --// 无效品质类型
	ITEM_QUALITY_GREY = 1, --// 灰色品质
	ITEM_QUALITY_BLUE = 2, --// 蓝色品质
	ITEM_QUALITY_PURPLE = 3, --// 紫色品质
	ITEM_QUALITY_YELLOW = 4, --// 黄色品质
	ITEM_QUALITY_RED = 5, --// 红色品质
}
Pb_Enum_ITEM_TYPE = 
{
	ITEM_INVAILD = 0, --// 无效物品类型
	ITEM_INSIDE = 1, --// 局内道具
	ITEM_PLAYER = 2, --// 角色
	ITEM_WEAPON = 3, --// 武器
	ITEM_VEHICLE = 4, --// 载具
	ITEM_PARAGLIDER = 5, --// 滑翔伞
	ITEM_SOCIAL = 6, --// 社交
	ITEM_ACTIVITY = 7, --// 活动
	ITEM_OTHER = 8, --// 其他
	ITEM_MONEY = 9, --// 货币
	ITEM_EQUIPMENT = 98, --// 装备
	ITEM_CONSUMABLES = 99, --// 消耗品
}
Pb_Enum_SYN_ITEM_CHANGE_TYPE = 
{
	SYN_ITEM_CHANGE_ADD = 0, --// 增加物品
	SYN_ITEM_CHANGE_DEL = 1, --// 删除物品
}
Pb_Enum_ITEM_USE_TYPE = 
{
	ITEM_USE_INVAILD = 0, --// 无效物品类型
	ITEM_USE_DROPID = 10001, --// 使用物品掉落Id
	ITEM_USE_COMPOSE_ITEM = 10002, --// 合成物品
	ITEM_USE_ADD_GOLD_COF = 10003, --// 使用金币加成
	ITEM_USE_ADD_EXP_COF = 10004, --// 使用经验加成
	ITEM_USE_EXP = 10005, --// 使用物品获得经验
	ITEM_USE_PASS_TICKET_EXP = 10006, --// 使用物品获得通行证经验
	ITEM_USE_CLINET_OPEN_UI = 20001, --// 客户端使用的类型
}
Pb_Enum_PLAYER_STATE = 
{
	PLAYER_OFFLINE = 0, --// 离线
	PLAYER_LOGIN = 1, --// 登陆中
	PLAYER_LOBBY = 2, --// 大厅中
	PLAYER_TEAM = 3, --// 组队中
	PLAYER_CUSTOMROOM = 4, --// 自建房中
	PLAYER_MATCH = 5, --// 匹配中
	PLAYER_BATTLE = 6, --// 战斗中
	PLAYER_SETTLE = 7, --// 结算中
}
Pb_Enum_RECOMMEND_TEAM_SOURCE = 
{
	RECOMMEND_INIT = 0, --// 一般推荐
	RECOMMEND_RECENT_PLAYED = 1, --// 最近共同游玩
}
Pb_Enum_PLAYER_ADD_EXPENRICE_REASON = 
{
	PLAYER_ADD_EXPENRICE_REASON_USEITEM = 0, --// 使用道具
	PLAYER_ADD_EXPENRICE_REASON_PALYGAME = 1, --// 打游戏
}
Pb_Enum_TAG_UNLOCK_TYPE = 
{
	TAG_UNLOCK_TYPE_INVAILD = 0, --// 无效类型
	TAG_UNLOCK_TYPE_DAN = 1, --// 段位条件解锁
}
Pb_Enum_LOTTERY_RECORD_TYPE = 
{
	LOTTERY_RECORD_INVAILD = 0, --// 无效类型
	LOTTERY_RECORD_TIME_LIMIT = 1, --// 有时限的
	LOTTERY_RECORD_FOREVER = 2, --// 永久的，常住的
}
Pb_Enum_MAIL_PAGE_TYPE = 
{
	MAIL_PAGE_INVAILD = 0, --// 无效邮件类型
	MAIL_PAGE_SYS = 1, --// 系统
	MAIL_PAGE_GIFT = 2, --// 礼物
	MAIL_PAGE_MSG = 3, --// 消息
}
Pb_Enum_DS_META_SRC = 
{
	MATCH_SVR = 0, --// 匹配
	CUSTOM_ROOM_SVR = 1, --// 自建房
}
Pb_Enum_GUIDE_COND_TYPE = 
{
	OUTSIDE_GAME_GUIDE = 0, --// 局外新手引导
}
Pb_Enum_RED_DOT_SYS = 
{
	RED_DOT_INVAILD = 0, --// 无效系统类型
	RED_DOT_ITEM = 1, --// 物品系统，红点key是物品唯一Id
	RED_DOT_MAIL = 2, --// 邮件系统, 红点key是邮件的唯一Id
	RED_DOT_NOTICE = 3, --// 公告系统，红点key是公告的配置的Id
	RED_DOT_SHOP = 4, --// 商店系统，红点key是商品Id
	RED_DOT_SEASON_LOTTERY = 5, --// 赛季抽奖卡池，红点key是奖池Id
	RED_DOT_CHAT_FRIEND = 6, --// 好友聊天，红点key是玩家的PlayerId
	RED_DOT_CHAT_TEAM = 7, --// 组队聊天，红点key是队伍Id
	RED_DOT_TEAM_INVIT = 8, --// 组队邀请，红点key是队伍Id
	RED_DOT_TEAM_APPLY = 9, --// 组队申请，红点key是申请队伍的玩家PlayerId
	RED_DOT_TEAM_ADD_FRIEND = 10, --// 添加好友，红点key是玩家的PlayerId
	RED_DOT_FAVOR_LEVEL_PRIZE = 11, --// 好感度等级奖励，红点key是等级段Id
	RED_DOT_FAVOR_TASK_FINISH = 12, --// 好感度剧情任务完成，红点key是任务Id
	RED_DOT_GAME_PLAY_MODE = 13, --// 玩法模式，红点key是模式Id
	RED_DOT_ACTIVITY = 14, --// 活动系统，红点key是活动Id
	RED_DOT_ACTIVITY_SUBITEM = 15, --// 活动系统子项Id，红点key是活动的子项Id
	RED_DOT_PLAYER_LEVEL = 16, --// 玩家等级系统
	RED_DOT_FAVOR_ITEM = 17, --// 好感度系统，获得可以赠送道具
	RED_DOT_ACHIEVE = 18, --// 成就系统，红点key是成就Id
	RED_DOT_BATTLE_PASS = 19, --// 赛季通行证，红点Key是通行证等级
	RED_DOT_MISC_SYS = 4096, --// 其他模块只有一个key的红点数据集合
}
Pb_Enum_RED_DOT_SYS_KEY_ID = 
{
	RED_DOT_SYS_KEY_ID_INVAILD = 0, --// 无效系统key
	RED_DOT_SYS_KEY_ID_VISITOR = 1, --// 访客红点key
}
Pb_Enum_CUSTOMROOM_JOIN_SRC = 
{
	JOIN_SRC_INVALID = 0, --// 无效来源
	JOIN_SRC_NORMAL = 1, --// 普通加入房间
	JOIN_SRC_INVITE = 2, --// 邀请加入房间
}
Pb_Enum_CUSTOMROOM_STATUS = 
{
	CUSTOMROOM_ST_IDLE = 0, --// 空闲中
	CUSTOMROOM_ST_GAME = 1, --// 游戏中
}
Pb_Enum_CUSTOMROOM_PLAYER_STATE = 
{
	IN_ROOM = 0, --// 在房间中
	KICKED_OUT = 1, --// 被踢出
	ROOM_DISBANDED = 2, --// 房间解散
}
Pb_Enum_PASS_TYPE = 
{
	BASIC = 0, --// 普通通行证 默认解锁
	PREMIUM = 1, --// 高级通行证
	DELUXE = 2, --// 豪华通行证
}
Pb_Enum_GOOD_REFRESH_TYPE = 
{
	GOOD_REFRESH_TYPE_INVALID = 0, --// 不限购
	GOOD_REFRESH_TYPE_DAY = 1, --// 每日刷新
	GOOD_REFRESH_TYPE_WEEK = 2, --// 每周刷新
	GOOD_REFRESH_TYPE_MONTH = 3, --// 每月刷新
	GOOD_REFRESH_TYPE_SEASON = 4, --// 每赛季刷新
	GOOD_REFRESH_TYPE_FOREVER = 5, --// 永久限购
}
Pb_Enum_PLAYER_STAT_TYPE = 
{
	STAT_INVALID = 0,
	STAT_BATTLE_MODE = 1, --// 对局模式统计数据
}
Pb_Enum_TASK_SOURCE_TYPE = 
{
	TASK_SOURCE_TYPE_GM = 0, --// Gm指令
	TASK_SOURCE_TYPE_SEASON = 1, --// 赛季任务
	TASK_SOURCE_TYPE_LEVEL = 2, --// 等级任务
	TASK_SOURCE_TYPE_QUESTIONNAIRE = 3, --// 问卷任务
	TASK_SOURCE_TYPE_LOGIN = 4, --// 玩家登录时触发的一些任务
}
Pb_Enum_TASK_TYPE_STATE = 
{
	TASK_TYPE_DOING = 0, --// 正在进行的任务
	TASK_TYPE_FINISH = 1, --// 已经完成的任务
}
Pb_Enum_REPLY_TYPE = 
{
	ACCEPT = 0, --// 同意
	REJECT = 1, --// 拒绝
}
Pb_Enum_TEAM_MEMBER_STATUS = 
{
	BATTLE = 0, --// 战斗中
	READY = 1, --// 准备
	UNREADY = 2, --// 未准备
	OFFLINE = 3, --// 离线
	SETTLE = 4, --// 结算中
	MATCH = 5, --// 匹配中
	CONNECTING = 6, --// 意外掉线
}
Pb_Enum_TEAM_SYNC_REASON = 
{
	SYNC_CREATE_TEAM = 0,
	SYNC_JOIN_TEAM = 1,
	SYNC_LEAVE_TEAM = 2,
	SYNC_SYNC_TEAM = 3,
	SYNC_TEAM_DISMISS = 4,
	SYNC_ON_LOGIN = 5,
	SYNC_SILENT_LEAVE = 6,
	SYNC_KICKED = 7,
	SYNC_LRU_REMOVE = 8,
	SYNC_ON_LOGOUT = 9, --// 意外离线
	SYNC_NORMAL_LOGOUT = 10, --// 正常离线
	SYNC_INVITE_LEAVE_TEAM = 11, --// 因为邀请而离队
}
Pb_Enum_TEAM_INCRE_SYNC_REASON = 
{
	INCRE_SYNC_LEAVE_TEAM = 0,
	INCRE_SYNC_ON_LOGOUT = 1, --// 意外离线
	INCRE_SYNC_NORMAL_LOGOUT = 2, --// 正常离线
	INCRE_SYNC_SILENT_LEAVE = 3,
	INCRE_SYNC_KICKED = 4,
	INCRE_SYNC_LEADER_CHANGE = 5,
	INCRE_SYNC_STATUS_CHANGE = 6,
	INCRE_SYNC_MEMBER_NAME_CHANGE = 7,
	INCRE_SYNC_MODE_CHANGE = 8,
	INCRE_SYNC_INVITE_LIST_CHANGE = 9,
	INCRE_SYNC_APPLY_LIST_CHANGE = 10,
	INCRE_SYNC_MERGE_SEND_LIST_CHANGE = 11,
	INCRE_SYNC_MERGE_REVC_LIST_CHANGE = 12,
	INCRE_SYNC_REQUEST_LIST_DEL_ALL = 13,
	INCRE_SYNC_HERO_CHANGE = 14,
	INCRE_SYNC_WEAPON_CHANGE = 15,
	INCRE_SYNC_INVITE_LEAVE_TEAM = 16, --// 因为邀请而离队
}
Pb_Enum_TEAM_SOURCE_TYPE = 
{
	TEAM_SOURCE_TYPE_NONE = 0,
	CHAT_IN_WORLD = 202, --// 公共聊天频道(点击头像添加好友)
	CHAT_IN_TEAM = 205, --// 组队聊天(点击头像添加好友)
	LAYER_SETTLEMENT = 206, --// 结算界面(点击头像添加好友)
	FRIEND_BLACK_LIST = 104, --// 黑名单
	SCORE_HISTORY = 207, --// 历史战绩
	COMMON_HEAD = 300, --// 个人信息
	RECENT_VISITOR = 302, --// 最近访客
	FRIEND_SEARCH_ID = 101, --// 好友搜索
	IN_TEAM_AS_OTAL_STRANGER = 208, --// 组队中(同队陌生人且非同队好友的好友)
	IN_TEAM_AS_FRIENDS_OF_FRIENDS = 209, --// 组队中(同队陌生人且同队好友的好友)
	LAYER_IN_TEAM_RECOMMONDATION1 = 210, --// 组队推荐界面1(好友页签)
	LAYER_IN_TEAM_RECOMMONDATION2 = 211, --// 组队推荐界面2(推荐页签)
}
Pb_Enum_UNLOCK_TYPE = 
{
	UNLOCK_TYPE_INVAILD = 0, --// 无效类型
	UNLOCK_TYPE_LEVEL = 1, --// 等级条件解锁
}
Pb_Enum_WEAPON_SLOT_TYPE = 
{
	WEAPON_SLOT_INVAILD = 0, --// 无效类型
	WEAPON_SLOT_CHIP = 1, --// 芯片
	WEAPON_SLOT_MUZZLE = 2, --// 枪口
	WEAPON_SLOT_GRIP = 3, --// 握把
	WEAPON_SLOT_CLIP = 4, --// 弹夹
	WEAPON_SLOT_STOCK = 5, --// 枪托
	WEAPON_SLOT_SIGHT = 6, --// 瞄具
	WEAPON_SLOT_MAX = 7, --// 最大值
}
