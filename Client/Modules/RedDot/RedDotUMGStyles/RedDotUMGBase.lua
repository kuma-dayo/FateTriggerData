---
--- 用于控制 UMG 控件显示逻辑
--- Description: 
--- Created At: 2023/10/12 17:33
--- Created By: 朝文
---

local class_name = "RedDotUMGBase"
---@class RedDotUMGBase
local RedDotUMGBase = BaseClass(nil, class_name)

---【派生类实现】展示红点
function RedDotUMGBase:ShowRedDot()   end
---【派生类实现】隐藏红点
function RedDotUMGBase:HideRedDot()   end

--- 派生类可使用接口 ---
---【派生类可使用】获取当前节点下的红点数量，这里会重复计算
function RedDotUMGBase:GetIsChildNotContainTag(Tag)
    local node = self.RedDotModel:GetNode(self.Data.RedDotKey, self.Data.RedDotSuffix)
    local bContainTag = node:ChildNotContainsTag(Tag)
    return bContainTag
end
---【派生类可使用】获取当前节点下的红点数量，这里会重复计算
function RedDotUMGBase:GetIsChildContainTag(Tag)
    local node = self.RedDotModel:GetNode(self.Data.RedDotKey, self.Data.RedDotSuffix)
    local bContainTag = node:ChildContainsTag(Tag)
    return bContainTag
end
---【派生类可使用】获取当前节点下的红点数量，这里会重复计算
function RedDotUMGBase:GetRedDotCount()
    local node = self.RedDotModel:GetNode(self.Data.RedDotKey, self.Data.RedDotSuffix)
    if not node then return 0 end
    
    local count = node:GetChildCount()
    return count
end
---【派生类可使用】获取当前节点下存在叶子的红点数量，每次都会触发遍历，需要考虑性能消耗
function RedDotUMGBase:GetRedDotLeafCount()
    local node = self.RedDotModel:GetNode(self.Data.RedDotKey, self.Data.RedDotSuffix)
    local count = node:GetLeafChildCount()
    return count
end

--- 红点计数 相关 ---
---【可选，派生类重写】当红点新增时(新增的红点内的红点数量计数为0)
function RedDotUMGBase:OnRedDotAdded()      self:UpdateRedDot() end
---【可选，派生类重写】当红点被移除时
function RedDotUMGBase:OnRedDotRemoved()    self:UpdateRedDot() end

--- Tag 相关 ---
---【可选，派生类重写】当红点或其叶子节点新增了一个Tag
function RedDotUMGBase:OnRedDotTagAdded(newTag)   self:UpdateRedDot() end
---【可选，派生类重写】当红点或其叶子节点移除了一个Tag
function RedDotUMGBase:OnRedDotTagRemoved(newTag) self:UpdateRedDot() end

---【可选，派生类重写】如果更新逻辑不一样的话
function RedDotUMGBase:UpdateRedDot()
    CLog("[cw] RedDotUMGBase:UpdateRedDot()")
    if self:IsNeedToShow() and self:CheckRedDotIsUnlock() then
        CLog("[cw] RedDotUMGBase:UpdateRedDot(true)")
        self:ShowRedDot()
    else
        CLog("[cw] RedDotUMGBase:UpdateRedDot(false)")
        self:HideRedDot()
    end
end

---根据类型判断是否需要展示红点
---@return boolean 是否需要展示红点
function RedDotUMGBase:IsNeedToShow()
    --不展示类型
    if self.RedDotModel:IsEnumRedDotDisplayRule_DoNotShow(self.RedDotDisplayRuleType) then
        --do nothing
        CLog("[cw] IsNeedToShow DoNotShow return false")
        return false

    --有任意子节点
    elseif self.RedDotModel:IsEnumRedDotDisplayRule_HasAnyChild(self.RedDotDisplayRuleType) then
        local bHasAnyChild = self:GetRedDotCount() > 0
        CLog("[cw] IsNeedToShow HasAnyChild return " .. tostring(bHasAnyChild))
        return bHasAnyChild

    --任意节点不包含标记
    elseif self.RedDotModel:IsEnumRedDotDisplayRule_HasAnyChildNotContainTag(self.RedDotDisplayRuleType) then
        local notContainTag = self.RedDotModel:RedDotDisplayRuleCfg_StringParam1(self.RedDotDisplayRuleId)
        if notContainTag == "self" then notContainTag = self.RedDotModel:ContactKey(self.Data.RedDotKey, self.Data.RedDotSuffix) end

        local RedDotNode = self.RedDotModel:GetNode(self.Data.RedDotKey, self.Data.RedDotSuffix)
        if not RedDotNode then
            CLog("[cw] IsNeedToShow HasAnyChildNotContainTag, but not find RedDotNode, return false")
            return false
        end

        local bAnyChildNotContainTag = RedDotNode:ChildNotContainsTag(notContainTag)
        CLog("[cw] IsNeedToShow HasAnyChildNotContainTag(" .. tostring(notContainTag) .. ") return " .. tostring(bAnyChildNotContainTag))
        return bAnyChildNotContainTag
        
    --奇奇怪怪节点
    else
        CError("[cw] IsNeedToShow unknow RedDotDisplayTypeEnum(" .. tostring(self.RedDotDisplayRuleType) .. ")")
        return false
    end
end

-- 检测红点是否解锁状态
function RedDotUMGBase:CheckRedDotIsUnlock()
    local IsUnlock = true
    if self.Data and self.Data.RedDotKey then
        IsUnlock = self.RedDotModel:CheckRedDotIsUnlock(self.Data.RedDotKey) 
    end
    return IsUnlock
end

--region 派生类不需要关心

function RedDotUMGBase:OnInit()
    self.MsgList = {
        {Model = RedDotModel, MsgName = RedDotModel.ON_REDDOT_ADDED,    Func = Bind(self, self._ON_REDDOT_ADDED)},
        {Model = RedDotModel, MsgName = RedDotModel.ON_REDDOT_REMOVED,  Func = Bind(self, self._ON_REDDOT_REMOVED)},
        {Model = RedDotModel, MsgName = RedDotModel.ON_REDDOT_UPATED,   Func = Bind(self, self._ON_REDDOT_UPATED)},
        
        {Model = RedDotModel, MsgName = RedDotModel.ON_REDDOT_TAG_ADDED,    Func = Bind(self, self._ON_REDDOT_TAG_ADDED)},
        {Model = RedDotModel, MsgName = RedDotModel.ON_REDDOT_TAG_REMOVED,  Func = Bind(self, self._ON_REDDOT_TAG_REMOVED)},
        {Model = RedDotModel, MsgName = RedDotModel.ON_REDDOT_DIGIT_DATA_UPDATE,  Func = Bind(self, self._ON_REDDOT_DIGIT_DATA_UPDATE)},
        {Model = RedDotModel, MsgName = RedDotModel.ON_REDDOT_UNLOCK_STATE_UPDATE,  Func = Bind(self, self._ON_REDDOT_UNLOCK_STATE_UPDATE)},
    }

    ---@type RedDotModel
    self.RedDotModel = MvcEntry:GetModel(RedDotModel)
end

function RedDotUMGBase:OnManualShow(Param)
    if self.Data and self.Data.RedDotKey then
        self:UpdateRedDot() 
    end
end

--[[
    self.Data = {
        RedDotKey = TabHeroSinItem_
        RedDotSuffix = 200010000
    }
--]]
function RedDotUMGBase:OnShow(Param)
    if not Param then
        return
    end
    self.Data = Param
    
    self:UpdateData(Param.RedDotKey, Param.RedDotSuffix)
    self:UpdateRedDot()
end

function RedDotUMGBase:UpdateData(RedDotKey, RedDotSuffix)
    self.Data = self.Data or {}
    self.Data.RedDotKey = RedDotKey
    self.Data.RedDotSuffix = RedDotSuffix
    
    self.wholeKey = self.RedDotModel:ContactKey(self.Data.RedDotKey, self.Data.RedDotSuffix)
    self.RedDotDisplayRuleId = self.RedDotModel:RedDotHierarchyCfg_GetRedDotDisplayRuleId(self.Data.RedDotKey)
    self.RedDotDisplayRuleType = self.RedDotModel:RedDotDisplayRuleCfg_GetRedDotDisplayRuleTypeEnum(self.RedDotDisplayRuleId)
end

function RedDotUMGBase:OnHide()
    self.Data = nil
end

function RedDotUMGBase:_ON_REDDOT_ADDED(_, key)
    if key ~= self.wholeKey then return end
    
    self:OnRedDotAdded()
end

function RedDotUMGBase:_ON_REDDOT_REMOVED(_, key)
    if key ~= self.wholeKey then return end
    
    self:OnRedDotRemoved()
end

function RedDotUMGBase:_ON_REDDOT_UPATED(_, key)
    if key ~= self.wholeKey then return end
    
    self:UpdateRedDot()
end

--[[
    Msg = {
        RedDotKey    = TabHeroSkinItem_
        RedDotSuffix = 200030002
        Tag          = TabHeroSkin_200030000
    }
--]]
function RedDotUMGBase:_ON_REDDOT_TAG_ADDED(_, Msg)
    print_r(Msg, "[cw] ====Msg")
    if self.RedDotModel:IsParentNode(Msg.RedDotKey, Msg.RedDotSuffix, self.Data.RedDotKey, self.Data.RedDotSuffix) then
        CLog("[cw] " .. tostring(Msg.RedDotKey) .. ", " .. tostring(Msg.RedDotSuffix) .. " is " .. tostring(self.Data.RedDotKey) .. ", " .. tostring(self.Data.RedDotSuffix) .. "'s child")
        self:OnRedDotTagAdded(Msg.Tag)
    else
        CLog("[cw] " .. tostring(Msg.RedDotKey) .. ", " .. tostring(Msg.RedDotSuffix) .. " is not " .. tostring(self.Data.RedDotKey) .. ", " .. tostring(self.Data.RedDotSuffix) .. "'s child")
    end
end

--[[
    Msg = {
        RedDotKey    = TabHeroSkinItem_
        RedDotSuffix = 200030002
        Tag          = TabHeroSkin_200030000
    }
--]]
---暂时没有移除的逻辑，先写下备用
function RedDotUMGBase:_ON_REDDOT_TAG_REMOVED(_, Msg)
    if self.RedDotModel:IsParentNode(Msg.RedDotKey, Msg.RedDotSuffix, self.Data.RedDotKey, self.Data.RedDotSuffix) then
        self:OnRedDotTagRemoved(Msg.Tag)
    end
end

function RedDotUMGBase:_ON_REDDOT_DIGIT_DATA_UPDATE(_, key)
    if key ~= self.wholeKey then return end
    
    self:UpdateRedDot()
end

function RedDotUMGBase:_ON_REDDOT_UNLOCK_STATE_UPDATE(_, RedDotKey)
    if self.Data and RedDotKey == self.Data.RedDotKey then
        self:UpdateRedDot() 
    end
end

--endregion 派生类不需要关心

return RedDotUMGBase