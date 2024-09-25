---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 局外结算战斗页面玩家信息条目
--- Created At: 2023/05/31 16:42
--- Created By: 朝文
---

local class_name = "HallSettlementSubpageBattleItemMdt"
local base = require("Client.Modules.HallSettlement.HallSettlement_Base.HallSettlement_Base_BattleItem")
---@class HallSettlementSubpageBattleItemMdt : HallSettlement_Base_BattleItem
local HallSettlementSubpageBattleItemMdt = BaseClass(base, class_name)

function HallSettlementSubpageBattleItemMdt:UpdateView()
    --1.头像、名字、默认不选中、组队按钮显示、点赞按钮显示
    HallSettlementSubpageBattleItemMdt.super.UpdateView(self)
    
    local Root = self.View
    local Data = self.Data
    
    --2.设置生存时间
    local PlayerSurvivalTime = Data.PlayerSurvivalTime
    local SurviveTimeText = TimeUtils.GetTimeStringColon(PlayerSurvivalTime)
    Root.Time:SetText(SurviveTimeText)

    --3.设置击杀数
    local PlayerKill = Data.PlayerKill
    Root.K:SetText(PlayerKill)

    --4.设置助攻
    local PlayerAssist = Data.PlayerAssist
    Root.A:SetText(PlayerAssist)

    --5.设置复活
    local RespawnTimes = Data.RespawnTimes
    Root.Restore:SetText(RespawnTimes)

    --6.设置救援
    local RescueTimes = Data.RescueTimes
    Root.Rescue:SetText(RescueTimes)

    --7.设置击倒
    local KnockDownTimes = Data.KnockDown
    Root.Down:SetText(KnockDownTimes)

    --8.设置伤害
    local PlayerDamage = Data.PlayerDamage
    Root.DMG:SetText(StringUtil.FormatNumberWithComma(PlayerDamage))
end

function HallSettlementSubpageBattleItemMdt:GetAllNeedToChangeColorTextWidget()
    local list = HallSettlementSubpageBattleItemMdt.super.GetAllNeedToChangeColorTextWidget(self)
    table.insert(list, self.View.PlayerName)
    table.insert(list, self.View.Time)
    table.insert(list, self.View.K)
    table.insert(list, self.View.A)
    table.insert(list, self.View.Restore)
    table.insert(list, self.View.Rescue)
    table.insert(list, self.View.Down)
    table.insert(list, self.View.DMG)
    return list
end

return HallSettlementSubpageBattleItemMdt
