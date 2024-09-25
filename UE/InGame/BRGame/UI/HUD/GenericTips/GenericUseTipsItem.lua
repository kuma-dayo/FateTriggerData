--
-- 战斗界面控件 - 通用使用提示
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.30
--
require("InGame.BRGame.UI.HUD.BattleUIHelper")

local ECountdownType = BattleUIHelper.ECountdownType

local GenericUseTipsItem = Class("Common.Framework.UserWidget")

-------------------------------------------- Init/Destroy ------------------------------------

function GenericUseTipsItem:OnInit()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)

    UserWidget.OnInit(self)
end

function GenericUseTipsItem:OnDestroy()

    UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------

-------------------------------------------- Function ------------------------------------

--[[
    InParamerters: { bEnable = xxx, CountdownType = xxx, MaxValue = xxx, Text = xxx,  }
]]
function GenericUseTipsItem:InitData(InParamerters)
    self.Paramerters = InParamerters

    if self.Paramerters and self.Paramerters.bEnable then
        self.CurNumber = 0
        self.MaxNumber = InParamerters.MaxValue or 10
        self.CountdownType = InParamerters.CountdownType
        self.TxtTips:SetText(InParamerters.Text or '')

        self:UpdateWidget(0)
        self:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    else
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function GenericUseTipsItem:UpdateWidget(InDeltaTime)
    if (not self.CurNumber) or (self.CurNumber > self.MaxNumber) then
        return
    end

    self.CurNumber = self.CurNumber + InDeltaTime

    local CurNumberValue, CurProgressValue = 0, 0
    if self.CountdownType == ECountdownType.NumberAdd_ProgressAdd then
        CurNumberValue = self.CurNumber
        CurProgressValue = CurNumberValue
    elseif self.CountdownType == ECountdownType.NumberAdd_ProgressLess then
        CurNumberValue = self.CurNumber
        CurProgressValue = (self.MaxNumber - self.CurNumber)
    elseif self.CountdownType == ECountdownType.NumberLess_ProgressAdd then
        CurNumberValue = (self.MaxNumber - self.CurNumber)
        CurProgressValue = self.CurNumber
    elseif self.CountdownType == ECountdownType.NumberLess_ProgressLess then
        CurNumberValue = (self.MaxNumber - self.CurNumber)
        CurProgressValue = CurNumberValue
    end

    self.TxtNum:SetText(string.format("%.1f", math.max(0, CurNumberValue)))

    self:UpdateProgress(CurProgressValue, self.MaxNumber)
end

function GenericUseTipsItem:UpdateProgress(InCurValue, InMaxValue)
    local NewPercent = math.max(0, InCurValue) / InMaxValue
    -- self.ImgProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", NewPercent)

    --Log.info("hzy Discovering builds for {0}", NewPercent)
    -- self.GUIProgressBar:SetPercent(NewPercent)
end

-------------------------------------------- Callable ------------------------------------

-- 
function GenericUseTipsItem:Tick(MyGeometry, InDeltaTime)
    if self.Paramerters and self.Paramerters.bEnable then
        self:UpdateWidget(InDeltaTime)
    end
end

return GenericUseTipsItem
