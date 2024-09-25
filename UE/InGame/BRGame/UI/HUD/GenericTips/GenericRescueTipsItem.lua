--
-- 战斗界面控件 - 通用救援提示
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.03.30
--

local ECountdownType = BattleUIHelper.ECountdownType

local ParentClassName = "InGame.BRGame.UI.HUD.GenericTips.GenericUseTipsItem"
local GenericUseTipsItem = require(ParentClassName)
local GenericRescueTipsItem = Class(ParentClassName)


-------------------------------------------- Init/Destroy ------------------------------------

function GenericRescueTipsItem:OnInit()
	--GenericUseTipsItem.OnInit(self)

    self.TrsRescueTips:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.TrsRescueProgress:SetVisibility(UE.ESlateVisibility.Collapsed)
	UserWidget.OnInit(self)
end

function GenericRescueTipsItem:OnDestroy()

	GenericUseTipsItem.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

function GenericRescueTipsItem:InitData(InParamerters)
	--GenericUseTipsItem.InitData(self, InParamerters)
end

function GenericRescueTipsItem:UpdateProgress(InCurValue, InMaxValue)      -- override
    local NewPercent = math.max(0, InCurValue) / InMaxValue
	self.ImgProgress:GetDynamicMaterial():SetScalarParameterValue("Progress", NewPercent)
    --self.GUIProgressBar:SetPercent(NewPercent)
end

-- 更新救援按键提示
function GenericRescueTipsItem:UpdateRescueTips(bEnableTips)
    local NewVisible = bEnableTips and
        UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed
    self.TrsRescueTips:SetVisibility(NewVisible)
end

--[[
    更新救援进度提示
    InParamerters: {
        bEnable = xxx, bRescueBreak = xxx, bEnableDoing = xxx,
        CountdownType = xxx, MaxValue = xxx, Text = xxx,
    }
]]
function GenericRescueTipsItem:UpdateRescueProgress(InParamerters)
    self.Paramerters = InParamerters

    local NewColor = (InParamerters.bRescueBreak) and
        UIHelper.LinearColor.Red or UIHelper.LinearColor.White
    self.ImgProgress:SetColorAndOpacity(NewColor)
    
    if InParamerters.bEnable then
        self.CurNumber = 0
        self.MaxNumber = InParamerters.MaxValue or 10
        self.CountdownType = InParamerters.CountdownType
        self.TxtTips:SetText(InParamerters.Text or '')
        self:UpdateWidget(0)

        self.TrsRescueProgress:SetRenderOpacity(1)
        self.TrsRescueProgress:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self:StopAnimationByName("Anim_RescueBreak")
        
    elseif (InParamerters.bRescueBreak) then
        self.TrsRescueProgress:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
        self:SimplePlayAnimationByName("Anim_RescueBreak", false)
    else
        self.TrsRescueProgress:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function GenericRescueTipsItem:UpdateWidget(InDeltaTime)
    if (not self.Paramerters) or (not self.Paramerters.bEnableDoing) then
        return
    end
    
	GenericUseTipsItem.UpdateWidget(self, InDeltaTime)
end

-------------------------------------------- Callable ------------------------------------

return GenericRescueTipsItem
