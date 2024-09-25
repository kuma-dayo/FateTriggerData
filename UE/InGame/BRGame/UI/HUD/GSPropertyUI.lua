require "UnLua"

local GSPropertyUI = Class("Common.Framework.UserWidget")

function GSPropertyUI:Initialize(Initializer)
    self.WidgetIndexTable = {}

end

function GSPropertyUI:OnInit()

    -- 注册消息监听
    self.MsgList = {
        { MsgName = GameDefine.MsgCpp.GenericStatistic_Msg_ShowProperty,                 Func = self.OnShowProperty,         bCppMsg = true },
        { MsgName = GameDefine.MsgCpp.GenericStatistic_Msg_ShowExtraProperty,                 Func = self.OnShowExtraProperty,         bCppMsg = true },
    }

    UserWidget.OnInit(self)
end

function GSPropertyUI:OnDestroy()
    UserWidget.OnDestroy(self)
end

function GSPropertyUI:OnShowProperty(TargetAttor,GSCustomData)
    print("GSPropertyUI:OnShowProperty")
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local PropertyName = GSCustomData.PropertyTag.TagName
    local ID = GSCustomData.ID
    local Value = GSCustomData.Value
    local Name = string.gsub(PropertyName, "GenericStatistic.Property.", "");
    if self.WidgetIndexTable[PropertyName] then
        self.WidgetIndexTable[PropertyName]:BP_SetPairValue(ID,Value)
    else
        local ItemWidget = UE.UWidgetBlueprintLibrary.Create(self, self.ItemWidgetClass)
        ItemWidget:BP_SetItemTitle("PlayerID:"..ID.." - "..Name)
        ItemWidget:BP_SetPairValue(ID,Value)
        self.WidgetIndexTable[PropertyName] = ItemWidget
        self.VerticalBox_List:AddChild(ItemWidget)
    end
end

function GSPropertyUI:OnShowExtraProperty(TargetAttor,GSCustomData)
    print("GSPropertyUI:OnShowExtraProperty")
    self:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    local PropertyName = GSCustomData.PropertyTag.TagName
    local ID = GSCustomData.ID
    local UnitID = GSCustomData.Value.UnitId
    local UnitValue = GSCustomData.Value.UnitValue
    local Name = string.gsub(PropertyName, "GenericStatistic.Property.", "");
    if self.WidgetIndexTable[PropertyName] then
        self.WidgetIndexTable[PropertyName]:BP_SetPairValue(UnitID,UnitValue)
    else
        local ItemWidget = UE.UWidgetBlueprintLibrary.Create(self, self.ItemWidgetClass)
        ItemWidget:BP_SetItemTitle("PlayerID:"..ID.." - "..Name)
        ItemWidget:BP_SetPairValue(UnitID,UnitValue)
        self.WidgetIndexTable[PropertyName] = ItemWidget
        self.VerticalBox_List:AddChild(ItemWidget)
    end
end

return GSPropertyUI
