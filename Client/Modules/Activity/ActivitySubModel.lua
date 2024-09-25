local ActivitySubData = require("Client.Modules.Activity.Data.ActivitySubData")

local super = ListModel;
local class_name = "ActivitySubModel";

---@class ActivitySubModel : ListModel
---@field private super ListModel
ActivitySubModel = BaseClass(super, class_name);
 
ActivitySubModel.CommunityShareSaveKey = "CommunityShareSaveKey"

ActivitySubModel.INNER_ACTIVITY_SUBITEM_STATE_CHANGE = "INNER_ACTIVITY_SUBITEM_STATE_CHANGE"

function ActivitySubModel:__init()
    ---@type DitryFlag
    self:_dataInit()
end

function ActivitySubModel:_dataInit()
    self:Clean()
    self.SubListTypeMap = nil
    self.SubListByAcId = nil
    self.TargetItemChangeMap = nil
    self.AllSubItemCompleteStateByAcId = nil
end

---@param data any
function ActivitySubModel:OnLogin(data)
    CWaring("ActivitySubModel OnLogin")
end

--- 玩家登出时调用
---@param data any
function ActivitySubModel:OnLogout(data)
    CWaring("ActivitySubModel OnLogout")
    ActivitySubModel.super.OnLogout(self)
    self:_dataInit()
end

--- 重写父方法,返回唯一Key
---@param vo any
function ActivitySubModel:KeyOf(vo)
    return vo["SubItemId"]
end

--- 重写父类方法,如果数据发生改变
--- 进行通知到这边的逻辑
---@param vo any
function ActivitySubModel:SetIsChange(value)
    ActivitySubModel.super.SetIsChange(self, value)
end

function ActivitySubModel:ReclaimItemsByAcId(AcId)
    local SubItemList = self:GetSubItemsByAcId(AcId)
    self:ReclaimItems(SubItemList)
end

function ActivitySubModel:ReclaimItems(List)
    if not List then
        return
    end
    for _, v1 in pairs(List) do
        ---@type ActivitySubData
        local SubItem = self:GetData(v1)
        if SubItem then
            PoolManager.Reclaim(SubItem)
        end
    end
    self:DeleteDatas(List)
end

function ActivitySubModel:ResetItemsByAcId(AcId)
    local SubItemList = self:GetSubItemsByAcId(AcId)
    self:ResetItems(SubItemList)
end

function ActivitySubModel:ResetItems(List)
    if not List then
        return
    end
    for _, v in ipairs(List) do
        ---@type ActivitySubData
        local SubItem = self:GetData(v)
        if SubItem then
            SubItem:Reset()
        end
    end
end

function ActivitySubModel:AppendAcSubDatas(AcId)
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_ActivityCfg, AcId)
    if not Cfg then
        CError("ActivitySubModel:AppendAcSubDatas Cfg is nil. AcId:"..AcId)
        return false
    end

    self.TargetItemChangeMap = self.TargetItemChangeMap or {}
    self.SubListByAcId = self.SubListByAcId or {}
    self.SubListTypeMap = self.SubListTypeMap or {}

    self.SubListByAcId[AcId] = self.SubListByAcId[AcId] or {}

    local SubListByTypeId = {}
    self.SubListTypeMap[AcId] = self.SubListTypeMap[AcId] or {}
    self.SubListTypeMap[AcId] = SubListByTypeId

    local Index = 1
    local MaxLoop = 100

    local AcModel = MvcEntry:GetModel(ActivityModel)
    repeat
        local SubItemId = Cfg[StringUtil.FormatSimple("SubItemId{0}", Index)]
        if not SubItemId or SubItemId == 0 then
            break
        end
        Index = Index + 1

        ---@type ActivitySubData
        local AcSubData = PoolManager.GetInstance(ActivitySubData)
        AcSubData:InitFromCfgId(AcId, SubItemId)
        AcSubData:Reset()

        self:AppendData(AcSubData)
        if AcSubData.TaskID > 0 then
            AcModel:RecordTask2AcIdList(AcSubData.TaskID, AcId)
        end

        local TypeID = AcSubData.Type
        SubListByTypeId[TypeID] = SubListByTypeId[TypeID] or {}
        table.insert(SubListByTypeId[TypeID], SubItemId)
        table.insert(self.SubListByAcId[AcId], SubItemId)

        if AcSubData.TargetItemId > 0 then
            self.TargetItemChangeMap[AcSubData.TargetItemId] = self.TargetItemChangeMap[AcSubData.TargetItemId] or {}
            table.insert(self.TargetItemChangeMap[AcSubData.TargetItemId], SubItemId)
        end
    until Index > MaxLoop
    if Index > MaxLoop then
        CError("ActivityData:InitSubItems SubItem is overflow")
    end
end

--- 通过活动id获取子项id列表
---@param AcId any
function ActivitySubModel:GetSubItemsByAcId(AcId)
    if not self.SubListByAcId then
        return nil
    end
    return self.SubListByAcId[AcId]
end

--- 通过活动id和类型返回子项id
---@param AcId any
---@param Type any
function ActivitySubModel:GetSubItemsByAcIdAndType(AcId, Type)
    if not self.SubListTypeMap or not self.SubListTypeMap[AcId] then
        return nil
    end
    return self.SubListTypeMap[AcId][Type]
end

function ActivitySubModel:SetSubItemState(SubItemId, NewState)
    ---@type ActivitySubData
    local SubItem = self:GetData(SubItemId)
    if not SubItem then
        return
    end
    SubItem:SetState(NewState)
end

function ActivitySubModel:SetSubAcState(SubId, NewState)
    ---@type ActivitySubData
    local SubItem = self:GetData(SubId)
    SubItem:SetState(NewState)
end

function ActivitySubModel:RefreshSubAcState(AcId)
    local AllFinished = true

    local SubItemList = self:GetSubItemsByAcId(AcId)
    if not SubItemList then
        return
    end
    for _, v in ipairs(SubItemList) do
        ---@type ActivitySubData
        local SubItem = self:GetData(v)
        if AllFinished and not SubItem:IsGot() then
            AllFinished = false
        end
    end

    self.AllSubItemCompleteStateByAcId = self.AllSubItemCompleteStateByAcId or {}
    self.AllSubItemCompleteStateByAcId[AcId] = AllFinished
end

--- 所有子项是否已经完成
---@param AcId any
function ActivitySubModel:IsAllSubItemsFinished(AcId)
    self:RefreshSubAcState(AcId)
    return self.AllSubItemCompleteStateByAcId[AcId] or false
end

return ActivitySubModel;