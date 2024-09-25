---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 征服模式历史战绩详细条目
--- Created At: 2023/08/14 17:27
--- Created By: 朝文
---

local class_name = "MatchHistoryDetail_ConqureItem"
local super = require("Client.Modules.PlayerInfo.MatchHistoryDetail.MatchHistoryDetail_SubPageItemBase")
---@class MatchHistoryDetail_ConqureItem : MatchHistoryDetail_SubPageItemBase
local MatchHistoryDetail_ConqureItem = BaseClass(super, class_name)

---@return table
function MatchHistoryDetail_ConqureItem:GetAllNeedToChangeColorTextWidget()
    local Root = self.View
    local res = MatchHistoryDetail_ConqureItem.super.GetAllNeedToChangeColorTextWidget(self)
    table.insert(res, Root.K)
    table.insert(res, Root.A)
    table.insert(res, Root.Conquest)
    table.insert(res, Root.DMG)
    return res
end

function MatchHistoryDetail_ConqureItem:UpdateView()
    MatchHistoryDetail_ConqureItem.super.UpdateView(self)

    --征服模式额外需要显示的内容

    local Root = self.View
    local Data = self.Data

    --设置击杀数
    local PlayerKill = Data.PlayerKill or 0
    Root.K:SetText(PlayerKill)

    --设置助攻
    local PlayerAssist = Data.PlayerAssist or 0
    Root.A:SetText(PlayerAssist)

    --设置占点
    local ConqurePoint = Data.ConquestCount or 0
    Root.Conquest:SetText(ConqurePoint)

    --设置伤害
    local PlayerDamage = Data.PlayerDamage or 0
    Root.DMG:SetText(StringUtil.FormatNumberWithComma(PlayerDamage))
end

return MatchHistoryDetail_ConqureItem
