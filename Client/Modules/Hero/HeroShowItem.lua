local class_name = "HeroShowItem"
---@class HeroShowItem
local HeroShowItem = BaseClass(nil, class_name)

HeroShowItem.LASTPLAYSTATE = {
    LIKE = 1, --激活订阅
    UNLIKE = 2 --取消订阅
}

function HeroShowItem:OnInit()
    self.BindNodes = {
        { UDelegate = self.View.OnAnimationFinished_vx_btn_hero_like_out,	Func = Bind(self,self.On_vx_btn_hero_like_out_Finished) },
    }
    UIHandler.New(
        self,
        self.View.GUIButton,
        CommonButtonExtend,
        {
            ClickFunc = Bind(self, self.OnClicked_BtnClick),
            RightClickFunc = Bind(self, self.OnRightMouseClicked_BtnClick)
        }
    )

    self.MsgList = {
        {Model = HeroModel, MsgName = HeroModel.ON_PLAYER_LIKE_HERO_CHANGE, Func = Bind(self, self.PlayerLikeHeroChange)},
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_LIKE_SKIN_CHANGE, Func = Bind(self, self.UpdateSkin)},
        {Model = HeroModel, MsgName = HeroModel.ON_HERO_SHOW_ITEM_SELECT, Func = Bind(self, self.Select)},
        {Model = HeroModel,  MsgName = HeroModel.ON_NEW_HERO_UNLOCKED,	           Func = Bind(self, self.PlayerUnlockHeroChange) },   
        {Model = EventTrackingModel,  MsgName = EventTrackingModel.ON_SATE_ACTIVE_CHANGED_WITH_TAB_ID,	           Func = self.OnShowByHallTabChange }, 
		{Model = DepotModel,  	MsgName = DepotModel.ON_DEPOT_DATA_INITED,      Func = Bind(self, self.ON_DEPOT_DATA_INITED)},
    }

    self.Param = nil
    self.IsSelect = false
end

function HeroShowItem:OnHide()

end

function HeroShowItem:PlayerLikeHeroChange(_, Data)
    if Data.OldId == self.HeroId then
        self:PlayDynamicEffectByLike(false)
    end
    if Data.NewId == self.HeroId then
        self:PlayDynamicEffectByLike(true)
    end

    if Data.OldId == self.HeroId or Data.NewId == self.HeroId then
        self:UpdateBtnState()
    end
end

function HeroShowItem:PlayerUnlockHeroChange()
    self:UpdateBtnState()
end

function HeroShowItem:OnManualShow(Param)
    self:UpdateSkin({HeroId=self.HeroId})
    self:UpdateBtnState()
end

function HeroShowItem:OnShow(Param)
    if not Param or not Param.HeroId then
        CError("HeroShowItem:OnShow Param is null")
        return
    end
    self.HeroId = Param.HeroId
    local CfgHero = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, self.HeroId)

    if not CfgHero then
        return
    end
    self.IsSelect = false
    self:UpdateSkin({HeroId=self.HeroId})
    self:UpdateBtnState()

    self.View.Gap:SetVisibility(Param.IsLastOne and UE.ESlateVisibility.Collapsed or UE.ESlateVisibility.SelfHitTestInvisible)

    local GapVisibility = self.View.Gap:GetVisibility()
    local IsGapVisible = not (GapVisibility == UE.ESlateVisibility.Collapsed or GapVisibility == UE.ESlateVisibility.Hidden)

    if self.View.VX_Hover then --动效hover是正常的，有个尺寸对不上，做下适配
        local Height_VX_Hover = self.View.VX_Hover.Slot:GetSize().y
        local Width_Gap = IsGapVisible and self.View.Gap.Slot:GetSize().x or self.View.VX_Hover.Slot:GetSize().x
        self.View.VX_Hover.Slot:SetSize(UE.FVector2D(Width_Gap, Height_VX_Hover))
    end

    --绑定红点
    local RedDotKey = "TabHero_"
    local RedDotSuffix = CfgHero[Cfg_HeroConfig_P.Id]
    if not self.RedDot then
        CLog("[hz] WBP_RedDotFactory")
        self.View.WBP_RedDotFactory:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
        self.RedDot =
            UIHandler.New(
            self,
            self.View.WBP_RedDotFactory,
            CommonRedDot,
            {RedDotKey = RedDotKey, RedDotSuffix = RedDotSuffix}
        ).ViewInstance
    else
        self.RedDot:ChangeKey(RedDotKey, RedDotSuffix)
    end
end

-- function HeroShowItem:OnManualShow(Param)
--     self.IsSelect = false
--     self:UpdateBtnState()
-- end

function HeroShowItem:UpdateSkin(Param)
    local CfgHero = G_ConfigHelper:GetSingleItemById(Cfg_HeroConfig, Param.HeroId)
    if not CfgHero then
        return
    end
    local FavoriteSkinId = MvcEntry:GetModel(HeroModel):GetFavoriteSkinIdByHeroId(CfgHero[Cfg_HeroConfig_P.Id])
    local TblSkin = G_ConfigHelper:GetSingleItemById(Cfg_HeroSkin, FavoriteSkinId)
    if not TblSkin then
        return
    end
    CommonUtil.SetBrushFromSoftObjectPath(self.View.HeroIcon, TblSkin[Cfg_HeroSkin_P.PNGPathNormal])
end

function HeroShowItem:OnShowByHallTabChange(InViewData)
    if InViewData and InViewData.TabId == CommonConst.HL_HERO then
        local IsShowLike = self.HeroId == MvcEntry:GetModel(HeroModel):GetFavoriteId()
        if IsShowLike then
            if self.View.VXE_CommonBTN_HeroLike_In then
                self.View:VXE_CommonBTN_HeroLike_In()
            end
        end
    end
end

function HeroShowItem:UpdateBtnState()
    local HeroModel = MvcEntry:GetModel(HeroModel)
    self.IsLock = not HeroModel:CheckGotHeroById(self.HeroId)
    local IsLikeNow = self.HeroId == HeroModel:GetFavoriteId()
    self.View:SetWidgetState(self.IsLock and 2 or (IsLikeNow and 1 or 0), self.IsSelect)
    self.View.Img_SubLeft:SetVisibility(IsLikeNow and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
    self.View.Img_SubRight:SetVisibility(self.IsLock and UE.ESlateVisibility.SelfHitTestInvisible or UE.ESlateVisibility.Collapsed)
end

function HeroShowItem:Select(_,Data)
    if Data.OldId == self.HeroId then
        self.IsSelect = false
    end
    if Data.NewId == self.HeroId then
        self.IsSelect = true
    end
    if Data.OldId == self.HeroId or Data.NewId == self.HeroId then
        self:UpdateBtnState()
    end
end

function HeroShowItem:OnClicked_BtnClick()
    MvcEntry:GetModel(HeroModel):DispatchType(HeroModel.ON_HERO_SHOW_ITEM_CLICK, self.HeroId)
end

function HeroShowItem:OnRightMouseClicked_BtnClick()
    MvcEntry:GetModel(HeroModel):DispatchType(HeroModel.ON_HERO_SHOW_ITEM_RIGHTCLICK, self.HeroId)
end

--[[
    播放显示退出动效
]]
function HeroShowItem:PlayDynamicEffectByLike(InIsByLike)
    if InIsByLike then
        if self.View.VXE_CommonBTN_HeroLike_In then
            self.View:VXE_CommonBTN_HeroLike_In()
        end
    else
        if self.View.VXE_CommonBTN_HeroLike_Out then
            self.View:VXE_CommonBTN_HeroLike_Out()
        end
    end
end

function HeroShowItem:On_vx_btn_hero_like_out_Finished()
    self.View.Img_SubLeft:SetVisibility(UE.ESlateVisibility.Collapsed)
end


function HeroShowItem:ON_DEPOT_DATA_INITED()
    self:UpdateBtnState()
end

return HeroShowItem
