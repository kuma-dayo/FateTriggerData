--[[
    角色展示板，成就展示层
]]
local SuperClassName = "Client.Modules.Hero.HeroDisplay.Layers.WBP_HeroDisplayLayerBase"
local WBP_HeroDisplayLayerAchieve = Class(SuperClassName)

function WBP_HeroDisplayLayerAchieve:OnInit()
    self.Super.OnInit(self)
    CWaring("WBP_HeroDisplayLayerAchieve:OnInit()")


    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then -- 局内
    else
        self.MsgList = {
            {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_ACHIEVE_SHOW,	Func = Bind(self,self.ON_HERO_DISPLAYBOARD_ACHIEVE_SHOW_Func) },
            {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_ACHIEVE_CHANGE,	Func = Bind(self,self.ON_HERO_DISPLAYBOARD_ACHIEVE_CHANGE_Func) },
        }
    end
end

function WBP_HeroDisplayLayerAchieve:OnShow(Param)
    self.Super.OnShow(self,Param)
end

function WBP_HeroDisplayLayerAchieve:OnHide()
    self.Super.OnHide(self)
end

function WBP_HeroDisplayLayerAchieve:GetTextureWidget(Slot)
    if Slot == 1 then
        return self.AchImg_1
    elseif Slot == 2 then
        return self.AchImg_2
    elseif Slot == 3 then
        return self.AchImg_3
    end
end

function WBP_HeroDisplayLayerAchieve:UpdateDisplayLayerTexture(Slot, AchieveId)
    if not(self:GetIsOpen()) then
        return
    end
    
    local Widget = self:GetTextureWidget(Slot)
    if Widget == nil then
        return 
    end
    Widget:SetVisibility(AchieveId == 0 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)

    -- local AchieveCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_AchievementCfg, Cfg_AchievementCfg_P.MissionID, AchieveId)
    -- local IconPath = AchieveCfg and AchieveCfg[Cfg_AchievementCfg_P.Image] or ""
    -- local AchieveCfg = G_ConfigHelper:GetSingleItemByKeys(Cfg_AchievementCfg, {Cfg_AchievementCfg_P.MissionID,Cfg_AchievementCfg_P.SubID},{AchieveId, 1})
    -- local IconPath = AchieveCfg and AchieveCfg[Cfg_AchievementCfg_P.Image] or ""
    -- CommonUtil.SetBrushFromSoftObjectPath(Widget, AchieveCfg and AchieveCfg[Cfg_AchievementCfg_P.Image] or "") 

    local IconPath = MvcEntry:GetModel(AchievementModel):GetAchievementIcon(AchieveId)
    CommonUtil.SetBrushFromSoftObjectPath(Widget, IconPath) 
end

function WBP_HeroDisplayLayerAchieve:ON_HERO_DISPLAYBOARD_ACHIEVE_SHOW_Func(_, Param)
    if not(self:GetIsOpen()) then
        return
    end

    local DisplayId = Param.DisplayId
    if self:GetDisplayId() ~= DisplayId then
        return
    end
    self:UpdateUI()
end

function WBP_HeroDisplayLayerAchieve:UpdateUI()
    if not(self:GetIsOpen()) then
        return
    end

    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then -- 局内
        --局内3D展示只要这里更新就可以，外部调用这个函数
    else
        local bIsLock = not (MvcEntry:GetModel(HeroModel):CheckGotHeroById(self:GetDisplayId()))
        if bIsLock then
            -- 英雄未解锁
            for Slot= 1, HeroDefine.SLOT_NUM, 1 do
                local AchiveId = 0
                self:UpdateDisplayLayerTexture(Slot, AchiveId)
            end
        else
            local DisplayId = self:GetDisplayId()
            -- local AchiveId = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardAchieveId(DisplayId, 1)
            -- self:UpdateDisplayLayerTexture(1, AchiveId)
            -- AchiveId = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardAchieveId(DisplayId, 2)
            -- self:UpdateDisplayLayerTexture(2, AchiveId)
            -- AchiveId = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardAchieveId(DisplayId, 3)
            -- self:UpdateDisplayLayerTexture(3, AchiveId)
            for Slot= 1, HeroDefine.SLOT_NUM, 1 do
                local AchiveId = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardAchieveId(DisplayId, Slot)
                self:UpdateDisplayLayerTexture(Slot, AchiveId)
            end
        end
    end
end

function WBP_HeroDisplayLayerAchieve:UpdateUIInBattle(UpdateParam)
    if UpdateParam and UpdateParam.AchieveMap then
        local idx = 1
        for k, v in pairs(UpdateParam.AchieveMap) do
            self:UpdateDisplayLayerTexture(idx, v)
            idx = idx + 1
        end
    end
end

function WBP_HeroDisplayLayerAchieve:SetUIByParam(Param)
    if Param and Param.SlotToAchieveId then
        for slot = 1, HeroDefine.SLOT_NUM do
            self:UpdateDisplayLayerTexture(slot, Param.SlotToAchieveId[slot] or 0)
        end
    end
end

function WBP_HeroDisplayLayerAchieve:ON_HERO_DISPLAYBOARD_ACHIEVE_CHANGE_Func(_, Param)
    if not(self:GetIsOpen()) then
        return
    end

    if Param == nil then
        return
    end
    local DisplayId = Param.DisplayId
    local AchieveId = Param.AchieveId
    local Slot = Param.Slot

    if self:GetDisplayId() ~= DisplayId then
        return
    end
    self:UpdateDisplayLayerTexture(Slot, AchieveId)
end





return WBP_HeroDisplayLayerAchieve