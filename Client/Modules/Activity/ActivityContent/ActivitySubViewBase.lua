--[[
    活动子项基类
]] 
local class_name = "ActivitySubViewBase"
ActivitySubViewBase = BaseClass(UIHandlerViewBase, class_name)

function ActivitySubViewBase:OnInit()
    CWaring("ActivitySubViewBase:OnInit")
    ---@type ActivitySubData
    self.SubData = nil
    CommonUtil.MvcMsgRegisterOrUnRegister(self,{
        {Model = ActivitySubModel, MsgName = ActivitySubModel.INNER_ACTIVITY_SUBITEM_STATE_CHANGE,	Func = Bind(self, self.ActivitySubItemStateChange) }
    },true)
end

function ActivitySubViewBase:ActivitySubItemStateChange(_, SubItemId)
    if not CommonUtil.IsValid(self.View) then
        -- CDebug("ActivitySubViewBase:ActivitySubItemStateChange Is Not Valid")
        return
    end
    if not self.SubData or self.SubData.SubItemId == 0 then
        return
    end
    if SubItemId ~= self.SubData.SubItemId then
        return
    end
    CWaring("ActivitySubViewBase:OnStateChangedNotify SubItemId:" .. SubItemId)
    self:OnSubStateChangedNotify()
end

function ActivitySubViewBase:OnDestroy()
    CWaring("ActivitySubViewBase:OnDestroy")
    CommonUtil.MvcMsgRegisterOrUnRegister(self,{
        {Model = ActivitySubModel, MsgName = ActivitySubModel.INNER_ACTIVITY_SUBITEM_STATE_CHANGE,	Func = Bind(self, self.ActivitySubItemStateChange) }
    },false)
end

function ActivitySubViewBase:OnSubStateChangedNotify()
    CWaring("ActivitySubViewBase:OnStateChangedNotify")
end

return ActivitySubViewBase
