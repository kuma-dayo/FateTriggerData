---
--- Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 历史战绩详情mdt
--- Created At: 2023/08/11 17:17
--- Created By: 朝文
---

local MatchConst = require("Client.Modules.Match.MatchConst")

local class_name = "MatchHistoryDetailMdt"
---@class MatchHistoryDetailMdt : GameMediator
MatchHistoryDetailMdt = MatchHistoryDetailMdt or BaseClass(GameMediator, class_name)
MatchHistoryDetailMdt.Const = {
    -- --经典大逃杀
    -- [MatchConst.Enum_MatchType.Survive] = {
    --     Bp = "/Game/BluePrints/UMG/OutsideGame/Information/MatchHistoryDetail/BR/WBP_HistoryDetail_BR_SubPage.WBP_HistoryDetail_BR_SubPage",
    --     Lua = "Client.Modules.PlayerInfo.MatchHistoryDetail.Survive.MatchHistoryDetail_SurviveMode",
    -- },
    -- --征服模式
    -- [MatchConst.Enum_MatchType.Conqure] = {
    --     Bp = "/Game/BluePrints/UMG/OutsideGame/Information/MatchHistoryDetail/Conqure/WBP_HistoryDetail_Conqure_SubPage.WBP_HistoryDetail_Conqure_SubPage",
    --     Lua = "Client.Modules.PlayerInfo.MatchHistoryDetail.Conqure.MatchHistoryDetail_Conqure",
    -- },
    -- --团竞模式
    -- [MatchConst.Enum_MatchType.TeamMatch] = {
    --     Bp = "/Game/BluePrints/UMG/OutsideGame/Information/MatchHistoryDetail/TeamMatch/WBP_HistoryDetail_TeamMatch_SubPage.WBP_HistoryDetail_TeamMatch_SubPage",
    --     Lua = "Client.Modules.PlayerInfo.MatchHistoryDetail.TeamMatch.MatchHistoryDetail_TeamMatch",
    -- },
    -- --个人死斗
    -- [MatchConst.Enum_MatchType.DeathMatch] = {
    --     Bp = "/Game/BluePrints/UMG/OutsideGame/Information/MatchHistoryDetail/DeathMatch/WBP_HistoryDetail_DeathMatch_SubPage.WBP_HistoryDetail_DeathMatch_SubPage",
    --     Lua = "Client.Modules.PlayerInfo.MatchHistoryDetail.DeathMatch.MatchHistoryDetail_DeathMatch",
    -- },

    --大逃杀模式
    [MatchConst.Enum_MatchType.Survive] = {
        AttachLua = "Client.Modules.HallSettlement.HallSettlement_BR.HallSettlement_BR_Battle",
        AttachBp = "/Game/BluePrints/UMG/OutsideGame/Settlement/RP/WBP_Settlement_RP_Battle.WBP_Settlement_RP_Battle",
    },
    --团队竞技模式
    [MatchConst.Enum_MatchType.TeamMatch] = {
        AttachLua = "Client.Modules.HallSettlement.HallSettlement_TeamMatch.HallSettlement_TeamMatch_Battle",
        AttachBp = "/Game/BluePrints/UMG/OutsideGame/Settlement/Team/WBP_Settlement_TeamMatch_Battle.WBP_Settlement_TeamMatch_Battle",
    },
    --个人死斗模式
    [MatchConst.Enum_MatchType.DeathMatch] = {
        AttachLua = "Client.Modules.HallSettlement.HallSettlement_DeathMatch.HallSettlement_DeathMatch_Battle",
        AttachBp = "/Game/BluePrints/UMG/OutsideGame/Settlement/Solo/WBP_Settlement_Solo_Battle.WBP_Settlement_Solo_Battle",
    },
    --征服模式
    [MatchConst.Enum_MatchType.Conqure] = {
        AttachLua = "Client.Modules.HallSettlement.HallSettlement_Conqure.HallSettlement_Conqure_Battle",
        AttachBp = "/Game/BluePrints/UMG/OutsideGame/Settlement/Conquest/WBP_Settlement_Conquest_Battle.WBP_Settlement_Conquest_Battle",
    },
}

function MatchHistoryDetailMdt:__init()
end

function MatchHistoryDetailMdt:OnShow(data)end
function MatchHistoryDetailMdt:OnHide()end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()

    self.MsgList =
    {
        {Model = HallSettlementModel,  MsgName = HallSettlementModel.ON_SETTLEMENT_PLAYER_ITEM_CLICK_EVENT,		   Func = self.ON_SETTLEMENT_PLAYER_ITEM_CLICK_EVENT_func },
    }

    UIHandler.New(self, self.WBP_CommonBtnTips_Back, WCommonBtnTips,
            {
                OnItemClick = self.OnButtonClick_Back,
                TipStr = G_ConfigHelper:GetStrFromCommonStaticST("Lua_MatchHistoryDetailMdt_return"),
                CommonTipsID = CommonConst.CT_ESC,
                ActionMappingKey = ActionMappings.Escape,
                HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
            })

    ---@type PlayerInfo_MatchHistoryModel
    self.PlayerInfo_MatchHistoryModel = MvcEntry:GetModel(PlayerInfo_MatchHistoryModel)

    ---@type UserModel
    self.UserModel = MvcEntry:GetModel(UserModel)

    -- 当前选中的玩家ID
    self.CurSelectPlayerId = nil
end

--[[
    Param 参考结构
    {

    }
]]
function M:OnShow(Param)
    self.GameId = Param and Param.GameId or 0
    CLog("[cw] M:OnShow(" .. tostring(self.GameId) .. ")")
    
    self._GameType = self.PlayerInfo_MatchHistoryModel:GetGameModeById(self.GameId)
    CLog("[cw] self._GameType: " .. tostring(self._GameType))
    
    self.Data = self.PlayerInfo_MatchHistoryModel:GetData(self.GameId)

    self:UnloadSubPage()
    self:LoadSubPage()
    self:UpdateBattleInfo()
end

function M:UpdateBattleInfo()
    
    --1.地图名
    local MapName = self.PlayerInfo_MatchHistoryModel:GetSceneNameById(self.GameId)
    self.MapName:SetText(MapName)

    --2.模式名
    local ModeName = self.PlayerInfo_MatchHistoryModel:GetGameModeNameById(self.GameId)
    self.GameType:SetText(ModeName)
    
    --3.对局结果

    --大逃杀模式和死斗模式，显示 排名/总队伍数
    local CurRankNum = self.PlayerInfo_MatchHistoryModel:GetDetailRankById(self.GameId)
    local IsWin = CurRankNum == 1
    if self._GameType == MatchConst.Enum_MatchType.Survive or
            self._GameType == MatchConst.Enum_MatchType.DeathMatch then      
        self.WidgetSwitcher_GameRank:SetActiveWidgetIndex(IsWin and 1 or 2)
        local RankNumber = IsWin and self.RankNumber_1 or self.RankNumber_2
        local All = IsWin and self.All_1 or self.All_2          
        local TotalTeam = self.PlayerInfo_MatchHistoryModel:GetDetailTotalTeamById(self.GameId)  
        RankNumber:SetText(CurRankNum)
        All:SetText(TotalTeam)
    --征服模式和团竞模式显示 胜利/失败
    elseif self._GameType == MatchConst.Enum_MatchType.Conqure or
            self._GameType == MatchConst.Enum_MatchType.TeamMatch then
        if IsWin then
            self.WidgetSwitcher_GameRank:SetActiveWidgetIndex(1)
        else
            self.WidgetSwitcher_GameRank:SetActiveWidgetIndex(2)
        end
    end

    -- --3.1.大逃杀模式(1/100)
    -- if self._GameType == MatchConst.Enum_MatchType.Survive then
    --     self.WidgetSwitcher_GameRank:SetActiveWidgetIndex(0)
        
    --     local Rank = self.PlayerInfo_MatchHistoryModel:GetDetailRankById(self.GameId)
    --     self.RankNumber:SetText(Rank)

    --     local TotalTeam = self.PlayerInfo_MatchHistoryModel:GetDetailTotalTeamById(self.GameId)
    --     self.All:SetText(TotalTeam)
        
    -- --3.2.征服模式(胜利|失败)
    -- elseif self._GameType == MatchConst.Enum_MatchType.Conqure then
    --     self.WidgetSwitcher_GameRank:SetActiveWidgetIndex(1)

    --     local Rank = self.PlayerInfo_MatchHistoryModel:GetDetailRankById(self.GameId)
    --     if Rank == 1 then
    --         self.GameResult:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_MatchHistoryDetailMdt_win")))
    --     else
    --         self.GameResult:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_MatchHistoryDetailMdt_fail")))
    --     end

    -- --3.3.死斗模式(1/100)
    -- elseif self._GameType == MatchConst.Enum_MatchType.DeathMatch then
    --     self.WidgetSwitcher_GameRank:SetActiveWidgetIndex(0)
    --     local Rank = self.PlayerInfo_MatchHistoryModel:GetDetailRankById(self.GameId)
    --     self.RankNumber:SetText(Rank)

    --     local TotalTeam = self.PlayerInfo_MatchHistoryModel:GetDetailTotalTeamById(self.GameId)
    --     self.All:SetText(TotalTeam)

    -- --3.4.团竞模式(胜利|失败)
    -- elseif self._GameType == MatchConst.Enum_MatchType.TeamMatch then
    --     self.WidgetSwitcher_GameRank:SetActiveWidgetIndex(1)

    --     local Rank = self.PlayerInfo_MatchHistoryModel:GetDetailRankById(self.GameId)
    --     if Rank == 1 then
    --         self.GameResult:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_MatchHistoryDetailMdt_win")))
    --     else
    --         self.GameResult:SetText(StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_MatchHistoryDetailMdt_fail")))
    --     end
    -- end
end

function M:LoadSubPage()
    local Cfg = MatchHistoryDetailMdt.Const[self._GameType]
    if not Cfg or not next(Cfg) or not Cfg.AttachLua or not Cfg.AttachBp then
        CError("[cw] Please check lua or bp, something wrong here")
        CLog("[cw] Cfg.AttachLua: " .. tostring(Cfg and Cfg.AttachLua))
        CLog("[cw] Cfg.AttachBp: " .. tostring(Cfg and Cfg.AttachBp))
        return
    end

    local WidgetClass = UE4.UClass.Load(Cfg.AttachBp)
    local Widget = NewObject(WidgetClass, self)
    UIRoot.AddChildToPanel(Widget, self.PanelContent)
    local Param = {
        Teammates = self.PlayerInfo_MatchHistoryModel:GetDetailTeammatesById(self.GameId),
        MatchType = self._GameType,
        SettlementItemType = HallSettlementModel.Enum_SettlementItemType.History,
    }
    ---@generic MatchHistoryDetail_SubpageDerive:MatchHistoryDetail_SubpageBase 
    ---@type MatchHistoryDetail_SubpageDerive
    self.SubPageContent = UIHandler.New(self, Widget, require(Cfg.AttachLua), Param).ViewInstance
end

---封装一个卸载子界面的方法
function M:UnloadSubPage()
    if not self.SubPageContent then return end

    self.PanelContent:ClearChildren()
    self.SubPageContent = nil
end

------------------------- 按钮详情相关 ------------------------
---点击玩家item回调
function M:ON_SETTLEMENT_PLAYER_ITEM_CLICK_EVENT_func(Param)
    if Param.SelectPlayerId then
        local MyPlayerId = self.UserModel:GetPlayerId()
        if MyPlayerId ~= Param.SelectPlayerId and Param.SelectPlayerId then
            local Param = {
                SelectPlayerId = Param.SelectPlayerId,
                PlayerName = Param.PlayerName,
            }
            MvcEntry:OpenView(ViewConst.HallSettlementDetailBtn, Param)
        end
    end
end
------------------------- 按钮详情相关 ------------------------

---反复打开界面，例如跳转回来时触发的逻辑
function M:OnRepeatShow(data)
end

function M:OnHide()
    --1.清空Avatar
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    HallAvatarMgr:HideAvatarByViewID(ViewConst.HallSettlement)
end

---点击返回按钮
function M:OnButtonClick_Back()
    MvcEntry:CloseView(ViewConst.MatchHistoryDetail)
end

return M