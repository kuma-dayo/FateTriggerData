local ActivityDefine = require("Client.Modules.Activity.ActivityDefine")

local class_name = "ActivitySubData"
---@class ActivitySubData
local ActivitySubData = BaseClass(nil, class_name)

ActivitySubData.SubItemId = 0

ActivitySubData.Type = Pb_Enum_ACTIVITY_SUB_ITEM_TYPE.ACTIVITY_SUB_ITEM_TYPE_INVAILD
ActivitySubData.TaskID = 0
ActivitySubData.JumpId = 0
---@class ActivityReward 奖励
---@field RewardId number
---@field RewardNum number
---@type ActivityReward[]
ActivitySubData.Rewards = nil
ActivitySubData.Cfg = nil
ActivitySubData.IsChanged = true

ActivitySubData.DayCircle = false
ActivitySubData.ExtParam = nil

ActivitySubData.TargetItemId = 0
ActivitySubData.TargetValue = 0

ActivitySubData.State = ActivityDefine.ActivitySubState.Not

ActivitySubData.BelongAcId = 0

function ActivitySubData:InitFromCfgId(OwnerId, ConfigId)
    local SubItemCfg = G_ConfigHelper:GetSingleItemById(Cfg_ActivitySubItemCfg, ConfigId)
    if not SubItemCfg then
        return false
    end
    self.BelongAcId = OwnerId
    self.Cfg = SubItemCfg
    self.SubItemId = SubItemCfg[Cfg_ActivitySubItemCfg_P.SubItemId]
    self.Type = SubItemCfg[Cfg_ActivitySubItemCfg_P.TypeID]
    self.TaskID = SubItemCfg[Cfg_ActivitySubItemCfg_P.TaskID]
    self.JumpId = SubItemCfg[Cfg_ActivitySubItemCfg_P.JumpId]
    self.DayCircle = SubItemCfg[Cfg_ActivitySubItemCfg_P.DayCircle]

    if self.JumpId < 1 and self.TaskID > 0 then
        local TaskCfg = G_ConfigHelper:GetSingleItemById(Cfg_TaskCfg, self.TaskID)
        if TaskCfg then
            self.JumpId = TaskCfg[Cfg_TaskCfg_P.JumpId]
        end
    end

    local PrizeCondition = SubItemCfg[Cfg_ActivitySubItemCfg_P.PrizeCondition]
    local CondiArr = string.split(PrizeCondition, ";")
    if CondiArr and #CondiArr > 1 then
        self.TargetItemId = tonumber(CondiArr[1])
        self.TargetValue = tonumber(CondiArr[2])
    end

    local Index = 1
    local MaxLoop = 100
    repeat
        local RewardId = SubItemCfg[StringUtil.FormatSimple("Reward{0}", Index)]
        local RewardNum = SubItemCfg[StringUtil.FormatSimple("RewardNum{0}", Index)]
        if not RewardId or not RewardNum or RewardId == 0 then
            break
        end
        Index = Index + 1
        local Reward = {
            RewardId = RewardId,
            RewardNum = RewardNum,
        }
        self.Rewards = self.Rewards or {}
        table.insert(self.Rewards,Reward)
    until Index > MaxLoop
    if Index > MaxLoop then
        CError("ActivitySubData:InitFromCfgId Rewards is overflow")
    end

    local ExtIndex = 1
    local ExtMaxLoop = 10
    repeat
        local ParamStr = SubItemCfg["Param" .. ExtIndex]
        if not ParamStr then
            break
        end
        ExtIndex = ExtIndex + 1
        self.ExtParam = self.ExtParam or {}
        table.insert(self.ExtParam, ParamStr)
    until ExtIndex > ExtMaxLoop
    if ExtIndex > ExtMaxLoop then
        CError("ActivitySubData:InitFromCfgId ExtraParam is overflow")
    end

    return true
end

function ActivitySubData:Recycle()
    CWaring("ActivitySubData:Recycle SubItemId"..self.SubItemId)
    self:Reset()
    self.SubItemId = 0
    self.Type = Pb_Enum_ACTIVITY_SUB_ITEM_TYPE.ACTIVITY_SUB_ITEM_TYPE_INVAILD
    self.TaskID = 0
    self.JumpId = 0
    self.Rewards = nil
    self.Cfg = nil
    self.DayCircle = false
    self.ExtParam = nil
    self.TargetItemId = 0
    self.TargetValue = 0
    self.BelongAcId = 0
end

function ActivitySubData:Reset()
    -- CWaring("ActivitySubData:Reset SubItemId"..self.SubItemId)
    self.IsChanged = true
    self.State = ActivityDefine.ActivitySubState.Not
end

--- 获取标题
function ActivitySubData:GetTittle()
    if not self.Cfg  then
        return ""
    end
    local TaskTittle = self.Cfg[Cfg_ActivitySubItemCfg_P.TaskTittle]

    if not TaskTittle or string.len(TaskTittle) == 0 then
        if self.TaskID > 0 then
            local TaskCfg = G_ConfigHelper:GetSingleItemById(Cfg_TaskCfg, self.TaskID)
            if not TaskCfg then
                return ""
            end
            return StringUtil.FormatText(TaskCfg[Cfg_TaskCfg_P.TaskDescription], TaskCfg[Cfg_TaskCfg_P.Params1], TaskCfg[Cfg_TaskCfg_P.Params2], TaskCfg[Cfg_TaskCfg_P.Params3], TaskCfg[Cfg_TaskCfg_P.Params4])
        end
    end
    return StringUtil.FormatText(TaskTittle)
end

--- 跳转界面
function ActivitySubData:JumpView()
    if self.JumpId < 1 then
        return
    end
    MvcEntry:GetCtrl(ViewJumpCtrl):JumpTo(self.JumpId)
end

--- 更新状态
---@param State ActivitySubState
function ActivitySubData:SetState(NewState)
    if NewState == self.State then
        return
    end
    self.IsChanged = true
    self.State = NewState
    self:OnRefreshState()
end

function ActivitySubData:GetState()
    return self.State
end

--- 是否已经领取
function ActivitySubData:IsGot()
    return self.State == ActivityDefine.ActivitySubState.Got
end

--- 是否能领取
function ActivitySubData:IsCanGet()
    return self.State == ActivityDefine.ActivitySubState.Can
end


function ActivitySubData:GetJumpID()
    local JumpId = 0
    if self.JumpId > 0 then
        JumpId = self.JumpId
    else
        if self.TaskID > 0 then
            JumpId = MvcEntry:GetModel(TaskModel):GetTaskJumpID(self.TaskID)
       end
    end

    return JumpId
end

function ActivitySubData:OnRefreshState()
    print("ActivitySubData:RefreshState", self.SubItemId, self.State)
    MvcEntry:GetModel(ActivitySubModel):DispatchType(ActivitySubModel.INNER_ACTIVITY_SUBITEM_STATE_CHANGE, self.SubItemId)
end

function ActivitySubData:DoAccept()
    if self:IsCanGet() then
        MvcEntry:GetCtrl(ActivityCtrl):SendProtoActivityGetPrizeReq(self.BelongAcId, {self.SubItemId})
    else
        return
    end
end

--- 通过活动id和子项id获取分享活动类型客户端本地完成结果的key
---@param ActId number 活动ID
---@param SubItemId number 子项ID
function ActivitySubData:GetSaveKeyByActIdAndSubItemId(ActId, SubItemId)
    if not ActId or not SubItemId then
        return ""
    end
    return StringUtil.FormatSimple("{0}|{1}|{2}", ActivitySubModel.CommunityShareSaveKey, ActId, SubItemId)
end

--- 通过下标获取子项附加参数
---@param Index number 下标
function ActivitySubData:GetExtraParamByIndex(Index)
    return self.ExtParam[Index] or ""
end

return ActivitySubData
