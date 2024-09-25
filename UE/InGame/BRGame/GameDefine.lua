--
-- GameDefine
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.04
--

require("Common.Framework.CommFuncs")

local GameDefine = {}


------------------------------------------- Msg ----------------------------------------

-- 消息定义(Lua)
GameDefine.Msg = {
	-- Battle
	BATTLE_ModeState				= "BATTLE_ModeState",

    -- Player
	PLAYER_RespawnXEndRespawn		= "RespawnX.EndRespawn",
	PLAYER_ShowItemDetailInfo		= "PLAYER_ShowItemDetailInfo",
	PLAYER_ShowItemDetailInfo_Deffer	= "PLAYER_ShowItemDetailInfo_Deffer",
	PLAYER_HideItemDetailInfo		= "PLAYER_HideItemDetailInfo",
	PLAYER_HideItemDetailInfo_Deffer	= "PLAYER_HideItemDetailInfo_Deffer",
	PLAYER_OpenSelectItem			= "PLAYER_OpenSelectItem",
	PLAYER_GenericFeedback			= "PLAYER_GenericFeedback",
	PLAYER_InPoisonCircle			= "PLAYER_InPoisonCircle",
	PLAYER_ToggleDropPartOfItem		= "PLAYER_ToggleDropPartOfItem",
	PLAYER_SkillProgressNotifyUI_Start		= "PLAYER_SkillProgressNotifyUI_Start",
	PLAYER_SkillProgressNotifyUI_End		= "PLAYER_SkillProgressNotifyUI_End",
	PLAYER_UpdateRespawnGeneState		= "PLAYER_UpdateRespawnGeneState",
	PLAYER_CursorShowCircleProgress		= "PLAYER_CursorShowCircleProgress",
	PLAYER_CursorHideCircleProgress		= "PLAYER_CursorHideCircleProgress",


	-- InventoryItem
	InventoryItemNumChangeSingle	= "InventoryItem.NumChange.Single",
	InventoryItemNumChangeTotal		= "InventoryItem.NumChange.Total",
	InventoryClearBag				= "InventoryItem.ClearBag",
	InventoryItemMaxNumChange		= "InventoryItem.MaxStack.Change",
	PLAYER_ItemSlots			    = "InventoryItem.Slot.Change",
	InventoryItemClientPreDiscard	= "InventoryItem.ClientPreDiscard",
	InventoryItemWeaponDestroyEnhance	= "InventoryItem.Weapon.DestroyEnhance",
	InventoryItemSlotDragOnDrop 	= "InventoryItem.Slot.DragOnDrop",

	-- Equipment
	EquippedInstance_Spawn			= "Equipment.EquippedInstance.Spawn",
	EquippedInstance_Destroy		= "Equipment.EquippedInstance.Destroy",
	PLAYER_EquipmentHandleChange	= "Equipment.EquipmentHandleChange",

	-- Weapon
	WEAPON_UpdateWeaponPanelBGPic	= "WEAPON_UpdateWeaponPanelBGPic",
	WEAPON_UpdateWeaponBulletNum	= "WEAPON_UpdateWeaponBulletNum",
	WEAPON_WeaponSlotDragOnDrop		= "WEAPON_WeaponSlotDragOnDrop",
	WEAPON_ArmorSlotDragOnDrop		= "WEAPON_ArmorSlotDragOnDrop",
	WEAPON_WearMicroChip			= "WEAPON_WearMicroChip",
	WEAPON_FireModeChange_Clinet	= "Weapon.Event.FireModeChange.Client",


	Attachment_Guide_Start = "Attachment.Guide.Start",
	Attachment_Guide_End = "Attachment.Guide.End",
	
	-- Minimap
	MINIMAP_SizeChanged				= "MINIMAP_SizeChanged",
	MINIMAP_CloseLargemap			= "MINIMAP_CloseLargemap",
	MINIMAP_UpdateMarkRoutePreview	= "MINIMAP_UpdateMarkRoutePreview",

	MINIMAP_StatusChanged			= "UIEvent.OnMapStatusChanged" ,	--Params ： int 0：小地图 1：大地图 2：中地图
	
	-- Largemap
	LARGEMAP_UpdateMapZoomLevel				= "LARGEMAP_UpdateMapZoomLevel",
	LARGEMAP_UpdateMapMarkMod_Moblie		= "LARGEMAP_UpdateMapMarkMod_Moblie",
	LARGEMAP_DeleteMarkPoint_Moblie			= "LARGEMAP_DeleteMarkPoint_Moblie",
	LARGEMAP_MarkMyself						= "LARGEMAP_MarkMyself",
	LARGEMAP_MoveToMyself					= "LARGEMAP_MoveToMyself",
	LARGEMAP_MoveToAssignPos				= "LARGEMAP_MoveToAssignPos",

	-- MarkSystem
	MarkSystem_UpdateSelectMark		= "MarkSystem_UpdateSelectMark",

	-- BuoysSystem
	BuoysSystem_ShowBootyBox		= "BuoysSystem_ShowBootyBox",

	-- SelectPanel
	SelectPanel_Open				= "SelectPanel_Open",
	SelectPanel_Close				= "SelectPanel_Close",

	-- Respawn
	UISync_Select_Respawn_Button = "UISync.Select.RespawnButton",

	-- AdvanceMarkSystem
	AdvanceMarkSystem_Reserve_Item = "AdvanceMarkSystem.ReserveItem",
	AdvanceMarkSystem_Mark_Item = "AdvanceMarkSystem.MarkItem",
	AdvanceMarkSystem_Mark_Point = "AdvanceMarkSystem.MarkPoint",


	AdvanceMarkSystem_Buoys_Remove = "AdvanceMarkSystem.BuoysMark.Remove",

	AdvanceMarkSystem_Mark_PlayLine = "AdvanceMarkSystem.PlayLine.Update",
	AdvanceMarkSystem_Mark_PlayLineRemove = "AdvanceMarkSystem.PlayLine.Remove",

	AdvanceMarkSystem_Mark_OrdinaryLine = "AdvanceMarkSystem.OrdinaryLine.Update",
	AdvanceMarkSystem_Mark_OrdinaryLineRemove = "AdvanceMarkSystem.OrdinaryLine.Remove",

	-- Settlement
	SETTLEMENT_PlayerSettlementComplate = "SETTLEMENT_PlayerSettlementComplate",

	-- BagUI
	BagMobile_ShowItemDetail = "BagMobile_ShowItemDetail",
	BagMobile_HideItemDetail = "BagMobile_HideItemDetail",
	BagMobile_HideItemButton = "BagMobile_HideItemButton",
	BagMobile_ShowDropAmount = "BagMobile_ShowDropAmount",
	BagMobile_HideDropAmount = "BagMobile_HideDropAmount",

	-- OB UI
	OB_Refresh_PlayerCard = "OB_Refresh_PlayerCard",
	OB_Refresh_PlayerDeath = "OB_Refresh_PlayerDeath",
}
SetErrorIndex(GameDefine.Msg)


-- 消息定义(C++)
GameDefine.MsgCpp = {
	-- GameMode
	GAMEMODE_Plane					= "GameMode.Plane",
	GAMEMODE_PlaneStartCruise		= "GameMode.Plane.StartCruise",
	GAMEMODE_PlaneCanJump			= "GameMode.Plane.CanJump",
	GAMEMODE_PlaneForceJump			= "GameMode.Plane.ForceJump",
	GAMEMODE_PlaneEndCruise			= "GameMode.Plane.EndCruise",

	-- GameState
	GAMESTATE_PlayerStateAdd		= "GameState.PlayerState.Add",
	GAMESTATE_PlayerStateRemove		= "GameState.PlayerState.Remove",
	GAMESTATE_EnterState			= "GameState.BR.PostEnterState",
	GAMESTATE_LeaveState			= "GameState.BR.PostLeaveState",
	GAMESTATE_RingShipChanged		= "GameState.Changed.RingShip",
	GAMESTATE_CurrentFlightChanged	= "GameState.Changed.CurrentFlight",
	GAMESTATE_GameFlowStateChange  	= "GameState.GameFlowStateChange",
	GAMESTATE_DFGameProgressChange  	= "GameState.DFGameProgressInfoChanged",

	-- Statistic
	Statistic_RepDatas				= "GenericStatistic.Update.RepDatas",
	Statistic_RepDatasPS			= "GenericStatistic.Update.RepDatasPS",
	Statistic_RepDatasGS			= "GenericStatistic.Update.RepDatasGS",
	TeamExSystemInfo_RemainTeamNumChange = "TeamExSubsystemState.RemainTeamNumChange",
	PlayerExSubsystemState_NumberOfPlayersChange = "PlayerExSubsystemState.NumberOfPlayersChange",
	Statistic_BattleRecord          = "GenericStatistic.Msg.BattleRecord",
	ViewPlayerBattleRecord 			= "UISync.Update.ViewPlayerBattleRecord",
	GenericStatistic_DamageList = "GenericStatistic.Msg.DamageList",

	ForceUpdateScore			 	= "GMP.Camp.ForceUpdateScore",
	OccupyingPercentChanged			= "GMP.ConquestZone.OccupyingPercentChanged",
	ZoneOwnerCampIdChanged			= "GMP.ConquestZone.ZoneOwnerCampIdChanged",
	ZoneStateChanged			 	= "GMP.ConquestZone.ZoneStateChanged",
	ZonePlayerChanged				= "GMP.ConquestZone.ZonePlayerChanged",
	OccupyingCampIdChanged			= "GMP.ConquestZone.OccupyingCampIdChanged",

	-- ObserveX
	ObserveX_TryActivate = "ObserveX.System.TryActivate",

	-- GUV Root 模式相关消息
	GUV_BRReview_Exit = "GUV.BRReview.Exit",
	GUV_BRReview_Continue = "GUV.BRReview.Continue",

	-- Inventory
	INVENTORY_ItemOnNew = "InventoryItem.OnNew",
	INVENTORY_ItemOnNewPost = "InventoryItem.OnNewPost",
	INVENTORY_ItemOnDestroy = "InventoryItem.OnDestroy",
	INVENTORY_ItemOnNew_Helmet = "InventoryItem.OnNew.Helmet",
	INVENTORY_ItemOnDestroy_Helmet = "InventoryItem.OnDestroy.Helmet",
	INVENTORY_ItemOnNew_Bag ="InventoryItem.OnNew.Bag",
	INVENTORY_ItemOnDestroy_Bag = "InventoryItem.OnDestroy.Bag",
	INVENTORY_ItemOnNew_Armor = "InventoryItem.OnNew.Armor",
	INVENTORY_ItemOnDestroy_Armor = "InventoryItem.OnDestroy.Armor",
	INVENTORY_ItemOnNew_Currency ="InventoryItem.OnNew.Currency",
	INVENTORY_ItemOnDestroy_Currency ="InventoryItem.OnDestroy.Currency",
	INVENTORY_ItemOnStackNum_Change_Currency="InventoryItem.StackNum.Change.Currency",

	-- InventoryEnhance
	INVENTORY_Enhance_Update = "InventoryItem.EnhanceSystem.EnhanceIdUpdate",

	-- InventorySlot
	-- "InventoryItem.Slot.Change" 目前的名字是 GameDefine.Msg.PLAYER_ItemSlots
	INVENTORY_InventoryItemSlot_Change_Armor = "InventoryItem.Slot.Change.Armor",
	INVENTORY_InventoryItemSlot_Change_Bag = "InventoryItem.Slot.Change.Bag",
	INVENTORY_InventoryItemSlot_Change_Helmet = "InventoryItem.Slot.Change.Helmet",
	INVENTORY_InventoryItemSlot_Change_Potion = "InventoryItem.Slot.Change.Potion",
	INVENTORY_InventoryItemSlot_Change_Throwable = "InventoryItem.Slot.Change.Throwable",
	INVENTORY_InventoryItemSlot_Change_Weapon = "InventoryItem.Slot.Change.Weapon",
	INVENTORY_InventoryItemSlot_Reset = "InventoryItem.Slot.Reset",

	INVENTORY_EQUIPPABLE_ONREP_WEAPON = "InventoryItem.Equippable.OnRep.Weapon",
	

	-- Inventory Weapon Attachment
	INVENTORY_WeaponAttachment_UIUpdate_Attach = "InventoryItem.WeaponAttachment.UIUpdate",

	-- Playzone
	PLAYZONE_Beginplay				= "Playzone.Changed.Beginplay",
	PLAYZONE_PlayzoneDataChange		= "Playzone.Changed.PlayzoneData",

	RING_RunningChange				= "Ring.RunningChange",
	RING_StateChange				= "Ring.StateChange",

	RING_ShowScanedPlayzone			= "ScanTower.ShowNextCircle",
	RING_HideScanedPlayzone			= "ScanTower.HideAll",
	
	-- PlayerController
	PC_UpdatePlayerState			= "PlayerController.Update.PlayerState",
	PC_UpdatePlayerPawn				= "PlayerController.Update.Pawn",

	PC_InputKeyDown_N				= "PlayerController.InputKeyDown.N",
	PC_InputKeyDown_Delete			= "PlayerController.InputKeyDown.Delete",
	PC_InputKeyUp_Alt				= "PlayerController.InputKeyUp.Alt",
	PC_Input_SetMapMarkRoute		= "EnhancedInput.SetMapMarkRoute",
	PC_Input_SwitchFullMap			= "EnhancedInput.SwitchFullMap",
	PC_Input_ScaleMap				= "EnhancedInput.ScaleMap",
	PC_Input_ScaleMapEnLarge_Gamepad= "EnhancedInput.ScaleMap.EnLargeGamepad",
	PC_Input_ScaleMapReduce_Gamepad = "EnhancedInput.ScaleMap.ReduceGamepad",
	PC_Input_DelMapMark				= "EnhancedInput.DelMapMark",
	PC_Input_ResetMapCursor			= "EnhancedInput.ResetMapCursor",
	PC_Input_SelectMedicines		= "EnhancedInput.SelectMedicines",
	PC_Input_SelectMedicinesEnd		= "EnhancedInput.SelectMedicinesEnd",
	PC_Input_SelectThrow			= "EnhancedInput.SelectThrow",
	PC_Input_SelectThrowEnd			= "EnhancedInput.SelectThrowEnd",
	PC_Input_SelectItemMark			= "EnhancedInput.SelectItemMark",
	PC_Input_SelectItemConfirm	    = "EnhancedInput.SelectItemConfirm",
	PC_Input_SelectItemCancel	    = "EnhancedInput.SelectItemCancel",
	PC_Input_UISwitch				= "EnhancedInput.UISwitch",
	PC_Input_MarkSystemPoint		= "EnhancedInput.MarkSystem.MarkPoint",
	PC_Input_MarkSystemEnemy		= "EnhancedInput.MarkSystem.MarkEnemy",
	PC_Input_MarkSystemSelect		= "EnhancedInput.MarkSystem.MarkSelect",
	PC_Input_MarkSystemSelectEnd	= "EnhancedInput.MarkSystem.MarkSelectEnd",
	PC_Input_SwitchInputHintShow    = "EnhancedInput.SwitchInputHintShow",
	PC_Input_OB_Accusation 			= "EnhancedInput.OB.Accusation",
	PC_Input_OB_ShowPlayerFlag 	    = "EnhancedInput.OB.ShowPlayerFlag",
	PC_Input_OB_RemindFlagLocation  = "EnhancedInput.OB.RemindFlagLocation",
	PC_Input_OB_ReturnLobby 		= "EnhancedInput.OB.ReturnLobby",
	PC_Input_Review_Exit			= "EnhancedInput.ExitReview",
	PC_Input_Review_Continue		= "EnhancedInput.ContinueReview",
	PC_Input_ItemCombination        = "EnhancedInput.ChooseItemCombinationUI",
	PC_Input_RebornSpaceUI_Start	= "Enhancedinput.RebornSpaceUI.Start",
	PC_Input_RebornSpaceUI_Triggered= "Enhancedinput.RebornSpaceUI.Triggered",
	PC_Input_RebornSpaceUI_Completed= "Enhancedinput.RebornSpaceUI.Completed",
	PC_Input_RebornSpaceUI_Canceled = "Enhancedinput.RebornSpaceUI.Canceled",
	PC_Input_OB_TogglePlayerCard 	= "EnhancedInput.OB.TogglePlayerCard",
	PC_Input_OB_ToggleDeathInfo 	= "EnhancedInput.OB.ToggleDeathInfo",

	-- Player
	PLAYER_PSPawn					= "PlayerState.Update.Pawn",
	PLAYER_PSTeamId					= "PlayerState.Update.TeamId",
	PLAYER_PSTeamPos				= "PlayerState.Update.TeamPos",
	PLAYER_TeammatePSList			= "PlayerState.Update.TeammatePSList",
	PLAYER_PSHealth					= "PlayerState.Update.Health",
	PLAYER_PSName					= "PlayerState.Update.PlayerName",
	PLAYER_PSAlive					= "PlayerState.Update.Alive",
	PLAYER_PSDeadTimeSec			= "PlayerState.Update.DeadTimeSec",
	PLAYER_PSRespawnGeneCollectState= "PlayerState.Update.RespawnGeneCollectState",
	PLAYER_PSRespawnGeneDeployState	= "PlayerState.Update.RespawnGeneDeployState",
	PLAYER_PSUpdateRespawnGeneState	= "PlayerState.Update.RespawnGeneState",
	PLAYER_CollectGenePlayerId 		= "PlayerState.Update.CollectGenePlayerIds",

	PLAYER_WeaponState				= "GMP.Weapon.StateChanged",
	PLAYER_SkillBuffChanged			= "Skill.Changed.ActiveBuff",
	PLAYER_BuffTagChanged			= "Buff.Changed.BuffTag",
	PLAYER_BuffCurLevelChanged		= "Buff.Changed.CurrentLevel",
	PLAYER_HealthShowPreview		= "Player.Health.ShowPreview",
	PLAYER_GenericItemUseProgress  ="Player.Generic.ItemUseProgress",
	
	GenericStatistic_Msg_SpecificCampData = "GenericStatistic.Msg.SpecificCampData",
	ObserveX_System_BecomeObserver  = "ObserveX.System.BecomeObserver",
	-- 团队竞技
	GMP_Camp_ScoreChanged = "GMP.Camp.ScoreChanged",

	-- 濒死/救援
	--PLAYER_DyingGodRule				= "LifetimeManager.DyingGodRule",
	PLAYER_OnBeginBeingRescue		= "LifetimeManager.OnBeginBeingRescue",
	PLAYER_OnBeginDead				= "LifetimeManager.OnBeginDead",
	PLAYER_OnBeginDying				= "LifetimeManager.OnBeginDying",
	PLAYER_OnEndBeingRescue			= "LifetimeManager.OnEndBeingRescue",
	PLAYER_OnEndDead				= "LifetimeManager.OnEndDead",
	PLAYER_OnEndDying				= "LifetimeManager.OnEndDying",
	PLAYER_UpdateDeadCountdown		= "LifetimeManager.UpdateDeadCountdown",
	
	PLAYER_OnBeginRescue			= "RescueManager.OnBeginRescue",
	PLAYER_OnEndRescue				= "RescueManager.OnEndRescue",
	PLAYER_OnRescuing				= "RescueManager.OnRescuing",
	PLAYER_OnRescueActorChanged		= "RescueManager.OnBestBeingRescueActorChanged",

	-- 复活
	PLAYER_OnBeginRespawn			= "RespawnX.BeginRespawn",
	PLAYER_OnEndRespawn				= "RespawnX.EndRespawn",
	PLAYER_OnGeneProgressChange 	= "BootyBox.CurrentProgressChange",
	RespawnX_RuleCollect            = "RespawnX.RuleCollect",

	-- Character
	CHARACTER_WeaponStanceChanged	= "Character.WeaponStanceChanged",

	-- Skill
	SKILL_Start						= "SkillComp.Skill.Start",
	SKILL_End						= "SkillComp.Skill.End",
	SKILL_Activate                  = "GeSkill.Ability.SkillStart",
    SKILL_SkillCost                 = "GeSkill.Ability.CommitCost",
	SKILL_SkillCooldown             = "GeSkill.Ability.CommitCooldown",
	

	-- Weapon
	WEAPON_StateEnter 						= "Weapon.StateEnter",
	WEAPON_StateLeave 						= "Weapon.StateLeave",

	WEAPON_UpdateMagazineConfig				= "Weapon.Update.MagazineConfig",
	WEAPON_UpdateMagMaxBullet				= "Weapon.Update.MagMaxBullet",

	WEAPON_GWSAttachmentEffectOnPreAttached		= "GWSAttachmentEffect.OnPreAttached",
	WEAPON_GWSAttachmentEffectOnPostAttached 	= "GWSAttachmentEffect.OnPostAttached",
	WEAPON_GWSAttachmentEffectOnPreDetached 	= "GWSAttachmentEffect.OnPreDetached",
	WEAPON_GWSAttachmentEffectOnPostDetached 	= "GWSAttachmentEffect.OnPostDetached",
	WEAPON_SwitchFireMode 						= "Player.Weapon.SwitchFireMode",
	WEAPON_WeaponMagUpdate						= "Weapon.Event.MagUpdated.Client",

	WEAPON_GAW_AttachmentStateChange		= "GAWAttachmentEffect.OnAttachmentStateChange",
	WEAPON_SKIN_ATTACH_SUCCEED		= "Weapon.Event.AvatarAttachSucceed",

	WEAPON_Functionality_TolBullet_OnEnableDisable = "Weapon.Functionality.TolBullet.OnEnableDisable",
	WEAPON_InventoryItem_CreateEnhance = "InventoryItem.Weapon.CreateEnhance",

	-- Bag
	BAG_WhenShowHideBag				= "UIEvent.BagEvent",
	BAG_FeatureSetUpdate 			= "Bag.FeatureSet.Update",
	BAG_WeightOrSlotNum				= "Bag.WeightOrSlotNum.Update",
	BAG_OnEscTriggerBagUI			= "UIEvent.OnEscTriggerBagUI",
	BAG_InventoryItemInfinitePotion = "InventoryItem.Infinite.Potion",
	BAG_InventoryItemInfiniteProjectile = "InventoryItem.Infinite.Projectile",
	
	-- Bag Gamepad
	BagUI_DiscardAndPickPart  = "Enhancedinput.BagUI.GamepadDiscardAndPickPart",
	BagUI_DiscardAndPickHalf  = "Enhancedinput.BagUI.GamepadDiscardAndPickHalf",
	BagUI_DiscardAndPickAll   = "Enhancedinput.BagUI.GamepadDiscardAndPickAll",
	BagUI_DiscardPopTip       = "Enhancedinput.BagUI.GamepadDiscardPopTip",
	BagUI_UseItem 	          =  "Enhancedinput.BagUI.GamepadUseItem", 
	BagUI_DiscardAndPickHalfStart  = "Enhancedinput.BagUI.GamepadDiscardAndPickHalf.Start",
	BagUI_DiscardAndPickHalfCancel  = "Enhancedinput.BagUI.GamepadDiscardAndPickHalf.Cancel",

	-- UISync
	UISync_UpdateMarkData			= "UISync.Update.MarkData",
	UISync_UpdateMarkRouteData		= "UISync.Update.MarkRouteData",
	UISync_UpdateUnitMarkData		= "UISync.Update.UnitMarkData",
	--UISync_UpdateMarkSystemPoint	= "UISync.Update.MarkSystemPoint",
	UISync_UpdateOpenFireStatus     = "UISync.Update.OpenFireStatus",
	UISync_UpdateSkillStatus        = "UISync.Update.SkillStatus",
	UISync_UpdateOnBeginDying       = "UISync.Update.OnBeginDying",
	UISync_UpdateOnDead      		= "UISync.Update.OnDead",
	UISync_UpdateOnRescueMe         = "UISync.Update.OnRescueMe",
	UISync_UpdateOnDrive			= "UISync.Update.OnDrive",
	UISync_UpdateOffLine			= "UISync.Update.IsOffLine",
	UISync_UpdateRecoveryMaxArmor	= "UISync.Update.RecoveryMaxArmor",
	UISync_UpdatePlayerDamageList   = "UISync.Update.PlayerDamageList",
	UISync_Update_HeroTypeId		="UISync.Update.HeroTypeId",
	UISync_Update_LocalPlayerBattleRecord = "UISync.Update.LocalPlayerBattleRecord",
	UISync_Update_FreshEnhanceId = "UISync.Update.FreshEnhanceId",
	UISync_Update_ParachuteRespawnStart = "UISync.Update.ParachuteRespawnStart",
	UISync_Update_ParachuteRespawnFinished = "UISync.Update.ParachuteRespawnFinished",
	UISync_Update_ParachuteRespawnRuleEnd = "UISync.Update.ParachuteRespawnRuleEnd",
	UISync_Update_RuleActiveTimeSec = "UISync.Update.RuleActiveTimeSec",
	UISync_Update_RuntimeHeroId = "UISync.Update.RuntimeHeroId",
	-- UIEvent
	UIEvent_Update_DisConnect		= "UIEvent.Update.DisConnect",
	UIEvent_Update_ReConnect		= "UIEvent.Update.ReConnect",


	-- MarkSystem
	MarkSystem_UpdateMarkPoint		= "MarkSystem.Update.MarkPoint",
	MarkSystem_RemoveMarkPoint		= "MarkSystem.Remove.MarkPoint",
	MarkSystem_HitTraceSucc			= "MarkSystem.HitTrace.Succ",
	MarkSystem_HitTraceFail			= "MarkSystem.HitTrace.Fail",

	-- BuoysSystem
	BuoysSystem_UpdateExpand		= "BuoysSystem.Update.Expand",
	
	-- Minimap
	Minimap_UpdateExpandItem		= "MinimapSystem.Update.Expand",		-- form cpp
	Minimap_NotifyUpdateWidget		= "MinimapSystem.NotifyUpdateWidget",	-- from lua
	Minimap_UpdateZoomLevel			= "MinimapSystem.Update.ZoomLevel",		-- to cpp

	Minimap_OpenLargeMapByGamepad   = "MinimapSystem.OpenLargeMapByGamepad", --temp，手柄打

	-- MinimapManagerSystem
	MiniMapTextureUpdate			= "MinimapManagerSystem.Update.MapTexture",		-- form cpp

	-- Mobile Input
	UI_MobileInput_ADS             	= "UI.MobileInput.ADS",
	UI_MobileInput_MarkStick		= "UI.MobileInput.MarkStick",
	UI_MobileInput_MarkStickEnd		= "UI.MobileInput.MarkStickEnd",

	UI_SkillDesc_SkillDetail_Down = "UI.SkillDesc.SkillDeatail.Down",
	UI_SkillDesc_SkillDetail_Up = "UI.SkillDesc.SkillDeatail.Up",
	UI_SkillDesc_LeftOffset = "UI.SkillDesc.LeftOffset",
	UI_SkillDesc_RightOffset = "UI.SkillDesc.RightOffset",

	-- Respawn
	Respawn_Gene_Collect			= "Respawn.Gene.Collect",

	--GenericStatistic
	GenericStatistic_Msg_ShowProperty = "GenericStatistic.Msg.ShowProperty",
	GenericStatistic_Msg_ShowExtraProperty = "GenericStatistic.Msg.ShowExtraProperty",

	--GenericMission
	GenericMission_Msg_ShowMission = "GenericMission.Msg.ShowMission",

	-- 击杀流水
	GenericStatistic_Msg_KillList = "GenericStatistic.Msg.KillList",
	GenericStatistic_Msg_HitDown  = "GenericStatistic.Msg.HitDown",
	-- 语音
	BattleChat_OnOpenOrCloseVoiceChat = "BattleChat.OnOpenOrCloseVoiceChat",
	BattleChat_OnAddRoomMemberInfo = "BattleChat.OnAddRoomMemberInfo",
	-- 文字聊天
	BattleChat_OnRefreshIngameChatBox = "BattleChat.OnNewMessageCome",
	BattleChat_OnStartMsgChat = "EnhancedInput.TeamChat.StartMsgChat",
	-- 换弹
	Character_Gun_Reload_Tac_OnTagEvent = "AnimSet.Gun.Reload.Tac.OnTagEvent",
	Character_Gun_Reload_Full_OnTagEvent = "AnimSet.Gun.Reload.Full.OnTagEvent",
	Character_Gun_Reload_OnTagEvent = "Character.Gun.Reload.OnTagEvent",
	Character_Gun_Fire_Burst_OnTagEvent = "Character.Gun.Fire.Burst.OnTagEvent",
	--过载芯片
	CHARACTER_Gun_BloodBullet_OnTagEvent ="Character.Gun.BloodBullet.OnTagEvent",

	-- 滑翔相关
	Character_BRState_Parachute_Glide_OnTagEvent = "Character.BRState.Parachute.Glide.OnTagEvent",
	Character_BRState_Parachute_Skydive_OnTagEvent = "Character.BRState.Parachute.Skydive.OnTagEvent",

	-- 角色载具相关
	Character_Vehicle_Driver_OnTagEvent = "Character.Vehicle.Driver.OnTagEvent",
	Character_Vehicle_LeanOut_OnTagEvent = "Character.Vehicle.LeanOut.OnTagEvent",
	Character_Vehicle_Passenger_OnTagEvent = "Character.Vehicle.Passenger.OnTagEvent",

	-- 角色姿态
	Character_Stance_Dying_OnTagEvent = "Character.Stance.Dying.OnTagEvent",
	Character_Stance_Dead_OnTagEvent = "Character.Stance.Dead.OnTagEvent",

	--下发武器
	Give_Item_Combination = "GUV.GiveItemCombiantionGroup",
	TeamCompetition_Start = "GUV.TeamCompetition.Start",
	TeamCompetition_End ="GUV.TeamCompetition.End",

	-- Scoreboard 计分板
	SCOREBOARD_UPDATE_CampSharedInfoParams = "Scoreboard.Update.CampSharedInfoParams",

	-- 游玩游戏模式的次数
	PlayGameModeCountResponse = "Response.PlayGameModeCountResponse",

	-- 伤害系统
	GDS_OnAnyAttrubuteChange = "GDS.Event.AnyChange",

	-- 转盘
	SelectAvatarAction_GamepadLeftShoulder				= "EnhancedInput.SelectAvatarAction.GamepadLeftShoulder",
	SelectAvatarAction_GamepadRightShoulder				= "EnhancedInput.SelectAvatarAction.GamepadRightShoulder",

}
SetErrorIndex(GameDefine.MsgCpp)


-- 名字定义
GameDefine.NName = {
	-- Common
	NAME_Default       				= "Default",

	NAME_Revealed       			= "RevealedByHero01",


}
SetErrorIndex(GameDefine.NName)


-- 标签名
GameDefine.NTag = {
	-- GameState
	GAMESTATE_EnteringMap       	= "GameState.BR.EnteringMap",
	GAMESTATE_WarmingUp       		= "GameState.BR.WarmingUp",
	GAMESTATE_InProgress      		= "GameState.BR.InProgress",
	GAMESTATE_GameOver        		= "GameState.BR.GameOver",
	GAMESTATE_Recycle        		= "GameState.BR.Recycle",
	
	-- Character
	CHARACTER_GunFire				= "Character.Gun.Fire",
	CHARACTER_GunTryFire			= "Character.Gun.TryFire",
	CHARACTER_GunAimDownSight       = "Character.Gun.AimDownSight",
	CHARACTER_GunAimOverShoulder	= "Character.Gun.AimOverShoulder",
	CHARACTER_GunHipFiring			= "Character.Gun.HipFiring",

	CHARACTER_AliveState			= "Character.BaseState.Alive",
	CHARACTER_DeadState				= "Character.BaseState.Dead",
	CHARACTER_BeingRescueState		= "Character.BRState.BeingRescue",
	CHARACTER_DyingState			= "Character.BRState.Dying",
	CHARACTER_RescueState			= "Character.BRState.Rescue",
	CHARACTER_OnRideState			= "Character.BRState.OnRide",
	CHARACTER_OnShipState			= "Character.BRState.OnShip",
	CHARACTER_ParachuteState		= "Character.BRState.Parachute",

	CHARACTER_ShowInventory			= "Character.Action.ShowInventory",

	-- Weapon
	WEAPON_HitActorForUI			= "GMP.Weapon.HitActorForUI",
	WEAPON_AttachSlot_Barrel		= "Weapon.AttachSlot.Barrel",
	WEAPON_AttachSlot_FrontGrip		= "Weapon.AttachSlot.FrontGrip",
	WEAPON_AttachSlot_Optics		= "Weapon.AttachSlot.Optics",
	WEAPON_AttachSlot_Mag			= "Weapon.AttachSlot.Mag",
	WEAPON_AttachSlot_Stocks		= "Weapon.AttachSlot.Stocks",
	WEAPON_AttachSlot_HopUp			= "Weapon.AttachSlot.HopUp",

	-- WeaponSkin
	WEAPON_SKIN_ATTACHSLOT_GUNBODY	= "Weapon.AttachSlot.GunBody",

	-- Infinite
	ABILITY_INFINITE_POTION			= "GameplayAbility.GMS_CH.Gameplay.Infinite.InfinitePotion",
	ABILITY_INFINITE_PROJECTILE		= "GameplayAbility.GMS_CH.Gameplay.Infinite.InfiniteProjectile",

	-- Equipment
	Equipment_ActivelyEquip			= "Equipment.Actively.Equip",
	Equipment_ActivelyUnEquip		= "Equipment.Actively.UnEquip",
	Equipment_EquippableSwitchSpeed_Equip = "Character.EquippableSwitchSpeed.Equip",
	Equipment_EquippableSwitchSpeed_UnEquip = "Character.EquippableSwitchSpeed.UnEquip",
	Equipment_EquippableSwitchSpeed_Equip_Instant = "Character.EquippableSwitchSpeed.Equip.Instant",
	Equipment_EquippableSwitchSpeed_Equip_Normal = "Character.EquippableSwitchSpeed.Equip.Normal",
	Equipment_EquippableSwitchSpeed_UnEquip_Instant = "Character.EquippableSwitchSpeed.UnEquip.Instant",
	Equipment_EquippableSwitchSpeed_UnEquip_Normal = "Character.EquippableSwitchSpeed.UnEquip.Normal",
	
	-- Table
	TABLE_EnhanceAttribute = "Table.EnhanceAttribute",
}
SetErrorIndex(GameDefine.NTag)


-- 统计标签名
GameDefine.NStatistic = {
	-- Statistic
	PlayerRanking					= "Statistic.Player.Ranking",
	PlayerTeamRanking				= "Statistic.Player.TeamRanking",
	PlayerKill						= "Statistic.Player.Kill",
	PlayerTeamKill					= "Statistic.Player.TeamKill",

}
SetErrorIndex(GameDefine.NStatistic)


GameDefine.DragActionSource = {
	BagZoom = 1,
	EquipZoom = 2,
	PickZoom = 3
}
SetErrorIndex(GameDefine.DragActionSource)

GameDefine.DropAction = {
	PURPOSE_Pick = 1,
	PURPOSE_Discard = 2,
	PURPOSE_Equip = 3,
	PURPOSE_UnEquip = 4
}
SetErrorIndex(GameDefine.DropAction)

GameDefine.InstanceIDType = {
	ItemInstance = 1,
	PickInstance = 2,
	WeaponInstance = 3,
	AttachmentInstance = 4
}
SetErrorIndex(GameDefine.InstanceIDType)

GameDefine.NItemAttribute = {
	IsUsing = "IsUsing",
	AttachmentHandleID = "AttachmentHandleID",
	WeaponHandleID = "WeaponHandleID",
	PreDetachAttachmentBulletNum = "PreDetachAttachmentBulletNum",

	-- 物品来源：初始来源
	Name_OriginalSource = "OriginalSource",
	-- 物品来源：最近来源
	Name_LastSource = "LastSource",
	-- 物品来源：来源的值（FString）
	Value_ItemSource_PickUpAirDrop = "PickUpAirDrop",
	Value_ItemSource_PickUpNormal = "PickUpNormal",
}
SetErrorIndex(GameDefine.NItemAttribute)

GameDefine.NItemSubTable = {
	Ingame = "Ingame"
}
SetErrorIndex(GameDefine.NItemSubTable)

-- 处理新的 ItemConfig 表的重构
GameDefine.NIngameItemMapCategory = {
	Weapon = "3",
	Vehicle = "4",
	Equipment = "98",
	Consumables = "99"
}
SetErrorIndex(GameDefine.NIngameItemMapCategory)

GameDefine.NInputKey = {
	LeftMouseButton = "LeftMouseButton",
	RightMouseButton = "RightMouseButton",
	MiddleMouseButton = "MiddleMouseButton"
}

GameDefine.TouchType = {
	None = 1,
    Selected = 2,
    Drag = 3
}
SetErrorIndex(GameDefine.TouchType)

------------------------------------------- Enum ----------------------------------------


------------------------------------------- Require ----------------------------------------

_G.GameDefine = GameDefine

require ("InGame.BRGame.UI.Minimap.MinimapHelper")
require ("InGame.BRGame.UI.HUD.GenericTips.GenericTipsHelper")

return GameDefine
