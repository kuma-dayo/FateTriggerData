--[[
    任务数据模型
]]


local super = ListModel;
local class_name = "TaskModel"

---@class TaskModel : ListModel
---@field private super ListModel
TaskModel = BaseClass(super, class_name);


TaskModel.ON_PLAYER_ACCEPT_TASK = "ON_PLAYER_ACCEPT_TASK"
TaskModel.TASK_ACCEPT_NOTIFY = "TASK_ACCEPT_NOTIFY"
-- TaskModel.ON_PLAYER_GET_TASK_PRIZE = "ON_PLAYER_GET_TASK_PRIZE"

function TaskModel:__init()
    self:DataInit()
end

function TaskModel:DataInit()
    self.SingleOnlineMap = {}
end

--[[
    玩家登出时调用
]]
function TaskModel:OnLogout(data)
    self:DataInit()
end


--[[
    重写父方法，返回唯一Key
]]
function TaskModel:KeyOf(vo)
    return vo["TaskId"]
end


function TaskModel:UpdateTaskProcess(TargetProcessMap)
    if TargetProcessMap == nil then
        return
    end
    local TaskList = {}
    for TaskId, TaskProcess in pairs(TargetProcessMap) do
        local TaskData = self:GetData(TaskId)
        if TaskData ~= nil then
            -- TaskData.TargetProcessList = TaskProcess.ProcessNodeList
            for k, LbProcessNode in pairs(TaskProcess.ProcessNodeList) do
                TaskData.TargetProcessList = TaskData.TargetProcessList or {}
                TaskData.TargetProcessList[LbProcessNode.Index] = TaskData.TargetProcessList[LbProcessNode.Index] or {}
                TaskData.TargetProcessList[LbProcessNode.Index].ProcessValue = LbProcessNode.ProcessValue    
            end
            table.insert(TaskList, TaskData)
        end
    end
    self:UpdateDatas(TaskList)
end

function TaskModel:UpdateTaskState(TaskStateMap)
    if TaskStateMap == nil then
        return
    end
    local TaskList = {}
    for TaskId, TaskState in pairs(TaskStateMap) do
        local TaskData = self:GetData(TaskId)
        if TaskData == nil then
            TaskData = {
                TaskId = TaskId,
                State = TaskState
            }
            self:AppendData(TaskData)
        else
            TaskData.State = TaskState
        end
        table.insert(TaskList, TaskData)
    end
    self:UpdateDatas(TaskList)
end

---是否是在线时长任务
function TaskModel:IsSingleOnlineTask(TaskId, EventId)
    if self.SingleOnlineMap[TaskId] == 1 then
        return true
    elseif self.SingleOnlineMap[TaskId] == 0 then
        return false
    end
    
    local TaskCfg = G_ConfigHelper:GetSingleItemById(Cfg_TaskCfg, TaskId)
    if TaskCfg then
        local Conditionstr = TaskCfg[Cfg_TaskCfg_P.Condition]
        if string.match(Conditionstr,"SingleOnline") then
            self.SingleOnlineMap[TaskId] = 1
            return true
        else
            self.SingleOnlineMap[TaskId] = 0
        end
    end
    return false
end

function TaskModel:GetTaskJumpID(TaskId)
    local TaskCfg = G_ConfigHelper:GetSingleItemById(Cfg_TaskCfg, TaskId)
    if TaskCfg then
        return TaskCfg[Cfg_TaskCfg_P.JumpId]
    end
    return 0
end

-- 获取任务描述
function TaskModel:GetTaskDescription(TaskId)
    local TaskCfg = G_ConfigHelper:GetSingleItemById(Cfg_TaskCfg, TaskId)
    if TaskCfg then
        return TaskCfg[Cfg_TaskCfg_P.TaskDescription]
    end
    return ""
end

-- 获取任务奖励item信息
---@return number 奖励物品ID number 奖励物品数量
function TaskModel:GetTaskRewardItemInfo(TaskId)
    local RewardItemId, RewardItemNum
    local TaskCfg = G_ConfigHelper:GetSingleItemById(Cfg_TaskCfg, TaskId)
    if TaskCfg then
        RewardItemId = TaskCfg[Cfg_TaskCfg_P.RewardId]
        RewardItemNum = TaskCfg[Cfg_TaskCfg_P.RewardNum]
    end
    return RewardItemId, RewardItemNum
end

---特殊处理时长任务进度:将秒转换成分
local function TransitionSingleOnlineTaskProcess(TargetProcessNode)
    local Node = table.deepCopy(TargetProcessNode)
    Node.ProcessValue = math.floor(Node.ProcessValue / 60)
--    if Node.MaxProcess == nil then
--        CError(string.format("TransitionSingleOnlineTaskProcess Node.MaxProcess == 0,\n[%s],\n[%s]", table.tostring(Node),table.tostring(TargetProcessNode)),true)
--    end
    Node.MaxProcess = math.floor(Node.MaxProcess / 60)
    return Node
end

--[[
    存在一个任务多目标情况，供此情况取进度值用

    TaskId 任务ID
    EventId 目标ID（可选）  参考 TargetEventCfg.TaskEventId
        EventId不传的情况下，将会进度列表的第一个进度信息进行返回


    返回任务进度信息:
    message TargetProcessNode
    {
        int64 EventId       = 1;        // Key是任务的事件类型Id,参考Task.xslx,TargetEventCfg页签
        int64 ProcessValue  = 2;        // 当前进度
        int64 MaxProcess    = 3;        // 目标最大进度
    } 
]] 
function TaskModel:GetTaskProcess(TaskId, EventId)
    local TaskData = self:GetData(TaskId)
    if TaskData == nil then
        CError(string.format("TaskModel:GetTaskProcess TaskData == nil !!!!! TaskId=[%s],EventId=[%s]", tostring(TaskId), tostring(EventId)))
        return {EventId = 0, ProcessValue = 0, MaxProcess = 0}
    end
    local ProcessList = TaskData and TaskData.TargetProcessList or {}
    if not EventId then
        if self:IsSingleOnlineTask(TaskId, EventId) then
            return TransitionSingleOnlineTaskProcess(TaskData.TargetProcessList[1])
        end
        return TaskData.TargetProcessList[1]
    else
        for _, V in ipairs(ProcessList) do
            if V.EventId == EventId then
                if self:IsSingleOnlineTask(TaskId, EventId) then
                    return TransitionSingleOnlineTaskProcess(V)
                end
                return V
            end
        end
    end
    CError(string.format("TaskModel:GetTaskProcess Get Failed !!!!! TaskId=[%s],EventId=[%s]", tostring(TaskId), tostring(EventId)))
    return {EventId = 0, ProcessValue = 0, MaxProcess = 0}
end


--任务是否完成
function TaskModel:HasTaskFinished(TaskId)
    local TaskData = self:GetData(TaskId)
    return TaskData and TaskData.State >= Pb_Enum_TASK_TYPE_STATE.TASK_TYPE_FINISH or false
end




return TaskModel;