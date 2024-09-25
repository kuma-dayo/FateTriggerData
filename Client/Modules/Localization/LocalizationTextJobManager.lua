--[[
    LocalizationTextJob 
    1.会有超时逻辑，超时后仍然会执行回调，但是返回空值
    2.会有请求异常处理，异常仍然会执行回调，但是返回空值
]] 
local class_name = "LocalizationTextJob"
---@class LocalizationTextJob
local LocalizationTextJob = BaseClass(nil, class_name)
LocalizationTextJob.InnerID = 0

function LocalizationTextJob:__init(Timeout)
    self.IsWorking = false
    self.Timeout =  Timeout
    self.ID = LocalizationTextJob.InnerID
    LocalizationTextJob.InnerID = LocalizationTextJob.InnerID + 1
    print("LocalizationTextJob:__init", self.ID)
end

function LocalizationTextJob:DoAction(CallBackFunc)
    print("LocalizationTextJob:DoAction", self.ID)
    -- if self.IsWorking then
    --     CError("LocalizationTextJob Already IsWorking")
    --     return
    -- end
    self.CallBackFuncList =  self.CallBackFuncList or {}
    table.insert(self.CallBackFuncList,CallBackFunc)
    self.IsWorking = true
    self:AddOrClearTimeoutTimer(true)
end

function LocalizationTextJob:Close()
    print("LocalizationTextJob:Close", self.ID)
    self.CallBackFuncList = nil
    self.IsWorking = false
    self:AddOrClearTimeoutTimer(false)
end

function LocalizationTextJob:OnReqSucCallback(InContent)
    print("LocalizationTextJob:OnReqSucCallback", self.ID)
    if not self.IsWorking then
        return
    end
    for _, v in ipairs(self.CallBackFuncList) do
        if v then
            v(InContent)
        end
    end
    self:Close()
end

function LocalizationTextJob:AddOrClearTimeoutTimer(IsAdd)
    print("LocalizationTextJob:AddOrClearTimeoutTimer", self.ID)
    if self.TimeoutTimer then
        Timer.RemoveTimer(self.TimeoutTimer)
    end
    self.TimeoutTimer = nil
    if IsAdd then
        self.TimeoutTimer = Timer.InsertTimer(self.Timeout,Bind(self,self.OnJobTimerout),false)
    end
end

function LocalizationTextJob:OnJobTimerout()
    print("LocalizationTextJob:OnJobTimerout", self.ID)
    self:OnReqSucCallback("")
end

function LocalizationTextJob:Dispose()
    print("LocalizationTextJob:Dispose", self.ID)
    self:Close()
end

---@class LocalizationTextJobManager
local LocalizationTextJobManager = BaseClass(nil, "LocalizationTextJobManager")
LocalizationTextJobManager.JobMap = {}
LocalizationTextJobManager.Timeout = 5
function LocalizationTextJobManager:__init(Timeout)
    Timeout = Timeout or 5
    LocalizationTextJobManager.Timeout = Timeout
    print("LocalizationTextJobManager:__init")
end

function LocalizationTextJobManager:HandleJob(ID, CallBackFunc)
    print("LocalizationTextJobManager:HandleJob", ID)
    local Job = LocalizationTextJobManager.JobMap[ID]
    if not Job then
        for _, v in pairs(LocalizationTextJobManager.JobMap) do
            if v and not v.IsWorking then
                Job = v
                break
            end
        end
        if not Job then
            Job = LocalizationTextJob.New(LocalizationTextJobManager.Timeout)
        end
    end
    LocalizationTextJobManager.JobMap[ID] = Job
    Job:DoAction(CallBackFunc)
end

function LocalizationTextJobManager:SyncJob(ID, InContent)
    print("LocalizationTextJobManager:SyncJob", ID)
    local Job = LocalizationTextJobManager.JobMap[ID]
    if not Job then
        return
    end
    Job:OnReqSucCallback(InContent)
end

function LocalizationTextJobManager:IsJobWorking(ID)
    print("LocalizationTextJobManager:IsJobWorking", ID)
    local Job = LocalizationTextJobManager.JobMap[ID]
    if not Job then
        return false
    end
    return Job.IsWorking
end

function LocalizationTextJobManager:Dispose()
    print("LocalizationTextJobManager:Dispose")
    for _, v in pairs(LocalizationTextJobManager.JobMap) do
        v:Dispose()
    end
    LocalizationTextJobManager.JobMap = {}
end

return LocalizationTextJobManager
