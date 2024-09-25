---
--- 简单的红点，有红点计数则显示，没有则不显示
--- Description: 
--- Created At: 2023/10/12 17:33
--- Created By: 朝文
---

local class_name = "RedDotUMGNormalStyle"
local super = require("Client.Modules.RedDot.RedDotUMGStyles.RedDotUMGBase")
---@class RedDotUMGNormalStyle : RedDotUMGBase
local RedDotUMGNormalStyle = BaseClass(super, class_name)

---【派生类实现】展示红点
function RedDotUMGNormalStyle:ShowRedDot()
    self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
end

---【派生类实现】隐藏红点
function RedDotUMGNormalStyle:HideRedDot()
    self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return RedDotUMGNormalStyle
