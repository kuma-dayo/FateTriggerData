--
-- 好感度系统 - 日记界面
--
-- @COMPANY	Saros
-- @AUTHOR	朱越
-- @DATE	2024.04.09
--

local FavorabilityDiaryPanel = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------


-------------------------------------------- Init/Destroy ------------------------------------

function FavorabilityDiaryPanel:OnInit()
	-- self.MiscConfigTable = {
	-- 	{ Tag = GameDefine.NStatistic.PlayerRanking,	TxtKey = "PlayerRanking" },
	-- }

    -- local TextStr = G_ConfigHelper:GetStrTableRow(ConfigDefine.StrTable.InGameUI, "Settlement_ReturnLobby")
    -- self.TxtCfgReturnLobby = TextStr or "RetureLobby(%ds)"

	-- self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
	-- self.LocalPC.bShowMouseCursor = true
	
	-- self.BindNodes = {
	-- 	{ UDelegate = self.BtnReturnLobby.OnClicked, Func = self.OnClicked_ReturnLobby },
	-- }

    -- self.MsgList = {
	-- }

	self:InitData()
	UserWidget.OnInit(self)
end

function FavorabilityDiaryPanel:OnDestroy()
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Function ------------------------------------

function FavorabilityDiaryPanel:InitData(InParameters)

end

-------------------------------------------- Callable ------------------------------------

return FavorabilityDiaryPanel
