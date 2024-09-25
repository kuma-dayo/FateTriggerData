require "UnLua"
require "InGame.BRGame.GameDefine"

local DetailKeyMap = Class("Common.Framework.UserWidget")

function DetailKeyMap:Initialize(Initializer)

end

----- UserWidget Functions -----

function DetailKeyMap:OnInit()
	UserWidget.OnInit(self)

    self.AllInteractionKeyWidget = {
        self.InputHintDataWidget_0_0,
        self.InputHintDataWidget_0_1,
        self.InputHintDataWidget_0_2,
        self.InputHintDataWidget_1_0,
        self.InputHintDataWidget_1_1,
        self.InputHintDataWidget_1_2
    }
end

function DetailKeyMap:OnDestroy()

	UserWidget.OnDestroy(self)
end

----- UserWidget Functions -----


function DetailKeyMap:SetInteractionInfo(InInteractionKey)
    local bExist = UE.UDataTableFunctionLibrary.DoesDataTableRowExist(self.DT_KeyCombinationLayout, InInteractionKey)
    if not bExist then
        print("DetailKeyMap:SetInteractionInfo [bExist]=",bExist)
        return
    end
    local LayoutStructInfo = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.DT_KeyCombinationLayout, InInteractionKey)
    if not LayoutStructInfo then
        return
    end

    -- hide all Interaction Key Widget
    self.HorizontalBox_First:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.HorizontalBox_Second:SetVisibility(UE.ESlateVisibility.Collapsed)
    for i, v in ipairs(self.AllInteractionKeyWidget) do
        if v then
            v:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end

    local KeyNum = LayoutStructInfo.ContainKeyCombinationArray:Length()
    for i = 1, KeyNum, 1 do
        local InnerLayoutInfo = LayoutStructInfo.ContainKeyCombinationArray:Get(i)
        local TempInteractionKeyWidget = self:GetTargetInteractionKeyWidget(InnerLayoutInfo.HorizontalIndex, InnerLayoutInfo.VerticalIndex)
        if TempInteractionKeyWidget then
            local InnerKeyInfo = UE.UDataTableFunctionLibrary.GetRowDataStructure(self.DT_KeyCombinationInfo, InnerLayoutInfo.KeyCombinationName)
            if InnerKeyInfo then
                TempInteractionKeyWidget:SetDataFromKeyCombination(InnerLayoutInfo.KeyCombinationName, InnerKeyInfo)
                TempInteractionKeyWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                if InnerLayoutInfo.VerticalIndex == 0 then
                    self.HorizontalBox_First:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                else
                    self.HorizontalBox_Second:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                end
            end
        end
    end
end

function DetailKeyMap:GetTargetInteractionKeyWidget(InIndexHorizontal, InIndexVertical)
    if (InIndexVertical == 0) and (InIndexHorizontal == 0) then
        return self.InputHintDataWidget_0_0
    elseif (InIndexVertical == 0) and (InIndexHorizontal == 1) then
        return self.InputHintDataWidget_0_1
    elseif (InIndexVertical == 0) and (InIndexHorizontal == 2) then
        return self.InputHintDataWidget_0_2
    elseif (InIndexVertical == 1) and (InIndexHorizontal == 0) then
        return self.InputHintDataWidget_1_0
    elseif (InIndexVertical == 1) and (InIndexHorizontal == 1) then
        return self.InputHintDataWidget_1_1
    elseif (InIndexVertical == 1) and (InIndexHorizontal == 2) then
        return self.InputHintDataWidget_1_2
    else
        return nil
    end
end

-- 获取目标交互键控件，通过组合键名称
function DetailKeyMap:GetTargetInteractionKeyByName(InKeyCombinationName)
    if not self.AllInteractionKeyWidget then
        return nil
    end

    for i, v in ipairs(self.AllInteractionKeyWidget) do
        if v and v.KeyCombinationName then
            if v.KeyCombinationName == InKeyCombinationName then
                return v
            end
        end
    end

    return nil
end

-- 更新丢弃个数控件的逻辑
function DetailKeyMap:UpdateDiscardNumWidget(InItemID, InItemNum, InKeyCombinationName)
    if not InItemID then return end
    if not InItemNum then return end
    if InItemNum <= 1 then return end
    local TargetNumWidget = self:GetTargetInteractionKeyByName(InKeyCombinationName)
    if not TargetNumWidget then
        return
    end

    local TempInventoryQuickDiscardNum, bInventoryQuickDiscardNum = UE.UItemSystemManager.GetItemDataInt32(
        self, InItemID, "InventoryQuickDiscardNum", GameDefine.NItemSubTable.Ingame,"DetailKeyMap:UpdateDiscardNumWidget")
    
    if bInventoryQuickDiscardNum then
        local FinalDiscardNum = 0
        FinalDiscardNum = math.min(TempInventoryQuickDiscardNum, InItemNum)

        if FinalDiscardNum > 0 then
            self:SetDiscardNum(TargetNumWidget, FinalDiscardNum)
            self:SetDiscardNumTextVisibility(TargetNumWidget, true)
        else
            self:SetDiscardNumTextVisibility(TargetNumWidget, false)
        end

    else
        self:SetDiscardNumTextVisibility(TargetNumWidget, false)
    end
end

function DetailKeyMap:HideAllNumber()
    for i, v in ipairs(self.AllInteractionKeyWidget) do
        if v then
            self:SetDiscardNumTextVisibility(v, false)
        end
    end
end

-- 设置丢弃个数。InDiscardNum 应传入整数
function DetailKeyMap:SetDiscardNum(InWidget, InDiscardNum)
    if not InWidget then return end
    if not InDiscardNum then return end
    if InDiscardNum < 0 then return end

    if InWidget.GUITextBlock_Parentheses_Value then
        InWidget.GUITextBlock_Parentheses_Value:SetText(tostring(InDiscardNum))
    end
end

-- 设置丢弃个数文字显示状态。InState 应传入 true/false
function DetailKeyMap:SetDiscardNumTextVisibility(InWidget, InState)
    if not InWidget then return end
    if InWidget.GUITextBlock_Parentheses_L then
        if InState then
            InWidget.GUITextBlock_Parentheses_L:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            InWidget.GUITextBlock_Parentheses_L:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end

    if InWidget.GUITextBlock_Parentheses_R then
        if InState then
            InWidget.GUITextBlock_Parentheses_R:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            InWidget.GUITextBlock_Parentheses_R:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end

    if InWidget.GUITextBlock_Parentheses_Value then
        if InState then
            InWidget.GUITextBlock_Parentheses_Value:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            InWidget.GUITextBlock_Parentheses_Value:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end


function DetailKeyMap:SetInteractionKeyWidgetVisibility(InKeyCombinationName, InVisibilityState)
    local CurWidget = self:GetTargetInteractionKeyByName(InKeyCombinationName)
    if CurWidget then
        if InVisibilityState then
            CurWidget:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            CurWidget:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end


return DetailKeyMap