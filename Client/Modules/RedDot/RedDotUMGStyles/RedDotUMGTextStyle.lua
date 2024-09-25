---
--- 简单的红点，有红点计数则显示，没有则不显示
--- Description: 
--- Created At: 2023/10/17 17:03
--- Created By: 朝文
---

local class_name = "RedDotUMGTextStyle"
local super = require("Client.Modules.RedDot.RedDotUMGStyles.RedDotUMGBase")
---@class RedDotUMGTextStyle : RedDotUMGBase
local RedDotUMGTextStyle = BaseClass(super, class_name)

---【派生类实现】展示红点
function RedDotUMGTextStyle:ShowRedDot()
    self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

    ---@type RedDotModel
    local RedDotModel = MvcEntry:GetModel(RedDotModel)
    local RedDotDisplayTypeId = RedDotModel:RedDotHierarchyCfg_GetRedDotDisplayTypeId(self.Data.RedDotKey)
    local RedDotDisplayText = RedDotModel:RedDotDisplayTypeCfg_FTextParam1(RedDotDisplayTypeId)
    self.View.RedDotText:SetText(RedDotDisplayText)
end

---【派生类实现】隐藏红点
function RedDotUMGTextStyle:HideRedDot()
    self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return RedDotUMGTextStyle
