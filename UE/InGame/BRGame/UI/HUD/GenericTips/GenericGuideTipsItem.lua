--
-- 战斗界面控件 - 通用提示(按键指南)
--
-- @COMPANY	ByteDance
-- @AUTHOR	飞羽
-- @DATE	2022.06.02
--

local GenericGuideTipsItem = Class("Common.Framework.UserWidget")


-------------------------------------------- Init/Destroy ------------------------------------

function GenericGuideTipsItem:OnInit()
	UserWidget.OnInit(self)
end

function GenericGuideTipsItem:OnDestroy()
	UserWidget.OnDestroy(self)
end

-------------------------------------------- Get/Set ------------------------------------


-------------------------------------------- Function ------------------------------------

--[[
    更新数据
    InParamerters: {
        bEnable = xxx,
        TextKey = xxx, TextTips = xxx,
		TopTips1 = xxx, TopTips2 = xxx,
    }
]]
function GenericGuideTipsItem:InitData(InParamerters)
    print("GenericGuideTipsItem", ">> InitData, ", GetObjectName(self))
    Dump(InParamerters, InParamerters, 9)
    
    self.Paramerters = InParamerters
    
    if InParamerters.bEnable then
        self.TxtGuideKey:SetText(InParamerters.TextKey or '')
        self.TxtGuideTips:SetText(InParamerters.TextTips or '')

        local bShowTopTips = InParamerters.TopTips1 and ('' ~= InParamerters.TopTips1)
        if bShowTopTips then
            self.TxtTopTips1:SetText(InParamerters.TopTips1)
            self.TxtTopTips2:SetText(InParamerters.TopTips2 or '')
        end
        self.TrsTopTips:SetVisibility(bShowTopTips and
            UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
    end
    self:SetVisibility(InParamerters.bEnable and
        UE.ESlateVisibility.HitTestInvisible or UE.ESlateVisibility.Collapsed)
end

-------------------------------------------- Callable ------------------------------------

return GenericGuideTipsItem
