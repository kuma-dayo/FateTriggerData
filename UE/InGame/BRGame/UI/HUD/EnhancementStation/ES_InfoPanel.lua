---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hudi.
--- DateTime: 2023/9/8 16:34
---

local ES_InfoPanel = Class("Common.Framework.UserWidget")

local function GetInt(BlackBoard, Key)
    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackBoardKeySelector.SelectedKeyName = Key
    local Value, Result = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsInt(BlackBoard, BlackBoardKeySelector)
    return Value
end

local function GetName(BlackBoard, Key)
    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackBoardKeySelector.SelectedKeyName = Key
    local Value, Result = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsName(BlackBoard, BlackBoardKeySelector)
    return Value
end

local function GetBool(BlackBoard, Key)
    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackBoardKeySelector.SelectedKeyName = Key
    local Value, Result = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsBool(BlackBoard, BlackBoardKeySelector)
    return Value
end

local function GetString(BlackBoard, Key)
    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackBoardKeySelector.SelectedKeyName = Key
    local Value, Result = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(BlackBoard, BlackBoardKeySelector)
    return Value
end

local function GetEnum(BlackBoard, Key)
    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackBoardKeySelector.SelectedKeyName = Key
    local Value, Result = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsEnum(BlackBoard, BlackBoardKeySelector)
    return Value
end

local function GetFloat(BlackBoard, Key)
    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackBoardKeySelector.SelectedKeyName = Key
    local Value, Result = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsFloat(BlackBoard, BlackBoardKeySelector)
    return Value
end


function ES_InfoPanel:OnUpdate(Context, BlackBoard)
    -- EnhanceState 0:准备 1:制作中 2：制作成功 3：售罄
    local EnhanceState = GetInt(BlackBoard, "EnhanceState")
    local AttributeId = GetName(BlackBoard, "EnhanceAttribute")

    if EnhanceState == 0 then
        --0.准备
        self.WidgetSwitcher_Screen:SetActiveWidgetIndex(0)
        self.ProgressSwitcher:SetActiveWidgetIndex(0)
        local StationType = GetEnum(BlackBoard, "StationType")
        local StationTypeText = ""
        if StationType == UE.EEnhancementStationType.Weapon then
            StationTypeText = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ES_Weaponsentry"))
        end
        if StationType == UE.EEnhancementStationType.ArmorHead then
            StationTypeText = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ES_Helmetentry"))
        end
        if StationType == UE.EEnhancementStationType.Bag then
            StationTypeText = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ES_Backpackentry"))
        end
        if StationType == UE.EEnhancementStationType.ArmorBody then
            StationTypeText = StringUtil.Format(G_ConfigHelper:GetStrFromCommonStaticST("Lua_ES_Armorentry"))
        end

        self.Text_Title:SetText(StationTypeText)
        self.Text_Title_2:SetText(StationTypeText)

        local bMultiPrice = GetBool(BlackBoard, "bMultiPrice")
        if bMultiPrice then
            self.Text_Price_Min:SetText(GetInt(BlackBoard, "EnhancePriceMin"))
            self.Text_Price_Max:SetText(GetInt(BlackBoard, "EnhancePriceMax"))
            self.Text_Price_Max:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            self.Text_Price_3:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        else
            self.Text_Price_Max:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.Text_Price_3:SetVisibility(UE.ESlateVisibility.Collapsed)
            self.Text_Price_Min:SetText(GetInt(BlackBoard, "EnhancePrice"))
            if AttributeId then
                local Data = UE.UEnhancementSettings.GetAttributeDataById(Context, AttributeId)
                self.EnhanceIcon:SetBrushFromSoftTexture(UE.UGFUnluaHelper.ToSoftObjectPtr(Data.EnhanceIcon), true)

                --local ItemLevel = UE.UEnhancementSettings.GetItemLevelById(Context, AttributeId)
                --todo self.EnhanceBG:SetBrushTintColor(self.TintColorArray[ItemLevel])
            end
        end   
        local EquipSoftTex2D = self.EquipIconMap:Find(StationType)
        if EquipSoftTex2D then
            self.Img_EquipmentIcon:SetBrushFromSoftTexture(EquipSoftTex2D,false)
        end
        self.WidgetSwitcher_0:SetActiveWidgetIndex(StationType ~= UE.EEnhancementStationType.Weapon and 1 or 0)  
    elseif EnhanceState == 1 then
        -- 1:制作中 
        self.WidgetSwitcher_Screen:SetActiveWidgetIndex(0)
        self.ProgressSwitcher:SetActiveWidgetIndex(1)
        self.EnhanceDuration = GetFloat(BlackBoard, "EnhanceDuration")
        self.EnhanceTimer = self.EnhanceDuration
        self.EnhanceTimerHandle = UE.UKismetSystemLibrary.K2_SetTimerDelegate({self, self.UpdateProgressBar}, 0.05, true, 0, 0)
        self.EnhanceTimerBar:SetPercent(1)
        if AttributeId then
            local Data = UE.UEnhancementSettings.GetAttributeDataById(Context, AttributeId)
            if Data then
                self.EnhanceIcon:SetBrushFromSoftTexture(UE.UGFUnluaHelper.ToSoftObjectPtr(Data.EnhanceIcon), true)
            end
            --local ItemLevel = UE.UEnhancementSettings.GetItemLevelById(Context, AttributeId)
            --todo self.EnhanceBG:SetBrushTintColor(self.TintColorArray[ItemLevel])
        end
    elseif EnhanceState == 2 then
        --2：制作成功 
        self.WidgetSwitcher_Screen:SetActiveWidgetIndex(1)
        if AttributeId then
            local Data = UE.UEnhancementSettings.GetAttributeDataById(Context, AttributeId)
            if Data then
                self.Image_Item_Success:SetBrushFromSoftTexture(UE.UGFUnluaHelper.ToSoftObjectPtr(Data.EnhanceIcon), true)
            end
        end
    elseif EnhanceState == 3 then
        --3：售罄
        self.WidgetSwitcher_Screen:SetActiveWidgetIndex(2)
        self.ResetDuration = GetFloat(BlackBoard, "ResetDuration")
        self.ResetTimer = self.ResetDuration
    end
end

function ES_InfoPanel:UpdateProgressBar()
    self.EnhanceTimer = self.EnhanceTimer - 0.05
    if self.EnhanceTimer < 0 then
        self.EnhanceTimer = 0
        UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.EnhanceTimerHandle)
    end
    self.EnhanceTimerBar:SetPercent(self.EnhanceTimer / self.EnhanceDuration)
    -- self.EnhanceTimerText:SetText(TimeUtils.getTimeStringSimple(math.ceil(self.EnhanceTimer)))
end

-- function ES_InfoPanel:UpdateResetTimeText()
--     self.ResetTimer = self.ResetTimer - 1
--     if self.ResetTimer < 0 then
--         self.ResetTimer = 0
--         UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.ResetTimerHandle)
--     end
--     --self.ResetTimerText:SetText(TimeUtils.getTimeStringSimple(math.ceil(self.ResetTimer)))
-- end


function ES_InfoPanel:OnDestroy()
    UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.EnhanceTimerHandle)
    UE.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.ResetTimerHandle)
end

return ES_InfoPanel