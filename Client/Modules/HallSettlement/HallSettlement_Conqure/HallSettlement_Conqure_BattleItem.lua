---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 局外结算战斗页面玩家信息条目
--- Created At: 2023/05/31 16:42
--- Created By: 朝文
---

local class_name = "HallSettlement_Conqure_BattleItem"
local base = require("Client.Modules.HallSettlement.HallSettlement_Base.HallSettlement_Base_BattleItem")
---@class HallSettlement_Conqure_BattleItem : HallSettlement_Base_BattleItem
local HallSettlement_Conqure_BattleItem = BaseClass(base, class_name)

function HallSettlement_Conqure_BattleItem:UpdateView()
    --1.头像、名字、默认不选中
    HallSettlement_Conqure_BattleItem.super.UpdateView(self)
    
    local Root = self.View
    local Data = self.Data
    
    --2.设置击败
    local PlayerKill = Data.PlayerKill
    Root.K:SetText(PlayerKill)

    --3.设置助攻
    local PlayerAssist = Data.PlayerAssist
    Root.A:SetText(PlayerAssist)

    --3.设置占点
    local ConqurePoint = Data.ConquestCount
    Root.Conquest:SetText(ConqurePoint)
    
    --4.设置伤害
    local PlayerDamage = Data.PlayerDamage
    Root.DMG:SetText(StringUtil.FormatNumberWithComma(PlayerDamage))
end

function HallSettlement_Conqure_BattleItem:GetAllNeedToChangeColorTextWidget()
    local list = HallSettlement_Conqure_BattleItem.super.GetAllNeedToChangeColorTextWidget(self)
    table.insert(list, self.View.K)
    table.insert(list, self.View.A)
    table.insert(list, self.View.Conquest)
    table.insert(list, self.View.DMG)
    return list
end

return HallSettlement_Conqure_BattleItem
