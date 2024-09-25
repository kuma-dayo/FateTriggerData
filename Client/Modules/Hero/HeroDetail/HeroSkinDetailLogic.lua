--[[
    角色皮肤详情解耦逻辑
]]

---@class HeroSkinDetailLogic
local class_name = "HeroSkinDetailLogic"
local HeroSkinDetailLogic = BaseClass(UIHandlerViewBase, class_name)

function HeroSkinDetailLogic:OnInit()
    -- 开启InputFocus避免隐藏Tab页时仍监听输入
    self.InputFocus = true
    self.BindNodes = 
    {
		-- { UDelegate = self.View.GUIButtonEquip.OnClicked,				    Func = Bind(self,self.OnClicked_GUIButtonEquip) },
		{ UDelegate = self.View.GUIButtonEquip.OnClicked,				    Func = Bind(self,self.OnClicked_GUIButtonEquip) },
		{ UDelegate = self.View.WBP_CommonBtn_Cir_Small.GUIButton_Main.OnClicked,				    Func = Bind(self,self.OnClicked_GUIButtonSuitEquip) },
		{ UDelegate = self.View.WBP_ReuseList.OnUpdateItem,				    Func = Bind(self,self.OnUpdateItem) },
		{ UDelegate = self.View.WBP_SuitList.OnUpdateItem,				    Func = Bind(self,self.OnUpdateSuitItem) },
	}
    self.MsgList = 
    {
		{Model = DepotModel, MsgName = ListModel.ON_UPDATED_MAP_CUSTOM, Func = self.ON_ITEM_UPDATED_MAP_CUSTOM_Func },
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_LIKE_SKIN_CHANGE, Func = self.ON_HERO_LIKE_SKIN_CHANGE_Func },
        {Model = HeroModel,  MsgName = HeroModel.ON_HERO_SKIN_SUIT_SELECT,	           Func = Bind(self, self.UpdateBtnState) },   
        {Model = HeroModel,  MsgName = HeroModel.ON_HERO_SKIN_SUIT_SUBITEM_SELECT,	           Func = Bind(self, self.UpdateSubBtnState) },   
        {Model = HeroModel,  MsgName = HeroModel.HERO_SKIN_DEFAULT_PART_CHANGE,	           Func = Bind(self, self.HERO_SKIN_DEFAULT_PART_CHANGE) },   
        {Model = ActivityModel, MsgName = ActivityModel.ACTIVITY_ACTIVITYLIST_CHANGE, Func = Bind(self, self.ACTIVITY_ACTIVITYLIST_CHANGE_FUNC)},
	}

    self.Widget2Item = {}
    self.SuitWidget2Item = {}

    -- local Param = 
    -- {
    --     --道具图标
    --     ItemId = 0,
    --     --Icon控件
    --     IconWidget = self.View.GUIImageMoney,
    --     --文本控件（显示数量）
    --     LabelWidget = self.View.GUITBCost,
    --     CheckEnough = true,
    -- }
    -- self.CurrencyTipInstance = UIHandler.New(self,self.Handler, CommonCurrencyTip,Param).ViewInstance

    self.ModelHero = MvcEntry:GetModel(HeroModel)
    self.ModelDepot = MvcEntry:GetModel(DepotModel)

    
    -- 皮肤购买按钮
    self.UnlockBtn = UIHandler.New(self, self.View.WBP_HeroBuyButton, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnClicked_GUIButtonBuy),
        CommonTipsID = CommonConst.CT_SPACE,
        ActionMappingKey = ActionMappings.SpaceBar,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HeroSkinDetailLogic_buy"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    }).ViewInstance

    -- 装备按钮
    UIHandler.New(self, self.View.GUIButtonEquip, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnClicked_GUIButtonEquip),
        CommonTipsID = CommonConst.CT_SPACE,
        ActionMappingKey = ActionMappings.SpaceBar,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HeroSkinDetailLogic_equipment_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
    })
end


--[[
    local Param = {
        HeroId = self.HeroId
    }
]]
function HeroSkinDetailLogic:OnShow(Param)
    if not Param then
        return
    end
    self.Param = Param
    self.HeroId = self.Param.HeroId
    self.SkinId = self.ModelHero:GetFavoriteSkinIdByHeroId(self.HeroId)
    self.CurSelectSkinId = 0
    self:UpdateSkinListShow();
    self:UpdateSkinShow()
end

function HeroSkinDetailLogic:OnManualShow(Param)
    if not Param then
        return
    end
    self.Param = Param
    self.HeroId = self.Param.HeroId
    self.SkinId = self.ModelHero:GetFavoriteSkinIdByHeroId(self.HeroId)
    self.CurSelectSkinId = 0
    self:UpdateSkinListShow();
    self:UpdateSkinShow()
end

function HeroSkinDetailLogic:UpdateUI(Param)
    if not Param then
        return
    end
    self.Param = Param
    self.HeroId = self.Param.HeroId
    self.SkinId = self.ModelHero:GetFavoriteSkinIdByHeroId(self.HeroId)
    self.CurSelectSkinId = 0
    self:UpdateSkinListShow();
    self:UpdateSkinShow()
    --快速切换英雄后重置Item选中状态
    for _, Item in pairs(self.Id2Item) do
        Item:OnManualShow()
    end
end

function HeroSkinDetailLogic:OnHide()
end

function HeroSkinDetailLogic:OnShowAvator(Param,IsInit, IsSwitch, IsQuickSwitch)
    local NeedShowHeroId = self.HeroId
    local SkinId = self.SkinId

    local CustomPartList = self:GetCurShowPartList()
    self.WidgetBase:UpdateAvatarShow(NeedShowHeroId,SkinId,true, CustomPartList, IsSwitch, IsQuickSwitch)
end


function HeroSkinDetailLogic:GetCurShowPartList()
    local CustomPartList = {}
    if self.CurSelectSkinId == 0 then
        local _, PartList = MvcEntry:GetModel(HeroModel):GetCurSkinSelect(self.SkinId)
        CustomPartList = PartList
    else
        local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.SkinId, self.CurSelectSkinId)
        if Cfg[Cfg_HeroSkin_P.SuitType] == Pb_Enum_HERO_SKIN_TYPE.HERO_SKIN_TYPE_PART  then
            for _, v in pairs(Cfg[Cfg_HeroSkin_P.SuitPartList]) do
                table.insert(CustomPartList, v)
            end
        end
    end
    return CustomPartList
end

function HeroSkinDetailLogic:UpdateSkinListShow()
    self.Id2Item = {}
    --self.Id2DataIndex = {}
    self.CurSelectItem = nil
    self.DataList = MvcEntry:GetModel(HeroModel):GetHeroSkinList(self.HeroId)
    table.sort(self.DataList,function (A,B)
        if #A == 0 or #B == 0 then
            return
        end

        local IsEquipedA = table.contains(A,self.SkinId) and 1 or 0
        local IsEquipedB = table.contains(B,self.SkinId) and 1 or 0
        if IsEquipedA ~= IsEquipedB then
            return IsEquipedA > IsEquipedB
        end

        local SkinConfigA = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,A[1])
        local SkinConfigB = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,B[1])

        local TheItemIdA = SkinConfigA[Cfg_HeroConfig_P.ItemId]
        local TheItemIdB = SkinConfigB[Cfg_HeroConfig_P.ItemId]
        local TheItemIdACount = self.ModelDepot:GetItemCountByItemId(TheItemIdA)
        local TheItemIdBCount = self.ModelDepot:GetItemCountByItemId(TheItemIdB)
        if TheItemIdACount ~= TheItemIdBCount then
            return TheItemIdACount > TheItemIdBCount
        end

        if SkinConfigA[Cfg_HeroSkin_P.SuitType] ~= 0 or SkinConfigB[Cfg_HeroSkin_P.SuitType] ~= 0 then
            return SkinConfigA[Cfg_HeroSkin_P.SuitType] > SkinConfigB[Cfg_HeroSkin_P.SuitType]
        end

        local TheItemIdACfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,TheItemIdA)
        local TheItemIdBCfg = G_ConfigHelper:GetSingleItemById(Cfg_ItemConfig,TheItemIdB)
        if TheItemIdACfg[Cfg_ItemConfig_P.Quality] ~= TheItemIdBCfg[Cfg_ItemConfig_P.Quality] then
            return TheItemIdACfg[Cfg_ItemConfig_P.Quality] > TheItemIdBCfg[Cfg_ItemConfig_P.Quality]
        end
        return SkinConfigA[Cfg_HeroConfig_P.SkinId] > SkinConfigB[Cfg_HeroConfig_P.SkinId]
    end)
    local CurShowIndex = 1
    local index = 1
    local found = false
    for _,v in pairs(self.DataList) do
        for _, dv in ipairs(v) do
            if self.SkinId == dv then
                found = true
                break
            end
        end
        if found then
            CurShowIndex = index
            self.SkinIDArr = v
            break
        end
        index = index + 1
    end

    self.DataListSize = #self.DataList
	self.View.WBP_ReuseList:Reload(#self.DataList)
    
    if not self.ListWASDControl then
        local Param = {
            --列表数量（从1开始计数）
            DataListSize = self.DataListSize,
            --当前开始Index值
            CurShowIndex = CurShowIndex,
            --是否垂直朝向
            IsVertical = true,
            --多少列 IsVertical为true生效  ColNum 为nil值或者 <=1, 只会响应 WS 及 上下按键
            ColNum = 2,
            --操作回调，参数为列表的Index值 ，表示操作后需要展示的目标 Index
            Callback = Bind(self,self.OnListWASDControlCallBack)
        }
        self.ListWASDControl = UIHandler.New(self,self.View,CommonListWASDControl,Param).ViewInstance
    else
        local Param = {
            --列表数量（从1开始计数）
            DataListSize = self.DataListSize,
            --当前开始Index值
            CurShowIndex = CurShowIndex,
        }
        self.ListWASDControl:UpdateParam(Param)
    end
end

function HeroSkinDetailLogic:OnListWASDControlCallBack(ShowIndex)
    --print_trackback()
    self.View.WBP_ReuseList:JumpByIdx(ShowIndex)

    local SkinIDArr = self.DataList[ShowIndex]
    local SkinID = SkinIDArr[1]
    local Item = self.Id2Item[SkinID]
    if Item then
        Item:OnClicked_BtnClick()
    end
end

function HeroSkinDetailLogic:OnUpdateItem(Handler,Widget, Index)
	local FixIndex = Index + 1
	local SkinIDArr = self.DataList[FixIndex]
	if SkinIDArr == nil then
		return
	end

	local TargetItem = self:CreateItem(Widget)
	if TargetItem == nil then
		return
	end
    local SkinId = SkinIDArr[1]
    local param = {
        CurSkinId = self.SkinId,
        SkinIDArr = SkinIDArr,
        SkinId = SkinId,
        HeroId = self.HeroId,
        Index = FixIndex,
    }
	TargetItem:SetData(param)
    self.Id2Item[SkinId] = TargetItem
    --self.Id2DataIndex[SkinId] = FixIndex
    if SkinId == self.SkinId then
        self.CurSelectItem = TargetItem
    end
end

function HeroSkinDetailLogic:CreateItem(Widget)
	local Item = self.Widget2Item[Widget]
	if not Item then
		Item = UIHandler.New(self,Widget,require("Client.Modules.Hero.Skin.HeroSkinListItem"))
		self.Widget2Item[Widget] = Item
	end
	return Item.ViewInstance
end

function HeroSkinDetailLogic:OnSkinItemClick(SkinId,Item,SkinIDArr)
    if SkinId == self.SkinId then
        return
    end
    self.SkinIDArr = SkinIDArr
    self.SkinId = SkinId
    if Item then
        self.CurSelectItem = Item
        if self.CurSelectItem.RedDot then self.CurSelectItem.RedDot:Interact() end
    end

    self:UpdateSkinShow()
    self:OnShowAvator(nil, nil , true)
end

function HeroSkinDetailLogic:UpdateSkinShow()
    local CfgHeroSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,self.SkinId)

    if CfgHeroSkin[Cfg_HeroSkin_P.SuitType] == 0 then
        self.View.SuitPartPanel:SetVisibility(UE.ESlateVisibility.Collapsed)
    else
        self.View.SuitPartPanel:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        if CfgHeroSkin[Cfg_HeroSkin_P.SuitType] == 1 then
            self.View.MoreBtn:SetVisibility(UE.ESlateVisibility.Collapsed)
        else
            self.View.MoreBtn:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        end
        self.View.WidgetSwitcher_Bg:SetActiveWidgetIndex(CfgHeroSkin[Cfg_HeroSkin_P.SuitType] == 1 and 0 or 1)
        if self.SkinIDArr then
            self.View.WBP_SuitList:Reload(#self.SkinIDArr)
        end
    end
   
    -- self:OnShowAvator()
    local Param = {
        HideBtnSearch = true,
        ItemID = self.SkinId,
    }
    if not self.CommonDescriptionCls then
        self.CommonDescriptionCls = UIHandler.New(self,self.View.WBP_Common_Description, CommonDescription, Param).ViewInstance
    else
        self.CommonDescriptionCls:UpdateUI(Param)
    end

    self:UpdateSkinStateShow()

end

function HeroSkinDetailLogic:UpdateSkinStateShow()
    local TblSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,self.SkinId) 
    self.ItemIdOfSkin = TblSkin[Cfg_HeroSkin_P.ItemId]
    self.UnlockItemId = TblSkin[Cfg_HeroSkin_P.UnlockItemId]
    self.UnlockItemNum = TblSkin[Cfg_HeroSkin_P.UnlockItemNum]
    --CWaring("self.UnlockItemNum:" .. self.UnlockItemNum)
    --CWaring("self.UnlockItemId:" .. self.UnlockItemId)
    -- self.CurrencyTipInstance:UpdateItemId(self.UnlockItemId,self.UnlockItemNum)
    -- 货币展示放到按钮中做
    if self.UnlockBtn then
        local JumpID = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(self.ItemIdOfSkin)
        self.UnlockBtn:ShowCurrency(self.UnlockItemId, self.UnlockItemNum, JumpID)
        self.UnlockBtn:SetBtnEnabled(TblSkin[Cfg_HeroSkin_P.IsCanUnlock] and true or false, "", true)
    end
    local IsLock = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(self.ItemIdOfSkin) <= 0

    self.View.WidgetSwitcherOwnStatus:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    if IsLock then
        self.View.WidgetSwitcherOwnStatus:SetActiveWidget(self.View.NeedBuy)
    else
        self:UpdateSmallBtn()
        local FavoriteSkinId = MvcEntry:GetModel(HeroModel):GetSuitFavoriteSkinIdByHeroId(self.HeroId)
        if FavoriteSkinId == self.SkinId then
            self.View.WidgetSwitcherOwnStatus:SetActiveWidget(self.View.AlreadyEqupped)
        else
            self.View.WidgetSwitcherOwnStatus:SetActiveWidget(self.View.GUIButtonEquip)
        end
    end
end

--[[
    皮肤装备按钮点击
]]
function HeroSkinDetailLogic:OnClicked_GUIButtonEquip()
    -- UIAlert.Show("功能未开放")
    if not self.ModelHero:CheckGotHeroById(self.HeroId) then
        UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromSpecialStaticST("SD_SpecialText","Lua_Special_TwoParam"),
        G_ConfigHelper:GetStrFromCommonStaticST("Lua_CommonHallTab_personwithforesight_Btn"),
        G_ConfigHelper:GetStrFromOutgameStaticST("SD_Hero","Lua_AchieveChooseLogic_Notunlockedyet")))
        return
    end
    local CfgSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,self.SkinId)
    if CfgSkin and CfgSkin[Cfg_HeroSkin_P.SuitType] == Pb_Enum_HERO_SKIN_TYPE.HERO_SKIN_TYPE_PART  then
        MvcEntry:GetCtrl(HeroCtrl):SelectHeroSkinDefaultPartReq(self.SkinId, CfgSkin[Cfg_HeroSkin_P.SuitID])
    end

    MvcEntry:GetCtrl(HeroCtrl):SendProto_SelectHeroSkinReq(self.HeroId, self.SkinId)
end

--[[
    皮肤部件装备界面
]]
function HeroSkinDetailLogic:OnClicked_GUIButtonSuitEquip()
    local Cfg = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,self.SkinId)
    if not Cfg then
        return
    end
    MvcEntry:OpenView(ViewConst.HeroSuitSkinDetail,{
        HeroId = Cfg[Cfg_HeroSkin_P.HeroId],
        SkinId = Cfg[Cfg_HeroSkin_P.SkinId],
        SuitId = Cfg[Cfg_HeroSkin_P.SuitID]
    })
end

--[[
    皮肤购买
]]
function HeroSkinDetailLogic:OnClicked_GUIButtonBuy()
    CWaring("self.UnlockItemId:" .. self.UnlockItemId)
    local ItemName = MvcEntry:GetModel(DepotModel):GetItemName(self.UnlockItemId)
    local Cost = self.UnlockItemNum
	local Balance = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(self.UnlockItemId)
	if Balance < Cost then
		local msgParam = {
			describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HeroSkinDetailLogic_isnotenoughtobuy"),ItemName),
		}
		UIMessageBox.Show(msgParam)
		return
	end
	local msgParam = {
		-- describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Shop', "Lua_ShopCtrl_SureWantToBuy"), StringUtil.GetRichTextImgForId(self.UnlockItemId), Cost),
        describe = CommonUtil.GetBuyCostDescribeText(self.UnlockItemId, Cost), --确定要花 {0}{1} 购买吗？
		leftBtnInfo = {},
		rightBtnInfo = {
			callback = function()
				MvcEntry:GetCtrl(HeroCtrl):SendProto_BuyHeroSkinReq(self.HeroId, 
						self.SkinId)
			end
		}
	}
	UIMessageBox.Show(msgParam)
end

function HeroSkinDetailLogic:OnViewAllClicked()
    local SkinId = self.SkinId
    -- local SkinDataList = self.DataList
    local CustomPartList = self:GetCurShowPartList()
    local Param = {
        SkinId = SkinId,
        -- SkinDataList = SkinDataList,
        FromID = HeroDetailPanelMdt.MenTabKeyEnum.Skin,
        CustomPartList = CustomPartList
    }
    MvcEntry:OpenView(ViewConst.HeroPreView,Param)
end

function HeroSkinDetailLogic:ON_ITEM_UPDATED_MAP_CUSTOM_Func(ChangeMap)
    -- print_r(ChangeMap)
    if self.ItemIdOfSkin and ChangeMap[self.ItemIdOfSkin] then
        self:UpdateSkinStateShow()
    end
end

function HeroSkinDetailLogic:ON_HERO_LIKE_SKIN_CHANGE_Func()
    self.CurSelectSkinId = 0
    self:UpdateSkinStateShow()
end


function HeroSkinDetailLogic:OnUpdateSuitItem(Handler,Widget, Index)
	local FixIndex = Index + 1
	local SkinId = self.SkinIDArr[FixIndex]
	if SkinId == nil then
		return
	end

	local TargetItem = self:CreateSuitItem(Widget)
	if TargetItem == nil then
		return
	end
    local param = {
        SkinId = SkinId,
        HeroId = self.HeroId,
        SkinIDArr = self.SkinIDArr,
        Index = FixIndex,
    }
	TargetItem:SetData(param)
end

function HeroSkinDetailLogic:CreateSuitItem(Widget)
	local Item = self.SuitWidget2Item[Widget]
	if not Item then
		Item = UIHandler.New(self,Widget,require("Client.Modules.Hero.Skin.HeroSkinSuitListItem"))
		self.SuitWidget2Item[Widget] = Item
	end
	return Item.ViewInstance
end
 
function HeroSkinDetailLogic:UpdateBtnState(_, Param)
    local SkinId = Param.SkinId
    local SkinIDArr = Param.SkinIDArr
    local Item = Param.Item
    local CurSkinId = MvcEntry:GetModel(HeroModel):GetCurSkinSelect(SkinId)
    if SkinId == self.SkinId or SkinIDArr == self.SkinIDArr then
        return
    end
    self.CurSelectSkinId = CurSkinId
    self:OnSkinItemClick(SkinId, Item,SkinIDArr)
end
function HeroSkinDetailLogic:UpdateSubBtnState(_, Param)
    local SkinId = Param.SkinId
    local SkinIDArr = Param.SkinIDArr
    self.CurSelectSkinId = SkinId
    self:OnSkinItemClick(SkinId, nil, SkinIDArr)
end

function HeroSkinDetailLogic:HERO_SKIN_DEFAULT_PART_CHANGE()
    self.CurSelectSkinId = 0
    self.View.WidgetSwitcherOwnStatus:SetVisibility(UE.ESlateVisibility.Collapsed)
    self:UpdateSmallBtn()
end

function HeroSkinDetailLogic:UpdateSmallBtn()
    local FavoriteSkinId = MvcEntry:GetModel(HeroModel):GetCurSkinSelect(self.SkinId)
    -- self.View.WBP_CommonBtn_Small:SetWidgetState(FavoriteSkinId == 0)
end

function HeroSkinDetailLogic:ACTIVITY_ACTIVITYLIST_CHANGE_FUNC(_, ActivityIDList)
    if ActivityIDList then
        local JumpIDList = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(self.ItemIdOfSkin)
        for _, JumpID in pairs(JumpIDList) do
            local JumpCfg = G_ConfigHelper:GetSingleItemById(Cfg_JumpViewCfg,JumpID)
            local ViewParams = JumpCfg[Cfg_JumpViewCfg_P.ViewParams]
            local ParamsID = ViewParams ~= nil and ViewParams:Length() > 0 and ViewParams[1] or 0
            if JumpCfg and JumpCfg[Cfg_JumpViewCfg_P.JumpType] == ViewJumpCtrl.JumpTypeDefine.JumpActivity then
                for _, ActivityID in ipairs(ActivityIDList) do
                    if tonumber(ParamsID) == ActivityID then
                        self:UpdateSkinStateShow();
                        break
                    end
                end
            end
        end
    else
        self:UpdateSkinStateShow();
    end
end

return HeroSkinDetailLogic
