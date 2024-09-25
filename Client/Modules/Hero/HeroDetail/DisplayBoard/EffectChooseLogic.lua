--[[
    角色展示板选择特效
]]

---@class EffectChooseLogic
local class_name = "EffectChooseLogic"
local EffectChooseLogic = BaseClass(UIHandlerViewBase, class_name)


function EffectChooseLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    self.Widget2Item = {}

    ---@type HeroModel
    self.ModelHero = MvcEntry:GetModel(HeroModel)
    ---@type DepotModel
    self.ModelDepot = MvcEntry:GetModel(DepotModel)

    if CommonUtil.IsValid(self.View.WBP_ReuseList) then
        self.View.WBP_ReuseList:Setvisibility(UE.ESlateVisibility.Collapsed)
    end
    if CommonUtil.IsValid(self.View.WBP_ReuseList_Effect) then
        self.View.WBP_ReuseList_Effect:Setvisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    end
    
    self.BindNodes = {
        { UDelegate = self.View.WBP_ReuseList_Effect.OnUpdateItem,           Func = Bind(self, self.OnUpdateItem)},
    }

    self.MsgList = {
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_EFFECT_SELECT, Func = Bind(self, self.ON_HERO_DISPLAYBOARD_EFFECT_SELECT_Func) },
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_DISPLAYBOARD_BUY, Func = Bind(self, self.ON_HERO_DISPLAYBOARD_BUY_Func) },
        {Model = DepotModel, MsgName = ListModel.ON_UPDATED_MAP_CUSTOM, Func =  Bind(self, self.ON_UPDATED_MAP_CUSTOM_Func) },
    }

    self.UnlockBtnIns = UIHandler.New(self, self.View.GUIButtonBuy, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonBuy),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_EffectChooseLogic_buy"),--购买
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.SpaceBar,
        CheckButtonIsVisible = true,
    }).ViewInstance

    UIHandler.New(self, self.View.GUIButtonFetch, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonFetch),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_EffectChooseLogic_Gotoget"),--前往获取
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.SpaceBar,
        CheckButtonIsVisible = true,
    })

    UIHandler.New(self, self.View.GUIButtonEquip, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonEquip),
        CommonTipsID = CommonConst.CT_SPACE,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_EffectChooseLogic_show"),--展示
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        ActionMappingKey = ActionMappings.SpaceBar,
        CheckButtonIsVisible = true,
    })

    UIHandler.New(self, self.View.GUIButtonAlreadyEqupped, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonAlreadyEqupped),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_EffectChooseLogic_Ondisplay_Btn"),--展示中
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        CheckButtonIsVisible = true,
    }).ViewInstance:SetBtnEnabled(false)

    UIHandler.New(self, self.View.GUIButtonNoAvailable, WCommonBtnTips,{
        OnItemClick = Bind(self, self.OnClicked_GUIButtonNoAvailable),
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_EffectChooseLogic_Theactivityhasended"),--活动已结束
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        CheckButtonIsVisible = true,
    }).ViewInstance:SetBtnEnabled(false)
end

function EffectChooseLogic:OnShow(Param)
    if not Param then
        return
    end
    self.HeroId = Param.HeroId
    self.TabId = Param.TabId
    self.OnChooseBoradItem = Param.OnChooseBoradItem
    self.RequestAvatarHiddenInGame = Param.OnRequestAvatarHiddenInGame

    local EffectId = self.ModelHero:GetSelectedDisplayBoardEffectId(self.HeroId)
    self:SetChooseBoradData(EffectId)
    
    self:UpdateEffectListShow()
    self:UpdateButtonStateByChoose()

    --检测配置是否能被展示
    self:CheckIsShowFlag(self.ChooseBoardId)
end

function EffectChooseLogic:OnManualShow(param)
    -- CError("---------------------- OnManualShow")
    self:OnShow(param)
end

function EffectChooseLogic:OnManualHide(param)
    -- self:OnHide()
end

function EffectChooseLogic:OnHide()
end

function EffectChooseLogic:OnShowAvator(Data,IsNotVirtualTrigger) 
    -- CError("---------------------- OnShowAvator,IsNotVirtualTrigger ="..tostring(IsNotVirtualTrigger))
    if IsNotVirtualTrigger then
        if self.RequestAvatarHiddenInGame then
            local param = {bHide = false,bReShowDisplayBoard = false}
            self.RequestAvatarHiddenInGame(param)
        end
    end
end

function EffectChooseLogic:OnHideAvator(Data,IsNotVirtualTrigger) 
    -- CError("---------------------- OnHideAvator,IsNotVirtualTrigger ="..tostring(IsNotVirtualTrigger))
end

---检测配置是否能被展示
function EffectChooseLogic:CheckIsShowFlag(BoardId)
    BoardId = BoardId or 0
    if BoardId <= 0  then
        return
    end

    local bCanShow = false
    for k, DataCfg in pairs(self.DataList) do
        if DataCfg[Cfg_HeroDisplayEffect_P.Id] == BoardId then
            bCanShow = true
            break
        end
    end
    if not bCanShow then
        if UE.UGFUnluaHelper.IsEditor() then
            UIAlert.Show(string.format("检测配置 BoardId=[%s] 不能展示给玩家!!!", tostring(BoardId)))
        end
       
        CError(string.format("EffectChooseLogic:CheckIsShowFlag, 检测配置 BoardId=[%s] 不能展示给玩家!!!",tostring(BoardId)))
    end
end

function EffectChooseLogic:SetChooseBoradData(EffectId)
    self.ChooseBoardId = EffectId
    if self.OnChooseBoradItem then
        local Param = {TabId = self.TabId, BoradId = self.ChooseBoardId}
        self.OnChooseBoradItem(Param)
    end
end

----------------------------------------------list >>

function EffectChooseLogic:UpdateEffectListShow()
    -- self.Id2Item = {}
    self.CurSelectItem = nil

    self.DataList = self:GetValidDisplayBoardData(self.HeroId)
    self:SortDisplayBoardData(self.DataList)

    self.DataListSize = #self.DataList
	self.View.WBP_ReuseList_Effect:Reload(#self.DataList)
end

---获取有效的贴纸数据
function EffectChooseLogic:GetValidDisplayBoardData(HeroId)
    local ListData = {}

    local Dict = G_ConfigHelper:GetDict(Cfg_HeroDisplayEffect)
    for k, Cfg in pairs(Dict) do
        if(Cfg[Cfg_HeroDisplayEffect_P.HeroId] == 0 or Cfg[Cfg_HeroDisplayEffect_P.HeroId] == HeroId) and Cfg[Cfg_HeroDisplayEffect_P.ShowFlag] then
            table.insert(ListData, Cfg)
        end
    end

    return ListData
end



---排序
function EffectChooseLogic:SortDisplayBoardData(ListData)
    if ListData == nil or next(ListData) == nil then
        return
    end

    local SortFunc = function (ItemA,ItemB)
        local IdA = ItemA[Cfg_HeroDisplayEffect_P.Id]
        local IdB = ItemB[Cfg_HeroDisplayEffect_P.Id]
        --是否装备排序
        local IsEquipedA = self.ModelHero:HasDisplayBoardEffectIdSelected(self.HeroId, IdA) and 1 or 0
        local IsEquipedB = self.ModelHero:HasDisplayBoardEffectIdSelected(self.HeroId, IdB) and 1 or 0
        if IsEquipedA ~= IsEquipedB then
            return IsEquipedA > IsEquipedB
        end

        local ItemIdA = ItemA[Cfg_HeroDisplayEffect_P.ItemId]
        local ItemIdB = ItemB[Cfg_HeroDisplayEffect_P.ItemId]
        
        --是否拥有排序
        local HasSortA = self.ModelDepot:GetItemCountByItemId(ItemIdA) > 0 and 1 or 0
        local HasSortB = self.ModelDepot:GetItemCountByItemId(ItemIdB) > 0 and 1 or 0
        if HasSortA ~= HasSortB then
            return HasSortA > HasSortB
        end

        --排序权重:越大越靠前
        if ItemA[Cfg_HeroDisplayEffect_P.SortWeight] ~= ItemB[Cfg_HeroDisplayEffect_P.SortWeight] then
            return ItemA[Cfg_HeroDisplayEffect_P.SortWeight] > ItemB[Cfg_HeroDisplayEffect_P.SortWeight]
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

function EffectChooseLogic:CreateItem(Widget, IconParam)
	local Item = self.Widget2Item[Widget]
	if not Item then
		-- Item = UIHandler.New(self, Widget, require("Client.Modules.Hero.HeroDetail.DisplayBoard.CommonChooseListItem"))
        Item = UIHandler.New(self, Widget, CommonItemIcon, IconParam)
		self.Widget2Item[Widget] = Item
	end
	return Item.ViewInstance
end

function EffectChooseLogic:OnUpdateItem(Handler,Widget, Index)
	local FixIndex = Index + 1
	local ConfigData = self.DataList[FixIndex]
	if ConfigData == nil then
		return
	end

	local TargetItem = self:CreateItem(Widget)
	if TargetItem == nil then
		return
	end
    local EffectId = ConfigData[Cfg_HeroDisplayEffect_P.Id]
    local ItemId = ConfigData[Cfg_HeroDisplayEffect_P.ItemId]
    -- local CornerTagInfo = self:GetCornerTagInfo(EffectId)
    local RetVal = MvcEntry:GetCtrl(HeroCtrl):GetCornerTagParam(self.TabId, self.HeroId, EffectId)
    ---@type CornerTagParam
    local CornerTagInfo = RetVal.TagParam
    -- local param = {
    --     HeroId = self.HeroId,
    --     DisplayBoardId = EffectId,
    --     DisplayBoardTabID = EHeroDisplayBoardTabID.Effect.TabId,
    --     Index = FixIndex,
    --     ClickFunc = Bind(self, self.OnEffectIdItemClick, ConfigData, TargetItem),
    -- }

    local IconParam = {
        IconType = CommonItemIcon.ICON_TYPE.PROP,
        ItemId = ItemId,
        ClickCallBackFunc = Bind(self, self.OnEffectIdItemClick, ConfigData, TargetItem),
        -- ClickMethod = UE.EButtonClickMethod.DownAndUp,
        -- HoverFuncType = CommonItemIcon.HOVER_FUNC_TYPE.TIP,
        ShowItemName = false,

        RightCornerTagId = CornerTagInfo.TagId,
        RightCornerTagHeroId = CornerTagInfo.TagHeroId,
        RightCornerTagHeroSkinId = CornerTagInfo.TagHeroSkinId,
        IsLock = CornerTagInfo.IsLock,
        IsGot = CornerTagInfo.IsGot,
        IsOutOfDate = CornerTagInfo.IsOutOfDate,
        RedDotKey = "HeroDisplayBoardEffectItem_",
        RedDotSuffix = EffectId,
        RedDotInteractType = CommonConst.RED_DOT_INTERACT_TYPE.CLICK,
    }

	TargetItem:UpdateUI(IconParam)
    -- self.Id2Item[EffectId] = TargetItem
    -- self.ItemIns2Id[TargetItem] = EffectId
    
    if EffectId == self.ChooseBoardId then
        TargetItem:SetIsSelect(true)
        self.CurSelectItem = TargetItem
    else
        TargetItem:SetIsSelect(false)
    end
end

-- local Params = {
--     Icon = self.View,
--     ItemId = self.IconParams.ItemId,
-- }
-- function EffectChooseLogic:OnEffectIdItemClick(ConfigData, ItemView, FixIndex)
function EffectChooseLogic:OnEffectIdItemClick(ConfigData, ItemView, Params)
    if ConfigData[Cfg_HeroDisplayEffect_P.Id] == self.ChooseBoardId then
        return
    end
    self:SetChooseBoradData(ConfigData[Cfg_HeroDisplayEffect_P.Id])

    if self.CurSelectItem then
		self.CurSelectItem:SetIsSelect(false)
	end
    if ItemView then
        self.CurSelectItem = ItemView
        self.CurSelectItem:SetIsSelect(true)
    end

    self:Update3DEffectShow()
    self:UpdateButtonStateByChoose()
end

function EffectChooseLogic:Update3DEffectShow()
    local Param = {
        DisplayId = self.HeroId,
        EffectId = self.ChooseBoardId
    }
    self.ModelHero:DispatchType(HeroModel.ON_HERO_DISPLAYBOARD_EFFECT_CHANGE, Param)
end

----------------------------------------------list <<

----------------------------------------------btn >>

-- function EffectChooseLogic:ActiveButtonStateByChoose(ActiveBtn)
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
--         if BtnWidget == ActiveBtn then
--             BtnWidget:Setvisibility(UE.ESlateVisibility.Visible)
--         else
--             BtnWidget:Setvisibility(UE.ESlateVisibility.Collapsed)
--         end
--     end
-- end

function EffectChooseLogic:UpdateButtonStateByChoose()
    self.View.WidgetSwitcher:SetVisibility(self.ChooseBoardId == 0 and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)
    local TblEffect = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayEffect, self.ChooseBoardId) 
    if TblEffect == nil then
        return
    end

    local ItemId = TblEffect[Cfg_HeroDisplayEffect_P.ItemId]

    local IsLock = not(self.ModelHero:HasDisplayBoardEffect(self.ChooseBoardId)) 
    if IsLock then
        local UnlockFlag = TblEffect[Cfg_HeroDisplayEffect_P.UnlockFlag]
        local AvailableFlag = TblEffect[Cfg_HeroDisplayEffect_P.AvailableFlag]
        if AvailableFlag then
            local JumpIDs = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(ItemId)
            if UnlockFlag then
                if self.UnlockBtnIns and self.UnlockBtnIns:IsValid() then
                    local UnlockItemId = TblEffect[Cfg_HeroDisplayEffect_P.UnlockItemId]
                    local UnlockItemNum = TblEffect[Cfg_HeroDisplayEffect_P.UnlockItemNum]
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
            -- 活动结束
            self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonNoAvailable)  
        end
    else
        local SelectedEffectId = self.ModelHero:GetSelectedDisplayBoardEffectId(self.HeroId)
        if SelectedEffectId == self.ChooseBoardId then
            self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonAlreadyEqupped)
        else
            self.View.WidgetSwitcher:SetActiveWidget(self.View.GUIButtonEquip)
        end
    end
end


function EffectChooseLogic:OnClicked_GUIButtonEquip()
    self.IsLock = not (self.ModelHero:CheckGotHeroById(self.HeroId))
    if self.IsLock then
        UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Hero","Lua_HeroDisplayBoard_PleaseUnlockHero")) --请先解锁先觉者
        return
    end
        
    MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerSelectEffectReq(self.HeroId, self.ChooseBoardId)
end

function EffectChooseLogic:OnClicked_GUIButtonAlreadyEqupped()

end

function EffectChooseLogic:OnClicked_GUIButtonNoAvailable()
    UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_Theactivityhasended"))--活动已结束
end

function EffectChooseLogic:OnClicked_GUIButtonFetch()
   --前往跳转?
   local tblCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroDisplayEffect, Cfg_HeroDisplayEffect_P.Id, self.ChooseBoardId)
   if tblCfg == nil then
       --TODO:跳转失败
       UIAlert.Show(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_StickerChooseLogic_Theactivityhasended")) -- 活动已结束
       return
   end

   local JumpIDs = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(tblCfg[Cfg_HeroDisplayEffect_P.ItemId])
   if JumpIDs then
       MvcEntry:GetCtrl(ViewJumpCtrl):JumpToByTArrayList(JumpIDs)    
   end
end

function EffectChooseLogic:OnClicked_GUIButtonBuy()
    
    local TblEffect = G_ConfigHelper:GetSingleItemById(Cfg_HeroDisplayEffect, self.ChooseBoardId) 
    if TblEffect == nil then
        return
    end

    -- local ItemId = TblEffect[Cfg_HeroDisplayEffect_P.ItemId]
    local UnlockItemId = TblEffect[Cfg_HeroDisplayEffect_P.UnlockItemId]
    local UnlockItemNum = TblEffect[Cfg_HeroDisplayEffect_P.UnlockItemNum]
    -- local UnlockFlag = TblEffect[Cfg_HeroDisplayEffect_P.UnlockFlag]
    -- local AvailableFlag = TblEffect[Cfg_HeroDisplayEffect_P.AvailableFlag]
    
    local ItemName = self.ModelDepot:GetItemName(UnlockItemId)
    local Cost = UnlockItemNum
	local Balance = self.ModelDepot:GetItemCountByItemId(UnlockItemId)
	if Balance < Cost then
		local msgParam = {
			describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_EffectChooseLogic_isnotenoughtobuy"),ItemName),
		}
		UIMessageBox.Show(msgParam)
		return
	end
	local msgParam = {
		-- describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_EffectChooseLogic_Areyousureyouwanttob"), Cost,ItemName),
        describe = CommonUtil.GetBuyCostDescribeText(UnlockItemId, Cost), --确定要花 {0}{1} 购买吗？
		leftBtnInfo = {},
		rightBtnInfo = {
			callback = function()
				MvcEntry:GetCtrl(HeroCtrl):SendProto_PlayerBuyEffectReq(self.ChooseBoardId)
			end
		}
	}
	UIMessageBox.Show(msgParam)
end

----------------------------------------------btn <<

----------------------------------------------server >>

function EffectChooseLogic:ON_HERO_DISPLAYBOARD_EFFECT_SELECT_Func()
    self:Update3DEffectShow()
    self:UpdateButtonStateByChoose()
    self.View.WBP_ReuseList_Effect:Refresh()
end

function EffectChooseLogic:ON_HERO_DISPLAYBOARD_BUY_Func(_, EffectId)
    if EffectId == self.ChooseBoardId then
        self:OnClicked_GUIButtonEquip()
    else
        self:UpdateButtonStateByChoose()
        self.View.WBP_ReuseList_Effect:Refresh()
    end
end

function EffectChooseLogic:ON_UPDATED_MAP_CUSTOM_Func(_,ChangeMap)
    self:UpdateButtonStateByChoose()
    self.View.WBP_ReuseList_Effect:Refresh()
end

----------------------------------------------server >>

return EffectChooseLogic
