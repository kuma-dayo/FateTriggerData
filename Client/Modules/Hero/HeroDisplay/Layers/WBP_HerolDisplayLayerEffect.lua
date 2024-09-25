--[[
    角色展示板，Effect 层
]]
local SuperClass = "Client.Modules.Hero.HeroDisplay.Layers.WBP_HeroDisplayLayerBase"
local WBP_HerolDisplayLayerEffect = Class(SuperClass)

function WBP_HerolDisplayLayerEffect:OnInit()
    self.Super.OnInit(self)
    CWaring("WBP_HerolDisplayLayerEffect:OnInit()")


    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then -- 局内
    else
        self.MsgList = {
            {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_EFFECT_SHOW,	Func = Bind(self,self.ON_HERO_DISPLAYBOARD_EFFECT_SHOW_Func) },
            {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_EFFECT_CHANGE,	Func = Bind(self,self.ON_HERO_DISPLAYBOARD_EFFECT_CHANGE_Func) },
        }
    end
end

function WBP_HerolDisplayLayerEffect:OnShow(Param)
    self.Super.OnShow(self,Param)
end

function WBP_HerolDisplayLayerEffect:OnHide()
    self.Super.OnHide(self)
end

function WBP_HerolDisplayLayerEffect:UpdateEffectTexture(EffectId)
    if not(self:GetIsOpen()) then
        return
    end

    local EffectCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayEffect, Cfg_HeroDisplayEffect_P.Id, EffectId)
    if EffectCfg ~= nil then
        self.ImageEffect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.ImageEffect, EffectCfg[Cfg_HeroDisplayEffect_P.ResPath]) 
    else
        self.ImageEffect:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function WBP_HerolDisplayLayerEffect:UpdateUI()
    if not(self:GetIsOpen()) then
        return
    end

    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then -- 局内
    else
        local bIsLock = not (MvcEntry:GetModel(HeroModel):CheckGotHeroById(self:GetDisplayId()))
        if bIsLock then
            -- 英雄未解锁
            -- 获取英雄角色面板的默认配置
            ---@type DisplayBoardNode
            local DisplayData = MvcEntry:GetModel(HeroModel):GetDefaultDisplayBoardData(self:GetDisplayId())
            local EffectId = DisplayData and DisplayData.EffectId or 0
            self:UpdateEffectTexture(EffectId)
        else
            local EffectId = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardEffectId(self:GetDisplayId())
            self:UpdateEffectTexture(EffectId)
        end
    end
end
function WBP_HerolDisplayLayerEffect:UpdateUIInBattle(UpdateParam)
    if UpdateParam and UpdateParam.EffectId then
        self:UpdateEffectTexture(UpdateParam.EffectId)
    end
end

function WBP_HerolDisplayLayerEffect:SetUIByParam(Param)
    if Param and Param.EffectId then
        self:UpdateEffectTexture(Param.EffectId)
    end
end

function WBP_HerolDisplayLayerEffect:ON_HERO_DISPLAYBOARD_EFFECT_SHOW_Func(_, Param)
    if not(self:GetIsOpen()) then
        return
    end

    if Param == nil then
        return
    end
    local DisplayId = Param.DisplayId
    if self:GetDisplayId() ~= DisplayId then
        return
    end
    self:UpdateUI()
end

function WBP_HerolDisplayLayerEffect:ON_HERO_DISPLAYBOARD_EFFECT_CHANGE_Func(_, Param)
    if not(self:GetIsOpen()) then
        return
    end

    if Param == nil then
        return
    end
    local DisplayId = Param.DisplayId
    local EffectId = Param.EffectId

    if self:GetDisplayId() ~= DisplayId then
        return
    end
    self:UpdateEffectTexture(EffectId)
end


return WBP_HerolDisplayLayerEffect