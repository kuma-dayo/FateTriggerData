--[[
    公用MaskLayer层
]]
---@class UIMaskLayer
UIMaskLayer = UIMaskLayer or {}
local Const = {
    DefaultZOrder = 100,
    DefaultUMGPath = "/Game/BluePrints/UMG/Components/WBP_UIMask.WBP_UIMask",
}

--[[
    使用参考：    
    msgParam = {
        LayerDescribe = "",     --【可选】描述，默认为【提示】
        LayerRenderOpacity = "",--【可选】MaskLayer透明度
        LayerZOrderParam = {    --【可选】层级,一般需同时指明父节点,也可不用
            ParentNode = nil,
            ZOrder = 1
        },
        CloseCallback = func,        --【可选】点击屏幕关闭
        PopCallback = func        --【可选】点击屏幕弹窗回调
    }
    UIMaskLayer.Show(msgParam)
]]
---展示通用确认弹窗
---@param msgParam table 展示数据，数据格式参考上方注释
function UIMaskLayer.Show(msgParam)
    local widget_class = UE.UClass.Load(CommonUtil.FixBlueprintPathWithC(Const.DefaultUMGPath))
    local instance = NewObject(widget_class, GameInstance, nil, "Client.Common.UIMaskLayer")
    local ParentNode = nil
    local MyZOrder = Const.DefaultZOrder
    if msgParam.LayerZOrderParam then
        ParentNode = msgParam.LayerZOrderParam.ParentNode or nil
        MyZOrder = msgParam.LayerZOrderParam.ZOrder or 0
    end
    if not ParentNode then
        ParentNode = UIRoot.GetLayer(UIRoot.UILayerType.Tips)
    end
    UIRoot.AddChildToPanel(instance, ParentNode, MyZOrder)
    ---@see UIMaskLayer_C#Show
    instance:Show(msgParam)

    return instance
end

-------------------------------------------------------代理脚本-----------------------------------
---@class UIMaskLayer_C
local M = Class()

function M:Construct()
    self.BtnClick.OnClicked:Clear()
    self.BtnClick.OnClicked:Add(self, self.OnShowTipPop)
end

function M:Destruct()
    self:Release()
end

function M:Show(msg)
    self.MsgParam = msg
    if self.MsgParam.LayerDescribe then
        self.UIShowTxtTip:SetVisibility(UE.ESlateVisibility.Visible)
        self.UIShowTxtTip:SetText(self.MsgParam.LayerDescribe)
    end
    local MaskOpacity = self.MsgParam.LayerRenderOpacity or 0
    self.UIMask:SetRenderOpacity(MaskOpacity)
end

function M:OnShowTipPop()
    if self.MsgParam.PopCallback then
        self.MsgParam.PopCallback()
    end
end

---关闭界面
function M:OnClicked_CancelBtn()
    
    self:_DoClose()
end

---关闭界面函数，会触发关闭界面回调
function M:_DoClose()
    if self.MsgParam.CloseCallback then
        self.MsgParam.CloseCallback()
    end
    
    self:RemoveFromParent()
end

return M