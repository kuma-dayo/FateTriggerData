--- 视图控制器
local class_name = "ActivityEmpty"
local ActivityEmpty = BaseClass(ActivityViewBase, class_name)

function ActivityEmpty:OnInit(Param)
    self.MsgList = {}
    self.BindNodes = {}
    ActivityEmpty.super.OnInit(self, Param)
    self.Model = MvcEntry:GetModel(ActivityModel)
    self.Data = nil
end

function ActivityEmpty:OnShow(Param)
    if not Param or not Param.Id then
        CError("ActivityEmpty:OnShow Param is nil")
        return
    end
    ---@type ActivityData
    self.Data = self.Model:GetData(Param.Id)
    if not self.Data then
        CError("ActivityEmpty:OnShow ActivityData is nil ActivityId:"..Param.Id)
        return
    end
end

function ActivityEmpty:OnHide(Param)
    self.Data = nil
end

function ActivityEmpty:OnStateChangedNotify()
    
end

return ActivityEmpty
