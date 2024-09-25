DSPb_ProtoList = 
{
	["Common.proto"] = {PrePath="Server/Net/Protocols/",},
	["Datapack.proto"] = {PrePath="Server/Net/Protocols/",},
	["DSMgr.proto"] = {PrePath="Server/Net/Protocols/",},
}

DSPb_Message = 
{
	--Common.proto
	ClientInfo = "ClientInfo",
	AccountInfo = "AccountInfo",
	DeviceInfo = "DeviceInfo",
	LocationInfo = "LocationInfo",

	--Datapack.proto
	MsgHeadNormal = "MsgHeadNormal",
	HandshakeReq = "HandshakeReq",
	HandshakeRsp = "HandshakeRsp",

	--DSMgr.proto
	DSHeartbeatReq = "DSHeartbeatReq",
	DSHeartbeatRsp = "DSHeartbeatRsp",
	GameplayInfoBase = "GameplayInfoBase",
	GameParamSync = "GameParamSync",
	ForkProcessReq = "ForkProcessReq",
	ForkProcessRsp = "ForkProcessRsp",
	TimeConsumingPhaseLoadFinish = "TimeConsumingPhaseLoadFinish",
	ReadyForkProcess = "ReadyForkProcess",
	HeroSkinPartInfo = "HeroSkinPartInfo",
	HeroSkinListBase = "HeroSkinListBase",
	SkinIdListBase = "SkinIdListBase",
	WeaponSkinIdBase = "WeaponSkinIdBase",
	WeaponSkinListBase = "WeaponSkinListBase",
	StickerNode = "StickerNode",
	DisplayBoardInfo = "DisplayBoardInfo",
	FavorInfo = "FavorInfo",
	VehicleStickerNode = "VehicleStickerNode",
	VehicleStickerData = "VehicleStickerData",
	HeroVehicleNode = "HeroVehicleNode",
	PlayerInfoRsp = "PlayerInfoRsp",
	DSSelectHeroRsp = "DSSelectHeroRsp",
	DSSelectSkinRsp = "DSSelectSkinRsp",
	UpdatePlayerInfoSync = "UpdatePlayerInfoSync",
	PlayerExitDSSync = "PlayerExitDSSync",
	KillDSSync = "KillDSSync",
	RegistDSReq = "RegistDSReq",
	GameParamSyncReq = "GameParamSyncReq",
	OnDSCrash = "OnDSCrash",
	PlayerInfoReq = "PlayerInfoReq",
	PlayerRuntimeHeroSync = "PlayerRuntimeHeroSync",
	DSSelectHeroReq = "DSSelectHeroReq",
	DSSelectSkinReq = "DSSelectSkinReq",
	CheckLoginKeyReq = "CheckLoginKeyReq",
	PlayerOnlineStateChangeReq = "PlayerOnlineStateChangeReq",
	BattleWeaponDataBase = "BattleWeaponDataBase",
	BattleSkillDataBase = "BattleSkillDataBase",
	BattleHeroDataBase = "BattleHeroDataBase",
	BattleVehicleDataBase = "BattleVehicleDataBase",
	BattleDataBase = "BattleDataBase",
	SaveBattleDataReq = "SaveBattleDataReq",
	GameStateChangeReq = "GameStateChangeReq",
	PlayerSettlementMsg = "PlayerSettlementMsg",
	KillEventInfo = "KillEventInfo",
	KillsAndDeathsFlow = "KillsAndDeathsFlow",
	PlayerSettlementReq = "PlayerSettlementReq",
	TeamSettlementMsg = "TeamSettlementMsg",
	EarlyTeamSettlementReq = "EarlyTeamSettlementReq",
	TeamSettlementReq = "TeamSettlementReq",
	PlayerReconnectReq = "PlayerReconnectReq",
	PlayerReconnectRsp = "PlayerReconnectRsp",
	BattleSettlementMsg = "BattleSettlementMsg",
	BattleSettlementReq = "BattleSettlementReq",
	CampPlayerSettlementBase = "CampPlayerSettlementBase",
	CampTeamSettlementBase = "CampTeamSettlementBase",
	CampSettlementBase = "CampSettlementBase",
	PlayerInfoBase = "PlayerInfoBase",
	CampSettlementReq = "CampSettlementReq",
	DedicatedServerEndSync = "DedicatedServerEndSync",
	TaskProcessNode = "TaskProcessNode",
	TaskInfoNode = "TaskInfoNode",
	DsTaskDataNotify = "DsTaskDataNotify",
	TaskUpdateProcessNotify = "TaskUpdateProcessNotify",
	DsBuryingPoint = "DsBuryingPoint",
	DsBuryingPointSync = "DsBuryingPointSync",
	DsMetricsReport = "DsMetricsReport",

}

DSPb_Enum_PackFlag = 
{
	PACK_NONE = 0, --// 无包头
	PACK_NORMAL = 1, --// 普通包
	PACK_SERVICE = 2, --// SERVICE包，带路由信息
}
DSPb_Enum_MsgType = 
{
	MSG_NONE = 0, --// 无包头
	MSG_PBRPC = 1, --// PBRPC
	MSG_LUARPC = 2, --// LUARPC
}
DSPb_Enum_CryptoType = 
{
	CRYPTO_NONE = 0, --// 明文
	CRYPTO_BLOWFISH = 1, --// BF
	CRYPTO_RC4 = 2, --// RC4
	CRYPTO_AES = 3, --// AES
}
