---
--- local Mdt 模块，用于控制 UMG 控件显示逻辑
--- Description: 大厅结算界面，战斗页签挂载的子页面ui逻辑
--- Created At: 2023/04/10 10:41
--- Created By: 朝文
---

local class_name = "HallSettlement_BR_Battle"
local base = require("Client.Modules.HallSettlement.HallSettlement_Base.HallSettlement_Base_Battle")
---@class HallSettlement_BR_Battle : HallSettlement_Base_Battle
local HallSettlement_BR_Battle = BaseClass(base, class_name)

---@return string 列表下的item的lua路径
function HallSettlement_BR_Battle:GetBattleItemLuaPath()
    return "Client.Modules.HallSettlement.HallSettlement_BR.HallSettlement_BR_BattleItem"
end

return HallSettlement_BR_Battle
