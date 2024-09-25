--[[
    角色详情界面
]] local class_name = "HeroSuitSkinDetailPanelMdt"

HeroSuitSkinDetailPanelMdt = HeroSuitSkinDetailPanelMdt or BaseClass(GameMediator, class_name)

function HeroSuitSkinDetailPanelMdt:__init()
end

function HeroSuitSkinDetailPanelMdt:OnShow(data)
end

function HeroSuitSkinDetailPanelMdt:OnHide()
end

-------------------------------------------------------------------------------

local M = Class("Client.Mvc.UserWidgetBase")

function M:OnInit()
    self.MsgList = {
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_SKIN_PART_SELECT, Func = Bind(self, self.OnSkinPartSelect)},
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_SKIN_PART_EQUIP, Func = Bind(self, self.UpdateSkinStateShow)},
        -- {Model = InputModel, MsgName = ActionPressed_Event(ActionMappings.SpaceBar), Func = self.OnSpaceBarClick },
        {Model = DepotModel, MsgName = ListModel.ON_UPDATED_MAP_CUSTOM, Func = self.ON_ITEM_UPDATED_MAP_CUSTOM_Func},
    }
    self.BindNodes = {
        -- {UDelegate = self.GUIButtonEquip.GUIButton_Tips.OnClicked, Func = Bind(self, self.OnClicked_GUIButtonEquip)}
    }

    UIHandler.New(
        self,
        self.CommonBtnTips_ESC,
        WCommonBtnTips,
        {
            OnItemClick = Bind(self, self.OnEscClicked),
            CommonTipsID = CommonConst.CT_ESC,
            ActionMappingKey = ActionMappings.Escape,
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Second
        }
    )
    self.UnlockBtn =
        UIHandler.New(
        self,
        self.WBP_HeroBuyButton,
        WCommonBtnTips,
        {
            OnItemClick = Bind(self, self.OnClicked_GUIButtonBuy),
            CommonTipsID = CommonConst.CT_SPACE,
            ActionMappingKey = ActionMappings.SpaceBar,
            TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HeroSkinDetailLogic_buy"),
            HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
            CheckButtonIsVisible = true
        }
    ).ViewInstance
    
    UIHandler.New(self, self.GUIButtonEquip, WCommonBtnTips,
    {
        OnItemClick = Bind(self, self.OnClicked_GUIButtonEquip),
        CommonTipsID = CommonConst.CT_SPACE,
        ActionMappingKey = ActionMappings.SpaceBar,
        TipStr = G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HeroSkinDetailLogic_equipment_Btn"),
        HoverFontStyleType = WCommonBtnTips.HoverFontStyleType.Main,
        CheckButtonIsVisible = true
    })
end

--[[
    皮肤装备按钮点击
]]
function M:OnClicked_GUIButtonEquip()
    if self.GUIButtonEquip:GetVisibility() == UE.ESlateVisibility.Collapsed then
        return
    end

    local FavoriteSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(self.HeroId)
    local CfgParts = G_ConfigHelper:GetMultiItemsByKeys(Cfg_HeroSkin,{Cfg_HeroSkin_P.HeroId, Cfg_HeroSkin_P.SuitID},{self.HeroId, self.SuitId})
    local Found = false
    local DefaultSkinId
    for _, v in pairs(CfgParts) do
        if not DefaultSkinId then
            if MvcEntry:GetModel(HeroModel):IsUnLockSkinId(v[Cfg_HeroSkin_P.SkinId]) then
                DefaultSkinId = v[Cfg_HeroSkin_P.SkinId]
            end
        end
        if v[Cfg_HeroSkin_P.SkinId] == FavoriteSkinId then
            Found = true
            break
        end
    end
    if not Found and DefaultSkinId then
        MvcEntry:GetCtrl(HeroCtrl):SendProto_SelectHeroSkinReq(self.HeroId, DefaultSkinId)
    end

    if MvcEntry:GetModel(HeroModel):GetCurSkinSelectBySuitId(self.SuitId) > 0 then
        MvcEntry:GetCtrl(HeroCtrl):SelectHeroSkinDefaultPartReq(0, self.SuitId)
    end

    local TempList = self:GetShowPartList()
    MvcEntry:GetCtrl(HeroCtrl):EquipSuitPartReq(self.HeroId, TempList)
end

function M:OnSpaceBarClick()
    if self.WidgetSwitcherOwnStatus:GetActiveWidgetIndex() == 2 then
        self:OnClicked_GUIButtonBuy()
    elseif self.WidgetSwitcherOwnStatus:GetActiveWidgetIndex() == 0 then
        self:OnClicked_GUIButtonEquip()
    end
end

function M:OnClicked_GUIButtonBuy()
    if self.WBP_HeroBuyButton:GetVisibility() == UE.ESlateVisibility.Collapsed then
        return
    end

    local Cfgs = G_ConfigHelper:GetMultiItemsByKeys(Cfg_HeroSkin, {Cfg_HeroSkin_P.HeroId,Cfg_HeroSkin_P.SuitID}, {self.HeroId,self.SuitId})

    if not Cfgs then
        return
    end

    local Found = false
    for _, v in pairs(Cfgs) do
        local IsLock = false
        if v[Cfg_HeroSkin_P.ItemId] > 0 then
            IsLock = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(v[Cfg_HeroSkin_P.ItemId]) <= 0
        end
        if not IsLock then
            Found = true
            break
        end
    end
    if not Found then
        UIAlert.Show(StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST("SD_Hero", tostring(1584))))
        return
    end

    CWaring("self.UnlockItemId:" .. self.UnlockItemId)
    if self.UnlockItemId <= 0 then
        return
    end
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
		describe = StringUtil.Format(G_ConfigHelper:GetStrFromOutgameStaticST('SD_Hero', "Lua_HeroSkinDetailLogic_Areyousureyouwanttob"), Cost,ItemName),
		leftBtnInfo = {},
		rightBtnInfo = {
			callback = function()
				MvcEntry:GetCtrl(HeroCtrl):BuySuitPartReq(self.SkinPartId)
			end
		}
	}
	UIMessageBox.Show(msgParam)
end

function M:OnSkinPartSelect(_, Param)
    self.SkinPartId = Param.SkinPartId
    self:UpdateSkinStateShow()

    local TempList = self:GetShowPartList(true)

    if self.CurShowAvatar then
        self.CurShowAvatar:AttachAvatarByIDs(TempList)
    end
end

function M:GetShowPartList(IsPreview)
    local SelectCfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkinPart, Cfg_HeroSkinPart_P.PartId, self.SkinPartId)
    local PreviewPartList = MvcEntry:GetModel(HeroModel):GetSkinSuitEquipPartIdList(self.SuitId, IsPreview)
    local TempList = {}
    if PreviewPartList then
        for _, v in ipairs(PreviewPartList) do
            local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkinPart, Cfg_HeroSkinPart_P.PartId, v)
            if Cfg[Cfg_HeroSkinPart_P.PartType] == SelectCfg[Cfg_HeroSkinPart_P.PartType] then
                table.insert(TempList, self.SkinPartId)
            else
                table.insert(TempList, v)
            end
        end
    end
    return TempList
end

function M:ON_ITEM_UPDATED_MAP_CUSTOM_Func()
    self:UpdateSkinStateShow()
end

function M:UpdateSkinStateShow()
    local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkinPart, Cfg_HeroSkinPart_P.PartId, self.SkinPartId)
    if not Cfg then
        return
    end
    self.UnlockItemId = Cfg[Cfg_HeroSkinPart_P.UnlockItemId]
    self.UnlockItemNum = Cfg[Cfg_HeroSkinPart_P.UnlockItemNum]
    local JumpID = MvcEntry:GetCtrl(ViewJumpCtrl):GetItemCfgJumpIdByID(Cfg[Cfg_HeroSkinPart_P.ItemId])
    if self.UnlockBtn then
        self.UnlockBtn:ShowCurrency(Cfg[Cfg_HeroSkinPart_P.UnlockItemId], Cfg[Cfg_HeroSkinPart_P.UnlockItemNum], JumpID)
    end

    local ItemId = Cfg[Cfg_HeroSkinPart_P.ItemId]

    local isEquip = false
    local isUnLock = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(ItemId) > 0
    if isUnLock then
        isEquip = MvcEntry:GetModel(HeroModel):IsPartIdEquiped(self.SkinPartId)
    end

    self.WBP_HeroBuyButton:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible) 
    if not isUnLock and self.UnlockItemId <= 0 and (JumpID == nil or JumpID:Length() == 0) then
        self.WBP_HeroBuyButton:SetVisibility(UE.ESlateVisibility.Collapsed) 
    end

    -- 0:normal状态 1:已装备 2:购买
    self.WidgetSwitcherOwnStatus:SetActiveWidgetIndex(not isUnLock and 2 or (isEquip and 1 or 0))

    local Param = {
        HideBtnSearch = true,
        ItemID = self.SkinPartId,
    }
    if not self.CommonDescriptionCls then
        self.CommonDescriptionCls = UIHandler.New(self,self.View.WBP_Common_Description, CommonDescription, Param).ViewInstance
    else
        self.CommonDescriptionCls:UpdateUI(Param)
    end
end

function M:OnShow(Param)
    if not Param or not Param.SuitId then
        return
    end

    self.SuitId = Param.SuitId
    self.HeroId = Param.HeroId
    self.SkinId = Param.SkinId

    local CfgPartTypes = G_ConfigHelper:GetDict(Cfg_HeroSkinPartType)

    if not CfgPartTypes then
        return
    end

    local WidgetClass =
        UE4.UClass.Load(
        CommonUtil.FixBlueprintPathWithC(
            "/Game/BluePrints/UMG/OutsideGame/Hero/WBP_HeroSuitPartListItem.WBP_HeroSuitPartListItem"
        )
    )

    for i, v in ipairs(CfgPartTypes) do
        local CfgParts =
            G_ConfigHelper:GetMultiItemsByKeys(
            Cfg_HeroSkinPart,
            {Cfg_HeroSkinPart_P.PartType, Cfg_HeroSkinPart_P.SuitID},
            {v[Cfg_HeroSkinPartType_P.PartType], self.SuitId}
        )
        if CfgParts then
            local Widget = NewObject(WidgetClass, self)
            self.GUIVBSuitPartList:AddChild(Widget)

            if not self.SkinPartId then
                for _, PartCfg in ipairs(CfgParts) do
                    local PartId = PartCfg[Cfg_HeroSkinPart_P.PartId]
                    if not self.SkinPartId then
                        self.SkinPartId = PartId
                    end
                    if MvcEntry:GetModel(HeroModel):IsPartIdEquiped(PartId) then
                        self.SkinPartId = PartId
                        break
                    end
                end
            end

            local param = {
                PartType = v[Cfg_HeroSkinPartType_P.PartType],
                SuitId = self.SuitId,
                CurSelectId = self.SkinPartId
            }
            UIHandler.New(self, Widget, require("Client.Modules.Hero.Skin.HeroSkinSuitPartList"), param)
        end
    end

    self:UpdateSkinStateShow()
end

function M:OnHide()
end
-- function M:HandleSelectHeroSkin()
--     local Cfgs = G_ConfigHelper:GetMultiItemsByKey(Cfg_HeroSkin,Cfg_HeroSkin_P.SuitID, self.SuitId)
--     if not Cfgs then
--         return
--     end
--     if #Cfgs < 1 then
--         return
--     end
--     local DefaultCfg = Cfgs[1]
--     if DefaultCfg[Cfg_HeroSkin_P.SuitType] == Pb_Enum_HERO_SKIN_TYPE.HERO_SKIN_TYPE_PART then
--         local Unlock = false
--         for _, v in pairs(Cfgs) do
--             if MvcEntry:GetModel(DepotModel):GetItemCountByItemId(v[Cfg_HeroSkin_P.ItemId]) > 0 then
--                 Unlock = true
--                 break
--             end
--         end
--         if Unlock then
--             MvcEntry:GetCtrl(HeroCtrl):SelectHeroSkinDefaultPartReq(0, self.SuitId)
--         end
--     end
-- end

function M:OnEscClicked()
    MvcEntry:CloseView(self.viewId)
    return true
end

function M:OnShowAvator(Param, IsNotVirtualTrigger)
    self:UpdateAvatarShow()
end

function M:OnHideAvator(Param, IsNotVirtualTrigger)
    self:OnHideAvatorInner()
end

function M:UpdateAvatarShow(HeroId, SkinId)
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end

    if not self.HeroId or not self.SkinId then
        return
    end

    local SpawnHeroParam = {
        ViewID = ViewConst.HeroSuitSkinDetail,
        InstID = 0,
        HeroId = self.HeroId,
        SkinID = self.SkinId,
        Location = UE.FVector(0, 0, 0),
        Rotation = UE.FRotator(0, 0, 0)
    }

    self.CurShowAvatar = HallAvatarMgr:ShowAvatar(HallAvatarMgr.AVATAR_HERO, SpawnHeroParam)
    self.CurShowAvatar:OpenOrCloseCameraAction(false)
    self.CurShowAvatar:OpenOrCloseAvatorRotate(false)
end

function M:OnHideAvatorInner()
    local HallAvatarMgr = CommonUtil.GetHallAvatarMgr()
    if HallAvatarMgr == nil then
        return
    end
    HallAvatarMgr:HideAvatarByViewID(self.viewId)
end


return M
