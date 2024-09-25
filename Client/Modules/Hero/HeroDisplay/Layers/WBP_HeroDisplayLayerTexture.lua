--[[
    角色展示板，贴图层
]]

local SuperClass = "Client.Modules.Hero.HeroDisplay.Layers.WBP_HeroDisplayLayerBase"
local WBP_HeroDisplayLayerTexture = Class(SuperClass)

function WBP_HeroDisplayLayerTexture:OnInit()
    self.Super.OnInit(self)
    CWaring("WBP_HeroDisplayLayerTexture:OnInit()")

    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then -- 局内
    else
        self.MsgList = {
            { Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_STICKER_CHANGE,	Func = Bind(self,self.ON_HERO_DISPLAYBOARD_STICKER_CHANGE_Func) },
            { Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_STICKER_SHOW,	Func = Bind(self,self.ON_HERO_DISPLAYBOARD_STICKER_SHOW_Func) },
        }
    end
end

function WBP_HeroDisplayLayerTexture:OnShow(Param)
    self.Super.OnShow(self,Param)
end

function WBP_HeroDisplayLayerTexture:OnHide()
    self.Super.OnHide(self)
end

function WBP_HeroDisplayLayerTexture:GetTextureWidget(Slot)
    if Slot == 1 then
        return self.StickerImg_1
    elseif Slot == 2 then
        return self.StickerImg_2
    elseif Slot == 3 then
        return self.StickerImg_3
    end
end

function WBP_HeroDisplayLayerTexture:UpdateUI()
    if not(self:GetIsOpen()) then
        return
    end

    if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then -- 局内
    else
        local DisplayId = self:GetDisplayId()
        local bIsLock = not (MvcEntry:GetModel(HeroModel):CheckGotHeroById(DisplayId))
        if bIsLock then
            -- 英雄未解锁
            -- 获取英雄角色面板的默认配置
            ---@type DisplayBoardNode
            local DisplayData = MvcEntry:GetModel(HeroModel):GetDefaultDisplayBoardData(DisplayId)
            for Slot= 1, HeroDefine.STICKER_SLOT_NUM, 1 do
                local StickerInfo = DisplayData and DisplayData.SlotToStickerInfo[Slot] or nil
                self:UpdateDisplayLayerTexture(Slot, StickerInfo and StickerInfo.StickerId or 0, StickerInfo)
            end
        else
            local DisplayId = self:GetDisplayId()
            -- local StickerInfo = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardSticker(DisplayId, 1)
            -- self:UpdateDisplayLayerTexture(1, StickerInfo and StickerInfo.StickerId or 0, StickerInfo)
            -- StickerInfo = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardSticker(DisplayId, 2)
            -- self:UpdateDisplayLayerTexture(2, StickerInfo and StickerInfo.StickerId or 0, StickerInfo)
            -- StickerInfo = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardSticker(DisplayId, 3)
            -- self:UpdateDisplayLayerTexture(3, StickerInfo and StickerInfo.StickerId or 0, StickerInfo)
            for Slot= 1, HeroDefine.STICKER_SLOT_NUM, 1 do
                local StickerInfo = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardSticker(DisplayId, Slot)
                self:UpdateDisplayLayerTexture(Slot, StickerInfo and StickerInfo.StickerId or 0, StickerInfo)
            end
        end
    end

end
function WBP_HeroDisplayLayerTexture:UpdateUIInBattle(UpdateParam)
    if UpdateParam and UpdateParam.StickerMap then
        local idx = 1
        for k, StickerInfo in pairs(UpdateParam.StickerMap) do
            self:UpdateDisplayLayerTexture(idx, StickerInfo and StickerInfo.StickerId or 0, StickerInfo)
            idx = idx + 1
        end
    end
end

function WBP_HeroDisplayLayerTexture:SetUIByParam(Param)
    if Param and Param.SlotToStickerInfo then
        local idx = 1
        for slot = 1, HeroDefine.STICKER_SLOT_NUM do
            ---@type LbStickerNode
            local StickerInfo = Param.SlotToStickerInfo[slot]
            self:UpdateDisplayLayerTexture(idx, StickerInfo and StickerInfo.StickerId or 0, StickerInfo)
        end
    end
end

function WBP_HeroDisplayLayerTexture:UpdateDisplayLayerTexture(Slot, StickerId, StickerInfo)
    if not(self:GetIsOpen()) then
        return
    end

    local Widget = self:GetTextureWidget(Slot)
    if Widget == nil then
        return 
    end
    if StickerInfo ~= nil then
        local Float2IntScale = 1
        if MvcEntry:GetModel(ViewModel):GetState(ViewConst.LevelBattle) then -- 局内
        else
            Float2IntScale = HeroModel.DISPLAYBOARD_FLOAT2INTSCALE
        end
        local Angle = StickerInfo.Angle and StickerInfo.Angle / Float2IntScale  or 0
        local ScaleX = StickerInfo.ScaleX and StickerInfo.ScaleX / Float2IntScale or 1
        local ScaleY = StickerInfo.ScaleY and StickerInfo.ScaleY / Float2IntScale or 1
        local XPos = StickerInfo.XPos and StickerInfo.XPos / Float2IntScale or 0
        local YPos = StickerInfo.YPos and StickerInfo.YPos / Float2IntScale or 0
        CLog(StringUtil.Format("StickerInfo.XPos:{0}, StickerInfo.YPos:{1}",StickerInfo.XPos, StickerInfo.YPos))
        CLog(StringUtil.Format("Slot:{0}, XPos:{1}, YPos:{2}",Slot,XPos,YPos))
        Widget:SetRenderTransformAngle(Angle)
        Widget:SetRenderScale(UE.FVector2D(ScaleX,ScaleY))
        Widget:GetParent().Slot:SetPosition(UE.FVector2D(XPos, YPos))
        --CError(string.format("DDDDDDDDDDDDDDDDDDDDDDDD: Widget:GetParent() = ",UE.UKismetSystemLibrary.GetDisplayName(Widget:GetParent())))
    end

    Widget:SetVisibility(StickerId == 0 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    local StickerCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplaySticker, Cfg_HeroDisplaySticker_P.Id, StickerId)
    CommonUtil.SetBrushFromSoftObjectPath(Widget, StickerCfg and StickerCfg[Cfg_HeroDisplaySticker_P.ResPath] or "") 
end


function WBP_HeroDisplayLayerTexture:ON_HERO_DISPLAYBOARD_STICKER_SHOW_Func(_, Param)
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

function WBP_HeroDisplayLayerTexture:ON_HERO_DISPLAYBOARD_STICKER_CHANGE_Func(_, Param)
    if not(self:GetIsOpen()) then
        return
    end
    
    if Param == nil then
        return
    end
    local DisplayId = Param.DisplayId
    local StickerId = Param.StickerId
    local Slot = Param.Slot
    if self:GetDisplayId() ~= DisplayId then
        return
    end
    self:UpdateDisplayLayerTexture(Slot, StickerId, Param.StickerInfo)
end



return WBP_HeroDisplayLayerTexture