--[[
    角色展示板编辑装备选择替换Slot的界面
]]


local class_name = "StickerChooseSlotMdt";
StickerChooseSlotMdt = StickerChooseSlotMdt or BaseClass(GameMediator, class_name);



function StickerChooseSlotMdt:__init()
end

function StickerChooseSlotMdt:OnShow(data)
end

function StickerChooseSlotMdt:OnHide()
end



local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()

    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true

    ---@type HeroModel
    self.ModelHero = MvcEntry:GetModel(HeroModel)

    self.BindNodes = {
		
    }

    self.MsgList = {
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.Escape), Func = self.OnEscClicked },
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.SpaceBar), Func = self.OnSpaceBarClick },
	}

    UIHandler.New(self, self.WBP_Change, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_WBP_Change),
        CommonTipsID = CommonConst.CT_SPACE,
        ActionMappingKey = ActionMappings.SpaceBar,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "1592"),--替换
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })

    UIHandler.New(self, self.CommonBtnTipsESC, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_WBP_Cancle),
        CommonTipsID = CommonConst.CT_ESC,
        ActionMappingKey = ActionMappings.Escape,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HeroSkillPreviewMdt_return_Btn"), -- 返回
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second,
    })
end

--[[
    Param = {
        HeroId
        SkinId
        SkinDataList
    }
]]
function M:OnShow(Param)
    if Param == nil then
        return
    end

    
    self:UpdateUI(Param)
end

function M:OnRepeatShow(Param)
    self:UpdateUI(Param)
end

function M:OnHide()
    self:ResetCustomData()
end

function M:ResetCustomData()
    self.Slot2WidgetIns = nil
end

function M:UpdateUI(Param)
   
    self.HeroId = Param.HeroId
    self.ChooseStickerId = Param.ChooseStickerId
    self.ChooseSlotId = Param.ChooseSlotId
    self.OnSelectSlotOption = Param.OnSelectSlotOption
    self.EditResultSynParam = Param.EditResultSynParam

    self.LastChooseSlot = 0
   
    -- self:InitSlotList()
    self:UpdateSlotListShow()
    self:UpdateHeroDisplayBoard2D()
end

-------------------------------------------------------------------------------Slot >>

function M:GetSlotWidget(Slot)
    if Slot == 1 then
        return self.WBP_Widget1
    elseif Slot == 2 then
        return self.WBP_Widget2
    elseif Slot == 3 then
        return self.WBP_Widget3
    end
end

---更新左侧Slot
---@param bEditing boolean
function M:UpdateSlotListShow(bEditing)
    bEditing = bEditing or false

    self.Slot2WidgetIns = self.Slot2WidgetIns or {}

    for Slot = 1, HeroDefine.STICKER_SLOT_NUM , 1 do
        ---@type LbStickerNode
        local StickerInfo = self.ModelHero:GetSelectedDisplayBoardSticker(self.HeroId, Slot)

        -- local bPreview = false
        -- if bEditing and Slot == self.ChooseSlotId and StickerInfo == nil then
        --     bPreview = true
        -- end
        local StickerId = StickerInfo and StickerInfo.StickerId or 0
        -- if bEditing then
        --     StickerId = self.ChooseStickerId
        -- end

        local StickerChooseSlotItem = require("Client.Modules.Hero.HeroDetail.DisplayBoard.StickerChooseSlotItem")
        local Param = {
            Slot = Slot,
            ChooseId = self.ChooseStickerId,
            bPreview = false,
            bEditing = bEditing,
            InstigateType = StickerChooseSlotItem.InstigateType.SlotMdt,
            HeroId = self.HeroId,
            StickerId = StickerId,
            OnClickCallBack = Bind(self, self.OnClickSlotItem),
            -- OnClickedSlotArea = Bind(self,self.OnClickedSlotArea),
            -- OnHoveredSlotArea = Bind(self,self.OnHoveredSlotArea),
            -- OnDragCallBack = Bind(self,self.OnDragSlotFunc),
            -- OnClickedUnequip = Bind(self,self.OnClickedUnequip),
            OnClickedReplace = Bind(self, self.OnClickedReplace),
        }

        if self.Slot2WidgetIns[Slot] == nil then
            local SlotWidget = self:GetSlotWidget(Slot)
            self.Slot2WidgetIns[Slot] = UIHandler.New(self, SlotWidget, StickerChooseSlotItem, Param).ViewInstance
            -- self.Slot2WidgetIns[Slot]:SetIsSelect(false)
        else
            --TODO:
            -- self.Slot2WidgetIns[Slot]:SetIsSelect(false)
            self.Slot2WidgetIns[Slot]:UpdateUI(Param)
        end

        self.Slot2WidgetIns[Slot]:SetIsSelect(false)

        self.CurWidgetIns = nil
    end
end

function M:OnClickSlotItem(Param)
   self:SwitchChooseSlot_Inner(Param)
end

function M:OnClickedReplace(Param)
    self:SwitchChooseSlot_Inner(Param)
end

function M:SwitchChooseSlot_Inner(Param)
    local Slot = Param.Slot
    local StickerId = Param.StickerId

    if self.CurWidgetIns then
        self.CurWidgetIns:SetIsSelect(false)
    end
    self.CurWidgetIns = self.Slot2WidgetIns[Slot]
    if self.CurWidgetIns then
        self.CurWidgetIns:SetIsSelect(true)
    end

    self.LastChooseSlot = Slot

    self:SetSelectedHeroDisplayBoard2D(true, Slot)
end



-------------------------------------------------------------------------------Slot <<

------------------------------------------Board_2D >>
-- 更新角色面板2D
function M:UpdateHeroDisplayBoard2D()
    local EquippedFloorId = self.ModelHero:GetSelectedDisplayBoardFloorId(self.HeroId)
    local EquippedRoleId = self.ModelHero:GetSelectedDisplayBoardRoleId(self.HeroId)
    local EquippedEffectId = self.ModelHero:GetSelectedDisplayBoardEffectId(self.HeroId)

    local EquippedSlotToAchieveId = {}
    for Slot = 1, HeroDefine.STICKER_SLOT_NUM, 1 do
        local AchieveId = self.ModelHero:GetSelectedDisplayBoardAchieveId(self.HeroId, Slot)
        EquippedSlotToAchieveId[Slot] = AchieveId
    end

    local SlotToStickerInfo = {}
    for Slot = 1, HeroDefine.STICKER_SLOT_NUM , 1 do
        ---@type LbStickerNode
        -- local StickerInfo = self.EditSlot2StickerMap[Slot]
        local StickerInfo = self.ModelHero:GetSelectedDisplayBoardSticker(self.HeroId, Slot)
        SlotToStickerInfo[Slot] = StickerInfo
    end

    ---@type DisplayBoardNode
    local DisplayData = {
        HeroId = self.HeroId,
        FloorId = EquippedFloorId,
        RoleId = EquippedRoleId,
        EffectId = EquippedEffectId,
        SlotToAchieveId = EquippedSlotToAchieveId,
        SlotToStickerInfo = SlotToStickerInfo,
    }

    local Param = {
        HeroId = self.HeroId,
        DisplayData = DisplayData
    }

    if self.DisplayBoard2DHandler == nil or not(self.DisplayBoard2DHandler:IsValid()) then
        self.DisplayBoard2DHandler = UIHandler.New(self, self.WBP_HeroDisplayBoard2D, require("Client.Modules.Hero.HeroDetail.DisplayBoard.HeroDisplayBoard2D"), Param)

        --预览编辑的贴纸
        self:PreviewStickerEditByData()
    else
        -- self.DisplayBoard2DHandler:ManualOpen(Param)
        self.DisplayBoard2DHandler.ViewInstance:UpdateUI(Param)

        --预览编辑的贴纸
        self:PreviewStickerEditByData()
    end
end

---预览编辑的贴纸
function M:PreviewStickerEditByData()
    if self.EditResultSynParam == nil then
        return
    end

    if self.DisplayBoard2DHandler and self.DisplayBoard2DHandler:IsValid() then
        local StickerId = self.EditResultSynParam.StickerId
        local Angle = self.EditResultSynParam.Angle
        local Scale = self.EditResultSynParam.Scale
        local LocalPos = self.EditResultSynParam.LocalPos
        self.DisplayBoard2DHandler.ViewInstance:PreviewStickerEditByData(StickerId, Angle, Scale, LocalPos)
    end
end

function M:SetSelectedHeroDisplayBoard2D(bSelected, Slot)
    if self.DisplayBoard2DHandler and self.DisplayBoard2DHandler:IsValid() then
        self.DisplayBoard2DHandler.ViewInstance:SetStickerSelected(bSelected, Slot)
    end
end

------------------------------------------Board_2D <<


------------------------------------------btn >>
---确定展示
function M:OnClicked_WBP_Change()
    if self.LastChooseSlot <= 0 then
        -- Alter
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "1591")) --选择要替换的栏位
        return
    end

    if self.OnSelectSlotOption then 
        local Param = {
            bEquip = true,
            Slot = self.LastChooseSlot,
        }
        self.OnSelectSlotOption(Param)
    end

    MvcEntry:CloseView(ViewConst.HeroDisplayBoardStickerChooseSlot)
end

---放弃
function M:OnClicked_WBP_Cancle()
    if self.OnSelectSlotOption then 
        local Param = {
            bEquip = false,
            Slot = self.LastChooseSlot
        }

        self.OnSelectSlotOption(Param)
    end

    MvcEntry:CloseView(ViewConst.HeroDisplayBoardStickerChooseSlot)
end
------------------------------------------btn <<

return M
