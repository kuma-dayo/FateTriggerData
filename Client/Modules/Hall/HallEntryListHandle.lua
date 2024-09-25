--[[
    活动基类
]] 
local class_name = "HallEntryListHandle"
HallEntryListHandle = BaseClass(UIHandlerViewBase, class_name)

function HallEntryListHandle:OnInit()
    self.MsgList = {
		{Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_ACTIVITYLIST_CHANGE, Func = Bind(self, self.UpdateUI)},
    }

    self.EntryHandleMap = {}
    ---@type ActivityModel
    self.AcModel = MvcEntry:GetModel(ActivityModel)
end

function HallEntryListHandle:OnShow(Param)
    self:UpdateUI()
end

function HallEntryListHandle:OnHide(Param)
    self.EntryHandleMap = {}
end

function HallEntryListHandle:HideAllEntry()
    if not self.EntryHandleMap then
        return
    end
    for _, v in pairs(self.EntryHandleMap) do
        if v:IsValid() then
            v:ManualClose()
        end
    end
end

function HallEntryListHandle:UpdateUI()
    self:HideAllEntry()
	local EntryList = self.AcModel:GetShowEntryList()
	if EntryList then
        for _, v in pairs(EntryList) do
            if not self.EntryHandleMap[v] then
                local WidgetClass = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(CommonEntryIcon.UMGPath))
                local Widget = NewObject(WidgetClass, self.View)
                self.View:AddChild(Widget)
                self.EntryHandleMap[v] = UIHandler.New(self, Widget, CommonEntryIcon, {EntryId = v}).ViewInstance
            else
                self.EntryHandleMap[v]:ManualOpen({EntryId = v})
            end
        end
	end
end

return HallEntryListHandle
