class_name = "AchieveChooseSlotItem"
local AchieveChooseSlotItem = BaseClass(UIHandlerViewBase, class_name)


function AchieveChooseSlotItem:OnInit()
    self.MsgList = {

	}
    self.BindNodes = {
        { UDelegate = self.View.GUIButton_ClickArea.OnClicked,	    Func = Bind(self,self.OnClickedSlotClickArea)},
        { UDelegate = self.View.GUIButton_ClickArea.OnHovered,	    Func = Bind(self,self.OnHoveredSlotClickArea)},

        { UDelegate = self.View.WBP_CommonSubscript_Sys.Btn_Delete.OnClicked,	    Func = Bind(self,self.OnClickedSubscript_Delete)},
        { UDelegate = self.View.WBP_CommonSubscript_Sys.Btn_Switch.OnClicked,	    Func = Bind(self,self.OnClickedSubscript_Switch)},
	}
end

function AchieveChooseSlotItem:OnShow(Param)
    ---@type HeroModel
    self.ModelHero = MvcEntry:GetModel(HeroModel)

    self.AchieveId = 0
    self.Slot = Param.Slot
    
    -- {OnClickedSlotFunc = nil,OnHoveredSlotArea,OnDragCallBack = nil}
    self.OnClickedSlotArea = Param.OnClickedSlotArea
    self.OnHoveredSlotArea = Param.OnHoveredSlotArea
    self.OnDragCallBack = Param.OnDragCallBack
    self.OnClickedUnequip = Param.OnClickedUnequip
    self.OnClickedReplace = Param.OnClickedReplace
end

function AchieveChooseSlotItem:OnManualShow(Param)
end

function AchieveChooseSlotItem:OnManualHide(Param)
end

function AchieveChooseSlotItem:OnHide(Param)
end

--[[
	@param Data 自定义参数，首次创建时可能存在值
	@param IsNotVirtualTrigger 是否  不是因为虚拟场景切换触发的
		true  表示为初始化创建
		false 表示为虚拟场景切换触发
]]
function AchieveChooseSlotItem:OnShowAvator(Data,IsNotVirtualTrigger) 
end

function AchieveChooseSlotItem:OnHideAvator(Data,IsNotVirtualTrigger) 
end

function AchieveChooseSlotItem:OnDestroy(Data,IsNotVirtualTrigger)
    
end

function AchieveChooseSlotItem:UpdateUI(Param)
    -- CError(string.format("AchieveChooseSlotItem:UpdateUI Slot更新 Param = %s",table.tostring(Param)))
    self.ChooseId = Param.ChooseId
    self.bEditing = Param.bEditing
    self.HeroId = Param.HeroId
    self.Slot = self.Slot or Param.Slot
    
    self.AchieveId = self.ModelHero:GetSelectedDisplayBoardAchieveId(self.HeroId, self.Slot)
    if self.AchieveId > 0 then
        self.View.WidgetSwitcher_State:SetActiveWidget(self.View.WBP_CommonItemIcon) --成就
        
        self:UpdateWidgetIns()
    else
        
        self.View.WBP_CommonSubscript_Sys:SetVisibility(UE.ESlateVisibility.Collapsed)

        if self.bEditing then
            local Num = self.ModelHero:GetSelectedDisplayBoardAchieveNum(self.HeroId)
            if self.ChooseId > 0 then
                if Num > 0 then
                    self.View.WidgetSwitcher_State:SetActiveWidget(self.View.Panel_Change)--交换
                else
                    self.View.WidgetSwitcher_State:SetActiveWidget(self.View.Panel_Add)--加号
                end
            else
                self.View.WidgetSwitcher_State:SetActiveWidget(self.View.GUIImage_Empty)--白板
            end
        else
            self.View.WidgetSwitcher_State:SetActiveWidget(self.View.GUIImage_Empty)--白板
        end
    end
end

function AchieveChooseSlotItem:UpdateWidgetIns()

    local RightCornerTagId = 0
    if self.bEditing then
        if self.ChooseId == self.AchieveId  then
            RightCornerTagId = CornerTagCfg.Delete.TagId
        else
            RightCornerTagId = CornerTagCfg.Replace.TagId
        end
    end

    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.ACHIEVEMENT,
        ItemId = self.AchieveId,
        DragCallBackFunc = Bind(self, self.OnDragCallBackFunc),
        ClickMethod = UE.EButtonClickMethod.DownAndUp,
        HoverCallBackFunc = Bind(self, self.OnHoveredSlotClickArea),
        -- HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
        ShowItemName = true,

        -- RightCornerTagId = RightCornerTagId,
        RightCornerTagId = 0,
        RightCornerTagHeroId = 0,
        RightCornerTagHeroSkinId = 0,
        IsLock = false,
        IsGot = false,
        IsOutOfDate = false,
    }

    local ComItemIcon = self.View.WBP_CommonItemIcon
    if not self.WidgetListInstance then
        self.WidgetListInstance = UIHandler.New(self, ComItemIcon, CommonItemIcon, IconParam).ViewInstance
    else
        self.WidgetListInstance:UpdateUI(IconParam)
    end

    if RightCornerTagId == CornerTagCfg.Delete.TagId then
        --卸载/删除
        self.View.WBP_CommonSubscript_Sys:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.WBP_CommonSubscript_Sys.WidgetSwitcherState:SetActiveWidget(self.View.WBP_CommonSubscript_Sys.Delete)
    elseif RightCornerTagId == CornerTagCfg.Replace.TagId then
        --替换
        self.View.WBP_CommonSubscript_Sys:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.View.WBP_CommonSubscript_Sys.WidgetSwitcherState:SetActiveWidget(self.View.WBP_CommonSubscript_Sys.Switch)
    else
        self.View.WBP_CommonSubscript_Sys:SetVisibility(UE.ESlateVisibility.Collapsed)
    end
end

---拖拽回调
---@param Params {Handle:UUserWidget,Icon,ItemId,DragType}
function AchieveChooseSlotItem:OnDragCallBackFunc(Param)
    if self.OnDragCallBack then
        ---@type AchievementData
        local AchieveData = self.AchieveData
        local Param = {
            Slot = self.Slot,
            AchieveId = self.AchieveId,
            DragType = Param.DragType
        }
        self.OnDragCallBack(Param)
    end
end

function AchieveChooseSlotItem:OnClickedSlotClickArea()
    -- CError("AchieveChooseSlotItem:OnClickedSlotClickArea() :Clicked 到了SlotArea,self.AchieveId = "..tostring(self.AchieveId))
    if self.AchieveId == nil or self.AchieveId > 0 then
        return
    end
    if self.OnClickedSlotArea then
        local Param = {Slot = self.Slot, AchieveId = self.AchieveId}
        self.OnClickedSlotArea(Param)
    end
end

function AchieveChooseSlotItem:OnHoveredSlotClickArea()
    -- CError("AchieveChooseSlotItem:OnHoveredSlotClickArea() :Hovered 到了SlotArea")
    if self.bEditing then
        if self.OnHoveredSlotArea then
            local Param = {Slot = self.Slot, AchieveId = self.AchieveId}
            self.OnHoveredSlotArea(Param)
        end
    end
end

function AchieveChooseSlotItem:OnClickedSubscript_Delete()
    -- CError("AchieveChooseSlotItem:OnClickedSubscript_Delete(): Clicked 到了 Delete")
    if self.OnClickedUnequip then
        local Param = {
            Slot = self.Slot,
            AchieveId = self.AchieveId,
        }
        self.OnClickedUnequip(Param)
    end
end

function AchieveChooseSlotItem:OnClickedSubscript_Switch()
    -- CError("AchieveChooseSlotItem:OnClickedSubscript_Switch(): Clicked 到了 Switch")

    if self.OnClickedReplace then
        local Param = {
            Slot = self.Slot,
            AchieveId = self.AchieveId,
        }
        self.OnClickedReplace(Param)
    end
end

return AchieveChooseSlotItem

