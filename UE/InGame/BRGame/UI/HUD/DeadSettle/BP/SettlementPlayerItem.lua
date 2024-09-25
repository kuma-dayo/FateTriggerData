--
-- 战斗界面 - 结算详情界面
--
-- @COMPANY	ByteDance
-- @AUTHOR	邱天
-- @DATE	2022.011.9
--

local SettlementPlayerItem = Class("Common.Framework.UserWidget")

-------------------------------------------- Config/Enum ------------------------------------


-------------------------------------------- Init/Destroy ------------------------------------

function SettlementPlayerItem:OnInit()

	--self:InitData()
	UserWidget.OnInit(self)

	self.StickerWidgetList = {
        [1] = self.Image_Sticker_1,
        [2] = self.Image_Sticker_2, 
        [3] = self.Image_Sticker_3, 
    }

    self.AchievementWidgetList = {
        [1] = self.Image_Achieve_1,
        [2] = self.Image_Achieve_2, 
        [3] = self.Image_Achieve_3, 
    }
end

function SettlementPlayerItem:OnDestroy()

	UserWidget.OnDestroy(self)
end
-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function SettlementPlayerItem:InitData(PlayerData)
	local InDataIndex = PlayerData.PosInTeam
	--local PlayerData = SettlementProxy:GetPlayerDataByIndex(InDataIndex)
	if not PlayerData then
		error("SettlementPlayerItem", ">> InitData not valid!!! PosInTeam" , tostring(InDataIndex))
		return
	end

	--玩家名字 
	local name = SettlementProxy:GetPlayerDataPlayerName(PlayerData)
	local playerId = tonumber(PlayerData.PlayerId)
	print("SettlementPlayerItem >> name:[", name, "]")
	print("SettlementPlayerItem >> playerId:[", playerId, "]")
	if name == '' or playerId == nil then
		print("SettlementPlayerItem >> PlayerData.PlayerName:[", PlayerData.PlayerName, "]")
		print("SettlementPlayerItem >> PlayerData.PlayerId:[", PlayerData.PlayerId, "]")
		name = PlayerData.PlayerName or '-'
	end
	self.Text_Name:SetText(name)

	self.GUITextBlock_TeamNum:SetText(tostring(InDataIndex))
	local ImgColor = MinimapHelper.GetTeamMemberColor(InDataIndex)
	--if self.Image_Num_bg then self.Image_Num_bg:SetColorAndOpacity(ImgColor) end


	local CurHeroId = SettlementProxy:GetPlayerDataHeroID(PlayerData)
	print("SettlementPlayerItem >> CurHeroId:", CurHeroId)
	
	-- 头像资源 图片资源
	if false then
		local SkinId = MvcEntry:GetModel(HeroModel):GetDefaultSkinIdByHeroId(CurHeroId)
		local HeroSkinCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,SkinId)
		if HeroSkinCfg then
			local HeadPNGPath = HeroSkinCfg[Cfg_HeroSkin_P.FullBodyPNGPath]
			local HeadBGPNGPath = HeroSkinCfg[Cfg_HeroSkin_P.FullBodyBGPNGPath]
			if HeadPNGPath ~= nil then
				print("SettlementPlayerItem >> HeadPNGPath:", HeadPNGPath, "InHeroId:", CurHeroId)
				local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(HeadPNGPath)
				if ImageSoftObjectPtr ~= nil then
					print("SettlementPlayerItem:InitData	加载图片")
					self.Image_Head:SetBrushFromSoftTexture(ImageSoftObjectPtr, true)
				end
			else
				print("SettlementPlayerItem >> InitData Failed InHeroId:", CurHeroId)
			end

			if HeadBGPNGPath ~= nil then
				print("SettlementPlayerItem >> HeadBGPNGPath:", HeadBGPNGPath, "InHeroId:", CurHeroId)
				local ImageSoftObjectPtr = UE.UGFUnluaHelper.ToSoftObjectPtr(HeadBGPNGPath)
				if ImageSoftObjectPtr ~= nil then
					print("SettlementPlayerItem:InitData	加载图片")
					self.Image_Bg:SetBrushFromSoftTexture(ImageSoftObjectPtr, true)
				end
			else
				print("SettlementPlayerItem >> InitData Failed InHeroId:", CurHeroId)
			end
		end
	end



	self.BP_SettlementPlayerItemMisc_Kill.Text_Num:SetText(SettlementProxy:GetPlayerDataKill(PlayerData))
	self.BP_SettlementPlayerItemMisc_LayDown.Text_Num:SetText(SettlementProxy:GetPlayerDataLayDown(PlayerData))
	self.BP_SettlementPlayerItemMisc_SaveCnt.Text_Num:SetText(SettlementProxy:GetPlayerDataSaveCnt(PlayerData))
	self.BP_SettlementPlayerItemMisc_ResurrectionCnt.Text_Num:SetText(SettlementProxy:GetPlayerDataResurrectionCnt(PlayerData))

	self.BP_SettlementPlayerItemMisc_Assist.Text_Num:SetText(SettlementProxy:GetPlayerDataPlayerAssist(PlayerData))
	self.BP_SettlementPlayerItemMisc_Damage.Text_Num:SetText(SettlementProxy:GetPlayerDataPlayerDamage(PlayerData))
	self.BP_SettlementPlayerItemMisc_SurvivalTime.Text_Num:SetText(SettlementProxy:GetPlayerDataPlayerSurvivalTime(PlayerData))

	self:UpdatePanelByMode(PlayerData)
	self:RefreshHeroCardShow(PlayerData)
end

function SettlementPlayerItem:UpdatePanelByMode(PlayerData)
	local GameMode =  SettlementProxy:GetCurrentGameMode()
	if GameMode == Settlement.EGameMode.TeamCompetition or GameMode == Settlement.EGameMode.Conquest then
		self.BP_SettlementPlayerItemMisc_LayDown:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.BP_SettlementPlayerItemMisc_Death:SetVisibility(UE.ESlateVisibility.Visible)

		self.BP_SettlementPlayerItemMisc_Kill.Text_Num:SetText(SettlementProxy:GetPlayerDataPlayerKill(PlayerData))
		self.BP_SettlementPlayerItemMisc_Death.Text_Num:SetText(SettlementProxy:GetPlayerDataDeath(PlayerData))
	elseif GameMode == Settlement.EGameMode.DeathFight then
		self.BP_SettlementPlayerItemMisc_LayDown:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.BP_SettlementPlayerItemMisc_Death:SetVisibility(UE.ESlateVisibility.Visible)
		self.BP_SettlementPlayerItemMisc_Assist:SetVisibility(UE.ESlateVisibility.Collapsed)
		self.BP_SettlementPlayerItemMisc_Kill:SetVisibility(UE.ESlateVisibility.Visible)

		self.BP_SettlementPlayerItemMisc_Kill.Text_Num:SetText(SettlementProxy:GetPlayerDataPlayerKill(PlayerData))
		self.BP_SettlementPlayerItemMisc_Death.Text_Num:SetText(SettlementProxy:GetPlayerDataDeath(PlayerData))
	end
end

-------------------------------------------- Callable ------------------------------------

---3D展示牌
function SettlementPlayerItem:RefreshHeroCardShow(PlayerData)
	print("SettlementPlayerItem >> RefreshHeroCardShow: PlayerId = ", PlayerData.PlayerId)

	local PlayerExInfo = UE.UPlayerExSubsystem.Get(self):GetPlayerExInfoById(PlayerData.PlayerId)
    if PlayerExInfo ~= nil then
		print("SettlementPlayerItem >> RefreshHeroCardShow: PlayerExInfo Valid")
        self.HeroBoardData = PlayerExInfo:GetDisplayBoardInfo()
    else
		print("SettlementPlayerItem >> RefreshHeroCardShow: PlayerExInfo == nil")
        self.HeroBoardData = nil
    end

    if self.HeroBoardData == nil then
		print("SettlementPlayerItem >> RefreshHeroCardShow: self.HeroBoardData == nil")
        return
    end
  
    print("SettlementPlayerItem@RefreshHeroCardShow", self.HeroBoardData.FloorId, self.HeroBoardData.RoleId, self.HeroBoardData.EffectId)
    -- 底板
    local FloorCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayFloor, Cfg_HeroDisplayFloor_P.Id, self.HeroBoardData.FloorId)
    if FloorCfg ~= nil then
		print("SettlementPlayerItem@RefreshHeroCardShow FloorCfg[Cfg_HeroDisplayFloor_P.FrameResPath] = ", FloorCfg[Cfg_HeroDisplayFloor_P.FrameResPath])
        if string.len(FloorCfg[Cfg_HeroDisplayFloor_P.FrameResPath]) > 1 then
            CommonUtil.SetBrushFromSoftObjectPath(self.Image_Frame, FloorCfg[Cfg_HeroDisplayFloor_P.FrameResPath]) 
            self.Image_Frame:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.Image_Frame:SetVisibility(UE.ESlateVisibility.Collapsed)
        end

		print("SettlementPlayerItem@RefreshHeroCardShow FloorCfg[Cfg_HeroDisplayFloor_P.FloorResPath] = ", FloorCfg[Cfg_HeroDisplayFloor_P.FloorResPath])
        if string.len(FloorCfg[Cfg_HeroDisplayFloor_P.FloorResPath]) > 1 then
            CommonUtil.SetBrushFromSoftObjectPath(self.Image_Floor, FloorCfg[Cfg_HeroDisplayFloor_P.FloorResPath]) 
            self.Image_Floor:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.Image_Floor:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    else
        self.Image_Frame:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Image_Floor:SetVisibility(UE.ESlateVisibility.Collapsed)
        print("SettlementPlayerItem@RefreshHeroCardShow Hide Image_Frame and Image_Floor")
    end

    -- 角色
    local RoleCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayRole, Cfg_HeroDisplayRole_P.Id, self.HeroBoardData.RoleId)
    if RoleCfg ~= nil then
		print("SettlementPlayerItem@RefreshHeroCardShow RoleCfg[Cfg_HeroDisplayRole_P.ResPath]) = ", RoleCfg[Cfg_HeroDisplayRole_P.ResPath])
        CommonUtil.SetBrushFromSoftObjectPath(self.Image_Role, RoleCfg[Cfg_HeroDisplayRole_P.ResPath]) 
        self.Image_Role:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) 
    else
        self.Image_Role:SetVisibility(UE.ESlateVisibility.Collapsed) 
        print("SettlementPlayerItem@RefreshHeroCardShow Image_Role")
    end

    -- 特效
    local EffectCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayEffect, Cfg_HeroDisplayEffect_P.Id, self.HeroBoardData.EffectId)
    if EffectCfg ~= nil then
		print("SettlementPlayerItem@RefreshHeroCardShow EffectCfg[Cfg_HeroDisplayEffect_P.ResPath] = ", EffectCfg[Cfg_HeroDisplayEffect_P.ResPath])
        CommonUtil.SetBrushFromSoftObjectPath(self.Image_Effect, EffectCfg[Cfg_HeroDisplayEffect_P.ResPath]) 
        self.Image_Effect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) 
    else
        self.Image_Effect:SetVisibility(UE.ESlateVisibility.Collapsed) 
        print("SettlementPlayerItem@RefreshHeroCardShow Image_Effect")
    end

    -- 贴纸 
    for Index, Widget in ipairs(self.StickerWidgetList) do

		local StickerInfo = self.HeroBoardData.StickerMap:FindRef(Index)
		self:RefreshStickerTexture(Widget, StickerInfo)
    end

    -- 成就
    for Index, Widget in ipairs(self.AchievementWidgetList) do

		local AchiveId = self.HeroBoardData.AchieveMap:FindRef(Index)
		local AchiveSubId = self.HeroBoardData.AchieveSubMap:FindRef(Index)
		self:RefreshAchievement(Widget, AchiveId, AchiveSubId)
    end

    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function SettlementPlayerItem:RefreshStickerTexture(Widget, StickerInfo)
    Widget:SetVisibility(StickerInfo == nil and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    if StickerInfo == nil then
		print("SettlementPlayerItem@RefreshStickerTexture StickerInfo == nil")
        return
    end

    local StickerCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplaySticker, Cfg_HeroDisplaySticker_P.Id, StickerInfo.StickerId)
    CommonUtil.SetBrushFromSoftObjectPath(Widget, StickerCfg and StickerCfg[Cfg_HeroDisplaySticker_P.ResPath] or "") 

    local Float2IntScale = HeroModel.DISPLAYBOARD_FLOAT2INTSCALE
    local Angle = StickerInfo.Angle and StickerInfo.Angle / Float2IntScale  or 0
	local ScaleX = StickerInfo.ScaleX and StickerInfo.ScaleX / Float2IntScale or 1
	local ScaleY = StickerInfo.ScaleY and StickerInfo.ScaleY / Float2IntScale or 1
    local XPos = StickerInfo.XPos and StickerInfo.XPos / Float2IntScale or 0
    local YPos = StickerInfo.YPos and StickerInfo.YPos / Float2IntScale or 0
    CLog(StringUtil.Format("SettlementPlayerItem StickerInfo.XPos:{0}, StickerInfo.YPos:{1}",StickerInfo.XPos, StickerInfo.YPos))
    Widget:SetRenderTransformAngle(Angle)
    Widget:SetRenderScale(UE.FVector2D(ScaleX, ScaleY))
    Widget:GetParent().Slot:SetPosition(UE.FVector2D(XPos, YPos))
end

function SettlementPlayerItem:RefreshAchievement(Widget, AchieveId, AchieveSubId)
    Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if (AchieveId == nil) or (AchieveSubId == nil) then
		print("SettlementPlayerItem@RefreshAchievement AchieveId == [%s] or AchieveSubId == [%s]", tostring(AchieveId), tostring(AchieveSubId))
		Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
	print("SettlementPlayerItem@RefreshAchievement AchieveId[%d] AchieveSubId[%d]",AchieveId,AchieveSubId)
    local AchieveCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_AchievementCfg, {Cfg_AchievementCfg_P.MissionID,Cfg_AchievementCfg_P.SubID},{AchieveId, AchieveSubId})
	if AchieveCfg and AchieveCfg.Image then
		print("SettlementPlayerItem@RefreshAchievement AchieveCfg "..AchieveCfg.Image)
		CommonUtil.SetBrushFromSoftObjectPath(Widget, AchieveCfg.Image)
	else
		Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
	end
end


return SettlementPlayerItem
