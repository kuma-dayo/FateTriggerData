---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 大逃杀历史战绩详细条目
--- Created At: 2023/08/14 17:27
--- Created By: 朝文
---

local class_name = "MatchHistoryDetail_SurviveModeItem"
local super = require("Client.Modules.PlayerInfo.MatchHistoryDetail.MatchHistoryDetail_SubPageItemBase")
---@class MatchHistoryDetail_SurviveModeItem : MatchHistoryDetail_SubPageItemBase
local MatchHistoryDetail_SurviveModeItem = BaseClass(super, class_name)

---@return table
function MatchHistoryDetail_SurviveModeItem:GetAllNeedToChangeColorTextWidget()
    local Root = self.View
    local res = MatchHistoryDetail_SurviveModeItem.super.GetAllNeedToChangeColorTextWidget(self)
    table.insert(res, Root.Time)
    table.insert(res, Root.K)
    table.insert(res, Root.A)
    table.insert(res, Root.Restore)
    table.insert(res, Root.DMG)
    return res
end

function MatchHistoryDetail_SurviveModeItem:UpdateView()
    MatchHistoryDetail_SurviveModeItem.super.UpdateView(self)

    --大逃杀模式额外需要显示的内容    
    local Root = self.View
    local Data = self.Data

    --1.设置生存时间
    local PlayerSurvivalTime = Data.PlayerSurvivalTime or 0
    local SurviveTimeText = TimeUtils.GetTimeStringColon(PlayerSurvivalTime)
    Root.Time:SetText(SurviveTimeText)

    --2.设置击杀数
    local PlayerKill = Data.PlayerKill or 0
    Root.K:SetText(PlayerKill)

    --3.设置助攻
    local PlayerAssist = Data.PlayerAssist or 0
    Root.A:SetText(PlayerAssist)

    --4.设置救援
    local RespawnTimes = Data.RescueTimes or 0
    Root.Restore:SetText(RespawnTimes)

    --5.设置伤害
    local PlayerDamage = Data.PlayerDamage or 0
    Root.DMG:SetText(StringUtil.FormatNumberWithComma(PlayerDamage))
end

return MatchHistoryDetail_SurviveModeItem
