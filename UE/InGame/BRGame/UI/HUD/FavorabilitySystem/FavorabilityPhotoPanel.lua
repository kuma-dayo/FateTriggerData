--
-- 好感度系统 - 日记界面
--
-- @COMPANY	Saros
-- @AUTHOR	朱越
-- @DATE	2024.04.09
--

local FavorabilityPhotoPanel = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------


-------------------------------------------- Init/Destroy ------------------------------------

function FavorabilityPhotoPanel:OnInit()
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

function FavorabilityPhotoPanel:OnDestroy()
	UserWidget.OnDestroy(self)
end

function FavorabilityPhotoPanel:OnShow(Param, Blackboard)
    print("FavorabilityPhotoPanel:InitDataOnShow")

	-- local TexturePath = "Texture2D'/Game/Arts/UI/2DTexture/Favorability/T_Favorability_Photo.T_Favorability_Photo'"

	local TexturePathSelector = UE.FGenericBlackboardKeySelector()
    TexturePathSelector.SelectedKeyName = "TexturePath"
    local TexturePath, Result = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(Blackboard, TexturePathSelector)
    if Result then
        local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(TexturePath)
		if ImageSoftObjectPtr ~= nil then
			print("FavorabilityPhotoPanel:OnShow	加载图片")
			self.GUIImage_154:SetBrushFromSoftTexture(ImageSoftObjectPtr, true)
		end
    end
end

-------------------------------------------- Function ------------------------------------

function FavorabilityPhotoPanel:InitData(InParameters)

end

-------------------------------------------- Callable ------------------------------------

return FavorabilityPhotoPanel
