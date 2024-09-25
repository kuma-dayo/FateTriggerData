local class_name = "HeroSkinSuitPartListItem"
local HeroSkinSuitPartListItem = BaseClass(nil, class_name)

function HeroSkinSuitPartListItem:OnInit()
    self.MsgList = {
        {Model = DepotModel, MsgName = ListModel.ON_UPDATED_MAP_CUSTOM, Func = self.ON_ITEM_UPDATED_MAP_CUSTOM_Func},
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_SKIN_PART_SELECT, Func = Bind(self, self.OnSkinPartSelect)},
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_SKIN_PART_EQUIP, Func = Bind(self, self.HandlePartStateChange)}
    }
    self.BindNodes = {
        {UDelegate = self.View.HeroPartListbtn.OnClicked, Func = Bind(self, self.OnClicked_BtnClick)}
    }
end

function HeroSkinSuitPartListItem:OnHide()
end

function HeroSkinSuitPartListItem:OnShow(Param)
    self.SkinPartId = Param.PartId
    self.IsSelect = self.SkinPartId == Param.CurSelectId
    --TODO Icon展示
    local Cfg = G_ConfigHelper:GetSingleItemByKey(Cfg_HeroSkinPart, Cfg_HeroSkinPart_P.PartId, self.SkinPartId)
    if not Cfg then
        return
    end
    self.PartType = Cfg[Cfg_HeroSkinPart_P.PartType]
    self.SuitId = Cfg[Cfg_HeroSkinPart_P.SuitID]

    CommonUtil.SetBrushFromSoftObjectPath(self.View.Icon_Head_Item, Cfg[Cfg_HeroSkinPart_P.SuitPartPath])
    self.ItemIdOfSkin = Cfg[Cfg_HeroSkinPart_P.ItemId]

    self:UpdateSkinStateShow()
end

function HeroSkinSuitPartListItem:OnClicked_BtnClick()
    MvcEntry:GetModel(HeroModel):DispatchType(
        HeroModel.ON_HERO_SKIN_PART_SELECT,
        {PartType = self.PartType, SuitId = self.SuitId, SkinPartId = self.SkinPartId, LastSkinPartId = self.LastSkinPartId}
    )
end
function HeroSkinSuitPartListItem:OnSkinPartSelect(_, Param)
    self.IsSelect = Param.SkinPartId == self.SkinPartId
    self:UpdateSkinStateShow()
    self.LastSkinPartId = Param.SkinPartId
end

function HeroSkinSuitPartListItem:ON_ITEM_UPDATED_MAP_CUSTOM_Func(ChangeMap)
    self:UpdateSkinStateShow()
end

function HeroSkinSuitPartListItem:UpdateSkinStateShow()
    local isEquip = false
    local isUnLock = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(self.ItemIdOfSkin) > 0
    if isUnLock then
        isEquip = MvcEntry:GetModel(HeroModel):IsPartIdEquiped(self.SkinPartId)
    end
    local TagId = isEquip and CornerTagCfg.Equipped.TagId or CornerTagCfg.Lock.TagId
    CommonUtil.SetCornerTagImg(self.View.Img_Sub, TagId)
    -- 0:normal状态 1:锁定 2:选中状态
    self.View:SetWidgetState(not isUnLock and 1 or (isEquip and 2 or 0), self.IsSelect)
end

function HeroSkinSuitPartListItem:HandlePartStateChange(_, SkinPartId)
    -- if SkinPartId ~= self.SkinPartId then
    --     return
    -- end
    self:UpdateSkinStateShow()
end
return HeroSkinSuitPartListItem
