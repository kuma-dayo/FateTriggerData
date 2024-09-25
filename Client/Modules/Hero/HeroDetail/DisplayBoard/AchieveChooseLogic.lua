--[[
    角色展示板选择成就
]]

---@class AchieveChooseLogic
local class_name = "AchieveChooseLogic"
local AchieveChooseLogic = BaseClass(nil, class_name)


local SLOT_NUM = 3

function AchieveChooseLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    self.Widget2ItemHandler = {}

    self.BindNodes = {
        { UDelegate = self.View.WBP_ReuseList.OnUpdateItem,	    Func = Bind(self, self.OnUpdateItem)},
	}

    self.MsgList = {
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_ACHIEVE_SELECT, Func = Bind(self, self.ON_HERO_DISPLAYBOARD_ACHIEVE_SELECT_Func) },
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_BUY, Func = Bind(self, self.ON_HERO_DISPLAYBOARD_BUY_Func) },
        {Model = AchievementModel, MsgName = AchievementModel.ACHIEVE_DATA_UPDATE, Func = Bind(self, self.ON_ACHIEVE_DATA_UPDATE_Func) },
    }

    UIHandler.New(self, self.View.GUIButtonEquip, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonEquip),
        CommonTipsID = CommonConst.CT_SPACE,
        ActionMappingKey = ActionMappings.SpaceBar,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_AchieveChooseLogic_show"),--展示
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        CheckButtonIsVisible = true,
    })

    UIHandler.New(self, self.View.GUIButtonUnEquip, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonUnEquip),
        CommonTipsID = CommonConst.CT_SPACE,
        ActionMappingKey = ActionMappings.SpaceBar,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_AchieveChooseLogic_unload"),--卸下
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        CheckButtonIsVisible = true,
    })

    UIHandler.New(self, self.View.GUIButtonNoAvailable, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonNoAvailable),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_AchieveChooseLogic_Notunlockedyet"),--尚未解锁
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        CheckButtonIsVisible = true,
    }).ViewInstance:SetBtnEnabled(false)
  
    UIHandler.New(self, self.View.GUIButtonFetch, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonFetch),
        CommonTipsID = CommonConst.CT_SPACE,
        ActionMappingKey = ActionMappings.SpaceBar,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_AchieveChooseLogic_Gotoget_Btn"),--前往获取
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        CheckButtonIsVisible = true,
    })
end

function AchieveChooseLogic:OnShow(Param)
    if not Param then
        return
    end

    ---@type HeroModel
    self.ModelHero = MvcEntry:GetModel(HeroModel)
    ---@type DepotModel
    self.ModelDepot = MvcEntry:GetModel(DepotModel)

    self.HeroId = Param.HeroId
    self.TabId = Param.TabId
    self.OnChooseBoradItem = Param.OnChooseBoradItem
    self.RequestAvatarHiddenInGame = Param.OnRequestAvatarHiddenInGame

    --默认无选中的成就
    self:SetChooseBoradData(0, nil)

    --更新成就列表
    self:UpdateAchieveListShow()
    --更新3D列表
    self:Update3DAchieveListShow()
    --切换右下角按钮
    self:UpdateButtonStateByChoose()
    --更新左侧Slot
    self:UpdateSlotListShow()
end

function AchieveChooseLogic:OnManualShow(param)
    self:OnShow(param)
end

function AchieveChooseLogic:OnManualHide(param)
    self:OnHide()
end

function AchieveChooseLogic:OnHide()
    -- self.ItemIns2Id = nil

    self:RemoveAutoHideTimer()
    self:RemoveClosureTimer()
    self:RemoveDoubleClickResetTimer()
end

function AchieveChooseLogic:OnShowAvator(Data,IsNotVirtualTrigger) 
    -- CError("---------------------- OnShowAvator,IsNotVirtualTrigger ="..tostring(IsNotVirtualTrigger))
    if IsNotVirtualTrigger then
        if self.RequestAvatarHiddenInGame then
            local param = {bHide = false,bReShowDisplayBoard = false}
            self.RequestAvatarHiddenInGame(param)
        end
    end
end

function AchieveChooseLogic:OnHideAvator(Data,IsNotVirtualTrigger) 
    -- CError("---------------------- OnHideAvator,IsNotVirtualTrigger ="..tostring(IsNotVirtualTrigger))
end

-------------------------------------------------------------------------------List >>

function AchieveChooseLogic:UpdateAchieveListShow()
    self.ItemIns2Id = {}
    
    ---@type AchievementData[]
    self.DataList = self:GetValidDisplayBoardData(self.HeroId)
    self:SortDisplayBoardData(self.DataList)

    self.DataListSize = #self.DataList
    self.View.WBP_ReuseList:Reload(#self.DataList)
end

---获取有效的贴纸数据
function AchieveChooseLogic:GetValidDisplayBoardData(HeroId)
    ---@type AchievementData[]
    local ListData = MvcEntry:GetModel(AchievementModel):GetAchievementDataByHeroId(HeroId)
    return ListData
end

---排序
function AchieveChooseLogic:SortDisplayBoardData(ListData)
    if ListData == nil or next(ListData) == nil then
        return
    end

    ---@param ItemA AchievementData
    ---@param ItemB AchievementData
    local SortFunc = function (ItemA, ItemB)
        local IsEquipedA = self.ModelHero:HasDisplayBoardAchieveIdSelected(self.HeroId, ItemA.ID) and 1 or 0
        local IsEquipedB = self.ModelHero:HasDisplayBoardAchieveIdSelected(self.HeroId, ItemB.ID) and 1 or 0
        if IsEquipedA ~= IsEquipedB then
            return IsEquipedA > IsEquipedB
        end

        local IsAUnlock = ItemA:IsUnlock() and 1 or 0
        local IsBUnlock = ItemB:IsUnlock() and 1 or 0
        if IsAUnlock ~= IsBUnlock then
            return IsAUnlock > IsBUnlock
        end

        if ItemA.Quality ~= ItemB.Quality then
            return ItemA.Quality > ItemB.Quality
        end
        return ItemA.ID > ItemB.ID
    end

    table.sort(ListData, SortFunc)
end

---@return AchievementData
function AchieveChooseLogic:GetAchiveData(AchiveId)
    for _, v in ipairs(self.DataList) do
        if v.ID == AchiveId then
            return v
        end
    end
    return nil
end

---获取物品状态以及角标状态
function AchieveChooseLogic:GetCornerTagInfo(AchieveId)
    local CornerTagInfo = {
        RightCornerTagId = 0,
        RightCornerTagHeroId = 0,
        RightCornerTagHeroSkinId = 0,
        IsLock = false,
        IsGot = false,
        IsOutOfDate = false,
        ItemState = HeroDefine.EDisplayBoardItemState.Owned
    }
    
    ---@type AchievementData
    local AchieveData = self:GetAchiveData(AchieveId)

    ---是否解锁
    CornerTagInfo.IsLock = not(AchieveData:IsUnlock()) 
    if CornerTagInfo.IsLock then
        --被锁住
        CornerTagInfo.RightCornerTagId = CornerTagCfg.Lock.TagId
        CornerTagInfo.ItemState = HeroDefine.EDisplayBoardItemState.Lock
        return CornerTagInfo 
    end

    --是否被当前装备
    local bEquipped = self.ModelHero:HasDisplayBoardAchieveIdSelected(self.HeroId, AchieveId)
    if bEquipped then
        --被装备
        CornerTagInfo.RightCornerTagId = CornerTagCfg.Equipped.TagId
        CornerTagInfo.ItemState = HeroDefine.EDisplayBoardItemState.EquippedByCur
        return CornerTagInfo
    end

    --是否被其它英雄装备
    local HeroList = {}
    -- HeroList = self.ModelHero:GetAchieveUsedByHeroId(AchieveId, self.HeroId) --成就不需要显示 被其它英雄装备 的标记,所以注释此代码
    if HeroList and next(HeroList) then
        --被装备
        CornerTagInfo.RightCornerTagId = CornerTagCfg.HeroBg.TagId
        CornerTagInfo.RightCornerTagHeroId = HeroList[1]
        CornerTagInfo.RightCornerTagHeroSkinId = self.ModelHero:GetDefaultSkinIdByHeroId(HeroList[1])

        CornerTagInfo.ItemState = HeroDefine.EDisplayBoardItemState.EquippedByOther
    end

    return CornerTagInfo
end

function AchieveChooseLogic:CreateItem(Widget)
	local Item = self.Widget2ItemHandler[Widget]
	if not Item then
        local Param = {OnDragCallBack = Bind(self, self.OnDragAchieveItemFunc)}
		Item = UIHandler.New(self, Widget, require("Client.Modules.Hero.HeroDetail.DisplayBoard.AchieveChooseListItem"), Param)
		self.Widget2ItemHandler[Widget] = Item
	end
	return Item.ViewInstance
end

function AchieveChooseLogic:OnUpdateItem(Handler, Widget, Index)
	local FixIndex = Index + 1
    ---@type AchievementData
	local AchieveData = self.DataList[FixIndex]
	if AchieveData == nil then
		return
	end

    local AchieveId = AchieveData.ID
    local CornerTagInfo = self:GetCornerTagInfo(AchieveId)

    local AcParam = {
        ChoosedId = self.ChooseAchieveId,
        AchieveId = AchieveId,
        AchieveData = AchieveData,
        CornerTagInfo = CornerTagInfo
    }

	local ItemIns = self:CreateItem(Widget)
    ItemIns:UpdateUI(AcParam)

    self.ItemIns2Id[ItemIns] = AchieveId
    
    if AchieveId == self.ChooseAchieveId then
        ItemIns:SetIsSelect(true)
    else
        ItemIns:SetIsSelect(false)
    end
end

---设置选中数据
function AchieveChooseLogic:SetChooseBoradData(AchieveId, AchieveData)
    self.ChooseAchieveId = AchieveId
    ---@type AchievementData
    self.ChooseAchieveData = AchieveData

    if self.OnChooseBoradItem then
        local Param = {TabId = self.TabId, ItemId = 0, BoradId = self.ChooseAchieveId}
        self.OnChooseBoradItem(Param)
    end
end

---检查选择的成就是否是 解锁的
function AchieveChooseLogic:CheckChooseAchieveIsUnlock()
    if self.ChooseAchieveId <= 0 then 
        return false
    end

    if self.ChooseAchieveData == nil or not(self.ChooseAchieveData:IsUnlock()) then
        return false
    end

    return true
end

---设置选中标记
function AchieveChooseLogic:SetSelectedMark(InAchieveId)
    for ItemIns ,AchieveId in pairs(self.ItemIns2Id) do
        if InAchieveId == AchieveId then
            ItemIns:SetIsSelect(true)
        else
            ItemIns:SetIsSelect(false)
        end
    end
end

-------------------------------------------------------------------------------List <<


-------------------------------------------------------------------------------Drag >>

---拖拽成就列表中的成就Item
function AchieveChooseLogic:OnDragAchieveItemFunc(Param)
    --处理拖拽行为
    self:HandleDraggingBehavior(Param)
end

---处理拖拽行为
---@param Param { AchieveId:number, DragType:CommonConst.DRAG_TYPE_DEFINE}
function AchieveChooseLogic:HandleDraggingBehavior(Param)
    local AchieveId = Param.AchieveId
    local DragType = Param.DragType

    -- AchieveData, DragType
    ---@type AchievementData
    local AchieveData =  self:GetAchiveData(AchieveId)
    if AchieveData == nil then
        CError(string.format("处理拖拽回调 AchieveData == nil AchieveId = %s", AchieveId))
        return
    end

    -- CError("处理拖拽回调 DragType = "..DragType)

    --设置选中数据
    self:SetChooseBoradData(AchieveId, AchieveData)
    --切换选中标签
    self:SetSelectedMark(AchieveId)
    --切换右下角按钮
    self:UpdateButtonStateByChoose()

    if not(AchieveData:IsUnlock()) then
        --TODO:未解锁
        -- CError(string.format("处理拖拽回调 未解锁 AchieveId = %s", AchieveId))
        
        -- UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_AchieveChooseLogic_Notunlockedyet"))--尚未解锁

        --更新左侧Slot
        self:UpdateSlotListShow(false)
        return    
    end

    -- 获取成就是否被装备
    local bEqui = self.ModelHero:HasDisplayBoardAchieveIdSelected(self.HeroId, AchieveId)
    if bEqui then
        --TODO:已被装备
        -- CError(string.format("处理拖拽回调/点击回调 已被装备 AchieveId = %s",AchieveId))
    end
    
    self.bDragging = DragType == CommonConst.DRAG_TYPE_DEFINE.DRAG_END
    if DragType == CommonConst.DRAG_TYPE_DEFINE.DRAG_BEGIN then
        self:ResetDoubleClickData()
        self:RemoveAutoHideTimer()
        self.AutoHideTimer = self:InsertTimer(Timer.NEXT_TICK, function()
            --移动拖拽Widget
            local MousePos = UE.UWidgetLayoutLibrary.GetMousePositionOnPlatform() 
            local _,CurViewPortPos = UE.USlateBlueprintLibrary.AbsoluteToViewport(self.View, MousePos)
            self.View.MoveItem.Slot:SetPosition(CurViewPortPos)
        end, true)

        self.View.MoveItem:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        local IconParam = {
            -- RightCornerTagId = 0,
            IconType = CommonItemIcon.ICON_TYPE.ACHIEVEMENT,
            ItemId = AchieveData.ID,
        }
        if self.MoveItemIns then
            self.MoveItemIns:UpdateUI(IconParam)
        else
            -- self.MoveItemIns = UIHandler.New(self, self.View.MoveItem, CommonItemIcon, IconParam).ViewInstance
            self.MoveItemIns = UIHandler.New(self, self.View.MoveItem, require("Client.Modules.Common.CommonItemIconMove"), IconParam).ViewInstance
        end
    else
        self:RemoveAutoHideTimer()
        self.View.MoveItem:SetVisibility(UE.ESlateVisibility.Collapsed)
        if self.MoveItemIns then
            self.MoveItemIns:OnHide()
        end
    end

    if DragType == CommonConst.DRAG_TYPE_DEFINE.DRAG_BEGIN or DragType == CommonConst.DRAG_TYPE_DEFINE.CLICK then
        --TODO:选中了具体的成就，更新左侧Slot
        self:UpdateSlotListShow(true)
    end

    if DragType == CommonConst.DRAG_TYPE_DEFINE.CLICK then
        self:CheckIsDoubleClick()
    end

    if DragType == CommonConst.DRAG_TYPE_DEFINE.DRAG_END then
        --TODO:放弃选中的具体的成就
        -- CError("处理拖拽回调,拖拽结束 DragType = "..DragType)
        self:ResetDoubleClickData()
        self:RemoveClosureTimer()
        self.ClosureTimer = self:InsertTimer(0.3, function()
            -- self:SetChooseBoradData(0, nil)
            -- --更新左侧Slot
            -- self:UpdateSlotListShow(false)
            -- --刷新列表
            -- self.View.WBP_ReuseList:Refresh()

            -- CError("定时器:触发闭包")
            --执行闭包:处理拖拽结束时的情况
            self:ExeDragEndClosure(2)
        end)

        --TODO:制作闭包
        local MakeClosureFunc = function()
            local SaveDragType = DragType
            self.ClosureUniID = self.ClosureUniID and (self.ClosureUniID + 1) or (os.time())
            local SaveUniID = self.ClosureUniID
            local CheckDragEnd = function()
                -- CError("执行了闭包函数 1")
                if SaveUniID == self.ClosureUniID and SaveDragType == CommonConst.DRAG_TYPE_DEFINE.DRAG_END then
                    -- CError("执行了闭包函数 2")
                    self:SetChooseBoradData(0, nil)
                    --更新左侧Slot
                    self:UpdateSlotListShow(false)
                    --刷新列表
                    self.View.WBP_ReuseList:Refresh()
                end
            end
            return CheckDragEnd
        end
        self.DragEndClosure = MakeClosureFunc()
    end
end

---检测双击
function AchieveChooseLogic:CheckIsDoubleClick()
    -- self.NoteTime = self.NoteTime or nil
    -- self.NoteId = self.NoteId or 0
    -- local UtcNow = UE.UKismetMathLibrary.ToUnixTimestamp(UE.UKismetMathLibrary.UtcNow())
    local UtcNow = UE.UKismetMathLibrary.UtcNow()
    -- CError(string.format("CheckIsDoubleClick 1 UtcNow = %s,self.NoteId = %s, self.NoteTime = %s",tostring(UtcNow),tostring(self.NoteId),tostring(self.NoteTime)))
    CLog(string.format("CheckIsDoubleClick 1 UtcNow = %s,self.NoteId = %s, self.NoteTime = %s",tostring(UtcNow),tostring(self.NoteId),tostring(self.NoteTime)))
    if self.NoteId and self.NoteId == self.ChooseAchieveId and self.NoteTime then
        -- GetTotalMilliseconds
        local tt = UE.UKismetMathLibrary.Subtract_DateTimeDateTime(UtcNow,self.NoteTime)
        -- local tt = UtcNow - self.NoteTime
        -- local tt2 = UE.UKismetMathLibrary.ToUnixTimestamp(tt)
        local tt2 = UE.UKismetMathLibrary.GetTotalMilliseconds(tt)
        local tt3 = UE.UKismetMathLibrary.GetMilliseconds(tt)
        -- CError(string.format("CheckIsDoubleClick 2 UtcNow - self.NoteTime = %s,tt3=%s",tostring(tt2), tostring(tt3)))
        if tt2 < CommonConst.DOUBLECLICKTIME * 1000 then
            self:OnClicked_GUIButtonEquip()
        end
        -- if UtcNow - self.NoteTime < 300 then
        --     self.NoteTime = 0
        -- end

        self:ResetDoubleClickData()
    else
        self.NoteTime = UtcNow
        self.NoteId = self.ChooseAchieveId

        self:RemoveDoubleClickResetTimer()
        self.DoubleClickResetTimer = self:InsertTimer(CommonConst.DOUBLECLICKTIME, function()
            self:ResetDoubleClickData()
        end, false)
    end
end

function AchieveChooseLogic:RemoveDoubleClickResetTimer()
    if self.DoubleClickResetTimer then
        self:RemoveTimer(self.DoubleClickResetTimer)
    end
    self.DoubleClickResetTimer = nil
end

function AchieveChooseLogic:ResetDoubleClickData()
    self:RemoveDoubleClickResetTimer()
    self.NoteTime = nil
    self.NoteId = 0
end

---执行闭包:处理拖拽结束时的情况
function AchieveChooseLogic:ExeDragEndClosure(ExeReason)
    if self.DragEndClosure then
        -- CError(string.format("--执行闭包:处理拖拽结束时的情况,ExeReason = %s", tostring(ExeReason)))
        self.DragEndClosure()
    end
    self.DragEndClosure = nil

    self:RemoveClosureTimer()
end

function AchieveChooseLogic:RemoveClosureTimer()
    if self.ClosureTimer then
        self:RemoveTimer(self.ClosureTimer)
    end
    self.ClosureTimer = nil
end

function AchieveChooseLogic:RemoveAutoHideTimer()
    if self.AutoHideTimer then
        self:RemoveTimer(self.AutoHideTimer)
    end
    self.AutoHideTimer = nil    
end
-------------------------------------------------------------------------------Drag <<

-------------------------------------------------------------------------------Slot >>

function AchieveChooseLogic:GetSlotWidget(Slot)
    if Slot == 1 then
        return self.View.WBP_Widget1
    elseif Slot == 2 then
        return self.View.WBP_Widget2
    elseif Slot == 3 then
        return self.View.WBP_Widget3
    end
end

---更新左侧Slot
---@param bEditing boolean
function AchieveChooseLogic:UpdateSlotListShow(bEditing)
    bEditing = bEditing or false

    for Slot = 1, SLOT_NUM, 1 do
        local Param = {
            Slot = Slot,
            HeroId = self.HeroId,
            ChooseId = self.ChooseAchieveId,
            bEditing = bEditing,
            OnClickedSlotArea = Bind(self,self.OnClickedSlotArea),
            OnHoveredSlotArea = Bind(self,self.OnHoveredSlotArea),
            OnDragCallBack = Bind(self,self.OnDragSlotFunc),
            OnClickedUnequip = Bind(self,self.OnClickedUnequip),
            OnClickedReplace = Bind(self,self.OnClickedReplace),
        }

        local SlotWidget = self:GetSlotWidget(Slot)
        self.Slot2WidgetIns = self.Slot2WidgetIns or {}
        if self.Slot2WidgetIns[Slot] == nil or not(self.Slot2WidgetIns[Slot]:IsValid()) then
            self.Slot2WidgetIns[Slot] = UIHandler.New(self, SlotWidget, require("Client.Modules.Hero.HeroDetail.DisplayBoard.AchieveChooseSlotItem"), Param).ViewInstance
        end
        self.Slot2WidgetIns[Slot]:UpdateUI(Param)
    end
end

---点击Slot
function AchieveChooseLogic:OnClickedSlotArea(Param)
    -- CError(string.format("---点击Slot ,Param = %s,ChooseAchieveId = %s", table.tostring(Param), self.ChooseAchieveId))

    if not(self:CheckChooseAchieveIsUnlock()) then 
        return
    end

    self:SendProto_PlayerAchieveReq(true, Param.Slot, self.ChooseAchieveId)
end

---拖拽到Slot
function AchieveChooseLogic:OnHoveredSlotArea(Param)
    -- CError(string.format("拖拽到Slot ,Param = %s, bDragging =%s, ChooseAchieveId = %s", table.tostring(Param), tostring(self.bDragging), self.ChooseAchieveId))

    if not(self.bDragging) then
        return
    end

    if not(self:CheckChooseAchieveIsUnlock()) then 
        return
    end

    local AchieveId = self.ChooseAchieveId
    self:SendProto_PlayerAchieveReq(true, Param.Slot, self.ChooseAchieveId)

    -- CError("拖拽到Slot:触发闭包")
    ---执行闭包:处理拖拽结束时的情况
    self:ExeDragEndClosure(1)
end

---拖拽Slot的成就
function AchieveChooseLogic:OnDragSlotFunc(Param)
    -- CError(string.format("拖拽Slot的成就 ,Param = %s", table.tostring(Param)))

    --处理拖拽行为
    self:HandleDraggingBehavior(Param)
end

---点击Slot卸载成就
function AchieveChooseLogic:OnClickedUnequip(Param)
    -- CError(string.format("点击Slot卸载成就 ,Param = %s", table.tostring(Param)))

    -- 卸载成就
    self:SendProto_PlayerAchieveReq(false, Param.Slot, Param.AchieveId)
end

---点击Slot替换成就
function AchieveChooseLogic:OnClickedReplace(Param)
    -- CError(string.format("点击Slot替换成就 ,Param = %s, ChooseAchieveId = %s", table.tostring(Param), self.ChooseAchieveId))

    if not(self:CheckChooseAchieveIsUnlock()) then 
        return
    end

    -- 卸载成就
    -- self:SendProto_PlayerAchieveReq(false, Param.Slot, Param.AchieveId)
    -- 装配成就
    self:SendProto_PlayerAchieveReq(true, Param.Slot, self.ChooseAchieveId)
end

-------------------------------------------------------------------------------Slot <<

-------------------------------------------------------------------------------Slot3D >>

function AchieveChooseLogic:Update3DAchieveListShow()
    local Update3DAchieveShow = function(Slot)
        local AchieveId = self.ModelHero:GetSelectedDisplayBoardAchieveId(self.HeroId, Slot)
        local Param = {
            DisplayId = self.HeroId,
            Slot = Slot,
            AchieveId = AchieveId
        }
        self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_ACHIEVE_CHANGE, Param)
    end

    for Slot=1, SLOT_NUM do
        Update3DAchieveShow(Slot)
    end
end
-------------------------------------------------------------------------------Slot3D <<

-------------------------------------------------------------------------------btn >>

-- function AchieveChooseLogic:ActiveButtonStateByChoose(ActiveBtn)
--     if self.BtnWidgets == nil then
--         self.BtnWidgets = {self.View.GUIButtonNoAvailable,self.View.GUIButtonEquip,self.View.GUIButtonUnEquip,self.View.GUIButtonFetch}    
--     end
--     for k, BtnWidget in pairs(self.BtnWidgets) do
--         if CommonUtil.IsValid(BtnWidget) then
--             if BtnWidget == ActiveBtn then
--                 BtnWidget:Setvisibility(UE.ESlateVisibility.Visible)
--             else
--                 BtnWidget:Setvisibility(UE.ESlateVisibility.Collapsed)
--             end
--         end
--     end
-- end

--- 更新按钮的状态：
---切换右下角按钮
--- 1、选择不同的Slot
--- 2、选择不同的AchieveId
--- 3、购买
function AchieveChooseLogic:UpdateButtonStateByChoose()
    -- self.ChooseAchieveId
    -- self.ChooseAchieveData
    if self.ChooseAchieveId == 0 or self.ChooseAchieveData == nil  then
        self.View.WidgetSwitcher:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end

    if self.ChooseAchieveData:IsUnlock() then
        --已经解锁
        self.View.WidgetSwitcher:SetVisibility(UE.ESlateVisibility.Collapsed)
        return
    end

    self.View.WidgetSwitcher:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    
    -- if self.ChooseAchieveData:GetCanAvailable() then
    --     --前往获取 GetCanAvailable():这个函数失效了
    --     self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonFetch)
    -- else 
    --     --尚未解锁;不能获取的
    --     self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonNoAvailable)
    -- end

    --前往获取
    self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonFetch)
end

---获取一个空的Slot
function AchieveChooseLogic:GetEmptySlot()
    for Slot = 1, SLOT_NUM, 1 do
        local AchieveId = self.ModelHero:GetSelectedDisplayBoardAchieveId(self.HeroId, Slot)
        if AchieveId <= 0 then
            return Slot
        end
    end
    return SLOT_NUM
end

---装备按钮：未来可用作双击事件
function AchieveChooseLogic:OnClicked_GUIButtonEquip()
    if not(self:CheckChooseAchieveIsUnlock()) then 
        return
    end

    self:ResetDoubleClickData()
    local Slot = self:GetEmptySlot()
    self:SendProto_PlayerAchieveReq(true, Slot, self.ChooseAchieveId)
end

---卸载按钮
function AchieveChooseLogic:OnClicked_GUIButtonUnEquip()
    local GetEquippedSlot = function()
        for Slot = 1, SLOT_NUM, 1 do
            local AchieveId = self.ModelHero:GetSelectedDisplayBoardAchieveId(self.HeroId, Slot)
            if AchieveId > 0 then
                return Slot
            end
        end
        return SLOT_NUM
    end

    self:ResetDoubleClickData()

    local Slot = self:GetEquippedSlot()
    self:SendProto_PlayerAchieveReq(false, Slot)
end

function AchieveChooseLogic:OnClicked_GUIButtonFetch()
    --TODO:前往获取
    CWaring("点击 前往获取 个人中心的成就页签 成就")
    -- 12 个人中心的成就页签
    local JumpIDs = UE.TArray(UE.int32)
    JumpIDs:AddUnique(JumpCode.AchieveMent.JumpId)
    MvcEntry:GetCtrl(ViewJumpCtrl):JumpToByTArrayList(JumpIDs)
end

function AchieveChooseLogic:OnClicked_GUIButtonNoAvailable()
    --TODO:尚未解锁
    CError("点击 尚未解锁")
end

-------------------------------------------------------------------------------btn <<

-------------------------------------------------------------------------------Server >>

---服务器事件:成就装备/卸载
function AchieveChooseLogic:ON_HERO_DISPLAYBOARD_ACHIEVE_SELECT_Func(Param)
    if Param == nil or Param.HeroId ~= self.HeroId then
        return
    end

    self:SetChooseBoradData(0, nil)
    --更新左侧Slot
    self:UpdateSlotListShow()
    --更新3D Slot
    self:Update3DAchieveListShow()
    --切换右下角按钮
    self:UpdateButtonStateByChoose()
    --更新成就列表
    self.View.WBP_ReuseList:Refresh()
end

---服务器事件:
function AchieveChooseLogic:ON_HERO_DISPLAYBOARD_BUY_Func()
    --切换右下角按钮
    self:UpdateButtonStateByChoose()

    --更新左侧Slot
    self:UpdateSlotListShow(false)

    --更新成就列表
    self.View.WBP_ReuseList:Refresh()
end

---服务器事件:成就改变
function AchieveChooseLogic:ON_ACHIEVE_DATA_UPDATE_Func()
    --切换右下角按钮
    self:UpdateButtonStateByChoose()

    --更新左侧Slot
    self:UpdateSlotListShow(false)

    --更新成就列表
    self.View.WBP_ReuseList:Refresh()
end

---请求装备/卸载协议
function AchieveChooseLogic:SendProto_PlayerAchieveReq(bEquip, InSlot, InAchieveId)
    self.IsLock = not (self.ModelHero:CheckGotHeroById(self.HeroId))
    if self.IsLock then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Hero","Lua_HeroDisplayBoard_PleaseUnlockHero")) --请先解锁先觉者
        return
    end
        

    InAchieveId = InAchieveId or 0
    if bEquip then
        -- CError(string.format("请求 装备 成就 InSlot= %s,AchieveId=%s",InSlot, InAchieveId))
        MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerEquipAchieveReq(self.HeroId, InSlot, InAchieveId)
    else
        -- CError(string.format("请求 卸载 成就 InSlot= %s,AchieveId=%s",InSlot, InAchieveId))
        MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerUnEquipAchieveReq(self.HeroId, InSlot)
    end

    self:SetChooseBoradData(0, nil)
end

-------------------------------------------------------------------------------Server <<


return AchieveChooseLogic