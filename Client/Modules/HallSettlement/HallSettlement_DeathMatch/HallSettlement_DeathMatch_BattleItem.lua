---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 局外结算战斗页面玩家信息条目
--- Created At: 2023/08/22 15:45
--- Created By: 朝文
---

local class_name = "HallSettlement_RP_ConqureItem"
local base = require("Client.Modules.HallSettlement.HallSettlement_Base.HallSettlement_Base_BattleItem")
---@class HallSettlement_RP_ConqureItem : HallSettlement_Base_BattleItem
local HallSettlement_RP_ConqureItem = BaseClass(base, class_name)

function HallSettlement_RP_ConqureItem:UpdateView()
    --1.头像、名字、默认不选中
    HallSettlement_RP_ConqureItem.super.UpdateView(self)
    
    --2.设置名次
    local Root = self.View
    ---@type HallSettlementModel
    local HallSettlementModel = MvcEntry:GetModel(HallSettlementModel)
    local Rank = HallSettlementModel:GetRankNum()
    Root.Rank:SetText(Rank)
    
    --3.设置击败
    local Data = self.Data
    local PlayerKill = Data.PlayerKill
    Root.K:SetText(PlayerKill)

    --4.设置死亡
    local PlayerDeath = Data.PlayerDeath
    Root.A:SetText(PlayerDeath)
    
    --5.设置伤害
    local PlayerDamage = Data.PlayerDamage
    Root.DMG:SetText(StringUtil.FormatNumberWithComma(PlayerDamage))
end

function HallSettlement_RP_ConqureItem:GetAllNeedToChangeColorTextWidget()
    local list = HallSettlement_RP_ConqureItem.super.GetAllNeedToChangeColorTextWidget(self)
    table.insert(list, self.View.Rank)
    table.insert(list, self.View.K)
    table.insert(list, self.View.A)
    table.insert(list, self.View.DMG)
    return list
end

return HallSettlement_RP_ConqureItem
