---@class AcBaseData
local AcBaseData = BaseClass(nil, "AcBaseData")

AcBaseData.ID = 0
---活动页签
AcBaseData.TabId = 0
---活动排序
AcBaseData.SortValue = 0
---时间
AcBaseData.StartTime = 0
AcBaseData.EndTime = 0
AcBaseData.IsChanged = true
AcBaseData.State = 0
---类型
AcBaseData.Type = 0

function AcBaseData:Init()
    self.ID = 0
    self.TabId = 0
    self.SortValue = 0
    self.StartTime = 0
    self.EndTime = 0
    self.IsChanged = true
    self.State = 0
end
--- 回收
function AcBaseData:Recycle()
    self:Init()
end
 
---状态变化
function AcBaseData:SetState(NewState)
    if NewState == self.State then
        return
    end
    self.State = NewState
    self.IsChanged = true
    self:OnRefreshState()
end

function AcBaseData:OnRefreshState()
end

--- 是否可用
function AcBaseData:IsAvailble()
    return true
end

function AcBaseData:Sort()
    return self.SortValue
end

function AcBaseData:Reset()
    self.State = 0
end

function AcBaseData:GetTabIcon()
    return nil
end

return AcBaseData
