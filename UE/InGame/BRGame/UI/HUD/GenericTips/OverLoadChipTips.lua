local OverLoadChipTips = Class("Common.Framework.UserWidget")

local TipsWidgetStyle = 
{
    ["TPP"] = 1,
    ["DefaultAim"] = 2,
    ["1X"] = 3,
    ["2X"] = 4,
    ["3X"] = 5,
    ["4X"] = 6,
    ["8X"] = 7,
    ["10X"] = 8,
}

function OverLoadChipTips:OnInit()
    local LocalPC = UE.UGameplayStatics.GetPlayerController(self, 0)
    if LocalPC then
        local LocalPS = UE.UPlayerStatics.GetCPS(LocalPC)
        if LocalPS then self.PlayerHealthBar:InitRefPS(LocalPS) end
    end
    UserWidget.OnInit(self)
end

function OverLoadChipTips:OnDestroy()
    UserWidget.OnDestroy(self)
end

function OverLoadChipTips:OnShow()
    self:VXE_LoadChip_In()
end

function OverLoadChipTips:OnClose()
    self:VXE_LoadChip_Out()
end

function OverLoadChipTips:UpdateData(Owner,NewCountDownTime,TipGenricBlackboard)
    local BlackBoardKeySelector = UE.FGenericBlackboardKeySelector()
    BlackBoardKeySelector.SelectedKeyName = "Tag"
    local NewTag, bFindTag = UE.UGenericBlackboardBlueprintFunctionLibrary.TryGetValueAsString(TipGenricBlackboard, BlackBoardKeySelector)
    if bFindTag then
        self:RemoveAllActiveWidgetStyleFlags()
        if NewTag and TipsWidgetStyle[NewTag] then
            self:AddActiveWidgetStyleFlags(TipsWidgetStyle[NewTag])
        end
    end
    --print("OverLoadChipTips:UpdateData:Tag=", NewTag, " TipsWidgetStyle[NewTag]=", TipsWidgetStyle[NewTag])
    local ScaleStr = self.HealthBarScale:GetText()
    local ScaleNum = tonumber(ScaleStr)
    if ScaleNum then
        local HealthBarSlot = UE.UWidgetLayoutLibrary.SlotAsOverlaySlot(self.HealthBarOverlay)
        local NewMargin = UE.FMargin()
        NewMargin.Left = -ScaleNum
        NewMargin.Right = -ScaleNum
        HealthBarSlot:SetPadding(NewMargin)
    end
end

return OverLoadChipTips