local class_name = "AchieveChooseListItem"
local AchieveChooseListItem = BaseClass(UIHandlerViewBase, class_name)

function AchieveChooseListItem:OnInit()
    self.MsgList = {

	}
    self.BindNodes = {
        -- { UDelegate = self.View.GUIButtonItem.OnClicked,		    Func = Bind(self,self.OnClicked_BtnClick) },
        -- { UDelegate = self.View.GUIButtonItem.OnHovered,            Func = Bind(self,self.OnBtnHovered) },
        -- { UDelegate = self.View.GUIButtonItem.OnUnhovered,          Func = Bind(self,self.OnBtnUnhovered) },
	}
end

function AchieveChooseListItem:OnShow(Param)
    self.OnDragCallBack = Param.OnDragCallBack
end

function AchieveChooseListItem:OnManualShow(Param)

end

function AchieveChooseListItem:OnManualHide(Param)

end

function AchieveChooseListItem:OnHide(Param)

end

function AchieveChooseListItem:OnDestroy(Data,IsNotVirtualTrigger)
end


function AchieveChooseListItem:UpdateUI(Param)
    local CornerTagInfo = Param.CornerTagInfo
    local AchieveId = Param.AchieveId
    ---@type AchievementData
    self.AchieveData = Param.AchieveData

    -- local IconParam = {
    --     IconType = CommonItemIcon.ICON_TYPE.ACHIEVEMENT,
    --     ItemId = AchieveId,
    --     DragCallBackFunc = Bind(self, self.DragCallBackFunc),
    --     ClickMethod = UE.EButtonClickMethod.DownAndUp,
    --     HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
    --     ShowItemName = true,
    --     IsCheckAchievementCornerTag = true,

    --     RightCornerTagId = CornerTagInfo.RightCornerTagId,
    --     RightCornerTagHeroId = CornerTagInfo.RightCornerTagHeroId,
    --     RightCornerTagHeroSkinId = CornerTagInfo.RightCornerTagHeroSkinId,
    --     IsLock = CornerTagInfo.IsLock,
    --     IsGot = CornerTagInfo.IsGot,
    --     IsOutOfDate = CornerTagInfo.IsOutOfDate,
    -- }

    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.ACHIEVEMENT,
        ItemId = AchieveId,
        DragCallBackFunc = Bind(self, self.OnDragCallBackFunc),
        ClickMethod = UE.EButtonClickMethod.DownAndUp,
        -- ClickMethod = UE.EButtonClickMethod.PreciseClick,
        -- HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
        ShowItemName = true,

        RightCornerTagId = CornerTagInfo.RightCornerTagId,
        RightCornerTagHeroId = CornerTagInfo.RightCornerTagHeroId,
        RightCornerTagHeroSkinId = CornerTagInfo.RightCornerTagHeroSkinId,
        IsLock = CornerTagInfo.IsLock,
        IsGot = CornerTagInfo.IsGot,
        IsOutOfDate = CornerTagInfo.IsOutOfDate,
    }

    local ComItemIcon = self.View.WBP_CommonItemIcon
    if not self.WidgetListInstance then
        self.WidgetListInstance = UIHandler.New(self, ComItemIcon, CommonItemIcon, IconParam).ViewInstance
    else
        self.WidgetListInstance:UpdateUI(IconParam)
    end

    --TODO:名字
    if CommonUtil.IsValid(self.View.RootName) then
        self.View.RootName:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end

    if CommonUtil.IsValid(self.View.GUITextBlock_Name) then
        self.View.GUITextBlock_Name:SetText(self.AchieveData:GetName())
        -- if UE.UGFUnluaHelper.IsEditor() then
        --     --名字
        --     -- AchieveData:GetName()
        --     --ID
        --     -- AchieveData.UniID.."|"..AchieveData.ID
        --     --获得时间
        --     -- AchieveData:GetTimeStr()
        --     --任务ID
        --     -- AchieveData.TaskId
        --     --数量
        --     -- AchieveData.Count
        --     self.View.GUITextBlock_Name:SetText(StringUtil.Format("{0}|{1}|{2}", tostring(self.AchieveData.TaskId), tostring(self.AchieveData.ID), self.AchieveData:GetName()))
        -- end
    end
    
    if CommonUtil.IsValid(self.View.GUITextBlock_Level) then
        self.View.GUITextBlock_Level:SetText(self.AchieveData:GetCurQualityCap())
    end
end

---拖拽回调
---@param Params {Handle:UUserWidget,Icon,ItemId,DragType}
function AchieveChooseListItem:OnDragCallBackFunc(Param)
    if self.OnDragCallBack then
        ---@type AchievementData
        local AchieveData = self.AchieveData
        local Param = {
            AchieveId = AchieveData.ID,
            DragType = Param.DragType
        }
        self.OnDragCallBack(Param)
    end
end

function AchieveChooseListItem:SetIsSelect(bSelected)
    self.WidgetListInstance:SetIsSelect(bSelected)
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- --[[
--     {
--         AchieveData,
--         HeroId = self.HeroId,
--         ClickFunc
--         Index
--     }
-- ]]
-- function AchieveChooseListItem:SetData(Param, OnItemCallBack)
--     self.Param = Param
--     self.ClickFunc = Param.ClickFunc
--     self.OnItemCallBack = OnItemCallBack
--     self:SetAchieveData()
-- end

-- function AchieveChooseListItem:SetAchieveData()
--     if self.Param == nil or self.Param.AchieveData == nil then
--         return
--     end
    
--     self:SetUiInfo()

--     self.IsLocked = not self.Param.AchieveData:IsUnlock()
--     self.IsSelected = MvcEntry:GetModel(HeroModel):HasDisplayBoardAchieveIdSelected(self.Param.HeroId, self.Param.AchieveData.ID)
--     self.UsedByHeroId = 0
--     self:UpdateStateShow()
-- end

-- function AchieveChooseListItem:SetUiInfo()
--     ---@type AchievementData
--     local AchieveData = self.Param.AchieveData

--     ---通用控件
--     if CommonUtil.IsValid(self.View.WBP_CommonItemIcon) then

--         local ComItemIcon = self.View.WBP_CommonItemIcon

--         local AchieveId = AchieveData.ID
--         if not AchieveId then
--             ComItemIcon:SetVisibility(UE.ESlateVisibility.Collapsed)
--             return
--         end
--         ComItemIcon:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
     
--         local IconParam = {
--             IconType = CommonItemIcon.ICON_TYPE.ACHIEVEMENT,
--             ItemId = AchieveId,
--             DragCallBackFunc = Bind(self, self.DragCallBackFunc1),
--             ClickMethod = UE.EButtonClickMethod.DownAndUp,
--             HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
--             ShowItemName = true,
--             IsItemShowStateChanged = true,
--             RightCornerTagId = CornerTagCfg.HeroBg.TagId,
--             RightCornerTagHeroId = 200010000,
--             RightCornerTagHeroSkinId = 200010001,
--         }
--         if not self.WidgetListInstance then
--             self.WidgetListInstance = UIHandler.New(self, ComItemIcon, CommonItemIcon, IconParam).ViewInstance
--         else
--             self.WidgetListInstance:UpdateUI(IconParam)
--         end
--     end

--     --图片
--     CommonUtil.SetBrushFromSoftObjectPath(self.View.GUIImageIcon, AchieveData:GetIcon())

--     --名字
--     self.View.GUITextBlock_Name:SetText(AchieveData:GetName())

--     if UE.UGFUnluaHelper.IsEditor() then
--         if UE.UGFUnluaHelper.IsEditor() then
--             self.View.GUITextBlock_Name:SetText(AchieveData.UniID.."|"..AchieveData.ID)
--         end

--         --等级
--         self.View.GUITextBlock_Level:SetText(AchieveData:GetCurQualityCap())
        
--         --获得时间
--         self.View.GUITextBlock_Get:SetText(AchieveData:GetTimeStr())
--         if UE.UGFUnluaHelper.IsEditor() then
--             self.View.GUITextBlock_Get:SetText(AchieveData:IsUnlock() and "OK" or "NO")
--         end

--         --数量
--         self.View.GUITextBlock_Count:SetText(StringUtil.FormatText(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_OneParam_Pro1_7"),AchieveData.Count))
--         if UE.UGFUnluaHelper.IsEditor() then
--             self.View.GUITextBlock_Count:SetText(AchieveData.TaskId)
--         end
--     else
--         self.View.GUITextBlock_Name:SetVisibility(UE.ESlateVisibility.Collapsed)
--         self.View.GUITextBlock_Level:SetVisibility(UE.ESlateVisibility.Collapsed)
--         self.View.GUITextBlock_Get:SetVisibility(UE.ESlateVisibility.Collapsed)
--         self.View.GUITextBlock_Count:SetVisibility(UE.ESlateVisibility.Collapsed)
--     end
-- end



-- --[[
--     状态显示
--     已装备
--     未解锁
--     已解锁未装备
-- ]]
-- function AchieveChooseListItem:UpdateStateShow()
--     local CommonSubscriptWidget = self.View.WBP_CommonSubscript_Equiped
--     if CommonSubscriptWidget == nil then
--         return
--     end

--     CommonSubscriptWidget.WidgetSwitcherState:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--     if self.UsedByHeroId > 0 then
--         CommonSubscriptWidget.WidgetSwitcherState:SetActiveWidget(CommonSubscriptWidget.Used)
--     elseif self.IsSelected then
--         CommonSubscriptWidget.WidgetSwitcherState:SetActiveWidget(CommonSubscriptWidget.Equiped)
--     elseif self.IsLocked then
--         CommonSubscriptWidget.WidgetSwitcherState:SetActiveWidget(CommonSubscriptWidget.Locked)
--     else
--         CommonSubscriptWidget.WidgetSwitcherState:SetVisibility(UE.ESlateVisibility.Collapsed)
--     end

--     if self.UsedByHeroId  > 0 then
--        CLog("Achieve: UsedByHeroId === ")
--     end

--     self.View.WidgetSwitcherBg:SetActiveWidgetIndex(self.IsLocked and 1 or 0)
-- end

-- function AchieveChooseListItem:Select()
--     if self.IsLock then
--         self.View.GUIImageSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
--         self.View.GUIImageLockSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--     else
--         self.View.GUIImageSelect:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
--         self.View.GUIImageLockSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
--     end
-- end


-- function AchieveChooseListItem:UnSelect()
--     self.View.GUIImageSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
--     self.View.GUIImageLockSelect:SetVisibility(UE.ESlateVisibility.Collapsed)
-- end


-- function AchieveChooseListItem:OnClicked_BtnClick()
--     if self.Param and self.Param.ClickFunc then
--         self.Param.ClickFunc(self, self.Param.AchieveData)
--     end
-- end

-- function AchieveChooseListItem:OnBtnHovered()
--     self.View.RootPanel:SetRenderScale(UE.FVector2D(1.1,1.1))
--     if self.View.Slot then
--         self.View.Slot:SetZOrder(1)
--     end
-- end

-- function AchieveChooseListItem:OnBtnUnhovered()
--     self.View.RootPanel:SetRenderScale(UE.FVector2D(1,1))
--     if self.View.Slot then
--         self.View.Slot:SetZOrder(0)
--     end
-- end



return AchieveChooseListItem

