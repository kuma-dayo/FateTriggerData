--[[
    好感度信息
]]
local class_name = "FavorabilityInfoLogic"
local FavorabilityInfoLogic = BaseClass(nil, class_name)


function FavorabilityInfoLogic:OnInit()
    self.BindNodes = {}
    self.MsgList = {
        {Model = FavorabilityModel, MsgName = FavorabilityModel.FAVOR_VALUE_CHANGED, Func = Bind(self,self.UpdateLevelInfo)},
    }
    self.FavorModel = MvcEntry:GetModel(FavorabilityModel)
end

function FavorabilityInfoLogic:OnShow()
end

function FavorabilityInfoLogic:OnHide()
end

--[[
    HeroId - 对应的英雄id
]]
function FavorabilityInfoLogic:UpdateUI(HeroId)
    if not HeroId then
        return
    end
    self.IsUnlock = false
    self.HeroId = HeroId
    self:UpdateLevelInfo()
   
end

function FavorabilityInfoLogic:UpdateLevelInfo()
    if not self.HeroId then
        return
    end
    local HeroId = self.HeroId
    local FavorLevel = self.FavorModel:GetCurFavorLevel(HeroId)
    local HeroCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig,self.HeroId)
    local IsUnlock = FavorLevel > 0 and HeroCfg and HeroCfg[Cfg_HeroConfig_P.IsOpenFavor]
    if IsUnlock then
        self.View.Text_Level:SetText(FavorLevel)
        local IsMax = self.FavorModel:IsFavorFullLevel(HeroId)
        if IsMax then
            self.View.ProgressNumPanel:SetVisibility(UE.ESlateVisibility.Collapsed) 
            self.View.Progress_Bar:SetVisibility(UE.ESlateVisibility.Collapsed) 
        else
            self.View.ProgressNumPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) 
            self.View.Progress_Bar:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) 
            local CurValue = self.FavorModel:GetCurFavorValue(HeroId)
            local MaxValue = self.FavorModel:GetMaxFavorValueForLevel(FavorLevel)
            self.View.Text_Cur:SetText(CurValue)
            self.View.Text_Max:SetText("/"..MaxValue)

            local Material = self.View.Progress:GetDynamicMaterial()
            if Material then
                Material:SetScalarParameterValue("Progress",CurValue/MaxValue)
            end
        end
    else
        self.View.Progress_Bar:SetVisibility(UE.ESlateVisibility.Collapsed) 
    end
end

return FavorabilityInfoLogic
