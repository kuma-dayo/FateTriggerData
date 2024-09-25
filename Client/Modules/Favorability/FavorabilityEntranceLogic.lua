--[[
    角色界面-好感度入口
]]
local class_name = "FavorabilityEntranceLogic"
local FavorabilityEntranceLogic = BaseClass(nil, class_name)


function FavorabilityEntranceLogic:OnInit()
    self.BindNodes = {
    	{ UDelegate = self.View.GUIButtonEntrance.OnClicked,	Func = Bind(self,self.GUIButtonEntrance_OnClicked) },
	}
    self.MsgList = {
        {Model = FavorabilityModel, MsgName = FavorabilityModel.FAVOR_VALUE_CHANGED, Func = Bind(self,self.UpdateLevelInfo)},
    }
    self.FavorModel = MvcEntry:GetModel(FavorabilityModel)
end

function FavorabilityEntranceLogic:OnShow()
end
function FavorabilityEntranceLogic:OnHide()
end

--[[
    HeroId - 对应的英雄id
]]
function FavorabilityEntranceLogic:UpdateUI(HeroId)
    if not HeroId then
        return
    end
    self.IsUnlock = false
    self.HeroId = HeroId
    self:UpdateLevelInfo()
end

function FavorabilityEntranceLogic:UpdateLevelInfo()
    if not self.HeroId then
        return
    end
    local HeroId = self.HeroId
    local FavorLevel = self.FavorModel:GetCurFavorLevel(HeroId)
    local HeroCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig,self.HeroId)
    local IsUnlock = FavorLevel > 0 and HeroCfg and HeroCfg[Cfg_HeroConfig_P.IsOpenFavor]
    if IsUnlock then
        self.View.WidgetSwitcher_Content:SetActiveWidget(self.View.Content_Normal)
        self.View.Text_Level:SetText(FavorLevel)
        local IsFull = self.FavorModel:IsFavorFullLevel(HeroId)
        -- 满级保持空进度不增长
        local CurValue = IsFull and 0 or self.FavorModel:GetCurFavorValue(HeroId)
        local MaxValue = self.FavorModel:GetMaxFavorValueForLevel(FavorLevel)
        self.View.ProgressLv:SetPercent(CurValue/MaxValue)
    else
        self.View.WidgetSwitcher_Content:SetActiveWidget(self.View.Content_Lock)
    end
end

function FavorabilityEntranceLogic:GUIButtonEntrance_OnClicked()
    local Param = {
        HeroId = self.HeroId
    }
    MvcEntry:OpenView(ViewConst.FavorablityMainMdt,Param)
end

return FavorabilityEntranceLogic
