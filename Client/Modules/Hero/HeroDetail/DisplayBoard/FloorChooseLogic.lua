--[[
    角色展示板选择底板
]]

---@class FloorChooseLogic
local class_name = "FloorChooseLogic"
local FloorChooseLogic = BaseClass(UIHandlerViewBase, class_name)

function FloorChooseLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    -- self.InputFocus = true

    self.Widget2Item = {}
    ---@type HeroModel
    self.ModelHero = MvcEntry:GetModel(HeroModel)
    ---@type DepotModel
    self.ModelDepot = MvcEntry:GetModel(DepotModel)
    
    if CommonUtil.IsValid(self.View.WBP_ReuseList) then
        self.View.WBP_ReuseList:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    if CommonUtil.IsValid(self.View.WBP_ReuseList_Effect) then
        self.View.WBP_ReuseList_Effect:Setvisibility(UE.ESlateVisibility.Collapsed)
    end

    self.BindNodes = {
        { UDelegate = self.View.WBP_ReuseList.OnUpdateItem,           Func = Bind(self, self.OnUpdateItem)},
    }

    self.MsgList = {
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_FLOOR_SELECT, Func = Bind(self, self.ON_HERO_DISPLAYBOARD_FLOOR_SELECT_Func) },
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_BUY, Func = Bind(self, self.ON_HERO_DISPLAYBOARD_BUY_Func) },
        {Model = DepotModel, MsgName = ListModel.ON_UPDATED_MAP_CUSTOM, Func =  Bind(self, self.ON_UPDATED_MAP_CUSTOM_Func) },
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.W),Func = Bind(self, self.OnWClick)}, 
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.S), Func = Bind(self, self.OnSClick)},
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.A),Func = Bind(self, self.OnAClick) }, 
        {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.D), Func = Bind(self, self.OnDClick)}, 
    }

    self.UnlockBtnIns = UIHandler.New(self, self.View.GUIButtonBuy, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonBuy),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_FloorChooseLogic_buy"), --购买
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.SpaceBar,
        CheckButtonIsVisible = true,
    }).ViewInstance

    UIHandler.New(self, self.View.GUIButtonFetch, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonFetch),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_FloorChooseLogic_Gotoget"), --前往获取
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.SpaceBar,
        CheckButtonIsVisible = true,
    })

    UIHandler.New(self, self.View.GUIButtonEquip, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonEquip),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_FloorChooseLogic_show_Btn"), --展示
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.SpaceBar,
        CheckButtonIsVisible = true,
    })

    UIHandler.New(self, self.View.GUIButtonAlreadyEqupped, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonAlreadyEqupped),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_FloorChooseLogic_Ondisplay_Btn"), --展示中
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        CheckButtonIsVisible = true,
    }).ViewInstance:SetBtnEnabled(false)
    
    UIHandler.New(self, self.View.GUIButtonNoAvailable, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonNoAvailable),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_FloorChooseLogic_Theactivityhasended"), --活动已结束
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        CheckButtonIsVisible = true,
    }).ViewInstance:SetBtnEnabled(false)

    -- -- 红点item列表 key为FloorId
    -- self.RedDotItemList = {}
end



function FloorChooseLogic:OnShow(Param)
    if not Param then
        return
    end
    self.HeroId = Param.HeroId
    self.TabId = Param.TabId
    self.OnChooseBoradItem = Param.OnChooseBoradItem
    self.RequestAvatarHiddenInGame = Param.OnRequestAvatarHiddenInGame

    local FloorId = self.ModelHero:GetSelectedDisplayBoardFloorId(self.HeroId)
    -- self.ChooseBoardId = self.SelectedFloorId ~= 0 and self.SelectedFloorId or self.ModelHero:GetDefaultFloorIdByHeroId(self.HeroId)
    self:SetChooseBoradData(FloorId)
    
    self:UpdateFloorListShow()
    self:UpdateButtonStateByChoose()

    --检测配置是否能被展示
    self:CheckIsShowFlag(self.ChooseBoardId)
end

function FloorChooseLogic:OnManualShow(param)
    self:OnShow(param)
end

function FloorChooseLogic:UpdateUI(param)
    self:OnShow(param)
end

function FloorChooseLogic:OnManualHide(param)
    -- self:OnHide()
end

function FloorChooseLogic:OnHide()
end

function FloorChooseLogic:OnShowAvator(Data,IsNotVirtualTrigger) 
    -- CError("---------------------- OnShowAvator,IsNotVirtualTrigger ="..tostring(IsNotVirtualTrigger))
    if IsNotVirtualTrigger then
        if self.RequestAvatarHiddenInGame then
            local param = {bHide = false,bReShowDisplayBoard = false}
            self.RequestAvatarHiddenInGame(param)
        end
    end
end

function FloorChooseLogic:OnHideAvator(Data,IsNotVirtualTrigger) 
    -- CError("---------------------- OnHideAvator,IsNotVirtualTrigger ="..tostring(IsNotVirtualTrigger))
end

---检测配置是否能被展示
function FloorChooseLogic:CheckIsShowFlag(BoardId)
    BoardId = BoardId or 0
    if BoardId <= 0  then
        return
    end

    local bCanShow = false
    for k, DataCfg in pairs(self.DataList) do
        if DataCfg[Cfg_HeroDisplayFloor_P.Id] == BoardId then
            bCanShow = true
            break
        end
    end
    if not bCanShow then
        if UE.UGFUnluaHelper.IsEditor() then
            UIAlert.Show(string.format("检测配置 BoardId=[%s] 不能展示给玩家!!!", tostring(BoardId)))
        end
       
        CError(string.format("FloorChooseLogic:CheckIsShowFlag, 检测配置 BoardId=[%s] 不能展示给玩家!!!",tostring(BoardId)))
    end
end

function FloorChooseLogic:SetChooseBoradData(FloorId)
    self.ChooseBoardId = FloorId
    if self.OnChooseBoradItem then
        local Param = {TabId = self.TabId, BoradId = self.ChooseBoardId}
        self.OnChooseBoradItem(Param)
    end
end

----------------------------------------------list >>

function FloorChooseLogic:UpdateFloorListShow()
    -- self.Id2Item = {}
    self.CurSelectItem = nil

    self.DataList = self:GetValidDisplayBoardData(self.HeroId)
    self:SortDisplayBoardData(self.DataList)

    self.DataListSize = #self.DataList
	self.View.WBP_ReuseList:Reload(#self.DataList)    
end

---获取有效的贴纸数据
function FloorChooseLogic:GetValidDisplayBoardData(HeroId)
    local ListData = {}

    local Dict = G_ConfigHelper:GetDict(Cfg_HeroDisplayFloor)
    for k, Cfg in pairs(Dict) do
        if(Cfg[Cfg_HeroDisplayFloor_P.HeroId] == 0 or Cfg[Cfg_HeroDisplayFloor_P.HeroId] == HeroId) and Cfg[Cfg_HeroDisplayFloor_P.ShowFlag] then
            table.insert(ListData, Cfg)
        end
    end

    return ListData
end

---排序
function FloorChooseLogic:SortDisplayBoardData(ListData)
    if ListData == nil or next(ListData) == nil then
        return
    end

    local SortFunc = function (ItemA,ItemB)
        local IdA = ItemA[Cfg_HeroDisplayFloor_P.Id]
        local IdB = ItemB[Cfg_HeroDisplayFloor_P.Id]
        --是否装备排序
        local IsEquipedA = self.ModelHero:HasDisplayBoardFloorIdSelected(self.HeroId, IdA) and 1 or 0
        local IsEquipedB = self.ModelHero:HasDisplayBoardFloorIdSelected(self.HeroId, IdB) and 1 or 0
        if IsEquipedA ~= IsEquipedB then
            return IsEquipedA > IsEquipedB
        end

        local ItemIdA = ItemA[Cfg_HeroDisplayFloor_P.ItemId]
        local ItemIdB = ItemB[Cfg_HeroDisplayFloor_P.ItemId]
        
        --是否拥有排序
        local HasSortA = self.ModelDepot:GetItemCountByItemId(ItemIdA) > 0 and 1 or 0
        local HasSortB = self.ModelDepot:GetItemCountByItemId(ItemIdB) > 0 and 1 or 0
        if HasSortA ~= HasSortB then
            return HasSortA > HasSortB
        end

        --排序权重:越大越靠前
        if ItemA[Cfg_HeroDisplayFloor_P.SortWeight] ~= ItemB[Cfg_HeroDisplayFloor_P.SortWeight] then
            return ItemA[Cfg_HeroDisplayFloor_P.SortWeight] > ItemB[Cfg_HeroDisplayFloor_P.SortWeight]
        end

        local ItemIdACfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemIdA)
        local ItemIdBCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig, ItemIdB)
        if ItemIdACfg and ItemIdBCfg then
            --品质权重:越大越靠前
            if ItemIdACfg[Cfg_ItemConfig_P.Quality] ~= ItemIdBCfg[Cfg_ItemConfig_P.Quality] then
                return ItemIdACfg[Cfg_ItemConfig_P.Quality] > ItemIdBCfg[Cfg_ItemConfig_P.Quality]
            end
        end
       
        return IdA > IdB
    end

    table.sort(ListData, SortFunc)
end

function FloorChooseLogic:CreateItem(Widget)
	local Item = self.Widget2Item[Widget]
	if not Item then
		-- Item = UIHandler.New(self, Widget, require("Client.Modules.Hero.HeroDetail.DisplayBoard.CommonChooseListItem"))
        Item = UIHandler.New(self, Widget, CommonItemIconVertical)
		self.Widget2Item[Widget] = Item
	end
	return Item.ViewInstance
end

function FloorChooseLogic:OnUpdateItem(Handler,Widget, Index)
	local FixIndex = Index + 1
	local ConfigData = self.DataList[FixIndex]
	if ConfigData == nil then
		return
	end

	local TargetItem = self:CreateItem(Widget)
	if TargetItem == nil then
		return
	end

    local FloorId = ConfigData[Cfg_HeroDisplayFloor_P.Id]
    local ItemId = ConfigData[Cfg_HeroDisplayFloor_P.ItemId]

    local RetVal = MvcEntry:GetCtrl(HeroCtrl):GetCornerTagParam(self.TabId, self.HeroId, FloorId)
    ---@type CornerTagParam
    local CornerTagInfo = RetVal.TagParam
    -- local param = {
    --     HeroId = self.HeroId,
    --     DisplayBoardId = FloorId,
    --     DisplayBoardTabID = EHeroDisplayBoardTabID.Floor.TabId,
    --     Index = FixIndex,
    --     ClickFunc = Bind(self, self.OnFloorIdItemClick, ConfigData, TargetItem),
    -- }
    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemId,
        ClickCallBackFunc = Bind(self, self.OnFloorIdItemClick, ConfigData, TargetItem),
        -- ClickMethod = UE.EButtonClickMethod.DownAndUp,
        -- HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
        ShowItemName = false,

        RightCornerTagId = CornerTagInfo.TagId,
        RightCornerTagHeroId = CornerTagInfo.TagHeroId,
        RightCornerTagHeroSkinId = CornerTagInfo.TagHeroSkinId,
        -- IsLock = CornerTagInfo.IsLock,
        -- IsGot = CornerTagInfo.IsGot,
        IsOutOfDate = CornerTagInfo.IsOutOfDate,
        RedDotKey = "HeroDisplayBoardFloorItem_",
        RedDotSuffix = FloorId,
        RedDotInteractType = CommonConst.RED_DOT_INTERACT_TYPE.CLICK,
    }
	TargetItem:UpdateUI(IconParam)
    
    if FloorId == self.ChooseBoardId then
        TargetItem:SetIsSelect(true)
        self.CurSelectItem = TargetItem
    else
        TargetItem:SetIsSelect(false)
    end

    -- self:RegisterRedDot(TargetItem.View, FloorId)
end

function FloorChooseLogic:OnFloorIdItemClick(ConfigData, ItemView, Param)
    if ConfigData[Cfg_HeroDisplayFloor_P.Id] == self.ChooseBoardId then
        return
    end
    self:SetChooseBoradData(ConfigData[Cfg_HeroDisplayFloor_P.Id])

    if self.CurSelectItem then
		self.CurSelectItem:SetIsSelect(false)
	end
    if ItemView then
        self.CurSelectItem = ItemView
        self.CurSelectItem:SetIsSelect(true)
    end

    self:Update3DFloorShow()
    self:UpdateButtonStateByChoose()
    -- self:InteractRedDot(ConfigData[Cfg_HeroDisplayFloor_P.Id])
end

function FloorChooseLogic:Update3DFloorShow()
    local Param = {
        DisplayId = self.HeroId,
        FloorId = self.ChooseBoardId
    }
    self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_FLOOR_CHANGE, Param)
end

----------------------------------------------list <<

----------------------------------------------btn >>

-- function FloorChooseLogic:ActiveButtonStateByChoose(ActiveBtn)
--     if self.BtnWidgets == nil then
--         self.BtnWidgets = {
--             self.View.GUIButtonNoAvailable,
--             self.View.GUIButtonFetch,
--             self.View.GUIButtonBuy,
--             self.View.GUIButtonEquip,
--             self.View.GUIButtonAlreadyEqupped,
--         }    
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

function FloorChooseLogic:UpdateButtonStateByChoose()
    self.View.WidgetSwitcher:SetVisibility(self.ChooseBoardId == 0 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)

    local TblFloor = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayFloor, self.ChooseBoardId) 
    if TblFloor == nil then
        return
    end

    local ItemId = TblFloor[Cfg_HeroDisplayFloor_P.ItemId]
    
    local IsLock = not(self.ModelHero:HasDisplayBoardFloor(self.ChooseBoardId)) 
    if IsLock then
        local UnlockFlag = TblFloor[Cfg_HeroDisplayFloor_P.UnlockFlag]
        local AvailableFlag = TblFloor[Cfg_HeroDisplayFloor_P.AvailableFlag]
        if AvailableFlag then
            local JumpIDs = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(ItemId)
            if UnlockFlag then
                if self.UnlockBtnIns and self.UnlockBtnIns:IsValid() then
                    local UnlockItemId = TblFloor[Cfg_HeroDisplayFloor_P.UnlockItemId]
                    local UnlockItemNum = TblFloor[Cfg_HeroDisplayFloor_P.UnlockItemNum]
                    self.UnlockBtnIns:ShowCurrency(UnlockItemId, UnlockItemNum, JumpIDs)
                end

                self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonBuy)
            else
                if JumpIDs and JumpIDs:Length() > 0 then
                    -- 有跳转配置则显示 跳转
                    self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonFetch)
                else
                    -- 活动结束
                    self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonNoAvailable)
                end
            end
        else
            self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonNoAvailable)   
        end
    else
        local SelectedFloorId = self.ModelHero:GetSelectedDisplayBoardFloorId(self.HeroId)
        if SelectedFloorId == self.ChooseBoardId then
            self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonAlreadyEqupped)
        else
            self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonEquip)
        end
    end
end

function FloorChooseLogic:OnClicked_GUIButtonEquip()
    self.IsLock = not (self.ModelHero:CheckGotHeroById(self.HeroId))
    if self.IsLock then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Hero","Lua_HeroDisplayBoard_PleaseUnlockHero")) --请先解锁先觉者
        return
    end

    MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerSelectFloorReq(self.HeroId, self.ChooseBoardId)
end

function FloorChooseLogic:OnClicked_GUIButtonAlreadyEqupped()
    CError("FloorChooseLogic:OnClicked_GUIButtonAlreadyEqupped")
end

function FloorChooseLogic:OnClicked_GUIButtonNoAvailable()
    -- CError("FloorChooseLogic:OnClicked_GUIButtonNoAvailable")
    UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_Theactivityhasended"))--活动已结束
end

function FloorChooseLogic:OnClicked_GUIButtonFetch()
    -- CError("FloorChooseLogic:OnClicked_GUIButtonFetch")
    --前往跳转?
    local tblCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayFloor, Cfg_HeroDisplayFloor_P.Id, self.ChooseBoardId)
    if tblCfg == nil then
        --TODO:跳转失败
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_Theactivityhasended")) -- 活动已结束
        return
    end

    local JumpIDs = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(tblCfg[Cfg_HeroDisplayFloor_P.ItemId])
    if JumpIDs then
        MvcEntry:GetCtrl(ViewJumpCtrl):JumpToByTArrayList(JumpIDs)    
    end
end

function FloorChooseLogic:OnClicked_GUIButtonBuy()
    -- CWaring("self.UnlockItemId:" .. self.UnlockItemId)
    -- CError("FloorChooseLogic:OnClicked_GUIButtonBuy")
    local TblFloor = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayFloor, self.ChooseBoardId) 
    if TblFloor == nil then
        return
    end

    -- local ItemId = TblFloor[Cfg_HeroDisplayFloor_P.ItemId]
    local UnlockItemId = TblFloor[Cfg_HeroDisplayFloor_P.UnlockItemId]
    local UnlockItemNum = TblFloor[Cfg_HeroDisplayFloor_P.UnlockItemNum]
    -- local UnlockFlag = TblFloor[Cfg_HeroDisplayFloor_P.UnlockFlag]
    -- local AvailableFlag = TblFloor[Cfg_HeroDisplayFloor_P.AvailableFlag]

    local ItemName = self.ModelDepot:GetItemName(UnlockItemId)
    local Cost = UnlockItemNum
	local Balance = self.ModelDepot:GetItemCountByItemId(UnlockItemId)
	if Balance < Cost then
		local msgParam = {
			describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_FloorChooseLogic_isnotenoughtobuy"), ItemName), --{0}不够，无法购买
		}
		UIMessageBox.Show(msgParam)
		return
	end

	local msgParam = {
		-- describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_FloorChooseLogic_Areyousureyouwanttob"), Cost, ItemName), --确定要花{0}{1}购买吗？
        describe = CommonUtil.GetBuyCostDescribeText(UnlockItemId, Cost), --确定要花 {0}{1} 购买吗？
		leftBtnInfo = {},
		rightBtnInfo = {
			callback = function()
				MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerBuyFloorReq(self.ChooseBoardId)
			end
		}
	}
	UIMessageBox.Show(msgParam)
end

----------------------------------------------btn <<

----------------------------------------------server >>

function FloorChooseLogic:ON_HERO_DISPLAYBOARD_FLOOR_SELECT_Func()
    self:Update3DFloorShow()
    self:UpdateButtonStateByChoose()
    self.View.WBP_ReuseList:Refresh()
end

function FloorChooseLogic:ON_HERO_DISPLAYBOARD_BUY_Func(_, FloorId)
    if self.ChooseBoardId == FloorId then
        self:OnClicked_GUIButtonEquip()
    else
        self:UpdateButtonStateByChoose()
        self.View.WBP_ReuseList:Refresh()
    end
end

function FloorChooseLogic:ON_UPDATED_MAP_CUSTOM_Func(_,ChangeMap)
    self:UpdateButtonStateByChoose()
    self.View.WBP_ReuseList:Refresh()
end

----------------------------------------------server >>

----------------------------------------------按键 >>

function FloorChooseLogic:OnWClick()
    
end

function FloorChooseLogic:OnSClick()
    
end

function FloorChooseLogic:OnAClick()
    
end

function FloorChooseLogic:OnDClick()
    
end

----------------------------------------------按键 <<

----------------------------------------------reddot >>
-- -- 绑定红点
-- function FloorChooseLogic:RegisterRedDot(Widget, FloorId)
--     if Widget.WBP_RedDotFactory then
--         local RedDotKey = "HeroDisplayBoardFloorItem_"
--         local RedDotSuffix = FloorId
--         local RedDotItem = self.RedDotItemList[FloorId]
--         if not RedDotItem then
--             self.RedDotItemList[FloorId] = UIHandler.New(self,  Widget.WBP_RedDotFactory, CommonRedDot, {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}).ViewInstance
--         else
--             RedDotItem:ChangeKey(RedDotKey, RedDotSuffix)
--         end
--     end
-- end

-- -- 红点触发逻辑
-- function FloorChooseLogic:InteractRedDot(FloorId)
--     if self.RedDotItemList[FloorId] then
--         self.RedDotItemList[FloorId]:Interact()
--     end
-- end
----------------------------------------------reddot >>

return FloorChooseLogic
