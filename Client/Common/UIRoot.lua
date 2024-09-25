---@class UIRoot
---@field UILayerType table
UIRoot = UIRoot or {}


UIRoot.UILayerType = {
    Scene = 1,
    --场景
    Fix = 2,
    --一级弹窗，二级弹窗之类
    Pop = 3,
    --交互窗体，例如MessageBox
    Dialog = 4,
    --提示窗体，例如UIAlert
    Tips = 5,
    --不随世界被清理，用于Loading
    KeepAlive = 6,
}

UIRoot.layer2UMG = UIRoot.layer2UMG or {}
-- 每个UILayerType对应层级下子节点的计数，用于设置子节点的ZOrder
UIRoot.layer2ChildCount = UIRoot.layer2ChildCount or {}

function UIRoot.GetLayer(layerType)
    if not UIRoot.layer2UMG[layerType] then
        local widget_class = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(LayerNormalUMGPath))
        local widget_root = NewObject(widget_class, GameInstance, nil, "Client.Common.UIRoot")
        local zOrder = layerType

        if layerType == UIRoot.UILayerType.Dialog or layerType == UIRoot.UILayerType.Tips or layerType == UIRoot.UILayerType.KeepAlive then
            --临时Fix 在房间界面弹出Dialog层级不够的情况。  后续房间重构后，这段再代码再进行移除
            zOrder = layerType * 10000
        end
        if layerType == UIRoot.UILayerType.KeepAlive then
            CWaring("UIRoot.GetLayer bKeepAliveWhenWorldCleanup true:" .. layerType)
            widget_root.bKeepAliveWhenWorldCleanup = true
        end
        
        --类型不同，所处的显示层级也不同
        widget_root:AddToViewport(zOrder)
        widget_root:OnShow(layerType)

        UIRoot.layer2UMG[layerType] = widget_root
        UIRoot.layer2ChildCount[layerType] = 0
    end
    return UIRoot.layer2UMG[layerType].root
end

---@param child widget 要缓存起来的widget实例
---@param layerType number 所属的图层类型
---@return void
function UIRoot.AddChildToLayer(child,layerType,zOrder)
    if not child then
        CError("UIRoot.AddChildToLayer child nil",true)
        return
    end
    local parent = UIRoot.GetLayer(layerType)
    UIRoot.AddChildToPanel(child,parent,zOrder)
    UIRoot.OnLayerChildAdd(child,layerType,zOrder)
end

-- 向 UILayer 各层添加子节点时，更新当前子节点数，根据当前层级的节点数作为该节点的ZOrder设置
function UIRoot.OnLayerChildAdd(child,layerType,customZOrder)
    UIRoot.layer2ChildCount[layerType] = UIRoot.layer2ChildCount[layerType] + 1
    local slot = child.Slot
    if not slot then
        CError("UIRoot.OnLayerChildAdd slot nil",true)
        print_r(child)
        return
    end
    local zOrder = customZOrder or UIRoot.layer2ChildCount[layerType]
    slot:SetZOrder(zOrder)
    -- CWaring(StringUtil.Format("===== OnLayerChildAdd: layerType|count = {0}|{1}",layerType,UIRoot.layer2ChildCount[layerType]))
end

-- 向 UILayer 各层添子节点销毁时，更新当前子节点数
function UIRoot.OnLayerChildDisposed(layerType,viewId)
    UIRoot.layer2ChildCount[layerType] = UIRoot.layer2ChildCount[layerType] - 1
    -- CWaring(StringUtil.Format("===== OnLayerChildDisposed: layerType|count = {0}|{1}|{2}", layerType,UIRoot.layer2ChildCount[layerType],viewId and viewId or ""))
    if UIRoot.layer2ChildCount[layerType] < 0 then
        -- CError("OnLayerChildDisposed: count error after remove!Please Check!!:" .. UIRoot.layer2ChildCount[layerType] .. "|ViewId:" .. (viewId and viewId or ""))
        print_trackback()
        UIRoot.layer2ChildCount[layerType] = 0
    end
end

function UIRoot.GetLayerChildCount(layerType)
    return UIRoot.layer2ChildCount[layerType] or 0
end

function UIRoot.AddChildToPanel(child,panel,zOrder)
    if not child then
        CError("UIRoot.AddChildToPanel child nil",true)
        return
    end
    if not panel then
        CError("UIRoot.AddChildToPanel panel nil",true)
        return
    end
    panel:AddChild(child)

    local slot = child.Slot
    if slot then
        --TODO 设置锚点及偏移  达到实际Size跟父亲一样大
        if slot:IsA(UE.UCanvasPanelSlot) then
            local NewAnchors = UE.FAnchors()
            NewAnchors.Minimum = UE.FVector2D(0, 0)
            NewAnchors.Maximum = UE.FVector2D(1, 1)
            slot:SetAnchors(NewAnchors)
    
    
            local LocalFMargin = UE.FMargin()
            slot:SetOffsets(LocalFMargin)

            if zOrder then
                slot:SetZOrder(zOrder)
            end
        end
    end
end

local M = Class()

function M:Construct()
    -- self.testButton.OnClicked:Add(self, M.OnClicked_ExitButton)	
    -- print("UIRoot Create Layer:" + self:GetFName())
    CLog("UIRoot Create Layer:")
end

function M:OnShow(layerType)
    self.layerType = layerType
    CLog("UIRoot-----OnShow:" .. layerType)
end

function M:Destruct()
    if self.layerType then
        print("UIRoot-----Destruct:" .. self.layerType)
    end
    self.root:ClearChildren()
    self:RemoveFromParent()
    if self.layerType then
        UIRoot.layer2UMG[self.layerType] = nil
        UIRoot.layer2ChildCount[self.layerType] = 0
    end
    self:Release()
end


return M