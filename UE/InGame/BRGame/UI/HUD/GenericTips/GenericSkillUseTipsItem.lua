--
-- 战斗界面控件 - 通用技能使用提示
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.06.22
--

local ECountdownType = BattleUIHelper.ECountdownType

local GenericSkillUseTipsItem = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function GenericSkillUseTipsItem:OnInit()
    self:SetVisibility(UE.ESlateVisibility.Collapsed)

	UserWidget.OnInit(self)
end

function GenericSkillUseTipsItem:OnDestroy()

	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

--[[
    local InParamerters = {
		bEnable = xxx, bIsCasting = xxx,
		IconAsset = xxx, MaxValue = xxx,
		CountdownType = ECountdownType.NumberLess_ProgressAdd, 
	}
]]
function GenericSkillUseTipsItem:InitData(InParamerters)
    self.Paramerters = InParamerters

    if self.Paramerters and self.Paramerters.bEnable then
        self.CurNumber = 0
        self.MaxNumber = InParamerters.MaxValue or 10
        self.CountdownType = InParamerters.CountdownType
        --self.TxtTips:SetText(InParamerters.Text or '')

        self.TrsProgress:SetVisibility(InParamerters.bIsCasting and 
            UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
        self.TrsGuideTips_Fly:SetVisibility((not InParamerters.bIsCasting) and 
            UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
            
        if "" ~= InParamerters.IconAsset then
            self.ImgIcon:SetBrushFromSoftTexture(InParamerters.IconAsset, false)
        end

        self:UpdateWidget(0)
        self:SetVisibility(UE.ESlateVisibility.HitTestInvisible)
    else
        self:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function GenericSkillUseTipsItem:UpdateWidget(InDeltaTime)
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

    local NewPercent = math.max(0, CurProgressValue) / self.MaxNumber
    self.TxtNum:SetText(string.format("%.1f", math.max(0, CurNumberValue)))
	self.BarProgress:SetPercent(NewPercent)
end

-------------------------------------------- Callable ------------------------------------

-- 
function GenericSkillUseTipsItem:Tick(MyGeometry, InDeltaTime)
    if self.Paramerters and self.Paramerters.bEnable then
        self:UpdateWidget(InDeltaTime)
    end
end

return GenericSkillUseTipsItem
