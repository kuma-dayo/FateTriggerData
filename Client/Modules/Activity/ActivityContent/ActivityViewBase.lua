--[[
    活动基类
]] 
local class_name = "ActivityViewBase"
ActivityViewBase = BaseClass(UIHandlerViewBase, class_name)

function ActivityViewBase:OnInit(Param)
    CWaring("ActivityViewBase:OnInit")
    ---@type ActivityData
    self.Data = nil
    CommonUtil.MvcMsgRegisterOrUnRegister(self,{
        {Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_STATE_CHANGE,	Func = Bind(self, self.ActivityStateChange) }
    },true)
end

function ActivityViewBase:ActivityStateChange(_, AcId)
    if not CommonUtil.IsValid(self.View) then
        -- CDebug("ActivityViewBase:ActivitySubItemStateChange Is Not Valid")
        return
    end
    if not self.Data or self.Data.ID == 0 then
        return
    end
    if AcId ~= self.Data.ID then
        return
    end
    CWaring("ActivityViewBase:ActivityStateChange AcId:" .. AcId)
    self:OnStateChangedNotify()
end

function ActivityViewBase:OnStateChangedNotify()
    CWaring("ActivityViewBase:OnStateChangedNotify")
end
function ActivityViewBase:OnDestroy()
    CWaring("ActivityViewBase:OnDestroy")
    CommonUtil.MvcMsgRegisterOrUnRegister(self,{
        {Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_STATE_CHANGE,	Func = Bind(self, self.ActivityStateChange) }
    },false)
end

return ActivityViewBase
