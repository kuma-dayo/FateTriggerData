---
--- 简单的红点，有红点计数则显示，没有则不显示
--- Description: 
--- Created At: 2023/10/17 17:52
--- Created By: 朝文
---

local class_name = "RedDotUMGNumCountStyle"
local super = require("Client.Modules.RedDot.RedDotUMGStyles.RedDotUMGBase")
---@class RedDotUMGNumCountStyle : RedDotUMGBase
local RedDotUMGNumCountStyle = BaseClass(super, class_name)

---【派生类实现】展示红点
function RedDotUMGNumCountStyle:ShowRedDot()
    self.View:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local RedDotCount = self:GetRedDotCount()

    ---@type RedDotModel
    local RedDotModel = MvcEntry:GetModel(RedDotModel)
    local RedDotDisplayTypeId = RedDotModel:RedDotHierarchyCfg_GetRedDotDisplayTypeId(self.Data.RedDotKey)
    local MaxShowRedDotCount = RedDotModel:RedDotDisplayTypeCfg_NumParam1(RedDotDisplayTypeId)
    if RedDotCount <= MaxShowRedDotCount then
        self.View.RedDotCount:SetText(RedDotCount)
    else
        local BeyoundMaxRedDotCountDisplayText = RedDotModel:RedDotDisplayTypeCfg_FTextParam1(RedDotDisplayTypeId)
        self.View.RedDotCount:SetText(BeyoundMaxRedDotCountDisplayText)
    end
end

---【派生类实现】隐藏红点
function RedDotUMGNumCountStyle:HideRedDot()
    self.View:SetVisibility(UE.ESlateVisibility.Collapsed)
end

return RedDotUMGNumCountStyle
