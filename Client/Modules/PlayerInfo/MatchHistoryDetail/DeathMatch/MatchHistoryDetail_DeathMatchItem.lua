---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 死斗模式历史战绩详细条目
--- Created At: 2023/08/14 17:27
--- Created By: 朝文
---

local class_name = "MatchHistoryDetail_DeathMatchItem"
local super = require("Client.Modules.PlayerInfo.MatchHistoryDetail.MatchHistoryDetail_SubPageItemBase")
---@class MatchHistoryDetail_DeathMatchItem : MatchHistoryDetail_SubPageItemBase
local MatchHistoryDetail_DeathMatchItem = BaseClass(super, class_name)

---@return table
function MatchHistoryDetail_DeathMatchItem:GetAllNeedToChangeColorTextWidget()
    local Root = self.View
    local res = MatchHistoryDetail_DeathMatchItem.super.GetAllNeedToChangeColorTextWidget(self)
    table.insert(res, Root.Rank)
    table.insert(res, Root.K)
    table.insert(res, Root.A)
    table.insert(res, Root.DMG)
    return res    
end

function MatchHistoryDetail_DeathMatchItem:UpdateView()
    MatchHistoryDetail_DeathMatchItem.super.UpdateView(self)

    --死斗模式额外需要显示的内容

    local Root = self.View
    local Data = self.Data

    --设置名次
    ---@type PlayerInfo_MatchHistoryModel
    local PlayerRank = Data.PlayerRank or 0
    Root.Rank:SetText(PlayerRank)
    
    --设置击杀数
    local PlayerKill = Data.PlayerKill or 0
    Root.K:SetText(PlayerKill)

    --设置死亡
    local PlayerDeath = Data.PlayerDeath or 0
    Root.A:SetText(PlayerDeath)

    --设置伤害
    local PlayerDamage = Data.PlayerDamage or 0
    Root.DMG:SetText(StringUtil.FormatNumberWithComma(PlayerDamage))
end

return MatchHistoryDetail_DeathMatchItem