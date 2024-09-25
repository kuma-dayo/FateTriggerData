--[[
    任务控制模块
]]
require("Client.Modules.Task.TaskModel")


local class_name = "TaskCtrl";
TaskCtrl = TaskCtrl or BaseClass(UserGameController,class_name);

function TaskCtrl:__init()
    CWaring("==TaskCtrl init")
    ---@type TaskModel
    self.Model = nil
end

function TaskCtrl:Initialize()
    CWaring("==TaskCtrl Initialize")
    self.Model = self:GetModel(TaskModel)
end

--[[
    玩家登入的时候，进行请求数据
]]
function TaskCtrl:OnLogin(data)
    self:SendProto_PlayerAllTaskReq()
end

--[[
    玩家登出
]]
function TaskCtrl:OnLogout(data)
    CWaring("TaskCtrl OnLogout")
end

function TaskCtrl:AddMsgListenersUser()
    self.ProtoList = 
    {
        {MsgName = Pb_Message.PlayerAllTaskRsp, Func = self.PlayerAllTaskRsp_Func},
        {MsgName = Pb_Message.PlayerAcceptTaskRsp, Func = self.PlayerAcceptTaskRsp_Func},
        -- {MsgName = Pb_Message.PlayerGetTaskPrizeRsp, Func = self.PlayerGetTaskPrizeRsp_Func},
        {MsgName = Pb_Message.PlayerTaskAcceptNotify, Func = self.PlayerTaskAcceptNotify_Func},
        {MsgName = Pb_Message.PlayerTaskDeleteNotify, Func = self.PlayerTaskDeleteNotify_Func},
        {MsgName = Pb_Message.PlayerTaskProcessNotify, Func = self.PlayerTaskProcessNotify_Func},
        {MsgName = Pb_Message.PlayerTaskStateNotify, Func = self.PlayerTaskStateNotify_Func},
    }
end


function TaskCtrl:SendProto_PlayerAllTaskReq()
    local Msg = {
    }
    self:SendProto(Pb_Message.PlayerAllTaskReq, Msg)
end


function TaskCtrl:SendProto_PlayerAcceptTaskReq(TaskId)
    local Msg = {
        TaskId = TaskId
    }
    self:SendProto(Pb_Message.PlayerAcceptTaskReq, Msg)
end

-- function TaskCtrl:SendProto_PlayerGetTaskPrizeReq(TaskId)
--     local Msg = {
--         TaskId = TaskId
--     }
--     self:SendProto(Pb_Message.PlayerGetTaskPrizeReq, Msg)
-- end


-----------------------------------------------------------------

function TaskCtrl:PlayerAllTaskRsp_Func(Msg)
    -- print_r(Msg)
    self.Model:SetDataList(Msg.TaskList)
end

function TaskCtrl:PlayerAcceptTaskRsp_Func(Msg)
    print_r(Msg)
    self.Model:DispatchType(TaskModel.ON_PLAYER_ACCEPT_TASK, Msg.TaskId)
end

-- function TaskCtrl:PlayerGetTaskPrizeRsp_Func(Msg)
--     self.Model:DispatchType(TaskModel.ON_PLAYER_GET_TASK_PRIZE, Msg.TaskId)
-- end

function TaskCtrl:PlayerTaskAcceptNotify_Func(Msg)
    -- print_r(Msg)
    self.Model:UpdateDatas(Msg.TaskList)
    self.Model:DispatchType(TaskModel.TASK_ACCEPT_NOTIFY, Msg.TaskId)
end

function TaskCtrl:PlayerTaskDeleteNotify_Func(Msg)
    print_r(Msg)
    self.Model:DeleteDatas(Msg.TaskIdList)
end

function TaskCtrl:PlayerTaskProcessNotify_Func(Msg)
    print_r(Msg)
   self.Model:UpdateTaskProcess(Msg.TargetProcessMap)
end

function TaskCtrl:PlayerTaskStateNotify_Func(Msg)
    print_r(Msg)
    self.Model:UpdateTaskState(Msg.TaskStateMap)
end

