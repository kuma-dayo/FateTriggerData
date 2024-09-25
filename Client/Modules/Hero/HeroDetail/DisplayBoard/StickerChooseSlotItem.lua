class_name = "StickerChooseSlotItem"

---@class StickerChooseSlotItem
local StickerChooseSlotItem = BaseClass(UIHandlerViewBase, class_name)

StickerChooseSlotItem.InstigateType = {
    Default = 0,
    SlotMdt = 1
}


function StickerChooseSlotItem:OnInit()
    self.MsgList = {

	}

    self.BindNodes = {
    --     { UDelegate = self.View.GUIButton_ClickArea.OnClicked,	    Func = Bind(self,self.OnClickedSlotClickArea)},
    --     { UDelegate = self.View.GUIButton_ClickArea.OnHovered,	    Func = Bind(self,self.OnHoveredSlotClickArea)},

        { UDelegate = self.View.WBP_CommonSubscript_Sys.Btn_Delete.OnClicked,	    Func = Bind(self,self.OnClickedSubscript_Delete)},
        { UDelegate = self.View.WBP_CommonSubscript_Sys.Btn_Switch.OnClicked,	    Func = Bind(self,self.OnClickedSubscript_Switch)},
	}
end

function StickerChooseSlotItem:OnShow(Param)
    ---@type HeroModel
    self.ModelHero = MvcEntry:GetModel(HeroModel)

    self.Slot = Param.Slot
    


    self:UpdateUI(Param)
end

function StickerChooseSlotItem:OnManualShow(Param)
end

function StickerChooseSlotItem:OnManualHide(Param)
end

function StickerChooseSlotItem:OnHide(Param)
end

--[[
	@param Data 自定义参数，首次创建时可能存在值
	@param IsNotVirtualTrigger 是否  不是因为虚拟场景切换触发的
		true  表示为初始化创建
		false 表示为虚拟场景切换触发
]]
function StickerChooseSlotItem:OnShowAvator(Data,IsNotVirtualTrigger) 
end

function StickerChooseSlotItem:OnHideAvator(Data,IsNotVirtualTrigger) 
end

function StickerChooseSlotItem:OnDestroy(Data,IsNotVirtualTrigger)
    
end

function StickerChooseSlotItem:UpdateUI(Param)
    self.InstigateType = Param.InstigateType or StickerChooseSlotItem.InstigateType.Default
    self.ChooseId = Param.ChooseId
    self.bEditing = Param.bEditing
    self.bPreview = Param.bPreview
    self.HeroId = Param.HeroId
    self.StickerId = Param.StickerId
    self.Slot = self.Slot or Param.Slot

    self.OnClickCallBack = Param.OnClickCallBack
    -- self.OnClickedSlotArea = Param.OnClickedSlotArea
    -- self.OnHoveredSlotArea = Param.OnHoveredSlotArea
    -- self.OnDragCallBack = Param.OnDragCallBack
    -- self.OnClickedUnequip = Param.OnClickedUnequip
    self.OnClickedReplace = Param.OnClickedReplace

    if self.InstigateType == StickerChooseSlotItem.InstigateType.SlotMdt then
        self:UpdateUI_InMdtSlot()
    elseif self.InstigateType == StickerChooseSlotItem.InstigateType.Default then
      self:UpdateUI_InLogicSlot()
    end
end

---------------------------------------- MdtSlot >>

function StickerChooseSlotItem:UpdateUI_InMdtSlot()
    self.View.WBP_CommonSubscript_Sys:SetVisibility(UE.ESlateVisibility.Collapsed) --角标

    if self.StickerId > 0 then
        self.View.WidgetSwitcher_State:SetActiveWidget(self.View.WBP_CommonItemIcon) --贴纸
        
        self:UpdateWidgetIns_InMdtSlot()
    else
        self.View.WidgetSwitcher_State:SetActiveWidget(self.View.GUIImage_Empty)--白板
    end
end


function StickerChooseSlotItem:UpdateWidgetIns_InMdtSlot()
    local RightCornerTagId = CornerTagCfg.Replace.TagId
    RightCornerTagId = 0
    -- if self.bEditing then
    --     if self.bPreview then
    --         RightCornerTagId = CornerTagCfg.Replace.TagId
    --     else
    --         if self.ChooseId == self.StickerId  then
    --             RightCornerTagId = CornerTagCfg.Delete.TagId
    --         else
    --             RightCornerTagId = CornerTagCfg.Replace.TagId
    --         end
    --     end
    -- end

    local StickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplaySticker, self.StickerId)
    local ItemId = StickerCfg[Cfg_HeroDisplaySticker_P.ItemId]

    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemId,
        ClickCallBackFunc = Bind(self, self.ClickCallBackFunc, self.StickerId),
        -- DragCallBackFunc = Bind(self, self.OnDragCallBackFunc),
        -- ClickMethod = UE.EButtonClickMethod.DownAndUp,
        -- HoverCallBackFunc = Bind(self, self.OnHoveredSlotClickArea),
        -- HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,

        RightCornerTagId = RightCornerTagId,
        RightCornerTagHeroId = 0,
        RightCornerTagHeroSkinId = 0,
        IsLock = false,
        IsGot = false,
        IsOutOfDate = false,
    }

    if self.WidgetListInstance == nil then
        self.WidgetListInstance = UIHandler.New(self, self.View.WBP_CommonItemIcon, CommonItemIcon, IconParam).ViewInstance
    else
        self.WidgetListInstance:UpdateUI(IconParam)
    end

    -- self.View.WBP_CommonSubscript_Sys.WidgetSwitcherState:SetActiveWidget(self.View.WBP_CommonSubscript_Sys.Switch)
end

-- local Params = {
--     Icon = self.View,
--     ItemId = self.IconParams.ItemId,
-- }
function StickerChooseSlotItem:ClickCallBackFunc(StickerId, Params)
    if self.OnClickCallBack then
        local Param = {
            Slot = self.Slot,
            StickerId = self.StickerId,
        }
        self.OnClickCallBack(Param)
    end
end

---------------------------------------- MdtSlot <<

---------------------------------------- LogicSlot >>
function StickerChooseSlotItem:UpdateUI_InLogicSlot()
    self.View.WBP_CommonSubscript_Sys:SetVisibility(UE.ESlateVisibility.Collapsed) --角标
    -- self.StickerId = self.ModelHero:GetSelectedDisplayBoardStickerId(self.HeroId, self.Slot)
    if self.StickerId > 0 then
        self.View.WidgetSwitcher_State:SetActiveWidget(self.View.WBP_CommonItemIcon) --贴纸
        
        self:UpdateWidgetIns_InLogicSlot()
    else
        self.View.WidgetSwitcher_State:SetActiveWidget(self.View.GUIImage_Empty)--白板
    end
end

function StickerChooseSlotItem:UpdateWidgetIns_InLogicSlot()
    local RightCornerTagId = 0
    -- if self.bEditing then
    --     if self.bPreview then
    --         RightCornerTagId = CornerTagCfg.Replace.TagId
    --     else
    --         if self.ChooseId == self.StickerId  then
    --             RightCornerTagId = CornerTagCfg.Delete.TagId
    --         else
    --             RightCornerTagId = CornerTagCfg.Replace.TagId
    --         end
    --     end
    -- end


    local StickerCfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplaySticker, self.StickerId)
    local ItemId = StickerCfg[Cfg_HeroDisplaySticker_P.ItemId]

    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemId,
        ClickCallBackFunc = Bind(self, self.ClickCallBackFunc, self.StickerId),
        -- DragCallBackFunc = Bind(self, self.OnDragCallBackFunc),
        -- ClickMethod = UE.EButtonClickMethod.DownAndUp,
        -- HoverCallBackFunc = Bind(self, self.OnHoveredSlotClickArea),
        -- HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,

        -- RightCornerTagId = RightCornerTagId,
        RightCornerTagId = 0,
        RightCornerTagHeroId = 0,
        RightCornerTagHeroSkinId = 0,
        IsLock = false,
        IsGot = false,
        IsOutOfDate = false,
    }

    if not self.WidgetListInstance then
        self.WidgetListInstance = UIHandler.New(self, self.View.WBP_CommonItemIcon, CommonItemIcon, IconParam).ViewInstance
    else
        self.WidgetListInstance:UpdateUI(IconParam)

        self.WidgetListInstance:SetIsSelect(self.ChooseId == self.StickerId)
    end
end

---------------------------------------- LogicSlot <<


function StickerChooseSlotItem:OnClickedSubscript_Delete()
    CError("StickerChooseSlotItem:OnClickedSubscript_Delete(): Clicked 到了 Delete")
    if self.OnClickedUnequip then
        local Param = {
            Slot = self.Slot,
            StickerId = self.StickerId,
        }
        self.OnClickedUnequip(Param)
    end
end

function StickerChooseSlotItem:SetIsSelect(bSelect)
    if self.WidgetListInstance then
        self.WidgetListInstance:SetIsSelect(bSelect)
    end
end

function StickerChooseSlotItem:OnClickedSubscript_Switch()
    CError("StickerChooseSlotItem:OnClickedSubscript_Switch(): Clicked 到了 Switch")

    if self.OnClickedReplace then
        local Param = {
            Slot = self.Slot,
            StickerId = self.StickerId,
        }
        self.OnClickedReplace(Param)
    end
end

return StickerChooseSlotItem

