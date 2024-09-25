--
-- 消息
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2021.12.13
--

local MsgDefine = {
	-- Network
	NET_SocketError							= "NET_SocketError",
	NET_Disconnected 						= "NET_Disconnected",
	NET_EngineVersionError 					= "NET_EngineVersionError",

	-- Common
	LEVEL_PreLoadMap						= "LEVEL_PreLoadMap",
	LEVEL_PostLoadMapWithWorld				= "LEVEL_PostLoadMapWithWorld",
	LEVEL_ActorSpawned						= "LEVEL_ActorSpawned",

	-- Login
	LOGIN_Successful 						= "LOGIN_Successful",

	-- RoleInfo
	ROLE_ModifyName 						= "ROLE_ModifyName",

	-- Settlement 
	SETTLEMENT_PlayerSettlement						= "SETTLEMENT_PlayerSettlement",
	SETTLEMENT_TeamSettlement 						= "SETTLEMENT_TeamSettlement",
	SETTLEMENT_GameSettlement						= "SETTLEMENT_GameSettlement",
	SETTLEMENT_CampSettlement						= "SETTLEMENT_CampSettlement",
	SETTLEMENT_CacheObserverData					= "SETTLEMENT_CacheObserverData",
	SETTLEMENT_ShowObserverInfo					= "SETTLEMENT_ShowObserverInfo",
}
SetErrorIndex(MsgDefine)

return MsgDefine
