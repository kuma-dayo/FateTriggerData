

local OBHeroDisplayCard = Class("Common.Framework.UserWidget")
function OBHeroDisplayCard:OnInit()
    print("OBCheck@OBHeroDisplayCard OnInit")
    self:InitData()
    self:InitUI()
    self:InitGameEvent()
    self:InitUIEvent()

    UserWidget.OnInit(self)
end

function OBHeroDisplayCard:OnShow()
    print("OBCheck@OBHeroDisplayCard OnShow")
    self:ShowWidget()
end

--   ___ _   _ ___ _____ 
--  |_ _| \ | |_ _|_   _|
--   | ||  \| || |  | |  
--   | || |\  || |  | |  
--  |___|_| \_|___| |_|  
function OBHeroDisplayCard:InitUI()
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

    self:ResetWidget()
end

function OBHeroDisplayCard:InitData()
	self.LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    self.ViewPS = self.LocalPC.PlayerState  --被观战玩家（存活的）

    self.HeroId = nil
    self.HeroBoardData = nil
end

function OBHeroDisplayCard:InitGameEvent()
    -- 注册消息监听
    self.MsgList = { 
        { MsgName = GameDefine.MsgCpp.PC_UpdatePlayerState,	  Func = self.OnUpdateLocalPCPS,   bCppMsg = true, WatchedObject = self.LocalPC },
    }
end

function OBHeroDisplayCard:InitUIEvent()

end

function OBHeroDisplayCard:UpdateHeroData()
    local TheViewPlayerId = self.ViewPS:GetPlayerId()
    if self.HeroId == TheViewPlayerId then
        return
    end
    print("OBCheck@UpdateHeroData heroID:", self.HeroId)

    self.HeroId = TheViewPlayerId
    local PlayerExInfo = UE.UPlayerExSubsystem.Get(self):GetPlayerExInfoById(self.HeroId)
    if PlayerExInfo ~= nil then
        self.HeroBoardData = PlayerExInfo:GetDisplayBoardInfo()
    else
        self.HeroBoardData = nil
        print("OBCheck@UpdateHeroData nil")
    end
end

--   _   _ ___   ____  _____ _____ ____  _____ ____  _   _ 
--  | | | |_ _| |  _ \| ____|  ___|  _ \| ____/ ___|| | | |
--  | | | || |  | |_) |  _| | |_  | |_) |  _| \___ \| |_| |
--  | |_| || |  |  _ <| |___|  _| |  _ <| |___ ___) |  _  |
--   \___/|___| |_| \_\_____|_|   |_| \_\_____|____/|_| |_|
function OBHeroDisplayCard:ShowWidget()
    if self.HeroBoardData == nil then
        self:UpdateHeroData()
    end

   self:RefreshHeroCardShow()
end

function OBHeroDisplayCard:ResetWidget()

end

function OBHeroDisplayCard:RefreshHeroCardShow()
    if self.HeroBoardData == nil then
        return
    end  
    print("OBCheck@RefreshHeroCardShow", self.HeroBoardData.FloorId, self.HeroBoardData.RoleId, self.HeroBoardData.EffectId)
    -- 底板
    local FloorCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayFloor, Cfg_HeroDisplayFloor_P.Id, self.HeroBoardData.FloorId)
    if FloorCfg ~= nil then
        if string.len(FloorCfg[Cfg_HeroDisplayFloor_P.FrameResPath]) > 1 then
            CommonUtil.SetBrushFromSoftObjectPath(self.Image_Frame, FloorCfg[Cfg_HeroDisplayFloor_P.FrameResPath]) 
            self.Image_Frame:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.Image_Frame:SetVisibility(UE.ESlateVisibility.Collapsed)
            print("OBCheck@RefreshHeroCardShow Hide Image_Frame")
        end

        if string.len(FloorCfg[Cfg_HeroDisplayFloor_P.FloorResPath]) > 1 then
            CommonUtil.SetBrushFromSoftObjectPath(self.Image_Floor, FloorCfg[Cfg_HeroDisplayFloor_P.FloorResPath]) 
            self.Image_Floor:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.Image_Floor:SetVisibility(UE.ESlateVisibility.Collapsed)
            print("OBCheck@RefreshHeroCardShow Hide Image_Frame")
        end
    else
        self.Image_Frame:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.Image_Floor:SetVisibility(UE.ESlateVisibility.Collapsed)
        print("OBCheck@RefreshHeroCardShow Hide Image_Frame and Image_Floor")
    end

    -- 角色
    local RoleCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayRole, Cfg_HeroDisplayRole_P.Id, self.HeroBoardData.RoleId)
    if RoleCfg ~= nil then
        CommonUtil.SetBrushFromSoftObjectPath(self.Image_Role, RoleCfg[Cfg_HeroDisplayRole_P.ResPath]) 
        self.Image_Role:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) 
    else
        self.Image_Role:SetVisibility(UE.ESlateVisibility.Collapsed) 
        print("OBCheck@RefreshHeroCardShow Hide Image_Role")
    end

    -- 特效
    local EffectCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayEffect, Cfg_HeroDisplayEffect_P.Id, self.HeroBoardData.EffectId)
    if EffectCfg ~= nil then
        CommonUtil.SetBrushFromSoftObjectPath(self.Image_Effect, EffectCfg[Cfg_HeroDisplayEffect_P.ResPath]) 
        self.Image_Effect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) 
    else
        self.Image_Effect:SetVisibility(UE.ESlateVisibility.Collapsed) 
        print("OBCheck@RefreshHeroCardShow Hide Image_Effect")
    end

    -- 贴纸 
    for Index, Widget in ipairs(self.StickerWidgetList) do
        local StickerInfo = self.HeroBoardData.StickerMap and self.HeroBoardData.StickerMap:FindRef(Index) or nil
        self:RefreshStickerTexture(Widget, StickerInfo)
    end

    -- 成就
    for Index, Widget in ipairs(self.AchievementWidgetList) do
        local AchiveId = self.HeroBoardData.AchieveMap and self.HeroBoardData.AchieveMap:FindRef(Index) or nil
        local AchiveSubId = self.HeroBoardData.AchieveSubMap:FindRef(Index) or nil
        self:RefreshAchievement(Widget, AchiveId, AchiveSubId)
    end

    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

function OBHeroDisplayCard:RefreshStickerTexture(Widget, StickerInfo)
    Widget:SetVisibility(StickerInfo == nil and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    if StickerInfo == nil then
        print("OBCheck@RefreshHeroCardShow Hide Sticker")
        return
    end

    local StickerCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplaySticker, Cfg_HeroDisplaySticker_P.Id, StickerInfo.StickerId)
    if StickerCfg == nil then
        print("OBCheck@RefreshHeroCardShow StickerCfg is nil")
        return
    end
    CommonUtil.SetBrushFromSoftObjectPath(Widget, StickerCfg and StickerCfg[Cfg_HeroDisplaySticker_P.ResPath] or "") 

    local Float2IntScale = HeroModel.DISPLAYBOARD_FLOAT2INTSCALE
    local Angle = StickerInfo.Angle and StickerInfo.Angle / Float2IntScale  or 0
	local ScaleX = StickerInfo.ScaleX and StickerInfo.ScaleX / Float2IntScale or 1
	local ScaleY = StickerInfo.ScaleY and StickerInfo.ScaleY / Float2IntScale or 1
    local XPos = StickerInfo.XPos and StickerInfo.XPos / Float2IntScale or 0
    local YPos = StickerInfo.YPos and StickerInfo.YPos / Float2IntScale or 0
    Widget:SetRenderTransformAngle(Angle)
    Widget:SetRenderScale(UE.FVector2D(ScaleX, ScaleY))
    Widget:GetParent().Slot:SetPosition(UE.FVector2D(XPos, YPos))
end

function OBHeroDisplayCard:RefreshAchievement(Widget, AchieveId, AchieveSubId)
    Widget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if (AchieveId == nil) or (AchieveSubId == nil) then
		print("OBHeroDisplayCard@RefreshAchievement AchieveId == [%s] or AchieveSubId == [%s]", tostring(AchieveId), tostring(AchieveSubId))
		Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end
	print("OBHeroDisplayCard@RefreshAchievement AchieveId[%d] AchieveSubId[%d]",AchieveId,AchieveSubId)
    local AchieveCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_AchievementCfg, {Cfg_AchievementCfg_P.MissionID,Cfg_AchievementCfg_P.SubID},{AchieveId, AchieveSubId})
	if AchieveCfg and AchieveCfg.Image then
		print("OBHeroDisplayCard@RefreshAchievement AchieveCfg "..AchieveCfg.Image)
		CommonUtil.SetBrushFromSoftObjectPath(Widget, AchieveCfg.Image)
	else
		Widget:SetVisibility(UE.ESlateVisibility.Collapsed)
	end
end

--   _   _ ___    ____ ___  _   _ _____ ____   ___  _      
--  | | | |_ _|  / ___/ _ \| \ | |_   _|  _ \ / _ \| |     
--  | | | || |  | |  | | | |  \| | | | | |_) | | | | |     
--  | |_| || |  | |__| |_| | |\  | | | |  _ <| |_| | |___  
--   \___/|___|  \____\___/|_| \_| |_| |_| \_\\___/|_____|

--   _   _ ___   _______     _______ _   _ _____ 
--  | | | |_ _| | ____\ \   / / ____| \ | |_   _|
--  | | | || |  |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| || |  | |___  \ V / | |___| |\  | | |  
--   \___/|___| |_____|  \_/  |_____|_| \_| |_|  


--    ____    _    __  __ _____   _______     _______ _   _ _____ 
--   / ___|  / \  |  \/  | ____| | ____\ \   / / ____| \ | |_   _|
--  | |  _  / _ \ | |\/| |  _|   |  _|  \ \ / /|  _| |  \| | | |  
--  | |_| |/ ___ \| |  | | |___  | |___  \ V / | |___| |\  | | |  
--   \____/_/   \_\_|  |_|_____| |_____|  \_/  |_____|_| \_| |_| 

--[GMP消息]每次切换被观战者（存活的）后触发
function OBHeroDisplayCard:OnUpdateLocalPCPS(InLocalPC, InOldPS, InNewPS)
    --更新存活被观战者
    print("OBCheck@OnUpdateLocalPCPS", GetObjectName(self.LocalPC), GetObjectName(InLocalPC), GetObjectName(InNewPS))
	if self.LocalPC == InLocalPC then
        if InNewPS then
            print("OBCheck@OnUpdateLocalPCPS success")
            self.ViewPS = InNewPS
            self:UpdateHeroData()
            self:RefreshHeroCardShow()
        end
	end

end

return OBHeroDisplayCard