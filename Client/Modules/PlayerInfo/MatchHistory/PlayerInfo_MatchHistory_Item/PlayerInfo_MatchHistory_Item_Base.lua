---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 历史战绩条目基类
--- Created At: 2023/08/08 10:45
--- Created By: 朝文
---

local class_name = "PlayerInfo_MatchHistory_Item_Base"
---@class PlayerInfo_MatchHistory_Item_Base
local PlayerInfo_MatchHistory_Item_Base = BaseClass(nil, class_name)

function PlayerInfo_MatchHistory_Item_Base:OnInit()
    self.BindNodes = {
        {UDelegate = self.View.WBP_MatchHistoty_ListItem_Base.GUIButton_HoverArea.OnClicked,     Func = Bind(self, self.OnButtClicked_HoverArea)},
        {UDelegate = self.View.WBP_MatchHistoty_ListItem_Base.GUIButton_HoverArea.OnHovered,     Func = Bind(self, self.OnButtHovered_HoverArea)},
        {UDelegate = self.View.WBP_MatchHistoty_ListItem_Base.GUIButton_HoverArea.OnUnhovered,   Func = Bind(self, self.OnButtUnhovered_HoverArea)},
        {UDelegate = self.View.WBP_MatchHistoty_ListItem_Base.GUIButton_HoverArea.OnPressed,     Func = Bind(self, self.OnButtPressed_HoverArea)},
        {UDelegate = self.View.WBP_MatchHistoty_ListItem_Base.GUIButton_HoverArea.OnReleased,    Func = Bind(self, self.OnButtReleased_HoverArea)},
    }
end

function PlayerInfo_MatchHistory_Item_Base:OnShow(Param)    end
function PlayerInfo_MatchHistory_Item_Base:OnHide()         end

--[[
    Param = { 
        GeneralData = { 
            HeroId = 200020000 
            SurvivalTime = 143.57386779785 
            SkinId = 0 
            Rank = 1 
            GameplayCfg =  { 
                GameplayId = 10001 
                View = 1
                TeamType = 1
                LevelId = 101101 
            } 
            Time = 1691562013 
            KillNum = 1 
        } 
        GameId = "12700116913955911" 
        FixedIndex = 1
    } 
--]]
function PlayerInfo_MatchHistory_Item_Base:SetData(Param)
    self.Data = Param
end

function PlayerInfo_MatchHistory_Item_Base:UpdateView()
    if not self.Data then return end
    if not self.Data.GeneralData then return end

    self:_UpdateResult()
    self:_UpdateHeadIcon()
    self:_UpdatePrimaryData()
    self:_UpdateSecondaryData()
    self:_UpdateGameType()
    self:_UpdateMapeName()
    self:_UpdatePlayTime()
end

---更新排名
function PlayerInfo_MatchHistory_Item_Base:_UpdateResult()
    if not self.Data then return end
    if not self.Data.GeneralData then return end
    if not self.Data.GeneralData.GameplayCfg then return end
    
    --TODO:子类重写
end

---更新头像
function PlayerInfo_MatchHistory_Item_Base:_UpdateHeadIcon()
    if not self.Data then return end
    if not self.Data.GeneralData then CLog("[cw] PlayerInfo_MatchHistory_Item_Base:_UpdateHeadIcon() not self.Data.GeneralData") return end

    local HeroSkinCfg = MvcEntry:GetModel(HeroModel):GetDefaultSkinCfgByHeroId(self.Data.GeneralData.HeroId)
    if not HeroSkinCfg then
        CError("PlayerInfo_MatchHistory_Item_Base _UpdateHeadIcon Error For Id = "..tostring(self.Data.GeneralData.HeroId),true)
        return
    end
    -- CommonUtil.SetBrushFromSoftObjectPath(self.View.WBP_MatchHistoty_ListItem_Base.WBP_MatchHistory_ListItem_HeroIcon.GUIImage_Hero, HeroSkinCfg[Cfg_HeroSkin_P.PNGPath])
    CommonUtil.SetMaterialTextureParamSoftObjectPath(self.View.WBP_MatchHistoty_ListItem_Base.WBP_MatchHistory_ListItem_HeroIcon.GUIImage_Hero,"Target", HeroSkinCfg[Cfg_HeroSkin_P.PNGPath])
end

---更新主要数据
function PlayerInfo_MatchHistory_Item_Base:_UpdatePrimaryData()
    if not self.Data then return end
    if not self.Data.GeneralData then CLog("[cw] PlayerInfo_MatchHistory_Item_Base:_UpdatePrimaryData() not self.Data.GeneralData") return end

    --子类重写
end

---更新次要数据
function PlayerInfo_MatchHistory_Item_Base:_UpdateSecondaryData()
    if not self.Data then return end
    if not self.Data.GeneralData then return end

    --子类重写
end

---玩法类型
function PlayerInfo_MatchHistory_Item_Base:_UpdateGameType()
    if not self.Data then return end
    if not self.Data.GeneralData then return end
    if not self.Data.GeneralData.GameplayCfg then return end

    local LevelId = self.Data.GeneralData.GameplayCfg.LevelId
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    -- local ModeId = MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(LevelId)
    local ModeId = self.Data.GeneralData.GameplayCfg.ModeId or MatchModeSelectModel:GetGameLevelEntryCfg_ModeCfg(LevelId)
    local ModeName = MatchModeSelectModel:GetModeEntryCfg_ModeName(ModeId)
    self.View.WBP_MatchHistoty_ListItem_Base.Text_GameType:SetText(StringUtil.Format(ModeName))
end

---更新地图名
function PlayerInfo_MatchHistory_Item_Base:_UpdateMapeName()
    if not self.Data then return end
    if not self.Data.GeneralData then return end
    if not self.Data.GeneralData.GameplayCfg then return end

    local LevelId = self.Data.GeneralData.GameplayCfg.LevelId
    ---@type MatchModeSelectModel
    local MatchModeSelectModel = MvcEntry:GetModel(MatchModeSelectModel)
    -- local SceneId = MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(LevelId)
    local SceneId = self.Data.GeneralData.GameplayCfg.SceneId or MatchModeSelectModel:GetGameLevelEntryCfg_SceneCfg(LevelId)
    local SceneName = MatchModeSelectModel:GetSceneEntryCfg_SceneName(SceneId)
    self.View.WBP_MatchHistoty_ListItem_Base.Text_MatchMapName:SetText(StringUtil.Format(SceneName))
end

---更新游玩时间
function PlayerInfo_MatchHistory_Item_Base:_UpdatePlayTime()
    if not self.Data then return end
    if not self.Data.GeneralData then return end
    if not self.Data.GeneralData.GameplayCfg then return end

    local TimeStamp = self.Data.GeneralData.Time or 0
    local TimeStr = TimeUtils.GetDateTimeStrFromTimeStamp(TimeStamp, "%04d-%02d-%02d %02d:%02d")
    self.View.WBP_MatchHistoty_ListItem_Base.Text_MatchTime:SetText(TimeStr)
end

function PlayerInfo_MatchHistory_Item_Base:OnHover()
    self.View.WBP_MatchHistoty_ListItem_Base.WidgetSwitcher_State:SetActiveWidgetIndex(1)
    self.View.WBP_MatchHistoty_ListItem_Base.WidgetSwitcher_Arrow:SetActiveWidgetIndex(1)
end

function PlayerInfo_MatchHistory_Item_Base:OnUnHover()
    self.View.WBP_MatchHistoty_ListItem_Base.WidgetSwitcher_State:SetActiveWidgetIndex(0)
    self.View.WBP_MatchHistoty_ListItem_Base.WidgetSwitcher_Arrow:SetActiveWidgetIndex(0)
end

function PlayerInfo_MatchHistory_Item_Base:Press()
    self.View.WBP_MatchHistoty_ListItem_Base.WidgetSwitcher_State:SetActiveWidgetIndex(2)
    self.View.WBP_MatchHistoty_ListItem_Base.WidgetSwitcher_Arrow:SetActiveWidgetIndex(2)
end

function PlayerInfo_MatchHistory_Item_Base:OnButtClicked_HoverArea()
    CLog("[cw] PlayerInfo_MatchHistory_Item_Base:OnButtClicked_Detail()")
    
    local GameId = self.Data.GameId
    --如果已经存在历史记录了，则不需要请求，直接打开就好
    ---@type PlayerInfo_MatchHistoryModel
    local PlayerInfo_MatchHistoryModel = MvcEntry:GetModel(PlayerInfo_MatchHistoryModel)
    if PlayerInfo_MatchHistoryModel:IsGotDetailRecordById(GameId) then
        MvcEntry:OpenView(ViewConst.MatchHistoryDetail, {GameId = GameId})
        return
    end

    --如果不存在，则需要请求并记录一下
    ---@type PlayerInfo_MatchHistoryCtrl
    local PlayerInfo_MatchHistoryCtrl = MvcEntry:GetCtrl(PlayerInfo_MatchHistoryCtrl)
    ---@type SeasonModel
    local SeasonModel = MvcEntry:GetModel(SeasonModel)
    PlayerInfo_MatchHistoryCtrl:SendDetailRecordReq(GameId, SeasonModel:GetCurrentSeasonId(), self.Data.CurPlayerId)
end

function PlayerInfo_MatchHistory_Item_Base:OnButtHovered_HoverArea()  self:OnHover()      end
function PlayerInfo_MatchHistory_Item_Base:OnButtUnhovered_HoverArea()self:OnUnHover()    end
function PlayerInfo_MatchHistory_Item_Base:OnButtPressed_HoverArea()  self:Press()        end
function PlayerInfo_MatchHistory_Item_Base:OnButtReleased_HoverArea() self:OnUnHover()    end

return PlayerInfo_MatchHistory_Item_Base