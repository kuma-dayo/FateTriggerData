local class_name = "HeroSkinSuitListItem"
local HeroSkinSuitListItem = BaseClass(nil, class_name)

function HeroSkinSuitListItem:OnInit()
    self.MsgList = {
        {Model = HeroModel,  MsgName = HeroModel.ON_HERO_SKIN_SUIT_SUBITEM_SELECT,	           Func = Bind(self, self.UpdateBtnState) }, 
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_LIKE_SKIN_CHANGE, Func = self.HERO_SKIN_DEFAULT_PART_CHANGE },
        {Model = HeroModel,  MsgName = HeroModel.HERO_SKIN_DEFAULT_PART_CHANGE,	           Func = Bind(self, self.HERO_SKIN_DEFAULT_PART_CHANGE) },   
        {Model = DepotModel, MsgName = ListModel.ON_UPDATED_MAP_CUSTOM, Func = self.ON_ITEM_UPDATED_MAP_CUSTOM_Func },
    }
    self.BindNodes = {
        {UDelegate = self.View.HeroPartListbtn.OnClicked, Func = Bind(self, self.OnClicked_BtnClick)}
    }
end

function HeroSkinSuitListItem:OnShow(Param)
end

function HeroSkinSuitListItem:OnHide()
end

--[[
    {
        SkinId = SkinId,
        HeroId = self.HeroId,
        ClickFunc
        Index
    }
]]
function HeroSkinSuitListItem:SetData(Param)
    --TODO 根据数据进行展示
    self.Param = Param
    self.SkinId = self.Param.SkinId
    self.SkinIDArr = self.Param.SkinIDArr
    self.HeroId = self.Param.HeroId
    self:HERO_SKIN_DEFAULT_PART_CHANGE()
end

function HeroSkinSuitListItem:UpdateSkinStateShow()
    local TblSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin,self.SkinId) 
    self.ItemIdOfSkin = TblSkin[Cfg_HeroSkin_P.ItemId]
    self.UnlockItemId = TblSkin[Cfg_HeroSkin_P.UnlockItemId]
    self.UnlockItemNum = TblSkin[Cfg_HeroSkin_P.UnlockItemNum]

    local ShowColorIcon = TblSkin[Cfg_HeroSkin_P.SuitType] == 1
    self.View.Icon_Head_Item:SetVisibility(not ShowColorIcon and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.Icon_Color_Item:SetVisibility(ShowColorIcon and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    if ShowColorIcon then
        CommonUtil.SetBrushFromSoftObjectPath(self.View.Icon_Color_Item, TblSkin[Cfg_HeroSkin_P.SuitIconPath])
    else
        CommonUtil.SetBrushFromSoftObjectPath(self.View.Icon_Head_Item, TblSkin[Cfg_HeroSkin_P.SuitIconPath])
    end

    if self.UnlockBtn then
        self.UnlockBtn:ShowCurrency(self.UnlockItemId,self.UnlockItemNum)
    end

    local IsLock = MvcEntry:GetModel(DepotModel):GetItemCountByItemId(self.ItemIdOfSkin) <= 0
    local TagId = CornerTagCfg.Lock.TagId
    if IsLock then
        self.View:SetWidgetState(1,self.Select)
    else
        local FavoriteSkinId = MvcEntry:GetModel(HeroModel):GetSuitFavoriteSkinIdByHeroId(self.HeroId)
        if FavoriteSkinId == self.SkinId then
            self.View:SetWidgetState(2, self.Select)
            TagId = CornerTagCfg.Equipped.TagId
        else
            self.View:SetWidgetState(0, self.Select)
        end
    end
    CommonUtil.SetCornerTagImg(self.View.Img_Sub, TagId)
end


function HeroSkinSuitListItem:OnClicked_BtnClick()
    MvcEntry:GetModel(HeroModel):DispatchType(HeroModel.ON_HERO_SKIN_SUIT_SUBITEM_SELECT, {HeroId = self.HeroId, SkinId = self.SkinId, SkinIDArr = self.SkinIDArr})
end

function HeroSkinSuitListItem:UpdateBtnState(_, Param)
    self.Select = self.SkinId == Param.SkinId
    self:UpdateSkinStateShow()
end

function HeroSkinSuitListItem:ON_HERO_LIKE_SKIN_CHANGE_Func()
    self:UpdateSkinStateShow()
end
function HeroSkinSuitListItem:ON_ITEM_UPDATED_MAP_CUSTOM_Func()
    self:UpdateSkinStateShow()
end
function HeroSkinSuitListItem:HERO_SKIN_DEFAULT_PART_CHANGE()
    local SelectSkinId = MvcEntry:GetModel(HeroModel):GetCurSkinSelect(self.SkinId)
    self.Select = SelectSkinId == self.SkinId
    self:UpdateSkinStateShow()
end

return HeroSkinSuitListItem
