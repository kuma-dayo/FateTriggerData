class_name = "HeroDisplayBoard2D"
local HeroDisplayBoard2D = BaseClass(UIHandlerViewBase, class_name)

----------------------------------------
---@class LbStickerNode
---@field StickerId number 贴纸Id
---@field XPos number X偏移坐标
---@field YPos number Y偏移坐标
---@field Angle number 角度
---@field ScaleX number X缩放系数
---@field ScaleY number Y缩放系数
----------------------------------------
----------------------------------------
---@class DisplayBoardNode 角色面板数据
---@field HeroId number 
---@field FloorId number 
---@field RoleId number 
---@field EffectId number 
---@field SlotToAchieveId table<number,number> 
---@field SlotToStickerInfo table<number,LbStickerNode> 
----------------------------------------

local InitSize = UE.FVector2D(262, 254)
local InitLocalPos = UE.FVector2D(0, 270)

function HeroDisplayBoard2D:OnInit()
    self.MsgList = {

    }

    ---@type HeroModel
    self.ModelHero = MvcEntry:GetModel(HeroModel)
end

function HeroDisplayBoard2D:OnShow(Param)
    self:UpdateUI(Param)
end

function HeroDisplayBoard2D:OnManualShow(Param)
    self:UpdateUI(Param)
end

function HeroDisplayBoard2D:OnManualHide(Param)
end

function HeroDisplayBoard2D:OnHide(Param)
    self:ResetEditParam()
end

function HeroDisplayBoard2D:OnDestroy(Data, IsNotVirtualTrigger)
    
end

---获取自己的角色面板数据
function HeroDisplayBoard2D:AutoGetDisplayBoardData(InHeroId)
    local FloorId = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardFloorId(InHeroId)
    local RoleId = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardRoleId(InHeroId)
    local EffectId = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardEffectId(InHeroId)

    local SlotToStickerInfo = {}
    local SlotToAchieveId = {}
    for Slot = 1, HeroDefine.STICKER_SLOT_NUM, 1 do
        local StickerInfo = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardSticker(InHeroId, Slot)
        SlotToStickerInfo[Slot] = StickerInfo

        local AchiveId = MvcEntry:GetModel(HeroModel):GetSelectedDisplayBoardAchieveId(InHeroId, Slot)
        SlotToAchieveId[Slot] = AchiveId
    end

    local DisplayData = {
        HeroId = InHeroId,
        FloorId = FloorId,
        RoleId = RoleId,
        EffectId =EffectId,
        SlotToAchieveId = SlotToAchieveId,
        SlotToStickerInfo = SlotToStickerInfo,
    }
    return DisplayData
end

function HeroDisplayBoard2D:UpdateUI(Param)
    if Param == nil then
        return
    end

    if Param.HeroId == nil  then
        return
    end

    self.IsLock = not (MvcEntry:GetModel(HeroModel):CheckGotHeroById(Param.HeroId))
    if self.IsLock then
        -- 英雄未解锁
        -- 获取英雄角色面板的默认配置
        Param.DisplayData = MvcEntry:GetModel(HeroModel):GetDefaultDisplayBoardData(Param.HeroId)
    end
    if Param.DisplayData == nil then
        return
    end

    ---@type DisplayBoardNode
    self.DisplayData = Param.DisplayData 
    if self.DisplayData == nil then
        self.DisplayData = self:AutoGetDisplayBoardData(Param.HeroId)
    end
    self.HeroId = self.DisplayData.HeroId
   
    self:UpdateDisplayBoardFloor()
    self:UpdateDisplayBoardRole()
    self:UpdateDisplayBoardEffet()
    self:UpdateDisplayBoardSticker()
    self:UpdateDisplayBoardAchieve()
end

---获取对应的面板是否开启
function HeroDisplayBoard2D:GetDisplayBoardTabIsOpen(TabId)
    local bOpen = false
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayBoardTabConfig, TabId)
    if Cfg then
        bOpen = Cfg[Cfg_HeroDisplayBoardTabConfig_P.IsOpen]
    end
    return bOpen
end

---背景
function HeroDisplayBoard2D:UpdateDisplayBoardFloor()
    local bOpen = self:GetDisplayBoardTabIsOpen(EHeroDisplayBoardTabID.Floor.TabId)
    self.View.Image_Bg:SetVisibility(bOpen and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if CommonUtil.IsValid(self.View.Image_Frame) then
        self.View.Image_Frame:SetVisibility(bOpen and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed) 
    end

    if not(bOpen) then
        return
    end

    local FloorId = self.DisplayData.FloorId
    local FloorCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayFloor, Cfg_HeroDisplayFloor_P.Id, FloorId)
    CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_Bg, FloorCfg and FloorCfg[Cfg_HeroDisplayFloor_P.FloorResPath] or "") 
    if CommonUtil.IsValid(self.View.Image_Frame) then
        local FrameResPath = FloorCfg and FloorCfg[Cfg_HeroDisplayFloor_P.FrameResPath] or ""
        if FrameResPath and string.len(FrameResPath) > 1 then
            self.View.Image_Frame:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
            CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_Frame, FrameResPath) 
        else    
            self.View.Image_Frame:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
    end
end

---角色
function HeroDisplayBoard2D:UpdateDisplayBoardRole()
    local bOpen = self:GetDisplayBoardTabIsOpen(EHeroDisplayBoardTabID.Role.TabId)
    self.View.Image_Role:SetVisibility(bOpen and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if not(bOpen) then
        return
    end

    local RoleId = self.DisplayData.RoleId
    local RoleCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayRole, Cfg_HeroDisplayRole_P.Id, RoleId)
    CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_Role, RoleCfg and RoleCfg[Cfg_HeroDisplayRole_P.ResPath] or "" ) 
end

---特效
function HeroDisplayBoard2D:UpdateDisplayBoardEffet()
    local bOpen = self:GetDisplayBoardTabIsOpen(EHeroDisplayBoardTabID.Effect.TabId)
    self.View.Image_VX:SetVisibility(bOpen and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if not(bOpen) then
        return
    end

    local EffectId = self.DisplayData.EffectId
    local EffectCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayEffect, Cfg_HeroDisplayEffect_P.Id, EffectId)
    CommonUtil.SetBrushFromSoftObjectPath(self.View.Image_VX, EffectCfg and EffectCfg[Cfg_HeroDisplayEffect_P.ResPath] or "") 
end

-----------------------贴纸>>

---获取贴纸Widget
function HeroDisplayBoard2D:GetStickerImgWidget(Slot)
    if Slot == 1 then
        return self.View.StickerImg_1
    elseif Slot == 2 then
        return self.View.StickerImg_2
    elseif Slot == 3 then
        return self.View.StickerImg_3
    elseif Slot == 4 then
        return self.View.StickerImg_Edit
    end
    return nil
end

---@param StickerInfo LbStickerNode
function HeroDisplayBoard2D:UpdateDisplayLayerTexture(Slot, StickerId, StickerInfo)
    local Widget = self:GetStickerImgWidget(Slot)
    if Widget == nil then
        return 
    end

    Widget:SetVisibility(StickerId == 0 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    local StickerCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplaySticker, Cfg_HeroDisplaySticker_P.Id, StickerId)
    CommonUtil.SetBrushFromSoftObjectPath(Widget, StickerCfg and StickerCfg[Cfg_HeroDisplaySticker_P.ResPath] or "") 

    if StickerInfo ~= nil then
        local Float2IntScale = HeroModel.DISPLAYBOARD_FLOAT2INTSCALE
        local Angle = StickerInfo.Angle and StickerInfo.Angle / Float2IntScale  or 0
        local ScaleX = StickerInfo.ScaleX and StickerInfo.ScaleX / Float2IntScale or 1
        local ScaleY = StickerInfo.ScaleY and StickerInfo.ScaleY / Float2IntScale or 1
        local XPos = StickerInfo.XPos and StickerInfo.XPos / Float2IntScale or 0
        local YPos = StickerInfo.YPos and StickerInfo.YPos / Float2IntScale or 0
        -- CLog(StringUtil.Format("StickerInfo.XPos:{0}, StickerInfo.YPos:{1}",StickerInfo.XPos, StickerInfo.YPos))
        -- CLog(StringUtil.Format("Slot:{0}, XPos:{1}, YPos:{2}",Slot,XPos,YPos))
        Widget:SetRenderTransformAngle(Angle)
        Widget:SetRenderScale(UE.FVector2D(ScaleX, ScaleY))
        Widget:GetParent().Slot:SetPosition(UE.FVector2D(XPos, YPos))
    end
end

---贴纸
function HeroDisplayBoard2D:UpdateDisplayBoardSticker()
    local bOpen = self:GetDisplayBoardTabIsOpen(EHeroDisplayBoardTabID.Sticker.TabId)
    self.View.StickerPanel:SetVisibility(bOpen and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if not(bOpen) then
        return
    end

    for Slot= 1, HeroDefine.STICKER_SLOT_NUM, 1 do
        local StickerInfo = self.DisplayData.SlotToStickerInfo[Slot]
        self:UpdateDisplayLayerTexture(Slot, StickerInfo and StickerInfo.StickerId or 0, StickerInfo)
    end
end

-----------------------贴纸<<

-----------------------成就>>

---获取成就Widget
function HeroDisplayBoard2D:GetAchieveImgWidget(Slot)
    if Slot == 1 then
        return self.View.AchImg_1
    elseif Slot == 2 then
        return self.View.AchImg_2
    elseif Slot == 3 then
        return self.View.AchImg_3
    end
    return nil
end

---设置单个成就
function HeroDisplayBoard2D:UpdateDisplayLayerAchieve(Slot, AchieveId)
    local Widget = self:GetAchieveImgWidget(Slot)
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

---成就
function HeroDisplayBoard2D:UpdateDisplayBoardAchieve()
    local bOpen = self:GetDisplayBoardTabIsOpen(EHeroDisplayBoardTabID.Achieve.TabId)
    self.View.AchPanel:SetVisibility(bOpen and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if not(bOpen) then
        return
    end

    for Slot = 1, HeroDefine.STICKER_SLOT_NUM, 1 do
        self:UpdateDisplayLayerAchieve(Slot, self.DisplayData.SlotToAchieveId[Slot] or 0)
    end
end

-----------------------成就<<

--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-----------------------贴纸编辑相关>>

---@class StickerEditParam 贴纸编辑的数据
---@field AbsolutePos UE.FVector2D 屏幕位置
---@field Angle number
---@field Scale UE.FVector2D


function HeroDisplayBoard2D:OpenStickerEdit()
    
end

function HeroDisplayBoard2D:CloseStickerEdit()
    self:EndStickerEdit()
end

---@param StickerInfo LbStickerNode
function HeroDisplayBoard2D:SwitchStickerVisibility_Inner(Slot, StickerInfo, bVisibility)
    local Widget = self:GetStickerImgWidget(Slot)
    if Widget then
        if bVisibility then
            local StickerId = StickerInfo and StickerInfo.StickerId or 0
            Widget:GetParent():SetVisibility(StickerId > 0 and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed) 
        else
            Widget:GetParent():SetVisibility(UE.ESlateVisibility.Collapsed)   
        end
    end
end

---开始编辑并获取对应贴纸的初始编辑参数
---@param Param table{StickerId:number, OnEditResultSyn:func}
---@return StickerEditParam
function HeroDisplayBoard2D:StartStickerEdit(Param)
    self.OnEditResultSyn = Param.OnEditResultSyn

    local StickerId = Param.StickerId
    self.EditorStickerId = StickerId
    self.bRefreshEditBrush = true

    local EditParam = {
        Angle = 0,
        AbsolutePos = UE.FVector2D(0, 0),
        Scale = UE.FVector2D(1.0, 1.0),
        InitSize = UE.FVector2D(InitSize.X, InitSize.Y) ,
    }

    local StickerInfo = nil
    self.EditSlot = nil
    for Slot = 1, HeroDefine.STICKER_SLOT_NUM ,1 do
        local Info = self.DisplayData.SlotToStickerInfo[Slot]
        if Info and Info.StickerId == StickerId then
            -- 等到合适的时机再屏蔽贴纸频闭此Slot的贴纸
            -- self:SwitchStickerVisibility_Inner(Slot, Info, false)
            StickerInfo = Info
            self.EditSlot = Slot
        else
            self:SwitchStickerVisibility_Inner(Slot, Info, true)
        end
    end
   
    --TODO:编辑的贴纸设置图片,并设置为可见
    -- Widget:GetParent():SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)   
    -- self.View.ScaleBox_Edit:SetVisibility(UE.ESlateVisibility.Collapsed)  
    self.View.ScaleBox_Edit:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)  
    self:SetStickerEditBrush(StickerId)
    self:SetOpacity_ScaleBox_Edit(0)

    if StickerInfo then
        -- CError(string.format("HeroDisplayBoard2D:StartStickerEdit StickerInfo = %s",table.tostring(StickerInfo)))

        local Float2IntScale = HeroModel.DISPLAYBOARD_FLOAT2INTSCALE

        EditParam.Angle = StickerInfo.Angle / Float2IntScale

        EditParam.Scale.X = StickerInfo.ScaleX / Float2IntScale
        EditParam.Scale.Y = StickerInfo.ScaleY / Float2IntScale

        local XPos = StickerInfo.XPos / Float2IntScale
        local YPos = StickerInfo.YPos / Float2IntScale
        local StickerPanelSize = UE.USlateBlueprintLibrary.GetLocalSize(self.View.StickerPanel:GetCachedGeometry())
        XPos = XPos + (StickerPanelSize.X * 0.5)
        YPos = YPos + (StickerPanelSize.Y * 0.5)
        local AbsPos = UE.USlateBlueprintLibrary.LocalToAbsolute(self.View.StickerPanel:GetCachedGeometry(), UE.FVector2D(XPos,YPos))
        EditParam.AbsolutePos.X = AbsPos.X
        EditParam.AbsolutePos.Y = AbsPos.Y
    else
        local LocalPos = UE.FVector2D(InitLocalPos.X, InitLocalPos.Y)
        local bUse_1 = true
        if bUse_1 then
            LocalPos = UE.FVector2D(InitLocalPos.X, InitLocalPos.Y)
            local StickerPanelSize = UE.USlateBlueprintLibrary.GetLocalSize(self.View.StickerPanel:GetCachedGeometry())
            LocalPos.X = LocalPos.X + (StickerPanelSize.X * 0.5)
            LocalPos.Y = LocalPos.Y + (StickerPanelSize.Y * 0.5)
        else
            -- --不要使用此逻辑
            -- LocalPos = UE.USlateBlueprintLibrary.GetLocalTopLeft(self.View.ScaleBox_Edit:GetCachedGeometry())
            -- local ScaleBox_EditSize = UE.USlateBlueprintLibrary.GetLocalSize(self.View.ScaleBox_Edit:GetCachedGeometry())
            -- LocalPos.X = LocalPos.X + (ScaleBox_EditSize.X * 0.5)
            -- LocalPos.Y = LocalPos.Y + (ScaleBox_EditSize.Y * 0.5)
        end

        local AbsPos = UE.USlateBlueprintLibrary.LocalToAbsolute(self.View.StickerPanel:GetCachedGeometry(), LocalPos)
        EditParam.AbsolutePos.X = AbsPos.X
        EditParam.AbsolutePos.Y = AbsPos.Y
    end

    -- CError(string.format("HeroDisplayBoard2D:StartStickerEdit EditParam = %s",table.tostring(EditParam)))

    return EditParam
end

---结束贴纸编辑
function HeroDisplayBoard2D:EndStickerEdit()
    if self.EditSlot == nil or self.EditSlot == 0 then
        return
    end
    local Wiget = self:GetStickerImgWidget(self.EditSlot)
    if Wiget == nil then
        CError("HeroDisplayBoard2D:EndStickerEdit() Wiget == nil !!!")
        return
    end
    Wiget:SetRenderTransformAngle(self.EditAngle)
    Wiget:SetRenderScale(UE.FVector2D(self.EditScale, self.EditScale))
    Wiget:GetParent().Slot:SetPosition(self.EditLocalPos)

    for Slot = 1, HeroDefine.STICKER_SLOT_NUM ,1 do
        self:SwitchStickerVisibility_Inner(Slot, self.DisplayData.SlotToStickerInfo[Slot], true)
    end
    
    self.View.ScaleBox_Edit:SetVisibility(UE.ESlateVisibility.Collapsed) 

    self:ResetEditParam()
end

function HeroDisplayBoard2D:ResetEditParam()
    self.OnEditResultSyn = nil
    
    self.EditorStickerId = nil
    self.bRefreshEditBrush = nil
    self.EditSlot = nil
    self.EditAngle = nil
    self.EditScale = nil
    self.EditLocalPos = nil
end

function HeroDisplayBoard2D:SetStickerEditBrush(StickerId)
    local Widget = self.View.StickerImg_Edit
    local StickerCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplaySticker, Cfg_HeroDisplaySticker_P.Id, StickerId)
    local ResPath = StickerCfg and StickerCfg[Cfg_HeroDisplaySticker_P.ResPath] or ""
    CommonUtil.SetBrushFromSoftObjectPath(Widget, ResPath) 
end

function HeroDisplayBoard2D:SetOpacity_ScaleBox_Edit(Opacity, bNextFrame, HideSlot)
    bNextFrame = bNextFrame or false
    if bNextFrame then
        self:InsertTimer(Timer.NEXT_FRAME, function()
            if CommonUtil.IsValid(self.View.ScaleBox_Edit) then
                self.View.ScaleBox_Edit:SetRenderOpacity(Opacity)
                if HideSlot then
                    -- 已经等到 合适的时机再屏蔽贴纸频闭此Slot的贴纸
                    self:HideSlotSticker(HideSlot)
                end
            end
        end, false)
    else
        self.View.ScaleBox_Edit:SetRenderOpacity(Opacity)
        if HideSlot then
            -- 已经等到 合适的时机再屏蔽贴纸频闭此Slot的贴纸
            self:HideSlotSticker(HideSlot)
        end
    end
end

function HeroDisplayBoard2D:HideSlotSticker(InHideSlot)
    if InHideSlot and self.DisplayData and self.DisplayData.SlotToStickerInfo then
        local Info = self.DisplayData.SlotToStickerInfo[InHideSlot]
        if Info then
            self:SwitchStickerVisibility_Inner(InHideSlot, Info, false)
        end
    end
end

---贴纸编辑:旋转,缩放,位置
function HeroDisplayBoard2D:UpdateStickerEdit(Angle, ScaleLength, AbsolutePos, ScaleDir)
    -- CError(string.format("HeroDisplayBoard2D:UpdateStickerEdit Angle = %s",table.tostring({Angle = Angle, ScaleLength = ScaleLength, AbsolutePos = AbsolutePos, ScaleDir = ScaleDir})))

    if self.bRefreshEditBrush then
        self.bRefreshEditBrush = false
        -- 颜色:E98844
        self.View.ScaleBox_Edit:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self:SetStickerEditBrush(self.EditorStickerId)
        self:SetOpacity_ScaleBox_Edit(1, true, self.EditSlot)
    end

    --位置
    local StickerPanelSize = UE.USlateBlueprintLibrary.GetLocalSize(self.View.StickerPanel:GetCachedGeometry())
    local LocalPos = UE.USlateBlueprintLibrary.AbsoluteToLocal(self.View.StickerPanel:GetCachedGeometry(), AbsolutePos)
    LocalPos.X = LocalPos.X - (StickerPanelSize.X * 0.5)
    LocalPos.Y = LocalPos.Y - (StickerPanelSize.Y * 0.5)
    self.EditLocalPos = LocalPos

    --旋转
    self.EditAngle = Angle

    --缩放
    self.EditScale = UE.FVector2D(ScaleLength * ScaleDir.X, ScaleLength * ScaleDir.Y)

    --设置编辑的贴纸的RenderTrans
    self:SetStickerEditRenderTrans(self.EditAngle, self.EditScale, self.EditLocalPos)

    if self.OnEditResultSyn then
        local Param = {
            StickerId = self.EditorStickerId,
            Slot = self.EditSlot,
            Angle = Angle, 
            Scale = self.EditScale, 
            LocalPos = LocalPos
        }
        self.OnEditResultSyn(Param)
    end
end

---设置编辑的贴纸的RenderTrans
function HeroDisplayBoard2D:SetStickerEditRenderTrans(Angle, Scale, Pos)
    self.View.ScaleBox_Edit.Slot:SetPosition(Pos)
    self.View.StickerImg_Edit:SetRenderTransformAngle(Angle)
    self.View.StickerImg_Edit:SetRenderScale(Scale)
end

---预览编辑的数据
function HeroDisplayBoard2D:PreviewStickerEditByData(StickerId, Angle, Scale, Pos)
    self.View.ScaleBox_Edit:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) 
    self:SetStickerEditBrush(StickerId)
    self:SetOpacity_ScaleBox_Edit(1)
    self:SetStickerEditRenderTrans(Angle, Scale, Pos)
end

---预览编辑的数据
function HeroDisplayBoard2D:PreviewStickerEditEnd()
    self.View.ScaleBox_Edit:SetVisibility(UE.ESlateVisibility.Collapsed) 
end

function HeroDisplayBoard2D:SetStickerSelected(bSelected, InSlot)
    if bSelected then
        self.View.ScaleBox_SelectMark:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)

        if InSlot <= HeroDefine.STICKER_SLOT_NUM  then
            local Widget = self:GetStickerImgWidget(InSlot)
    
            if Widget == nil then
                return
            end
    
            local Scale = Widget.RenderTransform.Scale
            local Size = UE.FVector2D(0,0)
            Size.X = math.abs(Scale.X * InitSize.X)
            Size.Y = math.abs(Scale.Y * InitSize.Y)
            self.View.Image_LineBox.Slot:SetSize(Size)
    
            -- local Angle = Widget:GetRenderTransformAngle()
            local Angle = Widget.RenderTransform.Angle
            self.View.Image_LineBox:SetRenderTransformAngle(Angle)
    
            local Pos = Widget:GetParent().Slot:GetPosition()
            self.View.ScaleBox_SelectMark.Slot:SetPosition(Pos)
        end
    else
        self.View.ScaleBox_SelectMark:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

-----------------------贴纸编辑相关<<


return HeroDisplayBoard2D