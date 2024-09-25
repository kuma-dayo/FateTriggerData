--[[
    角色展示板，BG层
]]
local SuperClass = "Client.Modules.Hero.HeroDisplay.Layers.WBP_HeroDisplayLayerBase"
local WBP_HeroDisplayLayerBg = Class(SuperClass)

function WBP_HeroDisplayLayerBg:OnInit()
    self.Super.OnInit(self)
    CWaring("WBP_HeroDisplayLayerBg:OnInit()")


    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then -- 局内
    else
        self.MsgList = {
            {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_FLOOR_SHOW,	Func = Bind(self,self.ON_HERO_DISPLAYBOARD_FLOOR_SHOW_Func) },
            {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_FLOOR_CHANGE,	Func = Bind(self,self.ON_HERO_DISPLAYBOARD_FLOOR_CHANGE_Func) },
        }
    end
end

function WBP_HeroDisplayLayerBg:OnShow(Param)
    self.Super.OnShow(self,Param)
end

function WBP_HeroDisplayLayerBg:OnHide()
    self.Super.OnHide(self)
end

function WBP_HeroDisplayLayerBg:UpdateFloorTexture(FloorId)
    if not(self:GetIsOpen()) then
        return
    end
    
    local FloorCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayFloor, Cfg_HeroDisplayFloor_P.Id, FloorId)
    if FloorCfg ~= nil then
        self.ImageBg:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        CommonUtil.SetBrushFromSoftObjectPath(self.ImageBg, FloorCfg[Cfg_HeroDisplayFloor_P.FloorResPath]) 
      
        if CommonUtil.IsValid(self.ImageFrame) then
            local FrameResPath = FloorCfg[Cfg_HeroDisplayFloor_P.FrameResPath]
            if FrameResPath and string.len(FrameResPath) > 1 then
                self.ImageFrame:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
                CommonUtil.SetBrushFromSoftObjectPath(self.ImageFrame, FrameResPath) 
            else
                self.ImageFrame:SetVisibility(UE.ESlateVisibility.Collapsed)
            end
        end
    else
        self.ImageBg:SetVisibility(UE.ESlateVisibility.Collapsed)
        self.ImageFrame:SetVisibility(UE.ESlateVisibility.Collapsed)
        CWaring(string.format("WBP_HeroDisplayLayerBg:UpdateFloorTexture, FloorCfg ~= nil!!!! FloorId = %s", tostring(FloorId)))
    end
end

function WBP_HeroDisplayLayerBg:UpdateUI()
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
            local FloorId = DisplayData and DisplayData.FloorId or 0
            self:UpdateFloorTexture(FloorId)
        else
            local FloorId = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardFloorId(self:GetDisplayId())
            self:UpdateFloorTexture(FloorId)
        end
    end
end

function WBP_HeroDisplayLayerBg:UpdateUIInBattle(UpdateParam)
    if UpdateParam and UpdateParam.FloorId then
        self:UpdateFloorTexture(UpdateParam.FloorId)
    end
end

function WBP_HeroDisplayLayerBg:SetUIByParam(Param)
    if Param and Param.FloorId then
        self:UpdateFloorTexture(Param.FloorId)
    end
end

function WBP_HeroDisplayLayerBg:ON_HERO_DISPLAYBOARD_FLOOR_SHOW_Func(_, Param)
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

function WBP_HeroDisplayLayerBg:ON_HERO_DISPLAYBOARD_FLOOR_CHANGE_Func(_, Param)
    if not(self:GetIsOpen()) then
        return
    end

    if Param == nil then
        return
    end
    local DisplayId = Param.DisplayId
    local FloorId = Param.FloorId

    if self:GetDisplayId() ~= DisplayId then
        return
    end
    self:UpdateFloorTexture(FloorId)
end


return WBP_HeroDisplayLayerBg