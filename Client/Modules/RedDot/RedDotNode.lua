---
--- 红点节点类，包含基本的红点字段和函数接口
--- Description: 红点类
--- Created At: 2023/10/19 15:39
--- Created By: 朝文
---

local class_name = "RedDotNode"
---@class RedDotNode
local RedDotNode = BaseClass(nil, class_name)

function RedDotNode:__init()
    self.Key             = ""               --唯一key
    self.RedDotKey       = ""               --红点key，用于确定父级关系及样式
    self.RedDotSuffix    = ""               --尾缀
    self.RedDotCount     = 0                --红点数量
    self.ServerSysId     = Pb_Enum_RED_DOT_SYS.RED_DOT_INVAILD   --服务器定义的红点系统模块Id
    self.ServerKeyId     = 0                --服务器定义的红点key
    self.TriggerTypeId   = RedDotModel.Enum_RedDotTriggerType.Click    --红点触发操作类型
    ---@type table<string, RedDotNode>
    self.Parents         = {}               --父亲
    ---@type table<string, RedDotNode>
    self.Childs          = {}               --孩子节点
    ---@type table<string, boolean>
    self.Tags            = {}               --节点上包含的标记
    ---@type boolean
    self.ChildsTagChange = true             --孩子tag数据是否已改变
    ---@type boolean
    self.ChildContainsTagState = false      --是否任意孩子包含tag
    ---@type boolean
    self.ChildsCountChange = true           --当前树分支下存在叶子的数量是否已改变
    ---@type number
    self.ChildUniqueCount = 0               --当前树分支下存在叶子的数量
end

---初始化的时候，或者从对象池里面拿出来的时候，可以调用这个来初始化节点的值
function RedDotNode:InitData(RedDotKey, RedDotSuffix, ServerSysId, ServerKeyId, TriggerTypeId)
    self.RedDotKey       = tostring(RedDotKey or "")
    self.RedDotSuffix    = tostring(RedDotSuffix or "")
    self.Key             = self.RedDotKey .. self.RedDotSuffix
    self.RedDotCount     = 0
    self.ServerSysId     = ServerSysId or Pb_Enum_RED_DOT_SYS.RED_DOT_INVAILD
    self.ServerKeyId     = ServerKeyId or 0
    self.TriggerTypeId   = TriggerTypeId or RedDotModel.Enum_RedDotTriggerType.Click
    self.Parents         = {}
    self.Childs          = {}
    self.Tags            = {}
    self.ChildsTagChange = true 
    self.ChildContainsTagState = false
    self.ChildUniqueCount = 0
end

---@return boolean 是否是叶子节点
function RedDotNode:IsLeaftNode() return not next(self.Childs)  end
---@return boolean 是否是根节点
function RedDotNode:IsRootNode()  return not next(self.Parents) end
---@return number 获取孩子，不会去重
function RedDotNode:GetChildCount()     return self.RedDotCount end
---@return number 获取当前树分支下存在叶子的数量
function RedDotNode:GetLeafChildCount()
    -- if self.ChildsCountChange then
    --     self.ChildsCountChange = false
    --     self.ChildUniqueCount = self:CheckLeafChildCount()
    -- end
    -- return self.ChildUniqueCount
    return self:CheckLeafChildCount()
end

---@return number 获取当前树分支下存在叶子的数量
function RedDotNode:CheckLeafChildCount()
    local uniqueCount = 0
    local UniqueMap = {}

    ---@param RedDotNode RedDotNode
    local function _InnerLoopCheck(RedDotNode)
        if not RedDotNode then return end

        if RedDotNode:IsLeaftNode() then
            if not UniqueMap[RedDotNode.Key] then
                uniqueCount = uniqueCount + 1
                UniqueMap[RedDotNode.Key] = true
            end
        else
            for _, childNode in pairs(RedDotNode.Childs) do
                _InnerLoopCheck(childNode)
            end
        end
    end

    _InnerLoopCheck(self)
    return uniqueCount
end

--- 更新孩子节点的状态  并刷新相关数据  外部更新Childs必须使用这个方法 不然会导致数据错乱
function RedDotNode:UpdateRedDotChild(WholeKey, RedDotNode)
    self.Childs[WholeKey] = RedDotNode
    self.ChildsTagChange = true
    self.ChildsCountChange = true
end

--- 更新父节点的状态  尽量避免外部修改数据
function RedDotNode:UpdateRedDotParent(ParentWholeKey, ParentNode)
    self.Parents[ParentWholeKey] = ParentNode
end

--- Tag 相关 ---
function RedDotNode:AddTag(tag)     
    -- self.ChildsTagChange = true  
    self.Tags[tag] = true   
end
function RedDotNode:HasTag(tag)       return self.Tags[tag]   end
function RedDotNode:RemoveTag(tag)   
    -- self.ChildsTagChange = true
    self.Tags[tag] = nil    
end
---@param tag string 需要检查的tag
---@return boolean 任意孩子包含tag
function RedDotNode:ChildContainsTag(tag)
    -- if self.ChildsTagChange then
    --     self.ChildsTagChange = false
    --     self.ChildContainsTagState = self:CheckChildContainsTag(tag)
    -- end
    return self:CheckChildContainsTag(tag)
end

---@param tag string 需要检查的tag
---@return boolean 任意孩子包含tag
function RedDotNode:CheckChildContainsTag(tag)
    if self:IsLeaftNode() then return self:HasTag(tag) end
    for _, child in pairs(self.Childs) do
        if child:ChildContainsTag(tag) then
            return true
        end
    end
    return false
end

---@param tag string 需要检查的tag
---@return boolean 任意孩子不包含tag
function RedDotNode:ChildNotContainsTag(tag)
    -- if self.ChildsTagChange then
    --     self.ChildsTagChange = false
    --     self.ChildContainsTagState = self:CheckChildContainsTag(tag)
    -- end
    return not self:CheckChildContainsTag(tag)
end

--- 如果是hover的情况 不管是点击还是hover都触发红点
---@param TriggerTypeId number  红点触发操作类型
function RedDotNode:CheckIsSameTriggerType(TriggerTypeId)
    if self.TriggerTypeId == RedDotModel.Enum_RedDotTriggerType.Hover then
        return true
    else
        return self.TriggerTypeId == TriggerTypeId
    end
end

return RedDotNode
