--[[
    角色展示板，英雄层
]]
local SuperClass = "Client.Modules.Hero.HeroDisplay.Layers.WBP_HeroDisplayLayerBase"
local WBP_HeroDisplayLayerHero = Class(SuperClass)

function WBP_HeroDisplayLayerHero:OnInit()
    self.Super.OnInit(self)
    CWaring("WBP_HeroDisplayLayerHero:OnInit()")

    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then -- 局内
    else
        self.MsgList = {
            {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_ROLE_SHOW,	Func = Bind(self,self.ON_HERO_DISPLAYBOARD_ROLE_SHOW_Func) },
            {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_ROLE_CHANGE,	Func = Bind(self,self.ON_HERO_DISPLAYBOARD_ROLE_CHANGE_Func) },
        }
    end
end

function WBP_HeroDisplayLayerHero:OnShow(Param)
    self.Super.OnShow(self,Param)
end

function WBP_HeroDisplayLayerHero:OnHide()
    self.Super.OnHide(self)
end

function WBP_HeroDisplayLayerHero:UpdateRoleTexture(RoleId)
    if not(self:GetIsOpen()) then
        return
    end
    
    local RoleCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayRole, Cfg_HeroDisplayRole_P.Id, RoleId)
    if RoleCfg ~= nil then
        self.ImageHero:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.ImageHero, RoleCfg[Cfg_HeroDisplayRole_P.ResPath]) 
    else
        self.ImageHero:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

function WBP_HeroDisplayLayerHero:UpdateUI()
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
            local RoleId = DisplayData and DisplayData.RoleId or 0
            self:UpdateRoleTexture(RoleId)
        else
            local RoleId = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardRoleId(self:GetDisplayId())
            self:UpdateRoleTexture(RoleId)
        end
    end
end

function WBP_HeroDisplayLayerHero:UpdateUIInBattle(UpdateParam)
    if UpdateParam and UpdateParam.RoleId then
        self:UpdateRoleTexture(UpdateParam.RoleId)
    end
end

function WBP_HeroDisplayLayerHero:SetUIByParam(Param)
    if Param and Param.RoleId then
        self:UpdateRoleTexture(Param.RoleId)
    end
end

function WBP_HeroDisplayLayerHero:ON_HERO_DISPLAYBOARD_ROLE_SHOW_Func(_, Param)
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


function WBP_HeroDisplayLayerHero:ON_HERO_DISPLAYBOARD_ROLE_CHANGE_Func(_, Param)
    if not(self:GetIsOpen()) then
        return
    end

    if Param == nil then
        return
    end
    local DisplayId = Param.DisplayId
    local RoleId = Param.RoleId

    if self:GetDisplayId() ~= DisplayId then
        return
    end
    self:UpdateRoleTexture(RoleId)
end


return WBP_HeroDisplayLayerHero