--
-- 战斗主界面
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.04.07
--

local BattlePanel = Class("Common.Framework.UserWidget")

local ESelectItemType = UE.ESelectItemType
local SelectConsumableItemProxy = require("InGame.BRGame.UI.HUD.SelectItem.SelectConsumableItemProxy")


-------------------------------------------- Init/Destroy ------------------------------------

function BattlePanel:OnInit()
	print("BattlePanel", string.format(">> %s:OnInit, ...", GetObjectName(self)))

	--
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)

    self.BindNodes = {
    }
	-- self.MsgList = {
    --     { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState,	        Func = self.OnUpdateLocalPCPS,      bCppMsg = true,	WatchedObject = nil },
    -- }

    self.IsFirstOpenSelectItemPanel = true     -- 标记当前是否是第一次打开轮盘

	UserWidget.OnInit(self)

    -- 动态创建布局
    if self.bDynamicCreateWidget then
        UIHelper.CreateBattleLayouts(self)
    end
    -- DebugDll
    UE.UGFUnluaHelper.DebugDll()
end

function BattlePanel:OnDestroy()
    MsgHelper:UnregisterList(self, self.MsgList_Pawn or {})

	UserWidget.OnDestroy(self)
end

-------------------------------------------- Function ------------------------------------

-------------------------------------------- Callable ------------------------------------

-- 本地玩家更新改变PS
-- function BattlePanel:OnUpdateLocalPCPS(InLocalPC, InOldPS, InNewPS)
-- 	print("BattlePanel", ">> OnUpdateLocalPCPS, ", GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS))
-- 	if self.LocalPC == InLocalPC then
-- 		self:OnUpdateStatistic(InNewPS)
-- 	end
-- end

-- -- 响应角色更新统计数据
-- function BattlePanel:OnUpdateStatistic(InPlayerState, InStatisticComp)
--     print("BattlePanel", ">> OnUpdateStatistic, Start ", 
--         GetObjectName(self.LocalPC.PlayerState), GetObjectName(InPlayerState), GetObjectName(InStatisticComp))

--     -- if self.LocalPC and (self.LocalPC:IsOriginalPlayerState(InPlayerState)) then
--     --     local NumTeamRanking = UE.UGenericStatics.GetRepStackCount(InPlayerState, GameDefine.NStatistic.PlayerTeamRanking, 0)
--     --     print("BattlePanel", ">> OnUpdateStatistic, Exec ", NumTeamRanking)
--     --     if NumTeamRanking > 0 then
--     --         -- 关闭战斗面板等/胜利失败结算
--     --         local UIManager = UE.UGUIManager.GetUIManager(self)
--     --         UIManager:CloseAllWidget(true)
--     --         UIManager:ShowByKey("UMG_SettlementPanel")
--     --     end
--     -- end
-- end

return BattlePanel
