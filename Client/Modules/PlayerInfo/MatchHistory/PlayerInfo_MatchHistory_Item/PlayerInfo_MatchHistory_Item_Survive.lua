---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 历史战绩大逃杀模式条目
--- Created At: 2023/08/08 10:43
--- Created By: 朝文
---

local class_name = "PlayerInfo_MatchHistory_Item_Survive"
local base = require("Client.Modules.PlayerInfo.MatchHistory.PlayerInfo_MatchHistory_Item.PlayerInfo_MatchHistory_Item_Base")
---@class PlayerInfo_MatchHistory_Item_Survive : PlayerInfo_MatchHistory_Item_Base
local PlayerInfo_MatchHistory_Item_Survive = BaseClass(base, class_name)

---重写主要数据更新，显示击倒次数
function PlayerInfo_MatchHistory_Item_Survive:_UpdatePrimaryData()
    if not self.Data then return end
    if not self.Data.GeneralData then CLog("[cw] PlayerInfo_MatchHistory_Item_Survive:_UpdatePrimaryData() not self.Data.GeneralData") return end

    local text = self.Data.GeneralData.KillNum or 0
    self.View.WBP_MatchHistoty_ListItem_Base.Text_Primary:SetText(text)
end

---重写次要数据更新，显示存活时间
function PlayerInfo_MatchHistory_Item_Survive:_UpdateSecondaryData()
    if not self.Data then return end
    if not self.Data.GeneralData then return end

    self.View.WBP_MatchHistoty_ListItem_Base.HorizontalBox_Secondary:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local text = TimeUtils.GetTimeStringMin(self.Data.GeneralData.SurvivalTime or 0)
    self.View.WBP_MatchHistoty_ListItem_Base.Text_Secondary:SetText(text)
end

---重写一下更新排名的逻辑
function PlayerInfo_MatchHistory_Item_Survive:_UpdateResult()
    if not self.Data then return end
    if not self.Data.GeneralData then return end
    if not self.Data.GeneralData.GameplayCfg then return end
    
    --设置文字
    local rank = self.Data.GeneralData.Rank
    self.View.HistoryListItemWidget_ResultNum.Text_Rank:SetText(rank)
    self.View.HistoryListItemWidget_ResultNum.Text_Rank_1:SetText(rank)
    self.View.HistoryListItemWidget_ResultNum.Text_Rank_2:SetText(rank)

    self:_InnerInteractiveHandler(false)
end

function PlayerInfo_MatchHistory_Item_Survive:_InnerInteractiveHandler(bIspressed)
    if bIspressed then
        if self.Data.GeneralData.Rank == 1 then
            self.View.HistoryListItemWidget_ResultNum.WidgetSwitcher:SetActiveWidget(self.View.HistoryListItemWidget_ResultNum.Victory)

            self.View.WBP_MatchHistoty_ListItem_Base.Overlay_Win:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.WBP_MatchHistoty_ListItem_Base.Image_WinResultNum:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.WBP_MatchHistoty_ListItem_Base.Image_WinResultText:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            self.View.HistoryListItemWidget_ResultNum.WidgetSwitcher:SetActiveWidget(self.View.HistoryListItemWidget_ResultNum.Normal_Hover)
            self.View.WBP_MatchHistoty_ListItem_Base.Overlay_Win:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    else
        if self.Data.GeneralData.Rank == 1 then
            self.View.HistoryListItemWidget_ResultNum.WidgetSwitcher:SetActiveWidget(self.View.HistoryListItemWidget_ResultNum.Victory)

            self.View.WBP_MatchHistoty_ListItem_Base.Overlay_Win:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.WBP_MatchHistoty_ListItem_Base.Image_WinResultNum:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.View.WBP_MatchHistoty_ListItem_Base.Image_WinResultText:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            self.View.HistoryListItemWidget_ResultNum.WidgetSwitcher:SetActiveWidget(self.View.HistoryListItemWidget_ResultNum.Normal_Default)
            self.View.WBP_MatchHistoty_ListItem_Base.Overlay_Win:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

function PlayerInfo_MatchHistory_Item_Survive:OnHover()
    PlayerInfo_MatchHistory_Item_Survive.super.OnHover(self)
    self:_InnerInteractiveHandler(true)
end

function PlayerInfo_MatchHistory_Item_Survive:OnUnHover()
    PlayerInfo_MatchHistory_Item_Survive.super.OnUnHover(self)
    self:_InnerInteractiveHandler(false)
end

function PlayerInfo_MatchHistory_Item_Survive:Press()
    PlayerInfo_MatchHistory_Item_Survive.super.Press(self)
    self:_InnerInteractiveHandler(true)
end

return PlayerInfo_MatchHistory_Item_Survive
