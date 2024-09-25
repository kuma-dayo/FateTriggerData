local M = Class()

function M:Construct()
    self.QueueListData = nil
    self.UsingWidgetList = nil
    self.AvailableWidgetList = nil
    self.CurShowIndex = 0
    self.UUIDIndex = 0
end

function M:Destruct()
    self:Hide()
    CommonPopQueue.Active = false
    CommonPopQueue.instance = nil
    self:Release()
end

function M:Show(List)
    self:RecycleAllItems()
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    CommonPopQueue.Active = true
    self.QueueListData = self.QueueListData or {}
    for i = 1, #List do
        self.QueueListData[#self.QueueListData + 1] = List[i]
    end
    self:CheckRepeat()
end

function M:Append(Data)
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    CommonPopQueue.Active = true
    self.QueueListData = self.QueueListData or nil
    table.insert(self.QueueListData, Data)
    self:CheckRepeat()
end

function M:Hide()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)
    CommonPopQueue.Active = false
    self.QueueListData = nil
    self.UsingWidgetList = nil
    self.CurShowIndex = 0
    self.UUIDIndex = 0
    self.AvailableWidgetList = nil
end

function M:CheckRepeat()
    if not self.QueueListData or #self.QueueListData == 0 then
        self:Hide()
        return
    end

    self.UsingWidgetList = self.UsingWidgetList or {}

    if table.nums(self.UsingWidgetList) >= CommonPopQueue.MaxShowCount then
        return
    end
    self.CurShowIndex = self.CurShowIndex or 0
    local NextShowIndex = self.CurShowIndex + 1
    local Data = self.QueueListData[NextShowIndex]

    if not Data then
        return
    end

    CLog("==============CheckRepeat Show")
    self.CurShowIndex = NextShowIndex
    local widget = self:GetItem()
    widget:Show(Data, CommonPopQueue.Duration, Bind(self, self.HideCallBack))

    self:CheckRepeat()
end


function M:GetItem()
    if not CommonPopQueue.ItemUMGPath then
        CError("CommonPopQueueView GetItem CommonPopQueue.ItemUMGPath is nil")
        return
    end
    self.AvailableWidgetList = self.AvailableWidgetList or {}
    local Widget
    if not self.UUIDIndex then
        self.UUIDIndex = 0
    end
    if #self.AvailableWidgetList == 0 then
        local widget_class = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(CommonPopQueue.ItemUMGPath))
        Widget = NewObject(widget_class, GameInstance, nil, "Client.Modules.Common.CommonPopQueueViewItem")
        self.UUIDIndex = self.UUIDIndex + 1
        Widget.UUID = self.UUIDIndex
    else
        Widget = self.AvailableWidgetList[#self.AvailableWidgetList]
        self.AvailableWidgetList[#self.AvailableWidgetList] = nil
        Widget:RemoveFromParent()
    end
    
    if self.ListBox then
        self.ListBox:AddChild(Widget)
    end
    
    if Widget.UUID == -1 then
        self.UUIDIndex = self.UUIDIndex + 1
        Widget.UUID = self.UUIDIndex
    end

    self.UsingWidgetList[Widget.UUID] = Widget
    return Widget
end

function M:RecycleItem(UUID)
    CLog("==============RecycleItem "..UUID)
    local Widget = self.UsingWidgetList[UUID]
    if not Widget then
       return
    end
    Widget:Hide()
    self.AvailableWidgetList[#self.AvailableWidgetList + 1] = Widget
    Widget:RemoveFromParent()
    self.Pool:AddChild(Widget)
end

function M:RecycleAllItems()
    CLog("==============RecycleAllItems ")
    if not self.UsingWidgetList then
        return
    end
    for _, v in pairs(self.UsingWidgetList) do
        self:RecycleItem(v.UUID)
    end
    self.UsingWidgetList = nil
end


function M:HideCallBack(UUID)
    CLog("==============HideCallBack "..UUID)
    self:RecycleItem(UUID)
    self.UsingWidgetList[UUID] = nil
    self:CheckRepeat()
    if table.nums(self.UsingWidgetList) <= 0 then
        self:Hide()
    end
end

return M