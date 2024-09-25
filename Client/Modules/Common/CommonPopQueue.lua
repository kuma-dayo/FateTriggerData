CommonPopQueue = CommonPopQueue or {}

if CommonPopQueue.Active == nil then
    CommonPopQueue.Active = false
end
CommonPopQueue.Instance = CommonPopQueue.Instance or nil

CommonPopQueue.MaxShowCount = 3
CommonPopQueue.Duration = 3
CommonPopQueue.ShowGap = 0.3
CommonPopQueue.ItemUMGPath = nil

--- func desc
---@param Data QueueViewItemData
---@param ItemUMGPath any
---@param MaxShowCount any
---@param Duration any
function CommonPopQueue.Append(Data, ItemUMGPath, MaxShowCount, Duration)
    CommonPopQueue.Show({Data})
end

--- func desc
---@param List QueueViewItemData[] 展示的数据列表
---@param ItemUMGPath any 展示的UMG资源路径
---@param MaxShowCount any 最大展示数量
---@param Duration any 展示时间
function CommonPopQueue.Show(List, ItemUMGPath, MaxShowCount, Duration)
    CommonPopQueue.ItemUMGPath = ItemUMGPath or CommonPopQueue.ItemUMGPath
    CommonPopQueue.MaxShowCount = MaxShowCount or CommonPopQueue.MaxShowCount
    CommonPopQueue.Duration = Duration or CommonPopQueue.Duration
    if not CommonUtil.IsValid(CommonPopQueue.Instance) then
        local widget_class = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(CommonPopQueueUMGPath))
        CommonPopQueue.Instance = NewObject(widget_class, GameInstance, nil, "Client.Modules.Common.CommonPopQueueView")
        UIRoot.AddChildToLayer(CommonPopQueue.Instance,UIRoot.UILayerType.Tips)
    end
    CommonPopQueue.Instance:Show(List)
end


function CommonPopQueue.Close()
    if CommonUtil.IsValid(CommonPopQueue.Instance) then
        CommonPopQueue.Instance:Hide()
    end
end

function CommonPopQueue.IsActive()
    return CommonPopQueue.Active
end

